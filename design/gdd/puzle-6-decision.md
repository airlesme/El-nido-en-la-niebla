# Puzle 6 · Decisión (sistema 16)

> **Status**: Revisado (ronda de corrección 9) — pendiente de re-review
> **Author**: Narrative Director (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Ambivalencia sin moral binaria (ninguna opción es incorrecta) · Autonomía como progresión (la elección es del jugador y es definitiva) · Información incompleta (la carta no explica por qué firmó Vera) · Tensión sin castigo (sin fallo, sin temporizador de solución)

## Summary

El compartimento 4 de la caja (`D01d`) tiene un panel con tres botones: **«Estoy bien»** (A), **«La verdad»** (B) y **«Todavía no»** (C). El jugador pulsa uno, una sola vez. Esa elección fija `carta_variante`, abre la tapa, muestra la carta de Vera con una primera frase distinta según la opción (`CARTA_A`/`CARTA_B`/`CARTA_C`) y el mismo cuerpo (`CARTA_CUERPO`), y cambia la primera línea de la llamada (`VO_G_12A/B/C`, escena 7). No hay respuesta incorrecta: es la primera decisión de la historia que el juego devuelve después. Este GDD **instancia** el marco de puzles (9); no redefine su ciclo de vida, su esquema de datos ni sus avisos.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `9 Marco de puzles`, `10 Caja y compartimentos`, `18 Base de contenido narrativo` · Escribe: nada (los hechos los escribe 9) · Política de validación: `ON_CHOICE`

## Overview

P6 es el último puzle de la caja y el único sin dificultad: su peso es emocional. Cuando `caja_c1`, `caja_c2` y `caja_c3` son verdaderos, P6 pasa de `BLOQUEADO` a `ACTIVO` (solo `SFX_UNLOCK_SOFT`; el compartimento no se entreabre). El jugador abre la vista `D01d` (sin apertura previa de tapa) y ve los tres botones. Al pulsar uno, el marco recibe `SOLVED` con la opción como carga útil y escribe, en el mismo fotograma, `carta_variante` y después `caja_c4` (9, regla 16 y F5); `caja_completa` lo recalcula el estado (3). La presentación es no bloqueante: `SFX_LOCK_CLICK` (0,3 s), la tapa (`BOX_C4_OPEN`, 1,6 s, la anima 10 con `play_open(4)`) y, al final, 9 pide a 7 `abrir_lectura(I-07)`. La carta queda en el bolsillo (D-14: permanente) y se relee con `repasar_bolsillo` (20). Si el jugador tarda, hay dos pistas automáticas (10 s y 20 s sin pulsar) que solo informan de la regla (elección única) y de lo que cambia (la primera frase), nunca de qué elegir.

Este GDD no escribe ni modifica ningún texto de la carta ni de la llamada: los textos son de 18 y los redacta el writer.

## Player Fantasy

Vera no resuelve nada: **contesta**. Tres botones de latón en el frontal de la caja y una pregunta que nadie formula en voz alta («¿qué le dices a la carta que escribiste?»). El jugador siente el peso de una decisión pequeña, íntima y sin red: no hay respuesta que aplauda ni respuesta que castigue, y nadie le dice cuál era la «buena». Pulsa, la cerradura cede, la tapa se abre sin prisa y aparece una carta con **su** primera frase y un cuerpo que es igual para todos. Más tarde, en la llamada, una voz le repite lo que «escribió». Ahí la elección cobra peso, sin que el juego lo explique.

Aesthetics del MDA: **Narrative** (la primera decisión de la historia que el juego devuelve), **Fantasy** (Vera habla por sí misma). Necesidad SDT: **Autonomía** (la decisión es libre y es suya; nadie la guía). Tests de pilar: si dudamos entre una pista que señale una opción «recomendada» y una que solo explique la regla, elegimos la que explica la regla (*Ambivalencia sin moral binaria*, *Autonomía como progresión*); si dudamos entre una fanfarria o un icono al elegir y el clic seco de la cerradura, elegimos el clic (*El espacio expresa la emoción*; 10, regla 20: la caja no celebra); si dudamos entre un diálogo de confirmación («¿seguro?») y dejar que el jugador pulse, dejamos que pulse (anti-pilar *NOT una historia explicada*; D16-1).

## Detailed Rules

Convención: «regla N de 9» = regla N del *Core Rules* de `marco-de-puzles.md`. «Regla 27b de 7» es el apartado (b) de la regla 27 de `interaccion-e-inspeccion.md` (así lo citan 9, 10 y 20). Los textos de la carta, de los botones y de las pistas son de 18 y los redacta el writer: este GDD **no los escribe ni los cambia**.

### A. Identidad y acceso

1. **Instancia del marco.** P6 es un puzle `VIEW` (vista `D01d`), política `ON_CHOICE` (regla 12 de 9), resolución `IMMEDIATE` (regla 17 de 9), `solved_flag` = `caja_c4`, `compartment: 4`. Todo valor numérico vive en `puzzles.json` (sección «Datos del puzle»), nunca en el controlador (regla 5 de 9). La clase `Puzzle6Controller` hereda de `PuzzleController` (regla 9 de 9) y **solo** devuelve veredictos (regla 10 de 9).
2. **Acceso.** `requires.all = [caja_c1, caja_c2, caja_c3]` (Anexo B.6 del slice; D9-35; el orden de la caja, D-16 del slice, sigue pendiente de confirmar). Mientras falte alguno, P6 está `BLOQUEADO`: 10 contesta `SIN_EFECTO` al pulsar `D01d` y la vista no se abre (reglas 7 y 24 de 9; regla 8 de 10). Al pasar a `ACTIVO` solo suena `SFX_UNLOCK_SOFT`; **C4 no se entreabre** (`ajar_cm` no se aplica, D9-48, regla 13 de 10).
3. **Apertura de la vista.** `D01d` se abre desde `exploración` **sin apertura previa de la tapa** (regla 11 de 10): los tres botones y la cerradura están en el frontal. El cursor entra libre: **ningún botón queda preseleccionado ni con foco inicial** (D16-1).

### B. La elección

4. **Opciones.** Exactamente tres botones, con IDs `D01d/button_A`, `D01d/button_B` y `D01d/button_C`, en este orden: **A «Estoy bien»**, **B «La verdad»**, **C «Todavía no»** (slice §10.6 y B.6). Los tres son `atraccion = true` y del mismo tamaño y peso en `elements()` (regla 9 de 9). El texto de cada botón es de 18 (ver Cambios requeridos: nombre de las claves). Ninguna opción es incorrecta, ninguna es la «recomendada» y **ningún aspecto del panel codifica bueno/malo** (pilar 1; el aspecto lo decide arte, Open Question 6).
5. **Cómo se acepta.** 7 entrega `seleccionar` como **un único evento con `inicio` y `fin` en el mismo fotograma, al soltar** (regla 20 de 7, tabla); su `elemento` es el fijado al pulsar. El controlador acepta la elección al recibir un `seleccionar` cuyo `elemento` es uno de los tres botones y, **cuando 7 defina `elemento_bajo` para `seleccionar`** (hoy no está especificado; ver Cambios requeridos, 7), cuyo `elemento_bajo` coincide con `elemento` (se suelta sobre el mismo botón que se pulsó). Un gesto que pulsa y se mueve más del umbral de arrastre es `agarrar` (7), no `seleccionar`: **no elige**. Una `cancelación` (cierre de vista, `atrás`, pausa, pérdida de foco; regla 11b de 9) **no elige**. Un `seleccionar` fuera de un botón no hace nada (pero un clic en vacío sí reinicia la inactividad, F1; el reinicio ocurre al recibirse el `seleccionar`, es decir, al soltar). Motivo: la elección es definitiva (D16-2). El slice (B.6) dice «pulsar»; la aceptación al soltar es el cambio registrado en D16-2.
6. **Una sola vez.** El primer botón aceptado fija el veredicto `SOLVED` con `choice` ∈ {`A`, `B`, `C`}; el marco descarta cualquier segundo `SOLVED` (S9, regla 28 de 9) y los otros dos botones quedan **inertes** (se ignoran sus gestos; no hay `REJECT`, no hay sonido). Dos pulsaciones en el mismo fotograma: gana la primera que llega al marco (AC-25 de 9).
7. **No hay fallo.** P6 no puede devolver `REJECT`; si lo hiciera, el marco lo trata como `NONE` y lo registra como error de datos (reglas 14 y 15 de 9). Tampoco hay `on_reject` en los datos.
8. **La elección es definitiva (D-14, decisión del usuario: «la respuesta es definitiva»).** Desde la aceptación: (a) `carta_variante` es un hecho de un solo sentido (3, regla 4); (b) P6 es `RESUELTO` y nunca vuelve atrás (reglas 6 y 28 de 9); (c) la vista **no se reabre** (`on_reopen: NO_VIEW`; 10 contesta `SIN_EFECTO`, reglas 7 y 35 de 9); (d) no existe «deshacer», «cambiar carta» ni segunda carta. La permanencia afecta solo al estado **persistido**: si el juego se cierra antes de que se guarde la resolución, la elección no existe y al cargar puede rehacerse (regla 24, Edge Case 6). **Esto roza «la respuesta es definitiva» (D-14) y se eleva a la Open Question 12; no se decide aquí** (D16-10, D16-16).
9. **Sin confirmación.** No hay diálogo «¿seguro?», ni texto previo que anuncie que es definitiva, ni segundo clic (D16-1). Quien elige antes de los 10 s de la pista 1 elige sin saber que es definitiva (D-W5); es una asimetría **aceptada** (Edge Case 1) y se eleva a la Open Question 1.

### C. Qué determina la variante y qué escribe cada sistema

10. **`carta_variante` = la opción pulsada, y nada más.** `A`→`CARTA_A`, `B`→`CARTA_B`, `C`→`CARTA_C`. No depende de `t4_decision`, de `respuesta_llamada` ni de ningún otro hecho: `respuesta_llamada` (A–D) se escribe **después** (escena 7) y no puede influir en la carta; la variante `D` de la llamada («No responder») **no existe en la carta** (el grupo `CARTA_` solo tiene A–C, 18 regla 5; AC-05 de 18). La variante solo cambia líneas (pilar 1, tabla de ingeniería): `VO_G_12A/B/C` en la llamada (22, regla 7) y el primer fragmento de `I-07` (20, R2 y AC-13).
11. **Quién escribe qué.** **9 es el único escritor** de `carta_variante` y `caja_c4` (regla 1 de 9); P6 no escribe ningún hecho, no emite avisos y no llama a 3. El marco ejecuta la regla 16 de 9 en el mismo fotograma, en este orden: (1) `carta_variante` = `choice`; (2) `caja_c4` = verdadero; (3) el estado recalcula `caja_completa` (si `caja_c1`–`c3` ya eran verdaderos; no lo escribe 9); (4) estado público `RESUELTO`; (5) aviso `EV_PUZZLE_SOLVED_P6` con `{puzzle: P6, rewards: [I-07], choice}`; (6) «compartimento completado» (4); (7) feedback y presentación (regla 13). El orden garantiza que quien reaccione a `caja_completa` ya lee `carta_variante` (F5 de 9, AC-17 de 9). **16 no escribe `caja_completa`, `llamada_*`, `respuesta_llamada` ni `t4_decision`.**
12. **La carta no explica.** La carta (`I-07`) es `CARTA_<variante>` + `CARTA_CUERPO` en estilo `manuscrito_vera` (20, R2). El juego no añade encima marcas, resaltados, comentario de Vera ni línea del Guardián sobre la elección (pilares 1 y 5; anti-pilar *NOT una historia explicada*). El texto lo escribe el writer.

### D. Presentación, lectura y recompensa

13. **Presentación no bloqueante** (regla 16.6 de 9; F2): en t = 0 (la aceptación) suena `SFX_LOCK_CLICK` (0,3 s); en t = 0,3 s `play_resolution` llama a `play_open(4)` de 10 (`BOX_C4_OPEN`, 1,6 s, `FINAL_ABIERTO`); la carta plegada queda visible dentro de la tapa a t = 1,9 s. Ningún hecho ni aviso espera a la presentación. No hay *stinger*, luz ni sonido de «caja completa» (regla 20 de 10). `close_view_after_s` es **nulo** (F4 de 9): el marco no cierra la vista; la cierra el jugador.
14. **Lectura aplazada de la carta.** Al final de la presentación (t = 1,9 s) el marco pide `abrir_lectura(I-07)` a 7 (regla 16.6 de 9). Según la tabla de la regla 27b de 7: con la vista `D01d` `Abierta`, `ACEPTADA` apilada sobre la vista; con la vista `Saliendo`, o `exploración` con una transición en curso (incluido el regreso de cámara), `APLAZADA` y se abre al volver `exploración` estable (tope de 3 s de tiempo de juego, después se descarta y la carta sigue en el bolsillo). Un `atrás` durante la salida lo consume la vista y **no** es un `repasar_bolsillo` (N4-2, D9-63, AC-59 de 9). La carta se cierra con `atrás`; la lectura apilada no cierra la vista: el jugador debe pulsar `atrás` otra vez para salir de `D01d`. **9 no reintenta ni cancela** la lectura por ningún `atrás` (regla 16.6 de 9); si se descarta, no se vuelve a pedir.
15. **La carta es permanente (D-14).** Desde que `caja_c4` es verdadero, `I-07` está en el bolsillo (20 la deriva del hecho, R5). El jugador la relee con `repasar_bolsillo` (`atrás` en `exploración`; R18 y R22 de 20; regla 35 de 9; D9-57, firme). P6 **no** pide relectura al reabrir (D9-54).
16. **Recompensa.** Solo `I-07` (la carta; `rewards: ["I-07"]`, informativa: 20 deriva el ítem de `caja_c4`). No hay medalla, logro, indicador ni cambio de música. El contenido de la recompensa es la carta y, después, la llamada.

### E. Pistas

17. **Dos niveles, solo texto** (D9-14, decisión del usuario; regla 27 de 9). Nivel 1 `PISTA_P6_N1` («Solo puedes elegir una vez») a los 10 s†; nivel 2 `PISTA_P6_N2` («La carta no cambia; cambia la primera frase») a los 20 s†. Textos de 18 (regla 20 de 18), sin `PISTA_P6_N3`. Los dos niveles informan de **la regla** (definitiva) y de **lo que cambia**; ninguno señala, resalta ni sugiere una opción (D16-4). Ningún nivel resuelve el puzle (no hay `AUTO_SOLVE_ELEMENT`): decidir es del jugador.
18. **Pistas automáticas.** Ambos niveles son `trigger: IDLE` con `idle_reset: PRESS_ONLY` («sin pulsar»; F3 de 9): `idle` solo se reinicia al recibirse un `seleccionar` (su `inicio`, que llega al soltar junto con el `fin`; incluido un clic en vacío); mover el cursor, la deriva de un stick o la pausa **no** lo reinician (D9-19; AC-31). Los dos umbrales se miden desde la **misma** última acción (el nivel 2 no se reancla al mostrar el 1). Cada nivel se dispara una vez por compromiso con la vista. **Reapertura (D16-14):** al volver a abrir la vista, `idle` empieza en 0 y los niveles **por encima** de `hint_level_reached` se rearman; un nivel ya alcanzado **no** vuelve a salir por umbral (monotonía, regla 26 de 9), pero **el texto del nivel más alto alcanzado se reaplica una vez al abrir la vista** (el jugador no pierde la información que ya tenía; es el mismo mecanismo que una pista pedida con la vista cerrada, Edge Case 11). Mientras no exista el sistema 17, `idle_hints_auto_apply` (verdadero†) aplica el texto solo (regla 26 de 9, D9-10); el 17 podrá desactivarlo y asumir el reparto.
19. **Relación con «pistas desde la pausa».** `IDLE` implica `REQUEST` (regla 25 de 9): el jugador puede pedir el nivel 1 o el 2 **en cualquier momento** desde el menú de pausa (17/25), incluso antes de los 10 s. Pedirlo cuenta como alcanzar el nivel y consume su umbral `IDLE` (no se aplica dos veces; AC-51 de 9); el nivel alcanzado (`hint_level_reached`) es monótono y solo en memoria (regla 26 de 9). `request_hint` solo es válido con P6 `ACTIVO`; tras resolverse, se rechaza. Desde la pausa el texto se **muestra al reanudar** y su duración usa el reloj de juego (reglas 26 y 36 de 9; AC-50). El marco no decide cuándo se ofrece una pista: eso es de 17.
20. **Las pistas no son información nueva** (regla 27 de 9): el panel tiene tres botones con su texto y la regla de «una sola vez» es la del slice (D-14). Las pistas la hacen explícita; no la crean.

### F. Ajustes, carga y cierre

21. **`reducir_sobresaltos`: P6 no lo lee.** P6 no tiene destellos, parpadeo ni sobresalto sonoro (`SFX_LOCK_CLICK` es un clic seco y bajo; la tapa es lenta). La atenuación del apagón y de `SFX_BREATH_BROKEN` es de 23/28 en la escena 7, que ocurre **después** y con otro dueño (6, tabla de consumidores). P6 no abre ninguna transición brusca hacia el apagón: el apagón lo dispara 21 al salir de D (D-03 del slice).
22. **`reducir_movimiento`: P6 no lo lee.** P6 no tiene `REJECT` (no hay temblor que sustituir, regla 14b de 9), ni fundido de superposición (no hay `DEFERRED`). La tapa (`BOX_C4_OPEN`, 1,6 s, lenta y sin sacudida) es escenificación de 10; este GDD **no la acorta ni la hace instantánea** con el ajuste activo y mantiene la carta a t = 1,9 s. Si el equipo de accesibilidad quiere otra cosa, la decide 10 (Open Question 5 de 10) y se refleja aquí (Open Question 5 de este GDD).
23. **Cierre de la vista.** `atrás` cierra `D01d` en cualquier momento (S4 de 9, regla 28; regla 23 de 7). Antes de elegir: no se pierde nada ni se penaliza; al volver, P6 sigue `ACTIVO`, `idle` empieza en 0 y las pistas siguen la regla de reapertura (regla 18, F1, D16-14). Después de elegir: ver regla 14 (lectura aplazada) y Edge Case 7 (la tapa continúa aunque el jugador salga; Edge Case 13 de 10).
24. **Guardado y carga.** El único estado de P6 es `caja_c4` (+ `carta_variante`). Se guarda con las causas `puzzle_solved:P6` y `compartment_done:4` (regla 23 de 9; 5 espera a que la cola de avisos esté vacía, de modo que nunca hay `caja_c4` sin `caja_completa` ni sin `carta_variante`). Al cargar con `caja_c4` verdadero: P6 `RESUELTO`; `restore_solved_presentation()` llama a `set_final_pose(4)` de 10 (tapa abierta con la carta plegada, sin animar, sin sonido, idempotente; regla 8 de 9, D9-51; regla 15 de 10); **no hay avisos, no hay `abrir_lectura` automática, no hay pistas**. Con `caja_c4` falso: `ACTIVO` o `BLOQUEADO` según `requires.all` (en silencio); el estado en memoria (ningún botón elegido, `idle` a 0, nivel de pista a 0) empieza vacío.
25. **Sin medidor ni marca.** Ningún hecho, ítem ni línea de P6 representa «moralidad» o «relación» (anti-pilar). `carta_variante` y `respuesta_llamada` solo eligen líneas (pilar 1, ingeniería; 22, regla 21).

## Formulas

P6 reutiliza las fórmulas del marco (F3, F4, F5, F7 y F9 de 9) con sus propios valores; no define ninguna regla numérica nueva. Las cifras † son anclajes de playtest, no de código.

### F1 · Pistas automáticas (instancia de F3 de 9)

`idle = t_ahora − t_ultima_accion`  (solo con la vista `D01d` abierta, en reloj de juego)
`nivel k se aplica por umbral cuando idle ≥ idle_s[k] y k > hint_level_reached`  (una vez por compromiso; k ∈ {1, 2}; al aplicarse, `hint_level_reached = max(hint_level_reached, k)`)
`al abrir la vista con hint_level_reached = k0 > 0: el texto del nivel k0 se reaplica una vez en t_apertura`

**Variables:** `t_ultima_accion` = instante de la apertura de la vista o del último `seleccionar` recibido (su `inicio`, que llega al soltar; `PRESS_ONLY`; cuenta un clic en vacío; no cuenta mover el cursor, la deriva de stick ni la pausa); `hint_level_reached` ∈ {0, 1, 2}, monótono y solo en memoria (regla 26 de 9); `idle_s[1]` = 10 s† (5–60), `idle_s[2]` = 20 s† (5–60), con `idle_s[1] < idle_s[2]`; ambos desde la **misma** `t_ultima_accion`.
**Output Range:** `idle` ≥ 0 s. Instantes de aparición: `t_apertura + idle_s[k]` o `t_último_clic + idle_s[k]`, el mayor; sin tope superior (S3 de 9: no hay temporizador de solución).
**Example:** el jugador abre la vista en t = 100 s y no pulsa: nivel 1 a 110 s, nivel 2 a 120 s. Si hace un clic en vacío en t = 104 s: nivel 1 a 114 s, nivel 2 a 124 s. Si mueve el cursor en t = 115 s: no cambia nada (nivel 2 a 124 s). Con la pausa abierta de t = 107 s a t = 137 s, `idle` queda en 7 s: el nivel 1 sale 3 s después de reanudar. Petición desde la pausa del nivel 1 con `idle` = 3 s: el nivel 1 se aplica al reanudar, se consume y no vuelve a salir; el nivel 2 sale a `idle` = 20 s. Petición del nivel 2 a `idle` = 3 s: se aplica el 2 y el nivel alcanzado pasa a 2, de modo que el 1 **no** sale después por umbral (monotonía, regla 26 de 9; ver Open Question 8). **Reapertura:** el jugador vio el nivel 1 (a 10 s), cierra a 14 s y reabre en t = 200 s: `hint_level_reached` = 1, así que el texto del nivel 1 se reaplica en t = 200 s, el nivel 1 no vuelve a salir por umbral y el nivel 2 sale a `idle` = 20 s (t = 220 s). Si había visto el 2 (a 20 s) y reabre: se reaplica el 2 en t_apertura y no sale ningún nivel más.

### F2 · Línea temporal de la elección (instancia de F5 de 9 y F5 de 10)

`t_hechos = 0`  ·  `t_clic = 0 … 0,3 s`  ·  `t_tapa_inicio = t_clic_fin = 0,3 s`  ·  `t_carta = t_tapa_inicio + BOX_C4_OPEN = 0,3 + 1,6 = 1,9 s`  ·  `t_pide_lectura = t_carta`

**Variables:** `t_clic` = `SFX_LOCK_CLICK` 0,3 s; `BOX_C4_OPEN` 1,6 s† (1,2–1,6, 10); `t_devolver` = 0,5 s (regreso de cámara, regla 18 de 2 / F4 de 9); `t_atrás` = instante de un `atrás` del jugador tras la elección; tope de la lectura aplazada = 3 s (regla 27b de 7).
**Salida del jugador antes de la carta:** `t_exploración = t_atrás + t_devolver`. Si `t_exploración ≤ t_pide_lectura`: `ACEPTADA` en `exploración` a t = 1,9 s. Si no: `APLAZADA` y se abre en `t_exploración`; espera = `t_exploración − t_pide_lectura` ≤ `t_devolver` = 0,5 s ≪ 3 s.
**Output Range:** `t_carta` ∈ [1,5; 1,9] s con `BOX_C4_OPEN` ∈ [1,2; 1,6]. Con la salida del jugador (`t_devolver` = 0,5 s) la espera de la lectura es ≤ 0,5 s (≪ tope de 3 s). Solo si una transición de 7 durase más (cota de 7, regla 23: ≤ 3 s), la espera podría alcanzar 3,0 s exactos y el tope sería un empate (la carta se descartaría y quedaría en el bolsillo; ver Edge Case 8).
**Example:** `t_atrás` = 1,0 s → `t_exploración` = 1,5 s: la carta se abre sola a 1,9 s, con la tapa terminando de abrirse. `t_atrás` = 1,8 s → `t_exploración` = 2,3 s: `APLAZADA` 0,4 s y la carta se abre a 2,3 s. Nada de esto retrasa ningún hecho (todos en t = 0).

### F3 · Duración del puzle frente a F7 y F9 de 9

`T_P6 = t_entrada + t_decisión + t_presentación + t_lectura + t_salida`

**Variables:** `t_entrada` = `t_vista_entrada_s` 1,0 s† (10, F1); `t_decisión` ≥ 0 s (sin tope: no hay reglas de tiempo); `t_presentación` = `t_carta` = 1,9 s (F2); `t_lectura` = 6–12 s† (estimación de playtest: 21–25 palabras†, cifra **sin fuente** —no sale de 18; pedida en Cambios requeridos (18)—, a 150–200 palabras por minuto da 21/200·60 = 6,3 s y 25/150·60 = 10,0 s; el rango 6–12 s añade margen por el cuerpo de la carta y la relectura; el mínimo usa 6,0 s, por debajo del cálculo, a propósito); `t_salida` = 0,5 s (`t_devolver`; el `atrás` de lectura añade ≈ 0 s).
**Output Range:** mínimo plausible = 1,0 + 2,0 + 1,9 + 6,0 + 0,5 = **11,4 s** (≈ 0,19 min); típico de un jugador nuevo = 1,0 + 15 + 1,9 + 10 + 0,5 ≈ **28 s** (≈ 0,47 min); techo de F7 (2 min = 120 s) ⇒ `t_decisión` máx. = 120 − (1,0 + 1,9 + 12 + 0,5) = **104,6 s**.
**Observación:** el mínimo de F7 para P6 (0,5 min = 30 s) es un objetivo para jugadores nuevos, **no** un suelo: un jugador decidido está por debajo (11,4 s). No contradice F9 (F9 ya dice «a medir»), pero el mínimo de F9 sobrestima el tiempo de P6 hasta en ≈ 18,6 s (0,31 min). No hay cambio requerido; queda anotado en la Open Question 9. Las pistas (10 s y 20 s) caen antes del mínimo de F7 (30 s), así que un jugador que dude las ve dentro de la ventana prevista.

## Edge Cases

1. **El jugador decide en menos de 10 s sin saber que es definitiva (D-W5).** Es válido y no recibe aviso: no hay diálogo, ni pista previa, ni deshacer (regla 9). La elección queda fijada, `carta_variante` se escribe y la llamada la devuelve. Es la asimetría deliberada de «pistas automáticas»: quien duda se entera de la regla (nivel 1, 10 s; o desde la pausa en cualquier momento, regla 19); quien actúa con decisión ejerce la autonomía del pilar 3 sin red. Se eleva como Open Question 1 porque toca el tono del momento más íntimo del slice.
2. **Dos botones pulsados en el mismo fotograma** (o dos gestos `seleccionar` concurrentes en mando/ratón): gana el primero que llega al marco; el segundo se descarta (S9 de 9, AC-25 de 9). Solo uno fija `carta_variante`.
3. **Pulsar en un botón y soltar en otro (o fuera).** Si el movimiento supera el umbral de arrastre es `agarrar` (7), no `seleccionar`: no elige nada. Si 7 entrega un `seleccionar` cuyo `elemento_bajo` (cuando lo defina) no coincide con `elemento`, tampoco elige (regla 5). Una `cancelación` (pausa, `atrás`, pérdida de foco) tampoco elige (regla 11b de 9). Un clic en vacío reinicia la inactividad (al recibirse el `seleccionar`) pero no elige.
4. **Cerrar la vista antes de elegir (`atrás`).** No se pierde ni penaliza nada (regla 23). Al reabrir: `idle` empieza en 0; los niveles por encima de `hint_level_reached` se rearman; **un nivel ya alcanzado no vuelve a salir por umbral (monotonía, regla 26 de 9) pero su texto —el del nivel más alto alcanzado— se reaplica una vez al abrir la vista** (F1, D16-14; comportamiento más seguro: el jugador no pierde información ya ofrecida). Si el jugador cierra a los 9 s (sin nivel alcanzado) y reabre, la cuenta empieza de nuevo.
5. **`atrás` durante la presentación** (entre t = 0 y 1,9 s). Lo consume la vista que sale; no es `repasar_bolsillo` (D9-63, AC-59 de 9). La tapa continúa (Edge Case 7) y la carta se abre sola al volver `exploración` estable (F2). El jugador no pierde la carta ni la elección.
6. **Cierre del juego a mitad de la presentación o antes del guardado.** Los hechos se escriben en t = 0 y 5 guarda con las causas `puzzle_solved:P6` / `compartment_done:4` cuando la cola de avisos queda vacía (regla 23 de 9). Si el guardado llegó a escribirse: al cargar, `caja_c4` verdadero (regla 24, Edge Case 9). Si el juego se cerró antes: P6 vuelve a `ACTIVO` y el jugador puede elegir **otra** opción (no hay hecho de un solo sentido persistido; D-14 gobierna lo persistido). **Esto roza «la respuesta es definitiva» (D-14) en el momento más íntimo del slice: es una Open Question (12), no una decisión cerrada.** `periodic` y `quit` de 5 cubren el cierre normal.
7. **El jugador sale de `D01d` mientras la tapa se abre.** La animación `BOX_C4_OPEN` continúa y termina con el jugador en `exploración` (Edge Case 13 de 10). Los hechos y la elección no se ven afectados.
8. **`abrir_lectura(I-07)` `APLAZADA` vence (3 s), `RECHAZADA` o descartada.** La carta no se abre sola; `I-07` ya está en el bolsillo (20 la deriva de `caja_c4`) y se lee con `repasar_bolsillo` (regla 15; AC-12 de 20). No se reintenta (regla 14). Los motivos de rechazo (`inspección`, `ordenador`, `llamada`, otra lectura abierta) no pueden darse en P6 sin consola: la vista del P6 es el único modo abierto al resolver.
9. **Cargar tras elegir** (en cualquier punto posterior): P6 `RESUELTO`, C4 `FINAL_ABIERTO` sin animar ni sonar, `I-07` en el bolsillo con la variante guardada, sin lectura automática y sin avisos (reglas 8 y 24 de 9; AC-02 de 20). La llamada lee `carta_variante` (22, regla 7) sin importar si el jugador llegó a leer la carta.
10. **Pausa dentro de la vista.** `idle` no avanza (F3 de 9, AC-50). Un nivel pedido desde la pausa se aplica al estado en el acto y su texto se muestra al reanudar (regla 19). Un clic sobre el menú de pausa no cuenta como `seleccionar` de la vista.
11. **Pista pedida con la vista cerrada** (`request_hint(P6, k)` con P6 `ACTIVO`): se aplica al estado y el texto se muestra la próxima vez que se abra la vista (regla 26 de 9). **Pista pedida con P6 `BLOQUEADO` o `RESUELTO`:** `request_hint` la rechaza (`ACTIVO` es condición); no hay efecto ni error visible.
12. **`caja_c4` verdadero y `carta_variante` sin fijar** (solo consola; estado imposible por el orden de F2/F5): 20 dibuja `I-07` con `CARTA_CUERPO` solo y registra un error en desarrollo; 22 omite `VO_G_12*` y avisa (D22-12). P6 no inventa una variante y no reescribe el hecho (el marco no escribe en la carga).
13. **La consola fuerza `caja_c4`** (regla 31 de 9): P6 queda `RESUELTO` en silencio, sin `EV_PUZZLE_SOLVED_P6`, sin tapa animada y sin carta. **Un controlador que devuelve `REJECT`:** se trata como `NONE` y se registra como error de datos (regla 15 de 9).
14. **`reducir_movimiento` o `reducir_sobresaltos` cambian durante la presentación.** No afectan: P6 no los lee (reglas 21 y 22). Un cambio de `reducir_sobresaltos` durante la escena 7 lo gestionan 23/28, no P6.
15. **Mando o teclado.** Sin foco inicial en ningún botón (regla 3); la navegación y la atracción asistida son de 7 y Entrada (`atraccion = true`). El primer botón enfocado no equivale a elegirlo: la elección exige `seleccionar` (regla 5).
16. **El jugador sale de D sin haber leído la carta** (la descartó o cerró de inmediato) y la llamada se dispara (D-03 del slice, 21/22): `VO_G_12*` cita lo que Vera «escribió» aunque el jugador no lo haya leído; la carta sigue en el bolsillo. Es válido por diseño (pilar 3: el jugador decide qué leer) y no bloquea nada; si el efecto emocional resulta débil, el playtest del criterio 6 del slice (§19) lo revelará.
17. **Resolubilidad (S7 de 9).** Desde cualquier estado alcanzable con P6 `ACTIVO` —tras pistas, cancelaciones, cierres y reaperturas, y guardar y cargar a mitad— el jugador puede pulsar cualquiera de los tres botones y llegar a `RESUELTO` (regla 30 de 9): ningún botón se bloquea salvo después de la aceptación.

## Dependencies

Convención (como en 22): **la dureza la declara el dependiente**; el proveedor la repite en su propio GDD. P6 es el dependiente de 9, 10 y 18 (índice, fila 16: «9, 10, 18»); de los consumidores de lo que P6 produce (20, 22) la declaran ellos.

| Sistema | Dureza | Quién la declara | Qué usa P6 | Qué da P6 | Referencia |
|---|---|---|---|---|---|
| 9 Marco de puzles | **Dura** | 16 (dependiente) | Ciclo de vida, `ON_CHOICE`, escritura de hechos (`carta_variante`, `caja_c4`), avisos, pistas `IDLE` y `request_hint`, `restore_solved_presentation`, `on_reopen`, `abrir_lectura(I-07)` al final de la presentación | `Puzzle6Controller` (veredicto `SOLVED` + `choice`), sus datos de `puzzles.json`, `elements()` de `D01d` | reglas 1, 4, 7, 9, 12, 16, 24 a 27, 35 de 9; F3, F5, F7 y F9 |
| 10 Caja y compartimentos | **Dura** | 16 (dependiente; 9 ↔ 10 es circular aceptada, D9-62) | `play_open(4)` (tapa, 1,6 s), `set_final_pose(4)`, anclaje `ANC_D01d` y nodos de los botones, respuesta `SIN_EFECTO` en `BLOQUEADO`/`RESUELTO`, carta plegada como decorado | Llamadas desde `play_resolution` (`play_open(4)`) y `restore_solved_presentation` (`set_final_pose(4)`); los tres botones cuelgan de los nodos de la caja | reglas 8, 11, 13, 15, 16, 20 de 10; F5 de 10 |
| 18 Base de contenido narrativo | **Dura** | 16 (dependiente) | Textos: los tres botones, `CARTA_A/B/C`, `CARTA_CUERPO` (no los usa P6 directamente: los dibuja 20; el panel usa los de los botones), `PISTA_P6_N1`, `PISTA_P6_N2` | Ninguna | reglas 5 y 20 de 18; AC-03 y AC-05 de 18 |
| 20 Documentos y bolsillo | Blanda | 20 (dependiente de 9; 16 no depende de 20) | La carta (`I-07`) la dibuja y la guarda 20 desde `caja_c4` y `carta_variante`; el repaso (`repasar_bolsillo`) | Hechos `caja_c4` y `carta_variante` (vía 3, escritos por 9); aviso `rewards: [I-07]` informativo | R2, R5, R13, R18, R22 de 20 |
| 7 Interacción e inspección | Blanda (indirecta vía 9) | 9 y 7 | `D01d` se abre por `abrir_vista` (la llama 10); `PointerEvent` `seleccionar`; `abrir_lectura` (regla 27b de 7), cierre de lectura y de vista (regla 23) | — (P6 no llama a 7: lo hace el marco) | reglas 20 a 23, 27 de 7 |
| 22 Llamada telefónica | Indirecta (vía 3) | 22 (dependiente) | — | `carta_variante` (A–C): elige `VO_G_12A/B/C` | reglas 7 y 21 de 22; D22-12 |
| 3 Estado y bus de eventos | Indirecta (vía 9) | 9 | — (P6 no lee ni escribe en 3) | `caja_c4` y `carta_variante` los escribe 9; `caja_completa` lo recalcula 3 | regla 7 de 3 |
| 6 Ajustes persistentes | **Ninguna** | — | P6 no lee `reducir_sobresaltos` ni `reducir_movimiento` (reglas 21 y 22); 9 sí lee `reducir_movimiento` para los rechazos (que P6 no tiene) | — | tabla de consumidores de 6 |
| 17 Sistema de pistas (`sistema-de-pistas.md`) | Blanda (la declara 17) | 17 | — | Dos niveles `IDLE` con texto, para que 17 asuma el reparto | reglas 25 y 26 de 9 |

**Bidireccionalidad.** 9 y 10 ya listan «11 a 16» / «13 a 16» como dependientes (índice, fila 9; regla 24 de 9; 10, tabla de Dependencies); 18 lista «16 Puzle 6 | Los tres botones, `CARTA_A/B/C` y `CARTA_CUERPO`»; 20 y 22 ya describen su lectura de `carta_variante`/`I-07`. Lo que falta por reflejar está en «Cambios requeridos en otros GDDs».

**Circularidad.** 16 → 9 → 10 y 16 → 10 → 9 reproducen el ciclo 9 ↔ 10 ya aceptado (D9-62): ambas llamadas ocurren en ejecución tras «escena lista»; no hay ciclo de construcción.

## Tuning Knobs

Todos viven en `puzzles.json` o en los datos de su dueño (regla 5 de 9: «todo valor numérico vive aquí»). † = a validar en playtest.

| Knob | Tipo | Defecto | Rango seguro | Qué afecta | Fuente / rationale |
|---|---|---|---|---|---|
| `idle_s` nivel 1 (P6) | G | **10 s†** | 5–60 (y `< idle_s[2]`) | Cuándo aparece «Solo puedes elegir una vez». Más bajo: el aviso llega a jugadores que aún leen el panel (los trata como indecisos); más alto: más jugadores eligen sin saber que es definitiva (D-W5) | slice B.6; F1; `idle_s_P6_N1,N2` de 9 |
| `idle_s` nivel 2 (P6) | G | **20 s†** | 5–60 (y `> idle_s[1]`) | Cuándo aparece «La carta no cambia; cambia la primera frase» | slice B.6; F1 |
| `idle_reset` (P6) | enum | `PRESS_ONLY` | `GESTURE`, `GESTURE_AND_MOVE`, `PRESS_ONLY` | Qué reinicia la inactividad. Con `GESTURE_AND_MOVE` mover el cursor retrasaría las pistas a un jugador que lee el panel con el ratón | F3 de 9, D9-19: coincide con «sin pulsar» (B.6) |
| `idle_hints_auto_apply` (global de 9) | bool | verdadero† | — | Si 9 aplica solo las pistas `IDLE` (hasta que exista 17). Con falso, solo salen desde la pausa | regla 26 de 9; D9-10 |
| `SFX_LOCK_CLICK` duración | F | 0,3 s | fija (slice B.6) | Retraso de la tapa respecto al clic; entra en `t_carta` (F2) | slice B.6; regla 16.6 de 9 |
| `BOX_C4_OPEN` | F | 1,6 s† | 1,2–1,6 | Duración de la tapa; `t_carta` = 0,3 + `BOX_C4_OPEN` (F2). Lo posee 10 | 10, Tuning Knobs; D10-2 |
| `close_view_after_s` (P6) | F | **nulo** | nulo (no knob) | No hay cierre automático: el jugador cierra tras leer la carta. Cambiarlo a un valor sería una decisión de diseño (F4 de 9) | F4 de 9 |
| `ajar_cm` (P6) | F | **0 (no aplica)** | — | C4 no se entreabre al desbloquearse (D9-48) | regla 13 de 10 |
| Tope de la lectura aplazada | F | 3 s | (de 7) | Cuánto espera `abrir_lectura(I-07)` si el jugador sale durante la presentación | regla 27b de 7; F2 |
| `lectura_min_s` de `I-07` | F | (de 7/20) | — | No lo fija este GDD; no se muestra al jugador | catálogo de 7 |

**No son knobs:** el número de botones (3), el número de niveles de pista (2; D9-14), la permanencia de la elección (D-14, es una regla, no un número), la regla de «un solo botón» y el orden de las escrituras (F5 de 9).

## Acceptance Criteria

Tipos: **L** = lógica (prueba automática con `GameClock` falso, regla 36 de 9), **I** = integración (con los sistemas reales: 9, 10, 7, 20, 22), **PV** = playtest o verificación visual con captura retenida en `production/qa/evidence/`. Entre paréntesis, la regla o fórmula que cubre.

- **AC-16-01 (R2, L):** **GIVEN** P6 `BLOQUEADO` con `caja_c1` y `caja_c2` verdaderos y `caja_c3` falso, **THEN** `get_view_gate('D01d')` devuelve `BLOCKED`, no se escribe ningún hecho y no se abre la vista; **WHEN** `caja_c3` pasa a verdadero, **THEN** P6 pasa a `ACTIVO`, se emite «puzle activado» (P6) una vez, suena `SFX_UNLOCK_SOFT` y `ajar_cm` no está en la carga útil (cubre AC-03 y AC-04 de 9).
- **AC-16-02 (R4, I):** **GIVEN** P6 `ACTIVO` y `D01d` abierta, **THEN** `elements()` devuelve exactamente `D01d/button_A`, `D01d/button_B` y `D01d/button_C`, los tres con `atraccion = true` y misma forma y tamaño, y ninguno tiene foco ni selección inicial.
- **AC-16-03 (R5, R8, L):** **GIVEN** P6 `ACTIVO`, **WHEN** llega un `seleccionar` (con `inicio` y `fin` en el mismo fotograma, al soltar) sobre el botón B, **THEN** el veredicto es `SOLVED` con `choice` = `B` y se aplica el orden de F5 de 9 (`carta_variante` = B, `caja_c4` = verdadero, `caja_completa` recalculado, estado `RESUELTO`, `EV_PUZZLE_SOLVED_P6` con `{puzzle: P6, rewards: [I-07], choice: B}`, «compartimento completado» (4)); **repetido** con A y C con resultado `carta_variante` = A y C (cubre AC-17 de 9).
- **AC-16-04 (R5, L):** **GIVEN** un gesto que pulsa sobre el botón A y se mueve más del umbral de arrastre hasta soltar sobre el B (`agarrar`, no `seleccionar`), **THEN** no hay veredicto `SOLVED` y no se escribe ningún hecho; **GIVEN** un `seleccionar` fuera de todo botón (clic en vacío), **THEN** no hay `SOLVED` y `idle` se reinicia al recibirse; **GIVEN** (cuando 7 defina `elemento_bajo` de `seleccionar`) un `seleccionar` con `elemento` = A y `elemento_bajo` ≠ A, **THEN** tampoco se elige; **GIVEN** una `cancelación` (`atrás`, pausa, pérdida de foco), **THEN** tampoco se elige.
- **AC-16-05 (R6, L):** **GIVEN** P6 `ACTIVO`, **WHEN** llegan dos `seleccionar` sobre dos botones distintos en el mismo fotograma, **THEN** solo el primero fija `carta_variante`, el segundo se descarta (S9) y tras la aceptación los otros dos botones no producen veredicto, sonido ni `REJECT` (cubre AC-25 de 9).
- **AC-16-06 (R7, L):** **GIVEN** un controlador de P6 que devuelve `REJECT`, **THEN** el marco lo trata como `NONE` y registra un error de datos; **GIVEN** `puzzles.json`, **THEN** P6 no declara `on_reject` (cubre AC-11 de 9).
- **AC-16-07 (R8, L + I):** **L: GIVEN** P6 `RESUELTO`, **THEN** no existe método de retroceso, `get_view_gate('D01d')` devuelve `SOLVED` y 10 contesta `SIN_EFECTO` (la vista no se abre; AC-04 y regla 35 de 9). **I: WHEN** se pulsa `D01d` con 10 y 7 reales, **THEN** suena `SFX_CLICK_SUBTLE`, no hay movimiento de cámara y `carta_variante` no cambia.
- **AC-16-08 (R10, L):** **GIVEN** `t4_decision` = `returned` o `assigned` y cualquier valor previo de `respuesta_llamada`, **WHEN** se elige A, B o C, **THEN** `carta_variante` es exactamente la opción pulsada (ninguna otra entrada influye) y nunca toma el valor `D`.
- **AC-16-09 (R11, I):** **GIVEN** un suscriptor de `caja_completa` con `caja_c1`–`c3` ya verdaderos, **WHEN** se elige una opción, **THEN** al recibir `caja_completa` ya lee `carta_variante` (cubre AC-17 de 9) y el hecho `caja_completa` lo escribe el estado, no 9 ni 16.
- **AC-16-10 (R13, F2, I):** **GIVEN** P6 con reloj falso, **WHEN** se elige a t = 0, **THEN** `SFX_LOCK_CLICK` se pide en t = 0; `play_open(4)` de 10 en t = 0,3 s; la tapa termina (`FINAL_ABIERTO`) en t = 1,9 s; `abrir_lectura(I-07)` se pide en t = 1,9 s; ningún hecho ni aviso se retrasa respecto a t = 0 (cubre AC-08 de 10 y AC-17 de 9).
- **AC-16-11 (R13, L):** **GIVEN** `puzzles.json`, **THEN** P6 declara `close_view_after_s` nulo y el marco no emite `cerrar_vista('D01d', 'resuelto')` tras resolver.
- **AC-16-12 (R14, I):** **GIVEN** la vista `D01d` `Abierta` al llegar `abrir_lectura(I-07)`, **THEN** `ACEPTADA` apilada; `atrás` cierra la carta y deja la vista abierta; un segundo `atrás` cierra la vista. **GIVEN** un `atrás` a t = 1,8 s, **THEN** la petición queda `APLAZADA` y la carta se abre en `exploración` estable a t ≈ 2,3 s sin repetirse; **GIVEN** un `atrás` a t = 0,5 s, **THEN** la carta se abre a t = 1,9 s en `exploración`. En ningún caso se emite `repasar_bolsillo` desde ese `atrás` (cubre AC-59 de 9 y AC-12c de 20).
- **AC-16-13 (R15, I):** **GIVEN** P6 `RESUELTO` y el jugador en `exploración` estable, **WHEN** pulsa `atrás`, **THEN** 20 abre `I-07` con `CARTA_<variante>` y después `CARTA_CUERPO` (`manuscrito_vera`, textos exactos de 18; AC-13 de 20) y la reapertura de `D01d` no la pide 9 (AC-42 de 9).
- **AC-16-14 (R16, L):** **GIVEN** cualquier elección, **THEN** `rewards` = [`I-07`] y no se emite ningún otro aviso de recompensa, indicador, sonido de «caja completa» ni cambio de música propios de P6 (regla 20 de 10; AC-13 de 10: ninguna diferencia visible ni audible entre variantes).
- **AC-16-15 (R17, R18, L):** **GIVEN** P6 con la vista abierta y reloj falso, **WHEN** pasan 10 s sin `seleccionar`, **THEN** se emite «puzle inactivo» (nivel 1) una vez y se aplica `PISTA_P6_N1`; a 20 s, nivel 2 con `PISTA_P6_N2`; mover el cursor a los 15 s no reinicia `idle`; un clic en vacío sí; `puzzles.json` declara exactamente dos niveles y ninguna clave `PISTA_P6_N3` (cubre AC-30 y AC-31 de 9).
- **AC-16-24 (R18, F1, L):** **GIVEN** P6 `ACTIVO`, reloj falso y `hint_level_reached` = 1 (nivel 1 aplicado a 10 s), **WHEN** se cierra y reabre la vista, **THEN** el texto de `PISTA_P6_N1` se reaplica una vez en t_apertura, el nivel 1 no vuelve a salir por umbral y el nivel 2 sale a `idle` = 20 s; **GIVEN** `hint_level_reached` = 2, **THEN** se reaplica `PISTA_P6_N2` al abrir y no sale ningún nivel más; **GIVEN** `hint_level_reached` = 0, **THEN** no se reaplica nada y los dos umbrales se rearman desde 0 (D16-14).
- **AC-16-16 (R17, L):** **GIVEN** `puzzles.json`, **THEN** ningún nivel de P6 declara `HIGHLIGHT`, `AFFORDANCE` ni `AUTO_SOLVE_ELEMENT`, y ninguno de los dos textos nombra una opción concreta (A, B, C, «Estoy bien», «La verdad» o «Todavía no»).
- **AC-16-17 (R19, L):** **GIVEN** el juego en pausa con P6 `ACTIVO`, **WHEN** `request_hint(P6, 1)` desde la pausa, **THEN** se aplica, el nivel alcanzado es 1, el umbral de 10 s no lo vuelve a aplicar y el texto se muestra al reanudar con duración medida en reloj de juego; **GIVEN** la pausa con `idle` = 7 s durante 30 s, **THEN** `idle` sigue en 7 s al reanudar (cubre AC-50 y AC-51 de 9); **GIVEN** P6 `RESUELTO`, **THEN** `request_hint` se rechaza.
- **AC-16-18 (R21, R22, I):** **GIVEN** `reducir_sobresaltos` o `reducir_movimiento` activos o inactivos, **WHEN** se resuelve P6, **THEN** `t_carta` = 1,9 s, la tapa dura `BOX_C4_OPEN` y el resultado es idéntico (P6 no lee ninguno de los dos ajustes); **GIVEN** un cambio de ajuste durante la presentación, **THEN** no hay efecto.
- **AC-16-19 (R24, L + I):** **GIVEN** una instantánea con `caja_c4` y `carta_variante` = C, **WHEN** se carga, **THEN** P6 `RESUELTO`, `set_final_pose(4)` se llama una vez sin animación ni sonido, no hay avisos ni `abrir_lectura` y `I-07` está en el bolsillo; **GIVEN** `caja_c4` falso con `requires.all` cumplido, **THEN** `ACTIVO` en silencio con el estado en memoria vacío; **GIVEN** el juego cerrado antes de que se guarde la resolución, **THEN** al cargar P6 está `ACTIVO` y puede elegirse otra opción (comportamiento actual, sujeto a la Open Question 12).
- **AC-16-20 (S7, L):** **GIVEN** `N_fuzz` = 1.000 secuencias aleatorias con pistas, cancelaciones, cierres y reaperturas y guardado/carga a mitad, **THEN** desde cualquier estado el solucionador de referencia llega a `RESUELTO` por la tubería real con cualquiera de las tres opciones (regla 30 de 9).
- **AC-16-21 (R10, I):** **GIVEN** `carta_variante` = A, B o C, **WHEN** se llega a la escena 7, **THEN** 22 pide exactamente `VO_G_12A`, `VO_G_12B` o `VO_G_12C` (AC-22-05 de 22).
- **AC-16-22 (PV, criterio 6 del slice):** **GIVEN** playtests, **THEN** las tres variantes de carta aparecen y al menos un jugador menciona que la llamada cambió según su elección; **y** ningún jugador describe una opción como «la buena» o «la correcta» (comprobación del pilar 1); **y** se registra cuántos jugadores eligen antes de ver el nivel 1 y cuántos dicen no haber sabido que era definitiva (D-W5; datos para la Open Question 1; instrumentación de la regla 32 de 9, solo en builds de desarrollo y playtest).
- **AC-16-23 (PV, R4, R13):** **GIVEN** una captura retenida de `D01d` con los tres botones, de la tapa abierta con la carta plegada y de la carta A, B y C, **THEN** el panel no codifica bueno/malo (sin rojo/verde moral; art bible) y las tres variantes de la caja son idénticas (AC-13 de 10).

## Datos del puzle

Entrada de `assets/data/puzzles/puzzles.json` según el esquema v2 de la regla 4b de 9 (D9-67 a D9-79); `schema_version: 2` es de la raíz del fichero y se repite en el ejemplo para fijar la versión de la entrada. Ningún campo de la entrada queda con ‡. Las claves de datos van en inglés; los IDs del slice se conservan. Los textos **no** están aquí: el panel y las pistas referencian claves de 18.

```json
{
  "schema_version": 2,
  "id": "P6", "mode": "VIEW", "view": "D01d",
  "solved_flag": "caja_c4",
  "requires": { "all": ["caja_c1", "caja_c2", "caja_c3"] },
  "validation": { "policy": "ON_CHOICE" },
  "solution": {
    "options": [
      { "choice": "A", "element": "D01d/button_A" },
      { "choice": "B", "element": "D01d/button_B" },
      { "choice": "C", "element": "D01d/button_C" }
    ],
    "accept": "ANY",
    "commit_on": "SELECT_END_SAME_ELEMENT"
  },
  "on_reject": null,
  "idle_reset": "PRESS_ONLY",
  "on_unlock": { "sfx": "SFX_UNLOCK_SOFT" },
  "on_solved": {
    "write": [
      { "flag": "carta_variante", "value_from": "choice" },
      { "flag": "caja_c4", "value": true }
    ],
    "compartment": 4,
    "sfx": "SFX_LOCK_CLICK", "sfx_s": 0.3,
    "presentation": [
      { "at_s": 0.3, "call": "play_open", "args": [4] }
    ],
    "rewards": ["I-07"],
    "request_reading": { "doc": "I-07", "at_s": 1.9 },
    "close_view_after_s": null
  },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "IMMEDIATE" },
  "hints": [
    { "level": 1, "trigger": "IDLE", "idle_s": 10, "availability": "ALWAYS",
      "effects": [ { "type": "TEXT", "key": "PISTA_P6_N1" } ] },
    { "level": 2, "trigger": "IDLE", "idle_s": 20, "availability": "ALWAYS",
      "effects": [ { "type": "TEXT", "key": "PISTA_P6_N2" } ] }
  ]
}
```

**Notas de validación (regla 29 de 9).**
- `id` y `solved_flag` únicos y declarados en `flags.json` (`caja_c4`, y `carta_variante` en `on_solved.write`); `requires.all` sin ciclos y con escritor (`caja_c1` P3, `caja_c2` P4, `caja_c3` P5); `rewards` y `view` existen en los catálogos (`I-07`; `D01d` en el catálogo de 7). Dos niveles de pista (no tres); cada nivel `TEXT` referencia una de las 8 claves `PISTA_*` de 18 (`PISTA_P6_N1`, `PISTA_P6_N2`; ninguna `PISTA_P6_N3`); sin `on_reject` (P6 no tiene fallo); estado inicial que no satisface su propia solución (ningún botón elegido, `carta_variante` sin fijar).
- Elementos de la vista: `pick_min_px` y separación mínima R₁+R₂ entre los tres botones con la tolerancia asistida y la normal (regla 29 de 9; la zona de botones **no** declara `atraccion_desactivada`). Los tres botones son del mismo tamaño y su separación es la misma entre pares (no hay botón «más cercano»).
- `value_from: "choice"` (valor de `on_solved.write` tomado de la carga útil del veredicto; sin `map`, se copia tal cual: `A`/`B`/`C`; regla 4b-a, D9-68), `commit_on` (`SELECT_END_SAME_ELEMENT`, el defecto de 9: acepta el `seleccionar` fase `fin` cuyo `elemento_bajo` es el mismo elemento fijado al pulsar; una `cancelación` nunca acepta; regla 4b-g, D9-73), `presentation` (`play_open(4)`), `request_reading` e `idle_reset` los define el esquema v2 de 9 (regla 4b-h, 4b-i, 4b-j) y ya están publicados: no queda ‡. `on_reject: null` es válido y esperado en `ON_CHOICE` (regla 4b-d, D9-70). Los botones no declaran `tolerance_px`: R = 64 px (‡ 7, propuesta de 9, D9-78); separación entre botones ≥ 128 px.
- `idle_s` por nivel está en los niveles de pista (regla 25 y F3 de 9); `idle_reset` es el campo de puzle que F3 de 9 declara («cada puzle declara qué cuenta»).
- Claves de los textos de los tres botones: pendientes de nombre en 18 (Cambios requeridos); no se referencian desde `puzzles.json` salvo que 9 los pida para `elements()`.

## Decisiones tomadas

Decisiones **del usuario** ya firmes (se recogen, no se discuten): P6 con **dos** niveles de pista (D9-14); la respuesta de la llamada es definitiva (D-15 del slice; la carta lo es por D-14); los textos los escribe el writer. Las demás son decisiones por defecto de este lote (recomendación propia), revisables.

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D16-1 | Sin diálogo de confirmación, sin aviso previo de que es definitiva y sin botón preseleccionado | Diálogo «¿Seguro?» o texto en el panel («solo una vez») | Un diálogo explicaría la decisión y la convertiría en un trámite (anti-pilar *NOT una historia explicada*, pilar 2); añadiría texto que no existe en 18; ningún botón preseleccionado evita sesgar la elección (pilar 1). El coste (elegir sin saber, D-W5) se mitiga con las pistas y se eleva como Open Question 1 |
| D16-2 | La elección se acepta al recibir el `seleccionar` único de 7 (llega al soltar, con `inicio` y `fin` en el mismo fotograma, regla 20 de 7), sobre un botón y, cuando 7 defina `elemento_bajo`, soltando sobre el mismo | Aceptar al pulsar (la letra de B.6: «pulsar»); suponer un `inicio` y un `fin` separados | La decisión es definitiva y el slice la quiere «íntima»: un arrastre (`agarrar`) o una cancelación no debe fijar la carta. 7 ya fija el evento único; la hipótesis de dos eventos era inalcanzable (revisión, aviso 2). Aceptar al soltar es un cambio respecto a la letra de B.6, coherente con 7 |
| D16-3 | P6 no lee `reducir_sobresaltos` ni `reducir_movimiento` | Hacer instantánea la tapa con `reducir_movimiento`; atenuar `SFX_LOCK_CLICK` con `reducir_sobresaltos` | P6 no tiene susto, temblor ni fundido; la tapa es lenta y la posee 10 (su Open Question 5). Mantener 1,9 s conserva F2/F3 y los AC de tiempo. Pendiente de 10 y accesibilidad (Open Question 5) |
| D16-4 | Las dos pistas son solo texto (`TEXT`) y nunca señalan una opción | `HIGHLIGHT` de un botón; una pista que sugiera «la más habitual» | Cualquier señal sobre un botón sesgaría la elección y lo convertiría en «el correcto» (pilar 1). Las pistas informan de la regla y de la consecuencia (regla 27 de 9: énfasis de información ya presente) |
| D16-5 | Las pistas pueden pedirse desde la pausa en cualquier momento (`IDLE` implica `REQUEST`) | Que solo salgan a los 10 y 20 s | Regla 25 de 9. Quien quiera saber la regla antes de elegir puede hacerlo sin esperar (pilar 3) |
| D16-6 | `close_view_after_s` nulo: la vista no se cierra sola | Cerrar a 1,5 s como P1/P3/P4/P5 | El jugador debe poder leer la carta y quedarse en el panel el tiempo que quiera; F4 de 9 ya lo prevé |
| D16-7 | La variante la fija solo la opción pulsada; no hay carta `D` | Variar la carta con `t4_decision` o crear una variante `D` | La carta se escribe antes de la llamada y de `respuesta_llamada` (escena 7), que no existe aún; `t4_decision` ya tiene su lector (`VO_G_14_*`, 22). El grupo `CARTA_` tiene A–C (18, regla 5) |
| D16-8 | Tras elegir, los otros dos botones quedan inertes sin `REJECT` ni sonido | Hacer que suenen o vibren (feedback de «ya has elegido») | Toda acción procesada genera respuesta (regla 13 de 9), pero un rechazo contradice «no hay fallo» (regla 15) y la caja no añade señal (regla 20 de 10); la respuesta es la propia presentación de la tapa |
| D16-9 | Tras cargar con `caja_c4` verdadero no se reabre la carta ni se repite la presentación | Reabrir la lectura al cargar | La carta ya se leyó (o está en el bolsillo); repetir un momento íntimo lo abarata. Relectura voluntaria con `repasar_bolsillo` (D9-57) |
| D16-10 | Si el juego se cierra antes de guardar la resolución, la elección se puede rehacer (**comportamiento por defecto, no cerrado: Open Question 12**) | Persistir la elección al pulsar con un guardado propio | El marco no añade hechos ni causas de guardado (regla 22 de 9); 5 espera a la cola de avisos. La ventana es la de un guardado automático, pero **roza D-14 («la respuesta es definitiva»)** en el momento más íntimo del slice; se eleva a OQ 12 sin decidir |
| D16-11 | Un nivel de pista pedido desde la pausa cuenta como alcanzado y consume su umbral; pedir el 2 sin el 1 deja el 1 como alcanzado por monotonía (no sale después por umbral) | Que el 1 siga saliendo por umbral | Monotonía de `hint_level_reached` (regla 26 de 9). Interpretación nuestra: confirmar con 9 (Open Question 8). Coherente con D16-14 |
| D16-12 | Los botones son del mismo tamaño y aspecto para las tres opciones; el orden A–B–C del slice se conserva | Orden aleatorio por sesión; tamaños distintos | El orden fijo es el del slice y evita que el diseño dé más peso a una opción (pilar 1). El aspecto lo decide arte (Open Question 6) |
| D16-13 | Los campos de datos `value_from`, `commit_on`, `presentation`, `request_reading` e `idle_reset` los define el esquema v2 de 9 (publicado, regla 4b); P6 los referencia. **(Ronda 8: absorbidos en 9, esquema v2, regla 4b, D9-68, D9-73; se quitan las ‡; `commit_on` usa el nombre de 9, `SELECT_END_SAME_ELEMENT`, con la semántica de 9: `fin` sobre el mismo elemento que `inicio`, que es el `seleccionar` único de 7 al soltar)** | Fijar aquí la sintaxis | El esquema es de 9 (cambio único de versión, resumen del lote). Solo cambia el bloque de datos |
| D16-14 | Reapertura de la vista: un nivel de pista ya alcanzado **no** sale otra vez por umbral, pero el texto del nivel más alto alcanzado **se reaplica una vez al abrir la vista**; los niveles superiores se rearman desde `idle` = 0 | No reaplicar nada (el jugador pierde lo ya ofrecido); rearmar también los niveles ya alcanzados (viola la monotonía de la regla 26 de 9 y repite la pista por umbral) | Lo más seguro: respeta la monotonía, no repite la pista como si fuera nueva y no retira información ya dada; es el mismo mecanismo que la pista pedida con la vista cerrada (regla 26 de 9, Edge Case 11). Decisión por defecto, pendiente de que 9 la confirme (Open Question 8) |
| D16-15 | `t_lectura` y las 21–25 palabras† quedan como estimación de playtest sin fuente; se pide a 18 el conteo real | Dar la cifra como dato de 18 | No se inventa una fuente; las cifras de F3 son anclajes (†). El cálculo (6,3–10,0 s) cae dentro del rango 6–12 s |
| D16-16 | El rehacer la elección tras un cierre antes de guardar (Edge Case 6, regla 8, D16-10) **se eleva a Open Question 12 sin decidirse**; mientras tanto rige el defecto de D16-10 | Prohibir la rehecha (guardado síncrono al pulsar) o aceptarla como firme | Roza D-14 («definitiva») en el momento más íntimo del slice; toca pilares y tono, y la decide el usuario. La revisión (aviso 5) pedía elevarlo |
| D16-17 | (Ronda 8) Alineado con el esquema v2 de `puzzles.json` (regla 4b de 9): `schema_version: 2`; `commit_on` = `SELECT_END_SAME_ELEMENT` (nombre de 9; sustituye al `SELECT_SAME_ELEMENT` provisional); `on_reject: null` explícito; sin ‡ en los campos absorbidos; R = 64 px de los botones ‡ 7 | Mantener el nombre provisional y las ‡ | Un nombre por concepto (D9-68, D9-73, D9-70, D9-78); sin cambio de diseño ni de tiempos |
| D16-18 | **(Ronda de corrección 9, `gdd-cross-review-2026-11-10.md`)** La fila de 17 pasa de «(sin GDD) · la declarará 17» a `sistema-de-pistas.md` («la declara 17»). Sin cambios de reglas | Dejar el texto hasta el próximo lote | Un «sin GDD» obsoleto sugiere un contrato abierto que ya está cerrado |

## Open Questions

Las cuestiones de **tono, pilares o alcance** no se deciden aquí. Este GDD no escribe ni modifica ningún texto de la carta, de los botones ni de la llamada.

| # | Pregunta | Quién decide | Impacto |
|---|---|---|---|
| 1 | **¿Debe el juego avisar de la permanencia antes de pulsar?** (D-W5) Hoy solo avisa la pista 1 (10 s) o la pausa; quien elige antes no lo sabe. Opciones: (a) dejarlo (defecto actual); (b) un indicio diegético en la cerradura, sin texto; (c) bajar `idle_s[1]`. **Toca tono y autonomía (pilar 3) y el momento más íntimo del slice.** Recomendación: (a) y medirlo en playtest (AC-16-22) | Usuario / creative-director | Pilares 1 y 3; no cambia reglas de 9 |
| 2 | **¿Pre-juzga la carta a la opción A?** `CARTA_A` («Estoy bien. Es lo que escribiría si no fuera verdad») afirma que «Estoy bien» no es verdad, y el botón B se llama «La verdad». Juntos pueden leerse como A = mentira, B = verdad: una lectura binaria que roza el pilar 1 («ninguna opción es incorrecta») y confirma un hecho de Vera (pilar 5). Los textos son del slice §12 y de 18 y **no se tocan aquí** | Narrative-director / writer / usuario | Pilares 1 y 5; el texto de `CARTA_A` y de las etiquetas de los botones |
| 3 | **¿Confirmar D-14?** El slice lo marca «Pendiente · Confirmar» (§20) aunque el usuario dijo que la respuesta es definitiva. Este GDD lo trata como firme | Usuario | Marcar D-14 como tomada en el slice (cambio requerido) |
| 4 | **D-16 (orden de la caja):** `requires` de P6 = `caja_c1`, `caja_c2`, `caja_c3` (Anexo B.6) frente a §8/§13.3 del slice, que dicen «cualquier orden». El Anexo manda (D9-12, D9-35) | Usuario | `requires.all` y AC-16-01 |
| 5 | **`reducir_movimiento` y la tapa:** la regla 14b(c) de 9 dice que las animaciones de movimiento «las resuelve el controlador con cambio instantáneo», pero 10 (Open Question 5) propone no acortar `BOX_Cn_OPEN`. P6 hoy **no** la acorta (D16-3). ¿Se mantiene? | Accessibility-specialist / ux-designer, con 10 y 9 | AC-16-18; sin cambio en `t_carta` si se mantiene |
| 6 | **Aspecto del panel de tres botones** (orden, material, iluminación, estado de los dos no elegidos tras la pulsación): como **entrada narrativa**, ningún aspecto debe codificar bueno/malo ni «el elegido es el correcto» (pilar 1; sin rojo/verde moral). La decisión visual es de arte | Art-director | Capturas de AC-16-23 |
| 7 | **La carta se abre sola (D7-32).** 7 decide, por defecto y revisable, que la carta se abre aunque el jugador salga antes; el propio 7 anota que «el usuario puede preferir (b)» (dejarla solo en el bolsillo). P6 solo hereda el comportamiento (regla 14) | Usuario (tono del clímax) | Reglas 14 y 15; Edge Case 8 |
| 8 | **Monotonía de las pistas y reapertura:** ¿pedir el nivel 2 sin haber visto el 1 deja el 1 como «alcanzado» (D16-11)? ¿Se reaplica el texto del nivel más alto alcanzado al reabrir la vista (D16-14)? La regla 25 de 9 solo dice que pedir un nivel consume *su* umbral; la regla 26 dice «monótono» y F3 «se rearma al volver a comprometerse» | Game-designer (9) | F1; Edge Case 4; AC-16-17; AC-16-24 |
| 9 | **F7/F9:** el mínimo de F7 para P6 (30 s) está por encima del mínimo plausible (11,4 s, F3 de este GDD). F9 queda conservador por ≈ 0,31 min | Producer / game-designer (9) | Solo estimación; sin cambio de reglas |
| 10 | **Efecto emocional de leer la carta tras la llamada o sin leerla** (Edge Case 16): si el jugador no la lee, `VO_G_12*` pierde su contexto. ¿Se acepta? (pilar 3 frente a criterio 6 del slice) | Usuario / narrative-director | Medir en playtest (AC-16-22) |
| 11 | **Tiempo de lectura de `I-07`:** no hay `lectura_min_s` definido para la carta ni cota máxima. Lo gestionan 7/20 | Game-designer (7) / 20 | Sin efecto en P6 |
| 12 | **¿Se puede rehacer la elección si el juego se cierra antes de guardar la resolución?** (Edge Case 6, regla 8, D16-10, AC-16-19). Hoy sí: al cargar, P6 está `ACTIVO` y el jugador puede elegir otra opción, lo que **roza «la respuesta es definitiva» (D-14)** en el momento más íntimo del slice. Opciones: (a) dejarlo (defecto actual; la ventana es la de un guardado automático); (b) guardado síncrono al aceptar la elección, antes de la presentación (cambia reglas de 5 y de 9, regla 22 de 9); (c) tratar `carta_variante` como persistida de inmediato y no rehacible. **Toca pilar 3 y tono; no se decide aquí** | Usuario / creative-director, con 5 y 9 | Pilares 1 y 3; regla 8; D16-10; AC-16-19 |

## Cambios requeridos en otros GDDs

Este GDD no ha editado ningún archivo existente. Cambios a aplicar (los coordina `producer`, regla 4 de coordinación):

| GDD | Cambio | Motivo |
|---|---|---|
| `systems-index.md` | Fila 16: estado «Borrador (lote Feature 3) — pendiente de review», ruta `design/gdd/puzle-6-decision.md`; dependencias «9, 10, 18 (duras; la dureza la declara 16; 9 ↔ 10 circular)» · indirectas 3 · consumidores: 20 y 22 (declaran ellos) | Existe el GDD |
| `marco-de-puzles.md` (9) | (a) **absorbido en 9 (esquema v2, D9-68, D9-73; regla 4b):** `value_from` en `on_solved.write`, `commit_on` (`SELECT_END_SAME_ELEMENT`), `presentation`, `request_reading` e `idle_reset`; 16 ya quitó las marcas ‡; (b) **absorbido en 9 (regla 4b-h, 4b-i, 4b-j):** `idle_reset` a nivel de puzle y `presentation`/`request_reading` en `on_solved`; queda ‡ 7 el R = 64 px de los botones sin tolerancia (D9-78); (c) **Open Question 2 de 9**: confirmar con este GDD que 7/20 cierran bien la carta apilada sobre la vista de P6 (AC-16-12 la cubre); (d) aclarar la monotonía de pedir un nivel **y si, al reabrir la vista, el texto del nivel más alto alcanzado se reaplica** (regla 26 de 9 y F3: «monótono» / «se rearma al volver a comprometerse»; Open Question 8 y D16-14 de 16); (e) añadir «16» a las referencias de P6 si procede; (f) **Open Question 12 de 16** (rehacer la elección tras un cierre antes de guardar; regla 22 de 9) | Datos de P6 en «Datos del puzle» |
| `caja-y-compartimentos.md` (10) | Fila «13 a 16 Puzles 3 a 6» de Dependencies: marcar P6 como GDD escrito; confirmar `ANC_D01d`, los nodos de los tres botones y que `set_final_pose(4)` es idempotente y silencioso; enlazar su Open Question 5 con la Open Question 5 de 16 | Dependencia dura 16 → 10 |
| `base-de-contenido-narrativo.md` (18) | (a) Nombrar las claves de los **tres botones** del panel (p. ej. `UI_P6_BOTON_A/B/C`; el registro de 18 solo dice «los tres botones») y sus textos «Estoy bien», «La verdad», «Todavía no»; (b) confirmar que 16 no necesita más claves; (c) Open Question 2 de 16 sobre `CARTA_A` y el botón B; (d) **aportar la fuente de las «21–25 palabras»** entre la primera frase y `CARTA_CUERPO` (F3 de 16 la marca † y no la inventa) o el conteo real de palabras de `CARTA_A/B/C` y `CARTA_CUERPO` para recalcular `t_lectura` | Dependencia dura 16 → 18 |
| `documentos-y-bolsillo.md` (20) | Mencionar a 16 como dueño del puzle que escribe `caja_c4`/`carta_variante` (vía 9) en Dependencies; sin cambio de reglas | Bidireccionalidad |
| `llamada-telefonica.md` (22) | En Dependencies, la fila 9 puede nombrar a 16 como el controlador que origina `carta_variante`; sin cambio de reglas | Bidireccionalidad |
| `interaccion-e-inspeccion.md` (7) | Catálogo de vistas: `D01d` con los elementos `D01d/button_A/B/C`; **definir `elemento_bajo` de `seleccionar`** (la regla 20 de 7 ya fija que `seleccionar` llega con `inicio` y `fin` en el mismo fotograma al soltar y que `elemento` es el de al pulsar, pero no especifica `elemento_bajo`): ¿el elemento bajo el cursor al soltar? 16 (regla 5, AC-16-04) lo usa para exigir que se suelte sobre el mismo botón; hasta entonces solo se exige `elemento` ∈ botones | Contrato de 7 |
| `slice-v0.3.md` (contenido v0.4.2) | Si el usuario confirma (Open Questions 3 y 4): pasar D-14 a «Tomada» y alinear §8/§13.3 con el Anexo B.6 (D-16). No se pide cambiar ningún texto | Estado de decisiones |
| `ajustes-persistentes.md` (6) | Ninguno (P6 no lee ajustes). Opcional: una línea en la tabla de consumidores aclarando que P6 no lee `reducir_*` | Claridad |

**Hechos/IDs nuevos que no existen aún:** los IDs de elemento `D01d/button_A/B/C` y las claves de texto de los botones (18).

## Entradas para el registro

Solo lo **nuevo**; lo ya registrado por 9, 10, 18, 20 y 22 (`P6`, `caja_c4`, `carta_variante`, `EV_PUZZLE_SOLVED_P6`, `I-07`, `idle_s_P6_N1,N2`, `BOX_C4_OPEN`, `PISTA_P6_N1/N2`, `CARTA_*`) no se repite.

| Tipo | Nombre | Valor / descripción | Fuente |
|---|---|---|---|
| constante | `P6_BUTTON_IDS` | `D01d/button_A`, `D01d/button_B`, `D01d/button_C` (A «Estoy bien», B «La verdad», C «Todavía no») | regla 4 |
| constante | `P6_CHOICES` | `A`, `B`, `C` (enum de `choice` y de `carta_variante`; sin `D`) | reglas 4 y 10 |
| constante | `P6_COMMIT_ON` | `SELECT_END_SAME_ELEMENT` (esquema v2 de 9, regla 4b-g) | regla 5, D16-2 |
| constante | `P6_LOCK_CLICK_S` | 0,3 s (duración de `SFX_LOCK_CLICK`) | slice B.6; F2 |
| fórmula | `t_carta_p6` | `0,3 + BOX_C4_OPEN` = 1,9 s (rango 1,5–1,9 s) | F2 |
| fórmula | `T_P6` | `t_entrada + t_decisión + t_presentación + t_lectura + t_salida`; mínimo plausible 11,4 s; típico ≈ 28 s | F3 |
| constante | `P6_T_LECTURA_EST_S` | 6–12 s† (estimación de lectura; las 21–25 palabras† no tienen fuente: pedida a 18) | F3 |
| constante | `idle_reset_P6` | `PRESS_ONLY` | regla 18 |
| regla | `p6_choice_is_final` | La elección es definitiva (D-14); `carta_variante` es un hecho de un solo sentido; la reapertura contesta `SIN_EFECTO` | regla 8 |
| regla | `p6_no_ajustes` | P6 no lee `reducir_sobresaltos` ni `reducir_movimiento` | reglas 21 y 22 |
| aviso | (ninguno nuevo) | P6 no emite avisos propios; usa `EV_PUZZLE_SOLVED_P6` y «compartimento completado» (4) de 9 | regla 11 |
| hecho | (ninguno nuevo) | P6 no escribe ni añade hechos; `carta_variante` y `caja_c4` son de 9 | regla 11 |
| clave de texto | `UI_P6_BOTON_A/B/C` ‡ | Textos de los tres botones; **nombre propuesto, pendiente de 18** | Cambios requeridos (18) |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Primer borrador (lote Feature 3, sistema 16), por el narrative-director en modo autónomo: reglas A–F (25), F1–F3, 17 edge cases, dependencias bidireccionales (16 → 9, 10, 18), knobs, 23 AC, entrada de `puzzles.json`, 12 decisiones (D16-1 a D16-12), 11 preguntas abiertas. Sin cambios en ningún archivo existente. Estado: Borrador (lote Feature 3) — pendiente de review. |
| 2026-11-09 | **Ronda de corrección 7** (revisión independiente `reviews/puzle-6-decision-review.md`: 0 bloqueantes, 6 avisos; revisión parcial). (1) Regla 5, Edge Case 3, D16-2 y AC-16-04 sin la hipótesis de `inicio`/`fin` separados: `seleccionar` llega único al soltar (regla 20 de 7); pide a 7 definir `elemento_bajo`. (2) Campos de datos remitidos al esquema v2 de 9 (D16-13; `commit_on` = `SELECT_SAME_ELEMENT`; ‡ conservado: 9 aún no los publica). (3) Rehacer la elección tras un cierre antes de guardar elevado a Open Question 12 (regla 8, Edge Case 6, D16-10, D16-16). (4) Reapertura de la vista: nivel alcanzado no sale por umbral pero su texto se reaplica una vez (regla 18, F1, Edge Case 4, D16-14, AC-16-24; OQ 8 ampliada). (5) `t_lectura`: 21–25 palabras† sin fuente, pedida a 18 (D16-15); recalculado 6,3–10,0 s dentro de 6–12 s. (6) Preguntas de tono (OQ 1 y 2) intactas. F2: redacción del Output Range aclarada. Fórmulas recomprobadas (F2 1,9 s; F3 11,4 / 28,4 / 104,6 s). Estado: Revisado (ronda de corrección 8) — pendiente de re-review. |
| 2026-11-09 | **Ronda de corrección 8:** alineación mecánica con el esquema v2 de `puzzles.json` (regla 4b de 9): `schema_version: 2`, `commit_on` = `SELECT_END_SAME_ELEMENT`, `on_reject: null`, quitadas las ‡ de `value_from`, `presentation`, `request_reading` e `idle_reset`, peticiones a 9 absorbidas marcadas, R = 64 px ‡ 7; D16-17. Sin cambio de diseño. Estado: Revisado (ronda de corrección 8) — pendiente de re-review. |
| 2026-11-10 | **Ronda de corrección 9:** fila de 17 con su GDD; D16-18. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. |
