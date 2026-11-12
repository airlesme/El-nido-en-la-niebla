## Test double: a GameState whose status and `llamada_completada` are set by the test.
## It is a Node, so the suite must auto_free() it. Counts writes (must stay 0).
class_name ScriptedGameState extends GameState

var scripted_status: GameState.Status = GameState.Status.READY
var call_completed: bool = false
var write_count: int = 0


func get_status() -> GameState.Status:
	return scripted_status


func get_fact(fact: StringName) -> Variant:
	return call_completed if fact == &"llamada_completada" else false


func set_fact(_fact: StringName, _value: Variant, _owner_id: int) -> bool:
	write_count += 1
	return false
