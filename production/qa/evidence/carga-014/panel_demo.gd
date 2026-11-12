## Evidence scene (CP-014): black curtain + ErrorPanel, same layers as the Shell. Not shipped.
extends Node


func _ready() -> void:
	var curtain: CanvasLayer = CanvasLayer.new()
	curtain.layer = 100
	var rect: ColorRect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.add_child(rect)
	add_child(curtain)
	var panel: ErrorPanel = (load("res://src/shell/error_panel.tscn") as PackedScene).instantiate()
	add_child(panel)
	get_tree().paused = true
	panel.show_error(&"missing_resource")
