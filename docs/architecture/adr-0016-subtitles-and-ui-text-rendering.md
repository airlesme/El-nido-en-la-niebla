# ADR-0016: Subtitles and UI Text Rendering

## Status

Accepted (2026-11-11) — SP-16A…D run on 4.7.2 headless (9 tests) with the engine's default font; SP-16E (text-server metrics), the Atkinson Hyperlegible font check and the inline-glyph ±2 px check deferred as NEEDS_WINDOWED to the playable prototype

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/VERSION.md` (pin 4.7.2),
`docs/engine-reference/godot/modules/ui.md` (verified 2026-10-17) and
ADR-0001, -0002, -0006, -0007, -0008, -0009 (all `Proposed`, reconciled
2026-11-10).

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation:
autonomous`); user approval pending at the end of the batch.

## Summary

Systems 24 (prompt), 25 (pause), 26 (subtitles) and 27 (title) need one
rendering contract: which `CanvasLayer` draws what and in which order, how
subtitle lines become timed pages inside a reserved band, how the prompt
footer avoids the subtitles, how `{accion:<id>}` tokens become glyph + text,
and which shared menu components 25 and 27 build on. Decided: eight fixed
`CanvasLayer` slots (`UiLayers`, veil split from the pause menu so subtitles
sit between them), pure `SubtitlePaginator` / `SubtitleTimeline` /
`SubtitleBand` classes driven by `GameClock`, a pull query
`SubtitleBandQuery` for 24 and 22, one `TokenResolver` + `GlyphText` site for
binding labels, Atkinson Hyperlegible Next as dynamic fonts at logical sizes
under ADR-0007's stretch (MSDF as spike fallback), a `HintPanelProvider`
pull port, `OptionsComponent.mostrar(pantalla, pestana_inicial)` + `cerrado`
as a single Shell instance shared by 25 and 27, and a `HoldRepeat` on
`RealClock` that suppresses native key echo.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | UI · Rendering (2D canvas, fonts) |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH — 4.6 dual focus, 4.7 `RichTextLabel` image units, 4.7 `accessibility_live` type and 4.7 stretch defaults are post-cutoff (`VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/ui.md` (4.4–4.7 changes, Theme, Focus, Recursive Disable, Localization-Ready UI); ADR-0002 § process-mode table; ADR-0006 D6, D9, D13, OI-4, OI-7; ADR-0007 D7, D8, D9, OI-4, OI-5, SP-1…SP-4; ADR-0008 D3, D4, D11; ADR-0009 D6 |
| **Post-Cutoff APIs Used** | Dual focus (4.6): `grab_focus()` moves keyboard/gamepad focus only — sourced; `RichTextLabel.add_image()` with `width_unit`/`height_unit` (`RichTextLabel.ImageUnit`, float sizes) (4.7) — sourced as signature shape, member names NOT SOURCEABLE; `Control.accessibility_live` typed `AccessibilityServer.AccessibilityLiveMode` (4.7) — only through ADR-0007's `A11y.set_live` |
| **Verification Required** | SP-16A font crispness under `canvas_items` + `fractional` (shared probe with ADR-0007 SP-1/SP-3); SP-16B `CanvasLayer` order and `process_mode` under pause; SP-16C native echo of `ui_*` and its suppression; SP-16D inline glyph via `add_image`; SP-16E rendered line count vs the character model (§ Validation Criteria) |

> Knowledge Risk is HIGH: re-validate on any engine upgrade.

### Engine API sourcing

| API / behaviour this ADR relies on | Status | Spike |
|---|---|---|
| `Theme.set_font_size(name, theme_type, size)`, `Theme.set_color(...)` | Sourced: `modules/ui.md` § Theme and Style | SP-16A (with ADR-0007 SP-3) |
| `Control.grab_focus()` = keyboard/gamepad focus only; hover is separate (4.6) | Sourced: `modules/ui.md` § Focus Management, § 4.6 | — (ADR-0006 S-0006-F) |
| `focus_neighbor_top/bottom/left/right = other.get_path()` | Sourced: `modules/ui.md` § Focus Management | — |
| `Label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` | Sourced: `modules/ui.md` § Localization-Ready UI | SP-16E |
| `Control.mouse_filter = Control.MOUSE_FILTER_IGNORE` (recursive in 4.5+) | Sourced: `modules/ui.md` § Recursive Disable | — |
| `RichTextLabel.add_image()` takes `width_unit`/`height_unit` (`RichTextLabel.ImageUnit`), float sizes (4.7) | Sourced (shape): `modules/ui.md` § 4.7. **`ImageUnit` member names and the remaining parameter order: NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`** | SP-16D |
| `CanvasLayer.layer` (draw order by integer) and per-layer `process_mode` | **NOT SOURCEABLE — `CanvasLayer` not covered by `docs/engine-reference/godot/modules/ui.md`** (ADR-0002 already depends on per-layer `process_mode`, S4) | SP-16B |
| Font import options (dynamic rasterisation, MSDF, oversampling) and whether `canvas_items` stretch re-rasterises text at the final size | **NOT SOURCEABLE — fonts not covered by `docs/engine-reference/godot/modules/ui.md`** | SP-16A |
| `Label.get_line_count()` / text measurement (`Font.get_string_size`, `TextParagraph`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`** | SP-16E (dev assertion only, never logic) |
| `InputEvent.is_echo()`, `is_action_pressed()`, `is_action_released()`, `Control._gui_input()`, `accept_event()` | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md` or `modules/input.md`** | SP-16C |
| Viewport visible rect / canvas transform for window ↔ logical mapping | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`** | SP-16B (with ADR-0007 SP-1) |
| `Control.offset_transform_*` (4.7, containers do not reset it) | Sourced: `modules/ui.md` § 4.7 — used for the 24 footer lift so a container never snaps it back | SP-16B |
| `Control.modulate` alpha for fades | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`** (fades are computed in script from injected clocks; no `Tween` in 24/26) | SP-16B |

Every NOT SOURCEABLE call is confined to one named site (§ Implementation
Guidelines G-3) so a failing spike changes one file.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (notice names and payloads: `line_*`, `sound_requested`, `interaction_executed`, `pause_*`, `scene_load_started`, `full_unload_requested`, `input_*`); ADR-0002 (process-mode table, `GameClock`/`RealClock`); ADR-0005 (`ContentDB.get_line()`, segments, `UI_*` keys); ADR-0006 (`get_binding_label`, `bindings_revision`, `menú` context, `PointerTargetProvider`, cursor); ADR-0007 (stretch D7, 24 px logical floor, `UiTextScale`, `A11y`, `FocusChain`); ADR-0008 (`line_started` timing D4, `seg_b_inicio_s` in 18 D11); ADR-0009 (Shell, `UiPorts`, `SceneServices.hint_panel`, bind/unbind) |
| **Enables** | ADR-0017 (call UI of 22 respects `SubtitleBandQuery.reserved_height_px()`); UI ADR/stories of 19 (computer overlay in `SCENE_UI`, closes ADR-0007 OI-5 for the slice); 27 title stories; 30 accessibility tab |
| **Blocks** | Epics for 24 (Prompt), 25 (Pause), 26 (Subtitles), 27 (Title UI); UI parts of 17 (hint panel), 20 (reading screen), 22 (answer options) |
| **Ordering Note** | ADR-0007 D7 stretch settings and SP-1 must land before SP-16A; SP-16A/B/C must pass before any UI screenshot evidence (`production/qa/evidence/`) is accepted |

## Context

### Problem Statement

`architecture.md` (§ Required ADRs, row ADR-0016) leaves five Presentation
contracts unsigned (QQ-19 for 17 → 25 and `OptionsComponent`) and several
cross-GDD rules without a mechanism: subtitles drawn *above* the pause veil
(26 R22, ADR-0002), the 24 footer that must never cover a subtitle (24 R24,
26 R23), a reserved band that caps 22 and 24 (26 F4), pagination with an
8 s page cap (26 R7, F2), `{accion:<id>}` tokens (24 R27, 26 Edge Cases),
held repetition of `ui_izquierda/derecha` (TR-pause-013, handed here by
ADR-0006 D6/OI-4), one 24 px logical text floor (ADR-0007 D7), and which
menu building blocks 25 and 27 share. Without one ADR each of four epics
would invent its own layer numbers, timers and glyph code.

### Current State

No UI code exists. ADR-0002 fixed process modes per layer; ADR-0009 placed
24/25/26 in `Shell`; ADR-0007 fixed scaling. The `Shell` tree in
`architecture.md` lists `HUD`, `Subtitles`, `PauseMenu` (veil included) and
`Curtain` as sibling `CanvasLayer`s **without layer numbers**: as drawn, the
veil lives inside `PauseMenu`, so subtitles cannot be both above the veil and
below the menu panels.

### Constraints

- GDScript, statically typed; no new autoloads (ADR-0009: UI are Shell nodes).
- No engine API from memory; NOT SOURCEABLE calls in one site each.
- Logical pixels at the 1920×1080 base only; no script computes
  `alto_ventana/1080`; `content_scale_factor` never written (ADR-0007 D7).
- 26 emits nothing and calls neither 23 nor 21 (TR-subs-001).
- 24 and 26 clocks are game time (frozen in pause); 25 is real time.
- Spanish only in the slice; no `tr()` catalogue — text comes from 18.
- Single developer, slice scope: no screen-reader promise (30 D30-2).

### Requirements

- R1 Fixed, documented draw order and process mode for every UI layer.
- R2 Subtitles visible over the veil, under the menu panels, frozen in pause.
- R3 Subtitle timing exactly per 26 F1/F2 and 23's `t_lectura_s`.
- R4 Footer of 24 lifts above visible subtitle blocks; 22/24 content never
  enters `alto_reservado_px`.
- R5 Every reading text ≥ 24 logical px, reflow without clipping at
  `escala_texto_ui` 1.50 (TR-a11y-007, TR-pause-022).
- R6 Glyph + text for bound actions, never a hard-coded key.
- R7 One options UI reused by pause and title; hint panel pulled, not pushed.
- R8 Held repetition 0.4 s / 0.12 s real time, with no OS echo added.
- R9 Cost: ≤ 0.3 ms CPU per frame for 24 + 26 at steady state (§ Performance).

## Decision

### D1 — Eight fixed `CanvasLayer` slots; the veil is its own layer

| `layer` | Node (owner) | Parent | `process_mode` | Clock | Contents |
|---|---|---|---|---|---|
| 0 | (default canvas) | — | — | — | 3D world |
| 5 | `SceneUi` (27, 19, 22) | inside the `WorldSlot` instance | inherits **`PAUSABLE`** | `GameClock` | Title screens and warnings (27), computer overlay (19), call answer options (22) |
| 10 | `HUD` (24, 17, 20) | `Shell` | **`PAUSABLE`** | `GameClock` | `InteractionPrompt` (ring, label, footer), `HintNote`, `ReadingScreen` |
| 20 | `PauseVeil` (25) | `Shell` | **`ALWAYS`** | `RealClock` | Veil + desaturation, F3 fade |
| 30 | `Subtitles` (26) | `Shell` | **`ALWAYS`** | `GameClock` (own freeze) | Band with ≤ 2 blocks |
| 40 | `MenuLayer` (25) | `Shell` | **`ALWAYS`** | `RealClock` | `PauseMenu` root and dialogs; the single `OptionsComponent` (also hosted by 27) |
| 50 | `CursorLayer` (1) | `Shell` | **`ALWAYS`** | `RealClock` | Virtual cursor drawing (ADR-0006 D9) |
| 60 | `Curtain` (4) | `Shell` | **`ALWAYS`** | `RealClock` | Load curtain |
| 70 | `ErrorPanel` (4) | `Shell` | **`ALWAYS`** | `RealClock` | Fatal/release error panel |

Values live in `src/ui/ui_layers.gd` as constants (structure, not gameplay
data). Rules: every `CanvasLayer` **must** set `layer` and `process_mode`
explicitly in code from `UiLayers` (ADR-0002 R: no inheritance from `Shell`);
a new layer takes a free slot between existing ones and is added to this
table. This is consistent with ADR-0002's table (HUD `PAUSABLE`, Subtitles
`ALWAYS`, PauseMenu `ALWAYS`, Curtain `ALWAYS`) and only **splits** the veil
out of `PauseMenu` into `PauseVeil`, owned and faded by 25.

Consequences of the order: (a) subtitles are above the veil and below the
menu panels; a level-2 options panel may occlude frozen blocks, which is
accepted (they are frozen and 26 R26's preview is a separate sample);
(b) the curtain hides subtitles: 21 must not start a line while the curtain
covers the screen except where 4's `sin control` hand-off says so (OI-4);
(c) `SceneUi` freezes with the world, so 19/22 overlays never animate in
pause; (d) the cursor draws above menus and below the curtain.

### D2 — Logical canvas, `SafeArea169` and `ViewportMapper` (closes ADR-0006 OI-7, ADR-0007 OI-4 part)

All layout is in logical px of the **logical viewport** produced by ADR-0007
D7 (`canvas_items` + `expand`: 1920×1080 at 16:9, 2560×1080 at 21:9,
1920×1200 at 16:10). `SafeAreaMath.safe_rect(logical: Vector2) -> Rect2`
(pure): if `logical.x / logical.y > 16/9` the rect is the centred
`logical.y × 16/9` wide column; otherwise the whole viewport; then inset 5 %
per side (`margen_seguro_pct`, 30 / art bible). `SafeArea169` is a `Control`
that applies it on resize. HUD, prompt, subtitles and `SceneUi` overlays
anchor to it; full-screen menus (25/27/19) may use the extra height.

`ViewportMapper` (pure, `RefCounted`) maps window px ↔ logical px from a
`ViewportProbe` port. `EngineViewportProbe` is the **only** site reading the
viewport's visible rect / canvas transform (NOT SOURCEABLE, SP-16B).
`PointerCursor` (ADR-0006 D9) is clamped to `ViewportMapper.logical_rect()`,
not a literal 1920×1080 (amendment C3).

### D3 — Fonts, sizes and the floor (closes ADR-0007 OI-4 font part)

- **Family:** Atkinson Hyperlegible Next (art bible 7.2; OFL), files
  `assets/fonts/atkinson_hyperlegible_next/` Regular, Italic, Bold. Coverage
  check in CI: every character of every 18 string used by 24/25/26/27 exists
  in the face (Spanish, `«»`, `¿¡`, `ñ`, accented vowels, `…`).
- **Rasterisation:** dynamic font (no pre-baked bitmap), sizes set on the
  **logical** theme size; the engine's `canvas_items` stretch produces the
  physical size (24 logical → 16 px at 720p, 48 px at 2160p, ADR-0007 table).
  Whether text is re-rasterised at the physical size or scaled as a texture
  is NOT SOURCEABLE → **SP-16A**. Fallback if blurred at 2160p or 1440p:
  MSDF import of the same faces (one import setting, no code change, because
  every size goes through the theme). Second fallback: three prebuilt themes
  (ADR-0007 SP-3 fallback).
- **Two themes, one font:** `ui_theme.tres` (every UI type; sizes scaled by
  `UiTextScale` per ADR-0007 D7.4) and `subtitle_theme.tres` (types
  `SubtitleText`, `SubtitleSpeaker`; size from `subtitulos_tamano`, **never**
  scaled by `escala_texto_ui`).
- **Sizes (logical px, `assets/data/ui/text_sizes.json`):** UI title 44,
  header 32, body/options 28, secondary 24 (25 R13); footer 28 (24 R24);
  subtitles `pequeno`/`medio`/`grande` 24/32/44 (26 F3 as amended by
  ADR-0007 D7.2: `alto_logico = base_px`, no window factor, no run-time
  `max`). Glyph height = text line height (24 R12). Ring 28/48 px is an icon,
  not text, and is not scaled by `escala_texto_ui`.
- **Floor:** `A11yConstants.TEXT_MIN_PX` (24) enforced at **data-validation
  time** on both themes and `text_sizes.json` (ADR-0007 D7.3). BBCode
  `[font_size]` and `add_theme_font_size_override` on reading text are
  forbidden (CI grep).
- **Reflow:** every multi-line UI text uses `AUTOWRAP_WORD_SMART` (sourced)
  inside containers; nothing sets a fixed height on a text node. Menus
  scroll vertically when the content exceeds the safe rect at 1.50 (never
  clip, never shrink).

### D4 — Tokens `{accion:<id>}`, `TokenResolver` and `GlyphText`

Grammar (data from 18): `{accion:<id>}` where `<id>` is an action id of
ADR-0006's table, Unicode letters and `_` (the GDD literal `atrás` keeps its
accent). One resolver for 24, 26, 25 and 30:

1. `TokenResolver.resolve(text) -> Array[TextRun]` (pure; injected
   `BindingLabelSource`, `ContentDB`, `LogSink`). Each token becomes one
   `GLYPH` run `{glifo_id, texto}` from `get_binding_label(id, -1)`
   (ADR-0006 D13: derived actions already map to their base).
2. `{}` from `get_binding_label` → `TEXT` run with the action's display name
   `UI_ACCION_<ID>` ‡ from 18 (24 R27: «Atrás»), plus a warning log.
3. Unknown token kind (`{foo:…}`, unclosed `{`) → removed from the output,
   error log in dev; the ADR-0005 content validator rejects it in CI. A raw
   token or key is **never** shown.
4. **Cache by revision.** Callers keep `(text_key, revision)`; they re-resolve
   only when `bindings_revision()` differs (ADR-0006 D13; covers the title
   options path where `pause_closed` never fires) or on
   `input_device_changed` / `pause_closed` (TR-prompt-010). Re-resolution
   recomposes the node; it never resets a clock.
5. `GlyphText.render(rtl: RichTextLabel, runs, line_h_px)` is the **only**
   site calling `RichTextLabel` content APIs: a `GLYPH` run is an inline
   image `assets/ui/glyphs/<glifo_id>.png` sized to the line height
   (`add_image`, 4.7 units — SP-16D) **followed by** `texto` (a glyph is never
   alone, 24 R12). Missing texture → `texto` in a framed text run, logged.
6. Character counting for 7's `duracion_pie` keeps "a token counts as one
   character" (24 R23); 23's `n_car` for `t_lectura_s` excludes tokens and
   brackets (26 F1). `TokenResolver.count_for_footer()` /
   `count_for_reading()` expose both so neither caller re-parses.

### D5 — Subtitles (26): three pure classes and a thin view

**Ownership split.** `SubtitleTimeline` (state machine, times),
`SubtitlePaginator` (text → pages) and `SubtitleBand` (F3/F4 geometry) are
pure `RefCounted`s with no engine calls; `SubtitlesLayer` (the `CanvasLayer`)
only subscribes, forwards notices with `now = GameClock.now()`, and draws
what `SubtitleTimeline.visible_blocks()` returns. 26 subscribes and never
emits (TR-subs-001).

**Notices consumed (ADR-0001 names).** `line_requested` (`line_id`,
`fallback_s?`), `line_started` (`line_id`, `duracion_s`, `canal`),
`line_finished` (`line_id`, `motivo`), `line_no_audio` / `line_failed`
(`line_id`, `t_lectura_s`), `sound_requested` (only a `sound_id` with a
`SUB_*` key in 18; actions `play`/`stop`/`interrupt`), `pause_opened`,
`pause_closed`, `scene_load_started`, `full_unload_requested`,
`input_context_changed` (`contexto == llamada` retires the buzz subtitle,
26 R12), `input_device_changed` (token re-resolve), plus Settings changes of
`subtitulos_activos/tamano/fondo/hablante` and `reducir_movimiento`
(ADR-0007 `subscribe_change`).

**Block life cycle** (one `SubBlock` per line or sound):

```
 line_requested ─► PENDING ──line_started (T = duracion_s)──► SHOWING(page i) ──line_finished──► TAIL(t_cola_sub_s) ─► GONE
                     │                                            ▲          (min not met and motivo ≠ interrumpida/corte/watchdog: hold to min)
                     ├─ line_no_audio / line_failed ──────────────┘ (T = fallback_s, else t_lectura_s; ends at T, no TAIL)
                     └─ R8: no line_started and channel free ─► SHOWING at request time (degraded)
 scene_load_started / full_unload_requested ─► every block GONE at once, queue emptied, no fade (also while frozen)
```

Rules the timeline enforces (each traced to 26): appear in the frame of
`line_started` (R6, TR-subs-003); with audio, last page until
`max(t_fin + t_cola_sub_s, t_inicio + t_lectura_s)` (F1, R7);
`interrumpida` / `corte` / `watchdog` retire after `t_cola_sub_s` even under
the minimum (R11); no-audio/failed blocks last exactly `fallback_s` (or
`t_lectura_s`), never longer or shorter (R9); duplicate `line_id` ignored;
first of `line_started`/`line_no_audio`/`line_failed` wins, the second is
logged (Edge Cases); ≤ `sub_bloques_max` visible, newest at the bottom,
sound under voice (R15, R28); a third block replaces the oldest once its
yield minimum `min(t_lectura_s, ceder_min_s)` is met, queue of 1, overflow
drops the oldest with a log (R15); a sound subtitle waits ≤
`t_sub_sfx_espera_s` then drops (R28); `SFX_PHONE_BUZZ` once per loop start,
retired on `stop`/`interrupt`, on entering `llamada`, or at
`t_sub_sfx_lazo_s` (R12); `subtitulos_activos = false` keeps every clock
running and only stops drawing (R21).

**Time.** All times are `GameClock.now()` values. 26 also keeps its own
`_paused` flag from `pause_opened`/`pause_closed` (as 23 does, ADR-0008
D3.6) and shifts every pending deadline by the paused span — redundant with
the frozen `GameClock` on purpose, so TR-subs-008 never depends on the tree.
Fades are `alpha = f(now − t_fade_start)` computed in
`SubtitlesLayer._process`, so a fade freezes mid-way in pause although the
layer is `ALWAYS`. No `Tween` in 26.

**Pagination (`SubtitlePaginator`, 26 F2 + F3).**

1. Input: resolved runs of each segment (18: one segment, or `VO_G_07`'s A/B
   with optional `seg_b_inicio_s` ‡, ADR-0008 D11), window `T`,
   `car_linea = floor(sub_car_linea · base_medio / base_tam)` (56/42/30).
2. Segment windows: `P = pausa_segmento_s` only between segments;
   `t_i = (T − P) · n_i / Σn`. If `seg_b_inicio_s` exists: A =
   `[0, seg_b_inicio_s − P]`, B = `[seg_b_inicio_s, T]`.
3. Layout per segment: sentences (split after `.`, `?`, `!`, `…` + space)
   packed greedily into pages of ≤ `sub_lineas_max` lines of ≤ `car_linea`
   characters (word wrap by characters). A sentence that does not fit one
   page splits at word boundaries; a word longer than `car_linea` is
   hard-split (logged).
4. Page count ≥ `ceil(t_seg / t_sub_max_s)`; if layout gave fewer, the
   longest page splits at the word boundary nearest its middle until met.
5. Page duration ∝ characters. A page < `pagina_min_s` (1.0) merges with its
   neighbour if the merged text still fits 2 lines; otherwise it keeps 1.0 s
   and the difference comes from its longest neighbour (kept ≥ 1.0 s).
6. The character model is authoritative and deterministic (unit-tested). The
   renderer wraps with `AUTOWRAP_WORD_SMART`; in dev, a block whose rendered
   line count exceeds `sub_lineas_max` logs a warning (SP-16E). The font is
   never shrunk.
7. Size change mid-block: re-paginate the **remaining** time of the current
   segment from the current page; elapsed time is kept (R19).

Worked check (26 F2 example, `medio`): `VO_G_07`, `T` 14.0, `P` 1.2, A 26
chars → 2.73 s, B 96 chars → 10.07 s > 8.0 → 2 pages by sentences (≈ 4.93 s
and ≈ 5.14 s), each ≤ 2 × 42 chars. This exact case is a unit test.

**Band geometry (`SubtitleBand`, 26 F4 in logical px).** Band width =
`sub_ancho_pct` (60 %) of the **safe-column width** (D2: on 21:9 the band
stays 1152 px, so `car_linea` keeps its meaning); bottom margin =
`round(sub_margen_inf_pct · logical_h)`; `alto_banda = sub_lineas_max ·
sub_bloques_max · base_tam · 1.25 + 2 · sub_hueco_px`; `reserved_height_px =
alto_banda + bottom_margin` → 260 (`medio`) / 320 (`grande`) at 1080 logical,
268 / 328 at 1200 logical (16:10). `visible_top_px()` = top edge of the
highest **drawn** block minus `sub_hueco_px`, or `INF` when nothing is drawn
(also with `subtitulos_activos = false`: the footer never moves for
invisible blocks).

**`SubtitleBandQuery` (pull port, `UiPorts.subtitle_band`).**
`visible_top_px() -> float`, `reserved_height_px() -> float`. Read by 24 each
frame and by 22 when laying out answers. A query is not a notice, so
TR-subs-001 holds.

**Style (26 R16–R18).** Speaker `NOMBRE:` from `UI_SUB_HABLANTE_*` ‡ (always,
or only with 2 blocks when `subtitulos_hablante = false`); Vera's interior
voice in the Italic face, megafonía inside `«»`, Guardián plain; optional
name tint never the only channel; sounds inside `[ ]`, no speaker.
Backgrounds `opaco`/`translucido` (`sub_fondo_opacidad_min` 0.70†,
art-director confirms) target 7:1 against pure white and pure black;
`ninguno` uses a 2 px outline (theme outline constant on `SubtitleText` ‡,
NOT SOURCEABLE name → SP-16A) for 4.5:1. Fade `t_fundido_sub_s` 0.15 s, or
6's `reduce_motion_fade_s` 0.10 s (R20). Preview `UI_SUB_MUESTRA` ‡ is a
separate `SubtitlePreview` control in the options screen, same theme and
`SubtitleBand` math, never touching the game band or 23 (R26).

### D6 — Prompt (24): ring, label, footer, `HECHO` filter, coexistence with 26

- **Ring and label** (`InteractionPrompt`, HUD). Polls 7's `get_target()`
  once per render frame and draws only when `InputRouter.top() ==
  EXPLORACION` and the target is not null (TR-prompt-001/-002). Exact screen
  centre, 28 / 48 px (`icono_grande`), 80 % opacity, fades 250/150 ms,
  120 ms cross-fade on target change, 100 ms with `reducir_movimiento`;
  `360·p` clockwise fill from 12 o'clock (24 F1). Drawn procedurally in
  `_draw()` so it is crisp at every scale (`draw_arc` NOT SOURCEABLE —
  captured in SP-16A). Label = `GlyphText` of `interactuar` + 18 text.
- **Pulse filter on `interaction_executed` (ADR-0001 D11, G-12).** 24 is the
  **only** consumer that does not gate on `HECHO`: `HECHO` → accept pulse
  (0.80→1.00→0.80, 120 ms); `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO`
  → reject pulse (0.80→0.40→0.80); any other value → no pulse + error log.
  One notice = one pulse (TR-prompt-006). `PulseGate` drops a pulse starting
  < `pulso_min_intervalo_ms` (340; data validation rejects < 334) after the
  previous one, on `RealClock` (a perceptual limit); no queue
  (TR-prompt-007). The pulse starts in the handler's frame (≤ 100 ms).
- **Footer** (`FooterSlot` view + pure `FooterState`). Implements the
  `PromptSink` port of ADR-0009 D6 (`mostrar_pie`, `ocultar_pie`; signature
  in § Key Interfaces, closing ADR-0009 O2 for `PromptSink`). Single slot,
  last caller wins in a frame, 150/100 ms cross-fade; `PERSISTENTE` lives
  until `get_target().id` differs from the id at **draw** time; `retener`
  pending without expiry until another `retener` or a load; game-time clock;
  hidden and frozen outside `exploración`; object footers discarded on
  leaving through a 7 mode or `sin control` (24 R21–R28). Width ≤ 60 % of
  the safe column, ≤ 2 lines (3 for > `texto_max_caracteres`, with a data
  warning), 28 px body scaled by `escala_texto_ui`, 85 % panel.
- **Coexistence with 26 (24 R24, 26 R23, TR-prompt-016, TR-subs-015).** Each
  frame: `rest_y = safe_bottom − footer_h`; `top =
  subtitle_band.visible_top_px()`; target `y = min(rest_y, top − footer_h)`.
  When `y` changes, the footer moves over its own fade time (150/100 ms) by
  animating `offset_transform` (4.7, sourced: containers do not reset it).
  If `y < safe_top` the footer sits directly above the blocks and is
  clipped to 2 lines — the subtitle is never covered or moved. Ring and
  label never move. With no drawn block the footer rests at its anchor.

### D7 — Hint panel provider (17 → 25; closes QQ-19 part, ADR-0009 O2)

```gdscript
# src/systems/hints/ports/hint_panel_provider.gd
## Published by 17 in SceneServices.hint_panel; pulled by 25 (ADR-0009 D6).
@abstract class_name HintPanelProvider extends RefCounted
## false = the «Pistas» row does not exist in 25's root (never disabled).
@abstract func is_available() -> bool
## Builds 17's panel; 25 parents it under MenuLayer (level 2) and frees it on close.
@abstract func create_panel() -> HintPanel
```

```gdscript
# src/systems/hints/ports/hint_panel.gd
## Base of 17's panel. 25 owns ui_atrás/pausa; the panel never handles them.
@abstract class_name HintPanel extends Control
## First control 25 focuses when the panel is shown.
@abstract func initial_focus() -> Control
## Called by 25 right after the panel becomes visible.
@abstract func on_shown() -> void
## Called by 25 right before the panel is freed.
@abstract func on_hidden() -> void
```

25 pulls `ctx.scene.hint_panel` inside its bind window; with no bound scene
(title) or a `null` provider the row does not exist. The panel inherits
`ALWAYS` from `MenuLayer` and calls 17's synchronous API (`request_hint`
through 17's service) — synchronous calls into a `PAUSABLE` node work in
pause (ADR-0002 NS-13). `ui_atrás`/`pausa` return to the root with focus on
«Pistas» (25 R14); no hint counter is passed. On `unbind_scene` 25 frees an
open panel and drops the provider.

### D8 — `OptionsComponent` (25, reused by 27; closes QQ-19 part)

One instance, owned by `Shell` under `MenuLayer` (ADR-0002: `ALWAYS`
because 27 shows it with the tree running), exposed as `UiPorts.options`:

```gdscript
# src/ui/options/options_component.gd
## Level-2 options screens shared by 25 (pause) and 27 (title). Host-agnostic (25 R15).
class_name OptionsComponent extends Control
## Emitted once when the player leaves level 2 (ui_atrás, pausa or «Volver»).
signal cerrado(pantalla: StringName)
## pantalla ∈ {&"sonido_pantalla", &"accesibilidad", &"controles"}.
## pestana_inicial ∈ {&"", &"teclado_raton", &"mando", &"manejo"}, only for &"controles";
## &"" = tab of the active device (25 R19). Unknown value → log + default.
func mostrar(pantalla: StringName, pestana_inicial: StringName = &"") -> void: pass
## Host-forced close (e.g. Saliendo); emits nothing.
func ocultar() -> void: pass
func is_open() -> bool: return false
```

(The GDD's `pestaña_inicial` becomes `pestana_inicial`: identifiers stay
ASCII.) The component reads/writes only Settings (6) and InputRouter (1)
rebinding/handling APIs; it never reads pause state, emits `pause_*`,
flushes Settings or pauses time (25 R15). The host supplies the `menú`
context and the backdrop (25: `PauseVeil`; 27: its own background in
`SceneUi`) and restores focus to the row that opened the screen on
`cerrado`. Accessibility-tab rows and order come from 30's ordered list
(`assets/data/ui/a11y_tab.json` ‡, owner 30).

### D9 — Shared menu components (25, 27, 30, 17's panel)

`src/ui/menu/` — every menu is assembled from these; no screen writes its
own focus logic:

| Component | Behaviour | Traces |
|---|---|---|
| `MenuList` | Ordered rows **built from offered rows only** (absent rows do not exist, never disabled); `FocusChain.link_vertical(rows, wrap = false)`; owns the selection cursor (source of truth, ADR-0007 D8.3); initial focus and focus restore by row id | TR-pause-009/-010, TR-title-005 |
| `ButtonRow`, `ToggleRow`, `SelectorRow`, `SliderRow` | Value always as text («Sí»/«No», «Medio», «35 %», «Silencio»); per-row «Restablecer»; left/right step through `HoldRepeat` (D10); slider drag with mouse | 25 R11, R16; TR-pause-013 |
| `BindingRow` | Action name + 2 slots + «Restablecer»; slot text via `GlyphText`; «Sin asignar» | 25 R21 |
| `NoticeLine` | Non-focusable icon + text (never colour-only), `A11y.set_live(polite)`: «guardado en riesgo», «Mando desconectado/conectado», printable-key warning, 27's damaged-save line | 25 R17, R24, R27; TR-title-011 |
| `ConfirmDialog` | Modal; initial focus «Cancelar»; `ui_atrás` = Cancel | 25 R10, R18, R28, R30 |
| `MessageDialog` | Single «Aceptar» | 25 R23 |
| `CaptureDialog` | One input; `guarda_captura_s`, `t_captura_s` and text countdown on `RealClock` (25 F2); events via `UiEventReader` | 25 R22 |
| `WarningsScreen` | 27's «Antes de empezar»: header + 5 `UI_…` entries, no countdown or auto-advance, «Salir del juego» always; reused read-only from «Avisos de contenido» | TR-title-002 |

**Focus and hover (dual focus).** Keyboard/gamepad: `grab_focus()`
(sourced). Mouse hover over a row moves the `MenuList` cursor and calls
`grab_focus()`; click moves and activates (25 R9, TR-pause-009, ADR-0006
D9). The virtual cursor goes through the same path via
`PointerTargetProvider.on_hover`. The visible focus ring is drawn from the
cursor (border ≥ 3:1 + shape), never from engine hover styling. This
**overrides ADR-0007 D8.3's "hover must not move the cursor"**
(contradiction C2). Focus stops at the first/last row (no wrap).

**Text.** Every label is an 18 key (`UI_PAUSA_*`, `UI_TITULO_*`, …) through
`ContentDB`, tokens through D4; no literals in `src/ui/` (CI grep).
Accessible name = visible text via `A11y.set_accessible_name` on build and
on every text change.

### D10 — Held repetition and echo suppression (closes ADR-0006 OI-4)

`HoldRepeat` (pure, injected `RealClock`) implements 25 F1: `press(dir)` →
one immediate step; `tick(now)` → one step at each `t_ini + k·t_rep`
crossed (`repeticion_inicial_s` 0.4†, `repeticion_s` 0.12†, from
`pause.json`); `release()` / `cancel()` stop. It is ticked by the focused
row's `_process` (under an `ALWAYS` layer: runs in pause and on the title).

`UiEventReader` is the **only** site reading `InputEvent` for UI. In
`SliderRow`/`SelectorRow._gui_input` it maps `ui_left`/`ui_right` press →
`press`, release → `release`, **drops every echo event**, and consumes the
event so native focus navigation does not also act (all NOT SOURCEABLE →
SP-16C). Cancellation without a release event: focus change,
`input_context_changed`, window focus loss (ADR-0006 adapter
`window_focus_changed`), `cerrado`. «Alternar en lugar de mantener» does not
affect it (25 R12). There is no repetition on `ui_up`/`ui_down`: echoes are
dropped there too, so holding never scrolls into a destructive row.

### D11 — Accessibility hooks (ADR-0007 D8 single sites)

26's block container: `A11y.set_live(block, true)` with name = speaker +
text. 25's header line and every `NoticeLine`: `set_live(polite)`.
`A11y.set_unavailable` for the «Quitar» slot command (25 R24). No contrast
or size logic at run time: contrast is art-direction data verified by AC-30
captures; sizes are validated in CI (D3).

### D12 — Data files (`assets/data/ui/`, validated per ADR-0005)

| File | Owner | Keys (‡ = named here) |
|---|---|---|
| `text_sizes.json` | 30 / ADR-0007 | UI theme entries `(name, theme_type, base_px)` |
| `subtitles.json` ‡ | 26 | `t_cola_sub_s`, `t_sub_max_s`, `pagina_min_s`, `sub_ancho_pct`, `sub_margen_inf_pct`, `sub_lineas_max`, `sub_car_linea`, `sub_bloques_max`, `ceder_min_s`, `sub_hueco_px`, `bases_px {pequeno, medio, grande}`, `t_fundido_sub_s`, `t_sub_sfx_min_s`, `t_sub_sfx_lazo_s`, `t_sub_sfx_espera_s`, `sub_fondo_opacidad_min` |
| `prompt.json` | 24 | ring sizes, fades, pulse depth, `pulso_min_intervalo_ms`, `latencia_feedback_ms`, footer size/opacity/width, `texto_max_caracteres` |
| `pause.json` | 25 | `repeticion_inicial_s`, `repeticion_s`, `guarda_captura_s`, `t_captura_s`, `t_velo_s`, `t_velo_reducido_s`, `guarda_apertura_s` |
| `ui_layout.json` ‡ | this ADR | `margen_seguro_pct` (0.05) |

`pausa_segmento_s`, `t_min_lect_s`, `cps_lect`, `t_max_lect_s` are 23's
(F3 of 23); 26 reads them through 23's `ReadTime` config object and never
duplicates them.

### Architecture Diagram

```
 Shell (main scene, never unloaded) ─ layer order bottom → top
 ┌──────────────────────────────────────────────────────────────────────────────────────┐
 │ 0  world 3D                                                                          │
 │ 5  SceneUi (in WorldSlot, PAUSABLE): 27 title/warnings · 19 computer · 22 answers ──┐ │
 │10  HUD (PAUSABLE): InteractionPrompt(24) · HintNote(17) · ReadingScreen(20)         │ │
 │        ▲ get_target() (7)    ▲ visible_top_px()        reserved_height_px() ◄───────┘ │
 │20  PauseVeil (ALWAYS, 25, RealClock fade)              │                              │
 │30  Subtitles (ALWAYS, 26, GameClock) ── SubtitleBandQuery (UiPorts.subtitle_band)    │
 │        SubtitlesLayer ─► SubtitleTimeline ─► SubtitlePaginator ─► SubtitleBand       │
 │40  MenuLayer (ALWAYS): PauseMenu(25) · HintPanel(17, pulled) · OptionsComponent ◄─27 │
 │50  CursorLayer (ALWAYS, 1) · 60 Curtain (4) · 70 ErrorPanel (4)                       │
 └──────────────────────────────────────────────────────────────────────────────────────┘
 Bus (ADR-0001) ─► 26: line_* · sound_requested · pause_* · scene_load_started · full_unload_requested
                ─► 24: interaction_executed (all four resultado) · input_device_changed · pause_closed
 InputRouter (1) ─► TokenResolver/GlyphText: get_binding_label · bindings_revision
 Settings (6)    ─► UiTextScale (ui_theme only) · 26 subtitle_theme · 24 flags
 ViewportProbe (only engine site) ─► ViewportMapper ─► SafeAreaMath ─► every layout
```

### Key Interfaces

```gdscript
# src/ui/ui_layers.gd
## Draw order of every CanvasLayer (D1). Structure, not gameplay data.
class_name UiLayers extends RefCounted
const SCENE_UI: int = 5
const HUD: int = 10
const PAUSE_VEIL: int = 20
const SUBTITLES: int = 30
const MENU: int = 40
const CURSOR: int = 50
const CURTAIN: int = 60
const ERROR: int = 70

## Sets layer + process_mode explicitly (ADR-0002: never inherited from Shell).
static func configure(cl: CanvasLayer, layer: int, mode: Node.ProcessMode) -> void:
	cl.layer = layer                 # NOT SOURCEABLE (SP-16B)
	cl.process_mode = mode
```

```gdscript
# src/ui/layout/safe_area_math.gd
## Pure safe-rect math (D2).
class_name SafeAreaMath extends RefCounted
static func safe_rect(logical: Vector2, margin_pct: float) -> Rect2:
	var col: Rect2 = Rect2(Vector2.ZERO, logical)
	if logical.x / logical.y > 16.0 / 9.0:
		var w: float = logical.y * 16.0 / 9.0
		col = Rect2(Vector2((logical.x - w) * 0.5, 0.0), Vector2(w, logical.y))
	var inset: Vector2 = col.size * margin_pct          # plain arithmetic, no engine helper
	return Rect2(col.position + inset, col.size - inset * 2.0)

# src/ui/layout/viewport_mapper.gd
@abstract class_name ViewportProbe extends RefCounted
@abstract func logical_size() -> Vector2            # EngineViewportProbe: only engine site (SP-16B)
@abstract func window_to_logical(p: Vector2) -> Vector2

class_name ViewportMapper extends RefCounted
func _init(probe: ViewportProbe, margin_pct: float) -> void: pass
func logical_rect() -> Rect2: return Rect2()
func safe_rect() -> Rect2: return Rect2()
func window_to_logical(p: Vector2) -> Vector2: return p
```

```gdscript
# src/ui/text/text_run.gd
class_name TextRun extends RefCounted
enum Kind { TEXT, GLYPH }
var kind: Kind = Kind.TEXT
var text: String = ""            # TEXT: literal; GLYPH: label texto (always shown)
var glifo_id: StringName = &""

# src/ui/text/binding_label_source.gd — adapter over InputRouter (ADR-0006 D13); Fake in tests
@abstract class_name BindingLabelSource extends RefCounted
@abstract func get_binding_label(accion: StringName, dispositivo: int = -1) -> Dictionary
@abstract func bindings_revision() -> int

# src/ui/text/token_resolver.gd
## Expands {accion:<id>} tokens (D4). Pure; never shows a raw token.
class_name TokenResolver extends RefCounted
func _init(labels: BindingLabelSource, content: ContentDB, log: LogSink) -> void: pass
func resolve(text: String) -> Array[TextRun]: return []
func revision() -> int: return 0
func count_for_footer(text: String) -> int: return 0     # token = 1 char (24 R23)
func count_for_reading(text: String) -> int: return 0    # tokens and [ ] excluded (26 F1)

# src/ui/text/glyph_text.gd
## The ONLY site writing RichTextLabel content (SP-16D).
class_name GlyphText extends RefCounted
static func render(rtl: RichTextLabel, runs: Array[TextRun], line_h_px: float) -> void: pass
```

```gdscript
# src/ui/subtitles/subtitle_band_query.gd — UiPorts.subtitle_band
@abstract class_name SubtitleBandQuery extends RefCounted
## Logical y of the top of drawn blocks minus sub_hueco_px; INF when none drawn.
@abstract func visible_top_px() -> float
## 26 F4 alto_reservado_px for the current size and logical height.
@abstract func reserved_height_px() -> float

# src/ui/subtitles/subtitle_page.gd
class_name SubtitlePage extends RefCounted
var lines: PackedStringArray = PackedStringArray()
var start_s: float = 0.0         # relative to the block window start
var dur_s: float = 0.0

# src/ui/subtitles/subtitle_paginator.gd — pure (D5)
class_name SubtitlePaginator extends RefCounted
func _init(cfg: SubtitleConfig) -> void: pass
## segments: one String per 18 segment (tokens already resolved to plain text).
func paginate(segments: PackedStringArray, window_s: float, size_id: StringName,
		seg_b_start_s: float = -1.0) -> Array[SubtitlePage]: return []
func chars_per_line(size_id: StringName) -> int: return 0

# src/ui/subtitles/subtitle_timeline.gd — pure state machine (D5); now = GameClock.now()
class_name SubtitleTimeline extends RefCounted
func _init(cfg: SubtitleConfig, paginator: SubtitlePaginator, text: LineTextSource,
		read_time: ReadTime, log: LogSink) -> void: pass
func on_line_requested(line_id: StringName, fallback_s: float, now: float) -> void: pass
func on_line_started(line_id: StringName, duracion_s: float, canal: StringName, now: float) -> void: pass
func on_line_finished(line_id: StringName, motivo: StringName, now: float) -> void: pass
func on_line_no_audio(line_id: StringName, t_lectura_s: float, now: float) -> void: pass
func on_sound(sound_id: StringName, accion: StringName, now: float) -> void: pass
func on_pause(paused: bool, now: float) -> void: pass
func on_context(contexto: StringName, now: float) -> void: pass
func clear_all() -> void: pass                       # load / full unload: no fade
func set_size(size_id: StringName, now: float) -> void: pass
func step(now: float) -> void: pass
func visible_blocks(now: float) -> Array[SubBlockView]: return []   # ≤ sub_bloques_max, oldest first

class_name SubBlockView extends RefCounted
var speaker_key: StringName = &""                    # &"" for sounds
var style: StringName = &"plain"                     # &"italic" | &"guillemets" | &"plain" | &"bracket"
var lines: PackedStringArray = PackedStringArray()
var alpha: float = 1.0
```

```gdscript
# src/interaction/ports/prompt_sink.gd — signature fixed here (ADR-0009 O2)
@abstract class_name PromptSink extends RefCounted
const PERSISTENTE: float = -1.0
@abstract func mostrar_pie(clave: StringName, duracion_s: float, retener: bool = false) -> void
@abstract func ocultar_pie() -> void

# src/ui/prompt/pulse_gate.gd — pure, RealClock injected (TR-prompt-007)
class_name PulseGate extends RefCounted
enum Pulse { NONE, ACCEPT, REJECT }
func _init(clock: RealClock, min_interval_ms: int) -> void: pass
func classify(resultado: StringName) -> Pulse: return Pulse.NONE
func try_start(p: Pulse) -> bool: return false

# src/ui/menu/hold_repeat.gd — pure, RealClock injected (25 F1)
class_name HoldRepeat extends RefCounted
signal stepped(dir: int)
func _init(clock: RealClock, t_ini: float, t_rep: float) -> void: pass
func press(dir: int) -> void: pass
func release() -> void: pass
func cancel() -> void: pass
func tick() -> void: pass

# src/ui/menu/ui_event_reader.gd — the ONLY site reading InputEvent for UI (SP-16C)
class_name UiEventReader extends RefCounted
enum Kind { NONE, PRESS, RELEASE }
static func horizontal(ev: InputEvent) -> Vector2i: return Vector2i.ZERO   # (dir, Kind); echo → NONE

# src/core/composition/ui_ports.gd — additions to ADR-0009's UiPorts
# var subtitle_band: SubtitleBandQuery   (NullSubtitleBand: visible_top INF, reserved 0)
# var options: OptionsComponent           (hosted by 25, used by 27)
```

### Reference pseudocode

```gdscript
# SubtitlePaginator.paginate — F2 windows, then pages (D5 steps 2–5)
func paginate(segments: PackedStringArray, window_s: float, size_id: StringName,
		seg_b_start_s: float = -1.0) -> Array[SubtitlePage]:
	var out: Array[SubtitlePage] = []
	var cpl: int = chars_per_line(size_id)
	var pause: float = _cfg.pausa_segmento_s if segments.size() > 1 else 0.0
	var windows: Array[Vector2] = _segment_windows(segments, window_s, pause, seg_b_start_s)
	for i in segments.size():
		var w: Vector2 = windows[i]                       # (start, duration)
		var pages: Array[PackedStringArray] = _layout(segments[i], cpl)
		while pages.size() < ceili(w.y / _cfg.t_sub_max_s):
			pages = _split_longest(pages, cpl)
		var timed: Array[SubtitlePage] = _distribute(pages, w)   # ∝ chars, ≥ pagina_min_s
		out.append_array(timed)
	return out

func _segment_windows(segs: PackedStringArray, t: float, p: float, b0: float) -> Array[Vector2]:
	if segs.size() == 1:
		return [Vector2(0.0, t)]
	if b0 >= 0.0:
		return [Vector2(0.0, b0 - p), Vector2(b0, t - b0)]
	var n_a: int = segs[0].length()
	var n_b: int = segs[1].length()
	var t_a: float = (t - p) * n_a / float(n_a + n_b)
	return [Vector2(0.0, t_a), Vector2(t_a + p, t - p - t_a)]
```

```gdscript
# SubtitleTimeline — key transitions
func on_line_started(line_id: StringName, duracion_s: float, _canal: StringName, now: float) -> void:
	var b: SubBlock = _pending.get(line_id)
	if b == null or b.state != SubBlock.State.PENDING:
		_log.line(&"warn", "line_started for %s ignored (first signal wins)" % line_id); return
	b.start(now, duracion_s, _paginator.paginate(_text.segments(line_id), duracion_s,
		_size, _text.seg_b_start(line_id)))
	b.min_end = now + _read_time.for_line(line_id)      # t_lectura_s of 23 (F1)
	_admit(b, now)                                      # ≤ 2 visible; queue of 1; yield min

func on_line_finished(line_id: StringName, motivo: StringName, now: float) -> void:
	var b: SubBlock = _find(line_id)
	if b == null: return                                # never born: no late block (Edge Cases)
	var cut: bool = motivo in [&"interrumpida", &"corte", &"watchdog"]
	var end: float = now + _cfg.t_cola_sub_s
	b.end_at = end if cut else maxf(end, b.min_end)

func on_pause(paused: bool, now: float) -> void:
	if paused == _paused: return
	_paused = paused
	if paused: _paused_at = now
	else: _shift_all(now - _paused_at)                  # ~0 with GameClock frozen; guards TR-subs-008

func step(now: float) -> void:
	if _paused: return
	for b in _visible.duplicate():
		if b.end_at >= 0.0 and now >= b.end_at: _retire(b, now)
	_promote_queue(now)
```

```gdscript
# InteractionPrompt (24) — per-frame, HUD (PAUSABLE)
func _process(_delta: float) -> void:
	var now: float = _clock.now()
	if _labels.bindings_revision() != _rev:              # int compare, no query (TR-prompt-010)
		_rev = _labels.bindings_revision(); _resolve_glyphs()
	var t: Variant = _interaction.get_target()
	_ring.update(t, _input.top() == InputTypes.Context.EXPLORACION, now)
	var top: float = _band.visible_top_px()
	var rest_y: float = _mapper.safe_rect().end.y - _footer.height()
	_footer.move_to(minf(rest_y, top - _footer.height()), now)   # offset_transform, own fade

func _on_interaction_executed(p: Dictionary) -> void:
	var pulse: PulseGate.Pulse = _gate.classify(p.get(&"resultado", &""))
	if pulse == PulseGate.Pulse.NONE:
		_log.line(&"error", "interaction_executed: unknown resultado"); return
	if _gate.try_start(pulse): _ring.pulse(pulse, _clock.now())
```

```gdscript
# SliderRow / SelectorRow (25, 27, 30)
func _gui_input(ev: InputEvent) -> void:
	var h: Vector2i = UiEventReader.horizontal(ev)        # echo already dropped
	if h.y == UiEventReader.Kind.PRESS: _repeat.press(h.x); accept_event()   # NOT SOURCEABLE
	elif h.y == UiEventReader.Kind.RELEASE: _repeat.release(); accept_event()

func _process(_delta: float) -> void:
	if has_focus(): _repeat.tick()                      # has_focus(): NOT SOURCEABLE (ADR-0007 SP-4)
	else: _repeat.cancel()
```

### Implementation Guidelines

- **G-1** Every `CanvasLayer` **must** be configured through
  `UiLayers.configure()`; no literal `layer =` elsewhere (CI grep).
- **G-2** 24 and 26 **must** take time only from injected `GameClock`; 25,
  `HoldRepeat`, `PulseGate`, `CaptureDialog` and the veil **must** use
  `RealClock`. No `Tween`, `Timer` or `create_timer` in `src/ui/subtitles/`
  or `src/ui/prompt/` (CI grep).
- **G-3** NOT SOURCEABLE APIs live in exactly one file each:
  `UiLayers.configure` (layer), `EngineViewportProbe` (viewport),
  `GlyphText` (`RichTextLabel` content), `UiEventReader` (`InputEvent`),
  `RingView._draw` (`draw_arc`). No other file may name them.
- **G-4** No script **may** compute a window/1080 factor or write
  `content_scale_factor`; all sizes are logical (ADR-0007 D7).
- **G-5** Reading text **must** come from 18 keys; raw tokens/keys **must
  never** reach the screen; `[font_size]` BBCode and per-node font-size
  overrides on reading text are forbidden.
- **G-6** 26 **must never** emit a notice or call 23/21/9/22;
  `SubtitleBandQuery` is its only outward surface.
- **G-7** 24 **must** treat all four `resultado` values; every other
  consumer of `interaction_executed` keeps ADR-0001 G-12's `HECHO` gate.
- **G-8** Menus **must** be built from `src/ui/menu/` components; a row not
  offered is not instantiated (never `disabled` to hide an option).
- **G-9** `OptionsComponent` **must not** reference `PauseMenu`, `pause_*`,
  `GameClock` or `Settings.flush`.
- **G-10** 17's panel **must** be created through `HintPanelProvider` and
  freed by 25; 17 never references 25.
- **G-11** Every UI story **must** be evidenced with screenshots at 1280×720,
  1920×1080 and 3840×2160 (plus 2560×1080 for HUD/subtitles) with both
  `escala_texto_ui` 1.00 and 1.50, after SP-16A passes.

## Alternatives Considered

### Alternative 1: Veil inside `PauseMenu`, subtitles above the whole menu

- **Description**: Keep the tree of `architecture.md`; give `Subtitles` a
  higher layer than `PauseMenu`.
- **Pros**: One layer fewer; subtitles never occluded.
- **Cons**: Frozen subtitles draw over menu panels and dialogs (bottom rows of
  the options screens, capture dialog), harming 25's legibility and focus
  visibility; preview sample would compete with real blocks.
- **Estimated Effort**: Slightly lower.
- **Rejection Reason**: 25's operability (TR-pause-009/-022) outranks
  seeing frozen blocks; 26 R22 only requires "over the veil".

### Alternative 2: Subtitles push their top edge as a notice to 24

- **Description**: 26 emits «banda de subtítulos cambiada» on the bus.
- **Pros**: 24 does no per-frame read.
- **Cons**: Breaks TR-subs-001 (26 emits nothing); adds a registry entry and
  a delivery-order dependency for a value that changes every fade frame.
- **Estimated Effort**: Similar.
- **Rejection Reason**: A pull query costs one float read per frame and keeps
  26's contract intact.

### Alternative 3: Pixel-measured pagination with the engine's text server

- **Description**: Paginate by measuring rendered width of each word.
- **Pros**: Exact fit for a proportional font.
- **Cons**: Text measurement APIs are NOT SOURCEABLE; results depend on
  font rasterisation and scale, so tests become non-deterministic and
  headless-fragile.
- **Estimated Effort**: Higher.
- **Rejection Reason**: 26 already specifies characters per line; the
  character model is deterministic; SP-16E checks it against rendering.

### Alternative 4: Native echo / `HSlider` built-in stepping for repetition

- **Description**: Let OS key repeat and `HSlider` handle held arrows.
- **Pros**: No code.
- **Cons**: OS repeat rate is user-configured and differs from 0.4/0.12 s;
  gamepad D-pad has no OS echo, so devices would diverge (25 R9).
- **Estimated Effort**: Lower.
- **Rejection Reason**: TR-pause-013 fixes real-time values per device.

### Alternative 5: Separate `OptionsComponent` instances for title and pause

- **Description**: 27 instantiates its own copy in `SceneUi`.
- **Pros**: No cross-host sharing.
- **Cons**: A `PAUSABLE` copy inside `WorldSlot` (fine on title) but two live
  instances risk divergent state and double `subscribe_change`; ADR-0002
  already placed the component `ALWAYS` in Shell.
- **Estimated Effort**: Similar.
- **Rejection Reason**: One instance matches ADR-0002/0009 and 25 R15.

## Consequences

### Positive

- One numbered layer table; process modes match ADR-0002 exactly.
- Subtitle and prompt logic is pure and unit-testable without a scene tree.
- All glyph, viewport, layer and UI-input engine surfaces are one file each.
- Pause and title share one options implementation and one menu kit.
- The footer never covers a subtitle; 22 gets a numeric band cap.

### Negative

- One extra `CanvasLayer` (`PauseVeil`) and a level-2 panel can hide frozen
  subtitles.
- Character-based pagination may wrap differently from the rendered font on
  edge cases (warning only).
- 24 reads `bindings_revision()` and `visible_top_px()` every frame
  (negligible cost, but a per-frame dependency on two ports).
- Overrides ADR-0007 D8.3 on hover (amendment needed).

### Neutral

- Fonts may switch to MSDF after SP-16A with no code change.
- The GDD's `pestaña_inicial` is spelt `pestana_inicial` in code.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Text blurry at 1440p/2160p under `canvas_items` (SP-16A) | Low | High | MSDF import; then three prebuilt themes |
| `CanvasLayer` order or `ALWAYS` input differs from expectation (SP-16B) | Low | High | Spike before any UI story; layer numbers are one constant file |
| Echo cannot be told apart, or `accept_event` does not stop native focus moves (SP-16C) | Medium | Medium | Rows set `focus_mode` to keep focus and handle left/right fully; fall back to polling held state through ADR-0006's router observation of `ui_*` |
| `add_image` inline alignment poor (SP-16D) | Medium | Low | Glyph as framed text run (always accompanied by `texto` anyway) |
| Character model wraps to 3 rendered lines with `grande` | Medium | Low | Dev warning; lower `sub_car_linea` in data; never shrink font |
| Lines played under the curtain are invisible (OI-4) | Low | Medium | 21/ADR-0017 must not start lines before curtain lift |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| subtitulos.md (26) | TR-subs-001…002: subscribe-only, notice list | D5 notices; G-6; `SubtitleBandQuery` is a pull |
| subtitulos.md | TR-subs-003…007: sync, degradation, no-audio, F1 visible time, F2 pagination, `VO_G_07` | D5 life cycle, paginator steps 1–7, worked check |
| subtitulos.md | TR-subs-008…010: own game clocks frozen in pause, hidden-but-counting, clear on load/full unload | D5 Time, `on_pause`, `clear_all` |
| subtitulos.md | TR-subs-011: every context and over the veil | D1 layer 30 `ALWAYS` above `PauseVeil` |
| subtitulos.md | TR-subs-012…015: band, blocks, size, reserved band | D5 band geometry; D3 sizes (F3 per ADR-0007) |
| subtitulos.md | TR-subs-016…019: contrast, speaker channels, fades, settings | D5 Style; D11 |
| subtitulos.md | TR-subs-020…021: sound subtitles, preview | D5 rules (R12, R28), `SubtitlePreview` |
| prompt-de-interaccion.md (24) | TR-prompt-001…004: polling, contexts, ring, fill | D6 ring |
| prompt-de-interaccion.md | TR-prompt-005…007: pulses from `interaction_executed`, four results, 340 ms cap | D6 `PulseGate`, G-7 |
| prompt-de-interaccion.md | TR-prompt-008…010, -017: label, glyph from `get_binding_label`, re-resolve, `{accion:atrás}` | D4, D6 |
| prompt-de-interaccion.md | TR-prompt-011…016: footer API, slot, duration, context rules, legibility, coexistence with 26 | D6 footer, `PromptSink`, coexistence rule |
| prompt-de-interaccion.md | TR-prompt-018…020: scale, settings, no colour/state/audio, data file | D2, D3, D12 (F2 re-read per ADR-0007) |
| menu-de-pausa.md (25) | TR-pause-009…011: dual focus, initial focus/return, veil fade | D9 `MenuList`, hover rule; D1 `PauseVeil` (`RealClock`) |
| menu-de-pausa.md | TR-pause-013: held repetition 0.4/0.12 s real time | D10 |
| menu-de-pausa.md | TR-pause-022: `UI_PAUSA_*`, ≥ 24 px, reflow, safe margins, contrast | D3, D9 Text, D2 |
| pantalla-de-titulo.md (27) | TR-title-002: warnings screen | D9 `WarningsScreen` |
| pantalla-de-titulo.md | TR-title-005: rows not offered do not exist | D9 `MenuList`, G-8 |
| pantalla-de-titulo.md | TR-title-011: non-modal damaged-save line | D9 `NoticeLine` |
| menu-de-pausa.md / sistema-de-pistas.md | QQ-19: hint panel provider; `OptionsComponent.mostrar` + `cerrado` | D7, D8 |
| opciones-de-accesibilidad.md (30) | 24 px floor, reflow at 1.50, AccessKit hooks | D3, D11 (with ADR-0007) |

## Performance Implications

- **CPU**: steady state ≤ 0.3 ms/frame for 24 + 26 (two port reads, ≤ 2
  blocks, alpha updates). Pagination runs once per line start / size change
  (≤ 200 chars, < 0.1 ms). Glyph re-render only on revision change.
- **Memory**: two themes, three font faces (dynamic cache; MSDF atlas if
  adopted ≈ a few MB), glyph textures < 1 MB.
- **Load Time**: fonts load at Boot with Shell; no per-scene UI load.
- **Network**: none.

## Migration Plan

No code exists. `architecture.md` § tree gains `PauseVeil` and layer
numbers (listed in § Open Items; not edited here).

**Rollback plan**: layer numbers, fonts and pagination parameters are
constants/data; reverting to Alternative 1 changes `UiLayers` and removes
`PauseVeil` (one file + one node).

## Validation Criteria

### Spikes (short, on Godot 4.7.2; SP-16A shares ADR-0007's SP-1/SP-3 probe)

| ID | Question | Method | Pass | Fallback |
|---|---|---|---|---|
| SP-16A | Font crispness and ring under `canvas_items` + `fractional` | Probe scene: Atkinson Regular/Italic at 24/28/32/44 logical, outline 2 px, ring 28/48; screenshots at 1280×720, 1920×1080, 2560×1440, 3840×2160; dynamic vs MSDF | No visible blur or uneven stems at 1440p/2160p by lead + art-director review of retained captures; outline intact | MSDF; then three prebuilt themes |
| SP-16B | Layer order, `ALWAYS`/`PAUSABLE` per layer, viewport probe | Shell mock with the 8 layers, pause on/off, 21:9 and 16:10 windows | Draw order as D1; `PAUSABLE` HUD frozen, Subtitles/Menu running; mapper matches cursor ±1 px | Adjust constants; probe uses alternate viewport API |
| SP-16C | Echo detection and event consumption for `ui_left/right` | Hold arrow / D-pad / stick on `SliderRow` 3 s | Steps = F1 (±1) on every device; no extra native focus move | Poll held state via router observation |
| SP-16D | `add_image` inline glyph alignment and units | `GlyphText` with key and pad glyphs at 3 sizes | Glyph height = line height ±2 px, baseline aligned | Framed text run |
| SP-16E | Character model vs rendered lines | All slice subtitle lines × 3 sizes | ≤ 2 rendered lines per page for ≥ 98 % pages; zero clipping | Lower `sub_car_linea` in data |

### Test Plan (`tests/unit/ui/`, `tests/integration/ui/`; GdUnit4)

| Test file | Covers |
|---|---|
| `tests/unit/ui/test_safe_area_math.gd` | 16:9, 21:9, 16:10 safe rects; 5 % insets |
| `tests/unit/ui/test_subtitle_paginator.gd` | F2 `VO_G_07` example (2.73 / 1.2 / 4.93 / 5.14 s); `seg_b_inicio_s` path; `ceil(T/8)` pages; ≥ 1.0 s merge/borrow; 56/42/30 chars; deterministic twice |
| `tests/unit/ui/test_subtitle_timeline.gd` | TR-subs-003…010, -013, -020: appear on `line_started`; tail 0.4 s; min `t_lectura_s`; cuts ignore min; no-audio = `fallback_s` exactly; R8 degradation; first signal wins; duplicates; 3rd block queue/yield/drop; sound under voice and 2.0 s drop; buzz once per loop; pause freezes (including mid-fade); `clear_all` while frozen; disabled keeps counting |
| `tests/unit/ui/test_subtitle_band.gd` | F4 260/320 at 1080, 268/328 at 1200; `visible_top_px` INF when none drawn or disabled |
| `tests/unit/ui/test_token_resolver.gd` | `{accion:atrás}` → glyph + text; `{}` → `UI_ACCION_ATRAS` + warn; unknown token removed; counts footer vs reading; revision caching |
| `tests/unit/ui/test_pulse_gate.gd` | Four results mapping; unknown → none; 340 ms gate with fake `RealClock`; no queue |
| `tests/unit/ui/test_footer_state.gd` | 24 R21–R28: single slot, last wins, `PERSISTENTE` vs draw-time id, `retener` pending, context discard rules, game-time freeze |
| `tests/unit/ui/test_footer_lift.gd` | `y = min(rest, top − h)`; clip to 2 lines when out of safe rect; never overlaps blocks |
| `tests/unit/ui/test_hold_repeat.gd` | F1: immediate step; 1.03 s → 6 repeats (±1); 20 steps ≈ 2.56 s; release/cancel |
| `tests/unit/ui/test_menu_list.gd` | Offered rows only; no wrap; initial focus; restore by id; hover moves cursor |
| `tests/unit/ui/test_options_component.gd` | `mostrar` screens/tabs, default tab = active device, `cerrado` once, no `pause_*`, no flush |
| `tests/integration/ui/test_ui_layers.gd` | Layer constants and process modes of Shell nodes (ADR-0002 table) |
| `tests/integration/ui/test_hint_panel_pull.gd` | Row absent without provider/title; panel freed on close and on unbind |
| `tests/integration/ui/test_subtitles_bus.gd` | Real `GameState` bus: notices → blocks in the same frame (±1); 26 emits nothing (spy) |
| Data validation (CI) | Theme and `text_sizes.json` ≥ 24; `pulso_min_intervalo_ms` ≥ 334; font coverage of all 18 UI/subtitle strings; no `[font_size]` |
| Visual evidence (`production/qa/evidence/`) | G-11 resolutions × scales for HUD, subtitles (3 sizes × 3 backgrounds), pause, options, title |

### We will know this was right if

- No UI story needs a layer number or timer not in this ADR.
- Every subtitle AC of 26 passes from unit tests without a scene tree.
- SP-16A captures show crisp text at 720p–2160p with no code change.
- Playtest never reports a footer over a subtitle or an un-readable page.

## Spike Results (2026-11-11)

Godot 4.7.2 stable, Windows, Vulkan Forward+. Headless: `tests/unit/engine_facts/adr0016_ui_text_and_layers_test.gd`
(9 tests, all PASS, run alone). Windowed: `prototypes/ui-spike/` with `--write-movie` (engine frames only);
retained frames in `production/qa/evidence/ui-spike/ui-spike_<W>x<H>.png`. The status of this ADR stays `Proposed`.

| Spike | Result | Observed value | Fallback needed |
|---|---|---|---|
| SP-16A | PASS (provisional font) | Dynamic font re-rasterised at the final size under `canvas_items` + `expand` + `fractional`. Cap height of `H` measured in real px (font 24/32/44 logical): 720p 12/17/21; 1080p 17/23/31; 1440p 23/30/42; 2160p 35/45/64 (ideal 0.714 × size × s = 34.3/45.7/62.8). Edge transition (intermediate-luminance run on a stem) 0–2 px at every size, ≤ 1 px at 2160p. Text legible at all 7 sizes; the 2 px outline sample is intact. **Caveat:** Atkinson is not in the repo; the engine's built-in default font was used, so crispness of Atkinson itself, the 28 px size, Italic and the ring 28/48 stay NEEDS_REVIEW (lead + art-director on retained captures) | No (MSDF not needed on this evidence) |
| SP-16B | PASS (headless part) | `CanvasLayer.layer` round-trips; `ALWAYS` layer ran 5 frames under `tree.paused` (2→7) while the `PAUSABLE` layer stayed at 2→2; a `CanvasLayer` with `PROCESS_MODE_INHERIT` under an `ALWAYS` parent can process while paused. 21:9 and 16:10 logical rects (2560×1080, 1920×1200) match. Draw order of the 8 layers as rendered and mapper vs cursor ±1 px: NEEDS_WINDOWED | No |
| SP-16C | PASS (headless routing) | `is_echo()` true on a key event with `echo=true`; `is_action_pressed(&"ui_right")` is **false** for an echo and true with `allow_echo=true`. Via `Viewport.push_input` a `Button` overriding `_gui_input` with `accept_event()` kept focus (native, no handler: focus moved to `focus_neighbor_right`). Hold of 3 s on keyboard/D-pad/stick across real devices: NEEDS_MANUAL (hardware) | No |
| SP-16D | PASS (API); alignment NEEDS_WINDOWED review | `RichTextLabel.add_image` args: `image, width, height, color, inline_align, region, key, pad, tooltip, width_unit, height_unit, alt_text`; `RichTextLabel.ImageUnit` = `IMAGE_UNIT_PIXEL`, `IMAGE_UNIT_PERCENT`, `IMAGE_UNIT_EM` (the NOT SOURCEABLE names are now sourced). Frame shows a 32×32 inline glyph followed by text on one line, vertically near the text centre; ±2 px baseline check not measured (flat placeholder square) | Framed text run only if the real key/pad glyph misaligns |
| SP-16E | NEEDS_WINDOWED | `Label.get_line_count()` works headless (3 lines for a 96-char sentence at 300 px) but the headless text server does not use real glyph metrics; the ≥ 98 % pages ≤ 2 lines check over the slice lines needs the real font in a window | Lower `sub_car_linea` if it fails |

Other observed facts: `Window.get_final_transform().get_scale()` = `s` exactly (see ADR-0007 SP-1);
`--write-movie` records at the project's viewport size, not the `--resolution` size.

## Open Items

| ID | Item | Owner | Close when |
|---|---|---|---|
| OI-1 | `architecture.md` Shell tree: add `PauseVeil` and the layer numbers of D1; § Required ADRs row 0016 → this ADR | technical-director | `/architecture-review` |
| OI-2 | **Applied 2026-11-10 (OI-2, OI-3, OI-4 applied in ADR-0007, -0006, -0017).** ADR-0007 D8.3 amendment: hover moves the options cursor (C2) | technical-director | ADR-0007 revised |
| OI-3 | ADR-0006 D9 amendment: `PointerCursor` bounds = `ViewportMapper.logical_rect()`; `zone_rect()` default from the mapper (C3) | technical-director | ADR-0006 revised |
| OI-4 | Lines under the curtain are invisible: ADR-0017 must state that 21 does not start lines while `Curtain` covers the screen (C5) | ADR-0017 | ADR-0017 drafted |
| OI-5 | GDD 26 F3/TR-subs-014 and GDD 24 F2/TR-prompt-015/-018 still carry the window factor; re-read per ADR-0007 D7 (G18, user QQ-10) (C1) | game-designer / user | GDD 24/26 next round |
| OI-6 | GDD 24 R14/TR-prompt-010: add `bindings_revision()` polling (G16) (C6) | 24 author | GDD 24 next round |
| OI-7 | 18 keys ‡: `UI_ACCION_<ID>`, `UI_SUB_HABLANTE_*`, `UI_SUB_MUESTRA`; `seg_b_inicio_s` per segment | narrative / 18 | GDD 18 next round |
| OI-8 | `a11y_tab.json` (30's ordered row list) and glyph atlas ids per `PadFamily` | 30 / ux | Before 25/30 stories |
| OI-9 | `sub_fondo_opacidad_min`, outline colour and name tints: art-director measures 7:1 / 4.5:1 | art-director | AC-30 captures |
| OI-10 | 19's computer screen confirmed as root-canvas overlay in `SceneUi` (closes ADR-0007 OI-5 for the slice) | 19 author | GDD 19 next round |

### Contradictions found

| # | Between | Resolution here |
|---|---|---|
| C1 | GDD 26 F3 / 24 F2 (window factor + run-time `max`) vs ADR-0007 D7 | ADR-0007 prevails: logical sizes, CI floor (OI-5) |
| C2 | ADR-0007 D8.3 ("hover must not move the cursor") vs GDD 25 R9 / TR-pause-009 / ADR-0006 D9 (hover moves focus) | Hover moves focus (D9); amend ADR-0007 (OI-2) |
| C3 | ADR-0006 D9 cursor "logical 1920×1080" vs ADR-0007 D7.5 `expand` (wider/taller logical viewport) | Mapper's logical rect (D2); amend ADR-0006 (OI-3) |
| C4 | `architecture.md` tree (veil inside `PauseMenu`, no layer numbers) vs ADR-0002 "subtitles above the veil" | Veil split into `PauseVeil` (D1, OI-1) |
| C5 | 26 R22 (drawn in `sin control`) vs curtain above subtitles | Curtain stays on top; constraint pushed to ADR-0017 (OI-4) |
| C6 | TR-prompt-010 (re-resolve only on device change / `pause_closed`) vs ADR-0006 D13 / G16 (`bindings_revision`) | Both: revision poll plus the two notices (D4.4, OI-6) |

## Related

- Depends on: ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0007, ADR-0008,
  ADR-0009 (all `Proposed`); amends 0006 D9 and 0007 D8.3 (OI-2, OI-3).
- Enables: ADR-0017 (call UI band cap, curtain/lines), 19 UI, 27 title.
- Design: `design/gdd/subtitulos.md`, `design/gdd/prompt-de-interaccion.md`,
  `design/gdd/menu-de-pausa.md`, `design/gdd/pantalla-de-titulo.md`,
  `design/gdd/sistema-de-pistas.md`, `design/gdd/opciones-de-accesibilidad.md`.
- Architecture: `docs/architecture/architecture.md` (§ Required ADRs row
  ADR-0016, QQ-19), `docs/architecture/tr-baseline-provisional.md`,
  `docs/architecture/adr-reconciliation-2026-11-10.md`.
- Engine reference: `docs/engine-reference/godot/modules/ui.md`.
