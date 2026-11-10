# ADR-0019: Performance Budgets and Reference Hardware

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-10

## Last Verified

2026-11-10 — against Godot 4.7.2 engine reference (`docs/engine-reference/godot/`)
and the user's answers of 2026-11-10 (PLAN-TECNICO § 7). **No measurement exists
yet on the reference machine**: every number below is a provisional target.

## Decision Makers

User (reference hardware, team size, no fixed demo date — answers of
2026-11-10); technical-director (budgets, measurement method, cut ladder).

## Summary

The project had no reference machine, so the provisional budgets of ADR-0008,
-0012, -0014 and -0015 (60 fps, ≤ 1,0 ms GPU for 28, ≤ 0,5 ms GPU for 29, ≤ 0,5 ms
CPU for the Player, ≤ 24 voices / ≤ 24 MB audio) could not be measured or closed.
Decided: the reference machine is the developer's own laptop (Intel Core Ultra 7
265H with **integrated** Intel Graphics, 15,4 GB shared RAM, 1920×1200 @ 60 Hz);
budgets stay **provisional targets** with a fixed measurement protocol, the
**frame** budget is the binding constraint, per-system numbers are allocation
guides, and a fixed, measurement-triggered cut ladder (shadow quality → 3D render
scale → rain → glow → 29 fallback materials) runs before any renderer change.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable), Forward+, Windows default backend D3D12 |
| **Domain** | Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH — D3D12 default (4.6) and glow-before-tonemap (4.6) are post-cutoff; iGPU behaviour of Forward+ on D3D12 is not covered by any reference doc |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/rendering.md`, `breaking-changes.md`, `current-best-practices.md`; ADR-0008 § Budgets, ADR-0012 D11, ADR-0014 D2/D5/D6/D9/D12, ADR-0015 D11; `.claude/docs/technical-preferences.md` § Performance Budgets; `.claude/docs/effects-map.md` § `performance.*` |
| **Post-Cutoff APIs Used** | None called. Designed against: D3D12 default backend on Windows (4.6, sourced `rendering.md` § 4.6); glow processed before tonemapping (4.6, sourced); Shader Baker (4.5, existence only, via ADR-0015) |
| **Verification Required** | P1–P6 (§ Validation Criteria) on the reference machine; NS-P1…NS-P6 below confirmed in the first profiling run |

### Engine API sourcing

| ID | Behaviour relied on | Source status | Checked in |
|---|---|---|---|
| — | D3D12 is the Windows default backend since 4.6 | `rendering.md` § 4.6 | P1 (record backend) |
| — | Glow processed before tonemapping (4.6) | `rendering.md` § 4.6 | P5 (glow-off step re-runs ADR-0014 S0b-6) |
| NS-P1 | `Performance` monitors `TIME_PROCESS`, `TIME_PHYSICS_PROCESS`, `MEMORY_STATIC`, `MEMORY_STATIC_MAX`, `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, `RENDER_TOTAL_OBJECTS_IN_FRAME`, `RENDER_VIDEO_MEM_USED`, `RENDER_TEXTURE_MEM_USED` exist with these names in 4.7.2 | NOT SOURCEABLE — pre-cutoff 4.x API, not in the engine reference | P1 |
| NS-P2 | `RenderingServer.viewport_set_measure_render_time()` + `viewport_get_measured_render_time_gpu()` return a usable per-frame GPU time on D3D12 / Intel iGPU | NOT SOURCEABLE | P1; fallback: external capture (PIX or Intel GPA), as in ADR-0014 D9 |
| NS-P3 | `rendering/scaling_3d/mode` / `scale` (bilinear, FSR 1) apply to 3D only, leaving `canvas_items` UI at native resolution | NOT SOURCEABLE | P4 (screenshot: subtitles crisp at 0,77) |
| NS-P4 | `--rendering-driver d3d12` / `vulkan` command-line selection works on 4.7.2 Windows exports | NOT SOURCEABLE | P1 (informative Vulkan run) |
| NS-P5 | `DisplayServer.window_set_vsync_mode(VSYNC_DISABLED)` and `Engine.max_fps = 0` uncap the frame rate in a profiling build on this laptop's compositor | NOT SOURCEABLE | P1 |
| NS-P6 | `Time.get_ticks_usec()` resolution is adequate for frame-time logging | NOT SOURCEABLE (same as ADR-0014 NS-A9) | P1; fallback: `Performance.TIME_PROCESS` per frame |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (it closes budgets that other ADRs left provisional; it needs none of them `Accepted` to be applied) |
| **Enables** | ADR-0014 D12 precondition (S0b now runs on reference hardware) and D9 PV budgets; ADR-0015 OI-4 / AC-18; ADR-0012 OI-10; ADR-0008 budget row; ADR-0007 / QQ-10 (720p subtitle floor can now be judged on a 1920×1200 panel) |
| **Blocks** | M4 profiling stories; AC-28-19; ADR-0015 AC-18 / AC-20 (they need P2–P3 data, not only this ADR) |
| **Ordering Note** | P1 (baseline) should run as part of spike S0b, before art investment. ADR-0018 must provide the `profiling` export preset (Open Item OI-3) before P2–P6 can be run on an export rather than in the editor |

## Context

### Problem Statement

Four ADRs and three GDDs carry budgets marked PV or † "until the reference
hardware is fixed" (QQ-04). Without a machine, S0b has no pass criterion, M4 has no
profiling target and `project.yaml` has no `performance.*` block, so `/perf-profile`
and `/gate-check` report `NOT ASSESSED`. The user answered on 2026-11-10.

### Current State

User answers (2026-11-10, firm):

- **Team:** one person, with Claude agents. No art or audio staff to absorb a
  late renderer change.
- **Reference machine:** the developer's current laptop — Windows 11 Enterprise;
  Intel Core Ultra 7 265H (16 cores / 16 threads, 2,2 GHz base); integrated GPU
  reported as "Intel Graphics", driver 32.0.101.8801, shared memory (WMI
  `AdapterRAM` reports 2 GB — unreliable, it is a 32-bit field and does not
  describe a shared-memory iGPU); 15,4 GB RAM; display 1920×1200 @ 60 Hz.
- **Demo date:** none fixed. Plan by milestones with relative durations and a cut
  order.
- **Box order (D-16):** chain c1 → c3 → c4, c2 free (current design).

Existing budget figures (all provisional, none measured):

| Source | Budget | Status before this ADR |
|---|---|---|
| `technical-preferences.md` | 60 fps, 16,6 ms frame, ~1500 draw calls, memory ceiling unset | Provisional |
| ADR-0014 D9 / TR-atmos-016 | 28: GPU ≤ 1,0 ms at 1080p; CPU ≤ 0,15 ms mean / 0,5 ms peak; ≤ 8 visible lights, ≤ 2 shadowed, ≤ 14 enabled; ≤ 500 particles; textures ≤ 8 MB; overdraw ≤ 3; 99 % of frames ≤ 16,6 ms | PV |
| ADR-0015 D11 / TR-shaders-009 | 29: GPU ≤ 0,5 ms at 1080p (glass 0,20, mirror 0,10, outlines 0,15, margin 0,05); ≤ 6 added draws per view; ≤ 3 samples/px | † unmeasured |
| ADR-0012 D11 | Player CPU ≤ 0,5 ms per frame at 60 fps | Provisional |
| ADR-0008 / TR-audio-021 | ≤ 24 voices; effects resident ≤ 10 MB; audio in memory ≤ 24 MB; on disk ≤ 40 MB | Provisional |

### Constraints

- **Integrated GPU, shared memory.** Fill rate and memory bandwidth are shared
  with the CPU. The scene's expensive features — Forward+ clustered lighting,
  two shadowed omni/spot lights, glow, transparent rain glass with up to three
  alpha layers, GPU particles — are all fill- or bandwidth-bound.
- **Native resolution is 1920×1200**, 11 % more pixels than the 1080p the
  existing budgets assume.
- **Laptop power and thermal state** change results: plugged in vs battery,
  Windows power mode, sustained load after a few minutes.
- **One developer.** A renderer switch (Forward+ → Compatibility) late in M4
  would invalidate ADR-0014 and ADR-0015 work and every capture made so far.
- **No invented numbers.** This ADR does not estimate iGPU timings; there is no
  sourced data for this GPU with Godot 4.7.2 on D3D12.

### Requirements

- TR-atmos-016, TR-shaders-009, TR-audio-021 get a measurement method, a machine
  and a pass rule.
- Budgets fit the shared 15,4 GB of RAM.
- A defined response when a budget fails, applied in a fixed order, that never
  touches accessibility floors (flash limits, 24 px text, ambient floor).

## Decision

### D1 — The reference machine is the developer laptop

The single reference machine (`REF-1`) is the laptop described in § Current State.
All budget pass/fail verdicts are made on `REF-1` under the conditions of D5. Any
other machine produces numbers labelled "non-reference", informative only. The
slice has no separate "minimum" spec: `REF-1` *is* the minimum for the demo. A
weaker target is out of scope until after the slice (Open Item OI-5).

### D2 — Renderer stays Forward+ on D3D12; 60 fps on the iGPU is a risk, NOT VERIFIED

- **Is 60 fps realistic on `REF-1` with Forward+ / D3D12 at native 1920×1200?**
  **NOT VERIFIED.** There is no measurement and no sourced figure. The judgement
  recorded here is qualitative: the S0b corridor combines every fill-bound feature
  of the slice at once, on an integrated GPU, at a resolution above the budgets'
  1080p. **Risk: HIGH** that native resolution with glow and two shadowed lights
  misses 99 % ≤ 16,6 ms; **risk: LOW** that the CPU side misses (a 16-core desktop-class
  CPU; the CPU budgets below are small).
- **Decision:** keep Forward+ and the Windows default D3D12 backend (the backend
  every ADR-0014/0015 capture is specified on). Do **not** pre-emptively switch to
  the Compatibility renderer. The response to a miss is the D4 ladder, whose first
  real lever is 3D render scale. Compatibility is an **escalation** (D4 step E),
  requiring a new ADR that supersedes the Forward+ parts of ADR-0014 and ADR-0015.
- **Vulkan** is run once per profiling pass as an informative comparison (NS-P4).
  If Vulkan is materially faster on `REF-1`, switching the default backend is a
  one-line project setting and is decided by a revision of this ADR, not ad hoc.
- **Shipped defaults stay as authored** (glow on, two shadowed lights, render
  scale 1,0) **until P1 measures them**. Defaults change only through the ladder.

### D3 — Budgets (provisional targets)

**The frame is the binding budget.** Per-system budgets are allocation guides: a
system over its share while the frame passes is logged, not cut; a frame miss is
attributed with the per-system numbers to choose the ladder step.

| ID | Budget | Target on `REF-1` | Source | Status |
|---|---|---|---|---|
| B1 | Frame | 99 % of frames ≤ 16,6 ms; mean ≤ 14,0 ms; at native 1920×1200, render scale as shipped | technical-preferences, TR-atmos-016 | Target, NOT VERIFIED |
| B2 | GPU frame | ≤ 14,0 ms p99 (2,6 ms margin for driver, compositor and present) | this ADR | Target, NOT VERIFIED |
| B3 | CPU main thread | `TIME_PROCESS` + `TIME_PHYSICS_PROCESS` ≤ 8,0 ms p99 | this ADR | Target, low risk |
| B4 | Player (2) CPU | ≤ 0,5 ms per frame | ADR-0012 D11 | Target, low risk |
| B5 | Atmosphere (28) | GPU ≤ 1,0 ms; CPU ≤ 0,15 ms mean / 0,5 ms peak; lights ≤ 8 visible / ≤ 2 shadowed / ≤ 14 enabled; ≤ 500 particles; textures ≤ 8 MB; overdraw ≤ 3 | ADR-0014 D2/D9, TR-atmos-016 | Lights/particles **hard** (static tests); GPU **at risk on iGPU**, NOT VERIFIED |
| B6 | Shaders (29) | GPU ≤ 0,5 ms worst view; ≤ 6 added draws per view; ≤ 3 samples/px | ADR-0015 D11, TR-shaders-009 | Draws/samples hard; GPU **at risk on iGPU**, NOT VERIFIED |
| B7 | Draw calls | ≤ 1500 per frame (`RENDER_TOTAL_DRAW_CALLS_IN_FRAME`) | technical-preferences | Target; revisit after P1 |
| B8 | Audio (23) | ≤ 24 voices; effects resident ≤ 10 MB; audio in memory ≤ 24 MB; on disk ≤ 40 MB | ADR-0008, TR-audio-021 | Target, low risk (counted, not GPU) |
| B9 | Process RAM | `MEMORY_STATIC` ≤ 1536 MB peak | this ADR | Target |
| B10 | Video memory | `RENDER_VIDEO_MEM_USED` ≤ 1024 MB peak (textures ≤ 512 MB of it) | this ADR | Target |
| B11 | **Memory ceiling** | Process RAM + video memory ≤ **3072 MB** peak, any scene, any time | this ADR | **Ceiling** (`memory_ceiling_mb`) |
| B12 | Hitches | 0 frames > 50 ms after the 2 s warm-up of a measured run; first-run shader compile hitches recorded separately | ADR-0015 (Shader Baker) | Target |

**Which existing figures are incompatible with an iGPU without measurement:**

- **B5 GPU 1,0 ms (28) and B6 GPU 0,5 ms (29)** were written for "1080p on
  minimum desktop hardware". On `REF-1` they cover transparent rain glass with up
  to three layers, ≤ 500 particles, a reflection proxy, glass/mirror shaders and
  outlines — all fill-bound, at 1200 lines. They are kept as targets but are the
  two figures most likely to be wrong; their "at 1080p" is reinterpreted as "at
  the internal 3D resolution actually rendered".
- **B1 at native resolution with glow and 2 shadowed lights** — see D2.
- **B7 1500 draw calls** is not a GPU question on D3D12 (CPU submission) and is
  probably compatible; it is flagged only because it was never measured.
- B3, B4, B8 and the hard light/particle caps are not GPU-bound and are not
  considered at risk.

**Memory ceiling rationale.** 15,4 GB are shared between the OS, the iGPU and
the game. 3 GB (≈ 20 %) is generous for a low-poly, two-scene slice and leaves
room for the OS, the editor, a capture tool and a browser running at the same
time during a pitch. It also keeps the demo plausible on a common 8 GB machine,
without making that machine a reference (OI-5). `AdapterRAM` (2 GB) is **not**
used as a VRAM limit: the iGPU has no dedicated memory.

### D4 — Cut ladder (measurement-triggered, fixed order)

Applied **by the developer after a failed run**, one step at a time, re-measuring
after each; the step that makes the run pass becomes the shipped default and is
recorded in the perf log. **Not** a runtime dynamic-quality system (that would
make flash analysis and captures non-reproducible). Step choice uses the frame
attribution of D5: skip a step whose subsystem is not where the time goes.

| Step | Cut | Expected visual cost | Data / owner | Must re-run |
|---|---|---|---|---|
| 0 | Measurement hygiene: AC power, Windows "best performance", vsync off in the profiling build, no other GPU apps; record backend | None | D5 | — |
| 1 | **Shadow quality**: positional shadow atlas and filter quality lowered; then the non-puzzle shadowed light (V06) loses `shadow_enabled` (P2 beam keeps its shadow if P2 needs it) | Low | `shadow_allowlist`, project settings (ADR-0014 D2) | S0b-3 |
| 2 | **3D render scale** 1,0 → 0,85 → 0,77, FSR 1 or bilinear (whichever reads better on the art); UI stays native (NS-P3) | Low–medium; low-poly art tolerates it | project setting; ADR-0007 for a possible player option (OI-4) | P4 screenshot, ADR-0015 SH5 text contrast |
| 3 | **Rain**: GDD 28 F8 ladder — emission distance scaling from 6 m, `n_max_ventanal` 200 → 100, one glass noise layer | Medium | `atmosphere.json` (ADR-0014 D6) | S0b-4 |
| 4 | **Glow**: lower glow levels/intensity, then off | Medium (tone) | `Environment` (art director) | ADR-0014 S0b-6 flash capture; ADR-0015 SH5 |
| 5 | **Shaders 29**: per-material `StandardMaterial3D` fallback (ADR-0015), outlines first, mirror second, glass last (P2 legibility depends on it) | Medium–high | ADR-0015 fallback | ADR-0015 C-01…C-08 |
| 6 | **Light reach**: `distance_fade` (NS-A6), visible set 8 → 6 via `zone_visibility` | High (space expresses emotion) | ADR-0014 D2 | S0b-3, T-AT14 |
| E | **Escalation**: Compatibility renderer or 30 fps target — new ADR, user decision (changes the look / feel the demo is pitched on) | — | technical-director + user | everything |

**Never cut:** flash limits and `FLASH_MAX_HZ`, ambient floor, 24 px text floor,
subtitle band, timings of 21/22/23, audio budgets. Lighting caps in B5 are
ceilings, never raised to buy fidelity elsewhere.

### D5 — Measurement method

**Runs.**

| Run | Scene / path | Measures | When |
|---|---|---|---|
| P1 | S0b corridor: ADR-0014 D12 scripted 30 s walk in `pasillo` (rain on, 6 `C03`, `C02` reflection, `LUCES_PARPADEO` at 10 s) | B1–B3, B5, B7, B12; backend comparison | S0b (baseline, before art investment) |
| P2 | Worst views of 29: P2 glass view, P5 mirror view, outlined inspection | B6 (ADR-0015 AC-18), B1 | M4 |
| P3 | Full-slice scripted route (each `planta` room + `recepcion`, blackout and call) | B1, B3, B4, B8, B9–B11, B12 | M4, and before M5 |
| P4 | P1 repeated at each render-scale step tried | B1, NS-P3 screenshot | when D4 step 2 is used |
| P5 | Ladder re-runs | as the step's "must re-run" | per step |
| P6 | Memory soak: 20 min of free play, then P3 again | B9–B11 growth | before M5 |

**Protocol per run.**

1. Build: exported **release** build from the `profiling` preset (OI-3, ADR-0018),
   which includes the dev-only perf harness. Editor runs are informative only.
2. Machine: `REF-1` on AC power, Windows power mode "Best performance", display at
   native 1920×1200 fullscreen, browser and capture tools closed (except an
   external GPU capture when explicitly taking one); 2 minutes in the scene before
   recording (thermal steady state).
3. Vsync off and `max_fps = 0` (NS-P5) for budget runs, to measure headroom; one
   extra run with vsync on (as shipped) counts frames that miss 16,6 ms.
4. Discard the first 120 frames (warm-up), then record **1800 frames** (30 s at 60
   fps; for P3 record the whole route). **3 runs**; the verdict uses the **worst** run.
5. Per frame, the harness logs: frame time (`Time.get_ticks_usec()` delta, NS-P6),
   `TIME_PROCESS`, `TIME_PHYSICS_PROCESS`, GPU time (NS-P2), draw calls, primitives,
   objects, `MEMORY_STATIC`, `RENDER_VIDEO_MEM_USED`, `RENDER_TEXTURE_MEM_USED`,
   active voices (23's own counter, ADR-0008), and the debug scope timers of 2 and
   28 (ADR-0012, ADR-0014 NS-A9). Peaks of memory use `MEMORY_STATIC_MAX`.
6. Per-system GPU (28, 29): the differential method of ADR-0014 D9 (same path,
   subtree on vs off) using NS-P2, or an external capture (PIX / Intel GPA on D3D12)
   when NS-P2 is not usable on the iGPU. The tool used is recorded.
7. Report: mean, p50, p95, p99, max for each series; count of frames > 16,6 ms and
   > 50 ms; verdict per budget (PASS / FAIL / NOT ASSESSED) — the harness emits
   numbers only; the verdict is written by the person filing the report
   (helpers emit observations, never verdicts).

**Records (`production/qa/`).**

- `production/qa/perf/perf-YYYY-MM-DD-<run>.md` — header: build hash, preset,
  Godot version, backend (D3D12/Vulkan), driver version, resolution, render scale,
  vsync, power mode, ladder step in force; then the summary table and verdicts.
- `production/qa/perf/perf-YYYY-MM-DD-<run>-<n>.csv` — raw per-frame series.
- `production/qa/evidence/perf/` — retained screenshot of each measured view with
  the harness overlay (and the P4 render-scale comparison), per the run-and-observe rule.

### Key Interfaces

- `tools/perf/` (dev-only, excluded from the shipping preset by ADR-0018): a
  `PerfHarness` node that drives the scripted path, samples the monitors in D5.5
  and writes the CSV. It reads nothing from game state beyond the scope timers
  already defined in ADR-0012 and ADR-0014, and is injected, not an autoload.
- `project.yaml` `performance.*` (OI-1) is the machine-readable copy of B1, B7
  and B11 for `/perf-profile` and `/gate-check`.

### Implementation Guidelines

- Budget verdicts **must** come from `REF-1` runs under D5; numbers from any other
  machine **must** be labelled "non-reference".
- A shipped quality default **must never** change except through a D4 step
  recorded in a perf log.
- Accessibility floors listed under "Never cut" **must never** be traded for
  frame time.
- The perf harness **must never** ship in the release preset.
- Systems **must** keep their static caps (lights, particles, draws, voices) as
  tests; those caps do not wait for measurements.
- A new GPU feature (new post-process, `SubViewport`, additional shadowed light,
  `AreaLight3D`) **must** have a P-run before it becomes a default.

## Alternatives Considered

### Alternative 1: Choose a stronger desktop with a discrete GPU as reference
- **Description**: Budget against a mid-range desktop GPU; test the laptop as "low".
- **Pros**: 60 fps at native resolution far more likely; budgets of 28/29 plausible as written.
- **Cons**: The user does not have that machine; one-person team; budgets would be
  verified on hardware nobody runs; the pitch is likely shown on the laptop.
- **Estimated Effort**: Lower tuning effort, but requires hardware access.
- **Rejection Reason**: Contradicts the user's firm answer (b); unverifiable.

### Alternative 2: Switch to the Compatibility renderer now
- **Description**: Target OpenGL 3.3 Compatibility from the start on the iGPU.
- **Pros**: Broadest hardware support; likely cheaper on weak GPUs.
- **Cons**: ADR-0015 is "Forward+ only"; ADR-0014's GPU particles, glow chain and
  capture specs assume Forward+; a pre-emptive switch trades known look for an
  unmeasured gain; reverting later costs the same rework twice.
- **Estimated Effort**: High (revise 0014/0015, re-author materials).
- **Rejection Reason**: No measurement says it is needed; kept as ladder step E.

### Alternative 3: Target 30 fps on the iGPU
- **Description**: Fix 33,3 ms as the frame budget.
- **Pros**: Almost certainly reachable.
- **Cons**: First-person camera feel and ADR-0012's interpolation tuning at 60 Hz
  physics; a 30 fps pitch build reads as unfinished.
- **Estimated Effort**: Low.
- **Rejection Reason**: Premature; kept as part of escalation E.

### Alternative 4: Runtime dynamic resolution / auto quality
- **Description**: Adjust render scale or effects at run time from measured frame time.
- **Pros**: Self-tuning on unknown hardware.
- **Cons**: Non-deterministic captures; flash analysis (ADR-0014 S0b-6) and text
  contrast (ADR-0015 SH5) would need to hold at every quality level; extra code for one person.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Fixed, measured defaults are simpler and testable; revisit post-slice.

## Consequences

### Positive
- QQ-04 closed; S0b and M4 have a machine and a pass rule.
- A cut order exists before the first miss, so a failure costs a re-run, not a debate.
- `performance.*` can be set, so `/perf-profile` and `/gate-check` stop reporting
  `NOT ASSESSED` for frame and memory.

### Negative
- Budgets on an iGPU are conservative: art may have to work at render scale < 1,0
  or with fewer shadows than the art bible imagines.
- One machine: no coverage of other GPUs (AMD/NVIDIA drivers) in the slice.
- Laptop thermal/power variance makes runs noisier; the protocol (worst of 3) is
  the price.

### Neutral
- 28's and 29's GPU shares remain allocation guides until P1/P2 data exists.

## Risks

- **60 fps at native resolution not reachable on the iGPU (HIGH, NOT VERIFIED).**
  Mitigation: P1 in S0b, before art investment; ladder D4; escalation E with the user.
- **NS-P2 GPU timing unusable on Intel D3D12.** Mitigation: external capture tool
  for per-system numbers; frame verdicts still come from frame time.
- **Driver update changes results.** Mitigation: driver version in every log;
  re-run P1 after any driver update.
- **Render scale hurts P2 glass text legibility.** Mitigation: step 2 re-runs
  ADR-0015 SH5; UI and subtitles stay native.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| atmosfera-reactiva.md (28) | TR-atmos-016 / F8 / AC-28-19: ≤ 8 visible lights, ≤ 2 shadowed, ≤ 14 enabled, GPU ≤ 1,0 ms, CPU ≤ 0,15 / 0,5 ms, 60 fps in 99 % of frames, "en el hardware mínimo" | D1 fixes the machine (`REF-1` = minimum for the slice); B1/B5 targets; D5 P1 measurement; D4 ladder aligns with F8 order (particles, drop layers, shadows) and adds render scale before lights |
| shaders-y-efectos.md (29) | TR-shaders-009 / F29-7: ≤ 0,5 ms GPU at 1080p, ≤ 6 draws, ≤ 3 samples, reference hardware Q9 | D1 closes Q9; B6 with "1080p" reinterpreted as internal 3D resolution; D5 P2 measures AC-18 |
| director-de-audio.md (23) | TR-audio-021 / R50 / F7: ≤ 24 voices, ≤ 10 MB resident effects, ≤ 24 MB in memory, ≤ 40 MB on disk | B8 confirmed as targets on `REF-1`; counted in P3; inside B9/B11 |
| jugador-en-primera-persona.md (2) | ADR-0012 D11 CPU share ≤ 0,5 ms (OI-10) | B4; scope timer logged in P3 |

## Performance Implications
- **CPU**: B3/B4 targets; harness cost exists only in the `profiling` preset.
- **Memory**: B9–B11; 3 GB ceiling on 15,4 GB shared.
- **Load Time**: not budgeted by this ADR (no sourced baseline); P3 logs scene load times informatively.
- **Network**: N/A.

## Migration Plan

No game code exists yet that this changes. Updates required elsewhere:
`technical-preferences.md` memory ceiling (via OI-1), architecture.md budget
table, ADR-0014 D12 "non-reference" label lifted once P1 runs on `REF-1`.

**Rollback plan**: if `REF-1` proves unrepresentative (for example, the pitch
will be shown on other hardware), supersede this ADR with a new reference; the
measurement protocol and the ladder carry over unchanged.

## Validation Criteria

- **P1 run filed** in `production/qa/perf/` on `REF-1` with all header fields and
  NS-P1…NS-P6 marked verified or replaced by their fallback.
- **B1 passes** (worst of 3 runs) at the shipped defaults, with at most ladder
  steps 1–4 applied, by the end of M4.
- **B11 passes** in P6 (no growth beyond the ceiling after 20 min).
- AC-28-19, ADR-0015 AC-18 and TR-audio-021 have a filed perf log each.

**We will know this was right if** S0b produces a verdict on `REF-1` in one
session, a miss is resolved by a ladder step without reopening the renderer
choice, and the demo build runs on the pitch machine without hitches.

## Open Items

| ID | Item | Owner | Blocks |
|---|---|---|---|
| OI-1 | Apply to `project.yaml` (not edited by this ADR; via `/settings` or by hand): `performance: { target_framerate: 60, frame_budget_ms: 16.67, draw_call_limit: 1500, memory_ceiling_mb: 3072, enforce: warn }`. Only these five keys are read by `/perf-profile` / `/gate-check` (effects-map); the other budgets live here. Mirror `memory_ceiling_mb` into `technical-preferences.md` | user / `/settings` | `/perf-profile` verdicts |
| OI-2 | Record the developer's local editor version in `VERSION.md` (currently only the cloud install is recorded) | user | Installed-version gap |
| OI-3 | `profiling` export preset including `tools/perf/` with the shipping preset excluding it | ADR-0018 revision | P2–P6 on exports |
| OI-4 | Whether render scale (D4 step 2) is also exposed to the player as an option | ADR-0007 / game-designer | Settings GDD 6 |
| OI-5 | A weaker "minimum" spec beyond `REF-1` (e.g. 8 GB machines) | post-slice | — |
| OI-6 | Re-baseline B5/B6 shares from P1/P2 data (revision of this ADR) | technical-director | AC-28-19, AC-18 |

## Related
- ADR-0008 (audio budgets), ADR-0012 (Player CPU, OI-10), ADR-0014 (D2, D9, D12 S0b),
  ADR-0015 (D11, OI-4, AC-18), ADR-0007 (UI scale / QQ-10), ADR-0018 (export presets)
- `docs/PLAN-TECNICO.md` § 4 (M4 profiling) and § 7 (answers 2026-11-10)
- `docs/architecture/architecture.md` § Presupuestos de rendimiento provisionales, QQ-04
- `design/gdd/atmosfera-reactiva.md` F8, AC-28-19; `design/gdd/shaders-y-efectos.md` F29-7
