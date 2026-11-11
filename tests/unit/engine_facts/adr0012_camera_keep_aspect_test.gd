extends GdUnitTestSuite
# Verifica NP-4 y NP-9 de ADR-0012 en Godot 4.7.2 (S-0012-B, parte numerica headless).
## S-0012-B: Camera3D.keep_aspect = KEEP_HEIGHT makes `fov` the vertical angle; a 1 m quad at 1 m measured
## through unproject_position in SubViewports of 16:9, 4:3, 21:9 and 32:9; a horizontal-FOV cap at 120 deg
## gives 51.9 deg vertical at 32:9; a fov change is visible in the same frame; viewport size API.
## Rendered pixels in a real resized window are NEEDS_WINDOWED (prototypes/physics-spike/).

const FOV_V_DEG: float = 70.0
const HFOV_CAP_DEG: float = 120.0  # cap that yields 51.9 deg vertical at 32:9


func _cam_in_viewport(size: Vector2i, fov_deg: float) -> Camera3D:
	var vp: SubViewport = SubViewport.new()
	vp.size = size
	add_child(auto_free(vp))
	var cam: Camera3D = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.fov = fov_deg
	vp.add_child(cam)
	cam.current = true
	return cam


func _quad_height_px(cam: Camera3D) -> float:
	var a: Vector2 = cam.unproject_position(Vector3(0.0, -0.5, -1.0))
	var b: Vector2 = cam.unproject_position(Vector3(0.0, 0.5, -1.0))
	return absf(b.y - a.y)


func _measured_vertical_fov_deg(cam: Camera3D, viewport_h: float) -> float:
	return rad_to_deg(2.0 * atan(viewport_h / _quad_height_px(cam) * 0.5))


func test_quad_height_px_matches_vertical_fov_formula_at_four_aspects() -> void:
	# Arrange
	var sizes: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1440, 1080), Vector2i(2520, 1080), Vector2i(3840, 1080)]
	var worst: float = 0.0

	# Act
	for s: Vector2i in sizes:
		var cam: Camera3D = _cam_in_viewport(s, FOV_V_DEG)
		var measured: float = _quad_height_px(cam)
		var expected: float = float(s.y) / (2.0 * tan(deg_to_rad(FOV_V_DEG) * 0.5))
		worst = maxf(worst, absf(measured - expected))
		var sz: Vector2 = cam.get_viewport().get_visible_rect().size
		print("S-0012-B size=", s, " aspect=", float(s.x) / float(s.y), " quad_px=", measured, " expected_px=", expected, " visible_rect=", sz)
		assert_vector(sz).is_equal(Vector2(s))
	print("S-0012-B worst quad px error=", worst)

	# Assert: within +-1 px at every aspect (F5 not applied)
	assert_float(worst).is_less(1.0)


func test_horizontal_fov_cap_gives_51_9_degrees_vertical_at_32_9() -> void:
	# Arrange: 32:9 viewport; fov_v = 2 atan(tan(hfov_cap / 2) / aspect)
	var size: Vector2i = Vector2i(3840, 1080)
	var aspect: float = float(size.x) / float(size.y)
	var fov_v: float = rad_to_deg(2.0 * atan(tan(deg_to_rad(HFOV_CAP_DEG) * 0.5) / aspect))
	var cam: Camera3D = _cam_in_viewport(size, fov_v)

	# Act
	var measured: float = _measured_vertical_fov_deg(cam, float(size.y))
	print("S-0012-B 32:9 capped fov_v(computed)=", fov_v, " measured vertical FOV deg=", measured)

	# Assert
	assert_float(measured).is_equal_approx(51.9, 0.2)


func test_fov_change_is_visible_in_the_same_frame() -> void:
	# Arrange
	var cam: Camera3D = _cam_in_viewport(Vector2i(1920, 1080), 70.0)
	var before: float = _quad_height_px(cam)

	# Act
	cam.fov = 50.0
	var after: float = _quad_height_px(cam)
	var expected_after: float = 1080.0 / (2.0 * tan(deg_to_rad(25.0)))
	print("S-0012-B fov 70->50 same frame: quad px ", before, " -> ", after, " expected ", expected_after)

	# Assert
	assert_float(after).is_equal_approx(expected_after, 1.0)
	assert_float(after).is_greater(before)


func test_near_and_make_current_are_readable() -> void:
	# Arrange
	var cam: Camera3D = _cam_in_viewport(Vector2i(1280, 720), 70.0)
	cam.near = 0.03
	var other: Camera3D = Camera3D.new()
	cam.get_viewport().add_child(other)

	# Act
	other.make_current()
	var other_current: bool = other.is_current()
	cam.make_current()
	print("S-0012-B near=", cam.near, " make_current switches: other=", other_current, " cam=", cam.is_current(), " other_after=", other.is_current())

	# Assert
	assert_float(cam.near).is_equal_approx(0.03, 1e-6)
	assert_bool(other_current).is_true()
	assert_bool(cam.is_current()).is_true()
	assert_bool(other.is_current()).is_false()
