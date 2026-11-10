# Interaction Pattern Library

> **Status**: In Design (todos los patrones en estado Draft: nada está implementado; el proyecto está en preproducción)
> **Author**: ux-designer (`/ux-design patterns`, modo autónomo; consolida decisiones ya tomadas, no inventa comportamientos)
> **Last Updated**: 2026-11-10
> **Version**: 0.1
> **Engine**: Godot 4.7.2
> **UI Framework**: Nodos `Control` sobre ocho `CanvasLayer` fijos (ADR-0016 D1)
> **Related Documents**:
> - `design/accessibility-requirements.md`: compromisos de accesibilidad (nivel Estándar)
> - `design/art/art-bible.md` (§4.5, §7): estilo visual, tipografía, iconografía, animación (decide art-director, no este documento)
> - `design/gdd/entrada-y-controles.md` (1), `prompt-de-interaccion.md` (24), `menu-de-pausa.md` (25), `subtitulos.md` (26), `pantalla-de-titulo.md` (27), `interaccion-e-inspeccion.md` (7), `opciones-de-accesibilidad.md` (30), `ajustes-persistentes.md` (6)
> - `docs/architecture/adr-0006-…` (entrada), `adr-0007-…` (ajustes y escala de UI), `adr-0016-…` (subtítulos y texto de UI)
> - `design/ux/[pantalla].md`: specs por pantalla (**aún no existen**: fase posterior)
>
> **Template**: Interaction Pattern Library

> **Por qué existe.** Las specs por pantalla dirán «usa el patrón P-05» en lugar de repetir foco, teclado, mando y texto. Este documento **consolida** lo ya decidido en los GDD y ADR citados; si una fila difiere de su fuente, **manda la fuente** y se corrige aquí. Lo abierto se marca **«decisión pendiente del usuario» (DPU)**; lo que ninguna fuente verifica, **NO VERIFICADO**.
>
> **Convenciones de entrada.** Las acciones lógicas son las de 1 (`interactuar`, `atrás`, `pausa`, `seleccionar`, `mover`, `mirar`, `ui_arriba/abajo/izquierda/derecha`, `ui_aceptar`, `ui_atrás`). Las teclas por defecto: `E`/clic izq. (`interactuar`), clic der. (`atrás`), `Esc` (`pausa` y `ui_atrás`), flechas y `Enter` (`ui_*`); mando: botón sur (`A`/`✕`), botón este (`B`/`○`), `Start`, cruceta/stick izquierdo. Todas las asignaciones del mundo son **reasignables**; las `ui_*` son **fijas** (1 reglas 15 y 16). Ningún patrón asume una tecla concreta: los glifos se resuelven con `get_binding_label` (P-21).
>
> **Estados de patrón**: Draft (especificado, sin implementar), Stable (implementado y validado), Deprecated.

---

## Overview

### How to Use This Library

- **Si diseñas una pantalla:** busca el patrón en el catálogo antes de inventar uno. Si ninguno encaja, propón uno aquí antes de escribir la spec.
- **Si implementas:** cada patrón nombra su GDD/ADR de origen (`Origen`) y sus requisitos de accesibilidad. Los componentes de código ya nombrados en ADR-0016 D9 (`MenuList`, `ToggleRow`, `SelectorRow`, `SliderRow`, `BindingRow`, `NoticeLine`, `ConfirmDialog`, `MessageDialog`, `CaptureDialog`, `WarningsScreen`) y `OptionsComponent` (D8) son los de este catálogo.
- **Si revisas:** «botón normal» o «como siempre» no es una referencia válida; se cita el patrón por ID.

### Principios transversales (aplican a todos los patrones)

1. **Todo es operable con un solo dispositivo** (solo teclado y ratón o solo mando). Ningún control exige gesto compuesto, doble pulsación ni reacción en una ventana de tiempo (1 regla 4; 30 regla 16).
2. **El foco y el estado nunca dependen solo del color**: forma, texto, icono, posición (art bible §4.5, §7.6).
3. **Un glifo nunca va solo**: siempre con su texto (24 regla 12).
4. **Texto**: Atkinson Hyperlegible Next; suelo **24 px lógicos** (30 regla 26); contraste texto ≥ 4,5:1 y bordes/foco ≥ 3:1 (30 regla 25). Reflow, no recorte (30 regla 11). **DPU QQ-10**: suelo lógico o real a 720p.
5. **Los ajustes se aplican al instante**, sin «Aplicar» ni «Cancelar cambios» (25 regla 11; 6 regla 5).
6. **Sin etiquetas de dificultad, sin banners, sin colores de alarma, sin rojo como señal** (30 regla 3; art bible §4.5).
7. **Márgenes seguros de 5 %** por lado; HUD, prompt, subtítulos y `SceneUi` anclados a un rectángulo central 16:9 (`SafeArea169`, ADR-0016 D2).
8. **Fundido con `reducir_movimiento`: 100 ms fijo** (rango único 50–150 ms, 30 regla 27).

---

## Pattern Catalog

### Pattern Catalog Index

| ID | Pattern Name | Category | Description | Used In (pantallas futuras) | Status |
|----|-------------|----------|-------------|------------------|--------|
| P-01 | Foco dual (teclado, mando, ratón) | Navigation | Un solo cursor de foco para los tres dispositivos | Todos los menús | Draft |
| P-02 | Lista de menú (`MenuList`) | Navigation / Layout | Filas verticales sin wrap, foco inicial y retorno | Raíz de pausa, título, pantallas de nivel 2 | Draft |
| P-03 | Fila de ajuste (Toggle / Selector / Slider) | Input | Valor siempre en texto, «Restablecer» por fila | Sonido y pantalla, Accesibilidad, Manejo | Draft |
| P-04 | Repetición al mantener (`HoldRepeat`) | Input | Pasos repetidos en deslizadores | P-03 | Draft |
| P-05 | Diálogo de confirmación y de mensaje | Modal | Modal con foco inicial seguro | Volver al título, Nueva partida, restablecer, conflictos de asignación | Draft |
| P-06 | Fila y captura de reasignación | Input | Dos ranuras por acción y diálogo de captura | Controles | Draft |
| P-07 | Línea de aviso (`NoticeLine`) | Feedback | Icono + texto no enfocable | Pausa, título, Controles | Draft |
| P-08 | Atrás / Pausa por contexto | Navigation | Qué hace cada botón en cada contexto | Todas | Draft |
| P-09 | Anillo de interacción | Game-Specific (Context Action Prompt) | Presencia, progreso y rechazo sin punto de mira permanente | Exploración | Draft |
| P-10 | Pulsación prolongada y alternar | Input | `leer`, `mantener`, `agarrar`, `rotar` con alternativa | Exploración, puzles | Draft |
| P-11 | Pie de texto | Feedback | Una línea de ambiente, sin información necesaria | Exploración | Draft |
| P-12 | Inspección de objeto | Game-Specific | Objeto en la mano, mirada gira el objeto | `V05` | Draft |
| P-13 | Lectura de documento | Game-Specific | Pantalla de lectura con páginas | Documentos, correos, libro de visitas | Draft |
| P-14 | Vista cercana de puzle | Game-Specific | Cursor, picking 2D y gestos | Puzles 1 a 6, panel de la caja | Draft |
| P-15 | Cursor virtual del mando | Input | Dos sticks, velocidad, atracción asistida | P-14, P-16, P-17, menús con mando | Draft |
| P-16 | Ordenador y campo de texto | Game-Specific | Cursor + texto con teclado físico o en pantalla | Ordenador (19) | Draft |
| P-17 | Opciones de la llamada | Game-Specific | Opciones por foco, sin temporizador | Llamada (22) | Draft |
| P-18 | Subtítulos | Feedback | Banda inferior, ≤ 2 bloques | Todas las escenas con voz | Draft |
| P-19 | Pausa: apertura, cierre y velo | Navigation / Modal | Pausa sobre cualquier contexto con guarda | Raíz de pausa | Draft |
| P-20 | Advertencias y arranque | Modal / Navigation | Pantalla de lectura sin cuenta atrás | Título | Draft |
| P-21 | Glifo con texto y token de acción | Feedback | `{accion:<id>}` → glifo + nombre vigente | 24, 25, 26, 30 | Draft |
| P-22 | Rechazo y «sin efecto» | Feedback | Pulso + sonido + pie, sin rojo ni temblor | Exploración, puzles | Draft |
| P-23 | Fundidos y `reducir_movimiento` | Feedback | Duraciones y sustituciones | Todas | Draft |
| P-24 | Panel de pistas | Navigation | Proveedor de 17 dentro de la pausa | Pausa | Draft |
| P-25 | Pestañas de pantalla | Navigation | `ui_izquierda/derecha` cambian pestaña | Controles | Draft |
| P-26 | Reflow y scroll con `escala_texto_ui` | Layout | Nada recortado a 1,50 | Todas | Draft |

---

## Patterns

### Navegación y menús

#### P-01 Foco dual (teclado, mando, ratón)

**Category**: Navigation
**Origen**: ADR-0016 D9 «Focus and hover (dual focus)»; 25 regla 9; 27 regla 15; 4.6 dual focus (ADR-0007 D8, `grab_focus()` = teclado/mando, fuente: referencia de motor).
**Description**: Hay **un solo cursor de foco** (`MenuList` es la fuente de verdad) para los tres dispositivos. El ratón al pasar sobre una fila mueve el cursor y llama a `grab_focus()`; el clic mueve y activa; el cursor virtual (P-15) entra por el mismo camino. El anillo de foco se dibuja desde el cursor, no con el estilo de hover del motor.

**Specification**:
- Teclado: `ui_arriba/abajo` mueven por filas; `ui_aceptar` (`Enter`) activa.
- Mando: cruceta o stick izquierdo mueve; botón sur activa.
- Ratón: hover mueve el foco; clic activa; los deslizadores se arrastran.
- Foco visible: borde ≥ 3:1 **más** forma (corchete o subrayado) **más** brillo; nunca solo color (25 regla 9; art bible §4.4, §7.2).
- **En el título**, el ratón no cambia el foco al reaparecer el cursor hasta que se mueve (27 regla 15).
- Nombre accesible = texto visible (`A11y.set_accessible_name`); **NO VERIFICADO** el API de AccessKit (ADR-0007 SP-4).

**When to Use**: En todo menú y diálogo.
**When NOT to Use**: En el mundo (exploración, vista cercana): ahí rige el cursor de P-14/P-15.
**Nota de decisión**: ADR-0016 D9 **anula** ADR-0007 D8.3 («el hover no debe mover el cursor») por contradicción C2; se registra aquí para no reabrirla.

---

#### P-02 Lista de menú (`MenuList`)

**Category**: Navigation / Layout
**Origen**: 25 reglas 9 y 10; ADR-0016 D9 (`MenuList`, `FocusChain.link_vertical(rows, wrap = false)`); 27 regla 7.
**Description**: Lista vertical de filas construida **solo con las filas ofrecidas**. Las filas no ofrecidas **no existen** (no se muestran desactivadas): no hay opción muerta que explicar (27 regla 7; «Pistas» sin proveedor, «Continuar» sin partida).

**Specification**:
- **Sin wrap**: `ui_arriba` en la primera fila no hace nada; el foco se detiene (no hay efecto sorpresa).
- **Foco inicial**: «Reanudar» en la pausa (nunca «Volver al título» ni una fila destructiva); «Continuar» si existe, si no «Nueva partida», en el título.
- **Retorno**: al volver de un nivel 2, foco en la fila que lo abrió; al reabrir el menú vuelve a «Reanudar» (no recuerda pantalla).
- Sostener `ui_arriba/abajo` **no repite** (se descartan los ecos): mantener nunca desplaza el foco hasta una fila destructiva (ADR-0016 D10).
- Teclado: flechas; mando: cruceta/stick; ratón: hover y clic.

**When to Use**: Raíz de pausa, raíz del título, pantallas de nivel 2.
**When NOT to Use**: Cuadrículas (no hay en el slice: sin inventario, slice D.1).

---

#### P-25 Pestañas de pantalla

**Category**: Navigation
**Origen**: 25 reglas 9 y 19 («Controles»: Teclado y ratón, Mando, Manejo).
**Specification**: `ui_izquierda/derecha` cambian de pestaña (25 regla 9); en filas con deslizador/selector esas mismas teclas mueven un paso (P-03). Qué fila consume cada una es **decisión de la spec de «Controles»** (no la fija ninguna fuente). Pestaña por defecto de «Controles» = dispositivo activo (1 regla 3), salvo que el anfitrión pase `pestana_inicial`. Pestaña activa distinguida por marca y texto, no por color.
**Nota**: la plantilla limita a 5–6 pestañas; aquí hay 3.
**NO VERIFICADO**: el conflicto entre `ui_izquierda/derecha` como pestaña y como paso de selector no está resuelto en las fuentes consultadas: la spec de «Controles» debe fijar la regla (ver Gaps).

---

#### P-08 Atrás / Pausa por contexto

**Category**: Navigation
**Origen**: 1 (tabla de contextos, reglas 5, 7, 12, 23); 25 reglas 5 y 6; 27 regla 15; 22 regla 10.
**Description**: «Ir atrás» es el patrón más usado y **nunca se sobrescribe** (reglas de 1). Resumen por contexto (acción física: `atrás` = clic der. / botón este; `pausa` = `Esc` / `Start`):

| Contexto | `atrás` (clic der. / B) | `pausa` (`Esc` / Start) |
|---|---|---|
| `exploración` | Emite `repasar_bolsillo` (un documento por pulsación; no repite al mantener) | Abre la pausa |
| `inspección` | Suelta el objeto | Abre la pausa |
| `lectura` | Cierra solo la lectura superior | Abre la pausa |
| `vista cercana` | Sale de la vista (o resolver el puzle) | Abre la pausa |
| `ordenador` | Sale del ordenador. Con el campo de texto enfocado, `Esc` sigue siendo `pausa` y no cancela el texto (1 regla 20) | Abre la pausa |
| `llamada` | **No hace nada** (no hay colgar manual) | Abre la pausa |
| `menú` (pausa) | `ui_atrás` (`Esc`/botón este) sube **un** nivel; solo desde la raíz reanuda | Igual que `ui_atrás`: sube un nivel; solo desde la raíz reanuda |
| `menú` (título) | `ui_cancel` no hace nada (no salir por accidente) | No cierra el título |
| `sin control` | Se descarta | Única acción aceptada |
| Transición bloqueante | Se descarta (excepto `repasar_bolsillo`, decide 7) | Se acepta |

**Specification**: una pulsación produce **un** efecto (el menú consume el evento; 25 regla 6). La pulsación que **cierra** un modo no lanza `repasar_bolsillo` (1 regla 23). La que **cierra** el menú no llega al mundo hasta soltar y volver a pulsar.
**Accesibilidad**: `atrás` conserva siempre al menos una asignación no imprimible (1 regla 17); se avisa si se asigna una tecla imprimible (P-06).

---

#### P-19 Pausa: apertura, cierre y velo

**Category**: Navigation / Modal
**Origen**: 25 reglas 1 a 7; 1 reglas 7, 21 y 22; ADR-0016 D1 (capa `PauseVeil` 20, `MenuLayer` 40).
**Description**: La pausa abre sobre cualquier contexto **salvo durante una carga de escena** (entonces se abre al terminar). Detiene el tiempo de juego en el mismo fotograma. Tres causas: el jugador (`pausa`), pérdida de foco de la ventana y desconexión del mando activo.

**Specification**:
- Velo azul noche con ligera desaturación; fundido de apertura **350 ms** (100 ms con `reducir_movimiento`); sin parpadeo después. El menú acepta entradas desde el primer fotograma (solo el fundido es visual).
- Guarda de apertura de 0,15 s (las acciones de menú se ignoran) para que la pulsación que abre no cierre.
- Cierre: «Reanudar», `pausa` o `ui_atrás` desde la raíz; en nivel 2 o diálogo suben un nivel.
- Pérdida de foco: se abre sola, también durante una transición bloqueante.
- Mando desconectado: panel con un solo botón «Reanudar» (o línea fija en cabecera si el menú ya estaba abierto); sin cuenta atrás; teclado y ratón valen para reanudar.
- La pausa **no** muestra tiempo jugado, pistas usadas ni intentos (25 regla 8).
- Línea «guardado en riesgo» cuando 5 lo avisa (P-07). No hay guardado manual ni «salir del juego» (25 regla 29).

**When NOT to Use**: En el título (la base de la pila es el menú del título de 27).

---

#### P-24 Panel de pistas

**Category**: Navigation
**Origen**: 25 regla 14; ADR-0016 D7.
**Specification**: 17 registra un proveedor de panel. **Sin proveedor la fila «Pistas» no existe** (no desactivada). El panel es nivel 2 con las reglas de foco y retorno de P-02; `ui_atrás` sube a la raíz y el panel **nunca** maneja `ui_atrás`/`pausa`. 25 no recibe contadores de pistas y no guarda nada. Contenido (niveles, qué puzle) es de 17.

---

### Entradas de ajuste

#### P-03 Fila de ajuste (Toggle / Selector / Slider)

**Category**: Input
**Origen**: 25 reglas 11, 12, 16 y 18; ADR-0016 D9 (`ToggleRow`, `SelectorRow`, `SliderRow`); 30 reglas 5 a 7; 6 regla 1.
**Description**: Cada ajuste es una fila con **nombre, valor en texto, una línea de ayuda** y su «Restablecer». Controles: conmutador (Sí/No), selector de 2 a 3 valores (texto), deslizador con pasos (valor en texto).

**Specification**:
- Valor **siempre en texto** («Sí»/«No», «Medio», «35 %», «Silencio» en 0, «1,25×», «70°»). Nunca solo posición, color o icono.
- Teclado/mando: `ui_aceptar` activa o cambia el conmutador; `ui_izquierda/derecha` cambian un paso en selector y deslizador (P-04). Ratón: clic y arrastre.
- Se escribe en 6 **al instante** (6 regla 5). Si 6 ajusta o rechaza el valor, la fila **lo relee** y muestra el real; sin mensaje de error (25 regla 11; 6 regla 6).
- La fila se refresca si el valor cambia fuera (p. ej. `Alt+Intro` y `modo_ventana`).
- Deslizadores de volumen: tras soltar o cambiar de paso, muestra de audio del bus (23). `subtitulos_*`: vista previa fija `UI_SUB_MUESTRA`.
- Orden de la pestaña «Accesibilidad» (30 regla 6): (1) Lectura: `escala_texto_ui`, `icono_grande`, `etiqueta_accion_visible`, `multiplicador_pie`, `pie_persistente`; (2) Confort y movimiento: `reducir_movimiento`, `reducir_sobresaltos`, `balanceo_camara`, `campo_vision`; (3) Ayudas de puzle: `asistencia_encaje`, `asistencia_rotacion`; (4) «Restablecer todos» (18 claves). Después, línea de remisión no enfocable.
- «Sonido y pantalla»: tres volúmenes, `subtitulos_activos`, `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante`, `modo_ventana` (30 D30-7).
- Sin etiquetas de dificultad, logros ni «modo fácil» (30 regla 3).

**When NOT to Use**: Más de 3 valores en un selector (no hay casos en el slice).

---

#### P-04 Repetición al mantener (`HoldRepeat`)

**Category**: Input
**Origen**: 25 regla 12 y F1; ADR-0016 D10; ADR-0006.
**Specification**: Mantener `ui_izquierda/derecha` sobre deslizador repite pasos tras `repeticion_inicial_s` (0,4 s†) a `repeticion_s` (0,12 s†) por paso; al soltar, para. Una pulsación = un paso. Se cancela al cambiar el foco, el contexto, perder el foco de la ventana o cerrar. **No** hay repetición en `ui_arriba/abajo`. No la afecta «alternar en lugar de mantener» (es navegación). Valores † a validar en playtest.
**Accesibilidad**: nunca exige mantener: cada paso se logra con una pulsación.

---

#### P-06 Fila y captura de reasignación

**Category**: Input
**Origen**: 25 reglas 19 a 26 y F2; 1 reglas 15 a 17 y 20; ADR-0006 (validador).
**Description**: «Controles» lista las acciones físicas reasignables (`mover`, `mirar`, `interactuar`, `pausa`, `atrás`, `seleccionar`) por dispositivo, con **dos ranuras**, «Sin asignar» en texto y «Restablecer» por acción. No existen filas para gestos derivados ni `ui_*`; en su lugar, leyendas de texto no enfocables (25 regla 20).

**Specification**:
- Activar una ranura → diálogo de tres opciones: «Cambiar», «Quitar», «Cancelar».
- «Cambiar» → diálogo **Capturando**: «Pulsa la nueva tecla o botón». Escucha **solo el dispositivo de la pestaña**; empieza 0,25 s tras **soltar** la entrada que lo abrió. `Esc` cancela en teclado; en «Mando» `ui_atrás` **no** cancela (es un valor legítimo): cancela el temporizador (8 s†, visible en texto «Se cancela en 5 s»), `Esc` del teclado o la desconexión.
- Conjuntos `mover` y `mirar`: un texto único («W A S D»); en teclado se piden cuatro direcciones con «1 de 4»; en mando se elige stick o cruceta.
- Resultados (25 regla 23): asignada; conflicto con **Intercambiar/Cancelar** (foco en Cancelar); conflicto sin intercambio posible o con conjunto (solo «Aceptar»); rechazo por mínimo de `interactuar`, `atrás`, `pausa`; misma entrada en las dos ranuras. «Quitar» se desactiva con «Sin efecto» en texto en la única asignación no imprimible de `atrás`.
- Aviso permanente (P-07) si `atrás`, `interactuar` o `pausa` van a una tecla imprimible (escribe en el buscador del ordenador).
- «Restablecer» por acción sin confirmación; por dispositivo, con confirmación (P-05).
**Accesibilidad**: un jugador solo con mando nunca queda atrapado en la captura (temporizador visible).

---

#### P-10 Pulsación prolongada y alternar

**Category**: Input
**Origen**: 1 reglas 4, 10, 13, 14 y F6; 7 reglas 9 y 13; 24 regla 6; 30 regla 15.
**Description**: `interactuar` es el único botón del mundo. Sin `verbo_largo`, el verbo corto se dispara **al pulsar**; con `verbo_largo` (`leer`), la decisión es al soltar o al cumplirse `t_hold`. `seleccionar` da `agarrar` (mantener y mover), `rotar` (mantener y mover en horizontal) y `mantener` (mantener más allá del umbral): decide la primera señal (desplazamiento ≥ `d_arrastre` o `t_hold`).

| | Teclado y ratón | Mando |
|---|---|---|
| Activar | `E` o clic izq. al pulsar | Botón sur al pulsar |
| `leer` | Mantener `E`/clic hasta `t_hold`; el anillo se rellena (P-09) | Mantener botón sur |
| `agarrar`/`rotar` | Mantener clic y mover ratón (rotar: 1 px = 0,25°) | Mantener botón sur y mover stick (rotar: eje horizontal con mayor magnitud) |
| **Alternar en lugar de mantener** (ajuste de `controles`, defecto desactivado) | Una pulsación inicia, la siguiente termina; `atrás` cancela | Igual |

**Accesibilidad**: con alternar, todos los gestos se completan sin mantener (BLOCKING, 30 AC-30-09). **Propuesta a validar en playtest** (1 regla 14): `leer` y `mantener` solo se completan si la segunda pulsación llega tras `t_hold`.
**When NOT to Use**: Para exigir mantener varios botones; ninguna acción lo hace.

---

#### P-15 Cursor virtual del mando

**Category**: Input
**Origen**: 1 regla 12, F5a y F5b; ADR-0006 D9; 1 Visual/Audio.
**Specification**: Con mando, en `vista cercana` y `ordenador` el cursor se mueve con **cualquiera** de los dos sticks; en `llamada` y `menú`, solo con el **derecho** (el izquierdo y la cruceta mueven el foco `ui_*`). Velocidad ajustable, atracción asistida hacia el elemento más cercano (desactivable; limitada a la mitad de la velocidad del cursor: mover el stick siempre vence). Forma **no circular** (el círculo es de la luz del mundo y del anillo de interacción; **diseño visual pendiente de art-director**). Visible con mando y ratón. Con ratón es el cursor real, libre dentro de la ventana. Se dibuja sobre los menús y bajo la cortina (capa 50).
**Excepción**: en `llamada` el cursor está **oculto** hasta que 22 muestra las opciones (**riesgo abierto: DPU OQ 5 de 30**).

---

### Exploración y mundo

#### P-09 Anillo de interacción

**Category**: Game-Specific (Context Action Prompt)
**Origen**: 24 reglas 1 a 16; ADR-0016 D6; art bible §7.3; 30 (`icono_grande`, `etiqueta_accion_visible`).
**Description**: Solo hay anillo cuando hay un objeto interactuable apuntado. **No hay punto de mira permanente**: sin objetivo no se dibuja nada.

**Specification**:
- Centro de pantalla, fijo; 28 px a 1080p (anillo), versión grande 48 px con `icono_grande`; blanco frío con filo azul noche.
- Aparece 250 ms, desaparece 150 ms (100 ms con `reducir_movimiento`). Si el objetivo cambia de objeto a objeto, no parpadea (fundido cruzado de etiqueta 120 ms).
- Progreso de `leer`: relleno horario del propio anillo (no barra); si se suelta antes, se vacía en 100 ms; en alternar permanece entre las dos pulsaciones.
- Pulso de aceptación (80 → 100 %, 120 ms) y de rechazo (P-22).
- **Etiqueta de acción** (`etiqueta_accion_visible`, apagada por defecto): `[glifo] + texto` bajo el anillo (P-21).
- Oculto en `menú`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada` y `sin control`.
- Un objeto deshabilitado no tiene icono ni reacción: no revela interacciones futuras (7 regla 8).
- Teclado y mando: idéntico, solo cambia el glifo de la etiqueta.

---

#### P-11 Pie de texto

**Category**: Feedback (equivalente a Toast)
**Origen**: 24 reglas 21 a 29 y F3; 7 regla 12; 6 (`multiplicador_pie`, `pie_persistente`).
**Specification**:
- Un solo hueco; una petición nueva **sustituye** al pie con fundido cruzado de 150 ms (100 ms con `reducir_movimiento`). Sin cola.
- Abajo-centro, dentro de márgenes seguros; máximo 2 líneas, ancho ≤ 60 %; blanco frío sobre panel azul noche al 85 %; ≥ 28 px y nunca < 24 px; fundidos 250 ms.
- Duración la calcula 7 (F5, con `multiplicador_pie`); `pie_persistente` mantiene el pie hasta que cambie el objetivo o llegue otro. El reloj es de tiempo de juego: la pausa lo detiene.
- **Nunca lleva información necesaria para avanzar**; no se puede releer (L-5 de accesibilidad). Un texto > 90 caracteres no es un pie: es un documento (P-13).
- Cuando hay subtítulos visibles, el pie sube sobre ellos; nunca los solapa (24 regla 24).
- `UI_BOLSILLO_AYUDA` (`{accion:atrás}: revisar los papeles`): una vez por sesión (20), se retiene hasta volver a `exploración`.
- Solo en `exploración`; los pies de objeto se descartan al salir.

**When NOT to Use**: Decisiones, errores accionables, información crítica.

---

#### P-22 Rechazo y «sin efecto»

**Category**: Feedback
**Origen**: 24 regla 18 y 20; 7 regla 11; 30 regla 18.
**Specification**: Todo rechazo comparte un **pulso** del anillo (80 % → 40 % → 80 %, 120 ms; opacidad, sin movimiento) + `SFX_CLICK_SUBTLE` (lo emite 7) + pie `OBJ_<id>` si el objeto lo tiene. **Sin rojo, sin temblor, sin texto de error.** Tope: ≥ 340 ms entre pulsos (≤ 2,9/s), por debajo de 3 destellos/s (30 regla 18). No hay pulso para: pulsación en enfriamiento o transición, `repasar_bolsillo` sin documentos. La comprensión no depende del pulso (el sonido y el pie lo redundan).

---

#### P-12 Inspección de objeto

**Category**: Game-Specific
**Origen**: 7 reglas 13 a 15; 1 regla 11.
**Specification**: `INSPECCION_MANO` pide el contexto `inspección`: mano alcanza (≤ 0,5 s), sostiene el objeto a distancia fija, y `mirar` (ratón o stick derecho) **gira el objeto** sin límite de ángulo ni inercia. `atrás` lo suelta. Mientras entra y sale (≤ 0,9 s) solo se acepta `pausa`. El mundo sigue vivo: inspeccionar no pausa. Sin inventario ni menú de objetos. En el slice solo `V05` (peluche) es sostenible; solo objetos pequeños (≤ 0,20 m de radio).
**Accesibilidad**: la información oculta (la pegatina de `V05`) es geometría real: revela girando; no depende de color.

---

#### P-13 Lectura de documento

**Category**: Game-Specific
**Origen**: 7 reglas 16 a 18; 20; 30 regla 9; art bible §7.5 (vista de enfoque).
**Specification**: `LEER` abre `lectura` a pantalla completa (modo de enfoque). `interactuar` pasa de página; no hay retroceso: se cierra con `atrás`. En la última página `interactuar` no hace nada. Cerrar antes de tiempo no tiene coste: se relee. Los documentos se releen desde el ordenador y con `repasar_bolsillo` (`atrás` en exploración). Texto escalable con `escala_texto_ui`; contenido y estilo son de 20.
**Teclado/mando**: mantener `E` o botón sur para abrir (o alternar); pasar página con `E`/botón sur; cerrar con clic der./botón este.

---

#### P-14 Vista cercana de puzle

**Category**: Game-Specific
**Origen**: 7 reglas 19 a 23; 1 reglas 12 y 13; 30 reglas 12 a 16; puzles 11 a 16.
**Description**: La cámara se cede a un anclaje perpendicular al plano; el cursor se convierte a coordenadas de la vista con picking 2D contra los elementos que declara el puzle (aritmética, sin colliders 3D). Cada gesto llega al receptor con fases `inicio`/`actualización`/`fin`/`cancelación`.

**Specification**:
- Objetivos de pulsación ≥ **44 px** (`pick_min_px`); P1, P2, P4 y P6 no exigen arrastre ni precisión fina.
- `seleccionar` se entrega **al soltar**; `agarrar` empieza tras 8 px de desplazamiento; la pieza no «salta».
- La inactividad para pistas se mide solo con `inicio`, `fin` y `cancelación`, no con `actualización`.
- Tolerancias de precisión con asistencia: encaje 0,10 m frente a 0,04 m (P3); ±6° frente a ±3° (P5); dwell de 0,8 s en P5 (**DPU OQ 9**).
- Entrada y salida son transiciones bloqueantes (solo `pausa`); tope de 3 s.
- Salir con `atrás` (clic der. / botón este). Las esperas pasivas (rechazo de P1 1,5 s, P3 0,4 s) no exigen acción.
- Feedback visual **y** sonoro en cada acción, correcta o no (slice §16). Sin color como único canal (P3: silueta + contorno; P4: texto; P5: contorno; P6: texto).
**Teclado y ratón**: ratón real; **Mando**: P-15.

---

#### P-16 Ordenador y campo de texto

**Category**: Game-Specific
**Origen**: 1 regla 20; 19 R16; 30 regla 16; art bible §7.6.
**Specification**: Contexto `ordenador` (la cámara se acerca; el jugador no se sienta). Cursor visible. El único campo de texto del slice es la búsqueda «transición»: con el campo enfocado el teclado físico entrega caracteres y consume antes que cualquier acción las teclas imprimibles, `Retroceso`, `Supr`, flechas y `Enter`; `Esc` sigue siendo `pausa`; clic der. y botón este siguen siendo `atrás` y sacan del ordenador. Con **mando**: teclado en pantalla anclado bajo el campo, operado con el cursor y `seleccionar` (19 R16, AC-10a de 19). Sin scanlines, bloom fuerte ni parpadeo. Salida siempre con el mismo botón.
**Accesibilidad**: reasignar `atrás` o `interactuar` a una tecla imprimible escribe en el campo; la pantalla de reasignación lo avisa (P-06).

---

#### P-17 Opciones de la llamada

**Category**: Game-Specific
**Origen**: 22 (reglas 9, 10 y 17); 1 tabla de contextos; art bible §7.6.
**Specification**: Contexto `llamada`. Las opciones aparecen cuando 22 las muestra; mientras tanto `ui_*` y `seleccionar` no producen efecto. **No hay temporizador**; «No responder» es un botón. Foco marcado con corchete, subrayado y posición (no solo brillo); foco inicial determinista; navegación vertical con mando; luminancia máxima del panel limitada durante el apagón. `atrás` y `ui_atrás` no hacen nada (no hay colgar manual). Subtítulos arriba y opciones abajo si coinciden (art bible §7.5). Las opciones no usan la banda inferior reservada a subtítulos. **DPU OQ 5 de 30**: cursor oculto para mando.

---

### Subtítulos y texto de sistema

#### P-18 Subtítulos

**Category**: Feedback
**Origen**: 26 reglas 1 a 29; ADR-0016 D3 y D5; art bible §7.5; 30 regla 10.
**Specification**:
- Banda inferior centrada, ancho 60 %, máximo **2 bloques** de **2 líneas**; un bloque = un hablante. Nunca se mueve con la cámara ni se ancla al altavoz.
- Nombre de hablante escrito `VERA:`, `GUARDIÁN:`, `MEGAFONÍA:` (`subtitulos_hablante`, defecto Sí). Estilo redundante (cursiva, comillas angulares). Sonidos entre corchetes y sin hablante: `[Llanto contenido]`.
- Tamaño `pequeno`/`medio`/`grande` = 24/32/44 px lógicos; fondo `ninguno`/`translucido`/`opaco`. **No** los escala `escala_texto_ui`. Defecto: activados, `medio`, `translucido`.
- Fundido 150 ms (100 ms con `reducir_movimiento`). Duración mínima de lectura; páginas de ≤ 8 s sincronizadas con la voz; con volumen a 0 los tiempos no cambian.
- Se dibujan en todos los contextos con voz, incluida la pausa (sobre el velo).
- «Pausa abierta» congela sus relojes; «carga iniciada» y «descarga total» los vacían sin fundido.
- El pie de texto se desplaza arriba; nunca se tapa un subtítulo.
**Accesibilidad**: contraste 4,5:1 criterio, 7:1 objetivo; nunca el color como único canal.

---

#### P-21 Glifo con texto y token de acción

**Category**: Feedback
**Origen**: 24 reglas 12 a 16 y 27; 1 regla 24; ADR-0016 D4 (`TokenResolver`, `GlyphText`).
**Specification**: Los textos de 18 llevan `{accion:<id>}`; se resuelve a **glifo + texto** de la asignación vigente (`get_binding_label`). Las acciones derivadas se resuelven a su base (`leer`→`interactuar`, `repasar_bolsillo`→`atrás`, `agarrar/rotar/mantener`→`seleccionar`). Con dos asignaciones se muestra la primera por orden de alta. Se vuelve a resolver al cambiar de dispositivo, tras «pausa cerrada» y cuando cambia la revisión de asignaciones, **sin reiniciar relojes**. Si falla, se muestra el nombre de la acción («Atrás»); **nunca** la clave ni el token crudo. Teclas = rectángulo con el nombre; mando = forma neutra con letra o símbolo. La familia de glifo del mando (`A`/`✕`) **no está verificada en el motor** (1, OQ 19).

---

#### P-26 Reflow y scroll con `escala_texto_ui`

**Category**: Layout
**Origen**: 30 reglas 8 a 11 y F1; ADR-0007 D7; ADR-0016 D3.
**Specification**: `escala_texto_ui` ∈ {1,00; 1,25; 1,50}, aplicada en el fotograma del aviso sin reiniciar nada (se ofrece desde la pausa, que ya detiene el tiempo). **Reflow, no recorte**: contenedores crecen o pasan a más líneas, o la pantalla hace scroll vertical; nunca se superponen controles ni queda una acción fuera de pantalla. Texto con `AUTOWRAP_WORD_SMART`; ninguna altura fija en nodos de texto; sin `[font_size]` BBCode. Objetivos de pulsación escalan con el texto con mínimo 44 px. Una pantalla que cambia con un bloque visible conserva scroll y foco. No escala: subtítulos, iconos, texto diegético fuera de la vista de enfoque. Si no cabe el texto de ayuda de una fila, pasa a una segunda línea. **DPU**: el cierre de `escala_texto_ui` en el slice y el suelo a 720p.

---

### Modales, avisos y arranque

#### P-05 Diálogo de confirmación y de mensaje

**Category**: Modal
**Origen**: 25 reglas 10, 18, 23, 28 y 30; 27 regla 11; ADR-0016 D9.
**Specification**:
- **Confirmación** (`ConfirmDialog`): título breve, una frase de consecuencia, botón de acción con **la acción nombrada** (no «Sí»/«OK») y «Cancelar». **Foco inicial en «Cancelar»**; `ui_atrás` = Cancelar. Foco atrapado dentro del diálogo; al cerrar vuelve a la fila que lo abrió.
- **Mensaje** (`MessageDialog`): un solo «Aceptar».
- Usos: «Volver al título» (texto normal «Se guardará tu progreso.»; con guardado en riesgo, aviso grave: único caso), «Nueva partida» (pausa y título), «Restablecer todos» (cita lo que cubre y lo que no), restablecer dispositivo, conflicto de asignación.
- Un botón destructivo **nunca** ejecuta directamente: siempre abre confirmación. Tras confirmar, el sistema pasa a «Saliendo» y descarta entradas (un doble clic no repite).
- Sin cuenta atrás ni cierre automático.

---

#### P-07 Línea de aviso (`NoticeLine`)

**Category**: Feedback
**Origen**: 25 reglas 17, 24 y 27; 27 regla 19; ADR-0016 D9 y D11.
**Specification**: Icono + palabra clave + texto, **no enfocable**, anunciada como `set_live(polite)`. Nunca modal, nunca solo color, sin temporizador propio. Casos: «No se puede guardar la partida. Seguimos intentándolo.» (pausa); «Mando desconectado»/«Mando conectado» (cabecera; cambia al reconectar, desaparece al cerrar); aviso de tecla imprimible (Controles); partida dañada o de versión más nueva (título, una vez por arranque). Sin «guardado correcto» ni icono de disco.

---

#### P-20 Advertencias y arranque

**Category**: Modal / Navigation
**Origen**: 27 reglas 1 a 6 y 15 a 17; ADR-0016 D9 (`WarningsScreen`).
**Specification**: «Antes de empezar» con cinco entradas de contenido sensible, **sin cuenta atrás ni avance automático**; «Entendido» (`ui_accept`) y «Salir del juego» siempre presente. Una sola vez (`advertencias_vistas`); releíble desde Opciones › «Avisos de contenido» con «Volver». Sin línea de cierre que prometa contenido (27 OQ 8). Sin flashes ni sacudidas; entrada con fundido (100 ms con `reducir_movimiento`). Entradas ignoradas, no encoladas, durante fundidos y cargas. `ui_cancel` en el menú principal no hace nada. «Salir del juego» cierra sin confirmación (`SceneTree.quit()` **NO VERIFICADO** en la referencia). Un fallo de carga muestra un panel sobre la cortina («Volver al título», foco en él, sin rojo).
**Hueco**: no incluye aviso de fotosensibilidad (ver `accessibility-requirements.md`).

---

#### P-23 Fundidos y `reducir_movimiento`

**Category**: Feedback
**Origen**: 30 reglas 19 y 27; 24 reglas 5 y 24; 25 regla 7; 26 regla 20; 27 F1; art bible §7.4.
**Descripción**: Los valores de la tabla son **los ya decididos** en los GDD; el art bible §7.4 es la fuente visual (decide art-director).

| Elemento | Normal | Con `reducir_movimiento` |
|---|---|---|
| Anillo de interacción (aparece / desaparece) | 250 ms / 150 ms | 100 ms |
| Fundido cruzado de etiqueta del anillo | 120 ms | 100 ms |
| Pulso de aceptación o rechazo | 120 ms (opacidad) | Sin cambio (no es movimiento) |
| Pie de texto (entrada/salida) | 250 ms | 100 ms |
| Fundido cruzado entre pies | 150 ms | 100 ms |
| Subtítulos | 150 ms | 100 ms |
| Velo de la pausa | 350 ms | 100 ms |
| Título (F1 de 27) | según 27 | 100 ms |
| `LUCES_PARPADEO` (3 destellos) | Según 21/28 | Una atenuación suave de 0,6 s |

**Reglas**: rango único del fundido reducido 50–150 ms, defecto 100 ms (6 `reduce_motion_fade_s`). Sin deslizamientos ni escalas en los menús. Tope duro de destellos de 3/s siempre activo (30 regla 18). **Sonidos de UI**: ninguna fuente consultada define la tabla de sonidos de la interfaz salvo `SFX_CLICK_SUBTLE`; **NO SOURCEABLE aquí**: la tabla de eventos de UI → categoría de sonido corresponde a `design/gdd/sound-bible.md` / 23.

---

## Gaps & Patterns Needed

| # | Hueco | Detalle | Quién |
|---|---|---|---|
| G-1 | Cursor de los puzles y de la llamada | Forma no circular sin definir; diseño visual no existe (1 Visual/Audio; 7 UI Requirements) | art-director |
| G-2 | Pestañas vs. pasos de selector | `ui_izquierda/derecha` para pestañas y para pasos de deslizador: falta la regla de qué fila las consume en «Controles» | spec de «Controles» |
| G-3 | Vista cercana: presentación | Tamaño del tablero y distancia de la vista del puzle 4 pendientes (14 OQ 1) | 7, 10, art |
| G-4 | Etiquetas de objeto y pistas | Textos de ayuda `UI_ACC_*` y provisionales de 18 | writer |
| G-5 | Sonidos de interfaz | Fuera de las fuentes consultadas (solo `SFX_CLICK_SUBTLE`) | 23 / sound-bible |
| G-6 | Aviso de fotosensibilidad | No existe en 27 | usuario |
| G-7 | Historial de pies | Fuera del slice (7 OQ) | — |
| G-8 | Pantalla de créditos | Alcance abierto (27 OQ 7) | usuario |
| G-9 | Patrones de la plantilla no necesarios en el slice | Cuadrículas/inventario, barras de salud, minimapa, números de daño, estados, habilidad, loading bar, árbol de habilidades: **no existen** en el slice (slice §16, D.1). No se documentan | — |

**Inconsistencias a vigilar**: (1) la plantilla pide `Button (Primary/Secondary/Destructive)`: el proyecto no usa botones primarios con peso visual distinto; las acciones de menú son filas (P-02) y los diálogos usan P-05. (2) P-01 anula la regla de hover de ADR-0007 D8.3.

---

## Decisiones tomadas (modo autónomo, registradas)

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| DP-1 | El catálogo parte de los **patrones que existen en los GDD**, no de la lista genérica de la plantilla | Copiar los 40 patrones de la plantilla | El slice no tiene inventario, HUD de salud ni minimapa; documentarlos violaría «no inventar requisitos» |
| DP-2 | Los valores de animación se limitan a los de los GDD (P-23) | Usar la tabla de duraciones de la plantilla (80/250/200 ms…) | Ninguna fuente del proyecto los adopta; decide art-director |
| DP-3 | «Sin foco sorpresa»: sin wrap, foco inicial seguro, `Cancelar` por defecto en destructivos | Wrap circular | 25 regla 9 y 10; coherente con *Tensión sin castigo* |
| DP-4 | El orden de la pestaña Accesibilidad es el de 30, no el de 25 | Mantener el de 25 | 30 D25-24 / AC-30-02 sustituye al orden de 25 |
| DP-5 | La tabla de «atrás» por contexto se documenta como patrón aparte (P-08) | Dejarla en cada spec | Es el fallo de navegación más frecuente en menús de juego |

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| **DPU.** Suelo de texto a 720p (QQ-10): lógico (16 px reales) o real (24 px reales) | Usuario | Antes de implementar el tema de UI | Por defecto lógico (ADR-0007 OI-1) |
| **DPU.** `escala_texto_ui` cerrada en el slice (QQ-08, OQ 10 de 30) | Usuario | Antes de cerrar el catálogo de 6 | Por defecto sí |
| **DPU.** Parpadeo del pasillo y apagón con `reducir_sobresaltos` / `reducir_movimiento` (OQ 10 de 30) | Usuario | Antes del re-review de 28 | Se mantiene lo escrito en 30 y 28 |
| **DPU.** Cursor oculto de la llamada con mando (OQ 5 de 30) | 22, usuario | Antes de cerrar la capa | Playtest con mando |
| **DPU.** Dwell de P5 (OQ 9 de 30) | Usuario, 15 | Tras playtest | Aceptar la excepción |
| ¿Cómo se resuelve `ui_izquierda/derecha` en pestañas frente a selectores? (G-2) | ux-designer | Spec de «Controles» | Abierta |
| ¿Detecta Godot 4.7 la familia del mando (`A`/`✕`)? | ui-programmer | Spike de ADR-0006 | NO VERIFICADO |
| ¿Qué API de AccessKit nombra y ordena los controles en 4.7? | ui-programmer | Spike SP-4 de ADR-0007 | NO VERIFICADO |
