extends GdUnitTestSuite
## CP-015 (AC-11a, scope M1 `partida_nueva`): the boot wiring (`Boot.wire_scene_loading` + `Boot.start_new_game`)
## with the real SceneLoader, the real `planta.tscn`, the real Player and InputRouter, real data files and the
## real RealClock, no window. The wait is bounded by a wall-clock deadline that only aborts a hang: nothing asserts
## on elapsed time or on a frame count. Everything is freed by `auto_free`.

const WAIT_LIMIT_MS: int = 60000
const POS_TOLERANCE_M: float = 0.01
const YAW_TOLERANCE_DEG: float = 0.5

var _alphas: Array[float] = []


func _make_ctx() -> ServiceContext:
	var ctx: ServiceContext = ServiceContext.new()
	ctx.flavor = BuildFlavor.new(false)
	ctx.logger = RecordingLog.new()
	ctx.fatal = RecordingFatalHandler.new()
	ctx.files = FileStore.new()
	ctx.real_clock = RealClock.new()
	ctx.state = auto_free(GameState.new())
	ctx.clock = auto_free(GameClock.new())
	ctx.content = auto_free(ContentDB.new())
	ctx.input = auto_free(InputRouter.new())
	ctx.scenes = auto_free(SceneLoader.new())
	add_child(ctx.state)
	add_child(ctx.clock)
	add_child(ctx.input)
	add_child(ctx.scenes)
	return ctx


func test_new_game_boot_reaches_exploration_with_player_at_spawn_office() -> void:
	# Arrange
	_alphas = []
	var ctx: ServiceContext = _make_ctx()
	var slot: Node3D = auto_free(Node3D.new())
	add_child(slot)
	assert_bool(Boot.wire_state(ctx)).is_true()
	ctx.clock.setup(ctx)
	ctx.input.setup(ctx)
	ctx.scenes.setup(ctx)
	var sink: Callable = func(a: float) -> void: _alphas.append(a)
	assert_bool(Boot.wire_scene_loading(ctx, slot, sink, null)).is_true()

	# Act
	assert_bool(Boot.start_new_game(ctx)).is_true()
	var deadline: int = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while ctx.scenes.get_state() != SceneLoader.State.READY and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame

	# Assert: loaded and in exploration
	assert_int(ctx.scenes.get_state()).is_equal(SceneLoader.State.READY)
	assert_bool((ctx.fatal as RecordingFatalHandler).has_failed()).is_false()
	assert_int(ctx.input.top()).is_equal(InputTypes.Context.EXPLORACION)
	assert_bool(ctx.input.in_game()).is_true()
	assert_int(slot.get_child_count()).is_equal(1)
	# The curtain starts black (primed) and ends clear
	assert_float(_alphas[0]).is_equal(1.0)
	assert_float(_alphas[_alphas.size() - 1]).is_equal(0.0)
	# AC-11a: position, velocity and orientation of the anchor
	var root: GameSceneRoot = slot.get_child(0) as GameSceneRoot
	var anchor: Node3D = root.get_node(root.spawn_anchor) as Node3D
	var player: Player = root.get_player() as Player
	assert_object(player).is_not_null()
	var feet: Vector3 = player.global_position
	assert_float(feet.distance_to(anchor.global_position)).is_less(POS_TOLERANCE_M)
	assert_float(player.velocity.length()).is_less(POS_TOLERANCE_M)
	var yaw_err_deg: float = absf(rad_to_deg(angle_difference(player.pose_actual().yaw, anchor.global_rotation.y)))
	assert_float(yaw_err_deg).is_less(YAW_TOLERANCE_DEG)


func test_planta_loaded_twice_keeps_services_and_one_scene_per_sampled_frame() -> void:
	# Arrange
	_alphas = []
	var ctx: ServiceContext = _make_ctx()
	var slot: Node3D = auto_free(Node3D.new())
	add_child(slot)
	Boot.wire_state(ctx)
	ctx.clock.setup(ctx)
	ctx.input.setup(ctx)
	ctx.scenes.setup(ctx)
	assert_bool(Boot.wire_scene_loading(ctx, slot, func(a: float) -> void: _alphas.append(a), null)).is_true()
	var ids: Array[int] = [ctx.state.get_instance_id(), ctx.input.get_instance_id(), ctx.clock.get_instance_id()]
	var max_children: int = 0

	# Act: new game, then a second load of the same planta
	assert_bool(Boot.start_new_game(ctx)).is_true()
	var deadline: int = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while ctx.scenes.get_state() != SceneLoader.State.READY and Time.get_ticks_msec() < deadline:
		max_children = maxi(max_children, slot.get_child_count())
		await get_tree().process_frame
	var first: Node = slot.get_child(0)
	assert_bool(ctx.scenes.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.REANUDAR,
			SceneLoader.FinalControl.EXPLORACION)).is_true()
	deadline = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while ctx.scenes.get_state() != SceneLoader.State.READY and Time.get_ticks_msec() < deadline:
		max_children = maxi(max_children, slot.get_child_count())
		await get_tree().process_frame

	# Assert
	assert_int(ctx.scenes.get_state()).is_equal(SceneLoader.State.READY)
	assert_int(max_children).is_less_equal(1)
	assert_int(slot.get_child_count()).is_equal(1)
	assert_bool(is_instance_valid(first)).is_false()
	assert_array(ids).is_equal([ctx.state.get_instance_id(), ctx.input.get_instance_id(), ctx.clock.get_instance_id()])


func test_wants_auto_start_is_off_only_with_the_no_autostart_arg() -> void:
	assert_bool(Boot.wants_auto_start(PackedStringArray())).is_true()
	assert_bool(Boot.wants_auto_start(PackedStringArray(["--boot-report"]))).is_true()
	assert_bool(Boot.wants_auto_start(PackedStringArray(["--no-autostart"]))).is_false()
