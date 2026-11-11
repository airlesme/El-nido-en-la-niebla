# ADR-0014: Atmosphere — Lighting Budget, Light Envelopes, Flash Limiter, Rain and Delayed Reflection

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/VERSION.md` (pin 4.7, installed
4.7.2 in the cloud environment; developer editor version not recorded),
`docs/engine-reference/godot/modules/rendering.md` (last verified 2026-10-17),
ADR-0002, ADR-0003, ADR-0007, ADR-0009 and `adr-reconciliation-2026-11-10.md`.

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation:
autonomous`). Pending user confirmation for `Accepted`. Inputs: GDD 28
`atmosfera-reactiva.md`, GDD 30 `opciones-de-accesibilidad.md`.

## Summary

System 28 (Atmosphere) needs a rendering budget, a pause-safe way to animate
light energy, a single photosensitivity limiter whose units agree with GDD 30,
and an implementation for rain and the delayed reflection of `C02` that fits
≤ 1,0 ms GPU / ≤ 0,15 ms CPU on reference hardware that is not yet chosen
(QQ-04). Decided: 28 stays a scene node (ADR-0009 D11) under `WorldSlot`
(`PAUSABLE`); all light and rain envelopes are pure functions evaluated against
`GameClock.now()` (no `Tween`); flashes are counted in one unit (flash onsets
in a half-open 1000 ms window, integer game-time ms) by a local
`LightFlashLimiter` and then the global `FlashGuard` of ADR-0007; rain is one
`GPUParticles3D` per window; the reflection is a mirrored-position proxy fed by
`Player.pose_con_retardo(τ)`; no `LightmapGI`, no `AreaLight3D`, no HDR output,
fixed exposure, glow allowed (pre-tonemap since 4.6). Budgets are provisional
until spike S0b (30 s of corridor on reference hardware).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH — 4.6 glow/tonemap change and 4.7 rendering additions are post-cutoff; most light/particle/environment property behaviour used here is NOT SOURCEABLE (table below) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/rendering.md`; ADR-0002 § Engine API sourcing (NS-5, NS-7) |
| **Post-Cutoff APIs Used** | 4.6 "glow processes before tonemapping (screen blending)" and "AgX tonemapper: white point and contrast controls" (behavioural, `rendering.md` § 4.6); 4.6 "D3D12 default backend on Windows" (`rendering.md` § 4.6, affects profiling); 4.7 `AreaLight3D` and HDR output (both **excluded**, `rendering.md` § 4.7); 4.4 particles `.restart(keep_seed)` (`rendering.md` § 4.4, used only for deterministic rain restart) |
| **Verification Required** | Spike S0b (D12) and ADR-0002 spike S7 (particles under pause). Every NS row below is checked in S0b before AC-28-16 / AC-28-19 close |

### Engine API sourcing

Rule: engine behaviour is cited from `docs/engine-reference/`, never from
memory. Where the reference does not cover it, the row says so and the ADR does
not depend on it for correctness, only for cost or for a fallback.

| ID | Behaviour / API this ADR uses | Source | Checked in |
|---|---|---|---|
| — | Glow is processed **before** tonemapping, screen blending (4.6) | `rendering.md` § 4.6 Changes | S0b-6 (visual) |
| — | AgX tonemapper has white point and contrast controls (4.6) | `rendering.md` § 4.6 Changes | — |
| — | `AreaLight3D` exists (4.7) — not used | `rendering.md` § 4.7 Changes | — |
| — | HDR output exists on Windows (4.7) — disabled for the slice | `rendering.md` § 4.7 Changes | S0b-6 |
| — | D3D12 is the default backend on Windows since 4.6 | `rendering.md` § 4.6, § Rendering Backend Selection | S0b-1 (record backend) |
| — | Forward+ is the default renderer | `rendering.md` § Rendering Backend Selection | — |
| — | Post-processing via `Compositor` / `CompositorEffect` (28 adds none) | `rendering.md` § Post-Processing | — |
| — | Particles `.restart()` takes optional `keep_seed` (4.4) | `rendering.md` § 4.4 Changes | S0b-4 |
| — | `Time.get_ticks_msec()` (production `RealClock`) | ADR-0002 D1, `deprecated-apis.md` | — |
| NS-A1 | `Light3D.light_energy` write each frame, `shadow_enabled`, `visible = false` removing the light from Forward+ clustering cost | NOT SOURCEABLE — Light3D properties and cluster cost not covered by `docs/engine-reference/godot/modules/rendering.md` | S0b-2 |
| NS-A2 | `Environment` ambient light energy writable at run time; auto-exposure off by default; tonemap/glow/HDR-output property names | NOT SOURCEABLE — `Environment` / `CameraAttributes` properties not covered by `docs/engine-reference/godot/modules/rendering.md` | S0b-6 |
| NS-A3 | `GPUParticles3D` `amount`, `amount_ratio`, `speed_scale`, shadow casting off, draw pass mesh | NOT SOURCEABLE — `GPUParticles3D` properties not covered by `docs/engine-reference/godot/modules/rendering.md` (only `.restart(keep_seed)`) | S0b-4 |
| NS-A4 | `GPUParticles3D` freezes under a paused tree (= ADR-0002 NS-7) | NOT SOURCEABLE — particle pause not covered by `docs/engine-reference/godot/modules/rendering.md` | ADR-0002 S7 |
| NS-A5 | `ReflectionProbe` intensity property; fresnel on a transparent `StandardMaterial3D` | NOT SOURCEABLE — `ReflectionProbe` not covered by `docs/engine-reference/godot/modules/rendering.md` | S0b-5 |
| NS-A6 | `Light3D` `distance_fade_*` (fallback 4 of GDD 28 F8) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/rendering.md` | S0b-2 (only if needed) |
| NS-A7 | Per-system GPU timing (`RenderingServer` / `Performance` monitors, "Objects in frame") | NOT SOURCEABLE — profiler and monitors not covered by `docs/engine-reference/godot/modules/rendering.md` | S0b-1 (measurement method D9 avoids depending on it) |
| NS-A8 | Relative screen luminance is non-decreasing in light energy with fixed exposure and AgX (the property that makes the energy-space flash proxy conservative, D4) | NOT SOURCEABLE — tonemapper transfer curve not covered by `docs/engine-reference/godot/modules/rendering.md` | S0b-6 (luminance script) |
| NS-A9 | `Time.get_ticks_usec()` for CPU timing of 28 in debug builds | NOT SOURCEABLE — only `get_ticks_msec()` is in `deprecated-apis.md`; fallback: `get_ticks_msec()` over 60-frame batches | S0b-1 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (bus: notices and payload registry), ADR-0002 (`GameClock`, variant A pause, G-1/G-9/G-10, spike S7), ADR-0003 (rooms are not scene loads; «escena lista»), ADR-0005 (`atmosphere/atmosphere.json` registry slot and validation), ADR-0007 (`A11yConstants`, `FlashGuard`; amendment pending, OI-1), ADR-0009 (D11 scene node, `configurar`, `SubscriptionBag`, `ctx.scene.player`) |
| **Enables** | ADR-0012 (Player: contract of `pose_con_retardo(τ)` / `giro_acumulado()` and hand-light mechanism, TR-atmos-010), ADR-0015 (Shaders 29: `reflection_strength_max`, replacement of `rain_glass_material`, shared flash rule), ADR-0017 (Scene director 21: order vocabulary and parameters), ADR-0019 (reference hardware: closes the PV budgets) |
| **Blocks** | Epic «Atmósfera (28)» stories for light states, flicker, blackout, rain, reflection; S0b atmosphere prototype |
| **Ordering Note** | Implementable on ADR-0002 variant A before S7 passes (the only NS on the critical path is particle pause, NS-A4). Budgets stay PV until ADR-0019 fixes hardware (QQ-04) and S0b runs |

## Context

### Problem Statement

GDD 28 specifies the night-shift atmosphere: six `C03` corridor lights with a
flicker and a blackout, an Archive tube with ambient flicker, a reception tube
that flickers once, rain on three windows, and a once-per-game delayed
reflection in `C02`. It fixes budgets (TR-atmos-016/-017) and safety limits
(TR-atmos-005/-006, TR-a11y-010) but leaves to this ADR: how energy is
animated so that pause is correct, how the flash rule of 28 (energy-based,
"2 cycles/s") and of 30 (luminance-based, "3 flashes/s") are counted in one
unit, how the budgets are enforced and measured with no reference hardware,
and how rain and reflection are built. `architecture.md` § Required ADRs lists
ADR-0014 as HIGH risk with a mandatory spike (S0b) for milestones M3–M4.

### Current State

No code. Decided upstream and respected here:

- **ADR-0009 D11:** `Atmosphere` is a node at the root of `planta` and
  `recepcion` with one `AtmosphereZone` per room; not an autoload
  (TR-atmos-001 rejected as written). Rooms are children of one `planta`
  instance (ADR-0003), so walking between rooms never loads anything.
- **ADR-0002:** variant A (tree pause, `WorldSlot` `PAUSABLE`); `GameClock` is
  the only game-time source (G-1); `Tween` and `GPUParticles3D` pause
  behaviour is NOT SOURCEABLE (NS-5, NS-7); 28's «pausa abierta» / «pausa
  cerrada» handler is the seam for variant B (D3). Fallback SB1 explicitly
  names "tick-driven envelope on `GameClock` instead of `Tween` for 28/29
  (ADR-0014)".
- **ADR-0007 D9:** `A11yConstants` (code, not data) and `FlashGuard`
  (`RealClock`, `try_flash() -> bool`, ≤ `FLASH_MAX_PER_S` = 3 per
  `FLASH_WINDOW_MS` = 1000). OI-6 delegates to this ADR *which* effects count
  as a flash.
- **Reconciliation 2026-11-10:** G25 (GDD 28 DT-1 → scene node) pending in the
  GDD; no open ADR-to-ADR contradiction involving 28.

### Constraints

- Godot 4.7, GDScript, Forward+ (default renderer; D3D12 default on Windows).
- Art bible §9 and GDD 28 R23: no `LightmapGI`; lights are real-time.
- Reference hardware not fixed (QQ-04): every number in D9 is provisional (PV).
- Photosensitivity limits must be code constants with tests (DT-9, ADR-0007
  D9); a data typo must never raise them.
- 28 talks to 21 and 29 only through the bus (TR-atmos-002); it never writes
  facts or settings (TR-atmos-003).
- One programmer; the slice must ship a demo, so the design favours few
  moving parts and deterministic unit tests.

### Requirements

- ≤ 8 dynamic lights visible per view, ≤ 2 shadowed, ≤ 14 per loaded scene
  (TR-atmos-016/-017).
- GPU of 28 ≤ 1,0 ms; CPU ≤ 0,15 ms mean / 0,5 ms peak; textures ≤ 8 MB;
  overdraw ≤ 3 layers; 60 fps in 99 % of frames (TR-atmos-016) — PV.
- Blackout 0,4 s monotone (0,8 s reduced), restore 2,0 s monotone, ambient
  floor 0,06; flicker 3 × 0,15 s with 0,35 s pauses (F1, F4).
- Flash ≤ 2 cycles/s, pause ≥ 0,35 s, ≤ 3 flashes per 1 s, depth floor 0,40,
  surplus merged with a warning, priority blackout > `C03` > tube
  (TR-atmos-005/-006, TR-a11y-010).
- Pause freezes everything 28 shows and resumes without jumps (TR-atmos-018,
  AC-28-16).
- Rain: 3 windows, ≤ 200 per window, ≤ 500 total, 2-tri meshes, no shadows,
  no screen texture (TR-atmos-014/-015).
- Reflection: ≤ 400 tris, 1 draw call, 0 `SubViewport`, no negative scale,
  state machine F3, once per game (TR-atmos-009/-011/-012/-013).
- State volatile, rebuilt from facts and 21's resume orders (TR-atmos-003).

## Decision

### D1 — Placement and composition (inherits ADR-0009 D11)

`Atmosphere` (`src/presentation/atmosphere/atmosphere.gd`, `Node3D`) is a child
of the scene root of `planta` and `recepcion`, under `WorldSlot`, therefore
`PAUSABLE` by inheritance (ADR-0002 D2, G-7). It is configured last in the
ADR-0009 D4 order and subscribes before «escena lista», so 21's resume orders
always find a listener. One `AtmosphereZone` (`atmosphere_zone.gd`, `Node3D`)
per room (`despacho_vera`, `pasillo`, `archivo`, `sala_reuniones`,
`despacho_guardian`, `recepcion`) owns, via `%Unique` names in its own subtree,
its lights, window emitters and, for `pasillo`, the `C02` proxy.

All behaviour lives in four plain `RefCounted` classes with no engine calls,
so the unit suite needs no `SceneTree`:

| Class | Responsibility | Time source |
|---|---|---|
| `LightEnvelope` | One energy curve (F4 shapes: fall, flicker dip, pulse, monotone restore, jump) evaluated as `factor(t_ms)` | absolute game-time ms |
| `LightFlashLimiter` | 28-local rule: onset spacing, pause, depth floor, priority, merge + warning | game-time ms |
| `RainLevel` | `lluvia_nivel` per zone (F5), linear ramps between targets | game-time ms |
| `DelayedReflection` | `OFF/ENTRANDO/ACTIVO/SALIENDO`, τ(t) of F3, turn condition | game-time ms |

`Atmosphere` is the only node with `_process`; zones are passive registries.

### D2 — Light budget and how it is enforced

| Rule | Value | Enforcement |
|---|---|---|
| Lights visible per view | ≤ 8 (`OmniLight3D` / `SpotLight3D`, any owner, P2's beam included) | **Static**: `atmosphere.json` declares `zone_visibility` (rooms visible from each room through open doors/glass); test T-AT14 loads the scene and asserts, for each room, Σ enabled lights of its visible set ≤ 8 |
| Shadowed lights | ≤ 2 **per loaded scene instance** (statically, not per view) | `shadow_enabled` only on lights listed in `shadow_allowlist` (`V06`, P2 beam); T-AT14 asserts every other `Light3D` has it off and the list has ≤ 2 entries. Stronger than "≤ 2 visible" and needs no frustum test |
| Lights enabled per loaded scene | ≤ 14 with `visible = true` at any time | **Zone activation**: when the player enters a room (`AtmosphereZone` trigger volume), 28 sets `visible = true` on the lights of that room's visible set and `false` on all others (NS-A1). T-AT15 walks every room transition and asserts ≤ 14 |
| Lights at energy 0 | `visible = false` once a blackout fall completes; `visible = true` the frame a restore starts | Envelope end callback |
| Light types | `OmniLight3D`, `SpotLight3D` only. **No `AreaLight3D`** (4.7; cost not sourced), no `DirectionalLight3D` indoors | T-AT14 |
| Global illumination | No `LightmapGI` (art bible §9), no `VoxelGI`, no SDFGI, no SSR (DT-3); one `ReflectionProbe` per room that needs it | T-AT14 node-type scan |

28 owns the **whole** light budget of a scene, including P2's `SpotLight3D`
(TR-atmos-017): puzzle lights are registered in the zone as read-only for 28,
so they are counted but never driven. The hands' light (TR-atmos-010) is
decided by ADR-0012; if it is a `Light3D` it counts inside these numbers.

**Contradiction resolved (C1).** GDD 28 F8 and TR-atmos-016 say "≤ 14 loaded
per scene" and assume six scenes. Under ADR-0009 D11 / ADR-0003 the five
`planta` rooms are **one** scene instance; their authored lights add up to
about 15–17 (6 `C03` + `V06` + `V02` + B lamps, auxiliary omni and P2 beam +
archive tube + D lamps and window light). Decision: the cap of 14 applies to
**enabled** lights (`visible = true`), enforced by zone activation; the
authored count per instance is capped at 24 as a sanity limit. GDD 28 F8's
row must be reworded (OI-3).

### D3 — Light energy is a pure envelope on `GameClock`, not a `Tween`

Every light change of 28 (blackout, restore, flicker dip, tube flicker, pulse,
ambient floor) is a `LightEnvelope` started at `t0_ms = roundi(clock.now() *
1000)` and **evaluated** each frame as `E = E_nom · factor(now_ms)`. Nothing
integrates engine `delta` (ADR-0002 G-1). Rationale:

1. **Pause is correct by construction in A and in B.** `GameClock.now()`
   freezes while paused, so the envelope freezes; at resume it continues
   from the same point with the rest of its duration (GDD 28 R22). NS-5 / S5
   (`Tween` pause mode) leaves 28's critical path; ADR-0002's SB1 fallback
   ("tick-driven envelope on `GameClock` instead of `Tween` for 28/29") is
   simply adopted as the design.
2. **The limiter must know the exact shape.** Onsets, recovery ends and depth
   are fields of the envelope, so `LightFlashLimiter` reasons on data, not on
   a running animation.
3. **Determinism for AC-28-01/-03/-05** (±0,02–0,05 s): tests drive
   `GameClock.advance()` and read `factor()`; no frame loop.
4. **Idempotence (R6):** a repeated `LUCES_APAGON` whose target equals the
   current or pending target is a no-op; a duration-0 order is a `jump`
   envelope (R21, not a flash).
5. **Cost:** ≤ 14 envelope evaluations + writes per frame; finished envelopes
   are dropped, so in steady state 28 writes nothing.

Colour never changes during an envelope (R7). `FxTween.make()` (ADR-0002 G-9)
is not used by 28. **Deviation from GDD 28 R7 and TR-atmos-008/-018** (they
say `Tween`): recorded as OI-2; no timing or limit changes.

### D4 — One flash unit, two limiters (closes ADR-0007 OI-6)

**Unit.** A *flash* is 30 R24's: a pair of opposite luminance changes. Counted
as **one onset** (the instant the first change starts), timestamped in
integer milliseconds, in a **half-open sliding window `[t − 1000, t)`**. Both
limiters, AC-28-02, AC-28-21 and AC-30-13 count this unit. Integer ms removes
the "exactly 2,0 Hz, no margin" float risk named in GDD 28 R11a.

**Which effects of 28 are flash candidates (runtime proxy of 30 R24).** 28
cannot measure screen luminance or field-of-view area at run time. It uses a
**conservative energy-space proxy**:

- candidate = any envelope whose shape is **non-monotone** (down-then-up or
  up-then-down) and whose depth `|1 − f|` ≥ `A11yConstants.FLASH_LUMA_DELTA`
  (0,10) of nominal energy, on any light group of a zone;
- the area criterion (> 25 %) is **assumed met** for every candidate (no
  exemption for small lights);
- **not** candidates: monotone envelopes (blackout fall, restore, rain
  ramps), duration-0 jumps, and the ambient-floor change.

So the `C03` flicker (depth 0,60, or 0,35 reduced), the tubes (0,60 / 0,35)
and the resolution pulse (+0,25 / +0,15) are all candidates; `reducir_*`
lowers depth but never exempts an effect. The proxy over-counts as long as
screen luminance is non-decreasing in energy (NS-A8), which D5 protects by
fixing exposure; S0b-6 verifies it with the per-frame luminance script.

**Threshold vs floor — not the same quantity.** `FLASH_LUMA_DELTA` (0,10) is
the *classification* threshold (is this a flash?). `LIGHT_FLICKER_DEPTH_FLOOR`
(0,40 of nominal) is an *aesthetic/safety floor* (how deep may a flicker go?,
R11e, art bible §8.7). Both are fractions of nominal energy inside 28 and are
never compared to each other.

**Layer 1 — `LightFlashLimiter` (28, game-time ms).** For each candidate, in
priority order blackout > `C03` > tube/pulse (the lower one is dropped if they
overlap, R11):

- (a) onset spacing ≥ `1000 / LIGHT_FLICKER_MAX_HZ` = 500 ms since the
  previous accepted onset of any 28 candidate;
- (b) gap ≥ `LIGHT_FLICKER_MIN_PAUSE_S` = 350 ms from the previous recovery
  end to this onset;
- (c) depth clamped: flicker/tube `f` ≥ `LIGHT_FLICKER_DEPTH_FLOOR` (0,40);
  pulses (upward) are not clamped;
- (d) a candidate violating (a) or (b) is **dropped** (merged), never
  delayed, with a `logger` warning `ATMOS_FLASH_MERGED` ‡;
- data `pausa_min_s` < 0,35 is raised to 0,35 at load, with a warning.

With (a), any half-open 1000 ms window contains **at most 2** onsets of 28:
2 flashes/s, which is GDD 28's "2 cycles/s" and is strictly inside 30 R18's
3/s. The GDD default (3 × 150 ms dips, 350 ms pauses, period 500 ms) passes
exactly: onsets at 0, 500, 1000 ms; windows `[0,1000)` and `[500,1500)` each
hold 2.

**Layer 2 — `FlashGuard.try_flash()` (ADR-0007, global, `RealClock`).** Called
once per candidate **after** layer 1 accepts it, at onset. If it returns
`false` (21, 24 or 29 already used the 3/s budget), the candidate is dropped
like (d). This is the only cross-system limiter; 28 does not reimplement it.

**Clock interaction.** Layer 1 runs on game time (frozen in pause: nothing of
28 flashes while paused). `FlashGuard` runs on real time, so a pause longer
than 1 s empties its window. Accepted: the pause veil sits between the two
halves of any interrupted sequence, so the on-screen sequence is not
continuous; the video check AC-30-13 covers both cases.

**Contradiction resolved (C2) — identifier `FLASH_MAX_HZ`.** TR-atmos-005 /
GDD 28 R9 use `FLASH_MAX_HZ = 2,0` (lights), while ADR-0007's
`A11yConstants` comments `FLASH_MAX_PER_S = 3` as `"FLASH_MAX_HZ"`. One name
with two values is a defect waiting to happen. Decision: `FLASH_MAX_HZ` is
retired. Canonical names: `FLASH_MAX_PER_S` (3, global, 30),
`LIGHT_FLICKER_MAX_HZ` (2,0), `LIGHT_FLICKER_MIN_PAUSE_S` (0,35) — both already
in `A11yConstants` — plus a new `LIGHT_FLICKER_DEPTH_FLOOR: float = 0.40`
(TR-atmos-005's `FLASH_DEPTH_FLOOR`). The constants stay in ADR-0007's file;
the amendment is OI-1 (not applied by this ADR). 28 must not define its own
copies.

**Contradiction noted (C3) — AC-28-02 vs R11a.** AC-28-02 asserts "≤ 3 per
1 s"; with layer 1 the true maximum is 2. AC-28-02 stays valid (≤ 3 holds) but
T-AT05 asserts ≤ 2, and GDD 28 should tighten the AC (OI-3).

### D5 — `WorldEnvironment`, tonemap, glow, exposure

- **One `WorldEnvironment` per game scene** (`planta`, `recepcion`), a child
  of the scene root, not per room. The `Environment` resource lives in
  `assets/` and is authored by the art director.
- **Runtime writers:** only 28, and only the ambient light energy for the
  blackout floor (`ambiente_apagon` 0,06 / 0,10 reduced) via a monotone
  `LightEnvelope` (NS-A2). Nobody writes tonemap, glow or exposure at run time.
- **Tonemap:** AgX (4.6 white point and contrast controls, `rendering.md`
  § 4.6), fixed per build; values are art direction.
- **Glow:** allowed. Since 4.6 it is processed **before** tonemapping with
  screen blending (`rendering.md` § 4.6): the bloom of a bright `C03` core
  grows and shrinks with energy before compression, enlarging the visual area
  of a flicker. This is why D4 assumes the area criterion is met. Glow
  intensity and threshold are art data; S0b-6 captures blackout and flicker
  with glow on. Constraint from ADR-0015 OI-1(a): the shipped glow threshold
  **must** be ≥ 1,0, or ADR-0015's SH5 pass is re-run with the shipped value.
- **Exposure:** fixed; **no auto-exposure** in the game scenes. Auto exposure
  would rescale luminance after a blackout and could turn a monotone change
  into a flash, breaking D4's proxy.
- **HDR output (4.7): disabled for the slice.** 30 R24 is defined on relative
  luminance of SDR content and AC-30-13 analyses SDR video; HDR output changes
  the range the threshold is measured against. Re-evaluate after the slice.
- No `Compositor` effects from 28 (any belong to 29, ADR-0015).

### D6 — Rain: `GPUParticles3D` per window + glass shader on game time

- One `GPUParticles3D` per visible window (`B`, `D`, `R03`), emission box the
  size of the window, `amount` ≤ 200 each (`n_max_ventanal`), ≤ 500 visible in
  total; 2-triangle quad draw pass; shadow casting off; additive or
  alpha-scissor material, no sorted alpha (NS-A3).
- `RainLevel` per zone gives `lluvia_nivel` ∈ [0, 1] (F5: `base_zona` from
  23's `perfil_dB`, order multipliers, linear ramps). 28 maps it each frame to
  the emitter's emission ratio (`amount_ratio` ‡, NS-A3) and to the glass
  shader's `densidad`. Fallback if that property is absent or restarts the
  system: `emitting = false` below 0,05 with a fixed `amount` (S0b-4 decides).
- Determinism: emitters use a fixed seed and `restart(true)` (`keep_seed`,
  `rendering.md` § 4.4) when a scene is (re)built.
- **Glass** `rain_glass.gdshader` (spatial, transparent, blend mix, two 512²
  noise layers, no `hint_screen_texture`, DT-11). Its scroll phase is a
  uniform `u_phase` fed from `GameClock.now()` (ADR-0002 G-10), never `TIME`,
  so it freezes in pause by construction.
- `reducir_movimiento`: particle speed scale ×0,5 (NS-A3) and `u_speed` ×0,5,
  read on «ajustes aplicados».
- Blackout: `RainLevel` → `lluvia_apagon` in `d_lluvia_apagon` (0,4 s, the same
  datum as 23) from the frame the order arrives; `LLUVIA_VUELVE` 2,0 s;
  `LLUVIA_CESA` 6,0 s (AC-28-12).
- Over-budget ladder (GDD 28 F8) is data-only: distance scaling of emission
  from 6 m, one glass layer, then light `distance_fade` (NS-A6).
- Pause: particles are frozen by the tree (variant A, NS-A4 / S7). In variant
  B, 28's «pausa abierta» handler sets the emitters' speed scale to 0 and back
  (ADR-0002 SB3). The handler exists in both variants (ADR-0002 D3).

### D7 — Delayed reflection: mirrored-position proxy, no viewport

- `C02` is a transparent glass (fresnel + `ReflectionProbe`, NS-A5) in front of
  a minimal mirrored room. The proxy `MeshInstance3D` (≤ 400 tris, 1 draw call,
  no face) lives behind it. **No `SubViewport`, no mirrored camera, no
  negative scale, no `CULL_FRONT`** (DT-3, DT-13).
- Each frame **while the player is in `pasillo`** and not paused, 28 reads
  `τ = reflection.tau_s(now_ms)`, calls `player.pose_con_retardo(τ)` and
  applies F2 (`p' = p − 2((p − p0)·n)n`, yaw from the reflected forward).
  Outside `pasillo` the proxy is hidden and not updated.
- `DelayedReflection` implements F3 (smoothstep τ in `ENTRANDO`, constant in
  `ACTIVO`, smoothstep down in `SALIENDO`), the turn exit
  (`giro_acumulado() ≥ umbral_giro_deg` in `T_giro`, and ≥ `t_activo_min_s`
  active), the 3,0 s timeout, `retardo ≤ T_hist` clamp + warning, and a
  once-per-game latch (21 R12 owns the fact; 28 also refuses a second run).
- `reducir_movimiento` (read on each trigger): two proxies (τ = 0 and τ = 0,6)
  cross-faded by alpha over 0,5 s in / 0,35 s out. Two draw calls only during
  the fade; still 0 viewports.
- `pose_con_retardo(τ)` must index the Player's history by **game time**, so a
  pause does not open a hole in the buffer: contract for ADR-0012 (OI-4).
- The `ReflectionProbe` of `sala_reuniones` (for `B04`, no delay) is set by 28
  to intensity `min(data, reflection_strength_max)`; the cap is published by
  29 as data (ADR-0015). The intensity cap is the knob; the acceptance
  criterion is ADR-0015 D2's **measured** `ΔL_refl ≤ 0,045` on the film —
  28 does not read 0,15 as the only test (ADR-0015 OI-1(b)). 28 never touches `mat_glass_memo`, and only `C02` is
  in group `reflejo_retardado` (TR-atmos-013, AC-28-11).

### D8 — Pause behaviour (TR-atmos-018, AC-28-16)

| What 28 shows | Frozen by | Variant A | Variant B |
|---|---|---|---|
| Light energy, ambient floor | `GameClock.now()` frozen (D3) | yes | yes |
| Rain level, glass phase | `GameClock.now()` frozen (D6) | yes | yes |
| Reflection τ and proxy | `_process` returns early when `clock.is_paused()`; τ from game time | yes | yes |
| Particles | tree pause (NS-A4, S7) | yes | 28's handler, speed scale 0 (SB3) |
| Flash limiter window | game-time ms (layer 1) | frozen | frozen |
| `FlashGuard` window | real time (ADR-0007) | runs | runs |

- 28 subscribes to «pausa abierta» / «pausa cerrada» (never to
  `GameClock.paused_changed`, ADR-0002 G-6). In A the handler only records
  the state for the debug overlay; in B it drives SB3.
- No order is lost during pause: bus handlers still run (ADR-0002 NS-13). An
  order received while paused starts its envelope at the frozen `now()`; it
  becomes visible on resume. This is the only consequence and it is correct.
- AC-28-16 now depends on GameClock (unit-testable, T-AT09) plus S7 for
  particles; it no longer depends on S5.

### D9 — Performance budget (all PV until ADR-0019 and S0b)

| Budget | Value | Status | Measured by |
|---|---|---|---|
| GPU of 28 | ≤ 1,0 ms per frame at 1080p, including its lights, particles, glass and proxy; excluding P2's beam | PV (QQ-04) | S0b differential capture: frame GPU time with the 28 subtree enabled minus disabled, same camera path; GPU capture tool external to Godot (PIX / RenderDoc, D3D12 default backend recorded) — avoids NS-A7 |
| CPU of 28 | ≤ 0,15 ms mean, ≤ 0,5 ms peak | PV | debug-only scope timer around `Atmosphere._process` (NS-A9) |
| Lights | ≤ 8 visible, ≤ 2 shadowed, ≤ 14 enabled | Hard (D2) | T-AT14/-15 (static) |
| Particles | ≤ 500 visible, ≤ 200 per window | Hard (data clamp) | validator + T-AT11 |
| Textures of 28 | ≤ 8 MB (2 × 512² noise + gradients) | PV | import report |
| Overdraw at windows | ≤ 3 alpha layers per pixel | PV | overdraw view in S0b |
| Proxy | 1 draw call (2 in a reduced-motion fade), ≤ 400 tris, 0 `SubViewport` | Hard | T-AT13 static scan |
| Frame | 60 fps in 99 % of frames (16,6 ms) | PV | S0b frame-time log |

CPU estimate (not a measurement): per frame ≤ 14 envelope evaluations, ≤ 3
rain ratios, one `pose_con_retardo` call and F2 when in `pasillo`; no
allocations in `_process` (pre-sized arrays). Expected well under 0,05 ms on
any desktop CPU; the 0,15 ms budget leaves margin for GDScript overhead.

### D10 — Data, resources and failure

- `assets/data/atmosphere/atmosphere.json` (ADR-0005 registry slot): `zone_profiles`
  (nominal energies, `f_*`, durations, `base_zona` derivation constants),
  `zone_visibility`, `shadow_allowlist`, `seed_archivo`, material paths,
  `reflection` block (`p0`, `n`, timings). **Invalid file → `ctx.fatal`**
  (`DATOS_ESCENA_INVALIDOS`, ADR-0009 D8 rule 10); ADR-0005's "may soften" is
  **not** taken: an atmosphere with wrong numbers is worse than a clear load
  failure in a demo build, and the validator runs at boot (ADR-0005 level B).
- Values outside safety constants (`pausa_min_s` < 0,35, `f_parpadeo` < 0,40,
  `n_max_ventanal` > 200, Σ > 500) are **clamped with a warning**, not fatal:
  the constants are the guarantee (DT-9), data cannot bypass them.
- Material resources (`rain_glass_material`, `mirror_glass_material`,
  `rain_particles_material`) are loaded with `load()` in `configurar()`
  (≤ 1 MB total); missing → built-in default material + `logger` error, not
  fatal (TR-atmos-019, GDD 28 R24).

### D11 — Orders, rebuild and determinism

- 21's orders arrive as bus notices (vocabulary `LUCES_PARPADEO`,
  `LUCES_APAGON`, `LUCES_RESTAURAR`, `LLUVIA_REALCE`, `LLUVIA_CESA`,
  `LLUVIA_VUELVE`, `REFLEJO_RETARDADO`; notice name and payload keys ‡,
  ADR-0001 registry / ADR-0017). Executed in the receiving frame, idempotent;
  unknown order → warning, no state change (R6, AC-28-22).
- Resolution pulses consume `EV_PUZZLE_SOLVED_<ID>` (DT-18), cosmetic only.
- Rebuild (TR-atmos-003, R21): on «escena lista» 28 reads facts once
  (`caja_completa`, `llamada_completada`) and sets `NORMAL`; 21's resume
  order `LUCES_APAGON` with duration 0 produces `jump` envelopes (no flash,
  no limiter call). Transients are never resumed.
- Determinism: the Archive tube schedule is precomputed from `seed_archivo`
  (20261109) with a local `RandomNumberGenerator` seeded once; two flickers
  per 20 000 ms with ≥ 350 ms between them (TR-atmos-020). Reception's tube
  flickers once on «escena lista», through the limiter.

### D12 — Spike S0b: 30 s of corridor on reference hardware

Owner engine-programmer; precondition: ADR-0019 names the reference machine
(QQ-04) — until then S0b runs on the developer machine and its numbers are
labelled "non-reference".

| Step | Scenario | Pass criterion | If it fails |
|---|---|---|---|
| S0b-1 | 30 s scripted walk X = 3 → 23 in `pasillo`, rain on, 6 `C03`, `C02` reflection active, `LUCES_PARPADEO` at 10 s; record backend (D3D12/Vulkan), resolution 1080p | 99 % of frames ≤ 16,6 ms; CPU of 28 mean ≤ 0,15 ms, peak ≤ 0,5 ms | Apply F8 ladder in order; re-run |
| S0b-2 | Same, GPU differential (28 on/off) | ≤ 1,0 ms; confirm `visible = false` removes a light's cost (NS-A1) | Ladder steps 3–4 (NS-A6); escalate budget to ADR-0019 |
| S0b-3 | Light audit at each camera stop | ≤ 8 visible, ≤ 2 shadowed, ≤ 14 enabled | Fix `zone_visibility` data |
| S0b-4 | Rain level 1,0 → 0 → 1,0 ramps | No restart pop; `amount_ratio` or fallback chosen (NS-A3); seed stable | Fallback of D6 |
| S0b-5 | `C02` glass with probe and proxy | Reads as reflection; fresnel works on transparent glass (NS-A5); 1 draw call | Opaque proxy + fake fresnel in shader |
| S0b-6 | Capture 10 s of flicker, blackout, restore, tube with glow on, fixed exposure, SDR | Per-frame luminance script (`tools/`, AC-28-21): ≤ 3 flashes per 1 s window (expected 2); luminance non-decreasing in energy (NS-A8); blackout and restore not counted | Lower glow; if NS-A8 fails, make the proxy count monotone changes > 0,10 within 1 s as half-flashes |
| S0b-7 | ADR-0002 S7 run with the rain emitters | Identical frames while paused, no burst on resume | ADR-0002 SB3 |

### Architecture Diagram

```text
 bus (GameState, ADR-0001)                      Settings (6)      GameClock      FlashGuard (ADR-0007)
  │ orders of 21, EV_PUZZLE_SOLVED_*,            │ reducir_*        │ now()/paused   │ try_flash()
  │ «pausa abierta/cerrada», «escena lista»      │                  │                │
  ▼                                              ▼                  ▼                ▼
 ┌───────────────────────── Atmosphere (scene node, PAUSABLE, configured last) ─────────────────────┐
 │  order router ─► LightFlashLimiter ─► LightEnvelope[]  ─┐                                        │
 │                                       RainLevel[zone]   ├─► _process(): if paused → return       │
 │                                       DelayedReflection ┘     write light_energy / visible       │
 │                                                                write emission ratio, u_phase      │
 │                                                                pose_con_retardo(τ) → F2 → proxy   │
 └──────────────┬───────────────────────────────┬───────────────────────────┬───────────────────────┘
                ▼                               ▼                           ▼
   AtmosphereZone × 6 (lights,          WorldEnvironment (1 per      Player (2) via ctx.scene.player
   emitters, glass, probe, proxy)       scene; ambient energy only)  pose_con_retardo, giro_acumulado
```

### Key Interfaces

‡ = name or signature owned by another ADR, or to be confirmed when that ADR
is written. Files under `src/presentation/atmosphere/`.

| Interface | Kind | File | Notes |
|---|---|---|---|
| `Atmosphere` | `Node3D` | `atmosphere.gd` | `configurar(ctx)`; no public gameplay API (ADR-0009 D11: nobody calls it). Debug: `debug_snapshot() -> Dictionary` |
| `AtmosphereZone` | `Node3D` | `atmosphere_zone.gd` | `zone_id`, `lights() -> Array[Light3D]`, `driven_lights()`, `emitters()`, `glass()`, `probe()`; passive |
| `LightEnvelope` | `RefCounted` | `light_envelope.gd` | `factor(now_ms) -> float`, `is_done(now_ms)`, `is_flash_candidate()`, `onset_ms`, `recovery_end_ms` |
| `LightFlashLimiter` | `RefCounted` | `light_flash_limiter.gd` | `admit(env, priority, now_ms) -> bool`; injected `FlashGuard`, `LogSink` |
| `RainLevel` | `RefCounted` | `rain_level.gd` | `set_target(level, dur_ms, now_ms)`, `value(now_ms)` |
| `DelayedReflection` | `RefCounted` | `delayed_reflection.gd` | `trigger(retardo_s, dur_s, reduced, now_ms) -> bool`, `tau_s(now_ms)`, `crossfade_alpha(now_ms)`, `update_turn(deg_in_window, now_ms)` |
| `AtmosphereProfile` | `RefCounted` | `atmosphere_profile.gd` | Parsed, clamped `atmosphere.json` |
| `PlayerPoseSource` ‡ | port | ADR-0012 | `pose_con_retardo(tau_s: float) -> Transform3D`, `giro_acumulado(window_s: float) -> float` |

### Pseudocode (typed GDScript, illustrative)

```gdscript
# src/presentation/atmosphere/light_envelope.gd
## One energy curve. Pure: no engine calls. Times are game-time ms.
class_name LightEnvelope extends RefCounted

enum Shape { FALL, RESTORE, DIP, PULSE, JUMP }

var shape: Shape
var onset_ms: int
var fall_ms: int          # DIP: 50 / PULSE: 300 / FALL: d_apagon / RESTORE: d_restaurar
var hold_ms: int          # DIP: 0
var rise_ms: int          # DIP: 100 / PULSE: 700
var from_f: float         # factor of E_nom at onset
var to_f: float           # target (FALL/RESTORE/JUMP) or extreme (DIP/PULSE)

var recovery_end_ms: int:
	get: return onset_ms + fall_ms + hold_ms + rise_ms

## Non-monotone and deep enough to count as a flash (D4).
func is_flash_candidate() -> bool:
	if shape != Shape.DIP and shape != Shape.PULSE:
		return false
	return absf(to_f - from_f) >= A11yConstants.FLASH_LUMA_DELTA

func factor(now_ms: int) -> float:
	var t: int = now_ms - onset_ms
	match shape:
		Shape.JUMP:
			return to_f
		Shape.FALL:      # F4, smoothstep, monotone
			return lerpf(from_f, to_f, _smooth(t, fall_ms))
		Shape.RESTORE:   # F4, linear, monotone
			return lerpf(from_f, to_f, _lin(t, fall_ms))
		_:               # DIP / PULSE: out, hold, back
			if t < fall_ms:
				return lerpf(from_f, to_f, _lin(t, fall_ms))
			if t < fall_ms + hold_ms:
				return to_f
			return lerpf(to_f, from_f, _lin(t - fall_ms - hold_ms, rise_ms))

func is_done(now_ms: int) -> bool:
	return now_ms >= recovery_end_ms

static func _lin(t: int, d: int) -> float:
	return 1.0 if d <= 0 else clampf(float(t) / float(d), 0.0, 1.0)

static func _smooth(t: int, d: int) -> float:
	var x: float = _lin(t, d)
	return x * x * (3.0 - 2.0 * x)
```

```gdscript
# src/presentation/atmosphere/light_flash_limiter.gd
## 28-local photosensitivity rule (D4 layer 1) + global FlashGuard (layer 2).
class_name LightFlashLimiter extends RefCounted

enum Priority { BLACKOUT = 3, C03 = 2, TUBE = 1, PULSE = 1 }

const NO_ONSET: int = -1_000_000
var _min_spacing_ms: int = roundi(1000.0 / A11yConstants.LIGHT_FLICKER_MAX_HZ)   # 500
var _min_pause_ms: int = roundi(A11yConstants.LIGHT_FLICKER_MIN_PAUSE_S * 1000.0) # 350

var _guard: FlashGuard
var _log: LogSink
var _last_onset_ms: int = NO_ONSET
var _last_recovery_end_ms: int = NO_ONSET
var _active_priority: int = 0

func _init(guard: FlashGuard, log_sink: LogSink) -> void:
	_guard = guard
	_log = log_sink

## Clamps depth, then admits or drops (merges) the envelope. Never delays it.
func admit(env: LightEnvelope, priority: Priority, now_ms: int) -> bool:
	if not env.is_flash_candidate():
		return true                                   # monotone / jump: not a flash
	if env.shape == LightEnvelope.Shape.DIP:
		env.to_f = maxf(env.to_f, A11yConstants.LIGHT_FLICKER_DEPTH_FLOOR)  # OI-1
	var busy: bool = now_ms < _last_recovery_end_ms
	if busy and priority <= _active_priority:
		return _drop(&"overlap_lower_priority", env)
	if env.onset_ms - _last_onset_ms < _min_spacing_ms:
		return _drop(&"spacing", env)
	if env.onset_ms - _last_recovery_end_ms < _min_pause_ms:
		return _drop(&"pause", env)
	if not _guard.try_flash():                        # global 3/s, RealClock
		return _drop(&"flash_guard", env)
	_last_onset_ms = env.onset_ms
	_last_recovery_end_ms = env.recovery_end_ms
	_active_priority = priority
	return true

func _drop(reason: StringName, env: LightEnvelope) -> bool:
	_log.line(&"warning", "ATMOS_FLASH_MERGED %s onset=%d" % [reason, env.onset_ms])
	return false
```

```gdscript
# src/presentation/atmosphere/atmosphere.gd (excerpt)
## System 28. Scene node (ADR-0009 D11). Only node of 28 with _process.
class_name Atmosphere extends Node3D

var _clock: GameClock
var _state: GameState
var _settings: Settings
var _player: Player                      # pose_con_retardo / giro_acumulado (ADR-0012 ‡)
var _log: LogSink
var _profile: AtmosphereProfile
var _limiter: LightFlashLimiter
var _reflection: DelayedReflection
var _zones: Dictionary[StringName, AtmosphereZone] = {}
var _envelopes: Dictionary[Light3D, LightEnvelope] = {}   # one live envelope per light
var _nominal: Dictionary[Light3D, float] = {}
var _rain: Dictionary[StringName, RainLevel] = {}
var _current_zone: StringName = &""
var _subs := SubscriptionBag.new()

func configurar(ctx: ServiceContext) -> void:
	if not ctx.require(&"atmosphere", [&"state", &"clock", &"settings", &"content", &"scene.player"]):
		return
	_clock = ctx.clock
	_state = ctx.state
	_settings = ctx.settings
	_player = ctx.scene.player
	_log = ctx.logger
	_profile = AtmosphereProfile.from_catalog(ctx.content, ctx.fatal, _log)   # D10
	_limiter = LightFlashLimiter.new(ctx.a11y_flash_guard, _log)              # injection point ‡ (OI-5)
	_reflection = DelayedReflection.new(_profile.reflection, _log)
	for zone: AtmosphereZone in _collect_zones():
		_zones[zone.zone_id] = zone
		for light: Light3D in zone.driven_lights():
			_nominal[light] = _profile.nominal_energy(zone.zone_id, light.name)
	_subs.notice(_state, &"orden_atmosfera", _on_order)          # ‡ ADR-0001/0017
	_subs.notice(_state, &"pausa_abierta", _on_pause_opened)
	_subs.notice(_state, &"pausa_cerrada", _on_pause_closed)
	_subs.notice(_state, &"ajustes_aplicados", _on_settings)
	_subs.notice(_state, &"escena_lista", _on_scene_ready)

func _exit_tree() -> void:
	_subs.release_all()

func _now_ms() -> int:
	return roundi(_clock.now() * 1000.0)

func _process(_delta: float) -> void:
	if _clock.is_paused():
		return                                  # D8: nothing of 28 advances
	var now_ms: int = _now_ms()
	for light: Light3D in _envelopes.keys():
		var env: LightEnvelope = _envelopes[light]
		light.light_energy = _nominal[light] * env.factor(now_ms)     # NS-A1
		if env.is_done(now_ms):
			if env.shape == LightEnvelope.Shape.FALL and env.to_f <= 0.001:
				light.visible = false           # D2; RESTORE sets visible = true at its start
			_envelopes.erase(light)
	for zone_id: StringName in _rain:
		_zones[zone_id].apply_rain(_rain[zone_id].value(now_ms))      # ratio + u_phase
	_zones[&"pasillo"].set_glass_phase(_clock.now())
	if _current_zone == &"pasillo":
		_update_reflection(now_ms)

func _start_dip_sequence(zone_id: StringName, times: int, f: float, now_ms: int) -> void:
	var t: int = now_ms
	for i: int in times:
		for light: Light3D in _zones[zone_id].driven_lights():
			var env := LightEnvelope.new()
			env.shape = LightEnvelope.Shape.DIP
			env.onset_ms = t; env.fall_ms = 50; env.hold_ms = 0; env.rise_ms = 100
			env.from_f = 1.0; env.to_f = f
			if i == 0 and light == _zones[zone_id].driven_lights()[0]:
				if not _limiter.admit(env, LightFlashLimiter.Priority.C03, now_ms):
					return                      # merged: whole group skips this dip
			_queue(light, env)                  # starts when now_ms >= onset_ms
		t += 150 + _profile.pausa_min_ms       # ≥ 350 after clamp (D10)
	# (Each dip of the group is admitted once, at its onset; simplified here.)

func _update_reflection(now_ms: int) -> void:
	_reflection.update_turn(_player.giro_acumulado(_profile.reflection.t_giro_s), now_ms)
	var tau: float = _reflection.tau_s(now_ms)
	var pose: Transform3D = _player.pose_con_retardo(tau)            # ADR-0012 ‡
	_zones[&"pasillo"].place_proxy(_mirror(pose, _profile.reflection.p0, _profile.reflection.n),
			_reflection.crossfade_alpha(now_ms))

static func _mirror(pose: Transform3D, p0: Vector3, n: Vector3) -> Transform3D:
	var p: Vector3 = pose.origin - 2.0 * (pose.origin - p0).dot(n) * n          # F2
	var f: Vector3 = -pose.basis.z
	var fr: Vector3 = f - 2.0 * f.dot(n) * n
	var yaw: float = atan2(fr.x, fr.z)
	return Transform3D(Basis(Vector3.UP, yaw), p)                                 # no negative scale
```

The `_start_dip_sequence` sketch admits per dip, not per light; the real
implementation keeps one limiter decision per **group onset** and applies it
to every light of the group (a flash is a visual event, not a per-light one).

### Implementation Guidelines

1. 28 must be a scene node under `WorldSlot` (`PAUSABLE`); it must never be an autoload (ADR-0009 D11).
2. Every light, ambient or rain change must be a `LightEnvelope` / `RainLevel` evaluated against `GameClock.now()` in integer ms; 28 must never use `Tween`, `AnimationPlayer`, `Timer`, `create_timer()` or accumulate engine `delta`.
3. Every non-monotone light envelope must pass `LightFlashLimiter.admit()` before it starts; the limiter must call `FlashGuard.try_flash()` after its local checks; surplus must be dropped, never delayed.
4. Photosensitivity constants must be read from `A11yConstants`; 28 must never define its own copies, and data must never raise them (clamp + warning).
5. Only lights in `shadow_allowlist` may have shadows; the list must have ≤ 2 entries per scene instance; only `OmniLight3D` / `SpotLight3D` may be used.
6. Lights outside the current room's visible set must be `visible = false`; ≤ 14 enabled per scene instance at any time.
7. `LightmapGI`, `VoxelGI`, SDFGI, SSR, `AreaLight3D`, auto-exposure, HDR output and `SubViewport` must never be used by 28 in the slice.
8. Shaders of 28 must not use `TIME`; phases come from uniforms fed by `GameClock.now()`.
9. The reflection proxy must never have negative scale or `CULL_FRONT`; only `C02` may be in group `reflejo_retardado`.
10. 28 must never write facts or settings and must never call 21 or 29; all input arrives by bus notice and `ctx` reads.
11. `_process` must not allocate; arrays and dictionaries are sized in `configurar()`.
12. `atmosphere.json` invalid → `ctx.fatal`; missing material → default + error log.

## Alternatives Considered

### Alternative 1: `Tween` on `light_energy` (GDD 28 R7, TR-atmos-008)
- **Description**: `create_tween()` on the zone node via `FxTween.make()`, frozen by the tree pause.
- **Pros**: Less code; what the GDD wrote; editor-friendly easing.
- **Cons**: Pause depends on NS-5 (Tween pause mode, not sourceable) and S5; the limiter cannot inspect a running tween's shape; tests need a frame loop; variant B needs SB1 anyway.
- **Estimated Effort**: Slightly lower up front; higher once SB1 or test harnesses are needed.
- **Rejection Reason**: ADR-0002 G-1 prefers `GameClock`; SB1 already names this ADR's choice as the fallback. Choosing it now removes an NS from the critical path for ~100 lines.

### Alternative 2: Own clock accumulating engine `delta` in 28
- **Description**: 28 keeps `_t += delta` and pauses itself on «pausa abierta».
- **Pros**: Independent of tree pause.
- **Cons**: Violates ADR-0002 G-1 (a second game-time accumulator); drifts from 21/23 timing.
- **Estimated Effort**: Same as chosen.
- **Rejection Reason**: Two sources of game time.

### Alternative 3: Only `FlashGuard` (no local limiter)
- **Description**: 28 relies on ADR-0007's global 3/s guard.
- **Pros**: One limiter.
- **Cons**: Does not enforce 28's stricter 2 cycles/s, 0,35 s pause, depth floor or priority (TR-atmos-006, art bible §8.7); real-time window differs from game-time envelopes.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Fails TR-atmos-005/-006.

### Alternative 4: Runtime luminance measurement for the flash rule
- **Description**: Read back a downsampled frame each frame and count luminance flashes exactly per 30 R24.
- **Pros**: Exact definition, area criterion included.
- **Cons**: GPU readback stalls; cost unsourced; reacts after the flash has been shown.
- **Estimated Effort**: High.
- **Rejection Reason**: A limiter must prevent, not detect; detection stays offline (AC-30-13, S0b-6).

### Alternative 5: `LightmapGI` baked base + few dynamic lights
- **Description**: Bake static lighting, keep only `C03` dynamic.
- **Pros**: Cheaper GPU per light.
- **Cons**: Art bible §9 forbids it; the blackout changes most of the lighting, so a bake shows wrong bounce during it; bake pipeline for one programmer.
- **Estimated Effort**: High.
- **Rejection Reason**: Art bible constraint and blackout correctness.

### Alternative 6: `SubViewport` mirror for `C02` (DT-3)
- **Description**: Mirrored camera rendering a delayed frame.
- **Pros**: Reflects the whole corridor.
- **Cons**: Roughly a second scene render; delayed video gives wrong parallax; breaks the 1,0 ms budget.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Budget; GDD DT-3.

### Alternative 7: CPU particles or mesh-flipbook rain
- **Description**: `CPUParticles3D` or a scrolling rain sheet.
- **Pros**: Particle pause NS-A4 disappears (sheet on `u_phase`).
- **Cons**: CPU cost against 0,15 ms (CPU particles); sheet reads flat at window distance.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Kept as the fallback if S7 fails in both variants: a shader sheet on `u_phase` is pause-correct by construction.

## Consequences

### Positive
- Pause correctness of 28 no longer depends on `Tween` pause semantics; AC-28-16 becomes unit-testable except for particles.
- One flash unit across 28, 30, 21, 24 and 29; integer ms removes float-boundary failures at exactly 2,0 Hz.
- Budgets enforced statically (light counts, shadow allowlist, node types), so violations fail tests before S0b.
- All behaviour in four pure classes; the unit suite runs without a scene.

### Negative
- ~300 lines of envelope/limiter code instead of tweens.
- GDD 28 text (R7, F8 row, DT-1, AC-28-02) and TR-atmos-005/-008/-016/-018 need edits.
- The energy proxy over-counts (any ≥ 10 % non-monotone change is a flash), which may drop a decorative tube flicker that a real luminance analysis would allow.
- Budgets remain provisional; S0b on non-reference hardware may need repeating.

### Neutral
- 28 keeps subscribing to «pausa abierta» / «pausa cerrada» although in variant A the handler does almost nothing.
- Zone activation means lights in unseen rooms are off; authoring must keep `zone_visibility` correct.

## Risks
- **NS-A8 fails** (luminance not monotone in energy because of glow/tonemap): a monotone blackout could look like a flash. Mitigation: S0b-6; fixed exposure; extend the proxy (D12 S0b-6 fallback).
- **NS-A1: `visible = false` does not remove the light's cluster cost.** Mitigation: S0b-2; then lower authored count or use `distance_fade`.
- **NS-A3/NS-A4: rain emission ratio or pause misbehave.** Mitigation: D6 fallback; Alternative 7 sheet.
- **Reference hardware never fixed (QQ-04)** leaves budgets unverifiable. Mitigation: S0b on developer hardware labelled non-reference; ADR-0019 blocks AC-28-19 closure, not implementation.
- **`pose_con_retardo` on wall-clock history** would jump after a pause. Mitigation: OI-4 contract on ADR-0012; T-AT12 with a fake player.
- **FlashGuard injection point not defined** in `ServiceContext`. Mitigation: OI-5.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| atmosfera-reactiva.md (28) | TR-atmos-001: placement (autoload) | Superseded by ADR-0009 D11; inherited in D1 |
| atmosfera-reactiva.md (28) | TR-atmos-002, -003: bus only, volatile, rebuilt from facts | D1, D11; no calls to 21/29; rebuild on «escena lista» + jump envelopes |
| atmosfera-reactiva.md (28) | TR-atmos-004, -019: data file, material resources | D10 |
| atmosfera-reactiva.md (28) | TR-atmos-005, -006: code constants, global limiter, merge, priority | D4 (layers 1 and 2), C2; amendment OI-1 |
| atmosfera-reactiva.md (28) | TR-atmos-007: `LightState`, idempotent orders, unknown → warning | D3 item 4, D11 |
| atmosfera-reactiva.md (28) | TR-atmos-008: energy transitions, 0,4/0,8 s, 2,0 s, floor 0,06 | D3 (envelopes, **not `Tween`**, OI-2), D5 ambient floor |
| atmosfera-reactiva.md (28) | TR-atmos-009, -011, -012, -013: proxy, state machine, crossfade, reflection ownership | D7 |
| atmosfera-reactiva.md (28) | TR-atmos-010: hands keep light | Deferred to ADR-0012; budget counts it (D2) |
| atmosfera-reactiva.md (28) | TR-atmos-014, -015: rain particles, glass shader | D6 |
| atmosfera-reactiva.md (28) | TR-atmos-016, -017: light/GPU/CPU budgets, no `LightmapGI`, Forward+ | D2, D9, D12 (C1 on "per scene") |
| atmosfera-reactiva.md (28) | TR-atmos-018, R22, AC-28-16: pause | D8 |
| atmosfera-reactiva.md (28) | TR-atmos-020: deterministic Archive tube, Reception tube | D11 |
| atmosfera-reactiva.md (28) | AC-28-19, OQ 10: 30 s spike on reference hardware | D12 (S0b) |
| opciones-de-accesibilidad.md (30) | TR-a11y-010: single flash definition, ≤ 3/s, lights ≤ 2 cycles/s with ≥ 0,35 s | D4 unit and proxy; layer 1 ⇒ ≤ 2/s; layer 2 ⇒ ≤ 3/s global |
| opciones-de-accesibilidad.md (30) | TR-a11y-011: video verification (PEAT availability unverified), luminance script | S0b-6; AC-30-13 remains the verification; tool choice QQ-23 stays with QA (OI-6) |

## Performance Implications
- **CPU**: ≤ 0,15 ms mean / 0,5 ms peak budget (PV); estimate < 0,05 ms (D9).
- **GPU**: ≤ 1,0 ms (PV), dominated by ≤ 8 lights in Forward+ clustering, ≤ 500 particles and window overdraw.
- **Memory**: textures ≤ 8 MB; material resources ≤ 1 MB loaded synchronously.
- **Load Time**: negligible (one JSON already loaded by `ContentDB`, three small materials).
- **Network**: N/A.

## Migration Plan
New code; no migration. Order: `LightEnvelope` + T-AT01–03 → `LightFlashLimiter` + T-AT04–07 (with `FakeRealClock` `FlashGuard`) → `RainLevel`, `DelayedReflection` + tests → `AtmosphereProfile` (after ADR-0005 schema) → `Atmosphere`/`AtmosphereZone` nodes + integration tests → S0b.

**Rollback plan**: If S0b-2 fails the GPU budget after the F8 ladder, cut `C03` to 4 enabled lights and rain to the shader sheet (Alternative 7) before touching the 1,0 ms budget; budget changes go through ADR-0019. If envelopes prove insufficient (unlikely), switching to `Tween` is local to `Atmosphere._process` and does not change any interface.

## Validation Criteria

### Test plan (`tests/unit/atmosphere/`, `tests/integration/atmosphere/`, GdUnit4)

| ID | File | Asserts | Covers |
|---|---|---|---|
| T-AT01 | `test_light_envelope.gd` | FALL 400 ms smoothstep monotone, mid value 0,5 at 200 ms; RESTORE linear 2000 ms, 0,5 at 1000 ms | AC-28-03, -05; F4 |
| T-AT02 | `test_light_envelope.gd` | DIP 50/0/100 ms reaches `f` and returns; `is_flash_candidate` true at depth ≥ 0,10, false at 0,09; FALL/RESTORE/JUMP never candidates | D4 |
| T-AT03 | `test_flicker_sequence.gd` | 3 dips: total 1150 ms ±20, onset spacing ≥ 500 ms | AC-28-01; F1 |
| T-AT04 | `test_light_flash_limiter.gd` | `pausa_min_s` 0,05 in data → 350 ms enforced; 6 dips requested in 1 s → ≤ 2 admitted per half-open window, rest dropped with `ATMOS_FLASH_MERGED` | AC-28-02 (tightened, C3) |
| T-AT05 | `test_light_flash_limiter.gd` | Sliding-window sweep over 10 s of default flicker: max onsets in any `[t, t+1000)` = 2 | TR-a11y-010 |
| T-AT06 | `test_light_flash_limiter.gd` | Depth floor: `f_parpadeo` 0,10 → 0,40; FALL to 0,0 untouched | AC-28-23 |
| T-AT07 | `test_light_flash_limiter.gd` | Fake `FlashGuard` returning false → candidate dropped; priority BLACKOUT > C03 > TUBE on overlap | D4 layer 2, R11 |
| T-AT08 | `test_reduced_settings.gd` | `reducir_sobresaltos`: one dip to 0,65, ramps 300 ms, blackout 800 ms ±30; both flags: one 600 ms dip | AC-28-06 |
| T-AT09 | `test_atmosphere_pause.gd` | Pause mid-dip and mid-blackout via `GameClock.pause()`; `advance()` while paused leaves factors unchanged; after resume the remaining duration completes; no new onsets during pause | AC-28-16 (lights), D8 |
| T-AT10 | `test_rain_level.gd` | F5 `base_zona` values; realce clamp to 1,0; blackout 400 ms ±50; vuelve 2000 ±100; cesa 6000 ±200 | AC-28-12, -13 (level) |
| T-AT11 | `test_atmosphere_profile.gd` | Clamps: `n_max_ventanal` 300 → 200, Σ > 500 scaled, warning; invalid file → `fatal` called | D10 |
| T-AT12 | `test_delayed_reflection.gd` | τ = 0,3 s ±0,02 mid-ENTRANDO; turn 30° no exit, 55° exit after ≥ 1,0 s; timeout 3,0 s; second trigger refused; F2 example `(14,0,0,5)` → `(14,0,−3,5)` | AC-28-07, -08, -09 |
| T-AT13 | `test_reflection_scene_scan.gd` (integration) | Proxy ≤ 400 tris, scale positive, no `SubViewport` under 28, only `C02` in `reflejo_retardado` | AC-28-11, -24 (static part) |
| T-AT14 | `test_light_budget_static.gd` (integration) | Per room visible set ≤ 8 lights; ≤ 2 shadowed per instance and only allowlisted; no `LightmapGI`/`VoxelGI`/`AreaLight3D`/`DirectionalLight3D` | TR-atmos-016/-017 |
| T-AT15 | `test_zone_activation.gd` (integration) | Walk every room transition: enabled lights ≤ 14 at every step | D2, C1 |
| T-AT16 | `test_atmosphere_resume.gd` (integration) | Facts `caja_completa` ∧ ¬`llamada_completada` + jump order → APAGON at first frame, no limiter call; `llamada_completada` → NORMAL | AC-28-14, -15 |
| T-AT17 | `test_archive_tube.gd` | Seed 20261109: exactly 2 flickers per 20 000 ms, ≥ 350 ms apart, identical across runs | AC-28-18 |
| T-AT18 | `test_unknown_order.gd` | Unknown order → warning, no state change | AC-28-22 |

Doubles: `GameClock` driven by `advance()` with `NullPauseBackend` (ADR-0002), `FakeRealClock` inside a real `FlashGuard`, `RecordingLog`, a `FakePlayer` implementing the ADR-0012 port; contexts from `TestContexts` (ADR-0009). Visual ACs (AC-28-04, -10, -20, -24) need retained screenshots in `production/qa/evidence/`.

### We will know this was right if
- T-AT01–T-AT18 pass in CI with no frame loop for the unit ones.
- S0b-1/-2 meet the PV budgets on the machine named by ADR-0019 without using more than the first two steps of the F8 ladder.
- S0b-6 / AC-30-13 video analysis finds ≤ 2 flashes per 1 s in 28's sequences and none from blackout or restore.
- No GDD rule of 28 had to change in timing or limits; only wording (OI-2, OI-3).

## Spike Results (S0b, 2026-11-11)

Prototype `prototypes/s0b-atmosphere/` (graybox hallway, 6 C03 lights, 2 shadowed, rain, C02 reflection, glow, AgX, SDR), exported release on REF-1 (Core Ultra 7 265H, Intel iGPU, D3D12), 3 P1 runs. Full data: `production/qa/perf/perf-2026-11-11-P1.md`. **Conditions were not ideal** (Windows "Balanced" power plan, other apps open): the figures are indicative until the developer repeats the run clean.

| Step | Result | Note |
|---|---|---|
| S0b-1 | PASS (proposed) | p99 frame 13.38 ms worst run; 0 frames > 16.6 ms; system 28 CPU mean 28–33 µs, peak ≤ 390 µs |
| S0b-2 | **FAIL on the per-system figure** | differential GPU of 28 ≈ 4.2 ms mean (5.2 → 9.4 ms) vs ≤ 1.0 ms; frame total still within budget |
| S0b-3 | PASS | 6 stops, ≤ 6 visible, 2 shadowed, ≤ 6 enabled; "visible" is an approximation |
| S0b-4, S0b-5, S0b-7 | NOT VALIDATED | rain ramp, glass reflection/fresnel and rain under pause not judged yet |
| S0b-6 | PARTIAL | ≤ 2 flash onsets per 1 s window on per-frame luminance; luminance monotonicity inconclusive (camera motion confounds it) |

NS-A7/NS-P2 (GPU time per viewport via `RenderingServer`): available and non-zero on 1800/1800 frames on this iGPU; not cross-checked with PIX / Intel GPA. The memory monitor returned 0: memory NOT ASSESSED. The tone was approved visually by the developer (2026-11-11). **Consequence:** D12's "at most the first two steps of F8" criterion is met at step 0 on a graybox scene, but the 4.2 ms of GPU the atmosphere costs is the main item to cut first (shadows, rain, glow, in that order of the F8 ladder) once real content is added. Status stays `Proposed` (dependencies 0003, 0005, 0007 not accepted; clean re-run pending).

## Open Items

| ID | Item | Owner / where |
|---|---|---|
| OI-1 | **Applied 2026-11-10 (OI-1 in ADR-0007 D9; OI-5 as `ctx.flash_guard` in ADR-0009 D3).** **Amend ADR-0007 D9**: add `LIGHT_FLICKER_DEPTH_FLOOR: float = 0.40`; replace the `"FLASH_MAX_HZ"` alias comment on `FLASH_MAX_PER_S` (C2); state the flash unit (onset, half-open 1000 ms, integer ms) and that 28 calls `try_flash()` after its local limiter (closes ADR-0007 OI-6) | ADR-0007 (next reconciliation) |
| OI-2 | GDD 28 R7, R22 and TR-atmos-008/-018: "`Tween`" → "envelope evaluated on `GameClock` (ADR-0014 D3)"; R22's ‡ on `TWEEN_PAUSE_STOP` removed for 28; OQ 12 closed by ADR-0002 + D8 | `/propagate-design-change` |
| OI-3 | GDD 28 F8 / TR-atmos-016: "≤ 14 cargadas por escena" → "≤ 14 habilitadas por instancia de escena (activación por sala)" (C1); AC-28-02 "≤ 3" → "≤ 2" (C3); DT-1 → scene node (reconciliation G25); TR-atmos-005 names → `A11yConstants` names (C2); `zone_visibility` and `shadow_allowlist` added to Tuning Knobs | `/propagate-design-change` |
| OI-4 | `pose_con_retardo(τ)` indexes history by game time; `giro_acumulado(window_s)` signature; hand-light mechanism counts in the light budget | ADR-0012 |
| OI-5 | `FlashGuard` is not a field of `ServiceContext` (ADR-0009 D3); decide injection (`ctx.a11y.flash_guard` or built by Boot and exposed through `Settings`) | ADR-0009 / ADR-0007 |
| OI-6 | Flash-analysis tool (PEAT availability unverified; QQ-23) and the luminance script in `tools/` | QA / accessibility-specialist |
| OI-7 | Notice name and payload of 21's atmosphere orders (`orden_atmosfera` ‡) and of room entry used for zone activation | ADR-0001 registry, ADR-0017, ADR-0011 |
| OI-8 | User decisions still open in GDD 28 that do not change this ADR's mechanics: OQ 8 flicker rhythm (limiter unchanged for any option), OQ 11 reduced blackout 0,8 s, OQ 1 rain in blackout | User |
| OI-9 | Reference hardware (QQ-04): all D9 budgets PV until then | User → ADR-0019 |

## Related
- ADR-0001 (bus), ADR-0002 (pause, `GameClock`, S5/S7, SB1/SB3), ADR-0003 (rooms not loads), ADR-0005 (data registry), ADR-0007 (`A11yConstants`, `FlashGuard`; amended by OI-1), ADR-0009 (D11 placement; OI-5), ADR-0012, ADR-0015, ADR-0017, ADR-0019 (future).
- `docs/architecture/adr-reconciliation-2026-11-10.md` (G25).
- `design/gdd/atmosfera-reactiva.md` (R1–R25, F1–F8, AC-28-01…24, OQ 10, OQ 12); `design/gdd/opciones-de-accesibilidad.md` (R18, R20, R24, AC-30-13).
- `docs/architecture/architecture.md` § Required ADRs (ADR-0014), § Presupuestos de rendimiento provisionales; `docs/architecture/tr-baseline-provisional.md` (TR-atmos-001…020, TR-a11y-010/-011).
