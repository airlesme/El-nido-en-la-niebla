extends GdUnitTestSuite
## Autoload skeleton (ADR-0009 D1/D2): names, order, ALWAYS process_mode, main scene.

const EXPECTED_ORDER: Array[String] = [
	"ContentDBAutoload",
	"GameStateAutoload",
	"GameClockAutoload",
	"InputRouterAutoload",
	"SettingsAutoload",
	"AudioDirectorAutoload",
	"SaveServiceAutoload",
	"SceneLoaderAutoload",
	"SceneDirectorAutoload",
]


func _registered_autoloads() -> Array[String]:
	var names: Array[String] = []
	for prop: Dictionary in ProjectSettings.get_property_list():
		var prop_name: String = prop["name"]
		if prop_name.begins_with("autoload/"):
			names.append(prop_name.trim_prefix("autoload/"))
	return names


func _autoload_order(name: String) -> int:
	return ProjectSettings.get_order("autoload/" + name)


func test_autoload_list_has_nine_entries_in_adr_0009_order() -> void:
	# Arrange
	var names: Array[String] = _registered_autoloads()

	# Act
	names.sort_custom(func(a: String, b: String) -> bool: return _autoload_order(a) < _autoload_order(b))

	# Assert
	assert_array(names).is_equal(EXPECTED_ORDER)


func test_registered_names_end_in_autoload_and_are_enabled_singletons() -> void:
	# Arrange / Act / Assert
	for name: String in EXPECTED_ORDER:
		var value: String = ProjectSettings.get_setting("autoload/" + name)
		assert_bool(name.ends_with("Autoload")).is_true()
		assert_str(value).starts_with("*res://")


func test_every_autoload_script_declares_process_mode_always() -> void:
	# Arrange
	var scripts: Array[GDScript] = [
		ContentDB, GameState, GameClock, InputRouter, Settings,
		AudioDirector, SaveService, SceneLoader, SceneDirector,
	]

	# Act / Assert
	for script: GDScript in scripts:
		var node: Node = auto_free(script.new())
		assert_int(node.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


func test_game_clock_runs_before_every_other_node() -> void:
	# Arrange
	var clock: GameClock = auto_free(GameClock.new())

	# Act / Assert
	assert_int(clock.process_priority).is_equal(GameClock.PROCESS_PRIORITY)
	assert_int(GameClock.PROCESS_PRIORITY).is_equal(-1000)


func test_main_scene_is_registered_and_exists() -> void:
	# Arrange
	var path: String = ProjectSettings.get_setting("application/run/main_scene")

	# Act / Assert
	assert_str(path).is_equal("res://src/core/boot/main.tscn")
	assert_bool(ResourceLoader.exists(path)).is_true()
