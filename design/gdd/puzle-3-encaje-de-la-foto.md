# Puzle 3 · Encaje de la foto

> **Status**: Revisado (ronda de corrección 7) — pendiente de re-review
> **Author**: game-designer (lote autónomo) + agentes
> **Last Updated**: 2026-11-09
> **Sistema**: 13 · Puzle 3 · Encaje de la foto (`Feature`, categoría `Gameplay`, prioridad `MVP`)
> **Implements Pillar**: Tensión sin castigo (la pieza vuelve a la bandeja, sin contador ni espera larga) · Información incompleta (el puzle entrega un hecho —en la foto del equipo no hay nadie en el sexto hueco— y ninguna intención) · Autonomía como progresión (la solución se deduce de la forma y el color; el orden de las piezas y el orden respecto al P4 son libres) · El espacio expresa la emoción (el hueco vacío se comunica con luz y silueta, no con texto)

> **Convenciones.** ‡ = propuesta que debe confirmar el GDD del sistema afectado. † = valor propuesto, a validar en playtest. Las claves de datos van en inglés; los IDs del slice (`P3`, `D01a`, `caja_c1`, `I-06a`, `NOTA_01`, `SFX_SNAP`, `EV_PUZZLE_SOLVED_P3`…) se conservan tal cual. «Pieza P1»…«P5» y «hueco S1»…«S6» son los nombres del slice (B.3) en la prosa; los IDs de elemento llevan el prefijo de la vista (`D01a/piece_1`…`D01a/piece_5`, `D01a/slot_1`…`D01a/slot_6`, `D01a/frame`, `D01a/tray`), como exige la regla «Core Rules» de 9, para no colisionar con `P1`–`P5` (puzles). Las reglas se citan como «regla N de X» (X = número de sistema del índice).

## Summary

El puzle 3 es el primero de la caja de madera del Guardián. Dentro del compartimento 1 (`D01a`) hay un marco de seis huecos y una bandeja con cinco piezas de una foto rota: la foto del equipo. El jugador arrastra cada pieza a su hueco por forma y color; cuando la quinta encaja, el compartimento se abre y deja una nota en letra del Guardián. El sexto hueco **no tiene pieza y debe quedar vacío**: es un hecho que el puzle muestra sin explicarlo (qué significa ese vacío lo decide el jugador; ver Open Question 2). Es un puzle físico y sin riesgo (manipulación sencilla, el escalón bajo de la curva de dificultad del marco), con una sola salida mecánica y un único rechazo posible: la pieza que no encaja vuelve a la bandeja en 0,4 s.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `9 Marco de puzles` (dura), `10 Caja y compartimentos` (dura), `6 Ajustes persistentes` (blanda, `asistencia_encaje`) · Transitivas: `7 Interacción e inspección` y `2 Jugador` (vía 9), `18 Base de contenido` (dura en validación vía 9), `20 Documentos y bolsillo` (recompensa)

## Overview

El puzle 3 (`P3`) es una instancia del marco de puzles (9): no define ciclo de vida, política de fallo, escritura de hechos ni reparto de pistas, solo **sus datos y su controlador** (`PuzzleController`, regla 9 de 9). Vive en la vista cercana `D01a` (modo `VIEW`, `ACTIVO` desde el inicio, sin dependencias: `requires.all` vacío). La vista muestra un marco con seis huecos en tres filas (`S1 S2 / S3 S4 / S5 S6`) y una bandeja con cinco piezas (`P1`–`P5`). El jugador arrastra una pieza (ratón: pulsar, mover más de 8 px y soltar; mando: cursor virtual con el mismo gesto) y la suelta sobre el marco. Si queda a ≤ 0,04 m de **su** hueco (0,10 m con `asistencia_encaje`; 88 px y 220 px en pantalla de referencia), encaja con `SFX_SNAP` y queda fija; si no, vuelve a la bandeja en 0,4 s con `SFX_REJECT` sin tocar nada más. La solución es la identidad (`P1→S1` … `P5→S5`); `S6` rechaza toda pieza. Al encajar la quinta, el marco de 9 escribe `caja_c1`, emite `EV_PUZZLE_SOLVED_P3` y «compartimento completado» (1), el marco de la foto se ilumina 1,0 s, la tapa se cierra (10) y la nota `I-06a` («La transición es tuya», `NOTA_01`) llega al bolsillo. El único estado que el puzle conserva entre sesiones es su hecho `caja_c1`; las piezas a medias no se guardan (regla 22 de 9).

Tres cosas hacen distinto a este puzle del resto: (1) **la solución exige no hacer algo** —el sexto hueco debe quedarse vacío—, así que el puzle se comprueba como «5 elementos requeridos de 6» y no como «todos los huecos llenos»; (2) **no tiene texto**: sus tres niveles de pista son efectos visuales o de dato (18, D18-1: P3 aporta 0 de las 8 claves `PISTA_*`); (3) **la pieza arrastrada no es un objeto sostenible** del Jugador (D-42 de 2): es un elemento de la vista que sigue al cursor, y el gesto de mano `HAND_PLACE` se aplica sin `sostener`.

## Player Fantasy

Vera tiene delante una foto del equipo hecha pedazos y la recompone con las manos, sin prisa y sin que nadie la juzgue. Al principio es un placer táctil y sencillo —el chasquido de cada pieza, el color que continúa en la pieza vecina—; al final, cuando las cinco piezas están en su sitio y el sexto hueco sigue vacío, el jugador ve por sí mismo que las cinco piezas están en su sitio y que el sexto hueco sigue vacío. Qué significa ese vacío no lo dice nada: ni la nota («La transición es tuya», en letra del Guardián) ni la interfaz lo explican, y la nota admite más de una lectura. (El tono exacto de la silueta de `slot_6` está pendiente de creative-director y narrative-director: Open Question 2.)

Estética principal (MDA): **Sensation** (encaje, sonido, luz del marco al completarse) y **Narrative** (la ausencia como hecho); secundaria: **Discovery** (descubrir que el hueco vacío es el correcto). Necesidades SDT: **Competencia** (el chasquido y la pieza fija dan feedback inmediato; la solución se deduce de forma y color sin pistas), **Autonomía** (las cinco piezas en cualquier orden; el compartimento 1 y el 2 en cualquier orden, regla 24 de 9). Pilares: *Información incompleta* (hecho observable fijo —cinco compañeros, un hueco sin pieza—, intención nunca confirmada), *Tensión sin castigo* (equivocarse cuesta 0,4 s y ningún estado) y *El espacio expresa la emoción* (el vacío se muestra con una silueta y la luz del marco, no con una línea). Emoción objetivo en el arco del slice: el comienzo del tramo «Intimidad y tensión» (Caja, puzles 3–6); un puzle calmado que prepara el peso de los siguientes (P4: decidir si Vera habla por otra persona). En la curva de sierra del marco es el escalón físico y sencillo entre la deducción espacial del P2 y el razonamiento sobre texto del P4.

## Detailed Rules

**Reparto con el marco (9).** 13 posee: la lista de elementos de `D01a`, la geometría de huecos y piezas, la regla de encaje, qué es una colocación correcta, el significado de los tres efectos de pista y la presentación de la resolución (marco iluminado). 9 posee todo lo demás: estado, planificación, bloqueo, hechos, avisos, pistas y su inactividad. El controlador `P3Controller` hereda de `PuzzleController` (regla 9 de 9) y **solo devuelve veredictos** (regla 10 de 9): nunca escribe hechos ni emite avisos.

### A. Elementos y geometría

1. **Elementos de la vista `D01a`.** `elements()` (regla 9 de 9) devuelve, con coordenadas en metros del plano de la vista (origen en el centro del marco, +x a la derecha, +y arriba; ver regla 20 y F1):
   - `D01a/slot_1` … `D01a/slot_6`: los seis huecos, en tres filas y dos columnas (`S1 S2 / S3 S4 / S5 S6`). `atraccion` = verdadero **en los seis por igual** (también `slot_6`: la atracción del mando no debe delatar cuál hueco queda vacío).
   - `D01a/piece_1` … `D01a/piece_5`: las piezas **aún en la bandeja o en el aire**; `atraccion` verdadero. Una pieza ya encajada **sale de `elements()`** (deja de ser seleccionable y de atraer; regla 9) y se dibuja fija en su hueco.
   - Decorado no interactivo (no entra en `elements()`): `D01a/frame` (el marco), `D01a/tray` (la bandeja, parte del compartimento 1: regla 17 de 10) y, tras resolver, `NOTA_01` (lo coloca 10, regla 17 de 10).
   - Nadie más mueve, añade ni quita elementos. Cada vez que cambia una forma o un `z_orden` (pieza agarrada, soltada, encajada) el controlador emite `elements_changed` (regla 9 de 9).
2. **Geometría (†, de datos; F1).** Pitch de los huecos 0,12 m en x y en y: `S1 (−0,06; +0,12)`, `S2 (+0,06; +0,12)`, `S3 (−0,06; 0)`, `S4 (+0,06; 0)`, `S5 (−0,06; −0,12)`, `S6 (+0,06; −0,12)`. Cada hueco es una forma de 0,10 × 0,10 m; cada pieza, de 0,09 × 0,09 m. La bandeja es la zona `x ∈ [0,24; 0,48]`, `y ∈ [−0,19; +0,19]`; las posiciones de reposo de las piezas son `P1 (0,30; +0,12)`, `P2 (0,42; +0,12)`, `P3 (0,30; 0)`, `P4 (0,42; 0)`, `P5 (0,36; −0,12)`. El pitch 0,12 m garantiza la separación mínima de la regla 22 de 7 incluso con el encaje asistido (F1). Las cifras son **propuestas de datos**: el arte y 10 pueden cambiarlas sin tocar reglas si se cumplen las desigualdades de F1 y F1b (regla 29 de 9).
   **Encuadre (D13-16).** El origen de coordenadas es el centro del marco, pero **el centro de la pantalla es `view_center_m` = (0,185; 0)†**, el centro de la caja envolvente de la composición (huecos desde `x = −0,11` hasta la bandeja en `x = 0,48`), no el del marco. La vista sigue a `view_distance_m` = 0,35 m (B.3). Con ese encuadre todo el contenido cabe en 16:9 y en 16:10 con `FOV_v` 70° (F1b); con la vista centrada en el marco, la bandeja y `P2`/`P4` quedarían fuera de pantalla. El desplazamiento lateral lo materializa el anclaje `ANC_D01A` (7 y 10; Cambios requeridos). La conversión de coordenadas de pantalla a metros resta `view_center_m` (F6 de 7); la comprobación de encaje sigue en metros del plano de la vista.
3. **Qué lleva cada pieza y cada hueco (contenido, no valores).** Cada pieza es un trozo de la foto del equipo con **una silueta propia** (una persona) y un contorno de borde que solo encaja en su hueco; el color de la foto continúa en las piezas vecinas. Un hueco sin pista lleva el contorno de borde y el color del trozo que falta; con el nivel 1 de pista muestra además la silueta de su pieza (regla 17). `S6` tiene contorno y color como los demás y, con el nivel 1, **una silueta sin pieza** (no hay ninguna pieza que le corresponda). La foto no contiene texto ni nombre alguno: ningún elemento de la vista dice quién es cada persona ni quién falta (pilar *Información incompleta*). La forma exacta de siluetas, contornos y la paleta son de arte (art bible); **requisito de diseño:** las cinco piezas deben poder asignarse a sus huecos por forma y color sin ninguna pista (slice §19.2).
4. **Solución.** `piece_i → slot_i` para `i = 1…5` (slice B.3). `slot_6` no recibe ninguna pieza. Datos: `solution.map` y `solution.empty` (ver «Datos del puzle»). El mapa es **inyectivo** (a cada hueco, como mucho una pieza).

### B. Gesto de arrastre

5. **Gestos aceptados.** Una pieza en la bandeja acepta `agarrar` (siempre) y `mantener` (solo con el nivel 2 de pista alcanzado, regla 18). Un hueco no acepta ningún gesto. Una pulsación breve sobre una pieza (`seleccionar`) no está aceptada: no hace nada y no cuenta como intento (regla 13 de 9: si no hay veredicto responde el objeto, regla 11 de 7).
6. **Agarrar (ratón y mando por igual).** Los gestos y sus fases son los de 7 y Entrada (`agarrar`: `inicio` → `actualización`… → `fin` o `cancelación`; umbral `d_arrastre` de 8 px). Con **ratón**: pulsar sobre la pieza, mover más de 8 px, soltar. Con **mando**: el cursor virtual (Entrada, F5a) sobre la pieza, mantener el botón de pulsar, mover el stick, soltar el botón; la atracción asistida (Entrada, F5b) opera sobre los elementos con `atraccion` y es la de siempre: 13 no define ninguna atracción propia. **Un solo flujo, sin ramas por dispositivo.** El `elemento` queda fijado al pulsar (regla 21 de 7): la pieza sigue al cursor aunque este salga de ella.
7. **La pieza se centra en el cursor.** En `inicio` el centro de la pieza pasa a la posición del cursor en la vista (`pos_vista`) en `t_centrar_s` = 0,08 s† (instantáneo con `reducir_movimiento`, regla 14b(c) de 9); en `actualización` el centro sigue al cursor (`delta_px` convertido a metros con los ppm de la vista, F6 de 7). Así la comprobación de la regla 10 usa una sola posición (la del cursor) y la atracción del mando, que lleva el cursor al centro del hueco, produce un encaje seguro. El z-orden de la pieza agarrada es el más alto.
8. **Pieza en el aire.** No hay límite de tiempo ni de recorrido: el cursor no sale de la vista (Entrada lo detiene en el borde). La pieza en el aire **no es un objeto sostenible** (D-42 de 2): no hay `sostener`/`soltar`; el gesto de mano `HAND_POINT` durante el arrastre y `HAND_PLACE` (≤ 0,5 s†) al encajar son del Jugador y de 7 (D-25 y `HAND_PLACE` en 2; D7-64 en 7); 13 no pide ni define ningún gesto de mano.
9. **Cancelación.** Ante `cancelación` (cierre de la vista, `atrás`, pausa, pérdida de foco, `cerrar_modos()`; regla 11b de 9) la pieza vuelve **en silencio** a su posición de reposo de la bandeja (instantáneo; sin `SFX_REJECT`, sin evaluar, sin bloqueo). No se pierde ninguna pieza.

### C. Encaje y comprobación

10. **Cuándo se comprueba.** Política `PER_ELEMENT` (regla 12 de 9): solo cuando una pieza **termina** su gesto, es decir, en `fin` de un `agarrar`. No hay comprobación mientras se arrastra ni retraso (`delay_s` no aplica). El controlador calcula, con `c` = la posición del cursor en la vista, `p_i` = el centro del hueco correcto (`slot_i`) y `r` el radio de encaje (regla 11): **encaja** si y solo si `|c − p_i| ≤ r` y `slot_i` está libre. Cualquier otra suelta es un intento fallido (regla 14; la bandeja, regla 12). La distancia es euclídea en el plano de la vista; el borde cuenta como dentro (`≤`).
11. **Radio de encaje.** `r = snap_radius_m` = **0,04 m** (88 px en la vista de referencia) y, con `asistencia_encaje` activo en Ajustes (6), `r = assisted_snap_radius_m` = **0,10 m** (220 px). El controlador lee el ajuste al configurar y al cambiar (regla 14b de 9: el cambio con el puzle activo afecta al **siguiente** intento, no a uno en curso). La conversión a píxeles la hace 7 (F6 de 7; F1 de este GDD); el controlador trabaja en metros.
12. **Soltar en la bandeja (B.3: es un `REJECT` más).** El slice dice «si no encaja, vuelve a la bandeja en 0,4 s (`SFX_REJECT`)» sin excepción para la bandeja, así que **la referencia es que soltar dentro de la zona de la bandeja (regla 2) sin cumplir la regla 10 devuelve `REJECT`**, igual que cualquier otra suelta fallida (regla 14: `SFX_REJECT`, bloqueo `ELEMENT`, vuelta en 0,4 s). El dato `tray_drop_verdict` = `REJECT` lo fija. **Propuesta pendiente de confirmación del usuario (D13-4‡, Open Question 7):** `tray_drop_verdict` = `NONE` (vuelta de 0,4 s sin `SFX_REJECT`, sin bloqueo y sin contar como intento), porque dejar una pieza a propósito no es un error. Hasta que el usuario la confirme, no se implementa. Si el cursor está dentro del radio de encaje de su hueco, **gana el encaje** aunque la bandeja y el radio asistido se solapen (no se solapan con la geometría de la regla 2).
    **Pieza en vuelo de vuelta (A8).** Durante los 0,4 s de vuelta tras un `REJECT` el elemento está bloqueado (regla 14): la entrada sobre esa pieza se descarta (Edge Case 10) y la animación no se interrumpe. Con la propuesta `NONE` no hay bloqueo: un `agarrar` sobre la pieza en vuelo **interrumpe la animación** y la pieza parte de su posición actual hacia el cursor (regla 7). Tras una `cancelación` (regla 9) la vuelta es instantánea y no hay pieza en vuelo.
13. **Encaje.** El veredicto es `PARTIAL` con `progress` = el conjunto de las piezas encajadas (regla 13b de 9: el sonido es solo por la pieza nueva). La pieza se desliza al centro de su hueco en `snap_anim_s` = 0,2 s† (instantáneo con `reducir_movimiento`), se fija, sale de `elements()`, y suena `SFX_SNAP` (0,2 s; `on_partial` de la definición). Una pieza encajada **no se puede volver a coger** (no hay forma de que esté mal puesta: solo encaja en su hueco), de modo que ninguna regla de «deshacer» es necesaria.
14. **Rechazo (`REJECT`).** Una suelta que no cumple la regla 10 —sobre otro hueco, sobre `slot_6`, sobre el marco sin acertar, en la bandeja (regla 12, referencia B.3) o en cualquier punto de la vista— devuelve `REJECT` con la pieza como elemento afectado. Política única del marco (regla 14 de 9), instanciada: `SFX_REJECT` en el mismo fotograma; la pieza vuelve a su reposo de la bandeja en `reset_after_s` = `piece_return_s` = **0,4 s**; `lock: ELEMENT` (solo esa pieza ignora la entrada 0,4 s; **las demás se pueden coger de inmediato**); las piezas ya encajadas y las demás no se tocan; sin temblor (`shake_s` = 0: el movimiento de vuelta es la animación; con `reducir_movimiento` la pieza aparece en la bandeja sin deslizarse, manteniéndose los 0,4 s del bloqueo). No hay contador de fallos, límite de intentos, pérdida de piezas, cambio de dificultad ni consecuencia en la historia (regla 14 de 9; pilar *Tensión sin castigo*).
15. **Un hueco ocupado no acepta otra pieza; `S6` rechaza cualquier pieza** (slice B.3). Con el mapa inyectivo y piezas fijas al encajar, lo primero es estructural (solo `piece_i` encaja en `slot_i` y `piece_i` ya no se puede coger); el controlador lo comprueba igualmente (`slot_i` libre en la regla 10) como defensa frente a datos mal formados. Una suelta sobre `slot_6` es un `REJECT` como cualquier otro: **no existe el estado «hueco 6 lleno»**.
16. **Resolución.** El puzle es `SOLVED` cuando las cinco piezas requeridas (`solution.required`) están encajadas: «5 elementos requeridos de 6» (matriz de encaje de 9). El veredicto `SOLVED` sale de la misma suelta que encaja la quinta pieza y no hay segunda comprobación. **El estado de `slot_6` no interviene**: no se exige «vacío» como condición adicional, porque `slot_6` no puede llenarse (regla 15). A partir de ahí, la regla 16 de 9 se aplica íntegra y en su orden: (1) `caja_c1` = verdadero (único hecho de `on_solved.write`); (2) estado `RESUELTO`; (3) `EV_PUZZLE_SOLVED_P3` con `rewards: [I-06a]`; (4) «compartimento completado» (1); (5) feedback y `play_resolution`; (6) `cerrar_vista(D01a, 'resuelto')` tras `close_view_after_s` = 1,5 s† (F4 de 9). `resolution.kind` = `IMMEDIATE` (nada se difiere ni se interrumpe).
17. **Presentación del acierto (`play_resolution`, no bloqueante).** La quinta pieza se desliza y suena `SFX_SNAP` como las demás (`on_solved.sfx`); a la vez, **el marco se ilumina `frame_lit_s` = 1,0 s** (luz cálida que sube y baja sobre `D01a/frame`; el nivel de luz y su color son de arte y de 28, pilar *El espacio expresa la emoción*), con `slot_6` **vacío e iluminado igual que el resto**, sin resaltarlo ni apagarlo. Con `reducir_movimiento` el marco pasa a la luz final sin transición. 13 no añade sonido propio de resolución (el slice no lo define: B.7). La nota `NOTA_01` aparece sobre la bandeja por el aviso `EV_PUZZLE_SOLVED_P3` (la coloca 10: decorado no interactivo; regla 17 de 10; el cierre es la regla 14 de 10) y el ítem `I-06a` llega al bolsillo (derivado del hecho `caja_c1` por 20). No hay lectura automática de la nota (D20-19, D18-22): se relee con `repasar_bolsillo` (`atrás` en exploración). La tapa se cierra por 10 tras «vista cercana cerrada» (AC-11 de 10).

### D. Pistas (sin texto)

18. **Tres niveles, ninguno con clave de texto** (18, D18-1: P3 no aporta claves `PISTA_*`; la regla 27 de 9 valida los efectos no textuales contra el catálogo). Efectos `AFFORDANCE` (regla 25 de 9) cuyo comportamiento es del controlador:
    - **Nivel 1 (`REQUEST`, `ON_HINT`): `SLOT_SILHOUETTES`.** Cada hueco muestra la silueta de su pieza; `slot_6` muestra una silueta que ninguna pieza lleva. Permanece mientras dure la sesión de la escena (no se persiste).
    - **Nivel 2 (`REQUEST`, `ON_HINT`): `ROW_NUMBER_ON_HOLD`.** Habilita `mantener` (≥ `t_hold` de Entrada, 0,5 s) sobre una pieza de la bandeja: mientras se mantiene pulsado se muestra el número de fila de esa pieza (1 = `S1`/`S2`, 2 = `S3`/`S4`, 3 = `S5`/`S6`; `piece_1`, `piece_2` → 1; `piece_3`, `piece_4` → 2; `piece_5` → 3) sobre la pieza. `mantener` no mueve la pieza ni cuenta como intento. (El slice §10.3 dice «bordes numerados por fila» y B.3 dice a la vez «un número de fila en el borde» (siempre visible) y «mantener `PULSAR` 0,5 s muestra su número de fila» como pista. Un número siempre visible deja sin función al nivel 2, así que son incompatibles: se mantiene el número oculto hasta el nivel 2, que es lo que recoge 18; ver D13-11 y Open Question 8.)
    - **Nivel 3 (`IDLE` 60 s†, `condition: HELD_PIECE`, `idle_reset: GESTURE_AND_MOVE`): `CORRECT_SLOT_OUTLINE`.** Marca con un contorno el hueco correcto de la pieza **en el aire** (`HELD_PIECE` = hay un `agarrar` en curso; F3 de 9). El contorno permanece sobre ese hueco hasta que su pieza encaja (o hasta cerrar la vista) y **nunca** marca `slot_6`. Pedido desde la pausa (sin pieza en el aire), el destino lo decide 9 (regla 25 de 9, esquema v2: el hueco de la pieza más cercana a su sitio o, si no hay ninguna, los huecos libres); 13 solo añade que los huecos libres son los de la regla 19 (sin `slot_6`).
19. **Qué es un «hueco libre» para las pistas.** Solo los huecos con pieza asignada y sin pieza colocada (`slot_1`–`slot_5` sin su pieza). `slot_6` **nunca** es un hueco libre para ningún efecto de pista (de lo contrario una pista marcaría como destino el hueco que debe quedar vacío). Es el único cambio que 13 pide a la regla 25 de 9.
20. **Las pistas son énfasis, nunca información nueva** (regla 27 de 9). Ninguna pista mueve la cámara (regla 14 de 2; D9-32), coloca una pieza ni resuelve un elemento (**no hay `AUTO_SOLVE_ELEMENT` en P3**).

### E. Entrada en la vista, persistencia y reapertura

21. **Acceso.** `ACTIVO` desde el inicio, sin dependencias; el orden respecto a P4 es libre (regla 24 de 9). La apertura de la tapa (`BOX_C1_OPEN`, 1,6 s) y el bloqueo de la cámara a 0,35 m (1,0 s) son de 10 y de 7 (B.3; F1 de 10). Al abrir la vista el controlador muestra las piezas aún no encajadas en sus reposos de la bandeja y las encajadas en sus huecos.
22. **Estado entre aperturas y entre sesiones.** Cerrar la vista **conserva** las piezas encajadas mientras dure la escena (regla 21(b) de 9; AC-26 de 9); cargar una partida o la escena reinicia el puzle vacío, salvo que `caja_c1` sea verdadero, caso en que se restaura el estado final (regla 8 de 9). No hay `persist`: el progreso parcial no se guarda (regla 22 de 9, deliberado: rehacerlo no cuesta nada).
23. **Restauración (`restore_solved_presentation()`).** Con `caja_c1` verdadero al cargar: marco con las cinco piezas en sus huecos y `slot_6` vacío (la imagen que reutiliza la secuencia del P5: B.5), apagado el efecto de «marco iluminado», sin avisos ni sonidos; la tapa en `FINAL_CERRADO` la coloca `set_final_pose(1)` de 10.
24. **Reapertura.** `on_reopen` = `NO_VIEW` (regla 35 de 9): con P3 resuelto, 10 contesta `SIN_EFECTO` con `SFX_CLICK_SUBTLE` y la vista no se abre.
25. **Reloj.** Todo temporizador de este puzle (`snap_anim_s`, `piece_return_s`, `frame_lit_s`, `t_centrar_s`, el umbral de la pista 3) usa el `GameClock` de 9 (regla 36 de 9), de modo que la pausa los detiene.

### F. Qué escribe 9 (y qué no escribe 13)

26. **Escribe 9, no 13:** `caja_c1` (regla 1 de 9: único escritor); el aviso `EV_PUZZLE_SOLVED_P3` y «compartimento completado» (1); «feedback de puzle» con los sonidos; «puzle activado» (no aplica a P3: nace `ACTIVO`); «pista aplicada»; el nivel de pista alcanzado en memoria; el cierre de la vista. **No escribe nadie** estado de piezas: no hay hecho para las piezas del P3 y este GDD no crea ninguno (el catálogo del slice D.2 no cambia).
27. **Lo que 13 entrega al exterior:** a 9, veredictos (`NONE`, `PARTIAL`, `REJECT`, `SOLVED`; nunca `HOLDING`, regla 13 de 9) y los efectos de pista; a 7, `elements()`/`elements_changed` y el tratamiento de gestos; a 10, nada directo (10 reacciona al aviso del marco); a 23, solo los identificadores de sonido por el aviso «feedback de puzle» de 9.

## Formulas

### F1 · Radios de encaje en metros y en píxeles; separación de elementos

`ppm = (H / 2) / (d · tan(FOV_v / 2))`   ·   `r_px = r_m · ppm`   ·   `R(elemento) = min(max(64, tol_px), 128)`   ·   `sep_min = R₁ + R₂`

**Variables:** `H` alto del viewport lógico (1080 de referencia; 1200 en 16:10); `d` = `view_distance_m` = 0,35 m (slice B.3; knob de 9); `FOV_v` = 70° vertical (`fov_vista_deg` de 7, verificación V2 pendiente); `r_m` = `snap_radius_m` 0,04 m o `assisted_snap_radius_m` 0,10 m; `tol_px` = `r_px` del hueco (las piezas no tienen tolerancia de encaje: `tol_px` = 0 ⇒ `R` = 64).
**Output Range:** `ppm` ≈ 2.203 (H = 1080) y 2.448 (H = 1200); `r_px` normal 88 px y asistido 220 px (H = 1080).

**Example (H = 1080):** `tan 35° = 0,70021`; `d · tan = 0,24507`; `ppm = 540 / 0,24507 = 2.203,5`. `r_px` normal = 0,04 · 2.203,5 = 88,1 ≈ **88 px**; asistido = 0,10 · 2.203,5 = 220,4 ≈ **220 px** (coincide con F6 y AC-32 de 7). Con H = 1200: `ppm = 600 / 0,24507 = 2.448` ⇒ 97,9 px y 244,8 px.

**Comprobación de separación (regla 22 de 7; regla 29 de 9), con la geometría de la regla 2:**

| Par | Distancia | R₁ + R₂ normal | R₁ + R₂ asistido | Resultado |
|---|---|---|---|---|
| hueco–hueco (pitch 0,12 m = 264 px) | 264 px | 88 + 88 = **176** | 128 + 128 = **256** | cumple ambos (margen 8 px en el asistido) |
| hueco–hueco en diagonal (0,170 m = 374 px) | 374 px | 176 | 256 | cumple |
| pieza–pieza en la bandeja (≥ 0,12 m = 264 px) | 264 px | 64 + 64 = 128 | 128 | cumple |
| pieza–hueco más próximos (`P3`–`S4`, 0,24 m = 529 px) | 529 px | 64 + 88 = 152 | 64 + 128 = 192 | cumple |
| tamaño mínimo (`pick_min_px` 44 px) | pieza 0,09 m = 198 px; hueco 0,10 m = 220 px | — | — | cumple |

Con ppm < 2.133 (= 256 / 0,12) la separación asistida dejaría de cumplirse (advertencia de validación, no fallo; regla 29 de 9). Con H = 1080 y 16:9 hay un margen de 3 %; si el FOV real fuese otro (V2 de 7) hay que recalcular el pitch: **pitch mínimo** = `256 / ppm`.

### F1b · Encuadre: contenido visible en 16:9 y 16:10

`h_vis = d · tan(FOV_v / 2)`   ·   `w_vis(a) = a · h_vis` (`a` = ancho/alto)   ·   rango visible en x = `[x_c − w_vis, x_c + w_vis]`   ·   `margen = w_vis − max(x_c − x_min, x_max − x_c)`

**Variables:** `d` = 0,35 m; `FOV_v` = 70°; `x_c` = `view_center_m.x`; `x_min` = −0,11 m (borde izquierdo de `slot_1/3/5`: −0,06 − 0,05); `x_max` = 0,48 m (borde de la bandeja; el borde de `P2`/`P4` en reposo es 0,42 + 0,045 = 0,465 m); `a` = 16/9 y 16/10.
**Output Range:** `margen` ≥ 0,09 m (≈ 220 px) en 16:10.

**Example:** `h_vis = 0,35 · 0,70021 = 0,24507` m (semialto). Semianchura: 16:9 → 0,24507 · 1,7778 = **0,4357 m**; 16:10 → 0,24507 · 1,6 = **0,3921 m**. *Sin desplazamiento* (`x_c` = 0): la bandeja (0,48) y `P2`/`P4` (borde 0,465) quedan fuera en ambas, y en 16:10 incluso el centro de `P2`/`P4` (0,42 > 0,392). *Con `x_c` = 0,185* (centro de [−0,11; 0,48]): rango visible 16:9 = [−0,251; 0,621], 16:10 = [−0,207; 0,577]; margen = 0,4357 − 0,295 = **0,141 m** (≈ 311 px a 2.203 ppm) y 0,3921 − 0,295 = **0,097 m** (≈ 237 px a 2.448 ppm). En vertical: el contenido llega a ±0,19 m (bandeja) frente a ±0,245 m visibles (margen 0,055 m ≈ 121 px). Alejar la vista en vez de desplazarla exigiría `d` ≥ (0,48 + 0,03) / (1,6 · 0,70021) = 0,455 m, lo que da ppm ≈ 1.883 y pitch asistido 226 px < 256 px (advertencia permanente de F1): se descarta. `d` = 0,35 m es ≥ `d_ins_min` (0,25 m) y ≤ `d_ins_max` (0,60 m) de 7: no choca con la inspección en mano, que es otro modo y no usa esta vista.


### F2 · Colocaciones necesarias y coste de la fuerza bruta (comprobación del diseño)

`N_col = |solution.required| = 5`   ·   `W_max = Σ_{k=0}^{4} (5 − k) = 15`   ·   `W_med = Σ_{k=0}^{4} (5 − k) / 2 = 7,5`   ·   `T = N_col · t_g + W · (t_g + piece_return_s)`

**Variables:** `k` piezas ya encajadas (0–4); quien prueba a ciegas tiene `6 − k` huecos libres para la siguiente pieza (el suyo y `slot_6` incluidos), así que en el peor caso falla `5 − k` veces antes de acertar; `t_g` = tiempo de un gesto de coger y soltar (1,2 s† con ratón; 2,5 s† con mando); `piece_return_s` = 0,4 s (la pieza no se puede volver a coger durante ese tiempo).
**Output Range:** `N_col` = 5 fijo (no depende de ninguna opción); `W` ∈ [0, 15].

**Example (ratón, `t_g` = 1,2 s):** `T_peor = 5 · 1,2 + 15 · (1,2 + 0,4) = 6 + 24 = 30 s`; `T_media = 6 + 7,5 · 1,6 = 18 s`. **Se acepta:** la fuerza bruta resuelve el puzle en ≤ 30 s, muy por debajo del objetivo de F7 (90–180 s), y eso **no es un exploit**: no hay penalización que eludir ni recompensa que se pierda (el hecho que entrega el puzle —el sexto hueco vacío— se ve igual por cualquier camino). Es la consecuencia directa del pilar *Tensión sin castigo*; el reto es de lectura de forma y color, no de ensayo y error. (Compárese con F6 de 9: P1 ≈ 61 s de media; P4 ≈ 22 s.)

### F3 · Duración esperada de un jugador nuevo, sin pistas (frente a F7 de 9)

`T = t_entrada + t_orient + Σ_{i=1}^{5}(t_buscar_i + t_g) + E · (t_g + piece_return_s) + t_cierre`

**Variables:** `t_entrada` = `BOX_C1_OPEN` 1,6 s + vista de cierre 1,0 s = 2,6 s (F1 de 10); `t_orient` = tiempo de entender la foto y que sobra un hueco (20–40 s†); `t_buscar` = tiempo de localizar el hueco de una pieza (6–15 s†; con mando, la cota alta); `E` = intentos fallidos (3–6†); `t_cierre` = `close_view_after_s` 1,5 s + `t_devolver` 0,5 s = 2,0 s.
**Output Range:** 65–150 s; mediana esperada ≈ 100 s.

**Example:** rápido (`t_orient` 20, `t_buscar` 6, `t_g` 1,2, `E` 3): 2,6 + 20 + 5·7,2 + 3·1,6 + 2,0 = **65,4 s (1,1 min)**. Central (30, 10, 1,6, `E` 4): 2,6 + 30 + 5·11,6 + 4·2,0 + 2,0 = **100,6 s (1,7 min)**. Lento con mando (40, 15, 2,5, `E` 6): 2,6 + 40 + 5·17,5 + 6·2,9 + 2,0 = **149,5 s (2,5 min)**. **Frente a F7 de 9 (1,5–3 min):** la mediana y el extremo lento caen dentro; el extremo rápido (1,1 min) queda por debajo, y es aceptable (F7 es para un jugador nuevo y el slice mide el total con F9). Si la mediana de playtest sale por debajo de 1,5 min **no se endurece el puzle**: es un escalón físico y breve de la sierra de dificultad. Si sale por encima de 3 min, se revisa primero la legibilidad de forma y color (arte) y después se baja `idle_s` del nivel 3 de pista (30–120 s), nunca se añaden fallos.

### F4 · Condición de resolución

`solved = (|placed ∩ required| = |required|)`   con `required = {piece_1 … piece_5}`

**Variables:** `placed` = conjunto de piezas encajadas; `required` = `solution.required`. El estado de `slot_6` no interviene (regla 16).
**Output Range:** booleano; `|placed|` ∈ [0, 5] y **no puede superar 5** (no hay sexta pieza).
**Example:** con 4 piezas encajadas y la quinta suelta dentro de 0,04 m de `slot_5`: `|placed|` = 5 ⇒ `SOLVED` en ese fotograma; soltada la misma pieza sobre `slot_6` ⇒ `REJECT`, `|placed|` sigue en 4.

### F5 · Línea temporal de la resolución (en reloj de juego, `t = 0` en la suelta de la quinta pieza)

`0` suelta → `0 … snap_anim_s (0,2)` desliz + `SFX_SNAP` → `0 … frame_lit_s (1,0)` marco iluminado → `close_view_after_s (1,5)` petición `cerrar_vista(D01a, 'resuelto')` → `+ t_devolver (0,5)` cámara de vuelta (**2,0 s**) → `close_delay_s` de 10 → `BOX_C1_CLOSE` (0,8 s†)

**Variables:** `frame_lit_s` 1,0 s (slice B.3); `close_view_after_s` 1,5 s† (F4 de 9); `t_devolver` 0,5 s (regla 18 de 2); `close_delay_s` y `BOX_C1_CLOSE` son de 10 (F4 de 10).
**Example:** hechos (`caja_c1`, avisos) en `t = 0`; la nota `NOTA_01` es visible desde `t ≈ 0` y 10 la mantiene hasta que la tapa se cierra (en la vista, **≈ 1,5 s** hasta la petición de cierre, con la tapa cerrándose después); la restauración tras cargar es instantánea. El marco ilumina 1,0 s < 1,5 s: la luz termina antes de que la vista se cierre.

## Edge Cases

Cada caso dice qué ocurre; ninguno castiga ni bloquea (S1–S9 de la regla 28 de 9).

1. **Pieza soltada fuera del marco** (sobre el fondo de la vista): `REJECT` como cualquier encaje fallido (regla 14): `SFX_REJECT`, la pieza vuelve a su reposo en 0,4 s, solo ella queda bloqueada 0,4 s.
2. **Pieza soltada en la bandeja:** como B.3, `REJECT` con `SFX_REJECT`, bloqueo `ELEMENT` y vuelta en 0,4 s (regla 12); cuenta como intento fallido para la instrumentación (regla 32 de 9). Con la propuesta D13-4‡ (`NONE`) sería una vuelta silenciosa, sin bloqueo y sin contar.
3. **Pieza soltada sobre un hueco que no es el suyo (incluido `slot_6`):** `REJECT` (reglas 14 y 15). `slot_6` no se llena nunca: el puzle no puede quedar en un estado «hueco 6 lleno».
4. **Dos piezas encajadas en el mismo hueco:** imposible por construcción (el mapa de la solución es inyectivo, regla 4; una pieza solo encaja en su hueco; una pieza encajada no se vuelve a coger). Defensa en profundidad: la regla 10 exige el hueco libre, y un `solution.map` no inyectivo es un error de datos que la prueba de datos de este puzle (AC-14) detecta en desarrollo.
5. **Cierre de la vista con piezas colocadas** (`atrás`, cierre forzado, salir a explorar): las piezas encajadas se conservan mientras dure la escena (regla 22); una pieza en el aire recibe `cancelación` y vuelve en silencio a la bandeja (regla 9). Al volver a abrir la vista el puzle sigue donde estaba.
6. **Cierre del juego o carga con piezas a medias:** el progreso parcial se pierde y el puzle empieza vacío (reglas 22 de 9 y D-2 de 5): rehacerlo no cuesta nada y no hay pérdida de un hecho. Con `caja_c1` verdadero se restaura el estado final (regla 23).
7. **Mando sin cursor visible** (al abrir la vista, tras una lectura apilada o un cambio de dispositivo): Entrada coloca el cursor virtual en su posición inicial o restaurada y lo hace visible (7: «el cursor se oculta y su posición se restaura»); mientras el cursor no esté en la vista, `agarrar` no puede iniciarse. **Mando con la atracción asistida desactivada** (ajuste de Entrada): el jugador debe colocar el cursor a mano; con 0,04 m (88 px) puede resultar exigente, y por eso `asistencia_encaje` (0,10 m) es independiente de la atracción: se puede activar solo el radio, solo la atracción, ambos o ninguno.
8. **El jugador cambia `asistencia_encaje` con una pieza en el aire:** afecta al **siguiente** intento, no al que está en curso (regla 14b de 9; regla 11).
9. **Suelta exactamente en el borde del radio (`|c − p_i| = r`):** encaja (`≤`). Las comparaciones se hacen en metros con una tolerancia numérica de 1e-6 m, no en píxeles, para que el resultado no dependa de la resolución.
10. **Pulsar o arrastrar una pieza durante su bloqueo de 0,4 s:** los eventos de ese elemento se **descartan** (no se encolan; regla 14 de 9); las demás piezas funcionan. Quinta pieza y bloqueo: solo puede estar bloqueada la pieza que acaba de rechazarse, y es la única que falta cuando quedan cuatro encajadas, de modo que no existe el caso «quinta pieza encajada mientras otra está bloqueada».
11. **Pausa o `atrás` durante la animación de encaje (0,2 s) o de vuelta (0,4 s):** el estado cambió en el fotograma de la suelta; la animación se completa al instante al volver (regla 21(b) de 9). La quinta pieza ya cuenta como encajada: si el jugador sale con `atrás` en ese instante, el puzle queda `RESUELTO` y 10 cierra la tapa (AC-32 de 10).
12. **Pista de nivel 3 con la mano vacía a los 60 s:** el umbral vence y no se consume; al agarrar una pieza el contorno aparece en ese momento (F3 de 9). **Pedida desde la pausa:** el destino lo decide 9 (regla 18 y regla 25 de 9) y **nunca** es `slot_6` (regla 19).
13. **Pistas pedidas con el puzle resuelto:** `request_hint` valida que el puzle esté `ACTIVO` (regla 26 de 9) y no hace nada; con la vista cerrada y el puzle `ACTIVO`, el efecto se aplica al estado y se ve al abrir la vista.
14. **El jugador resuelve el P4 antes o después que el P3, o abre el P3 sin haber resuelto nada más:** válido; no hay dependencias entre los dos (regla 24 de 9; edge case 18 de 10).
15. **El jugador no entiende que sobra un hueco y prueba cada pieza en `slot_6`:** cada intento es un `REJECT` de 0,4 s; el nivel 1 de pista (silueta sin pieza en `slot_6`) lo muestra. Nada lo cuenta ni lo penaliza.
16. **`reducir_movimiento` activo:** el centrado, el encaje, la vuelta a la bandeja y la luz del marco son cambios instantáneos; los tiempos de bloqueo (0,4 s), de iluminación (1,0 s) y de cierre (1,5 s) **no cambian** (regla 14b de 9).
17. **Resolución de pantalla distinta de 1080p o relación 16:10:** `r_px` depende de `H` (F1); la comprobación de encaje se hace en metros, así que el comportamiento no cambia; solo la advertencia de separación se recalcula (F1). Con el encuadre de la regla 2 (`view_center_m` = 0,185 m, F1b) todo el contenido cabe en 16:9 (margen 0,141 m) y en 16:10 (0,097 m); en relaciones más estrechas que 16:10 (4:3 → semianchura 0,327 m, margen 0,032 m) cabe con poco margen, y por debajo de ≈ 1,2:1 (semianchura < 0,295 m) la bandeja recortaría: el aspecto mínimo soportado (16:10 en el slice) se confirma con 7, y si hiciera falta menos se ajusta `view_distance_m` o `view_center_m`, nunca el radio de encaje.
18. **Agarrar una pieza durante su vuelta de 0,4 s (A8):** tras `REJECT` (referencia B.3) la pieza está bloqueada y la entrada se descarta (edge 10), sin interrumpir la animación; con la propuesta `NONE` (D13-4‡) un `agarrar` interrumpe la vuelta y la pieza parte de donde esté. Tras `cancelación` no hay vuelo (vuelta instantánea).
19. **Degenerate strategies (Sirlin).** (a) *Fuerza bruta*: ≤ 30 s (F2); se acepta (pilar *Tensión sin castigo*; no hay recompensa que perder). (b) *Soltar todo en el centro del marco* (0; 0) (el centro del marco ya no es el centro de pantalla, regla 2), a 0,06 m de `S3` y de `S4`: con el radio normal (0,04 m) no encaja nada; con `asistencia_encaje` (0,10 m) encajan solo `piece_3` y `piece_4`, cada una en su hueco (solo cuenta el hueco propio), lo cual es inocuo y es precisamente la generosidad que ese ajuste promete; el resto de piezas sigue exigiendo acercarse a su hueco (≥ 0,12 m del centro de los demás huecos, regla 2). (c) *Arrastrar sin mirar fijándose en el sonido*: `SFX_SNAP` frente a `SFX_REJECT` es una señal de acierto legible, no una vía de deducción de `slot_6` (el rechazo de `slot_6` suena igual que cualquier otro).

## Dependencies

**Dureza declarada por el dependiente** (convención del índice): cada fila dice qué necesita *13* de él (13 depende) o qué necesita *él* de 13 (dependiente). Todas las filas deben aparecer también en el GDD del otro sistema (Cambios requeridos).

| Sistema | Dirección | Dureza (la declara el dependiente) | Qué fluye | Contrato / reglas |
|---|---|---|---|---|
| 9 Marco de puzles | 13 depende de 9 | **Dura** (declara 13: sin el marco no hay estado, hechos, pistas ni fallo) | 9 → 13: definición `P3` de `puzzles.json`, gestos (`handle_pointer`), `cancel_gesture`, `request_hint` → `apply_hint_effect`, restauración. 13 → 9: `elements()`, `elements_changed`, veredictos (`NONE`, `PARTIAL`, `REJECT`, `SOLVED`) | Reglas 4, 9–14, 16, 21, 22, 24–27 de 9 |
| 10 Caja y compartimentos | 13 depende de 10 | **Dura** (declara 13: `D01a` y su apertura, la bandeja y el cierre los pone 10) | 10 → 13: vista `D01a`, bandeja (parte del compartimento 1, regla 17 de 10), `set_final_pose(1)`, `NOTA_01`. 13 → 10: nada directo; 10 reacciona al aviso de 9 | Reglas 9, 14 y 17 de 10; F1 y F4 de 10; AC-11, AC-23 y AC-32 de 10 |
| 6 Ajustes persistentes | 13 depende de 6 | **Blanda** (declara 13: sin ajuste el radio es 0,04 m) | 6 → 13 (vía 9): `asistencia_encaje` (bool, falso) y `reducir_movimiento`; se leen al configurar y al cambiar | `asistencia_encaje` en 6 («13 Puzle 3»); regla 14b de 9 |
| 7 Interacción e inspección | 13 depende de 7 (transitivo, vía 9) | **Dura** (declara 13: cursor, picking, `agarrar`/`mantener`, conversión metros ↔ px) | 7 → 13 (vía 9): `PointerEvent` y sus fases; F6 (ppm); regla 22 (tamaños y separación); `atraccion_desactivada` (no usado). 13 → 7: `elements()` | Reglas 20–22 de 7; F5b y F6 de Entrada y de 7; el anclaje `ANC_D01A` desplazado a `view_center_m` (regla 2) |
| 2 Jugador | 13 depende de 2 (transitivo, vía 7) | **Blanda** (declara 13: solo la presentación de manos) | 2 → 13: `HAND_POINT` y `HAND_PLACE` los reproduce 7 por 2; la pieza arrastrada **no** es sostenible (D-42), sin `sostener`; el regreso de cámara `t_devolver` 0,5 s | D-25, D-42 de 2; AC-32 y AC-47 de 2 |
| 18 Base de contenido | 13 depende de 18 | **Blanda** (declara 13: P3 no tiene texto; solo la validación de 9 lee 18) | 18 → 13: nada; 18 declara que P3 N1–N3 son efectos no textuales (0 claves `PISTA_*`) | D18-1; tabla de pistas de 18 |
| 20 Documentos y bolsillo | 20 depende de 13 (vía el hecho `caja_c1`) | **Dura** (declara 20: `I-06a` se deriva del hecho) | 13/9 → 20: `caja_c1` y `rewards: [I-06a]` informativos; 20 → 13: nada | R8 de 20; D20-19 |
| 3 Estado y bus | 13 depende de 3 (vía 9) | **Dura** (declara 9) | 9 → 3: escribe `caja_c1` y emite avisos; 13 no lee ni escribe hechos | Regla 1 de 9 |
| 5 Guardado y carga | 5 depende del hecho de 13 | **Dura** (declara 5) | `compartment_done:1` y `puzzle_solved:P3`; el progreso parcial no se guarda | D-2 de 5; regla 22 de 9 |
| 17 Sistema de pistas ‡ | 17 depende de 13 (vía 9) | **Blanda** (declara 17: sin 17, 9 aplica el nivel 3 de `IDLE`) | 9 → 13: `apply_hint_effect` (tres `AFFORDANCE`) | Reglas 25–27 de 9 |
| 23 Director de audio ‡ | 23 depende de 13 (vía 9) | **Blanda** (declara 23) | «feedback de puzle» con `SFX_SNAP` y `SFX_REJECT` | Regla 13 de 9; B.7 del slice |
| 28 Atmósfera · 29 Shaders | 28 depende de 13 (vía 9) | **Blanda** (declara 28) | Aviso de resolución: la luz del marco iluminado (1,0 s) | Regla 17 de este GDD |

**Dependencia circular:** ninguna. 13 no lee ni escribe estado; todo pasa por 9.

## Tuning Knobs

Todos los valores viven en datos (`assets/data/puzzles/puzzles.json` para los de 9 y 13; regla 29 de 9), nunca en el controlador. **Propietario** = quien define el valor; 13 solo lo referencia cuando el propietario es 9 (ver Cambios requeridos si falta en su Tuning Knobs). † = a validar en playtest.

| Knob | Cat. | Defecto | Rango seguro | Propietario | Qué afecta y por qué ese valor |
|---|---|---|---|---|---|
| `snap_radius_m` | Feel | 0,04 m (88 px) | 0,03–0,06 | 9 (slice B.3) | Exigencia de precisión del encaje; 88 px es un objetivo cómodo con ratón. Menos de 0,03 m frustra; más de 0,06 m quita lectura |
| `assisted_snap_radius_m` | Feel (accesibilidad) | 0,10 m (220 px) | 0,06–0,15 | 9 (slice B.3) | Radio con `asistencia_encaje`. Debe mantenerse `< 0,18 m` para no entrar en la bandeja (regla 12) |
| `piece_return_s` | Feel | 0,4 s | 0,2–1,0 | 9 (fila `piece_return_s` de su Tuning Knobs) | Vuelta de la pieza = bloqueo `ELEMENT`; `≤ lock_max_s` (2,0 s) |
| `frame_lit_s` | Feel | 1,0 s | 0,5–2,0 | 9 | Luz del marco al resolver |
| `view_distance_m` | Feel | 0,35 m | 0,25–0,5 | 9 (y 7) | Entra en `ppm` (F1) y en el encuadre (F1b): cambiarlo cambia los px de encaje, la separación mínima y la semianchura visible |
| `close_view_after_s` | Gate | 1,5 s† | 0,5–3,0 | 9 | Cuánto se ve la nota y el marco antes de cerrar la vista |
| `idle_s` N3 | Gate | 60 s† | 30–120 | 9 (registro: `idle_s_P3_N3`) | Cuándo aparece el contorno sin pedirlo |
| `idle_move_px_P3` | Feel | 40 px† | 16–120 | 9 (registro) | Zona muerta del movimiento para la inactividad |
| `t_hold` (nivel 2) | Feel | 0,5 s | 0,3–1,0 (hasta 1,5 en accesibilidad) | 1 Entrada (F6) | Pulsación sostenida para ver el número de fila |
| `slot_pitch_m` | Curve | 0,12 m | 0,12–0,16 (mínimo = `256 / ppm`, F1) | **13** | Separación de huecos: ≥ 0,1162 m para no advertir con el encaje asistido; máx. por el alto de la vista (F1) |
| `slot_size_m` / `piece_size_m` | Feel | 0,10 / 0,09 m | 0,08–0,11 / 0,07–0,10 | **13** (arte puede cambiarlo) | Tamaño legible; ≥ `pick_min_px` (44 px) |
| `tray_rect_m` y `piece_rest_m[5]` | Curve | ver regla 2 | separación pieza–pieza ≥ 0,06 m | **13** | Posiciones de la bandeja; sin solape con el radio asistido de ningún hueco |
| `snap_anim_s` | Feel | 0,2 s† | 0,1–0,4 | **13** | Deslizamiento al hueco (coincide con `SFX_SNAP` 0,2 s) |
| `t_centrar_s` | Feel | 0,08 s† | 0–0,15 | **13** | Centrado de la pieza en el cursor al agarrar (regla 7) |
| `view_center_m` | Curve | (0,185; 0)† | x ∈ [0,15; 0,22] (margen ≥ 0,05 m en 16:10, F1b) | **13** (lo materializa `ANC_D01A` de 7/10) | Centro de pantalla en coordenadas del marco; con 0 la bandeja queda fuera de pantalla |
| `tray_drop_verdict` | Feel | `REJECT` (B.3) | `REJECT` / `NONE` | **13** (decisión del usuario pendiente: D13-4‡) | Qué devuelve soltar una pieza en la bandeja |

**Interacciones entre knobs:** `slot_pitch_m` × `view_distance_m` fijan los píxeles (F1); subir `assisted_snap_radius_m` por encima de ~0,12 m hace que dos radios asistidos se solapen (inocuo, solo cuenta el hueco propio) pero el tope `R = 128` de la atracción mantiene la separación en 256 px. `piece_return_s` mayor de 1,0 s empieza a sentirse castigo (pilar 4).

## Acceptance Criteria

Tipos: **L** = lógica (prueba automática, `tests/unit/puzzle_3/`, reloj falso de la regla 36 de 9), **I** = integración (`tests/integration/puzzle_3/`), **PV** = playtest o verificación visual (captura retenida en `production/qa/evidence/`).

**Encaje y fallo**
- **AC-01 (R10, R11, F1, L):** **GIVEN** `asistencia_encaje` falso y la pieza `piece_2` agarrada, **WHEN** se suelta con el cursor a 0,039 m del centro de `slot_2`, **THEN** `PARTIAL` (encaja); **WHEN** a 0,041 m, **THEN** `REJECT`. **GIVEN** `asistencia_encaje` verdadero, **THEN** a 0,099 m encaja y a 0,101 m no (marco AC-08). A exactamente 0,040 m encaja (`≤`, ε = 1e-6 m).
- **AC-02 (F1, L):** **GIVEN** H = 1080, `d` = 0,35 m y FOV_v = 70°, **THEN** `ppm` = 2.203 (±1), 0,04 m = 88 px (±0,5) y 0,10 m = 220 px (±0,5); **GIVEN** H = 1200, `ppm` = 2.448 (±1) (AC-32 de 7).
- **AC-03 (R13, L):** **GIVEN** una pieza soltada dentro del radio de su hueco, **THEN** el veredicto es `PARTIAL` con `progress` = piezas encajadas, `SFX_SNAP` suena una vez, la pieza queda en el centro de su hueco, sale de `elements()` y un nuevo `agarrar` sobre ella no la mueve.
- **AC-04 (R14, L):** **GIVEN** una pieza soltada fuera del radio de su hueco (en cualquier punto, bandeja incluida), **THEN** `REJECT` y `SFX_REJECT` en el mismo fotograma; la pieza vuelve a la bandeja a los 0,4 s; durante esos 0,4 s solo esa pieza ignora la entrada y otra pieza se puede agarrar; las piezas encajadas no cambian; no existe contador de fallos ni estado nuevo (inspección del estado del controlador).
- **AC-05 (R12, L):** **GIVEN** `tray_drop_verdict` = `REJECT` (referencia B.3) y una pieza soltada con el cursor dentro de la bandeja, **THEN** `REJECT`, `SFX_REJECT`, bloqueo `ELEMENT` y vuelta a su reposo en 0,4 s, igual que AC-04; **GIVEN** la propuesta D13-4‡ (`tray_drop_verdict` = `NONE`, solo si el usuario la confirma), **THEN** `NONE`, sin sonido, sin bloqueo y vuelta en 0,4 s. **GIVEN** el cursor dentro del radio de su hueco, **THEN** gana el encaje en ambos casos.
- **AC-06 (R15, L):** **GIVEN** las cinco piezas y todos los huecos incorrectos (cada pieza sobre cada uno de los otros cuatro huecos y sobre `slot_6`: 25 combinaciones), **THEN** las 25 devuelven `REJECT`, `slot_6` nunca queda ocupado y `|placed|` no cambia.
- **AC-07 (R16, F4, L):** **GIVEN** cuatro piezas encajadas, **WHEN** se encaja la quinta, **THEN** el veredicto es `SOLVED` en ese fotograma y, en este orden: `caja_c1` = verdadero, estado `RESUELTO`, `EV_PUZZLE_SOLVED_P3` con `rewards: [I-06a]`, «compartimento completado» (1); `slot_6` sigue vacío y no se consulta.
- **AC-08 (R16, L):** **GIVEN** las 120 permutaciones del orden de colocación de las cinco piezas, **THEN** en todas el `SOLVED` llega solo con la quinta y no antes.
- **AC-09 (R9, L):** **GIVEN** una pieza en el aire, **WHEN** llega `cancelación` (`atrás`, pausa, pérdida de foco, `cerrar_modos()`), **THEN** la pieza vuelve a la bandeja sin sonido, sin `REJECT` y sin evaluar (marco AC-45).

**Entrada, mando y geometría**
- **AC-10 (R7, R10, L):** **GIVEN** un `agarrar` con `inicio` en `pos_vista` = (0,30; 0,12), **THEN** el centro de la pieza pasa al cursor en 0,08 s (instantáneo con `reducir_movimiento`) y la comprobación usa la posición del cursor. **GIVEN** el mando con atracción asistida activa y el cursor atraído al centro de `slot_3` con `piece_3` agarrada, **THEN** encaja con el radio normal.
- **AC-11 (R1, L):** **GIVEN** la vista abierta con dos piezas encajadas, **THEN** `elements()` contiene seis huecos (`atraccion` verdadero en los seis, incluido `slot_6`) y tres piezas con `atraccion` verdadero, y no contiene las encajadas; **WHEN** una pieza se agarra, se suelta o encaja, **THEN** se emite `elements_changed`.
- **AC-12 (F1, R2, L):** **GIVEN** la geometría por defecto, **THEN** la validación de separación (regla 29 de 9) no da fallo ni advertencia con H = 1080 (hueco–hueco 264 px ≥ 256 px asistido); **GIVEN** `slot_pitch_m` = 0,11 m, **THEN** advertencia con la tolerancia asistida y ningún fallo (264 → 242 px ≥ 176 px normal); **GIVEN** `slot_pitch_m` = 0,07 m (154 px < 176 px) sin `atraccion_desactivada`, **THEN** fallo de arranque.
- **AC-13 (R2, L):** **GIVEN** el radio asistido (0,10 m) y los centros de los seis huecos, **THEN** ningún punto a ≤ 0,10 m de un hueco está dentro de la bandeja (`x ≥ 0,24`).

**Datos**
- **AC-14 (R4, L):** **GIVEN** la entrada `P3` de «Datos del puzle», **THEN** pasa la validación de 9 (regla 29: `view` en el catálogo de 7, `solved_flag` = `caja_c1` en `flags.json`, `requires.all` vacío, tres pistas, ningún `reset_after_s` > `lock_max_s`, estado inicial que no satisface la solución); y **GIVEN** una variante con `solution.map` no inyectivo o con `required` ≠ 5 elementos, **THEN** el controlador falla la validación de datos (desarrollo: error visible).

**Pistas**
- **AC-15 (R18, L/PV):** **GIVEN** `request_hint(P3, 1)`, **THEN** los seis huecos muestran su silueta y `slot_6` una silueta sin pieza; **GIVEN** el nivel 2 alcanzado, **WHEN** se mantiene 0,5 s una pieza, **THEN** se muestra su número de fila (1, 1, 2, 2, 3 para `piece_1`…`piece_5`) mientras se mantiene y la pieza no se mueve ni cuenta como intento; **GIVEN** el nivel 2 no alcanzado, **THEN** `mantener` no tiene efecto; **GIVEN** 60 s sin acción (ruido < 40 px) con una pieza en el aire, **THEN** el hueco correcto de esa pieza queda contorneado hasta que encaja (marco AC-32).
- **AC-16 (R19, L):** **GIVEN** cualquier estado y `request_hint(P3, 3)` desde la pausa (sin pieza en el aire), **THEN** el contorno lo coloca 9 según su regla 25 (hueco de la pieza más cercana a su sitio o, si no hay ninguna, los huecos libres) y **nunca** en `slot_6`; con las cinco piezas encajadas el puzle está `RESUELTO` y la petición no hace nada.
- **AC-17 (R20, L):** **GIVEN** cualquier combinación de pistas, **THEN** ninguna mueve la cámara, coloca una pieza ni resuelve un elemento, y el puzle sigue siendo resoluble (solucionador de referencia de la regla 30 de 9, 1.000 secuencias aleatorias con pistas, cancelaciones, cierres/reaperturas y guardar/cargar).

**Persistencia y presentación**
- **AC-18 (R22, I):** **GIVEN** tres piezas encajadas, **WHEN** se cierra y reabre la vista, **THEN** las tres siguen; **WHEN** se carga la escena, **THEN** empieza vacío (marco AC-26).
- **AC-19 (R23, R24, I):** **GIVEN** `caja_c1` verdadero al cargar, **THEN** P3 está `RESUELTO` con las cinco piezas y `slot_6` vacío, sin `EV_PUZZLE_SOLVED_P3`, sin «compartimento completado» y sin sonidos (marco AC-02); **WHEN** el jugador pulsa `D01a`, **THEN** `SIN_EFECTO` con `SFX_CLICK_SUBTLE` y la vista no se abre (AC-23 de 10).
- **AC-20 (R14, R25, L):** **GIVEN** `reducir_movimiento` activo, **THEN** el centrado, el encaje, la vuelta y la luz del marco son instantáneos y los bloqueos (0,4 s), la iluminación (1,0 s) y el cierre (1,5 s) conservan su duración; **GIVEN** la pausa durante los 0,4 s de bloqueo, **THEN** el bloqueo no avanza (reloj falso).
- **AC-21 (R17, F5, PV):** captura retenida de la vista en el instante del marco iluminado, con `slot_6` vacío e iluminado igual que el resto y `NOTA_01` visible sobre la bandeja; ≥ 1,5 s de vista tras resolver hasta la petición de cierre.
- **AC-22 (R8, R14, I):** **GIVEN** un arrastre y un encaje completos, **THEN** el Jugador reproduce `HAND_POINT` y `HAND_PLACE` sin ningún `sostener` ni `soltar` y la lista de objetos sostenibles sigue siendo solo `V05` (AC-32 y AC-47 de 2).

- **AC-27 (R2, F1b, L/PV):** **GIVEN** `view_center_m` = (0,185; 0), `d` = 0,35 m, `FOV_v` = 70° y viewports 1920×1080 y 1920×1200, **THEN** los bordes de los seis huecos, de la bandeja (`x` = 0,48) y de `P2`/`P4` en reposo (`x` = 0,465) caen dentro del viewport con margen ≥ 0,09 m (≈ 220 px) en horizontal y ≥ 0,05 m en vertical; captura retenida de ambas relaciones con las cinco piezas en la bandeja. **GIVEN** `view_center_m` = (0; 0), **THEN** la validación debe fallar (la bandeja queda fuera).
- **AC-28 (R12, edge 18, L):** **GIVEN** una pieza en vuelo de vuelta tras un `REJECT`, **WHEN** el jugador pulsa y arrastra sobre ella, **THEN** el evento se descarta y la animación termina en 0,4 s; **GIVEN** la propuesta `NONE` (D13-4‡), **THEN** el `agarrar` interrumpe la vuelta y la pieza parte de su posición actual hacia el cursor; **GIVEN** `cancelación`, **THEN** la pieza ya está en reposo.

**Experienciales (playtest; F7 y F2)**
- **AC-23 (F3, PV):** con 5 jugadores nuevos, mediana de tiempo de resolución sin pistas dentro de 1,5–3 min (F7 de 9) y **ninguno** pierde una pieza ni queda sin salida (AC-38 de 9); si la mediana < 1,5 min no se cambia nada (F3).
- **AC-24 (R3, PV):** **GIVEN** la vista sin pistas, **THEN** al menos 4 de 5 jugadores asignan las cinco piezas por forma y color sin pedir el nivel 1 (slice §19.2).
- **AC-25 (R17, PV; condicionado al resultado de Open Question 2 sobre la silueta de `slot_6`):** al terminar, al menos 3 de 5 jugadores, preguntados «¿qué ves en la foto?» sin sugerir nada, mencionan por sí mismos el hueco vacío o que falta alguien; **ninguno** describe el puzle como castigador o confuso como única descripción (§19.4). La pregunta nunca sugiere quién falta (pilar *Información incompleta*).
- **AC-26 (R6, PV):** el puzle se completa con teclado y ratón, con mando con y sin atracción asistida, y con `asistencia_encaje` activado y desactivado, sin pasos fuera del flujo único de la regla 6.

## Datos del puzle

Entrada de `assets/data/puzzles/puzzles.json` según el esquema de la regla 4 de 9 (todo valor numérico aquí; ninguno en el controlador). `on_partial`, `availability`, `condition` e `idle_reset` ya los admite el esquema v2 de 9 (regla 13, regla 25 y F3 de 9) y aquí solo se usan. Lo nuevo que 13 aporta es: el `id` de cada `AFFORDANCE` y su catálogo, `idle_move_px` por puzle, `frame_lit_s` en `on_solved`, `row` por pieza, `tray_drop_verdict`, `view_center_m` y `solution.slots/pieces/tray_rect_m/empty` (la regla 4 de 9 deja a `solution` datos que solo interpreta el controlador). `snap_radius_m` y `view_distance_m` son knobs de 9 cuya ubicación el esquema no fija: aquí van en `solution` (‡, a confirmar con 9); `piece_return_s` es `reset_after_s` de `on_reject`.

```json
{
  "id": "P3", "mode": "VIEW", "view": "D01a",
  "solved_flag": "caja_c1",
  "requires": { "all": [] },
  "validation": { "policy": "PER_ELEMENT" },
  "solution": {
    "required": ["D01a/piece_1", "D01a/piece_2", "D01a/piece_3", "D01a/piece_4", "D01a/piece_5"],
    "map": {
      "D01a/piece_1": "D01a/slot_1", "D01a/piece_2": "D01a/slot_2", "D01a/piece_3": "D01a/slot_3",
      "D01a/piece_4": "D01a/slot_4", "D01a/piece_5": "D01a/slot_5"
    },
    "empty": ["D01a/slot_6"],
    "snap_radius_m": 0.04,
    "view_distance_m": 0.35, "view_center_m": [0.185, 0.0],
    "tray_drop_verdict": "REJECT",
    "snap_anim_s": 0.2, "t_centrar_s": 0.08,
    "slots": {
      "D01a/slot_1": { "center_m": [-0.06,  0.12], "size_m": 0.10 },
      "D01a/slot_2": { "center_m": [ 0.06,  0.12], "size_m": 0.10 },
      "D01a/slot_3": { "center_m": [-0.06,  0.00], "size_m": 0.10 },
      "D01a/slot_4": { "center_m": [ 0.06,  0.00], "size_m": 0.10 },
      "D01a/slot_5": { "center_m": [-0.06, -0.12], "size_m": 0.10 },
      "D01a/slot_6": { "center_m": [ 0.06, -0.12], "size_m": 0.10 }
    },
    "pieces": {
      "D01a/piece_1": { "rest_m": [0.30,  0.12], "size_m": 0.09, "row": 1 },
      "D01a/piece_2": { "rest_m": [0.42,  0.12], "size_m": 0.09, "row": 1 },
      "D01a/piece_3": { "rest_m": [0.30,  0.00], "size_m": 0.09, "row": 2 },
      "D01a/piece_4": { "rest_m": [0.42,  0.00], "size_m": 0.09, "row": 2 },
      "D01a/piece_5": { "rest_m": [0.36, -0.12], "size_m": 0.09, "row": 3 }
    },
    "tray_rect_m": [0.24, -0.19, 0.48, 0.19]
  },
  "assist": { "setting": "asistencia_encaje", "snap_radius_m": 0.10 },
  "atraccion_desactivada": false,
  "idle_reset": "GESTURE_AND_MOVE", "idle_move_px": 40,
  "on_partial": { "sfx": "SFX_SNAP", "sfx_s": 0.2 },
  "on_reject": { "sfx": "SFX_REJECT", "shake_s": 0, "reset_after_s": 0.4, "lock": "ELEMENT" },
  "on_solved": {
    "write": [{ "flag": "caja_c1", "value": true }],
    "compartment": 1,
    "sfx": "SFX_SNAP", "sfx_s": 0.2,
    "frame_lit_s": 1.0,
    "rewards": ["I-06a"],
    "close_view_after_s": 1.5
  },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "IMMEDIATE" },
  "hints": [
    { "level": 1, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [{ "type": "AFFORDANCE", "id": "SLOT_SILHOUETTES" }] },
    { "level": 2, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [{ "type": "AFFORDANCE", "id": "ROW_NUMBER_ON_HOLD" }] },
    { "level": 3, "trigger": "IDLE", "idle_s": 60, "condition": "HELD_PIECE", "availability": "ON_HINT",
      "effects": [{ "type": "AFFORDANCE", "id": "CORRECT_SLOT_OUTLINE" }] }
  ]
}
```

Sin `persist` (ningún hecho intermedio), sin `needs_items` (el puzle no necesita ítems), sin `on_unlock` (nace `ACTIVO`) y sin `TEXT` en las pistas (0 claves `PISTA_*`).

## Decisiones tomadas

Modo por lotes autónomo (2026-11-09): decididas con la recomendación propia; ninguna cambia pilares, tono ni alcance del slice. IDs `D13-n`.

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D13-1 | El hecho del puzle es **`caja_c1`** (D.2 del slice y regla 1 de 9); P5 lo requiere (`caja_c3` es de P5) | Usar `caja_c3` (como figuraba en el encargo) | El slice D.2 y 9 asignan `caja_c1` a P3, `caja_c2` a P4, `caja_c3` a P5; el nombre del encargo era un error de numeración |
| D13-2 | La resolución es «5 elementos requeridos de 6»; el estado de `slot_6` **no interviene** y `slot_6` no puede llenarse (regla 15) | Exigir además «`slot_6` vacío» como condición | Redundante (no puede llenarse) y añadiría un estado comprobable que no puede fallar; coincide con la matriz de 9 |
| D13-3 | Comprobación con una sola posición: el **cursor**; la pieza se **centra en el cursor** al agarrar en 0,08 s† (regla 7) | La pieza conserva el desfase de agarre y se compara su centro | Con mando, la atracción asistida lleva el cursor al centro del hueco; con desfase de hasta 0,045 m la pieza quedaría fuera del radio normal (0,04 m) y el encaje con atracción fallaría. Un solo flujo para ratón y mando |
| D13-4 (revisada, ronda 7) | Soltar en la **bandeja** sigue **B.3**: `REJECT` con `SFX_REJECT` como cualquier suelta fallida (`tray_drop_verdict` = `REJECT`). La variante `NONE` (vuelta silenciosa sin bloqueo) queda como **propuesta pendiente de confirmación del usuario** (Open Question 7) | Dar por decidido `NONE` (versión del borrador) | B.3 no exceptúa la bandeja y es la fuente de verdad; apartarse de ella es algo que CLAUDE.md manda preguntar. El argumento a favor de `NONE` (dejar una pieza a propósito no es un error, pilar *Tensión sin castigo*) se conserva para que el usuario decida; el coste de cambiarlo es un valor de datos |
| D13-5 | Una pieza encajada es **fija** y sale de `elements()` | Permitir sacar piezas encajadas | Con solución única una pieza encajada nunca está mal puesta; sacarla crearía estados y casos de borde sin función. No añade ninguna forma de atasco (S7) |
| D13-6 | `slot_6` tiene **atracción igual** que los demás huecos (regla 1) | Quitarle la atracción | Una atracción distinta delataría con el mando cuál hueco queda vacío (rompe la deducción y *Autonomía como progresión*) |
| D13-7 | Las tres pistas son `AFFORDANCE` con identificador propio (`SLOT_SILHOUETTES`, `ROW_NUMBER_ON_HOLD`, `CORRECT_SLOT_OUTLINE`); 0 claves `PISTA_*` | `HIGHLIGHT` de elementos fijos para N3 | El destino de N3 depende de la pieza en el aire (dinámico); `HIGHLIGHT` tiene `targets` fijos. Coincide con 18 (D18-1: P3 sin texto) |
| D13-8 | El contorno de N3 **permanece sobre el hueco** hasta que su pieza encaja (no solo mientras se sostiene) | Marcarlo solo mientras la pieza esté en el aire | El umbral es «una vez por compromiso» (F3 de 9): si desapareciera al soltar, un solo rechazo lo gastaría. Sigue siendo énfasis, no información nueva |
| D13-9 | «Hueco libre» para pistas excluye `slot_6` (regla 19) | Aplicar a todos los huecos sin pieza, como dice la regla 25 de 9 | Una pista que marcase `slot_6` señalaría como destino el hueco que debe quedar vacío (contradice la función del puzle). Requiere aclarar la redacción de 9 |
| D13-10 | Un solo hueco-radio por pieza: el encaje solo cuenta el **hueco propio** | Encajar en el hueco más cercano si es libre | Con la solución identidad y radio asistido de 0,10 m, «el más cercano» podría colocar una pieza en un hueco ajeno; por diseño no existe una colocación incorrecta que quede puesta |
| D13-11 | Para el nivel 2 se sigue **B.3** (mantener `PULSAR` 0,5 s sobre una pieza) y para el nivel 3 **B.3** (contorno tras 60 s); el §10.3 del slice dice «bordes numerados por fila» y «silueta sin pieza al acercar» | Seguir §10.3 | El Anexo B es la especificación de implementación (D9-12) y 18 y 9 ya siguen B.3. Se elevan las discrepancias como pregunta abierta 3 |
| D13-12 | Geometría propuesta: huecos con pitch 0,12 m (3 filas × 2 columnas), piezas de 0,09 m, bandeja a la derecha (regla 2) | Pitch 0,10 m (más compacto) | 0,12 m es el mínimo que cumple la separación de la regla 22 de 7 con el encaje asistido (256 px; margen 8 px). Con 0,10 m (220 px) habría advertencia permanente |
| D13-13 | La nota `NOTA_01` es visible ≈ 1,5 s antes del cierre de la vista y no se lee automáticamente | Alargar `close_view_after_s` a 3 s para leerla | La relectura voluntaria desde el bolsillo ya está decidida (D20-19, D10-17); 13 no cambia el ritmo de la escena 6. Se observa en playtest (AC-25) |
| D13-14 | Sin sonido propio de resolución (solo `SFX_SNAP` de la quinta pieza y la luz del marco) | Añadir un sonido nuevo de «foto completa» | El slice no lo define (B.7) y el audio no es decisión de diseño de 13; el silencio tras el chasquido sirve al pilar *El espacio expresa la emoción* |
| D13-15 | La comprobación de encaje se hace en **metros** con ε = 1e-6 m (los píxeles son solo para validar la separación y el cursor) | Comparar en píxeles | El resultado no debe depender de la resolución ni del redondeo (F1) |
| D13-16 | **Encuadre:** el centro de pantalla es `view_center_m` = (0,185; 0)†, el centro de la composición; `view_distance_m` sigue en 0,35 m (regla 2, F1b) | (a) Centrar la vista en el marco; (b) alejar la vista a `d` ≥ 0,455 m; (c) reducir la bandeja | (a) deja la bandeja y `P2`/`P4` fuera de pantalla (semianchura 0,392 m en 16:10 < 0,465); (b) cambia B.3 y baja ppm a ≈ 1.883 (separación asistida 226 px < 256 px, advertencia permanente) y los radios de B.3 dejan de ser 88/220 px; (c) comprime la bandeja por debajo de la separación pieza–pieza sin ganar el margen necesario. Desplazar el anclaje no toca ningún valor de B.3 (distancia, radios) |
| D13-17 | Pieza en vuelo de vuelta (0,4 s): tras `REJECT` está bloqueada y la animación no se interrumpe; con la variante `NONE`, un `agarrar` la interrumpe y parte de su posición actual (regla 12, edge 18) | Dejar sin definir | Una regla única, sin saltos ni piezas que desaparezcan; coherente con el bloqueo `ELEMENT` de la regla 14 de 9 |
| D13-18 | Se recorta de 13 lo que ya define 9 (destino de la pista 3 desde pausa, `on_partial`, `availability`, `condition`, `idle_reset`, knobs de 9): 13 los referencia y solo exige que `slot_6` no sea nunca hueco libre (regla 19) | Reproducirlos en 13 | Evita la divergencia detectada (13 decía «menor número que falte», 9 «todos los huecos libres»); una sola fuente |
| D13-19 | El número de fila de B.3 («en el borde», siempre visible) **no se aplica**; el número sigue oculto hasta el nivel 2 y se eleva como Open Question 8 | Mostrar el número siempre | Un número siempre visible vacía el nivel 2 de pista (B.3 y 18); es una incompatibilidad interna de B.3 que decide el autor del slice |

## Open Questions

| # | Pregunta | Quién | Estado |
|---|---|---|---|
| 1 | **Discrepancia interna del slice entre §10.3 y B.3** en las pistas: N2 «bordes numerados por fila» (§10.3) frente a «mantener `PULSAR` 0,5 s» (B.3), y N3 «el hueco vacío muestra una silueta sin pieza al acercar la cámara» (§10.3) frente a «contorno del hueco correcto tras 60 s sin movimiento» (B.3). 13 sigue B.3 (D13-11), como 9 y 18. **Toca el texto del slice: lo decide el autor.** (En 13 la «silueta sin pieza» de `slot_6` aparece con el nivel 1 de pista; si se quisiera como N3 de §10.3, cambia la pista.) | Autor (slice v0.4.x) | Abierta |
| 2 | **¿Las siluetas dicen demasiado?** Con el nivel 1, `slot_6` muestra una silueta sin pieza: el jugador puede leerla como «el sitio de Vera». Es un hecho observable (pilar 5) y la silueta es anónima, pero roza la frontera entre hecho e intención. Hay que confirmar que la silueta de `slot_6` no es reconocible como una persona concreta ni lleva rasgo alguno. B.3 declara «S6 es el hueco de Vera»: el tono (hecho neutro frente a «sitio de Vera») queda abierto; el Player Fantasy ya está escrito en términos neutros y AC-25 depende de esta decisión | creative-director · narrative-director | Abierta (afecta a tono; no la decido) |
| 3 | **Escala de la vista frente al modelo físico.** La caja mide 0,50 × 0,30 × 0,20 m (slice A.6) y el marco de este GDD ocupa 0,28 × 0,40 m con un radio de encaje de 0,04 m «en coordenadas del marco» (B.3). Se asume que la vista cercana a 0,35 m presenta el marco **ampliado** (convención de F6 de 7 para el plano de la vista). Si el marco debe ser físicamente coherente con la caja, hay que reescalar los metros (y entonces los radios de B.3 dejan de ser 88/220 px) | 7 · 10 · art-director | Abierta (V2 de 7: eje del FOV) |
| 4 | **`gestos_aceptados` por elemento.** El nivel 2 necesita que `mantener` solo exista tras alcanzarse (regla 5). Entrada dice que 7 le entrega `gestos_aceptados`, pero el contrato `ViewElement` de 9 (regla 9) no lo lleva | 7 · 9 | Abierta (Cambios requeridos) |
| 5 | **Desplazamiento inicial de la pieza.** 7 dice que la pieza «no salta» 8 px al agarrar (selección, no visual); 13 la centra en el cursor en 0,08 s (hasta 0,045 m, ≈ 100 px). Confirmar que esa interpretación es válida para 7 (D13-3) | 7 | Abierta |
| 6 | **¿El jugador se entera de que tiene `I-06a`?** (observación de playtest, sin decisión de diseño pendiente en 13): la nota se ve ≈ 1,5 s y no se lee sola. Si en playtest el jugador no sabe que tiene `I-06a`, se revisa en 20/10, no en 13 | Playtest | Abierta |
| 7 | **Soltar en la bandeja (D13-4‡).** B.3 dice «si no encaja, vuelve a la bandeja en 0,4 s (`SFX_REJECT`)»; 13 lo sigue (`REJECT`). Propuesta: soltar *dentro de la bandeja* devuelve `NONE` (sin sonido, sin bloqueo, sin contar como intento) porque es dejar la pieza a propósito. Contradice la letra de B.3, así que **no se aplica sin confirmación del usuario**; basta cambiar `tray_drop_verdict` | Usuario | Abierta (propuesta pendiente) |
| 8 | **Número de fila en el borde de la pieza (B.3).** B.3 da a cada pieza «un número de fila en el borde» (siempre visible) y a la vez usa el número como pista de nivel 2 (mantener 0,5 s). Son incompatibles (el nivel 2 no aportaría nada). 13 mantiene el número oculto hasta el nivel 2 (D13-19); el autor decide: número permanente (y se elimina o cambia el nivel 2, con 9, 18) o pista | Autor del slice (v0.4.x) | Abierta |

## Cambios requeridos en otros GDDs

No se ha editado ningún archivo existente. Lo que debe cambiar fuera:

- **9 Marco de puzles** (13 se apoya en el esquema v2 de 9 y solo pide lo que falta): (a) regla 25: «huecos libres» del P3 **excluye `slot_6`** (D13-9; es el único cambio sobre la pista desde pausa, que ya define 9); (b) catálogo de `AFFORDANCE` con los tres identificadores de P3 y un campo `id`; `idle_move_px` por puzle, `frame_lit_s` en `on_solved`, `row`, `tray_drop_verdict`, `view_center_m` y `solution.slots/pieces/tray_rect_m/empty`; dónde viven `snap_radius_m` y `view_distance_m` en el esquema; indicar qué cuenta F7 (13 incluye `t_entrada` 2,6 s y `t_cierre` 2,0 s, F3); (c) regla 9/`ViewElement`: `gestos_aceptados` por elemento (Open Question 4) o un mecanismo equivalente para habilitar `mantener` con el nivel 2; (d) regla 29: validar que `solution.map` del P3 es inyectivo y que `required` no incluye ningún hueco vacío (el controlador expone una validación de datos); (e) citar a 13 como el controlador de P3 en «Interacciones» y «Dependencies»; (f) Tuning Knobs: `piece_return_s` y `snap_radius_m` ya figuran en 9; `snap_anim_s`, `t_centrar_s`, `view_center_m` y `tray_drop_verdict` son de 13 y no se piden a 9 (se corrige el borrador anterior); opcional: `assisted_snap_radius_m` como fila propia.
- **7 Interacción e inspección:** (a) `gestos_aceptados` por elemento de vista (Open Question 4); (b) confirmar que el centrado de la pieza al agarrar (Open Question 5) es compatible con «la pieza no salta»; (c) añadir a 13 en Dependencies/Interactions como receptor de la vista `D01a` (a través de 9); (d) comprobar que la atracción de Entrada (F5b) incluye los huecos del P3 con la tolerancia asistida; (e) **verificación V2 del FOV** (F1 y F1b de este GDD dependen de ella); (f) el anclaje `ANC_D01A` y la conversión pantalla→metros de la vista `D01a` deben admitir el centro de pantalla desplazado `view_center_m` = (0,185; 0) (D13-16) y confirmar el aspecto mínimo soportado (16:10).
- **10 Caja y compartimentos:** (0) colocar `ANC_D01A` con ese desplazamiento lateral; (a) mencionar a 13 (Dependencies) y que `restore_solved_presentation()` del P3 coloca las cinco piezas y deja `slot_6` vacío; (b) coherencia geométrica de la bandeja y del marco con `tray_rect_m` y `slot_pitch_m` (Open Question 3); (c) `NOTA_01` visible desde el aviso de resolución hasta el cierre (F5).
- **6 Ajustes persistentes:** aclarar que `asistencia_encaje` es **independiente** de la atracción asistida de Entrada (edge 7 de 13) y su fila de «Quién lo lee» pasa de «13 Puzle 3» a «13 vía 9».
- **18 Base de contenido:** sin texto nuevo; confirmar la fila P3 N3 («el contorno permanece hasta que la pieza encaja», D13-8).
- **2 Jugador:** sin cambios; la nota de D-42 queda cumplida por 13 (regla 8). Confirmar quién dispara `HAND_PLACE` al encajar (7 por D7-64).
- **`design/gdd/systems-index.md`:** fila 13: estado «Borrador (lote Feature 3)», enlace al GDD; las dependencias 6, 9 y 10 ya coinciden.
- **Slice (autor):** Open Question 1 y Open Question 8 (número de fila); Open Question 7 (bandeja) la decide el usuario.

## Entradas para el registro

Formato de `design/registry/entities.yaml` (`status: active`, `added: 2026-11-09`). `snap_radius_m_P3`, `assisted_snap_radius_m_P3`, `idle_s_P3_N3` e `idle_move_px_P3` **ya existen**; este GDD solo debe añadirse a su `referenced_by`.

| Entidad / constante | Valor | Unidad | Fuente | Nota |
|---|---|---|---|---|
| `slot_pitch_m_P3` | 0,12 | m | este GDD (D13-12) | †; mínimo `256 / ppm` (F1) |
| `slot_size_m_P3` / `piece_size_m_P3` | 0,10 / 0,09 | m | este GDD | † |
| `view_center_m_P3` | (0,185; 0) | m | este GDD (D13-16) | †; margen ≥ 0,09 m en 16:10 (F1b) |
| `snap_anim_s_P3` | 0,2 | s | este GDD (coincide con `SFX_SNAP` de B.3) | † |
| `t_centrar_s_P3` | 0,08 | s | este GDD (D13-3) | † |
| `piece_count_P3` / `slot_count_P3` / `empty_slot_count_P3` | 5 / 6 / 1 | — | slice B.3 | `required` = 5 |
| `hint_effect_ids_P3` | `SLOT_SILHOUETTES`, `ROW_NUMBER_ON_HOLD`, `CORRECT_SLOT_OUTLINE` | — | este GDD (D13-7) | sin claves `PISTA_*` |
| fórmula `snap_acceptance_P3` | `|c − p_i| ≤ r ∧ slot_i libre` | m | este GDD (regla 10) | `r` ∈ {0,04; 0,10} |
| fórmula `bruteforce_time_P3` | `T_peor ≈ 30 s`, `T_media ≈ 18 s` | s | F2 | comprobación, no objetivo |
| fórmula `expected_duration_P3` | 65–150 s, mediana ≈ 100 s | s | F3 | frente a F7 de 9 (90–180 s) |

## Historial

- **2026-11-09:** borrador inicial (lote Feature 3, autor: game-designer, modo autónomo). Instancia el marco de puzles (9) para P3; 15 decisiones D13-1 a D13-15, 6 preguntas abiertas (1 sobre el texto del slice, 2 sobre el tono) y cambios requeridos en 9, 7, 10, 6, 18, 2 y el índice. Estado: Borrador (lote Feature 3) — pendiente de review.
- **2026-11-09 (ronda de corrección 7, revisión independiente: 0 bloqueantes, 9 avisos):** A1 encuadre definido (`view_center_m` 0,185 m, F1b, regla 2, edge 17, AC-27, D13-16); A2 D13-4 revisada: la bandeja sigue B.3 (`REJECT`), `NONE` queda como propuesta pendiente (Open Question 7); A3 número de fila de B.3 incompatible con la pista 2, mantenido oculto y elevado (Open Question 8, D13-19); A4 Player Fantasy y Summary en términos neutros, tono de `slot_6` abierto (OQ 2, AC-25 condicionado); A6–A7–A9 recorte frente al esquema v2 de 9 (regla 18, Datos del puzle, Cambios en 9; D13-18); A8 vuelta de la pieza definida (regla 12, edge 18, AC-28, D13-17); citas de 10 corregidas (colocación de `NOTA_01` = regla 17 de 10). A5 sigue en OQ 5. Decisiones D13-16 a D13-19. Estado: Revisado (ronda de corrección 7) — pendiente de re-review.
