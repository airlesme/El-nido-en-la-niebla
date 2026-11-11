extends GdUnitTestSuite
## IP-002: PickMath (F1 steps 1-5) and PickRegistry (ADR-0011 D2/D3). No physics world: the picks are plain
## nodes in the suite and every contact comes from arithmetic (G-1).
## Covers AC-01 (unknown/duplicate id), AC-02 (phone reach), AC-07b (eye ray, not camera) and exactness
## against an independent brute-force oracle with a fixed seed (as the 2026-11-11 spike).

const ITEMS_FULL: String = "res://assets/data/interaction/interactables.json"
const CONFIG_FULL: String = "res://assets/data/interaction/interaction_config.json"
const PHONE_SIZE: Vector3 = Vector3(0.15, 0.08, 0.02)
const RADIUS: float = 0.06
const REACH: float = 1.8
const ORACLE_SEED: int = 20261111
const ORACLE_RAYS: int = 400
const TOL: float = 0.001


## Eye ray double: origin and direction set by the test.
class FakeEye extends EyeRaySource:
	var origin: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3(0.0, 0.0, -1.0)

	func eye_origin() -> Vector3:
		return origin

	func eye_direction() -> Vector3:
		return dir


func _catalog() -> InteractionCatalog:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text(ITEMS_FULL, FileAccess.get_file_as_string(ITEMS_FULL))
	store.put_text(CONFIG_FULL, FileAccess.get_file_as_string(CONFIG_FULL))
	return InteractionCatalog.load_from(DataReader.new(store, BuildFlavor.new(true)))


func _pick(id: StringName, size: Vector3, pos: Vector3, basis: Basis = Basis.IDENTITY) -> InteractablePick:
	var pick: InteractablePick = auto_free(InteractablePick.new())
	pick.interactable_id = id
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	pick.add_child(cs)
	pick.transform = Transform3D(basis, pos)
	add_child(pick)
	return pick


func _picks(list: Array[InteractablePick]) -> Array[InteractablePick]:
	return list


func _eye(origin: Vector3, dir: Vector3) -> FakeEye:
	var e: FakeEye = FakeEye.new()
	e.origin = origin
	e.dir = dir
	return e


## Phone whose front face (towards +z) is `depth` metres in front of the origin along -z.
func _phone_at(depth: float) -> PickRegistry:
	var pick: InteractablePick = _pick(&"V02", PHONE_SIZE, Vector3(0.0, 0.0, -(depth + PHONE_SIZE.z * 0.5)))
	return PickRegistry.build(_picks([pick]), _catalog())


func _collect(reg: PickRegistry, eye: EyeRaySource) -> int:
	return reg.collect(eye, RADIUS, reg.make_pool())


# --- AC-02 -------------------------------------------------------------------------------------------

func test_phone_at_1_38_m_with_reach_1_8_is_contact() -> void:
	var reg: PickRegistry = _phone_at(1.38)
	var pool: Array[InteractionTypes.ContactInfo] = reg.make_pool()

	var n: int = reg.collect(_eye(Vector3.ZERO, Vector3(0, 0, -1)), RADIUS, pool)

	assert_int(n).is_equal(1)
	assert_float(pool[0].d_c).is_equal_approx(1.38, TOL)
	assert_bool(pool[0].contains_axis).is_true()
	assert_float(pool[0].delta).is_equal(0.0)


func test_phone_at_1_9_m_is_not_contact() -> void:
	var reg: PickRegistry = _phone_at(1.9)

	assert_int(_collect(reg, _eye(Vector3.ZERO, Vector3(0, 0, -1)))).is_equal(0)


func test_phone_reach_boundary_1_79_in_1_81_out() -> void:
	assert_int(_collect(_phone_at(1.79), _eye(Vector3.ZERO, Vector3(0, 0, -1)))).is_equal(1)
	assert_int(_collect(_phone_at(1.81), _eye(Vector3.ZERO, Vector3(0, 0, -1)))).is_equal(0)


# --- AC-01 -------------------------------------------------------------------------------------------

func test_unknown_id_is_data_error_and_not_registered() -> void:
	var pick: InteractablePick = _pick(&"NO_EXISTE", PHONE_SIZE, Vector3(0, 0, -1))

	var reg: PickRegistry = PickRegistry.build(_picks([pick]), _catalog())

	assert_bool(reg.has_errors()).is_true()
	assert_str(String(reg.issues[0].rule)).is_equal("unknown_id")
	assert_int(reg.size()).is_equal(0)
	assert_int(_collect(reg, _eye(Vector3.ZERO, Vector3(0, 0, -1)))).is_equal(0)


func test_duplicate_id_is_data_error_keeping_first() -> void:
	var a: InteractablePick = _pick(&"V02", PHONE_SIZE, Vector3(0, 0, -1))
	var b: InteractablePick = _pick(&"V02", PHONE_SIZE, Vector3(1, 0, -1))

	var reg: PickRegistry = PickRegistry.build(_picks([a, b]), _catalog())

	assert_str(String(reg.issues[0].rule)).is_equal("duplicate_id")
	assert_int(reg.size()).is_equal(1)


func test_empty_id_is_data_error() -> void:
	var pick: InteractablePick = _pick(&"", PHONE_SIZE, Vector3(0, 0, -1))

	assert_bool(PickRegistry.build(_picks([pick]), _catalog()).has_errors()).is_true()


func test_non_box_scaled_or_wrong_layer_picks_are_rejected() -> void:
	var sphere: InteractablePick = _pick(&"V02", PHONE_SIZE, Vector3(0, 0, -1))
	(sphere.shape_node()).shape = SphereShape3D.new()
	var scaled: InteractablePick = _pick(&"V03", PHONE_SIZE, Vector3(0, 0, -1), Basis.from_scale(Vector3(2, 1, 1)))
	var layered: InteractablePick = _pick(&"V04", PHONE_SIZE, Vector3(0, 0, -1))
	layered.collision_layer = 1

	var reg: PickRegistry = PickRegistry.build(_picks([sphere, scaled, layered]), _catalog())

	assert_int(reg.size()).is_equal(0)
	var rules: PackedStringArray = PackedStringArray()
	for i: DataIssue in reg.issues:
		rules.append(String(i.rule))
	assert_array(rules).contains_exactly(["pick_shape", "pick_scale", "pick_layer"])


func test_pick_has_layer_bit_3_and_group() -> void:
	var pick: InteractablePick = _pick(&"V02", PHONE_SIZE, Vector3.ZERO)

	assert_int(pick.collision_layer).is_equal(InteractionTypes.LAYER_INTERACTABLE)
	assert_bool(pick.is_in_group(&"interactable_pick")).is_true()


# --- AC-07b ------------------------------------------------------------------------------------------

func test_origin_is_the_eye_ray_not_the_camera() -> void:
	var reg: PickRegistry = _phone_at(1.0)
	var eyes: FakeEye = _eye(Vector3(0.0, 0.0, 0.0), Vector3(0, 0, -1))
	# Camera with full head bob: displaced 0.4 m to the side. Never read by the registry.
	var camera: FakeEye = _eye(Vector3(0.4, 0.0, 0.0), Vector3(0, 0, -1))
	var pool: Array[InteractionTypes.ContactInfo] = reg.make_pool()

	assert_int(reg.collect(eyes, RADIUS, pool)).is_equal(1)
	assert_float(pool[0].d_c).is_equal_approx(1.0, TOL)
	assert_int(reg.collect(camera, RADIUS, pool)).is_equal(0)


func test_zero_direction_gives_no_contacts() -> void:
	assert_int(_collect(_phone_at(1.0), _eye(Vector3.ZERO, Vector3.ZERO))).is_equal(0)


# --- determinism and order ---------------------------------------------------------------------------

func test_contacts_come_out_in_id_order_whatever_the_insertion_order() -> void:
	var b: InteractablePick = _pick(&"V03", Vector3(0.2, 0.2, 0.2), Vector3(0, 0, -1.5))
	var a: InteractablePick = _pick(&"V02", Vector3(0.2, 0.2, 0.2), Vector3(0, 0, -1.0))
	var reg: PickRegistry = PickRegistry.build(_picks([b, a]), _catalog())
	var pool: Array[InteractionTypes.ContactInfo] = reg.make_pool()

	var n: int = reg.collect(_eye(Vector3.ZERO, Vector3(0, 0, -1)), RADIUS, pool)

	assert_int(n).is_equal(2)
	assert_str(String(reg.entry_at(pool[0].entry).id)).is_equal("V02")
	assert_str(String(reg.entry_at(pool[1].entry).id)).is_equal("V03")
	assert_float(pool[0].d_c).is_equal_approx(0.9, TOL)
	assert_float(pool[1].d_c).is_equal_approx(1.4, TOL)


func test_collect_is_repeatable_with_a_reused_pool() -> void:
	var reg: PickRegistry = _phone_at(1.2)
	var pool: Array[InteractionTypes.ContactInfo] = reg.make_pool()
	var eye: FakeEye = _eye(Vector3.ZERO, Vector3(0, 0, -1))

	var n1: int = reg.collect(eye, RADIUS, pool)
	var d1: float = pool[0].d_c
	var n2: int = reg.collect(eye, RADIUS, pool)

	assert_int(n2).is_equal(n1)
	assert_float(pool[0].d_c).is_equal(d1)


# --- PickMath exactness ------------------------------------------------------------------------------

func test_off_axis_box_gives_delta_to_nearest_face() -> void:
	# Axis along -z; phone centred 0.1 m to the right: its near edge is at x = 0.025 -> delta 0.025.
	var xf: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.1, 0.0, -1.0))
	var out: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()

	var hit: bool = PickMath.measure(Vector3.ZERO, Vector3(0, 0, -1), xf, PHONE_SIZE * 0.5, RADIUS, REACH, out)

	assert_bool(hit).is_true()
	assert_bool(out.contains_axis).is_false()
	assert_float(out.delta).is_equal_approx(0.025, TOL)
	# Flat plateau: any depth inside the box z-range (0.99..1.01) is a valid closest point.
	assert_float(out.d_c).is_between(0.99 - TOL, 1.01 + TOL)


func test_delta_just_above_radius_is_not_contact_and_just_below_is() -> void:
	var h: Vector3 = PHONE_SIZE * 0.5
	var out: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()
	var near: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.075 + RADIUS - 0.002, 0.0, -1.0))
	var far: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.075 + RADIUS + 0.002, 0.0, -1.0))

	assert_bool(PickMath.measure(Vector3.ZERO, Vector3(0, 0, -1), near, h, RADIUS, REACH, out)).is_true()
	assert_bool(PickMath.measure(Vector3.ZERO, Vector3(0, 0, -1), far, h, RADIUS, REACH, out)).is_false()


func test_box_behind_the_origin_is_not_contact() -> void:
	var xf: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 1.0))
	var out: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()

	assert_bool(PickMath.measure(Vector3.ZERO, Vector3(0, 0, -1), xf, PHONE_SIZE * 0.5, RADIUS, REACH, out)).is_false()


func test_origin_inside_box_is_contact_at_depth_zero() -> void:
	var xf: Transform3D = Transform3D(Basis.IDENTITY, Vector3.ZERO)
	var out: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()

	assert_bool(PickMath.measure(Vector3.ZERO, Vector3(0, 0, -1), xf, Vector3(0.5, 0.5, 0.5), RADIUS, REACH, out)).is_true()
	assert_float(out.d_c).is_equal(0.0)
	assert_bool(out.contains_axis).is_true()


func test_slab_parallel_ray_outside_slab_misses() -> void:
	assert_float(PickMath.slab_enter(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0.5, 0.5, 0.5), REACH)).is_equal(-1.0)


func test_prefilter_never_discards_a_real_contact() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = ORACLE_SEED
	var out: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()
	var h: Vector3 = Vector3(0.3, 0.2, 0.1)
	for i: int in ORACLE_RAYS:
		var xf: Transform3D = _random_box_xf(rng)
		var u: Vector3 = _random_dir(rng)
		if PickMath.measure(Vector3.ZERO, u, xf, h, RADIUS, REACH, out):
			assert_bool(PickMath.prefilter(Vector3.ZERO, u, REACH, xf.origin, h.length(), RADIUS)).is_true()


# --- seeded oracle (brute force, independent of PickMath) --------------------------------------------

func _random_box_xf(rng: RandomNumberGenerator) -> Transform3D:
	var axis: Vector3 = _random_dir(rng)
	var basis: Basis = Basis(axis, rng.randf_range(0.0, TAU))
	var pos: Vector3 = Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(-0.6, 0.6), rng.randf_range(-2.0, -0.2))
	return Transform3D(basis, pos)


func _random_dir(rng: RandomNumberGenerator) -> Vector3:
	var v: Vector3 = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	if v.length() < 0.1:
		return Vector3(0, 0, -1)
	return v.normalized()


func test_oracle_400_seeded_rays_match_brute_force() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = ORACLE_SEED
	var h: Vector3 = Vector3(0.3, 0.2, 0.1)
	var out: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()
	var samples: int = 4000
	var hits: int = 0
	var mismatches: int = 0
	for i: int in ORACLE_RAYS:
		var xf: Transform3D = _random_box_xf(rng)
		# Aim at the box with a random miss offset so both contacts and near misses are frequent.
		var target: Vector3 = xf.origin + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5), rng.randf_range(-0.3, 0.3))
		var u: Vector3 = target.normalized()
		var inv: Transform3D = xf.affine_inverse()
		var lu: Vector3 = inv.basis * u
		var lo: Vector3 = inv * Vector3.ZERO
		# Reference: fine sampling of f(t) and of "inside the box".
		var best_delta: float = INF
		var first_inside: float = -1.0
		var best_depth: float = 0.0
		for s: int in samples + 1:
			var t: float = REACH * float(s) / float(samples)
			var p: Vector3 = lo + lu * t
			var d: float = (p - p.clamp(-h, h)).length()
			if d < best_delta:
				best_delta = d
				# Depth of the closest box point along the ray (D3 step 5 input).
				best_depth = ((xf * p.clamp(-h, h)) - Vector3.ZERO).dot(u)
			if d == 0.0 and first_inside < 0.0:
				first_inside = t
		var step: float = REACH / float(samples)
		var got: bool = PickMath.measure(Vector3.ZERO, u, xf, h, RADIUS, REACH, out)
		if best_delta > RADIUS + 2.0 * step:
			if got:
				mismatches += 1
			continue
		if best_delta < RADIUS - 2.0 * step:
			if not got:
				# Legitimate only when the closest point lies outside [0, reach] (step 5).
				if first_inside >= 0.0 or (best_depth >= 0.0 and best_depth <= REACH):
					mismatches += 1
				continue
			hits += 1
			if first_inside >= 0.0:
				# A sample inside the box: the slab test must agree within one sample step.
				if not out.contains_axis or absf(out.d_c - first_inside) > step + TOL:
					mismatches += 1
			elif absf(out.delta - best_delta) > TOL:
				mismatches += 1
	assert_int(mismatches).is_equal(0)
	assert_int(hits).is_greater(40)
