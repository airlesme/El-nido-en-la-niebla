extends GdUnitTestSuite
## Probe: with W held at several yaws, the real body displacement must point where the camera looks.

const PLAYER_SCENE: String = "res://src/player/player.tscn"
const PLAYER_JSON: String = "player/player.json"


class FakeInput extends PlayerInputPort:
	var move: Vector2 = Vector2(0.0, 1.0)
	func context() -> InputTypes.Context:
		return InputTypes.Context.EXPLORACION
	func move_vector() -> Vector2:
		return move
	func look_delta_deg() -> Vector2:
		return Vector2.ZERO


class FakeSurface extends SurfaceProbe:
	func floor_surface() -> StringName:
		return DEFAULT_SURFACE


class FakeAspect extends AspectSource:
	func aspect() -> float:
		return 16.0 / 9.0


class FakeProbe extends PenetrationProbe:
	func is_penetrating(_c: Vector3) -> bool:
		return false


func _run(yaw: float) -> Array[float]:
	var floor_body: StaticBody3D = auto_free(StaticBody3D.new())
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(100.0, 0.2, 100.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.1, 0.0)
	floor_body.add_child(shape)
	add_child(floor_body)
	var log: RecordingLog = RecordingLog.new()
	var clock: GameClock = auto_free(GameClock.new())
	var res: DataResult = DataReader.new(FileStore.new(), BuildFlavor.new(true)).read_file(
			DataCatalog.Entry.new(PLAYER_JSON, PlayerSchema.new()))
	var cfg: PlayerConfig = PlayerConfig.from_dict(res.value)
	var p: Player = auto_free((load(PLAYER_SCENE) as PackedScene).instantiate())
	add_child(p)
	p.set_process(false)
	p.set_physics_process(false)
	p._wire(cfg, clock, log, FakeInput.new(), FakeSurface.new(), FakeAspect.new(), FakeProbe.new())
	p.set_process(false)
	p.set_physics_process(false)
	p.colocar(Vector3.ZERO, yaw, 0.0)
	var start: Vector3 = p.global_position
	for i: int in 90:
		p._tick(1.0 / 60.0)
	p._present(1.0)
	var disp: Vector3 = p.global_position - start
	var cam_fwd: Vector3 = -p.get_node("%MainCamera").global_basis.z
	cam_fwd.y = 0.0
	disp.y = 0.0
	var ang: float = rad_to_deg(disp.signed_angle_to(cam_fwd, Vector3.UP))
	return [ang, disp.length()]


func test_forward_matches_camera_for_several_yaws() -> void:
	for yaw: float in [0.0, 0.56, -0.9, 1.5, 3.0]:
		var r: Array[float] = _run(yaw)
		assert_float(r[1]).is_greater(0.5)
		assert_float(absf(r[0])).is_less(1.0)
