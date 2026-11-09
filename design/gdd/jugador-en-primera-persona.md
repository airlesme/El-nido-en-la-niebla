# Jugador en primera persona (movimiento, cámara, manos)

> **Status**: Designed (pendiente de design-review)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (cámara sin sacudidas, sin pérdida de control, opciones de confort) · Autonomía como progresión (nada dirige la mirada del jugador) · El espacio expresa la emoción (peso del paseo, manos como sujeto de la luz, pose para el reflejo)

## Summary

Es el cuerpo de Vera visto desde dentro: caminar a velocidad de paseo por la planta 9, mirar a su alrededor con la cámara a 1,62 m y ver sus manos haciendo cada gesto del slice. Convierte `mover` y `mirar` de Entrada y controles en un movimiento lento, pesado y sin deslizamientos, y presta su cámara y sus manos a Interacción, Ordenador y Llamada cuando el jugador mira de cerca. Existe porque el slice se juega entero desde ese punto de vista y porque *Tensión sin castigo* exige que la cámara nunca sacuda, gire sola ni se quede sin respuesta, y que el balanceo y el campo de visión se puedan reducir.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `1 Entrada y controles` (dura) · `4 Escena de planta` (dura: aparición, suelo y zonas) · `6 Ajustes persistentes` (blanda: `balanceo_camara`, `campo_vision`, propuestos)

## Overview

El Jugador es la entidad que el jugador controla: un cuerpo con colisión, una cámara a la altura de los ojos de Vera y un par de manos. Sus responsabilidades son cuatro. **Moverse**: recibe el vector `mover` de Entrada y lo convierte en una velocidad de paseo única (sin sprint, salto ni agacharse, slice §5 y A.0), con aceleración y frenado cortos, colisión con los muros y el mobiliario y deslizamiento a lo largo de ellos. **Mirar**: aplica a la cámara el cambio de orientación `mirar` de Entrada, con el pitch acotado, sin giro lateral de la cámara (roll) y sin ningún movimiento que el jugador no haya pedido, salvo un balanceo opcional al caminar. **Mostrar manos**: las manos de Vera están siempre en pantalla; reposan, se balancean al caminar y ejecutan los gestos que otros sistemas piden (abrir un cajón, teclear, girar una lámpara, descolgar, pasar página, sostener y girar un objeto, encajar una pieza). **Prestar la cámara**: en `vista cercana`, `ordenador` y similares, Interacción (7) toma la cámara con una petición que el Jugador acota en tiempo y devuelve intacta.

No es una pantalla ni tiene estado de partida: no escribe ni lee hechos, no se guarda (el guardado no almacena posición, slice D.3) y se coloca de nuevo en cada carga. Aporta además dos servicios a otros sistemas: la **pose** del jugador (para que Atmósfera reactiva (28) dibuje el reflejo con retardo de la escena 4) y un **rayo de visión** (para que Interacción (7) apunte). Todos los números de este GDD viven en `assets/data/player/player.json` (Tuning Knobs).

## Player Fantasy

Vera es una persona cansada que recorre de noche un edificio que conoce demasiado bien. El jugador debe sentir **peso y presencia** (estética de Sensación y Fantasía, MDA): paso lento, sin prisa posible, el pasillo de 24 m que se hace largo y el silencio entre pasos. Debe sentir **control sereno** (Autonomía y Competencia, SDT): la mirada va donde él quiere, nunca la fuerza el juego, y por eso lo inquietante (un reflejo tardío, una luz que falla) lo descubre él al mirar y no se le impone. Las manos son su prueba de estar ahí: pequeñas, limpias, iluminadas por el monitor o por el teléfono; cuando hacen algo, el jugador lo reconoce como un gesto suyo.

Lo que **no** debe sentir: mareo, deslizamiento sobre hielo, sacudidas de cámara «de susto», pérdida de control porque el juego quiere enseñarle algo. El susto de este juego es sonido, luz y silencio (pilar 4); el cuerpo del jugador es el único elemento estable de la pantalla.

## Detailed Design

### Core Rules

† = valor propuesto, a validar en el prototipo gris o en playtest. Los nombres de operaciones y nodos son identificadores de código (inglés); el formato técnico lo fija un ADR.

**Cuerpo y colisión**

1. **Una instancia, un cuerpo.** El Jugador es un cuerpo cinemático con una cápsula de colisión de radio `radio_capsula` (0,25 m†) y altura `altura_capsula` (1,75 m†), con los pies en el suelo. No tiene física propia más allá de mantenerse pegado al suelo (la planta es plana, sin escalones ni rampas) y deslizarse a lo largo de lo que choca. **No empuja nada**: puertas, sillas y objetos son estáticos o los mueve su sistema (7, 8) por código (plan técnico §1).
2. **Solo se camina.** No existen sprint, salto, agacharse ni tumbarse (slice §5 y A.0; Entrada, regla 1). Una acción con esos nombres no existe en el Jugador.
3. **Pasos mínimos del diseño de espacios.** Un paso que el jugador debe poder cruzar tiene al menos 0,60 m de ancho (diámetro de la cápsula, 0,50 m, más 0,10 m de margen); un hueco que no debe cruzar es menor de 0,50 m. La puerta de 1,00 m y el pasillo de 2,60 m (slice A.0, A.1) caben con holgura.
4. **Sensor de zona.** Además de la cápsula, el Jugador lleva un sensor de punto (`radio_sensor_zona`, 0,05 m†) en el centro de su cápsula, a la altura de la cintura, que es lo que detectan los volúmenes `T-…` de la escena (4). Así «X entre 9,0 y 10,0» (slice A.3) se cumple cuando el **centro** del jugador cruza la línea, no cuando lo hace el borde de la cápsula (0,25 m antes).
5. **Capa propia.** La cápsula está en su propia capa de colisión y el rayo de interacción (7) la excluye.

**Movimiento**

6. **Entrada.** Cada tick de física el Jugador lee el vector `mover` (X lateral, + a la derecha; Y avance, + hacia delante) que entrega Entrada. Solo lo lee en estado Libre (regla 22); en cualquier otro estado el objetivo es `(0, 0)`. Si su longitud supera 1 se normaliza a 1 (defensivo); por debajo de 1 se respeta (el stick es analógico, el teclado entrega longitud 1).
7. **Velocidad única, analógica.** La velocidad objetivo es `v_paseo` (1,6 m/s†) multiplicada por el módulo del vector; la marcha atrás se reduce por `k_atras` (0,8†) (F1). No hay otras marchas: con el stick a medias el jugador camina más despacio, pero no corre.
8. **Velocidad en el cuerpo, no en el mundo.** La velocidad se calcula y se acelera **en el marco del cuerpo** (adelante/lateral) y después se gira con el yaw actual. Girar la cabeza mientras se camina redirige el movimiento al instante, sin la sensación de «arrastre» lateral que produce acelerar en coordenadas del mundo (F2).
9. **Aceleración y frenado cortos.** `t_acel` (0,20 s†) para llegar a `v_paseo` y `t_freno` (0,15 s†) para parar (F2). Sin deslizamiento tras soltar: el jugador se detiene en ≤ 0,11 m.
10. **Colisión.** Al chocar con un muro o mueble, el jugador desliza a lo largo de la superficie (la componente tangente se conserva, la normal se anula). Empujar contra una pared no produce rebote ni vibración.
11. **Tiempo.** El movimiento se calcula en el paso de física fijo (`f_fisica`, 60 Hz† por defecto del proyecto) y se presenta interpolado entre pasos, de modo que a 30, 60 o 144 fps el jugador recorre la misma distancia por segundo (el ADR del Jugador fija el mecanismo). Con el tiempo de juego detenido (pausa) el Jugador no avanza ni anima.

**Cámara**

12. **Altura de ojos fija.** Los ojos están a **1,62 m** del suelo (slice A.0) y no cambian: no hay agacharse ni transición de altura. La cámara cuelga de un nodo de cabeza que gira en yaw con el cuerpo y en pitch por separado.
13. **Orientación.** Cada vez que Entrada entrega un cambio de orientación `Δθ` (yaw, pitch), el Jugador lo suma a su orientación **en el fotograma en que lo recibe**, sin multiplicarlo por el tiempo (Entrada F2 y F3 ya lo han hecho). El yaw es ilimitado (se normaliza a [−180°, 180°)); el pitch se limita a ±`pitch_max` (80°†) (F4). Entrada no limita ángulos (su regla 9); este es el único sitio donde se limitan.
14. **Sin roll, sin sacudidas, sin tirones.** La cámara nunca gira sobre su eje de visión (roll = 0 siempre). Ningún evento del juego —puertas, apagón, zonas, voces, el reflejo— mueve, sacude ni orienta la cámara del jugador, ni altera el campo de visión de forma transitoria. La única variación de posición que el Jugador aplica por sí mismo es el balanceo de la regla 16. Las excepciones son las dos cesiones voluntarias de la regla 18 y la colocación de una carga (regla 20).
15. **Sin suavizado ni aceleración de la mirada.** La orientación sigue 1:1 a lo que entrega Entrada: ningún filtrado añade latencia ni «inercia». (La curva del stick es de Entrada.)
16. **Balanceo al caminar (opcional).** Al caminar, la cámara se desplaza **solo en traslación** (vertical y lateral, nunca rotación) con un ciclo ligado a la distancia **realmente recorrida** (F3). Tres niveles en el ajuste `balanceo_camara`: `completo`, `reducido` (valor inicial†) y `ninguno`. Con `ninguno` la cámara no se mueve nunca respecto a los ojos fijos (offset exactamente 0). El balanceo se desvanece con la velocidad: parado no hay balanceo; contra una pared tampoco. El rayo de interacción y los detectores parten de los ojos **sin balanceo**.
17. **Campo de visión.** El valor de referencia del slice es **70° vertical** (el ajuste `campo_vision`, 60 a 90, inicial 70). Se limita además el campo horizontal a `fov_h_max` (120°†) para pantallas ultra anchas (F5). El cambio de `campo_vision` se aplica en el acto. Las manos no dependen de este valor (regla 25).
18. **Cesión de cámara.** Interacción (7) —y por extensión Ordenador (19)— puede pedir `ceder_camara(propietario, pose_destino, fov_destino, duración)` para la vista cercana de un puzle, un panel o el ordenador. El Jugador guarda su yaw y pitch, interpola la cámara a la pose pedida con una curva suave (smoothstep) en `duración` (acotada a `t_transicion_max`, 3 s, el tope de Entrada F8) y la mantiene allí. Mientras está cedida, el cuerpo no se mueve ni mira. `devolver_camara(propietario)` interpola de vuelta al yaw y pitch guardados en `t_devolver` (0,5 s†). Solo puede haber **un propietario**: otra petición de un propietario distinto se rechaza y se registra (en desarrollo, error visible). Un propietario solo puede devolver lo suyo.
19. **Rayo de visión.** El Jugador ofrece, en cualquier momento, el origen (ojos sin balanceo) y la dirección de la cámara. El alcance, el filtro y qué objeto es interactuable los decide Interacción (7). No existe una retícula permanente: el centro de la pantalla es el punto de mira y el icono contextual (24) aparece solo sobre lo interactuable (slice §16).
20. **Colocación.** El sistema 4 coloca al Jugador con una operación síncrona `colocar(posición, yaw, pitch)` (paso 5 de su secuencia de arranque, Escena de planta regla 9): el Jugador queda con velocidad cero, orientación dada, balanceo en reposo, cámara propia (se cancela cualquier cesión), manos en reposo sin objeto, y la memoria de poses vaciada y rellenada con la pose inicial (F6). No hereda nada de la escena anterior. En la planta es `spawn_office` (−3,0; 0,0), mirando hacia el ordenador V01; en Recepción, `spawn_elevator`.
21. **Fuera del mundo.** Una red de seguridad devuelve al jugador a su última pose segura si queda atrapado en geometría o cae por debajo de `y_min` (−2,0 m†); ver Edge Cases. Nunca se mueve al jugador por otro motivo sin que lo pida el sistema 4.

**Estados y contextos de entrada**

22. **El Jugador sigue el contexto de Entrada.** Lee el contexto activo (aviso «contexto de entrada cambiado») y se comporta según la tabla de States and Transitions. Solo en `exploración` recibe `mover` y `mirar`; en todos los demás contextos la cámara y el cuerpo reciben objetivo cero. Al salir de `exploración` **no se anula la velocidad de golpe**: el cuerpo frena con `t_freno` (regla 9), como si se hubiera soltado la tecla, de modo que la cámara no da un salto. Los ejes continuos no se descartan al recuperar el control (ver Dependencies, propuesta a Entrada).

**Manos**

23. **Siempre visibles.** Las manos de Vera están en pantalla en todo momento de juego, incluidos el reposo y el caminar (art bible §5.1: 0,3 a 0,6 m, siempre en pantalla). No llevan nada puesto (sin reloj, anillo ni pulsera): lo único que aparece en ellas son los objetos del juego, cuando se usan (art bible §5.1; los ítems de slice D.1 vuelven al «bolsillo visual», sin menú).
24. **Gestos por petición.** Las manos no deciden nada: otros sistemas piden gestos y reciben el aviso de que terminaron. Las operaciones son `reproducir_gesto(id, parámetros)`, `sostener(item_id)` / `soltar()`, `apuntar(punto_3d)` (la mano activa se orienta hacia un punto del mundo, para los puzles; cómo se resuelve lo fija el ADR) y `reposo()`. El catálogo de gestos del slice es la tabla de la sección Visual/Audio; los que bloquean el contexto de Entrada duran ≤ `t_transicion_max` (3 s). Una petición mientras otro gesto bloqueante está en curso se rechaza y se registra; no se encola.
25. **Plano propio.** Las manos se dibujan **encima del mundo** con su propio campo de visión (`fov_manos`, 60°†): no atraviesan muros aunque el jugador esté pegado a ellos, y su tamaño y forma no cambian con `campo_vision` ni con la relación de aspecto. Cómo se consigue (shader, sub-viewport, segunda cámara) lo fija el ADR junto al technical-artist (art bible, apartado de manos).
26. **Mano principal.** La derecha actúa (alcanza, agarra, gira, pasa página); la izquierda acompaña (sostiene el papel, el teléfono, el objeto en inspección). No hay opción de zurdos en el slice.
27. **Movimiento de las manos.** Con el balanceo en `completo` o `reducido`, las manos añaden al movimiento de la cámara un balanceo propio con retardo de fase, una pequeña inercia al girar la cabeza y una respiración en reposo (F3 y F7). Con `ninguno` las manos quedan quietas fuera de los gestos pedidos, y la respiración también se anula.
28. **Iluminación de las manos.** Las manos reciben la luz de la escena (el monitor, el teléfono desde abajo, la lámpara V06) y siempre conservan un mínimo de luz que las hace legibles, incluso en el apagón (art bible §5.1). El valor y el modo los fija el art director; el Jugador solo garantiza que el material no se desactiva.

**Servicios a otros sistemas**

29. **Pose del jugador.** En cada paso de física el Jugador anota su pose (posición, yaw, pitch, velocidad horizontal, fase del paso) en una memoria circular de `T_hist` (1,0 s†) y ofrece `pose_con_retardo(τ)` (F6) para 0 ≤ τ ≤ `T_hist`. Es lo que Atmósfera reactiva (28) usa para dibujar el reflejo con retardo de 0,6 s del patio de luces (slice C.4, plan técnico §3). Solo el Jugador escribe esta memoria; los demás la leen.
30. **Giro acumulado.** El Jugador ofrece `giro_acumulado()`: grados de yaw recorridos en los últimos `T_giro` (0,5 s†) (F8). Atmósfera (28) lo usa para decidir cuándo «el jugador gira la cabeza» y el reflejo vuelve a la normalidad (slice, escena 4); el umbral lo fija 28, no el Jugador.
31. **Pasos.** Cada vez que un pie «toca el suelo» según la distancia recorrida (F3), el Jugador emite una señal directa `paso(superficie, intensidad)` a Audio (23), con `intensidad` entre `i_paso_min` (0,4†) y 1,0 según la velocidad. No pasa por el bus de eventos (3): es de alta frecuencia y no tiene sentido guardarlo ni reproducirlo. La superficie la etiqueta el suelo de la escena (4); si no hay etiqueta se usa `default`. Los pasos suenan con cualquier valor de `balanceo_camara`.
32. **Sin estado de juego.** El Jugador no escribe hechos, no los lee y no se incluye en el guardado. Todo lo suyo se reconstruye en `colocar`.

### States and Transitions

| Estado | Cuándo | Cuerpo | Cámara | Manos | Sale hacia |
|---|---|---|---|---|---|
| **Sin escena** | Antes de cargar, o con la escena descargada | No existe o está inerte | — | — | Libre (por `colocar`, en estado Congelado hasta que Entrada devuelva `exploración`) |
| **Libre** | Contexto `exploración` | Camina con `mover` | Mira con `mirar`; balanceo según ajuste | Reposo + balanceo; pueden recibir gestos | Congelado · Cámara cedida · Sin escena |
| **Congelado** | Contextos `inspección`, `lectura`, `llamada`, `menú`, `sin control` y justo tras `colocar` | Objetivo cero: frena con `t_freno` y queda quieto | Fija en la orientación actual | Sostienen o ejecutan lo que se pida (objeto en inspección, papel en lectura, teléfono en llamada) | Libre · Cámara cedida · Sin escena |
| **Cámara cedida** | Tras `ceder_camara`, contextos `vista cercana` y `ordenador` | Quieto | Interpolada a la pose pedida y mantenida; el cuerpo no se mueve | En modo cursor/gesto (`apuntar`) o reposo | Libre o Congelado (tras `devolver_camara` y su interpolación) · Sin escena |

Reglas de transición:
- **Libre → Congelado / Cámara cedida:** la entrada de movimiento pasa a cero y el cuerpo frena (regla 22); el balanceo se desvanece por la propia velocidad (F3). La cámara no salta.
- **Congelado → Libre:** ocurre cuando Entrada anuncia `exploración`; el Jugador empieza a leer `mover` y `mirar` ese mismo tick. Una cesión en curso debe haber terminado su devolución: mientras dura (`t_devolver`), el Jugador sigue en Cámara cedida y descarta `mover` y `mirar`.
- **Pausa:** el tiempo de juego se detiene; las interpolaciones y el balanceo se congelan y continúan al reanudar. Un gesto de manos bloqueante se detiene y retoma.
- **Descarga de escena:** pasa a Sin escena; se descartan cesiones y gestos sin avisos. El estado no sobrevive a la carga siguiente (regla 32).

### Interactions with Other Systems

| Sistema | Qué recibe del Jugador | Qué entrega al Jugador |
|---|---|---|
| 1 Entrada y controles | Nada (solo lee el contexto activo y las acciones) | `mover` (Vector2), `mirar` (Δyaw, Δpitch), aviso de contexto cambiado |
| 4 Escena de planta | Sensor de zona y cápsula para los volúmenes `T-…`; fin de `colocar` | `colocar(…)`, anclas `spawn_office` / `spawn_elevator`, etiquetas de superficie del suelo, geometría con colisión |
| 7 Interacción e inspección | Rayo de visión (origen y dirección); fin de gestos de manos | `ceder_camara`, `devolver_camara`, `reproducir_gesto`, `sostener`, `soltar`, `apuntar`, `reposo` |
| 8 Control de acceso | — | Colisión de puertas (contrato en Dependencies) |
| 19 Ordenador · 22 Llamada | Fin de gestos (teclear, descolgar) | Gestos de manos (`HAND_TYPE`, `HAND_PHONE_*`); cesión de cámara el ordenador |
| 20 Documentos y bolsillo visual | — | `sostener(item_id)` / `soltar()` al usar y guardar un ítem |
| 23 Director de audio | Señal `paso(superficie, intensidad)`; posición y orientación del oyente | — |
| 28 Atmósfera reactiva | `pose_con_retardo(τ)`, `giro_acumulado()`, `pose` actual | — |
| 6 Ajustes persistentes | Lee `balanceo_camara` y `campo_vision` y su aviso de cambio | — |
| 3 Estado y bus de eventos | Nada: el Jugador no emite ni lee hechos ni avisos del bus | — |
| 21 Director de escenas | — | Peticiones de `sin control` vía Entrada (el Jugador se congela con el contexto) |

## Formulas

### F1 · Velocidad objetivo en el marco del cuerpo

`v_obj = v_paseo × ( m'.x × k_lat , m'.y × (m'.y ≥ 0 ? 1 : k_atras) )`, con `m' = m / max(1, |m|)`

**Variables:**
| Variable | Tipo | Rango | Origen | Descripción |
|---|---|---|---|---|
| m | Vector2 | longitud ≈ 0–1 (se normaliza si > 1) | Entrada (`mover`) | X lateral (+ derecha), Y avance (+ delante); en estado distinto de Libre, (0, 0) |
| v_paseo | float (m/s) | 1,0–2,2 | datos, 1,6† | Velocidad máxima de paseo |
| k_lat | float | 0,7–1,0 | datos, 1,0† | Factor de paso lateral |
| k_atras | float | 0,5–1,0 | datos, 0,8† | Factor de marcha atrás |
| v_obj | Vector2 (m/s) | |v_obj| ≤ v_paseo | calculada | Velocidad objetivo en el marco del cuerpo |

**Rango de salida:** módulo de 0 a `v_paseo` (1,6 m/s); marcha atrás máxima 1,28 m/s.
**Ejemplos:** `m = (0, 1)` → `(0; 1,6)`. `m = (0, −1)` → `(0; −1,28)`. `m = (0,7071; 0,7071)` (W+D) → `(1,131; 1,131)`, módulo 1,6. `m = (1, 1)` → se normaliza a `(0,7071; 0,7071)`, módulo 1,6 (en diagonal no se corre más). Stick con `|m| = 0,5` hacia delante → `(0; 0,8)`.

### F2 · Aceleración y frenado

`v ← move_toward(v, v_obj, a × dt)`, con `a = v_paseo / t_acel` si `|v_obj| ≥ |v|`, o `a = v_paseo / t_freno` en otro caso. La posición se integra con el paso semi-implícito (primero la velocidad, después la posición). `v` se gira a coordenadas del mundo con el yaw actual **después** de acelerar (regla 8).

**Variables:** `dt` = 1/`f_fisica` (1/60 s); `t_acel` 0,05–0,5 s (0,20†); `t_freno` 0,05–0,4 s (0,15†).
**Rango de salida:** `a_acel` = 8,0 m/s² y `a_freno` = 10,67 m/s² con los valores por defecto.
**Ejemplo:** desde reposo con `m = (0, 1)`: tras 12 pasos (0,20 s) `v = 1,6 m/s`, distancia recorrida **0,173 m** (con paso semi-implícito). Desde 1,6 m/s soltando: `v = 0` a los 9 pasos (0,15 s), distancia **0,107 m**. Recorrer 24 m del pasillo en línea recta tarda ≈ **15,1 s**.

### F3 · Balanceo, manos y pasos (ligados a la distancia)

`d ← d + |Δpos_horizontal|` (distancia realmente recorrida, tras colisiones)
`φ = 2π × d / L_paso`;  `r = clamp(|v| / v_paseo, 0, 1)`
`cámara.y = A_v × g × r × cos(φ)`  ·  `cámara.x = A_h × g × r × sin(φ / 2)`
`manos.y_extra = A_manos × g × r × cos(φ − φ_ret)`
Evento de paso en cada `d = (n + ½) × L_paso`, n = 0, 1, 2…

**Variables:**
| Variable | Tipo | Rango | Origen | Descripción |
|---|---|---|---|---|
| L_paso | float (m) | 0,6–0,9 | datos, 0,75† | Distancia entre dos apoyos de pies |
| A_v / A_h | float (m) | 0–0,03 / 0–0,02 | datos, 0,015† / 0,010† | Amplitud del balanceo vertical y lateral de la cámara a g = 1 |
| A_manos | float (m) | 0–0,02 | datos, 0,008† | Balanceo vertical propio de las manos |
| φ_ret | float (rad) | 0–1,5 | datos, 0,8† | Retardo de fase de las manos |
| g | float | {1; 0,5; 0} | datos según `balanceo_camara` | `completo` = `g_completo` (1,0), `reducido` = `g_reducido` (0,5†), `ninguno` = 0. Entre niveles, g se mueve linealmente en `t_cambio_balanceo` (0,25 s†) |
| r | float | 0–1 | calculada | Se desvanece al parar: el balanceo no «salta» al detenerse |

**Rasgos:** el punto más bajo de la cámara (`cos φ = −1`) coincide con el apoyo del pie (φ = π, es decir, `d = L_paso/2`), y el lateral tiene periodo de dos pasos. **Solo traslación; roll = 0.** Con `g = 0` el offset es exactamente (0, 0) y las manos no se mueven.
**Ejemplo (`completo`, r = 1):** en el apoyo, `y = −0,015 m` y `x = +0,010 m`; con `reducido`, `y = −0,0075 m`. Caminando 3,0 m en línea recta a `v_paseo` hay 4 pasos (a 0,375; 1,125; 1,875 y 2,625 m). A `v_paseo` la cadencia es 1,6 / 0,75 = 2,13 pasos por segundo. Empujando contra un muro, `d` no avanza: sin balanceo ni pasos.

### F4 · Orientación y límite del pitch

`yaw ← wrap(yaw + Δyaw, −180°, 180°)`;  `pitch ← clamp(pitch + Δpitch, −pitch_max, +pitch_max)`;  `roll = 0`

**Variables:** `Δyaw`, `Δpitch` en grados (Entrada F2/F3, ya con la inversión vertical aplicada; + arriba para pitch); `pitch_max` 60–89° (80°†).
**Ejemplos:** `pitch = 78°`, `Δpitch = +5°` → 80°. `yaw = 179°`, `Δyaw = +5°` → −176°. Una orientación de colocación fuera de rango (pitch 95°) se limita a 80°.
**Nota:** al aplicarse sin `dt`, el mismo giro físico da el mismo resultado a cualquier fps.

### F5 · Campo de visión efectivo

`h = 2 × atan( tan(fov_v / 2) × aspecto )`;  si `h > fov_h_max`: `fov_v_efectivo = 2 × atan( tan(fov_h_max / 2) / aspecto )`, si no `fov_v_efectivo = fov_v`

**Variables:** `fov_v` = `campo_vision` (60–90°, 70° por defecto); `aspecto` = ancho / alto de la ventana; `fov_h_max` 100–140° (120°†).
**Ejemplos (fov_v = 70°):** 16:9 (1,778) → h = 102,4°, sin cambio. 16:10 → 96,4°. 4:3 → 86,0°. 21:9 (2,333) → 117,0°, sin cambio. 32:9 (3,556) → h = 136,2° > 120° → `fov_v_efectivo` = 51,9°. Con `fov_v = 90°` en 16:9 → h = 121,2° → `fov_v_efectivo` ≈ 88,5°.
**Nota:** el slice y A.0 dan «70°» sin decir el eje; este GDD lo fija como vertical (decisión D-06).

### F6 · Memoria de poses y pose con retardo

`N = ceil(T_hist × f_fisica) + 1` muestras; la muestra 0 es la más reciente. `s = τ × f_fisica`; `i = floor(s)`; `α = s − i`; `pose(τ) = lerp(muestra[i], muestra[i+1], α)` (posición con `lerp`, yaw por el arco más corto, pitch con `lerp`; velocidad y fase del paso con `lerp`).

**Variables:** `T_hist` 0,6–2,0 s (1,0†; ≥ 0,6 s para el retardo del slice); `f_fisica` 60 Hz†; `τ` ∈ [0, T_hist], se limita a ese rango (sin error); si hay menos historia que τ (justo tras `colocar`), la memoria está rellena con la pose inicial.
**Ejemplos:** N = 61. τ = 0,6 → s = 36, α = 0 → exactamente la muestra de hace 36 pasos. Tras 2 s caminando a 1,6 m/s hacia el este, `pose(0,6)` queda a **0,96 m** al oeste de la pose actual. τ = 0,0125 → s = 0,75, entre las muestras 0 y 1 con α = 0,75.

### F7 · Inercia de las manos al girar y respiración

`ω_f ← lerp(ω_f, ω_yaw, 1 − exp(−dt / τ_in))`;  `manos.x_giro = clamp( −k_in × ω_f × g , −X_in_max , +X_in_max )`
`manos.y_resp = A_resp × g × sin(2π × f_resp × t_juego)`

**Variables:** `ω_yaw` en °/s (yaw aplicado en el fotograma / dt, `dt` limitado a 0,1 s); `k_in` 0–0,0005 m por °/s (0,0002†); `τ_in` 0,05–0,3 s (0,12†); `X_in_max` 0–0,05 m (0,03†); `A_resp` 0–0,006 m (0,003†); `f_resp` 0,15–0,4 Hz (0,25†); `t_juego` = tiempo de juego (se detiene en pausa).
**Ejemplos (g = 1):** giro sostenido a 60 °/s → desplazamiento −0,0120 m; a 120 °/s (máximo del stick por defecto) → −0,024 m; a 200 °/s (ratón) → −0,030 m (tope). Con `reducido` (g = 0,5) todo se reduce a la mitad.

### F8 · Giro acumulado

`giro_acumulado = Σ |Δyaw_tick|` sobre los últimos `T_giro` (0,5†; rango 0,2–1,0 s), con `Δyaw_tick` = diferencia de yaw entre dos pasos de física consecutivos (por el arco más corto).
**Ejemplo:** giro sostenido a 60 °/s durante 0,5 s → 30°. En reposo, 0°. Se pone a 0 en `colocar`.

### Valores por defecto y rangos seguros

Ver Tuning Knobs.

## Edge Cases

**Movimiento y colisión**
- **If el jugador empuja contra un muro en diagonal**: desliza a lo largo del muro con la componente tangente; si empuja de frente, queda parado sin vibrar, `d` no avanza (sin balanceo ni pasos).
- **If el jugador entra en una esquina o en un hueco de menos de 0,50 m**: no entra; la cápsula se detiene en la boca. Un hueco que debería ser transitable pero mide menos de 0,60 m es un defecto de contenido.
- **If `mover` llega con longitud > 1** (dos entradas sumadas): se normaliza a 1 (F1); nunca supera `v_paseo`.
- **If `mover` es NaN o infinito**: se trata como (0, 0) y se registra una línea; en desarrollo, error visible.
- **If se suelta `mover` a media zancada**: la velocidad cae a cero en 9 pasos; `r` baja con ella y el balanceo se apaga sin saltos; la fase `d` se conserva y el siguiente paso continúa desde donde estaba.
- **If se cambia de dirección brusca (W a S)**: la velocidad pasa por cero en el marco del cuerpo con `t_freno` y `t_acel` (sin deslizamiento lateral).
- **If una puerta se abre sobre el jugador**: la hoja de la puerta no tiene colisión con el jugador desde el inicio de la apertura (contrato con 8, Dependencies); si aun así se produce penetración, la regla de atasco la resuelve.
- **If el jugador queda atrapado** (el motor reporta penetración sin resolver durante `t_atasco`, 0,5 s†, o cae bajo `y_min`): se reubica en la **última pose segura** (anotada cada `t_pose_segura`, 0,25 s†, solo cuando no hay penetración y hay suelo), con velocidad cero, y se registra; en desarrollo, error visible. Si no existe pose segura, se usa el ancla de aparición.
- **If el jugador aparece solapando geometría** (ancla mal colocada): la colocación se acepta y el motor resuelve la penetración; es un defecto de contenido y se registra.
- **If hay un tirón de fotogramas** (una ventana minimizada, un guardado): la física avanza en pasos fijos (el motor limita los pasos por fotograma) y la mirada no usa `dt`, así que ni se teletransporta ni gira de más; los suavizados de las manos usan `dt` limitado a 0,1 s.
- **If el jugador camina durante el fundido de 2,0 s de la escena 1**: no puede; el contexto sigue en `sin control` hasta que 4 pida `exploración` (Escena de planta, regla 9).
- **If hay superficies sin etiqueta**: el paso usa la superficie `default` y no es un error.

**Cámara**
- **If el pitch recibe un giro mayor que el límite en un solo fotograma** (pico de ratón): se limita a ±80°; el yaw lo da Entrada, acotado a ±45° por fotograma.
- **If llega una orientación NaN o infinita**: se ignora ese fotograma y se registra; la orientación anterior se conserva.
- **If `campo_vision` es inválido o falta**: Ajustes entrega siempre un valor válido (su regla 4); este sistema no lo reinterpreta.
- **If la ventana cambia de relación de aspecto** (modo ventana): F5 se recalcula en el siguiente fotograma; el campo de las manos no cambia.
- **If se pide `ceder_camara` con una duración superior a 3 s**: se limita a 3 s y se registra. Con duración 0, la cámara salta a la pose pedida en ese fotograma.
- **If se pide `ceder_camara` estando ya cedida por otro propietario**: se rechaza y se registra (regla 18). Si el mismo propietario la pide de nuevo, la cámara interpola desde donde esté a la nueva pose; el yaw y pitch guardados no cambian.
- **If se pide `devolver_camara` sin cesión, o desde un propietario distinto**: se rechaza y se registra; no se mueve nada.
- **If la escena se descarga durante una cesión**: se descarta la cesión; el siguiente `colocar` fija una orientación nueva.
- **If se pausa durante una interpolación de cámara**: se congela con el tiempo de juego; al reanudar continúa.
- **If el jugador mira el reflejo del patio de luces**: la cámara no reacciona; la imagen de la silueta es responsabilidad de 28. El Jugador solo ofrece la pose y el giro acumulado.

**Manos**
- **If se pide un gesto bloqueante con otro en curso**: se rechaza y se registra (regla 24); Interacción serializa.
- **If un gesto no termina en 3 s** (animación sin fin o evento perdido): el Jugador emite el aviso de fin y libera las manos al reposo, y registra el fallo (tope coherente con Entrada F8).
- **If se pide `sostener` con un ítem desconocido**: se rechaza y se registra; las manos siguen como estaban. En desarrollo, error visible.
- **If se pide `sostener` con un objeto ya en la mano**: se rechaza (primero `soltar`).
- **If se pausa durante un gesto**: se congela y continúa al reanudar; no se salta ni se repite.
- **If el jugador gira muy rápido con las manos en reposo**: la inercia (F7) se limita a ±0,03 m; las manos nunca salen del encuadre.
- **If el apagón deja la escena a oscuras**: las manos conservan su luz mínima (regla 28); nunca desaparecen.

**Servicios**
- **If `pose_con_retardo` se llama con τ negativo o mayor que `T_hist`**: se limita a [0, `T_hist`] sin error.
- **If alguien intenta escribir la memoria de poses**: no hay operación pública para ello (solo lectura).
- **If la frecuencia de física del proyecto cambia**: `N` se recalcula con `f_fisica` (F6); una discrepancia entre el valor del dato y el del motor es un error de arranque (el juego no entra en partida, como los sistemas 3, 4 y 6).
- **If se emite `paso` sin superficie**: se usa `default`.
- **If el jugador se detiene durante la intensidad mínima** (v ≈ 0): no hay pasos: los pasos nacen de `d`, no del tiempo.

**Datos**
- **If un valor de `player.json` está fuera de su rango seguro, falta o el fichero no existe**: los datos son inválidos y el juego no entra en partida, con un mensaje de error claro (mismo criterio que los sistemas 3, 4, 6 y 18). Aplica, entre otros, a: `radio_capsula` ≥ 0,35 (no cabe por las puertas con margen), `altura_capsula` < 1,70 (los ojos a 1,62 m no caben con `near`), `pitch_max` ≥ 90 y `T_hist` < 0,6.

**Degeneradas (Sirlin)**
- No existe una estrategia dominante: no hay sprint ni atajos de movimiento. No hay forma de atravesar muros ni de saltarse puertas; las puertas bloquean mientras su sistema (8) lo decida. Si el jugador fuerza la cápsula contra una puerta cerrada, solo la desliza.

## Dependencies

**Aguas arriba (de qué depende):**
- **1 Entrada y controles — dura.** Entrega `mover`, `mirar` y los avisos de contexto. Sin Entrada el Jugador no se mueve.
- **4 Escena de planta y carga de Recepción — dura.** Aporta suelo, colisión, anclas de aparición, etiquetas de superficie y los volúmenes de zona; invoca `colocar`. Sin escena no hay mundo.
- **6 Ajustes persistentes — blanda.** Lee `balanceo_camara` y `campo_vision`. Sin Ajustes usa los valores iniciales del catálogo (regla 4 de ese GDD).
- **Motor:** física de personaje con Jolt y cámara (plan técnico §1, §2.2); verificar contra `docs/engine-reference/godot` antes de implementar.

**Aguas abajo (quién depende de este sistema):**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 7 Interacción e inspección | Dura | Rayo de visión, cesión de cámara, gestos de manos |
| 28 Atmósfera reactiva | Dura | `pose_con_retardo`, `giro_acumulado` |
| 4 Escena de planta | Blanda | Cápsula, sensor de zona; `colocar` |
| 23 Director de audio | Blanda | Señal `paso`; oyente |
| 19 Ordenador · 22 Llamada · 20 Documentos | Blanda | Gestos de manos (`HAND_TYPE`, `HAND_PHONE_*`, `sostener`) |
| 21 Director de escenas | Indirecta | Congelado vía contexto `sin control` |
| 8 Control de acceso | Indirecta | Contrato de colisión de las puertas |

**Cambios propuestos a otros documentos (no se han editado; los resuelve su autor):**
- **Systems index, fila 2:** añadir 6 a «Depende de» (hoy 1, 4) y 28, 23 a la lista de dependientes; pasar el estado a Designed.
- **Ajustes persistentes (6), regla 1:** añadir al catálogo `balanceo_camara` (enum `completo`, `reducido`, `ninguno` · inicial `reducido`†) y `campo_vision` (float 60 a 90, paso de 5 en la interfaz · inicial 70†), con lectores «2 Jugador», y a la lista de «restablecer todos». Las pantallas de 25 y 30 deben ofrecerlos.
- **Entrada y controles (1), F8:** aclarar que la regla de «tecla mantenida durante una transición» se aplica a las acciones disparadoras, no al eje continuo `mover` (si el jugador mantiene W al volver el control, el Jugador camina). Y que su ajuste de sensibilidad se queda como está.
- **Escena de planta (4):** (a) las puertas desactivan la colisión de su hoja al empezar a abrirse; (b) los volúmenes `T-…` detectan el sensor de zona del Jugador (regla 4); (c) el suelo lleva etiqueta de superficie; (d) el interior de la cabina del ascensor (Open Questions de ese GDD) debe medir al menos 1,2 m × 1,2 m para que la cápsula quepa.
- **Atmósfera reactiva (28), cuando se diseñe:** consume la pose y el giro acumulado; fija el umbral de «gira la cabeza» sobre `giro_acumulado`.
- **Interacción (7), cuando se diseñe:** usa solo estas operaciones para cámara y manos; serializa gestos; ninguna interacción dura más de 3 s sin ceder el contexto.
- **Art bible, Open Questions:** confirmar el eje del FOV (D-06) y el campo de visión de las manos (regla 25).

**Bidireccionalidad.** Ninguno de los GDDs citados se ha editado en esta tarea; cada uno debe listar a Jugador como proveedor o consumidor según la tabla. Entrada y Escena de planta ya lo nombran (sus tablas de interacción con el sistema 2).

## Tuning Knobs

Todos viven en `assets/data/player/player.json`, salvo los dos ajustes del jugador, que viven en Ajustes (6). Categoría: **F** = feel, **C** = curva, **G** = gate (ritmo/diseño de espacios). Todos son †: a validar en playtest.

| Parámetro | Defecto | Rango seguro | Cat. | Razón |
|---|---|---|---|---|
| `v_paseo` | 1,6 m/s | 1,0–2,2 | G | 24 m de pasillo en ≈ 15 s; recorrido típico del slice (~150–200 m) ≈ 2 min. Más rápido pierde el peso; más lento cansa al volver sobre los pasos |
| `k_atras` | 0,8 | 0,5–1,0 | F | Marcha atrás más lenta y cuidadosa |
| `k_lat` | 1,0 | 0,7–1,0 | F | Paso lateral sin penalización para no «torcer» el paseo |
| `t_acel` / `t_freno` | 0,20 / 0,15 s | 0,05–0,5 / 0,05–0,4 | F | Peso sin deslizamiento; frenado en ≤ 0,11 m |
| `radio_capsula` | 0,25 m | 0,20–0,30 | G | Cabe por puertas de 1,00 m con holgura; ver Core Rules 3 |
| `altura_capsula` | 1,75 m | 1,70–1,85 | G | Los ojos (1,62 m) quedan dentro |
| `altura_ojos` | 1,62 m | **fija (slice A.0)** | G | No es un parámetro de ajuste; está aquí para referencia |
| `radio_sensor_zona` | 0,05 m | 0,02–0,15 | G | Precisión del cruce de las zonas `T-…` |
| `pitch_max` | 80° | 60–89 | F | Permite ver mesa y techo sin voltear la cámara |
| `campo_vision` (**ajuste**) | 70° vertical | 60–90 | F | Slice A.0; ajuste de confort |
| `fov_h_max` | 120° | 100–140 | F | Tope para pantallas ultra anchas |
| `near` (plano cercano) | 0,05 m | 0,03–0,10 | G | Con radio de cápsula 0,25 m la cámara no atraviesa muros |
| `fov_manos` | 60° | 40–75 | F | Manos con forma estable; ver regla 25 |
| `balanceo_camara` (**ajuste**) | `reducido` | `completo` / `reducido` / `ninguno` | F | Confort; ver D-05 |
| `g_completo` / `g_reducido` | 1,0 / 0,5 | 0,5–1,5 / 0,2–0,8 | F | Escala del balanceo por nivel |
| `t_cambio_balanceo` | 0,25 s | 0,1–1,0 | F | Cambiar el nivel andando no produce un salto |
| `L_paso` | 0,75 m | 0,6–0,9 | F | Cadencia de ≈ 2,1 pasos por segundo |
| `A_v` / `A_h` | 0,015 / 0,010 m | 0–0,03 / 0–0,02 | F | Balanceo sutil (4 cm de recorrido total a g = 1) |
| `A_manos` / `φ_ret` | 0,008 m / 0,8 rad | 0–0,02 / 0–1,5 | F | Manos con seguimiento retardado |
| `k_in` / `τ_in` / `X_in_max` | 0,0002 / 0,12 s / 0,03 m | 0–0,0005 / 0,05–0,3 / 0–0,05 | F | Inercia al girar |
| `A_resp` / `f_resp` | 0,003 m / 0,25 Hz | 0–0,006 / 0,15–0,4 | F | Respiración en reposo |
| `i_paso_min` | 0,4 | 0,2–0,8 | F | Intensidad del paso a velocidad mínima |
| `t_devolver` | 0,5 s | 0,2–1,5 | F | Regreso de cámara tras la vista cercana |
| `t_transicion_max` | 3,0 s | **= Entrada F8 (1–5)** | G | Un solo tope para todo el juego |
| `T_hist` | 1,0 s | 0,6–2,0 | G | Cubre el retardo de 0,6 s de la escena 4 con margen |
| `T_giro` | 0,5 s | 0,2–1,0 | F | Ventana de «gira la cabeza» |
| `f_fisica` | 60 Hz | **valor del proyecto** | G | Fija `N` (F6) |
| `t_atasco` / `t_pose_segura` / `y_min` | 0,5 s / 0,25 s / −2,0 m | 0,25–2 / 0,1–1 / −10…−1 | G | Red de seguridad contra atascos |
| `t_item_dentro` / `t_item_fuera` | 0,3 / 0,3 s | 0,15–0,6 | F | Un ítem aparece y vuelve al «bolsillo visual» |

## Visual/Audio Requirements

*(Sección opcional para la categoría Core; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

- **Manos (art bible §3.1, §5.1):** formas simples, mate, sin bisel ni objetos puestos, legibles por contraste de valor contra el mobiliario verde humo; un solo LOD. Siempre en pantalla. Reciben la luz del monitor y del teléfono. Con luz mínima garantizada (regla 28).
- **Catálogo de gestos del slice** (identificadores propuestos, en inglés; los `ANIM_*` ya existen en slice B.7):

| Gesto | Usa | Duración | Bloquea contexto |
|---|---|---|---|
| `HAND_IDLE` | Reposo en exploración | bucle | no |
| `HAND_REACH` | Alcance genérico (pulsar, tocar, `SFX_CLICK_SUBTLE`) | ≤ 0,5 s† | sí |
| `HAND_DRAWER` | Abrir cajón (V03, A05, D05) | ≤ 1,2 s† | sí |
| `HAND_CARD_SWIPE` | Pasar tarjeta por el lector (C06, C07, D06) | ≤ 1,0 s† | sí |
| `HAND_TURN` | Girar una lámpara (B01–B03) o un control | ≤ 0,8 s† | sí |
| `HAND_HOLD_ITEM` | Sostener y girar un objeto (V05, A03, tarjetas) | bucle | no |
| `HAND_READ` | Sostener un papel o documento | bucle | no |
| `ANIM_PAGE_TURN` | Pasar página (R01) | ≤ 1,0 s† | sí |
| `HAND_TYPE` | Teclear (V01) | bucle | no |
| `ANIM_PHONE_PICKUP` | Descolgar (V02) | **0,8 s** (slice B.7) | sí |
| `HAND_PHONE_HOLD` | Teléfono en la mano durante la llamada, pantalla hacia Vera | bucle | no |
| `HAND_PHONE_PUTDOWN` | Colgar tras `SFX_PHONE_END` | ≤ 0,6 s† | sí |
| `HAND_POINT` | La mano sigue un punto 3D en vista cercana (`apuntar`) | bucle | no |

- **Sin cuerpo visible:** al mirar hacia abajo no hay torso ni piernas (art bible §5, §3.1: Vera existe en manos y reflejo). El technical-artist define el proxy de cuerpo entero del reflejo (28) y el campo visual de las manos.
- **Pasos (audio, 23):** señal `paso(superficie, intensidad)` a ≈ 2 Hz a `v_paseo`; superficie `default` en el slice. El silencio entre pasos es parte del tono (slice §4); el audio director decide la mezcla. No hay sonido de respiración ni de ropa propios en este GDD.
- **Oyente:** en la cámara (con su orientación), sin balanceo.
- **Fotosensibilidad:** el balanceo es de baja frecuencia (≈ 2 Hz) y baja amplitud, y no hay destellos asociados al Jugador.

## Game Feel

- **Latencia de mirada:** la orientación se aplica en el mismo fotograma que llega la entrada, sin suavizado (regla 15). Sin presupuesto numérico de latencia: el slice no define equipo de referencia (slice §21).
- **Movimiento:** lento y pesado a propósito, con ≈ 0,15 s para arrancar y parar, pero sin deslizamiento: la cápsula siempre se detiene donde el jugador espera. Girar mientras se camina redirige el movimiento al instante (regla 8).
- **Peso:** a 2,13 pasos por segundo y con el balanceo en `reducido` (7,5 mm de caída en el apoyo), la sensación debe ser «camino, no flotó ni me balanceo»; a `completo`, el paso se nota sin llegar a ser incómodo (a validar).
- **Manos:** el jugador debe reconocer que la mano que sale es la suya (el gesto empieza cuando él lo pide). Las manos respiran en reposo; no parecen estatuas.
- **Comodidad:** sin roll, sin sacudidas, sin cambios bruscos de FOV, sin mirada forzada. Campo de visión y balanceo ajustables (pilar *Tensión sin castigo*).
- **Referencia de comparación:** los valores † se afinan en el primer playtest comparando con otros juegos de caminar en primera persona; los juegos de referencia siguen pendientes de elegir por el autor (Entrada, Game Feel).

## UI Requirements

El Jugador no tiene pantalla. Requisitos a las pantallas de 25 (menú de pausa) y 30 (accesibilidad):
- **Campo de visión:** deslizador de 60° a 90° en pasos de 5° con el valor visible y «restablecer» (70°); el cambio se ve en el acto tras el menú (el mundo está pausado).
- **Balanceo de cámara:** selector de tres valores (`completo`, `reducido`, `ninguno`) con su valor actual visible, operable con ratón y mando (`ui_izquierda` y `ui_derecha`).
- Ambos se ofrecen junto a «reducir sobresaltos» y no dentro de un submenú de más de un nivel.
- Los rótulos son entradas `UI_…` de la base de contenido (18). **Sin retícula**: el icono de interacción lo pone 24.

📌 **UX Flag — Jugador en primera persona**: las dos opciones de confort deben incluirse en `/ux-design` para las opciones de accesibilidad antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §4, §5, §16 | Pilares, primera persona a la altura de los ojos, manos visibles, sin sprint, sin barras ni game over | Alcance de este sistema |
| `design/slice/slice-v0.3.md` · A.0 y A.1 | Ojos a 1,62 m, FOV 70°, sin agacharse; puertas de 1,00 × 2,10 m, pasillo 2,6 m | Constantes (F5, reglas 3 y 12) |
| `design/slice/slice-v0.3.md` · A.3, C.4 y escena 4 | Zonas `T-PAS-1/2`, reflejo retardado 0,6 s durante 3 s, vuelve a la normalidad al girar la cabeza | Origen del sensor de zona, F6 y F8 |
| `design/slice/slice-v0.3.md` · B.7, C.7 y D.1 | `ANIM_PHONE_PICKUP` 0,8 s, `ANIM_PAGE_TURN`, bolsillo visual | Catálogo de gestos de manos |
| `design/slice/slice-v0.3.md` · D.3 | El guardado no almacena la posición | Regla 32 |
| `design/gdd/entrada-y-controles.md` · reglas 1, 5–9, 22; F2, F3, F8 | Acciones `mover` y `mirar`, contextos, límites de ángulo, tope de transición | Entradas del Jugador |
| `design/gdd/escena-de-planta.md` · reglas 9, 10 | `colocar`, `spawn_office` (−3,0; 0,0), Recepción | Colocación y suelo |
| `design/gdd/ajustes-persistentes.md` · reglas 1, 4, 7 | Catálogo y aviso de cambio | Dónde viven `balanceo_camara` y `campo_vision` |
| `design/gdd/estado-y-bus-de-eventos.md` · regla 14 | Ajustes fuera del estado | El Jugador no usa el bus |
| `design/art/art-bible.md` · §3.1, §5.1, §5.2 y Open Questions (FOV, manos) | Manos, reflejo, silueta | Visual/Audio |
| `docs/PLAN-TECNICO.md` · §2.2 y §3 | `CharacterBody3D`, ojos 1,62 m, reflejo con el buffer de posición | Dirección técnica |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Autonomía como progresión*, *El espacio expresa la emoción* | Pilares que este sistema sirve |

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D-01 | Una sola velocidad de paseo, analógica con el stick (1,6 m/s†) | Varias marchas; sprint «de aviso» | Slice §5: sin sprint. La velocidad analógica da control fino al mando sin una acción nueva |
| D-02 | Velocidad calculada en el marco del cuerpo | Aceleración en coordenadas del mundo | Evita el arrastre lateral al girar, fuente típica de incomodidad y de «control de hielo» |
| D-03 | Frenado corto (0,15 s) sin inercia larga | Parada instantánea o deslizamiento largo | Peso sin pérdida de control; el pilar 4 pide que el cuerpo nunca se rebele |
| D-04 | Cámara sin roll, sin sacudidas y sin mirada dirigida por eventos | Un tirón de cámara en los sustos; «mirar al reflejo» automático | Pilares *Tensión sin castigo* y *Autonomía*: el susto es luz y sonido; el jugador decide qué mirar |
| D-05 | Balanceo solo en traslación, tres niveles, inicial `reducido` | Balanceo completo por defecto; balanceo con roll; sin opción | El balanceo es una de las causas más frecuentes de mareo; se ofrece pero tenue por defecto. A validar en playtest |
| D-06 | 70° se interpreta como **vertical** (≈ 102° horizontal en 16:9), con deslizador de 60 a 90° y tope horizontal de 120° | 70° horizontal (≈ 43° vertical, «túnel» en salas de 2,70 m); FOV fijo sin opción | Es el valor por defecto de `Camera3D` y se ve el mobiliario de salas pequeñas; el deslizador y el tope sirven al confort y a pantallas ultra anchas. Pendiente de confirmar por art (art bible) |
| D-07 | Manos dibujadas sobre el mundo con su propio campo de visión | Manos en el mundo con colisión; mismo FOV que el mundo | Sin atravesar muros con el radio de 0,25 m; forma estable con cualquier `campo_vision` |
| D-08 | Sin cuerpo visible | Torso y piernas | Art bible §5: Vera existe en manos y reflejo |
| D-09 | El Jugador posee la memoria de poses (1,0 s) | Que 28 grabe su propio historial | Un solo escritor; sincronizada con el paso de física |
| D-10 | El Jugador **presta** la cámara con un contrato de petición y devolución, un propietario a la vez | Que cada puzle mueva la cámara | Un solo sitio acota el tiempo (3 s) y garantiza la devolución |
| D-11 | Sensor de zona puntual, además de la cápsula | Usar la cápsula como detector | Las zonas `T-…` del slice están medidas al centro del jugador (A.3) |
| D-12 | Cápsula de 0,25 m de radio | 0,20 m (más holgura) o 0,30 m | Compromiso entre cruzar la puerta de 1,00 m sin roces y no atravesar objetos con el borde de la cámara |
| D-13 | Pitch ±80° | ±89° o ±70° | Ver la mesa y el techo sin voltear |
| D-14 | Al salir de `exploración` el cuerpo frena con `t_freno` | Anular la velocidad al instante | Evita un salto de cámara por el balanceo; coherente con soltar la tecla |
| D-15 | Pasos y balanceo por distancia recorrida | Por tiempo o por la entrada | Contra un muro no hay pasos; el ritmo sigue a la velocidad real |
| D-16 | El rayo de visión parte de los ojos sin balanceo | Desde la cámara con balanceo | Que el objetivo de interacción no parpadee al andar |
| D-17 | Sin empuje de objetos | Física de objetos | Plan técnico §1: los objetos se mueven por código; nada pesa en el jugador |
| D-18 | Pasos por señal directa a Audio | Aviso del bus de eventos | Alta frecuencia, sin utilidad de guardado ni reproducción |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/player/`), bloqueante; **I** = integración o playtest documentado, bloqueante; **V** = captura retenida en `production/qa/evidence/` más visto bueno del lead, bloqueante. Los tests L usan un reloj inyectado (pasos de física enteros), entrada falsa y colisión falsa. Tolerancia numérica ±0,002 salvo indicación. Los valores † pueden cambiar tras el playtest; los criterios se actualizan con ellos. El GDD no define presupuesto de rendimiento y no se inventa uno (equipo de referencia sin definir, slice §21).

**Movimiento (reglas 1–11)**
- **AC-01 (R7, F1, L)**: **GIVEN** `v_paseo` = 1,6 y `k_atras` = 0,8, **WHEN** `m` vale (0, 1), (0, −1), (0,7071; 0,7071), (1, 1) y (0, 0,5), **THEN** `v_obj` es (0; 1,6), (0; −1,28), (1,131; 1,131), (1,131; 1,131) y (0; 0,8).
- **AC-02 (R9, F2, L)**: **GIVEN** reposo, **WHEN** `m` = (0, 1) durante 12 pasos de 1/60 s, **THEN** `v` = 1,6 m/s y la distancia recorrida es 0,173 m; **WHEN** después `m` = (0, 0), **THEN** `v` = 0 a los 9 pasos y la distancia adicional es 0,107 m.
- **AC-03 (R8, F2, L)**: **GIVEN** velocidad 1,6 m/s hacia delante con yaw 0°, **WHEN** el yaw pasa a 90° en un tick con `m` = (0, 1), **THEN** la velocidad en el mundo gira 90° sin pérdida de módulo (1,6 m/s) en el mismo tick.
- **AC-04 (R6-7, L)**: **GIVEN** estado Libre, **THEN** no existe ninguna acción de sprint, salto o agacharse en el Jugador; **GIVEN** `m` = NaN, **THEN** se trata como (0, 0) y se añade una línea al log.
- **AC-05 (R10, L)**: **GIVEN** un muro a 45° y `m` = (0, 1), **WHEN** el jugador avanza contra él, **THEN** su velocidad queda paralela al muro (componente normal 0) y no hay rebote; **GIVEN** un muro de frente, **THEN** la velocidad llega a 0 y la posición no oscila (variación < 1 mm durante 60 pasos).
- **AC-06 (R10-11, I)**: **GIVEN** el pasillo (X 0 a 24, A.1) y teclado, **WHEN** el jugador avanza en línea recta con `W` sostenido, **THEN** tarda 15,1 ± 0,3 s, y el tiempo es el mismo con la ventana a 30, 60 y 144 fps.
- **AC-07 (R1, R3, I)**: **GIVEN** la planta construida, **WHEN** el jugador cruza cada puerta de 1,00 m (A, B, D, umbral de Vera) y recorre el pasillo a su ancho completo, **THEN** nunca queda atascado ni roza el marco; **GIVEN** cualquier hueco de mobiliario < 0,50 m, **THEN** no se puede entrar.
- **AC-08 (R1, L)**: **GIVEN** un objeto estático, **WHEN** el jugador empuja contra él, **THEN** el objeto no se mueve.
- **AC-09 (R4, I)**: **GIVEN** `T-PAS-1` (X de 9,0 a 10,0), **WHEN** el jugador camina hacia el este, **THEN** la zona se activa con su centro en X = 9,0 ± 0,05, no con el borde de la cápsula.

**Cámara (reglas 12–20)**
- **AC-10 (R12, L)**: **GIVEN** cualquier estado y el balanceo en `ninguno`, **THEN** la altura de los ojos sobre el suelo es 1,62 m y el desplazamiento de la cámara respecto a los ojos es exactamente (0, 0, 0).
- **AC-11 (R13, F4, L)**: **GIVEN** pitch 78°, **WHEN** llega Δpitch = +5°, **THEN** pitch = 80°; **GIVEN** yaw 179°, **WHEN** llega Δyaw = +5°, **THEN** yaw = −176°.
- **AC-12 (R13, L)**: **GIVEN** un mismo Δyaw total de 90° entregado en 3 fotogramas o en 12, con tiempos de fotograma distintos, **THEN** el yaw final es idéntico (±0,001°).
- **AC-13 (R14, L)**: **GIVEN** una secuencia cualquiera de entradas y de avisos del juego (zona activada, puerta abierta, apagón, llamada, reflejo), **THEN** el roll de la cámara es 0 exacto y, en estado Libre, la orientación solo cambia por Δ de Entrada.
- **AC-14 (R14, L)**: **GIVEN** `reducir_sobresaltos` en verdadero o falso, **THEN** ninguna salida del Jugador (orientación, offset, FOV, manos) cambia.
- **AC-15 (R16, F3, L)**: **GIVEN** `completo`, r = 1, **WHEN** d = 0,375 m, **THEN** `cámara.y` = −0,015 y `cámara.x` = +0,010; con `reducido`, `cámara.y` = −0,0075; con `ninguno`, ambos 0 en todo d.
- **AC-16 (R16, F3, L)**: **GIVEN** `completo` y el jugador empujando contra un muro, **THEN** `d` no avanza y el offset es (0, 0); **WHEN** se suelta `mover` a media zancada, **THEN** el offset tiende a 0 en ≤ 9 pasos sin discontinuidades > 2 mm por tick.
- **AC-17 (R16, L)**: **GIVEN** `reducido`, **WHEN** el ajuste cambia a `completo` mientras se camina, **THEN** `g` pasa de 0,5 a 1,0 en 0,25 s ± 1 tick, sin salto de offset > 2 mm.
- **AC-18 (R17, F5, L)**: **GIVEN** `fov_v` = 70°, **THEN** el campo efectivo es 70° en 16:9, 16:10, 4:3 y 21:9, y 51,9° ± 0,1° en 32:9; **GIVEN** `fov_v` = 90° en 16:9, **THEN** 88,5° ± 0,1°.
- **AC-19 (R17, I)**: **WHEN** el jugador cambia `campo_vision` en el menú de pausa, **THEN** al reanudar el campo efectivo coincide con F5 en el mismo fotograma.
- **AC-20 (R18, L)**: **GIVEN** estado Libre, yaw/pitch (30°, −10°), **WHEN** Interacción pide `ceder_camara(P1, pose, 60°, 1,0 s)`, **THEN** al cabo de 1,0 s la cámara está en `pose` (±0,001 m, ±0,1°); **WHEN** pide `devolver_camara(P1)`, **THEN** a los 0,5 s la orientación es (30°, −10°) ± 0,1° y la posición la de los ojos.
- **AC-21 (R18, L)**: **WHEN** se pide `ceder_camara` con 5 s, **THEN** dura 3,0 s y hay una línea de log; **WHEN** un propietario P2 pide ceder o devolver mientras P1 la tiene, **THEN** se rechaza y la cámara no se mueve (en desarrollo, error visible).
- **AC-22 (R19, L)**: **GIVEN** balanceo `completo` en movimiento, **THEN** el origen del rayo de visión es siempre (X, 1,62, Z) del cuerpo, sin offset de balanceo.
- **AC-23 (R20, L)**: **GIVEN** un jugador en movimiento con cámara cedida, **WHEN** 4 llama a `colocar(p, yaw, pitch)`, **THEN** en ese mismo tick posición = p (±0,001), velocidad 0, orientación = (yaw, pitch limitado), sin cesión activa, manos en reposo sin objeto y `giro_acumulado` = 0.

**Estados (regla 22)**
- **AC-24 (R22, L)**: **GIVEN** Libre con velocidad 1,6 m/s, **WHEN** Entrada anuncia `inspección`, **THEN** el objetivo pasa a (0, 0), el cuerpo se detiene en 9 pasos tras 0,107 m y la orientación no cambia aunque `mirar` siga llegando.
- **AC-25 (R22, L)**: **GIVEN** Cámara cedida durante su devolución, **WHEN** llega `mover`, **THEN** se descarta hasta que la devolución termina.
- **AC-26 (R22, I)**: **GIVEN** Libre y `W` mantenida, **WHEN** Entrada devuelve `exploración` tras una inspección, **THEN** el jugador camina en ese mismo tick (propuesta a Entrada, Dependencies).
- **AC-27 (States, L)**: **GIVEN** pausa, **THEN** durante 600 pasos de reloj de pared ni la posición, ni la orientación, ni la fase `d`, ni una interpolación en curso, ni un gesto de manos avanzan; **WHEN** se reanuda, **THEN** continúan desde donde estaban.

**Manos (reglas 23–28)**
- **AC-28 (R24, L)**: **WHEN** se pide un gesto bloqueante con otro en curso, **THEN** se rechaza y se registra; **WHEN** un gesto no termina en 3 s, **THEN** se emite el fin y las manos vuelven a reposo con una línea de log.
- **AC-29 (R24, L)**: **WHEN** se pide `sostener` con un ítem desconocido o con otro objeto ya en la mano, **THEN** se rechaza y las manos no cambian.
- **AC-30 (R27, F7, L)**: **GIVEN** g = 1, **WHEN** ω_f es 60, 120 y 200 °/s, **THEN** `manos.x_giro` es −0,0120; −0,0240 y −0,0300 m; **GIVEN** `ninguno`, **THEN** es 0 y la respiración es 0 en todo instante.
- **AC-31 (R23, R25, V)**: **GIVEN** la planta en la escena 1, **WHEN** se captura el reposo con `campo_vision` en 60°, 70° y 90°, **THEN** el tamaño y la forma de las manos son idénticos en las tres capturas, y no hay objeto, reloj ni anillo en ellas.
- **AC-32 (R23, R24, V)**: **WHEN** se ejecuta cada gesto de la tabla de Visual/Audio —abrir cajón (V03), teclear (V01), girar lámpara (B01), descolgar (V02), pasar página (R01), girar el peluche (V05), encajar una pieza (puzle 3), pasar tarjeta (C06)—, **THEN** hay una captura retenida en la que se ven las manos haciendo el gesto, sin atravesar geometría.
- **AC-33 (R25, V)**: **GIVEN** el jugador pegado a un muro (cápsula tocando), **THEN** las manos no atraviesan el muro (captura retenida).
- **AC-34 (R28, V)**: **GIVEN** el apagón de la escena 7, **THEN** las manos son legibles con la luz de la pantalla del teléfono (captura retenida, art bible §2.5).

**Servicios (reglas 29–31)**
- **AC-35 (R29, F6, L)**: **GIVEN** `f_fisica` = 60 y `T_hist` = 1,0, **THEN** `N` = 61; **GIVEN** 2 s a 1,6 m/s hacia el este, **THEN** `pose_con_retardo(0,6)` queda 0,96 ± 0,02 m al oeste de la pose actual; **THEN** τ = −1 y τ = 5 se limitan a 0 y 1,0 sin error; **GIVEN** justo después de `colocar`, **THEN** `pose_con_retardo(0,6)` = pose inicial.
- **AC-36 (R29, L)**: **THEN** no existe ninguna operación pública que escriba en la memoria de poses.
- **AC-37 (R30, F8, L)**: **GIVEN** un giro de 60 °/s durante 0,5 s, **THEN** `giro_acumulado` = 30° ± 0,5°; en reposo = 0.
- **AC-38 (R31, F3, L)**: **GIVEN** 3,0 m caminados a `v_paseo` desde reposo, **THEN** se emiten 4 señales `paso` (en d = 0,375; 1,125; 1,875; 2,625 m), con intensidad ≥ `i_paso_min`; con `ninguno` también se emiten; contra un muro, ninguna.
- **AC-39 (R32, L)**: **THEN** el Jugador no tiene operación de escritura ni suscripción al estado (3) y no aparece en la instantánea del guardado.

**Red de seguridad (Edge Cases)**
- **AC-40 (L)**: **GIVEN** penetración sin resolver durante 0,5 s o `y` < −2,0 m, **THEN** el jugador vuelve a la última pose segura con velocidad 0 y hay una línea de log; sin pose segura, al ancla de aparición.

**Datos**
- **AC-41 (L)**: **GIVEN** una fixture con `v_paseo` = 2,0, **THEN** F1 usa 2,0 sin recompilar; **GIVEN** fixtures con `radio_capsula` = 0,40, `pitch_max` = 95, `T_hist` = 0,4 o sin fichero, **THEN** el juego no entra en partida, se invoca el manejador de error fatal inyectado con el nombre del parámetro y no se carga la escena.

**Experienciales (playtest)**
- **AC-42 (I)**: **GIVEN** 5 jugadores nuevos (plan técnico M5) y el balanceo en su valor inicial, **THEN** ninguno reporta mareo ni deslizamiento; la descripción del movimiento incluye «lento», «pesado» o similar sin «lento» como queja única (sistema de notas del playtest); al menos 4 de 5 mueven la cámara a voluntad sin pedirle ayuda al evaluador.
- **AC-43 (I)**: **GIVEN** la escena 4, **WHEN** el jugador gira la cabeza hacia el patio de luces, **THEN** el juego no mueve su cámara y el reflejo reacciona solo mediante `giro_acumulado` (criterio de 28, slice criterio 4).

## Open Questions

Ninguna contradice el slice ni cambia pilares o alcance; son verificaciones técnicas o ajustes de otros documentos.

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Interpretación del campo de visión (70° vertical)** y valor para las manos; confirmar con el art director (art bible, Open Questions) | art-director | GDD de 28 / primer prototipo |
| 2 | **Cómo se dibujan las manos sobre el mundo** (shader en `vertex()`, sub-viewport o segunda cámara); la nota del art bible indica que escribir `PROJECTION_MATRIX` en 4.7 no está verificado | technical-artist + ADR | Fase de arquitectura |
| 3 | **Presentación interpolada** a más de 60 fps (interpolación de física del motor o seguimiento en el fotograma) y compatibilidad con el sensor de zona; verificar contra `docs/engine-reference/godot` | ADR del Jugador | Fase de arquitectura |
| 4 | **`apuntar` en vista cercana:** si las manos usan cinemática inversa o animaciones mezcladas, y cómo siguen un cursor virtual; depende de los puzles 3 y 5 | GDD de 7 y de los puzles | GDD del sistema 7 |
| 5 | **Cabina del ascensor** (interior sin definir en el slice): mínimo 1,2 × 1,2 m para la cápsula | GDD de 4 / level-designer | Fase de arquitectura |
| 6 | **Etiqueta de superficie del suelo:** si el slice distingue moqueta, baldosa o suelo húmedo | audio-director | GDD del sistema 23 |
| 7 | **Valores † de confort:** `balanceo_camara` inicial `reducido`, `v_paseo` 1,6 m/s, `A_v`/`A_h`; a validar en el primer playtest | game-designer + playtest | Playtest M5 |
| 8 | **Cambios a otros GDDs** de la lista de Dependencies (Ajustes, Entrada F8, Escena de planta, índice) | autores de cada GDD | Antes del `/design-review` de este documento |

## Propuesta de registro

Entradas que se propondrían para `design/registry/entities.yaml` (no se ha editado; `source` es este GDD salvo indicación).

```yaml
entities:
  - name: vera_player_character
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/entrada-y-controles.md
      - design/gdd/escena-de-planta.md
      - design/art/art-bible.md
    eye_height_m: 1.62            # slice A.0 (fijo)
    capsule_radius_m: 0.25
    capsule_height_m: 1.75
    movement: walk_only           # sin sprint, salto ni agacharse
    visible_body: hands_only
    added: "2026-11-09"

constants:
  - name: player_eye_height_m
    status: active
    source: design/slice/slice-v0.3.md   # A.0; este GDD lo aplica
    referenced_by:
      - design/gdd/jugador-en-primera-persona.md
      - design/gdd/escena-de-planta.md
    value: 1.62
    added: "2026-11-09"
  - name: player_fov_vertical_default_deg
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/entrada-y-controles.md
      - design/art/art-bible.md
    value: 70
    range: [60, 90]
    note: "Eje vertical (decisión D-06); tope horizontal 120"
    added: "2026-11-09"
  - name: player_walk_speed_mps
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/entrada-y-controles.md
    value: 1.6
    range: [1.0, 2.2]
    added: "2026-11-09"
  - name: player_capsule_radius_m
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/escena-de-planta.md
    value: 0.25
    range: [0.20, 0.30]
    added: "2026-11-09"
  - name: player_min_passage_width_m
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/escena-de-planta.md
    value: 0.60
    added: "2026-11-09"
  - name: player_pitch_limit_deg
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/entrada-y-controles.md
    value: 80
    range: [60, 89]
    added: "2026-11-09"
  - name: player_step_length_m
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/jugador-en-primera-persona.md
    value: 0.75
    added: "2026-11-09"
  - name: player_pose_history_s
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/gdd/jugador-en-primera-persona.md
    value: 1.0
    range: [0.6, 2.0]
    note: "Debe cubrir el retardo del reflejo (0,6 s, slice C.4)"
    added: "2026-11-09"
  - name: player_camera_transition_cap_s
    status: active
    source: design/gdd/entrada-y-controles.md   # F8
    referenced_by:
      - design/gdd/jugador-en-primera-persona.md
    value: 3.0
    added: "2026-11-09"

formulas:
  - name: player_ground_velocity
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by: []
    expression: "v_obj = v_paseo * (m'.x*k_lat, m'.y*(m'.y>=0 ? 1 : k_atras)); m' = m / max(1,|m|)"
    output_range: "0 to 1.6 m/s (back 1.28 m/s)"
    added: "2026-11-09"
  - name: player_effective_fov
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by:
      - design/art/art-bible.md
    expression: "h = 2*atan(tan(fov_v/2)*aspect); if h > 120deg then fov_v = 2*atan(tan(60deg)/aspect)"
    output_range: "fov_v_eff 51.9 to 90 deg"
    added: "2026-11-09"
  - name: player_camera_bob_offset
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by: []
    expression: "y = A_v*g*r*cos(2*pi*d/L_paso); x = A_h*g*r*sin(pi*d/L_paso); translation only"
    output_range: "|y| <= 0.015 m, |x| <= 0.010 m"
    added: "2026-11-09"
  - name: player_pose_delayed
    status: active
    source: design/gdd/jugador-en-primera-persona.md
    referenced_by: []
    expression: "lerp over ring buffer N = ceil(T_hist*f_fisica)+1; s = tau*f_fisica"
    output_range: "tau in [0, T_hist]"
    added: "2026-11-09"
```
