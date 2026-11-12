extends GdUnitTestSuite
## CP-009 integration (T-I5, part of 4): the full unload with REAL nodes and the tree PAUSED
## (the "Volver al título" path from the pause menu), no window. SceneLoader is PROCESS_MODE_ALWAYS
## and drives itself with its own `_process`; real RealClock. Waits are bounded by a wall-clock
## deadline that only aborts a hang; nothing asserts on elapsed time or a frame count.

const WAIT_LIMIT_MS: int = 20000

var _events: Array[String] = []
var _last_alpha: float = -1.0


## SceneSource backed by a real PackedScene for the game scene and a bare Node as the title marker.
class PackedSource extends SceneSource:
	var packed: PackedScene
	var titles: int = 0

	func instantiate(destination: StringName) -> Node:
		if destination == SceneSource.TITLE:
			titles += 1
			var marker: Node = Node.new()
			marker.name = &"TitleMarker"
			return marker
		return packed.instantiate()


func after_test() -> void:
	get_tree().paused = false


func _packed_root() -> PackedScene:
	var root: SceneRootDouble = SceneRootDouble.new().build(_events)
	for child: Node in root.get_children():
		child.owner = root
	var packed: PackedScene = PackedScene.new()
	assert_int(packed.pack(root)).is_equal(OK)
	root.free()
	return packed


func _transitions() -> LoadTransitions:
	var row: Dictionary = {"d_out": 0.05, "d_in": 0.05}
	return LoadTransitions.from_dict({
		"t_cap_s": 10.0, "n_gap": 2, "delta_max_s": 0.1, "delta_ref_s": 0.0333333333,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {"partida_nueva": row, "reanudar": row, "recepcion": row, "cierre": {"d_out": 0.05}},
	})


func _on_bus(_payload: Dictionary, id: StringName) -> void:
	_events.append("bus:%s" % id)


func _await_until(condition: Callable) -> void:
	var deadline: int = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_bool(condition.call()).is_true()


func test_full_unload_with_the_tree_paused_frees_the_scene_and_keeps_requested_before_completed() -> void:
	_events = []
	_last_alpha = -1.0
	var state: ChanneledGameState = auto_free(ChanneledGameState.new())
	var input: SpyInputContexts = SpyInputContexts.new()
	var source: PackedSource = PackedSource.new()
	source.packed = _packed_root()
	var slot: Node3D = auto_free(Node3D.new())
	add_child(slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.logger = RecordingLog.new()
	ctx.flavor = BuildFlavor.new(false)
	ctx.fatal = RecordingFatalHandler.new()
	ctx.state = state
	ctx.clock = auto_free(GameClock.new())
	var loader: SceneLoader = SceneLoader.new()
	loader.setup(ctx)
	loader.set_source(source)
	loader.wire_sequence(slot, _transitions(), RealClock.new(), input,
			func(a: float) -> void: _last_alpha = a)
	add_child(loader)
	auto_free(loader)
	for id: StringName in [NoticeIds.FULL_UNLOAD_REQUESTED, NoticeIds.FULL_UNLOAD_COMPLETED,
			NoticeIds.GAME_FINISHED]:
		state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, id, _on_bus.bind(id))

	assert_bool(loader.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.PARTIDA_NUEVA,
			SceneLoader.FinalControl.EXPLORACION)).is_true()
	await _await_until(func() -> bool: return loader.get_state() == SceneLoader.State.READY)
	var scene: Node = slot.get_child(0)
	assert_bool(loader.process_mode == Node.PROCESS_MODE_ALWAYS).is_true()

	get_tree().paused = true
	assert_bool(loader.request_full_unload()).is_true()
	assert_int(loader.get_state()).is_equal(SceneLoader.State.NO_SCENE)
	await _await_until(func() -> bool: return loader.get_phase() == SceneLoader.Phase.IDLE)

	assert_bool(get_tree().paused).is_true() # nothing in the unload resumed the tree
	assert_bool(is_instance_valid(scene)).is_false() # no orphan: the instance is gone
	assert_int(slot.get_child_count()).is_equal(1)
	assert_str(String(slot.get_child(0).name)).is_equal("TitleMarker")
	assert_int(source.titles).is_equal(1)
	assert_float(_last_alpha).is_equal(1.0)
	assert_int(loader.get_state()).is_equal(SceneLoader.State.NO_SCENE)
	assert_int(_events.count("bus:%s" % NoticeIds.FULL_UNLOAD_REQUESTED)).is_equal(1)
	assert_int(_events.count("bus:%s" % NoticeIds.FULL_UNLOAD_COMPLETED)).is_equal(1)
	assert_bool(_events.find("bus:%s" % NoticeIds.FULL_UNLOAD_REQUESTED)
			< _events.find("bus:%s" % NoticeIds.FULL_UNLOAD_COMPLETED)).is_true()
	assert_int(_events.count("bus:%s" % NoticeIds.GAME_FINISHED)).is_equal(0)
	assert_int(input.reset_calls).is_equal(0)
	assert_int(input.restore_calls).is_equal(1)
	assert_bool(loader.is_processing()).is_false()
