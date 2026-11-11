## Tier B (boot sweep, debug) and tier C (CI) validator (ADR-0005 D3). Created by Boot (ADR-0009 D1).
## Reads every catalog entry with the same DataReader the owners use, builds a RefIndex from the
## normalised results and resolves every `ref()` of every schema. Never stops at the first issue.
## Example: `var issues := DataValidator.new(reader, logger).sweep(DataCatalog.entries())`.
class_name DataValidator extends RefCounted

## Narrative files whose records are content keys (ADR-0005 D2.3).
const NARRATIVE_DIR: String = "narrative/"
const FLAGS_FILE: String = "state/flags.json"

var _reader: DataReader
var _log: LogSink
var _entries: Array[DataCatalog.Entry]


## `entries` defaults to the catalog; tests and tier C may inject their own list.
func _init(reader: DataReader, log_sink: LogSink,
		entries: Array[DataCatalog.Entry] = DataCatalog.entries()) -> void:
	_reader = reader
	_log = log_sink
	_entries = entries


## Reads every entry, builds the RefIndex, resolves every ref() and detects ids repeated across
## files. Returns all issues (reader issues first, then cross-file ones); never stops early (D3.3).
func sweep(entries: Array[DataCatalog.Entry]) -> Array[DataIssue]:
	var all: Array[DataIssue] = []
	var results: Dictionary = {} # rel_path -> DataResult
	for e: DataCatalog.Entry in entries:
		var r: DataResult = _reader.read_file(e)
		results[e.rel_path] = r
		all.append_array(r.issues)
	var index: RefIndex = _build_index(entries, results, all)
	for e: DataCatalog.Entry in entries:
		var r: DataResult = results[e.rel_path]
		if r.value != null:
			_check_refs(r.value, e.schema.root(), index, e.rel_path, "$", all)
	return all


## Boot step 4 entry point (tier B). Debug only: Boot does not call it in release.
## Logs every issue and raises ONE fatal with the count and the first error: CONTENIDO_INVALIDO when
## that error's file is a narrative one, otherwise the code of its registry row (CATALOGO_INVALIDO
## by default).
func run(ctx: ServiceContext) -> void:
	var issues: Array[DataIssue] = sweep(_entries)
	var errors: int = 0
	var first: DataIssue = null
	for i: DataIssue in issues:
		if i.severity == DataIssue.Severity.ERROR:
			errors += 1
			if first == null:
				first = i
			_log.line(LogSink.LEVEL_ERROR, i.format())
		else:
			_log.line(LogSink.LEVEL_WARN, i.format())
	if errors > 0:
		ctx.fatal.raise_fatal(_fatal_code_for(first.file),
				{&"count": errors, &"file": first.file, &"param": first.json_path, &"rule": first.rule})


func _fatal_code_for(file: String) -> StringName:
	for e: DataCatalog.Entry in _entries:
		if e.rel_path == file:
			return e.fatal_code
	return FatalErrorHandler.CATALOGO_INVALIDO


# --- RefIndex construction -------------------------------------------------

## Indexes facts (+ enum values) from state/flags.json and every record id of narrative/*.
## An id already indexed from another file (or earlier in this one) is a `dup_id` ERROR.
func _build_index(entries: Array[DataCatalog.Entry], results: Dictionary,
		issues: Array[DataIssue]) -> RefIndex:
	var index: RefIndex = RefIndex.new()
	var owner_of: Dictionary = {} # content id -> "file path"
	for e: DataCatalog.Entry in entries:
		var r: DataResult = results[e.rel_path]
		if r.value == null or typeof(r.value) != TYPE_DICTIONARY:
			continue
		var root: Dictionary = r.value
		if e.rel_path == FLAGS_FILE:
			_index_facts(root, index)
		elif e.rel_path.begins_with(NARRATIVE_DIR):
			_index_content(e.rel_path, root, index, owner_of, issues)
	return index


func _index_facts(root: Dictionary, index: RefIndex) -> void:
	var facts: Variant = root.get("facts")
	if typeof(facts) != TYPE_ARRAY:
		return
	for f: Variant in facts:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = f
		if not fact.has("name"):
			continue
		var name: StringName = StringName(fact["name"])
		index.add(&"fact", name)
		if fact.has("values") and typeof(fact["values"]) == TYPE_ARRAY:
			index.set_fact_values(name, fact["values"])


func _index_content(file: String, root: Dictionary, index: RefIndex, owner_of: Dictionary,
		issues: Array[DataIssue]) -> void:
	for coll: Variant in root:
		var records: Variant = root[coll]
		if typeof(records) != TYPE_ARRAY:
			continue
		var arr: Array = records
		for i: int in arr.size():
			if typeof(arr[i]) != TYPE_DICTIONARY:
				continue
			var rec: Dictionary = arr[i]
			if not rec.has("id"):
				continue
			var id: StringName = StringName(rec["id"])
			var path: String = "%s[%d].id" % [coll, i]
			if owner_of.has(id):
				issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, path, &"dup_id",
						"duplicate id %s (also in %s)" % [id, owner_of[id]]))
				continue
			owner_of[id] = file
			index.add(&"content_key", id)
			if StringName(rec.get("status", &"active")) == &"retired":
				index.add_retired(id)


# --- ref() resolution ------------------------------------------------------

## Walks `value` along `spec` and resolves every ID field that declares a `ref_kind`.
## Kinds nobody provides yet (item, interactable, view, sound) and &"fact_value" are skipped.
## TODO(ADR-0010): fact_value needs the sibling fact name; resolved with the puzzles schema story.
func _check_refs(value: Variant, spec: FieldSpec, index: RefIndex, file: String, path: String,
		issues: Array[DataIssue]) -> void:
	match spec.kind:
		FieldSpec.Kind.ID:
			if spec.ref_kind != &"" and typeof(value) == TYPE_STRING_NAME:
				_resolve(StringName(value), spec.ref_kind, index, file, path, issues)
		FieldSpec.Kind.NULLABLE:
			if value != null:
				_check_refs(value, spec.item, index, file, path, issues)
		FieldSpec.Kind.ARRAY:
			if typeof(value) == TYPE_ARRAY:
				var arr: Array = value
				for i: int in arr.size():
					_check_refs(arr[i], spec.item, index, file, "%s[%d]" % [path, i], issues)
		FieldSpec.Kind.MAP:
			if typeof(value) == TYPE_DICTIONARY:
				var d: Dictionary = value
				for k: Variant in d:
					_check_refs(d[k], spec.item, index, file, DataReader._join(path, str(k)), issues)
		FieldSpec.Kind.OBJECT:
			_check_object_refs(value, spec, index, file, path, issues)
		FieldSpec.Kind.ONE_OF:
			if typeof(value) == TYPE_DICTIONARY:
				var obj: Dictionary = value
				var tag: Variant = obj.get(spec.discriminator)
				if typeof(tag) == TYPE_STRING and spec.variants.has(tag):
					_check_object_refs(value, spec.variants[tag], index, file, path, issues)


func _check_object_refs(value: Variant, spec: FieldSpec, index: RefIndex, file: String, path: String,
		issues: Array[DataIssue]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	var obj: Dictionary = value
	for table: Dictionary in [spec.required, spec.optional]:
		for k: Variant in table:
			var key: String = str(k)
			if obj.has(key):
				_check_refs(obj[key], table[k], index, file, DataReader._join(path, key), issues)


func _resolve(id: StringName, kind: StringName, index: RefIndex, file: String, path: String,
		issues: Array[DataIssue]) -> void:
	if kind == &"fact_value" or not index.provides(kind):
		return
	if not index.has(kind, id):
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, path, &"ref_missing",
				"%s '%s' does not exist" % [kind, id]))
	elif index.is_retired(id):
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, path, &"ref_retired",
				"%s '%s' is retired" % [kind, id]))
