extends GdUnitTestSuite
## PoseHistory (PJ-007, ADR-0012 D7, GDD 2 F6; AC-35, T-U8): circular pose memory and `pose_con_retardo`.

const F: int = 60
const T_HIST: float = 1.0
const SPEED: float = 1.6


func _pose(x: float, yaw: float = 0.0) -> PlayerPose:
	var p: PlayerPose = PlayerPose.new()
	p.position = Vector3(x, 0.0, 0.0)
	p.yaw = yaw
	return p


## 2 s walking east at 1.6 m/s: 120 samples, x(k) = SPEED * k / F.
func _walked() -> PoseHistory:
	var h: PoseHistory = PoseHistory.new(T_HIST, F)
	h.fill(_pose(0.0))
	for k in range(1, 121):
		h.record_tick(Vector3(SPEED * float(k) / float(F), 0.0, 0.0), 0.0, 0.0, SPEED, 0.0)
	return h


func test_capacity_for_default_config_is_62() -> void:
	assert_int(PoseHistory.new(1.0, 60).capacity()).is_equal(62)


func test_capacity_has_no_float_rounding_surplus() -> void:
	# 0.6 * 60 is 36.00000000000001 in doubles; N must still be 36 + 2.
	assert_int(PoseHistory.new(0.6, 60).capacity()).is_equal(38)


func test_delay_of_0_6_s_after_two_seconds_is_0_96_m_behind() -> void:
	var h: PoseHistory = _walked()

	var delayed: float = h.pose_con_retardo(0.6).position.x

	assert_float(h.pose_con_retardo(0.0).position.x - delayed).is_equal_approx(0.96, 0.02)


func test_tau_zero_is_newest_sample() -> void:
	var h: PoseHistory = _walked()

	assert_float(h.pose_con_retardo(0.0).position.x).is_equal_approx(3.2, 0.0001)


func test_tau_t_hist_is_sample_60_without_reading_outside() -> void:
	var h: PoseHistory = _walked()

	# Sample 60 = tick 120 - 60 = 60 -> x = 1.6.
	assert_float(h.pose_con_retardo(1.0).position.x).is_equal_approx(1.6, 0.0001)


func test_tau_out_of_range_is_clamped() -> void:
	var h: PoseHistory = _walked()

	assert_float(h.pose_con_retardo(-1.0).position.x).is_equal_approx(h.pose_con_retardo(0.0).position.x, 0.00001)
	assert_float(h.pose_con_retardo(5.0).position.x).is_equal_approx(h.pose_con_retardo(1.0).position.x, 0.00001)


func test_tau_between_samples_interpolates() -> void:
	var h: PoseHistory = _walked()

	# tau 0.0125 -> s = 0.75: 0.75 of the way from sample 0 (3.2) to sample 1.
	var expected: float = 3.2 - 0.75 * SPEED / float(F)
	assert_float(h.pose_con_retardo(0.0125).position.x).is_equal_approx(expected, 0.0001)


func test_after_fill_every_delay_returns_initial_pose() -> void:
	var h: PoseHistory = _walked()
	var start: PlayerPose = _pose(7.0, 1.0)
	start.pitch = 0.2
	start.speed_h = 0.3
	start.step_phase = 0.4

	h.fill(start)

	for tau: float in [0.0, 0.6, 1.0]:
		var p: PlayerPose = h.pose_con_retardo(tau)
		assert_vector(p.position).is_equal_approx(Vector3(7.0, 0.0, 0.0), Vector3.ONE * 0.0001)
		assert_float(p.yaw).is_equal_approx(1.0, 0.0001)
		assert_float(p.pitch).is_equal_approx(0.2, 0.0001)
		assert_float(p.speed_h).is_equal_approx(0.3, 0.0001)
		assert_float(p.step_phase).is_equal_approx(0.4, 0.0001)


func test_ring_wraps_after_more_writes_than_capacity() -> void:
	var h: PoseHistory = PoseHistory.new(T_HIST, F)
	h.fill(_pose(0.0))
	for k in range(1, 201):
		h.record_tick(Vector3(float(k), 0.0, 0.0), 0.0, 0.0, 0.0, 0.0)

	assert_float(h.pose_con_retardo(0.0).position.x).is_equal_approx(200.0, 0.0001)
	assert_float(h.pose_con_retardo(1.0).position.x).is_equal_approx(140.0, 0.0001)


func test_yaw_interpolates_by_shortest_arc() -> void:
	var h: PoseHistory = PoseHistory.new(T_HIST, F)
	h.fill(_pose(0.0, PI - 0.1))
	h.record_tick(Vector3.ZERO, -PI + 0.1, 0.0, 0.0, 0.0)

	# Halfway between PI-0.1 and -PI+0.1 by the short arc is +-PI, never 0.
	var yaw: float = h.pose_con_retardo(1.0 / 120.0).yaw

	assert_float(absf(yaw)).is_equal_approx(PI, 0.0001)


func test_yaw_stays_in_range_after_wrapping_input() -> void:
	var h: PoseHistory = PoseHistory.new(T_HIST, F)

	h.fill(_pose(0.0, 3.0 * PI))

	assert_float(h.pose_con_retardo(0.0).yaw).is_between(-PI, PI)
