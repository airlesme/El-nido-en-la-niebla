class_name ZoneTrigger extends Area3D
## Trigger volume `T-...` (ADR-0003 D8). No logic: it only forwards its ID to the `ZoneHub`.
##
## `monitoring` starts false (the hub / SceneLoader enables it at "terminada"); the mask is
## only `zone_sensor`. Never reads facts.

## Emitted when the player's zone sensor enters this volume.
signal entered(zone_id: StringName)

## Layer bits by name in `project.godot` (ADR-0011): `zone_sensor` = 4, `zone_trigger` = 5.
const LAYER_ZONE_SENSOR: int = 1 << 3
const LAYER_ZONE_TRIGGER: int = 1 << 4

## Zone ID, e.g. `T-PAS-1`.
@export var zone_id: StringName = &""


func _init() -> void:
	collision_layer = LAYER_ZONE_TRIGGER
	collision_mask = LAYER_ZONE_SENSOR
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


func _on_area_entered(_area: Area3D) -> void:
	entered.emit(zone_id)
