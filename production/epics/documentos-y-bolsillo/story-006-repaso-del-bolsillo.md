# Story 006: Repaso del bolsillo (`repasar_bolsillo`) y pista única de sesión

> **Epic**: Documentos y bolsillo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L — 1,5 días (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/documentos-y-bolsillo.md` — § Detailed Rules › F (relectura); § Formulas (F2)
**Requirement**: `TR-pocket-013`, `TR-pocket-014`, `TR-pocket-015`, `TR-pocket-018` (solicitud de la pista; el dibujo es de 24)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (D4: 20 → 7 `abrir_lectura`); ADR-0011 (tabla de `abrir_lectura` y petición aplazada); ADR-0001 (avisos de lectura); ADR-0006 (acción derivada `repasar_bolsillo`)
**ADR Decision Summary**: `repasar_bolsillo()` (derivada de `atrás` en `exploración`) llama `abrir_lectura(item_id)` de 7 sobre la lista fija `repaso_orden` filtrada por `has_item`, con cursor de sesión `i_siguiente = (pos+1) mod m`; `repaso_pendiente` evita avanzar con peticiones ajenas; pista `UI_BOLSILLO_AYUDA` una vez por sesión.
**ADR Version**: ADR-0009 2026-11-10 · ADR-0011 2026-11-10 · ADR-0001 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguno.

**Control Manifest Rules (this layer)**:
- Required: F-R31, F-R32.
- Forbidden: guardar el cursor de repaso; mensaje cuando no hay nada que repasar.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/documentos-y-bolsillo.md`, scoped to this story (M1 solo adquiere `I-04`; las pruebas usan hechos forzados para `I-05`/`I-07`):*

- [ ] **AC-11**: con `I-07`, `I-05`, `I-04` presentes y cuatro llamadas `ACEPTADA` → abre `I-07`, `I-05`, `I-04`, `I-07`; sin ninguno, no hace nada.
- [ ] **AC-12 / AC-12b / AC-12c**: con una petición de 9 aplazada → `RECHAZADA`, el cursor no avanza, sin mensaje; con `APLAZADA` propia → espera «lectura abierta» sin repetir y avanza solo cuando llega; «lectura descartada» → no avanza; «lectura abierta» de una petición ajena no mueve el cursor.
- [ ] **AC-14 / AC-16 (orden)**: cerrar una lectura con `atrás` no lanza un segundo repaso con la misma pulsación; el orden es `repaso_orden` con independencia del orden de adquisición.
- [ ] **AC-18**: al entrar el primer documento relegible se solicita `UI_BOLSILLO_AYUDA` una vez por el puerto `PromptSink` de 7 (`mostrar_pie(clave, duracion_pie(clave), retener)`); no se repite en la sesión; tras restaurar (sesión nueva) puede pedirse otra vez.

---

## Implementation Notes

- La pista visible (pie de 24) está diferida por ADR-0016; aquí se verifica solo la solicitud contra un doble de `PromptSink`.
- La acción `repasar_bolsillo` la emite Entrada (ADR-0006); 20 la recibe por sink. Si ADR-0006 no fija cómo se enlaza la acción derivada a 20, ADR-fallback.

---

## Out of Scope

- Pantalla de lectura: diferida por ADR-0016.

---

## Files

- `src/systems/pocket/pocket_review.gd`
- `tests/integration/pocket/repaso_del_bolsillo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pocket/repaso_del_bolsillo_test.gd` (7 real o doble con la tabla de `abrir_lectura`) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`, `production/epics/interaccion-y-prompt/story-008-pila-de-modos-y-lectura.md`
- Unlocks: None
