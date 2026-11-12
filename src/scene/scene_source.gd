## The only class that touches resource loading for world scenes (ADR-0003 § Key Interfaces).
## Port: production loads a PackedScene and instantiates it; tests inject a fake factory.
## Synchronous load (ADR-0003 D4); never `ResourceLoader.load_threaded_*` (C-X03).
## Example: `var root: Node = source.instantiate(&"planta")  # null on failure`.
class_name SceneSource extends RefCounted

## destination key -> scene path.
## `planta.tscn` lives here since CP-013; `recepcion.tscn` does not exist yet (the loader treats it as a load failure).
## TODO(recepcion-scene): create recepcion.tscn (owner: Recepcion story).
const DEFAULT_PATHS: Dictionary = {
	&"planta": "res://src/scene/planta.tscn",
	&"recepcion": "res://src/scene/recepcion.tscn",
	&"title": "res://src/shell/title.tscn",
}
## Key of the title marker (a slot occupant, not a game scene: ADR-0003 D2).
const TITLE: StringName = &"title"

## Failure kinds the loader maps to its causes (CP-008).
const FAILURE_MISSING_RESOURCE: StringName = &"missing_resource"
const FAILURE_INSTANTIATE_FAILED: StringName = &"instantiate_failed"

## Why the last `instantiate` returned null (`&""` after a success or before any call).
## Doubles may set it; an empty value on failure is read as `instantiate_failed`.
var last_failure: StringName = &""

## Overridable path table (tests and 013 may point it elsewhere).
var paths: Dictionary = DEFAULT_PATHS


## Returns the instantiated scene for `destination` (&"planta" | &"recepcion" | &"title") or null on failure.
## Never throws: unknown destination, missing path, non-PackedScene resource and
## non-instantiable scene all yield null.
func instantiate(destination: StringName) -> Node:
	last_failure = &""
	if not paths.has(destination):
		last_failure = FAILURE_MISSING_RESOURCE
		return null
	var path: String = String(paths[destination])
	if not ResourceLoader.exists(path):
		last_failure = FAILURE_MISSING_RESOURCE
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null or not packed.can_instantiate():
		last_failure = FAILURE_INSTANTIATE_FAILED
		return null
	return packed.instantiate()
