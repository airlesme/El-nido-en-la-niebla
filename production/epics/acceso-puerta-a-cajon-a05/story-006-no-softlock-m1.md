# Story 006: Invariantes no-softlock M1 (P1 → A → `A05`) con capturas

> **Epic**: Acceso — puerta A y cajón A05
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S — 0,5 días (0,5–1), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/control-de-acceso.md` — § Edge Cases; regla 18 (no-softlock)
**Requirement**: `TR-access-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (estados derivados de hechos); ADR-0002 (pausa); ADR-0011 (cancelación de gesto no bloquea)
**ADR Decision Summary**: ninguna puerta queda cerrada con su condición cumplida; las tarjetas no se gastan; rechazo o cancelación del gesto nunca bloquea apertura ni entrega.
**ADR Version**: ADR-0001 2026-11-10 · ADR-0002 2026-11-10 · ADR-0011 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: capturas del propio motor con `--write-movie` (`.claude/docs/run-and-observe.md`), nunca del escritorio.

**Control Manifest Rules (this layer)**:
- Required: F-R05.
- Forbidden: —
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/control-de-acceso.md` y hito M1, scoped to this story:*

- [ ] **C-M1-3 (parte de 8)**: la puerta A abre siempre tras `archivo_abierto`, también tras fallos previos de P1 (×5 fallos y luego solución), con test de estado.
- [ ] **AC-16 (tramo M1)**: lista de comprobación con captura retenida de cada paso P1 → A abierta → `A05` abierto, con y sin reinicio de estado (restore de 3) entre pasos.
- [ ] Con el gesto `HAND_DRAWER` cancelado o rechazado, `A05` se abre y entrega igualmente (por tope o `gesto_terminado` con cualquier motivo).

---

## Implementation Notes

- El reinicio «con cierre/reanudación» del GDD exige guardado (ADR-0004, Proposed): en M1 se sustituye por restore de instantánea de 3 y se anota la diferencia en la evidencia.

---

## Out of Scope

- Tramos B, D y `C08` de AC-16 (fuera de M1).

---

## Files

- `tests/integration/access/no_softlock_m1_test.gd`
- `production/qa/evidence/no-softlock-m1-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/access/no_softlock_m1_test.gd` — must exist and pass; capturas retenidas en `production/qa/evidence/`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/acceso-puerta-a-cajon-a05/story-004-puerta-a-en-escena.md`, `production/epics/acceso-puerta-a-cajon-a05/story-005-cajon-a05.md`; épico `puzles-marco-y-p1` (escritura de `archivo_abierto`)
- Unlocks: cierre de C-M1-1 y C-M1-3 junto con los demás épicos
