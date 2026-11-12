## The only class that touches resource loading for world scenes (ADR-0003 § Key Interfaces).
## Port: production loads a PackedScene and instantiates it; tests inject a fake factory.
## TODO(carga-005): real implementation (`load(path) as PackedScene` + `instantiate()`), after S-0003-A.
## Example: `var root: Node = source.instantiate(&"planta")  # null on failure`.
class_name SceneSource extends RefCounted


## Returns the instantiated scene for `destination` (&"planta" | &"recepcion") or null on failure.
## Never throws.
func instantiate(_destination: StringName) -> Node:
	return null
