extends GdUnitTestSuite
## Regression probe (user report 2026-11-12): after a new game, holding W must move the player where the camera
## looks. Real boot wiring, real planta, real Player and InputRouter, a real key event through the engine.

const WAIT_LIMIT_MS: int = 60000
const MIN_TRAVEL_M: float = 0.6
const MAX_ANGLE_DEG: float = 3.0


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


func _key(code: Key, pressed: bool) -> InputEventKey:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	return ev


func test_holding_w_after_new_game_moves_along_the_camera_forward() -> void:
	# Arrange
	var ctx: ServiceContext = _make_ctx()
	var slot: Node3D = auto_free(Node3D.new())
	add_child(slot)
	assert_bool(Boot.wire_state(ctx)).is_true()
	ctx.clock.setup(ctx)
	ctx.input.setup(ctx)
	ctx.scenes.setup(ctx)
	assert_bool(Boot.wire_scene_loading(ctx, slot, func(_a: float) -> void: pass, null)).is_true()
	assert_bool(Boot.start_new_game(ctx)).is_true()
	var deadline: int = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while ctx.scenes.get_state() != SceneLoader.State.READY and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var root: GameSceneRoot = slot.get_child(0) as GameSceneRoot
	var player: Player = root.get_player() as Player
	var start: Vector3 = player.global_position

	# Act: a real W press, then wait (bounded) until the body has travelled
	Input.parse_input_event(_key(KEY_W, true))
	deadline = Time.get_ticks_msec() + WAIT_LIMIT_MS
	while player.global_position.distance_to(start) < MIN_TRAVEL_M and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await get_tree().process_frame
	var disp: Vector3 = player.global_position - start
	disp.y = 0.0
	var cam_fwd: Vector3 = -(player.get_node("%MainCamera") as Camera3D).global_basis.z
	cam_fwd.y = 0.0
	var angle_deg: float = rad_to_deg(disp.signed_angle_to(cam_fwd, Vector3.UP))
	print("WALKDIR move=", ctx.input.get_move_vector(), " disp=", disp, " cam_fwd=", cam_fwd, " angle_deg=", angle_deg,
			" yaw=", player.pose_actual().yaw)
	Input.parse_input_event(_key(KEY_W, false))

	# Assert
	assert_float(disp.length()).is_greater(MIN_TRAVEL_M)
	assert_float(absf(angle_deg)).is_less(MAX_ANGLE_DEG)
