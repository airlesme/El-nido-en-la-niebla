## Facts and notice bus (system 3). Registered as autoload `GameStateAutoload` (ADR-0009 D1).
## EB-005 scope: catalog loading (`load_catalog`), status and the notice channel built with the
## `max_chained_notices` read from `flags.json`. Reads (EB-007); writes/snapshot arrive in later stories.
## Example: `state.setup(ctx); if state.load_catalog("state/flags.json") == OK: state.get_fact(&"caja_c1")`.
class_name GameState extends Node

## Lifecycle (GDD 3 § States): UNLOADED until the catalog loads, READY after, RESTORING reserved
## (restore is deferred by ADR-0004).
enum Status { UNLOADED, READY, RESTORING }

var _ctx: ServiceContext
var _status: Status = Status.UNLOADED
var _channel: NoticeChannel
var _max_chained: int = 0
var _names: Array[StringName] = []
var _types: Dictionary = {}    # StringName -> StringName (&"bool" | &"int" | &"enum")
var _initials: Dictionary = {} # StringName -> bool | int | StringName
var _index: Dictionary = {}    # StringName -> int slot (resolved once, ADR-0001 G-3)
var _slots: Array = []         # current values by slot (bool | int | StringName)
var _errors: ErrorPolicy


func _init() -> void:
	# ADR-0009 D2: explicit, never inherited. No I/O, no autoload reads here (F-R26).
	process_mode = Node.PROCESS_MODE_ALWAYS


## Composition point, called once by Boot (ADR-0009 D2/D3). Never called by systems.
## Keeps the context; performs no I/O (the catalog is loaded by `load_catalog`, story 014 wires it).
func setup(ctx: ServiceContext) -> void:
	_ctx = ctx
	_errors = ErrorPolicyDefault.new(ctx.flavor)


## Replaces the ErrorPolicy (ADR-0001: injected seam). Tests pass a recording double so a dev-build
## failure does not quit the tree. Call after `setup` and before `load_catalog`.
func set_error_policy(policy: ErrorPolicy) -> void:
	_errors = policy


## Loads and validates the fact catalog (ADR-0001 Key Interfaces, ADR-0005 D3 tier L). `path` is
## relative to `assets/data/` and must be a registered `DataCatalog` row, e.g. "state/flags.json".
## Any error is raised through `ctx.fatal` as CATALOGO_INVALIDO with the offending `param`; the
## state stays UNLOADED and the call returns ERR_INVALID_DATA. Example: `load_catalog("state/flags.json")`.
func load_catalog(path: String) -> Error:
	var entry: DataCatalog.Entry = _find_entry(path)
	if entry == null:
		return _fail(path, "path", &"unregistered", "not a registered catalog file")
	var files: FileStore = _ctx.files if _ctx.files != null else FileStore.new()
	var result: DataResult = DataReader.new(files, _ctx.flavor).read_file(entry)
	for issue: DataIssue in result.issues:
		var level: StringName = LogSink.LEVEL_ERROR \
				if issue.severity == DataIssue.Severity.ERROR else LogSink.LEVEL_WARN
		_ctx.logger.line(level, issue.format())
	var bad: DataIssue = result.first_error()
	if bad != null:
		return _fail(path, bad.json_path, bad.rule, bad.message)
	if result.value == null:
		return _fail(path, "$", &"parse", "file could not be read")
	_commit(result.value as Dictionary)
	return OK


## Current lifecycle status.
func get_status() -> Status:
	return _status


## Number of declared facts (0 while UNLOADED).
func fact_count() -> int:
	return _names.size()


## True when `fact` is declared in the loaded catalog (case-sensitive: `Tarjeta_B` is not `tarjeta_B`).
func is_declared(fact: StringName) -> bool:
	return _index.has(fact)


## Current value of `fact` (bool, int, or StringName for enums; `&""` = "sin fijar").
## Undeclared fact or UNLOADED (CA-27): dev -> `ErrorPolicy.fail`; release (and after a non-halting
## fail) -> neutral `false` plus one log line. Example: `state.get_fact(&"caja_c1")`.
func get_fact(fact: StringName) -> Variant:
	var slot: int = _index.get(fact, -1)
	if slot < 0:
		return _read_failed("fact '%s' is not declared" % fact)
	return _slots[slot]


## Slot of `fact`, or -1 when undeclared (also while UNLOADED). Call once at `configurar()` and
## cache the result; stable until the next `load_catalog`. Example: `_slot = state.resolve_fact(&"memo_leido")`.
func resolve_fact(fact: StringName) -> int:
	return _index.get(fact, -1)


## Hot-path read by slot from `resolve_fact`: one bounds check and one Array index, no allocation.
## An out-of-range index is treated as an undeclared fact (CA-27). Example: `state.get_fact_at(_slot)`.
func get_fact_at(index: int) -> Variant:
	if index < 0 or index >= _slots.size():
		return _read_failed("fact index %d is out of range" % index)
	return _slots[index]


## The channel built from the catalog (null while UNLOADED). TODO(ADR-0001): the subscription
## wrappers (EB-008) will hide it; exposed meanwhile so tests can observe the chain cap.
func get_channel() -> NoticeChannel:
	return _channel


func _find_entry(path: String) -> DataCatalog.Entry:
	for e: DataCatalog.Entry in DataCatalog.entries():
		if e.rel_path == path:
			return e
	return null


func _commit(root: Dictionary) -> void:
	_max_chained = root["max_chained_notices"]
	_names.clear()
	_types.clear()
	_initials.clear()
	_index.clear()
	_slots.clear()
	for f: Variant in root["facts"]:
		var d: Dictionary = f
		var fact: StringName = d["name"]
		var type: StringName = d["type"]
		var initial: Variant = d["initial"]
		if type == &"enum":
			initial = StringName(initial) if initial != null else &""
		_names.append(fact)
		_types[fact] = type
		_initials[fact] = initial
		_index[fact] = _slots.size()
		_slots.append(initial)
	_channel = NoticeChannel.new(_max_chained, _ctx.logger, _errors, NoticeIds.SCHEMA)
	_status = Status.READY


func _fail(file: String, param: String, rule: StringName, message: String) -> Error:
	_status = Status.UNLOADED
	_ctx.fatal.raise_fatal(FatalErrorHandler.CATALOGO_INVALIDO,
			{&"file": file, &"param": param, &"rule": rule, &"message": message})
	return ERR_INVALID_DATA


## CA-27 read failure: log one line, ask the ErrorPolicy to stop (dev), return the neutral `false`
## (an undeclared name has no type).
func _read_failed(why: String) -> Variant:
	var msg: String = "state read: %s%s" % [why, " (state UNLOADED)" if _status == Status.UNLOADED else ""]
	_ctx.logger.line(LogSink.LEVEL_ERROR, msg)
	_errors.fail(msg)
	return false
