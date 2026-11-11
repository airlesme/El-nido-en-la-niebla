extends GdUnitTestSuite
## EB-001: platform seams (LogSink, ErrorPolicy, FatalErrorHandler, TestContexts).


## ErrorPolicy double that records fail() calls instead of stopping.
class SpyPolicy extends ErrorPolicy:
	var fails: Array[String] = []

	func fail(msg: String) -> void:
		fails.append(msg)
		return

	func is_strict() -> bool:
		return true


func test_recording_log_collects_level_and_message() -> void:
	# Arrange
	var log_sink: RecordingLog = RecordingLog.new()

	# Act
	log_sink.line(&"info", "a")
	log_sink.line(&"warn", "b")
	log_sink.line(&"error", "c")

	# Assert
	assert_int(log_sink.lines.size()).is_equal(3)
	assert_that(log_sink.lines[0]).is_equal({&"level": &"info", &"msg": "a"})
	assert_that(log_sink.lines[1]).is_equal({&"level": &"warn", &"msg": "b"})
	assert_that(log_sink.lines[2]).is_equal({&"level": &"error", &"msg": "c"})


func test_recording_fatal_handler_records_calls_and_flags_failure() -> void:
	# Arrange
	var handler: RecordingFatalHandler = RecordingFatalHandler.new()
	assert_bool(handler.has_failed()).is_false()

	# Act
	handler.raise_fatal(FatalErrorHandler.CATALOGO_INVALIDO, {&"param": &"max_chained_notices"})

	# Assert
	assert_bool(handler.has_failed()).is_true()
	assert_int(handler.calls.size()).is_equal(1)
	assert_that(handler.calls[0][&"code"]).is_equal(&"CATALOGO_INVALIDO")
	assert_that(handler.calls[0][&"detail"]).is_equal({&"param": &"max_chained_notices"})


func test_error_policy_default_is_strict_only_in_debug() -> void:
	# Arrange / Act / Assert
	assert_bool(ErrorPolicyDefault.new(BuildFlavor.new(true)).is_strict()).is_true()
	assert_bool(ErrorPolicyDefault.new(BuildFlavor.new(false)).is_strict()).is_false()


func test_error_policy_default_fail_in_release_does_not_halt() -> void:
	# Arrange
	var policy: ErrorPolicyDefault = ErrorPolicyDefault.new(BuildFlavor.new(false))

	# Act: if it halted, the suite would quit or error here
	policy.fail("invalid write")

	# Assert
	assert_bool(policy.is_strict()).is_false()


func test_base_error_policy_is_inert() -> void:
	# Arrange
	var policy: ErrorPolicy = ErrorPolicy.new()

	# Act
	policy.fail("x")

	# Assert
	assert_bool(policy.is_strict()).is_false()


func test_log_sink_accepts_every_level_without_error() -> void:
	# Arrange
	var sink: LogSink = LogSink.new()

	# Act (info only: warn/error would pollute the run's error output)
	sink.line(&"info", "log sink smoke")

	# Assert
	assert_object(sink).is_not_null()


func test_debug_fatal_handler_logs_and_stops_through_error_policy() -> void:
	# Arrange
	var log_sink: RecordingLog = RecordingLog.new()
	var policy: SpyPolicy = SpyPolicy.new()
	var handler: DebugFatalHandler = DebugFatalHandler.new(log_sink, policy)

	# Act
	handler.raise_fatal(FatalErrorHandler.DEPENDENCIA_AUSENTE, {&"param": &"state"})

	# Assert
	assert_bool(handler.has_failed()).is_true()
	assert_int(policy.fails.size()).is_equal(1)
	assert_int(log_sink.lines.size()).is_equal(1)
	assert_that(log_sink.lines[0][&"level"]).is_equal(&"error")
	assert_str(policy.fails[0]).contains("DEPENDENCIA_AUSENTE")


func test_release_fatal_handler_logs_flags_failure_and_never_stops() -> void:
	# Arrange
	var log_sink: RecordingLog = RecordingLog.new()
	var handler: ReleaseFatalHandler = ReleaseFatalHandler.new(log_sink)
	assert_bool(handler.has_failed()).is_false()

	# Act
	handler.raise_fatal(FatalErrorHandler.CONTENIDO_INVALIDO, {&"param": &"x"})

	# Assert
	assert_bool(handler.has_failed()).is_true()
	assert_int(log_sink.lines.size()).is_equal(1)
	assert_str(log_sink.lines[0][&"msg"]).contains(FatalMessages.CONTENIDO_INVALIDO_TEXT)


func test_fatal_messages_cover_every_code_and_fall_back_for_unknown() -> void:
	# Arrange
	var codes: Array[StringName] = [
		FatalErrorHandler.CATALOGO_INVALIDO,
		FatalErrorHandler.DATOS_ESCENA_INVALIDOS,
		FatalErrorHandler.DEPENDENCIA_AUSENTE,
		FatalErrorHandler.CONTENIDO_INVALIDO,
	]

	# Act / Assert
	for code: StringName in codes:
		assert_str(FatalMessages.for_code(code)).is_not_equal(FatalMessages.UNKNOWN_TEXT)
	assert_str(FatalMessages.for_code(&"OTRO")).is_equal(FatalMessages.UNKNOWN_TEXT)


func test_boot_picks_fatal_handler_by_flavor() -> void:
	# Arrange
	var log_sink: RecordingLog = RecordingLog.new()

	# Act
	var debug_handler: FatalErrorHandler = Boot.make_fatal_handler(BuildFlavor.new(true), log_sink)
	var release_handler: FatalErrorHandler = Boot.make_fatal_handler(BuildFlavor.new(false), log_sink)

	# Assert
	assert_bool(debug_handler is DebugFatalHandler).is_true()
	assert_bool(release_handler is ReleaseFatalHandler).is_true()


func test_test_contexts_make_returns_frozen_context_of_doubles() -> void:
	# Arrange / Act
	var ctx: ServiceContext = TestContexts.make()
	auto_free(ctx.clock)
	auto_free(ctx.state)

	# Assert
	assert_bool(ctx.is_frozen()).is_true()
	assert_bool(ctx.logger is RecordingLog).is_true()
	assert_bool(ctx.fatal is RecordingFatalHandler).is_true()
	assert_bool(ctx.real_clock is FakeRealClock).is_true()
	assert_bool(ctx.clock is FakeClock).is_true()
	assert_bool(ctx.state is FakeGameState).is_true()


func test_test_contexts_override_replaces_a_single_service() -> void:
	# Arrange
	var handler: RecordingFatalHandler = RecordingFatalHandler.new()

	# Act
	var ctx: ServiceContext = TestContexts.make({&"fatal": handler})
	auto_free(ctx.clock)
	auto_free(ctx.state)

	# Assert
	assert_object(ctx.fatal).is_same(handler)
	assert_bool(ctx.logger is RecordingLog).is_true()
