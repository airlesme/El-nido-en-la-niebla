# Caja y compartimentos

> **Status**: Borrador (lote Feature 1) — pendiente de review
> **Author**: Game Designer (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el jugador abre los compartimentos en el orden que quiera dentro de las dependencias) · Tensión sin castigo (la caja nunca falla, nunca se atasca y nunca bloquea más de 3 s) · El espacio expresa la emoción (madera, cerraduras y un altavoz dentro de la caja dicen lo que nadie explica) · Información incompleta (la caja guarda objetos y una voz, no confirma intenciones)

## Summary

La caja de nogal del despacho del Guardián (`D01`) tiene cuatro compartimentos (`D01a`–`D01d`, `C1`–`C4`), uno por cada puzle 3 a 6. Este sistema es el **hardware** de la caja: decide cómo se ve, cómo suena y cuánto tarda cada compartimento en abrirse, entreabrirse, cerrarse o quedarse abierto, y encadena esa animación con el acercamiento de cámara de Interacción e inspección (7). **No decide cuándo se abre cada compartimento ni si el puzle está resuelto**: eso lo calcula el Marco de puzles (9) a partir de los hechos `caja_c1`–`caja_c4`; la caja solo obedece y lo escenifica.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `3 Estado y bus`, `7 Interacción e inspección`, `9 Marco de puzles` · Dueño de: manejadores de `D01a`–`D01d`, constantes `BOX_C1_OPEN`…`BOX_C4_OPEN`

## Overview

Caja y compartimentos es la capa de escenificación entre los puzles 3 a 6 y el mundo físico. Tiene un manejador por cada `D01a`–`D01d` que Interacción e inspección (7) consulta (`can_interact`) y activa (`interact`). Al pulsar sobre un compartimento disponible, la caja bloquea el contexto con un token (`bloquear_contexto`), anima la apertura (`BOX_Cn_OPEN`) y, al terminar, pide a 7 la vista cercana (`abrir_vista(id, desde_token)`), de modo que el jugador percibe un único gesto continuo: mano, tapa, acercamiento y puzle. Si el puzle no está disponible o ya está resuelto, la caja no anima nada y contesta `SIN_EFECTO`, según lo que diga `get_view_gate` del Marco (9).

La caja **no guarda hechos** ni escribe ninguno. Lee `caja_c1`–`caja_c4` y el estado público de cada puzle para saber qué postura (pose) enseñar, escucha los avisos de 9 («puzle activado» con `ajar_cm`, «compartimento completado» n) para saber cuándo entreabrir o cerrar, y presenta lo que cada compartimento contiene: una nota, una lista de tareas, una voz y una carta. La combinación «caja completa» (`caja_completa`) es un hecho derivado del Estado (3); la caja no lo emite ni reacciona a él.

## Player Fantasy

Vera no abre una caja: **la dejan entrar**. Cada compartimento es una capa de algo que el Guardián no se atrevió a decir en voz alta, guardado en nogal, con bisagras que ceden sin prisa y una madera que suena a despacho de noche. El jugador siente peso (el compartimento tarda lo que tarda una mano en tirar de una tapa), intimidad (la cámara se acerca sin cortes, como quien se inclina) y la certeza tranquila de que **la caja nunca se enfada**: si algo aún no se abre, no pasa nada; si se sale a medias, se vuelve; si se acierta, la madera se cierra o se queda abierta como decisión del objeto, no como premio.

Aesthetics del MDA: **Discovery** (qué hay en cada capa y en qué orden se lee), **Sensation** (madera, tapa, altavoz, luz del marco) y **Narrative** (una nota, una lista, una voz, una carta: una confesión a medias, sin explicarla). Necesidades SDT: **Autonomía** (C1 y C2 se abren en el orden que se quiera; la caja no empuja), **Competencia** (cada pulsación tiene una respuesta legible en menos de 0,5 s: sonido de bloqueo o inicio de apertura) y **Relatedness** (el Guardián habita el objeto: su letra, su voz, su carta).

**Test de pilar.** Si dudamos entre un texto que diga «completa los otros compartimentos primero» y un clic seco de madera que no abre, elegimos el clic (*El espacio expresa la emoción*, *Autonomía como progresión*: las pistas son de 17, no de la caja). Si dudamos entre una fanfarria al completar la caja y que la caja siga ahí, callada, elegimos que siga ahí (*Información incompleta*: el apagón al salir de D es la única señal; lo emite 21).

## Detailed Rules

Convención: «regla N de X» remite a la regla numerada del GDD del sistema X. Los tiempos son de **tiempo de juego** (la pausa los detiene; regla 36 de 9, regla 32 de 7).

### A. Propiedad y alcance

1. **Qué posee la caja (10).** El nodo `D01` y sus cuatro compartimentos (modelo, tapas, bandeja, altavoz, anclajes de cámara `ANC_D01A`–`ANC_D01D`), sus animaciones de apertura, entreabierto y cierre, los manejadores de `D01a`–`D01d` (regla 3 de 7) y las constantes `BOX_C1_OPEN`…`BOX_C4_OPEN`. **No posee:** los hechos `caja_c1`–`caja_c4` (los escribe 9, regla 16 de 9; dueño 3), el estado de los puzles (9), las piezas y reglas de cada puzle (13 a 16: piezas, fichas, ángulo θ, botones), los ítems y documentos (20), las líneas y su audio (18, 23), el hecho derivado `caja_completa` (3, regla 7).
2. **Los cuatro compartimentos.** Fuente: slice B.3–B.6 y C.6; dependencias: regla 24 de 9 (el slice D-16, pendiente de confirmar).

   | n | ID | Puzle | Hecho | Disponible cuando (lo decide 9) | Contiene (qué se ve) | Recompensa | Pose final |
   |---|---|---|---|---|---|---|---|
   | 1 | `D01a` | P3 · Encaje de la foto | `caja_c1` | Al entrar en D | Marco de seis huecos, bandeja con cinco piezas | `I-06a` (`NOTA_01`, «La transición es tuya») | `FINAL_CERRADO` |
   | 2 | `D01b` | P4 · Tablero de tareas | `caja_c2` | Al entrar en D (sin dependencias) | Tablero con cuatro fichas T1–T4 | `I-05` (lista de tareas del Guardián) | `FINAL_CERRADO` |
   | 3 | `D01c` | P5 · Espejo de la diferencia | `caja_c3` | `caja_c1` | Marco interior giratorio con superficie reflectante y un altavoz | `VO_G_07` (unos 14 s, desde el altavoz) | `FINAL_CERRADO` |
   | 4 | `D01d` | P6 · Decisión | `caja_c4` | `caja_c1`, `caja_c2` y `caja_c3` | Panel con tres botones (A «Estoy bien», B «La verdad», C «Todavía no»), cerradura y tapa | `I-07` (la carta) | `FINAL_ABIERTO` |

3. **La caja no decide disponibilidad.** Toda pregunta «¿se puede abrir ya?» se contesta con `get_view_gate(view_id)` de 9 (regla 7 de 9). La caja no lee `caja_cn` para decidir si abre; los lee **solo para reconstruir la pose** (regla 6). No contiene lógica de dependencias entre compartimentos (D9-11).

### B. Poses (estado de presentación, no son hechos)

4. **Pose de cada compartimento.** Valor de presentación en memoria, nunca guardado y nunca visible para otros sistemas como hecho:

   | Pose | Significado |
   |---|---|
   | `CERRADO` | Tapa cerrada, puzle `ACTIVO` o `BLOQUEADO` |
   | `ENTREABIERTO` | Solo C3: tapa separada `ajar_cm` cm (regla 11) |
   | `ABRIENDO` | `BOX_Cn_OPEN` en curso (C1–C3 al pulsar; C4 durante la resolución) |
   | `ABIERTO` | Tapa abierta, puzle sin resolver (o C4 recién resuelto, antes de ser estado final) |
   | `CERRANDO` | Animación de cierre tras resolver (C1–C3) |
   | `FINAL_CERRADO` | C1–C3 resueltos y cerrados |
   | `FINAL_ABIERTO` | C4 resuelto, tapa abierta con la carta dentro |

   Transiciones: `CERRADO → ABRIENDO → ABIERTO` (pulsación con `get_view_gate` = `OPEN`); `CERRADO → ENTREABIERTO` («puzle activado» de P5 con `ajar_cm`); `ENTREABIERTO → ABRIENDO`; `ABIERTO → CERRANDO → FINAL_CERRADO` («compartimento completado» n=1–3, regla 12); `ABIERTO → FINAL_ABIERTO` (n=4, regla 13). **Nunca hacia atrás:** un `FINAL_*` no cambia (S2 de 9, regla 28 de 9). Salir de la vista sin resolver **no** cierra el compartimento (regla 9, paso 5).
5. **Configuración al arrancar `planta`.** En el orden de arranque 7 → 9 → resto (regla 9, paso 6 de 4), la caja se configura **después** de 9 y reconstruye la pose **de forma síncrona y sin animar, sin sonar y sin emitir nada**, leyendo hechos y estado de 9. No guarda ni restaura nada propio. Si 9 falla la validación de datos, la caja no se configura (fallo de carga inmediato, 4).
6. **Pose inicial según hechos.**
   - `caja_cn` verdadero → `FINAL_CERRADO` (n=1–3) o `FINAL_ABIERTO` (n=4), con su contenido final (regla 15).
   - P5 `ACTIVO` y `caja_c3` falso → C3 en `ENTREABIERTO` (`ajar_cm` de la definición, 2 cm) sin sonido (regla 8 de 9: pasa a `ACTIVO` en silencio).
   - Cualquier otro caso → `CERRADO`.
   - Con `pendiente_revelacion` verdadero al guardar, 9 lo limpia al configurarse; la caja deja C3 en `ENTREABIERTO` y el jugador la reabre (el progreso parcial no se persiste, D9-8).

### C. Interacción y apertura

7. **Disponibilidad ante 7 (`can_interact`).** Siempre `SI` o `SIN_EFECTO`, **nunca `NO`** (el compartimento sigue habilitado para 7; regla 7 de 9). `SI` si `get_view_gate` devuelve `OPEN`; `SIN_EFECTO` si `BLOCKED` o `SOLVED`. Verbo corto `ABRIR` (`UI_VERBO_ABRIR`) siempre, sin cambio de etiqueta con el estado.
8. **Respuesta `SIN_EFECTO`.** 7 reproduce `feedback_sfx` de `get_view_gate` (por defecto `SFX_CLICK_SUBTLE`) y, si hay `feedback_text_key`, el pie de texto. **Por defecto sin texto en C3 y C4** (D10-8). La caja **no anima, no abre la vista y no mueve ninguna tapa** en este caso: no hay acercamiento de cámara inútil ni «tirón» de la tapa. Vale igual para un compartimento resuelto: no reabre su vista (reglas 7 y 35 de 9).
9. **`interact()` de C1, C2 y C3 con `OPEN` (secuencia encadenada, regla 19 de 7).** En el mismo paso de la pulsación (dentro de `interact()`, requisito de `bloquear_contexto`, regla 30 de 7):
   1. Se consulta `get_view_gate`; si no es `OPEN`, se devuelve `SIN_EFECTO` (regla 8). Si pasa, la caja **no** vuelve a consultarlo hasta el paso 4.
   2. **Pose `CERRADO` o `ENTREABIERTO`:** `token = bloquear_contexto("D01x")`. Si devuelve `nulo`, se devuelve `SIN_EFECTO`, no se anima nada y se registra el error (no hay softlock: nada quedó bloqueado).
   3. Pose `ABRIENDO`: animación `BOX_Cn_OPEN` (duración por compartimento, regla 21), sonido `SFX_BOX_WOOD_OPEN` en t = 0. `D01a`–`D01d` **no declaran `gesto_hecho`**: la animación del compartimento es el gesto (regla 3 de 7).
   4. Al terminar la animación (señal de fin de la animación, no un temporizador de fotograma): pose `ABIERTO` y `abrir_vista(id, desde_token = token)`. Si `ACEPTADA`, el bloqueo se **transfiere** a la cámara sin soltarse (regla 19 de 7). Si `RECHAZADA(motivo)`, la caja llama a `liberar_contexto(token)`, registra el motivo y deja el compartimento `ABIERTO` (el jugador puede volver a pulsar y se aplica el paso 5).
   5. **Pose `ABIERTO` (reapertura tras `atrás`):** no hay animación ni token. La caja llama directamente a `abrir_vista(id)` desde `exploración`. `T_cadena` = solo `t_vista_entrada_s` (F1).
   6. Se devuelve `HECHO`.
10. **Vista y gestos.** La caja **no** interviene en la vista cercana: la abre 7, la sirve el receptor que 9 registró para el ID (regla 30 de 7), y el cursor y los gestos son de 7 y Entrada. La caja solo aporta el anclaje de cámara `ANC_D01x`, **perpendicular al plano del puzle** (condición de la regla 19 de 7), y los nodos donde cuelgan los elementos de cada puzle. Cerrar con `atrás` o con `cerrar_vista` sigue la regla 23 de 7 sin intervención de la caja.
11. **Compartimento 4 (`D01d`): sin apertura previa.** El panel de tres botones y su cerradura están en el **frontal** del compartimento (slice B.6: la tapa se abre *tras* pulsar). Por tanto `interact()` de C4 con `OPEN` salta los pasos 2 a 4 de la regla 9 y llama a `abrir_vista("D01d")` directamente desde `exploración` (sin token). `BOX_C4_OPEN` (tapa, 1,6 s) se reproduce **dentro de la presentación de resolución del P6**: la caja ofrece `play_open(4)`, que el controlador del P6 llama desde `play_resolution` **tras** `SFX_LOCK_CLICK` (0,3 s) (regla 16.6 de 9). La caja no inicia esa animación por su cuenta ni escribe nada. `T_cadena(4)` = `t_vista_entrada_s` (F1).

### D. Entreabierto de C3

12. **«Puzle activado» de P5 con `ajar_cm`** (regla 24 de 9). El sonido `SFX_UNLOCK_SOFT` lo reproduce 9 en el aviso. La caja desplaza la tapa de C3 `ajar_cm` cm a lo largo de `ajar_s` (F4) **en cuanto D01c es visible para la cámara de Vera en `exploración`**; si en el aviso el jugador está en la vista cercana de `D01a` (el caso normal: `caja_c1` se escribe ahí), la animación espera a que se devuelva la cámara. Pose lógica `ENTREABIERTO` desde el aviso; solo la animación se difiere. El estado `ENTREABIERTO` no cambia `can_interact` (lo decide 9).
13. **C4 no se entreabre.** `ajar_cm` no se aplica al P6 (B.6 no lo pide; regla 24 de 9). Decisión en «Decisiones tomadas»; la Open Question 5 de 9 queda resuelta en ese sentido salvo veto del creative director.

### E. Cierre y estado final

14. **Cierre de C1–C3.** Al recibir «compartimento completado» (n=1–3) de 9 (emitido tras `EV_PUZZLE_SOLVED_*`, regla 16.5 de 9): se marca `cierre_pendiente[n]`. El cierre **empieza** `close_delay_s` después de que se cumpla lo primero de: (a) la vista de `D01x` no está `Abierta` (se emite «vista cercana cerrada», que 9 pide tras `close_view_after_s` con motivo `resuelto`, o la cierra el jugador con `atrás`, o ya estaba cerrada); (b) la vista nunca estuvo abierta (P5 con el jugador lejos). Dura `BOX_Cn_CLOSE`, con `SFX_BOX_WOOD_CLOSE`, **sin token ni bloqueo** (es escenificación; el jugador puede moverse). Al terminar: `FINAL_CERRADO`. Si la animación de cierre se solapa con la de otro compartimento, son independientes.
15. **Contenido final visible (`restore_solved_presentation`, regla 35 de 9).** La caja implementa esa operación: coloca la pose final y el contenido final sin animar, tanto al cargar como si la presentación se interrumpió. Contenido: C1, sobre la bandeja, el papel `NOTA_01` (decorado no interactivo); C2, tablero con las cuatro fichas selladas, visible solo si el compartimento se ve (cerrado, no se ve); C3, marco interior alineado a θ* y silueta de Vera resaltada (lo fija el controlador, regla 17 de 9); C4, tapa abierta con la carta plegada dentro.
16. **C4 queda abierto** (regla 35 de 9; la línea `VO_G_13D` dice «Te he dejado la caja abierta»). `FINAL_ABIERTO` para todas las variantes de la carta (`carta_variante` A, B o C): la caja no distingue variantes (*Ambivalencia sin moral binaria*: ningún aspecto de la caja codifica la elección). Si «compartimento completado» (4) llega con la tapa aún animando, se deja terminar.

### F. Contenido y su relación con 7 y 20

17. **Recompensas.** Los ítems no son hechos (slice D.1): los deriva 20 de los hechos y del aviso `EV_PUZZLE_SOLVED_*` (campo `rewards`, regla 16 de 9). La caja **no** añade ni quita ítems; solo muestra el decorado:
    - C1: papel `NOTA_01` en la bandeja, que **no** es parte del compartimento y no se cierra con él (slice B.3: «En la bandeja aparece I-06a»). No es interactivo por defecto (Pregunta abierta 1).
    - C2: sin decorado propio; `I-05` solo en el bolsillo (20).
    - C3: la caja ofrece la fuente de audio 3D `SPK_D01C`, en el altavoz del compartimento; la secuencia de P5 (paso `LINE`, regla 20 de 9) la usa para `VO_G_07` y 23 la reproduce ahí. La caja no reproduce, no mide ni espera la línea.
    - C4: carta plegada dentro de la tapa, visible al abrirse. La lectura (`abrir_lectura(I-07)`) la pide 9 al final de su presentación (regla 16.6 de 9) y la gestiona 7/20.
18. **Con 20.** La caja no consulta `has_item` ni lee el bolsillo. Un ítem no abre ni bloquea ningún compartimento (la caja no tiene `needs_items`).

### G. «Caja completa»

19. **Quién la emite.** `caja_completa` es un hecho **derivado** de 3 (regla 7 de 3): `caja_c1` y `caja_c2` y `caja_c3` y `caja_c4`. Lo recalcula 3 cuando 9 escribe `caja_c4` (o el último de los cuatro); el aviso de `caja_c4` se entrega antes que el del derivado (CA-14 de 3). **La caja no lo escribe, no lo emite y no reacciona a él.** Lo lee 21 (apagón y llamada al cruzar el umbral de D; slice C.7) y 7 (`habilitado_si`).
20. **Sin señal de «completada».** Al completar el cuarto compartimento la caja no añade luz, sonido ni animación propios de «caja completa» (*Información incompleta*, *El espacio expresa la emoción*: la señal es la planta). La presentación del P6 (regla 11) es la del puzle, no una celebración.

### H. Tiempos

21. **Duraciones.** Valores por defecto y rango en Tuning Knobs. `BOX_Cn_OPEN` es **por compartimento** con **tope 1,6 s** (reconciliación del slice con 7, en Decisiones tomadas D10-1). Validación en datos: `BOX_Cn_OPEN[n] + t_vista_entrada_s(n) ≤ T_tope − margen_min` para n = 1–3 (F1); un valor fuera de rango es error de datos.
22. **Reloj.** Las animaciones de la caja corren con el tiempo de juego: el nodo de animación y los sonidos se pausan con `SceneTree.paused`. Que esto detenga las animaciones en 4.7 no está cubierto por `docs/engine-reference/godot/` (es la verificación pendiente de la Open Question 4 de 9; Pregunta abierta 4 aquí). Mientras no se verifique, la caja **no** usa `Tween` ni `SceneTreeTimer` para temporizar `BOX_Cn_OPEN` (usa la señal de fin de animación).
23. **Sin persistencia ni peticiones de guardado.** La caja no guarda ni pide guardar. El guardado por `compartment_done:<n>` (regla 6 de 5) lo dispara el aviso de 9; la instantánea espera a que la cola de avisos esté vacía (regla 5 de 5).

## Formulas

### F1 · Cadena de apertura (pulsación → primera acción en la vista)

`T_cadena(n) = BOX_Cn_OPEN[n] + T_entrada(n)` para n = 1, 2, 3 · `T_cadena(4) = T_entrada(4)` · `T_reapertura(n) = T_entrada(n)` (pose `ABIERTO`)
`T_entrada(n) = min(t_vista_entrada_s(n), t_transicion_max)` (F4 de 7)
`Margen(n) = T_tope − T_cadena(n)` · **Restricción de datos:** `Margen(n) ≥ margen_min`

**Variables:** `BOX_Cn_OPEN[n]` (s; 1,2–1,6), `t_vista_entrada_s(n)` (s; 0,6–1,2 en las vistas encadenadas, valor de 7), `T_tope` = tope único de transición de Entrada (F8 de Entrada; 3 s por defecto, rango seguro 3–5), `margen_min` = 0,2 s. El token de `bloquear_contexto` caduca a 3 s de tiempo de juego (regla 30 de 7); `BOX_Cn_OPEN` < 3 s siempre.

| n | `BOX_Cn_OPEN` | `T_entrada` 1,0 s (defecto) → `T_cadena` / margen | `T_entrada` 1,2 s (peor caso) → `T_cadena` / margen | Reapertura |
|---|---|---|---|---|
| 1 | 1,6 s | 2,6 s / 0,4 s | 2,8 s / 0,2 s | 1,0–1,2 s |
| 2 | 1,4 s (slice) | 2,4 s / 0,6 s | 2,6 s / 0,4 s | 1,0–1,2 s |
| 3 | 1,4 s | 2,4 s / 0,6 s | 2,6 s / 0,4 s | 1,0–1,2 s |
| 4 | — (la tapa va en la resolución) | 1,0 s / 2,0 s | 1,2 s / 1,8 s | 1,0–1,2 s |

`t_vista_entrada_s` de `D01b`–`D01d` los define el catálogo de 7 (el slice solo da 1,0 s para `D01a`); la tabla supone 1,0 s. Peor caso global: 2,8 s ≤ 3 s.

### F2 · Reconciliación `BOX_Cn_OPEN` (slice) ↔ valor único de 7

`BOX_OPEN_MAX = T_tope_mín − t_entrada_máx − margen_min = 3,0 − 1,2 − 0,2 = 1,6 s`

El slice da valores por compartimento (B.3: `BOX_C1_OPEN` = 1,6 s; B.4: `BOX_C2_OPEN` = 1,4 s); 7 modela **un único** `BOX_Cn_OPEN` = 1,6 s con rango [1,2; 1,6]. Se reconcilian así: **el 1,6 s de 7 es el tope (`BOX_OPEN_MAX`), no el valor de cada compartimento**; los valores reales son por compartimento y todos ≤ 1,6 s. Los de C1 y C2 vienen del slice; los de C3 (1,4 s) y C4 (1,6 s) los fija este GDD (D10-1, D10-2). Si Entrada sube su tope a 4 s, `BOX_OPEN_MAX` sube a 2,6 s pero **no** se usa: el rango de 7 y del registro sigue [1,2; 1,6].

### F3 · Entreabierto de C3

`x(t) = ajar_cm · suavizado(t / ajar_s)` para `t ∈ [0, ajar_s]`, con `suavizado(u) = 3u² − 2u³`; `ajar_cm` ∈ [1, 4] (lo fija 9), `ajar_s` ∈ [0,3; 1,2].
**Ejemplo:** `ajar_cm` = 2, `ajar_s` = 0,6: en t = 0,3 s, x = 1,0 cm; velocidad máxima = 1,5 · 2 cm / 0,6 s = 5 cm/s.

### F4 · Cierre de C1–C3

`t_inicio_cierre = max(t_aviso, t_vista_cerrada) + close_delay_s` · `t_fin_cierre = t_inicio_cierre + BOX_Cn_CLOSE[n]`
Si la vista nunca estuvo abierta: `t_vista_cerrada = t_aviso`.
**Ejemplo (P5 con `close_view_after_s` = 1,5 s, valor del ejemplo de 9; `t_devolver` = 0,5 s de Jugador):** aviso en t = 0 → 9 pide cerrar la vista en 1,5 s → cámara devuelta en 2,0 s («vista cercana cerrada») → cierre empieza en 2,3 s y termina en 3,1 s con `BOX_Cn_CLOSE` = 0,8 s.

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
6. **El puzle pasa de `ACTIVO` a `RESUELTO` por consola o por la pista nivel 3 (`AUTO_SOLVE_ELEMENT`) mientras la caja anima** (p. ej. `caja_c2` escrito con la apertura en curso): la caja termina la animación, el `get_view_gate` consultado ya pasó (paso 1), `abrir_vista` se llama y el marco cierra la vista de inmediato por su red de seguridad (regla 7 de 9). El aviso (n) pone `cierre_pendiente`; el cierre sigue la regla 14. Sin error visible.
7. **El jugador sale de la vista (`atrás`) antes de resolver.** El compartimento queda `ABIERTO` (regla 9.5). Salir de D con el compartimento abierto es válido; vuelve a verse abierto. Cargar una partida lo deja `CERRADO` (no se persiste la pose parcial, regla 6).
8. **Dos compartimentos abiertos a la vez** (C1 `ABIERTO` sin resolver y se pulsa C2): válido. No hay límite; cada uno es independiente.
9. **Resolución de C3 con el jugador lejos de la caja** (`pendiente_revelacion`, B.5): la pose es `ABIERTO`; al terminar la secuencia 9 emite el aviso (3); como la vista nunca estuvo `Abierta`, el cierre empieza a los `close_delay_s` y se anima (el sonido se atenúa por distancia). Si el jugador carga antes de volver: C3 vuelve a `ENTREABIERTO` y se reabre normalmente.
10. **«Puzle activado» de P5 con el jugador en la vista de D01a.** El sonido ya sonó (9); la animación del entreabierto espera hasta que D01c sea visible en `exploración` (regla 12). Si el jugador cierra la vista de lado y D01c queda fuera de campo, espera; `can_interact` ya vale `SI` (lo decide 9), así que no impide abrir.
11. **Cargar con `caja_c4` verdadero y `caja_c3` falso** (instantánea corrupta o consola): cada compartimento se reconstruye de su propio hecho (C4 `FINAL_ABIERTO`, C3 según el estado de 9). Se registra la incoherencia; 9 y 3 la reconcilian (reglas 8 y 31 de 9). No hay bloqueo.
12. **Cargar a mitad de la secuencia del P6** (los hechos ya están escritos, regla 16 de 9; se guardó): `caja_c4` verdadero → `FINAL_ABIERTO` sin animar. La carta ya está en el bolsillo (20).
13. **`atrás` pulsado durante la presentación del P6** (tras `SFX_LOCK_CLICK`): el P6 es de resolución inmediata (solo P5 es diferida, regla 17 de 9), así que `atrás` funciona (S4 de 9, regla 28 de 9): la vista puede cerrarse con la tapa a medias; la animación `BOX_C4_OPEN` **continúa** y termina con el jugador en `exploración`. La lectura de `I-07` la pide 9 al final (si el jugador ya salió, la petición a 7 se gestiona por el contrato de lectura de 7/20; no es asunto de la caja).
14. **«Compartimento completado» llega y la vista sigue `Abierta`.** El cierre espera a «vista cercana cerrada» (regla 14); nunca se cierra la tapa «delante» de la cámara.
15. **Consola/orden de 21 abre una vista de un puzle `BLOQUEADO` o `RESUELTO`.** El marco ejecuta su red de seguridad (regla 7 de 9). La caja no hace nada (no hay animación asociada porque no pasó por `interact()`).
16. **Valores de datos fuera de rango** (`BOX_Cn_OPEN` > 1,6 s o `Margen` < `margen_min`): error de datos en la carga; en desarrollo falla visible, en la demo se recorta a 1,6 s y se registra. Nunca se supera el token de 3 s.
17. **Degenerado: spam de pulsaciones durante `ABRIENDO`.** El contexto está bloqueado (regla 19 de 7): se descartan. Spam sobre un `BLOQUEADO`: `SIN_EFECTO` sin coste. No hay estrategia dominante: el orden de C1/C2 es libre y es una elección legítima (*Autonomía como progresión*); C3 → C4 es secuencial por diseño (D-16).
18. **Orden P4 antes que P3.** Válido (regla 24 de 9). `I-05` llega antes que `I-06a`; la caja no impone orden.
19. **Dos avisos «compartimento completado» seguidos** (p. ej. C1 y C2 resueltos con la ayuda de pistas en el mismo fotograma, improbable): se encolan y cada cierre empieza cuando le toca (regla 14); los cierres no se bloquean entre sí.

## Dependencies

Tipos: **Dura** = no funciona sin ella; **Blanda** = mejora la experiencia. «→» = la caja recibe; «←» = la caja ofrece. Cada fila cita la regla/AC en ambos lados (si el GDD del otro lado aún no existe, queda en «Cambios requeridos»).

| Sistema | Tipo | Dirección y contrato | Regla/AC en este GDD | Regla/AC en el otro GDD |
|---|---|---|---|---|
| 3 Estado y bus | Dura | → lee `caja_c1`–`caja_c4` (solo para reconstruir la pose); `caja_completa` es derivado de 3 y la caja no lo toca | Reglas 3, 6, 19 | Regla 7 de 3, CA-07 y CA-14; fila «10 Caja y compartimentos» de su tabla de dependencias |
| 7 Interacción e inspección | Dura | ← manejadores de `D01a`–`D01d` (`can_interact`, `interact`); usa `bloquear_contexto`/`liberar_contexto`, `abrir_vista(id, desde_token)`; → «vista cercana abierta/cerrada» | Reglas 7 a 11, 14 | Reglas 3, 19, 23 y 30 de 7; F4; AC-27, AC-27b; `BOX_Cn_OPEN` en Tuning Knobs (**requiere cambios**, ver «Cambios requeridos») |
| 9 Marco de puzles | Dura | → `get_view_gate`, «puzle activado» `{puzzle, ajar_cm?}`, `EV_PUZZLE_SOLVED_*`, «compartimento completado» (n); ← `play_open(4)`, `restore_solved_presentation`, anclajes y nodos donde cuelgan los controladores | Reglas 3, 8, 11, 12, 14 a 16 | Reglas 7, 16.5, 24 y 35 de 9; AC-03, AC-17 y AC-49; fila «10 Caja y compartimentos ‡» |
| 4 Escena de planta | Dura | ← el nodo `D01` vive en la escena de D y se configura en el paso 6 (iii) del arranque, después de 9; → recarga completa de la escena | Regla 5 | Regla 8 y regla 9, paso 6 de 4 |
| 5 Guardado y carga | Blanda | La caja no guarda ni pide guardar; el guardado por `compartment_done:<n>` es un aviso de 9 | Regla 23 | Reglas 5 y 6 de 5 |
| 20 Documentos y bolsillo | Blanda | ← decorado `NOTA_01` y carta plegada; 20 deriva los ítems de los hechos; la caja no consulta `has_item` | Reglas 17, 18 | Pendiente (20 aún no existe) |
| 23 Director de audio | Blanda | ← fuente 3D `SPK_D01C`, `SFX_BOX_WOOD_OPEN` y `SFX_BOX_WOOD_CLOSE`; 23 reproduce `VO_G_07` en el altavoz | Reglas 17, 22 | Pendiente |
| 13–16 Puzles 3 a 6 | Dura | ← anclajes y nodos de cada puzle; → los controladores llaman a `play_open(4)` (P6) | Reglas 10, 11 | Pendiente |
| 21 Director de escenas | Blanda | No hay llamada directa: 21 lee `caja_completa` de 3 | Regla 19 | Regla 7 de 3 (fila de 21) |
| 1 Entrada y controles | Dura (indirecta) | El token de `bloquear_contexto` declara una transición bloqueante de Entrada; el tope de 3 s es el de Entrada | Reglas 9, 21; F1 | Regla 8 y F8 de Entrada; tope 3–5 s |
| 2 Jugador en primera persona | Blanda (indirecta) | La cámara la cede 7 (`ceder_camara`); la caja no la toca | Regla 10 | Contrato de cesión de cámara de 2 |
| 17 Sistema de pistas | — | Sin relación: las pistas no mueven la caja salvo por `AUTO_SOLVE_ELEMENT` vía 9 | Edge case 6 | AC-43 de 9 |

## Tuning Knobs

Fichero propuesto: `assets/data/box/box.json` (los de 9 —`ajar_cm`, `close_view_after_s`— viven en el JSON de puzles de 9). Categorías: **F** = feel, **C** = curve, **G** = gate.

| Knob | Cat. | Defecto | Rango seguro | Qué afecta / razonamiento |
|---|---|---|---|---|
| `BOX_C1_OPEN` | F | **1,6 s** (slice B.3) | 1,2–1,6 | Peso del gesto de abrir D01a. Tope por F2 |
| `BOX_C2_OPEN` | F | **1,4 s** (slice B.4) | 1,2–1,6 | Idem D01b |
| `BOX_C3_OPEN` | F | 1,4 s | 1,2–1,6 | Idem D01c; menor que C1 porque ya parte de 2 cm entreabierta (D10-1) |
| `BOX_C4_OPEN` | F | 1,6 s (slice B.6) | 1,2–1,6 | Tapa del P6 en la presentación de resolución (no entra en `T_cadena`). Mismo rango por coherencia con el registro |
| `margen_min` | G | 0,2 s | 0,1–0,5 | Holgura mínima de `T_cadena` frente al tope de Entrada (validación de datos) |
| `BOX_Cn_CLOSE` (n = 1–3) | F | 0,8 s | 0,4–1,2 | Duración del cierre tras resolver; no bloqueante |
| `close_delay_s` | F | 0,3 s | 0–1,0 | Pausa entre «vista cerrada» y el cierre para que el jugador vea cerrarse la tapa |
| `ajar_s` | F | 0,6 s | 0,3–1,2 | Velocidad del entreabierto de C3 (`ajar_cm` es de 9, 2 cm, rango 1–4) |
| `reopen_skips_animation` | G | `true` | bool | Con `false` cada reapertura repite `BOX_Cn_OPEN` (peor ritmo al reintentar; no recomendado) |
| `locked_text_key` (C3, C4) | F | vacío | vacío o clave de 18 | Texto de pie al pulsar un compartimento bloqueado. Vacío = solo sonido (D10-8) |
| `c4_stays_open` | G | `true` | bool | Regla 35 de 9 y línea `VO_G_13D`. Con `false` C4 pasaría a `FINAL_CERRADO` (rompería la línea) |

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

Tipos: **L** = lógica (prueba automática, `tests/unit/box/`), **I** = integración (`tests/integration/box/`), **PV** = playtest o verificación visual con captura retenida en `production/qa/evidence/`.

- **AC-01 (R7, L)**: **GIVEN** `get_view_gate` de `D01c` = `BLOCKED` (`caja_c1` falso), **WHEN** 7 consulta `can_interact`, **THEN** devuelve `SIN_EFECTO`, nunca `NO`; **GIVEN** `OPEN`, **THEN** `SI`; **GIVEN** `SOLVED`, **THEN** `SIN_EFECTO`.
- **AC-02 (R8, L)**: **GIVEN** `D01c` `BLOQUEADO`, **WHEN** el jugador pulsa, **THEN** no se llama a `bloquear_contexto`, no se anima nada, no se llama a `abrir_vista`, y suena `SFX_CLICK_SUBTLE` sin texto.
- **AC-03 (R9, I)**: **GIVEN** `D01a` `ACTIVO` y `CERRADO`, **WHEN** el jugador pulsa, **THEN** se obtiene un token, `SFX_BOX_WOOD_OPEN` suena en t = 0, la animación dura 1,6 s, y en el mismo paso al terminar se llama a `abrir_vista("D01a", desde_token)`; no hay ningún fotograma en `exploración` entre las dos fases.
- **AC-04 (R9, F1, I)**: **GIVEN** `D01a` con `t_vista_entrada_s` = 1,2 s, **WHEN** se mide desde la pulsación hasta «vista cercana abierta», **THEN** ≤ 2,8 s, sin que Entrada libere el contexto antes (tope 3 s).
- **AC-05 (R9.5, I)**: **GIVEN** `D01a` `ABIERTO` tras `atrás` sin resolver, **WHEN** el jugador pulsa, **THEN** no hay `BOX_C1_OPEN`, no hay token, `abrir_vista("D01a")` se llama desde `exploración` y la primera acción llega en `t_vista_entrada_s`.
- **AC-06 (R9.4, L)**: **GIVEN** `abrir_vista` devuelve `RECHAZADA`, **THEN** se llama a `liberar_contexto(token)`, queda `ABIERTO`, se registra el motivo y el contexto vuelve a `exploración`.
- **AC-07 (R9.2, L)**: **GIVEN** `bloquear_contexto` devuelve `nulo`, **THEN** `interact()` devuelve `SIN_EFECTO`, no se anima y se registra un error.
- **AC-08 (R11, I)**: **GIVEN** `D01d` `ACTIVO`, **WHEN** el jugador pulsa, **THEN** no hay animación previa ni token y `abrir_vista("D01d")` se llama directamente; **WHEN** se resuelve el P6, **THEN** `play_open(4)` se reproduce tras `SFX_LOCK_CLICK` (0,3 s) y dura `BOX_C4_OPEN`; la carta es visible a t = 1,9 s.
- **AC-09 (R12, I)**: **GIVEN** `caja_c1` pasa a verdadero con el jugador en la vista de `D01a`, **THEN** «puzle activado» (P5) lleva `ajar_cm` = 2, `SFX_UNLOCK_SOFT` suena una vez (9, AC-03 de 9) y el entreabierto de 2 cm se anima en cuanto D01c es visible en `exploración`, nunca durante la vista de D01a.
- **AC-10 (R13, L)**: **GIVEN** `caja_c1`, `c2` verdaderos y `c3` falso, **WHEN** P6 pasa a `ACTIVO`, **THEN** C4 no se mueve (sin entreabierto) y solo suena `SFX_UNLOCK_SOFT` (9).
- **AC-11 (R14, F4, I)**: **GIVEN** P3 resuelto con la vista `Abierta`, **WHEN** llega «compartimento completado» (1), **THEN** la tapa no se mueve hasta «vista cercana cerrada» + `close_delay_s`, se anima `BOX_C1_CLOSE` durante 0,8 s con `SFX_BOX_WOOD_CLOSE`, sin token ni bloqueo de contexto; la pose final es `FINAL_CERRADO`.
- **AC-12 (R14, I)**: **GIVEN** P5 resuelto con el jugador fuera de D, **THEN** el cierre de C3 empieza a `close_delay_s` del aviso (la vista nunca estuvo abierta).
- **AC-13 (R16, I)**: **GIVEN** P6 resuelto con las variantes A, B y C por separado, **THEN** C4 queda `FINAL_ABIERTO` con la tapa abierta y la carta dentro; ninguna diferencia visible ni audible entre variantes.
- **AC-14 (R5, R6, L)**: **GIVEN** una carga con `caja_c1` y `caja_c2` verdaderos, `caja_c3` falso y P5 `ACTIVO`, **THEN** C1 y C2 en `FINAL_CERRADO`, C3 en `ENTREABIERTO` sin sonido ni animación, C4 `CERRADO`; **y** no se emite ningún aviso, no se llama a `bloquear_contexto` y el log no contiene errores ni advertencias.
- **AC-15 (R5, R6, L)**: **GIVEN** `caja_c4` verdadero al cargar, **THEN** C4 `FINAL_ABIERTO` sin animar, y 9 no emite `EV_PUZZLE_SOLVED_P6` ni «compartimento completado» (AC-02 de 9).
- **AC-16 (R15, L)**: **GIVEN** `restore_solved_presentation(n)` para cada n, **THEN** la pose y el contenido final se colocan en el mismo fotograma sin animar ni sonar, de forma idempotente.
- **AC-17 (R19, L)**: **GIVEN** la caja en cualquier estado, **THEN** ningún código de la caja escribe, emite ni se suscribe a `caja_completa`; **GIVEN** `caja_c4` verdadero, **THEN** el aviso de `caja_c4` precede al de `caja_completa` (CA-14 de 3) y la caja no cambia de pose por ello.
- **AC-18 (R20, PV)**: **GIVEN** la caja completa, **WHEN** el jugador la observa, **THEN** no aparece ninguna luz, sonido ni animación de «completado» propios de la caja. Playtest: a ≥ 5 de 5 jugadores no se les «anuncia» que han terminado; reconocen la llamada como consecuencia de salir de D.
- **AC-19 (R17, L)**: **GIVEN** la caja, **THEN** no hay ninguna llamada a `has_item`, ni escritura de ítems, ni lectura del bolsillo.
- **AC-20 (R17, I)**: **GIVEN** la secuencia de P5 en el paso `LINE`, **THEN** `VO_G_07` suena desde `SPK_D01C` (la posición 3D es la del altavoz del compartimento) y la caja no temporiza ni espera la línea.
- **AC-21 (R22, I)**: **GIVEN** pausa abierta durante `BOX_C1_OPEN`, **WHEN** se reanuda, **THEN** la animación y su sonido continúan desde donde estaban y `T_cadena` no excede 2,8 s de tiempo de juego (verificación del editor 4.7 pendiente, Pregunta abierta 4).
- **AC-22 (R21, L)**: **GIVEN** `box.json` con `BOX_C1_OPEN` = 1,8 s o `Margen` < 0,2 s, **THEN** la validación de datos lo rechaza (error en desarrollo; recorte a 1,6 s y aviso en la demo).
- **AC-23 (R14, L)**: **GIVEN** `get_view_gate` de `D01a` = `SOLVED`, **WHEN** el jugador pulsa, **THEN** `SIN_EFECTO` con `SFX_CLICK_SUBTLE`, la tapa de C1 no se mueve y la vista no se abre (regla 35 de 9).
- **AC-24 (R2, PV)**: **GIVEN** una sesión de playtest con 5 jugadores nuevos, **THEN** ≥ 4 abren los cuatro compartimentos sin consultar pistas de nivel 3 y ninguno atribuye una tapa que no se abre a un fallo del juego (sensación «el juego no responde»); el orden de C1/C2 varía entre jugadores.
- **AC-25 (R9, F6, PV)**: **GIVEN** una captura de vídeo, **WHEN** se mide pulsación → primer sonido, **THEN** < 0,5 s en el caso `SI` y en el caso `SIN_EFECTO`.
- **AC-V1 (R4, R12, R14, PV)**: **GIVEN** capturas de cada pose (`CERRADO`, `ENTREABIERTO`, `ABIERTO`, `FINAL_CERRADO`, `FINAL_ABIERTO`) de los cuatro compartimentos, **THEN** son distinguibles entre sí y se retienen en `production/qa/evidence/`.

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D10-1 | `BOX_Cn_OPEN` es **por compartimento** (C1 1,6 s, C2 1,4 s, C3 1,4 s, C4 1,6 s) y el 1,6 s del registro/7 pasa a ser el **tope** (F2). C3 = 1,4 s porque parte de 2 cm entreabierta | Valor único 1,6 s para los cuatro (modelo actual de 7) | El slice (B.3, B.4) da 1,6 y 1,4: un valor único lo contradice; el tope 1,6 conserva la cadena ≤ 2,8 s. Prevalece el slice |
| D10-2 | `BOX_C4_OPEN` = la **tapa del P6** (1,6 s), dentro de la presentación de resolución, **sin apertura previa** de la vista (regla 11) | Encadenar `BOX_C4_OPEN` antes de la vista como C1–C3 (regla 19 de 7) | El slice B.6 pone los tres botones antes y la tapa *después* de pulsar; 9 (regla 16.6) ya modela «0,3 s + 1,6 s» tras la resolución. Encadenar añadiría una tapa que se abre dos veces |
| D10-3 | Salir de la vista sin resolver deja el compartimento `ABIERTO`; la reapertura omite la animación (`reopen_skips_animation`) | Cerrar al salir y repetir 1,6 s cada vez | Repetir 1,6 s en cada reintento castiga el tanteo (*Tensión sin castigo*) y alarga el micro-loop; no cambia la regla de 7 (peor caso 2,8 s sigue acotado) |
| D10-4 | C1–C3 se cierran tras resolverse (el cierre de C1 es del slice B.3; C2 y C3 se extienden por coherencia); el cierre espera a que la vista se cierre | Cierre inmediato al resolver; dejar todos abiertos | Cerrar con la cámara delante rompe la vista; el slice solo documenta C1, y tres compartimentos cerrados + uno abierto da a C4 su peso (*El espacio expresa la emoción*) |
| D10-5 | C4 queda **abierto** en las tres variantes de la carta | Cerrarlo; abrir/cerrar según variante | Regla 35 de 9 y `VO_G_13D`; una caja que cambia según la elección sería un indicador moral (*Ambivalencia*) |
| D10-6 | El entreabierto de C3 se anima **cuando D01c es visible en `exploración`**, no en el aviso | Animar en el aviso aunque la cámara esté en la vista de D01a | Si no se ve, el jugador no relaciona el sonido con el hueco; sin pistas de texto la caja debe «enseñar» (*Autonomía*, *El espacio expresa la emoción*). Cuesta ~1,5–2 s de retraso visual |
| D10-7 | C4 **no** se entreabre | Entreabrir 2 cm también (Open Question 5 de 9) | B.6 no lo pide; el frontal de C4 ya es el panel de botones |
| D10-8 | Pulsar un compartimento bloqueado: solo `SFX_CLICK_SUBTLE`, sin texto (`locked_text_key` vacío) | Pie «Todavía no» | Regla 7 de 9 (por defecto sin texto) y pilar *Autonomía*: las pistas son de 17, no de la caja. La clave existe como knob si el playtest lo pide |
| D10-9 | La caja **no** emite «compartimento completado» ni `caja_completa` | Que la emita la caja | D9-24 y regla 7 de 3: 9 posee el orden de escritura y 3 el derivado; 10 solo escenifica |
| D10-10 | Sin señal propia al completar los cuatro | Luz o sonido de «caja completa» | *Información incompleta* y el disparador del slice (D-03): salir de D con `caja_completa`; lo escenifica 21 |
| D10-11 | Los ítems de la caja no son interactuables por defecto; solo `NOTA_01` tiene decorado en la bandeja | Cada recompensa como objeto cogible | Ampliar el catálogo de 7 es cambio de alcance (35 entradas); se deja como Pregunta abierta 1 |
| D10-12 | Se temporiza con la señal de fin de animación, no con `Tween`/`SceneTreeTimer` | `create_timer` para el fin de `BOX_Cn_OPEN` | Misma razón que regla 36 de 9 (pausa y determinismo) |
| D10-13 | La caja no es dueña de ningún hecho ni aviso nuevo | Hecho `box_pose_*` | Evita estado duplicado (regla 3 de 7/3); la pose es reconstruible de `caja_cn` y 9 |

## Preguntas abiertas

| # | Pregunta | Dueño | Estado |
|---|---|---|---|
| 1 | ¿`NOTA_01` (y quizá `I-05`) deben ser un objeto que el jugador **coge** de la bandeja (entrada nueva en el catálogo de 7 y recoger en 20), o llegan solos al bolsillo? Por defecto llegan solos y el decorado de la bandeja no es interactivo (D10-11). El pilar *Autonomía* sugiere cogerlas | Autor / 20 / 7 | Abierta. Cambia alcance del catálogo |
| 2 | ¿7 acepta que `D01d` no encadene la tapa antes de la vista (regla 11)? | Revisión de 7 | Abierta (cambio en 7 requerido) |
| 3 | `SFX_UNLOCK_SOFT` lo reproduce 9 en el aviso, pero el entreabierto se anima después (D10-6): ¿se acepta el desfase o 10 reproduce el sonido con la animación? | 9 / 10 | Abierta; por defecto se acepta el desfase |
| 4 | ¿La pausa (`SceneTree.paused`) detiene `AnimationPlayer` y sus sonidos en 4.7? No está cubierto por `docs/engine-reference/godot/` | lead-programmer | Abierta (misma que la 4 de 9) |
| 5 | `reducir_movimiento` (4): ¿debe acortar las animaciones de la caja? Por defecto solo `ajar_s` y el cierre | ux-designer / accessibility | Abierta |
| 6 | Voz y altavoz: ¿`SPK_D01C` es un nodo de 10 o un bus virtual de 23? Por defecto, nodo de 10 que 23 referencia | 23 / audio-director | Abierta |

No hay ninguna pregunta que cambie pilares, tono o alcance del slice más allá de la 1.

## Cambios requeridos en otros GDDs

No se ha editado ninguno. Para el siguiente paso del lote:

- **7 Interacción e inspección:** (a) regla 19, F4, fila `BOX_Cn_OPEN` de Tuning Knobs, D7-19/D7-43/D7-47/D7-52 y AC: la cadena `BOX_Cn_OPEN` + `t_vista_entrada_s` aplica a `D01a`–`D01c`; **`D01d` no encadena** (D10-2); (b) `BOX_Cn_OPEN` pasa de valor único a **tope 1,6 s** con valores por compartimento (D10-1); (c) tabla de interacción: `SIN_EFECTO` en `D01c`–`D01d`, no «`D01b`–`D01d`» (C2 no tiene dependencias, slice B.4 y D-16); (d) añadir 10 a `abrir_vista` desde `exploración` (reapertura sin token, regla 9.5).
- **9 Marco de puzles:** (a) regla 24 y Open Question 5: `ajar_cm` no se aplica al P6 (D10-7); (b) `play_resolution` del P6 debe llamar a `play_open(4)` de 10 tras `SFX_LOCK_CLICK`; (c) `restore_solved_presentation` lo implementa 10; (d) Dependencies: fila 10 con las reglas de esta página; (e) AC de «puzle activado» de P5: el entreabierto visible se difiere (D10-6).
- **3 Estado y bus:** sin cambios de contrato; la fila «10 Caja y compartimentos» ya dice «Dura, lee `caja_c1`–`c4`» (correcto).
- **4 Escena de planta:** añadir `D01`/`SPK_D01C` y anclajes `ANC_D01A`–`ANC_D01D` a la lista del paso 6 (iii) del arranque.
- **5 Guardado y carga:** ninguno.
- **20 Documentos y bolsillo (futuro):** derivar `I-06a`, `I-05` e `I-07` de los hechos; Pregunta abierta 1.
- **23 Director de audio (futuro):** fuente `SPK_D01C` y los dos `SFX_BOX_WOOD_*`.
- **13 a 16 (futuros):** sus elementos cuelgan de los nodos de la caja; P6 llama a `play_open(4)`.
- **`systems-index.md`:** fila 10 a «Borrador»; dependencias de 10: 3, 4, 7, 9 (duras), blandas 20, 23.

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
    note: "D10-1; parte entreabierta 2 cm"
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
    range: [0.1, 0.5]
    source: design/gdd/caja-y-compartimentos.md
  - name: BOX_Cn_CLOSE
    value: 0.8
    unit: s
    range: [0.4, 1.2]
    source: design/gdd/caja-y-compartimentos.md
  - name: box_close_delay_s
    value: 0.3
    unit: s
    range: [0.0, 1.0]
    source: design/gdd/caja-y-compartimentos.md
  - name: box_ajar_s
    value: 0.6
    unit: s
    range: [0.3, 1.2]
    source: design/gdd/caja-y-compartimentos.md
formulas:
  - name: box_chain_time        # T_cadena(n), F1
    output_range: [1.0, 2.8]
    source: design/gdd/caja-y-compartimentos.md
ids:                             # no son hechos
  - SFX_BOX_WOOD_OPEN
  - SFX_BOX_WOOD_CLOSE
  - SPK_D01C
  - ANC_D01B, ANC_D01C, ANC_D01D   # ANC_D01A ya figura en 7
interfaces:
  - play_open(n)                   # 10 -> llamado por el controlador del P6
  - restore_solved_presentation(n) # 10 -> llamado por 9 (regla 35 de 9)
```

No se proponen hechos, avisos ni flags nuevos (D10-13).

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote Feature 1). |
