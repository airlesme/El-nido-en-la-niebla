# Historias — Interacción y prompt (solo la mitad «Interacción», sistema 7)

> **Generado**: 2026-11-11 por `/create-stories` (modo `autonomous`, `review_mode: lean`)
> **Manifest Version**: 2026-11-11b · **Workflow**: standard · **Granularidad**: balanced (2–4 AC por historia)
> **ADRs**: ADR-0011 Accepted · ADR-0001 Accepted · ADR-0002 Accepted · ADR-0005 Accepted · ADR-0006 Accepted · ADR-0009 Accepted · ADR-0012 Accepted · ADR-0016 **Proposed** · ADR-0007 **Proposed**
> **QL-STORY-READY**: omitido — modo Lean
> **Estimaciones**: días de una persona, confianza **BAJA** (sin historial de sprints ni velocidad; R-M1-6).

| ID | Título | Tipo | Est. (días) | Depende de | Estado |
|----|--------|------|-------------|------------|--------|
| 001 | Catálogo `interactables.json`, esquema y configuración de 7 | Logic | 1 (0,5–1,5) | épico contenido-y-datos (DataReader, DataCatalog) | Ready |
| 002 | `PickRegistry` y `PickMath`: contactos F1 aritméticos | Logic | 1,5 (1–2,5) | 001 | Ready |
| 003 | Capas físicas y `OcclusionProbe` (`intersect_ray`) | Logic | 1 (0,5–1,5) | 002 | Ready |
| 004 | `FocusSelector`: agrupación, desempate, retención y disponibilidad | Logic | 1 (0,5–1,5) | 002, 003 | Ready |
| 005 | `InteractionSystem` en planta: barrido por paso, pausa, `get_target()` | Integration | 1 (1–2) | 004; épicos jugador-primera-persona, entrada-y-controles, carga-de-planta | Ready |
| 006 | `PressInterpreter`: corta/larga, enfriamiento, anillo `p` | Logic | 1 (0,5–1,5) | 005 | Ready |
| 007 | Orden al pulsar, reserva de gesto, `bloquear_contexto`, «interacción ejecutada» y `duracion_pie` | Logic | 1,5 (1–2) | 006 | Ready |
| 008 | Pila de modos y lectura (`abrir_lectura`, `lectura_min_s`, aplazada) | Logic | 1,5 (1–2,5) | 007 | Ready |
| 009 | Vista cercana: ciclo de vida, cesión de cámara y token | Logic | 1,5 (1–2,5) | 007, 008 | Ready |
| 010 | Contrato `ViewReceiver`, cancelación y `cerrar_modos()` | Logic | 1 (0,5–1,5) | 009 | Ready |
| 011 | `ViewMetrics` (F6), `ViewPicker` y `PointerEvent` | Logic | 1,5 (1–2) | 010 | Ready |
| 012 | Modo ordenador (`V01`) | Integration | 0,5 (0,5–1) | 009; épico ordenador-e-impresora | Ready |
| 013 | Recorrido M1 con mando y teclado + capturas de interacción | Integration | 1 (0,5–2) | 005–012; épicos puzles-marco-y-p1, documentos-y-bolsillo | Ready |

**Total Ready**: 13 historias · 15 días esperados (rango 10–23) · 0 Blocked.

## Diferido / bloqueado por ADR

No se escribe ninguna historia sobre estos TR (hito M1 § ADR y spikes, Regla). Se redactarán con
`/create-stories interaccion-y-prompt` cuando el ADR pase a `Accepted`.

| Qué | TR / AC | Bloqueado por | Salida |
|-----|---------|---------------|--------|
| Prompt (24) completo: anillo, etiqueta, glifos, pie, pulsos, convivencia con 26 | TR-prompt-001…017, 019, 020 | **ADR-0016** (Proposed) | spike corto de ADR-0016 con ADR-0007 → `/architecture-decision accept ADR-0016` |
| Escala de UI del prompt | TR-prompt-018 | **ADR-0007** y **ADR-0016** (Proposed) | idem |
| Pulsos de aceptación/rechazo (24) | TR-prompt-005/006 (lado 24) | **ADR-0016** (el lado de 7, el aviso, sí entra en 007) | idem |
| Capturas del prompt (C-M1-7 «prompt de interacción»): AC-V1, AC-V2, AC-V3 de GDD 7 | — | **ADR-0016** | idem |
| Fuente viva del tamaño de viewport lógico para `ViewMetrics` (`ViewportMapper`, OI-5) | TR-interact-015 (parte) | **ADR-0016** | 011 trabaja con W, H inyectados; el adaptador real llega con ADR-0016 |
| Viewport lógico `canvas_items`/`expand` en 16:10 (S-0011-C NEEDS_WINDOWED) | AC-32 (H=1200 medido en ventana), AC-V6 16:10 | ADR-0011 lo difiere al prototipo jugable; ADR-0016 lo mide | verificación en ventana en 013 si ADR-0016 ya está aceptado; si no, NOT ASSESSED anotado |

## Fuera del alcance de M1 (no por ADR)

- Inspección en mano `V05` (TR-interact-019; AC-17…AC-21, AC-20b, AC-V4): recorte 6 del hito.
- Vistas `D01a`–`D01d` de la caja (AC-26c, AC-27f, AC-V6 sobre `D01a`): sala D fuera de M1. El
  mecanismo de vista se prueba con receptores de prueba y con el panel de P1 (épico puzles-marco-y-p1).
- Lectores `C06`/`C07`/`D06` y ascensor `C08` (AC-26d): puertas B/D fuera de M1.
- `R01` de dos páginas (AC-23) entra solo como prueba unitaria con catálogo de prueba (008).
- Criterios de experiencia AC-X1/X2/X3: playtest de M5; AC-X2b sí entra (unitario, 006).
