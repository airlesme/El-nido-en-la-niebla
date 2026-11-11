# Story 001: Costuras de plataforma — `LogSink`, `ErrorPolicy`, `FatalErrorHandler`, `TestContexts`

> **Epic**: Estado y bus de eventos
> **Status**: Done
> **Layer**: Foundation (piezas de capa 0 Platform, ADR-0009 D4)
> **Type**: Logic
> **Estimate**: M (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 4 (escritura inválida: en desarrollo detiene, en final registra) y regla 14 (catálogo ausente → no hay partida)
**Requirement**: `TR-state-004` (detención en dev / log en final), `TR-state-001` (fichero ausente → fatal) — soporte transversal
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Service composition (D3, D8, D9) · ADR-0001: Event bus and fact contract (Key Interfaces «injectable seams», G-8)
**ADR Decision Summary**: Los errores irrecuperables de datos van solo por un `FatalErrorHandler` inyectado (`Debug`/`Release`/`Recording`); todo log por `LogSink` y toda «detención en dev» por `ErrorPolicy`. Las suites unitarias construyen el sistema con `TestContexts.make()` y nunca tocan un autoload.
**ADR Version**: ADR-0009 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0009) — MEDIUM en `ErrorPolicy` (ADR-0001 V-ENG-4)
**Engine Notes**: la detención en dev usa `assert(false, …)` (enmienda 2026-11-11 de ADR-0009 D8 por V-ENG-4); en release `assert` se elimina, por eso `ErrorPolicy.fail` es no-op en release y `FatalErrorHandler` sigue registrando.

**Control Manifest Rules (this layer)**:
- Required: F-R09 (todo log por `LogSink`, todo dev-halt por `ErrorPolicy`; solo `src/core/error_policy_default.gd` nombra las llamadas del motor), F-R36 (errores irrecuperables solo por `ctx.fatal`), F-R37 (suites con `TestContexts`), F-R66 (debug decidido por `BuildFlavor` inyectado)
- Forbidden: `get_tree().quit()`, `assert` sobre datos o UI propia desde un sistema (ADR-0009 D8 Rules)
- Guardrail: ninguno de rendimiento

---

## Acceptance Criteria

*Derivados de ADR-0009 D8/D9 y de ADR-0001 (seams); el GDD solo fija el comportamiento observable (CA-06/CA-06b/CA-26):*

- [ ] `RecordingLog` recoge `(level, msg)` de `LogSink.line()` con `level ∈ {&"info", &"warn", &"error"}`; `RecordingFatalHandler` añade `(code, detail)` a `calls` y nunca detiene; `has_failed()` pasa a `true` tras la primera llamada.
- [ ] `ErrorPolicy` por defecto: `is_strict()` es `true` con `BuildFlavor` debug y `false` con release; en release `fail(msg)` no detiene (test con `BuildFlavor.new(false)`).
- [ ] `TestContexts.make()` devuelve un `ServiceContext` congelado con `logger`, `fatal`, `real_clock`, `clock`, `state` de dobles; un override sustituye un solo servicio. Ninguna suite nombra un `*Autoload`.
- [ ] `ServiceContext` gana los campos `logger: LogSink`, `fatal: FatalErrorHandler` (ADR-0009 D3) y `Boot.compose()` los rellena (Debug/Release según `BuildFlavor`).

---

## Implementation Notes

*Derived from ADR-0009 D8/D9 y ADR-0001 Key Interfaces:*

- Firmas fijadas: `LogSink.line(level: StringName, msg: String) -> void`; `ErrorPolicy.fail(msg: String) -> void`, `ErrorPolicy.is_strict() -> bool`; `@abstract FatalErrorHandler.raise_fatal(code: StringName, detail: Dictionary) -> void`, `has_failed() -> bool`. Códigos: `CATALOGO_INVALIDO`, `DATOS_ESCENA_INVALIDOS`, `DEPENDENCIA_AUSENTE`, `CONTENIDO_INVALIDO`.
- Rutas: `src/core/platform/log_sink.gd` (ADR-0009 tabla, `RefCounted`), `src/core/composition/fatal_error_handler.gd` + variantes, `src/core/error_policy_default.gd` (G-8). Mensajes fatales en `src/core/composition/fatal_messages.gd` (constantes; texto en español permitido ahí).
- `ReleaseFatalHandler` pide el panel a `ctx.ui.error_panel`, que **no existe** en M1 (UiPorts, ADR-0009 TODO): en esta historia registra con `push_error` y deja la llamada al panel detrás de un `null`-check documentado. *ADR-fallback*: si al implementar hace falta una firma de `UiPorts`, no se inventa: se anota como Open Item en ADR-0009.
- Dobles en `tests/doubles/` (no es raíz de tests): `RecordingLog`, `RecordingFatalHandler`, `TestContexts`. `FakeGameState`, `FakeClock`, etc. se añaden a `TestContexts` cuando exista la clase que reemplazan (una línea por campo, ADR-0009 D9).
- `FileStore` no entra aquí: lo crea contenido-y-datos 001 (su único primer consumidor).

---

## Out of Scope

- contenido-y-datos 001: `FileStore` / `MemoryFileStore`.
- Story 014: uso de `ctx.fatal` por `GameState` al arrancar.
- `UiPorts`/`ErrorPanel` real (épico de carga-de-planta / Shell).

---

## Files

- `src/core/platform/log_sink.gd`, `src/core/error_policy_default.gd` (y clase base `ErrorPolicy`)
- `src/core/composition/fatal_error_handler.gd`, `debug_fatal_handler.gd`, `release_fatal_handler.gd`, `fatal_messages.gd`
- `src/core/composition/service_context.gd`, `src/core/boot/boot.gd` (campos y composición)
- `tests/doubles/recording_log.gd`, `tests/doubles/recording_fatal_handler.gd`, `tests/doubles/test_contexts.gd`
- `tests/unit/state/platform_seams_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/platform_seams_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/estado-y-bus/story-002-notice-channel-core.md`, `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`, `production/epics/estado-y-bus/story-014-boot-wiring-state.md`, `production/epics/contenido-y-datos/story-001-file-store-and-json-text.md`, `production/epics/entrada-y-controles/story-001-input-types-and-binding-table.md`

---

## Evidencia

- Suite: `tests/unit/state/platform_seams_test.gd` (12 tests, todos PASSED). Suite completa gdUnit4: 139 casos, 0 errores, 0 fallos, 0 huérfanos (28/28 suites); `--import` sin errores. Godot 4.7.2.
- CA1 (RecordingLog/RecordingFatalHandler): `test_recording_log_collects_level_and_message`, `test_recording_fatal_handler_records_calls_and_flags_failure`.
- CA2 (ErrorPolicy): `test_error_policy_default_is_strict_only_in_debug`, `test_error_policy_default_fail_in_release_does_not_halt`, `test_base_error_policy_is_inert`.
- CA3 (TestContexts): `test_test_contexts_make_returns_frozen_context_of_doubles`, `test_test_contexts_override_replaces_a_single_service`. Ninguna suite nombra un `*Autoload` en estas pruebas.
- CA4 (ServiceContext/Boot): campos `logger`, `fatal`; `Boot.make_fatal_handler` cubierto por `test_boot_picks_fatal_handler_by_flavor` (la composición completa de `compose()` toca autoloads y no se ejecuta en unit).
- Decisiones: `ErrorPolicyDefault` = `push_error` + `quit(1)` solo en debug (F-R09/F-X09, sin `assert`; la nota de motor de la historia queda superada por la enmienda). `DebugFatalHandler` delega la parada en `ErrorPolicy` inyectada (no nombra el motor); `ReleaseFatalHandler` solo registra, `# TODO(ADR-0009)` para `ctx.ui.error_panel`. La rama de debug real de `fail()` (quit) no es testeable en la suite.
- Ficheros: `src/core/platform/log_sink.gd`, `src/core/platform/error_policy.gd`, `src/core/error_policy_default.gd`, `src/core/composition/{fatal_error_handler,debug_fatal_handler,release_fatal_handler,fatal_messages,service_context}.gd`, `src/core/boot/boot.gd`, `tests/doubles/{recording_log,recording_fatal_handler,fake_real_clock,fake_clock,fake_game_state,test_contexts}.gd`, `tests/unit/state/platform_seams_test.gd`.
