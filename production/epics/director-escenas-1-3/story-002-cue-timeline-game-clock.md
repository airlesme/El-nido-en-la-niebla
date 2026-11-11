# Story 002: `CueTimeline` — `t_rel` sobre `GameClock`, órdenes vencidas y pausa

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Primitiva de secuenciación: una ejecución sondeada y cancelable por escena activa. `t_rel` es
`now − origen`, nunca un acumulador; las órdenes vencidas en el mismo fotograma salen todas, en orden.

**GDD**: `design/gdd/director-de-escenas.md` (F1, regla 7)
**Requirement**: `TR-director-005`, `TR-director-027` (reloj de test)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D2 (`CueTimeline`, `CueRun`, cancelar soltando); ADR-0002 D1, D6
**ADR Decision Summary**: una `CueRun` por escena sobre `GameClock.now()`; vale 0 con pausa, sin foco o sin mando; cancelar = soltar la ejecución, sin emitir nada.
**ADR Version**: ADR-0017 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0017)
**Engine Notes**: V1 parse check en 4.7.2 de las clases de § Key Interfaces; V2 (orden de `_process` entre `GameClock` y `SceneDirector`) NOT SOURCEABLE: el test fija la tolerancia de ±1 fotograma en vez de depender del orden.

**Control Manifest Rules (this layer)**:
- Required: FE-R21 (tiempo solo de `GameClock`: `now`, `deadline`, `is_due`)
- Forbidden: FE-X08 (`Timer`, `create_timer`, `GameClock.schedule()`, `await` sobre tiempo), FE-X09 (`AnimationPlayer`/`Tween` como línea de tiempo)
- Guardrail: FE-G03 (≤ 3 ejecuciones vivas + una cadena por fotograma)

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-03**: con `ESC1_LLEGADA` armada, si `t_rel` pasa de 5,9 a 6,4 en un fotograma, `MEGA_01` sale en él y los pulsos de `V02` (12,0 s) no; con la pausa abierta `t_rel` no avanza.
- [ ] **TR-director-005**: varias órdenes vencidas en un mismo fotograma salen todas, en orden de datos.
- [ ] **TR-director-027 (parte)**: tests con `GameClock` real avanzado con `advance()` y `NullPauseBackend` (reloj falso), avance manual de fotogramas a 1/60.

---

## Implementation Notes

- Rutas fijadas por ADR-0017: `src/director/timeline/cue.gd`, `cue_run.gd`, `scene_record.gd`, `clock_source.gd`.
- Si `GameClock` sigue sin `deadline`/`is_due` en el esqueleto, se añaden en `estado-y-bus` con las firmas de ADR-0002 § Key Interfaces (l. 527–530).

---

## Out of Scope

- Story 003: cancelación por avisos de carga.
- Story 005: contenido de `ESC1_LLEGADA`.

---

## Files

- `src/director/timeline/cue.gd`, `cue_run.gd`, `scene_record.gd`, `clock_source.gd`
- `tests/unit/director_de_escenas/cue_timeline_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/director_de_escenas/cue_timeline_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `GameClock` completo (`production/epics/estado-y-bus/`)
- Unlocks: `production/epics/director-escenas-1-3/story-003-ciclo-de-vida-cancelacion.md`, `production/epics/director-escenas-1-3/story-005-esc1-tiempos-c1.md`, `production/epics/director-escenas-1-3/story-007-esc3-vo-v-04-lluvia.md`
