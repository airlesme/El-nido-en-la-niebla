extends GdUnitTestSuite
## BobMath (PJ-005, ADR-0012 D3, GDD 2 F3). Pure math; config built in memory, clock injected as numbers.

const TICK: float = 1.0 / 60.0
const EPS: float = 0.000001


func _cfg() -> PlayerConfig:
	var c: PlayerConfig = PlayerConfig.new()
	c.l_paso = 0.75
	c.a_v = 0.015
	c.a_h = 0.010
	c.g_completo = 1.0
	c.g_reducido = 0.5
	c.t_cambio_balanceo = 0.25
	c.v_paseo = 1.6
	return c


func test_ninguno_offset_is_exactly_zero_everywhere() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	bob.configure(cfg, &"ninguno", 0.0)
	var g: float = bob.gain(5.0)

	for i in 200:
		var o: Vector3 = BobMath.offset(float(i) * 0.0371, 1.0, g, cfg)
		assert_bool(o == Vector3.ZERO).is_true()
		assert_float(o.x).is_equal(0.0)
		assert_float(o.y).is_equal(0.0)
		assert_float(o.z).is_equal(0.0)


func test_completo_at_footfall_matches_gdd_example() -> void:
	var cfg: PlayerConfig = _cfg()

	var o: Vector3 = BobMath.offset(0.375, 1.0, 1.0, cfg)

	assert_float(o.y).is_equal_approx(-0.015, EPS)
	assert_float(o.x).is_equal_approx(0.010, EPS)
	assert_float(o.z).is_equal(0.0)


func test_reducido_at_footfall_halves_vertical() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	bob.configure(cfg, &"reducido", 0.0)

	var o: Vector3 = BobMath.offset(0.375, 1.0, bob.gain(0.0), cfg)

	assert_float(o.y).is_equal_approx(-0.0075, EPS)


func test_zero_ratio_gives_zero_offset() -> void:
	var o: Vector3 = BobMath.offset(0.375, 0.0, 1.0, _cfg())

	assert_bool(o == Vector3.ZERO).is_true()


func test_ratio_is_clamped_to_unit_range() -> void:
	var cfg: PlayerConfig = _cfg()

	assert_vector(BobMath.offset(0.375, 7.0, 1.0, cfg)).is_equal_approx(BobMath.offset(0.375, 1.0, 1.0, cfg), Vector3.ONE * EPS)
	assert_bool(BobMath.offset(0.375, -3.0, 1.0, cfg) == Vector3.ZERO).is_true()


func test_non_finite_input_returns_zero() -> void:
	var cfg: PlayerConfig = _cfg()

	assert_bool(BobMath.offset(NAN, 1.0, 1.0, cfg) == Vector3.ZERO).is_true()
	assert_bool(BobMath.offset(0.3, INF, 1.0, cfg) == Vector3.ZERO).is_true()
	assert_bool(BobMath.offset(0.3, 1.0, NAN, cfg) == Vector3.ZERO).is_true()
	assert_bool(BobMath.offset(0.3, 1.0, 1.0, null) == Vector3.ZERO).is_true()


func test_invalid_l_paso_returns_zero() -> void:
	var cfg: PlayerConfig = _cfg()
	cfg.l_paso = 0.0

	assert_bool(BobMath.offset(0.3, 1.0, 1.0, cfg) == Vector3.ZERO).is_true()


func test_vertical_has_period_one_step_and_lateral_two_steps() -> void:
	var cfg: PlayerConfig = _cfg()

	var a: Vector3 = BobMath.offset(0.2, 1.0, 1.0, cfg)
	var b: Vector3 = BobMath.offset(0.2 + 0.75, 1.0, 1.0, cfg)
	var c: Vector3 = BobMath.offset(0.2 + 1.5, 1.0, 1.0, cfg)

	assert_float(b.y).is_equal_approx(a.y, EPS)
	assert_float(b.x).is_equal_approx(-a.x, EPS)
	assert_float(c.x).is_equal_approx(a.x, EPS)


func test_stalled_against_wall_offset_stays_zero() -> void:
	# d does not advance and r = 0: constant, zero offset on every tick.
	var cfg: PlayerConfig = _cfg()

	for i in 30:
		assert_bool(BobMath.offset(0.0, 0.0, 1.0, cfg) == Vector3.ZERO).is_true()


func test_release_mid_stride_fades_to_zero_within_nine_ticks_without_ratio_jump() -> void:
	var cfg: PlayerConfig = _cfg()
	var d: float = 0.1
	var prev_r: float = 1.0
	var last: Vector3 = Vector3.ONE
	for k in range(1, 10):
		var r: float = 1.0 - float(k) / 9.0
		d += cfg.v_paseo * r * TICK
		# Jump caused by the fall of r alone (same phase): must stay <= 2 mm per tick.
		var jump: float = (BobMath.offset(d, r, 1.0, cfg) - BobMath.offset(d, prev_r, 1.0, cfg)).length()
		assert_float(jump).is_less_equal(0.002)
		prev_r = r
		last = BobMath.offset(d, r, 1.0, cfg)

	assert_bool(last == Vector3.ZERO).is_true()


func test_level_ramp_reducido_to_completo_takes_quarter_second() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	var t0: float = 10.0
	bob.configure(cfg, &"reducido", t0)
	assert_float(bob.gain(t0)).is_equal(0.5)

	assert_bool(bob.set_level(&"completo", t0)).is_true()

	assert_float(bob.gain(t0)).is_equal_approx(0.5, EPS)
	assert_float(bob.gain(t0 + 0.125)).is_equal_approx(0.75, EPS)
	assert_float(bob.gain(t0 + 0.25)).is_equal(1.0)
	assert_float(bob.gain(t0 + 5.0)).is_equal(1.0)
	# Offset jump per tick caused by g alone (same d, r = 1) stays <= 2 mm.
	var prev_g: float = bob.gain(t0)
	for k in range(1, 16):
		var g: float = bob.gain(t0 + float(k) * TICK)
		var jump: float = (BobMath.offset(0.375, 1.0, g, cfg) - BobMath.offset(0.375, 1.0, prev_g, cfg)).length()
		assert_float(jump).is_less_equal(0.002)
		prev_g = g
	assert_float(prev_g).is_equal(1.0)


func test_level_ramp_to_ninguno_ends_exactly_zero() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	bob.configure(cfg, &"completo", 0.0)

	bob.set_level(&"ninguno", 1.0)

	assert_float(bob.gain(1.125)).is_equal_approx(0.5, EPS)
	assert_float(bob.gain(1.25)).is_equal(0.0)
	assert_bool(BobMath.offset(0.375, 1.0, bob.gain(2.0), cfg) == Vector3.ZERO).is_true()


func test_level_change_mid_ramp_starts_from_current_gain() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	bob.configure(cfg, &"reducido", 0.0)
	bob.set_level(&"completo", 0.0)
	var mid: float = bob.gain(0.125)

	bob.set_level(&"ninguno", 0.125)

	assert_float(bob.gain(0.125)).is_equal_approx(mid, EPS)
	assert_float(bob.gain(0.375)).is_equal(0.0)


func test_frozen_clock_freezes_ramp() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	bob.configure(cfg, &"reducido", 0.0)
	bob.set_level(&"completo", 0.0)

	# Paused: the injected game time does not advance.
	assert_float(bob.gain(0.1)).is_equal(bob.gain(0.1))
	assert_float(bob.gain(0.1)).is_less(1.0)


func test_unknown_level_is_rejected_and_state_kept() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()

	assert_bool(bob.set_level(&"completo", 0.0)).is_false() # before configure
	assert_bool(bob.configure(cfg, &"turbo", 0.0)).is_false()
	assert_bool(bob.configure(null, &"completo", 0.0)).is_false()
	bob.configure(cfg, &"reducido", 0.0)
	assert_bool(bob.set_level(&"turbo", 1.0)).is_false()
	assert_float(bob.gain(2.0)).is_equal(0.5)


func test_gain_before_configure_is_zero() -> void:
	assert_float(BobMath.new().gain(1.0)).is_equal(0.0)


func test_gain_with_non_finite_time_returns_target() -> void:
	var cfg: PlayerConfig = _cfg()
	var bob: BobMath = BobMath.new()
	bob.configure(cfg, &"completo", 0.0)

	assert_float(bob.gain(NAN)).is_equal(1.0)
