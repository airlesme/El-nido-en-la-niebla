# PROTOTYPE - NOT FOR PRODUCTION
extends RefCounted
## S0b-3: light audit at each camera stop (ADR-0014 D2: <= 8 visible, <= 2 shadowed, <= 14 enabled).
##  - enabled  = Light3D with is_visible_in_tree() (what zone activation controls)
##  - shadowed = Light3D with shadow_enabled over ALL lights in the instance (static rule of D2,
##               stronger than "visible"; includes lights that are currently hidden)
##  - visible  = enabled AND (its position is inside the camera frustum OR within its range of the camera).
##               Conservative approximation of "visible per view"; not a real frustum/cluster query.

const MAX_VISIBLE := 8
const MAX_SHADOWED := 2
const MAX_ENABLED := 14


static func run(tree: SceneTree, cam: Camera3D, label: String) -> String:
	var enabled := 0
	var shadowed := 0
	var visible_in_view := 0
	for n in tree.get_nodes_in_group("proto_lights"):
		var l := n as Light3D
		if l == null:
			continue
		if l.shadow_enabled:
			shadowed += 1
		if not l.is_visible_in_tree():
			continue
		enabled += 1
		var rng := 0.0
		if l is SpotLight3D:
			rng = (l as SpotLight3D).spot_range
		elif l is OmniLight3D:
			rng = (l as OmniLight3D).omni_range
		var d := cam.global_position.distance_to(l.global_position)
		if cam.is_position_in_frustum(l.global_position) or d <= rng:
			visible_in_view += 1
	var ok_v := visible_in_view <= MAX_VISIBLE
	var ok_s := shadowed <= MAX_SHADOWED
	var ok_e := enabled <= MAX_ENABLED
	var verdict := "PASS" if (ok_v and ok_s and ok_e) else "FAIL"
	return "AUDIT %s %s: visible=%d/%d shadowed=%d/%d enabled=%d/%d" % [
		verdict, label, visible_in_view, MAX_VISIBLE, shadowed, MAX_SHADOWED, enabled, MAX_ENABLED]
