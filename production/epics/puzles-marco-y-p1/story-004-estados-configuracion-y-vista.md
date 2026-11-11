# Story 004: Estados públicos, configuración síncrona y registro de vista `C05`

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

`PuzzleFramework` como nodo de escena de `planta`: configura P1 de forma síncrona al cargar, lo
registra como `ViewReceiver` de `C05` antes de «escena lista», expone `get_view_gate` y emite un
único «puzles configurados».

**GDD**: `design/gdd/marco-de-puzles.md` (reglas 6–8, 11, 24, 26, 35) · `design/gdd/puzle-1-cronologia.md` (R5, R6)
**Requirement**: `TR-puzzles-007`, `TR-puzzles-015`, `TR-puzzles-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D1 (topología), D12 (reconstrucción por hechos), D13 (ruta de fallo), D15 (view gate); ADR-0003 (orden de configuración 7 → 9, `INVALID_PUZZLE_DATA`); ADR-0011 (`ViewReceiver` como puerto `RefCounted`, OI-2)
**ADR Decision Summary**: un `PuzzleFramework` por escena con un `PuzzleRuntime` por puzle; estado `BLOQUEADO→ACTIVO→RESUELTO` monótono; con `solved_flag` verdadero al cargar se llama `restore_solved_presentation()` sin avisos.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0003 2026-11-10 · ADR-0011 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: sin API post-corte propia más allá de D2; `process_mode` del nodo según ADR-0002 D2.

**Control Manifest Rules (this layer)**:
- Required: FE-R16 (escrituras antes que avisos); `FactWriter(9)` llega por `SceneServices.puzzle_writer` (ADR-0010 OI-1, aplicado en ADR-0009 D3)
- Forbidden: F-X10 (sin `Timer`/`create_timer`); FE-X05
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-1**: partida nueva → `P1` `ACTIVO`, `archivo_abierto` falso, huecos vacíos, `en_mano = ninguna`; con `archivo_abierto` verdadero al cargar → `P1` `RESUELTO` y `get_view_gate('C05')` = `SOLVED` (la parte «`C05` no es objetivo en 7» está en la story 011).
- [ ] **GDD 9 AC-04b (parte P1)**: `registrar_receptor` para `C05` antes de «escena lista».
- [ ] **GDD 9 AC-68**: una carga de `planta` emite exactamente un «puzles configurados» antes de «escena lista».
- [ ] **ADR-0010 T-I1 (parte de datos inválidos)**: con `puzzles.json` inválido → `INVALID_PUZZLE_DATA`, nada registrado.

---

## Implementation Notes

- Rutas fijadas: `src/puzzles/framework/puzzle_framework.gd`. Las firmas `configure`, `get_view_gate`, `configuration_failed()` (C6) están en ADR-0010 D1/D13/D15.
- El orden de configuración lo dicta 4 (ADR-0003). Si `SceneLoader` aún es esqueleto, el test usa un doble de 4 que llama en el orden de ADR-0003.
- Solo P1 en M1; el bucle por puzle no debe asumir uno solo.

---

## Out of Scope

- Story 007: escritura de `archivo_abierto` al resolver.
- Story 011: puerta A e `habilitado_si` de `C05` en 7.

---

## Files

- `src/puzzles/framework/puzzle_framework.gd` (y `PuzzleRuntime` según D1)
- `tests/integration/puzzles/planta_configure_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/puzzles/planta_configure_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-001-puzzles-json-v2-p1.md`, `production/epics/puzles-marco-y-p1/story-002-contrato-controller-verdict.md`; `ViewReceiver` de ADR-0011 (`production/epics/interaccion-y-prompt/`)
- Unlocks: `production/epics/puzles-marco-y-p1/story-005-delayed-after-change.md`, `production/epics/puzles-marco-y-p1/story-008-material-vista-compose-i01.md`
