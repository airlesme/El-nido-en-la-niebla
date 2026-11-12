## Production adapter of `AspectSource`: the visible rect of a viewport (ADR-0012 D3, NP-9).
## Example: `var src: AspectSource = ViewportAspectSource.new(get_viewport())`.
class_name ViewportAspectSource extends AspectSource

var _viewport: Viewport


func _init(viewport: Viewport) -> void:
	_viewport = viewport


## Width / height of the viewport's visible rect; `FALLBACK_ASPECT` if the viewport is gone or has no height.
func aspect() -> float:
	if not is_instance_valid(_viewport):
		return FALLBACK_ASPECT
	var size: Vector2 = _viewport.get_visible_rect().size
	if size.y <= 0.0:
		return FALLBACK_ASPECT
	return size.x / size.y
