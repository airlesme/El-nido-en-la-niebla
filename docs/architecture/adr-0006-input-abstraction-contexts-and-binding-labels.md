# ADR-0006: Input Abstraction, Context Stack and Binding Labels

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`. It cannot
> move to `Accepted` before spikes S-0006-A … S-0006-F (§ Validation Criteria)
> have run on Godot 4.7.2 and their results are written into § Spike Results,
> and before ADR-0001, ADR-0002, ADR-0003 and ADR-0009 are `Accepted`.

## Date

2026-11-10

## Last Verified

2026-11-10 (against `docs/engine-reference/godot/` as last verified 2026-10-17,
`design/gdd/entrada-y-controles.md` round 10, `docs/architecture/architecture.md`
v1, `docs/architecture/tr-baseline-provisional.md`, ADR-0001/-0002/-0003/-0009
`Proposed`)

## Decision Makers

technical-director (autonomous mode, `modes.automation: autonomous`); user
approval pending at batch close.

## Summary

System 1 (Entrada y controles) must turn keyboard, mouse and gamepad into one
vocabulary of logical actions, own the context stack (including every
`sin control` operation that ADR-0003 calls), recognise pointer gestures, drive
a virtual cursor, and expose rebinding, conflict validation and
`get_binding_label(accion, dispositivo)` for 24, 25 and 30. Decided: the
`InputRouter` autoload owns its **own binding table** (data-driven from
`assets/data/input/default_bindings.json`) and matches normalised `RawInput`
records produced by one engine adapter; Godot's Input Map is used only for the
fixed `ui_*` GUI navigation; all logic below the adapter (stack, deadzone,
hysteresis, gestures, rebinding, labels) is pure GDScript testable without the
engine, and every engine-dependent behaviour sits behind spikes S-0006-A…F.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Input · UI (focus, text field) · Core (process mode, window focus) |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH (4.5 SDL3 gamepad backend, 4.6 dual focus, 4.7 `DEVICE_ID_*` are all post-cutoff; `VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/input.md` (4.7 `DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD`, 4.6 dual focus, 4.5 SDL3, `Input.get_vector`, `is_action_just_pressed`, `InputEventMouseButton`, `InputEventKey.keycode`, `InputEventJoypadButton.button_index`, `JOY_BUTTON_A`, `grab_focus()`); `modules/ui.md` (dual focus, recursive Control disable, focus neighbours); `breaking-changes.md` (Input row `DEVICE_ID_*`, UI dual-focus row); `deprecated-apis.md` (`event.device == 0` → event type or `DEVICE_ID_*`; `Time.get_ticks_msec()`); `current-best-practices.md` (dual focus, `DEVICE_ID_*`); `docs/architecture/architecture.md` §§ Data Flow 1/4, API Boundaries/Entrada, Required ADRs row ADR-0006, QQ-16 |
| **Post-Cutoff APIs Used** | `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` (4.7) — only to *assert* mouse/keyboard events are never treated as joypad 0; SDL3 joypad backend (4.5) — implicitly, for every gamepad event; dual focus (4.6) — `grab_focus()` moves only keyboard/gamepad focus |
| **Verification Required** | S-0006-A raw joypad events; S-0006-B gamepad family; S-0006-C connect/disconnect; S-0006-D mouse motion, mouse mode and `DEVICE_ID_*`; S-0006-E window focus and `_input` under pause; S-0006-F text field and dual focus (§ Validation Criteria) |

### Engine API sourcing

Every engine call or behaviour this ADR depends on. All NOT SOURCEABLE items
are confined to **one file**, `src/input/engine_input_adapter.gd` (‡), and are
implemented only after the named spike confirms them on 4.7.2.

| API / behaviour | Status | Spike |
|---|---|---|
| `InputEventKey`, `InputEventMouseButton`, `InputEventJoypadButton` types; `keycode`, `button_index`, `JOY_BUTTON_A` | Sourced: `modules/input.md` § Input Events, § Gamepad | — |
| `InputEvent.device`, `InputEvent.DEVICE_ID_MOUSE`, `InputEvent.DEVICE_ID_KEYBOARD` (4.7) | Sourced: `modules/input.md` § 4.7, `breaking-changes.md`, `deprecated-apis.md`. Their numeric values: **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | S-0006-D |
| `Control.grab_focus()` moves keyboard/gamepad focus only; mouse hover is separate (4.6) | Sourced: `modules/input.md`, `modules/ui.md` § Focus Management | S-0006-F (behaviour with `LineEdit`) |
| `Input.get_vector`, `Input.is_action_just_pressed` | Sourced: `modules/input.md` § Input Actions — **not used** for gameplay actions (§ Alternatives 1) | — |
| `Time.get_ticks_msec()` (behind `RealClock`) | Sourced: `deprecated-apis.md` (owned by ADR-0002) | — |
| `InputEventMouseMotion` and its relative-motion field; units under captured mouse and under the project stretch mode | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`** | S-0006-D |
| `InputEventJoypadMotion` (axis index, axis value), value range, whether any engine deadzone is applied to the event value | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`** (only "API unchanged" under SDL3) | S-0006-A |
| `Input.get_joy_axis(device, axis)` (raw axis polling) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`**; not used (axes are cached from events) | — |
| Joypad name / GUID query (`Input.get_joy_name`, `Input.get_joy_guid`, or SDL3 equivalents) for family detection (A / ✕) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`** | S-0006-B |
| Joypad connection signal (`Input.joy_connection_changed`) and connected-pad list (`Input.get_connected_joypads()`) under SDL3, including while the tree is paused | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`** | S-0006-C |
| `Input.mouse_mode` (captured / visible / hidden) and restoring it after focus loss | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`** | S-0006-D |
| Window/application focus-out notification | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | S-0006-E |
| `_input()` delivered to a `PROCESS_MODE_ALWAYS` autoload while `SceneTree.paused` | **NOT SOURCEABLE** — owned by ADR-0002 (NS-4, spike S4) | ADR-0002 S4 |
| Order `_input` → GUI → `_unhandled_input`, `Viewport.set_input_as_handled()` | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; the design does not rely on it (D9) | S-0006-F (observe only) |
| Key auto-repeat flag (`InputEvent.is_echo()`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`**; not relied on (echo detected by own pressed set, D2) | S-0006-A (observe only) |
| `KEY_*` constants other than `KEY_ESCAPE`; `InputEventKey.physical_keycode`, `unicode`, `as_text()` / key name strings | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/input.md`** (`KEY_ESCAPE` and `keycode` are sourced) | S-0006-D |
| `LineEdit` focus signals (`focus_entered` / `focus_exited`) and whether a mouse click on a `LineEdit` gives it keyboard focus under 4.6 dual focus | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/modules/ui.md`** (only "mouse hover ≠ keyboard focus") | S-0006-F |
| Project Input Map `ui_*` events (arrows, Enter, Esc, D-pad, left stick, south/east) declared in `project.godot` and read by GUI focus navigation | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | S-0006-F |
| Main-loop order between `_input`, `_process`, `_physics_process` of different nodes | **NOT SOURCEABLE** (ADR-0001 NS-7; `architecture.md` § Data Flow) — not relied on | — |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (notice names `input_device_changed`, `input_context_changed`, `no_control_absorbed`; synchronous FIFO drain; subscription to `scene_load_started` / `scene_load_finished` / `scene_load_failed`, `pause_closed`; Settings `settings_applied` via ADR-0007's names). ADR-0002 (`InputRouter` is `PROCESS_MODE_ALWAYS`; `RealClock` for polling, hysteresis and gesture timing; **`GameClock`** for the blocking-context safety cap, TR-input-005; spike S4 for input under pause). ADR-0003 (the `InputContexts` contract: `open_no_control`, `transfer_no_control`, `request_exploration`, `restore_menu`, `reset_stack_on_unload`; owner `StringName`s; the order «emit iniciada → open»). ADR-0009 (`InputRouter` is autoload #4 registered as `InputRouterAutoload`; construction without I/O; `setup(ctx)` at boot step 5; `ServiceContext.input`). All four are `Proposed`; this ADR must be re-checked when each is `Accepted`. |
| **Enables** | ADR-0011 (interaction and pointer picking: consumes the action sinks, `PointerTargetProvider`, gesture events, blocking transitions); ADR-0012 (player: `get_move_vector()`, `consume_look_delta()`); ADR-0016 (HUD/UI: cursor layer, glyph atlas, `CursorVisibility`, focus colours under dual focus); ADR-0007 (Settings: the opaque `controles` block and the handling-settings list); ADR-0017 (scene director: `open_no_control` / `close_no_control` / `transfer_no_control` / `request_exploration` as caller `&"scene_director"`). Closes QQ-16 and ADR-0003 O3. |
| **Blocks** | Epic for system 1; every story of 2, 7, 19, 20, 22, 24, 25, 27, 30 that reads an action, a context or a binding label; S0 milestone "walk the grey `planta` with keyboard and gamepad" |
| **Ordering Note** | ADR-0003 must be amended (Open Item OI-1) to pass the new third argument of `open_no_control` from `SceneLoader.request_load`. ADR-0001 registry must be amended for the `input_context_changed` payload and the owner example (OI-2). Neither amendment changes those ADRs' decisions. |

## Context

### Problem Statement

The slice mixes three handling modes — first-person walking, objects in hand,
and pointer puzzles in close-up views — and must be fully playable with either
keyboard + mouse or a gamepad, switching at any time, fully rebindable for
accessibility (slice §5). Nine systems read input (2, 7, 19, 20, 22, 24, 25,
27, 30) and four drive the context stack (4, 7, 21, 22, 25). Without one owner,
each puzzle reinvents its controls, the `sin control` handoff between 4 and 21
(ADR-0003) has no implementer, and 24/18 cannot show the right glyph. This must
be decided now because ADR-0003 already calls an `InputContexts` contract whose
signatures it delegates here (O3), and ADR-0011/-0012/-0016 cannot start
without the action and pointer contracts.

### Current State

No code. `architecture.md` § API Boundaries/Entrada sketches a Spanish-named
API (`entrar_en`, `sin_control_abrir`, …, `rebind`, `es_imprimible`) marked ‡;
ADR-0003 already calls an English-named `InputContexts` port
(`open_no_control`, …). The GDD (round 10) fixes the rules; QQ-16 asks for the
rebinding API, `es_imprimible`, the handling-settings list and the `sin control`
signatures.

### Constraints

- Godot 4.7.2, GDScript, typed. The model's knowledge stops around 4.3; SDL3
  (4.5), dual focus (4.6) and `DEVICE_ID_*` (4.7) are post-cutoff, so engine
  surface must be minimal and spiked.
- `InputRouter` runs `PROCESS_MODE_ALWAYS` (ADR-0002) and is autoload #4
  (ADR-0009): no I/O or subscriptions before `setup(ctx)`; never named outside
  `Boot`.
- Same-frame guarantees come from explicit synchronous calls and the bus drain
  (ADR-0001), never from callback order between nodes (NS-7).
- Gameplay values data-driven (`default_bindings.json`); all public methods
  unit-testable via injection (coding standards).
- One programmer; the slice has no local multiplayer, no touch, no
  `VirtualJoystick`, no gyro (4.7 features are out of scope).

### Requirements

- One vocabulary of actions; nothing outside system 1 names a key or button
  (TR-input-001).
- Context stack with exactly the GDD 1 rule 6 operations and notices
  (TR-input-003, -004), safety caps on game time (TR-input-005), load gating of
  pause (TR-input-006), blocking transitions (TR-input-007), pause triggers
  (TR-input-008, TR-pause-004, -021, TR-title-016).
- F1–F8 implemented bit-for-bit as pure functions (TR-input-002, -009 … -012).
- Rebinding, validator, minimums, import/export, labels (TR-input-015, -016,
  -018, TR-pause-016, -017).
- Text field precedence (TR-input-017, TR-computer-003, -004, -011, -012).
- Per-event cost negligible: budget ≤ 0,05 ms per frame on the target PC for
  routing + gestures + cursor (architecture.md frame budget gives Foundation no
  explicit share; this is this ADR's own cap).

## Decision

**D1 — A layer *beside* the Input Map, not on top of it.** `InputRouter` owns
a `BindingTable` loaded from `assets/data/input/default_bindings.json` and
overlaid with the player's `controles` block from Settings (6). It matches
normalised `RawInput` records against that table itself. The engine Input Map
is **not** used for any gameplay action (`mover`, `mirar`, `interactuar`,
`pausa`, `atrás`, `mover_cursor`, `seleccionar`) and is **never** written at
runtime. The Input Map keeps only Godot's built-in `ui_*` actions, declared
once in `project.godot` with the GDD defaults (arrows/Enter/Esc, D-pad, left
stick, south/east), which are fixed and not rebindable (GDD 1 rule 15). The
same fixed `ui_*` inputs are listed in the JSON section `ui_fixed` so the
validator (D11) never has to read the Input Map; a CI check compares both
(S-0006-F). Rationale: deterministic slot order for labels, two slots per
action and device, rebinding without `InputMap` mutation APIs (NOT
SOURCEABLE), own radial deadzone, and a fully engine-free test surface.

**D2 — One engine adapter, everything else pure.** `EngineInputAdapter`
(`Node`, child of `InputRouter`, `ALWAYS`) is the only file that reads
`InputEvent` fields, joypad names, connection signals, mouse mode and window
focus. It converts each event into a `RawInput` (`kind`, `code`, `device`,
`pressed`, `value`, `motion`) and calls `InputRouter.feed(raw)`. Device class is
decided **by event type** (`InputEventKey` / `InputEventMouse*` → keyboard+mouse;
`InputEventJoypad*` → gamepad); `event.device` is read only for joypad ids and
is **never** compared with `0` (4.7, `deprecated-apis.md`). Auto-repeat is
detected by the router's own pressed set (a press for an input already down is
an echo and is dropped), not by `is_echo()`. Tests drive `feed()` directly with
a `FakeEngineInput`.

**D3 — Context stack with typed entries.** The stack is `Array[StackEntry]`,
`StackEntry = {context, requester, cursor_pos, owner, declared_s, cap_deadline}`
(the last three only for `SIN_CONTROL`). Only the top receives actions. Generic
`enter(ctx, requester)` / `exit(ctx, requester)` serve 7, 22, 25, 27; the
`sin control` operations are separate methods (D4) and `enter`/`exit` reject
`SIN_CONTROL`. Entering the context already on top is ignored (no notice);
exiting a non-top context is rejected and logged. Empty stack after any pop →
`[EXPLORACION]`. Every effective change emits `input_context_changed`
`{anterior, contexto}` once, and runs the **change hook**: cancel the current
hold/gesture, latch every currently-pressed trigger input as
*ignored-until-release* (covers F8 "held key does not fire", GDD Edge Case
"`seleccionar` held entering `vista cercana`", TR-pause-008 "closing click does
not reach the world"), restore the entry's `cursor_pos`, apply its mouse mode.
The continuous axis `mover` is **not** latched (F8, contract 2↔7).

**D4 — `sin control` operations (closes QQ-16 and ADR-0003 O3).** Owners are
`StringName`s: `&"scene_loader"` (4), `&"scene_director"` (21) and
`&"input_router"` (fallback only). Operations, all logged when rejected and
none emitting when rejected:

| Operation (GDD 1 rule 6) | Method | Effect |
|---|---|---|
| *Abrir* | `open_no_control(owner, declared_s, absorbs_foreign := false)` | Top is `SIN_CONTROL` → reject. Foreign `SIN_CONTROL` anywhere and `absorbs_foreign and owner == &"scene_loader"` → **discard** (below). Foreign `SIN_CONTROL` under the top otherwise → reject (AC-E13). Else push; `declared_s <= 0` → 3 s + log. Cap = `GameClock.deadline(declared_s + margin_s)` |
| *Cerrar* | `close_no_control(owner)` | Top must be `SIN_CONTROL` owned by `owner`; pop; restore below (`[MENU, SIN_CONTROL(21)]` → `MENU` is restored and logged as 21 misuse) |
| *Traspasar* | `transfer_no_control(new_owner, declared_s)` | Top must be `SIN_CONTROL`; change owner and duration in place; cap renewed from now; **no** notice, stack unchanged |
| *Pedir `exploración`* | `request_exploration(owner)` | Top must be `SIN_CONTROL` owned by `owner`; stack becomes `[EXPLORACION]` (any `menú` below discarded); one notice (`sin control` → `exploración`); sets `in_game = true` |
| *Reponer `menú`* | `restore_menu()` | Stack becomes `[MENU(&"title")]`; notice if top changed; `in_game = false`; clears `carga_en_curso`; drops pending pause |
| *Descartar la pila* | inside `open_no_control` | Stack becomes `[SIN_CONTROL(scene_loader)]`; emits `input_context_changed` (old top → `sin control`) **even if the old top was already `sin control`** (owner changed), then `no_control_absorbed {dueno}` once per discarded owner |
| *Reinicio al descargar* | `reset_stack_on_unload()` | Stack becomes `[current SIN_CONTROL entry]` with owner, duration and cap **kept**; notice only if top was not `SIN_CONTROL`; none current → open `&"input_router"` 3 s + log. Never called on full unload (ADR-0003) |

The third argument of `open_no_control` is new: `SceneLoader` passes `true`
iff the accepted load's reason is `partida_nueva` or `reanudar` (GDD 4 rule
7). This keeps Entrada ignorant of 4's `Reason` enum and makes the discard
independent of whether `scene_load_started` has already been drained
(ADR-0003 emits «iniciada» and *then* opens; inside a running drain the notice
would arrive after the open). `carga_en_curso` is set by
`open_no_control(&"scene_loader", …)` **and** by `scene_load_started`, and
cleared by `scene_load_finished` / `scene_load_failed` / `restore_menu()`.

**D5 — Blocking transitions are not stack entries.** 7 calls
`begin_blocking(owner, max_s := -1.0)` / `end_blocking(owner)` (GDD 1 rule 8).
While active only `pausa` and `repasar_bolsillo` pass; everything else is
dropped, never queued. Cap = `GameClock.deadline(max_s if max_s > 0 else
transition_cap_s)` (3 s†). Both caps (D4, D5) live on **`GameClock`**, so they
freeze with the pause (ADR-0002 D2 row, TR-input-005); they are polled in
`_process` of the `ALWAYS` router. Expiry: log error, release (`sin control`
cap expiry acts as a *close* by its owner; empty → `[EXPLORACION]`).

**D6 — Delivery: sinks for triggers, polling for axes.** Per (context,
action) there is at most one sink, `Callable(ev: ActionEvent) -> void`,
registered with `bind_sink(ctx, action, sink)` by the system that owns that
reaction (7: `interactuar`/`leer`/`rotar_objeto`/`atrás` of its modes and the
pointer gestures; 20: `repasar_bolsillo`; 22: `seleccionar` in `llamada`; 25:
`pausa`/`ui_atrás` close in `menú`). A second bind replaces and logs. One raw
event produces **at most one** action for the top context, chosen by the
context's precedence list in data (`menú`: `ui_atrás` before `pausa`, so the
shared `Esc` gives one close, TR-pause-008). Axes are pulled synchronously:
`get_move_vector()` (2, physics tick) and `consume_look_delta()` (2, per
frame; F2 mouse pixels accumulated since last consume, plus F3 stick); both
return zero outside the context that owns them. The `ui_*` focus navigation in
`menú`, `llamada` and `ordenador` is **native GUI** (D1); the router does not
re-emit `ui_arriba/abajo/izquierda/derecha/aceptar` — it only observes them for
device detection. Held repetition of `ui_izquierda/derecha` (TR-pause-013) is
25's, in its Controls (ADR-0016).

**D7 — Device hysteresis (F7) and device notice.** Active device starts as
keyboard+mouse. `DeviceTracker` (pure, `RealClock`) counts as use: any key /
mouse button / pad button press immediately; mouse motion when Σ|relative| in
a sliding `T_m` window ≥ `N_m`; a stick when `|v| ≥ dz_in + m_s` sustained
`t_s`. After a switch, motion-only use cannot switch back during `t_lock`
(presses always can). On an effective switch: emit `input_device_changed
{dispositivo: &"teclado_raton" | &"mando"}` once, bump `bindings_revision`
(glyphs change), and notify the cursor (virtual ↔ real). Two pads are one
logical gamepad; `last_pad_id` is the last pad that produced *use*.

**D8 — Own radial deadzone (F1) on raw axes.** The adapter caches the last
`InputEventJoypadMotion` value per (pad, axis); the router builds `Vector2`
per stick and applies F1 (`dz_in`, `dz_out`) radially. No engine deadzone is
used (gameplay does not touch the Input Map). Whether event values arrive
already deadzoned is S-0006-A; if they do, F1 still holds for `dz_in` above
the engine's floor and the floor is recorded.

**D9 — Virtual cursor and pointer targets.** In `VISTA_CERCANA`, `ORDENADOR`,
`LLAMADA` and `MENU`, `PointerCursor` (pure) holds `p` in logical pixels
bounded by `ViewportMapper.logical_rect()` (1920×1080 is the 16:9 reference;
wider/taller under `expand` — ADR-0016 OI-3, ADR-0011 C1). With mouse it mirrors the real cursor (position from the adapter,
converted to logical pixels by `ViewportMapper` ‡, owned by ADR-0016's
resolution decision). With gamepad it integrates F5a (stick of greater
magnitude in close-up/computer; right stick only in `llamada`/`menú`) and F5b
magnetism over targets supplied by the context's `PointerTargetProvider`
(`targets() -> Array[PointerTarget]{id, center_px, tolerance_px,
gestos_aceptados, focus_order}`), registered by 7 (puzzles, ADR-0011), 19, 22
and 25. The real mouse is **never warped**. For GUI screens the provider maps
the hovered target to a `Control` and calls `grab_focus()` (dual focus: moves
keyboard/gamepad focus only, `modules/ui.md`), so south/`ui_aceptar` activates
it natively — no synthetic mouse events. Visibility is a separate flag
`set_cursor_visible(requester, visible)`, used by 22 (hidden until `OPCIONES`,
D33); drawing is ADR-0016's `CursorLayer`. `delta` is clamped to 0,1 s (F5b).

**D10 — Gesture recogniser (F4, F6, rule 13, rule 14).** `GestureRecognizer`
(pure) runs per `seleccionar` press. At press it asks the provider for the
target under `p` and freezes its `gestos_aceptados`. First signal wins:
`elapsed ≥ t_hold` (counts only if `mantener` accepted) or `|p − p0| ≥
d_arrastre` (counts only if `agarrar` or `rotar` accepted; with gamepad `rotar`
starts when the horizontal stick leaves the deadzone). `rotar` with mouse
replays the pixels accumulated before the threshold in its first update.
Outputs: `PRESSED` (highlight), then exactly one of `seleccionar` on release,
or `GESTURE_START/UPDATE/END` for `agarrar|rotar|mantener`, or `CANCELLED` on
context change / focus loss / `atrás` in toggle mode. Toggle mode (rule 14)
replaces "release" with "next press"; `leer`/`mantener` complete only if the
second press is ≥ `t_hold` after the first. `interactuar` uses the same
recogniser restricted to {`leer`}, with 7's `set_target_long_verb(bool)`
deciding fire-on-press vs decide-on-release (rule 10, TR-input-013). Time is
`RealClock` (F6: "el tiempo es real").

**D11 — Rebinding API and conflict validator (closes QQ-16).** Bindings are
`InputBinding` values (`kind`, `code`, optional `axis_dir`), never raw
`InputEvent`s past the adapter. 25/30 capture an event, call
`binding_from_event(ev)` (null = not capturable: mouse motion, `ui_*`-only
inputs on pad stick for non-sets, unknown), then `rebind(...)`. The validator
checks, in this order: rebindable action → set completeness (`mover`/`mirar`
take 4 directions or one stick) → duplicate in the same action → minimum
guarantees (`interactuar`, `atrás`, `pausa` keep ≥ 1 per device; `atrás`
keyboard+mouse keeps ≥ 1 binding that is not *text-field-consumed*) → `pausa`
against `ui_fixed` (not swappable) → same-context conflict with the
allowed-pairs list (`pausa`/`ui_atrás` on `Esc`). A swappable conflict returns
`CONFLICT_SWAPPABLE` and changes nothing until `confirm_swap(result)`. Slot
order is the order of addition; replacing keeps the slot; `get_binding_label`
reads slot 0.

**D12 — `es_imprimible` and text-field precedence (TR-input-017,
TR-computer-003/-004).** `es_imprimible(ev)` is true for a keyboard key that
produces a character: decided by a **deny-list** of non-printable key names in
data (`Esc`, `Tab`, `Enter`, `Backspace`, `Delete`, `Insert`, arrows,
`Home`/`End`/`PageUp`/`PageDown`, `F1`–`F12`, modifiers, `CapsLock`, …); any
other key is printable (conservative: an unknown key is treated as one that
writes). Mouse and pad inputs are never printable. The rule-17 minimum uses
the stricter `is_text_field_consumed(b)` = printable ∪ {`Backspace`, `Delete`,
arrows, `Enter`}, because those are exactly what the field eats (rule 20); a
`atrás` bound only to `Backspace` would never close the computer
(TR-computer-003). Precedence is explicit, not by GUI order: 19 calls
`set_text_entry(owner, active)` when its search field gains/loses focus; while
active (and only in `ORDENADOR`) the router does not map text-field-consumed
keys to any action and leaves the event untouched for the `LineEdit`. `pausa`
(`Esc`), right click and pad east keep working. The gamepad on-screen keyboard
(TR-computer-011) is driven by 19 with the existing cursor and `seleccionar`;
on device switch pad→keyboard 19 hides it and keeps text and focus
(TR-computer-012) on `input_device_changed`.

**D13 — `get_binding_label(accion, dispositivo)` and pad family.** Pure,
deterministic query: resolves derived actions to their base (`leer` →
`interactuar`; `repasar_bolsillo` → `atrás`; `agarrar`/`rotar`/`mantener` →
`seleccionar`); `dispositivo` `-1` = active device; returns `{tipo, texto,
glifo_id}` or `{}` (= *nulo*, logged) for an unknown action/device; reads slot
0. `texto` for keys comes from a data table `key_labels` (Spanish names:
`E`, `Esc`, `Clic izq.`, `Clic der.`, …), never from `as_text()` (NOT
SOURCEABLE and not localised). Pad `texto`/`glifo_id` depend on
`PadFamily ∈ {XBOX, PLAYSTATION, GENERIC}`: the adapter reports the joypad
name of `last_pad_id` and `PadFamilyClassifier` matches it against
substrings in data (`gamepad_families`); unknown → `GENERIC`, which uses Xbox
letters (`A`/`B`) with neutral glyph ids. `bindings_revision: int` increments
on any binding change, family change or device switch, so a cache (24) can
compare instead of needing a new notice (rebinding is also reachable from the
title's options, where `pause_closed` never fires).

**D14 — Pause triggers.** The router emits a direct signal
`pause_requested(cause: PauseCause)` (`ACTION`, `FOCUS_LOST`, `PAD_LOST`),
connected by `Shell` to 25, which pushes `menú` and pauses `GameClock`
(ADR-0002 O1/O2). Rules: never while `carga_en_curso` (focus/pad causes are
kept as *pending* and fired on `scene_load_finished`, dropped on
`scene_load_failed`/`restore_menu`); never with `in_game == false` (title:
`PAD_LOST` instead switches active device to keyboard+mouse,
TR-title-016; focus loss does nothing); `PAD_LOST` only if the active device is
the gamepad and the lost pad is `last_pad_id`. Focus loss always cancels held
actions and gestures first. With `menú` already on top the signal is still
emitted for `PAD_LOST` (25 shows its header line, TR-pause-021) and not for
`FOCUS_LOST`. Mouse mode per context comes from data: captured in
`exploración`/`inspección`/`lectura`, visible in cursor contexts and `menú`,
hidden in `llamada` until 22 shows it and in `sin control`.

### Architecture Diagram

```text
 OS events
    │
    ▼
 EngineInputAdapter (Node, ALWAYS)  ← ONLY file with NOT SOURCEABLE engine calls
    │  RawInput{kind, code, device, pressed, value, motion}
    │  joy connected/disconnected · joy name · window focus · set_mouse_mode()
    ▼
 InputRouter (autoload #4, ALWAYS) ─────────────────────────────────────────────┐
    │ text-entry gate (D12) ─► leaves field keys to LineEdit                     │
    │ DeviceTracker F7 (RealClock) ─► notice input_device_changed               │
    │ BindingTable (json + `controles`) ─► logical action                       │
    │ ContextStack [StackEntry…] + BlockingGate (caps on GameClock)              │
    │     └─► notices input_context_changed / no_control_absorbed (bus, 0001)    │
    │ latch-until-release · one-event-one-action (precedence per context)       │
    ├─► sinks (ctx, action) ─► 7 Interaction · 20 Pocket · 22 Call · 25 Pause    │
    ├─► poll ─► 2 Player: get_move_vector() / consume_look_delta() (F1–F3)       │
    ├─► PointerCursor F5a/F5b ◄── PointerTargetProvider (7, 19, 22, 25)          │
    │      └─► GestureRecognizer F4/F6 ─► sink of top context                   │
    ├─► pause_requested(cause) ─► Shell ─► 25 (push menú, GameClock.pause)       │
    └─► get_binding_label / rebind / export / import ◄── 24, 25, 30, 6           │
 InputContextsPort (RefCounted) ◄── 4 SceneLoader, 21 SceneDirector ─────────────┘
 Native GUI focus navigation (Input Map ui_* only, fixed) ── menú/llamada/ordenador
```

### Key Interfaces

Signatures close the ‡ of `architecture.md` § API Boundaries/Entrada and
supersede its Spanish method names (identifiers in English per `CLAUDE.md`;
the GDD literals `get_binding_label` and `es_imprimible` are kept). Comments use
a single `#` so `Grep ^#` section lookups do not match code; real sources use
`##` doc comments.

```gdscript
# src/input/input_types.gd
class_name InputTypes extends RefCounted
enum Context { EXPLORACION, INSPECCION, LECTURA, VISTA_CERCANA, ORDENADOR, LLAMADA, MENU, SIN_CONTROL }
enum Device { KEYBOARD_MOUSE = 0, GAMEPAD = 1, ACTIVE = -1 }       # not engine device ids
enum RawKind { KEY, MOUSE_BUTTON, MOUSE_MOTION, PAD_BUTTON, PAD_AXIS }
enum Phase { PRESSED, RELEASED, TAP, LONG, GESTURE_START, GESTURE_UPDATE, GESTURE_END, CANCELLED }
enum PauseCause { ACTION, FOCUS_LOST, PAD_LOST }
enum PadFamily { XBOX, PLAYSTATION, GENERIC }
enum RebindStatus { ASSIGNED, CONFLICT_SWAPPABLE, CONFLICT_NOT_SWAPPABLE, MINIMUM_VIOLATION,
		BACK_ONLY_PRINTABLE, SET_INCOMPLETE, DUPLICATE, NOT_REBINDABLE, INVALID_INPUT }
const OWNER_SCENE_LOADER: StringName = &"scene_loader"
const OWNER_SCENE_DIRECTOR: StringName = &"scene_director"
const OWNER_INPUT_ROUTER: StringName = &"input_router"

class RawInput extends RefCounted:
	var kind: RawKind
	var code: int              # keycode, mouse button index, JOY_BUTTON_*, or axis index
	var device: int            # joypad id for PAD_*; unused for keyboard/mouse (never compared with 0)
	var pressed: bool
	var value: float           # PAD_AXIS raw value
	var motion: Vector2        # MOUSE_MOTION relative pixels (S-0006-D)
	var position: Vector2      # mouse position, logical px (ViewportMapper)

class InputBinding extends RefCounted:
	var kind: RawKind
	var code: int
	var axis_dir: int = 0      # −1/+1 for an axis half; 0 otherwise
	func equals(o: InputBinding) -> bool:
		return kind == o.kind and code == o.code and axis_dir == o.axis_dir

class ActionEvent extends RefCounted:
	var action: StringName
	var phase: Phase
	var position: Vector2      # cursor contexts (logical px)
	var delta: Vector2         # agarrar: Δp px; rotar: (Δφ degrees, 0)
	var target_id: StringName  # PointerTarget.id at press, &"" if none

class RebindResult extends RefCounted:
	var status: RebindStatus
	var action: StringName
	var device: Device
	var slot: int
	var binding: InputBinding
	var conflict_action: StringName = &""
	var conflict_slot: int = -1
```

```gdscript
# src/input/input_router.gd — autoload #4, registered as InputRouterAutoload (ADR-0009)
class_name InputRouter extends Node
signal pause_requested(cause: InputTypes.PauseCause)   # direct signal to Shell → 25 (D14)

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS              # ADR-0002 / ADR-0009 D2

# Lifecycle
func setup(ctx: ServiceContext) -> void                  # boot step 5: load json, subscribe
func feed(raw: InputTypes.RawInput) -> void              # called only by EngineInputAdapter / tests
func contexts_port() -> InputContexts                    # handed to 4 and 21 by Boot

# Context stack (generic; rejects SIN_CONTROL)
func enter(ctx: InputTypes.Context, requester: StringName) -> bool
func exit(ctx: InputTypes.Context, requester: StringName) -> bool
func top() -> InputTypes.Context
func is_loading() -> bool                                # carga_en_curso
func begin_blocking(owner: StringName, max_s: float = -1.0) -> void
func end_blocking(owner: StringName) -> void

# `sin control` (D4) — also exposed through InputContextsPort
func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool
func close_no_control(owner: StringName) -> bool
func transfer_no_control(new_owner: StringName, declared_s: float) -> bool
func request_exploration(owner: StringName) -> bool
func restore_menu() -> void
func reset_stack_on_unload() -> void
## margen_E of the sin-control cap, read by 21 for GDD 21 F5 (ADR-0017 A3) ‡
func no_control_margin_s() -> float

# Delivery (D6, D9, D10)
func bind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable) -> void
func unbind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable) -> void
func get_move_vector() -> Vector2                        # unit-clamped; zero outside EXPLORACION
func consume_look_delta() -> Vector2                     # degrees (yaw, pitch); F2 + F3
func get_rotate_object_delta() -> Vector2                # INSPECCION
func set_pointer_provider(ctx: InputTypes.Context, provider: PointerTargetProvider) -> void
func set_cursor_visible(requester: StringName, visible: bool) -> void
func get_cursor_position() -> Vector2                    # logical px
func set_target_long_verb(has_long_verb: bool) -> void   # 7, for the aimed object (rule 10)
func set_text_entry(owner: StringName, active: bool) -> void   # 19 (D12)
func active_device() -> InputTypes.Device
func pad_family() -> InputTypes.PadFamily

# Labels (D13) — GDD literal name
func get_binding_label(accion: StringName, dispositivo: int = -1) -> Dictionary  # {tipo, texto, glifo_id} | {}
func bindings_revision() -> int

# Rebinding (D11) — closes QQ-16
func binding_from_event(ev: InputEvent) -> InputTypes.InputBinding   # null = not capturable; delegates to adapter
func rebind(accion: StringName, dispositivo: InputTypes.Device, slot: int, b: InputTypes.InputBinding) -> InputTypes.RebindResult
func rebind_set(accion: StringName, dispositivo: InputTypes.Device, slot: int, parts: Array[InputTypes.InputBinding]) -> InputTypes.RebindResult
func confirm_swap(pending: InputTypes.RebindResult) -> InputTypes.RebindResult
func remove_binding(accion: StringName, dispositivo: InputTypes.Device, slot: int) -> InputTypes.RebindResult
func reset_action(accion: StringName, dispositivo: InputTypes.Device) -> void
func reset_device(dispositivo: InputTypes.Device) -> void
func get_bindings(accion: StringName, dispositivo: InputTypes.Device) -> Array[InputTypes.InputBinding]
func es_imprimible(ev: InputEvent) -> bool                # GDD literal (TR-pause-017)
func is_text_field_consumed(b: InputTypes.InputBinding) -> bool

# Handling settings (TR-pause-017) and persistence block (TR-input-016)
func get_handling_settings() -> Array[Dictionary]         # [{id, tipo, rango: Vector2, paso, valor, rotulo}]
func set_handling_setting(id: StringName, value: Variant) -> bool
func export_bindings() -> Dictionary                      # opaque `controles` block for Settings (6)
func import_bindings(block: Dictionary) -> void           # tolerant; logs every discard
```

```gdscript
# src/input/input_contexts_port.gd — the ADR-0003 `InputContexts` contract, as a port
# (ADR-0003 names the class InputContexts; this ADR keeps that name as the port type)
class_name InputContexts extends RefCounted
var _router: InputRouter
func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
	return _router.open_no_control(owner, declared_s, absorbs_foreign)
func close_no_control(owner: StringName) -> bool:
	return _router.close_no_control(owner)
func transfer_no_control(new_owner: StringName, declared_s: float) -> bool:
	return _router.transfer_no_control(new_owner, declared_s)
func request_exploration(owner: StringName) -> bool:
	return _router.request_exploration(owner)
func restore_menu() -> void:
	_router.restore_menu()
func reset_stack_on_unload() -> void:
	_router.reset_stack_on_unload()
```

(`contexts_port()` returns an `InputContexts`; the name `InputContextsPort`
in the diagram and the method list is the same type.)

```gdscript
# src/input/pointer_target_provider.gd — implemented by 7 (ADR-0011), 19, 22, 25
class_name PointerTargetProvider extends RefCounted
func targets() -> Array[Dictionary]: return []   # [{id, center_px, tolerance_px, gestos_aceptados, focus_order}]
func on_hover(_target_id: StringName) -> void: pass   # GUI providers call grab_focus() here
func zone_rect() -> Rect2: return Rect2()   # default: ViewportMapper.logical_rect() (ADR-0016 OI-3)
## Target under p_px; default = nearest centre within tolerance_px, &"" if none.
## GestureRecognizer calls it at press so ActionEvent.target_id equals 7's pick (ADR-0011 A-1).
func target_at(p_px: Vector2) -> StringName: return &""

# src/input/engine_input_adapter.gd — the only NOT SOURCEABLE surface (signatures ours)
class_name EngineInputAdapter extends Node
signal raw(input: InputTypes.RawInput)
signal pad_connection_changed(pad_id: int, connected: bool)   # S-0006-C
signal window_focus_changed(focused: bool)                     # S-0006-E
func pad_name(pad_id: int) -> String                           # S-0006-B
func set_mouse_mode(mode: StringName) -> void                  # &"captured" | &"visible" | &"hidden"; S-0006-D
func to_binding(ev: InputEvent) -> InputTypes.InputBinding     # S-0006-D
func is_printable_key(code: int) -> bool                       # deny-list in data (D12)
```

**Notice payloads (amend ADR-0001 registry, OI-2).**
`input_device_changed {dispositivo: &"teclado_raton" | &"mando"}`;
`input_context_changed {anterior: SN, contexto: SN}` with the context
`StringName`s `&"exploracion"`, `&"inspeccion"`, `&"lectura"`,
`&"vista_cercana"`, `&"ordenador"`, `&"llamada"`, `&"menu"`, `&"sin_control"`;
`no_control_absorbed {dueno: SN}` with an owner constant above (e.g.
`&"scene_director"`, not `&"21"`).

**Data file shape** (`assets/data/input/default_bindings.json`, validated by
`DataValidator` in debug/CI; ADR-0005 owns the schema format):

```text
{ "version": 1,
  "actions":   { "<accion>": { "rebindable": bool, "set": bool, "contexts": [..],
                               "kbm": [binding, binding?], "pad": [binding, binding?] } },
  "derived":   { "leer": "interactuar", "repasar_bolsillo": "atrás", "agarrar": "seleccionar", ... },
  "contexts":  { "<ctx>": { "actions": [..], "precedence": [..], "mouse": "captured|visible|hidden" } },
  "ui_fixed":  { "kbm": [..], "pad": [..] },          "allowed_pairs": [["pausa","ui_atrás"]],
  "minimums":  ["interactuar","atrás","pausa"],        "non_printable_keys": [..],
  "key_labels": { "<binding>": {"texto": "...", "glifo_id": "..."} },
  "gamepad_families": { "playstation": ["PlayStation","DualSense","DualShock","PS4","PS5"],
                        "xbox": ["Xbox","XInput"] },
  "pad_labels": { "xbox": {..}, "playstation": {..}, "generic": {..} },
  "tuning":    { "dz_in": 0.15, "dz_out": 0.05, "k_m": 0.10, ... (GDD 1 § Valores por defecto) } }
```

### Core pseudocode

Typed GDScript, abridged (logging helpers, dev assertions and JSON parsing
omitted).

```gdscript
# ─── InputRouter: stack ─────────────────────────────────────────────────────
class StackEntry extends RefCounted:
	var context: InputTypes.Context
	var requester: StringName
	var cursor_pos: Vector2
	var owner: StringName = &""
	var declared_s: float = 0.0
	var cap_deadline: float = INF      # GameClock time

var _stack: Array[StackEntry] = []
var _loading: bool = false
var _in_game: bool = false
var _pending_pause: int = -1           # PauseCause or −1
var _clock: GameClock
var _real: RealClock
var _bus: GameState                    # notices (ADR-0001)
var _t: Dictionary                     # tuning from json

func _top() -> StackEntry:
	return _stack.back() if not _stack.is_empty() else null

func _no_control_index_foreign(owner: StringName) -> int:
	for i: int in _stack.size():
		var e: StackEntry = _stack[i]
		if e.context == InputTypes.Context.SIN_CONTROL and e.owner != owner:
			return i
	return -1

func open_no_control(owner: StringName, declared_s: float, absorbs_foreign: bool = false) -> bool:
	if owner == InputTypes.OWNER_SCENE_LOADER:
		_loading = true                                   # robust to a queued «iniciada» (D4)
	var foreign: int = _no_control_index_foreign(owner)
	if foreign >= 0 and absorbs_foreign and owner == InputTypes.OWNER_SCENE_LOADER:
		return _discard_and_open(owner, declared_s)
	var top: StackEntry = _top()
	if top != null and top.context == InputTypes.Context.SIN_CONTROL:
		return _reject(&"open_on_no_control", owner)       # must transfer instead
	if foreign >= 0:
		return _reject(&"foreign_no_control_below", owner) # AC-E13
	if declared_s <= 0.0:
		declared_s = _t.no_duration_cap_s                  # 3 s, logged
		_log_missing_duration(owner)
	var e := StackEntry.new()
	e.context = InputTypes.Context.SIN_CONTROL
	e.requester = owner
	e.owner = owner
	e.declared_s = declared_s
	e.cap_deadline = _clock.deadline(declared_s + _t.no_control_margin_s)
	_push(e)
	return true

func _discard_and_open(owner: StringName, declared_s: float) -> bool:
	var prev: InputTypes.Context = _top().context
	var dropped: Array[StringName] = []
	for old: StackEntry in _stack:
		if old.context == InputTypes.Context.SIN_CONTROL and old.owner != owner and not dropped.has(old.owner):
			dropped.append(old.owner)
	var e := StackEntry.new()
	e.context = InputTypes.Context.SIN_CONTROL
	e.requester = owner
	e.owner = owner
	e.declared_s = declared_s
	e.cap_deadline = _clock.deadline(declared_s + _t.no_control_margin_s)
	_stack = [e]
	_on_context_changed(prev, e, true)                     # forced: owner changed
	for d: StringName in dropped:
		_bus.notify(&"no_control_absorbed", {"dueno": d})
	return true

func transfer_no_control(new_owner: StringName, declared_s: float) -> bool:
	var top: StackEntry = _top()
	if top == null or top.context != InputTypes.Context.SIN_CONTROL:
		return _reject(&"transfer_without_no_control", new_owner)
	top.owner = new_owner
	top.declared_s = declared_s if declared_s > 0.0 else _t.no_duration_cap_s
	top.cap_deadline = _clock.deadline(top.declared_s + _t.no_control_margin_s)
	return true                                            # no notice, no hook (GDD rule 6)

func request_exploration(owner: StringName) -> bool:
	var top: StackEntry = _top()
	if top == null or top.context != InputTypes.Context.SIN_CONTROL or top.owner != owner:
		return _reject(&"exploration_not_owner", owner)
	var base := StackEntry.new()
	base.context = InputTypes.Context.EXPLORACION
	base.requester = owner
	_stack = [base]                                        # discards any menú below (title)
	_in_game = true
	_on_context_changed(top.context, base, false)
	return true

func close_no_control(owner: StringName) -> bool:
	var top: StackEntry = _top()
	if top == null or top.context != InputTypes.Context.SIN_CONTROL or top.owner != owner:
		return _reject(&"close_not_owner", owner)
	_pop_top()                                             # empty → [EXPLORACION]; [MENU] below → logged
	return true

func restore_menu() -> void:
	var prev: StackEntry = _top()
	var m := StackEntry.new()
	m.context = InputTypes.Context.MENU
	m.requester = &"title"
	_stack = [m]
	_in_game = false
	_loading = false
	_pending_pause = -1
	if prev == null or prev.context != InputTypes.Context.MENU:
		_on_context_changed(prev.context if prev else InputTypes.Context.MENU, m, false)

func reset_stack_on_unload() -> void:
	var current: StackEntry = null
	for i: int in range(_stack.size() - 1, -1, -1):
		if _stack[i].context == InputTypes.Context.SIN_CONTROL:
			current = _stack[i]
			break
	var prev: StackEntry = _top()
	if current == null:
		_log_error(&"unload_without_no_control")
		current = StackEntry.new()
		current.context = InputTypes.Context.SIN_CONTROL
		current.owner = InputTypes.OWNER_INPUT_ROUTER
		current.declared_s = _t.no_duration_cap_s
		current.cap_deadline = _clock.deadline(current.declared_s)
	_stack = [current]                                     # owner, duration and cap kept
	if prev == null or prev.context != InputTypes.Context.SIN_CONTROL:
		_on_context_changed(prev.context if prev else InputTypes.Context.EXPLORACION, current, false)

func _on_context_changed(prev: InputTypes.Context, next: StackEntry, forced: bool) -> void:
	if prev == next.context and not forced:
		return
	_gestures.cancel()
	_hold.cancel()
	_latch.latch_all_pressed(_pressed, _continuous_axes)   # ignored until released (D3)
	_cursor.restore(next.cursor_pos)
	_adapter.set_mouse_mode(_mouse_mode_for(next.context))
	_bus.notify(&"input_context_changed", {"anterior": _ctx_name(prev), "contexto": _ctx_name(next.context)})

# ─── caps and pause gating (D5, D14) ────────────────────────────────────────
func _process(_delta: float) -> void:                      # engine delta ignored: clocks only
	var now_game: float = _clock.now()
	var top: StackEntry = _top()
	if top != null and top.context == InputTypes.Context.SIN_CONTROL and now_game >= top.cap_deadline:
		_log_error(&"no_control_cap_expired", top.owner)
		_pop_top()
	if _blocking.active and now_game >= _blocking.deadline:
		_log_error(&"blocking_cap_expired", _blocking.owner)
		_blocking.clear()
	var dt: float = minf(_real_dt(), _t.delta_max_s)       # 0,1 s (F3, F5b)
	_devices.tick(_real.now_ms())
	_cursor.tick(dt, _sticks, _provider_for(top))
	_gestures.tick(_real.now_ms(), _cursor.position(), _sticks)

func _request_pause(cause: InputTypes.PauseCause) -> void:
	if not _in_game:
		return                                              # title (TR-title-016)
	if _loading:
		if cause != InputTypes.PauseCause.ACTION:
			_pending_pause = cause                          # fired at «terminada» (rule 21–22)
		return                                              # `pausa` during a load is dropped (rule 7)
	if _top().context == InputTypes.Context.MENU and cause == InputTypes.PauseCause.FOCUS_LOST:
		return
	pause_requested.emit(cause)

func _on_scene_load_finished(_p: Dictionary) -> void:
	_loading = false
	if _pending_pause >= 0:
		var c: int = _pending_pause
		_pending_pause = -1
		_request_pause(c)

func _on_scene_load_failed(_p: Dictionary) -> void:
	_loading = false
	_pending_pause = -1                                     # AC-E14

func _on_pad_connection_changed(pad_id: int, connected: bool) -> void:
	if connected or pad_id != _devices.last_pad_id:
		return
	if _devices.active == InputTypes.Device.GAMEPAD:
		_cancel_holds()
		if _in_game:
			_request_pause(InputTypes.PauseCause.PAD_LOST)
		else:
			_devices.force(InputTypes.Device.KEYBOARD_MOUSE)   # title: switch, keep focus

# ─── feed: one event, at most one action (D6) ───────────────────────────────
func feed(raw: InputTypes.RawInput) -> void:
	_devices.observe(raw, _real.now_ms())                  # F7; may emit input_device_changed
	if raw.kind == InputTypes.RawKind.PAD_AXIS:
		_sticks.set_axis(raw.device, raw.code, raw.value)
		return
	if raw.kind == InputTypes.RawKind.MOUSE_MOTION:
		_mouse_accum += raw.motion
		_cursor.mouse_moved(raw.position)
		return
	var b := InputTypes.InputBinding.new()
	b.kind = raw.kind
	b.code = raw.code
	if raw.pressed:
		if _pressed.has(_key(b)):
			return                                          # echo: own pressed set (D2)
		_pressed[_key(b)] = true
	else:
		_pressed.erase(_key(b))
		if _latch.release(b):
			return                                          # was latched: swallow release too
	if _latch.is_latched(b):
		return
	if _text_entry_active and _top().context == InputTypes.Context.ORDENADOR \
			and raw.kind == InputTypes.RawKind.KEY and _is_field_key(raw.code):
		return                                              # left to the LineEdit (D12)
	var top: StackEntry = _top()
	var action: StringName = _bindings.resolve(b, _ctx_precedence(top.context))   # first match only
	if action == &"":
		return
	if _blocking.active and action != &"pausa" and not _is_pocket_review(action, top, raw):
		return                                              # dropped, never queued (rule 8)
	if action == &"pausa" and top.context != InputTypes.Context.MENU:
		if raw.pressed:
			_request_pause(InputTypes.PauseCause.ACTION)
		return
	_dispatch(top, action, raw)                             # derives leer / repasar_bolsillo / gestures
```

```gdscript
# ─── pure math (src/input/input_math.gd), F1–F5 ─────────────────────────────
static func deadzone(v: Vector2, dz_in: float, dz_out: float) -> float:          # F1
	return clampf((v.length() - dz_in) / (1.0 - dz_out - dz_in), 0.0, 1.0)

static func look_mouse(px: Vector2, k_m: float, s_m: float, inv: int, cap_deg: float) -> Vector2:  # F2
	var d: Vector2 = Vector2(px.x, px.y * inv) * k_m * s_m
	return d.clamp(Vector2(-cap_deg, -cap_deg), Vector2(cap_deg, cap_deg))

static func look_stick(v: Vector2, r: float, w_max: float, p: float, s_s: float, dt: float) -> Vector2:  # F3
	if r <= 0.0:
		return Vector2.ZERO
	return v.normalized() * (w_max * pow(r, p) * s_s) * minf(dt, 0.1)

static func cursor_speed(r: float, v_max: float, s_c: float) -> float:          # F5a
	return v_max * r * r * s_c

static func magnet_step(p: Vector2, t: Vector2, d: float, r_cap: float, lam: float, v_c: float,
		v_on: float, v_off: float, dt: float) -> Vector2:                     # F5b
	if d < 3.0 or v_c >= v_off:
		return Vector2.ZERO
	var w: float = clampf(1.0 - d / r_cap, 0.0, 1.0) * clampf((v_off - v_c) / (v_off - v_on), 0.0, 1.0)
	var step: Vector2 = (t - p) * (1.0 - exp(-lam * dt)) * w
	return step.limit_length(0.5 * v_c * dt)

static func rotate_pad(x: float, r_x: float, w_r_max: float, near_mark: bool, f_marca: float, dt: float) -> float:  # F4
	return signf(x) * w_r_max * r_x * r_x * (f_marca if near_mark else 1.0) * dt
```

`InputMath.deadzone` with `v = (0,5; 0,4)` returns 0,613 (GDD F1 example);
these GDD examples are the unit-test fixtures (§ Test Plan).

### Implementation Guidelines

- `EngineInputAdapter` **must** be the only file in `src/` that reads
  `InputEvent` subclasses' fields, calls `Input.*`, reads joypad names, sets
  the mouse mode or listens for window focus (CI grep: `Input\.` and
  `InputEvent` outside `src/input/engine_input_adapter.gd` fail, except
  `binding_from_event`/`es_imprimible` signatures that only forward).
- Code **must never** compare `InputEvent.device` with `0`; device class
  **must** come from the event type (4.7, `deprecated-apis.md`).
- Gameplay code **must never** call `Input.is_action_*`, `Input.get_vector`
  or `InputMap.*`; actions come from sinks and polling of `InputRouter` only.
  The engine Input Map **must never** be modified at runtime.
- Every action name, binding, threshold and label **must** come from
  `default_bindings.json`; no key or button literal outside the adapter and
  the JSON.
- `InputRouter` **must** use `GameClock` for the `sin control` and blocking
  caps and `RealClock` for hysteresis, gestures, `t_hold`, cursor and
  magnetism; it **must never** read `_process(delta)` for either.
- Exactly one sink per (context, action); a system **must** bind its sinks in
  `configurar(ctx)` (scene systems) or `setup(ctx)` (Shell/autoloads) and
  **must** tolerate being freed without unbinding (the router checks
  `Callable.is_valid()` before calling and drops invalid sinks with a log).
- Only 4 (`&"scene_loader"`) and 21 (`&"scene_director"`) **may** call the
  `sin control` operations, and only through the `InputContexts` port; 7
  **must never** open `sin control` (it uses `begin_blocking`).
- `SceneLoader.request_load` **must** pass `absorbs_foreign = true` iff the
  reason is `partida_nueva` or `reanudar` (OI-1 amends ADR-0003's call).
- The router **must** emit at most one action per raw event and **must** run
  the change hook (cancel, latch, cursor restore, mouse mode, notice) on every
  effective stack change — and only on effective ones.
- `get_binding_label` **must** be side-effect free; tests call it twice and
  compare.
- UI screens **must** use `grab_focus()` for gamepad/keyboard focus and
  **must** be tested with both input paths (dual focus, `modules/ui.md`).

### Rebinding validator (reference pseudocode)

```gdscript
# src/input/binding_validator.gd — pure; table and data injected
func validate(t: BindingTable, accion: StringName, dev: InputTypes.Device, slot: int,
		b: InputTypes.InputBinding) -> InputTypes.RebindResult:
	var r := _result(accion, dev, slot, b)
	if not _data.is_rebindable(accion):
		return _with(r, InputTypes.RebindStatus.NOT_REBINDABLE)        # ui_*, mover_cursor, mouse motion
	if b == null:
		return _with(r, InputTypes.RebindStatus.INVALID_INPUT)
	for i: int in t.get_slots(accion, dev).size():
		if i != slot and t.get_slots(accion, dev)[i].equals(b):
			return _with(r, InputTypes.RebindStatus.DUPLICATE)
	var after: Array[InputTypes.InputBinding] = t.slots_after_replace(accion, dev, slot, b)
	if accion == &"atrás" and dev == InputTypes.Device.KEYBOARD_MOUSE \
			and after.all(func(x: InputTypes.InputBinding) -> bool: return is_text_field_consumed(x)):
		return _with(r, InputTypes.RebindStatus.BACK_ONLY_PRINTABLE)
	if accion == &"pausa" and _data.ui_fixed(dev).any(func(x: InputTypes.InputBinding) -> bool: return x.equals(b)):
		return _with(r, InputTypes.RebindStatus.CONFLICT_NOT_SWAPPABLE)
	for other: StringName in _data.actions_sharing_context(accion):    # pausa shares all contexts
		if _data.is_allowed_pair(accion, other):
			continue
		var j: int = t.find(other, dev, b)
		if j >= 0:
			r.conflict_action = other
			r.conflict_slot = j
			var swap_ok: bool = _minimums_hold_after_swap(t, accion, dev, slot, other, j)
			return _with(r, InputTypes.RebindStatus.CONFLICT_SWAPPABLE if swap_ok
					else InputTypes.RebindStatus.CONFLICT_NOT_SWAPPABLE)
	return _with(r, InputTypes.RebindStatus.ASSIGNED)               # caller commits; slot kept
```

`remove_binding` returns `MINIMUM_VIOLATION` when it would leave
`interactuar`, `atrás` or `pausa` with no binding on that device, and
`BACK_ONLY_PRINTABLE` when it would leave `atrás` (keyboard+mouse) with only
text-field-consumed keys. `rebind_set` returns `SET_INCOMPLETE` until all four
directions (or one stick) are given. `import_bindings` runs every entry
through the same validator in table order: unknown action or invalid input →
dropped + log; same-context conflict → first in table order wins, the other
reverts to default + log (GDD 1 Edge Cases).

## Alternatives Considered

### Alternative 1: Godot Input Map as the binding store (rebind with `InputMap` at runtime)
- **Description**: Declare every action in `project.godot`; read with
  `Input.is_action_just_pressed` / `Input.get_vector`; rebind with
  `InputMap.action_erase_events` / `action_add_event`; persist with event
  serialisation.
- **Pros**: Idiomatic; GUI and gameplay share one table; less code.
- **Cons**: The mutation and serialisation APIs are NOT SOURCEABLE for 4.7;
  the Input Map has no slot order, so `get_binding_label` determinism (rule
  24) and "replace keeps position" need a shadow table anyway; per-action
  engine deadzone is per axis, not the radial F1; one action cannot be active
  only in one context, so the stack would be reimplemented on top; unit tests
  need the engine.
- **Estimated Effort**: ~0,7× initially, ~1,2× once the shadow table and
  context filter are added.
- **Rejection Reason**: Fails determinism and testability; adds post-cutoff
  surface instead of removing it.

### Alternative 2: Each context is a `Node` with its own `_unhandled_input`
- **Description**: Push/pop context nodes; each reads events itself; the
  front-most handles them and marks them handled.
- **Pros**: Uses engine propagation; local reasoning per mode.
- **Cons**: Relies on `_input`/GUI/`_unhandled_input` order and
  `set_input_as_handled` (NOT SOURCEABLE); gestures, latch-until-release,
  hysteresis and caps would be duplicated per node; the `sin control` stack
  must survive scene unload, which per-scene nodes do not (ADR-0009 P test).
- **Estimated Effort**: ~1,0× code, ~1,5× tests.
- **Rejection Reason**: Spreads one concern across many nodes and depends on
  unsourced propagation order.

### Alternative 3: Virtual cursor by warping the OS mouse / synthetic mouse events
- **Description**: Move the real cursor (`Input.warp_mouse`) or inject
  `InputEventMouseButton` (`Input.parse_input_event`) so GUI and puzzles see a
  single pointer.
- **Pros**: Puzzles and GUI need one code path; hover "just works".
- **Cons**: Both APIs NOT SOURCEABLE; warping fights the player's real mouse
  when both devices are active (rule 2); synthetic events would re-enter the
  router and be counted as mouse use, flipping the active device (F7).
- **Estimated Effort**: ~0,8×.
- **Rejection Reason**: Breaks the hysteresis and the two-devices-at-once
  rule; replaced by `PointerTargetProvider` + `grab_focus()`.

### Alternative 4: Notice «asignaciones cambiadas» on the bus
- **Description**: Add a bus notice whenever bindings change (GDD OQ 19).
- **Pros**: Push instead of pull for 24 and 18.
- **Cons**: New registry entry in ADR-0001; fires in the title where nothing
  displays glyphs; 24 already re-queries on `input_device_changed` and
  `pause_closed`.
- **Estimated Effort**: ~equal.
- **Rejection Reason**: `bindings_revision()` covers the title-options path
  without widening the bus contract; reversible if 30 needs push.

## Consequences

### Positive
- One file holds every post-cutoff and unsourced input API; spikes failing
  change only the adapter.
- Stack, F1–F8, gestures, validator and labels are pure and run in gdUnit4
  without a window (≈ 90 % of system 1 logic under unit tests).
- `sin control` handoff of ADR-0003 has a concrete implementer with the exact
  rejection semantics of GDD 1 rule 6; discard no longer depends on drain
  order.
- Deterministic labels; rebinding cannot corrupt the engine Input Map.

### Negative
- Two binding sources exist: the router table (gameplay) and the Input Map
  (`ui_*`), kept consistent by a CI check, not by construction.
- The router reimplements what `Input.get_vector` gives for free (axis
  combination), ~150 lines more.
- `PointerTargetProvider` must be implemented by every cursor screen (7, 19,
  22, 25), including GUI ones.
- ADR-0003's call site and ADR-0001's payload must be amended.

### Neutral
- `architecture.md`'s Spanish method names (`entrar_en`, `sin_control_abrir`,
  `rebind`) are replaced by English ones; GDD literals kept.
- Pause opening stays 25's; Entrada only says *when*.

## Risks

- **R1 SDL3 gives no usable joypad name (S-0006-B fails).** Glyphs would show
  `GENERIC` (Xbox letters) for a PlayStation pad. Mitigation: fallback is
  readable text (`A`, `B`); a manual "estilo de botones" setting is a GDD 30
  decision to propose, not taken here.
- **R2 No connection signal under SDL3 or while paused (S-0006-C).**
  Mitigation: adapter polls the connected-pad list every 0,5 s of real time;
  rule 22 latency ≤ 0,5 s accepted.
- **R3 Event axis values already deadzoned (S-0006-A).** Mitigation: record the
  floor; clamp the `dz_in` safe range's lower bound to it in data.
- **R4 Clicking a `LineEdit` does not give it keyboard focus under dual focus
  (S-0006-F).** Mitigation: 19 calls `grab_focus()` on the field from its own
  click handler; `set_text_entry` is driven by 19, not by engine focus.
- **R5 Mouse relative motion scales with stretch mode (S-0006-D).** F2 assumes
  physical pixels. Mitigation: adapter divides by the stretch factor reported
  by `ViewportMapper` (ADR-0016).
- **R6 `_input` not delivered to `ALWAYS` autoload during pause (ADR-0002
  S4).** Blocking for the whole menu; ADR-0002 variant B fallback applies.
- **R7 Shared `Esc` double-fires through native GUI `ui_cancel`.** Mitigation:
  25 never binds `ui_cancel` itself; the router's one-event-one-action is the
  only close path (test I-4).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| entrada-y-controles.md (1) | TR-input-001 vocabulary, physical vs derived actions, layer over the Input Map | D1, D2, D6; derived table in data |
| entrada-y-controles.md (1) | TR-input-002 both devices, last-used, F7 hysteresis, one notice per change | D7, `DeviceTracker` |
| entrada-y-controles.md (1) | TR-input-003 stack, top only, ignore/reject rules, notice on effective change | D3, `enter`/`exit`, change hook |
| entrada-y-controles.md (1) | TR-input-004 `sin control` operations and absorbed notice | D4, `InputContexts` port, pseudocode |
| entrada-y-controles.md (1) | TR-input-005 caps 3 s / declared + 2 s, stop with pause | D4, D5 on `GameClock` |
| entrada-y-controles.md (1) | TR-input-006 `carga_en_curso`, deferred pause | D4 (set on open + notice), D14 |
| entrada-y-controles.md (1) | TR-input-007 blocking transitions, drop not queue, held key | D5, D3 latch, `repasar_bolsillo` exception |
| entrada-y-controles.md (1) | TR-input-008 menu consumes event, mouse release/recapture, focus/pad pause | D6 precedence, D14, mouse mode per context |
| entrada-y-controles.md (1) | TR-input-009 F2/F3 | `InputMath.look_mouse`, `look_stick`; `consume_look_delta()` |
| entrada-y-controles.md (1) | TR-input-010 F1 radial on raw axes | D8, `InputMath.deadzone` |
| entrada-y-controles.md (1) | TR-input-011 virtual cursor F5a/F5b, visibility by 22 | D9 |
| entrada-y-controles.md (1) | TR-input-012 gesture recogniser F4/F6 | D10 |
| entrada-y-controles.md (1) | TR-input-013 `interactuar` short/long verb, cancel | D10 (`set_target_long_verb`) |
| entrada-y-controles.md (1) | TR-input-014 `repasar_bolsillo` | D6 sink of 20, press edge, own echo filter, D5 exception |
| entrada-y-controles.md (1) | TR-input-015 rebinding, validator, minimums | D11, validator pseudocode |
| entrada-y-controles.md (1) | TR-input-016 data file, export/import tolerant | D1, `export_bindings`/`import_bindings` |
| entrada-y-controles.md (1) | TR-input-017 text field precedence | D12 |
| entrada-y-controles.md (1) | TR-input-018 `get_binding_label`, pad family | D13 (family behind S-0006-B) |
| entrada-y-controles.md (1) | TR-input-019 toggle-instead-of-hold, `t_hold` to 1,5 s | D10; range in `get_handling_settings()` |
| menu-de-pausa.md (25) | TR-pause-004 three causes, one menu | D14 `pause_requested(cause)` |
| menu-de-pausa.md (25) | TR-pause-008 one event one effect; closing click held | D6, D3 latch (opening guard 0,15 s stays 25's) |
| menu-de-pausa.md (25) | TR-pause-013 held repeat of `ui_izquierda/derecha` | Not here: native GUI + 25 (D6); Open Item OI-4 |
| menu-de-pausa.md (25) | TR-pause-016 capture per device, set in 4 steps | `binding_from_event`, `rebind_set`; timers stay 25's (`RealClock`) |
| menu-de-pausa.md (25) | TR-pause-017 rebind results, `es_imprimible`, settings list | D11 `RebindStatus`, D12, `get_handling_settings()` |
| menu-de-pausa.md (25) | TR-pause-021 pad-lost panel, also with menu open, deferred in load | D14 |
| ordenador-correo-impresora.md (19) | TR-computer-003 `atrás` always closes | D12 (`is_text_field_consumed` minimum; right click / east bypass) |
| ordenador-correo-impresora.md (19) | TR-computer-004 field consumes before actions | D12 `set_text_entry` gate |
| ordenador-correo-impresora.md (19) | TR-computer-011 on-screen keyboard with cursor + `seleccionar` | D9 provider + D10; no new actions |
| ordenador-correo-impresora.md (19) | TR-computer-012 device switch keeps text, hides keyboard | D7 notice consumed by 19 |
| pantalla-de-titulo (27) | TR-title-007 inputs ignored during fade/load | D4 `sin control` above `menú` + D3 latch |
| pantalla-de-titulo (27) | TR-title-008 full navigation, `ui_cancel` no-op, contexto `menú` | D1 native `ui_*`, D6; title `menú` is base (no sink closes it) |
| pantalla-de-titulo (27) | TR-title-016 pad lost on title, no pause on focus loss | D14 `in_game == false` branch |

**TRs covered by range:** TR-input-001 … TR-input-019 (all, with -005 shared
with ADR-0002 and -004 with ADR-0003); TR-pause-004, -008, -016, -017, -021
(TR-pause-013 deferred, OI-4); TR-computer-003, -004, -011, -012 (input side
only); TR-title-007, -008, -016.

## Performance Implications
- **CPU**: per raw event O(bindings of the top context) ≤ ~20 comparisons;
  per frame one cursor/magnet step over ≤ ~30 targets and one gesture tick.
  Budget ≤ 0,05 ms/frame; measured by test P-1.
- **Memory**: < 50 KB (table, stack ≤ 4 entries, label dictionaries).
- **Load Time**: one JSON parse at boot step 5 (< 1 ms for < 20 KB).
- **Network**: none.

## Migration Plan

No code exists. Order: `InputTypes`/`InputMath` + unit tests → `BindingTable`,
validator, labels → stack + `InputContexts` port (unblocks ADR-0003 stories) →
`DeviceTracker`, cursor, gestures → `EngineInputAdapter` after spikes. Update
`architecture.md` § API Boundaries/Entrada to these signatures at
`/architecture-review` (OI-3).

**Rollback plan**: if the own-table approach proves too costly, the
`BindingTable` interface can be re-backed by the Input Map (Alternative 1)
without touching consumers, since nothing outside the router sees bindings.

## Validation Criteria

### Spikes (must run on Godot 4.7.2 before `Accepted`)

| Spike | Question | Method | Pass |
|---|---|---|---|
| S-0006-A | Raw joypad events: `InputEventJoypadMotion` axis index/value range, no engine deadzone on the value, button indices for south/east/start, OS-repeat behaviour of keys | Probe scene logging events for one Xbox-layout and one PlayStation pad, and holding a key | Values in [−1, 1], resting value ≤ 0,05 (else record floor), `JOY_BUTTON_A` = south on both pads, repeated key presses observed and filtered by the pressed set |
| S-0006-B | Pad family: which API returns a name/GUID under SDL3, and the strings for DualSense/DualShock 4/Xbox | Same probe, print name + GUID | Strings match `gamepad_families` substrings, or the list is updated from the observed strings |
| S-0006-C | Connect/disconnect: signal name and arguments, delivery while `SceneTree.paused`, connected-pad list | Unplug/replug with and without pause | Disconnect observed ≤ 0,5 s in both states; else polling fallback (R2) |
| S-0006-D | Mouse: relative motion units with captured mode at 1080p and 1440p windows; `mouse_mode` set/restore after focus loss; numeric `DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD`; key code constants and their `key_labels` | Probe at two window sizes | Relative px independent of stretch (or factor recorded, R5); no event of type key/mouse reports a joypad id |
| S-0006-E | Window focus-out notification reaches an `ALWAYS` autoload, also paused | Alt-Tab with and without pause | Received once per loss |
| S-0006-F | `LineEdit`: keys not consumed by the router reach it; mouse click gives keyboard focus under dual focus; `focus_entered/exited`; project Input Map `ui_*` with left stick + D-pad navigates focus; `ui_fixed` matches `project.godot` | UI probe + CI script | All observed; CI check passes |

### Test Plan

Unit (`tests/unit/input/`, gdUnit4, `FakeRealClock`, `GameClock.advance()`,
recording bus, `FakeEngineInput`):

- **U-1 F1–F5**: GDD examples as fixtures (F1 0,613; F2 (18,−6) → (1,8°,
  −0,6°) and ±45° cap; F3 57,6 °/s at 30 and 60 fps; F5a 338 px/s; F5b
  0,833 px/frame cap and 88 px tolerance case; F4 ±60 °/s and brake).
- **U-2 F6 precedence**: all five GDD F6 examples; toggle mode second press
  before/after `t_hold`.
- **U-3 F7**: 4 px tremor no switch; 20 px switch; drift 0,2 no; 0,35 for
  0,1 s yes; `t_lock`; one notice per switch.
- **U-4 stack**: ignore same top; reject non-top exit; empty → exploración;
  one notice per effective change and none on rejection.
- **U-5 `sin control`**: every row of GDD 1 rule 6 table, including the three
  «Nueva partida» rows (discard + forced notice + `no_control_absorbed`),
  AC-E13 rejection, transfer renews cap without notice, reset keeps cap count,
  missing duration → 3 s + log, cap expiry pops and logs, cap frozen while
  `GameClock` paused.
- **U-6 latch**: held `interactuar` across `vista cercana` entry; held key
  across transition; `mover` not latched.
- **U-7 pause gating**: during load `pausa` dropped, focus/pad pending → fired
  at finished, dropped at failed; title branch; `Esc` in `menú` → one close.
- **U-8 validator**: every `RebindStatus`; allowed pair; `pausa` vs `ui_fixed`;
  `atrás` only `Backspace` rejected; slot order kept on replace.
- **U-9 import**: unknown action, invalid entry, same-context conflict.
- **U-10 labels**: derived → base; slot 0; `{}` for unknown; pure (two calls
  equal, revision unchanged); family XBOX/PLAYSTATION/GENERIC.
- **U-11 `es_imprimible` / text gate**: letters printable, deny-list not;
  field keys not mapped while `set_text_entry` active; `Esc`, right click
  still `pausa`/`atrás`.
- **U-12 `repasar_bolsillo`**: press edge only, echo ignored, not after a
  closing `atrás`, delivered during blocking transition.

Integration (`tests/integration/input/`): **I-1** ADR-0003 load sequence with
real `SceneLoader` + router: title → planta (`exploracion`), title → planta
(`ninguno`, transfer to 21), planta → recepción, failure → `[menú]`. **I-2**
pause during `vista cercana` restores cursor and context. **I-3** 21 never
transfers → cap frees with log. **I-4** shared `Esc` with 25's real menu: one
close, no world click on release.

Performance: **P-1** 1 000 synthetic events + 600 frames with 30 targets,
mean router cost ≤ 0,05 ms/frame.

Run-and-observe (`production/qa/evidence/`): pad glyph screenshots per family
in prompt (24) and pause rebinding screen (25) once S-0006-B passes.

### We will know this was right if
- No story outside system 1 needs to name a key, button or Input Map action.
- ADR-0003's I-1 sequence passes with zero uncontrolled frames.
- A failing spike changes only `engine_input_adapter.gd` and data.

## Open Items

| ID | Item | Owner | Closes when |
|---|---|---|---|
| OI-1 | **Resolved 2026-11-10 (applied in ADR-0003).** Amend ADR-0003: `open_no_control(&"scene_loader", _d_load, reason in [PARTIDA_NUEVA, REANUDAR])`; add `close_no_control` to its `InputContexts` listing; correct § D6 note "same `RealClock` Entrada uses for its tope" — the cap runs on `GameClock` (ADR-0002); `M_traspaso` computed on real time is conservative (real ≥ game) and therefore safe | technical-director | ADR-0003 revised |
| OI-2 | **Resolved 2026-11-10 (applied in ADR-0001 registry).** Amend ADR-0001 registry: `input_context_changed` payload `{anterior, contexto}` (GDD 1 rule 6 requires both); `no_control_absorbed.dueno` example `&"scene_director"`, not `&"21"`; closes ADR-0001 OI-6 for system 1 | technical-director | ADR-0001 revised |
| OI-3 | `architecture.md` § API Boundaries/Entrada: replace Spanish sketch with § Key Interfaces; QQ-16 closed | technical-director | `/architecture-review` |
| OI-4 | TR-pause-013 held repetition of `ui_izquierda/derecha` (0,4 s / 0,12 s) lives in 25's Controls with native GUI; confirm in ADR-0016 that native echo is suppressed | ADR-0016 | ADR-0016 accepted |
| OI-5 | GDD 1 rule 17 says "tecla imprimible"; this ADR enforces the stricter *text-field-consumed* set (adds `Backspace`, `Delete`, arrows, `Enter`). GDD wording to align | game-designer | GDD 1 next round |
| OI-6 | **Resolved: `RealClock` (ADR-0002).** ADR-0009 names the real clock `MonotonicClock` in `ServiceContext.real_clock`; ADR-0002 names it `RealClock`. This ADR uses `RealClock`; one name to be fixed | technical-director | ADR-0009 / ADR-0002 accepted |
| OI-7 | `ViewportMapper` (logical 1920×1080 ↔ window) and stretch mode | ADR-0016 | ADR-0016 accepted |
| OI-8 | Pad-family fallback `GENERIC` shows Xbox letters; a manual glyph-style setting would be a GDD 30 change (not decided here) | game-designer / accessibility | After S-0006-B |
| OI-9 | GDD 1 Open Question 19 (notice «asignaciones cambiadas») answered with `bindings_revision()`; 24 must poll it | ux / 24 author | GDD 24 next round |

## Spike Results

## Spike Results (2026-11-11)

Godot 4.7.2.stable, headless, synthetic events. Tests: `tests/unit/engine_facts/adr0006_input_events_test.gd`
and `adr0006_loop_order_test.gd`; harness for the rest: `prototypes/input-spike/` (README = exact steps).
Status stays `Proposed`: S-0006-A…E have unverified parts (NEEDS_MANUAL); none of the observed results contradicts a decision.

| S-n | Claim | Result | Figures observed | Fallback / note |
|---|---|---|---|---|
| S-0006-A | Raw joypad events: axis index/value, no engine deadzone, button indices, key repeat | PARTIAL (synthetic PASS; physical NEEDS_MANUAL) | `JOY_AXIS_LEFT_X/Y/RIGHT_X/Y/TRIGGER_L/R` = 0..5; `JOY_BUTTON_A`=0, `B`=1, `START`=6, `DPAD_UP`=11. A synthetic motion of 0,03 arrives in `_input` unmodified (float32: 0,0299999993). `parse_input_event` + `flush_buffered_events` updates `is_joy_button_pressed` even for an unconnected pad 0. `is_echo()` false by default, settable | Resting value of real hardware (<= 0,05?) and OS key repeat: NEEDS_MANUAL. R3 stays open |
| S-0006-B | Pad family from name/GUID | NEEDS_MANUAL (API verified) | `Input.get_joy_name(0)` = `""`, `get_joy_guid(0)` = `""`, `get_joy_info(0)` = `{}`, `get_connected_joypads()` = `[]` with no pad (no error) | Strings of DualSense/DS4/Xbox unknown: R1 / OI-8 (`GENERIC` fallback) |
| S-0006-C | Connect/disconnect signal, also paused | NEEDS_MANUAL (API verified) | `Input.joy_connection_changed(device: int, connected: bool)` exists, 2 args; a manual emit reaches subscribers | Delivery under pause and latency <= 0,5 s unmeasured: R2 polling fallback stands |
| S-0006-D | Mouse, `mouse_mode`, `DEVICE_ID_*`, key constants | PARTIAL, one assumption FALSE | `DEVICE_ID_KEYBOARD`=**16**, `DEVICE_ID_MOUSE`=**32**, `DEVICE_ID_EMULATION`=-1 (positive, not negative); a new `InputEventKey`/`MouseMotion` already has `device` 16/32, a new pad event 0. `relative` passes unscaled through `push_input`. `KEY_ESCAPE`=4194305, `KEY_ENTER`=4194309, `KEY_W`=87, `KEY_SPACE`=32; `as_text()` of W = `W`, `OS.get_keycode_string(KEY_ESCAPE)` = `Escape`. Headless: `Input.mouse_mode` write is ignored (stays 0 = VISIBLE after CAPTURED/HIDDEN) | Code must compare against the `DEVICE_ID_*` constants, never "negative = not a pad" (a real pad id could be confused only if >= 16). Relative px at 1080p/1440p, captured set/restore after focus loss: NEEDS_MANUAL (R5) |
| S-0006-E | Window focus-out reaches an `ALWAYS` autoload, also paused | NEEDS_MANUAL | Constants exist: `NOTIFICATION_APPLICATION_FOCUS_OUT`=2017, `..._IN`=2016, `NOTIFICATION_WM_WINDOW_FOCUS_OUT`=1005 | Needs a real window; harness prints `FOCUS_OUT` |
| S-0006-F | `LineEdit`, dual focus, `ui_*` in Input Map | PARTIAL PASS | `_input` → `_unhandled_input`; `set_input_as_handled()` in `_input` stops `_unhandled_input`. `LineEdit.grab_focus()` emits `focus_entered` then `focus_exited` on release. Input Map events: `ui_left/right/up/down/accept` = 3 each, `ui_cancel` = 1 | Mouse click on a `LineEdit` giving keyboard focus (needs a real pointer) and left stick/D-pad navigation: NEEDS_MANUAL; `ui_fixed` vs `project.godot` CI check not run here |
| C1 / NS-7 | Order of `_input`, `_physics_process`, `_process` between autoload-like nodes; same-frame bus delivery | MEASURED | Three root children A, B, C added in that order. `_input`: **reverse** tree order (C, B, A) in both `push_input` and the `parse_input_event` buffer. `_physics_process` and `_process`: add order (A, B, C). Per iteration: `_input` → all due `_physics_process` ticks → `_process`. With a tick due every iteration (1000 Hz): notice emitted in A's `_input` reached B's `_physics_process` and C's `_process` in the **same** frame (emitted 27, phys 27, proc 27). At 60 Hz with fast frames (headless) a tick is not due every iteration: the physics subscriber got it 1 iteration later (6→7, 15→16); `_process` subscriber same frame | The bus must not rely on a same-frame delivery to a physics subscriber (depends on whether a tick is due) nor on `_input` order between nodes. A queue drained once per tick or per frame is safe in both cases |

Not run: key repeat from the OS, real hot-plug, `Alt-Tab`, windows of two sizes (see the README of the harness).

## Related
- Depends on: ADR-0001, ADR-0002, ADR-0003, ADR-0009 (all `Proposed`).
- Amends (pending): ADR-0003 `open_no_control` call and D6 note (OI-1);
  ADR-0001 notice registry (OI-2).
- Enables: ADR-0007, ADR-0011, ADR-0012, ADR-0016, ADR-0017.
- Design: `design/gdd/entrada-y-controles.md`; `design/gdd/menu-de-pausa.md`;
  `design/gdd/ordenador-correo-impresora.md`; title GDD (27);
  `design/slice/slice-v0.3.md` §5.
- Code (once implemented): `src/input/input_router.gd`,
  `src/input/engine_input_adapter.gd`, `src/input/input_math.gd`,
  `src/input/binding_validator.gd`, `src/input/input_contexts_port.gd`,
  `assets/data/input/default_bindings.json`.
