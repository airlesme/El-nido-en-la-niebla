## Camera pose in world space (ADR-0012 § Key Interfaces «CameraPose»; D4). Value type, no logic.
## Roll does not exist: orientation is yaw and pitch only. Angles in radians.
class_name CameraPose extends RefCounted

## Eye position, metres, world space.
var position: Vector3 = Vector3.ZERO
## Yaw in radians, [-PI, PI), 0 looks along -Z.
var yaw: float = 0.0
## Pitch in radians, + = up.
var pitch: float = 0.0


## Builds a pose. Example: `CameraPose.make(Vector3(0, 1.6, 0), 0.5, -0.1)`.
static func make(p_position: Vector3, p_yaw: float, p_pitch: float) -> CameraPose:
	var pose: CameraPose = CameraPose.new()
	pose.position = p_position
	pose.yaw = p_yaw
	pose.pitch = p_pitch
	return pose
