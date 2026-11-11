## Port that gives the interaction system the eye ray (ADR-0011 D3/D9; GDD 7 rule 5, TR-interact-002).
## The production adapter wraps `Player.rayo_vision()` (physics eyes: no head bob, no interpolation), so
## the origin is never the camera. Unit tests use a double.
## Two scalar getters instead of an `Array` return: no allocation per physics step (FE-R10).
## TODO(ADR-0012 OI-4): the adapter lands with the Player story; `rayo_vision()` return type is still open.
## Example: `class Fixed extends EyeRaySource: func eye_origin() -> Vector3: return Vector3.ZERO ...`.
@abstract
class_name EyeRaySource extends RefCounted


## World-space origin of the eye ray (physics eyes, no balanceo).
@abstract func eye_origin() -> Vector3


## World-space direction of the eye ray (the registry normalises it).
@abstract func eye_direction() -> Vector3
