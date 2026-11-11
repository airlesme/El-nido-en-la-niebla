# Story 015: Test de estado de M1 — 5 flags por su dueño, sin estados terminales en escenas 1–3

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Acceptance Criteria (CA-31, CA-32); hito `production/milestones/m1-gray-prototype.md` § Criterios de salida C-M1-3, C-M1-4
**Requirement**: `TR-state-005` (dueño), `TR-state-011` (sin «avisos descartados» en el recorrido)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (D7, D5) · ADR-0009 (D9 dobles)
**ADR Decision Summary**: El contrato de escritor único se comprueba en dev; el test de estado recorre el espacio alcanzable de los 5 hechos de M1 con emisores de prueba que escriben con el `FactWriter` de su dueño.
**ADR Version**: ADR-0001 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R05, F-R37 (`TestContexts`)
- Forbidden: tocar un autoload desde la suite
- Guardrail: cola máxima observada < `max_chained_notices`

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md` y el hito, scoped to M1:*

- [ ] **C-M1-4**: `correos_leidos` (19), `archivo_abierto` (9), `formulario_leido`, `tarjeta_B`, `tarjeta_D` (20) solo los escribe su dueño; un escritor ajeno en dev es inválido (con emisores de prueba).
- [ ] **C-M1-3 (parte automática)**: ningún estado alcanzable de los 5 hechos en las escenas 1–3 impide llegar a `tarjeta_B ∧ tarjeta_D` (enumeración del orden de escrituras permitido por los dueños).
- [ ] **CA-32 (con emisores)**: la secuencia de escrituras y avisos del recorrido 1–3 no emite `notices_dropped` y la cola más larga queda por debajo de `max_chained_notices`.
- [ ] **CA-31** queda **parcial**: se cierra cuando existan los escritores reales (19, 9, 20) — anotarlo en la evidencia.

---

## Implementation Notes

- El «grafo» de qué hecho habilita qué escritura sale del slice (C.2–C.3) y de los GDD de 19, 9 y 20; si una precondición no está escrita en ellos, no se inventa: se marca la arista como supuesta en el test y se pregunta en `/consistency-check`.
- El recorrido manual de fallo ×5 de P1 (C-M1-3) es del épico puzles-marco-y-p1.

---

## Out of Scope

- Escritores reales; recorrido manual de C-M1-3.

---

## Files

- `tests/integration/state/m1_state_reachability_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/state/m1_state_reachability_test.gd` OR playtest doc.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-006-flags-json-data.md`, `production/epics/estado-y-bus/story-009-one-way-and-reversible-facts.md`, `production/epics/estado-y-bus/story-010-derived-facts.md`, `production/epics/estado-y-bus/story-014-boot-wiring-state.md`
- Unlocks: None
