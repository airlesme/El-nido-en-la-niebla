# ADR-0011: Interaction Focus Query under Jolt and View Picking

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> This ADR must not move to `Accepted` before spikes S-0011-A, S-0011-B and
> S-0011-C (§ Validation Criteria) have run on Godot 4.7.2 and their results
> are written into § Spike Results.

## Date

2026-11-10

## Last Verified

2026-11-10 (against Godot 4.7.2 engine reference, ADR-0001/0002/0003/0006/0009
and `adr-reconciliation-2026-11-10.md`)

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation:
autonomous`); user approval at batch close.

## Summary

System 7 (`InteractionSystem`) needs a focus sweep that implements GDD 7 F1
exactly ("all contacts of a 0,06 m sphere along the eye ray, with depth and
distance to axis"), view picking in close-up views, the F6 px-per-metre
conversion, and the signed contract with owners (8, 9, 10, 19, 20, 22, 28) and
24. Decided: **candidates are gathered and measured arithmetically** against the
interactables' own `BoxShape3D` pick volumes held in a per-scene registry (no
`intersect_shape`, no `ShapeCast3D` in the hot path); **occlusion is the only
physics query** (`intersect_ray`, the one sourced API) on a geometry-only mask;
view picking is pure 2D arithmetic over `ViewReceiver.elements()` with a
`ViewMetrics` value that implements F6 with an explicit FOV axis; three spikes
gate `Accepted`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pinned 4.7.2) |
| **Domain** | Physics (focus query, occlusion) / Input (view picking) |
| **Layer** | Feature |
| **Knowledge Risk** | HIGH (Physics/Jolt and Camera rows of `architecture.md` § Engine Knowledge Gap Summary). The decision is shaped to move every NOT SOURCEABLE behaviour off the F1 critical path; residual risk is in occlusion depth (Jolt margins) and in the FOV axis / logical viewport height |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/physics.md` (Jolt default since 4.6; "Collision margins may behave differently"; `intersect_ray` + `PhysicsRayQueryParameters3D.create(from, to)` + `collision_mask` pattern); `modules/ui.md` and `current-best-practices.md` (new 4.7 projects: stretch `canvas_items` / `expand`); `modules/rendering.md` (no Camera3D content); `breaking-changes.md` (stretch defaults row; Jolt rows irrelevant: no `SoftBody3D`, no `WorldBoundaryShape3D` in the sweep) |
| **Post-Cutoff APIs Used** | Jolt as default 3D physics (4.6) — affects only the occlusion ray. `@abstract` (4.5) for the ports, as in ADR-0009. Stretch defaults of 4.7 new projects (only through ADR-0016's `ViewportMapper`) |
| **Verification Required** | S-0011-A (shape queries under Jolt — recorded as oracle and as the scaling path, not as the F1 mechanism; cost per step); S-0011-B (`intersect_ray` depth error on box faces under Jolt vs analytic, `exclude`, mask filtering); S-0011-C (`Camera3D` FOV axis with `keep_aspect`, logical viewport height in 16:10 with `canvas_items`/`expand`, physics-step order Player → 7) |

> **Note**: Knowledge Risk is HIGH. This ADR must be re-validated if the
> project upgrades the engine; flag it `Superseded` and write a new ADR.

### Sourcing table

Anything marked NOT SOURCEABLE is implemented only after the named spike has
recorded the observed behaviour.

| API / behaviour | Status | Spike |
|---|---|---|
| `get_world_3d().direct_space_state`, `PhysicsRayQueryParameters3D.create(from, to)`, `query.collision_mask`, `intersect_ray(query) -> Dictionary` with `position`, `normal` | Sourced — `modules/physics.md` § Raycasting | — |
| `intersect_ray` result `collider` / `rid` keys; `query.exclude: Array[RID]`; `query.collide_with_areas` / `collide_with_bodies`; `hit_from_inside` | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/physics.md`** (the snippet only shows `position`, `normal`) | S-0011-B |
| Depth accuracy of `intersect_ray` against a Jolt `BoxShape3D` face (convex radius / margin) | **NOT SOURCEABLE — `modules/physics.md` only says Jolt margins "may behave differently"** | S-0011-B |
| `PhysicsDirectSpaceState3D.intersect_shape`, `PhysicsShapeQueryParameters3D`, `max_results`, result keys; whether it returns *every* overlap under Jolt | **NOT SOURCEABLE — not covered by `modules/physics.md`** (only `intersect_ray`) | S-0011-A (oracle only) |
| `ShapeCast3D` (`target_position`, `force_shapecast_update`, `get_collision_count`, which contacts it reports along a sweep) | **NOT SOURCEABLE — not covered by `modules/physics.md`** | S-0011-A (recorded, rejected) |
| `BoxShape3D.size`, `CollisionShape3D.shape`, `Area3D.monitoring` / `monitorable`, `collision_layer` / `collision_mask` on `Area3D` | **NOT SOURCEABLE — not covered by `modules/physics.md`** (only `collision_mask` on the ray query appears) | S-0011-A |
| `Camera3D.fov` axis and `Camera3D.keep_aspect` (`KEEP_HEIGHT` / `KEEP_WIDTH`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/rendering.md`** (no Camera3D section); also listed `⚠ NS` in `architecture.md` § Module Ownership row 2 | S-0011-C |
| Logical viewport height under `canvas_items` + `expand` in a 16:10 window (GDD 7 F6 assumes 1200) | **NOT SOURCEABLE — `modules/ui.md` only states the 4.7 defaults, not the resulting logical size** | S-0011-C (shared with ADR-0007's stretch spike) |
| `Node.process_physics_priority` ordering of two `_physics_process` callbacks | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | S-0011-C |
| `_physics_process` stops under tree pause | NOT SOURCEABLE — owned by ADR-0002 NS-1 / S1 | ADR-0002 S1 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (bus, `get_fact_at`, `interaction_executed` D11, notice names of 7); ADR-0002 (`GameClock`, `WorldSlot` `PAUSABLE`, G-1/G-4/G-6); ADR-0003 (D8 collision layer `zone_sensor`; `configurar` order with 7 first); ADR-0006 (contexts, `bind_sink`, `ActionEvent`, `PointerTargetProvider`, `set_target_long_verb`, `begin_blocking`/`end_blocking`, logical px); ADR-0009 (7 is F1, `SceneServices.interaction`, `PromptSink`/`InteractionQuery` ports, `ctx.require`) |
| **Enables** | ADR-0010 (puzzle framework receivers, `InteractionQuery` for P3), ADR-0016 (prompt 24 reads `get_target()`; `ViewportMapper` feeds `ViewMetrics`), ADR-0012 (Player: `rayo_vision`, `fov_actual`, gesture reservation) ‡ numbering per `architecture.md` |
| **Blocks** | Interaction epic stories "detección" (F1), "vista cercana / picking" (F6, AC-32, AC-V6); P3/P4 stories that depend on ppm (TR-puzzle3-008/-009, TR-puzzle4-002) |
| **Ordering Note** | 0001 → 0002 → 0009 → 0003 → 0006 → **0011**. S-0011-C shares its 16:10 window setup with ADR-0007's stretch spike; run them in one session |

## Context

### Problem Statement

GDD 7 F1 requires, every physics step in `exploración`, the set of **all**
interactables within `radio_apuntado_m` (0,06 m) of the eye ray up to their
reach, each with its depth `d_c`, whether it contains the exact axis, and its
distance to the axis; then occlusion with a 0,03 m tolerance, grouping, a
four-key tie-break and retention by steps and distance. GDD 7 states this is
**not claimed implementable** with the 7-ray `intersect_ray` fallback (D7-37)
and blocks AC-05 and the detection story on this ADR (V1). Close-up views need
2D picking in logical pixels and the F6 conversion, whose FOV axis (V2) and
16:10 logical height (V4) are engine-dependent. `architecture.md` § API
Boundaries leaves one gap: `elemento_bajo` on `seleccionar` (asked by 16), and
ADR-0009 O2 leaves the `PromptSink` and `InteractionQuery` signatures to this
ADR.

### Current State

No code. The contract is signed in GDD 7 (rules 3, 5–12, 19–23, 27–32; F1, F2,
F5, F6) and summarised in `architecture.md` § Interacción (7). The only
sourced physics API is `intersect_ray`.

### Constraints

- **Engine knowledge:** shape queries, `ShapeCast3D`, Camera3D FOV axis and
  the logical viewport under `expand` are not in the engine reference. Nothing
  may rely on remembered behaviour; spikes decide.
- **Composition (ADR-0009):** 7 is sub-layer F1, configured first in a game
  scene; it may call 1, 2, 4, 18 directly; calls to owners (F2–F5) and to 24
  (Presentation) go through ports defined on 7's side.
- **Pause (ADR-0002):** 7 lives under `WorldSlot` (`PAUSABLE`); all its timers
  are game time; every `_physics_process` starts with `if clock.is_paused():
  return` (G-4); 7 never connects to `GameClock.paused_changed` (G-6).
- **Input (ADR-0006):** 7 receives actions only through sinks of its contexts;
  cursor position is in logical pixels; the real mouse is never warped.
- **No hardware budget yet** (QQ-04): costs below are provisional until ADR-0019.
- **Testability:** F1, F2, F3, F5, F6 and picking must run in gdUnit4 without
  a physics world (coding standards: logic stories need unit tests).

### Requirements

- F1 exactly as written, including (i) axis containment, (iii) distance to
  axis, and the `radio_pegajoso_m` retention clause (AC-04, AC-04b, AC-05,
  AC-X2b).
- Separate masks for interactables and geometry; Player body excluded
  (TR-interact-004).
- `can_interact` only for candidates that pass `habilitado_si` and for the
  retained target (TR-interact-006).
- F6 with an explicit FOV axis, valid in 16:9 and 16:10 (AC-32, AC-V6,
  TR-puzzle3-008/-009).
- `PointerEvent` with `elemento_bajo` on `seleccionar` (D7-69, 16 AC-16-04).
- Sweep ≤ 0,25 ms mean / 0,5 ms peak CPU per physics step with 40
  registered interactables; picking ≤ 0,05 ms per frame with 40 elements
  (provisional; this ADR sets them, ADR-0019 confirms on reference hardware).
- Defined behaviour in pause for sweep, press, ring, retention, gestures in
  views, tokens.

## Decision

### D1 — Collision layers and masks (project-wide 3D physics layers)

Named in `project.godot` (`layer_names/3d_physics/layer_N`, NOT SOURCEABLE
key path, S-0011-A). Numbers are part of the contract; ADR-0003's
`zone_sensor` is adopted unchanged.

| Bit | Name | Who is on it | Who masks it |
|---|---|---|---|
| 1 | `world_geometry` | Static level geometry, furniture, closed doors, the solid body of any interactable that blocks the player (e.g. `V01` desk, `C08` cabin) | Player capsule; **7's occlusion ray (only this bit)** |
| 2 | `player_body` | Player `CharacterBody3D` capsule (GDD 2 rule 5) | Nobody in 7 (excluded by construction) |
| 3 | `interactable` | One `Area3D` pick volume per catalog entry (`monitoring = false`, `monitorable = false`, mask 0) | Nobody at runtime; S-0011-A oracle and the `intersect_shape` scaling path (D11) |
| 4 | `zone_sensor` | Player zone sensor (ADR-0003 D8) | `ZoneTrigger`s |
| 5 | `zone_trigger` | `ZoneTrigger` `Area3D`s (ADR-0003 D8; layer bit recorded here so the table is complete) | Nobody (zones mask bit 4) |

Rules (must / must never):

- A pick volume **must** be on bit 3 only and **must never** be on bit 1:
  interactables do not occlude each other (GDD 7 F1 step 2: geometry mask
  "sin la capa interactuable").
- The occlusion mask is the constant `OCCLUSION_MASK = 1 << 0`. It
  **must never** include bits 2–5 (TR-interact-004). Both masks live in
  `interaction_config.json` as `mascara_interactuable` / `mascara_geometria`
  (GDD 7 Tuning Knobs) and are validated at load against this table (any other
  value is a data error, ADR-0005).
- When an interactable also has a solid body on bit 1 (its own furniture), the
  solid body's RID is listed in the entry's `self_occluders` and excluded from
  that candidate's occlusion ray (D4); a pick volume **must** enclose its solid
  body or coincide with it within `desempate_prof_m` (scene lint, T-S3).

### D2 — Pick volumes and the per-scene registry

Each catalog entry present in a scene has one `InteractablePick` node
(`Area3D` + one `CollisionShape3D` with a `BoxShape3D`) whose script exports
`interactable_id: StringName` and `self_occluders: Array[NodePath]` (own
subtree only, ADR-0009 rule 2). **Box only**: spheres, capsules and meshes are
rejected by the scene lint; a non-box object (the phone `V02`, 15 × 8 cm) gets
its tightest box. Rationale: F1 needs exact distances; ray–box and point–box
distance are closed-form and cheap, other shapes are not worth their cost in a
35-object slice.

At `configurar()`, 7 collects every `InteractablePick` under the scene root
(`get_tree().get_nodes_in_group(&"interactable_pick")` ‡, scene-local group),
checks each `interactable_id` against the catalog (unknown or duplicate = data
error, TR-interact-007) and builds a dense `PickRegistry`:

- per entry: `id`, catalog row index, `prioridad`, `alcance_c`
  (`alcance_m` or global), `half_extents: Vector3` (read once from
  `BoxShape3D.size / 2`, NOT SOURCEABLE, S-0011-A), a `Node3D` reference for
  the live `global_transform` (drawers move), the cached `habilitado_si`
  fact indices (`GameState.resolve_fact`, ADR-0001), the excluded RIDs, and a
  bounding radius `|half_extents|` for the prefilter.
- Entries are sorted by `id` once; iteration order is therefore deterministic
  and is the last tie-break key (iv) for free.

The registry is rebuilt only on scene load (7 has no persistent state,
TR-interact-021). Catalog-only IDs without a pick in the scene are allowed
(other scene); a pick without a handler at «escena lista» is a development
error (TR-interact-007).

### D3 — Candidate gathering: arithmetic, not a physics shape query

**Decision (closes V1):** the F1 contact set `C` is computed by pure GDScript
math over the registry. Neither `intersect_shape` nor `ShapeCast3D` is used to
obtain F1's contacts.

Why: F1 needs, per contact, `d_c`, axis containment and distance to axis.
`intersect_shape` (static overlap) returns at most an overlap set without
per-contact depth along the ray; `ShapeCast3D` is a motion cast that reports
contacts at its impact fraction, so farther candidates in the same sweep
(the `B02`/`B05` group of F1 example 2) are not guaranteed — both statements
are about undocumented APIs (NOT SOURCEABLE, recorded by S-0011-A, not relied
on). Any physics path would therefore need the same arithmetic afterwards; with
≤ 40 entries per scene the registry is a cheaper broadphase than a physics
query, is deterministic, and runs headless without a physics world.

For the eye ray `o + t·u` (`u` unit, from `Player.rayo_vision()` ‡, physics
state, no bob — TR-interact-002) and an entry with box `B` (local half
extents `h`, transform `T`):

1. **Prefilter:** `dist(center, ray segment [0, alcance_c]) ≤ |h| + r` else skip.
2. **Local frame:** `o' = T⁻¹·o`, `u' = T.basis⁻¹·u` (boxes are unscaled by
   lint; non-uniform scale rejected).
3. **Axis containment (i):** slab test of the ray against `[-h, h]` on
   `t ∈ [0, alcance_c]`. Hit ⇒ `contains_axis = true`, `δ = 0`,
   `d_c = t_enter`, contact point `q = o + t_enter·u`.
4. **Distance to axis (iii), no hit:** `f(t) = |o' + t·u' − clamp(o' + t·u',
   −h, h)|` is convex on `[0, alcance_c]`; golden-section search with a fixed
   **24 iterations** (bracket shrink 0,618²⁴ ≈ 1·10⁻⁵, i.e. ≤ 18 µm on 1,8 m;
   fixed count ⇒ deterministic cost) gives `t*`, `δ = f(t*)`. If `δ >
   radio_apuntado_m` the entry is not a contact. Otherwise `q = T·clamp(o' +
   t*·u', −h, h)` (closest box point to the axis) and `d_c = (q − o)·u`.
5. **Reach:** keep only `0 ≤ d_c ≤ alcance_c`.
6. **Availability:** drop if `habilitado_si` is false (direct fact read via
   cached indices, `get_fact_at`, no subscription — TR-interact-006); else call
   the handler's `can_interact(verbo)` and drop on `NO`. These two checks run
   only for entries that survived 1–5, plus the retained target (D5).

`d_c` is the axis projection of the contact point, so for a box face hit
squarely it equals the face depth — the same quantity the occlusion ray
measures (D4), which is what makes the 0,03 m tolerance meaningful.

### D4 — Occlusion: one `intersect_ray` per surviving contact

For each contact `c`, after availability:

```gdscript
var q := PhysicsRayQueryParameters3D.create(eye, c.contact_point)   # sourced
q.collision_mask = _config.mascara_geometria                       # sourced (bit 1 only)
q.exclude = c.excluded_rids                                        # NOT SOURCEABLE (S-0011-B)
var hit: Dictionary = _space.intersect_ray(q)                       # sourced
var occluded := not hit.is_empty() \
		and (hit.position - eye).dot(u) < c.d_c - _config.desempate_prof_m
```

`d_g` is measured along the axis (dot with `u`) so it is comparable with
`d_c`. A support surface under a flat object (`B05` on its table, `A04` on its
box) hits at `d_g ≈ d_c` and does not occlude (F1 example 4). The physics
query sits behind `OcclusionProbe` (D9) so unit tests use an analytic double.
Expected rays per step: one per contact that passed D3 — typically 0–3, worst
case bounded by `max_contactos_por_paso` (data, default 8; extra contacts
beyond it, in registry order, are logged once per scene in debug and ignored).

### D5 — Grouping, tie-break and retention (F1 steps 3–5)

Pure `FocusSelector` over the non-occluded contacts:

1. `d_min = min d_c`; `G = { c : d_c ≤ d_min + desempate_prof_m }`.
2. Sort `G` by the key `(not contains_axis, −prioridad, δ, id)` —
   lexicographic, `id` compared as `String` (stable, locale-free). First
   element = candidate.
3. **Retention (rule 7):** if there is a candidate it replaces the target in
   this step (always). If there is none and a target exists: the target is
   retained while `steps_since_lost ≤ N_gracia` **and** `δ_target ≤
   radio_pegajoso_m`, where `N_gracia = floori(t_gracia_foco_s ·
   physics_hz + 0,5)` (0,12 s × 60 = **7 steps**: kept for 7 steps, lost on
   the 8th) and `δ_target` is the D3 step-4 distance recomputed for that one
   entry **without** the `radio_apuntado_m` cut. `steps_since_lost` counts
   physics steps actually executed (none during pause, D10). The retained
   target is re-checked for `habilitado_si` and `can_interact`; `NO` or
   disabled ⇒ lost in the same step, no grace (rule 7, rule 3).
4. On every target change 7 calls `InputRouter.set_target_long_verb(has_largo)`
   (ADR-0006 D10) in the same step.

`physics_hz` is read from the engine's physics tick setting once at
`configurar()` ‡; tests inject it.

### D6 — Press handling, owner contract and the extended `resultado`

The handler contract is a **port defined on 7's side** (ADR-0009 D6 pattern),
typed, so owners in F2–F5 and 28 implement it through an adapter (as in D5 of
ADR-0009); 7 never names an owner class.

- `can_interact(verbo) -> InteractResult {SI, NO, SIN_EFECTO}` — pure, no side
  effects, no allocation; called at most once per entry per step.
- `etiqueta(verbo) -> StringName` — `&""` = use catalog label.
- `interact(verbo, contexto: Dictionary) -> InteractOutcome {HECHO, SIN_EFECTO}`
  — return domain **unchanged** (GDD 7 rule 29).

`interactuar` arrives through `bind_sink(EXPLORACION, &"interactuar", …)`
(ADR-0006 D6). `PressInterpreter` (pure) turns the router's
`PRESSED`/`TAP`/`LONG`/`CANCELLED` into at most one verb, applies
`t_enfriamiento_s` per object and maps to `resultado`. **Authority for the
long press is the router** (`LONG` on `RealClock`, ADR-0006 D10); 7's ring
progress `p` (F2) is presentation, computed on `GameClock` from the `PRESSED`
time and clamped at 1 until `LONG` or release arrives. The two clocks differ
only during pause, and pause cancels the press (D10), so they cannot disagree
on an outcome.

Order on a processed press (rule 3, TR-interact-008):

```text
verdict := can_interact(verbo) of THIS step (cached by the sweep)
gesture := SI ? catalog.gesto_hecho (may be none) : SIN_EFECTO ? HAND_REACH
if gesture != none and not player.reserve(gesture):   # 2 rejects (blocking gesture running)
    resultado := GESTO_RECHAZADO ; SFX_CLICK_SUBTLE ; log ; no interact()
elif verdict == SIN_EFECTO:
    resultado := SIN_EFECTO ; SFX_CLICK_SUBTLE ; pie(texto) if any ; no interact()
else:
    outcome := handler.interact(verbo, ctx)   # owner may call bloquear_contexto() inside
    resultado := (outcome == HECHO) ? HECHO : SIN_EFECTO   # SIN_EFECTO: SFX + pie; gesture runs on
short tap on a LEER-only object: resultado := TOQUE_CORTO ; ring pulse ; SFX_CLICK_SUBTLE
notify(&"interaction_executed", {id, verbo, resultado})   # once per processed press, same step
```

`resultado` is the `StringName` domain of ADR-0001 D11 (`&"HECHO"`,
`&"SIN_EFECTO"`, `&"GESTO_RECHAZADO"`, `&"TOQUE_CORTO"`); 7 is its only
producer. Muted presses (cooldown, transition) emit nothing. `SFX_CLICK_SUBTLE`
is requested by 7 through `sound_requested` (ADR-0001 registry) in the same
step, which meets `latencia_feedback_ms` 100 ms by construction (≤ 1 physics
step + 1 audio frame; T-I3 measures it).

`bloquear_contexto(razon) -> int` maps to `InputRouter.begin_blocking(owner =
&"interaction:<razon>", max_s = 3.0)`; it is accepted only while 7 is inside
`interact()` (a re-entrancy flag) or with a live token of the same owner; else
returns `-1` and logs (TR-interact-009). The 3 s cap is the router's, on
`GameClock` (ADR-0006 D5); 7 does not duplicate it. `abrir_vista(id,
desde_token)` transfers the token to the camera transition without calling
`end_blocking` in between (TR-interact-014).

### D7 — F6: `ViewMetrics` with an explicit FOV axis (closes V2 by construction)

`ViewMetrics` is an immutable value built when a view becomes `Abierta`
(`camara_cedida`) and rebuilt only if the logical viewport size reported by
`ViewportMapper` (ADR-0016) changes:

```text
inputs : W, H        logical viewport px (ViewportMapper; never assumed 1920×1080)
         fov_deg     Player.fov_actual() at camara_cedida (GDD 7 F6: read, not assumed)
         fov_axis    VERTICAL | HORIZONTAL  (from the camera's keep_aspect, D7 rule)
         d           catalog vista.distancia_m (camera → view plane, m)
         c_m         catalog vista.centro_m (view_center_m; default (0, 0))
FOV_v  = fov_axis == VERTICAL ? fov : 2·atan( tan(fov/2) · H / W )
ppm    = (H / 2) / ( d · tan(FOV_v / 2) )
px → m : m = c_m + Vector2(px.x − W/2, H/2 − px.y) / ppm      (y up in the view plane)
m → px : px = Vector2(W/2, H/2) + Vector2(m.x − c_m.x, −(m.y − c_m.y)) · ppm
tol_px = tol_m · ppm
```

Checks (AC-32): `H = 1080, d = 0,35, fov = 70° VERTICAL` → 2 203 ppm (±1),
0,04 m → 88 px, 0,10 m → 220 px; `H = 1200` → 2 448; `fov = 70° HORIZONTAL`,
`W/H = 16/9` → 3 917 (±2).

Rules:

- The Player camera **must** set `keep_aspect` to keep-height explicitly in
  its `.tscn` (property and enum names NOT SOURCEABLE, S-0011-C), so `fov` is
  vertical in every aspect and 16:10 shows the same vertical extent and less
  width — which is why GDD 13 F1b fixes 16:10 as the minimum aspect.
  `ViewMetrics` still takes `fov_axis` so the code does not silently depend on
  the default; it is read from the camera once at view open.
- `H_px` is whatever `ViewportMapper` reports. GDD 7 F6's 1200 for 16:10 is
  the expected value under `canvas_items`/`expand` and is verified, not
  assumed (S-0011-C, V4).
- `distancia_m` and `centro_m` are **new fields of the catalog `vista` /
  `modo` block** ‡ (GDD 7 rule 31; single source for 7, 10 and 13). A scene
  test asserts the anchor-to-plane distance equals `distancia_m` ± 1 mm and
  that the anchor is perpendicular to the plane (rule 19) within 0,1°.
- **Fit check (TR-puzzle3-009):** at data validation and in CI, for every view
  and for both (1920, 1080) and (1920, 1200), the union of `elements()`
  bounds must lie inside the visible rectangle with ≥ 0,09 m horizontal and
  ≥ 0,05 m vertical margin; with `centro_m = (0, 0)` on `D01a` it must fail
  (AC-27 of 13).
- **Separation check (TR-interact-018, TR-puzzle3-008, TR-puzzle4-002):**
  centres ≥ R₁ + R₂ with `R = min(max(64, tol_px), 128)`; warning by default,
  boot failure only per GDD 7 rule 22. Run with the ppm of each aspect; 13's
  "warn below 2 133 ppm" falls out of the same check.

### D8 — View picking (2D arithmetic) and `PointerEvent`

While a view is `Abierta`, `ViewPicker` (pure) maps the cursor to the view
plane with `ViewMetrics` and hit-tests the receiver's `elements()` (read at
`on_open` and on the frame after `elements_changed`, TR-interact-017):

- Shapes in view metres: `RECT {center, size, rot_deg}`, `CIRCLE {center,
  radius}`, `POLYGON {points}` (even-odd crossing test written in-house; no
  `Geometry2D`, keeps it engine-free).
- **Minimum size:** the hit area is the union of the shape and a square of side
  `pick_min_px / ppm` centred on the shape's bounding-box centre (rule 22).
- **Order among hits:** higher `z_orden`, then smaller pixel distance from the
  cursor to the element's bbox centre, then smaller `id`. Non-interactive
  elements (`D01b/rule`, the `D01c` decor IDs) are never hits.
- **Attraction targets for the router (ADR-0006 D9):** 7 is the
  `PointerTargetProvider` of `VISTA_CERCANA`; `targets()` returns one entry
  per element with `atraccion = true` and the view not
  `atraccion_desactivada`: `{id, center_px (m → px), tolerance_px (tol_m · ppm,
  or 64 if none), gestos_aceptados, focus_order}`. The list is rebuilt only
  when `elements()` or `ViewMetrics` change; `targets()` returns the cached
  array.
- **Single picking authority:** the router's `target_id` (ADR-0006 D10, used
  to freeze `gestos_aceptados`) **must** equal 7's pick. 7 therefore implements
  `target_at(p_px) -> StringName` on its provider and asks ADR-0006 to call it
  instead of its own nearest-centre lookup (amendment A-1, § Open Items).

`PointerEvent` (built by 7, delivered with `handle_pointer`):

| Field | Type | Meaning |
|---|---|---|
| `gesto` | `StringName` | `&"desplazar"`, `&"seleccionar"`, `&"agarrar"`, `&"rotar"`, `&"mantener"` |
| `fase` | `Fase` | `INICIO`, `ACTUALIZACION`, `FIN`, `CANCELACION` |
| `elemento` | `StringName` | captured at press / gesture start; `&""` for `desplazar` |
| `elemento_bajo` | `StringName` | pick under the cursor **now**; `&""` if none |
| `pos_px`, `pos_vista` | `Vector2` | current cursor, logical px and view metres |
| `pos_px_inicio` | `Vector2` | cursor at press (new field ‡, makes the single `seleccionar` event self-contained) |
| `delta_px`, `delta_grados` | `Vector2`, `float` | per GDD 7 rule 20 table |

**`elemento_bajo` on `seleccionar` (closes the `architecture.md` gap, asked by
16):** 7 caches `elemento` and `pos_px_inicio` on the router's `PRESSED`; when
the router delivers `seleccionar` (release) 7 picks again **at the release
position with the element list current at that frame** and sends **one**
event with `fase = FIN`, `elemento` = press pick, `elemento_bajo` = release pick
(`&""` if none). The comparison `elemento == elemento_bajo` is the
controller's (P6, AC-16-04). If `elements_changed` arrived between press and
release, the release pick uses the new list; the captured `elemento` is not
re-validated (rule 17: a gesture in progress keeps its eligibility).
`desplazar` / `ACTUALIZACION` events are produced by 7 polling
`InputRouter.get_cursor_position()` once per frame and only when the position
or `elemento_bajo` changed; receivers must not count them as activity (B-03).
A gesture the element does not accept is never delivered (D7-68).

### D9 — Cost per step and seams

Budget (provisional, set here; ADR-0019 confirms on reference hardware):

| Work | When | Bound | Budget |
|---|---|---|---|
| Prefilter (D3.1) | each physics step in `exploración` | n ≤ 40 entries × ~20 ops | — |
| Exact test (D3.2–5) | survivors only | ≤ 8 entries × (slab + 24 golden-section evals) | — |
| Availability (D3.6) | contacts only | ≤ 8 fact reads + ≤ 8 `can_interact` | — |
| Occlusion (D4) | contacts only | ≤ `max_contactos_por_paso` rays (8) | — |
| **Whole sweep** | per step | — | **≤ 0,25 ms mean, ≤ 0,5 ms peak** (S-0011-A measures; T-P1 guards) |
| Picking + `desplazar` | per frame in `VISTA_CERCANA` | ≤ 40 elements | **≤ 0,05 ms mean** |
| Nothing | any other context, pause, transitions | — | 0 (early return) |

No per-step allocation: candidate arrays are pre-sized members reused every
step; `get_target()` returns a cached `Dictionary` rebuilt only on change
(callers must not mutate it — documented on the method).

Seams for testing (all injected in `configurar()` or by tests):
`EyeRaySource` (Player `rayo_vision()` adapter), `OcclusionProbe`
(`PhysicsOcclusionProbe` wraps `intersect_ray`; `AnalyticOcclusionProbe` for
unit tests), `GameClock`, `InputRouter` sinks, `PromptSink`, the bus.

### D10 — Pause

7 is under `WorldSlot` (`PAUSABLE`, ADR-0002 D2). Behaviour is defined so it
is identical under Variant A (tree pause) and B (no tree pause):

- `_physics_process` starts with `if _clock.is_paused(): return` (G-4): no
  sweep, `steps_since_lost` and cooldowns do not advance (they are step or
  `GameClock` based).
- Opening the menu pushes `MENU` on the router; ADR-0006 D10 delivers
  `CANCELLED` to 7's sinks for any press or gesture in progress. 7 then:
  cancels the press (ring off, no verb, **no** `interaction_executed`, rule 28);
  in a view, sends `CANCELACION` to the receiver for the captured gesture
  (rule 21) — the view stays open.
- On the first unpaused step 7 detects the edge (`_was_paused` member, polled;
  never `paused_changed`, G-6), sets `steps_since_lost` past `N_gracia` so a
  stale target is not retained, and runs a full sweep in that step ("el
  objetivo se recalcula en el primer fotograma", rule 28).
- Tokens of `bloquear_contexto` and the 3 s caps are the router's, on
  `GameClock`: frozen by construction. `lectura_min_s` and the 3 s
  deferred-reading cap (rule 27b) are `GameClock` deadlines (`deadline`/
  `is_due`, ADR-0002 G-1).
- `get_target()` keeps returning the last value during pause; 24 is hidden
  behind the veil and re-resolves glyphs on «pausa cerrada» (ADR-0002 D2 row).

### D11 — Scaling path (not used in the slice)

If a future scene exceeds the prefilter budget (≈ > 150 entries), the
broadphase — and only the broadphase — is replaced by
`intersect_shape` with a capsule (radius `radio_apuntado_m`, axis along the
ray, length `alcance_interaccion_m`) on mask bit 3, **provided S-0011-A shows
it returns every overlap under Jolt**; D3.2–6, D4 and D5 stay unchanged. This
is the reason pick volumes are real `Area3D`s on bit 3 rather than plain
`Node3D` boxes: the oracle test and this path need them in the physics space.

### Architecture Diagram

```text
 physics step (WorldSlot PAUSABLE, after Player: S-0011-C)
 ┌──────────────────────────── InteractionSystem (7, F1) ─────────────────────────────┐
 │  EyeRaySource ── rayo_vision() ◄── Player (2)                                       │
 │        │                                                                            │
 │        ▼                                                                            │
 │  PickRegistry (≤40 boxes, sorted by id) ─► FocusSweep (D3 arithmetic)               │
 │        │                    habilitado_si ◄── GameState.get_fact_at (3, read)       │
 │        │                    can_interact  ◄── InteractionHandler ports (8,9,10,19,20,22,28)
 │        ▼                                                                            │
 │  OcclusionProbe ── intersect_ray, mask bit 1 ──► Jolt space (only physics query)    │
 │        ▼                                                                            │
 │  FocusSelector (group, tie-break, retention) ─► target ─► set_target_long_verb (1)  │
 │        │                                                    ▲                       │
 │  get_target() (cached) ◄── 24 per frame (Shell, bound ctx)  │                       │
 │                                                             │                       │
 │  sinks (1): interactuar ─► PressInterpreter ─► Player.reserve ─► handler.interact   │
 │                                   │                                                 │
 │                                   └─► notify interaction_executed {id,verbo,resultado}
 │                                                                                     │
 │  VISTA_CERCANA: cursor px (1) ─► ViewMetrics (F6) ─► ViewPicker ─► PointerEvent     │
 │                      ▲ ViewportMapper (16)     elements() ◄── ViewReceiver (9, 19)  │
 │                      └ PointerTargetProvider.targets()/target_at() ─► router (1)    │
 └─────────────────────────────────────────────────────────────────────────────────────┘
```

### Key Interfaces

Public GDD-signed operations keep the GDD literal names (`registrar_manejador`,
`get_target`, `duracion_pie`…), as ADR-0009 already does; new internal types are
English. Comments use a single `#` so `Grep ^#` lookups do not match code; real
sources use `##` doc comments.

```gdscript
# src/interaction/interaction_types.gd
class_name InteractionTypes extends RefCounted
enum InteractResult { SI, NO, SIN_EFECTO }
enum InteractOutcome { HECHO, SIN_EFECTO }
enum Mode { NINGUNO, INSPECCION, LECTURA, VISTA, ORDENADOR }
enum Fase { INICIO, ACTUALIZACION, FIN, CANCELACION }
enum FovAxis { VERTICAL, HORIZONTAL }
const RESULTADO_HECHO: StringName = &"HECHO"
const RESULTADO_SIN_EFECTO: StringName = &"SIN_EFECTO"
const RESULTADO_GESTO_RECHAZADO: StringName = &"GESTO_RECHAZADO"
const RESULTADO_TOQUE_CORTO: StringName = &"TOQUE_CORTO"
const PIE_PERSISTENTE: float = -1.0          # sentinel of duracion_pie (not INF: survives JSON/clamp)
const OCCLUSION_MASK: int = 1 << 0           # world_geometry (D1)
const LAYER_INTERACTABLE: int = 1 << 2

class ContactInfo extends RefCounted:        # reused, pre-sized pool (D9)
	var entry: int                           # PickRegistry index
	var d_c: float                           # axis depth of contact point (m)
	var delta: float                         # distance to axis (m); 0 if contains_axis
	var contains_axis: bool
	var contact_point: Vector3

class PointerEvent extends RefCounted:
	var gesto: StringName
	var fase: Fase
	var elemento: StringName = &""
	var elemento_bajo: StringName = &""
	var pos_px: Vector2
	var pos_px_inicio: Vector2
	var pos_vista: Vector2                   # view metres
	var delta_px: Vector2
	var delta_grados: float
```

```gdscript
# src/interaction/ports/interaction_handler.gd — implemented by owners' adapters
@abstract class_name InteractionHandler extends RefCounted
@abstract func can_interact(verbo: StringName) -> InteractionTypes.InteractResult   # pure, cheap
@abstract func interact(verbo: StringName, contexto: Dictionary) -> InteractionTypes.InteractOutcome
func etiqueta(_verbo: StringName) -> StringName: return &""                       # &"" = catalog label

# src/interaction/ports/view_receiver.gd — implemented by 9 (one per puzzle view) and 19 (V01)
@abstract class_name ViewReceiver extends RefCounted
signal elements_changed
@abstract func elements() -> Array[ViewElement]
@abstract func handle_pointer(ev: InteractionTypes.PointerEvent) -> void
@abstract func on_open() -> void
@abstract func on_close(motivo: StringName) -> void

# src/interaction/view_element.gd
class_name ViewElement extends RefCounted
enum Shape { RECT, CIRCLE, POLYGON }
var id: StringName
var shape: Shape
var center_m: Vector2
var size_m: Vector2                         # RECT
var rot_deg: float                          # RECT
var radius_m: float                         # CIRCLE
var points_m: PackedVector2Array            # POLYGON
var z_orden: int
var atraccion: bool
var interactivo: bool = true
var tolerancia_m: float = -1.0              # -1 = none → R = 64 px
var gestos_aceptados: Array[StringName]
var focus_order: int

# src/interaction/ports/prompt_sink.gd — closes ADR-0009 O2 for PromptSink; implemented by 24
@abstract class_name PromptSink extends RefCounted
@abstract func mostrar_pie(clave: StringName, duracion_s: float, retener: bool) -> void  # duracion_s may be PIE_PERSISTENTE
@abstract func ocultar_pie() -> void

# src/interaction/ports/interaction_query.gd — closes ADR-0009 O2 for InteractionQuery (P3, 13)
@abstract class_name InteractionQuery extends RefCounted
@abstract func view_ppm() -> float                             # 0.0 if no view Abierta
@abstract func meters_to_px(m: float) -> float
@abstract func view_to_px(p_m: Vector2) -> Vector2
@abstract func px_to_view(p_px: Vector2) -> Vector2
```

```gdscript
# src/interaction/view_metrics.gd — pure value, F6 (D7)
class_name ViewMetrics extends RefCounted
var w_px: float
var h_px: float
var ppm: float
var center_m: Vector2

static func build(w: float, h: float, fov_deg: float, axis: InteractionTypes.FovAxis,
		distance_m: float, center: Vector2) -> ViewMetrics:
	assert(w > 0.0 and h > 0.0 and distance_m > 0.0 and fov_deg > 0.0 and fov_deg < 180.0)
	var half: float = deg_to_rad(fov_deg) * 0.5
	var half_v: float = half if axis == InteractionTypes.FovAxis.VERTICAL \
			else atan(tan(half) * h / w)
	var vm := ViewMetrics.new()
	vm.w_px = w
	vm.h_px = h
	vm.ppm = (h * 0.5) / (distance_m * tan(half_v))
	vm.center_m = center
	return vm

func px_to_view(p: Vector2) -> Vector2:
	return center_m + Vector2(p.x - w_px * 0.5, h_px * 0.5 - p.y) / ppm

func view_to_px(m: Vector2) -> Vector2:
	var d: Vector2 = (m - center_m) * ppm
	return Vector2(w_px * 0.5 + d.x, h_px * 0.5 - d.y)
```

```gdscript
# src/interaction/focus/pick_math.gd — pure, D3 steps 2–4
class_name PickMath extends RefCounted
const GOLDEN_ITERATIONS: int = 24
const INV_PHI: float = 0.6180339887

# Fills `out` and returns true if the box is a contact (δ ≤ radius, 0 ≤ d_c ≤ reach).
static func measure(o: Vector3, u: Vector3, xf: Transform3D, h: Vector3,
		radius: float, reach: float, out: InteractionTypes.ContactInfo) -> bool:
	var inv: Transform3D = xf.affine_inverse()
	var lo: Vector3 = inv * o
	var lu: Vector3 = inv.basis * u
	var t_enter: float = slab_enter(lo, lu, h, reach)       # -1.0 if no hit in [0, reach]
	if t_enter >= 0.0:
		out.contains_axis = true
		out.delta = 0.0
		out.d_c = t_enter
		out.contact_point = o + u * t_enter
		return true
	var a: float = 0.0
	var b: float = reach
	var c: float = b - (b - a) * INV_PHI
	var d: float = a + (b - a) * INV_PHI
	for i in GOLDEN_ITERATIONS:
		if _dist(lo + lu * c, h) < _dist(lo + lu * d, h):
			b = d
		else:
			a = c
		c = b - (b - a) * INV_PHI
		d = a + (b - a) * INV_PHI
	var t_star: float = (a + b) * 0.5
	var p: Vector3 = lo + lu * t_star
	var delta: float = _dist(p, h)
	if delta > radius:
		return false
	var q: Vector3 = xf * p.clamp(-h, h)
	var d_c: float = (q - o).dot(u)
	if d_c < 0.0 or d_c > reach:
		return false
	out.contains_axis = false
	out.delta = delta
	out.d_c = d_c
	out.contact_point = q
	return true

static func _dist(p: Vector3, h: Vector3) -> float:
	return (p - p.clamp(-h, h)).length()

static func slab_enter(lo: Vector3, lu: Vector3, h: Vector3, reach: float) -> float:
	var t0: float = 0.0
	var t1: float = reach
	for k in 3:
		if absf(lu[k]) < 1e-9:
			if lo[k] < -h[k] or lo[k] > h[k]:
				return -1.0
			continue
		var ta: float = (-h[k] - lo[k]) / lu[k]
		var tb: float = (h[k] - lo[k]) / lu[k]
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
		if t0 > t1:
			return -1.0
	return t0
```

```gdscript
# src/interaction/interaction_system.gd — F1 scene node (excerpt; GDD-signed API)
class_name InteractionSystem extends Node3D

var _clock: GameClock
var _state: GameState                         # soft (GDD 7: blanda 3); see contradiction C2
var _settings: Settings                       # soft (GDD 7: blanda 6): multiplicador_pie, pie_persistente
var _input: InputRouter
var _scenes: SceneLoader
var _player: Player
var _content: ContentDB
var _prompt: PromptSink                       # soft (null object)
var _config: InteractionConfig                # interaction_config.json (D1 masks, F1/F2/F5 knobs)
var _probe: OcclusionProbe
var _registry: PickRegistry
var _selector := FocusSelector.new()
var _press := PressInterpreter.new()
var _view_provider := ViewPointerProvider.new()   # PointerTargetProvider of VISTA_CERCANA (D8)
var _target_cache_dirty: bool = true
var _was_paused: bool = false
var _subs := SubscriptionBag.new()

func configurar(ctx: ServiceContext) -> void:
	# hard deps per GDD 7: 1, 2, 4, 18 (+ GameClock, ADR-0002 G-1)
	if not ctx.require(&"interaction", [&"clock", &"input", &"scenes", &"content", &"scene.player"]):
		return
	_clock = ctx.clock
	_state = ctx.state
	_settings = ctx.settings
	_input = ctx.input
	_scenes = ctx.scenes
	_content = ctx.content
	_player = ctx.scene.player
	_prompt = ctx.ui.prompt_sink if ctx.ui != null else NullPromptSink.new()
	_config = InteractionConfig.from_content(_content)      # validated by ADR-0005 at boot
	_probe = PhysicsOcclusionProbe.new(get_world_3d())
	_registry = PickRegistry.build(self, _content, _state)   # D2; data errors → ctx.fatal
	_input.bind_sink(InputTypes.Context.EXPLORACION, &"interactuar", _on_interactuar)
	_input.set_pointer_provider(InputTypes.Context.VISTA_CERCANA, _view_provider)

# Registration (before «escena lista», TR-interact-007)
func registrar_manejador(id: StringName, manejador: InteractionHandler) -> void: pass
func registrar_receptor(vista_id: StringName, receptor: ViewReceiver) -> void: pass

func _physics_process(_dt: float) -> void:
	var paused: bool = _clock.is_paused()
	if paused:
		_was_paused = true
		return                                 # D10, G-4
	if _was_paused:
		_was_paused = false
		_selector.drop_retention()              # rule 28: recompute, no stale grace
	if _input.top() != InputTypes.Context.EXPLORACION or _input.is_loading():
		_selector.clear()
		return
	var ray: Array = _player.rayo_vision()      # [origin: Vector3, dir: Vector3] ‡ ADR-0012
	var target_changed: bool = _selector.step(ray[0], ray[1], _registry, _probe, _config)
	if target_changed:
		_input.set_target_long_verb(_selector.target_has_long_verb())
		_target_cache_dirty = true

# Queries
func get_target() -> Dictionary: return {}      # {id, etiqueta, largo, p, anillo_visible} | {}; cached, do not mutate
func duracion_pie(clave: StringName) -> float: return 0.0   # F5 × multiplicador_pie | PIE_PERSISTENTE
func modo_actual() -> InteractionTypes.Mode: return InteractionTypes.Mode.NINGUNO
func query_port() -> InteractionQuery: return null          # handed to 9 for P3's PuzzleServices

# Modes and views (GDD 7 rule 30; behaviour per rules 19–27, unchanged by this ADR)
func abrir_vista(vista_id: StringName, desde_token: int = -1) -> Dictionary: return {}
func cerrar_vista(vista_id: StringName, motivo: StringName) -> void: pass
func abrir_lectura(doc_id: StringName) -> Dictionary: return {}
func cerrar_lectura(motivo: StringName) -> void: pass
func cerrar_modos() -> void: pass
func bloquear_contexto(razon: StringName) -> int: return -1
func liberar_contexto(token: int) -> void: pass
```

### Implementation Guidelines

- **G-1** F1 contacts **must** be computed by `PickMath` over `PickRegistry`;
  `intersect_shape` and `ShapeCast3D` **must never** be used for focus in the
  slice (D3, D11).
- **G-2** The only physics query in 7 **must** be `intersect_ray` with
  `collision_mask = mascara_geometria` (bit 1), behind `OcclusionProbe`.
- **G-3** Every pick volume **must** be a single unscaled `BoxShape3D` on
  layer bit 3 only, `monitoring` and `monitorable` off; scene lint rejects
  anything else.
- **G-4** `_physics_process` **must** start with the pause guard and **must**
  return early outside stable `EXPLORACION` (D10).
- **G-5** `can_interact` **must** be called only for D3 survivors and the
  retained target, at most once per entry per step; handlers **must** be
  side-effect free in it.
- **G-6** 7 **must** emit exactly one `interaction_executed` per processed
  press with `resultado` from `InteractionTypes.RESULTADO_*`; never in
  cooldown, transition or a cancelled press.
- **G-7** `ViewMetrics` **must** be the only place where px ↔ m conversion
  happens; puzzle code gets it through `InteractionQuery`. Nobody may hardcode
  1080, 1920, 70° or 1 200 ppm.
- **G-8** The Player camera **must** set keep-height explicitly in its
  `.tscn` (S-0011-C names the property); `ViewMetrics` **must** receive the
  axis, never assume it.
- **G-9** `seleccionar` **must** reach the receiver as one `FIN` event with
  `elemento` (press pick) and `elemento_bajo` (release pick).
- **G-10** No per-step allocation in the sweep; `get_target()` returns a
  cached dictionary.
- **G-11** 7 **must never** connect to `GameClock.paused_changed`; pause is
  detected by polling `is_paused()` (ADR-0002 G-6).

## Alternatives Considered

### Alternative 1: `intersect_shape` with a capsule as the F1 mechanism

- **Description**: Each step, one `intersect_shape` (capsule along the ray,
  mask bit 3, `collide_with_areas`) returns the overlapping pick volumes; F1
  runs on that set.
- **Pros**: Scales to many interactables; the physics broadphase does the
  culling.
- **Cons**: API and Jolt behaviour NOT SOURCEABLE; returns overlaps without
  per-contact depth or axis distance, so D3's arithmetic is still required;
  needs a physics world in every F1 test; `max_results` truncation is a new
  failure mode.
- **Estimated Effort**: Same as chosen plus a gating spike.
- **Rejection Reason**: Adds an unsourced dependency and no information F1
  needs at ≤ 40 entries. Kept as the scaling path for the broadphase only
  (D11), conditional on S-0011-A.

### Alternative 2: `ShapeCast3D` node (sphere swept along the ray)

- **Description**: A `ShapeCast3D` child of the camera, sphere radius
  0,06 m, `target_position` at reach, read `get_collision_count()` each step.
- **Pros**: Editor-visible; one node.
- **Cons**: A motion cast reports contacts at its impact fraction, not every
  object along the sweep (NOT SOURCEABLE, recorded by S-0011-A), which breaks
  F1's group `G` (example 2) and retention distance; update timing relative to
  7's `_physics_process` is node-driven (lag or `force_shapecast_update`);
  node state complicates headless unit tests.
- **Estimated Effort**: Lower to wire, higher to make correct.
- **Rejection Reason**: Cannot be shown to return all contacts; F1 would
  degrade the way the 7-ray fallback does (D7-37).

### Alternative 3: 7-ray `intersect_ray` fan (GDD 7 D7-27 fallback)

- **Description**: 1 central + 6 ring rays of radius `radio_apuntado_m`.
- **Pros**: Uses only the sourced API.
- **Cons**: No distances to untouched colliders: (iii) approximated, retention
  loses `radio_pegajoso_m`; GDD 7 explicitly says it does not satisfy F1;
  7 rays per step cost more than D3's arithmetic.
- **Estimated Effort**: Low.
- **Rejection Reason**: Declared non-compliant by the GDD (D7-37).

### Alternative 4: Physics raycast picking in views (3D colliders per element)

- **Description**: Elements as `Area3D`s; picking by `intersect_ray` from
  the camera through the cursor.
- **Pros**: Works with arbitrary meshes.
- **Cons**: GDD 7 rule 20 forbids it (picking is "aritmética pura y
  comprobable sin motor"); needs camera unprojection (NOT SOURCEABLE);
  `pick_min_px` enlargement becomes geometry edits.
- **Rejection Reason**: Contradicts rule 20 and testability.

### Alternative 5: Assume vertical FOV and H = 1080 (no axis, no mapper)

- **Rejection Reason**: Exactly the V2/V4 risk GDD 7 refuses to assume; a
  wrong axis is a 78 % ppm error (2 203 vs 3 917), which would break every
  tolerance in P1–P6.

## Consequences

### Positive

- F1 is implementable as written, including (iii) and the retention distance;
  AC-05's distance clause is unblocked by design, pending only S-0011-B for
  occlusion depth.
- The whole focus and picking logic runs headless in gdUnit4 with doubles;
  only occlusion needs physics (integration tests).
- Deterministic: fixed iteration counts, sorted registry, lexicographic
  tie-break.
- One px ↔ m authority (`ViewMetrics`) shared by 7, 9, 13 and the data
  validator; 16:10 behaviour is computed, not hoped for.
- Closes ADR-0009 O2 for `PromptSink` and `InteractionQuery`, and the
  `elemento_bajo` gap of `architecture.md`.

### Negative

- Pick volumes must be boxes, and a pick volume must be kept consistent with
  its object's solid body (lint T-S3) — level-design discipline.
- Two new catalog fields (`distancia_m`, `centro_m`) and one new
  `PointerEvent` field (`pos_px_inicio`) need GDD 7 edits.
- ADR-0006 needs an amendment (`target_at`) so router and 7 agree on the
  element under the cursor.
- O(n) prefilter does not scale past ~150 entries (D11 covers it).

### Neutral

- Layer bit assignments become a project-wide contract (D1).
- Ports are `RefCounted` adapters (`@abstract`), not `Node` bases as
  `architecture.md` § Interacción sketches for `ViewReceiver`.

## Risks

| ID | Risk | Mitigation |
|---|---|---|
| R1 | Jolt ray-hit depth on box faces is off by its convex radius/margin, so supports occlude flat objects (`B05`, `A04`) or walls fail to | S-0011-B measures the error; decision rule there. `desempate_prof_m` range 0,01–0,08 already absorbs ≤ 1 cm |
| R2 | `PhysicsRayQueryParameters3D.exclude` absent or different | S-0011-B; fallback: re-cast from `hit.position + u·1 mm` up to 4 times skipping `self_occluders` RIDs |
| R3 | Player and 7 physics order not controllable → eye ray one step stale | S-0011-C; fallback: tree order (7 after Player under the scene root) and record; a 1-step lag at 60 Hz is within `t_gracia_foco_s` |
| R4 | Camera FOV axis cannot be pinned, or `expand` yields an unexpected logical H in 16:10 | `ViewMetrics` takes both as inputs; only AC-32's expected numbers change (GDD edit), not code |
| R5 | GDScript cost of the golden-section loop exceeds budget | Prefilter keeps survivors ≤ 8; T-P1 guards; fallback: analytic segment–box distance (12 edges + 2 endpoints) |
| R6 | Owners return non-pure `can_interact` (side effects) | Review rule G-5 + unit test per handler calling it twice and comparing state |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| interaccion-e-inspeccion.md (7) | **TR-interact-002…006**: sweep per physics step in `exploración` with `rayo_vision()`; all contacts of the 0,06 m sphere (V1); separate masks, Player layer excluded, 0,03 m occlusion tolerance; retention 7 steps + 0,15 m; `can_interact` only for candidates | D1–D5, D10; G-1…G-5 |
| interaccion-e-inspeccion.md (7) | **TR-interact-007…011**: handler contract and registration; gesture reserved before `interact()`; `bloquear_contexto` token, 3 s cap; long-press timing F2; feedback ≤ 100 ms | D6 (port, order, router authority, `begin_blocking` mapping, same-step SFX) |
| interaccion-e-inspeccion.md (7) | **TR-interact-012…014, 019…021**: mode stack, camera hand-off, D01a–c chain, inspection F3, `abrir_lectura` table, no state | Behaviour unchanged from the GDD; this ADR fixes the API surface (Key Interfaces), the token transfer (D6) and pause semantics (D10). F3 is pure math in `InspectionMath` (T-U9) |
| interaccion-e-inspeccion.md (7) | **TR-interact-015…018**: arithmetic 2D picking; F6 ppm; `PointerEvent` incl. `elemento_bajo`; `gestos_aceptados` and re-read after `elements_changed`; `pick_min_px`, separation R₁+R₂ | D7, D8; G-7…G-9 |
| interaccion-e-inspeccion.md (7) | **TR-interact-022**: target not on the bus; 24 polls `get_target()`; pie via `mostrar_pie(clave, duracion_pie(clave), retener)`; F5 | `PromptSink` port signature; cached `get_target()` (D9); `PIE_PERSISTENTE` sentinel |
| interaccion-e-inspeccion.md (7) | **TR-interact-001**: catalog schema | Partial: two new `vista` fields (D7); schema validation is ADR-0005's |
| puzle-3-encaje-de-la-foto (13) | **TR-puzzle3-008**: ppm with d = 0,35 m, 70°, 2 203 / 2 448; controller in metres, 7 converts; separation warning < 2 133 ppm | D7 (`ViewMetrics`, `InteractionQuery`), separation check |
| puzle-3-encaje-de-la-foto (13) | **TR-puzzle3-009**: `view_center_m` (0,185; 0) subtracted in screen→metres; fit in 16:9 and 16:10 with margins; (0; 0) must fail | D7 `centro_m` and fit check at both aspects |
| puzle-4-tablero-de-tareas.md (14) | **TR-puzzle4-002**: 28 pointable elements, ≥ 44 px, centres ≥ 128 px | D8 minimum size; D7 separation check with R = 64 |
| prompt-de-interaccion.md (24) | Contract 24↔7: `anillo_visible`, `duracion_pie`, `resultado`, `get_target` | `get_target()` fields, `duracion_pie`, `RESULTADO_*`, `PromptSink` |
| puzle-6 (16) | `elemento_bajo` on `seleccionar` (AC-16-04) | D8, G-9 |

## Performance Implications

- **CPU**: sweep ≤ 0,25 ms mean / 0,5 ms peak per physics step with 40
  entries (≤ 8 occlusion rays); picking ≤ 0,05 ms per frame in views; zero
  outside `exploración` / views and in pause. Provisional until ADR-0019.
- **Memory**: registry ≈ 40 × ~200 B; pre-sized contact pool of 8; no
  per-step allocation.
- **Load Time**: registry build at `configurar()`, O(n log n), < 1 ms.
- **Network**: N/A.

## Migration Plan

No existing code. Order of stories: (1) `PickMath`, `FocusSelector`,
`ViewMetrics`, `ViewPicker`, `PressInterpreter` with unit tests; (2) spikes;
(3) `InteractionSystem` wiring and integration tests; (4) catalog fields and
scene lint.

**Rollback plan**: if S-0011-B shows occlusion is unusable under Jolt, replace
`PhysicsOcclusionProbe` with an arithmetic probe over `OccluderBox` proxies on
bit 1 (same interface); if D3 misses budget, swap the broadphase to D11. Both
are local to one class.

## Validation Criteria

### Spikes (must run on Godot 4.7.2 before `Accepted`)

**S-0011-A — Shape queries under Jolt and sweep cost.** Setup: Jolt, 60 Hz;
40 `InteractablePick` boxes (bit 3) laid out like `planta` (incl. a `B02`/`B05`
pair 2 cm apart and `V02` 15 × 8 cm). Record: (a) `intersect_shape` with a
capsule and `collide_with_areas`: does it return every overlapping box, in what
order, with which keys; (b) `ShapeCast3D` sphere sweep: which of the boxes along
the sweep it reports; (c) `BoxShape3D.size`, layer names in `project.godot`;
(d) cost of D3+D5 with 40 entries over 600 steps (mean, p99) on the dev
machine. **Decision rule:** D3 stays regardless of (a)/(b). If (d) mean >
0,25 ms → apply R5 fallback; D11 is enabled only if (a) returns all overlaps.
Cross-check: D3's contact set equals (a)'s overlap set on 1 000 random rays
(oracle; difference = bug in `PickMath` or lint).

**S-0011-B — Occlusion ray under Jolt.** Rays against `BoxShape3D` faces at
0,5–1,8 m, normal and 60° incidence: depth error vs analytic; `exclude` with
the candidate's solid body; mask bit 1 ignores bits 2–5; ray starting inside a
box. **Decision rule:** error ≤ 5 mm → as designed; 5–10 mm → raise
`desempate_prof_m` floor to 3 × error and record; > 10 mm or `exclude`
missing → R2 / rollback probe.

**S-0011-C — Camera FOV axis, logical viewport, physics order.** Window 1920 ×
1080, 1920 × 1200, 2560 × 1600 with `canvas_items`/`expand`: logical size
reported to `ViewportMapper`; with keep-height, measure on-screen size of a
known 0,10 m quad at 0,35 m and compare with `ViewMetrics` (± 2 px); without
it, record the default axis. Two `_physics_process` nodes with
`process_physics_priority` 0 / 10: observed order over 600 steps.
**Decision rule:** measured px within ± 2 px of `ViewMetrics` in all three
windows → AC-32 numbers confirmed; otherwise update the GDD expected values
(code unchanged). Order not controllable → R3 fallback.

### Test plan

| ID | Type | File | Covers |
|---|---|---|---|
| T-U1 | Unit | `tests/unit/interaction/pick_math_test.gd` | Slab hit, grazing within 0,06 m, miss at 0,061 m, reach cut, rotated box, determinism (same input twice) — TR-interact-003 |
| T-U2 | Unit | `tests/unit/interaction/focus_selector_test.gd` | F1 examples 1–4 (V02 edge; B02/B05 Δ 0,02 → B05; Δ 0,10 → B02; axis beats priority; support does not occlude via analytic probe) — AC-04, AC-04b, TR-interact-004 |
| T-U3 | Unit | `tests/unit/interaction/focus_retention_test.gd` | Kept 7 steps, lost on 8th; lost at δ 0,151 m; new candidate replaces at once; `NO` drops without grace; no step counting while paused — AC-05 (distance clause), TR-interact-005 |
| T-U4 | Unit | `tests/unit/interaction/press_interpreter_test.gd` | Order reserve → interact; `GESTO_RECHAZADO` without `interact()`; `SIN_EFECTO` paths; `TOQUE_CORTO`; cooldown mute; one notice per press; ring `p` and `anillo_visible` at 0,12 s — TR-interact-008, -010 |
| T-U5 | Unit | `tests/unit/interaction/view_metrics_test.gd` | 2 203 / 88 / 220; 2 448 at H 1200; 3 917 horizontal control; px↔m round trip with `centro_m` — AC-32, TR-puzzle3-008 |
| T-U6 | Unit | `tests/unit/interaction/view_picker_test.gd` | RECT/CIRCLE/POLYGON; `pick_min_px` enlargement; `z_orden`, distance, id order; non-interactive never hit; `elemento_bajo` at release differs after cursor move; re-read after `elements_changed` — TR-interact-015…017, AC-16-04 |
| T-U7 | Unit | `tests/unit/interaction/view_layout_validation_test.gd` | Separation R₁+R₂ (176 / 256 px); fit in 16:9 and 16:10 with margins; `D01a` with (0,0) fails; P4 28 elements ≥ 128 px — TR-interact-018, TR-puzzle3-009, TR-puzzle4-002 |
| T-U8 | Unit | `tests/unit/interaction/blocking_token_test.gd` | Token only inside `interact()`; transfer by `abrir_vista(desde_token)`; idempotent release — TR-interact-009, -014 |
| T-U9 | Unit | `tests/unit/interaction/inspection_math_test.gd` | F3 `d_ins` examples (V05 0,469 m; r 0,20 → 0,60) — TR-interact-019 |
| T-U10 | Unit | `tests/unit/interaction/pause_behaviour_test.gd` | Paused clock: no sweep; `CANCELLED` cancels press without notice; view stays open and receiver gets `CANCELACION`; first unpaused step re-sweeps without grace — rule 28, D10 |
| T-I1 | Integration | `tests/integration/interaction/occlusion_jolt_test.gd` | S-0011-B cases as regression (physics, headless) |
| T-I2 | Integration | `tests/integration/interaction/oracle_crosscheck_test.gd` | S-0011-A cross-check on a fixed seed list of rays (seeded list stored as fixture, deterministic) |
| T-I3 | Integration | `tests/integration/interaction/feedback_latency_test.gd` | `sound_requested` and `interaction_executed` in the same step as the press — TR-interact-011 |
| T-P1 | Performance | `tests/performance/interaction/sweep_cost_test.gd` | 40 entries, 600 steps; mean ≤ 0,25 ms, p99 ≤ 0,5 ms (advisory until ADR-0019) |
| T-S3 | Scene lint | `tests/integration/interaction/pick_volume_lint_test.gd` | Box only, bit 3 only, unscaled, encloses solid body; anchor distance = `distancia_m` ± 1 mm, perpendicular ± 0,1° |
| V-1 | Visual | `production/qa/evidence/` | AC-V6: `D01a` in 16:9 and 16:10 with debug overlay of hit areas |

### Success criteria

We will know this was right if: AC-04, AC-04b, AC-05 (with distance) and
AC-32 pass headless; S-0011-B error ≤ 5 mm; T-P1 within budget; and the
playtest reports no "icon flicker" or "can't click the small thing" findings
on `V02`, `B05` and the P4 board.

## Spike Results

_Not run yet._

## Open Items

| ID | Item | Owner / route |
|---|---|---|
| OI-1 | Run S-0011-A/B/C and fill § Spike Results | Implementation, S0 |
| OI-2 | GDD 7 rule 31: add `distancia_m` (required on views) and `centro_m` (optional, default (0,0)) to the `vista`/`modo` schema; GDD 13 reads them instead of its own `view_distance_m` | game-designer (GDD 7, 13) |
| OI-3 | GDD 7 rule 20 table: add `pos_px_inicio`; `seleccionar` = one `FIN` event (wording "inicio y fin en el mismo fotograma") | game-designer (GDD 7) |
| OI-4 | `Player.rayo_vision()` return type, `fov_actual()`, gesture reservation call (`reserve`) and keep-height on the camera | ADR-0012 (Player) ‡ |
| OI-5 | `ViewportMapper` change notification (or 7 polls size each frame in views — current choice) | ADR-0016 |
| OI-6 | Size of the `D01b` board and its `distancia_m` (GDD 14 OQ 1); the separation check will validate whatever is chosen | 7 / 10 / art |

### Amendments requested to other ADRs (A-1…A-3 applied 2026-11-10 in ADR-0006 / ADR-0009; A-4 targets `architecture.md`, pending)

| # | Target | Amendment |
|---|---|---|
| A-1 | ADR-0006 | `PointerTargetProvider.target_at(p_px: Vector2) -> StringName` (default: nearest centre within `tolerance_px`); `GestureRecognizer` uses it at press so `ActionEvent.target_id` equals 7's pick (D8) |
| A-2 | ADR-0009 D4 | Row 7 (F1): add `3` (read only: `get_fact_at`, `resolve_fact`) and `6` (read `multiplicador_pie`, `pie_persistente`) — both soft in GDD 7 |
| A-3 | ADR-0009 D3 example | `registrar_manejador(&"A03", self)` → pass an `InteractionHandler` adapter (typed port, D6) |
| A-4 | `architecture.md` § Interacción (7) | `ViewReceiver` is a `RefCounted` port, not `extends Node`; `duracion_pie` sentinel `PIE_PERSISTENTE = -1.0`, not `INF`; `elemento_bajo` gap closed (D8) |

### Contradictions detected (for `/architecture-review`)

1. **C1 — ADR-0006 D9 vs GDD 7 F6:** ADR-0006 says the cursor lives in
   "logical 1920×1080 pixels"; GDD 7 F6 expects `H_px` = 1200 in 16:10 with
   `expand`. Resolved here in favour of "whatever `ViewportMapper` reports"
   (D7); ADR-0006's figure is read as the 16:9 reference. ADR-0016 owns the
   final number.
2. **C2 — ADR-0009 D4 vs GDD 7 dependencies:** the allowed-calls row for 7
   lists 1, 2, 4, 18 only, but GDD 7 reads facts of 3 (`habilitado_si`, rule 8)
   and settings of 6 (rule 12). Amendment A-2.
3. **C3 — ADR-0006 D10 vs GDD 7 rule 20:** the router determines the target
   under the cursor from `center_px`/`tolerance_px` circles, while GDD 7 picks
   by shape, `z_orden` and `pick_min_px`. Two authorities can disagree on
   `gestos_aceptados`. Amendment A-1.
4. **C4 — ADR-0006 D10 vs GDD 7 F2 / rule 32:** long press on `RealClock` in
   the router vs game time in GDD 7. Resolved: the router fires `LONG`; 7's
   ring `p` is presentation on `GameClock`; they differ only in pause, which
   cancels the press (D6, D10). No GDD change needed beyond a note.
5. **C5 — `architecture.md` `duracion_pie` "INF = PERSISTENTE" vs GDD 7
   rule 30 "centinela p. ej. -1":** resolved to `-1.0` (A-4).
6. Reconciliation 2026-11-10 G16 (24 polls `bindings_revision()`) and G18
   (24 px floor) do not touch 7's contract; G26 (upward calls → output ports)
   is applied here through `InteractionHandler`, `ViewReceiver` and
   `PromptSink`.

## Related

- ADR-0001 Event bus and fact contract (depends on: `interaction_executed`
  D11, `get_fact_at`, notice registry of 7)
- ADR-0002 Pause and game time (depends on: `GameClock`, G-4, G-6)
- ADR-0003 Scene loading (depends on: D8 `zone_sensor` layer, `configurar`
  order)
- ADR-0006 Input abstraction (depends on; amendment A-1)
- ADR-0009 Service composition (depends on; closes O2 for `PromptSink` and
  `InteractionQuery`; amendments A-2, A-3)
- ADR-0010 Puzzle framework, ADR-0012 Player, ADR-0016 UI/prompt (enabled)
- `design/gdd/interaccion-e-inspeccion.md` (F1, F2, F5, F6; rules 3, 5–12,
  19–23, 27–32; V1, V2, V4)
- `docs/architecture/tr-baseline-provisional.md` (TR-interact-001…022,
  TR-puzzle3-008/-009, TR-puzzle4-002)

