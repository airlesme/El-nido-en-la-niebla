extends GdUnitTestSuite
## EB-010: derived facts (CA-07, CA-14). Catalog from MemoryFileStore.

const PATH: String = "state/flags.json"
const FULL_PATH: String = "res://assets/data/state/flags.json"

## ErrorPolicy double that records fail() calls and never quits the tree.
class SpyPolicy extends ErrorPolicy:
	var fails: Array[String] = []

	func fail(msg: String) -> void:
		fails.append(msg)

	func is_strict() -> bool:
		return false

var _store: MemoryFileStore
var _log: RecordingLog
var _spy: SpyPolicy


func before_test() -> void:
	_store = MemoryFileStore.new()
	_log = RecordingLog.new()
	_spy = SpyPolicy.new()


func _b(fact: String, owner: int = 9) -> Dictionary:
	return {"name": fact, "type": "bool", "initial": false, "owner": owner}


func _e(fact: String, values: Array, owner: int = 9) -> Dictionary:
	return {"name": fact, "type": "enum", "initial": null, "owner": owner, "values": values}


## The 20 facts of slice D.2 (the catalog validates the full set and owners).
func _doc() -> Dictionary:
	var facts: Array = [
		_b("correos_leidos", 19), _b("archivo_abierto"), _b("formulario_leido", 20),
		_b("tarjeta_B", 20), _b("tarjeta_D", 20), _b("memo_leido"),
	]
	for p: String in ["pos_L", "pos_C", "pos_R"]:
		facts.append({"name": p, "type": "int", "initial": 2, "owner": 9, "range": [1, 4]})
	facts.append_array([_b("caja_c1"), _e("t4_decision", ["returned", "assigned"]),
		_b("caja_c2"), _b("caja_c3"), _b("caja_c4"), _b("pendiente_revelacion"),
		{"name": "caja_completa", "type": "bool", "initial": false, "owner": 3,
			"derive": ["caja_c1", "caja_c2", "caja_c3", "caja_c4"]},
		_e("carta_variante", ["A", "B", "C"]), _b("llamada_iniciada", 22),
		_e("respuesta_llamada", ["A", "B", "C", "D"], 22), _b("llamada_completada", 22)])
	return {"schema_version": 1, "max_chained_notices": 12, "facts": facts}


func _state() -> GameState:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(false)
	c.fatal = RecordingFatalHandler.new()
	c.files = _store
	c.freeze()
	var s: GameState = auto_free(GameState.new())
	s.setup(c)
	s.set_error_policy(_spy)
	_store.put_text(FULL_PATH, JSON.stringify(_doc()))
	assert_int(s.load_catalog(PATH)).is_equal(OK)
	return s


func test_last_input_true_sets_derived_true_and_direct_write_is_rejected() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(9)
	for f: StringName in [&"caja_c1", &"caja_c2", &"caja_c3"]:
		assert_bool(w.write(f, true)).is_true()
	assert_bool(s.get_fact(&"caja_completa") as bool).is_false()

	assert_bool(w.write(&"caja_c4", true)).is_true()

	assert_bool(s.get_fact(&"caja_completa") as bool).is_true()
	var before: int = _log.lines.size()
	assert_bool(s.writer_for(3).write(&"caja_completa", false)).is_false()
	assert_bool(s.get_fact(&"caja_completa") as bool).is_true()
	assert_int(_log.lines.size() - before).is_equal(1)
	assert_int(_spy.fails.size()).is_equal(1)


func test_direct_write_of_derived_true_with_missing_inputs_is_rejected() -> void:
	var s: GameState = _state()

	assert_bool(s.writer_for(3).write(&"caja_completa", true)).is_false()

	assert_bool(s.get_fact(&"caja_completa") as bool).is_false()
	assert_int(_spy.fails.size()).is_equal(1)


func test_input_notice_arrives_before_derived_notice() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(9)
	var order: Array[StringName] = []
	var ch: NoticeChannel = s.get_channel()
	for f: StringName in [&"caja_c4", &"caja_completa"]:
		ch.subscribe(NoticeChannel.Kind.FACT, f,
				func(fact: StringName, _o: Variant, _n: Variant) -> void: order.append(fact))
	for f: StringName in [&"caja_c1", &"caja_c2", &"caja_c3"]:
		w.write(f, true)

	w.write(&"caja_c4", true)

	assert_that(order).is_equal([&"caja_c4", &"caja_completa"])


func test_incomplete_inputs_leave_derived_false_and_silent() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(9)
	var seen: Array = []
	s.get_channel().subscribe(NoticeChannel.Kind.FACT, &"caja_completa",
			func(f: StringName, _o: Variant, _n: Variant) -> void: seen.append(f))

	w.write(&"caja_c1", true)
	w.write(&"caja_c3", true)
	w.write(&"caja_c4", true)

	assert_bool(s.get_fact(&"caja_completa") as bool).is_false()
	assert_int(seen.size()).is_equal(0)


func test_rewriting_an_input_does_not_renotify_the_derived() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(9)
	var seen: Array = []
	s.get_channel().subscribe(NoticeChannel.Kind.FACT, &"caja_completa",
			func(f: StringName, _o: Variant, _n: Variant) -> void: seen.append(f))
	for f: StringName in [&"caja_c1", &"caja_c2", &"caja_c3", &"caja_c4"]:
		w.write(f, true)

	w.write(&"caja_c4", true)

	assert_int(seen.size()).is_equal(1)
