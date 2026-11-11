## Node of a schema tree (ADR-0005 D2, Key Interfaces). Built only through the DataSchema static
## helpers (`DataSchema.int_(1, 8)`, `DataSchema.object_({...})`); never instantiate it by hand.
class_name FieldSpec extends RefCounted

enum Kind { BOOL, INT, FLOAT, STRING, ID, ENUM, NULLABLE, ARRAY, OBJECT, MAP, ONE_OF, LANG_TEXT }
## CLAMP only where the ADR says so (box.json); everything else reports an ERROR.
enum OutOfRange { ERROR, CLAMP }

## Node kind; decides which branch of DataReader.normalise handles it.
var kind: Kind
## INT / FLOAT lower bound (inclusive).
var min_value: float = -INF
## INT / FLOAT upper bound (inclusive).
var max_value: float = INF
## INT / FLOAT behaviour outside [min_value, max_value].
var out_of_range: OutOfRange = OutOfRange.ERROR
## ID: pattern the whole string must match. MAP: pattern for the keys.
var pattern: RegEx = null
## ENUM: closed list of accepted values.
var allowed: Array[StringName] = []
## ARRAY / MAP / NULLABLE element spec.
var item: FieldSpec = null
## ARRAY: minimum length.
var min_len: int = 0
## ARRAY: maximum length, -1 = unbounded.
var max_len: int = -1
## ARRAY of OBJECT: key whose value must be unique among the elements.
var unique_by: StringName = &""
## STRING: whether "" is accepted.
var allow_empty: bool = false
## OBJECT: String -> FieldSpec of mandatory keys.
var required: Dictionary = {}
## OBJECT: String -> FieldSpec of optional keys.
var optional: Dictionary = {}
## OBJECT: unknown keys are a WARNING (and kept raw) instead of an ERROR.
var open_with_warning: bool = false
## ONE_OF: key of the object whose value selects the variant.
var discriminator: String = ""
## ONE_OF: String -> FieldSpec (an OBJECT that declares the discriminator key itself).
var variants: Dictionary = {}
## Cross-file reference kind (&"fact", &"item", ...), resolved in tier B/C only (story 003).
var ref_kind: StringName = &""
## ARRAY: in release a failing element is dropped (TR-director-004).
var record_isolated: bool = false
## Free tags (e.g. "quality").
var tags: PackedStringArray = PackedStringArray()
