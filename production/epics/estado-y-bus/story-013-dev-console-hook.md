# Story 013: Gancho de consola de pruebas `dev_force`

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 15 (modo de pruebas)
**Requirement**: `TR-state-018` (parte del gancho; la exclusión del export es de ADR-0018)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (§ Key Interfaces `dev_force`; G-11)
**ADR Decision Summary**: `GameState` expone solo el gancho `dev_force(fact, value)`, que salta las reglas 4 y 6, emite el aviso normal, recalcula derivados y deja log. La consola vive en un script aparte excluido de la demo (mecanismo de ADR-0018).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R11 (la consola en un script aparte excluido de la demo; `GameState` solo el gancho), F-R66
- Forbidden: lógica de consola dentro de `game_state.gd`
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-28**: en dev, `dev_force(&"tarjeta_B", false)` con `tarjeta_B` verdadero se permite, se registra, emite el aviso de cambio y recalcula derivados.
- [ ] Con `BuildFlavor` release, `dev_force` no cambia nada y registra una línea (defensa en profundidad hasta que ADR-0018 excluya el script).

---

## Implementation Notes

- Firma (ADR-0001): `dev_force(fact: StringName, value: Variant) -> void` («proposed», fijada por el ADR).
- La interfaz de consola (comandos, UI) **no** se diseña aquí: ningún ADR Accepted la firma. Solo el gancho y su test.

---

## Out of Scope

- **CA-29** y el script de `tools/ci/`: diferido por ADR-0018 (Proposed).
- UI de la consola de depuración.

---

## Files

- `src/core/game_state.gd`
- `tests/unit/state/dev_force_hook_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/dev_force_hook_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-010-derived-facts.md`
- Unlocks: None
