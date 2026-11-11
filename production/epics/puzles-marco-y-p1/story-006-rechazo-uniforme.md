# Story 006: Rechazo uniforme — bloqueo 1,5 s, vibración 1,2 s, reinicio sin penalización

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

El fallo de P1 no es terminal: las hojas vibran, vuelven a la impresión a los 1,5 s y el puzle
vuelve a aceptar entrada. Sin contador, sin texto, sin hecho. Los 23 estados incorrectos son
indistinguibles. Es criterio «no se recorta nunca» del hito (C-M1-3, parte lógica).

**GDD**: `design/gdd/marco-de-puzles.md` (reglas 13, 14, F1) · `design/gdd/puzle-1-cronologia.md` (R22, R25, R26)
**Requirement**: `TR-puzzles-018`, `TR-puzzle1-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D5 (pipeline de veredictos), D7 (bloqueo y descarte); ADR-0001 (aviso «feedback de puzle»)
**ADR Decision Summary**: `REJECT` → feedback, `lock: PUZZLE` ≤ `lock_max_s` 2,0 s con eventos **descartados**, `reset_attempt` tras `reset_after_s`.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: el bloqueo de 9 no es un bloqueo de Entrada (ADR-0006 no interviene).

**Control Manifest Rules (this layer)**:
- Required: FE-R17 (eventos durante un bloqueo se descartan, nunca se encolan), FE-R15
- Forbidden: FE-X06
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-8 / GDD 9 AC-07**: `S = [1,2,3,4]` → `REJECT`: `SFX_REJECT`, vibración 1,2 s (orden de presentación), a 1,5 s las cuatro referencias vuelven a la hoja, entrada descartada 1,5 s y después aceptada; sin contador, texto ni hecho; el nivel de pista no varía.
- [ ] **GDD 11 AC-10**: los 23 estados completos incorrectos producen veredicto, sonido, animación y duración idénticos, sin información de qué hueco es correcto.
- [ ] **ADR-0010 T-U7 (parte reject)**: eventos durante el bloqueo descartados (no encolados); `lock` > `lock_max_s` imposible.
- [ ] **C-M1-3 (lógica)**: cinco rechazos seguidos dejan P1 `ACTIVO` y resoluble (el recorrido manual ×5 va en la story 012).

---

## Implementation Notes

- `shake_s` 1,2, `reset_after_s` 1,5 y `lock` vienen de `on_reject` en datos (TR-puzzle1-013).
- La vibración se **pide** al presentador como paso de presentación; esta historia comprueba la orden y su duración, no el aspecto (story 010).
- La variante `reducir_movimiento` (tono estático) está **Diferida** (ADR-0007 Proposed); el código deja el punto de lectura con el valor por defecto `false`, sin cachearlo.

---

## Out of Scope

- Story 010: aspecto de la vibración y captura.

---

## Files

- `src/puzzles/framework/puzzle_framework.gd` (pipeline D5)
- `tests/unit/puzzles/verdict_pipeline_test.gd`, `tests/unit/puzzle_1/p1_reject_uniform_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: los tests de Files con `GameClock` falso — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-005-delayed-after-change.md`
- Unlocks: `production/epics/puzles-marco-y-p1/story-010-panel-p1-gris-captura.md`, `production/epics/puzles-marco-y-p1/story-012-oraculo-y-fallo-x5.md`
