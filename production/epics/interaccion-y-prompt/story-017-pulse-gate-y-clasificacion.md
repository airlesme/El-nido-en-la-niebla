# Story 017: `PulseGate` — clasificación del `resultado` y tope de fotosensibilidad

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S — 0,5 día (0,5–1), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › C reglas 17–20; D24-9, D24-12; AC-24-06
**Requirement**: `TR-prompt-006` (lado de 24; el aviso lo emite 007), `TR-prompt-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 «Pulse filter», `PulseGate`, G-2, G-7); ADR-0001 (D11, G-12: `interaction_executed`, `InteractionNotice`)
**ADR Decision Summary**: 24 es el **único** consumidor que no filtra por `HECHO`: `HECHO` → pulso de aceptación; `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` → pulso de rechazo; cualquier otro valor → sin pulso + log de error. `PulseGate` descarta un pulso nuevo que empiece a < `pulso_min_intervalo_ms` (340; validación rechaza < 334) del anterior, sobre `RealClock` (límite perceptual); sin cola.
**ADR Version**: ADR-0016 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (puro GDScript)
**Engine Notes**: `RealClock` inyectado (hay un doble en pruebas); nada de `Time` directo ni `Timer`. `InteractionNotice` y `NoticeIds.INTERACTION_EXECUTED` ya existen en `src/core/`.

**Control Manifest Rules (this layer)**:
- Required: F-R08 (24 es la excepción documentada; el resto filtra con `InteractionNotice.is_done`), F-R07 (callback barato, sin `await`).
- Forbidden: cola de pulsos; aviso nuevo de rechazo (D24-9); reproducir audio (`SFX_CLICK_SUBTLE` es de 7).
- Guardrail: sin asignaciones por aviso (`classify` devuelve enum).

**Decisiones de usuario ya cerradas que la afectan**: **nº 4 (2026-11-12)**: el aviso «interacción ejecutada» es **uno**; el resto de sistemas filtran por `HECHO`, 24 lee los cuatro valores. Esta historia no añade ningún aviso.

---

## Acceptance Criteria

*From GDD 24 AC-24-06 y ADR-0016 § Test Plan (`test_pulse_gate.gd`), scoped to this story:*

- [ ] `classify`: `HECHO` → `ACCEPT`; `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` → `REJECT`; cualquier otro valor, clave ausente o tipo erróneo → `NONE` + error por `LogSink` (un gesto = un aviso = un pulso, TR-prompt-006).
- [ ] **AC-24-06 (tope)**: con `RealClock` falso, 10 avisos en 1 s → como máximo 3 `try_start == true` y el intervalo entre inicios ≥ 340 ms (≥ 334); un pulso rechazado por el tope **no** se reencola ni se dispara después (sin cola).
- [ ] El tope se mide en `RealClock` (la pausa no lo congela): con el reloj de juego parado el resultado no cambia; un aviso exactamente a 340 ms del anterior pasa, a 339 ms no.
- [ ] El sonido no depende del tope (la prueba verifica que 17 no llama a ningún puerto de audio).

---

## Implementation Notes

- Firma fijada por ADR-0016 § Key Interfaces: `PulseGate._init(clock: RealClock, min_interval_ms: int)`, `classify(resultado: StringName) -> Pulse`, `try_start(p: Pulse) -> bool`, `enum Pulse {NONE, ACCEPT, REJECT}`.
- Los literales de `resultado` salen de las constantes de `InteractionNotice`, no de cadenas sueltas.

---

## Out of Scope

- Dibujo del pulso (curva F1): 018/022. Suscripción al bus y latencia ≤ 100 ms: 021.

---

## Files

- `src/ui/prompt/pulse_gate.gd`
- `tests/unit/prompt/pulse_gate_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/prompt/pulse_gate_test.gd` — debe existir y pasar.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 014 (`pulso_min_intervalo_ms`); `RealClock` del épico estado-y-bus; `InteractionNotice` (ya en `src/core/`)
- Unlocks: 021
