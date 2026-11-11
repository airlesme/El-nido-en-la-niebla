## Ordered, FIFO, non-reentrant dispatcher shared by GameState (3) and Settings (6).
## ADR-0001 D1/D2/D5/D6. Core only (EB-002): subscription, FIFO queue, synchronous drain.
## The chained-notice cap, clear_pending, run_after_drain and the enqueue tap are EB-003;
## schema validation is EB-004.
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


## Enqueues a named notice; drains now unless already draining.
func notify(notice: StringName, payload: Dictionary = {}) -> void:
	_enqueue({&"kind": Kind.NOTICE, &"topic": notice, &"a": payload, &"b": null})


## True when no entry is pending.
func is_queue_empty() -> bool:
	return _queue.is_empty()


## True while inside a synchronous drain.
func is_draining() -> bool:
	return _draining


func _enqueue(entry: Dictionary) -> void:
	_queue.push_back(entry)
	if not _draining:
		_drain()


func _drain() -> void:
	_draining = true
	while not _queue.is_empty():
		var e: Dictionary = _queue.pop_front()
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
	_draining = false


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
