# Historias — Épico «Director de escenas 1–3 (versión mínima)»

> **Épico**: `production/epics/director-escenas-1-3/EPIC.md` · **Capa**: Feature (autoload n.º 9) · **Hito**: M1 · **PARCIAL**
> **GDD**: `design/gdd/director-de-escenas.md` (21) · tiempos: `design/slice/slice-v0.3.md` Anexo C.1 y C.3
> **Manifest Version**: 2026-11-11b · **workflow**: standard · **story_granularity**: balanced · **docs.density**: balanced
> **Generado**: 2026-11-11 por `/create-stories` (automation: autonomous) · **Ruta de voz: «sin audio»**
> **Revisión**: QL-STORY-READY skipped — Lean mode

ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0003 Accepted · ADR-0004 **Proposed** · ADR-0005 Accepted ·
ADR-0006 Accepted · ADR-0007 **Proposed** · ADR-0008 **Proposed** · ADR-0009 Accepted · ADR-0017 Accepted

Estimaciones en días; **confianza BAJA** en todas (sin historial de sprints; orden de `_process` entre
`GameClock` y `SceneDirector` NOT SOURCEABLE — ADR-0017 V2; el esqueleto `src/director/scene_director.gd`
solo tiene `_init`/`setup`).

## Historias

| ID | Título | Tipo | Est. (d) | Depende de | Estado |
|----|--------|------|----------|------------|--------|
| 001 | `scenes.json` y `director_config.json`: esquema y validación | Logic | 1,0 | contenido-y-datos (DataValidator) | Ready |
| 002 | `CueTimeline`: `t_rel` sobre `GameClock`, órdenes vencidas y pausa | Logic | 1,0 | estado-y-bus (`GameClock` completo) | Ready |
| 003 | Ciclo de vida persistente y matriz de cancelación | Logic | 1,5 | 002 | Ready |
| 004 | Traspaso de `sin control` y duración declarada (`ESC1_LLEGADA`) | Integration | 1,5 | 002, 003; carga-de-planta, entrada-y-controles | Ready |
| 005 | `ESC1_LLEGADA`: tiempos de C.1 ±1 fotograma con reloj falso (sin audio) | Logic | 1,5 | 001, 002, 004 | Ready |
| 006 | Mensaje del Guardián: «Responder» → «Ahora no» → +1,0 s | Integration | 1,0 | 005; objeto `V02` (H23) | Ready |
| 007 | `ESC3`: `formulario_leido` → `LLUVIA_REALCE` + `VO_V_04` (tiempos de C.3) | Logic | 1,0 | 001, 002 | Ready |
| 008 | Encadenado escenas 1–3 sin consola y cronometraje | Integration | 1,0 | 005, 006, 007; épicos de M1 | Ready |

**Orden recomendado (camino crítico en negrita):** **001 → 002 → 003 → 004 → 005** → 006 → 007 → 008.
Total: 9,5 d (esperado; optimista ≈ 7, pesimista ≈ 13 si V2 obliga a fijar `process_priority`).

## Diferido (sin historia)

| Requisito / AC | Motivo | Desbloqueo |
|----------------|--------|------------|
| **TR-director-009** (dos canales de voz, aplazamiento por canal) — AC-21-26 | **ADR-0008 Proposed** | aceptación parcial de ADR-0008 (SA1, SA3, SA5, SA6) |
| **TR-director-026** (líneas `fallida`/`sin audio` sin reintento, subtítulo) | **ADR-0008 Proposed** | ídem; las historias 005 y 007 solo comprueban que se **pide** la línea, no su espera ni su final |
| Espera por fin de línea en C.1/C.3 con audio real (`LineWait` sobre respuestas de 23) | ADR-0008 Proposed; audio en épico `audio-provisional` (BLOQUEADO) | ADR-0008 |
| AC-21-11, AC-21-27 (`reducir_movimiento`) | `SettingsReader` de ADR-0007 **Proposed**; además escenas 4 y 8 | ADR-0007 / M2+ |
| AC-21-07 variante «Continuar» desde partida guardada | ADR-0004 **Proposed** (con estado inyectado sí se prueba en 004) | ADR-0004 |
| Escenas 4–8, apagón, llamada, cierre (TR-director-016…023) | fuera del alcance M1 | M2/M3 |

## Decisiones tomadas (autonomous)

1. **ADR-0017 depende de ADR-0004/0007/0008 (Proposed)**: dependencias estrechas (sellado de la
   llamada, `SettingsReader`, canales de voz), ninguna ejercida por las escenas 1–3 en ruta «sin
   audio». Historias Ready; lo que sí las ejerce está en Diferido. *Descartado:* bloquear el épico.
2. **Ruta «sin audio»**: el director emite `line_requested` a su `t_rel` y **no espera** la línea en
   C.1 (AC-21-05b: «sin aplazarse»). El test usa un doble de 23 que no responde.
3. **Firmas**: se usan las de ADR-0017 § Key Interfaces (`SceneRecord`, `CueRun`, `CueEmitter`,
   `StepChain`, `LineWait`, `setup(ctx)`) y ADR-0002 (`now`, `deadline`, `is_due`). `CueTimeline` y
   `ClockSource` tienen ruta en el ADR (`src/director/timeline/`); cualquier método que el ADR no
   muestre es tarea de la historia con ADR-fallback (se añade siguiendo D2 y se anota para
   `/architecture-review`).
4. **Tiempos de C.3**: el slice solo fija tiempos de otros sistemas en C.3 (`ANIM_DOOR_OPEN` 1,2 s → 8;
   lectura A04 2 s → 20). Al director le toca `d_vo04_s` tras `formulario_leido` (AC-21-08).
