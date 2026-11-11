# Story 007: Resolución `IMMEDIATE` — orden de escritura y `EV_PUZZLE_SOLVED_P1`

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Con `2 · 1 · 3 · 4` y 0,6 s de calma, el marco —y solo el marco— escribe `archivo_abierto` y anuncia
la resolución en el mismo fotograma y en un orden fijo.

**GDD**: `design/gdd/marco-de-puzles.md` (reglas 16, 17, S9) · `design/gdd/puzle-1-cronologia.md` (R34)
**Requirement**: `TR-puzzles-011`, `TR-puzzles-020` (parte P1), `TR-puzzle1-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D5.3 (orden de compromiso), D14 (avisos); ADR-0001 (`FactWriter`, orden escritura → aviso)
**ADR Decision Summary**: hechos de `on_solved.write` → `solved_flag` → `RESUELTO` → `EV_PUZZLE_SOLVED_<ID>` → resto de avisos; un segundo `SOLVED` en el mismo fotograma se descarta (S9).
**ADR Version**: ADR-0010 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna API post-corte propia.

**Control Manifest Rules (this layer)**:
- Required: FE-R16 (escrituras antes que avisos, orden D5.3)
- Forbidden: FE-X05 (el controlador no escribe hechos)
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-11**: en el mismo fotograma y por este orden: `archivo_abierto` = verdadero, `P1` `RESUELTO`, `EV_PUZZLE_SOLVED_P1 {puzzle:'P1', rewards:[]}` una vez, sin «compartimento completado», `SFX_UNLOCK` 1,4 s; a 1,5 s `cerrar_vista('C05','resuelto')`.
- [ ] **GDD 9 AC-18 / AC-24**: un segundo `SOLVED` en el mismo fotograma se descarta; el aviso sale una vez.
- [ ] **C-M1-4 (parte P1)**: `archivo_abierto` solo lo escribe 9 — test con `RecordingFactWriter` que falla si otro sistema lo escribe.

---

## Implementation Notes

- Tests con `RecordingFactWriter` y el doble de bus de ADR-0009 D9 (ADR-0010 § Validation Criteria, T-U8).
- `close_view_after_s` 1,5 es dato y corre en `GameClock`.

---

## Out of Scope

- Story 011: reacción de la puerta A (sistema 8) al hecho.

---

## Files

- `src/puzzles/framework/puzzle_framework.gd` (commit D5.3)
- `tests/unit/puzzles/commit_order_test.gd`, `tests/unit/puzzle_1/p1_resolution_order_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: los tests de Files — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-005-delayed-after-change.md`
- Unlocks: `production/epics/puzles-marco-y-p1/story-010-panel-p1-gris-captura.md`, `production/epics/puzles-marco-y-p1/story-011-puerta-a-y-c05.md`
