class_name ZoneEntryQueue extends RefCounted
## Pure ordering logic of `ZoneHub` (ADR-0003 D8, TR-scene-006, T-U9). No engine access.
##
## Entries are stamped with a physics tick and a zone ID. `drain()` returns the pending IDs
## ordered by (tick, ID) with plain lexicographic ID comparison. Every entry is kept:
## re-entering a zone emits again (no deduplication across entries).

var _ticks: Array[int] = []
var _ids: Array[StringName] = []


## Records one entry of `zone_id` seen at physics tick `tick`.
func record(tick: int, zone_id: StringName) -> void:
	_ticks.append(tick)
	_ids.append(zone_id)


## Number of entries waiting to be drained.
func size() -> int:
	return _ids.size()


## Returns the pending IDs ordered by (tick, ID) and empties the queue.
func drain() -> Array[StringName]:
	var order: Array[int] = []
	for i: int in _ids.size():
		order.append(i)
	order.sort_custom(_less)
	var out: Array[StringName] = []
	for i: int in order:
		out.append(_ids[i])
	_ticks.clear()
	_ids.clear()
	return out


func _less(a: int, b: int) -> bool:
	if _ticks[a] != _ticks[b]:
		return _ticks[a] < _ticks[b]
	var ida: String = String(_ids[a])
	var idb: String = String(_ids[b])
	if ida != idb:
		return ida < idb
	return a < b
