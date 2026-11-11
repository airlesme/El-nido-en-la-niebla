## Schema of `assets/data/interaction/interaction_config.json` (ADR-0011 D1/D3, ADR-0005 D2). Owned by system 7.
## Shape: `{schema_version: 1, <knob>: number, ...}`: one flat object with the Tuning Knobs of GDD 7
## (`design/gdd/interaccion-e-inspeccion.md` § Tuning Knobs). The safe ranges below are the GDD ranges.
## The two masks are validated against the layer table of ADR-0011 D1: `mascara_interactuable` must be
## bit 3 and `mascara_geometria` bit 1; any other value is a data error (TR-interact-004).
## TODO(ADR-0005): `interaction/interaction_config.json` is not in the D1 file table (only
## `interactables.json` is); it is registered here as an ADR-fallback (same owner, same scene-load policy).
## Example: `var entry := DataCatalog.Entry.new("interaction/interaction_config.json", InteractionConfigSchema.new())`.
class_name InteractionConfigSchema extends DataSchema


## Cross-field checks a FieldSpec tree cannot express.
class ConfigRules extends FileRules:
	func check(value: Variant, file: String, issues: Array[DataIssue]) -> void:
		var c: Dictionary = value
		if int(c["mascara_interactuable"]) != InteractionTypes.LAYER_INTERACTABLE:
			issues.append(_err(file, "mascara_interactuable", &"mask",
					"must be bit 3 (%d), got %d" % [InteractionTypes.LAYER_INTERACTABLE, c["mascara_interactuable"]]))
		if int(c["mascara_geometria"]) != InteractionTypes.OCCLUSION_MASK:
			issues.append(_err(file, "mascara_geometria", &"mask",
					"must be bit 1 (%d), got %d" % [InteractionTypes.OCCLUSION_MASK, c["mascara_geometria"]]))
		if float(c["pie_min_s"]) > float(c["pie_max_s"]):
			issues.append(_err(file, "pie_min_s", &"range", "pie_min_s must not exceed pie_max_s"))
		if float(c["d_ins_min"]) > float(c["d_ins_max"]):
			issues.append(_err(file, "d_ins_min", &"range", "d_ins_min must not exceed d_ins_max"))


	static func _err(file: String, path: String, rule: StringName, msg: String) -> DataIssue:
		return DataIssue.new(DataIssue.Severity.ERROR, file, path, rule, msg)


func version() -> int:
	return 1


func root() -> FieldSpec:
	return object_({
		"alcance_interaccion_m": float_(1.2, 3.0),
		"radio_apuntado_m": float_(0.0, 0.15),
		"radio_pegajoso_m": float_(0.0, 0.3),
		"t_gracia_foco_s": float_(0.0, 0.3),
		"desempate_prof_m": float_(0.01, 0.08),
		"mascara_interactuable": int_(0, 1 << 20),
		"mascara_geometria": int_(0, 1 << 20),
		"max_contactos_por_paso": int_(1, 64),
		"t_anillo_inicio_s": float_(0.05, 0.25),
		"t_enfriamiento_s": float_(0.1, 0.6),
		"latencia_feedback_ms": int_(50, 200),
		"pick_min_px": float_(32.0, 64.0),
		"r_max_inspeccion_m": float_(0.05, 0.25),
		"theta_fill_deg": float_(15.0, 40.0),
		"d_ins_min": float_(0.25, 0.4),
		"d_ins_max": float_(0.4, 0.8),
		"k_inspeccion": float_(0.3, 2.0),
		"cps_pie": float_(10.0, 20.0),
		"pie_min_s": float_(1.5, 3.0),
		"pie_max_s": float_(4.0, 12.0),
		"texto_max_caracteres": int_(60, 140),
	})


func rules() -> FileRules:
	return ConfigRules.new()
