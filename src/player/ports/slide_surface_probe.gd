## Production adapter of `SurfaceProbe`: reads the `surface` metadata of the floor collider hit by the last
## `move_and_slide()` (ADR-0012 D10, S-0012-C NP-8, C-R24). `&"default"` when there is no floor or no label.
## Example: `var probe: SurfaceProbe = SlideSurfaceProbe.new(player)`.
class_name SlideSurfaceProbe extends SurfaceProbe

const META_KEY: StringName = &"surface"

var _body: CharacterBody3D


func _init(body: CharacterBody3D) -> void:
	_body = body


## Label of the floor under the body, or `SurfaceProbe.DEFAULT_SURFACE`.
func floor_surface() -> StringName:
	if not is_instance_valid(_body):
		return DEFAULT_SURFACE
	for i: int in _body.get_slide_collision_count():
		var hit: KinematicCollision3D = _body.get_slide_collision(i)
		if hit.get_normal().dot(Vector3.UP) < 0.7:
			continue
		var collider: Object = hit.get_collider()
		if collider != null and collider.has_meta(META_KEY):
			return StringName(str(collider.get_meta(META_KEY)))
	return DEFAULT_SURFACE
