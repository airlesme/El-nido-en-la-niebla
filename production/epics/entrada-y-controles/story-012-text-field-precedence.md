# Story 012: Precedencia del campo de texto en `ordenador` (`es_imprimible`)

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, regla 20 (campo de texto enfocado)
**Requirement**: `TR-input-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D12)
**ADR Decision Summary**: `es_imprimible(ev)` es verdadero para una tecla que produce carácter, decidido por una lista de denegación en datos (`Esc`, `Tab`, `Enter`, `Backspace`, `Delete`, flechas…). Con `set_text_entry(owner, true)` el campo consume imprimibles, `Retroceso`, `Supr`, flechas y `Enter` antes que cualquier acción; `Esc` y clic derecho siguen siendo `pausa`/`atrás`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: foco del `LineEdit` por puntero: NEEDS_MANUAL (S-0006). Teclados no QWERTY: la lista de denegación evita depender del layout.

**Control Manifest Rules (this layer)**:
- Required: F-R42 (lista de denegación en datos)
- Forbidden: lista de permitidos por carácter
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-20 (parte L)**: con `ordenador` y campo enfocado, «tra» + `Retroceso` ×2 deja el campo en «t» (simulado con un doble del campo), el contexto sigue en `ordenador` y no se emite `atrás`; `Esc` emite `pausa`.
- [ ] `es_imprimible` es falso para cada tecla de la lista de denegación y verdadero para `a`, `ñ`, `1`, espacio.

---

## Implementation Notes

- Firmas (ADR-0006): `set_text_entry(owner, active)`, `es_imprimible(ev: InputEvent) -> bool`, `is_text_field_consumed(b: InputBinding) -> bool`; adaptador `is_printable_key(code)`.
- La parte I de AC-20 (con `LineEdit` real) se cierra en ordenador-e-impresora.

---

## Out of Scope

- `LineEdit` real y búsqueda (19).

---

## Files

- `src/input/input_router.gd`, `src/input/engine_input_adapter.gd`
- `tests/unit/input/text_field_precedence_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/text_field_precedence_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`
- Unlocks: None (lo consume ordenador-e-impresora)
