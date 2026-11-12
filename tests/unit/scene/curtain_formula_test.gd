extends GdUnitTestSuite
## CP-003 (T-U4 of ADR-0003): CurtainMath, GDD 4 F1. AC-F1, TR-scene-014, TR-scene-015. Pure maths, no engine time.

const TOL: float = 0.0001


func _transitions() -> LoadTransitions:
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": 2, "delta_max_s": 0.1, "delta_ref_s": 1.0 / 30.0,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {
			"recepcion": {"d_out": 0.8, "d_in": 0.8},
			"cierre": {"d_out": 0.8},
		},
	})


func test_alpha_out_from_clear_is_half_at_half_duration() -> void:
	assert_float(CurtainMath.alpha_out(0.0, 0.4, 0.8)).is_equal_approx(0.5, TOL)


func test_alpha_out_from_partial_alpha() -> void:
	assert_float(CurtainMath.alpha_out(0.6, 0.4, 0.8)).is_equal_approx(0.8, TOL)


func test_alpha_in_at_quarter_duration() -> void:
	assert_float(CurtainMath.alpha_in(0.2, 0.8)).is_equal_approx(0.84375, TOL)


func test_alpha_bounds_clamp_outside_the_fade() -> void:
	assert_float(CurtainMath.alpha_out(0.0, -1.0, 0.8)).is_equal_approx(0.0, TOL)
	assert_float(CurtainMath.alpha_out(0.0, 5.0, 0.8)).is_equal_approx(1.0, TOL)
	assert_float(CurtainMath.alpha_in(5.0, 0.8)).is_equal_approx(0.0, TOL)
	assert_float(CurtainMath.alpha_in(-1.0, 0.8)).is_equal_approx(1.0, TOL)


func test_zero_or_negative_duration_skips_without_division() -> void:
	assert_float(CurtainMath.alpha_out(0.0, 0.0, 0.0)).is_equal(1.0)
	assert_float(CurtainMath.alpha_out(0.3, 0.0, -1.0)).is_equal(1.0)
	assert_float(CurtainMath.alpha_in(0.0, 0.0)).is_equal(0.0)
	var c: CurtainMath = CurtainMath.new()
	c.begin_out(0.0)
	assert_bool(c.step_out(0.016, 0.1, 0.0)).is_true()
	assert_float(c.alpha).is_equal(1.0)
	c.begin_in()
	assert_bool(c.step_in(0.016, 0.1, 0.0)).is_true()
	assert_float(c.alpha).is_equal(0.0)


func test_alpha_zero_already_black_skips_darkening() -> void:
	var c: CurtainMath = CurtainMath.new()
	c.begin_out(1.0)
	assert_bool(c.step_out(0.0, 0.1, 0.8)).is_true()
	assert_float(c.alpha).is_equal(1.0)
	assert_float(c.elapsed_s).is_equal(0.0)


func test_frame_time_is_clipped_to_delta_max() -> void:
	assert_float(CurtainMath.advance_t(0.0, 0.5, 0.1)).is_equal_approx(0.1, TOL)
	assert_float(CurtainMath.advance_t(0.2, 0.02, 0.1)).is_equal_approx(0.22, TOL)
	assert_float(CurtainMath.advance_t(0.2, -1.0, 0.1)).is_equal_approx(0.2, TOL)
	var c: CurtainMath = CurtainMath.new()
	c.begin_out(0.0)
	assert_bool(c.step_out(0.5, 0.1, 0.8)).is_false()
	assert_float(c.elapsed_s).is_equal_approx(0.1, TOL)


func test_stepper_darkens_and_lightens_to_the_ends() -> void:
	var c: CurtainMath = CurtainMath.new()
	c.begin_out(0.0)
	var frames: int = 0
	while not c.step_out(0.1, 0.1, 0.8) and frames < 100:
		frames += 1
	assert_int(frames).is_equal(7)
	assert_float(c.alpha).is_equal(1.0)
	assert_int(c.phase).is_equal(CurtainMath.Phase.DARK)
	c.begin_in()
	frames = 0
	while not c.step_in(0.1, 0.1, 0.8) and frames < 100:
		frames += 1
	assert_int(frames).is_equal(7)
	assert_float(c.alpha).is_equal(0.0)
	assert_int(c.phase).is_equal(CurtainMath.Phase.CLEAR)


func test_step_in_wrong_phase_does_nothing() -> void:
	var c: CurtainMath = CurtainMath.new()
	assert_bool(c.step_in(0.1, 0.1, 0.8)).is_false()
	assert_bool(c.step_out(0.1, 0.1, 0.8)).is_false()
	assert_float(c.alpha).is_equal(0.0)


func test_reduced_motion_uses_fixed_duration_for_every_motivo() -> void:
	var t: LoadTransitions = _transitions()
	assert_float(LoadBudget.d_out(t, &"recepcion", true)).is_equal_approx(0.1, TOL)
	assert_float(LoadBudget.d_in(t, &"recepcion", true)).is_equal_approx(0.1, TOL)
	assert_float(LoadBudget.d_out(t, &"cierre", true)).is_equal_approx(0.1, TOL)
	assert_float(LoadBudget.d_in(t, &"cierre", true)).is_equal(0.0)
	assert_float(LoadBudget.d_out(t, &"recepcion", false)).is_equal_approx(0.8, TOL)
	assert_float(CurtainMath.alpha_out(0.0, 0.05, LoadBudget.d_out(t, &"recepcion", true))).is_equal_approx(0.5, TOL)
