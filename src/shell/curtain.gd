## Full-screen black curtain above the world and the UI (GDD R11, ADR-0003, C-R12).
## Only SceneLoader writes the alpha of its ColorRect (story 005); this node just hosts it
## and keeps running while the tree is paused.
class_name Curtain extends CanvasLayer


func _init() -> void:
	# C-R12: explicit, never inherited, so the fade survives pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
