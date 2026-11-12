## T-I1 (ADR-0003), scope M1: Shell layout, layer order, process modes and persistence of
## autoloads while the WorldSlot swaps game scenes. No window needed.
## The real SceneLoader.load_planta does not exist yet (stories 004/005): the swap is
## done by hand under WorldSlot, which is the only thing the loader will do there.
extends GdUnitTestSuite


const SHELL_PATH: String = "res://src/shell/shell.tscn"
const SWAPS: int = 2


## Instantiates the Shell WITHOUT Boot (compose() would re-run setup() on the live autoloads).
func _make_shell() -> Shell:
	var packed: PackedScene = load(SHELL_PATH)
	var shell: Shell = packed.instantiate()
	var boot: Node = shell.get_node("Boot")
	shell.remove_child(boot)
	boot.free()
	add_child(shell)
	auto_free(shell)
	return shell


func _autoload_ids() -> PackedInt64Array:
	return PackedInt64Array([
		GameStateAutoload.get_instance_id(),
		InputRouterAutoload.get_instance_id(),
		SettingsAutoload.get_instance_id(),
		AudioDirectorAutoload.get_instance_id(),
	])


func test_shell_scene_has_boot_as_first_child() -> void:
	# Arrange
	var shell: Node = auto_free(load(SHELL_PATH).instantiate())

	# Act
	var first: Node = shell.get_child(0)

	# Assert
	assert_str(first.name).is_equal("Boot")
	assert_object(first).is_instanceof(Boot)


func test_shell_world_slot_starts_empty() -> void:
	# Arrange / Act
	var shell: Shell = _make_shell()

	# Assert
	assert_int(shell.world_slot.get_child_count()).is_equal(0)


func test_curtain_has_highest_layer_except_error_panel() -> void:
	# Arrange
	var shell: Shell = _make_shell()
	var max_other: int = -2147483648

	# Act
	for child: Node in shell.get_children():
		if child is CanvasLayer and child != shell.curtain and child != shell.error_panel:
			max_other = maxi(max_other, (child as CanvasLayer).layer)

	# Assert
	assert_int(shell.curtain.layer).is_greater(max_other)
	assert_int(shell.error_panel.layer).is_greater(shell.curtain.layer)


func test_curtain_and_error_panel_run_always_and_world_slot_inherits() -> void:
	# Arrange
	var shell: Shell = _make_shell()

	# Assert
	assert_int(shell.curtain.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_int(shell.error_panel.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_int(shell.world_slot.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)


func test_autoload_instances_survive_world_slot_swaps_with_one_scene_per_sample() -> void:
	# Arrange
	var shell: Shell = _make_shell()
	var before: PackedInt64Array = _autoload_ids()
	var max_seen: int = 0

	# Act: swap game scenes like the loader will (free old, add new), sampling each step
	for i: int in SWAPS:
		for old: Node in shell.world_slot.get_children():
			shell.world_slot.remove_child(old)
			old.free()
		max_seen = maxi(max_seen, shell.world_slot.get_child_count())
		var planta: Node3D = Node3D.new()
		planta.name = &"planta"
		shell.world_slot.add_child(planta)
		max_seen = maxi(max_seen, shell.world_slot.get_child_count())
		await get_tree().process_frame

	# Assert
	assert_array(Array(_autoload_ids())).is_equal(Array(before))
	assert_int(max_seen).is_equal(1)
	assert_int(shell.world_slot.get_child_count()).is_equal(1)
