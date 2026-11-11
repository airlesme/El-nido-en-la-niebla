## One finding of the data pipeline. Never thrown: always collected (ADR-0005 Key Interfaces, F-R65).
## Example: `issues.append(DataIssue.new(DataIssue.Severity.ERROR, "puzzles/puzzles.json", "line 4", &"parse", "bad"))`.
class_name DataIssue extends RefCounted

enum Severity { WARNING, ERROR }

## Severity of the finding.
var severity: Severity
## File path relative to assets/data/, e.g. "puzzles/puzzles.json".
var file: String
## Location inside the file: "puzzles[2].id", "line 7" or "$" (whole file).
var json_path: String
## Machine-readable code: &"bom", &"parse", &"missing", &"empty", &"dup_key", ...
var rule: StringName
## English, developer-facing message (log only, never shown to the player).
var message: String
## Free tags, e.g. ["quality"].
var tags: PackedStringArray = PackedStringArray()


func _init(p_sev: Severity, p_file: String, p_path: String, p_rule: StringName, p_msg: String) -> void:
	severity = p_sev
	file = p_file
	json_path = p_path
	rule = p_rule
	message = p_msg


## One-line text: "ERROR puzzles/puzzles.json puzzles[2].id dup_id: duplicate id P3".
func format() -> String:
	return "%s %s %s %s: %s" % [Severity.keys()[severity], file, json_path, rule, message]
