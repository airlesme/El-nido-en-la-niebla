extends GdUnitTestSuite
## CP-005 (T-U2 of ADR-0003): the 9-step load sequence against doubles and an injected clock.
## AC-09 (planta scope), AC-10, AC-06 + AC-23, AC-F3 part 2, plus bounds and failures.
## Virtual time: tick N happens at N * 1000/60 ms of the fake RealClock; request at tick 0.

const PLANTA: SceneLoader.Destination = SceneLoader.Destination.PLANTA
const RECEPCION: SceneLoader.Destination = SceneLoader.Destination.RECEPCION
const NEW_GAME: SceneLoader.Reason = SceneLoader.Reason.PARTIDA_NUEVA
const RESUME: SceneLoader.Reason = SceneLoader.Reason.REANUDAR
const ELEVATOR: SceneLoader.Reason = SceneLoader.Reason.RECEPCION
const EXPLORE: SceneLoader.FinalControl = SceneLoader.FinalControl.EXPLORACION
const NONE: SceneLoader.FinalControl = SceneLoader.FinalControl.NINGUNO
const MAX_TICKS: int = 900

var _events: Array[String] = []
var _payloads: Dictionary = {}
var _bus_subs: Array[int] = []


class Rig extends RefCounted:
	var loader: SceneLoader
	var state: ChanneledGameState
	var clock: FakeRealClock
	var input: SpyInputContexts
	var source: ScriptedSceneSource
	var slot: Node3D
	var game_clock: GameClock
	var fatal: RecordingFatalHandler
	var sink: RecordingLog
	var tick_no: int = 0
	var scanned: int = 0
	var first_seen: Dictionary = {}


func before_test() -> void:
	_events = []
	_payloads = {}


# Values mirror assets/data/scene/load_transitions.json (fixture: no file I/O in unit tests).
func _transitions(n_gap: int, d_out: float, d_in: float) -> LoadTransitions:
	var row: Dictionary = {"d_out": d_out, "d_in": d_in}
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": n_gap, "delta_max_s": 0.1, "delta_ref_s": 0.0333333333,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {"partida_nueva": {"d_out": d_out, "d_in": 2.0}, "reanudar": row,
				"recepcion": row, "cierre": {"d_out": d_out}},
	})


func _rig(n_gap: int = 2, d_out: float = 0.8, d_in: float = 0.8, reduced: bool = false) -> Rig:
	var r: Rig = Rig.new()
	r.state = auto_free(ChanneledGameState.new())
	r.clock = FakeRealClock.new()
	r.input = SpyInputContexts.new()
	r.input.events = _events
	r.source = ScriptedSceneSource.new()
	r.source.events = _events
	r.game_clock = auto_free(GameClock.new())
	r.source.game_clock = r.game_clock
	r.fatal = RecordingFatalHandler.new()
	r.sink = RecordingLog.new()
	r.slot = auto_free(Node3D.new())
	add_child(r.slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = r.sink
	ctx.flavor = BuildFlavor.new(false)
	ctx.fatal = r.fatal
	ctx.state = r.state
	ctx.clock = r.game_clock
	r.loader = auto_free(SceneLoader.new())
	r.loader.setup(ctx)
	r.loader.set_source(r.source)
	r.loader.wire_sequence(r.slot, _transitions(n_gap, d_out, d_in), r.clock, r.input,
			func(a: float) -> void: _events.append("alpha:%.4f" % a),
			func() -> bool: return reduced)
	for id: StringName in [NoticeIds.SCENE_LOAD_STARTED, NoticeIds.SCENE_READY,
			NoticeIds.SCENE_LOAD_FINISHED, NoticeIds.SCENE_LOAD_FAILED, NoticeIds.GAME_FINISHED]:
		r.state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, id, _on_bus.bind(id))
	return r


func _on_bus(payload: Dictionary, id: StringName) -> void:
	_events.append("bus:%s" % id)
	_payloads[id] = payload


func _mark(r: Rig) -> void:
	while r.scanned < _events.size():
		var e: String = _events[r.scanned]
		r.scanned += 1
		if not r.first_seen.has(e):
			r.first_seen[e] = r.tick_no
		if e.begins_with("alpha:") and r.first_seen.has("bus:scene_ready") \
				and not r.first_seen.has("alpha_after_ready"):
			r.first_seen["alpha_after_ready"] = r.tick_no


## Drives the machine frame by frame until it leaves LOADING (bounded by MAX_TICKS). After the unload
## tick it waits one engine frame so `queue_free` takes effect (S-0003-A: freed at U+1).
func _drive(r: Rig) -> void:
	var guard: int = 0
	while r.loader.get_state() == SceneLoader.State.LOADING and guard < MAX_TICKS:
		guard += 1
		r.tick_no += 1
		r.clock.ms = roundi(float(r.tick_no) * 1000.0 / 60.0)
		r.loader.tick()
		_mark(r)
		if r.loader.get_phase() == SceneLoader.Phase.INSTANTIATING:
			await get_tree().process_frame
	assert_bool(guard < MAX_TICKS).is_true()


func _without_alpha() -> Array[String]:
	var out: Array[String] = []
	for e: String in _events:
		if not e.begins_with("alpha:"):
			out.append(e)
	return out


func _load_once(r: Rig, reason: SceneLoader.Reason = RESUME, control: SceneLoader.FinalControl = EXPLORE,
		destination: SceneLoader.Destination = PLANTA) -> void:
	assert_bool(r.loader.request_load(destination, reason, control)).is_true()
	await _drive(r)


func _reset_log(r: Rig) -> void:
	_events.clear()
	r.scanned = 0
	r.first_seen.clear()


# --- AC-09 ---

func test_planta_from_planta_logs_the_nine_steps_in_order() -> void:
	var r: Rig = _rig()
	await _load_once(r)
	_reset_log(r)
	await _load_once(r)
	assert_array(_without_alpha()).is_equal([
		"bus:scene_load_started", "input:open_no_control",
		"input:reset_stack_on_unload", "unload", "src:instantiate", "colocar",
		"configure:7", "validate:9", "configure:9", "configure:rest",
		"bus:scene_ready", "bus:scene_load_finished", "input:request_exploration"])
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)


func test_curtain_is_untouched_before_started_and_unload_waits_for_alpha_one() -> void:
	var r: Rig = _rig()
	await _load_once(r)
	_reset_log(r)
	await _load_once(r)
	var open_i: int = _events.find("input:open_no_control")
	var reset_i: int = _events.find("input:reset_stack_on_unload")
	var ready_i: int = _events.find("bus:scene_ready")
	var finished_i: int = _events.find("bus:scene_load_finished")
	assert_int(open_i).is_greater(0) # "iniciada" before anything else
	assert_bool(_events[0] == "bus:scene_load_started").is_true()
	assert_bool(reset_i > open_i + 1).is_true() # darkening writes alpha in between
	var previous: float = -1.0
	for i: int in range(open_i + 1, reset_i):
		assert_bool(_events[i].begins_with("alpha:")).is_true()
		var a: float = float(_events[i].substr(6))
		assert_bool(a >= previous).is_true()
		previous = a
	assert_str(_events[reset_i - 1]).is_equal("alpha:1.0000")
	assert_str(_events[reset_i + 1]).is_equal("unload")
	# Fade in: alpha writes between ready and finished, non increasing, ending at 0.
	previous = 2.0
	for i: int in range(ready_i + 1, finished_i):
		assert_bool(_events[i].begins_with("alpha:")).is_true()
		var b: float = float(_events[i].substr(6))
		assert_bool(b <= previous).is_true()
		previous = b
	assert_str(_events[finished_i - 1]).is_equal("alpha:0.0000")


func test_started_payload_carries_nominal_d_carga_and_no_control_opens_with_it() -> void:
	var r: Rig = _rig()
	await _load_once(r, NEW_GAME)
	var started: Dictionary = _payloads[NoticeIds.SCENE_LOAD_STARTED]
	assert_str(String(started[&"destino"])).is_equal("planta")
	assert_str(String(started[&"motivo"])).is_equal("partida_nueva")
	assert_str(String(started[&"control_final"])).is_equal("exploracion")
	# partida_nueva: 0.8 + T_cap 10 + 2 * 0.0333333333 + 2.0
	assert_float(float(started[&"D_carga"])).is_equal_approx(12.8666666666, 0.0001)
	assert_int(r.input.opens.size()).is_equal(1)
	assert_float(float(r.input.opens[0][&"declared_s"])).is_equal_approx(float(started[&"D_carga"]), 0.0001)
	assert_bool(r.input.opens[0][&"absorbs"]).is_true()


func test_elevator_reason_does_not_absorb_foreign_contexts() -> void:
	var r: Rig = _rig()
	r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.PLANTA)
	r.state.call_completed = true
	await _load_once(r, ELEVATOR, NONE, RECEPCION)
	assert_bool(r.input.opens[0][&"absorbs"]).is_false()


# --- U / U+1 (S-0003-A) ---

func test_instantiation_happens_exactly_one_frame_after_the_unload() -> void:
	var r: Rig = _rig()
	await _load_once(r)
	_reset_log(r)
	var old: SceneRootDouble = r.source.made[0]
	await _load_once(r)
	assert_int(r.first_seen["src:instantiate"]).is_equal(int(r.first_seen["unload"]) + 1)
	assert_bool(is_instance_valid(old)).is_false()
	assert_int(r.slot.get_child_count()).is_equal(1)
	assert_object(r.source.made[1]).is_not_same(old)


func test_game_clock_is_reset_right_before_instantiating() -> void:
	var r: Rig = _rig()
	r.game_clock.advance(0.05)
	assert_float(r.game_clock.now()).is_greater(0.0)
	await _load_once(r)
	assert_float(r.source.clock_seen).is_equal(0.0)


func test_first_load_from_no_scene_does_not_unload_or_reset_the_stack() -> void:
	var r: Rig = _rig()
	await _load_once(r)
	assert_int(r.input.reset_calls).is_equal(0)
	assert_bool(_events.has("unload")).is_false()


func test_title_in_the_slot_is_freed_without_a_stack_reset() -> void:
	var r: Rig = _rig()
	var title: Node3D = Node3D.new()
	r.slot.add_child(title)
	await _load_once(r)
	assert_bool(is_instance_valid(title)).is_false()
	assert_int(r.input.reset_calls).is_equal(0)
	assert_int(r.slot.get_child_count()).is_equal(1)


func test_player_is_placed_from_the_anchor_with_level_pitch() -> void:
	var r: Rig = _rig()
	await _load_once(r)
	var spy: PlayerSpy = r.source.made[0].player
	assert_int(spy.placed.size()).is_equal(1)
	assert_vector(spy.placed[0][&"position"]).is_equal_approx(Vector3(1.0, 2.0, 3.0), Vector3(0.001, 0.001, 0.001))
	assert_float(float(spy.placed[0][&"yaw"])).is_equal_approx(0.5, 0.001)
	assert_float(float(spy.placed[0][&"pitch"])).is_equal(0.0)


# --- AC-10 ---

func test_final_control_exploration_requests_exploration_once_and_no_game_finished() -> void:
	var r: Rig = _rig()
	await _load_once(r, RESUME, EXPLORE)
	assert_int(r.input.exploration_requests).is_equal(1)
	assert_bool(_events.has("bus:game_finished")).is_false()
	assert_bool(r.source.made[0].hub.is_enabled()).is_true()


func test_final_control_none_requests_no_exploration() -> void:
	var r: Rig = _rig()
	await _load_once(r, RESUME, NONE)
	assert_int(r.input.exploration_requests).is_equal(0)
	assert_str(String(_payloads[NoticeIds.SCENE_LOAD_FINISHED][&"control_final"])).is_equal("ninguno")


# --- AC-06 + AC-23 ---

func test_element_reads_the_fact_once_before_ready_and_state_is_not_written() -> void:
	var r: Rig = _rig()
	r.state.facts[&"archivo_abierto"] = true
	await _load_once(r, RESUME, EXPLORE)
	var root: SceneRootDouble = r.source.made[0]
	assert_int(root.configure_calls).is_equal(1)
	assert_bool(root.element_saw == true).is_true()
	assert_int(_events.find("configure:rest")).is_less(_events.find("bus:scene_ready"))
	assert_int(r.state.write_count).is_equal(0)
	assert_int(int(r.state.reads.get(&"archivo_abierto", 0))).is_equal(1)
	assert_int(int(r.state.reads.get(&"llamada_completada", 0))).is_equal(0)


func test_validation_failure_stops_the_sequence_without_waiting_for_t_cap() -> void:
	var r: Rig = _rig()
	r.source.fail_validation = true
	await _load_once(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_array(_without_alpha().filter(func(e: String) -> bool: return e.begins_with("configure:") \
			or e.begins_with("validate:"))).is_equal(["configure:7", "validate:9:fail"])
	assert_bool(_events.has("bus:scene_ready")).is_false()
	assert_bool(_events.has("bus:scene_load_finished")).is_false()
	assert_str(String(_payloads[NoticeIds.SCENE_LOAD_FAILED][&"causa"])).is_equal("invalid_puzzle_data")
	# Fails in the very frame of the configuration, far below T_cap (10 s).
	assert_int(r.first_seen["bus:scene_load_failed"]).is_equal(int(r.first_seen["src:instantiate"]))
	assert_float(r.loader.get_curtain_alpha()).is_equal(1.0)
	assert_int(r.input.restore_calls).is_equal(1)
	assert_bool(r.loader.is_processing()).is_false()


func test_source_returning_null_fails_with_instantiate_failed() -> void:
	var r: Rig = _rig()
	r.source.fail = true
	await _load_once(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_str(String(_payloads[NoticeIds.SCENE_LOAD_FAILED][&"causa"])).is_equal("instantiate_failed")
	assert_bool(_events.has("bus:scene_ready")).is_false()


# --- AC-F3 (part 2) ---

func test_instant_load_at_60fps_starts_the_fade_in_n_gap_frames_after_ready() -> void:
	var r: Rig = _rig(2)
	await _load_once(r, RESUME)
	var ready_tick: int = r.first_seen["bus:scene_ready"]
	assert_int(r.first_seen["alpha_after_ready"]).is_equal(ready_tick + 2)
	var t: float = float(_payloads[NoticeIds.SCENE_LOAD_FINISHED][&"t_since_started_s"])
	assert_float(t).is_equal_approx(1.6333, 0.001)


func test_zero_gap_frames_starts_the_fade_in_in_the_ready_frame() -> void:
	var r: Rig = _rig(0)
	await _load_once(r)
	assert_int(r.first_seen["alpha_after_ready"]).is_equal(int(r.first_seen["bus:scene_ready"]))


func test_zero_durations_complete_without_dividing_and_keep_the_order() -> void:
	var r: Rig = _rig(0, 0.0, 0.0)
	await _load_once(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.READY)
	assert_float(r.loader.get_curtain_alpha()).is_equal(0.0)
	assert_int(r.first_seen["bus:scene_load_finished"]).is_equal(int(r.first_seen["src:instantiate"]))


func test_reduced_motion_shortens_the_fades_but_not_the_declared_d_carga() -> void:
	var nominal: Rig = _rig()
	await _load_once(nominal)
	var nominal_ticks: int = nominal.tick_no
	var nominal_d: float = float(_payloads[NoticeIds.SCENE_LOAD_STARTED][&"D_carga"])
	_events.clear()
	var r: Rig = _rig(2, 0.8, 0.8, true)
	await _load_once(r)
	assert_int(r.tick_no).is_less(nominal_ticks)
	assert_float(float(_payloads[NoticeIds.SCENE_LOAD_STARTED][&"D_carga"])).is_equal(nominal_d)


func test_machine_stops_processing_when_idle_and_is_dormant_when_unwired() -> void:
	var r: Rig = _rig()
	await _load_once(r)
	assert_bool(r.loader.is_processing()).is_false()
	assert_int(r.loader.get_phase()).is_equal(SceneLoader.Phase.IDLE)
	var bare: SceneLoader = auto_free(SceneLoader.new())
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = RecordingLog.new()
	ctx.flavor = BuildFlavor.new(false)
	ctx.fatal = RecordingFatalHandler.new()
	ctx.state = r.state
	bare.setup(ctx)
	assert_bool(bare.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	assert_int(bare.get_phase()).is_equal(SceneLoader.Phase.IDLE)
	assert_bool(bare.is_processing()).is_false()


# --- Reception (outside M1 acceptance, behaviour of the same machine) ---

func test_reception_emits_game_finished_after_finished_in_the_same_frame() -> void:
	var r: Rig = _rig()
	r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.PLANTA)
	r.state.call_completed = true
	await _load_once(r, ELEVATOR, NONE, RECEPCION)
	var f: int = _events.find("bus:scene_load_finished")
	assert_int(_events.find("bus:game_finished")).is_equal(f + 1)
