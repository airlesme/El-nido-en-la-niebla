# PROTOTYPE - NOT FOR PRODUCTION
# Question: ADR-0002 S7, S10, S11, SB3 (need a real renderer). Loaded by main.gd only with a window.
# Date: 2026-11-10
extends Node

const WIN_FRAMES: int = 120
const REGION_HALF: int = 100


class Rig extends CharacterBody3D:
	func _physics_process(_delta: float) -> void:
		move_and_slide()


var slot: Node
var set_paused: Callable


func _frame() -> void:
	await get_tree().process_frame


func _frames(n: int) -> void:
	for i in n:
		await _frame()


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _region_diff(a: Image, b: Image) -> int:
	var cx: int = a.get_width() >> 1
	var cy: int = a.get_height() >> 1
	var r: Rect2i = Rect2i(cx - REGION_HALF, cy - REGION_HALF, REGION_HALF * 2, REGION_HALF * 2)
	var da: PackedByteArray = a.get_region(r).get_data()
	var db: PackedByteArray = b.get_region(r).get_data()
	var n: int = mini(da.size(), db.size())
	var diff: int = 0
	for i in n:
		if da[i] != db[i]:
			diff += 1
	return diff


func run(parent: Node, pause_cb: Callable, ids: Array) -> Array:
	slot = parent.get_node("WorldSlot")
	set_paused = pause_cb
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var out: Array = []
	for id: String in ids:
		var r: Dictionary = {"id": id, "status": "UNVERIFIED_API", "detail": "not a windowed claim"}
		if id == "S7":
			r = await _particles("S7", false)
		elif id == "SB3":
			r = await _particles("SB3", true)
		elif id == "S10":
			r = await _shader_time()
		elif id == "S11":
			r = await _interp()
		out.append(r)
	return out


func _clear() -> void:
	set_paused.call(false)
	for c: Node in slot.get_children():
		slot.remove_child(c)
		c.queue_free()
	await _frame()


func _particles(id: String, via_speed_scale: bool) -> Dictionary:
	await _clear()
	var cam: Camera3D = Camera3D.new()
	cam.position = Vector3(0, 0, 4)
	slot.add_child(cam)
	cam.current = true
	var pm: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.0, 0.1, 0.1)
	pm.direction = Vector3(0, -1, 0)
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, -2, 0)
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.2, 0.2)
	mesh.material = mat
	var ps: GPUParticles3D = GPUParticles3D.new()
	ps.amount = 300
	ps.lifetime = 2.0
	ps.preprocess = 2.0
	ps.process_material = pm
	ps.draw_pass_1 = mesh
	ps.position = Vector3(0, 0.5, 0)
	slot.add_child(ps)
	ps.emitting = true
	await _frames(40)
	if via_speed_scale:
		ps.speed_scale = 0.0
	else:
		set_paused.call(true)
	await _frame()
	var img0: Image = await _grab()
	await _frames(59)
	var img60: Image = await _grab()
	await _frames(59)
	var img120: Image = await _grab()
	var d60: int = _region_diff(img0, img60)
	var d120: int = _region_diff(img0, img120)
	var tag: String = id.to_lower()
	img0.save_png("user://pause_spike_%s_paused_000.png" % tag)
	img60.save_png("user://pause_spike_%s_paused_060.png" % tag)
	img120.save_png("user://pause_spike_%s_paused_120.png" % tag)
	if via_speed_scale:
		ps.speed_scale = 1.0
	else:
		set_paused.call(false)
	var prev: Image = img120
	var max_resume_diff: int = 0
	for i in 10:
		await _frame()
		var im: Image = await _grab()
		max_resume_diff = maxi(max_resume_diff, _region_diff(prev, im))
		im.save_png("user://pause_spike_%s_resume_%02d.png" % [tag, i])
		prev = im
	var total: int = REGION_HALF * REGION_HALF * 4 * 4
	var ok: bool = d60 == 0 and d120 == 0
	await _clear()
	return {
		"id": id, "status": "PASS" if ok else "FAIL",
		"detail": "bytes differing in centre region (of %d) paused f+1 vs f+60=%d vs f+120=%d; max consecutive-frame diff after resume=%d. Pixel part only: REVIEW user://pause_spike_%s_*.png by eye for a burst/density jump on resume (path: %s)" % [total, d60, d120, max_resume_diff, tag, OS.get_user_data_dir()],
	}


func _shader_time() -> Dictionary:
	await _clear()
	var cam: Camera3D = Camera3D.new()
	cam.position = Vector3(0, 0, 2)
	slot.add_child(cam)
	cam.current = true
	var sh: Shader = Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { ALBEDO = vec3(fract(TIME * 0.5)); }\n"
	var sm: ShaderMaterial = ShaderMaterial.new()
	sm.shader = sh
	var q: MeshInstance3D = MeshInstance3D.new()
	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(3, 3)
	q.mesh = qm
	q.material_override = sm
	slot.add_child(q)
	await _frames(10)
	set_paused.call(true)
	await _frames(2)
	var a: Image = await _grab()
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1000:
		await _frame()
	var b: Image = await _grab()
	var pa: Color = a.get_pixel(a.get_width() >> 1, a.get_height() >> 1)
	var pb: Color = b.get_pixel(b.get_width() >> 1, b.get_height() >> 1)
	var advanced: bool = absf(pa.r - pb.r) > 0.01
	await _clear()
	return {"id": "S10", "status": "PASS", "detail": "INFORMATIVE: shader TIME advances during tree pause = %s (centre pixel r %.3f -> %.3f over 1 s paused)" % [advanced, pa.r, pb.r]}


func _interp() -> Dictionary:
	await _clear()
	if not ClassDB.class_has_method("Node3D", "get_global_transform_interpolated"):
		return {"id": "S11", "status": "UNVERIFIED_API", "detail": "Node3D.get_global_transform_interpolated() missing in this build; capture frames by eye per README"}
	Engine.max_fps = 144
	var rig: Rig = Rig.new()
	rig.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	rig.velocity = Vector3(3, 0, 0)
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.shape = SphereShape3D.new()
	rig.add_child(cs)
	var cam: Camera3D = Camera3D.new()
	cam.position = Vector3(0, 0, 3)
	rig.add_child(cam)
	slot.add_child(rig)
	cam.current = true
	await _frames(60)
	set_paused.call(true)
	await _frame()
	var held: Vector3 = (cam.call("get_global_transform_interpolated") as Transform3D).origin
	var identical: bool = true
	for i in WIN_FRAMES:
		await _frame()
		var o: Vector3 = (cam.call("get_global_transform_interpolated") as Transform3D).origin
		if not o.is_equal_approx(held):
			identical = false
	set_paused.call(false)
	var step: float = rig.velocity.length() / float(Engine.physics_ticks_per_second)
	var max_jump: float = 0.0
	var prev: Vector3 = held
	for i in 10:
		await _frame()
		var o2: Vector3 = (cam.call("get_global_transform_interpolated") as Transform3D).origin
		max_jump = maxf(max_jump, (o2 - prev).length())
		prev = o2
	Engine.max_fps = 0
	var ok: bool = identical and max_jump <= step * 1.5
	await _clear()
	return {"id": "S11", "status": "PASS" if ok else "FAIL", "detail": "NUMERIC part only: camera interpolated origin identical across %d paused frames=%s; max displacement between rendered frames after resume=%.4f (one physics step=%.4f). Visual pop still needs eye review with a frame capture." % [WIN_FRAMES, identical, max_jump, step]}
