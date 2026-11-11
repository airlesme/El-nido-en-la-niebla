# Story 008: `StuckGuard` — red de seguridad contra atasco y caída

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Edge Cases (red de seguridad, D-23)
**Requirement**: `TR-player-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D8; P-6; P-11)
**ADR Decision Summary**: penetración > `eps_atasco_m` ⇔ una cápsula reducida en `eps` solapa geometría estática (puerto `PenetrationProbe`); con desplazamiento < `eps` durante `t_atasco` 0,5 s, o `y < y_min` −2,0 m, se recoloca en la última pose segura (si no, el ancla de `colocar`), velocidad 0, `TickInterpolator.reset`, log. Pose segura cada `t_pose_segura` 0,25 s (plazo de `GameClock`) si en suelo y sonda falsa.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (sonda de forma bajo Jolt)
**Engine Notes**: **Medido en S-0012-D NP-6**: con eps 0,02 → penetración 0,00 false, 0,01 false, 0,03/0,05/0,10 true; coste medio 0,0024 ms (p99 0,003). La junta de 0,03 m cambia de resultado justo en eps (eps ≥ 0,03 → false). **Medido en S-0011-A**: `intersect_shape` tiene `max_results` por defecto 32 y lo aplica: la sonda de producción pasa `max_results` explícito (basta 1 para un booleano, pero debe ser explícito, no el defecto).

**Control Manifest Rules (Core)**:
- Required: C-R25 (una consulta de forma por tick; elegir `eps_atasco_m` conociendo el punto de cambio), C-R19 (cadencia de pose segura con `GameClock`), C-R22
- Forbidden: C-X14 (informe de penetración del motor)
- Guardrail: C-G01 (1 consulta de forma por tick)

---

## Acceptance Criteria

- [ ] **AC-40**: GIVEN una colisión falsa con penetración > 0,02 m y desplazamiento < 0,02 m durante 0,5 s seguidos, o `y` < −2,0 m, THEN el jugador vuelve a la última pose segura con velocidad 0 y una línea de log (en desarrollo, error visible); sin pose segura, al ancla de aparición; GIVEN penetración 0 (empujar un muro), THEN no se reubica. El test prueba el criterio, no una señal del motor.
- [ ] La recolocación **no** rellena la memoria de poses ni pone a 0 la ventana de yaw (no es un `colocar`).

---

## Implementation Notes

- Puerto `PenetrationProbe.is_penetrating(capsule_center: Vector3) -> bool` (§ Key Interfaces). Producción: `intersect_shape()` con `CapsuleShape3D` reducida pre-construida (radio `r − ε`, altura `h − 2ε`), máscara = capas estáticas (`world_geometry`, tabla de capas de ADR-0011), excluyendo al Player, `max_results` explícito.
- Los números de capa en `project.godot` faltan (manifiesto P-23): la sonda de producción depende de la historia de capas de ADR-0011; esta historia solo necesita el fake.

---

## Out of Scope

- 011: cableado de la sonda real y llamada a `TickInterpolator.reset`.

---

## Files

- `src/player/stuck_guard.gd`, `src/player/ports/penetration_probe.gd`
- `tests/unit/player/stuck_guard_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/stuck_guard_test.gd` (T-U11) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-001-player-config.md`
- Unlocks: `production/epics/jugador-primera-persona/story-011-player-node-api.md`
