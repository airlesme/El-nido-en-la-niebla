# ADR-0001: Event Bus and Fact Contract

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.

## Date

2026-11-10

## Last Verified

2026-11-10 — against Godot 4.7.2 engine reference (`docs/engine-reference/godot/`,
last verified 2026-10-17) and `design/gdd/estado-y-bus-de-eventos.md` (round 10).

## Decision Makers

technical-director (autonomous batch mode, `modes.automation: autonomous`);
user approval pending at end of batch.

## Summary

System 3 (`GameState`) must hold the 20 slice facts and announce changes and
named notices to ~25 systems with a FIFO, non-reentrant, capped delivery
guarantee that Godot signals do not document; Settings (6) needs the same
semantics without depending on 3. Decision: a project-owned dispatcher,
`NoticeChannel` (plain `RefCounted`, `Callable` subscriber list, single FIFO
queue, `max_chained_notices` cap), instantiated once in `GameState` and once in
`Settings`; notice names are `StringName` constants in one registry
(`NoticeIds`), payloads are `Dictionary` validated against a per-notice schema
in debug builds, and the snapshot is `{snapshot_version, facts}` JSON-safe.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM — the decision deliberately uses only pre-cutoff GDScript core (`RefCounted`, `Callable`, `StringName`, `Dictionary`, `Array`); no post-cutoff API is load-bearing. Risk stays MEDIUM (not LOW) because several behaviours it relies on are NOT SOURCEABLE (below) and must be proven by tests on 4.7.2 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `current-best-practices.md` (GDScript 4.5+ and 4.7: variadic args, lambda capture by value, `@abstract`, typed-return overrides; gdUnit4 CLI notes); `deprecated-apis.md` (`signal.connect(callable)` replaces string `connect`; typed collections preferred); `breaking-changes.md` (4.7 typed-return overrides); `modules/input.md` (`StringName` literals `&"…"` in hot paths) |
| **Post-Cutoff APIs Used** | None load-bearing. Typed-return override rule (4.7) applies to any subclass of `LogSink`/`ErrorPolicy`: overrides need an explicit `return` (`current-best-practices.md` § GDScript 4.7). `@abstract` (4.5) is **not** used here to keep the doubles trivial |
| **Verification Required** | See "NOT SOURCEABLE" list below; each item has a gdUnit4 test in Validation Criteria (V-ENG-1…V-ENG-6) that must pass on 4.7.2 before `Accepted` |

**NOT SOURCEABLE behaviours (never filled in from memory):**

| # | Behaviour this ADR depends on | Status | Mitigation |
|---|---|---|---|
| NS-1 | Whether `Callable.is_valid()` returns `false` (without error) once the bound object has been freed with its scene (CA-17) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | V-ENG-1; fallback: store `get_object()` + `is_instance_valid()` (also NOT SOURCEABLE, same test), or require owners to unsubscribe in `_exit_tree` |
| NS-2 | Cost and allocation of `Dictionary` lookup by `StringName` key and of returning a `Variant` from it (TR-state-002, "constant cost, no allocation") | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | V-ENG-2 perf test; the indexed read path (`resolve_fact` + `get_fact_at`) exists so the hot path does not depend on NS-2 |
| NS-3 | How `JSON.parse_string` / `JSON.parse` types integral numbers (`2` → `int` or `float`) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (GDD 3 OQ 8, GDD 5 AC-30c) | Restore accepts both (`2` and `2.0`), rule 13; V-ENG-3 round-trip test |
| NS-4 | Which call stops execution in a debug build and is a no-op in a release export (`assert`, `OS.is_debug_build()`, `push_error`) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | All "dev halts / release logs" goes through an injected `ErrorPolicy`; its production implementation is chosen by a spike (V-ENG-4) and is the only file that names those APIs |
| NS-5 | Delivery order and reentrancy of Godot `signal.emit()` with several connections (connection order? synchronous re-entry?) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | Not relied upon: the bus does its own dispatch. Contract signals (§ Signal policy) must not assume an order between two receivers |
| NS-6 | Whether non-ASCII identifiers (`cola_vacía`) parse in GDScript 4.7 | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | Code identifiers are ASCII English (`is_queue_empty`); the GDD name is kept in the mapping table |
| NS-7 | Main-loop order between `_input`, `_physics_process`, `_process` of different nodes | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (also stated in `architecture.md` § Data Flow) | Same-frame guarantees come from synchronous drain, never from callback order |
| NS-8 | Whether a runtime script error inside a `Callable.call()` aborts only the callee or also the caller's loop (GDScript has no exceptions) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | V-ENG-5; RK-6 |
| NS-9 | Iterating an `Array` while it is appended to inside the loop | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | Not relied upon: the drain iterates by index with a bound fixed before the loop |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (Foundation; can be implemented first) |
| **Related (non-blocking)** | ADR-0002 Pause and game time — the bus is `process_mode` `ALWAYS` and never reads `GameClock`; pause notices `pause_opened`/`pause_closed` travel on it. ADR-0009 Service composition — decides how `GameState`, `Settings`, `FactWriter` and `NoticeChannel` reach systems via `ServiceContext`; this ADR fixes the types it injects |
| **Enables** | ADR-0003 (scene loading: `scene_load_*` notices, silent-write window), ADR-0004 (save: snapshot format, `is_queue_empty`, `state_restored`, `notices_dropped`), ADR-0005 (data schema: `flags.json` schema, `max_chained_notices`), ADR-0006 (input notices), ADR-0007 (Settings reuses `NoticeChannel`), ADR-0008 (audio payloads `line_requested`/`sound_requested`/`line_*`); also ADR-0010, -0011, -0017 for their notice payloads |
| **Blocks** | Every story that reads/writes a fact or emits/consumes a notice: epics for systems 3, 4, 5, 6, 7, 8, 9, 19, 20, 21, 22, 23, 25, 26, 28 |
| **Ordering Note** | Write order 0001 → 0002 → 0009 → 0003 (`architecture.md` § Required ADRs). 0004–0008 must cite the names and payload keys in § Notice Name Registry, not re-declare them. Payload schemas marked ‡ (21's three notices) are placeholders until ADR-0017 |

## Context

### Problem Statement

GDD 3 (`estado-y-bus-de-eventos.md`) fixes the *contract* of the shared memory
of the slice — 20 typed facts with a single writer each, one derived fact
(`caja_completa`), automatic change notices, ~45 named notices from 15 emitters
(rule 10) — and explicitly leaves to an ADR: the technical format of notices
(rule 10, TR-state-012), the snapshot format and `max_chained_notices` (OQ 2),
the `owner` mechanism (OQ 3), the injectable log sink (OQ 7) and the method
signatures (`architecture.md` QQ-15). It also requires Settings (6), which must
not depend on 3, to share "one single mechanism" with the bus (rule 10 "Fuera
del bus", GDD 6 rule 7, TR-settings-005/-006). Every Feature system and the
save system are blocked until the names, payloads and API exist, so this is the
first ADR (`architecture.md` § Required ADRs, row ADR-0001). It must also record
the contract chosen for «interacción ejecutada» (QQ-09).

### Current State

No code and no ADR exist (`architecture.md` § ADR Audit: 0 of 609 TR covered).
`architecture.md` § API Boundaries "Bus y estado (3)" proposes ‡ signatures and
the shared `NoticeChannel` class; this ADR confirms or replaces each one.

### Constraints

- **Delivery semantics are fixed by the GDD**, not negotiable here: value
  applied at write time even during a delivery (rule 3); notice only on real
  change (rule 9); FIFO by occurrence and by subscription order; no reentrancy:
  notices raised during a delivery are queued (rule 11); unsubscribe during a
  delivery takes effect when that delivery ends (rule 9, CA-16); new game /
  restore requested during a delivery applies when it ends (rule 11, CA-13b);
  freed subscribers do not error (CA-17).
- **Hot read path:** system 7 reads arbitrary facts for ~35 objects every
  physics step (60 Hz) — constant cost, no allocation (TR-state-002, Game Feel).
- **Dev vs release:** invalid writes halt in dev and are ignored with one log
  line in release (rule 6); `owner` checked only in dev (rule 2, TR-state-005).
  How a GDScript build tells the two apart is NS-4.
- **Testability:** every public method unit-testable with gdUnit4 without a
  scene tree (`coding-standards.md`); log destination replaceable by tests
  (rule 15, OQ 7); autoloads only named from composition points (`architecture.md`
  § Module Ownership, "Regla de uso").
- **Threads:** main thread only (`architecture.md` § Data Flow 6).
- **Language/naming:** code identifiers in English ASCII; GDD IDs (`caja_c1`,
  `EV_PUZZLE_SOLVED_P1`, payload keys such as `D_carga`, `line_id`) kept
  literally (project `CLAUDE.md`).
- **Engine knowledge:** post-cutoff engine; anything not in
  `docs/engine-reference/godot/` is NOT SOURCEABLE (table above).

### Requirements

- R1. Read a fact by name at any time in `LISTO`; O(1), allocation-free hot path.
- R2. Validated write with type/range/declared/derived/one-way checks, dev-only
  `owner` check, release: ignore + one log line.
- R3. Derived facts recomputed on every input change; derived notice delivered
  after its input's notice.
- R4. Three subscription kinds: one fact, all fact changes, one named notice;
  filtering done by the bus.
- R5. One FIFO queue for fact changes and named notices; no reentrancy; cap
  `max_chained_notices` (data, 8–256) → drop rest + log + dev halt + emit
  «avisos descartados».
- R6. Snapshot (sync, never waits, "unavailable" with pending queue), restore
  (sync, atomic, single «estado restaurado»), new game (single «estado
  restablecido»), `snapshot_version` query, `cola_vacía()` query.
- R7. Silent repair write: owner only, reversible facts only, only between
  «carga de escena iniciada» and «escena lista»/«carga de escena fallida»; no
  notice.
- R8. Same delivery semantics reusable by Settings (6) without depending on 3.
- R9. Closed, documented set of notice names with payload contracts (rule 10);
  an undeclared emitter/name is detectable in dev.
- R10. Dev console hooks (rule 15) and injectable log sink.

## Decision

**D1 — Own dispatcher, not Godot signals.** Notices (fact changes and named
notices) are delivered by a project class `NoticeChannel` (`RefCounted`, no
scene-tree dependency) holding an ordered subscriber list of `Callable`s and one
FIFO queue. Godot `signal`s are not used for any notice in the GDD 3 rule 10
table, because the GDD guarantees (FIFO across emitters, no reentrancy, cap,
deferred unsubscribe, deferred reset/restore) are not documented for signals
(NS-5) and would have to be rebuilt around them anyway.

**D2 — One class, two instances (TR-state-012).** `GameState` (autoload, system
3) owns one `NoticeChannel`; `Settings` (autoload, system 6) owns another. The
class has no knowledge of facts or settings, so 6 does not depend on 3. Both
channels read their cap from their own data (`flags.json` for 3; ADR-0007
decides 6's key, default the same 64). The two queues are independent: a Settings
notice never waits for a GameState drain and vice versa.

**D3 — Notice names are `StringName` constants in a closed registry.** A single
script `NoticeIds` (`src/core/notice_ids.gd`, `class_name NoticeIds`) declares
one `const` per notice (§ Notice Name Registry). Where a GDD already fixes a
code name it is used literally (`pause_opened`, `pause_closed`,
`EV_PUZZLE_SOLVED_P1`…`P6`); every other Spanish GDD name maps to one English
snake_case `StringName`. Emitting a name absent from the registry is an invalid
call (dev: halt via `ErrorPolicy`; release: dropped + one log line). Fact names
are the `flags.json` names (`&"caja_c1"`), case-sensitive.

**D4 — Typed payloads = `Dictionary` + per-notice schema checked in debug.**
Payloads are `Dictionary` with `StringName` keys equal to the GDD data names
(`&"destino"`, `&"D_carga"`, `&"line_id"`…). `NoticeIds.SCHEMA` declares for each
notice its keys, their `Variant.Type` and whether optional. In debug builds the
channel validates every `notify` against it (missing required key, unknown key,
wrong type → `ErrorPolicy`); release builds skip the check. Consumers read
payloads through typed accessor helpers where one is provided (e.g.
`InteractionNotice.is_done(payload) -> bool`). Fact-change delivery has no
payload dictionary: `cb(fact: StringName, old: Variant, new: Variant)`.

**D5 — Single FIFO queue, synchronous drain, per-drain cap.** `notify()` and
every real fact change *enqueue* an entry. If the channel is not already
draining, the call drains synchronously before returning; if it is draining
(the caller is a subscriber), the entry waits in the queue — that is the "no
reentrancy" of rule 11. One *drain* is the unit the cap bounds:
`max_chained_notices` = 64 (data; safe 8–256) entries delivered per drain. When
entry 65 would be delivered: the remaining queue is discarded, one log line is
written, `ErrorPolicy.fail` runs (dev halt), and `notices_dropped` («avisos
descartados») is delivered once. Entries enqueued while delivering
`notices_dropped` get a fresh budget; a second overflow in the same drain drops
silently (log only, no second `notices_dropped`). Because the drain is
synchronous, a chain can never span frames, so "per frame" (GDD 3 Edge Cases)
and "per drain" are the same bound for any chain; independent drains in one
frame each have their own budget (recorded in Open Items OI-3).

**D6 — Subscription model.** One ordered list per channel; each subscription is
`{handle: int, kind, topic: StringName, cb: Callable, active: bool}` with
`kind ∈ {FACT, ALL_FACTS, NOTICE}`. Delivery walks the list in subscription order
and filters by kind/topic (filtering in the bus, rule 9). Subscribe during a
drain: effective from the next entry. Unsubscribe during a drain: the
subscription is marked for removal and removed after the current entry has been
delivered to everyone (CA-16). Before calling, the channel checks
`cb.is_valid()` (NS-1); an invalid callable is skipped silently and pruned at
drain end (CA-17).

**D7 — Writer identity by capability (GDD 3 OQ 3).** `flags.json` stores
`owner` as the GDD system number (`9`, `19`, `20`, `22`, `3`). The composition
root (ADR-0009) gives each writer system a `FactWriter` bound to its number
(`GameState.writer_for(9)`); systems never pass their own number. Release builds
skip the owner comparison but still run all other rule 6 checks.

**D8 — Snapshot format.** `{"snapshot_version": 1, "facts": {<fact>: <value>}}`
with exactly the 20 declared facts (derived included, CA-24), `bool` as JSON
bool, `int` as JSON number, enum as `String` or `null` for "sin fijar". Keys are
`String` (JSON-safe). § Snapshot Format.

**D9 — Silent-write window via internal tap at enqueue.** `GameState` watches
its own channel for `scene_load_started` (opens), `scene_ready` and
`scene_load_failed` (close) **at the moment they are enqueued** (a channel
"tap", not an ordinary subscriber), so the window state never depends on the
position of 3 in the subscriber list or on queue latency. This implements GDD 3
rule 16(a) "3 se suscribe…" with a strictly earlier observation point; the
observable contract is identical.

**D10 — Signal policy (contract signals).** Godot signals are allowed only (a)
inside one system, or (b) from a provider to its direct consumer one sublayer
above when a GDD names the signal: Player (2) `paso`, `gesto_terminado`,
`camara_cedida` → 7, 8, 20, 23; puzzle controller `elements_changed(tag)` → 9;
`GameClock.paused_changed` (ADR-0002). They are **forbidden** between peers and
for anything listed in GDD 3 rule 10. A contract signal must not carry a fact
change and must not assume an order between two receivers (NS-5). Engine node
signals (`body_entered`, `finished`, `timeout`) stay internal to the system that
owns the node.

**D11 — «interacción ejecutada» (QQ-09): one notice, filtered by `HECHO`.**
`interaction_executed {id: StringName, verbo: StringName, resultado: StringName}`
with `resultado ∈ {&"HECHO", &"SIN_EFECTO", &"GESTO_RECHAZADO", &"TOQUE_CORTO"}`,
emitted by 7 once per processed press (GDD 7 rule 29, D7-74; GDD 24 D24-9).
24 consumes every value; every other consumer **must** filter
`InteractionNotice.is_done(payload)` (`resultado == &"HECHO"`). No separate
«interacción rechazada» notice. The bus cannot verify that a consumer filters,
so the filter is a review rule in the control manifest (§ Implementation
Guidelines G-12) plus one integration test per consumer (V-INT-3).

### Architecture Diagram

```text
             writers (FactWriter bound to owner 9 / 19 / 20 / 22)
                     │ write(fact, v)              ┌──────────── composition (ADR-0009)
                     ▼                              │  writer_for(n), ServiceContext
 ┌──────────────────────── GameState (autoload, system 3) ───────────────────────┐
 │ FactCatalog (flags.json) ─► values[] (indexed) ─► derived recompute            │
 │        │ validate: declared · type · range · derived · one-way · owner(dev)    │
 │        ▼ real change only                                                     │
 │   NoticeChannel #1 ──────────────────────────────────────────────────────┐    │
 │   │ tap@enqueue: scene_load_started/ready/failed → silent-write window   │    │
 │   │ queue FIFO [FACT_CHANGE | NOTICE] ── drain (sync, cap 64) ──► subs   │    │
 │   │ deferred: reset / restore after drain                               │    │
 │   └────────────────────────────────────────────────────────────────────┘    │
 │ snapshot() / restore() / reset_new_game() / is_queue_empty()                  │
 └───────────────────────────────────────────────────────────────────────────────┘
        ▲ notify(NoticeIds.X, payload)                 │ cb(fact, old, new) / cb(payload)
   emitters 1,4,5,7,8,9,21,22,23,25                     ▼ subscribers (ordered)
                                                     5, 8, 9, 17, 21, 23, 24, 26, 27, 28 …

 ┌──── Settings (autoload, system 6) ────┐   same NoticeChannel class, own instance,
 │  values · NoticeChannel #2            │   own cap; no reference to GameState
 └───────────────────────────────────────┘
 LogSink and ErrorPolicy injected into both (tests use recording doubles)
```

### Key Interfaces

Typed GDScript pseudocode. **"proposed signature"** = no GDD signs it; this ADR
fixes it (QQ-15). GDD operation names in the right-hand comment.

```gdscript
# ─── src/core/notice_channel.gd ─────────────────────────────────────────────
class_name NoticeChannel extends RefCounted
## Ordered, FIFO, non-reentrant dispatcher shared by GameState (3) and Settings (6).

enum Kind { FACT, ALL_FACTS, NOTICE }

func _init(max_chained: int, log_sink: LogSink, errors: ErrorPolicy,
		schema: Dictionary = {}) -> void: pass              # proposed signature
## Subscribe to one topic (fact name or notice name) or ALL_FACTS (topic ignored).
## Returns a handle > 0. Effective from the next delivered entry.
func subscribe(kind: Kind, topic: StringName, cb: Callable) -> int: return 0   # proposed
## Effective after the entry currently being delivered (CA-16). Unknown handle: no-op.
func unsubscribe(handle: int) -> void: pass                                     # proposed
## Enqueue a fact change; drains now unless already draining.
func push_change(fact: StringName, old: Variant, new: Variant) -> void: pass    # proposed
## Enqueue a named notice (validated against schema in debug); drains now unless draining.
func notify(notice: StringName, payload: Dictionary = {}) -> void: pass         # proposed
func is_queue_empty() -> bool: return true          # GDD: cola_vacía()
func is_draining() -> bool: return false            # proposed
## Discard pending entries (used by reset/restore). Does not notify.
func clear_pending() -> void: pass                  # proposed
## Run `job` once the current drain ends (immediately if idle).
func run_after_drain(job: Callable) -> void: pass   # proposed
## Observe notices at enqueue time (GameState window). Not a subscriber.
func set_enqueue_tap(tap: Callable) -> void: pass   # proposed

# ─── src/core/game_state.gd  (autoload `GameState`, process_mode ALWAYS) ─────
class_name GameState extends Node
## Facts + bus of system 3. Only composition points name the autoload.

enum Status { UNLOADED, READY, RESTORING }             # Sin cargar / Listo / Restaurando
const SNAPSHOT_VERSION: int = 1

## Load and validate flags.json. Error -> FatalErrorHandler (CA-26). Called by Boot.
func load_catalog(path: String) -> Error: return OK                 # proposed
func get_status() -> Status: return Status.READY                     # proposed
func get_snapshot_version() -> int: return SNAPSHOT_VERSION          # GDD: snapshot_version (read-only)

# Reads (any system)                                                   # GDD: lectura de hecho
func get_fact(fact: StringName) -> Variant: return null              # proposed; O(1) dict lookup
func resolve_fact(fact: StringName) -> int: return -1                # proposed; index, -1 if undeclared
func get_fact_at(index: int) -> Variant: return null                 # proposed; hot path (7, habilitado_si)
func is_declared(fact: StringName) -> bool: return false             # proposed

# Writes (only through FactWriter in production code)                  # GDD: escritura validada
func writer_for(owner_id: int) -> FactWriter: return null            # proposed; composition only
func set_fact(fact: StringName, value: Variant, owner_id: int) -> bool: return false   # proposed
func write_silent(fact: StringName, value: Variant, owner_id: int) -> bool: return false # GDD: escribir_silencioso

# Snapshot / lifecycle (5)
func is_queue_empty() -> bool: return true                           # GDD: cola_vacía()
## True while the channel is inside a synchronous drain. Wrapper over NoticeChannel (ADR-0004 OI-1).
func is_draining() -> bool: return false
## Run `job` once, when the current synchronous drain ends (same logical frame,
## before further input); immediately if idle. Used by 5 for the seal capture
## and `request_save` deferral. Wrapper over NoticeChannel (ADR-0004 OI-1).
func run_after_drain(job: Callable) -> void: pass
## {} = "no disponible" (pending notices). Never waits.
func request_snapshot() -> Dictionary: return {}                     # GDD: petición de instantánea
## Sync + atomic. Inside a drain: deferred to drain end (rule 11).
func restore(snapshot: Dictionary) -> void: pass                     # GDD: restaurar
## All facts to initial; single state_reset. Inside a drain: deferred.
func reset_new_game() -> void: pass                                  # GDD: partida nueva

# Subscriptions (thin wrappers over the channel)
func subscribe_fact(fact: StringName, cb: Callable) -> int: return 0     # cb(fact, old, new)
func subscribe_all_facts(cb: Callable) -> int: return 0                  # cb(fact, old, new)
func subscribe_notice(notice: StringName, cb: Callable) -> int: return 0 # cb(payload: Dictionary)
func unsubscribe(handle: int) -> void: pass
func notify(notice: StringName, payload: Dictionary = {}) -> void: pass  # GDD: aviso con nombre

# Dev console (rule 15). Compiled out of the demo by ADR-0018; CA-29 checks.
func dev_force(fact: StringName, value: Variant) -> void: pass       # proposed

# ─── src/core/fact_writer.gd ────────────────────────────────────────────────
class_name FactWriter extends RefCounted
## Capability handed by the composition root to systems 9, 19, 20, 22.
func _init(state: GameState, owner_id: int) -> void: pass
func write(fact: StringName, value: Variant) -> bool: return false          # -> set_fact
func write_silent(fact: StringName, value: Variant) -> bool: return false   # -> GameState.write_silent

# ─── injectable seams (OQ 7, NS-4) ──────────────────────────────────────────
class_name LogSink extends RefCounted
func line(level: StringName, msg: String) -> void: pass     # &"info" | &"warn" | &"error"
class_name ErrorPolicy extends RefCounted
## Dev: stop execution (implementation chosen by spike V-ENG-4). Release: no-op.
func fail(msg: String) -> void: pass
func is_strict() -> bool: return false                      # true in dev builds
```

Read API contract: `get_fact` returns `bool`/`int`/`StringName` (enum; `&""` =
"sin fijar"). Undeclared fact or `UNLOADED`: dev → `ErrorPolicy.fail`; release →
neutral value of the type (`false`, `0`, `&""`; an undeclared name has no type
and returns `false`) plus one log line (CA-27). Write returns `true` only
when the value was accepted (changed or identical); `false` on rejection.

Callback signatures (fixed by this ADR):

| Subscription | Callback |
|---|---|
| `subscribe_fact`, `subscribe_all_facts` | `func(fact: StringName, old: Variant, new: Variant) -> void` |
| `subscribe_notice` | `func(payload: Dictionary) -> void` (empty dict when the notice has no data) |
| Settings `subscribe_change` (ADR-0007) | `func(key: StringName, old: Variant, new: Variant) -> void` (`controles`: `old`/`new` are `null`, re-read) |

A lambda used as a callback must declare all parameters (or `...args`):
a one-argument lambda on a three-argument call errors
(`current-best-practices.md`, lambdas). Lambdas capture locals by value; tests
use a `Dictionary`/`Array` recorder.

### Notice Name Registry

Source: GDD 3 rule 10 (round 10) plus payloads from the emitter GDDs as
recorded in `tr-baseline-provisional.md`. `NoticeIds` holds exactly these
constants. Key types: `SN` = `StringName`, `F` = `float`, `I` = `int`,
`A` = `Array`; `?` = optional. **‡** = the GDD names the datum but not the key,
or the payload is owned by a later ADR; the key below is a *proposed key* and
may change only through that ADR.

| GDD name | `StringName` constant | Emitter | Payload (keys literal) |
|---|---|---|---|
| (cambio de hecho, rule 9) | — channel kind `FACT` | 3 | callback args `(fact, old, new)` |
| «estado restablecido» | `&"state_reset"` | 3 | — |
| «estado restaurado» | `&"state_restored"` | 3 | — |
| «avisos descartados» | `&"notices_dropped"` | 3 (and 6's channel, own instance) | — |
| «dispositivo de entrada cambiado» | `&"input_device_changed"` | 1 | `dispositivo: SN` ‡ (`teclado_raton` / `mando`; ADR-0006) |
| «contexto de entrada cambiado» | `&"input_context_changed"` | 1 | `anterior: SN` (previous context), `contexto: SN` (ADR-0006; GDD 1 rule 6) |
| «`sin control` absorbido» | `&"no_control_absorbed"` | 1 | `dueno: SN` (the discarded holder, e.g. `&"scene_director"`; ADR-0006) |
| «carga de escena iniciada» | `&"scene_load_started"` | 4 | `destino: SN`, `motivo: SN`, `control_final: SN` ‡, `D_carga: F` (ADR-0003 O1) |
| «escena lista» | `&"scene_ready"` | 4 | `destino: SN` |
| «carga de escena terminada» | `&"scene_load_finished"` | 4 | `destino: SN`, `motivo: SN`, `control_final: SN` ‡, `t_since_started_s: F` ‡ (ADR-0003 O1; GDD 3/4/21 to confirm) |
| «carga de escena fallida» | `&"scene_load_failed"` | 4 | `destino: SN`, `motivo: SN`, `causa: SN` |
| «descarga total solicitada» | `&"full_unload_requested"` | 4 | — |
| «descarga total completada» | `&"full_unload_completed"` | 4 | — |
| «zona activada» | `&"zone_entered"` | 4 | `zona: SN` ‡ (`T-…`) |
| «partida terminada» | `&"game_finished"` | 4 (sole emitter, CA-36) | — |
| «guardado en riesgo» | `&"save_at_risk"` | 5 | — |
| «guardado restablecido» | `&"save_recovered"` | 5 | — |
| «vista cercana abierta» | `&"close_view_opened"` | 7 | `vista: SN` ‡ |
| «vista cercana cerrada» | `&"close_view_closed"` | 7 | `vista: SN` ‡, `motivo: SN` (`jugador`/`resuelto`/`sistema`) |
| «lectura abierta» | `&"reading_opened"` | 7 | `doc: SN` ‡ |
| «lectura completada» | `&"reading_completed"` | 7 | `doc: SN` ‡ |
| «lectura cerrada» | `&"reading_closed"` | 7 | `doc: SN` ‡, `motivo: SN` |
| «lectura descartada» | `&"reading_discarded"` | 7 | `doc: SN` ‡, `motivo: SN` |
| «modos cerrados» | `&"modes_closed"` | 7 | `lista: A` ‡ |
| «interacción ejecutada» | `&"interaction_executed"` | 7 | `id: SN`, `verbo: SN`, `resultado: SN` (D11) |
| «sonido pedido» | `&"sound_requested"` | 7, 8, 10, 15, 17, 19, 22, 25 | `sound_id: SN`, `fuente: SN?`, `accion: SN` (`play`/`stop`/`set`/`interrupt`), `valor: F?` |
| «línea pedida» | `&"line_requested"` | 8, 9, 21, 22 | `line_id: SN`, `fuente: SN?`, `fallback_s: F?`, `puzzle: SN?` (voice only; ADR-0008) |
| «puerta abierta» | `&"door_opened"` | 8 | `puerta: SN` ‡ (`A`/`B`/`D`) |
| «ascensor llamado» | `&"elevator_called"` | 8 | — |
| «ascensor rechazado» | `&"elevator_rejected"` | 21 | — |
| «efecto de escena pedido» | `&"scene_effect_requested"` | 21 | ‡ ADR-0017 (`id`, `objetivo`, `duracion`, `parametros` per TR-atmos contract) |
| «estado de objeto pedido» | `&"object_state_requested"` | 21 (sole emitter) | ‡ ADR-0017 |
| «tarjeta final pedida» | `&"end_card_requested"` | 21 | ‡ ADR-0017 |
| `EV_PUZZLE_SOLVED_<ID>` | `&"EV_PUZZLE_SOLVED_P1"` … `&"EV_PUZZLE_SOLVED_P6"` (literal, six constants) | 9 | `puzzle: SN`, `rewards: A`, `choice: SN?` (TR-puzzles-020) |
| «compartimento completado» | `&"compartment_completed"` | 9 | `n: I` (1–4) |
| «puzle activado» | `&"puzzle_activated"` | 9 | `puzzle: SN`, `ajar_cm: F?` |
| «resolución de puzle interrumpida» | `&"puzzle_resolution_interrupted"` | 9 | `puzzle: SN` ‡ |
| «pista aplicada» | `&"hint_applied"` | 9 | `id: SN`, `nivel: I`, `text_key: SN?` (TR-hints-015) |
| «puzle inactivo» | `&"puzzle_idle"` | 9 | `id: SN`, `nivel: I` (TR-hints-014) |
| «feedback de puzle» | `&"puzzle_feedback"` | 9 | `puzzle: SN`, `sound_id: SN`, `text_key: SN?`, `element: SN?` |
| «puzles configurados» | `&"puzzles_configured"` | 9 | — |
| «llamada iniciada» | `&"call_started"` | 22 | — |
| «llamada completada» | `&"call_completed"` | 22 | — |
| «línea iniciada» | `&"line_started"` | 23 | `line_id: SN`, `duracion_s: F`, `canal: SN` |
| «línea terminada» | `&"line_finished"` | 23 | `line_id: SN`, `motivo: SN` (`fin`/`corte`/`watchdog`/`interrumpida`) |
| «línea sin audio» | `&"line_no_audio"` | 23 | `line_id: SN`, `t_lectura_s: F` |
| «línea fallida» | `&"line_failed"` | 23 | `line_id: SN`, `t_lectura_s: F` |
| «pausa abierta» | `&"pause_opened"` (literal, GDD 25) | 25 | — |
| «pausa cerrada» | `&"pause_closed"` (literal, GDD 25) | 25 | — |

Settings' own channel (ADR-0007) carries only its change kind and
`&"settings_applied"` («ajustes aplicados»); those names live in ADR-0007, not
in `NoticeIds`.

Name rules: one name per notice (no aliases; «sonido de llamada pedido» does
not exist, DT-24); adding a notice = add the constant + schema row here (ADR
amendment) **and** the row in GDD 3 rule 10. `call_started` coincides with
GDD 5's save cause string; they are different namespaces and the coincidence is
intentional (5 maps notice → cause 1:1).

### Snapshot Format

```json
{
  "snapshot_version": 1,
  "facts": {
    "correos_leidos": false, "archivo_abierto": true, "formulario_leido": false,
    "tarjeta_B": false, "tarjeta_D": false, "memo_leido": true,
    "pos_L": 2, "pos_C": 4, "pos_R": 1,
    "caja_c1": true, "caja_c2": false, "caja_c3": false, "caja_c4": false,
    "pendiente_revelacion": false, "caja_completa": false,
    "carta_variante": null, "t4_decision": null,
    "llamada_iniciada": false, "respuesta_llamada": null, "llamada_completada": false
  }
}
```

- `request_snapshot()` returns this shape as a `Dictionary` with `String` keys
  and JSON-native values (`bool`, `int`, `String`, `null`); `{}` when
  `!is_queue_empty()` or status ≠ `READY` (no side effect, DT-3).
- Exactly the 20 catalog facts; no settings (CA-24, rule 14). `caja_completa`
  is written for readability and **ignored** on restore (recomputed).
- `snapshot_version` is the format version of this object, not the save-file
  version (ADR-0004 owns the file envelope `v<N>` + checksum).
- **Restore type rules** (rule 13, NS-3): `int` fact accepts `int`, or `float`
  with zero fractional part (`2.0` → 2, no log); fractional or out of range →
  initial + log. `bool` fact accepts only `bool`; anything else → initial +
  log. Enum accepts `null` (unset) or a `String`/`StringName` in the allowed set;
  anything else → unset + log. Missing fact → initial (no log). Undeclared key
  → ignored + log. Incoherent combinations (e.g. `llamada_completada` without
  `llamada_iniciada`) → kept + warning log; `caja_c3 ∧ pendiente_revelacion` →
  kept, no log (CA-34). `snapshot_version` greater than `SNAPSHOT_VERSION` is
  rejected by 5 before calling `restore` (GDD 5 rule 20); `restore` itself logs
  and proceeds best-effort if handed one.

### Invariants

- **I-1 Write-through.** After `set_fact` returns `true`, `get_fact` returns the
  new value, inside or outside a drain (rule 3, CA-13).
- **I-2 Change-only.** A notice is enqueued iff `old != new` (typed equality);
  identical writes allocate nothing and enqueue nothing (CA-10).
- **I-3 Derived after input.** For a write that changes a derived input, the
  input's `FACT` entry is enqueued before the derived one (CA-14); derived
  values are recomputed before `set_fact` returns.
- **I-4 FIFO + subscription order.** Entries are delivered in enqueue order;
  each entry to active subscribers in subscription order (CA-12).
- **I-5 No reentrancy.** No callback is ever invoked while another callback of
  the same channel is on the stack (CA-13).
- **I-6 Bounded drain.** At most `max_chained_notices` entries per drain, then
  drop + log + `ErrorPolicy.fail` + one `notices_dropped` (CA-15).
- **I-7 Atomic restore/reset.** No callback, read or write runs between the
  first and last fact assignment of `restore`/`reset_new_game`; the queue is
  cleared; exactly one `state_restored`/`state_reset` is then delivered with
  status already `READY` (CA-18, CA-19, CA-23). Requested inside a drain → run
  after the drain (CA-13b).
- **I-8 Snapshot consistency.** `request_snapshot()` never returns a non-empty
  result while an entry is pending, so `caja_c4 = true ∧ caja_completa = false`
  is unobservable in a snapshot (CA-25).
- **I-9 Silent write.** `write_silent` succeeds only if: status `READY`, window
  open, `owner_id` matches (always checked, in release too, because the window
  rule is a contract and not a dev aid), fact reversible (`pos_L/C/R`,
  `pendiente_revelacion`), value valid. It enqueues nothing and writes one
  `info` log line (CA-35).
- **I-10 Freed subscribers.** A subscriber whose object has been freed is never
  called and never errors (CA-17; NS-1).
- **I-11 Closed names.** Every `notify` name is in `NoticeIds`; every write
  name is in the catalog; both case-sensitive (Edge Cases).

### Implementation Guidelines

- **G-1** Systems must read and write facts only through the injected
  `GameState` reference and their `FactWriter`; they must never name the
  `GameState` autoload outside composition points (ADR-0009).
- **G-2** Notice names must be referenced as `NoticeIds.X` constants; string
  literals for notice names are forbidden outside `notice_ids.gd` and tests.
- **G-3** Fact names in code must be `StringName` literals (`&"caja_c1"`) or
  constants; hot paths must cache `resolve_fact()` indices at `configurar()`
  time and call `get_fact_at()` (system 7, `habilitado_si`).
- **G-4** Systems must never derive state from a notice they could have missed;
  on `state_restored`/`state_reset` they must re-read facts (rule 8).
- **G-5** Godot signals must never carry a GDD 3 rule 10 notice or a fact change
  (D10). Contract signals are limited to the list in D10; adding one requires the
  GDD to sign it and an amendment here.
- **G-6** Callbacks must be cheap and must not `await`; a callback that needs
  time must start its own process (Tween, GameClock timer, ADR-0002).
- **G-7** Payload dictionaries must be built fresh per `notify` and must not be
  mutated by consumers (the same instance reaches every subscriber).
- **G-8** All logging must go through `LogSink`; all "dev halts" through
  `ErrorPolicy`. Only `src/core/error_policy_default.gd` may name the engine
  calls of NS-4.
- **G-9** `flags.json` must declare `max_chained_notices` (int, 8–256, default
  64); out of range → catalog invalid (CA-26 path).
- **G-10** `GameState` and `Settings` must run with `process_mode = ALWAYS`
  (ADR-0002) so pause never stalls a drain; the bus itself has no per-frame
  processing.
- **G-11** The dev console (`dev_force`) must live in a separate script excluded
  from the demo export (ADR-0018, CA-29); `GameState` exposes only the hook.
- **G-12** Every consumer of `interaction_executed` other than 24 must gate its
  reaction on `InteractionNotice.is_done(payload)`.
- **G-13** Code identifiers are ASCII English; the GDD names map as:
  `escribir_silencioso` → `write_silent`, `cola_vacía()` → `is_queue_empty()`,
  `snapshot_version` → `get_snapshot_version()`.

### Drain and Write Algorithms (reference pseudocode)

```gdscript
# NoticeChannel — internal state
var _subs: Array[Dictionary] = []      # {handle, kind, topic, cb, active}, subscription order
var _queue: Array[Dictionary] = []     # {kind, topic, a, b}; a/b = old/new or payload
var _draining := false
var _after_drain: Array[Callable] = []
var _pending_removal: Array[int] = []

func _enqueue(entry: Dictionary) -> void:
	if _tap.is_valid() and entry.kind == Kind.NOTICE:
		_tap.call(entry.topic, entry.a)            # GameState window (D9)
	_queue.push_back(entry)
	if not _draining:
		_drain()

func _drain() -> void:
	_draining = true
	var delivered := 0
	var dropped_once := false
	while not _queue.is_empty():
		if delivered >= _max_chained:
			var lost := _queue.size()
			_queue.clear()
			_log.line(&"error", "notices dropped: %d pending" % lost)
			_errors.fail("max_chained_notices reached")   # dev halt (NS-4)
			if dropped_once:
				break                                # second overflow: log only
			dropped_once = true
			delivered = 0
			_queue.push_back({kind = Kind.NOTICE, topic = NoticeIds.NOTICES_DROPPED, a = {}, b = null})
			continue
		var e: Dictionary = _queue.pop_front()
		delivered += 1
		var n := _subs.size()                        # bound fixed before iterating (late subscribers skip this entry)
		for i in n:
			var s: Dictionary = _subs[i]             # removals are deferred, so indices stay stable
			if s.active and _matches(s, e) and s.cb.is_valid():
				if e.kind == Kind.NOTICE: s.cb.call(e.a)
				else: s.cb.call(e.topic, e.a, e.b)
		_apply_pending_removals()                    # CA-16: after the entry, not mid-entry
	_prune_invalid()
	_draining = false
	_run_after_drain_jobs()                          # deferred restore / reset (rule 11)

# GameState.set_fact — order of checks (rule 6, rule 4, rule 2)
#  1 status RESTORING → reject (log; dev fail).  UNLOADED → reject (CA-27).
#  2 undeclared / derived → invalid.          3 exact type (no coercion), range/enum set → invalid.
#  4 one-way fact already set and value differs → invalid.   5 dev only: owner_id != catalog owner → invalid.
#  6 value == current → return true (no enqueue, no alloc).
#  7 assign; recompute dependents; push_change(input) then push_change(derived) for each real change.
```

Subscriptions added during a drain are appended to `_subs` and are not visited
for the entry in flight (the loop bound is taken before iterating). `restore`
and `reset_new_game` called while `_draining` register a job via
`run_after_drain`; when they run, they first `clear_pending()`.

## Alternatives Considered

### Alternative 1: Godot signals on the `GameState` autoload

- **Description**: `signal fact_changed(fact, old, new)` plus one `signal` per
  named notice (≈45) declared on `GameState`; systems `connect()` directly.
- **Pros**: Idiomatic; editor shows connections; no custom dispatcher; typed
  signal parameters give per-notice arity checking.
- **Cons**: Order between receivers, reentrancy on `emit()` and the effect of
  disconnecting during an emission are NOT SOURCEABLE (NS-5); the GDD's queue,
  cap, deferred unsubscribe and deferred reset/restore would still need a
  wrapper, making signals a second mechanism rather than the only one. ≈45
  signals on one class couple every emitter to `GameState`'s script. Settings
  could not reuse it without duplicating the wrapper (TR-state-012). Per-fact
  subscription would need filtering in every subscriber, which rule 9 forbids.
- **Estimated Effort**: Similar to the chosen approach once the wrapper is built.
- **Rejection Reason**: Cannot guarantee rules 9 and 11 without the same custom
  code, and adds an undocumented engine behaviour to the critical path.

### Alternative 2: Godot signals with `CONNECT_DEFERRED`

- **Description**: Emit normally; connect every subscriber deferred so delivery
  happens at idle time, avoiding reentrancy.
- **Pros**: Removes reentrancy with no custom code.
- **Cons**: Breaks "same frame" delivery (Game Feel) and the save rule "snapshot
  at the first instant with empty queue", which needs an observable queue;
  deferred-call timing is NOT SOURCEABLE; no cap; no ordered merge between
  fact-change and named notices.
- **Estimated Effort**: Lower initially, higher in debugging.
- **Rejection Reason**: Violates TR-state-009 ordering/same-frame and gives 5
  no `is_queue_empty()`.

### Alternative 3: Typed payload classes (one `RefCounted` per notice)

- **Description**: `class_name SceneLoadStarted extends RefCounted` with typed
  fields, one per notice (≈45 classes), `notify(NoticeIds.X, payload: Notice)`.
- **Pros**: Compile-time field checks; autocompletion.
- **Cons**: ≈45 tiny classes to keep in sync with GDD tables; most notices have
  no data; the bus would still type its queue as `Variant`; JSON-like payloads
  of 21 are owned by data (ADR-0017) and fit `Dictionary` naturally.
- **Estimated Effort**: ~3× the chosen approach for the registry.
- **Rejection Reason**: Cost disproportionate for the slice; debug-time schema
  validation gives the same safety in tests. Revisit if payload bugs appear in
  integration (Open Items OI-5).

### Alternative 4: Separate bus implementation for Settings (6)

- **Description**: 6 implements its own queue as GDD 6 rule 7 literally reads.
- **Pros**: No shared class; zero coupling.
- **Cons**: Two implementations of identical semantics to test and keep in sync;
  contradicts TR-state-012 "one single mechanism".
- **Rejection Reason**: The shared `NoticeChannel` gives 6 the same semantics
  with no dependency on 3.

### Alternative 5 (QQ-09): separate «interacción rechazada» notice for 24

- **Description**: Keep «interacción ejecutada» `HECHO`-only and add a second
  notice for `SIN_EFECTO`/`GESTO_RECHAZADO`/`TOQUE_CORTO`.
- **Pros**: Consumers 21/23/28 need no filter.
- **Cons**: Two notices per gesture family; GDDs 7 (D7-74) and 24 (D24-9) already
  rejected it as duplication ("un gesto, un aviso, un pulso").
- **Rejection Reason**: Contradicts two signed GDD decisions; the filter costs
  one comparison.

## Consequences

### Positive

- Every GDD 3 delivery guarantee is implemented in one ~300-line class that is
  unit-testable without a scene tree; Settings gets the same guarantees for free.
- Ordering, cap and deferral do not depend on any NOT SOURCEABLE engine
  behaviour except `Callable.is_valid()` (NS-1), which has a fallback.
- One registry makes "undeclared emitter = documentation defect" (rule 10)
  enforceable in dev and testable (V-UNIT-14).
- Writer capability (`FactWriter`) resolves GDD 3 OQ 3 without systems knowing
  their own number and makes CA-08 testable.
- Snapshot is already JSON-native; ADR-0004 serialises it without conversion.

### Negative

- No editor visibility of subscriptions (signals would show in the Node dock);
  mitigated by a dev-only `dump_subscriptions()` for the console.
- Payloads are checked at run time (debug), not at parse time.
- One subscriber list scanned per entry: O(S) with S ≈ 60; acceptable for
  discrete notices, not for per-frame data (which is why 24's target and 2's
  footsteps never use the bus).
- Mixed-language payload keys (`destino`, `line_id`) because GDD IDs are kept
  literally.

### Neutral

- `GameState` keeps the ‡ signatures from `architecture.md` almost unchanged;
  renames: `escribir_silencioso` → `write_silent`, `cola_vacía` →
  `is_queue_empty`, `subscribe_all` → `subscribe_all_facts`, plus indexed reads.

## Risks

- **RK-1 `Callable.is_valid()` does not detect freed objects (NS-1).**
  Mitigation: V-ENG-1 first; fallback `is_instance_valid(cb.get_object())`; last
  resort, mandatory unsubscribe in `_exit_tree` enforced by a debug check of
  dangling handles at `scene_load_finished`.
- **RK-2 Dictionary read allocates (NS-2), breaking TR-state-002.** Mitigation:
  indexed `get_fact_at()` backed by a plain `Array`; V-ENG-2 measures both.
- **RK-3 A consumer forgets the `HECHO` filter (D11).** Mitigation: G-12 in the
  control manifest; V-INT-3 per consumer.
- **RK-4 Cap reached in a legitimate cascade.** The longest known slice chain is
  a handful of entries (`carta_variante` → `caja_c4` → `caja_completa` →
  apagón, GDD 3 Edge Cases); 64 leaves ~10× margin. Mitigation: CA-32 records
  the longest drain observed in a full run (`max_drain_len` dev metric).
- **RK-5 Payload schema drift between GDD tables and `NoticeIds.SCHEMA`.**
  Mitigation: V-UNIT-15 checks that every constant has a schema row; the registry
  table above is the single source and later ADRs reference it.
- **RK-6 Callback throws mid-drain.** GDScript has no exceptions; a runtime
  error in a callback (NOT SOURCEABLE whether the caller continues) could leave
  `_draining = true`. Mitigation: V-ENG-5 checks behaviour on 4.7.2; if the
  drain does not continue, `GameState` resets `_draining` at the next `notify`
  when the queue is empty and logs (dev halt).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| estado-y-bus-de-eventos.md | Rules 1–7: closed catalog, single owner, write-through, one-way, reversible, invalid write, derived (TR-state-001…007) | `load_catalog`, `set_fact` check order, `FactWriter` (D7), I-1, I-3 |
| estado-y-bus-de-eventos.md | Rule 9: change-only notice, three subscription kinds, bus-side filtering (TR-state-008) | D6, I-2, `subscribe_fact` / `subscribe_all_facts` / `subscribe_notice` |
| estado-y-bus-de-eventos.md | Rule 10: named notices, technical format left to ADR; one mechanism with 6 (TR-state-012) | D1–D4, § Notice Name Registry, `NoticeChannel` shared with 6 |
| estado-y-bus-de-eventos.md | Rule 11 + Edge Cases: FIFO, no reentrancy, deferred reset/restore, cap with «avisos descartados» (TR-state-009…011) | D5, drain algorithm, I-4…I-6; `max_chained_notices` = 64 |
| estado-y-bus-de-eventos.md | Rules 12–13: new game, snapshot, restore, `snapshot_version`, `cola_vacía()`, JSON type tolerance (TR-state-013…016) | D8, § Snapshot Format, I-7, I-8 |
| estado-y-bus-de-eventos.md | Rule 16: silent repair write and its window (TR-state-017) | D9, I-9, `write_silent` |
| estado-y-bus-de-eventos.md | Rule 15 + OQ 7: dev console, injectable log (TR-state-018) | `dev_force` hook, `LogSink`, `ErrorPolicy`, G-11 (CI check in ADR-0018) |
| estado-y-bus-de-eventos.md | Game Feel: constant-cost, allocation-free read (TR-state-002) | `resolve_fact` + `get_fact_at`, V-ENG-2 |
| ajustes-persistentes.md | Rule 7: own change notice, same delivery rules, auto-unsubscribe on unload (TR-settings-005, -006) | Own `NoticeChannel` instance (D2), I-10; key/payload details in ADR-0007 |
| interaccion-e-inspeccion.md / prompt-de-interaccion.md | Rule 29 / D7-74 / D24-9: «interacción ejecutada» with four `resultado` values (TR-prompt-005, -006) | D11 (QQ-09) |
| marco-de-puzles.md, puzle-1…6 | Same-frame write → notice order on resolution (TR-puzzles-011, -019, -020; TR-puzzle1-012, -015; TR-puzzle2-010; TR-puzzle4-013, -017; TR-puzzle5-013, -014; TR-puzzle6-006, -007) | I-1 + I-4: writes visible at once, notices in call order; `EV_PUZZLE_SOLVED_P1…P6` constants and payload |
| control-de-acceso.md | «puerta abierta» once per opening; `EN_USO` exit via «ascensor rechazado» (TR-access-007, -014) | Registry names; bus does not deduplicate (Edge Cases), 8 owns idempotence |
| director-de-escenas.md | Reads facts, reacts to change notices, emits orders by bus (TR-director-006, -007, -008, -014, -019, -023) | Subscription kinds; registry; D11 filter for `V02` |
| llamada-telefonica.md | Single writer of three facts; notices «llamada iniciada/completada» (TR-call-010, -012, -013, -014, -017) | `FactWriter(22)`; `set_fact` returns `false` on rejected write so 22 can replay the stored value (TR-call-012) |
| director-de-audio.md / subtitulos.md | Exactly one response per «línea pedida», enqueued, never inside the request's delivery (TR-audio-006, -007; TR-subs-001, -002) | D5: anything 23 emits during delivery of `line_requested` is queued (I-5) |
| escena-de-planta.md | Load notices with payloads; sole emitter of «partida terminada»; stale-scene warning (TR-scene-020, -021; TR-input-006) | Registry; D9 consumes `scene_load_*` |
| guardado-y-carga.md | Wait for empty queue; `notices_dropped` cause (TR-save-007, -012) | `is_queue_empty()`, I-8, D5 |
| menu-de-pausa.md | `pause_opened`/`pause_closed` literal names (TR-pause-005, -006) | Registry (literal constants) |
| sistema-de-pistas.md, documentos-y-bolsillo.md, ordenador-correo-impresora.md, caja-y-compartimentos.md, atmosfera-reactiva.md | Notice subscriptions and single-fact writes (TR-hints-005, -014, -015; TR-pocket-012, -015; TR-computer-006; TR-box-012; TR-atmos-002) | Registry names and payloads; `FactWriter(19)`, `FactWriter(20)` |

**TR coverage (by range):** TR-state-001…018 (018: hooks only; CI script in
ADR-0018); TR-settings-005, -006 (mechanism only); TR-puzzles-011, -019, -020;
Events of 8 (TR-access-007, -014), 9 (TR-puzzle1-012, -015, TR-puzzle2-010,
TR-puzzle4-013, -017, TR-puzzle5-013, -014, TR-puzzle6-006, -007), 21
(TR-director-006, -007, -008, -014, -019, -023), 22 (TR-call-010, -012…-014,
-017), 23 (TR-audio-006, -007); plus notice-contract parts of TR-scene-020,
-021, TR-save-007, -012, TR-prompt-005, -006, TR-pause-005, -006, TR-subs-001,
-002, TR-hints-005, -014, -015, TR-input-006, TR-pocket-012, -015,
TR-computer-006, TR-box-012, TR-atmos-002. The behaviour inside each emitter
(when it emits) stays with its own ADR.

## Performance Implications

- **CPU**: Read `get_fact_at`: one `Array` index; ~35 reads × 60 Hz ≈ 2,100
  reads/s, target < 0.02 ms per physics step total (V-ENG-2). Write: ≤ 6 checks
  + optional derived recompute (one rule, four inputs). Notice: O(S) scan,
  S ≈ 60 subscriptions, a few notices per frame at peak (puzzle resolution
  ≈ 6 entries) → target < 0.05 ms per drain of 10 entries. No per-frame cost
  when idle (no `_process`).
- **Memory**: 20 facts + ~60 subscriptions + queue ≤ 64 entries: < 50 KB.
  One `Dictionary` allocation per enqueued entry and per payload; identical
  writes allocate nothing.
- **Load Time**: Parse of `flags.json` (20 entries) — negligible (< 1 ms).
- **Network**: N/A.

## Migration Plan

No existing code. Implementation order: `LogSink`/`ErrorPolicy` doubles →
`NoticeChannel` + unit tests → `FactCatalog` (`flags.json` schema shared with
ADR-0005) → `GameState` → `FactWriter` → `NoticeIds` + schema → `Settings` reuse
(ADR-0007). `architecture.md` § API Boundaries "Bus y estado (3)" is updated to
these signatures when this ADR is accepted (not edited by this ADR).

**Rollback plan**: The public surface (`GameState` methods and `NoticeIds`) is
mechanism-agnostic; if the custom channel proved wrong, `NoticeChannel` could be
reimplemented internally over signals without touching callers, provided the
replacement passes the same V-UNIT suite.

## Validation Criteria

We will know this was right if: every CA of GDD 3 marked L passes as a gdUnit4
unit test with no scene tree; CA-32 (full slice run) never emits
`notices_dropped` and `max_drain_len` < 16; the hot read path stays under
budget; and no story needs a second notice mechanism.

**Engine verification (must pass on 4.7.2 before `Accepted`)** —
`tests/unit/core/engine_assumptions_test.gd`:

| ID | Test (`test_[scenario]_[expected]`) | Proves |
|---|---|---|
| V-ENG-1 | `test_callable_of_freed_node_is_invalid` | NS-1 (else fallback per RK-1) |
| V-ENG-2 | `test_get_fact_at_35_reads_per_step_under_budget` (perf, 10,000 iterations, records allocations if measurable) | NS-2, TR-state-002 |
| V-ENG-3 | `test_json_roundtrip_int_fact_restores_as_int` | NS-3 (with GDD 5 AC-30c) |
| V-ENG-4 | `test_error_policy_strict_in_debug_noop_in_release` (spike + manual check on a release export) | NS-4 |
| V-ENG-5 | `test_callback_runtime_error_does_not_wedge_drain` | RK-6 / NS-8 |
| V-ENG-6 | `test_variadic_lambda_receives_three_args` | lambda/rest-param note (`current-best-practices.md`) |

**Unit tests** — `tests/unit/state/` and `tests/unit/core/` (files
`state_facts_test.gd`, `state_notices_test.gd`, `state_snapshot_test.gd`,
`state_silent_write_test.gd`, `core_notice_channel_test.gd`):

| ID | Scenario | GDD CA |
|---|---|---|
| V-UNIT-1 | 20 facts loaded with initials; owners match "Escribe" column | CA-01, CA-30 |
| V-UNIT-2 | Read initial / read after valid write | CA-02 |
| V-UNIT-3 | One-way bool/enum: same value no notice, other value rejected + 1 log | CA-03, CA-04 |
| V-UNIT-4 | Reversible `pos_*`, `pendiente_revelacion` both directions | CA-05 |
| V-UNIT-5 | Release policy: invalid writes keep value + exactly 1 log line; strict policy calls `fail` | CA-06, CA-06b (strict path via double) |
| V-UNIT-6 | Derived `caja_completa` recompute; direct write rejected; notice order c4 → completa | CA-07, CA-14 |
| V-UNIT-7 | Owner mismatch invalid with strict policy, unchecked with release policy | CA-08 |
| V-UNIT-8 | No delivery to late subscriber; exactly-once change; none on identical write | CA-09, CA-10 |
| V-UNIT-9 | Subscription order A, B; FIFO across two changes | CA-12 |
| V-UNIT-10 | Subscriber writes Y on X: Y delivered after X to all; read of Y immediate | CA-13 |
| V-UNIT-11 | New game requested inside a drain → applied after, single `state_reset`, empty queue | CA-13b, CA-18 |
| V-UNIT-12 | Cap from data (test value 8): exactly 8 delivered, rest dropped, 1 log, `fail` called, one `notices_dropped` | CA-15 |
| V-UNIT-13 | Unsubscribe during a drain: no later entries | CA-16 |
| V-UNIT-14 | `notify` with name absent from `NoticeIds` → `fail` (strict) / dropped + log | rule 10 |
| V-UNIT-15 | Every `NoticeIds` constant has a schema row; payload with missing/extra/mistyped key → `fail` (strict) | CA-11, CA-36 (shape) |
| V-UNIT-16 | Snapshot/restore round trip; single `state_restored`; status `READY` at delivery | CA-19, CA-23 |
| V-UNIT-17 | Restore: missing fact, undeclared fact, incoherent derived, invalid enum, `pos_C` = 9, `2.0`, `2.5`, bool as number | CA-20, CA-21, CA-33 |
| V-UNIT-18 | Restore keeps `llamada_iniciada ∧ ¬llamada_completada` silently; inverse with warning; `caja_c3 ∧ pendiente_revelacion` silently | CA-22, CA-34 |
| V-UNIT-19 | Reentrant read/write/restore from a test hook inside restore → rejected + log | CA-23 |
| V-UNIT-20 | Snapshot keys = 20 facts, no settings; `{}` with pending queue | CA-24, CA-25 |
| V-UNIT-21 | `UNLOADED` read → neutral + log; write dropped; undeclared read in `READY` | CA-27 |
| V-UNIT-22 | `dev_force` bypasses one-way rule, emits change, logs | CA-28 |
| V-UNIT-23 | `write_silent`: success path (no notice, queue empty, info log, later read); rejected by non-owner, outside window, after `scene_ready`, after `scene_load_failed`, on one-way fact; Save double `dif` true | CA-35 |
| V-UNIT-24 | `correos_leidos` emits generic change only | CA-37 |
| V-UNIT-25 | `NoticeChannel` alone (no `GameState`): same FIFO/no-reentrancy/cap suite run against a Settings-like owner | TR-settings-006 |

**Integration tests** — `tests/integration/state/`:

| ID | Scenario | GDD CA |
|---|---|---|
| V-INT-1 | Node subscriber freed with its scene; next change no error | CA-17 |
| V-INT-2 | Test emitters for every registry notice reach a subscriber with name + payload; per-fact subscriber isolated | CA-11, CA-36 |
| V-INT-3 | 21, 23, 28 doubles ignore `interaction_executed` with `resultado ≠ HECHO`; 24 pulses for all four | D11, TR-prompt-006 |
| V-INT-4 | Full slice run in dev: no `notices_dropped`, no owner violation, `max_drain_len` recorded | CA-31, CA-32 |
| V-INT-5 | Missing/corrupt `flags.json` at boot → fatal handler, no game entry | CA-26 |

CA-29 (demo export without console) is validated by ADR-0018's CI script.

## Open Items

| # | Item | Owner | Resolve before |
|---|---|---|---|
| OI-1 | Run V-ENG-1…6 on 4.7.2 and record results here (NS-1…NS-9; NS-5, NS-7 and NS-9 are avoided by design and need no test) | lead-programmer | `Accepted` |
| OI-2 | **GDD contradiction:** GDD 7 rule 29 lists 28 (Atmósfera) as a consumer of «interacción ejecutada»; the 28 contract in `tr-baseline-provisional.md` (from `atmosfera-reactiva.md`) says 28 does **not** consume it. Under D11 either is valid; GDD 7 rule 29 / OQ 6 should be aligned with 28 | game-designer (GDD 7 / 28 re-review) | Re-review of 7 and 28 |
| OI-3 | **Interpretation:** GDD 3 says the cap is "por fotograma"; this ADR applies it per synchronous drain (D5). Equivalent for any single chain; GDD 3 Tuning Knobs text should say "por entrega encadenada" | game-designer (GDD 3) | GDD 3 re-review |
| OI-4 | **Interpretation:** I-9 checks `owner` for `write_silent` in release too, while GDD 3 rule 2 skips owner checks in release for normal writes. Rule 16(a) makes ownership part of the silent-write contract, so the stricter reading is used | technical-director | GDD 3 re-review (confirm) |
| OI-5 | Revisit typed payload classes (Alt. 3) if integration finds payload bugs that the debug schema did not catch | technical-director | M2 retrospective |
| OI-6 | Proposed payload keys ‡ (`dispositivo`, `contexto`, `dueno`, `zona`, `vista`, `doc`, `lista`, `puerta`, `puzzle` in `puzzle_resolution_interrupted`) must be confirmed by GDDs 1, 4, 7, 8, 9 or by ADR-0006/-0003/-0011/-0010. Closed for system 1 by ADR-0006 (`anterior`/`contexto`, `dueno`; reconciliation 2026-11-10); `dispositivo` still ‡ | owners of those ADRs | Each ADR |
| OI-7 | Payload schemas of `scene_effect_requested`, `object_state_requested`, `end_card_requested` | ADR-0017 | M3 |
| OI-8 | GDD 3 internal inconsistency (minor): its Dependencies row for 7 lists four notices; rule 10 lists eleven. The registry follows rule 10 | game-designer (GDD 3) | GDD 3 re-review |
| OI-9 | `architecture.md` § API Boundaries "Bus y estado (3)" keeps `escribir_silencioso`/`cola_vacía` as identifiers; update to G-13 names on acceptance | technical-director | `Accepted` |

## Related

- `docs/architecture/architecture.md` — § Data Flow 2, § API Boundaries "Bus y
  estado (3)", § Required ADRs (row ADR-0001), § Open Questions QQ-09, QQ-15.
- `docs/architecture/tr-baseline-provisional.md` — TR-state-001…018 and the
  Events rows cited above.
- `design/gdd/estado-y-bus-de-eventos.md` — rules 1–16, Edge Cases, Tuning
  Knobs, Acceptance Criteria CA-01…CA-37, DT-3, DT-6, DT-10, DT-24.
- `design/gdd/ajustes-persistentes.md` rule 7; `design/gdd/interaccion-e-inspeccion.md`
  rule 29, D7-74, OQ 6; `design/gdd/prompt-de-interaccion.md` D24-9.
- ADR-0002 (pause, related), ADR-0009 (composition, related); required by
  ADR-0003…ADR-0008, and by ADR-0010, ADR-0011, ADR-0017 for payloads.
- Code (once implemented): `src/core/notice_channel.gd`, `src/core/notice_ids.gd`,
  `src/core/game_state.gd`, `src/core/fact_writer.gd`, `src/core/log_sink.gd`,
  `src/core/error_policy.gd`, `assets/data/state/flags.json`.
