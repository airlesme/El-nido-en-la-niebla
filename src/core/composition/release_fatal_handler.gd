## Release FatalErrorHandler (ADR-0009 D8): logs and records; never quits.
## TODO(ADR-0009): once UiPorts exists, ask `ctx.ui.error_panel` to show
## FatalMessages.for_code(code). Not available in M1, so only the log is produced.
class_name ReleaseFatalHandler extends FatalErrorHandler

var _logger: LogSink
var _failed: bool = false


func _init(logger: LogSink) -> void:
	_logger = logger


## Logs the code, the hard-coded message and the detail; marks failure.
func raise_fatal(code: StringName, detail: Dictionary) -> void:
	_failed = true
	_logger.line(LogSink.LEVEL_ERROR, "FATAL %s: %s %s" % [code, FatalMessages.for_code(code), str(detail)])


## True after the first raise_fatal() call.
func has_failed() -> bool:
	return _failed
