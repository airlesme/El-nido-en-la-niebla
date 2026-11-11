## Reads one registered file and normalises it against its schema (ADR-0005 D4, D5; F-R49).
## The single entry point for game data: no other code touches FileAccess/JSON for it.
## Never throws: every problem is a DataIssue in the result; the caller applies the release policy.
## Output is a tree of Dictionary / typed Array (StringName ids and enums, int, float). Callers that
## keep it must treat it as immutable (D5.6, F-R58) and may call make_read_only() themselves.
## Example: `var r := DataReader.new(store, BuildFlavor.new(false)).read_file(entry)`.
class_name DataReader extends RefCounted

## 2^53: largest integral float that is still exact.
const MAX_SAFE_INT: float = 9007199254740992.0
## Prefix of every catalog path.
const DATA_ROOT: String = "res://assets/data/"

var _files: FileStore
var _flavor: BuildFlavor


func _init(files: FileStore, flavor: BuildFlavor) -> void:
	_files = files
	_flavor = flavor


## Parse + schema_version + normalisation + FileRules. `value` is null when the file could not be
## parsed or its version is unusable; otherwise it holds the normalised tree plus every issue found.
func read_file(entry: DataCatalog.Entry) -> DataResult:
	var r: DataResult = DataResult.new()
	var rel: String = entry.rel_path
	var raw: Variant = JsonText.read(_files, DATA_ROOT + rel, rel, r.issues)
	if raw == null:
		return r
	if typeof(raw) != TYPE_DICTIONARY:
		r.issues.append(_err(rel, "$", &"root", "root must be an object"))
		return r
	var root: Dictionary = raw
	if not root.has("schema_version"):
		r.issues.append(_err(rel, "schema_version", &"required", "missing schema_version"))
		return r
	var before: int = r.issues.size()
	var ver: int = to_int(root["schema_version"], rel, "schema_version", r.issues)
	if r.issues.size() > before:
		return r
	var supported: int = entry.schema.version()
	if ver != supported:
		var why: String = "newer than supported" if ver > supported else "older than supported"
		r.issues.append(_err(rel, "schema_version", &"version",
				"schema_version %d is %s (expected %d)" % [ver, why, supported]))
		return r
	root.erase("schema_version")
	r.value = normalise(root, entry.schema.root(), rel, "$", r.issues)
	var extra: FileRules = entry.schema.rules()
	if extra != null and not r.has_errors():
		extra.check(r.value, rel, r.issues)
	return r


## D4.1: the only sanctioned int conversion in the project. Accepts an int, or a finite float with
## no fractional part and magnitude <= 2^53. Anything else (2.5, "2", true, null, NAN, INF) appends
## an ERROR naming `path` and returns 0 (a value that must not be used).
static func to_int(v: Variant, file: String, path: String, issues: Array[DataIssue]) -> int:
	match typeof(v):
		TYPE_INT:
			return v
		TYPE_FLOAT:
			var f: float = v
			if is_finite(f) and absf(f) <= MAX_SAFE_INT and f == floorf(f):
				return int(f)
	issues.append(_err(file, path, &"type", "expected integer, got %s" % _describe(v)))
	return 0


## Recursive walk. Returns the normalised value for `spec`; problems are appended to `issues`
## with a JSON path ("puzzles[2].id"). `path` is "$" for the root object.
func normalise(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Variant:
	match spec.kind:
		FieldSpec.Kind.INT:
			var before: int = issues.size()
			var n: int = to_int(v, file, path, issues)
			if issues.size() > before:
				return n
			return _range_int(n, spec, file, path, issues)
		FieldSpec.Kind.FLOAT:
			if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or (typeof(v) == TYPE_FLOAT and not is_finite(v)):
				issues.append(_err(file, path, &"type", "expected finite number, got %s" % _describe(v)))
				return 0.0
			return _range_float(float(v), spec, file, path, issues)
		FieldSpec.Kind.ENUM:
			var s: StringName = StringName(v) if typeof(v) == TYPE_STRING else &""
			if s == &"" or not spec.allowed.has(s):
				issues.append(_err(file, path, &"enum", "%s not in %s" % [_describe(v), spec.allowed]))
			return s
		FieldSpec.Kind.OBJECT:
			return _normalise_object(v, spec, file, path, issues)
		FieldSpec.Kind.ARRAY:
			return _normalise_array(v, spec, file, path, issues)
		_:
			return _normalise_other(v, spec, file, path, issues)


func _normalise_other(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Variant:
	match spec.kind:
		FieldSpec.Kind.BOOL:
			if typeof(v) != TYPE_BOOL:
				issues.append(_err(file, path, &"type", "expected boolean, got %s" % _describe(v)))
				return false
			return v
		FieldSpec.Kind.STRING:
			if typeof(v) != TYPE_STRING:
				issues.append(_err(file, path, &"type", "expected string, got %s" % _describe(v)))
				return ""
			var text: String = v
			if text.is_empty() and not spec.allow_empty:
				issues.append(_err(file, path, &"empty", "string must not be empty"))
			return text
		FieldSpec.Kind.ID:
			if typeof(v) != TYPE_STRING:
				issues.append(_err(file, path, &"type", "expected id string, got %s" % _describe(v)))
				return &""
			var id: String = v
			if not _full_match(spec.pattern, id):
				issues.append(_err(file, path, &"pattern", "\"%s\" does not match %s" % [id, spec.pattern.get_pattern()]))
			return StringName(id)
		FieldSpec.Kind.NULLABLE:
			if v == null:
				return null
			return normalise(v, spec.item, file, path, issues)
		FieldSpec.Kind.MAP:
			return _normalise_map(v, spec, file, path, issues)
		FieldSpec.Kind.ONE_OF:
			return _normalise_one_of(v, spec, file, path, issues)
		FieldSpec.Kind.LANG_TEXT:
			return _normalise_lang_text(v, file, path, issues)
	issues.append(_err(file, path, &"schema", "unsupported spec kind %d" % spec.kind))
	return null


func _normalise_object(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Dictionary:
	var out: Dictionary = {}
	if typeof(v) != TYPE_DICTIONARY:
		issues.append(_err(file, path, &"type", "expected object, got %s" % _describe(v)))
		return out
	var src: Dictionary = v
	for k: Variant in spec.required:
		var key: String = str(k)
		var child_path: String = _join(path, key)
		if not src.has(key):
			issues.append(_err(file, child_path, &"required", "missing required key"))
			continue
		out[key] = normalise(src[key], spec.required[k], file, child_path, issues)
	for k: Variant in spec.optional:
		var key: String = str(k)
		if src.has(key):
			out[key] = normalise(src[key], spec.optional[k], file, _join(path, key), issues)
	for k: Variant in src:
		var key: String = str(k)
		if spec.required.has(key) or spec.optional.has(key):
			continue
		var severity: DataIssue.Severity = DataIssue.Severity.WARNING if spec.open_with_warning \
				else DataIssue.Severity.ERROR
		issues.append(DataIssue.new(severity, file, _join(path, key), &"unknown_key", "unknown key"))
		if spec.open_with_warning:
			out[key] = src[k]
	return out


func _normalise_array(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Array:
	var out: Array = _typed_array(spec.item)
	if typeof(v) != TYPE_ARRAY:
		issues.append(_err(file, path, &"type", "expected array, got %s" % _describe(v)))
		return out
	var src: Array = v
	var drop_bad: bool = spec.record_isolated and not _flavor.is_debug()
	var seen: Dictionary = {}
	for i: int in src.size():
		var item_path: String = "%s[%d]" % [path, i]
		var before: int = issues.size()
		var n: Variant = normalise(src[i], spec.item, file, item_path, issues)
		if drop_bad and _has_error_since(issues, before):
			continue
		if spec.unique_by != &"" and n is Dictionary:
			var item_dict: Dictionary = n
			var ukey: String = str(spec.unique_by)
			if item_dict.has(ukey):
				if seen.has(item_dict[ukey]):
					issues.append(_err(file, _join(item_path, ukey), &"dup_id",
							"duplicate %s %s" % [ukey, item_dict[ukey]]))
				seen[item_dict[ukey]] = true
		out.append(n)
	if src.size() < spec.min_len:
		issues.append(_err(file, path, &"length", "%d items, minimum %d" % [src.size(), spec.min_len]))
	if spec.max_len >= 0 and src.size() > spec.max_len:
		issues.append(_err(file, path, &"length", "%d items, maximum %d" % [src.size(), spec.max_len]))
	return out


func _normalise_map(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Dictionary:
	var out: Dictionary = {}
	if typeof(v) != TYPE_DICTIONARY:
		issues.append(_err(file, path, &"type", "expected object, got %s" % _describe(v)))
		return out
	var src: Dictionary = v
	for k: Variant in src:
		var key: String = str(k)
		var child_path: String = _join(path, key)
		if not _full_match(spec.pattern, key):
			issues.append(_err(file, child_path, &"key", "key does not match %s" % spec.pattern.get_pattern()))
		out[key] = normalise(src[k], spec.item, file, child_path, issues)
	return out


func _normalise_one_of(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Dictionary:
	if typeof(v) != TYPE_DICTIONARY:
		issues.append(_err(file, path, &"type", "expected object, got %s" % _describe(v)))
		return {}
	var src: Dictionary = v
	var tag: Variant = src.get(spec.discriminator)
	if typeof(tag) != TYPE_STRING or not spec.variants.has(tag):
		issues.append(_err(file, _join(path, spec.discriminator), &"variant",
				"%s is not one of %s" % [_describe(tag), spec.variants.keys()]))
		return {}
	return _normalise_object(src, spec.variants[tag], file, path, issues)


func _normalise_lang_text(v: Variant, file: String, path: String, issues: Array[DataIssue]) -> Dictionary:
	var out: Dictionary = {}
	if typeof(v) != TYPE_DICTIONARY:
		issues.append(_err(file, path, &"type", "expected language map, got %s" % _describe(v)))
		return out
	var src: Dictionary = v
	if src.is_empty():
		issues.append(_err(file, path, &"empty", "language map has no entries"))
	for k: Variant in src:
		var lang: String = str(k)
		var child_path: String = _join(path, lang)
		if typeof(src[k]) != TYPE_STRING:
			issues.append(_err(file, child_path, &"type", "expected string, got %s" % _describe(src[k])))
			continue
		var text: String = src[k]
		if text.is_empty():
			issues.append(_err(file, child_path, &"empty", "text must not be empty"))
		out[lang] = text
	return out


func _range_int(n: int, spec: FieldSpec, file: String, path: String, issues: Array[DataIssue]) -> int:
	if n >= spec.min_value and n <= spec.max_value:
		return n
	if spec.out_of_range == FieldSpec.OutOfRange.CLAMP and not _flavor.is_debug():
		issues.append(DataIssue.new(DataIssue.Severity.WARNING, file, path, &"clamped",
				"%d clamped to [%s, %s]" % [n, spec.min_value, spec.max_value]))
		return int(clampf(float(n), spec.min_value, spec.max_value))
	issues.append(_err(file, path, &"range", "%d outside [%s, %s]" % [n, spec.min_value, spec.max_value]))
	return n


func _range_float(n: float, spec: FieldSpec, file: String, path: String, issues: Array[DataIssue]) -> float:
	if n >= spec.min_value and n <= spec.max_value:
		return n
	if spec.out_of_range == FieldSpec.OutOfRange.CLAMP and not _flavor.is_debug():
		issues.append(DataIssue.new(DataIssue.Severity.WARNING, file, path, &"clamped",
				"%s clamped to [%s, %s]" % [n, spec.min_value, spec.max_value]))
		return clampf(n, spec.min_value, spec.max_value)
	issues.append(_err(file, path, &"range", "%s outside [%s, %s]" % [n, spec.min_value, spec.max_value]))
	return n


## Empty array typed for the element kind, so `==` against a typed Array[int] works (D4.4).
static func _typed_array(item: FieldSpec) -> Array:
	match item.kind:
		FieldSpec.Kind.INT:
			return Array([], TYPE_INT, &"", null)
		FieldSpec.Kind.FLOAT:
			return Array([], TYPE_FLOAT, &"", null)
		FieldSpec.Kind.BOOL:
			return Array([], TYPE_BOOL, &"", null)
		FieldSpec.Kind.STRING:
			return Array([], TYPE_STRING, &"", null)
		FieldSpec.Kind.ID, FieldSpec.Kind.ENUM:
			return Array([], TYPE_STRING_NAME, &"", null)
		FieldSpec.Kind.OBJECT, FieldSpec.Kind.MAP, FieldSpec.Kind.ONE_OF, FieldSpec.Kind.LANG_TEXT:
			return Array([], TYPE_DICTIONARY, &"", null)
	return []


static func _full_match(re: RegEx, s: String) -> bool:
	var m: RegExMatch = re.search(s)
	return m != null and m.get_start() == 0 and m.get_end() == s.length()


static func _has_error_since(issues: Array[DataIssue], from: int) -> bool:
	for i: int in range(from, issues.size()):
		if issues[i].severity == DataIssue.Severity.ERROR:
			return true
	return false


static func _join(path: String, key: String) -> String:
	return key if path == "$" else "%s.%s" % [path, key]


static func _describe(v: Variant) -> String:
	if typeof(v) == TYPE_FLOAT and not is_finite(v):
		return "non-finite number"
	return type_string(typeof(v))


static func _err(file: String, path: String, rule: StringName, msg: String) -> DataIssue:
	return DataIssue.new(DataIssue.Severity.ERROR, file, path, rule, msg)
