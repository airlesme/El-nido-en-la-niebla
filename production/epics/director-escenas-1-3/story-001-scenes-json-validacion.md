# Story 001: `scenes.json` y `director_config.json` — esquema y validación

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Las escenas son datos declarativos (disparador + condiciones + cues). Una escena mal formada se
descarta sola y el resto funciona.

**GDD**: `design/gdd/director-de-escenas.md` (regla 3)
**Requirement**: `TR-director-003`, `TR-director-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D1 (`director/scenes.json`), D9 (validación nivel L en `setup`); ADR-0005 D2–D3 (esquemas, niveles L/B/C; A5 aplicado: `al_disparar`, `cadena`, campos de cue)
**ADR Decision Summary**: ID repetido, orden desconocida o `t_rel` decreciente descartan esa escena (error visible en desarrollo; en build, descarte + una línea de log).
**ADR Version**: ADR-0017 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0017) — HIGH según VERSION.md para 4.7
**Engine Notes**: JSON solo por el envoltorio de ADR-0005.

**Control Manifest Rules (this layer)**:
- Required: FE-R26 (ningún valor de `scenes.json`/`director_config.json` duplicado en código)
- Forbidden: `JSON.parse_string` fuera de ADR-0005
- Guardrail: validación solo al arrancar

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-01**: con un ID repetido, una orden desconocida o `t_rel` decreciente, esa escena se descarta, se registra una línea (error visible en desarrollo) y las demás se cargan.
- [ ] Las entradas de M1 (`ESC1_LLEGADA`, la de `VO_V_04` de la escena 3) pasan la validación con los tiempos del Anexo C.1 del slice como dato (1,5 / 6,0 / 12,0 / 14,0 s; +1,0 s).

---

## Implementation Notes

- Rutas de datos: `assets/data/director/scenes.json`, `assets/data/director/director_config.json` (ADR-0017 D1; el EPIC menciona `scenes/scenes.json`: prevalece el ADR, anotar la discrepancia).
- Solo se escriben las escenas 1–3; el esquema admite las 8.

---

## Out of Scope

- Story 002: ejecución de la línea de tiempo.

---

## Files

- `assets/data/director/scenes.json`, `assets/data/director/director_config.json`
- esquema según ADR-0005 D2 en `src/director/` (nombre según el registro de ADR-0005 D1)
- `tests/unit/director_de_escenas/scenes_validation_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/director_de_escenas/scenes_validation_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `DataValidator` (`production/epics/contenido-y-datos/`)
- Unlocks: `production/epics/director-escenas-1-3/story-005-esc1-tiempos-c1.md`, `production/epics/director-escenas-1-3/story-007-esc3-vo-v-04-lluvia.md`
