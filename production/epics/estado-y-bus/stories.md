# Historias — Épico: Estado y bus de eventos

> **Épico**: `production/epics/estado-y-bus/EPIC.md` · **GDD**: `design/gdd/estado-y-bus-de-eventos.md` (3)
> **Generado**: 2026-11-11 por `/create-stories` (modo autonomous, `review_mode: lean` → QL-STORY-READY omitido)
> **Manifest Version**: 2026-11-11b · **Granularidad**: balanced (2–4 CA por historia)
> **ADRs**: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0005 Accepted · ADR-0009 Accepted · ADR-0004 **Proposed** · ADR-0007 **Proposed** · ADR-0018 **Proposed**
> **Estimaciones**: días-persona, **confianza BAJA** (no hay velocidad medida; ningún sprint cerrado). S ≈ 0,5 d · M ≈ 1 d · L ≈ 2 d.

| ID | Título | Tipo | Est. | Días | Depende de | Estado |
|----|--------|------|------|------|------------|--------|
| [001](story-001-platform-seams.md) | Costuras de plataforma: `LogSink`, `ErrorPolicy`, `FatalErrorHandler`, `TestContexts` | Logic | M | 1,5 | — | Ready |
| [002](story-002-notice-channel-core.md) | `NoticeChannel`: suscripción, cola FIFO, drenaje síncrono sin reentrada | Logic | M | 1 | 001 | Ready |
| [003](story-003-notice-channel-cap-and-lifecycle.md) | `NoticeChannel`: tope de avisos encadenados, callables inválidos, `run_after_drain`, tap | Logic | M | 1 | 002 | Ready |
| [004](story-004-notice-ids-registry.md) | Registro `NoticeIds` y validación de payload en debug | Logic | M | 1 | 002 | Ready |
| [005](story-005-flags-schema-and-catalog-load.md) | Esquema de `flags.json` y `GameState.load_catalog` | Logic | M | 1,5 | 001, contenido-y-datos 002 y 003 | Ready |
| [006](story-006-flags-json-data.md) | Datos `assets/data/state/flags.json` (20 hechos, dueños) | Config/Data | S | 0,5 | 005 | Ready |
| [007](story-007-fact-reads.md) | Lecturas O(1): `get_fact`, `resolve_fact`, `get_fact_at`, valor neutro | Logic | S | 0,5 | 005 | Ready |
| [008](story-008-validated-writes-and-writer.md) | Escritura validada y `FactWriter` (tipo, rango, dueño en dev) | Logic | M | 1,5 | 003, 007 | Ready |
| [009](story-009-one-way-and-reversible-facts.md) | Hechos de un solo sentido y reversibles | Logic | S | 0,5 | 008 | Ready |
| [010](story-010-derived-facts.md) | Hechos derivados (`caja_completa`) | Logic | S | 0,5 | 008 | Ready |
| [011](story-011-reset-new-game.md) | Partida nueva: `reset_new_game` y `state_reset` | Logic | S | 0,5 | 003, 008 | Ready |
| [012](story-012-silent-write-window.md) | `write_silent` y ventana de carga por tap | Logic | M | 1 | 004, 008 | Ready |
| [013](story-013-dev-console-hook.md) | Gancho de consola de pruebas `dev_force` | Logic | S | 0,5 | 010 | Ready |
| [014](story-014-boot-wiring-state.md) | Composición en `Boot`: catálogo al arrancar y entrega de `FactWriter` | Integration | M | 1 | 001, 005, 008 | Ready |
| [015](story-015-m1-state-test.md) | Test de estado de M1: 5 flags por su dueño, sin estados terminales en escenas 1–3 | Integration | M | 1 | 006, 009, 010, 014 | Ready |

**Total**: 15 historias (12 Logic, 2 Integration, 1 Config/Data) · ≈ 13 días-persona · 15 Ready, 0 Blocked.
**Camino crítico**: 001 → 002 → 003 → (contenido 002/003) → 005 → 007 → 008 → 010 → 015. Toda historia jugable de M1 que escribe un hecho depende de 008 y 014.

## Diferido / bloqueado por ADR

No se escribe historia sobre estos requisitos (regla del hito M1 § ADR y spikes):

| Requisito / CA | Bloqueado por | Motivo |
|---|---|---|
| TR-state-013 (instantánea), CA-19, CA-24 | ADR-0004 (Proposed) | Guardado, recorte 4 del hito |
| TR-state-014 (restaurar atómico), CA-20, CA-21, CA-22, CA-23, CA-34 | ADR-0004 (Proposed) | Guardado, recorte 4 |
| TR-state-015 (tolerancia de tipos al restaurar), CA-33 | ADR-0004 (Proposed) | Guardado, recorte 4 (`DataReader.to_int` sí entra, en contenido-y-datos 002) |
| TR-state-016 (`request_snapshot`), CA-25 | ADR-0004 (Proposed) | Guardado, recorte 4 (`is_queue_empty` sí entra, en 002) |
| CA-35, cláusula «Guardado doble con línea base» | ADR-0004 (Proposed) | El resto de CA-35 entra en 012 |
| CA-37, cláusula «la instantánea siguiente lo recoge» | ADR-0004 (Proposed) | El aviso genérico de cambio se prueba en 002 |
| TR-state-018, CA-29 (script de CI que comprueba que la consola no está en la demo) | ADR-0018 (Proposed) | Exclusión del export y `tools/ci/` son de ADR-0018; el gancho entra en 013 |
| ADR-0001 D2: segunda instancia de `NoticeChannel` en `Settings` (6) | ADR-0007 (Proposed) | Ajustes persistentes, recorte 7; la clase es la misma (002/003) |

## Decisiones tomadas (modo autonomous)

- **Costuras de plataforma en este épico (001).** `LogSink`, `ErrorPolicy` y `FatalErrorHandler` no tienen épico propio en M1 y los necesitan los tres épicos Foundation; ADR-0001 y ADR-0009 (Accepted) los firman. *Descartado:* crear un épico «plataforma» — añade un artefacto sin trabajo nuevo.
- **`flags.json` lo escribe este épico (006)**, no contenido-y-datos: el registro de ADR-0005 D1 da a 3 como dueño del fichero. El criterio C-M1-4 de contenido-y-datos queda cubierto aquí.
- **`reset_new_game` (011) sin TR propio:** la regla 12 del GDD (partida nueva) no tiene fila en `tr-registry.yaml` fuera de la instantánea; se cita `TR-state-???` y se anota como hueco del registro para `/architecture-review`.
