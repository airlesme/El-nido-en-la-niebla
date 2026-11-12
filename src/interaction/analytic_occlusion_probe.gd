## Test double of the occlusion probe (ADR-0011 D9): axis-aligned solid boxes, first entry along the segment.
## Mirrors the measured engine behaviour: a segment that starts inside a box does not hit it, and boxes whose
## RID is in the contact's `excluded_rids` are skipped.
## Example: `probe.add_box(AABB(Vector3(-2, -2, -1.1), Vector3(4, 4, 0.1)))` is a wall at z = -1.0.
class_name AnalyticOcclusionProbe extends OcclusionProbe

var _boxes: Array[AABB] = []
var _rids: Array[RID] = []


## Adds a solid box; `rid` (optional) lets a contact exclude it.
func add_box(box: AABB, rid: RID = RID()) -> void:
	_boxes.append(box)
	_rids.append(rid)


func hit_depth(eye: Vector3, u: Vector3, c: InteractionTypes.ContactInfo) -> float:
	var best: float = NO_HIT
	for i: int in _boxes.size():
		if _rids[i].is_valid() and c.excluded_rids.has(_rids[i]):
			continue
		var box: AABB = _boxes[i]
		if box.has_point(eye):
			continue
		var p: Variant = box.intersects_segment(eye, c.contact_point)
		if p == null:
			continue
		var d: float = ((p as Vector3) - eye).dot(u)
		if best == NO_HIT or d < best:
			best = d
	return best
