## Pure decision of the `request_load` preconditions (ADR-0003 § Preconditions of `request_load`,
## GDD 4 rules 7 and 13). No engine, no state: the caller hands in what it observed.
## Example: `LoadPreconditions.check(SceneLoader.State.READY, -1, SceneLoader.Destination.PLANTA, true, false)`.
class_name LoadPreconditions extends RefCounted

## Why a request is rejected; OK means accepted.
enum Verdict {
	OK,
	LOADING, ## state is Cargando (includes a second request in the same frame)
	IN_ERROR, ## state is Error
	STATE_NOT_READY, ## GameState not Listo, or restoring
	CALL_NOT_COMPLETED, ## recepcion while `llamada_completada` is false (rule 13)
	PLANTA_WITH_RECEPCION, ## planta while recepcion is loaded
	RECEPCION_FROM_NO_SCENE, ## recepcion with nothing loaded
}

## Value of `loaded` when no game scene is loaded.
const NONE_LOADED: int = -1


## `loaded` is a `SceneLoader.Destination` value or NONE_LOADED. Checks run in the ADR's order.
static func check(state: SceneLoader.State, loaded: int, destination: SceneLoader.Destination,
		game_state_ready: bool, call_completed: bool) -> Verdict:
	if state == SceneLoader.State.LOADING:
		return Verdict.LOADING
	if state == SceneLoader.State.ERROR:
		return Verdict.IN_ERROR
	if not game_state_ready:
		return Verdict.STATE_NOT_READY
	if destination == SceneLoader.Destination.RECEPCION:
		if state == SceneLoader.State.NO_SCENE:
			return Verdict.RECEPCION_FROM_NO_SCENE
		if not call_completed:
			return Verdict.CALL_NOT_COMPLETED
	elif loaded == SceneLoader.Destination.RECEPCION:
		return Verdict.PLANTA_WITH_RECEPCION
	return Verdict.OK


## One-line description for logs and fatal details.
static func describe(verdict: Verdict) -> String:
	return String(Verdict.keys()[verdict]).to_lower()
