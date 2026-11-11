## Sole owner of "pause active" and game time (ADR-0002 D1). Autoload `GameClockAutoload`.
## Skeleton (S0): time and pause holders only.
## TODO(ADR-0002): PauseBackend wiring, configure(), schedule()/cancel()/deadline()/is_due().
class_name GameClock extends Node

## Emitted when the first holder pauses or the last one resumes.
signal paused_changed(is_paused: bool)

## Lowest process priority in the project: delta is computed before any consumer (ADR-0009 D2).
const PROCESS_PRIORITY: int = -1000

var _max_frame_delta_s: float = 0.25 # TODO(ADR-0002): from assets/data/core/clock.json
var _holders: Dictionary[StringName, bool] = {}
var _game_time_s: float = 0.0
var _frame_delta_s: float = 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = PROCESS_PRIORITY


func _process(delta: float) -> void:
	advance(delta)


## Composition point, called once by Boot. Reads nothing (ADR-0009 D2 step 3).
func setup(_ctx: ServiceContext) -> void:
	return


## Seconds of game time since the session clock started. Frozen while paused.
func now() -> float:
	return _game_time_s


## Game-time delta of the current frame; 0.0 while paused.
func delta() -> float:
	return _frame_delta_s


## True while at least one requester holds the pause.
func is_paused() -> bool:
	return not _holders.is_empty()


## Idempotent per requester. Delta becomes 0 immediately.
func pause(requester: StringName) -> void:
	var was_paused: bool = is_paused()
	_holders[requester] = true
	_frame_delta_s = 0.0
	if not was_paused:
		paused_changed.emit(true)


## Releases one requester; time resumes only when no requester holds the pause.
func resume(requester: StringName) -> void:
	if not _holders.has(requester):
		return
	_holders.erase(requester)
	if not is_paused():
		paused_changed.emit(false)


## Public for tests: drives the clock without the engine loop.
func advance(engine_delta_s: float) -> void:
	if is_paused():
		_frame_delta_s = 0.0
		return
	_frame_delta_s = clampf(engine_delta_s, 0.0, _max_frame_delta_s)
	_game_time_s += _frame_delta_s


## New session: clears game time.
func reset_session() -> void:
	_game_time_s = 0.0
	_frame_delta_s = 0.0
