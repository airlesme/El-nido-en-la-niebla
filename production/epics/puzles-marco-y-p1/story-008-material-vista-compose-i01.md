# Story 008: Material de la vista — `elements()`, `compose_i01()` y sin `I-01`

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

La hoja impresa (I-01) es la entrada de P1. Al abrir `C05`, 9 pide a 19 la hoja con `compose_i01()`
y monta las 4 referencias; sin la hoja, la vista existe pero no ofrece material.

**GDD**: `design/gdd/puzle-1-cronologia.md` (R7, R17, R19, R27, R40, R41) · `design/gdd/marco-de-puzles.md` (S6, R34)
**Requirement**: `TR-puzzle1-002`, `TR-puzzle1-008`, `TR-puzzle1-009`, `TR-puzzle1-014` (parte cierre/reapertura, `KEEP`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D15 (`missing_items`), D2 (`on_open`, `elements`); ADR-0011 (`ViewReceiver`, `ViewElement`); ADR-0001 (`has_item`, sin escrituras)
**ADR Decision Summary**: el marco calcula `missing_items` y llama `on_open()`; 19 aporta los bloques y las refs vía `compose_i01()`, el marco crea `C05/paper/ref_N` (exactamente 4) y el controlador declara `C05/slot_1..4`.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0011 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna API post-corte propia.

**Control Manifest Rules (this layer)**:
- Required: FE-R12, FE-R18
- Forbidden: FE-X05
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-2**: con `I-01`, al abrir `C05` el marco llama una vez a `compose_i01()`; `elements()` tiene 4 `C05/paper/ref_N` y 4 `C05/slot_k`; la hoja muestra 6 bloques en orden `3,1,4,2` con los dos de ruido sin referencia; cerrar y reabrir da un resultado idéntico.
- [ ] **GDD 11 AC-3**: ordenar los bloques con `ref` por el entero `ts_envio` ascendente da `[2,1,3,4]` = `solution.sequence` (prueba de CI, TR-puzzle1-002).
- [ ] **GDD 11 AC-5 / AC-21**: sin `I-01` (o con un doble que devuelve 3 o 5 refs → error de datos) la vista abre con 4 huecos vacíos y 0 referencias, `SFX_CLICK_SUBTLE` al pulsar un hueco, ningún hecho escrito, `atrás` cierra.
- [ ] **GDD 11 AC-20**: dos huecos llenos sobreviven a cerrar y reabrir; `en_mano = ninguna`; la hoja se reconstruye con `compose_i01()`.

---

## Implementation Notes

- `compose_i01()` lo implementa la story `production/epics/ordenador-e-impresora/story-003-compose-i01.md`; aquí se consume. Hasta entonces, doble con los datos de 18.
- La parte «al cargar partida se pierden las colocaciones» de TR-puzzle1-014 está **Diferida** (ADR-0004).

---

## Out of Scope

- Story 009: geometría y zonas.
- Story 010: aspecto.

---

## Files

- `src/puzzles/p1_cronologia/puzzle1_controller.gd` (`elements()`, `on_open`)
- `src/puzzles/framework/puzzle_framework.gd` (`missing_items`, `ref_N`)
- `tests/integration/puzzle_1/p1_material_test.gd`, `tests/unit/puzzle_1/p1_solution_matches_i01_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/puzzle_1/p1_material_test.gd` y la prueba de CI de AC-3 — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-003-puzzle1-controller-r13.md`, `production/epics/puzles-marco-y-p1/story-004-estados-configuracion-y-vista.md`, `production/epics/ordenador-e-impresora/story-003-compose-i01.md`; `has_item` (`production/epics/documentos-y-bolsillo/`)
- Unlocks: `production/epics/puzles-marco-y-p1/story-010-panel-p1-gris-captura.md`, `production/epics/puzles-marco-y-p1/story-012-oraculo-y-fallo-x5.md`
