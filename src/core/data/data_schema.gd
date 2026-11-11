## Base of every per-file schema (ADR-0005 D2.1). Subclasses implement `version()` and `root()`
## and may override `rules()`; they build the tree with the static helpers below.
## Example: `return object_({"id": id_("^P[1-6]$"), "level": int_(1, 3)})`.
@abstract class_name DataSchema extends RefCounted


## Highest schema_version this code accepts (puzzles.json = 2, others = 1).
@abstract func version() -> int


## Tree for the root object (schema_version is checked and stripped by DataReader).
@abstract func root() -> FieldSpec


## Optional semantic checks run after a clean normalisation. Default: none.
func rules() -> FileRules:
	return null


# --- builders (static, return a new FieldSpec) -----------------------------

## Boolean.
static func bool_() -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.BOOL
	return f


## Integer in [lo, hi]; read through DataReader.to_int (D4.1).
static func int_(lo: int, hi: int) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.INT
	f.min_value = lo
	f.max_value = hi
	return f


## Finite number (int or float accepted, stored as float) in [lo, hi].
static func float_(lo: float, hi: float) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.FLOAT
	f.min_value = lo
	f.max_value = hi
	return f


## String, non-empty unless `allow_empty`.
static func string_(allow_empty: bool = false) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.STRING
	f.allow_empty = allow_empty
	return f


## String that fully matches `regex`; normalised to StringName. `ref` names a cross-file reference.
static func id_(regex: String, ref: StringName = &"") -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.ID
	f.pattern = RegEx.create_from_string(regex)
	f.ref_kind = ref
	return f


## String from a closed list; normalised to StringName.
static func enum_(values: Array[StringName]) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.ENUM
	f.allowed = values
	return f


## Array of `of`, at least `lo` long; `unique_key` (ARRAY of OBJECT) must be unique.
static func array_(of: FieldSpec, lo: int = 0, unique_key: StringName = &"") -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.ARRAY
	f.item = of
	f.min_len = lo
	f.unique_by = unique_key
	return f


## Object with required and optional keys (String -> FieldSpec); unknown keys are errors.
static func object_(req: Dictionary, opt: Dictionary = {}) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.OBJECT
	f.required = req
	f.optional = opt
	return f


## Object keyed by a free but pattern-checked key set; values follow `of`.
static func map_(key_pattern: String, of: FieldSpec) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.MAP
	f.pattern = RegEx.create_from_string(key_pattern)
	f.item = of
	return f


## Either null or `of`.
static func nullable(of: FieldSpec) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.NULLABLE
	f.item = of
	return f


## Object whose `discriminator` key picks a variant (String -> OBJECT FieldSpec declaring that key).
static func one_of_(discriminator: String, variants: Dictionary) -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.ONE_OF
	f.discriminator = discriminator
	f.variants = variants
	return f


## Language map {"es": "non-empty text", ...} (ADR-0005 D7).
static func lang_text() -> FieldSpec:
	var f: FieldSpec = FieldSpec.new()
	f.kind = FieldSpec.Kind.LANG_TEXT
	return f


# --- modifiers (mutate and return the same spec) ----------------------------

## OBJECT: unknown keys become WARNINGs and are kept raw.
static func open_with_warning(spec: FieldSpec) -> FieldSpec:
	spec.open_with_warning = true
	return spec


## INT / FLOAT: out of range is clamped (WARNING) in release instead of an ERROR.
static func clamped(spec: FieldSpec) -> FieldSpec:
	spec.out_of_range = FieldSpec.OutOfRange.CLAMP
	return spec


## ARRAY: in release, an element with errors is dropped.
static func isolated(spec: FieldSpec) -> FieldSpec:
	spec.record_isolated = true
	return spec
