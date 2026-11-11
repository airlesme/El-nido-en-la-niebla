# Story 007: Lecturas O(1) — `get_fact`, `resolve_fact`, `get_fact_at`, valor neutro

> **Epic**: Estado y bus de eventos
> **Status**: Done — criterios con evidencia; suite 290/290 con EB-006 (los fallos ajenos del momento se resolvieron)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 3 (lectura) y § Edge Cases (lectura en «Sin cargar» / hecho no declarado)
**Requirement**: `TR-state-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (§ Key Interfaces «Reads», Read API contract, G-3)
**ADR Decision Summary**: Lectura por diccionario O(1) o, en caliente, por índice resuelto una vez (`resolve_fact` en `configurar()`, `get_fact_at` por paso de física). Hecho no declarado o `UNLOADED`: dev → `ErrorPolicy.fail`; release → valor neutro del tipo + una línea de log.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: coste de lectura de `Dictionary` medido en `tests/unit/engine_facts/adr0001_dictionary_read_cost_test.gd`.

**Control Manifest Rules (this layer)**:
- Required: F-R03 (nombres de hecho como `StringName`; en caliente índices cacheados), F-R05 (leer por la referencia inyectada)
- Forbidden: nombrar `GameStateAutoload` fuera de `Boot` (F-R25)
- Guardrail: ~35 objetos con `habilitado_si` leen por paso de física: `get_fact_at` sin asignaciones

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [x] **CA-02 (lectura)**: un hecho sin tocar devuelve su inicial (bool/int/`StringName`, `&""` = sin fijar).
- [x] **CA-27**: en release y «Sin cargar», o con un hecho no declarado en «Listo», la lectura devuelve el neutro (`false`, `0`, `&""`; no declarado → `false`) y añade una línea de log; en dev llama a `ErrorPolicy.fail`.
- [x] `resolve_fact(&"no_existe") == -1`; `get_fact_at(resolve_fact(x)) == get_fact(x)` para los 20 hechos; `is_declared` distingue mayúsculas (`Tarjeta_B` no existe).

---

## Implementation Notes

- Firmas (ADR-0001): `get_fact(fact: StringName) -> Variant`, `resolve_fact(fact: StringName) -> int`, `get_fact_at(index: int) -> Variant`, `is_declared(fact: StringName) -> bool`.
- Almacenamiento: `Array` de valores indexado + `Dictionary[StringName, int]` de índices; el test de «sin asignaciones» es revisión de código (no hay contador fiable de asignaciones en GDScript).

---

## Out of Scope

- Story 008: escritura. CA-27 «la escritura se descarta» se prueba allí.

---

## Files

- `src/core/game_state.gd`
- `tests/unit/state/fact_reads_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/fact_reads_test.gd` — must exist and pass.
**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`
- Unlocks: `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`

---

## Evidencia

- `tests/unit/state/fact_reads_test.gd`: 10 casos, 0 fallos, 0 orphans (CA-02, CA-27 dev/release/UNLOADED, `resolve_fact` -1, `get_fact_at == get_fact` para los 20 hechos, mayúsculas, índice -1/20 fuera de rango).
- Coste registrado (sin aserción): 0,00017 ms por `get_fact_at` (10000 iteraciones, headless).
- `--import` sin errores. Suite completa: `290 test cases | 0 errors | 3 failures | 0 orphans`; sin `ObjectDB instances were leaked` ni `resources still in use`. Los 3 fallos son de `tests/unit/state/flags_owners_test.gd` (EB-006, otro agente: `range` `[1.0, 4.0]` vs `[1, 4]`), no de esta historia.
- Cambios: `src/core/game_state.gd` (almacén `Array` + `Dictionary` de índices, `resolve_fact`, `get_fact_at`, `set_error_policy`, ErrorPolicy inyectable); `tests/unit/state/flags_catalog_load_test.gd` (aserción `get_fact(&"nope") is_null` sustituida: ahora una lectura no declarada es fallo CA-27).
- Sin asignaciones en `get_fact_at`: revisión de código (un chequeo de límites + un índice de `Array`).
