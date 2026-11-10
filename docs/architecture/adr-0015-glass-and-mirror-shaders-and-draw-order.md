# ADR-0015: Glass and Mirror Shaders and Transparent Draw Order

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`. This ADR
> also carries the spike that TR-shaders-008 requires before implementation
> (§ Spike Plan); it cannot go to `Accepted` before the spike report lands.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/` (VERSION.md pin 4.7.2,
`modules/rendering.md`, `breaking-changes.md`, `current-best-practices.md`,
`deprecated-apis.md`), `design/gdd/shaders-y-efectos.md` (GDD 29, round-10
text), `docs/architecture/tr-baseline-provisional.md`, ADR-0002, ADR-0007,
ADR-0009 and `adr-reconciliation-2026-11-10.md`.

## Decision Makers

technical-director (author, autonomous mode per `project.yaml`
`modes.automation: autonomous`); user approval pending at batch close.
Implementation review: technical-artist (shaders), engine-programmer (spike).

## Summary

GDD 29 needs three `spatial` shaders (memo glass of puzzle 2, mirror photo of
puzzle 5, outline mask) whose transparent draw order, per-instance parameters,
first-use compile hitch, pause behaviour and legibility under the 4.6/4.7
post-process chain all rest on engine behaviour that `docs/engine-reference/`
does not document. This ADR fixes the shader inventory and render modes, splits
the glass into an **opaque shaded film** (which carries 28's `ReflectionProbe`
reflection) plus an **unshaded transparent text layer**, uses **one
`ShaderMaterial` per surface** (no `instance uniform` in the slice), drives every
envelope and the film phase **tick-wise from `GameClock`** (no `TIME`, no
`Tween`), keeps a `StandardMaterial3D` provisional backend behind the same
`SurfaceFx` port, and defines a blocking spike (SH1–SH14) whose results decide
the remaining fallbacks.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable), Forward+ only; Windows default backend D3D12 (`rendering.md` § 4.6) |
| **Domain** | Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | **HIGH** — every rendering decision here depends on shading-language and material behaviour that the engine reference does not cover, on a post-cutoff post-process chain (glow before tonemapping, 4.6; HDR output, 4.7) and on a post-cutoff export feature (Shader Baker, 4.5) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/rendering.md` (§ 4.7, § 4.6, § 4.5, § 4.3 `Compositor`, § Common Mistakes); `breaking-changes.md` (Rendering rows: Shader Baker, `LinearToSRGB`, `Shader.set_default_texture_parameter`); `current-best-practices.md` (Shader Baker line); `deprecated-apis.md` (`Compositor` row). ADR-0002 § D3, G-9, G-10, Spike S5/S10/SB1; ADR-0007 § D9 `A11yConstants`/`FlashGuard`, `SettingsReader`; ADR-0009 § D6 output ports, § D7 `PuzzleServices` |
| **Post-Cutoff APIs Used** | Shader Baker (4.5, sourced: existence and purpose only); glow processed before tonemapping with screen blending (4.6, sourced: as a fact we must design against, not an API we call); HDR output (4.7, sourced: existence only); D3D12 default on Windows (4.6, sourced); `@abstract` (4.5, sourced via ADR-0009) |
| **Verification Required** | Everything in the NOT SOURCEABLE register below; the spike (§ Spike Plan) turns each row into PASS/FAIL on 4.7.2 before any implementation story leaves `Blocked` |

### NOT SOURCEABLE register

Every item below is used by this ADR but **not covered by
`docs/engine-reference/godot/`**. Each is written from the shading-language
conventions the team expects, is assumed only as far as stated, and is checked
by the spike row named.

| # | Claim | Not covered by | Spike |
|---|---|---|---|
| NS-R1 | `render_mode` tokens `blend_mix`, `unshaded`, `depth_draw_never`, `cull_back`, `cull_front` parse in 4.7.2 `spatial` shaders | `modules/rendering.md` | SH4 |
| NS-R2 | `Material.render_priority` orders **transparent** materials (higher drawn later) and is ignored between opaque and transparent passes | `modules/rendering.md` | SH3 |
| NS-R3 | Opaque geometry is drawn before all transparent geometry, independently of `render_priority` | `modules/rendering.md` | SH3 |
| NS-R4 | An `unshaded` material receives **no** `ReflectionProbe` contribution; a shaded opaque `StandardMaterial3D` does | `modules/rendering.md` | SH6 |
| NS-R5 | `unshaded` output is still affected by `Environment` glow, tonemapping and auto-exposure (GDD 29 R45: "possibly false" exemption) | `modules/rendering.md` (only states glow moved before tonemapping in 4.6) | SH5 |
| NS-R6 | `#include "res://….gdshaderinc"` works in `spatial` shaders on 4.7.2, including under Shader Baker | `modules/rendering.md`, `breaking-changes.md` | SH2, SH9 |
| NS-R7 | `instance uniform` (scalar / `vec4`) and `GeometryInstance3D.set_instance_shader_parameter()` | `modules/rendering.md` | SH1 (informative) |
| NS-R8 | `fwidth()` on `UV` in `fragment()` returns screen-space derivatives usable for a pixel-width outline | `modules/rendering.md` | SH7 |
| NS-R9 | Shader `TIME` keeps advancing while the tree is paused | `modules/rendering.md`; ADR-0002 NS-10 | ADR-0002 S10 (reused, not duplicated) |
| NS-R10 | Shader Baker: how it is enabled in the export preset, whether it covers `ShaderMaterial`s only referenced from scenes, and whether it removes the first-draw pipeline compile hitch on D3D12 | `modules/rendering.md` and `breaking-changes.md` state only "pre-compiles shaders" | SH9 |
| NS-R11 | Drawing a material once (visible, in frustum, behind the curtain) compiles its pipeline so that the next appearance does not hitch | `modules/rendering.md` | SH10 |
| NS-R12 | Sampler hints `source_color`, `filter_linear_mipmap`, `repeat_disable`, `hint_range` | `modules/rendering.md` (only says `sampler2D`/`texture()` unchanged in 4.4) | SH4, SH14 |
| NS-R13 | `Shader.get_shader_uniform_list()` (or equivalent) to validate a loaded shader's parameters at run time; no runtime signal for a shader that failed to compile | `modules/rendering.md` | SH12 |
| NS-R14 | In-engine GPU time and draw-call readout (`Performance` monitors, Visual Profiler, `RenderingServer` measured GPU time) | `modules/rendering.md` | SH11 |
| NS-R15 | `Environment` glow HDR threshold semantics (that a colour ≤ 1.0 never blooms when threshold ≥ 1.0) after the 4.6 glow rework | `modules/rendering.md` | SH5 |

> Knowledge Risk is HIGH. On any engine upgrade past 4.7.2 this ADR is
> re-validated by re-running SH3–SH7, SH9–SH10 and the capture set; if a row
> flips, this ADR is marked `Superseded` and a new one is written.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (pause and game time: `GameClock`/`GameClockReader`, G-7 explicit `process_mode`, G-10 no meaningful `TIME`); ADR-0009 (composition: `SurfaceFx` output port in `src/puzzles/ports/`, `NullSurfaceFx`, `PuzzleServices.surface_fx`, `SceneServices.surface_fx`, D4 `configurar()` order with 29 after 22); ADR-0007 (`SettingsReader` / `subscribe_key` for `reducir_movimiento` and `campo_vision`; `A11yConstants` flash and contrast limits) |
| **Related (non-blocking)** | ADR-0014 Atmosphere (`Proposed`, same batch): D5 — one `WorldEnvironment` per scene, AgX, glow allowed (threshold is art data), **fixed exposure, no auto-exposure**, **HDR output disabled for the slice**, no `Compositor` from 28; D7 — 28 sets the `sala_reuniones` `ReflectionProbe` for `B04` to intensity `min(data, reflection_strength_max)` and never touches `mat_glass_memo`. This ADR consumes those as given (OI-1 lists the one open point: glow threshold). ADR-0013 (hands / first-person rendering: AA choice affects thin glyphs and outlines). ADR-0010 puzzle framework (who forwards hint effects, GDD 29 Q6). ADR-0019 reference hardware (QQ-04) |
| **Enables** | Implementation stories for GDD 29 (shaders, `SurfaceFxNode`, `FxTarget`, provisional backend), the visual parts of GDD 12 (P2) and GDD 15 (P5), milestone M4 |
| **Blocks** | Epic «Shaders y efectos (29)»; P2 and P5 presentation stories. The **provisional backend** (§ D8) is **not** blocked by the spike and may start once this ADR is `Accepted` (it is the mitigation the systems index asks for) |
| **Ordering Note** | Spike SH1–SH14 runs before the shader stories; the provisional backend and the pure models (`FxEnvelope`, `FxRotation`) can be built in parallel with the spike. AC-18 (budget) cannot close before QQ-04 fixes the reference hardware |

## Context

### Problem Statement

GDD 29 is the only system in the slice that writes custom shaders, and the two
puzzles that depend on it hard (P2 memo glass, P5 mirror) hinge on legibility
and pixel-exact registration. Five things must be fixed before any shader is
written, because each changes the file layout or the API of `SurfaceFx`:

1. how the transparent layers of the glass (film, 28's reflection, text, halo)
   and the outlines are ordered, given that `render_priority` and `blend_mode`
   are NOT SOURCEABLE;
2. whether per-instance values go through `instance uniform` or a material per
   instance (TR-shaders-006, unverified);
3. how the first appearance avoids a compile hitch (Shader Baker vs warm-up,
   TR-shaders-007, unverified) and whether `#include` survives it;
4. how effects freeze in pause when shader `TIME` may not (TR-shaders-017,
   ADR-0002 G-10);
5. what "legible" means once glow, tonemapping, exposure and HDR output of
   4.6/4.7 act on an `unshaded` surface (TR-shaders-010, GDD 29 R45).

TR-shaders-008 requires a spike and an ADR before implementation; this is that
ADR.

### Current State

No shader, no `SurfaceFx` code. GDD 29 proposes the API (R33, 10 operations),
the three shaders (R7–R9), one single-material glass (R7, D29-13) at
`render_priority` 0 with 28's reflection below it (R14), outlines at
`render_priority` 3 (R41), `instance uniform vec4 frag_alpha` with a
per-instance-material fallback (R11), `Tween`-driven envelopes (R35, TR-shaders-020)
and a provisional `StandardMaterial3D` version (R36–R39). ADR-0009 already
fixes `SurfaceFx` as an `@abstract RefCounted` output port with a
`NullSurfaceFx`, implemented by a scene node of 29 and reached through
`ctx.scene.surface_fx` / `PuzzleServices.surface_fx`.

Two GDD statements cannot both hold and drive part of this decision:

- R7/D29-13 make the glass **one `unshaded` material** that composes the film,
  while R12 makes 28's `B04` reflection the room's **`ReflectionProbe`** and R14
  places it **between film and text**. An `unshaded` material is not expected
  to receive probe reflections (NS-R4), and a single material cannot have a
  separate mesh drawn *between* two of its internal layers. One of the two has
  to give (§ D2).
- R33 lists 10 operations, but R23 and TR-puzzle2-015 define `FLOOR_MARKS` as an
  order of 12 to 29 that has no operation. ADR-0009 copied "10 operations".

### Constraints

- **Engine:** Godot 4.7.2, Forward+, Windows default D3D12; no compute, no
  `hint_screen_texture`, no `hint_depth_texture` (TR-shaders-003, R6, R40).
- **Composition:** no autoload for 29 (ADR-0009 D1); per-view scene node;
  callers see only the `SurfaceFx` port and must survive `NullSurfaceFx`.
- **Pause:** game time only from `GameClock` (ADR-0002 D1); no meaningful
  `TIME` (G-10); the design must work in variant A and B.
- **Data:** artistic values in `fx_config.tres`, not in shader code
  (TR-shaders-019, coding standards); safety limits stay in `A11yConstants`
  (ADR-0007 D9, code not data).
- **Budget (unmeasured, †):** ≤ 0,5 ms GPU at 1080p for all of 29 in the worst
  view, ≤ 6 draw calls added per view, ≤ 3 texture samples per pixel in the
  glass (+ ≤ 4 dilation samples in outlines) (F29-7, TR-shaders-009). Reference
  hardware not fixed (QQ-04, Q9).
- **Team:** one programmer plus agents; the slice has three shaders, not a
  material system. Simplicity wins over reuse.

### Requirements

- Glass: fragment fade F29-1 from current alpha (no jump), latent residue,
  mirrored orientation by one uniform, `MIRROR_PREVIEW` in `neutral_zone_uv`,
  double-ring halo per lamp beam (3 lamps), text contrast ≥ 4,5 against film
  plus reflection at its cap (F29-2), x-height ≥ 14 px at 1080p / 90° (F29-3).
- Mirror: UV rotation with aspect correction (F29-6), no θ-dependent term other
  than rotation, registration error ≤ 1 px at θ\*, `FADE` and Vera `OUTLINE`.
- Outlines: resolution-independent width (F29-5), `PULSE` ≤ 2 Hz and
  `PERSISTENT` with corner marks, shape-coded (no colour dependence).
- Pause freezes every envelope; resume continues without a step.
- Shader failure or missing resource never blocks a puzzle: provisional backend
  with the same API and a single `push_error`.
- No compile hitch > 50 ms on first appearance (AC-20).
- Every public method unit-testable without the renderer.

## Decision

### D1 — Shader inventory and render modes

Three `shader_type spatial` files in `assets/shaders/`, one shader per file,
names per TR-shaders-002, plus one include. **No fourth shader**: the glass
film is a `StandardMaterial3D` (D2).

| File | Material(s) | `render_mode` (NS-R1) | Pass | `render_priority` (NS-R2) | Texture samples / px |
|---|---|---|---|---|---|
| `spatial_surface_glass_memo.gdshader` | `mat_glass_memo` (`B04`, text layer) | `blend_mix, unshaded, depth_draw_never, cull_back` | transparent | **1** | ≤ 2 (fragments atlas + preview re-sample of the same atlas); halo is analytic |
| `spatial_surface_mirror_photo.gdshader` | `mat_mirror_reflection` (`D01c/reflection`), `mat_box_photo` (`D01c/box_photo`) | `blend_mix, unshaded, depth_draw_never, cull_back` | transparent | **0** | 1 (reflection); ≤ 2 on the box photo while `FADE` is active (D5) |
| `spatial_fx_outline_mask.gdshader` | one `mat_outline_<target>` per `FxTarget` | `blend_mix, unshaded, depth_draw_never, cull_back` (flat mask mode); hull variant via `#define`-free uniform `hull_mode` + `cull_front` material copy only if a mesh target appears (none in the slice) | transparent | **3** | 1 + ≤ 4 dilation |
| `include/fx_common.gdshaderinc` | — | shared pure functions: `fx_rotate_uv`, `fx_ring`, `fx_dilate4`, `fx_luma`, `fx_in_unit_rect` | — | — | — |
| (no shader) `StandardMaterial3D` | `mat_glass_film` (`B04`, opaque, **shaded**) | default (lit) | **opaque** | 0 (irrelevant: opaque) | 0–1 (optional albedo noise) |
| (no shader) `StandardMaterial3D` | `B08` floor numbers (`FLOOR_MARKS`, TR-shaders-020) | existing level material, `emission_energy_multiplier` driven | opaque | — | unchanged |

Rules: every 29 shader **must** clamp its colour output to `[0, 1]` (no HDR
values; D7). Every 29 shader **must never** read `TIME`,
`hint_screen_texture`, `hint_depth_texture`, or use `discard` (the out-of-range
UV of the rotated photo and the outline edge go to alpha 0, F29-6, R41).

### D2 — Glass = opaque shaded film + unshaded text layer (amends GDD 29 R7/D29-13)

`B04` is two draws, both owned by 29, stacked by geometry, not by priority:

1. **`mat_glass_film`** — opaque `StandardMaterial3D` on the glass mesh:
   albedo at `L_film` ≤ 0,06, metallic/roughness/specular from
   `fx_config.tres`. Being shaded and opaque, it **receives 28's room
   `ReflectionProbe`** (NS-R4) — that *is* the reflection under the text, with
   no extra mesh and no `render_priority` involved (opaque before transparent,
   NS-R3).
2. **`mat_glass_memo`** — the shader of D1 on a coplanar quad offset
   `glass_text_offset_m` (data, default 0,001 m) towards the viewer: fragments
   F1–F3 + seal, latent residue, `MIRROR_PREVIEW`, beam halos, `film_breath`
   veil. `render_priority` 1 so it is drawn after any priority-0 transparent
   that 28 might add in the room (rain on the window) and before outlines (3).

Why: GDD 29 R14 requires *film → reflection → text*; R12 makes the reflection
a `ReflectionProbe`. An `unshaded` single material cannot show the probe, and
a single material cannot interleave another mesh. Splitting by **opaque vs
transparent** makes the order a property of the pipeline (NS-R3, the most
conservative of the ordering claims) instead of `render_priority` between
transparents (NS-R2). Legibility is protected because the text layer stays
`unshaded`, alpha 1 over the film, and is never lit.

**Reflection cap (amends R13 and AC-16 wording).** There is no proxy alpha to
cap in `B04`. `reflection_strength_max` (0,15†) becomes a **measured
luminance budget**: in capture, the reflection may add at most
`ΔL_refl_max = reflection_strength_max · L_refl_max = 0,15 · 0,30 = 0,045` to
the film's luminance (F29-2 worst case, `L_bg_eff` ≤ 0,105). The film's
`roughness`/`specular` in `fx_config.tres` are the knobs; 28 owns the probe
and sets its intensity to `min(data, reflection_strength_max)` (ADR-0014 D7),
29 owns the film material and rejects any combination that
breaks F29-2 (R13 criterion unchanged).

Rollback trigger: if SH6 shows an `unshaded` material **does** receive the
probe *and* SH3 shows transparent `render_priority` ordering is reliable,
D2 may collapse back to R7's single material; nothing outside 29 changes.

### D3 — One `ShaderMaterial` per surface; no `instance uniform` in the slice (amends GDD 29 R11 order)

Each surface gets its own `ShaderMaterial` (`resource_local_to_scene` or
duplicated at `configurar()`), never shared. Per-instance values
(`frag_alpha`, `theta_deg`, `fade_alpha`, outline intensity) are **ordinary
`uniform`s** written with `ShaderMaterial.set_shader_parameter()` through a
single helper `FxParams` (§ Key Interfaces).

Why: the slice draws at most one glass, two photos and four outlines per view;
`instance uniform` only pays off when many instances share a material. Each
outline target has its own mask **texture**, which cannot be an
`instance uniform` anyway, so outlines would need distinct materials
regardless. Removing `instance uniform` removes two unverified risks at once
(NS-R7 and "Shader Baker with `instance uniform`", TR-shaders-007) at zero
draw-call cost. The GDD's fallback becomes the rule; SH1 still records
`instance uniform` behaviour so a later scene with many instances can adopt it
by changing `FxParams` only.

### D4 — `#include` with a guarded fallback

The three shaders `#include "res://assets/shaders/include/fx_common.gdshaderinc"`
(NS-R6). If SH2 or SH9 fails, the include is **inlined** into each shader by
a build-time step (`tools/asset-pipeline/inline_shader_includes.gd`, headless
editor script) — never hand-copied — and a unit test asserts the inlined blocks
are byte-identical to the include. The include contains only pure functions;
no uniforms, no `render_mode`.

### D5 — Mirror: rotation in the shader, `FADE` inside the box-photo material

- `mat_mirror_reflection` samples the reflection photo once at
  `fx_rotate_uv(UV, theta_deg, aspect)` (F29-6). Nothing else in the shader
  depends on θ (R8, AC-9) — enforced by a static test (§ Tests, T-SF09).
- `mat_box_photo` uses the **same shader** at `theta_deg = 0` and, during
  `FADE`, re-samples the D04 photo (`overlay_tex`) at
  `fx_rotate_uv(UV, overlay_theta_deg, aspect)` with `overlay_alpha` from the
  F29-1 envelope. This keeps P5 within six draws (reflection 1 + box photo 1 +
  ≤ 4 outlines) instead of seven with a separate overlay quad. The reflection
  instance keeps R8's single sample (`overlay_alpha = 0` skips the second
  sample with a uniform branch).
- Both photos: same texture size, `filter_linear_mipmap`, `repeat_disable`
  (NS-R12), same UV layout from art; out of `[0,1]` after rotation → alpha 0.
- Node rotation is the provisional/fallback path (R24, D29-5) and is the only
  mechanism in `ProvisionalFxBackend`.

### D6 — Envelopes are tick-driven from `GameClock`; no `Tween`, no `TIME` (amends TR-shaders-017/-020)

All 29 animation — fragment and preview fades (F29-1), halo entry, `FADE`,
`OUTLINE`, `HIGHLIGHT` pulse (F29-4), `FLOOR_MARKS` emission, `film_breath`
phase — is computed in `SurfaceFxNode._process()` from
`GameClockReader.now()` by the pure model `FxEnvelope`, and written to the
materials through `FxParams`. Consequences:

- Pause freezes everything **by construction** in variant A (node is
  `PROCESS_MODE_PAUSABLE`, set explicitly in its `.tscn`, ADR-0002 G-7) and in
  variant B (`now()` is frozen) — independent of S5/S10 outcomes; SB1's
  escalation ("tick-driven envelope instead of `Tween` for 28/29") is
  pre-empted for 29.
- `film_breath` is `sin(2π · film_breath_hz · GameClock.now())` evaluated in
  GDScript and passed as `film_phase`; the shader never reads `TIME` (G-10).
  Off with `reducir_movimiento` (Q8 default).
- 29 **does not use** ADR-0002's `FxTween` helper (G-9 still binds every other
  world tween).
- Durations owned by callers stay theirs: 29 never counts `HIGHLIGHT`
  `duration_s` (9 calls `stop_highlight`, R29) and never counts P5's sequence
  (15 issues `play_fade` / `play_outline`).
- `reducir_movimiento` is read at `configurar()` and on
  `subscribe_key(&"reducir_movimiento", …)`; a change applies to the **next**
  order (R34). The reduced fade is `fade_reduced_s` (0,1 s, data), validated at
  load against `A11yConstants.REDUCED_MOTION_FADE_MIN_S/MAX_S`.

Fade curve: F29-1 (`smoothstep`, re-anchored at the current value on every
re-target). TR-puzzle2-007's provisional text (`clamp(op0 ± dt/T)`, linear) is
superseded by F29-1; both satisfy "no jump", F29-1 is the GDD formula.

### D7 — `unshaded` is **not** exempt from glow, tonemapping or exposure

29 assumes the opposite of GDD 29 R45's old claim: `unshaded` output goes
through the level `Environment` like everything else (NS-R5; `rendering.md`
§ 4.6 places glow before tonemapping with screen blending). Design response:

1. **Clamp to SDR.** 29 shaders output colour in `[0, 1]` (D1). With a glow
   HDR threshold ≥ 1,0 (NS-R15) the text cannot seed bloom; the threshold
   value belongs to 28/ADR-0014 and is requested there (OI-1).
2. **No auto-exposure.** Already fixed by ADR-0014 D5 (fixed exposure, no
   auto-exposure in game scenes, nobody writes tonemap/glow/exposure at run
   time). 29 does not touch the `Environment`.
3. **Measure, not compute.** `L_txt` ≥ 0,80, `L_film` ≤ 0,06 and C ≥ 4,5 are
   measured **in capture**, linear relative luminance of the rendered pixel,
   with the level `Environment`, glow and tonemapper as shipped (SH5, AC-3).
   The compensation knob is `text_luma` in `fx_config.tres`, clamped ≤ 1,0.
4. **HDR output (4.7) is off for the slice** (ADR-0014 D5): AC-3 is defined
   on SDR output. If a later ADR enables HDR output, SH5 and AC-3 are re-run;
   nothing in the shaders changes.

### D8 — Backends behind the port (strategy), fallback to `StandardMaterial3D`

`SurfaceFxNode` owns one `FxBackend` per surface (`glass`, `mirror`,
`outline:<target_id>`):

- `ShaderFxBackend` — the materials of D1/D2.
- `ProvisionalFxBackend` — GDD 29 R36: `StandardMaterial3D` unshaded with alpha
  transparency; one quad per fragment F1–F3, seal, preview and halo; node
  rotation for θ; `Sprite3D`/quad with `modulate` for outlines; same
  `FxEnvelope` driving `albedo_color.a` / `modulate.a`. Its draw-call excess
  over F29-7 is accepted (R36).

Selection at `configurar()`, per surface, in this order:
`fx_config.force_provisional` (data) → shader resource fails to load or has
empty code → required uniform missing (`FxShaderCheck`, NS-R13) → else shader.
Failure is logged **once** per surface with `push_error` through
`ErrorPolicy` (ADR-0001) and the puzzle continues (R39, TR-shaders-016).
Because a runtime compile failure may have no observable signal (NS-R13), the
debug build also runs `FxShaderCheck` at Boot step 9's validator pass and the
CI parse check catches syntax errors (AC-17). The provisional backend is the
first thing built (D29-11) and stays shipped as the fallback.

### D9 — Compile hitch: Shader Baker **and** warm-up, both

- **Shader Baker** (4.5+, sourced) is enabled in the Windows export preset for
  all three shaders (NS-R10 for the exact option and coverage).
- **Warm-up is always done**, not only as the alternative: when a puzzle view
  opens, 4's opening transition holds the curtain; `SurfaceFxNode.prewarm()`
  makes every 29 material of that view visible for `prewarm_frames` (data,
  default 2) in front of the camera at alpha 0,001 (not 0, to avoid a
  culled/skipped draw) and then resets them (NS-R11). It runs inside the
  transition, so it is never visible. Cost: ≤ 2 frames of ≤ 6 extra draws.
- Why both: AC-20 (≤ 50 ms hitch) is a hard player-visible criterion, the
  baker's coverage of scene-only `ShaderMaterial`s on D3D12 is unsourced, and
  warm-up is cheap. SH9/SH10 decide whether either can be dropped.

### D10 — Glass text is a pre-generated atlas; outline width by `fwidth`

- **Atlas.** `tools/asset-pipeline/bake_glass_text.gd` (headless editor
  script) renders the `DOC_01` fragments from `ContentDB` (18, locale `es`) with
  the art-bible font into **one RGBA8 texture laid out at final glass UVs**:
  R = F1, G = F2, B = F3, A = SEAL coverage, **unmirrored** (orientation is the
  `mirrored` uniform, R18/Q7). Output `assets/textures/fx/glass_memo_fragments.png`
  + `glass_memo_fragments.json` (`f1_rect_uv`, glyph x-height in metres for the
  F29-3 check). One sample yields all four coverages; `dot(cov, frag_alpha)`
  composes them. Not `Label3D`, not translatable at run time (TR-shaders-019).
  Re-bake is a pipeline step, checked by a unit test comparing the JSON hash
  with `DOC_01`'s content hash.
- **Outline width.** `w_uv = outline_width_px · fwidth(UV)` in the shader
  (NS-R8). Fallback if SH7 fails: `px_to_uv` uniform written per frame by
  `SurfaceFxNode` from camera distance, vertical FOV (`campo_vision`) and
  viewport height — exact for the fixed inspection views.

### D11 — Draw order, view budget and flash rule

**Order per view** (lower row drawn first):

| Order | P2 view (`B04`) | P5 view (`D01c`) | Mechanism |
|---|---|---|---|
| 1 | `mat_glass_film` (opaque, receives probe) | scene geometry | opaque pass (NS-R3) |
| 2 | 28's transparent room effects, if any | 28's, if any | transparent, priority 0 (28's choice) |
| 3 | — | `mat_mirror_reflection`, `mat_box_photo` | transparent, priority 0, depth-sorted; non-overlapping on screen |
| 4 | `mat_glass_memo` | — | transparent, priority 1 |
| 5 | `mat_outline_*` (≤ 4) | `mat_outline_*` (≤ 4: Vera, `HIGHLIGHT` reflection, `HIGHLIGHT` box_photo, `MARK_LIT` mark_40) | transparent, priority 3 |

Fallback if SH3 fails (priority ignored between transparents): the text quad
is offset `glass_text_offset_m` and outline quads `outline_offset_m` (data,
0,002 m) towards the viewer so back-to-front distance sorting yields the same
order; order 1 does not depend on SH3.

**Draw-call budget per view (F29-7, †, unmeasured — QQ-04):**
P2 = film 1 + text 1 + outlines ≤ 4 = **6**; P5 = reflection 1 + box photo 1
+ outlines ≤ 4 = **6**. `FLOOR_MARKS` adds 0 (existing material). A seventh 29
draw in a view is a budget violation escalated to technical-director. GPU:
`glass_memo` + film ≤ 0,20 ms, mirror ≤ 0,10, all outlines ≤ 0,15, margin 0,05
— total ≤ 0,5 ms at 1080p; **every number is a target, not a measurement**,
until QQ-04/ADR-0019 fixes the hardware and SH11 measures on it.

**Flash rule.** 29 effects are designed never to meet the flash definition, so
29 does not call `FlashGuard.try_flash()`; instead a unit test (T-SF06) proves
every `FxEnvelope` configuration stays inside **both** GDD 29 R5 (no opposing
pair > 0,25 within 333 ms, no pulse > 2 Hz) **and** `A11yConstants`
(`FLASH_MAX_PER_S`, `FLASH_WINDOW_MS`, `FLASH_LUMA_DELTA`,
`LIGHT_FLICKER_MAX_HZ`). Where they differ, the stricter value applies
(OI-5).

### Architecture Diagram

```
 Feature (callers)                     Presentation (29, scene node in `planta`)
 ┌──────────────┐  SurfaceFx port      ┌──────────────────────────────────────────────┐
 │ 12 P2 ctrl   │──(PuzzleServices)──► │ SurfaceFxNode  (PROCESS_MODE_PAUSABLE, .tscn) │
 │ 15 P5 ctrl   │──(PuzzleServices)──► │  ├─ FxTargetRegistry ◄── FxTarget nodes       │
 │ 9 hints      │──(ctx.scene)───────► │  ├─ FxEnvelope × n   ◄── GameClockReader.now()│
 └──────────────┘   NullSurfaceFx      │  ├─ FxConfig (fx_config.tres) + A11yConstants │
                    if 29 absent       │  ├─ SettingsReader: reducir_movimiento,       │
                                       │  │                  campo_vision              │
                                       │  └─ FxBackend per surface (strategy)          │
                                       │       ├─ ShaderFxBackend ── FxParams ──┐      │
                                       │       └─ ProvisionalFxBackend (R36)    │      │
                                       └────────────────────────────────────────┼──────┘
                                                                                ▼
   B04:  mat_glass_film (opaque, lit; 28's ReflectionProbe) ◄─ 28 owns probe/Environment
         mat_glass_memo (transparent p1, unshaded)  ── glass_memo_fragments.png (baked from DOC_01)
   D01c: mat_mirror_reflection / mat_box_photo (transparent p0)
   any:  mat_outline_<target> (transparent p3)
   B08:  existing StandardMaterial3D, emission_energy_multiplier
```

### Key Interfaces

```gdscript
# ─── src/puzzles/ports/surface_fx.gd  (ADR-0009 D6; signatures fixed here, closes ADR-0009 O2 for SurfaceFx) ───
## Output port: orders from 9, 12 and 15 to 29. Presentation only; never fails.
@abstract class_name SurfaceFx extends RefCounted

enum Fragment { F1, F2, F3, SEAL }

## R17: target alpha 1/0; fade F29-1 from the current value.
@abstract func set_fragment(id: Fragment, visible: bool) -> void
## R19: F1 in the opposite orientation in neutral_zone_uv; holds >= 333 ms.
@abstract func play_mirror_preview(id: Fragment, duration_s: float) -> void
## R20: current point of each beam, glass UV; empty array or NaN entry = no halo.
## Index 0..2 = lamps L, C, R (GDD 12 R5).
@abstract func set_beam_halo(points_uv: PackedVector2Array) -> void
## R23 (missing from GDD 29 R33): numbers 1-4 lit; marker at each lamp's position.
## positions[i] in 1..4 for lamp i; empty = marks off.
@abstract func set_floor_marks(positions: PackedInt32Array) -> void
## R29: PULSE until stop_highlight(); duration_s is informative (9 owns the count).
@abstract func play_highlight(target_id: StringName, duration_s: float) -> void
@abstract func stop_highlight(target_id: StringName) -> void
## R30: PERSISTENT outline + four corner marks; never stored by 29.
@abstract func set_mark_lit(target_id: StringName) -> void
## R26: D04 photo over the box photo, F29-1 over duration_s.
@abstract func play_fade(duration_s: float) -> void
## R27: Vera outline, entry over duration_s, held until clear_all().
@abstract func play_outline(duration_s: float) -> void
## R24: continuous; called on the frames theta changes.
@abstract func set_theta(theta_deg: float) -> void
## Edge case 5: everything off, no fade; resets P5 sequence state (R28).
@abstract func clear_all() -> void

# NullSurfaceFx (all no-ops), RecordingSurfaceFx (tests) — ADR-0009 D6/D8.
```

```gdscript
# ─── src/presentation/fx/fx_envelope.gd  — pure model, unit-tested (F29-1, F29-4) ───
class_name FxEnvelope extends RefCounted

var _a0: float = 0.0
var _a1: float = 0.0
var _t_ini: float = 0.0
var _t_f: float = 0.0          # 0 = instant

## Re-anchors at the current value: no jump on mid-fade re-target (R17, AC-2).
func retarget(target: float, now_s: float, fade_s: float) -> void:
	_a0 = value(now_s)
	_a1 = clampf(target, 0.0, 1.0)
	_t_ini = now_s
	_t_f = maxf(fade_s, 0.0)

func value(now_s: float) -> float:
	if _t_f <= 0.0:
		return _a1
	var k: float = clampf((now_s - _t_ini) / _t_f, 0.0, 1.0)
	return _a0 + (_a1 - _a0) * smoothstep(0.0, 1.0, k)

func is_settled(now_s: float) -> bool:
	return now_s - _t_ini >= _t_f

## F29-4: PULSE intensity; reduced motion => amp 0 (constant I_base).
static func pulse(now_s: float, t_ini: float, cfg: FxConfig, reduced: bool) -> float:
	var amp: float = 0.0 if reduced else cfg.highlight_amp
	var hz: float = minf(cfg.highlight_pulse_hz, A11yConstants.LIGHT_FLICKER_MAX_HZ)
	var i: float = cfg.highlight_base + amp * 0.5 * (1.0 + sin(TAU * hz * (now_s - t_ini)))
	return i
```

```gdscript
# ─── src/presentation/fx/fx_params.gd — the ONLY place that writes material parameters ───
class_name FxParams extends RefCounted
## Today: per-material uniforms (D3). Switching to instance uniforms is a change here only.
static func set_param(mat: ShaderMaterial, name: StringName, value: Variant) -> void:
	mat.set_shader_parameter(name, value)

# ─── src/presentation/fx/fx_target.gd ───
## Declares a highlightable element in a scene (R31, TR-shaders-015).
class_name FxTarget extends Node
@export var target_id: StringName
@export var outline_mask: Texture2D          # 1-channel, undilated (R9)
@export var surface: NodePath                # MeshInstance3D / quad to dress

# ─── src/presentation/fx/fx_backend.gd ───
@abstract class_name FxBackend extends RefCounted
@abstract func apply(state: FxSurfaceState) -> void    # values already evaluated for this frame
@abstract func prewarm(visible: bool) -> void
@abstract func clear() -> void
# ShaderFxBackend · ProvisionalFxBackend · RecordingFxBackend (tests)
```

```gdscript
# ─── src/presentation/fx/surface_fx_node.gd (sketch) ───
class_name SurfaceFxNode extends Node
## Scene node of 29 (ADR-0009 D1). process_mode = PAUSABLE set in surface_fx.tscn (G-7).

var _clock: GameClockReader
var _settings: SettingsReader
var _cfg: FxConfig
var _targets: Dictionary[StringName, FxTarget] = {}
var _backends: Dictionary[StringName, FxBackend] = {}
var _frag: Array[FxEnvelope] = []            # F1, F2, F3, SEAL
var _reduced: bool = false

func configurar(ctx: ServiceContext) -> void:
	_clock = ctx.clock_reader
	_settings = ctx.settings_reader
	_cfg = FxConfigLoader.load_validated(ctx)          # ranges vs A11yConstants
	_reduced = _settings.get_bool(&"reducir_movimiento")
	ctx.settings.subscribe_key(&"reducir_movimiento", _on_reduced_changed)  # next order only (R34)
	_register_targets()                                # FxTarget children of the scene
	_backends = FxBackendSelector.build(_cfg, _targets) # D8 order; push_error once on fallback

func as_port() -> SurfaceFx:
	return _SurfaceFxAdapter.new(self)                 # adapter, as ADR-0009 D5

func _fade_s(nominal_s: float) -> float:
	return _cfg.fade_reduced_s if _reduced else nominal_s

func set_fragment(id: int, visible: bool) -> void:
	_frag[id].retarget(1.0 if visible else 0.0, _clock.now(), _fade_s(_cfg.fragment_fade_s))

func play_highlight(target_id: StringName, _duration_s: float) -> void:
	if not _targets.has(target_id):
		push_warning("SurfaceFx: unknown target_id %s" % target_id)   # R31, AC-13
		return
	# replaces any running PULSE on the same target (R32); MARK_LIT untouched
	...

func _process(_delta: float) -> void:
	var now_s: float = _clock.now()                    # frozen in pause (ADR-0002 D1)
	for key: StringName in _backends:
		_backends[key].apply(_evaluate(key, now_s))
```

```glsl
// ─── assets/shaders/include/fx_common.gdshaderinc  (pure functions only) ───
// F29-6: rotation about c with aspect correction a = width / height.
vec2 fx_rotate_uv(vec2 uv, float theta_deg, float a) {
	float t = radians(-theta_deg);
	vec2 p = (uv - vec2(0.5)) * vec2(a, 1.0);
	p = vec2(cos(t) * p.x - sin(t) * p.y, sin(t) * p.x + cos(t) * p.y);
	return p / vec2(a, 1.0) + vec2(0.5);
}
float fx_in_unit_rect(vec2 uv) {            // 1 inside [0,1]^2, else 0 (no discard)
	vec2 s = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	return s.x * s.y;
}
// Double ring (R20): two thin circles, analytic, w in uv; aspect-corrected distance.
float fx_ring(vec2 uv, vec2 c, float r, float w, float gap, float a) {
	float d = length((uv - c) * vec2(a, 1.0));
	float r1 = 1.0 - smoothstep(0.0, w, abs(d - r));
	float r2 = 1.0 - smoothstep(0.0, w, abs(d - (r + gap)));
	return max(r1, r2);
}
float fx_luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }
```

```glsl
// ─── assets/shaders/spatial_surface_glass_memo.gdshader (pseudocode) ───
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_back;   // NS-R1, SH4
#include "res://assets/shaders/include/fx_common.gdshaderinc" // NS-R6, SH2

group_uniforms text;
uniform sampler2D fragments_tex : source_color, filter_linear_mipmap, repeat_disable; // RGBA = F1,F2,F3,SEAL
uniform vec4 frag_alpha = vec4(0.0);            // envelopes, written by FxParams (D3)
uniform float residue_alpha : hint_range(0.0, 0.1) = 0.04;
uniform vec3 text_color : source_color = vec3(0.9);
uniform float text_luma : hint_range(0.0, 1.0) = 1.0;
uniform bool mirrored = true;                   // R18 / Q7
group_uniforms preview;
uniform vec4 neutral_zone_uv;                   // xy = min, zw = max
uniform vec4 f1_rect_uv;                        // from glass_memo_fragments.json
uniform float preview_alpha = 0.0;              // envelope x mirror_preview_opacity (0.8)
group_uniforms halo;
uniform vec2 halo_uv_0; uniform vec2 halo_uv_1; uniform vec2 halo_uv_2;   // lamps L, C, R
uniform vec3 halo_alpha = vec3(0.0);
uniform float halo_radius_uv = 0.06; uniform float halo_width_uv = 0.004; uniform float halo_gap_uv = 0.008;
uniform vec3 halo_color : source_color = vec3(0.85);
uniform float glass_aspect = 1.0;
group_uniforms breath;
uniform float film_phase = 0.0;                 // sin(2π f GameClock.now()), CPU side (D6, G-10)
uniform float film_breath_amp = 0.0;            // 0 when reducir_movimiento

void fragment() {
	vec2 uv = mirrored ? vec2(1.0 - UV.x, UV.y) : UV;
	vec4 cov = texture(fragments_tex, uv);                                   // sample 1
	float text_a = dot(cov, max(frag_alpha, vec4(residue_alpha)));           // latent residue (R18)
	// MIRROR_PREVIEW: map neutral zone -> F1 rect, opposite orientation, sample 2
	vec2 nz = (UV - neutral_zone_uv.xy) / (neutral_zone_uv.zw - neutral_zone_uv.xy);
	vec2 puv = mix(f1_rect_uv.xy, f1_rect_uv.zw, mirrored ? nz : vec2(1.0 - nz.x, nz.y));
	float prev_a = preview_alpha > 0.0 ? texture(fragments_tex, puv).r * fx_in_unit_rect(nz) * preview_alpha : 0.0;
	float ring = max(max(fx_ring(UV, halo_uv_0, halo_radius_uv, halo_width_uv, halo_gap_uv, glass_aspect) * halo_alpha.x,
	                     fx_ring(UV, halo_uv_1, halo_radius_uv, halo_width_uv, halo_gap_uv, glass_aspect) * halo_alpha.y),
	                     fx_ring(UV, halo_uv_2, halo_radius_uv, halo_width_uv, halo_gap_uv, glass_aspect) * halo_alpha.z);
	float breath = film_breath_amp * (0.5 + 0.5 * film_phase);              // veil over the opaque film
	float glyph_a = max(text_a, prev_a);
	// Glyph wins where both overlap; ring radius > glyph size keeps them apart (R20).
	vec3 col = mix(halo_color, text_color * text_luma, step(ring, glyph_a));
	ALBEDO = clamp(col, 0.0, 1.0);                                           // SDR clamp (D1, D7)
	ALPHA = clamp(max(max(glyph_a, ring), breath), 0.0, 1.0);
}
```

```glsl
// ─── assets/shaders/spatial_surface_mirror_photo.gdshader (pseudocode) ───
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_back;
#include "res://assets/shaders/include/fx_common.gdshaderinc"
uniform sampler2D photo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D overlay_tex : source_color, filter_linear_mipmap, repeat_disable; // D04, box photo only
uniform float theta_deg = 0.0;          // reflection: from 15 via set_theta; box: 0
uniform float overlay_theta_deg = 0.0;  // θ* at FADE time
uniform float overlay_alpha = 0.0;      // FADE envelope (F29-1); 0 on the reflection instance
uniform float frame_aspect = 1.333;
// No other θ-dependent term (R8, AC-9; static test T-SF09).
void fragment() {
	vec2 uv = fx_rotate_uv(UV, theta_deg, frame_aspect);
	vec4 c = texture(photo_tex, uv);
	float a = c.a * fx_in_unit_rect(uv);
	if (overlay_alpha > 0.0) {                       // uniform branch: 2nd sample only during FADE
		vec2 ouv = fx_rotate_uv(UV, overlay_theta_deg, frame_aspect);
		vec4 o = texture(overlay_tex, ouv) * fx_in_unit_rect(ouv);
		c.rgb = mix(c.rgb, o.rgb, o.a * overlay_alpha);
		a = max(a, o.a * overlay_alpha);
	}
	ALBEDO = clamp(c.rgb, 0.0, 1.0);
	ALPHA = a;
}
```

```glsl
// ─── assets/shaders/spatial_fx_outline_mask.gdshader (pseudocode, flat mode) ───
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_back;
#include "res://assets/shaders/include/fx_common.gdshaderinc"
uniform sampler2D outline_mask : filter_linear_mipmap, repeat_disable;  // undilated, 1 channel
uniform float outline_width_px = 4.0;      // F29-5, CPU clamps round(H·0.0035) to [3, 6]
uniform float intensity = 0.0;             // PULSE (F29-4) or PERSISTENT envelope
uniform bool corner_marks = false;         // MARK_LIT (R30): shape, not colour
uniform vec3 stroke_light : source_color = vec3(0.85);   // L >= 0.70 (F29-5)
uniform vec3 stroke_dark  : source_color = vec3(0.02);   // L <= 0.05, 1 px rim
void fragment() {
	vec2 w = outline_width_px * fwidth(UV);                  // NS-R8; fallback px_to_uv uniform
	float inside = texture(outline_mask, UV).r;              // sample 1
	float grown = max(max(texture(outline_mask, UV + vec2(w.x, 0.0)).r,
	                      texture(outline_mask, UV - vec2(w.x, 0.0)).r),
	                  max(texture(outline_mask, UV + vec2(0.0, w.y)).r,
	                      texture(outline_mask, UV - vec2(0.0, w.y)).r)); // +4 (budget)
	float ring = clamp(grown - inside, 0.0, 1.0);            // stroke outside the silhouette
	float rim  = ring * (1.0 - smoothstep(0.0, 1.0, ring * outline_width_px)); // dark 1 px edge
	float corners = corner_marks ? fx_corner_marks(UV, w) : 0.0;   // in include
	ALBEDO = clamp(mix(stroke_light, stroke_dark, rim), 0.0, 1.0);
	ALPHA = clamp(max(ring, corners) * intensity, 0.0, 1.0);
}
```

Pseudocode is normative for structure (what is sampled, what is a uniform,
what is forbidden), not for exact expressions; technical-artist owns the
final expressions within those limits. `fx_corner_marks` is part of the
include.

### Implementation Guidelines

- **G-1** 29 shaders **must** be `shader_type spatial`, one per file under
  `assets/shaders/`, named `[type]_[category]_[name].gdshader`; shared code only
  in `assets/shaders/include/fx_common.gdshaderinc`.
- **G-2** 29 shaders **must never** contain `TIME`, `hint_screen_texture`,
  `hint_depth_texture`, `discard`, compute, or any HDR (> 1,0) colour output.
  Enforced by T-SF10 (static scan).
- **G-3** Material parameters **must** be written only through `FxParams`;
  each surface **must** have its own `ShaderMaterial` (never shared).
- **G-4** Animation in 29 **must** be evaluated from `GameClockReader.now()` by
  `FxEnvelope`; 29 **must never** create a `Tween`, `Timer` or
  `SceneTreeTimer`, nor count a caller's `duration_s`.
- **G-5** `SurfaceFxNode` **must** have `process_mode = PROCESS_MODE_PAUSABLE`
  written in its `.tscn` (ADR-0002 G-7).
- **G-6** `render_priority` values are fixed: film opaque; photos 0; glass text
  1; outlines 3. A new transparent 29 material **must** take a value from this
  table via an ADR amendment.
- **G-7** Every artistic value **must** live in `fx_config.tres`; ranges are
  validated at load; safety limits come from `A11yConstants` and **must never**
  be copied into `fx_config.tres`.
- **G-8** Unknown `target_id` → `push_warning`, return; never an error, never
  a crash (AC-13). Backend fallback → one `push_error` per surface (D8).
- **G-9** The glass text **must** come from the baked atlas; `Label3D` for
  glass text is forbidden.
- **G-10** Callers (9, 12, 15) **must** reach 29 only through the `SurfaceFx`
  port and **must** tolerate `NullSurfaceFx` (ADR-0009 D6).
- **G-11** A seventh 29 draw call in a view, or a fourth texture sample per
  glass pixel, is a budget violation and **must** be escalated, not merged.

## Spike Plan

**Required by TR-shaders-008.** **Goal:** turn NS-R1…NS-R15 into PASS/FAIL
facts on **4.7.2.stable, Forward+, D3D12** (Vulkan run informative) and pick
the fallbacks of D2–D4, D9–D11. **Where:** `prototypes/spike-shaders/`
(throwaway, outside the code root, own `project.godot`). **Owner:**
technical-artist + engine-programmer; reviewed by technical-director.
**Harness:** one scene with a `B04` stand-in (film mesh + text quad + room
`ReflectionProbe` + the level `Environment` copied from 28's current
`WorldEnvironment`, glow on), a `D01c` stand-in (two 4:3 photo quads with
art-like test photos and registration crosses), four outline targets, a fixed
inspection camera at d = 1,2 m, FOV 70°/90°. Headless (**H**) claims with
gdUnit4; windowed (**W**) claims with retained screenshots in
`production/qa/evidence/adr-0015-spike/` (rendering is not judged headless).
Each probe logs which API names parsed, because the names are themselves NS.

| # | Claim | Prototype and measurement | PASS criterion | On FAIL |
|---|---|---|---|---|
| SH1 | `instance uniform` scalar/`vec4` + `set_instance_shader_parameter` (NS-R7) — **H+W**, informative | Two quads sharing one material, different `vec4` per instance | Each quad shows its own value; record whether arrays are rejected | Nothing (D3 does not use it); recorded for later scenes |
| SH2 | `#include` of `.gdshaderinc` (NS-R6) — **H** | Shader including `fx_common.gdshaderinc`; editor parse + headless load | Parses, compiles, function results identical to inlined copy (pixel diff 0 on a test quad) | D4 inline build step |
| SH3 | Transparent order by `render_priority`; opaque before transparent (NS-R2, NS-R3) — **W** | Overlapping transparent quads with priorities 0/1/3 placed in **reverse** depth order; opaque film behind | Final colour matches priority order regardless of depth; film always under | D11 offset fallback (`glass_text_offset_m`, `outline_offset_m`); re-capture |
| SH4 | `render_mode` tokens and sampler hints parse (NS-R1, NS-R12) — **H** | One shader per token set of D1; `--check-only` style parse in CI (`current-best-practices.md` § Command Line) | All parse without warnings (AC-17) | Correct spelling in this ADR (not a FAIL of the design) |
| SH5 | `unshaded` under glow/tonemap/exposure; SDR clamp vs glow threshold (NS-R5, NS-R15) — **W** | Text quad with `L_txt` target 0,80 over film 0,06; captures with glow off/on, threshold 0,8/1,0, auto-exposure off/on | With 28's shipped settings: C ≥ 4,5 with reflection at budget, ≥ 7 without (AC-3); text pixels unchanged (± 0,01 L) between glow off and on at threshold ≥ 1,0 | Escalate to ADR-0014: threshold/exposure for inspection views; else lower `L_film` / raise `text_luma` within ≤ 1,0 |
| SH6 | Probe on `unshaded` vs shaded opaque (NS-R4) — **W** | Same mesh, bright object in the probe, `unshaded` vs lit `StandardMaterial3D` | Lit film shows the reflection; `unshaded` does not (expected) | If `unshaded` *does* receive it **and** SH3 passes: D2 may collapse to one material (rollback trigger) |
| SH7 | `fwidth(UV)` outline width (NS-R8) — **W** | Outline at 1280×720, 1920×1080, 3840×2160 | Measured stroke = `clamp(round(H·0,0035), 3, 6)` px ± 0,5 px at each | `px_to_uv` uniform (D10) |
| SH8 | Shader `TIME` in pause (NS-R9) | **Not run here** — reuse ADR-0002 S10 | — | — (G-2 bans `TIME` in 29 regardless) |
| SH9 | Shader Baker (NS-R10) — **W, export build** | Windows export with baker on; cold start (shader cache cleared); open P2 view, fire first fragment; frame-time trace | Record how it is enabled; first fragment frame ≤ 50 ms above median (AC-20); `#include` survives | Rely on warm-up (D9); record |
| SH10 | Warm-up during transition (NS-R11) — **W, export build** | Baker **off**; `prewarm()` 2 frames behind curtain; then first fragment | Same ≤ 50 ms criterion | Increase `prewarm_frames`; if still failing, warm-up at Boot behind the title (escalate) |
| SH11 | GPU time and draw calls (NS-R14) — **W** | Worst P2 (3 fragments + 3 halos + preview + 4 outlines) and worst P5 (`FADE` + Vera + 2 `HIGHLIGHT` + `MARK_LIT`) at 1080p | Record the readout method that works; draw calls ≤ 6 per view; GPU ms recorded on the dev machine and **labelled non-reference** until QQ-04 | Budget review (G-11); numbers do not close AC-18 |
| SH12 | Detecting a broken shader at run time (NS-R13) — **H** | Load a shader with a syntax error and one with a missing uniform | Record whether `get_shader_uniform_list()` (or equivalent) and load status detect each | `FxShaderCheck` relies on CI parse + `force_provisional`; D8 order unchanged |
| SH13 | D3D12 vs Vulkan parity — **W**, informative | SH3, SH5, SH7 captures on both | Record differences | Slice ships the Windows default (D3D12); differences logged |
| SH14 | Registration ≤ 1 px at θ\* (F29-6, NS-R12) — **W** | Box and reflection photos with crosses, θ = θ\*, 1080p, magnified capture | `e_px` ≤ 1,0 at all control points (AC-8) | Check `repeat_disable`/mipmap bias; fall back to node rotation (D5) and re-measure |

**Decision Rule (technical-director, when the report lands):** SH2, SH3, SH4,
SH6, SH7, SH12, SH14 select fallbacks mechanically per the "On FAIL" column.
SH5 failing with 28's settings blocks AC-3 and is escalated to ADR-0014 before
any shader story closes. SH9 **and** SH10 both failing blocks AC-20 and is
escalated. SH1, SH8, SH11, SH13 are informative. The report updates § Engine
Compatibility (NS rows → "verified 4.7.2 — spike report <date>"), records the
verified behaviour in `docs/engine-reference/godot/modules/rendering.md`, and
then this ADR goes to the user for `Accepted`.

**Estimated cost:** ~2,5 developer-days: harness 0,5 d; H claims 0,5 d; W
claims and captures 1,0 d; export-build claims SH9/SH10 0,25 d; report and
engine-reference update 0,25 d.

## Alternatives Considered

### Alternative 1: Single `unshaded` glass material (GDD 29 R7 / D29-13 as written)
- **Description**: film, text, preview and halo in one transparent pass; 28's
  reflection as a separate mesh at a lower `render_priority`.
- **Pros**: one draw call; one material to tune.
- **Cons**: in `B04` the reflection is a `ReflectionProbe` (R12), which an
  `unshaded` material is not expected to show (NS-R4); even with a mesh
  reflection, it cannot sit *between* film and text of one material, so R14's
  stack is unattainable; ordering rests on NS-R2 alone.
- **Estimated Effort**: same.
- **Rejection Reason**: cannot satisfy R12 + R14 together. Kept as the SH6
  rollback target.

### Alternative 2: `instance uniform` as primary (GDD 29 R11)
- **Description**: one shared material per shader; per-instance `frag_alpha`,
  `theta_deg`, intensity via `instance uniform`.
- **Pros**: fewer material resources; batching-friendly if many instances.
- **Cons**: two unverified behaviours (NS-R7 and its interaction with Shader
  Baker); masks are textures and cannot be instance values, so outlines need
  separate materials anyway; the slice has ≤ 6 instances per view.
- **Estimated Effort**: slightly higher (spike-dependent).
- **Rejection Reason**: risk without benefit at slice scale; reversible later
  through `FxParams` only.

### Alternative 3: `Tween` envelopes (GDD 29 R35, TR-shaders-017/-020)
- **Description**: one `Tween` per fade via ADR-0002's `FxTween.make(node)`.
- **Pros**: idiomatic; less code for simple fades.
- **Cons**: pause correctness depends on S5 (`TWEEN_PAUSE_*`, NS) and on SB1 in
  variant B; re-targeting mid-fade needs kill/recreate; harder to unit-test
  deterministically than a pure function of `now()`.
- **Estimated Effort**: lower to write, higher to verify.
- **Rejection Reason**: `FxEnvelope` is a few lines, pause-proof in A and B by
  construction, and directly covered by AC-1/2/10/11/21 unit tests.

### Alternative 4: Post-process outline / glass via `Compositor` + `CompositorEffect`
- **Description**: full-screen pass (sourced pattern, `rendering.md` § 4.3) for
  outlines; or a screen-read glass.
- **Pros**: arbitrary meshes, uniform width.
- **Cons**: needs screen/depth reads (forbidden, R6/TR-shaders-003), costs a
  full-screen pass against a 0,5 ms budget, and is harder to fall back from.
- **Rejection Reason**: D29-3 already rejected it; nothing in the slice needs it.

### Alternative 5: Stencil-buffer outlines (4.5, sourced as existing)
- **Description**: mark silhouettes in stencil, draw an expanded pass.
- **Pros**: exact silhouettes for meshes.
- **Cons**: API not documented in the engine reference; extra passes;
  slice targets are flat photos and marks.
- **Rejection Reason**: D29-4; masks are exact and cheaper for flat targets.

### Alternative 6: Shader Baker only (no warm-up), or warm-up only
- **Pros**: one mechanism.
- **Cons**: baker coverage on D3D12 for scene-only materials is unsourced
  (NS-R10); warm-up alone may miss pipelines the baker would cover.
- **Rejection Reason**: AC-20 is player-visible and both are cheap; SH9/SH10
  may justify dropping one later.

### Alternative 7: `Label3D` for glass text
- **Rejection Reason**: D29-1 / TR-shaders-019 — contrast and size control,
  identical provisional and final output, no run-time translation in the slice.

## Consequences

### Positive
- The only ordering that matters for legibility (film under text) rests on
  opaque-before-transparent, the most conservative pipeline assumption.
- No dependency on `TIME`, `Tween` pause modes or `instance uniform`: three NS
  items stop mattering for correctness.
- Every timing AC of GDD 29 is a pure unit test over `FxEnvelope` with a fake
  clock.
- The provisional backend ships as a real fallback with the same port; P2/P5
  stay playable if a shader breaks.
- `FLOOR_MARKS` gets an operation; ADR-0009 O2 is closed for `SurfaceFx`.

### Negative
- The glass is two draws, not one (still within the 6-draw view budget).
- Per-surface materials mean more `.tres`/duplicated resources to manage.
- `SurfaceFxNode._process()` writes uniforms every frame while any envelope is
  unsettled (CPU cost negligible at ≤ 6 surfaces, but it is per-frame work).
- The reflection cap becomes a capture measurement, not an enforceable alpha.
- Amends GDD 29 R7, R11, R13, R33, R35, D29-13 and TR-shaders-004/-006/-017/-020
  and TR-puzzle2-007 wording (§ Open Items).

### Neutral
- Box photo carries the `FADE` overlay (≤ 2 samples during `FADE` only).
- Warm-up adds ≤ 2 frames inside the opening transition of each puzzle view.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Glow/tonemap/exposure drop text contrast below 4,5 (SH5) | Medium | High (P2 unreadable) | SDR clamp; no auto-exposure in views; `text_luma`/`L_film` knobs; escalation to ADR-0014; capture-based AC-3 |
| Probe reflection on the film exceeds `ΔL_refl_max` | Medium | Medium | Film `roughness`/`specular` knobs (29); probe intensity (28); AC-16 capture |
| `render_priority` unreliable between transparents (SH3) | Low–Medium | Medium | Geometric offset fallback; film order independent of it |
| First-appearance hitch > 50 ms (SH9/SH10) | Medium | Medium | Baker + warm-up; Boot-time warm-up as escalation |
| Registration > 1 px at θ\* (SH14) | Low | High (P5 unsolvable visually) | Same texture/filters/UVs; node-rotation fallback; art control points |
| Budget unmeasurable (QQ-04 open) | High | Medium | Numbers held as targets; SH11 dev-machine data labelled non-reference; AC-18 stays open |
| ADR-0014 contradicts the reflection/Environment contract assumed here | Medium | Medium | OI-1; D2 needs only "28 owns a room `ReflectionProbe` and the `Environment`" |
| Thin glyphs/outlines shimmer under TAA (ADR-0013's AA choice) | Medium | Low–Medium | Mipmapped atlas; capture under the shipped AA; flagged to ADR-0013 |

## GDD Requirements Addressed

**TRs covered:** TR-shaders-001…020 (all), TR-puzzle2-007, TR-puzzle2-015,
TR-puzzle5-008, TR-puzzle5-012.

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| shaders-y-efectos.md (29) | TR-shaders-001: presentation only, deterministic orders | `SurfaceFx` port has no return values and writes no facts; `FxEnvelope` is a pure function of `now()` (D6) |
| shaders-y-efectos.md (29) | TR-shaders-002, -003: three `spatial` shaders, naming, no screen/depth read, Forward+ only | D1, G-1, G-2, T-SF10 static scan |
| shaders-y-efectos.md (29) | TR-shaders-004: glass one material `blend_mix`/`unshaded`/`depth_draw_never`/priority 0, ≤ 3 samples | **Amended** by D2: text layer keeps those modes at priority 1 with ≤ 2 samples; film is an opaque lit `StandardMaterial3D` |
| shaders-y-efectos.md (29) | TR-shaders-005: outline `blend_mix`, priority 3, ≤ 4 dilation samples, no `discard` | D1, D11, outline pseudocode |
| shaders-y-efectos.md (29) | TR-shaders-006: `instance uniform` scalar/`vec4`, fallback per-instance material | D3: per-instance material is primary; SH1 informative |
| shaders-y-efectos.md (29) | TR-shaders-007, -008: `#include`, Shader Baker, warm-up; spike + ADR before implementation | D4, D9; § Spike Plan SH2, SH9, SH10 |
| shaders-y-efectos.md (29) | TR-shaders-009 (F29-7): ≤ 0,5 ms, ≤ 6 draws, ≤ 3 samples, unmeasured | D11 budget table; G-11; SH11; AC-18 open on QQ-04 |
| shaders-y-efectos.md (29) | TR-shaders-010, -011 (F29-2, F29-3): contrast ≥ 4,5 measured in capture; x-height ≥ 14 px | D7 (SDR clamp, capture measurement, `text_luma`); D10 atlas JSON x-height; captures C-01…C-04 |
| shaders-y-efectos.md (29) | TR-shaders-012 (R5): no flashes | D11 flash rule; T-SF06 against R5 and `A11yConstants` |
| shaders-y-efectos.md (29) | TR-shaders-013 (R4): shape-coded signals | Double ring, corner marks, double stroke, floor-mark point marker; capture C-07 (grayscale + 3 CVD) |
| shaders-y-efectos.md (29) | TR-shaders-014 (R34): reads only `reducir_movimiento`, `campo_vision` | `SettingsReader` + `subscribe_key`; next-order rule (D6) |
| shaders-y-efectos.md (29) | TR-shaders-015 (R31): `FxTarget` registry, unknown id → warning | `FxTarget`, `FxTargetRegistry`, G-8, T-SF04 |
| shaders-y-efectos.md (29) | TR-shaders-016 (R39): fallback to provisional, same API, one `push_error` | D8, T-SF07 |
| shaders-y-efectos.md (29) | TR-shaders-017 (R35): pause freezes envelopes; `TIME` not used | **Amended** by D6: tick-driven from `GameClock` instead of `Tween`; `film_phase` uniform; G-2/G-4; T-SF05 |
| shaders-y-efectos.md (29) | TR-shaders-018 (F29-6, R25): registration ≤ 1 px; same texture/filter/UV; `fwidth` | D5, D10; SH7, SH14; T-SF08; capture C-05 |
| shaders-y-efectos.md (29) | TR-shaders-019: values in `fx_config.tres`; glass text pre-generated | G-7; D10 atlas bake from `DOC_01`; T-SF11 |
| shaders-y-efectos.md (29) | TR-shaders-020: `FLOOR_MARKS` without shader | `StandardMaterial3D` emission, **driven by `FxEnvelope` instead of `Tween`** (D6); new `set_floor_marks` operation |
| puzle-2-memorando-en-el-cristal.md (12) | TR-puzzle2-007: instantaneous logical visibility, fade from current opacity, kept under `reducir_movimiento` | `set_fragment` → `FxEnvelope.retarget()` from current value; F29-1 curve supersedes the linear TR text; reduced = 0,1 s |
| puzle-2-memorando-en-el-cristal.md (12) | TR-puzzle2-015: closed affordance catalogue (`MIRROR_PREVIEW`, `FLOOR_MARKS`, `BEAM_HALO`); halo per frame | `play_mirror_preview`, `set_floor_marks`, `set_beam_halo` (3 lamps); halo distance decided by 12, 29 only draws |
| puzle-5-espejo-de-la-diferencia.md (15) | TR-puzzle5-008: purely geometric reflection, D04 rotated with θ over the box photo, no coherence aid | D5: only rotation depends on θ; T-SF09 static check; `FADE` overlay inside box photo |
| puzle-5-espejo-de-la-diferencia.md (15) | TR-puzzle5-012: reveal without text/arrow/flash/zoom/camera move; contour by shape and luminance; drawn by 29 | `play_outline` with Vera mask, double stroke light/dark, no colour coding; no camera or audio from 29 |

## Performance Implications

- **CPU**: `SurfaceFxNode._process()` evaluates ≤ 12 envelopes and writes ≤ ~20
  uniforms per frame while effects are unsettled; idle surfaces skip writes.
  Expected ≪ 0,05 ms (unmeasured).
- **GPU**: targets per D11 (≤ 0,5 ms at 1080p, worst view), **unmeasured** until
  QQ-04 / ADR-0019; overdraw limited to the glass and photo quads plus outline
  quads.
- **Memory**: one RGBA8 fragments atlas (size set by art from F29-3; e.g.
  2048×1024 ≈ 8 MB uncompressed with mipmaps — budget note, not a decision),
  two photos, ≤ 5 single-channel masks; one `ShaderMaterial` per surface.
- **Load Time**: Shader Baker reduces startup compile (`breaking-changes.md`);
  warm-up costs ≤ 2 frames inside each view's opening transition.
- **Network**: none.

## Migration Plan

New code; no migration. Order: (1) `FxEnvelope`, `FxRotation` (GDScript mirror
of `fx_rotate_uv`), `FxConfig` + tests T-SF01–T-SF06, T-SF08 → (2) `SurfaceFx`
port signatures (amend ADR-0009 D6 row: 11 operations) + `NullSurfaceFx`,
`RecordingSurfaceFx` → (3) `ProvisionalFxBackend` + `SurfaceFxNode` +
`FxTarget` (playable P2/P5, AC-19) → (4) spike SH1–SH14 in parallel with (1)–(3)
→ (5) shaders + `ShaderFxBackend` per spike outcome → (6) atlas bake tool →
(7) captures C-01…C-08 and AC-18/AC-20 measurements.

**Rollback plan**: set `fx_config.force_provisional = true` per surface — the
provisional backend is always shipped. If D2 proves wrong (SH6 rollback
trigger), collapse film + text into one material; callers and port unchanged.
If `fwidth`, `#include` or `render_priority` fail, the fallbacks of D4/D10/D11
apply without API change.

## Validation Criteria

### Capture plan (retained screenshots, `production/qa/evidence/`)

Naming: `production/qa/evidence/adr-0015/<id>_<desc>_<res>.png`; each capture
has a sibling `.md` with build hash, renderer/backend (D3D12), `Environment`
used, settings and the measured values. Spike captures go to
`production/qa/evidence/adr-0015-spike/`.

| ID | What | Conditions | Measured / pass | AC |
|---|---|---|---|---|
| C-01 | P2 glass, F1–F3 lit | 1080p, level `Environment`, reflection at budget and without | C ≥ 4,5 / ≥ 7; `L_film` ≤ 0,06 + `ΔL_refl` ≤ 0,045 | AC-3, AC-16 |
| C-02 | P2 glass, no fragment lit | same | `C_res` ≤ 1,5 | AC-3 |
| C-03 | `MIRROR_PREVIEW` active | same, reflection at budget | C ≥ 4,5; no overlap with the 12 points | AC-3, AC-6 |
| C-04 | x-height | 1080p at FOV 90° and 70° | ≥ 14 px | AC-4 |
| C-05 | P5 at θ\* magnified | 1080p | `e_px` ≤ 1 at control points | AC-8 |
| C-06 | P5 at θ\* and θ\* + 20° | 1080p | mean luminance/sharpness equal (± 0,01 L) | AC-9 |
| C-07 | Halo, `MARK_LIT`, `OUTLINE`, `HIGHLIGHT` | grayscale + protanopia/deuteranopia/tritanopia simulation (tool named in the `.md`) | signal ≥ 4,5 by luminance and distinct by shape | AC-14 |
| C-08 | Provisional backend, same views as C-01/C-04/C-05 | `force_provisional = true` | AC-3 (no-reflection form), AC-4, AC-8 | AC-19 |
| V-01 | Video: every 29 effect, normal and reduced motion | 60 fps capture | no opposing pair > 0,25 in 333 ms; no pulse > 2 Hz | AC-15 |
| V-02 | Cold-start trace, first fragment | export build | no frame > 50 ms over median | AC-20 |

### Automated tests (`tests/unit/shaders/`, gdUnit4, fake clock, no renderer)

| ID | File | Covers |
|---|---|---|
| T-SF01 | `test_fx_envelope_fade.gd` | F29-1: 0,5 at t = 0,4 s, 1,0 at ≥ 0,8 s; reduced 1,0 at ≥ 0,1 s (AC-1) |
| T-SF02 | `test_fx_envelope_retarget.gd` | mid-fade reversal starts at current value, no jump; last order in a frame wins (AC-2, EC-2) |
| T-SF03 | `test_surface_fx_p5_sequence.gd` | `play_fade` 1,2 s, `play_outline` 0,8 s ends at 2,0 s from sequence start (caller-driven), held until `clear_all`; reduced entry 0,1 s; re-run from alpha 0 (AC-10, R28) |
| T-SF04 | `test_surface_fx_targets.gd` | unknown `target_id` → warning, no exception; `HIGHLIGHT` replaces `HIGHLIGHT`; `MARK_LIT` overlays (AC-13, R32) |
| T-SF05 | `test_surface_fx_pause.gd` | `FakeGameClock` paused mid-`HIGHLIGHT` and mid-fade: values constant; resume continues without step (AC-21) |
| T-SF06 | `test_fx_flash_model.gd` | all envelope configs vs GDD 29 R5 and `A11yConstants` (AC-11, AC-15) |
| T-SF07 | `test_fx_backend_selection.gd` | missing shader / missing uniform / `force_provisional` → provisional, one `push_error` per surface (AC-19, R39) |
| T-SF08 | `test_fx_rotation.gd` | F29-6 worked example (4:3, 90°, (0,75; 0,5) → (0,5; 0,167)); GDScript `FxRotation` equals include formula |
| T-SF09 | `test_mirror_shader_theta_terms.gd` | static: in `spatial_surface_mirror_photo.gdshader`, `theta_deg` appears only as an argument of `fx_rotate_uv` (AC-9) |
| T-SF10 | `test_fx_shader_static_rules.gd` | static scan of `assets/shaders/`: no `TIME`, `hint_screen_texture`, `hint_depth_texture`, `discard`; one shader per file; naming (AC-17) |
| T-SF11 | `test_glass_atlas_hash.gd` | atlas JSON hash matches `DOC_01` content hash (re-bake required) |
| T-SF12 | `test_fx_config_ranges.gd` | `fx_config.tres` ranges (Tuning Knobs) and `fade_reduced_s` within `A11yConstants` bounds |

Integration: P2 and P5 views with `RecordingSurfaceFx` assert 12/15 issue the
expected orders (owned by the 12/15 stories, `tests/integration/puzzles/`).

### We'll know this was right if…
- All spike rows have a recorded outcome and no "On FAIL" escalation is open.
- C-01…C-08 pass with the shipped `Environment` on D3D12.
- AC-18 and AC-20 pass on the reference hardware once QQ-04 is fixed.
- No P2/P5 story needed to change the `SurfaceFx` port after (2).

## Open Items

| ID | Item | Owner | Blocks |
|---|---|---|---|
| OI-1 | **ADR-0014 reconciliation.** Consistent: fixed exposure, no auto-exposure, HDR off, probe owned by 28, `mat_glass_memo` untouched by 28. Open: (a) glow threshold is art data in ADR-0014 D5 — this ADR needs it ≥ 1,0 or an SH5 pass with the shipped value; (b) ADR-0014 D7 caps the probe **intensity** at `reflection_strength_max` (0,15); this ADR adds the **measured** cap `ΔL_refl` ≤ 0,045 on the film (D2). Both hold together (intensity is the knob, ΔL the criterion); ADR-0014 D7 should cite D2 so 28 does not read 0,15 as the only test; (c) ADR-0014 D12 "shared flash rule" vs OI-5 | technical-director (reconciliation round) | AC-3, AC-16 |
| OI-2 | **GDD 29 amendments**: R7/D29-13 (glass = film + text, D2); R11 (per-instance material primary, D3); R13/AC-16 (luminance cap, not alpha); R33 (11 operations: + `set_floor_marks`); R35/TR-shaders-017/-020 (no `Tween`, `FxEnvelope`); R41 (glass text priority 1). Also TR-shaders-004/-006/-017/-020 and TR-puzzle2-007 (F29-1 curve) wording in `tr-baseline-provisional.md` | game-designer (29) / `/architecture-review` | — (text only) |
| OI-3 | **ADR-0009 D6 row** says "10 operations of GDD 29": amend to 11 and point to this ADR's signatures (closes ADR-0009 O2 for `SurfaceFx`) | technical-director (reconciliation round) | — |
| OI-4 | **Reference hardware** (QQ-04 / Q9 / ADR-0019): F29-7 numbers stay targets | user → ADR-0019 | AC-18 |
| OI-5 | **Flash definitions differ**: GDD 29 R5 (0,25 luminance, 333 ms, 2 Hz) vs `A11yConstants` (`FLASH_LUMA_DELTA` 0,10, 3/s in 1000 ms, area > 25 %). This ADR tests both and applies the stricter; GDD 29 should cite ADR-0007 D9 | game-designer (29) + accessibility-specialist (30) | — |
| OI-6 | Who forwards hint effects to `SurfaceFx` (GDD 29 Q6: 9 signal vs direct) | ADR-0010 | 9's hint stories |
| OI-7 | Q1 of GDD 29 (P2/P5 views as 3D world surfaces vs `SubViewport`/UI) is assumed **3D world** here; a `SubViewport` answer invalidates D2/D11 | user / 4 / 7 | all shader stories |
| OI-8 | Q7 (text orientation) only flips the `mirrored` uniform and the atlas preview mapping; blocks AC-5 and atlas art, not this ADR | user / 12 | AC-5 |
| OI-9 | `A11yConstants.TEXT_MIN_PX` (24 logical px, UI font size) vs F29-3 (14 px x-height, world text) measure different things; ADR-0016/GDD 30 should state that world text uses F29-3 | accessibility-specialist | — |
| OI-10 | AA choice (ADR-0013) and HDR output (D7.4) must be fixed before C-01…C-07 are final | ADR-0013 / ADR-0019 | captures |

## Related

- **Depends on:** ADR-0002 (pause, `GameClock`, G-7, G-10; S10 reused as SH8);
  ADR-0007 (`SettingsReader`, `subscribe_key`, `A11yConstants`, `FlashGuard`);
  ADR-0009 (`SurfaceFx` port, `NullSurfaceFx`, `PuzzleServices`, D4 order).
- **Amends (text, pending OI-2/OI-3):** GDD 29 R7, R11, R13, R33, R35, R41,
  D29-13, AC-16; ADR-0009 D6 row; TR-shaders-004/-006/-017/-020, TR-puzzle2-007.
- **Related:** ADR-0014 (atmosphere, OI-1), ADR-0013 (rendering/AA), ADR-0010
  (hint routing), ADR-0019 (reference hardware);
  `docs/architecture/adr-reconciliation-2026-11-10.md` (G7: 29 R35 closes after
  the pause spike — satisfied for 29 by D6 regardless of S5; G26: 12/15 upward
  calls → `SurfaceFx` output port, honoured by G-10).
- **Design:** `design/gdd/shaders-y-efectos.md`,
  `design/gdd/puzle-2-memorando-en-el-cristal.md`,
  `design/gdd/puzle-5-espejo-de-la-diferencia.md`.
- **Code (planned):** `src/puzzles/ports/surface_fx.gd`,
  `src/presentation/fx/` (`surface_fx_node.gd`, `fx_envelope.gd`,
  `fx_params.gd`, `fx_target.gd`, `fx_backend.gd`), `assets/shaders/`,
  `tools/asset-pipeline/bake_glass_text.gd`,
  `tools/asset-pipeline/inline_shader_includes.gd`, `tests/unit/shaders/`.
