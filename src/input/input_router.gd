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
	_state = ctx.state


## Injects the state whose channel carries `input_context_changed` (tests; `setup` does it from the context).
func use_state(state: GameState) -> void:
	_state = state


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


## Single entry of raw input; called only by the adapter and by tests. Resolves the FIRST action bound
## to `raw` (F-R46) and emits `action_fed`; axes and mouse motion without a binding emit nothing.
## Example: `router.feed(raw_e_pressed)` emits `action_fed(&"interactuar", true)`.
func feed(raw: InputTypes.RawInput) -> void:
	if raw == null or _table == null:
		return
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


func _notify(notice: StringName, payload: Dictionary) -> void:
	if _state == null:
		return
	var channel: NoticeChannel = _state.get_channel()
	if channel != null:
		channel.notify(notice, payload)
