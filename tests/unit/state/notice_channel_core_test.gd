extends GdUnitTestSuite
## EB-002: NoticeChannel core (CA-09, CA-10, CA-12, CA-16).

var _ch: NoticeChannel
var _rec: Array = []


func before_test() -> void:
	_ch = NoticeChannel.new(64, RecordingLog.new(), ErrorPolicy.new())
	_rec = []


func _fact_cb(tag: String) -> Callable:
	return func(fact: StringName, old: Variant, new: Variant) -> void:
		_rec.append([tag, fact, old, new])


func _notice_cb(tag: String) -> Callable:
	return func(payload: Dictionary) -> void:
		_rec.append([tag, payload])


func test_notice_without_subscribers_is_not_received_by_late_subscriber() -> void:
	_ch.notify(&"n1")
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"n1", _notice_cb("A"))
	assert_int(_rec.size()).is_equal(0)
	assert_bool(_ch.is_queue_empty()).is_true()
	assert_bool(_ch.is_draining()).is_false()


func test_fact_change_delivered_once_with_name_old_new() -> void:
	_ch.subscribe(NoticeChannel.Kind.FACT, &"x", _fact_cb("A"))
	_ch.push_change(&"x", 1, 2)
	assert_array(_rec).is_equal([["A", &"x", 1, 2]])


func test_notice_delivers_payload_and_empty_dict_by_default() -> void:
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", _notice_cb("A"))
	_ch.notify(&"n", {&"k": 5})
	_ch.notify(&"n")
	assert_array(_rec).is_equal([["A", {&"k": 5}], ["A", {}]])


func test_subscribers_receive_in_subscription_order() -> void:
	_ch.subscribe(NoticeChannel.Kind.FACT, &"x", _fact_cb("A"))
	_ch.subscribe(NoticeChannel.Kind.ALL_FACTS, &"", _fact_cb("B"))
	_ch.push_change(&"x", 0, 1)
	assert_array(_rec).is_equal([["A", &"x", 0, 1], ["B", &"x", 0, 1]])


func test_successive_changes_arrive_in_occurrence_order() -> void:
	_ch.subscribe(NoticeChannel.Kind.ALL_FACTS, &"", _fact_cb("A"))
	_ch.push_change(&"x", 0, 1)
	_ch.push_change(&"y", 0, 1)
	_ch.push_change(&"x", 1, 2)
	assert_array(_rec).is_equal([["A", &"x", 0, 1], ["A", &"y", 0, 1], ["A", &"x", 1, 2]])


func test_fact_subscriber_ignores_other_facts_and_notices() -> void:
	_ch.subscribe(NoticeChannel.Kind.FACT, &"x", _fact_cb("A"))
	_ch.push_change(&"y", 0, 1)
	_ch.notify(&"x")
	assert_int(_rec.size()).is_equal(0)


func test_notice_subscriber_ignores_facts_and_other_notices() -> void:
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", _notice_cb("A"))
	_ch.push_change(&"n", 0, 1)
	_ch.notify(&"other")
	assert_int(_rec.size()).is_equal(0)


func test_entries_enqueued_during_drain_run_after_current_entry_fifo() -> void:
	var ch: NoticeChannel = _ch
	var rec: Array = _rec
	ch.subscribe(NoticeChannel.Kind.NOTICE, &"a", func(_p: Dictionary) -> void:
		rec.append("a-start")
		ch.notify(&"b")
		rec.append("a-end:%s" % ch.is_draining()))
	ch.subscribe(NoticeChannel.Kind.NOTICE, &"b", func(_p: Dictionary) -> void: rec.append("b"))
	ch.notify(&"a")
	assert_array(rec).is_equal(["a-start", "a-end:true", "b"])
	assert_bool(ch.is_draining()).is_false()


func test_unsubscribe_during_delivery_blocks_later_entries_only() -> void:
	var ch: NoticeChannel = _ch
	var rec: Array = _rec
	var handles: Array[int] = [0]
	handles[0] = ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", func(_p: Dictionary) -> void:
		rec.append("self")
		ch.unsubscribe(handles[0]))
	ch.notify(&"n")
	ch.notify(&"n")
	assert_array(rec).is_equal(["self"])


func test_unsubscribe_applies_after_current_entry() -> void:
	var ch: NoticeChannel = _ch
	var rec: Array = _rec
	var handles: Array[int] = [0]
	ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", func(_p: Dictionary) -> void:
		ch.unsubscribe(handles[0]))
	handles[0] = ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", _notice_cb("B"))
	ch.notify(&"n")
	ch.notify(&"n")
	assert_int(rec.size()).is_equal(1)


func test_subscribe_during_delivery_valid_from_next_entry() -> void:
	var ch: NoticeChannel = _ch
	var rec: Array = _rec
	var cb_late: Callable = _notice_cb("late")
	ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", func(_p: Dictionary) -> void:
		ch.subscribe(NoticeChannel.Kind.NOTICE, &"n", cb_late))
	ch.notify(&"n")
	assert_int(rec.size()).is_equal(0)
	ch.notify(&"n")
	assert_int(rec.size()).is_equal(1)


func test_unsubscribe_unknown_handle_is_noop() -> void:
	var h: int = _ch.subscribe(NoticeChannel.Kind.FACT, &"x", _fact_cb("A"))
	_ch.unsubscribe(9999)
	_ch.unsubscribe(0)
	_ch.unsubscribe(-1)
	_ch.push_change(&"x", 0, 1)
	assert_int(_rec.size()).is_equal(1)
	_ch.unsubscribe(h)
	_ch.unsubscribe(h)
	_ch.push_change(&"x", 1, 2)
	assert_int(_rec.size()).is_equal(1)


func test_subscribe_returns_distinct_positive_handles() -> void:
	var a: int = _ch.subscribe(NoticeChannel.Kind.FACT, &"x", _fact_cb("A"))
	var b: int = _ch.subscribe(NoticeChannel.Kind.FACT, &"x", _fact_cb("B"))
	assert_int(a).is_greater(0)
	assert_int(b).is_greater(a)
