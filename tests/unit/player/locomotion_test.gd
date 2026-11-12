extends GdUnitTestSuite
## PJ-002 (T-U1 of ADR-0012): Locomotion F1/F2 in the body frame. AC-01, AC-02, AC-03, AC-45, AC-04 (b). TR-player-006.
## Pure maths: no node, no physics. The config is the real player.json (no magic numbers beyond the AC ones).

const PLAYER_FULL: String = "res://assets/data/player/player.json"
const TOL: float = 0.002
const DT: float = 1.0 / 60.0


func _cfg() -> PlayerConfig:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAYER_FULL))
	return PlayerConfig.from_dict(parsed as Dictionary)


func _assert_v2(actual: Vector2, ex: float, ey: float) -> void:
	assert_float(actual.x).is_equal_approx(ex, TOL)
	assert_float(actual.y).is_equal_approx(ey, TOL)


## Runs `n` ticks of F2 toward `v_obj`; returns the final velocity.
func _run(cfg: PlayerConfig, v: Vector2, v_obj: Vector2, n: int) -> Vector2:
	for i: int in n:
		v = Locomotion.accelerate(v, v_obj, cfg, DT)
	return v


## Ticks until `done.call(v)` is true (max 100); returns the step count, or -1.
func _steps_until(cfg: PlayerConfig, v: Vector2, v_obj: Vector2, done: Callable) -> int:
	for i: int in range(1, 101):
		v = Locomotion.accelerate(v, v_obj, cfg, DT)
		if done.call(v):
			return i
	return -1


# --- AC-01: F1 ---------------------------------------------------------------

func test_target_forward_is_v_paseo() -> void:
	_assert_v2(Locomotion.target(Vector2(0, 1), _cfg()), 0.0, 1.6)


func test_target_backward_is_scaled_by_k_atras() -> void:
	_assert_v2(Locomotion.target(Vector2(0, -1), _cfg()), 0.0, -1.28)


func test_target_diagonal_keeps_modulus_v_paseo() -> void:
	var t: Vector2 = Locomotion.target(Vector2(0.7071, 0.7071), _cfg())
	_assert_v2(t, 1.131, 1.131)
	assert_float(t.length()).is_equal_approx(1.6, TOL)


func test_target_overlong_input_is_normalised() -> void:
	var t: Vector2 = Locomotion.target(Vector2(1, 1), _cfg())
	_assert_v2(t, 1.131, 1.131)
	assert_float(t.length()).is_equal_approx(1.6, TOL)


func test_target_half_stick_is_half_speed() -> void:
	_assert_v2(Locomotion.target(Vector2(0, 0.5), _cfg()), 0.0, 0.8)


func test_target_zero_input_is_zero() -> void:
	assert_vector(Locomotion.target(Vector2.ZERO, _cfg())).is_equal(Vector2.ZERO)


func test_target_lateral_uses_k_lat() -> void:
	var cfg: PlayerConfig = _cfg()
	cfg.k_lat = 0.7
	_assert_v2(Locomotion.target(Vector2(1, 0), cfg), 1.6 * 0.7, 0.0)


func test_target_backward_diagonal_scales_only_the_backward_component() -> void:
	var t: Vector2 = Locomotion.target(Vector2(1, -1), _cfg())
	_assert_v2(t, 1.131, -1.131 * 0.8)


# --- AC-04 (b): NaN / infinity ---------------------------------------------------

func test_target_nan_input_is_zero() -> void:
	assert_vector(Locomotion.target(Vector2(NAN, 1.0), _cfg())).is_equal(Vector2.ZERO)
	assert_vector(Locomotion.target(Vector2(0.0, NAN), _cfg())).is_equal(Vector2.ZERO)


func test_target_infinite_input_is_zero() -> void:
	assert_vector(Locomotion.target(Vector2(INF, 0.0), _cfg())).is_equal(Vector2.ZERO)
	assert_vector(Locomotion.target(Vector2(0.0, -INF), _cfg())).is_equal(Vector2.ZERO)


func test_sanitize_move_passes_finite_values_through() -> void:
	assert_vector(Locomotion.sanitize_move(Vector2(0.25, -0.5))).is_equal(Vector2(0.25, -0.5))


func test_sanitize_move_nan_returns_zero() -> void:
	assert_vector(Locomotion.sanitize_move(Vector2(NAN, NAN))).is_equal(Vector2.ZERO)


# --- AC-02: start and stop ---------------------------------------------------------

func test_start_from_rest_reaches_v_paseo_in_12_steps_covering_0_173_m() -> void:
	var cfg: PlayerConfig = _cfg()
	var v: Vector2 = Vector2.ZERO
	var dist: float = 0.0
	var v_obj: Vector2 = Locomotion.target(Vector2(0, 1), cfg)
	for i: int in 12:
		v = Locomotion.accelerate(v, v_obj, cfg, DT)
		dist += v.length() * DT
	_assert_v2(v, 0.0, 1.6)
	assert_float(dist).is_equal_approx(0.173, TOL)


func test_release_stops_in_9_steps_covering_0_107_m() -> void:
	var cfg: PlayerConfig = _cfg()
	var v: Vector2 = Vector2(0, 1.6)
	var dist: float = 0.0
	for i: int in 9:
		v = Locomotion.accelerate(v, Vector2.ZERO, cfg, DT)
		dist += v.length() * DT
	assert_float(v.length()).is_less(TOL)
	assert_float(dist).is_equal_approx(0.107, TOL)


func test_release_is_not_finished_one_step_early() -> void:
	var v: Vector2 = _run(_cfg(), Vector2(0, 1.6), Vector2.ZERO, 8)
	assert_float(v.length()).is_greater(0.1)


# --- AC-03: yaw ----------------------------------------------------------------------

func test_yaw_change_rotates_world_velocity_in_the_same_tick_without_losing_modulus() -> void:
	var cfg: PlayerConfig = _cfg()
	var v: Vector2 = Vector2(0, 1.6)
	var v_obj: Vector2 = Locomotion.target(Vector2(0, 1), cfg)
	var before: Vector2 = Locomotion.to_world(Locomotion.accelerate(v, v_obj, cfg, DT), 0.0)
	var after: Vector2 = Locomotion.to_world(Locomotion.accelerate(v, v_obj, cfg, DT), deg_to_rad(90.0))
	assert_float(after.length()).is_equal_approx(before.length(), 0.0001)
	assert_float(absf(rad_to_deg(before.angle_to(after)))).is_equal_approx(90.0, 0.01)


func test_to_world_matches_basis_rotation_about_up() -> void:
	var yaw: float = 0.7
	var v: Vector2 = Vector2(0.4, 1.2)
	var expected: Vector3 = Basis(Vector3.UP, yaw) * Vector3(v.x, 0.0, -v.y)
	var w: Vector2 = Locomotion.to_world(v, yaw)
	assert_float(w.x).is_equal_approx(expected.x, 0.0001)
	assert_float(w.y).is_equal_approx(expected.z, 0.0001)


func test_to_world_yaw_zero_forward_is_minus_z() -> void:
	_assert_v2(Locomotion.to_world(Vector2(0, 1.6), 0.0), 0.0, -1.6)


func test_to_body_is_the_inverse_of_to_world() -> void:
	var v: Vector2 = Vector2(0.3, -0.9)
	for yaw: float in [0.0, 0.5, -2.0, PI, 5.5]:
		var back: Vector2 = Locomotion.to_body(Locomotion.to_world(v, yaw), yaw)
		assert_float(back.x).is_equal_approx(v.x, 0.0001)
		assert_float(back.y).is_equal_approx(v.y, 0.0001)


func test_to_body_adopts_a_slid_velocity() -> void:
	# Wall at yaw 0 head-on: world velocity along -Z removed -> body velocity 0.
	assert_vector(Locomotion.to_body(Vector2.ZERO, 1.0)).is_equal(Vector2.ZERO)
	# Tangent only (world X) at yaw 0 is body-lateral.
	_assert_v2(Locomotion.to_body(Vector2(1.1, 0.0), 0.0), 1.1, 0.0)


# --- AC-45: braking rule ---------------------------------------------------------------

func test_reversal_follows_the_reference_table() -> void:
	var cfg: PlayerConfig = _cfg()
	var v: Vector2 = Vector2(0, 1.6)
	var v_obj: Vector2 = Locomotion.target(Vector2(0, -1), cfg)
	var expected: Array[float] = [1.422, 1.244, 1.067, 0.889, 0.711, 0.533, 0.356, 0.178, 0.0, -0.133]
	for i: int in expected.size():
		v = Locomotion.accelerate(v, v_obj, cfg, DT)
		assert_float(v.y).is_equal_approx(expected[i], TOL)


func test_reversal_crosses_zero_at_9_steps_and_reaches_target_at_19() -> void:
	var cfg: PlayerConfig = _cfg()
	var v_obj: Vector2 = Locomotion.target(Vector2(0, -1), cfg)
	var zero_at: int = _steps_until(cfg, Vector2(0, 1.6), v_obj, func(v: Vector2) -> bool: return v.y < TOL)
	var target_at: int = _steps_until(cfg, Vector2(0, 1.6), v_obj, func(v: Vector2) -> bool: return v.y < -1.28 + TOL)
	assert_int(zero_at).is_equal(9)
	assert_int(target_at).is_equal(19)


func test_lateral_to_forward_arrives_in_17_steps_with_acceleration_rate() -> void:
	var cfg: PlayerConfig = _cfg()
	var v_obj: Vector2 = Locomotion.target(Vector2(0, 1), cfg)
	var v: Vector2 = Vector2(1.6, 0)
	assert_bool(Locomotion.brake_applies(v, v_obj)).is_false()
	var steps: int = _steps_until(cfg, v, v_obj, func(c: Vector2) -> bool: return c.distance_to(Vector2(0, 1.6)) < TOL)
	assert_int(steps).is_equal(17)


func test_stop_from_full_speed_takes_9_steps() -> void:
	var cfg: PlayerConfig = _cfg()
	var steps: int = _steps_until(cfg, Vector2(0, 1.6), Vector2.ZERO, func(v: Vector2) -> bool: return v.length() < TOL)
	assert_int(steps).is_equal(9)


func test_brake_rule_boundaries() -> void:
	assert_bool(Locomotion.brake_applies(Vector2(0, 1.0), Vector2(0, -1.0))).is_true()
	assert_bool(Locomotion.brake_applies(Vector2(0, 1.0), Vector2(0, 0.5))).is_true()
	assert_bool(Locomotion.brake_applies(Vector2(0, 0.5), Vector2(0, 1.0))).is_false()
	assert_bool(Locomotion.brake_applies(Vector2.ZERO, Vector2.ZERO)).is_false()
	# Within the 0.001 tolerance neither condition holds.
	assert_bool(Locomotion.brake_applies(Vector2(0, 1.0), Vector2(0, 0.9995))).is_false()


# --- limits and invalid inputs ----------------------------------------------------------

func test_accelerate_never_overshoots_the_target() -> void:
	var cfg: PlayerConfig = _cfg()
	var v: Vector2 = Locomotion.accelerate(Vector2(0, 1.59), Vector2(0, 1.6), cfg, 1.0)
	_assert_v2(v, 0.0, 1.6)


func test_accelerate_with_invalid_dt_returns_velocity_unchanged() -> void:
	var cfg: PlayerConfig = _cfg()
	var v: Vector2 = Vector2(0, 1.0)
	assert_vector(Locomotion.accelerate(v, Vector2.ZERO, cfg, 0.0)).is_equal(v)
	assert_vector(Locomotion.accelerate(v, Vector2.ZERO, cfg, -0.1)).is_equal(v)
	assert_vector(Locomotion.accelerate(v, Vector2.ZERO, cfg, NAN)).is_equal(v)


func test_target_follows_a_changed_v_paseo_from_data() -> void:
	var cfg: PlayerConfig = _cfg()
	cfg.v_paseo = 2.0
	_assert_v2(Locomotion.target(Vector2(0, 1), cfg), 0.0, 2.0)
