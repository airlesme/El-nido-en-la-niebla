# Story 011: Partida nueva — `reset_new_game` y `state_reset`

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 12 (partida nueva) y regla 11 (diferida al final del drenaje)
**Requirement**: `TR-state-???` — **sin entrada en el registro** para la partida nueva fuera de la instantánea (hueco anotado para `/architecture-review`); relacionado con `TR-state-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (§ Key Interfaces `reset_new_game`; G-4)
**ADR Decision Summary**: Todos los hechos vuelven a su inicial, se vacía la cola y se emite un único `state_reset` sin avisos por hecho; dentro de un drenaje se aplaza al final. Los consumidores releen al recibir `state_reset`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R06 (al recibir `state_reset` se releen los hechos)
- Forbidden: emitir un aviso por hecho en el reinicio
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`:*

- [ ] **CA-18**: con progreso arbitrario y avisos pendientes, la partida nueva deja los 20 hechos en su inicial, la cola vacía y emite un único `state_reset` sin avisos de cambio.
- [ ] **CA-13b**: un suscriptor que pide partida nueva al recibir un aviso: al terminar esa entrega se aplica, la cola queda vacía y se emite un único `state_reset`.

---

## Implementation Notes

- Firma (ADR-0001): `reset_new_game() -> void`. Usa `NoticeChannel.clear_pending()` y `run_after_drain()` (003). Nombre del aviso desde `NoticeIds` (004).

---

## Out of Scope

- `restore()` y `state_restored` — diferidos por ADR-0004.

---

## Files

- `src/core/game_state.gd`
- `tests/unit/state/reset_new_game_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/reset_new_game_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-003-notice-channel-cap-and-lifecycle.md`, `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`
- Unlocks: None (lo consume carga-de-planta: `partida_nueva`)
