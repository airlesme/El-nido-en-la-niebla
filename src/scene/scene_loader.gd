## World scene loader and curtain (system 4). Registered as autoload `SceneLoaderAutoload` (ADR-0009 D1).
## CP-004 scope: public states and the `request_load` preconditions (ADR-0003). What happens after
## a request is accepted (the 9-step sequence) is story 005; Error is 008; full unload is 009.
## Example: `if scenes.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.PARTIDA_NUEVA, SceneLoader.FinalControl.EXPLORACION): ...`.
## TODO(ADR-0003): amend § Key Interfaces: `setup(ctx)` (ADR-0009 D2) replaces the 6-parameter form.
class_name SceneLoader extends Node

## The 4 public states of GDD 4.
enum State { NO_SCENE, LOADING, READY, ERROR }
enum Destination { PLANTA, RECEPCION }
enum Reason { PARTIDA_NUEVA, REANUDAR, RECEPCION }
enum FinalControl { EXPLORACION, NINGUNO }

## Fatal code for a rejected request in dev builds.
## TODO(ADR-0009): register this code in FatalErrorHandler's list (owner: ADR-0009 / core).
const FATAL_LOAD_REJECTED: StringName = &"PETICION_DE_CARGA_RECHAZADA"
const FACT_CALL_COMPLETED: StringName = &"llamada_completada"

var _ctx: ServiceContext
var _source: SceneSource
var _state: State = State.NO_SCENE
var _loaded: int = LoadPreconditions.NONE_LOADED
var _pending_destination: Destination = Destination.PLANTA
var _pending_reason: Reason = Reason.PARTIDA_NUEVA
var _pending_final_control: FinalControl = FinalControl.EXPLORACION


func _init() -> void:
	# ADR-0009 D2: explicit, never inherited. No I/O, no autoload reads here.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Composition point, called once by Boot (ADR-0009 D2/D3). Never called by systems.
## TODO(carga-005): SceneSource, Curtain, InputContexts, RealClock and LoadTransitions via ctx.require.
func setup(ctx: ServiceContext) -> void:
	_ctx = ctx


## Injects the scene source (ADR-0003 D4). Tests pass a fake; Boot wires the real one (story 005).
func set_source(source: SceneSource) -> void:
	_source = source


## Current public state.
func get_state() -> State:
	return _state


## «petición de carga». Returns false when rejected by a precondition (ADR-0003): dev raises the
## fatal handler, release logs one line. A rejection changes nothing and never touches the source.
## On acceptance the state becomes LOADING and the request is kept for story 005.
func request_load(destination: Destination, reason: Reason, final_control: FinalControl) -> bool:
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
	return true


## Runtime seam for stories 005/008/009 and tests: sets the state and which game scene is loaded
## (`loaded` is a Destination value or LoadPreconditions.NONE_LOADED).
## TODO(carga-005): replace by the real transitions of the load sequence.
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
