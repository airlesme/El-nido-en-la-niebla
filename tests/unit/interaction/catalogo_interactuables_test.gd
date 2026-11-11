extends GdUnitTestSuite
## IP-001: interactables.json + interaction_config.json schemas and InteractionCatalog
## (AC-37, AC-38, AC-15 and AC-26b data parts, mask validation of ADR-0011 D1).
## Valid data comes from the real files; invalid variants are built in memory (MemoryFileStore).

const ITEMS_FULL: String = "res://assets/data/interaction/interactables.json"
const CONFIG_FULL: String = "res://assets/data/interaction/interaction_config.json"
const COVERAGE_FULL: String = "res://tests/fixtures/interaction/cobertura_anexo_a.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary


func _row(id: String) -> Dictionary:
	var items: Array = _json(ITEMS_FULL)["interactables"]
	for e: Variant in items:
		var d: Dictionary = e
		if d["id"] == id:
			return d.duplicate(true)
	return {}


func _items_doc(rows: Array) -> Dictionary:
	return {"schema_version": 1, "interactables": rows}


func _load(items: Dictionary, config: Dictionary = _json(CONFIG_FULL)) -> InteractionCatalog:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(ITEMS_FULL, JSON.stringify(items))
	store.put_text(CONFIG_FULL, JSON.stringify(config))
	return InteractionCatalog.load_from(DataReader.new(store, BuildFlavor.new(true)))


func _rules(cat: InteractionCatalog) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for i: DataIssue in cat.issues:
		if i.severity == DataIssue.Severity.ERROR:
			out.append("%s:%s" % [i.json_path, i.rule])
	return out


func _expect_rule(cat: InteractionCatalog, rule: String) -> void:
	assert_bool(cat.has_errors()).is_true()
	var found: bool = false
	for s: String in _rules(cat):
		if s.ends_with(":" + rule):
			found = true
	assert_bool(found).override_failure_message("expected rule %s in %s" % [rule, _rules(cat)]).is_true()


# --- real data / AC-37 -------------------------------------------------------

func test_real_files_load_without_issues() -> void:
	var cat: InteractionCatalog = InteractionCatalog.load_from(DataReader.new(FileStore.new(), BuildFlavor.new(true)))
	assert_array(cat.issues).is_empty()
	assert_int(cat.ids().size()).is_equal(35)


func test_catalog_ids_equal_coverage_rows_marked_interactuable() -> void:
	var cat: InteractionCatalog = InteractionCatalog.load_from(DataReader.new(FileStore.new(), BuildFlavor.new(true)))
	var expected: Array[String] = []
	var rows: Array = _json(COVERAGE_FULL)["rows"]
	for r: Variant in rows:
		var d: Dictionary = r
		if d["interactuable"]:
			expected.append(String(d["id"]))
	expected.sort()
	var actual: Array[String] = []
	for id: StringName in cat.ids():
		actual.append(String(id))
	assert_array(actual).is_equal(expected)
	assert_int(expected.size()).is_equal(35)


func test_non_interactable_coverage_rows_have_motivo_and_are_not_in_catalog() -> void:
	var cat: InteractionCatalog = InteractionCatalog.load_from(DataReader.new(FileStore.new(), BuildFlavor.new(true)))
	var rows: Array = _json(COVERAGE_FULL)["rows"]
	var excluded: int = 0
	for r: Variant in rows:
		var d: Dictionary = r
		if not d["interactuable"]:
			excluded += 1
			assert_str(String(d.get("motivo", ""))).is_not_empty()
			assert_bool(cat.has(StringName(d["id"]))).is_false()
	assert_int(excluded).is_greater(0)


func test_coverage_ids_are_unique() -> void:
	var seen: Dictionary = {}
	var rows: Array = _json(COVERAGE_FULL)["rows"]
	for r: Variant in rows:
		var id: String = (r as Dictionary)["id"]
		assert_bool(seen.has(id)).is_false()
		seen[id] = true


# --- AC-38 -------------------------------------------------------------------

func test_rule_31_examples_validate() -> void:
	var rows: Array = []
	for id: String in ["V02", "V05", "A02a", "A04", "C05", "D01a", "V01"]:
		rows.append(_row(id))
	var cat: InteractionCatalog = _load(_items_doc(rows))
	assert_array(cat.issues).is_empty()
	assert_bool(cat.has(&"V05")).is_true()
	assert_bool(bool(cat.entry(&"V05")["sostenible"])).is_true()
	assert_float(float(cat.entry(&"D01a")["vista"]["distancia_m"])).is_equal(0.35)


func test_lock_duration_field_is_rejected() -> void:
	var r: Dictionary = _row("V02")
	r["t_bloqueo_s"] = 0.8
	_expect_rule(_load(_items_doc([r])), "unknown_key")


func test_requiere_item_is_rejected() -> void:
	var r: Dictionary = _row("C05")
	r["requiere_item"] = "I-01"
	_expect_rule(_load(_items_doc([r])), "unknown_key")


func test_unknown_field_is_rejected() -> void:
	var r: Dictionary = _row("V04")
	r["color"] = "rojo"
	_expect_rule(_load(_items_doc([r])), "unknown_key")


func test_sostenible_outside_inspeccion_mano_is_rejected() -> void:
	var r: Dictionary = _row("V02")
	r["sostenible"] = true
	_expect_rule(_load(_items_doc([r])), "sostenible")


func test_inspeccion_mano_radius_above_r_max_is_rejected() -> void:
	var r: Dictionary = _row("V05")
	(r["inspeccion"] as Dictionary)["radio_m"] = 0.21
	_expect_rule(_load(_items_doc([r])), "range")


func test_inspeccion_mano_radius_equal_to_r_max_is_accepted() -> void:
	var r: Dictionary = _row("V05")
	(r["inspeccion"] as Dictionary)["radio_m"] = 0.20
	assert_bool(_load(_items_doc([r])).has_errors()).is_false()


func test_vista_block_in_non_delegar_effect_is_rejected() -> void:
	var r: Dictionary = _row("V04")
	r["vista"] = _row("D01a")["vista"]
	r["vista"]["vista_id"] = "V04"
	_expect_rule(_load(_items_doc([r])), "vista")


func test_inspeccion_mano_without_inspeccion_block_is_rejected() -> void:
	var r: Dictionary = _row("V05")
	r.erase("inspeccion")
	_expect_rule(_load(_items_doc([r])), "required")


func test_duplicate_id_is_rejected() -> void:
	_expect_rule(_load(_items_doc([_row("V02"), _row("V02")])), "dup_id")


func test_empty_catalog_is_rejected() -> void:
	_expect_rule(_load(_items_doc([])), "length")


func test_verbo_largo_other_than_leer_is_rejected() -> void:
	var r: Dictionary = _row("A04")
	r["verbo_largo"] = "ABRIR"
	r["etiqueta_largo"] = "UI_VERBO_ABRIR"
	_expect_rule(_load(_items_doc([r])), "verb")


func test_entry_without_any_verb_is_rejected() -> void:
	var r: Dictionary = _row("V04")
	r.erase("verbo_corto")
	r.erase("etiqueta_corto")
	_expect_rule(_load(_items_doc([r])), "verb")


func test_verb_without_label_is_rejected() -> void:
	var r: Dictionary = _row("V04")
	r.erase("etiqueta_corto")
	_expect_rule(_load(_items_doc([r])), "required")


func test_texto_not_matching_id_is_rejected() -> void:
	var r: Dictionary = _row("V04")
	r["texto"] = "OBJ_OTRO"
	_expect_rule(_load(_items_doc([r])), "texto")


func test_view_distance_is_required_and_positive() -> void:
	var r: Dictionary = _row("D01a")
	(r["vista"] as Dictionary).erase("distancia_m")
	_expect_rule(_load(_items_doc([r])), "required")
	var z: Dictionary = _row("C05")
	(z["modo"] as Dictionary)["distancia_m"] = 0
	_expect_rule(_load(_items_doc([z])), "range")


func test_centro_m_is_optional_and_read() -> void:
	var cat: InteractionCatalog = _load(_items_doc([_row("D01a"), _row("D01b")]))
	assert_bool((cat.entry(&"D01a")["vista"] as Dictionary).has("centro_m")).is_true()
	assert_bool((cat.entry(&"D01b")["vista"] as Dictionary).has("centro_m")).is_false()


func test_alcance_defaults_to_global_and_entry_overrides() -> void:
	var r: Dictionary = _row("V02")
	var o: Dictionary = _row("V03")
	o["alcance_m"] = 2.5
	var cat: InteractionCatalog = _load(_items_doc([r, o]))
	assert_float(cat.alcance_m(&"V02")).is_equal(1.8)
	assert_float(cat.alcance_m(&"V03")).is_equal(2.5)
	assert_float(cat.alcance_m(&"ZZZ")).is_equal(0.0)


func test_prioridad_out_of_range_is_rejected() -> void:
	var r: Dictionary = _row("B01")
	r["prioridad"] = 10
	assert_bool(_load(_items_doc([r])).has_errors()).is_true()
	r["prioridad"] = 9
	assert_bool(_load(_items_doc([r])).has_errors()).is_false()


# --- AC-26b (data part): t_vista_entrada_s -----------------------------------

func test_chained_view_entry_time_above_1_2_is_rejected() -> void:
	for id: String in ["D01a", "D01b", "D01c"]:
		var r: Dictionary = _row(id)
		(r["vista"] as Dictionary)["t_vista_entrada_s"] = 1.3
		_expect_rule(_load(_items_doc([r])), "range")


func test_chained_view_entry_time_of_exactly_1_2_is_accepted() -> void:
	var r: Dictionary = _row("D01c")
	(r["vista"] as Dictionary)["t_vista_entrada_s"] = 1.2
	assert_bool(_load(_items_doc([r])).has_errors()).is_false()


func test_non_chained_view_keeps_the_0_6_to_1_5_range() -> void:
	var r: Dictionary = _row("D01d")
	(r["vista"] as Dictionary)["t_vista_entrada_s"] = 1.5
	assert_bool(_load(_items_doc([r])).has_errors()).is_false()
	(r["vista"] as Dictionary)["t_vista_entrada_s"] = 1.51
	assert_bool(_load(_items_doc([r])).has_errors()).is_true()
	(r["vista"] as Dictionary)["t_vista_entrada_s"] = 0.59
	assert_bool(_load(_items_doc([r])).has_errors()).is_true()


func test_box_open_above_max_is_rejected_and_equal_is_accepted() -> void:
	var bad: Array[DataIssue] = InteractionCatalog.check_box_open({"BOX_C1_OPEN": 1.7, "BOX_C2_OPEN": 1.4}, 1.6, "box/box.json")
	assert_int(bad.size()).is_equal(1)
	assert_str(bad[0].json_path).is_equal("BOX_C1_OPEN")
	var ok: Array[DataIssue] = InteractionCatalog.check_box_open({"BOX_C1_OPEN": 1.6, "BOX_C4_OPEN": 1.6}, 1.6, "box/box.json")
	assert_array(ok).is_empty()


func test_box_open_max_outside_its_safe_range_is_rejected() -> void:
	assert_int(InteractionCatalog.check_box_open({}, 1.7, "box/box.json").size()).is_equal(1)
	assert_int(InteractionCatalog.check_box_open({}, 1.1, "box/box.json").size()).is_equal(1)
	assert_int(InteractionCatalog.check_box_open({}, 1.2, "box/box.json").size()).is_equal(0)


# --- AC-15 (data part): texto_max_caracteres ---------------------------------

func test_object_text_of_120_characters_is_rejected() -> void:
	var issues: Array[DataIssue] = InteractionCatalog.check_object_texts(
			{"OBJ_V04": "x".repeat(120)}, 90, "narrative/objects.json")
	assert_int(issues.size()).is_equal(1)
	assert_str(String(issues[0].rule)).is_equal("text_length")


func test_object_text_boundary_90_accepted_91_rejected() -> void:
	assert_array(InteractionCatalog.check_object_texts({"OBJ_A": "x".repeat(90)}, 90, "f")).is_empty()
	assert_int(InteractionCatalog.check_object_texts({"OBJ_A": "x".repeat(91)}, 90, "f").size()).is_equal(1)


func test_text_limit_comes_from_the_config_file() -> void:
	var cat: InteractionCatalog = InteractionCatalog.load_from(DataReader.new(FileStore.new(), BuildFlavor.new(true)))
	assert_int(cat.config_int(&"texto_max_caracteres")).is_equal(90)
	assert_int(InteractionCatalog.check_object_texts(
			{"OBJ_A": "x".repeat(120)}, cat.config_int(&"texto_max_caracteres"), "f").size()).is_equal(1)


# --- masks (ADR-0011 D1) -----------------------------------------------------

func test_masks_of_bit_3_and_bit_1_are_accepted() -> void:
	var cfg: Dictionary = _json(CONFIG_FULL)
	cfg.erase("schema_version")
	cfg["schema_version"] = 1
	assert_bool(_load(_json(ITEMS_FULL), cfg).has_errors()).is_false()
	assert_int(InteractionTypes.LAYER_INTERACTABLE).is_equal(4)
	assert_int(InteractionTypes.OCCLUSION_MASK).is_equal(1)


func test_interactable_mask_other_than_bit_3_is_a_data_error() -> void:
	for bad: int in [0, 1, 2, 5, 8, 12]:
		var cfg: Dictionary = _json(CONFIG_FULL)
		cfg["mascara_interactuable"] = bad
		_expect_rule(_load(_json(ITEMS_FULL), cfg), "mask")


func test_geometry_mask_other_than_bit_1_is_a_data_error() -> void:
	for bad: int in [0, 2, 3, 4, 5, 16]:
		var cfg: Dictionary = _json(CONFIG_FULL)
		cfg["mascara_geometria"] = bad
		_expect_rule(_load(_json(ITEMS_FULL), cfg), "mask")


func test_swapped_masks_are_rejected() -> void:
	var cfg: Dictionary = _json(CONFIG_FULL)
	cfg["mascara_interactuable"] = 1
	cfg["mascara_geometria"] = 4
	assert_int(_rules(_load(_json(ITEMS_FULL), cfg)).size()).is_equal(2)


# --- config knobs ------------------------------------------------------------

func test_config_defaults_match_the_gdd_tuning_knobs() -> void:
	var cat: InteractionCatalog = InteractionCatalog.load_from(DataReader.new(FileStore.new(), BuildFlavor.new(true)))
	assert_float(cat.config_float(&"radio_apuntado_m")).is_equal(0.06)
	assert_float(cat.config_float(&"desempate_prof_m")).is_equal(0.03)
	assert_float(cat.config_float(&"t_gracia_foco_s")).is_equal(0.12)
	assert_float(cat.config_float(&"radio_pegajoso_m")).is_equal(0.15)
	assert_float(cat.config_float(&"t_enfriamiento_s")).is_equal(0.25)
	assert_float(cat.config_float(&"t_anillo_inicio_s")).is_equal(0.12)
	assert_int(cat.config_int(&"latencia_feedback_ms")).is_equal(100)
	assert_int(cat.config_int(&"max_contactos_por_paso")).is_equal(8)
	assert_float(cat.config_float(&"pick_min_px")).is_equal(44.0)


func test_config_value_outside_safe_range_is_rejected() -> void:
	var cfg: Dictionary = _json(CONFIG_FULL)
	cfg["radio_apuntado_m"] = 0.16
	assert_bool(_load(_json(ITEMS_FULL), cfg).has_errors()).is_true()
	cfg["radio_apuntado_m"] = 0.15
	assert_bool(_load(_json(ITEMS_FULL), cfg).has_errors()).is_false()


func test_config_unknown_key_and_missing_key_are_rejected() -> void:
	var cfg: Dictionary = _json(CONFIG_FULL)
	cfg["extra"] = 1
	_expect_rule(_load(_json(ITEMS_FULL), cfg), "unknown_key")
	var cfg2: Dictionary = _json(CONFIG_FULL)
	cfg2.erase("pick_min_px")
	_expect_rule(_load(_json(ITEMS_FULL), cfg2), "required")


func test_invalid_data_yields_an_empty_catalog() -> void:
	var r: Dictionary = _row("V02")
	r["bogus"] = 1
	var cat: InteractionCatalog = _load(_items_doc([r]))
	assert_bool(cat.has_errors()).is_true()
	assert_int(cat.ids().size()).is_equal(0)
	assert_bool(cat.has(&"V02")).is_false()


# --- registry ----------------------------------------------------------------

func test_data_catalog_registers_both_files_with_their_schema() -> void:
	var seen: Dictionary = {}
	for e: DataCatalog.Entry in DataCatalog.entries():
		seen[e.rel_path] = e
	assert_bool(seen.has("interaction/interactables.json")).is_true()
	assert_bool(seen.has("interaction/interaction_config.json")).is_true()
	var e: DataCatalog.Entry = seen["interaction/interactables.json"]
	assert_int(e.owner).is_equal(7)
