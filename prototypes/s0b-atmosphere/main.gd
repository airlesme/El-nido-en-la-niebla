# PROTOTYPE - NOT FOR PRODUCTION
extends Node3D
## S0b atmosphere test: scripted 30 s walk X 3 -> 23 in the grey corridor + measurement harness.
## Hidden controls (after `--`): --perf-run --out= --vsync= --scale= --scale-mode=bilinear|fsr
##   --rain= --rain-mode=ratio|emit --shadows= --glow= --lights-n= --c28= --no-reflection
##   --frames=N --warmup=N --luma-every=N --clock=real|frame --blackout=0|1
##   --shot=<png> --shot-at=<ms>      (P toggles pause, Esc quits)

const WorldBuilder := preload("res://world_builder.gd")
const Harness := preload("res://harness.gd")
const LightAudit := preload("res://light_audit.gd")
const AtmosphereScript := preload("res://atmosphere.gd")

const PATH_MS := 30000
const STOPS_MS: Array[int] = [0, 6000, 12000, 18000, 24000, 30000]   # X = 3, 7, 11, 15, 19, 23

var path_ms: int = 0

var _args: Dictionary = {}
var _perf_run: bool = false
var _warmup: int = 120
var _rec_frames: int = 1800
var _luma_every: int = 0
var _clock_mode: String = "real"
var _frame_idx: int = 0
var _clock_frames: int = 0
var _real_ms: int = 0
var _last_ticks: int = 0
var _last_path_ms: int = 0
var _audited: Array[bool] = [false, false, false, false, false, false]
var _shot_path: String = ""
var _shot_at: int = 0
var _shot_done: bool = false
var _camera: Camera3D
var _atm: AtmosphereScript
var _harness: Harness
var _c28: bool = true
var _done: bool = false


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var s: String = a.lstrip("-")
		var kv := s.split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"


func _arg_i(key: String, default: int) -> int:
	return int(_args[key]) if _args.has(key) else default


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_args()
	var gate := OS.has_feature("profiling") or OS.is_debug_build()
	_perf_run = _args.has("perf-run") and gate
	_warmup = _arg_i("warmup", 120)
	_rec_frames = _arg_i("frames", 1800)
	_luma_every = _arg_i("luma-every", 0)
	_clock_mode = str(_args.get("clock", "frame" if _perf_run else "real"))
	_c28 = _arg_i("c28", 1) == 1
	_shot_path = str(_args.get("shot", ""))
	_shot_at = _arg_i("shot-at", 15000)

	if _arg_i("vsync", 1) == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	var scale: float = float(_args.get("scale", "1.0"))
	if scale < 1.0:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if _args.get("scale-mode", "bilinear") == "fsr" else Viewport.SCALING_3D_MODE_BILINEAR
		get_viewport().scaling_3d_scale = scale

	var opts := {
		"lights_n": _arg_i("lights-n", 6),
		"shadows": clampi(_arg_i("shadows", 2), 0, 2),
		"rain": _arg_i("rain", 1) == 1,
		"glow": _arg_i("glow", 1) == 1,
		"reflection": not _args.has("no-reflection"),
		"rain_mode": str(_args.get("rain-mode", "ratio")),
		"blackout": _arg_i("blackout", 1) == 1,
	}
	var built := WorldBuilder.build(self, opts)
	_camera = built["camera"]
	_atm = built["atm"]
	_atm.main = self
	if not _c28:
		_atm.visible = false
		_atm.process_mode = Node.PROCESS_MODE_DISABLED

	_harness = Harness.new()
	var out := str(_args.get("out", "user://s0b-perf.csv"))
	_harness.setup(get_viewport(), out, _perf_run)
	_harness.log_line("options: %s perf_run=%s clock=%s c28=%s" % [str(_args), _perf_run, _clock_mode, _c28])
	_harness.log_line("window=%s scale=%.2f vsync=%s max_fps=%d" % [
		str(DisplayServer.window_get_size()), get_viewport().scaling_3d_scale,
		str(DisplayServer.window_get_vsync_mode()), Engine.max_fps])
	_harness.log_line("lights=%d shadows=%d rain=%s glow=%s tonemap=AgX exposure=fixed SDR" % [
		opts["lights_n"], opts["shadows"], opts["rain"], opts["glow"]])
	_last_ticks = Time.get_ticks_msec()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			get_tree().paused = not get_tree().paused
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit(0)


func _process(delta: float) -> void:
	if _done:
		return
	var ticks := Time.get_ticks_msec()
	var paused := get_tree().paused
	if not paused:
		_real_ms += ticks - _last_ticks
	_last_ticks = ticks

	# own integer-ms clock (frame mode: 1 frame = 1000/60 ms; real mode: sum of tick differences)
	var warming := _perf_run and _frame_idx < _warmup
	var clock_ms: int
	if _clock_mode == "frame":
		if not paused and not warming:
			_clock_frames += 1
		@warning_ignore("integer_division")
		clock_ms = (_clock_frames * 1000) / 60
	else:
		clock_ms = 0 if warming else _real_ms
	path_ms = clock_ms if _perf_run else clock_ms % PATH_MS
	if path_ms < _last_path_ms:
		_audited = [false, false, false, false, false, false]
		_shot_done = false
	_last_path_ms = path_ms

	var rec := _frame_idx - _warmup
	if _perf_run and rec >= _rec_frames:
		_finish()
		return

	_update_camera()
	_audit_stops()

	if _shot_path != "" and not _shot_done and path_ms >= _shot_at:
		_shot_done = true
		get_viewport().get_texture().get_image().save_png(_shot_path)
		_harness.log_line("shot saved: %s (path_ms=%d)" % [_shot_path, path_ms])

	if _perf_run and rec >= 0:
		var luma := NAN
		if _luma_every > 0 and rec % _luma_every == 0:
			luma = _harness.luma_sample()
		_harness.record(rec, delta, {
			"luma": luma, "cpu28_us": _atm.cpu_us, "path_ms": path_ms, "state": _atm.state,
			"factor": _atm.light_factor, "rain": _atm.rain_level, "cam_x": _camera.position.x})
	_frame_idx += 1


func _update_camera() -> void:
	var x := 3.0 + 20.0 * float(path_ms) / PATH_MS
	var w := smoothstep(11.0, 13.0, x) * (1.0 - smoothstep(19.0, 21.0, x))   # glance at the window
	_camera.position = Vector3(x, 1.6, 0.0)
	_camera.rotation_degrees = Vector3(0.0, lerpf(-90.0, -65.0, w), 0.0)


func _audit_stops() -> void:
	for k in STOPS_MS.size():
		if not _audited[k] and path_ms >= STOPS_MS[k]:
			_audited[k] = true
			_harness.log_line(LightAudit.run(get_tree(), _camera, "stop %d X=%.1f t=%d ms" % [k, _camera.position.x, path_ms]))


func _finish() -> void:
	_done = true
	_harness.finish()
	get_tree().quit(0)
