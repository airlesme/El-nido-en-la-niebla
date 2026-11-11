## CD-001: FileStore + JsonText (BOM on bytes, trailing commas, duplicate keys, missing vs empty).
extends GdUnitTestSuite

const F: String = "x/x.json"


func _store(text: String) -> MemoryFileStore:
	var s: MemoryFileStore = MemoryFileStore.new()
	s.put_text(F, text)
	return s


func _read(store: MemoryFileStore) -> Array:
	var issues: Array[DataIssue] = []
	var v: Variant = JsonText.read(store, F, F, issues)
	return [v, issues]


func test_read_valid_json_returns_tree_without_issues() -> void:
	var r: Array = _read(_store('{"a": [1, {"b": "«ñ»"}], "c": null}'))
	assert_array(r[1]).is_empty()
	assert_str(((r[0] as Dictionary)["a"][1] as Dictionary)["b"]).is_equal("«ñ»")


func test_read_bom_returns_null_and_bom_issue() -> void:
	var s: MemoryFileStore = MemoryFileStore.new()
	var b: PackedByteArray = PackedByteArray([0xEF, 0xBB, 0xBF])
	b.append_array("{}".to_utf8_buffer())
	s.put_bytes(F, b)
	var r: Array = _read(s)
	assert_object(r[0]).is_null()
	assert_int((r[1] as Array).size()).is_equal(1)
	assert_str(String((r[1][0] as DataIssue).rule)).is_equal("bom")
	assert_str((r[1][0] as DataIssue).file).is_equal(F)


func test_read_trailing_comma_in_array_returns_null_with_line() -> void:
	var r: Array = _read(_store("[1,\n2,\n]"))
	assert_object(r[0]).is_null()
	var i: DataIssue = (r[1] as Array)[0]
	assert_str(String(i.rule)).is_equal("trailing_comma")
	assert_str(i.json_path).is_equal("line 3")


func test_read_trailing_comma_in_object_returns_null() -> void:
	var r: Array = _read(_store('{"a": 1,}'))
	assert_object(r[0]).is_null()
	assert_str(String((r[1][0] as DataIssue).rule)).is_equal("trailing_comma")


func test_read_duplicate_key_returns_null_with_line() -> void:
	var r: Array = _read(_store('{\n"id": 1,\n"id": 2\n}'))
	assert_object(r[0]).is_null()
	var i: DataIssue = (r[1] as Array)[0]
	assert_str(String(i.rule)).is_equal("dup_key")
	assert_str(i.json_path).is_equal("line 3")


func test_read_same_key_in_sibling_and_nested_objects_is_not_duplicate() -> void:
	var r: Array = _read(_store('{"a": {"id": 1}, "b": {"id": 2}, "id": 3, "l": [{"id": 1}, {"id": 1}]}'))
	assert_array(r[1]).is_empty()
	assert_object(r[0]).is_not_null()


func test_read_comma_and_quote_inside_strings_are_not_misread() -> void:
	var r: Array = _read(_store('{"a": "x,]\\"y", "b": ",}"}'))
	assert_array(r[1]).is_empty()


func test_read_broken_json_returns_null_with_parse_issue_and_line() -> void:
	var r: Array = _read(_store('{\n"a": 1\n"b": 2\n}'))
	assert_object(r[0]).is_null()
	var i: DataIssue = (r[1] as Array)[0]
	assert_str(String(i.rule)).is_equal("parse")
	assert_str(i.json_path).starts_with("line ")
	assert_str(i.message).is_not_empty()


func test_read_missing_file_reports_missing() -> void:
	var issues: Array[DataIssue] = []
	var v: Variant = JsonText.read(MemoryFileStore.new(), F, F, issues)
	assert_object(v).is_null()
	assert_str(String(issues[0].rule)).is_equal("missing")


func test_read_empty_file_reports_empty_not_missing() -> void:
	var r: Array = _read(_store(""))
	assert_object(r[0]).is_null()
	assert_str(String((r[1][0] as DataIssue).rule)).is_equal("empty")


func test_read_injected_open_failure_reports_open_error() -> void:
	var s: MemoryFileStore = _store("{}")
	s.fail(F, ERR_FILE_NO_PERMISSION)
	var r: Array = _read(s)
	assert_object(r[0]).is_null()
	assert_str(String((r[1][0] as DataIssue).rule)).is_equal("open_error")


func test_parse_text_with_surviving_bom_is_rejected() -> void:
	var issues: Array[DataIssue] = []
	var v: Variant = JsonText.parse("﻿{}", F, issues)
	assert_object(v).is_null()
	assert_str(String(issues[0].rule)).is_equal("bom")


func test_parse_literal_null_root_is_not_an_error() -> void:
	var issues: Array[DataIssue] = []
	var v: Variant = JsonText.parse("null", F, issues)
	assert_object(v).is_null()
	assert_array(issues).is_empty()


func test_parse_collects_issue_and_never_throws_on_garbage() -> void:
	var issues: Array[DataIssue] = []
	assert_object(JsonText.parse("}{", F, issues)).is_null()
	assert_int(issues.size()).is_equal(1)
	assert_bool(issues[0].format().begins_with("ERROR x/x.json ")).is_true()


func test_memory_file_store_counts_each_read_as_an_access() -> void:
	var s: MemoryFileStore = _store("{}")
	_read(s)
	_read(s)
	assert_int(s.access_count).is_equal(2)
	assert_int(s.accesses_of(F)).is_equal(2)
	assert_int(s.accesses_of("other")).is_equal(0)


func test_data_result_first_error_skips_warnings() -> void:
	var r: DataResult = DataResult.new()
	assert_bool(r.has_errors()).is_false()
	assert_object(r.first_error()).is_null()
	r.issues.append(DataIssue.new(DataIssue.Severity.WARNING, F, "$", &"w", "w"))
	assert_bool(r.has_errors()).is_false()
	var e: DataIssue = DataIssue.new(DataIssue.Severity.ERROR, F, "$", &"e", "e")
	r.issues.append(e)
	assert_bool(r.has_errors()).is_true()
	assert_object(r.first_error()).is_same(e)
