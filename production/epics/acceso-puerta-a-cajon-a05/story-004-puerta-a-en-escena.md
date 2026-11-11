# Story 004: Puerta A en escena — hoja, colisión con Jolt y paso del jugador

> **Epic**: Acceso — puerta A y cajón A05
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1 día (0,5–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/control-de-acceso.md` — § Detailed Rules › Puerta A; § Visual/Audio Requirements
**Requirement**: `TR-access-008`, `TR-access-009` (en escena), `TR-access-018` (hueco transitable)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (G-9 tweens con el nodo del mundo como dueño; D2 `process_mode`); ADR-0011 (D1: la hoja cerrada está en `world_geometry`, bit 1); ADR-0001 (aviso `door_opened`)
**ADR Decision Summary**: la hoja (cuerpo en bit 1) desactiva su colisión en el primer paso de `ABRIÉNDOSE` y sigue `θ(t)` del modelo; hueco 1,00 × 2,10 m transitable por la cápsula de 0,25 m.
**ADR Version**: ADR-0002 2026-11-10 · ADR-0011 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (colisión de la hoja con Jolt; márgenes)
**Engine Notes**: Jolt por defecto desde 4.6 («Collision margins may behave differently», `modules/physics.md`): la prueba de paso usa la cápsula real del Jugador.

**Control Manifest Rules (this layer)**:
- Required: ADR-0002 G-7 (`process_mode` explícito), G-9.
- Forbidden: `AnimationPlayer`/`Tween` como fuente de verdad del tiempo (el modelo manda).
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/control-de-acceso.md`, scoped to this story:*

- [ ] **AC-03 (integración)**: en la escena de planta, al escribir `archivo_abierto`, la hoja empieza a girar en ese paso y su colisión se retira; termina a 90° en 1,2 s de juego.
- [ ] **AC-08 (puerta A)**: con A `ABRIÉNDOSE` o `ABIERTA`, la cápsula de 0,25 m del Jugador atraviesa el hueco de 1,00 m sin contacto con hoja ni marco; captura retenida como refuerzo.
- [ ] Captura del motor (`--write-movie`) de la puerta A abierta en `production/qa/evidence/` (parte de C-M1-7 «Archivo»).

---

## Implementation Notes

- La hoja lee `θ` del modelo cada fotograma (o tween de mundo sincronizado con el modelo); el estado y el tiempo nunca los decide el nodo.
- Capturas con `godot --write-movie` desde un estado de arranque de dev; nunca del escritorio.

---

## Out of Scope

- Puertas B/D. Guardado al abrir (ADR-0004).

---

## Files

- `src/world/access/door_leaf.gd`, escena de la puerta A
- `tests/integration/access/puerta_a_en_escena_test.gd`
- `production/qa/evidence/puerta-a-en-escena-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/access/puerta_a_en_escena_test.gd` — must exist and pass; captura retenida en `production/qa/evidence/`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/acceso-puerta-a-cajon-a05/story-003-puerta-a-apertura.md`; épicos `jugador-primera-persona` (cápsula), `carga-de-planta`
- Unlocks: `production/epics/acceso-puerta-a-cajon-a05/story-006-no-softlock-m1.md`
