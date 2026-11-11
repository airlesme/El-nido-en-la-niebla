# Story 007: `ESC3` — `formulario_leido` → `LLUVIA_REALCE` + `VO_V_04` (tiempos de C.3)

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Escena 3 (C.3): al leer A04 (2 s, sistema 20) se escribe `formulario_leido`; el director espera
`d_vo04_s`, intensifica la lluvia y pide `VO_V_04`, una sola vez.

**GDD**: `design/gdd/director-de-escenas.md` (regla 5)
**Requirement**: `TR-director-007`, `TR-director-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D1, D2, D5; ADR-0001 (aviso de cambio de hecho)
**ADR Decision Summary**: el director lee hechos y nunca escribe; reacciona al aviso de cambio, no al valor al cargar.
**ADR Version**: ADR-0017 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: FE-R21, FE-R23, FE-R26 (`d_vo04_s` en datos)
- Forbidden: FE-X11
- Guardrail: FE-G03

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-08**: cuando `formulario_leido` cambia a verdadero, tras `d_vo04_s` se emite `LLUVIA_REALCE` y se pide `VO_V_04` una vez (±1 fotograma, `GameClock` falso); con `formulario_leido` ya verdadero al configurar (estado inyectado), no se emite ninguna.
- [ ] **C-M1-5 (C.3)**: el test de timeline compara `t_rel` de ambas órdenes con `scenes.json`, ±1 fotograma.
- [ ] **TR-director-007**: el director no escribe ningún hecho (doble de `FactWriter` que falla ante cualquier escritura).

---

## Implementation Notes

- `ANIM_DOOR_OPEN` 1,2 s y la lectura de A04 no son del director (sistemas 8 y 20).
- «Continuar» desde partida guardada → **Diferido** (ADR-0004); se prueba con estado inyectado.

---

## Out of Scope

- Atmósfera real de la lluvia (S0b).

---

## Files

- `assets/data/director/scenes.json` (escena 3)
- `tests/unit/director_de_escenas/esc3_c3_timing_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/director_de_escenas/esc3_c3_timing_test.gd` con `GameClock` falso — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/director-escenas-1-3/story-001-scenes-json-validacion.md`, `production/epics/director-escenas-1-3/story-002-cue-timeline-game-clock.md`
- Unlocks: `production/epics/director-escenas-1-3/story-008-encadenado-escenas-1-3.md`
