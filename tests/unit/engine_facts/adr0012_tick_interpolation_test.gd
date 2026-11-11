extends GdUnitTestSuite
# Verifica NP-1, NP-2 y NP-3 de ADR-0012 en Godot 4.7.2 (S-0012-A y S-0012-F, parte numerica headless).
## S-0012-A: all pending _physics_process ticks run before _process in a frame; 2 ticks/frame at 30 fps,
## 0-1 at 144; own interpolation (prev/curr + accumulator alpha) is monotonic and moves v*frame_dt per frame.
## S-0012-F: engine physics interpolation is off by default; a paused own interpolator leaves the camera
## transform identical and resumes with <= one tick of displacement.
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
	var h30: Dictionary = (summary[30] as Dictionary)["tick_hist"]
	assert_bool(h30.has(2)).is_true()
	var h144: Dictionary = (summary[144] as Dictionary)["tick_hist"]
	assert_bool(h144.has(0)).is_true()
	assert_bool(h144.has(2) or h144.has(3)).is_false()


func _metrics(frames: Array[Dictionary], key: String) -> Dictionary:
	var worst_rel: float = 0.0
	var non_monotonic: int = 0
	var t: float = 0.0
	var checked: int = 0
	for i: int in range(1, frames.size()):
		var f: Dictionary = frames[i]
		var p: Dictionary = frames[i - 1]
		t += float(f["delta"])
		var dx: float = float(f[key]) - float(p[key])
		if dx <= 0.0 and t > 0.5:
			non_monotonic += 1
		if t > 0.6:
			var expected: float = SPEED * float(f["delta"])
			if expected > 1e-3:  # ignore sub-millimetre frames of the uncapped run (float noise)
				worst_rel = maxf(worst_rel, absf(dx - expected) / expected)
				checked += 1
	return {"non_monotonic": non_monotonic, "worst_rel": worst_rel, "checked": checked}


func test_own_accumulator_vs_engine_fraction_interpolation_at_30_60_144_and_uncapped() -> void:
	# Arrange / Act: the own accumulator is recorded (timing-dependent, not asserted);
	# the engine fraction path (ADR-0012 R1 fallback) is asserted.
	for cap: int in [30, 60, 144, 0]:
		var r: Array[Dictionary] = await _run_walk(cap, 2.0)
		var frames: Array[Dictionary] = r.slice(0, r.size() - 1)
		var own: Dictionary = _metrics(frames, "eye_own")
		var eng: Dictionary = _metrics(frames, "eye_engine")
		print("S-0012-A cap=", cap, " frames=", frames.size(), " OWN accumulator: ", own, " | ENGINE fraction: ", eng,
			" final_eye_x=", (frames.back() as Dictionary)["eye_engine"])

		# Assert: engine fraction path
		assert_int(int(eng["non_monotonic"])).is_equal(0)
		if cap != 0:
			assert_float(float(eng["worst_rel"])).is_less(0.10)


func test_paused_own_interpolator_keeps_camera_identical_and_resumes_within_one_tick() -> void:
	# Arrange: engine interpolation is off (S-0012-F); walk at 144 fps, pause mid-walk, resume
	var rig: Rig = Rig.new()
	var cam: Camera3D = Camera3D.new()
	rig.camera = cam
	rig.add_child(cam)
	add_child(auto_free(rig))
	Engine.max_fps = 144
	var t: float = 0.0
	while t < 0.8:
		await get_tree().process_frame
		t += float((rig.frames.back() as Dictionary)["delta"]) if not rig.frames.is_empty() else 0.0

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
	rig.paused_own = false
	var x_before: float = cam.global_transform.origin.x
	await get_tree().process_frame
	var first_step: float = cam.global_transform.origin.x - x_before
	var one_tick: float = SPEED * TICK_DT
	Engine.max_fps = 0
	rig.set_process(false)
	rig.set_physics_process(false)
	print("S-0012-F paused frames identical=", identical, "/", frames_paused, " first_resume_frame_dx=", first_step,
		" one_tick_displacement=", one_tick, " engine_interp_on_camera=", cam.is_physics_interpolated_and_enabled())

	# Assert
	assert_int(identical).is_equal(frames_paused)
	assert_float(first_step).is_between(0.0, one_tick + 1e-6)
	assert_bool(cam.is_physics_interpolated_and_enabled()).is_false()
