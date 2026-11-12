## Root script of planta.tscn / recepcion.tscn (ADR-0003 § Key Interfaces, GDD escena-de-planta R2-R4, R9).
## Exposes the player, the zone hub, the required-node validation and the ordered, synchronous
## `configure_all` (7 -> validation of 9 -> 9 -> group `scene_element` in tree order).
## Example: `if root.configure_all(ctx) == GameSceneRoot.ConfigureResult.INVALID_PUZZLE_DATA: ...`
class_name GameSceneRoot extends Node3D

## Group of every element exposing `configurar(ctx)`.
const ELEMENT_GROUP: StringName = &"scene_element"
## Node names (anywhere below the root) that M1 requires: containers and anchors.
## `door_slot_b`, `door_slot_d`, `door_slot_elevator` belong to rooms outside M1 and are not required.
## TODO(adr-0003-o-item): annotate this M1 list in ADR-0003 O-items (owner: carga-012).
const DEFAULT_REQUIRED_NODES: PackedStringArray = [
	"office", "corridor", "archive", "spawn_office", "door_slot_a", "drawer_slot_a05",
]

enum ConfigureResult { OK, INVALID_PUZZLE_DATA }

## Spawn anchor (`spawn_office` | `spawn_elevator`).
@export var spawn_anchor: NodePath
## [InteractionSystem (7), PuzzleFramework (9)] in planta; empty is valid (recepcion, M1 before 7/9).
@export var configure_first: Array[NodePath] = []
## Names that `validate_required_nodes` demands. Empty disables the check (recepcion).
@export var required_nodes: PackedStringArray = DEFAULT_REQUIRED_NODES

@export var player_path: NodePath = ^"Player"
@export var zone_hub_path: NodePath = ^"ZoneHub"


## Registers every `ZoneTrigger` below the root with the zone hub (their `monitoring` stays false until the hub is enabled).
func _ready() -> void:
	var hub: ZoneHub = get_zone_hub()
	if hub == null:
		return
	for node: Node in find_children("*", "ZoneTrigger", true, false):
		hub.register(node as ZoneTrigger)


## The Player child (typed as Node: the Player class belongs to system 2).
## TODO(pj-011): return type `Player` once it exists (owner: pj-011).
func get_player() -> Node:
	return get_node_or_null(player_path)


## The zone hub of this scene, or null.
func get_zone_hub() -> ZoneHub:
	return get_node_or_null(zone_hub_path) as ZoneHub


## Names from `required_nodes` that are absent (empty = OK). Order follows the list.
func validate_required_nodes() -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	for node_name: String in required_nodes:
		if find_child(node_name, true, false) == null:
			missing.append(node_name)
	return missing


## Calls `configurar(ctx)` on `configure_first` in order, then on `ELEMENT_GROUP` in tree order,
## skipping already-configured nodes. Synchronous. After each configure_first node that exposes
## `configuration_failed()` (PuzzleFramework, ADR-0010 D13) a true answer stops everything and
## returns INVALID_PUZZLE_DATA.
## TODO(puzzle-framework): bind to PuzzleFramework.configuration_failed() when it exists (owner: ADR-0010 story).
func configure_all(ctx: ServiceContext) -> ConfigureResult:
	var done: Dictionary = {} # Node instance id -> true
	for path: NodePath in configure_first:
		var node: Node = get_node_or_null(path)
		if node == null or done.has(node.get_instance_id()):
			continue
		done[node.get_instance_id()] = true
		_configure(node, ctx)
		if node.has_method(&"configuration_failed") and bool(node.call(&"configuration_failed")):
			return ConfigureResult.INVALID_PUZZLE_DATA
	if not is_inside_tree():
		return ConfigureResult.OK
	for element: Node in get_tree().get_nodes_in_group(ELEMENT_GROUP):
		if not is_ancestor_of(element) or done.has(element.get_instance_id()):
			continue
		done[element.get_instance_id()] = true
		_configure(element, ctx)
	return ConfigureResult.OK


func _configure(node: Node, ctx: ServiceContext) -> void:
	if node.has_method(&"configurar"):
		node.call(&"configurar", ctx)
