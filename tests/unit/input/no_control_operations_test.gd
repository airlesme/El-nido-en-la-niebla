extends GdUnitTestSuite
## EC-004: `sin control` operations (ADR-0006 D4) and the `InputContexts` port.
## AC-E13, AC-E13b, AC-08 (stack part).

const LOADER: StringName = InputTypes.OWNER_SCENE_LOADER
const DIRECTOR: StringName = InputTypes.OWNER_SCENE_DIRECTOR
const SIN: InputTypes.Context = InputTypes.Context.SIN_CONTROL
const MENU: InputTypes.Context = InputTypes.Context.MENU
const EXPLO: InputTypes.Context = InputTypes.Context.EXPLORACION


# Records notices into plain arrays (no `self` capture: no RefCounted cycle).
func _stack(notices: Array, log: RecordingLog = null) -> ContextStack:
	var emit: Callable = func(notice: StringName, payload: Dictionary) -> void:
		notices.append([notice, payload])
	return ContextStack.new(log, emit)


func _title_stack(notices: Array, log: RecordingLog = null) -> ContextStack:
	var s: ContextStack = _stack(notices, log)
	s.restore_menu()
	notices.clear()
	return s


func _ev(action: StringName) -> InputTypes.ActionEvent:
	var ev: InputTypes.ActionEvent = InputTypes.ActionEvent.new()
	ev.action = action
	return ev


# --- open ------------------------------------------------------------------------------------

func test_open_pushes_sin_control_with_owner_and_one_notice() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)

	assert_bool(s.open_no_control(LOADER, 2.0)).is_true()

	assert_int(s.top()).is_equal(SIN)
	assert_int(s.depth()).is_equal(2)
	assert_str(s.no_control_owner()).is_equal("scene_loader")
	assert_float(s.no_control_declared_s()).is_equal(2.0)
	assert_int(notices.size()).is_equal(1)
	assert_str(notices[0][0]).is_equal("input_context_changed")
	assert_str(notices[0][1][&"contexto"]).is_equal("sin_control")


func test_open_without_duration_uses_default_and_logs() -> void:
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack([], log)

	assert_bool(s.open_no_control(LOADER, 0.0)).is_true()

	assert_float(s.no_control_declared_s()).is_equal(s.no_duration_s())
	assert_int(log.lines.size()).is_equal(1)


func test_open_with_negative_duration_uses_default() -> void:
	var s: ContextStack = _stack([])

	s.open_no_control(DIRECTOR, -5.0)

	assert_float(s.no_control_declared_s()).is_equal(s.no_duration_s())


func test_open_with_empty_owner_is_rejected() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)

	assert_bool(s.open_no_control(&"", 1.0)).is_false()

	assert_int(s.depth()).is_equal(1)
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)


# --- AC-E13 ----------------------------------------------------------------------------------

func test_open_while_sin_control_on_top_is_rejected_and_logged() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.open_no_control(DIRECTOR, 2.0)).is_false()

	assert_int(s.depth()).is_equal(2)
	assert_str(s.no_control_owner()).is_equal("scene_loader")
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)


func test_transfer_changes_owner_and_duration_without_notice_or_stack_change() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.transfer_no_control(DIRECTOR, 5.0)).is_true()

	assert_str(s.no_control_owner()).is_equal("scene_director")
	assert_float(s.no_control_declared_s()).is_equal(5.0)
	assert_int(s.depth()).is_equal(2)
	assert_int(s.top()).is_equal(SIN)
	assert_array(notices).is_empty()


func test_transfer_without_duration_uses_default() -> void:
	var s: ContextStack = _stack([])
	s.open_no_control(LOADER, 2.0)

	s.transfer_no_control(DIRECTOR, 0.0)

	assert_float(s.no_control_declared_s()).is_equal(s.no_duration_s())


func test_transfer_without_sin_control_on_top_is_rejected() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)

	assert_bool(s.transfer_no_control(DIRECTOR, 2.0)).is_false()

	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)
	assert_str(s.no_control_owner()).is_equal("")


func test_close_by_non_owner_is_rejected_and_stack_unchanged() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.close_no_control(DIRECTOR)).is_false()
	assert_bool(s.close_no_control(&"")).is_false()

	assert_int(s.top()).is_equal(SIN)
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(2)


func test_close_by_owner_pops_with_one_notice() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.close_no_control(LOADER)).is_true()

	assert_int(s.top()).is_equal(EXPLO)
	assert_int(s.depth()).is_equal(1)
	assert_int(notices.size()).is_equal(1)
	assert_str(notices[0][1][&"anterior"]).is_equal("sin_control")
	assert_str(notices[0][1][&"contexto"]).is_equal("exploracion")


func test_close_without_sin_control_is_rejected() -> void:
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack([], log)

	assert_bool(s.close_no_control(LOADER)).is_false()

	assert_int(log.lines.size()).is_equal(1)


func test_close_over_menu_restores_menu_and_logs_misuse() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _title_stack(notices, log)
	s.open_no_control(DIRECTOR, 2.0)
	notices.clear()

	assert_bool(s.close_no_control(DIRECTOR)).is_true()

	assert_int(s.top()).is_equal(MENU)
	assert_int(notices.size()).is_equal(1)
	assert_int(log.lines.size()).is_equal(1)


func test_generic_enter_and_exit_still_reject_sin_control() -> void:
	var s: ContextStack = _stack([])
	s.open_no_control(LOADER, 2.0)

	assert_bool(s.enter(SIN, LOADER)).is_false()
	assert_bool(s.exit(SIN, LOADER)).is_false()

	assert_int(s.depth()).is_equal(2)


# --- foreign below ---------------------------------------------------------------------------

func test_open_with_foreign_sin_control_under_top_is_rejected() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)
	s.open_no_control(LOADER, 2.0)
	s.enter(InputTypes.Context.LLAMADA, &"phone") # a context above the foreign one
	notices.clear()

	assert_bool(s.open_no_control(DIRECTOR, 2.0)).is_false()

	assert_int(s.depth()).is_equal(3)
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)


func test_absorbing_open_discards_the_stack_and_reports_each_foreign_owner() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.open_no_control(DIRECTOR, 2.0)
	s.enter(MENU, &"pause_menu")
	notices.clear()

	assert_bool(s.open_no_control(LOADER, 4.0, true)).is_true()

	assert_int(s.depth()).is_equal(1)
	assert_int(s.top()).is_equal(SIN)
	assert_str(s.no_control_owner()).is_equal("scene_loader")
	assert_int(notices.size()).is_equal(2)
	assert_str(notices[0][0]).is_equal("input_context_changed")
	assert_str(notices[1][0]).is_equal("no_control_absorbed")
	assert_str(notices[1][1][&"dueno"]).is_equal("scene_director")


func test_absorbing_open_over_foreign_on_top_notifies_even_if_top_was_sin_control() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.open_no_control(DIRECTOR, 2.0)
	notices.clear()

	assert_bool(s.open_no_control(LOADER, 4.0, true)).is_true()

	assert_int(notices.size()).is_equal(2)
	assert_str(notices[0][1][&"anterior"]).is_equal("sin_control")
	assert_str(notices[0][1][&"contexto"]).is_equal("sin_control")


func test_absorbing_flag_is_ignored_for_other_owners() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.open_no_control(DIRECTOR, 2.0, true)).is_false()

	assert_str(s.no_control_owner()).is_equal("scene_loader")
	assert_array(notices).is_empty()


func test_absorbing_open_without_foreign_is_a_plain_open() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)

	assert_bool(s.open_no_control(LOADER, 4.0, true)).is_true()

	assert_int(s.depth()).is_equal(2)
	assert_int(notices.size()).is_equal(1)


# --- AC-E13b ---------------------------------------------------------------------------------

func test_title_stack_transfer_keeps_menu_below_without_notice() -> void:
	var notices: Array = []
	var s: ContextStack = _title_stack(notices)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.transfer_no_control(DIRECTOR, 3.0)).is_true()

	assert_int(s.depth()).is_equal(2)
	assert_int(s.top()).is_equal(SIN)
	assert_str(s.no_control_owner()).is_equal("scene_director")
	assert_array(notices).is_empty()


func test_request_exploration_by_owner_leaves_only_exploracion() -> void:
	var notices: Array = []
	var s: ContextStack = _title_stack(notices)
	s.open_no_control(LOADER, 2.0)
	s.transfer_no_control(DIRECTOR, 3.0)
	notices.clear()

	assert_bool(s.request_exploration(DIRECTOR)).is_true()

	assert_int(s.depth()).is_equal(1)
	assert_int(s.top()).is_equal(EXPLO)
	assert_bool(s.in_game()).is_true()
	assert_int(notices.size()).is_equal(1)
	assert_str(notices[0][1][&"anterior"]).is_equal("sin_control")
	assert_str(notices[0][1][&"contexto"]).is_equal("exploracion")


func test_request_exploration_by_non_owner_is_rejected() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _title_stack(notices, log)
	s.open_no_control(LOADER, 2.0)
	notices.clear()

	assert_bool(s.request_exploration(DIRECTOR)).is_false()

	assert_int(s.depth()).is_equal(2)
	assert_bool(s.in_game()).is_false()
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)


func test_request_exploration_without_sin_control_is_rejected() -> void:
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack([], log)

	assert_bool(s.request_exploration(DIRECTOR)).is_false()

	assert_bool(s.in_game()).is_false()
	assert_int(log.lines.size()).is_equal(1)


# --- restore_menu ----------------------------------------------------------------------------

func test_restore_menu_replaces_the_stack_with_menu_and_clears_in_game() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.open_no_control(LOADER, 2.0)
	s.request_exploration(LOADER)
	notices.clear()

	s.restore_menu()

	assert_int(s.depth()).is_equal(1)
	assert_int(s.top()).is_equal(MENU)
	assert_bool(s.in_game()).is_false()
	assert_int(notices.size()).is_equal(1)
	assert_str(notices[0][1][&"contexto"]).is_equal("menu")


func test_restore_menu_twice_notifies_only_once() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)

	s.restore_menu()
	s.restore_menu()

	assert_int(notices.size()).is_equal(1)
	assert_int(s.depth()).is_equal(1)


# --- AC-08 (stack part) ----------------------------------------------------------------------

func test_in_sin_control_interactuar_is_dropped_and_pausa_passes() -> void:
	var s: ContextStack = _stack([])
	var hits: Array[StringName] = []
	var sink: Callable = func(ev: InputTypes.ActionEvent) -> void: hits.append(ev.action)
	s.bind_sink(EXPLO, &"interactuar", sink)
	s.bind_sink(SIN, &"pausa", sink)
	s.open_no_control(LOADER, 2.0)

	assert_bool(s.deliver(_ev(&"interactuar"))).is_false()
	assert_bool(s.deliver(_ev(&"pausa"))).is_true()
	s.close_no_control(LOADER)
	assert_bool(s.deliver(_ev(&"interactuar"))).is_true()

	assert_array(hits).is_equal([&"pausa", &"interactuar"])


# --- port ------------------------------------------------------------------------------------

func test_port_forwards_every_operation_to_the_router() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	var port: InputContexts = router.contexts_port()

	assert_bool(port.open_no_control(LOADER, 2.0, false)).is_true()
	assert_bool(port.transfer_no_control(DIRECTOR, 2.0)).is_true()
	assert_bool(port.close_no_control(LOADER)).is_false()
	assert_bool(port.request_exploration(DIRECTOR)).is_true()
	assert_int(router.top()).is_equal(EXPLO)
	assert_bool(router.in_game()).is_true()
	port.restore_menu()

	assert_int(router.top()).is_equal(MENU)
	assert_bool(router.in_game()).is_false()


func test_port_after_router_is_freed_rejects_without_error() -> void:
	var router: InputRouter = InputRouter.new()
	var port: InputContexts = router.contexts_port()
	router.free()

	assert_bool(port.open_no_control(LOADER, 2.0)).is_false()
	assert_bool(port.close_no_control(LOADER)).is_false()
	assert_bool(port.transfer_no_control(LOADER, 1.0)).is_false()
	assert_bool(port.request_exploration(LOADER)).is_false()
	port.restore_menu()
