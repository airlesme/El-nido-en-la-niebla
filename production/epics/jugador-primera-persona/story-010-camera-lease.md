# Story 010: `CameraLease` — cesión y devolución de cámara

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R18, § Formulas F9
**Requirement**: `TR-player-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D5; P-6; P-9)
**ADR Decision Summary**: `CameraLease` (`RefCounted`) con estados `OWN → LEASING → LEASED → RETURNING → OWN` sobre `GameClock.now()`; propietario único de la lista cerrada `propietarios_camara`; duración limitada a [0, `t_transicion_max`]; F9 smoothstep con yaw Euler por arco corto y pitch separados (roll inexistente); `camara_cedida` en el primer `_process` con u = 1 (nunca reentrante); devolución en `t_devolver` 0,5 s con objetivo reevaluado cada fotograma.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura)
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: C-R19 (tiempos de cesión del `GameClock`), C-R21 (bool síncrono + log; señales de llegada desde `_process`), C-R20
- Forbidden: C-X15 (`Timer`/`Tween`), slerp de cámara (roll)
- Guardrail: C-G01

---

## Acceptance Criteria

- [ ] **AC-20**: GIVEN Libre, 16:9, `campo_vision` 70°, yaw/pitch (30°, −10°), WHEN 7 pide `ceder_camara(interaccion:vista, pose, 60°, 1,0 s)`, THEN a 0,5 s la posición está a mitad de camino y el FOV vale 65° (±0,1°); a 1,0 s la cámara está en `pose` (±0,001 m, ±0,1°), FOV 60° y se emite `camara_cedida`; WHEN `devolver_camara(interaccion:vista)`, THEN a 0,5 s orientación (30°, −10°) ± 0,1°, posición de los ojos, FOV 70° ± 0,1° y `camara_devuelta` en ese tick.
- [ ] **AC-21**: WHEN `ceder_camara` con 5 s, THEN dura 3,0 s y hay una línea de log; WHEN otro propietario P2 pide ceder o devolver mientras P1 la tiene (incluso en su devolución), o un propietario fuera de `propietarios_camara` pide ceder, THEN se rechaza y la cámara no se mueve (en desarrollo, error visible).
- [ ] **AC-25**: GIVEN Cámara cedida en devolución, WHEN llega `mover`, THEN se descarta hasta `camara_devuelta`; `camara_devuelta` se emite antes de salir de Cámara cedida.
- [ ] **AC-44 (alcance M1)**: GIVEN pose cedida con pitch 85° y yaw 170° → −170°, THEN roll = 0 exacto en toda la transición, el yaw pasa por 180° (arco corto) y el pitch final es 85°; con pitch pedido 95° el final es 89°. *(La parte «32:9 → 51,9°» depende de F5, TR-player-008, diferida.)*

---

## Implementation Notes

- FOV: `fov_1 = F5(fov_destino, aspect)` en el ADR. **En M1 F5 no existe** (TR-player-008 diferido): el lease interpola hacia `fov_destino_deg` tal cual, detrás de una única función de conversión para que `CameraFov.to_engine()` la sustituya luego. Para 16:9 y FOV ≤ 70° el resultado es idéntico a F5 (AC-20).
- Mismo propietario puede re-ceder desde cualquier estado (inicio = estado actual de cámara, yaw/pitch guardados sin cambio); `duracion` 0 → `camara_cedida` en el siguiente `_process`.
- `colocar` y la descarga de escena cancelan sin señales (009).

---

## Out of Scope

- 011: aplicar la pose a `Rig`/`Look`; consumo por Interacción (7) y Ordenador (19): sus épicos.

---

## Files

- `src/player/camera_lease.gd`
- `tests/unit/player/camera_lease_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/camera_lease_test.gd` (T-U6) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-004-look.md`, `story-009-state-machine-colocar.md`
- Unlocks: `production/epics/jugador-primera-persona/story-011-player-node-api.md`
