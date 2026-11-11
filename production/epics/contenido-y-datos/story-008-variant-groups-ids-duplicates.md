# Story 008: Grupos de variantes, IDs retirados y duplicados entre ficheros

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 3–5 (identificadores estables, inactivos, grupos de variantes); § Edge Cases (duplicados)
**Requirement**: `TR-content-003`, `TR-content-004`, `TR-content-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D9 Stable-ID policy; D6 `variant_id`, `group_suffixes`)
**ADR Decision Summary**: Los IDs son sensibles a mayúsculas, nunca se borran ni reutilizan (se retiran con `"status": "retired"` → «no encontrado»). Los grupos se declaran en datos (prefijo + sufijos, incluidos de varias letras) y el consumidor construye el ID con `variant_id(prefix, suffix)`. Duplicado entre ficheros: dev detiene; release gana el primero con log.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R63 (IDs de variante con `ContentDB.variant_id`), F-R64 (IDs retirados, nunca borrados)
- Forbidden: concatenar prefijo + sufijo en el consumidor
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`, scoped to this story:*

- [ ] **AC-04 (parte L)**: un identificador retirado se trata como «no encontrado».
- [ ] **AC-05 (parte L)**: con los grupos `CARTA_` (A–C), `VO_G_12` (A–C), `VO_G_13` (A–D), `VO_G_14` (`RET`, `ASG`), `VO_V_12` (A–D) en fixture, `variant_id(&"VO_G_12", "D") == &""` y `get_line(&"VO_G_12D").found == false`; `group_suffixes(&"VO_G_14")` = `RET`, `ASG`.
- [ ] **AC-E5 (parte L)**: dos registros con el mismo ID en ficheros distintos: en dev `ErrorPolicy.fail`; en release gana el primero cargado y se registra.

---

## Implementation Notes

- Firmas (ADR-0005): `variant_id(prefix: StringName, suffix: String) -> StringName`, `group_suffixes(prefix: StringName) -> PackedStringArray`.
- El fallo del verificador cuando falta una letra (AC-05 T) y el de duplicados (AC-E5 T) son de 010.

---

## Out of Scope

- Story 010: comprobaciones de nivel T.

---

## Files

- `src/narrative/content_db.gd`, `src/narrative/content_rules.gd`
- `tests/unit/content/variant_groups_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/variant_groups_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-004-content-db-load-and-lifecycle.md`
- Unlocks: `production/epics/contenido-y-datos/story-010-data-check-verifier-core.md`
