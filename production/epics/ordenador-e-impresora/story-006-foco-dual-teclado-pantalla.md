# Story 006: Foco dual y teclado en pantalla (mando y teclado)

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L — 2,0 d (confianza BAJA: el riesgo HIGH de ADR-0006 se concentra aquí)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

C-M1-6 exige la búsqueda con teclado **y** con mando. El campo consume las teclas antes que
Entrada; con mando, un teclado en pantalla operado con el cursor y `seleccionar` existentes.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R8, R16, F5)
**Requirement**: `TR-computer-004`, `TR-computer-011`, `TR-computer-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (foco dual, teclado en pantalla, prioridad de la UI sobre las acciones de Entrada)
**ADR Decision Summary**: con foco en el campo, la UI consume imprimibles, `Retroceso`, `Supr`, flechas e `Intro`; el teclado en pantalla se activa si el dispositivo activo es mando y no añade acciones de Entrada.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `LineEdit` y teclado en pantalla con foco dual (4.6): consultar `docs/engine-reference/godot/` y los spikes de ADR-0006 § Validation Criteria antes de implementar; cualquier comportamiento no cubierto es **NOT SOURCEABLE** y se registra.

**Control Manifest Rules (this layer)**:
- Required: FE-R09; sin acciones nuevas de Entrada
- Forbidden: `Esc`/`Retroceso` como cierre (TR-computer-003)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-09 (resto)**: `Retroceso` con foco en el campo borra un carácter y no cierra; `Esc` no cierra (según el GDD).
- [ ] **GDD 19 AC-10a**: con mando y el campo enfocado se muestra el teclado en pantalla; eventos inyectados de stick y `seleccionar` que pulsan t-r-a-n-s-i-c-i-o-n y `Buscar` dan `hay_resultados` verdadero.
- [ ] **GDD 19 AC-11 (parte de datos)**: `tecla_px` ≥ `pick_min_px` (44) y `tecla_sep_px` ≥ 8 en los datos. (Medición a 16:10 y región 1280×720 → Diferido, ADR-0007.)
- [ ] **GDD 19 AC-25**: mando → teclado con texto escrito conserva texto y foco y oculta el teclado en pantalla.

---

## Implementation Notes

- Los eventos se inyectan por la capa de Entrada de ADR-0006 (no `Input.parse_input_event` directo si ADR-0006 fija otra vía).
- Geometría de teclas en datos (TR-computer-021).

---

## Out of Scope

- Story 007: gesto de manos.
- Story 009: aspecto del teclado.

---

## Files

- `src/world/computer/search_field.gd`, `src/world/computer/onscreen_keyboard.gd` (fallback de ruta)
- `tests/integration/computer/dual_focus_keyboard_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/computer/dual_focus_keyboard_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ordenador-e-impresora/story-005-receptor-v01-apertura-cierre.md`; capa de Entrada (`production/epics/entrada-y-controles/`)
- Unlocks: `production/epics/ordenador-e-impresora/story-007-gesto-hand-type.md`, `production/epics/ordenador-e-impresora/story-009-overlay-gris-capturas.md`
