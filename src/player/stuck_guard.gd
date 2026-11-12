## Safety net against getting stuck or falling out of the world (ADR-0012 D8; GDD 2 D-23; TR-player-019; AC-40).
## Pure logic. The overlap query goes through `PenetrationProbe` (one call per tick, C-G01); the caller (Player, story 011)
## moves the body to `safe_pose()` when `tick` returns true, zeroes velocity, calls `TickInterpolator.reset` and logs.
## Relocation is not a `colocar`: this class does not touch pose memory or the yaw window.
## Example: `var g := StuckGuard.new(cfg, probe); g.reset(anchor); if g.tick(pos, step_len, on_floor, clock.now()): move(g.safe_pose())`.
class_name StuckGuard extends RefCounted

## Tolerance on the stuck-time comparison (seconds), so 30 ticks of 1/60 s count as 0.5 s.
const _TIME_EPS: float = 1e-6

var _cfg: PlayerConfig
var _probe: PenetrationProbe
var _anchor: Vector3 = Vector3.ZERO
var _safe: Vector3 = Vector3.ZERO
var _has_safe: bool = false
var _next_safe_at: float = 0.0
var _stuck_active: bool = false
var _stuck_since: float = 0.0
var _stuck_origin: Vector3 = Vector3.ZERO


func _init(cfg: PlayerConfig, probe: PenetrationProbe) -> void:
	_cfg = cfg
	_probe = probe


## Called by `colocar`: records the spawn anchor (fallback target), drops the safe pose and clears the stuck state.
func reset(anchor: Vector3) -> void:
	_anchor = anchor
	_has_safe = false
	_next_safe_at = 0.0
	_clear_stuck()


## True when the last safe pose exists (otherwise `safe_pose()` is the spawn anchor).
func has_safe_pose() -> bool:
	return _has_safe


## Feet position to relocate to: the last safe pose, or the anchor recorded by `reset` when there is none.
func safe_pose() -> Vector3:
	return _safe if _has_safe else _anchor


## One physics tick, after `move_and_slide`. `position` = feet, `step_len` = horizontal distance moved this tick,
## `now` = `GameClock` time in seconds. Returns true when the Player must be relocated to `safe_pose()`.
func tick(position: Vector3, step_len: float, on_floor: bool, now: float) -> bool:
	if position.y < _cfg.y_min:
		_clear_stuck()
		return true
	var penetrating: bool = _probe.is_penetrating(position + Vector3(0.0, _cfg.altura_capsula * 0.5, 0.0))
	if on_floor and not penetrating and now >= _next_safe_at:
		_safe = position
		_has_safe = true
		_next_safe_at = now + _cfg.t_pose_segura
	if not penetrating:
		_clear_stuck()
		return false
	if not _stuck_active:
		_begin_stuck(position, now)
		return false
	var moved: float = Vector2(position.x - _stuck_origin.x, position.z - _stuck_origin.z).length()
	if moved >= _cfg.eps_atasco_m or step_len >= _cfg.eps_atasco_m:
		_begin_stuck(position, now)
		return false
	if now - _stuck_since >= _cfg.t_atasco - _TIME_EPS:
		_clear_stuck()
		return true
	return false


func _begin_stuck(position: Vector3, now: float) -> void:
	_stuck_active = true
	_stuck_since = now
	_stuck_origin = position


func _clear_stuck() -> void:
	_stuck_active = false
