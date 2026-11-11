# Story 006: `PressInterpreter` — corta/larga, enfriamiento y anillo `p`

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 9, 10, 28; § Formulas › F2
**Requirement**: `TR-interact-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D6 `PressInterpreter`, D10); ADR-0006 (D6 `bind_sink`, D10 `LONG` en `RealClock`, cancelación)
**ADR Decision Summary**: `PressInterpreter` puro convierte `PRESSED`/`TAP`/`LONG`/`CANCELLED` del router en a lo sumo un verbo, aplica `t_enfriamiento_s` por objeto; la autoridad de la pulsación larga es el router; el `p` del anillo (F2) es presentación en `GameClock`, con `clamp` a 1 hasta `LONG` o suelta.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (puro)
**Engine Notes**: ninguno propio; `interactuar` llega por `bind_sink(ctx: InputTypes.Context, action: StringName, sink: Callable)` (ADR-0006).

**Control Manifest Rules (this layer)**:
- Required: FE-R05; ADR-0002 G-1 (tiempo de juego por `GameClock` inyectado).
- Forbidden: `Timer`/`create_timer` para `t_hold`/enfriamiento (ADR-0002 G-3).
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-08 / AC-09**: objeto solo con `verbo_corto` → se dispara en el fotograma de la pulsación; con corto y largo y `t_hold` 0,5: 0,18 s y suelta → corto al soltar; 0,62 s → `leer` a 0,50 s y la suelta no dispara nada (AC-09 consultivo).
- [ ] **AC-10 / AC-36c**: 0,30 s mantenidos → `p = 0,6` y anillo visible; 0,10 s → no visible (antes de `t_anillo_inicio_s`); `largo` falso en un objeto solo corto; en modo alternar entre pulsaciones sigue visible.
- [ ] **AC-11 / AC-12**: toque corto sobre un objeto solo `leer` (`B05`/`A04`) no abre lectura (resultado `TOQUE_CORTO`); en enfriamiento de 0,25 s, una pulsación a 0,10 s se descarta y a 0,30 s se procesa.
- [ ] **AC-16 / AC-35c**: una pulsación prolongada en curso se cancela con `pausa` sin disparar `leer`; en modo alternar, `atrás` antes de la segunda pulsación cancela el anillo sin abrir.

---

## Implementation Notes

*Derived from ADR-0011 D6/D10:*

- Entrada: eventos del router; salida: `{verbo | ninguno, resultado_previsto}`. Sin reloj propio: recibe `GameClock` para `p` y el enfriamiento.
- `p = clamp((t − t_pulsado)/t_hold, 0, 1)` con `t_hold` leído de Entrada (no duplicado).
- Cancelación por `MENU`/pausa: anillo apagado, sin verbo y **sin** `interaction_executed`.

---

## Out of Scope

- Story 007: lo que ocurre con el verbo (gesto, `interact()`, aviso).

---

## Files

- `src/interaction/press_interpreter.gd`
- `tests/unit/interaction/press_interpreter_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/press_interpreter_test.gd` — must exist and pass (reloj falso).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-005-interaction-system-barrido.md`; épico `entrada-y-controles` (eventos `PRESSED`/`TAP`/`LONG`/`CANCELLED`)
- Unlocks: `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md`
