## Debug FatalErrorHandler (ADR-0009 D8 as amended 2026-11-11): logs, records the failure and
## stops through the injected ErrorPolicy (push_error + quit(1) in dev, F-X09).
## Example: `DebugFatalHandler.new(LogSink.new(), ErrorPolicyDefault.new(BuildFlavor.new(true)))`.
class_name DebugFatalHandler extends FatalErrorHandler

var _logger: LogSink
var _errors: ErrorPolicy
var _failed: bool = false


func _init(logger: LogSink, errors: ErrorPolicy) -> void:
	_logger = logger
	_errors = errors


## Logs code + detail, marks failure, then asks the ErrorPolicy to stop.
func raise_fatal(code: StringName, detail: Dictionary) -> void:
	_failed = true
	var msg: String = "FATAL %s %s" % [code, str(detail)]
	_logger.line(LogSink.LEVEL_ERROR, msg)
	_errors.fail(msg)


## True after the first raise_fatal() call.
func has_failed() -> bool:
	return _failed
