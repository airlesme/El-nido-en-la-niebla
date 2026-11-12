## Port of the `sin control` operations that Boot hands to 4 (SceneLoader) and 21 (SceneDirector)
## (ADR-0003 contract, ADR-0006 D4). Thin: every call goes to the router, which logs rejections.
## Holds a weak reference so the port never keeps the router alive (no RefCounted cycle).
## Example: `ports.open_no_control(InputTypes.OWNER_SCENE_LOADER, 2.0, true)`.
## TODO(input-owner): ADR-0006 lists the file as `input_contexts_port.gd`; the story fixes `input_contexts.gd`.
class_name InputContexts extends RefCounted

var _router_ref: WeakRef


func _init(router: InputRouter = null) -> void:
	_router_ref = weakref(router)


## See `InputRouter.open_no_control`.
func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
	var r: InputRouter = _router()
	return r != null and r.open_no_control(owner, declared_s, absorbs_foreign)


## See `InputRouter.close_no_control`.
func close_no_control(owner: StringName) -> bool:
	var r: InputRouter = _router()
	return r != null and r.close_no_control(owner)


## See `InputRouter.transfer_no_control`.
func transfer_no_control(new_owner: StringName, declared_s: float) -> bool:
	var r: InputRouter = _router()
	return r != null and r.transfer_no_control(new_owner, declared_s)


## See `InputRouter.request_exploration`.
func request_exploration(owner: StringName) -> bool:
	var r: InputRouter = _router()
	return r != null and r.request_exploration(owner)


## See `InputRouter.restore_menu`.
func restore_menu() -> void:
	var r: InputRouter = _router()
	if r != null:
		r.restore_menu()


## See `InputRouter.reset_stack_on_unload`.
func reset_stack_on_unload() -> void:
	var r: InputRouter = _router()
	if r != null:
		r.reset_stack_on_unload()


func _router() -> InputRouter:
	return _router_ref.get_ref() as InputRouter
