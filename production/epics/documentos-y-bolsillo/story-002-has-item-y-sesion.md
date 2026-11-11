# Story 002: `has_item` derivado de hechos y conjunto de sesión (`I-01`)

> **Epic**: Documentos y bolsillo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/documentos-y-bolsillo.md` — § Detailed Rules › C (adquisición), G (persistencia y propiedad); § Formulas (F3)
**Requirement**: `TR-pocket-002`, `TR-pocket-003`, `TR-pocket-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (D3 `configurar(ctx)`, inyección sin singleton, D4 llamadas permitidas); ADR-0001 (lectura de hechos por `GameState` inyectado); ADR-0005 (catálogo)
**ADR Decision Summary**: el bolsillo no tiene almacenamiento propio: `has_item(id)` se deriva del hecho correspondiente o del conjunto de sesión (`I-01`, solo memoria, vaciado al descargar planta, nueva partida y carga); no hay API para tirar, soltar, combinar ni consumir.
**ADR Version**: ADR-0009 2026-11-10 · ADR-0001 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguno.

**Control Manifest Rules (this layer)**:
- Required: F-R05, F-R28 (`configurar(ctx)` con `ctx.require`), F-R29, F-R31.
- Forbidden: persistencia propia de 20; operaciones de consumo.
- Guardrail: `has_item` barato (lectura directa).

---

## Acceptance Criteria

*From GDD `design/gdd/documentos-y-bolsillo.md`, scoped to this story:*

- [ ] **AC-02**: con `tarjeta_B` verdadero, `has_item("I-02")` es verdadero e `I-03` falso; al restaurar una instantánea con `caja_c1`, `caja_c2`, `caja_c4` verdaderos, `has_item` es verdadero para `I-06a`, `I-05`, `I-07` sin llamar a ninguna función de 20.
- [ ] **AC-05**: tras `otorgar_sesion("I-01")`, al restaurar/cargar, `has_item("I-01")` es falso aunque `correos_leidos` sea verdadero.
- [ ] **AC-05b (con doble de 19)**: tras la carga, una nueva `otorgar_sesion("I-01")` deja `has_item("I-01")` verdadero (la parte «P1 resoluble» se cierra en el épico puzles-marco-y-p1).
- [ ] **AC-19**: la API pública de 20 no tiene operación de tirar/soltar/combinar/consumir; usar una tarjeta o `reposo()` no pone ningún hecho a falso.

---

## Implementation Notes

- «Cargar» en M1 = `GameState` restore/reset (ADR-0001); el guardado real (ADR-0004, Proposed) no se necesita: la prueba usa la instantánea de 3.
- El conjunto de sesión se vacía en «escena descargada», `state_reset` y `state_restored` (nombres del registro de ADR-0001).

---

## Out of Scope

- Story 003: escritura de hechos. Story 005: vaciado durante la descarga con presentación en curso.

---

## Files

- `src/systems/pocket/pocket.gd`
- `tests/unit/pocket/has_item_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pocket/has_item_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/documentos-y-bolsillo/story-001-catalogo-items.md`; épico `estado-y-bus` (`GameState`, instantánea)
- Unlocks: `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`
