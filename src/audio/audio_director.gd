## Audio layers and voice queue (system 23).
## Skeleton (S0): no game logic. Registered as autoload `AudioDirectorAutoload` (ADR-0009 D1).
## TODO(ADR-0008): the public API of this service is not signed in ADR-0009; add it from the owning ADR.
class_name AudioDirector extends Node


func _init() -> void:
	# ADR-0009 D2: explicit, never inherited. No I/O, no autoload reads here.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Composition point, called once by Boot (ADR-0009 D2/D3). Never called by systems.
func setup(_ctx: ServiceContext) -> void:
	# TODO(ADR-0008): real initialisation (ADR-0009 D2 boot order).
	return
