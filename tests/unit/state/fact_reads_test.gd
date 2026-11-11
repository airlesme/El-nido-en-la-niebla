extends GdUnitTestSuite
## EB-007: GameState reads (CA-02, CA-27 reads, resolve_fact / get_fact_at / is_declared).
## Catalog served by MemoryFileStore (20 facts of slice D.2). No Node is left alive (auto_free).

const PATH: String = "state/flags.json"
const FULL_PATH: String = "res://assets/data/state/flags.json"

## ErrorPolicy double that records fail() calls and never quits the tree.
class SpyPolicy extends ErrorPolicy:
	var fails: Array[String] = []
	var strict: bool = true

	func fail(msg: String) -> void:
		fails.append(msg)
		return

	func is_strict() -> bool:
		return strict

var _store: MemoryFileStore
var _log: RecordingLog
var _spy: SpyPolicy


func before_test() -> void:
	_store = MemoryFileStore.new()
	_log = RecordingLog.new()
	_spy = SpyPolicy.new()


func _b(fact: String, owner: int = 9) -> Dictionary:
	return {"name": fact, "type": "bool", "initial": false, "owner": owner}


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
	return {"schema_version": 1, "max_chained_notices": 12, "facts": facts}


func _state(debug: bool, load_it: bool) -> GameState:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(debug)
	c.fatal = RecordingFatalHandler.new()
	c.files = _store
	c.freeze()
	var s: GameState = auto_free(GameState.new())
	s.setup(c)
	_spy.strict = debug
	s.set_error_policy(_spy)
	if load_it:
		_store.put_text(FULL_PATH, JSON.stringify(_doc()))
		assert_int(s.load_catalog(PATH)).is_equal(OK)
	return s


func test_untouched_facts_return_their_initial_value() -> void:
	var s: GameState = _state(true, true)

	assert_bool(s.get_fact(&"caja_c1") as bool).is_false()
	assert_int(s.get_fact(&"pos_L") as int).is_equal(2)
	assert_int(typeof(s.get_fact(&"t4_decision"))).is_equal(TYPE_STRING_NAME)
	assert_bool(s.get_fact(&"t4_decision") == &"").is_true()
	assert_bool(s.get_fact(&"respuesta_llamada") == &"A").is_true()
	assert_int(_spy.fails.size()).is_equal(0)
	assert_int(_log.lines.size()).is_equal(0)


func test_resolve_unknown_fact_is_minus_one_and_silent() -> void:
	var s: GameState = _state(true, true)

	assert_int(s.resolve_fact(&"no_existe")).is_equal(-1)
	assert_int(_spy.fails.size()).is_equal(0)


func test_get_fact_at_matches_get_fact_for_the_20_facts() -> void:
	var s: GameState = _state(true, true)
	var seen: Dictionary = {}

	for f: Variant in _doc()["facts"]:
		var name: StringName = StringName((f as Dictionary)["name"])
		var slot: int = s.resolve_fact(name)
		assert_bool(slot >= 0 and slot < 20).is_true()
		assert_bool(seen.has(slot)).is_false()
		seen[slot] = true
		assert_that(s.get_fact_at(slot)).is_equal(s.get_fact(name))
	assert_int(seen.size()).is_equal(20)


func test_is_declared_is_case_sensitive() -> void:
	var s: GameState = _state(true, true)

	assert_bool(s.is_declared(&"tarjeta_B")).is_true()
	assert_bool(s.is_declared(&"Tarjeta_B")).is_false()


func test_hot_read_is_repeatable_and_stable() -> void:
	# Cost is only logged, never asserted (flaky under load). Structure: same value every call,
	# no failure path taken (a failure would log/allocate).
	var s: GameState = _state(true, true)
	var slot: int = s.resolve_fact(&"pos_C")
	var start: int = Time.get_ticks_usec()
	var sum: int = 0

	for i: int in 10000:
		sum += s.get_fact_at(slot) as int

	var us: int = Time.get_ticks_usec() - start
	print("EB-007 cost: %.5f ms per get_fact_at (10000 iterations)" % (us / 1000.0 / 10000.0))
	assert_int(sum).is_equal(20000)
	assert_int(_log.lines.size()).is_equal(0)
	assert_int(_spy.fails.size()).is_equal(0)


func test_undeclared_read_in_dev_calls_fail_and_logs() -> void:
	var s: GameState = _state(true, true)

	var v: Variant = s.get_fact(&"nope")

	assert_int(_spy.fails.size()).is_equal(1)
	assert_int(_log.lines.size()).is_equal(1)
	assert_bool(v == false).is_true()


func test_undeclared_read_in_release_returns_neutral_and_logs_one_line() -> void:
	var s: GameState = _state(false, true)

	var v: Variant = s.get_fact(&"Tarjeta_B")

	assert_bool(v == false and typeof(v) == TYPE_BOOL).is_true()
	assert_int(_log.lines.size()).is_equal(1)
	assert_that(_log.lines[0][&"level"]).is_equal(LogSink.LEVEL_ERROR)


func test_unloaded_read_in_release_returns_neutral_and_logs() -> void:
	var s: GameState = _state(false, false)

	assert_bool(s.get_fact(&"caja_c1") == false).is_true()
	assert_int(s.resolve_fact(&"caja_c1")).is_equal(-1)
	assert_int(_log.lines.size()).is_equal(1)
	assert_str(_log.lines[0][&"msg"] as String).contains("UNLOADED")


func test_unloaded_read_in_dev_calls_fail() -> void:
	var s: GameState = _state(true, false)

	s.get_fact(&"caja_c1")

	assert_int(_spy.fails.size()).is_equal(1)


func test_get_fact_at_out_of_range_is_treated_as_undeclared() -> void:
	var s: GameState = _state(false, true)

	assert_bool(s.get_fact_at(-1) == false).is_true()
	assert_bool(s.get_fact_at(20) == false).is_true()
	assert_bool(s.get_fact_at(s.resolve_fact(&"nope")) == false).is_true()
	assert_int(_log.lines.size()).is_equal(3)
