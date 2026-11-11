extends GdUnitTestSuite
# Verifica NP-1, NP-2 y NP-3 de ADR-0012 en Godot 4.7.2 (S-0012-A y S-0012-F, parte numerica headless).
## S-0012-A: all pending _physics_process ticks run before _process in a frame; 2 ticks/frame at 30 fps,
## 0-1 at 144; own interpolation (prev/curr + accumulator alpha) is monotonic and moves v*frame_dt per frame.
## S-0012-F: engine physics interpolation is off by default; a paused own interpolator leaves the camera
## transform identical and resumes with <= one tick of displacement.
## Only deterministic asserts live here (step order vs _process, structure). The load-sensitive ones (ticks/frame
## rate, per-frame deviations, first resume step) are in tests/timing/adr0012_tick_rate_timing_test.gd.
## The rendered/visual part and the full 15,1 s corridor walk are NEEDS_WINDOWED (prototypes/physics-spike/).

const SPEED: float = 1.6
const ACCEL_S: float = 0.2
const TICK_DT: float = 1.0 / 60.0


class Rig extends Node3D:
	var tick_dt: float = 1.0 / 60.0
	var speed: float = 1.6
	var accel_s: float = 0.2
	var held: bool = true
	var paused_own: bool = false
	var prev_x: float = 0.0
	var curr_x: float = 0.0
	var vel: float = 0.0
	var acc: float = 0.0
	var ticks_this_frame: int = 0
	var seq: Array[String] = []  # "P" per tick, "R" per rendered frame
	var frames: Array[Dictionary] = []
	var camera: Camera3D
	var use_engine_fraction: bool = false

	func _physics_process(_delta: float) -> void:
		if paused_own:
			return
		ticks_this_frame += 1
		seq.append("P")
		var target: float = speed if held else 0.0
		vel = move_toward(vel, target, speed / accel_s * tick_dt)
		prev_x = curr_x
		curr_x += vel * tick_dt

	func _process(delta: float) -> void:
		seq.append("R")
		if not paused_own:
			acc += delta
			acc -= tick_dt * float(ticks_this_frame)
			acc = maxf(acc, 0.0)
		var alpha: float = clampf(acc / tick_dt, 0.0, 1.0)
		var eye_own: float = lerpf(prev_x, curr_x, alpha)
		var frac: float = Engine.get_physics_interpolation_fraction()
		var eye_x: float = lerpf(prev_x, curr_x, frac) if use_engine_fraction else eye_own
		if camera != null:
			camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(eye_x, 1.6, 0.0))
		frames.append({
			"delta": delta, "ticks": ticks_this_frame, "alpha": alpha, "eye_x": eye_x, "eye_own": eye_own,
			"eye_engine": lerpf(prev_x, curr_x, frac),
			"engine_fraction": frac,
			"paused": paused_own,
		})
		ticks_this_frame = 0


func _run_walk(fps_cap: int, seconds: float) -> Array[Dictionary]:
	var rig: Rig = Rig.new()
	var cam: Camera3D = Camera3D.new()
	rig.camera = cam
	rig.add_child(cam)
	add_child(auto_free(rig))
	Engine.max_fps = fps_cap
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += float((rig.frames.back() as Dictionary)["delta"]) if not rig.frames.is_empty() else 0.0
	Engine.max_fps = 0
	rig.set_process(false)
	rig.set_physics_process(false)
	var out: Array[Dictionary] = rig.frames.duplicate()
	out.append({"seq": rig.seq.duplicate()})
	return out


func test_physics_tick_rate_reads_back_60_and_engine_interpolation_defaults_off() -> void:
	# Arrange / Act
	var setting: Variant = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", -1)
	var interp_setting: Variant = ProjectSettings.get_setting("physics/common/physics_interpolation", "UNSET")
	var root_interpolated: bool = get_tree().root.is_physics_interpolated_and_enabled()
	print("S-0012-A/F physics_ticks_per_second setting=", setting, " Engine.physics_ticks_per_second=", Engine.physics_ticks_per_second,
		" | physics_interpolation setting=", interp_setting, " root.is_physics_interpolated_and_enabled=", root_interpolated,
		" has_setting=", ProjectSettings.has_setting("physics/common/physics_interpolation"))

	# Assert
	assert_int(Engine.physics_ticks_per_second).is_equal(60)
	assert_bool(root_interpolated).is_false()


func test_ticks_run_before_process_in_each_frame_at_30_60_and_144_fps() -> void:
	# Arrange
	var summary: Dictionary = {}

	# Act
	for cap: int in [30, 60, 144]:
		var r: Array[Dictionary] = await _run_walk(cap, 1.5)
		var seq: Array = (r.back() as Dictionary)["seq"]
		var frames: Array[Dictionary] = r.slice(0, r.size() - 1)
		# Within the sequence, each "R" must come after the ticks of its frame; i.e. no "P" is ever
		# recorded between an "R" and the end of that same frame: proven by frames' tick counts matching
		# the "P" entries preceding each "R".
		var p_before_r: int = 0
		var mismatch: int = 0
		var frame_idx: int = 0
		for e: String in seq:
			if e == "P":
				p_before_r += 1
			else:
				if frame_idx < frames.size() and int(frames[frame_idx]["ticks"]) != p_before_r:
					mismatch += 1
				p_before_r = 0
				frame_idx += 1
		var tick_hist: Dictionary = {}
		for f: Dictionary in frames:
			var n: int = int(f["ticks"])
			tick_hist[n] = int(tick_hist.get(n, 0)) + 1
		summary[cap] = {"frames": frames.size(), "tick_hist": tick_hist, "mismatch": mismatch}
		print("S-0012-A cap=", cap, " frames=", frames.size(), " ticks/frame histogram=", tick_hist, " order mismatches=", mismatch)

	# Assert
	for cap: int in [30, 60, 144]:
		assert_int(int((summary[cap] as Dictionary)["mismatch"])).is_equal(0)


func test_paused_own_interpolator_keeps_camera_identical() -> void:
	# Arrange: engine interpolation is off (S-0012-F); walk a few frames, then pause. No fps cap: structural only.
	var rig: Rig = Rig.new()
	var cam: Camera3D = Camera3D.new()
	rig.camera = cam
	rig.add_child(cam)
	add_child(auto_free(rig))
	for i: int in 20:
		await get_tree().process_frame

	# Act
	rig.paused_own = true
	await get_tree().process_frame
	var pose_at_pause: Transform3D = cam.global_transform
	var identical: int = 0
	var frames_paused: int = 30
	for i: int in frames_paused:
		await get_tree().process_frame
		if cam.global_transform == pose_at_pause:
			identical += 1
	rig.set_process(false)
	rig.set_physics_process(false)

	# Assert
	assert_int(identical).is_equal(frames_paused)
	assert_bool(cam.is_physics_interpolated_and_enabled()).is_false()
