extends GdUnitTestSuite
## CameraLease (PJ-010, ADR-0012 D5, GDD 2 R18/F9; AC-20, AC-21, AC-25, AC-44; T-U6). Injected clock, no engine nodes.

const VISTA: StringName = &"interaccion:vista"
const ORDENADOR: StringName = &"interaccion:ordenador"
const EYES: Vector3 = Vector3(0.0, 1.62, 0.0)
const FOV_FREE: float = 70.0
const YAW0: float = 0.5235987756 # 30 deg
const PITCH0: float = -0.1745329252 # -10 deg

var _t: float = 0.0
var _log: RecordingLog
var _lease: CameraLease
var _cfg: PlayerConfig


func _now() -> float:
	return _t


func before_test() -> void:
	_t = 0.0
	_cfg = PlayerConfig.new()
	_cfg.t_devolver = 0.5
	_cfg.t_transicion_max = 3.0
	_cfg.pitch_cesion_max = deg_to_rad(89.0)
	_cfg.propietarios_camara.assign([VISTA, ORDENADOR])
	_log = RecordingLog.new()
	_lease = CameraLease.new(_cfg, _log, _now)


func _pose(pos: Vector3, yaw_deg: float, pitch_deg: float) -> CameraPose:
	return CameraPose.make(pos, deg_to_rad(yaw_deg), deg_to_rad(pitch_deg))


## Sets the clock to `t`, evaluates a free camera at EYES/YAW0/PITCH0 and returns the result.
func _eval(t: float) -> CameraPose:
	_t = t
	return _lease.evaluate(EYES, YAW0, PITCH0, FOV_FREE)


func _lease_to(pose: CameraPose, fov: float, dur: float) -> void:
	_eval(0.0)
	assert_bool(_lease.ceder_camara(VISTA, pose, fov, dur)).is_true()


func _errors() -> int:
	var n: int = 0
	for l: Dictionary in _log.lines:
		if l[&"level"] == LogSink.LEVEL_ERROR:
			n += 1
	return n


# --- AC-20

func test_own_passes_the_free_camera_through() -> void:
	var cam: CameraPose = _eval(1.0)
	assert_vector(cam.position).is_equal(EYES)
	assert_float(cam.yaw).is_equal(YAW0)
	assert_float(cam.pitch).is_equal(PITCH0)
	assert_float(_lease.fov()).is_equal(FOV_FREE)
	assert_bool(_lease.is_own()).is_true()


func test_cession_is_halfway_at_half_the_duration_with_fov_65() -> void:
	var dest: CameraPose = _pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0)
	_lease_to(dest, 60.0, 1.0)
	var cam: CameraPose = _eval(0.5)
	assert_vector(cam.position).is_equal_approx(Vector3(1.0, 1.31, 0.0), Vector3.ONE * 0.001)
	assert_float(_lease.fov()).is_equal_approx(65.0, 0.1)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASING)


func test_cession_arrives_at_the_pose_and_emits_ceded_once() -> void:
	var dest: CameraPose = _pose(Vector3(2.0, 1.0, 0.0), 90.0, 20.0)
	_lease_to(dest, 60.0, 1.0)
	var cam: CameraPose = _eval(1.0)
	assert_vector(cam.position).is_equal_approx(dest.position, Vector3.ONE * 0.001)
	assert_float(rad_to_deg(cam.yaw)).is_equal_approx(90.0, 0.1)
	assert_float(rad_to_deg(cam.pitch)).is_equal_approx(20.0, 0.1)
	assert_float(_lease.fov()).is_equal_approx(60.0, 0.1)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASED)
	var evs: Array[CameraLease.LeaseEvent] = _lease.take_events()
	assert_int(evs.size()).is_equal(1)
	assert_str(evs[0].kind).is_equal(CameraLease.CEDED)
	assert_str(evs[0].owner).is_equal(VISTA)
	_eval(1.5)
	assert_int(_lease.take_events().size()).is_equal(0)


func test_return_reaches_saved_look_eyes_and_fov_in_half_a_second() -> void:
	var dest: CameraPose = _pose(Vector3(2.0, 1.0, 0.0), 90.0, 20.0)
	_lease_to(dest, 60.0, 1.0)
	_eval(1.0)
	_lease.take_events()
	assert_bool(_lease.devolver_camara(VISTA)).is_true()
	var mid: CameraPose = _eval(1.25)
	assert_float(_lease.fov()).is_equal_approx(65.0, 0.1)
	assert_vector(mid.position).is_equal_approx(dest.position.lerp(EYES, 0.5), Vector3.ONE * 0.001)
	assert_int(_lease.take_events().size()).is_equal(0)
	assert_bool(_lease.is_own()).is_false()
	var cam: CameraPose = _eval(1.5)
	assert_float(rad_to_deg(cam.yaw)).is_equal_approx(30.0, 0.1)
	assert_float(rad_to_deg(cam.pitch)).is_equal_approx(-10.0, 0.1)
	assert_vector(cam.position).is_equal(EYES)
	assert_float(_lease.fov()).is_equal_approx(70.0, 0.1)
	var evs: Array[CameraLease.LeaseEvent] = _lease.take_events()
	assert_int(evs.size()).is_equal(1)
	assert_str(evs[0].kind).is_equal(CameraLease.RETURNED)
	assert_bool(_lease.is_own()).is_true()


func test_return_target_follows_live_eyes_each_frame() -> void:
	_lease_to(_pose(Vector3(2.0, 1.0, 0.0), 90.0, 0.0), 60.0, 0.0)
	_eval(0.0)
	_lease.devolver_camara(VISTA)
	_t = 0.5
	var cam: CameraPose = _lease.evaluate(Vector3(5.0, 1.62, 5.0), YAW0, PITCH0, FOV_FREE)
	assert_vector(cam.position).is_equal(Vector3(5.0, 1.62, 5.0))


func test_zero_duration_arrives_on_next_evaluate_not_inside_the_call() -> void:
	_eval(0.0)
	assert_bool(_lease.ceder_camara(VISTA, _pose(Vector3.ONE, 10.0, 0.0), 50.0, 0.0)).is_true()
	assert_int(_lease.take_events().size()).is_equal(0)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASING)
	var cam: CameraPose = _eval(0.0)
	assert_vector(cam.position).is_equal(Vector3.ONE)
	assert_int(_lease.take_events().size()).is_equal(1)


func test_smoothstep_at_quarter_gives_0156_of_the_way() -> void:
	_eval(0.0)
	_lease.ceder_camara(VISTA, CameraPose.make(EYES + Vector3(1.0, 0.0, 0.0), YAW0, PITCH0), 70.0, 1.0)
	var cam: CameraPose = _eval(0.25)
	assert_float(cam.position.x).is_equal_approx(0.15625, 0.0005)


func test_paused_clock_freezes_the_transition() -> void:
	_lease_to(_pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0), 60.0, 1.0)
	var a: CameraPose = _eval(0.4)
	var b: CameraPose = _eval(0.4)
	assert_vector(a.position).is_equal(b.position)


# --- AC-21

func test_duration_5s_is_clamped_to_3s_and_logs() -> void:
	_eval(0.0)
	_lease.ceder_camara(VISTA, _pose(Vector3(3.0, 1.62, 0.0), 30.0, -10.0), 70.0, 5.0)
	var warns: int = 0
	for l: Dictionary in _log.lines:
		if l[&"level"] == LogSink.LEVEL_WARN:
			warns += 1
	assert_int(warns).is_equal(1)
	_eval(2.9)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASING)
	_eval(3.0)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASED)


func test_negative_duration_is_clamped_to_zero() -> void:
	_eval(0.0)
	_lease.ceder_camara(VISTA, _pose(Vector3.ONE, 0.0, 0.0), 70.0, -2.0)
	_eval(0.0)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASED)


func test_other_owner_cannot_cede_or_return_while_leased() -> void:
	var dest: CameraPose = _pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0)
	_lease_to(dest, 60.0, 1.0)
	var before: CameraPose = _eval(0.5)
	assert_bool(_lease.ceder_camara(ORDENADOR, _pose(Vector3.ZERO, 0.0, 0.0), 50.0, 1.0)).is_false()
	assert_bool(_lease.devolver_camara(ORDENADOR)).is_false()
	assert_int(_errors()).is_equal(2)
	var after: CameraPose = _eval(0.5)
	assert_vector(after.position).is_equal(before.position)
	assert_str(_lease.owner()).is_equal(VISTA)


func test_other_owner_is_rejected_during_the_return_too() -> void:
	_lease_to(_pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0), 60.0, 0.0)
	_eval(0.0)
	_lease.devolver_camara(VISTA)
	_eval(0.2)
	assert_bool(_lease.ceder_camara(ORDENADOR, _pose(Vector3.ZERO, 0.0, 0.0), 50.0, 1.0)).is_false()
	assert_bool(_lease.devolver_camara(ORDENADOR)).is_false()
	assert_str(_lease.owner()).is_equal(VISTA)


func test_unknown_owner_is_rejected_and_camera_does_not_move() -> void:
	_eval(0.0)
	assert_bool(_lease.ceder_camara(&"intruso", _pose(Vector3.ONE, 0.0, 0.0), 50.0, 1.0)).is_false()
	assert_bool(_lease.ceder_camara(&"", _pose(Vector3.ONE, 0.0, 0.0), 50.0, 1.0)).is_false()
	assert_int(_errors()).is_equal(2)
	assert_bool(_lease.is_own()).is_true()
	assert_vector(_eval(1.0).position).is_equal(EYES)


func test_return_when_own_is_rejected_and_second_return_is_ignored() -> void:
	_eval(0.0)
	assert_bool(_lease.devolver_camara(VISTA)).is_false()
	assert_int(_errors()).is_equal(1)
	_lease_to(_pose(Vector3.ONE, 0.0, 0.0), 50.0, 0.0)
	_eval(0.0)
	assert_bool(_lease.devolver_camara(VISTA)).is_true()
	_eval(0.25)
	var mid: CameraPose = _eval(0.25)
	assert_bool(_lease.devolver_camara(VISTA)).is_true()
	assert_vector(_eval(0.25).position).is_equal(mid.position)
	assert_int(_errors()).is_equal(1)


func test_invalid_arguments_are_rejected() -> void:
	_eval(0.0)
	assert_bool(_lease.ceder_camara(VISTA, null, 50.0, 1.0)).is_false()
	assert_bool(_lease.ceder_camara(VISTA, _pose(Vector3.ONE, 0.0, 0.0), NAN, 1.0)).is_false()
	assert_bool(_lease.ceder_camara(VISTA, _pose(Vector3.ONE, 0.0, 0.0), 50.0, INF)).is_false()
	assert_bool(_lease.ceder_camara(VISTA, CameraPose.make(Vector3(NAN, 0, 0), 0.0, 0.0), 50.0, 1.0)).is_false()
	assert_bool(_lease.is_own()).is_true()


func test_same_owner_can_relase_from_current_camera_keeping_saved_look() -> void:
	_lease_to(_pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0), 60.0, 1.0)
	var mid: CameraPose = _eval(0.5)
	assert_bool(_lease.ceder_camara(VISTA, _pose(Vector3(4.0, 1.0, 0.0), 30.0, -10.0), 50.0, 1.0)).is_true()
	var start: CameraPose = _eval(0.5)
	assert_vector(start.position).is_equal_approx(mid.position, Vector3.ONE * 0.001)
	assert_float(_lease.fov()).is_equal_approx(65.0, 0.01)
	_eval(1.5)
	_lease.take_events()
	_lease.devolver_camara(VISTA)
	var back: CameraPose = _eval(2.0)
	assert_float(back.yaw).is_equal_approx(YAW0, 1e-5)
	assert_float(back.pitch).is_equal_approx(PITCH0, 1e-5)


func test_relase_during_return_starts_from_where_the_camera_is() -> void:
	_lease_to(_pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0), 60.0, 0.0)
	_eval(0.0)
	_lease.devolver_camara(VISTA)
	var mid: CameraPose = _eval(0.25)
	assert_bool(_lease.ceder_camara(VISTA, _pose(Vector3(9.0, 1.0, 0.0), 30.0, -10.0), 50.0, 1.0)).is_true()
	assert_vector(_eval(0.25).position).is_equal_approx(mid.position, Vector3.ONE * 0.001)
	assert_int(_lease.state()).is_equal(CameraLease.State.LEASING)


# --- AC-25

func test_not_own_until_returned_event_is_available_in_the_same_evaluation() -> void:
	_lease_to(_pose(Vector3(2.0, 1.0, 0.0), 30.0, -10.0), 60.0, 0.0)
	_eval(0.0)
	_lease.take_events()
	_lease.devolver_camara(VISTA)
	_eval(0.4)
	assert_bool(_lease.is_own()).is_false()
	_eval(0.5)
	assert_bool(_lease.is_own()).is_true()
	assert_int(_lease.take_events().size()).is_equal(1)


func test_state_machine_stays_in_camara_cedida_during_return_and_discards_move() -> void:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.place(PlayerPose.new(), Look.new(_cfg.pitch_max), PoseHistory.new(1.0, 60), YawWindow.new(0.5, 60),
			TickInterpolator.new(), 1.62)
	sm.sync(InputTypes.Context.EXPLORACION, true)
	assert_bool(sm.is_free()).is_true()
	_eval(0.0)
	_lease.ceder_camara(VISTA, _pose(Vector3.ONE, 0.0, 0.0), 50.0, 0.0)
	_eval(0.0)
	_lease.devolver_camara(VISTA)
	_eval(0.2)
	sm.sync(InputTypes.Context.EXPLORACION, _lease.is_own())
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CAMARA_CEDIDA)
	assert_bool(sm.is_free()).is_false()
	_eval(0.5)
	var evs: Array[CameraLease.LeaseEvent] = _lease.take_events()
	assert_str(evs[evs.size() - 1].kind).is_equal(CameraLease.RETURNED)
	sm.sync(InputTypes.Context.EXPLORACION, _lease.is_own())
	assert_bool(sm.is_free()).is_true()


# --- cancel

func test_cancel_silently_returns_to_own_without_events() -> void:
	_lease_to(_pose(Vector3.ONE, 0.0, 0.0), 50.0, 0.0)
	_eval(0.0)
	_lease.cancel_silently()
	assert_bool(_lease.is_own()).is_true()
	assert_int(_lease.take_events().size()).is_equal(0)
	_eval(1.0)
	assert_int(_lease.take_events().size()).is_equal(0)
	assert_bool(_lease.ceder_camara(ORDENADOR, _pose(Vector3.ONE, 0.0, 0.0), 50.0, 1.0)).is_true()


func test_cancel_silently_works_as_the_place_callable() -> void:
	_lease_to(_pose(Vector3.ONE, 0.0, 0.0), 50.0, 1.0)
	var cancel: Callable = _lease.cancel_silently
	assert_bool(cancel.is_valid()).is_true()
	cancel.call()
	assert_bool(_lease.is_own()).is_true()


# --- AC-44

func test_yaw_170_to_minus_170_takes_the_short_arc_with_no_roll() -> void:
	_t = 0.0
	_lease.evaluate(EYES, deg_to_rad(170.0), 0.0, FOV_FREE) # start yaw 170 deg
	_lease.ceder_camara(VISTA, CameraPose.make(EYES, deg_to_rad(-170.0), deg_to_rad(85.0)), 70.0, 1.0)
	var mid: CameraPose = _eval(0.5)
	assert_float(absf(rad_to_deg(mid.yaw))).is_equal_approx(180.0, 0.01)
	# no intermediate sample goes the long way round (through 0)
	for i in 21:
		var cam: CameraPose = _eval(i * 0.05)
		assert_float(absf(rad_to_deg(cam.yaw))).is_greater_equal(169.99)
	var end: CameraPose = _eval(1.0)
	assert_float(rad_to_deg(end.yaw)).is_equal_approx(-170.0, 0.01)
	assert_float(rad_to_deg(end.pitch)).is_equal_approx(85.0, 0.01)
	# roll is structurally absent: the basis from (pitch, yaw, 0) has no roll component
	var basis: Basis = Basis.from_euler(Vector3(end.pitch, end.yaw, 0.0), EULER_ORDER_YXZ)
	assert_float(basis.get_euler(EULER_ORDER_YXZ).z).is_equal_approx(0.0, 1e-6)


func test_requested_pitch_95_ends_at_89() -> void:
	_lease_to(CameraPose.make(EYES, 0.0, deg_to_rad(95.0)), 70.0, 0.5)
	var end: CameraPose = _eval(0.5)
	assert_float(rad_to_deg(end.pitch)).is_equal_approx(89.0, 0.001)


func test_requested_pitch_minus_95_ends_at_minus_89() -> void:
	_lease_to(CameraPose.make(EYES, 0.0, deg_to_rad(-95.0)), 70.0, 0.5)
	assert_float(rad_to_deg(_eval(0.5).pitch)).is_equal_approx(-89.0, 0.001)


func test_yaw_outside_range_is_wrapped() -> void:
	_lease_to(CameraPose.make(EYES, deg_to_rad(370.0), 0.0), 70.0, 0.0)
	assert_float(rad_to_deg(_eval(0.0).yaw)).is_equal_approx(10.0, 0.001)
