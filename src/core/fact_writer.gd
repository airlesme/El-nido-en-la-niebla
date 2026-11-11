## Write capability of one system (ADR-0001 D7, control manifest F-R05). `Boot` hands each writer
## system a `FactWriter` bound to its own owner number, so a system never passes (or forges) it.
## Example: `var w: FactWriter = state.writer_for(9); w.write(&"caja_c1", true)`.
class_name FactWriter extends RefCounted

var _state: GameState
var _owner_id: int


## Binds the writer to `state` and the owner number of the system it is given to.
func _init(state: GameState, owner_id: int) -> void:
	_state = state
	_owner_id = owner_id


## Writes `fact` through `GameState.set_fact` with this writer's owner. Returns true when the value
## was accepted (changed or identical), false when rejected. Example: `w.write(&"pos_L", 3)`.
func write(fact: StringName, value: Variant) -> bool:
	return _state.set_fact(fact, value, _owner_id)
