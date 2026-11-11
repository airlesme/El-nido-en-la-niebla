extends Node
# PROTOTYPE - NOT FOR PRODUCTION
# Question: ADR-0006 S-0006-A..E on real hardware/window. Prints one line per observation to stdout and
# user://input_spike.log. Keys: P toggle pause, C captured mouse, V visible, H hidden, ESC quit.
# Window size for S-0006-D: run twice, e.g. `--resolution 1920x1080` and `--resolution 2560x1440`.

var _log: FileAccess
var _rest_max: Dictionary = {}
var _motion_sum: Vector2 = Vector2.ZERO
var _t0: int = 0


func _ready() -> void:
	_log = FileAccess.open("user://input_spike.log", FileAccess.WRITE)
	_t0 = Time.get_ticks_msec()
	Input.joy_connection_changed.connect(_on_joy)
	for id: int in Input.get_connected_joypads():
		_say("START pad id=%d name='%s' guid='%s' info=%s" % [id, Input.get_joy_name(id), Input.get_joy_guid(id), Input.get_joy_info(id)])
	_say("DEVICE_ID_KEYBOARD=%d DEVICE_ID_MOUSE=%d window=%s" % [InputEvent.DEVICE_ID_KEYBOARD, InputEvent.DEVICE_ID_MOUSE, get_window().size])


func _on_joy(device: int, connected: bool) -> void:
	_say("joy_connection_changed device=%d connected=%s paused=%s name='%s' guid='%s' list=%s" % [device, connected, get_tree().paused, Input.get_joy_name(device), Input.get_joy_guid(device), Input.get_connected_joypads()])


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT: _say("FOCUS_OUT app paused=%s mouse_mode=%d" % [get_tree().paused, Input.mouse_mode])
		NOTIFICATION_APPLICATION_FOCUS_IN: _say("FOCUS_IN app mouse_mode=%d" % Input.mouse_mode)
		NOTIFICATION_WM_WINDOW_FOCUS_OUT: _say("FOCUS_OUT window")
		NOTIFICATION_WM_WINDOW_FOCUS_IN: _say("FOCUS_IN window")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		var m: InputEventJoypadMotion = event
		var k: String = "%d:%d" % [m.device, m.axis]
		_rest_max[k] = maxf(absf(m.axis_value), _rest_max.get(k, 0.0)) if absf(m.axis_value) < 0.2 else _rest_max.get(k, 0.0)
		_say("JOY_MOTION dev=%d axis=%d value=%.4f (max |value| < 0.2 so far: %.4f)" % [m.device, m.axis, m.axis_value, _rest_max.get(k, 0.0)])
	elif event is InputEventJoypadButton:
		var b: InputEventJoypadButton = event
		_say("JOY_BUTTON dev=%d idx=%d pressed=%s" % [b.device, b.button_index, b.pressed])
	elif event is InputEventKey:
		var e: InputEventKey = event
		if e.pressed:
			_say("KEY dev=%d keycode=%d '%s' echo=%s" % [e.device, e.keycode, e.as_text_keycode(), e.echo])
			match e.keycode:
				KEY_P: get_tree().paused = not get_tree().paused; _say("paused=%s" % get_tree().paused)
				KEY_C: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED; _say("mouse_mode=%d" % Input.mouse_mode)
				KEY_V: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; _say("mouse_mode=%d" % Input.mouse_mode)
				KEY_H: Input.mouse_mode = Input.MOUSE_MODE_HIDDEN; _say("mouse_mode=%d" % Input.mouse_mode)
				KEY_ESCAPE: get_tree().quit()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		_motion_sum += mm.relative
		_say("MOUSE dev=%d relative=%s sum=%s pos=%s mode=%d" % [mm.device, mm.relative, _motion_sum, mm.position, Input.mouse_mode])


func _say(line: String) -> void:
	var s: String = "[%6d ms] %s" % [Time.get_ticks_msec() - _t0, line]
	print(s)
	if _log != null:
		_log.store_line(s)
		_log.flush()
