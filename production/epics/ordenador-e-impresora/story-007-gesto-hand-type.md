# Story 007: Gesto `HAND_TYPE` mientras se teclea

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S — 0,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Mientras Vera teclea, sus manos teclean. Si el Jugador rechaza el gesto, el texto se escribe igual.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R19)
**Requirement**: `TR-computer-022`, `TR-computer-009` (parte `t_tipeo_inactivo`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (contexto de vista); ADR-0002 (`t_tipeo_inactivo` 1,0 s en `GameClock`)
**ADR Decision Summary**: 19 pide `reproducir_gesto('HAND_TYPE')` en bucle y `reposo()` tras 1,0 s sin teclear o en `on_close`.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0006)
**Engine Notes**: ninguna propia.

**Control Manifest Rules (this layer)**:
- Required: tiempo por `GameClock`
- Forbidden: F-X10
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-20**: el Jugador reproduce `HAND_TYPE` hasta 1,0 s tras el último carácter o hasta `on_close`; si el Jugador rechaza el gesto, el texto se sigue escribiendo.

---

## Implementation Notes

- `reproducir_gesto`/`reposo` son API del Jugador (2, ADR-0012); usar sus firmas. Test con doble del Jugador que rechaza.

---

## Out of Scope

- Animación de las manos (épico `jugador-primera-persona`).

---

## Files

- `src/world/computer/search_field.gd`
- `tests/integration/computer/hand_type_gesture_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/computer/hand_type_gesture_test.gd` con `GameClock` falso — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ordenador-e-impresora/story-006-foco-dual-teclado-pantalla.md`; API de gestos (`production/epics/jugador-primera-persona/`)
- Unlocks: None
