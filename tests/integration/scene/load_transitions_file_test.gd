extends GdUnitTestSuite
## CP-002 AC-D2 (I) and AC-F1: the REAL `assets/data/scene/load_transitions.json` through the real FileStore.
## Absent / corrupt cases use an in-memory store (a real file cannot be removed from a test); the platform is never asserted.


func _real_reader() -> DataReader:
	return DataReader.new(FileStore.new(), BuildFlavor.new(true))


func test_real_file_has_no_issues_through_the_reader() -> void:
	var r: DataResult = _real_reader().read_file(
			DataCatalog.Entry.new(LoadTransitions.PATH, LoadTransitionsSchema.new()))
	assert_array(r.issues).is_empty()


func test_real_file_loads_with_the_gdd_table() -> void:
	var fatal: RecordingFatalHandler = RecordingFatalHandler.new()
	var cfg: LoadTransitions = LoadTransitions.load_from(_real_reader(), fatal)
	assert_bool(fatal.has_failed()).is_false()
	assert_object(cfg).is_not_null()
	assert_float(cfg.d_in_s(&"partida_nueva")).is_equal(2.0)
	assert_float(cfg.d_in_s(&"reanudar")).is_equal(0.8)
	assert_float(cfg.d_out_s(&"recepcion")).is_equal(0.8)
	assert_float(cfg.d_in_s(&"recepcion")).is_equal(0.8)
	assert_float(cfg.d_out_s(&"cierre")).is_equal(0.8)
	assert_float(cfg.t_cap_s).is_equal(10.0)
	assert_int(cfg.n_gap).is_equal(2)
	assert_float(cfg.delta_max_s).is_equal(0.1)
	assert_float(cfg.reduced_motion_s).is_equal(0.1)


func test_absent_file_does_not_enter_a_game_and_raises_fatal() -> void:
	var fatal: RecordingFatalHandler = RecordingFatalHandler.new()
	var cfg: LoadTransitions = LoadTransitions.load_from(
			DataReader.new(MemoryFileStore.new(), BuildFlavor.new(true)), fatal)
	assert_object(cfg).is_null()
	assert_str(fatal.calls[0][&"code"]).is_equal("DATOS_ESCENA_INVALIDOS")


func test_corrupt_file_does_not_enter_a_game_and_raises_fatal() -> void:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text("res://assets/data/scene/load_transitions.json", "not json {")
	var fatal: RecordingFatalHandler = RecordingFatalHandler.new()
	var cfg: LoadTransitions = LoadTransitions.load_from(DataReader.new(store, BuildFlavor.new(true)), fatal)
	assert_object(cfg).is_null()
	assert_str(fatal.calls[0][&"code"]).is_equal("DATOS_ESCENA_INVALIDOS")
