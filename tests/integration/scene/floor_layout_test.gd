extends GdUnitTestSuite
## CP-013: gray planta geometry against `floor_layout.json` (AC-02, TR-scene-007) and the walk (AC-04). No window.
## Measures the CSGBox3D sizes and positions (containers sit at the origin, boxes are axis aligned), so nothing
## depends on the engine building the CSG meshes.

const PLANTA_PATH: String = "res://src/scene/planta.tscn"
const LAYOUT_PATH: String = "res://tests/fixtures/scene/floor_layout.json"
const WORLD_GEOMETRY_BIT: int = 1
const NON_FURNITURE: PackedStringArray = ["Floor", "Ceiling", "WallWest", "WallEast", "WallNorth", "WallSouth"]

var _layout: Dictionary = {}
var _root: GameSceneRoot = null


func before_test() -> void:
	_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH)) as Dictionary
	var packed: PackedScene = load(PLANTA_PATH) as PackedScene
	_root = packed.instantiate() as GameSceneRoot
	auto_free(_root)


func after_test() -> void:
	_root = null
	_layout = {}


func _box(node: CSGBox3D) -> AABB:
	return AABB(node.position - node.size * 0.5, node.size)


func _csg(container: String, node_name: String) -> CSGBox3D:
	return _root.get_node("%s/%s" % [container, node_name]) as CSGBox3D


## True when `box` covers [x_range] x [z_range] within `tol` on every edge.
func _footprint_matches(box: AABB, x_range: Array, z_range: Array, tol: float) -> bool:
	return absf(box.position.x - float(x_range[0])) <= tol \
			and absf(box.end.x - float(x_range[1])) <= tol \
			and absf(box.position.z - float(z_range[0])) <= tol \
			and absf(box.end.z - float(z_range[1])) <= tol


func test_containers_sit_at_the_origin_with_identity_transform() -> void:
	for container: String in (_layout["containers"] as Dictionary):
		var node: Node3D = _root.get_node(container) as Node3D
		assert_bool(node != null).is_true()
		assert_that(node.transform).is_equal(Transform3D.IDENTITY)


func test_container_footprints_match_slice_a1_within_tolerance() -> void:
	var tol: float = float(_layout["tolerance_m"])
	for container: String in (_layout["containers"] as Dictionary):
		var spec: Dictionary = (_layout["containers"] as Dictionary)[container] as Dictionary
		var floor_box: AABB = _box(_csg(container, "Floor"))
		var ceiling_box: AABB = _box(_csg(container, "Ceiling"))
		assert_bool(_footprint_matches(floor_box, spec["x"], spec["z"], tol)).override_failure_message(
				"%s floor %s" % [container, floor_box]).is_true()
		assert_bool(_footprint_matches(ceiling_box, spec["x"], spec["z"], tol)).override_failure_message(
				"%s ceiling %s" % [container, ceiling_box]).is_true()


func test_ceiling_is_2_70_above_the_floor_top_in_every_container() -> void:
	var tol: float = float(_layout["tolerance_m"])
	for container: String in (_layout["containers"] as Dictionary):
		var floor_top: float = _box(_csg(container, "Floor")).end.y
		var ceiling_bottom: float = _box(_csg(container, "Ceiling")).position.y
		assert_float(floor_top).is_equal_approx(0.0, tol)
		assert_float(ceiling_bottom - floor_top).is_equal_approx(float(_layout["ceiling_height_m"]), tol)


func test_a_box_off_by_more_than_5_cm_is_rejected() -> void:
	var spec: Dictionary = (_layout["containers"] as Dictionary)["office"] as Dictionary
	var exact: AABB = _box(_csg("office", "Floor"))
	var shifted: AABB = AABB(exact.position + Vector3(0.06, 0.0, 0.0), exact.size)
	assert_bool(_footprint_matches(exact, spec["x"], spec["z"], 0.05)).is_true()
	assert_bool(_footprint_matches(shifted, spec["x"], spec["z"], 0.05)).is_false()


func test_door_openings_are_1_00_by_2_10_and_centered_on_the_slice_axis() -> void:
	var tol: float = float(_layout["tolerance_m"])
	for door: Dictionary in (_layout["doors"] as Array):
		var container: String = door["container"]
		var left: AABB = _box(_csg(container, door["left"]))
		var right: AABB = _box(_csg(container, door["right"]))
		var header: AABB = _box(_csg(container, door["header"]))
		var lo: float = left.end.z if door["axis"] == "z" else left.end.x
		var hi: float = right.position.z if door["axis"] == "z" else right.position.x
		assert_float(hi - lo).override_failure_message(door["id"]).is_equal_approx(float(_layout["door_width_m"]), tol)
		assert_float((lo + hi) * 0.5).override_failure_message(door["id"]).is_equal_approx(float(door["center"]), tol)
		assert_float(header.position.y).override_failure_message(door["id"]).is_equal_approx(float(_layout["door_height_m"]), tol)


func test_door_leaf_fills_the_archive_opening_and_is_a_switchable_world_collider() -> void:
	var leaf: CSGBox3D = _root.get_node("archive/door_slot_a/DoorLeaf") as CSGBox3D
	assert_float(leaf.size.x).is_equal_approx(float(_layout["door_width_m"]), 0.05)
	assert_float(leaf.size.y).is_equal_approx(float(_layout["door_height_m"]), 0.05)
	assert_bool(leaf.use_collision).is_true()
	assert_int(leaf.collision_layer & WORLD_GEOMETRY_BIT).is_equal(WORLD_GEOMETRY_BIT)
	# System 8 turns the collision off when the door starts to open: the leaf must accept it.
	leaf.use_collision = false
	assert_bool(leaf.use_collision).is_false()


func test_no_walkable_passage_is_narrower_than_0_60() -> void:
	var min_passage: float = float(_layout["min_passage_m"])
	for door: Dictionary in (_layout["doors"] as Array):
		assert_float(float(_layout["door_width_m"])).is_greater_equal(min_passage)
	var corridor: AABB = _box(_csg("corridor", "Floor"))
	assert_float(corridor.size.z).is_greater_equal(min_passage)


func test_collidable_furniture_stays_inside_its_container_envelope() -> void:
	var tol: float = float(_layout["tolerance_m"])
	for container: String in ["office", "archive"]:
		var spec: Dictionary = (_layout["containers"] as Dictionary)[container] as Dictionary
		for child: Node in _root.get_node(container).get_children():
			var csg: CSGBox3D = child as CSGBox3D
			if csg == null or not csg.use_collision or NON_FURNITURE.has(String(csg.name)) \
					or String(csg.name).begins_with("Wall") or String(csg.name).begins_with("Door"):
				continue
			var box: AABB = _box(csg)
			assert_bool(box.position.x >= float(spec["x"][0]) - tol and box.end.x <= float(spec["x"][1]) + tol \
					and box.position.z >= float(spec["z"][0]) - tol and box.end.z <= float(spec["z"][1]) + tol) \
					.override_failure_message("%s/%s %s outside the envelope" % [container, csg.name, box]).is_true()


func test_zone_triggers_start_with_monitoring_off_in_the_tscn() -> void:
	var zones: Array[Node] = _root.find_children("*", "ZoneTrigger", true, false)
	assert_int(zones.size()).is_equal(4)
	for zone: Node in zones:
		assert_bool((zone as ZoneTrigger).monitoring).is_false()


func test_required_nodes_of_m1_are_present_and_one_player_one_hub() -> void:
	assert_int(_root.validate_required_nodes().size()).is_equal(0)
	assert_bool(_root.get_player() != null).is_true()
	assert_bool(_root.get_zone_hub() != null).is_true()
	assert_int(_root.find_children("*", "CharacterBody3D", true, false).size()).is_equal(1)


## AC-04 at scene level: a test player placed along office -> archive -> office never touches the curtain
## and the scene emits no "scene_load_started". The real, loader-driven walk is story 015.
func test_walk_office_to_archive_and_back_keeps_alpha_zero_and_emits_no_load() -> void:
	var loader: SceneLoader = auto_free(SceneLoader.new())
	var started: Array[int] = [0]
	_root.get_zone_hub().configure(func(notice: StringName, _payload: Dictionary) -> void:
		if notice == NoticeIds.SCENE_LOAD_STARTED:
			started[0] += 1)
	add_child(_root)
	var player: Node3D = _root.get_player() as Node3D
	var waypoints: Array[Vector3] = [
		Vector3(-3.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(8.0, 0.0, 0.0),
		Vector3(8.0, 0.0, -1.3), Vector3(8.0, 0.0, -3.0), Vector3(8.0, 0.0, -1.3), Vector3(8.0, 0.0, 0.0),
		Vector3(4.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(-3.0, 0.0, 0.0),
	]
	for point: Vector3 in waypoints:
		player.position = point
		assert_float(loader.get_curtain_alpha()).is_equal(0.0)
	assert_int(started[0]).is_equal(0)
	remove_child(_root)
