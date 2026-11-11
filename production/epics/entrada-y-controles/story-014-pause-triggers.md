# Story 014: Disparadores de pausa (`pause_requested`)

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, reglas 7, 21 y 22 (pausa; pérdida de foco; desconexión del mando)
**Requirement**: `TR-input-008`, `TR-input-006` (no durante la carga)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D14) · ADR-0002 (O1/O2: 25 apila `menú` y pausa `GameClock`)
**ADR Decision Summary**: El router emite la señal directa `pause_requested(cause: PauseCause)` (`ACTION`, `FOCUS_LOST`, `PAD_LOST`), que `Shell` conecta a 25; nunca durante `carga_en_curso` (foco/mando se aplazan al final de la carga). `Esc` compartido `pausa`/`ui_atrás` produce un solo cierre.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `NOTIFICATION_APPLICATION_FOCUS_OUT` y desconexión de mando: NEEDS_MANUAL (S-0006, foco dual en 4.7).

**Control Manifest Rules (this layer)**:
- Required: F-R22 (orden de apertura de pausa en un mismo frame), F-R18 (`process_mode` explícito), F-R16
- Forbidden: que el router pause `GameClock` por sí mismo
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to M1 (menú de pausa = recorte 5; se prueba con un doble de 25):*

- [ ] **AC-07 (parte L)**: en cualquier contexto salvo carga, `pausa` emite `pause_requested(ACTION)`; con `menú` arriba, `pausa` o `atrás` lo cierran con un solo cierre por pulsación.
- [ ] **AC-E4**: con una transición bloqueante activa y el mando activo, desconectarlo emite `pause_requested(PAD_LOST)` en el acto; durante una carga, se aplaza.
- [ ] **AC-E11 / AC-E7 (I)**: perder el foco durante una carga abre la pausa al terminar, no antes; recuperar el foco con el menú abierto no lo cierra (sesión manual registrada, NEEDS_MANUAL).
- [ ] **AC-21 / AC-22 (I)**: pérdida de foco con `interactuar` mantenida → cancelación + `pause_requested(FOCUS_LOST)`; desconexión del mando activo → `PAD_LOST`; si no era el activo, nada (manual).

---

## Implementation Notes

- Firma de la señal y `PauseCause` de ADR-0006 D14 / § Key Interfaces. Conexión en `Shell` (no existe aún): en esta historia, un doble de 25 en el test de integración.
- Texto «Mando desconectado» es de 25 (fuera).

---

## Out of Scope

- Menú de pausa (GDD 25, recorte 5).

---

## Files

- `src/input/input_router.gd`, `src/input/engine_input_adapter.gd`
- `tests/integration/input/pause_triggers_test.gd`, `production/qa/evidence/input-pause-manual.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/input/pause_triggers_test.gd` OR playtest doc (las partes NEEDS_MANUAL en `production/qa/evidence/input-pause-manual.md`).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-005-safety-cap-and-loading-state.md`, `production/epics/entrada-y-controles/story-007-device-tracker-hysteresis.md`
- Unlocks: `production/epics/entrada-y-controles/story-015-boot-wiring-and-manual-session.md`
