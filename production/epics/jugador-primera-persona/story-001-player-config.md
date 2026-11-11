# Story 001: `PlayerConfig` y validación de `player.json`

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Tuning Knobs, § Edge Cases (datos inválidos), § Acceptance Criteria «Datos» (AC-41)
**Requirement**: `TR-player-002`, `TR-player-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Player controller, physics interpolation and camera (§ Key Interfaces «PlayerConfig», D1, D4) · ADR-0005: Data schema validation and content catalog (fila de registro `player/player.json`)
**ADR Decision Summary**: `PlayerConfig` (`src/player/player_config.gd`) es la vista tipada y validada de `assets/data/player/player.json`; todo knob del GDD con su rango y los invariantes derivados; cualquier fallo = fatal `CATALOGO_INVALIDO` con el nombre del parámetro.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (épico) / LOW para esta historia (lógica pura)
**Engine Notes**: Parser JSON de 4.7 cubierto por el spike S-0005-A de ADR-0005; esta historia no toca APIs post-corte nuevas.

**Control Manifest Rules (Core)**:
- Required: C-R14 (`player.json` lleva `f_fisica` y el arranque lo compara con la tasa del motor; discrepancia = fatal); C-R20 (claves `_deg` convertidas **una vez** en `PlayerConfig`, ángulos públicos en radianes)
- Forbidden: valores de juego en código (coding-standards: data-driven)
- Guardrail: C-G01 (≤ 64 KB de estado del Player)

---

## Acceptance Criteria

*From GDD, scoped to this story:*

- [ ] **AC-41**: GIVEN una fixture con `v_paseo` = 2,0, THEN F1 usa 2,0 sin recompilar; GIVEN fixtures con `radio_capsula` = 0,30 o 0,40, `pitch_max` = 95, `T_hist` = 0,4, `g_reducido` ≥ `g_completo`, `radio_sensor_zona` = 0,10 o sin fichero, THEN no se entra en partida, se invoca el manejador de error fatal inyectado con el nombre del parámetro y no se carga la escena.
- [ ] **TR-player-002**: el invariante `2×radio_capsula + margen_paso (0,10) = player_min_passage_width_m (0,60)` se comprueba al cargar.
- [ ] **TR-player-021 / ADR-0012 D1**: `f_fisica` distinto de `Engine.physics_ticks_per_second` (60, medido en S-0012-A NP-2) es fatal.
- [ ] Toda duración de gesto bloqueante del catálogo `gestures` ≤ `t_transicion_max` (3 s) — se valida aunque las manos estén fuera de M1, porque el esquema es de este ADR.

---

## Implementation Notes

*Derived from ADR-0012 § Key Interfaces y D4:*

- Esquema propiedad de ADR-0012; registro y cargador, de ADR-0005. Invariantes listados en el ADR: `2·radio_capsula + margen_paso = player_min_passage_width_m`, `g_reducido < g_completo`, `pitch_max_deg < 90`, `T_hist ≥ 0.6`, blocking `duration_s ≤ t_transicion_max`, `f_fisica` = tick rate del motor.
- Ángulos en datos con sufijo `_deg` (`pitch_max_deg`, `pitch_cesion_max_deg`); `PlayerConfig` expone radianes. `campo_vision` y `balanceo_camara` **no** viven aquí (Ajustes, GDD 6): en M1 se usan sus valores por defecto (70°, nivel inicial) inyectados, sin lector de Ajustes (ADR-0007 Proposed).
- La tasa del motor se inyecta para el test (no leer `Engine` dentro de la lógica, C-R22).
- **Sin firma en el ADR** para el constructor/fábrica de `PlayerConfig` (p. ej. `from_dict(d) -> PlayerConfig` o similar): la fija esta historia y se anota en ADR-0012 § Key Interfaces como enmienda (ADR-fallback).

---

## Out of Scope

- 002–010: el uso de cada knob.
- Lector y suscripción de Ajustes (ADR-0007, diferido).

---

## Files

- `src/player/player_config.gd`
- `assets/data/player/player.json`
- `tests/fixtures/player/player_valid.json` y fixtures inválidas
- `tests/unit/player/player_config_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/player_config_test.gd` (T-U13 de ADR-0012) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: cargador de datos de ADR-0005 (épico de datos/contenido); None dentro de este épico
- Unlocks: `production/epics/jugador-primera-persona/story-002-locomotion.md`, `story-004-look.md`, `story-005-bob-math.md`, `story-006-step-tracker.md`, `story-007-pose-history-yaw-window.md`, `story-008-stuck-guard.md`
