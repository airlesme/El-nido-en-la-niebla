# Entrada y controles

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Autonomía como progresión · Tensión sin castigo (accesibilidad y control sin fricción)

## Summary

Traduce teclado, ratón y mando en acciones del juego (moverse, mirar, interactuar con un solo botón, leer, volver, pausar y los gestos de los puzles) y decide qué acciones valen en cada momento. Permite jugar el slice completo con cualquiera de los dos dispositivos, con un cursor virtual para los puzles en el mando, y se puede reasignar y ajustar por completo por accesibilidad. Existe porque el slice mezcla tres modos de manejo muy distintos y exige accesibilidad desde el principio.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: ninguna dura (blanda: 3 Estado y bus, solo para emitir sus avisos)

## Overview

Entrada y controles traduce lo que el jugador hace con el teclado y el ratón, o con el mando, en un vocabulario único de **acciones del juego** (moverse, mirar, interactuar, leer, volver, pausar, y los gestos de puntero de los puzles) y decide, en cada momento, qué acciones están activas. El resto de sistemas pide acciones («¿quiere interactuar?»), nunca teclas ni botones.

El juego se maneja con un solo botón contextual en exploración (slice §5) y se puede jugar completo con cualquiera de los dos dispositivos, alternando entre ellos sin menús: el sistema detecta cuál se está usando y avisa para que los iconos del juego cambien. En los puzles, donde el slice describe gestos de puntero (clic, arrastrar, rotar), el teclado y ratón usan el cursor real y el mando usa un **cursor virtual** movido con el stick, de modo que ningún puzle exige ratón. Todas las acciones se pueden reasignar (accesibilidad, slice §5) y los valores de sensibilidad, zona muerta y velocidad son ajustables.

Existe porque el slice combina tres modos de manejo muy distintos (caminar en primera persona, inspeccionar objetos en la mano y puzles de puntero en vista cercana) y porque exige accesibilidad desde el principio. Resolverlo en un único punto evita que cada puzle reinvente su control, y garantiza el pilar *Tensión sin castigo* en lo físico: ningún gesto requiere precisión temporal, combinaciones de botones simultáneos ni habilidad motriz fina que no se pueda compensar con ajustes.

## Detailed Design

### Core Rules

**Acciones y dispositivos**

1. **Vocabulario de acciones.** El resto del juego solo conoce acciones lógicas, nunca teclas ni botones. Las acciones del slice son (ver tabla de asignaciones por defecto):
   - *Exploración:* `mover`, `mirar`, `interactuar`, `pausa`.
   - *Inspección y lectura:* `rotar_objeto` (con el eje de mirar), `leer` (mantener `interactuar`), `atrás`.
   - *Vista cercana de puzle, ordenador y llamada:* `mover_cursor`, `seleccionar`, `agarrar` (mantener `seleccionar` y mover), `rotar` (mantener `seleccionar` y mover en horizontal: gesto `ROTAR` del Anexo B), `mantener` (mantener `seleccionar` más allá del umbral: gesto `PULSAR` largo del puzle 3), `atrás`.
   - *Menús y opciones de la llamada:* `ui_arriba`, `ui_abajo`, `ui_izquierda`, `ui_derecha`, `ui_aceptar`, `ui_atrás`.
   No existen `correr`, `agacharse` ni `saltar` (slice §5 y A.0).
2. **Dos dispositivos a la vez.** Teclado y ratón, y mando, están siempre activos: una acción llega al juego venga de donde venga. No hay modo «elige tu dispositivo».
3. **Dispositivo activo = el último usado.** Cuenta como uso la pulsación de cualquier tecla, botón o clic, el movimiento del ratón por encima de un mínimo y un stick fuera de su zona muerta. El dispositivo activo solo determina qué iconos muestra el juego; al cambiar se emite el aviso «dispositivo de entrada cambiado» (teclado/ratón o mando). Una pequeña histéresis (ver Formulas) evita parpadeos por temblor del ratón o deriva del stick.
4. **Un gesto, un botón.** Ninguna acción exige pulsar dos botones a la vez, doble pulsación ni reaccionar dentro de una ventana de tiempo (solo se exige mantener un botón hasta un umbral). El único gesto compuesto es mantener un botón mientras se mueve el cursor o un stick (`agarrar`, `rotar`), y los únicos gestos con tiempo son la pulsación prolongada (`leer`, `mantener`) y el arrastre; todos tienen la alternativa de la regla 14.

**Contextos de entrada**

5. **Un contexto activo.** Hay una pila de contextos y solo el de arriba recibe acciones: `exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`, `llamada`, `menú` y `sin control`. Las acciones de un contexto no existen en los demás (por ejemplo, `mover` solo en `exploración`).
6. **Quién abre y cierra contextos.** Este sistema posee la pila y expone «entrar en» y «salir de» un contexto. Los piden: Interacción (7) para `inspección`, `lectura`, `vista cercana` y `ordenador`; el menú de pausa (25) para `menú`; la llamada (22) para `llamada`; y el director de escenas (21) para `sin control`, **declarando una duración máxima** (regla 8). Salir restaura el contexto anterior tal como estaba (posición del cursor incluida). **Aviso de cambio:** tras cada entrada o salida efectiva de la pila se emite «contexto de entrada cambiado» con dos datos (contexto anterior, contexto nuevo); una petición ignorada o rechazada (ver Edge Cases) no emite nada, y el reinicio de la pila al descargar una escena emite uno solo, con `sin control` como contexto nuevo.
7. **Pausa.** `pausa` abre el menú sobre cualquier contexto salvo durante una carga de escena, detiene el tiempo de juego y, al cerrarlo, restablece el contexto inferior. Con el menú abierto, `atrás` y `pausa` lo cierran; si ambas comparten tecla (`Esc`), una sola pulsación produce un solo cierre, porque el menú consume el evento. Al abrir el menú el ratón se libera; al cerrarlo se recaptura si el contexto restaurado lo requiere. El menú de título es la base de la pila: `pausa`, `atrás` y `ui_atrás` no lo cierran; solo se sale de él al empezar o reanudar la partida.
8. **Transiciones.** Mientras una transición de cámara o de animación bloquea el contexto (p. ej. la cámara acercándose al marco del puzle 3, o la animación de descolgar), solo se acepta `pausa`; el resto de acciones se descarta y **no se guarda para después**. Las transiciones de cámara y animación tienen un tope de seguridad de 3 s; las escenas dirigidas (`sin control` pedido por el director de escenas) declaran su propia duración máxima (F8).

**Exploración, inspección y lectura**

9. **Mirar.** `mirar` entrega un cambio de orientación por fotograma, calculado con la sensibilidad del dispositivo (ver Formulas). La orientación y sus límites son del sistema de jugador (2); este sistema no limita ángulos.
10. **Interactuar.** `interactuar` es el único botón del mundo: pulsación corta = activar, coger o inspeccionar lo que el icono contextual indica; pulsación prolongada (umbral de Formulas) sobre un documento o texto = `leer`. Para que activar no tenga retraso, la acción corta se dispara **al pulsar**, salvo sobre objetos que ofrecen `leer`: en esos, la pulsación corta se decide **al soltar** (más corta que el umbral) y mientras se mantiene se muestra un indicador de progreso. Qué hace cada objeto lo decide Interacción (7).
11. **Inspección.** Con un objeto en la mano, `mirar` pasa a girar el objeto en lugar de la cámara (`rotar_objeto`); `atrás` lo suelta.

**Puzles y vista cercana**

12. **Cursor.** En `vista cercana`, `ordenador` y `llamada` hay un cursor en pantalla. Con ratón es el cursor real, libre dentro de la ventana. Con mando es un **cursor virtual** movido con cualquiera de los dos sticks en `vista cercana` y `ordenador`, y solo con el derecho en `llamada` y `menú` (donde el izquierdo y la cruceta mueven el foco, `ui_*`); lleva velocidad y atracción asistida hacia el elemento interactivo más cercano (ver Formulas), y la atracción se puede desactivar. En `exploración` e `inspección` el cursor no existe y el ratón queda capturado.
13. **Gestos de puntero.** Se mapean a una sola secuencia en ambos dispositivos:
    - `seleccionar` = clic o `A`/`✕` (equivale a `CLICK` y a `PULSAR` corto del Anexo B).
    - `agarrar` = mantener `seleccionar` y mover el cursor más allá de un umbral de inicio de arrastre (ver Formulas), para distinguirlo de `mantener`; equivale a `ARRASTRAR` del Anexo B.
    - `rotar` = mantener `seleccionar` sobre un control giratorio y mover en horizontal; con ratón, 1 píxel = 0,25° (slice, Anexo B); con mando, velocidad angular proporcional al stick (ver Formulas). Mientras se rota, el cursor queda quieto.
    - `mantener` = mantener `seleccionar` el tiempo del umbral (`PULSAR` largo del puzle 3).
    - «Pasar el cursor» (resaltado de la ficha, puzle 4) = cursor sobre el elemento; con mando, la atracción asistida o el cursor virtual producen el mismo resaltado.
    Cómo reacciona cada puzle lo define su GDD; este sistema solo entrega la secuencia.

**Accesibilidad y personalización**

14. **Alternar en lugar de mantener.** Existe un ajuste para que `leer`, `mantener` y `agarrar` se activen con una pulsación y se terminen con otra. Por defecto está desactivado. Con él activo, el gesto en curso también se cancela con `atrás` o al cambiar de contexto. *(Propuesta, a validar en playtest:)* `leer` y `mantener` se completan solo si la segunda pulsación llega después de `t_hold` (F6) desde la primera; si llega antes, se cancelan sin efecto; `agarrar` se suelta con la segunda pulsación.
15. **Reasignación.** Todas las acciones de exploración, inspección, lectura y vista cercana se pueden reasignar, por separado para teclado/ratón y para mando, con hasta dos asignaciones por acción y dispositivo. Los ejes `mover` y `mirar` se reasignan como conjunto (cada conjunto cuenta como una acción con sus dos asignaciones). No se pueden reasignar los movimientos del ratón ni las acciones `ui_*` (navegación fija con flechas/`Enter` y cruceta/`A`), pero sí los botones del ratón.
16. **Conflictos.** Dos acciones del mismo contexto no pueden compartir entrada: el intento muestra el conflicto y ofrece intercambiar o cancelar. Acciones de contextos distintos sí pueden compartirla (p. ej. `interactuar` y `seleccionar`). Como `pausa` está activa en todos los contextos, no puede asignarse a una entrada que use una acción `ui_*` fija (flechas, `Enter`, cruceta, botón sur): ahí el intercambio es imposible y el intento se rechaza con el mismo mensaje de conflicto.
17. **Mínimos garantizados.** `interactuar`, `atrás` y `pausa` conservan siempre al menos una asignación por dispositivo; quitar la última se rechaza. «Restablecer» existe por acción y para todo el dispositivo.
18. **Ajustes de manejo.** Son propiedad de este sistema y los guarda Ajustes (6): sensibilidad de mirada (ratón y stick por separado), invertir eje vertical (por dispositivo), zonas muertas de sticks, velocidad del cursor virtual, atracción asistida activada/desactivada y alternar-en-lugar-de-mantener.
19. **Datos, no código.** Las asignaciones por defecto y los valores de ajuste iniciales viven en un fichero de datos (`assets/data/input/default_bindings.json`). Las asignaciones personalizadas se entregan a Ajustes como un bloque que este sistema sabe exportar e importar; Ajustes lo guarda y lo reaplica al arrancar.
20. **Texto.** En el ordenador (contexto `ordenador`) el teclado físico entrega caracteres. El mando no puede escribir: necesita un teclado en pantalla controlado con foco, a definir en el GDD del ordenador (19) y de interfaz.

**Pérdida de foco y de mando**

21. **Ventana sin foco.** Si la ventana pierde el foco, se abre el menú de pausa automáticamente; si ocurre durante una carga de escena (donde la regla 7 impide abrirla), se abre al terminar la carga.
22. **Mando desconectado.** Si el mando era el dispositivo activo y se desconecta, se abre el menú de pausa con el mensaje «Mando desconectado»; al reconectar se ofrece continuar. Teclado y ratón siguen valiendo para reanudar.

**Asignaciones por defecto**

| Acción | Teclado y ratón | Mando |
|---|---|---|
| `mover` | `W` `A` `S` `D` | Stick izquierdo |
| `mirar` | Movimiento del ratón | Stick derecho |
| `interactuar` · `leer` (mantener) | `E` · clic izquierdo | Botón sur (`A` / `✕`) |
| `atrás` | Clic derecho · `Retroceso` | Botón este (`B` / `○`) |
| `pausa` | `Esc` | `Start` / `Options` |
| `mover_cursor` | Ratón | Ambos sticks (solo el derecho en `llamada` y `menú`) |
| `seleccionar` · `agarrar` · `rotar` · `mantener` | Clic izquierdo (pulsar / mantener) | Botón sur (pulsar / mantener) |
| `ui_arriba/abajo/izquierda/derecha` | Flechas | Cruceta · stick izquierdo |
| `ui_aceptar` · `ui_atrás` | `Enter` · `Esc` | Botón sur · botón este |

### States and Transitions

La pila empieza vacía en el arranque, con `menú` (título) como primer contexto, y pasa a `exploración` al comenzar partida o reanudarla.

| Contexto | Acciones activas | Cursor y ratón | Se entra desde | Se sale con |
|---|---|---|---|---|
| `exploración` | `mover`, `mirar`, `interactuar`, `pausa` | Sin cursor; ratón capturado | Inicio de partida; al salir de cualquier otro | — (contexto base) |
| `inspección` | `rotar_objeto` (eje de mirar), `leer`, `atrás`, `pausa` | Sin cursor; ratón capturado | Interacción (7), al coger un objeto | `atrás` |
| `lectura` | `atrás`, `interactuar` (pasar página), `pausa` | Sin cursor | Interacción (7), al leer | `atrás` |
| `vista cercana` | `mover_cursor`, `seleccionar`, `agarrar`, `rotar`, `mantener`, `atrás`, `pausa` | Cursor visible (virtual con mando) | Interacción (7), al abrir un puzle o panel | `atrás` o resolverse el puzle |
| `ordenador` | `mover_cursor`, `seleccionar`, texto, `atrás`, `pausa` | Cursor visible | Interacción (7), al sentarse al ordenador | `atrás` |
| `llamada` | `ui_*` o cursor, `seleccionar` (sobre las opciones), `pausa` | Cursor visible | Llamada (22), tras descolgar | La llamada (22) la cierra |
| `menú` | `ui_*`, cursor, `ui_aceptar`, `ui_atrás` | Cursor visible | `pausa`, título, pérdida de foco o mando | `ui_atrás` · `pausa` |
| `sin control` | solo `pausa` | Sin cursor | Director de escenas (21), transiciones | El sistema que lo abrió |

**Dispositivo activo:** teclado/ratón ↔ mando según la regla 3; el valor inicial es teclado/ratón hasta la primera entrada.

### Interactions with Other Systems

| Sistema | Qué recibe de Entrada y controles | Qué entrega a Entrada y controles |
|---|---|---|
| 2 Jugador | `mover` (vector 2D) y `mirar` (cambio de orientación) en `exploración` | Nada |
| 7 Interacción | `interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero | Peticiones de entrar y salir de `inspección`, `lectura`, `vista cercana` y `ordenador` |
| 24 Prompt de interacción | Dispositivo activo (para elegir el icono) y la asignación actual de la acción | — |
| 25 Menú de pausa | `pausa`, `ui_*`, `atrás`; avisos de foco y mando | Peticiones de entrar y salir de `menú`; pantalla de reasignación (usa la API de reasignación) |
| 30 Accesibilidad | API de reasignación, ajustes de manejo, alternar-en-lugar-de-mantener | Valores elegidos por el jugador |
| 6 Ajustes | Bloque de asignaciones y ajustes de manejo para guardar | Bloque guardado, al arrancar |
| 19 Ordenador, 22 Llamada, 27 Título | `ui_*`, cursor, texto | Peticiones de contexto (22 para `llamada`) |
| 21 Director de escenas | — | Peticiones de `sin control` |
| 3 Estado y avisos | Los avisos «dispositivo de entrada cambiado» y «contexto de entrada cambiado» (se documentan aquí según la regla 10 de ese GDD) | — |

## Formulas

Propuestas por `systems-designer`. † = valor propuesto, **a validar en playtest**; las constantes que vienen del slice no llevan †. Todos los valores se leen de `assets/data/input/default_bindings.json`; los ajustables por el jugador van marcados «(ajuste)». **Unidades:** los píxeles del cursor (F5a, F5b, F6) son del viewport lógico de 1920 × 1080 (modo de estiramiento del proyecto, a confirmar en el ADR de resolución), no de la ventana física; los de la mirada con ratón (F2) y el gesto `rotar` con ratón (F4) son píxeles físicos relativos del dispositivo. El nombre de `t_hold` en el registro de entidades es `long_press_threshold`.

### F1 · Zona muerta radial reescalada (usada por F2, F4 y F5a)

The zona muerta radial formula is defined as:

`r = clamp((|v| − dz_in) / (1 − dz_out − dz_in), 0, 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| v | Vector2 | \|v\| ≤ 1 | engine (crudo) | Ejes del stick sin zona muerta del motor |
| dz_in | float | 0–0,5 | data file, 0,15† (ajuste) | Zona muerta interior |
| dz_out | float | 0–0,2 | data file, 0,05† | Margen exterior: el máximo se alcanza con \|v\| = 0,95 |
| r | float | 0–1 | calculated | Magnitud normalizada |

**Output Range:** 0 si \|v\| ≤ 0,15; 1 si \|v\| ≥ 0,95 (los rangos permitidos garantizan dz_in + dz_out < 1). Continua, sin salto al salir de la zona muerta; se evalúa en radial, no por eje.
**Example:** v = (0,5; 0,4), \|v\| = 0,640 → r = (0,640 − 0,15) / 0,80 = **0,613**.

### F2 · Mirada con ratón

The mirada con ratón formula is defined as:

`Δθ = relative_px × k_m × s_m × inv`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| relative_px | Vector2 | acotado | engine | Píxeles de movimiento del ratón acumulados en el fotograma |
| k_m | float | constante | constant, 0,10 °/px† | Grados por píxel base |
| s_m | float | 0,25–3 | data file, 1,0† (ajuste) | Sensibilidad del jugador |
| inv | int | {−1, +1} | data file, +1 (ajuste) | Inversión vertical |
| Δθ | Vector2 (°) | ±45 | calculated | Cambio de yaw y pitch en el fotograma |

**Output Range:** limitado a ±45° por fotograma como protección ante picos. **No usa el tiempo del fotograma**, así que el mismo movimiento físico da el mismo giro a 30 o a 144 fps.
**Example:** relative = (18, −6) → yaw 1,8°, pitch −0,6°. Una vuelta completa = 3.600 px.

### F3 · Mirada con stick

The mirada con stick formula is defined as:

`ω = ω_max × r^p × s_s;   Δθ = (v/|v|) × ω × min(delta, 0,1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| r | float | 0–1 | calculated | Resultado de F1 |
| ω_max | float (°/s) | 60–180 | data file, 120† | Velocidad angular máxima |
| p | float | 1–2 | data file, 1,5† | Exponente de la curva (control fino cerca del centro) |
| s_s | float | 0,5–2 | data file, 1,0† (ajuste) | Sensibilidad del jugador |
| delta | float (s) | > 0 | engine | Tiempo del fotograma, limitado a 0,1 s para evitar saltos tras un tirón |

**Output Range:** 0 a ω_max · s_s (240 °/s con los valores por defecto y s_s = 2; 360 °/s en el peor caso de los rangos: ω_max = 180 y s_s = 2). Curva de potencia: una lineal dificulta la precisión y una en S añade zonas planas. Con 120 °/s, un giro de 180° tarda 1,5 s y se recorre el campo de visión (70°) en ~0,58 s: lento y suficiente para un juego de caminar.
**Example:** r = 0,613 → r^1,5 = 0,480 → ω = 57,6 °/s. A 60 fps: 0,96 °/fotograma; a 30 fps: 1,92 °/fotograma (misma velocidad).

### F4 · Gesto `rotar`

The rotar formula is defined as:

`Ratón:  Δφ = px_x × 0,25°      Mando:  Δφ = sign(x) × ω_r_max × r_x² × f_marca × delta`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| px_x | int | acotado | engine | Píxeles horizontales de movimiento |
| 0,25 | float (°/px) | constante | constant (slice, Anexo B) | Ganancia del ratón |
| ω_r_max | float (°/s) | 20–90 | data file, 60† (modo fino: 25†) | Velocidad máxima de rotación con mando |
| r_x | float | 0–1 | calculated | F1 aplicada al eje horizontal |
| f_marca | float | 0,3–1 | data file, 0,5† | Freno cuando el ángulo está a ≤ 1° de una marca de 5° |
| delta | float (s) | > 0 | engine | Tiempo del fotograma |

**Output Range:** ratón, 0,25 °/px sin multiplicador; mando, ±60 °/s. Soltar el stick detiene la rotación al instante y el ángulo se conserva durante el mantenimiento de 0,8 s del puzle 5.
**Example (puzle 5, de 0° a 40°, tolerancia ±3°):** con r = 0,71 (30 °/s) se llega a 30° en 1,0 s; con r = 0,35 (7,4 °/s), a 38° en 1,1 s; con r = 0,2 y freno (1,2 °/s), a 40° en 1,7 s. Total ~4 s (~2 s si va directo); el freno en las marcas de 5° (f_marca) añade unos 0,4 s a la fase rápida, así que ~4,4 s en la práctica. Con 0,25 s de reacción, el error es de 1,8° a 7,4 °/s y de 0,3° a 1,2 °/s, dentro de ±3°. Con ratón, 40° = 160 px y ±3° = ±12 px. El modo fino (accesibilidad) baja a 25 °/s. El modo asistido (±6°) no requiere nada más.

### F5a · Velocidad del cursor virtual

The velocidad del cursor formula is defined as:

`v_c = v_max × r² × s_c;    p += dir × v_c × delta`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| r | float | 0–1 | calculated | F1 del stick con mayor magnitud (en `llamada` y `menú`, solo el derecho) |
| v_max | float (px/s) | 400–1600 | data file, 900† | Velocidad máxima en pantalla de 1920 × 1080 |
| s_c | float | 0,5–1,5 | data file, 1,0† (ajuste) | Ajuste del jugador |
| dir | Vector2 | unitario | calculated | Dirección del stick |
| p | Vector2 (px) | dentro de la ventana | calculated | Posición del cursor |

**Output Range:** 0 a 1.350 px/s; la posición se limita a la ventana (cruzar la pantalla a máxima velocidad: ~2,1 s).
**Example:** r = 0,613 → 338 px/s. Con r = 0,2 → 36 px/s, suficiente para elementos pequeños.

### F5b · Atracción asistida (magnetismo)

The atracción asistida formula is defined as:

`w = clamp(1 − d/R, 0, 1) × g;   g = clamp((v_off − v_c)/(v_off − v_on), 0, 1);   Δp = limitar_módulo( (t − p) × (1 − e^(−λ·delta)) × w ,  0,5 · v_c · delta )`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| d | float (px) | ≥ 0 | calculated | Distancia al centro del elemento interactivo más cercano |
| R | float (px) | 32–128 | data file, 64† | Radio de captación base; **por elemento: R = max(R base, tolerancia del elemento en px)** |
| λ | float (1/s) | 2–10 | data file, 5† | Intensidad |
| v_on, v_off | float (px/s) | — | data file, 300†, 450† | Tramo en que la atracción se apaga al moverse rápido |
| t, p | Vector2 (px) | — | calculated | Centro del elemento y posición del cursor |
| delta | float (s) | > 0 | engine | Tiempo del fotograma, limitado a 0,1 s (igual que F3) |
| v_c | float (px/s) | ≥ 0 | calculated | Velocidad del cursor de F5a |

**Output Range:** la tracción nunca supera la mitad de la velocidad del cursor (`0,5 · v_c · delta` por fotograma), de modo que **cualquier movimiento deliberado del stick vence siempre a la atracción**, sea cual sea s_c, v_max, λ o R dentro de sus rangos. Consecuencia: con el stick en reposo (v_c = 0) no hay atracción y el cursor no se mueve solo. Se anula además con d < 3 px (evita temblor), con v_c ≥ 450 px/s y si el ajuste está desactivado. El objetivo cambia solo si otro candidato está más cerca por más de 8 px†.
**Example:** d = 40, v_c = 100, 60 fps → w = 0,375; factor 0,080; sin tope Δp = 1,2 px/fotograma (72 px/s); el tope `0,5 · 100 / 60` = 0,833 px/fotograma lo reduce a **Δp = 0,833 px/fotograma (50 px/s)**. Con v_c = 400 el tope es 3,33 px/fotograma y no actúa.

### F6 · Pulsación prolongada y umbral de arrastre

The pulsación prolongada formula is defined as:

`largo = (t_ahora − t_pulsado) ≥ t_hold;      arrastre = (|p − p_pulsado| ≥ d_arrastre)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t_hold | float (s) | 0,3–1,0 (hasta 1,5 en accesibilidad) | data file, 0,5 (slice, B.3) (ajuste de accesibilidad) | Umbral de pulsación prolongada |
| d_arrastre | float (px) | 4–16 | data file, 8† | Distancia mínima para que mantener `seleccionar` sea `agarrar` y no `mantener` |
| p, p_pulsado | Vector2 (px) | — | calculated | Posición actual del cursor y al pulsar |

**Output Range:** el tiempo es real, no escalado. Por debajo de 0,3 s, los toques y el temblor activan `leer` sin querer; por encima de 1,0 s el juego parece no responder; hace falta un indicador de progreso (el art bible excluye las barras).
**Example:** con 0,5 s, una pulsación de 0,18 s es corta y una de 0,62 s es larga. Mantener 0,6 s moviendo 3 px es `mantener`; mantener y moverse 12 px es `agarrar`.

### F7 · Histéresis del dispositivo activo

The histéresis formula is defined as:

`ratón:  Σ|relative| en ventana T_m ≥ N_m;   stick:  |v| ≥ dz_in + m_s durante t_s;   tecla o botón: inmediato;   tras un cambio, el movimiento solo no cambia de nuevo durante t_lock`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| T_m | float (s) | 0,1–0,5 | data file, 0,2† | Ventana de acumulación del ratón |
| N_m | float (px) | 6–40 | data file, 12† | Píxeles acumulados para contar como uso |
| m_s | float | 0,1–0,3 | data file, 0,15† | Margen del stick sobre su zona muerta |
| t_s | float (s) | 0,05–0,3 | data file, 0,10† | Tiempo sostenido del stick |
| t_lock | float (s) | 0–1 | data file, 0,4† | Bloqueo tras un cambio |

**Output Range:** devuelve verdadero o falso («cuenta como uso»).
**Example:** un temblor de 4 px en 0,2 s no cambia el dispositivo; un gesto de 20 px sí. Una deriva de 0,2 no cambia; empujar a 0,35 durante 0,1 s sí.

### F8 · Descarte durante transiciones

No hay fórmula: la duración la fijan la cámara o el director de escenas. Sí hay un **tope de seguridad**, tras el cual se registra el error y se libera el contexto: **3 s†** para transiciones de cámara y animaciones; para `sin control` pedido por el director de escenas, la **duración máxima que el propio director declara al pedirlo más un margen de 2 s†** (la declara cada escena en su GDD, sistema 21). Siempre hay un tope: un bloqueo de una transición corta se libera a los 3 s, no a los de la escena más larga. Una tecla mantenida durante la transición no debe dispararse al terminar (se ignora hasta soltarla).

### Valores por defecto y rangos seguros

| Valor | Defecto | Rango seguro |
|---|---|---|
| k_m (ratón, °/px) | 0,10† | 0,03–0,30 |
| dz_in / dz_out | 0,15† / 0,05† | 0–0,5 / 0–0,2 |
| ω_max (mirada con stick, °/s) | 120† | 60–180 |
| ω_r_max (rotar con mando, °/s) | 60† | 20–90 |
| v_max (cursor virtual, px/s) | 900† | 400–1600 |
| R / λ (atracción) | 64 px† / 5† | 32–128 / 2–10 |
| t_hold | 0,5 s | 0,3–1,0 (1,5 accesible) |
| d_arrastre | 8 px† | 4–16 |
| N_m en T_m | 12 px en 0,2 s† | 6–40 px en 0,1–0,5 s |
| Tope de transición (cámara y animación) | 3 s† | 1–5 |
| Margen sobre la duración declarada (escenas dirigidas) | 2 s† | 1–5 |

## Edge Cases

**Dispositivos**
- **If el jugador usa teclado/ratón y mando a la vez**: ambos funcionan; el dispositivo activo es el del último evento (regla 3) y solo cambia los iconos.
- **If el ratón se mueve por una vibración o el stick tiene deriva**: no cuenta como uso mientras no supere los umbrales de histéresis (ver Formulas); los iconos no cambian.
- **If se conectan dos mandos**: se aceptan los dos como un único «mando»; el activo es el último que generó entrada. No hay asignación por jugador.
- **If un mando se desconecta y no era el dispositivo activo**: no ocurre nada visible; si era el activo, se aplica la regla 22 (pausa con mensaje).
- **If el mando se desconecta durante una animación que bloquea el contexto** (p. ej. `ANIM_PHONE_PICKUP`): el menú de pausa se abre al terminar la animación, no durante.

**Contextos**
- **If se pide entrar en un contexto que ya está arriba de la pila**: se ignora (no se apila dos veces).
- **If un sistema pide salir de un contexto que no es el de arriba**: se rechaza y se registra; la pila no cambia.
- **If se abre el menú de pausa durante `vista cercana`, `ordenador` o `llamada`**: al cerrarlo se restaura el contexto con el cursor donde estaba y el estado del puzle intacto; el tiempo de juego (incluida la cuenta de 20 s de la llamada) se detuvo mientras tanto.
- **If una escena se descarga con la pila en un contexto distinto de `exploración`** (p. ej. al pasar a Recepción): la pila se reinicia a `sin control` hasta que el director de escenas (21) la devuelva a `exploración`.
- **If llega una acción durante una transición que bloquea el contexto**: se descarta, no se guarda (regla 8); la única excepción es `pausa`.
- **If el jugador mantiene `seleccionar` al entrar en `vista cercana`** (porque el botón de interactuar es el mismo): esa pulsación no cuenta como `seleccionar` hasta soltarse y volver a pulsar.
- **If se mantiene `interactuar` y el contexto cambia antes de cumplirse el umbral**: la pulsación en curso se cancela.

**Gestos**
- **If el cursor virtual sale de la ventana o de la zona del puzle**: se detiene en el borde de la zona permitida; el cursor real del ratón queda confinado a la ventana.
- **If se suelta `seleccionar` fuera de cualquier destino válido durante `agarrar`**: la pieza vuelve según las reglas de su puzle (p. ej. a la bandeja en el puzle 3); este sistema solo entrega «soltar».
- **If se rota con el mando y se llega al límite del control**: el giro se detiene en el límite sin rebotar.
- **If la atracción asistida compite entre dos elementos a la misma distancia**: gana el que está más cerca de la dirección del stick; si sigue el empate, el primero en el orden de enfoque del puzle.
- **If se usa `mantener` en un elemento sin acción de mantener**: se trata como un `seleccionar` al soltar.

**Reasignación**
- **If el jugador intenta dejar `interactuar`, `atrás` o `pausa` sin asignación en un dispositivo**: se rechaza (regla 17).
- **If un archivo de asignaciones guardado contiene una acción que ya no existe o una entrada no válida**: esa entrada se descarta con una línea en el log y la acción conserva su valor por defecto.
- **If dos acciones del mismo contexto quedan con la misma entrada tras importar un archivo** (p. ej. editado a mano): gana la primera en el orden de la tabla y la otra vuelve a su valor por defecto, con aviso en el log.
- **If se pulsa una tecla no asignable durante la captura de una nueva asignación** (`Esc` cancela la captura): la captura termina sin cambios.

**Ventana y foco**
- **If la ventana pierde el foco con una acción mantenida**: la acción se cancela sin completarse (no se dispara `leer`) y se abre la pausa (regla 21).
- **If el sistema recupera el foco con el menú de pausa abierto**: se mantiene abierto; el jugador reanuda cuando quiere.
- **If se pausa durante `inspección` o `lectura`**: al reanudar, el objeto o la página siguen como estaban (se restaura el contexto, regla 6).
- **If se pausa durante `sin control`**: el tope de seguridad de la transición (F8) también se detiene mientras el menú está abierto.
- **If la ventana pierde el foco durante una carga de escena**: la pausa se abre al terminar la carga (regla 21), no durante.
- **If se pulsa `pausa`, `atrás` o `ui_atrás` en el menú de título**: no se cierra (es la base de la pila, regla 7).
- **If se intenta asignar `pausa` a una entrada de una acción `ui_*` fija**: se rechaza (regla 16).

**Texto**
- **If se usa el mando en un campo de texto sin teclado en pantalla disponible** (hasta que se defina en el sistema 19): el campo no es operable con mando; es una laguna registrada en Open Questions, no un comportamiento definido.

## Dependencies

**Aguas arriba (de qué depende):** ninguna dura. Usa las capacidades de entrada del motor (teclado, ratón, mando) y un fichero de datos con las asignaciones por defecto. **Blanda: 3 Estado y bus de eventos**, solo para emitir «dispositivo de entrada cambiado» y «contexto de entrada cambiado» (regla 10 del GDD del 3); Entrada funciona sin el bus salvo por esos dos avisos y no lee ni escribe hechos. Necesita **leer** de Ajustes (6) las asignaciones personalizadas al arrancar; ese contacto va por el bloque exportable de la regla 19, de modo que Ajustes depende de este sistema y no al revés.

**Aguas abajo (quién depende de este sistema).**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 2 Jugador | Dura | `mover`, `mirar` |
| 7 Interacción | Dura | `interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero; petición de contextos |
| 25 Menú de pausa | Dura | `pausa`, `ui_*`; contexto `menú`; API de reasignación |
| 30 Accesibilidad | Dura | API de reasignación y ajustes de manejo |
| 6 Ajustes | Dura | Guarda y reaplica el bloque de asignaciones y ajustes de manejo |
| 19 Ordenador | Blanda | Cursor, `seleccionar`, texto |
| 22 Llamada | Blanda | Contexto `llamada`, `ui_*` |
| 24 Prompt de interacción | Blanda | Dispositivo activo y asignación vigente de cada acción (para el icono) |
| 27 Pantalla de título y cierre | Blanda | `ui_*`, cursor |
| 21 Director de escenas | Blanda | Peticiones de `sin control`, con su duración máxima declarada (F8) |
| 3 Estado y bus de eventos | Blanda (aguas arriba) | Recibe «dispositivo de entrada cambiado» y «contexto de entrada cambiado» |
| 11 a 16 Puzles | Indirecta (vía 7) | Gestos de puntero |

**Índice de sistemas:** ya refleja al sistema 1 como dependencia de 2, 6, 7, 19, 21, 22, 24, 25, 27 y 30.

**Bidireccionalidad.** El par con el sistema 3 está cerrado en ambos sentidos (su regla 10 y su tabla de Dependencies listan a Entrada como emisor blando). Del resto de sistemas, ninguno tiene todavía GDD: cada uno debe listar a Entrada y controles como dependencia y usar los nombres de acción de la regla 1.

## Visual/Audio Requirements

*(Sección opcional para la categoría Core; en modo `lean` no se consulta a `art-director`: revisar antes de producción.)*

- **Icono de interacción:** el art bible (§3.3 y §7.3) define un anillo con punto central, blanco frío, que solo aparece sobre objetos interactuables y cambia el glifo de botón según el último dispositivo usado (regla 3). Este sistema solo aporta el dispositivo activo y la asignación vigente.
- **Cursor de los puzles y de las opciones de la llamada:** no está definido en el art bible. Debe ser visible con el mando y con el ratón, con una forma que **no sea un círculo** (el círculo pertenece a la luz del mundo y al icono de interacción, art bible §7.3).
- **Indicador de progreso de `leer` / `mantener`:** el art bible excluye las barras. Se propone completar el anillo del icono de interacción; el cursor de los puzles necesita su propio indicador equivalente.
- **Audio:** sin sonido propio salvo `SFX_CLICK_SUBTLE` para interacciones sin efecto (slice, B.7); el resto de sonidos de interacción los define cada sistema.

## Game Feel

- **Latencia percibida:** la acción corta se dispara al pulsar, sin esperar (regla 10), salvo sobre objetos con `leer`.
- **Mirada:** lenta y pesada a propósito (juego de caminar, FOV 70°, sin sprint). La mirada con ratón es independiente de los fps (F2); la del stick usa curva de potencia para dar precisión cerca del centro (F3).
- **Cursor virtual:** debe poder colocarse sobre elementos pequeños sin esfuerzo (36 px/s a stick suave) y cruzar la pantalla en ~2 s a máxima velocidad (F5a); la atracción ayuda cerca del elemento pero nunca retiene al jugador: su tracción está limitada a la mitad de la velocidad del cursor, así que mover el stick siempre vence (F5b).
- **Rotar con mando:** el control debe poder clavar 40° ± 3° en menos de ~4 s con un stick (F4, puzle 5).
- **Referencia de comparación:** los valores marcados † se afinan en el primer playtest (slice §23.4) comparando con la sensación de otros juegos de caminar en primera persona; los juegos de referencia siguen pendientes de elegir por el autor.

## UI Requirements

- **Pantalla de reasignación** (en el menú de pausa 25 y en accesibilidad 30): lista de acciones por dispositivo, captura de la nueva entrada, aviso de conflicto con opciones intercambiar o cancelar (regla 16), restablecer por acción y por dispositivo, y mensaje cuando se rechaza quitar la última asignación (regla 17).
- **Ajustes de manejo:** sensibilidad de mirada (ratón y stick por separado), invertir eje vertical por dispositivo, zonas muertas, velocidad del cursor, atracción asistida y «alternar en lugar de mantener», con valores seguros indicados en Formulas.
- **Mensaje «Mando desconectado»** con opción de continuar (regla 22).
- **Teclado en pantalla** para el mando en el ordenador (regla 20): pendiente de definir.
- Toda la interfaz respeta los márgenes seguros del art bible (5 % por lado a 1920 × 1080).

📌 **UX Flag — Entrada y controles**: este sistema tiene requisitos de interfaz. En la fase de preproducción, ejecuta `/ux-design` para la pantalla de reasignación, los ajustes de manejo y el mensaje de mando desconectado antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §5 | Perspectiva y controles (un solo botón, sin sprint, pulsación prolongada para leer, remapeo) | Define el alcance de este sistema |
| `design/slice/slice-v0.3.md` · Anexo B | Entradas `CLICK`, `ARRASTRAR`, `ROTAR` (1 px ≈ 0,25°), `PULSAR`; 40° ± 3° (± 6°); encaje a 0,04 m (0,10 m asistido); 0,5 s de `PULSAR` largo | Constantes que condicionan F4, F5b y F6 |
| `design/slice/slice-v0.3.md` · §21 | Plataforma PC, mando compatible, 1920 × 1080 | Base de las fórmulas en píxeles |
| `design/art/art-bible.md` · §3.3, §7.3, §4.5 | Icono de interacción, glifos de prompts, márgenes seguros, icono grande de accesibilidad | Condiciona la sección Visual/Audio |
| `design/gdd/estado-y-bus-de-eventos.md` · regla 10 y Dependencies | Los avisos «dispositivo de entrada cambiado» (regla 3) y «contexto de entrada cambiado» (regla 6) se documentan aquí; Entrada figura allí como emisor blando | Este sistema los emite por el bus |
| `design/gdd/systems-index.md` | Fila 1 y dependientes 2, 6, 7, 19, 21, 22, 24, 25, 27, 30 | Debe reflejar la tabla de Dependencies |
| `docs/engine-reference/godot/modules/input.md` | SDL3 (4.5), foco dual (4.6), identificación por tipo de evento (4.7) | Restricciones de motor para la implementación |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/input/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante; **V** = captura retenida en `production/qa/evidence/`, bloqueante. Tolerancia numérica ±0,001 salvo indicación. Los valores marcados † en Formulas pueden cambiar tras el playtest; los criterios numéricos se actualizan con ellos. El GDD no define presupuesto de latencia ni de CPU y no se inventa uno.

**Reglas (acciones, dispositivos y contextos)**
- **AC-01 (R1, L)**: **GIVEN** el mapa de acciones cargado, **WHEN** se listan, **THEN** existen solo las acciones de la regla 1 y no existen `correr`, `agacharse` ni `saltar`.
- **AC-02 (R2, L)**: **GIVEN** teclado y mando conectados, **WHEN** se emite `interactuar` desde cada uno, **THEN** ambas llegan al juego sin elegir dispositivo.
- **AC-03 (R3, L + V)**: **GIVEN** la partida recién arrancada, **THEN** el dispositivo activo es teclado/ratón; **WHEN** llega una tecla o botón, **THEN** el dispositivo activo cambia de inmediato y se emite una sola vez «dispositivo de entrada cambiado». *(V: los iconos del prompt cambian; se cierra cuando exista el sistema 24.)*
- **AC-04 (R4, L + I)**: **GIVEN** el mapa de acciones y `default_bindings.json`, **THEN** ninguna acción tiene una asignación que combine dos botones, una doble pulsación o un temporizador de reacción, y las únicas esperas son `t_hold` y el arrastre (L). **GIVEN** el recorrido completo del slice con cada dispositivo, **THEN** el playtest documentado no registra ninguna acción que lo exija (I).
- **AC-05 (R5, L)**: **GIVEN** el contexto `inspección`, **WHEN** llega `mover`, **THEN** se descarta.
- **AC-06 (R6, L)**: **GIVEN** `vista cercana` con el cursor en (X, Y) y luego `menú` encima, **WHEN** se sale del menú, **THEN** el contexto y el cursor vuelven a (X, Y).
- **AC-07 (R7, L)**: **GIVEN** cualquier contexto salvo una carga de escena, **WHEN** llega `pausa`, **THEN** se abre el menú y el tiempo de juego se detiene; **WHEN** llega `pausa` o `atrás` con el menú abierto, **THEN** se cierra y se restaura el contexto inferior con un solo cierre por pulsación; **WHEN** llega `pausa` durante una carga de escena, **THEN** no se abre.
- **AC-08 (R8, L)**: **GIVEN** el contexto `sin control`, **WHEN** se pulsa `interactuar` y termina la transición, **THEN** no se dispara; **WHEN** se pulsa `pausa`, **THEN** abre el menú.
- **AC-09 (R9, L)**: **GIVEN** F2 y F3, **WHEN** se mira, **THEN** con relative = (1000, 0) el giro entregado se limita a 45° (tope de F2) y con delta = 0,5 s a 0,1 s de F3; el sistema entrega solo el cambio de orientación y no recibe ni aplica ningún límite de pitch o yaw de la cámara.
- **AC-10 (R10, L + V)**: **GIVEN** un objeto sin `leer`, **WHEN** se pulsa `interactuar`, **THEN** la acción se dispara al pulsar; **GIVEN** un documento, **WHEN** la pulsación dura 0,18 s, **THEN** activa al soltar; **WHEN** dura 0,62 s, **THEN** se lanza `leer` y un indicador de progreso es visible (V).
- **AC-11 (R11, L)**: **GIVEN** el contexto `inspección`, **WHEN** llega `mirar`, **THEN** gira el objeto y no la cámara; **WHEN** llega `atrás`, **THEN** se suelta.
- **AC-12 (R12, I + V)**: **GIVEN** el mando en `vista cercana` u `ordenador`, **THEN** cualquiera de los dos sticks mueve el cursor; en `llamada` y `menú`, solo el derecho; en `exploración` no hay cursor y el ratón queda capturado (V).
- **AC-13 (R13, L)**: **GIVEN** `seleccionar` mantenida, **WHEN** el cursor se mueve 8 px o más, **THEN** se emite `agarrar`; **WHEN** se mantiene 0,5 s moviéndose menos de 8 px, **THEN** se emite `mantener`; **WHEN** se rota con el ratón, **THEN** 160 px horizontales dan 40° y el cursor queda quieto.
- **AC-14 (R14, L)**: **GIVEN** el ajuste «alternar» activo, **WHEN** se pulsa una vez, **THEN** `leer`, `mantener` y `agarrar` empiezan y otra pulsación los termina; **WHEN** llega `atrás` o cambia el contexto, **THEN** el gesto se cancela. Por defecto el ajuste está desactivado.
- **AC-15 (R15, L)**: **WHEN** se reasigna `interactuar` a `F`, **THEN** `F` funciona y `E` ya no; se permiten dos asignaciones por acción y dispositivo y la tercera se rechaza; `mover` y `mirar` se reasignan como conjunto; las acciones `ui_*` no se pueden reasignar.
- **AC-16 (R16, L)**: **WHEN** se asigna a una acción una entrada ya usada por otra del mismo contexto, **THEN** se ofrece intercambiar o cancelar; entre contextos distintos se permite.
- **AC-17 (R17, L)**: **WHEN** se quita la última asignación de `pausa`, `atrás` o `interactuar` en un dispositivo, **THEN** se rechaza; «restablecer» funciona por acción y por dispositivo.
- **AC-18 (R18, L)**: **GIVEN** los ajustes de manejo cambiados, **WHEN** se exportan y se importan, **THEN** se conservan todos, incluidos sensibilidad e inversión vertical por dispositivo.
- **AC-19 (R19, L)**: **GIVEN** `assets/data/input/default_bindings.json` modificado, **WHEN** arranca el juego, **THEN** el cambio se refleja sin tocar código; importar un bloque válido restaura las asignaciones.
- **AC-20 (R20, I)**: **GIVEN** el contexto `ordenador` con teclado físico, **THEN** se escriben caracteres. *(Con mando no hay criterio hasta definir el teclado en pantalla; ver Open Questions.)*
- **AC-21 (R21, I)**: **GIVEN** `interactuar` mantenida, **WHEN** la ventana pierde el foco, **THEN** la acción se cancela sin disparar `leer` y se abre la pausa.
- **AC-22 (R22, I)**: **GIVEN** el mando como dispositivo activo, **WHEN** se desconecta, **THEN** se abre la pausa con «Mando desconectado», teclado y ratón pueden reanudar y al reconectar se ofrece continuar; si el mando no era el activo, no ocurre nada visible.

**Fórmulas (valores del ejemplo, tolerancia ±0,001 salvo indicación)**
- **AC-F1 (L)**: **GIVEN** v = (0,5; 0,4), **THEN** r = 0,613; \|v\| = 0,15 → 0; \|v\| = 0,14 → 0; \|v\| = 0,95 → 1; \|v\| = 1 → 1.
- **AC-F2 (L)**: **GIVEN** relative = (18, −6), s_m = 1, inv = +1, **THEN** yaw = 1,8° y pitch = −0,6°; 3.600 px dan 360°; el resultado es idéntico simulando 30 y 144 fps; un pico enorme se limita a ±45° por fotograma.
- **AC-F3 (L)**: **GIVEN** r = 0,613, **THEN** ω = 57,6 °/s (±0,1) y 0,96 °/fotograma a 60 fps y 1,92 °/fotograma a 30 fps; con delta = 0,5 s se usa 0,1 s; con ω_max = 120 y s_s = 2 el máximo es 240 °/s, y con ω_max = 180 y s_s = 2, 360 °/s.
- **AC-F4 (L)**: **GIVEN** el ratón, **THEN** 160 px = 40°; **GIVEN** el mando, **THEN** r = 0,71 → 30 °/s (±0,5), r = 0,35 → 7,4 °/s, r = 0,2 con freno → 1,2 °/s; soltar el stick deja la velocidad en 0 y conserva el ángulo.
- **AC-F5 (L)**: **GIVEN** r = 0,613, **THEN** v_c = 338 px/s (±1); r = 0,2 → 36 px/s; r = 1 con s_c = 1,5 → 1.350 px/s; la posición queda dentro de la ventana. **GIVEN** d = 40, v_c = 100 y 60 fps, **THEN** w = 0,375, factor = 0,080, Δp sin tope = 1,2 px/fotograma y Δp final = 0,833 px/fotograma (±0,01); no hay atracción con d < 3 px, con v_c ≥ 450 px/s, con v_c = 0 ni con el ajuste desactivado; el objetivo cambia solo si otro candidato está más cerca por más de 8 px. **Escape:** **GIVEN** cada combinación de extremos (s_c = 0,5 y 1,5; v_max = 400 y 1600; λ = 2 y 10; R = 32 y 128) y cualquier r > 0 fuera de la zona muerta, **THEN** la velocidad neta del cursor hacia fuera del objetivo es mayor que 0 (la tracción nunca supera `0,5 · v_c`). Con delta = 0,5 s se usa 0,1 s.
- **AC-F6 (L)**: **GIVEN** t_hold = 0,5 s, **THEN** 0,18 s es corta y 0,62 s es larga; mantener 0,6 s moviéndose 3 px es `mantener` y moviéndose 12 px es `agarrar`.
- **AC-F7 (L)**: **GIVEN** el ratón, **THEN** 4 px en 0,2 s no cambian el dispositivo y 20 px sí; **GIVEN** el stick, **THEN** 0,2 no cambia y 0,35 durante 0,1 s sí; tras un cambio, el movimiento solo no cambia de nuevo durante 0,4 s.
- **AC-F8 (L)**: **GIVEN** una transición de cámara o animación que no termina, **WHEN** pasan 3 s, **THEN** se registra el error y se libera el contexto; **GIVEN** un `sin control` pedido con una duración máxima de 8 s, **WHEN** pasan 8 + 2 s, **THEN** se registra el error y se libera, y a los 3 s no se ha liberado; **GIVEN** una petición de `sin control` sin duración declarada, **THEN** se aplica el tope de 3 s y se registra la omisión. Una tecla mantenida durante la transición se ignora hasta soltarla.

**Casos límite**
- **AC-E1 (L)**: entrar en un contexto que ya está arriba se ignora; salir de uno que no es el de arriba se rechaza, se registra y la pila no cambia.
- **AC-E2 (I)**: **GIVEN** una escena descargada con la pila fuera de `exploración`, **THEN** la pila queda en `sin control`.
- **AC-E3 (L)**: **GIVEN** `seleccionar` mantenida al entrar en `vista cercana`, **THEN** no cuenta hasta soltarla y volver a pulsar.
- **AC-E4 (L)**: **GIVEN** el mando desconectado durante `ANIM_PHONE_PICKUP`, **THEN** la pausa se abre al terminar la animación.
- **AC-E5 (L)**: importar un archivo con una acción inexistente descarta esa entrada con una línea en el log; si hay conflicto en el mismo contexto, gana la primera de la tabla y la otra vuelve a su valor por defecto; `Esc` cancela la captura de una asignación sin cambios.
- **AC-E6 (L)**: `mantener` sobre un elemento sin acción de mantener se trata como `seleccionar` al soltar.
- **AC-E7 (I)**: con el menú abierto, recuperar el foco de la ventana no lo cierra.
- **AC-E8 (I)**: **GIVEN** una pausa durante `inspección`, `lectura` o `sin control`, **WHEN** se reanuda, **THEN** el objeto o la página siguen como estaban y el tope de la transición no avanzó durante la pausa.
- **AC-E9 (L)**: **GIVEN** un suscriptor y la pila en `exploración`, **WHEN** se entra en `inspección` y luego se sale, **THEN** recibe dos veces «contexto de entrada cambiado», con (`exploración`, `inspección`) y (`inspección`, `exploración`); **WHEN** se pide entrar en un contexto que ya está arriba o salir de uno que no lo está, **THEN** no recibe nada; **WHEN** se descarga la escena con la pila fuera de `exploración`, **THEN** recibe un solo aviso con `sin control` como contexto nuevo.
- **AC-E10 (L)**: **GIVEN** la pila con solo el menú de título, **WHEN** llega `pausa`, `atrás` o `ui_atrás`, **THEN** el menú sigue abierto; **GIVEN** `pausa` reasignada a `Enter` o a una flecha, **THEN** se rechaza con el mensaje de conflicto.
- **AC-E11 (I)**: **GIVEN** la ventana que pierde el foco durante una carga de escena, **THEN** la pausa se abre al terminar la carga y no antes.
- **AC-E12 (L)**: **GIVEN** `interactuar` mantenida en `exploración` sobre un documento, **WHEN** el contexto cambia antes de 0,5 s, **THEN** la pulsación se cancela y no se lanza `leer`.

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Teclado en pantalla para el mando** en el campo de búsqueda del ordenador («transición»): ¿teclado virtual, sugerencia autocompletada u otra solución? Hoy no hay criterio de aceptación para mando en `ordenador` (AC-20). | `/design-system` del sistema 19 y `/ux-design` | GDD del sistema 19 |
| 2 | **Equivalencia píxeles ↔ metros** del encuadre del puzle 3 (supuesto de partida: 1.200 px/m, 0,04 m = 48 px, 0,10 m = 120 px); cada puzle debe entregar su tolerancia en píxeles para F5b. | GDD del sistema 13 (y 9) | GDD del sistema 13 |
| 3 | **Tamaño y separación mínima** de los elementos pequeños de los puzles 1 y 4: si hay centros a menos de 2·R, la atracción es ambigua. | GDD de los sistemas 11 y 14 | Esos GDD |
| 4 | **Cursor visual** de los puzles (forma no circular, art bible §7.3) e **indicador de progreso** sin barras. | `/art-bible` (ampliar) o `/ux-design` | Fase de UX |
| 5 | **Auto-repetición de `ui_*`** (velocidad de navegación al mantener una dirección). | `/ux-design` | Fase de UX |
| 6 | **Foco y cursor simultáneos en `llamada` y `menú`:** qué resalta el último dispositivo usado (foco dual de Godot 4.6). | `/ux-design` | Fase de UX |
| 7 | **Teclado sin ratón:** el gesto `rotar` y el cursor no tienen alternativa solo con teclado. ¿Se exige por accesibilidad? | Sistema 30 (Accesibilidad) | GDD del sistema 30 |
| 8 | **Gesto de cámara** de las pistas (slice §10): ¿es una acción de entrada o solo una cámara que apunta? Si es entrada, falta definirla aquí. | GDD del sistema 17 (Pistas) | GDD del sistema 17 |
| 9 | **Acción de leer con duración** (A04 «Leer (2 s)»): ¿el umbral de 0,5 s es el tiempo de mantener y los 2 s el de lectura? | GDD del sistema 20 (Documentos) | GDD del sistema 20 |
| 10 | **Valores †** de F1 a F7 y el tope de 3 s de F8: validar en el primer playtest. | Playtest (slice §23.4) | Primer playtest |
| 11 | ~~Índice de sistemas: añadir el sistema 1 como dependencia de 6, 19, 21, 22, 24 y 27.~~ **Resuelta:** el índice ya lo refleja. | — | Cerrada (2026-11-08) |
| 12 | **Duración máxima de cada escena dirigida** que pide `sin control` (F8): el director de escenas debe declararla al pedir el contexto; hay que fijarla por escena (apagón, llamada, ascensor). | GDD del sistema 21 (Director de escenas) | GDD del sistema 21 |
| 13 | **Resolución lógica del cursor:** confirmar que los píxeles de F5a, F5b y F6 son del viewport lógico 1920 × 1080 (modo de estiramiento). | `/architecture-decision` | Fase de arquitectura |
