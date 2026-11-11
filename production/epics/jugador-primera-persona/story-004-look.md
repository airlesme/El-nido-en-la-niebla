# Story 004: Mirada 1:1 — yaw/pitch, límites y roll 0

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R13–R15, § Formulas F4
**Requirement**: `TR-player-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D2 «Look is not interpolated», D3, D4; P-2, P-4, P-7) · ADR-0006 (`consume_look_delta()` en grados)
**ADR Decision Summary**: `consume_look_delta()` se aplica a `_yaw`/`_pitch` en el `_process` en que llega, 1:1, sin `dt` ni filtro; yaw en [−π, π), pitch ±`pitch_max`; `Look.basis` solo de yaw y pitch (roll nunca se escribe); el cuerpo nunca rota.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Yaw según la rotación diestra de Godot alrededor de +Y, yaw 0 mirando a −Z (D4).

**Control Manifest Rules (Core)**:
- Required: C-R17 (cuerpo sin rotar; mirada 1:1 en el fotograma; roll nunca), C-R20 (radianes en API; `_deg` en datos)
- Forbidden: C-X10 (suavizado exponencial), C-X13 (rotar el `CharacterBody3D`)
- Guardrail: C-G01

---

## Acceptance Criteria

- [ ] **AC-11**: GIVEN pitch 78°, WHEN Δpitch = +5°, THEN pitch = 80°; GIVEN yaw 179°, WHEN Δyaw = +5°, THEN yaw = −176°.
- [ ] **AC-12**: GIVEN un mismo Δyaw total de 90° en 3 fotogramas o en 12, con tiempos distintos, THEN el yaw final es idéntico (±0,001°).
- [ ] **AC-13 (alcance M1)**: GIVEN la fixture determinista (semilla 20261109, 600 pasos) con Δ de mirada y avisos de zona activada, THEN roll = 0 exacto y, en Libre, la orientación solo cambia por Δ de Entrada. *(Los eventos de puerta, apagón, llamada, reflejo y pista de P1 de la fixture completa se añaden cuando existan esos sistemas; anotarlo en el test.)*
- [ ] **AC-14**: GIVEN `reducir_sobresaltos` verdadero o falso, THEN ninguna salida del Jugador (orientación, offset, FOV) cambia (el Jugador no lo lee). NaN en el Δ de mirada → se descarta + log.

---

## Implementation Notes

- **OI-3 de ADR-0012 se cierra aquí**: convención de signo de `consume_look_delta()` (+yaw = derecha?, +pitch = arriba tras inversión) frente a la convención en radianes de D4, resuelta en `_look_sign`. Si GDD 1 F2–F3 y ADR-0006 no la fijan sin ambigüedad, anotar la decisión en ADR-0012 § Open Items y avisar al dueño de ADR-0006.
- Lógica (`Look` math) sin motor detrás de `PlayerInputPort.look_delta_deg()` (puerto `@abstract` de § Key Interfaces); en el test, `FakeInput`.
- Conversión `deg_to_rad` en la frontera; la API pública queda en radianes.

---

## Out of Scope

- 010: pitch de poses cedidas (`pitch_cesion_max`) y arco corto de cesión.
- 009: descarte de `mirar` fuera de Libre.

---

## Files

- `src/player/look.gd` (o nombre equivalente dentro de `src/player/`)
- `src/player/ports/player_input_port.gd`
- `tests/unit/player/look_test.gd`
- `tests/fixtures/player/look_seed_20261109.json`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/look_test.gd` (T-U3) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-001-player-config.md`
- Unlocks: `production/epics/jugador-primera-persona/story-009-state-machine-colocar.md`, `story-010-camera-lease.md`
