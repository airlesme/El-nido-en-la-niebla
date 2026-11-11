## Schema of `assets/data/state/flags.json` (ADR-0005 D2 table, ADR-0001 D7/D8). Owned by system 3.
## Shape: `{schema_version: 1, max_chained_notices: INT 8-256, facts: [{name, type, initial, owner,
## range?, values?, derive?}]}` with exactly `FACT_COUNT` facts. `type` selects the variant:
## `bool` (optional `derive`), `int` (mandatory `range` [lo, hi]) or `enum` (mandatory `values`;
## `initial` is a String or null = "sin fijar").
## `derive` is not fixed by ADR-0001/0005: it is an ARRAY of bool fact names whose conjunction is the
## fact (`caja_completa = caja_c1 AND ... AND caja_c4`). TODO(ADR-0001): confirm the form of `derive`
## (ADR-fallback chosen by EB-005; the recomputation itself belongs to story EB-010).
## Example: `var entry := DataCatalog.Entry.new("state/flags.json", FlagsSchema.new())`.
class_name FlagsSchema extends DataSchema

## Exactly the 20 facts of slice D.2 (GDD 3 rule 1).
const FACT_COUNT: int = 20
## Bounds of `max_chained_notices` (ADR-0001 D6).
const MAX_CHAINED_MIN: int = 8
const MAX_CHAINED_MAX: int = 256
## Pattern of a fact name. Wider than ADR-0005 D2 (`^[a-z][a-z0-9_]*$`): slice IDs such as `tarjeta_B`
## and `pos_L` keep their capitals. TODO(ADR-0005): widen the D2 table row (ADR-fallback of EB-005).
const NAME_PATTERN: String = "^[a-z][a-zA-Z0-9_]*$"
## Bounds accepted for an int fact's `range` ends and `initial`.
const INT_LIMIT: int = 1000000


## Semantic checks a FieldSpec tree cannot express: initial vs type/range/values, unique enum
## values, derive inputs declared (existing bool facts, not itself).
class FlagsRules extends FileRules:
	func check(value: Variant, file: String, issues: Array[DataIssue]) -> void:
		var root: Dictionary = value
		var facts: Array = root["facts"]
		var by_name: Dictionary = {}
		for f: Variant in facts:
			var d: Dictionary = f
			by_name[d["name"]] = d
		for i: int in facts.size():
			var d: Dictionary = facts[i]
			var p: String = "facts[%d]" % i
			match str(d["type"]):
				"int":
					_check_int(d, file, p, issues)
				"enum":
					_check_enum(d, file, p, issues)
				"bool":
					_check_bool(d, by_name, file, p, issues)


	func _check_int(d: Dictionary, file: String, p: String, issues: Array[DataIssue]) -> void:
		var rng: Array = d["range"]
		var lo: int = rng[0]
		var hi: int = rng[1]
		if lo > hi:
			issues.append(_err(file, p + ".range", &"range", "range [%d, %d] is empty" % [lo, hi]))
			return
		var ini: int = d["initial"]
		if ini < lo or ini > hi:
			issues.append(_err(file, p + ".initial", &"range", "initial %d outside [%d, %d]" % [ini, lo, hi]))


	func _check_enum(d: Dictionary, file: String, p: String, issues: Array[DataIssue]) -> void:
		var values: Array = d["values"]
		var seen: Dictionary = {}
		for v: Variant in values:
			if seen.has(v):
				issues.append(_err(file, p + ".values", &"dup_id", "duplicate value %s" % v))
			seen[v] = true
		var ini: Variant = d["initial"]
		if ini != null and not seen.has(ini):
			issues.append(_err(file, p + ".initial", &"enum", "initial %s not in values" % ini))


	func _check_bool(d: Dictionary, by_name: Dictionary, file: String, p: String,
			issues: Array[DataIssue]) -> void:
		if not d.has("derive"):
			return
		var inputs: Array = d["derive"]
		for n: Variant in inputs:
			if n == d["name"]:
				issues.append(_err(file, p + ".derive", &"ref", "fact derives from itself"))
			elif not by_name.has(n) or str((by_name[n] as Dictionary)["type"]) != "bool":
				issues.append(_err(file, p + ".derive", &"ref", "%s is not a declared bool fact" % n))


	static func _err(file: String, path: String, rule: StringName, msg: String) -> DataIssue:
		return DataIssue.new(DataIssue.Severity.ERROR, file, path, rule, msg)


func version() -> int:
	return 1


func root() -> FieldSpec:
	var facts: FieldSpec = array_(one_of_("type", {
		"bool": object_({
			"name": id_(NAME_PATTERN), "type": enum_([&"bool"] as Array[StringName]),
			"initial": bool_(), "owner": int_(1, 99),
		}, {"derive": array_(id_(NAME_PATTERN), 1)}),
		"int": object_({
			"name": id_(NAME_PATTERN), "type": enum_([&"int"] as Array[StringName]),
			"initial": int_(-INT_LIMIT, INT_LIMIT), "owner": int_(1, 99),
			"range": _range_spec(),
		}),
		"enum": object_({
			"name": id_(NAME_PATTERN), "type": enum_([&"enum"] as Array[StringName]),
			"initial": nullable(string_()), "owner": int_(1, 99),
			"values": array_(string_(), 1),
		}),
	}), FACT_COUNT, &"name")
	facts.max_len = FACT_COUNT
	return object_({
		"max_chained_notices": int_(MAX_CHAINED_MIN, MAX_CHAINED_MAX),
		"facts": facts,
	})


func rules() -> FileRules:
	return FlagsRules.new()


static func _range_spec() -> FieldSpec:
	var r: FieldSpec = array_(int_(-INT_LIMIT, INT_LIMIT), 2)
	r.max_len = 2
	return r
