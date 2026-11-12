# Story 018: `RingState` — visibilidad, fundidos, relleno F1 y curva de pulso

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M — 1,5 días (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › A reglas 2–9; § Formulas F1; AC-24-01…05, 16, 20
**Requirement**: `TR-prompt-002`, `TR-prompt-003`, `TR-prompt-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 «Ring and label»: sondeo por fotograma, solo con `top() == EXPLORACION`, `360·p` horario desde las 12 h, 100 ms con `reducir_movimiento`, G-2 reloj de juego); ADR-0002 (`GameClock`, HUD `PAUSABLE`)
**ADR Decision Summary**: el anillo se dibuja solo con contexto `exploración` y objetivo ≠ nulo; se mantiene en el cambio directo de objeto (fundido cruzado 120 ms de etiqueta); el relleno es `360·p`; fundidos 250 in / 150 out (100 fijos con `reducir_movimiento`); la animación corre con `GameClock` inyectado (la pausa congela los fundidos), sin `Tween`/`Timer`.
**ADR Version**: ADR-0016 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura; el dibujo es 022)
**Engine Notes**: sin nodos ni `Tween`: `update(target, context_is_exploration, now_s)` avanza un estado de opacidad/relleno determinista; 022 solo lo pinta.

**Control Manifest Rules (this layer)**:
- Required: F-R18 (HUD `PAUSABLE`, reloj de juego), F-R07.
- Forbidden: F-X10 (`create_timer`), `Tween`/`Timer` en `src/ui/prompt/` (ADR-0016 G-2), recalcular objetivo, verbo o `p` (R1).
- Guardrail: sin asignaciones por fotograma (reutiliza un único objeto de estado; `get_target()` devuelve el mismo `Dictionary`, 005).

**Decisiones de usuario ya cerradas que la afectan**: **nº 3**: `reducir_movimiento` apaga el balanceo y los movimientos decorativos; en el prompt solo fija los fundidos en 100 ms (el pulso de opacidad no es movimiento y **no** depende de él, regla 18).

---

## Acceptance Criteria

*From GDD 24 § Acceptance Criteria, scoped to this story:*

- [ ] **AC-24-01 / AC-24-02**: con `exploración` y objetivo ≠ nulo la opacidad sube a `anillo_opacidad` en 250 ms (el primer fotograma tras el primer objetivo ≠ nulo ya la inicia); a nulo baja en 150 ms; sin objetivo no hay ningún elemento (sin punto de mira); en `menú`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada` y `sin control` el estado es «oculto» aunque `get_target()` devuelva un valor.
- [ ] **AC-24-03**: cambio de objetivo `V05` → `C05` sin pasar por nulo → la opacidad del anillo no baja y se marca un fundido cruzado de etiqueta de 120 ms; mismo `id` con `etiqueta` distinta (`V06` encendida → apagada) → mismo comportamiento.
- [ ] **AC-24-04 / F1**: `largo`, `anillo_visible`, `p = 0,6` → 216° horario desde las 12 h; `anillo_visible` falso → 0°; soltar antes de `t_hold` (`p` vuelve a 0) → vaciado en 100 ms; en modo «alternar» el relleno **permanece** entre las dos pulsaciones y se vacía al cancelar (AC-24-20: la señal de cancelación es `p = 0`/`anillo_visible` falso de 7, 24 no decide).
- [ ] **F1 pulso** (curva, sin disparo): aceptación `0,80 + 0,20·tri(t/0,12)`, rechazo `0,80 − 0,40·tri(t/0,12)` con valores de ejemplo (rechazo `t = 0,06` → 0,40; `t = 0,12` → 0,80); un cambio de objetivo durante un pulso no lo cancela ni lo reinicia.
- [ ] **AC-24-16**: `reducir_movimiento` activo → todos los fundidos (anillo, etiqueta) duran 100 ms; si cambia durante un fundido, aplica a la siguiente animación; la pausa congela la animación a mitad y continúa al reanudar (tiempo de juego).

---

## Implementation Notes

- Clase pura `RingState` (`RefCounted`) con `PromptConfig` y `GameClock` inyectados; salidas: `opacity`, `fill_degrees`, `label_crossfade`, `pulse_opacity`. El tamaño en píxeles y el modo `icono_grande` los resuelve 022.
- La señal de contexto entra como bool (`top() == EXPLORACION`) para no acoplar a `InputRouter` (la 021 lo cablea).
- `tri(x) = 1 − |2x − 1|` en `[0,1]`, 0 fuera.

---

## Out of Scope

- Dibujo (`_draw`, `draw_arc`): 022. Disparo del pulso por el aviso y latencia: 021. Pie: 019.

---

## Files

- `src/ui/prompt/ring_state.gd`
- `tests/unit/prompt/ring_state_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/prompt/ring_state_test.gd` — debe existir y pasar.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 014 (`PromptConfig`); `GameClock` (estado-y-bus); forma de `get_target()` fijada en `production/epics/interaccion-y-prompt/story-005-interaction-system-barrido.md` (se prueba con objetivos falsos; no necesita 005 terminada)
- Unlocks: 021, 022
