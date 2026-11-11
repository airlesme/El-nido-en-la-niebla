class_name TickInterpolator
extends RefCounted
## One-tick-latency interpolation of the player rig (ADR-0012 D2, C-R15).
##
## Pure, engine-free: it never reads a clock. The caller (Player, story 011) pushes one
## sample per physics tick and passes the alpha each frame, taken from
## `Engine.get_physics_interpolation_fraction()`. It keeps NO accumulator of its own
## (C-X09) and never extrapolates: alpha is clamped to [0, 1].
##
## Signatures are defined here (ADR-0012 does not fix them).
## TODO(ADR-0012): record push/reset/sample signatures in the ADR (ADR-fallback).

var _prev_position: Vector3 = Vector3.ZERO
var _curr_position: Vector3 = Vector3.ZERO
var _prev_phase: float = 0.0
var _curr_phase: float = 0.0
var _prev_ratio: float = 0.0
var _curr_ratio: float = 0.0


## Places the interpolator at `position` with no history: `prev = curr`, so the next
## frame shows no sweep. Call from `colocar` and the safety-net relocation.
func reset(position: Vector3, phase: float = 0.0, ratio: float = 0.0) -> void:
	_prev_position = position
	_curr_position = position
	_prev_phase = phase
	_curr_phase = phase
	_prev_ratio = ratio
	_curr_ratio = ratio


## Shifts `prev <- curr <- new` once per physics tick. Non-finite input is ignored
## (the previous state is kept) so a NaN can never reach the camera.
func push(position: Vector3, phase: float, ratio: float) -> void:
	if not (position.is_finite() and is_finite(phase) and is_finite(ratio)):
		return
	_prev_position = _curr_position
	_curr_position = position
	_prev_phase = _curr_phase
	_curr_phase = phase
	_prev_ratio = _curr_ratio
	_curr_ratio = ratio


## Presented eye position: `lerp(prev, curr, alpha)`.
func position_at(alpha: float) -> Vector3:
	return _prev_position.lerp(_curr_position, _clean_alpha(alpha))


## Presented step phase `d`, same alpha as the position.
func phase_at(alpha: float) -> float:
	return lerpf(_prev_phase, _curr_phase, _clean_alpha(alpha))


## Presented speed ratio `r`, same alpha as the position.
func ratio_at(alpha: float) -> float:
	return lerpf(_prev_ratio, _curr_ratio, _clean_alpha(alpha))


## Clamps alpha to [0, 1] (never extrapolate); a non-finite alpha counts as 1.0 (current).
func _clean_alpha(alpha: float) -> float:
	if not is_finite(alpha):
		return 1.0
	return clampf(alpha, 0.0, 1.0)
