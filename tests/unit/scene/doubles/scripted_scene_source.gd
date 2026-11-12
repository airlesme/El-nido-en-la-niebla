## Test double of SceneSource: builds a fresh SceneRootDouble per call (never reuses an instance).
## `fail` makes it return null. Records the GameClock time seen at instantiation (reset_session check).
class_name ScriptedSceneSource extends SceneSource

var events: Array[String] = []
var fail: bool = false
var fail_validation: bool = false
var game_clock: GameClock
var clock_seen: float = -1.0
var made: Array[SceneRootDouble] = []


func instantiate(_destination: StringName) -> Node:
	events.append("src:instantiate")
	if game_clock != null:
		clock_seen = game_clock.now()
	if fail:
		return null
	var root: SceneRootDouble = SceneRootDouble.new().build(events)
	root.fail_validation = fail_validation
	made.append(root)
	return root
