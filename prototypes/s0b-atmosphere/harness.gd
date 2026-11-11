# PROTOTYPE - NOT FOR PRODUCTION
extends RefCounted
## S0b dev-only measurement harness (ADR-0019 D5): per-frame CSV + summary.
## Emits numbers only. Verdicts (PASS/FAIL per budget) are written by the person.

const HEADER := "frame,t_ms,frame_time_ms,ticks_dt_ms,time_process_ms,time_physics_ms,draw_calls,objects,primitives,mem_static_mb,video_mem_mb,gpu_ms,render_cpu_ms,cpu28_us,luma,path_ms,flicker_state,light_factor,rain_level,cam_x"

var out_path: String = ""
var vp: Viewport
var vp_rid: RID
var gpu_api_ok: bool = false
var log_lines: PackedStringArray = PackedStringArray()

var _file: FileAccess
var _t0_usec: int = -1
var _last_usec: int = -1
var _s_frame := PackedFloat64Array()
var _s_proc := PackedFloat64Array()
var _s_phys := PackedFloat64Array()
var _s_gpu := PackedFloat64Array()
var _s_cpu28 := PackedFloat64Array()
var _s_draw := PackedFloat64Array()
var _s_mem := PackedFloat64Array()
var gpu_nonzero: int = 0


func log_line(s: String) -> void:
	print(s)
	log_lines.append(s)


func setup(viewport: Viewport, out: String, csv: bool) -> void:
	vp = viewport
	vp_rid = viewport.get_viewport_rid()
	out_path = out
	# NS-P2: do not assume the GPU timing API works; check first and say so.
	var all_ok := true
	for m in ["viewport_set_measure_render_time", "viewport_get_measured_render_time_gpu", "viewport_get_measured_render_time_cpu"]:
		var ok := ClassDB.class_has_method("RenderingServer", m)
		all_ok = all_ok and ok
		log_line("API RenderingServer.%s %s" % [m, "OK" if ok else "MISSING"])
	gpu_api_ok = all_ok
	if gpu_api_ok:
		RenderingServer.call("viewport_set_measure_render_time", vp_rid, true)
	log_line("backend: adapter=%s vendor=%s driver=%s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_current_rendering_driver_name()])
	log_line("engine: %s debug_build=%s editor=%s" % [
		Engine.get_version_info()["string"], OS.is_debug_build(), OS.has_feature("editor")])
	if csv:
		var dir := out_path.get_base_dir()
		if dir != "" and not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		_file = FileAccess.open(out_path, FileAccess.WRITE)
		if _file == null:
			log_line("ERROR cannot open CSV %s (err %d)" % [out_path, FileAccess.get_open_error()])
		else:
			_file.store_line(HEADER)
			log_line("csv: %s" % ProjectSettings.globalize_path(out_path))


## Mean relative luminance of the last rendered frame, downscaled to 32x18 (AC-28-21 input).
func luma_sample() -> float:
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return NAN
	img.resize(32, 18, Image.INTERPOLATE_BILINEAR)
	var sum := 0.0
	for y in 18:
		for x in 32:
			var c := img.get_pixel(x, y).srgb_to_linear()
			sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
	return sum / 576.0


## info keys: luma (float, NAN = not sampled), cpu28_us, path_ms, state, factor, rain, cam_x
func record(frame: int, delta: float, info: Dictionary) -> void:
	var now := Time.get_ticks_usec()
	if _t0_usec < 0:
		_t0_usec = now
		_last_usec = now
	var ticks_dt := float(now - _last_usec) / 1000.0
	_last_usec = now
	var ft := delta * 1000.0
	var proc := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objs := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var prims := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var vmem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var gpu_s := "NA"
	var rcpu_s := "NA"
	if gpu_api_ok:
		var g: float = RenderingServer.call("viewport_get_measured_render_time_gpu", vp_rid)
		var c: float = RenderingServer.call("viewport_get_measured_render_time_cpu", vp_rid)
		gpu_s = "%.4f" % g
		rcpu_s = "%.4f" % c
		_s_gpu.append(g)
		if g > 0.0:
			gpu_nonzero += 1
	var cpu28: float = float(info.get("cpu28_us", 0))
	var luma: float = info.get("luma", NAN)
	var luma_s := "NA" if is_nan(luma) else "%.5f" % luma
	_s_frame.append(ft)
	_s_proc.append(proc)
	_s_phys.append(phys)
	_s_cpu28.append(cpu28)
	_s_draw.append(draws)
	_s_mem.append(mem)
	if _file != null:
		_file.store_line("%d,%.3f,%.4f,%.4f,%.4f,%.4f,%d,%d,%d,%.2f,%.2f,%s,%s,%d,%s,%d,%s,%.4f,%.4f,%.3f" % [
			frame, float(now - _t0_usec) / 1000.0, ft, ticks_dt, proc, phys, int(draws), int(objs), int(prims),
			mem, vmem, gpu_s, rcpu_s, int(cpu28), luma_s, int(info.get("path_ms", 0)),
			str(info.get("state", "")), float(info.get("factor", 1.0)), float(info.get("rain", 1.0)),
			float(info.get("cam_x", 0.0))])


func finish() -> void:
	if _file != null:
		_file.close()
		_file = null
	log_line("---- SUMMARY (%d frames) ----" % _s_frame.size())
	_series("frame_time_ms", _s_frame)
	_series("time_process_ms", _s_proc)
	_series("time_physics_ms", _s_phys)
	if gpu_api_ok:
		_series("gpu_ms(API)", _s_gpu)
		log_line("gpu_ms nonzero frames: %d of %d (%s)" % [gpu_nonzero, _s_gpu.size(),
			"usable" if gpu_nonzero > 0 else "ALL ZERO: NS-P2 not usable here"])
	else:
		log_line("gpu_ms: NA (API MISSING)")
	_series("cpu28_us", _s_cpu28)
	_series("draw_calls", _s_draw)
	_series("mem_static_mb", _s_mem)
	var over166 := 0
	var over50 := 0
	for v in _s_frame:
		if v > 16.6:
			over166 += 1
		if v > 50.0:
			over50 += 1
	var n := maxi(_s_frame.size(), 1)
	log_line("frames > 16.6 ms: %d (%.2f %%)   frames > 50 ms: %d" % [over166, 100.0 * over166 / n, over50])
	log_line("final backend: adapter=%s driver=%s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_driver_name()])
	if out_path != "":
		var f := FileAccess.open(out_path + ".summary.txt", FileAccess.WRITE)
		if f != null:
			for l in log_lines:
				f.store_line(l)
			f.close()


func _series(nm: String, a: PackedFloat64Array) -> void:
	if a.is_empty():
		return
	var s := a.duplicate()
	s.sort()
	var sum := 0.0
	for v in a:
		sum += v
	log_line("%-16s mean=%.4f p50=%.4f p95=%.4f p99=%.4f max=%.4f" % [
		nm, sum / a.size(), _pct(s, 0.50), _pct(s, 0.95), _pct(s, 0.99), s[s.size() - 1]])


func _pct(sorted: PackedFloat64Array, p: float) -> float:
	var i := clampi(int(ceil(p * sorted.size())) - 1, 0, sorted.size() - 1)
	return sorted[i]
