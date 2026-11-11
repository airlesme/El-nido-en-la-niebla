extends GdUnitTestSuite
## EC-002: EngineInputAdapter (event -> RawInput), InputRouter.feed and the axis cache.
## AC-02 (interactuar from keyboard, mouse and pad with no device choice), the five event kinds,
## at most one action per raw event, last-axis cache. Synthetic events only.

const SHIPPED: String = "res://assets/data/input/default_bindings.json"
const FULL_PATH: String = "res://assets/data/input/default_bindings.json"


func _adapter() -> EngineInputAdapter:
	return auto_free(EngineInputAdapter.new())


func _table() -> BindingTable:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var c: ServiceContext = ServiceContext.new()
	c.logger = RecordingLog.new()
	c.flavor = BuildFlavor.new(true)
	c.fatal = RecordingFatalHandler.new()
	c.files = store
	c.freeze()
	var t: BindingTable = BindingTable.new()
	assert_int(t.load_defaults(c)).is_equal(OK)
	return t


func _key(code: int, pressed: bool = true) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.keycode = code as Key
	e.pressed = pressed
	return e


func _pad_axis(pad: int, axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
	e.device = pad
	e.axis = axis
	e.axis_value = value
	return e


# --- the five kinds ---------------------------------------------------------------------

func test_key_event_becomes_key_raw() -> void:
	var r: InputTypes.RawInput = _adapter().to_raw(_key(KEY_E))

	assert_int(r.kind).is_equal(InputTypes.RawKind.KEY)
	assert_int(r.code).is_equal(KEY_E)
	assert_bool(r.pressed).is_true()


func test_key_with_only_physical_keycode_uses_it() -> void:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = KEY_W
	e.pressed = false

	var r: InputTypes.RawInput = _adapter().to_raw(e)

	assert_int(r.code).is_equal(KEY_W)
	assert_bool(r.pressed).is_false()


func test_mouse_button_becomes_mouse_button_raw_with_position() -> void:
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = Vector2(12, 34)

	var r: InputTypes.RawInput = _adapter().to_raw(e)

	assert_int(r.kind).is_equal(InputTypes.RawKind.MOUSE_BUTTON)
	assert_int(r.code).is_equal(MOUSE_BUTTON_LEFT)
	assert_vector(r.position).is_equal(Vector2(12, 34))


func test_mouse_motion_becomes_motion_raw_keeping_relative_unscaled() -> void:
	var e: InputEventMouseMotion = InputEventMouseMotion.new()
	e.relative = Vector2(3, -4)
	e.position = Vector2(100, 50)

	var r: InputTypes.RawInput = _adapter().to_raw(e)

	assert_int(r.kind).is_equal(InputTypes.RawKind.MOUSE_MOTION)
	assert_vector(r.motion).is_equal(Vector2(3, -4))
	assert_vector(r.position).is_equal(Vector2(100, 50))


func test_pad_button_becomes_pad_button_raw_with_pad_id() -> void:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.device = 3
	e.button_index = JOY_BUTTON_A
	e.pressed = true

	var r: InputTypes.RawInput = _adapter().to_raw(e)

	assert_int(r.kind).is_equal(InputTypes.RawKind.PAD_BUTTON)
	assert_int(r.code).is_equal(JOY_BUTTON_A)
	assert_int(r.device).is_equal(3)


func test_pad_axis_keeps_raw_value_without_deadzone() -> void:
	var r: InputTypes.RawInput = _adapter().to_raw(_pad_axis(1, JOY_AXIS_LEFT_Y, -0.03))

	assert_int(r.kind).is_equal(InputTypes.RawKind.PAD_AXIS)
	assert_int(r.code).is_equal(JOY_AXIS_LEFT_Y)
	assert_int(r.device).is_equal(1)
	assert_float(r.value).is_equal_approx(-0.03, 0.0001)


func test_unsupported_and_null_events_give_null() -> void:
	var a: EngineInputAdapter = _adapter()

	assert_object(a.to_raw(null)).is_null()
	assert_object(a.to_raw(InputEventScreenTouch.new())).is_null()


func test_device_class_comes_from_type_not_from_device_id() -> void:
	var a: EngineInputAdapter = _adapter()
	var k: InputEventKey = _key(KEY_E)
	k.device = InputEvent.DEVICE_ID_KEYBOARD
	var p: InputEventJoypadButton = InputEventJoypadButton.new()
	p.device = 0
	p.button_index = JOY_BUTTON_A

	assert_int(a.to_raw(k).kind).is_equal(InputTypes.RawKind.KEY)
	assert_int(a.to_raw(p).kind).is_equal(InputTypes.RawKind.PAD_BUTTON)
	assert_int(a.to_raw(p).device).is_equal(0)


# --- AC-02: interactuar from every device, one action at most ------------------------------

func test_interactuar_arrives_from_key_mouse_and_pad_without_choosing_device() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_table(_table())
	add_child(router)
	var seen: Array[StringName] = []
	router.action_fed.connect(func(action: StringName, _pressed: bool) -> void: seen.append(action))
	var mb: InputEventMouseButton = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	var pb: InputEventJoypadButton = InputEventJoypadButton.new()
	pb.button_index = JOY_BUTTON_A
	pb.pressed = true

	router.adapter().handle_event(_key(KEY_E))
	router.adapter().handle_event(mb)
	router.adapter().handle_event(pb)

	assert_array(seen).is_equal([&"interactuar", &"interactuar", &"interactuar"])


func test_feed_emits_at_most_one_action_per_raw_event() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_table(_table())
	var seen: Array[StringName] = []
	router.action_fed.connect(func(action: StringName, _pressed: bool) -> void: seen.append(action))

	router.feed(_adapter().to_raw(_key(KEY_E)))

	assert_int(seen.size()).is_equal(1)


func test_feed_ignores_unbound_raw_null_and_missing_table() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	var seen: Array[StringName] = []
	router.action_fed.connect(func(action: StringName, _pressed: bool) -> void: seen.append(action))
	var unbound: InputTypes.RawInput = _adapter().to_raw(_key(KEY_F24))

	router.feed(unbound)
	router.feed(null)
	router.use_table(_table())
	router.feed(unbound)

	assert_int(seen.size()).is_equal(0)


func test_router_is_always_processed_and_adds_adapter_in_ready() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	add_child(router)

	assert_int(router.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_int(router.adapter().process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_object(router.adapter()).is_not_null()


func test_engine_event_through_parse_input_event_reaches_the_router() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	router.use_table(_table())
	add_child(router)
	var seen: Array[StringName] = []
	router.action_fed.connect(func(action: StringName, _pressed: bool) -> void: seen.append(action))

	Input.parse_input_event(_key(KEY_E))
	Input.flush_buffered_events()

	assert_array(seen).is_equal([&"interactuar"])


# --- to_binding -------------------------------------------------------------------------

func test_to_binding_captures_key_press_but_not_release() -> void:
	var a: EngineInputAdapter = _adapter()

	var b: InputTypes.InputBinding = a.to_binding(_key(KEY_Q))

	assert_int(b.kind).is_equal(InputTypes.RawKind.KEY)
	assert_int(b.code).is_equal(KEY_Q)
	assert_object(a.to_binding(_key(KEY_Q, false))).is_null()


func test_to_binding_axis_threshold_and_direction() -> void:
	var a: EngineInputAdapter = _adapter()

	assert_int(a.to_binding(_pad_axis(0, JOY_AXIS_LEFT_Y, -0.9)).axis_dir).is_equal(-1)
	assert_int(a.to_binding(_pad_axis(0, JOY_AXIS_LEFT_Y, 0.5)).axis_dir).is_equal(1)
	assert_object(a.to_binding(_pad_axis(0, JOY_AXIS_LEFT_Y, 0.49))).is_null()


func test_to_binding_rejects_mouse_motion_and_unsupported() -> void:
	var a: EngineInputAdapter = _adapter()

	assert_object(a.to_binding(InputEventMouseMotion.new())).is_null()
	assert_object(a.to_binding(null)).is_null()
	assert_object(a.to_binding(InputEventScreenTouch.new())).is_null()


# --- axis cache ---------------------------------------------------------------------------

func test_axis_cache_keeps_last_value_per_pad_and_axis() -> void:
	var a: EngineInputAdapter = _adapter()

	a.handle_event(_pad_axis(0, JOY_AXIS_LEFT_X, 0.25))
	a.handle_event(_pad_axis(0, JOY_AXIS_LEFT_X, -0.75))
	a.handle_event(_pad_axis(1, JOY_AXIS_LEFT_X, 0.5))

	assert_float(a.last_axis_value(0, JOY_AXIS_LEFT_X)).is_equal_approx(-0.75, 0.0001)
	assert_float(a.last_axis_value(1, JOY_AXIS_LEFT_X)).is_equal_approx(0.5, 0.0001)
	assert_float(a.last_axis_value(0, JOY_AXIS_RIGHT_Y)).is_equal(0.0)


func test_axis_cache_stores_small_values_and_clear_axes_resets_one_pad() -> void:
	var a: EngineInputAdapter = _adapter()
	a.handle_event(_pad_axis(0, JOY_AXIS_RIGHT_X, 0.03))
	a.handle_event(_pad_axis(1, JOY_AXIS_RIGHT_X, 0.4))

	assert_float(a.last_axis_value(0, JOY_AXIS_RIGHT_X)).is_equal_approx(0.03, 0.0001)
	a.clear_axes(0)

	assert_float(a.last_axis_value(0, JOY_AXIS_RIGHT_X)).is_equal(0.0)
	assert_float(a.last_axis_value(1, JOY_AXIS_RIGHT_X)).is_equal_approx(0.4, 0.0001)


func test_non_axis_events_do_not_touch_the_cache() -> void:
	var a: EngineInputAdapter = _adapter()

	a.handle_event(_key(KEY_E))

	assert_float(a.last_axis_value(0, 0)).is_equal(0.0)


# --- engine queries, printable keys ------------------------------------------------------------

func test_pad_name_is_empty_without_pad() -> void:
	assert_str(_adapter().pad_name(0)).is_equal("")


func test_set_mouse_mode_accepts_known_names_without_error() -> void:
	var a: EngineInputAdapter = _adapter()
	var before: Input.MouseMode = Input.mouse_mode

	a.set_mouse_mode(&"visible")
	a.set_mouse_mode(&"hidden")
	a.set_mouse_mode(&"visible")

	assert_int(Input.mouse_mode).is_equal(before)


func test_is_printable_key_ranges_and_deny_list() -> void:
	var a: EngineInputAdapter = _adapter()

	assert_bool(a.is_printable_key(KEY_A)).is_true()
	assert_bool(a.is_printable_key(KEY_SPACE)).is_true()
	assert_bool(a.is_printable_key(KEY_SPACE - 1)).is_false()
	assert_bool(a.is_printable_key(KEY_ESCAPE)).is_false()
	a.set_non_printable_keys([KEY_A] as Array[int])
	assert_bool(a.is_printable_key(KEY_A)).is_false()
	assert_bool(a.is_printable_key(KEY_B)).is_true()
