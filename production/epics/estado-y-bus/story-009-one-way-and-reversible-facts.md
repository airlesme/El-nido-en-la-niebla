# Story 009: Hechos de un solo sentido y reversibles

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 6 (un solo sentido; reversibles `pos_L/C/R` y `pendiente_revelacion`)
**Requirement**: `TR-state-006`, `TR-state-004` (cambio de un solo sentido rechazado)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (§ Drain and Write Algorithms; § Invariants)
**ADR Decision Summary**: bool y enum son de un solo sentido salvo `pendiente_revelacion`; `pos_L/C/R` (int 1–4, inicial 2) son reversibles. Un retroceso se rechaza con la política de escritura inválida (dev halt / release log).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R05, F-R09
- Forbidden: lista de reversibles en código — sale del catálogo (`flags.json`)
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`:*

- [ ] **CA-03**: con `tarjeta_B` verdadero, escribir verdadero no emite aviso; escribir falso se rechaza, sigue verdadero y añade una línea de log.
- [ ] **CA-04**: con `carta_variante = B`, escribir C o «sin fijar» se rechaza y sigue en B; idéntico para `respuesta_llamada` y `t4_decision` (`returned` no admite `assigned` ni «sin fijar»).
- [ ] **CA-05**: `pos_L` 2 → 4 → 1 se aceptan; `pendiente_revelacion` falso → verdadero → falso se aceptan y emiten su aviso.

---

## Implementation Notes

- La reversibilidad se declara por hecho en el catálogo (campo del esquema de 005); si el esquema de ADR-0005 D2 no tiene campo para ello, *ADR-fallback*: se deriva de la regla del GDD (bool/enum = un solo sentido; `int` con `range` = reversible; excepción nominal `pendiente_revelacion` como constante en `game_state.gd`) y se anota en ADR-0001 Open Items.
- Enum «sin fijar» → valor fijado es avance; fijado → otro valor o «sin fijar» es retroceso.

---

## Out of Scope

- Story 012: `write_silent` (solo sobre reversibles).

---

## Files

- `src/core/game_state.gd`
- `tests/unit/state/one_way_facts_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/one_way_facts_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`
- Unlocks: `production/epics/estado-y-bus/story-015-m1-state-test.md`
