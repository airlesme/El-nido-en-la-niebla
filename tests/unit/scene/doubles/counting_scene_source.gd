## Test double: a SceneSource that counts instantiate() calls and returns null.
class_name CountingSceneSource extends SceneSource

var calls: int = 0


func instantiate(_destination: StringName) -> Node:
	calls += 1
	return null
