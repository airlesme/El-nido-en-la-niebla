## Typed, validated view of `assets/data/scene/load_transitions.json` (ADR-0003 § Key Interfaces «LoadTransitions»,
## TR-scene-015, TR-scene-022). Fade durations per `motivo` plus `T_cap`, `N_gap`, `Δ_max`, `Δ_ref` and the full
## unload bound; nothing of this lives in code. `reducir_movimiento` is NOT read here (Settings, ADR-0007): the
## fixed fade it imposes is exposed as `reduced_motion_s` for the caller to apply (story 003).
## Any failure while loading is fatal `DATOS_ESCENA_INVALIDOS` with the parameter name in `detail[&"param"]`
## and no config is created (`load_from` returns null), so the game does not enter a match.
## TODO(ADR-0003): the signature is not fixed there; this story fixes `load_from(reader, fatal)` and
## `from_dict(d)` (what `SceneLoader.validate` will call at Boot step g) and records it as an amendment
## to § Key Interfaces (ADR-fallback; owner: lead-programmer).
## Example: `var lt := LoadTransitions.load_from(reader, ctx.fatal); if lt == null: return`.
class_name LoadTransitions extends RefCounted

## File of the registry row (ADR-0005 D1), relative to assets/data/.
const PATH: String = "scene/load_transitions.json"
## GDD system number that owns the file.
const OWNER: int = 4
## `motivo` values present in the table.
const MOTIVO_PARTIDA_NUEVA: StringName = &"partida_nueva"
const MOTIVO_REANUDAR: StringName = &"reanudar"
const MOTIVO_RECEPCION: StringName = &"recepcion"
const MOTIVO_CIERRE: StringName = &"cierre"

## Total wait in black before a load fails, seconds (GDD `T_cap`).
var t_cap_s: float = 0.0
## Grace frames between «escena lista» and the start of the fade in.
var n_gap: int = 0
## Per-frame clamp of fade time, seconds (GDD `Δ_max`).
var delta_max_s: float = 0.0
## Reference frame duration used only to size `D_carga`, seconds (GDD `Δ_ref`).
var delta_ref_s: float = 0.0
## Declared duration of the full unload, seconds.
var t_descarga_total_max_s: float = 0.0
## d_out = d_in imposed by `reducir_movimiento`, seconds (GDD rule 11).
var reduced_motion_s: float = 0.0

# motivo -> seconds (64-bit floats; a Vector2 would round to 32-bit). `cierre` never lifts, so its d_in is 0.
var _d_out: Dictionary[StringName, float] = {}
var _d_in: Dictionary[StringName, float] = {}


## Reads and validates `scene/load_transitions.json`. On any problem (missing, corrupt, out of range) raises
## `DATOS_ESCENA_INVALIDOS` on `fatal` with `{param, value, owner, file, rule, message}` and returns null.
## Example: `LoadTransitions.load_from(DataReader.new(FileStore.new(), BuildFlavor.new(false)), fatal)`.
static func load_from(reader: DataReader, fatal: FatalErrorHandler) -> LoadTransitions:
	var res: DataResult = reader.read_file(DataCatalog.Entry.new(PATH, LoadTransitionsSchema.new()))
	var bad: DataIssue = res.first_error()
	if bad != null:
		fatal.raise_fatal(FatalErrorHandler.DATOS_ESCENA_INVALIDOS, {
			&"param": bad.json_path, &"value": null, &"owner": OWNER, &"file": bad.file,
			&"rule": bad.rule, &"message": bad.message,
		})
		return null
	return from_dict(res.value)


## Builds the config from a tree already normalised by `LoadTransitionsSchema` (no validation here).
## Example: `LoadTransitions.from_dict(result.value)`.
static func from_dict(d: Dictionary) -> LoadTransitions:
	var c: LoadTransitions = LoadTransitions.new()
	c.t_cap_s = float(d["t_cap_s"])
	c.n_gap = int(d["n_gap"])
	c.delta_max_s = float(d["delta_max_s"])
	c.delta_ref_s = float(d["delta_ref_s"])
	c.t_descarga_total_max_s = float(d["t_descarga_total_max_s"])
	c.reduced_motion_s = float(d["reducir_movimiento_s"])
	var table: Dictionary = d["motivos"]
	for key: Variant in table:
		var row: Dictionary = table[key]
		c._d_out[StringName(str(key))] = float(row["d_out"])
		c._d_in[StringName(str(key))] = float(row.get("d_in", 0.0))
	return c


## True when `motivo` has a row.
func has_motivo(motivo: StringName) -> bool:
	return _d_out.has(motivo)


## Darken duration of `motivo` in seconds, without `reducir_movimiento`. Unknown `motivo`: 0.0 and an error log.
func d_out_s(motivo: StringName) -> float:
	if not _d_out.has(motivo):
		push_error("LoadTransitions: unknown motivo '%s'" % motivo)
		return 0.0
	return _d_out[motivo]


## Lighten duration of `motivo` in seconds (0.0 for `cierre`, which never lifts). Unknown `motivo`: 0.0 and an error log.
func d_in_s(motivo: StringName) -> float:
	if not _d_out.has(motivo):
		push_error("LoadTransitions: unknown motivo '%s'" % motivo)
		return 0.0
	return _d_in[motivo]
