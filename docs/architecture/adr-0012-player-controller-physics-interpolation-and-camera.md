# ADR-0012: Player Controller, Physics Interpolation and Camera

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` until it is `Accepted`, and it
> cannot be `Accepted` before spikes S-0012-A…F (§ Validation Criteria) have run
> on Godot 4.7.2 and their results are recorded in § Spike Results.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `design/gdd/jugador-en-primera-persona.md` (GDD 2, state
after correction round 6 / D-44), `docs/architecture/tr-baseline-provisional.md`
(TR-player-001…021, TR-scene-007), ADR-0002 / 0003 / 0006 / 0009 (all
`Proposed`) and `adr-reconciliation-2026-11-10.md`. Engine claims checked
against `docs/engine-reference/godot/` (pin 4.7.2); everything not covered
there is marked NOT SOURCEABLE.

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation:
autonomous`); final acceptance: the user.

## Summary

GDD 2 needs a first-person body that walks at one slow speed with short
acceleration, never jitters against walls, shows the same distance per second
at 30, 60 and 144 fps, lends its camera to 7 with a bounded handshake, keeps a
1 s pose history for 28's delayed reflection, rescues itself from geometry
traps and runs a two-slot hand-gesture machine — all pause-correct under
ADR-0002. This ADR decides: a `CharacterBody3D` on Jolt that is **never
rotated**, stepped at a fixed 60 Hz with `move_and_slide()`; **engine physics
interpolation off** and an **own one-tick-latency interpolator** for the
camera/hands rig only (no exponential smoothing); vertical FOV through F5 with
`keep_aspect` = keep height (spike); a camera-lease state machine on game
time; a column ring buffer for poses; a shrunk-capsule overlap probe for the
safety net; and a pure-logic `HandSlots` machine whose blocking gestures end on
`GameClock` deadlines while animations are advanced manually.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Physics (primary) · Rendering (camera) · Animation (hands) · Core |
| **Layer** | Core (GDD 2 Quick reference: Layer `Core`; ADR-0009 D4 sub-layer C2) |
| **Knowledge Risk** | HIGH — Jolt became default in 4.6, 3D physics interpolation was rearchitected in 4.5, and `Camera3D`, `keep_aspect`, shape queries, `AnimationMixer` manual advance and the physics/process callback order are not covered by the engine reference (see table below) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/physics.md`; `modules/animation.md`; `modules/rendering.md` (no camera content); `breaking-changes.md` (row "3D interpolation rearchitected") |
| **Post-Cutoff APIs Used** | Jolt as 3D physics engine (4.6 default; `project.yaml` `physics: "Jolt"`); `@abstract` on port classes (4.5, VERSION.md; same convention as ADR-0009 D5); `TwoBoneIK` / `LookAtModifier3D` (4.6 / 4.7, `modules/animation.md`) for `apuntar` only. The decision deliberately **avoids** depending on the 4.5 interpolation API |
| **Verification Required** | S-0012-A callback order and own interpolation at 30/60/144 fps; S-0012-B `keep_aspect` and FOV axis; S-0012-C Jolt `CharacterBody3D` slide/jitter/floor; S-0012-D shrunk-capsule overlap query; S-0012-E `AnimationMixer` manual advance; S-0012-F engine interpolation default and a regression of ADR-0002 S11 with it off |

> Knowledge Risk is HIGH: if the project leaves 4.7.x, this ADR is re-validated
> (spikes re-run) before any Player story continues.

### Engine API sourcing

Sourced claims (the only ones):

| Claim | Source |
|---|---|
| `CharacterBody3D` with `velocity`, `move_and_slide()`, `is_on_floor()`, `get_gravity()` inside `_physics_process(delta)`; API unchanged across Jolt and GodotPhysics3D | `modules/physics.md` § Basic Physics Setup |
| Jolt is the default 3D engine since 4.6; existing projects keep their setting; "collision margins may behave differently" | `modules/physics.md` § 4.6, § Jolt vs GodotPhysics3D |
| Jolt `Area3D` overlap reporting changed in 4.7 (SoftBody); filter with layers/masks | `modules/physics.md` § 4.7 |
| `PhysicsDirectSpaceState3D.intersect_ray()` with `PhysicsRayQueryParameters3D.create()` and `collision_mask` | `modules/physics.md` § Raycasting |
| 3D physics interpolation moved from `RenderingServer` to `SceneTree` in 4.5; "user-facing API unchanged, internal behaviour may differ in edge cases" | `modules/physics.md` § 4.5; `breaking-changes.md` |
| `AnimationMixer` is the base of `AnimationPlayer` / `AnimationTree`; `active` (not `playback_active`); `callback_mode_method` | `modules/animation.md` § 4.3 |
| IK via `SkeletonModifier3D` children of `Skeleton3D` (`TwoBoneIK`, …); `LookAtModifier3D.relative` defaults to `false` in 4.7 | `modules/animation.md` § 4.6, § 4.7 |

NOT SOURCEABLE (each one has a spike or a fallback; none is used without it):

| # | Claim this ADR relies on | Status | Spike |
|---|---|---|---|
| NP-1 | Within one rendered frame, all pending `_physics_process` ticks run **before** `_process`; at 30 fps two ticks run per frame, at 144 fps most frames run zero ticks | NOT SOURCEABLE — main-loop callback order not covered by `docs/engine-reference/godot/` | S-0012-A |
| NP-2 | Project setting for the physics tick rate (`physics/common/physics_ticks_per_second` or equivalent) and its read-back at runtime (`Engine.physics_ticks_per_second`) | NOT SOURCEABLE — tick-rate setting not covered by `docs/engine-reference/godot/modules/physics.md` | S-0012-A |
| NP-3 | Project setting that enables/disables 3D physics interpolation, its **default** in a new 4.7 project, per-node opt-out, `get_global_transform_interpolated()`, `reset_physics_interpolation()`, `Engine.get_physics_interpolation_fraction()` | NOT SOURCEABLE — `modules/physics.md` only records the 4.5 relocation, no API names or defaults | S-0012-F (only to prove it is **off**; none of these APIs is used) |
| NP-4 | `Camera3D.fov` is in degrees and `Camera3D.keep_aspect` = keep height makes it the **vertical** angle; `Camera3D.near`; `make_current()` | NOT SOURCEABLE — `docs/engine-reference/godot/` has no camera module (`rendering.md` only mentions `Camera3D` as a `Compositor` host) | S-0012-B |
| NP-5 | Jolt `CharacterBody3D` slides along a wall without bounce and without sub-millimetre oscillation when pushed head-on; stays on a flat floor without `floor_snap_length` tuning | NOT SOURCEABLE — slide quality under Jolt not covered by `modules/physics.md` (only the API) | S-0012-C |
| NP-6 | A boolean overlap query of a `CapsuleShape3D` against static geometry (`PhysicsDirectSpaceState3D.intersect_shape()` with `PhysicsShapeQueryParameters3D`, `exclude`, `collision_mask`) works under Jolt | NOT SOURCEABLE — only `intersect_ray` is in `modules/physics.md`; ADR-0011 spikes `intersect_shape` with Jolt for 7 | S-0012-D (shared with ADR-0011) |
| NP-7 | `AnimationMixer` can be put in a manual process mode (`callback_mode_process` = manual) and advanced with `advance(delta)`; `AnimationTree` state/blend parameters set from code | NOT SOURCEABLE — `modules/animation.md` covers `callback_mode_method` only | S-0012-E |
| NP-8 | Reading the floor's surface label: `get_slide_collision()` / `KinematicCollision3D.get_collider()` and `Object.get_meta()` | NOT SOURCEABLE — slide-collision introspection not covered by `modules/physics.md` | S-0012-C (case 6) |
| NP-9 | Viewport aspect from `get_viewport().get_visible_rect().size` (and a size-changed signal) under ADR-0007's stretch mode | NOT SOURCEABLE — viewport size API not covered by `docs/engine-reference/godot/` | S-0012-B |
| NP-10 | `Area3D` with `monitorable = true` on layer `zone_sensor`, `SphereShape3D` radius 0,05 m detected by zone `Area3D`s under Jolt | NOT SOURCEABLE here; owned and spiked by ADR-0003 (S-0003-B) | — (ADR-0003) |

GDScript core built-ins (`Vector2/3` maths, `move_toward`, `lerp`, `wrapf`,
`clampf`, `is_finite`, `deg_to_rad`) are assumed unchanged since 4.3; the spike
project's parse check confirms them and is not counted as evidence of anything
else.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 Pause and game time (`GameClock.now()/delta()/is_paused()`, G-1, G-4, `WorldSlot` `PAUSABLE`; this ADR closes its OI-4) · ADR-0003 Scene loading (per-scene `Player`, step 5 `colocar(anchor.global_position, anchor.global_rotation.y, 0.0)`, `zone_sensor`; this ADR closes its O6 and R5) · ADR-0006 Input (`get_move_vector()`, `consume_look_delta()` in degrees, `top()`, contexts enum) · ADR-0009 Service composition (`configurar(ctx)`, `SceneServices.player`, C2 sub-layer, contract signals, `@abstract` ports) · ADR-0005 Data schema (`player/player.json`, fatal `CATALOGO_INVALIDO` with parameter) · ADR-0007 Settings (`balanceo_camara`, `campo_vision` reader and change subscription ‡) |
| **Enables** | ADR-0011 (7 consumes `rayo_vision()`, `fov_actual()`, camera lease, hand gestures) · ADR-0013 (hands rendering plugs into the `HandsRig` node defined here, with `fov_manos`) · ADR-0014 (28 consumes `pose_con_retardo()`, `giro_acumulado()`) · ADR-0008 (23 consumes `paso` and the listener from `rayo_vision()`) |
| **Blocks** | Epic "Jugador en primera persona" (all stories); M1 grey-box walk; 7's focus and view stories; 28's reflection story |
| **Ordering Note** | S-0012-D shares its probe with ADR-0011's `intersect_shape` spike: run once, record in both. S-0012-E overlaps ADR-0002 S6/SB2: if ADR-0002 S6 passes, this ADR still keeps manual advance (D9) because the gesture deadline must not depend on the tree. Amendments requested from ADR-0003, ADR-0008 and ADR-0009 are listed in § Open Items; none changes their decisions |

## Context

### Problem Statement

The slice is played entirely from Vera's eyes (GDD 2 Overview). Pillar 4
*Tensión sin castigo* turns comfort into hard requirements: no roll, no camera
moved by events, no added look latency, bob reducible to exactly zero, and the
same walking speed whatever the frame rate. At the same time five systems
consume the Player synchronously (4 places it, 7 aims and borrows the camera,
8/19/20/22 request hand gestures, 23 hears steps, 28 reads delayed poses), so
its API is a closed list checked by equality (rule 33, AC-04). GDD 2 Open
Question 3 delegates three engine questions here: whether 3D physics
interpolation is reliable on `CharacterBody3D` in 4.7, how `keep_aspect` makes
the FOV vertical, and which query yields capsule penetration for the trap
rule. ADR-0002 (OI-4) and ADR-0003 (O6, R5) are waiting on this ADR for the
interpolation-under-pause and teleport-reset behaviour and for `colocar`'s
angle units.

### Current State

No Player code exists (`src/` holds no player module). GDD 2 is complete and
reviewed; its Detailed Rules, Formulas F1–F10 and ACs 01–51 are the source.
ADR-0003 already calls `colocar(anchor.global_position,
anchor.global_rotation.y, 0.0)` — i.e. radians — before the scene's
`configurar()` pass; ADR-0009 already lists `SceneServices.player: Player` and
the allowed calls 4 → 2, 7 → 2, 20 → 2, 28 → 2; ADR-0008 already connects
`on_paso(superficie, intensidad)` and asks for `listener_position()`.

### Constraints

- **Engine:** Godot 4.7.2, GDScript, Jolt (`project.yaml`). Only the APIs in
  § Engine API sourcing may be relied on without a spike.
- **Time:** all game-time logic reads the injected `GameClock` (ADR-0002 G-1);
  every `_physics_process` that moves a body starts with the pause guard
  (G-4); no `Timer` / `create_timer()` / `Engine.time_scale` (G-3).
- **Composition:** `_ready()` local only; dependencies through
  `configurar(ctx)`; the Player is C2 and may call only lower layers
  (1 `InputRouter`, `GameClock`, 6 `Settings`, 18 `ContentDB`); everything it
  tells upper layers goes through contract signals (ADR-0009 D4).
- **Closed API** (GDD 2 rule 33, TR-player-020): 14 operations and 6 signals,
  nothing else public. Public names stay as the GDD literal (Spanish, like
  `colocar` in ADR-0003); internals are English.
- **Data:** every feel/curve/gate value in `assets/data/player/player.json`
  (TR-player-021), validated at boot (TR-player-002, ADR-0005).
- **Testing:** logic is unit-testable headless with an injected clock (integer
  physics ticks), fake input and fake collision (GDD 2 AC preamble).
- **Team/schedule:** one programmer; M1 needs walking in the grey box first, so
  the decision must allow locomotion stories to start before hands rendering
  (ADR-0013) is decided.

### Requirements

- Same distance per second at 30, 60 and 144 fps; corridor 24 m in 15,1 ± 0,3 s
  (AC-06, TR-player-004).
- Presentation (camera, hands) smooth between physics ticks; services (ray
  origin, zone sensor, pose memory) read the un-interpolated physics state;
  look applied per frame (TR-player-005).
- Pause freezes movement, braking, interpolations, bob, gestures and transfers
  and resumes without a pop (TR-player-015, ADR-0002 S11).
- `colocar` resets everything in the same tick, including interpolation
  (TR-player-018, ADR-0003 R5).
- Vertical FOV with the F5 horizontal cap, applied in the frame it changes
  (TR-player-008).
- Camera lease with one owner, F9 Euler interpolation, roll = 0 always
  (TR-player-007, -013).
- Pose ring of 62 samples, no out-of-bounds read at τ = `T_hist`
  (TR-player-016); `giro_acumulado()` over 0,5 s (TR-player-017).
- Trap/fall safety net that does not depend on an engine "penetration" signal
  (TR-player-019, D-23).
- Hand slots with background/blocking gestures, suspension and resumption, no
  queue, 3 s cap (TR-player-011, -012).
- Provisional performance budget (GDD 2 has none; § Performance Implications).

## Decision

### D1 — Body: an un-rotated `CharacterBody3D` on Jolt, `move_and_slide()` at 60 Hz

`Player` (`src/player/player.gd`, `class_name Player extends CharacterBody3D`)
is the scene's single body. Its origin is at the **feet**; a `CapsuleShape3D`
of radius `radio_capsula` 0,25 m and height `altura_capsula` 1,75 m is offset
up by half the height. The body node is **never rotated**: yaw and pitch are
two `float`s owned by the Player (radians) and applied only to the
presentation rig (D3). The capsule is symmetric about Y, so collision does not
care, and the physics-state yaw used by services is simply the value of
`_yaw` at tick time.

Each physics tick (after the G-4 guard) the Player:

1. Syncs its state machine with the input context (D6).
2. Reads `mover` (zero unless Libre; NaN/∞ → zero + log), computes F1 in the
   body frame, accelerates with F2 (`a_freno` iff `v·v_obj < −0,001` or
   `|v_obj| < |v| − 0,001`), rotates by `_yaw` into world X/Z.
3. Sets `velocity` (Y: gravity from `get_gravity()` when not `is_on_floor()`,
   else 0 — sourced pattern; the floor is flat, there is no jump) and calls
   `move_and_slide()` (sourced).
4. **Adopts the slid horizontal velocity** back into the body frame (so a
   head-on wall drives `v` to 0 and a 45° wall leaves only the tangent
   component — AC-05), accumulates `d += |Δpos_horizontal|` (F3, real
   displacement after collisions).
5. Emits `paso` at each `d = (n + ½)·L_paso` (F3), writes the pose sample (D7),
   updates the yaw window (D7), runs the safety net (D8) and hands the new
   physics eye position to the interpolator (D2).

`f_fisica` = 60 Hz is the project physics tick rate (NP-2). `player.json`
carries `f_fisica` and boot validation compares it with the engine's tick rate
(GDD 2 Edge Cases: mismatch is fatal). The integration step is the fixed
`dt = 1 / f_fisica`, never the frame delta. Nothing is pushed: there are no
`RigidBody3D`s in the slice, doors and objects are moved by their systems'
code (GDD 2 rule 1, D-17). Collision layers: capsule on its own layer
`player_body`, zone sensor on `zone_sensor` only (ADR-0003); names/numbers are
ADR-0011's project layer table ‡. No `CharacterBody3D` tuning property
(`floor_snap_length`, `wall_min_slide_angle`, `safe_margin`, `motion_mode`) is
changed from its default unless S-0012-C shows it is needed; any change is
recorded in § Spike Results with its value.

### D2 — Time: fixed 60 Hz physics + **own** interpolation of the rig; engine interpolation off

The project's 3D physics interpolation setting stays **off** (NP-3; S-0012-F
only proves the default/off state). The Player interpolates its own
presentation with a `TickInterpolator` (pure `RefCounted`, ~30 lines):

- On every physics tick it receives the new physics eye position
  (`global_position + Vector3.UP × altura_ojos`) and the scalar step phase
  `d` and speed ratio `r`, shifting `prev ← curr ← new`.
- On every `_process` it advances an accumulator that **mirrors the engine's**:
  `acc += frame_dt − ticks_since_last_frame × dt`, clamped to `[0, dt]` (the
  clamp re-synchronises after a hitch, a max-steps cut or the engine's jitter
  fix), and returns `α = acc / dt`. `frame_dt` is `GameClock.delta()` — 0
  while paused, so the rig holds in both ADR-0002 variants.
- The rig shows `lerp(prev, curr, α)` (position) and evaluates F3 bob with
  `lerp(d_prev, d_curr, α)`, `lerp(r_prev, r_curr, α)`. That is standard
  one-tick-latency interpolation: it never extrapolates.
- `reset(p)` sets `prev = curr = p`, `acc = 0`, `ticks = 0`. `colocar` and the
  safety-net relocation call it (closes ADR-0003 R5 / O6: no smear, no API of
  NP-3 needed).

Look is **not** interpolated: `consume_look_delta()` is applied to `_yaw` /
`_pitch` in `_process` of the frame it arrives (rule 13, 15) and the rig's
basis is rebuilt from them in the same frame. Movement direction uses `_yaw`
as it stands at the next tick (rule 8). Under pause, variant A stops both
callbacks (tree), variant B leaves `_process` running with `delta() = 0` and
the G-4 guard returns from `_physics_process`; in both cases `α` is frozen and
the first frame after resume continues from it (ADR-0002 S11 criterion, closes
ADR-0002 OI-4). The only engine assumption left is NP-1 (callback order),
which S-0012-A measures; if it fails, the accumulator source is swapped for
the engine fraction in one function (`_fraction()`), behind the same class.

Only the Player has a moving kinematic body in the slice. **Consequence for
other ADRs:** objects moved by code (doors 8, box 10, held objects here) must
be animated per frame on game time, not per physics tick, or they would step
at 60 Hz on a 144 Hz display. Recorded for ADR-0010/0011/0014 (§ Open Items).

### D3 — Presentation rig and camera; vertical FOV via F5

```
Player (CharacterBody3D, player.gd) ............ physics state; never rotated; PAUSABLE (inherits WorldSlot)
├── BodyShape (CollisionShape3D: CapsuleShape3D r 0.25, h 1.75, y = 0.875)
├── ZoneSensor (Area3D, layer zone_sensor, monitorable; SphereShape3D r 0.05, y = 0.90)
└── Rig (Node3D) ............................... position = interpolated eyes − body position (local)
    └── Look (Node3D) ........................... basis = yaw · pitch, roll 0
        ├── Bob (Node3D) ........................ local translation F3 (0 while leased / g = 0)
        │   └── MainCamera (Camera3D) ........... fov = F5, keep_aspect = keep height, near = 0.05
        └── HandsRig (Node3D, hands_rig.gd) ...... F3 hand bob, F7 inertia/breath, gestures (D9);
                                                     how it is drawn over the world = ADR-0013
```

Because the body is never rotated and engine interpolation is off, the rig's
local position is exactly `interpolated_eyes − global_position`; no
`top_level` (not sourceable) is needed. During a lease (D5) `Rig`/`Look` take
the leased pose instead (same formula, world target − body position), `Bob` is
zero and the hands follow the camera.

`MainCamera` FOV: `fov = F5(campo_vision, aspect)` in degrees with
`keep_aspect` = keep height (NP-4, S-0012-B). `aspect` comes from an injected
`AspectSource` (production: viewport visible rect, NP-9; tests: fixed values)
and F5 is re-evaluated whenever aspect or `campo_vision` changes, in that
frame. **Fallback if S-0012-B shows `keep_aspect` is not the vertical axis or
cannot be set:** keep the engine default axis and feed it the converted value
`F5` already computes (h ↔ v from the same aspect) — a change inside
`CameraFov.to_engine()` only. `near` = 0,05 m from data; with the camera on the
capsule axis it is ≥ 0,20 m from any wall the capsule touches, so the main
camera cannot clip walls (the hands are ADR-0013's problem).

Bob (F3) is translation only; `g` follows `balanceo_camara` with the linear
`t_cambio_balanceo` ramp on game time; with `ninguno` the offset is exactly
`Vector3.ZERO` (the multiplication by `g = 0.0` is exact). Roll is never
written anywhere: `Look.basis` is built from yaw and pitch only.

### D4 — Angles and units at the API

- Code and the public API use **radians** for every angle (`colocar`,
  `ceder_camara` pose, `PlayerPose.yaw/pitch`, `giro_acumulado()`); this
  matches ADR-0003's call `colocar(…, anchor.global_rotation.y, 0.0)` and
  closes ADR-0003 O6. `player.json` keeps the GDD's degrees with a `_deg`
  suffix (`pitch_max_deg`, `pitch_cesion_max_deg`, `campo_vision` stays
  degrees in Settings) and `PlayerConfig` converts once at load. `fov_actual()`
  returns **degrees** (it is a FOV, consumed as such by 7's F6 and F5).
- Yaw follows Godot's right-handed rotation about +Y, yaw 0 looking along −Z,
  wrapped to [−π, π). Pitch + = up, clamped to ±`pitch_max` in free look,
  ±`pitch_cesion_max` in leased poses. `consume_look_delta()` returns degrees
  (ADR-0006); the Player converts with `deg_to_rad` and applies the sign
  convention of GDD 1 F2/F3 (‡, § Open Items OI-3).
- Positions are metres, world space; `PlayerPose.position` is the feet; eyes
  are `position + UP × altura_ojos` (1,62 m, fixed).

### D5 — Camera lease state machine (`CameraLease`, pure `RefCounted`)

States: `OWN` → `LEASING(owner)` → `LEASED(owner)` → `RETURNING(owner)` →
`OWN`. Driven by `GameClock.now()` (the `t` of F9 is game time; frozen in
pause).

- `ceder_camara(propietario, pose_destino, fov_destino, duracion)`: rejected +
  logged (dev: `ErrorPolicy` visible) if `propietario` ∉ `propietarios_camara`
  or another owner holds any non-`OWN` state; accepted from `OWN` (saves
  `_yaw`, `_pitch`), or from any state of the **same** owner (start = current
  camera state, saved yaw/pitch unchanged). `duracion` clamped to
  `[0, t_transicion_max]` (log if clamped); pitch of the target clamped to
  ±`pitch_cesion_max`; `fov_1 = F5(fov_destino, aspect)`. F9 smoothstep with
  separate Euler yaw (shortest arc, then wrap) and pitch; position `lerp`; FOV
  `lerp`. `camara_cedida(propietario)` is emitted in the first `_process`
  where `u = 1` (with `duracion = 0`, the next `_process`, never re-entrantly
  inside the call).
- `devolver_camara(propietario)`: rejected if not the holder or in `OWN`;
  ignored if already `RETURNING` for that owner. Target re-evaluated every
  frame: live interpolated eyes, saved yaw/pitch, `F5(campo_vision)`; duration
  `t_devolver` (0,5 s, single value). At `u = 1`: state `OWN`, emit
  `camara_devuelta(propietario)`, the state machine (D6) leaves Cámara cedida
  in the same call after the emission (AC-25).
- `colocar` and scene unload cancel any lease **without** signals.
- While non-`OWN`: `mover`/`mirar` are discarded, `Bob` = 0, the body brakes
  with `t_freno` (rule 22).

### D6 — Player state machine (Sin escena / Libre / Congelado / Cámara cedida)

The Player **polls** the active context once per physics tick and once per
frame through its input port (`context()` = ADR-0006 `top()`); it does **not**
subscribe to `input_context_changed` on the bus (GDD 2: "3 Estado y bus — el
Jugador no emite ni lee hechos ni avisos del bus"; polling gives the same
same-tick behaviour, § Open Items C4). Transitions are exactly GDD 2 § States
and Transitions: Libre iff context = `EXPLORACION` and lease = `OWN` and not
"just placed"; `colocar` → Congelado until the first poll that sees
`EXPLORACION`; lease ≠ `OWN` → Cámara cedida. Leaving Libre sets the target
velocity to zero and brakes (no velocity reset). Entering Libre reads `mover`
in that same tick (AC-26).

### D7 — Pose memory and yaw window (`PoseHistory`, pure `RefCounted`)

Column ring buffers sized once in `configurar()`: `N = ceil(T_hist × f_fisica)
+ 2` (62 by default): `PackedVector3Array` positions, `PackedFloat32Array` yaw,
pitch, horizontal speed, step phase. One write per physics tick (after
`move_and_slide()`), from the physics state; sample 0 = newest.
`pose_con_retardo(τ)`: `τ` clamped to `[0, T_hist]`, `s = τ × f_fisica`, `i =
min(floor(s), N − 2)`, `α = clamp(s − i, 0, 1)`, lerp (yaw by shortest arc)
between samples `i` and `i + 1` (F6). `fill(pose)` writes all N samples (used by
`colocar`). Read-only to everyone else; no public write.

Yaw window (F8): a ring of `ceil(T_giro × f_fisica)` = 30 `|Δyaw_tick|` values
(shortest arc between consecutive ticks); `giro_acumulado()` sums the ring on
demand (30 adds — no running sum, so no float drift); `colocar` zeroes it.

### D8 — Safety net (`StuckGuard`, logic pure; probe behind a port)

Criterion of GDD 2 (D-23), with a probe that needs only a boolean overlap:
**penetration deeper than `eps_atasco_m` ⇔ a capsule shrunk by `eps_atasco_m`
(radius `r − ε`, height `h − 2ε`, same centre) overlaps static geometry.**
Touching a wall without penetration never overlaps the shrunk capsule, so
"pushing a wall does not count" holds by construction.

- `PenetrationProbe` port: `is_penetrating(center: Vector3) -> bool`.
  Production: `intersect_shape()` with a pre-built shrunk `CapsuleShape3D`,
  mask = static world layers, excluding the Player (NP-6, S-0012-D); tests: a
  fake.
- Each tick: if probe true **and** horizontal displacement over the window <
  `eps_atasco_m`, accumulate stuck time; reset otherwise. At `t_atasco` (0,5 s),
  or if `y < y_min` (−2,0 m): relocate to the last safe pose (else the spawn
  anchor recorded by `colocar`), velocity 0, `TickInterpolator.reset`, log;
  dev: visible error. Pose memory and yaw window are **not** refilled (it is
  not a `colocar`).
- Safe pose: every `t_pose_segura` (0,25 s, `GameClock` deadline), if
  `is_on_floor()` and probe false.
- Cost: one shape query per tick; S-0012-D measures it (budget D11).

### D9 — Hands: `HandSlots` logic + `HandsRig` presentation

`HandSlots` (pure `RefCounted`) owns the rules of GDD 2 rule 24 / D-33…D-43;
`HandsRig` (node) only plays what `HandSlots` says. The gesture catalogue is
data (`player.json` → `gestures`), one entry per id of the Visual/Audio table:

```text
"HAND_CARD_SWIPE": { "hand": "right", "kind": "blocking", "duration_s": 1.0,
                     "also_suspends": ["left"], "uses_held": true }
"ANIM_PHONE_PICKUP": { "hand": "both", "kind": "blocking", "duration_s": 0.8,
                       "chain_on_complete": "HAND_PHONE_HOLD" }
"HAND_HOLD_ITEM":  { "hand": "held", "kind": "background", "requires_held": true }
```

Rules (each one is a unit test, § Test Plan):

- **Slots:** `right`, `left`. Each has at most one background gesture, an
  optional held object (`sostener`) and, for `right`, an optional pointing
  target (`apuntar`). A held object occupies its slot for background purposes
  except for gestures with `requires_held` (so `HAND_READ` is rejected with an
  item held, AC-50; `HAND_HOLD_ITEM` requires it, AC-29).
- **Background** accepted iff its slot has no background gesture (rule a).
- **Blocking** accepted iff no blocking is active anywhere (rule b); on accept
  it suspends the background gesture and pointing of its own hand(s) plus
  `also_suspends` (rules c, e; `HAND_CARD_SWIPE` over `HAND_HOLD_ITEM`, D-37),
  and the held object stays in the hand. On end: resume what it suspended
  (no signal for them), emit `gesto_terminado(id, motivo)`, then start
  `chain_on_complete` if any (D-43).
- **End of a blocking gesture is a `GameClock` deadline at `duration_s`**
  (≤ `t_transicion_max`, validated at boot). If at that deadline the animator
  still reports the clip playing, it is cut and `motivo = &"tope"` + log;
  otherwise `&"completo"`. `reposo()` → `&"cancelado"`. Gesture completion
  therefore never depends on an animation signal or on the tree pause.
- **`sostener(id, mano, pose_inspeccion)`** rejected (logged, never queued) if
  any blocking is active, if that hand already holds, if `id` is in neither
  20's catalogue nor the scene holdables list (`V05` only), or if
  `pose_inspeccion` nullness does not match the kind (scene object ⇒ required;
  20 item ⇒ null). Scene object: F10 transfer in `t_mano_s` on game time,
  `objeto_sujeto` at arrival; 20 item: fade `t_item_dentro`, `objeto_sujeto`
  at its end. `girar_objeto` rejected unless a scene object has arrived.
  `soltar()` reverses (F10 or `t_item_fuera`) and emits `objeto_soltado`.
- **`reposo()`**: cancel the blocking (signal), drop the held object **in that
  step** (scene object snapped back, `objeto_soltado`; no `objeto_sujeto` if it
  was travelling), clear background gestures and pointing silently, idle.
- **Held object transform:** the Player writes the object's `global_transform`
  every frame (F10 / camera-relative hold); the object stays parented where
  the scene put it. The Player is the only writer (D-35).
- **Animation drive:** `HandsRig`'s `AnimationTree` runs in manual process mode
  and is advanced each `_process` with `GameClock.delta()` (NP-7, S-0012-E);
  this freezes clips in pause in both ADR-0002 variants (answers ADR-0002 SB2).
  Fallback if manual advance is unavailable: default process mode under
  `WorldSlot` (`PAUSABLE`, variant A) plus ADR-0002's `PauseAdapter` in B.
- **`apuntar(punto)`:** right-arm `TwoBoneIK` (4.6, `modules/animation.md`)
  with a `Marker3D` target set per frame to `punto` clamped to arm reach; IK
  influence blended in/out over the background-gesture transition. Rig and
  bone names are technical-artist content (GDD 2 OQ 4; § Open Items).
- **F7** (inertia, breath) and the hands' F3 bob are local offsets of
  `HandsRig`, computed with `GameClock.delta()` limited to 0,1 s and
  `GameClock.now()`; all zero with `g = 0`.

### D10 — Services and the closed public API

Public surface = GDD 2 rule 33, by equality (AC-04): operations `colocar`,
`ceder_camara`, `devolver_camara`, `rayo_vision`, `fov_actual`,
`reproducir_gesto`, `sostener`, `soltar`, `girar_objeto`, `apuntar`, `reposo`,
`pose_actual`, `pose_con_retardo`, `giro_acumulado`; signals `paso`,
`gesto_terminado`, `camara_cedida`, `camara_devuelta`, `objeto_sujeto`,
`objeto_soltado`. Plus the ADR-0009 lifecycle entry `configurar(ctx)`, which is
the composition contract of every scene system and not part of rule 33's
gameplay list (the AC-04 test excludes it explicitly, together with engine
callbacks).

- `rayo_vision()` → origin = physics eyes (no bob, no interpolation), direction
  = current camera forward (`-Look.global_basis.z`, includes a lease). It is
  also **the listener source for 23**: ADR-0008's requested
  `listener_position()` is not added (closed API); 23 reads
  `rayo_vision().origen` (§ Open Items C1).
- `paso(superficie, intensidad)`: contract signal 2 → 23 (ADR-0009 D4), never
  the bus. `superficie` from a `SurfaceProbe` port (production: floor collider
  metadata `surface`, NP-8; `&"default"` if missing — the only value in the
  slice, GDD 2 OQ 6).

### D11 — Provisional performance budget (GDD 2 has none)

Owner of final numbers: ADR-0019 (reference hardware still open, QQ-04). Until
then, measured on the dev machine in the grey `planta` with profiler on:

| Item | Budget | Measured by |
|---|---|---|
| Player CPU per physics tick (`_physics_process` incl. `move_and_slide()` and the probe) | ≤ 0,15 ms mean, ≤ 0,40 ms peak | S-0012-C/D, `tests/performance/player/` |
| Player CPU per rendered frame (`_process`: look, rig, lease, `HandSlots`, F7) excluding hands animation evaluation | ≤ 0,10 ms mean, ≤ 0,25 ms peak | S-0012-A |
| Hands animation + IK evaluation per frame | ≤ 0,20 ms mean | S-0012-E (rendering cost: ADR-0013) |
| Shape queries per tick (safety net) | 1 | code review + S-0012-D |
| Heap allocations per frame in steady walking | 0 from Player logic (the `PlayerPose` returned to 28 is the only per-call object; ≤ 1 per frame) | S-0012-A allocation monitor |
| Memory (logic, pose ring, gesture table) | ≤ 64 KB | estimate: 62 × 20 B ≈ 1,3 KB ring; table < 4 KB |

Total Player share: ≤ 0,5 ms of the 16,6 ms frame (3 %) at 60 fps; at 30 fps
two physics ticks fit in the same share. A budget miss is escalated to
technical-director, not tuned silently.

### Architecture Diagram

```
 Foundation / C1 (autoloads, injected via ctx)          Player (C2, scene node, PAUSABLE)
 ┌──────────────┐  context(), move_vector()   ┌──────────────────────────────────────────────────────┐
 │ InputRouter  │──── look_delta_deg() ──────►│ PlayerInputPort ─┐                                    │
 │  (ADR-0006)  │                             │                  ▼                                    │
 ├──────────────┤  now(), delta(), is_paused()│  _physics_process (60 Hz, G-4 guard)                  │
 │ GameClock    │────────────────────────────►│   PlayerStateMachine ─► Locomotion F1/F2 ─► move_and_slide()
 │  (ADR-0002)  │                             │   ─► StepTracker F3 (paso) ─► PoseHistory F6 / YawWindow F8
 ├──────────────┤  balanceo_camara,           │   ─► StuckGuard (PenetrationProbe) ─► TickInterpolator.on_tick
 │ Settings (6) │── campo_vision + change ───►│                                                        │
 ├──────────────┤                             │  _process (per frame)                                   │
 │ ContentDB    │── player/player.json ──────►│   look 1:1 (F4) ─► TickInterpolator α ─► CameraLease F9  │
 │  (18, 0005)  │   (PlayerConfig, boot-valid)│   ─► Rig/Look/Bob (F3) ─► MainCamera fov = F5            │
 └──────────────┘                             │   ─► HandSlots (deadlines) ─► HandsRig (manual advance, F7, F10, IK)
                                              └──────┬───────────────┬───────────────┬──────────────────┘
          direct calls downward (ADR-0009 D4)        │ signals (contract, upward)    │ reads (synchronous)
   4 ── colocar() ──────────────────────────────────►│  paso ───────────────► 23     │◄── pose_con_retardo, giro_acumulado ── 28
   7 ── ceder/devolver_camara, gestures, sostener ──►│  gesto_terminado, objeto_* ──► 7, 8, 20, 22
   8, 19, 20, 22 ── reproducir_gesto / sostener / reposo ►  camara_cedida/devuelta ─► 7 │◄── rayo_vision, fov_actual ── 7, 23
```

### Key Interfaces

```gdscript
# src/player/player.gd
## First-person body of Vera (GDD 2). Public surface = GDD 2 rule 33 exactly.
class_name Player extends CharacterBody3D

signal paso(superficie: StringName, intensidad: float)
signal gesto_terminado(id: StringName, motivo: StringName)   # &"completo" | &"cancelado" | &"tope"
signal camara_cedida(propietario: StringName)
signal camara_devuelta(propietario: StringName)
signal objeto_sujeto(obj_id: StringName)
signal objeto_soltado(obj_id: StringName)

## ADR-0009 lifecycle (not part of rule 33). Hard deps: clock, input, content, logger, fatal.
func configurar(ctx: ServiceContext) -> void
## Synchronous full reset (rule 20). Angles in radians. Legal before configurar() (C2).
func colocar(posicion: Vector3, yaw: float, pitch: float) -> void
## Camera lease (rule 18, F9). pose_destino = {posicion: Vector3, yaw: float, pitch: float}.
func ceder_camara(propietario: StringName, pose_destino: CameraPose, fov_destino_deg: float, duracion_s: float) -> bool
func devolver_camara(propietario: StringName) -> bool
## Physics eyes (no bob) + current camera forward. Also the audio listener (C1).
func rayo_vision() -> VisionRay
## Effective vertical FOV in degrees, including a lease in progress.
func fov_actual() -> float
## Hands (rule 24). Return false = rejected and logged; nothing is queued.
func reproducir_gesto(id: StringName, parametros: Dictionary = {}) -> bool
func sostener(obj_id: StringName, mano: StringName, pose_inspeccion: InspectionPose) -> bool
func soltar() -> bool
func girar_objeto(delta_yaw: float, delta_pitch: float) -> bool   # radians
func apuntar(punto: Vector3) -> bool
func reposo() -> void
## Services (rules 29–30). Read-only.
func pose_actual() -> PlayerPose
func pose_con_retardo(tau_s: float) -> PlayerPose
func giro_acumulado() -> float   # radians over the last T_giro seconds
```

```gdscript
# src/player/player_types.gd — value types (RefCounted, no logic)
class_name PlayerPose extends RefCounted
var position: Vector3        # feet, world, physics state
var yaw: float               # radians, [-PI, PI)
var pitch: float             # radians
var speed_h: float           # m/s
var step_phase: float        # d modulo 2·L_paso, metres

class_name CameraPose extends RefCounted
var position: Vector3; var yaw: float; var pitch: float     # roll does not exist

class_name InspectionPose extends RefCounted
var distancia_m: float; var orientation: Quaternion          # 7's F3 (0.469 m for V05)

class_name VisionRay extends RefCounted
var origen: Vector3; var direccion: Vector3                  # direccion normalised
```

```gdscript
# src/player/ports/*.gd — @abstract RefCounted ports (ADR-0009 D5 convention)
@abstract class_name PlayerInputPort extends RefCounted
@abstract func context() -> InputTypes.Context              # InputRouter.top()
@abstract func move_vector() -> Vector2                     # InputRouter.get_move_vector()
@abstract func look_delta_deg() -> Vector2                  # InputRouter.consume_look_delta()

@abstract class_name PenetrationProbe extends RefCounted
@abstract func is_penetrating(capsule_center: Vector3) -> bool   # shrunk capsule overlap (D8)

@abstract class_name SurfaceProbe extends RefCounted
@abstract func floor_surface() -> StringName                # &"default" when unlabelled

@abstract class_name AspectSource extends RefCounted
@abstract func aspect() -> float                            # width / height of the 3D view

@abstract class_name HandAnimator extends RefCounted        # implemented by HandsRig (ADR-0013 draws it)
@abstract func play(id: StringName) -> void
@abstract func stop(id: StringName) -> void
@abstract func is_playing(id: StringName) -> bool
@abstract func advance(game_dt: float) -> void
```

`PlayerConfig` (`src/player/player_config.gd`) is the typed, validated view of
`player.json` (ADR-0005 registry row `player/player.json`, schema owned by this
ADR): every knob of GDD 2 § Tuning Knobs with its range, the `gestures`
catalogue, `propietarios_camara`, `sostenibles_escena` (`["V05"]`), and the
derived invariants (`2·radio_capsula + margen_paso = player_min_passage_width_m`,
`g_reducido < g_completo`, `pitch_max_deg < 90`, `T_hist ≥ 0.6`, every blocking
`duration_s ≤ t_transicion_max`, `f_fisica` = engine tick rate). Any failure:
fatal `CATALOGO_INVALIDO` with the parameter name (TR-player-002, AC-41).

### Core pseudocode

```gdscript
# ─── player.gd (excerpt) ───────────────────────────────────────────────────
var _clock: GameClock
var _input: PlayerInputPort
var _cfg: PlayerConfig
var _interp: TickInterpolator
var _lease: CameraLease
var _poses: PoseHistory
var _yaw_window: YawWindow
var _stuck: StuckGuard
var _hands: HandSlots
var _state: PlayerStateMachine
var _surface: SurfaceProbe
var _aspect: AspectSource
var _look_sign: Vector2 = Vector2.ONE           # OI-3; fixed from GDD 1 F2/F3 convention
var _v_body: Vector2 = Vector2.ZERO          # body frame: x lateral, y forward
var _yaw: float = 0.0
var _pitch: float = 0.0
var _d: float = 0.0                           # F3 distance actually walked
var _pending_place: PlayerPose = null         # colocar() before configurar() (C2)

func configurar(ctx: ServiceContext) -> void:
	if not ctx.require(&"player", [&"clock", &"input", &"content", &"logger", &"fatal"]):
		return
	_clock = ctx.clock
	_cfg = PlayerConfig.from_content(ctx.content, ctx.fatal)         # fatal on invalid data
	_input = InputRouterPlayerPort.new(ctx.input)
	_interp = TickInterpolator.new(_cfg.dt)
	_lease = CameraLease.new(_cfg, ctx.logger)
	_poses = PoseHistory.new(_cfg.pose_samples())                     # N = 62
	_yaw_window = YawWindow.new(_cfg.yaw_window_ticks())              # 30
	_stuck = StuckGuard.new(_cfg, JoltShrunkCapsuleProbe.new(self, _cfg))
	_hands = HandSlots.new(_cfg, _clock, %HandsRig, ctx.logger)
	_hands.finished.connect(func(id: StringName, m: StringName) -> void: gesto_terminado.emit(id, m))
	# … objeto_sujeto / objeto_soltado forwarded the same way; settings soft-dep (ADR-0007 ‡)
	if _pending_place != null:
		_apply_place(_pending_place)
		_pending_place = null

func colocar(posicion: Vector3, yaw: float, pitch: float) -> void:
	var p := PlayerPose.new()
	p.position = posicion; p.yaw = wrapf(yaw, -PI, PI); p.pitch = pitch
	if _cfg == null:                                   # ADR-0003 step 5 precedes step 6
		_pending_place = p
		global_position = posicion; velocity = Vector3.ZERO
		return
	_apply_place(p)

func _apply_place(p: PlayerPose) -> void:
	p.pitch = clampf(p.pitch, -_cfg.pitch_max, _cfg.pitch_max)
	global_position = p.position
	velocity = Vector3.ZERO; _v_body = Vector2.ZERO
	_yaw = p.yaw; _pitch = p.pitch; _d = 0.0
	_lease.cancel_silently()
	_hands.reset_silently()                            # idle, no object, no signals (rule 20)
	_poses.fill(p); _yaw_window.clear()
	_stuck.reset(p.position)                           # also the fallback anchor
	_interp.reset(_eyes_physics(), _d, 0.0)
	_state.on_placed()                                 # Congelado until EXPLORACION

func _physics_process(_delta: float) -> void:
	if _clock == null or _clock.is_paused():           # ADR-0002 G-4
		return
	_tick(_cfg.dt)

func _tick(dt: float) -> void:
	_state.sync(_input.context(), _lease.is_own())
	var m: Vector2 = _input.move_vector() if _state.is_free() else Vector2.ZERO
	if not (is_finite(m.x) and is_finite(m.y)):
		m = Vector2.ZERO
		_log_invalid(&"mover")
	var v_obj: Vector2 = Locomotion.target(m, _cfg)               # F1
	_v_body = Locomotion.accelerate(_v_body, v_obj, _cfg, dt)     # F2 (dot-product rule)
	var w: Vector2 = Locomotion.to_world(_v_body, _yaw)
	var vy: float = 0.0 if is_on_floor() else velocity.y + get_gravity().y * dt
	velocity = Vector3(w.x, vy, w.y)
	var before: Vector3 = global_position
	move_and_slide()
	_v_body = Locomotion.to_body(Vector2(velocity.x, velocity.z), _yaw)   # adopt slide (AC-05)
	var step_len: float = Vector2(global_position.x - before.x, global_position.z - before.z).length()
	var r: float = clampf(_v_body.length() / _cfg.v_paseo, 0.0, 1.0)
	for i in StepTracker.crossings(_d, _d + step_len, _cfg.l_paso):
		paso.emit(_surface.floor_surface(), lerpf(_cfg.i_paso_min, 1.0, r))
	_d += step_len
	_poses.push(global_position, _yaw, _pitch, _v_body.length(), fmod(_d, 2.0 * _cfg.l_paso))
	_yaw_window.push(_yaw)
	if _stuck.tick(global_position, step_len, is_on_floor(), _clock.now()):
		_relocate(_stuck.safe_pose())
	_interp.on_tick(_eyes_physics(), _d, r)

func _process(_delta: float) -> void:
	if _clock == null:
		return
	var gdt: float = _clock.delta()                    # 0 while paused (both variants)
	var look: Vector2 = _input.look_delta_deg()        # always consumed; zero outside EXPLORACION
	if _state.is_free() and gdt > 0.0:
		_apply_look(look)                              # F4, 1:1, no dt
	var a: float = _interp.advance(gdt)
	var eyes: Vector3 = _interp.position(a)
	var cam: CameraPose = _lease.evaluate(_clock.now(), eyes, _yaw, _pitch)   # OWN → passthrough
	%Rig.position = cam.position - global_position
	%Look.basis = Basis.from_euler(Vector3(cam.pitch, cam.yaw, 0.0), EULER_ORDER_YXZ)  # roll 0
	%Bob.position = BobMath.offset(_interp.d(a), _interp.r(a), _bob_gain(gdt), _cfg) if _lease.is_own() else Vector3.ZERO
	%MainCamera.fov = CameraFov.to_engine(_lease.fov(_clock.now(), _fov_free()), _aspect.aspect())
	for ev in _lease.take_events():                    # emitted outside the request call
		(camara_cedida if ev.kind == CameraLease.CEDED else camara_devuelta).emit(ev.owner)
	_state.sync(_input.context(), _lease.is_own())     # leave Cámara cedida after camara_devuelta
	_hands.update(_clock.now(), gdt, _yaw_rate(look, gdt))

func _apply_look(look_deg: Vector2) -> void:
	if not (is_finite(look_deg.x) and is_finite(look_deg.y)):
		_log_invalid(&"mirar"); return
	_yaw = wrapf(_yaw + _look_sign.x * deg_to_rad(look_deg.x), -PI, PI)
	_pitch = clampf(_pitch + _look_sign.y * deg_to_rad(look_deg.y), -_cfg.pitch_max, _cfg.pitch_max)
```

```gdscript
# ─── tick_interpolator.gd ──────────────────────────────────────────────────
class_name TickInterpolator extends RefCounted
var _dt: float
var _prev: Vector3; var _curr: Vector3
var _d_prev: float; var _d_curr: float; var _r_prev: float; var _r_curr: float
var _acc: float = 0.0
var _ticks: int = 0

func _init(dt: float) -> void: _dt = dt

func on_tick(p: Vector3, d: float, r: float) -> void:
	_prev = _curr; _curr = p
	_d_prev = _d_curr; _d_curr = d; _r_prev = _r_curr; _r_curr = r
	_ticks += 1

## Mirrors the engine accumulator (NP-1). Returns alpha in [0, 1].
func advance(frame_dt: float) -> float:
	_acc = clampf(_acc + frame_dt - float(_ticks) * _dt, 0.0, _dt)
	_ticks = 0
	return _acc / _dt

func position(a: float) -> Vector3: return _prev.lerp(_curr, a)
func d(a: float) -> float: return lerpf(_d_prev, _d_curr, a)
func r(a: float) -> float: return lerpf(_r_prev, _r_curr, a)

func reset(p: Vector3, d0: float, r0: float) -> void:
	_prev = p; _curr = p; _d_prev = d0; _d_curr = d0; _r_prev = r0; _r_curr = r0
	_acc = 0.0; _ticks = 0
```

```gdscript
# ─── hand_slots.gd (acceptance core) ───────────────────────────────────────
func play(id: StringName) -> bool:
	var g: GestureDef = _cfg.gesture(id)
	if g == null: return _reject(id, &"unknown")
	if g.kind == GestureDef.BLOCKING:
		if _blocking != null: return _reject(id, &"blocking_active")         # rule b
		_blocking = ActiveGesture.new(g, _clock.deadline(g.duration_s))
		for hand in g.suspended_hands():                                     # rules c, e + also_suspends
			_slots[hand].suspend()
		_animator.play(id)
		return true
	var hand: StringName = g.resolve_hand(_slots)                            # "held" → hand holding
	var slot: HandSlot = _slots.get(hand)
	if slot == null or slot.has_background(): return _reject(id, &"slot_busy")  # rule a
	if g.requires_held and not slot.holds(): return _reject(id, &"no_object")
	if not g.requires_held and slot.holds(): return _reject(id, &"slot_busy")   # AC-50
	slot.background = id
	if not slot.suspended: _animator.play(id)
	return true

func update(now: float, game_dt: float, yaw_rate: float) -> void:
	if _blocking != null and _clock.is_due(_blocking.deadline):
		var id: StringName = _blocking.def.id
		var motivo: StringName = &"tope" if _animator.is_playing(id) else &"completo"
		if motivo == &"tope": _animator.stop(id); _log_cap(id)
		var chain: StringName = _blocking.def.chain_on_complete
		_blocking = null
		for s in _slots.values(): s.resume(_animator)
		finished.emit(id, motivo)
		if chain != &"": play(chain)                                         # D-43
	_transfers.update(now)                                                   # F10 / item fades
	_animator.advance(game_dt)                                               # manual mode (NP-7)
```

`Basis.from_euler(…, EULER_ORDER_YXZ)`, `%Unique` access and `is_finite` are
GDScript core used as pseudocode; the spike's parse check confirms the exact
spelling. None of the pseudocode is a sourced engine claim beyond § Engine API
sourcing.

### Implementation Guidelines

- **P-1** `Player` **must** integrate movement only in `_physics_process`, with
  the fixed `dt = 1 / f_fisica`, after the ADR-0002 G-4 guard. It **must
  never** move the body from `_process`.
- **P-2** The body node **must never** be rotated; yaw and pitch live in
  `Player` floats and are applied only to `Look`.
- **P-3** Engine 3D physics interpolation **must** stay off project-wide
  (S-0012-F); no code **may** call any NP-3 API. Presentation smoothing of the
  Player **must** go through `TickInterpolator`; exponential smoothing of the
  camera position or orientation **must never** be added.
- **P-4** Look **must** be applied 1:1 in the frame it is consumed, without
  `dt`, filtering or acceleration; roll **must never** be written.
- **P-5** Services (`rayo_vision` origin, zone sensor, `PoseHistory`,
  `pose_actual`) **must** read the physics state; only `Rig`/`Look`/`Bob`,
  `MainCamera` and `HandsRig` read interpolated values.
- **P-6** Every time used by the lease, gestures, transfers, item fades,
  safe-pose cadence and bob-level ramp **must** come from the injected
  `GameClock` (`now()`, `delta()`, `deadline()`/`is_due()`); `Timer`,
  `create_timer()`, `Tween` and `AnimationPlayer` signals **must never** decide
  when a Player rule ends.
- **P-7** Public angles **must** be radians, `fov_actual()` degrees; data uses
  `_deg` keys converted once in `PlayerConfig`.
- **P-8** The public surface **must** equal GDD 2 rule 33 plus `configurar`;
  helpers are `_private` or live in internal classes. A test compares the
  script's method and signal lists with a fixed list (AC-04, AC-36, AC-39).
- **P-9** Requests from other systems **must** be answered synchronously with
  `bool` (accepted/rejected + log) and **must never** emit a signal re-entrantly
  inside the call; arrival signals (`camara_cedida`, `objeto_sujeto`, …) are
  emitted from `_process`/`_physics_process`.
- **P-10** The Player **must not** subscribe to, emit on or read the bus of 3,
  and **must not** be in the save snapshot (TR-player-018, AC-39).
- **P-11** All engine-dependent behaviour (shape query, floor surface, aspect,
  animation drive) **must** sit behind the ports of § Key Interfaces; logic
  classes (`Locomotion`, `StepTracker`, `BobMath`, `CameraFov`, `CameraLease`,
  `PoseHistory`, `YawWindow`, `StuckGuard`, `HandSlots`, `TickInterpolator`)
  **must** be engine-free `RefCounted`s testable headless.
- **P-12** Objects held by the Player **must** have their `global_transform`
  written only by the Player while held (D-35); the owning system **must not**
  move them in that window.

## Alternatives Considered

### Alternative 1: Engine 3D physics interpolation (4.5+ SceneTree-based)
- **Description**: Turn the project setting on; the body is interpolated by the
  engine; the camera reads the interpolated transform each frame; `colocar`
  calls the engine's teleport reset.
- **Pros**: Also smooths any other physics-moved node for free; no own class.
- **Cons**: Every name and default it needs is NOT SOURCEABLE (NP-3); the 4.5
  rearchitecture is documented to "differ in edge cases"; per-frame camera
  rotation on an interpolated hierarchy is a known class of conflicts that we
  cannot check against the reference; pause hold (ADR-0002 S11) and teleport
  reset become engine claims instead of unit-tested logic.
- **Estimated Effort**: Lower code (−30 lines), higher spike risk.
- **Rejection Reason**: Puts TR-player-004/-015/-018 on unsourceable behaviour
  when one moving body is all the slice has. Kept as the fallback if S-0012-A
  shows NP-1 cannot be mirrored (§ Risks R1).

### Alternative 2: Frame-rate follow with exponential smoothing (GDD 2 rule 11's named alternative)
- **Description**: Camera rig chases the body each frame with
  `lerp(cam, body, 1 − exp(−k·dt))`.
- **Pros**: Trivial; no tick bookkeeping.
- **Cons**: Adds latency and positional lag that varies with frame rate; the
  camera never sits exactly on the eyes when stopped within a bounded time;
  conflicts with "no added latency or inertia" (rule 15) and with exact `colocar`
  placement.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Smoothing is a feel change, not an interpolation;
  pillar 4 comfort requirements forbid it.

### Alternative 3: Variable-step movement in `_process`
- **Description**: Move the body with the frame delta; no interpolation.
- **Pros**: No interpolation at all.
- **Cons**: F2 step counts (9/12/17/19 ticks) and AC-02/-45 stop being exact;
  collision response varies with fps; Jolt is stepped at the physics rate
  anyway.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Breaks the GDD's tick-exact formulas and AC-06.

### Alternative 4: Rotate the body with yaw (conventional FPS controller)
- **Description**: `rotation.y = yaw` on the `CharacterBody3D`; camera child.
- **Pros**: Familiar pattern; matches the sourced example's `transform.basis`.
- **Cons**: Yaw changes per frame would rotate a physics body outside the tick;
  the interpolated rig would need the body's rotation history; no benefit for a
  Y-symmetric capsule.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Adds a second interpolated quantity for nothing.

### Alternative 5: Engine penetration report for the safety net
- **Description**: Read penetration depth from `move_and_slide()` collisions or
  a rest-info query.
- **Pros**: Direct depth value.
- **Cons**: D-23 already rejected relying on an engine penetration signal; depth
  APIs are NOT SOURCEABLE.
- **Estimated Effort**: Similar.
- **Rejection Reason**: The shrunk-capsule boolean gives the same criterion
  with a query ADR-0011 spikes anyway.

### Alternative 6: Gesture end on `animation_finished`
- **Description**: A blocking gesture ends when its clip's signal fires.
- **Pros**: Animation and rule never disagree.
- **Cons**: Pause behaviour of `AnimationPlayer` is ADR-0002 NS-6; a lost or
  never-firing signal is exactly GDD 2's 3 s cap case; durations would be owned
  by assets, not data (contradicts "cada gesto tiene una duración fija en
  datos").
- **Estimated Effort**: Lower.
- **Rejection Reason**: Rules must end on game time; the animator is advisory
  (`tope` on mismatch).

## Consequences

### Positive
- Locomotion, lease, poses, safety net and hands are engine-free classes:
  ACs 01–05, 10–18, 20–25, 27–30, 35–41, 44–51 run headless with integer ticks.
- Pause and teleport correctness of the camera become unit tests instead of
  engine claims; ADR-0002 OI-4 and ADR-0003 O6/R5 close.
- Only NP-1 stands between the decision and 144 fps smoothness, and it has a
  one-function fallback.
- Hands logic is decided now; ADR-0013 only decides how `HandsRig` is drawn.

### Negative
- ~30 lines of own interpolation to maintain; any future physics-moved object
  is not smoothed for free (code-moved objects must animate per frame, D2).
- Polling the context duplicates information also available as a bus notice.
- `colocar` before `configurar` needs a pending-placement path (C2).

### Neutral
- Public names stay Spanish (contract literal), internals English.
- `listener_position()` requested by ADR-0008 is served by `rayo_vision()`.

## Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | NP-1 false (physics ticks not before `_process`, or engine accumulator not mirrorable) → micro-judder at 144 fps | Medium | S-0012-A measures frame-to-frame eye displacement; fallback = engine fraction in `_fraction()`, or Alternative 1 for the rig only |
| R2 | Jolt `CharacterBody3D` oscillates against walls (NP-5) → AC-05 fails | Medium | S-0012-C; tune only `safe_margin`/`wall_min_slide_angle` with recorded values; last resort: zero the normal component of `_v_body` ourselves from the slide normals |
| R3 | `keep_aspect` not settable/vertical (NP-4) | Low | `CameraFov.to_engine()` converts F5's vertical value to the engine axis |
| R4 | Shrunk-capsule probe gives false positives at thin geometry seams | Low | `eps_atasco_m` tunable 0,005–0,05; the time + displacement conjunction filters transients; log every relocation in playtest |
| R5 | Manual `AnimationMixer` advance unavailable (NP-7) | Low | Default process mode + ADR-0002 variant A / `PauseAdapter`; gesture end does not depend on it anyway |
| R6 | Held object collides with the capsule or the interaction ray while in hand | Medium | Owner (7) disables the held object's collision while held ‡ (Open Item OI-6); interaction ray already excludes the Player layer |
| R7 | Budget D11 exceeded by `move_and_slide()` + probe under Jolt | Low | Probe every second tick (criterion still met: 0,5 s window) |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| jugador-en-primera-persona.md | **TR-player-001** kinematic Jolt body, fixed capsule, no sprint/jump/crouch, slide without bounce (<1 mm / 60 ticks), pushes nothing, own layer excluded from 7's ray | D1 (un-rotated `CharacterBody3D`, adopt slid velocity, layer `player_body`); S-0012-C |
| jugador-en-primera-persona.md | **TR-player-002, TR-player-021** boot validation with parameter name; all knobs in `player.json`; tests with injected clock, fake input, fake collision | `PlayerConfig` invariants (§ Key Interfaces); P-11 ports; § Test Plan |
| jugador-en-primera-persona.md | **TR-player-003** 0,05 m zone sensor separate from the capsule | D3 node tree (`ZoneSensor` on `zone_sensor`); detection behaviour = ADR-0003 S-0003-B |
| jugador-en-primera-persona.md | **TR-player-004, TR-player-005** fixed 60 Hz + interpolated presentation; which transform each service reads | D2 own interpolator, engine interpolation off; P-5; S-0012-A |
| jugador-en-primera-persona.md | **TR-player-006, TR-player-007** body-frame velocity F1/F2 with the dot-product rule; look 1:1, wrap, ±80°, roll 0 | D1 steps 2–4; D3/D4; P-4 |
| jugador-en-primera-persona.md | **TR-player-008** vertical FOV, F5 cap, `near` 0,05, immediate apply, leased FOV through F5 | D3 `CameraFov`, `AspectSource`; D5; S-0012-B |
| jugador-en-primera-persona.md | **TR-player-009** translation-only bob by distance, levels, ramp, exact zero | D3 `BobMath` on interpolated `d`/`r`; `g = 0` exact |
| jugador-en-primera-persona.md | **TR-player-010** hands drawn over the world with `fov_manos` | **Partial**: node contract `HandsRig` and `fov_manos` in data here; drawing technique, wall non-penetration and blackout light = **ADR-0013** |
| jugador-en-primera-persona.md | **TR-player-011, TR-player-012** two-slot gesture machine, no queue, 3 s cap; held-object ownership F10 | D9 `HandSlots`, deadlines on `GameClock`, `tope`; P-12 |
| jugador-en-primera-persona.md | **TR-player-013** one-owner camera lease, F9 Euler, `t_devolver`, pitch ≤ 89° | D5 `CameraLease`; P-9 |
| jugador-en-primera-persona.md | **TR-player-014** four-state machine driven by the input context | D6 (polling, no bus) |
| jugador-en-primera-persona.md | **TR-player-015** everything freezes and resumes under pause | D2 (`α` frozen with `delta() = 0`), G-4 guard, P-6, D9 manual advance |
| jugador-en-primera-persona.md | **TR-player-016, TR-player-017** 62-sample pose ring; `giro_acumulado`; `paso` as direct signal | D7; D10 |
| jugador-en-primera-persona.md | **TR-player-018** synchronous `colocar`, not saved | `_apply_place` (pseudocode), pending path (C2), P-10 |
| jugador-en-primera-persona.md | **TR-player-019** trap/fall safety net without engine penetration signal | D8 shrunk-capsule probe; S-0012-D |
| jugador-en-primera-persona.md | **TR-player-020** closed public API by equality | D10, P-8 |
| escena-de-planta.md | **TR-scene-007** geometric contract: 0,60 m passage ⇔ 0,25 m capsule; door leaves without collision on opening; floor surface label (`default`) | Invariant validated in `PlayerConfig`; capsule fixed in D1; `SurfaceProbe` (D10). Door collision withdrawal is 8's (contract only); level geometry is content |
| marco-de-puzles / interaccion (7) | Camera lease, `rayo_vision`, `fov_actual`, gestures | D5, D9, D10 — consumed by ADR-0011 |
| atmosfera-reactiva (28) | Delayed pose (0,6 s) and head turn | D7 — consumed by ADR-0014 |

Covered by range: **TR-player-001…009, 011…021 full; TR-player-010 partial
(→ ADR-0013); TR-scene-007 Player side.**

## Performance Implications
- **CPU**: ≤ 0,5 ms per frame total for the Player at 60 fps (D11 table);
  one `move_and_slide()` and one shape query per physics tick.
- **Memory**: ≤ 64 KB of logic data; pose ring ≈ 1,3 KB; zero steady-state
  per-frame allocations except one `PlayerPose` per 28 query.
- **Load Time**: `player.json` parse + validation < 1 ms (ADR-0005 boot step);
  Player instantiated with each game scene (ADR-0003 D3), no extra resources
  beyond the hands rig (ADR-0013).
- **Network**: None.

## Migration Plan

No Player code exists; nothing to migrate. Order of work: (1) spikes S-0012-A,
-B, -C, -F in `prototypes/spike-player/` (throwaway); (2) logic classes with
their unit tests; (3) `Player` node and grey-box walk (M1); (4) `HandSlots`
with a fake `HandAnimator`; (5) `HandsRig` once ADR-0013 is `Accepted`.

**Rollback plan**: interpolation, aspect, probe, surface and animation drive
are each one class behind a port or one function (`_fraction()`,
`CameraFov.to_engine()`); swapping any of them (e.g. to Alternative 1) does not
touch `Locomotion`, `CameraLease`, `PoseHistory`, `HandSlots` or their tests.

## Validation Criteria

### Spikes (Godot 4.7.2, Jolt, before `Accepted`)

Where: `prototypes/spike-player/` (grey corridor 24 × 2,6 m, one 1,00 m door,
a 45° wall, a 0,45 m gap, one `V05` stand-in). Vsync off; frame cap via the
engine's max-fps setting (name per spike; NOT SOURCEABLE).

| ID | Verifies | Procedure | PASS criterion | On FAIL |
|---|---|---|---|---|
| S-0012-A | NP-1, NP-2; own interpolation at 30/60/144 fps | Log per frame: ticks run, `α`, rendered eye X; walk the corridor with `W` held at caps 30, 60, 144 (and uncapped) | Ticks always before `_process` in the frame; 2 ticks/frame at 30, 0–1 at 144; eye X strictly monotonic while walking; max deviation of per-frame displacement from `v·frame_dt` ≤ 10 % after acceleration; corridor 15,1 ± 0,3 s at every cap (AC-06) | R1: `_fraction()` from the engine; else Alternative 1 for the rig |
| S-0012-B | NP-4, NP-9: `keep_aspect`, FOV axis, `near` | Camera at 70°, 1 m tall quad at 1 m distance; window 16:9, 4:3, 21:9, 32:9 (windowed resize) | Quad height in px = `viewport_h × 1 / (2·tan(fov_v/2))` ± 1 px for every aspect where F5 does not cap; at 32:9 the measured vertical FOV is 51,9° ± 0,2°; FOV change visible in the same frame | `CameraFov.to_engine()` converts to the engine axis |
| S-0012-C | NP-5, NP-8: Jolt slide, floor, no push, surface label | Push head-on 60 ticks; 45° wall; corner; 1,00 m door at full width; 0,45 m gap; floor collider with metadata `surface = "test"` | Head-on: position variation < 1 mm over 60 ticks (AC-05); 45°: normal velocity component < 0,001 m/s; never stuck in the door (AC-07); gap not enterable; `y` constant on flat floor; label read as `test`; per-tick CPU within D11 | R2 mitigations; record any property change and value |
| S-0012-D | NP-6: shrunk-capsule overlap (with ADR-0011) | Capsule pushed against a wall; teleported 0,05 m into a wall; 0,03 m into a seam | Wall touch → false; 0,05 m → true; overlap query ≤ 0,05 ms per call | Probe from slide-collision depth if exposed; else relocate only on `y_min` + displacement criterion (log as deviation) |
| S-0012-E | NP-7: manual `AnimationMixer` advance | 1,0 s clip, manual mode, advanced with a fake `GameClock.delta()`; pause for 120 frames | Clip pose constant during pause; ends after 1,0 s of advanced time ± 1 frame; `AnimationTree` parameter set from code takes effect next advance | R5 fallback |
| S-0012-F | NP-3: engine interpolation default/off; ADR-0002 S11 regression | New 4.7.2 project: record the default; with it off, run ADR-0002 S11 (pause mid-walk at 144 fps) against the own interpolator | Setting confirmed off in `project.godot`; camera `global_transform` identical across paused frames; first frame after resume moves ≤ one tick of displacement | Set it off explicitly; S11 failure is a bug in `TickInterpolator` |

### Test Plan

All unit tests: gdUnit4, `tests/unit/player/`, fake `GameClock` advanced in
whole ticks, `FakeInput`, `FakeProbe`, `FakeAnimator`, fixtures from
`tests/fixtures/player/player_valid.json` (no inline magic numbers except
boundary values that *are* the AC).

| ID | Type | File | Covers |
|---|---|---|---|
| T-U1 | Unit | `locomotion_test.gd` | AC-01, -02, -03, -45 (F1/F2 step tables), NaN `mover` (AC-04 b) |
| T-U2 | Unit | `tick_interpolator_test.gd` | α at 30/60/144 synthetic frame sequences; clamp on hitch; reset; frozen with `frame_dt = 0` |
| T-U3 | Unit | `look_test.gd` | AC-11, -12, -13 (roll 0 over fixture seed 20261109), -14, NaN look |
| T-U4 | Unit | `bob_math_test.gd` | AC-10, -15, -16, -17, -22 |
| T-U5 | Unit | `camera_fov_test.gd` | AC-18 (F5 aspects), leased FOV through F5 |
| T-U6 | Unit | `camera_lease_test.gd` | AC-20, -21, -25, -44; same-owner re-lease; `duracion` 0; no re-entrant signal |
| T-U7 | Unit | `player_state_machine_test.gd` | AC-23 (state part), -24, -26 (logic), Congelado after `colocar` |
| T-U8 | Unit | `pose_history_test.gd` | AC-35, -36; τ = 0 and τ = `T_hist` without out-of-bounds |
| T-U9 | Unit | `yaw_window_test.gd` | AC-37 |
| T-U10 | Unit | `step_tracker_test.gd` | AC-38 |
| T-U11 | Unit | `stuck_guard_test.gd` | AC-40 (criterion, not engine) |
| T-U12 | Unit | `hand_slots_test.gd` | AC-28, -29, -46, -47, -48, -49, -50, -51; `tope` on animator mismatch |
| T-U13 | Unit | `player_config_test.gd` | AC-41, TR-player-002 invariants, blocking durations ≤ 3 s |
| T-U14 | Unit | `player_api_surface_test.gd` | AC-04 a, -36, -39 (method/signal lists by equality, `configurar` and engine callbacks excluded) |
| T-U15 | Unit | `player_pause_test.gd` | AC-27 (600 wall-clock ticks with `is_paused()`; nothing advances; resume continues) |
| T-I1 | Integration | `tests/integration/player/player_walk_test.gd` | Headless physics: AC-05, -08, AC-06 time at fixed tick, `colocar` + `colocar` before `configurar` (C2) |
| T-I2 | Integration | `tests/integration/player/player_zone_test.gd` | AC-09 with ADR-0003 S-0003-B as regression |
| T-P1 | Performance | `tests/performance/player/player_budget_test.gd` | D11 budgets on the dev machine (advisory until ADR-0019) |

Player-observable checks (AC-19, -31…-34, -42, -43, feel at 144 fps) need a
launched build and retained screenshots in `production/qa/evidence/`
(`.claude/docs/run-and-observe.md`); a parse check is not a run.

We will know this decision was right if: S-0012-A passes at all three caps with
the own interpolator; AC-06 and AC-27 pass in the first grey-box build; and no
Player story needs to touch an NP-3 API.

## Spike Results

*Empty until S-0012-A…F run on 4.7.2.*

## Open Items

| # | Item | Owner | Before |
|---|---|---|---|
| OI-1 | **Applied 2026-11-10 (OI-1, OI-2, OI-4, OI-5 applied in ADR-0008, -0009, -0002, -0003).** ADR-0008 amendment: replace the requested `listener_position()` with `rayo_vision().origen` / `.direccion` (closed API, C1) | ADR-0008 | ADR-0008 accepted |
| OI-2 | ADR-0009 D4 amendment: add 2 to the allowed direct calls of **8** (`reproducir_gesto(HAND_CARD_SWIPE)`, `sostener` via 20), **19** (`HAND_TYPE`), **22** (`ANIM_PHONE_PICKUP`, `HAND_PHONE_PUTDOWN`, `reposo()`), and **23** (`rayo_vision()` read, bind window); all are downward to C2 and already signed in GDD 2 § Interactions (C3) | ADR-0009 | ADR-0009 accepted |
| OI-3 | Sign convention of `consume_look_delta()` (+yaw = right? +pitch = up after inversion) against D4's radians convention; resolve in `_look_sign` | ADR-0006 / GDD 1 F2–F3 | First look story |
| OI-4 | ADR-0002 OI-4 can be marked *Resolved by ADR-0012 D2* (own interpolator, engine interpolation off; S11 runs as S-0012-F) | ADR-0002 | Reconciliation round |
| OI-5 | ADR-0003 O6 and R5 can be marked *Resolved by ADR-0012 D2/D4* (radians; `TickInterpolator.reset` in `colocar`) | ADR-0003 | Reconciliation round |
| OI-6 | Collision of the held object (`V05`) while in hand, and who toggles it (7 as owner ‡) | ADR-0011 | `V05` inspection story |
| OI-7 | Code-moved objects (doors 8, box 10, 29 targets) animate per frame on game time, not per physics tick (D2 consequence) | ADR-0010 / ADR-0011 / ADR-0014 | Their stories |
| OI-8 | Hands rig bone names, `TwoBoneIK` chain and `apuntar` reach; `HAND_CARD_SWIPE` with the card in the left hand (GDD 2 OQ 4, OQ 9) | technical-artist + ADR-0013 | Hands stories |
| OI-9 | Collision layer numbers for `player_body` and `zone_sensor` | ADR-0011 (ADR-0003 O7) | ADR-0011 |
| OI-10 | Final budgets on reference hardware | ADR-0019 | M4 |

### Contradictions found in the sources

| # | Between | Resolution in this ADR |
|---|---|---|
| C1 | ADR-0008 § Key Interfaces asks the Player for `listener_position() -> Vector3` vs GDD 2 rule 33 / AC-04 (closed API by equality) | No new operation; 23 uses `rayo_vision()` (D10, OI-1) |
| C2 | ADR-0003 step 5 calls `colocar` **before** step 6 `configurar()`, but `colocar` needs the validated config (pitch clamp, ring size) | `colocar` before `configurar` stores a pending placement (position applied at once) and `configurar` completes it; same frame, before «escena lista», nobody reads the Player in between. No change to ADR-0003 |
| C3 | ADR-0009 D4 "allowed direct calls" table omits 2 from the rows of 8, 19, 22 and 23, which GDD 2 signs | Calls are downward (F5/F3/C3 → C2), so allowed by D4's rule; table amendment requested (OI-2) |
| C4 | GDD 2 rule 22 ("lee el contexto activo (aviso «contexto de entrada cambiado»)") vs GDD 2 § Interactions row 3 ("el Jugador no emite ni lee hechos ni avisos del bus") | Polling `top()` through `PlayerInputPort` each tick and frame (D6); same-tick semantics preserved; no bus |
| C5 | `architecture.md` row ADR-0012 lists TR-player-001…021, row ADR-0013 lists TR-player-010 | TR-player-010 partial here (node contract), technique in ADR-0013 |
| C6 | GDD 2 rule 11 names "seguir al cuerpo en cada fotograma con suavizado de posición" as the alternative to engine interpolation | Neither: own non-smoothing interpolation (D2); smoothing rejected (Alternative 2). Not a contradiction with the GDD's intent (it delegates the mechanism) |

## Related

- Depends on: ADR-0002 (pause, `GameClock`), ADR-0003 (per-scene Player,
  `colocar`, `zone_sensor`), ADR-0005 (data schema), ADR-0006 (input ports),
  ADR-0007 (settings ‡), ADR-0009 (composition) — all `Proposed`.
- Enables / constrains: ADR-0008 (listener, `paso`), ADR-0011 (interaction:
  ray, lease, gestures, layers), ADR-0013 (hands rendering), ADR-0014
  (reflection from `pose_con_retardo`), ADR-0019 (budgets).
- Closes (pending reconciliation): ADR-0002 OI-4; ADR-0003 O6, R5.
- Design: `design/gdd/jugador-en-primera-persona.md` (rules 1–33, F1–F10,
  D-01…D-44, AC-01…AC-51, OQ 3); `design/gdd/escena-de-planta.md` (TR-scene-007);
  `docs/architecture/architecture.md` § Required ADRs row ADR-0012;
  `docs/architecture/tr-baseline-provisional.md`.
- Code (once implemented): `src/player/`, `tests/unit/player/`,
  `tests/integration/player/`, `prototypes/spike-player/`.
