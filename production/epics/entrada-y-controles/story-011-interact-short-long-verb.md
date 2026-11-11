# Story 011: `interactuar` — verbo corto / largo y cancelación

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, regla 10 (verbo corto y largo); § Formulas F6; § Edge Cases
**Requirement**: `TR-input-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D6, D10; `set_target_long_verb`)
**ADR Decision Summary**: 7 informa con `set_target_long_verb(bool)` del objeto apuntado. Sin `verbo_largo`: verbo corto al pulsar. Con `verbo_largo`: decide al soltar (corto) o a `t_hold` (`leer`), con indicador de progreso; la pulsación se cancela al cambiar de contexto o perder el foco.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: ninguna adicional.

**Control Manifest Rules (this layer)**:
- Required: F-R44, F-R16 (`t_hold` en tiempo real), F-R42
- Forbidden: que 7 mida la duración de la pulsación
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-10 (parte L)**: sin `verbo_largo`, el corto se dispara al pulsar; con corto y largo, una pulsación de 0,18 s activa el corto al soltar; con solo `verbo_largo` (documento), 0,5 s lanza `leer` y antes de eso no ocurre nada al soltar (según el GDD); el progreso se expone para el prompt.
- [ ] **AC-E12**: `interactuar` mantenida sobre un documento en `exploración`; si el contexto cambia antes de 0,5 s, se cancela y no se lanza `leer`.
- [ ] **AC-21 (parte L)**: perder el foco con `interactuar` mantenida cancela sin `leer` (la apertura de la pausa es 014).

---

## Implementation Notes

- Firma (ADR-0006): `set_target_long_verb(has_long_verb: bool) -> void`. El progreso para 24 se expone en el `ActionEvent` o en un getter que fije ADR-0006 § Key Interfaces; si no hay getter firmado, *ADR-fallback*: no se inventa — la historia de 24 lo pide como enmienda de ADR-0006.
- Parte V de AC-10 (indicador visible) es del prompt (ADR-0016, Proposed).

---

## Out of Scope

- Indicador visual de progreso (24).

---

## Files

- `src/input/input_router.gd`
- `tests/unit/input/interact_verbs_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/interact_verbs_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`, `production/epics/entrada-y-controles/story-006-blocking-transitions-and-pocket-review.md`
- Unlocks: `production/epics/entrada-y-controles/story-015-boot-wiring-and-manual-session.md`
