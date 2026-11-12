extends GdUnitTestSuite
## CP-007 (T-U3 of ADR-0003): holds and real-time `T_cap` of the load machine.
## AC-13, AC-F2, AC-19 (holds part), AC-F3 part 3. Virtual time: the fake RealClock is set in
## milliseconds relative to the frame where alpha reaches 1 (`dark_ms`), never in a fixed frame count.

const PLANTA: SceneLoader.Destination = SceneLoader.Destination.PLANTA
const RESUME: SceneLoader.Reason = SceneLoader.Reason.REANUDAR
const EXPLORE: SceneLoader.FinalControl = SceneLoader.FinalControl.EXPLORACION
const FRAME_MS: int = 16
const T_CAP_MS: int = 10000
const MAX_TICKS: int = 900

var _events: Array[String] = []


class Rig extends RefCounted:
	var loader: SceneLoader
	var state: ChanneledGameState
	var clock: FakeRealClock
	var source: HoldingSceneSource
	var sink: RecordingLog
	var dark_ms: int = 0


func before_test() -> void:
	_events = []


func _transitions() -> LoadTransitions:
	var row: Dictionary = {"d_out": 0.8, "d_in": 0.8}
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": 2, "delta_max_s": 0.1, "delta_ref_s": 0.0333333333,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {"partida_nueva": {"d_out": 0.8, "d_in": 2.0}, "reanudar": row,
				"recepcion": row, "cierre": {"d_out": 0.8}},
	})


func _rig(ids: Array[StringName]) -> Rig:
	var r: Rig = Rig.new()
	r.state = auto_free(ChanneledGameState.new())
	r.clock = FakeRealClock.new()
	r.source = HoldingSceneSource.new()
	r.source.events = _events
	r.sink = RecordingLog.new()
	var slot: Node3D = auto_free(Node3D.new())
	add_child(slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = r.sink
	ctx.flavor = BuildFlavor.new(false)
	ctx.fatal = RecordingFatalHandler.new()
	ctx.state = r.state
	ctx.clock = auto_free(GameClock.new())
	r.loader = auto_free(SceneLoader.new())
	r.loader.setup(ctx)
	r.source.loader = r.loader
	r.source.hold_ids = ids
	r.loader.set_source(r.source)
	r.loader.wire_sequence(slot, _transitions(), r.clock, SpyInputContexts.new(),
			func(a: float) -> void: _events.append("alpha:%.4f" % a))
	for id: StringName in [NoticeIds.SCENE_READY, NoticeIds.SCENE_LOAD_FINISHED, NoticeIds.SCENE_LOAD_FAILED]:
		r.state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, id, _on_bus.bind(id))
	return r


func _on_bus(_payload: Dictionary, id: StringName) -> void:
	_events.append("bus:%s" % id)


## Runs the load until the configure frame has executed (phase WAITING_HOLDS, or already past it).
func _to_wait(r: Rig) -> void:
	assert_bool(r.loader.request_load(PLANTA, RESUME, EXPLORE)).is_true()
	var guard: int = 0
	while r.loader.get_phase() != SceneLoader.Phase.INSTANTIATING and guard < MAX_TICKS:
		guard += 1
		r.clock.ms += FRAME_MS
		r.loader.tick()
	assert_bool(guard < MAX_TICKS).is_true()
	r.dark_ms = r.clock.ms
	await get_tree().process_frame # the previous scene is freed one frame later (S-0003-A)
	_at(r, FRAME_MS)


## Sets the clock to `since_dark_ms` after alpha reached 1 and runs one frame.
func _at(r: Rig, since_dark_ms: int) -> void:
	r.clock.ms = r.dark_ms + since_dark_ms
	r.loader.tick()


func _count(event: String) -> int:
	return _events.count(event)


func _alpha_writes() -> int:
	return _events.filter(func(e: String) -> bool: return e.begins_with("alpha:")).size()


func _logged(r: Rig, needle: String) -> bool:
	for entry: Dictionary in r.sink.lines:
		if String(entry[&"msg"]).contains(needle):
			return true
	return false


# --- AC-F2 / AC-13 ---

func test_staggered_releases_make_the_scene_ready_at_the_last_one_without_failure() -> void:
	var r: Rig = _rig([&"a:one", &"b:two", &"c:three"])
	await _to_wait(r)
	assert_int(r.loader.get_hold_count()).is_equal(3)
	var writes: int = _alpha_writes()
	r.loader.release_hold(&"a:one")
	_at(r, 200)
	r.loader.release_hold(&"b:two")
	_at(r, 1500)
	assert_int(_count("bus:scene_ready")).is_equal(0)
	assert_float(r.loader.get_curtain_alpha()).is_equal(1.0)
	assert_int(_alpha_writes()).is_equal(writes) # AC-13: no curtain movement while held
	r.loader.release_hold(&"c:three")
	_at(r, 4000)
	assert_int(_count("bus:scene_ready")).is_equal(1)
	assert_int(_count("bus:scene_load_failed")).is_equal(0)
	assert_int(r.loader.get_phase()).is_not_equal(SceneLoader.Phase.WAITING_HOLDS)


func test_fade_in_does_not_start_before_the_scene_is_ready() -> void:
	var r: Rig = _rig([&"a:one"])
	await _to_wait(r)
	var writes: int = _alpha_writes()
	for ms: int in [500, 1000, 3000]:
		_at(r, ms)
	assert_int(_alpha_writes()).is_equal(writes)
	assert_int(r.loader.get_phase()).is_equal(SceneLoader.Phase.WAITING_HOLDS)
	r.loader.release_hold(&"a:one")
	_at(r, 3100)
	assert_int(_count("bus:scene_ready")).is_equal(1)


func test_hold_never_released_fails_at_exactly_t_cap_with_its_id() -> void:
	var r: Rig = _rig([&"puerta:cerradura"])
	await _to_wait(r)
	_at(r, T_CAP_MS - 1)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.LOADING)
	assert_int(_count("bus:scene_load_failed")).is_equal(0)
	_at(r, T_CAP_MS)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_int(_count("bus:scene_load_failed")).is_equal(1)
	assert_bool(_logged(r, "t_cap")).is_true()
	assert_bool(_logged(r, "puerta:cerradura")).is_true()
	assert_int(_count("bus:scene_ready")).is_equal(0)
	assert_float(r.loader.get_curtain_alpha()).is_equal(1.0)


func test_pending_ids_in_the_failure_log_are_only_the_unreleased_ones_sorted() -> void:
	var r: Rig = _rig([&"z:last", &"a:first", &"m:released"])
	await _to_wait(r)
	r.loader.release_hold(&"m:released")
	_at(r, T_CAP_MS)
	assert_bool(_logged(r, "pending=[&\"a:first\", &\"z:last\"]")).is_true()


func test_one_hundred_holds_released_at_one_second_do_not_accumulate_to_a_failure() -> void:
	var ids: Array[StringName] = []
	for i: int in 100:
		ids.append(StringName("sys:e%d" % i))
	var r: Rig = _rig(ids)
	await _to_wait(r)
	assert_int(r.loader.get_hold_count()).is_equal(100)
	for id: StringName in ids:
		r.loader.release_hold(id)
	_at(r, 1000)
	assert_int(_count("bus:scene_ready")).is_equal(1)
	assert_int(_count("bus:scene_load_failed")).is_equal(0)


func test_window_without_focus_for_twenty_seconds_still_fails_by_real_time() -> void:
	var r: Rig = _rig([&"a:one"])
	await _to_wait(r)
	_at(r, 100)
	_at(r, 20000) # one huge frame: wall time keeps running, nothing is clipped
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_int(_count("bus:scene_load_failed")).is_equal(1)


func test_release_at_the_cap_frame_wins_over_the_failure() -> void:
	var r: Rig = _rig([&"a:one"])
	await _to_wait(r)
	r.loader.release_hold(&"a:one")
	_at(r, T_CAP_MS)
	assert_int(_count("bus:scene_ready")).is_equal(1)
	assert_int(_count("bus:scene_load_failed")).is_equal(0)


# --- take / release semantics ---

func test_take_is_idempotent_and_one_release_frees_it() -> void:
	var r: Rig = _rig([&"a:one", &"a:one"])
	await _to_wait(r)
	assert_int(r.loader.get_hold_count()).is_equal(1)
	r.loader.release_hold(&"a:one")
	assert_int(r.loader.get_hold_count()).is_equal(0)


func test_double_and_unknown_releases_never_go_below_zero() -> void:
	var r: Rig = _rig([&"a:one", &"b:two"])
	await _to_wait(r)
	r.loader.release_hold(&"a:one")
	r.loader.release_hold(&"a:one")
	r.loader.release_hold(&"nadie:nada")
	assert_int(r.loader.get_hold_count()).is_equal(1) # the double release did not eat b's hold
	r.loader.release_hold(&"b:two")
	r.loader.release_hold(&"b:two")
	assert_int(r.loader.get_hold_count()).is_equal(0)


func test_no_holds_means_ready_in_the_configure_frame() -> void:
	var r: Rig = _rig([])
	await _to_wait(r)
	assert_int(_count("bus:scene_ready")).is_equal(1)
	assert_int(r.loader.get_hold_count()).is_equal(0)


# --- AC-19 (holds part) ---

func test_hold_taken_after_scene_ready_is_ignored_logged_and_ready_is_not_repeated() -> void:
	var r: Rig = _rig([])
	await _to_wait(r)
	assert_int(_count("bus:scene_ready")).is_equal(1)
	r.loader.take_hold(&"tarde:elemento")
	assert_int(r.loader.get_hold_count()).is_equal(0)
	assert_bool(_logged(r, "tarde:elemento")).is_true()
	for ms: int in [100, 200, 400]:
		_at(r, ms)
	assert_int(_count("bus:scene_ready")).is_equal(1)


func test_hold_taken_before_the_window_opens_is_ignored_and_logged() -> void:
	var r: Rig = _rig([])
	r.loader.take_hold(&"pronto:elemento")
	assert_int(r.loader.get_hold_count()).is_equal(0)
	assert_bool(_logged(r, "pronto:elemento")).is_true()


func test_hold_after_a_t_cap_failure_is_ignored() -> void:
	var r: Rig = _rig([&"a:one"])
	await _to_wait(r)
	_at(r, T_CAP_MS)
	r.loader.take_hold(&"b:late")
	assert_int(r.loader.get_hold_count()).is_equal(1) # only the old one; the late one was refused
	assert_bool(_logged(r, "b:late")).is_true()


# --- AC-F3 part 3 ---

func test_t_cap_failure_happens_at_d_out_plus_t_cap_before_d_carga() -> void:
	var r: Rig = _rig([&"a:one"])
	await _to_wait(r)
	_at(r, 20000) # also without focus
	var fail_ms: int = r.clock.ms
	# d_out 0.8 s -> the curtain is dark ~800 ms after the start; the failure comes T_cap later.
	assert_int(r.dark_ms).is_greater_equal(800)
	assert_int(r.dark_ms).is_less(800 + 100)
	var d_carga_ms: float = (0.8 + 10.0 + 2.0 * 0.0333333333 + 0.8) * 1000.0
	var cap_ms: int = r.dark_ms + T_CAP_MS
	assert_float(float(cap_ms)).is_less(d_carga_ms)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_int(fail_ms).is_greater_equal(cap_ms)
