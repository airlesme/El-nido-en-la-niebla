extends GdUnitTestSuite
## EB-006: the real `assets/data/state/flags.json` (20 facts of slice D.2, owners of GDD 3
## § Interactions with Other Systems). Reads the shipped file on purpose (CA-30 is about the data).

const PATH: String = "state/flags.json"
const FULL_PATH: String = "res://assets/data/state/flags.json"

## name -> [owner, type]; source: GDD 3 «Escribe» column (caja_completa: 3, derived by the system).
const EXPECTED: Dictionary = {
	"correos_leidos": [19, "bool"], "archivo_abierto": [9, "bool"],
	"formulario_leido": [20, "bool"], "tarjeta_B": [20, "bool"], "tarjeta_D": [20, "bool"],
	"memo_leido": [9, "bool"], "pos_L": [9, "int"], "pos_C": [9, "int"], "pos_R": [9, "int"],
	"caja_c1": [9, "bool"], "t4_decision": [9, "enum"], "caja_c2": [9, "bool"],
	"caja_c3": [9, "bool"], "caja_c4": [9, "bool"], "pendiente_revelacion": [9, "bool"],
	"caja_completa": [3, "bool"], "carta_variante": [9, "enum"], "llamada_iniciada": [22, "bool"],
	"respuesta_llamada": [22, "enum"], "llamada_completada": [22, "bool"],
}

var _fatal: RecordingFatalHandler
var _log: RecordingLog


func before_test() -> void:
	_fatal = RecordingFatalHandler.new()
	_log = RecordingLog.new()


func _doc() -> Dictionary:
	var bytes: PackedByteArray = FileStore.new().read_bytes(FULL_PATH)
	return JSON.parse_string(bytes.get_string_from_utf8()) as Dictionary


func _facts_by_name() -> Dictionary:
	var by_name: Dictionary = {}
	for f: Variant in _doc()["facts"] as Array:
		var d: Dictionary = f
		by_name[d["name"]] = d
	return by_name


func test_real_file_loads_without_issues() -> void:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(true)
	c.fatal = _fatal
	c.files = FileStore.new()
	c.freeze()
	var state: GameState = auto_free(GameState.new())
	state.setup(c)

	var err: Error = state.load_catalog(PATH)

	assert_int(err).is_equal(OK)
	assert_bool(_fatal.has_failed()).is_false()
	assert_int(state.get_status()).is_equal(GameState.Status.READY)
	assert_int(state.fact_count()).is_equal(20)


func test_real_file_has_exactly_the_20_facts_with_owner_and_type() -> void:
	var by_name: Dictionary = _facts_by_name()

	assert_int((_doc()["facts"] as Array).size()).is_equal(20)
	assert_int(by_name.size()).is_equal(20)
	for n: String in EXPECTED:
		assert_bool(by_name.has(n)).is_true()
		var d: Dictionary = by_name[n]
		var want: Array = EXPECTED[n]
		assert_int(int(d["owner"])).is_equal(want[0])
		assert_str(str(d["type"])).is_equal(want[1])


func test_real_file_header_and_reversible_facts() -> void:
	var doc: Dictionary = _doc()
	var by_name: Dictionary = _facts_by_name()

	assert_int(int(doc["schema_version"])).is_equal(1)
	assert_int(int(doc["max_chained_notices"])).is_equal(64)
	for p: String in ["pos_L", "pos_C", "pos_R"]:
		assert_int(int((by_name[p] as Dictionary)["initial"])).is_equal(2)
		var rng: Array = (by_name[p] as Dictionary)["range"]
		assert_int(rng.size()).is_equal(2)
		assert_int(int(rng[0])).is_equal(1)
		assert_int(int(rng[1])).is_equal(4)
	assert_array((by_name["caja_completa"] as Dictionary)["derive"] as Array) \
			.contains_exactly(["caja_c1", "caja_c2", "caja_c3", "caja_c4"])
	assert_array((by_name["t4_decision"] as Dictionary)["values"] as Array) \
			.contains_exactly(["returned", "assigned"])
