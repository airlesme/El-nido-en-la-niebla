# Story 007: Orden al pulsar, reserva de gesto, `bloquear_contexto`, «interacción ejecutada» y `duracion_pie`

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 3, 10, 11, 12, 29, 30; § Formulas › F5
**Requirement**: `TR-interact-008`, `TR-interact-009`, `TR-interact-011`, `TR-interact-022` (pie: `duracion_pie` y llamada a `mostrar_pie`); lado de 7 de `TR-prompt-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D6, G-6); ADR-0001 (D11 `interaction_executed`, registro `sound_requested`); ADR-0006 (`begin_blocking`/`end_blocking`, tope 3 s en `GameClock`); ADR-0012 (`reproducir_gesto`)
**ADR Decision Summary**: al procesar una pulsación 7 reserva el gesto (`gesto_hecho` si `SI`, `HAND_REACH` si `SIN_EFECTO`) **antes** de `interact()`; rechazo → `GESTO_RECHAZADO` sin `interact()`; emite exactamente un `interaction_executed {id, verbo, resultado}` y `SFX_CLICK_SUBTLE` en el mismo paso; `bloquear_contexto(razon)` → `InputRouter.begin_blocking(&"interaction:<razon>", 3.0)` solo dentro de `interact()` o con token vivo.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0001 2026-11-10 · ADR-0006 2026-11-10 · ADR-0012 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: firmas fijadas: `begin_blocking(owner: StringName, max_s: float = -1.0)`, `end_blocking(owner)` (ADR-0006); `reproducir_gesto(id: StringName, parametros: Dictionary = {})` (ADR-0012). La **reserva** del gesto (`player.reserve`, ADR-0011 D6 pseudocódigo) está en OI-4 de ADR-0011 → ADR-0012: si ADR-0012 no fija cómo se reserva/rechaza (valor de retorno de `reproducir_gesto` o método aparte), **tarea de esta historia**: proponer la firma y registrarla como ADR-fallback (enmienda de ADR-0012), sin inventarla en el código sin registro.

**Control Manifest Rules (this layer)**:
- Required: FE-R07 (un `interaction_executed` por pulsación procesada, `resultado` de `InteractionTypes.RESULTADO_*`), F-R08 (consumidores ≠ 24 filtran con `InteractionNotice.is_done`).
- Forbidden: FE-X04 (`sin control`); un campo de duración de bloqueo en el catálogo.
- Guardrail: respuesta ≤ `latencia_feedback_ms` 100 ms (≤ 6 pasos).

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-13**: con `V02` (`gesto_hecho = ANIM_PHONE_PICKUP`, `SI`) y un doble del Jugador, `reproducir_gesto` precede a `interact()`; contexto bloqueado (transición, no `sin control`) hasta `gesto_terminado`, y un `interactuar` en ese intervalo se descarta; rechazo del doble → no se llama a `interact()`, no se bloquea, suena `SFX_CLICK_SUBTLE` y se registra; `cancelado`/`tope` liberan sin deshacer; `SIN_EFECTO` pide `HAND_REACH`.
- [ ] **AC-14 / AC-36**: `SIN_EFECTO` → en ≤ 6 pasos suena `SFX_CLICK_SUBTLE`, se pide `HAND_REACH` y el pie si hay `texto`; `HECHO` → «interacción ejecutada» con ID, verbo y resultado.
- [ ] **AC-36b**: `SIN_EFECTO` (lector sin tarjeta, con manejador de prueba), gesto rechazado y toque corto sobre `A04` emiten una vez `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` en el mismo paso que el clic; enfriamiento/transición no emiten; `interact()` sigue devolviendo solo `HECHO`/`SIN_EFECTO`.
- [ ] **AC-15 / AC-15b**: `duracion_pie` de 30 caracteres = 2,64 s (±0,01), 90 = 6,93 s; `multiplicador_pie` 2,0 → 5,29 s; `{accion:atrás}` cuenta 1 carácter; `pie_persistente` → `PERSISTENTE`; sin Ajustes → 1,0 y falso; 7 llama `mostrar_pie(clave, valor, retener = falso)` sobre el puerto `PromptSink`.
- [ ] **AC-26b (token)**: `bloquear_contexto` fuera de `interact()` y sin token → `-1`/nulo y registro; token no liberado → liberado a 3 s de juego por el router (la pausa detiene la cuenta).

---

## Implementation Notes

*Derived from ADR-0011 D6:*

- Secuencia literal del pseudocódigo D6 (veredicto cacheado del barrido → gesto → `interact` → `resultado` → `notify(&"interaction_executed", …)`).
- `SFX_CLICK_SUBTLE` vía `sound_requested` (registro de ADR-0001) en el mismo paso.
- F5: `t_pie = clamp(0,5 + n/14, 2, 8) · multiplicador_pie`; `multiplicador_pie`/`pie_persistente` leídos de Ajustes (6) si existe, si no 1,0/falso (dependencia blanda).
- `PromptSink` es un puerto de 7 (costura D9); en M1 lo implementa un doble/registro hasta que exista 24 (ADR-0016). El pie visible queda diferido.

---

## Out of Scope

- 24 (prompt): pulsos, anillo dibujado, pie visible — diferido por ADR-0016.

---

## Files

- `src/interaction/press_handler.gd` (o dentro de `interaction_system.gd`), `src/interaction/footer_duration.gd`, `src/interaction/ports/prompt_sink.gd`
- `tests/unit/interaction/orden_al_pulsar_test.gd`, `tests/unit/interaction/duracion_pie_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/orden_al_pulsar_test.gd` y `duracion_pie_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-006-press-interpreter.md`; épico `estado-y-bus` (bus, `interaction_executed` en el registro)
- Unlocks: `production/epics/interaccion-y-prompt/story-008-pila-de-modos-y-lectura.md`, `production/epics/interaccion-y-prompt/story-009-vista-cercana-ciclo.md`; manejadores de `production/epics/acceso-puerta-a-cajon-a05/` y `production/epics/documentos-y-bolsillo/`
