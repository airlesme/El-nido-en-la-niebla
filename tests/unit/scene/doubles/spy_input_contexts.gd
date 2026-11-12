## Test double of the `sin control` port: logs every call into a shared event list.
class_name SpyInputContexts extends InputContexts

var events: Array[String] = []
var opens: Array[Dictionary] = []
var exploration_requests: int = 0
var reset_calls: int = 0
var restore_calls: int = 0


func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
	events.append("input:open_no_control")
	opens.append({&"owner": owner, &"declared_s": declared_s, &"absorbs": absorbs_foreign})
	return true


func request_exploration(_owner: StringName) -> bool:
	events.append("input:request_exploration")
	exploration_requests += 1
	return true


func restore_menu() -> void:
	events.append("input:restore_menu")
	restore_calls += 1


func reset_stack_on_unload() -> void:
	events.append("input:reset_stack_on_unload")
	reset_calls += 1
