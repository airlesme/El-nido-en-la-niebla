class_name ZoneHub extends Node
## One per game scene; the only emitter of "zona activada" (`NoticeIds.ZONE_ENTERED`).
## ADR-0003 D8, TR-scene-006. Stamps each entry with `Engine.get_physics_frames()`, orders by
## (tick, ID) and emits once per entry in a deferred flush.

var _queue: ZoneEntryQueue = ZoneEntryQueue.new()
var _zones: Array[ZoneTrigger] = []
var _enabled: bool = false
var _flush_queued: bool = false
## Callable(notice: StringName, payload: Dictionary) -> void; normally `NoticeChannel.notify`.
# TODO(scene-owner): ADR-0003 does not fix how the hub receives the bus; fallback = injected
# Callable via `configure()`. Replace when the Boot/ServiceContext wiring (CP-001) is final.
var _notify: Callable = Callable()


## Injects the notice emitter (`NoticeChannel.notify`).
func configure(notify: Callable) -> void:
	_notify = notify


## Registers `zone` and applies the current enabled state to it.
func register(zone: ZoneTrigger) -> void:
	if zone == null or _zones.has(zone):
		return
	_zones.append(zone)
	zone.monitoring = _enabled
	zone.entered.connect(_on_zone_entered)


## Toggles `monitoring` on every registered zone (SceneLoader enables it at "terminada").
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	for zone: ZoneTrigger in _zones:
		if is_instance_valid(zone):
			zone.monitoring = enabled


## Whether the registered zones are currently monitoring.
func is_enabled() -> bool:
	return _enabled


func _on_zone_entered(zone_id: StringName) -> void:
	_queue.record(Engine.get_physics_frames(), zone_id)
	if not _flush_queued:
		_flush_queued = true
		_flush.call_deferred()


func _flush() -> void:
	_flush_queued = false
	for id: StringName in _queue.drain():
		if _notify.is_valid():
			_notify.call(NoticeIds.ZONE_ENTERED, {&"zona": id})
