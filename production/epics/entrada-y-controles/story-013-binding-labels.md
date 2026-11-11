# Story 013: `get_binding_label` y familia de mando

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, regla 24 (etiquetas de asignación; contrato con 24)
**Requirement**: `TR-input-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D13)
**ADR Decision Summary**: Consulta pura y determinista: resuelve acciones derivadas a su base (`leer` → `interactuar`, `repasar_bolsillo` → `atrás`, `agarrar`/`rotar`/`mantener` → `seleccionar`); `dispositivo = -1` es el activo; devuelve `{tipo, texto, glifo_id}` o `{}` y la primera asignación por orden de alta.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: cadenas de familia de mando (SDL3): NEEDS_MANUAL (S-0006-B); con un nombre desconocido, familia genérica.

**Control Manifest Rules (this layer)**:
- Required: F-R47 (`get_binding_label` sin efectos laterales), F-R42
- Forbidden: texto de etiqueta en código (sale de datos)
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`:*

- [ ] **AC-E19**: con los valores por defecto, `get_binding_label(interactuar, teclado/ratón)` = `{tipo: tecla, texto: E}`; `get_binding_label(atrás, teclado/ratón)` = `{tipo: boton_raton, texto: Clic der.}`; y el resto de casos de AC-E19 del GDD (mando, derivadas, acción desconocida).
- [ ] Dos llamadas seguidas devuelven lo mismo y no cambian estado (`bindings_revision()` igual).

---

## Implementation Notes

- Firmas (ADR-0006): `get_binding_label(accion, dispositivo := -1) -> Dictionary`, `pad_family() -> InputTypes.PadFamily`, `bindings_revision() -> int`.
- `glifo_id` se devuelve como ID; el atlas que lo dibuja es ADR-0016 (Proposed).

---

## Out of Scope

- Atlas de glifos y prompt (24, ADR-0016).

---

## Files

- `src/input/input_router.gd`, `src/input/binding_table.gd`
- `tests/unit/input/binding_labels_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/binding_labels_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-001-input-types-and-binding-table.md`, `production/epics/entrada-y-controles/story-007-device-tracker-hysteresis.md`
- Unlocks: None (lo consume interaccion-y-prompt)
