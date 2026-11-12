## Port that gives the Player its input (ADR-0012 § Key Interfaces «PlayerInputPort», D6; ADR-0009 D5 convention).
## The production adapter wraps `InputRouter` (`top()`, `get_move_vector()`, `consume_look_delta()`); unit tests use a fake.
## Example: `class Fake extends PlayerInputPort: func look_delta_deg() -> Vector2: return Vector2(5, 0) ...`.
@abstract
class_name PlayerInputPort extends RefCounted


## Active input context (`InputRouter.top()`).
@abstract func context() -> InputTypes.Context


## Move vector, x = right, y = forward (`InputRouter.get_move_vector()`).
@abstract func move_vector() -> Vector2


## Look delta accumulated since the last call, in DEGREES (`InputRouter.consume_look_delta()`; ADR-0006).
## Convention (closes ADR-0012 OI-3, see `Look`): x = yaw with +x = turn right, y = pitch with +y = look up,
## inversion and sensitivity already applied by Input. Zero outside EXPLORACION.
@abstract func look_delta_deg() -> Vector2
