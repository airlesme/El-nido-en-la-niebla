# ADR-0010: Puzzle Framework and Controller Contract

## Status

Accepted (2026-11-11) — no spike required; C4, C5 and C6 amendments recorded in Open Items to apply when the first story touches them

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-10

## Last Verified

2026-11-10 (against Godot 4.7 engine reference, ADR-0001…0009 and the
reconciliation of 2026-11-10)

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation: autonomous`);
user approval pending at end of batch.

## Summary

System 9 (`marco-de-puzles.md`) needs one implementation of the puzzle
lifecycle, validation scheduling, failure policy, fact writes, notices, idle
tracking and hint hook, shared by six controllers (systems 11–16) that must
stay pure and isolated. Decided: a scene-level `PuzzleFramework` node owns
every side effect and one `PuzzleRuntime` per puzzle; each puzzle is an
`@abstract PuzzleController` subclass that only holds its pieces and returns a
typed `Verdict`; the five validation policies are strategy objects driven by
an injected `GameClock`; hints, re-application, `first_action`, idle
re-emission, `commit_on`, `idle_reset`, `request_reading` and fact-only
persistence (rebuilt with `restore_solved_presentation`) are fixed here.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | Core (scripting architecture; no rendering/physics API) |
| **Layer** | Feature |
| **Knowledge Risk** | MEDIUM — `@abstract` (4.5) and typed-return override inheritance (4.7) are post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `current-best-practices.md` (§ GDScript: `@abstract`, § GDScript 4.7: typed-return overrides, lambdas); `breaking-changes.md` (rows "Overrides inherit a typed return", "`@abstract` decorator") |
| **Post-Cutoff APIs Used** | `@abstract` on classes and methods (4.5); 4.7 rule "an override of a typed method inherits its return type and needs an explicit `return`" |
| **Verification Required** | V1–V5 in § Validation Criteria (parse checks on 4.7.2 of the `@abstract` forms used, explicit returns, abstract instantiation error) |

**Engine claims and their sources:**

| Claim | Source |
|---|---|
| `@abstract` on a separate line before `class_name`, and `@abstract func f() -> T` with no body | `current-best-practices.md` § GDScript (4.5) example |
| Typed-return override needs explicit `return` | `current-best-practices.md` § GDScript (4.7); `breaking-changes.md` |
| `@abstract` on the **same line** as `class_name` (form used in `architecture.md` and ADR-0009 D5) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/current-best-practices.md`** (only the two-line form is shown). This ADR uses the two-line form; V1 checks the one-line form |
| Whether the 4.7 inherited-return rule also applies to `-> void` overrides | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/breaking-changes.md`**. Not relied on: void overrides need no `return` either way |
| Error raised when instantiating an `@abstract` class (`.new()`) — parse time or run time | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**. T-U1 records the observation |
| `@abstract` on an inner class (`class X:`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**. Not used: every abstract type here is a top-level `class_name` file |
| Tweens/AnimationPlayer freezing with `SceneTree.paused` | Out of scope here: ADR-0002 spike S5 (`FxTween.make`, G-9); this ADR's timers are `GameClock` only |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (bus, `FactWriter`, `NoticeIds`, write→notice order), ADR-0002 (`GameClock`: `now`/`delta`/`schedule`/`cancel`/`is_paused`, G-1…G-3), ADR-0003 (configure order 7 → 9, `INVALID_PUZZLE_DATA`, unload), ADR-0004 (save causes; save reads facts only), ADR-0005 (`puzzles.json` v2 schema, tiers L/B/C, `PuzzleDataRules` slot), ADR-0006 (input: the reject `lock` is not an input context), ADR-0009 (`configurar(ctx)`, `PuzzleServices`, `ViewGateProvider`/`BoxPresenter` adapters, D7 isolation, output ports) |
| **Enables** | ADR-0011 (interaction: `ViewReceiver` adapter shape, `PointerEvent`, `ViewElement`, `InteractionQuery`), ADR-0015 (`SurfaceFx` ops used by hints/P2/P5), ADR-0016 (UI: hint note via 17), ADR-0017 (director reacts to `EV_PUZZLE_SOLVED_*`) ; stories of epics 9, 10, 11–16, 17 |
| **Blocks** | Epic «Marco de puzles (9)», epics P1–P6 (11–16), «Caja (10)» gate stories, «Sistema de pistas (17)» API stories — until `Accepted` |
| **Ordering Note** | ADR-0011 must accept the `ViewReceiver`-as-port shape (OI-2) before the P1/P3–P6 view stories start; P2 (`WORLD`) can start after this ADR alone |

## Context

### Problem Statement

GDD 9 defines one framework for six heterogeneous puzzles (permutation,
lamp positions, drag-and-fit, per-card stamping, sustained rotation, single
choice). Without a fixed contract each controller would re-implement timers,
failure, fact writes and notices; the anti-softlock invariants S1–S9 (rule 28)
and the resolution order (rule 16) could then only be tested six times. The
controllers 11–16, GDD 17 (hints) and GDD 10 (box) have also signed changes
that 9 must absorb: `PARTIAL{element, action}` (14), `first_action`,
re-application, idle re-emission and `text_key` (17), and the per-zone
`atraccion_desactivada` exception of P1 (11).

### Current State

No code. `architecture.md` § API Boundaries carries a draft interface (13
abstract methods, `Verdict` with a `Dictionary` payload, `request_hint -> bool`).
ADR-0009 fixed where the framework lives (scene node, sub-layer F4), what a
controller may see (`PuzzleServices`) and the 9⇄10 ports. ADR-0005 fixed the
`puzzles.json` v2 schema and left cross-field rules (`PuzzleDataRules`) to this ADR.

### Constraints

- GDScript single inheritance: `PuzzleFramework extends Node` cannot also be a
  `ViewReceiver` or `ViewGateProvider` (ADR-0009 D5) — adapters.
- Controllers get **only** `PuzzleServices`: no writer, no bus, no peers (ADR-0009 D7).
- All game-time logic on the injected `GameClock`; `SceneTreeTimer`, `Timer`,
  `create_timer` forbidden (ADR-0002 G-1, G-3; TR-puzzles-014).
- Writes then notices in the same frame, in call order (ADR-0001 I-1/I-4).
- Release validation failure = scene-load failure of 4, never an inactive puzzle (GDD 9 R29).
- Slice scope: six puzzles, one scene (`planta`); no runtime puzzle authoring.

### Requirements

- One implementation of: public state machine, five policies, verdict
  processing, failure lock, resolution (immediate/deferred), idle, hint API,
  reconstruction from facts.
- Deterministic unit tests with a manually advanced clock and fake controllers.
- Per-frame cost negligible: only `SUSTAINED` with an open view evaluates every frame.
- The oracle test (rule 30, TR-puzzles-021) must drive the real pipeline.

## Decision

### D1. Topology

```text
planta.tscn
└─ PuzzleFramework (Node, F4, src/puzzles/framework/puzzle_framework.gd)
   ├─ P1Chronology   (PuzzleController, src/puzzles/p1_chronology/)
   ├─ P2Memo         (PuzzleController, src/puzzles/p2_memo/)       [WORLD]
   ├─ P3PhotoFit     (PuzzleController, src/puzzles/p3_photo_fit/)
   ├─ P4TaskBoard    (PuzzleController, src/puzzles/p4_task_board/)
   ├─ P5Mirror       (PuzzleController, src/puzzles/p5_mirror/)
   └─ P6Decision     (PuzzleController, src/puzzles/p6_decision/)
```

Folder slugs are ‡ (the ID `P<N>` is the binding part; ADR-0009 D7 pattern
`src/puzzles/p<N>_<slug>/`). Controllers are **child nodes** of the framework
in the scene; the framework finds them by `controller_id: StringName`
(exported, `&"P1"`…`&"P6"`), never by path into another system. Controller
presentation nodes (pieces, sheet, inner frame) live under each controller.

The framework holds one `PuzzleRuntime` (`RefCounted`, framework-private) per
puzzle: public state, internal phase, policy object, last `progress`, lock,
timers, idle tracker, hint ledger, engagement data. **No runtime field is
visible to any controller.**

`PuzzleController` is defined in 9's folder and implemented by F5 systems: it
is an output port in the sense of ADR-0009 D6 (the interface belongs to the
caller's layer), so 9 → 11–16 calls are not upward calls.

### D2. `PuzzleController` (abstract contract, common to the six controllers)

Thirteen abstract methods (TR-puzzles-008) plus four virtual hooks with a
default body (the base "only provides data utilities", rule 9 — the hooks are
default no-ops, not behaviour).

```gdscript
# src/puzzles/framework/puzzle_controller.gd
## Base of every puzzle controller (11–16). Holds only its own pieces.
## Never writes facts, never emits notices, never changes public state (rule 10).
@abstract
class_name PuzzleController extends Node

## Emitted on every change of a shape, z-order, accepted gestures or element
## state. `tag` (e.g. &"REF_PLACED") drives `on_change.sfx` (rule 4b-k).
signal elements_changed(tag: StringName)

@export var controller_id: StringName = &""      # &"P1" … &"P6"

var services: PuzzleServices = null               # set by the framework before configure()

## Read definition (already normalised, ints converted) and the facts the
## definition names (already filtered by 9). Writes nothing.
@abstract func configure(def: Dictionary, flags: Dictionary) -> void
## VIEW only. Called after 9 computed missing_items (D15).
@abstract func on_open() -> void
## motivo ∈ &"jugador" | &"resuelto" | &"sistema".
@abstract func on_close(motivo: StringName) -> void
## 7's picking contract. Excludes `visual_elements` and `decor`.
@abstract func elements() -> Array[ViewElement]
@abstract func handle_pointer(ev: PointerEvent) -> void
## WORLD only. Returns ActivationResult.DONE (HECHO) or NO_EFFECT (SIN_EFECTO).
@abstract func handle_activation(element_id: StringName, verb: StringName) -> int
## Silent return of the in-flight piece (rule 11b). Never evaluates.
@abstract func cancel_gesture() -> void
## PURE: function of own state + definition. No time, no accumulator.
@abstract func evaluate() -> Verdict
@abstract func reset_attempt(scope: StringName, element: StringName) -> void
## step = {call, args} (IMMEDIATE presentation) or a DEFERRED step record.
@abstract func play_resolution(step: Dictionary) -> void
## Final look without notices, sounds or animation; idempotent (rule 8, D9-51).
@abstract func restore_solved_presentation() -> void
## Returns true iff the state of some element changed (rule 12b).
@abstract func apply_hint_effect(effect: Dictionary) -> bool

# --- virtual hooks with defaults (override only where the GDD needs it) ---

## Re-application ("Repetir", GDD 17 R13): presentation only. Return false
## when the effect is persistent and already visible (17 shows "Ya está a la vista").
func replay_hint_effect(effect: Dictionary) -> bool:
    return true
## Hint `condition` (today only &"HELD_PIECE", P3 level 3).
func is_condition_met(condition: StringName) -> bool:
    return false
## Called by 9 when a setting it relays changes (asistencia_*, reducir_movimiento).
func on_setting_changed(key: StringName) -> void:
    pass
## P5 only (rule 19): resume a DEFERRED reveal; set θ = θ*.
func prepare_resume() -> void:
    pass
## Values of the facts listed in def.persist (P2: {&"pos_L": 2, …}); 9 writes them (D12).
func persist_values() -> Dictionary:
    return {}
```

```gdscript
# src/puzzles/framework/activation_result.gd
class_name ActivationResult
const DONE: int = 0        # HECHO
const NO_EFFECT: int = 1   # SIN_EFECTO
```

Rules (must / must never):

- Every override of a typed abstract method **must** end in an explicit
  `return` of the declared type (4.7 rule); `-> void` overrides need none.
- A controller **must never** call `GameClock.schedule` for game logic of 9's
  (locks, delays, accumulators, idle). It **may** read `services.clock` for its
  own presentation tweens' pacing only (P5 `theta_settle_s`), via `FxTween.make`
  (ADR-0002 G-9).
- `configure()` **must not** call `services.box` (see D12 for the one exemption
  in `restore_solved_presentation`).
- `handle_activation` returns `NO_EFFECT` only for a `RESUELTO` puzzle, and 9
  short-circuits that case before calling (rule 7); a controller returning
  `NO_EFFECT` while `ACTIVO` is a programming error (logged).

`ViewElement` and `PointerEvent` are 7's types (ADR-0011); this ADR assumes
the fields of GDD 9 rule 9 / 7 rule 20: `ViewElement {id, shape, z_order,
attraction: bool, accepted_gestures: Array[StringName]}`, `PointerEvent
{gesto, fase, elemento, elemento_bajo, pos_px, pos_vista, delta_px, delta_grados}`
(names ‡ ADR-0011).

### D3. `Verdict` (typed value object)

The `Dictionary` payload of `architecture.md` is replaced by typed fields so
`PARTIAL{element, action}` (14) and `SOLVED{choice | t4_action}` are checkable.

```gdscript
# src/puzzles/framework/verdict.gd
## Result of PuzzleController.evaluate(). Immutable after construction.
class_name Verdict extends RefCounted

enum Kind { NONE, HOLDING, PARTIAL, REJECT, SOLVED }

var kind: Kind = Kind.NONE
## PARTIAL: IDs of elements currently correct (rule 13b edge).
var progress: Array[StringName] = []
## PARTIAL (P4: the card just incorporated) or REJECT (affected element).
var element: StringName = &""
## PARTIAL (P4: &"ASSIGN" | &"RETURN"); keys on_partial.stamp_text_keys.
var action: StringName = &""
## SOLVED: value_from source keys (&"choice" P6, &"t4_action" P4).
var payload: Dictionary = {}

static func none() -> Verdict:
    return Verdict.new()

static func holding() -> Verdict:
    var v := Verdict.new()
    v.kind = Kind.HOLDING
    return v

static func partial(p: Array[StringName], el: StringName = &"", act: StringName = &"") -> Verdict:
    var v := Verdict.new()
    v.kind = Kind.PARTIAL
    v.progress = p.duplicate()
    v.element = el
    v.action = act
    return v

static func reject(el: StringName) -> Verdict:
    var v := Verdict.new()
    v.kind = Kind.REJECT
    v.element = el
    return v

static func solved(carry: Dictionary = {}) -> Verdict:
    var v := Verdict.new()
    v.kind = Kind.SOLVED
    v.payload = carry.duplicate()
    return v
```

Admissibility (framework-enforced, rule 13/15): a verdict kind not admitted by
the puzzle's policy, or a `REJECT`/`PARTIAL` whose `element` falls outside
`on_reject.applies_to` / `on_partial.elements`, is **treated as `NONE` and
logged as a data error** (`LogSink` warn; dev `ErrorPolicy.fail`).

| Policy | Admitted kinds |
|---|---|
| `DELAYED_AFTER_CHANGE` | NONE, REJECT, SOLVED |
| `ON_CHANGE` | NONE, PARTIAL, SOLVED |
| `PER_ELEMENT` | NONE, PARTIAL, REJECT, SOLVED |
| `SUSTAINED` | NONE, HOLDING (SOLVED from the controller is **inadmissible**) |
| `ON_CHOICE` | NONE, SOLVED |

### D4. The five validation policies (strategy objects)

```gdscript
# src/puzzles/framework/policies/validation_policy.gd
## Decides WHEN 9 calls evaluate(). Never decides what a verdict means.
@abstract
class_name ValidationPolicy extends RefCounted
## A state change of an element (gesture end, hint true, reset_attempt, restore).
@abstract func on_change(rt: PuzzleRuntime) -> void
## A forwarded pointer event (after the controller handled it).
@abstract func on_pointer(rt: PuzzleRuntime, ev: PointerEvent) -> void
## Every frame with the puzzle engaged (dt = GameClock.delta()).
@abstract func on_frame(rt: PuzzleRuntime, dt: float) -> void
## View closed, cancellation or interrupt: drop transient state (rule 21b).
@abstract func on_disengage(rt: PuzzleRuntime) -> void
@abstract func admits(kind: Verdict.Kind) -> bool
```

| Policy (data) | Class | When `evaluate()` is called | Transient state (framework-owned) |
|---|---|---|---|
| `DELAYED_AFTER_CHANGE` (P1) | `DelayedAfterChangePolicy` | `delay_s` after the last change, via `GameClock.schedule`; every change cancels and re-arms (F1). It arms on **every** change; the "all slots full" test is the controller's `NONE` (rule 12, R12/R21 of 11). Disengage cancels; re-engage re-arms once (F1 example) | one `GameClock` handle |
| `ON_CHANGE` (P2) | `OnChangePolicy` | synchronously after every change; once after «escena lista» (D12) | none |
| `PER_ELEMENT` (P3, P4) | `PerElementPolicy` | synchronously after a change the controller reports as an **element completion**: `elements_changed` with tag in `{&"PIECE_DROPPED", &"CARD_COMPLETED", &"CARD_RETURNED"}` ‡ (tags fixed in 13/14 stories) or any change from a hint/reset | none |
| `SUSTAINED` (P5) | `SustainedPolicy` | every frame while engaged and phase ≠ `RESOLVING`; `acum += min(dt, dt_max)` on `HOLDING`, `0` otherwise, on disengage and on `cancelación`; `SOLVED` when `acum ≥ hold_s − EPS` (`EPS = 0.0001`, F2) — the **framework** synthesises `Verdict.solved()` | `acum: float` |
| `ON_CHOICE` (P6) | `OnChoicePolicy` | after every forwarded `seleccionar` event of phase `inicio` or `fin` (never `cancelación`); the controller returns `SOLVED{choice}` only once its `ChoiceCommit` helper (D7) reports a commit | none |

`dt` is always `GameClock.delta()` — 0 while paused, so pause freezes every
policy by construction (TR-puzzles-014). Rule 12b: **every** state-changing
path (gesture, `apply_hint_effect → true`, `reset_attempt`, restore) ends in
`policy.on_change(rt)`; nothing calls `evaluate()` outside a policy.

### D5. Verdict processing (one pipeline, rules 13–17)

```gdscript
# inside PuzzleFramework — single entry for every verdict
func _process_verdict(rt: PuzzleRuntime, v: Verdict) -> void:
    if rt.public_state != PublicState.ACTIVO or rt.solved_this_frame:
        return                                            # S9: second SOLVED same frame dropped
    if not rt.policy.admits(v.kind) or not _element_admitted(rt, v):
        _log_data_error(rt, v)
        v = Verdict.none()
    match v.kind:
        Verdict.Kind.NONE:
            rt.policy_reset_hold()                        # SUSTAINED acum = 0
        Verdict.Kind.HOLDING:
            pass                                          # SustainedPolicy accumulates
        Verdict.Kind.PARTIAL:
            _emit_partial_edge(rt, v)                     # rule 13b, D5.1
        Verdict.Kind.REJECT:
            _apply_reject(rt, v)                          # rule 14, D5.2
        Verdict.Kind.SOLVED:
            rt.solved_this_frame = true
            if rt.def.resolution.kind == &"DEFERRED":
                _start_deferred(rt, v)                    # rule 17, D5.4
            else:
                _commit_solved(rt, v)                     # rule 16, D5.3
```

`solved_this_frame` is cleared at the next `GameClock` frame (the framework's
`_process`), giving "idempotent per frame" (TR-puzzles-007, TR-puzzle4-017,
TR-puzzle6-005); after commit the public state is `RESUELTO` and the first
guard drops everything anyway.

**D5.1 `PARTIAL` edge.** `new = v.progress − rt.last_progress`. For each
element in `new` (order of `v.progress`): notify `puzzle_feedback {puzzle,
sound_id: on_partial.sfx, text_key: on_partial.stamp_text_keys.get(v.action, null),
element}`. Only when `v.element != &""` and it is in `new` does `action`
select the stamp text; `progress` stays mandatory (it drives the edge for
P2/P3). Then `rt.last_progress = v.progress`. A decrease emits nothing.
After `REJECT` or `reset_attempt`, `last_progress` is recomputed by calling
`evaluate()` **without processing** it (a pure call has no effect) and taking
its `progress` when `PARTIAL`, else `[]`.

**D5.2 `REJECT`** (rule 14, TR-puzzles-018): (a) notify `puzzle_feedback
{puzzle, sound_id: on_reject.sfx, text_key: on_reject.message_key?, element}`
and ask the controller for the shake (its own presentation, honouring
`reducir_movimiento`, rule 14b) through `play_resolution({call: &"reject",
args: [element, shake_s]})`; (b) `reset_attempt(scope, element)` after
`reset_after_s` (scheduled on `GameClock`; `0.0` = same frame); then
`policy.on_change`; (c) set `rt.lock` = `{scope: PUZZLE|ELEMENT|NONE, element,
until_s: clock.now() + reset_after_s}`; events matching the lock are
**discarded**, never queued; (d) nothing else changes. No counters exist
(playtest log D16 records, rules never read it). Validation guarantees
`reset_after_s ≤ lock_max_s = 2.0`.

**D5.3 Immediate commit** (rule 16, TR-puzzles-011), one frame, in order:

```gdscript
func _commit_solved(rt: PuzzleRuntime, v: Verdict) -> void:
    for w: Dictionary in rt.def.on_solved.write:          # 16.1 declared order
        _writer.write(w.flag, _resolve_write_value(w, v.payload))
    if not _wrote(rt.def.on_solved.write, rt.def.solved_flag):
        _writer.write(rt.def.solved_flag, true)          # 16.2
    rt.public_state = PublicState.RESUELTO               # 16.3 (idempotent)
    rt.phase = Phase.IDLE
    var ev: Dictionary = {"puzzle": rt.id, "rewards": rt.def.on_solved.get("rewards", [])}
    if v.payload.has(&"choice"):
        ev["choice"] = v.payload[&"choice"]
    _state.notify(NoticeIds.puzzle_solved(rt.id), ev)    # 16.4 EV_PUZZLE_SOLVED_<ID>
    if rt.def.on_solved.has("compartment"):
        _state.notify(NoticeIds.COMPARTMENT_COMPLETED, {"n": int(rt.def.on_solved.compartment)})  # 16.5
    _start_presentation(rt)                              # 16.6 non-blocking: sfx, presentation[], request_reading
    _schedule_close(rt)                                  # 16.7 close_view_after_s (null = none)
    _idle_stop(rt)
```

`_resolve_write_value`: literal `value`, or `payload[value_from]` passed
through `map` when present (P4 `RETURN→returned`; P6 copied as is). A
missing payload key is a programming error (dev fail; release: skip that
write, log, and still write `solved_flag` — never a stuck puzzle).

**D5.4 Deferred resolution** (P5, rules 17–20, TR-puzzles-012/-013):
on `SOLVED`: `cancel_gesture()` if a gesture is active (silent), controller
sets θ = θ* (inside its `play_resolution({call: &"begin"})`), write
`resume_flag = true`, phase `RESOLVING`, run `resolution.steps` in order, each
on `GameClock.schedule(duration_s)`; a `LINE` step notifies `line_requested
{puzzle, line_id, fallback_s}` and ends at the first of: «línea terminada»
(capped at `fallback_s + line_grace_s`), `fallback_s` after «línea sin audio»
/ «línea fallida», or `fallback_s + line_grace_s` with no signal. 23's
signals arriving while paused are processed when the bus delivers them; the
step clock is `GameClock` so pause cannot shorten a step. At the end:
write `solved_flag` (16.1–16.2), write `resume_flag = false`, then 16.3–16.7.
**Interrupt** only by leaving the view (`on_close` with `jugador`/`sistema`,
`cerrar_modos`, scene unload): cancel step handles, notify
`puzzle_resolution_interrupted {puzzle}` (closes ADR-0001 OI-6 for key
`puzzle`), phase `IDLE`, nothing of rule 16 written. On re-engage with
`resume_flag` true: skip validation, `prepare_resume()`, replay from step 1.

### D6. `GameClock` injection and timers

- The framework copies `ctx.clock` (`GameClock`) in `configurar()`; controllers
  get the read-only `GameClockReader` of ADR-0009 D7.
- All framework timers go through one helper so they can be cancelled together:

```gdscript
# src/puzzles/framework/puzzle_timers.gd
## Owns GameClock handles per puzzle. cancel_all() on disengage/unload.
class_name PuzzleTimers extends RefCounted
var _clock: GameClock
var _handles: Dictionary = {}     # key: StringName (&"delay", &"lock", &"step", &"close", &"reading", &"present_0"…) → int

func _init(clock: GameClock) -> void:
    _clock = clock

func start(key: StringName, after_s: float, cb: Callable) -> void:
    stop(key)
    _handles[key] = _clock.schedule(after_s, cb)

func stop(key: StringName) -> void:
    if _handles.has(key):
        _clock.cancel(_handles[key])
        _handles.erase(key)

func stop_all() -> void:
    for k: StringName in _handles.keys():
        _clock.cancel(_handles[k])
    _handles.clear()
```

- Timers covered: F1 delay, rule-14 lock and reset, F2 accumulator (per frame,
  no handle), F3 idle (polled each frame against `clock.now()`), F4 close,
  F8 steps and `line_grace_s`, `presentation[].at_s`, `request_reading.at_s`,
  hint `duration_s` (HIGHLIGHT owned by 9). CI grep (ADR-0002 G-3) covers
  `src/puzzles/`.
- `_exit_tree()` calls `stop_all()` on every runtime and releases the
  `SubscriptionBag` (ADR-0009 rule 6).

### D7. Input path, lock, cancellation and `commit_on`

- 9 registers with 7 **in `configurar()`** (7 is F1, already configured): one
  `ViewReceiver` adapter per `VIEW` puzzle (`registrar_receptor(view, adapter)`)
  and itself as handler of the `WORLD` elements that are not `decor`
  (`registrar_manejador(&"B01"…)`). Adapters follow ADR-0009 D5 (`WeakRef`
  owner, safe default). If ADR-0011 keeps `ViewReceiver extends Node`, the
  adapter is a child `Node` of the framework instead (OI-2).
- Forwarding order per event: (1) drop if phase `RESOLVING` (except the
  `atrás`-driven `on_close`, which 7 owns) or if `rt.lock` matches; (2) idle
  tracker sees the event (D8); (3) controller `handle_pointer(ev)`; (4)
  `policy.on_pointer(rt, ev)`; (5) on `fase == cancelación`: `cancel_gesture()`,
  `policy.on_disengage(rt)` for transient state only, no evaluation, no sound.
- `WORLD` activation: `can_interact(Girar)` → yes always; `interact` → if
  `RESUELTO` return `NO_EFFECT`; else `handle_activation` and, on `DONE`,
  record `first_action` (D9), feed idle/policy as a change.
- **`commit_on`** (rule 4b-g) lives in `solution` and is interpreted by a
  framework-provided pure helper composed by any `ON_CHOICE` controller:

```gdscript
# src/puzzles/framework/choice_commit.gd
## Pure commit tracker for ON_CHOICE puzzles (P6). No time, no side effects.
class_name ChoiceCommit extends RefCounted
const SELECT_END_SAME_ELEMENT: StringName = &"SELECT_END_SAME_ELEMENT"
const SELECT_START: StringName = &"SELECT_START"
var mode: StringName = SELECT_END_SAME_ELEMENT
var _pressed: StringName = &""
var committed: StringName = &""          # element id; &"" = none

## Returns true when this event commits a choice.
func feed(ev: PointerEvent) -> bool:
    if committed != &"" or ev.gesto != &"seleccionar":
        return false
    match ev.fase:
        &"inicio":
            _pressed = ev.elemento
            if mode == SELECT_START and _pressed != &"":
                committed = _pressed
                return true
        &"fin":
            if mode == SELECT_END_SAME_ELEMENT and _pressed != &"" and ev.elemento == ev.elemento_bajo:
                committed = _pressed
                _pressed = &""
                return true
            _pressed = &""
        &"cancelación":
            _pressed = &""
    return false
```

  `inicio` and `fin` in the same frame are processed in arrival order (7
  delivers them in order). The controller maps `committed` → `choice`; its
  `evaluate()` returns `Verdict.solved({&"choice": …})` iff `committed != &""`.

### D8. Idle tracking (`idle_reset`) and «puzle inactivo»

One `IdleTracker` (`RefCounted`, framework-owned) per engaged puzzle (VIEW:
between `on_open` and `on_close`; WORLD: never engaged → no IDLE levels in the
slice, P2 has none).

| `idle_reset` | Resets `t_last_action` and anchor |
|---|---|
| `GESTURE` (default) | `inicio`/`fin`/`cancelación` of any gesture; element state change; hint application |
| `GESTURE_AND_MOVE` (P3) | the above **plus** a pointer `actualización` farther than `idle_move_px` (≥16, P3 = 40, logical 1920×1080) from the anchor |
| `PRESS_ONLY` (P6) | only `seleccionar` `inicio` (also on empty space) |

Each frame: `idle = clock.now() − t_last_action`. For each `IDLE` level not
yet consumed in this engagement, crossing `idle_s` marks it **due** and
notifies `puzzle_idle {id, nivel}` once. Then:

- If `idle_hints_auto_apply` (data; `false` in the slice because 17 exists,
  D9-81 / TR-hints-014) → 9 calls its own `request_hint(id, nivel)`.
- **Re-emission (17 point 1):** a due level whose `condition` was false when
  it became due is re-checked every frame through
  `controller.is_condition_met(condition)`; on the false→true edge 9 notifies
  `puzzle_idle {id, nivel}` **again** (once per edge). The level is consumed
  only when `request_hint` applies it.
- A `REQUEST` of that level (from 17 / the pause) consumes it (rule 25).
- Re-engaging re-arms unconsumed-in-engagement levels from `idle = 0`;
  `hint_level_reached` never decreases.

### D9. Hint API for 17 (`list_puzzles`, `get_hints`, `request_hint`)

```gdscript
# PuzzleFramework public API used by 17 (ADR-0009 D4 row 17)
enum PublicState { BLOQUEADO, ACTIVO, RESUELTO }

class_name HintOutcome    # src/puzzles/framework/hint_outcome.gd
const REFUSED: int = 0          # not ACTIVO, RESOLVING, unknown id/level
const APPLIED: int = 1          # first application: level reached, «pista aplicada» emitted
const REAPPLIED: int = 2        # level already applied: presentation repeated, nothing else
const ALREADY_VISIBLE: int = 3  # level already applied and every effect persistent & visible

## One entry per puzzle, in P1…P6 order.
## {id, state: PublicState, resolving: bool, mode: &"VIEW"|&"WORLD", view_id: StringName|null,
##  last_engaged_s: float|null, first_action_s: float|null, hint_level_reached: int}
func list_puzzles() -> Array[Dictionary]
## The rule-25 records of `id` (normalised; `effects` included), [] if unknown.
func get_hints(id: StringName) -> Array[Dictionary]
func request_hint(id: StringName, level: int) -> int    # HintOutcome
```

`request_hint` algorithm:

1. Unknown id/level, puzzle not `ACTIVO`, or phase `RESOLVING` → `REFUSED`
   (logged for D16; no level, no IDLE consumption, rule 26, D9-74).
2. **Level already in `rt.applied_levels` → re-application** (17 R13, D17-23,
   TR-hints-013): for each effect: `TEXT` → nothing (17 shows its own note from
   its ledger); `AUTO_SOLVE_ELEMENT` → **skipped**; `HIGHLIGHT` → re-shown by
   its presenter for `duration_s`; `AFFORDANCE` → `controller.replay_hint_effect`.
   No `evaluate()`, no `hint_level_reached` change, no IDLE consumption, **no
   «pista aplicada»**. Result `ALREADY_VISIBLE` if every non-text effect
   reported already visible, else `REAPPLIED`. A level lower than the maximum
   that was applied is the same case.
3. **First application**: add to `applied_levels`, `hint_level_reached =
   max(...)`, consume its IDLE threshold if any; apply each non-text effect —
   `HIGHLIGHT` of view elements/`visual_elements` → controller
   `apply_hint_effect`; `HIGHLIGHT` of world objects (`V08`, `B0x`, `decor`)
   → 9 through `SurfaceFx` (op ‡ ADR-0015; `NullSurfaceFx` absent); with
   `needs_items` missing, `targets_if_missing_items` replaces `targets`;
   `AFFORDANCE`/`AUTO_SOLVE_ELEMENT` → `apply_hint_effect`; any `true` →
   `policy.on_change` (rule 12b, possibly `SOLVED` in the same call). Then
   notify `hint_applied {id, nivel, text_key}` where `text_key` is the
   `PISTA_*` of the level's `TEXT` effect or `null` (17 point 5, TR-hints-015).
   9 never draws or defers text. Return `APPLIED`.
4. Effects with duration run on `GameClock` (start at resume when requested in
   pause); a view effect requested with the view closed is applied to state
   and shown on next `on_open`.

`first_action_s`: `clock.now()` of the first `DONE` activation of a `WORLD`
puzzle in the scene session (17 `discover_if: FIRST_ACTION`, TR-hints-006/-007);
`null` otherwise and for `VIEW`. `last_engaged_s`: `clock.now()` at the last
`on_open`. Both memory-only, reset on configure. `list_puzzles` exposes
`resolving` so 17 can list `ACTIVO`/`RESOLVING` puzzles (TR-hints-006).

### D10. View elements: attraction and the P1 chip exception

`elements()` returns the controller's list; the framework's `ViewReceiver`
adapter post-processes it **once per call** with `element_zones` (rule 4b-c):
for each zone whose `ids` (exact or trailing-`*` prefix) match an element,
`atraccion_desactivada: true` forces `attraction = false`. **Exception to rule
9 accepted (P1, D11-17):** rule 9 lists "referencias y huecos del P1" as
attraction targets; P1's `ref_*` zone declares `atraccion_desactivada`, so
`C05/paper/ref_N` has `attraction = false` and only `C05/slot_k` attracts.
The controller may still return `attraction = true` by role; the zone wins.
Validation (D13) uses the zone flag when checking separation (R29).

### D11. `request_reading` and presentation

`_start_presentation(rt)`: notify `puzzle_feedback {puzzle, sound_id:
on_solved.sfx}` if present; for each `presentation[i]` schedule
`play_resolution({call, args})` at `at_s` (catalogue: `play_open(n)` — the
controller forwards to `services.box.play_open(n)`; 9 never animates the
lid); if `request_reading` present, schedule at `at_s` a single call to 7's
`abrir_lectura(doc)`. 9 **does not retry or cancel** it on `APLAZADA`/
`RECHAZADA` (7 owns deferral, TR-interact-020; rule 16.6); the result is
logged. Scene unload cancels pending entries (D6). P6: `close_view_after_s`
is `null` → no close.

### D12. Persistence by facts and reconstruction

- 9 persists **nothing of its own** (TR-puzzles-016): facts only —
  `solved_flag`s, `pos_L/C/R` (written by 9 in **every** P2 change from
  `persist_values()`, see note), `pendiente_revelacion`,
  `carta_variante`, `t4_decision`. Partial progress, `hint_level_reached`,
  `applied_levels`, `first_action_s` are memory-only.
- **Configuration** (`configurar(ctx)`, synchronous, GDD 4 r9.6, TR-puzzles-015):

```gdscript
func configurar(ctx: ServiceContext) -> void:
    if not ctx.require(&"puzzles", [&"state", &"clock", &"content", &"settings", &"scene.interaction"]):
        return
    # copy refs (rule 4 of ADR-0009 D3); writer via composition (OI-1)
    var defs: Array[Dictionary] = _load_and_validate(ctx)   # tier L, D13
    if defs.is_empty():
        _config_failed = true                               # read by GameSceneRoot.configure_all
        return
    for def: Dictionary in defs:
        var rt := _build_runtime(def)                       # controller.services = PuzzleServices (ADR-0009 D7)
        rt.controller.configure(def, _filtered_flags(def))
        if _state.get_fact(def.solved_flag):
            rt.public_state = PublicState.RESUELTO          # (1)
            rt.controller.restore_solved_presentation()     # instant, silent
            var rf: StringName = def.resolution.get("resume_flag", &"")
            if rf != &"" and _state.get_fact(rf):
                _writer.write_silent(rf, false)             # rule 8 / 19
        elif _requires_met(def):
            rt.public_state = PublicState.ACTIVO            # (2) silent
        else:
            rt.public_state = PublicState.BLOQUEADO
            _subscribe_requires(rt)                         # rule 24
        # (3) persist facts were passed in `flags` → controller restored them in configure()
        _register_with_interaction(rt)
    _subs.notice(_state, NoticeIds.SCENE_READY, _on_scene_ready_once)   # ON_CHANGE re-evaluation
    _state.notify(NoticeIds.PUZZLES_CONFIGURED, {})         # once, before «escena lista»
```

- Note on `persist`: the controller restores from `flags` in `configure()`;
  to write `pos_*`, the framework reads `controller.persist_values()` (D2
  hook, default `{}`) after each processed change of a puzzle with a
  non-empty `persist` list, and writes only the keys listed in `persist`
  (P2). Unknown keys → data error.
- **Exemption to ADR-0009 D3 rule 5:** `restore_solved_presentation()` runs
  inside 9's `configurar()` and calls `BoxPresenter.set_final_pose(n)`, a call
  to F4's Box before «escena lista». Allowed because the call is idempotent,
  silent and touches only Box's own subtree (ready since `_ready`); Box's
  adapter **must** accept it before `Box.configurar` (Box also rebuilds its
  pose from `caja_c*`, TR-box-001 — double set is harmless). Amendment
  required in ADR-0009 (C4).
- On «escena lista», once: `evaluate()` on `ON_CHANGE` puzzles (P2: `pos =
  3,1,4` with `memo_leido` false resolves by the normal path).
- P5 unresolved with `pendiente_revelacion` true stays true; the reveal
  replays on next engagement (D5.4).
- Dev console (rule 31): a fact change to `solved_flag`/`requires.all` not
  produced by 9 reconciles silently (to `RESUELTO` + restore; or `ACTIVO`/
  `BLOQUEADO` with memory reset) without `EV_PUZZLE_SOLVED_*`. Detection: the
  framework tracks its own pending writes; a change it did not write is
  external.
- Monotony (S2): no API returns a puzzle to an earlier state; only the
  reconciliation path above, compiled into dev builds only (ADR-0018 strip).

### D13. Validation (`PuzzleDataRules`) and failure path

`PuzzleDataRules` (`src/puzzles/data/puzzle_data_rules.gd`) implements every
cross-field/cross-file check of GDD 9 rule 29 listed in ADR-0005 D2.4, as a
`FileRules` of ADR-0005 (one implementation for tiers L, B, C). Additions
fixed here: `on_partial.elements` and `on_reject.applies_to` reference
`elements()`-level IDs declared in data; `presentation[].call ∈ {play_open}`
with `args == [compartment]`; `hints` count 3 (P6: 2); separation check
honours `element_zones.atraccion_desactivada`; `idle_hints_auto_apply` BOOL.

Failure in `configurar()`: collect all issues → `ctx.fatal.raise_fatal(
&"DATOS_ESCENA_INVALIDOS", {count, first})` (ADR-0009 D8) **and** set
`_config_failed`; `GameSceneRoot.configure_all` reads
`PuzzleFramework.configuration_failed() -> bool` and returns
`INVALID_PUZZLE_DATA` (ADR-0003 step 6). No controller is configured, no
receiver registered — nothing half-configured.

### D14. Notices emitted by 9 (registry of ADR-0001, unchanged names)

| Notice | Payload (literal keys) | When |
|---|---|---|
| `EV_PUZZLE_SOLVED_P1…P6` | `puzzle`, `rewards`, `choice?` | 16.4 |
| `compartment_completed` | `n` | 16.5 |
| `puzzle_activated` | `puzzle`, `ajar_cm?` | `BLOQUEADO → ACTIVO` at runtime (never at load) |
| `puzzle_feedback` | `puzzle`, `sound_id`, `text_key?`, `element?` | partial edge, reject, `on_change` tag, `on_unlock`, `locked_feedback`, success sfx |
| `line_requested` | `line_id`, `puzzle`, `fallback_s` | `LINE` step |
| `puzzle_resolution_interrupted` | `puzzle` | D5.4 (closes ADR-0001 OI-6 for this key) |
| `hint_applied` | `id`, `nivel`, `text_key` (`SN` or `null`) | first application only |
| `puzzle_idle` | `id`, `nivel` | threshold crossing **and** condition false→true edge |
| `puzzles_configured` | — | end of `configurar()` |

`id`/`nivel` vs `puzzle` asymmetry is inherited from ADR-0001 / GDD 17 and kept.

### D15. View gate (port for 10) and safety net

`get_view_gate(view_id) -> {state: &"OPEN"|&"BLOCKED"|&"SOLVED",
missing_items: Array[StringName], feedback_sfx: StringName, feedback_text_key:
StringName}` (ADR-0009 D5 shape; `missing_items` is a list — empty = none;
GDD 9 rule 7's `bool` is replaced, C5). `missing_items` is computed with
`PocketQuery.has_item` (9 calls 20 directly per ADR-0009 D4) at every
`on_open`. **P1 sheet:** GDD 9 rule 7 says "9 draws `C05/paper` with
`compose_i01()`"; since ADR-0009 D7 already puts `composer` and `pocket` in
P1's `PuzzleServices`, the call is made **by the P1 controller inside
`on_open()`**, guarded by `services.pocket.has_item(&"I-01")`, on every
opening (including re-opening while `ACTIVO`). 9 keeps ownership of the
gate (`missing_items`, `locked_feedback`); the sheet layout data
(`p1_view.json`) is 9's file passed in `def`. Recorded as C10. Safety net: a
view of a `BLOQUEADO`/`RESUELTO` puzzle opened by another path → emit
`locked_feedback` and `cerrar_vista(view, &"sistema")` (TR-puzzle1-017).

### D16. Playtest log

`PuzzlePlaytestLog` (dev/playtest builds only; stripped from the demo by
ADR-0018): per-puzzle time to solve, attempts, rejects, hints applied/
refused-in-`RESOLVING`, view closes, verdict element/action/choice. It is
write-only from 9; no rule reads it (TR-puzzles-022).

### Architecture Diagram

```text
             7 InteractionSystem (F1)                   17 HintService (F5)
     PointerEvent │ ▲ elements()                 list/get/request_hint │ ▲ puzzle_idle, hint_applied
                  ▼ │                                                  ▼ │ (bus)
  ┌────────────────────────── PuzzleFramework (F4) ──────────────────────────┐
  │ ViewReceiver adapters ─► PuzzleRuntime ×6 ─► ValidationPolicy ×5 kinds    │
  │                           │  lock · timers(GameClock) · IdleTracker       │
  │                           │  hint ledger · last_progress                  │
  │  FactWriter(9) ◄── _commit_solved / persist / resume_flag                 │
  │  GameState.notify ◄── D14 notices          ViewGateProvider adapter ──► 10│
  └───────────┬───────────────────────────────────────────────▲─────────────┘
   configure/evaluate/…  │ Verdict, elements_changed            │ BoxPresenter
                        ▼                                       │
        PuzzleController (P1…P6, F5) ── PuzzleServices{clock reader, settings
        reader, content, pocket, composer, box, surface_fx, interaction_query}
```

### Key Interfaces

| Interface | Kind | Path | Section |
|---|---|---|---|
| `PuzzleController` | `@abstract Node` | `src/puzzles/framework/puzzle_controller.gd` | D2 |
| `Verdict` | `RefCounted` | `src/puzzles/framework/verdict.gd` | D3 |
| `ValidationPolicy` + 5 subclasses | `@abstract RefCounted` | `src/puzzles/framework/policies/` | D4 |
| `PuzzleTimers` | `RefCounted` | `src/puzzles/framework/puzzle_timers.gd` | D6 |
| `ChoiceCommit` | `RefCounted` | `src/puzzles/framework/choice_commit.gd` | D7 |
| `IdleTracker` | `RefCounted` | `src/puzzles/framework/idle_tracker.gd` | D8 |
| `HintOutcome`, `ActivationResult` | constants | `src/puzzles/framework/` | D9, D2 |
| `PuzzleFramework` public API: `configurar`, `configuration_failed`, `list_puzzles`, `get_hints`, `request_hint`, `get_view_gate`, `as_view_gate_provider` | `Node` | `src/puzzles/framework/puzzle_framework.gd` | D9, D12, D13, D15 |
| `PuzzleDataRules` | `FileRules` (ADR-0005) | `src/puzzles/data/puzzle_data_rules.gd` | D13 |

### Implementation Guidelines

1. Controllers **must** extend `PuzzleController` and **must never** reference
   `PuzzleFramework`, `GameState`, `FactWriter`, the bus, another controller or
   `InteractionSystem` (ADR-0009 D7; CI `list_puzzle_cross_refs.sh`).
2. `evaluate()` **must** be pure: no clock reads, no member writes, no signals.
   T-U3 calls it twice and compares.
3. Only `PuzzleFramework` **may** call `evaluate()`, and only from a
   `ValidationPolicy` path or the D5.1 recompute.
4. Every state-changing path **must** end in `policy.on_change(rt)` (rule 12b).
5. All framework timing **must** use `PuzzleTimers`/`GameClock`; `Timer`,
   `create_timer`, `await` on tree timers **must never** appear in `src/puzzles/`.
6. Writes **must** precede notices and follow D5.3 order exactly.
7. Events during a lock **must** be dropped, never queued.
8. `request_hint` re-application **must never** call `evaluate()` or apply
   `AUTO_SOLVE_ELEMENT`, and **must never** emit `hint_applied`.
9. 9 **must never** present `TEXT` hint effects; it forwards `text_key`.
10. Typed overrides **must** `return` explicitly (4.7). Abstract classes use the
    two-line `@abstract` / `class_name` form.
11. Integer data fields **must** reach controllers already converted to `int`
    (ADR-0005 D4); controllers **must never** re-parse JSON.

## Alternatives Considered

### Alternative 1: Fat controllers (each puzzle owns its timers, writes and notices)
- **Description**: `PuzzleController` gets a `FactWriter` and the bus; the framework only routes input.
- **Pros**: Fewer framework concepts; each GDD reads end-to-end in one file.
- **Cons**: Failure policy, S9 and rule-16 order implemented six times; breaks ADR-0009 D7 and GDD 9 rule 10; oracle test cannot be shared.
- **Estimated Effort**: Lower up front, higher overall (×6 tests).
- **Rejection Reason**: Contradicts rule 10 and the "check the failure policy once" goal.

### Alternative 2: Data-only puzzles interpreted by a generic engine (no controller classes)
- **Description**: Describe permutations, angles, cards in JSON; one interpreter.
- **Pros**: Adding puzzles is data-only.
- **Cons**: Six heterogeneous mechanics would need a DSL; presentation is bespoke anyway.
- **Estimated Effort**: Much higher.
- **Rejection Reason**: Over-engineering for six puzzles; GDD 9 rule 3 already chose data + controller.

### Alternative 3: Policies as a `match` inside the framework (no strategy objects)
- **Description**: One `_on_change` with a `match policy` block.
- **Pros**: One file, no extra classes.
- **Cons**: Transient state of five policies mixed in the runtime; harder isolated tests.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Strategy objects give one unit test file per policy and a typed `admits()` table.

### Alternative 4: Keep `Verdict.payload: Dictionary` (architecture.md draft)
- **Pros**: No new fields when a puzzle needs new data.
- **Cons**: `PARTIAL{element, action}` and `progress` untyped; typos fail silently.
- **Rejection Reason**: Typed fields are checkable; `payload` kept only for `value_from` sources.

### Alternative 5: `request_hint -> bool` with a separate `reapply_hint()`
- **Pros**: Keeps the draft signature.
- **Cons**: 17 already calls `request_hint(id, last_applied)` for «Repetir» (R13) and needs "ya está a la vista".
- **Rejection Reason**: One call with a 4-value outcome serves 17 without a second method.

## Consequences

### Positive
- Rule 16 order, S1–S9 and the failure policy are tested once with fake controllers.
- Controllers are small, pure and unit-testable without a scene tree.
- Every 14/17/11 change request is absorbed without new facts.
- Pause correctness by construction (`GameClock.delta()` = 0).

### Negative
- More framework classes (runtime, 5 policies, timers, idle, commit helper).
- Five virtual hooks beyond the 13 abstract methods (`replay_hint_effect`, `is_condition_met`, `on_setting_changed`, `prepare_resume`, `persist_values`).
- `HintOutcome` changes 17's `true/false` checks.
- An exemption to ADR-0009 D3 rule 5 (D12).

### Neutral
- Controllers are scene children of the framework; their scenes are authored inside `planta`.

## Risks

- **R1 `@abstract` form differences on 4.7.2** (one-line vs two-line). Mitigation: two-line form; V1 parse check in S0.
- **R2 Same-frame ordering of 7's `inicio`/`fin`** for P6 `commit_on`. Mitigation: `ChoiceCommit` is order-driven; T-U9 feeds both in one frame.
- **R3 PER_ELEMENT completion tags drift between 13/14 and 9.** Mitigation: tags are constants in `PerElementPolicy`; T-I3 asserts each.
- **R4 Box adapter called before Box configured** (D12). Mitigation: T-I5 configures 9 before 10 with `caja_c1` true and checks one final pose, no sound.
- **R5 Dev-console reconciliation misdetects own writes.** Mitigation: pending-write set cleared after the drain (`run_after_drain`); T-U12.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| marco-de-puzles.md (9) | TR-puzzles-007 states, monotony, S9 | D1 runtime, D5 guards, D12 monotony |
| marco-de-puzles.md (9) | TR-puzzles-008/-009 abstract controller, pure `evaluate`, `Verdict`, sole writer | D2, D3, D5.3 |
| marco-de-puzles.md (9) | TR-puzzles-010 five policies, rule 12b | D4 |
| marco-de-puzles.md (9) | TR-puzzles-011 resolution order | D5.3 |
| marco-de-puzles.md (9) | TR-puzzles-012/-013 deferred, `LINE` steps | D5.4 |
| marco-de-puzles.md (9) | TR-puzzles-014 injectable `GameClock` | D6 |
| marco-de-puzles.md (9) | TR-puzzles-015/-016 configuration, persistence by facts | D12 |
| marco-de-puzles.md (9) | TR-puzzles-017 receivers/handlers, `get_view_gate` | D7, D15 |
| marco-de-puzles.md (9) | TR-puzzles-018 failure policy | D5.2 |
| marco-de-puzles.md (9) | TR-puzzles-019 hint API, idle | D8, D9 |
| marco-de-puzles.md (9) | TR-puzzles-020 notices | D14 |
| marco-de-puzles.md (9) | TR-puzzles-021 oracle | § Validation T-I6 |
| marco-de-puzles.md (9) | TR-puzzles-022 playtest log, accessibility settings | D16, D2 `on_setting_changed` |
| puzle-1-cronologia.md (11) | TR-puzzle1-003, -004, -006, -007, -009, -012, -015, -016; `atraccion_desactivada` zone (D11-17) | D2, D3 admits, D4 delayed, D10, D15, D5.3, D9 |
| puzle-2-memorando-en-el-cristal.md (12) | TR-puzzle2-003, -005, -010, -014, -016 | D12 persist, D4 ON_CHANGE, D5.3, D9 |
| puzle-3-encaje-de-la-foto.md (13) | TR-puzzle3-003, -007, -008, -010, -012, -015, -016 | D4 PER_ELEMENT, D5.2 `ELEMENT` lock, D7 cancel, D8 `GESTURE_AND_MOVE` + condition re-emission, D9 |
| puzle-4-tablero-de-tareas.md (14) | TR-puzzle4-004, -005, -006 (`PARTIAL{element, action}`), -010, -012, -013, -014, -017 | D3, D5.1, D5.3 `value_from`/`map`, D5 S9 |
| puzle-5-espejo-de-la-diferencia.md (15) | TR-puzzle5-002, -007, -009, -013, -014 | D3 SUSTAINED admits, D4, D5.4 |
| puzle-6-decision.md (16) | TR-puzzle6-002, -005, -006, -007, -011, -012 | D7 `commit_on`, D5 S9, D5.3, D8 `PRESS_ONLY`, D9 |
| caja-y-compartimentos.md (10) | TR-box-001 availability only via `get_view_gate` | D15, D12 exemption |
| sistema-de-pistas.md (17) | TR-hints-006, -007 (`first_action`, list fields), -013 (re-application), -014 (auto-apply false, idle re-emission) | D8, D9 |

## Performance Implications
- **CPU**: per frame, idle polling of ≤1 engaged puzzle and, for P5 engaged, one `evaluate()`; event-driven otherwise. Target < 0.05 ms/frame (record in S0).
- **Memory**: six runtimes + controllers' own nodes; framework state < 50 KB.
- **Load Time**: tier-L validation of `puzzles.json` (ADR-0005 budget) plus six `configure()` calls; no I/O beyond ADR-0005's reader.
- **Network**: N/A.

## Migration Plan

No existing code. `architecture.md` § API Boundaries "Marco de puzles (9)"
block is superseded by D2/D3/D9/D15 (update in `/architecture-review`).

**Rollback plan**: policies and `Verdict` are internal to 9; reverting to the
`Dictionary` verdict or to `request_hint -> bool` touches only 9, the
controllers' `evaluate()` bodies and 17's call site.

## Validation Criteria

Tests (gdUnit4; framework tests use fake controllers, a real `GameClock`
driven by `advance()` with `NullPauseBackend`, a `RecordingFactWriter` ‡ and a
recording bus double from ADR-0009 D9):

| ID | File | Asserts | Covers |
|---|---|---|---|
| T-U1 | `tests/unit/puzzles/puzzle_controller_contract_test.gd` | each P1–P6 script overrides all 13 abstract methods; instantiating the base fails (record parse vs run time) | D2, V3 |
| T-U2 | `tests/unit/puzzles/verdict_test.gd` | factories, immutability of `progress` copy | D3 |
| T-U3 | `tests/unit/puzzles/evaluate_purity_test.gd` | two calls → equal verdicts; no signal; no clock read (clock spy) | D2 rule 2 |
| T-U4 | `tests/unit/puzzles/policies/delayed_after_change_test.gd` | F1 example (10.00 → 10.40 → 11.00), cancel on close, re-arm | D4 |
| T-U5 | `…/sustained_test.gd` | 47 frames no, 48 yes at 1/60; dt 0.5 clamps to 0.1; acum reset on NONE/close/cancel; controller SOLVED inadmissible | D4, F2 |
| T-U6 | `…/on_change_test.gd`, `per_element_test.gd`, `on_choice_test.gd` | evaluation moments; admissibility table | D3, D4 |
| T-U7 | `tests/unit/puzzles/verdict_pipeline_test.gd` | partial edge (rise, fall silent, re-rise), `stamp_text_keys` by action, reject lock drop-not-queue, `lock_max_s`, S9 second SOLVED same frame dropped | D5 |
| T-U8 | `tests/unit/puzzles/commit_order_test.gd` | P4/P6 write order, `value_from`+`map`, notices after writes, no `compartment_completed` for P1/P2 | D5.3 |
| T-U9 | `tests/unit/puzzles/choice_commit_test.gd` | both modes; `fin` on another element; `cancelación`; same-frame `inicio`+`fin` | D7 |
| T-U10 | `tests/unit/puzzles/idle_tracker_test.gd` | three `idle_reset` modes; F3 P6 example (move at 15 s ignored); P3 condition false at 60 s, re-emission on grab; pause freezes | D8 |
| T-U11 | `tests/unit/puzzles/request_hint_test.gd` | REFUSED in RESOLVING; APPLIED emits `hint_applied{text_key}`; REAPPLIED no evaluate, no AUTO_SOLVE, no notice; ALREADY_VISIBLE; P4 level 3 with T2–T4 → SOLVED; `first_action_s` | D9 |
| T-U12 | `tests/unit/puzzles/reconstruction_test.gd` | solved → restore, no notices/sounds; resume flag on solved cleared silently; P5 pending kept; dev reconciliation silent | D12 |
| T-U13 | `tests/unit/puzzles/element_zones_test.gd` | P1 `ref_*` attraction false, slots true | D10 |
| T-U14 | `tests/unit/puzzles/data/puzzle_data_rules_test.gd` | each D13 addition and rule-29 check → issue with `json_path` | D13 |
| T-I1 | `tests/integration/puzzles/planta_configure_test.gd` | `puzzles_configured` once before `scene_ready`; ON_CHANGE re-eval after ready; invalid data → `INVALID_PUZZLE_DATA`, nothing registered | D12, D13 |
| T-I2 | `tests/integration/puzzles/deferred_p5_test.gd` | 16.0 s with/without audio; interrupt on close emits notice, writes nothing; resume replays | D5.4 |
| T-I3 | `tests/integration/puzzles/per_element_tags_test.gd` | P3/P4 completion tags trigger evaluation | R3 |
| T-I4 | `tests/integration/puzzles/hints_17_contract_test.gd` | 17 + 9 with auto-apply false; P3 re-emission path | D8, D9 |
| T-I5 | `tests/integration/puzzles/box_restore_order_test.gd` | 9 before 10, `set_final_pose` once, silent | D12, R4 |
| T-I6 | `tests/integration/puzzles/solvability_oracle_test.gd` | `N_fuzz` = 1000 seeded-deterministic sequences per puzzle through `handle_pointer → evaluate → framework` | TR-puzzles-021 |

Engine verifications (S0, record in `docs/engine-reference/godot/`):
V1 one-line `@abstract class_name` parses on 4.7.2; V2 an override missing
`return` on `-> Verdict` errors as documented; V3 base instantiation error
timing; V4 `Array[StringName]` field default per instance (no shared default);
V5 static factory on a `class_name` `RefCounted` callable from another script.

We'll know this was right if: the six controllers each stay under ~400 lines
with no timer code, T-U7/T-U8 catch an injected order bug, and no story needs
a new fact or a framework special case per puzzle.

## Open Items

| ID | Item | Owner / route |
|---|---|---|
| OI-1 | **Applied 2026-11-10: `SceneServices.puzzle_writer` in ADR-0009 D3 (also C4 rule-5 exemption and C6 note in ADR-0003).** How `FactWriter(9)` reaches 9: `ServiceContext` has no writer field; `GameState.writer_for(9)` is "composition only" (ADR-0001) — propose `SceneServices.puzzle_writer` built by the scene root | ADR-0009 amendment |
| OI-2 | `ViewReceiver` is `@abstract … extends Node` in `architecture.md`; this ADR needs a `RefCounted` port (adapter) or a child-node adapter | ADR-0011 |
| OI-3 | PER_ELEMENT completion tags (`PIECE_DROPPED`, `CARD_COMPLETED`, `CARD_RETURNED`) ‡ | stories of 13/14 |
| OI-4 | `SurfaceFx` operation for world `HIGHLIGHT` (`V08`, `B0x`, `B08`) | ADR-0015 |
| OI-5 | Field names of `ViewElement`/`PointerEvent` in English vs GDD Spanish keys | ADR-0011 |
| OI-6 | Field lists of `puzzles.json` keys added here (`idle_hints_auto_apply` placement) for ADR-0005 registry (reconciliation row 28) | ADR-0005 / `/architecture-review` |
| OI-7 | Folder slugs `p<N>_<slug>` | lead-programmer |

### Contradictions detected (for `/architecture-review`)

| # | Between | Resolution here | Change required |
|---|---|---|---|
| C1 | GDD 9 rule 9 (P1 refs attract) vs GDD 11 D11-17 | Zone override wins (D10) | GDD 9 rule 9 text |
| C2 | GDD 9 rule 9/13 `PARTIAL(progress)` vs GDD 14 `{element, action}` | Both: `progress` + optional `element`/`action` (D3) | GDD 9 rules 9, 13; `architecture.md` |
| C3 | `architecture.md`/GDD 17 R11 `request_hint -> bool` | `-> int` `HintOutcome` (D9) | GDD 17 R11.4/R13 (`!= REFUSED`), `architecture.md` |
| C4 | ADR-0009 D3 rule 5 vs restore at configure calling `BoxPresenter` | Exemption (D12) | ADR-0009 D3 rule 5 |
| C5 | GDD 9 rule 7 `missing_items: bool` vs ADR-0009 D5 `Array[StringName]` | List (D15) | GDD 9 rule 7 |
| C6 | ADR-0003 `configure_all -> ConfigureResult` vs ADR-0009 `configurar -> void` | `configuration_failed()` query (D13) | ADR-0003 pseudocode note |
| C7 | GDD 17 R13 "reaplica los efectos (… nota)" vs 17 change (3) "no emite «pista aplicada» nueva" | No notice; 17 shows its own note (D9 step 2) | GDD 17 R13 wording |
| C8 | GDD 9 rule 26 `idle_hints_auto_apply` default true vs 17 (false in data) | Data value false in slice; behaviour supports both (D8) | GDD 9 Tuning Knobs |
| C9 | 13 abstract methods (TR-puzzles-008) vs 5 virtual hooks added | Hooks have defaults; TR list unchanged | TR-puzzles-008 note |
| C10 | GDD 9 rule 7 / R30 ("9 draws the sheet with `compose_i01()`") vs ADR-0009 D7 (`composer` in P1's services) | P1 controller calls it in `on_open()`; 9 owns the gate (D15) | GDD 9 rule 7, GDD 11 Dependencies |
| C11 | GDD 9 rule 14(a) "framework emits shake animation" vs rule 10/14b (presentation is the controller's) | 9 emits the sound notice; controller plays the shake via `play_resolution({call: &"reject"})` (D5.2) | GDD 9 rule 4b `presentation[].call` catalogue gains internal `reject`/`begin` (not data) |

## Related
- ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0009 (depends on)
- ADR-0011, ADR-0015, ADR-0016, ADR-0017 (enabled)
- `design/gdd/marco-de-puzles.md`, `puzle-1-cronologia.md` … `puzle-6-decision.md`, `caja-y-compartimentos.md`, `sistema-de-pistas.md`
- `docs/architecture/architecture.md` § API Boundaries (block superseded), § Required ADRs row ADR-0010
- `docs/architecture/adr-reconciliation-2026-11-10.md` (rows 28, G26)
