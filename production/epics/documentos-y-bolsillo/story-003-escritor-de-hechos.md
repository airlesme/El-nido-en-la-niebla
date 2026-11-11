# Story 003: Escritor único — `formulario_leido`, `otorgar("A05")` → `tarjeta_B`, `tarjeta_D`

> **Epic**: Documentos y bolsillo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/documentos-y-bolsillo.md` — § Detailed Rules › C (adquisición), E (lectura), G (propiedad)
**Requirement**: `TR-pocket-004`, `TR-pocket-005`, `TR-pocket-012`, `TR-pocket-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (D7 `FactWriter` con `owner = 20`, D11/registro: `reading_completed`, `reading_opened`, `reading_closed`, `reading_discarded`); ADR-0009 (inyección del `FactWriter` por la raíz de composición)
**ADR Decision Summary**: 20 es el único escritor de `formulario_leido`, `tarjeta_B`, `tarjeta_D` (monótonos falso→verdadero) a través del `FactWriter` que le entrega `GameState.writer_for(20)`; hecho primero, presentación después.
**ADR Version**: ADR-0001 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguno.

**Control Manifest Rules (this layer)**:
- Required: F-R05 (solo por el `FactWriter` inyectado; nunca pasa su número de propietario), F-R31 (suscripciones en `SubscriptionBag`).
- Forbidden: escribir un hecho de otro dueño; escribir en falso.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/documentos-y-bolsillo.md`, scoped to this story:*

- [ ] **AC-03**: con «lectura completada» de `A04`, `formulario_leido` pasa a verdadero una vez; si llega de nuevo, no hay aviso de cambio.
- [ ] **AC-10 (lógica, con reloj falso y 7 real o doble)**: lectura de 1,9 s y cierre → `formulario_leido` sigue falso; 2,0 s → verdadero.
- [ ] **AC-04**: `otorgar("A05")` con ambas tarjetas falsas escribe `tarjeta_B` y **luego** `tarjeta_D`; una segunda llamada no escribe ni presenta.
- [ ] **C-M1-4 (parte de 20)**: un test de estado comprueba que los 3 flags solo los escribe 20 (escritura desde otro `FactWriter` rechazada por 3).

---

## Implementation Notes

- 20 se suscribe a `&"reading_completed"` con payload `doc` (‡ en ADR-0001: confirmar la clave del payload en el registro de nombres; si no está fijada, ADR-fallback).
- `otorgar(origen)` es idempotente: comprueba el hecho antes de escribir y solo inicia la presentación (005) si escribió algo.
- Firma de `otorgar`: el GDD fija `otorgar("A05")`; el tipo de retorno no lo fija ningún ADR → tarea de la historia con ADR-fallback (proponer `-> void`).

---

## Out of Scope

- Story 005: presentación de las tarjetas. Story 004: tapa `A03`.

---

## Files

- `src/systems/pocket/pocket.gd` (escritura y suscripciones)
- `tests/unit/pocket/escritor_de_hechos_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pocket/escritor_de_hechos_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/documentos-y-bolsillo/story-002-has-item-y-sesion.md`, `production/epics/interaccion-y-prompt/story-008-pila-de-modos-y-lectura.md` (emisor de `reading_completed`; un doble basta para la prueba unitaria)
- Unlocks: `production/epics/documentos-y-bolsillo/story-004-tapa-a03.md`, `production/epics/documentos-y-bolsillo/story-005-presentacion-tarjetas.md`, `production/epics/documentos-y-bolsillo/story-006-repaso-del-bolsillo.md`, `production/epics/acceso-puerta-a-cajon-a05/story-005-cajon-a05.md`
