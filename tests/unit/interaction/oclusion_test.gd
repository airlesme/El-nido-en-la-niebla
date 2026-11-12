extends GdUnitTestSuite
## IP-003: occlusion rule of F1 step 2 (ADR-0011 D4) against the analytic probe (no engine physics).

const TOL: float = 0.03
const EYE: Vector3 = Vector3.ZERO
const U: Vector3 = Vector3(0, 0, -1)


func _contact(d_c: float) -> InteractionTypes.ContactInfo:
	var c: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()
	c.d_c = d_c
	c.contact_point = EYE + U * d_c
	return c


func _wall(z_front: float) -> AABB:
	return AABB(Vector3(-2, -2, z_front - 0.1), Vector3(4, 4, 0.1))


func test_wall_between_eye_and_object_occludes() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(_wall(-1.0))
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_true()


func test_no_geometry_does_not_occlude() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_false()
	assert_float(probe.hit_depth(EYE, U, _contact(1.5))).is_equal(OcclusionProbe.NO_HIT)


func test_support_surface_cutting_segment_at_1499_does_not_occlude() -> void:
	# B05 flat at 1.50 m over a table whose top face is hit at 1.499 m.
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(_wall(-1.499))
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_false()


func test_tolerance_boundary_is_strict() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(_wall(-1.4))  # d_g = 1.4 -> 1.4 < 1.5 - 0.03 is true
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_true()
	var probe2: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe2.add_box(_wall(-1.47))  # d_g = 1.47 == 1.5 - 0.03 -> not less
	assert_bool(probe2.is_occluded(EYE, U, _contact(1.5), TOL)).is_false()


func test_segment_starting_inside_solid_is_not_occluded() -> void:
	# Measured engine behaviour (S-0011-B): a ray born inside a solid does not hit.
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2)))  # contains the eye
	assert_bool(probe.is_occluded(EYE, U, _contact(1.5), TOL)).is_false()


func test_excluded_rid_is_skipped() -> void:
	var rid: RID = PhysicsServer3D.body_create()
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(_wall(-1.0), rid)
	var c: InteractionTypes.ContactInfo = _contact(1.5)
	var blocked: bool = probe.is_occluded(EYE, U, c, TOL)
	c.excluded_rids = [rid]
	var skipped: bool = probe.is_occluded(EYE, U, c, TOL)
	PhysicsServer3D.free_rid(rid)
	assert_bool(blocked).is_true()
	assert_bool(skipped).is_false()


func test_nearest_of_several_boxes_is_used() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(_wall(-1.2))
	probe.add_box(_wall(-0.8))
	assert_float(probe.hit_depth(EYE, U, _contact(1.5))).is_equal_approx(0.8, 1e-5)


func test_filter_keeps_visible_contacts_in_order() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	probe.add_box(AABB(Vector3(0.5, -1, -1.1), Vector3(1.0, 2, 0.1)))  # wall crossed only by the segment to x=1
	var pool: Array[InteractionTypes.ContactInfo] = []
	var xs: Array[float] = [0.0, 1.0, -1.0]
	for x: float in xs:
		var c: InteractionTypes.ContactInfo = InteractionTypes.ContactInfo.new()
		c.d_c = 1.5
		c.entry = pool.size()
		c.contact_point = Vector3(x, 0, -1.5)
		pool.append(c)
	var kept: int = probe.filter_visible(EYE, U, pool, 3, 8, TOL)
	assert_int(kept).is_equal(2)
	assert_int(pool[0].entry).is_equal(0)
	assert_int(pool[1].entry).is_equal(2)


func test_filter_ignores_contacts_beyond_max_and_logs_once() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	var pool: Array[InteractionTypes.ContactInfo] = []
	for i: int in 3:
		pool.append(_contact(1.5))
	assert_int(probe.filter_visible(EYE, U, pool, 3, 2, TOL)).is_equal(2)
	assert_bool(probe.overflow_was_logged()).is_true()
	probe.reset_scene()
	assert_bool(probe.overflow_was_logged()).is_false()


func test_filter_with_zero_contacts_returns_zero() -> void:
	var probe: AnalyticOcclusionProbe = AnalyticOcclusionProbe.new()
	var pool: Array[InteractionTypes.ContactInfo] = []
	assert_int(probe.filter_visible(EYE, U, pool, 0, 8, TOL)).is_equal(0)
	assert_bool(probe.overflow_was_logged()).is_false()


func test_layer_names_and_occlusion_mask_constant() -> void:
	var expected: Array[String] = ["world_geometry", "player_body", "interactable", "zone_sensor", "zone_trigger"]
	for i: int in expected.size():
		var key: String = "layer_names/3d_physics/layer_%d" % (i + 1)
		assert_str(str(ProjectSettings.get_setting(key, ""))).is_equal(expected[i])
	assert_int(InteractionTypes.OCCLUSION_MASK).is_equal(1 << 0)
