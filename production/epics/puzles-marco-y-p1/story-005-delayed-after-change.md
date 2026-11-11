# Story 005: Política `DELAYED_AFTER_CHANGE` 0,6 s y cancelación con `GameClock`

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA: `GameClock` del esqueleto no expone aún `deadline`/`is_due`/`schedule`)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

P1 se comprueba 0,6 s después del último cambio con los cuatro huecos llenos. La cuenta vive en
tiempo de juego (se para con la pausa) y se rearma con cada pulsación.

**GDD**: `design/gdd/marco-de-puzles.md` (regla 12, F1) · `design/gdd/puzle-1-cronologia.md` (R12, R20, R21, F5)
**Requirement**: `TR-puzzles-010` (parte `DELAYED_AFTER_CHANGE`), `TR-puzzles-014`, `TR-puzzle1-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D4 (políticas como estrategia), D6 (`GameClock` inyectado, `PuzzleTimers`), D7 (cancelación); ADR-0002 D1, D6 (único reloj, prohibición de temporizadores)
**ADR Decision Summary**: cada política es un objeto estrategia; `DelayedAfterChange` arma un plazo en `PuzzleTimers` sobre el `GameClock` inyectado; la cancelación (cierre, `atrás`, foco, pausa) devuelve la pieza en mano sin evaluar.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0002: HIGH por `SceneTree.paused`; aquí no se usa)
**Engine Notes**: los tests usan un `GameClock` real avanzado con `advance()` y `NullPauseBackend` (ADR-0010 § Validation Criteria) — es el «reloj falso».

**Control Manifest Rules (this layer)**:
- Required: FE-R15 (todo tiempo del marco por `PuzzleTimers`/`GameClock`)
- Forbidden: FE-X06 / F-X10 (`Timer`, `create_timer`, `await` sobre temporizadores del árbol en `src/puzzles/`; lo vigila `tools/ci/forbid_timers.sh`)
- Guardrail: FE-G02

---

## Acceptance Criteria

- [ ] **GDD 11 AC-6 / GDD 9 AC-06**: huecos llenos en t = 10,00, selección en 10,40 y colocación en 10,80 → no se evalúa en 10,60 ni en 11,00; salir de la vista en 10,70 cancela.
- [ ] **GDD 11 AC-7**: con una referencia en mano a 0,35 s, a 0,95 s `evaluate()` = `NONE` sin rechazo; al colocarla a 1,20 s, nueva evaluación a 1,80 s.
- [ ] **GDD 11 AC-9 / GDD 9 AC-45 (parte P1)**: `cancelación` con referencia en mano → `en_mano = ninguna`, sin `REJECT`, sin sonido, sin evaluar; con cuatro huecos llenos y la vista abierta la cuenta se rearma a 0,6 s.

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines 3, 4, 5:*

- Rutas fijadas: `src/puzzles/framework/policies/validation_policy.gd`, `src/puzzles/framework/puzzle_timers.gd`.
- `delay_s` (0,6; rango 0,3–1,5) es dato de `puzzles.json`.
- **Tarea con ADR-fallback:** si el esqueleto `src/core/game_clock.gd` sigue sin `deadline(after_s)`, `is_due(deadline_s)`, `schedule(after_s, callback)` y `cancel(handle)`, se añaden con las firmas exactas de ADR-0002 § Key Interfaces (l. 527–544) dentro del épico `estado-y-bus`, no aquí. Esta historia no inventa otra API de tiempo.

---

## Out of Scope

- Story 006: qué pasa tras un `REJECT`.
- Story 007: qué pasa tras un `SOLVED`.

---

## Files

- `src/puzzles/framework/policies/validation_policy.gd` (+ `DelayedAfterChange`)
- `src/puzzles/framework/puzzle_timers.gd`
- `tests/unit/puzzles/policies/delayed_after_change_test.gd`, `tests/unit/puzzle_1/p1_timing_f5_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: los dos tests de Files con `GameClock` falso — must exist and pass. Sin aserciones dependientes del tiempo real.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-003-puzzle1-controller-r13.md`, `production/epics/puzles-marco-y-p1/story-004-estados-configuracion-y-vista.md`; `GameClock` completo (épico `production/epics/estado-y-bus/`)
- Unlocks: `production/epics/puzles-marco-y-p1/story-006-rechazo-uniforme.md`, `production/epics/puzles-marco-y-p1/story-007-resolucion-immediate.md`
