# Story 010: Panel P1 en gris — presentación, vibración y captura

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

El panel de la puerta A en gris (sin texturas, M1): hoja, sellos, 4 huecos, la vibración del
rechazo y el estado resuelto. Cierra C-M1-7 para «panel P1».

**GDD**: `design/gdd/puzle-1-cronologia.md` (R25, R35, R46; AC-PV2, AC-PV5)
**Requirement**: `TR-puzzle1-013` (presentación), `TR-puzzle1-015` (presentación)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D5 (pasos de presentación), D12 (`restore_solved_presentation`); ADR-0002 (`Tween` en pausa: S5 / `FxTween.make`, G-9)
**ADR Decision Summary**: la presentación la piden los pasos del pipeline; el estado resuelto se dibuja igual al resolver y al reconstruir, sin sonido en la reconstrucción.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (`Tween` con `SceneTree.paused`: spike S5 de ADR-0002)
**Engine Notes**: crear tweens solo con `FxTween.make` (ADR-0002 G-9); nunca `create_tween()` suelto.

**Control Manifest Rules (this layer)**:
- Required: FE-R15
- Forbidden: FE-X06; colores verde/rojo como única señal (AC-PV5)
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-PV5 (parte 16:9)**: captura retenida de `C05` resuelto con los huecos `2·1·3·4` y sus sellos legibles a 1920×1080, sin verde ni rojo. (16:10 → Diferido, ADR-0007.)
- [ ] **GDD 11 AC-8 (visual)**: captura de un fotograma de la vibración del rechazo y de las referencias de vuelta en la hoja tras 1,5 s.
- [ ] **C-M1-7 (panel P1)**: captura del panel con material y sin material.
- [ ] **AC-PV2 (parte medible)**: desde el inicio del rechazo hasta poder reintentar ≤ 2,0 s, observado en la grabación (`--fixed-fps` permite contar fotogramas). La parte «0 de 6 lo llaman castigo» es de playtest (M5).

---

## Implementation Notes

- **Evidencia del propio motor, nunca del escritorio**: `godot --path . --write-movie production/qa/evidence/p1-panel/p1.png --fixed-fps 60 <escena de prueba>` según `.claude/docs/run-and-observe.md`; conservar los PNG elegidos y borrar el resto.
- Escena de prueba de evidencia en `tests/scenes/` o `prototypes/` (no en `src/`), con dobles de 19 y 20 que dan `I-01`.

---

## Out of Scope

- Story 011: puerta abriéndose.

---

## Files

- escena/presentador de `C05` en `src/puzzles/p1_cronologia/` (nombre a fijar por el implementador; ninguna firma pública nueva)
- `production/qa/evidence/p1-panel/` (PNG) y `production/qa/evidence/story-010-panel-p1-gris-captura-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retenidas en `production/qa/evidence/p1-panel/` + sign-off del lead en `production/qa/evidence/story-010-panel-p1-gris-captura-evidence.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-006-rechazo-uniforme.md`, `production/epics/puzles-marco-y-p1/story-007-resolucion-immediate.md`, `production/epics/puzles-marco-y-p1/story-008-material-vista-compose-i01.md`, `production/epics/puzles-marco-y-p1/story-009-geometria-p1-view.md`
- Unlocks: None
