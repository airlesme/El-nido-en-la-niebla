# Story 002: Estados derivados y configuración al arrancar (puerta A, `A05`)

> **Epic**: Acceso — puerta A y cajón A05
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/control-de-acceso.md` — § Detailed Rules › Estados de la puerta, Puerta A, Cajón A05, Hechos/avisos; § States and Transitions
**Requirement**: `TR-access-004`, `TR-access-005`, `TR-access-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (lectura de hechos por `GameState` inyectado; 8 no escribe hechos); ADR-0009 (D3 `configurar(ctx)`, F-R30 orden de configuración); ADR-0005 (datos de 001)
**ADR Decision Summary**: estados de puerta y cajón derivados de hechos + temporizadores; configuración síncrona en el mismo fotograma, en el paso 6 del arranque de 4 (tras 7 y 9), sin emitir «puerta abierta»; A nace según `archivo_abierto`, `A05` nace `ABIERTO` solo con ambas tarjetas.
**ADR Version**: ADR-0001 2026-11-10 · ADR-0009 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguno.

**Control Manifest Rules (this layer)**:
- Required: F-R05, F-R28, F-R30 (orden de `planta` como dato), FE-R06 (`can_interact` puro).
- Forbidden: que 8 persista o escriba hechos.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/control-de-acceso.md`, scoped to this story:*

- [ ] **AC-01**: con `archivo_abierto` falso, A nace `CERRADA` con colisión activa; con verdadero, `ABIERTA` sin colisión y sin «puerta abierta».
- [ ] **AC-19 (nacimiento)**: con ambas tarjetas verdaderas, `A05` nace `ABIERTO` sin llamar a `otorgar`; con solo `tarjeta_B`, nace `CERRADO`.
- [ ] **TR-access-004 / AC-14 (parte de 8)**: un test de estado confirma que ninguna acción de 8 cambia ningún hecho (los del Anexo D.2 intactos).
- [ ] `can_interact` del cajón es puro (lectura directa de hechos) y `interact` revalida el estado.

---

## Implementation Notes

- Los «hechos definitivos» al configurar vienen de `GameState` (nueva partida o restore de 3; guardado real diferido por ADR-0004).
- Estado expuesto a la escena por un objeto puro (`AccessModel`) para probarlo sin nodos.

---

## Out of Scope

- Story 003: transición de apertura. Story 005: apertura del cajón.

---

## Files

- `src/world/access/access.gd`, `src/world/access/access_model.gd`
- `tests/unit/access/configuracion_al_arrancar_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/access/configuracion_al_arrancar_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/acceso-puerta-a-cajon-a05/story-001-datos-access-json.md`; épico `estado-y-bus`
- Unlocks: `production/epics/acceso-puerta-a-cajon-a05/story-003-puerta-a-apertura.md`, `production/epics/acceso-puerta-a-cajon-a05/story-005-cajon-a05.md`
