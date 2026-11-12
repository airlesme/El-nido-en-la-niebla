## Production occlusion probe (ADR-0011 D4): one `intersect_ray` from the eye to the contact point with
## `collision_mask` = geometry bit only (never bits 2-5, FE-R01) and the contact's `excluded_rids`.
## `hit_from_inside` stays false: a ray born inside a solid returns no hit (FE-R02).
## Example: `PhysicsOcclusionProbe.new(get_world_3d(), config_mascara_geometria)`.
class_name PhysicsOcclusionProbe extends OcclusionProbe

var _world: World3D
var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()


## `mask` must be `InteractionTypes.OCCLUSION_MASK` (validated at config load; asserted here).
func _init(world: World3D, mask: int = InteractionTypes.OCCLUSION_MASK) -> void:
	assert(mask == InteractionTypes.OCCLUSION_MASK, "occlusion mask must be bit 1 only")
	_world = world
	_query.collision_mask = mask
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	_query.hit_from_inside = false


func hit_depth(eye: Vector3, u: Vector3, c: InteractionTypes.ContactInfo) -> float:
	_query.from = eye
	_query.to = c.contact_point
	_query.exclude = c.excluded_rids
	var hit: Dictionary = _world.direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		return NO_HIT
	return ((hit["position"] as Vector3) - eye).dot(u)
