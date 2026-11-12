extends GdUnitTestSuite
## PJ-004 (T-U3 of ADR-0012): Look maths. AC-11, AC-12, AC-13 (M1 scope), AC-14. TR-player-007.
## AC-13: the door, blackout, call, reflection and P1-hint events of the full fixture are added when those systems exist.
## Pure maths: no node, no physics. pitch_max comes from the real player.json.

const PLAYER_FULL: String = "res://assets/data/player/player.json"
const FIXTURE: String = "res://tests/fixtures/player/look_seed_20261109.json"
const TOL_RAD: float = deg_to_rad(0.001)


func _cfg() -> PlayerConfig:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAYER_FULL))
	return PlayerConfig.from_dict(parsed as Dictionary)


func _look() -> Look:
	return Look.new(_cfg().pitch_max)


# --- AC-11 -------------------------------------------------------------------

func test_pitch_78_plus_5_clamps_to_pitch_max() -> void:
	var look: Look = _look()
	look.set_orientation(0.0, deg_to_rad(78.0))
	look.apply(0.0, deg_to_rad(5.0))
	assert_float(rad_to_deg(look.pitch)).is_equal_approx(80.0, 0.001)


func test_pitch_clamps_on_negative_side() -> void:
	var look: Look = _look()
	look.apply(0.0, deg_to_rad(-500.0))
	assert_float(look.pitch).is_equal(-_cfg().pitch_max)


func test_yaw_179_plus_5_wraps_to_minus_176() -> void:
	var look: Look = _look()
	look.set_orientation(deg_to_rad(179.0), 0.0)
	look.apply(deg_to_rad(5.0), 0.0)
	assert_float(rad_to_deg(look.yaw)).is_equal_approx(-176.0, 0.001)


func test_yaw_stays_in_half_open_range_after_many_turns() -> void:
	var look: Look = _look()
	for i: int in 1000:
		look.apply(deg_to_rad(37.0), 0.0)
		assert_bool(look.yaw >= -PI and look.yaw < PI).is_true()


func test_orientation_out_of_range_is_limited() -> void:
	var look: Look = _look()
	look.set_orientation(deg_to_rad(190.0), deg_to_rad(95.0))
	assert_float(rad_to_deg(look.pitch)).is_equal_approx(80.0, 0.001)
	assert_float(rad_to_deg(look.yaw)).is_equal_approx(-170.0, 0.001)


# --- OI-3: sign convention at the frontier ------------------------------------

func test_input_right_turns_clockwise_from_above() -> void:
	var look: Look = _look()
	look.apply_input_deg(Vector2(90.0, 0.0))
	# Turning right from -Z must face +X.
	var forward: Vector3 = look.to_basis() * Vector3.FORWARD
	assert_float(forward.x).is_equal_approx(1.0, 0.0001)
	assert_float(forward.z).is_equal_approx(0.0, 0.0001)


func test_input_up_raises_the_view() -> void:
	var look: Look = _look()
	look.apply_input_deg(Vector2(0.0, 30.0))
	var forward: Vector3 = look.to_basis() * Vector3.FORWARD
	assert_float(forward.y).is_equal_approx(sin(deg_to_rad(30.0)), 0.0001)


func test_yaw_zero_looks_along_minus_z() -> void:
	var forward: Vector3 = _look().to_basis() * Vector3.FORWARD
	assert_float(forward.z).is_equal_approx(-1.0, 0.0001)


# --- AC-12: frame-rate independence -------------------------------------------

func _final_yaw(frames: int) -> float:
	var look: Look = _look()
	for i: int in frames:
		look.apply_input_deg(Vector2(90.0 / float(frames), 0.0))
	return look.yaw


func test_same_total_yaw_in_3_or_12_frames_gives_same_result() -> void:
	assert_float(_final_yaw(3)).is_equal_approx(_final_yaw(12), TOL_RAD)


func test_irregular_split_of_the_same_total_gives_same_result() -> void:
	var a: Look = _look()
	for d: float in [10.0, 50.0, 30.0]:
		a.apply_input_deg(Vector2(d, 0.0))
	var b: Look = _look()
	b.apply_input_deg(Vector2(90.0, 0.0))
	assert_float(a.yaw).is_equal_approx(b.yaw, TOL_RAD)


# --- AC-13 (M1 scope) ---------------------------------------------------------

func test_fixture_roll_is_exactly_zero_and_zone_notices_do_not_move_the_view() -> void:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(fx["seed"])
	var max_d: float = float(fx["max_delta_deg"])
	var notices: Array = fx["zone_notice_steps"]
	var look: Look = _look()
	for step: int in int(fx["steps"]):
		var d: Vector2 = Vector2(rng.randf_range(-max_d, max_d), rng.randf_range(-max_d, max_d))
		if notices.has(step):
			# A zone-activated notice carries no look input: orientation must not change on its own.
			var before: Vector2 = Vector2(look.yaw, look.pitch)
			look.apply_input_deg(Vector2.ZERO)
			assert_vector(Vector2(look.yaw, look.pitch)).is_equal(before)
		var yaw_before: float = look.yaw
		var pitch_before: float = look.pitch
		look.apply_input_deg(d)
		var euler: Vector3 = look.to_basis().get_euler(EULER_ORDER_YXZ)
		assert_float(euler.z).is_equal_approx(0.0, 1e-6)
		# Roll as seen by the basis: the local X axis never leaves the horizontal plane.
		assert_float((look.to_basis() * Vector3.RIGHT).y).is_equal_approx(0.0, 1e-6)
		assert_bool(absf(look.pitch) <= _cfg().pitch_max).is_true()
		if d == Vector2.ZERO:
			assert_float(look.yaw).is_equal(yaw_before)
			assert_float(look.pitch).is_equal(pitch_before)


func test_fixture_is_deterministic_across_runs() -> void:
	var a: Vector2 = _run_fixture()
	var b: Vector2 = _run_fixture()
	assert_vector(a).is_equal(b)


func _run_fixture() -> Vector2:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(fx["seed"])
	var max_d: float = float(fx["max_delta_deg"])
	var look: Look = _look()
	for step: int in int(fx["steps"]):
		look.apply_input_deg(Vector2(rng.randf_range(-max_d, max_d), rng.randf_range(-max_d, max_d)))
	return Vector2(look.yaw, look.pitch)


# --- AC-14 --------------------------------------------------------------------

func test_nan_delta_is_discarded_and_orientation_unchanged() -> void:
	var look: Look = _look()
	look.set_orientation(0.3, 0.2)
	assert_bool(look.apply_input_deg(Vector2(NAN, 5.0))).is_false()
	assert_float(look.yaw).is_equal(0.3)
	assert_float(look.pitch).is_equal(0.2)


func test_infinite_delta_is_discarded() -> void:
	var look: Look = _look()
	assert_bool(look.apply_input_deg(Vector2(1.0, INF))).is_false()
	assert_bool(look.apply(-INF, 0.0)).is_false()
	assert_float(look.yaw).is_equal(0.0)
	assert_float(look.pitch).is_equal(0.0)


func test_non_finite_orientation_is_ignored() -> void:
	var look: Look = _look()
	look.set_orientation(NAN, 0.1)
	assert_float(look.yaw).is_equal(0.0)
	assert_float(look.pitch).is_equal(0.0)


func test_invalid_pitch_max_falls_back_to_zero() -> void:
	var look: Look = Look.new(NAN)
	look.apply(0.0, 1.0)
	assert_float(look.pitch).is_equal(0.0)


func test_look_has_no_reduce_startle_input() -> void:
	# The Player does not read `reducir_sobresaltos`: the API takes only the input delta, so outputs depend on it alone.
	var a: Look = _look()
	var b: Look = _look()
	a.apply_input_deg(Vector2(12.0, -7.0))
	b.apply_input_deg(Vector2(12.0, -7.0))
	assert_vector(Vector2(a.yaw, a.pitch)).is_equal(Vector2(b.yaw, b.pitch))
	assert_bool(a.to_basis().is_equal_approx(b.to_basis())).is_true()


# --- port ---------------------------------------------------------------------

class FakeInput extends PlayerInputPort:
	var delta: Vector2 = Vector2.ZERO

	func context() -> InputTypes.Context:
		return InputTypes.Context.EXPLORACION

	func move_vector() -> Vector2:
		return Vector2.ZERO

	func look_delta_deg() -> Vector2:
		return delta


func test_port_fake_feeds_look_in_degrees() -> void:
	var input: FakeInput = FakeInput.new()
	input.delta = Vector2(0.0, 10.0)
	var look: Look = _look()
	look.apply_input_deg(input.look_delta_deg())
	assert_float(rad_to_deg(look.pitch)).is_equal_approx(10.0, 0.001)
