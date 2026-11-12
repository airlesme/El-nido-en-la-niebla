extends GdUnitTestSuite
## CP-013 AC-03: every M1 element ID exists once and inside its container (prefix rule of GDD escena-de-planta R4).

const PLANTA_PATH: String = "res://src/scene/planta.tscn"
const IDS_PATH: String = "res://tests/fixtures/scene/element_ids.json"
const PREFIX_CONTAINER: Dictionary = { "V": "office", "A": "archive", "C": "corridor", "T": "corridor" }

var _ids: Dictionary = {}
var _root: Node = null


func before_test() -> void:
	_ids = JSON.parse_string(FileAccess.get_file_as_string(IDS_PATH)) as Dictionary
	_root = auto_free((load(PLANTA_PATH) as PackedScene).instantiate())


func after_test() -> void:
	_root = null
	_ids = {}


func _count_named(id: String) -> int:
	var count: int = 0
	var pending: Array[Node] = [_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if String(node.name) == id:
			count += 1
		pending.append_array(node.get_children())
	return count


func _container_ids() -> Array[String]:
	var result: Array[String] = []
	for key: String in _ids:
		if not key.begins_with("_"):
			result.append(key)
	return result


func test_every_id_exists_exactly_once_in_the_whole_scene() -> void:
	for container: String in _container_ids():
		for id: String in (_ids[container] as Array):
			assert_int(_count_named(id)).override_failure_message(id).is_equal(1)


func test_every_id_lives_inside_its_container() -> void:
	for container: String in _container_ids():
		var holder: Node = _root.get_node(container)
		for id: String in (_ids[container] as Array):
			assert_bool(holder.find_child(id, true, false) != null).override_failure_message(
					"%s not under %s" % [id, container]).is_true()


func test_container_matches_the_id_prefix() -> void:
	for container: String in _container_ids():
		for id: String in (_ids[container] as Array):
			assert_str(String(PREFIX_CONTAINER[id.substr(0, 1)])).override_failure_message(id).is_equal(container)


func test_containers_outside_m1_are_not_created() -> void:
	for absent: String in ["meeting_room", "guardian_office", "reception"]:
		assert_bool(_root.find_child(absent, true, false) == null).is_true()
