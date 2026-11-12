# Story 002: Locomoción F1/F2 en el marco del cuerpo

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R6–R9, § Formulas F1, F2
**Requirement**: `TR-player-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D1 pasos 2 y 4; P-1; P-11)
**ADR Decision Summary**: velocidad calculada en el marco del cuerpo con F1, acelerada con F2 (`a_freno` sii `v·v_obj < −0,001` o `|v_obj| < |v| − 0,001`) y girada por `_yaw`; `Locomotion` es `RefCounted` sin motor.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura; el `move_and_slide` es de 011/012)
**Engine Notes**: ninguna API de motor en esta clase (P-11).

**Control Manifest Rules (Core)**:
- Required: C-R14 (integración solo en `_physics_process`, `dt = 1/f_fisica` fijo, tras la guarda G-4), C-R22 (`Locomotion` sin motor)
- Forbidden: C-X12 (mover el cuerpo con el delta de fotograma), C-X13 (rotar el cuerpo)
- Guardrail: C-G01

---

## Acceptance Criteria

- [ ] **AC-01**: GIVEN `v_paseo` = 1,6 y `k_atras` = 0,8, WHEN `m` vale (0, 1), (0, −1), (0,7071; 0,7071), (1, 1) y (0, 0,5), THEN `v_obj` es (0; 1,6), (0; −1,28), (1,131; 1,131), (1,131; 1,131) y (0; 0,8).
- [ ] **AC-02**: GIVEN reposo, WHEN `m` = (0, 1) durante 12 pasos de 1/60 s, THEN `v` = 1,6 m/s y la distancia es 0,173 m; WHEN después `m` = (0, 0), THEN `v` = 0 a los 9 pasos y la distancia adicional es 0,107 m.
- [ ] **AC-03**: GIVEN 1,6 m/s hacia delante con yaw 0°, WHEN el yaw pasa a 90° en un tick con `m` = (0, 1), THEN la velocidad en el mundo gira 90° sin pérdida de módulo en el mismo tick.
- [ ] **AC-45**: tabla de pasos de `v.y` con `v` = (0; 1,6) y `m` = (0, −1) (1,422 · 1,244 · … · 0 · −0,133; cruza 0 a los 9 pasos, −1,28 a los 19); `v` = (1,6; 0), `m` = (0, 1) → (0; 1,6) a los 17 pasos; `m` = (0, 0) → 0 a los 9 pasos. Más **AC-04 (parte b)**: `m` = NaN se trata como (0, 0) con una línea de log.

---

## Implementation Notes

- D1 paso 2: `mover` vale cero salvo en Libre (la máquina de estados es 009); NaN/∞ → cero + log.
- D1 paso 4: tras `move_and_slide()` se **adopta la velocidad horizontal deslizada** de vuelta al marco del cuerpo (cubre AC-05 en 012). La API de esta clase debe permitir ese paso de adopción.
- Tolerancia ±0,002 (GDD). Fixtures de `tests/fixtures/player/`, sin números mágicos salvo los del AC.
- Firmas internas de `Locomotion` no fijadas por el ADR: se definen aquí (privadas al módulo del Player, P-8).

---

## Out of Scope

- 011/012: llamada real a `move_and_slide()`, gravedad, adopción con colisión real.
- 009: qué estado anula `mover`.

---

## Files

- `src/player/locomotion.gd`
- `tests/unit/player/locomotion_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/locomotion_test.gd` (T-U1) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-001-player-config.md`
- Unlocks: `production/epics/jugador-primera-persona/story-009-state-machine-colocar.md`, `story-011-player-node-api.md`

---

## Evidencia

- `src/player/locomotion.gd` (`Locomotion`, `RefCounted` estático, sin motor): `target` (F1), `accelerate` + `brake_applies` (F2), `to_world`/`to_body` (giro por yaw y adopción del deslizamiento), `sanitize_move` (NaN/∞ → cero + `push_warning`). Firmas fijadas aquí con `# TODO(ADR-0012)` (dueño lead-programmer): el ADR solo esboza nombres.
- `tests/unit/player/locomotion_test.gd`: 28 casos. AC-01, AC-02 (12 pasos/0,173 m; 9 pasos/0,107 m), AC-03, AC-45 (tabla de inversión, 9 y 19 pasos, lateral→avance 17, parada 9), AC-04 b. Límites (sin sobrepasar, dt inválido, tolerancia del freno, k_lat/v_paseo desde datos).
- Ejecución local (Godot 4.7.2): `--import` sin errores; `-a res://tests/unit/player`: 69 casos, 0 fallos, 0 huérfanos, sin avisos de fuga.
- Suite bloqueante completa: 528 casos, 1 fallo ajeno (`tests/unit/content/data_validator_test.gd::test_registry_lists_m1_rows_in_fixed_order`: el registro ya incluye `scene/load_transitions.json`, trabajo en curso de CP-002) y fugas `ObjectDB`/`resources still in use` al salir que no aparecen en las suites de `player` por separado. No es de esta historia.
