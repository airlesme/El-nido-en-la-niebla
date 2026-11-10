# ADR-0002: Pause and Game Time

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.
> **Additional gate for this ADR:** it is a decision *conditioned on a spike*
> (§ Spike Plan). It may only move to `Accepted` once the spike report exists and
> every claim in § Spike Plan has a recorded PASS/FAIL; the Decision Rule in that
> section then fixes whether Option A (tree pause) or Option B (`GameClock`
> without tree pause) is the accepted variant. Accepting before the spike is not
> allowed.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/` (pin 4.7.2) and GDDs 23, 25,
26, 28, 29 in their round-10 state. Nothing pause-related is verified on the
engine yet (see § Engine Compatibility).

## Decision Makers

technical-director (autonomous batch mode, `modes.automation: autonomous`);
user approval at batch close. Inputs: `architecture.md` § Required ADRs (row
ADR-0002), § Data Flow (Pause), QQ-06, QQ-17.

## Summary

Every timed rule in the slice (puzzles, call, scene director, subtitles,
atmosphere, shaders, access, box, computer, input safety cap) must stop exactly
while the pause menu (25) is open, while the pause UI, settings deferred save,
save retries, key-capture timer, volume sample and scene-load cap keep running
in real time; GDDs 23 D23-25 and 28 R22 / 29 R35 contradict each other on
whether the scene tree is paused. Decision: `GameClock` (autoload) is the only
source of game time (Δ_juego) and the only owner of "pause active" in **both**
variants; the recommended variant **A** additionally sets `SceneTree.paused = true`
with an explicit `process_mode` per system (table in § Decision), and variant
**B** (fallback) keeps the tree running and gates engine-driven presentation
per system — the choice between A and B is made by a mandatory spike on 4.7.2.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — every engine behaviour this decision touches (tree pause, `process_mode`, pause of `Tween` / `AnimationPlayer` / `GPUParticles3D` / audio players, shader `TIME`, physics interpolation under pause) is NOT SOURCEABLE; see table below |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `breaking-changes.md` (4.5 "3D interpolation rearchitected — moved from RenderingServer to SceneTree"; 4.7 `RenderingServer.particles_request_process_time()` rename; `AnimationMixer` base class); `deprecated-apis.md` (`Time.get_ticks_msec()` preferred over `OS.get_ticks_msec()`; `AnimationMixer.callback_mode_method`, `AnimationMixer.active`); `current-best-practices.md` and `modules/animation.md` (`Tween.tween_await()`, 4.7); `modules/physics.md` (4.5 interpolation note); `modules/audio.md` (`create_tween()` fade example, player pooling); `modules/input.md`, `modules/ui.md`, `modules/rendering.md` (searched; no pause content) |
| **Post-Cutoff APIs Used** | None load-bearing by name. The decision is *affected* by the 4.5 physics-interpolation rearchitecture (`breaking-changes.md`, `modules/physics.md`: "API unchanged but internals differ"), which is why S11 exists |
| **Verification Required** | All 16 claims of § Spike Plan (S1–S16), on 4.7.2, windowed and headless where noted, before `Accepted` |

**What the engine reference does cover (sourceable, used here):**

| Fact | Source |
|---|---|
| `Time.get_ticks_msec()` is the preferred millisecond tick source (replaces `OS.get_ticks_msec()`) | `docs/engine-reference/godot/deprecated-apis.md` |
| 3D physics interpolation moved from `RenderingServer` to `SceneTree` in 4.5; user API unchanged, internals differ in edge cases | `docs/engine-reference/godot/breaking-changes.md`, `modules/physics.md` |
| `AnimationPlayer` and `AnimationTree` extend `AnimationMixer`; `callback_mode_method`, `active` live on the base class | `docs/engine-reference/godot/breaking-changes.md`, `deprecated-apis.md` |
| `Tween.tween_await()` (4.7) pauses a tween *until a signal is emitted* (not related to tree pause) | `docs/engine-reference/godot/modules/animation.md` |
| `RenderingServer.particles_request_process_time()` parameter renamed `process_time`, `process_time_residual` added (4.7) | `docs/engine-reference/godot/breaking-changes.md` |
| `create_tween()` + `tween_property()` + `await tween.finished` (fade pattern) | `docs/engine-reference/godot/modules/audio.md` |

**NOT SOURCEABLE behaviours (never filled in from memory):** every entry is
`NOT SOURCEABLE — <what> not covered by docs/engine-reference/godot/`. The
identifiers below (`PROCESS_MODE_*`, `TWEEN_PAUSE_*`, `stream_paused`, …) are
the names the GDDs already use with ‡; their *existence and spelling* in 4.7.2
is part of what the spike confirms.

| # | Behaviour this ADR depends on | Status | Spike claim |
|---|---|---|---|
| NS-1 | `SceneTree.paused` exists and, when `true`, stops `_process` / `_physics_process` of nodes whose effective mode is pausable, from the next callback onwards | NOT SOURCEABLE — tree pause not covered by `docs/engine-reference/godot/` (no file mentions `paused`) | S1 |
| NS-2 | `Node.process_mode` values `PROCESS_MODE_INHERIT` / `PAUSABLE` / `WHEN_PAUSED` / `ALWAYS` / `DISABLED`, inheritance from parent, and the root's default | NOT SOURCEABLE — `process_mode` not covered by `docs/engine-reference/godot/` | S2 |
| NS-3 | A node with `ALWAYS` keeps receiving `_process(delta)` with a real, non-zero `delta` while the tree is paused | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | S3 |
| NS-4 | Input while paused: `ALWAYS` nodes and `Control`s under an `ALWAYS` `CanvasLayer` receive `_input` / GUI events (focus, mouse, gamepad); pausable nodes receive none | NOT SOURCEABLE — input under pause not covered by `docs/engine-reference/godot/modules/input.md` or `modules/ui.md` | S4 |
| NS-5 | `Tween` pause semantics: a tween from `create_tween()` on a pausable node stops while paused and resumes from the same progress; `Tween.set_pause_mode()` with `TWEEN_PAUSE_BOUND` / `STOP` / `PROCESS` exists; a `TWEEN_PAUSE_PROCESS` tween keeps running while paused | NOT SOURCEABLE — Tween pause not covered by `docs/engine-reference/godot/modules/animation.md` (only `tween_await`) | S5 |
| NS-6 | `AnimationPlayer` under a pausable node stops at its current position while paused, fires no method/call tracks, and resumes from there (blocks AC-21 of GDD 10, TR-box-015) | NOT SOURCEABLE — AnimationPlayer under pause not covered by `docs/engine-reference/godot/modules/animation.md` | S6 |
| NS-7 | `GPUParticles3D` under a pausable node freezes its simulation (no advance, no emission) while paused and resumes without a burst | NOT SOURCEABLE — particle pause not covered by `docs/engine-reference/godot/modules/rendering.md` or `breaking-changes.md` | S7 |
| NS-8 | `AudioStreamPlayer` / `AudioStreamPlayer3D` `stream_paused` exists, holds the playback position, and resumes from it | NOT SOURCEABLE — `stream_paused` not covered by `docs/engine-reference/godot/modules/audio.md` | S8 |
| NS-9 | An audio player whose effective mode is `ALWAYS` keeps playing while the tree is paused; what a player under a *pausable* parent does when the tree pauses | NOT SOURCEABLE — audio under tree pause not covered by `docs/engine-reference/godot/modules/audio.md` | S9 |
| NS-10 | Whether the shader built-in `TIME` keeps advancing while the tree is paused | NOT SOURCEABLE — shader `TIME` under pause not covered by `docs/engine-reference/godot/modules/rendering.md` | S10 |
| NS-11 | 3D physics interpolation (SceneTree-based since 4.5) holds the last interpolated transform while paused and does not pop/extrapolate on resume | NOT SOURCEABLE — interpolation *under pause* not covered by `docs/engine-reference/godot/modules/physics.md` (only the 4.5 relocation is) | S11 |
| NS-12 | A `CharacterBody3D` (Jolt) under a pausable node takes no physics step while paused and keeps `velocity` for resume | NOT SOURCEABLE — physics step under pause not covered by `docs/engine-reference/godot/modules/physics.md` | S12 |
| NS-13 | A `Callable` / signal handler bound to a pausable node **executes** when invoked while the tree is paused (bus delivery of «descarga total solicitada», «pausa abierta» to 9, 21, 26, 28) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (ADR-0001 NS-5 covers order, not pause) | S13 |
| NS-14 | `queue_free()` / `remove_child()` of a pausable subtree completes while the tree is paused (unload on «Volver al título»), leaving no orphans | NOT SOURCEABLE — freeing under pause not covered by `docs/engine-reference/godot/` | S14 |
| NS-15 | `_process` order between autoloads / `process_priority` (whether `GameClock` can be made to run first in a frame) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (same gap as ADR-0001 NS-7) | S15 (informative; the design does not rely on it) |
| NS-16 | Pause semantics of `SceneTreeTimer` (`create_timer`) and of `Timer` nodes | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | S16 (informative; both are banned for game time regardless) |

**Also NOT SOURCEABLE, used only by Option B (fallback):** `Tween.pause()` /
`Tween.play()`, `AnimationPlayer.pause()` and `speed_scale`, `GPUParticles3D.speed_scale`
— NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/animation.md`
or `modules/rendering.md`. They are spike claims SB1–SB3 (§ Spike Plan) and only
need to run if Option B is selected.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Event bus and fact contract (`Proposed`) — «pausa abierta» / «pausa cerrada» (`pause_opened` / `pause_closed`) travel on its `NoticeChannel` with synchronous drain; the bus node is `ALWAYS` and never reads `GameClock` (ADR-0001 § ADR Dependencies). Must be `Accepted` before this ADR is implemented |
| **Related (non-blocking)** | ADR-0009 Service composition — registers `GameClock` as autoload #3 and injects `GameClock` / `RealClock` through `ServiceContext` ‡; this ADR fixes the types it injects and the `process_mode` each autoload and `Shell` child gets. ADR-0008 Audio — implements 23's own per-player pause (`stream_paused`, NS-8) and the volume sample on top of this ADR's `process_mode` row for `AudioDirector` |
| **Enables** | ADR-0003 (scene loading: `T_cap` real time, unload while paused, "no instantiate while paused"), ADR-0006 (input: `InputRouter` `ALWAYS`, blocking-context safety cap on game time), ADR-0008 (audio pause), ADR-0010 (puzzle timers on `GameClock`), ADR-0012 (player and physics interpolation under pause), ADR-0014 (atmosphere `Tween` / rain under pause), ADR-0015 (shader phase uniform instead of `TIME`), ADR-0016 (`CanvasLayer` `process_mode` for HUD / subtitles / pause / curtain), ADR-0017 (scene director and call timers on `GameClock`) |
| **Blocks** | Every story with a timer, tween, animation or particle effect, and every story of system 25: epics for 1, 2, 7, 8, 9 (+ 11–16), 10, 17, 19, 21, 22, 23, 25, 26, 28, 29 |
| **Ordering Note** | `architecture.md` § Required ADRs: 0001 → 0002 → 0009 → 0003 can be drafted while the pause spike runs; 0004–0008 depend on 0001 and 0002. The spike (§ Spike Plan) is the first engineering task of the project and must finish before any story listed under **Blocks** starts |

## Context

### Problem Statement

The slice is a slow, tension-without-punishment adventure: the player must be
able to open the pause menu at any moment (except during a scene load) and come
back to *exactly* the same instant — a call on hold with 12 s elapsed must still
be at 12 s after 30 s in the menu (AC-25-09), a box compartment half-open must
continue from that pose (TR-box-015), a flicker mid-fall must finish its
remaining duration (28 R22). At the same time the pause screen itself is live:
it fades a veil, guards the opening press, repeats held directions, captures a
key binding with an 8 s timeout, plays a volume sample, and lets Settings and
Save keep their real-time retries. Thirteen GDDs define timers; without one
owner of "pause active" and of game time each system would reinvent pause, and
the reviews already found them disagreeing.

The decision is needed now because it is Foundation: every timer, tween and
animation in the codebase is written against it, and changing the mechanism
after systems exist means touching all of them.

### Current State

No code exists. The GDDs state a *contract* and leave the *mechanism* to this
ADR (25 R2, D25-28, OQ 2). Their positions:

| Source | Position |
|---|---|
| 25 R2–R5 | 25 marks "pause active": Δ_juego = 0 from the opening frame, resumes on the exit frame; real time continues for UI, 6 deferred save (F3), capture timer (F2), 23 volume sample, 5 retries. "Who physically stops the scene tree is fixed by the ADR" |
| 25 R3, D25-19, D25-30 | 25 emits «pausa abierta» once per effective opening, after entering `menú` and marking pause; «pausa cerrada» once per close, *after* restoring the input context and resuming time. Code names `pause_opened` / `pause_closed`; no aliases. Consumers declared by 3: 5, 23, 26, 28; 21 and 22 use the stopped clock, not the notice |
| 25 R28, R30, D25-27 | «Volver al título»: 5 `quit` save (sync) → 4 «descarga total solicitada» (23 discards paused voices, 26 retires frozen blocks) → unload → «pausa cerrada» only to normalise the clock. «Nueva partida»: «carga iniciada» discards voice and blocks, then «pausa cerrada» |
| **23 R41, D23-25** | Voices and one-shot SFX paused per player (`stream_paused` ‡) on «pausa abierta»; loops and drone continue at `pausa_amb_db` (−6 dB); volume sample never paused; 23 `process_mode` always active; **"no fallback by the tree: 25 only stops game time and does not declare pausing the `SceneTree`"**; line clocks are game time |
| **28 R22** | On «pausa abierta» / «pausa cerrada» 28 freezes `Tween`s and particles (`PROCESS_MODE_PAUSABLE` and `GPUParticles3D` pause ‡) and resumes without jumps — **assumes a pausable tree** |
| **29 R35** | Envelopes on game clock; `Tween` with `PROCESS_MODE_PAUSABLE` ‡ and `TWEEN_PAUSE_STOP` ‡ — **assumes a pausable tree**; `TIME` under pause NOT SOURCEABLE, so 29 does not use `TIME` for anything meaningful (only decorative `film_breath`, phase by uniform from the game clock) |
| 26 R25, OQ 8 | Own clocks on game time, frozen by «pausa abierta», not dependent on tree pause |
| TR-puzzles-014 | Injectable `GameClock` for every framework timer; `SceneTreeTimer` / `create_timer` forbidden |
| TR-input-005 | Blocking-context safety cap (3 s / declared + 2 s) stops with pause |
| `architecture.md` | `GameClock` is autoload #3, sole owner of "pause active" and Δ_juego; recommended (to spike) `SceneTree.paused = true` + explicit `process_mode`; QQ-06 proposes the reconciliation adopted below |

The contradiction (TR-pause-003, QQ-06): 23 D23-25 says the tree is *not*
paused; 28 R22 and 29 R35 rely on it being paused.

### Constraints

- **Engine knowledge:** none of the pause behaviour is in
  `docs/engine-reference/godot/` (16 NS items above). No line of this ADR may
  rely on remembered engine behaviour; everything load-bearing goes through the
  spike.
- **Testability:** all public methods unit-testable with dependency injection
  (coding standards). Timers must be testable without real time passing.
- **Data-driven:** tunable durations live in JSON under `assets/data/`
  (ADR-0005); this ADR adds `assets/data/core/clock.json` ‡ (§ Tuning).
- **Scope:** vertical slice of ~15–30 min, one developer; the solution must be
  small. No slow motion, no time scale, no rewinding are needed.
- **Single thread:** all game code runs on the main thread (`architecture.md`
  § 6 Hilos).
- **Main-loop order is NOT SOURCEABLE** (ADR-0001 NS-7, NS-15 here): no
  guarantee may depend on which node's `_process` runs first.

### Requirements

- R-1: Δ_juego = 0 from the frame pause opens; game time resumes on the exit
  frame (TR-pause-001, TR-input-008).
- R-2: One source of game time, injectable, with a test double (TR-puzzles-014).
- R-3: Real time keeps running for: 25 UI (F1, F2, F3, F4), 6 deferred save
  (F3), 5 retries, 23 volume sample, 4 `T_cap`, 23 dev pause watchdog
  (TR-pause-002).
- R-4: Engine-driven presentation in the world (`Tween`, `AnimationPlayer`,
  `GPUParticles3D`, `CharacterBody3D`, physics interpolation) freezes and
  resumes without jumps (TR-player-015, TR-box-015, TR-atmos-018, TR-shaders-017).
- R-5: 23 and 26 keep their own pause driven by the notices (TR-audio-015,
  TR-subs-008) and 23 is never paused by the tree (TR-audio-001).
- R-6: Exact notice names and order: «pausa abierta» (`pause_opened`) and
  «pausa cerrada» (`pause_closed`), once each, in the order of 25 R3/R5/R28/R30.
- R-7: No `SceneTreeTimer` for game time (TR-puzzles-014).
- R-8: Resolve 23 D23-25 vs 28 R22 / 29 R35 with the smallest GDD change
  (TR-pause-003).
- R-9: Pause must be possible during blocking transitions (focus loss, gamepad
  disconnect; TR-input-008) and never during a scene load (1 rule 7).

## Decision

### D1 — `GameClock` is the only source of game time (both variants)

`GameClock` (autoload #3, `process_mode` `ALWAYS`) owns the "pause active" flag
and game time. **All game-time logic in the codebase reads time from
`GameClock`** — through `now()`, `delta()`, deadlines or `schedule()` — and
never integrates the engine's `delta` into a game-time accumulator of its own.
This is what makes the pause *correct by construction* (TR-puzzles-014): when
pause is active, `GameClock` does not advance, so every timer, envelope, wait
counter and safety cap is frozen whatever the engine does with the tree.

Consequence that drives the rest of the ADR: **the tree pause is not what
makes game time stop.** It only decides who freezes the *engine-driven*
presentation — `Tween`, `AnimationPlayer`, `GPUParticles3D`, physics bodies,
physics interpolation — that does not read `GameClock`. That is the only part
that differs between A and B, and the only part the spike can break.

Real time is a separate injectable `RealClock` (production implementation
reads `Time.get_ticks_msec()`, sourced in `deprecated-apis.md`). Code that must
run during pause (R-3) reads `RealClock`, never `GameClock`.

### D2 — Recommended variant A: `SceneTree.paused = true` + explicit `process_mode`

`GameClock.pause()` / `resume()` call an injected `PauseBackend`. In variant A
the backend is `TreePauseBackend`, which sets `get_tree().paused` (NS-1). Every
node that must run during pause declares its `process_mode` explicitly; the
world inherits the pausable default under `WorldSlot`, which is set
**explicitly** to `PAUSABLE` so the behaviour does not depend on the root's
default (NS-2).

**Rule of thumb:** *autoloads and `Shell` UI layers that must react during
pause are `ALWAYS`; everything under `WorldSlot` is `PAUSABLE`.* `WHEN_PAUSED`
is not used in the slice (see the note after the table).

| Node (system) | `process_mode` | Time it uses | Why |
|---|---|---|---|
| `ContentDB` (18) | `ALWAYS` | none | Read-only catalog; 25, 26, 27 query it during pause. No `_process` |
| `GameState` (3) | `ALWAYS` | none | Bus must drain «pausa abierta» / «descarga total solicitada» while paused (ADR-0001: never reads `GameClock`) |
| `GameClock` | `ALWAYS` | engine `delta` → game time; `RealClock` | Must see the frame in which pause ends; never stops itself |
| `InputRouter` (1) | `ALWAYS` | `RealClock` for polling / hysteresis; **`GameClock`** for the blocking-context safety cap (TR-input-005) | Must route `menú` input, focus loss and gamepad disconnect while paused (TR-input-008); the cap stops with pause |
| `Settings` (6) | `ALWAYS` | `RealClock` (deferred save F3) | Deferred save keeps advancing in real time (AC-25-09) |
| `AudioDirector` (23) | `ALWAYS` | `GameClock` for line clocks; `RealClock` for volume sample, ramps during pause, dev watchdog `t_pausa_max_s` | TR-audio-001; own per-player pause (D4). **All `AudioStreamPlayer*` nodes of the game live under it** (pool + positioned players), none under `WorldSlot` |
| `SaveService` (5) | `ALWAYS` | `RealClock` (retries) | Retries in real time; `quit` save runs while paused |
| `SceneLoader` (4) + `Curtain` | `ALWAYS` | `RealClock` (`T_cap`, unscaled); curtain fade `RealClock` | Unload happens while paused («Volver al título»); `T_cap` is real time |
| `SceneDirector` (21) | `ALWAYS` | `GameClock` (timeline, `t_espera_voz` → 23's `t_cola_canal_s`) | Persistent autoload; reacts to «descarga total completada» during pause; its time stops because `GameClock` stops, not because of the tree |
| `Shell` (root scene) | `ALWAYS` | — | Container; each child sets its own mode explicitly (no child relies on inheriting from `Shell`) |
| `WorldSlot` and the whole world instance: `Player` (2), `InteractionSystem` (7), `Access` (8), `PuzzleFramework` + controllers 11–16 (9), `Box` D01 (10), `HintService` (17), `Computer` V01/V08 (19), `Pocket` (20), `CallController` (22), `Atmosphere` (28), `SurfaceFx` / `FxTarget` (29) | **`PAUSABLE`** (set on `WorldSlot`; descendants `INHERIT`) | `GameClock` for every rule timer; engine-driven presentation frozen by the tree | Freezes `Tween`, `AnimationPlayer`, `GPUParticles3D`, `CharacterBody3D`, interpolation (R-4). Bus handlers and synchronous queries (17's panel inside 25) still run (NS-13) |
| `HUD` `CanvasLayer`: `InteractionPrompt` (24), `HintNote` (17), `ReadingScreen` (20) | `PAUSABLE` | `GameClock` | Hidden behind the veil; 24 re-resolves glyphs on «pausa cerrada» via handler (NS-13) |
| `Subtitles` `CanvasLayer` (26) | `ALWAYS` | `GameClock` (frozen ⇒ blocks frozen) | Sits above the veil and stays visible; must retire blocks on «descarga total solicitada» during pause (26 R27). TR-subs-008 satisfied without depending on the tree |
| `PauseMenu` `CanvasLayer` + `OptionsComponent` (25; reused by 27) | `ALWAYS` | `RealClock` (F1 repeat, F2 capture 8 s and guard 0.25 s, F3 veil, F4 opening guard 0.15 s) | Must process while paused; `OptionsComponent` is also shown on the title **with the tree running**, so it cannot be `WHEN_PAUSED`. In state Cerrado it is hidden and does no work |
| Panel de error (4) | `ALWAYS` | `RealClock` | Must work whatever the pause state |

**Note — deviation from `architecture.md` § Required ADRs (row ADR-0002):** the
row proposed `WHEN_PAUSED` for 25's UI and Options. This ADR uses `ALWAYS`
instead, because (a) `OptionsComponent` is reused by the title (27) where the
tree is not paused, and would be inert under `WHEN_PAUSED`; (b) 25 must handle
the closing frame and the «Volver al título» path, during which `resume()` is
called before 25 is discarded. `WHEN_PAUSED` would add a mode with no benefit
in the slice. Recorded in § Open Items (OI-1) for the architecture doc.

### D3 — Reconciling 23 D23-25 with 28 R22 / 29 R35 (TR-pause-003)

Adopted: the QQ-06 proposal. **The tree is paused (variant A) and 23 and 26 run
`ALWAYS` with their own pause driven by «pausa abierta» / «pausa cerrada».**

| GDD | What stays | What changes (text only) |
|---|---|---|
| 23 R41, D23-25 | Own per-player pause; loops/drone at `pausa_amb_db`; no fallback by the tree; `process_mode` always active; line clocks on game time | The justification "25 only stops game time and does not declare pausing the `SceneTree`" becomes: "the tree may be paused (ADR-0002); 23 is `ALWAYS`, does not inherit it and never uses it as a fallback" |
| 26 R25, OQ 8 | Unchanged: own clocks on game time; OQ 8 closes ("does not depend on the tree" holds in A and B) | — |
| 28 R22 | Freeze `Tween` and particles, resume without jumps | In A the tree does the freezing; 28's «pausa abierta» / «pausa cerrada» handler is the **seam for variant B** and is a no-op for `Tween` / particles in A (it stays subscribed so the contract in 3 does not change) |
| 29 R35 | Envelopes on game clock; no meaningful `TIME`; `film_breath` phase by uniform from `GameClock.now()` | `PROCESS_MODE_PAUSABLE` and `TWEEN_PAUSE_STOP` remain ‡ until S2 / S5 |

Why this works in both variants: 23 and 26 never depended on the tree; 28 and
29 depend on *something* freezing their engine-driven effects, which is the
tree in A and their own adapter in B. No GDD changes its rules, only 23's
rationale text.

### D4 — Notice contract and event order

Names are the GDD names; code names per 25 R3 and ADR-0001 § Notice Name
Registry: «pausa abierta» = `pause_opened`, «pausa cerrada» = `pause_closed`.
No payload, no aliases, one emission per effective opening / closing. Emitter:
25 only. Consumers (declared by 3): 5, 23, 26, 28 (+ 24 for glyph re-resolution
on «pausa cerrada», `architecture.md` § Data Flow). 21 and 22 do **not** consume
them: they use the stopped `GameClock`. `GameClock.paused_changed` is **not** a
substitute for the notices: it exists only for infrastructure (the backend,
tests, the dev overlay); no gameplay or presentation system may connect to it
(guideline G-6).

**Opening** (cause: `pausa` action, window focus lost, active gamepad
disconnected; 1 decides when; never while `carga_en_curso`). All steps in the
same frame, in this order:

| # | Step | Who | Effect |
|---|---|---|---|
| O1 | 25 requests context `menú` from 1; if 1 rejects, stop here (no pause, no notice; 25 Edge Cases) | 25 → 1 | Input context pushed; mouse released (1 rule 7) |
| O2 | `GameClock.pause(&"pause_menu")` | 25 → `GameClock` | `is_paused()` = true, `delta()` = 0 immediately; `now()` frozen; backend applies tree pause (A) or nothing (B); `paused_changed(true)` |
| O3 | 6 «vaciar pendientes» (synchronous call, not the bus; D25-16) | 25 → 6 | Pending settings written |
| O4 | Emit «pausa abierta» (`pause_opened`) | 25 → bus (3) | Drained synchronously (ADR-0001) → 5 save with `cause` = `pause_opened`; 23 `stream_paused` voices and one-shots, loops/drone ramp to −6 dB (real time); 26 freezes (already frozen by O2; it records the state); 28 adapter (no-op in A) |
| O5 | Veil fade starts (F3, real time) | 25 | Visual only; menu accepts input from O1 + F4 guard |

Invariant: anything that reads `GameClock` after O2 in the same frame sees
`delta() == 0`; anything that read it *before* O2 in that frame saw the normal
Δ — acceptable, since main-loop order is NS (NS-15) and the budget is one frame.
Deadlines (§ Key Interfaces) make that frame harmless: `now()` does not advance
on the frame after O2.

**Closing** (Reanudar, `pausa` or `ui_atrás` at root; 25 R5):

| # | Step | Who | Effect |
|---|---|---|---|
| C1 | 25 asks 1 to leave `menú` | 25 → 1 | Previous context restored; cursor where it was; mouse recaptured if the context needs it; closing press held back from the world (25 R6) |
| C2 | `GameClock.resume(&"pause_menu")` | 25 → `GameClock` | Tree unpaused (A); game time advances from the next `GameClock` tick; `paused_changed(false)` |
| C3 | Emit «pausa cerrada» (`pause_closed`) — last | 25 → bus | 23 resumes voices / one-shots and ramps loops back; 26 resumes; 28 adapter (no-op in A); 24 re-resolves glyphs |

**«Volver al título» from the pause** (25 R28; order "solicitada → completada →
pausa cerrada"; the tree stays paused until T6):

| # | Step | Effect |
|---|---|---|
| T1 | 25 → Saliendo; 25 → 5 «salir al título» (`quit`, urgent, synchronous I/O) | One write, no retry |
| T2 | 25 → 4 descarga total; 4 emits «descarga total solicitada» | 23 discards paused voices / one-shots and queue; 26 retires frozen blocks (handlers on `ALWAYS` nodes) |
| T3 | 4 frees the world instance **while the tree is paused** (NS-14) | No world node processes during its own teardown |
| T4 | 1 restores `menú` with the title menu as base | — |
| T5 | 4 emits «descarga total completada» | 5 re-inspects; 21 clears volatile memory |
| T6 | `GameClock.resume(&"pause_menu")`, then 25 emits «pausa cerrada» and is discarded | Clock normalised; nothing is left to resume (23, 26 ignore it without error) |

**«Nueva partida» from the pause** (25 R30): 25 → Saliendo → 5
`nueva_partida()` → 4 opens load (`partida_nueva`), 1 discards the stack, 4
emits «carga iniciada» (23 discards paused voice; 26 retires blocks; 9 and 21
cancel their waits, 23 R42) → **25 calls `GameClock.resume()` and emits «pausa
cerrada»** → 4 continues unload + instantiate behind the curtain in `sin
control`. Hard rule for 4 (ADR-0003): **never add a world instance to
`WorldSlot` while `GameClock.is_paused()`**; unloading while paused is allowed
(T3). See OI-3.

### D5 — What runs in real time during pause

| Item | Owner | Clock | Node mode |
|---|---|---|---|
| Pause UI: veil F3 (0.35 / 0.10 s), opening guard F4 (0.15 s), direction repeat F1 | 25 | `RealClock` | `ALWAYS` |
| Key-capture timer F2 (8 s) and capture guard (0.25 s) | 25 | `RealClock` | `ALWAYS` |
| Settings deferred save (6 F3) | 6 | `RealClock` | `ALWAYS` |
| Save retries | 5 | `RealClock` | `ALWAYS` |
| Volume sample of the sliders (`UI_VOL_MUESTRA` / `SFX_CLICK_SUBTLE`), never `stream_paused` | 23 | `RealClock` (+ audio playback, NS-9) | `ALWAYS` |
| Loops / drone at `pausa_amb_db`, ramp 0.05 s | 23 | `RealClock` | `ALWAYS` |
| Scene-load cap `T_cap` (real time, unscaled) and curtain | 4 | `RealClock` | `ALWAYS` |
| Dev pause watchdog `t_pausa_max_s` (600 s, warning only) | 23 | `RealClock` | `ALWAYS` |

**Stops with pause (game time, `GameClock`):** 1 blocking-context safety cap;
2 movement, braking, interpolations, bob, gestures, transfers and `t` of F7 /
F9 / F10 (TR-player-015); 7 deferred-request cap; 8 (all 8 timers,
TR-access-012); 9 F1–F3, F8, locks, `close_view_after_s`, `line_grace_s`
(TR-puzzles-014); 10 animations and watchers (TR-box-015); 17 hint timers; 19
`t_busqueda`, `t_impresion`, `t_tipeo_inactivo` (TR-computer-009); 21 timeline;
22 call state machine and 20 s wait; 23 line clocks; 26 block clocks,
minimums, `fallback_s`; 28 tweens, flicker, rain; 29 envelopes and
`film_breath` phase.

### D6 — Ban on `SceneTreeTimer` and `Timer` for game time

Game code **must never** use `get_tree().create_timer()` (`SceneTreeTimer`) or
`Timer` nodes for game time, and must not use them for real time either in
gameplay / presentation systems: their pause semantics are NS-16, and two
timer mechanisms per system is the failure mode this ADR exists to prevent.
Game-time waits use `GameClock.schedule()` or deadlines; real-time waits use
`RealClock` deadlines polled in `_process` of an `ALWAYS` node. One-frame
deferrals with no duration are out of scope of this ban; the mechanism for
them is not fixed here (its behaviour under pause is part of NS-1 / S1). A CI grep (`tools/ci/` ‡, ADR-0018) fails
the build on `create_timer(` or `Timer.new(` outside `tests/` and `prototypes/`.

### D7 — Variant B (fallback): `GameClock` without tree pause

Selected only if the spike's Decision Rule says so (§ Spike Plan). Same
`GameClock`, same notices, same order, same `process_mode` table **except**
`WorldSlot` stays `PAUSABLE` but the tree is never paused (`NullPauseBackend`).
What changes:

- Game-time rules: unchanged (they already read `GameClock`).
- `_physics_process` of 2 (and any physics consumer) begins with
  `if clock.is_paused(): return` — written in A as well (guideline G-4), so B
  needs no change here.
- World input: already gated by 1's context stack (`menú` on top ⇒ no world
  actions), so no change.
- Engine-driven presentation registers with a `PauseAdapter` (one per scene,
  owned by the world root, listening to `paused_changed`) that, per registered
  object, calls `Tween.pause()` / `play()` (SB1), `AnimationPlayer.pause()` /
  `play()` or `speed_scale` (SB2), `GPUParticles3D.speed_scale` (SB3). 28 and
  29 use their «pausa abierta» / «pausa cerrada» handlers for the same.
- Physics interpolation: 2 resets / holds interpolation on pause per ADR-0012.

**Partial B** is allowed: if only some presentation claims fail (S5, S6, S7,
S11, S12), keep A and register just the failing kind with the adapter.

### Architecture Diagram

```text
 InputRouter (1, ALWAYS) ── `pausa` / focus lost / pad lost ──► PauseMenu (25, ALWAYS)
                                                                  │ O1 push `menú`
                                                                  │ O2 pause(&"pause_menu")
                                                                  ▼
            ┌──────────────────────── GameClock (autoload, ALWAYS) ─────────────────────┐
            │ holders: Set[StringName]   game_time_s   frame_delta_s   schedule heap      │
            │ _process(engine Δ) ─► advance(min(Δ, max_frame_delta_s)) if not paused     │
            │ pause()/resume() ─► PauseBackend.apply(paused)                             │
            └──────────┬──────────────────────────────────────────────┬─────────────────┘
                       │ A: TreePauseBackend                          │ B: NullPauseBackend
                       ▼ get_tree().paused = true (NS-1)              ▼ (nothing) + PauseAdapter
         ┌──────────── SceneTree ──────────────────────────────┐   per world root (SB1–SB3)
         │ ALWAYS: autoloads, Subtitles, PauseMenu, Curtain    │
         │ PAUSABLE: WorldSlot ─► world (2,7,8,9,10,17,19,20,  │
         │           22,28,29), HUD (24, 17 note, 20 reading)  │
         └─────────────────────────────────────────────────────┘
  readers of game time:  now() / delta() / deadline / schedule()  ◄── 1 cap, 2, 7–10, 17, 19, 21–23, 26, 28, 29
  readers of real time:  RealClock.now_ms() (Time.get_ticks_msec) ◄── 4 T_cap, 5, 6, 23 sample/ramps, 25 F1–F4
  notices (bus, ADR-0001): O4 «pausa abierta» → 5, 23, 26, 28      C3 «pausa cerrada» → 5*, 23, 26, 28, 24
                           (* 5 ignores «pausa cerrada»; listed by 3 as consumer)
```

### Key Interfaces

Signatures close the ‡ of `architecture.md` § Pausa and QQ-17. GDScript,
typed. Engine calls that are NOT SOURCEABLE are confined to
`TreePauseBackend` (and `PauseAdapter` in B), the only files that name them.
Comments are written with a single `#` here so that `Grep ^#` section lookups
on this ADR do not match code; in the real source, public APIs use `##` doc
comments (coding standards).

```gdscript
# Real-time source. Production reads Time.get_ticks_msec() (deprecated-apis.md).
class_name RealClock extends RefCounted

# Milliseconds since an arbitrary origin; monotonic within a session.
func now_ms() -> int:
	return Time.get_ticks_msec()


# Test double: time moves only when the test says so.
class_name FakeRealClock extends RealClock

var _ms: int = 0

func now_ms() -> int:
	return _ms

func advance_ms(ms: int) -> void:
	_ms += ms
```

```gdscript
# Strategy that applies (or not) the engine-side pause. Variant A or B is chosen
# in Boot (ADR-0009); nothing else names the backend.
class_name PauseBackend extends RefCounted

func apply(_paused: bool) -> void:
	return


# Variant A. The ONLY file that writes SceneTree.paused (NS-1, spike S1).
class_name TreePauseBackend extends PauseBackend

var _tree: SceneTree

func _init(tree: SceneTree) -> void:
	_tree = tree

func apply(paused: bool) -> void:
	_tree.paused = paused  # NOT SOURCEABLE until S1 passes


# Variant B and unit tests.
class_name NullPauseBackend extends PauseBackend
```

```gdscript
# Sole owner of "pause active" and of game time (Δ_juego). Autoload #3,
# process_mode ALWAYS (set in its scene, NS-2). Systems receive it by injection.
class_name GameClock extends Node

# Infrastructure only (backend, PauseAdapter, tests, dev overlay). Gameplay and
# presentation use the bus notices «pausa abierta» / «pausa cerrada» (G-6).
signal paused_changed(is_paused: bool)

const NO_HANDLE: int = -1

var _backend: PauseBackend = NullPauseBackend.new()
var _max_frame_delta_s: float = 0.25          # from assets/data/core/clock.json ‡
var _holders: Dictionary[StringName, bool] = {}
var _game_time_s: float = 0.0
var _frame_delta_s: float = 0.0
var _next_handle: int = 0
var _scheduled: Array[_Scheduled] = []        # kept sorted by (due_s, handle)

class _Scheduled:
	var handle: int
	var due_s: float
	var callback: Callable

# Composition point (Boot, ADR-0009). Never called by systems.
func configure(backend: PauseBackend, max_frame_delta_s: float) -> void:
	_backend = backend
	_max_frame_delta_s = max_frame_delta_s

func _process(delta: float) -> void:
	advance(delta)

# Seconds of game time since the session clock started. Frozen while paused.
func now() -> float:
	return _game_time_s

# Game-time Δ of the current frame; 0.0 while paused and on the frame pause opens.
func delta() -> float:
	return _frame_delta_s

func is_paused() -> bool:
	return not _holders.is_empty()

# Idempotent per requester. Δ becomes 0 immediately (same frame).
func pause(requester: StringName) -> void:
	var was_paused: bool = is_paused()
	_holders[requester] = true
	_frame_delta_s = 0.0
	if not was_paused:
		_backend.apply(true)
		paused_changed.emit(true)

# Releases one requester; time resumes only when no requester holds the pause.
func resume(requester: StringName) -> void:
	if not _holders.has(requester):
		return  # unknown requester: logged through ErrorPolicy (ADR-0001), no effect
	_holders.erase(requester)
	if not is_paused():
		_backend.apply(false)
		paused_changed.emit(false)

# Absolute game time at which something `after_s` from now is due.
func deadline(after_s: float) -> float:
	return _game_time_s + after_s

func is_due(deadline_s: float) -> bool:
	return _game_time_s >= deadline_s

# Calls `callback` once when game time reaches now() + after_s. Never fires
# while paused. Returns a handle for cancel().
func schedule(after_s: float, callback: Callable) -> int:
	var entry := _Scheduled.new()
	entry.handle = _next_handle
	entry.due_s = _game_time_s + maxf(after_s, 0.0)
	entry.callback = callback
	_next_handle += 1
	_insert_sorted(entry)
	return entry.handle

func cancel(handle: int) -> void:
	for i: int in _scheduled.size():
		if _scheduled[i].handle == handle:
			_scheduled.remove_at(i)
			return

# Public for tests: drives the clock without the engine loop.
func advance(engine_delta_s: float) -> void:
	if is_paused():
		_frame_delta_s = 0.0
		return
	_frame_delta_s = clampf(engine_delta_s, 0.0, _max_frame_delta_s)
	_game_time_s += _frame_delta_s
	while not _scheduled.is_empty() and _scheduled[0].due_s <= _game_time_s:
		var due: _Scheduled = _scheduled.pop_front()
		if due.callback.is_valid():  # NS per ADR-0001 NS-1 (freed owner)
			due.callback.call()
		if is_paused():
			break  # a callback opened the pause: remaining entries wait

# Test/reset support: new session (Nueva partida, title). Clears schedule.
func reset_session() -> void:
	_scheduled.clear()
	_game_time_s = 0.0
	_frame_delta_s = 0.0

func _insert_sorted(entry: _Scheduled) -> void:
	var i: int = _scheduled.size()
	while i > 0 and _scheduled[i - 1].due_s > entry.due_s:
		i -= 1
	_scheduled.insert(i, entry)
```

Notes on the interface:

- The typed `Dictionary[StringName, bool]` and typed `for i: int` loop are
  not confirmed by `docs/engine-reference/godot/`; if the parse check on 4.7.2
  rejects either, use an untyped `Dictionary` / loop — not a design change.
- `_Scheduled` is an inner class to keep `GameClock` one file; ADR-0009 may
  move it. Insertion is O(n); the slice has tens of scheduled entries at most.
- `reset_session()` is called by 4 (ADR-0003) when a new world session starts;
  game time is not persisted (no GDD saves it; timers are volatile and
  re-derived from facts).
- `pause()` while already paused by the same requester is a no-op, which
  covers 25's "already open: no reopen, no re-emit" edge case at clock level.

**Usage pattern (consumers):**

```gdscript
# Example: 22's 20 s wait in OPCIONES (game time; frozen by pause by construction).
class_name CallWaitTimer extends RefCounted

var _clock: GameClock
var _handle: int = GameClock.NO_HANDLE

func _init(clock: GameClock) -> void:
	_clock = clock

func start(wait_s: float, on_timeout: Callable) -> void:
	stop()
	_handle = _clock.schedule(wait_s, on_timeout)

func stop() -> void:
	if _handle != GameClock.NO_HANDLE:
		_clock.cancel(_handle)
		_handle = GameClock.NO_HANDLE
```

```gdscript
# Example: 25's key-capture timer F2 (real time; runs while paused).
# PauseMenu is ALWAYS, so _process keeps running (NS-3, spike S3).
var _real: RealClock
var _capture_deadline_ms: int = -1

func _start_capture(timeout_s: float) -> void:
	_capture_deadline_ms = _real.now_ms() + int(timeout_s * 1000.0)

func _process(_delta: float) -> void:
	if _capture_deadline_ms >= 0 and _real.now_ms() >= _capture_deadline_ms:
		_capture_deadline_ms = -1
		_cancel_capture()
```

```gdscript
# Example: 2's physics guard (G-4). Redundant in A, required in B.
func _physics_process(delta: float) -> void:
	if _clock.is_paused():
		return
	_step_movement(delta)
```

### Implementation Guidelines

- **G-1** All game-time logic **must** read time from an injected `GameClock`
  (`now`, `delta`, `deadline`/`is_due`, `schedule`/`cancel`). It **must never**
  accumulate the engine `delta` of `_process` into a game-time counter of its
  own. Exception: engine-driven presentation (Tween, AnimationPlayer,
  particles, physics step) which the tree / adapter freezes.
- **G-2** Code that must run during pause **must** use an injected `RealClock`
  and live on an `ALWAYS` node (§ D2 table). It **must never** read
  `GameClock` for that purpose.
- **G-3** `get_tree().create_timer()`, `Timer` nodes and `Engine.time_scale`
  **must never** be used in `src/` (D6). CI grep enforces it.
- **G-4** Every `_physics_process` that moves a body **must** start with
  `if clock.is_paused(): return`.
- **G-5** Only `TreePauseBackend` writes `SceneTree.paused`. Only `GameClock`
  calls the backend. Only 25 calls `GameClock.pause()` / `resume()` in the
  slice (requester `&"pause_menu"`); a dev console may use its own requester.
- **G-6** No gameplay or presentation system connects to
  `GameClock.paused_changed`; they consume «pausa abierta» / «pausa cerrada»
  on the bus, or simply observe that `GameClock` stopped.
- **G-7** Every `process_mode` in § D2 **must** be set explicitly in the owning
  `.tscn` (or in `Boot` for autoloads), never left to inheritance from `Shell`
  or the root. `WorldSlot` is explicitly `PAUSABLE`.
- **G-8** All `AudioStreamPlayer*` nodes **must** be owned by 23
  (`AudioDirector`, `ALWAYS`); scenes provide marker nodes only (23 R19).
- **G-9** World tweens **must** be created with the owning world node's
  `create_tween()` (bound to a pausable node), never `get_tree().create_tween()`;
  their pause mode is set by a single helper `FxTween.make(node)` ‡ so that the
  `TWEEN_PAUSE_*` value chosen by S5 lives in one place. UI tweens on `ALWAYS`
  nodes (veil) use the same helper with `ui = true`.
- **G-10** Shaders **must not** use `TIME` for anything with gameplay or
  timing meaning; time-driven phases are uniforms fed from `GameClock.now()`
  (29 R35). Decorative use of `TIME` is allowed only where freezing in pause is
  not required.
- **G-11** 4 **must never** add a world instance to `WorldSlot` while
  `GameClock.is_paused()`; freeing the current world while paused is allowed.
- **G-12** Pause **must not** be opened while 4 has `carga_en_curso` (1 rule 7);
  `GameClock.pause()` asserts it through `ErrorPolicy` in debug.

### Tuning

`assets/data/core/clock.json` ‡ (path per ADR-0005):

| Key | Default | Safe range | Affects |
|---|---|---|---|
| `max_frame_delta_s` | 0.25† | 0.05–0.5 | Largest game-time step per frame; a hitch longer than this slows game time instead of jumping timers (e.g. a 2 s stall advances game time 0.25 s) |

All pause-UI durations stay in 25's data (`ui/pause.json`), 23's in
`audio/audio_settings.json`; this ADR adds no other knob.

## Spike Plan

**Goal:** turn NS-1…NS-16 into PASS/FAIL facts on **4.7.2.stable** and select
A, partial B or B. **Where:** `prototypes/spike-pause/` (throwaway, outside
the code root; its own `project.godot` with Jolt as in the project). **Owner:**
engine-programmer (Godot specialist), reviewed by technical-director.
**Harness:** a `SpikeShell` scene that mirrors § D2 (`ALWAYS` autoload stand-ins,
an `ALWAYS` `CanvasLayer` with a `Button` list, a `PAUSABLE` `WorldSlot`), the
`GameClock` / `RealClock` / backends of § Key Interfaces, and a probe node per
claim. gdUnit4 headless for claims marked **H**; windowed run with retained
screenshots or capture for claims marked **W** (rendering cannot be judged
headless, coding standards § What NOT to Automate). Conventions: 60 Hz physics;
"paused window" = 120 rendered frames (≈ 2 s); every probe also logs which API
names parsed, because the names themselves are unconfirmed. Any measuring call
that is itself NS (e.g. a playback-position getter, an orphan-node counter) is
listed in the report with whether it worked.

| # | Claim (NS) | Prototype and measurement | PASS criterion | On FAIL |
|---|---|---|---|---|
| S1 | Tree pause stops pausable processing (NS-1) — **H** | Probe under `WorldSlot` counts `_process` and `_physics_process` calls; backend sets pause at frame k for 120 frames, then clears it | 0 calls during frames k+1…k+120 (one call at frame k tolerated); counting resumes within 1 frame after unpause | **B** |
| S2 | `process_mode` values and inheritance (NS-2) — **H** | Script referencing the five `PROCESS_MODE_*` constants; `INHERIT` child under a `PAUSABLE` and under an `ALWAYS` parent; log the root's effective mode | Script parses; `INHERIT` child follows its parent in both cases; explicit `PAUSABLE` on `WorldSlot` works whatever the root default is | **B** (and correct names in § D2 if only spelling differs: not a FAIL) |
| S3 | `ALWAYS` keeps processing with real Δ (NS-3) — **H** | Probe under `ALWAYS` node; compare Σ`delta` over the paused window with `RealClock` elapsed | 120 ±1 calls; Σ`delta` within ±5 % of real elapsed; never 0 | **B** |
| S4 | Input during pause (NS-4) — **W** + **H** where simulated input is available | Keyboard, mouse click and gamepad (connect / disconnect) during pause: counters on an `ALWAYS` probe, on a `PAUSABLE` probe, and on a `Button` list in the `ALWAYS` `CanvasLayer` (focus navigation + click) | `ALWAYS` probe and buttons receive every event; `PAUSABLE` probe receives 0; focus moves with keyboard and gamepad; click activates | **B** (UI and 1 must work in pause; this is non-negotiable) |
| S5 | `Tween` under pause (NS-5) — **H** | `create_tween()` on a `PAUSABLE` node: property 0→1 over 1.0 s; pause at 0.5 s for the window; repeat for each `TWEEN_PAUSE_*` value; a `TWEEN_PAUSE_PROCESS` tween on an `ALWAYS` node (veil stand-in) | World tween value constant (bit-exact) during pause; completes at 1.0 s of *unpaused* time ±1 frame; no step at resume larger than one frame's step; the `ALWAYS` veil tween completes during pause. Record which `TWEEN_PAUSE_*` value achieves this | **Partial B** for tweens (SB1); fix G-9 helper to the value that passes |
| S6 | `AnimationPlayer` under pause (NS-6) — **H** | 1.6 s animation (`BOX_OPEN_MAX`) with a method track at 1.0 s; pause at 0.8 s for the window | Position constant during pause; method track not called during pause; called exactly once after resume; `animation_finished` after 1.6 s of unpaused time ±1 frame. Unblocks AC-21 of 10 | **Partial B** for animations (SB2) |
| S7 | `GPUParticles3D` under pause (NS-7) — **W** | Rain emitter (28 stand-in) in view; screenshots at frames k+1, k+60, k+120 of the pause and k+121…k+130 after resume | Paused screenshots identical in the particle region (pixel diff 0, or ≤ 0.1 % pixels if TAA/noise is on and documented); no visible burst or density change on resume (capture reviewed). Unblocks AC-28-16 | **Partial B** for particles (SB3) |
| S8 | `stream_paused` (NS-8) — **H** + listening | 10 s tone with audible markers on an `ALWAYS` player; `stream_paused = true` at 3.0 s for 5 s of real time | Position holds 3.0 s ±0.05 during pause; resume continues from 3.0 s ±0.05 (audibly no restart, no skip); property name parses | ADR-0008 picks another per-player mechanism (not an A/B question); AC-23-18 stays PV |
| S9 | Audio under tree pause (NS-9) — **H** + listening | Looping player under `ALWAYS` (23 stand-in) and one under `PAUSABLE` during the window | `ALWAYS` player keeps playing (position advances ≈ real time ±5 %); `PAUSABLE` behaviour recorded (informative under G-8) | **B** (if the tree pause silences `ALWAYS` audio, 23 R41 and D23-7 cannot hold under A) |
| S10 | Shader `TIME` under pause (NS-10) — **W**, informative | Quad whose colour is driven by `TIME`; two screenshots 1 s apart during pause | Informative: record whether `TIME` advances. G-10 already holds in both outcomes | — |
| S11 | Physics interpolation under pause (NS-11) — **W** | Interpolation on (setting name per ADR-0012), camera on a moving `CharacterBody3D`, render rate ≠ physics rate (vsync off, 144 fps cap or uncapped); pause mid-movement; frame-by-frame capture | Camera `global_transform` identical across paused rendered frames; first rendered frame after resume moves ≤ one physics step of displacement; no visible pop in capture | **Partial B** for interpolation (ADR-0012 resets / holds it on pause) |
| S12 | `CharacterBody3D` (Jolt) under pause (NS-12) — **H** | Body with `velocity` v calling `move_and_slide()`, *without* the G-4 guard (to isolate the engine); pause for the window | Position unchanged during pause; `velocity` == v after resume; first step after resume identical to an unpaused step | **Partial B** (G-4 guard already covers it; record that the guard is load-bearing) |
| S13 | Handlers on pausable nodes run while paused (NS-13) — **H** | During pause, an `ALWAYS` emitter calls a `Callable` and emits a signal bound to a `PAUSABLE` node; also a `NoticeChannel` stand-in drain | Handler runs synchronously, exactly once per emission, in the same frame | **B** (9, 21, 26, 28 handlers during «Volver al título» depend on it) |
| S14 | Freeing under pause (NS-14) — **H** | Instantiate a 200-node world stand-in under `WorldSlot`, pause, `queue_free()` it, wait 3 `ALWAYS` frames; repeat 10× (as ADR-0003's spike) | Instance invalid after ≤ 3 frames each time; orphan-node / object count returns to baseline after 10 cycles | **B** for the unload path only: 25 resumes before T3 (and OI-3 reopens) |
| S15 | `_process` order / `process_priority` (NS-15) — **H**, informative | Log call order of three autoload stand-ins with and without `process_priority` | Informative: record the order. Design does not depend on it (deadlines, one-frame tolerance) | — |
| S16 | `SceneTreeTimer` / `Timer` under pause (NS-16) — **H**, informative | Default `create_timer(1.0)` and a `Timer` under `PAUSABLE` during the window | Informative: record whether they advance. Ban D6 holds in both outcomes | — |
| SB1 | `Tween.pause()` / `play()` (B only) — **H** | As S5 with the tree never paused, adapter pauses the tween | Same criterion as S5 | Escalate: write a tick-driven envelope on `GameClock` instead of `Tween` for 28/29 (ADR-0014/0015) |
| SB2 | `AnimationPlayer.pause()` / `play()` or `speed_scale = 0` (B only) — **H** | As S6 with the adapter | Same criterion as S6 | Escalate: drive the animation manually from `GameClock.delta()` (callback mode per ADR-0012) |
| SB3 | `GPUParticles3D.speed_scale = 0` (B only) — **W** | As S7 with the adapter | Same criterion as S7 | Escalate: hide/restore or `RenderingServer.particles_request_process_time()` (renamed parameters sourced in `breaking-changes.md`; behaviour NS) |

**Decision Rule (applied by technical-director when the report lands):**

1. **Core set S1, S2, S3, S4, S9, S13** all PASS → variant **A** is viable.
   Any FAIL in the core set → variant **B** for the whole game; run SB1–SB3.
2. With A viable: each FAIL among **S5, S6, S7, S11, S12** → **partial B** for
   that kind only (adapter registration); run the matching SB.
3. **S14** FAIL → keep A, but 25 calls `GameClock.resume()` before T3 on the
   «Volver al título» path (the world is already in `sin control` behind the
   curtain and 23/26 have discarded at T2); OI-3 reopens for ADR-0003.
4. **S8** FAIL → handled in ADR-0008; does not change A/B.
5. **S10, S15, S16** are informative; their results are recorded and do not
   change the decision.
6. The report updates this ADR (§ Engine Compatibility: NS rows → "verified
   4.7.2 — spike report <date>") and records the verified behaviour in
   `docs/engine-reference/godot/modules/` (25 OQ 2 asks for that), then the
   ADR goes to the user for `Accepted`.

**Estimated cost:** ~2 developer-days (≈ 16 h): harness and backends 0.25 d;
headless claims S1–S3, S5, S6, S8, S9, S12–S16 with gdUnit4 0.75 d; windowed
claims S4, S7, S10, S11 with retained evidence 0.5 d; report and
engine-reference update 0.5 d. If the Decision Rule selects full B: +1 d for
SB1–SB3 and the `PauseAdapter`. Partial B: +0.25 d per failing kind.

## Alternatives Considered

### Alternative 1: Variant B as the primary decision (own `GameClock`, tree never paused)
- **Description**: § D7 applied from the start: no `SceneTree.paused`; every
  engine-driven effect in the world registers with a `PauseAdapter`.
- **Pros**: Does not depend on S1–S4 / S13 / S14; matches 23 D23-25 literally;
  pause logic fully visible in project code.
- **Cons**: Every tween, animation and emitter must register (easy to forget,
  only visible in play); still relies on NS APIs (SB1–SB3), so it does not
  remove engine risk, it moves it; more code in 2, 8, 10, 28, 29.
- **Estimated Effort**: +1 d infrastructure, plus per-system registration
  (≈ 0.25 d spread across 5 systems).
- **Rejection Reason**: Not rejected — **kept as the fallback**. Not primary
  because it costs more code for the same or larger NS surface, and the engine
  feature it replaces is the conventional mechanism for exactly this need.

### Alternative 2: `Engine.time_scale = 0` during pause
- **Description**: Freeze all engine time globally.
- **Pros**: One line.
- **Cons**: Its effect on `ALWAYS` nodes' `delta`, UI tweens, audio and physics
  is NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`; likely
  freezes the pause UI itself (veil, guards, capture timer) which 25 requires in
  real time; a hidden global that every test would have to reset.
- **Estimated Effort**: Low to write, high to make the pause UI work.
- **Rejection Reason**: Conflicts with R-3; banned by G-3.

### Alternative 3: Notice-only pause per system, no central clock
- **Description**: Extend 23/26's model to everyone: each system listens to
  «pausa abierta» / «pausa cerrada» and stops its own timers.
- **Pros**: No new module; no engine dependence for game time.
- **Cons**: Thirteen implementations of the same rule; ordering bugs (a timer
  firing in the frame before the notice drains); no shared test double;
  contradicts TR-puzzles-014 (injectable `GameClock`) and `architecture.md`
  autoload #3.
- **Estimated Effort**: Similar code, much higher test cost.
- **Rejection Reason**: Violates R-2 and the single-owner rule.

### Alternative 4: `WHEN_PAUSED` for 25's UI and Options (as in the `architecture.md` row)
- **Description**: 25 processes only while paused.
- **Pros**: Guarantees the menu does no work in play.
- **Cons**: `OptionsComponent` is reused by the title with the tree running and
  would be inert; complicates the closing and «Volver al título» frames.
- **Estimated Effort**: Same.
- **Rejection Reason**: Breaks 25 R15 / 27's reuse; `ALWAYS` + hidden has the
  same cost and no failure case (§ D2 note).

## Consequences

### Positive
- Game time stops by construction for every rule timer, independent of the
  engine outcome: the spike can only change *presentation* freezing, never the
  correctness of AC-25-09-type requirements.
- One test double (`GameClock.advance()`, `FakeRealClock`) makes every timer in
  13 systems unit-testable without waiting.
- A→B is a one-line change in `Boot` (backend) plus adapter registrations; no
  gameplay code changes, because G-1/G-4 are written for both.
- The 23 ↔ 28/29 contradiction closes with a rationale-only text change in 23.
- `process_mode` of every node is a documented table, auditable by a test.

### Negative
- `GameClock` is an extra autoload and a mandatory injection in almost every
  system (accepted: `architecture.md` already lists it).
- Two clocks (`GameClock`, `RealClock`) exist; choosing the wrong one is a bug
  class. Mitigated by G-1/G-2 and the § D5 table.
- Banning `create_timer()` / `Timer` removes familiar engine conveniences.
- `max_frame_delta_s` makes game time drift from wall time on long hitches
  (accepted: no rule in the slice depends on wall time).
- Everything is provisional until the spike: stories in **Blocks** wait ~2 days.

### Neutral
- 28's pause handler exists in both variants but does nothing for tweens and
  particles in A.
- Game time is not persisted; on load, timers are re-derived from facts, as the
  GDDs already assume.

## Risks
- **Core-set FAIL (S1–S4, S9, S13)** → full B: +1 d and per-system adapter
  registrations. *Mitigation:* G-1/G-4/G-9 already isolate the change; the
  spike runs first, before any dependent story.
- **A forgotten `process_mode`** (e.g. a new `CanvasLayer` left inheriting) →
  UI frozen in pause or world running. *Mitigation:* G-7 and V-6 (tree-walk
  audit test).
- **A tween created with `get_tree().create_tween()`** escapes the bound-node
  pause. *Mitigation:* G-9 helper; CI grep for `get_tree().create_tween(`.
- **One-frame skew at O2** (a consumer read Δ before `pause()` that frame).
  *Mitigation:* deadlines; budget of one frame is below every tolerance in the
  GDDs (smallest is ±0.1 s).
- **4 instantiating while paused** in a future path. *Mitigation:* G-11 assert;
  V-5.
- **The S8 mechanism fails** → 23's per-player pause needs an alternative.
  *Mitigation:* owned by ADR-0008; AC-23-18 stays PV.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| menu-de-pausa.md (25) | TR-pause-001: Δ_juego = 0 from the opening frame, resumes on the exit frame; mechanism undecided (OQ 2, D25-28) | D1, D2: `GameClock.pause()` zeroes Δ in the same frame (O2); mechanism A with B fallback; closes 25 OQ 2 once the spike lands |
| menu-de-pausa.md (25) | TR-pause-002: UI, 6 deferred save, capture timer 8 s, volume sample, 5 retries in real time | D5 table, G-2, `RealClock`; § D2 `ALWAYS` rows; S3, S4, S9 |
| menu-de-pausa.md (25) | TR-pause-003: resolve 28 R22 / 29 R35 vs 23 D23-25; consumers 5, 23, 26, 28 | D3 reconciliation; D4 consumer list |
| menu-de-pausa.md (25) | R3, R5, R28, R30; AC-25-02, AC-25-50, AC-25-58, AC-25-62 (once-only notices, order) | D4 opening / closing / «Volver al título» / «Nueva partida» sequences |
| director-de-audio.md (23) | TR-audio-001: persistent node, `process_mode` always active | § D2: `AudioDirector` `ALWAYS`; G-8 |
| director-de-audio.md (23) | TR-audio-015, R41, D23-7, D23-25: own per-player pause, loops at −6 dB, sample never paused, no tree fallback, line clocks on game time | D3 (23 keeps its model; rationale text only), D5, S8, S9; per-player mechanism delegated to ADR-0008 |
| marco-de-puzles.md (9) | TR-puzzles-014: injectable `GameClock` for every framework timer; `SceneTreeTimer` / `create_timer` forbidden | D1, D6, G-1, G-3; `schedule()` / deadlines |
| caja-y-compartimentos.md (10) | TR-box-015: animations and watchers on game time; `AnimationPlayer` under pause unconfirmed (blocks AC-21) | Watchers on `GameClock` (G-1); animation freezing = S6 (A) or SB2 (B) |
| atmosfera-reactiva.md (28) | TR-atmos-018, R22, AC-28-16: freeze `Tween` and `GPUParticles3D`, resume without jumps | A: tree freezes (`PAUSABLE`), S5 and S7; B: 28's handler + adapter, SB1 and SB3 |
| shaders-y-efectos.md (29) | TR-shaders-017, R35, AC-21: envelopes on game clock; `Tween` pausable; no meaningful `TIME` | G-1, G-9, G-10; S5, S10 |
| subtitulos.md (26) | TR-subs-008, R25, OQ 8: own clocks on game time, frozen by «pausa abierta», not dependent on tree pause | 26 `ALWAYS`, clocks from `GameClock`; true in A and B |
| entrada-y-controles.md (1) | TR-input-005: blocking-context safety cap stops with pause | Cap on `GameClock` (§ D2 `InputRouter` row) |
| entrada-y-controles.md (1) | TR-input-008: game time stops, menu consumes the event, mouse released / recaptured, focus loss / pad disconnect open pause even in blocking transitions | Time: O2/C2. Event consumption, mouse and device signals: ADR-0006 (this ADR fixes `InputRouter` `ALWAYS` and S4) |
| jugador-en-primera-persona.md (2) | TR-player-015: speed, braking, interpolations, bob, gestures, transfers freeze and resume; `t` of F7/F9/F10 is game time | G-1, G-4; S11, S12; interpolation detail to ADR-0012 |
| control-de-acceso.md (8) | TR-access-012: all 8 timers on game time, stop with pause | G-1, `schedule()` |
| ordenador-correo-impresora.md (19) | TR-computer-009: `t_busqueda`, `t_impresion` 1.5 s, `t_tipeo_inactivo` 1.0 s on game time | G-1, `schedule()` / deadlines |
| llamada (22), director-de-escenas (21) | AC-25-09 / AC-22-11: 20 s wait at 12 s stays at 12 s after 30 s of pause | `CallWaitTimer` pattern on `GameClock`; V-3 |

TRs covered (15): TR-pause-001, -002, -003; TR-audio-001, -015;
TR-puzzles-014; TR-box-015; TR-atmos-018; TR-shaders-017; TR-subs-008;
TR-input-005, -008 (time part; rest ADR-0006); TR-player-015; TR-access-012;
TR-computer-009.

## Performance Implications
- **CPU**: `GameClock.advance()` once per frame: one clamp, one add, a peek at
  the schedule head; firing is O(k) for due entries. Insert is O(n) with
  n ≤ ~50 in the slice — negligible against a 16.6 ms frame (ADR-0019 owns the
  budget). In A, a paused tree skips world processing, so pause is cheaper than
  play.
- **Memory**: one autoload, one entry per scheduled timer (< 1 KB total).
- **Load Time**: none.
- **Network**: not applicable.

## Migration Plan

No code exists. Order: (1) spike in `prototypes/spike-pause/`; (2) update this
ADR with results and the selected variant; (3) implement `GameClock`,
`RealClock`, backends and unit tests in the code root (`src/core/clock/` ‡,
ADR-0009 fixes the path) before any system with a timer; (4) each system's
first story injects `GameClock` and declares its `process_mode` per § D2.

**Rollback plan**: if A misbehaves after implementation (a regression on an
engine patch), switch `Boot` to `NullPauseBackend` and register the affected
kinds with the `PauseAdapter` (§ D7). Gameplay code is untouched by design.

## Validation Criteria

- **V-1 (unit, `tests/unit/clock/`)**: `pause()` zeroes `delta()` in the same
  call; `now()` does not advance while paused; `pause()`/`resume()` idempotent
  per requester; two requesters: time resumes only after both release;
  `schedule()` never fires while paused; due entries fire in (due, handle)
  order; a callback that opens pause stops further firing that frame;
  `max_frame_delta_s` clamps; `reset_session()` clears.
- **V-2 (unit)**: `FakeRealClock` drives 25's F2 capture timer to 8 s while
  `GameClock` is paused.
- **V-3 (integration, `tests/integration/pause/`)**: AC-25-09 — call wait at
  12 s, 30 s of pause (real frames), still 12 s on resume; 6's deferred save
  completed during the pause.
- **V-4 (integration)**: notice order and multiplicity — one «pausa abierta»
  per opening, none on reject / already open / title Options; one «pausa
  cerrada» after context restore and `resume()`; «Volver al título» order T1–T6
  (AC-25-02, -50, -58, -62).
- **V-5 (integration)**: 4 refuses to instantiate while paused (G-11) and
  unloads while paused without orphans (S14 repeated in the real `Shell`).
- **V-6 (integration)**: tree-walk audit — every node in § D2 has the declared
  `process_mode`; no `WorldSlot` descendant is `ALWAYS`.
- **V-7 (CI)**: grep fails on `create_timer(`, `Timer.new(`,
  `get_tree().create_tween(`, `Engine.time_scale` in the code root.
- **V-8 (visual, `production/qa/evidence/`)**: AC-21 of 10, AC-28-16, AC-21 of
  29 observed in a pause/resume capture.

We will know this was right if: the spike's core set passes, V-1…V-7 pass in
CI, and no playtest report shows a timer advancing, a voice resuming over the
title, or a visible jump on resume.

## Spike Results (2026-11-10)

Run with Godot 4.7.2.stable.official.ed1daf0bf (same as the pin) from `prototypes/pause-spike/`; raw output in `prototypes/pause-spike/results-2026-11-10.md`, retained captures in `production/qa/evidence/pause-spike/`.

| Test | Claim | Result |
|---|---|---|
| S1 | `SceneTree.paused` stops `_process`/`_physics_process` of pausable nodes; resumes | **PASS** (0 calls in window) |
| S2 | `process_mode` values, inheritance, root default | **PASS** (INHERIT under PAUSABLE does not run; under ALWAYS runs) |
| S3 | `ALWAYS` node receives real, non-zero `delta` in pause | **PASS** (ratio 0.9996 vs wall clock) |
| S4 | Input/focus under pause | **PARTIAL**: simulated events reach ALWAYS probes (3/3) and not PAUSABLE ones (0). Keyboard/gamepad focus navigation and gamepad connect/disconnect still need a manual run with a window and a pad |
| S5 | `Tween` under pause | **PASS** with `TWEEN_PAUSE_BOUND` and `STOP`; `PROCESS` mode on a world node does not freeze (expected) |
| S6 | `AnimationPlayer` under pause | **PASS** (position constant, no method-track marks fired in pause) |
| S7 | `GPUParticles3D` under pause | **PASS** (0 differing bytes across paused frames; no density burst on resume by eye, retained capture) |
| S8 | `AudioStreamPlayer.stream_paused` hold and resume | **PASS** (position held, resumed at held position); audible check still manual |
| S9 | `ALWAYS` audio player keeps playing | **PASS** |
| S10 | Shader `TIME` in pause | **TIME keeps advancing during pause** (informative): shaders must use a phase uniform driven by `GameClock`, as ADR-0015 already decides |
| S11 | Camera interpolation under pause | **PASS** numeric part (identical origin over 120 paused frames, no jump on resume); visual pop still to be eyeballed |
| S12 | `CharacterBody3D` freezes, velocity kept | **PASS** (guard G-4 not load-bearing) |
| S13 | Bus drain while paused | **PASS** |
| S14 | `queue_free` while paused frees in 1 frame | **PASS** (0 orphans) |
| S15 | Autoload order and `process_priority` | **PASS** (lower value first) |
| S16 | `create_timer` / `Timer` in pause | **PASS** informative: `create_timer` defaults to `process_always = true`, and fires in pause; confirms the ban on `SceneTreeTimer` for game time |
| SB1, SB2 | Option B (tree not paused) `Tween.pause()` and `AnimationPlayer.pause()` / `speed_scale = 0` | **PASS** (B is viable as fallback) |
| SB3 | Option B particles `speed_scale = 0` | **PASS** (pixel part) |

**Decision rule check:** core tests S1, S2, S3, S9, S13 PASS; S4 is only partially verified. Presentation tests S5, S6, S7, S11 PASS. **Option A (tree paused + explicit `process_mode`) holds. Status stays `Proposed` until the manual S4 run (keyboard and gamepad focus under pause, pad disconnect) is recorded.**

New facts for the design: (1) shader `TIME` is not paused, so ADR-0015's `film_phase`/`GameClock` uniforms are required, not optional; (2) `SceneTree.create_timer` fires in pause by default, so the CI grep ban is load-bearing; (3) no need for guard G-4 on `CharacterBody3D`.

## Open Items

| # | Item | Owner |
|---|---|---|
| OI-1 | `architecture.md` § Required ADRs row ADR-0002: `WHEN_PAUSED` for 25 → `ALWAYS` (§ D2 note); § Module Ownership `GameClock` row: add `RealClock`, `schedule`/`cancel`/`deadline`; § Data Flow pause: add T1–T6 and the «Nueva partida» resume point | technical-director, at `/architecture-review` |
| OI-2 | GDD text changes after the spike: 23 D23-25 rationale (§ D3); 28 R22 "in A the tree freezes, handler is the B seam"; 29 R35 close ‡ with the S5 value; 26 OQ 8 close; 25 OQ 2 / D25-28 close; 28 OQ 12, 29 OQ 11 close | `/propagate-design-change` |
| OI-3 | **Resolved 2026-11-10 (ADR-0003 step 4: G-11 assert; 4 calls `reset_session()` before instantiating).** «Nueva partida» from pause: confirm in ADR-0003 that 4 instantiates only after 25's `resume()` (G-11) and who calls `GameClock.reset_session()` (proposed: 4, before instantiating) | ADR-0003 |
| OI-4 | **Resolved by ADR-0012 D2** (own interpolator, engine interpolation off; S11 runs as S-0012-F). Physics interpolation hold/reset on pause in partial or full B | ADR-0012 |
| OI-5 | Consumers of «pausa cerrada»: 3 lists 5, 23, 26, 28; `architecture.md` § Data Flow adds 24 (glyphs) and 5 has no use for it. Align GDD 3 / 24 / 25 table l. 447 | GDD 3 owner |
| OI-6 | Record verified pause behaviour in `docs/engine-reference/godot/modules/` (25 OQ 2) | engine-programmer, spike report |
| OI-7 | **Resolved: ADR-0009 D3 (`ctx.clock: GameClock`, `ctx.real_clock: RealClock`, built in Boot steps 0/3).** Injection of `GameClock` / `RealClock` via `ServiceContext` and backend choice in `Boot` | ADR-0009 |

## Related
- ADR-0001 Event bus and fact contract — carries «pausa abierta» / «pausa cerrada»; its NS-1 (`Callable.is_valid()` on freed owner) and NS-7 (main-loop order) also apply here.
- ADR-0003 Scene loading — `T_cap`, unload while paused, G-11, `reset_session()`.
- ADR-0006 Input — `InputRouter` `ALWAYS`, event consumption, device signals.
- ADR-0008 Audio — per-player pause (`stream_paused`, S8), volume sample.
- ADR-0009 Service composition — autoload #3 and injection.
- ADR-0012 Player / interpolation; ADR-0014 Atmosphere; ADR-0015 Shaders; ADR-0016 UI layers; ADR-0017 Scene director and call.
- `docs/architecture/architecture.md` § Required ADRs (ADR-0002), § Data Flow (Pausa), § Pausa — ADR-0002, QQ-06, QQ-17.
- `docs/architecture/tr-baseline-provisional.md` (TRs listed above).
- `design/gdd/menu-de-pausa.md` R1–R7, R28, R30, D25-16, D25-19, D25-27, D25-28, OQ 2; `design/gdd/director-de-audio.md` R41, R42, D23-7, D23-25, D23-28; `design/gdd/atmosfera-reactiva.md` R22, OQ 12; `design/gdd/shaders-y-efectos.md` R35, OQ 11; `design/gdd/subtitulos.md` R25, R27, OQ 8.

