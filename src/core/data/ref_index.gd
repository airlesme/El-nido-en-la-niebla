## Cross-file reference index built by DataValidator from normalised results (ADR-0005 Key Interfaces).
## Kinds: &"fact", &"content_key", &"item", ... (the `ref(kind)` of a field).
## Example: `idx.add(&"fact", &"p1_solved"); idx.has(&"fact", &"p1_solved")` is true.
class_name RefIndex extends RefCounted

var _sets: Dictionary = {} # StringName kind -> Dictionary[StringName, bool]
var _fact_values: Dictionary = {} # StringName fact -> Array[StringName] (enum values)
var _retired: Dictionary = {} # StringName id -> true
var _provided: Dictionary = {} # StringName kind -> true (a source for the kind was indexed)


## Registers `id` under `kind` (also marks the kind as provided).
func add(kind: StringName, id: StringName) -> void:
	if not _sets.has(kind):
		_sets[kind] = {}
	var ids: Dictionary = _sets[kind]
	ids[id] = true
	_provided[kind] = true


## Marks `id` as retired: it stays known (never reusable) but `is_retired` reports it.
func add_retired(id: StringName) -> void:
	_retired[id] = true


## True when `id` was added under `kind`.
func has(kind: StringName, id: StringName) -> bool:
	if not _sets.has(kind):
		return false
	var ids: Dictionary = _sets[kind]
	return ids.has(id)


## True when `id` was marked retired.
func is_retired(id: StringName) -> bool:
	return _retired.has(id)


## True when `value` is one of the enum values declared for `fact`. Unknown fact -> false.
func fact_accepts(fact: StringName, value: StringName) -> bool:
	if not _fact_values.has(fact):
		return false
	var values: Array = _fact_values[fact]
	return values.has(value)


## Declares the enum values `fact` accepts.
## TODO(ADR-0005): setter not in the ADR sketch; needed so the builder can feed `fact_accepts`.
func set_fact_values(fact: StringName, values: Array) -> void:
	var copy: Array[StringName] = []
	for v: Variant in values:
		copy.append(StringName(v))
	_fact_values[fact] = copy


## True when at least one id was indexed under `kind`, i.e. its source file was read. Refs of a kind
## nobody provides yet are not resolvable and the checker skips them.
func provides(kind: StringName) -> bool:
	return _provided.has(kind)
