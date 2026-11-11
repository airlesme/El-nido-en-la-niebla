extends GdUnitTestSuite
## EB-008: validated writes and FactWriter (CA-02 write, CA-06, CA-08, CA-13).
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
		_b("correos_leidos", 19), _b("archivo_abierto"), _b("formulario_leido", 20),
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


func _state(debug: bool, load_it: bool = true) -> GameState:
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


func test_valid_owner_write_is_readable_immediately() -> void:
	var s: GameState = _state(true)
	var w: FactWriter = s.writer_for(9)

	var ok: bool = w.write(&"caja_c1", true)

	assert_bool(ok).is_true()
	assert_bool(s.get_fact(&"caja_c1") as bool).is_true()
	assert_int(_spy.fails.size()).is_equal(0)
	assert_int(_log.lines.size()).is_equal(0)


func test_valid_int_and_enum_writes_at_range_limits() -> void:
	var s: GameState = _state(true)
	var w: FactWriter = s.writer_for(9)

	assert_bool(w.write(&"pos_L", 1)).is_true()
	assert_bool(w.write(&"pos_R", 4)).is_true()
	assert_bool(w.write(&"t4_decision", &"assigned")).is_true()

	assert_int(s.get_fact(&"pos_L") as int).is_equal(1)
	assert_int(s.get_fact(&"pos_R") as int).is_equal(4)
	assert_bool(s.get_fact(&"t4_decision") == &"assigned").is_true()
	assert_int(_log.lines.size()).is_equal(0)


func test_invalid_writes_in_release_keep_value_and_log_exactly_one_line_each() -> void:
	var s: GameState = _state(false)
	var w: FactWriter = s.writer_for(9)
	var bad: Array[Array] = [
		[&"no_existe", true], [&"Tarjeta_B", true], [&"pos_L", 5], [&"pos_L", 0],
		[&"archivo_abierto", "si"], [&"pos_L", 3.0], [&"pos_C", true], [&"archivo_abierto", 1],
		[&"t4_decision", &"otro"], [&"t4_decision", "returned"], [&"caja_completa", true],
	]

	for pair: Array in bad:
		var before: int = _log.lines.size()
		assert_bool(w.write(pair[0] as StringName, pair[1])).is_false()
		assert_int(_log.lines.size() - before).is_equal(1)

	assert_int(s.get_fact(&"pos_L") as int).is_equal(2)
	assert_bool(s.get_fact(&"archivo_abierto") as bool).is_false()
	assert_bool(s.get_fact(&"caja_completa") as bool).is_false()
	assert_bool(s.get_fact(&"t4_decision") == &"").is_true()
	assert_bool(s.get_channel().is_queue_empty()).is_true()


func test_write_while_unloaded_is_discarded() -> void:
	var s: GameState = _state(false, false)

	var ok: bool = s.set_fact(&"caja_c1", true, 9)

	assert_bool(ok).is_false()
	assert_int(_log.lines.size()).is_equal(1)
	assert_str(_log.lines[0][&"msg"] as String).contains("UNLOADED")


func test_invalid_write_in_dev_calls_fail_once() -> void:
	var s: GameState = _state(true)

	s.writer_for(9).write(&"pos_L", 9)

	assert_int(_spy.fails.size()).is_equal(1)
	assert_int(_log.lines.size()).is_equal(1)
	assert_int(s.get_fact(&"pos_L") as int).is_equal(2)


func test_wrong_owner_is_invalid_in_dev() -> void:
	var s: GameState = _state(true)

	var ok: bool = s.writer_for(20).write(&"caja_c1", true)

	assert_bool(ok).is_false()
	assert_int(_spy.fails.size()).is_equal(1)
	assert_bool(s.get_fact(&"caja_c1") as bool).is_false()


func test_wrong_owner_is_not_checked_in_release() -> void:
	var s: GameState = _state(false)

	var ok: bool = s.writer_for(20).write(&"caja_c1", true)

	assert_bool(ok).is_true()
	assert_bool(s.get_fact(&"caja_c1") as bool).is_true()
	assert_int(_log.lines.size()).is_equal(0)


func test_identical_write_returns_true_without_notice() -> void:
	var s: GameState = _state(true)
	var seen: Array = []
	s.get_channel().subscribe(NoticeChannel.Kind.ALL_FACTS, &"",
			func(f: StringName, o: Variant, n: Variant) -> void: seen.append([f, o, n]))

	var ok: bool = s.writer_for(9).write(&"pos_C", 2)

	assert_bool(ok).is_true()
	assert_int(seen.size()).is_equal(0)


func test_real_change_notifies_once_with_old_and_new() -> void:
	var s: GameState = _state(true)
	var seen: Array = []
	s.get_channel().subscribe(NoticeChannel.Kind.FACT, &"pos_C",
			func(f: StringName, o: Variant, n: Variant) -> void: seen.append([f, o, n]))

	s.writer_for(9).write(&"pos_C", 3)

	assert_int(seen.size()).is_equal(1)
	assert_that(seen[0]).is_equal([&"pos_C", 2, 3])


func test_write_inside_subscriber_is_immediate_and_its_notice_comes_after() -> void:
	var s: GameState = _state(true)
	var w: FactWriter = s.writer_for(9)
	var order: Array = []
	var ch: NoticeChannel = s.get_channel()
	# First subscriber of X writes Y and reads it back at once.
	ch.subscribe(NoticeChannel.Kind.FACT, &"caja_c1", func(_f: StringName, _o: Variant, _n: Variant) -> void:
		w.write(&"caja_c2", true)
		order.append("read_y=%s" % s.get_fact(&"caja_c2"))
		order.append("x1"))
	ch.subscribe(NoticeChannel.Kind.FACT, &"caja_c1",
			func(_f: StringName, _o: Variant, _n: Variant) -> void: order.append("x2"))
	ch.subscribe(NoticeChannel.Kind.FACT, &"caja_c2",
			func(_f: StringName, _o: Variant, _n: Variant) -> void: order.append("y"))

	w.write(&"caja_c1", true)

	assert_array(order).contains_exactly(["read_y=true", "x1", "x2", "y"])
