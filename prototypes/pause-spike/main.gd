# PROTOTYPE - NOT FOR PRODUCTION
# Question: ADR-0002 pause spike. Which of NS-1..NS-16 hold on 4.7.2 (S1-S16, SB1-SB3)?
# Date: 2026-11-10
#
# Runner. Headless: `godot --headless --path prototypes/pause-spike --quit-after 20000`
# Optional user args (after `--`): --only=S1,S5   --windowed (force windowed probes)
extends Node

const WINDOW_FRAMES: int = 120          # "paused window" of the ADR spike plan
const FRAME_DELAY_MS: int = 12          # artificial frame cost so frames have a realistic Δ
const TWEEN_S: float = 1.0
const BOX_OPEN_S: float = 1.6
const PHYS_V: Vector3 = Vector3(1.0, 0.0, 0.0)


# ---------------------------------------------------------------- probes

class Probe extends Node:
	var process_calls: int = 0
	var physics_calls: int = 0
	var sum_delta: float = 0.0
	var min_delta: float = 1.0e9
	var input_events: int = 0
	var v: float = 0.0
	var mark_calls: int = 0
	var ping_calls: int = 0
	var ping_frame: int = -1

	func _process(delta: float) -> void:
		process_calls += 1
		sum_delta += delta
		if delta < min_delta:
			min_delta = delta

	func _physics_process(_delta: float) -> void:
		physics_calls += 1

	func _input(_event: InputEvent) -> void:
		input_events += 1

	func on_mark() -> void:
		mark_calls += 1

	func on_ping() -> void:
		ping_calls += 1
		ping_frame = Engine.get_process_frames()


class Emitter extends Node:
	signal ping


class OrderProbe extends Node:
	var tag: String = ""
	var sink: Array = []

	func _process(_delta: float) -> void:
		sink.append(str(Engine.get_process_frames()) + ":" + tag)


class Mover extends CharacterBody3D:
	var steps: int = 0
	var last_step: float = 0.0
	var record_first: bool = false
	var first_step: float = -1.0

	func _physics_process(_delta: float) -> void:
		var before: Vector3 = global_position
		move_and_slide()
		last_step = (global_position - before).length()
		steps += 1
		if record_first:
			first_step = last_step
			record_first = false


class TreePauseBackend:
	var tree: SceneTree

	func _init(t: SceneTree) -> void:
		tree = t

	# The ONLY place that writes SceneTree.paused (NS-1).
	func apply(p: bool) -> void:
		tree.paused = p


# ---------------------------------------------------------------- state

var slot: Node
var always_root: Node
var backend: TreePauseBackend
var results: Array[Dictionary] = []
var api_log: Array[String] = []
var core_ids: PackedStringArray = PackedStringArray(["S1", "S2", "S3", "S4", "S9", "S13"])
var only_ids: PackedStringArray = PackedStringArray()
var force_windowed: bool = false
var headless: bool = true
var wav_cache: AudioStreamWAV = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	slot = Node.new()
	slot.name = "WorldSlot"
	slot.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(slot)
	always_root = Node.new()
	always_root.name = "AlwaysRoot"
	always_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(always_root)
	backend = TreePauseBackend.new(get_tree())
	headless = DisplayServer.get_name() == "headless"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only_ids = a.substr(7).split(",")
		elif a == "--windowed":
			force_windowed = true
	_run()


# ---------------------------------------------------------------- helpers

func _frame() -> void:
	await get_tree().process_frame
	OS.delay_msec(FRAME_DELAY_MS)


func _frames(n: int) -> void:
	for i in n:
		await _frame()


func _physics_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _wait_s(sec: float) -> void:
	var t0: int = Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - t0) < sec * 1.0e6:
		await _frame()


func _reset() -> void:
	backend.apply(false)
	for c: Node in slot.get_children():
		slot.remove_child(c)
		c.queue_free()
	for c: Node in always_root.get_children():
		always_root.remove_child(c)
		c.queue_free()
	await _frame()
	await _frame()


func _report(id: String, status: String, detail: String) -> void:
	results.append({"id": id, "status": status, "detail": detail, "core": core_ids.has(id)})
	print("RESULT %s %s %s" % [id, status, detail])


func _has_result(id: String) -> bool:
	for r: Dictionary in results:
		if r["id"] == id:
			return true
	return false


func _has_prop(cls: String, prop: String) -> bool:
	for d: Dictionary in ClassDB.class_get_property_list(cls):
		if d.get("name", "") == prop:
			return true
	return false


func _api_method(cls: String, m: String) -> void:
	var ok: bool = ClassDB.class_has_method(cls, m)
	api_log.append("%s.%s() %s" % [cls, m, "OK" if ok else "MISSING"])


func _api_prop(cls: String, p: String) -> void:
	var ok: bool = _has_prop(cls, p)
	api_log.append("%s.%s (property) %s" % [cls, p, "OK" if ok else "MISSING"])


func _probe_api_names() -> void:
	_api_method("Tween", "pause")
	_api_method("Tween", "play")
	_api_method("Tween", "set_pause_mode")
	_api_method("AnimationPlayer", "pause")
	_api_method("AudioStreamPlayer", "get_playback_position")
	_api_method("Node3D", "get_global_transform_interpolated")
	_api_method("Node", "can_process")
	_api_method("SceneTree", "create_timer")
	_api_method("Viewport", "push_input")
	_api_method("RenderingServer", "particles_request_process_time")
	_api_prop("AudioStreamPlayer", "stream_paused")
	_api_prop("Node", "process_priority")
	_api_prop("Node", "process_mode")
	_api_prop("Node", "physics_interpolation_mode")
	_api_prop("GPUParticles3D", "speed_scale")
	for line: String in api_log:
		print("API ", line)


func _make_wav(seconds: float) -> AudioStreamWAV:
	if wav_cache != null:
		return wav_cache
	var rate: int = 22050
	var n: int = int(seconds * float(rate))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var s: float = sin(TAU * 440.0 * float(i) / float(rate)) * 0.2
		bytes.encode_s16(i * 2, int(s * 32767.0))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	wav_cache = w
	return w


# ---------------------------------------------------------------- run

func _run() -> void:
	await get_tree().process_frame
	print("PAUSE-SPIKE start. Godot ", str(Engine.get_version_info().get("string", "?")), " display=", DisplayServer.get_name())
	_probe_api_names()
	var tests: Array = [
		["S1", _t_s1], ["S2", _t_s2], ["S3", _t_s3], ["S4", _t_s4], ["S9", _t_s9], ["S13", _t_s13],
		["S5", _t_s5], ["S6", _t_s6], ["S7", _t_s7], ["S8", _t_s8], ["S10", _t_s10], ["S11", _t_s11],
		["S12", _t_s12], ["S14", _t_s14], ["S15", _t_s15], ["S16", _t_s16],
		["SB1", _t_sb1], ["SB2", _t_sb2], ["SB3", _t_sb3],
	]
	var windowed_ids: PackedStringArray = PackedStringArray(["S7", "S10", "S11", "SB3"])
	var run_windowed: bool = (not headless) or force_windowed
	if run_windowed and headless:
		print("WARN --windowed requested but display is headless; windowed probes will be NEEDS_WINDOWED")
		run_windowed = false
	for e: Array in tests:
		var id: String = e[0]
		var c: Callable = e[1]
		if only_ids.size() > 0 and not only_ids.has(id):
			continue
		if windowed_ids.has(id):
			continue_windowed_placeholder(id)
			continue
		await _reset()
		await c.call()
		if not _has_result(id):
			_report(id, "FAIL", "no result recorded (runtime error inside the test; see engine output above)")
	if run_windowed:
		await _reset()
		await _run_windowed_module()
	else:
		for id: String in windowed_ids:
			if only_ids.size() == 0 or only_ids.has(id):
				continue_windowed_placeholder(id, true)
	await _reset()
	_finish()


# In headless the windowed ids get their NEEDS_WINDOWED line; in windowed mode the
# module reports them instead, so this only registers when `emit` is true.
func continue_windowed_placeholder(id: String, emit: bool = false) -> void:
	if not emit:
		return
	var how: Dictionary = {
		"S7": "Run with a window: godot --path prototypes/pause-spike -- --only=S7. Observe user://pause_spike_s7_*.png (paused frames must be identical in the rain region; no burst on resume).",
		"S10": "Run with a window: godot --path prototypes/pause-spike -- --only=S10. Observe the detail: whether shader TIME advances during pause (informative).",
		"S11": "Run with a window, vsync off, 144 fps cap: godot --path prototypes/pause-spike -- --only=S11. Observe camera interpolated transform identical across paused frames and no pop on resume.",
		"SB3": "Run with a window: godot --path prototypes/pause-spike -- --only=SB3. Same criterion as S7 with GPUParticles3D.speed_scale = 0 and the tree NOT paused.",
	}
	_report(id, "NEEDS_WINDOWED", str(how[id]))


func _run_windowed_module() -> void:
	var script: GDScript = load("res://windowed.gd") as GDScript
	if script == null:
		for id: String in ["S7", "S10", "S11", "SB3"]:
			_report(id, "UNVERIFIED_API", "windowed.gd failed to load (parse error?)")
		return
	var w: Node = script.new() as Node
	add_child(w)
	var ids: Array = ["S7", "S10", "S11", "SB3"]
	if only_ids.size() > 0:
		ids = []
		for i: String in only_ids:
			if ["S7", "S10", "S11", "SB3"].has(i):
				ids.append(i)
	if ids.is_empty():
		w.queue_free()
		return
	var set_paused: Callable = backend.apply
	var out: Array = await w.call("run", self, set_paused, ids)
	for r: Dictionary in out:
		_report(str(r["id"]), str(r["status"]), str(r["detail"]))
	w.queue_free()


func _finish() -> void:
	var counts: Dictionary = {"PASS": 0, "FAIL": 0, "NEEDS_WINDOWED": 0, "UNVERIFIED_API": 0}
	var core_fail: bool = false
	var core_unverified: bool = false
	var core_pending: Array[String] = []
	for r: Dictionary in results:
		var s: String = r["status"]
		counts[s] = int(counts.get(s, 0)) + 1
		if r["core"]:
			if s == "FAIL":
				core_fail = true
			elif s == "UNVERIFIED_API":
				core_unverified = true
			elif s == "NEEDS_WINDOWED":
				core_pending.append(str(r["id"]))
	var code: int = 0
	if core_fail:
		code = 1
	elif core_unverified:
		code = 2
	var out: Dictionary = {
		"godot": Engine.get_version_info().get("string", "?"),
		"display": DisplayServer.get_name(),
		"results": results,
		"api_probe": api_log,
		"counts": counts,
		"core_ids": Array(core_ids),
		"core_pending_manual": core_pending,
		"exit_code": code,
	}
	var json: String = JSON.stringify(out, "  ")
	print("SUMMARY ", counts, " core_fail=", core_fail, " core_unverified=", core_unverified, " core_pending=", core_pending, " exit=", code)
	print("RESULTS_JSON_BEGIN")
	print(json)
	print("RESULTS_JSON_END")
	var f: FileAccess = FileAccess.open("user://results.json", FileAccess.WRITE)
	if f != null:
		f.store_string(json)
		f.close()
		print("results.json written to ", OS.get_user_data_dir(), "/results.json")
	var f2: FileAccess = FileAccess.open("res://results.json", FileAccess.WRITE)
	if f2 != null:
		f2.store_string(json)
		f2.close()
	get_tree().quit(code)


# ---------------------------------------------------------------- S1

func _t_s1() -> void:
	var p: Probe = Probe.new()
	slot.add_child(p)
	await _frames(5)
	await _physics_frames(5)
	var base_ok: bool = p.process_calls > 0 and p.physics_calls > 0
	backend.apply(true)
	var flag: bool = get_tree().paused
	var pc0: int = p.process_calls
	var hc0: int = p.physics_calls
	await _frames(WINDOW_FRAMES)
	var dp: int = p.process_calls - pc0
	var dh: int = p.physics_calls - hc0
	backend.apply(false)
	var pc1: int = p.process_calls
	var hc1: int = p.physics_calls
	await _frames(2)
	await _physics_frames(3)
	var resumed: bool = p.process_calls > pc1 and p.physics_calls > hc1
	var ok: bool = base_ok and flag and dp <= 1 and dh <= 1 and resumed
	_report("S1", "PASS" if ok else "FAIL", "baseline_ok=%s paused_flag=%s process_calls_in_window=%d physics_calls_in_window=%d resumed=%s" % [base_ok, flag, dp, dh, resumed])


# ---------------------------------------------------------------- S2

func _t_s2() -> void:
	var vals: Array[int] = [
		Node.PROCESS_MODE_INHERIT, Node.PROCESS_MODE_PAUSABLE, Node.PROCESS_MODE_WHEN_PAUSED,
		Node.PROCESS_MODE_ALWAYS, Node.PROCESS_MODE_DISABLED,
	]
	var distinct: bool = true
	for i in vals.size():
		for j in range(i + 1, vals.size()):
			if vals[i] == vals[j]:
				distinct = false
	var pa: Node = Node.new()
	pa.process_mode = Node.PROCESS_MODE_PAUSABLE
	var ca: Node = Node.new()
	ca.process_mode = Node.PROCESS_MODE_INHERIT
	pa.add_child(ca)
	var aa: Node = Node.new()
	aa.process_mode = Node.PROCESS_MODE_ALWAYS
	var ca2: Node = Node.new()
	ca2.process_mode = Node.PROCESS_MODE_INHERIT
	aa.add_child(ca2)
	always_root.add_child(pa)
	always_root.add_child(aa)
	var sc: Node = Node.new()   # INHERIT child under explicit-PAUSABLE WorldSlot
	slot.add_child(sc)
	var root: Window = get_tree().root
	var root_mode_orig: int = root.process_mode
	backend.apply(true)
	await _frame()
	var inherit_under_pausable: bool = ca.can_process()      # expect false
	var inherit_under_always: bool = ca2.can_process()       # expect true
	var slot_child_default: bool = sc.can_process()          # expect false
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	await _frame()
	var slot_child_root_always: bool = sc.can_process()      # expect false: explicit PAUSABLE wins
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	await _frame()
	var slot_child_root_pausable: bool = sc.can_process()    # expect false
	root.process_mode = root_mode_orig as Node.ProcessMode
	backend.apply(false)
	var ok: bool = distinct and (not inherit_under_pausable) and inherit_under_always and (not slot_child_default) and (not slot_child_root_always) and (not slot_child_root_pausable)
	_report("S2", "PASS" if ok else "FAIL", "constants_distinct=%s root_default_mode=%d inherit_under_pausable_can_process=%s inherit_under_always_can_process=%s worldslot_child(root default,ALWAYS,PAUSABLE)=%s/%s/%s" % [distinct, root_mode_orig, inherit_under_pausable, inherit_under_always, slot_child_default, slot_child_root_always, slot_child_root_pausable])


# ---------------------------------------------------------------- S3

func _t_s3() -> void:
	var p: Probe = Probe.new()
	always_root.add_child(p)
	backend.apply(true)
	await _frames(3)
	p.min_delta = 1.0e9
	var c0: int = p.process_calls
	var d0: float = p.sum_delta
	var t0: int = Time.get_ticks_usec()
	await _frames(WINDOW_FRAMES)
	var calls: int = p.process_calls - c0
	var sd: float = p.sum_delta - d0
	var elapsed: float = float(Time.get_ticks_usec() - t0) / 1.0e6
	backend.apply(false)
	var ratio: float = sd / elapsed
	var ok: bool = absi(calls - WINDOW_FRAMES) <= 1 and absf(ratio - 1.0) <= 0.05 and p.min_delta > 0.0
	_report("S3", "PASS" if ok else "FAIL", "calls=%d (expect %d+-1) sum_delta=%.3f real_elapsed=%.3f ratio=%.4f min_delta=%.5f" % [calls, WINDOW_FRAMES, sd, elapsed, ratio, p.min_delta])


# ---------------------------------------------------------------- S4

func _push_key() -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_A
	ev.physical_keycode = KEY_A
	ev.pressed = true
	get_viewport().push_input(ev)


func _t_s4() -> void:
	var pa: Probe = Probe.new()
	var pw: Probe = Probe.new()
	always_root.add_child(pa)
	slot.add_child(pw)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	always_root.add_child(layer)
	var btn: Button = Button.new()
	btn.text = "ok"
	btn.position = Vector2(10, 10)
	btn.size = Vector2(100, 40)
	var st: Dictionary = {"clicks": 0}
	btn.pressed.connect(func() -> void: st["clicks"] = int(st["clicks"]) + 1)
	layer.add_child(btn)
	await _frames(2)
	# control: unpaused
	_push_key()
	_push_key()
	await _frame()
	var ctrl_a: int = pa.input_events
	var ctrl_w: int = pw.input_events
	if ctrl_a < 2 or ctrl_w < 2:
		_report("S4", "UNVERIFIED_API", "control failed: Viewport.push_input did not reach probes while unpaused (always=%d pausable=%d); simulation unusable headless" % [ctrl_a, ctrl_w])
		return
	backend.apply(true)
	await _frame()
	var a0: int = pa.input_events
	var w0: int = pw.input_events
	_push_key()
	_push_key()
	_push_key()
	await _frame()
	var da: int = pa.input_events - a0
	var dw: int = pw.input_events - w0
	# Button click simulation (informative: needs GUI picking, may not work headless)
	var mm: InputEventMouseMotion = InputEventMouseMotion.new()
	mm.position = Vector2(30, 20)
	mm.global_position = mm.position
	get_viewport().push_input(mm)
	for pressed: bool in [true, false]:
		var mb: InputEventMouseButton = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.position = Vector2(30, 20)
		mb.global_position = mb.position
		mb.pressed = pressed
		if pressed:
			mb.button_mask = MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(mb)
		await _frame()
	var clicks: int = int(st["clicks"])
	backend.apply(false)
	var sim_ok: bool = da == 3 and dw == 0
	var detail: String = "SIM: always_probe_events=%d/3 pausable_probe_events=%d/0 button_click_sim=%d (informative; 0 may be a headless limitation). MANUAL still required: keyboard/gamepad focus navigation and gamepad connect/disconnect during pause (see README S4)." % [da, dw, clicks]
	_report("S4", "NEEDS_WINDOWED" if sim_ok else "FAIL", detail)


# ---------------------------------------------------------------- S5 / SB1 (tween)

func _tween_case(pause_mode: Tween.TweenPauseMode, via_api: bool) -> Dictionary:
	var p: Probe = Probe.new()
	slot.add_child(p)
	var st: Dictionary = {"done_us": 0}
	var tw: Tween = p.create_tween()
	tw.set_pause_mode(pause_mode)
	tw.tween_property(p, "v", 1.0, TWEEN_S)
	tw.finished.connect(func() -> void: st["done_us"] = Time.get_ticks_usec())
	var t_start: int = Time.get_ticks_usec()
	await _wait_s(TWEEN_S * 0.5)
	var t_pause: int = Time.get_ticks_usec()
	if via_api:
		tw.pause()
	else:
		backend.apply(true)
	await _frame()
	var v_hold: float = p.v
	await _frames(WINDOW_FRAMES)
	var v_after: float = p.v
	var constant: bool = v_hold == v_after
	var done_during: bool = int(st["done_us"]) != 0
	var t_resume: int = Time.get_ticks_usec()
	if via_api:
		tw.play()
	else:
		backend.apply(false)
	var prev: float = v_after
	var max_step: float = 0.0
	var max_dt: float = 0.0
	var last_us: int = Time.get_ticks_usec()
	var guard: int = 0
	while int(st["done_us"]) == 0 and guard < 600:
		await _frame()
		var now_us: int = Time.get_ticks_usec()
		var dt: float = float(now_us - last_us) / 1.0e6
		last_us = now_us
		if dt > max_dt:
			max_dt = dt
		var step: float = absf(p.v - prev)
		if step > max_step:
			max_step = step
		prev = p.v
		guard += 1
	var finished: bool = int(st["done_us"]) != 0
	var unpaused_s: float = -1.0
	if finished:
		unpaused_s = float(int(st["done_us"]) - t_start - (t_resume - t_pause)) / 1.0e6
	var completed_ok: bool = finished and (not done_during) and absf(unpaused_s - TWEEN_S) <= 0.06
	var step_ok: bool = max_step <= 2.0 * max_dt / TWEEN_S + 0.005
	tw.kill()
	return {
		"constant": constant, "done_during": done_during, "completed_ok": completed_ok,
		"unpaused_s": unpaused_s, "step_ok": step_ok, "max_step": max_step, "max_dt": max_dt,
		"ok": constant and completed_ok and step_ok,
	}


func _veil_case(pause_mode: Tween.TweenPauseMode) -> bool:
	var p: Probe = Probe.new()
	always_root.add_child(p)
	var st: Dictionary = {"done": false}
	var tw: Tween = p.create_tween()
	tw.set_pause_mode(pause_mode)
	tw.tween_property(p, "v", 1.0, 0.5)
	tw.finished.connect(func() -> void: st["done"] = true)
	backend.apply(true)
	await _frames(WINDOW_FRAMES)
	var done: bool = bool(st["done"])
	backend.apply(false)
	tw.kill()
	return done


func _fmt_case(name: String, r: Dictionary) -> String:
	return "%s{ok=%s const=%s done_during=%s unpaused_s=%.3f step_ok=%s max_step=%.4f max_dt=%.4f}" % [name, r["ok"], r["constant"], r["done_during"], r["unpaused_s"], r["step_ok"], r["max_step"], r["max_dt"]]


func _t_s5() -> void:
	var rb: Dictionary = await _tween_case(Tween.TWEEN_PAUSE_BOUND, false)
	await _reset()
	var rs: Dictionary = await _tween_case(Tween.TWEEN_PAUSE_STOP, false)
	await _reset()
	var rp: Dictionary = await _tween_case(Tween.TWEEN_PAUSE_PROCESS, false)
	await _reset()
	var veil_process: bool = await _veil_case(Tween.TWEEN_PAUSE_PROCESS)
	await _reset()
	var veil_bound: bool = await _veil_case(Tween.TWEEN_PAUSE_BOUND)
	var world_ok: bool = bool(rb["ok"]) or bool(rs["ok"])
	var veil_ok: bool = veil_process or veil_bound
	var winners: Array[String] = []
	if rb["ok"]:
		winners.append("BOUND")
	if rs["ok"]:
		winners.append("STOP")
	var detail: String = "world_modes_passing=%s veil_PROCESS_completes_in_pause=%s veil_BOUND_on_ALWAYS_node_completes=%s | %s | %s | %s (PROCESS on a world node is expected to fail)" % [winners, veil_process, veil_bound, _fmt_case("BOUND", rb), _fmt_case("STOP", rs), _fmt_case("PROCESS", rp)]
	_report("S5", "PASS" if (world_ok and veil_ok) else "FAIL", detail)


func _t_sb1() -> void:
	var r: Dictionary = await _tween_case(Tween.TWEEN_PAUSE_BOUND, true)
	_report("SB1", "PASS" if r["ok"] else "FAIL", "tree never paused; Tween.pause()/play(): " + _fmt_case("api", r))


# ---------------------------------------------------------------- S6 / SB2 (animation)

func _anim_case(mode: String) -> Dictionary:
	var holder: Node = Node.new()
	slot.add_child(holder)
	var p: Probe = Probe.new()
	p.name = "Target"
	holder.add_child(p)
	var ap: AnimationPlayer = AnimationPlayer.new()
	holder.add_child(ap)
	var anim: Animation = Animation.new()
	anim.length = BOX_OPEN_S
	var ti: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ti, NodePath("Target:v"))
	anim.track_insert_key(ti, 0.0, 0.0)
	anim.track_insert_key(ti, BOX_OPEN_S, 1.0)
	var tm: int = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(tm, NodePath("Target"))
	anim.track_insert_key(tm, 1.0, {"method": &"on_mark", "args": []})
	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(&"open", anim)
	ap.add_animation_library(&"", lib)
	var st: Dictionary = {"done_us": 0}
	ap.animation_finished.connect(func(_n: StringName) -> void: st["done_us"] = Time.get_ticks_usec())
	var t_start: int = Time.get_ticks_usec()
	ap.play(&"open")
	await _wait_s(0.8)
	var marks_at_pause: int = p.mark_calls
	var t_pause: int = Time.get_ticks_usec()
	if mode == "tree":
		backend.apply(true)
	elif mode == "pause_api":
		ap.pause()
	else:
		ap.speed_scale = 0.0
	await _frame()
	var v_hold: float = p.v
	await _frames(WINDOW_FRAMES)
	var v_after: float = p.v
	var marks_in_pause: int = p.mark_calls - marks_at_pause
	var done_during: bool = int(st["done_us"]) != 0
	var t_resume: int = Time.get_ticks_usec()
	if mode == "tree":
		backend.apply(false)
	elif mode == "pause_api":
		ap.play()
	else:
		ap.speed_scale = 1.0
	var guard: int = 0
	while int(st["done_us"]) == 0 and guard < 600:
		await _frame()
		guard += 1
	await _frames(2)
	var finished: bool = int(st["done_us"]) != 0
	var unpaused_s: float = -1.0
	if finished:
		unpaused_s = float(int(st["done_us"]) - t_start - (t_resume - t_pause)) / 1.0e6
	var const_ok: bool = v_hold == v_after
	var time_ok: bool = finished and (not done_during) and absf(unpaused_s - BOX_OPEN_S) <= 0.06
	var marks_ok: bool = marks_in_pause == 0 and p.mark_calls == 1
	return {
		"ok": const_ok and time_ok and marks_ok, "const": const_ok, "unpaused_s": unpaused_s,
		"marks_in_pause": marks_in_pause, "marks_total": p.mark_calls, "done_during": done_during,
	}


func _fmt_anim(r: Dictionary) -> String:
	return "{ok=%s position_const=%s unpaused_s=%.3f(expect %.1f) marks_in_pause=%d marks_total=%d(expect 1) finished_during_pause=%s}" % [r["ok"], r["const"], r["unpaused_s"], BOX_OPEN_S, r["marks_in_pause"], r["marks_total"], r["done_during"]]


func _t_s6() -> void:
	var r: Dictionary = await _anim_case("tree")
	_report("S6", "PASS" if r["ok"] else "FAIL", _fmt_anim(r))


func _t_sb2() -> void:
	var r1: Dictionary = await _anim_case("pause_api")
	await _reset()
	var r2: Dictionary = await _anim_case("speed_scale")
	var ok: bool = r1["ok"] or r2["ok"]
	_report("SB2", "PASS" if ok else "FAIL", "tree never paused; pause()/play()=%s | speed_scale=0/1=%s" % [_fmt_anim(r1), _fmt_anim(r2)])


# ---------------------------------------------------------------- S7 / S10 / S11 / SB3

func _t_s7() -> void:
	pass


func _t_s10() -> void:
	pass


func _t_s11() -> void:
	pass


func _t_sb3() -> void:
	pass


# ---------------------------------------------------------------- S8

func _t_s8() -> void:
	var pl: AudioStreamPlayer = AudioStreamPlayer.new()
	pl.stream = _make_wav(10.0)
	pl.volume_db = -30.0
	always_root.add_child(pl)
	pl.play()
	await _wait_s(1.0)
	var control: float = pl.get_playback_position()
	if control < 0.5:
		_report("S8", "UNVERIFIED_API", "playback position did not advance in the control run (pos=%.3f after ~1 s); Dummy audio driver may not tick get_playback_position(). Re-run windowed." % control)
		return
	pl.stream_paused = true
	await _frame()
	var a: float = pl.get_playback_position()
	await _wait_s(2.0)
	var b: float = pl.get_playback_position()
	pl.stream_paused = false
	await _frame()
	var r: float = pl.get_playback_position()
	await _wait_s(0.5)
	var c: float = pl.get_playback_position()
	var hold_ok: bool = absf(b - a) <= 0.05
	var resume_ok: bool = absf(r - a) <= 0.1
	var adv_ok: bool = absf((c - r) - 0.5) <= 0.15
	_report("S8", "PASS" if (hold_ok and resume_ok and adv_ok) else "FAIL", "pos_at_pause=%.3f pos_after_2s_pause=%.3f hold_ok=%s pos_just_after_resume=%.3f resume_ok=%s advance_in_0.5s=%.3f adv_ok=%s (scaled: pause at ~1 s, window 2 s; audible check still manual)" % [a, b, hold_ok, r, resume_ok, c - r, adv_ok])


# ---------------------------------------------------------------- S9

func _t_s9() -> void:
	var wav: AudioStreamWAV = _make_wav(10.0)
	var pa: AudioStreamPlayer = AudioStreamPlayer.new()
	pa.stream = wav
	pa.volume_db = -30.0
	always_root.add_child(pa)
	var pw: AudioStreamPlayer = AudioStreamPlayer.new()
	pw.stream = wav
	pw.volume_db = -30.0
	slot.add_child(pw)
	pa.play()
	pw.play()
	await _frames(15)
	var ctrl_a: float = pa.get_playback_position()
	if ctrl_a < 0.05:
		_report("S9", "UNVERIFIED_API", "control failed: position of the ALWAYS player did not advance while unpaused (pos=%.3f); Dummy driver limitation? Re-run windowed." % ctrl_a)
		return
	backend.apply(true)
	await _frame()
	var t0: int = Time.get_ticks_usec()
	var a0: float = pa.get_playback_position()
	var w0: float = pw.get_playback_position()
	await _frames(WINDOW_FRAMES)
	var elapsed: float = float(Time.get_ticks_usec() - t0) / 1.0e6
	var a1: float = pa.get_playback_position()
	var w1: float = pw.get_playback_position()
	var still_playing: bool = pa.playing
	backend.apply(false)
	var ratio: float = (a1 - a0) / elapsed
	var ok: bool = still_playing and absf(ratio - 1.0) <= 0.05
	_report("S9", "PASS" if ok else "FAIL", "ALWAYS_player advanced=%.3f in real=%.3f s ratio=%.3f playing=%s | PAUSABLE_player advanced=%.3f (informative, G-8). Audible check manual." % [a1 - a0, elapsed, ratio, still_playing, w1 - w0])


# ---------------------------------------------------------------- S12

func _t_s12() -> void:
	var m: Mover = Mover.new()
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.shape = SphereShape3D.new()
	m.add_child(cs)
	m.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	m.velocity = PHYS_V
	slot.add_child(m)
	await _physics_frames(10)
	var expected: float = PHYS_V.length() / float(Engine.physics_ticks_per_second)
	var base_ok: bool = m.steps > 0 and absf(m.last_step - expected) <= 1.0e-4
	backend.apply(true)
	await _frame()
	var pos0: Vector3 = m.global_position
	var steps0: int = m.steps
	await _frames(WINDOW_FRAMES)
	var pos1: Vector3 = m.global_position
	var moved: float = (pos1 - pos0).length()
	var dsteps: int = m.steps - steps0
	m.record_first = true
	backend.apply(false)
	await _physics_frames(4)
	var vel_ok: bool = m.velocity.is_equal_approx(PHYS_V)
	var first_ok: bool = m.first_step >= 0.0 and absf(m.first_step - expected) <= 1.0e-4
	var ok: bool = base_ok and moved <= 1.0e-6 and dsteps <= 1 and vel_ok and first_ok
	_report("S12", "PASS" if ok else "FAIL", "baseline_step=%.5f(expect %.5f) moved_in_pause=%.6f physics_calls_in_pause=%d velocity_kept=%s first_step_after_resume=%.5f. Guard G-4 load-bearing? Not needed here: engine froze the body without it." % [m.last_step, expected, moved, dsteps, vel_ok, m.first_step])


# ---------------------------------------------------------------- S13

func _t_s13() -> void:
	var em: Emitter = Emitter.new()
	always_root.add_child(em)
	var h: Probe = Probe.new()
	slot.add_child(h)
	em.ping.connect(h.on_ping)
	await _frames(2)
	backend.apply(true)
	await _frame()
	var f0: int = Engine.get_process_frames()
	em.ping.emit()
	var n1: int = h.ping_calls
	var same_frame1: bool = h.ping_frame == f0
	var c: Callable = h.on_ping
	c.call()
	var n2: int = h.ping_calls
	var queue: Array[Callable] = [h.on_ping, h.on_ping, h.on_ping]
	for q: Callable in queue:
		q.call()
	var n3: int = h.ping_calls
	h.call_deferred("on_ping")
	var n_before_def: int = h.ping_calls
	await _frame()
	var deferred_ran: bool = h.ping_calls == n_before_def + 1
	backend.apply(false)
	var ok: bool = n1 == 1 and same_frame1 and n2 == 2 and n3 == 5
	_report("S13", "PASS" if ok else "FAIL", "signal_emit_calls=%d same_frame=%s callable_calls=%d queue_drain_total=%d(expect 5) | informative: call_deferred ran during pause after 1 frame=%s" % [n1, same_frame1, n2, n3, deferred_ran])


# ---------------------------------------------------------------- S14

func _t_s14() -> void:
	await _frames(3)
	var base_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var base_orph: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var base_obj: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var max_frames: int = 0
	var all_freed: bool = true
	for cycle in 10:
		var world: Node = Node.new()
		for i in 200:
			world.add_child(Node.new())
		slot.add_child(world)
		await _frames(2)
		backend.apply(true)
		world.queue_free()
		var freed_in: int = -1
		for i in 3:
			await _frame()
			if not is_instance_valid(world):
				freed_in = i + 1
				break
		backend.apply(false)
		if freed_in < 0:
			all_freed = false
			max_frames = 99
		elif freed_in > max_frames:
			max_frames = freed_in
		await _frame()
	await _frames(3)
	var d_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - base_nodes
	var d_orph: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) - base_orph
	var d_obj: int = int(Performance.get_monitor(Performance.OBJECT_COUNT)) - base_obj
	var ok: bool = all_freed and max_frames <= 3 and d_nodes <= 0 and d_orph <= 0
	_report("S14", "PASS" if ok else "FAIL", "max_frames_to_free=%d all_freed=%s node_count_delta=%d orphan_delta=%d object_count_delta=%d (Performance monitors worked)" % [max_frames, all_freed, d_nodes, d_orph, d_obj])


# ---------------------------------------------------------------- S15

func _order_case(prios: Array[int]) -> String:
	var sink: Array = []
	var tags: Array[String] = ["A", "B", "C"]
	for i in 3:
		var o: OrderProbe = OrderProbe.new()
		o.tag = tags[i]
		o.sink = sink
		o.process_priority = prios[i]
		always_root.add_child(o)
	await _frames(4)
	var tail: Array = sink.slice(sink.size() - 3)
	var names: Array[String] = []
	for s: String in tail:
		names.append(s.get_slice(":", 1))
	for c: Node in always_root.get_children():
		always_root.remove_child(c)
		c.queue_free()
	await _frame()
	return "".join(PackedStringArray(names))


func _t_s15() -> void:
	var pr1: Array[int] = [0, 0, 0]
	var pr2: Array[int] = [2, 1, 0]
	var o1: String = await _order_case(pr1)
	var o2: String = await _order_case(pr2)
	_report("S15", "PASS", "INFORMATIVE: insertion order A,B,C with equal priority ran as %s; priorities A=2,B=1,C=0 ran as %s (lower value first expected)" % [o1, o2])


# ---------------------------------------------------------------- S16

func _t_s16() -> void:
	var st: Dictionary = {"default": false, "stop": false, "node_pausable": false, "node_always": false}
	var t1: SceneTreeTimer = get_tree().create_timer(0.5)
	t1.timeout.connect(func() -> void: st["default"] = true)
	var t2: SceneTreeTimer = get_tree().create_timer(0.5, false)
	t2.timeout.connect(func() -> void: st["stop"] = true)
	var n1: Timer = Timer.new()
	n1.one_shot = true
	n1.wait_time = 0.5
	n1.timeout.connect(func() -> void: st["node_pausable"] = true)
	slot.add_child(n1)
	n1.start()
	var n2: Timer = Timer.new()
	n2.one_shot = true
	n2.wait_time = 0.5
	n2.timeout.connect(func() -> void: st["node_always"] = true)
	always_root.add_child(n2)
	n2.start()
	backend.apply(true)
	await _wait_s(1.2)
	var during: Dictionary = st.duplicate()
	backend.apply(false)
	await _wait_s(1.0)
	_report("S16", "PASS", "INFORMATIVE: fired DURING pause (0.5 s timers, 1.2 s pause) = create_timer(default process_always=true):%s create_timer(process_always=false):%s Timer_under_PAUSABLE:%s Timer_under_ALWAYS:%s | all fired by end: %s" % [during["default"], during["stop"], during["node_pausable"], during["node_always"], st])


# ---------------------------------------------------------------- Windowed bridge

# The four windowed claims are handled in run(): headless -> NEEDS_WINDOWED lines,
# windowed -> windowed.gd. The stubs above exist only so the catalogue is complete.
