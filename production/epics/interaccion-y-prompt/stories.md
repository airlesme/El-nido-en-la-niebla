# Historias — Interacción y prompt (sistema 7: 001–013 · sistema 24: 014–025)

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

**Mitad Interacción (7)**: 13 historias Ready · 15 días esperados (rango 10–23) · 0 Blocked.

## Mitad Prompt (24) — historias 014–025

> **Generado**: 2026-11-12 por `/create-stories` (modo `autonomous`, `review_mode: lean`; QL-STORY-READY omitido).
> **ADRs**: ADR-0016 **Accepted** (2026-11-11) · ADR-0007 Accepted · ADR-0005 Accepted · ADR-0001 Accepted · ADR-0006 Accepted · ADR-0002 Accepted · ADR-0009 Accepted · ADR-0008 **Proposed** (ver «Decisiones tomadas»).
> **Manifest Version**: 2026-11-11b (anterior a la aceptación de ADR-0016: su § Presentation lo da por `Proposed`; las reglas de ADR-0016 § Implementation Guidelines G-1…G-11 se aplican hasta regenerarlo — `TODO(technical-director)`).
> **Estimaciones**: días de una persona, confianza **BAJA** (misma escala que 001–013).

| ID | Título | Tipo | Est. (días) | Depende de | Estado |
|----|--------|------|-------------|------------|--------|
| 014 | Datos del prompt: `prompt.json`, esquema y validación | Logic | 0,5 (0,5–1) | épico contenido-y-datos; 001 (patrón) | Ready |
| 015 | Capa `HUD`, área segura 16:9 y `ViewportMapper` | Logic | 1 (0,5–1,5) | estado-y-bus (`LogSink`); `Shell` (doble) | Ready |
| 016 | `BindingLabelSource`, `TokenResolver` y `GlyphText` | Logic | 1,5 (1–2,5) | entrada-y-controles 013; contenido-y-datos; 014 | Ready |
| 017 | `PulseGate`: clasificación del `resultado` y tope 340 ms | Logic | 0,5 (0,5–1) | 014; `RealClock` | Ready |
| 018 | `RingState`: visibilidad, fundidos, relleno F1 y curva de pulso | Logic | 1,5 (1–2) | 014; `GameClock` | Ready |
| 019 | `FooterState`: `mostrar_pie`/`ocultar_pie`, hueco único, vigencia | Logic | 1,5 (1–2) | 014, 016; 007 solo por el fichero del puerto | Ready |
| 020 | `FooterLift` y puerto `SubtitleBandQuery` | Logic | 0,5 (0,5–1) | 015, 019 | Ready |
| 021 | `InteractionPrompt` en `HUD`: sondeo, avisos, ajustes, escena lista | Integration | 1,5 (1–2) | 014–020; **005**; 007 (aviso real) | Ready |
| 022 | `RingView` y etiqueta de acción (glifo + texto) | UI | 1,5 (1–2,5) | 015, 016, 018, 021 | Ready |
| 023 | `FooterSlot`: panel, márgenes seguros, fundidos y elevación | UI | 1,5 (1–2,5) | 015, 016, 019, 020, 021 | Ready |
| 024 | Evidencia visual del prompt (C-M1-7) con teclado y mando | UI | 1 (0,5–1,5) | 020–023; 006, 007 | Ready |
| 025 | Escala de UI del prompt (F2) y suelo de texto de 24 px | Logic | 1 (0,5–1,5) | decisión ui-owner; 014, 015, 023 | **Blocked** |

**Prompt**: 12 historias (11 Ready · 1 Blocked) · 12 días esperados Ready (+1 de 025) · 4 Logic puras sin dependencia de 005 (014, 015, 017, 018) se pueden hacer en paralelo desde ya.

### Cobertura de TR (los 20 `TR-prompt-NNN`, sin huecos)

| TR | Historia | Nota |
|----|----------|------|
| 001 | 021 | sondeo por fotograma |
| 002, 003, 004 | 018 | visibilidad por contexto, fundidos y tamaños, relleno F1 (dibujo en 022) |
| 005 | 021 | disparo por el aviso, ≤ 100 ms (curva F1 en 018) |
| 006, 007 | 017 | clasificación de `resultado` y tope 340 ms |
| 008 | 022 | etiqueta apagada por defecto, glifo con texto, clave ausente |
| 009, 010, 017 | 016 | `get_binding_label`, re-resolución, token `{accion:atrás}` |
| 011, 012, 013, 014 | 019 | API, hueco único, duración/PERSISTENTE, solo en exploración y `retener` |
| 015 | 023 (parte) + **025** (parte, Blocked) | layout y contraste en 023; «texto ≥ max(28·s, 24) px» en 025 |
| 016 | 020 | convivencia con 26 |
| 018 | 015 (parte) + **025** (parte, Blocked) | márgenes y 16:9 en 015; F2/redondeo en 025 |
| 019 | 021 | lectura de ajustes de 6 con valores iniciales |
| 020 | 021 (resto) + 014 (parte: datos) | sin audio, sin color de estado, sin estado, escena lista |

### Decisiones tomadas (modo autonomous)

| Decisión | Alternativa descartada | Motivo |
|----------|------------------------|--------|
| El épico incluye lo mínimo de UI compartida que el prompt necesita (`UiLayers`, `SafeAreaMath`/`ViewportMapper`, `TokenResolver`/`GlyphText`, puerto `SubtitleBandQuery`) en 015, 016 y 020 | Esperar a un épico de UI base de 25/26/27 (no existe) | El prompt no puede cerrar C-M1-7 sin ellos; ADR-0016 los comparte y las historias dicen «reutilizar si 25/26/27 los crearon antes» |
| 019 crea el fichero del puerto `PromptSink` si 007 aún no lo hizo | Bloquear 019 en 007 | La firma está fijada en ADR-0016 § Key Interfaces; 007 lo reutiliza |
| ADR-0008 (`Proposed`) es `depends_on` de ADR-0016 pero **no bloquea** el prompt | Marcar todo `Blocked` por la regla literal de dependencias | ADR-0016 lo usa solo para `line_started` y `seg_b_inicio_s` de los subtítulos (D5); ninguna regla del prompt (D6) lo cita. **Revisar**: lo confirma technical-director |
| 025 queda `Blocked` en vez de implementar F2 del GDD o la regla de ADR-0007 | Elegir una de las dos | Contradicción GDD 24 F2/AC-24-14/TR-015/-018 frente a ADR-0007 D7 y ADR-0016 G-4 (ADR-0016 C1/OI-5); QQ-10 sin confirmar. No se inventa regla de diseño |
| El pie se implementa a factor 1,0 (sin `escala_texto_ui`) y sin capturas a 1,50 | Asumir que `escala_texto_ui` existe (ADR-0016 D6/G-11) | Decisión de usuario nº 3: «se da por cerrada»; `TODO(ui-owner)` en 023/024 |

### Decisiones de usuario (2026-11-12) que afectan al prompt

- **Nº 4**: el aviso «interacción ejecutada» es **uno**; 24 lee los cuatro valores y el resto filtra por `HECHO` → 017, 021.
- **Nº 3**: `reducir_movimiento` apaga el balanceo y movimientos decorativos; en el prompt solo fija fundidos de 100 ms → 018, 021, 023. `escala_texto_ui` cerrada → 023, 024.
- **Nº 5**: subtítulos/texto a 720p escalan con la ventana con suelo legible definido en 26 → 020, 025 (el suelo de 24 px lógicos sigue sin confirmar: QQ-10).

### Ruta crítica y orden recomendado en el Sprint 4

PJ-012/013 · **IP-004** · **IP-005** · historias del prompt · IP-006 · …. Mapeo: las Logic puras **014, 015, 017, 018** (y luego 016, 019, 020) no esperan a IP-005 y entran junto a PJ-012/013 e IP-004; **021** cuando IP-005 (`get_target()`) esté cerrada; **022 y 023** después de 021; **024** al final, tras IP-006/IP-007 (relleno `p` y aviso reales; antes, con estados forzados de dev). **025** no entra hasta resolver la pregunta abierta. Capacidad: ~12 días de prompt compiten con la cola de 7 (IP-006…011) y con PJ/EC/EB: si no cabe, el corte lógico es dejar 022–024 para el Sprint 5 y mantener 014–021 (lógica probada) en el 4.

## Diferido / bloqueado

| Qué | TR / AC | Bloqueado por | Salida |
|-----|---------|---------------|--------|
| Escala F2 y suelo de texto en píxeles del prompt | TR-prompt-015 (parte), TR-prompt-018 (parte); AC-24-14 (píxeles) | **Decisión de diseño** (GDD 24 frente a ADR-0007 D7 / ADR-0016 G-4; QQ-10) — historia 025 | `TODO(ui-owner)`: enmendar GDD 24 o ADR-0007 |
| Fuente viva del tamaño de viewport lógico para `ViewMetrics` (`ViewportMapper`, OI-5) | TR-interact-015 (parte) | desbloqueado: lo aporta la historia 015 | 011 puede pasar de W, H inyectados al adaptador real tras 015 |
| Viewport lógico `canvas_items`/`expand` en 16:10 (S-0011-C NEEDS_WINDOWED) | AC-32 (H=1200 medido en ventana), AC-V6 16:10 | NEEDS_WINDOWED (prototipo jugable) | se mide en 013/024 si se puede; si no, `NOT ASSESSED` anotado |
| Atkinson Hyperlegible, glifos reales, líneas reales (SP-16A/D/E) | AC-24-14, AC-24-22 | NEEDS_WINDOWED; la fuente no está en el repo | capturas «fuente provisional» en 024 |

## Fuera del alcance de M1 (no por ADR)

- Inspección en mano `V05` (TR-interact-019; AC-17…AC-21, AC-20b, AC-V4): recorte 6 del hito.
- Vistas `D01a`–`D01d` de la caja (AC-26c, AC-27f, AC-V6 sobre `D01a`): sala D fuera de M1. El
  mecanismo de vista se prueba con receptores de prueba y con el panel de P1 (épico puzles-marco-y-p1).
- Lectores `C06`/`C07`/`D06` y ascensor `C08` (AC-26d): puertas B/D fuera de M1.
- `R01` de dos páginas (AC-23) entra solo como prueba unitaria con catálogo de prueba (008).
- Criterios de experiencia AC-X1/X2/X3: playtest de M5; AC-X2b sí entra (unitario, 006).
