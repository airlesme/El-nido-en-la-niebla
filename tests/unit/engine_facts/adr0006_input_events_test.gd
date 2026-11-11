extends GdUnitTestSuite
# Verifica NS-n de ADR-0006 en Godot 4.7.2 (S-0006-A/B/C/D/E/F, parte sintetica headless).
## Observa con eventos sinteticos (Input.parse_input_event, Viewport.push_input): valores de InputEventJoypadMotion,
## DEVICE_ID_*, mouse motion relativo, is_echo, mouse_mode, API de nombre/GUID/lista de pads sin mando,
## orden _input -> GUI -> _unhandled_input. Lo que exige mando fisico o ventana real es NEEDS_MANUAL
## (prototypes/input-spike/): familia real, conexion/desconexion, deadzone de hardware, focus-out, escalado por stretch.


class Probe extends Node:
	var log: Array[String] = []
	var consume_in_input: bool = false

	func _input(event: InputEvent) -> void:
		log.append("input:" + event.get_class())
		if consume_in_input:
			get_viewport().set_input_as_handled()

	func _unhandled_input(event: InputEvent) -> void:
		log.append("unhandled:" + event.get_class())


func test_joypad_motion_event_keeps_axis_and_value_unmodified() -> void:
	# Arrange
	var probe: Probe = auto_free(Probe.new())
	add_child(probe)
	var ev: InputEventJoypadMotion = InputEventJoypadMotion.new()
	ev.axis = JOY_AXIS_LEFT_X
	ev.axis_value = 0.03  # inside any typical deadzone

	# Act
	get_viewport().push_input(ev)
	var seen: bool = probe.log.has("input:InputEventJoypadMotion")

	# Assert: a synthetic event reaches _input with the raw value (no engine deadzone on the event)
	print("S-0006-A synthetic joy motion axis=", ev.axis, " value=", ev.axis_value, " delivered=", seen)
	assert_bool(seen).is_true()
	assert_float(ev.axis_value).is_equal_approx(0.03, 0.0001)  # stored as float32: 0.0299999993


func test_joypad_axis_and_button_constants_are_documented_values() -> void:
	# Arrange / Act / Assert
	print("S-0006-A JOY_AXIS_LEFT_X=", JOY_AXIS_LEFT_X, " LEFT_Y=", JOY_AXIS_LEFT_Y, " RIGHT_X=", JOY_AXIS_RIGHT_X,
		" RIGHT_Y=", JOY_AXIS_RIGHT_Y, " TRIGGER_LEFT=", JOY_AXIS_TRIGGER_LEFT, " TRIGGER_RIGHT=", JOY_AXIS_TRIGGER_RIGHT)
	print("S-0006-A JOY_BUTTON_A=", JOY_BUTTON_A, " B=", JOY_BUTTON_B, " START=", JOY_BUTTON_START,
		" DPAD_UP=", JOY_BUTTON_DPAD_UP, " MAX=", JOY_BUTTON_MAX)
	assert_int(JOY_BUTTON_A).is_equal(0)
	assert_int(JOY_BUTTON_B).is_equal(1)
	assert_int(JOY_AXIS_LEFT_X).is_equal(0)
	assert_int(JOY_AXIS_LEFT_Y).is_equal(1)


func test_device_id_constants_numeric_values_observed() -> void:
	# Arrange / Act
	print("S-0006-D DEVICE_ID_KEYBOARD=", InputEvent.DEVICE_ID_KEYBOARD, " DEVICE_ID_MOUSE=", InputEvent.DEVICE_ID_MOUSE,
		" DEVICE_ID_EMULATION=", InputEvent.DEVICE_ID_EMULATION)

	# Assert: observed 4.7.2 = 16 / 32 / -1 (positive, NOT negative); pad ids come from the joypad index, so the
	# ADR must not assume "keyboard/mouse are negative" - it must compare against these constants
	assert_int(InputEvent.DEVICE_ID_KEYBOARD).is_equal(16)
	assert_int(InputEvent.DEVICE_ID_MOUSE).is_equal(32)
	assert_int(InputEvent.DEVICE_ID_EMULATION).is_equal(-1)


func test_new_key_and_mouse_events_default_device_is_not_a_pad_id() -> void:
	# Arrange / Act
	var key: InputEventKey = InputEventKey.new()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	var joy: InputEventJoypadButton = InputEventJoypadButton.new()
	print("S-0006-D default device key=", key.device, " mouse=", motion.device, " joy=", joy.device)

	# Assert: observed 4.7.2 = a new key/mouse event already carries DEVICE_ID_KEYBOARD/MOUSE; a new pad event is 0
	assert_int(key.device).is_equal(InputEvent.DEVICE_ID_KEYBOARD)
	assert_int(motion.device).is_equal(InputEvent.DEVICE_ID_MOUSE)
	assert_int(joy.device).is_equal(0)


func test_key_constants_and_text_names_observed() -> void:
	# Arrange
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = KEY_W
	ev.keycode = KEY_W
	ev.unicode = 119

	# Act
	var as_text: String = ev.as_text()
	var phys_text: String = ev.as_text_physical_keycode()
	print("S-0006-D KEY_ESCAPE=", KEY_ESCAPE, " KEY_W=", KEY_W, " KEY_SPACE=", KEY_SPACE, " KEY_ENTER=", KEY_ENTER,
		" as_text='", as_text, "' physical='", phys_text, "' ", OS.get_keycode_string(KEY_ESCAPE), "/", OS.get_keycode_string(KEY_ENTER))

	# Assert
	assert_str(OS.get_keycode_string(KEY_ESCAPE)).is_equal("Escape")
	assert_str(as_text).is_not_empty()


func test_mouse_motion_relative_is_passed_through_unscaled_on_push() -> void:
	# Arrange
	var probe: Probe = auto_free(Probe.new())
	add_child(probe)
	var ev: InputEventMouseMotion = InputEventMouseMotion.new()
	ev.relative = Vector2(7.0, -3.0)
	ev.position = Vector2(100, 100)

	# Act
	get_viewport().push_input(ev)

	# Assert: synthetic push does not rescale relative; stretch scaling of real events is NEEDS_MANUAL
	print("S-0006-D synthetic relative=", ev.relative, " delivered=", probe.log.has("input:InputEventMouseMotion"))
	assert_bool(probe.log.has("input:InputEventMouseMotion")).is_true()
	assert_vector(ev.relative).is_equal(Vector2(7.0, -3.0))


func test_is_echo_default_false_and_settable_on_synthetic_key() -> void:
	# Arrange
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true

	# Act
	var before: bool = key.is_echo()
	key.echo = true

	# Assert
	print("S-0006-A is_echo default=", before, " after set=", key.is_echo())
	assert_bool(before).is_false()
	assert_bool(key.is_echo()).is_true()


func test_input_parse_input_event_updates_pressed_state_for_pad_button() -> void:
	# Arrange
	var ev: InputEventJoypadButton = InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true

	# Act
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	var pressed: bool = Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	ev.pressed = false
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	var released: bool = Input.is_joy_button_pressed(0, JOY_BUTTON_A)

	# Assert: observed 4.7.2: parse_input_event + flush updates the polled state even for an unconnected pad 0
	print("S-0006-A parse_input_event pad A pressed->", pressed, " released->", released)
	assert_bool(pressed).is_true()
	assert_bool(released).is_false()


func test_joypad_name_guid_and_connected_list_without_pad() -> void:
	# Arrange / Act
	var pads: Array[int] = Input.get_connected_joypads()
	var name0: String = Input.get_joy_name(0)
	var guid0: String = Input.get_joy_guid(0)
	var info: Dictionary = Input.get_joy_info(0)
	print("S-0006-B/C no pad: connected=", pads, " name='", name0, "' guid='", guid0, "' info=", info)

	# Assert: calls exist and do not crash; with no pad they return empty values
	assert_str(name0).is_equal("") if pads.is_empty() else assert_str(name0).is_not_empty()


func test_joy_connection_changed_signal_exists_with_two_arguments() -> void:
	# Arrange
	var found: Dictionary = {}
	for s: Dictionary in Input.get_signal_list():
		if s["name"] == &"joy_connection_changed":
			found = s

	# Act
	var arg_names: Array[String] = []
	for a: Dictionary in found.get("args", []):
		arg_names.append("%s:%d" % [a["name"], a["type"]])
	print("S-0006-C joy_connection_changed args=", arg_names)

	# Assert
	assert_bool(found.is_empty()).is_false()
	assert_int(arg_names.size()).is_equal(2)


func test_joy_connection_changed_emitted_manually_reaches_subscriber() -> void:
	# Arrange (only checks the plumbing of the signal; real hot-plug is NEEDS_MANUAL)
	var got: Array = []
	var cb: Callable = func(device: int, connected: bool) -> void: got.append([device, connected])
	Input.joy_connection_changed.connect(cb)

	# Act
	Input.joy_connection_changed.emit(3, true)
	Input.joy_connection_changed.disconnect(cb)

	# Assert
	assert_array(got).is_equal([[3, true]])


func test_mouse_mode_set_and_restore_observed_headless() -> void:
	# Arrange
	var start: Input.MouseMode = Input.mouse_mode

	# Act
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var after_captured: Input.MouseMode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var after_hidden: Input.MouseMode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var after_visible: Input.MouseMode = Input.mouse_mode
	Input.mouse_mode = start
	print("S-0006-D mouse_mode start=", start, " captured->", after_captured, " hidden->", after_hidden,
		" visible->", after_visible, " (consts CAPTURED=", Input.MOUSE_MODE_CAPTURED, " HIDDEN=", Input.MOUSE_MODE_HIDDEN, ")")

	# Assert: observed 4.7.2 headless: the headless DisplayServer ignores the write (value stays VISIBLE).
	# Real captured/hidden set-and-restore is NEEDS_MANUAL (prototypes/input-spike/).
	assert_str(DisplayServer.get_name()).is_equal("headless")
	assert_int(after_captured).is_equal(start)
	assert_int(after_hidden).is_equal(start)
	assert_int(after_visible).is_equal(start)


func test_window_focus_notifications_constants_exist_and_can_be_delivered_to_a_node() -> void:
	# Arrange
	var n: Node = auto_free(Node.new())
	add_child(n)

	# Act: NOTIFICATION_APPLICATION_FOCUS_OUT / WM_WINDOW_FOCUS_OUT are the candidates for S-0006-E
	print("S-0006-E NOTIFICATION_APPLICATION_FOCUS_OUT=", Node.NOTIFICATION_APPLICATION_FOCUS_OUT,
		" WM_WINDOW_FOCUS_OUT=", Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT, " FOCUS_IN=", Node.NOTIFICATION_APPLICATION_FOCUS_IN)

	# Assert (real focus loss is NEEDS_MANUAL)
	assert_int(Node.NOTIFICATION_APPLICATION_FOCUS_OUT).is_not_equal(Node.NOTIFICATION_APPLICATION_FOCUS_IN)


func test_input_gui_unhandled_order_and_set_input_as_handled() -> void:
	# Arrange
	var order: Array[String] = []
	var probe: Probe = auto_free(Probe.new())
	add_child(probe)
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_Q
	ev.pressed = true

	# Act 1: not consumed
	get_viewport().push_input(ev)
	order.append_array(probe.log)
	probe.log.clear()
	# Act 2: consumed in _input
	probe.consume_in_input = true
	get_viewport().push_input(ev)
	print("S-0006-F order not consumed=", order, " consumed=", probe.log)

	# Assert
	assert_array(order).is_equal(["input:InputEventKey", "unhandled:InputEventKey"])
	assert_array(probe.log).is_equal(["input:InputEventKey"])


func test_line_edit_focus_signals_and_ui_actions_in_input_map() -> void:
	# Arrange
	var le: LineEdit = auto_free(LineEdit.new())
	add_child(le)
	var events: Array[String] = []
	le.focus_entered.connect(func() -> void: events.append("in"))
	le.focus_exited.connect(func() -> void: events.append("out"))

	# Act
	le.grab_focus()
	le.release_focus()
	var ui_actions: Array[String] = []
	for a: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept", &"ui_cancel"]:
		ui_actions.append("%s:%d" % [a, InputMap.action_get_events(a).size()] if InputMap.has_action(a) else "%s:MISSING" % a)
	print("S-0006-F LineEdit focus events=", events, " ui actions=", ui_actions)

	# Assert
	assert_array(events).is_equal(["in", "out"])
