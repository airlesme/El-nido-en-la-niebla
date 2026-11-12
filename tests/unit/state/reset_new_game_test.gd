extends GdUnitTestSuite
## EB-011: new game (CA-18, CA-13b). Catalog from MemoryFileStore.

const PATH: String = "state/flags.json"
const FULL_PATH: String = "res://assets/data/state/flags.json"

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


func _progress(s: GameState) -> void:
	var w: FactWriter = s.writer_for(9)
	for f: StringName in [&"caja_c1", &"caja_c2", &"caja_c3", &"caja_c4", &"memo_leido"]:
		w.write(f, true)
	w.write(&"pos_L", 4)
	w.write(&"t4_decision", &"assigned")
	w.write(&"carta_variante", &"B")


func _assert_all_initial(s: GameState) -> void:
	for f: StringName in [&"caja_c1", &"caja_c2", &"caja_c3", &"caja_c4", &"caja_completa", &"memo_leido"]:
		assert_bool(s.get_fact(f) as bool).is_false()
	assert_int(s.get_fact(&"pos_L") as int).is_equal(2)
	assert_int(s.get_fact(&"pos_C") as int).is_equal(2)
	assert_that(s.get_fact(&"t4_decision")).is_equal(&"")
	assert_that(s.get_fact(&"carta_variante")).is_equal(&"")


func test_reset_restores_all_facts_clears_queue_and_emits_one_state_reset() -> void:
	var s: GameState = _state()
	_progress(s)
	assert_bool(s.get_fact(&"caja_completa") as bool).is_true()
	var ch: NoticeChannel = s.get_channel()
	var resets: Array[int] = [0]
	var changes: Array[int] = [0]
	ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.STATE_RESET,
			func(_p: Dictionary) -> void: resets[0] += 1)
	ch.subscribe(NoticeChannel.Kind.ALL_FACTS, &"",
			func(_f: StringName, _o: Variant, _n: Variant) -> void: changes[0] += 1)

	s.reset_new_game()

	_assert_all_initial(s)
	assert_bool(ch.is_queue_empty()).is_true()
	assert_int(resets[0]).is_equal(1)
	assert_int(changes[0]).is_equal(0)


func test_reset_on_fresh_state_still_emits_single_state_reset() -> void:
	var s: GameState = _state()
	var resets: Array[int] = [0]
	s.get_channel().subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.STATE_RESET,
			func(_p: Dictionary) -> void: resets[0] += 1)

	s.reset_new_game()

	assert_int(resets[0]).is_equal(1)
	_assert_all_initial(s)


func test_reset_allows_one_way_fact_to_be_set_again() -> void:
	var s: GameState = _state()
	_progress(s)
	s.reset_new_game()

	assert_bool(s.writer_for(9).write(&"caja_c1", true)).is_true()
	assert_bool(s.get_fact(&"caja_c1") as bool).is_true()
	assert_int(_spy.fails.size()).is_equal(0)


func test_reset_requested_from_subscriber_is_deferred_to_end_of_drain() -> void:
	var s: GameState = _state()
	var ch: NoticeChannel = s.get_channel()
	var resets: Array[int] = [0]
	var queue_empty_at_reset: Array[bool] = []
	var seen_reset_inside_drain: Array[bool] = []
	ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.STATE_RESET, func(_p: Dictionary) -> void:
		resets[0] += 1
		# Capture the Node `s`, never the RefCounted channel `ch`: a lambda stored inside the channel that
		# captures the channel is a reference cycle (leaked at exit).
		queue_empty_at_reset.append(s.get_channel().is_queue_empty()))
	ch.subscribe(NoticeChannel.Kind.FACT, &"caja_c1",
			func(_f: StringName, _o: Variant, _n: Variant) -> void:
				s.reset_new_game()
				seen_reset_inside_drain.append(resets[0] > 0))

	s.writer_for(9).write(&"caja_c1", true)

	assert_that(seen_reset_inside_drain).is_equal([false])
	assert_int(resets[0]).is_equal(1)
	assert_that(queue_empty_at_reset).is_equal([true])
	assert_bool(ch.is_queue_empty()).is_true()
	assert_bool(ch.is_draining()).is_false()
	_assert_all_initial(s)


func test_reset_while_unloaded_is_a_noop() -> void:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(false)
	c.fatal = RecordingFatalHandler.new()
	c.freeze()
	var s: GameState = auto_free(GameState.new())
	s.setup(c)

	s.reset_new_game()

	assert_int(s.get_status()).is_equal(GameState.Status.UNLOADED)
