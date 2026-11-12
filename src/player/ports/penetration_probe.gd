## Port that answers whether the Player capsule is deeper than `eps_atasco_m` inside static geometry
## (ADR-0012 § Key Interfaces «PenetrationProbe», D8; TR-player-019).
## Production adapter (story 011, after the ADR-0011 layer story): `intersect_shape()` with a pre-built shrunk
## `CapsuleShape3D` (radius `r - eps`, height `h - 2 * eps`), mask = static world layers, Player excluded and an
## explicit `max_results` (S-0011-A: the default of 32 is applied silently). Never the engine penetration report (C-X14).
## Unit tests use a fake. Example: `class Fake extends PenetrationProbe: func is_penetrating(_c: Vector3) -> bool: return true`.
@abstract
class_name PenetrationProbe extends RefCounted


## True when the shrunk capsule centred at `capsule_center` (world space) overlaps static geometry.
@abstract func is_penetrating(capsule_center: Vector3) -> bool
