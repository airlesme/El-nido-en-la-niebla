extends GdUnitTestSuite
## CP-012: GameSceneRoot (AC-23 with the real root, required nodes) and the real SceneSource. No window.

const MINIMAL_WORLD: String = "res://tests/integration/scene/fixtures/minimal_world.tscn"

var _events: Array[String] = []


func before_test() -> void:
	_events = []


func _ctx() -> ServiceContext:
	return ServiceContext.new()


func _spy(root: Node, node_name: String, grouped: bool) -> ElementSpy:
	var spy: ElementSpy = ElementSpy.new()
	spy.name = node_name
	spy.events = _events
	root.add_child(spy)
	if grouped:
		spy.add_to_group(GameSceneRoot.ELEMENT_GROUP)
	return spy


## Root with elements added in tree order: Other (group), Seven, Nine; 7 and 9 listed in configure_first.
func _root_with_spies() -> GameSceneRoot:
	var root: GameSceneRoot = GameSceneRoot.new()
	add_child(root)
	auto_free(root)
	_spy(root, "Other", true)
	_spy(root, "Seven", true) # also in the group: must be configured once
	_spy(root, "Nine", true)
	root.configure_first = [^"Seven", ^"Nine"] as Array[NodePath]
	return root


func test_configure_all_runs_seven_then_validation_of_nine_then_nine_then_rest() -> void:
	var root: GameSceneRoot = _root_with_spies()

	var result: GameSceneRoot.ConfigureResult = root.configure_all(_ctx())

	assert_int(result).is_equal(GameSceneRoot.ConfigureResult.OK)
	assert_array(_events).is_equal([
		"configure:Seven", "failed?:Seven",
		"configure:Nine", "failed?:Nine",
		"configure:Other",
	])


func test_configure_all_with_failing_nine_returns_invalid_and_skips_the_rest() -> void:
	var root: GameSceneRoot = _root_with_spies()
	(root.get_node(^"Nine") as ElementSpy).failing = true

	var result: GameSceneRoot.ConfigureResult = root.configure_all(_ctx())

	assert_int(result).is_equal(GameSceneRoot.ConfigureResult.INVALID_PUZZLE_DATA)
	assert_bool(_events.has("configure:Other")).is_false()
	assert_array(_events).contains(["configure:Nine", "failed?:Nine"])


func test_configure_all_with_empty_configure_first_configures_the_group() -> void:
	var root: GameSceneRoot = GameSceneRoot.new()
	add_child(root)
	auto_free(root)
	_spy(root, "A", true)
	_spy(root, "B", true)

	var result: GameSceneRoot.ConfigureResult = root.configure_all(_ctx())

	assert_int(result).is_equal(GameSceneRoot.ConfigureResult.OK)
	assert_array(_events).is_equal(["configure:A", "configure:B"])


func test_configure_all_ignores_group_members_outside_the_root() -> void:
	var root: GameSceneRoot = GameSceneRoot.new()
	add_child(root)
	auto_free(root)
	var stranger: ElementSpy = _spy(self, "Stranger", true)
	auto_free(stranger)

	root.configure_all(_ctx())

	assert_array(_events).is_empty()


func _world_with(names: Array[String]) -> GameSceneRoot:
	var root: GameSceneRoot = GameSceneRoot.new()
	for node_name: String in names:
		var child: Node3D = Node3D.new()
		child.name = node_name
		root.add_child(child)
	add_child(root)
	auto_free(root)
	return root


func test_validate_required_nodes_with_all_m1_nodes_returns_empty() -> void:
	var root: GameSceneRoot = _world_with(
			["office", "corridor", "archive", "spawn_office", "door_slot_a", "drawer_slot_a05"])

	assert_bool(root.validate_required_nodes().is_empty()).is_true()


func test_validate_required_nodes_lists_each_missing_node() -> void:
	for missing: String in ["spawn_office", "office", "corridor", "archive"]:
		var present: Array[String] = ["office", "corridor", "archive", "spawn_office",
				"door_slot_a", "drawer_slot_a05"]
		present.erase(missing)
		var root: GameSceneRoot = _world_with(present)

		assert_array(root.validate_required_nodes()).is_equal([missing])


func test_validate_required_nodes_finds_nested_nodes() -> void:
	var root: GameSceneRoot = GameSceneRoot.new()
	root.required_nodes = PackedStringArray(["deep"])
	var a: Node3D = Node3D.new()
	a.name = "a"
	var deep: Node3D = Node3D.new()
	deep.name = "deep"
	a.add_child(deep)
	root.add_child(a)
	add_child(root)
	auto_free(root)

	assert_bool(root.validate_required_nodes().is_empty()).is_true()


func test_getters_return_player_and_hub_by_default_paths() -> void:
	var root: GameSceneRoot = GameSceneRoot.new()
	var player: Node = Node.new()
	player.name = "Player"
	root.add_child(player)
	var hub: ZoneHub = ZoneHub.new()
	hub.name = "ZoneHub"
	root.add_child(hub)
	add_child(root)
	auto_free(root)

	assert_object(root.get_player()).is_same(player)
	assert_object(root.get_zone_hub()).is_same(hub)


func test_scene_source_instantiates_a_packed_scene_from_its_path() -> void:
	var source: SceneSource = SceneSource.new()
	source.paths = {&"planta": MINIMAL_WORLD}

	var node: Node = source.instantiate(&"planta")

	assert_object(node).is_not_null()
	assert_str(node.name).is_equal("MinimalWorld")
	node.free()


func test_scene_source_with_missing_path_returns_null() -> void:
	var source: SceneSource = SceneSource.new()
	source.paths = {&"planta": "res://tests/integration/scene/fixtures/does_not_exist.tscn"}

	assert_object(source.instantiate(&"planta")).is_null()


func test_scene_source_with_non_scene_resource_returns_null() -> void:
	var source: SceneSource = SceneSource.new()
	source.paths = {&"planta": "res://src/scene/scene_source.gd"}

	assert_object(source.instantiate(&"planta")).is_null()


func test_scene_source_with_unknown_destination_returns_null() -> void:
	assert_object(SceneSource.new().instantiate(&"nowhere")).is_null()
