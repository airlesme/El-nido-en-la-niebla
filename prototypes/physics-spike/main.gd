# PROTOTYPE - NOT FOR PRODUCTION
# Windowed measurements for ADR-0011 S-0011-C and ADR-0012 S-0012-A/B.
# Usage: godot --path . -- [--fps=N] [--seconds=S]
# Prints: window size, logical viewport size, rendered height in px of a 0.10 m quad at 0.35 m
# (vertical fov 70), and a walk log (ticks per frame, eye X deltas) with engine fraction.
extends Node

const FOV: float = 70.0
const SPEED: float = 1.6

var _cam: Camera3D
var _quad: MeshInstance3D
var _frames: int = 0
var _prev: float = 0.0
var _curr: float = 0.0
var _ticks: int = 0
var _log: Array[String] = []
var _walk_seconds: float = 3.0
var _t: float = 0.0
var _last_eye: float = 0.0
var _measured: bool = false


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--fps="):
			Engine.max_fps = int(a.substr(6))
		if a.begins_with("--seconds="):
			_walk_seconds = float(a.substr(10))
	_cam = Camera3D.new()
	_cam.fov = FOV
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(_cam)
	_quad = MeshInstance3D.new()
	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.10, 0.10)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0, 1)
	qm.material = mat
	_quad.mesh = qm
	_quad.position = Vector3(0, 0, -0.35)
	add_child(_quad)
	print("window=", DisplayServer.window_get_size(), " logical viewport=", get_viewport().get_visible_rect().size,
		" physics tps=", Engine.physics_ticks_per_second, " max_fps=", Engine.max_fps)


func _physics_process(_d: float) -> void:
	_ticks += 1
	_prev = _curr
	_curr += SPEED / 60.0


func _process(delta: float) -> void:
	_frames += 1
	_t += delta
	var eye: float = lerpf(_prev, _curr, Engine.get_physics_interpolation_fraction())
	_log.append("%d ticks=%d dx=%.5f dt=%.5f" % [_frames, _ticks, eye - _last_eye, delta])
	_last_eye = eye
	_ticks = 0
	if _frames == 5 and not _measured:
		_measured = true
		var img: Image = get_viewport().get_texture().get_image()
		var top: int = -1
		var bottom: int = -1
		for y: int in img.get_height():
			var c: Color = img.get_pixel(img.get_width() / 2, y)
			if c.r > 0.9 and c.g < 0.1 and c.b > 0.9:
				if top < 0:
					top = y
				bottom = y
		print("rendered quad height px=", bottom - top + 1, " image=", img.get_size(), " expected(logical)=",
			float(get_viewport().get_visible_rect().size.y) * 0.10 / (2.0 * 0.35 * tan(deg_to_rad(FOV) * 0.5)))
	if _t >= _walk_seconds:
		for l: String in _log:
			print(l)
		get_tree().quit()
