# ADR-0009: Service Composition — Autoloads, Shell and Dependency Injection

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.

## Date

2026-11-10

## Last Verified

2026-11-10 — against Godot 4.7.2 references in `docs/engine-reference/godot/`
and `docs/architecture/architecture.md` v1 (commit `d37566b`).

## Decision Makers

technical-director (author, autonomous mode per `project.yaml`
`modes.automation: autonomous`); user approval pending at batch close.

## Summary

The slice has 30 systems whose GDDs sign direct calls inside a layer, a few
persistent services, and a hard requirement that every public method be
unit-testable without real singletons. This ADR fixes the **9 autoloads**,
makes `Boot` the **single composition root** that builds a typed
`ServiceContext` injected through `configurar(ctx)`, orders Core/Feature into
sub-layers (C1–C3, F1–F5) with direct calls allowed only downward through
injected ports, defines the `ViewGateProvider`/`BoxPresenter` ports that break
the 9⇄10 cycle, an injected `FatalErrorHandler`, the boot order, the test
doubles, and the rule that no puzzle controller can reach another puzzle.
QQ-13 is resolved: Atmosphere (28) is a scene node, not an autoload.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | LOW for the pattern itself (autoloads, `RefCounted`, `@onready` and typed GDScript are pre-cutoff); MEDIUM for the two post-cutoff features it leans on (`@abstract`, typed-return override rule of 4.7) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `current-best-practices.md` § GDScript (4.5+), § GDScript (4.7), § Command Line — Tests and Parse Check; `deprecated-apis.md` (row `$NodePath` in `_process()` → `@onready var`); `breaking-changes.md` (not needed beyond the 4.7 GDScript row) |
| **Post-Cutoff APIs Used** | `@abstract` class and method annotations (4.5, sourced in `current-best-practices.md`); typed-method override inherits the return type and needs an explicit `return` (4.7, sourced in the same file) |
| **Verification Required** | (V1) a `class_name` equal to an autoload name is rejected by the 4.7.2 parser — **NOT SOURCEABLE**, assumed from memory; this ADR avoids the clash by naming rule, so the outcome changes nothing but must be recorded. (V2) Autoloads are children of `root` in registration order and `_ready()`/`_process()` follow tree order — **NOT SOURCEABLE** for 4.7; `GameClock` sets an explicit `process_priority` so it does not depend on it. (V3) `@abstract` on a `RefCounted` port plus a concrete inner subclass parses and instantiates on 4.7.2 (sourced syntax, unobserved combination). (V4) `print_orphan_nodes()` / `OBJECT_NODE_COUNT` usable from a gdUnit4 suite for the TR-scene-009 check — **NOT SOURCEABLE**. (V5) gdUnit4 `mock()`/`spy()` on a class with `@abstract` members — **NOT SOURCEABLE**; this ADR does not depend on it (hand-written doubles). |

> Knowledge Risk is MEDIUM for two annotations only. On an engine upgrade,
> re-run the composition unit suite (§ Validation Criteria); the rest of the
> decision is engine-agnostic.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None that must be `Accepted` first. **Related:** ADR-0001 (event bus — this ADR fixes *where* `GameState` comes from, ADR-0001 fixes its API) and ADR-0002 (pause — owns the `process_mode` value of every autoload; this ADR only requires that each one declares it explicitly). Neither file exists yet (2026-11-10); both are `Required` in `architecture.md` § Required ADRs |
| **Enables** | ADR-0003 (scene loading uses `configurar(ctx)` and the bind/unbind protocol defined here), ADR-0010 (puzzle framework: `PuzzleServices`, `ViewGateProvider`, `BoxPresenter`), ADR-0011 (interaction ports), ADR-0014 (Atmosphere as scene node), ADR-0015 (`SurfaceFx` port and `FxTarget` registry), ADR-0016 (UI ports into `Shell`), ADR-0017 (director scene binding) |
| **Blocks** | Every story that creates a system node or a unit test suite (all of S0); the layer rules of `docs/architecture/control-manifest.md` |
| **Ordering Note** | `architecture.md` § Required ADRs: 0001 → 0002 → 0009 → 0003 can be drafted in parallel with the pause spike. If ADR-0002 changes the provisional `process_mode` table in § Decision 7, ADR-0002 wins and this ADR is updated, not superseded |

## Context

### Problem Statement

`architecture.md` v1 already lists 9 autoloads and states a rule ("autoloads
are named only from composition points; system code receives dependencies by
injection, `ServiceContext` ‡"), but leaves open the shape of that context,
when it is filled, who may call whom inside a layer, how persistent services
reach per-scene services, how fatal errors leave a system that must not know
the UI, and how a test replaces any of it. Without a decision before the
first line of code, each system will reach for `/root/...` or a global name,
and `.claude/docs/coding-standards.md` ("All public methods must be
unit-testable (dependency injection over singletons)") becomes unenforceable
retroactively. It must be decided now because every S0 story instantiates a
node and writes a test against it.

### Current State

No code exists (`src/` holds only `.gitkeep` folders; `project.godot` has no
`[autoload]` section). The documented state is:

- `architecture.md` § Module Ownership: 9 autoloads (`ContentDB`, `GameState`,
  `GameClock`, `InputRouter`, `Settings`, `AudioDirector`, `SaveService`,
  `SceneLoader`, `SceneDirector`); `Atmosphere`, `HintService`, `PauseMenu`,
  `SurfaceFx`, `CallController` rejected as autoloads.
- § System Layer Map: sub-layers C1–C3 and F1–F5, direct calls only downward
  through an injected interface, notices always through the bus; cycles
  2⇄4 and 9⇄10 broken by data contract and by two small interfaces.
- § Data Flow 4: boot steps 2a–2i run by a `Boot` node inside `Shell`.
- QQ-13 open: GDD 28 DT-1 asks for an `Atmosphere` autoload (TR-atmos-001);
  `architecture.md` keeps it as a scene node.

### Constraints

- **Engine:** GDScript has single inheritance and no interface keyword; the
  only enforced contract mechanism is `@abstract` (4.5+). A `Node` subclass
  such as `PuzzleFramework` cannot also extend `ViewGateProvider`.
- **Engine:** autoloads are global names visible to every script; the
  framework's parse check notes `--check-only -s <file>` fails on valid code
  that names an autoload (`current-best-practices.md`), so fewer files naming
  autoloads also means fewer parse-check special cases.
- **Design:** 15 direct intra-layer calls are signed in reviewed GDDs
  (7↔9, 9→10, 10→7, 8→20, 19→20, 9→19, 9→20, 20→7, 21→7, 17→9; 4→2, 5→4,
  23→6). Forbidding them would contradict the GDDs.
- **Design:** some signed calls point *upward* across layers: 7 and 20 call
  24 `mostrar_pie`; 9, 12 and 15 issue orders to 29 `SurfaceFx`; 17 provides
  a panel hosted by 25. They need a rule, not an exception list.
- **Design:** persistent services (21 `SceneDirector`, Shell UI 24/25/26)
  consume per-scene services (7, 9, 17) that are destroyed and recreated on
  every `planta` load (TR-scene-009).
- **Team:** solo/indie team; the mechanism must be explainable on one page
  and must not need a DI framework or plugin.

### Requirements

- Every system is constructible in a gdUnit4 test with doubles only — no
  autoload, no file I/O, no real clock (TR-settings-021, TR-puzzles-014).
- Persistent services keep the same `get_instance_id()` across scene changes
  (TR-scene-002, TR-director-001, TR-settings-007).
- After 10 `planta` load cycles, orphan nodes and bus subscribers return to
  their boot values (TR-scene-009).
- Configuration order inside `planta`: 7 → 9 → rest, synchronous, same frame
  (TR-scene-011).
- A catalog-level fatal error invokes an injected handler with a code and the
  offending parameter, using text independent of 18 (TR-settings-019).
- No per-frame cost: composition happens at boot and at scene load only.

## Decision

Eleven numbered decisions. Mandates use **must / must never** so
`/create-control-manifest` can extract them.

### D1. The autoload list (final): 9 entries

**Test for "autoload or scene node".** A service is an autoload only if it
meets **at least one** of these, and the row names which:

- **(P) Persistence** — a TR requires the same instance across scene changes,
  or it owns state that must survive `WorldSlot` being emptied.
- **(B) Before-scene** — it must exist and be ready before any scene (title
  included) is instantiated, because scenes or the error path read it.
- **(G) Global owner** — it is the single owner of a cross-cutting fact that
  would otherwise be reinvented per system (pause, notice bus).

Anything that fails all three is a **scene node** (in `planta`/`recepcion`/
`title`) or a **Shell node** (persistent UI that is not a service).

| Reg. order | Autoload name (registered) | `class_name` | System | Test met | Why it cannot be a scene node |
|---|---|---|---|---|---|
| 1 | `ContentDBAutoload` | `ContentDB` | 18 | B | Read-only catalog that 9 validates against and that 25, 26, 27 and the error panel read; it has no dependency on any scene, and the title needs it |
| 2 | `GameStateAutoload` | `GameState` | 3 | P, G | Facts + notice bus; the only horizontal channel; must survive loads (TR-scene-002); a scene-owned bus would drop subscribers mid-load |
| 3 | `GameClockAutoload` | `GameClock` | Pause (ADR-0002) | G | Sole owner of "pause active" and Δ_juego (TR-puzzles-014 and 8 other systems). Per-scene clocks would desynchronise across the load fade |
| 4 | `InputRouterAutoload` | `InputRouter` | 1 | P, B | Context stack and `sin control` owner live across the load (TR-scene-002; 4 opens `sin control` *before* unloading) |
| 5 | `SettingsAutoload` | `Settings` | 6 | P, B | TR-settings-007: survives scene changes with no dangling refs; the title's options read it |
| 6 | `AudioDirectorAutoload` | `AudioDirector` | 23 | P | Rain and drone layers cross `planta`→`recepcion` (TR-audio-001) |
| 7 | `SaveServiceAutoload` | `SaveService` | 5 | B | Inspection at boot and after "descarga total completada"; the title queries it with no game scene loaded |
| 8 | `SceneLoaderAutoload` | `SceneLoader` | 4 | P, B | Loads/unloads the world scene and owns the curtain; it cannot live inside what it unloads |
| 9 | `SceneDirectorAutoload` | `SceneDirector` | 21 | P | TR-scene-002, TR-director-001: persistent; receives the `sin control` handoff in the frame of "carga terminada", which a freshly instantiated scene node does not guarantee |

**Rejected as autoload (they are scene or Shell nodes):**

| Candidate | Lives in | Fails P/B/G because | Source that asked for it |
|---|---|---|---|
| `Atmosphere` (28) | Node at the root of each game scene (`planta`, `recepcion`) + `AtmosphereZone` per room | See **D11 (QQ-13)** | TR-atmos-001, GDD 28 DT-1 |
| `HintService` (17) | `planta` | State is per-session-of-scene, in memory (TR-hints-002); TR-hints-001 forbids a singleton | — |
| `Pocket` (20) | `planta`, exposed through the `PocketService` port | TR-pocket-003/-017: session set emptied on unload; facts live in 3 | baseline § 20 row "nodo o autoload con interfaz" — resolved as node |
| `CallController` (22) | `planta` | All state rebuilt from 3 facts; dies with the scene | — |
| `SurfaceFx` (29) | `planta` (+ `FxTarget` nodes per room) | Targets are scene meshes (TR-shaders-015) | — |
| `PauseMenu` (25), `InteractionPrompt` (24), `Subtitles` (26), HUD | `Shell` | Persistence is solved by `Shell` (never unloaded) without being a global service | — |
| `DataValidator`, `I01Composer`, `FatalErrorHandler`, clocks, log sink | `RefCounted` objects created by `Boot` | Stateless or boot-only; no tree presence needed | — |

**Naming rule (must).** The registered autoload name **must** end in
`Autoload` and **must never** equal a `class_name`. Types used across the code
are the `class_name` (`GameState`, `GameClock`, …, unchanged from
`architecture.md` § API Boundaries); the autoload name is used only by `Boot`
(D3). Rationale: keeps the global name out of system code by construction and
avoids the `class_name`/autoload clash (Verification V1 — assumed, NOT
SOURCEABLE). The autoload names are ‡ (this ADR proposes them).

**Adding a tenth autoload** requires amending this ADR with the P/B/G test row.

### D2. Autoload construction, `process_mode` and boot order

**Construction (must).** An autoload's `_init()`, `_enter_tree()` and
`_ready()` **must never** perform I/O, read another autoload, or subscribe to
anything. All real initialisation happens in `setup(ctx: ServiceContext)`,
called by `Boot`. This makes the registration order irrelevant to behaviour
(V2 is then only about processing order).

**`process_mode` (must).** Every autoload **must** set `process_mode`
explicitly in its `_init()`; inheriting from `root` is forbidden. The values
belong to **ADR-0002**; until it is `Accepted` the provisional table is the
one `architecture.md` § Required ADRs gives for ADR-0002:

| Autoload | Provisional `process_mode` | Note |
|---|---|---|
| `ContentDB` | `PROCESS_MODE_ALWAYS` | Does not process; explicit only to forbid inheritance |
| `GameState`, `GameClock`, `InputRouter`, `Settings`, `SaveService`, `SceneLoader`, `AudioDirector` | `PROCESS_MODE_ALWAYS` | 23 keeps its own per-player pause driven by `pause_opened` (QQ-06) |
| `SceneDirector` | **Open — ADR-0002** | `architecture.md` does not list 21 in either column; its timeline reads `GameClock`, so `ALWAYS` is safe if every timer is game time. Recorded as Open Item O1 |

**Processing order (must).** `GameClock` **must** set
`process_priority` to the lowest value used in the project
(`GameClock.PROCESS_PRIORITY := -1000` ‡) so its Δ_juego is computed before
any consumer reads it in the same frame, independent of tree order (V2).

**Boot order.** `Shell` is the main scene; its child `Boot` runs once, in
`_ready()`, synchronously, in this order (amends § Data Flow 4 by placing
`GameClock`, which that list omits):

```text
 0  Boot builds the platform objects: BuildFlavor, Log sink, RealClock, FatalErrorHandler
    (debug or release variant), FileStore, then an empty ServiceContext (D3)
 1  ContentDB.setup(ctx)      → load narrative/*        fail → fatal CONTENIDO_INVALIDO ‡
 2  GameState.setup(ctx)      → load state/flags.json   fail → fatal (CA-26 of 3)
 3  GameClock.setup(ctx)      → reads nothing; starts at now() = 0
 4  DataValidator.run(ctx)    → debug and CI only (QQ-14 → ADR-0005)
 5  InputRouter.setup(ctx)    → input/default_bindings.json; subscribes to Settings "applied"
 6  Settings.setup(ctx)       → defaults + user file → Listo → «ajustes aplicados»
                                (1 imports `controles`; 23 is not started yet: it reads
                                 Settings directly in step 7, so no ramp is lost)
 7  AudioDirector.setup(ctx)  → after 3 and 6
 8  SceneLoader.setup(ctx)    → validates load_transitions.json  fail → DATOS_ESCENA_INVALIDOS
 9  SceneDirector.setup(ctx)  → director/scenes.json + director/director_config.json (ADR-0005 D1; invalid scenes dropped)
10  SaveService.setup(ctx)    → inspect() → result kept for 27
11  Shell.setup_ui(ctx)       → configures HUD, Subtitles, PauseMenu, Curtain (D6)
12  ctx.freeze()              → from here the global context is read-only
13  SceneLoader.request_title()  → title.tscn into WorldSlot
```

A step that calls the fatal handler **must** stop the sequence (later steps
are not run). In release builds the handler shows the panel (D8); the
application is not closed.

### D3. `Boot` is the single composition root; `ServiceContext` is the injection unit

**Composition roots (must).** Only `src/core/boot/boot.gd` **must** name an
autoload (`GameStateAutoload`, …). `Shell` and every scene root receive the
context from `Boot`/`SceneLoader`; they **must never** name an autoload,
call `get_node("/root/…")`, or use `Engine.get_singleton()` for project
services. This tightens `architecture.md` § Module Ownership, which also
allowed "the `configurar(ctx)` of each scene": with the context passed in,
scene roots no longer need the names (recorded in § Contradictions).

**`ServiceContext` ‡** is a `RefCounted` with typed fields, filled by `Boot`
and frozen at step 12. A scene root derives a **scene context** from it with
`for_scene()`; the global part is shared, never copied.

```gdscript
# src/core/composition/service_context.gd
## Typed bag of injected services. Built by Boot; read-only after freeze().
class_name ServiceContext extends RefCounted

# --- Platform (layer 0) -------------------------------------------------
var logger: LogSink                    # push_* wrapper; tests use RecordingLog (not `log`: shadows the builtin)
var flavor: BuildFlavor                # debug / release policy, set in step 0 (ADR-0005 O2)
var real_clock: RealClock         # unscaled real time (T_cap, Settings debounce)
var fatal: FatalErrorHandler           # D8
var files: FileStore                   # user:// and res:// access; tests use MemoryFileStore

# --- Foundation (layer 1) and Core (layer 2): the 9 autoloads ------------
var content: ContentDB
var state: GameState
var clock: GameClock
var input: InputRouter
var settings: Settings
var audio: AudioDirector
var save: SaveService
var scenes: SceneLoader
var director: SceneDirector

# --- Output ports into Shell (persistent presentation, D6) ---------------
var ui: UiPorts                        # prompt_sink, reading_screen, hint_note_host, error_panel
var flash_guard: FlashGuard            # ADR-0007 D9 limiter, built by Boot on real_clock (ADR-0014 OI-5); used by 21, 24, 28, 29

# --- Per-scene part: null in the global context --------------------------
var scene: SceneServices = null

var _frozen: bool = false

## Seals the global context. Any later assignment is a programming error.
func freeze() -> void:
    _frozen = true

func is_frozen() -> bool:
    return _frozen

## Returns a new context sharing every global reference plus `services`.
## The global context itself is never mutated by a scene.
func for_scene(services: SceneServices) -> ServiceContext:
    var c := ServiceContext.new()
    c.logger = logger; c.flavor = flavor; c.real_clock = real_clock; c.fatal = fatal; c.files = files
    c.content = content; c.state = state; c.clock = clock; c.input = input
    c.settings = settings; c.audio = audio; c.save = save
    c.scenes = scenes; c.director = director; c.ui = ui; c.flash_guard = flash_guard
    c.scene = services
    c._frozen = true
    return c

## Hard-dependency guard used at the top of configurar(). Returns false and
## reports through `fatal` (debug: stop; release: scene load failure of 4).
func require(owner: StringName, deps: Array[StringName]) -> bool:
    for d in deps:
        if _resolve(d) == null:
            fatal.raise_fatal(&"DEPENDENCIA_AUSENTE", {"owner": owner, "dep": d})
            return false
    return true

func _resolve(path: StringName) -> Object:
    # "state", "scene.interaction", "ui.prompt_sink" … — dotted lookup, boot/load time only.
    var target: Object = self
    for part in String(path).split("."):
        if target == null:
            return null
        target = target.get(part)
    return target
```

```gdscript
# src/core/composition/scene_services.gd
## Per-scene services, built by the scene root before any configurar() call.
class_name SceneServices extends RefCounted

var player: Player                     # 2  (C2)
var interaction: InteractionSystem     # 7  (F1)
var pocket: PocketService              # 20 (F2)  port, implemented by the Pocket node
var computer: ComputerService          # 19 (F3)  port: compose_i01(), V01 receiver
var puzzles: PuzzleFramework           # 9  (F4)
var view_gates: ViewGateProvider       # 9  (F4)  port (D5)
var box: BoxPresenter                  # 10 (F4)  port (D5); null in recepcion
var hints: HintService                 # 17 (F5)
var puzzle_writer: FactWriter          # 9's writer, built by the scene root with GameState.writer_for(9) (ADR-0010 OI-1); only 9 reads it
var hint_panel: HintPanelProvider      # 17 → pulled by 25 (D6)
var surface_fx: SurfaceFx              # 29 output port (D6); null-safe NullSurfaceFx if absent
var atmosphere: Atmosphere             # 28 (layer 4), only for tests/debug; nobody calls it (D11)
var audio_index: AudioSceneIndex       # 23: markers with audio_id, AudioRoomVolume, surface tags; built by the scene root (ADR-0008 OI-6)
```

**The `configurar()` contract (must).** Every system node in a game scene
exposes exactly one entry point, the `configurar()` of the GDDs (parameter ‡):

```gdscript
## Stores injected references, subscribes to the bus, registers handlers.
## Called by the scene root, synchronously, in the order of D4.
func configurar(ctx: ServiceContext) -> void
```

Rules for implementers:

1. `_ready()` **must** only do local work (own children via `@onready var x:
   T = %X`, own data). It **must never** read a service: when `_ready()` runs
   the context has not been delivered yet.
2. `@onready` **must** be used only for the node's own subtree (`%Unique`
   names). Cross-system references **must** come from `ctx`, never from a
   `NodePath` into another system's subtree.
3. `configurar()` **must** start with `ctx.require(&"<system>", [...])` listing
   the system's **hard** dependencies (as declared by the dependent, per
   `architecture.md` § dependencias duras), and **must** treat soft ones as
   nullable with an `if x != null` guard or a null object.
4. `configurar()` **must** copy the references it needs into typed member
   variables and **must never** keep `ctx` itself beyond the call (keeps the
   dependency list visible in the member declarations and prevents
   service-locator use at runtime).
5. Inside `configurar()` a system **may** call only autoload services and
   systems already configured earlier in the D4 order (in practice: 7's
   `registrar_manejador`/`registrar_receptor`). Calls to F2–F4 services
   **must** wait until "escena lista". **Exemption (ADR-0010 D12):** 9's
   restore-at-configure may call `BoxPresenter.set_final_pose(n)` (a pose
   set on 10's adapter, no logic of 10 runs).
6. Every bus subscription and every `connect()` to a node outside the
   system's own subtree **must** go into a `SubscriptionBag` released in
   `_exit_tree()` (TR-scene-009: subscriber count back to boot value after 10
   cycles; GameState's `is_instance_valid` check is the safety net, not the
   mechanism).

```gdscript
# Example: 20 Pocket (F2). Hard deps per GDD 20: 3, 4, 7, 18.
class_name Pocket extends Node3D

var _state: GameState
var _content: ContentDB
var _interaction: InteractionSystem
var _player: Player
var _prompt: PromptSink                # soft (ui port)
var _subs := SubscriptionBag.new()
@onready var _lid: AnimationPlayer = %LidAnimation

func configurar(ctx: ServiceContext) -> void:
    if not ctx.require(&"pocket", [&"state", &"content", &"scenes", &"scene.interaction", &"scene.player"]):
        return
    _state = ctx.state
    _content = ctx.content
    _interaction = ctx.scene.interaction
    _player = ctx.scene.player
    _prompt = ctx.ui.prompt_sink if ctx.ui != null else null
    _interaction.registrar_manejador(&"A03", _as_handler())  # 7 is F1: configured before; InteractionHandler adapter (ADR-0011 D6)
    _subs.notice(_state, &"lectura_completada", _on_lectura_completada)
    _subs.signal_(_player.objeto_soltado, _on_objeto_soltado)

func _exit_tree() -> void:
    _subs.release_all()
```

`SubscriptionBag` ‡ (`src/core/composition/subscription_bag.gd`) records
`(GameState, handle)` pairs and `(Signal, Callable)` pairs and undoes them;
`release_all()` is idempotent.

**Autoloads are injected too.** `setup(ctx)` follows rules 3, 4 and 6: an
autoload copies the peers it needs (e.g. `Settings` keeps `files`,
`real_clock`, `fatal`, `logger`; `SceneDirector` keeps `state`, `clock`,
`input`, `scenes`, `content`, `settings` as a `SettingsReader` for
`reducir_movimiento` (ADR-0017 A1)). Tests call `setup()` on a fresh, non-registered
instance with a context of doubles (D9). No autoload reads another autoload by
global name, ever.

### D4. Sub-layers and the allowed direct calls

Two channels, never mixed:

- **Notices** ("something happened") **must** go through the bus of 3
  (ADR-0001), in any direction between any layers.
- **Direct calls** ("do this / tell me this now") **must** go only to a
  **strictly lower sub-layer** (or a lower layer), through a reference obtained
  from `ctx`. The only same-sub-layer direct calls allowed are the 9⇄10 port
  pair (D5). No direct call ever goes up, except through an **output port**
  (D6).

Sub-layers (from `architecture.md` § System Layer Map, adopted unchanged):

| Layer | Sub-layer | Systems | Configured in a scene? |
|---|---|---|---|
| 0 Platform | — | `LogSink`, `RealClock`, `FileStore`, `FatalErrorHandler`, `NoticeChannel`, `DataValidator` | No (Boot) |
| 1 Foundation | — | 3 `GameState`, `GameClock`, 1 `InputRouter`, 18 `ContentDB` | No (autoload) |
| 2 Core | C1 | 6 `Settings` | No (autoload) |
| | C2 | 2 `Player` (scene), 4 `SceneLoader` (autoload) | 2: yes |
| | C3 | 5 `SaveService`, 23 `AudioDirector` | No (autoload) |
| 3 Feature | F1 | 7 `InteractionSystem` | Yes |
| | F2 | 20 `Pocket` | Yes |
| | F3 | 19 `Computer` | Yes |
| | F4 | 9 `PuzzleFramework`, 10 `Box` | Yes |
| | F5 | 8 `Access`, 11–16 controllers, 17 `HintService`, 21 `SceneDirector` (autoload), 22 `CallController` | Yes, except 21 |
| 4 Presentation | — | 24, 25, 26, 27 (Shell / title), 28 `Atmosphere`, 29 `SurfaceFx` (scene) | 28, 29: yes |

**Allowed direct calls** (every signed call in the GDDs; anything not in this
table is forbidden and goes through the bus):

| Caller (sub-layer) | May call directly | Via |
|---|---|---|
| 4 (C2) | 2 `colocar()` | `ctx.scene.player`, delivered by the scene root |
| 5 (C3) | 4 (load, full unload), 3 snapshot/restore | `ctx.scenes`, `ctx.state` |
| 23 (C3) | 6; 2 `rayo_vision()` read, bind window only (ADR-0012 OI-2) | `ctx.settings`, bound scene context |
| 7 (F1) | 1, 2, 4, 18; 3 read only (`get_fact_at`, `resolve_fact`); 6 read (`multiplicador_pie`, `pie_persistente`) (ADR-0011 A-2) | `ctx` |
| 20 (F2) | 7, 2, 3 (own facts), 18 | `ctx`, `ctx.scene` |
| 19 (F3) | 20 `has_item`, `otorgar_sesion`; 7; 1; 3 (`correos_leidos`); 2 `HAND_TYPE` (ADR-0012 OI-2) | `ctx.scene.pocket`, … |
| 9 (F4) | 19 `compose_i01`, 20 `has_item`, 7, 10 via `BoxPresenter`, 3 (own facts) | `ctx.scene.computer`, `.pocket`, `.box` |
| 10 (F4) | 9 via `ViewGateProvider`, 7 | `ctx.scene.view_gates` |
| 8 (F5) | 20 `otorgar("A05")`, 7, 4; 2 `reproducir_gesto(HAND_CARD_SWIPE)`, `sostener` via 20 (ADR-0012 OI-2) | `ctx.scene.pocket`, … |
| 17 (F5) | 9 `list_puzzles`, `get_hints`, `request_hint` | `ctx.scene.puzzles` |
| 21 (F5, autoload) | 7 `cerrar_modos()`, 4 (full unload), 1 (`sin control` handoff) | bound scene context (D6) |
| 22 (F5) | 7, 1, 3 (own facts); 2 `ANIM_PHONE_PICKUP`, `HAND_PHONE_PUTDOWN`, `reposo()` (ADR-0012 OI-2) — never 5: the seal is notice-driven (GDD 5 rule 11, GDD 22 rule 3; ADR-0004 OI-2). `request_save` callers are 25 and `Shell` only | `ctx` |
| 11–16 (F5) | **only** their `PuzzleServices` (D7) | built by 9 |
| 24, 25, 26 (Presentation, Shell) | 7 `get_target()` / `duracion_pie()` (24); `HintPanelProvider` (25); 6, 1, 18 | bound scene context (D6) |
| 28 (Presentation) | 2 `pose_con_retardo`, `giro_acumulado` (read) | `ctx.scene.player` |

**Contract signals** (`architecture.md` § contradicciones, row "Señales de
Godot"): a provider's signal may be connected by its direct consumer when the
GDD signs it (2 → 7, 8, 20, 23; controller `elements_changed` → 7 through 9).
The consumer connects, in its `configurar()`, through its `SubscriptionBag`.
Signals **must never** connect two systems of the same sub-layer.

### Architecture Diagram

```text
                          ┌──────────────────────────── Shell (main scene, never unloaded) ──┐
                          │ Boot ──builds──► ServiceContext (global, frozen)                  │
                          │ HUD: InteractionPrompt(24) HintNote(17 UI) ReadingScreen(20 UI)   │
                          │ Subtitles(26)  PauseMenu(25)+OptionsComponent  Curtain+ErrorPanel │
                          └──┬──────────────────────────────────▲──────────────────────────────┘
       ctx.ui output ports   │ implements PromptSink,           │ bind_scene(scene_ctx) /
       (D6) ◄────────────────┘ ReadingScreen, HintNoteHost,     │ unbind_scene()   (pull, downward)
                               ErrorPanel                       │
 ┌─ WorldSlot: planta.tscn (new instance per load) ─────────────┴──────────────────────────────┐
 │ PlantaRoot ──builds──► SceneServices ──► ctx.for_scene() ──► configurar(ctx) in D4 order       │
 │                                                                                              │
 │  F5  Access(8)   HintService(17)   CallController(22)   P1..P6 controllers ◄─ PuzzleServices  │
 │        │  │          │                  │                      ▲ (built by 9, D7)            │
 │        │  ▼          ▼                  │                      │                             │
 │  F4    │ ┌─────────────────────┐  ViewGateProvider  ┌──────────┴───┐                          │
 │        │ │ Box(10)             │◄──────────────────►│ Puzzle-      │──► SurfaceFx port ──► 29  │
 │        │ │ implements          │   BoxPresenter     │ Framework(9) │    (upward, output port)  │
 │        │ │ BoxPresenter        │                    │ impl.        │                          │
 │        │ └─────────┬───────────┘                    │ ViewGate…    │                          │
 │        │           │                                └──┬────┬──────┘                          │
 │  F3    │           │                    Computer(19) ◄──┘    │                                │
 │  F2    └──────────►│◄──────── Pocket(20) ◄──────────────────┘ (has_item)                     │
 │  F1                ▼              ▼                                                          │
 │              InteractionSystem(7) ──► PromptSink port (upward, output port)                   │
 │  C2          Player(2) ◄── colocar() ── SceneLoader     Atmosphere(28) + AtmosphereZone×rooms │
 └──────────────────┬───────────────────────────────────────────────────────────────────────────┘
                    │ direct calls only downward; notices in any direction ═══► bus
 ┌──────────────────▼──────────────────────────── autoloads (root children) ────────────────────┐
 │ C3 SaveService(5)  AudioDirector(23)   C2 SceneLoader(4)   C1 Settings(6)   F5* SceneDirector │
 │ L1 ContentDB(18)  GameState(3) ═══ bus ═══  GameClock  InputRouter(1)                        │
 └──────────────────┬───────────────────────────────────────────────────────────────────────────┘
 ┌──────────────────▼──── layer 0: LogSink · RealClock · FileStore · FatalErrorHandler ─────┐
 └───────────────────────────────────────────────────────────────────────────────────────────────┘
  * 21 is an F5 system hosted as an autoload; it reaches scene services only while bound (D6).
```

### D5. `ViewGateProvider` and `BoxPresenter`: the 9⇄10 cycle

GDScript single inheritance means `PuzzleFramework extends Node` cannot also
extend an abstract interface. **Ports are `@abstract` `RefCounted` classes,
implemented by a small adapter the provider owns** and hands out. Neither
side references the other's `class_name`.

```gdscript
# src/puzzles/ports/view_gate_provider.gd
## What 10 may ask of 9. Implemented by PuzzleFramework's adapter.
@abstract class_name ViewGateProvider extends RefCounted
## {state: OPEN|BLOCKED|SOLVED, missing_items: Array[StringName],
##  feedback_sfx: StringName, feedback_text_key: StringName}  (signature ‡, ADR-0010)
@abstract func get_view_gate(view_id: StringName) -> Dictionary

# src/puzzles/ports/box_presenter.gd
## What 9 may ask of 10. Implemented by Box's adapter.
@abstract class_name BoxPresenter extends RefCounted
@abstract func play_open(compartment: int) -> void
@abstract func set_final_pose(compartment: int) -> void
```

```gdscript
# inside src/puzzles/puzzle_framework.gd
class _ViewGateAdapter extends ViewGateProvider:
    var _owner: WeakRef                       # no strong cycle 9 → adapter → 9
    func _init(owner: PuzzleFramework) -> void:
        _owner = weakref(owner)
    func get_view_gate(view_id: StringName) -> Dictionary:
        var fw := _owner.get_ref() as PuzzleFramework
        if fw == null:
            return {"state": &"BLOCKED", "missing_items": [], "feedback_sfx": &"", "feedback_text_key": &""}
        return fw.get_view_gate(view_id)      # explicit return: 4.7 typed-override rule

var _gate_port: ViewGateProvider = null
## Called by the scene root while building SceneServices (before configurar).
## Lazily created so the adapter never depends on member-initialiser order.
func as_view_gate_provider() -> ViewGateProvider:
    if _gate_port == null:
        _gate_port = _ViewGateAdapter.new(self)
    return _gate_port
```

`Box` exposes `as_box_presenter() -> BoxPresenter` the same way. The scene
root writes both into `SceneServices` **before** any `configurar()`, so 9 can
be configured before 10 (TR-scene-011) and still hold its `BoxPresenter`.
Rules: adapters **must** hold a `WeakRef` to their owner and return a safe
default when it is gone; the ports **must** stay in `src/puzzles/ports/`, a
folder neither 9 nor 10 owns, so neither file imports the other.

**Configuration order in `planta` (must)** — TR-scene-011 plus this ADR:

```text
scene root: build SceneServices (refs + ports) ─► ctx.for_scene(services)
  ─► 2 Player.configurar ─► 7 ─► 9 (validates puzzles.json, configures P1..P6)
  ─► 20 ─► 19 ─► 10 ─► 8 ─► 17 ─► 22 ─► 29 SurfaceFx ─► 28 Atmosphere
  ─► SceneLoader: director.bind_scene(ctx), shell.bind_scene(ctx) ─► n_ret = 0 ─► «escena lista»
```

The order is data in the scene root script (`CONFIG_ORDER: Array[StringName]`
‡), checked by an integration test, not by reading the tree.

### D6. Upward calls only through output ports; persistent services bind to scenes

**Output ports (dependency inversion).** Where a GDD signs a call from a
lower layer to a higher one, the **interface belongs to the caller's layer**
and the higher layer implements it; the composition root injects it. The
caller **must** treat the port as soft (null object if absent) — none of
these calls is on a hard-dependency path of the caller.

| Port ‡ | Defined in (caller side) | Implemented by | Callers | Injected via | Null object |
|---|---|---|---|---|---|
| `PromptSink` (`mostrar_pie`, `ocultar_pie`) | `src/interaction/ports/` | 24 `InteractionPrompt` (Shell) | 7, 20 | `ctx.ui.prompt_sink` | `NullPromptSink` (log once) |
| `ReadingScreen` | `src/systems/pocket/ports/` | 20's reading UI (Shell HUD) | 20 | `ctx.ui.reading_screen` | — (hard for 20; `require`) |
| `HintNoteHost` | `src/systems/hints/ports/` | 17's `HintNote` (Shell HUD) | 17 | `ctx.ui.hint_note_host` | `NullHintNoteHost` |
| `SurfaceFx` (11 operations: GDD 29's 10 + `set_floor_marks`; signatures in ADR-0015) | `src/puzzles/ports/` | 29 node in the scene | 9, 12, 15 | `ctx.scene.surface_fx` | `NullSurfaceFx` (TR-atmos-002 analogue: works without 29) |
| `ErrorPanel` | `src/core/composition/` | Curtain + error panel (Shell, owned by 4) | release `FatalErrorHandler` | `ctx.ui.error_panel` | — |

**Pull instead of push for 17 → 25.** The hints panel is hosted by 25 but
belongs to 17. 17 **must never** call 25; it publishes a
`HintPanelProvider` port in `SceneServices.hint_panel`, and 25 pulls it from
the bound scene context when the player opens the "Pistas" tab. With no
bound scene (title) the tab is hidden.

**Bind / unbind protocol** — for the persistent consumers of per-scene
services (`SceneDirector`, `AudioDirector` (23, reads `scene.audio_index`;
ADR-0008 OI-6) and `Shell`, which fans out to 24, 25, 26):

```gdscript
# src/core/composition/scene_bindable.gd
## Implemented by persistent services that use per-scene services.
@abstract class_name SceneBindable extends RefCounted
## Called by SceneLoader after the last configurar() and before «escena lista».
@abstract func bind_scene(scene_ctx: ServiceContext) -> void
## Called by SceneLoader at the start of any unload, before the instance is freed.
## Must drop every reference to scene services and release scene subscriptions.
@abstract func unbind_scene() -> void
```

(`SceneDirector`, `AudioDirector` and `Shell` are Nodes, so they hand out an adapter, as in
D5.) Rules: `SceneLoader` **must** call `unbind_scene()` on every bound
consumer before `queue_free()` of the world scene, and TR-scene-002's
"21 inactive during full unload" is implemented as "unbound". A persistent
service **must never** cache a scene service outside the bind window.

### D7. Puzzle isolation: no puzzle reaches another puzzle

Controllers 11–16 (`PuzzleController` subclasses, ADR-0010) **do not get a
`ServiceContext`**. `PuzzleFramework` builds one `PuzzleServices` per
controller in its `configurar()`, containing only what that controller's GDD
declares:

```gdscript
# src/puzzles/puzzle_services.gd
## The whole world as a puzzle controller sees it. No writer, no bus, no peers.
class_name PuzzleServices extends RefCounted
var clock: GameClockReader            # read-only view: now(), delta(), is_paused()
var settings: SettingsReader          # read-only view: get_setting()
var content: ContentDB                # read-only by construction
var pocket: PocketQuery = null        # has_item() only        — P1 (11)
var composer: I01Composer = null      # compose_i01()          — P1 (11)
var box: BoxPresenter = null          # play_open/set_final_pose — P3–P6 (13–16)
var surface_fx: SurfaceFx = null      # P2 (12), P5 (15)
var interaction_query: InteractionQuery = null   # P3 (13): read-only view of 7 ‡ (ADR-0011)
```

| Controller | Fields set (from `architecture.md` § System Layer Map) |
|---|---|
| P1 (11) | `pocket`, `composer` |
| P2 (12) | `surface_fx` |
| P3 (13) | `box`, `interaction_query` |
| P4 (14), P6 (16) | `box` |
| P5 (15) | `box`, `surface_fx` |

Rules (must / must never):

- A controller **must never** hold a reference to `PuzzleFramework`, to
  another `PuzzleController`, to `GameState`, or to `InteractionSystem`
  (writer side). It talks to 9 only by return values (`Verdict`,
  `handle_activation`) and by its `elements_changed` signal.
- No field of `PuzzleServices` **may** expose a controller, a list of
  controllers, or a puzzle's public state. Cross-puzzle facts (e.g. P6
  depending on `caja_c1`…`c4`) reach a controller only as the `flags`
  argument 9 passes to `configure(def, flags)`, already filtered to the facts
  its definition names.
- Each controller lives in its own folder `src/puzzles/p<N>_<slug>/`; a
  script under one folder **must never** `preload`/`load` or name a
  `class_name` from another `p<N>_*` folder (checked in CI, D10).
- `GameClockReader`/`SettingsReader` are read-only adapters; a controller
  cannot pause, write settings or start a timer outside `GameClock`
  (TR-puzzles-014).

### D8. Injected fatal error handler

```gdscript
# src/core/composition/fatal_error_handler.gd
## Sink for unrecoverable data/catalog errors. Systems never decide how to die.
@abstract class_name FatalErrorHandler extends RefCounted
## code: CATALOGO_INVALIDO | DATOS_ESCENA_INVALIDOS | DEPENDENCIA_AUSENTE | CONTENIDO_INVALIDO ‡ | …
## detail: {param, value, owner, …} — the offending parameter is mandatory when one exists.
@abstract func raise_fatal(code: StringName, detail: Dictionary) -> void
@abstract func has_failed() -> bool
```

| Variant | Created by `Boot` when | Behaviour |
|---|---|---|
| `DebugFatalHandler` | `OS.is_debug_build()` | `push_error` with code + detail, sets `has_failed`, then `assert(false, …)` so the editor stops at the call site (TR-settings-019 "en debug detiene") |
| `ReleaseFatalHandler` | release export | `push_error` (log), sets `has_failed`, and asks `ctx.ui.error_panel` to show the panel of 4/27 with a **hard-coded, 18-independent** message per code and the "Volver al título" / quit row; never calls `quit()` (`architecture.md` § Data Flow 4) |
| `RecordingFatalHandler` | tests | Appends `(code, detail)` to `calls`; never stops |

Rules: systems **must** report unrecoverable data errors only through
`ctx.fatal`; they **must never** call `get_tree().quit()`, `assert` on data,
or show UI themselves. A scene-time fatal (e.g. 9's validation, TR-puzzles-005)
**must** also be reported to 4 as a load failure (TR-scene-011); the handler
does not replace the load-failure path, it records and surfaces it. Fatal
message strings live in `src/core/composition/fatal_messages.gd` (constants;
Spanish UI text is allowed there as data that 18 cannot corrupt).

### D9. Test doubles

Hand-written doubles in `tests/doubles/` (not a test root: gdUnit4 only runs
`test_*` suites; doubles are plain scripts). gdUnit4 `mock()`/`spy()` **may**
be used for call verification but no suite **may** depend on it to construct
a system (V5, NOT SOURCEABLE).

| Double ‡ | Replaces | Built as | Key behaviour |
|---|---|---|---|
| `FakeGameState` | `GameState` | subclass of `GameState`, `setup()` skipped | In-memory facts from a fixture dict; synchronous notice delivery; records `set_fact` writer IDs |
| `FakeClock` | `GameClock` / `GameClockReader` | subclass | `advance(ticks: int)`; `set_paused(b)`; integer ticks (TR-settings-021) — already listed in layer 0 by `architecture.md` |
| `FakeRealClock` | `RealClock` | subclass | Same, unscaled |
| `MemoryFileStore` | `FileStore` | subclass | Dict of path → bytes; can inject read/rename failures (ADR-0004 tests) |
| `RecordingLog` | `LogSink` | subclass | Collects lines; asserts on log-and-continue paths |
| `RecordingFatalHandler` | `FatalErrorHandler` | concrete | See D8 |
| `FakeInputRouter`, `FakeSettings`, `FakeContentDB`, `FakeSceneLoader`, `FakeSaveService`, `FakeAudioDirector`, `FakeSceneDirector` | each autoload | subclass, public methods overridden | Record calls, return scripted values |
| `StubViewGateProvider`, `RecordingBoxPresenter`, `RecordingSurfaceFx`, `RecordingPromptSink`, `StubPocketQuery`, `StubI01Composer` | the ports | concrete subclasses of the `@abstract` ports | Scripted answers / recorded calls |

```gdscript
# tests/doubles/test_contexts.gd
## Factory for contexts made only of doubles. Overrides replace single services.
class_name TestContexts extends RefCounted

static func make(overrides: Dictionary = {}) -> ServiceContext:
    var c := ServiceContext.new()
    c.logger = overrides.get(&"logger", RecordingLog.new())
    c.real_clock = overrides.get(&"real_clock", FakeRealClock.new())
    c.fatal = overrides.get(&"fatal", RecordingFatalHandler.new())
    c.files = overrides.get(&"files", MemoryFileStore.new())
    c.state = overrides.get(&"state", FakeGameState.new())
    c.clock = overrides.get(&"clock", FakeClock.new())
    # … one line per field, same pattern …
    c.freeze()
    return c

static func make_scene(services: SceneServices, overrides: Dictionary = {}) -> ServiceContext:
    return make(overrides).for_scene(services)
```

Rules: a unit suite **must** build its system with `TestContexts` and
**must never** touch a registered autoload (gdUnit4 runs inside the project,
so autoloads exist at test time — using one makes the test order-dependent).
Doubles that are `Node`s **must** be freed by the suite (`auto_free()`), or
the run exits 101 for orphans (`current-best-practices.md` § Command Line).

### D10. Enforcement

Helpers emit observations; the CI step fails on a non-empty observation list
(per `CLAUDE.md` § Context Management — the script never judges).

| Check ‡ | Where | Observes |
|---|---|---|
| `tools/ci/list_autoload_refs.sh` | CI | Any `*Autoload` identifier or `/root/` path outside `src/core/boot/` |
| `tools/ci/list_puzzle_cross_refs.sh` | CI | Any `preload`/`load`/`class_name` of a `p<N>_*` folder from another `p<N>_*` folder, or a controller script naming `PuzzleFramework`, `GameState`, `InteractionSystem` |
| `tests/unit/composition/test_layer_calls.gd` | gdUnit4 | Members of each system's script whose type is a same/higher sub-layer class not in the D4 table (reads `get_script().get_script_property_list()` ‡ — mechanism to confirm in implementation) |
| `tests/integration/composition/test_planta_config_order.gd` | gdUnit4 | `CONFIG_ORDER` respected; every `configurar()` ran once; binds called before «escena lista» |

### D11. QQ-13 resolved: Atmosphere (28) is a scene node

**Decision:** `Atmosphere` is a node at the root of each game scene
(`planta`, `recepcion`), with one `AtmosphereZone` per room registering its
lights, windows and mirror with it during `configurar()`. It is not an
autoload. TR-atmos-001 is **rejected as written** and replaced by this.

Why GDD 28 DT-1's argument ("the state — blackout, rain — crosses scenes; the
autoload avoids losing the blackout when changing scene") does not hold in
this architecture:

1. **The rooms are not scenes.** office, corridor, archive, meeting_room and
   guardian_office are children of one `planta` instance (`architecture.md`
   § Árbol en ejecución). Walking between them never unloads anything, so a
   node at the `planta` root keeps the blackout across rooms. The "6 scenes"
   of TR-atmos-001 are 6 `AtmosphereZone`s, not 6 loads.
2. **Real loads already rebuild from facts.** The only loads are
   title → `planta` (new game / Continue), `planta` → `recepcion`, and the
   full unload. GDD 28 rule 21 already requires 28 to recompute its visible
   state from facts and from 21's resume orders after "Continuar", and TR-atmos-003
   says the state is volatile and not saved. A node rebuilt on «escena lista»
   is exactly that; an autoload would have to implement the same rebuild
   **and** an extra reset path, two paths for one behaviour.
3. **The real guardian of volatile scene state is 21**, which *is* persistent
   (`apagon_activo`, rule 12 for the delayed reflection). 28 receiving its
   orders by bus (TR-atmos-002) is unchanged.
4. **P/B/G test (D1):** not P (state derivable, not saved), not B (the title
   has no atmosphere), not G (owns nothing others need).

Ordering guarantee that makes it safe: 28 is configured (and subscribed)
before «escena lista» (D5 order), and 21 only emits its resume orders after
«escena lista» / «carga terminada», so no order is emitted into a scene
without a listener.

**Change required in GDD 28** (for `/propagate-design-change`, not done by
this ADR): DT-1 and the systems-table row ("Autoload `Atmosphere` +
`AtmosphereZone`") must read "scene node `Atmosphere` + `AtmosphereZone`,
see ADR-0009 D11". No rule, timing or limit of GDD 28 changes. ADR-0014
inherits this placement.

### Key Interfaces

| Interface ‡ | Kind | File (proposed) | Defined in |
|---|---|---|---|
| `ServiceContext` | `RefCounted` | `src/core/composition/service_context.gd` | D3 |
| `SceneServices` | `RefCounted` | `src/core/composition/scene_services.gd` | D3 |
| `UiPorts` | `RefCounted` (4 port fields) | `src/core/composition/ui_ports.gd` | D6 |
| `configurar(ctx: ServiceContext) -> void` | method on every scene system | — | D3 |
| `setup(ctx: ServiceContext) -> void` | method on every autoload | — | D2, D3 |
| `SubscriptionBag` | `RefCounted` | `src/core/composition/subscription_bag.gd` | D3 |
| `ViewGateProvider`, `BoxPresenter` | `@abstract RefCounted` | `src/puzzles/ports/` | D5 |
| `PromptSink`, `ReadingScreen`, `HintNoteHost`, `SurfaceFx`, `ErrorPanel`, `HintPanelProvider` | `@abstract RefCounted` | per D6 table | D6 |
| `SceneBindable` | `@abstract RefCounted` | `src/core/composition/scene_bindable.gd` | D6 |
| `PuzzleServices`, `GameClockReader`, `SettingsReader`, `PocketQuery`, `InteractionQuery` | `RefCounted` | `src/puzzles/` | D7 |
| `FatalErrorHandler` (+ Debug/Release) | `@abstract RefCounted` | `src/core/composition/` | D8 |
| `LogSink`, `RealClock`, `FileStore` | `RefCounted` | `src/core/platform/` | D3 |

Method signatures of the ports other than D5/D6/D8 are owned by the ADR of
the implementing system (ADR-0010, -0011, -0015, -0016); this ADR fixes only
that they exist, their direction and where they are injected.

### Implementation Guidelines

1. Only `src/core/boot/boot.gd` must name an autoload; autoload names end in `Autoload` and never equal a `class_name`.
2. Every autoload must set `process_mode` explicitly (values: ADR-0002) and must do no I/O, cross-autoload reads or subscriptions before `setup(ctx)`.
3. Every scene system must expose `configurar(ctx: ServiceContext) -> void`, begin it with `ctx.require(...)` for hard dependencies, copy references into typed members and never retain `ctx`.
4. `_ready()` must never read a service; `@onready` must reference only the node's own subtree.
5. Direct calls must go only to a strictly lower sub-layer through a `ctx` reference, except the 9⇄10 port pair; upward calls must go through an output port defined on the caller's side and implemented above.
6. Notices must always go through the bus of 3.
7. Every subscription or external `connect()` must be registered in a `SubscriptionBag` released in `_exit_tree()`.
8. Persistent services must reach scene services only between `bind_scene()` and `unbind_scene()`.
9. Puzzle controllers must receive only `PuzzleServices`; they must never reference another controller, `PuzzleFramework`, `GameState` or the writer side of 7.
10. Unrecoverable data errors must go to `ctx.fatal`; systems must never quit, assert on data or show error UI.
11. Unit suites must build systems with `TestContexts` doubles and must never use a registered autoload.

## Alternatives Considered

### Alternative 1: Autoloads named directly everywhere (classic Godot singletons)

- **Description**: Systems call `GameState.get_fact(...)` by global name; no context.
- **Pros**: Least code; idiomatic in small Godot projects; editor autocompletion.
- **Cons**: Every unit test runs against the real registered autoload (shared
  state across suites, file I/O at `setup`); violates `coding-standards.md`
  "dependency injection over singletons", TR-settings-021 and TR-hints-001;
  hides the dependency list; per-scene services still need a lookup.
- **Estimated Effort**: −30 % now, much more later (retrofitting DI after S0).
- **Rejection Reason**: Untestable by construction and contradicts three TRs.

### Alternative 2: Service locator (`Services.get(&"state")`)

- **Description**: One autoload registry; systems ask it for services at any time.
- **Pros**: One global; doubles registered per test; flexible.
- **Cons**: Untyped (`Variant` returns, casts everywhere); dependencies resolved
  at runtime, anywhere, so the D4 layer rule cannot be checked statically; a
  registry entry for a freed scene service dangles (TR-scene-009).
- **Estimated Effort**: Similar to the chosen approach.
- **Rejection Reason**: Loses typing and the "dependencies visible in member
  declarations" property; `ctx.require` + rule 4 (never retain `ctx`) is a
  locator used only at composition time, which keeps its benefit without its cost.

### Alternative 3: Exported `NodePath`s / `@export var x: Node` wired in the editor

- **Description**: Each system exports references set in the `.tscn`.
- **Pros**: Visible in the inspector; no code for wiring.
- **Cons**: Cannot reference autoloads or Shell nodes from inside `planta.tscn`;
  wiring lives in scene files that are hard to diff and review; tests must
  build trees.
- **Estimated Effort**: Lower for intra-scene refs, impossible for cross-scene.
- **Rejection Reason**: Covers only half of the graph. Still allowed for a
  system's **own** subtree (via `%Unique` + `@onready`, D3 rule 2).

### Alternative 4: Atmosphere as autoload (GDD 28 DT-1, TR-atmos-001)

- **Description**: `Atmosphere` autoload holds the volatile state; `AtmosphereZone` per room registers.
- **Pros**: Matches the GDD as written; no GDD change.
- **Cons**: Fails the P/B/G test; duplicates the rebuild-from-facts path GDD
  28 rule 21 already needs; adds a tenth persistent object that holds
  references to scene lights (dangling-reference risk on unload).
- **Estimated Effort**: Similar.
- **Rejection Reason**: D11.

### Alternative 5: Bus-only between all Feature systems (no direct calls)

- **Description**: The starting decision of `architecture.md`; every request becomes a notice.
- **Pros**: Simplest rule; no ports.
- **Cons**: Contradicts 15 signed synchronous calls (`has_item`, `get_view_gate`,
  `compose_i01`, `cerrar_modos` with a 2 s cap…) whose callers need an answer in
  the same frame.
- **Estimated Effort**: Higher (rewriting GDD contracts).
- **Rejection Reason**: Already rejected in `architecture.md`; recorded here for completeness.

## Consequences

### Positive

- Every system is constructible in a unit test with doubles only; the
  coding-standards DI rule becomes checkable (D10).
- Dependencies are visible as typed members; the layer rule is reviewable
  per file and partly checked in CI.
- The 9⇄10 cycle and the upward calls (24, 29, 25) have one uniform
  mechanism instead of exceptions.
- Persistent services cannot hold dangling references to a freed `planta`
  (bind window + `SubscriptionBag`), which is what TR-scene-009 measures.
- One fewer persistent object than GDD 28 asks for.

### Negative

- Boilerplate: a context class, adapters for every port (GDScript has no
  interfaces), a `require` list per system. Estimated ~25 small scripts in S0.
- `_resolve()` uses dotted string paths: a typo is caught at boot/load, not at
  parse time.
- Two concepts (`ServiceContext`, `PuzzleServices`) to learn; contributors
  must remember `_ready()` is too early for services.
- GDD 28 needs a change (DT-1), and `architecture.md` § Data Flow 4 and
  § Module Ownership need small amendments (§ Contradictions).

### Neutral

- Autoload names change to the `*Autoload` suffix; type names do not.
- Doubles live in `tests/doubles/`, a new folder outside the two test roots.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| R1 Contributors bypass `ctx` and name an autoload "just once" | High | Medium (test isolation lost) | D10 CI observation on `*Autoload` and `/root/`; naming rule makes the bypass conspicuous |
| R2 `@abstract` + inner adapter subclass misbehaves on 4.7.2 (V3) | Low | Medium | First S0 story writes `test_view_gate_adapter.gd`; fallback: non-abstract base with `push_error` bodies |
| R3 4.7 typed-override rule: an adapter method without explicit `return` fails to parse | Medium | Low | Sourced rule; parse check (`godot-parse-check.gd`) on every port file |
| R4 A persistent consumer touches a scene service after unbind (use-after-free) | Medium | High (crash in release) | `unbind_scene()` before `queue_free()`; adapters hold `WeakRef`; integration test of 10 load cycles |
| R5 Boot step order drifts from § Data Flow 4 when ADR-0002/0003/0005 land | Medium | Medium | Boot order is one table in `boot.gd` with a test asserting it; ADRs that change it amend D2 |
| R6 Same-frame ordering: `GameClock` delta read before update (V2) | Low | Medium | Explicit `process_priority`; `test_game_clock_priority.gd` |
| R7 GDD 28 owner disagrees with D11 | Low | Low | D11 changes placement only; reverting to an autoload is a local change (Rollback) |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| sistema-de-pistas.md (17) | TR-hints-001: `HintService` injected, no singleton/autoload of state | D1 rejected list; lives in `planta`, reached via `ctx.scene.hints`; panel via pull (D6) |
| ajustes-persistentes.md (6) | TR-settings-007: survives scene changes without dangling refs; scene subscribers unsubscribe on unload | D1 (autoload, P/B); D3 rule 6 `SubscriptionBag` |
| ajustes-persistentes.md (6) | TR-settings-019: invalid catalog → injected fatal handler, code `CATALOGO_INVALIDO` + offending parameter, text independent of 18 | D8 (`detail.param` mandatory; `fatal_messages.gd` constants) |
| ajustes-persistentes.md (6) | TR-settings-021: no real I/O, injected clock (integer ticks), replaceable error handler and log sink | D3 platform fields; D9 `MemoryFileStore`, `FakeRealClock`, `RecordingFatalHandler`, `RecordingLog` |
| escena-de-planta.md (4) | TR-scene-002: 1, 3, 6, 21, 23 persistent with the same instance id; 21 inactive during full unload | D1 (all five are autoloads); D6 unbind = inactive |
| escena-de-planta.md (4) | TR-scene-009: orphans and bus subscribers back to boot values after 10 cycles | D3 rule 6, D6 bind window; Validation T-I2 |
| escena-de-planta.md (4) | TR-scene-011: configuration order 7 → 9 → rest, synchronous | D5 configuration order + `CONFIG_ORDER` test |
| director-de-escenas.md (21) | TR-director-001: persistent, subscribed from boot | D1 row 9; D6 for its scene access |
| atmosfera-reactiva.md (28) | TR-atmos-001: autoload `Atmosphere` | **Rejected**; replaced by scene node (D11). TR-atmos-002/-003 (bus only, volatile, rebuilt from facts) are satisfied by it |
| documentos-y-bolsillo.md (20) | Baseline § 20 "Nodo/autoload propuesto": service with an injectable interface, not a singleton of game state | D1: scene node; `PocketService`/`PocketQuery` ports in `SceneServices`/`PuzzleServices` |
| shaders-y-efectos.md (29) | TR-shaders-015: `FxTarget` registry per scene; unknown `target_id` → `push_warning`, no failure | D1: `SurfaceFx` scene node; `FxTarget`s register with it in `configurar()`; callers reach it through the `SurfaceFx` output port with `NullSurfaceFx` fallback (D6) |
| marco-de-puzles.md (9) | TR-puzzles-014: injectable `GameClock` for every framework timer | `ctx.clock`; read-only `GameClockReader` in `PuzzleServices` (D7) |
| marco-de-puzles.md (9) + caja-y-compartimentos.md (10) | Accepted 9⇄10 cycle (`get_view_gate`, `play_open`, `set_final_pose`) | D5 ports and adapters |

Foundational in addition: constrains every GDD system through D3/D4.

## Performance Implications

- **CPU**: Zero per frame. Composition runs once at boot and once per scene
  load (≈ 30 `configurar()` calls, dotted lookups at load only). Adapter
  calls add one GDScript call per port call (`get_view_gate` per view open,
  not per frame); `get_target()` from 24 is a direct typed call.
- **Memory**: ~40 small `RefCounted` objects (contexts, ports, readers);
  negligible against any budget.
- **Load Time**: Not measurable against `T_cap` 10 s.
- **Network**: N/A.

## Migration Plan

No code exists; nothing to migrate. Doc follow-ups (not done by this ADR):
amend `architecture.md` § Data Flow 4 (GameClock step, steps 11–13) and
§ Module Ownership (composition roots, autoload names); GDD 28 DT-1 change
(D11); register `TR-atmos-001` as superseded in `tr-registry.yaml` at the next
`/architecture-review`.

**Rollback plan**: The decision is reversible per part. D11 can be reverted by
moving `Atmosphere` to an autoload behind the same bus subscriptions. The
naming rule (D1) is a rename. The injection pattern (D3) is the expensive one
to reverse; reverting it means Alternative 1 and losing unit isolation — the
reason to decide it before S0.

## Validation Criteria

gdUnit4 plan (`tests/unit/composition/`, `tests/integration/composition/`;
naming per `.claude/rules/test-standards.md`):

| ID | Suite ‡ | Proves | TR / decision |
|---|---|---|---|
| T-U1 | `test_service_context.gd` | `for_scene()` shares global refs, never mutates the global; `freeze()` sets read-only flag; `require()` reports the missing dotted dep to `RecordingFatalHandler` and returns false | D3 |
| T-U2 | `test_subscription_bag.gd` | `release_all()` removes every bus handle and signal connection on `FakeGameState`; idempotent | D3 rule 6, TR-settings-007 |
| T-U3 | `test_view_gate_adapter.gd` / `test_box_presenter_adapter.gd` | Adapter delegates; returns `BLOCKED` default after owner freed (WeakRef); parses under the 4.7 typed-override rule | D5, V3 |
| T-U4 | `test_puzzle_services.gd` | Each controller gets exactly the fields of the D7 table; readers expose no writer methods | D7 |
| T-U5 | `test_fatal_handlers.gd` | `RecordingFatalHandler` records `(CATALOGO_INVALIDO, {param})`; `ReleaseFatalHandler` calls `ErrorPanel` (recording double) and never `quit()` | D8, TR-settings-019 |
| T-U6 | `test_autoload_setup_isolation.gd` | Each autoload class: `new()` + `_ready()` with no `setup()` performs no I/O on `MemoryFileStore` and reads no other service; `process_mode` is not `INHERIT` | D2 |
| T-U7 | `test_game_clock_priority.gd` | `GameClock.process_priority` is the minimum in the project | D2, V2 |
| T-U8 | `test_layer_calls.gd` | No system script declares a member typed as a same/higher sub-layer class outside the D4 table | D4 |
| T-I1 | `test_planta_config_order.gd` | With all doubles for autoloads, a `planta` stub scene configures in `CONFIG_ORDER`, each once; `bind_scene` called before «escena lista» | D5, TR-scene-011 |
| T-I2 | `test_ten_load_cycles.gd` | 10 load/unload cycles: `FakeGameState` subscriber count and orphan node count back to baseline; every bound consumer unbound before free | TR-scene-009, D6, V4 |
| T-I3 | `test_boot_order.gd` | `Boot` with doubles calls `setup()` in D2 order and stops at the first fatal | D2 |

CI observations (D10) must be empty. **We will know this was right if**: by
the end of S0 every system story ships with unit tests that use only
`TestContexts`; T-I2 passes; and no story needed an exception to D4.

## Open Items

| ID | Item | Owner / route |
|---|---|---|
| O1 | ~~`process_mode` of `SceneDirector`~~ Resolved: ADR-0002 § process_mode table assigns `SceneDirector` `ALWAYS` on `GameClock` | ADR-0002 |
| O2 | (`SurfaceFx` closed by ADR-0015, 11 operations; `InteractionHandler`/`InteractionQuery` by ADR-0011.) Exact port method signatures for `PromptSink`, `SurfaceFx`, `HintPanelProvider`, `InteractionQuery`, `PocketQuery` | ADR-0011, -0015, -0016, -0010 |
| O3 | Mechanism for T-U8 (script property introspection) — confirm it works on 4.7.2, else replace by a CI text scan | Implementation, S0 |
| O4 | V1, V2, V4, V5 engine behaviours (NOT SOURCEABLE) — record observations in `docs/engine-reference/godot/` when the first S0 story runs | Implementation, S0 |
| O5 | Whether `recepcion` needs `SceneServices` beyond `player`, `interaction`, `atmosphere` (no puzzles there per TR-scene-011) | ADR-0003 |

### Contradictions detected (for `/architecture-review`)

1. **GDD 28 DT-1 / TR-atmos-001 vs `architecture.md`** (QQ-13): resolved in
   favour of the scene node (D11); GDD 28 needs the DT-1 change.
2. **`architecture.md` § Data Flow 4** omits `GameClock` from the Boot steps
   while § Module Ownership makes it a required autoload: D2 inserts it as step 3.
3. **`architecture.md` § Module Ownership "Regla de uso"** lets scene
   `configurar(ctx)` name autoloads; D3 narrows composition roots to `Boot`
   only (the context already carries them).
4. **Upward calls signed in GDDs** (7, 20 → 24 `mostrar_pie`; 9, 12, 15 → 29;
   17 → 25 panel) contradict the "calls only go down" rule of
   `architecture.md` § System Layer Map, which lists only intra-layer calls:
   resolved by output ports (D6), not by exceptions.
5. **Index layer map shows 21 as F5 but it is an autoload** listed with the
   Core persistents: kept as an F5 system hosted as an autoload, reaching
   scene services only while bound (D6).

## Related

- ADR-0001 Event bus and fact contract (related; not yet written)
- ADR-0002 Pause and game time (related; owns `process_mode` values; not yet written)
- ADR-0003 Scene loading, Shell and `sin control` handoff (enabled; bind/unbind and `CONFIG_ORDER`)
- ADR-0010, -0011, -0014, -0015, -0016, -0017 (enabled; own the port signatures)
- `docs/architecture/architecture.md` § System Layer Map, § Module Ownership, § Data Flow 4, § API Boundaries, QQ-13
- `docs/architecture/tr-baseline-provisional.md` (TRs in § GDD Requirements Addressed)
- `design/gdd/atmosfera-reactiva.md` DT-1 and rule 21
- `.claude/docs/coding-standards.md` (DI over singletons, testability)
