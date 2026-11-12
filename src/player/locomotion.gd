## Pure walking maths of the player (GDD 2 F1/F2, rules R6-R9; ADR-0012 D1 steps 2 and 4, P-11; TR-player-006).
## Engine-free: no node, no physics, no clock. All vectors live in the BODY frame (x = right, y = forward)
## except `to_world`/`to_body`, which convert to/from the horizontal world plane (x = world X, y = world Z).
## Yaw convention: it is the rotation about +Y of Godot's `Basis(Vector3.UP, yaw)`, so with yaw 0 "forward" is world -Z.
## The body node is never rotated (C-X13): yaw is a float owned by the Player and only used here.
## TODO(ADR-0012): the ADR sketches `Locomotion.target/accelerate/to_world/to_body` but fixes no signatures; this story
## fixes them (static, `PlayerConfig` injected) and adds `sanitize_move`/`brake_applies` (owner: lead-programmer).
## Example per tick: `v = Locomotion.accelerate(v, Locomotion.target(Locomotion.sanitize_move(m), cfg), cfg, dt)`,
## then `w = Locomotion.to_world(v, yaw)`; after `move_and_slide()`: `v = Locomotion.to_body(slid_xz, yaw)`.
class_name Locomotion extends RefCounted

## Dot-product / magnitude tolerance of the braking rule (GDD F2: float32 can leave a zero crossing at +-1e-7).
const BRAKE_EPSILON: float = 0.001


## Returns `m` when both components are finite, otherwise `Vector2.ZERO` plus one log line (AC-04 b, ADR-0012 D1 step 2).
## Zeroing `mover` outside the Libre state is the state machine's job (story 009), not this class's.
static func sanitize_move(m: Vector2) -> Vector2:
	if is_finite(m.x) and is_finite(m.y):
		return m
	push_warning("Locomotion: non-finite 'mover' input %s treated as (0, 0)" % [m])
	return Vector2.ZERO


## F1: target velocity in the body frame for the move vector `m`. `m` is normalised only when longer than 1;
## backward speed is scaled by `k_atras` and lateral speed by `k_lat`. Non-finite `m` counts as (0, 0) with a log line.
static func target(m: Vector2, cfg: PlayerConfig) -> Vector2:
	var mv: Vector2 = sanitize_move(m)
	var n: Vector2 = mv / maxf(1.0, mv.length())
	var forward: float = n.y if n.y >= 0.0 else n.y * cfg.k_atras
	return cfg.v_paseo * Vector2(n.x * cfg.k_lat, forward)


## True when F2 uses the braking rate: the velocity opposes the target (`v . v_obj < -0.001`) or the target is
## slower than the current speed (`|v_obj| < |v| - 0.001`).
static func brake_applies(v: Vector2, v_obj: Vector2) -> bool:
	return v.dot(v_obj) < -BRAKE_EPSILON or v_obj.length() < v.length() - BRAKE_EPSILON


## F2: one tick of `v.move_toward(v_obj, a * dt)` with `a = v_paseo / t_freno` when `brake_applies`, else
## `v_paseo / t_acel`. Returns `v` unchanged for a non-positive or non-finite `dt`. Never overshoots `v_obj`.
static func accelerate(v: Vector2, v_obj: Vector2, cfg: PlayerConfig, dt: float) -> Vector2:
	if not is_finite(dt) or dt <= 0.0:
		return v
	var t: float = cfg.t_freno if brake_applies(v, v_obj) else cfg.t_acel
	return v.move_toward(v_obj, cfg.v_paseo / t * dt)


## Body frame -> horizontal world plane (x = world X, y = world Z) for the current `yaw` (radians), after F2 (R8).
## Preserves the modulus. Equals `Basis(Vector3.UP, yaw) * Vector3(v.x, 0, -v.y)` projected to XZ.
static func to_world(v: Vector2, yaw: float) -> Vector2:
	var c: float = cos(yaw)
	var s: float = sin(yaw)
	return Vector2(v.x * c - v.y * s, -v.x * s - v.y * c)


## Inverse of `to_world`: adopts a horizontal world velocity (x = X, y = Z), e.g. the one slid by `move_and_slide()`,
## back into the body frame (ADR-0012 D1 step 4, AC-05).
static func to_body(w: Vector2, yaw: float) -> Vector2:
	var c: float = cos(yaw)
	var s: float = sin(yaw)
	return Vector2(w.x * c - w.y * s, -(w.x * s + w.y * c))
