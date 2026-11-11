# Historias — Épico «Ordenador (búsqueda) e impresora»

> **Épico**: `production/epics/ordenador-e-impresora/EPIC.md` · **Capa**: Feature · **Hito**: M1 · **PARCIAL**
> **GDD**: `design/gdd/ordenador-correo-impresora.md` (19) · fuente de tiempos: `design/slice/slice-v0.3.md` Anexo C.2
> **Manifest Version**: 2026-11-11b · **workflow**: standard · **story_granularity**: balanced · **docs.density**: balanced
> **Generado**: 2026-11-11 por `/create-stories` (automation: autonomous)
> **Revisión**: QL-STORY-READY skipped — Lean mode

ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0004 **Proposed** · ADR-0005 Accepted · ADR-0006 Accepted ·
ADR-0007 **Proposed** · ADR-0011 Accepted

Estimaciones en días; **confianza BAJA** en todas (sin historial de sprints; ADR-0006 con riesgo HIGH
por `LineEdit` y teclado en pantalla con foco dual; overlay H21 sin diseñar).

## Historias

| ID | Título | Tipo | Est. (d) | Depende de | Estado |
|----|--------|------|----------|------------|--------|
| 001 | Búsqueda: normalización y coincidencia exacta | Logic | 0,5 | contenido-y-datos (etiquetas de 18) | Ready |
| 002 | Latencia 0,4 s, lista en orden fijo 3, 1, 4, 2 y `correos_leidos` | Logic | 1,5 | 001; estado-y-bus (`GameClock`, `FactWriter`) | Ready |
| 003 | `compose_i01()` pura con `ts_envio` entero | Logic | 1,0 | contenido-y-datos | Ready |
| 004 | Impresora `V08`: máquina de estados 1,5 s y entrega de `I-01` | Integration | 1,5 | 002, 003; documentos-y-bolsillo | Ready |
| 005 | Receptor de vista `V01`: apertura, cierre, `atrás` y sesión en memoria | Integration | 1,0 | interaccion-y-prompt (`ViewReceiver`) | Ready |
| 006 | Foco dual y teclado en pantalla (mando y teclado) | Integration | 2,0 | 005; entrada-y-controles | Ready |
| 007 | Gesto `HAND_TYPE` mientras se teclea | Integration | 0,5 | 006; jugador-primera-persona | Ready |
| 008 | Fundido de encendido 0,3 s | Visual/Feel | 0,5 | 005 | Ready |
| 009 | Overlay del ordenador en gris y capturas (ordenador + impresión) | UI | 1,5 | 002, 004, 006 | Blocked |

**Orden recomendado (camino crítico en negrita, alimenta P1):** **001 → 002 → 003 → 004** → 005 → 006 → 007 → 008 → 009.
Total: 10,0 d (esperado; optimista ≈ 7, pesimista ≈ 14 si el foco dual de ADR-0006 necesita el fallback).

## Diferido (sin historia)

| Requisito / AC | Motivo | Desbloqueo |
|----------------|--------|------------|
| **TR-computer-013** (UI lógica 1920×1080, 16:9/16:10, 1280×720 mínimo, modo teclado ≤ 520 px) — AC-10b, AC-28 | **ADR-0007 Proposed** (escalado de UI) | aceptar ADR-0007 (parte de escalado, SP-1…6) |
| **TR-computer-014** (texto ≥ 24 px, contraste 4,5:1 / 7:1, atributo no cromático, «no disponible» al lector) — AC-18a, AC-18b, AC-19 | **ADR-0007 Proposed** | aceptar ADR-0007 |
| AC-21, rama `reducir_movimiento` (100 ms) | lectura de ajustes por `SettingsReader` de ADR-0007 **Proposed** | aceptar ADR-0007 |
| AC-14, AC-15 (partida cargada con `correos_leidos`) | ADR-0004 **Proposed** (guardado) | aceptar ADR-0004 |
| AC-27 (playtest 4 de 5 encuentran el buscador) | criterio de experiencia; se mide en M5 | M5 |

## Decisiones tomadas (autonomous)

1. **ADR-0006 depende de ADR-0007 (Proposed)**: la dependencia es de etiquetas/escalado; las historias
   de foco y teclado no tocan escalado, así que quedan Ready. *Descartado:* bloquear 005–009.
2. **Story 009 Blocked por H21** (overlay del ordenador pendiente en la cola de diseño, EPIC.md), no
   por ADR. Sin H21 no hay maqueta que capturar; C-M1-7 «ordenador» e «impresión» dependen de ella.
3. **Ruta del código de 19**: ningún ADR la fija (`architecture.md` solo dice «`Computer` V01/V08 en
   `planta`; overlay en `SceneUi`»). Fallback propuesto: `src/world/computer/`; el implementador lo
   confirma con lead-programmer en la story 001 y, si cambia, mueve las rutas de Files.
4. **compose_i01 aquí, consumo en P1**: la prueba de que su orden da `[2,1,3,4]` vive en
   `puzles-marco-y-p1/story-008`.
