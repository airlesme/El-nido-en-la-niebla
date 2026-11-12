## Ray of the player's sight (ADR-0012 § Key Interfaces «VisionRay», D10). Value type, no logic.
## `origen` = physics eyes (no bob, no interpolation); `direccion` = current camera forward, normalised.
## Also the audio listener source (ADR-0012 Open Item C1).
## Example: `var r: VisionRay = player.rayo_vision(); space.intersect_ray(r.origen, r.origen + r.direccion * 3.0)`.
class_name VisionRay extends RefCounted

## Ray origin, metres, world space.
var origen: Vector3 = Vector3.ZERO
## Normalised direction, world space.
var direccion: Vector3 = Vector3.FORWARD
