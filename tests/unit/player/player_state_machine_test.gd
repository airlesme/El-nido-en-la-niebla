extends GdUnitTestSuite
## PJ-009 (T-U7 of ADR-0012): player state machine and `colocar`. AC-23 (scope M1), AC-24, AC-26 (logic), C2. TR-player-014/018.
## Pure logic: no node, no physics, no clock. The config is the real player.json.

const PLAYER_FULL: String = "res://assets/data/player/player.json"
const DT: float = 1.0 / 60.0
const EXPLO: InputTypes.Context = InputTypes.Context.EXPLORACION


func _cfg() -> PlayerConfig:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAYER_FULL))
	return PlayerConfig.from_dict(parsed as Dictionary)


func _pose(pos: Vector3, yaw: float, pitch: float) -> PlayerPose:
	var p: PlayerPose = PlayerPose.new()
	p.position = pos
	p.yaw = yaw
	p.pitch = pitch
	return p


## State machine already placed and free (context EXPLORACION seen).
func _free_sm(cfg: PlayerConfig) -> PlayerStateMachine:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	var look: Look = Look.new(cfg.pitch_max)
	sm.place(_pose(Vector3.ZERO, 0.0, 0.0), look, PoseHistory.new(cfg.t_hist, cfg.f_fisica),
			YawWindow.new(cfg.t_giro, cfg.f_fisica), TickInterpolator.new(), cfg.altura_ojos)
	sm.sync(EXPLO, true)
	return sm


# --- initial state / transitions ---------------------------------------------

func test_new_machine_is_sin_escena_and_ignores_sync() -> void:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.sync(EXPLO, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.SIN_ESCENA)
	assert_bool(sm.is_free()).is_false()
	assert_object(sm.anchor()).is_null()


func test_place_then_exploration_poll_becomes_libre() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)
	assert_bool(sm.is_free()).is_true()


func test_placed_stays_congelado_until_exploration_is_seen() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.place(_pose(Vector3.ZERO, 0.0, 0.0), Look.new(cfg.pitch_max), PoseHistory.new(cfg.t_hist, cfg.f_fisica),
			YawWindow.new(cfg.t_giro, cfg.f_fisica), TickInterpolator.new(), cfg.altura_ojos)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CONGELADO)
	sm.sync(InputTypes.Context.INSPECCION, true)
	sm.sync(InputTypes.Context.SIN_CONTROL, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CONGELADO)
	sm.sync(EXPLO, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)


func test_non_exploration_context_freezes_and_return_frees() -> void:
	var sm: PlayerStateMachine = _free_sm(_cfg())
	for ctx: InputTypes.Context in [InputTypes.Context.INSPECCION, InputTypes.Context.LECTURA,
			InputTypes.Context.VISTA_CERCANA, InputTypes.Context.ORDENADOR, InputTypes.Context.LLAMADA,
			InputTypes.Context.MENU, InputTypes.Context.SIN_CONTROL]:
		sm.sync(ctx, true)
		assert_int(sm.state()).is_equal(PlayerStateMachine.State.CONGELADO)
		sm.sync(EXPLO, true)
		assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)


func test_lease_not_own_gives_camara_cedida_and_returns_to_libre() -> void:
	var sm: PlayerStateMachine = _free_sm(_cfg())
	sm.sync(EXPLO, false)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CAMARA_CEDIDA)
	assert_bool(sm.is_free()).is_false()
	sm.sync(EXPLO, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)


func test_lease_has_priority_over_context() -> void:
	var sm: PlayerStateMachine = _free_sm(_cfg())
	sm.sync(InputTypes.Context.INSPECCION, false)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CAMARA_CEDIDA)


func test_sin_escena_is_left_only_by_place() -> void:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.sync(EXPLO, false)
	sm.sync(InputTypes.Context.MENU, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.SIN_ESCENA)


# --- AC-24: leaving Libre brakes ----------------------------------------------

func test_leaving_libre_brakes_in_nine_steps_over_0_107_m_and_keeps_orientation() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	sm.set_velocity_body(Vector2(0.0, 1.6))
	var look: Look = Look.new(cfg.pitch_max)
	look.set_orientation(0.5, 0.1)
	sm.sync(InputTypes.Context.INSPECCION, true)   # Entrada announces `inspeccion`
	var dist: float = 0.0
	for i: int in 9:
		var v: Vector2 = sm.step_velocity(Vector2(0.0, 1.0), cfg, DT)   # `mover` keeps arriving, ignored
		dist += v.length() * DT
		if i == 7:
			assert_float(v.length()).is_greater(0.1)   # not stopped one step early
	assert_float(dist).is_equal_approx(0.107, 0.002)
	assert_float(sm.velocity_body().length()).is_less(0.002)
	assert_float(look.yaw).is_equal_approx(0.5, 0.000001)   # the machine never touches orientation


func test_leaving_libre_does_not_reset_velocity() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	sm.set_velocity_body(Vector2(0.0, 1.6))
	sm.sync(InputTypes.Context.MENU, true)
	assert_vector(sm.velocity_body()).is_equal(Vector2(0.0, 1.6))
	var v: Vector2 = sm.step_velocity(Vector2(0.0, 1.0), cfg, DT)
	assert_float(v.y).is_between(0.01, 1.6)


# --- AC-26 (logic): entering Libre reads `mover` in that tick ----------------

func test_entering_libre_walks_in_the_same_tick() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	sm.sync(InputTypes.Context.VISTA_CERCANA, true)
	assert_vector(sm.step_velocity(Vector2(0.0, 1.0), cfg, DT)).is_equal(Vector2.ZERO)
	sm.sync(EXPLO, true)
	var v: Vector2 = sm.step_velocity(Vector2(0.0, 1.0), cfg, DT)   # W held, same tick
	assert_float(v.y).is_greater(0.0)


func test_move_is_ignored_while_cedida_and_sin_escena() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	assert_vector(sm.step_velocity(Vector2(0.0, 1.0), cfg, DT)).is_equal(Vector2.ZERO)
	var sm2: PlayerStateMachine = _free_sm(cfg)
	sm2.sync(EXPLO, false)
	assert_vector(sm2.step_velocity(Vector2(0.0, 1.0), cfg, DT)).is_equal(Vector2.ZERO)


func test_set_velocity_body_ignores_non_finite() -> void:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.set_velocity_body(Vector2(1.0, 2.0))
	sm.set_velocity_body(Vector2(NAN, 0.0))
	assert_vector(sm.velocity_body()).is_equal(Vector2(1.0, 2.0))


# --- AC-23: colocar ---------------------------------------------------------

func test_place_resets_everything_in_the_same_call() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	sm.set_velocity_body(Vector2(0.5, 1.6))
	var look: Look = Look.new(cfg.pitch_max)
	var history: PoseHistory = PoseHistory.new(cfg.t_hist, cfg.f_fisica)
	var window: YawWindow = YawWindow.new(cfg.t_giro, cfg.f_fisica)
	var interp: TickInterpolator = TickInterpolator.new()
	for i: int in 10:
		window.record_tick(float(i + 1) * 0.1)
		history.record_tick(Vector3(float(i), 0, 0), 0.0, 0.0, 1.6, 0.0)
		interp.push(Vector3(float(i), 1.6, 0), 0.0, 1.0)
	assert_float(window.giro_acumulado()).is_greater(0.0)
	var calls: Array[int] = [0]
	var target: Vector3 = Vector3(3.0, 0.5, -2.0)
	var ok: bool = sm.place(_pose(target, 1.0, 0.2), look, history, window, interp, cfg.altura_ojos,
			func() -> void: calls[0] += 1)
	assert_bool(ok).is_true()
	assert_int(calls[0]).is_equal(1)
	assert_vector(sm.velocity_body()).is_equal(Vector2.ZERO)
	assert_float(look.yaw).is_equal_approx(1.0, 0.000001)
	assert_float(look.pitch).is_equal_approx(0.2, 0.000001)
	assert_float(window.giro_acumulado()).is_equal(0.0)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CONGELADO)
	for tau: float in [0.0, 0.3, cfg.t_hist]:
		var h: PlayerPose = history.pose_con_retardo(tau)
		assert_vector(h.position).is_equal_approx(target, Vector3.ONE * 0.001)
		assert_float(h.yaw).is_equal_approx(1.0, 0.000001)
	var eyes: Vector3 = target + Vector3(0.0, cfg.altura_ojos, 0.0)
	for a: float in [0.0, 0.5, 1.0]:
		assert_vector(interp.position_at(a)).is_equal_approx(eyes, Vector3.ONE * 0.001)
	assert_vector(sm.anchor().position).is_equal_approx(target, Vector3.ONE * 0.001)


func test_place_clamps_pitch_and_wraps_yaw() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	var look: Look = Look.new(cfg.pitch_max)
	sm.place(_pose(Vector3.ZERO, 3.0 * PI, 10.0), look, PoseHistory.new(cfg.t_hist, cfg.f_fisica),
			YawWindow.new(cfg.t_giro, cfg.f_fisica), TickInterpolator.new(), cfg.altura_ojos)
	assert_float(look.pitch).is_equal_approx(cfg.pitch_max, 0.000001)
	assert_float(absf(look.yaw)).is_equal_approx(PI, 0.0001)
	assert_float(sm.anchor().pitch).is_equal_approx(cfg.pitch_max, 0.000001)


func test_place_from_cedida_cancels_lease_and_freezes() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	sm.sync(EXPLO, false)
	var calls: Array[int] = [0]
	sm.place(_pose(Vector3.ONE, 0.0, 0.0), Look.new(cfg.pitch_max), PoseHistory.new(cfg.t_hist, cfg.f_fisica),
			YawWindow.new(cfg.t_giro, cfg.f_fisica), TickInterpolator.new(), cfg.altura_ojos,
			func() -> void: calls[0] += 1)
	assert_int(calls[0]).is_equal(1)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CONGELADO)
	sm.sync(EXPLO, true)   # lease is OWN after the cancel
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)


func test_place_with_non_finite_pose_is_rejected_without_changes() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = _free_sm(cfg)
	sm.set_velocity_body(Vector2(0.0, 1.0))
	var look: Look = Look.new(cfg.pitch_max)
	var bad: Array[PlayerPose] = [_pose(Vector3(NAN, 0, 0), 0.0, 0.0), _pose(Vector3.ZERO, INF, 0.0),
			_pose(Vector3.ZERO, 0.0, NAN), null]
	for p: PlayerPose in bad:
		var ok: bool = sm.place(p, look, PoseHistory.new(cfg.t_hist, cfg.f_fisica),
				YawWindow.new(cfg.t_giro, cfg.f_fisica), TickInterpolator.new(), cfg.altura_ojos)
		assert_bool(ok).is_false()
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)
	assert_vector(sm.velocity_body()).is_equal(Vector2(0.0, 1.0))


# --- C2: colocar before configurar ---------------------------------------------

func test_place_before_configure_stays_sin_escena_then_congelado_on_configure() -> void:
	var cfg: PlayerConfig = _cfg()
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.defer_place(_pose(Vector3(1, 2, 3), 0.5, 0.0))
	assert_bool(sm.has_pending()).is_true()
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.SIN_ESCENA)
	sm.sync(EXPLO, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.SIN_ESCENA)
	var pending: PlayerPose = sm.on_configured()
	assert_object(pending).is_not_null()
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.CONGELADO)
	assert_bool(sm.has_pending()).is_false()
	assert_bool(sm.place(pending, Look.new(cfg.pitch_max), PoseHistory.new(cfg.t_hist, cfg.f_fisica),
			YawWindow.new(cfg.t_giro, cfg.f_fisica), TickInterpolator.new(), cfg.altura_ojos)).is_true()
	sm.sync(EXPLO, true)
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.LIBRE)


func test_configure_without_pending_place_stays_sin_escena() -> void:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	assert_object(sm.on_configured()).is_null()
	assert_int(sm.state()).is_equal(PlayerStateMachine.State.SIN_ESCENA)


func test_defer_place_last_wins_and_invalid_is_ignored() -> void:
	var sm: PlayerStateMachine = PlayerStateMachine.new()
	sm.defer_place(_pose(Vector3(1, 0, 0), 0.0, 0.0))
	sm.defer_place(_pose(Vector3(2, 0, 0), 0.0, 0.0))
	sm.defer_place(_pose(Vector3(NAN, 0, 0), 0.0, 0.0))
	assert_float(sm.on_configured().position.x).is_equal(2.0)
