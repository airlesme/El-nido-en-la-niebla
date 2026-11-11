## Thin wrapper over the engine JSON parser. The ONLY place that touches JSON (ADR-0005 D5, F-R54..F-R57).
## Strictness the engine lacks (BOM, trailing commas, duplicate object keys) is added by pre-checks.
## Never throws: every problem becomes a DataIssue and the result is null.
## Example: `var issues: Array[DataIssue] = []; var tree: Variant = JsonText.read(store, path, path, issues)`.
class_name JsonText extends RefCounted

const _BOM: PackedByteArray = [0xEF, 0xBB, 0xBF]


## Reads `path` through `store` and parses it. Checks missing / empty / BOM on the BYTES before
## decoding (the engine strips the BOM silently, S-0005-A A5). Returns the raw tree or null.
## `file` is the name used in issues. Reads the file exactly once per call.
static func read(store: FileStore, path: String, file: String, issues: Array[DataIssue]) -> Variant:
	var bytes: PackedByteArray = store.read_bytes(path)
	var err: Error = store.last_error()
	if err != OK:
		var rule: StringName = &"missing" if err == ERR_FILE_NOT_FOUND else &"open_error"
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "$", rule,
				"cannot open file (error %d: %s)" % [err, error_string(err)]))
		return null
	if bytes.is_empty():
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "$", &"empty", "file is empty"))
		return null
	var had_bom: bool = bytes.size() >= 3 and bytes.slice(0, 3) == _BOM
	if had_bom:
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "$", &"bom",
				"UTF-8 BOM is not allowed"))
		bytes = bytes.slice(3)
	var tree: Variant = _parse_checked(bytes.get_string_from_utf8(), file, issues)
	return null if had_bom else tree


## Parses already-decoded text. Returns the raw tree or null (and appends issues with line and
## code) for broken JSON, trailing commas or duplicate keys in an object. A BOM that survived
## decoding is also rejected. Never throws.
static func parse(text: String, file: String, issues: Array[DataIssue]) -> Variant:
	if text.begins_with("﻿"):
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "$", &"bom",
				"UTF-8 BOM is not allowed"))
		_parse_checked(text.substr(1), file, issues)
		return null
	return _parse_checked(text, file, issues)


static func _parse_checked(text: String, file: String, issues: Array[DataIssue]) -> Variant:
	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		var line: int = json.get_error_line()
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file,
				"line %d" % line if line > 0 else "$", &"parse", json.get_error_message()))
		return null
	var before: int = issues.size()
	_scan_text(text, file, issues)
	if issues.size() > before:
		return null
	return json.get_data()


## Single pass over syntactically valid JSON text: reports trailing commas and duplicate keys.
## Keys are compared on their raw (still escaped) spelling.
static func _scan_text(text: String, file: String, issues: Array[DataIssue]) -> void:
	var is_object: Array[bool] = []
	var keys: Array[Dictionary] = []
	var expect_key: Array[bool] = []
	var last: String = ""
	var line: int = 1
	var i: int = 0
	var n: int = text.length()
	while i < n:
		var c: String = text[i]
		if c == "\n":
			line += 1
		elif c == " " or c == "\t" or c == "\r":
			pass
		elif c == "\"":
			var j: int = i + 1
			while j < n and text[j] != "\"":
				if text[j] == "\\":
					j += 1
				j += 1
			if not is_object.is_empty() and is_object[-1] and expect_key[-1]:
				var key: String = text.substr(i + 1, j - i - 1)
				if keys[-1].has(key):
					issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "line %d" % line,
							&"dup_key", "duplicate object key \"%s\"" % key))
				keys[-1][key] = true
				expect_key[-1] = false
			last = "\""
			i = j
		elif c == "{" or c == "[":
			is_object.append(c == "{")
			keys.append({})
			expect_key.append(c == "{")
			last = c
		elif c == "}" or c == "]":
			if last == ",":
				issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "line %d" % line,
						&"trailing_comma", "trailing comma before '%s'" % c))
			if not is_object.is_empty():
				is_object.pop_back()
				keys.pop_back()
				expect_key.pop_back()
			last = c
		else:
			if c == "," and not is_object.is_empty() and is_object[-1]:
				expect_key[-1] = true
			last = c
		i += 1
