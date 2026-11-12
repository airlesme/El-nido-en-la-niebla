extends GdUnitTestSuite
## EC-015 (automatic part): InputRouter.setup(ctx) at ADR-0009 D2 step 5 loads the real
## assets/data/input/default_bindings.json and hands out contexts_port(). No window needed.

var _log: RecordingLog
var _fatal: RecordingFatalHandler


func before_test() -> void:
	_log = RecordingLog.new()
	_fatal = RecordingFatalHandler.new()


func _ctx(files: FileStore, state: GameState, clock: GameClock) -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(true)
	c.fatal = _fatal
	c.files = files
	c.state = state
	c.clock = clock
	return c


func _router_in_tree() -> InputRouter:
	var router: InputRouter = auto_free(InputRouter.new())
	add_child(router)
	return router


func test_setup_real_bindings_loads_table_and_resolves_actions() -> void:
	var router: InputRouter = _router_in_tree()
	var ctx: ServiceContext = _ctx(FileStore.new(), auto_free(GameState.new()), auto_free(GameClock.new()))

	router.setup(ctx)

	assert_bool(_fatal.has_failed()).is_false()
	assert_bool(router.get_move_vector() == Vector2.ZERO).is_true()
	assert_object(router.adapter()).is_not_null()
	var seen: Array = []
	router.action_fed.connect(func(a: StringName, p: bool) -> void: seen.append([a, p]))
	var raw: InputTypes.RawInput = InputTypes.RawInput.new()
	raw.kind = InputTypes.RawKind.KEY
	raw.code = KEY_E
	raw.pressed = true
	router.feed(raw)
	assert_int(seen.size()).is_equal(1)
	assert_str(String(seen[0][0])).is_equal("interactuar")


func test_setup_leaves_exploration_on_top_and_hands_out_contexts_port() -> void:
	var router: InputRouter = _router_in_tree()
	router.setup(_ctx(FileStore.new(), auto_free(GameState.new()), auto_free(GameClock.new())))

	var port: InputContexts = router.contexts_port()

	assert_int(router.top()).is_equal(InputTypes.Context.EXPLORACION)
	assert_object(port).is_not_null()
	assert_bool(port.open_no_control(InputTypes.OWNER_SCENE_LOADER, 2.0, true)).is_true()
	assert_int(router.top()).is_equal(InputTypes.Context.SIN_CONTROL)
	assert_bool(port.close_no_control(InputTypes.OWNER_SCENE_LOADER)).is_true()


func test_setup_missing_bindings_raises_fatal_and_input_stays_inert() -> void:
	var router: InputRouter = _router_in_tree()
	var ctx: ServiceContext = _ctx(MemoryFileStore.new(), auto_free(GameState.new()), auto_free(GameClock.new()))

	router.setup(ctx)

	assert_bool(_fatal.has_failed()).is_true()
	assert_str(String(_fatal.calls[0][&"code"])).is_equal("CATALOGO_INVALIDO")
	var seen: Array = []
	router.action_fed.connect(func(a: StringName, p: bool) -> void: seen.append(a))
	var raw: InputTypes.RawInput = InputTypes.RawInput.new()
	raw.kind = InputTypes.RawKind.KEY
	raw.code = KEY_E
	raw.pressed = true
	router.feed(raw)
	assert_int(seen.size()).is_equal(0)
