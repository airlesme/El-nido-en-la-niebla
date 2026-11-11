## The ONLY file of the input layer that reads engine input (ADR-0006 D2; manifest F-R40): `InputEvent`
## fields, `Input` calls and the mouse mode. Everything else works on `InputTypes.RawInput` and is
## tested through `InputRouter.feed(raw)`.
## The device class comes from the event TYPE, never from `event.device` (F-R41; spike S-0006-D:
## `DEVICE_ID_KEYBOARD` = 16, `DEVICE_ID_MOUSE` = 32, `DEVICE_ID_EMULATION` = -1).
## One raw event yields at most one `RawInput` (F-R46). One small object is allocated per event.
## Example: `adapter.raw.connect(router.feed)`; the adapter then converts every `_input` event.
class_name EngineInputAdapter extends Node

## Emitted for every convertible engine event, after the axis cache is updated.
signal raw(input: InputTypes.RawInput)

## Axis magnitude from which a stick half counts as a capturable binding (rebinding, `to_binding`).
const CAPTURE_AXIS_THRESHOLD: float = 0.5
## Exclusive upper bound of Unicode-range keycodes (`KEY_SPECIAL` = 1 << 22 in the engine).
const _KEY_PRINTABLE_LIMIT: int = 1 << 22

## Keycodes that never count as text. TODO(ADR-0006): D12 puts the deny-list in
## `default_bindings.json` (`non_printable_keys`); until the schema carries it, it is injected.
var _non_printable: Dictionary = {}
## (pad_id * 64 + axis) -> last raw value, for D8 (story 008).
var _axis_cache: Dictionary = {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	handle_event(event)


## Converts `event`, updates the axis cache and emits `raw`. Returns the `RawInput`, or null when the
## event is not one of the five kinds the game knows (it is ignored).
## Example: `adapter.handle_event(key_event)`.
func handle_event(event: InputEvent) -> InputTypes.RawInput:
	var r: InputTypes.RawInput = to_raw(event)
	if r == null:
		return null
	if r.kind == InputTypes.RawKind.PAD_AXIS:
		_axis_cache[_axis_key(r.device, r.code)] = r.value
	raw.emit(r)
	return r


## Pure conversion of an engine event into a `RawInput`; null when unsupported (null included).
## Keys use `keycode`, falling back to `physical_keycode` when it is 0.
## Example: an `InputEventKey` with `keycode = KEY_E` and `pressed = true` gives `kind` KEY, `code` 69.
func to_raw(event: InputEvent) -> InputTypes.RawInput:
	if event == null:
		return null
	var r: InputTypes.RawInput = InputTypes.RawInput.new()
	if event is InputEventKey:
		var k: InputEventKey = event
		r.kind = InputTypes.RawKind.KEY
		r.code = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
		r.pressed = k.pressed
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		r.kind = InputTypes.RawKind.MOUSE_BUTTON
		r.code = mb.button_index
		r.pressed = mb.pressed
		r.position = mb.position
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		r.kind = InputTypes.RawKind.MOUSE_MOTION
		r.motion = mm.relative
		r.position = mm.position
	elif event is InputEventJoypadButton:
		var jb: InputEventJoypadButton = event
		r.kind = InputTypes.RawKind.PAD_BUTTON
		r.code = jb.button_index
		r.device = jb.device
		r.pressed = jb.pressed
	elif event is InputEventJoypadMotion:
		var jm: InputEventJoypadMotion = event
		r.kind = InputTypes.RawKind.PAD_AXIS
		r.code = jm.axis
		r.device = jm.device
		r.value = jm.axis_value
		r.pressed = absf(jm.axis_value) > 0.0
	else:
		return null
	return r


## Binding that `event` would create when captured for rebinding; null when it cannot be captured
## (release, mouse motion, an axis below `CAPTURE_AXIS_THRESHOLD`, unsupported event).
## Example: pad stick pushed up gives `PAD_AXIS`, `code` 1, `axis_dir` -1.
func to_binding(event: InputEvent) -> InputTypes.InputBinding:
	var r: InputTypes.RawInput = to_raw(event)
	if r == null or r.kind == InputTypes.RawKind.MOUSE_MOTION:
		return null
	var b: InputTypes.InputBinding = InputTypes.InputBinding.new()
	b.kind = r.kind
	b.code = r.code
	if r.kind == InputTypes.RawKind.PAD_AXIS:
		if absf(r.value) < CAPTURE_AXIS_THRESHOLD:
			return null
		b.axis_dir = 1 if r.value > 0.0 else -1
	elif not r.pressed:
		return null
	return b


## Last raw value seen for (`pad_id`, `axis`) without any dead zone; 0.0 when never seen.
func last_axis_value(pad_id: int, axis: int) -> float:
	return _axis_cache.get(_axis_key(pad_id, axis), 0.0)


## Forgets the cached axes of `pad_id` (disconnection, story 014).
func clear_axes(pad_id: int) -> void:
	for axis: int in range(64):
		_axis_cache.erase(_axis_key(pad_id, axis))


## Engine name of the pad; "" when there is none (spike S-0006-B).
func pad_name(pad_id: int) -> String:
	return Input.get_joy_name(pad_id)


## `&"captured"`, `&"visible"` or `&"hidden"`; anything else is ignored with a warning.
## Headless the engine ignores the write (spike S-0006-D).
func set_mouse_mode(mode: StringName) -> void:
	match mode:
		&"captured":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		&"visible":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		&"hidden":
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_:
			push_warning("EngineInputAdapter.set_mouse_mode: unknown mode '%s'" % mode)


## Replaces the deny-list of non-text keycodes. TODO(ADR-0006): read it from data (D12) in story 012.
func set_non_printable_keys(codes: Array[int]) -> void:
	_non_printable.clear()
	for c: int in codes:
		_non_printable[c] = true


## True when `code` is a Unicode-range keycode from SPACE up that is not in the deny-list.
## Example: `is_printable_key(KEY_A)` is true; `is_printable_key(KEY_ESCAPE)` is false.
func is_printable_key(code: int) -> bool:
	return code >= KEY_SPACE and code < _KEY_PRINTABLE_LIMIT and not _non_printable.has(code)


func _axis_key(pad_id: int, axis: int) -> int:
	return pad_id * 64 + axis
