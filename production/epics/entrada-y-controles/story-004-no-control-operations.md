# Story 004: Operaciones de `sin control` y puerto `InputContexts`

> **Epic**: Entrada y controles
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, regla 8 (`sin control` con dueño y duración); § Edge Cases
**Requirement**: `TR-input-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D4) · ADR-0003 (contrato `InputContexts`, orden «emitir iniciada → abrir»)
**ADR Decision Summary**: Dueños `StringName`: `&"scene_loader"` (4), `&"scene_director"` (21), `&"input_router"` (solo respaldo). Abrir / cerrar (solo el dueño) / traspasar (sin salir ni avisar, renueva tope) / pedir `exploración` (dueño) / reponer `menú`; toda petición rechazada se registra y no emite. `InputContexts` es el puerto que `Boot` entrega a 4 y 21.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0003 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: ninguna API de motor (lógica pura).

**Control Manifest Rules (this layer)**:
- Required: F-R45 (solo 4 y 21 llaman a las operaciones de `sin control`), F-R33 (puertos `@abstract RefCounted`)
- Forbidden: emitir aviso en una operación rechazada o en un traspaso
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-E13**: con `sin control`(4) arriba, 21 pide abrir otro → rechazado y registrado; 21 traspasa → cambian dueño y duración sin salir/entrar, pila igual, sin aviso; un no-dueño que cierra → rechazado.
- [ ] **AC-E13b**: pila [`menú`, `sin control`(4)] desde el título con `control_final = ninguno`; 21 traspasa → [`menú`, `sin control`(21)] sin aviso; 21 pide `exploración` → [`exploración`] (sin `menú` debajo).
- [ ] **AC-08 (parte de pila)**: en `sin control`, `interactuar` no se dispara al terminar; `pausa` sí pasa (la apertura del menú es de 014).

---

## Implementation Notes

- Firmas (ADR-0006): `open_no_control(owner, declared_s, absorbs_foreign := false) -> bool`, `close_no_control(owner) -> bool`, `transfer_no_control(new_owner, declared_s) -> bool`, `request_exploration(owner) -> bool`, `restore_menu() -> void`, `contexts_port() -> InputContexts`.
- El tope (cap_deadline) y `reset_stack_on_unload` son de 005.

---

## Out of Scope

- Story 005: tope de seguridad, `carga_en_curso`, reinicio de pila.

---

## Files

- `src/input/input_router.gd`, `src/input/input_contexts.gd`
- `tests/unit/input/no_control_operations_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/no_control_operations_test.gd` — must exist and pass.
**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`
- Unlocks: `production/epics/entrada-y-controles/story-005-safety-cap-and-loading-state.md`

---

## Evidencia

- `tests/unit/input/no_control_operations_test.gd` (28 casos: AC-E13, AC-E13b, AC-08 parte de pila, descarte con `no_control_absorbed`, límites e inválidos, puerto). `-a res://tests/unit/input`: 106 casos, 0 fallos, 0 orphans, sin `ObjectDB instances were leaked` ni `resources still in use`.
- Suite bloqueante completa (2026-11-12): 528 casos, 1 fallo ajeno (`data_validator_test::test_registry_lists_m1_rows_in_fixed_order`, trabajo concurrente de CP-002; falla también suelto). La salida completa imprimió el aviso de fugas, ausente en las suites de input sueltas: atribuible a suites ajenas en curso.
- Implementación en `ContextStack` (puro) con delegación en `InputRouter`; puerto `src/input/input_contexts.gd`.
- Pendiente a 005 (marcado con `TODO(input-owner)`): renovar `cap_deadline`, `carga_en_curso`, pausa pendiente en `restore_menu`, `NO_DURATION_S` a datos.
