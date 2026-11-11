# Story 005: Cajón `A05` — manejador, `HAND_DRAWER` o tope de 3 s → `otorgar("A05")`

> **Epic**: Acceso — puerta A y cajón A05
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/control-de-acceso.md` — § Detailed Rules › Cajón A05; § States and Transitions
**Requirement**: `TR-access-006`, `TR-access-012` (cajón), `TR-access-016`, `TR-access-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D6 contrato `InteractionHandler`, `gesto_hecho`); ADR-0009 (D4: 8 → 20 `otorgar`); ADR-0001; ADR-0002 (G-1)
**ADR Decision Summary**: `A05` `CERRADO` → «Abrir» devuelve `HECHO` y pasa a `ABRIENDO`; tras `gesto_terminado(HAND_DRAWER, cualquier motivo)` o `t_cajon_tope_s` 3,0 s de juego llama **una vez** a `otorgar("A05")` (idempotente) y queda `ABIERTO` (`can_interact = NO`).
**ADR Version**: ADR-0011 2026-11-10 · ADR-0009 2026-11-10 · ADR-0001 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: el gesto `HAND_DRAWER` lo reserva 7 como `gesto_hecho` del catálogo (ADR-0011 D6); 8 solo escucha `gesto_terminado` (nombre y payload según ADR-0012; si no están fijados, ADR-fallback).

**Control Manifest Rules (this layer)**:
- Required: FE-R06, F-R32, ADR-0002 G-1.
- Forbidden: `Timer` para el tope; segunda llamada a `otorgar`; bloquear la entrega si el gesto se cancela.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/control-de-acceso.md` y hito M1, scoped to this story:*

- [ ] **AC-19**: con ambas tarjetas falsas y `A05` `CERRADO`, «Abrir» devuelve `HECHO` y pasa a `ABRIENDO`; con `gesto_terminado(HAND_DRAWER, motivo)` para `completo`, `cancelado` y `tope` se llama una vez a `otorgar("A05")` y queda `ABIERTO` con `can_interact = NO`; sin gesto, se otorga a 3,0 s.
- [ ] **AC-13 (cajón)**: con la pausa abierta en `ABRIENDO`, el tope no avanza hasta reanudar.
- [ ] **C-M1-1 (parte de 8)**: con 20 real, tras abrir `A05` `tarjeta_B` y `tarjeta_D` son verdaderas (integración con `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`).

---

## Implementation Notes

- Manejador registrado con `registrar_manejador(&"A05", handler)` (adaptador con `WeakRef`, F-R33).
- La presentación de las tarjetas es de 20 y no bloquea a 8 (AC-24 de 20).

---

## Out of Scope

- Uso posterior de las tarjetas en lectores (fuera de M1).

---

## Files

- `src/world/access/drawer_a05_handler.gd`
- `tests/integration/access/cajon_a05_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/access/cajon_a05_test.gd` — must exist and pass (dobles de 7/Jugador, 20 real, reloj falso).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/acceso-puerta-a-cajon-a05/story-002-configuracion-al-arrancar.md`, `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`, `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md`
- Unlocks: `production/epics/acceso-puerta-a-cajon-a05/story-006-no-softlock-m1.md`
