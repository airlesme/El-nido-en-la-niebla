extends GdUnitTestSuite
## EB-009: one-way and reversible facts (CA-03, CA-04, CA-05). Catalog from MemoryFileStore.

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


func test_true_bool_rewritten_true_is_silent_and_false_is_rejected_with_one_log_line() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(20)
	var seen: Array = []
	s.get_channel().subscribe(NoticeChannel.Kind.FACT, &"tarjeta_B",
			func(f: StringName, o: Variant, n: Variant) -> void: seen.append([f, o, n]))
	assert_bool(w.write(&"tarjeta_B", true)).is_true()
	assert_int(seen.size()).is_equal(1)

	assert_bool(w.write(&"tarjeta_B", true)).is_true()
	assert_int(seen.size()).is_equal(1)
	var before: int = _log.lines.size()
	assert_bool(w.write(&"tarjeta_B", false)).is_false()

	assert_bool(s.get_fact(&"tarjeta_B") as bool).is_true()
	assert_int(_log.lines.size() - before).is_equal(1)
	assert_int(_spy.fails.size()).is_equal(1)
	assert_int(seen.size()).is_equal(1)


func test_enum_once_set_rejects_other_value_and_unset_and_keeps_it() -> void:
	var s: GameState = _state()
	var w9: FactWriter = s.writer_for(9)
	var w22: FactWriter = s.writer_for(22)
	var cases: Array[Array] = [
		[&"carta_variante", &"B", &"C"],
		[&"respuesta_llamada", &"D", &"A"],
		[&"t4_decision", &"returned", &"assigned"],
	]
	for c: Array in cases:
		var fact: StringName = c[0]
		var w: FactWriter = w22 if fact == &"respuesta_llamada" else w9
		assert_bool(w.write(fact, c[1])).is_true()

		var before: int = _log.lines.size()
		assert_bool(w.write(fact, c[2])).is_false()
		assert_bool(w.write(fact, &"")).is_false()

		assert_bool(s.get_fact(fact) == c[1]).is_true()
		assert_int(_log.lines.size() - before).is_equal(2)
		assert_bool(w.write(fact, c[1])).is_true()


func test_enum_unset_to_fixed_is_an_advance() -> void:
	var s: GameState = _state()

	assert_bool(s.writer_for(9).write(&"carta_variante", &"A")).is_true()

	assert_bool(s.get_fact(&"carta_variante") == &"A").is_true()
	assert_int(_log.lines.size()).is_equal(0)


func test_position_ints_are_reversible_within_range() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(9)

	assert_bool(w.write(&"pos_L", 4)).is_true()
	assert_bool(w.write(&"pos_L", 1)).is_true()

	assert_int(s.get_fact(&"pos_L") as int).is_equal(1)
	assert_int(_log.lines.size()).is_equal(0)
	assert_bool(w.write(&"pos_L", 5)).is_false()
	assert_int(s.get_fact(&"pos_L") as int).is_equal(1)


func test_pendiente_revelacion_goes_true_then_false_emitting_both_notices() -> void:
	var s: GameState = _state()
	var w: FactWriter = s.writer_for(9)
	var seen: Array = []
	s.get_channel().subscribe(NoticeChannel.Kind.FACT, &"pendiente_revelacion",
			func(_f: StringName, o: Variant, n: Variant) -> void: seen.append([o, n]))

	assert_bool(w.write(&"pendiente_revelacion", true)).is_true()
	assert_bool(w.write(&"pendiente_revelacion", false)).is_true()

	assert_that(seen).is_equal([[false, true], [true, false]])
	assert_int(_log.lines.size()).is_equal(0)
	assert_int(_spy.fails.size()).is_equal(0)
