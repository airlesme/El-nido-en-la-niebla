## Schema of `assets/data/player/player.json` (ADR-0012 § Key Interfaces «PlayerConfig», ADR-0005 D1/D2). Owned by system 2.
## Shape: `{schema_version: 1, <knob>: number, ..., propietarios_camara: [...], sostenibles_escena: [...],
## gestures: {ID: {...}}}`. Keys keep the GDD 2 names (`design/gdd/jugador-en-primera-persona.md` § Tuning Knobs);
## angles carry the `_deg` suffix (ADR-0012 D4) and `PlayerConfig` converts them once. Ranges are the GDD "rango seguro".
## `campo_vision` and `balanceo_camara` are Settings (GDD 6), not here. `radio_sensor_zona` is optional (ADR-0005 D1).
## Cross-field checks here: `g_reducido < g_completo`, `pitch_max_deg < 90`, gesture shape and blocking
## `duration_s <= t_transicion_max`. The two checks that need the engine or the registry (`f_fisica` = tick rate,
## `2*radio_capsula + margen_paso` = `player_min_passage_width_m`) live in `PlayerConfig`, which gets both injected.
## TODO(ADR-0012): the gesture entry keys beyond the three examples of D9 (`hand` set, `also_suspends`) follow GDD 2 Core Rules 24.
## Example: `var entry := DataCatalog.Entry.new("player/player.json", PlayerSchema.new())`.
class_name PlayerSchema extends DataSchema

const GESTURE_ID_PATTERN: String = "^[A-Z][A-Z0-9_]*$"


## Cross-field checks a FieldSpec tree cannot express.
class PlayerRules extends FileRules:
	func check(value: Variant, file: String, issues: Array[DataIssue]) -> void:
		var c: Dictionary = value
		if float(c["g_reducido"]) >= float(c["g_completo"]):
			issues.append(_err(file, "g_reducido", &"range", "g_reducido must be below g_completo"))
		if float(c["pitch_max_deg"]) >= 90.0:
			issues.append(_err(file, "pitch_max_deg", &"range", "pitch_max_deg must be below 90"))
		_check_gestures(c, file, issues)


	func _check_gestures(c: Dictionary, file: String, issues: Array[DataIssue]) -> void:
		var tope: float = float(c["t_transicion_max"])
		var gestures: Dictionary = c["gestures"]
		for id: Variant in gestures:
			var g: Dictionary = gestures[id]
			var base: String = "gestures.%s" % id
			if g["kind"] == &"blocking":
				if not g.has("duration_s"):
					issues.append(_err(file, base + ".duration_s", &"required", "blocking gesture needs duration_s"))
				elif float(g["duration_s"]) > tope:
					issues.append(_err(file, base + ".duration_s", &"range",
							"blocking duration %s exceeds t_transicion_max %s" % [g["duration_s"], tope]))
			elif g.has("duration_s"):
				issues.append(_err(file, base + ".duration_s", &"unknown_key", "background gesture loops: no duration_s"))
			if g.has("chain_on_complete") and not gestures.has(String(g["chain_on_complete"])):
				issues.append(_err(file, base + ".chain_on_complete", &"ref",
						"chain target %s is not in gestures" % g["chain_on_complete"]))


	static func _err(file: String, path: String, rule: StringName, msg: String) -> DataIssue:
		return DataIssue.new(DataIssue.Severity.ERROR, file, path, rule, msg)


func version() -> int:
	return 1


func root() -> FieldSpec:
	var hands: Array[StringName] = [&"right", &"left", &"both", &"held"]
	var side: Array[StringName] = [&"right", &"left"]
	var kinds: Array[StringName] = [&"blocking", &"background"]
	var gesture: FieldSpec = object_({
		"hand": enum_(hands),
		"kind": enum_(kinds),
	}, {
		"duration_s": float_(0.05, 5.0),
		"also_suspends": array_(enum_(side)),
		"uses_held": bool_(),
		"requires_held": bool_(),
		"chain_on_complete": id_(GESTURE_ID_PATTERN),
	})
	return object_({
		"v_paseo": float_(1.0, 2.2),
		"k_atras": float_(0.5, 1.0),
		"k_lat": float_(0.7, 1.0),
		"t_acel": float_(0.05, 0.5),
		"t_freno": float_(0.05, 0.4),
		"radio_capsula": float_(0.25, 0.25), # fixed: 2*r + margen_paso = 0.60 of the registry
		"margen_paso": float_(0.10, 0.10), # fixed
		"altura_capsula": float_(1.70, 1.85),
		"altura_ojos": float_(1.62, 1.62), # fixed (slice A.0)
		"pitch_max_deg": float_(60.0, 89.0),
		"pitch_cesion_max_deg": float_(80.0, 89.0),
		"propietarios_camara": array_(id_("^[a-z_]+:[a-z_]+$"), 1),
		"fov_h_max_deg": float_(100.0, 140.0),
		"near": float_(0.03, 0.10),
		"fov_manos_deg": float_(40.0, 75.0),
		"g_completo": float_(0.8, 1.5),
		"g_reducido": float_(0.2, 0.6),
		"t_cambio_balanceo": float_(0.1, 1.0),
		"l_paso": float_(0.6, 0.9),
		"a_v": float_(0.0, 0.03),
		"a_h": float_(0.0, 0.02),
		"a_manos": float_(0.0, 0.02),
		"phi_ret": float_(0.0, 1.5),
		"k_in": float_(0.0, 0.0005),
		"tau_in": float_(0.05, 0.3),
		"x_in_max": float_(0.0, 0.05),
		"a_resp": float_(0.0, 0.006),
		"f_resp": float_(0.15, 0.4),
		"i_paso_min": float_(0.2, 0.8),
		"t_devolver": float_(0.2, 1.5),
		"t_transicion_max": float_(1.0, 5.0),
		"t_hist": float_(0.6, 2.0),
		"t_giro": float_(0.2, 1.0),
		"f_fisica": int_(1, 1000), # compared with the engine tick rate by PlayerConfig
		"t_atasco": float_(0.25, 2.0),
		"t_pose_segura": float_(0.1, 1.0),
		"y_min": float_(-10.0, -1.0),
		"eps_atasco_m": float_(0.005, 0.05),
		"t_item_dentro": float_(0.15, 0.6),
		"t_item_fuera": float_(0.15, 0.6),
		"t_mano_s": float_(0.2, 0.8),
		"sostenibles_escena": array_(id_("^[A-Z][0-9]{2}$")),
		"gestures": map_(GESTURE_ID_PATTERN, gesture),
	}, {
		"radio_sensor_zona": float_(0.02, 0.05),
	})


func rules() -> FileRules:
	return PlayerRules.new()
