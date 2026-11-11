# Story 004: Esquemas narrativos y carga de `ContentDB` (Sin cargar → Listo / Error)

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 1, 14 y 19; § States and Transitions
**Requirement**: `TR-content-001`, `TR-content-011`, `TR-content-012` (solo lectura; la recarga en caliente está diferida)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D6 `ContentDB`; D10 esquemas narrativos en `src/narrative/`) · ADR-0009 (D1 autoload n.º 1, D2 paso 1)
**ADR Decision Summary**: `ContentDB.setup(ctx)` lee una vez los ficheros narrativos registrados, valida y construye un `ContentSnapshot` inmutable; error → `ctx.fatal(CONTENIDO_INVALIDO)` y estado `Error`. Peticiones en «Sin cargar»/«Cargando»: error visible en dev, «…» con log en release. Sin operaciones de escritura ni lectura de `GameState`.
**ADR Version**: ADR-0005 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna adicional a 001/002.

**Control Manifest Rules (this layer)**:
- Required: F-R58 (snapshot inmutable), F-R61 (todo texto visible sale de `ContentDB`; únicos literales: «…» y el mensaje de fallo de carga), F-R62 (lee ficheros solo en `setup()`), F-R26
- Forbidden: leer `GameState` desde `ContentDB`; I/O fuera de `setup()`
- Guardrail: lectura única al arrancar

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`, scoped to this story:*

- [ ] **AC-01**: en «Listo», un ejemplo de cada tipo (línea, documento, correo, ficha T1, pista, `UI_…`, `OBJ_…`) devuelve todos sus campos obligatorios no vacíos (fixtures).
- [ ] **AC-14 (parte automática)**: la interfaz pública de `ContentDB` no tiene operaciones de escritura (test que enumera los métodos públicos contra una lista permitida) ni referencia a `GameState`.
- [ ] **AC-21 (primera mitad)**: tras arrancar, varias peticiones no vuelven a leer ficheros (contador de `MemoryFileStore`).
- [ ] **AC-E1**: en «Sin cargar»/«Cargando», en dev `ErrorPolicy.fail`, en release «…» y log; con un fichero ausente o corrupto, estado `Error` y `RecordingFatalHandler` recibe `CONTENIDO_INVALIDO`.

---

## Implementation Notes

- Firmas (ADR-0005): `setup(ctx)`, `get_status() -> Status`, `has_key(id) -> bool`, `key_kind(id) -> StringName`, `get_language() -> StringName`. Los getters por tipo se completan en 005–008.
- Esquemas narrativos y `ContentRules` en `src/narrative/` (D10). Ficheros: los 10 narrativos de la fila de D1; en M1 basta con los que contengan datos de escenas 1–3 (009) — los demás se registran con contenido vacío válido si el esquema lo admite; si no lo admite, *ADR-fallback*: registrar solo los presentes y anotarlo en ADR-0005 Open Items.

---

## Out of Scope

- `dev_reload` (diferido por ADR-0018).
- Stories 005–008: idioma, segmentos, correos, variantes.

---

## Files

- `src/narrative/content_db.gd`, `src/narrative/content_snapshot.gd`, `src/narrative/content_rules.gd`, `src/narrative/data/*_schema.gd`
- `tests/unit/content/content_db_lifecycle_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/content_db_lifecycle_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-003-data-catalog-and-validator.md`
- Unlocks: `production/epics/contenido-y-datos/story-005-language-layer-and-markers.md`, `production/epics/contenido-y-datos/story-006-lines-documents-audio.md`, `production/epics/contenido-y-datos/story-007-mails-and-tasks.md`, `production/epics/contenido-y-datos/story-008-variant-groups-ids-duplicates.md`
