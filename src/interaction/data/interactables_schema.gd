## Schema of `assets/data/interaction/interactables.json` (ADR-0011 D2, ADR-0005 D2/G-6/G-7). Owned by system 7.
## Shape: `{schema_version: 1, interactables: [entry]}` (G-6: open ID collection = array of records with `id`).
## Entry fields: GDD 7 rule 31. The objects are closed (G-7): a duration-of-lock field, `requiere_item`
## or any unknown key is an `unknown_key` error. Intra-file semantics live in `CatalogRules`; checks that
## need `interaction_config.json` (`radio_m` vs `r_max_inspeccion_m`) are in `InteractionCatalog`.
## `vista`/`modo` carry `distancia_m` (required, > 0) and `centro_m` (optional, (0,0)) per ADR-0011 OI-2.
## TODO(design/gdd/interaccion-e-inspeccion.md): `distancia_m` of V01, C05, D01b-D01d, the `ANC_*` anchors and
## `DOC_LIBRO_VISITAS` (R01) are provisional (the GDD fixes only D01a = 0,35 m / centro (0,185; 0)).
## TODO(GDD 7): `cursor_inicial` accepts only `centro`; a point of the view has no FieldSpec yet (no entry uses it).
## Example: `var entry := DataCatalog.Entry.new("interaction/interactables.json", InteractablesSchema.new())`.
class_name InteractablesSchema extends DataSchema

const VERBS: Array[StringName] = [
	&"ABRIR", &"GIRAR", &"EXAMINAR", &"LEER", &"DESCOLGAR", &"ENCENDER", &"APAGAR", &"IMPRIMIR",
	&"USAR", &"ENTRAR",
]
const EFFECTS: Array[StringName] = [
	&"DELEGAR", &"INSPECCION_MANO", &"INSPECCION_TEXTO", &"LEER", &"ABRIR_VISTA", &"ABRIR_ORDENADOR",
]
## Chained views (box compartments): `t_vista_entrada_s` <= 1,2 s (GDD 7 rule 19, AC-26b).
const CHAINED_VIEW_IDS: Array[StringName] = [&"D01a", &"D01b", &"D01c"]
const T_VISTA_CHAINED_MAX_S: float = 1.2
const T_VISTA_MIN_S: float = 0.6
const T_VISTA_MAX_S: float = 1.5
const ID_PATTERN: String = "^[A-Z][0-9]{2}[a-d]?$"


## Semantic checks a FieldSpec tree cannot express.
class CatalogRules extends FileRules:
	func check(value: Variant, file: String, issues: Array[DataIssue]) -> void:
		var root: Dictionary = value
		var rows: Array = root["interactables"]
		for i: int in rows.size():
			var e: Dictionary = rows[i]
			_check_entry(e, "interactables[%d]" % i, file, issues)


	func _check_entry(e: Dictionary, p: String, file: String, issues: Array[DataIssue]) -> void:
		var id: String = String(e["id"])
		var effect: StringName = e["efecto"]
		var corto: StringName = _verb(e, "verbo_corto")
		var largo: StringName = _verb(e, "verbo_largo")
		if corto == &"" and largo == &"":
			issues.append(_err(file, p, &"verb", "at least one of verbo_corto / verbo_largo"))
		if largo != &"" and largo != &"LEER":
			issues.append(_err(file, p + ".verbo_largo", &"verb", "verbo_largo is only LEER"))
		_check_label(e, "corto", corto, p, file, issues)
		_check_label(e, "largo", largo, p, file, issues)
		if e.has("texto") and String(e["texto"]) != "OBJ_" + id:
			issues.append(_err(file, p + ".texto", &"texto", "texto must be OBJ_%s" % id))
		if effect == &"INSPECCION_TEXTO" and not e.has("texto"):
			issues.append(_err(file, p + ".texto", &"required", "INSPECCION_TEXTO needs texto"))
		if bool(e.get("sostenible", false)) and effect != &"INSPECCION_MANO":
			issues.append(_err(file, p + ".sostenible", &"sostenible", "sostenible only with INSPECCION_MANO"))
		if effect == &"INSPECCION_MANO" and not e.has("inspeccion"):
			issues.append(_err(file, p + ".inspeccion", &"required", "INSPECCION_MANO needs inspeccion"))
		if effect != &"INSPECCION_MANO" and e.has("inspeccion"):
			issues.append(_err(file, p + ".inspeccion", &"inspeccion", "inspeccion only with INSPECCION_MANO"))
		var needs_modo: bool = effect in [&"LEER", &"ABRIR_VISTA", &"ABRIR_ORDENADOR"]
		if needs_modo and not e.has("modo"):
			issues.append(_err(file, p + ".modo", &"required", "%s needs modo" % effect))
		if not needs_modo and e.has("modo"):
			issues.append(_err(file, p + ".modo", &"modo", "%s takes no modo" % effect))
		if needs_modo and e.has("modo"):
			_check_modo(e["modo"] as Dictionary, effect, id, p + ".modo", file, issues)
		if e.has("vista"):
			if effect != &"DELEGAR":
				issues.append(_err(file, p + ".vista", &"vista", "vista block only with DELEGAR"))
			_check_vista(e["vista"] as Dictionary, StringName(id), p + ".vista", file, issues)


	func _check_label(e: Dictionary, suffix: String, verb: StringName, p: String, file: String,
			issues: Array[DataIssue]) -> void:
		var key: String = "etiqueta_" + suffix
		if verb == &"":
			if e.has(key):
				issues.append(_err(file, "%s.%s" % [p, key], &"label", "label without verb"))
		elif not e.has(key):
			issues.append(_err(file, "%s.%s" % [p, key], &"required", "verb needs its label"))
		elif String(e[key]) != "UI_VERBO_" + String(verb):
			issues.append(_err(file, "%s.%s" % [p, key], &"label", "label must be UI_VERBO_%s" % verb))


	func _check_modo(m: Dictionary, effect: StringName, id: String, p: String, file: String,
			issues: Array[DataIssue]) -> void:
		var need: PackedStringArray = PackedStringArray()
		var allowed: PackedStringArray = PackedStringArray()
		if effect == &"LEER":
			need = PackedStringArray(["doc_id", "estilo"])
			allowed = PackedStringArray(["doc_id", "estilo", "lectura_min_s"])
		else:
			need = PackedStringArray(["vista_id", "anclaje", "distancia_m", "fov_vista_deg",
					"t_vista_entrada_s", "cursor_inicial"])
			allowed = need.duplicate()
			allowed.append("centro_m")
		for k: String in need:
			if not m.has(k):
				issues.append(_err(file, p + "." + k, &"required", "%s needs %s" % [effect, k]))
		for k: Variant in m:
			if not (str(k) in allowed):
				issues.append(_err(file, p + "." + str(k), &"unknown_key", "not valid for %s" % effect))
		if m.has("vista_id") and String(m["vista_id"]) != id:
			issues.append(_err(file, p + ".vista_id", &"vista", "vista_id must equal the entry id"))
		if m.has("distancia_m") and float(m["distancia_m"]) <= 0.0:
			issues.append(_err(file, p + ".distancia_m", &"range", "distancia_m must be > 0"))


	func _check_vista(v: Dictionary, id: StringName, p: String, file: String, issues: Array[DataIssue]) -> void:
		if StringName(v["vista_id"]) != id:
			issues.append(_err(file, p + ".vista_id", &"vista", "vista_id must equal the entry id"))
		if id in InteractablesSchema.CHAINED_VIEW_IDS \
				and float(v["t_vista_entrada_s"]) > InteractablesSchema.T_VISTA_CHAINED_MAX_S:
			issues.append(_err(file, p + ".t_vista_entrada_s", &"range",
					"chained view %s: t_vista_entrada_s <= %s" % [id, InteractablesSchema.T_VISTA_CHAINED_MAX_S]))


	static func _verb(e: Dictionary, key: String) -> StringName:
		var v: Variant = e.get(key)
		return StringName(v) if v != null else &""


	static func _err(file: String, path: String, rule: StringName, msg: String) -> DataIssue:
		return DataIssue.new(DataIssue.Severity.ERROR, file, path, rule, msg)


func version() -> int:
	return 1


func root() -> FieldSpec:
	var vista_req: Dictionary = {
		"vista_id": id_(ID_PATTERN),
		"anclaje": id_("^ANC_[A-Z0-9_]+$"),
		"distancia_m": float_(0.001, 10.0),
		"fov_vista_deg": float_(40.0, 90.0),
		"t_vista_entrada_s": float_(T_VISTA_MIN_S, T_VISTA_MAX_S),
		"cursor_inicial": enum_([&"centro"] as Array[StringName]),
	}
	var centro: FieldSpec = array_(float_(-10.0, 10.0), 2)
	centro.max_len = 2
	var pose: FieldSpec = array_(float_(-1.0, 1.0), 4)
	pose.max_len = 4
	var fact_list: FieldSpec = array_(id_("^[a-z][a-z0-9_]*$", &"fact"))
	var modo: FieldSpec = object_({}, {
		"doc_id": id_("^[A-Z][A-Z0-9_]+$"),
		"estilo": id_("^(impreso|pantalla|libro|cristal_espejo|manuscrito_[a-z]+)$"),
		"lectura_min_s": float_(0.0, 5.0),
		"vista_id": vista_req["vista_id"],
		"anclaje": vista_req["anclaje"],
		"distancia_m": vista_req["distancia_m"],
		"centro_m": centro,
		"fov_vista_deg": vista_req["fov_vista_deg"],
		"t_vista_entrada_s": vista_req["t_vista_entrada_s"],
		"cursor_inicial": vista_req["cursor_inicial"],
	})
	var vista: FieldSpec = object_(vista_req, {"centro_m": centro})
	var entry: FieldSpec = object_({
		"id": id_(ID_PATTERN),
		"efecto": enum_(EFFECTS),
	}, {
		"verbo_corto": nullable(enum_(VERBS)),
		"verbo_largo": nullable(enum_(VERBS)),
		"etiqueta_corto": id_("^UI_VERBO_[A-Z]+$"),
		"etiqueta_largo": id_("^UI_VERBO_[A-Z]+$"),
		"habilitado_si": object_({}, {"todos": fact_list, "ninguno": fact_list}),
		"alcance_m": float_(0.1, 5.0),
		"prioridad": int_(0, 9),
		"gesto_hecho": id_("^(HAND|ANIM)_[A-Z_]+$"),
		"texto": id_("^OBJ_[A-Za-z0-9_]+$"),
		"sostenible": bool_(),
		"inspeccion": object_({"pose_inspeccion": pose, "radio_m": float_(0.001, 5.0)}),
		"modo": modo,
		"vista": vista,
	})
	return object_({"interactables": array_(entry, 1, &"id")})


func rules() -> FileRules:
	return CatalogRules.new()
