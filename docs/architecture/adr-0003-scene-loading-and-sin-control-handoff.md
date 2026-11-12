# ADR-0003: Scene Loading, Shell and `sin control` Handoff

## Status

Accepted (2026-11-11) — spikes S-0003-A/B run on 4.7.2 (sensor range corrected to (8.95; 8.977], see O8); S-0003-C (synchronous load hitch) deferred until the grey `planta` exists

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`. It cannot
> move to `Accepted` before spikes S-0003-A and S-0003-B (§ Validation Criteria)
> have run on Godot 4.7.2 and their results are written into § Spike Results.

## Date

2026-11-10

## Last Verified

2026-11-10 (against `docs/engine-reference/godot/` as last verified 2026-10-17,
`design/gdd/escena-de-planta.md` round 10, `docs/architecture/architecture.md` v1)

## Decision Makers

technical-director (autonomous mode, `modes.automation: autonomous`); user
approval pending at batch close.

## Summary

System 4 (Escena de planta) needs a load/unload mechanism that keeps the UI,
the curtain and the persistent systems alive across `title` → `planta` →
`recepcion` → title, runs the GDD's 9-step sequence with holds and a real-time
`T_cap`, and hands the load's `sin control` to the scene director (21) in the
«carga de escena terminada» frame without a single uncontrolled frame. Decided:
a never-unloaded `Shell` main scene with a single `WorldSlot` into which the
`SceneLoader` autoload instantiates a fresh `PackedScene` instance per load
(no `change_scene_to_*`), a frame-driven synchronous load state machine, a
per-scene Player rebuilt with `colocar` (closes QQ-12), and `Area3D` zone
sensors gated until «terminada» — the engine-dependent parts behind two spikes.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Core (scene tree, resource loading) · Physics (zone sensors) · Input (stack handoff, contract only) |
| **Layer** | Core |
| **Knowledge Risk** | HIGH (Core/Scene and Physics/Jolt rows of `architecture.md` § Engine Knowledge Gap Summary) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `deprecated-apis.md` (rows `PackedScene.instance()` → `PackedScene.instantiate()`, Jolt default); `modules/physics.md` (Jolt default since 4.6, 4.7 `Area3D` reports `SoftBody3D` overlaps, "collision margins may behave differently"); `breaking-changes.md` (same Jolt rows); `current-best-practices.md` § testing (gdUnit4 exit 101 when a test leaks orphan nodes); `docs/architecture/architecture.md` §§ Module Ownership, Data Flow 4–6, API Boundaries/Escena, Required ADRs, QQ-12 |
| **Post-Cutoff APIs Used** | Jolt as default 3D physics (4.6) — zone sensors run on it. No other post-cutoff API is relied on. |
| **Verification Required** | S-0003-A (instantiate/free ×10, orphan and node counts, `queue_free` completion timing, also with the tree paused); S-0003-B (`Area3D` zone vs 0,05 m sensor under Jolt: entry X range, one entry per crossing, simultaneous entries, spawn-inside with `monitoring` enabled late); S-0003-C (record, not gate: synchronous load hitch of the grey `planta`) |

### Engine API sourcing

Every engine call this ADR depends on, and whether the reference covers it.
Anything marked NOT SOURCEABLE is implemented only after the named spike
confirms it on 4.7.2.

| API / behaviour | Status | Spike |
|---|---|---|
| `PackedScene.instantiate()` (name) | Sourced: `deprecated-apis.md` (renamed from `instance()` in 4.0) | — |
| `PackedScene` loading: `load()` / `ResourceLoader.load()` and its resource cache | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (no Core/resources module) | S-0003-A, S-0003-C |
| `ResourceLoader.load_threaded_request()` / `load_threaded_get_status()` (async loading) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; not used by this ADR (§ Alternatives 3) | — |
| `SceneTree.change_scene_to_file()` / `change_scene_to_packed()` and when they free the old scene | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; not used | — |
| `Node.add_child()`, `remove_child()`, `queue_free()`, `is_instance_valid()`; deletion of a `queue_free`d node by the next frame, including with `SceneTree.paused = true` | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (long-standing API, but its 4.7 timing is not in the reference) | S-0003-A |
| `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)`, `OBJECT_ORPHAN_NODE_COUNT`, `Node.print_orphan_nodes()` | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (named by TR-scene-009 only) | S-0003-A |
| gdUnit4 orphan detection (exit code 101 when a passing test leaks orphan nodes) | Sourced: `current-best-practices.md` (observed on 4.7.2 + gdUnit4 6.2.2) | — |
| `Area3D` overlap signals (`area_entered`) with Jolt, between a box zone and a 0,05 m `SphereShape3D` sensor; enabling `monitoring` with the sensor already inside | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (`modules/physics.md` only says Jolt is default and margins "may behave differently"; 4.7 `SoftBody3D` overlap note is irrelevant here: the slice has no soft bodies) | S-0003-B |
| `Engine.get_physics_frames()` (physics tick stamp for ordering simultaneous entries) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | S-0003-B |
| Relative `_process` order of autoloads and `Shell` (tree order) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; the design does not depend on it except in the risk noted under § Risks R3 | S-0003-A (observe only) |
| `Time.get_ticks_msec()` (real-time clock for `t_espera` and fades) | Sourced: `deprecated-apis.md` (replaces `OS.get_ticks_msec()`) | — |
| `CanvasLayer` (`layer`) + full-rect `ColorRect` for the curtain | Rated LOW in `architecture.md` Module Ownership; not described in the reference beyond UI module changes | — |
| `process_mode = PROCESS_MODE_ALWAYS` on `SceneLoader`, `Curtain` and the error panel | **NOT SOURCEABLE** — owned by ADR-0002 and its pause spike | ADR-0002 spike |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (event bus and fact contract: notice names, payloads, FIFO delivery without reentrancy, tolerance of subscribers freed without unsubscribing, `GameState` ready/restoring query). ADR-0002 (pause and game time: `SceneLoader` and `Curtain` run with `PROCESS_MODE_ALWAYS`; "Volver al título" from the pause runs with the tree paused). ADR-0009 (service composition: `SceneLoader`/`SceneDirector` autoload slots, `Shell`, `ServiceContext` injected into `configurar(ctx)`, injected fatal-error handler). None of the three exists yet as a file; all three are listed `Proposed` in `architecture.md` § Required ADRs. This ADR is written against their scope as stated there and must be re-checked when each is written. |
| **Enables** | ADR-0004 (save lifecycle: `continuar()` / `nueva_partida()` request `planta`, «carga de escena terminada», «partida terminada», «descarga total completada» re-inspection). ADR-0006 (input contexts: the `sin control` operations this ADR calls — open, transfer, request `exploración`, restore `menú`, stack reset on unload, discard-on-accepted-load). Also constrains ADR-0011 (interaction catalog hold), ADR-0012 (`colocar` and teleport vs physics interpolation), ADR-0017 (21's timeline consumes the handoff). |
| **Blocks** | Every `planta`/`recepcion` content story; Epic for system 4; integration stories of 7, 9, 21, 27 that need a loaded scene; the S0 milestone "load grey `planta`" |
| **Ordering Note** | `architecture.md`: 0001 → 0002 → 0009 → 0003 may be drafted in parallel with the pause spike. ADR-0004 and ADR-0006 must cite the notice and operation names fixed here verbatim. |

## Context

### Problem Statement

The slice has two game scenes (`planta`, `recepcion`) plus the title, and a
long list of things that must survive a scene change: the UI layers (24, 25,
26), the curtain, and the persistent systems 1, 3, 6, 21, 23 (TR-scene-002),
plus 5, `GameClock`, `ContentDB` (architecture § Autoloads). Loading must run
the GDD's 9-step sequence (TR-scene-010) with holds, a real-time cap, a
curtain that covers everything, and three end states (`exploracion`,
`ninguno` → handoff to 21, failure → title). Every `planta` load must be a new
instance and repeated cycles must not leak nodes or bus subscribers
(TR-scene-009). This must be decided before any scene content or integration
work starts, because it fixes the runtime tree that every other system is
composed into.

### Current State

No code. `architecture.md` v1 already proposes `Shell` + `WorldSlot`, the
autoload list (with `SceneLoader` #8 and `SceneDirector` #9), and the public
surface of system 4 (`request_load`, `request_full_unload`,
`request_fade_out`, `take_hold`, `release_hold`, all ‡). GDD 4 Open Question 1
("mecanismo de carga") and QQ-12 (Player persistent or per scene) are
explicitly delegated to this ADR.

### Constraints

- **Engine knowledge:** scene loading/freeing and `Area3D` under Jolt are not
  covered by `docs/engine-reference/godot/` (TR-scene-023). Nothing here may
  rely on remembered behaviour; spikes decide.
- **Main thread only:** `architecture.md` § Data Flow 6 — no TR asks for
  threaded loading; threaded resource loading is NOT SOURCEABLE.
- **Single writer of facts:** 4 writes no fact and reads only
  `llamada_completada` (TR-scene-020).
- **Testability:** every rule must be testable with injected doubles (fake
  scene source, curtain double, player spy, element spy with `configurar()`,
  fake state, fake bus, integer-tick clock — TR-scene-023).
- **Data-driven:** durations, `T_cap`, `N_gap`, `Δ_max`, `Δ_ref`,
  `t_descarga_total_max_s` live in `assets/data/scene/load_transitions.json`
  and are validated at boot (TR-scene-022).
- **Team/timeline:** indie slice; the mechanism must be small enough to build
  and test in the S0 milestone.

### Requirements

- Exactly one game scene at a time; `planta` is one continuous scene
  (TR-scene-001); a new instance per load (TR-scene-009).
- The 9-step order with the descarga starting only at α = 1 (TR-scene-010),
  configure order 7 → 9 → rest in one frame (TR-scene-011), idempotent holds
  (TR-scene-012), `T_cap` in unscaled real time, running without focus
  (TR-scene-013).
- Curtain above world and game UI, only the error message above it, F1 curve
  with `Δ_max` clipping and `d = 0` skip (TR-scene-014, -015).
- `D_carga = d_out + T_cap + N_gap·Δ_ref + d_in` declared to Entrada as the
  `sin control` duration in «iniciada» (TR-scene-016, -017).
- 4-state machine; failure ends in black + one action «Volver al título»; the
  app never closes and a half-configured scene is never revealed
  (TR-scene-018).
- Full unload: «descarga total solicitada» → unload → restore `menú` →
  «descarga total completada», ≤ 3,0 s† (TR-scene-019); 4 is the only emitter
  of «partida terminada» and «descarga total completada» (TR-scene-019, -020).
- Handoff of `sin control` to 21 in the «terminada» frame (TR-director-010,
  TR-input-004, TR-scene-017), viable while `M_traspaso ≥ 0` (TR-director-025).
- Zone triggers as pure detectors of the Player's 0,02–0,05 m sensor, every
  entry, simultaneous entries in lexicographic ID order (TR-scene-006,
  TR-player-003).

## Decision

Eight sub-decisions, D1–D8. Each names the alternative it beats; the full
comparison is in § Alternatives Considered.

**D1 — `Shell` + `WorldSlot`, never `change_scene_to_*`.** The project's main
scene is `Shell` (`res://src/shell/shell.tscn`), which is never unloaded. It
owns one empty `Node3D` named `WorldSlot` and the `CanvasLayer`s HUD,
Subtitles, PauseMenu and Curtain (+ error panel), as in `architecture.md`
§ Árbol en ejecución. `SceneLoader` (autoload #8) is the only code that adds
or removes a child of `WorldSlot`. `WorldSlot` holds at most one child:
`title`, `planta` or `recepcion`. `SceneTree.change_scene_to_*` is never
called (enforced by a CI grep, § Implementation Guidelines).

**D2 — Title is a slot occupant, not a game scene.** `title.tscn` lives in
`WorldSlot` (architecture § Data Flow 4, step 3) but is not a "game scene" in
GDD 4's sense: freeing it in step 3 is **not** a «descarga» — no Entrada stack
reset is requested and the pila keeps [`menú`, `sin control`(4)] as GDD 4
rule 9.3 requires ("si venía del título no hay escena que descargar").
TR-scene-001 ("one game scene") counts `planta`/`recepcion` only.

**D3 — Player is per scene, rebuilt with `colocar` (closes QQ-12).** Each of
`planta.tscn` and `recepcion.tscn` contains its own `Player` (system 2)
instance. Step 5 calls `player.colocar(position, yaw, pitch)` from the spawn
anchor (`spawn_office` / `spawn_elevator`). Nothing of the Player crosses a
load: TR-player-018 already says everything is rebuilt by `colocar` and the
Player is not saved; GDD 4 rule 10 says the Player does not inherit anything
from the previous scene. A persistent Player (reparented between slots) is
rejected (§ Alternatives 4).

**D4 — Synchronous loading, one frame, behind an injected `SceneSource`.**
The `PackedScene` is obtained and instantiated synchronously in the frame
after the curtain reaches α = 1, so any hitch is hidden behind black. The
call is wrapped in a `SceneSource` interface (real: resource load +
`instantiate()`; test: fake factory), so switching to threaded loading later
touches one class. `T_cap` still guards the whole wait: `t_espera` uses
unclipped real time, so a blocking frame counts in full. S-0003-C records the
real hitch of the grey `planta`; if it ever exceeds ~1 s on the reference
hardware (QQ-04), a new ADR revisits D4.

**D5 — Frame-driven load state machine with holds and real-time `T_cap`.**
`SceneLoader` exposes the 4 public states of GDD 4 (Sin escena, Cargando,
Lista, Error) and internally walks phases that map 1:1 to the 9 steps (§ Load
sequence). It reads time only from an injected `RealClock`
(`Time.get_ticks_msec()` in production, integer ticks in tests), never from
`_process(delta)` and never from `GameClock`. Holds are a set of
`StringName` holder IDs; «escena lista» ⇔ set empty after step 6.

**D6 — `sin control` lifecycle: 4 opens, Entrada resets, 21 transfers.**
4 calls Entrada's operations through an injected `InputContexts` interface
(signatures owned by ADR-0006): it *opens* `sin control`(4, `D_carga`) right
after emitting «iniciada», requests the stack reset only when it frees a game
scene, *requests `exploración`* at «terminada» when `control_final =
exploracion`, and *restores `menú`* on failure and on full unload. With
`control_final = ninguno` 4 does **nothing** to the stack after «terminada»:
21 (autoload, so alive in that frame) receives «carga de escena terminada»
and calls *transfer* in the same frame. 4 never closes or transfers on 21's
behalf.

**D7 — Full unload and «partida terminada» have one emitter: `SceneLoader`.**
`request_full_unload()` is the only path to «descarga total completada»; it
works from Lista and Error; «partida terminada» is emitted only immediately
after «carga de escena terminada» of `recepcion`, same frame.

**D8 — Zone triggers: `Area3D` gated until «terminada», funnelled through one
`ZoneHub`.** Each `T-…` is an `Area3D` (`ZoneTrigger`, no logic) whose
`monitoring` is `false` in the `.tscn`. The Player carries a separate
`Area3D` sensor with a `SphereShape3D` of `radio_sensor_zona` (0,05 m,
TR-player-003) on a dedicated collision layer `zone_sensor`; zones mask only
that layer. A scene-level `ZoneHub` (owned by 4, one per game scene)
collects entries stamped with the physics tick, sorts by (tick, ID) and emits
«zona activada» once per entry. `SceneLoader` enables `monitoring` on all
zones in the «terminada» frame, which gives GDD 4's "spawn-inside emits after
«terminada», never in the black wait". Whether Jolt reports the entry on the
next physics tick, and the activation band, is S-0003-B. **Resolved
2026-11-11 (S-0003-B, Godot 4.7.2 + Jolt):** the activation band for the sensor
centre is `X = face − radio + (0, v·dt]`; for `T-PAS-1` (face 9,0, radio 0,05,
v·dt 0,0267) that is **(8,95; 8,977]**, never earlier than 8,95. The earlier
written range 8,923–8,95 had the sign of the step term wrong.

### Architecture Diagram

```text
root (Window)
├── ContentDB · GameState · GameClock · InputRouter · Settings
├── AudioDirector · SaveService
├── SceneLoader  (autoload #8, PROCESS_MODE_ALWAYS)  ── owns ─┐
├── SceneDirector (autoload #9)                               │
└── Shell (main scene, never freed)                           │
    ├── WorldSlot (Node3D) ◄── add_child / remove_child ──────┤  only SceneLoader
    │     └── [ title | planta | recepcion ]  one at a time    │
    │            planta/recepcion root: GameSceneRoot          │
    │              ├── Player (2) ── colocar() ◄───────────────┤ step 5
    │              ├── ZoneHub ◄── ZoneTrigger(Area3D) × n     │ enable at «terminada»
    │              ├── configure_order: [7, 9] then group      │ step 6 configurar(ctx)
    │              └── office · corridor · archive · …         │
    ├── HUD · Subtitles · PauseMenu   (CanvasLayers, survive)  │
    └── Curtain (CanvasLayer, topmost) + ErrorPanel above it ◄─┘ alpha, message

 SceneLoader ──SYNC──► InputContexts (1): open / reset_on_unload / request_exploration / restore_menu
 SceneLoader ──AVISO─► bus (3): «carga de escena iniciada|lista|terminada|fallida», «escena lista»,
                               «partida terminada», «descarga total solicitada|completada», «zona activada»
 SceneDirector (21) ──AVISO in──► on «carga de escena terminada» (control_final = ninguno) ──SYNC──► InputContexts.transfer
```

### Load sequence (the 9 steps, frame by frame)

`F` = frame in which the request is accepted. "Same frame" means within one
`SceneLoader._process` call plus the bus delivery of the notices it emitted
(ADR-0001 delivers queued notices within the frame).

| Step (GDD 4 rule 9) | Phase | Frame | What `SceneLoader` does |
|---|---|---|---|
| 0 accept | — | F | Check preconditions (§ Preconditions). Reject → log (dev: fatal handler). Accept → state Cargando; read `reducir_movimiento` once (fixed for this load); resolve `d_out`, `d_in` for `motivo`; compute `D_carga` from **nominal** table values (GDD 4 F3). |
| 1 «iniciada» | `STARTED` | F | Emit «carga de escena iniciada» {destino, motivo, control_final ‡, D_carga}. Then SYNC `InputContexts.open_no_control(&"scene_loader", D_carga, absorbs_foreign = motivo in [PARTIDA_NUEVA, REANUDAR])`. Curtain untouched yet. |
| 2 curtain out | `FADING_OUT` | F … F+k | α from current α_0 to 1 by F1, `t += min(Δ_real, Δ_max)`; `d_out ≤ 0` or α_0 = 1 → α = 1 in frame F. At α = 1: `t_espera` starts (real time, unclipped). |
| 3 unload | `UNLOADING` | frame α = 1 is reached (U) | If `WorldSlot` holds `planta`/`recepcion`: SYNC `unbind_scene()` on every bound `SceneBindable` (21, 23, `Shell`; ADR-0009 D6), SYNC `InputContexts.reset_stack_on_unload()` (keeps owner, duration, tope count), then `remove_child` + `queue_free`. If it holds `title`: `remove_child` + `queue_free`, **no** stack reset (D2). |
| 4 instantiate | `INSTANTIATING` | U+1 | Assert the tree is not paused (ADR-0002 G-11: for «Nueva partida» from the pause, 25 calls `resume()` before `request_load`, so instantiation always follows the resume). Assert the old instance is gone (`is_instance_valid` false — S-0003-A). 4 calls `GameClock.reset_session()` (ADR-0002 OI-3) immediately before `SceneSource.instantiate(destino)`; failure → fail(`missing_resource`/`instantiate_failed`). `WorldSlot.add_child(instance)`. Validate required anchors/containers (TR-scene-003, -005) → fail(`missing_anchor`). |
| 5 place player | ″ | U+1 | `player.colocar(anchor.global_position, yaw, pitch)` from `spawn_office` / `spawn_elevator`. |
| 6 configure | ″ | U+1 | Holds window opens. `root.configure_all(ctx)`: 7 → 9 (validates `puzzles.json`; failure → immediate fail(`invalid_puzzle_data`), no wait for `T_cap`) → rest in tree order (8 fails open). All synchronous. Holds window stays open while `holds` is non-empty. |
| — wait | `WAITING_HOLDS` | U+1 … | Each frame: if `t_espera ≥ T_cap` → fail(`t_cap`, holder IDs). If `holds` empty → step 7. |
| 7 «escena lista» | `GAP` | L | Close holds window. SYNC `bind_scene(scene_ctx)` on 21, 23 and `Shell` adapters (ADR-0009 D6). Emit «escena lista» {destino}. Count `N_gap` frames. |
| 8 curtain in | `FADING_IN` | L+N_gap … | α by F1 (`α_in`), `Δ_max` clipping. |
| 9 «terminada» | — | T (α = 0) | State Lista. Enable zone monitoring (D8). Emit «carga de escena terminada» {destino, motivo, control_final ‡, t_since_started_s ‡}. If `control_final = exploracion` → SYNC `InputContexts.request_exploration(&"scene_loader")`. If `ninguno` → nothing (21 transfers, D6). If `destino = recepcion` → emit «partida terminada» right after, same frame. |

**Failure (any step 4–wait).** Curtain stays at α = 1 (never revealed); log
cause; emit «carga de escena fallida» {destino, motivo, causa}; SYNC
`InputContexts.restore_menu()`; state Error; show `ErrorPanel` (above the
curtain) with the single action «Volver al título», accepted with
`ui_aceptar` or the cursor; accepting calls `request_full_unload()`. No
«escena lista», no «terminada», no «partida terminada», no «descarga total
completada» until the full unload finishes (GDD 4 rule 14, round 5 E-2). In
debug builds every failure first goes to the injected fatal handler
(ADR-0009), which stops execution.

**Full unload (`request_full_unload`, from Lista or Error).**

| # | Frame | Action |
|---|---|---|
| 1 | F | Accept (reject in Cargando and Sin escena). Emit «descarga total solicitada» (no data; 21 goes inactive, 23 and 26 drop voices/blocks). State Sin escena. Start real-time `t_unload`. |
| 2 | F … | If α < 1: fade to α = 1 with `d_out = 0,1 s` (the `reducir_movimiento` constant; see Open Item O5). If α = 1 (after `cierre` or Error): nothing. |
| 3 | α = 1 (U) | `remove_child` + `queue_free` the slot child. **No** stack reset (GDD 4 rule 15, R6-4 g). |
| 4 | U+1 | Assert freed. SYNC `InputContexts.restore_menu()` → [`menú`]. Emit «descarga total completada» (no data). If `t_unload > t_descarga_total_max_s` → warning log. |
| 5 | first frame with `GameState.queue_empty()` after 4 | Instantiate `title.tscn` into `WorldSlot` behind the black curtain (5 has re-inspected on «completada»; 27 reads the result). Curtain lift over the title: Open Item O4. |

With the pause open ("Volver al título" from 25) the whole table runs with
the tree paused; this is why `SceneLoader`, `Curtain` and `ErrorPanel` are
`PROCESS_MODE_ALWAYS` (ADR-0002). The order «solicitada → completada →
pausa cerrada» is kept because 25 resumes only after receiving «completada».

**Boot.** `Boot` (architecture § Data Flow 4, step 3) calls
`SceneLoader.show_title()`, which instantiates `title.tscn` directly, with no
load notices (no game scene, no `sin control`).

### Preconditions of `request_load`

Reject (dev: fatal handler; release: one log line; return `false`) when any of:
state is Cargando (including a second request in the same frame); state is
Error; `GameState` is not Listo or is restoring; `destino = recepcion` and
`llamada_completada` is false (rule 13; 21 then emits «ascensor rechazado»);
`destino = planta` while `recepcion` is loaded (only from Sin escena/title or
reloading `planta` from `planta`); `destino = recepcion` from Sin escena.

**Stale scene (rule 17).** On «estado restablecido» / «estado restaurado»
with state Lista, `SceneLoader` does not warn immediately: it checks at the
end of the frame (after the bus queue is empty) whether a `request_load` has
arrived since. Only if not, it logs the warning (dev: visible error). This
removes the false positive of «Nueva partida» from the pause, where 5 resets
3 *before* requesting `planta` (GDD 5, TR-save-020).

### `sin control` handoff to 21 (D6 in detail)

```text
 frame T (α reaches 0)
   SceneLoader: state = Lista; enable zones; emit «carga de escena terminada»{…, control_final=NINGUNO, t_since_started_s}
   bus delivers (same frame) ─► SceneDirector._on_load_finished(payload)
        M_traspaso = (D_carga + margen_E) − t_since_started_s           (GDD 21 F5)
        M_traspaso ≥ 0 → InputContexts.transfer_no_control(&"scene_director", duracion_declarada)
                         if t_rel ≥ t_fin → InputContexts.request_exploration(&"scene_director")
        M_traspaso < 0 or transfer rejected → degrade to "momento", log; never re-take control
   bus delivers ─► «partida terminada» (only if destino = recepcion)
 owner sequence on the stack: 4 … 4 │ 21 (no frame without owner, no empty stack)
```

`D_carga` and `control_final` reach 21 in the «iniciada» payload;
`t_since_started_s` (‡) in «terminada» is measured by `SceneLoader` on
`RealClock`; Entrada's tope runs on `GameClock` (ADR-0002, ADR-0006).
Real time ≥ game time, so `M_traspaso` computed on real time is
conservative and therefore safe. If 21 does not transfer, the `sin control` stays 4's and
Entrada's tope `D_carga` + margen frees it and logs the omission (GDD 4 Edge
Cases) — 4 does not compensate.

### Key Interfaces

All signatures below are ‡ (proposed by this ADR; the GDDs leave the
technical form to an ADR — QQ-17). Names of notices are GDD names; their
`StringName` keys are fixed by ADR-0001.

```gdscript
# res://src/scene/scene_loader.gd — autoload #8
class_name SceneLoader extends Node

enum State { NO_SCENE, LOADING, READY, ERROR }
enum Destination { PLANTA, RECEPCION }
enum Reason { PARTIDA_NUEVA, REANUDAR, RECEPCION }
enum FinalControl { EXPLORACION, NINGUNO }
enum Phase { IDLE, FADING_OUT, UNLOADING, INSTANTIATING, WAITING_HOLDS, GAP, FADING_IN,
		UNLOAD_FADING, UNLOAD_FREEING, TITLE_PENDING }

## Injected at Boot (ADR-0009). Production doubles exist for every one.
func setup(ctx: ServiceContext, source: SceneSource, curtain: Curtain,
		input: InputContexts, clock: RealClock, transitions: LoadTransitions) -> void

## «petición de carga». Returns false when rejected (see Preconditions).
func request_load(destination: Destination, reason: Reason, final_control: FinalControl) -> bool
## «descarga total». Accepted from READY and ERROR only.
func request_full_unload() -> bool
## d_out of `reason` as this load would use it (0,1 s with reducir_movimiento); 21 reads d_cierre here (ADR-0017 A2) ‡
func fade_duration_s(reason: Reason) -> float
## Own fade for 21 (`cierre`): darkens only, no load, no D_carga, never lifts.
func request_fade_out(fade_reason: StringName = &"cierre") -> void
## Holds: valid only between step 6 start and «escena lista»; otherwise ignored + logged.
func take_hold(holder_id: StringName) -> void       # idempotent
func release_hold(holder_id: StringName) -> void    # double release never goes below 0
func get_state() -> State
## Boot only: instantiates the title with no load notices.
func show_title() -> void
```

```gdscript
# res://src/scene/scene_source.gd — the only class that touches resource loading
class_name SceneSource extends RefCounted
## Returns null on failure; never throws. Real implementation: load(path) as PackedScene,
## then instantiate(). NOT SOURCEABLE until S-0003-A.
func instantiate(destination: StringName) -> Node:
	return null
```

```gdscript
# res://src/scene/game_scene_root.gd — root script of planta.tscn / recepcion.tscn
class_name GameSceneRoot extends Node3D
@export var spawn_anchor: NodePath            # spawn_office | spawn_elevator
@export var configure_first: Array[NodePath]  # [InteractionSystem (7), PuzzleFramework (9)] in planta
const ELEMENT_GROUP: StringName = &"scene_element"   # every element with configurar(ctx)

enum ConfigureResult { OK, INVALID_PUZZLE_DATA }
func get_player() -> Player
func get_zone_hub() -> ZoneHub
func validate_required_nodes() -> PackedStringArray   # empty = OK (TR-scene-003, -005)
## Calls configurar(ctx) on configure_first in order, then on ELEMENT_GROUP in tree order,
## skipping the ones already configured. Synchronous. Stops at 9's validation failure.
## configurar() returns void (ADR-0009): after 9's call the root asks
## PuzzleFramework.configuration_failed() and maps true → INVALID_PUZZLE_DATA (ADR-0010 D13).
func configure_all(ctx: ServiceContext) -> ConfigureResult
```

```gdscript
# Contract with Entrada (1). Operation names are GDD 1 rule 6; signatures owned by ADR-0006.
class_name InputContexts extends RefCounted
func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool
func close_no_control(owner: StringName) -> bool
func transfer_no_control(new_owner: StringName, declared_s: float) -> bool
func request_exploration(owner: StringName) -> bool
func restore_menu() -> void
func reset_stack_on_unload() -> void
```

```gdscript
# res://src/scene/zone_hub.gd — one per game scene; the only emitter of «zona activada»
class_name ZoneHub extends Node
func register(zone: ZoneTrigger) -> void
func set_enabled(enabled: bool) -> void       # toggles monitoring on every registered zone
```

### Core pseudocode

Typed GDScript, abridged (logging, dev assertions and `LoadTransitions`
parsing omitted). Notice keys are placeholders until ADR-0001.

```gdscript
var _state: State = State.NO_SCENE
var _phase: Phase = Phase.IDLE
var _req: Dictionary = {}                 # destination, reason, final_control
var _holds: Dictionary = {}               # StringName -> true
var _holds_open: bool = false
var _d_out: float
var _d_in: float
var _d_load: float
var _t_started_ms: int
var _t_wait_start_ms: int
var _fade_t: float
var _gap_left: int
var _last_ms: int
var _old: Node = null

func request_load(destination: Destination, reason: Reason, final_control: FinalControl) -> bool:
	var why: StringName = _reject_reason(destination)
	if why != &"":
		_reject(why)
		return false
	_req = {"destination": destination, "reason": reason, "final_control": final_control}
	_state = State.LOADING
	var reduced: bool = _ctx.settings.get_bool(&"reducir_movimiento")   # read once (rule 11)
	_d_out = _tr.d_out(reason, reduced)
	_d_in = _tr.d_in(reason, reduced)
	_d_load = _tr.nominal_d_out(reason) + _tr.t_cap + _tr.n_gap * _tr.delta_ref + _tr.nominal_d_in(reason)
	_t_started_ms = _clock.now_ms()
	# Payload keys are ADR-0001's registry keys (reconciliation 2026-11-10).
	_ctx.bus.emit(&"scene_load_started", {"destino": destination, "motivo": reason,
			"control_final": final_control, "D_carga": _d_load})
	_input.open_no_control(&"scene_loader", _d_load,
			reason in [Reason.PARTIDA_NUEVA, Reason.REANUDAR])   # absorbs_foreign (ADR-0006)
	_begin_fade_out()
	return true

func _process(_delta: float) -> void:     # _delta ignored on purpose: real time only (D5)
	var now: int = _clock.now_ms()
	var dt_real: float = (now - _last_ms) / 1000.0
	_last_ms = now
	match _phase:
		Phase.FADING_OUT:
			if _curtain.step_out(minf(dt_real, _tr.delta_max), _d_out):   # true when α == 1
				_t_wait_start_ms = now
				_unload_current()                                      # step 3
				_phase = Phase.INSTANTIATING
		Phase.INSTANTIATING:
			_instantiate_and_configure()                               # steps 4–6
		Phase.WAITING_HOLDS:
			if (now - _t_wait_start_ms) / 1000.0 >= _tr.t_cap:
				_fail(&"t_cap", _holds.keys())
			elif _holds.is_empty():
				_scene_ready()                                         # step 7
		Phase.GAP:
			_gap_left -= 1
			if _gap_left <= 0:
				_phase = Phase.FADING_IN
		Phase.FADING_IN:
			if _curtain.step_in(minf(dt_real, _tr.delta_max), _d_in):    # true when α == 0
				_finish()                                              # step 9
		# UNLOAD_* and TITLE_PENDING: full-unload table, same pattern

func _unload_current() -> void:
	var child: Node = _slot_child()
	if child == null:
		return
	if child is GameSceneRoot:
		_input.reset_stack_on_unload()        # never for the title (D2), never on full unload
	_slot.remove_child(child)
	child.queue_free()
	_old = child

func _instantiate_and_configure() -> void:
	if _old != null and is_instance_valid(_old):   # S-0003-A: must be gone one frame later
		_fail(&"previous_scene_not_freed", [])
		return
	_old = null
	var root: GameSceneRoot = _source.instantiate(_dest_key()) as GameSceneRoot
	if root == null:
		_fail(&"instantiate_failed", [])
		return
	_slot.add_child(root)
	var missing: PackedStringArray = root.validate_required_nodes()
	if not missing.is_empty():
		_fail(&"missing_anchor", Array(missing))
		return
	var anchor: Node3D = root.get_node(root.spawn_anchor) as Node3D
	# step 5; yaw/pitch units follow GDD 2's colocar (ADR-0012); pitch 0 = level gaze
	root.get_player().colocar(anchor.global_position, anchor.global_rotation.y, 0.0)
	_holds.clear()
	_holds_open = true
	if root.configure_all(_ctx) == GameSceneRoot.ConfigureResult.INVALID_PUZZLE_DATA:   # step 6
		_fail(&"invalid_puzzle_data", [])          # immediate, no T_cap wait
		return
	_phase = Phase.WAITING_HOLDS
	if _holds.is_empty():
		_scene_ready()                             # n_ret = 0 → «escena lista» in this same frame (F2)

func _scene_ready() -> void:
	_holds_open = false
	_ctx.bus.emit(&"scene_ready", {"destino": _req.destination})
	_gap_left = _tr.n_gap
	_phase = Phase.GAP if _gap_left > 0 else Phase.FADING_IN

func _finish() -> void:
	_phase = Phase.IDLE
	_state = State.READY
	(_slot_child() as GameSceneRoot).get_zone_hub().set_enabled(true)       # D8
	_ctx.bus.emit(&"scene_load_finished", {"destino": _req.destination, "motivo": _req.reason,
			"control_final": _req.final_control,
			"t_since_started_s": (_clock.now_ms() - _t_started_ms) / 1000.0})
	if _req.final_control == FinalControl.EXPLORACION:
		_input.request_exploration(&"scene_loader")
	# NINGUNO: SceneDirector transfers on the notice above, same frame (D6). Do nothing.
	if _req.destination == Destination.RECEPCION:
		_ctx.bus.emit(&"game_completed", {})     # «partida terminada», only here

func _fail(cause: StringName, detail: Array) -> void:
	_holds_open = false
	_phase = Phase.IDLE
	_state = State.ERROR
	_curtain.set_alpha(1.0)                        # never reveal a half scene
	_ctx.fatal.report_load_failure(cause, detail)  # dev: stops; release: logs and returns
	_ctx.bus.emit(&"scene_load_failed", {"destino": _req.destination,
			"motivo": _req.reason, "causa": cause})
	_input.restore_menu()
	_curtain.show_error(_on_back_to_title)         # «Volver al título», ui_aceptar or cursor

func take_hold(holder_id: StringName) -> void:
	if not _holds_open:
		_log_ignored_hold(holder_id)               # dev: visible error (GDD 4 Edge Cases)
		return
	_holds[holder_id] = true

func release_hold(holder_id: StringName) -> void:
	_holds.erase(holder_id)                        # erase of a missing key is a no-op
```

```gdscript
# ZoneHub: lexicographic order of simultaneous entries (TR-scene-006)
var _pending: Array[Dictionary] = []      # {tick: int, id: StringName}
var _flush_queued: bool = false

func _on_zone_entered(zone_id: StringName) -> void:
	_pending.append({"tick": Engine.get_physics_frames(), "id": zone_id})   # NS, S-0003-B
	if not _flush_queued:
		_flush_queued = true
		_flush.call_deferred()

func _flush() -> void:
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.tick < b.tick or (a.tick == b.tick and String(a.id) < String(b.id)))
	for e: Dictionary in _pending:
		_bus.emit(&"zone_activated", {"zone_id": e.id})
	_pending.clear()
	_flush_queued = false
```

### Implementation Guidelines

- `SceneLoader` **must** be the only code that adds or removes children of
  `WorldSlot`, and the only emitter of «carga de escena iniciada / lista /
  terminada / fallida», «escena lista», «partida terminada», «descarga total
  solicitada / completada». `ZoneHub` must be the only emitter of «zona
  activada».
- Code **must never** call `SceneTree.change_scene_to_file`,
  `change_scene_to_packed` or `reload_current_scene` (CI grep over `src/`).
- `SceneLoader` **must never** read `delta` from `_process` or any
  `GameClock` value for `t_espera`, fades or `t_unload`; only `RealClock`.
- `SceneLoader` **must never** write a fact and must read only
  `llamada_completada`. It must never save or request a save.
- Every game-scene element with state **must** implement `configurar(ctx:
  ServiceContext) -> void`, be in group `scene_element`, read its facts there
  and finish synchronously or take a hold with a unique ID (convention:
  `&"<system>:<element_id>"`, e.g. `&"interaction:catalog"`).
- Holds **must** be released by ID; code must never count holds itself.
- Elements **must not** unsubscribe from the bus in `_exit_tree` as a
  correctness requirement: freed subscribers must be tolerated by ADR-0001
  (GDD 3); unsubscribing is allowed as hygiene.
- `ZoneTrigger` **must** have no script logic beyond forwarding its ID to
  `ZoneHub`, `monitoring = false` in the `.tscn`, and mask only layer
  `zone_sensor`. The Player's sensor **must** be on `zone_sensor` only and
  `monitorable = true`.
- A new game scene **must** be instantiated in a frame strictly after the
  frame in which the old one was `queue_free`d (step 3 → step 4 = U → U+1).
- `SceneLoader`, `Curtain` and `ErrorPanel` **must** run with
  `PROCESS_MODE_ALWAYS` (ADR-0002); game scenes keep the default inherited
  mode.
- The curtain `CanvasLayer` **must** have the highest `layer` of the HUD
  stack except `ErrorPanel`; ADR-0016 must not place any layer above it.
- `load_transitions.json` **must** be validated at boot
  (`SceneLoader.validate`, architecture § Data Flow 4, step g); invalid or
  missing → fatal handler with `DATOS_ESCENA_INVALIDOS`.

## Alternatives Considered

### Alternative 1: `SceneTree.change_scene_to_file` / `change_scene_to_packed`

- **Description**: Each of title, `planta`, `recepcion` is the tree's current
  scene; HUD, subtitles, pause, curtain become autoload `CanvasLayer`s.
- **Pros**: Idiomatic; no slot node; engine handles freeing.
- **Cons**: When the old scene is freed and the new one enters the tree is
  engine-internal timing (NOT SOURCEABLE), yet steps 3–6 depend on it frame by
  frame; four extra UI autoloads contradict the closed autoload list of
  `architecture.md` and ADR-0009; the step 3 / step 4 split, the D2 title rule
  and a fake scene source in tests become harder.
- **Estimated Effort**: Similar to build, higher to test.
- **Rejection Reason**: Gives up control of exactly the ordering TR-scene-010
  specifies, and inflates the autoload list.

### Alternative 2: Additive scenes (`planta` and `recepcion` co-resident)

- **Description**: Preload `recepcion` while in `planta` and swap visibility.
- **Pros**: Near-instant elevator transition.
- **Cons**: Violates TR-scene-001 (never both) and GDD 4 rule 13 (the
  `planta` unloads entirely); two scenes' subscribers live at once.
- **Estimated Effort**: Lower runtime cost, higher correctness cost.
- **Rejection Reason**: Contradicts the GDD.

### Alternative 3: Threaded loading (`ResourceLoader.load_threaded_*`)

- **Description**: Request the `PackedScene` on a worker thread in step 2,
  poll each frame, instantiate when loaded.
- **Pros**: No main-thread hitch; `T_cap` could fail a stuck load while it is
  stuck, not after.
- **Cons**: NOT SOURCEABLE in the reference; contradicts architecture § Data
  Flow 6 (main thread only) without a TR that needs it; the grey slice loads
  "in less than 1 s" (GDD 4 F2); more failure modes.
- **Estimated Effort**: +1–2 days plus a spike.
- **Rejection Reason**: Not needed by any TR; reversible later because only
  `SceneSource` changes (D4).

### Alternative 4: Persistent Player (QQ-12, the other option)

- **Description**: One `Player` under `Shell`, reparented into each scene (or
  kept outside `WorldSlot`) and teleported by `colocar`.
- **Pros**: Camera/hands nodes built once; no per-scene Player prefab.
- **Cons**: Every per-scene reference (7's target, 28's reflection proxy,
  zones, 29) must re-bind to an object that outlives the scene; the Player's
  physics body exists while no world exists (Sin escena, title); state could
  leak across loads, which rule 8 forbids; TR-player-018 already makes
  `colocar` a full reset, so persistence buys nothing.
- **Estimated Effort**: Similar, with more integration risk.
- **Rejection Reason**: Leak risk with no benefit; per-scene matches "nothing
  of a session filters into the next" (rule 8).

### Alternative 5: Zones by manual overlap query instead of `Area3D` signals

- **Description**: Each physics tick, `ZoneHub` tests the sensor centre
  against each `T-…` box arithmetically (AABB in zone local space).
- **Pros**: No Jolt dependency; deterministic; trivially ordered; unit-testable.
- **Cons**: Duplicates physics; zones must stay boxes; level designers lose
  editor shapes.
- **Estimated Effort**: Comparable.
- **Rejection Reason**: Kept as the **fallback** if S-0003-B fails (§ Risks
  R2), not as the default: the GDD names `Area3D` and the box test only
  covers box zones.

## Consequences

### Positive

- UI layers, curtain and the 9 autoloads survive every load without extra
  autoloads; one place (`SceneLoader`) owns tree mutation of the world.
- The 9 steps map 1:1 to phases; each rule is testable with doubles and an
  integer-tick clock (TR-scene-023).
- `sin control` never has a frame without owner: 4 holds it until 21's
  transfer in the «terminada» frame.
- Per-scene Player and fresh instances make leak checks meaningful: after a
  full unload, nothing game-side should remain.

### Negative

- A synchronous load hitch is invisible but real; a load that blocks longer
  than `T_cap` fails only after it returns (accepted; GDD 4 F3 already
  accepts loss of the invariant under sustained stalls).
- The title is a slot occupant with a special rule (D2), one more case to test.
- Zone monitoring is off during the black wait and the fade-in; any design
  that needs a zone to fire during the fade-in is impossible (none does).
- Adds two payload fields ‡ to GDD notices (`control_final` in «iniciada» and
  «terminada», `t_since_started_s` in «terminada»): GDD 3 / 4 / 21 need a
  propagation edit.

### Neutral

- `SceneLoader` is an autoload and `Curtain` a node in `Shell`; the curtain
  is injected into `SceneLoader` at Boot.
- `recepcion` has no puzzles: `configure_first` is empty there and 9's
  validation does not run (TR-scene-011).

## Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | `queue_free`d `planta` still valid at U+1 (or not freed under a paused tree), so two game scenes coexist or orphans accumulate | S-0003-A measures it; fallback: wait until `is_instance_valid(old)` is false for up to 3 frames (inside `T_cap`), else fail(`previous_scene_not_freed`) |
| R2 | Jolt `Area3D` misses the 0,05 m sensor, double-reports, or reports outside X (8,95; 8,977] (range corrected 2026-11-11 after S-0003-B) | S-0003-B passed on entries/doubles/misses; Alternative 5 (arithmetic box test in `ZoneHub`) discarded 2026-11-11 in favour of correcting the documented range |
| R3 | A load blocking > `D_carga` + 2 s lets Entrada's tope and `T_cap` expire in the same frame, order unknown | Accepted limitation (GDD 4 F3); S-0003-C records the real hitch; a warning is logged when the load exceeds `D_carga` |
| R4 | ADR-0001 does not deliver notices within the frame, breaking "same frame" handoff and «partida terminada» timing | Hard dependency on ADR-0001; integration test T-I2 fails if so |
| R5 | Physics interpolation shows a smear from the previous pose after `colocar` | **Resolved by ADR-0012 D2/D4** (`TickInterpolator.reset` in `colocar`); hidden anyway behind `N_gap` black frames |
| R6 | The pause opens in frame F between «iniciada» and the notice reaching Entrada | `open_no_control` is SYNC in F; `carga_en_curso` relies on ADR-0001 same-frame delivery before the next input dispatch (Open Item O2) |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| escena-de-planta.md | TR-scene-001 one game scene, continuous `planta` | D1 single `WorldSlot` child; D2 title is not a game scene |
| escena-de-planta.md | TR-scene-002 persistent 1, 3, 6, 21, 23 with same `get_instance_id()`; 21 inactive during full unload | Autoloads outside `WorldSlot`; «descarga total solicitada/completada» emitted by D7; test T-I1 checks instance IDs |
| escena-de-planta.md | TR-scene-003 named containers, IDs, duplicate anchors | `GameSceneRoot.validate_required_nodes()` in step 4 |
| escena-de-planta.md | TR-scene-004 spatial convention | Not decided here (content/level); `validate_required_nodes` only checks presence |
| escena-de-planta.md | TR-scene-005 required anchors; missing = load failure | Step 4 → fail(`missing_anchor`) |
| escena-de-planta.md | TR-scene-006 pure zone detectors, every entry, lexicographic order | D8 `ZoneTrigger` + `ZoneHub` (tick, ID) sort; S-0003-B |
| escena-de-planta.md | TR-scene-007 geometric contract with the Player | Not decided here (ADR-0012, content); zone layer `zone_sensor` separates sensor from capsule |
| escena-de-planta.md | TR-scene-008 request with 3 data and preconditions | `request_load(destination, reason, final_control)` + § Preconditions |
| escena-de-planta.md | TR-scene-009 new instance per load; nodes/subscribers back to baseline after 10 cycles | D1/D4 fresh `instantiate()`; S-0003-A and test T-I3 |
| escena-de-planta.md | TR-scene-010 9-step order, unload only at α = 1 | § Load sequence; phase `FADING_OUT` → `UNLOADING` only on α = 1 |
| escena-de-planta.md | TR-scene-011 configure order 7 → 9 → rest; 9 failure immediate; 8 fails open; no validation in `recepcion` | `configure_first` + group; `INVALID_PUZZLE_DATA` → immediate `_fail` |
| escena-de-planta.md | TR-scene-012 idempotent holds; ready ⇔ n_ret = 0; late holds ignored | `_holds` set + `_holds_open` window |
| escena-de-planta.md | TR-scene-013 `T_cap` real time, unscaled, with or without focus, not cumulative | `RealClock`, measured from α = 1, one total cap; holder IDs in the failure log |
| escena-de-planta.md | TR-scene-014 curtain above all but error; F1 | `Curtain` topmost `CanvasLayer`, `ErrorPanel` above; `step_out/step_in` implement F1 with `Δ_max`, `d ≤ 0` skip |
| escena-de-planta.md | TR-scene-015 durations per `motivo`; `reducir_movimiento` read in step 1 | `LoadTransitions` + read-once in `request_load` |
| escena-de-planta.md | TR-scene-016 `D_carga` declared in «iniciada»; `N_gap` | `_d_load` from nominal values; `open_no_control(…, D_carga)`; `GAP` phase |
| escena-de-planta.md | TR-scene-017 stack model during load | D6: open, reset on unload (game scenes only), request `exploración`, restore `menú`; 21 transfers |
| escena-de-planta.md | TR-scene-018 4 states; failure in black with «Volver al título»; never close, never reveal | `State`; `_fail` keeps α = 1 and shows `ErrorPanel` |
| escena-de-planta.md | TR-scene-019 full unload order and ≤ 3,0 s; only emitter of «completada» | § Full unload table; `t_unload` warning |
| escena-de-planta.md | TR-scene-020 only emitter of «partida terminada»; no facts, no saves | `_finish()` only; Implementation Guidelines |
| escena-de-planta.md | TR-scene-021 stale scene warning, no patching | End-of-frame check (§ Preconditions) |
| escena-de-planta.md | TR-scene-022 boot validation of `load_transitions.json` | `SceneLoader.validate` at Boot step g; `DATOS_ESCENA_INVALIDOS` |
| escena-de-planta.md | TR-scene-023 testability with doubles | Every dependency injected in `setup()`; § Test Plan |
| entrada-y-controles.md | TR-input-003 context stack, only top receives actions | Respected: 4 only calls GDD 1 operations, never pushes other contexts |
| entrada-y-controles.md | TR-input-004 `sin control` owner, duration, open/close/transfer/explore/restore/discard/reset | `InputContexts` contract (signatures to ADR-0006); discard-on-accepted-load stays Entrada's, triggered by 4's open in «iniciada» |
| entrada-y-controles.md | TR-input-006 `carga_en_curso` from «iniciada»/«terminada»/«fallida» | 4 emits exactly these three, in that order, once per load |
| director-de-escenas.md | TR-director-001 21 persistent | `SceneDirector` autoload #9 (with ADR-0009) |
| director-de-escenas.md | TR-director-002 21 inactive from full-unload request to «completada» | «descarga total solicitada» emitted in full-unload frame F, «completada» at U+1 |
| director-de-escenas.md | TR-director-010 transfer in the «terminada» frame; no frame without owner | D6 + § handoff diagram; 4 does nothing after «terminada» with `ninguno` |
| director-de-escenas.md | TR-director-025 `M_traspaso ≥ 0` | `D_carga` in «iniciada», `t_since_started_s` ‡ in «terminada», same clock |
| jugador-en-primera-persona.md | TR-player-018 `colocar` synchronous full reset, Player not saved | D3 per-scene Player; step 5 |
| jugador-en-primera-persona.md | TR-player-003 0,05 m zone sensor separate from capsule | D8 sensor `Area3D` on `zone_sensor`; S-0003-B |
| guardado-y-carga.md | TR-save-019 `continuar()` → `planta`/`reanudar`/`exploracion`; En partida at «terminada» | `request_load` contract; «terminada» emitted once, after α = 0 |
| guardado-y-carga.md | TR-save-020 `nueva_partida()` → `planta`/`partida_nueva`/`ninguno` | Same; stale-scene check tolerates the reset-before-request order |

## Performance Implications

- **CPU**: `SceneLoader._process` is a `match` over a phase; negligible when
  IDLE. `ZoneHub` sorts ≤ a handful of entries per frame.
- **Memory**: one game scene resident at a time; the title freed while
  playing. Whether the engine keeps the `PackedScene` cached after its
  instance is freed is NOT SOURCEABLE (S-0003-A records the delta after 10
  cycles). No budget exists yet (QQ-04, ADR-0019).
- **Load Time**: one synchronous hitch in frame U+1, behind black; the
  nominal black time is `d_out + load + N_gap + d_in` (≈ 1,63 s for an
  instant `recepcion` load, GDD 4 F3). S-0003-C records the grey `planta`.
- **Network**: N/A.

## Migration Plan

No code exists; nothing to migrate. Stories for system 4 are written against
this ADR once `Accepted`.

**Rollback plan**: D4 → swap `SceneSource` for a threaded implementation (new
ADR). D8 → Alternative 5 inside `ZoneHub`, same notice. D1 is the
expensive one to reverse; it is the reason for S-0003-A before acceptance.

## Validation Criteria

### Spikes (must run on Godot 4.7.2 before `Accepted`)

**S-0003-A — instantiate/free ×10, count orphans.**
Setup: minimal `Shell` + `WorldSlot` + real `SceneLoader`, a grey `planta`
with ≥ 50 nodes, 3 `scene_element`s that subscribe to a fake bus, one `Area3D`
zone, one `Player` stub; a title stub.
Procedure: boot → title; then 10 cycles of `request_load(PLANTA,
PARTIDA_NUEVA, NINGUNO)` → wait «terminada» → `request_full_unload()` → wait
«completada». Repeat the 10 cycles with `SceneTree.paused = true` during each
full unload (the pause path). Record after cycle 1 and after cycle 10:
`Performance.OBJECT_NODE_COUNT`, `OBJECT_ORPHAN_NODE_COUNT`, `OBJECT_COUNT`,
static memory, bus subscriber count; run `print_orphan_nodes()`; record at
U+1 whether `is_instance_valid(old)` is false (normal and paused).
Pass: node count after cycle 10 equals after cycle 1; orphan count 0;
subscriber count equals the post-boot value; old instance invalid at U+1 in
both modes (else R1 fallback becomes the rule). The same loop as a gdUnit4
test must not exit with 101.

**S-0003-B — `Area3D` zone with Jolt, 0,05 m sensor.**
Setup: Jolt 3D, physics 60 Hz; box zone `T-PAS-1` with its slice bounds;
sensor `Area3D` + `SphereShape3D` r = 0,05 m on layer `zone_sensor`; a
kinematic mover at 1,6 m/s along +X (step 1,6/60 ≈ 0,027 m < 0,1 m sensor
diameter, so no tunnelling by construction).
Procedure: (1) 100 crossings, log sensor centre X at each `area_entered`;
(2) two zones whose faces coincide entered in the same tick; (3) sensor placed
inside a zone with `monitoring = false`, then `monitoring = true`; (4) render
at 30, 60 and 144 fps with physics fixed at 60 Hz; (5) `Engine.get_physics_frames()`
stamp at each callback.
Pass: 100 entries, 0 doubles, 0 misses; every entry with centre X in
(8,95; 8,977] (corrected 2026-11-11; the original criterion read [8,923; 8,95], see S-0003-B.1 in Spike Results); case 2 delivers both entries with the same tick and the hub
emits them ID-sorted; case 3 reports one entry within 1–2 physics ticks after
enabling (record which); results identical at the three frame rates.
Fail on any → R2 fallback (Alternative 5) and update D8.

**S-0003-C — synchronous hitch (record only).** Time `SceneSource.instantiate`
plus `configure_all` for the grey `planta` on the developer machine; write
the number here. Not a gate until QQ-04 fixes reference hardware.

### Test Plan

Framework gdUnit4 (runner in `project.yaml`), all clocks integer-tick
`RealClock` doubles, no file I/O in unit tests (fake `SceneSource`,
`LoadTransitions` from a fixture constant).

| ID | Level | Path | Covers |
|---|---|---|---|
| T-U1 | Unit | `tests/unit/scene/scene_loader_preconditions_test.gd` | Rejections: second request same frame, Error state, 3 not Listo/restoring, `recepcion` with `llamada_completada` false, `planta` from `recepcion`, full unload from Cargando/Sin escena (TR-scene-008, rule 13) |
| T-U2 | Unit | `tests/unit/scene/scene_loader_sequence_test.gd` | Notice order and frames: «iniciada» before any α change; unload only at α = 1; instantiate at U+1; «escena lista» same frame when no holds; `N_gap` frames; «terminada» at α = 0; «partida terminada» only after `recepcion` «terminada», never on failure (TR-scene-010, -016, -020) |
| T-U3 | Unit | `tests/unit/scene/scene_loader_holds_test.gd` | Idempotent take/release, double release, late hold ignored and logged, `T_cap` fail at exactly `T_cap` ticks with holder IDs, not cumulative over 100 holds (TR-scene-012, -013) |
| T-U4 | Unit | `tests/unit/scene/curtain_formula_test.gd` | F1 examples of GDD 4 (α = 0,5 at t = 0,4 / d = 0,8; α = 0,844 at t = 0,2 in; d = 0 skip; `Δ_max` clip on a 2 s frame); `reducir_movimiento` 0,1 s and read-once (TR-scene-014, -015) |
| T-U5 | Unit | `tests/unit/scene/d_carga_test.gd` | `D_carga` ≈ 11,67 s for `recepcion` with nominal values, also with `reducir_movimiento` true (still nominal) (TR-scene-016) |
| T-U6 | Unit | `tests/unit/scene/scene_loader_input_contract_test.gd` | Input spy: open(4, D_carga) after «iniciada»; reset only when freeing a game scene, never for title nor full unload; `request_exploration` only with `exploracion`; nothing after «terminada» with `ninguno`; `restore_menu` on failure and full unload (TR-scene-017, TR-input-004) |
| T-U7 | Unit | `tests/unit/scene/scene_loader_failure_test.gd` | Each cause (instantiate, missing anchor, invalid puzzle data immediate, `T_cap`): α stays 1, «fallida» with cause, `restore_menu`, Error, no «lista/terminada/completada»; «Volver al título» → full unload → «completada» once (TR-scene-018, rule 14) |
| T-U8 | Unit | `tests/unit/scene/full_unload_test.gd` | Order «solicitada» → free → `restore_menu` → «completada»; ≤ `t_descarga_total_max_s` warning; works from Lista and Error; title instantiated only after queue empty (TR-scene-019) |
| T-U9 | Unit | `tests/unit/scene/zone_hub_order_test.gd` | Same-tick entries sorted by ID; different ticks by tick; every re-entry emits (TR-scene-006) |
| T-U10 | Unit | `tests/unit/scene/stale_scene_test.gd` | «estado restablecido» then `request_load` in the same frame → no warning; without request → warning (TR-scene-021) |
| T-U11 | Unit | `tests/unit/scene/load_transitions_validation_test.gd` | Out-of-range `d`, `T_cap`, `N_gap`, `Δ_max`, missing file → `DATOS_ESCENA_INVALIDOS` (TR-scene-022) |
| T-I1 | Integration | `tests/integration/scene/persistent_nodes_test.gd` | Autoload `get_instance_id()` unchanged across title → `planta` → `recepcion` → title (TR-scene-002) |
| T-I2 | Integration | `tests/integration/scene/no_control_handoff_test.gd` | Real `InputRouter` + real `SceneDirector` with a 15,0 s declared scene: stack owner 4 until the «terminada» frame, 21 from that frame, never empty; tope renewed to 17,0 s; `M_traspaso < 0` → degrade (TR-director-010, -025; AC-21-04) |
| T-I3 | Integration | `tests/integration/scene/orphan_cycles_test.gd` | S-0003-A loop as a regression test; gdUnit4 must not exit 101 (TR-scene-009) |
| T-I4 | Integration | `tests/integration/scene/zone_jolt_test.gd` | S-0003-B cases 1–3 as regression (physics, headless) (TR-scene-006, TR-player-003) |
| T-I5 | Integration | `tests/integration/scene/pause_full_unload_test.gd` | "Volver al título" with the tree paused completes and orders «solicitada → completada → pausa cerrada» (with ADR-0002) |

Player-observable checks (curtain look, error panel, title over black) need a
retained screenshot in `production/qa/evidence/` per `coding-standards.md`;
they are not automated.

### We will know this was right if

S-0003-A and S-0003-B pass unchanged; T-I2 shows no ownerless frame across
all rows of the GDD 4 stack table; and the first grey-box playtest shows no
visible frame of a half-configured scene.

## Spike Results (2026-11-11)

Godot 4.7.2.stable.official.ed1daf0bf, headless, Jolt (`physics/3d/physics_engine = DEFAULT`),
60 Hz. Tests: `tests/unit/engine_facts/adr0003_instantiate_free_orphans_test.gd` (3/3 pass),
`adr0003_zone_sensor_jolt_test.gd` (4/4 pass; they pin the observed values). Engine-level only:
the real `SceneLoader`/`Shell`/grey `planta` do not exist yet, so the loop uses a packed scene
built in the test (60 `Node3D` + 3 bus-subscribing elements + `Area3D` + `CharacterBody3D`).

| S-n | Claim | Result | Figures | Fallback |
|---|---|---|---|---|
| S-0003-A (normal) | 10 × instantiate/`queue_free`: node count equals cycle 1, 0 orphans, subscribers at baseline, old instance invalid at U+1 | PASS | nodes 17 → 17; orphans 0; subscribers 0 → 0 (element that never disconnects is also cleaned by the engine); `is_instance_valid(old)` true in the same frame, false at U+1 in 10/10; `OBJECT_COUNT` Δ(c1→c10) = 0; `MEMORY_STATIC` Δ = +1 076 B | none (R1 not triggered) |
| S-0003-A (tree paused) | same with `SceneTree.paused = true` during the free | PASS | nodes 17 → 17; orphans 0; invalid at U+1 in 10/10 | none |
| S-0003-A (gdUnit exit) | the loop as a gdUnit4 test does not exit 101 | PASS | suite exit code 0, 0 orphans | none |
| S-0003-B.1 | 100 entries, 0 doubles, 0 misses | PASS | 100 entries, 0 doubles, 0 misses (100 lanes, tick phases spread over one step) | none |
| S-0003-B.1 | every entry with sensor centre X in [8,923; 8,95] | **FAIL** | observed [8,95013; 8,97653] (all 100 outside the ADR range). Zone face X 9,0 − r 0,05 = 8,95 is the touch point: Jolt reports on the first tick after the sphere surface crosses the face (band = touch + one step 0,0267 m), never earlier. Entry is exact and deterministic; only the range written in the ADR is off | R2 fallback as written (Alternative 5, arithmetic box test in `ZoneHub`) and update D8. Note for the ADR owner: the sensor itself behaves correctly; revising the documented range to (8,95; 8,977] is the alternative to Alternative 5 |
| S-0003-B.2 | two zones with coincident faces entered in the same tick | PASS | both stamped physics frame 150; callback order was T-A, T-B although T-B was added first (hub must sort by ID itself, as designed) | none |
| S-0003-B.3 | `monitoring = true` with the sensor already inside reports one entry within 1–2 ticks | PASS | 0 entries while disabled; 1 entry, 1 physics tick after enabling | none |
| S-0003-B.4 | identical at 30, 60, 144 fps with physics at 60 Hz | PASS | sorted entry X lists identical at the three caps; count 100, doubles 0 each (`Engine.max_fps`, headless) | none |
| S-0003-B.5 | `Engine.get_physics_frames()` stamps at each callback | PASS | used in B.2 and B.3 | none |
| S-0003-C | grey `planta` synchronous load hitch (record only, 2026-11-12) | RECORDED (informative) | Godot 4.7.2 local editor build, windowed, `RealClock`, 5 fresh processes (`tools/evidence/s0003c_measure.tscn`). `SceneSource.instantiate` (load + instantiate of `planta.tscn`): median 293.5 ms, worst 307.7 ms. Longest frame gap from the request to READY (the hitch, render included): median 349.7 ms, worst 386.0 ms (336.3 / 341.4 / 349.7 / 363.5 / 386.0). Worst case < 1 s: no new ADR on D4 is triggered. **Caveat**: this is the developer's machine with the editor build, not a reference hardware nor an export (`playtest-windows`/`playtest-linux` pending, C-M1-10); the hitch happens behind the black curtain (alpha 1). | none (re-measure in the export) |

## Open Items

| # | Item | Owner | Before |
|---|---|---|---|
| O1 | Payload additions ‡: `control_final` in «carga de escena iniciada» and «carga de escena terminada», `t_since_started_s` in «terminada» (21 needs both for rule 8a and F5) | GDD 3 regla 10, GDD 4, GDD 21 (propagation) + ADR-0001 | ADR-0001 accepted |
| O2 | Same-frame delivery guarantee of the bus relative to input dispatch (R6) | ADR-0001 / ADR-0006 | Either accepted |
| O3 | ~~Exact `InputContexts` signatures and the owner `StringName`s~~ Resolved (reconciliation 2026-11-10): ADR-0006 signatures adopted (`open_no_control(owner, declared_s, absorbs_foreign)`, `close_no_control(owner)`); owners `&"scene_loader"`, `&"scene_director"`; tope on `GameClock` | ADR-0006 | — |
| O4 | Who lifts the curtain over the title after a full unload, and with which duration (GDD 4 OQ 8 open); proposal: a `titulo` row in `load_transitions.json`, `d_in` 0,8 s† (0,1 s with `reducir_movimiento`), triggered by 27 when ready | GDD 4 + GDD 27 | Title story |
| O5 | Full unload from a visible scene (pause) fades in 0,1 s instead of a cut: GDD 4 rule 15 says "sin fundidos", rule 11 says the curtain is always a fade | GDD 4 author | Next GDD 4 revision |
| O6 | ~~`colocar` angle units and teleport reset of physics interpolation~~ Resolved by ADR-0012 D2/D4: radians; `TickInterpolator.reset` in `colocar`; `colocar` before `configurar` stores a pending placement completed by `configurar` (ADR-0012 C2) | ADR-0012 | — |
| O7 | Collision layer name/number `zone_sensor` in the project layer table | ADR-0011 (masks) | ADR-0011 |
| O8 | ~~Zone sensor activation range 8,923–8,95 (S-0003-B.1 FAIL)~~ **Resuelto 2026-11-11: rango corregido a (8,95; 8,977], Alternativa 5 descartada** (user decision; GDD 2 rule 4/D-46, GDD 4 rule 18(c), TR-player-003 updated). Status stays `Proposed` | game-designer | — |

### Contradictions found in the sources

| # | Between | Resolution in this ADR |
|---|---|---|
| C1 | `architecture.md` § Data Flow 5 ("«iniciada» ─► 1 abre `sin control`(4, D_carga)", read as Entrada reacting to the notice) vs GDD 4 rule 9 ("quién abre … este sistema") | GDD wins: 4 opens SYNC right after emitting «iniciada» (D6). `architecture.md` wording to align |
| C2 | `architecture.md` § Árbol (title in `WorldSlot`) vs GDD 4 rule 9.3 ("si venía del título no hay escena que descargar") | D2: freeing the title is not a «descarga»; no stack reset |
| C3 | GDD 4 rule 15 ("sin fundidos") vs rule 11 (curtain is always a fade) for a full unload from a visible scene | 0,1 s fade; O5 |
| C4 | GDD 21 rule 11b ("«Nueva partida» o «Continuar» desde la pausa") vs GDD 25 rule 31 / GDD 4 round 10 (no «Continuar» in the pause) | No effect on 4; GDD 21 wording to align |
| C5 | GDD 4 rule 17 (warn on «estado restablecido» with a loaded scene) vs TR-save-020 order (reset before request) for «Nueva partida» from the pause | End-of-frame check (§ Preconditions) |
| C6 | GDD 21 rule 8a / F5 need `control_final` and `t_terminada`, but GDD 4/3 payloads of «iniciada»/«terminada» do not carry them | O1 |

## Spike Results (index)

See `## Spike Results (2026-11-11)` above, before Open Items. S-0003-C was recorded on 2026-11-12 (local editor only; export pending).

## Related

- Depends on: ADR-0001, ADR-0002, ADR-0009 (all Proposed, not yet written).
- Enables: ADR-0004, ADR-0006; constrains ADR-0011, ADR-0012, ADR-0016, ADR-0017.
- `docs/architecture/architecture.md` §§ Module Ownership, Data Flow 4–6, API Boundaries/Escena (4), Required ADRs, QQ-12 (closed by D3).
- `docs/architecture/tr-baseline-provisional.md` (TRs listed above).
- `design/gdd/escena-de-planta.md` (rules 1–18, F1–F3, Edge Cases, OQ 1 closed by this ADR), `design/gdd/director-de-escenas.md` (rules 1, 8, 11, F5), `design/gdd/entrada-y-controles.md` (rule 6, F8).
