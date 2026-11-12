## State machine of the Player and its `colocar` (re-placement) logic (ADR-0012 D6, D2 `reset`, D7 `fill`; GDD 2
## § States and Transitions, rules R20, R22; TR-player-014, TR-player-018).
## Pure logic, no engine nodes: the Player (story 011) owns one instance and polls it, it never subscribes to the bus (C-X16).
## States: SIN_ESCENA (before the first `colocar`), LIBRE (context EXPLORACION, lease OWN, not just placed),
## CONGELADO (any other context, or just placed until the first poll that sees EXPLORACION), CAMARA_CEDIDA (lease != OWN).
## The machine also owns the body-frame horizontal velocity, so that "leaving Libre sets the target to 0 and brakes
## (velocity is not reset)" and "entering Libre reads `mover` in that same tick" (AC-24, AC-26) are testable without physics.
## TODO(ADR-0012): the ADR sketches `sync`, `is_free`, `on_placed` only; the rest of the signatures (`place`, `step_velocity`,
## `defer_place`, `on_configured`) are fixed by this story (owner: lead-programmer).
## Example per tick: `sm.sync(input.context(), lease.is_own()); v = sm.step_velocity(input.move_vector(), cfg, dt)`.
class_name PlayerStateMachine extends RefCounted

## Player states (GDD 2).
enum State { SIN_ESCENA, LIBRE, CONGELADO, CAMARA_CEDIDA }

var _state: State = State.SIN_ESCENA
var _just_placed: bool = false
var _velocity_body: Vector2 = Vector2.ZERO
var _pending: PlayerPose = null
var _anchor: PlayerPose = null


## Current state.
func state() -> State:
	return _state


## True only in LIBRE: `mover` and `mirar` are honoured.
func is_free() -> bool:
	return _state == State.LIBRE


## Horizontal velocity in the body frame (x = right, y = forward), m/s.
func velocity_body() -> Vector2:
	return _velocity_body


## Adopts the velocity left by `move_and_slide()` (ADR-0012 D1 step 4). A non-finite value is ignored.
func set_velocity_body(v: Vector2) -> void:
	if is_finite(v.x) and is_finite(v.y):
		_velocity_body = v


## Pose last given to `place` (the spawn anchor `StuckGuard` falls back to), or null before any placement.
func anchor() -> PlayerPose:
	return _anchor


## Polls the world once (per physics tick and once per frame). `context` = `PlayerInputPort.context()`, `lease_own` =
## the camera lease is OWN. Does nothing in SIN_ESCENA. While "just placed", the machine stays CONGELADO until the first
## poll that sees EXPLORACION. Otherwise: lease != OWN -> CAMARA_CEDIDA; context EXPLORACION -> LIBRE; else CONGELADO.
func sync(context: InputTypes.Context, lease_own: bool) -> void:
	if _state == State.SIN_ESCENA:
		return
	if _just_placed:
		if context != InputTypes.Context.EXPLORACION:
			return
		_just_placed = false
	if not lease_own:
		_state = State.CAMARA_CEDIDA
	elif context == InputTypes.Context.EXPLORACION:
		_state = State.LIBRE
	else:
		_state = State.CONGELADO


## One tick of F2. `move` counts only when LIBRE; otherwise the target is (0, 0) and the body brakes from its current
## velocity (it is not reset). Returns the new body-frame velocity.
func step_velocity(move: Vector2, cfg: PlayerConfig, dt: float) -> Vector2:
	var m: Vector2 = move if is_free() else Vector2.ZERO
	_velocity_body = Locomotion.accelerate(_velocity_body, Locomotion.target(m, cfg), cfg, dt)
	return _velocity_body


## `colocar` before `configurar()` (C2): remembers the pose (the last one wins); the state stays SIN_ESCENA.
func defer_place(pose: PlayerPose) -> void:
	if _is_valid_pose(pose):
		_pending = pose


## True when a `defer_place` is waiting for `on_configured`.
func has_pending() -> bool:
	return _pending != null


## Called when `configurar()` finishes: if a placement was deferred, moves to CONGELADO (just placed) and returns that
## pose so the caller completes it with `place`; otherwise returns null and the state is unchanged.
func on_configured() -> PlayerPose:
	var p: PlayerPose = _pending
	_pending = null
	if p != null:
		_state = State.CONGELADO
		_just_placed = true
	return p


## `colocar` (ADR-0012 D6, same tick, synchronous): velocity 0, lease cancelled without signals (`cancel_lease`, a
## callable with no arguments provided by the Player; story 010 supplies `CameraLease.cancel_silently`), `Look` set
## (yaw wrapped, pitch clamped), `PoseHistory.fill`, `YawWindow.reset`, `TickInterpolator.reset` at the eyes
## (`position + (0, eye_height, 0)`), anchor saved, state CONGELADO until the first poll that sees EXPLORACION.
## A pose with a non-finite component is rejected with a log line and returns false (nothing changes).
## Returns true when the placement was applied.
func place(pose: PlayerPose, look: Look, history: PoseHistory, yaw_window: YawWindow, interp: TickInterpolator,
		eye_height: float, cancel_lease: Callable = Callable()) -> bool:
	if not _is_valid_pose(pose):
		return false
	_pending = null
	_velocity_body = Vector2.ZERO
	if cancel_lease.is_valid():
		cancel_lease.call()
	look.set_orientation(pose.yaw, pose.pitch)
	var p: PlayerPose = PlayerPose.new()
	p.position = pose.position
	p.yaw = look.yaw
	p.pitch = look.pitch
	history.fill(p)
	yaw_window.reset(p.yaw)
	interp.reset(p.position + Vector3(0.0, eye_height, 0.0), 0.0, 0.0)
	_anchor = p
	_just_placed = true
	_state = State.CONGELADO
	return true


func _is_valid_pose(pose: PlayerPose) -> bool:
	if pose == null or not pose.position.is_finite() or not is_finite(pose.yaw) or not is_finite(pose.pitch):
		push_warning("PlayerStateMachine: invalid pose for colocar ignored")
		return false
	return true
