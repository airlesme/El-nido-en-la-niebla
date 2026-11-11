# Story 010: Reconocedor de gestos F6 (`agarrar` / `mantener` / `seleccionar`)

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Formulas F6 (pulsación prolongada y umbral de arrastre); § Detailed Design › Core Rules, regla 13
**Requirement**: `TR-input-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D10) · ADR-0011 (A-1: `target_id` = pick de 7)
**ADR Decision Summary**: `GestureRecognizer` (puro) corre por cada pulsación de `seleccionar`: al pulsar pide el objetivo bajo `p` y congela sus `gestos_aceptados`; gana la primera señal: `t_hold` 0,5 s en tiempo real (si acepta `mantener`) o desplazamiento ≥ 8 px (si acepta `agarrar`); si no, `seleccionar` al soltar.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0011 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `t_hold` con `RealClock`.

**Control Manifest Rules (this layer)**:
- Required: F-R16, F-R42, F-R46
- Forbidden: decidir el gesto por el consumidor
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-13**: sobre un elemento que acepta `agarrar` y `mantener`, moverse ≥ 8 px antes de 0,5 s emite `agarrar` (y no `mantener` aunque luego pare); mantener 0,5 s moviéndose < 8 px emite `mantener`.
- [ ] **AC-F6**: 0,18 s es corta y 0,62 s larga; 0,6 s con 3 px → `mantener`, con 12 px → `agarrar`; quieto 0,6 s y luego 12 px → `mantener`; 12 px a 0,3 s y parar → `agarrar`.
- [ ] **AC-E3**: `seleccionar` mantenida al entrar en `vista cercana` no cuenta hasta soltar y volver a pulsar.
- [ ] **AC-E6**: mantener sobre un elemento que no acepta `mantener` no emite `mantener` y se trata como `seleccionar` al soltar.

---

## Implementation Notes

- `GestureRecognizer` en `src/input/gesture_recognizer.gd`; `ActionEvent.target_id` = `PointerTargetProvider.target_at(p0)` (ADR-0011 A-1).
- `rotar` (F4) no entra (recorte 6). Modo «alternar» (TR-input-019) diferido por ADR-0007.

---

## Out of Scope

- F4 `rotar`; modo alternar.

---

## Files

- `src/input/gesture_recognizer.gd`, `src/input/input_router.gd`
- `tests/unit/input/gesture_recognizer_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/gesture_recognizer_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-009-virtual-cursor.md`
- Unlocks: `production/epics/entrada-y-controles/story-015-boot-wiring-and-manual-session.md`
