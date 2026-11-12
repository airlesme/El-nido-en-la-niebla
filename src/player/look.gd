## Pure look maths of the player (GDD 2 rules 13-15, F4; ADR-0012 D2 «Look is not interpolated», D4; TR-player-007).
## Engine-free: no node, no clock. Holds `yaw` and `pitch` in RADIANS (C-R20). The delta is applied 1:1 in the frame
## it is consumed (no `dt`, no smoothing: C-X10), so the same physical turn gives the same result at any fps (AC-12).
## Roll does not exist here: the caller builds `Look.basis` from `yaw` and `pitch` only. The body is never rotated (C-X13).
## Yaw: rotation about +Y of Godot's `Basis(Vector3.UP, yaw)`, 0 looks along -Z, wrapped to [-PI, PI). Pitch: + = up.
## Sensitivity and vertical inversion are applied by Input (GDD 2 F4 variables), so they are not repeated here.
## OI-3 (sign convention of `consume_look_delta()`), decided here: input x = +right, y = +up (degrees). Godot yaw grows
## to the LEFT (counter-clockwise from above), hence `INPUT_SIGN.x = -1`. `apply()` itself takes angles already in the
## Godot convention (AC-11 adds +5 deg to yaw 179 deg and expects -176 deg); `apply_input_deg()` does the conversion.
## TODO(ADR-0006): confirm with its owner that `consume_look_delta()` is +right/+up (owner: lead-programmer).
## Example per frame: `look.apply_input_deg(input.look_delta_deg())`, then `%Look.basis = look.to_basis()`.
class_name Look extends RefCounted

## Input (+right, +up, degrees) -> Godot convention (+left, +up) factor per axis (OI-3).
const INPUT_SIGN: Vector2 = Vector2(-1.0, 1.0)

## Yaw in radians, wrapped to [-PI, PI).
var yaw: float = 0.0
## Pitch in radians, within +-`_pitch_max`.
var pitch: float = 0.0

var _pitch_max: float = 0.0


## `pitch_max` in radians (`PlayerConfig.pitch_max`); a non-finite or negative value falls back to 0 (no pitch) with a log.
func _init(pitch_max: float) -> void:
	if not is_finite(pitch_max) or pitch_max < 0.0:
		push_warning("Look: invalid pitch_max %s, using 0" % [pitch_max])
		pitch_max = 0.0
	_pitch_max = pitch_max


## Wraps an angle in radians to [-PI, PI).
static func wrap_yaw(a: float) -> float:
	return wrapf(a, -PI, PI)


## True when both components of `d` are finite.
static func is_finite_delta(d: Vector2) -> bool:
	return is_finite(d.x) and is_finite(d.y)


## F4: adds a delta (radians, Godot convention: +yaw left, +pitch up) to the orientation, wraps yaw and clamps pitch.
## A non-finite delta is discarded with one log line and returns false (AC-14); otherwise returns true.
func apply(d_yaw: float, d_pitch: float) -> bool:
	if not is_finite(d_yaw) or not is_finite(d_pitch):
		push_warning("Look: non-finite look delta (%s, %s) discarded" % [d_yaw, d_pitch])
		return false
	yaw = wrap_yaw(yaw + d_yaw)
	pitch = clampf(pitch + d_pitch, -_pitch_max, _pitch_max)
	return true


## Applies a `consume_look_delta()` value (degrees, x +right, y +up) at the frontier: sanitises, converts with
## `deg_to_rad` and `INPUT_SIGN`, then `apply()`. Returns false when the delta was discarded.
func apply_input_deg(delta_deg: Vector2) -> bool:
	if not is_finite_delta(delta_deg):
		push_warning("Look: non-finite look delta %s discarded" % [delta_deg])
		return false
	return apply(deg_to_rad(delta_deg.x) * INPUT_SIGN.x, deg_to_rad(delta_deg.y) * INPUT_SIGN.y)


## Sets the orientation directly (radians), wrapping yaw and clamping pitch (e.g. `colocar`); non-finite values are ignored.
func set_orientation(new_yaw: float, new_pitch: float) -> void:
	if not is_finite(new_yaw) or not is_finite(new_pitch):
		push_warning("Look: non-finite orientation (%s, %s) ignored" % [new_yaw, new_pitch])
		return
	yaw = wrap_yaw(new_yaw)
	pitch = clampf(new_pitch, -_pitch_max, _pitch_max)


## Basis of the `Look` node: yaw about +Y then pitch about local X. Roll is never written.
func to_basis() -> Basis:
	return Basis.from_euler(Vector3(pitch, yaw, 0.0), EULER_ORDER_YXZ)
