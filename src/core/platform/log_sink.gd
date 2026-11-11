## Single logging seam (ADR-0001 Key Interfaces, G-8; ADR-0009 D8/D9).
## Production implementation: forwards to the engine log. Tests use RecordingLog.
## Example: `ctx.logger.line(&"warn", "unknown fact 'x'")`.
class_name LogSink extends RefCounted

const LEVEL_INFO: StringName = &"info"
const LEVEL_WARN: StringName = &"warn"
const LEVEL_ERROR: StringName = &"error"


## Writes one log line. `level` is `&"info"`, `&"warn"` or `&"error"`; anything else is logged as info.
func line(level: StringName, msg: String) -> void:
	match level:
		LEVEL_ERROR:
			push_error(msg)
		LEVEL_WARN:
			push_warning(msg)
		_:
			print(msg)
