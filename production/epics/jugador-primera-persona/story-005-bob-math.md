# Story 005: `BobMath` — balanceo de cámara ligado a la distancia

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R12, R16, § Formulas F3
**Requirement**: `TR-player-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D3 «Bob (F3) is translation only»; P-6; P-11)
**ADR Decision Summary**: el balanceo es solo traslación del nodo `Bob`, función de la distancia real `d` y de `r`; `g` sigue el nivel `balanceo_camara` con la rampa lineal `t_cambio_balanceo` en tiempo de juego; con `ninguno` el offset es exactamente `Vector3.ZERO`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura)
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: C-R19 (la rampa de nivel usa el `GameClock` inyectado), C-R22 (`BobMath` sin motor)
- Forbidden: C-X15 (`Timer`/`Tween` para decidir el fin de la rampa)
- Guardrail: C-G01

---

## Acceptance Criteria

- [ ] **AC-10**: GIVEN cualquier estado y el balanceo en `ninguno`, THEN la altura de los ojos es 1,62 m y el desplazamiento de la cámara respecto a los ojos es exactamente (0, 0, 0).
- [ ] **AC-15**: GIVEN `completo`, r = 1, WHEN d = 0,375 m, THEN `cámara.y` = −0,015 y `cámara.x` = +0,010; con `reducido`, `cámara.y` = −0,0075; con `ninguno`, ambos 0 en todo d.
- [ ] **AC-16**: GIVEN `completo` y empujando contra un muro, THEN `d` no avanza y el offset es (0, 0); WHEN se suelta `mover` a media zancada, THEN el offset tiende a 0 en ≤ 9 pasos sin discontinuidades > 2 mm por tick.
- [ ] **AC-17 (parte lógica)**: GIVEN `reducido`, WHEN el nivel inyectado cambia a `completo` caminando, THEN `g` pasa de 0,5 a 1,0 en 0,25 s ± 1 tick sin salto > 2 mm. *(El disparo desde Ajustes queda diferido por ADR-0007, ver `stories.md`.)*

---

## Implementation Notes

- El nivel (`ninguno`/`reducido`/`completo`) entra por un setter interno inyectado; en M1 el `Player` le pasa el valor por defecto. **No** crear lector de Ajustes (ADR-0007 Proposed).
- `g = 0.0` multiplica exacto: no usar umbrales para «apagar».
- Con cesión de cámara activa `Bob` = 0 (lo aplica 010/011, no esta clase).

---

## Out of Scope

- 006: emisión de `paso`; 011: nodo `Bob` y fase interpolada.

---

## Files

- `src/player/bob_math.gd`
- `tests/unit/player/bob_math_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/bob_math_test.gd` (T-U4) — must exist and pass.
**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-001-player-config.md`
- Unlocks: `production/epics/jugador-primera-persona/story-011-player-node-api.md`

---

## Evidencia

- `src/player/bob_math.gd` (estático `offset(d, r, g, cfg)` según el pseudocódigo del ADR-0012; rampa de nivel por instancia `configure/set_level/gain(now_s)` con tiempo inyectado, sin Timer/Tween). `tests/unit/player/bob_math_test.gd`: 17/17.
- Suite bloqueante completa: 713 casos, 0 errores, 0 fallos, 0 orphans; 0 `ObjectDB instances leaked` / `resources still in use`. `--import` sin errores propios.
- AC-10, AC-15, AC-16, AC-17 cubiertos. Nota AC-16/17: «sin discontinuidades > 2 mm» se mide como el salto causado solo por la caída de `r` (≤ 1,7 mm) o por la rampa de `g` (< 1 mm) a igual `d`; el paso normal a `v_paseo` ya mueve `y` hasta 3,4 mm/tick por la fase, así que la lectura literal sobre el offset total no es satisfacible.
- TODO(ADR-0012) con dueño lead-programmer: registrar `configure/set_level/gain` en § Key Interfaces.
