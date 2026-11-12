## Facts and notice bus (system 3). Registered as autoload `GameStateAutoload` (ADR-0009 D1).
## EB-005 scope: catalog loading (`load_catalog`), status and the notice channel built with the
## `max_chained_notices` read from `flags.json`. Reads (EB-007); writes/snapshot arrive in later stories.
## Example: `state.setup(ctx); if state.load_catalog("state/flags.json") == OK: state.get_fact(&"caja_c1")`.
class_name GameState extends Node

## Lifecycle (GDD 3 § States): UNLOADED until the catalog loads, READY after, RESTORING reserved
## (restore is deferred by ADR-0004).
enum Status { UNLOADED, READY, RESTORING }

## The only bool that may go back to false (GDD 3 rule 6); `pos_L/C/R` are reversible as `int`.
const REVERSIBLE_BOOL: StringName = &"pendiente_revelacion"

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
var _owners: Dictionary = {}      # StringName -> int owner system number
var _ranges: Dictionary = {}      # StringName -> [min, max] (int facts with a range)
var _enum_values: Dictionary = {} # StringName -> Array[StringName]
var _derived: Dictionary = {}     # StringName -> true (written only by the state, EB-010)
var _derive_inputs: Dictionary = {} # derived StringName -> Array of input names (conjunction)
var _dependents: Dictionary = {}    # input StringName -> Array[StringName] derived facts (reverse index)


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


## Composition only (Boot): a writer bound to `owner_id`. Systems never call this themselves.
func writer_for(owner_id: int) -> FactWriter:
	return FactWriter.new(self, owner_id)


## Validated write (GDD 3 rules 2-4, ADR-0001 § Drain and Write Algorithms). Production code goes
## through `FactWriter.write`. Returns true when accepted (changed or identical). A valid change is
## applied at once, even while draining; only the notice is queued. Invalid writes keep the value,
## log exactly one line and call `ErrorPolicy.fail`. The owner is checked in dev builds only.
## Derived facts (EB-010) are recomputed after each accepted change; their notice follows the input's.
func set_fact(fact: StringName, value: Variant, owner_id: int) -> bool:
	if _status != Status.READY:
		return _write_failed("fact '%s': state is %s, write discarded" % [fact, Status.keys()[_status]])
	var slot: int = _index.get(fact, -1)
	if slot < 0:
		return _write_failed("fact '%s' is not declared" % fact)
	if _derived.has(fact):
		return _write_failed("fact '%s' is derived and cannot be written" % fact)
	var type_error: String = _check_value(fact, value)
	if type_error != "":
		return _write_failed(type_error)
	if _errors.is_strict() and int(_owners[fact]) != owner_id:
		return _write_failed("fact '%s' is owned by %d, written by %d" % [fact, _owners[fact], owner_id])
	var old: Variant = _slots[slot]
	if old == value:
		return true
	if _is_one_way(fact) and _is_set(fact, old):
		return _write_failed("fact '%s' is one-way: %s cannot go back to %s" % [fact, old, value])
	_slots[slot] = value
	_channel.push_change(fact, old, value)
	_recompute_dependents(fact)
	return true


## New game (GDD 3 rule 12, ADR-0001 G-4): every fact returns to its catalog initial, the pending
## queue is emptied and ONE `state_reset` is emitted, with no per-fact change notices. Inside a drain
## it is deferred to the end of that drain (rule 11). Consumers re-read the facts on `state_reset`.
## No-op while UNLOADED. Example: `state.reset_new_game()`.
func reset_new_game() -> void:
	if _status != Status.READY:
		return
	_channel.run_after_drain(_apply_reset)


func _apply_reset() -> void:
	for i: int in _names.size():
		_slots[i] = _initials[_names[i]]
	_channel.clear_pending()
	_channel.notify(NoticeIds.STATE_RESET)


## Re-evaluates every derived fact that lists `input` (reverse index built at load). A derived value
## that changes is stored and its notice queued after the input's (FIFO, CA-14); derived facts that
## feed other derived facts cascade. Generic: the rule comes from the catalog `derive` (conjunction).
func _recompute_dependents(input: StringName) -> void:
	var deps: Array = _dependents.get(input, [])
	for d: Variant in deps:
		var derived: StringName = d
		var all_true: bool = true
		for n: Variant in _derive_inputs[derived]:
			if _slots[_index[n as StringName]] != true:
				all_true = false
				break
		var slot: int = _index[derived]
		var old: Variant = _slots[slot]
		if old == all_true:
			continue
		_slots[slot] = all_true
		_channel.push_change(derived, old, all_true)
		_recompute_dependents(derived)


## The channel built from the catalog (null while UNLOADED). TODO(ADR-0001): the subscription
## wrappers (EB-008) will hide it; exposed meanwhile so tests can observe the chain cap.
func get_channel() -> NoticeChannel:
	return _channel


## Exact-type check (no implicit conversion) plus range / enum set. "" = valid.
func _check_value(fact: StringName, value: Variant) -> String:
	var want: StringName = _types[fact]
	var got: int = typeof(value)
	match want:
		&"bool":
			if got != TYPE_BOOL:
				return "fact '%s' expects bool, got type %d" % [fact, got]
		&"int":
			if got != TYPE_INT:
				return "fact '%s' expects int, got type %d" % [fact, got]
			if _ranges.has(fact):
				var r: Array = _ranges[fact]
				if (value as int) < (r[0] as int) or (value as int) > (r[1] as int):
					return "fact '%s': %d is outside range [%d, %d]" % [fact, value, r[0], r[1]]
		_:
			if got != TYPE_STRING_NAME:
				return "fact '%s' expects StringName enum, got type %d" % [fact, got]
			if not (_enum_values[fact] as Array).has(value):
				return "fact '%s': '%s' is not an allowed value" % [fact, value]
	return ""


## One-way rule (GDD 3 rule 6). TODO(ADR-0005 D2): the schema has no `reversible` field, so it is
## derived (ADR-fallback): `int` facts and `REVERSIBLE_BOOL` are reversible; other bool/enum are one-way.
func _is_one_way(fact: StringName) -> bool:
	return _types[fact] != &"int" and fact != REVERSIBLE_BOOL


## True once a one-way fact left its initial state: bool `true`, enum any fixed value (not `&""`).
func _is_set(fact: StringName, value: Variant) -> bool:
	if _types[fact] == &"bool":
		return value == true
	return value != &""


## Rejected write: one log line, ErrorPolicy.fail (dev halts), value untouched.
func _write_failed(msg: String) -> bool:
	var line: String = "state write: %s" % msg
	_ctx.logger.line(LogSink.LEVEL_ERROR, line)
	_errors.fail(line)
	return false


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
	_owners.clear()
	_ranges.clear()
	_enum_values.clear()
	_derived.clear()
	_derive_inputs.clear()
	_dependents.clear()
	for f: Variant in root["facts"]:
		var d: Dictionary = f
		var fact: StringName = d["name"]
		var type: StringName = d["type"]
		var initial: Variant = d["initial"]
		if type == &"enum":
			initial = StringName(initial) if initial != null else &""
		_owners[fact] = int(d["owner"])
		if d.has("range"):
			var rg: Array = d["range"]
			_ranges[fact] = [int(rg[0]), int(rg[1])]
		if type == &"enum":
			var allowed: Array[StringName] = []
			for v: Variant in d["values"]:
				allowed.append(StringName(v))
			_enum_values[fact] = allowed
		if d.has("derive"):
			_derived[fact] = true
			var ins: Array[StringName] = []
			for n: Variant in d["derive"]:
				var input: StringName = StringName(n)
				ins.append(input)
				if not _dependents.has(input):
					_dependents[input] = []
				(_dependents[input] as Array).append(fact)
			_derive_inputs[fact] = ins
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
