## The only class that touches resource loading for world scenes (ADR-0003 § Key Interfaces).
## Port: production loads a PackedScene and instantiates it; tests inject a fake factory.
## Synchronous load (ADR-0003 D4); never `ResourceLoader.load_threaded_*` (C-X03).
## Example: `var root: Node = source.instantiate(&"planta")  # null on failure`.
class_name SceneSource extends RefCounted

## destination key -> scene path.
## TODO(carga-013): confirm the final location of planta.tscn / recepcion.tscn (owner: carga-013).
const DEFAULT_PATHS: Dictionary = {
	&"planta": "res://src/scene/world/planta.tscn",
	&"recepcion": "res://src/scene/world/recepcion.tscn",
}

## Overridable path table (tests and 013 may point it elsewhere).
var paths: Dictionary = DEFAULT_PATHS


## Returns the instantiated scene for `destination` (&"planta" | &"recepcion") or null on failure.
## Never throws: unknown destination, missing path, non-PackedScene resource and
## non-instantiable scene all yield null.
func instantiate(destination: StringName) -> Node:
	if not paths.has(destination):
		return null
	var path: String = String(paths[destination])
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null or not packed.can_instantiate():
		return null
	return packed.instantiate()
