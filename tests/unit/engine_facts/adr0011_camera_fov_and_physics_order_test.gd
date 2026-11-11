extends GdUnitTestSuite
# Verifica NS-9..NS-11 de ADR-0011 en Godot 4.7.2 (S-0011-C, parte numerica en headless).
## S-0011-C: Camera3D.keep_aspect default and FOV axis measured through unproject_position in a
## SubViewport of the three window sizes; process_physics_priority order of two nodes.
## The logical viewport under canvas_items/expand and rendered pixels are NEEDS_WINDOWED
## (see prototypes/physics-spike/).

const FOV_DEG: float = 70.0
const QUAD_M: float = 0.10
const QUAD_DISTANCE_M: float = 0.35


class OrderProbe extends Node:
	var tag: String = ""
	var log_ref: Array[String] = []

	func _physics_process(_delta: float) -> void:
		log_ref.append(tag)


func _measure_px(size: Vector2i, keep: Camera3D.KeepAspect) -> Vector2:
	var vp: SubViewport = SubViewport.new()
	vp.size = size
	add_child(auto_free(vp))
	var cam: Camera3D = Camera3D.new()
	cam.fov = FOV_DEG
	cam.keep_aspect = keep
	vp.add_child(cam)
	cam.current = true
	# Quad of QUAD_M x QUAD_M at QUAD_DISTANCE_M in front of the camera (looking down -Z)
	var p_a: Vector2 = cam.unproject_position(Vector3(-QUAD_M * 0.5, -QUAD_M * 0.5, -QUAD_DISTANCE_M))
	var p_b: Vector2 = cam.unproject_position(Vector3(QUAD_M * 0.5, QUAD_M * 0.5, -QUAD_DISTANCE_M))
	return Vector2(absf(p_b.x - p_a.x), absf(p_b.y - p_a.y))


func test_keep_aspect_default_is_keep_height() -> void:
	# Arrange
	var cam: Camera3D = auto_free(Camera3D.new())

	# Act
	print("S-0011-C default keep_aspect=", cam.keep_aspect, " (KEEP_HEIGHT=", Camera3D.KEEP_HEIGHT, ") default fov=", cam.fov, " near=", cam.near)

	# Assert
	assert_int(cam.keep_aspect).is_equal(Camera3D.KEEP_HEIGHT)


func test_keep_height_quad_px_matches_vertical_fov_formula_in_three_viewports() -> void:
	# Arrange
	var sizes: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(2560, 1600)]
	var worst: float = 0.0

	# Act
	for s: Vector2i in sizes:
		var px: Vector2 = _measure_px(s, Camera3D.KEEP_HEIGHT)
		var expected: float = float(s.y) * QUAD_M / (2.0 * QUAD_DISTANCE_M * tan(deg_to_rad(FOV_DEG) * 0.5))
		worst = maxf(worst, maxf(absf(px.x - expected), absf(px.y - expected)))
		print("S-0011-C keep_height size=", s, " measured_px=", px, " expected_px=", expected)
	print("S-0011-C keep_height worst_err_px=", worst)

	# Assert: within +-2 px of the analytic vertical-FOV value
	assert_float(worst).is_less(2.0)


func test_keep_width_control_gives_horizontal_fov_value() -> void:
	# Arrange / Act
	var s: Vector2i = Vector2i(1920, 1200)
	var px: Vector2 = _measure_px(s, Camera3D.KEEP_WIDTH)
	var expected_w: float = float(s.x) * QUAD_M / (2.0 * QUAD_DISTANCE_M * tan(deg_to_rad(FOV_DEG) * 0.5))
	print("S-0011-C keep_width size=", s, " measured_px=", px, " expected_if_fov_is_horizontal=", expected_w)

	# Assert
	assert_float(px.x).is_equal_approx(expected_w, 2.0)


func test_process_physics_priority_orders_two_nodes_regardless_of_tree_order() -> void:
	# Arrange: add the priority-10 node FIRST in the tree, priority-0 second
	var order: Array[String] = []
	var high: OrderProbe = OrderProbe.new()
	high.tag = "p10"
	high.process_physics_priority = 10
	high.log_ref = order
	var low: OrderProbe = OrderProbe.new()
	low.tag = "p0"
	low.process_physics_priority = 0
	low.log_ref = order
	add_child(auto_free(high))
	add_child(auto_free(low))

	# Act
	for i: int in 30:
		await get_tree().physics_frame
	await get_tree().physics_frame
	var pairs: int = 0
	var inverted: int = 0
	var i2: int = 0
	while i2 + 1 < order.size():
		if order[i2] == "p0" and order[i2 + 1] == "p10":
			pairs += 1
			i2 += 2
		elif order[i2] == "p10":
			inverted += 1
			i2 += 1
		else:
			i2 += 1
	print("S-0011-C physics priority: callbacks=", order.size(), " p0-then-p10 pairs=", pairs, " p10-first occurrences=", inverted,
		" first6=", order.slice(0, 6))

	# Assert: lower priority value runs first, tree order notwithstanding
	assert_int(pairs).is_greater(20)
	assert_int(inverted).is_equal(0)
