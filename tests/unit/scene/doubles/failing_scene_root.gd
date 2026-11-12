## Scene root double whose validation reports `missing` names, whose spawn anchor path can be broken,
## and which can carry a second node named like the anchor (R4, AC-15c).
class_name FailingSceneRoot extends SceneRootDouble

var missing: PackedStringArray = PackedStringArray()


func validate_required_nodes() -> PackedStringArray:
	return missing


## Adds a second `Anchor` below a child node, after the original one in tree order.
func add_duplicate_anchor() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = &"Extra"
	add_child(holder)
	var twin: Node3D = Node3D.new()
	twin.name = &"Anchor"
	twin.position = Vector3(9.0, 9.0, 9.0)
	holder.add_child(twin)
