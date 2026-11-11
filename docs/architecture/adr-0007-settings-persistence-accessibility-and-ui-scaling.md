# ADR-0007: Settings Persistence, Accessibility and UI Scaling

## Status

Accepted (2026-11-11) — SP-1, SP-3 and SP-6 run on 4.7.2 (geometry equals min(W/1920, H/1080) on 7 resolutions, in test and in a real window); SP-2 and SP-5 partial and SP-4 (screen reader, Narrator) deferred as NEEDS_WINDOWED / NEEDS_MANUAL to the playable prototype

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.

## Date

2026-11-10

## Last Verified

2026-11-10 — against Godot 4.7 reference (`docs/engine-reference/godot/`, pin
4.7.2), `design/gdd/ajustes-persistentes.md` (ronda 10),
`design/gdd/opciones-de-accesibilidad.md`, ADR-0001, -0002, -0003, -0009
(all `Proposed`).

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation:
autonomous`); user confirmation pending on the items marked **USER** in § Open
Items (QQ-08, QQ-10).

## Summary

Settings (system 6) needs a file format, a validation/quantization contract, a
deferred-save loop, and signed read/write/reset/flush operations (QQ-15);
accessibility (30) needs a UI-scaling model that does not apply the window
factor twice, a single text floor, AccessKit preparation and code-level
safety constants. Decision: `user://settings/settings.json` (JSON, versioned,
canonical quantized values, NaN never stored), a `Settings` autoload on the
shared `NoticeChannel` (cap `max_chained_notices` 64 from `defaults.json`)
with a `RealClock` debounce of 0.5 s / 5.0 s, and **engine-side stretch
(`canvas_items` + `expand`, base 1920×1080) as the only resolution factor** —
GDD formulas drop `alto/1080` and work in logical pixels, where the 24 px floor
lives; AccessKit names and focus order go through one helper each, gated by a
spike.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | UI (primary) · Core (file I/O, autoload) |
| **Layer** | Core (Settings is sublayer C1, ADR-0009 D4; the UI-scaling rules are consumed by Presentation) |
| **Knowledge Risk** | HIGH — 4.5 (AccessKit), 4.6 (dual focus), 4.7 (stretch defaults, `accessibility_live` type) are post-cutoff (`VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `breaking-changes.md` (rows: stretch defaults for new projects; `Control.accessibility_live` type; AccessKit screen reader; `FileAccess.store_*` → `bool`); `deprecated-apis.md` (`Time.get_ticks_msec`, `AccessibilityServer.AccessibilityLiveMode`); `current-best-practices.md` § Accessibility (4.5+), § UI (4.6), § UI and Input (4.7); `modules/ui.md` (4.7/4.6/4.5 changes, Theme `set_font_size`, focus management, `focus_neighbor_*`) |
| **Post-Cutoff APIs Used** | `display/window/stretch/mode = canvas_items` / `aspect = expand` as **values** (sourced: `breaking-changes.md`, `modules/ui.md` 4.7); AccessKit integration of `Control` (4.5, sourced as a capability only); dual-focus semantics (4.6, sourced: `grab_focus()` = keyboard/gamepad only); `Control.accessibility_live` typed `AccessibilityServer.AccessibilityLiveMode` (4.7, sourced) |
| **Verification Required** | Spikes SP-1…SP-6 (§ Spike Plan): stretch geometry at 720p/1080p/2160p and 16:10; font crispness; runtime Theme re-layout; AccessKit name/focus/disabled; `DisplayServer` window mode; JSON/rename (shared with ADR-0004) |

### Engine API sourcing

| API / behaviour this ADR relies on | Status |
|---|---|
| Project settings `display/window/stretch/mode` (`canvas_items`) and `display/window/stretch/aspect` (`expand`) exist with those values | Sourced: `breaking-changes.md` (Project row), `modules/ui.md` § 4.7, `current-best-practices.md` § UI and Input (4.7) |
| Existing projects keep their stretch settings (so the value must be set explicitly in `project.godot`) | Sourced: same rows |
| Geometry of `canvas_items` + `expand`: scale factor `s = min(W/1920, H/1080)`, logical viewport grows on the free axis | **NOT SOURCEABLE — behaviour of `expand` not covered by `docs/engine-reference/godot/modules/ui.md` nor `modules/rendering.md`.** Assumed; SP-1 measures it |
| `display/window/size/viewport_width`/`viewport_height` (base size) and `display/window/stretch/scale_mode` (fractional vs integer) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`.** SP-1/SP-2 |
| Fonts rasterised at the final (scaled) size under `canvas_items`; 3D rendered at window resolution, not at the base size | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/rendering.md` nor `modules/ui.md`.** SP-1 |
| `Content scale` at runtime (`Window.content_scale_factor`, `content_scale_size`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`.** Not used by this ADR (Alternative 2 rejected) |
| `Theme.set_font_size(name, theme_type, size)` | Sourced: `modules/ui.md` § Theme and Style |
| A Theme change re-lays out containers in the same or next frame | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`.** SP-3 |
| `Control.grab_focus()` moves keyboard/gamepad focus only; mouse hover is separate (4.6 dual focus) | Sourced: `modules/ui.md` § Focus Management (4.6), § Common Mistakes |
| `focus_neighbor_top/bottom/left/right = other.get_path()` | Sourced: `modules/ui.md` § Focus Management |
| `Control` integrates with AccessKit (4.5) | Sourced as capability: `breaking-changes.md`, `current-best-practices.md` § Accessibility, `modules/ui.md` § 4.5 |
| Name of the accessible-name property, how disabled state and focus order are exposed to the screen reader, `AccessibilityLiveMode` member names | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md` (only the type of `accessibility_live` is listed).** SP-4 |
| `Time.get_ticks_msec()` | Sourced: `deprecated-apis.md` (via ADR-0002 `RealClock`) |
| `FileAccess.store_*` return `bool` | Sourced: `breaking-changes.md` (4.4) |
| `JSON` parse/stringify behaviour (failure detection, NaN, ints parsed as float), `DirAccess` rename over an existing file on Windows/Linux, `user://` resolution | **NOT SOURCEABLE — no `core.md` in `docs/engine-reference/godot/modules/`.** Confined to `FileStore` / `SettingsCodec`; SP-6 shared with ADR-0004 |
| `DisplayServer` window-mode set/get, OS rejection, external change (Alt+Enter) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (no `DisplayServer` module).** Confined to `WindowPort`; SP-5 |
| GDScript built-ins `is_nan`, `is_inf`, `clampf`, `floorf`, `roundi`, `is_equal_approx`, `typeof` | Pre-cutoff, stable since 4.0; **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (the reference lists changes only). Covered by unit tests (T-S03, T-S04) |

> Re-validate this ADR if the project upgrades engine version (HIGH risk).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (`NoticeChannel`, `LogSink`, `ErrorPolicy`, callback signature of `subscribe_change`); ADR-0002 (`RealClock`, `Settings` `process_mode` `ALWAYS`, «vaciar pendientes» O3 from 25); ADR-0009 (`Settings` autoload #5 `SettingsAutoload`, Boot step 6, `ServiceContext`, `FileStore`, `FatalErrorHandler`, `SubscriptionBag`, `SettingsReader`) |
| **Related (non-blocking)** | ADR-0004 Save format (not yet written) — owns the atomic-replace primitive of `FileStore` and the JSON/rename spike; this ADR uses `FileStore.write_atomic` and amends if ADR-0004 signs it differently. ADR-0003 — already reads `ctx.settings.get_bool(&"reducir_movimiento")` (signature fixed here) |
| **Enables** | ADR-0016 (subtitles and UI text rendering: works in logical px under the stretch of D7); ADR-0008 (volume curve F2 and `subscribe_change`); ADR-0006 (opaque `controles` block, `settings_applied`); UI ADRs of 25/27/19 (focus chain, accessible names, `UiTextScale`) |
| **Blocks** | Epic «Ajustes persistentes» (6); epic «Opciones de accesibilidad» (30); stories of 25/27 options tab, 26 text size, 24 pie size, 19 screen layout |
| **Ordering Note** | `project.godot` stretch settings (D7) must land before any UI screenshot evidence is taken, or every evidence capture is invalid |

## Context

### Problem Statement

`ajustes-persistentes.md` leaves to an ADR: file path/format/versioning, NaN
in a JSON file, the corrupt-copy name, the atomic replace, the chained-notice
cap and the read/write/reset/flush signatures (GDD 6 OQ 1–3, QQ-15; «Sin
criterio hasta que exista el ADR» paragraph). `opciones-de-accesibilidad.md`
F1 computes `tam_px = tam_base_px × escala_texto_ui × (alto_ventana_px/1080)`
and warns that if the project stretches the UI with `canvas_items` the window
factor is applied twice (TR-a11y-006); 24 F2 and 26 F3 carry the same
`alto/1080` factor, and 26 D26-22 records that at 720p `pequeno` = `medio` =
24 px because its floor is applied **after** scaling — while 30 rule 26 defines
the floor as 24 **logical** px (16 real at 720p). The UI ADR (0016), the
Settings epic and every screenshot-based AC of 24/25/26/27/19/30 depend on this.

### Current State

No code. `architecture.md` § API Boundaries «Ajustes (6)» lists the operations
with ‡; ADR-0001 fixes the callback signature and that Settings owns a second
`NoticeChannel`; ADR-0002 fixes `RealClock` and `ALWAYS`; ADR-0009 fixes the
autoload, Boot step 6 and test doubles. 

### Constraints

- GDD 6 rules 1–14, F1–F3 and Edge Cases are the behaviour spec; this ADR
  chooses mechanisms, it does not change behaviour except where § Contradictions
  says so.
- Unit tests do no real I/O and use integer-tick clocks (TR-settings-021).
- Only `Boot` names autoloads (ADR-0009 D3); Settings never reads `GameState`
  (ADR-0001 D2) nor `GameClock` (ADR-0002 D5).
- Engine behaviour not in `docs/engine-reference/godot/` is confined to one
  adapter class per API family and verified by spike.
- Solo developer, vertical slice: one file, no migrations (GDD 6 Edge Cases).

### Requirements

- R1 Always-valid synchronous reads; writes applied immediately (TR-settings-002).
- R2 Validation, clamping and grid quantization identical on write and on load
  (TR-settings-003, -004, -011).
- R3 Same delivery semantics as the bus, own channel, bounded chain (TR-settings-005, -006).
- R4 Versioned user file, tolerant per-key load, corrupt copy, atomic write,
  deferred save in real time (TR-settings-010…015).
- R5 One resolution factor for all UI text and a single 24 px floor
  (TR-a11y-005, -006, TR-prompt-018, TR-subs-014, TR-computer-013/-014, TR-title-015).
- R6 Screen-reader readiness without spreading unverified API (TR-a11y-015).
- R7 Photosensitivity limits that cannot be tuned away by data (TR-a11y-010).

## Decision

### D1 — Catalog: `res://assets/data/settings/defaults.json`

One JSON file, read once by `Settings.setup()`; schema checked by
`SettingsCatalog.load()` (and by `DataValidator` in CI, ADR-0005). Any failure
→ `ctx.fatal.report(&"CATALOGO_INVALIDO", {param: …})` (ADR-0009 D8,
TR-settings-019).

```json
{
  "catalog_version": 1,
  "params": {
    "n_pasos": 20, "db_min": -40.0,
    "t_guardado_s": 0.5, "t_guardado_max_s": 5.0,
    "max_chained_notices": 64,
    "reduce_motion_fade_s": 0.1,
    "window_poll_s": 0.5
  },
  "keys": {
    "vol_voces":   {"type": "float", "default": 1.0, "min": 0.0, "max": 1.0, "steps": "n_pasos", "reset": true},
    "campo_vision":{"type": "float", "default": 70.0, "min": 60.0, "max": 90.0, "step": 5.0, "reset": true},
    "multiplicador_pie": {"type": "float", "default": 1.0, "min": 1.0, "max": 3.0, "step": 0.25, "reset": true},
    "subtitulos_activos": {"type": "bool", "default": true, "reset": true},
    "escala_texto_ui": {"type": "enum", "values": ["1_00", "1_25", "1_50"], "default": "1_00",
                        "factors": {"1_00": 1.0, "1_25": 1.25, "1_50": 1.5}, "reset": true},
    "modo_ventana": {"type": "enum", "values": ["pantalla_completa", "ventana"], "default": "pantalla_completa", "reset": false},
    "advertencias_vistas": {"type": "bool", "default": false, "reset": false},
    "controles": {"type": "block", "reset": false}
  }
}
```

(Excerpt; the file declares all 20 valued keys of GDD 6 rule 1 plus
`controles`.) Validation (fatal if broken): `n_pasos` 10–40, `db_min` −60…−30,
`t_guardado_s` 0.2–2.0, `t_guardado_max_s` 2.0–30.0 and ≥ 2 × `t_guardado_s`,
`max_chained_notices` 8–256, `reduce_motion_fade_s` 0.05–0.15 (30 rule 27),
`window_poll_s` 0.1–2.0; every float key has `min < max`, `default` in range
and on-grid; `step` must divide `max − min` into an integer `steps`
(`abs(steps − roundf(steps)) < 1e-6`); enum `default` ∈ `values`; `factors`
covers `values` and every factor ≥ 1.0. **The `reset: true` count must equal
`RESET_ALL_KEY_COUNT := 18`** (a code constant in `SettingsCatalog`, the number
GDD 6 rule 8 says «cambia aquí primero»); a mismatch is `CATALOGO_INVALIDO`
with `param = "reset_count"`. If the user rejects `escala_texto_ui` (QQ-08) the
key is removed from data and the constant becomes 17 in the same commit.

Safe values for reads before a catalog exists (GDD 6 Edge Cases «antes de
Listo») are a code table `SettingsSafeValues.TABLE` (volumes 1.0,
`subtitulos_activos` true, `modo_ventana` `ventana`, `campo_vision` 70,
`balanceo_camara` `reducido`, `controles` absent, everything else false /
first enum value), because by definition they cannot come from the file that
failed.

### D2 — Canonical values and quantization

Every value held in memory is **canonical**: `bool`; `StringName` for enums;
for floats, the grid value recomputed from its index, never the caller's
float. Hence "same value" is exact equality of canonical values, which is
equivalent to GDD 6 F1 "compare `n`, not the float".

```gdscript
const QUANT_EPS: float = 1e-9   # absorbs 0.025 * 20 = 0.4999999… (AC-F1 «0,025 → n = 1»)

static func grid_index(def: SettingDef, v: float) -> int:
	var c: float = clampf(v, def.min_value, def.max_value)     # ±INF clamp to limits
	# multiply before dividing: (72.5-60)*6/30 = 2.5 exactly (GDD 6 F1 «72,5 → 75»)
	var x: float = (c - def.min_value) * float(def.steps) / (def.max_value - def.min_value)
	return clampi(int(floorf(x + 0.5 + QUANT_EPS)), 0, def.steps)

static func grid_value(def: SettingDef, n: int) -> float:
	return def.min_value + (def.max_value - def.min_value) * float(n) / float(def.steps)
```

Order of checks (`SettingsValidator.canonicalize`, shared by write and load):
1. type: `bool` must be `TYPE_BOOL` (no int coercion); float accepts
   `TYPE_FLOAT` or `TYPE_INT`; enum accepts `TYPE_STRING_NAME` or `TYPE_STRING`
   in `values`; `block` must be `TYPE_DICTIONARY`.
2. float NaN (`is_nan`) → **invalid** (checked before clamp; GDD 6 F2).
3. float out of range (incl. ±INF) → clamp + one `warn` log line, then quantize.
4. enum not in list → invalid (no quantization, 30 rule 8).
Invalid → write: rejected, previous value kept, `ErrorPolicy.fail` (dev halt)
+ log; load: that key takes its default + log (GDD 6 rules 6, 10).

### D3 — User file: `user://settings/settings.json`

| File | Role |
|---|---|
| `user://settings/settings.json` | Main file |
| `user://settings/settings.json.tmp` | Temporary of the atomic write |
| `user://settings/settings.corrupt.json` | **Single** copy of the last unreadable main file (a new one replaces the old) |

Separate folder from `user://saves/` (ADR-0004), so deleting saves never
touches settings (GDD 6 rule 3). Format:

```json
{
  "format_version": 1,
  "values": {"vol_voces": 0.5, "campo_vision": 80.0, "subtitulos_tamano": "grande",
             "modo_ventana": "ventana", "advertencias_vistas": true},
  "controles": { "...": "opaque block exported by InputRouter (1)" }
}
```

- **Only keys that differ from the default are written** (an absent key =
  default, GDD 6 rule 10). A default change in data then reaches players who
  never touched that key; unknown keys are never re-written (AC-09).
- `controles` is written only when present (opaque `Dictionary`, deep-copied
  in and out; deep equality decides "real change", AC-04c).
- **NaN is never written** (GDD 6 «representación de NaN»): memory cannot
  hold NaN (D2 rejects it), and `SettingsCodec.encode` asserts every float is
  finite before serializing. On load, any non-number where a float is
  expected — `null`, a string such as `"nan"`, an object — is a **type error**
  for that key only → default + log. There is no NaN encoding.
- `format_version`: absent, non-numeric, non-integral or greater than
  `SETTINGS_FORMAT_VERSION := 1` → unreadable (corrupt path); lower → read the
  recognised keys (no migrations in the slice). Numbers are compared with
  `is_equal_approx(v, roundf(v))` because the JSON parser may return floats
  for integers (NOT SOURCEABLE, SP-6).
- Root not a `Dictionary`, `values` not a `Dictionary`, or parse failure →
  unreadable.

**Corrupt path** (GDD 6 rule 11, AC-10a–c): `files.remove(corrupt)` (ignore
result) → `files.rename(main, corrupt)`; failure → one log line, main stays in
place and the first atomic save replaces it. Always continue to `READY` with
defaults; no dialog.

**Orphan temporary** (AC-15b): at load, if `main` exists, `tmp` is ignored and
removed. **Extension:** if `main` is absent and `tmp` exists, `tmp` is parsed
with the same rules and, if readable, adopted (renamed to `main`); otherwise
removed. This covers a replace primitive that is "remove then rename" on some
platform (SP-6) and never makes a valid main file lose to a temporary.

**Atomic write** = `files.write_atomic(main, text) -> bool`: write
`main + ".tmp"`, close, replace `main`. The primitive belongs to `FileStore`
and its platform sequence is fixed by ADR-0004's spike (shared, not
duplicated). `files.ensure_dir("user://settings")` runs before the first
write; failure counts as a write failure (AC-08b).

### D4 — Change notices on the shared `NoticeChannel`

`Settings` owns `NoticeChannel` #2 (ADR-0001 D2), built in `setup()` with
`max_chained = params.max_chained_notices` (64; 8–256), `ctx.logger`, the
`ErrorPolicy` and the schema `{&"settings_applied": {}}` plus the
`notices_dropped` row copied from `NoticeIds.SCHEMA`.

- A real change → `channel.push_change(key, old, new)`; `controles` →
  `push_change(&"controles", null, null)` (receiver re-reads, ADR-0001
  callback table).
- `subscribe_change(cb)` = `ALL_FACTS` kind; `subscribe_key(key, cb)` = `FACT`
  kind with topic `key`. Callback `func(key: StringName, old: Variant, new:
  Variant) -> void` (ADR-0001).
- «ajustes aplicados» = `channel.notify(SettingsNotices.APPLIED)` with
  `SettingsNotices.APPLIED := &"settings_applied"`; callback `func(payload:
  Dictionary) -> void` (empty dict). Not in `NoticeIds` (ADR-0001).
- **Chain cap (GDD 6 Edge Cases «bucle de avisos»): 64 per drain**, same
  algorithm as ADR-0001 D5 (drop rest, log, dev halt, one `notices_dropped`
  on this channel; nobody is required to listen to it). The cap is data
  (`params.max_chained_notices`), not shared with `flags.json`.
- Scene subscribers register through `SubscriptionBag` (ADR-0009 D3 rule 6);
  `release_all()` on unload gives auto-unsubscribe (TR-settings-007, AC-06g);
  the channel's `cb.is_valid()` pruning is the second line of defence.
- No change notice is delivered in `LOADING` (values are assigned directly,
  not through `_commit`).

### D5 — State machine and boot

`enum Status { UNLOADED, LOADING, READY }`. `setup(ctx)` (Boot step 6,
ADR-0009 D2) runs synchronously: catalog → user file → `WindowPort.apply_mode`
(OS rejection: keep the real mode, log, no notice) → `_status = READY` →
`channel.notify(APPLIED)`. Reads inside the `APPLIED` handlers see loaded
values (AC-12). Third-party calls in `UNLOADED`/`LOADING`: dev
`ErrorPolicy.fail`; release: read → catalog default if the catalog is loaded,
else `SettingsSafeValues`; write → discarded; one log line each
(TR-settings-009). InputRouter subscribes to `APPLIED` in Boot step 5, before
step 6 (ADR-0009 D2), so it never misses the notice.

### D6 — Deferred save on `RealClock`

`Settings` is `PROCESS_MODE_ALWAYS` (ADR-0002 D2) and reads only the injected
`RealClock.now_ms()` (integers; `FakeRealClock` in tests). Deadline polling in
`_process` (ADR-0002 D6: no `Timer`/`SceneTreeTimer`).

```gdscript
var _pending: bool = false
var _t_first_ms: int = 0
var _t_last_ms: int = 0
var _retry_at_ms: int = -1      # -1 = no retry scheduled
var _change_gen: int = 0        # snapshot guard (F3 «instantánea»)

func _mark_pending() -> void:
	var now: int = _clock.now_ms()
	if not _pending:
		_pending = true
		_t_first_ms = now
	_t_last_ms = now
	_change_gen += 1

## Engine-loop entry; public so tests drive it without a SceneTree.
func step() -> void:
	if _status != Status.READY:
		return
	_poll_window_mode()
	if not _pending:
		return
	var now: int = _clock.now_ms()
	if _retry_at_ms >= 0:
		if now >= _retry_at_ms:
			_write_now()
		return
	if now - _t_last_ms >= _t_save_ms or now - _t_first_ms >= _t_save_max_ms:
		_write_now()

func _process(_delta: float) -> void:
	step()

func _write_now() -> bool:
	var gen: int = _change_gen
	if _files.ensure_dir(SETTINGS_DIR) != OK or not _files.write_atomic(SETTINGS_PATH, _codec.encode(_values, _controls)):
		_log.line(&"warn", "settings: write failed; retry in %d ms" % _t_save_max_ms)
		_retry_at_ms = _clock.now_ms() + _t_save_max_ms
		return false
	_retry_at_ms = -1
	if gen == _change_gen:
		_pending = false            # else: a change arrived after the snapshot → stays pending
	return true
```

`_t_save_ms = roundi(t_guardado_s * 1000)`, `_t_save_max_ms` likewise. The
write is synchronous on the main thread, so a change cannot interleave today;
`_change_gen` keeps F3's snapshot rule true if the write ever moves to a
thread. Latency: a deadline fires on the first frame at or after it (≤ 1 frame
late), which AC-14a/b accept because tests drive `step()` with exact ticks.

**Forced writes.** `flush_pending()` writes now if `_pending` (no-op
otherwise) and ignores `_retry_at_ms`. Callers: 25 when the pause menu opens
(ADR-0002 D4 O3, synchronous, not the bus) and the **single quit path**
(Shell/ADR-0004 quit sequence) before the process exits. Settings does not
hook OS close notifications itself. A failed quit flush logs and returns —
never blocks (AC-14e).

### D7 — UI scaling: engine stretch is the only resolution factor

`project.godot` **must** set (explicitly, because existing projects keep their
values — `breaking-changes.md`):

| Setting | Value | Source |
|---|---|---|
| `display/window/size/viewport_width` × `viewport_height` | 1920 × 1080 | NOT SOURCEABLE (name) — SP-1 |
| `display/window/stretch/mode` | `canvas_items` | Sourced |
| `display/window/stretch/aspect` | `expand` | Sourced |
| `display/window/stretch/scale_mode` | `fractional` (720p needs 0.667) | NOT SOURCEABLE — SP-2 |
| Minimum window size | 1280 × 720 (below 720p unsupported, 30 F1) | NOT SOURCEABLE — SP-2 |

Rules that follow:

1. **All UI sizes are logical pixels at the 1920×1080 base.** The engine
   multiplies by `s` (expected `s = min(W/1920, H/1080)`, SP-1). No script
   computes `alto_ventana/1080`.
2. **GDD formulas are re-read without the window factor** (they are
   amended, § Contradictions C2):
   - 30 F1 → `tam_logico = roundi(tam_base_px × factor(escala_texto_ui))`.
   - 24 F2 → `s` is the engine's; 24 multiplies nothing; `ui_escala_min/max`
     (0.67–2.0) become the *supported resolution range* (720p–2160p), not a
     computed clamp.
   - 26 F3 → `alto_logico = base_px(subtitulos_tamano)` (24/32/44).
3. **The 24 px floor is logical** (`A11yConstants.TEXT_MIN_PX`, 30 rule 26,
   «24 px lógicos a 1080p, 16 px reales a 720 p»). Because every reading
   text has `tam_base_px ≥ 24` and every factor ≥ 1.0, the floor can never
   bind at run time: it is enforced **at data-validation time** (theme and
   `text_sizes` entries < 24 → CI error) instead of with a run-time `max()`.
   This dissolves D26-22: at 720p `pequeno` (16 real px) and `medio` (21.3)
   stay distinct. **USER** confirmation pending (QQ-10, § Open Items).
4. `escala_texto_ui` is applied by `UiTextScale` (Shell, ADR-0009 D6): it
   holds the list of scaled entries `(font-size name, theme type, base px)`
   in `res://assets/data/ui/text_sizes.json` and, on load and on every change
   notice of that key, calls `Theme.set_font_size(name, type,
   roundi(base × factor))` (sourced) on the shared UI Theme. **Not scaled**:
   the subtitle theme types (26 owns `subtitulos_tamano`), icons (24
   `icono_grande`), `Label3D`/diegetic text (30 rule 9). BBCode `[font_size]`
   in UI strings is forbidden (it would bypass the theme).
5. **Ultrawide / 16:10.** With `expand`, the logical viewport grows on the free
   axis (2560×1080 at 21:9, 1920×1200 at 16:10). HUD and prompts anchor to a
   central 1920×1080 safe rect (`SafeArea169` container, ADR-0016); full
   screen menus (25/27/19) may use the extra height. 16:10 never shrinks text.
6. **`content_scale_factor` is never written at run time** (it would scale
   icons and subtitles too, breaking 30 rules 9–10).

Resulting sizes (expected; SP-1 confirms ±1 px):

| Window (aspect) | Engine `s` | Logical viewport | Body 24 @ 1.00 | 24 @ 1.50 | Subs `pequeno`/`medio`/`grande` (24/32/44) | GDD-literal F1 under `canvas_items` (double factor), body 24 |
|---|---|---|---|---|---|---|
| 1280×720 (16:9) | 0.667 | 1920×1080 | 16.0 | 24.0 | 16.0 / 21.3 / 29.3 | 24 × 0.667 × 0.667 = **10.7** |
| 1920×1080 (16:9) | 1.000 | 1920×1080 | 24.0 | 36.0 | 24 / 32 / 44 | 24 |
| 2560×1440 (16:9) | 1.333 | 1920×1080 | 32.0 | 48.0 | 32 / 42.7 / 58.7 | **42.7** |
| 3840×2160 (16:9) | 2.000 | 1920×1080 | 48.0 | 72.0 | 48 / 64 / 88 | **96** |
| 1280×800 (16:10) | 0.667 | 1920×1200 | 16.0 | 24.0 | 16.0 / 21.3 / 29.3 | 24 × 0.741 × 0.667 = **11.9** |
| 1920×1200 (16:10) | 1.000 | 1920×1200 | 24.0 | 36.0 | 24 / 32 / 44 | 24 × 1.111 = **26.7** |
| 2560×1600 (16:10) | 1.333 | 1920×1200 | 32.0 | 48.0 | 32 / 42.7 / 58.7 | 24 × 1.481 × 1.333 = **47.4** |
| 2560×1080 (21:9) | 1.000 | 2560×1080 | 24.0 | 36.0 | 24 / 32 / 44 | 24 |

Values are physical px. The last column shows why the GDD factor must go:
×0.44 at 720p and ×2 at 2160p.

### D8 — AccessKit preparation (no screen-reader support promised)

The slice ships without screen-reader testing (30 D30-2); it ships **ready**:

1. **Accessible name = visible text**, set only through
   `A11y.set_accessible_name(control: Control, text: String) -> void`. That
   function is the **only** place allowed to name the engine property; until
   SP-4 identifies it, its body is a no-op plus a dev-only log (and SP-4 may
   find that AccessKit already uses `Button.text`/`Label.text`, in which case
   it stays a no-op for those types). Callers pass the same `tr()`/ContentDB
   string they display.
2. **Focus order = visual order** via `FocusChain.link_vertical(rows:
   Array[Control], wrap: bool)`, which sets `focus_neighbor_top/bottom` with
   `get_path()` (sourced). Row order comes from the screen's ordered row list
   (30 rule 6), never from tree order.
3. **Dual focus (4.6).** The options cursor (`OptionsComponent`, 25) is the
   source of truth for the selected row; it calls `grab_focus()` (keyboard/
   gamepad focus, sourced) so AccessKit follows it. Mouse hover **moves the
   cursor** (and thus focus) without activating; click activates (GDD 25 R9,
   TR-pause-009, ADR-0006 D9; amended by ADR-0016 OI-2). The visible
   focus ring is drawn from the cursor (non-colour: border ≥ 3:1 plus shape,
   30 rule 25), not from hover.
4. Disabled controls stay focusable-and-announced as «no disponible»
   (TR-computer-014) through `A11y.set_unavailable(control, bool)` — same
   single-site rule, SP-4.
5. `accessibility_live` (typed `AccessibilityServer.AccessibilityLiveMode`,
   4.7) is set only through `A11y.set_live(control, polite: bool)`; member
   names NOT SOURCEABLE (SP-4). Intended users: 25's header line, 26's block.

### D9 — Accessibility constants in code

`src/core/a11y/a11y_constants.gd` holds **safety limits**, deliberately code
and not data: a data edit must never be able to raise a photosensitivity cap
(exception to "gameplay values data-driven": these are not gameplay values).

```gdscript
class_name A11yConstants extends RefCounted
## Project-wide accessibility limits (GDD 30 rules 18, 24-27). Code, not data.

const FLASH_MAX_PER_S: int = 3            # 30 R18 (SC 2.3.1); one flash = one onset, counted in a half-open 1000 ms window, integer ms (ADR-0014 OI-1)
const FLASH_WINDOW_MS: int = 1000         # 30 R24 sliding window
const FLASH_LUMA_DELTA: float = 0.10      # 30 R24 >= 10 % of full range
const FLASH_DARK_MAX: float = 0.80        # 30 R24 darker state below 0.80
const FLASH_AREA_MIN: float = 0.25        # 30 R24 > 25 % of the field of view
const LIGHT_FLICKER_MAX_HZ: float = 2.0   # owner 28 (R9/R11), here for audit
const LIGHT_FLICKER_MIN_PAUSE_S: float = 0.35  # owner 28
const LIGHT_FLICKER_DEPTH_FLOOR: float = 0.40  # owner 28 (ADR-0014 OI-1), here for audit
const TEXT_MIN_PX: int = 24               # 30 R26, logical px at 1080 base
const CONTRAST_TEXT_MIN: float = 4.5      # 30 R25
const CONTRAST_NON_TEXT_MIN: float = 3.0  # 30 R25
const REDUCED_MOTION_FADE_MIN_S: float = 0.05  # 30 R27 range; default 0.1 is data (D1)
const REDUCED_MOTION_FADE_MAX_S: float = 0.15
const BASE_VIEWPORT: Vector2i = Vector2i(1920, 1080)
const MIN_WINDOW: Vector2i = Vector2i(1280, 720)
```

`FlashGuard` (`src/core/a11y/flash_guard.gd`, `RefCounted`, injected
`RealClock`): `try_flash() -> bool` returns `false` when `FLASH_MAX_PER_S`
flashes already happened in the last `FLASH_WINDOW_MS`; emitters 21, 24, 28,
29 call it before any effect that meets the R24 definition. It is the
run-time limiter; the video analysis of AC-30-13 is the verification. The
rendering ADRs of 28/29 decide *which* effects count as a flash: hands none
(ADR-0013); 28 calls `try_flash()` after its own local limiter (ADR-0014);
29 per ADR-0015. Injected as `ctx.flash_guard` (ADR-0009 D3).

### D10 — Window mode

`modo_ventana` is applied through an injected `WindowPort` (`apply_mode(mode:
StringName) -> StringName` returns the mode really applied; `current_mode() ->
StringName`). Only `WindowPort` names `DisplayServer` (NS, SP-5). External
changes (Alt+Enter) are detected by polling `current_mode()` every
`params.window_poll_s` (0.5 s, `RealClock`) in `step()`; a difference is
committed as a normal change (notice + pending). OS rejection after a player
write: commit the really applied mode (notice + log) (GDD 6 Edge Cases).

### Architecture Diagram

```text
 res://assets/data/settings/defaults.json ──► SettingsCatalog ──(invalid)──► ctx.fatal CATALOGO_INVALIDO
                                                   │ SettingDef[]
 writers: 25 · 27 · 30 rows ── set_setting ─┐      ▼
          1 InputRouter ── set_controls_block ─► ┌──────────── Settings (autoload #5, ALWAYS) ─────────────┐
          25 pause open ── flush_pending ──────► │ SettingsValidator (D2: type → NaN → clamp → grid)        │
          quit path ───── flush_pending ───────► │ _values{key: canonical}  _controls{}                     │
                                                 │ Status UNLOADED → LOADING → READY → notify(APPLIED)      │
                                                 │ NoticeChannel #2 (cap 64) ── push_change(key,old,new) ───┼──► subscribers
                                                 │ deferred save (RealClock 0.5 s / 5.0 s, retry)           │    (23, 26, 2, 7, 9,
                                                 │ WindowPort (modo_ventana, poll 0.5 s)                    │     24, 28, 4, 19, 21,
                                                 └───────┬─────────────────────────────────────────────────┘     1 on APPLIED)
                                                         │ SettingsCodec.encode / decode
                                                         ▼ FileStore (ADR-0009; atomic primitive ADR-0004)
                                user://settings/settings.json · .json.tmp · settings.corrupt.json

 Presentation (Shell): UiTextScale ◄─ change(escala_texto_ui) ─ Theme.set_font_size(base × factor)
 Engine: stretch canvas_items/expand, base 1920×1080 ─► the ONLY resolution factor s (D7)
 A11y: A11yConstants · FlashGuard · A11y.set_accessible_name / set_unavailable / set_live · FocusChain
```

### Key Interfaces

Typed GDScript. **‡ proposed** = no GDD signs it; this ADR fixes it (QQ-15).
GDD operation names on the right.

```gdscript
# ─── src/core/settings/settings.gd  (autoload SettingsAutoload, class Settings) ─
class_name Settings extends Node
## Owner of player preferences (GDD 6). Only Boot names the autoload.

enum Status { UNLOADED, LOADING, READY }                     # Sin cargar / Cargando / Listo
const SETTINGS_FORMAT_VERSION: int = 1
const SETTINGS_DIR: String = "user://settings"
const SETTINGS_PATH: String = "user://settings/settings.json"
const SETTINGS_CORRUPT_PATH: String = "user://settings/settings.corrupt.json"

## Boot step 6 (ADR-0009 D2). Synchronous; ends in READY and one «ajustes aplicados».
func setup(ctx: ServiceContext) -> void: pass                           # ‡
func get_status() -> Status: return Status.UNLOADED                     # ‡

# Reads — always a valid value (rule 4)                                  # «leer ajuste»
func get_setting(key: StringName) -> Variant: return null               # ‡ bool | float | StringName
func get_bool(key: StringName) -> bool: return false                    # ‡ dev fail if key is not bool
func get_float(key: StringName) -> float: return 0.0                    # ‡ canonical grid value
func get_enum(key: StringName) -> StringName: return &""                # ‡
func get_text_scale_factor() -> float: return 1.0                       # ‡ factors[escala_texto_ui]
func get_controls_block() -> Dictionary: return {}                      # ‡ deep copy; {} = «ausente»
func get_volume(key: StringName) -> VolumeLevel: return null            # ‡ F2 result for 23

# Writes                                                                  # «escribir ajuste»
## true = accepted (changed, identical, or clamped+logged); false = rejected (rule 6).
func set_setting(key: StringName, value: Variant) -> bool: return false # ‡
func set_controls_block(block: Dictionary) -> bool: return false        # ‡ only InputRouter (1)
func reset_setting(key: StringName) -> void: pass                       # ‡ «restablecer un ajuste»; only reset:true keys
func reset_all() -> void: pass                                          # ‡ «restablecer todos» = 18 keys
func flush_pending() -> void: pass                                      # ‡ «vaciar pendientes»; sync
func has_pending() -> bool: return false                                # ‡ tests / dev overlay

# Notices (NoticeChannel #2)
func subscribe_change(cb: Callable) -> int: return 0                    # ‡ cb(key, old, new), all keys
func subscribe_key(key: StringName, cb: Callable) -> int: return 0      # ‡ cb(key, old, new), one key
func subscribe_applied(cb: Callable) -> int: return 0                   # ‡ cb(payload: Dictionary) «ajustes aplicados»
func unsubscribe(handle: int) -> void: pass                             # ‡ effective after current entry

## Engine-loop entry (deferred save + window poll); public for tests.
func step() -> void: pass                                               # ‡

# ─── src/core/settings/settings_notices.gd ──────────────────────────────────
class_name SettingsNotices extends RefCounted
const APPLIED: StringName = &"settings_applied"
const CONTROLS_KEY: StringName = &"controles"

# ─── src/core/settings/volume_level.gd  (F2 of GDD 6) ───────────────────────
class_name VolumeLevel extends RefCounted
var muted: bool          # n == 0 → true, linear == 0.0 exactly, db undefined
var db: float            # db_min * (1 - v); meaningful only when not muted
var linear: float        # 10^(db/20), or 0.0 when muted; never log(0)
static func from_index(n: int, n_steps: int, db_min: float) -> VolumeLevel: return null

# ─── src/core/settings/settings_reader.gd  (ADR-0009 D7) ────────────────────
class_name SettingsReader extends RefCounted
## Read-only view for puzzle controllers: get_bool / get_float / get_enum only.

# ─── src/core/platform/file_store.gd  (methods used here; ‡ shared with ADR-0004) ─
class_name FileStore extends RefCounted
enum ReadStatus { OK, MISSING, ERROR }
func read_text(path: String) -> FileRead: return null      # FileRead {status: ReadStatus, text: String}
func write_atomic(path: String, text: String) -> bool: return false   # tmp = path + ".tmp"; sequence ADR-0004
func rename(from_path: String, to_path: String) -> Error: return OK   # ADR-0004 owns: Error, never onto an existing name
func remove(path: String) -> Error: return OK
func exists(path: String) -> bool: return false
func ensure_dir(dir: String) -> Error: return OK

# ─── src/core/settings/window_port.gd ───────────────────────────────────────
@abstract class_name WindowPort extends RefCounted
@abstract func apply_mode(mode: StringName) -> StringName  # returns mode really applied
@abstract func current_mode() -> StringName
# DisplayWindowPort (production, names DisplayServer, SP-5) · FakeWindowPort (tests: scriptable rejection)

# ─── src/ui/text/ui_text_scale.gd  (Shell, presentation) ───────────────────
class_name UiTextScale extends RefCounted
func _init(theme: Theme, entries: Array[UiTextSizeEntry]) -> void: pass
func apply(factor: float) -> void: pass                    # set_font_size(name, type, roundi(base × factor))
static func logical_size(base_px: int, factor: float) -> int: return roundi(base_px * factor)

# ─── src/core/a11y/ ─────────────────────────────────────────────────────────
class_name A11y extends RefCounted                         # the ONLY site naming AccessKit properties (SP-4)
static func set_accessible_name(control: Control, text: String) -> void: pass
static func set_unavailable(control: Control, unavailable: bool) -> void: pass
static func set_live(control: Control, polite: bool) -> void: pass
class_name FocusChain extends RefCounted
static func link_vertical(rows: Array[Control], wrap: bool) -> void: pass   # focus_neighbor_top/bottom
class_name FlashGuard extends RefCounted
func _init(clock: RealClock) -> void: pass
func try_flash() -> bool: return true                      # false if FLASH_MAX_PER_S hit in FLASH_WINDOW_MS
```

### Reference pseudocode — write, reset, load

```gdscript
func set_setting(key: StringName, value: Variant) -> bool:
	if not _guard_ready(&"set_setting", key):
		return false                                # dev fail / release discard + log (D5)
	var def: SettingDef = _catalog.find(key)
	if def == null or def.type == SettingDef.Type.BLOCK:
		return _reject(key, value, "undeclared or block")
	var canon: Variant = _validator.canonicalize(def, value)   # null = invalid (D2)
	if canon == null:
		return _reject(key, value, "invalid")
	_commit(def.key, canon)
	return true

func _commit(key: StringName, canon: Variant) -> void:
	var old: Variant = _values[key]
	if old == canon:                                # canonical ⇒ equality == same grid index n
		return
	_values[key] = canon                            # applied before any delivery (rule 5)
	if key == &"modo_ventana":
		var real: StringName = _window.apply_mode(canon)
		if real != canon:
			_log.line(&"warn", "settings: OS rejected window mode %s" % canon)
			_values[key] = real
			if real == old:
				return
			canon = real
	_mark_pending()
	_channel.push_change(key, old, canon)           # queued if inside a drain (no reentrancy)

func _reject(key: StringName, value: Variant, why: String) -> bool:
	_log.line(&"error", "settings: rejected %s = %s (%s)" % [key, var_to_str(value), why])
	_errors.fail("settings write rejected: %s" % key)   # dev halt; release no-op
	return false

func reset_all() -> void:
	if not _guard_ready(&"reset_all", &""):
		return
	for def: SettingDef in _catalog.resettable():    # catalog order; 18 keys (D1)
		_commit(def.key, def.default_value)          # one notice per key that really changes

func _load_user_file() -> void:                       # status == LOADING
	_values = _catalog.defaults()
	var main: FileRead = _files.read_text(SETTINGS_PATH)
	var tmp_path: String = SETTINGS_PATH + ".tmp"
	if main.status == FileStore.ReadStatus.MISSING and _files.exists(tmp_path):
		main = _files.read_text(tmp_path)            # D3 extension: adopt orphan only if main is absent
		if main.status == FileStore.ReadStatus.OK and _codec.is_readable(main.text):
			_files.rename(tmp_path, SETTINGS_PATH)
	_files.remove(tmp_path)                           # orphan: ignored and removed (AC-15b)
	match main.status:
		FileStore.ReadStatus.MISSING:
			return                                    # first boot: not an error, no log (AC-08a)
		FileStore.ReadStatus.ERROR:
			_quarantine("unreadable"); return
	var doc: SettingsDocument = _codec.decode(main.text)   # null = unreadable/structure/version
	if doc == null:
		_quarantine("invalid structure or version"); return
	for key: StringName in doc.values:
		var def: SettingDef = _catalog.find(key)
		if def == null or def.type == SettingDef.Type.BLOCK:
			continue                                  # unknown: ignored, never re-written
		var canon: Variant = _validator.canonicalize(def, doc.values[key])
		if canon == null:
			_log.line(&"warn", "settings: %s invalid in file, default used" % key)
		else:
			_values[key] = canon                      # clamped/quantized as on write (rule 10)
	_controls = doc.controls if doc.controls is Dictionary else {}   # unreadable block → «ausente»

func _quarantine(why: String) -> void:
	_log.line(&"warn", "settings: %s; defaults used, copy kept" % why)
	_files.remove(SETTINGS_CORRUPT_PATH)
	if _files.rename(SETTINGS_PATH, SETTINGS_CORRUPT_PATH) != OK:
		_log.line(&"warn", "settings: could not keep corrupt copy; next save replaces it")
	_values = _catalog.defaults()
	_controls = {}
```

### Implementation Guidelines

- **G-1** Systems **must** reach Settings only through `ctx.settings` (or
  `SettingsReader` for puzzles); only `Boot` names `SettingsAutoload`.
- **G-2** Only 25, 27 and 30's rows **may** call `set_setting`/`reset_*`; only
  InputRouter calls `set_controls_block`; only 27 writes `advertencias_vistas`.
  Review rule in the control manifest; `set_setting` does not check the caller.
- **G-3** Settings **must** use `RealClock` only (never `GameClock`, `Timer`,
  `SceneTreeTimer`), and **must never** read `GameState`.
- **G-4** Every float **must** pass `SettingsValidator.canonicalize`; nobody
  stores or compares the caller's float. NaN **must never** reach memory, the
  file or `VolumeLevel`.
- **G-5** `NoticeChannel` #2 **must** be built with
  `params.max_chained_notices`; no other Settings notice besides
  `push_change` and `SettingsNotices.APPLIED`.
- **G-6** No script **may** compute a resolution factor
  (`get_viewport().size.y / 1080` and similar are forbidden in UI code); UI
  sizes are logical px. CI text scan in `tools/ci/` flags `/ 1080` in `src/ui/`.
- **G-7** No reading text **may** have a logical size < `A11yConstants.TEXT_MIN_PX`;
  enforced by test T-A03 over the base Theme and `text_sizes.json`.
- **G-8** UI text sizes **must** come from the Theme (no BBCode
  `[font_size]`, no per-node `add_theme_font_size_override` on reading text
  except subtitles, which own `subtitulos_tamano`).
- **G-9** AccessKit properties **must** be touched only inside `A11y`; focus
  neighbours only through `FocusChain`; game logic **must never** treat hover
  as selection (dual focus).
- **G-10** Any effect that meets 30 rule 24 **must** ask `FlashGuard.try_flash()`
  first; `A11yConstants` values **must never** be moved to data.
- **G-11** `DisplayServer` **may** be named only in `DisplayWindowPort`; JSON and
  `FileAccess`/`DirAccess` only in `SettingsCodec` and `FileStore`.
- **G-12** Unit tests **must** use `MemoryFileStore`, `FakeRealClock`,
  `FakeWindowPort`, `RecordingLog` and a recording `ErrorPolicy` (ADR-0009 D9).

## Spike Plan

Run on the installed 4.7.2 editor, Windows (developer target) and Linux (CI).
Evidence (screenshots) retained in `production/qa/evidence/adr-0007/`;
observations written back to `docs/engine-reference/godot/modules/ui.md`.

| ID | Question (NS) | Method | Pass criterion | If it fails |
|---|---|---|---|---|
| SP-1 | `canvas_items` + `expand` geometry and quality at 1280×720, 1920×1080, 2560×1440, 3840×2160, 1280×800, 1920×1200, 2560×1080 (windowed; fullscreen at native where a monitor exists) | Probe scene: 1920×1080-anchored frame, `Label`s at 24/32/44 px, a 3D cube with a 1-px checker texture; capture each size | Logical viewport and glyph cap-height match the D7 table ±1 px; text not blurred at 2160p (edge ≤ 2 px transition); 3D checker resolved at native resolution; frame anchors hold at 16:10 and 21:9 | Glyphs blurred → re-evaluate `viewport` mode for none; `s ≠ min()` → recompute the D7 table and amend; 3D at base res → rendering ADR sets 3D scaling separately |
| SP-2 | `scale_mode` default/needed for 0.667; minimum window size setting | Same probe at 1280×720 with each `scale_mode`; try resizing below 1280×720 | Fractional scale applied at 720p; window cannot be made smaller than 1280×720 | Enforce minimum in `DisplayWindowPort` on resize |
| SP-3 | Runtime `Theme.set_font_size` re-lays out containers (25 options tab, 19 screen) | Toggle `escala_texto_ui` 1.00↔1.50 with the full options tab open; capture next frame | Layout correct by the next frame; no clipped text (AC-30-03 at 720p); apply cost < 2 ms | Fall back to swapping between three prebuilt Themes |
| SP-4 | AccessKit: accessible-name property (or default from `text`), disabled state, focus order, `AccessibilityLiveMode` members; `has_focus()` vs hover under dual focus | Windows Narrator / Accessibility Insights over a menu built with `A11y`/`FocusChain` | Narrator reads each control's visible text in visual order; disabled reads as unavailable; hover does not move keyboard focus | Record the gap; AC-30-16 stays pending (slice ships without reader support, D30-2) |
| SP-5 | `DisplayServer` window mode set/get, rejection, Alt+Enter detection by polling | `DisplayWindowPort` probe | `current_mode()` reflects Alt+Enter within one poll; apply returns the real mode | Detect via window size-changed signal instead of polling |
| SP-6 | JSON parse failure detection, NaN stringify, ints parsed as float, rename over existing (Windows/Linux) | **Shared with ADR-0004's spike** (same `FileStore`); Settings only adds a NaN/"nan"/`null` decode case | Parse error detectable without exceptions; `write_atomic` never leaves main invalid | ADR-0004 fixes the sequence; D3 orphan-adoption covers remove-then-rename |

## Alternatives Considered

### Alternative 1: Keep GDD F1 (`× alto/1080`) with stretch `disabled`
- **Description**: No engine stretch; every UI system multiplies by `alto/1080` (30 F1, 24 F2, 26 F3) and anchors by hand.
- **Pros**: Matches the GDD text literally; floor can be applied in physical px.
- **Cons**: Every Control, margin, icon and container must be scaled by script; one forgotten site breaks a resolution; the 4.7 default for new projects is `canvas_items` (risk of the double factor if the setting drifts); 16:10 uses `H/1080` (text 11 % larger than at 16:9 for the same width).
- **Estimated Effort**: High (scaling code in 5+ systems) vs. Low.
- **Rejection Reason**: Duplicates engine work across systems and is the failure mode TR-a11y-006 warns about.

### Alternative 2: Implement `escala_texto_ui` through `content_scale_factor`
- **Description**: Multiply the window's content scale by 1.25/1.50.
- **Pros**: One line; everything grows.
- **Cons**: Also scales icons and subtitles (violates 30 rules 9–10, the 2.25× of D30-5), reduces logical space by 33 % at 1.50 (layouts overflow), NOT SOURCEABLE.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Wrong scope of the setting.

### Alternative 3: Physical text floor (24 real px at every resolution) — D26-22 as written
- **Description**: Under `canvas_items`, logical size = `max(base × k, ceil(24 / s))`, recomputed on every window resize.
- **Pros**: 24 real px at 720p (24's and 26's intent); stricter legibility.
- **Cons**: Contradicts 30 rule 26 (the declared single definition: 16 real at 720p); makes `pequeno` = `medio` at 720p (D26-22) and the subtitle size option partly inert; resize-driven re-layout in every text system; at 720p every 24-px text becomes 36 logical, overflowing 1080-designed layouts.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Kept as the fallback if the user answers QQ-10 the other way; implemented by changing `UiTextScale.logical_size` only (one site), so reversal is cheap.

### Alternative 4: `ConfigFile` (`.cfg`) instead of JSON
- **Description**: Godot's INI-like `ConfigFile` for the user file.
- **Pros**: Native typed values.
- **Cons**: Not covered by the engine reference either; `controles` block is a nested Dictionary already exported as JSON by 1; save (ADR-0004) and catalogs are JSON, so one codec and one spike serve all.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Two formats for one team; no gain.

### Alternative 5: Store the grid index `n` in the file instead of the float
- **Description**: `"vol_voces": 10` meaning 10/20.
- **Pros**: No float drift at all.
- **Cons**: File unreadable to humans; changing `n_pasos` in data silently reinterprets every saved volume.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Re-quantizing the stored float on load (D2) already removes drift and survives a `n_pasos` change.

### Alternative 6: Unify Settings notices with the `GameState` bus
- **Rejection Reason**: Already rejected by ADR-0001 (Alternative 4 there / D2): 6 must not depend on 3 (GDD 6 rule 7).

## Consequences

### Positive
- One resolution factor, owned by the engine; GDD sizes become constants in logical px, testable without a window.
- Settings is fully unit-testable (memory store, fake clock, fake window); the same validator serves write and load, so file and UI cannot disagree.
- NaN has no representation to get wrong; corrupt and orphan files never block boot.
- Unverified engine APIs live in four files (`DisplayWindowPort`, `FileStore`, `SettingsCodec`, `A11y`).
- Safety limits cannot be raised by a data edit.

### Negative
- 24 F2, 26 F3/AC-26-08 and 30 F1 must be rewritten (C2, C3); 720p reading text is 16 real px (accepted by 30 R26, contested by 24/26).
- Writing only non-default keys means a changed default in data silently changes players who never touched that key (intended, but must be known when tuning).
- `FileStore.write_atomic` depends on an ADR not yet written (ADR-0004).

### Neutral
- The options cursor, not engine focus, is the selection source of truth in 25/27.
- `escala_texto_ui` stays provisional; removing it is a data + one-constant change.

## Risks

| Risk | Prob. | Impact | Mitigation |
|---|---|---|---|
| SP-1 shows `expand` geometry differs from `min(W/1920, H/1080)` | Low | Medium | Table D7 is derived, not hard-coded; amend table, no code depends on `s` (G-6) |
| Text blurry at 2160p under `canvas_items` | Low | High (visual product) | SP-1 before any UI story; fallback to MSDF fonts or font oversampling via ADR-0016 |
| Theme re-layout lags or clips at 1.50/720p | Medium | Medium | SP-3; prebuilt-Theme fallback; AC-30-03 screenshots |
| AccessKit API differs from expectation | Medium | Low (no reader support promised) | Single-site `A11y`; AC-30-16 pending, not blocking the slice |
| User rejects the logical floor (QQ-10) | Medium | Low | Alternative 3 in one function + data floor; table recomputed |
| Catalog drift from GDD 6 (18 keys) | Medium | Medium | `RESET_ALL_KEY_COUNT` check at load + T-S08 |
| Two instances overwrite each other's file | Low | Low | Out of slice scope (GDD 6 Edge Cases); last write wins |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| ajustes-persistentes.md (6) | TR-settings-001: closed catalog in `defaults.json`, undeclared key rejected | D1 schema, `SettingsCatalog`, `_reject` |
| ajustes-persistentes.md (6) | TR-settings-002: always-valid sync read; write applied at once | D2 canonical memory, `_commit` assigns before notify |
| ajustes-persistentes.md (6) | TR-settings-003, -004: clamp/NaN/type/enum validation; grid quantization comparing `n` | D2 `canonicalize`, `grid_index` (multiply-first, `QUANT_EPS`) |
| ajustes-persistentes.md (6) | TR-settings-005, -006: own notice (key, old, new), `controles` key-only, bus semantics | D4 on `NoticeChannel` #2, cap 64 |
| ajustes-persistentes.md (6) | TR-settings-007: survive scene changes, auto-unsubscribe | Autoload (ADR-0009), `SubscriptionBag`, `is_valid()` pruning |
| ajustes-persistentes.md (6) | TR-settings-008, -009: 3 states, READY before «ajustes aplicados», pre-READY policy | D5, `SettingsSafeValues` |
| ajustes-persistentes.md (6) | TR-settings-010…012: versioned file, tolerant load, single corrupt copy | D3 paths, `format_version`, `_quarantine` |
| ajustes-persistentes.md (6) | TR-settings-013, -014: deferred save 0.5/5.0 s, real time, snapshot, retry, non-blocking quit | D6 `step()`, `_change_gen`, `flush_pending` |
| ajustes-persistentes.md (6) | TR-settings-015: atomic write, orphan tmp, create folder | D3 `write_atomic`, orphan rule, `ensure_dir` |
| ajustes-persistentes.md (6) | TR-settings-016: opaque `controles` block | D3/D4, `set_controls_block`, deep copy |
| ajustes-persistentes.md (6) | TR-settings-017: volume curve, mute = linear 0, never `log(0)` | `VolumeLevel.from_index` (delivery to buses: ADR-0008) |
| ajustes-persistentes.md (6) | TR-settings-018: window mode applied by 6, rejection, external sync | D10 `WindowPort` + poll (SP-5) |
| ajustes-persistentes.md (6) | TR-settings-019: invalid catalog → `CATALOGO_INVALIDO` + param | D1 validation list (incl. `reset_count`) |
| ajustes-persistentes.md (6) | TR-settings-020: outside state/save; reset all = 18, exclusions | D3 separate folder; D1 `reset` flag + `RESET_ALL_KEY_COUNT` |
| ajustes-persistentes.md (6) | TR-settings-021: testability without I/O | G-12, § Validation Criteria |
| opciones-de-accesibilidad.md (30) | TR-a11y-003: reset all = 18 | D1 |
| opciones-de-accesibilidad.md (30) | TR-a11y-004, -008: `escala_texto_ui` enum applied in the notice frame; not subtitles/icons/diegetic | D7 rule 4 `UiTextScale` |
| opciones-de-accesibilidad.md (30) | TR-a11y-005, -006: F1 and the double factor | D7 rules 1–3 and table |
| opciones-de-accesibilidad.md (30) | TR-a11y-007: reflow, no clipping at 1.50 | D7 + SP-3 (container rules: ADR-0016) |
| opciones-de-accesibilidad.md (30) | TR-a11y-009, -010: contrast and flash definitions, hard cap | D9 `A11yConstants`, `FlashGuard` |
| opciones-de-accesibilidad.md (30) | TR-a11y-012: fade 100 ms, single range 50–150 ms | D1 `reduce_motion_fade_s` validated against D9 range |
| opciones-de-accesibilidad.md (30) | TR-a11y-014: read in the notice frame | D4 synchronous drain |
| opciones-de-accesibilidad.md (30) | TR-a11y-015: accessible name, visual focus order | D8 + SP-4 |
| prompt-de-interaccion.md (24) | TR-prompt-018: F2 scale 720p–2160p, ultrawide anchored to 16:9 | D7 rules 2 and 5 (engine `s`, `SafeArea169`) |
| subtitulos.md (26) | TR-subs-014: `alto_px = max(round(base·s), 24)` | D7 rule 3: base sizes in logical px, floor checked in data (C3) |
| ordenador-correo-impresora.md (19) | TR-computer-013: 1920×1080 logical, 16:9 and 16:10, 1280×720 minimum | D7 settings + SP-1/SP-2 |
| ordenador-correo-impresora.md (19) | TR-computer-014: text ≥ 24 logical; disabled exposed as unavailable | G-7, D8 rule 4 |
| pantalla-de-titulo.md (27) | TR-title-015: text scales with `escala_texto_ui`, floor 24, fits 1280×720 and 3840×2160 | D7, T-A03, SP-1 evidence |

**Not addressed here** (other owners): TR-a11y-001, -002 (scope/UI layout: 25 UI ADR, user OQ 8), -011 (video tooling; this ADR only gives the constants), -013 (consumer list), -016, -017 (puzzle design), -018 (ADR-0006), -019 (ADR-0008), -020 (content, ADR-0005).

## Performance Implications
- **CPU**: reads are one `Dictionary` lookup; a write is validation + one channel drain; `step()` is a few integer compares per frame plus a window poll every 0.5 s. `UiTextScale.apply` runs only on change (budget < 2 ms, SP-3).
- **Memory**: < 10 KB (20 values, controls block, catalog).
- **Load Time**: two small JSON parses at boot (< 1 ms expected; not measured).
- **Disk**: ≤ 0.2 writes/s during continuous slider drags (GDD 6 F3), file < 4 KB.
- **Network**: none.

## Migration Plan

New code; no migration. Order: `SettingDef`/`SettingsCatalog` + T-S01 → validator/quantization + T-S03/T-S04 → `Settings` core with `MemoryFileStore`/`FakeRealClock` → `SettingsCodec` (after SP-6) → `WindowPort` (after SP-5) → `project.godot` stretch (D7) + SP-1/SP-2 → `UiTextScale` (SP-3) → `A11y`/`FocusChain` (SP-4) → `A11yConstants`/`FlashGuard`.

**Rollback plan**: stretch is one project setting plus G-6 (no script depends on `s`); reverting to Alternative 1 means re-adding the factor in `UiTextScale.logical_size` and the subtitle/prompt size functions. File format has `format_version` for a future migration.

## Validation Criteria

This ADR is right if: all `L` ACs of GDD 6 pass headless with no real I/O;
SP-1 screenshots match the D7 table ±1 px at the eight sizes with crisp text;
no UI script contains a resolution factor (G-6 scan clean); AC-30-03 passes at
720p/1.50 on the first try of the options tab.

### Test plan

Unit (gdUnit4, `tests/unit/settings/` and `tests/unit/a11y/`; doubles from
ADR-0009 D9 plus `FakeWindowPort`; fixtures as constant JSON strings per case):

| Test | Suite | Covers |
|---|---|---|
| T-S01 | `test_settings_catalog.gd` | 20 valued keys + `controles` match GDD 6 rule 1 (type, range, default); `reset` count = 18; each invalid param (`n_pasos` 5, `db_min` 0, `t_guardado_max` < 2×, missing/corrupt file, bad `reset_count`, `reduce_motion_fade_s` 0.2) → `RecordingFatalHandler` gets `CATALOGO_INVALIDO` + param | AC-01, AC-16a/b; TR-settings-001, -019 |
| T-S02 | `test_settings_read_write.gd` | Immediate read-after-write for float/bool/enum; `get_bool` on a float key → dev fail | AC-02, AC-04e/g; TR-settings-002 |
| T-S03 | `test_settings_quantize.gd` | AC-F1 table (0.512→10, 0.026→1, 0.024→0, **0.025→1**, 1.0→20); `campo_vision` 72→70, 72.5→75, 95→90+log; `multiplicador_pie` 1.3→1.25, 1.125→1.25, 3.5→3.0, 0.5→1.0; same-`n` write → no notice, no pending | AC-04d/f, AC-06b; TR-settings-004 |
| T-S04 | `test_settings_validation.gd` | NaN rejected (value kept + log); ±INF clamp; `"0,5"` in float, `"ventana2"`, int in bool, scalar in `controles`, unknown key → rejected; dev policy halts (recording `ErrorPolicy`) | AC-05a–d (L part), AC-04c; TR-settings-003 |
| T-S05 | `test_settings_notices.gd` | Exactly one (key, old, new); order A,B; write-inside-handler queued, no nesting; unsubscribe mid-drain; two writes same frame ordered; `controles` notice with `null`/`null`; ping-pong loop stops at 64 with log + dev fail | AC-06a–f, AC-04c; TR-settings-005, -006 |
| T-S06 | `test_settings_scene_subscribers.gd` | `SubscriptionBag.release_all()` mid-drain and after; invalid callable pruned | AC-06g; TR-settings-007 |
| T-S07 | `test_settings_states.gd` | UNLOADED/LOADING read/write → dev fail; release → default / safe value + log; READY before APPLIED; reads inside APPLIED see loaded values; no change notice during LOADING | AC-12, AC-17a/b; TR-settings-008, -009 |
| T-S08 | `test_settings_reset.gd` | Reset one (notice only if differs; pending); reset all: 18 keys, notices only for changed, `modo_ventana`/`advertencias_vistas`/`controles` untouched | AC-07, AC-07a; TR-settings-020, TR-a11y-003 |
| T-S09 | `test_settings_file_load.gd` | No file → defaults, zero log lines; per-key invalid (type, enum, `null`, `"nan"`) → default + one line each; out-of-range clamps; off-grid quantizes; unknown key not re-written; version greater/absent/non-numeric → quarantine; lower → partial; unreadable → corrupt copy byte-identical, single copy replaced; rename failure → READY + log, next save replaces; orphan tmp removed; tmp adopted only when main absent | AC-08a, AC-09, AC-10a–c, AC-11a/b, AC-15b, AC-04b, AC-F1 (load); TR-settings-010…012, -015, -016 |
| T-S10 | `test_settings_deferred_save.gd` | `FakeRealClock`: single change at 3.0 s → write at 3.5 s; 12 s drag every 50 ms → exactly 3 writes (5.0, 10.05, 12.5); pause/quit flush writes only if pending; change after snapshot keeps pending; write failure → pending, log, retry at +5.0 s, nothing shown; quit flush failure returns; folder missing → created, creation failure = write failure; only non-default keys and no NaN in the encoded text | AC-08b, AC-14a–e, AC-15a; TR-settings-013, -014 |
| T-S11 | `test_volume_level.gd` | AC-F2a/b values, n = 0 → muted, linear exactly 0 | AC-F2a/b; TR-settings-017 |
| T-S12 | `test_settings_window_mode.gd` | `FakeWindowPort` rejection on write → real mode, log; rejection during LOADING → no notice; external change seen by poll → notice + pending | AC-13 (L part); TR-settings-018 |
| T-A01 | `test_ui_text_scale.gd` | `logical_size(24, 1.5) == 36`; `apply()` calls `set_font_size` for every entry, skips subtitle types; factor from `escala_texto_ui` | TR-a11y-004, -005, -008, TR-title-015 |
| T-A02 | `test_flash_guard.gd` | 3 flashes in 1000 ms allowed, 4th refused, allowed again after window slides (`FakeRealClock`) | TR-a11y-010 |
| T-A03 | `test_text_floor.gd` | Every entry of `text_sizes.json` and of the base Theme reading types ≥ `TEXT_MIN_PX`; subtitle bases 24/32/44 ≥ floor | G-7; TR-a11y-005, TR-subs-014, TR-computer-014 |
| T-A04 | `test_focus_chain.gd` | `link_vertical` sets top/bottom neighbours in row order, wrap on/off | TR-a11y-015 (structure only) |
| T-A05 | `test_a11y_constants.gd` | Constants equal GDD 30 rules 18, 24–27 values | TR-a11y-009, -010, -012 |

Integration (`tests/integration/settings/`): T-I1 real `user://` round-trip
in a temp profile including corrupt copy and orphan tmp (AC-15c optional kill
test); T-I2 Boot order with real `Settings` + `FakeInputRouter` (InputRouter
gets APPLIED and imports `controles`); T-I3 `escala_texto_ui` 1.50 at 1280×720
on 25/27/19 → screenshots (AC-30-03, UI, BLOCKING); T-I4 AC-13 on the real
`DisplayWindowPort` (manual, after SP-5). Lint: G-6 scan (`/ 1080` in
`src/ui/`), G-9/G-11 scans (engine names outside their adapters).

## Spike Results (2026-11-11)

Godot 4.7.2 stable, Windows. Headless: `tests/unit/engine_facts/adr0007_stretch_theme_and_json_test.gd`
(9 tests, PASS, run alone). Windowed: `prototypes/ui-spike/` + `--write-movie`; frames in
`production/qa/evidence/ui-spike/`. Status stays `Proposed`.

| Spike | Result | Observed value | Fallback needed |
|---|---|---|---|
| SP-1 | PASS (geometry, text); 3D NEEDS_WINDOWED | `canvas_items` + `expand`, base 1920×1080: logical viewport and `Window.get_final_transform().get_scale()` equal `s = min(W/1920, H/1080)` to 4e-8 / 0.0 px at 1280×720 (1920×1080, 0.6667), 1920×1080 (1.0), 2560×1440 (1920×1080, 1.3333), 3840×2160 (1920×1080, 2.0), 1280×800 (1920×1200, 0.6667), 1920×1200 (1920×1200, 1.0), 2560×1080 (2560×1080, 1.0). Both the headless embedded `Window` and the real window agree. Glyph cap height / edge widths: see ADR-0016 SP-16A (≤ 2 px transition, none blurred at 2160p). The rendered image size equals the window size (3840×2160 at 2160p), so the 3D buffer is at window resolution; the 1-px 3D checker was **not** rendered: NEEDS_WINDOWED. 16:10 and 21:9 anchors hold (corner labels at the window edges, 1920×1080 frame centred). **Operational note:** the OS clamps a decorated window taller than the desktop (2560×1440 request gave 2560×1183); borderless + `DisplayServer.window_set_size` reached the true size | No |
| SP-2 | PARTIAL | `Window.content_scale_stretch` (`fractional` = 0) exists and gives 0.6667 at 720p. Embedded `Window.min_size = 1280×720` clamps a requested 800×600 to 1280×720. OS-level minimum on a real top-level window (user resize below 720p): NEEDS_WINDOWED. The project setting name `display/window/stretch/scale_mode="fractional"` loaded without error in the prototype | Enforce minimum in `DisplayWindowPort` if the OS allows less |
| SP-3 | PASS (headless) | `Theme.set_default_font_size` 32→48 (×1.5) on a `VBoxContainer` with one `Label`: minimum size (276×45)→(414×67) by the next frame; the call itself took ~1 µs (the re-layout is deferred); the 25 options tab with a full screen and the 720p clipping check (AC-30-03): NEEDS_WINDOWED | No |
| SP-4 | NEEDS_MANUAL_SCREEN_READER | Needs Narrator / Accessibility Insights; not automatable | Record the gap (D30-2) |
| SP-5 | PARTIAL | `DisplayServer.get_name()` = `headless`, `window_get_mode()` = 1 (minimised) under the dummy display: the getter works but reports a meaningless mode there. Set/Alt+Enter poll: NEEDS_WINDOWED | Window size-changed signal if polling fails |
| SP-6 | PASS | `JSON.new().parse("{\"a\": 1,")` returns error 43 (`Expected '}'`) with no exception; `get_error_line()` is 0 on a one-line input. `JSON.stringify({"v": NAN})` = `{"v":null}` and `INF` = `1e99999`; `parse_string` returns `inf` for `1e999`, `null` (whole result) for bare `NaN`, `"nan"` stays a String, `null` stays null. Ints parse as float (`typeof` = `TYPE_FLOAT`). A NaN setting therefore round-trips as `null` and must be rejected by the codec. Rename-over-existing on Windows/Linux stays with ADR-0004 | No |

## Open Items

| ID | Item | Owner / route |
|---|---|---|
| OI-1 | **USER (QQ-10)** — confirm the **logical** 24 px floor (720p reading text = 16 real px; D26-22 dissolved: `pequeno` 16 / `medio` 21.3 at 720p). If rejected: Alternative 3 (24 real px everywhere) in `UiTextScale.logical_size` + subtitle size function; table D7 recomputed | User; then GDDs 24, 26 |
| OI-2 | **USER (QQ-08)** — `escala_texto_ui` closed for the slice? Default here: yes, 18 keys. If no: remove key from `defaults.json`, `RESET_ALL_KEY_COUNT` = 17. `reducir_movimiento` scope beyond slice §14 is not decided here (one key; consumers decide) | User |
| OI-3 | `FileStore.write_atomic` / `rename` platform sequence: **resolved 2026-11-10** — ADR-0004 `FileStore` gains `read_text`/`write_atomic` (delete-then-rename, D7 rule); primitives return `Error` (ADR-0004 shape adopted here). JSON behaviour still open (shared SP-6) | ADR-0004 (shared SP-6) |
| OI-4 | Container/reflow rules, `SafeArea169`, font choice and crispness fallback | ADR-0016 |
| OI-5 | **Resolved for the slice (ADR-0016 OI-10): root-canvas overlay in `SceneUi`, scaled by D7.** Whether 19's computer screen is a root-canvas overlay (scaled by D7) or a `SubViewport` on a 3D mesh (needs its own scaling) | ADR-0016 / 19 |
| OI-6 | **Resolved: ADR-0013 (hands: none), ADR-0014 (28), ADR-0015 (29).** Which effects count as "flash" for `FlashGuard` | Rendering ADRs of 28/29 |
| OI-7 | Spikes SP-1…SP-5 results written back to `docs/engine-reference/godot/modules/ui.md` | Implementation, first UI story |

### Contradictions detected (for `/architecture-review`)

1. **C1 Clock name. Resolved: `RealClock` (ADR-0002).** ADR-0002 names the real-time source `RealClock`/`FakeRealClock`; ADR-0009 (`ServiceContext.real_clock: MonotonicClock`, `FakeMonotonicClock`) names it `MonotonicClock`. This ADR uses `RealClock` (ADR-0002 owns time); ADR-0009 should rename.
2. **C2 Window factor in GDD formulas.** 30 F1, 24 F2 (`clamp(altura/1080, 0.67, 2.0)`) and 26 F3 (`s = alto_viewport/1080`) all multiply by the window height; under D7 that is the engine's job. Also, at 16:10 the GDDs use `H/1080` (1.111 at 1920×1200) while the engine uses `min(W/1920, H/1080)` (1.0). GDDs 24, 26, 30 to drop the factor.
3. **C3 Floor space (D26-22, QQ-10).** 30 rule 26 defines the floor in logical px (16 real at 720p); 26 F3/AC-26-08 and 24 F2 (`max(28·s, 24)`) apply it after scaling (24 real at 720p). Resolved in favour of 30 (the declared single definition) pending OI-1; AC-26-08 becomes "720p `medio` = 32 logical (21.3 real), `pequeno` = 24 logical (16 real)".
4. **C4 `tope_destellos_s` as a tuning knob.** 30 § Tuning Knobs lists it (2–3, «no subir»); this ADR makes it a code constant (D9). 30's table should mark it "code constant".
5. **C5 Window rejection notice.** GDD 6 AC-13 says a rejected `modo_ventana` write "emits the change notice"; when the applied mode equals the previous value there is no real change, so D10/`_commit` emits nothing (rule 7: no notice without a real change) and 25 re-reads after `set_setting` returns. A notice is emitted when the applied mode differs from the previous one.
6. **C6 Orphan temporary.** GDD 6 Edge Cases always ignores the `.tmp`; D3 adopts it when the main file is absent (extension, does not contradict the case where main exists).

## Related

- ADR-0001 Event bus and fact contract — depends on (`NoticeChannel`, callback signature).
- ADR-0002 Pause and game time — depends on (`RealClock`, `ALWAYS`, flush on pause O3).
- ADR-0003 Scene loading — consumer (`get_bool(&"reducir_movimiento")`).
- ADR-0004 Save format (pending) — shares `FileStore` and SP-6.
- ADR-0009 Service composition — depends on (autoload #5, Boot step 6, doubles).
- ADR-0016 Subtitles and UI text rendering (pending) — enabled by D7.
- `design/gdd/ajustes-persistentes.md`, `design/gdd/opciones-de-accesibilidad.md`, `design/gdd/subtitulos.md`, `design/gdd/prompt-de-interaccion.md`, `design/gdd/ordenador-correo-impresora.md`, `design/gdd/pantalla-de-titulo.md`, `design/gdd/menu-de-pausa.md`.
- `docs/architecture/architecture.md` § Required ADRs (ADR-0007), QQ-08, QQ-10, QQ-15; `docs/architecture/tr-baseline-provisional.md`.
