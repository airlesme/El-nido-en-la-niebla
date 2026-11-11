# Story 004: Traspaso de `sin control` y duración declarada (`ESC1_LLEGADA`)

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

En «Nueva partida», el `sin control` de la carga pasa de 4 al director en el mismo fotograma de
«carga de escena terminada», sin que la pila pase nunca por `exploración`.

**GDD**: `design/gdd/director-de-escenas.md` (reglas 8a, 8e, 11, 16; F5)
**Requirement**: `TR-director-010`, `TR-director-011`, `TR-director-012`, `TR-director-025`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 D6 (traspaso, carga «terminada» con `control_final`/`t_since_started_s`); ADR-0017 D6; ADR-0006 (`InputContexts.no_control_margin_s()`, A3 aplicado)
**ADR Decision Summary**: traspaso viable si `M_traspaso = (D_carga + margen_E) − t_terminada ≥ 0`; si no, o si se rechaza, la escena degrada a momento y se registra, sin reintento.
**ADR Version**: ADR-0003 2026-11-10 · ADR-0017 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: ninguna API nueva; riesgo heredado de ADR-0003/0006.

**Control Manifest Rules (this layer)**:
- Required: FE-R21; `margen_E` leído de su dueño (FE-R26 / G-7)
- Forbidden: FE-X04 (7 no abre `sin control`; aquí: el director no lo reabre tras rechazo)
- Guardrail: FE-G03

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-04**: con «Nueva partida», al llegar «carga de escena terminada» el director traspasa el `sin control` (dueño 21, 15,0 s declarados) en ese fotograma sin pasar por `exploración`.
- [ ] **GDD 21 AC-21-22 (primera parte)**: con un traspaso rechazado, el director no abre otro `sin control`, la escena sigue como momento y se registra.
- [ ] **GDD 21 AC-21-07 (estado inyectado)**: con `control_final` = `exploracion` (equivalente a «Continuar»), `ESC1_LLEGADA` no se ejecuta.

---

## Implementation Notes

- `duracion_declarada = t_fin + h_decl_s` (1,0†) — de `director_config.json`.
- Tests con doble de 4 y Entrada **real** (TR-director-027), `D_carga` reducido.

---

## Out of Scope

- Story 005: cues dentro de `ESC1_LLEGADA`.

---

## Files

- `src/director/scene_director.gd`
- `tests/integration/director_de_escenas/no_control_handoff_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/director_de_escenas/no_control_handoff_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/director-escenas-1-3/story-002-cue-timeline-game-clock.md`, `production/epics/director-escenas-1-3/story-003-ciclo-de-vida-cancelacion.md`; `production/epics/carga-de-planta/`, `production/epics/entrada-y-controles/`
- Unlocks: `production/epics/director-escenas-1-3/story-005-esc1-tiempos-c1.md`
