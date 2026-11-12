## Test double of a game scene root (planta/recepcion): the shape SceneLoader expects (ADR-0003 Key Interfaces).
## Logs to a shared event list; `configure_all` mimics the order 7 -> validation of 9 -> 9 -> rest.
## TODO(carga-012): replaced by the real GameSceneRoot.
class_name SceneRootDouble extends Node3D

@export var spawn_anchor: NodePath = ^"Anchor"

## Shared, append-only event log (strings only, so no reference cycle).
var events: Array[String] = []
var fail_validation: bool = false
var player: PlayerSpy
var hub: ZoneHub
var configure_calls: int = 0
## Value of `archivo_abierto` seen by the element spy during `configure_all` (null = never read).
var element_saw: Variant = null


## Builds the children (anchor, player spy, hub). Call before adding to the tree.
func build(event_log: Array[String]) -> SceneRootDouble:
	events = event_log
	var anchor: Node3D = Node3D.new()
	anchor.name = &"Anchor"
	anchor.position = Vector3(1.0, 2.0, 3.0)
	anchor.rotation.y = 0.5
	add_child(anchor)
	player = PlayerSpy.new()
	player.name = &"Player"
	player.events = event_log
	add_child(player)
	hub = ZoneHub.new()
	hub.name = &"ZoneHub"
	add_child(hub)
	return self


func validate_required_nodes() -> PackedStringArray:
	return PackedStringArray()


func get_player() -> Object:
	return get_node_or_null(^"Player") # by path: survives PackedScene round trips


func get_zone_hub() -> ZoneHub:
	return get_node_or_null(^"ZoneHub") as ZoneHub


func configure_all(ctx: ServiceContext) -> int:
	configure_calls += 1
	events.append("configure:7")
	if fail_validation:
		events.append("validate:9:fail")
		return SceneLoader.CONFIGURE_INVALID_PUZZLE_DATA
	events.append("validate:9")
	events.append("configure:9")
	element_saw = ctx.state.get_fact(&"archivo_abierto")
	events.append("configure:rest")
	return SceneLoader.CONFIGURE_OK


func _exit_tree() -> void:
	events.append("unload")
