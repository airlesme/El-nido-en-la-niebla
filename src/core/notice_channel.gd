## Ordered, FIFO, non-reentrant dispatcher shared by GameState (3) and Settings (6).
## ADR-0001 D1/D2/D5/D6. Core only (EB-002): subscription, FIFO queue, synchronous drain.
## EB-003 adds the per-drain chained-notice cap, invalid-callable pruning, clear_pending,
## run_after_drain and the enqueue tap. EB-004 adds schema validation in notify().
## Example:
## [codeblock]
## var ch := NoticeChannel.new(64, log_sink, errors)
## var h: int = ch.subscribe(NoticeChannel.Kind.FACT, &"door_open", _on_fact)
## ch.push_change(&"door_open", false, true)  # delivered now: _on_fact(&"door_open", false, true)
## ch.unsubscribe(h)
## [/codeblock]
class_name NoticeChannel extends RefCounted

## What a subscription listens to.
enum Kind { FACT, ALL_FACTS, NOTICE }

var _max_chained: int
var _after_drain: Array[Callable] = []
var _tap: Callable = Callable()
var _log: LogSink
var _errors: ErrorPolicy
var _schema: Dictionary
var _subs: Array[Dictionary] = []  # {handle, kind, topic, cb, active}, subscription order
var _queue: Array[Dictionary] = []  # {kind, topic, a, b}; a/b = old/new or payload
var _draining: bool = false
var _pending_removal: Array[int] = []
var _next_handle: int = 1


func _init(max_chained: int, log_sink: LogSink, errors: ErrorPolicy, schema: Dictionary = {}) -> void:
	_max_chained = max_chained
	_log = log_sink
	_errors = errors
	_schema = schema


## Subscribes to one topic (fact name or notice name); `topic` is ignored for ALL_FACTS.
## Fact callbacks: `func(fact: StringName, old: Variant, new: Variant)`; notice callbacks:
## `func(payload: Dictionary)`. Returns a handle > 0. Effective from the next delivered entry.
func subscribe(kind: Kind, topic: StringName, cb: Callable) -> int:
	var handle: int = _next_handle
	_next_handle += 1
	_subs.append({&"handle": handle, &"kind": kind, &"topic": topic, &"cb": cb, &"active": true})
	return handle


## Removes a subscription. During a drain it takes effect after the entry being delivered
## (CA-16). Unknown handle: no-op.
func unsubscribe(handle: int) -> void:
	if _draining:
		if not _pending_removal.has(handle):
			_pending_removal.append(handle)
		return
	_remove_handles([handle])


## Enqueues a fact change; drains now unless already draining. The caller decides that the
## value really changed.
func push_change(fact: StringName, old: Variant, new: Variant) -> void:
	_enqueue({&"kind": Kind.FACT, &"topic": fact, &"a": old, &"b": new})


## Enqueues a named notice; drains now unless already draining. With a non-empty schema
## (`NoticeIds.SCHEMA`) an unregistered name is rejected in every build (log line; dev also
## `ErrorPolicy.fail`) and the notice is dropped. Payload keys/types are validated only when
## `ErrorPolicy.is_strict()`; an invalid payload is dropped after `fail`. Empty schema: no checks.
func notify(notice: StringName, payload: Dictionary = {}) -> void:
	if not _validate(notice, payload):
		return
	_enqueue({&"kind": Kind.NOTICE, &"topic": notice, &"a": payload, &"b": null})


## True when no entry is pending.
func is_queue_empty() -> bool:
	return _queue.is_empty()


## True while inside a synchronous drain.
func is_draining() -> bool:
	return _draining


## Discards every pending entry without notifying anyone (reset/restore). Safe inside a drain:
## the drain then ends after the entry being delivered.
func clear_pending() -> void:
	_queue.clear()


## Runs `job` (no arguments) once the current drain ends, or right now when idle.
## Jobs run in the order they were registered. An invalid callable is ignored.
func run_after_drain(job: Callable) -> void:
	if _draining:
		_after_drain.append(job)
	elif job.is_valid():
		job.call()


## Sets an observer called as `tap(notice: StringName, payload: Dictionary)` when a notice is
## enqueued, before any delivery. It is not a subscriber. Fact changes are not tapped.
## Pass an empty `Callable()` to remove it.
func set_enqueue_tap(tap: Callable) -> void:
	_tap = tap


func _validate(notice: StringName, payload: Dictionary) -> bool:
	if _schema.is_empty():
		return true
	if not _schema.has(notice):
		_log.line(LogSink.LEVEL_ERROR, "notice '%s' is not in the registry: dropped" % notice)
		_errors.fail("unregistered notice '%s'" % notice)
		return false
	if not _errors.is_strict():
		return true  # release: no schema validation
	var spec: Dictionary = _schema[notice]
	for key: Variant in payload:
		if typeof(key) != TYPE_STRING_NAME:
			return _reject(notice, "key %s is not a StringName" % str(key))
		if not spec.has(key):
			return _reject(notice, "unknown key '%s'" % key)
		var want: int = (spec[key] as Array)[0]
		var got: int = typeof(payload[key])
		if got != want:
			return _reject(notice, "key '%s' has type %d, expected %d" % [key, got, want])
	for key: Variant in spec:
		if not payload.has(key) and not (spec[key] as Array)[1]:
			return _reject(notice, "missing required key '%s'" % key)
	return true


func _reject(notice: StringName, why: String) -> bool:
	var msg: String = "invalid payload for '%s': %s" % [notice, why]
	_log.line(LogSink.LEVEL_ERROR, msg)
	_errors.fail(msg)
	return false


func _enqueue(entry: Dictionary) -> void:
	if entry[&"kind"] == Kind.NOTICE and _tap.is_valid():
		_tap.call(entry[&"topic"], entry[&"a"])
	_queue.push_back(entry)
	if not _draining:
		_drain()


func _drain() -> void:
	_draining = true
	var delivered: int = 0
	var dropped_once: bool = false
	while not _queue.is_empty():
		if delivered >= _max_chained:
			var lost: int = _queue.size()
			_queue.clear()
			_log.line(LogSink.LEVEL_ERROR, "notices dropped: %d pending (max_chained_notices=%d)" % [lost, _max_chained])
			if dropped_once:
				break  # second overflow in this drain: log only
			_errors.fail("max_chained_notices reached")
			dropped_once = true
			delivered = 0  # entries enqueued while delivering notices_dropped get a fresh budget
			_queue.push_back({&"kind": Kind.NOTICE, &"topic": NoticeIds.NOTICES_DROPPED, &"a": {}, &"b": null})
			continue
		var e: Dictionary = _queue.pop_front()
		delivered += 1
		var n: int = _subs.size()  # bound fixed first: late subscribers skip this entry
		for i in n:
			var s: Dictionary = _subs[i]  # removals are deferred, indices stay stable
			if s[&"active"] and _matches(s, e) and (s[&"cb"] as Callable).is_valid():
				if e[&"kind"] == Kind.NOTICE:
					(s[&"cb"] as Callable).call(e[&"a"])
				else:
					(s[&"cb"] as Callable).call(e[&"topic"], e[&"a"], e[&"b"])
		if not _pending_removal.is_empty():
			_remove_handles(_pending_removal)
			_pending_removal.clear()
	_prune_invalid()
	_draining = false
	_run_after_drain_jobs()


func _prune_invalid() -> void:
	for i in range(_subs.size() - 1, -1, -1):
		if not (_subs[i][&"cb"] as Callable).is_valid():
			_subs.remove_at(i)


func _run_after_drain_jobs() -> void:
	while not _after_drain.is_empty():
		var job: Callable = _after_drain.pop_front()
		if job.is_valid():
			job.call()  # may start a new drain; jobs added meanwhile run in this loop or its own


func _matches(s: Dictionary, e: Dictionary) -> bool:
	var sk: Kind = s[&"kind"]
	var ek: Kind = e[&"kind"]
	if ek == Kind.NOTICE:
		return sk == Kind.NOTICE and s[&"topic"] == e[&"topic"]
	return sk == Kind.ALL_FACTS or (sk == Kind.FACT and s[&"topic"] == e[&"topic"])


func _remove_handles(handles: Array) -> void:
	for i in range(_subs.size() - 1, -1, -1):
		if handles.has(_subs[i][&"handle"]):
			_subs.remove_at(i)
