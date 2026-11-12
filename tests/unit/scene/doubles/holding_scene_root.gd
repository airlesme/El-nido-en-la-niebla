## Scene root double that takes holds on the loader during `configure_all` (step 6).
class_name HoldingSceneRoot extends SceneRootDouble

var loader: SceneLoader
var hold_ids: Array[StringName] = []


func configure_all(ctx: ServiceContext) -> int:
	var result: int = super.configure_all(ctx)
	for id: StringName in hold_ids:
		loader.take_hold(id)
	return result
