# Story 003: `Puzzle1Controller` — colocación, tabla R13 y `evaluate()` puro

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

El corazón de P1: 4 huecos, 4 referencias, solución `2 · 1 · 3 · 4`. El controlador solo guarda su
colocación y devuelve veredictos; no conoce tiempo, hechos ni avisos.

**GDD**: `design/gdd/puzle-1-cronologia.md` (R12, R13 —9 filas—, R20, R24)
**Requirement**: `TR-puzzle1-003`, `TR-puzzle1-004`, `TR-puzzle1-005`, `TR-puzzle1-006`, `TR-puzzle1-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D2, D3, D7 (ruta de entrada); ADR-0001 (el controlador no toca hechos)
**ADR Decision Summary**: subclase de `PuzzleController`; estado `S=(s1..s4)` inyectivo + `en_mano`; `evaluate()` = función pura de (colocación, `en_mano`, `solution`); `changed(tag)` con `&"REF_PLACED"` alimenta `on_change.sfx`.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: todo override de método tipado lleva `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: FE-R12, FE-R13, FE-R14 (todo camino que cambia estado termina en `policy.on_change(rt)` — lo llama el marco tras `changed`)
- Forbidden: FE-X05, FE-X07; FE-R09 (`seleccionar` llega como un único `FIN`)
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-4**: cada fila de la tabla R13 produce el estado de la tabla (mudanza fila 4, intercambio fila 5, misma referencia en el mismo hueco, descarte en bloqueo fila 9); nunca dos huecos con la misma referencia.
- [ ] **GDD 11 AC-16**: filas 4 y 5 → un solo «feedback de puzle» con `SFX_SLOT_IN` y el hueco; fila 6 → sin sonido (vía `changed(&"REF_PLACED")`).
- [ ] **TR-puzzle1-006**: `evaluate()` devuelve `SOLVED` con `[2,1,3,4]`, `REJECT` con cualquier otro estado completo y `NONE` con estado incompleto o `en_mano ≠ ninguna`; se recorren los 24 estados completos.

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines 1, 2, 10, 11:*

- Ruta: `src/puzzles/p1_cronologia/puzzle1_controller.gd`. El slug `p1_cronologia` sigue OI-7 de ADR-0010 (decisión del lead-programmer pendiente): si lo fija distinto, mover el fichero antes de cerrar.
- `solution` se lee de la definición recibida en `configure(def, flags)`; nunca constante.
- Ignora actualización, agarrar, mantener y rotar (TR-puzzle1-005).
- Tests con dobles: definición de fixture y eventos `PointerEvent` construidos a mano (forma de ADR-0011).

---

## Out of Scope

- Story 005: cuándo se llama a `evaluate()` (0,6 s).
- Story 008: `elements()` y el material de la hoja.

---

## Files

- `src/puzzles/p1_cronologia/puzzle1_controller.gd`
- `tests/unit/puzzle_1/p1_r13_table_test.gd`, `tests/unit/puzzle_1/p1_evaluate_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/puzzle_1/p1_r13_table_test.gd` y `p1_evaluate_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-002-contrato-controller-verdict.md`
- Unlocks: `production/epics/puzles-marco-y-p1/story-005-delayed-after-change.md`, `production/epics/puzles-marco-y-p1/story-008-material-vista-compose-i01.md`
