# Story 003: Pila de contextos, sinks y `input_context_changed`

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, reglas 5–6 (solo la cima recibe; salir restaura); § States and Transitions; § Edge Cases
**Requirement**: `TR-input-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D3, D6) · ADR-0003 (contrato `InputContexts`) · ADR-0001 (aviso `input_context_changed`)
**ADR Decision Summary**: La pila es `Array[StackEntry]` (`context`, `requester`, `cursor_pos`, …); solo la cima recibe acciones; `enter`/`exit` genéricos para 7, 22, 25, 27. Por (contexto, acción) hay como mucho un sink `Callable(ev: ActionEvent)` registrado con `bind_sink`; el aviso se emite solo en cambios efectivos de la pila.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0003 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: ninguna API de motor en la pila (pura).

**Control Manifest Rules (this layer)**:
- Required: F-R44 (un sink por (contexto, acción)), F-R02 (nombre del aviso por `NoticeIds`), F-R31 (suscripciones/`connect` desenlazables o tolerantes a liberación)
- Forbidden: `_unhandled_input` por contexto (Alternativa 2 descartada)
- Guardrail: el aviso solo en cambios efectivos

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-05**: en `inspección`, `mover` se descarta.
- [ ] **AC-06**: `vista cercana` con cursor en (X, Y), luego `menú` encima; al salir del menú, contexto y cursor vuelven a (X, Y).
- [ ] **AC-E1**: entrar en el contexto que ya está arriba se ignora; salir de uno que no es la cima se rechaza, se registra y la pila no cambia.
- [ ] **AC-E9**: entrar en `inspección` y salir emite dos `input_context_changed` con (`exploración`, `inspección`) y (`inspección`, `exploración`); las peticiones ignoradas/rechazadas no emiten.

---

## Implementation Notes

- Firmas (ADR-0006): `enter(ctx, requester) -> bool`, `exit(ctx, requester) -> bool`, `top() -> InputTypes.Context`, `bind_sink(ctx, action, sink)`, `unbind_sink(ctx, action, sink)`.
- El aviso pasa por el `GameState` inyectado (`ctx.state.notify`), con el payload de § Notice Name Registry de ADR-0001.

---

## Out of Scope

- Story 004: `sin control`.

---

## Files

- `src/input/input_router.gd`, `src/input/context_stack.gd`
- `tests/unit/input/context_stack_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/context_stack_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-002-engine-input-adapter.md`, `production/epics/estado-y-bus/story-004-notice-ids-registry.md`
- Unlocks: `production/epics/entrada-y-controles/story-004-no-control-operations.md`, `production/epics/entrada-y-controles/story-008-move-and-look-formulas.md`, `production/epics/entrada-y-controles/story-011-interact-short-long-verb.md`, `production/epics/entrada-y-controles/story-012-text-field-precedence.md`
