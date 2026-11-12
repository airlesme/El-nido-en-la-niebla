## Pure maths of movement and look (GDD 1 F1, F2, F3; ADR-0006 D6/D8; TR-input-009, TR-input-010).
## Engine-free and static: the tuning values (marked with a dagger in the GDD) are injected by the caller
## from `BindingTable.tuning_value`, never hardcoded here. Non-finite input counts as zero (never NaN out).
## Output convention of F2/F3 is the GDD's own: x = yaw, y = pitch with the screen axis (y down is positive);
## the router flips y to the +up convention of `Look` (see `InputRouter.consume_look_delta`).
## Example: `InputFormulas.mouse_look(Vector2(18, -6), 0.10, 1.0, 1)` returns `(1.8, -0.6)`.
class_name InputFormulas extends RefCounted

## Tolerance for float32 rounding of the axes at the dead-zone boundary.
const BOUNDARY_EPSILON: float = 1e-6
## Per-frame cap of F2 (degrees) against spikes; a GDD constant, not a tuning value.
const MOUSE_FRAME_CAP_DEG: float = 45.0
## Cap of the frame time in F3 (seconds) against jumps after a hitch; a GDD constant.
const STICK_DELTA_CAP_S: float = 0.1


## True when both components are finite.
static func is_finite_vec(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)


## F1: `r = clamp((|v| - dz_in) / (1 - dz_out - dz_in), 0, 1)`, radial over the raw axes.
## Non-finite `v` or `dz_in + dz_out >= 1` (invalid data) returns 0.
## Example: `radial_deadzone(Vector2(0.5, 0.4), 0.15, 0.05)` is 0.613.
static func radial_deadzone(v: Vector2, dz_in: float, dz_out: float) -> float:
	if not is_finite_vec(v) or not is_finite(dz_in) or not is_finite(dz_out):
		return 0.0
	var span: float = 1.0 - dz_out - dz_in
	if span <= 0.0:
		return 0.0
	var len: float = v.length()
	# Vector2 is float32: 0.15 arrives as 0.15000000596; the boundary itself must be inside the zone.
	if len <= dz_in + BOUNDARY_EPSILON:
		return 0.0
	return clampf((len - dz_in) / span, 0.0, 1.0)


## F2: `delta_theta = relative_px * k_m * s_m * inv`, each component capped to +-45 degrees.
## `inv` is +1 or -1 (vertical inversion, applied to y). Independent of the frame time.
## Non-finite `relative_px` or factors give (0, 0). Example: (18, -6) with k 0.10, s 1, inv +1 -> (1.8, -0.6).
static func mouse_look(relative_px: Vector2, k_m: float, s_m: float, inv: int) -> Vector2:
	if not is_finite_vec(relative_px) or not is_finite(k_m) or not is_finite(s_m):
		return Vector2.ZERO
	var d: Vector2 = relative_px * k_m * s_m
	d.y *= -1.0 if inv < 0 else 1.0
	return Vector2(clampf(d.x, -MOUSE_FRAME_CAP_DEG, MOUSE_FRAME_CAP_DEG),
			clampf(d.y, -MOUSE_FRAME_CAP_DEG, MOUSE_FRAME_CAP_DEG))


## F3 speed: `omega = omega_max * r^p * s_s` (degrees per second). `r` is clamped to [0, 1].
## Example: r 0.613, omega_max 120, p 1.5, s_s 1 -> 57.6.
static func stick_speed(r: float, omega_max: float, p: float, s_s: float) -> float:
	if not is_finite(r) or not is_finite(omega_max) or not is_finite(p) or not is_finite(s_s):
		return 0.0
	return omega_max * pow(clampf(r, 0.0, 1.0), p) * s_s


## F3: `delta_theta = (v / |v|) * omega * min(delta, 0.1)` with `r` from F1 on the raw axes `v`.
## `inv` is +1 or -1 (vertical inversion, applied to y). `delta` <= 0 or non-finite gives (0, 0).
## Example: v (0.5, 0.4) at 60 fps (delta 1/60) -> about 0.96 degrees along v.
static func stick_look(v: Vector2, dz_in: float, dz_out: float, omega_max: float, p: float, s_s: float,
		inv: int, delta: float) -> Vector2:
	if not is_finite_vec(v) or not is_finite(delta) or delta <= 0.0:
		return Vector2.ZERO
	var r: float = radial_deadzone(v, dz_in, dz_out)
	if r <= 0.0:
		return Vector2.ZERO
	var omega: float = stick_speed(r, omega_max, p, s_s)
	var d: Vector2 = v.normalized() * omega * minf(delta, STICK_DELTA_CAP_S)
	d.y *= -1.0 if inv < 0 else 1.0
	return d


## Movement vector (x right, y forward) from a left-stick sample: direction of `v` times F1's magnitude,
## so it is zero inside the dead zone and at most length 1. Non-finite `v` gives (0, 0).
static func stick_move(v: Vector2, dz_in: float, dz_out: float) -> Vector2:
	if not is_finite_vec(v):
		return Vector2.ZERO
	var r: float = radial_deadzone(v, dz_in, dz_out)
	if r <= 0.0:
		return Vector2.ZERO
	return v.normalized() * r
