## Pure F1 contact arithmetic (ADR-0011 D3 steps 1-5; GDD 7 F1). No physics, no scene: testable headless.
## For the eye ray `o + t*u` and a box (local half extents `h`, transform `xf`): prefilter, slab test for
## axis containment, otherwise a fixed 24-iteration golden-section search of the distance to the axis.
## Example: `PickMath.measure(o, u, xf, Vector3(0.075, 0.04, 0.01), 0.06, 1.8, info)`.
class_name PickMath extends RefCounted

const GOLDEN_ITERATIONS: int = 24
const INV_PHI: float = 0.6180339887
## Direction components below this are parallel to the slab.
const PARALLEL_EPSILON: float = 1e-9


## D3 step 1: true when the box centre is within `bound + radius` of the segment `[o, o + u*reach]`
## (`bound` = |half extents|). A cheap conservative reject; never discards a real contact.
static func prefilter(o: Vector3, u: Vector3, reach: float, center: Vector3, bound: float, radius: float) -> bool:
	var to_c: Vector3 = center - o
	var t: float = clampf(to_c.dot(u), 0.0, reach)
	return (to_c - u * t).length() <= bound + radius


## D3 steps 2-5. Fills `out` and returns true if the box is a contact (delta <= radius, 0 <= d_c <= reach).
## `u` must be unit length; `out` is left untouched on false.
static func measure(o: Vector3, u: Vector3, xf: Transform3D, h: Vector3,
		radius: float, reach: float, out: InteractionTypes.ContactInfo) -> bool:
	var inv: Transform3D = xf.affine_inverse()
	var lo: Vector3 = inv * o
	var lu: Vector3 = inv.basis * u
	var t_enter: float = slab_enter(lo, lu, h, reach)
	if t_enter >= 0.0:
		out.contains_axis = true
		out.delta = 0.0
		out.d_c = t_enter
		out.contact_point = o + u * t_enter
		return true
	var a: float = 0.0
	var b: float = reach
	var c: float = b - (b - a) * INV_PHI
	var d: float = a + (b - a) * INV_PHI
	for i: int in GOLDEN_ITERATIONS:
		if _dist(lo + lu * c, h) < _dist(lo + lu * d, h):
			b = d
		else:
			a = c
		c = b - (b - a) * INV_PHI
		d = a + (b - a) * INV_PHI
	var t_star: float = (a + b) * 0.5
	var p: Vector3 = lo + lu * t_star
	var delta: float = _dist(p, h)
	if delta > radius:
		return false
	var q: Vector3 = xf * p.clamp(-h, h)
	var d_c: float = (q - o).dot(u)
	if d_c < 0.0 or d_c > reach:
		return false
	out.contains_axis = false
	out.delta = delta
	out.d_c = d_c
	out.contact_point = q
	return true


## Entry distance of the local ray `lo + t*lu` into the box `[-h, h]` on `t` in `[0, reach]`;
## `-1.0` when there is no hit. An origin inside the box returns 0.0.
static func slab_enter(lo: Vector3, lu: Vector3, h: Vector3, reach: float) -> float:
	var t0: float = 0.0
	var t1: float = reach
	for k: int in 3:
		if absf(lu[k]) < PARALLEL_EPSILON:
			if lo[k] < -h[k] or lo[k] > h[k]:
				return -1.0
			continue
		var ta: float = (-h[k] - lo[k]) / lu[k]
		var tb: float = (h[k] - lo[k]) / lu[k]
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
		if t0 > t1:
			return -1.0
	return t0


static func _dist(p: Vector3, h: Vector3) -> float:
	return (p - p.clamp(-h, h)).length()
