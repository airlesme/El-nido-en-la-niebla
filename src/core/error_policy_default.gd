## Production ErrorPolicy (ADR-0001 G-8, F-R09, V-ENG-4). The ONLY file that names the
## engine calls that stop execution. `assert` is not used: stripped in release and, in debug,
## it only aborts the current function (F-X09).
## Example: `ErrorPolicyDefault.new(BuildFlavor.new(false)).fail("x")` is a no-op.
class_name ErrorPolicyDefault extends ErrorPolicy

var _flavor: BuildFlavor


func _init(flavor: BuildFlavor) -> void:
	_flavor = flavor


## Debug: `push_error` then `quit(1)` on the main loop. Release: no-op.
func fail(msg: String) -> void:
	if not is_strict():
		return
	push_error(msg)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.quit(1)


## True when the injected BuildFlavor is debug.
func is_strict() -> bool:
	return _flavor.is_debug()
