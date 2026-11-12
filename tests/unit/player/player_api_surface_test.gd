extends GdUnitTestSuite
## PJ-011 (T-U14 of ADR-0012): `Player` scene, rig and closed public API. AC-04 (a), AC-36, AC-39, AC-22 (via TR-player-020),
## camera M1 (fov, near, keep_aspect, `fov_actual`), physics interpolation off in `project.godot`.
## No wall-clock time and no frame waits: the tick and the frame are driven by hand (`_tick`, `_present`) with a fake clock,
## and the physics/process callbacks of the node are switched off so the engine loop cannot interleave.

const PLAYER_SCENE: String = "res://src/player/player.tscn"
const PLAYER_SCRIPT: String = "res://src/player/player.gd"
const PLAYER_JSON: String = "player/player.json"
const VISTA: StringName = &"interaccion:vista"
const DT: float = 1.0 / 60.0

## Rule 33 of GDD 2 (operations) and the six signals, fixed list. `configurar` is the ADR-0009 entry and is excluded.
const RULE_33_OPERATIONS: Array[String] = [
	"apuntar", "ceder_camara", "colocar", "devolver_camara", "fov_actual", "girar_objeto", "giro_acumulado",
	"pose_actual", "pose_con_retardo", "rayo_vision", "reposo", "reproducir_gesto", "soltar", "sostener",
]
const RULE_33_SIGNALS: Array[String] = [
	"camara_cedida", "camara_devuelta", "gesto_terminado", "objeto_soltado", "objeto_sujeto", "paso",
]


class FakeInput extends PlayerInputPort:
	var ctx: InputTypes.Context = InputTypes.Context.EXPLORACION
	var move: Vector2 = Vector2.ZERO
	var look: Vector2 = Vector2.ZERO


	func context() -> InputTypes.Context:
		return ctx


	func move_vector() -> Vector2:
		return move


	func look_delta_deg() -> Vector2:
		var out: Vector2 = look
		look = Vector2.ZERO
		return out


class FakeSurface extends SurfaceProbe:
	func floor_surface() -> StringName:
		return DEFAULT_SURFACE


class FakeAspect extends AspectSource:
	func aspect() -> float:
		return 16.0 / 9.0


class FakeProbe extends PenetrationProbe:
	func is_penetrating(_capsule_center: Vector3) -> bool:
		return false


var _log: RecordingLog
var _clock: GameClock
var _input: FakeInput
var _cfg: PlayerConfig


func before_test() -> void:
	_log = RecordingLog.new()
	_clock = auto_free(GameClock.new())
	_input = FakeInput.new()
	var res: DataResult = DataReader.new(FileStore.new(), BuildFlavor.new(true)).read_file(
			DataCatalog.Entry.new(PLAYER_JSON, PlayerSchema.new()))
	_cfg = PlayerConfig.from_dict(res.value)


## Scene instance in the tree, not yet configured; engine callbacks off.
func _scene_player() -> Player:
	var p: Player = auto_free((load(PLAYER_SCENE) as PackedScene).instantiate())
	add_child(p)
	p.set_process(false)
	p.set_physics_process(false)
	return p


func _wired_player() -> Player:
	var p: Player = _scene_player()
	p._wire(_cfg, _clock, _log, _input, FakeSurface.new(), FakeAspect.new(), FakeProbe.new())
	p.set_process(false)
	p.set_physics_process(false)
	return p


func _public_names(list: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in list:
		var n: String = entry["name"]
		if not n.begins_with("_"):
			out.append(n)
	out.sort()
	return out


func test_public_operations_equal_rule_33_plus_configurar() -> void:
	var script: GDScript = load(PLAYER_SCRIPT)
	var names: Array[String] = _public_names(script.get_script_method_list())

	names.erase("configurar") # ADR-0009 lifecycle entry, excluded explicitly
	assert_array(names).is_equal(RULE_33_OPERATIONS)
	assert_bool(script.get_script_method_list().any(func(m: Dictionary) -> bool: return m["name"] == "configurar")).is_true()


func test_signals_equal_rule_33_list() -> void:
	var script: GDScript = load(PLAYER_SCRIPT)

	assert_array(_public_names(script.get_script_signal_list())).is_equal(RULE_33_SIGNALS)


func test_no_operation_writes_pose_memory_or_state_3() -> void:
	var script: GDScript = load(PLAYER_SCRIPT)
	var names: Array[String] = _public_names(script.get_script_method_list())

	for n: String in names:
		for banned: String in ["fill", "record", "push", "reset", "set_fact", "sprint", "salto", "saltar", "agachar", "ocultar"]:
			assert_bool(n.contains(banned)).is_false()
	# AC-39: the Player neither reads nor subscribes to the game state, and it exposes no save hook.
	assert_bool(script.source_code.contains("GameState")).is_false()
	assert_bool(script.source_code.contains("ctx.state")).is_false()
	assert_bool(names.has("serializar")).is_false()
	assert_bool(names.has("save")).is_false()


func test_scene_rig_layout_and_layers() -> void:
	var p: Player = _wired_player()

	assert_object(p.get_node("%Rig")).is_instanceof(Node3D)
	assert_object(p.get_node("Rig/Look/Bob/MainCamera")).is_instanceof(Camera3D)
	var capsule: CapsuleShape3D = (p.get_node("%BodyShape") as CollisionShape3D).shape
	assert_float(capsule.radius).is_equal_approx(0.25, 0.0001)
	assert_float(capsule.height).is_equal_approx(1.75, 0.0001)
	assert_float((p.get_node("%BodyShape") as CollisionShape3D).position.y).is_equal_approx(0.875, 0.0001)
	var sensor: Area3D = p.get_node("ZoneSensor")
	assert_bool(sensor.monitorable).is_true()
	assert_int(sensor.collision_layer).is_equal(4 << 1) # layer 4 (zone_sensor) = bit value 8
	assert_float(((p.get_node("%ZoneShape") as CollisionShape3D).shape as SphereShape3D).radius).is_equal_approx(0.05, 0.0001)
	assert_float((p.get_node("%ZoneShape") as CollisionShape3D).position.y).is_equal_approx(0.90, 0.0001)
	assert_int(p.collision_layer).is_equal(2) # player_body = layer 2


func test_camera_defaults_fov_near_keep_height() -> void:
	var p: Player = _wired_player()
	var cam: Camera3D = p.get_node("%MainCamera")

	assert_float(cam.fov).is_equal_approx(70.0, 0.0001)
	assert_int(cam.keep_aspect).is_equal(Camera3D.KEEP_HEIGHT)
	assert_float(cam.near).is_equal_approx(0.05, 0.0001)
	assert_float(p.fov_actual()).is_equal_approx(70.0, 0.0001)


func test_fov_actual_includes_a_lease_in_progress() -> void:
	var p: Player = _wired_player()
	var cam: Camera3D = p.get_node("%MainCamera")
	var target: CameraPose = CameraPose.make(Vector3(0.0, 1.5, -1.0), 0.0, 0.0)
	assert_bool(p.ceder_camara(VISTA, target, 40.0, 1.0)).is_true()

	_clock.advance(0.25)
	_clock.advance(0.25)
	p._present(1.0)
	var mid: float = p.fov_actual()
	_clock.advance(0.25)
	_clock.advance(0.25)
	_clock.advance(0.25)
	p._present(1.0)

	assert_float(mid).is_between(40.0, 70.0)
	assert_float(mid).is_not_equal(70.0)
	assert_float(cam.fov).is_equal_approx(p.fov_actual(), 0.0001)
	assert_float(p.fov_actual()).is_equal_approx(40.0, 0.0001)


func test_lease_arrival_signal_comes_from_the_frame_not_the_request() -> void:
	var p: Player = _wired_player()
	var arrived: Array[StringName] = []
	p.camara_cedida.connect(func(owner: StringName) -> void: arrived.append(owner))
	var target: CameraPose = CameraPose.make(Vector3(0.0, 1.5, -1.0), 0.0, 0.0)

	p.ceder_camara(VISTA, target, 50.0, 0.0)
	assert_array(arrived).is_empty()
	p._present(1.0)

	assert_array(arrived).is_equal([VISTA])
	assert_bool(p.devolver_camara(VISTA)).is_true()


func test_rayo_vision_origin_is_physics_eyes_without_bob_while_walking() -> void:
	var p: Player = _wired_player()
	p._bob.configure(_cfg, BobMath.LEVEL_FULL, _clock.now())
	p.colocar(Vector3(3.0, 0.0, 4.0), 0.7, 0.0)
	_input.move = Vector2(0.0, 1.0)
	var bob_moved: bool = false
	var rig_differs: bool = false

	for i: int in 45:
		p._tick(DT)
		p._present(0.5)
		var ray: VisionRay = p.rayo_vision()
		var feet: Vector3 = p.global_position
		assert_float(ray.origen.x).is_equal_approx(feet.x, 0.00001)
		assert_float(ray.origen.z).is_equal_approx(feet.z, 0.00001)
		assert_float(ray.origen.y - feet.y).is_equal_approx(1.62, 0.00001)
		assert_float(ray.direccion.length()).is_equal_approx(1.0, 0.0001)
		if (p.get_node("%Bob") as Node3D).position.length() > 0.0:
			bob_moved = true
		if not (p.get_node("%Rig") as Node3D).position.is_equal_approx(Vector3(0.0, 1.62, 0.0)):
			rig_differs = true

	# The check above is only meaningful if the presented camera really moved while the ray did not.
	assert_bool(bob_moved).is_true()
	assert_bool(rig_differs).is_true()


func test_rayo_vision_direction_follows_look_and_lease() -> void:
	var p: Player = _wired_player()
	p.colocar(Vector3.ZERO, 0.0, 0.0)

	assert_vector(p.rayo_vision().direccion).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.0001)
	p.colocar(Vector3.ZERO, PI * 0.5, 0.0) # yaw +90 deg about +Y: -Z turns to -X
	assert_vector(p.rayo_vision().direccion).is_equal_approx(Vector3(-1.0, 0.0, 0.0), Vector3.ONE * 0.0001)
	p.ceder_camara(VISTA, CameraPose.make(Vector3(0.0, 1.5, 0.0), 0.0, 0.0), 70.0, 0.0)
	p._present(1.0)
	assert_vector(p.rayo_vision().direccion).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.0001)


func test_colocar_before_configurar_is_completed_on_configuration() -> void:
	var p: Player = _scene_player()
	p.colocar(Vector3(1.0, 0.0, 2.0), 0.5, 0.2)
	assert_vector(p.global_position).is_equal_approx(Vector3(1.0, 0.0, 2.0), Vector3.ONE * 0.0001)

	p._wire(_cfg, _clock, _log, _input, FakeSurface.new(), FakeAspect.new(), FakeProbe.new())
	p.set_process(false)
	p.set_physics_process(false)

	var pose: PlayerPose = p.pose_actual()
	assert_vector(pose.position).is_equal_approx(Vector3(1.0, 0.0, 2.0), Vector3.ONE * 0.0001)
	assert_float(pose.yaw).is_equal_approx(0.5, 0.0001)
	assert_float(pose.pitch).is_equal_approx(0.2, 0.0001)
	assert_float(p.giro_acumulado()).is_equal(0.0)


func test_colocar_non_finite_is_ignored() -> void:
	var p: Player = _wired_player()
	p.colocar(Vector3(1.0, 0.0, 1.0), 0.0, 0.0)

	p.colocar(Vector3(NAN, 0.0, 0.0), 0.0, 0.0)

	assert_vector(p.global_position).is_equal_approx(Vector3(1.0, 0.0, 1.0), Vector3.ONE * 0.0001)


func test_hands_operations_exist_return_false_and_log() -> void:
	var p: Player = _wired_player()

	assert_bool(p.reproducir_gesto(&"HAND_REACH")).is_false()
	assert_bool(p.sostener(&"V05", &"right", InspectionPose.new())).is_false()
	assert_bool(p.soltar()).is_false()
	assert_bool(p.girar_objeto(0.1, 0.1)).is_false()
	assert_bool(p.apuntar(Vector3.ZERO)).is_false()
	p.reposo()

	var hits: int = 0
	for l: Dictionary in _log.lines:
		if String(l[&"msg"]).contains("manos fuera de M1"):
			hits += 1
	assert_int(hits).is_equal(5)


func test_look_input_applies_only_when_free_and_is_always_consumed() -> void:
	var p: Player = _wired_player()
	p.colocar(Vector3.ZERO, 0.0, 0.0)
	_input.ctx = InputTypes.Context.MENU
	_input.look = Vector2(10.0, 0.0)

	p._frame(DT, 1.0)

	assert_vector(_input.look).is_equal(Vector2.ZERO) # consumed
	assert_float(p.pose_actual().yaw).is_equal(0.0)
	_input.ctx = InputTypes.Context.EXPLORACION
	p._tick(DT) # state polls EXPLORACION: Libre
	_input.look = Vector2(10.0, 0.0)
	p._frame(DT, 1.0)
	assert_vector(p.rayo_vision().direccion).is_not_equal(Vector3(0.0, 0.0, -1.0))


func test_project_physics_interpolation_is_explicitly_false() -> void:
	var cfg: ConfigFile = ConfigFile.new()

	assert_int(cfg.load("res://project.godot")).is_equal(OK)

	assert_bool(cfg.has_section_key("physics", "common/physics_interpolation")).is_true()
	assert_bool(cfg.get_value("physics", "common/physics_interpolation")).is_false()
