## Pick volume of one interactable (ADR-0011 D2): an `Area3D` with a single `CollisionShape3D` whose shape is
## an unscaled `BoxShape3D` on physics layer bit 3. The F1 focus never queries physics; `PickRegistry` reads the
## box size once and the live transform of the shape node.
## Example: add `InteractablePick` with `interactable_id = &"V02"` and a child `CollisionShape3D`.
class_name InteractablePick extends Area3D

const GROUP: StringName = &"interactable_pick"

## Catalog id (`interactables.json`). Unknown or duplicate ids are data errors at registry build.
@export var interactable_id: StringName = &""
## Own-subtree nodes that must not occlude this pick (ADR-0009 rule 2; used by the occlusion story).
@export var self_occluders: Array[NodePath] = []


func _init() -> void:
	collision_layer = InteractionTypes.LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	add_to_group(GROUP)


## The first `CollisionShape3D` child, or null.
func shape_node() -> CollisionShape3D:
	for c: Node in get_children():
		if c is CollisionShape3D:
			return c as CollisionShape3D
	return null
