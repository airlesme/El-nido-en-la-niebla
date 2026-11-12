## Footstep crossings tied to walked distance (ADR-0012 D1 step 5, D10 `paso`; GDD 2 F3, R31). Pure, engine-free.
## The Player (story 011) accumulates `d += |delta_pos_horizontal|` AFTER collisions (a wall adds 0) and emits `paso`
## for each crossing returned here, with `SurfaceProbe.floor_surface()` and `intensity(r, i_paso_min)`.
## A step happens at every `d = (n + 1/2) * L_paso`, n >= 0, independent of the sway level.
## Example: `for c in StepTracker.crossings(d, d + step_len, cfg.l_paso): paso.emit(probe.floor_surface(), StepTracker.intensity(r, cfg.i_paso_min))`.
## TODO(ADR-0012): signature `crossings(d_from, d_to, l_paso)` follows the ADR sketch; return type fixed here
## as Array[float] of distances (ADR-fallback; owner: lead-programmer).
class_name StepTracker extends RefCounted

## Tolerance absorbing float error when a crossing falls exactly on an interval end.
const EPSILON: float = 1e-9


## Crossing distances `(n + 1/2) * l_paso` inside the half-open interval (d_from, d_to], ascending.
## Empty when `d_to <= d_from`, `l_paso <= 0` or any input is non-finite.
static func crossings(d_from: float, d_to: float, l_paso: float) -> Array[float]:
	var out: Array[float] = []
	if not (is_finite(d_from) and is_finite(d_to) and is_finite(l_paso)):
		return out
	if l_paso <= 0.0 or d_to <= d_from:
		return out
	var first: int = maxi(int(floor(d_from / l_paso - 0.5 + EPSILON)) + 1, 0)
	var last: int = int(floor(d_to / l_paso - 0.5 + EPSILON))
	for n in range(first, last + 1):
		out.append((float(n) + 0.5) * l_paso)
	return out


## Step intensity `lerp(i_paso_min, 1, r)` with `r` (speed / v_paseo) clamped to [0, 1].
static func intensity(r: float, i_paso_min: float) -> float:
	if not is_finite(r):
		r = 0.0
	return lerpf(i_paso_min, 1.0, clampf(r, 0.0, 1.0))
