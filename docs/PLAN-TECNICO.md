# Plan de acción técnico · Slice «Turno de noche»

**Base:** `design/slice/slice-v0.3.md` (fuente de verdad del slice, según `CLAUDE.md`) · **Motor:** Godot 4 (ref. 4.7) · **Objetivo:** build jugable de ~15–30 min según el jugador (a medir en playtest) + vídeo/tráiler para financiación.
**Estado:** propuesta para aprobar. Nada de lo de abajo está implementado todavía.

## 1. Decisiones técnicas propuestas

| Tema | Propuesta | Por qué |
|---|---|---|
| Motor / versión | Godot 4.7 (último parche estable) | Ya elegido. Jolt es el motor de física por defecto desde 4.6. |
| Lenguaje | **GDScript** tipado | Iteración más rápida para un equipo pequeño; todo el slice es lógica de estado e interacción, sin cuellos de botella de CPU. C# solo si el equipo ya lo domina. |
| Render | **Forward+** (Vulkan/D3D12) | El slice vive de luz, reflejos y atmósfera (§4, §15): SDFGI/luces volumétricas/SSR compensan el low poly. Plataforma PC, así que no hace falta el renderer Mobile. |
| Física | Jolt, solo para el jugador y colisiones estáticas | No hay físicas complejas; los objetos «físicos» (piezas, fichas) se mueven por código. |
| Datos | JSON en `assets/data/` (líneas, flags, puzles, ítems) | Los IDs del documento (`VO_G_12A`, `caja_c1`…) pasan a ser claves; QA, subtítulos y localización los referencian. |
| Texto | Claves de traducción desde el primer día (resuelve D-10 a favor) | Coste casi nulo ahora; evita reescribir luego. Solo se entrega español. |
| Tests | gdUnit4 para lógica pura (flags, puzles, guardado, llamada) | Lo importante del slice es la máquina de estados, y es testeable sin escena. |
| Build | Export Windows + Linux con presets en repo; CI en GitHub Actions | Criterio de aceptación 9 y entrega a inversores. |

Se fijan formalmente con `/setup-engine godot 4.7` y ADRs (`/architecture-decision`).

## 2. Arquitectura

### 2.1 Autoloads (`src/core/`)
- **`EventBus`**: señales globales tipadas (`puzzle_solved(id)`, `flag_changed(name, value)`, `door_opened(id)`, `line_requested(id)`…). El documento ya nombra `EV_PUZZLE_SOLVED_<ID>`.
- **`GameState`**: todos los flags de Anexo D.2 con tipos (bool/int/enum). Única fuente de verdad; todo lo demás reacciona a `flag_changed`.
- **`SaveSystem`**: serializa `GameState` + escena actual. Autoguardado en los puntos de D.3 (puerta, compartimento, inicio de llamada). Casos de reanudación: llamada pendiente, `pendiente_revelacion`.
- **`Settings`**: remapeo, volúmenes (voces/efectos/música por separado), subtítulos, «reducir sobresaltos».
- **`AudioDirector`** (`src/audio/`): buses voz/SFX/música/ambiente, capas de lluvia por zona, silencios de puzle.
- **`SubtitleService`** (`src/ui/`): se alimenta de `lines.json`; cada línea sonora tiene su subtítulo (criterio 8).

### 2.2 Módulos de juego
- **Jugador (`src/player/`)**: `CharacterBody3D`, ojos a 1,62 m, FOV 70°, sin sprint ni agacharse; manos como rig/animaciones (`ANIM_*`). Mando y teclado vía `InputMap`.
- **Interacción (`src/interaction/`)**: raycast desde la cámara contra objetos con un componente `Interactable` (estados, prompt contextual, pulsación larga para leer, inspección con rotación en mano). Un único botón contextual (§5).
- **Puzles (`src/puzzles/`)**: clase base `PuzzleBase` con estados `BLOQUEADO/ACTIVO/RESUELTO` y señal de resolución; una subclase por puzle (cronología, lámparas, encaje, tablero, espejo, decisión). Reglas y soluciones **en JSON** (`assets/data/puzzles/`), no en código, para ajustar tolerancias (40° ±3°/±6°, radio de encaje 0,04/0,10 m) sin recompilar. «Sin fallo bloqueante» es una invariante del diseño: ningún estado de fallo es terminal.
- **Pistas (`src/systems/`)**: `HintService` con tres niveles por puzle, accesible desde pausa y gesto de cámara; se alimenta de los textos del Anexo B.
- **Mundo (`src/world/`)**: puertas, lectores de tarjeta (C06/C07), zonas de disparo (T-PAS-1/2), luminarias C03 (parpadeo/apagón).
- **Narrativa (`src/narrative/`)**: `SceneDirector` que ejecuta las escenas 1–8 como secuencias de eventos con tiempo (Anexo C); `CallController` para la llamada (variantes A/B/C, respuesta A–D, silencio a 20 s sin elección automática); `EndingController` para la recepción.
- **UI (`src/ui/`)**: ordenador (correo + búsqueda «transición»), impresora, menú de pausa, mensajes del teléfono, bolsillo visual (sin menú de inventario).

### 2.3 Escenas
Una escena continua de planta (`scenes/levels/floor9.tscn`) con puertas como disparadores y Recepción como escena aparte cargada tras la escena 7 (Anexo A.0). Props reutilizables en `scenes/props/`, un `.tscn` por puzle en `scenes/puzzles/`.

## 3. Soluciones técnicas para los puntos difíciles

| Punto | Enfoque | Riesgo |
|---|---|---|
| Memorando en espejo (P2) | Un `ShaderMaterial` sobre el cristal con tres máscaras; cada fragmento se revela (fundido 0,8 s) según la posición de su lámpara. Sin trazado de rayos real. | Bajo |
| Reflejo retardado (escena 4) | No reflejo real: una silueta/«fantasma» que reproduce el buffer de posición del jugador con retardo de 0,6 s, visible solo en las ventanas del patio de luces durante 3 s. | Bajo |
| Espejo de la diferencia (P5) | Composición de dos texturas en un shader (foto de pared sobre foto de caja) con rotación del marco; la tolerancia es un valor de datos. | Medio (feeling del giro) |
| Encaje de foto (P3) | Arrastre con raycast sobre un plano; snap a ≤0,04 m (0,10 m en modo asistido). | Bajo |
| Voz del Guardián | Pipeline fuera del motor (grabación → conversión → OGG/WAV); en el motor, solo `AudioStreamPlayer` por ID. | Medio-alto (calidad, ver §22) |
| Atmósfera con low poly | **Prueba de 30 segundos primero**: pasillo con luz, lluvia en ventana, drone y parpadeo (mitigación del §22). | Medio |

## 4. Hitos y calendario

Las semanas del documento (§23) son el punto de partida; añadimos una semana 0 y un cierre pulido, porque el objetivo es enseñarlo.

| Hito | Contenido | Salida / criterio |
|---|---|---|
| **S0 · Setup** | `/start`, `/setup-engine`, `project.godot`, autoloads vacíos, input map, CI + export, gdUnit4 | Proyecto abre, corre y exporta una escena vacía en Windows y Linux. Decisión D-16 cerrada. |
| **S0b · Test de atmósfera** | Pasillo de 30 s con luz/lluvia/audio | Aprobación visual: ¿transmite el tono? Decide la inversión en arte. |
| **M1 · Prototipo gris (S1)** | Despacho, pasillo, Archivo, ordenador/impresora, **puzle 1**, puerta A | Se juega de la escena 1 a la 3 sin texturas. |
| **M2 · Caja (S2)** | Despacho D, caja, **puzles 3–6** con dependencias y recompensas; Sala B con **puzle 2** | Todos los flags de D.2 funcionan; tests de lógica verdes. |
| **M3 · Llamada (S3)** | Apagón, llamada, 3 variantes de carta × 4 respuestas, Recepción y final | Slice completo de principio a fin en gris, con audio provisional. |
| **M4 · Pase de calidad (S4–S5)** | Arte final (texturas, shaders, luces), VO final, SFX, subtítulos, accesibilidad, pistas | Criterios 1, 2, 3, 8 cumplibles. Perfilado en equipo de referencia. |
| **M5 · Playtest y demo (S6)** | 5 jugadores sin explicaciones; correcciones; build + vídeo/tráiler | Criterios 4–7 medidos; gate `/gate-check`; paquete para financiación. |

Estimación gruesa: **6–7 semanas** con dedicación completa de una persona + herramientas de IA para arte/audio; sujeta a `/estimate` y `/sprint-plan` con el equipo real.

## 5. Calidad y riesgos técnicos

- **Tests:** unitarios de `GameState`, cada puzle (soluciones válidas e inválidas, sin softlock), `CallController` (12 combinaciones de carta/respuesta + silencio), guardado/restauración en cada punto de D.3.
- **Verificación de guion:** script en `tools/` que cruza `lines.json` con subtítulos y audio (nadie debería oír una línea sin subtítulo).
- **Rendimiento:** definir equipo de referencia (§21) en S0; presupuesto inicial propuesto: 60 fps a 1080p con luces dinámicas limitadas por sala.
- **Licencias de IA:** `docs/decisions/ai-asset-register.md` con herramienta, fecha y plan por asset desde el primer asset generado (§18).
- **Hechos que dependen de decisión:** D-04 (nombre de Vera), D-08 (voz), D-14–D-16. Los textos y la lógica deben leerlos de datos para que cambiarlos no toque código.

## 6. Primeros pasos con las skills

Orden recomendado en una sesión de Claude Code abierta en la raíz del repo:

1. **`/start`** — elige «ya tengo un diseño»; indica que el documento está en `design/slice/slice-v0.3.md`. Configura `modes.rigor` (recomendado: `standard`; el slice está muy especificado y se enseñará fuera, así que conviene algo más que `minimal`).
2. **`/setup-engine godot 4.7`** — fija motor, lenguaje y presupuestos; actualiza `project.yaml`.
3. **`/art-bible`** — fija el low poly con luz cálida/fría y la paleta del §15 (debe ir antes de `/map-systems`).
4. **`/map-systems`** — descompone el slice en sistemas (estado, interacción, puzles, llamada, audio, pistas…) y su orden de diseño.
5. **`/design-system`** (por sistema) o **`/quick-design`** — GDD de cada sistema a partir del documento.
6. **`/create-architecture`** → **`/architecture-decision`** (ADRs de motor, datos, guardado) → **`/create-control-manifest`**.
7. **`/create-epics`** → **`/create-stories`** → **`/sprint-plan`**.
8. **`/dev-story`** ↔ **`/story-done`** por historia; **`/gate-check`** entre fases; **`/playtest-report`** tras M5.

## 7. Qué necesito de ti para arrancar

1. **D-16 (orden de la caja):** ¿cadena c1→c3→c4 con c2 libre (Anexo B) o libre del todo (§8/§13.3)?
   — **Respondida 2026-11-10:** cadena c1→c3→c4 con c2 libre (el diseño actual, Anexo B).
2. **Lenguaje:** ¿GDScript (propuesto) o C#?
   — **De facto (2026-11-10):** GDScript, fijado en `project.yaml`; no hubo respuesta explícita en la ronda del 2026-11-10 (QQ-02).
3. **Equipo:** ¿cuántas personas y qué perfiles (código, arte, audio)? Determina `modes.rigor`, `team.size` y el calendario.
   — **Respondida 2026-11-10:** una persona, con agentes de Claude.
4. **Equipo de referencia** para pruebas (CPU/GPU/RAM mínimos).
   — **Respondida 2026-11-10:** el portátil de desarrollo (Intel Core Ultra 7 265H, GPU integrada Intel Graphics, 15,4 GB de RAM compartida, pantalla 1920×1200 a 60 Hz). Presupuestos y método de medida: ADR-0019.
5. **Fecha objetivo** de la demo de financiación, para ajustar S4–S5.
   — **Respondida 2026-11-10:** sin fecha fija; se planifica por hitos con plazos relativos y orden de recorte. Las 6–7 semanas de § 4 quedan como estimación, sin fecha.
