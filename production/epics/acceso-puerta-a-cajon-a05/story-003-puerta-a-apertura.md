# Story 003: Puerta A — `ABRIÉNDOSE` → `ABIERTA`, «puerta abierta» y curva de 1,2 s

> **Epic**: Acceso — puerta A y cajón A05
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/control-de-acceso.md` — § Detailed Rules › Puerta A, Hechos/avisos; § Formulas (θ(t))
**Requirement**: `TR-access-007`, `TR-access-008` (estado de colisión), `TR-access-009`, `TR-access-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (aviso `&"door_opened"` con `puerta: SN`, emisor 8); ADR-0002 (D1 `GameClock` único, G-1, G-3)
**ADR Decision Summary**: al cambiar `archivo_abierto` a verdadero, A pasa a `ABRIÉNDOSE` en ese paso, retira la colisión, emite una vez `door_opened {puerta: &"A"}` y llega a `ABIERTA` a los 1,2 s de juego con `θ(t) = 90°·(3x² − 2x³)`, `x = clamp(t/1,2)`; nunca se cierra; todos los tiempos se detienen en pausa.
**ADR Version**: ADR-0001 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (dominio de pausa; mitigado: tiempo solo por `GameClock`)
**Engine Notes**: nada de `Timer`, `create_timer` ni `Engine.time_scale` (ADR-0002 G-3).

**Control Manifest Rules (this layer)**:
- Required: ADR-0002 G-1; F-R31 (suscripción al hecho en `SubscriptionBag`).
- Forbidden: `SFX_UNLOCK` desde 8; segundo `door_opened` por la misma apertura.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/control-de-acceso.md` y hito M1, scoped to this story:*

- [ ] **AC-03 (lógica, reloj falso)**: A `CERRADA`; 9 escribe `archivo_abierto` en t = 20,0 → en t = 20,0 `ABRIÉNDOSE` sin colisión, `door_opened` (`A`) una vez; en t = 21,2 ± 0,05 `ABIERTA`; un segundo aviso con A `ABRIÉNDOSE`/`ABIERTA` no emite otro.
- [ ] **C-M1-5**: `ANIM_DOOR_OPEN` dura 1,2 s dentro de ±1 fotograma del dato con el reloj falso; θ(0,6) = 45° (±0,001).
- [ ] **AC-07**: una puerta `ABIERTA` sigue `ABIERTA` y sin colisión pase el tiempo que pase o aunque un hecho se fuerce a falso.
- [ ] **AC-13 (puerta)**: con la pausa abierta durante `ABRIÉNDOSE`, la transición no avanza hasta reanudar.

---

## Implementation Notes

- El estado vive en `AccessModel` (002); la hoja de escena solo lee `θ` (story 004).
- `door_opened` se emite en el primer paso de `ABRIÉNDOSE` por el bus (ADR-0001), no por señal de nodo.

---

## Out of Scope

- Story 004: hoja y colisión reales con Jolt. Guardado en `door_opened`: ADR-0004 (diferido).

---

## Files

- `src/world/access/access_model.gd` (transición de puerta)
- `tests/unit/access/puerta_a_apertura_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/access/puerta_a_apertura_test.gd` — must exist and pass (reloj falso).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/acceso-puerta-a-cajon-a05/story-002-configuracion-al-arrancar.md`
- Unlocks: `production/epics/acceso-puerta-a-cajon-a05/story-004-puerta-a-en-escena.md`
