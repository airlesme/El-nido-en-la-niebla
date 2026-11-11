# Story 004: `FocusSelector` — agrupación, desempate, retención y disponibilidad

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Formulas › F1 (pasos 3–5); § Core Rules, reglas 3, 7, 8
**Requirement**: `TR-interact-005`, `TR-interact-006`, `TR-interact-007` (contrato `can_interact`/`etiqueta`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D3.6, D5, D6 contrato de manejador, G-5); ADR-0001 (lectura directa de hechos por índice)
**ADR Decision Summary**: `FocusSelector` puro: `G = {c : d_c ≤ d_min + desempate_prof_m}`, orden `(not contains_axis, −prioridad, δ, id)`; retención `N_gracia = floori(t_gracia_foco_s · physics_hz + 0,5)` = 7 pasos con `δ_target ≤ radio_pegajoso_m`; `habilitado_si` por lectura directa y `can_interact` solo para supervivientes y el objetivo retenido.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (puro GDScript)
**Engine Notes**: `physics_hz` se lee una vez en `configurar()` de la opción de física del motor; las pruebas lo inyectan.

**Control Manifest Rules (this layer)**:
- Required: FE-R06 (`can_interact` ≤ 1 vez por entrada y paso, sin efectos laterales), F-R05 (hechos solo por `GameState` inyectado).
- Forbidden: suscribirse a hechos para `habilitado_si` (lectura directa, TR-interact-006).
- Guardrail: FE-G01.

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-04 / AC-04b**: `B02` (prio 1) a 1,10 m y `B05` (prio 2) a 1,12 m con el eje dentro de ambos → `B05`; `B05` a 1,20 m → `B02`; eje dentro de `B02` y `B05` solo tocada por la esfera → `B02`; eje fuera de ambos → `B05`; empate total → ID menor con independencia del orden de carga.
- [ ] **AC-05**: perdido 7 pasos y vuelve → `get_target()` no cambia; perdido 8 pasos dentro de `radio_pegajoso_m` → nulo en el 8.º; rayo a más de `radio_pegajoso_m` → nulo de inmediato (la cláusula que el GDD marca «BLOQUEADA hasta el ADR de V1» queda **desbloqueada**: ADR-0011 D3/D5 cierra V1 con `δ_target`); un candidato nuevo sustituye en el mismo paso; sin aviso de pérdida.
- [ ] **AC-06 / AC-06b**: `habilitado_si = {todos:[caja_c1]}` con `caja_c1` falso → no objetivo; verdadero → objetivo al paso siguiente; `can_interact = NO` → no objetivo; `SIN_EFECTO` → objetivo; `etiqueta()` con clave distinta → `get_target()` la entrega; `etiqueta()` nula → etiqueta del catálogo (AC-38b).
- [ ] **AC-X2b**: rayo oscilando ±0,6° a 8 Hz sobre `A04` durante 0,6 s → `get_target()` es `A04` en todos los pasos.

---

## Implementation Notes

*Derived from ADR-0011 D5/D6:*

- Orden lexicográfico con `id` comparado como `String`. El retenido se recomprueba con `habilitado_si` y `can_interact`; `NO` o deshabilitado → perdido en el mismo paso, sin gracia.
- `steps_since_lost` cuenta pasos de física ejecutados (ninguno en pausa).
- Puerto del manejador definido en el lado de 7 (`InteractionHandler`, `@abstract RefCounted`, F-R33): `can_interact(verbo) -> InteractResult {SI, NO, SIN_EFECTO}`, `etiqueta(verbo) -> StringName` (`&""` = catálogo), `interact(verbo, contexto) -> InteractOutcome {HECHO, SIN_EFECTO}`. `registrar_manejador(id, handler)`; un pick sin manejador en «escena lista» = error de desarrollo.
- Cada cambio de objetivo llama `InputRouter.set_target_long_verb(has_largo)` (ADR-0006, firma `set_target_long_verb(has_long_verb: bool)`) en el mismo paso — se integra en 005.

---

## Out of Scope

- Story 005: el nodo y el paso de física. Story 006/007: pulsación.

---

## Files

- `src/interaction/focus_selector.gd`, `src/interaction/ports/interaction_handler.gd`, `src/interaction/interaction_types.gd`
- `tests/unit/interaction/focus_selector_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/focus_selector_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-002-pick-registry-y-pickmath.md`, `production/epics/interaccion-y-prompt/story-003-capas-y-oclusion.md`; épico estado-y-bus (`GameState.resolve_fact`/lectura por índice)
- Unlocks: `production/epics/interaccion-y-prompt/story-005-interaction-system-barrido.md`
