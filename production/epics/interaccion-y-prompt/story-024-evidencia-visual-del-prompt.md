# Story 024: Evidencia visual del prompt (C-M1-7) y recorrido con mando y teclado

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — AC-24-01, 03, 05, 06, 07, 17, 18, 20, 22; `design/gdd/interaccion-e-inspeccion.md` — AC-V1, AC-V2, AC-V3
**Requirement**: cierre de `TR-prompt-002/003/004/005/008/015/016` en pantalla (sin TR propio; la cobertura de TR queda en 017–023)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (§ Validation Criteria «Visual evidence», G-11, spikes SP-16A/B/D/E NEEDS_WINDOWED); `.claude/docs/run-and-observe.md`
**ADR Decision Summary**: «A parse check is not a run»: toda historia con algo observable por el jugador se lanza y se observa; la captura es **del motor** (`--write-movie`), retenida en `production/qa/evidence/`.
**ADR Version**: ADR-0016 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: la medición real del viewport lógico en 16:10 (S-0011-C/P-19), la fuente Atkinson y la alineación de glifos están NEEDS_WINDOWED; esta historia los **mide** si el prototipo jugable lo permite y, si no, los anota `NOT ASSESSED` en el informe, nunca asumidos.

**Control Manifest Rules (this layer)**:
- Required: P-R04; evidencia retenida por tipo UI (coding-standards § Test Evidence).
- Forbidden: capturas del escritorio o de herramientas externas como sustituto del motor.
- Guardrail: informativo (FE-G01 en escena real).

**Decisiones de usuario ya cerradas que la afectan**: nº 3 y nº 5 (ver 023/025); **nº 4**: las capturas de rechazo se tomarán con el aviso único y sus tres valores no `HECHO`.

---

## Acceptance Criteria

*From GDD 24 y GDD 7 (AC-V1…V3), scoped to this story:*

- [ ] **AC-V1 / AC-V3 / AC-24-01/03/05/06/17**: capturas retenidas del anillo: sobre `V02` `vibrando` a ~1,4 m con y sin etiqueta activa («Descolgar») y sin icono con `V02` en `reposo`; el relleno de `leer` sobre `B05` con `p ≈ 0,6` (0,30 s); el pulso de aceptación y de rechazo (fotograma a 60 ms); `icono_grande`.
- [ ] **AC-V2 / AC-24-22 / AC-24-14 (parte visual)**: captura del pie de `D03` dentro de los márgenes del 5 % y con un bloque de subtítulo de prueba debajo; resoluciones **1280×720, 1920×1080 y 3840×2160** (más 2560×1080 para HUD), con fondo blanco y negro para el contraste; fuente declarada «provisional» si Atkinson no está en el repo.
- [ ] **AC-24-18**: lista comprobada **por separado con teclado y con mando** (anillo, etiqueta con glifo, pie de objeto `OBJ_C06`, pie `UI_BOLSILLO_AYUDA` con el glifo del dispositivo, pulso de rechazo) y registrada en `production/qa/evidence/prompt-evidence.md`.
- [ ] **AC-24-07**: el filtro/simulación de daltonismo queda `NOT SOURCEABLE` (el motor no lo documenta): se anota la herramienta externa elegida y su salida, o `NOT ASSESSED` si no se ejecuta.

---

## Implementation Notes

- Procedimiento `.claude/docs/run-and-observe.md` con `godot --path . --write-movie production/qa/evidence/<nombre>.png …`; las capturas con `escala_texto_ui` 1,50 de G-11 **no aplican** hasta que se resuelva el TODO(ui-owner) de 023 (decisión nº 3).
- La captura del recorrido de interacción (`V01`, panel P1) es de la 013; esta historia no la repite.

---

## Out of Scope

- AC-V4/V5 (inspección, lectura): fuera de M1 / épico documentos-y-bolsillo. AC-24-14 en **píxeles físicos**: 025.

---

## Files

- `production/qa/evidence/prompt-evidence.md`, capturas `production/qa/evidence/prompt-*.png`
- (opcional) `tests/integration/prompt/prompt_capture_scene.gd` (escena de arranque de dev)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/prompt-evidence.md` + capturas retenidas del motor (lista de arriba), con visto bueno del lead en el informe.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 021, 022, 023, 020; `production/epics/interaccion-y-prompt/story-006-press-interpreter.md` y `story-007-orden-al-pulsar-y-aviso.md` (relleno `p` real y aviso real; antes, estados forzados de dev)
- Unlocks: C-M1-7 (parte «prompt de interacción»); `production/epics/interaccion-y-prompt/story-013-recorrido-m1-y-capturas.md` puede citarla
