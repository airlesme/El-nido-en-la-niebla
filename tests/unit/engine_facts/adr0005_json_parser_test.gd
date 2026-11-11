extends GdUnitTestSuite
# Verifica NS-n de ADR-0005 en Godot 4.7.2 (S-0005-A casos A2-A6, A8, A9 (parte editor), A11, A12).
## A1 (tipado de numeros JSON) ya esta cubierto por V-ENG-3 de ADR-0001: adr0001_json_roundtrip_test.gd.
## A7 (export + .pck), A10 (argumentos de linea de comandos) y A9 en --export-* quedan NEEDS_MANUAL:
## exigen plantillas de exportacion / un proceso aparte.

const TMP_PATH: String = "user://adr0005_spike_tmp.json"


func _parse(text: String) -> Dictionary:
	var j: JSON = JSON.new()
	var err: Error = j.parse(text)
	return {"err": err, "line": j.get_error_line(), "msg": j.get_error_message(), "data": j.data}


func test_a2_malformed_json_reports_error_line_and_message() -> void:
	# Arrange: missing closing brace at line 7
	var text: String = "{\n  \"a\": 1,\n  \"b\": [1, 2],\n  \"c\": {\n    \"d\": 4\n  }\n  \n"

	# Act
	var r: Dictionary = _parse(text)
	var via_string: Variant = JSON.parse_string(text)
	print("A2 err=", r["err"], " line=", r["line"], " msg='", r["msg"], "' parse_string=", via_string)

	# Assert
	assert_int(r["err"]).is_equal(ERR_PARSE_ERROR)
	assert_int(r["line"]).is_greater(0)
	assert_str(r["msg"]).is_not_empty()
	assert_that(via_string).is_null()


func test_a3_duplicate_keys_last_value_wins_silently() -> void:
	# Arrange / Act
	var r: Dictionary = _parse("{\"id\": 1, \"id\": 2}")
	print("A3 err=", r["err"], " data=", r["data"])

	# Assert: observation (ADR D5.3 keeps the rule either way)
	assert_int(r["err"]).is_equal(OK)
	assert_int(r["data"].size()).is_equal(1)
	print("A3 value kept = ", r["data"]["id"])
	assert_float(r["data"]["id"]).is_equal(2.0)


func test_a4_non_standard_syntax_each_case_observed() -> void:
	# Arrange
	var cases: Dictionary = {
		"line_comment": "{\"a\": 1} // c",
		"line_comment_inside": "{\n// c\n\"a\": 1}",
		"block_comment": "{/* c */ \"a\": 1}",
		"trailing_comma_array": "{\"a\": [1, 2,]}",
		"trailing_comma_object": "{\"a\": 1,}",
		"nan": "{\"a\": NaN}",
		"infinity": "{\"a\": Infinity}",
		"single_quotes": "{'a': 1}",
		"leading_zero": "{\"a\": 01}",
		"hex": "{\"a\": 0x10}",
	}

	# Act
	var accepted: Dictionary = {}
	for k: String in cases:
		var r: Dictionary = _parse(cases[k])
		accepted[k] = r["err"] == OK
		print("A4 ", k, " -> ", "ACCEPTED data=%s" % [r["data"]] if r["err"] == OK else "error line=%d '%s'" % [r["line"], r["msg"]])

	# Assert: observed 4.7.2. REJECTED: comments, NaN, Infinity, single quotes, hex. ACCEPTED silently (non-standard):
	# trailing comma in array and in object, leading zero (01). ADR R2/G-16: a pre-check is needed if the
	# project wants to reject them; otherwise they are tolerated. Recorded as a result, not fixed here.
	for k: String in ["line_comment", "line_comment_inside", "block_comment", "nan", "infinity", "single_quotes", "hex"]:
		assert_bool(accepted[k]).is_false()
	for k: String in ["trailing_comma_array", "trailing_comma_object", "leading_zero"]:
		assert_bool(accepted[k]).is_true()


func test_a4_nan_and_infinity_literals_when_stringified_do_not_round_trip_as_numbers() -> void:
	# Arrange
	var text: String = JSON.stringify({"v": NAN, "w": INF})

	# Act
	var r: Dictionary = _parse(text)
	print("A4 stringify(NAN, INF)='", text, "' reparse err=", r["err"], " data=", r["data"])

	# Assert (observation): whatever stringify writes, the reader must reject non-finite numbers itself (D4.1 T-D1)
	assert_str(text).is_not_empty()


func test_a5_utf8_text_round_trips_byte_exact_and_bom_handling_observed() -> void:
	# Arrange
	var s: String = "«Sigo aquí.» — ñ"
	var text: String = JSON.stringify({"t": s})
	var bytes_with_bom: PackedByteArray = PackedByteArray([0xEF, 0xBB, 0xBF]) + "{\"t\": \"x\"}".to_utf8_buffer()

	# Act
	var back: Variant = JSON.parse_string(text)
	var bom_as_string: String = bytes_with_bom.get_string_from_utf8()
	var bom_parse: Dictionary = _parse(bom_as_string)
	print("A5 bom_string_first_codepoint=", bom_as_string.unicode_at(0), " len=", bom_as_string.length(),
		" parse err=", bom_parse["err"], " line=", bom_parse["line"], " msg='", bom_parse["msg"], "'")

	# Assert
	assert_str(back["t"]).is_equal(s)
	assert_array(back["t"].to_utf8_buffer()).is_equal(s.to_utf8_buffer())


func test_a5_bom_file_read_through_file_access_observed() -> void:
	# Arrange
	var w: FileAccess = FileAccess.open(TMP_PATH, FileAccess.WRITE)
	w.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]) + "{\"t\": \"«ñ»\"}".to_utf8_buffer())
	w.close()

	# Act
	var as_string: String = FileAccess.get_file_as_string(TMP_PATH)
	var r: Dictionary = _parse(as_string)
	var parse_string_result: Variant = JSON.parse_string(as_string)
	DirAccess.remove_absolute(TMP_PATH)
	print("A5 file BOM: first_cp=", as_string.unicode_at(0), " len=", as_string.length(), " err=", r["err"],
		" msg='", r["msg"], "' parse_string=", parse_string_result)

	# Assert: observation recorded; ADR D5.4 says a BOM is an ERROR from JsonText (so the reader must check it
	# itself if the engine strips or accepts it silently)
	assert_bool(as_string.length() > 0).is_true()


func test_a6_get_file_as_string_and_open_on_existing_and_missing_res_path() -> void:
	# Arrange
	var existing: String = "res://project.godot"
	var missing: String = "res://assets/data/__no_such_file__.json"

	# Act
	var text_ok: String = FileAccess.get_file_as_string(existing)
	var err_ok: Error = FileAccess.get_open_error()
	var text_missing: String = FileAccess.get_file_as_string(missing)
	var err_missing_gfas: Error = FileAccess.get_open_error()
	var f: FileAccess = FileAccess.open(missing, FileAccess.READ)
	var err_missing_open: Error = FileAccess.get_open_error()
	var f_ok: FileAccess = FileAccess.open(existing, FileAccess.READ)
	var via_open: String = f_ok.get_as_text()
	print("A6 existing: len=", text_ok.length(), " err=", err_ok, " | open().get_as_text len=", via_open.length(),
		" | missing get_file_as_string='", text_missing, "' err=", err_missing_gfas, " | missing open()=", f, " err=", err_missing_open,
		" FileAccess.get_open_error name=", error_string(err_missing_open))

	# Assert
	assert_int(err_ok).is_equal(OK)
	assert_str(text_ok).is_equal(via_open)
	assert_str(text_missing).is_equal("")
	assert_that(f).is_null()
	assert_int(err_missing_open).is_equal(ERR_FILE_NOT_FOUND)
	assert_int(err_missing_gfas).is_equal(ERR_FILE_NOT_FOUND)


func test_a8_tr_without_translations_returns_key_unchanged() -> void:
	# Arrange
	var label: Label = auto_free(Label.new())
	label.text = "UI_X"
	add_child(label)

	# Act
	var translated: String = tr("UI_X")
	print("A8 tr('UI_X')='", translated, "' label.text='", label.text, "' translations_registered=", TranslationServer.get_loaded_locales())

	# Assert
	assert_str(translated).is_equal("UI_X")
	assert_str(label.text).is_equal("UI_X")


func test_a9_is_debug_build_in_editor_run_is_true() -> void:
	# Arrange / Act
	var dbg: bool = OS.is_debug_build()
	print("A9 OS.is_debug_build() in editor/headless-script run = ", dbg, " (export-debug / export-release: NEEDS_MANUAL)")

	# Assert
	assert_bool(dbg).is_true()


func test_a11_make_read_only_dictionary_and_array_write_behaviour() -> void:
	# Arrange
	var d: Dictionary = {"a": 1}
	var a: Array = [1, 2, 3]
	d.make_read_only()
	a.make_read_only()

	# Act: writes are rejected; the value does not change (the engine also prints an error)
	var before_d: int = d["a"]
	var before_a: int = a[0]
	print("A11 dict read_only=", d.is_read_only(), " array read_only=", a.is_read_only())

	# Assert: only the flag and the unchanged read are asserted; the write itself raises an engine error which
	# gdUnit would count as a failure, so it is exercised in the NEEDS_MANUAL sweep (value recorded in the ADR)
	assert_bool(d.is_read_only()).is_true()
	assert_bool(a.is_read_only()).is_true()
	assert_int(before_d).is_equal(1)
	assert_int(before_a).is_equal(1)


func test_a12_parse_200kb_json_median_ms_recorded_under_budget() -> void:
	# Arrange: puzzles.json-like synthetic file of about 200 KB
	var items: Array = []
	for i: int in 1200:
		items.append({"id": "P%d" % i, "nombre": "Puzle número %d «ñ»" % i, "pasos": [1, 2, 3, 4, 5], "valor": 1.5 * i,
			"flags": {"a": true, "b": false, "c": null}, "texto": "Lorem ipsum dolor sit amet consectetur adipiscing elit"})
	var text: String = JSON.stringify({"schema_version": 2, "puzzles": items}, "\t")
	var times: Array[float] = []

	# Act
	for k: int in 10:
		var t0: int = Time.get_ticks_usec()
		var parsed: Variant = JSON.parse_string(text)
		times.append((Time.get_ticks_usec() - t0) / 1000.0)
		assert_bool(parsed is Dictionary).is_true()
	times.sort()
	var median: float = times[times.size() / 2]
	print("A12 size_kb=", text.length() / 1024.0, " median_ms=", median, " min=", times[0], " max=", times[-1])

	# Assert: generous guard (record only); the ADR budget is judged from the printed median
	assert_float(median).is_less(500.0)
