# Story 007: `PoseHistory` y `YawWindow` (servicios)

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R29–R30, § Formulas F6, F8
**Requirement**: `TR-player-016`, `TR-player-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D7; P-5; P-8)
**ADR Decision Summary**: búferes circulares por columnas de `N = ceil(T_hist × f_fisica) + 2` (62) muestras escritas una vez por tick desde el estado físico; `pose_con_retardo(τ)` con τ limitado a [0, `T_hist`] e interpolación (yaw por arco corto); `giro_acumulado()` suma bajo demanda un anillo de 30 `|Δyaw_tick|` (sin suma corriente).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura)
**Engine Notes**: `PackedVector3Array` / `PackedFloat32Array` para las columnas (D7).

**Control Manifest Rules (Core)**:
- Required: C-R18 (servicios leen estado físico), C-R21 (ninguna operación pública escribe la memoria de poses)
- Forbidden: —
- Guardrail: C-G01 (0 asignaciones por fotograma salvo ≤ 1 `PlayerPose`)

---

## Acceptance Criteria

- [ ] **AC-35**: GIVEN `f_fisica` = 60 y `T_hist` = 1,0, THEN `N` = 62; GIVEN 2 s a 1,6 m/s al este, THEN `pose_con_retardo(0,6)` queda 0,96 ± 0,02 m al oeste; `pose_con_retardo(0)` = muestra 0 y `pose_con_retardo(1,0)` = muestra 60 sin leer fuera del búfer; τ = −1 y τ = 5 se limitan a 0 y 1,0 sin error; justo tras `colocar` (`fill`), `pose_con_retardo(0,6)` y `(1,0)` = pose inicial.
- [ ] **AC-37**: GIVEN un giro de 60 °/s durante 0,5 s, THEN `giro_acumulado` = 30° ± 0,5° (en radianes en la API); en reposo = 0; `colocar` lo pone a 0.

---

## Implementation Notes

- D7: `i = min(floor(s), N − 2)`, `α = clamp(s − i, 0, 1)`, `s = τ × f_fisica`; `fill(pose)` escribe las N muestras.
- Tipo de retorno `PlayerPose` (`src/player/player_types.gd`, § Key Interfaces): `position` (pies), `yaw`, `pitch`, `speed_h`, `step_phase`.
- La escritura es interna del módulo; AC-36 (ninguna operación pública escribe) se prueba en 011.

---

## Out of Scope

- 011: exposición en la API (`pose_actual`, `pose_con_retardo`, `giro_acumulado`). Consumo por 28 (reflejo): fuera de M1.

---

## Files

- `src/player/pose_history.gd`, `src/player/yaw_window.gd`, `src/player/player_types.gd`
- `tests/unit/player/pose_history_test.gd`, `tests/unit/player/yaw_window_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/pose_history_test.gd` (T-U8) y `tests/unit/player/yaw_window_test.gd` (T-U9) — must exist and pass.
**Status**: [ ] Not yet created

---

## Evidencia

- AC-35 y AC-37 cubiertos por `tests/unit/player/pose_history_test.gd` (11) y `yaw_window_test.gd` (8): 19/19, 0 huérfanos.
- Suite bloqueante completa (Godot 4.7.2 local, `-i res://tests/timing`): 713 test cases, 0 errors, 0 failures, 0 orphans; sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` sin errores.
- Código: `src/player/pose_history.gd`, `yaw_window.gd`, `player_types.gd` (solo `PlayerPose`; `CameraPose`/`InspectionPose`/`VisionRay` quedan para sus historias: una `class_name` por fichero).
- Firmas internas no fijadas por ADR (`record_tick`, `fill`, `reset`, constructores) solo las usa el Player (C-R21); `capacity()` añadido para tests.

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-001-player-config.md`
- Unlocks: `production/epics/jugador-primera-persona/story-009-state-machine-colocar.md`, `story-011-player-node-api.md`
