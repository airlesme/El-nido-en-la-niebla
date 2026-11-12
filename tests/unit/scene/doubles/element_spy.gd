## Test double of a scene element / system with `configurar(ctx)`: logs to a shared string list.
## `failing` makes `configuration_failed()` answer true (PuzzleFramework stand-in, ADR-0010 D13).
class_name ElementSpy extends Node

var events: Array[String] = []
var failing: bool = false


func configurar(_ctx: ServiceContext) -> void:
	events.append("configure:%s" % name)


func configuration_failed() -> bool:
	events.append("failed?:%s" % name)
	return failing
