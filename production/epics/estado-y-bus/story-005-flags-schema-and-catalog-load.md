# Story 005: Esquema de `flags.json` y `GameState.load_catalog`

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 1 (catálogo cerrado) y regla 14 (arranque); § States and Transitions («Sin cargar» → «Listo»)
**Requirement**: `TR-state-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D1 fila `state/flags.json`, D2 tabla de esquemas, D3 nivel L) · ADR-0001 (D7, D8, G-9)
**ADR Decision Summary**: `flags.json` = `{schema_version: 1, max_chained_notices: INT 8–256, facts: [{name, type, initial, owner, range?, values?, derive?}]}` con exactamente 20 hechos; se lee solo con `DataReader.read_file(entry)` y su esquema GDScript; cualquier error → `ctx.fatal.raise_fatal(&"CATALOGO_INVALIDO", {...})` y no hay partida.
**ADR Version**: ADR-0005 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: el parser JSON devuelve todo número como `float`: los `int` pasan por `DataReader.to_int()` (ADR-0005 D4.1, F-R52). Claves duplicadas no son detectables tras parsear (S-0005-A) — lo cubre `JsonText` (contenido-y-datos 001).

**Control Manifest Rules (this layer)**:
- Required: F-R49 (solo `DataReader.read_file`), F-R50 (entrada en `DataCatalog` y esquema antes de existir el fichero), F-R51 (`schema_version` entero), F-R52 (`to_int`), F-R10 (`max_chained_notices`), F-R36 (`ctx.fatal`), F-R26 (sin I/O en `_init`/`_ready` del autoload)
- Forbidden: `FileAccess`/`JSON` fuera de `JsonText`/`FileStore` (F-R54)
- Guardrail: carga única al arrancar

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story (con un fixture de 20 hechos en `MemoryFileStore`):*

- [ ] **CA-01**: con el fichero de catálogo, al cargar existen exactamente 20 hechos y cada uno devuelve su inicial.
- [ ] **CA-26 (parte unitaria)**: fichero ausente, JSON corrupto, 19 o 21 hechos, `type` desconocido, `owner` no entero o `max_chained_notices` fuera de 8–256 → `RecordingFatalHandler` recibe `CATALOGO_INVALIDO` con el parámetro culpable y `get_status()` sigue en `UNLOADED`.
- [ ] El `NoticeChannel` de `GameState` se crea con el `max_chained_notices` leído (no con una constante).

---

## Implementation Notes

*Derived from ADR-0005 D1–D3 y ADR-0001 § Key Interfaces:*

- Firmas fijadas por ADR-0001: `load_catalog(path: String) -> Error`, `get_status() -> Status` (`enum Status { UNLOADED, READY, RESTORING }`). `RESTORING` se declara pero no se usa (restaurar está diferido por ADR-0004).
- El esquema vive en el `src/<area>/data/` del dueño (ADR-0005 D10, ruta marcada ‡): `src/core/state/data/flags_schema.gd` es la propuesta; *ADR-fallback*: si `/dev-story` ve conflicto con `src/core/data/` (capa 0), se queda en `src/core/state/data/` y se anota en ADR-0005 Open Items.
- `derive` declara la combinación (`caja_completa = caja_c1 ∧ … ∧ caja_c4`); aquí solo se valida que las entradas existen; el recálculo es 010.
- Enum: `String` o `null` en el fichero → `StringName` / `&""` («sin fijar») normalizado (ADR-0001 Read API contract).

---

## Out of Scope

- Story 006: el fichero real con los 20 hechos.
- Story 014: llamada desde `setup(ctx)` en el orden de arranque.

---

## Files

- `src/core/game_state.gd`, `src/core/state/data/flags_schema.gd`, entrada en `src/core/data/data_catalog.gd`
- `tests/unit/state/flags_catalog_load_test.gd`, `tests/fixtures/state/flags_*.json`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/flags_catalog_load_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-001-platform-seams.md`, `production/epics/contenido-y-datos/story-002-schema-and-data-reader.md`, `production/epics/contenido-y-datos/story-003-data-catalog-and-validator.md`
- Unlocks: `production/epics/estado-y-bus/story-006-flags-json-data.md`, `production/epics/estado-y-bus/story-007-fact-reads.md`, `production/epics/estado-y-bus/story-014-boot-wiring-state.md`
