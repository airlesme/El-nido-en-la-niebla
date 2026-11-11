# PROTOTYPE - NOT FOR PRODUCTION
extends Node3D
## "System 28" subtree for the S0b corridor. Only node with _process (ADR-0014 D1).
## Every light change is an envelope evaluated on an own integer-ms clock (main.path_ms):
## no Tween, no SceneTreeTimer, no engine delta (ADR-0014 D3, ADR-0002 G-1).
## Values are the ones WRITTEN in GDD 28 (R8, R9, R12, R20). The user decision on
## 1.15 s / 0.8 s with reducir_sobresaltos is NOT taken: no reduced variants here.

const FLICKER_ONSET_MS := 10000
const FLICKER_COUNT := 3
const DIP_FALL_MS := 50
const DIP_REC_MS := 100
const DIP_PERIOD_MS := 500          # 150 ms dip + 350 ms pause
const F_PARPADEO := 0.40
const BLACKOUT_AT_MS := 22000
const D_APAGON_MS := 400
const F_APAGON := 0.0
const RESTORE_AT_MS := 25000
const D_RESTAURAR_MS := 2000
const AMBIENT_FLOOR := 0.06
const LLUVIA_APAGON := 0.0
const D_LLUVIA_APAGON_MS := 400
const D_LLUVIA_VUELVE_MS := 2000
const REFLECT_ON_MS := 16500        # X = 14 (T-PAS-2)
const REFLECT_DUR_MS := 3000
const TAU_S := 0.6
const TAU_RAMP_MS := 500
const GLASS_Z := -1.3
const FIXTURE_EMISSION := 3.0
const HIST := 512

var main: Node
var camera: Camera3D
var env: Environment
var ambient_nom: float = 0.9
var lights: Array[Light3D] = []
var fixture_mats: Array[StandardMaterial3D] = []
var nominal: PackedFloat32Array = PackedFloat32Array()
var rain: GPUParticles3D
var rain_mode: String = "ratio"
var ghost: MeshInstance3D
var blackout_enabled: bool = true

var cpu_us: int = 0
var state: String = "NORMAL"
var light_factor: float = 1.0
var rain_level: float = 1.0

var _flicker_t0: int = -1
var _lvl := [1.0, 1.0, -1, 1, false]    # a, b, t0, dur, linear
var _rain := [1.0, 1.0, -1, 1]          # a, b, t0, dur
var _last_ms: int = -1
var _last_total: float = -1.0
var _last_level: float = -1.0
var _last_rain: float = -1.0
var _h_ms := PackedInt32Array()
var _h_pos := PackedVector3Array()
var _h_yaw := PackedFloat32Array()
var _h_head: int = 0


func _ready() -> void:
	_h_ms.resize(HIST)
	_h_pos.resize(HIST)
	_h_yaw.resize(HIST)
	_h_ms.fill(-1)


func reset() -> void:
	_flicker_t0 = -1
	_lvl = [1.0, 1.0, -1, 1, false]
	_rain = [1.0, 1.0, -1, 1]
	_last_ms = -1
	_last_total = -1.0
	_last_level = -1.0
	_last_rain = -1.0
	_h_ms.fill(-1)
	_h_head = 0
	state = "NORMAL"


func _process(_delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	var now: int = main.path_ms
	if now < _last_ms:
		reset()
	_fire_orders(_last_ms, now)
	_last_ms = now

	var level := _env_val(_lvl[0], _lvl[1], _lvl[2], _lvl[3], _lvl[4], now)
	var total := _flicker_factor(now) * level
	if absf(total - _last_total) > 0.00001:
		_last_total = total
		light_factor = total
		for i in lights.size():
			lights[i].light_energy = nominal[i] * total
			lights[i].visible = total > 0.001   # NS-A1: hidden at energy 0, visible the frame a restore starts
			fixture_mats[i].emission_energy_multiplier = FIXTURE_EMISSION * total
	if absf(level - _last_level) > 0.00001 and env != null:
		_last_level = level
		env.ambient_light_energy = AMBIENT_FLOOR + (ambient_nom - AMBIENT_FLOOR) * level

	var rl := _env_val(_rain[0], _rain[1], _rain[2], _rain[3], true, now)
	if absf(rl - _last_rain) > 0.00001:
		_last_rain = rl
		rain_level = rl
		if rain != null:
			if rain_mode == "emit":
				rain.emitting = rl > 0.05
			else:
				rain.amount_ratio = clampf(rl, 0.0, 1.0)

	_update_state(now, level)
	if ghost != null:
		_update_reflection(now)
	cpu_us = Time.get_ticks_usec() - t0


func _fire_orders(prev: int, now: int) -> void:
	if prev < FLICKER_ONSET_MS and now >= FLICKER_ONSET_MS and state != "APAGON":
		_flicker_t0 = FLICKER_ONSET_MS               # LUCES_PARPADEO
	if not blackout_enabled:
		return
	if prev < BLACKOUT_AT_MS and now >= BLACKOUT_AT_MS:   # LUCES_APAGON (monotone, cancels flicker)
		var cur := _env_val(_lvl[0], _lvl[1], _lvl[2], _lvl[3], _lvl[4], now)
		_flicker_t0 = -1
		_lvl = [cur, F_APAGON, BLACKOUT_AT_MS, D_APAGON_MS, false]
		var rc := _env_val(_rain[0], _rain[1], _rain[2], _rain[3], true, now)
		_rain = [rc, LLUVIA_APAGON, BLACKOUT_AT_MS, D_LLUVIA_APAGON_MS]
	if prev < RESTORE_AT_MS and now >= RESTORE_AT_MS:     # LUCES_RESTAURAR + LLUVIA_VUELVE
		var cur2 := _env_val(_lvl[0], _lvl[1], _lvl[2], _lvl[3], _lvl[4], now)
		_lvl = [cur2, 1.0, RESTORE_AT_MS, D_RESTAURAR_MS, true]
		var rc2 := _env_val(_rain[0], _rain[1], _rain[2], _rain[3], true, now)
		_rain = [rc2, 1.0, RESTORE_AT_MS, D_LLUVIA_VUELVE_MS]


static func _smooth(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func _env_val(a: float, b: float, t0: int, d: int, linear: bool, now: int) -> float:
	if t0 < 0:
		return b
	var x := clampf(float(now - t0) / float(d), 0.0, 1.0)
	return lerpf(a, b, x if linear else _smooth(x))


func _flicker_factor(now: int) -> float:
	if _flicker_t0 < 0:
		return 1.0
	var rel := now - _flicker_t0
	if rel < 0:
		return 1.0
	@warning_ignore("integer_division")
	var k := rel / DIP_PERIOD_MS
	if k >= FLICKER_COUNT:
		return 1.0
	var r := rel - k * DIP_PERIOD_MS
	if r < DIP_FALL_MS:
		return lerpf(1.0, F_PARPADEO, _smooth(float(r) / DIP_FALL_MS))
	if r < DIP_FALL_MS + DIP_REC_MS:
		return lerpf(F_PARPADEO, 1.0, _smooth(float(r - DIP_FALL_MS) / DIP_REC_MS))
	return 1.0


func _update_state(now: int, level: float) -> void:
	if _lvl[2] >= 0 and _lvl[1] == F_APAGON and now >= _lvl[2]:
		state = "APAGON"
	elif _lvl[2] >= 0 and _lvl[1] == 1.0 and level < 1.0:
		state = "RESTAURANDO"
	elif _flicker_t0 >= 0 and now - _flicker_t0 < (FLICKER_COUNT - 1) * DIP_PERIOD_MS + DIP_FALL_MS + DIP_REC_MS:
		state = "FLICKER"
	else:
		state = "NORMAL"


## F2/F3 of GDD 28: mirrored position of the player, delayed by tau.
func _update_reflection(now: int) -> void:
	var cp := camera.global_position
	var yaw := camera.global_rotation.y
	_h_head = (_h_head + 1) % HIST
	_h_ms[_h_head] = now
	_h_pos[_h_head] = cp
	_h_yaw[_h_head] = yaw
	var rel := now - REFLECT_ON_MS
	if rel < 0 or rel > REFLECT_DUR_MS + TAU_RAMP_MS:
		ghost.visible = false
		return
	var tau := TAU_S
	if rel < TAU_RAMP_MS:
		tau = TAU_S * _smooth(float(rel) / TAU_RAMP_MS)
	elif rel > REFLECT_DUR_MS:
		tau = TAU_S * (1.0 - _smooth(float(rel - REFLECT_DUR_MS) / TAU_RAMP_MS))
	var target := now - int(tau * 1000.0)
	var p := cp
	var y := yaw
	var i := _h_head
	for _n in HIST:
		if _h_ms[i] >= 0 and _h_ms[i] <= target:
			p = _h_pos[i]
			y = _h_yaw[i]
			break
		i = (i - 1 + HIST) % HIST
	ghost.visible = true
	# p' = p - 2((p - p0).n)n with p0 = (0,0,GLASS_Z), n = (0,0,1)
	ghost.global_position = Vector3(p.x, 0.85, p.z - 2.0 * (p.z - GLASS_Z))
	ghost.global_rotation = Vector3(0.0, PI - y, 0.0)
