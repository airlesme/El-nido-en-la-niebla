# Story 008: Fundido de encendido 0,3 s

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: S — 0,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

La primera apertura pasa de negro a la bandeja en `t_encendido` = 0,3 s, medidos con el reloj de
juego.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R4)
**Requirement**: `TR-computer-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006, ADR-0005 (dato `t_encendido`); ADR-0002 (G-9 `FxTween.make`)
**ADR Decision Summary**: fundido de 0,3 s con precisión ±1 fotograma; con `reducir_movimiento`, 100 ms fijos.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0005 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `Tween` en pausa: spike S5 de ADR-0002; crear con `FxTween.make`.

**Control Manifest Rules (this layer)**:
- Required: valor desde datos
- Forbidden: `create_tween()` suelto
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-21 (rama nominal)**: medido con el reloj de juego, negro → bandeja dura `t_encendido` ± 1 fotograma. Rama `reducir_movimiento` (100 ms) → **Diferido** (ADR-0007).
- [ ] Captura retenida del motor (`--write-movie … --fixed-fps 60`) con el fotograma inicial negro y el final con la bandeja; se cuentan 18 ± 1 fotogramas.

---

## Implementation Notes

- El fundido lee `reducir_movimiento` en el punto que fije ADR-0007; hasta entonces, valor por defecto `false` sin cachear.

---

## Out of Scope

- Story 009: contenido de la bandeja.

---

## Files

- `src/world/computer/computer_view_receiver.gd`
- `production/qa/evidence/computer-power-on/` y `production/qa/evidence/story-008-fundido-encendido-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retenidas en `production/qa/evidence/computer-power-on/` + sign-off en `production/qa/evidence/story-008-fundido-encendido-evidence.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ordenador-e-impresora/story-005-receptor-v01-apertura-cierre.md`
- Unlocks: None
