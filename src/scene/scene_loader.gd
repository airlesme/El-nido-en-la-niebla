## World scene loader and curtain (system 4). Registered as autoload `SceneLoaderAutoload` (ADR-0009 D1).
## CP-004: public states and the `request_load` preconditions. CP-005 (this file): the 9-step load
## sequence as a per-frame machine (ADR-0003 § Load sequence): «iniciada» -> curtain to alpha 1 -> unload
## in frame U -> instantiate in U+1 -> `colocar` -> `configure_all` -> «escena lista» -> N_gap frames ->
## curtain in -> «terminada». Time comes ONLY from the injected RealClock (no Timer/Tween, ADR-0002 D6).
## Holds/T_cap are 007, failures/ErrorPanel 008, the full unload (`request_full_unload`) is 009.
## The machine is dormant (state LOADING, nothing runs) until `wire_sequence` supplies its collaborators.
## Example: `if scenes.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.PARTIDA_NUEVA, SceneLoader.FinalControl.EXPLORACION): ...`.
## TODO(ADR-0003): amend § Key Interfaces: `setup(ctx)` (ADR-0009 D2) replaces the 6-parameter form, and
## `wire_sequence(...)` supplies slot/transitions/clock/input/curtain sink (owner: lead-programmer).
class_name SceneLoader extends Node

## The 4 public states of GDD 4.
enum State { NO_SCENE, LOADING, READY, ERROR }
enum Destination { PLANTA, RECEPCION }
enum Reason { PARTIDA_NUEVA, REANUDAR, RECEPCION }
enum FinalControl { EXPLORACION, NINGUNO }
## Phases of the machine (ADR-0003 Key Interfaces). The last three belong to the full unload (CP-009).
enum Phase { IDLE, FADING_OUT, UNLOADING, INSTANTIATING, WAITING_HOLDS, GAP, FADING_IN,
		UNLOAD_FADING, UNLOAD_FREEING, TITLE_PENDING }

## Fatal code for a rejected request in dev builds.
## TODO(ADR-0009): register this code in FatalErrorHandler's list (owner: ADR-0009 / core).
const FATAL_LOAD_REJECTED: StringName = &"PETICION_DE_CARGA_RECHAZADA"
const FACT_CALL_COMPLETED: StringName = &"llamada_completada"
## Mirror of `GameSceneRoot.ConfigureResult` (ADR-0003 Key Interfaces).
## TODO(carga-012): replace by `GameSceneRoot.ConfigureResult` when the real root exists (owner: carga-012).
const CONFIGURE_OK: int = 0
const CONFIGURE_INVALID_PUZZLE_DATA: int = 1
## Failure causes of the machine (ADR-0003 Failure). Story 008 owns the error state UI.
const CAUSE_INSTANTIATE_FAILED: StringName = &"instantiate_failed"
const CAUSE_PREVIOUS_NOT_FREED: StringName = &"previous_scene_not_freed"
const CAUSE_MISSING_ANCHOR: StringName = &"missing_anchor"
const CAUSE_INVALID_PUZZLE_DATA: StringName = &"invalid_puzzle_data"
const CAUSE_T_CAP: StringName = &"t_cap"
const CAUSE_MISSING_RESOURCE: StringName = &"missing_resource"
const CAUSE_MISSING_CONTAINER: StringName = &"missing_container"
## Fatal codes of dev builds: every failure goes to the injected handler first (ADR-0003 Failure).
## TODO(ADR-0009): register these codes in FatalErrorHandler's list (owner: ADR-0009 / core).
const FATAL_LOAD_FAILED: StringName = &"CARGA_DE_ESCENA_FALLIDA"
const FATAL_DUPLICATE_ANCHOR: StringName = &"ANCLA_DUPLICADA"
## Required nodes that are containers (the other required names are anchors/slots). M1 list of GameSceneRoot.
const CONTAINER_NAMES: PackedStringArray = ["office", "corridor", "archive"]

var _ctx: ServiceContext
var _source: SceneSource
var _state: State = State.NO_SCENE
var _loaded: int = LoadPreconditions.NONE_LOADED
var _pending_destination: Destination = Destination.PLANTA
var _pending_reason: Reason = Reason.PARTIDA_NUEVA
var _pending_final_control: FinalControl = FinalControl.EXPLORACION

var _slot: Node3D
var _transitions: LoadTransitions
var _clock: RealClock
var _input: InputContexts
## Callable(alpha: float) -> void; applies the curtain opacity to the visual Curtain.
var _alpha_sink: Callable = Callable()
## Callable() -> bool; reads `reducir_movimiento` once per load.
## TODO(settings-owner): Settings (ADR-0007) does not expose it yet; false until it does.
var _reduced_motion: Callable = Callable()
var _curtain: CurtainMath = CurtainMath.new()
var _phase: Phase = Phase.IDLE
var _d_out: float = 0.0
var _d_in: float = 0.0
var _d_load: float = 0.0
var _t_started_ms: int = 0
var _last_ms: int = 0
var _frame_dt: float = 0.0
var _gap_left: int = 0
var _t_dark_ms: int = 0
## Holder IDs of the holds (set semantics; values unused). Valid only while `_holds_open`.
var _holds: Dictionary[StringName, bool] = {}
var _holds_open: bool = false
var _old: Node = null
var _current_root: Node = null
## Cause of the last failure (`&""` while no failure is active). Valid in State.ERROR.
var _failure_cause: StringName = &""
## Callable(cause: StringName) -> void; asks the UI for the ErrorPanel with the single action
## «Volver al título». Its view is story 014; accepting it must call `request_full_unload()` (story 009).
var _error_panel_request: Callable = Callable()
## Real time (ms) at which the accepted full unload started (`t_unload` of ADR-0003).
var _t_unload_start_ms: int = 0


func _init() -> void:
	# ADR-0009 D2: explicit, never inherited. No I/O, no autoload reads here.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false) # enabled only while a load runs


func _process(_delta: float) -> void:
	tick()


## Composition point, called once by Boot (ADR-0009 D2/D3). Never called by systems.
## TODO(carga-005): SceneSource, Curtain, InputContexts, RealClock and LoadTransitions via ctx.require.
func setup(ctx: ServiceContext) -> void:
	_ctx = ctx


## Injects the scene source (ADR-0003 D4). Tests pass a fake; Boot wires the real one.
func set_source(source: SceneSource) -> void:
	_source = source


## Supplies the collaborators of the load sequence (ADR-0003 D4/D5). `slot` is the Shell's WorldSlot;
## `alpha_sink` is `Callable(alpha: float)` applying the curtain opacity; `input` may be null (no `sin control`).
## Example: `loader.wire_sequence(shell.world_slot, transitions, ctx.real_clock, input_port, curtain_rect_setter)`.
func wire_sequence(slot: Node3D, transitions: LoadTransitions, clock: RealClock, input: InputContexts,
		alpha_sink: Callable, reduced_motion: Callable = Callable()) -> void:
	_slot = slot
	_transitions = transitions
	_clock = clock
	_input = input
	_alpha_sink = alpha_sink
	_reduced_motion = reduced_motion


## Port to the error message: `request(cause: StringName)` is called once per failure, after the curtain
## is held at alpha 1 and Entrada has `restore_menu`. The visible panel is story 014.
## TODO(carga-014): the panel's accept action calls `request_full_unload()` (owner: carga-014).
## Example: `loader.set_error_panel_port(func(cause: StringName) -> void: panel.show_error(cause))`.
func set_error_panel_port(request: Callable) -> void:
	_error_panel_request = request


## Cause of the current failure (`&""` unless the state is ERROR).
func get_failure_cause() -> StringName:
	return _failure_cause


## Current public state.
func get_state() -> State:
	return _state


## Current phase of the load machine.
func get_phase() -> Phase:
	return _phase


## Current curtain opacity in [0, 1].
func get_curtain_alpha() -> float:
	return _curtain.alpha


## One frame of the machine, driven by `_process` (the engine delta is ignored on purpose: real time only).
## Public so tests can drive it frame by frame against an injected clock.
func tick() -> void:
	if _phase == Phase.IDLE or _clock == null:
		return
	var now: int = _clock.now_ms()
	_frame_dt = float(now - _last_ms) / 1000.0
	_last_ms = now
	match _phase:
		Phase.FADING_OUT:
			var dark: bool = _curtain.step_out(_frame_dt, _transitions.delta_max_s, _d_out)
			_apply_alpha()
			if dark:
				_t_dark_ms = now # alpha = 1: `t_espera` starts here (TR-scene-013)
				_phase = Phase.UNLOADING
				_unload_current()
				_phase = Phase.INSTANTIATING
		Phase.INSTANTIATING:
			_instantiate_and_configure()
		Phase.WAITING_HOLDS:
			_wait_step()
		Phase.GAP:
			_gap_left -= 1
			if _gap_left <= 0:
				_begin_fade_in()
		Phase.FADING_IN:
			_step_fade_in()
		Phase.UNLOAD_FADING:
			_step_unload_fade(now)
		Phase.UNLOAD_FREEING:
			_step_unload_freed(now)
		Phase.TITLE_PENDING:
			_step_title_pending()
		_:
			pass


## «petición de carga». Returns false when rejected by a precondition (ADR-0003): dev raises the
## fatal handler, release logs one line. A rejection changes nothing and never touches the source.
## On acceptance the state becomes LOADING and, when wired, the 9-step sequence starts (frame F).
func request_load(destination: Destination, reason: Reason, final_control: FinalControl) -> bool:
	if _is_unloading():
		_ctx.logger.line(LogSink.LEVEL_ERROR, "request_load rejected: a full unload is running")
		return false
	var state_ready: bool = _ctx.state != null and _ctx.state.get_status() == GameState.Status.READY
	var call_completed: bool = false
	if destination == Destination.RECEPCION and state_ready:
		call_completed = _ctx.state.get_fact(FACT_CALL_COMPLETED) == true
	var verdict: LoadPreconditions.Verdict = LoadPreconditions.check(
			_state, _loaded, destination, state_ready, call_completed)
	if verdict != LoadPreconditions.Verdict.OK:
		_reject(verdict, destination, reason)
		return false
	_pending_destination = destination
	_pending_reason = reason
	_pending_final_control = final_control
	_state = State.LOADING
	if _transitions != null and _clock != null and _slot != null:
		_start_sequence()
	return true


## Runtime seam for stories 008/009 and tests: sets the state and which game scene is loaded
## (`loaded` is a Destination value or LoadPreconditions.NONE_LOADED).
## The load sequence drives these fields itself; the seam stays for 008/009 and tests.
func set_runtime_state(state: State, loaded: int = LoadPreconditions.NONE_LOADED) -> void:
	_state = state
	_loaded = loaded


func _reject(verdict: LoadPreconditions.Verdict, destination: Destination, reason: Reason) -> void:
	var why: String = LoadPreconditions.describe(verdict)
	var detail: Dictionary = {
		&"param": &"request_load", &"rule": StringName(why),
		&"destination": Destination.keys()[destination], &"reason": Reason.keys()[reason],
		&"state": State.keys()[_state],
	}
	if _ctx.flavor != null and _ctx.flavor.is_debug():
		_ctx.fatal.raise_fatal(FATAL_LOAD_REJECTED, detail)
	else:
		_ctx.logger.line(LogSink.LEVEL_ERROR, "request_load rejected: %s" % str(detail))


# --- Load sequence (CP-005) ---

# Steps 0-1 (frame F): resolve durations, «iniciada», then `sin control`; the curtain is untouched yet.
func _start_sequence() -> void:
	var reduced: bool = _reduced_motion.is_valid() and bool(_reduced_motion.call())
	var motivo: StringName = _reason_key(_pending_reason)
	_d_out = LoadBudget.d_out(_transitions, motivo, reduced)
	_d_in = LoadBudget.d_in(_transitions, motivo, reduced)
	_d_load = LoadBudget.d_carga(_transitions, motivo)
	_t_started_ms = _clock.now_ms()
	_last_ms = _t_started_ms
	_notify(NoticeIds.SCENE_LOAD_STARTED, {
		&"destino": _dest_key(), &"motivo": motivo,
		&"control_final": _final_key(), &"D_carga": _d_load,
	})
	if _input != null:
		_input.open_no_control(InputTypes.OWNER_SCENE_LOADER, _d_load,
				_pending_reason != Reason.RECEPCION)
	_curtain.begin_out()
	_phase = Phase.FADING_OUT
	set_process(true)


# Step 3. Unbinding the scene adapters (ADR-0009 D6) hangs here.
# TODO(adr-0009-d6): SYNC `unbind_scene()` on 21, 23 and Shell adapters (owner: ADR-0009 / carga-012).
func _unload_current() -> void:
	if _slot.get_child_count() == 0:
		return
	var child: Node = _slot.get_child(0)
	if _loaded != LoadPreconditions.NONE_LOADED and _input != null:
		_input.reset_stack_on_unload() # never for the title (D2); `_loaded` is NONE then
	_slot.remove_child(child)
	child.queue_free()
	_old = child
	_current_root = null
	_loaded = LoadPreconditions.NONE_LOADED


# Steps 4-6, frame U+1.
func _instantiate_and_configure() -> void:
	if _old != null and is_instance_valid(_old):
		_fail(CAUSE_PREVIOUS_NOT_FREED)
		return
	_old = null
	if is_inside_tree() and get_tree().paused:
		_ctx.logger.line(LogSink.LEVEL_ERROR, "load: instantiating with the tree paused (ADR-0002 G-11)")
	if _ctx.clock != null:
		_ctx.clock.reset_session() # OI-3: immediately before instantiating
	var root: Node = _source.instantiate(_dest_key()) if _source != null else null
	if root == null:
		var why: StringName = _source.last_failure if _source != null else &""
		_fail(CAUSE_MISSING_RESOURCE if why == CAUSE_MISSING_RESOURCE else CAUSE_INSTANTIATE_FAILED)
		return
	_slot.add_child(root)
	_current_root = root
	if root.has_method(&"validate_required_nodes"):
		var missing: PackedStringArray = root.call(&"validate_required_nodes")
		if not missing.is_empty():
			_fail(_missing_cause(missing))
			return
	if not _place_player(root):
		_fail(CAUSE_MISSING_ANCHOR)
		return
	_holds.clear()
	_holds_open = true # step 6 starts: the holds window opens
	var result: int = CONFIGURE_OK
	if root.has_method(&"configure_all"):
		result = int(root.call(&"configure_all", _ctx))
	if result == CONFIGURE_INVALID_PUZZLE_DATA:
		_fail(CAUSE_INVALID_PUZZLE_DATA) # immediate: no T_cap wait
		return
	_phase = Phase.WAITING_HOLDS
	_wait_step()


## Takes a hold on «escena lista» (ADR-0003 D5). Idempotent per `holder_id` (`&"<system>:<element_id>"`, C-R06).
## Outside the window (before step 6 or after «escena lista») it is ignored and logged.
## TODO(carga-007): dev builds should also surface a visible error in-game (owner: carga-008, error UI).
func take_hold(holder_id: StringName) -> void:
	if not _holds_open:
		_ctx.logger.line(LogSink.LEVEL_ERROR, "take_hold ignored outside the holds window: %s" % holder_id)
		return
	_holds[holder_id] = true


## Releases the hold of `holder_id`; a missing or repeated release is a no-op (never below 0).
func release_hold(holder_id: StringName) -> void:
	_holds.erase(holder_id)


## Number of holds currently taken (`n_ret`).
func get_hold_count() -> int:
	return _holds.size()


# Each frame of the wait (ADR-0003): holds still pending at `t_espera >= T_cap` fail with their IDs;
# an empty set emits «escena lista» (same frame as configure when no holds were taken).
func _wait_step() -> void:
	var t_espera_ms: int = _clock.now_ms() - _t_dark_ms
	if float(t_espera_ms) / 1000.0 >= _transitions.t_cap_s and not _holds.is_empty():
		var ids: Array[StringName] = _holds.keys()
		ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
		_fail(CAUSE_T_CAP, ids)
		return
	if _holds.is_empty():
		_scene_ready()


# Step 5: `colocar(anchor position, yaw, pitch 0)` from the spawn anchor (C-R08).
# TODO(carga-012): typed against GameSceneRoot/Player once they exist; duck-typed meanwhile (owner: carga-012).
func _place_player(root: Node) -> bool:
	var anchor_path: Variant = root.get(&"spawn_anchor")
	if not root.has_method(&"get_player") or not anchor_path is NodePath:
		return false
	var anchor: Node3D = root.get_node_or_null(anchor_path as NodePath) as Node3D
	var player: Object = root.call(&"get_player") as Object
	if anchor == null or player == null or not player.has_method(&"colocar"):
		return false
	anchor = _resolve_duplicate_anchors(root, anchor)
	var pos: Vector3 = anchor.global_position if anchor.is_inside_tree() else anchor.position
	var yaw: float = anchor.global_rotation.y if anchor.is_inside_tree() else anchor.rotation.y
	player.call(&"colocar", pos, yaw, 0.0)
	return true


# Anchors with the same name (R4, AC-15c): dev raises a visible error through the fatal handler;
# the final build uses the first in tree order and logs one line.
func _resolve_duplicate_anchors(root: Node, anchor: Node3D) -> Node3D:
	var same: Array[Node] = root.find_children(String(anchor.name), "Node3D", true, false)
	if same.size() <= 1:
		return anchor
	var detail: Dictionary = {&"param": &"spawn_anchor", &"name": anchor.name, &"count": same.size()}
	if _ctx.flavor != null and _ctx.flavor.is_debug():
		_ctx.fatal.raise_fatal(FATAL_DUPLICATE_ANCHOR, detail)
	else:
		_ctx.logger.line(LogSink.LEVEL_ERROR, "duplicate spawn anchor, using the first in tree order: %s" % str(detail))
	return same[0] as Node3D


# Containers missing take precedence over anchors/slots in the reported cause.
func _missing_cause(missing: PackedStringArray) -> StringName:
	for node_name: String in missing:
		if CONTAINER_NAMES.has(node_name):
			return CAUSE_MISSING_CONTAINER
	return CAUSE_MISSING_ANCHOR


# Step 7.
func _scene_ready() -> void:
	_holds_open = false
	# TODO(adr-0009-d6): SYNC `bind_scene(scene_ctx)` on 21, 23 and Shell adapters.
	_notify(NoticeIds.SCENE_READY, {&"destino": _dest_key()})
	_gap_left = _transitions.n_gap
	if _gap_left > 0:
		_phase = Phase.GAP
	else:
		_begin_fade_in()


# Step 8: the first step of the curtain in happens in the frame L + N_gap.
func _begin_fade_in() -> void:
	_curtain.begin_in()
	_phase = Phase.FADING_IN
	_step_fade_in()


func _step_fade_in() -> void:
	var clear: bool = _curtain.step_in(_frame_dt, _transitions.delta_max_s, _d_in)
	_apply_alpha()
	if clear:
		_finish()


# Step 9.
func _finish() -> void:
	_phase = Phase.IDLE
	_state = State.READY
	_loaded = _pending_destination
	set_process(false)
	var hub: Object = null
	if _current_root != null and _current_root.has_method(&"get_zone_hub"):
		hub = _current_root.call(&"get_zone_hub") as Object
	if hub != null and hub.has_method(&"set_enabled"):
		hub.call(&"set_enabled", true) # TODO(carga-011): real ZoneHub wiring
	_notify(NoticeIds.SCENE_LOAD_FINISHED, {
		&"destino": _dest_key(), &"motivo": _reason_key(_pending_reason),
		&"control_final": _final_key(),
		&"t_since_started_s": float(_clock.now_ms() - _t_started_ms) / 1000.0,
	})
	if _pending_final_control == FinalControl.EXPLORACION and _input != null:
		_input.request_exploration(InputTypes.OWNER_SCENE_LOADER)
	if _pending_destination == Destination.RECEPCION:
		_notify(NoticeIds.GAME_FINISHED, {})


# Failure contract (ADR-0003 Failure): dev fatal handler first, curtain held at alpha 1, log with the cause,
# «carga de escena fallida», `restore_menu`, state Error, ErrorPanel request. Never «escena lista»,
# «terminada», «partida terminada» nor «descarga total completada» from here.
# `request_full_unload()` (accepted from ERROR) is the only exit (story 009).
func _fail(cause: StringName, pending_ids: Array[StringName] = []) -> void:
	_holds_open = false
	_phase = Phase.IDLE
	_state = State.ERROR
	_failure_cause = cause
	set_process(false)
	_curtain.alpha = 1.0 # never reveal a half scene
	_apply_alpha()
	_ctx.logger.line(LogSink.LEVEL_ERROR, "scene load failed: %s pending=%s" % [cause, pending_ids])
	if _ctx.flavor != null and _ctx.flavor.is_debug():
		_ctx.fatal.raise_fatal(FATAL_LOAD_FAILED, {
			&"param": &"load", &"destino": _dest_key(), &"motivo": _reason_key(_pending_reason),
			&"causa": cause, &"pending": pending_ids,
		})
	_notify(NoticeIds.SCENE_LOAD_FAILED, {
		&"destino": _dest_key(), &"motivo": _reason_key(_pending_reason), &"causa": cause,
	})
	if _input != null:
		_input.restore_menu()
	if _error_panel_request.is_valid():
		_error_panel_request.call(cause)


# --- Full unload (CP-009, ADR-0003 § Full unload) ---

## «descarga total»: Lista/Error -> Sin escena -> curtain to alpha 1 (`reducir_movimiento_s` if alpha < 1) ->
## `queue_free` of the slot child at U (NO input stack reset) -> at U+1 `restore_menu`, «descarga total completada»
## (and a log warning when `t_unload > t_descarga_total_max_s`) -> `title.tscn` once the notice queue is empty.
## Returns false (one error line, nothing changes) from Cargando, from Sin escena, while another unload runs, or
## when the sequence is not wired. It is the only path to «descarga total completada» (C-R02).
## Runs with the tree paused: the loader is PROCESS_MODE_ALWAYS (ADR-0002).
## Example: `if scenes.request_full_unload(): pass  # «Volver al título»`.
## TODO(carga-014): the ErrorPanel accept action and the pause menu (25) call this (owner: carga-014).
func request_full_unload() -> bool:
	var wired: bool = _transitions != null and _clock != null and _slot != null
	if (_state != State.READY and _state != State.ERROR) or _phase != Phase.IDLE or not wired:
		_ctx.logger.line(LogSink.LEVEL_ERROR, "request_full_unload rejected: state=%s phase=%s wired=%s" % [
				State.keys()[_state], Phase.keys()[_phase], wired])
		return false
	_notify(NoticeIds.FULL_UNLOAD_REQUESTED, {})
	_state = State.NO_SCENE
	_failure_cause = &""
	_holds_open = false
	_t_unload_start_ms = _clock.now_ms()
	_last_ms = _t_unload_start_ms
	_curtain.begin_out() # from the current opacity: alpha 1 (Error / after `cierre`) finishes in the same frame
	_phase = Phase.UNLOAD_FADING
	set_process(true)
	return true


# Steps 2-3: darken (0,1 s) and, at alpha = 1, free the slot child without touching the input stack.
func _step_unload_fade(_now: int) -> void:
	var dark: bool = _curtain.step_out(_frame_dt, _transitions.delta_max_s, _transitions.reduced_motion_s)
	_apply_alpha()
	if not dark:
		return
	# TODO(adr-0009-d6): SYNC `unbind_scene()` on 21, 23 and Shell adapters (owner: ADR-0009 / carga-012).
	_old = null
	for child: Node in _slot.get_children():
		_slot.remove_child(child)
		child.queue_free()
		_old = child
	_current_root = null
	_loaded = LoadPreconditions.NONE_LOADED
	_phase = Phase.UNLOAD_FREEING


# Step 4 (U+1): the old scene must be gone; then `menu` is restored and «completada» goes out.
func _step_unload_freed(now: int) -> void:
	if _old != null and is_instance_valid(_old):
		_ctx.logger.line(LogSink.LEVEL_ERROR, "full unload: the previous scene was not freed in U+1")
	_old = null
	if _input != null:
		_input.restore_menu()
	var t_unload_s: float = float(now - _t_unload_start_ms) / 1000.0
	_phase = Phase.TITLE_PENDING
	_notify(NoticeIds.FULL_UNLOAD_COMPLETED, {})
	if t_unload_s > _transitions.t_descarga_total_max_s:
		_ctx.logger.line(LogSink.LEVEL_WARN, "full unload took %.3f s (> %.3f s)" % [
				t_unload_s, _transitions.t_descarga_total_max_s])


# Step 5: the title goes in behind the black curtain once nobody has pending notices. Its lift is O4 (open).
func _step_title_pending() -> void:
	var channel: NoticeChannel = _ctx.state.get_channel() if _ctx.state != null else null
	if channel != null and not channel.is_queue_empty():
		return
	_phase = Phase.IDLE
	set_process(false)
	var title: Node = _source.instantiate(SceneSource.TITLE) if _source != null else null
	if title == null:
		_ctx.logger.line(LogSink.LEVEL_ERROR, "full unload: the title could not be instantiated")
		return
	_slot.add_child(title)


func _is_unloading() -> bool:
	return _phase == Phase.UNLOAD_FADING or _phase == Phase.UNLOAD_FREEING or _phase == Phase.TITLE_PENDING


func _apply_alpha() -> void:
	if _alpha_sink.is_valid():
		_alpha_sink.call(_curtain.alpha)


func _notify(notice: StringName, payload: Dictionary) -> void:
	if _ctx.state == null:
		return
	var channel: NoticeChannel = _ctx.state.get_channel()
	if channel != null:
		channel.notify(notice, payload)


func _dest_key() -> StringName:
	return &"planta" if _pending_destination == Destination.PLANTA else &"recepcion"


func _final_key() -> StringName:
	return &"exploracion" if _pending_final_control == FinalControl.EXPLORACION else &"ninguno"


func _reason_key(reason: Reason) -> StringName:
	match reason:
		Reason.PARTIDA_NUEVA:
			return LoadTransitions.MOTIVO_PARTIDA_NUEVA
		Reason.REANUDAR:
			return LoadTransitions.MOTIVO_REANUDAR
		_:
			return LoadTransitions.MOTIVO_RECEPCION
