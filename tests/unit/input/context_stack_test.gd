extends GdUnitTestSuite
## EC-003: ContextStack (pure) and its delivery through InputRouter.
## AC-05 (mover dropped in inspeccion), AC-06 (cursor restored), AC-E1 (ignored/rejected requests),
## AC-E9 (two notices for enter+exit, none for ignored/rejected), sinks (one per context/action).

const SHIPPED: String = "res://assets/data/input/default_bindings.json"


# Records notices into plain arrays (no `self` capture: no RefCounted cycle).
func _stack(notices: Array, log: RecordingLog = null) -> ContextStack:
	var emit: Callable = func(notice: StringName, payload: Dictionary) -> void:
		notices.append([notice, payload])
	return ContextStack.new(log, emit)


func _table() -> BindingTable:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(SHIPPED, FileAccess.get_file_as_string(SHIPPED))
	var c: ServiceContext = ServiceContext.new()
	c.logger = RecordingLog.new()
	c.flavor = BuildFlavor.new(true)
	c.fatal = RecordingFatalHandler.new()
	c.files = store
	c.freeze()
	var t: BindingTable = BindingTable.new()
	assert_int(t.load_defaults(c)).is_equal(OK)
	return t


func _ev(action: StringName) -> InputTypes.ActionEvent:
	var ev: InputTypes.ActionEvent = InputTypes.ActionEvent.new()
	ev.action = action
	return ev


func _key_w() -> InputTypes.RawInput:
	var raw: InputTypes.RawInput = InputTypes.RawInput.new()
	raw.kind = InputTypes.RawKind.KEY
	raw.code = KEY_W
	raw.pressed = true
	return raw


# --- base ------------------------------------------------------------------------------------

func test_new_stack_has_exploracion_as_only_entry() -> void:
	var s: ContextStack = _stack([])

	assert_int(s.top()).is_equal(InputTypes.Context.EXPLORACION)
	assert_int(s.depth()).is_equal(1)


func test_exiting_the_base_is_rejected_and_logged() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)

	assert_bool(s.exit(InputTypes.Context.EXPLORACION, ContextStack.BASE_REQUESTER)).is_false()

	assert_int(s.depth()).is_equal(1)
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)


# --- AC-E1 -----------------------------------------------------------------------------------

func test_entering_the_context_already_on_top_is_ignored_without_notice() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)
	s.enter(InputTypes.Context.INSPECCION, &"interaction")
	notices.clear()

	var ok: bool = s.enter(InputTypes.Context.INSPECCION, &"other")

	assert_bool(ok).is_false()
	assert_int(s.depth()).is_equal(2)
	assert_array(notices).is_empty()


func test_entering_the_current_top_at_start_is_ignored() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)

	assert_bool(s.enter(InputTypes.Context.EXPLORACION, &"x")).is_false()

	assert_int(s.depth()).is_equal(1)
	assert_array(notices).is_empty()


func test_exiting_a_non_top_context_is_rejected_logged_and_stack_unchanged() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)
	s.enter(InputTypes.Context.VISTA_CERCANA, &"puzzle")
	s.enter(InputTypes.Context.MENU, &"pause")
	notices.clear()

	var ok: bool = s.exit(InputTypes.Context.VISTA_CERCANA, &"puzzle")

	assert_bool(ok).is_false()
	assert_int(s.top()).is_equal(InputTypes.Context.MENU)
	assert_int(s.depth()).is_equal(3)
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(1)
	assert_str(log.lines[0][&"level"]).is_equal("error")


func test_exiting_with_a_different_requester_is_rejected() -> void:
	var s: ContextStack = _stack([], RecordingLog.new())
	s.enter(InputTypes.Context.LECTURA, &"reader")

	assert_bool(s.exit(InputTypes.Context.LECTURA, &"intruder")).is_false()

	assert_int(s.top()).is_equal(InputTypes.Context.LECTURA)


func test_sin_control_is_rejected_by_enter_and_exit() -> void:
	var notices: Array = []
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack(notices, log)

	assert_bool(s.enter(InputTypes.Context.SIN_CONTROL, &"x")).is_false()
	assert_bool(s.exit(InputTypes.Context.SIN_CONTROL, &"x")).is_false()

	assert_int(s.depth()).is_equal(1)
	assert_array(notices).is_empty()
	assert_int(log.lines.size()).is_equal(2)


func test_invalid_context_value_and_empty_requester_are_rejected() -> void:
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack([], log)

	assert_bool(s.enter(99 as InputTypes.Context, &"x")).is_false()
	assert_bool(s.enter(-1 as InputTypes.Context, &"x")).is_false()
	assert_bool(s.enter(InputTypes.Context.MENU, &"")).is_false()

	assert_int(s.depth()).is_equal(1)
	assert_int(log.lines.size()).is_equal(3)


# --- AC-E9 -----------------------------------------------------------------------------------

func test_enter_and_exit_inspeccion_emit_exactly_two_notices_with_both_names() -> void:
	var notices: Array = []
	var s: ContextStack = _stack(notices)

	assert_bool(s.enter(InputTypes.Context.INSPECCION, &"interaction")).is_true()
	assert_bool(s.exit(InputTypes.Context.INSPECCION, &"interaction")).is_true()

	assert_int(notices.size()).is_equal(2)
	assert_str(notices[0][0]).is_equal("input_context_changed")
	assert_dict(notices[0][1]).is_equal({&"anterior": &"exploracion", &"contexto": &"inspeccion"})
	assert_dict(notices[1][1]).is_equal({&"anterior": &"inspeccion", &"contexto": &"exploracion"})


func test_notice_name_is_the_registered_one() -> void:
	assert_bool(NoticeIds.SCHEMA.has(NoticeIds.INPUT_CONTEXT_CHANGED)).is_true()


# --- AC-06 -----------------------------------------------------------------------------------

func test_cursor_is_restored_when_the_menu_above_vista_cercana_exits() -> void:
	var s: ContextStack = _stack([])
	s.enter(InputTypes.Context.VISTA_CERCANA, &"puzzle")
	s.set_cursor_pos(Vector2(320.0, 180.0))

	s.enter(InputTypes.Context.MENU, &"pause")
	s.set_cursor_pos(Vector2(5.0, 7.0))
	assert_bool(s.exit(InputTypes.Context.MENU, &"pause")).is_true()

	assert_int(s.top()).is_equal(InputTypes.Context.VISTA_CERCANA)
	assert_vector(s.cursor_pos()).is_equal(Vector2(320.0, 180.0))


func test_new_entry_starts_with_cursor_at_origin() -> void:
	var s: ContextStack = _stack([])
	s.set_cursor_pos(Vector2(9.0, 9.0))

	s.enter(InputTypes.Context.MENU, &"pause")

	assert_vector(s.cursor_pos()).is_equal(Vector2.ZERO)


# --- sinks -----------------------------------------------------------------------------------

func test_only_the_top_context_receives_and_unaccepted_actions_are_dropped() -> void:
	var s: ContextStack = _stack([])
	var hits: Array[String] = []
	s.bind_sink(InputTypes.Context.EXPLORACION, &"interactuar", func(_e: InputTypes.ActionEvent) -> void: hits.append("exp"))
	s.bind_sink(InputTypes.Context.INSPECCION, &"interactuar", func(_e: InputTypes.ActionEvent) -> void: hits.append("ins"))
	s.bind_sink(InputTypes.Context.INSPECCION, &"atrás", func(_e: InputTypes.ActionEvent) -> void: hits.append("back"))

	assert_bool(s.deliver(_ev(&"interactuar"))).is_true()
	s.enter(InputTypes.Context.INSPECCION, &"i")
	assert_bool(s.deliver(_ev(&"interactuar"))).is_false() # not an inspeccion action even with a sink
	assert_bool(s.deliver(_ev(&"atrás"))).is_true()

	assert_array(hits).is_equal(["exp", "back"])


func test_second_bind_replaces_the_first_and_logs() -> void:
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack([], log)
	var hits: Array[String] = []
	s.bind_sink(InputTypes.Context.EXPLORACION, &"pausa", func(_e: InputTypes.ActionEvent) -> void: hits.append("a"))
	s.bind_sink(InputTypes.Context.EXPLORACION, &"pausa", func(_e: InputTypes.ActionEvent) -> void: hits.append("b"))

	s.deliver(_ev(&"pausa"))

	assert_array(hits).is_equal(["b"])
	assert_int(log.lines.size()).is_equal(1)
	assert_str(log.lines[0][&"level"]).is_equal("warn")


func test_unbind_removes_only_the_registered_callable() -> void:
	var s: ContextStack = _stack([])
	var hits: Array[String] = []
	var mine: Callable = func(_e: InputTypes.ActionEvent) -> void: hits.append("mine")
	var other: Callable = func(_e: InputTypes.ActionEvent) -> void: hits.append("other")
	s.bind_sink(InputTypes.Context.EXPLORACION, &"pausa", mine)

	s.unbind_sink(InputTypes.Context.EXPLORACION, &"pausa", other)
	assert_bool(s.has_sink(InputTypes.Context.EXPLORACION, &"pausa")).is_true()
	s.unbind_sink(InputTypes.Context.EXPLORACION, &"pausa", mine)

	assert_bool(s.has_sink(InputTypes.Context.EXPLORACION, &"pausa")).is_false()
	assert_bool(s.deliver(_ev(&"pausa"))).is_false()


func test_invalid_sink_is_rejected_and_null_event_is_dropped() -> void:
	var log: RecordingLog = RecordingLog.new()
	var s: ContextStack = _stack([], log)

	s.bind_sink(InputTypes.Context.EXPLORACION, &"pausa", Callable())

	assert_bool(s.has_sink(InputTypes.Context.EXPLORACION, &"pausa")).is_false()
	assert_int(log.lines.size()).is_equal(1)
	assert_bool(s.deliver(null)).is_false()


func test_sink_of_a_freed_object_is_dropped_not_called() -> void:
	var s: ContextStack = _stack([])
	var node: Node = Node.new()
	s.bind_sink(InputTypes.Context.EXPLORACION, &"pausa", Callable(node, "queue_free"))
	node.free()

	assert_bool(s.deliver(_ev(&"pausa"))).is_false()
	assert_bool(s.has_sink(InputTypes.Context.EXPLORACION, &"pausa")).is_false()


# --- AC-05 through the router ----------------------------------------------------------------

func test_mover_is_discarded_in_inspeccion_and_delivered_in_exploracion() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_table(_table())
	var hits: Array[StringName] = []
	var sink: Callable = func(ev: InputTypes.ActionEvent) -> void: hits.append(ev.action)
	router.bind_sink(InputTypes.Context.EXPLORACION, &"mover", sink)
	router.bind_sink(InputTypes.Context.INSPECCION, &"mover", sink)

	router.feed(_key_w())
	assert_array(hits).is_equal([&"mover"])
	hits.clear()
	assert_bool(router.enter(InputTypes.Context.INSPECCION, &"interaction")).is_true()
	router.feed(_key_w())

	assert_array(hits).is_empty()
	assert_bool(router.exit(InputTypes.Context.INSPECCION, &"interaction")).is_true()
	assert_int(router.top()).is_equal(InputTypes.Context.EXPLORACION)


func test_router_without_state_or_catalog_changes_context_without_error() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	var state: GameState = auto_free(GameState.new())
	router.use_state(state) # channel is null until the catalog loads

	assert_bool(router.enter(InputTypes.Context.MENU, &"pause")).is_true()

	assert_int(router.top()).is_equal(InputTypes.Context.MENU)
