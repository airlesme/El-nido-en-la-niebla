extends GdUnitTestSuite
## EB-004: NoticeIds registry, schema validation in NoticeChannel, InteractionNotice (CA-11, CA-36).

## ErrorPolicy double: records fail() calls; strictness is configurable.
class ConfigurableErrors extends ErrorPolicy:
	var strict: bool = true
	var fails: Array[String] = []

	func fail(msg: String) -> void:
		fails.append(msg)

	func is_strict() -> bool:
		return strict

var _log: RecordingLog
var _errors: ConfigurableErrors
var _ch: NoticeChannel


func before_test() -> void:
	_log = RecordingLog.new()
	_errors = ConfigurableErrors.new()
	_ch = NoticeChannel.new(64, _log, _errors, NoticeIds.SCHEMA)


## A valid payload built from the schema (required and optional keys).
func _valid_payload(notice: StringName) -> Dictionary:
	var p: Dictionary = {}
	var spec: Dictionary = NoticeIds.SCHEMA[notice]
	for key: StringName in spec:
		match (spec[key] as Array)[0]:
			TYPE_STRING_NAME: p[key] = &"x"
			TYPE_FLOAT: p[key] = 1.5
			TYPE_INT: p[key] = 2
			TYPE_ARRAY: p[key] = [1]
			TYPE_DICTIONARY: p[key] = {&"k": 1}
	return p


func _registry_constants() -> Dictionary:
	var out: Dictionary = {}
	var all: Dictionary = (NoticeIds as Script).get_script_constant_map()
	for k: String in all:
		if all[k] is StringName:
			out[all[k]] = k
	return out


# --- registry shape ----------------------------------------------------

func test_registry_constants_and_schema_keys_are_the_same_set() -> void:
	var consts: Dictionary = _registry_constants()
	assert_int(consts.size()).is_equal(NoticeIds.SCHEMA.size())
	for name: StringName in consts:
		assert_bool(NoticeIds.SCHEMA.has(name)).is_true()


func test_registry_names_the_gdd_literals_exactly() -> void:
	assert_str(NoticeIds.PAUSE_OPENED).is_equal("pause_opened")
	assert_str(NoticeIds.PAUSE_CLOSED).is_equal("pause_closed")
	assert_str(NoticeIds.EV_PUZZLE_SOLVED_P1).is_equal("EV_PUZZLE_SOLVED_P1")
	assert_str(NoticeIds.EV_PUZZLE_SOLVED_P6).is_equal("EV_PUZZLE_SOLVED_P6")
	assert_bool(NoticeIds.SCHEMA.has(&"EV_PUZZLE_SOLVED_P3")).is_true()


# --- CA-11 -------------------------------------------------------------

func test_every_registered_notice_is_delivered_with_its_name_and_data() -> void:
	var got: Dictionary = {}
	for name: StringName in NoticeIds.SCHEMA:
		var n: StringName = name
		_ch.subscribe(NoticeChannel.Kind.NOTICE, n, func(p: Dictionary) -> void: got[n] = p)
	for name: StringName in NoticeIds.SCHEMA:
		_ch.notify(name, _valid_payload(name))
	assert_int(got.size()).is_equal(NoticeIds.SCHEMA.size())
	for name: StringName in NoticeIds.SCHEMA:
		assert_dict(got[name]).is_equal(_valid_payload(name))
	assert_int(_errors.fails.size()).is_equal(0)


func test_subscriber_to_one_fact_does_not_receive_another_facts_change() -> void:
	var seen: Array[StringName] = []
	_ch.subscribe(NoticeChannel.Kind.FACT, &"caja_c1", func(f: StringName, _o: Variant, _n: Variant) -> void: seen.append(f))
	_ch.push_change(&"caja_c2", false, true)
	assert_int(seen.size()).is_equal(0)
	_ch.push_change(&"caja_c1", false, true)
	assert_array(seen).is_equal([&"caja_c1"])


# --- CA-36 -------------------------------------------------------------

func test_scene_load_started_carries_destino_motivo_and_d_carga() -> void:
	var got: Array[Dictionary] = []
	_ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_LOAD_STARTED, func(p: Dictionary) -> void: got.append(p))
	_ch.notify(NoticeIds.SCENE_LOAD_STARTED, {&"destino": &"hall", &"motivo": &"nuevo", &"control_final": &"jugador", &"D_carga": 0.8})
	assert_int(got.size()).is_equal(1)
	assert_str(got[0][&"destino"]).is_equal("hall")
	assert_str(got[0][&"motivo"]).is_equal("nuevo")
	assert_float(got[0][&"D_carga"]).is_equal(0.8)


func test_scene_load_failed_carries_destino_motivo_and_causa() -> void:
	var got: Array[Dictionary] = []
	_ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_LOAD_FAILED, func(p: Dictionary) -> void: got.append(p))
	_ch.notify(NoticeIds.SCENE_LOAD_FAILED, {&"destino": &"hall", &"motivo": &"nuevo", &"causa": &"recurso_ausente"})
	assert_int(got.size()).is_equal(1)
	assert_str(got[0][&"causa"]).is_equal("recurso_ausente")


func test_game_finished_has_a_single_registry_entry_without_payload() -> void:
	var names: Array = _registry_constants().keys().filter(func(n: StringName) -> bool: return n == &"game_finished")
	assert_int(names.size()).is_equal(1)
	assert_int((NoticeIds.SCHEMA[NoticeIds.GAME_FINISHED] as Dictionary).size()).is_equal(0)


# --- validation (debug) ------------------------------------------------

func test_debug_unregistered_name_fails_and_is_not_delivered() -> void:
	var hits: Array[int] = [0]
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"not_a_notice", func(_p: Dictionary) -> void: hits[0] += 1)
	_ch.notify(&"not_a_notice")
	assert_int(_errors.fails.size()).is_equal(1)
	assert_int(hits[0]).is_equal(0)
	assert_int(_log.lines.size()).is_equal(1)


func test_debug_missing_required_key_fails_and_is_not_delivered() -> void:
	var hits: Array[int] = [0]
	_ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_READY, func(_p: Dictionary) -> void: hits[0] += 1)
	_ch.notify(NoticeIds.SCENE_READY, {})
	assert_int(_errors.fails.size()).is_equal(1)
	assert_int(hits[0]).is_equal(0)


func test_debug_unknown_key_fails() -> void:
	_ch.notify(NoticeIds.SCENE_READY, {&"destino": &"a", &"extra": 1})
	assert_int(_errors.fails.size()).is_equal(1)


func test_debug_wrong_type_fails_including_int_for_float() -> void:
	_ch.notify(NoticeIds.SCENE_READY, {&"destino": "a_string"})
	_ch.notify(NoticeIds.COMPARTMENT_COMPLETED, {&"n": 1.0})
	_ch.notify(NoticeIds.LINE_STARTED, {&"line_id": &"VO", &"duracion_s": 3, &"canal": &"voz"})
	assert_int(_errors.fails.size()).is_equal(3)


func test_debug_string_key_instead_of_stringname_fails() -> void:
	_ch.notify(NoticeIds.SCENE_READY, {"destino": &"a"})
	assert_int(_errors.fails.size()).is_equal(1)


func test_debug_payload_on_a_payloadless_notice_fails() -> void:
	_ch.notify(NoticeIds.PAUSE_OPENED, {&"x": 1})
	assert_int(_errors.fails.size()).is_equal(1)


func test_debug_optional_keys_may_be_absent_or_present() -> void:
	_ch.notify(NoticeIds.SOUND_REQUESTED, {&"sound_id": &"s", &"accion": &"play"})
	_ch.notify(NoticeIds.SOUND_REQUESTED, {&"sound_id": &"s", &"accion": &"set", &"fuente": &"f", &"valor": 0.5})
	assert_int(_errors.fails.size()).is_equal(0)


# --- validation (release) ----------------------------------------------

func test_release_unregistered_name_is_dropped_with_a_log_line() -> void:
	_errors.strict = false
	var hits: Array[int] = [0]
	_ch.subscribe(NoticeChannel.Kind.NOTICE, &"not_a_notice", func(_p: Dictionary) -> void: hits[0] += 1)
	_ch.notify(&"not_a_notice")
	assert_int(hits[0]).is_equal(0)
	assert_int(_log.lines.size()).is_equal(1)


func test_release_does_not_validate_the_payload_schema() -> void:
	_errors.strict = false
	var hits: Array[int] = [0]
	_ch.subscribe(NoticeChannel.Kind.NOTICE, NoticeIds.SCENE_READY, func(_p: Dictionary) -> void: hits[0] += 1)
	_ch.notify(NoticeIds.SCENE_READY, {&"extra": 1})
	assert_int(hits[0]).is_equal(1)
	assert_int(_log.lines.size()).is_equal(0)


func test_channel_without_schema_accepts_any_name() -> void:
	var plain: NoticeChannel = NoticeChannel.new(64, _log, _errors)
	var hits: Array[int] = [0]
	plain.subscribe(NoticeChannel.Kind.NOTICE, &"anything", func(_p: Dictionary) -> void: hits[0] += 1)
	plain.notify(&"anything", {&"a": 1})
	assert_int(hits[0]).is_equal(1)
	assert_int(_errors.fails.size()).is_equal(0)


# --- InteractionNotice (D11) -------------------------------------------

func test_is_done_true_only_for_hecho() -> void:
	assert_bool(InteractionNotice.is_done({&"resultado": &"HECHO"})).is_true()
	assert_bool(InteractionNotice.is_done({&"resultado": &"SIN_EFECTO"})).is_false()
	assert_bool(InteractionNotice.is_done({&"resultado": &"GESTO_RECHAZADO"})).is_false()
	assert_bool(InteractionNotice.is_done({&"resultado": &"TOQUE_CORTO"})).is_false()


func test_is_done_false_for_missing_key_wrong_case_or_wrong_type() -> void:
	assert_bool(InteractionNotice.is_done({})).is_false()
	assert_bool(InteractionNotice.is_done({&"resultado": &"hecho"})).is_false()
	assert_bool(InteractionNotice.is_done({&"resultado": "HECHO"})).is_false()
	assert_bool(InteractionNotice.is_done({&"resultado": 1})).is_false()
