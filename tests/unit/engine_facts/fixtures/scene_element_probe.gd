extends Node3D
## Fixture for adr0003_instantiate_free_orphans_test.gd: a scene element that subscribes to a fake bus.
## `disconnect_on_exit` false means it relies on the engine dropping the connection when it is freed.

@export var disconnect_on_exit: bool = true

var received: int = 0


func _ready() -> void:
	var bus: Object = Engine.get_meta(&"adr0003_bus") as Object
	bus.connect(&"event_emitted", _on_event)


func _exit_tree() -> void:
	if not disconnect_on_exit:
		return
	var bus: Object = Engine.get_meta(&"adr0003_bus", null) as Object
	if bus != null and bus.is_connected(&"event_emitted", _on_event):
		bus.disconnect(&"event_emitted", _on_event)


func _on_event() -> void:
	received += 1
