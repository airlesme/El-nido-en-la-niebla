# Story 008: Encadenado escenas 1–3 sin consola y cronometraje

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,0 d (confianza BAJA: depende de que el resto de épicos de M1 estén integrados)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Cierre del épico: partida nueva → escena 3 completa en un export, sin consola de depuración, con el
recorrido cronometrado (dato informativo).

**GDD**: `design/gdd/director-de-escenas.md` (reglas 5, 24) · `production/milestones/m1-gray-prototype.md` (C-M1-1, C-M1-8)
**Requirement**: `TR-director-007` (sin escrituras de hechos en el recorrido 1–3)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D6; ADR-0003 (cargas); ADR-0001
**ADR Decision Summary**: el director encadena escenas solo por el bus; nunca escribe hechos.
**ADR Version**: ADR-0017 2026-11-10 · ADR-0003 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (VERSION.md, 4.7; exports `playtest-windows`/`playtest-linux`)
**Engine Notes**: ninguna API nueva.

**Control Manifest Rules (this layer)**:
- Required: FE-R22, FE-R23
- Forbidden: consola de depuración en el recorrido
- Guardrail: FE-G03

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-02 (escenas 1–3)**: en un recorrido simulado de la escena 1 a la 3, el registro de escrituras de hechos no contiene ninguna del director.
- [ ] **C-M1-1**: partida nueva → escena 3 completa (cajón A05 abierto, `tarjeta_B` y `tarjeta_D` verdaderos) sin consola, en `playtest-windows` y `playtest-linux` — playtest documentado en `tests/playtest/m1-escenas-1-3.md`.
- [ ] **C-M1-8**: tiempo del recorrido 1→3 anotado en el mismo documento (informativo, sin umbral).

---

## Implementation Notes

- Evidencia del motor: `--write-movie production/qa/evidence/m1-run/run.png --fixed-fps 60` de la llegada (escena 1) y del Archivo abierto (escena 3); nunca captura del escritorio.
- Ruta «sin audio»: el recorrido no espera líneas; el audio provisional llega con el épico `audio-provisional`.

---

## Out of Scope

- Rendimiento (C-M1-10), otro épico.

---

## Files

- `tests/integration/director_de_escenas/scenes_1_3_no_fact_writes_test.gd`
- `tests/playtest/m1-escenas-1-3.md`, `production/qa/evidence/m1-run/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/director_de_escenas/scenes_1_3_no_fact_writes_test.gd` **y** playtest documentado `tests/playtest/m1-escenas-1-3.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/director-escenas-1-3/story-005-esc1-tiempos-c1.md`, `production/epics/director-escenas-1-3/story-006-mensaje-guardian.md`, `production/epics/director-escenas-1-3/story-007-esc3-vo-v-04-lluvia.md`; `production/epics/puzles-marco-y-p1/story-011-puerta-a-y-c05.md`; épico `production/epics/acceso-puerta-a-cajon-a05/`
- Unlocks: None
