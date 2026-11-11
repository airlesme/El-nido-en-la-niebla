# Story 001: `FileStore` y `JsonText` (BOM en bytes, comas finales, claves duplicadas)

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation (piezas de capa 0 Platform)
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, regla 19 (carga única) y § Edge Cases (fichero ausente o corrupto)
**Requirement**: `TR-content-011` (lectura única; fichero ausente/corrupto → Error), `TR-content-015` (duplicados — la parte intra-fichero que el parser oculta)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D5 Reading files; § Spike Results S-0005-A) · ADR-0009 (D9 `MemoryFileStore`)
**ADR Decision Summary**: `JsonText.parse()` es el único sitio que toca el parser JSON; el BOM se comprueba en los bytes antes de decodificar, las comas finales y las claves duplicadas (indetectables tras parsear) se pre-comprueban sobre el texto; `get_open_error()` se lee en el acto tras abrir. Toda E/S de ficheros va por un `FileStore` inyectable.
**ADR Version**: ADR-0005 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: S-0005-A (4.7.2): claves duplicadas se pierden en silencio; BOM no se ve tras `get_as_text`; comas finales toleradas; un fichero ausente devuelve `""`, indistinguible de uno vacío salvo por `get_open_error()`. Ver `tests/unit/engine_facts/adr0005_json_parser_test.gd`.

**Control Manifest Rules (this layer)**:
- Required: F-R54 (`JsonText.parse` envuelve `JSON.new().parse(text)` con línea y mensaje), F-R55 (BOM sobre bytes), F-R56 (UTF-8 sin BOM, LF, JSON estricto), F-R57 (`get_open_error()` en el acto), F-R65 (recoger todos los problemas)
- Forbidden: `FileAccess`/`JSON` fuera de `FileStore`/`JsonText`
- Guardrail: —

---

## Acceptance Criteria

*Derivados de ADR-0005 D5 y S-0005-A; el GDD fija el observable (AC-E1, AC-21):*

- [ ] Un fichero con BOM, con coma final, con una clave duplicada en un objeto o con JSON roto devuelve `null` y un `DataIssue` con fichero, línea (si la hay) y código; nunca lanza.
- [ ] Un fichero ausente se distingue de uno vacío (issue `missing` vs `empty`).
- [ ] **AC-21 (parte de lectura)**: `MemoryFileStore` cuenta accesos; leer el mismo fichero dos veces por `FileStore` registra dos accesos (la garantía «una sola vez» la da 004).

---

## Implementation Notes

- Firma fijada (ADR-0005 Key Interfaces): `static func JsonText.parse(text: String, file: String, issues: Array[DataIssue]) -> Variant`. `DataIssue` (`_init(sev, file, path, …)`, `format()`) y `DataResult` (`has_errors()`, `first_error()`) se crean aquí.
- **`FileStore`: firma NO fijada** en los ADR Accepted leídos (ADR-0009 solo la lista en capa 0 y describe `MemoryFileStore` como «dict path → bytes» con fallos inyectables). *Tarea de la historia — ADR-fallback documentado*: mínimo necesario para leer (`read_bytes(path) -> PackedByteArray` + error de apertura) propuesto en la historia, registrado como Open Item en ADR-0009 y revisado por `lead-programmer` antes de cerrar; escritura/renombrado quedan para ADR-0004.
- Ruta: `src/core/platform/file_store.gd`, `src/core/data/json_text.gd`, `data_issue.gd`, `data_result.gd`.

---

## Out of Scope

- Story 002: esquemas y normalización.

---

## Files

- `src/core/platform/file_store.gd`, `src/core/data/json_text.gd`, `src/core/data/data_issue.gd`, `src/core/data/data_result.gd`
- `tests/doubles/memory_file_store.gd`
- `tests/unit/content/json_text_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/json_text_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-001-platform-seams.md`
- Unlocks: `production/epics/contenido-y-datos/story-002-schema-and-data-reader.md`
