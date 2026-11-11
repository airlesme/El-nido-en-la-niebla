extends GdUnitTestSuite
## EC-001: InputTypes, BindingTable and default_bindings.json (AC-01, AC-04 part L, AC-19 first half,
## missing/invalid file -> fatal). Fixtures are the shipped file parsed once and mutated in memory,
## served by MemoryFileStore; only the shipped-file tests read the real file from disk.

const FULL_PATH: String = "res://assets/data/input/default_bindings.json"
const SHIPPED: String = "res://assets/data/input/default_bindings.json"

var _store: MemoryFileStore
var _fatal: RecordingFatalHandler
var _log: RecordingLog


func before_test() -> void:
	_store = MemoryFileStore.new()
	_fatal = RecordingFatalHandler.new()
	_log = RecordingLog.new()


func _ctx() -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(true)
	c.fatal = _fatal
	c.files = _store
	c.freeze()
	return c


## The shipped file as a Dictionary (the fixture base).
func _doc() -> Dictionary:
	var text: String = FileAccess.get_file_as_string(SHIPPED)
	return JSON.parse_string(text) as Dictionary


func _put(doc: Dictionary) -> void:
	_store.put_text(FULL_PATH, JSON.stringify(doc))


func _action(doc: Dictionary, name: String) -> Dictionary:
	for a: Variant in doc["actions"]:
		if (a as Dictionary)["name"] == name:
			return a
	return {}


func _load() -> BindingTable:
	var t: BindingTable = BindingTable.new()
	t.load_defaults(_ctx())
	return t


func _expect_fatal(param: String) -> void:
	var t: BindingTable = BindingTable.new()
	assert_int(t.load_defaults(_ctx())).is_equal(ERR_INVALID_DATA)
	assert_int(_fatal.calls.size()).is_equal(1)
	assert_str(str(_fatal.calls[0][&"code"])).is_equal("CATALOGO_INVALIDO")
	assert_str(str((_fatal.calls[0][&"detail"] as Dictionary)[&"param"])).is_equal(param)
	assert_bool(t.is_loaded()).is_false()
	assert_int(t.action_names().size()).is_equal(0)


func _raw(kind: InputTypes.RawKind, code: int, value: float = 1.0) -> InputTypes.RawInput:
	var r: InputTypes.RawInput = InputTypes.RawInput.new()
	r.kind = kind
	r.code = code
	r.value = value
	return r


# --- InputTypes ------------------------------------------------------------------

func test_input_binding_equals_compares_kind_code_and_axis_dir() -> void:
	var a: InputTypes.InputBinding = InputTypes.InputBinding.new()
	a.kind = InputTypes.RawKind.PAD_AXIS
	a.code = 1
	a.axis_dir = -1
	var b: InputTypes.InputBinding = InputTypes.InputBinding.new()
	b.kind = InputTypes.RawKind.PAD_AXIS
	b.code = 1
	b.axis_dir = -1

	assert_bool(a.equals(b)).is_true()
	b.axis_dir = 1
	assert_bool(a.equals(b)).is_false()
	b.axis_dir = -1
	b.code = 0
	assert_bool(a.equals(b)).is_false()
	b.code = 1
	b.kind = InputTypes.RawKind.PAD_BUTTON
	assert_bool(a.equals(b)).is_false()


func test_input_types_enums_match_adr_0006() -> void:
	assert_int(InputTypes.Context.size()).is_equal(8)
	assert_int(InputTypes.Context.SIN_CONTROL).is_equal(7)
	assert_int(InputTypes.Device.KEYBOARD_MOUSE).is_equal(0)
	assert_int(InputTypes.Device.GAMEPAD).is_equal(1)
	assert_int(InputTypes.Device.ACTIVE).is_equal(-1)
	assert_int(InputTypes.PadFamily.size()).is_equal(3)
	assert_int(InputTypes.RebindStatus.size()).is_equal(9)
	assert_str(str(InputTypes.OWNER_INPUT_ROUTER)).is_equal("input_router")


func test_rebind_result_defaults_to_no_conflict() -> void:
	var r: InputTypes.RebindResult = InputTypes.RebindResult.new()

	assert_str(str(r.conflict_action)).is_equal("")
	assert_int(r.conflict_slot).is_equal(-1)


func test_catalog_registers_default_bindings_schema() -> void:
	var found: bool = false
	for e: DataCatalog.Entry in DataCatalog.entries():
		if e.rel_path == BindingTable.PATH and e.schema is DefaultBindingsSchema:
			found = true
	assert_bool(found).is_true()


# --- AC-01: only the physical actions ------------------------------------------------

func test_shipped_file_loads_exactly_the_13_physical_actions() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = BindingTable.new()

	assert_int(t.load_defaults(_ctx())).is_equal(OK)

	assert_bool(_fatal.has_failed()).is_false()
	assert_bool(t.is_loaded()).is_true()
	var names: Array[StringName] = t.action_names()
	assert_int(names.size()).is_equal(13)
	for n: StringName in DefaultBindingsSchema.PHYSICAL_ACTIONS:
		assert_bool(t.has_action(n)).is_true()


func test_derived_gestures_and_removed_actions_are_not_actions() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	for n: StringName in [&"leer", &"agarrar", &"rotar", &"mantener", &"repasar_bolsillo",
			&"correr", &"agacharse", &"saltar"]:
		assert_bool(t.has_action(n)).is_false()
		assert_int(t.get_bindings(n, InputTypes.Device.GAMEPAD).size()).is_equal(0)


func test_file_declaring_a_derived_gesture_is_fatal() -> void:
	for bad: String in ["leer", "agarrar", "rotar", "mantener", "correr", "agacharse", "saltar"]:
		before_test()
		var doc: Dictionary = _doc()
		(_action(doc, "seleccionar"))["name"] = bad
		_put(doc)
		_expect_fatal("actions[6].name")


func test_extra_action_beyond_the_13_is_fatal() -> void:
	var doc: Dictionary = _doc()
	(doc["actions"] as Array).append({"name": "saltar", "keyboard_mouse": [], "gamepad": []})
	_put(doc)
	_expect_fatal("actions[13].name")


func test_missing_action_is_fatal() -> void:
	var doc: Dictionary = _doc()
	(doc["actions"] as Array).pop_back()
	_put(doc)
	_expect_fatal("actions")


func test_duplicate_action_is_fatal() -> void:
	var doc: Dictionary = _doc()
	(_action(doc, "pausa"))["name"] = "interactuar"
	_put(doc)
	_expect_fatal("actions[3].name")


func test_shipped_default_assignments_match_the_gdd_table() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()
	var km: InputTypes.Device = InputTypes.Device.KEYBOARD_MOUSE
	var pad: InputTypes.Device = InputTypes.Device.GAMEPAD

	var inter: Array[InputTypes.InputBinding] = t.get_bindings(&"interactuar", km)
	assert_int(inter.size()).is_equal(2)
	assert_int(inter[0].kind).is_equal(InputTypes.RawKind.KEY)
	assert_int(inter[0].code).is_equal(KEY_E)
	assert_int(inter[1].kind).is_equal(InputTypes.RawKind.MOUSE_BUTTON)
	assert_int(inter[1].code).is_equal(MOUSE_BUTTON_LEFT)
	assert_int(t.get_bindings(&"interactuar", pad)[0].code).is_equal(JOY_BUTTON_A)
	assert_int(t.get_bindings(&"atrás", km)[0].code).is_equal(MOUSE_BUTTON_RIGHT)
	assert_int(t.get_bindings(&"atrás", pad)[0].code).is_equal(JOY_BUTTON_B)
	assert_int(t.get_bindings(&"pausa", km)[0].code).is_equal(KEY_ESCAPE)
	assert_int(t.get_bindings(&"pausa", pad)[0].code).is_equal(JOY_BUTTON_START)
	assert_int(t.get_bindings(&"ui_aceptar", km)[0].code).is_equal(KEY_ENTER)
	assert_int(t.get_bindings(&"ui_arriba", km)[0].code).is_equal(KEY_UP)
	assert_int(t.get_bindings(&"ui_abajo", km)[0].code).is_equal(KEY_DOWN)
	assert_int(t.get_bindings(&"ui_izquierda", km)[0].code).is_equal(KEY_LEFT)
	assert_int(t.get_bindings(&"ui_derecha", km)[0].code).is_equal(KEY_RIGHT)
	assert_int(t.get_bindings(&"ui_arriba", pad)[0].code).is_equal(JOY_BUTTON_DPAD_UP)
	assert_int(t.get_bindings(&"ui_derecha", pad)[0].code).is_equal(JOY_BUTTON_DPAD_RIGHT)
	var keys: Array[int] = []
	for b: InputTypes.InputBinding in t.get_bindings(&"mover", km):
		keys.append(b.code)
	assert_array(keys).is_equal([KEY_W, KEY_S, KEY_A, KEY_D])
	assert_int(t.get_bindings(&"mirar", km)[0].kind).is_equal(InputTypes.RawKind.MOUSE_MOTION)
	assert_int(t.get_bindings(&"mirar", pad)[1].code).is_equal(JOY_AXIS_RIGHT_Y)
	assert_int(t.get_bindings(&"mover", pad)[0].code).is_equal(JOY_AXIS_LEFT_X)


func test_active_device_has_no_bindings_in_the_table() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	assert_int(t.get_bindings(&"pausa", InputTypes.Device.ACTIVE).size()).is_equal(0)


# --- AC-04 (part L): no combos, double taps or timers ----------------------------------

func test_binding_with_chord_or_timing_fields_is_fatal() -> void:
	for extra: String in ["chord_with", "double_tap", "reaction_window_s", "combo", "timer"]:
		before_test()
		var doc: Dictionary = _doc()
		var b: Dictionary = (_action(doc, "pausa")["keyboard_mouse"] as Array)[0]
		b[extra] = 1
		_put(doc)
		_expect_fatal("actions[3].keyboard_mouse[0]." + extra)


func test_action_with_a_second_modifier_field_is_fatal() -> void:
	var doc: Dictionary = _doc()
	(_action(doc, "interactuar"))["modifier"] = {"kind": "KEY", "code": KEY_SHIFT}
	_put(doc)
	_expect_fatal("actions[2].modifier")


func test_shipped_waits_are_only_t_hold_and_drag() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var doc: Dictionary = _doc()
	for a: Variant in doc["actions"]:
		for key: Variant in (a as Dictionary):
			assert_bool(key in ["name", "comment", "keyboard_mouse", "gamepad"]).is_true()
		for dev: String in ["keyboard_mouse", "gamepad"]:
			for b: Variant in (a as Dictionary)[dev]:
				for key: Variant in (b as Dictionary):
					assert_bool(key in ["kind", "code", "axis_dir"]).is_true()
	assert_bool(_load().tuning_value(&"t_hold_s") > 0.0).is_true()
	assert_bool(_load().tuning_value(&"d_drag_px") > 0.0).is_true()


func test_keyboard_kind_on_gamepad_list_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((_action(doc, "pausa")["gamepad"] as Array)[0] as Dictionary)["kind"] = "KEY"
	_put(doc)
	_expect_fatal("actions[3].gamepad[0].kind")


func test_axis_dir_on_a_button_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((_action(doc, "pausa")["gamepad"] as Array)[0] as Dictionary)["axis_dir"] = 1
	_put(doc)
	_expect_fatal("actions[3].gamepad[0].axis_dir")


func test_axis_dir_out_of_range_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((_action(doc, "ui_arriba")["gamepad"] as Array)[1] as Dictionary)["axis_dir"] = 2
	_put(doc)
	_expect_fatal("actions[7].gamepad[1].axis_dir")


# --- AC-19 (first half): data, not code --------------------------------------------------

func test_changed_binding_in_the_file_is_reflected_without_code() -> void:
	var doc: Dictionary = _doc()
	((_action(doc, "interactuar")["keyboard_mouse"] as Array)[0] as Dictionary)["code"] = KEY_F
	_put(doc)
	var t: BindingTable = BindingTable.new()

	assert_int(t.load_defaults(_ctx())).is_equal(OK)

	assert_int(t.get_bindings(&"interactuar", InputTypes.Device.KEYBOARD_MOUSE)[0].code).is_equal(KEY_F)
	var raw: InputTypes.RawInput = _raw(InputTypes.RawKind.KEY, KEY_F)
	assert_array(t.actions_for(raw)).is_equal([&"interactuar"])
	assert_array(t.actions_for(_raw(InputTypes.RawKind.KEY, KEY_E))).is_empty()


func test_changed_tuning_value_in_the_file_is_reflected() -> void:
	var doc: Dictionary = _doc()
	((doc["tuning"] as Dictionary)["t_hold_s"] as Dictionary)["value"] = 0.8
	_put(doc)
	var t: BindingTable = _load()

	assert_float(t.tuning_value(&"t_hold_s")).is_equal_approx(0.8, 0.0001)


func test_shipped_tuning_defaults_and_ranges_match_the_gdd() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	assert_float(t.tuning_value(&"k_mouse_deg_per_px")).is_equal_approx(0.10, 0.0001)
	assert_float(t.tuning_value(&"dz_in")).is_equal_approx(0.15, 0.0001)
	assert_float(t.tuning_value(&"dz_out")).is_equal_approx(0.05, 0.0001)
	assert_float(t.tuning_value(&"v_max_px_s")).is_equal_approx(900.0, 0.0001)
	assert_float(t.tuning_value(&"t_hold_s")).is_equal_approx(0.5, 0.0001)
	assert_float(t.tuning_value(&"transition_cap_s")).is_equal_approx(3.0, 0.0001)
	assert_float(t.tuning_range(&"d_drag_px").x).is_equal_approx(4.0, 0.0001)
	assert_float(t.tuning_range(&"d_drag_px").y).is_equal_approx(16.0, 0.0001)
	assert_bool(t.toggle_default(&"attract_assist")).is_true()
	assert_bool(t.toggle_default(&"toggle_instead_of_hold")).is_false()
	assert_bool(is_nan(t.tuning_value(&"nope"))).is_true()
	assert_bool(t.toggle_default(&"nope")).is_false()


func test_tuning_value_outside_its_range_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((doc["tuning"] as Dictionary)["t_hold_s"] as Dictionary)["value"] = 1.6
	_put(doc)
	_expect_fatal("tuning.t_hold_s.value")


func test_tuning_value_at_the_range_limits_is_accepted() -> void:
	for v: float in [0.3, 1.5]:
		before_test()
		var doc: Dictionary = _doc()
		((doc["tuning"] as Dictionary)["t_hold_s"] as Dictionary)["value"] = v
		_put(doc)
		assert_int(BindingTable.new().load_defaults(_ctx())).is_equal(OK)
	assert_bool(_fatal.has_failed()).is_false()


func test_tuning_min_above_max_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((doc["tuning"] as Dictionary)["d_drag_px"] as Dictionary)["min"] = 20.0
	_put(doc)
	_expect_fatal("tuning.d_drag_px.min")


func test_dz_out_above_dz_in_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((doc["tuning"] as Dictionary)["dz_out"] as Dictionary)["value"] = 0.2
	((doc["tuning"] as Dictionary)["dz_in"] as Dictionary)["value"] = 0.1
	((doc["tuning"] as Dictionary)["dz_in"] as Dictionary)["min"] = 0.05
	_put(doc)
	_expect_fatal("tuning.dz_out.value")


func test_missing_tuning_key_is_fatal() -> void:
	var doc: Dictionary = _doc()
	(doc["tuning"] as Dictionary).erase("v_max_px_s")
	_put(doc)
	_expect_fatal("tuning.v_max_px_s")


func test_unknown_tuning_key_is_fatal() -> void:
	var doc: Dictionary = _doc()
	(doc["tuning"] as Dictionary)["t_double_tap_s"] = {"value": 0.2, "min": 0.1, "max": 0.5}
	_put(doc)
	_expect_fatal("tuning.t_double_tap_s")


func test_string_tuning_value_is_fatal() -> void:
	var doc: Dictionary = _doc()
	((doc["tuning"] as Dictionary)["t_hold_s"] as Dictionary)["value"] = "0.5"
	_put(doc)
	_expect_fatal("tuning.t_hold_s.value")


# --- missing or invalid file -> fatal with the culprit -----------------------------------------

func test_missing_file_is_fatal() -> void:
	_expect_fatal("$")


func test_corrupt_json_is_fatal() -> void:
	_store.put_text(FULL_PATH, "{ not json")
	_expect_fatal("$")


func test_wrong_schema_version_is_fatal() -> void:
	var doc: Dictionary = _doc()
	doc["schema_version"] = 2
	_put(doc)
	_expect_fatal("schema_version")


func test_minimum_action_without_gamepad_binding_is_fatal() -> void:
	for n: String in ["interactuar", "atrás", "pausa"]:
		before_test()
		var doc: Dictionary = _doc()
		(_action(doc, n)["gamepad"] as Array).clear()
		_put(doc)
		var t: BindingTable = BindingTable.new()
		assert_int(t.load_defaults(_ctx())).is_equal(ERR_INVALID_DATA)
		assert_bool(_fatal.has_failed()).is_true()


func test_duplicate_binding_in_one_list_is_fatal() -> void:
	var doc: Dictionary = _doc()
	var list: Array = _action(doc, "interactuar")["keyboard_mouse"]
	list.append((list[0] as Dictionary).duplicate())
	_put(doc)
	_expect_fatal("actions[2].keyboard_mouse[2]")


func test_failed_reload_leaves_the_table_empty() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = BindingTable.new()
	assert_int(t.load_defaults(_ctx())).is_equal(OK)

	_store.put_text(FULL_PATH, "{ not json")

	assert_int(t.load_defaults(_ctx())).is_equal(ERR_INVALID_DATA)
	assert_bool(t.is_loaded()).is_false()
	assert_bool(t.has_action(&"pausa")).is_false()


# --- matching ---------------------------------------------------------------------------

func test_pad_axis_half_matches_only_its_sign() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	var up: Array[StringName] = t.actions_for(_raw(InputTypes.RawKind.PAD_AXIS, JOY_AXIS_LEFT_Y, -0.9))
	var down: Array[StringName] = t.actions_for(_raw(InputTypes.RawKind.PAD_AXIS, JOY_AXIS_LEFT_Y, 0.9))

	assert_bool(&"ui_arriba" in up).is_true()
	assert_bool(&"ui_abajo" in up).is_false()
	assert_bool(&"ui_abajo" in down).is_true()
	assert_bool(&"mover" in up).is_true()
	assert_bool(&"mover_cursor" in up).is_true()


func test_unbound_input_matches_no_action() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	assert_array(t.actions_for(_raw(InputTypes.RawKind.KEY, KEY_Z))).is_empty()
	assert_array(t.actions_for(_raw(InputTypes.RawKind.PAD_BUTTON, JOY_BUTTON_Y))).is_empty()


func test_shared_south_button_matches_the_three_actions_of_distinct_contexts() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	var hits: Array[StringName] = t.actions_for(_raw(InputTypes.RawKind.PAD_BUTTON, JOY_BUTTON_A))

	assert_array(hits).contains_exactly_in_any_order([&"interactuar", &"seleccionar", &"ui_aceptar"])


func test_get_bindings_returns_a_copy() -> void:
	_store.put_text(FULL_PATH, FileAccess.get_file_as_string(SHIPPED))
	var t: BindingTable = _load()

	t.get_bindings(&"pausa", InputTypes.Device.GAMEPAD).clear()

	assert_int(t.get_bindings(&"pausa", InputTypes.Device.GAMEPAD).size()).is_equal(1)
