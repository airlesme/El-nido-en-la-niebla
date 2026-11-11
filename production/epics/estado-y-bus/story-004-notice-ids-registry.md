# Story 004: Registro `NoticeIds` y validación de payload en debug

> **Epic**: Estado y bus de eventos
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 10 (tabla de avisos con nombre y sus datos)
**Requirement**: `TR-state-012` (un único mecanismo; formato técnico fijado por ADR)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (D3, D4, D11; § Notice Name Registry)
**ADR Decision Summary**: Cada aviso es una constante `StringName` de un registro cerrado (`NoticeIds`, `src/core/notice_ids.gd`); los payloads son `Dictionary` con claves `StringName` y un esquema por aviso (`NoticeIds.SCHEMA`) que el canal valida solo en debug. Emitir un nombre ausente es una llamada inválida (dev: halt; release: se descarta con log).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna API post-corte; validación de tipos con `typeof()` frente a `Variant.Type`.

**Control Manifest Rules (this layer)**:
- Required: F-R02 (nombres de aviso como `NoticeIds.X`), F-R04 (payload `Dictionary` con claves `StringName` iguales a los nombres del GDD), F-R08 (consumidores de `interaction_executed` filtran `InteractionNotice.is_done`)
- Forbidden: literales de cadena para nombres de aviso fuera de `notice_ids.gd` y tests (G-2); mutar un payload recibido (G-7)
- Guardrail: la validación de esquema no corre en release

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-11 (con emisor de prueba)**: un suscriptor a cada aviso con nombre de la regla 10 que figura en § Notice Name Registry lo recibe con su nombre y datos; un suscriptor a un hecho concreto no recibe los cambios de otro.
- [ ] **CA-36**: `scene_load_started` llega con (`destino`, `motivo`, `D_carga`), `scene_load_failed` con (`destino`, `motivo`, causa) y el registro documenta un único emisor de «partida terminada» (4).
- [ ] En debug, `notify` con nombre no registrado, clave obligatoria ausente, clave desconocida o tipo erróneo llama a `ErrorPolicy.fail`; en release se descarta/acepta con una línea de log y sin validar el esquema.
- [ ] `InteractionNotice.is_done(payload)` devuelve `true` solo con `resultado == &"HECHO"` (D11).

---

## Implementation Notes

*Derived from ADR-0001 D3, D4, D11 y § Notice Name Registry:*

- Copiar los nombres y esquemas **literalmente** de § Notice Name Registry (ADR-0001 l. 386 y ss.); no añadir avisos que no estén ahí. Los que nombra el GDD en código (`pause_opened`, `pause_closed`, `EV_PUZZLE_SOLVED_P1`…`P6`) se usan tal cual.
- Avisos que pertenecen a ADR `Proposed` (p. ej. los payloads de audio de ADR-0008 o `settings_applied` de ADR-0007) se declaran solo si el registro de ADR-0001 los fija ya; si su esquema depende del ADR Proposed, se dejan fuera con un comentario `# pending ADR-00NN` y se anota en el índice.
- `NoticeChannel._init(..., schema)` recibe `NoticeIds.SCHEMA`; la comprobación usa `ErrorPolicy.is_strict()`.

---

## Out of Scope

- Emisores reales de cada aviso (sus épicos).
- Story 003: `notices_dropped` como mecanismo (aquí solo su entrada en el registro).

---

## Files

- `src/core/notice_ids.gd`, `src/core/interaction_notice.gd`
- `src/core/notice_channel.gd` (validación)
- `tests/unit/state/notice_ids_registry_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/notice_ids_registry_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-002-notice-channel-core.md`
- Unlocks: `production/epics/estado-y-bus/story-012-silent-write-window.md`, `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`

---

## Evidencia

- `src/core/notice_ids.gd` (constantes + `SCHEMA`, 54 avisos del § Notice Name Registry), `src/core/interaction_notice.gd`, validación en `NoticeChannel.notify()`; `NoticeChannel.NOTICES_DROPPED` provisional sustituido por `NoticeIds.NOTICES_DROPPED`.
- `tests/unit/state/notice_ids_registry_test.gd` (19 casos): CA-11, CA-36, validación debug (nombre ausente, clave obligatoria ausente, clave desconocida, tipo erróneo incl. int por float, clave String), release (nombre ausente descartado con log, sin validar esquema) y `is_done` (D11).
- `godot --headless --path . --import`: sin errores. Suite completa: `Overall Summary: 235 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`, exit 0; sin `ObjectDB instances were leaked` ni `resources still in use`.
- Decisiones: esquema vacío en el canal = sin validación (los tests previos usan nombres libres); en debug un aviso inválido se descarta tras `ErrorPolicy.fail`; `float` exige float (no acepta int). Ningún aviso omitido por ADR `Proposed`: el registro de ADR-0001 los fija todos.
