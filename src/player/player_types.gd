## Pose of the player body sampled from the physics state (ADR-0012 § Key Interfaces «player_types.gd»; GDD 2 rule 29).
## Value type, no logic. Angles in radians (D4).
## TODO(ADR-0012): CameraPose, InspectionPose and VisionRay are named in the same ADR block but GDScript allows one
## `class_name` per file; they are created by the stories that consume them (owner: lead-programmer).
class_name PlayerPose extends RefCounted

## Feet position, world space, physics state.
var position: Vector3 = Vector3.ZERO
## Yaw in radians, [-PI, PI).
var yaw: float = 0.0
## Pitch in radians.
var pitch: float = 0.0
## Horizontal speed, m/s.
var speed_h: float = 0.0
## Step phase: travelled distance modulo 2 * L_paso, metres.
var step_phase: float = 0.0
