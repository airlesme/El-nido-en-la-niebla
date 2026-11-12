## Test double of SceneSource for the failure causes of CP-008. Nodes only; no RefCounted cycles.
class_name FailingSceneSource extends SceneSource

## Returns null with `last_failure` = this value when set (`&"missing_resource"`, `&"instantiate_failed"`, `&""`).
var null_with: Variant = null
var missing: PackedStringArray = PackedStringArray()
var break_anchor: bool = false
var duplicate_anchor: bool = false
var events: Array[String] = []


func instantiate(_destination: StringName) -> Node:
	if null_with != null:
		last_failure = StringName(null_with)
		return null
	last_failure = &""
	var root: FailingSceneRoot = FailingSceneRoot.new()
	root.build(events)
	root.missing = missing
	if break_anchor:
		root.spawn_anchor = ^"Nope"
	if duplicate_anchor:
		root.add_duplicate_anchor()
	return root
