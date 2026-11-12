extends GdUnitTestSuite
## CP-014: ErrorPanel shows the single action, calls the unload port, works with the tree paused.

const PANEL_PATH: String = "res://src/shell/error_panel.tscn"

var _unloads: int = 0
var _unload_result: bool = true
var _requested: int = 0
var _added_action: bool = false


func before_test() -> void:
	_unloads = 0
	_unload_result = true
	_requested = 0
	_added_action = false


func after_test() -> void:
	get_tree().paused = false
	if _added_action:
		InputMap.erase_action(ErrorPanel.ACTION_ACCEPT)


func _unload() -> bool:
	_unloads += 1
	return _unload_result


func _on_requested() -> void:
	_requested += 1


func _make() -> ErrorPanel:
	var panel: ErrorPanel = auto_free((load(PANEL_PATH) as PackedScene).instantiate())
	add_child(panel)
	panel.set_unload_port(_unload)
	panel.return_to_title_requested.connect(_on_requested)
	return panel


func test_hidden_until_shown_and_always_process() -> void:
	var panel: ErrorPanel = _make()
	assert_bool(panel.is_showing()).is_false()
	assert_int(panel.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_int(panel.layer).is_equal(110)
	panel.show_error(&"missing_resource")
	assert_bool(panel.is_showing()).is_true()
	assert_str(String(panel.get_cause())).is_equal("missing_resource")
	assert_str((panel.get_node("%Action") as Button).text).is_equal("Volver al título")


func test_button_press_requests_full_unload_with_tree_paused() -> void:
	var panel: ErrorPanel = _make()
	get_tree().paused = true
	panel.show_error(&"missing_resource")
	assert_bool(panel.is_showing()).is_true()
	(panel.get_node("%Action") as Button).pressed.emit()
	assert_int(_unloads).is_equal(1)
	assert_int(_requested).is_equal(1)
	assert_bool(panel.is_showing()).is_false()


func test_rejected_unload_keeps_panel_open() -> void:
	var panel: ErrorPanel = _make()
	_unload_result = false
	panel.show_error(&"timeout")
	(panel.get_node("%Action") as Button).pressed.emit()
	assert_int(_unloads).is_equal(1)
	assert_int(_requested).is_equal(0)
	assert_bool(panel.is_showing()).is_true()


func test_ui_aceptar_accepts_and_other_actions_do_nothing() -> void:
	if not InputMap.has_action(ErrorPanel.ACTION_ACCEPT):
		InputMap.add_action(ErrorPanel.ACTION_ACCEPT)
		_added_action = true
	InputMap.add_action(&"test_pausa_cp014")
	var panel: ErrorPanel = _make()
	panel.show_error(&"missing_resource")
	var other: InputEventAction = InputEventAction.new()
	other.action = &"test_pausa_cp014"
	other.pressed = true
	panel._unhandled_input(other)
	InputMap.erase_action(&"test_pausa_cp014")
	assert_int(_unloads).is_equal(0)
	var accept: InputEventAction = InputEventAction.new()
	accept.action = ErrorPanel.ACTION_ACCEPT
	accept.pressed = true
	panel._unhandled_input(accept)
	assert_int(_unloads).is_equal(1)
	assert_int(_requested).is_equal(1)


func test_hidden_panel_ignores_accept() -> void:
	var panel: ErrorPanel = _make()
	panel._accept()
	assert_int(_unloads).is_equal(0)
