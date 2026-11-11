## Registry of loadable data files (ADR-0005 D1): the only list of files the game may load.
## Mirror of the D1 table; one row per file, in the fixed order of ADR-0005 D2.3 (state, narrative,
## input, puzzles), which tiers B/C and ContentDB follow.
## F-R50: a row is added here, with its schema, before the file exists. This story registers the M1
## rows; a row whose schema class does not exist yet is listed in `registry()` but left out of
## `entries()` until its owner story supplies the schema (see `_schema_for`).
## Example: `for e: DataCatalog.Entry in DataCatalog.entries(): reader.read_file(e)`.
class_name DataCatalog extends RefCounted

## When the owner loads the file (ADR-0005 D3 tier L).
enum LoadPoint { BOOT, SCENE }
## What the release build does when the file fails tier L (ADR-0005 D1 table).
enum ReleasePolicy { FATAL, SCENE_LOAD_FAILURE, DROP_RECORD, CLAMP_WARN }

## Folder and file names: one folder level, snake_case ASCII (ADR-0005 D1.1, D1.2).
const PATH_PATTERN: String = "^[a-z0-9_]+/[a-z0-9_]+\\.json$"

static var _path_regex: RegEx = null


## One registered file: its path relative to assets/data/, owner and schema.
class Entry extends RefCounted:
	## Path relative to assets/data/, e.g. "puzzles/puzzles.json".
	var rel_path: String
	## The single schema of this file (same object for tiers L, B and C). Null while pending.
	var schema: DataSchema
	## GDD system number that owns the folder/file (ADR-0005 D1 table).
	var owner: int = 0
	## When the owner loads it.
	var load_point: LoadPoint = LoadPoint.BOOT
	## Release behaviour on failure.
	var policy: ReleasePolicy = ReleasePolicy.FATAL
	## Fatal code raised on failure: CATALOGO_INVALIDO | DATOS_ESCENA_INVALIDOS | CONTENIDO_INVALIDO.
	var fatal_code: StringName = FatalErrorHandler.CATALOGO_INVALIDO


	func _init(p_rel_path: String, p_schema: DataSchema) -> void:
		rel_path = p_rel_path
		schema = p_schema


## True when `rel_path` follows the D1 convention: `<domain>/<file>.json`, exactly one folder,
## `[a-z0-9_]+` each, nothing at the root of assets/data/.
## Example: `is_valid_path("puzzles/puzzles.json")` is true; `"flags.json"`, `"state/my-flags.json"`
## and `"a/b/c.json"` are false.
static func is_valid_path(rel_path: String) -> bool:
	if _path_regex == null:
		_path_regex = RegEx.create_from_string(PATH_PATTERN)
	var m: RegExMatch = _path_regex.search(rel_path)
	return m != null and m.get_start() == 0 and m.get_end() == rel_path.length()


## Every registered row in D2.3 order, including rows whose schema is still pending (schema == null).
## Rows are built from scratch on each call, so callers may keep or mutate them.
static func registry() -> Array[Entry]:
	var rows: Array[Entry] = []
	rows.append(_row("state/flags.json", 3, LoadPoint.BOOT, ReleasePolicy.FATAL, FatalErrorHandler.CATALOGO_INVALIDO))
	for f: String in ["lines", "nonverbal", "documents", "mails", "tasks", "hints", "ui", "objects", "names", "groups"]:
		rows.append(_row("narrative/%s.json" % f, 18, LoadPoint.BOOT, ReleasePolicy.FATAL,
				FatalErrorHandler.CONTENIDO_INVALIDO))
	rows.append(_row("input/default_bindings.json", 1, LoadPoint.BOOT, ReleasePolicy.FATAL,
			FatalErrorHandler.CATALOGO_INVALIDO))
	rows.append(_row("player/player.json", 2, LoadPoint.BOOT, ReleasePolicy.FATAL,
			FatalErrorHandler.CATALOGO_INVALIDO))
	rows.append(_row("interaction/interactables.json", 7,LoadPoint.SCENE, ReleasePolicy.SCENE_LOAD_FAILURE,
			FatalErrorHandler.DATOS_ESCENA_INVALIDOS))
	rows.append(_row("interaction/interaction_config.json", 7, LoadPoint.SCENE, ReleasePolicy.SCENE_LOAD_FAILURE,
			FatalErrorHandler.DATOS_ESCENA_INVALIDOS))
	rows.append(_row("puzzles/puzzles.json", 9, LoadPoint.SCENE, ReleasePolicy.SCENE_LOAD_FAILURE,
			FatalErrorHandler.DATOS_ESCENA_INVALIDOS))
	return rows


## The entries that can be read today: registered rows that already have a schema, in D2.3 order.
## This is the single list tier B (DataValidator), tier C and the owners iterate.
static func entries() -> Array[Entry]:
	var out: Array[Entry] = []
	for e: Entry in registry():
		if e.schema != null:
			out.append(e)
	return out


static func _row(path: String, owner: int, load_point: LoadPoint, policy: ReleasePolicy,
		code: StringName) -> Entry:
	assert(is_valid_path(path), "DataCatalog row outside the D1 convention: %s" % path)
	var e: Entry = Entry.new(path, _schema_for(path))
	e.owner = owner
	e.load_point = load_point
	e.policy = policy
	e.fatal_code = code
	return e


## Schema of each row. Every M1 schema belongs to its owner story (ADR-0005 D2.1, F-R50), so each
## branch is filled when that story lands. Until then the row stays registered but is not swept.
static func _schema_for(path: String) -> DataSchema:
	# TODO(CD-004): narrative/* schemas (src/narrative/data/*_schema.gd) from the ContentDB story.
	# TODO(ADR-0010): puzzles/puzzles.json schema (PuzzlesSchema) from the puzzles story.
	match path:
		"state/flags.json":
			return FlagsSchema.new() # EB-005 (src/core/state/data/)
		"input/default_bindings.json":
			return DefaultBindingsSchema.new() # EC-001 (src/input/data/)
		"player/player.json":
			return PlayerSchema.new() # PJ-001 (src/player/data/)
		"interaction/interactables.json":
			return InteractablesSchema.new() # IP-001 (src/interaction/data/)
		"interaction/interaction_config.json":
			return InteractionConfigSchema.new() # IP-001 (ADR-fallback row, see schema note)
		_:
			return null
