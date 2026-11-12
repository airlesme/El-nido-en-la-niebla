# Story 006: `StepTracker` y señal `paso`

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R31, § Formulas F3 (pasos ligados a la distancia)
**Requirement**: `TR-player-009` (fase `d` y `L_paso`), `TR-player-020` (señal `paso` de la API)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D1 paso 5, D10 `paso`; P-11) · ADR-0009 (D4: señal de contrato 2 → 23, nunca el bus)
**ADR Decision Summary**: `paso(superficie, intensidad)` se emite en cada `d = (n + ½)·L_paso` de desplazamiento real; `superficie` sale de un puerto `SurfaceProbe` (`&"default"` si falta).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (lectura de metadatos del suelo)
**Engine Notes**: **Medido en S-0012-C NP-8**: `get_slide_collision(i).get_collider().get_meta("surface")` devuelve la etiqueta (`test`). La implementación de producción del puerto usa ese patrón (C-R24).

**Control Manifest Rules (Core)**:
- Required: C-R22 (`StepTracker` sin motor; el suelo detrás de `SurfaceProbe`), C-R24
- Forbidden: C-X16 (el Player no emite al bus)
- Guardrail: C-G01

---

## Acceptance Criteria

- [ ] **AC-38**: GIVEN 3,0 m caminados a `v_paseo` desde reposo, THEN se emiten 4 señales `paso` (en d = 0,375; 1,125; 1,875; 2,625 m), con intensidad `lerp(i_paso_min, 1, r)` (≥ 0,4; 1,0 con r = 1; 0,7 con r = 0,5); con balanceo `ninguno` también se emiten; contra un muro, ninguna.
- [ ] Sin metadato `surface` en el suelo, `superficie` = `&"default"` (único valor del slice, GDD 2 OQ 6).

---

## Implementation Notes

- `d` acumula `|Δpos_horizontal|` **después** de las colisiones (D1 paso 4): contra un muro no avanza.
- Puerto `SurfaceProbe.floor_surface() -> StringName` (firma de § Key Interfaces); en test, un fake.
- La señal la emite el `Player` (011) desde `_physics_process` (P-9); esta clase solo informa de cruces.

---

## Out of Scope

- Consumo por Audio (23, ADR-0008 Proposed): fuera de este épico.

---

## Files

- `src/player/step_tracker.gd`
- `src/player/ports/surface_probe.gd`
- `tests/unit/player/step_tracker_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/step_tracker_test.gd` (T-U10) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-001-player-config.md`
- Unlocks: `production/epics/jugador-primera-persona/story-011-player-node-api.md`

---

## Evidencia

- `tests/unit/player/step_tracker_test.gd`: 10 casos, 0 fallos (AC-38: 3,0 m a 1,6 m/s en ticks de 1/60 -> 4 cruces en 0,375/1,125/1,875/2,625; intensidad 1,0 / 0,7 / 0,4; sin avance (muro) -> 0; limites e invalidos; `SurfaceProbe` por defecto `&"default"`).
- La clase solo informa de cruces; la intensidad no depende del nivel de balanceo (el Player 011 emite la senal). El puerto de produccion (lectura de `get_meta("surface")`) queda para el Player 011.
- Suite bloqueante: `Overall Summary: 705 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`; 0 coincidencias de `leaked` / `still in use`.
- TODO(ADR-0012) (lead-programmer): `crossings(d_from, d_to, l_paso) -> Array[float]` e `intensity(r, i_paso_min)` por ADR-fallback.
