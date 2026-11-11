# Story 007: Lecturas O(1) — `get_fact`, `resolve_fact`, `get_fact_at`, valor neutro

> **Epic**: Estado y bus de eventos
> **Status**: Ready
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

- [ ] **CA-02 (lectura)**: un hecho sin tocar devuelve su inicial (bool/int/`StringName`, `&""` = sin fijar).
- [ ] **CA-27**: en release y «Sin cargar», o con un hecho no declarado en «Listo», la lectura devuelve el neutro (`false`, `0`, `&""`; no declarado → `false`) y añade una línea de log; en dev llama a `ErrorPolicy.fail`.
- [ ] `resolve_fact(&"no_existe") == -1`; `get_fact_at(resolve_fact(x)) == get_fact(x)` para los 20 hechos; `is_declared` distingue mayúsculas (`Tarjeta_B` no existe).

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
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`
- Unlocks: `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`
