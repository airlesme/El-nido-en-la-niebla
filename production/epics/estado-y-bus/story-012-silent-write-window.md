# Story 012: `write_silent` y ventana de carga por tap

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 16 (`escribir_silencioso`)
**Requirement**: `TR-state-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (D9; G-13)
**ADR Decision Summary**: `GameState` observa su propio canal con un tap en el encolado: `scene_load_started` abre la ventana, `scene_ready` y `scene_load_failed` la cierran. Dentro de la ventana el `owner` (9) puede escribir un hecho reversible sin aviso; fuera, o sobre un hecho de un solo sentido, o por otro sistema, es escritura inválida.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R12 (`escribir_silencioso` → `write_silent`), F-R05
- Forbidden: depender de la posición de 3 en la lista de suscriptores
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-35 (sin la cláusula de Guardado, diferida por ADR-0004)**: con un suscriptor a todos, otro a `pendiente_revelacion`, cola vacía, carga en curso y `pendiente_revelacion` verdadero, el `owner` (9) escribe falso con `write_silent`: la lectura da falso, nadie recibe aviso, la cola sigue vacía y hay una línea informativa de log.
- [ ] **CA-35 (rechazos)**: otro sistema, el `owner` fuera de la ventana o un hecho de un solo sentido → escritura inválida y el valor no cambia.
- [ ] La ventana la abre/cierra el tap aunque `GameState` no tenga ningún suscriptor ordinario y aunque los avisos aún estén en cola.

---

## Implementation Notes

- Firmas (ADR-0001): `GameState.write_silent(fact, value, owner_id) -> bool`, `FactWriter.write_silent(fact, value) -> bool`. Tap con `NoticeChannel.set_enqueue_tap` (003); nombres desde `NoticeIds` (004).

---

## Out of Scope

- La cláusula «Guardado doble con línea base… `dif` verdadero» de CA-35: ADR-0004 (Proposed).

---

## Files

- `src/core/game_state.gd`, `src/core/fact_writer.gd`
- `tests/unit/state/silent_write_window_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/silent_write_window_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-004-notice-ids-registry.md`, `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`
- Unlocks: None (lo consume puzles-marco-y-p1)
