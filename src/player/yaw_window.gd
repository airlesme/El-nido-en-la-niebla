## Accumulated turn over the last `T_giro` seconds (ADR-0012 D7; GDD 2 rule 30, F8; TR-player-017).
## Ring of `ceil(T_giro * f_fisica)` (30) values `|delta yaw per tick|` (shortest arc); `giro_acumulado` sums the ring on
## demand (no running sum, so no float drift). Pure logic. `record_tick` and `reset` are internal to the player module.
## Example: `var w := YawWindow.new(0.5, 60); w.reset(0.0); w.record_tick(0.017); w.giro_acumulado()`.
class_name YawWindow extends RefCounted

const _CEIL_EPS: float = 1e-6

var _ring: PackedFloat32Array = PackedFloat32Array()
var _pos: int = 0
var _last_yaw: float = 0.0


## `t_giro` in seconds, `f_fisica` in Hz; the ring holds at least 1 value.
func _init(t_giro: float, f_fisica: int) -> void:
	_ring.resize(maxi(ceili(maxf(t_giro, 0.0) * float(maxi(f_fisica, 1)) - _CEIL_EPS), 1))


## Number of ticks the window covers.
func capacity() -> int:
	return _ring.size()


## Internal (Player only, used by `colocar`): zeroes the window and sets the reference yaw (radians).
func reset(yaw: float) -> void:
	_ring.fill(0.0)
	_pos = 0
	_last_yaw = yaw


## Internal (Player only): stores `|shortest-arc delta|` between `yaw` and the previous tick's yaw, once per physics tick.
func record_tick(yaw: float) -> void:
	_ring[_pos] = absf(angle_difference(_last_yaw, yaw))
	_pos = (_pos + 1) % _ring.size()
	_last_yaw = yaw


## Radians turned over the last T_giro seconds (sum of the ring; 0 at rest and right after `reset`).
func giro_acumulado() -> float:
	var total: float = 0.0
	for v: float in _ring:
		total += v
	return total
