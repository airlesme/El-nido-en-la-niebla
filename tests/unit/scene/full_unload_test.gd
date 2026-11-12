extends GdUnitTestSuite
## CP-009 (T-U8 of ADR-0003): full unload against doubles and an injected clock.
## AC-16b, AC-16d (part of 4), rejection in Cargando/Sin escena, t_unload warning, exit from Error.
## Virtual time only; every wait is a bounded loop on a condition (no fixed frame counts).

const PLANTA: SceneLoader.Destination = SceneLoader.Destination.PLANTA
const RESUME: SceneLoader.Reason = SceneLoader.Reason.REANUDAR
const EXPLORE: SceneLoader.FinalControl = SceneLoader.FinalControl.EXPLORACION
const FRAME_MS: int = 16
const MAX_TICKS: int = 3000

var _events: Array[String] = []
var _panel_requests: Array[StringName] = []


## ScriptedSceneSource that also serves the title marker and counts it.
class TitleSource extends ScriptedSceneSource:
	var titles: int = 0
	var fail_title: bool = false

	func instantiate(destination: StringName) -> Node:
		if destination == SceneSource.TITLE:
			events.append("src:title")
			if fail_title:
				return null
			titles += 1
			return Node.new()
		return super.instantiate(destination)


class Rig extends RefCounted:
	var loader: SceneLoader
	var state: ChanneledGameState
	var clock: FakeRealClock
	var input: SpyInputContexts
	var source: TitleSource
	var slot: Node3D
	var sink: RecordingLog


func before_test() -> void:
	_events = []
	_panel_requests = []


func _transitions() -> LoadTransitions:
	var row: Dictionary = {"d_out": 0.8, "d_in": 0.8}
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": 2, "delta_max_s": 0.1, "delta_ref_s": 0.0333333333,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {"partida_nueva": {"d_out": 0.8, "d_in": 2.0}, "reanudar": row,
				"recepcion": row, "cierre": {"d_out": 0.8}},
	})


func _rig() -> Rig:
	var r: Rig = Rig.new()
	r.state = auto_free(ChanneledGameState.new())
	r.clock = FakeRealClock.new()
	r.input = SpyInputContexts.new()
	r.input.events = _events
	r.source = TitleSource.new()
	r.source.events = _events
	r.sink = RecordingLog.new()
	r.slot = auto_free(Node3D.new())
	add_child(r.slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = r.sink
	ctx.flavor = BuildFlavor.new(false)
	ctx.fatal = RecordingFatalHandler.new()
	ctx.state = r.state
	ctx.clock = auto_free(GameClock.new())
	r.loader = auto_free(SceneLoader.new())
	r.loader.setup(ctx)
	r.loader.set_source(r.source)
	r.loader.wire_sequence(r.slot, _transitions(), r.clock, r.input,
			func(a: float) -> void: _events.append("alpha:%.4f" % a))
	r.loader.set_error_panel_port(func(cause: StringName) -> void: _panel_requests.append(cause))
	for id: StringName in [NoticeIds.FULL_UNLOAD_REQUESTED, NoticeIds.FULL_UNLOAD_COMPLETED,
			NoticeIds.SCENE_LOAD_FINISHED, NoticeIds.SCENE_LOAD_FAILED, NoticeIds.GAME_FINISHED]:
		r.state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, id, _on_bus.bind(id))
	return r


func _on_bus(_payload: Dictionary, id: StringName) -> void:
	_events.append("bus:%s" % id)


## Advances one frame; after the freeing tick waits one engine frame so `queue_free` takes effect (U+1).
func _step(r: Rig, ms: int = FRAME_MS) -> void:
	r.clock.ms += ms
	r.loader.tick()
	if r.loader.get_phase() == SceneLoader.Phase.UNLOAD_FREEING \
			or r.loader.get_phase() == SceneLoader.Phase.INSTANTIATING:
		await get_tree().process_frame


func _load_until_settled(r: Rig) -> void:
	var guard: int = 0
	while r.loader.get_state() == SceneLoader.State.LOADING and guard < MAX_TICKS:
		guard += 1
		await _step(r)
	assert_bool(guard < MAX_TICKS).is_true()


func _load_until_ready(r: Rig) -> void:
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	await _load_until_settled(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)


func _run_unload(r: Rig, ms: int = FRAME_MS) -> void:
	var guard: int = 0
	while r.loader.get_phase() != SceneLoader.Phase.IDLE and guard < MAX_TICKS:
		guard += 1
		await _step(r, ms)
	assert_bool(guard < MAX_TICKS).is_true()


func _count(id: StringName) -> int:
	return _events.count("bus:%s" % id)


func _index(event: String) -> int:
	return _events.find(event)


# --- AC-16b / AC-16d ---

func test_unload_from_ready_ends_in_no_scene_with_curtain_closed_and_only_the_title() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	var old: Node = r.slot.get_child(0)
	assert_bool(r.loader.request_full_unload()).is_true()
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.NO_SCENE)
	await _run_unload(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.NO_SCENE)
	assert_float(r.loader.get_curtain_alpha()).is_equal(1.0)
	assert_bool(is_instance_valid(old)).is_false()
	assert_int(r.slot.get_child_count()).is_equal(1)
	assert_object(r.slot.get_child(0)).is_not_instanceof(SceneRootDouble)
	assert_int(r.source.titles).is_equal(1)
	assert_bool(r.loader.is_processing()).is_false()


func test_requested_then_completed_exactly_once_in_order_and_menu_restored_after_free() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	var mark: int = _events.size()
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	assert_int(_count(NoticeIds.FULL_UNLOAD_REQUESTED)).is_equal(1)
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(1)
	var requested: int = _index("bus:%s" % NoticeIds.FULL_UNLOAD_REQUESTED)
	var restore: int = _events.find("input:restore_menu", mark)
	var completed: int = _index("bus:%s" % NoticeIds.FULL_UNLOAD_COMPLETED)
	var title: int = _index("src:title")
	assert_bool(mark <= requested).is_true()
	assert_bool(requested < restore).is_true()
	assert_bool(restore < completed).is_true()
	assert_bool(completed < title).is_true()
	assert_int(_events.find("alpha:1.0000", requested)).is_greater(requested)
	assert_int(_count(NoticeIds.GAME_FINISHED)).is_equal(0)


func test_unload_never_resets_the_input_stack() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	assert_int(r.input.reset_calls).is_equal(0)
	assert_int(r.input.restore_calls).is_equal(1)


func test_curtain_darkens_monotonically_to_one_when_it_was_clear() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	var mark: int = _events.size()
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	var last: float = 0.0
	var seen: int = 0
	for i: int in range(mark, _events.size()):
		if _events[i].begins_with("alpha:"):
			var a: float = float(_events[i].substr(6))
			assert_bool(a >= last).is_true()
			last = a
			seen += 1
	assert_float(last).is_equal(1.0)
	assert_int(seen).is_greater(1) # it really faded (0,1 s), it did not jump


# --- Rejections and exits ---

func test_rejected_in_loading_and_in_no_scene_without_side_effects() -> void:
	var r: Rig = _rig()
	assert_bool(r.loader.request_full_unload()).is_false() # NO_SCENE
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	assert_bool(r.loader.request_full_unload()).is_false() # LOADING
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.LOADING)
	assert_int(_count(NoticeIds.FULL_UNLOAD_REQUESTED)).is_equal(0)
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(0)


func test_second_request_during_the_unload_and_new_loads_are_rejected() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	assert_bool(r.loader.request_full_unload()).is_true()
	assert_bool(r.loader.request_full_unload()).is_false()
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_false()
	await _run_unload(r)
	assert_int(_count(NoticeIds.FULL_UNLOAD_REQUESTED)).is_equal(1)
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(1)
	assert_bool(r.loader.request_full_unload()).is_false() # Sin escena again


func test_from_error_curtain_stays_closed_failure_has_no_completed_and_the_exit_completes_once() -> void:
	var r: Rig = _rig()
	r.source.fail = true
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	await _load_until_settled(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_int(_count(NoticeIds.FULL_UNLOAD_REQUESTED)).is_equal(0) # a failure alone emits neither
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(0)
	var mark: int = _events.size()
	assert_bool(r.loader.request_full_unload()).is_true()
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.NO_SCENE)
	await _run_unload(r)
	for i: int in range(mark, _events.size()):
		if _events[i].begins_with("alpha:"):
			assert_str(_events[i]).is_equal("alpha:1.0000") # nothing to fade: never lifts
	assert_int(_count(NoticeIds.FULL_UNLOAD_REQUESTED)).is_equal(1)
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(1)
	assert_str(String(r.loader.get_failure_cause())).is_empty()
	assert_int(r.source.titles).is_equal(1)
	assert_int(r.input.restore_calls).is_equal(2) # one from the failure, one from the unload


func test_error_with_a_half_loaded_scene_in_the_slot_frees_it() -> void:
	var r: Rig = _rig()
	r.source.fail_validation = true
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	await _load_until_settled(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_int(r.slot.get_child_count()).is_equal(1)
	var half: Node = r.slot.get_child(0)
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	assert_bool(is_instance_valid(half)).is_false()
	assert_int(r.slot.get_child_count()).is_equal(1)


# --- t_unload warning ---

func _warnings(r: Rig) -> int:
	var n: int = 0
	for entry: Dictionary in r.sink.lines:
		if entry[&"level"] == LogSink.LEVEL_WARN and String(entry[&"msg"]).contains("full unload took"):
			n += 1
	return n


func test_t_unload_over_the_limit_logs_a_warning_once() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r, 4000) # each frame is 4 s of real time: past 3,0 s
	assert_int(_warnings(r)).is_equal(1)
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(1) # the warning does not block


func test_t_unload_within_the_limit_logs_no_warning() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	assert_int(_warnings(r)).is_equal(0)


# --- Title ---

func test_title_missing_leaves_a_clean_no_scene() -> void:
	var r: Rig = _rig()
	r.source.fail_title = true
	await _load_until_ready(r)
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	assert_int(r.slot.get_child_count()).is_equal(0)
	assert_int(_count(NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(1)
	assert_bool(r.loader.get_phase() == SceneLoader.Phase.IDLE).is_true()


func test_a_new_load_is_accepted_from_the_title_without_resetting_the_stack() -> void:
	var r: Rig = _rig()
	await _load_until_ready(r)
	assert_bool(r.loader.request_full_unload()).is_true()
	await _run_unload(r)
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	await _load_until_settled(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)
	assert_int(r.input.reset_calls).is_equal(0) # the title is never a stack-reset case (D2)
	assert_int(r.slot.get_child_count()).is_equal(1)
	assert_object(r.slot.get_child(0)).is_instanceof(SceneRootDouble)
