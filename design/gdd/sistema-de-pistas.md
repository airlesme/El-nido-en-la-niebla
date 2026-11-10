# Sistema de pistas (sistema 17)

> **Status**: Revisado (ronda de corrección 10) — pendiente de re-review (ronda 10: ‡ de «puzles configurados» cerrada, `memo_leido` dicho una vez; ronda 9: panel sin «Nada pendiente» falso con puzles activos, D17-25; contratos con 3, 9, 23, 25; OQ 3, 10 y 11 pendientes de decisión del usuario)
> **Author**: Game Designer (lote autónomo)
> **Last Updated**: 2026-11-10
> **Implements Pillar**: Autonomía como progresión (las pistas son opcionales, escalonadas y nunca deciden por el jugador) · Tensión sin castigo (pedir una pista no cuesta nada: ni puntuación, ni marca, ni consecuencia) · Información incompleta (una pista enfatiza lo que ya está y nunca confirma una intención) · El espacio expresa la emoción (sin voz, sin icono de bombilla, sin sermón)

## Summary

Las pistas del slice las **declara** cada puzle (11 a 16, en `puzzles.json`, esquema v2), las **aplica** el marco (9, `request_hint`) y sus textos son de la base de contenido (18, 8 claves `PISTA_*`). Este sistema decide lo que faltaba: **cuándo y cuánto se ofrece**. Posee un registro en memoria (`HintLedger`: niveles aplicados, última pista, notas ya mostradas) y el **panel de pistas** que se abre desde el menú de pausa (25): lista solo los puzles que el jugador ya conoce, ofrece «Pedir una pista» (siempre el **siguiente** nivel, sin saltos, con una espera corta entre niveles) y «Repetir la última». Asume el reparto de las pistas automáticas por inactividad (P3 nivel 3, P6 niveles 1 y 2). Los textos se presentan como una **nota** sobria en pantalla, sin voz ni marco. No guarda nada: al cargar, las pistas empiezan de cero (D9-38).

## Overview

El slice promete que cada puzle se resuelve con información del propio juego (§19.2) y que hay ayuda opcional «en tres niveles; dos en el puzle 6», accesible desde el menú de pausa (§10, §16). El marco de puzles (9) ya hace lo mecánico: valida el estado, aplica los efectos (`TEXT`, `HIGHLIGHT`, `AFFORDANCE`, `AUTO_SOLVE_ELEMENT`), lleva `hint_level_reached` en memoria y emite «pista aplicada» y «puzle inactivo». Pero 9 declara que **no decide cuándo se ofrece una pista ni cuántas** (reglas 26) y que, si se abusa de pedirlas y eso daña el criterio 5 del slice, «se resuelve en el sistema 17 (espaciado)».

17 es esa capa de política y de presentación, deliberadamente pequeña:

1. **Quién posee qué.** 9 posee la aplicación de efectos y `hint_level_reached`. 17 posee el `HintLedger`, la escalera (qué nivel es el siguiente), la espera, las notas de texto y el panel. Ningún hecho nuevo en el estado (3): el registro no se persiste.
2. **Cómo se pide.** Solo desde el menú de pausa (25) o, en tres casos del slice, por inactividad (P3 nivel 3, P6 niveles 1 y 2). No hay acción de entrada dedicada (1) ni gesto de cámara (decisión del usuario, D9-32).
3. **Cómo se presenta.** Los efectos no textuales los dibuja 9 o el controlador del puzle. Los textos los muestra 17 como **nota**: una línea sobria, sin prefijo «Pista:», sin voz, sin icono, con duración proporcional a su longitud, y se pueden **releer** en el panel (cuaderno de notas).
4. **Qué nunca hace.** No escribe texto propio, no puntúa, no cuenta pistas usadas, no cambia el contenido del juego según las pistas pedidas y no guía fuera de los puzles (no hay pista de «adónde ir»).

## Player Fantasy

Vera se queda mirando algo que ya tenía delante. Nadie le habla ni le explica: la atención vuelve, un poco más afinada, a la hoja, al reflejo o al tablero. Una frase breve aparece abajo, sin dueño y sin voz, como un pensamiento que ella misma podría haber tenido; después se retira sola. Si el jugador quiere más, la segunda ayuda tarda unos segundos y es algo más concreta; la tercera es la más clara, pero **nunca** decide lo que Vera siente ni lo que Vera responde. El jugador debe sentir **competencia recuperada, no derrota admitida**: pedir ayuda es una forma de mirar mejor, no un fallo que se anota.

Aesthetics del MDA: **Discovery** (la pista devuelve la mirada a lo que hay) y **Challenge sin castigo** (pilar 4). Necesidades SDT: **Competencia** (se sale del atasco y se entiende *por qué*) y **Autonomía** (el jugador decide si pide, cuándo y cuánto; ningún nivel se impone salvo los tres automáticos del slice). Tests de pilar: si dudamos entre un contador de «pistas usadas» y no llevar cuenta, elegimos no llevarla (anti-pilar *NOT medidores*; pilar *Tensión sin castigo*); si dudamos entre una voz de Vera que diga la pista y una nota de texto en silencio, elegimos la nota (*Autonomía como progresión*: «`VO_V_*` comenta, no instruye»; *El espacio expresa la emoción*); si dudamos entre añadir una pista que aclare qué quiso decir un documento y dejar el documento abierto, lo dejamos abierto (*Información incompleta*).

## Detailed Rules

Convención: «regla N de 9» = regla N del *Core Rules* de `marco-de-puzles.md`. Los textos de pista son de 18 y los redacta el writer; los textos de la interfaz de pistas (`UI_PISTAS_*`) son **propuestas †** hasta que 18 los acoja. El reloj es el `GameClock` de 9 (regla 36): la pausa lo detiene.

### A. Identidad, propiedad del estado y alcance

1. **Qué es 17.** Un servicio (`HintService`, inyectado, sin singleton) con un registro en memoria (`HintLedger`) y un panel de interfaz (`HintPanel`) que aloja el menú de pausa (25). Escucha a 9 y a 7; no escribe hechos ni emite avisos propios.
2. **Propiedad del estado de pistas.** `hint_level_reached` (nivel máximo alcanzado, monótono) **sigue siendo de 9** (regla 26). 17 añade su propio estado por puzle, **solo en memoria**:
   - `applied`: conjunto de niveles aplicados (distinto del máximo: P3 puede tener `{3}` si el nivel 3 salió por inactividad sin pedir 1 y 2).
   - `t_ref`: instante de `GameClock` de la última pista **nueva** aplicada (F1).
   - `last_applied`: último nivel aplicado en el tiempo (para «Repetir»).
   - `notes`: lista ordenada de claves `PISTA_*` de las notas de texto **ya mostradas** (el cuaderno).
   - `pending_text`: clave de texto aplicada con el contexto del puzle ausente (regla 20), como mucho una por puzle.
3. **Qué no posee.** La definición, los efectos y la validación de cada pista (9 y 11–16); los textos (18); el menú de pausa y su foco (25); la pantalla de reasignación y los ajustes (6 y 25); el reloj (9); el audio (23); la lógica de la caja (10). 17 **no** conoce la solución de ningún puzle.
4. **Alcance del slice.** Solo pistas **de puzle** (las 17 declaradas: 3 en P1–P5 y 2 en P6, 8 con texto). No hay pistas de orientación fuera de los puzles (D17-9): el recuento de 8 claves `PISTA_*` es un conjunto cerrado (18, regla 20; `hint_key_count`).

### B. Qué puzles aparecen en el panel

5. **Se listan solo los puzles que el jugador ya conoce.** Un puzle aparece si cumple a la vez:
   - su estado en `list_puzzles()` es `ACTIVO` (también `RESOLVING`, mostrado inerte, regla 14);
   - declara al menos un nivel en `get_hints(id)`;
   - es **conocido**, según su campo `discover_if` de `hints_policy.json`: `COMMITMENT` (puzles `VIEW`: el jugador se ha comprometido con él al menos una vez en la sesión: `list_puzzles()` informa de su último compromiso), `FIRST_ACTION` (puzles `WORLD`, hoy solo P2: en un `WORLD` no hay compromiso, regla 11 de 9; se considera conocido tras la **primera activación válida de un manejador** `B01`–`B03`, que `list_puzzles()` expone como `first_action` ‡, cambio requerido en 9) o un hecho (`correos_leidos` para P1). Alternativa pendiente de confirmar con 3 y 12: «entrada a la Sala B» (D17-20).
6. **Motivo (anti-spoiler).** P3 y P4 están `ACTIVO` desde el inicio, aunque el jugador aún no haya visto la caja; listarlos en el panel revelaría su existencia y su función (pilar 3: lo que se mira lo decide el jugador). P1 es la excepción: el jugador que ya leyó los correos (`correos_leidos`) pero no sabe que debe imprimir **no se ha comprometido nunca** con P1 (la vista exige `I-01`, regla 7 de 9) y es justo quien necesita el nivel 1 (resaltar `V08`, `targets_if_missing_items`).
7. **No se listan** los puzles `BLOQUEADO` ni `RESUELTO`. Tampoco se muestra ninguno cuyo `discover_if` no se cumpla. **Estado vacío (D17-25):** si no hay ninguno listado **y ningún puzle está `ACTIVO` o `RESOLVING`** (todos `RESUELTO` o `BLOQUEADO`: Recepción y final), el panel muestra `UI_PISTAS_NADA` † («Nada pendiente.»); si no hay ninguno listado **pero hay al menos un puzle `ACTIVO`** (partida nueva, o tras cargar con el registro de compromisos vacío), muestra `UI_PISTAS_SIN_LISTA` † («Todavía no has examinado nada de lo que pueda salir una pista.»), que no nombra ningún puzle (anti-spoiler) ni afirma que no quede nada por hacer. Ninguna de las dos líneas lleva botón.
8. **Orden fijo** P1 a P6 (no cambia con la actividad). **Etiqueta** de cada puzle: `UI_PISTAS_P1` a `UI_PISTAS_P6` †, neutras y sin contenido de solución ni moral: «La cronología», «El memorando», «La foto del equipo», «El tablero», «El reflejo», «La carta». (Nombres propuestos; los fija el writer. «Decisión» no se usa: anticiparía que hay una elección, pilar 3.)
9. **Preselección.** Al abrir el panel queda seleccionada una entrada (el jugador puede cambiarla; no restringe nada):
   1. el puzle de la vista abierta, si se pausó dentro de una vista cercana;
   2. si no, el listado con el compromiso más reciente;
   3. si no hay ninguno, el primero de la lista.
   `memo_leido` y `formulario_leido` **no intervienen** (D17-10, Open Question 2).

### C. Cómo se pide una pista (la escalera)

10. **Una acción, un nivel.** En la entrada seleccionada, el botón «Pedir una pista» (`UI_PISTAS_PEDIR` †) pide **siempre el siguiente nivel no aplicado**: el menor `k` de `1..N` que no esté en `applied`. El jugador **no elige el nivel** (D17-2). Con `applied = {1}` pide el 2; con `{3}` (P3, por inactividad) pide el 1. Total de entradas en el menú de pausa: `pausa` → «Pistas» → «Pedir una pista» (3 acciones). **Pips (cortables, OQ 11):** junto a la etiqueta, una fila de `N` puntos (3; 2 en P6) con los niveles de `applied` rellenos; solo forma, sin cifras ni color moral; no es un contador de uso, es el estado de la escalera de la sesión (D17-17).
11. **Validaciones, en este orden** (resultado `HintResult`):
    1. El puzle debe estar `ACTIVO`. En `RESOLVING` el botón se muestra inerte y no se llama a 9 (`BUSY`; 9 lo ignoraría de todos modos, D9-74). En `BLOQUEADO`/`RESUELTO` ni se lista (regla 7).
    2. Si `applied` contiene todos los niveles: `COMPLETE`. El botón desaparece y queda «Repetir».
    3. Si `espera(p, k) > 0` (F1): `WAIT`. El botón se ve **apagado**, **sin relleno animado ni cifras** (el panel solo existe en pausa y la espera usa el `GameClock`, que en pausa no corre: una animación de relleno sería falsa, D17-20); pulsarlo suena `SFX_CLICK_SUBTLE` (verificado: slice B.7, 1, 24) y muestra `UI_PISTAS_ESPERA` † («Sigue mirando un poco antes de pedir otra.»). El flujo real es: pedir → reanudar → jugar el tiempo de `gap` → volver a pausar; el texto lo dice sin prometer una cuenta atrás. **No** hay penalización ni contador de intentos.
    4. Se llama a `request_hint(id, k)` de 9. Si devuelve `false` (el estado cambió, regla 26), 17 no toca el registro, anota «pista rechazada» y refresca el panel (`REJECTED`).
    5. Si devuelve `true`: 17 añade `k` a `applied`, fija `last_applied = k` y `t_ref = ahora`, y refresca el panel (`APPLIED`).
12. **Efecto de una petición hecha desde la pausa.** Lo que el jugador ve empieza **al reanudar** (regla 26 de 9: todo lo que dura usa el reloj de juego). El panel confirma con `UI_PISTAS_LISTA` † («Lo verás al volver.»). **No** muestra el texto de la pista dentro del panel: la primera lectura es en la escena, donde tiene sentido; después queda en el cuaderno (regla 21).
13. **Repetir.** «Repetir la última» (`UI_PISTAS_REPETIR` †) llama a `request_hint(id, last_applied)` de 9, que **reaplica** los efectos sin cambiar `hint_level_reached` ni consumir nada (cambio requerido en 9, punto 3). La reaplicación **solo repite la presentación** (resaltado, afordancia, nota): nunca reejecuta `AUTO_SOLVE_ELEMENT` ni llama a `evaluate()` (cambio requerido en 9, punto 3; AC-17-12b). No tiene espera, no tiene tope y no cambia `t_ref` ni `applied`. Sobre un efecto persistente que ya está a la vista (p. ej. `MARK_LIT`), el resultado es «ya está» y el panel muestra `UI_PISTAS_YA_VISIBLE` † («Ya está a la vista.»). Es el remedio contra la pista que se pasó sin leer o sin ver (la autonomía incluye volver a mirar).
14. **Sin tope de pistas.** No hay máximo de peticiones por puzle ni por partida: la escalera es finita (3 niveles; 2 en P6), la repetición es libre y nada se contabiliza. La única fricción es la espera de F1 (D17-4).

### D. Pistas automáticas por inactividad

15. **17 asume el reparto.** Mientras 17 exista, el dato de 9 `idle_hints_auto_apply` se entrega en **falso** y 17 se suscribe a «puzle inactivo» `(id, nivel)` (cambio requerido en 9, punto 1). Los umbrales y su medida (`idle_s`, `idle_reset`, `condition`, «una vez por compromiso») **siguen siendo de 9** (F3): 17 no mide inactividad.
16. **Qué hace 17 al recibir «puzle inactivo».** Si el puzle está `ACTIVO` (no `RESOLVING`), el nivel no está en `applied` y `auto_apply` es verdadero, llama a `request_hint(id, nivel)` **sin comprobar la espera** (los umbrales del slice son los tiempos del Anexo B) y actualiza `applied`, `last_applied` y `t_ref` como una petición normal. Si 9 no aplica el nivel (p. ej. la `condition` `HELD_PIECE` de P3 no se cumple: el umbral no se consume, F3 de 9), 17 no registra nada. Un nivel que ya está en `applied` se ignora. **Condición cumplida después del umbral:** 9 **vuelve a emitir** «puzle inactivo» `(id, nivel)` en cuanto la `condition` pasa a cumplirse con el umbral ya vencido (cambio requerido en 9, punto 1; p. ej. P3 nivel 3 al agarrar la pieza); 17 reacciona solo a ese aviso, no a «pista aplicada».
17. **Las tres pistas automáticas del slice** son las únicas que el jugador no pide: P3 nivel 3 (60 s † sin gesto ni movimiento, con pieza en la mano) y P6 niveles 1 (10 s † sin pulsar) y 2 (20 s †). Son las que fija el Anexo B. Ninguna decide por el jugador: P3 nivel 3 solo contornea el hueco de **la pieza que ya tiene en la mano**; P6 solo informa de la regla y de lo que cambia (D16-4).
18. **Nada automático más.** 17 no añade umbrales propios ni «pistas por fallo»: los puzles no tienen fallo que acumular (pilar 4) y P2/P5 no tienen `IDLE` por decisión de sus GDD (la voz y el sistema no guían, pilar 3).
19. **Autonomía frente a la pista automática.** Que sean automáticas es decisión del slice (Anexo B) y se respeta; se eleva el posible conflicto con el pilar 3 como Open Question 1. El interruptor `auto_apply` existe en los datos de 17 (no en Ajustes: «las pistas no se colocan en ajustes», índice) por si el usuario decide quitarlas.

### E. Presentación

20. **Efectos no textuales.** Los muestra 9 o el controlador del puzle (`HIGHLIGHT`, `AFFORDANCE`, `AUTO_SOLVE_ELEMENT`; reglas 25 y 26): ninguna pista mueve la cámara (decisión del usuario, D9-32). 17 no los dibuja ni los retrasa. **Contrato del `TEXT` con 9 (D17-21):** 9 aplica `HIGHLIGHT`, `AFFORDANCE` y `AUTO_SOLVE_ELEMENT` y **delega** el `TEXT` en 17: no lo presenta ni lo aplaza. «Pista aplicada» lleva `(id, nivel, text_key)` (`text_key` nulo si el nivel no tiene `TEXT`; cambio requerido en 9, punto 5) y 17 es el **único** que muestra la nota, una vez por aplicación.
21. **Nota de texto (`HintNote`).** Cuando llega «pista aplicada» con `text_key`, 17 lo muestra como una **nota**: una o dos líneas centradas en el tercio inferior de la pantalla, sobre una banda semitransparente neutra, con el estilo de texto de los avisos de interfaz de la base visual. Reglas de forma (el aspecto lo fija arte; aquí solo el comportamiento):
    - **Sin prefijo** («Pista:», «Consejo:»), sin icono, sin viñeta de «ayuda», sin color de aviso, sin rojo/verde moral.
    - **Sin voz**: ninguna línea `VO_*` ni lectura en voz alta. 23 puede decidir que «pista aplicada» no suene o que suene un único `SFX_CLICK_SUBTLE`; nunca una fanfarria ni un «ding» de recompensa.
    - **Duración** según F2 (por defecto 3,0–8,0 s), con fundido de entrada y salida de `note_fade_s`; usa el `GameClock` (la pausa la detiene).
    - **Una nota a la vez.** Si llega otra mientras hay una visible, espera a que la actual lleve al menos `note_min_s`; entonces la sustituye con un fundido cruzado. Cola de un elemento: si llegan varias, gana la más reciente.
    - Al **mostrarse** por primera vez, su clave se añade a `notes` (cuaderno). Una repetición no duplica.
22. **Contexto.** La nota de un puzle `VIEW` (P1, P3, P4, P5, P6) se muestra solo con **su vista abierta** (avisos «vista cercana abierta/cerrada» de 7). Si la pista se aplica con la vista cerrada (p. ej. se pidió desde una pausa en exploración), la clave queda en `pending_text` y se muestra al abrir esa vista. **El aplazamiento del `TEXT` por vista cerrada es solo de 17** (9 no aplaza texto; la regla 26 de 9 y su Edge Case 11 valen solo para efectos de vista no textuales). El panel avisa con `UI_PISTAS_PENDIENTE` † («La verás al volver a esto.»). Para el puzle `WORLD` (P2) no hay vista: la nota sale al reanudar (Open Question 6).
23. **Fin de la nota.** La nota se retira al agotar su duración, al cerrarse la vista del puzle, al pasar este a `RESUELTO` o al pausar y reanudar con otra nota pendiente. Nunca bloquea la entrada ni el cursor.
24. **Reapertura de P6 (D16-14, ratificada).** Al **abrir la vista** de un puzle con niveles `TEXT` de tipo `IDLE` ya aplicados (solo P6), 17 reaplica **una vez** la nota del nivel más alto aplicado, para que el jugador no pierda información que ya tenía; no sale por umbral. Los niveles superiores se rearman desde `idle = 0` (F3 de 9). No se reaplica nada en los demás puzles (evita la pista como cantinela).
25. **Cuaderno de notas.** En el panel, la entrada seleccionada muestra, bajo el botón, las notas ya mostradas de ese puzle, en orden (texto de 18, sin marco ni numeración de «nivel»). Es lectura gratuita e ilimitada y no cuenta como pista. Las pistas no textuales no figuran en el cuaderno (para volver a verlas, «Repetir la última»).
26. **Pistas dentro del panel.** El panel no muestra ningún texto de pista que el jugador no haya visto ya en la escena (regla 12): no se puede leer una pista «gratis» sin haberla pedido.

### F. Estados del puzle y casos especiales de contenido

27. **Puzle `BLOQUEADO`.** No se lista y 17 no llama a 9. Si 9 recibiera la llamada la rechazaría (regla 26).
28. **Puzle `RESUELTO`.** Sale de la lista. Se descartan su `pending_text` y la nota activa (regla 23). Su registro queda en memoria hasta el próximo `reset()` (sin efecto). No se ofrece nada: la información ya fue usada.
29. **Puzle `RESOLVING` (P5).** Inerte, sin llamada. Cuando vuelve a `ACTIVO` (salida de la vista con el hecho de reanudación ya escrito) vuelve a ser pedible.
30. **P4.** El nivel 1 es `availability: ALWAYS` (el texto ya está en el tablero): al pedirlo, la nota repite la regla (D17-7). El nivel 3 (`AUTO_SOLVE_ELEMENT`, solo T1) puede resolver el puzle (regla 12b): 17 refresca el panel tras la llamada y el puzle desaparece de la lista si pasó a `RESUELTO`. Con T1 ya aceptada, el nivel se consume igualmente (17 no lo sabe: el estado de las fichas es de 14). **Ninguna pista decide T4** (regla 12c, D9-42).
31. **P6.** Dos niveles, solo texto, sin pista que señale una opción (D16-4). Pedirlo desde el panel con la vista cerrada deja el texto pendiente (regla 22). La espera entre el nivel 1 y el 2 es 10 s † (igual al hueco entre sus umbrales).
32. **P1.** Con `I-01` ausente, el nivel 1 resalta `V08` (9 aplica `targets_if_missing_items`); 17 no interviene en la elección del objetivo. P1 puede pedirse con la vista cerrada: el resaltado de un objeto del mundo (`V08`) se ve al reanudar.
33. **P2.** Los niveles 2 y 3 (`FLOOR_MARKS`, `BEAM_HALO`) persisten mientras dure la sesión de la escena (R24 de 12); el nivel 1 es transitorio. Sin `IDLE`.

### G. Guardado, carga y reinicios

34. **17 no guarda nada.** `HintLedger`, `notes`, `t_ref` y las esperas son memoria de sesión. No hay hecho nuevo en el catálogo de 3 (los 20 hechos del D.2 son un conjunto cerrado), ni causa de guardado de 5. `hint_level_reached` tampoco se guarda (regla 26 de 9, AC-34, D9-38).
35. **Cuándo se vacía el registro.** Al cargar (Continuar), al empezar «Nueva partida» y, en general, cada vez que 9 se (re)configura (hoy, al cargar la escena de planta; 9 emite «puzles configurados» al terminar la configuración de todos los puzles: regla 8 y D9-80 de 9, declarado en la regla 10 de 3). Tras vaciar: `applied = ∅`, `notes = []`, `t_ref` indefinido (espera 0) y se **rehace la lista** (regla 5; sin compromisos todavía, solo se listan los puzles con `discover_if` por hecho). Si queda vacía con puzles `ACTIVO`, el panel muestra `UI_PISTAS_SIN_LISTA` y no «Nada pendiente» (regla 7, D17-25).
36. **Consecuencia de diseño.** Tras cargar, el jugador puede volver a subir la escalera desde el nivel 1 y las afordancias persistentes (`SLOT_SILHOUETTES`, `FLOOR_MARKS`…) hay que pedirlas de nuevo. Se acepta (D17-6): no cuesta nada, no bloquea y evita añadir hechos. El tiempo extra de rehacer 1–3 niveles es ≤ 60 s (F3).

### H. Tono y límites (lo que 17 nunca hace)

37. **Nunca** escribe, corrige ni resume un texto de pista; nunca añade «ánimo», elogio, reproche ni humor; nunca cuenta, muestra ni guarda cuántas pistas se pidieron (ni en pantalla de fin, ni en logros, ni como hecho); nunca cambia un `carta_variante`, una línea de la llamada ni un hecho según las pistas; nunca usa voz.
38. **Nunca confirma una intención** (pilar *Información incompleta*): las pistas son énfasis de hechos observables (regla 27 de 9). Si un texto de 18 lo hiciera, es un defecto de contenido, no una regla de 17 (checklist de AC-X1 de 9).
39. **Nunca bloquea ni demora la historia.** Una pista pedida o por inactividad no cierra puertas, no avanza el reloj de escena y no interrumpe una línea de voz ni la llamada (la llamada y el apagón ocurren fuera de puzles; 17 no tiene nada que aplicar entonces).
40. **Accesibilidad.** Todo el panel se maneja con teclado, ratón y mando (`ui_*`, contexto `menú` de 1); sin acciones de mantener ni de precisión; nada depende de un temporizador visible; la espera se indica con botón apagado y texto (`UI_PISTAS_ESPERA`), no solo con color.

## Formulas

### F1 · Espera antes de pedir un nivel

`espera(p, k) = max(0, gap(p, k) − (t_ahora − t_ref(p)))`

| Variable | Tipo | Rango | Descripción |
|---|---|---|---|
| `p` | puzle | P1–P6 | Puzle de la entrada |
| `k` | int | 1–3 (1–2 en P6) | Nivel que se pide (el menor no aplicado) |
| `gap(p, k)` | float (s) | 0–120 | Espera exigida para el nivel `k` (tabla): `gap(·,1) = 0`; `gap(·,2) = 20 s†`; `gap(·,3) = 40 s†`; **P6**: `gap(P6,2) = 10 s†` |
| `t_ahora` | float (s) | ≥ 0 | `GameClock`; en pausa no avanza |
| `t_ref(p)` | float (s) | ≥ 0 o `−∞` | Instante de la última pista **nueva** aplicada en `p` (por petición o por inactividad). Sin ninguna aplicada, `−∞` y `espera = 0` |

**Output Range:** 0 ≤ `espera` ≤ `gap`. Se evalúa **al abrir el panel y en cada pulsación de «Pedir»**, no por fotograma: el panel solo existe en pausa y con la pausa el `GameClock` está parado, así que dentro del panel la espera **no avanza** (D17-4, D17-20: la pausa no «gasta» la espera; solo la gasta jugar). No hay relleno animado ni cuenta atrás en el panel.
**Example (P4):** N1 pedido a `t = 300,0`. A `t = 312,5`: `espera(P4, 2) = max(0, 20 − 12,5) = 7,5 s`. A `t = 321`: 0; N2 aplicado, `t_ref = 321`. A `t = 330`: `espera(P4, 3) = max(0, 40 − 9) = 31 s`.
**Example (auto + petición, P3):** nivel 3 sale a los 60 s de inactividad en `t = 500` (`applied = {3}`, `t_ref = 500`). El jugador pide a `t = 502`: el siguiente es `k = 1` y `gap = 0` → se aplica; `t_ref = 502`. Pide `k = 2`: `espera = max(0, 20 − (t − 502))`.
**Nota de control:** la repetición (regla 13) y la nota de reapertura (regla 24) **no** fijan `t_ref` ni consumen espera.

### F2 · Duración de una nota de texto

`t_nota = clamp( n_palabras / lectura_pps + lectura_margen_s , note_min_s , note_max_s )`; si el efecto `TEXT` declara `duration_s`, **manda el dato**: `t_nota = duration_s`.

| Variable | Tipo | Rango | Descripción |
|---|---|---|---|
| `n_palabras` | int | 1–40 | Palabras del texto de 18 (contadas por espacios al cargar) |
| `lectura_pps` | float (palabras/s) | 2,0–4,5 | Velocidad de lectura supuesta, `3,0†` (≈ 180 palabras/min, cómoda y algo lenta) |
| `lectura_margen_s` | float (s) | 0,5–2,0 | Margen de reacción, `1,0†` |
| `note_min_s` / `note_max_s` | float (s) | 2,0–5,0 / 6,0–12,0 | Mínimo `3,0†` y máximo `8,0†` |

**Output Range:** 3,0–8,0 s (sin `duration_s`). El fundido (`note_fade_s`) está **dentro** de la duración.
**Examples** (conteo de las 8 claves del slice):

| Clave | Palabras | `t_nota` |
|---|---|---|
| `PISTA_P1_N2` «Ordena por hora de envío» | 5 | 3,0 s (mínimo) |
| `PISTA_P2_N1` «El memorando está escrito en espejo. Un haz lo muestra mejor que la luz directa» | 15 | 6,0 s |
| `PISTA_P4_N1` «Acepta lo que tiene urgencia y responsable. Devuelve lo que no te corresponde» | 13 | 5,33 s |
| `PISTA_P4_N3` «La urgencia sigue al plazo; el responsable, a quien ya lleva el caso» | 13 | 5,33 s |
| `PISTA_P5_N1` «El reflejo muestra algo que la foto de la caja no muestra» | 12 | 5,0 s |
| `PISTA_P5_N2` «Compara las dos fotos con atención» | 6 | 3,0 s |
| `PISTA_P6_N1` «Solo puedes elegir una vez» | 5 | 3,0 s |
| `PISTA_P6_N2` «La carta no cambia; cambia la primera frase» | 8 | 3,67 s |

(Conteos revisados contra el texto de 18. `PISTA_P2_N1` da 6,0 s por F2, pero mientras P2 conserve `duration_s: 2.0` manda el dato: 2,0 s.)

**Discrepancia detectada:** P2 declara `duration_s: 2.0` en su `TEXT` (12, JSON; `hint_text_s` de 9). Con 15 palabras, 2,0 s no alcanza para leerla (≈ 6 s). El slice (B.2) fija 2 s para **el texto de F1 en espejo** (vista previa), no para la frase de pista. Se propone a 12 y a 9 quitar el `duration_s` del `TEXT` de P2 (cambio 5), **pero es una reinterpretación de una línea literal del slice (B.2: «2 s el texto de F1 en espejo») y 12 tiene abierta la Q12-4: no se propaga hasta confirmarlo con 12 (OQ 5, decisión consciente frente al slice, D17-22)**. Hasta entonces, el dato manda y el cuaderno cubre la relectura.

### F3 · Tiempo mínimo para llegar al nivel `k` pidiendo (referencia de diseño)

`T_min(p, k) = Σ_{j=2..k} gap(p, j)`

| Puzle | `T_min` nivel 1 / 2 / 3 | Objetivo de F7 de 9 (jugador nuevo) | `T_min(3)` / mínimo de F7 |
|---|---|---|---|
| P1 | 0 / 20 / 60 s | 2–4 min | 50 % del mínimo |
| P2 | 0 / 20 / 60 s | 3–6 min | 33 % |
| P3 | 0 / 20 / 60 s | 1,5–3 min | 67 % |
| P4 | 0 / 20 / 60 s | 2–4 min | 50 % |
| P5 | 0 / 20 / 60 s | 1,5–3 min | 67 % |
| P6 | 0 / 10 s (sin nivel 3) | 0,5–2 min | `T_min(2)` = 33 % |

**Lectura.** El nivel 1 está siempre a un gesto (es el más suave). Llegar al nivel 3 pidiendo exige ≥ 60 s de juego desde la primera pista de ese puzle (o desde la última aplicada): no impide pedir ayuda a quien está atascado de verdad, pero evita la escalera de tres pulsaciones en 5 s. Es una **estimación de diseño sin datos**: el criterio 5 del slice (≥ 50 % identifica la diferencia del P5 sin nivel 3) y AC-X3 de 9 la contrastan en playtest, y `gap` es un knob de curva.

## Edge Cases

1. **Pausa en `RESOLVING` (P5, ~16 s).** El panel muestra la entrada inerte; no hay llamada, ni `HintResult` registrado en el log más allá de «ocupado». Al terminar la secuencia el puzle pasa a `RESUELTO` y sale de la lista.
2. **El puzle se resuelve dentro de la propia petición** (P4 nivel 3 con las otras tres fichas ya decididas). 9 procesa `evaluate()` y la resolución (regla 12b). 17 anota el nivel en `applied` (la llamada devolvió `true`), refresca la lista y el puzle desaparece. Los hechos y avisos de la resolución ya se escribieron en el acto (regla 26); la presentación espera a reanudar.
3. **`request_hint` devuelve `false`** (p. ej. un `SOLVED` llegó entre la comprobación y la llamada). 17 no modifica el registro, anota «pista rechazada» y refresca el panel; no muestra error. No hay estado inconsistente: `applied` solo cambia con `true`.
4. **Doble pista en el mismo fotograma** (petición desde pausa + «puzle inactivo» al reanudar). La inactividad de 9 no avanza en pausa y cada nivel se aplica una vez (`applied` es un conjunto): el segundo `request_hint` del mismo nivel se ignora. Las notas se encolan (regla 21).
5. **Cargar con el panel de un puzle ya parcial.** `reset()` vacía todo; la lista se rehace y solo salen los puzles con `discover_if` por hecho hasta que el jugador se comprometa de nuevo. Un jugador que carga en mitad del P4 y abre el panel **sin volver a abrir la vista** verá la lista vacía con `UI_PISTAS_SIN_LISTA` (no «Nada pendiente», que sería falso: D17-25): consecuencia aceptada de la regla anti-spoiler (D17-5), pedirá una pista en cuanto abra la vista de nuevo. Alternativa evaluada: listar por reconstrucción de hechos (`caja_c1`, etc.), descartada por añadir lecturas de hechos para un caso raro.
6. **P3 nivel 3 por inactividad sin pieza en la mano.** El umbral queda vencido y sin consumir (F3 de 9); 17 no registra nada. Si luego el jugador agarra una pieza, 9 **vuelve a emitir** «puzle inactivo» (regla 16) y 17 llama a `request_hint`: si devuelve `true`, registra `{3}`. Mecanismo único (la regla 16); 17 no depende de «pista aplicada» para registrar niveles.
7. **Pedir la pista de nivel `k` mientras otra nota se muestra.** La nota nueva espera a `note_min_s` de la actual; si pasa a `RESUELTO` o se cierra la vista, la cola se descarta.
8. **Clave `PISTA_*` inexistente en 18.** La validación de 9 aborta la carga (reglas 27 y 29; AC-30a): no se llega a 17. Si por un fallo aun así no hay texto en tiempo de ejecución, 17 muestra nada, anota el error y **no** añade el nivel a `applied` (no gasta una pista que no se vio).
9. **Pista pedida con la vista cerrada y nunca se reabre.** `pending_text` queda en memoria hasta `RESUELTO` o `reset()`; el puzle se resuelve sin que se vea (sin coste).
10. **P4 nivel 1 («ya visible»).** Pedirlo repite la regla en una nota (5,0 s) aunque ya esté en el tablero. Es un nivel «gastado» sin información nueva, **por diseño del slice** (B.4); no se salta (D17-7) porque eliminaría el escalón y rompería «tres niveles».
11. **Repetir con un efecto persistente ya activo** (`MARK_LIT`, `FLOOR_MARKS`): `UI_PISTAS_YA_VISIBLE`; sin llamada nueva si 9 informa de que no cambia nada.
12. **Spam del botón con espera.** Como el panel está en pausa y el `GameClock` no corre, pulsar de nuevo **no** acerca la disponibilidad: hay que reanudar y jugar. Cada pulsación inerte suena `SFX_CLICK_SUBTLE` y repite `UI_PISTAS_ESPERA` (que lo dice sin cuenta atrás); no se acumula nada (sin cola de pulsaciones, sin castigo).
13. **Sin ningún puzle listado:** en Recepción o al final (todos `RESUELTO`/`BLOQUEADO`) el panel muestra `UI_PISTAS_NADA`; al empezar o tras cargar, con algún puzle `ACTIVO`, `UI_PISTAS_SIN_LISTA` (D17-25). El menú de pausa puede mostrar la entrada «Pistas» siempre; 17 no oculta la entrada (decisión de 25).
14. **Mando desconectado o pérdida de foco con una nota visible.** El `GameClock` se detiene; al reanudar la nota continúa con el tiempo que le quedaba.
15. **Reapertura de P6 con la cola ocupada.** La nota reaplicada de D16-14 espera su turno (regla 21) y se descarta si la vista se cierra.
16. **Degenerate: pedir todas las pistas siempre.** No hay recompensa, penalización ni medidor: la ganancia es mecánica (resolver más rápido) y el coste es de F3 (≥ 60 s) y de «solo la pista 1 orienta» (P1). Es una decisión de autonomía legítima (pilar 3). El riesgo es el criterio 5 del slice; se mide, no se castiga.
17. **Degenerate: usar «Repetir» para mantener una pista persistente en pantalla.** Inocuo (la pista no cambia el estado ni resuelve; salvo P4 nivel 3, que ya se consumió).
18. **Dos entradas con el mismo puzle** no existen (una por puzle). **Etiquetas con `discover_if` por hecho** (P1): un hecho que se pierde (`correos_leidos` no se pierde: un solo sentido, 3, regla 4) no puede volver la entrada a «no conocida».
19. **Cambio de idioma o de tamaño de interfaz** (el tamaño es `escala_texto_ui` de 30; el slice no cambia de idioma en partida): las notas se recalculan por F2 (`n_palabras` del texto traducido) y los textos del cuaderno se refrescan por clave.

## Dependencies

Dureza según el criterio del índice (la declara el dependiente y los proveedores la repiten). Dirección: «→» es lo que 17 recibe; «←» lo que 17 da.

| Sistema | Dureza | Dirección | Contrato |
|---|---|---|---|
| **3 Estado y bus** | **Dura** | → | Suscripción a los avisos «pista aplicada», «puzle inactivo», «puzle activado» y «puzles configurados» (emisor 9; declarados en la regla 10 de 3); lectura de `correos_leidos` (propietario 19; 3 lo anota ya como lector de 17) para `discover_if` de P1. Emite «sonido pedido» (`SFX_CLICK_SUBTLE`, botón inerte; 3 regla 10, fila «Emisores de «sonido pedido»»). **No escribe ningún hecho ni emite otros avisos.** `formulario_leido` y `memo_leido` quedan **sin uso** en el slice (D17-10; 3 y 20 lo reflejan; Open Question 2) |
| **9 Marco de puzles** | **Dura** | ↔ | → `list_puzzles()` (estado, `mode`, vista, último compromiso, `hint_level_reached`), `get_hints(id)`, `request_hint(id, level)` (incluida su reaplicación, ‡), «puzle inactivo» `(id, nivel)`. ← el reparto de pistas automáticas (`idle_hints_auto_apply = false`) y la política de espera y de presentación del texto. **Reparto de la aplicación (D17-21):** 9 aplica `HIGHLIGHT`/`AFFORDANCE`/`AUTO_SOLVE_ELEMENT` y delega el `TEXT` (nota y su aplazamiento) en 17 vía `text_key` en «pista aplicada». Reglas 25 a 27 y 36, F3 y D9-37/D9-74 |
| **18 Base de contenido** | **Dura** | → | Las 8 claves `PISTA_*` con texto (regla 20; `hint_key_count`) y las claves `UI_PISTAS_*` ‡ (según la regla de 18 sobre claves provisionales con marcador de pendiente; no son del §12 ni cambian el recuento de 28 ni el de 8 `PISTA_*`) |
| **7 Interacción e inspección** | Blanda | → | «vista cercana abierta/cerrada» con el ID de la vista (contexto de la nota, regla 22). Sin 7, las notas de puzles `VIEW` se muestran al reanudar sin esperar la vista |
| **25 Menú de pausa** | Blanda (la declara 17, el dependiente; 25 debe repetir Blanda) | ← | 17 aporta `HintPanel` y su modelo; 25 lo aloja bajo «Pistas», le da foco y navegación (`ui_*`) y pausa el `GameClock`. **25 no depende de 17** (`menu-de-pausa.md` la aloja bajo «Pistas»; el índice: «el menú de pausa es MVP… 17 se enchufa a su menú después»). Las pistas **no** se colocan en ajustes |
| **11 a 16 Puzles** | Indirecta (vía 9) | → | Sus `hints` (niveles, `trigger`, `idle_s`, `condition`, `availability`, `effects`) y su `mode`/vista; cada uno ya declara a 17 como blanda (11, 13, 14, 16) o indirecta (15), la lectura de `memo_leido` por 12 es de 12 (17 no la comparte; ver la fila de 12, 20 y 19) |
| **1 Entrada y controles** | Ninguna directa | — | **No hay acción `pista`** (Open Question 8 de 1, cerrada); el panel usa el contexto `menú` |
| **5 Guardado y carga** | Indirecta | — | 17 no escribe ni lee el guardado; AC-41b de 5 («el progreso de pistas vuelve al nivel…») se cumple porque 17 no guarda |
| **23 Director de audio** | Blanda | ← | 17 emite «sonido pedido» (`SFX_CLICK_SUBTLE`, botón inerte; emisor 17 en la regla 10 de 3 y en 23 R5); sin 23 el botón no suena. Qué suena con «pista aplicada» lo decide 23 sin voz |
| **26 Subtítulos / 24 Prompt / 6 Ajustes / 30 Accesibilidad** | Ninguna | — | Las notas no son audio (26 no las subtitula); el prompt (24) no interviene; las pistas no son ajustes (6); posible opción «sin espera» de 30 (Open Question 3) |
| **12 Puzle 2 / 20 Documentos / 19 Ordenador** | Ninguna (19: Blanda por `correos_leidos`, vía 3) | — | 17 **no** lee `memo_leido` ni `formulario_leido` (3 ya los anota sin 17; 12 y 20 deben dejar de listar a 17 como lector); 17 sí lee `correos_leidos` de 19 vía 3. La divergencia con el slice D.2 sigue en la OQ 2 |

**Índice:** la fila 17 lista 3, 9, 18; falta añadir las blandas 7, 23, 25 y 19 (ver Cambios requeridos). **Circularidad:** ninguna: 17 depende de 9, 9 no depende de 17 (`idle_hints_auto_apply` de 9 funciona sin 17).

## Tuning Knobs

Todos viven en `assets/data/hints_policy.json` (datos de 17), nunca en código. Categorías: F (feel), C (curva), G (puerta/gate). Los valores con † son propuesta de este GDD.

| Knob | Cat. | Defecto | Rango seguro | Qué afecta / motivo |
|---|---|---|---|---|
| `gap_s[2]` | G | **20 s†** | 0–60 | Espera antes del nivel 2. Frena la escalera instantánea; ≤ 20 s para no frustrar a quien ya está atascado |
| `gap_s[3]` | G | **40 s†** | 0–120 | Espera antes del nivel 3 (el más claro). Protege el criterio 5 del slice (P5 sin nivel 3 ≥ 50 %) |
| `gap_s[2]` de P6 | G | **10 s†** | 0–30 | P6 tiene dos niveles y 30 s de objetivo mínimo; 10 s = hueco entre sus umbrales `IDLE` (10/20 s) |
| `auto_apply` | G | `true` | bool | Aplicar las tres pistas `IDLE` del slice. Si el usuario las quita (Open Question 1), P3 nivel 3 y P6 pasan a solo petición |
| `lectura_pps` | F | **3,0†** | 2,0–4,5 | Velocidad de lectura de F2; subirla acorta las notas |
| `lectura_margen_s` | F | **1,0†** | 0,5–2,0 | Margen de F2 |
| `note_min_s` | F | **3,0†** | 2,0–5,0 | Duración mínima de una nota |
| `note_max_s` | F | **8,0†** | 6,0–12,0 | Duración máxima |
| `note_fade_s` | F | **0,3 s†** | 0,1–0,6 | Fundido de entrada/salida (dentro de la duración) |
| `queue_max` | F | **1†** | 1–2 | Notas en cola (más de 1 acumula ruido) |
| `discover_if` (por puzle) | G | P1: `correos_leidos` · resto: `COMMITMENT` | enum | Cuándo una entrada se lista (anti-spoiler, regla 6) |
| `repeat_enabled` | G | `true` | bool | Mostrar «Repetir la última» |
| `labels` (P1–P6) | F | claves `UI_PISTAS_P1..P6` | claves de 18 | Etiquetas neutras del panel |

**Cruces con 9 (no se duplican aquí):** `idle_s` P3 nivel 3 = 60 s, `idle_s` P6 = 10 s/20 s, `idle_move_px`, `highlight_s` (3,0 s) y `idle_hints_auto_apply` son de 9. **`hint_text_s` (P2, 2,0 s†) queda sustituido por F2** (cambio 5).

## Acceptance Criteria

Etiquetas: L = lógica automatizable; I = integración; PV = playtest/visual con captura retenida.

**Datos y arranque**
- **AC-17-01 (R1–R4, L):** **GIVEN** `puzzles.json` del slice, **THEN** 17 lee 17 niveles (3 en P1–P5, 2 en P6), 8 con `TEXT`, y no define ninguna pista propia; **GIVEN** `hints_policy.json`, **THEN** valida con `schema_version: 1` y todas las claves `label_key` existen en 18.
- **AC-17-02 (R15, L):** **GIVEN** el arranque con 17 activo, **THEN** `idle_hints_auto_apply` de 9 es falso y 17 recibe «puzle inactivo»; **WHEN** 9 se queda sin 17 (prueba de integración), **THEN** `idle_hints_auto_apply` verdadero reproduce las tres pistas automáticas sin error (9 no depende de 17).

**Lista y preselección**
- **AC-17-03 (R5–R7, L):** **GIVEN** una partida nueva sin correos leídos, **THEN** la lista está vacía y el panel muestra `UI_PISTAS_SIN_LISTA` (P1–P4 están `ACTIVO`; **nunca** `UI_PISTAS_NADA`); **GIVEN** todos los puzles `RESUELTO`, **THEN** muestra `UI_PISTAS_NADA`; **GIVEN** una carga con P4 `ACTIVO` y sin compromisos, **THEN** `UI_PISTAS_SIN_LISTA`; **WHEN** `correos_leidos` pasa a verdadero, **THEN** aparece P1; P3 y P4 solo aparecen tras su primer compromiso.
- **AC-17-04 (R5–R7, L):** **GIVEN** P5 `BLOQUEADO`, **THEN** no se lista; **GIVEN** P5 `ACTIVO` sin compromiso, **THEN** no se lista; **WHEN** el jugador abre la vista, **THEN** aparece; **GIVEN** un puzle `RESUELTO`, **THEN** desaparece.
- **AC-17-05 (R9, L):** **GIVEN** pausa desde la vista abierta de P4 con compromisos previos en P1 y P3, **THEN** la entrada preseleccionada es P4; **GIVEN** pausa en exploración con último compromiso P3, **THEN** P3; **GIVEN** `formulario_leido` o `memo_leido` en cualquier valor, **THEN** la preselección no cambia.

**Escalera y espera**
- **AC-17-06 (R10, L):** **GIVEN** P4 sin pistas, **WHEN** el jugador pide tres veces sin esperar, **THEN** la primera aplica el nivel 1, la segunda y la tercera devuelven `WAIT` y no llaman a `request_hint`; **WHEN** el reloj falso avanza 20 s **con el juego en marcha** (no en pausa) y se reabre el panel, **THEN** el nivel 2 se puede pedir; **WHEN** avanzan otros 40 s en marcha, **THEN** el nivel 3; **THEN** `applied = {1,2,3}`, el botón desaparece y queda «Repetir».
- **AC-17-07 (F1, L):** **GIVEN** N1 aplicado a `t = 300,0`, **THEN** `espera(P4,2)` vale 7,5 s a `t = 312,5` y 0 a `t = 321`; **GIVEN** reloj falso detenido (pausa, panel abierto), **THEN** `espera` no avanza y el botón no tiene relleno animado; el texto mostrado es `UI_PISTAS_ESPERA` («Sigue mirando un poco antes de pedir otra.»).
- **AC-17-08 (R10, R16, L):** **GIVEN** P3 con el nivel 3 aplicado por inactividad (`applied = {3}`), **WHEN** el jugador pide, **THEN** el siguiente es el nivel 1 (sin espera); luego el 2 con espera de 20 s desde el 1; el nivel 3 no se vuelve a ofrecer.
- **AC-17-09 (R31, F1, L):** **GIVEN** P6 con la vista abierta y 5 s de juego, **WHEN** el jugador pide el nivel 1 y luego el 2, **THEN** el nivel 2 devuelve `WAIT` hasta 10 s tras el 1; no existe un nivel 3.
- **AC-17-10 (R11.4, L):** **GIVEN** `request_hint` devolviendo `false` (puzle `RESUELTO` entre medias), **THEN** `applied`, `last_applied` y `t_ref` no cambian y se anota «pista rechazada».
- **AC-17-11 (R11.1, R29, L):** **GIVEN** P5 `RESOLVING`, **THEN** el botón está inerte y 17 **no** llama a `request_hint` (AC-66 de 9 sigue valiendo si se llamara).

**Repetición y cuaderno**
- **AC-17-12 (R13, L):** **GIVEN** P1 con N1 y N2 aplicados, **WHEN** «Repetir la última», **THEN** se llama a `request_hint(P1, 2)`, `hint_level_reached` no cambia, `t_ref` no cambia, no hay espera; **GIVEN** `MARK_LIT` ya activo (P5 nivel 3), **THEN** el panel muestra `UI_PISTAS_YA_VISIBLE`.
- **AC-17-12b (R13, I):** **GIVEN** P4 con el nivel 3 ya aplicado (T1 resuelta por `AUTO_SOLVE_ELEMENT`), **WHEN** «Repetir la última», **THEN** solo se repite la presentación (nota/resaltado): no se llama a `AUTO_SOLVE_ELEMENT` ni a `evaluate()`, y ningún hecho ni estado de fichas cambia.
- **AC-17-13 (R25–R26, L):** **GIVEN** P2 con N1 pedido pero la nota aún no mostrada, **THEN** el cuaderno no la incluye y el panel no muestra su texto; **WHEN** la nota se muestra, **THEN** el cuaderno contiene `PISTA_P2_N1`; **WHEN** se repite, **THEN** no se duplica.

**Automáticas**
- **AC-17-14 (R15–R17, L):** **GIVEN** P6 con la vista abierta, **WHEN** pasan 10 s sin pulsar, **THEN** 17 aplica el nivel 1 una vez; a 20 s, el nivel 2; mover el cursor no reinicia; un clic en vacío sí; cada nivel entra en `applied` y fija `t_ref` (cubre AC-31 de 9 con 17 activo).
- **AC-17-15 (R16, L):** **GIVEN** P3 con 60 s sin gesto ni movimiento y sin pieza en la mano, **THEN** 17 no registra nada; **WHEN** el jugador agarra una pieza, **THEN** 9 vuelve a emitir «puzle inactivo» (P3, 3), 17 llama a `request_hint`, se aplica el contorno y 17 registra `{3}` (con `idle_hints_auto_apply = false`).
- **AC-17-16 (R16, L):** **GIVEN** un nivel ya en `applied`, **WHEN** llega su «puzle inactivo», **THEN** se ignora.
- **AC-17-17 (R19, L):** **GIVEN** `auto_apply` falso, **THEN** P6 y P3 nivel 3 no se aplican solos y siguen pudiéndose pedir (IDLE implica REQUEST).

**Presentación**
- **AC-17-18 (R21, F2, L):** **GIVEN** cada una de las 8 claves y la función contadora de palabras de 17 aplicada al texto real de 18, **THEN** `t_nota` = `clamp(n/3,0 + 1,0; 3,0; 8,0)` con ese conteo (±0,05 s; la tabla de F2 es ilustrativa, no el oráculo); **GIVEN** un `TEXT` con `duration_s`, **THEN** manda el dato (P2 mientras conserve `duration_s: 2.0`).
- **AC-17-28 (R5, L):** **GIVEN** P2 `ACTIVO` sin ninguna activación de `B01`–`B03`, **THEN** no se lista; **WHEN** se produce la primera activación válida de un manejador `B01`–`B03` (`first_action`), **THEN** P2 aparece y sus tres niveles (`PISTA_P2_N1`, `FLOOR_MARKS`, `BEAM_HALO`) son pedibles en orden.
- **AC-17-29 (R20–R22, I):** **GIVEN** una petición de P4 nivel 1 con la vista abierta, **THEN** 9 aplica los efectos no textuales, «pista aplicada» lleva `text_key = PISTA_P4_N1` y se muestra **una sola** nota (la de 17); **GIVEN** la vista cerrada, **THEN** solo 17 guarda `pending_text` (9 no aplaza el texto).
- **AC-17-30 (R10, PV, cortable):** **GIVEN** P4 con `applied = {1,2}`, **THEN** los pips muestran 2 de 3 rellenos y, en P6, N = 2; sin cifras ni color moral.
- **AC-17-19 (R21, L):** **GIVEN** una nota visible 1 s y otra que llega, **THEN** la nueva espera a `note_min_s` y sustituye con fundido cruzado; **GIVEN** tres notas seguidas, **THEN** solo queda en cola la más reciente.
- **AC-17-20 (R22, L):** **GIVEN** una pista de P4 pedida desde una pausa en exploración (vista cerrada), **THEN** `pending_text` guarda la clave, el panel muestra `UI_PISTAS_PENDIENTE` y la nota sale al abrir `D01b`.
- **AC-17-21 (R24, L):** **GIVEN** P6 con el nivel 2 aplicado, **WHEN** se cierra y se reabre la vista, **THEN** `PISTA_P6_N2` se muestra una vez al abrir y no vuelve a salir por umbral; en P4, **THEN** no se reaplica nada al reabrir.
- **AC-17-22 (R23, L):** **GIVEN** una nota visible, **WHEN** el puzle pasa a `RESUELTO` o se cierra la vista, **THEN** la nota se retira en `note_fade_s`.
- **AC-17-23 (R21, R37, PV):** **GIVEN** capturas retenidas de una nota en P1, P4 y P6 en `production/qa/evidence/`, **THEN** no hay prefijo ni icono de ayuda, ni color moral, ni voz; el tamaño y el contraste son legibles a 1080p y 720p.

**Estados, guardado, tono**
- **AC-17-24 (R34–R36, I):** **GIVEN** pistas pedidas en varios puzles, **WHEN** se guarda y se carga, **THEN** `applied`, `notes`, `t_ref` y `hint_level_reached` están vacíos, no existe ningún hecho nuevo en el guardado (5) y la lista solo contiene los puzles con `discover_if` por hecho (cubre AC-34 de 9 y AC-41b de 5).
- **AC-17-25 (R37, L):** **GIVEN** una partida completa con pistas pedidas en todos los puzles, **THEN** `carta_variante`, `respuesta_llamada`, `t4_decision` y los demás hechos son idénticos a una partida sin pistas con las mismas decisiones; no existe ningún contador ni estadística de pistas.
- **AC-17-26 (R30, I):** **GIVEN** P4 con T2–T4 decididas y T1 pendiente, **WHEN** el jugador pide el nivel 3 en pausa, **THEN** 9 resuelve T1, llama a `evaluate()` (AC-43 de 9), el puzle pasa a `RESUELTO`, y 17 lo retira de la lista; **GIVEN** T4 sin decidir, **THEN** el nivel 3 no cambia T4 (AC-55 de 9).
- **AC-17-27 (R40, I):** **GIVEN** teclado, ratón y mando, **THEN** todas las acciones del panel (cambiar de entrada, pedir, repetir, cerrar) se hacen con `ui_*`/cursor sin mantener ni apuntar con precisión.

**Experienciales (playtest, `qa.level` minimal permite playtest sin tests automáticos)**
- **AC-17-X1 (PV):** en el primer playtest (≥ 6 testers, AC-X3 de 9), ≥ 4 de 6 encuentran el panel sin ayuda en < 15 s y ninguno dice que la pista «le dijo qué sentir o qué elegir».
- **AC-17-X2 (PV):** ≥ 50 % identifica la diferencia del P5 sin nivel 3 (criterio 5 del slice); si < 50 %, subir `gap_s[3]` (rango hasta 90 s) antes de tocar el contenido.
- **AC-17-X3 (PV):** ningún tester describe la espera como «castigo» o «bloqueo» ni se queda esperando en el menú sin entender que hay que reanudar y jugar; si ≥ 2 lo hacen, bajar `gap_s` a ≤ 10 s o eliminarla (Open Question 3).
- **AC-17-X4 (PV):** la nota de pista se lee entera por ≥ 5 de 6 testers sin pedir «Repetir»; si no, subir `note_min_s`/bajar `lectura_pps`.

## Datos de 17 (`assets/data/hints_policy.json`)

Esquema propuesto (v1), ejemplo del slice:

```json
{
  "schema_version": 1,
  "defaults": {
    "gap_s": { "1": 0.0, "2": 20.0, "3": 40.0 },
    "auto_apply": true,
    "repeat_enabled": true,
    "reading_wps": 3.0, "reading_margin_s": 1.0,
    "note_min_s": 3.0, "note_max_s": 8.0, "note_fade_s": 0.3,
    "queue_max": 1
  },
  "puzzles": {
    "P1": { "label_key": "UI_PISTAS_P1", "discover_if": { "fact": "correos_leidos" } },
    "P2": { "label_key": "UI_PISTAS_P2", "discover_if": "FIRST_ACTION" },
    "P3": { "label_key": "UI_PISTAS_P3", "discover_if": "COMMITMENT" },
    "P4": { "label_key": "UI_PISTAS_P4", "discover_if": "COMMITMENT" },
    "P5": { "label_key": "UI_PISTAS_P5", "discover_if": "COMMITMENT" },
    "P6": { "label_key": "UI_PISTAS_P6", "discover_if": "COMMITMENT",
            "gap_s": { "2": 10.0 }, "reapply_text_on_reopen": true }
  }
}
```

Los niveles, efectos y claves **no** se repiten aquí: viven en `puzzles.json` (9). Escalera completa del slice, para referencia (fuentes: GDD 11 a 16):

| Puzle | Nivel 1 | Nivel 2 | Nivel 3 |
|---|---|---|---|
| P1 | `REQUEST` · `HIGHLIGHT` `C05/paper` (sin `I-01`: `V08`), 3 s | `REQUEST` · `TEXT` `PISTA_P1_N2` | `REQUEST` · `HIGHLIGHT` `C05/paper/stamp_1..4`, 3 s (verificado con 11, R30: es la línea de día y hora de cada bloque numerado en la hoja; el slice B.1 lo describe como «hora de envío en letra pequeña»; énfasis, sin información nueva) |
| P2 | `REQUEST` · `TEXT` `PISTA_P2_N1` + `MIRROR_PREVIEW` | `REQUEST` · `FLOOR_MARKS` | `REQUEST` · `BEAM_HALO` |
| P3 | `REQUEST` · `SLOT_SILHOUETTES` | `REQUEST` · `ROW_NUMBER_ON_HOLD` | `IDLE` 60 s† (`HELD_PIECE`) · `CORRECT_SLOT_OUTLINE` |
| P4 | `REQUEST`, `ALWAYS` · `TEXT` `PISTA_P4_N1` | `REQUEST` · `HOVER_HIGHLIGHT` | `REQUEST` · `AUTO_SOLVE_ELEMENT` (solo T1) + `TEXT` `PISTA_P4_N3` |
| P5 | `REQUEST` · `TEXT` `PISTA_P5_N1` + `HIGHLIGHT` | `REQUEST` · `TEXT` `PISTA_P5_N2` + `HIGHLIGHT` | `REQUEST` · `MARK_LIT` |
| P6 | `IDLE` 10 s† · `TEXT` `PISTA_P6_N1` | `IDLE` 20 s† · `TEXT` `PISTA_P6_N2` | — (no existe) |

## Decisiones tomadas

Decisiones **del usuario** ya firmes y que se recogen (no se discuten): P6 con dos niveles (D9-14); la pista de nivel 1 de P1 es un resaltado, sin cámara (D9-32); pistas `IDLE` también pedibles y efectos al reanudar en pausa (D9-37); las pistas no se persisten (D9-38, con 5). Las demás son recomendación propia de este lote, revisables.

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D17-1 | **Una sola vía de petición: el menú de pausa** (25), más las tres automáticas del slice | Acción de entrada `pista` de un solo botón en juego | El slice (§10, §16) dice «accesibles desde el menú de pausa»; una tecla dedicada añadiría un enlace reasignable a 1, riesgo de uso accidental y pediría ayuda por reflejo (pilar 3). Coste: 3 acciones; revisable si el playtest muestra fricción (Open Question 8) |
| D17-2 | **Escalera sin saltos**: «Pedir» da el siguiente nivel no aplicado; el jugador no elige el nivel | Selector de nivel 1/2/3 por puzle | El nivel 3 es el más claro (P4: resuelve T1; P5: marca los 40°); un acceso directo lo convertiría en «el botón de solución» y vaciaría los niveles 1–2. Pilar 3 y criterio 5. Resuelve además la Open Question 8 de 16 (pedir el 2 sin el 1 no ocurre desde 17) |
| D17-3 | **Registro propio de niveles aplicados** (conjunto `applied`) en vez de solo `hint_level_reached` | Usar el máximo de 9 | Con la pista automática P3 nivel 3 el máximo sería 3 con los niveles 1 y 2 sin ver; el jugador se quedaría sin ellos. 9 conserva su máximo (monotonía, AC-34); 17 añade el conjunto |
| D17-4 | **Espera corta entre niveles** (20 s† al nivel 2; 40 s† al 3; P6: 10 s†), medida con el `GameClock` (la pausa no avanza) | Sin espera (defecto de 9) · tope duro de pistas por puzle/partida | Sin espera, tres pulsaciones dan el nivel 3 en 3 s y dañan el criterio 5 (9, Edge Cases: «se resuelve en 17, espaciado»). Un tope duro es castigo (pilar 4, prioridad 1). La espera es proporcional (≤ 60 s) y no bloquea nada. La pausa no la avanza para que **jugar** (no esperar en el menú) sea lo que la gasta (ver D17-20 para la consecuencia de interfaz) |
| D17-5 | **Anti-spoiler: solo se listan los puzles ya conocidos** (compromiso previo, o `correos_leidos` en P1) | Listar todos los `ACTIVO` | P3 y P4 están `ACTIVO` desde el inicio; listarlos revelaría la caja y sus funciones. P1 va por hecho porque necesita su nivel 1 antes de poder comprometerse (falta `I-01`) |
| D17-6 | **17 no persiste nada** | Persistir niveles aplicados con un hecho nuevo o en el registro de guardado | El D.2 del slice es un conjunto cerrado de 20 hechos; D9-38 y el AC-41b de 5 ya asumen que el progreso de pistas se pierde. Coste ≤ 60 s de reescalar (F3) y sin bloqueo |
| D17-7 | **P4 nivel 1 (`ALWAYS`) cuenta como nivel y repite la regla en una nota** | Marcarlo aplicado al abrir y empezar en el 2 · ocultarlo | Mantiene «tres niveles» (B.4) con una sola regla uniforme; el coste es un «escalón vacío» en una vista donde el texto ya está. Se anota como Edge Case 10 |
| D17-8 | **Las notas de texto las dibuja 17 como nota sobria** (sin prefijo, icono, voz ni marco), con duración F2 y cuaderno de relectura | Que 9 las dibuje con `hint_text_s` fijo · que Vera las diga con `VO_V_*` | 9 declara que la interfaz de pistas es de 17 (línea «Pistas» de UI Requirements). Un `hint_text_s` fijo de 2 s no alcanza para 15 palabras. La voz contradice «`VO_V_*` comenta, no instruye» y *El espacio expresa la emoción* |
| D17-9 | **Sin pistas de orientación fuera de los puzles** | Una pista por escena («ve al Archivo», «lee el formulario») usando `formulario_leido` | Las 8 claves `PISTA_*` son cerradas (18, D18-1); añadir pistas de escena cambia el contenido y el alcance. Se eleva como Open Question 2 |
| D17-10 | **`formulario_leido` y `memo_leido` no se leen en el slice** | Usarlos para la preselección o para una pista de escena | `memo_leido` es redundante con P2 `RESUELTO`; `formulario_leido` solo tendría sentido con una pista de la escena 3 que no existe (D17-9). Leerlos sería código muerto. Se piden cambios en 3, 12 y 20 (Open Question 2) |
| D17-11 | **17 asume las pistas `IDLE`** y 9 las deja en falso (`idle_hints_auto_apply = false`) | Dejar a 9 aplicarlas por sí mismo | Un solo dueño del reparto (9 lo prevé) y del registro: si 9 las aplicara, 17 no sabría qué niveles se vieron. 9 conserva la medida de inactividad |
| D17-12 | **Las automáticas ignoran la espera** | Que también respeten F1 | Los umbrales son los tiempos del Anexo B (10/20/60 s); F1 se refiere a lo que el jugador **pide** |
| D17-13 | **Reapertura de P6: se reaplica una vez la nota del nivel más alto aplicado; en el resto de puzles, no** (ratifica D16-14) | Reaplicar en todos los puzles; no reaplicar nunca | En P6 la pista llega mientras se mira; al volver, perder la información ya dada es lo peor. En P1–P5 las pistas son afordancias persistentes o notas que el cuaderno guarda: reaplicar sería cantinela |
| D17-14 | **La nota se muestra con la vista abierta de su puzle; si no, queda pendiente** | Mostrarla siempre al reanudar | Un texto sobre «el tablero» en el pasillo no tiene contexto (regla 26 de 9, Edge Case 11 ya lo pide para efectos de vista). P2 no tiene vista: sale al reanudar (Open Question 6) |
| D17-15 | **El panel no muestra el texto de una pista que no se haya visto en escena** | Mostrar el texto en el panel al pedirla | Evita leer «gratis» una pista sin su contexto; la primera lectura es en la escena (pilar 3) y el cuaderno guarda la relectura |
| D17-16 | **Repetir es libre, sin espera, sin tope** | Limitar repeticiones | Repetir no da información nueva; limitarlo sería castigar no haber leído a tiempo (pilar 4) |
| D17-17 | **Sin contador, estadística ni logro de pistas** | «Sin pistas» como logro o dato en la pantalla final | Anti-pilar (*NOT medidores*) y *Tensión sin castigo*. Los pips del panel muestran el estado de la escalera de esa sesión, no una puntuación |
| D17-18 | **Textos de interfaz propios `UI_PISTAS_*`** (nada, pedir, repetir, espera, lista, pendiente, ya visible, nombres P1–P6), provisionales en 18 | Reutilizar claves `PISTA_*` para la interfaz · literales en el código | Las `PISTA_*` son un conjunto cerrado de 8 (regla 20 de 18); los literales en código están prohibidos (regla de 9, textos de puzle) |
| D17-19 | **17 no escribe en `puzzles.json` ni en ajustes**; sus datos van en `hints_policy.json` | Meter `gap_s` en `puzzles.json` | `puzzles.json` es el esquema v2 de 9; la política de reparto es de 17 (reglas 25–27 de 9: «el marco no decide cuándo se ofrece una pista»). Las pistas no se colocan en ajustes (nota del índice sobre 25) |
| D17-20 | **(Ronda 1, B-1/B-2.) P2 (`WORLD`) se lista tras su primera acción** (`discover_if: FIRST_ACTION`: primera activación válida de `B01`–`B03`). **La espera usa el `GameClock` y el panel no la anima**: texto verdadero `UI_PISTAS_ESPERA` («Sigue mirando un poco antes de pedir otra.»), evaluación al abrir/pedir | P2 por «entrada a Sala B» (necesita un hecho de sala no verificado en 3/12; queda como alternativa a confirmar) · reloj de pared con relleno animado en el panel | `COMMITMENT` no existe en un `WORLD` (regla 11 de 9) y dejaba P2 sin pistas. El reloj de pared haría que esperar en el menú gastase la espera, contra «jugar es lo que la gasta» y D9-37 (la pausa congela todo), y añadiría un segundo reloj |
| D17-21 | **(Ronda 1, B-4.) Contrato del `TEXT`:** 9 aplica efectos no textuales y delega el `TEXT` en 17 vía `text_key` en «pista aplicada»; el aplazamiento por vista cerrada es solo de 17. Para P3 nivel 3, mecanismo único: 9 re-emite «puzle inactivo» al cumplirse la condición | 9 dibuja el `TEXT` · 17 relee `get_hints` | Un único presentador evita la doble nota y el doble aplazamiento; el campo en el aviso evita una lectura extra |
| D17-22 | **(Ronda 1, W-5.) El cambio 5 (quitar `duration_s: 2.0` del `TEXT` de P2) no se propaga hasta confirmarlo con 12 (Q12-4).** Decisión consciente frente a la línea literal del slice B.2 | Aplicarlo ya | Reinterpreta el slice; hasta entonces manda el dato (2,0 s) y el cuaderno cubre la relectura |
| D17-23 | **(Ronda 1, W-6.) «Repetir» solo repite presentación**, nunca `AUTO_SOLVE_ELEMENT` ni `evaluate()` | Reaplicar todos los efectos | La reaplicación no debe tener consecuencias de estado (AC-17-12b) |
| D17-24 | **(Ronda 1, W-2/W-3.) Cuaderno, «Repetir», pips y aplazamiento de notas se marcan «cortables»** y se elevan como OQ 11; los pips se definen (regla 10, AC-17-30) | Quitarlos ya · dejarlos sin definir | No están en el slice (§10/§16); el slice sobrevive sin ellos. Decide el usuario |
| D17-25 | **(Ronda 9, R9-B1 y A4 de `cross-review-r10-diseno-y-pilares.md`.) Estado vacío del panel:** `UI_PISTAS_NADA` solo si ningún puzle está `ACTIVO`/`RESOLVING`; con algún `ACTIVO` y lista vacía (partida nueva, o tras cargar), `UI_PISTAS_SIN_LISTA` † («Todavía no has examinado nada de lo que pueda salir una pista.»), sin botón ni nombres. Además: 17 lee `correos_leidos` y no `formulario_leido` ni `memo_leido` (unificado con 3 y 20), emite «sonido pedido» (`SFX_CLICK_SUBTLE`) y consume «puzles configurados» de 9; las durezas son las que declara 17 (3 Dura, 9 Dura, 18 Dura, 7 y 25 Blandas, 23 Blanda) | Listar tras cargar todos los puzles `ACTIVO` (rompe el anti-spoiler de P3 y P4 para quien carga en el inicio) · reconstruir el compromiso desde hechos (D17-5, más lecturas para un caso raro) · dejar «Nada pendiente» (falso: afirma que no queda nada con puzles activos) | Es la opción más segura: nunca dice nada falso, no filtra la existencia de puzles y no añade lecturas de hechos. Clave nueva `UI_PISTAS_SIN_LISTA` provisional en 18. |
| D17-26 | (Ronda 10) Cerrada la ‡ de «puzles configurados» (3 regla 10 lo declara; emisor 9, consumidor 17) y la de la entrada «Pistas» en 25 (regla 14); `memo_leido`/`formulario_leido` quedan dichos una sola vez (fila de 12, 20 y 19 en Dependencies y D17-10); las ‡ de claves `UI_PISTAS_*` y del sonido de «pista aplicada» siguen abiertas (18 y 23 aún no las recogen) | Dejar las ‡ | Un contrato ya declarado no es propuesta; las abiertas conservan su motivo. |

## Open Questions

Las cuestiones de **tono, pilares o alcance** no se deciden aquí.

| # | Pregunta | Quién decide | Impacto / decisión por defecto |
|---|---|---|---|
| 1 | **¿Las tres pistas automáticas respetan el pilar 3 (autonomía)?** P3 nivel 3 contornea el hueco correcto tras 60 s sin gesto; P6 aparece a los 10 y 20 s. Son parte del Anexo B (decisión del slice), pero «escenas que resuelven el puzle por el jugador» violan el pilar. Opciones: (a) mantenerlas (defecto); (b) volverlas solo pedibles (`auto_apply = false`); (c) que el jugador pueda desactivarlas en el panel (haría falta una preferencia persistente en 6) | Usuario / creative-director | Pilares 3 y 4; `auto_apply`; AC-17-17. **Por defecto (a)** |
| 2 | **`formulario_leido` y `memo_leido` sin uso.** El slice (D.2) los anota como «pistas de la escena 3» y «pistas, recompensa de B», pero no define ninguna pista de escena ni clave para ella (las 8 `PISTA_*` son cerradas). Si se quisiera una pista de orientación («lee lo que encontraste en el Archivo», «vuelve a la Sala B»), requeriría claves nuevas y subiría el alcance. Opciones: (a) sin pista de escena y 17 no lee esos hechos (defecto); (b) añadir pistas de escena; (c) mantener (a) y **anotar la divergencia en el D.2 del slice** | **Decide el usuario** | **Por defecto (a):** no hay pista de escena (ya aplicado en 3; los cambios en 12 y 20 NO se propagan hasta que el usuario decida; **pendiente de decisión del usuario**). Divergencia con slice D.2 (líneas 1057/1060) anotada en el Historial |
| 3 | **La espera entre niveles (20/40 s)** ¿es aceptable frente a *Tensión sin castigo* (prioridad 1)? ¿Debe haber una opción de accesibilidad «sin espera»? | **Pendiente de decisión del usuario** (con 30, OQ 1 de 30: lazo cerrado, el dueño es el usuario) | **Por defecto actual:** espera corta (20/40 s), sin opción; se mide con AC-17-X3. El pilar 4 lista «un temporizador que decida por el jugador» como violación. Si se quiere la opción, la define 30 (no 6/25: «las pistas no son ajustes») |
| 4 | **Textos de interfaz y nombres de puzle** (`UI_PISTAS_*`, regla 8): tono, longitud y si los nombres de P5 («El reflejo») o P6 («La carta») anticipan demasiado | Writer / narrative-director | Provisionales †; no tocan el recuento de 28 ni el de 8 |
| 5 | **Duración de la nota de P2** (`duration_s` 2,0 s en 12 frente a F2 = 6,0 s) | Game-designer (12) con 9; **decide el usuario** (reinterpreta B.2 del slice) | Cambio 5 no propagado; por defecto manda el dato (2,0 s) hasta confirmar Q12-4 |
| 6 | **P2 es `WORLD`: ¿la nota debe esperar a que el jugador esté en Sala B?** Hoy sale al reanudar, esté donde esté, y la vista previa en espejo del cristal solo se ve allí | Game-designer (12) / 7 | Defecto: al reanudar. Si molesta, 9/7 exponen la habitación actual |
| 7 | **P4 nivel 1 (`ALWAYS`)** repite una regla ya visible. ¿Aceptable, o el nivel 1 debería aportar otro matiz? | Game-designer (14) | Defecto D17-7; el contenido es del slice (B.4) |
| 8 | **Fricción de la petición** (pausa → Pistas → Pedir). Si el playtest la ve alta, ¿hay una acción de entrada «pista» (D17-1 descartada)? Entrada (1) cerró su OQ 8 por decisión del usuario | Usuario / ux-designer con 1 | Defecto: no. AC-17-X1 |
| 9 | **¿`request_hint` de 9 acepta reaplicar** un nivel ya aplicado sin cambiar `hint_level_reached`? | Game-designer (9) | Si no, 17 degrada «Repetir» a releer el cuaderno (solo `TEXT`) |
| 10 | **Pips del panel** (número de niveles aplicados/total): revelan que P6 tiene dos niveles y los demás tres. ¿Se acepta o se ocultan? | **Pendiente de decisión del usuario** (roza el anti-pilar «NOT medidores») | Defecto actual: se muestran (el slice ya lo dice) |
| 11 | **Alcance de la interfaz extra:** cuaderno de notas, «Repetir la última», pips y aplazamiento de notas no están en el slice (§10/§16 solo piden «pistas en tres niveles en el menú de pausa») y dependen de 25 (ya redactado). ¿Se mantienen o se cortan? | **Pendiente de decisión del usuario** | Por defecto: se mantienen marcados «cortables»; el slice sobrevive sin ellos. «Repetir» depende además de la OQ 9 |
| 12 | **Alternativa de la espera:** si el playtest (AC-17-X3) muestra que la espera con reloj de juego confunde, ¿pasar a reloj de pared con relleno animado (D17-20)? | **Decide el usuario** | Por defecto: reloj de juego, texto veraz |

## Cambios requeridos en otros GDDs

Este GDD no ha editado ningún archivo existente. Cambios a aplicar (los coordina `producer`, regla 4 de coordinación) **en una sola pasada, tras el re-review de este GDD**. **Ronda 9:** 3 ya refleja las lecturas de 17 (`correos_leidos`, no `formulario_leido` ni `memo_leido`) y declara «puzles configurados» y «sonido pedido»; 9 emite «puzles configurados» (cambio 4 de 9 aplicado, D9-80). Quedan **condicionados** (no aplicar aún): los de 12 y 20 sobre `memo_leido`/`formulario_leido` (OQ 2) y el cambio 5 de 9/12 (OQ 5). Pendiente además de reciprocidad: 7 y 18 (dependientes de 17), claves `UI_PISTAS_*` y registro (`hint_gap_s_*`…) en `entities.yaml`/18, y la fila 17 del índice.

| GDD | Cambio | Motivo |
|---|---|---|
| `systems-index.md` | Fila 17: estado «Borrador (lote autónomo)», ruta `design/gdd/sistema-de-pistas.md`, dependencias «3, 9, 18 (duras) · blanda 7 · ‡ 25 (aloja el panel; 25 no depende de 17)»; prioridad y nota de 25 sin cambios; añadir «17 depende de 11–16 (indirecta vía 9)»; Next Steps: GDD 25 debe alojar `HintPanel` | Existe el GDD |
| `marco-de-puzles.md` (9) | (1) `idle_hints_auto_apply` = **falso** en los datos cuando 17 existe (la regla 26 y el knob siguen valiendo sin 17); **y 9 vuelve a emitir «puzle inactivo» cuando la `condition` pasa a cumplirse con el umbral ya vencido** (P3 nivel 3); (2) confirmar D9-74 con 17; (3) **`request_hint(id, level)` con `level` ya aplicado = reaplicación** (no cambia `hint_level_reached`, no consume umbral, no emite «pista aplicada» nueva) y definir lo mismo para un nivel inferior al máximo; (4) emitir «puzles configurados» tras cada `configure` (para el `reset()` de 17); (5) quitar `duration_s: 2.0` del `TEXT` de P2 y el knob `hint_text_s` (sustituido por F2 de 17), conservando `mirror_preview_s`; (3b) la reaplicación **solo repite la presentación**: nunca `AUTO_SOLVE_ELEMENT` ni `evaluate()` (AC-17-12b); (5b) **«pista aplicada» lleva `(id, nivel, text_key)`**; 9 aplica `HIGHLIGHT`/`AFFORDANCE`/`AUTO_SOLVE_ELEMENT` y **delega el `TEXT` en 17** (nota y aplazamiento por vista cerrada solo en 17); ajustar la regla 26/Edge Case 11 de 9 y su Dependencies; (6) `list_puzzles()` devuelve por puzle: estado, `mode`, `view_id`, último compromiso (o `null`), `first_action` (para `WORLD`: primera activación válida de un manejador, P2) y `hint_level_reached`; (7) cerrar la Open Question sobre monotonía/reapertura con D17-3, D17-13; (8) «UI Requirements/Pistas»: el panel lo aloja 25 con contenido de 17; (9) añadir `sistema-de-pistas.md` a Cross-References | Contratos de las reglas 25 y 26 |
| `estado-y-bus-de-eventos.md` (3) | Fila 17 de «Interactions»: lee **`correos_leidos`** (no `formulario_leido` ni `memo_leido`); suscripciones a «pista aplicada», «puzle inactivo», «puzle activado» y «puzles configurados» (**aplicado:** 3 ya las declara); tabla de hechos: `correos_leidos` pasa a «19 (escribe) · 17 (lee)»; `formulario_leido` y `memo_leido` quitan «17 Pistas ‡» de «Lee» (o se marcan «reservado, sin uso en el slice») | D17-10, Open Question 2 |
| `base-de-contenido-narrativo.md` (18) | Entradas **provisionales** (regla de 18 sobre claves provisionales con marcador de pendiente; `UI_PISTAS_ESPERA` con el texto revisado «Sigue mirando un poco antes de pedir otra.»; no cambian los 28 del §12 ni las 8 `PISTA_*`): `UI_PISTAS_NADA`, `UI_PISTAS_PEDIR`, `UI_PISTAS_REPETIR`, `UI_PISTAS_ESPERA`, `UI_PISTAS_LISTA`, `UI_PISTAS_PENDIENTE`, `UI_PISTAS_YA_VISIBLE`, `UI_PISTAS_P1` a `UI_PISTAS_P6` (propuestas en las reglas 7, 8, 11, 12, 13, 22); dependiente 17: «Dura» ya está; añadir la lectura de palabras (F2) como validación opcional | D17-18 |
| `puzle-2-memorando-en-el-cristal.md` (12) | Quitar `duration_s: 2.0` del `TEXT` de la pista 1 y del knob `hint_text_s`; R24: 17 muestra la nota (F2, ≈ 6 s) y no persiste; fila 17 de Dependencies: deja de ser lector de `memo_leido`; Open Question 6 de 17 | Cambio 5 |
| `puzle-6-decision.md` (16) | Ratificar D16-14 y D16-11 con D17-13 y D17-2; cerrar su Open Question 8 («el 2 sin el 1»: 17 no lo permite); fila 17: «Blanda (existe GDD)»; AC-16-17/AC-16-24 se cumplen con 17 activo | Contrato de 17 |
| `puzle-1-cronologia.md` (11), `puzle-3-encaje-de-la-foto.md` (13), `puzle-4-tablero-de-tareas.md` (14), `puzle-5-espejo-de-la-diferencia.md` (15) | Fila 17: ya existe GDD y es el dueño del reparto y de la nota de texto; 14: Edge Case de N1 `ALWAYS` (D17-7); 11: `discover_if: correos_leidos` y N1 sin compromiso previo; 13: la pista `IDLE` pasa a 17 | Reciprocidad |
| `documentos-y-bolsillo.md` (20) | Dependencies: 17 deja de leer `formulario_leido` (fila «17 Pistas»); R17 sin cambio | D17-10 |
| `guardado-y-carga.md` (5) | AC-41b: «el progreso de pistas vuelve al nivel 1» → «a ningún nivel aplicado (17)»; Dependencies: fila 17 «Ninguna (17 no guarda nada)» | Reciprocidad |
| `ordenador-correo-impresora.md` (19) | Fila 17: «blanda; ahora hay GDD»; `correos_leidos` lo lee 17 | Reciprocidad |
| `caja-y-compartimentos.md` (10) | Fila 17: ahora con GDD; sigue «sin relación» salvo `AUTO_SOLVE_ELEMENT` vía 9 | Reciprocidad |
| `interaccion-e-inspeccion.md` (7) | Catálogo de avisos: 17 consume «vista cercana abierta/cerrada» | Dependencia blanda |
| GDD 25 | Alojar `HintPanel` (entrada «Pistas», foco `ui_*`, navegación con mando); no colocar las pistas en ajustes | **Aplicado:** 25 regla 14 (proveedor de panel de pistas) |
| GDD 23 (futuro) | Decidir qué suena con «pista aplicada»: nada o un `SFX_CLICK_SUBTLE`; nunca voz | Contrato ‡ |
| GDD 30 (futuro) | Valorar la opción «sin espera entre pistas» (Open Question 3) | Accesibilidad |

**Hechos/IDs nuevos que no existen aún:** aviso «puzles configurados» (emisor 9); claves `UI_PISTAS_*` (18); fichero `assets/data/hints_policy.json`.

## Entradas para el registro

Solo lo **nuevo**; lo ya registrado (`hint_key_count`, `idle_s_*`, `highlight_s`, `PISTA_*`, `affordance_catalog`, `request_hint`, `GameClock`) no se repite. Valores con † son propuesta.

| Tipo | Nombre | Valor / descripción | Fuente |
|---|---|---|---|
| constante | `hint_gap_s_L2` | 20,0 s† (rango 0–60) | F1, Tuning Knobs |
| constante | `hint_gap_s_L3` | 40,0 s† (rango 0–120) | F1 |
| constante | `hint_gap_s_P6_L2` | 10,0 s† (rango 0–30) | F1 |
| constante | `hint_reading_wps` | 3,0 palabras/s† (rango 2,0–4,5) | F2 |
| constante | `hint_reading_margin_s` | 1,0 s† (rango 0,5–2,0) | F2 |
| constante | `hint_note_min_s` / `hint_note_max_s` | 3,0 s† / 8,0 s† | F2 |
| constante | `hint_note_fade_s` | 0,3 s† (rango 0,1–0,6) | regla 21 |
| constante | `hint_note_queue_max` | 1† | regla 21 |
| constante | `hint_auto_apply` | verdadero† (aplica las 3 pistas `IDLE` del slice) | regla 15 |
| fórmula | `hint_wait_remaining_s` | `max(0, gap(p,k) − (t − t_ref(p)))`; 0–`gap` | F1 |
| fórmula | `hint_note_duration_s` | `clamp(n_palabras/pps + margen, min, max)`; 3,0–8,0 s; `duration_s` del dato manda | F2 |
| fórmula | `hint_min_time_to_level` | `Σ gap(p, j)`, j = 2..k; 0 / 20 / 60 s (P6: 0 / 10 s) | F3 |
| regla | `hints_not_persisted` | 17 no guarda: ningún hecho, causa de guardado ni dato; vuelve a cero al cargar | regla 34 |
| regla | `hint_ladder_no_skip` | «Pedir» da el menor nivel no aplicado; el jugador no elige nivel | regla 10 |
| regla | `hint_no_counter` | Ningún contador, estadística ni logro de pistas | regla 37 |
| regla | `hint_list_discovered_only` | Solo se listan puzles `ACTIVO` y conocidos (`discover_if`) | regla 5 |
| interfaz | `HintService` | `get_panel_model()`, `request_next(puzzle_id) -> HintResult`, `repeat_last(puzzle_id) -> HintResult`, `on_puzzle_idle(id, level)`, `on_hint_applied(id, level)`, `on_view_opened/closed(view_id)`, `reset()` | Detailed Rules |
| enumerado | `HintResult` | `APPLIED`, `WAIT`, `COMPLETE`, `BUSY`, `NOT_AVAILABLE`, `REJECTED` | regla 11 |
| interfaz | `HintLedger` (por puzle) | `applied`, `t_ref`, `last_applied`, `notes`, `pending_text` (solo memoria) | regla 2 |
| aviso | «puzles configurados» (ya declarado en 3) | Emisor 9, tras cada `configure`; consumidor 17 (`reset()`) | regla 35 |
| fichero | `assets/data/hints_policy.json` | Política de 17 (esquema v1) | Datos de 17 |
| clave de texto | `UI_PISTAS_NADA`, `_SIN_LISTA`, `_PEDIR`, `_REPETIR`, `_ESPERA`, `_LISTA`, `_PENDIENTE`, `_YA_VISIBLE`, `_P1` a `_P6` ‡ | Textos de interfaz **propuestos †, pendientes de 18** | Cambios requeridos (18) |
| hecho | (ninguno nuevo) | 17 lee `correos_leidos` (de 19) y no escribe hechos | regla 5 |

## Historial

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-11-09 | **Ronda de corrección 1** (informe `reviews/sistema-de-pistas-review.md`): B-1 (P2 `FIRST_ACTION`, AC-17-28), B-2 (espera sin relleno, texto veraz, F1/Edge 12/AC-06/07), B-3 (F2 y AC-18 corregidos), B-4 (contrato `TEXT`/`text_key`, AC-17-29), W-1, W-6, W-8, W-9, W-10 cerrados; W-2/W-3 (cortables, pips definidos, OQ 11), W-4/W-5 (cambios condicionados a OQ 2/OQ 5, D17-22) y W-7 (pasada coordinada) quedan para el usuario/coordinación. **Divergencia anotada con el slice:** D.2 asigna `formulario_leido`/`memo_leido` a 17 (sin uso aquí, OQ 2) y B.2 fija 2 s para P2 (cambio 5 no propagado). Decisiones D17-20 a D17-24, OQ 11–12 | Game Designer (ronda de corrección) |
| 2026-11-09 | Borrador inicial (lote autónomo): propiedad del estado, escalera y espera, pistas automáticas, presentación como nota, cuaderno, sin persistencia; 19 decisiones, 10 preguntas abiertas y cambios para 3, 9, 12, 16, 18 y vecinos | Game Designer (lote autónomo) |
| 2026-11-10 | **Ronda de corrección 9** (`gdd-cross-review-2026-11-10.md` R9-B1 y `reviews/cross-review-r10-*.md`): estado vacío del panel sin «Nada pendiente» falso (regla 7, Edge 5 y 13, AC-17-03, D17-25, clave `UI_PISTAS_SIN_LISTA`); «puzles configurados» ya existe en 9 y 3; 17 emite «sonido pedido»; `correos_leidos` anotado y `formulario_leido`/`memo_leido` sin uso unificado con 3; durezas de 25 (Blanda) y 23 (Blanda); retiradas «sin GDD» y «cuando exista»; OQ 2, 3, 10 y 11 marcadas «pendiente de decisión del usuario» con su opción por defecto. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. | Game Designer (ronda de corrección) |
| 2026-11-10 | **Ronda de corrección 10** (R15-1/4): ‡ cerradas («puzles configurados», entrada «Pistas» en 25); `memo_leido` sin lectura de 17 dicho una vez; D17-26. Estado: Revisado (ronda de corrección 10) — pendiente de re-review. |
