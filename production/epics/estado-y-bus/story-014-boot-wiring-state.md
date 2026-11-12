# Story 014: Composición en `Boot` — catálogo al arrancar y entrega de `FactWriter`

> **Epic**: Estado y bus de eventos
> **Status**: In Progress — CA-26 (dev), CA-06b y `--boot-report` verificados; falta NOT ASSESSED de la parte release de CA-26 (ErrorPanel, UiPorts) y anotar C9 en ADR-0009 Open Items
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 14 (arranque); § States and Transitions
**Requirement**: `TR-state-001` (ausente/corrupto → no hay partida), `TR-state-005` (dueño solo en dev)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Service composition (D2 orden de arranque, D3 `Boot` única raíz, D8) · ADR-0001 (D7, G-1, G-10)
**ADR Decision Summary**: `Boot.compose()` llama a `GameStateAutoload.setup(ctx)` en el paso 2 del orden D2; `setup` carga `assets/data/state/flags.json` y, en error, `ctx.fatal` impide entrar en la partida. `Boot` es el único sitio que obtiene `writer_for(n)` y lo entrega a 9, 19, 20, 22.
**ADR Version**: ADR-0009 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0009)
**Engine Notes**: `process_mode = ALWAYS` explícito en `_init()` (ya en el esqueleto).

**Control Manifest Rules (this layer)**:
- Required: F-R24/F-R25 (solo `boot.gd` nombra autoloads), F-R26 (sin I/O en `_init`/`_ready`), F-R27 (orden de arranque síncrono), F-R36
- Forbidden: que un sistema obtenga su propio `FactWriter`
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-26 (I, arranque del juego)**: con `flags.json` ausente o corrupto, el juego no entra en la partida, deja el error de `CATALOGO_INVALIDO` en consola y se detiene (dev). El panel de error de release depende de `UiPorts` (fuera de M1): se registra NOT ASSESSED para la parte de release.
- [ ] **CA-06b (I)**: en una build de desarrollo, una escritura inválida de CA-06 detiene la ejecución con un error visible (prueba de arranque con un emisor de prueba).
- [ ] Con el `flags.json` real, `--boot-report` imprime la línea `[boot]` y `GameState.get_status() == READY` tras `compose()`.

---

## Implementation Notes

- Rellenar `GameState.setup(ctx)` (hoy TODO): leer `ctx.logger`, `ctx.fatal`, `ctx.flavor` y llamar a `load_catalog`. *ADR-fallback*: dónde guarda `Boot` los `FactWriter` hasta que existan 9/19/20/22 no lo fija ADR-0009 — se deja una tabla privada en `Boot` y se anota en ADR-0009 Open Items (C9).
- Test de integración en `tests/integration/state/` que arranca `main.tscn` sin escena de juego, o el informe de arranque si CI no permite ventana.

---

## Out of Scope

- `ErrorPanel` de release (Shell/UiPorts).

---

## Files

- `src/core/game_state.gd`, `src/core/boot/boot.gd`
- `tests/integration/state/boot_state_wiring_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/state/boot_state_wiring_test.gd` OR playtest doc.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-001-platform-seams.md`, `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`, `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`
- Unlocks: `production/epics/estado-y-bus/story-015-m1-state-test.md`

---

## Evidencia

- `Boot.wire_state(ctx)` (setup + `load_catalog("state/flags.json")`, paso 2 de D2); `compose()` fija `ctx.files`, corta tras el paso 2 si `ctx.fatal.has_failed()`; `Boot.writer_for_owner` con tabla privada (`# TODO(boot-owner)`). `setup` sigue sin I/O (F-R26).
- `tests/integration/state/boot_state_wiring_test.gd`: 6/6 PASSED (catálogo real: READY y 20 hechos en debug; release READY; ausente/corrupto -> CATALOGO_INVALIDO y UNLOADED; escritura inválida en dev -> `fail`; writer único por dueño).
- `--import` sin errores; `--headless --quit-after 5 -- --boot-report` -> `[boot] flavor=debug dev_tools=absent version=dev commit=dev`, sin errores ni fatal.
- Suite bloqueante: 756 casos, 1 fallo ajeno (`tests/unit/player/player_state_machine_test.gd`, PJ en curso), 0 orphans, sin `leaked`/`resources still in use`.
- Pendiente: parte release de CA-26 NOT ASSESSED; nota C9 en ADR-0009 Open Items (no tocado). El release no valida el esquema a fondo: cubierto por `DataReader` con `BuildFlavor`.
