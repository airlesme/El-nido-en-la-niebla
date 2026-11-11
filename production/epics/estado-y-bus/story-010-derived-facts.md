# Story 010: Hechos derivados (`caja_completa`)

> **Epic**: Estado y bus de eventos
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, regla 7 (derivados)
**Requirement**: `TR-state-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (§ Drain and Write Algorithms, § Invariants)
**ADR Decision Summary**: El derivado se declara en datos (`derive`), se recalcula tras cada cambio de una entrada y su aviso se encola después del de la entrada; escribirlo directamente es inválido.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R01 (orden FIFO), F-R05
- Forbidden: lógica de derivación codificada para un hecho concreto
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`:*

- [ ] **CA-07**: con `caja_c1`–`caja_c3` verdaderos y `caja_c4` falso, escribir `caja_c4` verdadero pone `caja_completa` a verdadero; escribir `caja_completa` directamente se rechaza.
- [ ] **CA-14**: el aviso de `caja_c4` llega antes que el de `caja_completa`.

---

## Implementation Notes

- Interpretar el `derive` que valida 005 (conjunción en el slice). Índice inverso entrada → derivados construido al cargar.
- `caja_c*` no se escriben en M1 (caja fuera de alcance), pero el derivado está en el catálogo de 20 y lo exige el test de catálogo.

---

## Out of Scope

- Escritores de `caja_c*` (puzles 2–6, fuera de M1).

---

## Files

- `src/core/game_state.gd`
- `tests/unit/state/derived_facts_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/derived_facts_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-008-validated-writes-and-writer.md`
- Unlocks: `production/epics/estado-y-bus/story-013-dev-console-hook.md`, `production/epics/estado-y-bus/story-015-m1-state-test.md`
