extends GdUnitTestSuite
## T-U9: ordering of zone entries (ZoneEntryQueue), no engine physics.


func test_same_tick_entries_are_ordered_by_id() -> void:
	var q: ZoneEntryQueue = ZoneEntryQueue.new()
	q.record(10, &"T-PAS-2")
	q.record(10, &"T-PAS-1")
	assert_array(q.drain()).is_equal([&"T-PAS-1", &"T-PAS-2"])


func test_different_ticks_are_ordered_by_tick_before_id() -> void:
	var q: ZoneEntryQueue = ZoneEntryQueue.new()
	q.record(11, &"T-A")
	q.record(10, &"T-Z")
	q.record(12, &"T-B")
	assert_array(q.drain()).is_equal([&"T-Z", &"T-A", &"T-B"])


func test_reentry_emits_every_time() -> void:
	var q: ZoneEntryQueue = ZoneEntryQueue.new()
	q.record(5, &"T-PAS-1")
	q.record(9, &"T-PAS-1")
	q.record(9, &"T-PAS-1")
	assert_array(q.drain()).is_equal([&"T-PAS-1", &"T-PAS-1", &"T-PAS-1"])


func test_drain_empties_queue_and_empty_drain_is_empty() -> void:
	var q: ZoneEntryQueue = ZoneEntryQueue.new()
	assert_int(q.drain().size()).is_equal(0)
	q.record(1, &"T-A")
	assert_int(q.size()).is_equal(1)
	q.drain()
	assert_int(q.size()).is_equal(0)


func test_negative_and_zero_ticks_and_empty_id_are_ordered_without_error() -> void:
	var q: ZoneEntryQueue = ZoneEntryQueue.new()
	q.record(0, &"T-B")
	q.record(-1, &"T-C")
	q.record(0, &"")
	assert_array(q.drain()).is_equal([&"T-C", &"", &"T-B"])


func test_lexicographic_not_numeric_id_order() -> void:
	var q: ZoneEntryQueue = ZoneEntryQueue.new()
	q.record(3, &"T-PAS-10")
	q.record(3, &"T-PAS-2")
	assert_array(q.drain()).is_equal([&"T-PAS-10", &"T-PAS-2"])
