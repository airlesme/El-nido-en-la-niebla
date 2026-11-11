# Story 011: Verificación contra la tabla §12 del slice

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation (tooling)
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 15–16 (comparación con el slice)
**Requirement**: `TR-content-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D8)
**ADR Decision Summary**: Las entradas `fuente: slice_§12` se comparan con la tabla §12 de `design/slice/slice-v0.3.md`: texto entre « », marcadores sustituidos, `[pausa]` → segmentos, fragmentos unidos con espacio; diferencias solo de espacios o saltos de línea no fallan.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: lee un `.md` del repositorio desde `tools/` (no se exporta).

**Control Manifest Rules (this layer)**:
- Required: F-R65
- Forbidden: copiar la tabla §12 a otro fichero (fuente única: el slice)
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`, scoped to M1:*

- [ ] **AC-15**: con los datos de M1 sin tocar, código 0; cambiar una letra de una línea `slice_§12` → ≠ 0 y nombra el ID; cambiar solo espacios/saltos → 0.
- [ ] **AC-16**: `VO_G_07` (`[pausa]`), `DOC_01` (fragmentos) y un texto con `{vera}` se comparan según la regla 16 y coinciden (fixtures si no están en los datos de M1).
- [ ] **AC-02 / AC-03**: el recuento de 28 entradas del §12 se ejecuta y, en M1, se registra **NOT ASSESSED** (faltan escenas 4–8 por alcance); la comprobación de mayúsculas exactas sí pasa para los IDs presentes.

---

## Implementation Notes

- Parser de la tabla §12 tolerante a la forma actual del slice; si el formato de la tabla no permite extraer el texto sin ambigüedad, no se adivina: se abre una pregunta a `narrative-director` y se marca la entrada como no comparable.

---

## Out of Scope

- Datos de escenas 4–8.

---

## Files

- `tools/data_check/slice_comparator.gd`
- `tests/unit/content/slice_comparator_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/slice_comparator_test.gd` — must exist and pass; salida del verificador archivada.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-009-m1-narrative-data.md`, `production/epics/contenido-y-datos/story-010-data-check-verifier-core.md`
- Unlocks: None
