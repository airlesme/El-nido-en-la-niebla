## Full-screen black curtain above the world and the UI (GDD R11, ADR-0003, C-R12).
## Only SceneLoader writes the alpha of its ColorRect (through `set_alpha`, wired by Boot); this node
## hosts it and keeps running while the tree is paused.
class_name Curtain extends CanvasLayer


func _init() -> void:
	# C-R12: explicit, never inherited, so the fade survives pause.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Sets the opacity of the black rect, clamped to [0, 1]. Safe before `_ready` (the child exists in the scene).
## Example: `curtain.set_alpha(0.5)`.
func set_alpha(alpha: float) -> void:
	var rect: ColorRect = get_node_or_null("Rect") as ColorRect
	if rect != null:
		rect.color = Color(0.0, 0.0, 0.0, clampf(alpha, 0.0, 1.0))


## Current opacity of the black rect (0 when the rect is missing).
func get_alpha() -> float:
	var rect: ColorRect = get_node_or_null("Rect") as ColorRect
	return rect.color.a if rect != null else 0.0
