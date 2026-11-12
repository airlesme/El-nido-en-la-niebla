## Input contexts and sin-control owner (system 1).
## Story EC-002 part: owns the `EngineInputAdapter` child and `feed(raw)`, which resolves at most one
## action per raw event. Stack, sinks, latches, gestures: later stories (003+).
## Registered as autoload `InputRouterAutoload` (ADR-0009 D1).
## TODO(ADR-0006): the rest of the public API (enter/exit, sinks, movement...) arrives with its stories.
class_name InputRouter extends Node

## Provisional: emitted by `feed` with the first action bound to the raw event.
## TODO(ADR-0006): replaced by context-aware delivery (D6) in story 003.
signal action_fed(action: StringName, pressed: bool)

var _adapter: EngineInputAdapter
var _table: BindingTable
var _stack: ContextStack
var _state: GameState
var _clock: GameClock
var _load_subs: Array[int] = [] # handles on the state's channel
## Raw polled state of EC-008 (updated by `feed`, read by `get_move_vector` / `consume_look_delta`).
var _left_stick: Vector2 = Vector2.ZERO
var _right_stick: Vector2 = Vector2.ZERO
var _mouse_px: Vector2 = Vector2.ZERO # relative px since the last consume
var _keys: Array[bool] = [false, false, false, false] # up, down, left, right of `mover`
## Player look settings (GDD 1 F2/F3 "ajuste"). TODO(ADR-0007): persisted settings replace these defaults.
var _sens_mouse: float = 1.0
var _sens_stick: float = 1.0
var _invert_mouse: bool = false
var _invert_pad: bool = false

## Safe ranges of the player sensitivities (GDD 1 F2: 0.25-3, F3: 0.5-2).
const SENS_MOUSE_RANGE: Vector2 = Vector2(0.25, 3.0)
const SENS_STICK_RANGE: Vector2 = Vector2(0.5, 2.0)


func _init() -> void:
	# ADR-0009 D2: explicit, never inherited. No I/O, no autoload reads here.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stack = ContextStack.new(null, _notify)


func _ready() -> void:
	if _adapter == null:
		_adapter = EngineInputAdapter.new()
		_adapter.name = "EngineInputAdapter"
		add_child(_adapter)
	if not _adapter.raw.is_connected(feed):
		_adapter.raw.connect(feed)


## Composition point, called once by Boot (ADR-0009 D2/D3). Never called by systems.
func setup(ctx: ServiceContext) -> void:
	# TODO(ADR-0006): load the binding table and subscribe (ADR-0009 D2 boot order).
	_stack.set_log(ctx.logger)
	use_clock(ctx.clock)
	use_state(ctx.state)


## Injects the state whose channel carries `input_context_changed` and the load notices
## (tests; `setup` does it from the context). Subscribes to `scene_load_started/finished/failed`.
func use_state(state: GameState) -> void:
	_unsubscribe_loading()
	_state = state
	_subscribe_loading()


## Injects the game clock of the `sin control` cap (tests; `setup` does it from the context).
func use_clock(clock: GameClock) -> void:
	_clock = clock
	_stack.set_clock(clock)


## Frame poll of the `sin control` cap with `GameClock.is_due` (no timer of its own; ADR-0002 D6).
func _process(_delta: float) -> void:
	_subscribe_loading()
	_stack.tick()


## True while a load is in progress (`carga_en_curso`); blocks the pause. Without load notices it never is.
func is_loading() -> bool:
	return _stack.is_loading()


## Margin (s) added to the declared duration of a `sin control` to get its cap; read by 21 (ADR-0017 A3).
func no_control_margin_s() -> float:
	return _stack.margin_s()


## Unload of a game scene: the stack becomes [the current `sin control`] keeping owner, duration and cap.
## Never for the title or a full unload (ADR-0003 D2).
func reset_stack_on_unload() -> void:
	_stack.reset_on_unload()


## Decides a pause request (see `ContextStack.gate_pause`). TODO(story-014): `pause_requested` consumes it.
func gate_pause(cause: InputTypes.PauseCause) -> bool:
	return _stack.gate_pause(cause)


## Pause cause deferred during a load (-1 none); story 014 fires it after `scene_load_finished`.
func take_pending_pause() -> int:
	return _stack.take_pending_pause()


## Injects the log seam of the stack (tests; `setup` does it from the context).
func use_log(log: LogSink) -> void:
	_stack.set_log(log)


## Context on top of the stack (ADR-0006 D3). Base: `EXPLORACION`.
func top() -> InputTypes.Context:
	return _stack.top()


## Pushes `ctx` for `requester`; false when ignored (already top) or rejected (`SIN_CONTROL`: story 004).
## Example: `router.enter(InputTypes.Context.INSPECCION, &"interaction")`.
func enter(ctx: InputTypes.Context, requester: StringName) -> bool:
	return _stack.enter(ctx, requester)


## Pops `ctx` if it is the top entry pushed by `requester`; otherwise rejected, logged, stack unchanged.
func exit(ctx: InputTypes.Context, requester: StringName) -> bool:
	return _stack.exit(ctx, requester)


## `sin control` operations (ADR-0006 D4). Only 4 (`scene_loader`) and 21 (`scene_director`) call them,
## through `contexts_port()` (F-R45). Rejected requests are logged and emit nothing.
func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
	return _stack.open_no_control(owner, declared_s, absorbs_foreign)


## Closes the top `sin control`; only its owner may.
func close_no_control(owner: StringName) -> bool:
	return _stack.close_no_control(owner)


## Hands the top `sin control` to `new_owner` without leaving it and without notice.
func transfer_no_control(new_owner: StringName, declared_s: float) -> bool:
	return _stack.transfer_no_control(new_owner, declared_s)


## The owner of the top `sin control` asks for `exploracion` (any `menu` below is discarded).
func request_exploration(owner: StringName) -> bool:
	return _stack.request_exploration(owner)


## Stack becomes `[menu]` (return to title).
func restore_menu() -> void:
	_stack.restore_menu()


## True after `request_exploration`, false after `restore_menu`.
func in_game() -> bool:
	return _stack.in_game()


## The port handed by Boot to 4 and 21 (ADR-0003); each call creates a thin wrapper over this router.
func contexts_port() -> InputContexts:
	return InputContexts.new(self)


## Registers the single sink of (ctx, action); a second bind replaces and logs (ADR-0006 D6).
func bind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable) -> void:
	_stack.bind_sink(ctx, action, sink)


## Removes `sink` from (ctx, action) if it is the one registered.
func unbind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable) -> void:
	_stack.unbind_sink(ctx, action, sink)


## Remembers the cursor of the top entry; restored when what is above it exits (AC-06).
func set_cursor_pos(pos: Vector2) -> void:
	_stack.set_cursor_pos(pos)


## Cursor (logical px) stored in the top entry.
func cursor_pos() -> Vector2:
	return _stack.cursor_pos()


## The engine adapter (child node); null before the router enters the tree.
func adapter() -> EngineInputAdapter:
	return _adapter


## Injects the binding table used by `feed`. TODO(ADR-0006): `setup` will own this in story 003.
func use_table(table: BindingTable) -> void:
	_table = table
	if table != null and table.is_loaded():
		_stack.set_caps(table.tuning_value(&"no_duration_cap_s"), table.tuning_value(&"sin_control_margin_s"))
		_invert_mouse = table.toggle_default(&"invert_y_keyboard_mouse")
		_invert_pad = table.toggle_default(&"invert_y_gamepad")


## Sets the player's look settings, clamped to their safe ranges (non-finite sensitivities are ignored).
## Example: `router.set_look_settings(1.5, 1.0, true, false)`.
func set_look_settings(mouse_sens: float, stick_sens: float, invert_mouse: bool, invert_pad: bool) -> void:
	if is_finite(mouse_sens):
		_sens_mouse = clampf(mouse_sens, SENS_MOUSE_RANGE.x, SENS_MOUSE_RANGE.y)
	if is_finite(stick_sens):
		_sens_stick = clampf(stick_sens, SENS_STICK_RANGE.x, SENS_STICK_RANGE.y)
	_invert_mouse = invert_mouse
	_invert_pad = invert_pad


## Movement poll (ADR-0006 D6): x = right, y = forward, length <= 1; zero outside `EXPLORACION`.
## Keyboard (normalised) plus the left stick through F1 (dead zone of ours, never the engine's).
func get_move_vector() -> Vector2:
	if _table == null or not _table.is_loaded() or _stack.top() != InputTypes.Context.EXPLORACION:
		return Vector2.ZERO
	var kb: Vector2 = Vector2(float(_keys[3]) - float(_keys[2]), float(_keys[0]) - float(_keys[1]))
	if kb != Vector2.ZERO:
		kb = kb.normalized()
	var pad: Vector2 = InputFormulas.stick_move(_left_stick,
			_table.tuning_value(&"dz_in"), _table.tuning_value(&"dz_out"))
	pad.y = -pad.y # stick up is axis -1; forward is +y
	return (kb + pad).limit_length(1.0)


## Look poll (ADR-0006 D6/D8): degrees to turn this frame, x = yaw (+right), y = pitch (+up), the convention
## `Look.apply_input_deg` expects. Mouse (F2) plus right stick (F3); consumes the accumulated mouse pixels
## even outside `EXPLORACION`, where it returns zero. `delta` is the frame time (s); a negative value
## (default) uses `get_process_delta_time()`. The router applies no pitch/yaw limits (AC-09).
## TODO(ADR-0006): the optional `delta` parameter is an ADR-fallback (F3 needs the frame time); owner: lead-programmer.
func consume_look_delta(delta: float = -1.0) -> Vector2:
	var px: Vector2 = _mouse_px
	_mouse_px = Vector2.ZERO
	if _table == null or not _table.is_loaded() or _stack.top() != InputTypes.Context.EXPLORACION:
		return Vector2.ZERO
	var dt: float = delta if delta >= 0.0 else get_process_delta_time()
	var m: Vector2 = InputFormulas.mouse_look(px, _table.tuning_value(&"k_mouse_deg_per_px"),
			_sens_mouse, -1 if _invert_mouse else 1)
	var s: Vector2 = InputFormulas.stick_look(_right_stick, _table.tuning_value(&"dz_in"),
			_table.tuning_value(&"dz_out"), _table.tuning_value(&"omega_max_deg_s"),
			_table.tuning_value(&"look_curve_exp"), _sens_stick, -1 if _invert_pad else 1, dt)
	var d: Vector2 = m + s
	return Vector2(d.x, -d.y) # F2/F3 use screen axes (y down); Look wants +up


## Single entry of raw input; called only by the adapter and by tests. Resolves the FIRST action bound
## to `raw` (F-R46) and emits `action_fed`; axes and mouse motion without a binding emit nothing.
## Example: `router.feed(raw_e_pressed)` emits `action_fed(&"interactuar", true)`.
func feed(raw: InputTypes.RawInput) -> void:
	if raw == null or _table == null:
		return
	_track(raw)
	var actions: Array[StringName] = _table.actions_for(raw)
	if actions.is_empty():
		return
	action_fed.emit(actions[0], raw.pressed)
	# D6 delivery: synchronous, by the stack (never by node `_input` order; spike 2026-11-11).
	var ev: InputTypes.ActionEvent = InputTypes.ActionEvent.new()
	ev.action = actions[0]
	ev.phase = InputTypes.Phase.PRESSED if raw.pressed else InputTypes.Phase.RELEASED
	ev.position = raw.position
	_stack.deliver(ev)


## Records the raw state polled by `get_move_vector` / `consume_look_delta`.
func _track(raw: InputTypes.RawInput) -> void:
	match raw.kind:
		InputTypes.RawKind.MOUSE_MOTION:
			if InputFormulas.is_finite_vec(raw.motion):
				_mouse_px += raw.motion
		InputTypes.RawKind.PAD_AXIS:
			var v: float = raw.value if is_finite(raw.value) else 0.0
			match raw.code:
				JOY_AXIS_LEFT_X: _left_stick.x = v
				JOY_AXIS_LEFT_Y: _left_stick.y = v
				JOY_AXIS_RIGHT_X: _right_stick.x = v
				JOY_AXIS_RIGHT_Y: _right_stick.y = v
		InputTypes.RawKind.KEY:
			var keys: Array[InputTypes.InputBinding] = _table.get_bindings(&"mover", InputTypes.Device.KEYBOARD_MOUSE)
			for i: int in mini(keys.size(), 4):
				if keys[i].kind == InputTypes.RawKind.KEY and keys[i].code == raw.code:
					_keys[i] = raw.pressed


## The state's channel exists only after its catalog loads: `_process` retries until it can subscribe.
func _subscribe_loading() -> void:
	if _state == null or _state.get_channel() == null or not _load_subs.is_empty():
		return
	var ch: NoticeChannel = _state.get_channel()
	_load_subs.append(ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_LOAD_STARTED, _on_load_started))
	_load_subs.append(ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_LOAD_FINISHED, _on_load_finished))
	_load_subs.append(ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_LOAD_FAILED, _on_load_failed))


func _unsubscribe_loading() -> void:
	if _state != null and _state.get_channel() != null:
		for h: int in _load_subs:
			_state.get_channel().unsubscribe(h)
	_load_subs.clear()


func _on_load_started(_payload: Dictionary) -> void:
	_stack.set_loading(true)


func _on_load_finished(_payload: Dictionary) -> void:
	_stack.set_loading(false)


func _on_load_failed(_payload: Dictionary) -> void:
	_stack.set_loading(false, true)


func _notify(notice: StringName, payload: Dictionary) -> void:
	if _state == null:
		return
	var channel: NoticeChannel = _state.get_channel()
	if channel != null:
		channel.notify(notice, payload)
