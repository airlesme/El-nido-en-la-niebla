extends GdUnitTestSuite
## CP-004 (T-U1 of ADR-0003): SceneLoader.request_load preconditions. AC-07a, AC-07b, AC-14, AC-16a (rejection).

const PLANTA: SceneLoader.Destination = SceneLoader.Destination.PLANTA
const RECEPCION: SceneLoader.Destination = SceneLoader.Destination.RECEPCION
const NEW_GAME: SceneLoader.Reason = SceneLoader.Reason.PARTIDA_NUEVA
const RESUME: SceneLoader.Reason = SceneLoader.Reason.REANUDAR
const ELEVATOR: SceneLoader.Reason = SceneLoader.Reason.RECEPCION
const EXPLORE: SceneLoader.FinalControl = SceneLoader.FinalControl.EXPLORACION
const NONE: SceneLoader.FinalControl = SceneLoader.FinalControl.NINGUNO


class Rig extends RefCounted:
	var loader: SceneLoader
	var state: ScriptedGameState
	var source: CountingSceneSource
	var fatal: RecordingFatalHandler
	var sink: RecordingLog


func _rig(debug: bool) -> Rig:
	var r: Rig = Rig.new()
	r.state = auto_free(ScriptedGameState.new())
	r.source = CountingSceneSource.new()
	r.fatal = RecordingFatalHandler.new()
	r.sink = RecordingLog.new()
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = r.sink
	ctx.flavor = BuildFlavor.new(debug)
	ctx.fatal = r.fatal
	ctx.state = r.state
	r.loader = auto_free(SceneLoader.new())
	r.loader.setup(ctx)
	r.loader.set_source(r.source)
	return r


func _assert_untouched(r: Rig, state: SceneLoader.State) -> void:
	assert_int(r.loader.get_state()).is_equal(state)
	assert_int(r.source.calls).is_equal(0)
	assert_int(r.state.write_count).is_equal(0)


# --- AC-07a ---

func test_planta_from_no_scene_with_ready_state_is_accepted_in_both_modes() -> void:
	for debug: bool in [true, false]:
		for reason: SceneLoader.Reason in [NEW_GAME, RESUME]:
			var r: Rig = _rig(debug)
			assert_bool(r.loader.request_load(PLANTA, reason, EXPLORE)).is_true()
			assert_int(r.loader.get_state()).is_equal(SceneLoader.State.LOADING)
			assert_int(r.fatal.calls.size()).is_equal(0)
			assert_int(r.sink.lines.size()).is_equal(0)


func test_planta_with_state_unloaded_or_restoring_is_rejected_in_both_modes() -> void:
	for debug: bool in [true, false]:
		for status: GameState.Status in [GameState.Status.UNLOADED, GameState.Status.RESTORING]:
			var r: Rig = _rig(debug)
			r.state.scripted_status = status
			assert_bool(r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)).is_false()
			_assert_untouched(r, SceneLoader.State.NO_SCENE)
			assert_int(r.fatal.calls.size()).is_equal(1 if debug else 0)
			assert_int(r.sink.lines.size()).is_equal(0 if debug else 1)


# --- AC-07b ---

func test_second_request_in_same_frame_is_rejected_in_both_modes() -> void:
	for debug: bool in [true, false]:
		var r: Rig = _rig(debug)
		assert_bool(r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)).is_true()
		assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_false()
		assert_int(r.loader.get_state()).is_equal(SceneLoader.State.LOADING)
		assert_int(r.fatal.calls.size() + r.sink.lines.size()).is_equal(1)


func test_request_during_loading_is_rejected() -> void:
	var r: Rig = _rig(false)
	r.loader.set_runtime_state(SceneLoader.State.LOADING, SceneLoader.Destination.PLANTA)
	assert_bool(r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)).is_false()
	_assert_untouched(r, SceneLoader.State.LOADING)


func test_request_in_error_is_rejected() -> void:
	var r: Rig = _rig(true)
	r.loader.set_runtime_state(SceneLoader.State.ERROR)
	assert_bool(r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)).is_false()
	_assert_untouched(r, SceneLoader.State.ERROR)
	assert_int(r.fatal.calls.size()).is_equal(1)


func test_planta_from_planta_ready_is_accepted() -> void:
	var r: Rig = _rig(false)
	r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.PLANTA)
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()


# --- AC-14 ---

func test_recepcion_with_call_not_completed_is_rejected_in_both_modes() -> void:
	for debug: bool in [true, false]:
		var r: Rig = _rig(debug)
		r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.PLANTA)
		r.state.call_completed = false
		assert_bool(r.loader.request_load(RECEPCION, ELEVATOR, NONE)).is_false()
		_assert_untouched(r, SceneLoader.State.READY)
		assert_int(r.fatal.calls.size()).is_equal(1 if debug else 0)


func test_recepcion_with_call_completed_is_accepted_with_no_final_control() -> void:
	var r: Rig = _rig(true)
	r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.PLANTA)
	r.state.call_completed = true
	assert_bool(r.loader.request_load(RECEPCION, ELEVATOR, NONE)).is_true()
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.LOADING)
	assert_int(r.state.write_count).is_equal(0)


func test_recepcion_from_no_scene_is_rejected_even_with_call_completed() -> void:
	var r: Rig = _rig(false)
	r.state.call_completed = true
	assert_bool(r.loader.request_load(RECEPCION, ELEVATOR, NONE)).is_false()
	_assert_untouched(r, SceneLoader.State.NO_SCENE)
	assert_int(r.sink.lines.size()).is_equal(1)


# --- AC-16a (rejection part) ---

func test_planta_with_recepcion_loaded_is_rejected_in_both_modes() -> void:
	for debug: bool in [true, false]:
		var r: Rig = _rig(debug)
		r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.RECEPCION)
		assert_bool(r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)).is_false()
		_assert_untouched(r, SceneLoader.State.READY)
		assert_int(r.fatal.calls.size()).is_equal(1 if debug else 0)


# --- Pure verdicts ---

func test_verdict_precedence_loading_before_state_not_ready() -> void:
	var v: LoadPreconditions.Verdict = LoadPreconditions.check(
			SceneLoader.State.LOADING, LoadPreconditions.NONE_LOADED, PLANTA, false, false)
	assert_int(v).is_equal(LoadPreconditions.Verdict.LOADING)


func test_verdict_names_are_distinct_for_each_rejection() -> void:
	var seen: Dictionary = {}
	for v: int in LoadPreconditions.Verdict.values():
		seen[LoadPreconditions.describe(v as LoadPreconditions.Verdict)] = true
	assert_int(seen.size()).is_equal(LoadPreconditions.Verdict.size())
