## Pose of a held object in front of the camera (ADR-0012 § Key Interfaces «InspectionPose»). Value type, no logic.
## Only named in the `sostener` signature: the hands are outside M1 (story 011 cut 1), so nothing consumes it yet.
class_name InspectionPose extends RefCounted

## Distance from the camera, metres.
var distancia_m: float = 0.0
## Object orientation.
var orientation: Quaternion = Quaternion.IDENTITY
