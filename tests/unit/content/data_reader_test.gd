## CD-002: DataSchema/FieldSpec, DataReader.normalise, to_int and read_file (ADR-0005 D2, D4, D5).
extends GdUnitTestSuite

const F: String = "t/t.json"
const FULL: String = "res://assets/data/t/t.json"


## Schema under test: { puzzles: [ {id, level, seq: [int], kind, note?, ratio} ] }.
class TestSchema extends DataSchema:
	var rules_obj: FileRules = null

	func version() -> int:
		return 2

	func root() -> FieldSpec:
		var rec: FieldSpec = object_({
			"id": id_("^P[1-6]$"),
			"level": int_(1, 3),
			"seq": array_(int_(0, 9)),
			"kind": enum_([&"a", &"b"] as Array[StringName]),
			"ratio": float_(0.0, 1.0),
		}, {"note": nullable(string_())})
		return object_({"puzzles": array_(rec, 1, &"id")})

	func rules() -> FileRules:
		return rules_obj


class ErrRules extends FileRules:
	func check(_value: Variant, file: String, issues: Array[DataIssue]) -> void:
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "$", &"semantic", "rule ran"))


func _reader(debug: bool = true) -> DataReader:
	return DataReader.new(MemoryFileStore.new(), BuildFlavor.new(debug))


func _norm(spec: FieldSpec, v: Variant, debug: bool = true) -> Array:
	var issues: Array[DataIssue] = []
	var out: Variant = _reader(debug).normalise(v, spec, F, "$", issues)
	return [out, issues]


func _read(text: String, schema: DataSchema = TestSchema.new(), debug: bool = true) -> DataResult:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(FULL, text)
	return DataReader.new(store, BuildFlavor.new(debug)).read_file(DataCatalog.Entry.new(F, schema))


func _rec(id: String = "P1", extra: String = "") -> String:
	return '{"id":"%s","level":2,"seq":[1,2],"kind":"a","ratio":0.5%s}' % [id, extra]


func _paths(issues: Array[DataIssue]) -> PackedStringArray:
	var p: PackedStringArray = PackedStringArray()
	for i: DataIssue in issues:
		p.append("%s:%s" % [i.json_path, i.rule])
	return p


# --- to_int ---------------------------------------------------------------

func test_to_int_accepts_int_and_integral_float() -> void:
	var issues: Array[DataIssue] = []
	assert_int(DataReader.to_int(2, F, "a", issues)).is_equal(2)
	assert_int(DataReader.to_int(2.0, F, "a", issues)).is_equal(2)
	assert_int(DataReader.to_int(-3.0, F, "a", issues)).is_equal(-3)
	assert_int(DataReader.to_int(DataReader.MAX_SAFE_INT, F, "a", issues)).is_equal(9007199254740992)
	assert_array(issues).is_empty()


func test_to_int_rejects_non_integers_with_issue_and_zero() -> void:
	var bad: Array = [2.5, "2", true, null, NAN, INF, -INF, DataReader.MAX_SAFE_INT * 2.0, [1], {}]
	for v: Variant in bad:
		var issues: Array[DataIssue] = []
		var n: int = DataReader.to_int(v, F, "x.y", issues)
		assert_int(n).is_equal(0)
		assert_int(issues.size()).is_equal(1)
		assert_str(issues[0].json_path).is_equal("x.y")
		assert_str(String(issues[0].rule)).is_equal("type")
		assert_int(issues[0].severity).is_equal(DataIssue.Severity.ERROR)


# --- normalise ------------------------------------------------------------

func test_normalise_int_out_of_range_is_range_issue() -> void:
	var spec: FieldSpec = DataSchema.int_(1, 3)
	assert_array(_norm(spec, 1.0)[1]).is_empty()
	assert_array(_norm(spec, 3)[1]).is_empty()
	for v: Variant in [0.0, 4.0]:
		var r: Array = _norm(spec, v)
		assert_str(String((r[1] as Array)[0].rule)).is_equal("range")


func test_normalise_int_fraction_gives_single_type_issue() -> void:
	var r: Array = _norm(DataSchema.int_(1, 3), 2.5)
	assert_int((r[1] as Array).size()).is_equal(1)


func test_normalise_float_accepts_int_and_rejects_non_finite_and_range() -> void:
	var spec: FieldSpec = DataSchema.float_(0.0, 1.0)
	var ok: Array = _norm(spec, 1)
	assert_float(ok[0]).is_equal(1.0)
	assert_array(ok[1]).is_empty()
	for v: Variant in [INF, NAN, "1", 1.5, -0.1, true]:
		assert_int((_norm(spec, v)[1] as Array).size()).is_equal(1)


func test_normalise_id_and_enum_produce_string_name() -> void:
	var id: Array = _norm(DataSchema.id_("^P[1-6]$"), "P3")
	assert_int(typeof(id[0])).is_equal(TYPE_STRING_NAME)
	assert_array(id[1]).is_empty()
	var en: Array = _norm(DataSchema.enum_([&"a", &"b"] as Array[StringName]), "b")
	assert_int(typeof(en[0])).is_equal(TYPE_STRING_NAME)
	assert_array(en[1]).is_empty()


func test_normalise_id_pattern_must_match_whole_string() -> void:
	assert_int((_norm(DataSchema.id_("P[1-6]"), "P1x")[1] as Array).size()).is_equal(1)
	assert_int((_norm(DataSchema.id_("^P[1-6]$"), "P7")[1] as Array).size()).is_equal(1)
	assert_int((_norm(DataSchema.id_("^P[1-6]$"), 3)[1] as Array).size()).is_equal(1)


func test_normalise_enum_rejects_unknown_and_non_string() -> void:
	var spec: FieldSpec = DataSchema.enum_([&"a"] as Array[StringName])
	assert_int((_norm(spec, "z")[1] as Array).size()).is_equal(1)
	assert_int((_norm(spec, 1)[1] as Array).size()).is_equal(1)
	assert_int((_norm(spec, "")[1] as Array).size()).is_equal(1)


func test_normalise_int_array_is_typed_array_of_int() -> void:
	var r: Array = _norm(DataSchema.array_(DataSchema.int_(0, 9)), [1.0, 2.0, 3.0])
	var out: Array = r[0]
	assert_bool(out.is_typed()).is_true()
	assert_int(out.get_typed_builtin()).is_equal(TYPE_INT)
	var expected: Array[int] = [1, 2, 3]
	assert_bool(out == expected).is_true()


func test_normalise_id_array_is_typed_string_name_and_object_array_typed_dictionary() -> void:
	var ids: Array = _norm(DataSchema.array_(DataSchema.id_("^a$")), ["a"])[0]
	assert_int(ids.get_typed_builtin()).is_equal(TYPE_STRING_NAME)
	var objs: Array = _norm(DataSchema.array_(DataSchema.object_({})), [{}])[0]
	assert_int(objs.get_typed_builtin()).is_equal(TYPE_DICTIONARY)


func test_normalise_array_length_bounds_and_type() -> void:
	var spec: FieldSpec = DataSchema.array_(DataSchema.int_(0, 9), 2)
	assert_str(String((_norm(spec, [1])[1] as Array)[0].rule)).is_equal("length")
	assert_array(_norm(spec, [1, 2])[1]).is_empty()
	assert_str(String((_norm(spec, "x")[1] as Array)[0].rule)).is_equal("type")
	spec.max_len = 2
	assert_str(String((_norm(spec, [1, 2, 3])[1] as Array)[0].rule)).is_equal("length")


func test_normalise_array_unique_by_reports_dup_id_with_path() -> void:
	var spec: FieldSpec = DataSchema.array_(DataSchema.object_({"id": DataSchema.string_()}), 0, &"id")
	var r: Array = _norm(spec, [{"id": "a"}, {"id": "b"}, {"id": "a"}])
	var issues: Array = r[1]
	assert_int(issues.size()).is_equal(1)
	assert_str((issues[0] as DataIssue).json_path).is_equal("$[2].id")
	assert_str(String((issues[0] as DataIssue).rule)).is_equal("dup_id")


func test_normalise_object_missing_and_unknown_keys_have_paths() -> void:
	var spec: FieldSpec = DataSchema.object_({"a": DataSchema.int_(0, 5)}, {"b": DataSchema.bool_()})
	var r: Array = _norm(spec, {"b": true, "zzz": 1})
	assert_array(_paths(r[1])).contains_exactly(["a:required", "zzz:unknown_key"])


func test_normalise_object_open_with_warning_keeps_unknown_as_warning() -> void:
	var spec: FieldSpec = DataSchema.open_with_warning(DataSchema.object_({}))
	var r: Array = _norm(spec, {"extra": 1})
	var issues: Array = r[1]
	assert_int((issues[0] as DataIssue).severity).is_equal(DataIssue.Severity.WARNING)
	assert_bool((r[0] as Dictionary).has("extra")).is_true()


func test_normalise_nullable_string_bool_and_lang_text() -> void:
	var nul: FieldSpec = DataSchema.nullable(DataSchema.string_())
	assert_array(_norm(nul, null)[1]).is_empty()
	assert_int((_norm(nul, "")[1] as Array).size()).is_equal(1)
	assert_int((_norm(DataSchema.string_(true), "")[1] as Array).size()).is_equal(0)
	assert_int((_norm(DataSchema.bool_(), 1)[1] as Array).size()).is_equal(1)
	var lt: FieldSpec = DataSchema.lang_text()
	assert_array(_norm(lt, {"es": "«Sigo aquí.»"})[1]).is_empty()
	assert_int((_norm(lt, {})[1] as Array).size()).is_equal(1)
	assert_int((_norm(lt, {"es": ""})[1] as Array).size()).is_equal(1)
	assert_int((_norm(lt, "x")[1] as Array).size()).is_equal(1)


func test_normalise_map_and_one_of() -> void:
	var m: FieldSpec = DataSchema.map_("^P[1-6]$", DataSchema.int_(0, 9))
	var r: Array = _norm(m, {"P1": 2.0, "X": 1.0})
	assert_array(_paths(r[1])).contains_exactly(["X:key"])
	var one: FieldSpec = DataSchema.one_of_("type", {
		"set": DataSchema.object_({"type": DataSchema.enum_([&"set"] as Array[StringName]), "v": DataSchema.int_(0, 9)}),
	})
	assert_array(_norm(one, {"type": "set", "v": 3.0})[1]).is_empty()
	assert_str(String((_norm(one, {"type": "nope"})[1] as Array)[0].rule)).is_equal("variant")
	assert_str(String((_norm(one, {"type": "set"})[1] as Array)[0].rule)).is_equal("required")


func test_normalise_clamp_only_in_release_otherwise_error() -> void:
	var spec: FieldSpec = DataSchema.clamped(DataSchema.int_(0, 10))
	var rel: Array = _norm(spec, 15.0, false)
	assert_int(rel[0]).is_equal(10)
	assert_int(((rel[1] as Array)[0] as DataIssue).severity).is_equal(DataIssue.Severity.WARNING)
	var dbg: Array = _norm(spec, 15.0, true)
	assert_int(((dbg[1] as Array)[0] as DataIssue).severity).is_equal(DataIssue.Severity.ERROR)


func test_normalise_isolated_array_drops_bad_element_in_release_only() -> void:
	var spec: FieldSpec = DataSchema.isolated(DataSchema.array_(DataSchema.int_(0, 9)))
	var rel: Array = _norm(spec, [1.0, 99.0, 2.0], false)
	var expected: Array[int] = [1, 2]
	assert_bool((rel[0] as Array) == expected).is_true()
	assert_int((rel[1] as Array).size()).is_equal(1)
	var dbg: Array = _norm(spec, [1.0, 99.0, 2.0], true)
	assert_int((dbg[0] as Array).size()).is_equal(3)


# --- read_file ------------------------------------------------------------

func test_read_file_valid_normalises_and_strips_schema_version() -> void:
	var r: DataResult = _read('{"schema_version": 2, "puzzles": [%s, %s]}' % [_rec("P1"), _rec("P2")])
	assert_array(r.issues).is_empty()
	var v: Dictionary = r.value
	assert_bool(v.has("schema_version")).is_false()
	var puzzles: Array = v["puzzles"]
	assert_int(puzzles.size()).is_equal(2)
	var p0: Dictionary = puzzles[0]
	assert_int(typeof(p0["id"])).is_equal(TYPE_STRING_NAME)
	assert_int(typeof(p0["level"])).is_equal(TYPE_INT)
	assert_int(typeof(p0["kind"])).is_equal(TYPE_STRING_NAME)
	assert_int((p0["seq"] as Array).get_typed_builtin()).is_equal(TYPE_INT)
	assert_bool(p0.has("note")).is_false()


func test_read_file_path_of_missing_required_key_in_record() -> void:
	var r: DataResult = _read('{"schema_version": 2, "puzzles": [%s, %s, {"id":"P3","level":1,"seq":[],"ratio":0}]}'
			% [_rec("P1"), _rec("P2")])
	assert_array(_paths(r.issues)).contains_exactly(["puzzles[2].kind:required"])


func test_read_file_collects_all_problems_without_stopping() -> void:
	var r: DataResult = _read('{"schema_version": 2, "puzzles": [{"id":"P9","level":7,"seq":[1.5],"kind":"z","ratio":2,"bogus":1}, %s]}'
			% _rec("P1", ',"note":""'))
	assert_array(_paths(r.issues)).contains_exactly_in_any_order([
		"puzzles[0].id:pattern", "puzzles[0].level:range", "puzzles[0].seq[0]:type",
		"puzzles[0].kind:enum", "puzzles[0].ratio:range", "puzzles[0].bogus:unknown_key",
		"puzzles[1].note:empty",
	])
	assert_bool(r.has_errors()).is_true()


func test_read_file_duplicate_id_reports_path() -> void:
	var r: DataResult = _read('{"schema_version": 2, "puzzles": [%s, %s]}' % [_rec("P1"), _rec("P1")])
	assert_array(_paths(r.issues)).contains_exactly(["puzzles[1].id:dup_id"])


func test_read_file_schema_version_missing_is_issue_and_not_thrown() -> void:
	var r: DataResult = _read('{"puzzles": []}')
	assert_array(_paths(r.issues)).contains_exactly(["schema_version:required"])
	assert_object(r.value).is_null()


func test_read_file_schema_version_not_integer_is_issue() -> void:
	for raw: String in ['"2"', "2.5", "true", "null", "[2]", "1e99999"]:
		var r: DataResult = _read('{"schema_version": %s, "puzzles": []}' % raw)
		assert_array(_paths(r.issues)).contains_exactly(["schema_version:type"])
		assert_object(r.value).is_null()


func test_read_file_schema_version_newer_or_older_is_version_issue() -> void:
	for ver: String in ["3", "1", "0", "-1"]:
		var r: DataResult = _read('{"schema_version": %s, "puzzles": [%s]}' % [ver, _rec()])
		assert_array(_paths(r.issues)).contains_exactly(["schema_version:version"])
		assert_object(r.value).is_null()


func test_read_file_schema_version_integral_float_is_accepted() -> void:
	var r: DataResult = _read('{"schema_version": 2.0, "puzzles": [%s]}' % _rec())
	assert_array(r.issues).is_empty()


func test_read_file_non_object_root_and_parse_error_and_missing_file() -> void:
	assert_str(String(_read("[1]").issues[0].rule)).is_equal("root")
	assert_str(String(_read("{").issues[0].rule)).is_equal("parse")
	var r: DataResult = DataReader.new(MemoryFileStore.new(), BuildFlavor.new(true)).read_file(
			DataCatalog.Entry.new(F, TestSchema.new()))
	assert_str(String(r.issues[0].rule)).is_equal("missing")
	assert_object(r.value).is_null()


func test_read_file_non_finite_number_is_rejected() -> void:
	var r: DataResult = _read('{"schema_version": 2, "puzzles": [{"id":"P1","level":1,"seq":[],"kind":"a","ratio":1e99999}]}')
	assert_array(_paths(r.issues)).contains_exactly(["puzzles[0].ratio:type"])


func test_read_file_file_rules_run_only_after_clean_normalisation() -> void:
	var schema: TestSchema = TestSchema.new()
	schema.rules_obj = ErrRules.new()
	var ok: DataResult = _read('{"schema_version": 2, "puzzles": [%s]}' % _rec(), schema)
	assert_array(_paths(ok.issues)).contains_exactly(["$:semantic"])
	var bad: DataResult = _read('{"schema_version": 2, "puzzles": []}', schema)
	assert_array(_paths(bad.issues)).contains_exactly(["puzzles:length"])


func test_read_file_reads_the_store_once() -> void:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(FULL, '{"schema_version": 2, "puzzles": [%s]}' % _rec())
	DataReader.new(store, BuildFlavor.new(true)).read_file(DataCatalog.Entry.new(F, TestSchema.new()))
	assert_int(store.accesses_of(FULL)).is_equal(1)
