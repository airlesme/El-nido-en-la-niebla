# Story 003: Ciclo de vida persistente y matriz de cancelación

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

El director es un autoload que sobrevive a los cambios de escena. Ante una carga fallida, una carga
no pedida o la descarga total, suelta todo sin emitir nada.

**GDD**: `design/gdd/director-de-escenas.md` (reglas 1, 1b, 8e, 11b)
**Requirement**: `TR-director-001`, `TR-director-002`, `TR-director-014`, `TR-director-015` (borrado del estado volátil)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D6 (ciclo de vida y matriz de cancelación); ADR-0003 (avisos de carga y descarga total); ADR-0009 (autoload, `setup(ctx)`)
**ADR Decision Summary**: suscripción al bus al arrancar, sin baja; estado «inactivo» desde la petición de descarga total hasta «descarga total completada»; cancelar = soltar ejecuciones y cadena.
**ADR Version**: ADR-0017 2026-11-10 · ADR-0003 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (`process_mode` del autoload)
**Engine Notes**: `SceneDirector` con `process_mode` `ALWAYS` fijado explícitamente (ADR-0002 D2, F-R18, F-X22).

**Control Manifest Rules (this layer)**:
- Required: FE-R22 (descartar toda ejecución viva con `scene_load_started`, `scene_load_failed`, `no_control_absorbed`, `full_unload_requested`, `state_reset`, `state_restored`; sin órdenes, pila ni hechos)
- Forbidden: F-X22 (autoload que hereda `process_mode`)
- Guardrail: FE-G03

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-22 (segunda parte)**: con «carga de escena fallida», se cancelan todas las ejecuciones sin órdenes ni hechos.
- [ ] **TR-director-002**: entre la petición de descarga total y «descarga total completada» el director ni escucha (salvo esa señal) ni emite; reloj parado.
- [ ] **TR-director-014**: «carga de escena iniciada» no pedida y «`sin control` absorbido» (dueño 21) cancelan sin órdenes ni hechos y rearman las escenas.

---

## Implementation Notes

- Extender `src/director/scene_director.gd` existente (`_init`, `setup(_ctx)`): la firma `setup(ctx: ServiceContext)` está fijada en ADR-0017 l. 764.
- Tests con doble de bus que registra todo lo emitido y falla ante cualquier emisión tras cancelar.

---

## Out of Scope

- Story 004: traspaso de `sin control`.

---

## Files

- `src/director/scene_director.gd`
- `tests/unit/director_de_escenas/lifecycle_cancellation_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/director_de_escenas/lifecycle_cancellation_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/director-escenas-1-3/story-002-cue-timeline-game-clock.md`
- Unlocks: `production/epics/director-escenas-1-3/story-004-traspaso-sin-control.md`
