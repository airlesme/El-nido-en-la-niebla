# Story 009: Geometría de `p1_view.json` y zonas de atracción

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S — 0,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

La geometría de la vista es dato, no código. La prueba comprueba tamaños mínimos y la excepción de
atracción: las referencias no atraen el cursor del mando, los huecos sí.

**GDD**: `design/gdd/puzle-1-cronologia.md` (R14, F6, D11-17)
**Requirement**: `TR-puzzle1-010`, `TR-puzzle1-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D10 (atracción y excepción de P1); ADR-0011 (`ViewElement`, picking 2D); ADR-0005 (esquema del fichero)
**ADR Decision Summary**: `element_zones` con `ids: ["C05/paper/ref_*"]` y `atraccion_desactivada: true`; el override de zona gana a la regla 9 del GDD 9 (contradicción C1).
**ADR Version**: ADR-0010 2026-11-10 · ADR-0011 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: FE-R08 (`ViewMetrics` única conversión px ↔ m)
- Forbidden: FE-X03 (no codificar 1080/1920 en código: los valores viven en el JSON)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 11 AC-18**: todos los elementos ≥ 44 px; separación entre centros de `ref_N` ≥ 128 px y de `slot_k` ≥ 128 px (por defecto 150 y 200); `ref_N` declara `atraccion_desactivada` = verdadero y `slot_k` no.
- [ ] **ADR-0010 T-U13**: `element_zones_test.gd` — P1 `ref_*` atracción falsa, huecos verdadera.

---

## Implementation Notes

- Valores de TR-puzzle1-010: viewport lógico 1920×1080, hoja 1000×960, `ref_N` 112×56 paso ≥ 150, `slot_k` 160×160 paso 200, R = 64 px.
- El escalado a otras resoluciones **no** es de esta historia (ADR-0007, Diferido).

---

## Out of Scope

- Story 010: presentación y captura.

---

## Files

- `assets/data/puzzles/p1_view.json`
- `tests/unit/puzzles/element_zones_test.gd`, `tests/unit/puzzle_1/p1_view_geometry_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: los tests de Files — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-001-puzzles-json-v2-p1.md`
- Unlocks: `production/epics/puzles-marco-y-p1/story-010-panel-p1-gris-captura.md`
