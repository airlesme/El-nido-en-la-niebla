# Story 013: Recorrido M1 con mando y teclado + capturas de interacción

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1 día (0,5–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Acceptance Criteria › Evidencia visual; § Game Feel
**Requirement**: `TR-interact-002`, `TR-interact-010`, `TR-interact-011` (en el recorrido real)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D9 presupuesto en escena real; S-0011-C NEEDS_WINDOWED); ADR-0006 (mando y teclado)
**ADR Decision Summary**: verificación en la escena de planta real de lo probado en unitario; los píxeles y el viewport lógico se observan en ventana.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: capturas **del propio motor** con `--write-movie` (procedimiento `.claude/docs/run-and-observe.md`), nunca del escritorio. Si ADR-0016 sigue Proposed, la verificación del alto lógico en 16:10 queda NOT ASSESSED anotado (no bloquea esta historia).

**Control Manifest Rules (this layer)**:
- Required: FE-R08, FE-R11.
- Forbidden: FE-X03.
- Guardrail: FE-G01 medido en la escena real (informativo).

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md` y hito M1, scoped to this story:*

- [ ] **C-M1-6 (parte de 7)**: sesión manual registrada: foco, pulsación corta, lectura por pulsación larga de `A04`, entrada y salida del ordenador y del panel P1, con mando y con teclado.
- [ ] **C-M1-3 (parte de 7)**: cancelar o salir de una vista/lectura/ordenador nunca deja el modo bloqueado (×5 en el recorrido, incluido abrir pausa durante una pulsación larga).
- [ ] **AC-V7**: captura retenida del ordenador `V01` abierto con la cámara acercada.
- [ ] **AC-V6 (adaptado a M1)**: captura retenida del panel de P1 en vista cercana con el cursor visible y no circular en 16:9 (16:10 si ADR-0016 ya está aceptado; si no, NOT ASSESSED anotado), con la captura de depuración de `pick_min_px`.

---

## Implementation Notes

- Capturas: `godot --path . --write-movie production/qa/evidence/<nombre>.png …` sobre una escena/estado de arranque de dev; guardar el fichero en `production/qa/evidence/` y la nota de sesión en `production/qa/evidence/recorrido-m1-interaccion-evidence.md`.
- AC-V5 (lectura de `A04`) depende de `ReadingScreen` (diferido por ADR-0016, épico documentos-y-bolsillo) — no se exige aquí.

---

## Out of Scope

- AC-V1/V2/V3 (prompt): diferidos por ADR-0016. AC-V4 (inspección): recorte 6. AC-X1/X3: playtest M5.

---

## Files

- `production/qa/evidence/recorrido-m1-interaccion-evidence.md`, capturas en `production/qa/evidence/`
- `tests/integration/interaction/recorrido_m1_test.gd` (recorrido scripted opcional)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: playtest documentado en `production/qa/evidence/recorrido-m1-interaccion-evidence.md` + capturas retenidas (motor, `--write-movie`) en `production/qa/evidence/`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: stories 005–012 de este épico; épicos `puzles-marco-y-p1` (panel P1), `ordenador-e-impresora`, `documentos-y-bolsillo` (`A04`)
- Unlocks: cierre de C-M1-6 junto con los demás épicos
