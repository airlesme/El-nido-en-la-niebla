## Production adapter of `PenetrationProbe` (ADR-0012 D8, TR-player-019): one `intersect_shape()` with a pre-built
## capsule shrunk by `eps_atasco_m` (radius `r - eps`, height `h - 2 * eps`), static world layer only, the body excluded
## and an explicit `max_results` of 1 (S-0011-A: the default of 32 is applied silently). Never the engine penetration report (C-X14).
## TODO(ADR-0012): the ADR names the probe's role, not this class or its constructor (owner: lead-programmer).
## Real behaviour against geometry is verified by story 012.
class_name ShrunkCapsuleProbe extends PenetrationProbe

## Physics layer mask of `world_geometry` (ADR-0011: layer 1).
const WORLD_GEOMETRY_MASK: int = 1
## Explicit result cap of the query (only "any hit" matters).
const MAX_RESULTS: int = 1

var _body: CharacterBody3D
var _query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()


func _init(body: CharacterBody3D, cfg: PlayerConfig) -> void:
	_body = body
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = maxf(cfg.radio_capsula - cfg.eps_atasco_m, 0.001)
	shape.height = maxf(cfg.altura_capsula - 2.0 * cfg.eps_atasco_m, 2.0 * shape.radius)
	_query.shape = shape
	_query.collision_mask = WORLD_GEOMETRY_MASK
	_query.collide_with_areas = false
	_query.collide_with_bodies = true


## True when the shrunk capsule centred at `capsule_center` overlaps static geometry. False when the body left the tree.
func is_penetrating(capsule_center: Vector3) -> bool:
	if not is_instance_valid(_body) or not _body.is_inside_tree():
		return false
	var world: World3D = _body.get_world_3d()
	if world == null:
		return false
	_query.transform = Transform3D(Basis.IDENTITY, capsule_center)
	_query.exclude = [_body.get_rid()]
	return not world.direct_space_state.intersect_shape(_query, MAX_RESULTS).is_empty()
