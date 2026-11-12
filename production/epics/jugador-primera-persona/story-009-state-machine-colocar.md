# Story 009: Máquina de estados del Jugador y `colocar`

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Done (2026-11-12; salvedad: suite completa no verificada, ver Evidencia)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (1–2; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § States and Transitions, § Core Rules R20, R22
**Requirement**: `TR-player-014`, `TR-player-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D6, D2 `reset`, D7 `fill`, D5 «`colocar` cancels any lease without signals») · ADR-0003 (D3: paso 5 `colocar(anchor.global_position, anchor.global_rotation.y, 0.0)`) · ADR-0006 (`top()`, enum de contextos)
**ADR Decision Summary**: el Player **sondea** el contexto activo una vez por tick y una por fotograma con `PlayerInputPort.context()` (no se suscribe al bus); Libre ⇔ contexto `EXPLORACION` y cesión `OWN` y no «recién colocado»; `colocar` → Congelado hasta el primer sondeo que vea `EXPLORACION`; salir de Libre pone objetivo 0 y frena (sin anular la velocidad); entrar en Libre lee `mover` en el mismo tick.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura)
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: C-R08 (un `Player` por escena, recolocado con `colocar`), C-R20 (radianes), C-R21 (respuesta síncrona sin señal reentrante)
- Forbidden: C-X16 (el Player no lee ni se suscribe al bus; sondeo con `top()`)
- Guardrail: C-G01

---

## Acceptance Criteria

- [ ] **AC-23 (alcance M1)**: GIVEN un jugador en movimiento con cámara cedida, WHEN 4 llama a `colocar(p, yaw, pitch)`, THEN en ese mismo tick posición = p (±0,001), velocidad 0, orientación = (yaw, pitch limitado), sin cesión activa (y sin `camara_devuelta`), estado Congelado y `giro_acumulado` = 0. *(«Manos en reposo sin objeto»: trivial en M1, sin manos.)*
- [ ] **AC-24**: GIVEN Libre a 1,6 m/s, WHEN Entrada anuncia `inspección`, THEN el objetivo pasa a (0, 0), el cuerpo se detiene en 9 pasos tras 0,107 m y la orientación no cambia aunque `mirar` siga llegando.
- [ ] **AC-26 (parte lógica)**: GIVEN `W` mantenida, WHEN el contexto vuelve a `exploración` tras una inspección o una vista cercana, THEN el jugador camina en ese mismo tick.
- [ ] `colocar` antes de `configurar()` es legal (C2 de ADR-0012) y deja Sin escena → Congelado al configurar.

---

## Implementation Notes

- `colocar` (síncrono, mismo tick): velocidad 0, `CameraLease` cancelada sin señales, `PoseHistory.fill(pose)`, `YawWindow` a 0, `TickInterpolator.reset(ojos)`, guarda el ancla para `StuckGuard`. El Player no decide el ancla (la da 4).
- Estados: Sin escena, Libre, Congelado, Cámara cedida (GDD 2). La cesión (010) solo aporta «lease ≠ OWN».

---

## Out of Scope

- 010: la cesión en sí; AC-25 (`mover` descartado durante la devolución).
- 012: AC-26 con física real.

---

## Files

- `src/player/player_state_machine.gd`
- `tests/unit/player/player_state_machine_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/player_state_machine_test.gd` (T-U7) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-002-locomotion.md`, `story-004-look.md`, `story-007-pose-history-yaw-window.md`
- Unlocks: `production/epics/jugador-primera-persona/story-010-camera-lease.md`, `story-011-player-node-api.md`

---

## Evidencia

- `src/player/player_state_machine.gd` y `tests/unit/player/player_state_machine_test.gd` (T-U7, 20 tests). `--import` sin errores.
- `-a res://tests/unit/player` con Godot 4.7.2 local: `Overall Summary: 169 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`; sin `ObjectDB instances were leaked` ni `resources still in use`.
- Suite bloqueante completa NO verificable en esta sesión: otro agente (EC-008, `src/input/`) dejó `InputFormulas` sin declarar y la suite aborta con Parse Error (no es de esta historia).
- AC-23: posición/velocidad/orientación (yaw envuelto, pitch limitado)/`giro_acumulado` 0/historial/interpolador y estado Congelado cubiertos. La cancelación de la cesión se prueba con un callable inyectado (`cancel_lease`); la cesión real (`CameraLease.cancel_silently`) la conecta 010/011.
- AC-24 (9 pasos, 0,107 m, orientación intacta), AC-26 parte lógica (mismo tick) y `colocar` antes de `configurar()` (`defer_place`/`on_configured`) cubiertos.
- Firmas fijadas por la historia (TODO(ADR-0012), dueño lead-programmer): `place`, `step_velocity`, `defer_place`, `on_configured`.
