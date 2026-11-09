# Caja y compartimentos

> **Status**: Revisado (ronda de corrección 3) — pendiente de re-review
> **Author**: Game Designer (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el jugador abre los compartimentos en el orden que quiera dentro de las dependencias) · Tensión sin castigo (la caja nunca falla, nunca se atasca y nunca bloquea más de 3 s) · El espacio expresa la emoción (madera, cerraduras y un altavoz dentro de la caja dicen lo que nadie explica) · Información incompleta (la caja guarda objetos y una voz, no confirma intenciones)

## Summary

La caja de nogal del despacho del Guardián (`D01`) tiene cuatro compartimentos (`D01a`–`D01d`, `C1`–`C4`), uno por cada puzle 3 a 6. Este sistema es el **hardware** de la caja: decide cómo se ve, cómo suena y cuánto tarda cada compartimento en abrirse, entreabrirse, cerrarse o quedarse abierto, y encadena esa animación con el acercamiento de cámara de Interacción e inspección (7). **No decide cuándo se abre cada compartimento ni si el puzle está resuelto**: eso lo calcula el Marco de puzles (9) a partir de los hechos `caja_c1`–`caja_c4`; la caja solo obedece y lo escenifica.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `3 Estado y bus`, `7 Interacción e inspección`, `9 Marco de puzles` · Dueño de: manejadores de `D01a`–`D01d`, constantes `BOX_C1_OPEN`…`BOX_C4_OPEN`

## Overview

Caja y compartimentos es la capa de escenificación entre los puzles 3 a 6 y el mundo físico. Tiene un manejador por cada `D01a`–`D01d` que Interacción e inspección (7) consulta (`can_interact`) y activa (`interact`). Al pulsar sobre un compartimento disponible, la caja bloquea el contexto con un token (`bloquear_contexto`), anima la apertura (`BOX_Cn_OPEN`, notación genérica de `BOX_C1_OPEN`…`BOX_C4_OPEN`) y, al terminar, pide a 7 la vista cercana (`abrir_vista(id, desde_token)`), de modo que el jugador percibe un único gesto continuo: mano, tapa, acercamiento y puzle. Si el puzle no está disponible o ya está resuelto, la caja no anima ninguna tapa y contesta `SIN_EFECTO`, según lo que diga `get_view_gate` del Marco (9) (7 puede reproducir su propio gesto de mano, `HAND_REACH`; no es de la caja).

La caja **no guarda hechos** ni escribe ninguno. Lee `caja_c1`–`caja_c4` y el estado público de cada puzle para saber qué postura (pose) enseñar, escucha los avisos de 9 («puzle activado» con `ajar_cm`, «compartimento completado» n) para saber cuándo entreabrir o cerrar, y presenta lo que cada compartimento contiene: una nota, una lista de tareas, una voz y una carta. La combinación «caja completa» (`caja_completa`) es un hecho derivado del Estado (3); la caja no lo emite ni reacciona a él.

## Player Fantasy

Vera no abre una caja: **la dejan entrar**. Cada compartimento es una capa de algo que el Guardián no se atrevió a decir en voz alta, guardado en nogal, con bisagras que ceden sin prisa y una madera que suena a despacho de noche. El jugador siente peso (el compartimento tarda lo que tarda una mano en tirar de una tapa), intimidad (la cámara se acerca sin cortes, como quien se inclina) y la certeza tranquila de que **la caja nunca se enfada**: si algo aún no se abre, no pasa nada; si se sale a medias, se vuelve; si se acierta, la madera se cierra o se queda abierta como decisión del objeto, no como premio.

Aesthetics del MDA: **Discovery** (qué hay en cada capa y en qué orden se lee), **Sensation** (madera, tapa, altavoz, luz del marco) y **Narrative** (una nota, una lista, una voz, una carta: una confesión a medias, sin explicarla). Necesidades SDT: **Autonomía** (C1 y C2 se abren en el orden que se quiera; la caja no empuja), **Competencia** (cada pulsación tiene una respuesta legible en menos de 0,5 s: sonido de bloqueo o inicio de apertura) y **Relatedness** (el Guardián habita el objeto: su letra, su voz, su carta).

**Test de pilar.** Si dudamos entre un texto que diga «completa los otros compartimentos primero» y un clic seco de madera que no abre, elegimos el clic (*El espacio expresa la emoción*, *Autonomía como progresión*: las pistas son de 17, no de la caja). Si dudamos entre una fanfarria al completar la caja y que la caja siga ahí, callada, elegimos que siga ahí (*Información incompleta*: el apagón al salir de D es la única señal; lo emite 21).

## Detailed Rules

Convención: «regla N de X» remite a la regla numerada del GDD del sistema X. Los tiempos son de **tiempo de juego** (la pausa los detiene; regla 36 de 9, regla 32 de 7).

### A. Propiedad y alcance

1. **Qué posee la caja (10).** El nodo `D01` y sus cuatro compartimentos (modelo, tapas, bandeja de C1, altavoz, anclajes de cámara `ANC_D01A`–`ANC_D01D`), sus animaciones de apertura, entreabierto y cierre, los manejadores de `D01a`–`D01d` (regla 3 de 7) y las constantes `BOX_C1_OPEN`…`BOX_C4_OPEN`. **No posee:** los hechos `caja_c1`–`caja_c4` (los escribe 9, regla 16 de 9; dueño 3), el estado de los puzles (9), las piezas y reglas de cada puzle (13 a 16: piezas, fichas, ángulo θ, botones), los ítems y documentos (20), las líneas y su audio (18, 23), el hecho derivado `caja_completa` (3, regla 7).
2. **Los cuatro compartimentos.** Fuente: slice B.3–B.6 y C.6; dependencias: regla 24 de 9 (el slice D-16, pendiente de confirmar).

   | n | ID | Puzle | Hecho | Disponible cuando (lo decide 9) | Contiene (qué se ve) | Recompensa | Pose final |
   |---|---|---|---|---|---|---|---|
   | 1 | `D01a` | P3 · Encaje de la foto | `caja_c1` | Al entrar en D | Marco de seis huecos, bandeja con cinco piezas (la bandeja es **parte del compartimento**, regla 17) | `I-06a` (`NOTA_01`, «La transición es tuya») | `FINAL_CERRADO` |
   | 2 | `D01b` | P4 · Tablero de tareas | `caja_c2` | Al entrar en D (sin dependencias) | Tablero con cuatro fichas T1–T4 | `I-05` (lista de tareas del Guardián; decorado de papel en el tablero, regla 17) | `FINAL_CERRADO` |
   | 3 | `D01c` | P5 · Espejo de la diferencia | `caja_c3` | `caja_c1` | Marco interior giratorio con superficie reflectante y un altavoz | `VO_G_07` (unos 14 s, desde el altavoz) | `FINAL_CERRADO` |
   | 4 | `D01d` | P6 · Decisión | `caja_c4` | `caja_c1`, `caja_c2` y `caja_c3` | Panel con tres botones (A «Estoy bien», B «La verdad», C «Todavía no»), cerradura y tapa | `I-07` (la carta) | `FINAL_ABIERTO` |

3. **La caja no decide disponibilidad.** Toda pregunta «¿se puede abrir ya?» se contesta con `get_view_gate(view_id)` de 9 (regla 7 de 9). La caja no lee `caja_cn` para decidir si abre; los lee **solo para reconstruir la pose** (regla 6). No contiene lógica de dependencias entre compartimentos (D9-11).

### B. Poses (estado de presentación, no son hechos)

4. **Pose de cada compartimento.** Valor de presentación en memoria, nunca guardado y nunca visible para otros sistemas como hecho:

   | Pose | Significado |
   |---|---|
   | `CERRADO` | Tapa cerrada, puzle `ACTIVO` o `BLOQUEADO` |
   | `ENTREABIERTO` | Solo C3: tapa separada `ajar_cm` cm (regla 12); la animación puede estar diferida o en curso, la pose lógica ya es esta |
   | `ABRIENDO` | `BOX_Cn_OPEN` en curso (C1–C3 al pulsar; C4 dentro de `play_open(4)`) |
   | `ABIERTO` | Tapa abierta, puzle sin resolver (solo C1–C3; C4 nunca está `ABIERTO`: pasa de `CERRADO` a `ABRIENDO` y de ahí a `FINAL_ABIERTO`) |
   | `CERRANDO` | Animación de cierre tras resolver (C1–C3) |
   | `FINAL_CERRADO` | C1–C3 resueltos y cerrados |
   | `FINAL_ABIERTO` | C4 resuelto, tapa abierta con la carta dentro |

   Transiciones (cualquier otra es inválida y se registra):
   - **C1–C3:** `CERRADO → ABRIENDO → ABIERTO` (pulsación con `get_view_gate` = `OPEN`); `ABIERTO → CERRANDO → FINAL_CERRADO` («compartimento completado» n=1–3, regla 14).
   - **C3 entreabierto:** `CERRADO → ENTREABIERTO` («puzle activado» de P5 con `ajar_cm`, regla 12). `ENTREABIERTO → ABRIENDO` en la pulsación: si la animación de entreabierto está **diferida o en curso, se cancela** (no se funde ni se salta) y `BOX_C3_OPEN`† parte de la **posición real de la tapa en ese instante** (0 a `ajar_cm` cm) hasta la apertura completa, con la duración fija de `BOX_C3_OPEN` (la cadena F1 no cambia).
   - **C3 interrumpido en la secuencia de P5:** `ABIERTO → ENTREABIERTO` (regla 9 de Edge Cases): salir de la vista durante `RESOLVING` deja a C3 en el **mismo** estado que al cargar con P5 `ACTIVO` (N5-1, D10-21); la tapa vuelve a `ajar_cm` cm (animación de F3, diferida hasta que `D01c` sea visible, regla 12) y la pulsación siguiente repite `ENTREABIERTO → ABRIENDO`.
   - **C4:** `CERRADO → ABRIENDO` solo por `play_open(4)` (regla 11) y `ABRIENDO → FINAL_ABIERTO` al terminar esa animación. «Compartimento completado» (4) llega en t = 0, antes de `play_open` (t = 0,3 s): la pose sigue `CERRADO` hasta `play_open`; el aviso solo marca `final_pendiente[4]`. Si la vista de `D01d` se cierra con `final_pendiente[4]` y la pose aún `CERRADO` (la presentación no se ejecutó: consola o interrupción), la caja coloca `FINAL_ABIERTO` sin animar (regla 15).
   - **Recuperación (señal de fin de animación perdida):** `ABRIENDO` sin señal al vencer el token de 3 s de tiempo de juego (C1–C3) → la tapa se coloca en su posición abierta sin animar, pose `ABIERTO`, error registrado, **no** se llama a `abrir_vista` (7 ya liberó el contexto); el jugador reintenta y se aplica la regla 9.5. `CERRANDO` sin señal a `BOX_Cn_CLOSE + 1,0 s`† → `FINAL_CERRADO` sin animar. `play_open(4)` sin señal a `BOX_C4_OPEN + 1,0 s`† → `FINAL_ABIERTO` sin animar. El reloj de estos vigilantes es el de juego (regla 22).
   - **Nunca hacia atrás:** un `FINAL_*` no cambia (S2 de 9, regla 28 de 9). Salir de la vista sin resolver **no** cierra el compartimento (regla 9, paso 5).
5. **Configuración al arrancar `planta`.** En el orden de arranque 7 → 9 → resto (regla 9, paso 6 de 4), la caja se configura **después** de 9 y reconstruye la pose **de forma síncrona y sin animar, sin sonar y sin emitir nada**, leyendo hechos y estado de 9. No guarda ni restaura nada propio. Si 9 falla la validación de datos, la caja no se configura (fallo de carga inmediato, 4).
6. **Pose inicial según hechos.**
   - `caja_cn` verdadero → `FINAL_CERRADO` (n=1–3) o `FINAL_ABIERTO` (n=4), con su contenido final (regla 15).
   - P5 `ACTIVO` y `caja_c3` falso → C3 en `ENTREABIERTO` (`ajar_cm` de la definición, 2 cm) sin sonido (regla 8 de 9: pasa a `ACTIVO` en silencio).
   - Cualquier otro caso → `CERRADO`.
   - Con `pendiente_revelacion` verdadero al guardar (P5 sin resolver, regla 19 de 9), **permanece verdadero**: 9 solo lo limpia si el puzle ya está `RESUELTO` (regla 8.1 de 9). La caja deja C3 en `ENTREABIERTO` (corresponde a `ACTIVO`); al reabrir, 9 salta la comprobación y reproduce la secuencia de P5 desde el principio (regla 19 de 9). La caja no lee ni toca `pendiente_revelacion`.

### C. Interacción y apertura

7. **Disponibilidad ante 7 (`can_interact`).** Siempre `SI` o `SIN_EFECTO`, **nunca `NO`** (el compartimento sigue habilitado para 7; regla 7 de 9). `SI` si `get_view_gate` devuelve `OPEN`; `SIN_EFECTO` si `BLOCKED` o `SOLVED`. Verbo corto `ABRIR` (`UI_VERBO_ABRIR`) siempre, sin cambio de etiqueta con el estado.
8. **Respuesta `SIN_EFECTO`.** 7 reproduce `SFX_CLICK_SUBTLE` y el `texto` de su catálogo (regla 3 de 7), vacío en `D01a`–`D01d` (D10-8). La caja **ignora** `feedback_sfx` y `feedback_text_key` de `get_view_gate`: 7 no tiene mecanismo para que un dueño los pase (ver «Cambios requeridos en 7»). La caja **no mueve ninguna tapa, no abre la vista y no pide bloqueo**; no hay acercamiento de cámara inútil ni «tirón» de la tapa. (7 puede reproducir `HAND_REACH`, reservado para `SIN_EFECTO`: es el gesto de la mano, no una animación de la caja.) Vale igual para un compartimento resuelto: no reabre su vista (reglas 7 y 35 de 9).
9. **`interact()` de C1, C2 y C3 con `OPEN` (secuencia encadenada, regla 19 de 7).** En el mismo paso de la pulsación (dentro de `interact()`, requisito de `bloquear_contexto`, regla 30 de 7):
   1. Se consulta `get_view_gate`; si no es `OPEN`, se devuelve `SIN_EFECTO` (regla 8). Si pasa, la caja **no** vuelve a consultarlo hasta el paso 4, donde lo reconsulta una vez.
   2. **Pose `CERRADO` o `ENTREABIERTO` (en este caso se cancela la animación de entreabierto, regla 4):** `token = bloquear_contexto("D01x")`. Si devuelve `nulo`, se devuelve `SIN_EFECTO`, no se anima nada y se registra el error (no hay softlock: nada quedó bloqueado).
   3. Pose `ABRIENDO`: animación `BOX_Cn_OPEN` (duración por compartimento, regla 21), sonido `SFX_BOX_WOOD_OPEN` en t = 0. `D01a`–`D01d` **no declaran `gesto_hecho`**: la animación del compartimento es el gesto (regla 3 de 7).
   4. Al terminar la animación (señal de fin de la animación, no un temporizador de fotograma; recuperación si no llega: regla 4): pose `ABIERTO` y se **reconsulta `get_view_gate`**. Si ya no es `OPEN` (p. ej. `SOLVED` por pista de nivel 3 o consola durante `ABRIENDO`), se llama a `liberar_contexto(token)`, **no** se abre la vista y el cierre sigue la regla 14 (sin acercamiento inútil). Si sigue `OPEN`: `abrir_vista(id, desde_token = token)`. Si `ACEPTADA`, el bloqueo se **transfiere** a la cámara sin soltarse (regla 19 de 7). Si `RECHAZADA(motivo)`, la caja llama a `liberar_contexto(token)`, registra el motivo y deja el compartimento `ABIERTO` (el jugador puede volver a pulsar y se aplica el paso 5).
   5. **Pose `ABIERTO` (reapertura tras `atrás`):** no hay animación ni token. La caja llama directamente a `abrir_vista(id)` desde `exploración`. `T_cadena` = solo `t_vista_entrada_s` (F1).
   6. Se devuelve `HECHO`.
10. **Vista y gestos.** La caja **no** interviene en la vista cercana: la abre 7, la sirve el receptor que 9 registró para el ID (regla 30 de 7), y el cursor y los gestos son de 7 y Entrada. La caja solo aporta el anclaje de cámara `ANC_D01x`, **perpendicular al plano del puzle** (condición de la regla 19 de 7), y los nodos donde cuelgan los elementos de cada puzle. Cerrar con `atrás` o con `cerrar_vista` sigue la regla 23 de 7 sin intervención de la caja.
11. **Compartimento 4 (`D01d`): sin apertura previa.** El panel de tres botones y su cerradura están en el **frontal** del compartimento (slice B.6: la tapa se abre *tras* pulsar). Por tanto `interact()` de C4 con `OPEN` salta los pasos 2 a 4 de la regla 9 y llama a `abrir_vista("D01d")` directamente desde `exploración` (sin token). `BOX_C4_OPEN` (tapa, 1,6 s) se reproduce **dentro de la presentación de resolución del P6**: la caja ofrece `play_open(4)`, que el controlador del P6 llama desde `play_resolution` **tras** `SFX_LOCK_CLICK` (0,3 s) (regla 16.6 de 9). La caja no inicia esa animación por su cuenta ni escribe nada. Pose: `CERRADO → ABRIENDO → FINAL_ABIERTO` (regla 4). `T_cadena(4)` = `t_vista_entrada_s` (F1).

### D. Entreabierto de C3

12. **«Puzle activado» de P5 con `ajar_cm`** (regla 24 de 9). El sonido `SFX_UNLOCK_SOFT` lo reproduce 9 en el aviso. La caja desplaza la tapa de C3 `ajar_cm` cm a lo largo de `ajar_s` (F3) **en cuanto D01c es visible para la cámara de Vera en `exploración`**, definido así: contexto `exploración`, el punto `VIS_D01C` (nodo sobre la tapa de C3) dentro del frustum de la cámara de Vera (`Camera3D.is_position_in_frustum`) y a distancia ≤ `ajar_visible_dist_m` (2,0 m†); no se comprueba oclusión (la caja está sobre el escritorio, sin objetos delante en el slice); si en el aviso el jugador está en la vista cercana de `D01a` (el caso normal: `caja_c1` se escribe ahí), la animación espera a que se devuelva la cámara. Pose lógica `ENTREABIERTO` desde el aviso; solo la animación se difiere. El estado `ENTREABIERTO` no cambia `can_interact` (lo decide 9).
13. **C4 no se entreabre.** `ajar_cm` no se aplica al P6 (B.6 no lo pide; regla 24 de 9). Decisión en «Decisiones tomadas»; la Open Question 5 de 9 queda resuelta en ese sentido salvo veto del creative director.

### E. Cierre y estado final

14. **Cierre de C1–C3.** Al recibir «compartimento completado» (n=1–3) de 9 (emitido tras `EV_PUZZLE_SOLVED_*`, regla 16.5 de 9): se marca `cierre_pendiente[n]`. El cierre **empieza** `close_delay_s`† después de que se cumpla lo primero de: (a) la vista de `D01x` no está `Abierta` (se emite «vista cercana cerrada», que 9 pide tras `close_view_after_s` con motivo `resuelto`, o la cierra el jugador con `atrás`, o ya estaba cerrada); (b) la vista **nunca estuvo abierta**: solo por consola/`AUTO_SOLVE` (regla 31 de 9) o por la reconsulta del paso 4 de la regla 9, **no** por juego normal; P5 no puede resolverse con la vista cerrada (reglas 17 a 19 de 9). Dura `BOX_Cn_CLOSE`†, con `SFX_BOX_WOOD_CLOSE`, **sin token ni bloqueo** (es escenificación; el jugador puede moverse). Al terminar: `FINAL_CERRADO`. Si el cierre se solapa con el de otro compartimento, son independientes. Si el jugador interrumpe la secuencia de P5 (sale de la vista), **no hay aviso** y por tanto no hay cierre: C3 sigue `ABIERTO` (regla 18 de 9).
15. **Contenido final visible y quién coloca qué.** `restore_solved_presentation()` (sin argumento) es un método del `PuzzleController` de cada puzle (regla 9 y tabla de interfaz de 9; reglas 8 y 35 de 9), **no** de la caja. La caja ofrece `set_final_pose(n)`, que el controlador (o 9) llama desde ese método: coloca la tapa y el decorado del compartimento en la pose final **sin animar, sin sonar y de forma idempotente**; lo usa también la regla 4 (recuperaciones). La caja **no** coloca lo que es del puzle: en C3 el marco interior alineado a θ* y la silueta resaltada los fija el controlador (regla 17 de 9); en C2 las fichas selladas, también el controlador. Pose final: C1–C3 `FINAL_CERRADO` (tapa cerrada: el interior no se ve y no se coloca decorado); C4 `FINAL_ABIERTO` (tapa abierta con la carta plegada dentro).
16. **C4 queda abierto** (regla 35 de 9; la línea `VO_G_13D` dice «Te he dejado la caja abierta»). `FINAL_ABIERTO` para todas las variantes de la carta (`carta_variante` A, B o C): la caja no distingue variantes (*Ambivalencia sin moral binaria*: ningún aspecto de la caja codifica la elección). Si «compartimento completado» (4) llega con la tapa aún animando, se deja terminar.

### F. Contenido y su relación con 7 y 20

17. **Recompensas.** Los ítems no son hechos (slice D.1): los deriva 20 de los hechos y del aviso `EV_PUZZLE_SOLVED_*` (campo `rewards`, regla 16 de 9). La caja **no** añade ni quita ítems; solo muestra el decorado:
    - C1: **la bandeja es parte del compartimento C1** (se ve con la tapa abierta y se cierra con él). Al resolver P3 aparece el papel `NOTA_01` sobre la bandeja (slice B.3), decorado **no interactivo**, visible mientras la vista de `D01a` sigue abierta y hasta que la tapa se cierra (regla 14). En `FINAL_CERRADO` no se ve y tras cargar no se coloca; la nota está en el bolsillo (20).
    - C2: papel de la lista (`I-05`, slice C.6 «D01b: I-05») como decorado no interactivo sobre el tablero, con el mismo ciclo de vida que `NOTA_01`. Su texto legible es de 20 (`I-05` en el bolsillo, releíble con `repasar_bolsillo()`, 20 R18; D10-17). 10 no presenta ninguna lectura.
    - C3: la caja ofrece la fuente de audio 3D `SPK_D01C`, en el altavoz del compartimento; la secuencia de P5 (paso `LINE`, regla 20 de 9) la usa para `VO_G_07` y 23 la reproduce ahí. La caja no reproduce, no mide ni espera la línea.
    - C4: carta plegada dentro de la tapa, visible al abrirse. La lectura (`abrir_lectura(I-07)`) la pide 9 al final de su presentación (regla 16.6 de 9) y la gestiona 7/20.
    - **Lectura de `I-05`/`I-06a` al resolver P4/P3 (R13 y Q2 de 20):** 10 **no** la presenta; sería una petición `abrir_lectura` de 9 (como la de `I-07`, regla 16.6 de 9) y cambiaría el ritmo de la escena 6. Por defecto no hay lectura automática: ambos documentos están en el bolsillo y se releen con el repaso (R6 de 20). Pregunta abierta 7.
18. **Con 20.** La caja no consulta `has_item` ni lee el bolsillo. Un ítem no abre ni bloquea ningún compartimento (la caja no tiene `needs_items`). 20 es dueño de `tarjeta_B`, `tarjeta_D` y `formulario_leido`; 9 de `caja_c1`–`caja_c4` (R24 de 20): la caja no escribe ninguno.

### G. «Caja completa»

19. **Quién la emite.** `caja_completa` es un hecho **derivado** de 3 (regla 7 de 3): `caja_c1` y `caja_c2` y `caja_c3` y `caja_c4`. Lo recalcula 3 cuando 9 escribe `caja_c4` (o el último de los cuatro); el aviso de `caja_c4` se entrega antes que el del derivado (CA-14 de 3). **La caja no lo escribe, no lo emite y no reacciona a él.** Lo lee 21 (apagón y llamada al cruzar el umbral de D; slice C.7) y 7 (`habilitado_si`).
20. **Sin señal de «completada».** Al completar el cuarto compartimento la caja no añade luz, sonido ni animación propios de «caja completa» (*Información incompleta*, *El espacio expresa la emoción*: la señal es la planta). La presentación del P6 (regla 11) es la del puzle, no una celebración.

### H. Tiempos

21. **Duraciones.** Valores por defecto y rango en Tuning Knobs. `BOX_Cn_OPEN` (notación genérica de `BOX_C1_OPEN`…`BOX_C4_OPEN`; no es una constante del registro) es **por compartimento** con **tope 1,6 s** (reconciliación del slice con 7, en Decisiones tomadas D10-1). Validación en datos: `BOX_Cn_OPEN[n] + t_vista_entrada_s(n) ≤ T_tope − margen_min` para n = 1–3 (F1); un valor fuera de rango es error de datos. Sin fuente en el slice y por tanto **propuestas (†) a validar en playtest**: `BOX_C3_OPEN`, `BOX_Cn_CLOSE`, `close_delay_s`, `ajar_s`, `ajar_visible_dist_m`, los vigilantes de la regla 4 y los `t_vista_entrada_s` de `D01b`–`D01d` (el slice solo da 1,0 s para `D01a`).
22. **Reloj.** Las animaciones de la caja y los vigilantes de la regla 4 corren con el tiempo de juego. **NOT SOURCEABLE:** si `SceneTree.paused` detiene `AnimationPlayer`, sus señales de fin y los sonidos en Godot 4.7 no está cubierto por `docs/engine-reference/godot/` (Open Question 4 de 9; Pregunta abierta 4 aquí). Evitar `Tween` y `SceneTreeTimer` **no elimina** esa dependencia (`AnimationPlayer` depende de lo mismo); solo evita sumar otra incógnita. Hasta verificarlo, AC-21 y el contrato de pausa de las reglas 9 y 14 quedan **sin confirmar**; no se asume ningún comportamiento del motor.
23. **Sin persistencia ni peticiones de guardado.** La caja no guarda ni pide guardar. El guardado por `compartment_done:<n>` (regla 6 de 5) lo dispara el aviso de 9; la instantánea espera a que la cola de avisos esté vacía (regla 5 de 5).

## Formulas

### F1 · Cadena de apertura (pulsación → primera acción en la vista)

`T_cadena(n) = BOX_Cn_OPEN[n] + T_entrada(n)` para n = 1, 2, 3 · `T_cadena(4) = T_entrada(4)` · `T_reapertura(n) = T_entrada(n)` (pose `ABIERTO`)
`T_entrada(n) = min(t_vista_entrada_s(n), t_transicion_max)` (F4 de 7)
`Margen(n) = T_tope − T_cadena(n)` · **Restricción de datos:** `Margen(n) ≥ margen_min`

**Variables:** `BOX_Cn_OPEN[n]` (notación genérica de `BOX_C1_OPEN`…`BOX_C4_OPEN`; s; 1,2–1,6), `t_vista_entrada_s(n)` (s; 0,6–1,2 en las vistas encadenadas, valor de 7), `T_tope` = tope único de transición de Entrada (F8 de Entrada; 3 s por defecto, rango seguro 3–5), `margen_min` = 0,2 s (rango 0,1–0,2; con 0,2 el peor caso C1 queda justo en el margen). El token de `bloquear_contexto` caduca a 3 s de tiempo de juego (regla 30 de 7); `BOX_Cn_OPEN` < 3 s siempre.

| n | `BOX_Cn_OPEN` | `T_entrada` 1,0 s (defecto) → `T_cadena` / margen | `T_entrada` 1,2 s (peor caso) → `T_cadena` / margen | Reapertura |
|---|---|---|---|---|
| 1 | 1,6 s | 2,6 s / 0,4 s | 2,8 s / 0,2 s | 1,0–1,2 s |
| 2 | 1,4 s (slice) | 2,4 s / 0,6 s | 2,6 s / 0,4 s | 1,0–1,2 s |
| 3 | 1,4 s† | 2,4 s / 0,6 s | 2,6 s / 0,4 s | 1,0–1,2 s |
| 4 | — (la tapa va en la resolución) | 1,0 s / 2,0 s | 1,2 s / 1,8 s | 1,0–1,2 s |

`t_vista_entrada_s` de `D01b`–`D01d` los define el catálogo de 7 (el slice solo da 1,0 s para `D01a`); la tabla **supone** 1,0 s (propuesta†). Peor caso global: 2,8 s ≤ 3 s.

### F2 · Reconciliación `BOX_Cn_OPEN` (slice) ↔ valor único de 7

`BOX_OPEN_MAX = T_tope_mín − t_entrada_máx − margen_min = 3,0 − 1,2 − 0,2 = 1,6 s` (con `margen_min` en su rango 0,1–0,2 el tope sería 1,6–1,7 s; se fija 1,6 s por coherencia con 7 y el registro)

El slice da valores por compartimento (B.3: `BOX_C1_OPEN` = 1,6 s; B.4: `BOX_C2_OPEN` = 1,4 s); 7 modelaba **un único** valor (`BOX_Cn_OPEN` = 1,6 s, rango [1,2; 1,6]), sustituido en 7 por `BOX_C1_OPEN`…`BOX_C4_OPEN` y `BOX_OPEN_MAX` (D7-62). Se reconcilian así: **el 1,6 s de 7 es el tope (`BOX_OPEN_MAX`), no el valor de cada compartimento**; los valores reales son por compartimento y todos ≤ 1,6 s. Los de C1 y C2 vienen del slice; los de C3 (1,4 s†) y C4 (1,6 s, slice B.6) los fija este GDD como propuesta (D10-1, D10-2). Si Entrada sube su tope a 4 s, `BOX_OPEN_MAX` sube a 2,6 s pero **no** se usa: el rango de 7 y del registro sigue [1,2; 1,6].

### F3 · Entreabierto de C3

`x(t) = ajar_cm · suavizado(t / ajar_s)` para `t ∈ [0, ajar_s]`, con `suavizado(u) = 3u² − 2u³`; `ajar_cm` ∈ [1, 4] (lo fija 9), `ajar_s` ∈ [0,3; 1,2] (0,6 s†, propuesta). Si se cancela por una pulsación (regla 4), `x` en ese instante es la posición de partida de `BOX_C3_OPEN`.
**Ejemplo:** `ajar_cm` = 2, `ajar_s` = 0,6: en t = 0,3 s, x = 1,0 cm; velocidad máxima = 1,5 · 2 cm / 0,6 s = 5 cm/s.

### F4 · Cierre de C1–C3

`t_inicio_cierre = max(t_aviso, t_vista_cerrada) + close_delay_s` · `t_fin_cierre = t_inicio_cierre + BOX_Cn_CLOSE[n]`
En juego normal la vista **siempre** estuvo abierta al resolver (reglas 17 a 19 de 9), así que `t_vista_cerrada` existe. Rama solo de consola/orden de 21/reconsulta del paso 4 (regla 9): si la vista nunca estuvo abierta, `t_vista_cerrada = t_aviso`.
**Ejemplo (P5 con `close_view_after_s` = 1,5 s, valor del ejemplo de 9; `t_devolver` = 0,5 s de Jugador):** aviso en t = 0 → 9 pide cerrar la vista en 1,5 s → cámara devuelta en 2,0 s («vista cercana cerrada») → cierre empieza en 2,3 s y termina en 3,1 s con `BOX_Cn_CLOSE` = 0,8 s†.

### F5 · Línea temporal del P6 en la caja

`t_carta_visible = t_pulsación + 0,3 s (SFX_LOCK_CLICK) + BOX_C4_OPEN (1,6 s) = 1,9 s`. Coincide con «0,3 s + 1,6 s» de 9 (AC-17 de 9). Los hechos (`carta_variante`, `caja_c4`) se escriben en t = 0, antes de la presentación (regla 16 de 9); la caja no retrasa ninguno.

### F6 · Latencia de respuesta (competencia)

Pulsación → primer feedback audible: ≤ 1 paso de física (`SFX_CLICK_SUBTLE` si `SIN_EFECTO`) o t = 0 (`SFX_BOX_WOOD_OPEN` al empezar `ABRIENDO`). Ambos < 0,5 s (micro-feedback del pilar *Tensión sin castigo*).

## Edge Cases

1. **Pulsar un compartimento `BLOQUEADO` (C3 antes de `caja_c1`; C4 antes de `c1`+`c2`+`c3`).** `SIN_EFECTO`: `SFX_CLICK_SUBTLE`, sin texto, sin animación, sin cámara, sin bloqueo (reglas 7 y 8). Repetirlo no cuesta nada ni desencadena nada; 7 aplica su enfriamiento del sonido.
2. **Pulsar un compartimento `RESUELTO`.** `SIN_EFECTO` igual; no reabre la vista (regla 35 de 9). La carta se relee desde el bolsillo (20), no desde la caja.
3. **Pausa durante `ABRIENDO`/`CERRANDO`/entreabierto.** La animación y su sonido se detienen y siguen al reanudar; el token no caduca durante la pausa (regla 30 de 7, regla 28 de 7).
4. **`bloquear_contexto` devuelve `nulo`** (otro modo abierto o fuera de `interact()`): `SIN_EFECTO`, sin animación, error registrado; el jugador puede reintentar. No hay estado a medias.
5. **`abrir_vista` rechaza al terminar la apertura.** Se libera el token, queda `ABIERTO`, se registra. Nueva pulsación → reapertura sin animación (regla 9.5).
6. **El puzle pasa de `ACTIVO` a `RESUELTO` por consola o por la pista nivel 3 (`AUTO_SOLVE_ELEMENT`) mientras la caja anima** (p. ej. `caja_c2` escrito con la apertura en curso): la caja termina la animación y, en el paso 4 de la regla 9, **reconsulta `get_view_gate`**: ve `SOLVED`, libera el token y **no** llama a `abrir_vista` (sin acercamiento inútil). El aviso (n) pone `cierre_pendiente` y, como la vista nunca estuvo abierta, el cierre empieza a `close_delay_s` (rama de F4). Si el hecho se escribe *después* del paso 4, el marco cierra la vista por su red de seguridad (regla 7 de 9) y se aplica la regla 14(a).
7. **El jugador sale de la vista (`atrás`) antes de resolver.** El compartimento queda `ABIERTO` (regla 9.5). Salir de D con el compartimento abierto es válido; vuelve a verse abierto. Cargar una partida lo deja `CERRADO` (no se persiste la pose parcial, regla 6; C3 `ENTREABIERTO` si P5 está `ACTIVO`).
8. **Dos compartimentos abiertos a la vez** (C1 `ABIERTO` sin resolver y se pulsa C2): válido. No hay límite; cada uno es independiente.
9. **Salir de la vista durante la secuencia de P5 (`RESOLVING`).** Según las reglas 17 a 19 de 9 la secuencia solo corre con la vista abierta: salir (`atrás`, `cerrar_modos()` de 21, descarga) la interrumpe y **no se escribe nada** (ni `caja_c3`, ni aviso, ni «compartimento completado»). Para la caja: C3 pasa a `ENTREABIERTO` (el mismo estado que tras cargar, D10-21), no hay `cierre_pendiente` ni cierre, `SPK_D01C` lo corta 23. Al volver a pulsar C3 (`ENTREABIERTO → ABRIENDO`, regla 4, con `BOX_C3_OPEN` desde la posición real de la tapa) 9 salta la comprobación y reproduce la secuencia desde el principio. Si se carga: `pendiente_revelacion` sigue verdadero (regla 6), C3 nace `ENTREABIERTO` y se reabre con `BOX_C3_OPEN`: idéntico. **No existe resolución de C3 con el jugador lejos en juego normal** (P5 no tiene `AUTO_SOLVE`; solo consola, regla 31 de 9, y entonces rige la rama de F4).
10. **«Puzle activado» de P5 con el jugador en la vista de D01a.** El sonido ya sonó (9); la animación del entreabierto espera hasta que D01c sea visible en `exploración` (regla 12). Si el jugador cierra la vista de lado y D01c queda fuera de campo, espera; `can_interact` ya vale `SI` (lo decide 9), así que no impide abrir.
11. **Cargar con `caja_c4` verdadero y `caja_c3` falso** (instantánea corrupta o consola): cada compartimento se reconstruye de su propio hecho (C4 `FINAL_ABIERTO`, C3 según el estado de 9). Se registra la incoherencia; 9 y 3 la reconcilian (reglas 8 y 31 de 9). No hay bloqueo.
12. **Cargar a mitad de la secuencia del P6** (los hechos ya están escritos, regla 16 de 9; se guardó): `caja_c4` verdadero → `FINAL_ABIERTO` sin animar. La carta ya está en el bolsillo (20).
13. **`atrás` pulsado durante la presentación del P6** (tras `SFX_LOCK_CLICK`): el P6 es de resolución inmediata (solo P5 es diferida, regla 17 de 9), así que `atrás` funciona (S4 de 9, regla 28 de 9): la vista puede cerrarse con la tapa a medias; la animación `BOX_C4_OPEN` **continúa** y termina con el jugador en `exploración`. La lectura de `I-07` la pide 9 al final (si el jugador ya salió, la petición a 7 se gestiona por el contrato de lectura de 7/20; no es asunto de la caja).
14. **«Compartimento completado» llega y la vista sigue `Abierta`.** El cierre espera a «vista cercana cerrada» (regla 14); nunca se cierra la tapa «delante» de la cámara.
15. **Consola/orden de 21 abre una vista de un puzle `BLOQUEADO` o `RESUELTO`.** El marco ejecuta su red de seguridad (regla 7 de 9). La caja no hace nada (no hay animación asociada porque no pasó por `interact()`).
16. **Valores de datos fuera de rango** (`BOX_Cn_OPEN` > 1,6 s o `Margen` < `margen_min`): error de datos en la carga; en desarrollo falla visible; en la demo se recorta a 1,6 s y se registra (decisión local, **más laxa** que la regla 29 de 9, donde el error de datos es fallo de carga; ver Cambios requeridos). Nunca se supera el token de 3 s.
17. **Degenerado: spam de pulsaciones durante `ABRIENDO`.** El contexto está bloqueado (regla 19 de 7): se descartan. Spam sobre un `BLOQUEADO`: `SIN_EFECTO` sin coste. No hay estrategia dominante: el orden de C1/C2 es libre y es una elección legítima (*Autonomía como progresión*); C3 → C4 es secuencial por diseño (D-16).
18. **Orden P4 antes que P3.** Válido (regla 24 de 9). `I-05` llega antes que `I-06a`; la caja no impone orden.
19. **Dos avisos «compartimento completado» seguidos** (p. ej. C1 y C2 resueltos con la ayuda de pistas en el mismo fotograma, improbable): se encolan y cada cierre empieza cuando le toca (regla 14); los cierres no se bloquean entre sí.

## Dependencies

Tipos: **Dura** = no funciona sin ella; **Blanda** = mejora la experiencia. «→» = la caja recibe; «←» = la caja ofrece. Cada fila cita la regla/AC en ambos lados (si el GDD del otro lado aún no existe, queda en «Cambios requeridos»).

| Sistema | Tipo | Dirección y contrato | Regla/AC en este GDD | Regla/AC en el otro GDD |
|---|---|---|---|---|
| 3 Estado y bus | Dura | → lee `caja_c1`–`caja_c4` (solo para reconstruir la pose); `caja_completa` es derivado de 3 y la caja no lo toca | Reglas 3, 6, 19 | Regla 7 de 3, CA-07 y CA-14; fila «10 Caja y compartimentos» de su tabla de dependencias |
| 7 Interacción e inspección | Dura | ← manejadores de `D01a`–`D01d` (`can_interact`, `interact`); usa `bloquear_contexto`/`liberar_contexto`, `abrir_vista(id, desde_token)`; → «vista cercana abierta/cerrada» | Reglas 7 a 11, 14 | Reglas 3, 19, 23 y 30 de 7; F4; AC-27, AC-27b; `BOX_OPEN_MAX` consumido por 7 en Tuning Knobs y F4 (D7-62; la sustitución de `BOX_Cn_OPEN` consta en 7) |
| 9 Marco de puzles | Dura | → `get_view_gate`, «puzle activado» `{puzzle, ajar_cm?}`, `EV_PUZZLE_SOLVED_*`, «compartimento completado» (n); ← `play_open(4)`, `set_final_pose(n)` (llamada desde `restore_solved_presentation()` de cada controlador), anclajes y nodos donde cuelgan los controladores | Reglas 3, 8, 11, 12, 14 a 16 | Reglas 7, 8, 16.5, 17, 18, 19, 24 y 35 de 9; AC-03, AC-17 y AC-49; fila «10 Caja y compartimentos ‡» |
| 4 Escena de planta | Dura | ← el nodo `D01` vive en la escena de D y se configura en el paso 6 (iii) del arranque, después de 9; → recarga completa de la escena | Regla 5 | Regla 8 y regla 9, paso 6 de 4 |
| 5 Guardado y carga | Blanda | La caja no guarda ni pide guardar; el guardado por `compartment_done:<n>` es un aviso de 9 | Regla 23 | Reglas 5 y 6 de 5 |
| 20 Documentos y bolsillo | Blanda | ← decorado `NOTA_01`, papel de `I-05` y carta plegada (no interactivos); 20 deriva los ítems de los hechos (R5, R24) y es dueño de `tarjeta_B`, `tarjeta_D`, `formulario_leido`; la caja no consulta `has_item`. `I-05`/`I-06a` no tienen presentación nueva (R13 y D20-19 de 20; Pregunta abierta 7, cerrada) | Reglas 17, 18 | R5, R6, R13, R24 y Q2 de 20 (fila de 9 y fila «10 Caja y compartimentos» en su tabla, Blanda; ronda 5) |
| 23 Director de audio | Blanda | ← fuente 3D `SPK_D01C`, `SFX_BOX_WOOD_OPEN` y `SFX_BOX_WOOD_CLOSE`; 23 reproduce `VO_G_07` en el altavoz | Reglas 17, 22 | Pendiente |
| 13–16 Puzles 3 a 6 | Dura | ← anclajes y nodos de cada puzle; → los controladores llaman a `play_open(4)` (P6) | Reglas 10, 11 | Pendiente |
| 21 Director de escenas | Indirecta (no hay llamada ni aviso de 10 a 21; 21 no la lista) | No hay llamada directa: 21 lee `caja_completa` de 3 | Regla 19 | Regla 7 de 3 (fila de 21) |
| 1 Entrada y controles | Indirecta (10 la declara; 1 no lista a 10; antes «Dura (indirecta)», etiqueta incoherente) | El token de `bloquear_contexto` declara una transición bloqueante de Entrada; el tope de 3 s es el de Entrada | Reglas 9, 21; F1 | Regla 8 y F8 de Entrada; tope 3–5 s |
| 2 Jugador en primera persona | Indirecta (así la lista el índice; 2 no lista a 10) | La cámara la cede 7 (`ceder_camara`); la caja no la toca | Regla 10 | Contrato de cesión de cámara de 2 |
| 17 Sistema de pistas | — | Sin relación: las pistas no mueven la caja salvo por `AUTO_SOLVE_ELEMENT` vía 9 | Edge case 6 | AC-43 de 9 |

## Tuning Knobs

Fichero propuesto: `assets/data/box/box.json` (los de 9 —`ajar_cm`, `close_view_after_s`— viven en el JSON de puzles de 9). Categorías: **F** = feel, **C** = curve, **G** = gate.

| Knob | Cat. | Defecto | Rango seguro | Qué afecta / razonamiento |
|---|---|---|---|---|
| `BOX_OPEN_MAX` | F | **1,6 s** | 1,2–1,6 | **Dueño: 10** (registro; F2). Tope de `BOX_C1_OPEN..C4`: `T_tope_mín − t_entrada_máx − margen_min` = 3,0 − 1,2 − 0,2. 7 lo **consume** (Tuning Knobs y F4 de 7, D7-62); no es una constante de 7. No sube con el tope de Entrada (F2) |
| `BOX_C1_OPEN` | F | **1,6 s** (slice B.3) | 1,2–1,6 | Peso del gesto de abrir D01a. Tope por F2 |
| `BOX_C2_OPEN` | F | **1,4 s** (slice B.4) | 1,2–1,6 | Idem D01b |
| `BOX_C3_OPEN` | F | 1,4 s† (propuesta) | 1,2–1,6 | Idem D01c; menor que C1 porque ya parte de 2 cm entreabierta (D10-1) |
| `BOX_C4_OPEN` | F | 1,6 s (slice B.6) | 1,2–1,6 | Tapa del P6 en la presentación de resolución (no entra en `T_cadena`). Mismo rango por coherencia con el registro |
| `margen_min` | G | 0,2 s | 0,1–0,2 | Holgura mínima de `T_cadena` frente al tope de Entrada (validación de datos). Con >0,2 el peor caso de C1 (2,8 s) sería error de datos |
| `BOX_Cn_CLOSE` (n = 1–3) | F | 0,8 s† (propuesta) | 0,4–1,2 | Duración del cierre tras resolver; no bloqueante |
| `close_delay_s` | F | 0,3 s† (propuesta) | 0–1,0 | Pausa entre «vista cerrada» y el cierre para que el jugador vea cerrarse la tapa |
| `ajar_s` | F | 0,6 s† (propuesta) | 0,3–1,2 | Velocidad del entreabierto de C3 (`ajar_cm` es de 9, 2 cm, rango 1–4) |
| `ajar_visible_dist_m` | G | 2,0 m† (propuesta) | 1,0–3,0 | Distancia máxima a la que D01c cuenta como «visible» para animar el entreabierto (regla 12) |
| `reopen_skips_animation` | G | `true` | bool | Con `false` cada reapertura repite `BOX_Cn_OPEN` (peor ritmo al reintentar; no recomendado) |
| `locked_text_key` (C3, C4) | F | vacío | vacío o clave de 18 | Texto de pie al pulsar un compartimento bloqueado. Vacío = solo sonido (D10-8) |
| `c4_stays_open` | G | `true` | bool | Regla 35 de 9 y línea `VO_G_13D`. Con `false` C4 pasaría a `FINAL_CERRADO` (rompería la línea) |

† = valor propuesto por este GDD sin fuente en el slice: se valida en playtest antes de fijarlo. Los vigilantes de recuperación (`BOX_Cn_CLOSE + 1,0 s`) son también propuestas.

Referencias a valores de otros sistemas: `t_vista_entrada_s` de `D01a`–`D01d` (7; ≤ 1,2 s), tope de transición (Entrada F8; 3 s), `t_devolver` (2; 0,5 s), `close_view_after_s` y `ajar_cm` (9).

## Visual/Audio Requirements

Requisitos de diseño para art y audio (no dirección artística; la decide art/audio-director):

- **Material y escala.** Nogal, 0,50 × 0,30 × 0,20 m (D01 en el slice, Anexo A). Cada compartimento debe ser **identificable sin explicarse** (cuatro huecos distintos: bandeja con marco, tablero, marco con espejo y altavoz, panel con tres botones) para que el jugador sepa a cuál va antes de pulsar (*Autonomía como progresión*).
- **Sin código moral en la caja.** Ningún color, luz ni símbolo distingue las variantes A/B/C de la carta ni un compartimento «bueno» (*Ambivalencia sin moral binaria*).
- **Sonido.** Madera para la caja (slice, sonidos de puzle): `SFX_BOX_WOOD_OPEN` y `SFX_BOX_WOOD_CLOSE` (propuestos, ver «Entradas para el registro»); `SFX_UNLOCK_SOFT` (9), `SFX_CLICK_SUBTLE` (7), `SFX_LOCK_CLICK` (P6) existen en el slice B.7. La caja no añade música ni *stinger* al completar un compartimento (*El espacio expresa la emoción*: silencio como lenguaje).
- **Altavoz de C3.** `SPK_D01C` debe sonar como si saliera de la caja (cercano, con timbre de altavoz pequeño o de madera) y respetar el volumen de voces del jugador (23). La voz del Guardián no suena ni amable ni amenazante (*Ambivalencia*).
- **Entreabierto de C3.** El movimiento de 2 cm debe verse desde la posición habitual del jugador a ~0,6–1,0 m del escritorio; si no se distingue, subir `ajar_cm` en 9 (rango 1–4).
- **Accesibilidad.** Sin parpadeos ni destellos en aperturas; las animaciones son lentas y suaves. Si existe la opción `reducir_movimiento` (regla 11 de 4), la caja puede acortar `ajar_s` y los cierres, pero **no** `BOX_Cn_OPEN` por debajo del rango (Pregunta abierta 5).

## Acceptance Criteria

Tipos: **L** = lógica (prueba automática, `tests/unit/box/`), **I** = integración (`tests/integration/box/`), **PV** = playtest o verificación visual con captura retenida en `production/qa/evidence/`, **R** = revisión de código / análisis estático (no es una prueba en tiempo de ejecución). Los PV de playtest son **observaciones cualitativas**: con n pequeño no se fijan umbrales estadísticos. Los valores marcados † son propuestas: el AC comprueba que se usa el valor de datos, no que sea el definitivo.

- **AC-01 (R7, L)**: **GIVEN** `get_view_gate` de `D01c` = `BLOCKED` (`caja_c1` falso), **WHEN** 7 consulta `can_interact`, **THEN** devuelve `SIN_EFECTO`, nunca `NO`; **GIVEN** `OPEN`, **THEN** `SI`; **GIVEN** `SOLVED`, **THEN** `SIN_EFECTO`.
- **AC-02 (R8, L)**: **GIVEN** `D01c` `BLOQUEADO`, **WHEN** el jugador pulsa, **THEN** no se llama a `bloquear_contexto`, `abrir_vista` ni a ninguna animación de tapa de la caja, 7 reproduce `SFX_CLICK_SUBTLE` sin texto, y la caja no lee `feedback_sfx`/`feedback_text_key` de `get_view_gate`. (El gesto `HAND_REACH` de 7, si se reproduce, no cuenta.)
- **AC-03 (R9, I)**: **GIVEN** `D01a` `ACTIVO` y `CERRADO`, **WHEN** el jugador pulsa, **THEN** se obtiene un token, `SFX_BOX_WOOD_OPEN` suena en t = 0, la animación dura 1,6 s, y en el mismo paso al terminar se llama a `abrir_vista("D01a", desde_token)`; no hay ningún fotograma en `exploración` entre las dos fases.
- **AC-04 (R9, F1, I)**: **GIVEN** `D01a` con `t_vista_entrada_s` = 1,2 s, **WHEN** se mide desde la pulsación hasta «vista cercana abierta», **THEN** ≤ 2,8 s, sin que Entrada libere el contexto antes (tope 3 s).
- **AC-05 (R9.5, I)**: **GIVEN** `D01a` `ABIERTO` tras `atrás` sin resolver, **WHEN** el jugador pulsa, **THEN** no hay `BOX_C1_OPEN`, no hay token, `abrir_vista("D01a")` se llama desde `exploración` y la primera acción llega en `t_vista_entrada_s`.
- **AC-06 (R9.4, L)**: **GIVEN** `abrir_vista` devuelve `RECHAZADA`, **THEN** se llama a `liberar_contexto(token)`, queda `ABIERTO`, se registra el motivo y el contexto vuelve a `exploración`.
- **AC-06b (R9.4, L)**: **GIVEN** `caja_c2` pasa a verdadero (consola) con `D01b` en `ABRIENDO`, **WHEN** termina la animación, **THEN** se reconsulta `get_view_gate` (= `SOLVED`), se llama a `liberar_contexto(token)`, **no** se llama a `abrir_vista`, y el cierre empieza a `close_delay_s`† del aviso (rama de F4).
- **AC-07 (R9.2, L)**: **GIVEN** `bloquear_contexto` devuelve `nulo`, **THEN** `interact()` devuelve `SIN_EFECTO`, no se anima y se registra un error.
- **AC-08 (R11, I)**: **GIVEN** `D01d` `ACTIVO`, **WHEN** el jugador pulsa, **THEN** no hay animación previa ni token y `abrir_vista("D01d")` se llama directamente; **WHEN** se resuelve el P6, **THEN** `play_open(4)` se reproduce tras `SFX_LOCK_CLICK` (0,3 s) y dura `BOX_C4_OPEN`; la carta es visible a t = 1,9 s.
- **AC-09 (R12, I)**: **GIVEN** `caja_c1` pasa a verdadero con el jugador en la vista de `D01a`, **THEN** «puzle activado» (P5) lleva `ajar_cm` = 2, `SFX_UNLOCK_SOFT` suena una vez (9, AC-03 de 9) y el entreabierto de 2 cm no se anima durante la vista; **WHEN** el contexto es `exploración`, `VIS_D01C` está dentro del frustum de la cámara y a ≤ `ajar_visible_dist_m`, **THEN** empieza a animarse (con `VIS_D01C` fuera de frustum o más lejos, no).
- **AC-10 (R13, L)**: **GIVEN** `caja_c1`, `c2` verdaderos y `c3` falso, **WHEN** P6 pasa a `ACTIVO`, **THEN** C4 no se mueve (sin entreabierto) y solo suena `SFX_UNLOCK_SOFT` (9).
- **AC-11 (R14, F4, I)**: **GIVEN** P3 resuelto con la vista `Abierta`, **WHEN** llega «compartimento completado» (1), **THEN** la tapa no se mueve hasta «vista cercana cerrada» + `close_delay_s`, se anima `BOX_C1_CLOSE` (valor de datos, 0,8 s† por defecto) con `SFX_BOX_WOOD_CLOSE`, sin token ni bloqueo de contexto; la pose final es `FINAL_CERRADO`.
- **AC-12 (R9 de 9, R14, I)**: **GIVEN** P5 en el paso `LINE` de `RESOLVING` con la vista abierta, **WHEN** el jugador sale (`atrás`), **THEN** no se escribe `caja_c3` ni se emite «compartimento completado», C3 queda `ENTREABIERTO` (mismo estado que tras cargar, N5-1) sin cierre, `pendiente_revelacion` sigue verdadero; **WHEN** pulsa C3 de nuevo, **THEN** `ENTREABIERTO → ABRIENDO` con `BOX_C3_OPEN` y 9 reproduce la secuencia desde el principio. **Y** (solo consola) **GIVEN** `caja_c3` escrito por consola con la vista cerrada, **THEN** el cierre empieza a `close_delay_s`† del aviso.
- **AC-13 (R16, I)**: **GIVEN** P6 resuelto con las variantes A, B y C por separado, **THEN** C4 queda `FINAL_ABIERTO` con la tapa abierta y la carta dentro; ninguna diferencia visible ni audible entre variantes.
- **AC-14 (R5, R6, L)**: **GIVEN** una carga con `caja_c1` y `caja_c2` verdaderos, `caja_c3` falso y P5 `ACTIVO`, **THEN** C1 y C2 en `FINAL_CERRADO`, C3 en `ENTREABIERTO` sin sonido ni animación, C4 `CERRADO`; **y** no se emite ningún aviso, no se llama a `bloquear_contexto` y el log no contiene errores ni advertencias.
- **AC-15 (R5, R6, L)**: **GIVEN** `caja_c4` verdadero al cargar, **THEN** C4 `FINAL_ABIERTO` sin animar, y 9 no emite `EV_PUZZLE_SOLVED_P6` ni «compartimento completado» (AC-02 de 9).
- **AC-16 (R15, L)**: **GIVEN** `set_final_pose(n)` para cada n llamada desde el `restore_solved_presentation()` del controlador, **THEN** la tapa y el decorado se colocan en el mismo fotograma sin animar ni sonar, de forma idempotente, y la caja no toca nada que sea del puzle (marco interior, fichas, silueta).
- **AC-17 (R19, R)**: **GIVEN** el código de la caja, **THEN** ninguna línea escribe, emite ni se suscribe a `caja_completa` (análisis estático); y (L) **GIVEN** `caja_c4` verdadero, el aviso de `caja_c4` precede al de `caja_completa` (CA-14 de 3) y la caja no cambia de pose por ello.
- **AC-18 (R20, PV)**: **GIVEN** la caja completa, **WHEN** el jugador la observa, **THEN** no aparece ninguna luz, sonido ni animación de «completado» propios de la caja. Playtest (cualitativo): se anota si algún jugador describe que el juego «anuncia» que ha terminado y si reconoce la llamada como consecuencia de salir de D.
- **AC-19 (R18, R)**: **GIVEN** el código de la caja, **THEN** no hay ninguna llamada a `has_item`, ni escritura de ítems ni de `tarjeta_B`/`tarjeta_D`/`formulario_leido`/`caja_cn`, ni lectura del bolsillo (análisis estático).
- **AC-20 (R17, I)**: **GIVEN** la secuencia de P5 en el paso `LINE`, **THEN** `VO_G_07` suena desde `SPK_D01C` (la posición 3D es la del altavoz del compartimento) y la caja no temporiza ni espera la línea.
- **AC-21 (R22, I)**: **GIVEN** pausa abierta durante `BOX_C1_OPEN`, **WHEN** se reanuda, **THEN** la animación y su sonido continúan desde donde estaban y `T_cadena` no excede 2,8 s de tiempo de juego. **Bloqueado hasta verificar en el editor** (NOT SOURCEABLE, Pregunta abierta 4): el AC no se da por superado sin esa verificación.
- **AC-22 (R21, L)**: **GIVEN** `box.json` con `BOX_C1_OPEN` = 1,8 s o `Margen` < 0,2 s, **THEN** la validación de datos lo rechaza (error en desarrollo; recorte a 1,6 s y aviso en la demo).
- **AC-23 (R14, L)**: **GIVEN** `get_view_gate` de `D01a` = `SOLVED`, **WHEN** el jugador pulsa, **THEN** `SIN_EFECTO` con `SFX_CLICK_SUBTLE`, la tapa de C1 no se mueve y la vista no se abre (regla 35 de 9).
- **AC-24 (R2, PV)**: **GIVEN** una sesión de playtest, **THEN** se anota si algún jugador atribuye una tapa que no se abre a un fallo del juego (sensación «el juego no responde») y el orden en que abre C1/C2. Observación cualitativa; no mide los puzles 3–6, solo la lectura de la caja.
- **AC-25 (R9, F6, I)**: **GIVEN** un reloj de juego falso, **WHEN** se pulsa un compartimento en los casos `SI` y `SIN_EFECTO`, **THEN** el primer sonido se pide en ≤ 1 paso de física (< 0,5 s). Captura de vídeo opcional como refuerzo (PV).
- **AC-26 (R4, L)**: **GIVEN** C3 `ENTREABIERTO` con la animación de entreabierto a mitad (o diferida), **WHEN** el jugador pulsa, **THEN** esa animación se cancela, `BOX_C3_OPEN` parte de la posición real de la tapa y la cadena F1 no supera 2,8 s.
- **AC-27 (R4, R11, L)**: **GIVEN** P6 resuelto, **THEN** C4 sigue `CERRADO` entre t = 0 («compartimento completado» 4) y `play_open(4)` (t = 0,3 s), pasa a `ABRIENDO` y termina en `FINAL_ABIERTO`; **GIVEN** la vista de `D01d` se cierra con `final_pendiente[4]` y la pose aún `CERRADO`, **THEN** se coloca `FINAL_ABIERTO` sin animar.
- **AC-28 (R4, L)**: **GIVEN** la señal de fin de animación no llega (fake), **THEN** `ABRIENDO` (al vencer el token de 3 s) pasa a `ABIERTO` sin llamar a `abrir_vista`, `CERRANDO` y `play_open(4)` pasan a su pose final tras `+ 1,0 s`†, y se registra un error en los tres casos.
- **AC-29 (Edge 13, I)**: **GIVEN** `atrás` durante `BOX_C4_OPEN`, **THEN** la animación continúa hasta `FINAL_ABIERTO` con el jugador en `exploración`.
- **AC-30 (Edge 19, L)**: **GIVEN** dos «compartimento completado» seguidos (n=1 y n=2), **THEN** cada cierre empieza cuando le toca y son independientes.
- **AC-31 (R9.5, L)**: **GIVEN** `reopen_skips_animation = false` y `D01a` `ABIERTO`, **WHEN** se pulsa, **THEN** se repite `BOX_C1_OPEN` con token y la cadena vuelve a ser F1.
- **AC-32 (R9.5, R14a, I)**: **GIVEN** P3 resuelto y el jugador sale con `atrás` antes del `close_view_after_s`, **THEN** el cierre empieza a `close_delay_s`† de «vista cercana cerrada».
- **AC-33 (R8, L)**: **GIVEN** `reducir_movimiento` activa, **THEN** (pendiente de la Pregunta abierta 5) solo `ajar_s` y `BOX_Cn_CLOSE` se acortan y `BOX_Cn_OPEN` no sale de su rango.
- **AC-34 (R4, Edge 9, N5-1, L)**: **GIVEN** P5 en `RESOLVING` y la vista de `D01c` abierta, **WHEN** el jugador sale (`atrás`), **THEN** C3 queda `ENTREABIERTO`; **WHEN** se guarda y se carga con P5 `ACTIVO`, **THEN** C3 nace `ENTREABIERTO`: el estado lógico es el mismo con y sin carga, y la pulsación siguiente pasa a `ABRIENDO` en ambos casos.
- **AC-V1 (R4, R12, R14, PV)**: **GIVEN** capturas de cada pose (`CERRADO`, `ENTREABIERTO`, `ABIERTO`, `FINAL_CERRADO`, `FINAL_ABIERTO`) de los cuatro compartimentos, **THEN** son distinguibles entre sí y se retienen en `production/qa/evidence/`.

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D10-1 | `BOX_Cn_OPEN` es **por compartimento** (C1 1,6 s, C2 1,4 s, C3 1,4 s†, C4 1,6 s) y el 1,6 s del registro/7 pasa a ser el **tope** (F2). C3 = 1,4 s† (propuesta: el slice no da valor; B.7 solo lista C1–C4 sin C3) porque parte de 2 cm entreabierta | Valor único 1,6 s para los cuatro (modelo actual de 7) | El slice (B.3, B.4) da 1,6 y 1,4: un valor único lo contradice; el tope 1,6 conserva la cadena ≤ 2,8 s. Prevalece el slice |
| D10-2 | `BOX_C4_OPEN` = la **tapa del P6** (1,6 s), dentro de la presentación de resolución, **sin apertura previa** de la vista (regla 11) | Encadenar `BOX_C4_OPEN` antes de la vista como C1–C3 (regla 19 de 7) | El slice B.6 pone los tres botones antes y la tapa *después* de pulsar; 9 (regla 16.6) ya modela «0,3 s + 1,6 s» tras la resolución. Encadenar añadiría una tapa que se abre dos veces |
| D10-3 | Salir de la vista sin resolver deja el compartimento `ABIERTO`; la reapertura omite la animación (`reopen_skips_animation`) | Cerrar al salir y repetir 1,6 s cada vez | Repetir 1,6 s en cada reintento castiga el tanteo (*Tensión sin castigo*) y alarga el micro-loop; no cambia la regla de 7 (peor caso 2,8 s sigue acotado) |
| D10-4 | (Extensión del slice, pendiente de veto del creative-director, Pregunta abierta 8) C1–C3 se cierran tras resolverse (el cierre de C1 es del slice B.3; C2 y C3 se extienden por coherencia); el cierre espera a que la vista se cierre | Cierre inmediato al resolver; dejar todos abiertos | Cerrar con la cámara delante rompe la vista; el slice solo documenta C1, y tres compartimentos cerrados + uno abierto da a C4 su peso (*El espacio expresa la emoción*) |
| D10-5 | C4 queda **abierto** en las tres variantes de la carta | Cerrarlo; abrir/cerrar según variante | Regla 35 de 9 y `VO_G_13D`; una caja que cambia según la elección sería un indicador moral (*Ambivalencia*) |
| D10-6 | (Escenificación, pendiente de veto, Pregunta abierta 8) El entreabierto de C3 se anima **cuando D01c es visible en `exploración`**, no en el aviso | Animar en el aviso aunque la cámara esté en la vista de D01a | Si no se ve, el jugador no relaciona el sonido con el hueco; sin pistas de texto la caja debe «enseñar» (*Autonomía*, *El espacio expresa la emoción*). Cuesta ~1,5–2 s de retraso visual |
| D10-7 | C4 **no** se entreabre | Entreabrir 2 cm también (Open Question 5 de 9) | B.6 no lo pide; el frontal de C4 ya es el panel de botones |
| D10-8 | Pulsar un compartimento bloqueado: solo `SFX_CLICK_SUBTLE`, sin texto (`locked_text_key` vacío) | Pie «Todavía no» | Regla 7 de 9 (por defecto sin texto) y pilar *Autonomía*: las pistas son de 17, no de la caja. La clave existe como knob si el playtest lo pide |
| D10-9 | La caja **no** emite «compartimento completado» ni `caja_completa` | Que la emita la caja | D9-24 y regla 7 de 3: 9 posee el orden de escritura y 3 el derivado; 10 solo escenifica |
| D10-10 | Sin señal propia al completar los cuatro | Luz o sonido de «caja completa» | *Información incompleta* y el disparador del slice (D-03): salir de D con `caja_completa`; lo escenifica 21 |
| D10-11 | Los ítems de la caja no son interactuables por defecto; `NOTA_01` y el papel de `I-05` son decorado (D10-17) | Cada recompensa como objeto cogible | Ampliar el catálogo de 7 es cambio de alcance (35 entradas); se deja como Pregunta abierta 1 |
| D10-12 | Se temporiza con la señal de fin de animación, no con `Tween`/`SceneTreeTimer` | `create_timer` para el fin de `BOX_Cn_OPEN` | Misma razón que regla 36 de 9 (pausa y determinismo) |
| D10-14 | **P5 se alinea con 9 (reglas 17 a 19 y 8.1):** la secuencia solo corre con la vista abierta; salir la interrumpe sin escribir nada y `pendiente_revelacion` sigue verdadero al cargar. Se retira la resolución con el jugador lejos | Que 10 contemple la resolución de C3 con el jugador lejos y que 9 limpie `pendiente_revelacion` al cargar | Contrato cruzado decidido: es inalcanzable en juego normal y no comprobable por el camino real (solo consola) |
| D10-15 | La caja ignora `feedback_sfx`/`feedback_text_key` de `get_view_gate`; con `SIN_EFECTO` 7 pone `SFX_CLICK_SUBTLE` y el `texto` de su catálogo | Que 7 pase sfx/clave dinámicos de 9 | 7 regla 3 no tiene mecanismo; si 9 o 10 los necesitan, es cambio en 7 (Cambios requeridos) |
| D10-16 | `restore_solved_presentation()` es del `PuzzleController`; la caja ofrece `set_final_pose(n)` y solo coloca tapa y decorado | Que la caja implemente `restore_solved_presentation(n)` | 9 regla 9 y tabla de interfaz lo definen sin argumento; evita doble dueño. El interior del puzle es del controlador |
| D10-17 | La bandeja es parte de C1; `NOTA_01` (y el papel de `I-05` en C2) son decorado visible hasta el cierre, no se colocan al cargar; la lectura de `I-05`/`I-06a` no la presenta 10 | `NOTA_01` visible en `FINAL_CERRADO`; que 10 abra la lectura | Con la tapa cerrada no se vería; la lectura la haría 9 y cambia el ritmo de la escena 6. **Decisión confirmada por el usuario (2026-11-09, slice v0.4):** no hay presentación propia de `I-05` ni de `I-06a`; son decorado de la caja y se releen desde el bolsillo con `repasar_bolsillo()` (20 D20-19). Antes era una desviación del slice C.6 y la Pregunta abierta 7; queda cerrada |
| D10-18 | Máquina de poses completa: cancelar el entreabierto al pulsar, C4 `CERRADO → ABRIENDO → FINAL_ABIERTO` y recuperación sin señal de fin | Dejar las transiciones implícitas | Sin ellas hay ramas sin comportamiento definido (token vencido, aviso en t = 0 antes de `play_open`) |
| D10-19 | Reconsultar `get_view_gate` en el paso 4 de la regla 9 | No reconsultar (9 cierra la vista) | Evita entrada 1,0 s + salida 0,5 s inútiles; la reconsulta es barata |
| D10-20 | «Visible» = `VIS_D01C` en frustum y ≤ 2,0 m† en `exploración`, sin oclusión | Dejarlo indefinido; raycast de oclusión | Comprobable y barato; la caja está libre sobre el escritorio |
| D10-13 | La caja no es dueña de ningún hecho ni aviso nuevo | Hecho `box_pose_*` | Evita estado duplicado (regla 3 de 7/3); la pose es reconstruible de `caja_cn` y 9 |
| D10-21 | **(Ronda de corrección 2, N5-1)** C3 interrumpido en la secuencia de P5 y C3 cargado quedan en el mismo estado, `ENTREABIERTO` (decisión del autor del lote). | Dejar `ABIERTO` en sesión y `ENTREABIERTO` al cargar. | La pose visible no debe depender de haber cargado; la secuencia de P5 se repite desde el principio (regla 19 de 9) y necesita la tapa a medio abrir. Salir de la vista de C1–C3 por `atrás` sin resolver sigue dejando `ABIERTO` (regla 9.5, Edge 7). |
| D10-22 | **(W-9)** `BOX_OPEN_MAX` tiene fila propia en Tuning Knobs, dueño 10; 7 lo consume. | Constante de 7 (Tuning Knobs de 7, l. 458 anterior). | El registro lo asigna a 10 y el valor sale de F2 de 10. |
| D10-23 | **(Ronda de corrección 3, R6-1, R6-2)** `BOX_Cn_OPEN` se escribe siempre como «notación genérica de `BOX_C1_OPEN`…`BOX_C4_OPEN`» (no es constante del registro) y se retira el «actualizar» del registro, ya aplicado. Durezas de la tabla alineadas con lo que declaran los demás: 7, 9, 4 y 13–16 Dura; 20 Blanda (así la declara 20); 1 Indirecta (10 la declara; 1 la lista como «Dura (indirecta)»); 21 y 2 Indirectas (no hay llamada directa; el índice las trata así). 5 queda Blanda (así la declara 5) y el índice la lista como indirecta: pendiente de alinear en el índice | Mantener «Blanda» con 21 y 2 y «Dura (indirecta)» en la fila de 1 | Regla común: manda el GDD dependiente; una etiqueta «Blanda» sin llamada directa duplicaba lo que el índice llama indirecta |

## Preguntas abiertas

| # | Pregunta | Dueño | Estado |
|---|---|---|---|
| 1 | ¿`NOTA_01` (y quizá `I-05`) deben ser un objeto que el jugador **coge** de la bandeja (entrada nueva en el catálogo de 7 y recoger en 20), o llegan solos al bolsillo? Por defecto llegan solos y el decorado de la bandeja no es interactivo (D10-11). El pilar *Autonomía* sugiere cogerlas | Autor / 20 / 7 | Abierta. Cambia alcance del catálogo |
| 2 | ¿7 acepta que `D01d` no encadene la tapa antes de la vista (regla 11)? | Revisión de 7 | Abierta (cambio en 7 requerido) |
| 3 | `SFX_UNLOCK_SOFT` lo reproduce 9 en el aviso, pero el entreabierto se anima después (D10-6): ¿se acepta el desfase o 10 reproduce el sonido con la animación? | 9 / 10 | Abierta; por defecto se acepta el desfase |
| 4 | **NOT SOURCEABLE.** ¿La pausa (`SceneTree.paused`) detiene `AnimationPlayer`, sus señales de fin y sus sonidos en 4.7? No está cubierto por `docs/engine-reference/godot/`; no se asume ninguna respuesta (AC-21 bloqueado) | lead-programmer | Abierta (misma que la 4 de 9) |
| 5 | `reducir_movimiento` (4): ¿debe acortar las animaciones de la caja? Por defecto solo `ajar_s` y el cierre | ux-designer / accessibility | Abierta |
| 6 | Voz y altavoz: ¿`SPK_D01C` es un nodo de 10 o un bus virtual de 23? Por defecto, nodo de 10 que 23 referencia | 23 / audio-director | Abierta |
| 7 | ~~¿Se presentan `I-05` e `I-06a` al resolver P4/P3?~~ **Resuelta (decisión del usuario, 2026-11-09, D10-17; 20 D20-19; slice v0.4):** no; decorado de la caja, releíbles desde el bolsillo. | — | Cerrada (2026-11-09) |
| 8 | ¿Se confirman D10-4 (cerrar C2 y C3, el slice solo cierra C1) y D10-6 (entreabierto diferido hasta ver D01c) y los valores † (`BOX_C3_OPEN`, cierres, `ajar_s`)? | creative-director | Abierta. Escenificación, no pilares |

No hay ninguna pregunta que cambie pilares o tono; la 1 y la 7 pueden cambiar alcance (catálogo de 7, ritmo de la escena 6).

## Cambios requeridos en otros GDDs

No se ha editado ninguno. Para el siguiente paso del lote:

- **7 Interacción e inspección:** (a) regla 19, F4, fila `BOX_Cn_OPEN` de Tuning Knobs, D7-19/D7-43/D7-47/D7-52 y AC: la cadena aplica a `D01a`–`D01c`; **`D01d` no encadena** (D10-2); regla 19 de 7 (encadena `D01a`–`D01d`) y línea ~233 («`SIN_EFECTO` en `D01b`–`D01d`») contradicen las reglas 7 y 11 de 10; (b) `BOX_Cn_OPEN` pasa de valor único a **tope 1,6 s** con valores por compartimento; (c) `SIN_EFECTO` solo en `D01c`–`D01d` (C2 sin dependencias, D-16); (d) `abrir_vista` desde `exploración` sin token (reapertura, regla 9.5); (e) **`SIN_EFECTO` (regla 3 de 7): o bien 7 acepta `feedback_sfx`/clave del dueño, o bien 9 deja de definirlos para `D01a`–`D01d`** (hoy 10 los ignora, D10-15); (f) `HAND_REACH` con `SIN_EFECTO` de la caja: confirmar que es el comportamiento deseado; (g) catálogo: `t_vista_entrada_s` de `D01b`–`D01d` y `VIS_D01C`.
- **9 Marco de puzles:** (a) regla 24 y Open Question 5: `ajar_cm` no se aplica al P6 (D10-7); (b) `play_resolution` del P6 llama a `play_open(4)` de 10 tras `SFX_LOCK_CLICK` (regla 16.6); (c) cada `restore_solved_presentation()` llama a `set_final_pose(n)` de 10 (no es un método de la caja); (d) Dependencies: fila 10 con las reglas de esta página; (e) AC de «puzle activado» de P5: el entreabierto visible se difiere (D10-6); (f) fijar quién presenta `I-05`/`I-06a` (Q2 de 20; Pregunta abierta 7); (g) regla 29 de 9 (error de datos = fallo de carga) frente a Edge 16 de 10 (recorte en la demo): alinear.
- **3 Estado y bus:** sin cambios de contrato.
- **4 Escena de planta:** añadir `D01`/`SPK_D01C`, `VIS_D01C` y anclajes `ANC_D01A`–`ANC_D01D` a la lista del paso 6 (iii).
- **5 Guardado y carga:** ninguno.
- **20 Documentos y bolsillo:** hecho en la ronda de corrección 2 de 20 (R8/R13 sin presentación de 9/10 para `I-05`/`I-06a`, D20-19; fila «10 Caja y compartimentos», Blanda).
- **21 Director de escenas:** la rama «nunca abierta» de F4 solo ocurre por orden de consola/21.
- **23 Director de audio (futuro):** fuente `SPK_D01C` y los dos `SFX_BOX_WOOD_*`.
- **13 a 16 (futuros):** sus elementos cuelgan de los nodos de la caja; P6 llama a `play_open(4)`.
- **Registro (`design/registry/entities.yaml`):** `BOX_Cn_OPEN` es solo notación genérica de `BOX_C1_OPEN`…`BOX_C4_OPEN`; el valor único queda sustituido por esas cuatro constantes y `BOX_OPEN_MAX` (aplicado en 7, D7-62, y citado por Entrada F8 como «tope `BOX_OPEN_MAX` 1,6 s»). Sin cambios pendientes para 10 en el registro.
- **`systems-index.md`:** fila 10 ya figura en borrador/revisión; dependencias de 10: 3, 4, 7, 9 (duras), blandas 20, 23 (añadir 4, 20, 23).

## Entradas para el registro

Propuestas para `design/registry/entities.yaml` (no se ha editado):

```yaml
constants:
  - name: BOX_C1_OPEN      # sustituye el valor único BOX_Cn_OPEN
    value: 1.6
    unit: s
    range: [1.2, 1.6]
    source: design/gdd/caja-y-compartimentos.md
    note: "slice B.3; tope BOX_OPEN_MAX = 3,0 - 1,2 - 0,2"
  - name: BOX_C2_OPEN
    value: 1.4
    unit: s
    range: [1.2, 1.6]
    source: design/gdd/caja-y-compartimentos.md
    note: "slice B.4"
  - name: BOX_C3_OPEN
    value: 1.4
    unit: s
    range: [1.2, 1.6]
    source: design/gdd/caja-y-compartimentos.md
    note: "PROPUESTA (sin valor en el slice); D10-1; parte entreabierta 2 cm"
  - name: BOX_C4_OPEN
    value: 1.6
    unit: s
    range: [1.2, 1.6]
    source: design/gdd/caja-y-compartimentos.md
    note: "slice B.6; tapa en la resolucion del P6, fuera de T_cadena (D10-2)"
  - name: BOX_OPEN_MAX
    value: 1.6
    unit: s
    source: design/gdd/caja-y-compartimentos.md
    note: "F2; el antiguo BOX_Cn_OPEN de 7 pasa a ser este tope"
  - name: box_open_margin_min_s
    value: 0.2
    unit: s
    range: [0.1, 0.2]
    source: design/gdd/caja-y-compartimentos.md
  - name: BOX_Cn_CLOSE
    value: 0.8
    unit: s
    range: [0.4, 1.2]
    source: design/gdd/caja-y-compartimentos.md
    note: "PROPUESTA, validar en playtest"
  - name: box_close_delay_s
    value: 0.3
    unit: s
    range: [0.0, 1.0]
    source: design/gdd/caja-y-compartimentos.md
    note: "PROPUESTA, validar en playtest"
  - name: box_ajar_s
    value: 0.6
    unit: s
    range: [0.3, 1.2]
    source: design/gdd/caja-y-compartimentos.md
    note: "PROPUESTA, validar en playtest"
  - name: box_ajar_visible_dist_m
    value: 2.0
    unit: m
    range: [1.0, 3.0]
    source: design/gdd/caja-y-compartimentos.md
    note: "PROPUESTA; regla 12"
formulas:
  - name: box_chain_time        # T_cadena(n), F1
    output_range: [1.0, 2.8]
    source: design/gdd/caja-y-compartimentos.md
ids:                             # no son hechos
  - SFX_BOX_WOOD_OPEN
  - SFX_BOX_WOOD_CLOSE
  - SPK_D01C
  - VIS_D01C
  - ANC_D01B, ANC_D01C, ANC_D01D   # ANC_D01A ya figura en 7
interfaces:
  - play_open(n)                   # 10 -> llamado por el controlador del P6
  - set_final_pose(n)              # 10 -> llamado desde restore_solved_presentation() del controlador (9, reglas 8 y 35)
```

No se proponen hechos, avisos ni flags nuevos (D10-13).

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote Feature 1). |
| 2026-11-09 | Ronda de corrección 1 tras la revisión independiente (1 bloqueante, 14 avisos): P5 alineado con 9 (reglas 17 a 19, 8.1; D10-14), dependencia con 20 actualizada y lista `I-05`/`I-06a` resuelta (D10-17, Pregunta abierta 7), regla 8 sin `feedback_sfx` dinámico, bandeja de C1 definida, máquina de poses completa con recuperación, reconsulta en el paso 4, «visible» definido, `margen_min` 0,1–0,2, valores † como propuesta, ACs reescritos y ampliados (AC-06b, AC-26 a AC-33), `restore_solved_presentation` → `set_final_pose`, Cambios requeridos ampliados. Estado: Revisado, pendiente de re-review. |
| 2026-11-09 | Ronda de decisiones 1: D-B aprobada por el usuario: `I-05` e `I-06a` sin presentación nueva (decorado en 10), releíbles con el repaso del bolsillo (20); D10-17 pasa de desviación del slice C.6 a decisión confirmada con el slice v0.4; Pregunta abierta 7 cerrada. Sin otros cambios. Estado: pendiente de re-review. |
| 2026-11-09 | Ronda de corrección 2 (informe cruzado ronda 5: W-4, W-9, N5-1): fila propia de `BOX_OPEN_MAX` en Tuning Knobs, Dependencies de 1 y 20 corregidas, C3 interrumpido = `ENTREABIERTO` como al cargar (regla 4, Edge 9, AC-12, AC-34), D10-21 y D10-22. Estado: Revisado (ronda de corrección 2) — pendiente de re-review. |
| 2026-11-09 | Ronda de corrección 3 (informe cruzado ronda 6: R6-1, R6-2): `BOX_Cn_OPEN` como notación genérica de `BOX_C1_OPEN`…`BOX_C4_OPEN`, sin «actualizar» el registro (ya aplicado), 21 y 2 pasan a Indirecta (D10-23). Estado: Revisado (ronda de corrección 3) — pendiente de re-review. |
