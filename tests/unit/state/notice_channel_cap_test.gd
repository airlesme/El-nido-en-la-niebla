extends GdUnitTestSuite
## EB-003: NoticeChannel cap, invalid callables, run_after_drain, clear_pending, tap
## (CA-15, CA-17 unit part).

const CAP: int = 8

## ErrorPolicy double that counts fail() calls.
class CountingErrors extends ErrorPolicy:
	var fails: Array[String] = []

	func fail(msg: String) -> void:
		fails.append(msg)

var _log: RecordingLog
var _errors: CountingErrors
var _ch: NoticeChannel


func before_test() -> void:
	_log = RecordingLog.new()
	_errors = CountingErrors.new()
	_ch = NoticeChannel.new(CAP, _log, _errors)


## Subscribes a counter to `topic`; returns a one-element array holding the count.
func _counter(topic: StringName) -> Array[int]:
	var c: Array[int] = [0]
	_ch.subscribe(NoticeChannel.Kind.NOTICE, topic, func(_p: Dictionary) -> void: c[0] += 1)
	return c


func _feed_loop(topic: StringName) -> void:
	_ch.subscribe(NoticeChannel.Kind.NOTICE, topic, func(_p: Dictionary) -> void: _ch.notify(topic))


# --- CA-15 -------------------------------------------------------------

func test_chain_over_cap_delivers_exactly_cap_then_drops_logs_fails_and_notifies_once() -> void:
	var loop_count: Array[int] = _counter(&"loop")
	var dropped: Array[int] = _counter(NoticeIds.NOTICES_DROPPED)
	_feed_loop(&"loop")
	_ch.notify(&"loop")
	assert_int(loop_count[0]).is_equal(CAP)
	assert_int(dropped[0]).is_equal(1)
	assert_int(_log.lines.size()).is_equal(1)
	assert_int(_errors.fails.size()).is_equal(1)
	assert_bool(_ch.is_queue_empty()).is_true()
	assert_bool(_ch.is_draining()).is_false()


func test_chain_of_exactly_cap_entries_does_not_overflow() -> void:
	var count: Array[int] = [0]
	var dropped: Array[int] = _counter(NoticeIds.NOTICES_DROPPED)
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"loop", func(_p: Dictionary) -> void:
		count[0] += 1
		if count[0] < CAP:
			_ch.notify(&"loop"))
	_ch.notify(&"loop")
	assert_int(count[0]).is_equal(CAP)
	assert_int(dropped[0]).is_equal(0)
	assert_int(_log.lines.size()).is_equal(0)
	assert_int(_errors.fails.size()).is_equal(0)


func test_chain_of_cap_plus_one_overflows_dropping_one_entry() -> void:
	var count: Array[int] = [0]
	var dropped: Array[int] = _counter(NoticeIds.NOTICES_DROPPED)
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"loop", func(_p: Dictionary) -> void:
		count[0] += 1
		if count[0] <= CAP:
			_ch.notify(&"loop"))
	_ch.notify(&"loop")
	assert_int(count[0]).is_equal(CAP)
	assert_int(dropped[0]).is_equal(1)
	assert_int(_errors.fails.size()).is_equal(1)


func test_second_overflow_in_same_drain_only_logs() -> void:
	var loop_count: Array[int] = _counter(&"loop")
	var dropped: Array[int] = _counter(NoticeIds.NOTICES_DROPPED)
	_feed_loop(&"loop")
	# Restarting the loop while notices_dropped is delivered gets a fresh budget, then overflows again.
	_ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.NOTICES_DROPPED, func(_p: Dictionary) -> void:
		_ch.notify(&"loop"))
	_ch.notify(&"loop")
	assert_int(dropped[0]).is_equal(1)
	assert_int(loop_count[0]).is_equal(CAP + CAP - 1)  # notices_dropped consumed one budget slot
	assert_int(_log.lines.size()).is_equal(2)
	assert_int(_errors.fails.size()).is_equal(1)
	assert_bool(_ch.is_queue_empty()).is_true()


func test_independent_drains_have_their_own_budget() -> void:
	var count: Array[int] = _counter(&"n")
	for i in CAP * 3:
		_ch.notify(&"n")
	assert_int(count[0]).is_equal(CAP * 3)
	assert_int(_errors.fails.size()).is_equal(0)


func test_channel_is_usable_after_overflow() -> void:
	_feed_loop(&"loop")
	_ch.notify(&"loop")
	var after: Array[int] = _counter(&"ok")
	_ch.notify(&"ok")
	assert_int(after[0]).is_equal(1)


# --- CA-17 (unit part) ---------------------------------------------------

func test_freed_subscriber_is_skipped_without_error_and_pruned() -> void:
	var node: Node = Node.new()
	var hits: Array[int] = [0]
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", func(_p: Dictionary) -> void: hits[0] += 1)
	var h: int = _ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", Callable(node, &"queue_free"))
	node.free()
	_ch.notify(&"n")
	assert_int(hits[0]).is_equal(1)
	assert_int(_ch._subs.size()).is_equal(1)
	_ch.unsubscribe(h)  # already pruned: no-op
	_ch.notify(&"n")
	assert_int(hits[0]).is_equal(2)


func test_null_callable_subscription_is_skipped_and_pruned() -> void:
	_ch.subscribe(NoticeChannel.Kind.FACT, &"x", Callable())
	_ch.push_change(&"x", 0, 1)
	assert_int(_ch._subs.size()).is_equal(0)


# --- run_after_drain / clear_pending ------------------------------------------

func test_run_after_drain_when_idle_runs_immediately() -> void:
	var ran: Array[int] = [0]
	_ch.run_after_drain(func() -> void: ran[0] += 1)
	assert_int(ran[0]).is_equal(1)


func test_run_after_drain_inside_drain_runs_once_after_drain_ends() -> void:
	var rec: Array = []
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"a", func(_p: Dictionary) -> void:
		_ch.run_after_drain(func() -> void: rec.append("job:draining=%s" % _ch.is_draining()))
		_ch.notify(&"b")
		rec.append("a"))
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"b", func(_p: Dictionary) -> void: rec.append("b"))
	_ch.notify(&"a")
	assert_array(rec).is_equal(["a", "b", "job:draining=false"])
	_ch.notify(&"b")
	assert_int(rec.size()).is_equal(4)  # job did not run a second time


func test_run_after_drain_runs_jobs_in_registration_order() -> void:
	var rec: Array = []
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"a", func(_p: Dictionary) -> void:
		_ch.run_after_drain(func() -> void: rec.append(1))
		_ch.run_after_drain(func() -> void: rec.append(2)))
	_ch.notify(&"a")
	assert_array(rec).is_equal([1, 2])


func test_run_after_drain_invalid_job_is_ignored() -> void:
	_ch.run_after_drain(Callable())
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"a", func(_p: Dictionary) -> void:
		_ch.run_after_drain(Callable()))
	_ch.notify(&"a")
	assert_bool(_ch.is_draining()).is_false()


func test_clear_pending_inside_drain_discards_queue_without_notifying() -> void:
	var later: Array[int] = _counter(&"later")
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"a", func(_p: Dictionary) -> void:
		_ch.notify(&"later")
		_ch.clear_pending())
	_ch.notify(&"a")
	assert_int(later[0]).is_equal(0)
	assert_bool(_ch.is_queue_empty()).is_true()


func test_clear_pending_when_idle_is_noop() -> void:
	_ch.clear_pending()
	assert_bool(_ch.is_queue_empty()).is_true()


# --- tap -------------------------------------------------------------------

func test_tap_sees_notice_at_enqueue_before_any_delivery() -> void:
	var rec: Array = []
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", func(_p: Dictionary) -> void: rec.append("deliver"))
	_ch.set_enqueue_tap(func(topic: StringName, payload: Dictionary) -> void: rec.append(["tap", topic, payload]))
	_ch.notify(&"n", {&"k": 1})
	assert_array(rec).is_equal([["tap", &"n", {&"k": 1}], "deliver"])


func test_tap_sees_every_chained_notice_before_it_is_delivered() -> void:
	var rec: Array = []
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"a", func(_p: Dictionary) -> void:
		rec.append("a")
		_ch.notify(&"b")
		rec.append("a-end"))
	_ch.set_enqueue_tap(func(topic: StringName, _p: Dictionary) -> void: rec.append("tap:%s" % topic))
	_ch.notify(&"a")
	assert_array(rec).is_equal(["tap:a", "a", "tap:b", "a-end"])


func test_tap_is_not_a_subscriber_and_does_not_see_fact_changes() -> void:
	var taps: Array[int] = [0]
	_ch.set_enqueue_tap(func(_t: StringName, _p: Dictionary) -> void: taps[0] += 1)
	_ch.push_change(&"x", 0, 1)
	assert_int(taps[0]).is_equal(0)
	assert_int(_ch._subs.size()).is_equal(0)


func test_tap_can_be_removed_and_invalid_tap_is_ignored() -> void:
	var taps: Array[int] = [0]
	_ch.set_enqueue_tap(func(_t: StringName, _p: Dictionary) -> void: taps[0] += 1)
	_ch.set_enqueue_tap(Callable())
	_ch.notify(&"n")
	assert_int(taps[0]).is_equal(0)
