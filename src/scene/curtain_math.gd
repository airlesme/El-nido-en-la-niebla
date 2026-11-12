## Pure curtain opacity logic (GDD 4 F1, ADR-0003 load sequence steps 2 and 8, TR-scene-014/015).
## No nodes, no engine time: the caller feeds the real frame time (from the injected RealClock, ADR-0002 D6)
## and applies `alpha` to the visual Curtain (another story). No Tween/Timer here (C-X05, ADR-0014).
## `alpha_out(a0, t, d) = a0 + (1 - a0) * S(clamp(t / d, 0, 1))`, `alpha_in(t, d) = 1 - S(clamp(t / d, 0, 1))`,
## `S(x) = x^2 (3 - 2x)`, `t += min(dt_real, delta_max)`; `d <= 0` or `a0 >= 1` skips the fade (no division).
## TODO(lead-programmer): ADR-0003 § Key Interfaces names `Curtain.step_out(dt, d)` / `step_in(dt, d)`
## without fixing the pure class; this story fixes `CurtainMath` with `begin_out/begin_in/step_out/step_in`
## (ADR-fallback, to be recorded as an amendment).
## Example: `var c := CurtainMath.new(); c.begin_out(0.0); while not c.step_out(dt_real, 0.1, 0.8): pass`.
class_name CurtainMath extends RefCounted

## Phase of the pure curtain machine.
enum Phase { IDLE, DARKENING, DARK, LIGHTENING, CLEAR }

## Current opacity in [0, 1].
var alpha: float = 0.0
## Elapsed time of the running fade, seconds (clipped time).
var elapsed_s: float = 0.0
## Current phase.
var phase: Phase = Phase.IDLE

var _alpha_0: float = 0.0


## Smoothstep `S(x) = x^2 (3 - 2x)` with `x` clamped to [0, 1].
static func smooth(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


## Darken opacity at `t` seconds from `alpha_0`; `d <= 0` or `alpha_0 >= 1` gives 1.
static func alpha_out(alpha_0: float, t: float, d: float) -> float:
	var a0: float = clampf(alpha_0, 0.0, 1.0)
	if d <= 0.0 or a0 >= 1.0:
		return 1.0
	return a0 + (1.0 - a0) * smooth(t / d)


## Lighten opacity at `t` seconds; `d <= 0` gives 0.
static func alpha_in(t: float, d: float) -> float:
	if d <= 0.0:
		return 0.0
	return 1.0 - smooth(t / d)


## Fade time after one frame: `t + min(dt_real, delta_max)` (negative `dt_real` counts as 0).
static func advance_t(t: float, dt_real: float, delta_max: float) -> float:
	return t + minf(maxf(dt_real, 0.0), delta_max)


## Starts a darkening from the current opacity (or from `alpha_0` when given, e.g. a test or a mid-fade restart).
func begin_out(alpha_0: float = -1.0) -> void:
	_alpha_0 = alpha if alpha_0 < 0.0 else clampf(alpha_0, 0.0, 1.0)
	alpha = _alpha_0
	elapsed_s = 0.0
	phase = Phase.DARKENING


## Starts a lightening from the current opacity.
func begin_in() -> void:
	elapsed_s = 0.0
	phase = Phase.LIGHTENING


## One frame of darkening. Returns true when alpha == 1 (also in the same frame for `d <= 0` or alpha_0 = 1).
func step_out(dt_real: float, delta_max: float, d: float) -> bool:
	if phase != Phase.DARKENING:
		return phase == Phase.DARK
	if d <= 0.0 or _alpha_0 >= 1.0:
		alpha = 1.0
	else:
		elapsed_s = advance_t(elapsed_s, dt_real, delta_max)
		alpha = 1.0 if elapsed_s >= d else alpha_out(_alpha_0, elapsed_s, d)
	if alpha >= 1.0:
		phase = Phase.DARK
		return true
	return false


## One frame of lightening. Returns true when alpha == 0 (same frame for `d <= 0`).
func step_in(dt_real: float, delta_max: float, d: float) -> bool:
	if phase != Phase.LIGHTENING:
		return phase == Phase.CLEAR
	if d <= 0.0:
		alpha = 0.0
	else:
		elapsed_s = advance_t(elapsed_s, dt_real, delta_max)
		alpha = 0.0 if elapsed_s >= d else alpha_in(elapsed_s, d)
	if alpha <= 0.0:
		phase = Phase.CLEAR
		return true
	return false
