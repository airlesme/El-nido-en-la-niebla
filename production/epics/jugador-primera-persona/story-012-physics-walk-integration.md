# Story 012: Integración física headless — muros, objetos y zona

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M — 1 día (1–2; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R1, R4, R10
**Requirement**: `TR-player-001`, `TR-player-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D1, D3; Test Plan T-I1, T-I2) · ADR-0003 (D8: sensor y `ZoneTrigger`, banda de activación)
**ADR Decision Summary**: `move_and_slide()` a 60 Hz con adopción de la velocidad deslizada; nada se empuja (sin `RigidBody3D`); la zona detecta el sensor esférico, no la cápsula.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 (Jolt) | **Risk**: HIGH
**Engine Notes**: **Medido en S-0012-C**: muro de frente, variación x 0,0 mm / y 0,72 mm en 60 ticks (se asienta a 3,7 mm del muro); muro a 45°: velocidad normal máx. 4,0e-5 m/s, deslizamiento 1,13 m/s; esquina 0,016 mm. **Medido en S-0003-B.1/B.4**: activación con centro del sensor en **(8,95; 8,977]** (observado 8,95013–8,97653), idéntica a 30/60/144 fps; Jolt informa en el primer tick tras cruzar la cara.

**Control Manifest Rules (Core)**:
- Required: C-R09 (sensor solo en `zone_sensor`, `monitorable`), C-R10 (banda (8,95; 8,977]), C-R24
- Forbidden: C-X12, C-X13
- Guardrail: C-G01 (comparar `move_and_slide` con 107 µs media / 246 µs p99 de S-0012-C)

---

## Acceptance Criteria

- [ ] **AC-05**: GIVEN un muro a 45° y `m` = (0, 1), THEN la velocidad queda paralela al muro (componente normal 0) y no hay rebote; GIVEN un muro de frente, THEN la velocidad llega a 0 y la posición varía < 1 mm durante 60 pasos.
- [ ] **AC-08**: GIVEN un objeto estático, WHEN el jugador empuja contra él, THEN no se mueve.
- [ ] **AC-09 (PV)**: GIVEN `T-PAS-1` (X 9,0 a 10,0) y `radio_sensor_zona` = 0,05, WHEN camina al este a `v_paseo`, THEN la zona se activa con su centro en X ∈ (8,95; 8,977] y nunca en X ≤ 8,95 ni con el borde de la cápsula (8,75). Reverificar en cada versión del motor.
- [ ] `colocar` + `colocar` antes de `configurar` en el mundo físico no deja barrido ni velocidad residual (T-I1, C2).

---

## Implementation Notes

- Escena de prueba construida en el test (suelo, muros, `ZoneTrigger` con `ZoneHub` de carga-de-planta 011); headless, física a 60 Hz; reloj `GameClock` falso por pasos enteros.
- AC-09 reutiliza el patrón de `tests/unit/engine_facts/adr0003_zone_sensor_jolt_test.gd` como regresión, ahora con el `Player` real.
- AC-06 (tiempo en el pasillo) aquí solo a tick fijo; la medición en ventana real es 013.

---

## Out of Scope

- 013: AC-06 a 30/60/144 fps en ventana y AC-07 (puertas de la planta).

---

## Files

- `tests/integration/player/player_walk_test.gd`, `tests/integration/player/player_zone_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/player/player_walk_test.gd` (T-I1) y `tests/integration/player/player_zone_test.gd` (T-I2) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-011-player-node-api.md`, `production/epics/carga-de-planta/story-011-zone-hub.md`
- Unlocks: `production/epics/jugador-primera-persona/story-013-gray-walk-evidence.md`
