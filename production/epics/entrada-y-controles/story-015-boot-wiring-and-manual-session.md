# Story 015: Composición en `Boot` y sesión manual teclado + mando

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M (≈ 1 día, confianza BAJA; la sesión manual depende de que existan escenas 1–3)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Acceptance Criteria AC-04 (parte I); hito M1 C-M1-6, C-M1-1, C-M1-9
**Requirement**: `TR-input-001`, `TR-input-002`, `TR-input-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (D2 paso 5, D3) · ADR-0006 (`setup(ctx)`; `contexts_port()` a 4 y 21)
**ADR Decision Summary**: `InputRouter.setup(ctx)` en el paso 5 del arranque carga `default_bindings.json`, se suscribe a los avisos de carga y `Boot` entrega `contexts_port()` a 4 y 21. La sesión manual con teclado y con mando recorre las escenas 1–3.
**ADR Version**: ADR-0009 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: aquí se cierran las comprobaciones NEEDS_MANUAL/NEEDS_WINDOWED de S-0006 y ADR-0011 (familia de mando, hot-plug, zona muerta real, foco, viewport lógico bajo `expand`).

**Control Manifest Rules (this layer)**:
- Required: F-R25, F-R26, F-R27
- Forbidden: suscripciones en `_init`/`_ready` del autoload
- Guardrail: 0 errores en consola (C-M1-9)

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md` y el hito, scoped to M1:*

- [ ] Tras `Boot.compose()`, `InputRouter` está listo con la pila [`menú`] o [`exploración`] según el arranque de M1 y `contexts_port()` entregado (test de integración).
- [ ] **AC-04 (parte I) / C-M1-6**: recorrido completo escenas 1–3 con teclado y con mando, sin combinaciones ni temporizadores de reacción; sesión registrada en `production/qa/evidence/input-m1-session.md`.
- [ ] Comprobaciones NEEDS_MANUAL de S-0006 registradas con PASS/FAIL (familia, hot-plug, zona muerta, foco, `LineEdit` por puntero).

---

## Implementation Notes

- Rellenar `InputRouter.setup(ctx)` (hoy TODO). La sesión manual se hace cuando existan carga-de-planta, jugador e interacción; la historia puede cerrarse en dos pasos (integración automática primero, sesión después) — anotarlo en la evidencia.

---

## Out of Scope

- Reasignación y ajustes (ADR-0007).

---

## Files

- `src/input/input_router.gd`, `src/core/boot/boot.gd`
- `tests/integration/input/boot_input_wiring_test.gd`, `production/qa/evidence/input-m1-session.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/input/boot_input_wiring_test.gd` OR playtest doc (`production/qa/evidence/input-m1-session.md`).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-010-gesture-recognizer.md`, `production/epics/entrada-y-controles/story-011-interact-short-long-verb.md`, `production/epics/entrada-y-controles/story-014-pause-triggers.md` (y transitivamente 001–013)
- Unlocks: None
