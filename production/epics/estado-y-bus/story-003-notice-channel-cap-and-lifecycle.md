# Story 003: `NoticeChannel` — tope de avisos encadenados, callables inválidos, `run_after_drain`, tap

> **Epic**: Estado y bus de eventos
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, reglas 10–11; § Edge Cases (bucles de escritura); § Tuning Knobs (`max_chained_notices`)
**Requirement**: `TR-state-011` (tope), `TR-state-010` (suscriptor liberado con su escena)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (D5, D6, D9)
**ADR Decision Summary**: El tope cuenta entradas entregadas por drenaje (64 por defecto, 8–256, en datos); al superarse se descarta la cola, se registra, `ErrorPolicy.fail` y se entrega una vez `notices_dropped`. Antes de llamar se comprueba `cb.is_valid()`; el inválido se salta y se poda al final. `run_after_drain` y el tap de encolado son ganchos para 5 y para la ventana de escritura silenciosa.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `Callable.is_valid()` sobre un objeto liberado verificado en `tests/unit/engine_facts/adr0001_callable_validity_test.gd` (NS-1).

**Control Manifest Rules (this layer)**:
- Required: F-R01, F-R09 (log por `LogSink`, halt por `ErrorPolicy`), F-R10 (`max_chained_notices` int 8–256 en `flags.json`)
- Forbidden: depender del orden entre dos receptores de una señal (NS-5)
- Guardrail: bucles independientes en un fotograma tienen cada uno su presupuesto (ADR-0001 OI-3)

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-15**: con un tope de prueba (p. ej. 8) inyectado, un bucle de escrituras que lo supera entrega exactamente 8 entradas, descarta el resto, añade una línea de log, llama a `ErrorPolicy.fail` (doble) y entrega `notices_dropped` una sola vez; un segundo desbordamiento en el mismo drenaje solo registra.
- [ ] **CA-17 (parte unitaria)**: un suscriptor cuyo objeto se ha liberado no produce error en el siguiente cambio y se poda al final del drenaje (la parte con escenas reales de 4 se cierra en carga-de-planta).
- [ ] `run_after_drain(job)` ejecuta `job` una vez al terminar el drenaje en curso, o en el acto si no hay drenaje; `clear_pending()` vacía la cola sin notificar.
- [ ] `set_enqueue_tap(tap)` observa cada aviso en el momento de encolarse, antes de cualquier entrega, y no cuenta como suscriptor.

---

## Implementation Notes

*Derived from ADR-0001 D5, D6, D9 y § Drain and Write Algorithms:*

- Firmas: `clear_pending() -> void`, `run_after_drain(job: Callable) -> void`, `set_enqueue_tap(tap: Callable) -> void` (ADR-0001 § Key Interfaces).
- Las entradas encoladas mientras se entrega `notices_dropped` tienen presupuesto nuevo; el segundo desbordamiento descarta en silencio (solo log).
- `notices_dropped` se nombra por `NoticeIds` (004). Si 004 no está aún, el test usa la constante que 004 declarará; no hay literal de cadena fuera de `notice_ids.gd` y tests (G-2).

---

## Out of Scope

- Story 004: registro de nombres y esquemas.
- Story 012: uso del tap para la ventana de `write_silent`.

---

## Files

- `src/core/notice_channel.gd`
- `tests/unit/state/notice_channel_cap_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/notice_channel_cap_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-002-notice-channel-core.md`
- Unlocks: `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`, `production/epics/estado-y-bus/story-011-reset-new-game.md`

---

## Evidencia

- `tests/unit/state/notice_channel_cap_test.gd` (17 tests): CA-15 (tope 8: 8 entregadas, 1 log, 1 `fail`, 1 `notices_dropped`; segundo desbordamiento solo log; límites cap y cap+1), CA-17 unitario (nodo liberado y callable nulo: sin error, podados), `run_after_drain`, `clear_pending`, tap.
- Suite completa en Godot 4.7.2: 186 casos, 0 errores, 0 fallos, 0 huérfanos (31/31 suites); `--import` sin errores.
- Nota: `notices_dropped` usa `NoticeChannel.NOTICES_DROPPED` con `# TODO(ADR-0001)` hasta que EB-004 cree `NoticeIds`. Segundo desbordamiento: solo log, sin `fail` (ADR D5 y historia; el pseudocódigo del ADR llama a `fail` en ambos).
