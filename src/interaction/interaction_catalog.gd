## Read-only catalog of interactables and interaction knobs (GDD 7 rules 2, 31; ADR-0011 D1/D2; ADR-0005).
## Reads `interaction/interactables.json` and `interaction/interaction_config.json` through `DataReader`
## (G-1) and adds the cross-file checks the per-file schemas cannot do (radius vs `r_max_inspeccion_m`).
## Also holds the data-side checks whose inputs live in other owners' files (object texts of 18, box times
## of 10), ready for those stories to call.
## TODO(ADR-0011): the read API below (`load_from`, `has`, `entry`, `ids`, `alcance_m`, `config_*`) is an
## ADR-fallback of IP-001: neither ADR-0011 "Key Interfaces" nor ADR-0005 fix it. Register it as an
## amendment of ADR-0011 (it only exposes what the schema defines).
## TODO(box.json, system 10 story): call `check_box_open` with the real `BOX_Cn_OPEN` values.
## TODO(narrative/objects.json, CD-004): call `check_object_texts` with the real `OBJ_*` texts.
## Example: `var cat := InteractionCatalog.load_from(reader); if cat.has_errors(): ...; cat.entry(&"V02")`.
class_name InteractionCatalog extends RefCounted

const INTERACTABLES_PATH: String = "interaction/interactables.json"
const CONFIG_PATH: String = "interaction/interaction_config.json"
## Range of the consumed `BOX_OPEN_MAX` (GDD 7 Tuning Knobs).
const BOX_OPEN_MAX_MIN_S: float = 1.2
const BOX_OPEN_MAX_MAX_S: float = 1.6

## Every issue found loading both files (reader, schema rules and cross-file checks).
var issues: Array[DataIssue] = []
var _rows: Dictionary[StringName, Dictionary] = {}
var _ids: Array[StringName] = []
var _config: Dictionary = {}


## Reads both files and validates them. Never throws: inspect `has_errors()`; with errors the catalog is
## empty (no partial data is exposed).
static func load_from(reader: DataReader) -> InteractionCatalog:
	var cat: InteractionCatalog = InteractionCatalog.new()
	var items: DataResult = reader.read_file(DataCatalog.Entry.new(INTERACTABLES_PATH, InteractablesSchema.new()))
	var cfg: DataResult = reader.read_file(DataCatalog.Entry.new(CONFIG_PATH, InteractionConfigSchema.new()))
	cat.issues.append_array(items.issues)
	cat.issues.append_array(cfg.issues)
	if items.has_errors() or cfg.has_errors():
		return cat
	var root: Dictionary = items.value
	var config: Dictionary = cfg.value
	cat.issues.append_array(cross_check(root, config, INTERACTABLES_PATH))
	if cat.has_errors():
		return cat
	cat._config = config
	var rows: Array = root["interactables"]
	for e: Dictionary in rows:
		var id: StringName = e["id"]
		cat._rows[id] = e
		cat._ids.append(id)
	cat._ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return cat


## Checks that need both files: an `INSPECCION_MANO` radius above `r_max_inspeccion_m` is an error;
## an entry `alcance_m` is also capped by nothing else (it replaces the global one).
static func cross_check(items_root: Dictionary, config: Dictionary, file: String) -> Array[DataIssue]:
	var out: Array[DataIssue] = []
	var r_max: float = config["r_max_inspeccion_m"]
	var rows: Array = items_root["interactables"]
	for i: int in rows.size():
		var e: Dictionary = rows[i]
		if e.has("inspeccion") and float((e["inspeccion"] as Dictionary)["radio_m"]) > r_max:
			out.append(DataIssue.new(DataIssue.Severity.ERROR, file,
					"interactables[%d].inspeccion.radio_m" % i, &"range",
					"radio_m %s exceeds r_max_inspeccion_m %s" % [(e["inspeccion"] as Dictionary)["radio_m"], r_max]))
	return out


## AC-15 (data part): every object text must fit in `max_chars` characters (`texto_max_caracteres`).
## `texts` maps `OBJ_*` key -> text. Longer ones are errors (a text over the limit is a document).
static func check_object_texts(texts: Dictionary, max_chars: int, file: String) -> Array[DataIssue]:
	var out: Array[DataIssue] = []
	for key: Variant in texts:
		var n: int = String(texts[key]).length()
		if n > max_chars:
			out.append(DataIssue.new(DataIssue.Severity.ERROR, file, str(key), &"text_length",
					"%d characters exceed texto_max_caracteres %d" % [n, max_chars]))
	return out


## AC-26b (data part): `box_open_max_s` must be within [1,2; 1,6] and every `BOX_Cn_OPEN` <= it.
## `box_open` maps name -> seconds.
static func check_box_open(box_open: Dictionary, box_open_max_s: float, file: String) -> Array[DataIssue]:
	var out: Array[DataIssue] = []
	if box_open_max_s < BOX_OPEN_MAX_MIN_S or box_open_max_s > BOX_OPEN_MAX_MAX_S:
		out.append(DataIssue.new(DataIssue.Severity.ERROR, file, "BOX_OPEN_MAX", &"range",
				"BOX_OPEN_MAX %s outside [%s, %s]" % [box_open_max_s, BOX_OPEN_MAX_MIN_S, BOX_OPEN_MAX_MAX_S]))
	for key: Variant in box_open:
		if float(box_open[key]) > box_open_max_s:
			out.append(DataIssue.new(DataIssue.Severity.ERROR, file, str(key), &"range",
					"%s %s exceeds BOX_OPEN_MAX %s" % [key, box_open[key], box_open_max_s]))
	return out


## True when loading found at least one ERROR.
func has_errors() -> bool:
	for i: DataIssue in issues:
		if i.severity == DataIssue.Severity.ERROR:
			return true
	return false


## True when `id` is in the catalog.
func has(id: StringName) -> bool:
	return _rows.has(id)


## The normalised row of `id` (do not mutate), or an empty Dictionary when absent.
func entry(id: StringName) -> Dictionary:
	return _rows.get(id, {})


## Every catalog ID, sorted by name (deterministic).
func ids() -> Array[StringName]:
	return _ids


## Reach of `id`: its own `alcance_m` or the global `alcance_interaccion_m`; 0.0 when absent.
func alcance_m(id: StringName) -> float:
	if not _rows.has(id):
		return 0.0
	var e: Dictionary = _rows[id]
	return float(e.get("alcance_m", _config["alcance_interaccion_m"]))


## A knob of `interaction_config.json` as float (0.0 if unknown key).
func config_float(key: StringName) -> float:
	return float(_config.get(String(key), 0.0))


## A knob of `interaction_config.json` as int (0 if unknown key).
func config_int(key: StringName) -> int:
	return int(_config.get(String(key), 0))
