# Story 002: `DataSchema`/`FieldSpec`, `DataReader.normalise` y `to_int`

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation (capa 0 Platform)
> **Type**: Logic
> **Estimate**: L (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, regla 1 (tipos de contenido con campos obligatorios)
**Requirement**: `TR-content-001` (cada tipo con sus campos), apoyo a `TR-state-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D2 Schema catalog, D4 Explicit numeric conversion)
**ADR Decision Summary**: Los esquemas son declaraciones GDScript (`DataSchema` abstracto con `version()`, `root()`, `rules()`) construidas con ayudantes estáticos; `DataReader.read_file(entry)` = parse + `schema_version` + normalización + `FileRules`, sin lanzar nunca. `to_int` es la única conversión entera del proyecto.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: el parser devuelve números como `float`; `to_int` acepta `int` o `float` de fracción nula dentro de rango y rechaza el resto (D4.1). `stringify(INF)` escribe `1e99999` (F-R52 nota).

**Control Manifest Rules (this layer)**:
- Required: F-R49 (solo `DataReader.read_file`), F-R51 (`schema_version` entero; rechazar versión mayor), F-R52 (`to_int`), F-R53 (colecciones abiertas = arrays de registros con `id`), F-R58 (datos normalizados inmutables), F-R59 (claves desconocidas = error salvo `open_with_warning`), F-R65
- Forbidden: `int()` sobre datos leídos
- Guardrail: —

---

## Acceptance Criteria

*Derivados de ADR-0005 D2/D4 (el GDD 18 AC-01 se prueba sobre esta base en 004):*

- [ ] `to_int`: `2` y `2.0` → 2 sin issue; `2.5`, `"2"`, `true`, fuera de rango → issue y valor no aceptado.
- [ ] `normalise` produce `StringName` para `id_`/`enum_`, `int` para `int_`, arrays tipados cuando el elemento lo permite; clave obligatoria ausente o desconocida → issue con ruta (`puzzles[2].id`).
- [ ] `schema_version` ausente, no entero o mayor que `version()` → issue; el resultado nunca lanza y recoge todos los problemas del fichero.

---

## Implementation Notes

- Firmas fijadas (ADR-0005 Key Interfaces): `DataSchema.version() -> int`, `root() -> FieldSpec`, `rules() -> FileRules`; ayudantes `int_`, `float_`, `id_(regex, ref)`, `enum_`, `array_(of, lo, unique_key)`, `object_(req, opt)`, `nullable`, `lang_text`; `DataReader._init(files: FileStore, flavor: BuildFlavor)`, `read_file(entry: DataCatalog.Entry) -> DataResult`, `static to_int(v, file, path, issues) -> int`, `normalise(...)`.
- Seguir el boceto de `normalise` de ADR-0005 (rama por tipo) literalmente. `DataCatalog.Entry` se declara aquí como tipo mínimo; el registro completo es 003.

---

## Out of Scope

- Story 003: registro de ficheros, `RefIndex`, validador.

---

## Files

- `src/core/data/field_spec.gd`, `src/core/data/data_schema.gd`, `src/core/data/data_reader.gd`, `src/core/data/file_rules.gd`
- `tests/unit/content/data_reader_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/data_reader_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-001-file-store-and-json-text.md`
- Unlocks: `production/epics/contenido-y-datos/story-003-data-catalog-and-validator.md`, `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`, `production/epics/entrada-y-controles/story-001-input-types-and-binding-table.md`
