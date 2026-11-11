extends GdUnitTestSuite
# ADR-0012 NP-1..NP-3, parte sensible a la carga (tasa de ticks por fotograma, desviaciones por fotograma,
# monotonicidad de la fraccion del motor, primer paso tras reanudar). Dependen del tiempo real de pared y de
# Engine.max_fps: bajo carga de CPU fallan sin que haya un defecto. Por eso viven en tests/timing/, que la CI
# bloqueante ignora (-i res://tests/timing) y se ejecutan en un paso aparte con continue-on-error.
# Los asertos deterministas (orden de pasos de fisica frente a _process, estructura) estan en
# tests/unit/engine_facts/adr0012_tick_interpolation_test.gd.

const SPEED: float = 1.6
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
	var frames: Array[Dictionary] = []
	var camera: Camera3D

	func _physics_process(_delta: float) -> void:
		if paused_own:
			return
		ticks_this_frame += 1
		var target: float = speed if held else 0.0
		vel = move_toward(vel, target, speed / accel_s * tick_dt)
		prev_x = curr_x
		curr_x += vel * tick_dt

	func _process(delta: float) -> void:
		if not paused_own:
			acc += delta
			acc -= tick_dt * float(ticks_this_frame)
			acc = maxf(acc, 0.0)
		var alpha: float = clampf(acc / tick_dt, 0.0, 1.0)
		var eye_own: float = lerpf(prev_x, curr_x, alpha)
		var frac: float = Engine.get_physics_interpolation_fraction()
		if camera != null:
			camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(eye_own, 1.6, 0.0))
		frames.append({
			"delta": delta, "ticks": ticks_this_frame, "alpha": alpha, "eye_own": eye_own,
			"eye_engine": lerpf(prev_x, curr_x, frac),
		})
		ticks_this_frame = 0


func after_test() -> void:
	# Un fallo a mitad de test no debe dejar el tope de fps puesto para el resto de la suite.
	Engine.max_fps = 0


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
	return rig.frames.duplicate()


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


func test_tick_rate_per_frame_is_2_at_30_fps_and_0_or_1_at_144_fps() -> void:
	# Arrange / Act
	var hists: Dictionary = {}
	for cap: int in [30, 60, 144]:
		var frames: Array[Dictionary] = await _run_walk(cap, 1.5)
		var tick_hist: Dictionary = {}
		for f: Dictionary in frames:
			var n: int = int(f["ticks"])
			tick_hist[n] = int(tick_hist.get(n, 0)) + 1
		hists[cap] = tick_hist
		print("S-0012-A cap=", cap, " frames=", frames.size(), " ticks/frame histogram=", tick_hist)

	# Assert
	assert_bool((hists[30] as Dictionary).has(2)).is_true()
	assert_bool((hists[144] as Dictionary).has(0)).is_true()
	assert_bool((hists[144] as Dictionary).has(2) or (hists[144] as Dictionary).has(3)).is_false()


func test_engine_fraction_interpolation_is_monotonic_and_within_10_percent_at_30_60_144_and_uncapped() -> void:
	# Arrange / Act: the own accumulator is only recorded; the engine fraction path (ADR-0012 R1 fallback) is asserted.
	for cap: int in [30, 60, 144, 0]:
		var frames: Array[Dictionary] = await _run_walk(cap, 2.0)
		var own: Dictionary = _metrics(frames, "eye_own")
		var eng: Dictionary = _metrics(frames, "eye_engine")
		print("S-0012-A cap=", cap, " frames=", frames.size(), " OWN accumulator: ", own, " | ENGINE fraction: ", eng)

		# Assert
		assert_int(int(eng["non_monotonic"])).is_equal(0)
		if cap != 0:
			assert_float(float(eng["worst_rel"])).is_less(0.10)


func test_resume_after_pause_moves_at_most_one_tick_at_144_fps() -> void:
	# Arrange
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
	rig.paused_own = true
	for i: int in 5:
		await get_tree().process_frame

	# Act
	rig.paused_own = false
	var x_before: float = cam.global_transform.origin.x
	await get_tree().process_frame
	var first_step: float = cam.global_transform.origin.x - x_before
	rig.set_process(false)
	rig.set_physics_process(false)
	print("S-0012-F first_resume_frame_dx=", first_step, " one_tick_displacement=", SPEED * TICK_DT)

	# Assert
	assert_float(first_step).is_between(0.0, SPEED * TICK_DT + 1e-6)
