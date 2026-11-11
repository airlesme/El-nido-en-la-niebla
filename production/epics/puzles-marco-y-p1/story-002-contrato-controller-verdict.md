# Story 002: Contrato `PuzzleController` y `Verdict`

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA: incluye las verificaciones de motor V1–V5)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Base abstracta común a los seis controladores y objeto de valor del veredicto. Es la primera pieza
con API post-corte (`@abstract`, retorno tipado heredado en 4.7) y por eso va antes que cualquier
controlador.

**GDD**: `design/gdd/marco-de-puzles.md` (reglas 6, 10, 11, 35)
**Requirement**: `TR-puzzles-008`, `TR-puzzles-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D2 (`PuzzleController`), D3 (`Verdict`)
**ADR Decision Summary**: `@abstract PuzzleController` con 13 métodos abstractos y 5 ganchos virtuales con valor por defecto; `Verdict` tipado e inmutable (`NONE`/`HOLDING`/`PARTIAL`/`REJECT`/`SOLVED`) con factorías estáticas.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: forma de dos líneas `@abstract` / `class_name`; los overrides tipados necesitan `return` explícito (4.7). El momento del error al instanciar la base es NOT SOURCEABLE: T-U1 lo **registra**. Registrar V1–V5 en `docs/engine-reference/godot/`.

**Control Manifest Rules (this layer)**:
- Required: FE-R12 (forma de dos líneas), FE-R13 (`evaluate()` puro), FE-R20 (`Verdict` tipado e inmutable)
- Forbidden: FE-X05 (el controlador no referencia `PuzzleFramework`, `GameState`, `FactWriter`, bus, otro controlador ni `InteractionSystem`), FE-X07 (controladores gordos)
- Guardrail: FE-G02 (< 0,05 ms/fotograma del marco)

---

## Acceptance Criteria

- [ ] **GDD 9 AC-01**: el objeto `PuzzleState` solo expone `activate()` y `resolve()`; no existe método de retroceso.
- [ ] **ADR-0010 T-U1**: instanciar la base falla (se anota si en parseo o en ejecución); un controlador de prueba que omite un método abstracto no parsea.
- [ ] **ADR-0010 T-U2**: factorías de `Verdict` y copia inmutable de `progress`.
- [ ] **ADR-0010 T-U3**: `evaluate()` llamado dos veces devuelve veredictos iguales, sin señal ni lectura de reloj (espía de reloj).

---

## Implementation Notes

- Rutas fijadas: `src/puzzles/framework/puzzle_controller.gd`, `src/puzzles/framework/verdict.gd`, `src/puzzles/framework/activation_result.gd`. Las firmas son las de ADR-0010 D2/D3: copiarlas, no reinterpretarlas.
- V1 (forma de una línea) y V2–V5 se ejecutan como parse checks con Godot 4.7.2 y se registran; si V1 falla no cambia nada (se usa la de dos líneas).
- `PuzzleState` es parte de `PuzzleRuntime` (D1); aquí solo su API pública monótona.

---

## Out of Scope

- Story 003: el primer controlador real (`Puzzle1Controller`).
- Story 005: políticas de comprobación.

---

## Files

- `src/puzzles/framework/puzzle_controller.gd`, `verdict.gd`, `activation_result.gd`
- `tests/unit/puzzles/puzzle_controller_contract_test.gd`, `tests/unit/puzzles/verdict_test.gd`, `tests/unit/puzzles/evaluate_purity_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: los tres tests de Files (gdUnit4) — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/puzles-marco-y-p1/story-003-puzzle1-controller-r13.md`, `production/epics/puzles-marco-y-p1/story-004-estados-configuracion-y-vista.md`
