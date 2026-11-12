## Circular pose memory of the player (ADR-0012 D7; GDD 2 rule 29, F6; TR-player-016).
## Column ring buffers of `N = ceil(T_hist * f_fisica) + 2` samples (62 by default); sample 0 is the newest.
## Pure logic, no engine nodes. `record_tick` and `fill` are internal to the player module (C-R21): the Player is the only
## caller; consumers (system 28) only get `pose_con_retardo`, exposed by story 011.
## Example: `var h := PoseHistory.new(1.0, 60); h.fill(p); h.record_tick(pos, yaw, 0.0, v, ph); h.pose_con_retardo(0.6)`.
class_name PoseHistory extends RefCounted

## Tolerance that keeps `ceil` from rounding up a product like 0.6 * 60 = 36.00000000000001.
const _CEIL_EPS: float = 1e-6

var _n: int = 0
var _t_hist: float = 0.0
var _f_fisica: float = 0.0
## Index in the ring of the newest sample.
var _head: int = 0
var _positions: PackedVector3Array = PackedVector3Array()
var _yaws: PackedFloat32Array = PackedFloat32Array()
var _pitches: PackedFloat32Array = PackedFloat32Array()
var _speeds: PackedFloat32Array = PackedFloat32Array()
var _phases: PackedFloat32Array = PackedFloat32Array()


## Sizes the buffers once. `t_hist` in seconds (> 0), `f_fisica` in Hz (>= 1); out-of-range values are clamped to those minima.
func _init(t_hist: float, f_fisica: int) -> void:
	_t_hist = maxf(t_hist, 0.0)
	_f_fisica = float(maxi(f_fisica, 1))
	_n = ceili(_t_hist * _f_fisica - _CEIL_EPS) + 2
	_positions.resize(_n)
	_yaws.resize(_n)
	_pitches.resize(_n)
	_speeds.resize(_n)
	_phases.resize(_n)


## Number of samples `N`.
func capacity() -> int:
	return _n


## Internal (Player only): writes one sample as the newest, overwriting the oldest. Yaw is stored wrapped to [-PI, PI).
func record_tick(position: Vector3, yaw: float, pitch: float, speed_h: float, step_phase: float) -> void:
	_head = (_head + 1) % _n
	_write(_head, position, yaw, pitch, speed_h, step_phase)


## Internal (Player only, used by `colocar`): writes `pose` into all N samples.
func fill(pose: PlayerPose) -> void:
	for i: int in _n:
		_write(i, pose.position, pose.yaw, pose.pitch, pose.speed_h, pose.step_phase)
	_head = 0


## Pose `tau_s` seconds ago. `tau_s` is clamped to [0, T_hist] (no error); lerp between samples i and i + 1 (yaw by the
## shortest arc). Allocates one PlayerPose.
func pose_con_retardo(tau_s: float) -> PlayerPose:
	var tau: float = clampf(tau_s, 0.0, _t_hist)
	var s: float = tau * _f_fisica
	var i: int = mini(floori(s), _n - 2)
	var a: float = clampf(s - float(i), 0.0, 1.0)
	var k0: int = _slot(i)
	var k1: int = _slot(i + 1)
	var p: PlayerPose = PlayerPose.new()
	p.position = _positions[k0].lerp(_positions[k1], a)
	p.yaw = wrapf(lerp_angle(_yaws[k0], _yaws[k1], a), -PI, PI)
	p.pitch = lerpf(_pitches[k0], _pitches[k1], a)
	p.speed_h = lerpf(_speeds[k0], _speeds[k1], a)
	p.step_phase = lerpf(_phases[k0], _phases[k1], a)
	return p


## Ring index of the sample `age` ticks old (0 = newest).
func _slot(age: int) -> int:
	return posmod(_head - age, _n)


func _write(slot: int, position: Vector3, yaw: float, pitch: float, speed_h: float, step_phase: float) -> void:
	_positions[slot] = position
	_yaws[slot] = wrapf(yaw, -PI, PI)
	_pitches[slot] = pitch
	_speeds[slot] = speed_h
	_phases[slot] = step_phase
