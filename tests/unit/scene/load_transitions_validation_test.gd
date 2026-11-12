extends GdUnitTestSuite
## CP-002 (T-U11 of ADR-0003): LoadTransitionsSchema + LoadTransitions. AC-D1, AC-F1, TR-scene-015, TR-scene-022.
## Every document is built in memory (MemoryFileStore); no file I/O, nothing that depends on the platform.

const FILE: String = "res://assets/data/scene/load_transitions.json"
const CODE: String = "DATOS_ESCENA_INVALIDOS"


func _doc() -> Dictionary:
	return {
		"schema_version": 1,
		"t_cap_s": 10.0,
		"n_gap": 2,
		"delta_max_s": 0.1,
		"delta_ref_s": 1.0 / 30.0,
		"t_descarga_total_max_s": 3.0,
		"reducir_movimiento_s": 0.1,
		"motivos": {
			"partida_nueva": {"d_out": 0.8, "d_in": 2.0},
			"reanudar": {"d_out": 0.8, "d_in": 0.8},
			"recepcion": {"d_out": 0.8, "d_in": 0.8},
			"cierre": {"d_out": 0.8},
		},
	}


## Loads `text` (null = no file) and returns [config, fatal handler].
func _load_text(text: Variant) -> Array:
	var store: MemoryFileStore = MemoryFileStore.new()
	if text != null:
		store.put_text(FILE, text as String)
	var fatal: RecordingFatalHandler = RecordingFatalHandler.new()
	var cfg: LoadTransitions = LoadTransitions.load_from(DataReader.new(store, BuildFlavor.new(true)), fatal)
	return [cfg, fatal]


func _load(doc: Variant) -> Array:
	return _load_text(null if doc == null else JSON.stringify(doc))


func _with(key: String, value: Variant) -> Dictionary:
	var d: Dictionary = _doc()
	d[key] = value
	return d


func _with_motivo(motivo: String, key: String, value: Variant) -> Dictionary:
	var d: Dictionary = _doc()
	var m: Dictionary = d["motivos"]
	var row: Dictionary = m[motivo]
	row[key] = value
	return d


func _expect_fatal(result: Array, param: String) -> void:
	var fatal: RecordingFatalHandler = result[1]
	assert_object(result[0]).is_null()
	assert_int(fatal.calls.size()).is_equal(1)
	assert_str(fatal.calls[0][&"code"]).is_equal(CODE)
	var detail: Dictionary = fatal.calls[0][&"detail"]
	assert_str(detail[&"param"]).is_equal(param)


func _expect_valid(result: Array) -> LoadTransitions:
	assert_bool((result[1] as RecordingFatalHandler).has_failed()).is_false()
	assert_object(result[0]).is_not_null()
	return result[0]


# --- valid data / AC-F1 ---------------------------------------------------------

func test_valid_document_loads_all_knobs() -> void:
	var cfg: LoadTransitions = _expect_valid(_load(_doc()))
	assert_float(cfg.t_cap_s).is_equal(10.0)
	assert_int(cfg.n_gap).is_equal(2)
	assert_float(cfg.delta_max_s).is_equal(0.1)
	assert_float(cfg.t_descarga_total_max_s).is_equal(3.0)
	assert_float(cfg.reduced_motion_s).is_equal(0.1)


func test_table_has_gdd_durations_per_motivo() -> void:
	var cfg: LoadTransitions = _expect_valid(_load(_doc()))
	assert_float(cfg.d_in_s(LoadTransitions.MOTIVO_PARTIDA_NUEVA)).is_equal(2.0)
	assert_float(cfg.d_in_s(LoadTransitions.MOTIVO_REANUDAR)).is_equal(0.8)
	assert_float(cfg.d_out_s(LoadTransitions.MOTIVO_RECEPCION)).is_equal(0.8)
	assert_float(cfg.d_in_s(LoadTransitions.MOTIVO_RECEPCION)).is_equal(0.8)


func test_cierre_only_darkens() -> void:
	var cfg: LoadTransitions = _expect_valid(_load(_doc()))
	assert_bool(cfg.has_motivo(LoadTransitions.MOTIVO_CIERRE)).is_true()
	assert_float(cfg.d_out_s(LoadTransitions.MOTIVO_CIERRE)).is_equal(0.8)
	assert_float(cfg.d_in_s(LoadTransitions.MOTIVO_CIERRE)).is_equal(0.0)


func test_unknown_motivo_is_absent() -> void:
	var cfg: LoadTransitions = _expect_valid(_load(_doc()))
	assert_bool(cfg.has_motivo(&"titulo")).is_false()


func test_fixture_value_is_used_without_recompiling() -> void:
	var cfg: LoadTransitions = _expect_valid(_load(_with("t_cap_s", 20.0)))
	assert_float(cfg.t_cap_s).is_equal(20.0)


# --- AC-D1: fixtures out of range ------------------------------------------------

func test_d_out_6_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with_motivo("recepcion", "d_out", 6.0)), "motivos.recepcion.d_out")


func test_d_in_6_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with_motivo("partida_nueva", "d_in", 6.0)), "motivos.partida_nueva.d_in")


func test_cierre_d_out_6_is_fatal() -> void:
	_expect_fatal(_load(_with_motivo("cierre", "d_out", 6.0)), "motivos.cierre.d_out")


func test_t_cap_2_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with("t_cap_s", 2.0)), "t_cap_s")


func test_n_gap_11_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with("n_gap", 11)), "n_gap")


func test_delta_max_02_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with("delta_max_s", 0.2)), "delta_max_s")


# --- boundaries ------------------------------------------------------------------

func test_range_edges_are_valid() -> void:
	assert_object(_load(_with_motivo("recepcion", "d_out", 5.0))[0]).is_not_null()
	assert_object(_load(_with_motivo("recepcion", "d_in", 0.0))[0]).is_not_null()
	assert_object(_load(_with("t_cap_s", 3.0))[0]).is_not_null()
	assert_object(_load(_with("t_cap_s", 30.0))[0]).is_not_null()
	assert_object(_load(_with("n_gap", 0))[0]).is_not_null()
	assert_object(_load(_with("n_gap", 10))[0]).is_not_null()
	assert_object(_load(_with("delta_max_s", 0.05))[0]).is_not_null()
	assert_object(_load(_with("delta_max_s", 0.1))[0]).is_not_null()


func test_just_outside_range_is_fatal() -> void:
	_expect_fatal(_load(_with("t_cap_s", 2.99)), "t_cap_s")
	_expect_fatal(_load(_with("t_cap_s", 30.01)), "t_cap_s")
	_expect_fatal(_load(_with("n_gap", -1)), "n_gap")
	_expect_fatal(_load(_with("delta_max_s", 0.04)), "delta_max_s")
	_expect_fatal(_load(_with("delta_max_s", 0.11)), "delta_max_s")
	_expect_fatal(_load(_with_motivo("recepcion", "d_out", -0.1)), "motivos.recepcion.d_out")


func test_other_knobs_out_of_range_are_fatal() -> void:
	_expect_fatal(_load(_with("delta_ref_s", 0.05)), "delta_ref_s")
	_expect_fatal(_load(_with("delta_ref_s", 0.001)), "delta_ref_s")
	_expect_fatal(_load(_with("t_descarga_total_max_s", 6.0)), "t_descarga_total_max_s")
	_expect_fatal(_load(_with("t_descarga_total_max_s", 0.5)), "t_descarga_total_max_s")
	_expect_fatal(_load(_with("reducir_movimiento_s", 6.0)), "reducir_movimiento_s")


# --- invalid shapes ---------------------------------------------------------------

func test_n_gap_fractional_is_fatal() -> void:
	_expect_fatal(_load(_with("n_gap", 2.5)), "n_gap")


func test_wrong_type_names_the_parameter() -> void:
	_expect_fatal(_load(_with("t_cap_s", "ten")), "t_cap_s")


func test_missing_key_names_the_parameter() -> void:
	var d: Dictionary = _doc()
	d.erase("delta_max_s")
	_expect_fatal(_load(d), "delta_max_s")


func test_missing_motivo_is_fatal() -> void:
	var d: Dictionary = _doc()
	(d["motivos"] as Dictionary).erase("cierre")
	_expect_fatal(_load(d), "motivos.cierre")


func test_missing_d_in_of_recepcion_is_fatal() -> void:
	var d: Dictionary = _doc()
	((d["motivos"] as Dictionary)["recepcion"] as Dictionary).erase("d_in")
	_expect_fatal(_load(d), "motivos.recepcion.d_in")


func test_unknown_key_is_fatal() -> void:
	_expect_fatal(_load(_with("extra", 1.0)), "extra")


func test_missing_file_is_fatal_and_creates_no_config() -> void:
	_expect_fatal(_load(null), "$")


func test_corrupt_json_is_fatal_and_creates_no_config() -> void:
	var r: Array = _load_text("{ \"schema_version\": 1, \"t_cap_s\": ")
	assert_object(r[0]).is_null()
	var fatal: RecordingFatalHandler = r[1]
	assert_int(fatal.calls.size()).is_equal(1)
	assert_str(fatal.calls[0][&"code"]).is_equal(CODE)


func test_empty_file_is_fatal() -> void:
	var r: Array = _load_text("")
	assert_object(r[0]).is_null()
	assert_bool((r[1] as RecordingFatalHandler).has_failed()).is_true()


# --- registry ----------------------------------------------------------------------

func test_registry_row_has_schema_owner_and_fatal_code() -> void:
	var found: bool = false
	for e: DataCatalog.Entry in DataCatalog.entries():
		if e.rel_path == "scene/load_transitions.json":
			found = true
			assert_int(e.owner).is_equal(4)
			assert_str(e.fatal_code).is_equal(CODE)
			assert_object(e.schema).is_instanceof(LoadTransitionsSchema)
	assert_bool(found).is_true()
