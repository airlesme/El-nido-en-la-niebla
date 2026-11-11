extends GdUnitTestSuite
## GameClock skeleton (ADR-0002 D1): game time freezes while paused. Deterministic, no engine loop.


func _make_clock() -> GameClock:
	return auto_free(GameClock.new())


func test_advance_accumulates_game_time() -> void:
	# Arrange
	var clock: GameClock = _make_clock()

	# Act
	clock.advance(0.1)
	clock.advance(0.1)

	# Assert
	assert_float(clock.now()).is_equal_approx(0.2, 0.0001)
	assert_float(clock.delta()).is_equal_approx(0.1, 0.0001)


func test_advance_clamps_huge_frame_delta() -> void:
	# Arrange
	var clock: GameClock = _make_clock()

	# Act
	clock.advance(10.0)

	# Assert
	assert_float(clock.delta()).is_equal_approx(0.25, 0.0001)


func test_pause_freezes_time_until_last_holder_resumes() -> void:
	# Arrange
	var clock: GameClock = _make_clock()
	clock.pause(&"menu")
	clock.pause(&"call")

	# Act
	clock.advance(0.1)
	clock.resume(&"menu")
	clock.advance(0.1)
	var still_paused: bool = clock.is_paused()
	clock.resume(&"call")
	clock.advance(0.1)

	# Assert
	assert_bool(still_paused).is_true()
	assert_float(clock.now()).is_equal_approx(0.1, 0.0001)
	assert_bool(clock.is_paused()).is_false()


func test_resume_unknown_requester_has_no_effect() -> void:
	# Arrange
	var clock: GameClock = _make_clock()
	clock.pause(&"menu")

	# Act
	clock.resume(&"other")

	# Assert
	assert_bool(clock.is_paused()).is_true()


func test_real_clock_is_monotonic() -> void:
	# Arrange
	var real_clock: RealClock = RealClock.new()

	# Act
	var first: int = real_clock.now_ms()
	var second: int = real_clock.now_ms()

	# Assert
	assert_int(second).is_greater_equal(first)
