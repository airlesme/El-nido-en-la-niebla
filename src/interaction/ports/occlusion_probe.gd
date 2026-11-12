## Port for the occlusion ray of F1 (ADR-0011 D4/D9; TR-interact-004). The only physics query of the
## interaction system. `PhysicsOcclusionProbe` wraps `intersect_ray`; `AnalyticOcclusionProbe` is the
## test double. A ray that starts inside a solid does not hit (measured, S-0011-B): that contact is
## treated as not occluded by that ray (FE-R02; `hit_from_inside` is never enabled).
## Example: `if probe.is_occluded(eye, u, contact, config_tolerance): ...`.
@abstract
class_name OcclusionProbe extends RefCounted

## Returned by `hit_depth` when the segment meets no geometry.
const NO_HIT: float = -1.0

var _overflow_logged: bool = false


## Axis depth `(hit - eye) . u` of the first geometry hit on the segment `eye -> c.contact_point`
## (excluding `c.excluded_rids`), or `NO_HIT`.
@abstract func hit_depth(eye: Vector3, u: Vector3, c: InteractionTypes.ContactInfo) -> float


## D4: occluded when geometry is hit before the contact by more than `tolerance` (`desempate_prof_m`),
## so a support surface under a flat object (hit depth ~ `d_c`) does not occlude it.
func is_occluded(eye: Vector3, u: Vector3, c: InteractionTypes.ContactInfo, tolerance: float) -> bool:
	var d_g: float = hit_depth(eye, u, c)
	return d_g != NO_HIT and d_g < c.d_c - tolerance


## Keeps in `pool[0..n)` only the unoccluded contacts (stable order, swap-free compaction of the pool
## objects) and returns the new count. At most `max_contacts` are tested, in registry order; the rest
## are dropped and logged once per scene in debug builds (see `reset_scene`). `u` must be unit length.
func filter_visible(eye: Vector3, u: Vector3, pool: Array[InteractionTypes.ContactInfo], n: int,
		max_contacts: int, tolerance: float) -> int:
	var tested: int = mini(n, max_contacts)
	if n > tested and not _overflow_logged:
		_overflow_logged = true
		if OS.is_debug_build():
			push_warning("OcclusionProbe: %d contacts exceed max_contactos_por_paso (%d); extras ignored" % [n, max_contacts])
	var kept: int = 0
	for i: int in tested:
		var c: InteractionTypes.ContactInfo = pool[i]
		if is_occluded(eye, u, c, tolerance):
			continue
		if kept != i:
			pool[i] = pool[kept]
			pool[kept] = c
		kept += 1
	return kept


## Re-arms the once-per-scene overflow log.
func reset_scene() -> void:
	_overflow_logged = false


## True once the overflow warning fired for the current scene.
func overflow_was_logged() -> bool:
	return _overflow_logged
