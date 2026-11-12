extends GdUnitTestSuite
## EC-008: F1 (radial dead zone), F2 (mouse look), F3 (stick look) as pure maths, the polls
## `get_move_vector` / `consume_look_delta` of the router, and the load-time rejection of `dz_in` < 0.05.
## AC-F1, AC-F2, AC-F3, AC-09. Environment-independent: no wall time, no frame counts.

const SHIPPED: String = "res://assets/data/input/default_bindings.json"
const TOL: float = 0.001
const DZ_IN: float = 0.15
const DZ_OUT: float = 0.05
const OMEGA: float = 120.0
const P: float = 1.5


func _ctx(store: MemoryFileStore, fatal: RecordingFatalHandler) -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = RecordingLog.new()
	c.flavor = BuildFlavor.new(true)
	c.fatal = fatal
	c.files = store
	c.freeze()
	return c


func _table() -> BindingTable:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(SHIPPED, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = BindingTable.new()
	assert_int(t.load_defaults(_ctx(store, RecordingFatalHandler.new()))).is_equal(OK)
	return t


func _router() -> InputRouter:
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_table(_table())
	return router


func _axis(code: int, value: float) -> InputTypes.RawInput:
	var raw: InputTypes.RawInput = InputTypes.RawInput.new()
	raw.kind = InputTypes.RawKind.PAD_AXIS
	raw.code = code
	raw.value = value
	return raw


func _motion(px: Vector2) -> InputTypes.RawInput:
	var raw: InputTypes.RawInput = InputTypes.RawInput.new()
	raw.kind = InputTypes.RawKind.MOUSE_MOTION
	raw.motion = px
	return raw


func _key(code: int, pressed: bool) -> InputTypes.RawInput:
	var raw: InputTypes.RawInput = InputTypes.RawInput.new()
	raw.kind = InputTypes.RawKind.KEY
	raw.code = code
	raw.pressed = pressed
	return raw


# --- F1 --------------------------------------------------------------------------------------

func test_f1_example_vector_gives_0_613() -> void:
	assert_float(InputFormulas.radial_deadzone(Vector2(0.5, 0.4), DZ_IN, DZ_OUT)).is_equal_approx(0.613, TOL)


func test_f1_inside_the_inner_zone_is_zero() -> void:
	assert_float(InputFormulas.radial_deadzone(Vector2(0.15, 0.0), DZ_IN, DZ_OUT)).is_equal(0.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(0.14, 0.0), DZ_IN, DZ_OUT)).is_equal(0.0)
	assert_float(InputFormulas.radial_deadzone(Vector2.ZERO, DZ_IN, DZ_OUT)).is_equal(0.0)


func test_f1_reaches_one_at_0_95_and_stays_at_the_axis_limits() -> void:
	assert_float(InputFormulas.radial_deadzone(Vector2(0.95, 0.0), DZ_IN, DZ_OUT)).is_equal_approx(1.0, TOL)
	assert_float(InputFormulas.radial_deadzone(Vector2(1.0, 0.0), DZ_IN, DZ_OUT)).is_equal(1.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(-1.0, 1.0), DZ_IN, DZ_OUT)).is_equal(1.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(0.0, -1.0), DZ_IN, DZ_OUT)).is_equal(1.0)


func test_f1_is_radial_not_per_axis() -> void:
	# Each axis alone is inside the zone (0.1 < 0.15); |v| = 0.141 still is; (0.2, 0.2) has |v| 0.283 and is not.
	assert_float(InputFormulas.radial_deadzone(Vector2(0.1, 0.1), DZ_IN, DZ_OUT)).is_equal(0.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(0.2, 0.2), DZ_IN, DZ_OUT)).is_greater(0.0)


func test_f1_float32_axis_arrives_as_is() -> void:
	# Spike 2026-11-11: 0.03 reaches us as 0.0299999993; the zone makes it irrelevant.
	assert_float(InputFormulas.radial_deadzone(Vector2(0.0299999993, 0.0), DZ_IN, DZ_OUT)).is_equal(0.0)


func test_f1_non_finite_or_invalid_zones_give_zero() -> void:
	assert_float(InputFormulas.radial_deadzone(Vector2(NAN, 0.5), DZ_IN, DZ_OUT)).is_equal(0.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(INF, 0.0), DZ_IN, DZ_OUT)).is_equal(0.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(0.5, 0.5), 0.6, 0.4)).is_equal(0.0)
	assert_float(InputFormulas.radial_deadzone(Vector2(0.5, 0.5), NAN, 0.05)).is_equal(0.0)


func _load_with_dz_in(value: float, min_value: float) -> Array:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHIPPED)) as Dictionary
	var dz: Dictionary = (doc["tuning"] as Dictionary)["dz_in"]
	dz["value"] = value
	dz["min"] = min_value
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(SHIPPED, JSON.stringify(doc))
	var fatal: RecordingFatalHandler = RecordingFatalHandler.new()
	var err: int = BindingTable.new().load_defaults(_ctx(store, fatal))
	return [err, fatal]


func test_dz_in_below_0_05_is_rejected_on_load() -> void:
	var res: Array = _load_with_dz_in(0.04, 0.0)

	assert_int(res[0]).is_equal(ERR_INVALID_DATA)
	assert_int((res[1] as RecordingFatalHandler).calls.size()).is_equal(1)
	assert_str(str(((res[1] as RecordingFatalHandler).calls[0][&"detail"] as Dictionary)[&"param"])).is_equal("tuning.dz_in.min")


func test_dz_in_exactly_0_05_is_accepted() -> void:
	var res: Array = _load_with_dz_in(0.05, 0.05)

	assert_int(res[0]).is_equal(OK)


# --- F2 --------------------------------------------------------------------------------------

func test_f2_example_motion_gives_yaw_1_8_pitch_minus_0_6() -> void:
	var d: Vector2 = InputFormulas.mouse_look(Vector2(18.0, -6.0), 0.10, 1.0, 1)

	assert_float(d.x).is_equal_approx(1.8, TOL)
	assert_float(d.y).is_equal_approx(-0.6, TOL)


func test_f2_3600_px_is_a_full_turn_when_split_into_frames() -> void:
	var total: float = 0.0
	for i: int in 36:
		total += InputFormulas.mouse_look(Vector2(100.0, 0.0), 0.10, 1.0, 1).x

	assert_float(total).is_equal_approx(360.0, TOL)


func test_f2_same_physical_motion_gives_the_same_turn_at_30_and_144_fps() -> void:
	# 1 s of motion at 720 px/s: the sum of per-frame results does not depend on the frame rate.
	var a: float = 0.0
	for i: int in 30:
		a += InputFormulas.mouse_look(Vector2(24.0, 0.0), 0.10, 1.0, 1).x
	var b: float = 0.0
	for i: int in 144:
		b += InputFormulas.mouse_look(Vector2(5.0, 0.0), 0.10, 1.0, 1).x

	assert_float(a).is_equal_approx(b, TOL)


func test_f2_spike_is_capped_to_45_degrees_each_way() -> void:
	assert_float(InputFormulas.mouse_look(Vector2(1000.0, 0.0), 0.10, 1.0, 1).x).is_equal(45.0)
	assert_float(InputFormulas.mouse_look(Vector2(-1000.0, 1000.0), 0.10, 1.0, 1).x).is_equal(-45.0)
	assert_float(InputFormulas.mouse_look(Vector2(-1000.0, 1000.0), 0.10, 1.0, 1).y).is_equal(45.0)


func test_f2_sensitivity_and_inversion_apply() -> void:
	var d: Vector2 = InputFormulas.mouse_look(Vector2(10.0, 10.0), 0.10, 2.0, -1)

	assert_float(d.x).is_equal_approx(2.0, TOL)
	assert_float(d.y).is_equal_approx(-2.0, TOL)


func test_f2_non_finite_input_gives_zero() -> void:
	assert_vector(InputFormulas.mouse_look(Vector2(NAN, 1.0), 0.10, 1.0, 1)).is_equal(Vector2.ZERO)
	assert_vector(InputFormulas.mouse_look(Vector2(1.0, INF), 0.10, 1.0, 1)).is_equal(Vector2.ZERO)
	assert_vector(InputFormulas.mouse_look(Vector2(1.0, 1.0), NAN, 1.0, 1)).is_equal(Vector2.ZERO)


# --- F3 --------------------------------------------------------------------------------------

func test_f3_example_speed_is_57_6_deg_per_s() -> void:
	var r: float = InputFormulas.radial_deadzone(Vector2(0.5, 0.4), DZ_IN, DZ_OUT)

	assert_float(InputFormulas.stick_speed(r, OMEGA, P, 1.0)).is_equal_approx(57.6, 0.1)


func test_f3_per_frame_turn_is_0_96_at_60_fps_and_1_92_at_30() -> void:
	var v: Vector2 = Vector2(0.5, 0.4)
	var at60: Vector2 = InputFormulas.stick_look(v, DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 1.0 / 60.0)
	var at30: Vector2 = InputFormulas.stick_look(v, DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 1.0 / 30.0)

	assert_float(at60.length()).is_equal_approx(0.96, TOL)
	assert_float(at30.length()).is_equal_approx(1.92, TOL)
	assert_float(at60.normalized().dot(v.normalized())).is_equal_approx(1.0, 0.0001)


func test_f3_frame_time_is_capped_to_0_1_s() -> void:
	var v: Vector2 = Vector2(1.0, 0.0)
	var long_frame: Vector2 = InputFormulas.stick_look(v, DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.5)
	var capped: Vector2 = InputFormulas.stick_look(v, DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.1)

	assert_float(long_frame.x).is_equal_approx(capped.x, 0.0001)
	assert_float(long_frame.x).is_equal_approx(12.0, TOL)


func test_f3_worst_case_speeds_are_240_and_360() -> void:
	assert_float(InputFormulas.stick_speed(1.0, 120.0, P, 2.0)).is_equal_approx(240.0, TOL)
	assert_float(InputFormulas.stick_speed(1.0, 180.0, P, 2.0)).is_equal_approx(360.0, TOL)


func test_f3_single_axis_and_full_deflection_in_both_signs() -> void:
	var right: Vector2 = InputFormulas.stick_look(Vector2(1.0, 0.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.1)
	var down: Vector2 = InputFormulas.stick_look(Vector2(0.0, -1.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.1)

	assert_float(right.x).is_equal_approx(12.0, TOL)
	assert_float(right.y).is_equal(0.0)
	assert_float(down.y).is_equal_approx(-12.0, TOL)


func test_f3_inside_dead_zone_or_bad_delta_or_nan_gives_zero() -> void:
	assert_vector(InputFormulas.stick_look(Vector2(0.1, 0.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.016)).is_equal(Vector2.ZERO)
	assert_vector(InputFormulas.stick_look(Vector2(1.0, 0.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.0)).is_equal(Vector2.ZERO)
	assert_vector(InputFormulas.stick_look(Vector2(1.0, 0.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, -1.0)).is_equal(Vector2.ZERO)
	assert_vector(InputFormulas.stick_look(Vector2(NAN, 0.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, 0.016)).is_equal(Vector2.ZERO)
	assert_vector(InputFormulas.stick_look(Vector2(1.0, 0.0), DZ_IN, DZ_OUT, OMEGA, P, 1.0, 1, INF)).is_equal(Vector2.ZERO)
	assert_float(InputFormulas.stick_speed(NAN, OMEGA, P, 1.0)).is_equal(0.0)


func test_f3_inversion_flips_only_pitch() -> void:
	var d: Vector2 = InputFormulas.stick_look(Vector2(0.7, 0.7), DZ_IN, DZ_OUT, OMEGA, P, 1.0, -1, 0.1)

	assert_float(d.x).is_greater(0.0)
	assert_float(d.y).is_less(0.0)


# --- router polls ----------------------------------------------------------------------------

func test_ac09_router_caps_mouse_spike_and_applies_no_camera_limits() -> void:
	var router: InputRouter = _router()
	router.feed(_motion(Vector2(1000.0, 0.0)))

	var d: Vector2 = router.consume_look_delta(0.016)

	assert_float(d.x).is_equal(45.0)
	assert_float(d.y).is_equal(0.0)


func test_router_look_delta_is_plus_right_plus_up_and_consumed_once() -> void:
	var router: InputRouter = _router()
	router.feed(_motion(Vector2(18.0, -6.0)))
	router.feed(_motion(Vector2(0.0, 0.0)))

	var first: Vector2 = router.consume_look_delta(0.016)
	var second: Vector2 = router.consume_look_delta(0.016)

	assert_float(first.x).is_equal_approx(1.8, TOL)
	assert_float(first.y).is_equal_approx(0.6, TOL) # mouse up -> look up
	assert_vector(second).is_equal(Vector2.ZERO)


func test_router_accumulates_motion_between_polls() -> void:
	var router: InputRouter = _router()
	router.feed(_motion(Vector2(10.0, 0.0)))
	router.feed(_motion(Vector2(8.0, 0.0)))

	assert_float(router.consume_look_delta(0.016).x).is_equal_approx(1.8, TOL)


func test_router_stick_look_uses_delta_capped_at_0_1() -> void:
	var router: InputRouter = _router()
	router.feed(_axis(JOY_AXIS_RIGHT_X, 1.0))

	assert_float(router.consume_look_delta(0.5).x).is_equal_approx(12.0, TOL)
	assert_float(router.consume_look_delta(0.1).x).is_equal_approx(12.0, TOL)


func test_router_look_is_zero_and_discards_motion_outside_exploracion() -> void:
	var router: InputRouter = _router()
	assert_bool(router.enter(InputTypes.Context.INSPECCION, &"interaction")).is_true()
	router.feed(_motion(Vector2(50.0, 50.0)))
	router.feed(_axis(JOY_AXIS_RIGHT_X, 1.0))

	assert_vector(router.consume_look_delta(0.016)).is_equal(Vector2.ZERO)
	assert_bool(router.exit(InputTypes.Context.INSPECCION, &"interaction")).is_true()
	router.feed(_axis(JOY_AXIS_RIGHT_X, 0.0))
	assert_vector(router.consume_look_delta(0.016)).is_equal(Vector2.ZERO)


func test_router_look_settings_are_clamped_and_invert_applies() -> void:
	var router: InputRouter = _router()
	router.set_look_settings(100.0, 1.0, true, false)
	router.feed(_motion(Vector2(10.0, 10.0)))

	var d: Vector2 = router.consume_look_delta(0.016)

	assert_float(d.x).is_equal_approx(3.0, TOL)
	assert_float(d.y).is_equal_approx(3.0, TOL) # screen down inverted -> up
	router.set_look_settings(NAN, NAN, false, false)
	router.feed(_motion(Vector2(10.0, 0.0)))
	assert_float(router.consume_look_delta(0.016).x).is_equal_approx(3.0, TOL)


func test_router_move_vector_from_keys_is_normalised() -> void:
	var router: InputRouter = _router()
	router.feed(_key(KEY_W, true))

	assert_vector(router.get_move_vector()).is_equal(Vector2(0.0, 1.0))
	router.feed(_key(KEY_D, true))
	var diag: Vector2 = router.get_move_vector()
	assert_float(diag.length()).is_equal_approx(1.0, 0.0001)
	assert_float(diag.x).is_equal_approx(diag.y, 0.0001)
	router.feed(_key(KEY_W, false))
	router.feed(_key(KEY_D, false))
	assert_vector(router.get_move_vector()).is_equal(Vector2.ZERO)


func test_router_move_vector_from_left_stick_uses_own_dead_zone() -> void:
	var router: InputRouter = _router()
	router.feed(_axis(JOY_AXIS_LEFT_Y, -0.1))
	assert_vector(router.get_move_vector()).is_equal(Vector2.ZERO)

	router.feed(_axis(JOY_AXIS_LEFT_Y, -1.0))
	assert_vector(router.get_move_vector()).is_equal(Vector2(0.0, 1.0)) # up = forward

	router.feed(_axis(JOY_AXIS_LEFT_X, 1.0))
	assert_float(router.get_move_vector().length()).is_equal_approx(1.0, 0.0001)


func test_router_move_vector_is_zero_outside_exploracion_and_with_nan() -> void:
	var router: InputRouter = _router()
	router.feed(_axis(JOY_AXIS_LEFT_Y, NAN))
	assert_vector(router.get_move_vector()).is_equal(Vector2.ZERO)

	router.feed(_axis(JOY_AXIS_LEFT_Y, -1.0))
	assert_bool(router.enter(InputTypes.Context.MENU, &"menu")).is_true()
	assert_vector(router.get_move_vector()).is_equal(Vector2.ZERO)


func test_router_without_table_polls_return_zero() -> void:
	var router: InputRouter = auto_free(InputRouter.new())

	assert_vector(router.get_move_vector()).is_equal(Vector2.ZERO)
	assert_vector(router.consume_look_delta(0.016)).is_equal(Vector2.ZERO)
