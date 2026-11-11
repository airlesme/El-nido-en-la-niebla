## Test double for FatalErrorHandler: appends (code, detail) to `calls`, never stops (ADR-0009 D8/D9).
class_name RecordingFatalHandler extends FatalErrorHandler

## Each entry: {&"code": StringName, &"detail": Dictionary}.
var calls: Array[Dictionary] = []


func raise_fatal(code: StringName, detail: Dictionary) -> void:
	calls.append({&"code": code, &"detail": detail})


func has_failed() -> bool:
	return not calls.is_empty()
