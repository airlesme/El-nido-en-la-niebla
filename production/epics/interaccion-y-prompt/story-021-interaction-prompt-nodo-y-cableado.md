# Story 021: `InteractionPrompt` en `HUD` — sondeo, avisos, ajustes y escena lista

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M — 1,5 días (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › A reglas 1, 7; B regla 14; C regla 19; E regla 31; § Edge Cases; AC-24-23
**Requirement**: `TR-prompt-001`, `TR-prompt-005`, `TR-prompt-019`, `TR-prompt-020` (el resto; los datos son de 014)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 y pseudocódigo `InteractionPrompt._process`/`_on_interaction_executed`, G-2, G-7); ADR-0001 (D11, G-12; avisos `scene_ready`, `input_device_changed`, `pause_closed`); ADR-0007 (canal propio `settings_applied`, lectura de ajustes)
**ADR Decision Summary**: `InteractionPrompt` (nodo en `HUD`, `PAUSABLE`) sondea `get_target()` **una vez por fotograma de render** y pasa `(target, top() == EXPLORACION, now)` a `RingState`; compara `bindings_revision()` (entero) y re-resuelve glifos solo si cambió; reacciona al aviso `interaction_executed` con `PulseGate.classify` → `try_start` → pulso, en el fotograma del aviso (≤ `latencia_feedback_ms` 100 ms); no emite audio, no persiste estado y no dibuja hasta «escena lista».
**ADR Version**: ADR-0016 2026-11-10 · ADR-0001 2026-11-10 · ADR-0007 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: las suscripciones usan el canal del bus por `NoticeIds` (ya existen `INTERACTION_EXECUTED`, `INPUT_DEVICE_CHANGED`, `SCENE_READY`, `PAUSE_CLOSED`); 6 (Ajustes persistentes) es M2: mientras no exista, `PromptSettings` entrega los valores iniciales (`reducir_movimiento` falso, `icono_grande` falso, `etiqueta_accion_visible` falso) y **un cambio de ajuste se aplica al fotograma siguiente** (TR-prompt-019).

**Control Manifest Rules (this layer)**:
- Required: F-R08 (24 es el único consumidor sin filtro `HECHO`), F-R06 (al recibir `state_restored`/`state_reset` el prompt vuelve a leer, no deriva de avisos perdidos), F-R07, F-R18 (HUD `PAUSABLE`), P-R01 no aplica.
- Forbidden: P-X01, `get_tree().paused` o `Timer` propios, emitir avisos desde 24, estado persistente, color para estados (sin rojo).
- Guardrail: cero consultas a Entrada por fotograma; `_process` sin asignaciones.

**Decisiones de usuario ya cerradas que la afectan**: **nº 4**: un solo aviso, 24 lee los cuatro valores y el resto filtra por `HECHO`; **nº 3**: `reducir_movimiento` solo cambia la duración de los fundidos aquí.

---

## Acceptance Criteria

*From GDD 24 § Acceptance Criteria, scoped to this story:*

- [ ] **AC-24-23 (integración con la dependencia dura)**: con `InteractionSystem` real o un doble fiel a su contrato, el bus real y `get_binding_label` real, 24 funciona sin adaptadores: `get_target()` con `anillo_visible`, el aviso con los cuatro valores de `resultado` y `duracion_pie` llegan tal como 7 los emite (casos en 7 AC-15b/36b/36c y en 1 AC-E19).
- [ ] **TR-prompt-001/005**: `get_target()` se sondea exactamente una vez por fotograma de render (contador en el doble) sin aviso de cambio de objetivo; el pulso arranca en el mismo fotograma del aviso (≤ 100 ms medidos en tiempo de juego) y un `HECHO` produce pulso de aceptación, `SIN_EFECTO`/`GESTO_RECHAZADO`/`TOQUE_CORTO` de rechazo, y un `resultado` desconocido ni pulso ni cuelgue (log de error).
- [ ] **TR-prompt-019**: un cambio de `reducir_movimiento`, `icono_grande` o `etiqueta_accion_visible` se aplica en el fotograma siguiente; sin Ajustes (6) los valores iniciales son falso/falso/falso y no hay error; un fundido en curso termina con el valor anterior.
- [ ] **TR-prompt-020**: con «escena lista» pendiente (arranque, escena sin Entrada) no se dibuja nada; tras `scene_ready` empieza el sondeo; `get_target()` es nulo tras cargar partida y el anillo aparece con su fundido; **24 no reproduce audio** (grep + prueba: ningún puerto de audio inyectado), no usa color para estados y no guarda nada (la prueba comprueba que no escribe hechos ni ajustes).
- [ ] **Re-resolución de glifos**: «dispositivo de entrada cambiado» y «pausa cerrada» disparan **una** re-resolución en el fotograma siguiente (con 016) sin reiniciar el reloj de ningún pie.

---

## Implementation Notes

- Nodo `InteractionPrompt` (`Control` bajo `SafeArea169` de 015, en `HUD`): construye `RingState` (018), `PulseGate` (017), `FooterState` (019), `FooterLift` (020) y los vistas (022, 023) por inyección; no usa singletons ni autoload.
- `PromptSettings`: puerto de lectura de ajustes con `Fake` en pruebas; el adaptador real a 6 llega con el épico de Ajustes (M2).
- Implementa `PromptSink` (019) para que 7 llame a `mostrar_pie`/`ocultar_pie` sin conocerlo.

---

## Out of Scope

- Dibujo: 022 y 023. Escala F2: 025 (Blocked). Cableado en `Shell` real: composición de ADR-0009 (si el `Shell` aún no existe, el nodo se prueba en una escena de prueba de `HUD`).

---

## Files

- `src/ui/prompt/interaction_prompt.gd`, `src/ui/prompt/prompt_settings.gd`, `src/ui/prompt/prompt_settings_defaults.gd`
- `tests/integration/prompt/interaction_prompt_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/prompt/interaction_prompt_test.gd` — debe existir y pasar (bus real, doble fiel de 7 hasta que 005–007 estén cerradas; repetir contra 7 real cuando lo estén).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 014, 015, 016, 017, 018, 019, 020; `production/epics/interaccion-y-prompt/story-005-interaction-system-barrido.md` (`get_target()` real); `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md` (aviso `interaction_executed` real; antes, se emite a mano con `InteractionNotice`); épico estado-y-bus (bus, `NoticeIds`); épico entrada-y-controles (`InputRouter.top()`)
- Unlocks: 022, 023, 024
