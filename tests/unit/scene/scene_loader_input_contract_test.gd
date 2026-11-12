extends GdUnitTestSuite
## CP-006 (T-U6 of ADR-0003): the `sin control` contract between the loader (4) and Entrada.
## AC-21, AC-21b and "unloading the title never resets the stack" (D2). Virtual time only; no frame count asserted.
## The safety cap (D_carga + margin) belongs to the router and is covered in tests/unit/input.

const PLANTA: SceneLoader.Destination = SceneLoader.Destination.PLANTA
const RECEPCION: SceneLoader.Destination = SceneLoader.Destination.RECEPCION
const NEW_GAME: SceneLoader.Reason = SceneLoader.Reason.PARTIDA_NUEVA
const RESUME: SceneLoader.Reason = SceneLoader.Reason.REANUDAR
const REC: SceneLoader.Reason = SceneLoader.Reason.RECEPCION
const EXPLORE: SceneLoader.FinalControl = SceneLoader.FinalControl.EXPLORACION
const NONE: SceneLoader.FinalControl = SceneLoader.FinalControl.NINGUNO
const FRAME_MS: int = 16
const MAX_TICKS: int = 3000
const MENU: InputTypes.Context = InputTypes.Context.MENU
const NO_CONTROL: InputTypes.Context = InputTypes.Context.SIN_CONTROL
const EXPLORATION: InputTypes.Context = InputTypes.Context.EXPLORACION
const LOADER: StringName = InputTypes.OWNER_SCENE_LOADER
const DIRECTOR: StringName = InputTypes.OWNER_SCENE_DIRECTOR


## Input double that models the context stack as [context, owner] pairs and logs every call.
class StackInput extends InputContexts:
	var stack: Array[Array] = []
	var calls: Array[String] = []
	var open_args: Array[Dictionary] = []
	var closes_by_loader: int = 0
	var menu_restores: int = 0
	var resets: int = 0

	func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
		calls.append("open")
		open_args.append({&"owner": owner, &"declared_s": declared_s, &"absorbs": absorbs_foreign})
		stack.append([InputTypes.Context.SIN_CONTROL, owner])
		return true

	func close_no_control(owner: StringName) -> bool:
		calls.append("close")
		if owner == InputTypes.OWNER_SCENE_LOADER:
			closes_by_loader += 1
		return true

	func transfer_no_control(new_owner: StringName, _declared_s: float) -> bool:
		calls.append("transfer")
		if stack.is_empty() or stack.back()[0] != InputTypes.Context.SIN_CONTROL:
			return false
		stack.back()[1] = new_owner
		return true

	func request_exploration(_owner: StringName) -> bool:
		calls.append("exploration")
		stack.clear()
		stack.append([InputTypes.Context.EXPLORACION, &""])
		return true

	func restore_menu() -> void:
		calls.append("restore_menu")
		menu_restores += 1
		stack.clear()
		stack.append([InputTypes.Context.MENU, &""])

	func reset_stack_on_unload() -> void:
		calls.append("reset")
		resets += 1
		var kept: Array[Array] = []
		for entry: Array in stack:
			if entry[0] == InputTypes.Context.SIN_CONTROL:
				kept.append(entry)
		stack = kept

	func contexts() -> Array[int]:
		var out: Array[int] = []
		for entry: Array in stack:
			out.append(entry[0])
		return out

	func owner_of_top() -> StringName:
		return stack.back()[1]


class Rig extends RefCounted:
	var loader: SceneLoader
	var clock: FakeRealClock
	var input: StackInput
	var source: SceneSource
	var slot: Node3D
	var sink: RecordingLog


var _finished: Array[Dictionary] = []


func before_test() -> void:
	_finished = []


func _on_finished(payload: Dictionary) -> void:
	_finished.append(payload)


func _transitions() -> LoadTransitions:
	var row: Dictionary = {"d_out": 0.8, "d_in": 0.8}
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": 2, "delta_max_s": 0.1, "delta_ref_s": 0.0333333333,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {"partida_nueva": {"d_out": 0.8, "d_in": 2.0}, "reanudar": row,
				"recepcion": row, "cierre": {"d_out": 0.8}},
	})


## `from_menu`: stack [menu] and nothing loaded; otherwise [exploracion] with a loaded planta in the slot.
func _rig(source: SceneSource, from_menu: bool = true) -> Rig:
	var r: Rig = Rig.new()
	var state: ChanneledGameState = auto_free(ChanneledGameState.new())
	state.call_completed = true
	r.clock = FakeRealClock.new()
	r.input = StackInput.new()
	r.source = source
	r.sink = RecordingLog.new()
	r.slot = auto_free(Node3D.new())
	add_child(r.slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = r.sink
	ctx.flavor = BuildFlavor.new(false)
	ctx.fatal = RecordingFatalHandler.new()
	ctx.state = state
	ctx.clock = auto_free(GameClock.new())
	r.loader = auto_free(SceneLoader.new())
	r.loader.setup(ctx)
	r.loader.set_source(source)
	r.loader.wire_sequence(r.slot, _transitions(), r.clock, r.input, func(_a: float) -> void: pass)
	state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_LOAD_FINISHED, _on_finished)
	if from_menu:
		r.input.stack.append([MENU, &""])
	else:
		r.input.stack.append([EXPLORATION, &""])
		r.slot.add_child(Node3D.new())
		r.loader.set_runtime_state(SceneLoader.State.READY, SceneLoader.Destination.PLANTA)
	return r


func _run(r: Rig) -> void:
	var guard: int = 0
	while r.loader.get_state() == SceneLoader.State.LOADING and guard < MAX_TICKS:
		guard += 1
		r.clock.ms += FRAME_MS
		r.loader.tick()
		if r.loader.get_phase() == SceneLoader.Phase.INSTANTIATING:
			await get_tree().process_frame
	assert_bool(guard < MAX_TICKS).is_true()


# --- AC-21 ---

func test_new_game_from_title_opens_no_control_owned_by_loader() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	assert_bool(r.loader.request_load(PLANTA, NEW_GAME, NONE)).is_true()
	assert_array(r.input.contexts()).is_equal([MENU, NO_CONTROL])
	assert_str(String(r.input.owner_of_top())).is_equal(String(LOADER))
	assert_int(r.input.open_args.size()).is_equal(1)
	assert_bool(r.input.open_args[0][&"absorbs"]).is_true()
	assert_float(r.input.open_args[0][&"declared_s"]).is_greater(0.0)


func test_resume_absorbs_foreign_contexts() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	r.loader.request_load(PLANTA, RESUME, NONE)
	assert_bool(r.input.open_args[0][&"absorbs"]).is_true()


func test_reception_reload_does_not_absorb_foreign_contexts() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new(), false)
	assert_bool(r.loader.request_load(RECEPCION, REC, EXPLORE)).is_true()
	assert_bool(r.input.open_args[0][&"absorbs"]).is_false()


func test_failed_load_restores_menu_and_never_closes() -> void:
	var src: ScriptedSceneSource = ScriptedSceneSource.new()
	src.fail = true
	var r: Rig = _rig(src)
	r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)
	await _run(r)
	assert_int(r.loader.get_state()).is_equal(SceneLoader.State.ERROR)
	assert_array(r.input.contexts()).is_equal([MENU])
	assert_int(r.input.menu_restores).is_equal(1)
	assert_int(r.input.closes_by_loader).is_equal(0)
	assert_int(r.input.calls.count("exploration")).is_equal(0)


func test_handoff_in_terminated_frame_leaves_21_as_owner_without_loader_close() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	r.loader.request_load(PLANTA, NEW_GAME, NONE)
	await _run(r)
	assert_int(_finished.size()).is_equal(1)
	assert_bool(r.input.transfer_no_control(DIRECTOR, 1.0)).is_true()
	assert_array(r.input.contexts()).is_equal([MENU, NO_CONTROL])
	assert_str(String(r.input.owner_of_top())).is_equal(String(DIRECTOR))
	assert_int(r.input.closes_by_loader).is_equal(0)
	assert_int(r.input.menu_restores).is_equal(0)


func test_no_handoff_leaves_loader_without_closing_or_restoring_menu() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	r.loader.request_load(PLANTA, NEW_GAME, NONE)
	await _run(r)
	# Nobody takes over: releasing is the router's cap, never the loader's.
	assert_int(r.input.closes_by_loader).is_equal(0)
	assert_int(r.input.menu_restores).is_equal(0)
	assert_str(String(r.input.owner_of_top())).is_equal(String(LOADER))


func test_terminated_reports_elapsed_time_from_the_real_clock() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	var start_ms: int = r.clock.ms
	r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)
	await _run(r)
	var elapsed_s: float = float(r.clock.ms - start_ms) / 1000.0
	assert_float(float(_finished[0][&"t_since_started_s"])).is_equal_approx(elapsed_s, 0.0001)


# --- AC-21b ---

func test_control_final_none_from_title_follows_the_stack_chain() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	r.loader.request_load(PLANTA, NEW_GAME, NONE)
	assert_array(r.input.contexts()).is_equal([MENU, NO_CONTROL])
	await _run(r)
	assert_int(r.input.calls.count("exploration")).is_equal(0) # `ninguno`: 4 leaves the stack alone
	assert_array(r.input.contexts()).is_equal([MENU, NO_CONTROL])
	r.input.transfer_no_control(DIRECTOR, 1.0)
	assert_str(String(r.input.owner_of_top())).is_equal(String(DIRECTOR))
	r.input.request_exploration(DIRECTOR)
	assert_array(r.input.contexts()).is_equal([EXPLORATION])
	assert_int(r.input.closes_by_loader).is_equal(0)
	assert_int(r.input.menu_restores).is_equal(0)


func test_control_final_none_from_planta_follows_the_stack_chain() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new(), false)
	r.loader.request_load(PLANTA, RESUME, NONE)
	assert_array(r.input.contexts()).is_equal([EXPLORATION, NO_CONTROL])
	await _run(r)
	assert_int(r.input.resets).is_equal(1)
	assert_array(r.input.contexts()).is_equal([NO_CONTROL])
	r.input.transfer_no_control(DIRECTOR, 1.0)
	assert_array(r.input.contexts()).is_equal([NO_CONTROL])
	assert_str(String(r.input.owner_of_top())).is_equal(String(DIRECTOR))
	r.input.request_exploration(DIRECTOR)
	assert_array(r.input.contexts()).is_equal([EXPLORATION])
	assert_int(r.input.closes_by_loader).is_equal(0)
	assert_int(r.input.menu_restores).is_equal(0)


func test_control_final_exploration_requests_it_once_at_terminated() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)
	await _run(r)
	assert_int(r.input.calls.count("exploration")).is_equal(1)
	assert_array(r.input.contexts()).is_equal([EXPLORATION])


# --- D2 ---

func test_unloading_the_title_does_not_reset_the_stack() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new())
	r.slot.add_child(Node3D.new()) # the title occupies the slot; nothing game-related is loaded
	r.loader.request_load(PLANTA, NEW_GAME, EXPLORE)
	await _run(r)
	assert_int(r.input.resets).is_equal(0)
	assert_int(_finished.size()).is_equal(1)


func test_unloading_a_game_scene_resets_the_stack_exactly_once() -> void:
	var r: Rig = _rig(ScriptedSceneSource.new(), false)
	r.loader.request_load(PLANTA, RESUME, EXPLORE)
	await _run(r)
	assert_int(r.input.resets).is_equal(1)
