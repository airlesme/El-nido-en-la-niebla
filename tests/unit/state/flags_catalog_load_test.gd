extends GdUnitTestSuite
## EB-005: FlagsSchema + GameState.load_catalog (CA-01, CA-26 unit part, channel cap from the file).
## Fixtures are built in code (20 facts of slice D.2) and served by MemoryFileStore: no disk I/O.

const PATH: String = "state/flags.json"
const FULL_PATH: String = "res://assets/data/state/flags.json"
const CHAIN: int = 12

var _store: MemoryFileStore
var _fatal: RecordingFatalHandler
var _log: RecordingLog


func before_test() -> void:
	_store = MemoryFileStore.new()
	_fatal = RecordingFatalHandler.new()
	_log = RecordingLog.new()


## Context of doubles without Node fakes (TestContexts would create orphan Nodes here).
func _ctx(debug: bool = true) -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(debug)
	c.fatal = _fatal
	c.files = _store
	c.freeze()
	return c


func _state(debug: bool = true) -> GameState:
	var s: GameState = auto_free(GameState.new())
	s.setup(_ctx(debug))
	return s


func _b(fact: String, owner: int = 9, initial: bool = false) -> Dictionary:
	return {"name": fact, "type": "bool", "initial": initial, "owner": owner}


## The 20 facts of slice D.2 as a JSON-shaped Dictionary.
func _doc() -> Dictionary:
	var facts: Array = [
		_b("correos_leidos", 20), _b("archivo_abierto"), _b("formulario_leido", 20),
		_b("tarjeta_B", 20), _b("tarjeta_D", 20), _b("memo_leido"),
	]
	for p: String in ["pos_L", "pos_C", "pos_R"]:
		facts.append({"name": p, "type": "int", "initial": 2, "owner": 9, "range": [1, 4]})
	facts.append_array([_b("caja_c1"),
		{"name": "t4_decision", "type": "enum", "initial": null, "owner": 9, "values": ["returned", "assigned"]},
		_b("caja_c2"), _b("caja_c3"), _b("caja_c4"), _b("pendiente_revelacion"),
		{"name": "caja_completa", "type": "bool", "initial": false, "owner": 3,
			"derive": ["caja_c1", "caja_c2", "caja_c3", "caja_c4"]},
		{"name": "carta_variante", "type": "enum", "initial": null, "owner": 9, "values": ["A", "B", "C"]},
		_b("llamada_iniciada", 22),
		{"name": "respuesta_llamada", "type": "enum", "initial": "A", "owner": 22, "values": ["A", "B", "C", "D"]},
		_b("llamada_completada", 22)])
	return {"schema_version": 1, "max_chained_notices": CHAIN, "facts": facts}


func _put(doc: Dictionary) -> void:
	_store.put_text(FULL_PATH, JSON.stringify(doc))


func _fact(doc: Dictionary, index: int) -> Dictionary:
	return (doc["facts"] as Array)[index]


func _expect_fatal(state: GameState, param: String) -> void:
	assert_int(state.load_catalog(PATH)).is_equal(ERR_INVALID_DATA)
	assert_int(_fatal.calls.size()).is_equal(1)
	assert_str(str(_fatal.calls[0][&"code"])).is_equal("CATALOGO_INVALIDO")
	assert_str(str((_fatal.calls[0][&"detail"] as Dictionary)[&"param"])).is_equal(param)
	assert_int(state.get_status()).is_equal(GameState.Status.UNLOADED)


# --- CA-01 ---------------------------------------------------------------

func test_valid_catalog_loads_20_facts_with_their_initials() -> void:
	_put(_doc())
	var state: GameState = _state()

	var err: Error = state.load_catalog(PATH)

	assert_int(err).is_equal(OK)
	assert_int(state.get_status()).is_equal(GameState.Status.READY)
	assert_int(state.fact_count()).is_equal(20)
	assert_bool(_fatal.has_failed()).is_false()
	assert_bool(state.get_fact(&"correos_leidos") as bool).is_false()
	assert_int(state.get_fact(&"pos_C") as int).is_equal(2)
	assert_str(str(state.get_fact(&"t4_decision"))).is_equal("")
	assert_int(typeof(state.get_fact(&"t4_decision"))).is_equal(TYPE_STRING_NAME)
	assert_str(str(state.get_fact(&"respuesta_llamada"))).is_equal("A")
	assert_bool(state.is_declared(&"caja_completa")).is_true()
	assert_bool(state.is_declared(&"nope")).is_false()
	assert_int(state.resolve_fact(&"nope")).is_equal(-1)


func test_status_is_unloaded_before_load() -> void:
	assert_int(_state().get_status()).is_equal(GameState.Status.UNLOADED)


func test_catalog_registers_flags_schema() -> void:
	var found: bool = false
	for e: DataCatalog.Entry in DataCatalog.entries():
		if e.rel_path == PATH and e.schema is FlagsSchema:
			found = true
	assert_bool(found).is_true()


# --- channel cap from the file ---------------------------------------------

func test_channel_cap_comes_from_max_chained_notices_in_file() -> void:
	_put(_doc())
	var state: GameState = _state(false)
	state.load_catalog(PATH)
	var count: Array[int] = [0]
	state.get_channel().subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.STATE_RESET,
			func(_p: Dictionary) -> void:
				count[0] += 1
				state.get_channel().notify(NoticeIds.STATE_RESET))

	state.get_channel().notify(NoticeIds.STATE_RESET)

	assert_int(count[0]).is_equal(CHAIN)


func test_channel_cap_bounds_8_and_256_are_accepted() -> void:
	for n: int in [8, 256]:
		var doc: Dictionary = _doc()
		doc["max_chained_notices"] = n
		_put(doc)
		var state: GameState = _state()
		assert_int(state.load_catalog(PATH)).is_equal(OK)
	assert_bool(_fatal.has_failed()).is_false()


# --- CA-26 (unit part) -----------------------------------------------------

func test_missing_file_is_fatal() -> void:
	_expect_fatal(_state(), "$")


func test_corrupt_json_is_fatal() -> void:
	_store.put_text(FULL_PATH, "{ not json")
	_expect_fatal(_state(), "$")


func test_19_facts_is_fatal_on_facts() -> void:
	var doc: Dictionary = _doc()
	(doc["facts"] as Array).pop_back()
	_put(doc)
	_expect_fatal(_state(), "facts")


func test_21_facts_is_fatal_on_facts() -> void:
	var doc: Dictionary = _doc()
	(doc["facts"] as Array).append(_b("extra"))
	_put(doc)
	_expect_fatal(_state(), "facts")


func test_unknown_type_is_fatal_on_that_fact() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 3)["type"] = "float"
	_put(doc)
	_expect_fatal(_state(), "facts[3].type")


func test_non_integer_owner_is_fatal_on_that_fact() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 1)["owner"] = 9.5
	_put(doc)
	_expect_fatal(_state(), "facts[1].owner")


func test_string_owner_is_fatal_on_that_fact() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 1)["owner"] = "9"
	_put(doc)
	_expect_fatal(_state(), "facts[1].owner")


func test_max_chained_below_8_is_fatal() -> void:
	var doc: Dictionary = _doc()
	doc["max_chained_notices"] = 7
	_put(doc)
	_expect_fatal(_state(), "max_chained_notices")


func test_max_chained_above_256_is_fatal() -> void:
	var doc: Dictionary = _doc()
	doc["max_chained_notices"] = 257
	_put(doc)
	_expect_fatal(_state(), "max_chained_notices")


func test_max_chained_fractional_is_fatal() -> void:
	var doc: Dictionary = _doc()
	doc["max_chained_notices"] = 8.5
	_put(doc)
	_expect_fatal(_state(), "max_chained_notices")


func test_duplicate_fact_name_is_fatal() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 1)["name"] = "correos_leidos"
	_put(doc)
	_expect_fatal(_state(), "facts[1].name")


func test_int_initial_outside_range_is_fatal() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 6)["initial"] = 5
	_put(doc)
	_expect_fatal(_state(), "facts[6].initial")


func test_enum_initial_not_in_values_is_fatal() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 16)["initial"] = "Z"
	_put(doc)
	_expect_fatal(_state(), "facts[16].initial")


func test_derive_from_undeclared_fact_is_fatal() -> void:
	var doc: Dictionary = _doc()
	_fact(doc, 15)["derive"] = ["caja_c1", "fantasma"]
	_put(doc)
	_expect_fatal(_state(), "facts[15].derive")


func test_wrong_schema_version_is_fatal() -> void:
	var doc: Dictionary = _doc()
	doc["schema_version"] = 2
	_put(doc)
	_expect_fatal(_state(), "schema_version")


func test_unregistered_path_is_fatal_on_path() -> void:
	var state: GameState = _state()

	assert_int(state.load_catalog("state/other.json")).is_equal(ERR_INVALID_DATA)

	assert_str(str((_fatal.calls[0][&"detail"] as Dictionary)[&"param"])).is_equal("path")
	assert_int(state.get_status()).is_equal(GameState.Status.UNLOADED)
