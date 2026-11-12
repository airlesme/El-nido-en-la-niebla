## First-person body of Vera (GDD 2). Public surface = GDD 2 rule 33 exactly, plus the ADR-0009 `configurar(ctx)`
## (ADR-0012 D1, D3, D10, § Key Interfaces; TR-player-001, TR-player-003, TR-player-020).
## An un-rotated `CharacterBody3D`: yaw and pitch live in `Look` (pure logic) and are applied only to the presentation rig
## `Rig/Look/Bob/MainCamera`. Physics runs at the fixed tick (never the frame delta); the rig shows the own interpolation of
## the eyes (`TickInterpolator`, alpha = engine fraction, C-R15). The hands are outside M1 (story 011, cut 1): their
## operations and signals exist (closed API, AC-04), return false and log, and there is no `HandsRig`.
## Every helper is `_`-prefixed on purpose: the public methods are compared by equality with rule 33 (T-U14).
## TODO(ADR-0012): `PlayerStateMachine`, `Look`, `TickInterpolator`, `BobMath` and the port adapters have signatures fixed by
## their own stories; the ADR pseudocode names differ (owner: lead-programmer).
## TODO(TR-player-008): `MainCamera.fov` is `campo_vision` as is; F5 (aspect conversion) is deferred (owner: gameplay-programmer).
## TODO(ADR-0007): the sway level comes from `PlayerConfig.balanceo_nivel` until Settings is Accepted (owner: lead-programmer).
## Example: `player.configurar(ctx)`, then `player.colocar(anchor.global_position, anchor.global_rotation.y, 0.0)`.
class_name Player extends CharacterBody3D

## Footstep: `superficie` from the floor probe, `intensidad` in [i_paso_min, 1] (contract signal 2 -> 23, never the bus).
signal paso(superficie: StringName, intensidad: float)
## A hand gesture ended. `motivo`: `&"completo"`, `&"cancelado"` or `&"tope"`. Never emitted in M1.
signal gesto_terminado(id: StringName, motivo: StringName)
## The camera lease reached its destination (arrives from `_process`, never inside the request).
signal camara_cedida(propietario: StringName)
## The camera went back to the player (arrives from `_process`).
signal camara_devuelta(propietario: StringName)
## An object is now held. Never emitted in M1.
signal objeto_sujeto(obj_id: StringName)
## The held object was released. Never emitted in M1.
signal objeto_soltado(obj_id: StringName)

## Message logged by the hand operations while the hands are not implemented.
const HANDS_OFF_MESSAGE: String = "manos fuera de M1"

var _clock: GameClock
var _log: LogSink
var _cfg: PlayerConfig
var _input: PlayerInputPort
var _surface: SurfaceProbe
var _aspect: AspectSource
var _sm: PlayerStateMachine = PlayerStateMachine.new()
var _look: Look
var _interp: TickInterpolator
var _lease: CameraLease
var _poses: PoseHistory
var _yaw_window: YawWindow
var _stuck: StuckGuard
var _bob: BobMath = BobMath.new()
var _d: float = 0.0
var _configured: bool = false

@onready var _body_shape: CollisionShape3D = %BodyShape
@onready var _zone_shape: CollisionShape3D = %ZoneShape
@onready var _rig: Node3D = %Rig
@onready var _look_node: Node3D = %Look
@onready var _bob_node: Node3D = %Bob
@onready var _camera: Camera3D = %MainCamera


func _ready() -> void:
	set_process(_configured)
	set_physics_process(_configured)


func _physics_process(_delta: float) -> void:
	if _clock == null or _clock.is_paused(): # ADR-0002 G-4
		return
	_tick(1.0 / float(_cfg.f_fisica))


func _process(_delta: float) -> void:
	if not _configured:
		return
	_frame(_clock.delta(), _fraction())


## ADR-0009 composition entry (not part of rule 33). Hard dependencies: clock, input, content, logger, fatal. A missing one
## raises `DEPENDENCIA_AUSENTE` (when `fatal` exists) and leaves the Player inert. Loads `player/player.json` (fatal on invalid
## data). Completes a `colocar` made before this call (C2). Example: `player.configurar(ctx)`.
## TODO(ADR-0009): `ctx.require` does not exist yet; the check is inline (owner: lead-programmer).
func configurar(ctx: ServiceContext) -> void:
	if _configured:
		return
	var missing: Array[StringName] = []
	if ctx == null:
		push_error("Player.configurar: null context")
		return
	if ctx.clock == null:
		missing.append(&"clock")
	if ctx.input == null:
		missing.append(&"input")
	if ctx.content == null:
		missing.append(&"content")
	if ctx.logger == null:
		missing.append(&"logger")
	if ctx.fatal == null:
		missing.append(&"fatal")
	if not missing.is_empty():
		if ctx.fatal != null:
			ctx.fatal.raise_fatal(FatalErrorHandler.DEPENDENCIA_AUSENTE, {&"system": &"player", &"missing": missing})
		else:
			push_error("Player.configurar: missing services %s" % [missing])
		return
	var files: FileStore = ctx.files if ctx.files != null else FileStore.new()
	var flavor: BuildFlavor = ctx.flavor if ctx.flavor != null else BuildFlavor.new(false)
	var cfg: PlayerConfig = PlayerConfig.load_from(DataReader.new(files, flavor), ctx.fatal,
			Engine.physics_ticks_per_second)
	if cfg == null:
		return
	_wire(cfg, ctx.clock, ctx.logger, InputRouterPlayerPort.new(ctx.input), SlideSurfaceProbe.new(self),
			ViewportAspectSource.new(get_viewport()), ShrunkCapsuleProbe.new(self, cfg))


## Synchronous full reset (rule 20): velocity 0, lease cancelled without signals, look, pose memory, yaw window and
## interpolator reset, state Congelado until the first poll that sees EXPLORACION. Angles in radians. Legal before
## `configurar()` (C2): the body moves and the rest is applied when configured. A non-finite argument is ignored and logged.
func colocar(posicion: Vector3, yaw: float, pitch: float) -> void:
	var pose: PlayerPose = PlayerPose.new()
	pose.position = posicion
	pose.yaw = yaw
	pose.pitch = pitch
	if not _configured:
		_sm.defer_place(pose)
		if posicion.is_finite():
			_set_feet(posicion)
			velocity = Vector3.ZERO
		return
	_apply_place(pose)


## Camera lease (rule 18, F9). `pose_destino.position` = eyes, world, radians. Returns false (logged) when rejected.
func ceder_camara(propietario: StringName, pose_destino: CameraPose, fov_destino_deg: float, duracion_s: float) -> bool:
	if not _configured:
		push_warning("Player.ceder_camara before configurar() rejected")
		return false
	return _lease.ceder_camara(propietario, pose_destino, fov_destino_deg, duracion_s)


## Gives the camera back to the player. Returns false (logged) when `propietario` does not hold it.
func devolver_camara(propietario: StringName) -> bool:
	if not _configured:
		return false
	return _lease.devolver_camara(propietario)


## Physics eyes (no bob, no interpolation) and the current camera forward, a lease included (also the audio listener).
func rayo_vision() -> VisionRay:
	var ray: VisionRay = VisionRay.new()
	ray.origen = _feet() + Vector3(0.0, _eye_height(), 0.0)
	var basis: Basis = _look_node.global_basis if _look_node.is_inside_tree() else _look_node.basis
	ray.direccion = (-basis.z).normalized()
	return ray


## Effective vertical FOV in degrees, a lease in progress included.
func fov_actual() -> float:
	if not _configured:
		return PlayerConfig.DEFAULT_CAMPO_VISION_DEG
	var f: float = _lease.fov()
	return f if f > 0.0 else _cfg.campo_vision_deg


## Hands are outside M1: returns false and logs.
func reproducir_gesto(_id: StringName, _parametros: Dictionary = {}) -> bool:
	return _hands_off()


## Hands are outside M1: returns false and logs.
func sostener(_obj_id: StringName, _mano: StringName, _pose_inspeccion: InspectionPose) -> bool:
	return _hands_off()


## Hands are outside M1: returns false and logs.
func soltar() -> bool:
	return _hands_off()


## Hands are outside M1: returns false and logs. Angles in radians.
func girar_objeto(_delta_yaw: float, _delta_pitch: float) -> bool:
	return _hands_off()


## Hands are outside M1: returns false and logs.
func apuntar(_punto: Vector3) -> bool:
	return _hands_off()


## Hands are outside M1: no-op.
func reposo() -> void:
	pass


## Pose of the physics state this tick (feet, yaw, pitch, speed, step phase). Allocates one `PlayerPose`.
func pose_actual() -> PlayerPose:
	return pose_con_retardo(0.0)


## Pose `tau_s` seconds ago, clamped to [0, T_hist]. Before `configurar()` it is the current feet position.
func pose_con_retardo(tau_s: float) -> PlayerPose:
	if _poses == null:
		var p: PlayerPose = PlayerPose.new()
		p.position = _feet()
		return p
	return _poses.pose_con_retardo(tau_s)


## Radians turned over the last `T_giro` seconds.
func giro_acumulado() -> float:
	if _yaw_window == null:
		return 0.0
	return _yaw_window.giro_acumulado()


# Builds every collaborator from an already validated config and injected ports. `configurar` calls it; unit tests call it
# directly with fakes (no ServiceContext needed).
func _wire(cfg: PlayerConfig, clock: GameClock, logger: LogSink, input: PlayerInputPort, surface: SurfaceProbe,
		aspect: AspectSource, probe: PenetrationProbe) -> void:
	_cfg = cfg
	_clock = clock
	_log = logger
	_input = input
	_surface = surface
	_aspect = aspect
	_look = Look.new(cfg.pitch_max)
	_interp = TickInterpolator.new()
	_lease = CameraLease.new(cfg, logger, clock.now)
	_poses = PoseHistory.new(cfg.t_hist, cfg.f_fisica)
	_yaw_window = YawWindow.new(cfg.t_giro, cfg.f_fisica)
	_stuck = StuckGuard.new(cfg, probe)
	if not _bob.configure(cfg, cfg.balanceo_nivel, clock.now()):
		_bob.configure(cfg, BobMath.LEVEL_REDUCED, clock.now())
	_apply_geometry()
	var anchor: PlayerPose = PlayerPose.new()
	anchor.position = _feet()
	_stuck.reset(anchor.position)
	_poses.fill(anchor)
	_yaw_window.reset(0.0)
	_interp.reset(_feet() + Vector3(0.0, cfg.altura_ojos, 0.0), 0.0, 0.0)
	_configured = true
	if is_node_ready():
		set_process(true)
		set_physics_process(true)
	var pending: PlayerPose = _sm.on_configured()
	if pending != null:
		_apply_place(pending)
	else:
		_present(1.0)


# Sizes capsule, zone sensor and camera from data (the scene only carries defaults).
func _apply_geometry() -> void:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = _cfg.radio_capsula
	capsule.height = _cfg.altura_capsula
	_body_shape.shape = capsule
	_body_shape.position = Vector3(0.0, _cfg.altura_capsula * 0.5, 0.0)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = _cfg.radio_sensor_zona
	_zone_shape.shape = sphere
	_camera.near = _cfg.near
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = _cfg.campo_vision_deg


func _apply_place(pose: PlayerPose) -> void:
	if not _sm.place(pose, _look, _poses, _yaw_window, _interp, _cfg.altura_ojos, _lease.cancel_silently):
		return
	global_basis = Basis.IDENTITY # C-X13: the body is never rotated; a rotated parent scene transform must not leak in
	_set_feet(pose.position)
	velocity = Vector3.ZERO
	_d = 0.0
	_stuck.reset(pose.position)
	_present(1.0)


# One physics tick (ADR-0012 D1 order): state sync, F1/F2, slide, adopt velocity, d, step, pose, yaw window, safety net, push.
func _tick(dt: float) -> void:
	_sm.sync(_input.context(), _lease.is_own())
	var m: Vector2 = _input.move_vector()
	if not (is_finite(m.x) and is_finite(m.y)):
		m = Vector2.ZERO
		_log.line(LogSink.LEVEL_WARN, "Player: non-finite move vector discarded")
	var v_body: Vector2 = _sm.step_velocity(m, _cfg, dt)
	var w: Vector2 = Locomotion.to_world(v_body, _look.yaw)
	var vy: float = 0.0 if is_on_floor() else velocity.y + get_gravity().y * dt
	velocity = Vector3(w.x, vy, w.y)
	var before: Vector3 = _feet()
	move_and_slide()
	var after: Vector3 = _feet()
	_sm.set_velocity_body(Locomotion.to_body(Vector2(velocity.x, velocity.z), _look.yaw))
	var speed: float = _sm.velocity_body().length()
	var step_len: float = Vector2(after.x - before.x, after.z - before.z).length()
	var r: float = clampf(speed / _cfg.v_paseo, 0.0, 1.0)
	for _crossing: float in StepTracker.crossings(_d, _d + step_len, _cfg.l_paso):
		paso.emit(_surface.floor_surface(), StepTracker.intensity(r, _cfg.i_paso_min))
	_d += step_len
	_poses.record_tick(after, _look.yaw, _look.pitch, speed, fmod(_d, 2.0 * _cfg.l_paso))
	_yaw_window.record_tick(_look.yaw)
	if _stuck.tick(after, step_len, is_on_floor(), _clock.now()):
		_relocate(_stuck.safe_pose())
		return
	_interp.push(after + Vector3(0.0, _cfg.altura_ojos, 0.0), _d, r)


# One rendered frame: look 1:1 (F4, only when free and time runs), then the presentation.
func _frame(game_dt: float, alpha: float) -> void:
	var look_deg: Vector2 = _input.look_delta_deg() # always consumed
	if _sm.is_free() and game_dt > 0.0:
		_look.apply_input_deg(look_deg)
	_present(alpha)
	_sm.sync(_input.context(), _lease.is_own())


# Evaluates the lease and writes Rig, Look, Bob and the camera FOV; then emits the queued lease events.
func _present(alpha: float) -> void:
	var eyes: Vector3 = _interp.position_at(alpha)
	var cam: CameraPose = _lease.evaluate(eyes, _look.yaw, _look.pitch, _cfg.campo_vision_deg)
	_rig.position = cam.position - _feet()
	_look_node.basis = Basis.from_euler(Vector3(cam.pitch, cam.yaw, 0.0), EULER_ORDER_YXZ) # roll 0
	if _lease.is_own():
		_bob_node.position = BobMath.offset(_interp.phase_at(alpha), _interp.ratio_at(alpha), _bob.gain(_clock.now()), _cfg)
	else:
		_bob_node.position = Vector3.ZERO
	_camera.fov = fov_actual()
	for ev: CameraLease.LeaseEvent in _lease.take_events():
		if ev.kind == CameraLease.CEDED:
			camara_cedida.emit(ev.owner)
		else:
			camara_devuelta.emit(ev.owner)


func _relocate(feet: Vector3) -> void:
	_set_feet(feet)
	velocity = Vector3.ZERO
	_sm.set_velocity_body(Vector2.ZERO)
	_interp.reset(feet + Vector3(0.0, _cfg.altura_ojos, 0.0), _d, 0.0)
	_log.line(LogSink.LEVEL_WARN, "Player: safety net relocated the body to %s" % [feet])


# `Engine.get_physics_interpolation_fraction()` is the only alpha source (C-R15, C-X09).
func _fraction() -> float:
	return Engine.get_physics_interpolation_fraction()


func _hands_off() -> bool:
	if _log != null:
		_log.line(LogSink.LEVEL_WARN, HANDS_OFF_MESSAGE)
	else:
		push_warning(HANDS_OFF_MESSAGE)
	return false


func _eye_height() -> float:
	return _cfg.altura_ojos if _cfg != null else 0.0


func _feet() -> Vector3:
	return global_position if is_inside_tree() else position


func _set_feet(p: Vector3) -> void:
	if is_inside_tree():
		global_position = p
	else:
		position = p
