# Story 005: Tope de seguridad con `GameClock`, `carga_en_curso` y reinicio de pila

> **Epic**: Entrada y controles
> **Status**: Done (2026-11-12)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, reglas 8–9 (tope de contextos bloqueantes; carga en curso); § Formulas F8; § Edge Cases
**Requirement**: `TR-input-005`, `TR-input-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D4, D14) · ADR-0002 (`GameClock.deadline()`/`is_due()`) · ADR-0003 (avisos de carga; `reset_stack_on_unload`) · ADR-0001
**ADR Decision Summary**: El tope de `sin control` = duración declarada + margen 2 s (3 s en transiciones de cámara), medido con el `GameClock` inyectado (no avanza en pausa) y renovado al traspasar. `carga_en_curso` se deriva de `scene_load_started`/`_finished`/`_failed` y bloquea la pausa; sin esos avisos nunca bloquea. Al descargar la escena, la pila queda [`sin control`] con el mismo dueño, duración y cuenta.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0002 2026-11-10 · ADR-0003 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `GameClock.deadline(after_s) -> float` e `is_due(deadline_s) -> bool` están firmados en ADR-0002 pero **sin implementar** en `src/core/game_clock.gd` (TODO). *Tarea de esta historia si nadie los ha hecho antes:* implementarlos según ADR-0002 con su test en `tests/unit/core/game_clock_test.gd` (+0,5 d de riesgo).

**Control Manifest Rules (this layer)**:
- Required: F-R43 (`InputRouter` usa `GameClock` para los topes), F-R15/F-R17 (tiempo de juego inyectado; esperas por `deadline`), F-R16 (`RealClock` para lo que corre en pausa), F-R48
- Forbidden: `_process(delta)` o `Timer` propios para el tope
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story (con `FakeClock`):*

- [ ] **AC-F8**: `sin control`(4) con `D_carga = 11,67 s` y traspaso a 21 en t = 9 s con 20 s declarados: el dueño pasa a 21, sin aviso, el tope vence en t = 31 s (no a 13,67 s) y a 13,67 s sigue activo.
- [ ] **AC-E14**: entre «carga iniciada» y «carga fallida» `pausa` queda bloqueada y vuelve tras el segundo; una pausa pendiente por foco durante la carga se descarta.
- [ ] **AC-E13c / AC-E13d**: con «carga iniciada» por `partida_nueva` desde la pausa, Entrada descarta la pila entera según el GDD y queda [`sin control`(4)].
- [ ] **AC-E2 (parte L)**: al descargar con la pila fuera de `exploración` y `sin control`(4) vigente, la pila queda [`sin control`] con el mismo dueño, duración y cuenta de tope.

---

## Implementation Notes

- Firmas (ADR-0006): `reset_stack_on_unload() -> void`, `is_loading() -> bool`, `no_control_margin_s() -> float` (lo lee 21, ADR-0017 A3). Valores (3 s, 2 s †) de `default_bindings.json`/datos, no constantes.
- Suscripción a los avisos de carga por el `GameState` inyectado (`subscribe_notice`). Vencimiento del tope: comprobación en el `_process` del router con `is_due` (no temporizador propio).

---

## Out of Scope

- Story 014: apertura de la pausa; carga real (carga-de-planta).

---

## Files

- `src/input/input_router.gd`, `src/core/game_clock.gd` (si falta `deadline`/`is_due`)
- `tests/unit/input/safety_cap_and_loading_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/safety_cap_and_loading_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Evidencia

- Suite bloqueante (`-a res://tests -i res://tests/timing`): `Overall Summary: 651 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`; sin `ObjectDB instances were leaked` ni `resources still in use`; `--import` sin errores; `tools/ci/forbid_timers.sh`: clean.
- `tests/unit/input/safety_cap_and_loading_test.gd` (AC-F8, AC-E14, AC-E13c/d, AC-E2 L) y 3 tests nuevos de `deadline`/`is_due` en `tests/unit/core/game_clock_test.gd`.
- Cambios: `GameClock.deadline/is_due` (src/core), `ContextStack` (tope, carga, `reset_on_unload`, `gate_pause`), `InputRouter` (`_process` con `is_due`, suscripción a avisos de carga, `is_loading`, `no_control_margin_s`, `reset_stack_on_unload`), `InputContexts.reset_stack_on_unload`, dato `no_duration_cap_s` en `default_bindings.json` + esquema.
- Notas: AC-E13c: el descarte lo dispara un `sin control` ajeno + `absorbs_foreign` (ADR-0006 D4, EC-004); sin él se apila. Disparar la pausa pendiente tras «terminada» queda en la historia 014 (`take_pending_pause`). Una pila reducida a [`sin control`] cuyo tope caduca repone `exploración`. El `SCRIPT ERROR ... nonexistent_method` de la salida es preexistente (no es de esta historia).

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-004-no-control-operations.md`
- Unlocks: `production/epics/entrada-y-controles/story-006-blocking-transitions-and-pocket-review.md`, `production/epics/entrada-y-controles/story-014-pause-triggers.md`
