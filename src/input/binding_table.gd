## Binding table of the input layer (ADR-0006 D1, D11; GDD 1 rules 1, 4, 19): the default assignments
## and tuning values read from `assets/data/input/default_bindings.json` through `DataReader`.
## It is a layer beside the Input Map: nothing here touches `Input` or `InputMap`.
## A missing or invalid file raises `ctx.fatal` (CATALOGO_INVALIDO) with the offending `param`.
## Override layer (`controles` block, ADR-0007) is out of scope: TODO(ADR-0007).
## Example: `var t := BindingTable.new(); if t.load_defaults(ctx) == OK: t.get_bindings(&"pausa", InputTypes.Device.GAMEPAD)`.
class_name BindingTable extends RefCounted

## Path of the data file relative to `assets/data/` (ADR-0005 D1 row).
const PATH: String = "input/default_bindings.json"

var _loaded: bool = false
## StringName action -> {Device: Array[InputTypes.InputBinding]}
var _actions: Dictionary = {}
var _action_names: Array[StringName] = []
var _tuning: Dictionary = {}  # String key -> {value, min, max} floats
var _toggles: Dictionary = {} # String key -> bool


## Loads and validates the file (tier L). Returns OK, or ERR_INVALID_DATA after raising the fatal
## through `ctx.fatal`; the table then stays empty. Calling again replaces the contents.
## Example: `var err: Error = table.load_defaults(ctx)`.
func load_defaults(ctx: ServiceContext) -> Error:
	_clear()
	var entry: DataCatalog.Entry = _find_entry()
	if entry == null:
		return _fail(ctx, "path", &"unregistered", "input/default_bindings.json is not a catalog row")
	var files: FileStore = ctx.files if ctx.files != null else FileStore.new()
	var result: DataResult = DataReader.new(files, ctx.flavor).read_file(entry)
	for issue: DataIssue in result.issues:
		var level: StringName = LogSink.LEVEL_ERROR \
				if issue.severity == DataIssue.Severity.ERROR else LogSink.LEVEL_WARN
		ctx.logger.line(level, issue.format())
	var bad: DataIssue = result.first_error()
	if bad != null:
		return _fail(ctx, bad.json_path, bad.rule, bad.message)
	if result.value == null:
		return _fail(ctx, "$", &"parse", "file could not be read")
	_commit(result.value as Dictionary)
	return OK


## True once `load_defaults` succeeded.
func is_loaded() -> bool:
	return _loaded


## Names of the physical actions in file order (empty before loading).
func action_names() -> Array[StringName]:
	return _action_names.duplicate()


## True when `action` is a physical action of the table. Derived gestures are not.
func has_action(action: StringName) -> bool:
	return _actions.has(action)


## Bindings of `action` for `device` (KEYBOARD_MOUSE or GAMEPAD), in file order. Unknown action or
## `Device.ACTIVE` returns an empty array (resolving ACTIVE belongs to the router).
## Example: `table.get_bindings(&"interactuar", InputTypes.Device.KEYBOARD_MOUSE)`.
func get_bindings(action: StringName, device: InputTypes.Device) -> Array[InputTypes.InputBinding]:
	var out: Array[InputTypes.InputBinding] = []
	var per_device: Dictionary = _actions.get(action, {})
	var list: Array = per_device.get(device, [])
	for b: InputTypes.InputBinding in list:
		out.append(b)
	return out


## Actions that have a binding matching `raw` (kind and code; for PAD_AXIS also the sign of
## `raw.value` when the binding is an axis half). The device is implied by the kind.
## Example: `table.actions_for(raw)` for a `W` key press returns `[&"mover"]`.
func actions_for(raw: InputTypes.RawInput) -> Array[StringName]:
	var out: Array[StringName] = []
	for action: StringName in _action_names:
		var per_device: Dictionary = _actions[action]
		for device: int in per_device:
			if _matches_any(per_device[device] as Array, raw):
				out.append(action)
				break
	return out


## Default value of a tuning key (`TUNING_KEYS` of the schema); an unknown key returns NAN.
func tuning_value(key: StringName) -> float:
	var t: Dictionary = _tuning.get(String(key), {})
	return t.get("value", NAN)


## Safe range (x = min, y = max) of a tuning key; an unknown key returns (NAN, NAN).
func tuning_range(key: StringName) -> Vector2:
	var t: Dictionary = _tuning.get(String(key), {})
	return Vector2(t.get("min", NAN), t.get("max", NAN))


## Initial value of a boolean setting; unknown key returns false.
func toggle_default(key: StringName) -> bool:
	return _toggles.get(String(key), false)


func _find_entry() -> DataCatalog.Entry:
	for e: DataCatalog.Entry in DataCatalog.entries():
		if e.rel_path == PATH:
			return e
	return null


func _clear() -> void:
	_loaded = false
	_actions.clear()
	_action_names.clear()
	_tuning.clear()
	_toggles.clear()


func _commit(root: Dictionary) -> void:
	for a: Variant in root["actions"]:
		var d: Dictionary = a
		var name: StringName = d["name"]
		_action_names.append(name)
		_actions[name] = {
			InputTypes.Device.KEYBOARD_MOUSE: _build(d["keyboard_mouse"] as Array),
			InputTypes.Device.GAMEPAD: _build(d["gamepad"] as Array),
		}
	var tuning: Dictionary = root["tuning"]
	for k: Variant in tuning:
		var t: Dictionary = tuning[k]
		_tuning[str(k)] = {"value": float(t["value"]), "min": float(t["min"]), "max": float(t["max"])}
	var toggles: Dictionary = root["toggles"]
	for k: Variant in toggles:
		_toggles[str(k)] = bool(toggles[k])
	_loaded = true


func _build(rows: Array) -> Array[InputTypes.InputBinding]:
	var out: Array[InputTypes.InputBinding] = []
	for r: Variant in rows:
		var d: Dictionary = r
		var b: InputTypes.InputBinding = InputTypes.InputBinding.new()
		b.kind = InputTypes.RawKind[str(d["kind"])]
		b.code = d["code"]
		b.axis_dir = d.get("axis_dir", 0)
		out.append(b)
	return out


func _matches_any(list: Array, raw: InputTypes.RawInput) -> bool:
	for b: InputTypes.InputBinding in list:
		if b.kind != raw.kind or b.code != raw.code:
			continue
		if b.kind == InputTypes.RawKind.PAD_AXIS and b.axis_dir != 0 \
				and int(signf(raw.value)) != b.axis_dir:
			continue
		return true
	return false


func _fail(ctx: ServiceContext, param: String, rule: StringName, message: String) -> Error:
	_clear()
	ctx.fatal.raise_fatal(FatalErrorHandler.CATALOGO_INVALIDO,
			{&"file": PATH, &"param": param, &"rule": rule, &"message": message})
	return ERR_INVALID_DATA
