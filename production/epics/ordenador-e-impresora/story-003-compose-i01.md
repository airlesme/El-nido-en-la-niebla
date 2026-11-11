# Story 003: `compose_i01()` pura con `ts_envio` entero

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

La hoja impresa I-01: 6 bloques en orden de presentación, 4 con referencia. Es la entrada de P1 y el
puzle la ordena por `ts_envio`, nunca analizando texto.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R20, R30; D19-16, D19-20)
**Requirement**: `TR-computer-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 D6 (registros de 18), D4 (enteros)
**ADR Decision Summary**: `compose_i01() -> SheetI01` síncrona y pura: sin estado ni escritura, `ts_envio` entero en minutos desde lunes 00:00 siempre presente.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: enteros como `int` (ADR-0005 D4)
- Forbidden: estado o escrituras en `compose_i01()`
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-16**: 6 bloques en orden de presentación con `ref` 3, null, 1, 4, null, 2, cada uno con `hora_envio` (resto según el GDD).
- [ ] **GDD 19 AC-31**: cada bloque lleva `ts_envio` = `índice_del_día · 1440 + hh · 60 + mm` de su registro.
- [ ] **GDD 19 AC-29**: estructura idéntica antes y después de cargar (aquí: antes y después de reiniciar el estado), exactamente 4 bloques con `ref`.
- [ ] **GDD 19 AC-30 / AC-17**: con `i01_hora_visible` o `i01_pie_ordena_visible` falso se reflejan en todos los bloques; ningún bloque contiene un literal de nombre o inicial vigente (regla 8 de 18).

---

## Implementation Notes

- La firma `compose_i01() -> SheetI01` la fija el GDD 19 / TR-computer-020. Los campos de `SheetI01` los fija el GDD (§ R20); si falta alguno en un ADR, se usan los nombres del GDD y se anota para `/architecture-review`.
- Ruta (fallback): `src/world/computer/sheet_i01.gd`.

---

## Out of Scope

- P1 que consume la hoja: `production/epics/puzles-marco-y-p1/story-008-material-vista-compose-i01.md`.

---

## Files

- `src/world/computer/sheet_i01.gd`
- `tests/unit/computer/compose_i01_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/computer/compose_i01_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `ContentDB` (`production/epics/contenido-y-datos/`)
- Unlocks: `production/epics/ordenador-e-impresora/story-004-impresora-v08-entrega-i01.md`, `production/epics/puzles-marco-y-p1/story-008-material-vista-compose-i01.md`
