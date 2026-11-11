## Typed accessors for the `interaction_executed` payload (ADR-0001 D11, G-12).
## Every consumer other than system 24 must filter with `is_done`.
## Example: `if InteractionNotice.is_done(payload): open_drawer(payload[&"id"])`
class_name InteractionNotice extends RefCounted

## `resultado` values emitted by system 7 (GDD 7 rule 29).
const RESULT_DONE: StringName = &"HECHO"
const RESULT_NO_EFFECT: StringName = &"SIN_EFECTO"
const RESULT_GESTURE_REJECTED: StringName = &"GESTO_RECHAZADO"
const RESULT_SHORT_TAP: StringName = &"TOQUE_CORTO"


## True only when `payload[&"resultado"]` is exactly `HECHO` (missing key or other type: false).
static func is_done(payload: Dictionary) -> bool:
	var r: Variant = payload.get(&"resultado")
	return typeof(r) == TYPE_STRING_NAME and r == RESULT_DONE
