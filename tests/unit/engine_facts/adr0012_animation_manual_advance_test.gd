extends GdUnitTestSuite
# Verifica NP-7 de ADR-0012 en Godot 4.7.2 (S-0012-E).
## S-0012-E: AnimationPlayer/AnimationTree with callback_mode_process = MANUAL advanced by a fake
## GameClock delta: pose constant while not advanced (120 frames), clip completes after 1.0 s of
## advanced time +- 1 frame, AnimationTree parameter set from code takes effect on the next advance.

const FAKE_DT: float = 1.0 / 60.0


func _build_rig() -> Dictionary:
	var holder: Node = auto_free(Node.new())
	var target: Node3D = Node3D.new()
	target.name = "Target"
	holder.add_child(target)

	var lib: AnimationLibrary = AnimationLibrary.new()
	var clip: Animation = Animation.new()
	clip.length = 1.0
	var t: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(t, NodePath("Target:position:x"))
	clip.track_insert_key(t, 0.0, 0.0)
	clip.track_insert_key(t, 1.0, 10.0)
	lib.add_animation(&"clip", clip)
	var a_zero: Animation = Animation.new()
	a_zero.length = 1.0
	a_zero.loop_mode = Animation.LOOP_LINEAR
	var t2: int = a_zero.add_track(Animation.TYPE_VALUE)
	a_zero.track_set_path(t2, NodePath("Target:position:y"))
	a_zero.track_insert_key(t2, 0.0, 0.0)
	lib.add_animation(&"zero", a_zero)
	var a_ten: Animation = Animation.new()
	a_ten.length = 1.0
	a_ten.loop_mode = Animation.LOOP_LINEAR
	var t3: int = a_ten.add_track(Animation.TYPE_VALUE)
	a_ten.track_set_path(t3, NodePath("Target:position:y"))
	a_ten.track_insert_key(t3, 0.0, 10.0)
	lib.add_animation(&"ten", a_ten)

	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.add_animation_library(&"", lib)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	holder.add_child(player)

	var root: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	var na: AnimationNodeAnimation = AnimationNodeAnimation.new()
	na.animation = &"zero"
	var nb: AnimationNodeAnimation = AnimationNodeAnimation.new()
	nb.animation = &"ten"
	var blend: AnimationNodeBlend2 = AnimationNodeBlend2.new()
	root.add_node(&"a", na)
	root.add_node(&"b", nb)
	root.add_node(&"blend", blend)
	root.connect_node(&"blend", 0, &"a")
	root.connect_node(&"blend", 1, &"b")
	root.connect_node(&"output", 0, &"blend")
	var tree: AnimationTree = AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = root
	tree.anim_player = NodePath("../AnimationPlayer")
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	holder.add_child(tree)
	add_child(holder)
	return {"target": target, "player": player, "tree": tree}


func test_manual_player_pose_is_constant_for_120_frames_without_advance_and_ends_after_1_s() -> void:
	# Arrange
	var rig: Dictionary = _build_rig()
	var target: Node3D = rig["target"]
	var player: AnimationPlayer = rig["player"]
	player.play(&"clip")
	player.advance(0.0)
	await get_tree().process_frame

	# Act: 30 ticks of 1/60 s advanced, then 120 frames of "pause" with no advance
	for i: int in 30:
		player.advance(FAKE_DT)
	var x_at_pause: float = target.position.x
	var changes: int = 0
	for i: int in 120:
		await get_tree().process_frame
		if absf(target.position.x - x_at_pause) > 1e-9:
			changes += 1
	# resume: 30 more ticks reach 1.0 s of advanced time
	for i: int in 29:
		player.advance(FAKE_DT)
	var x_before_last: float = target.position.x
	player.advance(FAKE_DT)
	var x_end: float = target.position.x
	print("S-0012-E manual player: x at 0.5 s=", x_at_pause, " changes during 120 paused frames=", changes,
		" x at 59 ticks=", x_before_last, " x at 60 ticks=", x_end, " is_playing=", player.is_playing(), " position=", player.current_animation_position)

	# Assert
	assert_float(x_at_pause).is_equal_approx(5.0, 0.2)
	assert_int(changes).is_equal(0)
	assert_float(x_before_last).is_less(10.0)
	assert_float(x_end).is_equal_approx(10.0, 0.2)


func test_animation_tree_parameter_set_from_code_takes_effect_on_next_advance() -> void:
	# Arrange
	var rig: Dictionary = _build_rig()
	var target: Node3D = rig["target"]
	var tree: AnimationTree = rig["tree"]
	tree.active = true
	tree.set(&"parameters/blend/blend_amount", 0.0)
	tree.advance(FAKE_DT)
	var y0: float = target.position.y

	# Act
	tree.set(&"parameters/blend/blend_amount", 1.0)
	var y_before_advance: float = target.position.y
	tree.advance(FAKE_DT)
	var y1: float = target.position.y
	tree.set(&"parameters/blend/blend_amount", 0.5)
	tree.advance(FAKE_DT)
	var y_half: float = target.position.y
	print("S-0012-E tree param: y(blend 0)=", y0, " y after set(1.0) before advance=", y_before_advance, " after advance=", y1, " y(blend 0.5)=", y_half)

	# Assert
	assert_float(y0).is_equal_approx(0.0, 1e-3)
	assert_float(y_before_advance).is_equal_approx(y0, 1e-6)
	assert_float(y1).is_equal_approx(10.0, 1e-3)
	assert_float(y_half).is_equal_approx(5.0, 1e-3)
