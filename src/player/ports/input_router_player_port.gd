## Production adapter of `PlayerInputPort` over `InputRouter` (ADR-0012 D6, ADR-0006). Holds no state of its own.
## TODO(ADR-0012): the ADR names the adapter (`InputRouterPlayerPort.new(ctx.input)`) but not its file; fixed here (owner: lead-programmer).
## Example: `var port: PlayerInputPort = InputRouterPlayerPort.new(ctx.input)`.
class_name InputRouterPlayerPort extends PlayerInputPort

var _router: InputRouter


func _init(router: InputRouter) -> void:
	_router = router


## `InputRouter.top()`; `MENU` when the router is gone (the Player stays frozen).
func context() -> InputTypes.Context:
	if not is_instance_valid(_router):
		return InputTypes.Context.MENU
	return _router.top()


## `InputRouter.get_move_vector()`; zero when the router is gone.
func move_vector() -> Vector2:
	if not is_instance_valid(_router):
		return Vector2.ZERO
	return _router.get_move_vector()


## `InputRouter.consume_look_delta()` in degrees; zero when the router is gone.
func look_delta_deg() -> Vector2:
	if not is_instance_valid(_router):
		return Vector2.ZERO
	return _router.consume_look_delta()
