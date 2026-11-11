extends GdUnitTestSuite
# Verifica NS-1..NS-4 de ADR-0011 en Godot 4.7.2 (S-0011-B).
## S-0011-B: intersect_ray against Jolt BoxShape3D faces: depth error vs analytic,
## exclude, mask filtering, ray starting inside a box, result keys.

const BOX_THICKNESS: float = 0.2
const TOLERANCE_M: float = 0.005  # ADR-0011 decision rule: <= 5 mm as designed


func _make_box(center: Vector3, size: Vector3, layer_bit: int) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1 << (layer_bit - 1)
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child(auto_free(body))
	return body


func _ray(from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, mask)
	q.exclude = exclude
	return get_viewport().world_3d.direct_space_state.intersect_ray(q)


func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


func test_normal_incidence_depth_error_within_5mm_at_0_5_to_1_8_m() -> void:
	# Arrange: wall face at z = -d for each distance, one box per distance (offset in x)
	var distances: Array[float] = [0.5, 1.0, 1.5, 1.8]
	for i: int in distances.size():
		var d: float = distances[i]
		_make_box(Vector3(i * 10.0, 0.0, -(d + BOX_THICKNESS * 0.5)), Vector3(4.0, 4.0, BOX_THICKNESS), 2)
	await _settle()

	# Act + Assert
	var worst: float = 0.0
	for i: int in distances.size():
		var d: float = distances[i]
		var origin: Vector3 = Vector3(i * 10.0, 0.0, 0.0)
		var hit: Dictionary = _ray(origin, origin + Vector3(0, 0, -3.0), 1 << 1)
		assert_bool(hit.is_empty()).is_false()
		var depth: float = origin.distance_to(hit["position"] as Vector3)
		var err: float = depth - d
		worst = maxf(worst, absf(err))
		print("S-0011-B normal d=", d, " depth=", depth, " err_mm=", err * 1000.0, " keys=", hit.keys())
	print("S-0011-B normal worst_err_mm=", worst * 1000.0)
	assert_float(worst).is_less(TOLERANCE_M)


func test_60_degree_incidence_depth_error_within_5mm() -> void:
	# Arrange
	var distances: Array[float] = [0.5, 1.0, 1.8]
	for i: int in distances.size():
		_make_box(Vector3(i * 30.0, 0.0, -(distances[i] + BOX_THICKNESS * 0.5)), Vector3(20.0, 4.0, BOX_THICKNESS), 2)
	await _settle()

	# Act
	var worst: float = 0.0
	var dir: Vector3 = Vector3(sin(deg_to_rad(60.0)), 0.0, -cos(deg_to_rad(60.0)))
	for i: int in distances.size():
		var d: float = distances[i]
		var origin: Vector3 = Vector3(i * 30.0, 0.0, 0.0)
		var hit: Dictionary = _ray(origin, origin + dir * 6.0, 1 << 1)
		assert_bool(hit.is_empty()).is_false()
		var expected: float = d / cos(deg_to_rad(60.0))
		var depth: float = origin.distance_to(hit["position"] as Vector3)
		worst = maxf(worst, absf(depth - expected))
		print("S-0011-B 60deg d=", d, " depth=", depth, " expected=", expected, " err_mm=", (depth - expected) * 1000.0)
	print("S-0011-B 60deg worst_err_mm=", worst * 1000.0)

	# Assert
	assert_float(worst).is_less(TOLERANCE_M)


func test_exclude_skips_the_excluded_body_and_hits_the_one_behind() -> void:
	# Arrange: near box at z=-1, far box at z=-2
	var near: StaticBody3D = _make_box(Vector3(0, 0, -1.1), Vector3(4, 4, BOX_THICKNESS), 2)
	_make_box(Vector3(0, 0, -2.1), Vector3(4, 4, BOX_THICKNESS), 2)
	await _settle()

	# Act
	var excluded: Array[RID] = [near.get_rid()]
	var hit_all: Dictionary = _ray(Vector3.ZERO, Vector3(0, 0, -5), 1 << 1)
	var hit_ex: Dictionary = _ray(Vector3.ZERO, Vector3(0, 0, -5), 1 << 1, excluded)
	print("S-0011-B exclude: all z=", (hit_all["position"] as Vector3).z, " excluded z=", (hit_ex["position"] as Vector3).z,
		" has collider=", hit_all.has("collider"), " has rid=", hit_all.has("rid"))

	# Assert
	assert_float((hit_all["position"] as Vector3).z).is_equal_approx(-1.0, 0.005)
	assert_float((hit_ex["position"] as Vector3).z).is_equal_approx(-2.0, 0.005)
	assert_bool(hit_all.has("collider")).is_true()
	assert_bool(hit_all.has("rid")).is_true()


func test_mask_bit_1_ignores_bodies_on_bits_2_to_5() -> void:
	# Arrange: one box on each of bits 2..5, ray mask only bit 1
	for bit: int in [2, 3, 4, 5]:
		_make_box(Vector3(0, 0, -(0.5 + bit * 0.5)), Vector3(4, 4, 0.1), bit)
	await _settle()

	# Act
	var hit_bit1: Dictionary = _ray(Vector3.ZERO, Vector3(0, 0, -6), 1 << 0)
	var hit_bit2: Dictionary = _ray(Vector3.ZERO, Vector3(0, 0, -6), 1 << 1)
	var hit_bit3: Dictionary = _ray(Vector3.ZERO, Vector3(0, 0, -6), 1 << 2)
	print("S-0011-B mask: bit1 empty=", hit_bit1.is_empty(), " bit2 z=", (hit_bit2["position"] as Vector3).z,
		" bit3 z=", (hit_bit3["position"] as Vector3).z)

	# Assert
	assert_bool(hit_bit1.is_empty()).is_true()
	assert_float((hit_bit2["position"] as Vector3).z).is_less(0.0)
	assert_float((hit_bit3["position"] as Vector3).z).is_less((hit_bit2["position"] as Vector3).z)


func test_ray_starting_inside_box_reports_hit_from_inside_flag_behaviour() -> void:
	# Arrange
	_make_box(Vector3.ZERO, Vector3(2, 2, 2), 2)
	await _settle()

	# Act
	var q_default: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3(0, 0, -5), 1 << 1)
	var q_off: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3(0, 0, -5), 1 << 1)
	q_off.hit_from_inside = false
	var space: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var r_default: Dictionary = space.intersect_ray(q_default)
	var r_off: Dictionary = space.intersect_ray(q_off)
	print("S-0011-B inside: default hit_from_inside=", q_default.hit_from_inside, " empty=", r_default.is_empty(),
		" | explicit false empty=", r_off.is_empty())

	# Assert: with hit_from_inside=false a ray that starts inside a box must not report it
	assert_bool(r_off.is_empty()).is_true()
