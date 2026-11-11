# Story 002: `NoticeChannel` — suscripción, cola FIFO, drenaje síncrono sin reentrada

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, reglas 8 a 11 (avisos)
**Requirement**: `TR-state-008`, `TR-state-009`, `TR-state-010` (baja diferida)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (D1, D5, D6)
**ADR Decision Summary**: Despachador propio (`NoticeChannel`, `RefCounted`) con una lista ordenada de suscripciones (`FACT`, `ALL_FACTS`, `NOTICE`) y una cola FIFO; `notify`/`push_change` encolan y drenan en el acto salvo que ya se esté drenando (no reentrada). La baja durante una entrega surte efecto al terminar esa entrega.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: lambdas como callback declaran los tres parámetros (`fact, old, new`) o `...args` (ADR-0001 § Key Interfaces; spike V-ENG `adr0001_variadic_lambda_test.gd`). Los tests usan un `Array`/`Dictionary` grabador (las lambdas capturan locales por valor).

**Control Manifest Rules (this layer)**:
- Required: F-R01 (todo aviso por `NoticeChannel`, FIFO única, drenaje síncrono, no reentrante), F-R07 (callbacks baratos, sin `await`), F-R48 (ningún consumidor depende de entrega en el mismo fotograma a un suscriptor de física — C1 medido en S-0006)
- Forbidden: señales de Godot para avisos de la regla 10 (ADR-0001 D1, D10; G-5)
- Guardrail: el bus no tiene procesamiento por fotograma (G-10)

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story (probados sobre `NoticeChannel` aislado):*

- [ ] **CA-09**: un aviso emitido sin suscriptores no lo recibe quien se suscribe después.
- [ ] **CA-10**: un suscriptor recibe un cambio exactamente una vez con (nombre, anterior, nuevo); escribir el mismo valor no entrega nada (la comprobación «cambia realmente» la hace quien llama a `push_change`, 008; aquí se prueba que una entrada = una entrega).
- [ ] **CA-12**: suscriptores A y B reciben en orden A, B; dos cambios sucesivos llegan en orden de ocurrencia. Un suscriptor `FACT` de X no recibe Y (regla 9).
- [ ] **CA-16**: quien se da de baja durante una entrega no recibe ningún aviso posterior; una suscripción hecha durante una entrega vale desde la siguiente entrada.

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines y § Drain and Write Algorithms:*

- Firmas (ADR-0001 § Key Interfaces, «proposed signature» fijada por el ADR): `_init(max_chained: int, log_sink: LogSink, errors: ErrorPolicy, schema: Dictionary = {})`, `subscribe(kind: Kind, topic: StringName, cb: Callable) -> int` (handle > 0), `unsubscribe(handle: int) -> void` (handle desconocido: no-op), `push_change(fact, old, new)`, `notify(notice, payload := {})`, `is_queue_empty() -> bool`, `is_draining() -> bool`.
- Callbacks: hechos `func(fact: StringName, old: Variant, new: Variant)`; avisos `func(payload: Dictionary)` (diccionario vacío si no hay datos).
- Subscripción = `{handle, kind, topic, cb, active}`; la entrega recorre la lista en orden y filtra en el bus. Marcar para quitar, quitar al terminar la entrada actual.
- Seguir el pseudocódigo de § Drain and Write Algorithms literalmente; el tope, `run_after_drain` y el tap son de 003.
- Archivo: `src/core/notice_channel.gd` (`class_name NoticeChannel`).

---

## Out of Scope

- Story 003: tope `max_chained_notices`, `notices_dropped`, callables inválidos, `clear_pending`, `run_after_drain`, `set_enqueue_tap`.
- Story 004: validación de nombres y payloads contra `NoticeIds.SCHEMA`.

---

## Files

- `src/core/notice_channel.gd`
- `tests/unit/state/notice_channel_core_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/notice_channel_core_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-001-platform-seams.md`
- Unlocks: `production/epics/estado-y-bus/story-003-notice-channel-cap-and-lifecycle.md`, `production/epics/estado-y-bus/story-004-notice-ids-registry.md`
