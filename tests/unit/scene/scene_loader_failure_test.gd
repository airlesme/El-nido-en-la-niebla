extends GdUnitTestSuite
## CP-008 (T-U7 of ADR-0003): load failure and the Error state.
## AC-15a (every cause; the Sin escena exit belongs to story 009), AC-15b, AC-15c.
## Virtual time only: the fake RealClock advances in milliseconds; no frame count is asserted.

const PLANTA: SceneLoader.Destination = SceneLoader.Destination.PLANTA
const RESUME: SceneLoader.Reason = SceneLoader.Reason.REANUDAR
const EXPLORE: SceneLoader.FinalControl = SceneLoader.FinalControl.EXPLORACION
const FRAME_MS: int = 16
const MAX_TICKS: int = 3000

var _events: Array[String] = []
var _failed_payloads: Array[Dictionary] = []
var _panel_requests: Array[StringName] = []


class Rig extends RefCounted:
	var loader: SceneLoader
	var state: ChanneledGameState
	var clock: FakeRealClock
	var input: SpyInputContexts
	var fatal: RecordingFatalHandler
	var sink: RecordingLog


func before_test() -> void:
	_events = []
	_failed_payloads = []
	_panel_requests = []


func _transitions() -> LoadTransitions:
	var row: Dictionary = {"d_out": 0.8, "d_in": 0.8}
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": 2, "delta_max_s": 0.1, "delta_ref_s": 0.0333333333,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {"partida_nueva": {"d_out": 0.8, "d_in": 2.0}, "reanudar": row,
				"recepcion": row, "cierre": {"d_out": 0.8}},
	})


func _rig(source: SceneSource, debug: bool = false, with_input: bool = true, with_panel: bool = true) -> Rig:
	var r: Rig = Rig.new()
	r.state = auto_free(ChanneledGameState.new())
	r.clock = FakeRealClock.new()
	r.input = SpyInputContexts.new()
	r.input.events = _events
	r.fatal = RecordingFatalHandler.new()
	r.sink = RecordingLog.new()
	var slot: Node3D = auto_free(Node3D.new())
	add_child(slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = r.sink
	ctx.flavor = BuildFlavor.new(debug)
	ctx.fatal = r.fatal
	ctx.state = r.state
	ctx.clock = auto_free(GameClock.new())
	r.loader = auto_free(SceneLoader.new())
	r.loader.setup(ctx)
	r.loader.set_source(source)
	r.loader.wire_sequence(slot, _transitions(), r.clock, r.input if with_input else null,
			func(a: float) -> void: _events.append("alpha:%.4f" % a))
	if with_panel:
		r.loader.set_error_panel_port(func(cause: StringName) -> void: _panel_requests.append(cause))
	for id: StringName in [NoticeIds.SCENE_READY, NoticeIds.SCENE_LOAD_FINISHED, NoticeIds.GAME_FINISHED,
			NoticeIds.FULL_UNLOAD_COMPLETED, NoticeIds.SCENE_LOAD_FAILED]:
		r.state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, id, _on_bus.bind(id))
	return r


func _on_bus(payload: Dictionary, id: StringName) -> void:
	_events.append("bus:%s" % id)
	if id == NoticeIds.SCENE_LOAD_FAILED:
		_failed_payloads.append(payload)


## Requests the load and runs it frame by frame until it leaves LOADING (bounded; virtual clock).
func _drive(r: Rig) -> void:
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	var guard: int = 0
	while r.loader.get_state() == SceneLoader.State.LOADING and guard < MAX_TICKS:
		guard += 1
		r.clock.ms += FRAME_MS
		r.loader.tick()
		if r.loader.get_phase() == SceneLoader.Phase.INSTANTIATING:
			await get_tree().process_frame # the previous scene is freed one frame later (S-0003-A)
	assert_bool(guard < MAX_TICKS).is_true()


func _logged(r: Rig, needle: String) -> bool:
	for entry: Dictionary in r.sink.lines:
		if String(entry[&"msg"]).contains(needle):
			return true
	return false


## The whole AC-15a contract except the Sin escena exit (story 009).
func _assert_failed(r: Rig, cause: StringName) -> void:
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_str(String(r.loader.get_failure_cause())).is_equal(String(cause))
	assert_float(r.loader.get_curtain_alpha()).is_equal(1.0)
	assert_str(_last_alpha()).is_equal("alpha:1.0000") # never lifted after the failure
	assert_bool(_logged(r, String(cause))).is_true()
	assert_int(_events.count("bus:%s" % NoticeIds.SCENE_LOAD_FAILED)).is_equal(1)
	assert_str(String(_failed_payloads[0][&"causa"])).is_equal(String(cause))
	assert_int(r.input.restore_calls).is_equal(1)
	assert_array(_panel_requests).is_equal([cause])
	for forbidden: StringName in [NoticeIds.SCENE_LOAD_FINISHED, NoticeIds.GAME_FINISHED,
			NoticeIds.FULL_UNLOAD_COMPLETED]:
		assert_int(_events.count("bus:%s" % forbidden)).is_equal(0)
	assert_int(r.input.exploration_requests).is_equal(0)


func _last_alpha() -> String:
	for i: int in range(_events.size() - 1, -1, -1):
		if _events[i].begins_with("alpha:"):
			return _events[i]
	return ""


# --- AC-15a: every cause, final build ---

func test_missing_resource_fails_into_error_with_curtain_closed() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.null_with = SceneSource.FAILURE_MISSING_RESOURCE
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"missing_resource")
	assert_int(_events.count("bus:%s" % NoticeIds.SCENE_READY)).is_equal(0)


func test_scene_not_instantiable_fails_with_instantiate_failed() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.null_with = SceneSource.FAILURE_INSTANTIATE_FAILED
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"instantiate_failed")


func test_null_without_reason_is_read_as_instantiate_failed() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.null_with = &""
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"instantiate_failed")


func test_missing_container_fails_with_its_own_cause() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.missing = PackedStringArray(["archive"])
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"missing_container")


func test_container_and_anchor_missing_together_report_the_container() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.missing = PackedStringArray(["door_slot_a", "corridor"])
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"missing_container")


func test_missing_required_anchor_fails_with_missing_anchor() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.missing = PackedStringArray(["spawn_office"])
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"missing_anchor")


func test_unresolvable_spawn_anchor_path_fails_with_missing_anchor() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.break_anchor = true
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"missing_anchor")


func test_holds_pending_at_t_cap_fail_with_t_cap() -> void:
	var src: HoldingSceneSource = HoldingSceneSource.new()
	var r: Rig = _rig(src)
	src.loader = r.loader
	src.events = _events
	src.hold_ids = [&"b:two", &"a:one"] as Array[StringName]
	await _drive(r)
	_assert_failed(r, &"t_cap")
	assert_bool(_logged(r, "[&\"a:one\", &\"b:two\"]") or _logged(r, "a:one")).is_true()


func test_invalid_puzzle_data_fails_without_waiting_for_t_cap() -> void:
	var src: ScriptedSceneSource = ScriptedSceneSource.new()
	src.fail_validation = true
	var r: Rig = _rig(src)
	await _drive(r)
	_assert_failed(r, &"invalid_puzzle_data")
	assert_int(r.clock.ms).is_less(10000) # immediate: the 10 s cap never elapsed


# --- Error is terminal for the machine ---

func test_error_state_rejects_new_loads_and_extra_ticks_change_nothing() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.null_with = SceneSource.FAILURE_MISSING_RESOURCE
	var r: Rig = _rig(src)
	await _drive(r)
	var before: int = _events.size()
	for i: int in range(5):
		r.clock.ms += FRAME_MS
		r.loader.tick()
	var accepted: bool = r.loader.request_load(PLANTA, RESUME, EXPLORE)
	assert_bool(accepted).is_false()
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_int(_events.size()).is_equal(before)
	assert_int(_panel_requests.size()).is_equal(1)


func test_failure_without_input_port_or_panel_port_does_not_crash() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.null_with = SceneSource.FAILURE_MISSING_RESOURCE
	var r: Rig = _rig(src, false, false, false)
	await _drive(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_float(r.loader.get_curtain_alpha()).is_equal(1.0)
	assert_int(_panel_requests.size()).is_equal(0)


func test_successful_load_requests_no_panel_and_has_no_failure_cause() -> void:
	var src: ScriptedSceneSource = ScriptedSceneSource.new()
	src.events = _events
	var r: Rig = _rig(src)
	await _drive(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)
	assert_int(_panel_requests.size()).is_equal(0)
	assert_str(String(r.loader.get_failure_cause())).is_empty()
	assert_int(r.input.restore_calls).is_equal(0)


# --- AC-15b: dev builds ---

func test_dev_build_failure_reaches_the_fatal_handler_with_the_cause() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.null_with = SceneSource.FAILURE_MISSING_RESOURCE
	var r: Rig = _rig(src, true)
	await _drive(r)
	assert_int(r.fatal.calls.size()).is_equal(1)
	assert_str(String(r.fatal.calls[0][&"code"])).is_equal(String(SceneLoader.FATAL_LOAD_FAILED))
	assert_str(String(r.fatal.calls[0][&"detail"][&"causa"])).is_equal("missing_resource")


func test_dev_build_invalid_puzzle_data_reaches_the_fatal_handler() -> void:
	var src: ScriptedSceneSource = ScriptedSceneSource.new()
	src.fail_validation = true
	var r: Rig = _rig(src, true)
	await _drive(r)
	assert_int(r.fatal.calls.size()).is_equal(1)
	assert_str(String(r.fatal.calls[0][&"detail"][&"causa"])).is_equal("invalid_puzzle_data")


func test_dev_build_t_cap_reaches_the_fatal_handler_with_the_pending_ids() -> void:
	var src: HoldingSceneSource = HoldingSceneSource.new()
	var r: Rig = _rig(src, true)
	src.loader = r.loader
	src.events = _events
	src.hold_ids = [&"a:one"] as Array[StringName]
	await _drive(r)
	assert_int(r.fatal.calls.size()).is_equal(1)
	assert_str(String(r.fatal.calls[0][&"detail"][&"causa"])).is_equal("t_cap")
	assert_array(r.fatal.calls[0][&"detail"][&"pending"]).contains([&"a:one"])


func test_final_build_failure_never_calls_the_fatal_handler() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.missing = PackedStringArray(["office"])
	var r: Rig = _rig(src, false)
	await _drive(r)
	assert_int(r.fatal.calls.size()).is_equal(0)


# --- AC-15c: duplicate anchors ---

func test_duplicate_anchor_in_dev_raises_a_visible_error() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.duplicate_anchor = true
	var r: Rig = _rig(src, true)
	await _drive(r)
	assert_int(r.fatal.calls.size()).is_equal(1)
	assert_str(String(r.fatal.calls[0][&"code"])).is_equal(String(SceneLoader.FATAL_DUPLICATE_ANCHOR))


func test_duplicate_anchor_in_final_build_uses_the_first_in_tree_order_and_logs_once() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	src.duplicate_anchor = true
	var r: Rig = _rig(src, false)
	await _drive(r)
	var player: PlayerSpy = (r.loader._current_root as SceneRootDouble).player
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)
	assert_int(r.fatal.calls.size()).is_equal(0)
	assert_int(player.placed.size()).is_equal(1)
	assert_vector(player.placed[0][&"position"]).is_equal(Vector3(1.0, 2.0, 3.0))
	var dup_lines: int = 0
	for entry: Dictionary in r.sink.lines:
		if String(entry[&"msg"]).contains("duplicate spawn anchor"):
			dup_lines += 1
	assert_int(dup_lines).is_equal(1)


func test_single_anchor_logs_no_duplicate_warning() -> void:
	var src: FailingSceneSource = FailingSceneSource.new()
	var r: Rig = _rig(src, true)
	await _drive(r)
	assert_int(r.fatal.calls.size()).is_equal(0)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)
