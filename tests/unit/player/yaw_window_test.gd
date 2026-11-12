extends GdUnitTestSuite
## YawWindow (PJ-007, ADR-0012 D7, GDD 2 F8; AC-37, T-U9): accumulated turn over the last T_giro seconds.

const F: int = 60
const T_GIRO: float = 0.5


## Turns `ticks` ticks at `deg_per_s`, starting from yaw 0.
func _turn(w: YawWindow, deg_per_s: float, ticks: int, start_yaw: float = 0.0) -> void:
	var step: float = deg_to_rad(deg_per_s) / float(F)
	for k in range(1, ticks + 1):
		w.record_tick(start_yaw + step * float(k))


func test_capacity_for_default_config_is_30() -> void:
	assert_int(YawWindow.new(0.5, 60).capacity()).is_equal(30)


func test_turn_60_deg_per_s_for_half_second_is_30_degrees() -> void:
	var w: YawWindow = YawWindow.new(T_GIRO, F)
	w.reset(0.0)

	_turn(w, 60.0, 30)

	assert_float(rad_to_deg(w.giro_acumulado())).is_equal_approx(30.0, 0.5)


func test_at_rest_is_zero() -> void:
	var w: YawWindow = YawWindow.new(T_GIRO, F)
	w.reset(1.0)

	for k in 60:
		w.record_tick(1.0)

	assert_float(w.giro_acumulado()).is_equal(0.0)


func test_reset_zeroes_the_window() -> void:
	var w: YawWindow = YawWindow.new(T_GIRO, F)
	w.reset(0.0)
	_turn(w, 60.0, 30)

	w.reset(0.0)

	assert_float(w.giro_acumulado()).is_equal(0.0)


func test_old_turn_leaves_the_window() -> void:
	var w: YawWindow = YawWindow.new(T_GIRO, F)
	w.reset(0.0)
	_turn(w, 60.0, 30)

	for k in 30:
		w.record_tick(deg_to_rad(30.0))

	assert_float(w.giro_acumulado()).is_equal_approx(0.0, 0.00001)


func test_turn_direction_does_not_matter() -> void:
	var w: YawWindow = YawWindow.new(T_GIRO, F)
	w.reset(0.0)

	_turn(w, -60.0, 30)

	assert_float(rad_to_deg(w.giro_acumulado())).is_equal_approx(30.0, 0.5)


func test_crossing_the_pi_seam_counts_the_short_arc() -> void:
	var w: YawWindow = YawWindow.new(T_GIRO, F)
	w.reset(PI - 0.01)

	w.record_tick(-PI + 0.01)

	assert_float(w.giro_acumulado()).is_equal_approx(0.02, 0.0001)


func test_degenerate_config_keeps_a_one_slot_ring() -> void:
	var w: YawWindow = YawWindow.new(0.0, 0)
	w.reset(0.0)

	w.record_tick(0.1)

	assert_int(w.capacity()).is_equal(1)
	assert_float(w.giro_acumulado()).is_equal_approx(0.1, 0.00001)
