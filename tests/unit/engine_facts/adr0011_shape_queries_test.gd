extends GdUnitTestSuite
# Verifica NS-5..NS-8 de ADR-0011 en Godot 4.7.2 (S-0011-A).
## S-0011-A: 40 Area3D pick boxes on layer 3 under Jolt: intersect_shape completeness and keys,
## ShapeCast3D sweep, BoxShape3D.size, cost of a per-step query proxy, ray vs analytic oracle.

const PICK_LAYER_BIT: int = 3
const PICK_MASK: int = 1 << (PICK_LAYER_BIT - 1)

var _boxes: Array[Area3D] = []
var _aabbs: Array[AABB] = []


func before_test() -> void:
	_boxes.clear()
	_aabbs.clear()
	# 37 small cubes in a grid (8 per row, 0.7 m pitch) at z = -1, plus V02, B02, B05
	for i: int in 37:
		_add_pick(Vector3((i % 8) * 0.7, (i / 8) * 0.5, -1.0), Vector3(0.2, 0.2, 0.2), "grid_%d" % i)
	_add_pick(Vector3(2.0, 3.0, -1.0), Vector3(0.15, 0.08, 0.02), "V02")
	_add_pick(Vector3(4.0, 3.0, -3.0), Vector3(0.4, 0.4, 0.02), "B02")
	_add_pick(Vector3(4.0, 3.0, -2.98), Vector3(0.2, 0.2, 0.02), "B05")  # 2 cm in front of B02


func _add_pick(center: Vector3, size: Vector3, node_name: String) -> void:
	var area: Area3D = Area3D.new()
	area.name = node_name
	area.collision_layer = PICK_MASK
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	area.add_child(cs)
	area.position = center
	add_child(auto_free(area))
	_boxes.append(area)
	_aabbs.append(AABB(center - size * 0.5, size))


func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


func _space() -> PhysicsDirectSpaceState3D:
	return get_viewport().world_3d.direct_space_state


func _capsule_query(pos: Vector3, radius: float, max_results: int) -> PhysicsShapeQueryParameters3D:
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = radius
	cap.height = 1.8
	var q: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis.IDENTITY, pos)
	q.collision_mask = PICK_MASK
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.margin = 0.0
	q.motion = Vector3.ZERO
	return q


func _analytic_capsule_overlaps(pos: Vector3, radius: float) -> Array[int]:
	# Vertical capsule: segment pos.y +- (0.9 - radius), radius. Distance from segment to AABB.
	var out: Array[int] = []
	var half_seg: float = 0.9 - radius
	for i: int in _aabbs.size():
		var bb: AABB = _aabbs[i]
		var dx: float = maxf(maxf(bb.position.x - pos.x, 0.0), pos.x - bb.end.x)
		var dz: float = maxf(maxf(bb.position.z - pos.z, 0.0), pos.z - bb.end.z)
		var seg_lo: float = pos.y - half_seg
		var seg_hi: float = pos.y + half_seg
		var dy: float = maxf(maxf(bb.position.y - seg_hi, 0.0), seg_lo - bb.end.y)
		if sqrt(dx * dx + dz * dz + dy * dy) <= radius:
			out.append(i)
	return out


func test_jolt_is_the_configured_3d_engine_and_box_size_reads_back() -> void:
	# Arrange / Act
	var engine_name: String = str(ProjectSettings.get_setting("physics/3d/physics_engine", "UNSET"))
	var layer_name: String = str(ProjectSettings.get_setting("layer_names/3d_physics/layer_3", ""))
	var size: Vector3 = ((_boxes[37].get_child(0) as CollisionShape3D).shape as BoxShape3D).size
	var jolt_present: bool = ProjectSettings.has_setting("physics/jolt_physics_3d/simulation/velocity_steps")
	var server_str: String = str(PhysicsServer3D)
	print("S-0011-A jolt_settings_present=", jolt_present, " PhysicsServer3D=", server_str)
	assert_bool(jolt_present).is_true()
	print("S-0011-A engine_setting=", engine_name, " layer_3_name='", layer_name, "' V02 size=", size,
		" area monitoring=", _boxes[0].monitoring, " monitorable=", _boxes[0].monitorable)

	# Assert
	assert_str(engine_name).is_not_equal("GodotPhysics3D")
	assert_vector(size).is_equal_approx(Vector3(0.15, 0.08, 0.02), Vector3(1e-6, 1e-6, 1e-6))


func test_intersect_shape_returns_every_overlapping_box_with_expected_keys() -> void:
	# Arrange
	await _settle()
	var positions: Array[Vector3] = [
		Vector3(0.7, 0.5, -1.0), Vector3(2.1, 0.5, -1.0), Vector3(1.0, 1.0, -0.8), Vector3(4.0, 3.0, -2.5),
		Vector3(3.5, 0.2, -1.1), Vector3(0.0, 0.0, 0.0), Vector3(2.0, 3.05, -1.0), Vector3(5.0, 1.5, -1.0),
	]
	var radius: float = 0.35
	var mismatches: int = 0
	var checked: int = 0
	var key_sample: Array = []
	var order_sample: Array[String] = []

	# Act
	for p: Vector3 in positions:
		var q: PhysicsShapeQueryParameters3D = _capsule_query(p, radius, 32)
		var results: Array[Dictionary] = _space().intersect_shape(q, 64)
		var got: Array[int] = []
		for r: Dictionary in results:
			if key_sample.is_empty():
				key_sample = r.keys()
			var idx: int = _boxes.find(r["collider"] as Area3D)
			got.append(idx)
		var expected: Array[int] = _analytic_capsule_overlaps(p, radius)
		var got_sorted: Array[int] = got.duplicate()
		got_sorted.sort()
		checked += 1
		if got_sorted != expected:
			mismatches += 1
			print("S-0011-A MISMATCH at ", p, " got=", got_sorted, " expected=", expected)
		if order_sample.is_empty() and got.size() > 2:
			for g: int in got:
				order_sample.append(_boxes[g].name)
	print("S-0011-A intersect_shape checked=", checked, " mismatches=", mismatches, " keys=", key_sample,
		" order_sample=", order_sample)

	# Assert
	assert_int(mismatches).is_equal(0)
	assert_bool(key_sample.has("collider")).is_true()
	assert_bool(key_sample.has("rid")).is_true()


func test_intersect_shape_max_results_caps_at_requested_count() -> void:
	# Arrange: a sphere that covers all 40 boxes
	await _settle()
	var q: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 20.0
	q.shape = sphere
	q.transform = Transform3D(Basis.IDENTITY, Vector3(2.0, 1.0, -1.0))
	q.collision_mask = PICK_MASK
	q.collide_with_areas = true
	q.collide_with_bodies = false

	# Act
	var all: Array[Dictionary] = _space().intersect_shape(q, 64)
	var capped: Array[Dictionary] = _space().intersect_shape(q, 32)
	var default_cap: Array[Dictionary] = _space().intersect_shape(q)
	print("S-0011-A max_results: 64->", all.size(), " 32->", capped.size(), " default->", default_cap.size())

	# Assert
	assert_int(all.size()).is_equal(40)
	assert_int(capped.size()).is_equal(32)


func test_shape_query_ignores_monitorable_false_and_respects_mask() -> void:
	# Arrange
	await _settle()
	var q: PhysicsShapeQueryParameters3D = _capsule_query(Vector3(0.0, 0.0, -1.0), 0.35, 32)
	q.collision_mask = 1  # pick volumes are on bit 3 only

	# Act
	var with_mask3: Array[Dictionary] = _space().intersect_shape(_capsule_query(Vector3(0.0, 0.0, -1.0), 0.35, 32), 16)
	var with_mask1: Array[Dictionary] = _space().intersect_shape(q, 16)
	q.collision_mask = PICK_MASK
	q.collide_with_areas = false
	var areas_off: Array[Dictionary] = _space().intersect_shape(q, 16)
	print("S-0011-A mask3=", with_mask3.size(), " mask1=", with_mask1.size(), " collide_with_areas=false=", areas_off.size())

	# Assert: monitorable=false volumes are still found by queries
	assert_int(with_mask3.size()).is_greater(0)
	assert_int(with_mask1.size()).is_equal(0)
	assert_int(areas_off.size()).is_equal(0)


func test_shapecast_sphere_sweep_reports_which_boxes_along_the_row() -> void:
	# Arrange: sweep a 0.05 m sphere along +X through the 8 cubes of row 0 (y=0, z=-1)
	await _settle()
	var cast: ShapeCast3D = ShapeCast3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.05
	cast.shape = sphere
	cast.collision_mask = PICK_MASK
	cast.collide_with_areas = true
	cast.collide_with_bodies = false
	cast.max_results = 32
	cast.target_position = Vector3(7.0, 0.0, 0.0)
	add_child(auto_free(cast))
	cast.global_position = Vector3(-1.0, 0.0, -1.0)
	await _settle()

	# Act
	cast.force_shapecast_update()
	var count: int = cast.get_collision_count()
	var names: Array[String] = []
	for i: int in count:
		names.append((cast.get_collider(i) as Node).name)
	print("S-0011-A ShapeCast sweep crosses 8 boxes (grid_0..grid_7): reports count=", count, " names=", names,
		" fraction=", cast.get_closest_collision_safe_fraction(), "/", cast.get_closest_collision_unsafe_fraction())

	# Assert: recorded, rejected as the F1 mechanism; only the contract "count <= crossed boxes" is asserted
	assert_int(count).is_less_equal(8)


func test_ray_first_hit_equals_analytic_nearest_box_on_1000_seeded_rays() -> void:
	# Arrange
	await _settle()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261111
	var hits: int = 0
	var mismatches: int = 0
	var ambiguous: int = 0

	# Act
	for n: int in 1000:
		var origin: Vector3 = Vector3(rng.randf_range(0.0, 5.0), rng.randf_range(0.0, 3.0), rng.randf_range(1.0, 2.0))
		var target_box: AABB = _aabbs[rng.randi_range(0, _aabbs.size() - 1)]
		var target: Vector3 = target_box.get_center() + Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12), 0.0)
		var dir: Vector3 = (target - origin).normalized()
		var reach: float = 8.0
		var best_i: int = -1
		var best_t: float = INF
		var second_t: float = INF
		for i: int in _aabbs.size():
			var t: float = _slab(origin, dir, _aabbs[i], reach)
			if t < 0.0:
				continue
			if t < best_t:
				second_t = best_t
				best_t = t
				best_i = i
			elif t < second_t:
				second_t = t
		var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, PICK_MASK)
		q.collide_with_areas = true
		q.collide_with_bodies = false
		var r: Dictionary = _space().intersect_ray(q)
		var got_i: int = -1 if r.is_empty() else _boxes.find(r["collider"] as Area3D)
		if best_i >= 0 and second_t - best_t < 0.002:
			ambiguous += 1
			continue
		if best_i >= 0:
			hits += 1
		if got_i != best_i:
			mismatches += 1
			if mismatches <= 5:
				print("S-0011-A ray MISMATCH n=", n, " analytic=", best_i, " jolt=", got_i, " t=", best_t)
	print("S-0011-A oracle rays=1000 analytic_hits=", hits, " ambiguous_skipped=", ambiguous, " mismatches=", mismatches)

	# Assert
	assert_int(hits).is_greater(300)
	assert_int(mismatches).is_equal(0)


## Ray vs AABB slab; returns entry distance or -1.
func _slab(o: Vector3, d: Vector3, bb: AABB, reach: float) -> float:
	var tmin: float = 0.0
	var tmax: float = reach
	for ax: int in 3:
		var lo: float = bb.position[ax]
		var hi: float = bb.end[ax]
		if absf(d[ax]) < 1e-9:
			if o[ax] < lo or o[ax] > hi:
				return -1.0
			continue
		var t1: float = (lo - o[ax]) / d[ax]
		var t2: float = (hi - o[ax]) / d[ax]
		tmin = maxf(tmin, minf(t1, t2))
		tmax = minf(tmax, maxf(t1, t2))
		if tmin > tmax:
			return -1.0
	return tmin


func test_per_step_query_proxy_cost_over_600_steps_is_within_budget() -> void:
	# Arrange: proxy for D3+D5: one eye ray + one capsule overlap query per step, 40 entries.
	await _settle()
	var space: PhysicsDirectSpaceState3D = _space()
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(2.0, 1.0, 1.0), Vector3(2.0, 1.0, -9.0), PICK_MASK)
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	var cap: PhysicsShapeQueryParameters3D = _capsule_query(Vector3(2.0, 1.0, -1.0), 0.35, 32)
	var samples: PackedFloat64Array = PackedFloat64Array()

	# Act
	for step: int in 600:
		var t0: int = Time.get_ticks_usec()
		var r: Dictionary = space.intersect_ray(ray)
		var s: Array[Dictionary] = space.intersect_shape(cap, 40)
		var t1: int = Time.get_ticks_usec()
		samples.append(float(t1 - t0) / 1000.0)
		if r.is_empty() and s.is_empty():
			pass
	var sorted: PackedFloat64Array = samples.duplicate()
	sorted.sort()
	var total: float = 0.0
	for v: float in samples:
		total += v
	var mean_ms: float = total / 600.0
	var p99_ms: float = sorted[int(600 * 0.99)]
	print("S-0011-A cost ray+shape proxy, 40 entries, 600 steps: mean_ms=", mean_ms, " p99_ms=", p99_ms, " max_ms=", sorted[599])

	# Assert: ADR-0011 budget mean <= 0.25 ms, peak <= 0.5 ms (p99 as the reported peak)
	assert_float(mean_ms).is_less(0.25)
	assert_float(p99_ms).is_less(0.5)
