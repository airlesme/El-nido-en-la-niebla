extends GdUnitTestSuite
## StuckGuard (PJ-008, ADR-0012 D8, GDD 2 D-23; AC-40, T-U11): the criterion, not an engine signal.

const DT: float = 1.0 / 60.0
const ANCHOR: Vector3 = Vector3(1.0, 0.0, 2.0)


class FakeProbe extends PenetrationProbe:
	var result: bool = false
	var calls: int = 0
	var last_center: Vector3 = Vector3.ZERO

	func is_penetrating(capsule_center: Vector3) -> bool:
		calls += 1
		last_center = capsule_center
		return result


var _probe: FakeProbe
var _guard: StuckGuard
var _now: float = 0.0


func before_test() -> void:
	var cfg: PlayerConfig = PlayerConfig.new()
	cfg.t_atasco = 0.5
	cfg.t_pose_segura = 0.25
	cfg.y_min = -2.0
	cfg.eps_atasco_m = 0.02
	cfg.altura_capsula = 1.75
	_probe = FakeProbe.new()
	_guard = StuckGuard.new(cfg, _probe)
	_guard.reset(ANCHOR)
	_now = 0.0


## Advances `n` ticks at `pos`; returns the tick index (1-based) that fired, or 0.
func _run(n: int, pos: Vector3, on_floor: bool = true, step_len: float = 0.0) -> int:
	for i in n:
		_now += DT
		if _guard.tick(pos, step_len, on_floor, _now):
			return i + 1
	return 0


func test_penetrating_and_still_for_half_second_relocates_to_anchor_without_safe_pose() -> void:
	_probe.result = true
	assert_int(_run(60, Vector3(5, 0, 5))).is_greater(0)
	assert_vector(_guard.safe_pose()).is_equal(ANCHOR)


func test_fires_at_t_atasco_not_before() -> void:
	_probe.result = true
	# tick 1 starts the window; fires once 0.5 s have elapsed -> tick 31
	assert_int(_run(30, Vector3(5, 0, 5))).is_equal(0)
	assert_int(_run(1, Vector3(5, 0, 5))).is_equal(1)


func test_pushing_a_wall_without_penetration_never_relocates() -> void:
	_probe.result = false
	assert_int(_run(600, Vector3(5, 0, 5))).is_equal(0)


func test_penetration_interrupted_resets_the_timer() -> void:
	_probe.result = true
	_run(25, Vector3(5, 0, 5))
	_probe.result = false
	_run(1, Vector3(5, 0, 5))
	_probe.result = true
	assert_int(_run(25, Vector3(5, 0, 5))).is_equal(0)


func test_displacement_over_eps_resets_the_timer() -> void:
	_probe.result = true
	_run(25, Vector3(5, 0, 5))
	assert_int(_run(1, Vector3(5.03, 0, 5))).is_equal(0)
	assert_int(_run(25, Vector3(5.03, 0, 5))).is_equal(0)
	assert_int(_run(10, Vector3(5.03, 0, 5))).is_greater(0)


func test_displacement_below_eps_does_not_reset_the_timer() -> void:
	_probe.result = true
	_run(20, Vector3(5, 0, 5))
	assert_int(_run(40, Vector3(5.01, 0, 5))).is_greater(0)


func test_large_single_step_resets_even_if_position_returns() -> void:
	_probe.result = true
	_run(25, Vector3(5, 0, 5))
	_run(1, Vector3(5, 0, 5), true, 0.05)
	assert_int(_run(25, Vector3(5, 0, 5))).is_equal(0)


func test_falling_below_y_min_relocates_even_without_penetration() -> void:
	assert_bool(_guard.tick(Vector3(0, -2.01, 0), 0.0, false, 0.1)).is_true()
	assert_vector(_guard.safe_pose()).is_equal(ANCHOR)


func test_y_equal_to_y_min_does_not_relocate() -> void:
	assert_bool(_guard.tick(Vector3(0, -2.0, 0), 0.0, false, 0.1)).is_false()


func test_safe_pose_is_recorded_on_floor_and_used_for_relocation() -> void:
	_run(1, Vector3(3, 0, 3))
	assert_bool(_guard.has_safe_pose()).is_true()
	assert_bool(_guard.tick(Vector3(3, -5, 3), 0.0, false, _now + DT)).is_true()
	assert_vector(_guard.safe_pose()).is_equal(Vector3(3, 0, 3))


func test_safe_pose_is_not_recorded_in_the_air() -> void:
	_run(10, Vector3(3, 1, 3), false)
	assert_bool(_guard.has_safe_pose()).is_false()


func test_safe_pose_is_not_recorded_while_penetrating() -> void:
	_probe.result = true
	_run(10, Vector3(3, 0, 3))
	assert_bool(_guard.has_safe_pose()).is_false()


func test_safe_pose_cadence_follows_t_pose_segura() -> void:
	_run(1, Vector3(1, 0, 0))
	_run(5, Vector3(2, 0, 0))
	# 0.083 s later: still the first pose
	assert_vector(_guard.safe_pose()).is_equal(Vector3(1, 0, 0))
	_run(15, Vector3(3, 0, 0))
	# > 0.25 s since the first record: refreshed
	assert_float(_guard.safe_pose().x).is_greater_equal(2.0)


func test_stuck_relocates_to_last_safe_pose_when_present() -> void:
	_run(1, Vector3(3, 0, 3))
	_probe.result = true
	assert_int(_run(60, Vector3(6, 0, 6))).is_greater(0)
	assert_vector(_guard.safe_pose()).is_equal(Vector3(3, 0, 3))


func test_reset_drops_safe_pose_and_sets_new_anchor() -> void:
	_run(1, Vector3(3, 0, 3))
	_guard.reset(Vector3(9, 0, 9))
	assert_bool(_guard.has_safe_pose()).is_false()
	assert_vector(_guard.safe_pose()).is_equal(Vector3(9, 0, 9))


func test_probe_is_queried_once_per_tick_at_capsule_center() -> void:
	_run(1, Vector3(1, 0.5, 1))
	assert_int(_probe.calls).is_equal(1)
	assert_vector(_probe.last_center).is_equal_approx(Vector3(1, 0.5 + 0.875, 1), Vector3(1e-5, 1e-5, 1e-5))


func test_after_relocation_stuck_state_is_cleared() -> void:
	_probe.result = true
	_run(60, Vector3(5, 0, 5))
	assert_int(_run(30, Vector3(5, 0, 5))).is_equal(0)
