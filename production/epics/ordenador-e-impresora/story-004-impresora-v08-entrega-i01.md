# Story 004: Impresora `V08` — máquina de estados 1,5 s y entrega de `I-01`

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Dos entradas (botón «Imprimir» y verbo de `V08`) y una sola máquina de estados. El trabajo enviado
no se cancela; al terminar entrega la hoja I-01 al bolsillo (20) si no la tiene.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R21–R25)
**Requirement**: `TR-computer-016`, `TR-computer-017`, `TR-computer-018`, `TR-computer-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (verbo de `V08`, contexto); ADR-0005 (datos `t_impresion`); ADR-0002 (temporizador en tiempo de juego)
**ADR Decision Summary**: `sin_resultados → lista ⇄ imprimiendo` (1,5 s); botón habilitado ⇔ `correos_leidos` ∧ `V08 ≠ imprimiendo`; `otorgar_sesion("I-01")` idempotente solo si `has_item('I-01')` es falso.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0005 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0006)
**Engine Notes**: ninguna API propia; el riesgo HIGH es de ADR-0006 (foco dual), no de esta máquina.

**Control Manifest Rules (this layer)**:
- Required: tiempo por `GameClock`; FE-R07 (un `interaction_executed` por pulsación)
- Forbidden: F-X10
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-12**: cada fila de la tabla R22 da su resultado (`sin_resultados` → `SIN_EFECTO` y `OBJ_V08_SIN_RESULTADOS`; `lista` sin hoja → `imprimiendo` 1,5 s y entrega; resto según el GDD).
- [ ] **GDD 19 AC-08**: con un trabajo enviado, cerrar el ordenador no lo cancela: `V08` termina e `hoja_en_bandeja` es verdadero.
- [ ] **GDD 19 AC-13**: sin `I-01`, al completar se llama una vez a `otorgar_sesion("I-01")` y `has_item('I-01')` es verdadero; si ya la tiene, no se vuelve a llamar.

---

## Implementation Notes

- `otorgar_sesion` y `has_item` son de 20 (épico `documentos-y-bolsillo`); usar sus firmas, no redefinirlas.
- «Nace en `lista` tras cargar» (TR-computer-016, AC-14/15) → **Diferido** (ADR-0004).

---

## Out of Scope

- Story 009: captura de la impresión.

---

## Files

- `src/world/computer/printer_v08.gd` (fallback de ruta)
- `tests/integration/computer/printer_v08_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/computer/printer_v08_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ordenador-e-impresora/story-002-latencia-lista-correos-leidos.md`, `production/epics/ordenador-e-impresora/story-003-compose-i01.md`; 20 (`production/epics/documentos-y-bolsillo/`)
- Unlocks: `production/epics/ordenador-e-impresora/story-009-overlay-gris-capturas.md`
