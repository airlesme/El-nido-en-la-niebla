# Story 005: `ESC1_LLEGADA` — tiempos de C.1 ±1 fotograma con reloj falso (sin audio)

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

C-M1-5. Anexo C.1 del slice: 0,0 fundido desde negro (2,0 s) y ventilador en bucle · 1,5 `VO_V_01` ·
6,0 `MEGA_01` desde C01 · 12,0 `V02` vibra (`SFX_PHONE_BUZZ`, 3 pulsos de 1 s) y mensaje «¿Jugamos
esta noche?» · 14,0 opciones y `exploración`. Ruta «sin audio»: las líneas se piden a su hora y la
línea de tiempo no espera su final.

**GDD**: `design/gdd/director-de-escenas.md` (reglas 7, 16; F1)
**Requirement**: `TR-director-006`, `TR-director-008`, `TR-director-013`, `TR-director-019` (`V02` → `vibrando`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D1 (cues), D2 (`CueTimeline`), D5 (cargas de `scene_effect_requested` / `object_state_requested`); ADR-0001 (órdenes por el bus)
**ADR Decision Summary**: `ESC1_LLEGADA` se mide desde «escena lista»; cada cue se emite por `CueEmitter`; al terminar pide `exploración`.
**ADR Version**: ADR-0017 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0017)
**Engine Notes**: ±1 fotograma a 60 fps (tolerancia 1/60 s) — independiente del orden V2.

**Control Manifest Rules (this layer)**:
- Required: FE-R21, FE-R23 (21 único emisor de `scene_effect_requested`/`object_state_requested`, siempre por `CueEmitter`)
- Forbidden: FE-X10, FE-X11 (21 no encola líneas ni pide `VO_G_*`)
- Guardrail: FE-G03

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-05b**: `VO_V_01` se pide a 1,5 s y `MEGA_01` a 6,0 s (±1 fotograma) **sin aplazarse**, aunque `VO_V_01` (≈ 8 s) siga «sonando» (doble de 23 sin respuesta); los pulsos de `V02` a 12,0 s.
- [ ] **GDD 21 AC-21-05**: a `t_rel` = 14,0 el director pide `exploración`; la pila queda [`exploración`] sin `menú`; `V02` ofrece «Responder».
- [ ] **C-M1-5 (C.1)**: test de timeline con `GameClock` falso que compara cada orden emitida (ID, `t_rel`) con la tabla de C.1 leída de `scenes.json`, tolerancia ±1 fotograma.
- [ ] **TR-director-006**: el origen es «escena lista», no el fin del aclarado.

---

## Implementation Notes

- `src/director/cue_emitter.gd` (ruta de ADR-0017 l. 875).
- La tabla esperada del test se lee del mismo `scenes.json` y se contrasta con constantes de fixture del Anexo C.1 (boundary values: aquí el número exacto es el objeto de la prueba).
- Espera por «línea terminada» y canales: **Diferido** (ADR-0008).

---

## Out of Scope

- Story 006: la respuesta del jugador al mensaje.

---

## Files

- `src/director/cue_emitter.gd`, `assets/data/director/scenes.json` (`ESC1_LLEGADA`)
- `tests/unit/director_de_escenas/esc1_c1_timing_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/director_de_escenas/esc1_c1_timing_test.gd` con `GameClock` falso — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/director-escenas-1-3/story-001-scenes-json-validacion.md`, `production/epics/director-escenas-1-3/story-002-cue-timeline-game-clock.md`, `production/epics/director-escenas-1-3/story-004-traspaso-sin-control.md`
- Unlocks: `production/epics/director-escenas-1-3/story-006-mensaje-guardian.md`, `production/epics/director-escenas-1-3/story-008-encadenado-escenas-1-3.md`
