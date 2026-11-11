extends GdUnitTestSuite
## PJ-001 (T-U13 of ADR-0012): PlayerSchema + PlayerConfig. AC-41, TR-player-002, TR-player-021.
## Valid data comes from the real file; invalid variants are built in memory (MemoryFileStore), no file I/O.

const PLAYER_FULL: String = "res://assets/data/player/player.json"
const TICK_RATE: int = 60


func _json() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAYER_FULL))
	return parsed as Dictionary


## Loads `doc` (null = no file) and returns [config, fatal handler].
func _load(doc: Variant, rate: int = TICK_RATE, passage: float = PlayerConfig.PLAYER_MIN_PASSAGE_WIDTH_M) -> Array:
	var store: MemoryFileStore = MemoryFileStore.new()
	if doc != null:
		store.put_text(PLAYER_FULL, JSON.stringify(doc))
	var fatal: RecordingFatalHandler = RecordingFatalHandler.new()
	var cfg: PlayerConfig = PlayerConfig.load_from(DataReader.new(store, BuildFlavor.new(true)), fatal, rate, passage)
	return [cfg, fatal]


func _with(key: String, value: Variant) -> Dictionary:
	var d: Dictionary = _json()
	d[key] = value
	return d


func _expect_fatal(result: Array, param: String) -> void:
	var cfg: PlayerConfig = result[0]
	var fatal: RecordingFatalHandler = result[1]
	assert_object(cfg).is_null()
	assert_int(fatal.calls.size()).is_equal(1)
	assert_str(fatal.calls[0][&"code"]).is_equal("CATALOGO_INVALIDO")
	var detail: Dictionary = fatal.calls[0][&"detail"]
	assert_str(detail[&"param"]).is_equal(param)


# --- valid data ---------------------------------------------------------------

func test_real_file_loads_with_gdd_defaults() -> void:
	var r: Array = _load(_json())
	var cfg: PlayerConfig = r[0]
	assert_bool((r[1] as RecordingFatalHandler).has_failed()).is_false()
	assert_float(cfg.v_paseo).is_equal(1.6)
	assert_float(cfg.altura_ojos).is_equal(1.62)
	assert_float(cfg.radio_capsula).is_equal(0.25)
	assert_float(cfg.altura_capsula).is_equal(1.75)
	assert_float(cfg.eps_atasco_m).is_equal(0.02)
	assert_float(cfg.radio_sensor_zona).is_equal(0.05)
	assert_int(cfg.f_fisica).is_equal(60)
	assert_float(cfg.campo_vision_deg).is_equal(70.0)


func test_v_paseo_fixture_value_is_used_without_recompiling() -> void:
	var cfg: PlayerConfig = _load(_with("v_paseo", 2.0))[0]
	assert_float(cfg.v_paseo).is_equal(2.0)


func test_angles_are_converted_to_radians_once() -> void:
	var cfg: PlayerConfig = _load(_json())[0]
	assert_float(cfg.pitch_max).is_equal_approx(deg_to_rad(80.0), 1e-9)
	assert_float(cfg.pitch_cesion_max).is_equal_approx(deg_to_rad(89.0), 1e-9)


func test_gestures_catalogue_is_typed() -> void:
	var cfg: PlayerConfig = _load(_json())[0]
	var pickup: PlayerConfig.GestureDef = cfg.gestures[&"ANIM_PHONE_PICKUP"]
	assert_bool(pickup.is_blocking()).is_true()
	assert_float(pickup.duration_s).is_equal(0.8)
	assert_str(pickup.chain_on_complete).is_equal("HAND_PHONE_HOLD")
	var swipe: PlayerConfig.GestureDef = cfg.gestures[&"HAND_CARD_SWIPE"]
	assert_array(swipe.also_suspends).is_equal([&"left"])
	assert_bool(swipe.uses_held).is_true()
	var hold: PlayerConfig.GestureDef = cfg.gestures[&"HAND_HOLD_ITEM"]
	assert_bool(hold.requires_held).is_true()
	assert_bool(hold.is_blocking()).is_false()
	assert_array(cfg.sostenibles_escena).is_equal([&"V05"])


func test_every_blocking_gesture_fits_t_transicion_max() -> void:
	var cfg: PlayerConfig = _load(_json())[0]
	for id: StringName in cfg.gestures:
		var g: PlayerConfig.GestureDef = cfg.gestures[id]
		if g.is_blocking():
			assert_float(g.duration_s).is_less_equal(cfg.t_transicion_max)


func test_missing_radio_sensor_zona_is_allowed_and_defaults() -> void:
	var d: Dictionary = _json()
	d.erase("radio_sensor_zona")
	var r: Array = _load(d)
	assert_bool((r[1] as RecordingFatalHandler).has_failed()).is_false()
	assert_float((r[0] as PlayerConfig).radio_sensor_zona).is_equal(0.05)


func test_radio_sensor_zona_range_edges() -> void:
	assert_object(_load(_with("radio_sensor_zona", 0.02))[0]).is_not_null()
	assert_object(_load(_with("radio_sensor_zona", 0.05))[0]).is_not_null()
	_expect_fatal(_load(_with("radio_sensor_zona", 0.019)), "radio_sensor_zona")


# --- AC-41 invalid data -------------------------------------------------------

func test_capsule_radius_030_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with("radio_capsula", 0.30)), "radio_capsula")


func test_capsule_radius_040_is_fatal_with_param_name() -> void:
	_expect_fatal(_load(_with("radio_capsula", 0.40)), "radio_capsula")


func test_pitch_max_95_is_fatal() -> void:
	_expect_fatal(_load(_with("pitch_max_deg", 95.0)), "pitch_max_deg")


func test_pitch_max_90_is_fatal() -> void:
	_expect_fatal(_load(_with("pitch_max_deg", 90.0)), "pitch_max_deg")


func test_t_hist_04_is_fatal() -> void:
	_expect_fatal(_load(_with("t_hist", 0.4)), "t_hist")


func test_t_hist_lower_bound_06_is_valid() -> void:
	assert_object(_load(_with("t_hist", 0.6))[0]).is_not_null()


func test_g_reducido_not_below_g_completo_is_fatal() -> void:
	var d: Dictionary = _json()
	d["g_completo"] = 0.8
	d["g_reducido"] = 0.8
	var r: Array = _load(d)
	assert_object(r[0]).is_null()
	assert_bool((r[1] as RecordingFatalHandler).has_failed()).is_true()
	var detail: Dictionary = (r[1] as RecordingFatalHandler).calls[0][&"detail"]
	assert_str(detail[&"param"]).is_equal("g_reducido")


func test_radio_sensor_zona_010_is_fatal() -> void:
	_expect_fatal(_load(_with("radio_sensor_zona", 0.10)), "radio_sensor_zona")


func test_missing_file_is_fatal_and_creates_no_config() -> void:
	_expect_fatal(_load(null), "$")


func test_missing_required_key_names_the_parameter() -> void:
	var d: Dictionary = _json()
	d.erase("v_paseo")
	_expect_fatal(_load(d), "v_paseo")


func test_wrong_type_names_the_parameter() -> void:
	_expect_fatal(_load(_with("v_paseo", "fast")), "v_paseo")


func test_unknown_key_is_fatal() -> void:
	_expect_fatal(_load(_with("salto", 1.0)), "salto")


func test_v_paseo_range_edges() -> void:
	assert_object(_load(_with("v_paseo", 1.0))[0]).is_not_null()
	assert_object(_load(_with("v_paseo", 2.2))[0]).is_not_null()
	_expect_fatal(_load(_with("v_paseo", 0.99)), "v_paseo")
	_expect_fatal(_load(_with("v_paseo", 2.21)), "v_paseo")


# --- TR-player-002: passage invariant ------------------------------------------

func test_passage_invariant_mismatch_is_fatal() -> void:
	_expect_fatal(_load(_json(), TICK_RATE, 0.70), "radio_capsula")


# --- TR-player-021 / D1: tick rate ----------------------------------------------

func test_f_fisica_different_from_engine_rate_is_fatal() -> void:
	_expect_fatal(_load(_json(), 120), "f_fisica")


func test_f_fisica_other_than_60_in_data_is_fatal_at_60() -> void:
	_expect_fatal(_load(_with("f_fisica", 30)), "f_fisica")


# --- gestures -------------------------------------------------------------------

func _gesture_doc(id: String, entry: Dictionary) -> Dictionary:
	var d: Dictionary = _json()
	var g: Dictionary = d["gestures"]
	g[id] = entry
	return d


func test_blocking_gesture_over_t_transicion_max_is_fatal() -> void:
	var d: Dictionary = _gesture_doc("HAND_REACH", {"hand": "right", "kind": "blocking", "duration_s": 3.5})
	_expect_fatal(_load(d), "gestures.HAND_REACH.duration_s")


func test_blocking_gesture_exactly_t_transicion_max_is_valid() -> void:
	var d: Dictionary = _gesture_doc("HAND_REACH", {"hand": "right", "kind": "blocking", "duration_s": 3.0})
	assert_object(_load(d)[0]).is_not_null()


func test_blocking_gesture_without_duration_is_fatal() -> void:
	var d: Dictionary = _gesture_doc("HAND_REACH", {"hand": "right", "kind": "blocking"})
	_expect_fatal(_load(d), "gestures.HAND_REACH.duration_s")


func test_background_gesture_with_duration_is_fatal() -> void:
	var d: Dictionary = _gesture_doc("HAND_READ", {"hand": "left", "kind": "background", "duration_s": 1.0})
	_expect_fatal(_load(d), "gestures.HAND_READ.duration_s")


func test_chain_to_unknown_gesture_is_fatal() -> void:
	var d: Dictionary = _gesture_doc("HAND_REACH",
			{"hand": "right", "kind": "blocking", "duration_s": 0.5, "chain_on_complete": "HAND_NOPE"})
	_expect_fatal(_load(d), "gestures.HAND_REACH.chain_on_complete")


func test_unknown_hand_is_fatal() -> void:
	var d: Dictionary = _gesture_doc("HAND_REACH", {"hand": "foot", "kind": "blocking", "duration_s": 0.5})
	_expect_fatal(_load(d), "gestures.HAND_REACH.hand")


func test_t_transicion_max_lowered_makes_long_gesture_fatal() -> void:
	# HAND_DRAWER lasts 1.2 s in the real data.
	_expect_fatal(_load(_with("t_transicion_max", 1.0)), "gestures.HAND_DRAWER.duration_s")


# --- registry --------------------------------------------------------------------

func test_registry_row_player_json_has_schema_owner_and_fatal_code() -> void:
	var found: bool = false
	for e: DataCatalog.Entry in DataCatalog.entries():
		if e.rel_path == "player/player.json":
			found = true
			assert_int(e.owner).is_equal(2)
			assert_str(e.fatal_code).is_equal("CATALOGO_INVALIDO")
			assert_object(e.schema).is_instanceof(PlayerSchema)
	assert_bool(found).is_true()


func test_real_file_has_no_issues_through_the_reader() -> void:
	var r: DataResult = DataReader.new(FileStore.new(), BuildFlavor.new(true)).read_file(
			DataCatalog.Entry.new("player/player.json", PlayerSchema.new()))
	assert_array(r.issues).is_empty()
