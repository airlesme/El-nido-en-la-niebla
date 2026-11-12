extends GdUnitTestSuite
## IP-003: PhysicsOcclusionProbe against the real physics world (Jolt in 4.7.2). Environment independent:
## only geometry and layers are asserted. Reference: tests/unit/engine_facts/adr0011_ray_occlusion_test.gd.

const TOL: float = 0.03
const EYE: Vector3 = Vector3.ZERO
const U: Vector3 = Vector3(0, 0, -1)

var _bodies: Array[StaticBody3D] = []


func after_test() -> void:
	for b: StaticBody3D in _bodies:
		if is_instance_valid(b):
			b.free()
	_bodies.clear()


func _box(center: Vector3, size: Vector3, layer: int) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child(body)
	_bodies.append(body)
	return body


func _wall(z_front: float, layer: int = 1) -> StaticBody3D:
	return _box(Vector3(0, 0, z_front - 0.1), Vector3(4, 4, 0.2), layer)


func _contact(d_c: float) -> InteractionTypes.ContactInfo:
	var c: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()
	c.d_c = d_c
	c.contact_point = EYE + U * d_c
	return c


func _probe() -> PhysicsOcclusionProbe:
	return PhysicsOcclusionProbe.new(get_viewport().world_3d)


func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


func test_wall_at_1m_occludes_object_at_1_5m() -> void:
	_wall(-1.0)
	await _settle()
	var probe: PhysicsOcclusionProbe = _probe()
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_true()
	assert_float(probe.hit_depth(EYE, U, _contact(1.5))).is_equal_approx(1.0, 0.005)


func test_support_surface_at_1499_does_not_occlude() -> void:
	_wall(-1.499)
	await _settle()
	assert_bool(_probe().is_occluded(EYE, U, _contact(1.5), TOL)).is_false()


func test_no_geometry_means_no_hit() -> void:
	await _settle()
	assert_float(_probe().hit_depth(EYE, U, _contact(1.5))).is_equal(OcclusionProbe.NO_HIT)


func test_bodies_on_other_layers_do_not_occlude() -> void:
	_wall(-1.0, 1 << 1)  # player_body
	_wall(-0.9, 1 << 2)  # interactable
	_wall(-0.8, 1 << 3)  # zone_sensor
	_wall(-0.7, 1 << 4)  # zone_trigger
	await _settle()
	assert_bool(_probe().is_occluded(EYE, U, _contact(1.5), TOL)).is_false()


func test_excluded_body_does_not_occlude() -> void:
	var wall: StaticBody3D = _wall(-1.0)
	await _settle()
	var c: InteractionTypes.ContactInfo = _contact(1.5)
	var probe: PhysicsOcclusionProbe = _probe()
	assert_bool(probe.is_occluded(EYE, U, c, TOL)).is_true()
	c.excluded_rids = [wall.get_rid()]
	assert_bool(probe.is_occluded(EYE, U, c, TOL)).is_false()


func test_eye_inside_solid_is_not_occluded() -> void:
	# Measured (S-0011-B): a ray that starts inside a solid does not hit.
	_box(EYE, Vector3(2, 2, 2), 1)
	await _settle()
	var probe: PhysicsOcclusionProbe = _probe()
	assert_float(probe.hit_depth(EYE, U, _contact(1.5))).is_equal(OcclusionProbe.NO_HIT)
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_false()
