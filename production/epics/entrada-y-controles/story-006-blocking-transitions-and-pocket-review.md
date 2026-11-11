# Story 006: Transiciones bloqueantes y `repasar_bolsillo`

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, reglas 8 (transiciones bloqueantes) y 23 (`repasar_bolsillo`); § Formulas F8
**Requirement**: `TR-input-007`, `TR-input-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D5, D6)
**ADR Decision Summary**: 7 llama a `begin_blocking(owner, max_s)`/`end_blocking(owner)`; mientras dura solo pasan `pausa` y `repasar_bolsillo`, el resto se descarta sin cola; una tecla mantenida durante la transición no dispara al terminar. `repasar_bolsillo` se deriva de `atrás` solo si la pulsación empieza en `exploración`, en el flanco, ignorando auto-repetición, y se entrega a 20 sin cola.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: auto-repetición de teclado: `InputEventKey.echo` (comprobado en `adr0006_input_events_test.gd`).

**Control Manifest Rules (this layer)**:
- Required: F-R44, F-R46, F-R43 (tope de la transición por `GameClock`)
- Forbidden: encolar acciones descartadas
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-08 (transición)**: con una transición bloqueante de 7 activa (marcador de bloqueo), `interactuar` pulsado durante ella no se dispara al terminar; `pausa` pasa; la transición termina por `end_blocking` o por su tope.
- [ ] **AC-E15**: con [`exploración`], una pulsación de `atrás` emite `repasar_bolsillo` una sola vez; mantener (auto-repetición) o soltar no emite más; en `inspección`, `lectura`, `vista cercana` no se emite.
- [ ] **AC-E16 (parte L)**: la pulsación de `atrás` que cierra una `lectura` no emite `repasar_bolsillo`; la siguiente sí.
- [ ] **AC-E17 (parte L)**: durante una transición bloqueante en `exploración`, `atrás` entrega `repasar_bolsillo` al sink de 20, no se guarda ni se repite al terminar; las demás acciones se descartan.

---

## Implementation Notes

- Firmas (ADR-0006): `begin_blocking(owner: StringName, max_s: float = -1.0)`, `end_blocking(owner: StringName)`. Tope por defecto 3 s † de datos.
- El sink de `repasar_bolsillo` lo registra 20 (documentos-y-bolsillo); aquí con un doble.

---

## Out of Scope

- Respuesta de 7 (`APLAZADA`/`RECHAZADA`) — interaccion-y-prompt.

---

## Files

- `src/input/input_router.gd`
- `tests/unit/input/blocking_transitions_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/blocking_transitions_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`, `production/epics/entrada-y-controles/story-005-safety-cap-and-loading-state.md`
- Unlocks: `production/epics/entrada-y-controles/story-011-interact-short-long-verb.md`
