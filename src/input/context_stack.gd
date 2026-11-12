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

## Requester of the `MENU` entry that `restore_menu` installs (ADR-0006 D4).
const MENU_REQUESTER: StringName = &"title"

## Duration used when an owner declares none (ADR-0006 D4: 3 s, logged).
## TODO(input-owner): move to the input tuning file with the rest of the caps (story 005).
const NO_DURATION_S: float = 3.0

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
var _in_game: bool = false
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


## Opens `SIN_CONTROL` for `owner` (ADR-0006 D4). Rejected (false, logged, no notice) when the top is
## already `SIN_CONTROL` (transfer instead) or a foreign `SIN_CONTROL` lies under the top. When
## `absorbs_foreign` and `owner` is `scene_loader`, the whole stack is discarded instead: one
## `input_context_changed` (even if the old top was `SIN_CONTROL`), then one `no_control_absorbed` per
## discarded foreign owner. `declared_s <= 0` becomes `NO_DURATION_S` and is logged.
## Example: `s.open_no_control(InputTypes.OWNER_SCENE_LOADER, 2.0)`.
func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
	if owner == &"":
		return _reject(&"open_without_owner", "")
	var foreign: int = _foreign_index(owner)
	if foreign >= 0 and absorbs_foreign and owner == InputTypes.OWNER_SCENE_LOADER:
		return _discard_and_open(owner, _duration(owner, declared_s))
	if _stack.back().context == InputTypes.Context.SIN_CONTROL:
		return _reject(&"open_on_no_control", owner)
	if foreign >= 0:
		return _reject(&"foreign_no_control_below", owner)
	var prev: InputTypes.Context = top()
	_stack.append(_make_no_control(owner, _duration(owner, declared_s)))
	_emit_change(prev, InputTypes.Context.SIN_CONTROL)
	return true


## Closes the top `SIN_CONTROL`; only its owner may. Restores what is below (a `MENU` below is logged as
## misuse of the owner). Anything else: rejected, logged, no notice.
func close_no_control(owner: StringName) -> bool:
	if not _top_is_owned_by(owner):
		return _reject(&"close_not_owner", owner)
	_stack.pop_back()
	if top() == InputTypes.Context.MENU:
		_log_line(&"warn", "close_restored_menu: %s" % owner)
	_emit_change(InputTypes.Context.SIN_CONTROL, top())
	return true


## Hands the top `SIN_CONTROL` to `new_owner` with a new duration: no pop, no push, NO notice, stack
## unchanged. Rejected (logged) when the top is not `SIN_CONTROL`. `declared_s <= 0` becomes `NO_DURATION_S`.
func transfer_no_control(new_owner: StringName, declared_s: float) -> bool:
	if new_owner == &"" or _stack.back().context != InputTypes.Context.SIN_CONTROL:
		return _reject(&"transfer_without_no_control", new_owner)
	var e: StackEntry = _stack.back()
	e.owner = new_owner
	e.requester = new_owner
	e.declared_s = _duration(new_owner, declared_s)
	# TODO(input-owner): renew `cap_deadline` from the clock in story 005.
	return true


## Owner of the `SIN_CONTROL` on top asks for `EXPLORACION`: the stack becomes `[EXPLORACION]` (any
## `MENU` below is discarded), one notice, `in_game` true. Not the owner: rejected, logged.
func request_exploration(owner: StringName) -> bool:
	if not _top_is_owned_by(owner):
		return _reject(&"exploration_not_owner", owner)
	_stack = [_make(InputTypes.Context.EXPLORACION, owner)]
	_in_game = true
	_emit_change(InputTypes.Context.SIN_CONTROL, InputTypes.Context.EXPLORACION)
	return true


## Stack becomes `[MENU(title)]`; notice only if the top changed; `in_game` false.
## TODO(input-owner): story 005 also clears `carga_en_curso` and drops the pending pause here.
func restore_menu() -> void:
	var prev: InputTypes.Context = top()
	_stack = [_make(InputTypes.Context.MENU, MENU_REQUESTER)]
	_in_game = false
	if prev != InputTypes.Context.MENU:
		_emit_change(prev, InputTypes.Context.MENU)


## True after `request_exploration`, false after `restore_menu` (ADR-0006 D4).
func in_game() -> bool:
	return _in_game


## Owner of the top `SIN_CONTROL`, `&""` when the top is another context.
func no_control_owner() -> StringName:
	var e: StackEntry = _stack.back()
	return e.owner if e.context == InputTypes.Context.SIN_CONTROL else &""


## Declared duration (s) of the top `SIN_CONTROL`, 0 when the top is another context.
func no_control_declared_s() -> float:
	var e: StackEntry = _stack.back()
	return e.declared_s if e.context == InputTypes.Context.SIN_CONTROL else 0.0


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


func _foreign_index(owner: StringName) -> int:
	for i: int in _stack.size():
		var e: StackEntry = _stack[i]
		if e.context == InputTypes.Context.SIN_CONTROL and e.owner != owner:
			return i
	return -1


func _top_is_owned_by(owner: StringName) -> bool:
	var e: StackEntry = _stack.back()
	return e.context == InputTypes.Context.SIN_CONTROL and e.owner == owner and owner != &""


func _duration(owner: StringName, declared_s: float) -> float:
	if declared_s > 0.0:
		return declared_s
	_log_line(&"warn", "no_control_without_duration: %s" % owner)
	return NO_DURATION_S


func _make_no_control(owner: StringName, declared_s: float) -> StackEntry:
	var e: StackEntry = _make(InputTypes.Context.SIN_CONTROL, owner)
	e.owner = owner
	e.declared_s = declared_s
	return e


func _discard_and_open(owner: StringName, declared_s: float) -> bool:
	var prev: InputTypes.Context = top()
	var dropped: Array[StringName] = []
	for old: StackEntry in _stack:
		if old.context == InputTypes.Context.SIN_CONTROL and old.owner != owner and not dropped.has(old.owner):
			dropped.append(old.owner)
	_stack = [_make_no_control(owner, declared_s)]
	_emit_change(prev, InputTypes.Context.SIN_CONTROL)
	if _notifier.is_valid():
		for d: StringName in dropped:
			_notifier.call(NoticeIds.NO_CONTROL_ABSORBED, {&"dueno": d})
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
