# Story 006: Datos `assets/data/state/flags.json` (20 hechos, dueños)

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Interactions with Other Systems (columna «Escribe»); `design/slice/slice-v0.3.md` § Anexo D.2 Banderas (fuente de los 20 hechos e iniciales)
**Requirement**: `TR-state-001`, `TR-state-006` (reversibles: `pos_L/C/R` int 1–4 inicial 2, `pendiente_revelacion`), `TR-state-007` (derivado `caja_completa`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (D1, D2: forma del fichero) · ADR-0001 (D7: `owner` = número de sistema; G-9)
**ADR Decision Summary**: Un fichero UTF-8 sin BOM, LF, JSON estricto, `schema_version: 1`, `max_chained_notices: 64`, exactamente 20 hechos con `owner` numérico (9, 19, 20, 22, 3).
**ADR Version**: ADR-0005 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (solo datos)
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R56 (UTF-8 sin BOM, LF, sin comentarios ni comas finales), F-R51, F-R10, F-R67 (export incluye `assets/data/*`)
- Forbidden: valores de juego en código
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-30**: el `owner` de cada uno de los 20 hechos coincide con la columna «Escribe» de § Interactions with Other Systems (`caja_completa` → 3). Test unitario que carga el fichero real.
- [ ] **C-M1-4 (parte de datos)**: `correos_leidos` (19), `archivo_abierto` (9), `formulario_leido`, `tarjeta_B`, `tarjeta_D` (20) existen con ese `owner`.
- [ ] El fichero carga sin issues con el esquema de 005 (smoke).

---

## Implementation Notes

- Transcribir los 20 hechos **solo** del Anexo D.2 del slice (incluido `t4_decision` `returned`/`assigned`) y la tabla del GDD 3; no inventar nombres. Si las dos fuentes difieren, prevalece el slice (CLAUDE.md) y se anota la discrepancia para `/propagate-design-change`.
- `max_chained_notices: 64` (ADR-0001 D5).

---

## Out of Scope

- Escritores reales de cada hecho (épicos 19, 9, 20).

---

## Files

- `assets/data/state/flags.json`
- `tests/unit/state/flags_owners_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`); además `tests/unit/state/flags_owners_test.gd` (CA-30, L en el GDD) must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md`
- Unlocks: `production/epics/estado-y-bus/story-015-m1-state-test.md`
