# Story 007: Dispositivo activo con histéresis F7 y aviso de cambio

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, regla 3 (dispositivo activo); § Formulas F7
**Requirement**: `TR-input-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D7) · ADR-0002 (`RealClock`) · ADR-0001 (aviso `input_device_changed`)
**ADR Decision Summary**: El dispositivo activo empieza en teclado/ratón; `DeviceTracker` (puro, `RealClock`) cuenta como uso cualquier pulsación al instante, el movimiento del ratón cuando Σ|relative| en una ventana `T_m` ≥ `N_m` y un stick sostenido por encima de `dz_in + m_s`; tras un cambio, el movimiento solo no vuelve a cambiar durante 0,4 s. «Dispositivo de entrada cambiado» se emite una vez por cambio.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0002 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: la histéresis usa `RealClock` (corre en pausa).

**Control Manifest Rules (this layer)**:
- Required: F-R16 (`RealClock` inyectado), F-R42 (umbrales en datos), F-R41
- Forbidden: `Time.get_ticks_*` directo
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story (con `FakeRealClock`):*

- [ ] **AC-03 (parte L)**: al arrancar el activo es teclado/ratón; una tecla o botón lo cambia al instante y emite una sola vez `input_device_changed`.
- [ ] **AC-F7**: ratón 4 px en 0,2 s no cambia y 20 px sí; stick 0,2 no cambia y 0,35 durante 0,1 s sí; tras un cambio, el movimiento solo no cambia de nuevo durante 0,4 s.

---

## Implementation Notes

- Firma (ADR-0006): `active_device() -> InputTypes.Device`. `DeviceTracker` en `src/input/device_tracker.gd`, puro.
- La parte V de AC-03 (iconos del prompt) depende de 24 (ADR-0016, Proposed): fuera.

---

## Out of Scope

- Iconos del prompt (ADR-0016).

---

## Files

- `src/input/device_tracker.gd`, `src/input/input_router.gd`
- `tests/unit/input/device_tracker_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/device_tracker_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-002-engine-input-adapter.md`, `production/epics/estado-y-bus/story-004-notice-ids-registry.md`
- Unlocks: `production/epics/entrada-y-controles/story-013-binding-labels.md`, `production/epics/entrada-y-controles/story-014-pause-triggers.md`
