# Entrada y controles

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Autonomía como progresión · Tensión sin castigo (accesibilidad y control sin fricción)

## Summary

[To be designed]

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

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
4. **Un gesto, un botón.** Ninguna acción exige pulsar dos botones a la vez, doble pulsación ni precisión temporal. El único gesto compuesto es mantener un botón mientras se mueve el cursor o un stick (`agarrar`, `rotar`), y los únicos gestos con tiempo son la pulsación prolongada (`leer`, `mantener`) y el arrastre; todos tienen la alternativa de la regla 14.

**Contextos de entrada**

5. **Un contexto activo.** Hay una pila de contextos y solo el de arriba recibe acciones: `exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`, `llamada`, `menú` y `sin control`. Las acciones de un contexto no existen en los demás (por ejemplo, `mover` solo en `exploración`).
6. **Quién abre y cierra contextos.** Este sistema posee la pila y expone «entrar en» y «salir de» un contexto. Los piden: Interacción (7) para `inspección`, `lectura`, `vista cercana` y `ordenador`; el menú de pausa (25) para `menú`; la llamada (22) para `llamada`; y el director de escenas (21) para `sin control`. Salir restaura el contexto anterior tal como estaba (posición del cursor incluida).
7. **Pausa.** `pausa` abre el menú sobre cualquier contexto salvo durante una carga de escena, detiene el tiempo de juego y, al cerrarlo, restablece el contexto inferior. Con el menú abierto, `atrás` y `pausa` lo cierran.
8. **Transiciones.** Mientras una transición de cámara o de animación bloquea el contexto (p. ej. la cámara acercándose al marco del puzle 3, o la animación de descolgar), solo se acepta `pausa`; el resto de acciones se descarta y **no se guarda para después**.

**Exploración, inspección y lectura**

9. **Mirar.** `mirar` entrega un cambio de orientación por fotograma, calculado con la sensibilidad del dispositivo (ver Formulas). La orientación y sus límites son del sistema de jugador (2); este sistema no limita ángulos.
10. **Interactuar.** `interactuar` es el único botón del mundo: pulsación corta = activar, coger o inspeccionar lo que el icono contextual indica; pulsación prolongada (umbral de Formulas) sobre un documento o texto = `leer`. Para que activar no tenga retraso, la acción corta se dispara **al pulsar**, salvo sobre objetos que ofrecen `leer`: en esos, la pulsación corta se decide **al soltar** (más corta que el umbral) y mientras se mantiene se muestra una barra de progreso. Qué hace cada objeto lo decide Interacción (7).
11. **Inspección.** Con un objeto en la mano, `mirar` pasa a girar el objeto en lugar de la cámara (`rotar_objeto`); `atrás` lo suelta.

**Puzles y vista cercana**

12. **Cursor.** En `vista cercana`, `ordenador` y `llamada` hay un cursor en pantalla. Con ratón es el cursor real, libre dentro de la ventana. Con mando es un **cursor virtual** movido con cualquiera de los dos sticks en `vista cercana` y `ordenador`, y solo con el derecho en `llamada` y `menú` (donde el izquierdo y la cruceta mueven el foco, `ui_*`); lleva velocidad y atracción asistida hacia el elemento interactivo más cercano (ver Formulas), y la atracción se puede desactivar. En `exploración` e `inspección` el cursor no existe y el ratón queda capturado.
13. **Gestos de puntero.** Se mapean a una sola secuencia en ambos dispositivos:
    - `seleccionar` = clic o `A`/`✕` (equivale a `CLICK` y a `PULSAR` corto del Anexo B).
    - `agarrar` = mantener `seleccionar` y mover el cursor más allá de un umbral de inicio de arrastre (ver Formulas), para distinguirlo de `mantener` (`ARRASTRAR`).
    - `rotar` = mantener `seleccionar` sobre un control giratorio y mover en horizontal; con ratón, 1 píxel = 0,25° (slice, Anexo B); con mando, velocidad angular proporcional al stick (ver Formulas). Mientras se rota, el cursor queda quieto.
    - `mantener` = mantener `seleccionar` el tiempo del umbral (`PULSAR` largo del puzle 3).
    - «Pasar el cursor» (resaltado de la ficha, puzle 4) = cursor sobre el elemento; con mando, la atracción asistida o el cursor virtual producen el mismo resaltado.
    Cómo reacciona cada puzle lo define su GDD; este sistema solo entrega la secuencia.

**Accesibilidad y personalización**

14. **Alternar en lugar de mantener.** Existe un ajuste para que `leer`, `mantener` y `agarrar` se activen con una pulsación y se terminen con otra. Por defecto está desactivado.
15. **Reasignación.** Todas las acciones de exploración, inspección, lectura y vista cercana se pueden reasignar, por separado para teclado/ratón y para mando, con hasta dos asignaciones por acción y dispositivo. Los ejes `mover` y `mirar` se reasignan como conjunto. No se pueden reasignar los movimientos del ratón ni las acciones `ui_*` (navegación fija con flechas/`Enter` y cruceta/`A`), pero sí los botones del ratón.
16. **Conflictos.** Dos acciones del mismo contexto no pueden compartir entrada: el intento muestra el conflicto y ofrece intercambiar o cancelar. Acciones de contextos distintos sí pueden compartirla (p. ej. `interactuar` y `seleccionar`).
17. **Mínimos garantizados.** `interactuar`, `atrás` y `pausa` conservan siempre al menos una asignación por dispositivo; quitar la última se rechaza. «Restablecer» existe por acción y para todo el dispositivo.
18. **Ajustes de manejo.** Son propiedad de este sistema y los guarda Ajustes (6): sensibilidad de mirada (ratón y stick por separado), invertir eje vertical (por dispositivo), zonas muertas de sticks, velocidad del cursor virtual, atracción asistida activada/desactivada y alternar-en-lugar-de-mantener.
19. **Datos, no código.** Las asignaciones por defecto y los valores de ajuste iniciales viven en un fichero de datos (`assets/data/input/default_bindings.json`). Las asignaciones personalizadas se entregan a Ajustes como un bloque que este sistema sabe exportar e importar; Ajustes lo guarda y lo reaplica al arrancar.
20. **Texto.** En el ordenador (contexto `ordenador`) el teclado físico entrega caracteres. El mando no puede escribir: necesita un teclado en pantalla controlado con foco, a definir en el GDD del ordenador (19) y de interfaz.

**Pérdida de foco y de mando**

21. **Ventana sin foco.** Si la ventana pierde el foco, se abre el menú de pausa automáticamente.
22. **Mando desconectado.** Si el mando era el dispositivo activo y se desconecta, se abre el menú de pausa con el mensaje «Mando desconectado»; al reconectar se ofrece continuar. Teclado y ratón siguen valiendo para reanudar.

**Asignaciones por defecto**

| Acción | Teclado y ratón | Mando |
|---|---|---|
| `mover` | `W` `A` `S` `D` | Stick izquierdo |
| `mirar` | Movimiento del ratón | Stick derecho |
| `interactuar` · `leer` (mantener) | `E` · clic izquierdo | Botón sur (`A` / `✕`) |
| `atrás` | Clic derecho · `Retroceso` | Botón este (`B` / `○`) |
| `pausa` | `Esc` | `Start` / `Options` |
| `mover_cursor` | Ratón | Cualquiera de los dos sticks |
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

Propuestas por `systems-designer`. † = valor propuesto, **a validar en playtest**; las constantes que vienen del slice no llevan †. Todos los valores se leen de `assets/data/input/default_bindings.json`; los ajustables por el jugador van marcados «(ajuste)».

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

**Output Range:** 0 si \|v\| ≤ 0,15; 1 si \|v\| ≥ 0,95. Continua, sin salto al salir de la zona muerta; se evalúa en radial, no por eje.
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

**Output Range:** 0 a ω_max · s_s (240 °/s en el peor caso permitido). Curva de potencia: una lineal dificulta la precisión y una en S añade zonas planas. Con 120 °/s, un giro de 180° tarda 1,5 s y se recorre el campo de visión (70°) en ~0,85 s: lento y suficiente para un juego de caminar.
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
**Example (puzle 5, de 0° a 40°, tolerancia ±3°):** con r = 0,71 (30 °/s) se llega a 30° en 1,0 s; con r = 0,35 (7,4 °/s), a 38° en 1,1 s; con r = 0,2 y freno (1,2 °/s), a 40° en 1,7 s. Total ~4 s (~2 s si va directo). Con 0,25 s de reacción, el error es de 1,8° a 7,4 °/s y de 0,3° a 1,2 °/s, dentro de ±3°. Con ratón, 40° = 160 px y ±3° = ±12 px. El modo fino (accesibilidad) baja a 25 °/s. El modo asistido (±6°) no requiere nada más.

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

`w = clamp(1 − d/R, 0, 1) × g;   g = clamp((v_off − v_c)/(v_off − v_on), 0, 1);   Δp = (t − p) × (1 − e^(−λ·delta)) × w`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| d | float (px) | ≥ 0 | calculated | Distancia al centro del elemento interactivo más cercano |
| R | float (px) | 32–128 | data file, 64† | Radio de captación base; **por elemento: R = max(R base, tolerancia del elemento en px)** |
| λ | float (1/s) | 2–10 | data file, 5† | Intensidad |
| v_on, v_off | float (px/s) | — | data file, 300†, 450† | Tramo en que la atracción se apaga al moverse rápido |
| t, p | Vector2 (px) | — | calculated | Centro del elemento y posición del cursor |

**Output Range:** tracción máxima ~80 px/s (a d = R/2). Se anula con d < 3 px (evita temblor), con v_c ≥ 450 px/s y si el ajuste está desactivado. El jugador siempre puede escapar (basta r ≥ 0,30). El objetivo cambia solo si otro candidato está más cerca por más de 8 px†.
**Example:** d = 40, v_c = 100, 60 fps → w = 0,375; factor 0,080; Δp = 1,2 px/fotograma (72 px/s).

### F6 · Pulsación prolongada y umbral de arrastre

The pulsación prolongada formula is defined as:

`largo = (t_ahora − t_pulsado) ≥ t_hold;      arrastre = (|p − p_pulsado| ≥ d_arrastre)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t_hold | float (s) | 0,3–1,0 (hasta 1,5 en accesibilidad) | data file, 0,5 (slice, B.3) (ajuste de accesibilidad) | Umbral de pulsación prolongada |
| d_arrastre | float (px) | 4–16 | data file, 8† | Distancia mínima para que mantener `seleccionar` sea `agarrar` y no `mantener` |
| p, p_pulsado | Vector2 (px) | — | calculated | Posición actual del cursor y al pulsar |

**Output Range:** el tiempo es real, no escalado. Por debajo de 0,3 s, los toques y el temblor activan `leer` sin querer; por encima de 1,0 s el juego parece no responder; hace falta una barra de progreso.
**Example:** con 0,5 s, una pulsación de 0,18 s es corta y una de 0,62 s es larga. Mantener 0,3 s moviendo 3 px es `mantener` (aún no es arrastre); moviendo 12 px es `agarrar`.

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

No hay fórmula: la duración la fijan la cámara o el director de escenas. Sí hay un **tope de seguridad de 3 s†**, tras el cual se registra el error y se libera el contexto. Una tecla mantenida durante la transición no debe dispararse al terminar (se ignora hasta soltarla).

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
| Tope de transición | 3 s† | 1–5 |

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

**Texto**
- **If se usa el mando en un campo de texto sin teclado en pantalla disponible** (hasta que se defina en el sistema 19): el campo no es operable con mando; es una laguna registrada en Open Questions, no un comportamiento definido.

## Dependencies

**Aguas arriba (de qué depende):** ninguna dura. Usa las capacidades de entrada del motor (teclado, ratón, mando) y un fichero de datos con las asignaciones por defecto. Necesita **leer** de Ajustes (6) las asignaciones personalizadas al arrancar; ese contacto va por el bloque exportable de la regla 19, de modo que Ajustes depende de este sistema y no al revés.

**Aguas abajo (quién depende de este sistema).**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 2 Jugador | Dura | `mover`, `mirar` |
| 7 Interacción | Dura | `interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero; petición de contextos |
| 25 Menú de pausa | Dura | `pausa`, `ui_*`; contexto `menú`; API de reasignación |
| 30 Accesibilidad | Dura | API de reasignación y ajustes de manejo |
| 6 Ajustes | Dura (**no está en el índice**) | Guarda y reaplica el bloque de asignaciones y ajustes de manejo |
| 19 Ordenador | Blanda (**no está en el índice**) | Cursor, `seleccionar`, texto |
| 22 Llamada | Blanda (**no está en el índice**) | Contexto `llamada`, `ui_*` |
| 24 Prompt de interacción | Blanda (**no está en el índice**) | Dispositivo activo y asignación vigente de cada acción (para el icono) |
| 27 Pantalla de título y cierre | Blanda (**no está en el índice**) | `ui_*`, cursor |
| 21 Director de escenas | Blanda (**no está en el índice**) | Peticiones de `sin control` |
| 11 a 16 Puzles | Indirecta (vía 7) | Gestos de puntero |

**Correcciones pendientes en el índice de sistemas** (se aplican al cerrar este GDD): añadir el sistema 1 como dependencia de 6, 19, 21, 22, 24 y 27.

**Bidireccionalidad.** Ninguno de estos sistemas tiene todavía GDD (salvo el 3, que no depende de este). Cada uno debe listar a Entrada y controles como dependencia y usar los nombres de acción de la regla 1.

## Visual/Audio Requirements

[To be designed]

## Game Feel

[To be designed]

## UI Requirements

[To be designed]

## Cross-References

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
