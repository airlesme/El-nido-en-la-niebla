# Story 002: `load_transitions.json` y su validación

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Tuning Knobs, § Acceptance Criteria «Datos» (AC-D1, AC-D2)
**Requirement**: `TR-scene-015`, `TR-scene-022`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (Implementation Guidelines: `SceneLoader.validate`) · ADR-0005 (registro de datos y esquema)
**ADR Decision Summary**: las duraciones de fundido por `motivo` viven en `assets/data/scene/load_transitions.json` y se validan al arrancar; inválido o ausente → manejador fatal con `DATOS_ESCENA_INVALIDOS` y el nombre del parámetro.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: parser JSON 4.7 cubierto por S-0005-A (ADR-0005).

**Control Manifest Rules (Core)**:
- Required: C-R13
- Forbidden: valores de fundido en código
- Guardrail: —

---

## Acceptance Criteria

- [ ] **AC-D1**: GIVEN contenidos de fixture inyectados como diccionarios (`d_out` = 6, `T_cap` = 2, `N_gap` = 11, `Δ_max` = 0,2), WHEN se valida, THEN en cada caso no se entra en partida y el manejador fatal recibe `DATOS_ESCENA_INVALIDOS` con el nombre del parámetro.
- [ ] **AC-D2 (I)**: GIVEN `assets/data/scene/load_transitions.json` ausente o corrupto en disco, WHEN arranca el juego, THEN no se entra en partida y se muestra el mensaje de error.
- [ ] **AC-F1 (tabla)**: GIVEN la tabla de datos, THEN `partida_nueva` tiene d_in = 2,0, `reanudar` d_in = 0,8 y `recepcion` d_out = d_in = 0,8 (rangos: `d` ≤ 5 s, `T_cap` 3–30, `N_gap` 0–10, `Δ_max` 0,05–0,1).

---

## Implementation Notes

- Tipo `LoadTransitions` (nombre de § Key Interfaces de ADR-0003, parámetro de `setup`); el método de validación se llama `SceneLoader.validate` en el ADR. Su firma no está fijada: definirla aquí y anotarla en ADR-0003 (ADR-fallback).
- La entrada `cierre` (solo oscurece) también figura en los datos (TR-scene-015).
- AC-D2 es integración (fichero real): `tests/integration/scene/`.

---

## Out of Scope

- 003: uso de las duraciones en F1/F3; `reducir_movimiento` real de Ajustes (ADR-0007 Proposed): en M1 valor por defecto inyectado.

---

## Files

- `assets/data/scene/load_transitions.json`, `src/scene/load_transitions.gd`
- `tests/unit/scene/load_transitions_validation_test.gd`, `tests/integration/scene/load_transitions_file_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/load_transitions_validation_test.gd` (T-U11) — must exist and pass; AC-D2 en `tests/integration/scene/load_transitions_file_test.gd`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: cargador de datos de ADR-0005; None dentro de este épico
- Unlocks: `production/epics/carga-de-planta/story-003-curtain-and-dcarga-formulas.md`
