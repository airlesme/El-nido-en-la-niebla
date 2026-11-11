extends GdUnitTestSuite
# Verifica NP-5, NP-6 y NP-8 de ADR-0012 en Godot 4.7.2 (S-0012-C y S-0012-D).
## S-0012-C: Jolt CharacterBody3D (capsule r 0.25 m, h 1.75 m) head-on, 45 deg wall, corner, 1.00 m door,
## 0.45 m gap, flat floor, floor metadata label, per-tick cost.
## S-0012-D: shrunk-capsule overlap query: touch -> false, 0.05 m inside -> true, cost per call.

const RADIUS: float = 0.25
const HEIGHT: float = 1.75
const DT: float = 1.0 / 60.0
const SPEED: float = 1.6
const GRAVITY: float = 9.8
const EPS_STUCK: float = 0.02  # eps_atasco_m (ADR range 0,005-0,05); spike value
const FLOOR_Y: float = 0.0


class Walker extends CharacterBody3D:
	var wish: Vector3 = Vector3.ZERO
	var log_pos: Array[Vector3] = []
	var log_vel: Array[Vector3] = []
	var run: bool = true
	var floor_label: String = ""
	var step_usec: Array[int] = []
	var active: bool = true

	func tick() -> void:
		var t0: int = Time.get_ticks_usec()
		velocity.x = wish.x
		velocity.z = wish.z
		velocity.y -= 9.8 * (1.0 / 60.0)
		move_and_slide()
		if is_on_floor():
			velocity.y = 0.0
		step_usec.append(Time.get_ticks_usec() - t0)
		log_pos.append(global_position)
		log_vel.append(get_real_velocity())
		for i: int in get_slide_collision_count():
			var c: KinematicCollision3D = get_slide_collision(i)
			var col: Object = c.get_collider()
			if col != null and col.has_meta(&"surface"):
				floor_label = str(col.get_meta(&"surface"))


class Driver extends Node:
	var walkers: Array[Walker] = []
	var ticks: int = 0

	func _physics_process(_delta: float) -> void:
		ticks += 1
		for w: Walker in walkers:
			w.tick()


func _static_box(parent: Node, center: Vector3, size: Vector3, yaw_deg: float = 0.0) -> StaticBody3D:
	var b: StaticBody3D = StaticBody3D.new()
	b.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	b.add_child(cs)
	b.position = center
	b.rotation_degrees.y = yaw_deg
	parent.add_child(b)
	return b


func _walker(parent: Node, pos: Vector3, wish: Vector3) -> Walker:
	var w: Walker = Walker.new()
	w.collision_layer = 2
	w.collision_mask = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = RADIUS
	cap.height = HEIGHT
	cs.shape = cap
	w.add_child(cs)
	w.position = pos
	w.wish = wish
	parent.add_child(w)
	return w


## Each scenario sits in its own z lane (20 m apart) with its own floor slab (top at y = 0).
func _lane_floor(parent: Node, z: float, label: String = "") -> StaticBody3D:
	var f: StaticBody3D = _static_box(parent, Vector3(5.0, -0.5, z), Vector3(30.0, 1.0, 10.0))
	if label != "":
		f.set_meta(&"surface", label)
	return f


func _run_ticks(driver: Driver, n: int) -> void:
	var start: int = driver.ticks
	while driver.ticks - start < n:
		await get_tree().physics_frame


func test_head_on_wall_push_has_no_oscillation_and_floor_y_is_constant() -> void:
	# Arrange
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var driver: Driver = Driver.new()
	root.add_child(driver)
	_lane_floor(root, 0.0, "test")
	_static_box(root, Vector3(3.0, 1.0, 0.0), Vector3(0.5, 2.0, 6.0))  # wall face at x = 2.75
	var w: Walker = _walker(root, Vector3(0.0, HEIGHT * 0.5 + 0.02, 0.0), Vector3(SPEED, 0, 0))
	driver.walkers.append(w)

	# Act: 140 ticks to arrive (2.5 m at 1.6 m/s = 94 ticks) and settle, then 60 ticks to measure
	await _run_ticks(driver, 200)
	var tail: Array[Vector3] = w.log_pos.slice(w.log_pos.size() - 60)
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	for p: Vector3 in tail:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var gap_to_wall: float = 2.75 - (tail.back() as Vector3).x - RADIUS
	print("S-0012-C head-on: x variation over 60 ticks (mm)=", (max_x - min_x) * 1000.0, " y variation (mm)=", (max_y - min_y) * 1000.0,
		" final x=", (tail.back() as Vector3).x, " gap capsule-to-wall (mm)=", gap_to_wall * 1000.0, " floor label='", w.floor_label,
		"' on_floor=", w.is_on_floor(), " floor_snap_length=", w.floor_snap_length, " safe_margin=", w.safe_margin)

	# Assert
	assert_float((max_x - min_x) * 1000.0).is_less(1.0)
	assert_float((max_y - min_y) * 1000.0).is_less(1.0)
	assert_str(w.floor_label).is_equal("test")


func test_45_degree_wall_slides_with_no_normal_velocity_and_corner_and_door_and_gap() -> void:
	# Arrange
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var driver: Driver = Driver.new()
	root.add_child(driver)

	# 45 deg wall in lane z = 20: wall plane through (3, *, 20) rotated 45 deg; normal = (-sin45, 0, cos45) rotated
	_lane_floor(root, 20.0)
	var wall45: StaticBody3D = _static_box(root, Vector3(3.0, 1.0, 20.0), Vector3(0.5, 2.0, 12.0), 45.0)
	var normal45: Vector3 = wall45.global_transform.basis.x.normalized()  # local +X is the face normal
	var w45: Walker = _walker(root, Vector3(0.0, HEIGHT * 0.5 + 0.02, 20.0), Vector3(SPEED, 0, 0))

	# Corner in lane z = 40: walls at x = 3 and z = 40 + 2, push diagonally
	_lane_floor(root, 40.0)
	_static_box(root, Vector3(3.0, 1.0, 40.0), Vector3(0.5, 2.0, 8.0))
	_static_box(root, Vector3(0.0, 1.0, 42.0), Vector3(8.0, 2.0, 0.5))
	var wcorner: Walker = _walker(root, Vector3(0.0, HEIGHT * 0.5 + 0.02, 40.0), Vector3(SPEED, 0, SPEED))

	# Door 1.00 m wide in a wall at x = 3 (lane z = 60), walker offset 0.2 m from centre
	_lane_floor(root, 60.0)
	_static_box(root, Vector3(3.0, 1.0, 60.0 - 0.5 - 2.0), Vector3(0.5, 2.0, 4.0))  # z 56.. 60 - 0.5 -> edge at z = 59.5
	_static_box(root, Vector3(3.0, 1.0, 60.0 + 0.5 + 2.0), Vector3(0.5, 2.0, 4.0))  # edge at z = 60.5
	var wdoor: Walker = _walker(root, Vector3(0.0, HEIGHT * 0.5 + 0.02, 60.2), Vector3(SPEED, 0, 0))

	# Gap 0.45 m in lane z = 80
	_lane_floor(root, 80.0)
	_static_box(root, Vector3(3.0, 1.0, 80.0 - 0.225 - 2.0), Vector3(0.5, 2.0, 4.0))
	_static_box(root, Vector3(3.0, 1.0, 80.0 + 0.225 + 2.0), Vector3(0.5, 2.0, 4.0))
	var wgap: Walker = _walker(root, Vector3(0.0, HEIGHT * 0.5 + 0.02, 80.0), Vector3(SPEED, 0, 0))

	driver.walkers.append_array([w45, wcorner, wdoor, wgap])

	# Act
	await _run_ticks(driver, 260)

	# 45 deg: normal component of the real velocity over the last 30 ticks
	var worst_normal: float = 0.0
	for v: Vector3 in w45.log_vel.slice(w45.log_vel.size() - 30):
		worst_normal = maxf(worst_normal, absf(v.dot(normal45)))
	var slide_speed: float = (w45.log_vel.back() as Vector3).length()
	# corner
	var cs_pos: Array[Vector3] = wcorner.log_pos.slice(wcorner.log_pos.size() - 60)
	var corner_jitter: float = 0.0
	for p: Vector3 in cs_pos:
		corner_jitter = maxf(corner_jitter, p.distance_to(cs_pos.back() as Vector3))
	# door
	var door_x: float = (wdoor.log_pos.back() as Vector3).x
	var gap_x: float = (wgap.log_pos.back() as Vector3).x
	print("S-0012-C 45deg: worst normal velocity (m/s) over last 30 ticks=", worst_normal, " slide speed=", slide_speed,
		" | corner jitter over 60 ticks (mm)=", corner_jitter * 1000.0, " final=", wcorner.log_pos.back(),
		" | door 1.00 m (offset 0.2 m) final x=", door_x, " (wall x 2.75..3.25) | gap 0.45 m final x=", gap_x)
	var cost_sorted: Array[int] = w45.step_usec.duplicate()
	cost_sorted.sort()
	var cost_sum: int = 0
	for u: int in cost_sorted:
		cost_sum += u
	print("S-0012-C move_and_slide cost per tick (us) on the 45deg walker: mean=", float(cost_sum) / float(cost_sorted.size()),
		" p99=", cost_sorted[int(cost_sorted.size() * 0.99)], " max=", cost_sorted.back())

	# Assert
	assert_float(worst_normal).is_less(0.001)
	assert_float(corner_jitter * 1000.0).is_less(1.0)
	assert_float(door_x).is_greater(3.5)  # passed through the 1.00 m door
	assert_float(gap_x).is_less(3.0)  # 0.45 m gap not passable (capsule is 0.50 m); tip may enter the opening


func test_shrunk_capsule_overlap_probe_touch_false_inside_true_and_cost() -> void:
	# Arrange: static wall, capsule probe shrunk by eps
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	_static_box(root, Vector3(3.0, 1.0, 0.0), Vector3(0.5, 2.0, 6.0))  # face at x = 2.75
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var probe_shape: CapsuleShape3D = CapsuleShape3D.new()
	probe_shape.radius = RADIUS - EPS_STUCK
	probe_shape.height = HEIGHT - 2.0 * EPS_STUCK
	var q: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	q.shape = probe_shape
	q.collision_mask = 1
	q.margin = 0.0
	var results: Dictionary = {}

	# Act: centre x such that the full capsule penetrates the wall by depth d
	for depth: float in [0.0, 0.01, 0.03, 0.05, 0.10]:
		var cx: float = 2.75 - RADIUS + depth
		q.transform = Transform3D(Basis.IDENTITY, Vector3(cx, 1.0, 0.0))
		results[depth] = space.intersect_shape(q, 1).size() > 0
	var samples: PackedFloat64Array = PackedFloat64Array()
	q.transform = Transform3D(Basis.IDENTITY, Vector3(2.75 - RADIUS + 0.05, 1.0, 0.0))
	for i: int in 600:
		var t0: int = Time.get_ticks_usec()
		space.intersect_shape(q, 1)
		samples.append(float(Time.get_ticks_usec() - t0) / 1000.0)
	var sorted: PackedFloat64Array = samples.duplicate()
	sorted.sort()
	var total: float = 0.0
	for v: float in samples:
		total += v
	var mean_ms: float = total / 600.0
	print("S-0012-D eps=", EPS_STUCK, " overlap by penetration depth (m)->bool: ", results,
		" | cost per call mean_ms=", mean_ms, " p99_ms=", sorted[int(600 * 0.99)])

	# Assert
	assert_bool(results[0.0]).is_false()
	assert_bool(results[0.05]).is_true()
	assert_float(mean_ms).is_less(0.05)
