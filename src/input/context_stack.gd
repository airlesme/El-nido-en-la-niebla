## Input context stack and per-(context, action) sinks (ADR-0006 D3/D6; GDD 1 rules 5-6). Pure: no
## engine API, no autoload reads; the notice goes out through an injected `Callable`.
## Only the top context receives actions; entering the top again is ignored; exiting a non-top
## context is rejected and logged; every effective change emits `input_context_changed` once.
## `SIN_CONTROL` is NOT handled here (story 004): `enter`/`exit` reject it.
## Example: `s.enter(InputTypes.Context.MENU, &"pause_menu")`, later `s.exit(InputTypes.Context.MENU, &"pause_menu")`.
class_name ContextStack extends RefCounted

## One stack entry (ADR-0006 D3). `owner`, `declared_s`, `cap_deadline` belong to `SIN_CONTROL` (story 004).
class StackEntry extends RefCounted:
	var context: InputTypes.Context
	var requester: StringName
	var cursor_pos: Vector2 = Vector2.ZERO
	var owner: StringName = &""
	var declared_s: float = 0.0
	var cap_deadline: float = INF

## Requester of the base entry.
const BASE_REQUESTER: StringName = &"input_router"

## Actions each context accepts (GDD 1 § States and Transitions). TODO(input-owner): move to data
## once the per-context precedence list (ADR-0006 D6) has a file; `ui_*` focus navigation is native GUI.
const _ALLOWED: Dictionary = {
	InputTypes.Context.EXPLORACION: [&"mover", &"mirar", &"interactuar", &"pausa", &"atrás", &"repasar_bolsillo"],
	InputTypes.Context.INSPECCION: [&"rotar_objeto", &"atrás", &"pausa"],
	InputTypes.Context.LECTURA: [&"atrás", &"interactuar", &"pausa"],
	InputTypes.Context.VISTA_CERCANA: [&"mover_cursor", &"seleccionar", &"atrás", &"pausa"],
	InputTypes.Context.ORDENADOR: [&"mover_cursor", &"seleccionar", &"atrás", &"pausa"],
	InputTypes.Context.LLAMADA: [&"mover_cursor", &"seleccionar", &"pausa"],
	InputTypes.Context.MENU: [&"mover_cursor", &"ui_aceptar", &"ui_atrás"],
	InputTypes.Context.SIN_CONTROL: [&"pausa"],
}

var _stack: Array[StackEntry] = []
var _sinks: Dictionary = {} # String "ctx/action" -> Callable
var _log: LogSink
var _notifier: Callable


## `log` receives rejections; `notifier` is `func(notice: StringName, payload: Dictionary)`
## (typically `state.get_channel().notify`). Either may be null/invalid: nothing is then emitted/logged.
func _init(log: LogSink = null, notifier: Callable = Callable()) -> void:
	_log = log
	_notifier = notifier
	_stack.append(_make(InputTypes.Context.EXPLORACION, BASE_REQUESTER))


## Replaces the log seam (the router passes `ctx.logger` in `setup`).
func set_log(log: LogSink) -> void:
	_log = log


## Replaces the notice emitter (the router injects the bus once it exists).
func set_notifier(notifier: Callable) -> void:
	_notifier = notifier


## Context on top of the stack (never empty: the base is `EXPLORACION`).
func top() -> InputTypes.Context:
	return _stack.back().context


## Number of entries (>= 1).
func depth() -> int:
	return _stack.size()


## Pushes `ctx`. Returns true only on an effective change. Ignored (false, no notice) when `ctx` is
## already on top; rejected (false, logged) for `SIN_CONTROL`, an unknown value or an empty requester.
func enter(ctx: InputTypes.Context, requester: StringName) -> bool:
	if not _is_generic(ctx):
		return _reject(&"enter_invalid_context", "context %s" % str(ctx))
	if requester == &"":
		return _reject(&"enter_without_requester", _name(ctx))
	var prev: InputTypes.Context = top()
	if ctx == prev:
		return false
	_stack.append(_make(ctx, requester))
	_emit_change(prev, ctx)
	return true


## Pops `ctx`, which must be the top entry and requested by the same `requester`. Anything else is
## rejected, logged, and leaves the stack unchanged. The base `EXPLORACION` cannot be popped.
func exit(ctx: InputTypes.Context, requester: StringName) -> bool:
	if not _is_generic(ctx):
		return _reject(&"exit_invalid_context", "context %s" % str(ctx))
	var entry: StackEntry = _stack.back()
	if entry.context != ctx or entry.requester != requester or _stack.size() == 1:
		return _reject(&"exit_not_top", "%s by %s" % [_name(ctx), requester])
	var prev: InputTypes.Context = entry.context
	_stack.pop_back()
	_emit_change(prev, top())
	return true


## Remembers the cursor (logical px) in the top entry; restored when the entries above it exit.
func set_cursor_pos(pos: Vector2) -> void:
	_stack.back().cursor_pos = pos


## Cursor stored in the top entry.
func cursor_pos() -> Vector2:
	return _stack.back().cursor_pos


## True when the top context accepts `action` (GDD 1 rule 5: other contexts' actions do not exist).
func accepts(action: StringName) -> bool:
	var allowed: Array = _ALLOWED.get(top(), [])
	return allowed.has(action)


## Registers the single sink `Callable(ev: ActionEvent)` of (ctx, action). A second bind replaces it
## and logs (F-R44). An invalid callable is rejected.
func bind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable) -> void:
	if not sink.is_valid():
		_reject(&"bind_invalid_sink", "%s/%s" % [_name(ctx), action])
		return
	var key: String = _key(ctx, action)
	if _sinks.has(key) and _sinks[key] != sink:
		_log_line(&"warn", "sink_replaced: %s/%s" % [_name(ctx), action])
	_sinks[key] = sink


## Removes the sink only if it is `sink` (a stale owner cannot unbind its successor). Unknown: no-op.
func unbind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable) -> void:
	var key: String = _key(ctx, action)
	if _sinks.get(key) == sink:
		_sinks.erase(key)


## True when (ctx, action) has a sink.
func has_sink(ctx: InputTypes.Context, action: StringName) -> bool:
	return _sinks.has(_key(ctx, action))


## Delivers `ev` to the sink of (top, `ev.action`). Dropped (false) when the top does not accept the
## action or has no sink. A sink whose target was freed is unbound instead of called (F-R31).
func deliver(ev: InputTypes.ActionEvent) -> bool:
	if ev == null or not accepts(ev.action):
		return false
	var key: String = _key(top(), ev.action)
	var sink: Callable = _sinks.get(key, Callable())
	if not sink.is_valid():
		_sinks.erase(key)
		return false
	sink.call(ev)
	return true


func _make(ctx: InputTypes.Context, requester: StringName) -> StackEntry:
	var e: StackEntry = StackEntry.new()
	e.context = ctx
	e.requester = requester
	return e


func _is_generic(ctx: int) -> bool:
	return ctx != InputTypes.Context.SIN_CONTROL and InputTypes.Context.values().has(ctx)


func _key(ctx: InputTypes.Context, action: StringName) -> String:
	return "%d/%s" % [ctx, action]


## Notice name of a context: the enum key in lowercase ASCII (`&"exploracion"`, `&"vista_cercana"`).
## TODO(input-owner): ADR-0001's registry only says `SN`; confirm the spelling with GDD 1 when a listener exists.
func _name(ctx: int) -> StringName:
	var keys: Array = InputTypes.Context.keys()
	var values: Array = InputTypes.Context.values()
	var i: int = values.find(ctx)
	return StringName(String(keys[i]).to_lower()) if i >= 0 else &"unknown"


func _emit_change(prev: InputTypes.Context, next: InputTypes.Context) -> void:
	if _notifier.is_valid():
		_notifier.call(NoticeIds.INPUT_CONTEXT_CHANGED, {&"anterior": _name(prev), &"contexto": _name(next)})


func _reject(rule: StringName, detail: String) -> bool:
	_log_line(&"error", "%s: %s" % [rule, detail])
	return false


func _log_line(level: StringName, msg: String) -> void:
	if _log != null:
		_log.line(level, "[input] " + msg)
