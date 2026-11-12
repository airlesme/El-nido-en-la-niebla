# Story 019: `FooterState` — API `mostrar_pie`/`ocultar_pie`, hueco único y vigencia

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M — 1,5 días (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › D reglas 21–23, 25–29; § Formulas F3; AC-24-12, 13, 15, 21
**Requirement**: `TR-prompt-011`, `TR-prompt-012`, `TR-prompt-013`, `TR-prompt-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 «Footer»: `FooterState` pura + `PromptSink`, G-2, G-7); ADR-0009 (D6 puerto `PromptSink`); ADR-0002 (reloj de juego, pausa)
**ADR Decision Summary**: `FooterState` implementa `PromptSink` (`mostrar_pie(clave, duracion_s, retener=false)`, `ocultar_pie()`, `PERSISTENTE = -1.0`): un solo hueco, el último de un fotograma gana, sin cola; `PERSISTENTE` vive hasta que `get_target().id` difiere del id **del instante de dibujo** o llega otro pie; `retener` queda pendiente sin caducidad hasta otro `retener` o carga/cambio de escena; reloj de tiempo de juego; oculto y congelado fuera de `exploración`.
**ADR Version**: ADR-0016 2026-11-10 · ADR-0009 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (puro GDScript)
**Engine Notes**: el fichero del puerto `src/interaction/ports/prompt_sink.gd` es de la historia 007 (puerto de 7); **si 007 aún no se ha implementado**, esta historia lo crea con la firma fijada por ADR-0016 § Key Interfaces y 007 lo reutiliza (anotar en `/story-done`).

**Control Manifest Rules (this layer)**:
- Required: F-R18 (HUD `PAUSABLE`), F-R07, P-R03 (clave → texto de `ContentDB`; clave inexistente: no se dibuja, error de dev, nunca se muestra la clave).
- Forbidden: cola de pies; F-X10 (`create_timer`); persistir pies (nada se guarda); `await` en callbacks.
- Guardrail: sin asignaciones por fotograma en `tick`.

**Decisiones de usuario ya cerradas que la afectan**: ninguna (la nº 3 solo toca el fundido reducido, que decide 023).

---

## Acceptance Criteria

*From GDD 24 § Acceptance Criteria y ADR-0016 § Test Plan (`test_footer_state.gd`), scoped to this story:*

- [ ] **AC-24-12**: con un pie en pantalla, otro `mostrar_pie` lo **sustituye** (marca fundido cruzado 150 ms, 100 con `reducir_movimiento`); dos pies en el mismo fotograma → gana el último, el primero se pierde sin cola.
- [ ] **AC-24-13 / AC-24-21**: `mostrar_pie(clave, 5,29)` → caduca a 5,29 s ± 1 fotograma de **tiempo de juego** (la pausa detiene el reloj y congela el fundido); `PERSISTENTE` no caduca por tiempo y se oculta cuando `get_target().id` cambia respecto del que había **al dibujarse** (nulo cuenta como valor; no el del instante de la petición) o llega otro pie.
- [ ] **AC-24-15**: pie de objeto activo + apertura de `lectura`/modo de 7/`sin control` → se descarta y no reaparece; `UI_BOLSILLO_AYUDA` (`retener = verdadero`) pedido durante `lectura` → aparece al volver a `exploración` con duración completa tras 6 s o 25 s de lectura (F3: sin caducidad); otro `retener` lo sustituye; carga de partida o cambio de escena → descartado; con la pausa abierta todo pie se congela y se reanuda con «pausa cerrada».
- [ ] Clave inexistente → no se dibuja, error por `LogSink`, nunca se muestra la clave; texto > `texto_max_caracteres` (90) → se acepta (hasta 3 líneas) con **advertencia de datos** en desarrollo (R25); 24 no guarda bandera de «una vez por sesión» (R28) ni historial (R29).

---

## Implementation Notes

- `FooterState` expone `current() -> FooterView` (clave, texto resuelto vía 016, `fase`, `opacidad`) para 023; recibe `set_context_exploration(bool)`, `set_target_id(id)`, `on_scene_changed()`, `on_state_restored()`.
- El texto con tokens lo resuelve 016 al dibujar; esta historia solo guarda la clave (re-resolver no reinicia el reloj).
- **Contrato con 020 (`retener` pierde su aviso)**: la pregunta 8 del GDD (que 24 avise a 20 de que descartó el pie retenido) queda abierta; defecto del GDD: sin aviso.

---

## Out of Scope

- Posición y elevación sobre subtítulos: 020. Dibujo, panel y tipografía: 023. Duración (`duracion_pie`): ya es de 007.

---

## Files

- `src/ui/prompt/footer_state.gd`, `src/ui/prompt/footer_view_model.gd`, `src/interaction/ports/prompt_sink.gd` (solo si 007 no lo ha creado)
- `tests/unit/prompt/footer_state_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/prompt/footer_state_test.gd` — debe existir y pasar.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 014 (`PromptConfig`), 016 (resolución de texto con tokens); `GameClock` y `ContentDB` de sus épicos; `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md` solo por el fichero del puerto (ver Engine Notes)
- Unlocks: 020, 021, 023
