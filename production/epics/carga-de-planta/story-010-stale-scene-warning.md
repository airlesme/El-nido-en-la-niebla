# Story 010: Aviso de escena obsoleta

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R17 (escena obsoleta)
**Requirement**: `TR-scene-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (§ Preconditions «Stale scene (rule 17)») · ADR-0001 (avisos «estado restablecido» / «estado restaurado», entrega en el fotograma)
**ADR Decision Summary**: ante «estado restablecido»/«estado restaurado» con estado Lista, 4 comprueba **al final del fotograma** (cola del bus vacía) si llegó un `request_load`; solo si no, advertencia (dev: error visible), sin parchear elementos. Evita el falso positivo de «Nueva partida» desde la pausa.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: suscripción al bus de ADR-0001 (4 sí puede escuchar avisos; solo lee el hecho `llamada_completada`)
- Forbidden: C-X05 (escribir hechos)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **AC-18**: GIVEN una escena cargada con un elemento espía, WHEN llega «estado restaurado» sin petición de recarga, THEN se registra una advertencia (dev: error visible) y `configurar()` recibe 0 llamadas nuevas.
- [ ] GIVEN «estado restablecido» seguido de `request_load` en el mismo fotograma, THEN no hay advertencia (T-U10).

---

## Implementation Notes

- «Final del fotograma» = tras vaciarse la cola de avisos de ADR-0001 (`GameState.queue_empty()` según la tabla de descarga total de ADR-0003).

---

## Out of Scope

- Guardado/restauración real (recorte 4).

---

## Files

- `src/scene/scene_loader.gd`
- `tests/unit/scene/stale_scene_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/stale_scene_test.gd` (T-U10) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-004-loader-preconditions-states.md`
- Unlocks: None
