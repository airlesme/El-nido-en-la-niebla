class_name BobMath
extends RefCounted
## Camera bob tied to the distance walked (GDD 2 F3, ADR-0012 D3; TR-player-009).
##
## Pure and engine-free (C-R22): it reads no clock and touches no node. Two parts:
## - `offset(d, r, g, cfg)` (static): translation of the `Bob` node. Translation only, roll never exists.
##   `d` is the real distance walked and `r` the speed ratio, both already interpolated with the
##   alpha of the `TickInterpolator` (ADR-0012 D2).
## - the level ramp (instance): `g` follows `balanceo_camara` (`completo`/`reducido`/`ninguno`) and moves
##   linearly over `t_cambio_balanceo` of GAME time. The caller passes `now_s` from the injected
##   `GameClock` (C-R19); no Timer/Tween is involved (C-X15). Pause freezes `now_s`, so it freezes the ramp.
##
## Signatures: `offset` follows the ADR-0012 pseudocode; the ramp API is fixed by this story.
## TODO(ADR-0012): record `configure`/`set_level`/`gain` in § Key Interfaces (ADR-fallback; owner: lead-programmer).
## Example:
##   var bob: BobMath = BobMath.new()
##   bob.configure(cfg, &"reducido", clock.now())
##   %Bob.position = BobMath.offset(interp.phase_at(a), interp.ratio_at(a), bob.gain(clock.now()), cfg)

const LEVEL_FULL: StringName = &"completo"
const LEVEL_REDUCED: StringName = &"reducido"
const LEVEL_NONE: StringName = &"ninguno"

var _cfg: PlayerConfig = null
var _g_from: float = 0.0
var _g_to: float = 0.0
var _t_start_s: float = 0.0
var _duration_s: float = 0.0


## Translation of the `Bob` node for distance `d` (m), speed ratio `r` and gain `g` (GDD 2 F3):
## `y = A_v*g*r*cos(phi)`, `x = A_h*g*r*sin(phi/2)`, `phi = 2*pi*d/L_paso`, z = 0.
## `g == 0.0` returns exactly `Vector3.ZERO` (no threshold). Non-finite input or a non-positive
## `l_paso` returns `Vector3.ZERO` so a NaN never reaches the camera. `r` is clamped to [0, 1].
static func offset(d: float, r: float, g: float, cfg: PlayerConfig) -> Vector3:
	if g == 0.0 or cfg == null or cfg.l_paso <= 0.0:
		return Vector3.ZERO
	if not (is_finite(d) and is_finite(r) and is_finite(g)):
		return Vector3.ZERO
	var amp: float = g * clampf(r, 0.0, 1.0)
	var phi: float = TAU * d / cfg.l_paso
	return Vector3(cfg.a_h * amp * sin(phi * 0.5), cfg.a_v * amp * cos(phi), 0.0)


## Gain `g` of a level using the config values; `ninguno` is exactly 0.0.
## Returns -1.0 for an unknown level (callers must reject it).
static func level_gain(level: StringName, cfg: PlayerConfig) -> float:
	match level:
		LEVEL_FULL:
			return cfg.g_completo
		LEVEL_REDUCED:
			return cfg.g_reducido
		LEVEL_NONE:
			return 0.0
	return -1.0


## Sets the config and puts `g` at `level` instantly (no ramp), at game time `now_s`.
## Returns false (state unchanged) for an unknown level or a null config.
func configure(cfg: PlayerConfig, level: StringName, now_s: float) -> bool:
	if cfg == null:
		return false
	var target: float = level_gain(level, cfg)
	if target < 0.0:
		return false
	_cfg = cfg
	_g_from = target
	_g_to = target
	_t_start_s = now_s
	_duration_s = 0.0
	return true


## Starts a linear ramp from the current gain to the one of `level` over `t_cambio_balanceo`,
## beginning at game time `now_s`. A change mid-ramp starts from the gain shown at that moment (no jump).
## Returns false for an unknown level or before `configure`.
func set_level(level: StringName, now_s: float) -> bool:
	if _cfg == null:
		return false
	var target: float = level_gain(level, _cfg)
	if target < 0.0:
		return false
	_g_from = gain(now_s)
	_g_to = target
	_t_start_s = now_s
	_duration_s = _cfg.t_cambio_balanceo
	return true


## Current gain `g` at game time `now_s`. Before `configure` it is 0.0. At the end of the ramp it is
## exactly the target (so `ninguno` gives exactly 0.0).
func gain(now_s: float) -> float:
	if _cfg == null or not is_finite(now_s):
		return _g_to
	if _duration_s <= 0.0 or now_s >= _t_start_s + _duration_s:
		return _g_to
	if now_s <= _t_start_s:
		return _g_from
	return lerpf(_g_from, _g_to, (now_s - _t_start_s) / _duration_s)
