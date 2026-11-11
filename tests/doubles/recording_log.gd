## Test double for LogSink: collects (level, msg) pairs instead of logging (ADR-0009 D9).
class_name RecordingLog extends LogSink

## Each entry: {&"level": StringName, &"msg": String}.
var lines: Array[Dictionary] = []


func line(level: StringName, msg: String) -> void:
	lines.append({&"level": level, &"msg": msg})
	return
