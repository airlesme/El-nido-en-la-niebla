## Debug/release policy, injected so tests can run release behaviour in the editor.
## ADR-0005 Key Interfaces; ADR-0018 V-18-2 expects editor true, playtest true, demo false.
class_name BuildFlavor extends RefCounted

var _debug: bool


func _init(debug: bool) -> void:
	_debug = debug


## Boot-time factory: reads the engine build type. Only Boot should call this.
static func from_engine() -> BuildFlavor:
	return BuildFlavor.new(OS.is_debug_build())


## True in editor and debug exports (playtest); false in release (demo).
func is_debug() -> bool:
	return _debug
