## Camera lease: one owner at a time takes the camera to a pose and gives it back (ADR-0012 D5; GDD 2 R18, F9;
## TR-player-013; AC-20, AC-21, AC-25, AC-44). Pure logic (`RefCounted`), no nodes, no `Tween`/`Timer` (ADR-0002 D6).
## States: OWN -> LEASING(owner) -> LEASED(owner) -> RETURNING(owner) -> OWN. Time is game time from an injected
## `now_source` (production: `clock.now`; frozen while paused). F9: smoothstep `s = u^2 (3 - 2u)`, position and FOV `lerp`,
## yaw by the shortest arc then wrapped, pitch separate; no roll exists, so there is no slerp.
## Arrival events are queued and read with `take_events()` from `_process`; they are never emitted inside a request call.
## TODO(ADR-0012): the ADR sketch has `CameraLease.new(cfg, logger)`, `evaluate(now, eyes, yaw, pitch)` and
## `fov(now, fov_free)`. This story fixes `new(cfg, logger, now_source)`, `evaluate(eyes, yaw, pitch, fov_free_deg)` (reads the
## injected clock, one time source) and `fov()` (FOV of the last evaluation), plus the signatures of the requests, which
## return a bool (accepted); recorded as an amendment (owner: lead-programmer).
## Example per frame: `var cam := lease.evaluate(eyes, yaw, pitch, fov_free); for ev in lease.take_events(): ...`.
class_name CameraLease extends RefCounted

## Lease states (ADR-0012 D5).
enum State { OWN, LEASING, LEASED, RETURNING }

## `LeaseEvent.kind` of `camara_cedida`.
const CEDED: StringName = &"ceded"
## `LeaseEvent.kind` of `camara_devuelta`.
const RETURNED: StringName = &"returned"


## Arrival event queued by `evaluate` and consumed with `take_events()`.
class LeaseEvent extends RefCounted:
	## `CameraLease.CEDED` or `CameraLease.RETURNED`.
	var kind: StringName = &""
	## Owner the event refers to.
	var owner: StringName = &""


var _cfg: PlayerConfig
var _log: LogSink
var _now_source: Callable
var _state: State = State.OWN
var _owner: StringName = &""
var _events: Array[LeaseEvent] = []
# Start of the current transition (camera state when it began).
var _t0: float = 0.0
var _duration: float = 0.0
var _pos0: Vector3 = Vector3.ZERO
var _yaw0: float = 0.0
var _pitch0: float = 0.0
var _fov0: float = 0.0
# Target of a cession.
var _target: CameraPose = null
var _fov_target: float = 0.0
# Free look saved when leaving OWN (updated every evaluation while OWN).
var _saved_yaw: float = 0.0
var _saved_pitch: float = 0.0
# Last evaluated camera.
var _has_cur: bool = false
var _cur_pos: Vector3 = Vector3.ZERO
var _cur_yaw: float = 0.0
var _cur_pitch: float = 0.0
var _cur_fov: float = 0.0


func _init(cfg: PlayerConfig, logger: LogSink, now_source: Callable) -> void:
	_cfg = cfg
	_log = logger
	_now_source = now_source


## Current state.
func state() -> State:
	return _state


## True when the player owns the camera (no lease in any phase).
func is_own() -> bool:
	return _state == State.OWN


## Owner holding the lease, or `&""` in OWN.
func owner() -> StringName:
	return _owner


## Vertical FOV in degrees of the last `evaluate` (includes a lease in progress).
func fov() -> float:
	return _cur_fov


## Asks for the camera (ADR-0012 D5, GDD 2 R18). `pose_destino.position` = eyes, world; angles in radians; `fov_destino_deg`
## vertical degrees; `duracion` seconds, clamped to [0, t_transicion_max] (logged when clamped). Returns false (and logs an
## error) when the owner is not in `propietarios_camara`, another owner holds the lease in any phase, or an argument is not
## finite; the camera does not move. The same owner may re-lease from any state: the start is the current camera, the saved
## yaw/pitch do not change. `camara_cedida` arrives from `evaluate` (with `duracion` 0, on the next one), never in this call.
func ceder_camara(propietario: StringName, pose_destino: CameraPose, fov_destino_deg: float, duracion: float) -> bool:
	if not _cfg.propietarios_camara.has(propietario):
		_log.line(LogSink.LEVEL_ERROR, "ceder_camara rejected: '%s' is not in propietarios_camara" % propietario)
		return false
	if _state != State.OWN and _owner != propietario:
		_log.line(LogSink.LEVEL_ERROR, "ceder_camara rejected: '%s' asked while '%s' holds the camera" % [propietario, _owner])
		return false
	if pose_destino == null or not _pose_finite(pose_destino) or not is_finite(fov_destino_deg) or not is_finite(duracion):
		_log.line(LogSink.LEVEL_ERROR, "ceder_camara rejected: non-finite pose, fov or duration from '%s'" % propietario)
		return false
	var d: float = clampf(duracion, 0.0, _cfg.t_transicion_max)
	if d != duracion:
		_log.line(LogSink.LEVEL_WARN, "ceder_camara: duration %s s clamped to %s s" % [duracion, d])
	var target: CameraPose = CameraPose.make(pose_destino.position, wrapf(pose_destino.yaw, -PI, PI),
			clampf(pose_destino.pitch, -_cfg.pitch_cesion_max, _cfg.pitch_cesion_max))
	_begin(target)
	_target = target
	_fov_target = _fov_for_target(fov_destino_deg)
	_duration = d
	_owner = propietario
	_state = State.LEASING
	return true


## Gives the camera back in `t_devolver` seconds towards the live eyes, the saved yaw/pitch and the free FOV (all re-read
## every `evaluate`). Returns false (and logs an error) if `propietario` does not hold the lease or the state is OWN; returns
## true without changes when it is already RETURNING for that owner. `camara_devuelta` arrives from `evaluate`.
func devolver_camara(propietario: StringName) -> bool:
	if _state == State.OWN or _owner != propietario:
		_log.line(LogSink.LEVEL_ERROR, "devolver_camara rejected: '%s' does not hold the camera" % propietario)
		return false
	if _state == State.RETURNING:
		return true
	_begin(null)
	_duration = _cfg.t_devolver
	_state = State.RETURNING
	return true


## Cancels any lease without events (`colocar`, scene unload; ADR-0012 D5). Drops queued events.
func cancel_silently() -> void:
	_state = State.OWN
	_owner = &""
	_events.clear()
	_target = null


## Camera for this frame (call once per `_process`). `eyes`, `yaw`, `pitch` = the free camera (live interpolated eyes and the
## player's look); `fov_free_deg` = free vertical FOV. In OWN it passes them through. May queue an arrival event and change
## state (LEASING -> LEASED, RETURNING -> OWN).
func evaluate(eyes: Vector3, yaw: float, pitch: float, fov_free_deg: float) -> CameraPose:
	if _state == State.OWN:
		_saved_yaw = yaw
		_saved_pitch = pitch
		_store(eyes, yaw, pitch, fov_free_deg)
		return CameraPose.make(eyes, yaw, pitch)
	var now: float = _now()
	var u: float = _progress(now)
	if _state == State.LEASED:
		_store(_target.position, _target.yaw, _target.pitch, _fov_target)
	elif _state == State.LEASING:
		if u >= 1.0:
			_store(_target.position, _target.yaw, _target.pitch, _fov_target)
			_state = State.LEASED
			_push_event(CEDED)
		else:
			var s: float = u * u * (3.0 - 2.0 * u)
			_store(_pos0.lerp(_target.position, s),
					_yaw0 + s * wrapf(_target.yaw - _yaw0, -PI, PI),
					lerpf(_pitch0, _target.pitch, s), lerpf(_fov0, _fov_target, s))
	else: # RETURNING
		if u >= 1.0:
			_store(eyes, _saved_yaw, _saved_pitch, fov_free_deg)
			var who: StringName = _owner
			_state = State.OWN
			_owner = &""
			_target = null
			_push_event_for(RETURNED, who)
		else:
			var s2: float = u * u * (3.0 - 2.0 * u)
			_store(_pos0.lerp(eyes, s2), _yaw0 + s2 * wrapf(_saved_yaw - _yaw0, -PI, PI),
					lerpf(_pitch0, _saved_pitch, s2), lerpf(_fov0, fov_free_deg, s2))
	return CameraPose.make(_cur_pos, _cur_yaw, _cur_pitch)


## Returns and clears the queued arrival events, in order.
func take_events() -> Array[LeaseEvent]:
	var out: Array[LeaseEvent] = _events.duplicate()
	_events.clear()
	return out


## Conversion of a requested FOV to the value interpolated towards. M1: identity (F5 does not exist, TR-player-008 deferred);
## for 16:9 and FOV <= 70 deg it equals F5. `CameraFov.to_engine()` replaces it later.
## TODO(TR-player-008): route through F5 with the injected aspect (owner: gameplay-programmer).
func _fov_for_target(fov_deg: float) -> float:
	return fov_deg


func _now() -> float:
	if _now_source.is_valid():
		return float(_now_source.call())
	return 0.0


# Starts a transition from the current camera. In OWN with no sample yet the start is the target itself (no motion).
func _begin(target: CameraPose) -> void:
	_t0 = _now()
	if _has_cur:
		_pos0 = _cur_pos
		_yaw0 = _cur_yaw
		_pitch0 = _cur_pitch
		_fov0 = _cur_fov
	elif target != null:
		_pos0 = target.position
		_yaw0 = target.yaw
		_pitch0 = target.pitch
		_fov0 = 0.0


func _progress(now: float) -> float:
	if _duration <= 0.0:
		return 1.0
	return clampf((now - _t0) / _duration, 0.0, 1.0)


func _store(pos: Vector3, yaw: float, pitch: float, fov_deg: float) -> void:
	_has_cur = true
	_cur_pos = pos
	_cur_yaw = wrapf(yaw, -PI, PI)
	_cur_pitch = pitch
	_cur_fov = fov_deg


func _push_event(kind: StringName) -> void:
	_push_event_for(kind, _owner)


func _push_event_for(kind: StringName, who: StringName) -> void:
	var ev: LeaseEvent = LeaseEvent.new()
	ev.kind = kind
	ev.owner = who
	_events.append(ev)


static func _pose_finite(p: CameraPose) -> bool:
	return p.position.is_finite() and is_finite(p.yaw) and is_finite(p.pitch)
