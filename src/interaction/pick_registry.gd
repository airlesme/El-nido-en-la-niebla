## Dense per-scene registry of pick volumes, sorted by id once (ADR-0011 D2) and the F1 contact sweep over it
## (D3 steps 1-5). Rebuilt only on scene load. Unknown ids, duplicate ids and picks that break the box rules
## (FE-R04: one unscaled `BoxShape3D`, layer = bit 3 only) are data errors reported in `issues`; an erroneous
## pick is not registered.
## TODO(IP-003): excluded RIDs (`self_occluders`) are resolved by the occlusion story.
## TODO(IP-004): cached `habilitado_si` fact indices (`GameState.resolve_fact`) arrive with the selector.
## Example: `var reg := PickRegistry.build(picks, catalog); var n := reg.collect(eye, 0.06, reg.make_pool())`.
class_name PickRegistry extends RefCounted

## Tolerance of the "unscaled box" lint.
const SCALE_EPSILON: float = 1e-3

## Registry row (D2). `shape` gives the live transform (drawers move).
class Entry extends RefCounted:
	var id: StringName = &""
	var prioridad: int = 0
	var alcance_c: float = 0.0
	var half_extents: Vector3 = Vector3.ZERO
	## `|half_extents|`, radius of the prefilter sphere.
	var bound: float = 0.0
	var shape: CollisionShape3D = null

## Data errors found building the registry.
var issues: Array[DataIssue] = []
var _entries: Array[Entry] = []
var _index_by_id: Dictionary[StringName, int] = {}


## Builds the registry from the scene's picks. Entries are sorted by id (deterministic order = last
## tie-break of F1). Picks must already be inside the tree (the live `global_transform` is read).
static func build(picks: Array[InteractablePick], catalog: InteractionCatalog) -> PickRegistry:
	var reg: PickRegistry = PickRegistry.new()
	var seen: Dictionary[StringName, bool] = {}
	for pick: InteractablePick in picks:
		var id: StringName = pick.interactable_id
		var where: String = String(pick.name)
		if not catalog.has(id):
			reg._error(where, &"unknown_id", "interactable_id '%s' is not in interactables.json" % id)
			continue
		if seen.has(id):
			reg._error(where, &"duplicate_id", "interactable_id '%s' appears more than once" % id)
			continue
		seen[id] = true
		var node: CollisionShape3D = pick.shape_node()
		if node == null or not (node.shape is BoxShape3D):
			reg._error(where, &"pick_shape", "'%s' needs a CollisionShape3D with a BoxShape3D" % id)
			continue
		if pick.collision_layer != InteractionTypes.LAYER_INTERACTABLE:
			reg._error(where, &"pick_layer", "'%s' must be on physics layer bit 3 only" % id)
			continue
		var s: Vector3 = node.global_transform.basis.get_scale()
		if absf(s.x - 1.0) > SCALE_EPSILON or absf(s.y - 1.0) > SCALE_EPSILON or absf(s.z - 1.0) > SCALE_EPSILON:
			reg._error(where, &"pick_scale", "'%s' box must not be scaled (scale %s)" % [id, s])
			continue
		var e: Entry = Entry.new()
		e.id = id
		e.prioridad = int(catalog.entry(id).get("prioridad", 0))
		e.alcance_c = catalog.alcance_m(id)
		e.half_extents = (node.shape as BoxShape3D).size * 0.5
		e.bound = e.half_extents.length()
		e.shape = node
		reg._entries.append(e)
	reg._entries.sort_custom(func(a: Entry, b: Entry) -> bool: return String(a.id) < String(b.id))
	for i: int in reg._entries.size():
		reg._index_by_id[reg._entries[i].id] = i
	return reg


## True when building found at least one error.
func has_errors() -> bool:
	return not issues.is_empty()


## Number of registered picks.
func size() -> int:
	return _entries.size()


## Row `index` (0 <= index < `size()`), ordered by id.
func entry_at(index: int) -> Entry:
	return _entries[index]


## Index of `id`, or -1.
func index_of(id: StringName) -> int:
	return _index_by_id.get(id, -1)


## Pre-sized pool of contacts for `collect` (create once per scene, reuse every step).
func make_pool() -> Array[InteractionTypes.ContactInfo]:
	var pool: Array[InteractionTypes.ContactInfo] = []
	pool.resize(_entries.size())
	for i: int in pool.size():
		pool[i] = InteractionTypes.ContactInfo.new()
	return pool


## F1 steps 1-5 for the current eye ray: fills `pool[0..n)` with the contacts, in id order, and returns
## `n`. The ray comes only from `eye` (physics eyes, never the camera: AC-07b). `radius` is
## `radio_apuntado_m`. `pool` must hold at least `size()` items (see `make_pool`). No allocation.
func collect(eye: EyeRaySource, radius: float, pool: Array[InteractionTypes.ContactInfo]) -> int:
	assert(pool.size() >= _entries.size(), "pool smaller than the registry")
	var dir: Vector3 = eye.eye_direction()
	if dir.is_zero_approx():
		return 0
	var u: Vector3 = dir.normalized()
	var o: Vector3 = eye.eye_origin()
	var n: int = 0
	for i: int in _entries.size():
		var e: Entry = _entries[i]
		var xf: Transform3D = e.shape.global_transform
		if not PickMath.prefilter(o, u, e.alcance_c, xf.origin, e.bound, radius):
			continue
		var out: InteractionTypes.ContactInfo = pool[n]
		if PickMath.measure(o, u, xf, e.half_extents, radius, e.alcance_c, out):
			out.entry = i
			n += 1
	return n


func _error(path: String, rule: StringName, msg: String) -> void:
	issues.append(DataIssue.new(DataIssue.Severity.ERROR, "scene", path, rule, msg))
