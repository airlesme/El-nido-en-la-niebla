extends GdUnitTestSuite
## EC-005: safety cap of `sin control` on `GameClock` (AC-F8), `carga_en_curso` and the pending pause
## (AC-E14), stack discard on `partida_nueva` (AC-E13c/d), reset on unload (AC-E2 part L).
## The clock is a real `GameClock` driven by `advance` in 0.25 s steps (exact in binary): no wall time.

const LOADER: StringName = InputTypes.OWNER_SCENE_LOADER
const DIRECTOR: StringName = InputTypes.OWNER_SCENE_DIRECTOR
const ROUTER: StringName = InputTypes.OWNER_INPUT_ROUTER
const SIN: InputTypes.Context = InputTypes.Context.SIN_CONTROL
const MENU: InputTypes.Context = InputTypes.Context.MENU
const EXPLO: InputTypes.Context = InputTypes.Context.EXPLORACION
const STEP_S: float = 0.25
const FLAGS_PATH: String = "state/flags.json"

## ErrorPolicy double: never quits the tree, skips payload validation.
class LenientPolicy extends ErrorPolicy:
	func fail(_msg: String) -> void:
		return

	func is_strict() -> bool:
		return false


func _clock() -> GameClock:
	return auto_free(GameClock.new())


## Advances the clock `seconds` in exact quarter-second steps, polling the cap every step.
func _run(clock: GameClock, s: ContextStack, seconds: float) -> void:
	var steps: int = roundi(seconds / STEP_S)
	for i: int in steps:
		clock.advance(STEP_S)
		s.tick()


func _stack(clock: GameClock, notices: Array, log: RecordingLog = null) -> ContextStack:
	var emit: Callable = func(notice: StringName, payload: Dictionary) -> void:
		notices.append([notice, payload])
	var s: ContextStack = ContextStack.new(log, emit)
	s.set_clock(clock)
	return s


## Stack in game: [EXPLORACION] reached through a `sin control` of the director.
func _in_game_stack(clock: GameClock, notices: Array) -> ContextStack:
	var s: ContextStack = _stack(clock, notices)
	s.open_no_control(DIRECTOR, 1.0)
	s.request_exploration(DIRECTOR)
	notices.clear()
	return s


func _state_with_catalog() -> GameState:
	var c: ServiceContext = ServiceContext.new()
	c.logger = RecordingLog.new()
	c.flavor = BuildFlavor.new(false)
	c.fatal = RecordingFatalHandler.new()
	c.freeze()
	var st: GameState = auto_free(GameState.new())
	st.setup(c)
	st.set_error_policy(LenientPolicy.new())
	assert_int(st.load_catalog(FLAGS_PATH)).is_equal(OK)
	return st


# --- AC-F8: cap on GameClock, renewed on transfer --------------------------------------------

func test_cap_after_transfer_expires_at_renewed_deadline_not_at_original() -> void:
	var clock: GameClock = _clock()
	var notices: Array = []
	var s: ContextStack = _stack(clock, notices)
	s.open_no_control(LOADER, 11.67) # original cap: 13.67 s
	_run(clock, s, 9.0)
	notices.clear()

	assert_bool(s.transfer_no_control(DIRECTOR, 20.0)).is_true() # new cap: 9 + 20 + 2 = 31 s
	_run(clock, s, 4.75) # t = 13.75, past the original 13.67

	assert_int(s.top()).is_equal(SIN)
	assert_str(s.no_control_owner()).is_equal("scene_director")
	assert_array(notices).is_empty()
	_run(clock, s, 17.0) # t = 30.75
	assert_int(s.top()).is_equal(SIN)
	_run(clock, s, STEP_S) # t = 31.0: due exactly
	assert_int(s.top()).is_equal(EXPLO)


func test_cap_expiry_logs_an_error_and_closes_as_owner_with_one_notice() -> void:
	var clock: GameClock = _clock()
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(clock, notices, log)
	s.open_no_control(DIRECTOR, 1.0) # cap = 3 s
	notices.clear()

	_run(clock, s, 3.0)

	assert_int(s.top()).is_equal(EXPLO)
	assert_int(notices.size()).is_equal(1)
	assert_str(notices[0][1][&"anterior"]).is_equal("sin_control")
	assert_bool(_has_line(log, "no_control_cap_expired")).is_true()


func test_cap_does_not_advance_while_game_is_paused() -> void:
	var clock: GameClock = _clock()
	var s: ContextStack = _stack(clock, [])
	s.open_no_control(DIRECTOR, 1.0) # cap = 3 s
	clock.pause(&"pause_menu")

	_run(clock, s, 100.0)
	assert_int(s.top()).is_equal(SIN)

	clock.resume(&"pause_menu")
	_run(clock, s, 2.75)
	assert_int(s.top()).is_equal(SIN)
	_run(clock, s, STEP_S)
	assert_int(s.top()).is_equal(EXPLO)


func test_stack_without_clock_arms_no_cap() -> void:
	var s: ContextStack = ContextStack.new()
	s.open_no_control(DIRECTOR, 1.0)

	assert_bool(s.tick()).is_false()
	assert_int(s.top()).is_equal(SIN)


func test_tick_on_a_stack_without_no_control_does_nothing() -> void:
	var clock: GameClock = _clock()
	var s: ContextStack = _stack(clock, [])

	_run(clock, s, 10.0)

	assert_int(s.top()).is_equal(EXPLO)


func test_open_without_duration_uses_no_duration_plus_margin_for_the_cap() -> void:
	var clock: GameClock = _clock()
	var s: ContextStack = _stack(clock, [])
	s.set_caps(3.0, 2.0)
	s.open_no_control(DIRECTOR, 0.0) # 3 s + 2 s = 5 s

	_run(clock, s, 4.75)
	assert_int(s.top()).is_equal(SIN)
	_run(clock, s, STEP_S)
	assert_int(s.top()).is_equal(EXPLO)


func test_set_caps_ignores_non_positive_values() -> void:
	var s: ContextStack = ContextStack.new()
	s.set_caps(0.0, -1.0)

	assert_float(s.no_duration_s()).is_equal(ContextStack.FALLBACK_NO_DURATION_S)
	assert_float(s.margin_s()).is_equal(ContextStack.FALLBACK_MARGIN_S)


func test_shipped_data_provides_no_duration_and_margin() -> void:
	var c: ServiceContext = ServiceContext.new()
	c.logger = RecordingLog.new()
	c.flavor = BuildFlavor.new(true)
	c.fatal = RecordingFatalHandler.new()
	c.freeze()
	var t: BindingTable = BindingTable.new()
	assert_int(t.load_defaults(c)).is_equal(OK)
	var router: InputRouter = auto_free(InputRouter.new())

	router.use_table(t)

	assert_float(t.tuning_value(&"no_duration_cap_s")).is_equal_approx(3.0, 0.0001)
	assert_float(router.no_control_margin_s()).is_equal_approx(2.0, 0.0001)


# --- AC-E14: carga_en_curso and pending pause -------------------------------------------------

func test_opening_no_control_as_scene_loader_sets_loading() -> void:
	var s: ContextStack = _stack(_clock(), [])

	s.open_no_control(LOADER, 2.0)

	assert_bool(s.is_loading()).is_true()


func test_load_failed_unblocks_pause_and_discards_pending_pause() -> void:
	var s: ContextStack = _in_game_stack(_clock(), [])
	assert_bool(s.gate_pause(InputTypes.PauseCause.ACTION)).is_true()

	s.set_loading(true)
	assert_bool(s.gate_pause(InputTypes.PauseCause.ACTION)).is_false()
	assert_bool(s.gate_pause(InputTypes.PauseCause.FOCUS_LOST)).is_false()
	assert_int(s.pending_pause()).is_equal(InputTypes.PauseCause.FOCUS_LOST)
	s.set_loading(false, true)

	assert_int(s.pending_pause()).is_equal(-1)
	assert_bool(s.gate_pause(InputTypes.PauseCause.ACTION)).is_true()


func test_load_finished_keeps_pending_pause_for_the_pause_story() -> void:
	var s: ContextStack = _in_game_stack(_clock(), [])
	s.set_loading(true)
	s.gate_pause(InputTypes.PauseCause.PAD_LOST)

	s.set_loading(false)

	assert_bool(s.is_loading()).is_false()
	assert_int(s.take_pending_pause()).is_equal(InputTypes.PauseCause.PAD_LOST)
	assert_int(s.take_pending_pause()).is_equal(-1)


func test_pause_action_during_load_is_dropped_not_remembered() -> void:
	var s: ContextStack = _in_game_stack(_clock(), [])
	s.set_loading(true)

	s.gate_pause(InputTypes.PauseCause.ACTION)

	assert_int(s.pending_pause()).is_equal(-1)


func test_pause_outside_the_game_is_refused() -> void:
	var s: ContextStack = _stack(_clock(), [])
	s.restore_menu()

	assert_bool(s.gate_pause(InputTypes.PauseCause.ACTION)).is_false()


func test_restore_menu_clears_loading_and_pending_pause() -> void:
	var s: ContextStack = _in_game_stack(_clock(), [])
	s.set_loading(true)
	s.gate_pause(InputTypes.PauseCause.FOCUS_LOST)

	s.restore_menu()

	assert_bool(s.is_loading()).is_false()
	assert_int(s.pending_pause()).is_equal(-1)


func test_router_derives_loading_from_the_three_load_notices() -> void:
	var state: GameState = _state_with_catalog()
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_state(state)
	var ch: NoticeChannel = state.get_channel()
	assert_bool(router.is_loading()).is_false()

	ch.notify(NoticeIds.SCENE_LOAD_STARTED)
	assert_bool(router.is_loading()).is_true()
	ch.notify(NoticeIds.SCENE_LOAD_FINISHED)
	assert_bool(router.is_loading()).is_false()
	ch.notify(NoticeIds.SCENE_LOAD_STARTED)
	ch.notify(NoticeIds.SCENE_LOAD_FAILED)

	assert_bool(router.is_loading()).is_false()


func test_router_without_load_notices_never_blocks() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_state(auto_free(GameState.new())) # no channel yet

	assert_bool(router.is_loading()).is_false()


# --- AC-E13c / AC-E13d: discard on partida_nueva ----------------------------------------------

func test_new_game_from_directed_scene_pause_leaves_only_loader_no_control() -> void:
	# GDD 1 rule 6 shape: [exploracion, sin control(21), menu]; the discard is triggered by the foreign `sin control`.
	var notices: Array = []
	var s: ContextStack = _in_game_stack(_clock(), notices)
	s.open_no_control(DIRECTOR, 5.0)
	s.enter(MENU, &"pause_menu")
	assert_int(s.depth()).is_equal(3)
	notices.clear()

	assert_bool(s.open_no_control(LOADER, 11.67, true)).is_true()

	assert_int(s.depth()).is_equal(1)
	assert_int(s.top()).is_equal(SIN)
	assert_str(s.no_control_owner()).is_equal("scene_loader")
	assert_float(s.no_control_declared_s()).is_equal(11.67)
	assert_bool(s.is_loading()).is_true()


func test_new_game_without_foreign_no_control_pushes_on_the_stack() -> void:
	# ADR-0006 D4: discard only with a foreign `sin control` and `absorbs_foreign`; otherwise a plain push.
	var s: ContextStack = _in_game_stack(_clock(), [])
	s.enter(MENU, &"pause_menu")

	assert_bool(s.open_no_control(LOADER, 11.67, true)).is_true()

	assert_int(s.depth()).is_equal(3)
	assert_int(s.top()).is_equal(SIN)


func test_new_game_over_foreign_no_control_discards_and_reports_absorbed() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(_clock(), notices)
	s.open_no_control(DIRECTOR, 5.0)
	s.enter(MENU, &"pause_menu")
	notices.clear()

	assert_bool(s.open_no_control(LOADER, 11.67, true)).is_true()

	assert_int(s.depth()).is_equal(1)
	assert_int(notices.size()).is_equal(2)
	assert_str(notices[0][0]).is_equal("input_context_changed")
	assert_str(notices[1][0]).is_equal("no_control_absorbed")
	assert_str(notices[1][1][&"dueno"]).is_equal("scene_director")


# --- AC-E2 (part L): reset on unload ----------------------------------------------------------

func test_unload_keeps_owner_duration_and_cap_of_current_no_control() -> void:
	var clock: GameClock = _clock()
	var notices: Array = []
	var s: ContextStack = _stack(clock, notices)
	s.open_no_control(DIRECTOR, 2.0) # cap = 4 s
	_run(clock, s, 1.0)
	notices.clear()

	s.reset_on_unload()

	assert_int(s.depth()).is_equal(1)
	assert_str(s.no_control_owner()).is_equal("scene_director")
	assert_float(s.no_control_declared_s()).is_equal(2.0)
	assert_array(notices).is_empty() # top already was `sin control`
	_run(clock, s, 2.75) # t = 3.75
	assert_int(s.top()).is_equal(SIN)
	_run(clock, s, STEP_S) # t = 4.0: the ORIGINAL cap
	assert_int(s.top()).is_equal(EXPLO)


func test_unload_with_stack_outside_exploration_keeps_the_no_control_below_the_top() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(_clock(), notices)
	s.open_no_control(DIRECTOR, 20.0)
	s.enter(MENU, &"pause_menu")
	notices.clear()

	s.reset_on_unload()

	assert_int(s.depth()).is_equal(1)
	assert_int(s.top()).is_equal(SIN)
	assert_str(s.no_control_owner()).is_equal("scene_director")
	assert_float(s.no_control_declared_s()).is_equal(20.0)
	assert_int(notices.size()).is_equal(1) # top was `menu`
	assert_str(notices[0][1][&"anterior"]).is_equal("menu")


func test_unload_without_current_no_control_opens_input_router_and_logs() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(_clock(), notices, log)
	s.enter(InputTypes.Context.INSPECCION, &"interaction")
	notices.clear()

	s.reset_on_unload()

	assert_int(s.depth()).is_equal(1)
	assert_str(s.no_control_owner()).is_equal("input_router")
	assert_float(s.no_control_declared_s()).is_equal(s.no_duration_s())
	assert_int(notices.size()).is_equal(1)
	assert_bool(_has_line(log, "reset_without_no_control")).is_true()


func test_router_poll_expires_the_cap_and_port_resets_the_stack() -> void:
	var clock: GameClock = _clock()
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_clock(clock)
	var port: InputContexts = router.contexts_port()
	router.open_no_control(DIRECTOR, 1.0) # cap = 3 s
	router.enter(MENU, &"pause_menu")

	port.reset_stack_on_unload()
	assert_int(router.top()).is_equal(SIN)
	for i: int in 12:
		clock.advance(STEP_S)
		router._process(STEP_S)

	assert_int(router.top()).is_equal(EXPLO)


func _has_line(log: RecordingLog, needle: String) -> bool:
	for l: Variant in log.lines:
		if str(l).contains(needle):
			return true
	return false
