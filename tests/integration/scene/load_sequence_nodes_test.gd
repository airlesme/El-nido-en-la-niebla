extends GdUnitTestSuite
## CP-005 integration: the load sequence with real nodes (SceneLoader in the tree driven by its own `_process`,
## real RealClock, a PackedScene instantiated by a real SceneSource, real ZoneHub), no window.
## Waits are bounded by a wall-clock deadline that only aborts a hang; nothing asserts on elapsed time.

const WAIT_LIMIT_MS: int = 20000

var _events: Array[String] = []
var _last_alpha: float = -1.0


## SceneSource backed by a real PackedScene (instantiated fresh on every call).
class PackedSource extends SceneSource:
	var packed: PackedScene
	var count: int = 0

	func instantiate(_destination: StringName) -> Node:
		count += 1
		return packed.instantiate()


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


func _await_state(loader: SceneLoader, wanted: SceneLoader.State) -> void:
	var deadline: int = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while loader.get_state() != wanted and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_int(loader.get_state()).is_equal(wanted)


func test_planta_reload_with_real_nodes_frees_the_old_scene_and_ends_ready() -> void:
	_events = []
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

	assert_bool(loader.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.PARTIDA_NUEVA,
			SceneLoader.FinalControl.EXPLORACION)).is_true()
	await _await_state(loader, SceneLoader.State.READY)
	assert_int(slot.get_child_count()).is_equal(1)
	var first: Node = slot.get_child(0)
	assert_bool((first as SceneRootDouble).get_zone_hub().is_enabled()).is_true()
	assert_float(_last_alpha).is_equal(0.0)

	assert_bool(loader.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.REANUDAR,
			SceneLoader.FinalControl.EXPLORACION)).is_true()
	await _await_state(loader, SceneLoader.State.READY)
	assert_bool(is_instance_valid(first)).is_false()
	assert_int(slot.get_child_count()).is_equal(1)
	assert_int(source.count).is_equal(2)
	assert_int(input.reset_calls).is_equal(1)
	assert_int(input.exploration_requests).is_equal(2)
	assert_int(input.opens.size()).is_equal(2)
	assert_bool(loader.is_processing()).is_false()
	assert_float(_last_alpha).is_equal(0.0)
	assert_int(state.write_count).is_equal(0)
