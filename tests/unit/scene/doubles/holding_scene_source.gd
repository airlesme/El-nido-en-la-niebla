## Test double of SceneSource: builds a SceneRootDouble whose `configure_all` takes the given holds
## on `loader` (as game elements would in step 6). Nodes only: no RefCounted cycle.
class_name HoldingSceneSource extends SceneSource

var loader: SceneLoader
var events: Array[String] = []
var hold_ids: Array[StringName] = []


func instantiate(_destination: StringName) -> Node:
	var root: HoldingSceneRoot = HoldingSceneRoot.new()
	root.build(events)
	root.loader = loader
	root.hold_ids = hold_ids.duplicate()
	return root
