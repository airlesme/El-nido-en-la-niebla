# Story 003: `DataCatalog`, `RefIndex` y `DataValidator` (paso 4 de arranque)

> **Epic**: Contenido narrativo y datos validados
> **Status**: Done
> **Layer**: Foundation (capa 0 Platform)
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 15–16 (verificación: referencias existentes)
**Requirement**: `TR-content-013` (base: referencias e IDs duplicados), `TR-content-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D1 registro canónico, D3 tres niveles L/B/C) · ADR-0009 (D1: `DataValidator` lo crea `Boot`, paso 4, solo debug)
**ADR Decision Summary**: `DataCatalog.entries()` es la única lista de ficheros cargables (`assets/data/<dominio>/<fichero>.json`, una carpeta). El mismo `DataReader` sirve los tres niveles: L (cada dueño al cargar), B (barrido de arranque en debug) y C (CI). `DataValidator.sweep` construye el `RefIndex` y resuelve cada `ref()` sin detenerse en el primero.
**ADR Version**: ADR-0005 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna adicional a 001/002.

**Control Manifest Rules (this layer)**:
- Required: F-R50 (entrada en `DataCatalog` y esquema antes de que exista el fichero), F-R60 (política de release por fila), F-R65, F-R27 (paso 4 en orden)
- Forbidden: `Boot` llama a `DataValidator.run` en release
- Guardrail: —

---

## Acceptance Criteria

*Derivados de ADR-0005 D1/D3 y del GDD 18 (AC-04 parte T, AC-17 base):*

- [ ] `DataCatalog.entries()` devuelve las entradas en el orden fijo de D2.3; un fichero fuera del convenio (raíz de `assets/data/`, kebab-case) no puede registrarse (test sobre el registro).
- [ ] `sweep` sobre fixtures con una referencia inexistente y un ID duplicado entre dos ficheros devuelve ambos issues (no se detiene en el primero).
- [ ] `DataValidator.run(ctx)` en debug con issues de error llama a `ctx.fatal` con `CONTENIDO_INVALIDO`/`CATALOGO_INVALIDO` según la fila; `Boot` no lo llama con `BuildFlavor` release.

---

## Implementation Notes

- Firmas (ADR-0005): `static DataCatalog.entries() -> Array[Entry]`; `RefIndex.add(kind, id)`, `add_retired(id)`, `has(kind, id)`, `is_retired(id)`, `fact_accepts(fact, value)`; `DataValidator._init(reader, log_sink)`, `sweep(entries) -> Array[DataIssue]`, `run(ctx) -> void`.
- Registrar en esta historia solo las filas de M1 (`state/flags.json`, ficheros `narrative/*`, `input/default_bindings.json`, `puzzles/puzzles.json`); cada fila con su esquema la añade la historia dueña del fichero (F-R50).
- Cablear el paso 4 en `Boot.compose()` (TODO actual de `boot.gd`).

---

## Out of Scope

- Story 010: verificador de `tools/` (nivel C con reglas narrativas).

---

## Files

- `src/core/data/data_catalog.gd`, `src/core/data/ref_index.gd`, `src/core/data/data_validator.gd`, `src/core/boot/boot.gd`
- `tests/unit/content/data_validator_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/data_validator_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-002-schema-and-data-reader.md`
- Unlocks: `production/epics/contenido-y-datos/story-004-content-db-load-and-lifecycle.md`, `production/epics/contenido-y-datos/story-010-data-check-verifier-core.md`, `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`

---

## Evidencia

- `--headless --path . --import`: sin errores.
- Suite completa gdUnit4 (Godot 4.7.2): `Overall Summary: 256 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`, `Executed test suites: (34/34)`, `Exit code: 0`; sin `ObjectDB instances were leaked` ni `resources still in use`.
- `tests/unit/content/data_validator_test.gd` (21 tests): orden y convención del registro (`is_valid_path` rechaza raíz, kebab-case, mayúsculas, dos carpetas, `.JSON`, `ñ`), `RefIndex`, `sweep` (ref inexistente + ID duplicado entre ficheros: ambos issues; retirado; fact; fichero ausente), `run` (`CONTENIDO_INVALIDO`/`CATALOGO_INVALIDO` con count/file/param, warnings sin fatal), `Boot.run_data_validation` (release: 0 lecturas).
- Notas: (1) las filas M1 están registradas en `DataCatalog.registry()`, pero `entries()` solo devuelve las que ya tienen esquema (hoy ninguna) hasta que la historia dueña lo aporte (F-R50; `TODO(CD-004/EB-005/ADR-0006/ADR-0010)`), por lo que el barrido real de arranque está vacío. (2) `RefIndex.set_fact_values` y `provides` no están en el ADR (`TODO(ADR-0005)`); `fact_value` y kinds sin proveedor se omiten (`TODO(ADR-0010)`). (3) Boot crea su propio `FileStore` hasta que `ServiceContext` tenga `files`. (4) `TestContexts.make` crea `FakeClock`/`FakeGameState` aunque se sobrescriban (huérfanos); los tests de esta historia construyen el contexto a mano.
