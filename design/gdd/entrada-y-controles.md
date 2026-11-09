# Entrada y controles

> **Status**: Revisado (ronda de corrección 2) — pendiente de re-review
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión · Tensión sin castigo (accesibilidad y control sin fricción)

## Summary

Traduce teclado, ratón y mando en acciones del juego (moverse, mirar, interactuar con un solo botón, leer, volver, pausar y los gestos de los puzles) y decide qué acciones valen en cada momento. Permite jugar el slice completo con cualquiera de los dos dispositivos, con un cursor virtual para los puzles en el mando, y se puede reasignar y ajustar por completo por accesibilidad. Existe porque el slice mezcla tres modos de manejo muy distintos y exige accesibilidad desde el principio.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: ninguna dura (blandas: 3 Estado y bus, para emitir y recibir avisos; 4 Escena de planta, emisor de los avisos de carga y de `D_carga`)

## Overview

Entrada y controles traduce lo que el jugador hace con el teclado y el ratón, o con el mando, en un vocabulario único de **acciones del juego** (moverse, mirar, interactuar, leer, volver, pausar, y los gestos de puntero de los puzles) y decide, en cada momento, qué acciones están activas. El resto de sistemas pide acciones («¿quiere interactuar?»), nunca teclas ni botones.

El juego se maneja con un solo botón contextual en exploración (slice §5) y se puede jugar completo con cualquiera de los dos dispositivos, alternando entre ellos sin menús: el sistema detecta cuál se está usando y avisa para que los iconos del juego cambien. En los puzles, donde el slice describe gestos de puntero (clic, arrastrar, rotar), el teclado y ratón usan el cursor real y el mando usa un **cursor virtual** movido con el stick, de modo que ningún puzle exige ratón. Todas las acciones se pueden reasignar (accesibilidad, slice §5) y los valores de sensibilidad, zona muerta y velocidad son ajustables.

Existe porque el slice combina tres modos de manejo muy distintos (caminar en primera persona, inspeccionar objetos en la mano y puzles de puntero en vista cercana) y porque exige accesibilidad desde el principio. Resolverlo en un único punto evita que cada puzle reinvente su control, y garantiza el pilar *Tensión sin castigo* en lo físico: ningún gesto requiere precisión temporal, combinaciones de botones simultáneos ni habilidad motriz fina que no se pueda compensar con ajustes.

## Detailed Design

### Core Rules

**Acciones y dispositivos**

1. **Vocabulario de acciones.** El resto del juego solo conoce acciones lógicas, nunca teclas ni botones. Hay dos tipos (ver tabla de asignaciones por defecto):
   - **Acciones físicas** (las únicas que tienen entrada propia y se reasignan, regla 15):
     - *Exploración:* `mover`, `mirar`, `interactuar`, `pausa` y `atrás` (pulsación corta; decisión del usuario, 2026-11-09, D27). En `exploración` `atrás` no cierra nada: de ella deriva la acción `repasar_bolsillo` (regla 23).
     - *Inspección y lectura:* `atrás`; en `inspección` `mirar` gira el objeto (`rotar_objeto`, regla 11).
     - *Vista cercana de puzle, ordenador y llamada:* `mover_cursor`, `seleccionar`, `atrás`.
     - *Menús y opciones de la llamada:* `ui_arriba`, `ui_abajo`, `ui_izquierda`, `ui_derecha`, `ui_aceptar`, `ui_atrás`.
   - **Gestos derivados** (los calcula este sistema a partir de una acción física; no tienen entrada propia ni se reasignan): `repasar_bolsillo` (de `atrás` en `exploración`, regla 23), `leer` (`interactuar` mantenida hasta `t_hold`, regla 10; no es una acción aparte), y a partir de `seleccionar`: `agarrar` (mantener y mover el cursor), `rotar` (mantener y mover en horizontal: gesto `ROTAR` del Anexo B) y `mantener` (mantener más allá del umbral: gesto `PULSAR` largo del puzle 3). Cuál de ellos se emite lo decide la regla 13 y F6.

   (`leer` se retira de `inspección`: 7 no le da uso, D7-28.) No existen `correr`, `agacharse` ni `saltar` (slice §5 y A.0).
2. **Dos dispositivos a la vez.** Teclado y ratón, y mando, están siempre activos: una acción llega al juego venga de donde venga. No hay modo «elige tu dispositivo».
3. **Dispositivo activo = el último usado.** Cuenta como uso la pulsación de cualquier tecla, botón o clic, el movimiento del ratón por encima de un mínimo y un stick fuera de su zona muerta. El dispositivo activo solo determina qué iconos muestra el juego; al cambiar se emite el aviso «dispositivo de entrada cambiado» (teclado/ratón o mando). Una pequeña histéresis (ver Formulas) evita parpadeos por temblor del ratón o deriva del stick.
4. **Un gesto, un botón.** Ninguna acción exige pulsar dos botones a la vez, doble pulsación ni reaccionar dentro de una ventana de tiempo (solo se exige mantener un botón hasta un umbral). El único gesto compuesto es mantener un botón mientras se mueve el cursor o un stick (`agarrar`, `rotar`), y los únicos gestos con tiempo son la pulsación prolongada (`leer`, `mantener`) y el arrastre; todos tienen la alternativa de la regla 14.

**Contextos de entrada**

5. **Un contexto activo.** Hay una pila de contextos y solo el de arriba recibe acciones: `exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`, `llamada`, `menú` y `sin control`. Las acciones de un contexto no existen en los demás (por ejemplo, `mover` solo en `exploración`).
6. **Quién abre y cierra contextos.** Este sistema posee la pila y expone «entrar en» y «salir de» un contexto. Los piden: Interacción (7) para `inspección`, `lectura`, `vista cercana` y `ordenador` (7 **no** pide `sin control`); el menú de pausa (25) para `menú`; la llamada (22) para `llamada`; y para `sin control`, **declarando una duración máxima** (F8), el director de escenas (21) en las escenas dirigidas y Escena de planta (4) en las cargas de escena (`D_carga`). Salir restaura el contexto anterior tal como estaba (posición del cursor incluida). **Aviso de cambio:** tras cada entrada o salida efectiva de la pila se emite «contexto de entrada cambiado» con dos datos (contexto anterior, contexto nuevo); una petición ignorada o rechazada (ver Edge Cases) no emite nada.

   **`sin control`: dueño, duración y operaciones (ronda 3, C-B4).** Todo `sin control` tiene un **dueño** (quien lo abrió) y una **duración declarada** (F8). Las operaciones son:
   - *Abrir* (dueño, duración): apila `sin control`. Si ya hay un `sin control` arriba, no se ignora ni se apila otro: se rechaza y se registra (hay que pedir el traspaso). Sin duración declarada se aplica el tope de 3 s y se registra la omisión.
   - *Cerrar*: solo lo cierra su dueño; la petición de otro se rechaza y se registra. Restaura el contexto anterior. Si la pila quedara vacía, queda `exploración` (hay partida en curso).
   - *Traspasar* (nuevo dueño, nueva duración): si el contexto superior es `sin control`, cambia su dueño y su duración **sin salir ni entrar** (la pila no cambia y no se emite «contexto de entrada cambiado») y **renueva el tope**: el nuevo tope es la nueva duración más el margen, contado desde el traspaso (F8). Lo pide el sistema que releva al dueño: el 21 releva al 4 en el fotograma de «carga de escena terminada» cuando `control_final` es `ninguno`, de modo que no hay ni un fotograma en que el control se libere. Si el contexto superior no es `sin control`, se rechaza y se registra.
   - *Pedir `exploración` el dueño del `sin control` superior* (ronda 4, N-B1): lo puede pedir **el dueño vigente** del `sin control` superior: el 4 con `control_final` = `exploracion` (Continuar), o el 21 tras un traspaso (Nueva partida, escena 1 dirigida). Cierra ese `sin control` y deja `exploración` como única base de la pila; si la pila venía del título (carga desde el título), **descarta cualquier `menú` que hubiera debajo**. Emite un solo aviso (`sin control`, `exploración`). Lo pide otro sistema que no sea el dueño: se rechaza y se registra.
   - *Cierre normal del `sin control` del 21 sobre [`menú`, `sin control`]* (ronda 4, N-B1): restaura lo que haya debajo, como cualquier «cerrar» (regla 6). El caso [`menú`, `sin control`(21)] solo se da si el 21 cierra su `sin control` **sin haber pedido `exploración`** en una carga que venía del título (error de uso del 21); entonces restaura `menú`, que es el comportamiento seguro (se registra). **No es la vuelta al título desde Recepción** (ronda 5, E-1): en Recepción la pila es [`sin control`(21)] sin `menú` debajo (tabla de la regla 6, y GDD 4 regla 15), y el título lo repone el 4 al terminar la descarga total con *Reponer `menú`* (aviso «descarga total completada»). **Para entrar en juego el 21 no cierra: pide `exploración`.** Si cerrara con «cerrar» en una carga desde el título, el jugador volvería al título en mitad de la partida (defecto; se registra).
   - *Reponer `menú`* (lo pide 4 ante un fallo de carga o una descarga total): cierra el `sin control` si lo hay y deja la pila en [`menú`]; emite un aviso (anterior, `menú`) si el contexto superior cambia.
   - *Descartar la pila al aceptar una carga nueva* (**decisión firme, ronda de corrección 2, E4-1; antes «propuesta», D22**): cuando una carga `partida_nueva` o `continuar` se acepta (el 4 pide *abrir* su `sin control` en «carga de escena iniciada» por una de esas dos causas) y la pila contiene un `sin control` de **otro dueño** —en cualquier posición y con o sin `menú` encima o debajo: [`menú`, `sin control`(21), `menú`], [`sin control`(21), `menú`], [`menú`, `sin control`(21)] o [`sin control`(21)]—, *abrir* no se rechaza: Entrada **descarta la pila entera** (el `sin control` ajeno, todo `menú` —el de la pausa y el del título— y cualquier otro contexto) y deja [`sin control`(4)] con el dueño y la duración del 4; su tope es `D_carga` + margen contado desde esa apertura (F8). El `sin control` ajeno **no puede caducar durante la carga porque ya no existe**. Se emite un solo aviso «contexto de entrada cambiado» (anterior = contexto que estaba arriba, nuevo = `sin control`) y, además, el aviso **«`sin control` absorbido»** (dato: dueño descartado, p. ej. 21), único nombre de esta señal, que escucha el dueño descartado (el 21 cancela su escena, regla 11b de 21). Desde ahí sigue la fila «Planta, `ninguno`» de la tabla (descarga conservando el `sin control`(4), traspaso al 21, `exploración`) o, con `continuar`, la petición de `exploración` del 4. Si la carga **falla**, el 4 repone `menú` ([`menú`]) como en cualquier fallo (el `sin control` del 21 no se restaura: su escena ya está cancelada). Sin `sin control` ajeno en la pila (p. ej. [`menú`] del título o [`exploración`] de la planta) no hay nada que absorber: *abrir* actúa como siempre (el `menú` del título queda debajo, porque *Reponer `menú`* lo necesita si la carga falla). **Cualquier otro intento de *abrir* con un `sin control` ajeno bajo la cima y sin carga aceptada sigue rechazándose y registrándose** (AC-E13). El 21 no emite ninguna operación de pila (regla 11b de 21).
   - *Reinicio de pila al descargar una escena*: la pila pasa a [`sin control`] **conservando el dueño, la duración declarada y la cuenta del tope del `sin control` vigente** (el que 4 abrió en «carga de escena iniciada»); no lo sustituye, no lo acorta ni reinicia su cuenta. Si el superior ya era `sin control`, no se emite aviso; si no, se emite uno solo con `sin control` como contexto nuevo. Si no había ningún `sin control` vigente (descarga fuera de una carga: defecto), se abre uno con dueño «Entrada» y el tope de 3 s, y se registra.

   **Modelo de pila en la primera carga desde el título.** Pila [`menú`]; en «iniciada» el 4 abre su `sin control` **por encima** ([`menú`, `sin control`]); no hay escena que descargar. Si la carga termina bien, con `control_final` = `exploracion` el 4 pide `exploración` y la pila queda [`exploración`]; con `ninguno` el 21 traspasa (pila sin cambio) y luego pide `exploración` (pila [`exploración`]); si falla, el 4 repone `menú` ([`menú`]). Desde la planta: [`exploración`, `sin control`] → (descarga) [`sin control`] → traspaso al 21 o `exploración`.

   | Origen de la carga | Antes | En «iniciada» | Tras traspaso al 21 | Final |
   |---|---|---|---|---|
   | Título, `exploracion` (Continuar) | [`menú`] | [`menú`, `sin control`(4)] | — | [`exploración`] (el 4 la pide) |
   | Título, `ninguno` (Nueva partida) | [`menú`] | [`menú`, `sin control`(4)] | [`menú`, `sin control`(21)] | [`exploración`] (el 21 la pide; descarta `menú`) |
   | Planta, `ninguno` (Nueva partida desde la pausa) | [`exploración`] | [`exploración`, `sin control`(4)] → tras la descarga [`sin control`(4)] | [`sin control`(21)] | [`exploración`] (el 21 la pide) |
   | Título (sin `sin control` ajeno), `ninguno` o `exploracion` | [`menú`] | [`menú`, `sin control`(4)] (nada que absorber) | (como las filas «Título») | (como las filas «Título») |
   | Escena 1 dirigida del 21 venida del título, pausa → «Nueva partida» o «Continuar» | [`menú`(título), `sin control`(21), `menú`(pausa)] | [`sin control`(4)] (se descarta la pila entera; avisos «contexto de entrada cambiado» (`menú`, `sin control`) y «`sin control` absorbido» (21)) | `ninguno`: [`sin control`(21)] · `exploracion`: — | `ninguno`: [`exploración`] (el 21 la pide) · `exploracion`: [`exploración`] (el 4 la pide) |
   | Escena 1 con el `menú` del título ya descartado, o escena 8 (`ESC8_ASCENSOR`, `ESC8_CIERRE`), pausa → «Nueva partida» o «Continuar» | [`sin control`(21), `menú`] (o [`menú`, `sin control`(21)], o [`sin control`(21)]) | [`sin control`(4)] (misma operación y mismos avisos) | `ninguno`: [`sin control`(21)] · `exploracion`: — | `ninguno`: [`exploración`] (el 21 la pide) · `exploracion`: [`exploración`] (el 4 la pide) |
7. **Pausa.** `pausa` abre el menú sobre cualquier contexto salvo durante una carga de escena (entre el aviso «carga de escena iniciada» y «carga de escena terminada» o «carga de escena fallida», que emite Escena de planta, 4, y que este sistema escucha por el bus; mientras dura se mantiene un estado interno `carga_en_curso`; sin esos avisos la pausa no se bloquea nunca), detiene el tiempo de juego y, al cerrarlo, restablece el contexto inferior. Con el menú abierto, `atrás` y `pausa` lo cierran; si ambas comparten tecla (`Esc`), una sola pulsación produce un solo cierre, porque el menú consume el evento. Al abrir el menú el ratón se libera; al cerrarlo se recaptura si el contexto restaurado lo requiere. Esa pulsación de `atrás` la consume el menú: no produce `repasar_bolsillo` (regla 23). El menú de título es la base de la pila: `pausa`, `atrás` y `ui_atrás` no lo cierran; solo se sale de él al empezar o reanudar la partida.
8. **Transiciones.** Mientras una transición de cámara o de animación bloquea el contexto (p. ej. la cámara acercándose al marco del puzle 3, o la animación de descolgar), solo se acepta `pausa`; el resto de acciones se descarta y **no se guarda para después** (única excepción: `repasar_bolsillo`, regla 23, que se entrega a 20 sin guardarla en Entrada; 7 decide si la acepta, la aplaza o la rechaza). **El bloqueo lo declara y mantiene Interacción (7) como transición bloqueante (sin `sin control`) desde `interactuar()` y termina con el aviso de fin que corresponda: «cámara cedida» (entrada a una vista cercana u ordenador, regla 19 de 7), «cámara devuelta» (salida) o «gesto terminado» (animación sin cesión de cámara), o con el tope de seguridad de 3 s (F8).** Las escenas dirigidas y las cargas (`sin control`) declaran su propia duración máxima (F8).

**Exploración, inspección y lectura**

9. **Mirar.** `mirar` entrega un cambio de orientación por fotograma, calculado con la sensibilidad del dispositivo (ver Formulas). La orientación y sus límites son del sistema de jugador (2); este sistema no limita ángulos.
10. **Interactuar.** `interactuar` es el único botón del mundo. Este sistema solo entrega los eventos del botón: `interactuar` pulsada (al pulsar), toque corto (soltada antes de `t_hold`) y el gesto `leer` (mantenida hasta `t_hold`, F6). **Qué hace cada objeto lo decide el catálogo de Interacción (7)** (`verbo_corto`, `verbo_largo`), no Entrada; 7 informa a Entrada, para el objeto apuntado, de si tiene `verbo_largo`. Para que activar no tenga retraso: si el objeto **no** tiene `verbo_largo`, el verbo corto se dispara **al pulsar**; si lo tiene, la decisión se toma **al soltar** (toque corto) o al cumplirse `t_hold` (`leer`), y mientras se mantiene se muestra un indicador de progreso. Con **solo** `verbo_largo` (todos los documentos del slice) un toque corto no activa nada: 7 pulsa el anillo y suena `SFX_CLICK_SUBTLE`.
11. **Inspección.** Con un objeto en la mano, `mirar` pasa a girar el objeto en lugar de la cámara (`rotar_objeto`); `atrás` lo suelta.

**Puzles y vista cercana**

12. **Cursor.** En `vista cercana`, `ordenador` y `llamada` hay un cursor en pantalla. Con ratón es el cursor real, libre dentro de la ventana. Con mando es un **cursor virtual** movido con cualquiera de los dos sticks en `vista cercana` y `ordenador`, y solo con el derecho en `llamada` y `menú` (donde el izquierdo y la cruceta mueven el foco, `ui_*`); lleva velocidad y atracción asistida hacia el elemento interactivo más cercano (ver Formulas), y la atracción se puede desactivar. En `exploración` e `inspección` el cursor no existe y el ratón queda capturado.
13. **Gestos de puntero.** `seleccionar` es la única acción física; `agarrar`, `rotar` y `mantener` son gestos derivados de una misma pulsación (regla 1) y se calculan igual con ambos dispositivos:
    - `seleccionar` = clic o `A`/`✕` (equivale a `CLICK` y a `PULSAR` corto del Anexo B). Se entrega **al soltar**, si la pulsación no se convirtió en ninguno de los gestos de abajo (el aviso de «pulsado» para el resaltado del elemento se entrega al pulsar).
    - `agarrar` = mantener `seleccionar` y mover el cursor más allá del umbral de inicio de arrastre (F6); equivale a `ARRASTRAR` del Anexo B.
    - `rotar` = mantener `seleccionar` sobre un control giratorio y mover en horizontal; con ratón, 1 píxel = 0,25° (slice, Anexo B); con mando, velocidad angular proporcional al **eje horizontal del stick con mayor magnitud** (F4; el otro stick se ignora mientras se rota). Mientras se rota, el cursor queda quieto.
    - `mantener` = mantener `seleccionar` el tiempo del umbral (`PULSAR` largo del puzle 3).
    - **Qué gestos puede iniciar cada pulsación** lo fija el elemento bajo el cursor al pulsar: 7 entrega, junto a su posición y tolerancia en px (F5b), la lista `gestos_aceptados` ⊆ {`agarrar`, `rotar`, `mantener`}. Un gesto que el elemento no acepta no se emite ni cuenta como señal.
    - **Precedencia (F6): decide la primera señal que se cumpla** (desplazamiento ≥ `d_arrastre` o `t_hold` cumplido) y la otra queda descartada hasta soltar. Si gana el desplazamiento, se emite `rotar` (si el elemento acepta `rotar`) o `agarrar`; si gana el tiempo y el elemento acepta `mantener`, se emite `mantener` y mover después no produce `agarrar` ni `rotar`. Un `agarrar` ya iniciado no pasa a `mantener` aunque el cursor se detenga.
    - «Pasar el cursor» (resaltado de la ficha, puzle 4) = cursor sobre el elemento; con mando, la atracción asistida o el cursor virtual producen el mismo resaltado.
    Cómo reacciona cada puzle lo define su GDD; este sistema solo entrega la secuencia.

**Accesibilidad y personalización**

14. **Alternar en lugar de mantener.** Existe un ajuste para que los gestos de mantener (`leer`, `mantener`, `agarrar` y `rotar`) se activen con una pulsación y se terminen con otra. Por defecto está desactivado. Con él activo, el gesto en curso también se cancela con `atrás` o al cambiar de contexto. `rotar` (el gesto del puzle 5) empieza con la pulsación sobre un control que lo acepta y termina con la siguiente; entre ambas el ratón o el stick controlan el giro y el cursor queda quieto. *(Propuesta, a validar en playtest:)* `leer` y `mantener` se completan solo si la segunda pulsación llega después de `t_hold` (F6) desde la primera; si llega antes, se cancelan sin efecto; `agarrar` y `rotar` se terminan con la segunda pulsación. Si un elemento acepta varios gestos, rige la primera señal de F6 y la segunda pulsación termina el gesto elegido. Quien no puede mantener un botón puede así jugar todos los puzles.
15. **Reasignación.** Se reasignan las **acciones físicas** de exploración, inspección, lectura y vista cercana (`mover`, `mirar`, `interactuar`, `pausa`, `atrás`, `seleccionar`), por separado para teclado/ratón y para mando, con hasta dos asignaciones por acción y dispositivo. Los gestos derivados (`leer`, `agarrar`, `rotar`, `mantener`) **no se reasignan**: siguen a la asignación vigente de `interactuar` o `seleccionar`. Los ejes `mover` y `mirar` se reasignan como conjunto (cada conjunto cuenta como una acción con sus dos asignaciones). No se pueden reasignar `mover_cursor` (movimientos del ratón y sticks), los movimientos del ratón ni las acciones `ui_*` (navegación fija con flechas/`Enter` y cruceta/`A`), pero sí los botones del ratón.
16. **Conflictos.** Dos acciones físicas del mismo contexto no pueden compartir entrada: el intento muestra el conflicto y ofrece intercambiar o cancelar. Acciones de contextos distintos sí pueden compartirla (p. ej. `interactuar` y `seleccionar`). **Excepción de diseño:** `pausa` y `ui_atrás` comparten `Esc` en `menú` (regla 7: el menú consume el evento y se produce un solo cierre); el validador la tiene en una lista de pares permitidos. Como `pausa` está activa en todos los contextos, no puede asignarse a una entrada que use una acción `ui_*` fija (flechas, `Enter`, cruceta, botón sur): ahí el intercambio es imposible y el intento se rechaza con el mismo mensaje de conflicto. Los gestos derivados comparten por construcción la entrada de su acción (no cuentan como conflicto).
17. **Mínimos garantizados.** `interactuar`, `atrás` y `pausa` conservan siempre al menos una asignación por dispositivo; quitar la última se rechaza. Además, `atrás` en teclado/ratón conserva siempre al menos una asignación que no sea una tecla imprimible (regla 20). «Restablecer» existe por acción y para todo el dispositivo.
18. **Ajustes de manejo.** Son propiedad de este sistema y los guarda Ajustes (6): sensibilidad de mirada (ratón y stick por separado), invertir eje vertical (por dispositivo), zonas muertas de sticks, velocidad del cursor virtual, atracción asistida activada/desactivada y alternar-en-lugar-de-mantener.
19. **Datos, no código.** Las asignaciones por defecto y los valores de ajuste iniciales viven en un fichero de datos (`assets/data/input/default_bindings.json`). Las asignaciones personalizadas se entregan a Ajustes como un bloque que este sistema sabe exportar e importar; Ajustes lo guarda y lo reaplica al arrancar.
20. **Texto.** En el ordenador (contexto `ordenador`), mientras un campo de texto tiene el foco (el único del slice es la búsqueda «transición»), el teclado físico entrega caracteres y el campo **consume antes que cualquier acción** las teclas imprimibles, `Retroceso`, `Supr`, las flechas y `Enter`. Quedan fuera del campo `pausa` (`Esc` sigue siendo `pausa`: abre el menú, no cancela el texto), el clic derecho y el botón este, que siguen siendo `atrás` y sacan del ordenador. `Retroceso` **no** es una asignación por defecto de `atrás` (decisión registrada abajo). Si el jugador reasigna `atrás` o `interactuar` a una tecla imprimible, esa tecla escribe mientras el campo tiene el foco (la pantalla de reasignación avisa del caso) y la otra asignación sigue valiendo, por eso regla 17. El mando no puede escribir: necesita un teclado en pantalla controlado con foco, a definir en el GDD del ordenador (19) y de interfaz.

**Pérdida de foco y de mando**

21. **Ventana sin foco.** Si la ventana pierde el foco, se abre el menú de pausa automáticamente, también durante una transición bloqueante (regla 8); si ocurre durante una carga de escena (donde la regla 7 impide abrirla), se abre al terminar la carga.
22. **Mando desconectado.** Si el mando era el dispositivo activo y se desconecta, se abre el menú de pausa con el mensaje «Mando desconectado» **en el acto, igual que la pérdida de foco** (también durante una transición bloqueante; si hay una carga de escena, al terminar la carga); al reconectar se ofrece continuar (la pantalla de ese mensaje es del sistema 25). Teclado y ratón siguen valiendo para reanudar.

**Repaso del bolsillo (decisión del usuario, 2026-11-09, D27)**

23. **`repasar_bolsillo`.** Con la pila en `exploración` (único contexto en que existe), una pulsación de `atrás` emite la acción derivada `repasar_bolsillo` hacia 20 (`repasar_bolsillo()`, 20 R18–R22): abre un documento por pulsación, sin menú ni pantalla de inventario (slice D.1). Reglas de entrega:
    - **Pulsación corta.** Se emite en el flanco de pulsación, sin umbral `t_hold`: `atrás` no tiene gesto largo que desambiguar en `exploración`. Mantener el botón no repite y soltarlo no emite nada (se ignoran los eventos de auto-repetición del teclado). Un documento por pulsación.
    - **Solo si la pulsación empieza en `exploración`.** El contexto se evalúa al pulsar. El `atrás` que **cierra** un modo (`lectura`, `inspección`, `vista cercana`, `ordenador`) o el menú (regla 7) lo consume ese contexto; aunque el cierre deje `exploración` arriba antes de soltar, esa misma pulsación **no** lanza `repasar_bolsillo`, ni al pulsar ni al soltar (20, AC-14). Para releer otro documento hace falta pulsar de nuevo.
    - **Con el ajuste «alternar en lugar de mantener» (regla 14)**, el `atrás` que cancela un gesto en curso (`leer`) se consume en la cancelación y no lanza el repaso.
    - **Transiciones.** Es la excepción de la regla 8: `repasar_bolsillo` se entrega aunque haya una transición bloqueante o un gesto de 7 (sin `sin control`), porque 7 decide `ACEPTADA`, `APLAZADA` o `RECHAZADA` (7, regla 27b); Entrada no la guarda ni la reintenta. En `sin control`, `menú`, `llamada` y el resto de contextos no existe.
    - **Asignación.** Es la de `atrás` (regla 15, reasignable; regla 17: siempre queda una asignación); `repasar_bolsillo` no se reasigna aparte. El pie de ayuda lo pide 20 (R23 de 20, `UI_BOLSILLO_AYUDA`), no Entrada.

**Asignaciones por defecto**

| Acción | Teclado y ratón | Mando |
|---|---|---|
| `mover` | `W` `A` `S` `D` | Stick izquierdo |
| `mirar` | Movimiento del ratón | Stick derecho |
| `interactuar` (de él deriva `leer`, al mantener) | `E` · clic izquierdo | Botón sur (`A` / `✕`) |
| `atrás` (en `exploración` deriva `repasar_bolsillo`, regla 23) | Clic derecho | Botón este (`B` / `○`) |
| `pausa` | `Esc` | `Start` / `Options` |
| `mover_cursor` | Ratón | Ambos sticks (solo el derecho en `llamada` y `menú`) |
| `seleccionar` (de él derivan `agarrar`, `rotar`, `mantener`; no reasignables por separado) | Clic izquierdo (pulsar / mantener) | Botón sur (pulsar / mantener) |
| `ui_arriba/abajo/izquierda/derecha` | Flechas | Cruceta · stick izquierdo |
| `ui_aceptar` · `ui_atrás` | `Enter` · `Esc` | Botón sur · botón este |

### States and Transitions

La pila empieza vacía en el arranque, con `menú` (título) como primer contexto, y pasa a `exploración` al comenzar partida o reanudarla (la carga la cubre un `sin control` del 4 por encima de `menú`; regla 6).

| Contexto | Acciones activas | Cursor y ratón | Se entra desde | Se sale con |
|---|---|---|---|---|
| `exploración` | `mover`, `mirar`, `interactuar`, `pausa`, `atrás` (→ `repasar_bolsillo`, regla 23) | Sin cursor; ratón capturado | Inicio de partida; al salir de cualquier otro | — (contexto base) |
| `inspección` | `rotar_objeto` (eje de mirar), `atrás`, `pausa` | Sin cursor; ratón capturado | Interacción (7), al coger un objeto | `atrás` |
| `lectura` | `atrás`, `interactuar` (pasar página), `pausa` | Sin cursor | Interacción (7), al leer | `atrás` |
| `vista cercana` | `mover_cursor`, `seleccionar` (y sus gestos derivados `agarrar`, `rotar`, `mantener`), `atrás`, `pausa` | Cursor visible (virtual con mando) | Interacción (7), al abrir un puzle o panel | `atrás` o resolverse el puzle |
| `ordenador` | `mover_cursor`, `seleccionar`, texto (con el campo enfocado, regla 20), `atrás`, `pausa` | Cursor visible | Interacción (7), al acercarse la cámara al ordenador (V01 solo acerca la cámara; el jugador no se sienta) | `atrás` |
| `llamada` | `ui_*` o cursor, `seleccionar` (sobre las opciones), `pausa` | Cursor visible | Llamada (22), tras descolgar | La llamada (22) la cierra |
| `menú` | `ui_*`, cursor, `ui_aceptar`, `ui_atrás` | Cursor visible | `pausa`, título, pérdida de foco o mando | `ui_atrás` · `pausa` |
| `sin control` | solo `pausa` (ninguna durante una carga de escena, regla 7) | Sin cursor | Director de escenas (21), Escena de planta (4) en las cargas | Su dueño (quien lo abrió o a quien se traspasó, regla 6) o el tope de F8 |

**Dispositivo activo:** teclado/ratón ↔ mando según la regla 3; el valor inicial es teclado/ratón hasta la primera entrada.

### Interactions with Other Systems

| Sistema | Qué recibe de Entrada y controles | Qué entrega a Entrada y controles |
|---|---|---|
| 2 Jugador | `mover` (vector 2D) y `mirar` (cambio de orientación) en `exploración` | Nada |
| 7 Interacción | `interactuar` (pulsada, toque corto), gesto `leer`, `rotar_objeto`, `atrás`, gestos de puntero | Por elemento de la vista: posición y tolerancia en px (F5b) y `gestos_aceptados` (regla 13); si el objeto apuntado tiene `verbo_largo` (regla 10); peticiones de entrar y salir de `inspección`, `lectura`, `vista cercana` y `ordenador`; transición bloqueante con sus avisos de fin (regla 8) |
| 4 Escena de planta | Contexto `sin control` durante las cargas (aguas abajo); reposición de `menú` | Avisos «carga de escena iniciada» (destino, `motivo`, `D_carga`) / «terminada» / «fallida» (bloquean y desbloquean `pausa`, regla 7); apertura de `sin control` con `D_carga` como duración declarada (F8); petición de `exploración` al terminar; petición de reponer `menú` ante un fallo o una descarga total |
| 20 Documentos y bolsillo | La acción derivada `repasar_bolsillo` (de `atrás` en `exploración`, regla 23) | Nada (la llamada a `abrir_lectura` a 7 es de 20) |
| 24 Prompt de interacción | Dispositivo activo (para elegir el icono) y la asignación actual de la acción | — |
| 25 Menú de pausa | `pausa`, `ui_*`, `atrás`; avisos de foco y mando | Peticiones de entrar y salir de `menú`; pantalla de reasignación (usa la API de reasignación) |
| 30 Accesibilidad | API de reasignación, ajustes de manejo, alternar-en-lugar-de-mantener | Valores elegidos por el jugador |
| 6 Ajustes | Bloque de asignaciones y ajustes de manejo para guardar | Bloque guardado, al arrancar; aviso «ajustes aplicados», con el que Entrada aplica el bloque |
| 19 Ordenador, 22 Llamada, 27 Título | `ui_*`, cursor, texto | Peticiones de contexto (22 para `llamada`) |
| 21 Director de escenas | — | Peticiones de `sin control` con su duración máxima y, al relevar al 4 tras una carga con `control_final` = `ninguno`, la operación «traspasar `sin control`» (regla 6) |
| 3 Estado y avisos | Los avisos «dispositivo de entrada cambiado» y «contexto de entrada cambiado» (se documentan aquí según la regla 10 de ese GDD) | Entrega los avisos de carga de 4 por el bus |

## Formulas

Propuestas por `systems-designer`. † = valor propuesto, **a validar en playtest**; las constantes que vienen del slice no llevan †. Todos los valores se leen de `assets/data/input/default_bindings.json`; los ajustables por el jugador van marcados «(ajuste)». **Unidades:** los píxeles del cursor (F5a, F5b, F6) son del viewport lógico de 1920 × 1080 (modo de estiramiento del proyecto, a confirmar en el ADR de resolución), no de la ventana física; los de la mirada con ratón (F2) y el gesto `rotar` con ratón (F4) son píxeles físicos relativos del dispositivo. El nombre de `t_hold` en el registro de entidades es `long_press_threshold`.

### F1 · Zona muerta radial reescalada (usada por F2, F4 y F5a)

The zona muerta radial formula is defined as:

`r = clamp((|v| − dz_in) / (1 − dz_out − dz_in), 0, 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| v | Vector2 | \|v\| ≤ 1 | engine (crudo) | Ejes del stick sin zona muerta del motor |
| dz_in | float | 0,05–0,5 | data file, 0,15† (ajuste) | Zona muerta interior (mínimo 0,05: con 0 la deriva del stick contaría como uso en F7) |
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
| r_x | float | 0–1 | calculated | F1 con \|v\| sustituido por \|v_x\| (eje horizontal) del stick de mayor magnitud; el otro stick se ignora mientras se rota |
| f_marca | float | 0,3–1 | data file, 0,5† | Freno cuando el ángulo está a ≤ 1° de una marca de 5° |
| delta | float (s) | > 0 | engine | Tiempo del fotograma |

**Output Range:** ratón, 0,25 °/px sin multiplicador; mando, ±60 °/s. Soltar el stick detiene la rotación al instante y el ángulo se conserva durante el mantenimiento de 0,8 s del puzle 5.
**Example (puzle 5, de 0° a 40°, tolerancia ±3°):** con r = 0,71 (30 °/s) se llega a 30° en 1,0 s; con r = 0,35 (7,4 °/s), a 38° en 1,1 s; con r = 0,2 y freno (1,2 °/s), a 40° en 1,7 s. Total ~4 s (~2 s si va directo); el freno en las marcas de 5° (f_marca) añade unos 0,4 s a la fase rápida, así que ~4,4 s en la práctica. Con ratón, los píxeles recorridos entre la pulsación y el inicio del gesto (hasta `d_arrastre`) no se pierden: se aplican en el fotograma en que `rotar` empieza. Con 0,25 s de reacción, el error es de 1,8° a 7,4 °/s y de 0,3° a 1,2 °/s, dentro de ±3°. Con ratón, 40° = 160 px y ±3° = ±12 px. El modo fino (accesibilidad) baja a 25 °/s. El modo asistido (±6°) no requiere nada más.

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

**Output Range:** 0 a `v_max · s_c`: 900 px/s con los valores por defecto, 1.350 px/s con s_c = 1,5 y **2.400 px/s en el peor caso de los rangos** (v_max = 1600, s_c = 1,5). La posición se limita a la ventana (cruzar la pantalla de 1920 px a 900 px/s: ~2,1 s; a 2.400 px/s: 0,8 s).
**Example:** r = 0,613 → 338 px/s. Con r = 0,2 → 36 px/s, suficiente para elementos pequeños.

### F5b · Atracción asistida (magnetismo)

The atracción asistida formula is defined as:

`w = clamp(1 − d/R, 0, 1) × g;   g = clamp((v_off − v_c)/(v_off − v_on), 0, 1);   Δp = limitar_módulo( (t − p) × (1 − e^(−λ·delta)) × w ,  0,5 · v_c · delta )`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| d | float (px) | ≥ 0 | calculated | Distancia al centro del elemento interactivo más cercano |
| R | float (px) | 32–128 | data file, 64† | Radio de captación base; **por elemento: R = min(max(R base, tolerancia del elemento en px), R_max_elem)**, con R_max_elem = 128† (el tope de R). Una tolerancia mayor (p. ej. 220 px asistida) no amplía la captación: encajar con esa tolerancia es cosa del puzle, no de la atracción |
| λ | float (1/s) | 2–10 | data file, 5† | Intensidad |
| v_on, v_off | float (px/s) | — | data file, 300†, 450† | Tramo en que la atracción se apaga al moverse rápido |
| t, p | Vector2 (px) | — | calculated | Centro del elemento y posición del cursor |
| delta | float (s) | > 0 | engine | Tiempo del fotograma, limitado a 0,1 s (igual que F3) |
| v_c | float (px/s) | ≥ 0 | calculated | Velocidad del cursor de F5a |

**Output Range:** la tracción nunca supera la mitad de la velocidad del cursor (`0,5 · v_c · delta` por fotograma), de modo que **cualquier movimiento deliberado del stick vence siempre a la atracción**, sea cual sea s_c, v_max, λ o R dentro de sus rangos. Consecuencia: con el stick en reposo (v_c = 0) no hay atracción y el cursor no se mueve solo. Se anula además con d < 3 px (evita temblor), con v_c ≥ 450 px/s y si el ajuste está desactivado. El objetivo cambia solo si otro candidato está más cerca por más de 8 px†. **Desempate cuando varios elementos comparten captación** (distancia < su R): es candidato el de menor `d` (centro más cercano); a igual `d`, el más cercano a la dirección del stick y después el primero en el orden de enfoque del puzle (Edge Cases); `w` se calcula solo con el R del objetivo. Con R_max_elem = 128 px, dos centros a menos de 256 px pueden compartir captación, pero siempre hay un único objetivo.
**Example:** d = 40, v_c = 100, 60 fps → w = 0,375; factor 0,080; sin tope Δp = 1,2 px/fotograma (72 px/s); el tope `0,5 · 100 / 60` = 0,833 px/fotograma lo reduce a **Δp = 0,833 px/fotograma (50 px/s)**. Con v_c = 400 el tope es 3,33 px/fotograma y no actúa. Con un elemento de tolerancia 88 px (0,04 m en D01a): R = min(max(64, 88), 128) = 88, w = 1 − 40/88 = 0,545 y Δp sin tope = 40 × 0,0800 × 0,545 = 1,745 px/fotograma (el tope con v_c = 100 sigue en 0,833); con 220 px (0,10 m) R = 128 (tope).

### F6 · Pulsación prolongada y umbral de arrastre

The pulsación prolongada formula is defined as:

`largo = (t_ahora − t_pulsado) ≥ t_hold;      arrastre = (|p − p_pulsado| ≥ d_arrastre)`

**Precedencia:** durante una pulsación de `seleccionar` decide la **primera señal** que se cumpla y la otra se descarta hasta soltar. `largo` solo cuenta como señal si el elemento acepta `mantener`; `arrastre` solo si acepta `agarrar` o `rotar` (con mando, `rotar` empieza al sacar el stick de la zona muerta, no por distancia). Si no se cumple ninguna, al soltar se emite `seleccionar`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t_hold | float (s) | 0,3–1,0 (hasta 1,5 en accesibilidad) | data file, 0,5 (slice, B.3) (ajuste de accesibilidad) | Umbral de pulsación prolongada |
| d_arrastre | float (px) | 4–16 | data file, 8† | Distancia mínima para que mantener `seleccionar` sea `agarrar` y no `mantener` |
| p, p_pulsado | Vector2 (px) | — | calculated | Posición actual del cursor y al pulsar |

**Output Range:** el tiempo es real, no escalado. Por debajo de 0,3 s, los toques y el temblor activan `leer` sin querer; por encima de 1,0 s el juego parece no responder; hace falta un indicador de progreso (el art bible excluye las barras).
**Example:** con 0,5 s, una pulsación de 0,18 s es corta y una de 0,62 s es larga. Mantener 0,6 s moviendo 3 px es `mantener` (a los 0,5 s); mantener y moverse 12 px es `agarrar`. Mantener quieto 0,6 s (ya `mantener`) y luego moverse 12 px **no** emite `agarrar`; moverse 12 px a los 0,3 s (`agarrar`) y detenerse hasta los 0,6 s **no** emite `mantener`. Si el elemento no acepta `mantener`, mantener quieto 0,6 s y luego moverse 12 px sí es `agarrar`.

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

No hay fórmula: la duración la fijan la cámara o el director de escenas. Sí hay un **tope de seguridad**, tras el cual se registra el error y se libera el contexto: **3 s†** para transiciones de cámara y animaciones (debe cubrir la cadena más larga declarada por 7, D01a: tope `BOX_OPEN_MAX` 1,6 s (10; cada compartimento declara el suyo ≤ tope) + `t_vista_entrada_s` ≤ 1,2 s = 2,8 s, más margen); para `sin control`, la **duración máxima que declara quien lo pide más un margen de 2 s†**: el director de escenas (21) declara la de cada escena en su GDD, y Escena de planta (4) declara `D_carga` (su F3: p. ej. ≈ 11,67 s para `recepcion`, tope ≈ 13,67 s) para las cargas de escena. **El tope se renueva con el traspaso** (regla 6): tras «traspasar `sin control`» el tope pasa a ser la nueva duración más el margen, contado desde ese instante (p. ej. el 21 toma el control en t = 9 s con 20 s declarados: el tope vence en t = 31 s, no en 13,67 s); el reinicio de la pila al descargar **no** renueva la cuenta. Si el tope libera un `sin control` y la pila quedaría vacía, queda `exploración`. Siempre hay un tope: un bloqueo de una transición corta se libera a los 3 s, no a los de la escena más larga. Una tecla mantenida durante la transición no debe dispararse al terminar (se ignora hasta soltarla). **Esta regla se aplica a las acciones disparadoras (`interactuar`, `leer`, `atrás`…), no al eje continuo `mover`:** si el jugador mantiene W cuando vuelve `exploración`, el Jugador (2) camina en ese tick (contrato 2↔7, GDD 2 fuente de verdad). Las transiciones bloqueantes declaradas por 7 (cámara/gesto, sin `sin control`) usan el tope de 3 s y este se detiene con la pausa igual que el de `sin control`.

### Valores por defecto y rangos seguros

| Valor | Defecto | Rango seguro |
|---|---|---|
| k_m (ratón, °/px) | 0,10† | 0,03–0,30 |
| dz_in / dz_out | 0,15† / 0,05† | 0,05–0,5 / 0–0,2 |
| ω_max (mirada con stick, °/s) | 120† | 60–180 |
| ω_r_max (rotar con mando, °/s) | 60† | 20–90 |
| v_max (cursor virtual, px/s) | 900† | 400–1600 |
| R base / R_max_elem / λ (atracción) | 64 px† / 128 px† / 5† | 32–128 / 64–128 / 2–10 |
| t_hold | 0,5 s | 0,3–1,0 (1,5 accesible) |
| d_arrastre | 8 px† | 4–16 |
| N_m en T_m | 12 px en 0,2 s† | 6–40 px en 0,1–0,5 s |
| Tope de transición (cámara y animación) | 3 s† | 3–5 (debe cubrir la cadena más larga declarada por 7, D01a: tope `BOX_OPEN_MAX` 1,6 s (10; cada compartimento declara el suyo ≤ tope) + `t_vista_entrada_s` ≤ 1,2 s = 2,8 s, más margen) |
| Margen sobre la duración declarada (escenas dirigidas) | 2 s† | 1–5 |

## Edge Cases

**Dispositivos**
- **If el jugador usa teclado/ratón y mando a la vez**: ambos funcionan; el dispositivo activo es el del último evento (regla 3) y solo cambia los iconos.
- **If el ratón se mueve por una vibración o el stick tiene deriva**: no cuenta como uso mientras no supere los umbrales de histéresis (ver Formulas); los iconos no cambian.
- **If se conectan dos mandos**: se aceptan los dos como un único «mando»; el activo es el último que generó entrada. No hay asignación por jugador.
- **If un mando se desconecta y no era el dispositivo activo**: no ocurre nada visible; si era el activo, se aplica la regla 22 (pausa con mensaje).
- **If el mando se desconecta durante una animación que bloquea el contexto** (p. ej. `ANIM_PHONE_PICKUP`): el menú de pausa se abre en el acto, igual que la pérdida de foco (regla 22; la regla 8 deja pasar `pausa`), y la animación se detiene con el tiempo de juego. Durante una carga de escena se abre al terminar la carga.

**Contextos**
- **If se pide entrar en un contexto que ya está arriba de la pila**: se ignora (no se apila dos veces). **Excepción: `sin control`**, que no se ignora sino que se rechaza y se registra; el relevo se pide con «traspasar `sin control`» (regla 6).
- **If un sistema pide salir de un contexto que no es el de arriba**: se rechaza y se registra; la pila no cambia.
- **If se abre el menú de pausa durante `vista cercana`, `ordenador` o `llamada`**: al cerrarlo se restaura el contexto con el cursor donde estaba y el estado del puzle intacto; el tiempo de juego (incluida la cuenta de 20 s de la llamada) se detuvo mientras tanto.
- **If una escena se descarga con la pila en un contexto distinto de `exploración`** (p. ej. al pasar a Recepción, tras el aviso «carga de escena iniciada» de 4): la pila se reinicia a [`sin control`] **conservando dueño, duración y cuenta del tope del `sin control` vigente** (regla 6; sin aviso si ya era el superior) hasta que su dueño la devuelva a `exploración` o el 21 la traspase. Durante la carga `pausa` se descarta (regla 7).
- **If la carga falla** (aviso «carga de escena fallida»): `carga_en_curso` termina, el 4 repone `menú` (pila [`menú`]) y el jugador sale del mensaje de error con `ui_aceptar` («Volver al título», GDD 4 regla 14). La pausa pendiente por foco o mando (reglas 21 y 22) se descarta: `menú` ya es la base de la pila.
- **If el 21 no traspasa el `sin control` de la carga con `control_final` = `ninguno`**: sigue siendo del 4 y lo libera el tope `D_carga` + margen, con el error registrado (F8).
- **If llega una acción durante una transición que bloquea el contexto**: se descarta, no se guarda (regla 8); la única excepción es `pausa`.
- **If el jugador mantiene `seleccionar` al entrar en `vista cercana`** (porque el botón de interactuar es el mismo): esa pulsación no cuenta como `seleccionar` hasta soltarse y volver a pulsar.
- **If se mantiene `interactuar` y el contexto cambia antes de cumplirse el umbral**: la pulsación en curso se cancela.

**Gestos**
- **If el cursor virtual sale de la ventana o de la zona del puzle**: se detiene en el borde de la zona permitida; el cursor real del ratón queda confinado a la ventana.
- **If se suelta `seleccionar` fuera de cualquier destino válido durante `agarrar`**: la pieza vuelve según las reglas de su puzle (p. ej. a la bandeja en el puzle 3); este sistema solo entrega «soltar».
- **If se rota con el mando y se llega al límite del control**: el giro se detiene en el límite sin rebotar.
- **If la atracción asistida compite entre dos elementos a la misma distancia**: gana el que está más cerca de la dirección del stick; si sigue el empate, el primero en el orden de enfoque del puzle.
- **If se mantiene `seleccionar` en un elemento sin acción de mantener**: el tiempo no es señal (F6); se emite `seleccionar` al soltar, o `agarrar`/`rotar` si el cursor supera el umbral antes.
- **If la pulsación mantenida es `agarrar` y el cursor se detiene sin llegar a ningún destino**: sigue siendo `agarrar` hasta soltar; no pasa a `mantener`.
- **If se escribe en el campo de búsqueda del ordenador y se pulsa `Retroceso`**: borra un carácter; no cierra el ordenador ni dispara `atrás` (regla 20). `Esc` abre la pausa, no cancela el texto.

- **If se pulsa `atrás` en `exploración` sin ningún documento relegible en el bolsillo**: `repasar_bolsillo` no hace nada (sin sonido ni mensaje, 20 R19).
- **If se pulsa `atrás` en `exploración` durante un gesto de 7**: la acción llega a 20 y 7 devuelve `APLAZADA` o `RECHAZADA` (regla 23); Entrada no la guarda.

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

**Aguas arriba (de qué depende):** ninguna dura. Usa las capacidades de entrada del motor (teclado, ratón, mando) y un fichero de datos con las asignaciones por defecto. **Blanda: 3 Estado y bus de eventos**, solo para emitir «dispositivo de entrada cambiado» y «contexto de entrada cambiado» (regla 10 del GDD del 3); Entrada funciona sin el bus salvo por esos dos avisos y, en sentido inverso, los avisos «carga de escena iniciada» / «carga de escena terminada» de 4 (regla 7); no lee ni escribe hechos. **Blanda: 4 Escena de planta**, emisor de esos avisos («iniciada» con `D_carga`, «terminada» y «fallida») y quien abre el `sin control` de una carga con `D_carga` (F8); sin 4, la pausa nunca se bloquea y las cargas usarían el tope de 3 s. **Dureza entre 2 y 4:** la dependencia entre Jugador (2) y Escena de planta (4) es dura en ambos sentidos (GDD 4); no afecta a la blanda de Entrada con 4. Escucha además «ajustes aplicados» de 6. Necesita **leer** de Ajustes (6) las asignaciones personalizadas al arrancar; ese contacto va por el bloque exportable de la regla 19, de modo que Ajustes depende de este sistema y no al revés.

**Aguas abajo (quién depende de este sistema).**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 2 Jugador | Dura | `mover`, `mirar` |
| 7 Interacción | Dura (contrato 2↔7: el GDD 2 prevalece) | `interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero; petición de contextos |
| 25 Menú de pausa | Dura | `pausa`, `ui_*`; contexto `menú`; API de reasignación |
| 30 Accesibilidad | Dura | API de reasignación y ajustes de manejo |
| 6 Ajustes | Dura | Guarda y reaplica el bloque de asignaciones y ajustes de manejo |
| 19 Ordenador | Dura | Cursor, `seleccionar`, texto; el teclado en pantalla de 19 (R16) se opera con el mismo cursor y `seleccionar`, sin acciones nuevas de Entrada |
| 20 Documentos y bolsillo | Blanda (así la declaran 20 y el índice) | Acción derivada `repasar_bolsillo` (regla 23) |
| 22 Llamada | Blanda | Contexto `llamada`, `ui_*` |
| 24 Prompt de interacción | Blanda | Dispositivo activo y asignación vigente de cada acción (para el icono) |
| 27 Pantalla de título y cierre | Blanda | `ui_*`, cursor |
| 21 Director de escenas | Dura | Peticiones de `sin control`, con su duración máxima declarada (F8), «traspasar `sin control`» al relevar al 4 (regla 6) y *abrir* un `sin control` propio en el cierre de la escena 8 (`ESC8_CIERRE`, 25,8 s declarados); es el 21 quien queda como dueño bajo una pausa en «Nueva partida desde la pausa» (operación «descartar la pila al aceptar una carga», regla 6) y recibe «`sin control` absorbido» si la pierde |
| 4 Escena de planta | Blanda (aguas arriba: emite avisos y declara `D_carga`) | Avisos de carga (iniciada, terminada, fallida); contexto `sin control` durante la carga; petición de `exploración`; reposición de `menú` |
| 25 Menú de pausa (pantalla de «Mando desconectado») | Pendiente | Mensaje y opción «continuar» al reconectar (regla 22): sin definir hasta el GDD del 25 |
| 18 Base de contenido narrativo | Blanda (aguas arriba) | Rótulos `UI_…` de la pantalla de reasignación y de los avisos de Entrada |
| 3 Estado y bus de eventos | Blanda (aguas arriba) | Recibe «dispositivo de entrada cambiado» y «contexto de entrada cambiado» |
| 10 Caja y compartimentos | Dura (indirecta) | El token `bloquear_contexto` declara una transición bloqueante de Entrada con su tope (regla 8, F8: cita `BOX_OPEN_MAX` de 10) |
| 11 a 16 Puzles | Indirecta (vía 7) | Gestos de puntero |

**Índice de sistemas:** ya refleja al sistema 1 como dependencia de 2, 4 (blanda; fila 4: «3 (blandas: 1, 6, 18)»), 6, 7, 19, 21, 22, 24, 25, 27 y 30 (verificado en la ronda 4; ya no falta nada).

**Bidireccionalidad.** El par con el sistema 3 está cerrado en ambos sentidos (su regla 10 y su tabla de Dependencies listan a Entrada como emisor blando). Los GDDs ya redactados 2, 4, 6, 7 y 18 listan a Entrada y controles (verificado en la ronda 4); 5 y 9 no la necesitan como dependencia (ni el índice la lista). Los GDDs 19, 20, 21 y 10 ya la listan (19 y 21 como dura, 20 como blanda y 10 como dura indirecta; verificado en la ronda de corrección 2); los sistemas sin GDD (22, 24, 25, 27, 30…) deben listarla y usar los nombres de acción de la regla 1.

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
- **Rotar con mando:** el control debe poder clavar 40° ± 3° en ~4,4 s con un stick (F4, puzle 5).
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
| `design/gdd/escena-de-planta.md` · reglas 7 y 12, F3 | Avisos «carga de escena iniciada» / «terminada»; `D_carga` como duración declarada de `sin control` | Contrato con 4 (regla 7, F8) |
| `design/gdd/interaccion-e-inspeccion.md` · reglas 9, 19, F6 | `verbo_corto`/`verbo_largo`, avisos de fin de transición, `F6_ppm` (2.203 px/m) | Reglas 8, 10 y F5b |
| `design/gdd/systems-index.md` | Fila 1 y dependientes 2, 4 (blanda), 6, 7, 19, 21, 22, 24, 25, 27, 30 | Debe reflejar la tabla de Dependencies |
| `docs/engine-reference/godot/modules/input.md` | SDL3 (4.5), foco dual (4.6), identificación por tipo de evento (4.7) | Restricciones de motor para la implementación |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/input/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante; **V** = captura retenida en `production/qa/evidence/`, bloqueante. Tolerancia numérica ±0,001 salvo indicación. Los valores marcados † en Formulas pueden cambiar tras el playtest; los criterios numéricos se actualizan con ellos. El GDD no define presupuesto de latencia ni de CPU y no se inventa uno.

**Reglas (acciones, dispositivos y contextos)**
- **AC-01 (R1, L)**: **GIVEN** el mapa de acciones cargado, **WHEN** se listan, **THEN** existen solo las acciones físicas de la regla 1 (`leer`, `agarrar`, `rotar` y `mantener` no figuran como acciones: son gestos derivados) y no existen `correr`, `agacharse` ni `saltar`.
- **AC-02 (R2, L)**: **GIVEN** teclado y mando conectados, **WHEN** se emite `interactuar` desde cada uno, **THEN** ambas llegan al juego sin elegir dispositivo.
- **AC-03 (R3, L + V)**: **GIVEN** la partida recién arrancada, **THEN** el dispositivo activo es teclado/ratón; **WHEN** llega una tecla o botón, **THEN** el dispositivo activo cambia de inmediato y se emite una sola vez «dispositivo de entrada cambiado». *(V: los iconos del prompt cambian; se cierra cuando exista el sistema 24.)*
- **AC-04 (R4, L + I)**: **GIVEN** el mapa de acciones y `default_bindings.json`, **THEN** ninguna acción tiene una asignación que combine dos botones, una doble pulsación o un temporizador de reacción, y las únicas esperas son `t_hold` y el arrastre (L). **GIVEN** el recorrido completo del slice con cada dispositivo, **THEN** el playtest documentado no registra ninguna acción que lo exija (I).
- **AC-05 (R5, L)**: **GIVEN** el contexto `inspección`, **WHEN** llega `mover`, **THEN** se descarta.
- **AC-06 (R6, L)**: **GIVEN** `vista cercana` con el cursor en (X, Y) y luego `menú` encima, **WHEN** se sale del menú, **THEN** el contexto y el cursor vuelven a (X, Y).
- **AC-07 (R7, L)**: **GIVEN** cualquier contexto salvo una carga de escena, **WHEN** llega `pausa`, **THEN** se abre el menú y el tiempo de juego se detiene; **WHEN** llega `pausa` o `atrás` con el menú abierto, **THEN** se cierra y se restaura el contexto inferior con un solo cierre por pulsación; **WHEN** llega `pausa` entre «carga de escena iniciada» y «carga de escena terminada», **THEN** no se abre y no se guarda; sin esos avisos la pausa no se bloquea nunca.
- **AC-08 (R8, L)**: **GIVEN** el contexto `sin control`, **WHEN** se pulsa `interactuar` y termina la transición, **THEN** no se dispara; **WHEN** se pulsa `pausa`, **THEN** abre el menú. **GIVEN** una transición bloqueante de 7, **THEN** termina con «cámara cedida» (entrada), «cámara devuelta» (salida) o «gesto terminado», y en cada caso el contexto acepta acciones desde ese aviso.
- **AC-09 (R9, L)**: **GIVEN** F2 y F3, **WHEN** se mira, **THEN** con relative = (1000, 0) el giro entregado se limita a 45° (tope de F2) y con delta = 0,5 s a 0,1 s de F3; el sistema entrega solo el cambio de orientación y no recibe ni aplica ningún límite de pitch o yaw de la cámara.
- **AC-10 (R10, L + V)**: **GIVEN** un objeto sin `verbo_largo`, **WHEN** se pulsa `interactuar`, **THEN** el verbo corto se dispara al pulsar; **GIVEN** un objeto con `verbo_corto` y `verbo_largo`, **WHEN** la pulsación dura 0,18 s, **THEN** el verbo corto se activa al soltar; **GIVEN** un objeto con solo `verbo_largo` (un documento), **WHEN** la pulsación dura 0,18 s, **THEN** no se activa nada (7 pulsa el anillo y suena `SFX_CLICK_SUBTLE`); **WHEN** la pulsación dura 0,62 s en cualquiera de los dos con `verbo_largo`, **THEN** se lanza `leer` a los 0,5 s y un indicador de progreso es visible (V).
- **AC-11 (R11, L)**: **GIVEN** el contexto `inspección`, **WHEN** llega `mirar`, **THEN** gira el objeto y no la cámara; **WHEN** llega `atrás`, **THEN** se suelta.
- **AC-12 (R12, I + V)**: **GIVEN** el mando en `vista cercana` u `ordenador`, **THEN** cualquiera de los dos sticks mueve el cursor; en `llamada` y `menú`, solo el derecho; en `exploración` no hay cursor y el ratón queda capturado (V).
- **AC-13 (R13, L)**: **GIVEN** `seleccionar` mantenida sobre un elemento que acepta `agarrar` y `mantener`, **WHEN** el cursor se mueve 8 px o más antes de 0,5 s, **THEN** se emite `agarrar` (y no `mantener` aunque después se detenga); **WHEN** se mantiene 0,5 s moviéndose menos de 8 px, **THEN** se emite `mantener` (y no `agarrar` aunque después se mueva 12 px); **GIVEN** un elemento que no acepta `mantener`, **WHEN** se mantiene 0,6 s quieto y se suelta, **THEN** se emite `seleccionar`; **WHEN** se suelta sin gesto derivado, **THEN** `seleccionar` se emite al soltar; **WHEN** se rota con el ratón sobre un control que acepta `rotar`, **THEN** 160 px horizontales dan 40° (incluidos los px previos al umbral) y el cursor queda quieto; con mando, solo gira el eje horizontal del stick de mayor magnitud.
- **AC-14 (R14, L)**: **GIVEN** el ajuste «alternar» activo, **WHEN** se pulsa una vez, **THEN** `leer`, `mantener`, `agarrar` y `rotar` empiezan y otra pulsación los termina (`rotar`: el giro lo controla el ratón o el stick entre ambas pulsaciones y el cursor queda quieto); **WHEN** llega `atrás` o cambia el contexto, **THEN** el gesto se cancela. Por defecto el ajuste está desactivado.
- **AC-15 (R15, L)**: **WHEN** se reasigna `interactuar` a `F`, **THEN** `F` funciona y `E` ya no; se permiten dos asignaciones por acción y dispositivo y la tercera se rechaza; `mover` y `mirar` se reasignan como conjunto; las acciones `ui_*` y `mover_cursor` no se pueden reasignar; `leer`, `agarrar`, `rotar` y `mantener` no aparecen en la pantalla de reasignación y siguen a `interactuar`/`seleccionar` (reasignar `seleccionar` a otra entrada la cambia para los cuatro).
- **AC-16 (R16, L)**: **WHEN** se asigna a una acción física una entrada ya usada por otra del mismo contexto, **THEN** se ofrece intercambiar o cancelar; entre contextos distintos se permite. **GIVEN** `default_bindings.json` tal como se entrega, **THEN** el validador lo acepta sin conflictos (el par `pausa`/`ui_atrás` en `Esc` de `menú` está en la lista de excepciones y los gestos derivados no cuentan).
- **AC-17 (R17, L)**: **WHEN** se quita la última asignación de `pausa`, `atrás` o `interactuar` en un dispositivo, **THEN** se rechaza; **WHEN** se intenta dejar como única asignación de `atrás` en teclado/ratón una tecla imprimible, **THEN** se rechaza; «restablecer» funciona por acción y por dispositivo.
- **AC-18 (R18, L)**: **GIVEN** los ajustes de manejo cambiados, **WHEN** se exportan y se importan, **THEN** se conservan todos, incluidos sensibilidad e inversión vertical por dispositivo.
- **AC-19 (R19, L)**: **GIVEN** `assets/data/input/default_bindings.json` modificado, **WHEN** arranca el juego, **THEN** el cambio se refleja sin tocar código; importar un bloque válido restaura las asignaciones.
- **AC-20 (R20, I + L)**: **GIVEN** el contexto `ordenador` con el campo de búsqueda enfocado y teclado físico, **THEN** se escriben caracteres; **WHEN** se escribe «tra» y se pulsa `Retroceso` dos veces, **THEN** el campo queda en «t», el contexto sigue siendo `ordenador` y no se emite `atrás` (I); **WHEN** se pulsa `Esc`, **THEN** abre la pausa y el texto no se borra; **WHEN** se pulsa clic derecho, **THEN** se emite `atrás` y se sale del ordenador. **GIVEN** `default_bindings.json`, **THEN** `Retroceso` no está asignado a ninguna acción (L). **GIVEN** `atrás` reasignada a una tecla imprimible (además del clic derecho), **WHEN** el campo tiene el foco, **THEN** la tecla escribe y no emite `atrás` (L). *(Con mando no hay criterio hasta definir el teclado en pantalla; ver Open Questions.)*
- **AC-21 (R21, I)**: **GIVEN** `interactuar` mantenida, **WHEN** la ventana pierde el foco, **THEN** la acción se cancela sin disparar `leer` y se abre la pausa.
- **AC-22 (R22, I)**: **GIVEN** el mando como dispositivo activo, **WHEN** se desconecta, **THEN** se abre la pausa con «Mando desconectado», teclado y ratón pueden reanudar y al reconectar se ofrece continuar; si el mando no era el activo, no ocurre nada visible.

**Fórmulas (valores del ejemplo, tolerancia ±0,001 salvo indicación)**
- **AC-F1 (L)**: **GIVEN** v = (0,5; 0,4), **THEN** r = 0,613; \|v\| = 0,15 → 0; \|v\| = 0,14 → 0; \|v\| = 0,95 → 1; \|v\| = 1 → 1; el ajuste de `dz_in` rechaza valores < 0,05.
- **AC-F2 (L)**: **GIVEN** relative = (18, −6), s_m = 1, inv = +1, **THEN** yaw = 1,8° y pitch = −0,6°; 3.600 px dan 360°; el resultado es idéntico simulando 30 y 144 fps; un pico enorme se limita a ±45° por fotograma.
- **AC-F3 (L)**: **GIVEN** r = 0,613, **THEN** ω = 57,6 °/s (±0,1) y 0,96 °/fotograma a 60 fps y 1,92 °/fotograma a 30 fps; con delta = 0,5 s se usa 0,1 s; con ω_max = 120 y s_s = 2 el máximo es 240 °/s, y con ω_max = 180 y s_s = 2, 360 °/s.
- **AC-F4 (L)**: **GIVEN** el ratón, **THEN** 160 px = 40°; **GIVEN** el mando, **THEN** r = 0,71 → 30 °/s (±0,5), r = 0,35 → 7,4 °/s, r = 0,2 con freno → 1,2 °/s; soltar el stick deja la velocidad en 0 y conserva el ángulo.
- **AC-F5 (L)**: **GIVEN** r = 0,613, **THEN** v_c = 338 px/s (±1); r = 0,2 → 36 px/s; r = 1 con s_c = 1,5 → 1.350 px/s; la posición queda dentro de la ventana. **GIVEN** d = 40, v_c = 100 y 60 fps, **THEN** w = 0,375, factor = 0,080, Δp sin tope = 1,2 px/fotograma y Δp final = 0,833 px/fotograma (±0,01); no hay atracción con d < 3 px, con v_c ≥ 450 px/s, con v_c = 0 ni con el ajuste desactivado; el objetivo cambia solo si otro candidato está más cerca por más de 8 px. **R por elemento:** tolerancia 88 px → R = 88 (w = 0,545 con d = 40); tolerancia 220 px → R = 128; tolerancia 20 px → R = 64; con dos candidatos que comparten captación gana el de menor `d` y `w` usa el R del objetivo. Salida máxima de F5a: v_max = 1600 y s_c = 1,5 → 2.400 px/s. **Escape:** **GIVEN** cada combinación de extremos (s_c = 0,5 y 1,5; v_max = 400 y 1600; λ = 2 y 10; R = 32 y 128) y cualquier r > 0 fuera de la zona muerta, **THEN** la velocidad neta del cursor hacia fuera del objetivo es mayor que 0 (la tracción nunca supera `0,5 · v_c`). Con delta = 0,5 s se usa 0,1 s.
- **AC-F6 (L)**: **GIVEN** t_hold = 0,5 s, **THEN** 0,18 s es corta y 0,62 s es larga; mantener 0,6 s moviéndose 3 px es `mantener` y moviéndose 12 px es `agarrar` (en elementos que aceptan ambos, la primera señal decide: quieto 0,6 s y luego 12 px es `mantener`, sin `agarrar`; 12 px a los 0,3 s y parar hasta 0,6 s es `agarrar`, sin `mantener`).
- **AC-F7 (L)**: **GIVEN** el ratón, **THEN** 4 px en 0,2 s no cambian el dispositivo y 20 px sí; **GIVEN** el stick, **THEN** 0,2 no cambia y 0,35 durante 0,1 s sí; tras un cambio, el movimiento solo no cambia de nuevo durante 0,4 s.
- **AC-F8 (L)**: **GIVEN** un `sin control` del 4 (`D_carga` = 11,67 s) y un traspaso al 21 en t = 9 s con 20 s declarados, **THEN** el dueño pasa a ser 21, no se emite «contexto de entrada cambiado», el tope vence en t = 31 s (no a los 13,67 s) y a los 13,67 s el contexto sigue activo; **GIVEN** el reinicio de pila al descargar, **THEN** el dueño, la duración y la cuenta del tope no cambian (a los 11,67 + 2 s desde «iniciada» se libera igual). **GIVEN** una transición de cámara o animación que no termina, **WHEN** pasan 3 s, **THEN** se registra el error y se libera el contexto; **GIVEN** un `sin control` pedido con una duración máxima de 8 s, **WHEN** pasan 8 + 2 s, **THEN** se registra el error y se libera, y a los 3 s no se ha liberado; **GIVEN** una carga de escena pedida por 4 con `D_carga` = 11,67 s, **WHEN** pasan 11,67 + 2 s, **THEN** se registra el error y se libera, y a los 3 s no se ha liberado; **GIVEN** una petición de `sin control` sin duración declarada, **THEN** se aplica el tope de 3 s y se registra la omisión. Una tecla mantenida durante la transición se ignora hasta soltarla.

**Casos límite**
- **AC-E1 (L)**: entrar en un contexto que ya está arriba se ignora; salir de uno que no es el de arriba se rechaza, se registra y la pila no cambia.
- **AC-E2 (I)**: **GIVEN** una escena descargada con la pila fuera de `exploración` y un `sin control` del 4 vigente, **THEN** la pila queda [`sin control`] con el mismo dueño, duración y cuenta de tope; **GIVEN** la primera carga desde el título (pila [`menú`]), **THEN** al abrirse el `sin control` del 4 la pila es [`menú`, `sin control`]; con «carga de escena terminada» y `exploración` pedida queda [`exploración`]; con «carga de escena fallida» y reposición de `menú` queda [`menú`].
- **AC-E3 (L)**: **GIVEN** `seleccionar` mantenida al entrar en `vista cercana`, **THEN** no cuenta hasta soltarla y volver a pulsar.
- **AC-E4 (L)**: **GIVEN** una transición bloqueante activa (simulada con un marcador de bloqueo; no requiere la animación real) y el mando como dispositivo activo, **WHEN** se desconecta, **THEN** la pausa se abre en el acto con «Mando desconectado», igual que con la pérdida de foco; **GIVEN** una carga de escena en curso, **THEN** se abre al terminar la carga. *(Observación con la animación real `ANIM_PHONE_PICKUP`: I, cuando exista.)*
- **AC-E5 (L)**: importar un archivo con una acción inexistente descarta esa entrada con una línea en el log; si hay conflicto en el mismo contexto, gana la primera de la tabla y la otra vuelve a su valor por defecto; `Esc` cancela la captura de una asignación sin cambios.
- **AC-E6 (L)**: mantener `seleccionar` sobre un elemento que no acepta `mantener` no emite `mantener` y se trata como `seleccionar` al soltar.
- **AC-E7 (I)**: con el menú abierto, recuperar el foco de la ventana no lo cierra.
- **AC-E8 (I)**: **GIVEN** una pausa durante `inspección`, `lectura` o `sin control`, **WHEN** se reanuda, **THEN** el objeto o la página siguen como estaban y el tope de la transición no avanzó durante la pausa.
- **AC-E9 (L)**: **GIVEN** un suscriptor y la pila en `exploración`, **WHEN** se entra en `inspección` y luego se sale, **THEN** recibe dos veces «contexto de entrada cambiado», con (`exploración`, `inspección`) y (`inspección`, `exploración`); **WHEN** se pide entrar en un contexto que ya está arriba o salir de uno que no lo está, **THEN** no recibe nada; **WHEN** se descarga la escena con la pila fuera de `exploración` y el superior no era `sin control`, **THEN** recibe un solo aviso con `sin control` como contexto nuevo; si el superior ya era `sin control`, no recibe ninguno.
- **AC-E10 (L)**: **GIVEN** la pila con solo el menú de título, **WHEN** llega `pausa`, `atrás` o `ui_atrás`, **THEN** el menú sigue abierto; **GIVEN** `pausa` reasignada a `Enter` o a una flecha, **THEN** se rechaza con el mensaje de conflicto.
- **AC-E11 (I)**: **GIVEN** la ventana que pierde el foco durante una carga de escena, **THEN** la pausa se abre al terminar la carga y no antes.
- **AC-E12 (L)**: **GIVEN** `interactuar` mantenida en `exploración` sobre un documento, **WHEN** el contexto cambia antes de 0,5 s, **THEN** la pulsación se cancela y no se lanza `leer`.
- **AC-E13 (L)**: **GIVEN** un `sin control` abierto por el 4 como superior, **WHEN** el 21 pide abrir otro `sin control`, **THEN** se rechaza y se registra; **WHEN** el 21 pide «traspasar», **THEN** cambia dueño y duración sin salir ni entrar, la pila no cambia y no hay aviso de cambio; **WHEN** un sistema que no es el dueño pide cerrarlo, **THEN** se rechaza; **WHEN** se pide «traspasar» sin `sin control` arriba, **THEN** se rechaza y se registra; **WHEN** el dueño pide `exploración`, **THEN** la pila queda [`exploración`] y se emite un solo aviso (`sin control`, `exploración`); **WHEN** el 4 repone `menú`, **THEN** la pila queda [`menú`].
- **AC-E13b (L)** *(ronda 4, N-B1)*: **GIVEN** la pila [`menú`, `sin control`(4)] de una carga desde el título con `control_final` = `ninguno`, **WHEN** el 21 traspasa, **THEN** la pila sigue [`menú`, `sin control`(21)] sin aviso; **WHEN** el 21 pide `exploración`, **THEN** la pila queda [`exploración`] (sin `menú` debajo) con un solo aviso (`sin control`, `exploración`). **Cierre normal (ronda 5, E-1):** desde [`menú`, `sin control`(21)] (el 21 no pidió `exploración`: error de uso), **WHEN** el 21 «cierra» su `sin control`, **THEN** la pila queda [`menú`] y se registra el defecto. **Vuelta al título desde Recepción:** desde [`sin control`(21)] (sin `menú` debajo), **WHEN** el 4 completa la descarga total y pide *Reponer `menú`*, **THEN** la pila queda [`menú`] con un solo aviso; el 21 no cierra nada.
- **AC-E13c (L)** *(firme, ronda de corrección 2, E4-1; AC-21-23b)*: **GIVEN** la pila [`sin control`(21), `menú`] durante `ESC1_LLEGADA` o `ESC8_CIERRE`, **WHEN** llega «carga de escena iniciada» del 4 por `partida_nueva` o `continuar` desde la pausa, **THEN** la pila pasa a [`sin control`(4)] con un solo aviso «contexto de entrada cambiado» (`menú`, `sin control`) y el aviso «`sin control` absorbido» (dueño 21) y, tras el traspaso del 21 y su petición de `exploración` (o la del 4 con `continuar`), queda [`exploración`]. **GIVEN** la pila [`menú`(título), `sin control`(21), `menú`(pausa)] durante `ESC1_LLEGADA` (Nueva partida → pausa → Nueva partida), **WHEN** llega esa misma «iniciada», **THEN** el resultado es el mismo [`sin control`(4)] (la pila entera se descarta, el `menú` del título incluido), el tope contado es el del 4 (`D_carga` + 2 s desde esa apertura) y el `sin control`(21) no puede liberar el contexto durante la carga (a los 15 + 2 s del tope antiguo, la pila sigue [`sin control`(4)]). **GIVEN** una de esas pilas y que la carga **falla**, **THEN** el 4 repone `menú` ([`menú`]). **GIVEN** [`sin control`(21), `menú`] y que el 4 pide *abrir* sin carga `partida_nueva`/`continuar` aceptada, **THEN** se rechaza y se registra como en AC-E13. **GIVEN** [`menú`] del título, **THEN** *abrir* funciona como siempre ([`menú`, `sin control`(4)]; AC-E2) y no se emite «`sin control` absorbido».
- **AC-E15 (R1, R23, L)** *(decisión D27)*: **GIVEN** la pila [`exploración`], **WHEN** llega una pulsación de `atrás`, **THEN** se emite una sola vez `repasar_bolsillo`; **WHEN** se mantiene el botón (auto-repetición) o se suelta, **THEN** no se emite nada más; **GIVEN** la pila en `inspección`, `lectura`, `vista cercana`, `ordenador`, `llamada`, `menú` o `sin control`, **WHEN** llega `atrás`, **THEN** nunca se emite `repasar_bolsillo`.
- **AC-E16 (R23, R14, L + I)** *(decisión D27; cubre 20 AC-14)*: **GIVEN** una `lectura` abierta desde `exploración`, **WHEN** el jugador pulsa `atrás`, la lectura se cierra (la pila vuelve a [`exploración`]) y mantiene o suelta el botón, **THEN** esa pulsación no emite `repasar_bolsillo`; **WHEN** pulsa `atrás` de nuevo, **THEN** se emite una vez. **GIVEN** el ajuste «alternar» y un `leer` en curso, **WHEN** llega `atrás`, **THEN** cancela el gesto y no emite `repasar_bolsillo`.
- **AC-E17 (R23, R8, I)** *(decisión D27)*: **GIVEN** una transición bloqueante de 7 en `exploración`, **WHEN** llega `atrás`, **THEN** `repasar_bolsillo` llega a 20 (y 7 responde `APLAZADA` o `RECHAZADA`), Entrada no la guarda ni la repite al terminar la transición y el resto de acciones sí se descartan (AC-08); **GIVEN** `atrás` reasignada, **THEN** `repasar_bolsillo` sigue a la asignación vigente.
- **AC-E14 (L)**: **GIVEN** «carga de escena iniciada» y luego «carga de escena fallida», **THEN** `pausa` queda bloqueada entre los dos avisos y vuelve a aceptarse tras el segundo (con `menú` en la base de la pila no abre nada); una pausa pendiente por pérdida de foco durante la carga se descarta.

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | ~~Teclado en pantalla para el mando en el campo de búsqueda del ordenador.~~ **Resuelta por 19 (R16, D19-13/14):** teclado en pantalla anclado bajo el campo, operado con el cursor de los sticks y `seleccionar` (sin acciones nuevas de Entrada). Criterio de mando: AC-10a de 19 (el AC-20 de este GDD cubre el teclado físico). | — | Cerrada (2026-11-09) |
| 2 | ~~Equivalencia píxeles ↔ metros del puzle 3.~~ **Resuelta en lo esencial:** 7 F6 (`F6_ppm`) da 2.203 px/m en D01a (0,04 m = 88 px, 0,10 m = 220 px; sustituye al supuesto de 1.200 px/m). Falta que cada puzle entregue su tolerancia en px a 7 y confirmar el eje del FOV (verificación pendiente V2 de 7). | GDD del sistema 13 (y 7) | GDD del sistema 13 |
| 3 | **Tamaño y separación mínima** de los elementos pequeños de los puzles 1 y 4. El criterio de separación mínima (y su severidad) lo fijan la regla 22 de 7 y la regla 29 de 9 (R₁+R₂ con la tolerancia asistida, R = 128 px, es decir 256 px en el peor caso); este GDD no fija cifras propias. | GDD de los sistemas 11 y 14 (y 7/9) | Esos GDD |
| 4 | **Cursor visual** de los puzles (forma no circular, art bible §7.3) e **indicador de progreso** sin barras. | `/art-bible` (ampliar) o `/ux-design` | Fase de UX |
| 5 | **Auto-repetición de `ui_*`** (velocidad de navegación al mantener una dirección). | `/ux-design` | Fase de UX |
| 6 | **Foco y cursor simultáneos en `llamada` y `menú`:** qué resalta el último dispositivo usado (foco dual de Godot 4.6). | `/ux-design` | Fase de UX |
| 7 | **Teclado sin ratón:** el gesto `rotar` y el cursor no tienen alternativa solo con teclado. ¿Se exige por accesibilidad? | Sistema 30 (Accesibilidad) | GDD del sistema 30 |
| 8 | ~~Gesto de cámara de las pistas.~~ **Resuelta (decisión del usuario, ronda 2):** el nivel 1 de pista no mueve la cámara, usa un resaltado; no hay acción de entrada para pistas. | — | Cerrada (2026-11-09) |
| 9 | ~~Acción de leer con duración (A04 «Leer (2 s)»).~~ **Resuelta por 7:** `t_hold` = 0,5 s es el mantener y `lectura_min_s` = 2 s el tiempo mínimo de lectura. | — | Cerrada (2026-11-09) |
| 10 | **Valores †** de F1 a F7 y el tope de 3 s de F8: validar en el primer playtest. | Playtest (slice §23.4) | Primer playtest |
| 11 | ~~Índice de sistemas: añadir el sistema 1 como dependencia de 6, 19, 21, 22, 24 y 27.~~ **Resuelta:** el índice ya lo refleja. | — | Cerrada (2026-11-08) |
| 12 | ~~Duración máxima de cada escena dirigida que pide `sin control` (F8).~~ **Resuelta por 21 (F2/F3):** `ESC1_LLEGADA` 15,0 s, `ESC8_ASCENSOR` 7,0 s, `ESC8_CIERRE` 25,8 s (más el margen de 2 s† de F8). Las cargas siguen declarando `D_carga` (4). | — | Cerrada (2026-11-09) |
| 13 | **Resolución lógica del cursor:** confirmar que los píxeles de F5a, F5b y F6 son del viewport lógico 1920 × 1080 (modo de estiramiento). | `/architecture-decision` | Fase de arquitectura |
| 14 | **Pendiente de verificación en el editor (no cubierto por `docs/engine-reference/godot/`; no se afirma nada):** (a) que el motor entregue ejes crudos sin zona muerta para F1 y cómo se combina con la zona muerta por acción del `InputMap`; (b) captura de ratón y `relative_px` acumulado; (c) señal de pérdida/recuperación de foco de la ventana y de conexión/desconexión de mando; (d) reasignación en caliente y guardado de eventos del `InputMap`. Nota ya respaldada por `modules/input.md`: desde 4.7 el dispositivo activo (regla 3, F7) se identifica por tipo de evento y no por `device == 0`. | `godot-specialist` / ADR de entrada | Antes de implementar las reglas 3, 12, 15, 21, 22 y F1 |
| 15 | **Validación de `gestos_aceptados`** por elemento (regla 13): 7 y los GDD de puzles deben declararlos; validar en playtest que ningún elemento del slice acepte a la vez `agarrar` y `mantener`, o que la precedencia de F6 resulte natural. | GDD 7 y puzles 11–16 | Esos GDD |
| 16 | ~~Relectura del bolsillo con `atrás` (20, Q1).~~ **Resuelta (decisión del usuario, 2026-11-09, D27):** `atrás` (pulsación corta) activa en `exploración` con la acción derivada `repasar_bolsillo` (regla 23); AC-E15 a AC-E17; 20 AC-11, AC-12, AC-12b y AC-14 y 9 AC-42 son firmes. | — | Cerrada (2026-11-09) |
| 17 | ~~«Nueva partida desde la pausa» durante una escena dirigida (operación «absorber el `sin control` ajeno»).~~ **Cerrada (ronda de corrección 2, E4-1, D22):** operación general y firme «descartar la pila al aceptar una carga» (regla 6, AC-E13c); aprobada por criterio del autor del lote 2026-11-09, **pendiente de confirmación del technical-director** (solo confirmación: no bloquea el diseño). | — | Cerrada (2026-11-09) |

## Decisiones tomadas

Ronda 2 (2026-11-09), en modo por lotes: se decide con la recomendación propia y se registra.

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D1 | **(Revisor, por defecto)** `Retroceso` deja de ser asignación por defecto de `atrás`; `atrás` = clic derecho / botón este. | Mantener `Retroceso` fuera del ordenador y que el campo de texto lo consuma en `ordenador`. | Evita que borrar un carácter cierre el ordenador y hace el mapa idéntico en todos los contextos. |
| D2 | En `ordenador` con el campo enfocado, el texto consume antes que cualquier acción las teclas imprimibles, `Retroceso`, `Supr`, flechas y `Enter`; `Esc` sigue siendo `pausa`. `atrás` conserva siempre una asignación no imprimible. | `Esc` cancela el texto. | `pausa` está garantizada en todos los contextos (regla 17). |
| D3 | `seleccionar` e `interactuar` son las únicas acciones físicas; `leer`, `agarrar`, `rotar` y `mantener` son gestos derivados no reasignables. `pausa`/`ui_atrás` en `Esc` de `menú` es una excepción declarada a la regla 16. | Acciones independientes con conflicto resuelto por contexto. | Un validador literal rechazaba las asignaciones por defecto; reasignar los gestos por separado no aporta accesibilidad. |
| D4 | La decisión corto/largo de `interactuar` es del catálogo de 7 (`verbo_largo`); con solo `verbo_largo` el toque corto no activa nada. | Que Entrada decida por tipo de objeto. | Contrato con 7 (regla 9). |
| D5 | El bloqueo de transición de 7 termina con «cámara cedida», «cámara devuelta» o «gesto terminado» (o 3 s). | Solo «devuelta»/«terminado». | La entrada a una vista se considera abierta con «cámara cedida» (regla 19 de 7). |
| D6 | `rotar` entra en «alternar en lugar de mantener» (regla 14). | Dejarlo como gesto mantenido. | Sin ello, el puzle 5 es injugable para quien no puede mantener un botón (*Tensión sin castigo*). |
| D7 | Precedencia de gestos: la primera señal (desplazamiento o `t_hold`) decide, el elemento declara `gestos_aceptados` y `seleccionar` se emite al soltar. Con mando, `rotar` usa el eje horizontal del stick de mayor magnitud. | Emitir `agarrar` y `mantener` a la vez; elegir un stick fijo. | Determinista y coherente con F5a (stick de mayor magnitud). |
| D8 | R por elemento acotado a 128 px; desempate por centro más cercano; una tolerancia asistida de 220 px no amplía la captación. | Ampliar R hasta la tolerancia. | La captación de 440 px solaparía elementos y rompería el control fino. |
| D9 | La desconexión de mando y la pérdida de foco abren la pausa en el acto, también en transiciones bloqueantes (salvo carga de escena). | Esperar al final de la animación. | Una sola regla; la regla 8 ya deja pasar `pausa` y el tiempo se detiene. |
| D10 | 4 es emisor blando de los avisos de carga y declara `D_carga` como duración de `sin control` (F8). | Tope fijo de 3 s para cargas. | Liberaría el control con la escena aún en negro (GDD 4, F3). |
| D11 | `dz_in` mínimo 0,05 (antes 0). | Documentar el riesgo. | Con 0, la deriva del stick contaría como uso (F7). |
| D12 | El «gesto de cámara» de las pistas deja de ser entrada (decisión del usuario: el nivel 1 usa resaltado). | — | Open Question 8 cerrada. |

Ronda 3 (2026-11-09), según `gdd-cross-review-2026-11-09.md` (C-B4, S-W3).

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D13 | `sin control` con dueño y duración, y operación «traspasar» (nuevo dueño y duración; tope renovado) para que el 21 releve al 4 sin soltar el control | Pedir `exploración` en «terminada» y que el 21 abra el suyo un fotograma después; o ignorar la petición del 21 | Sin fotograma sin contexto ni liberación del control a mitad de la escena 1 dirigida |
| D14 | El reinicio de pila al descargar conserva dueño, duración y cuenta del `sin control` vigente | Reiniciar a un `sin control` sin duración (3 s) | Con 3 s caducaba a mitad de una carga de hasta `D_carga` |
| D15 | Primera carga desde el título: [`menú`, `sin control`]; el fallo repone `menú` (4) y el jugador sale con `ui_aceptar` | Que el tope libere y el título quede sin contexto | S-W3: el jugador no tenía acción definida tras el mensaje de error |
| D16 | Pedir abrir un `sin control` con otro arriba se rechaza (no se ignora) | Ignorarlo como los demás contextos | Una petición ignorada dejaba al 21 sin control y sin aviso |
| D17 | `carga_en_curso` termina con «terminada» o «fallida» | Solo «terminada» | Un fallo dejaba la pausa bloqueada |
| D18 | N-B1 (ronda 4): «pedir `exploración`» lo puede pedir el dueño vigente del `sin control` superior (el 4 con `exploracion`, o el 21 tras un traspaso) y descarta lo que haya debajo si la pila venía del título; el cierre normal del `sin control` del 21 sobre [`menú`, `sin control`] restaura `menú` (solo vuelta al título). Tabla de pila antes/después por origen y AC-E13b | (b) fijar `control_final = exploracion` y quitar al 21 la escena 1; (c) que el traspaso desde el título descarte el `menú` | (a) es el arreglo mínimo y mantiene al 21 como director de la escena 1; (b) cambia el reparto 4/21 y (c) hace que el traspaso tenga efectos distintos según el origen |
| D19 | B-4 (ronda 4): rango seguro del tope de transición 3–5 s (antes 1–5 s) | Mantener 1–5 s y que 7 acote por tramo | El tope único debe cubrir la cadena más larga de 7 (D01a, 2,8 s); con 1 s Entrada libera antes de «cámara cedida» |
| D20 | Open Question 3 remite a 7 (regla 22) y 9 (regla 29) sin cifras propias | Mantener la recomendación de 16 px en Entrada | Tres severidades para el mismo dato (B-1); el criterio lo fijan 7 y 9 |
| D21 | E-1 (ronda 5): el cierre normal del 21 sobre [`menú`, `sin control`(21)] es un error de uso (restaura `menú`, se registra); la vuelta al título desde Recepción pasa por la descarga total + *Reponer `menú`* del 4, con la pila [`sin control`(21)] sin `menú` debajo | Mantener «único caso legítimo: vuelta al título desde Recepción» | Contradecía la tabla de pila de la regla 6 y el GDD 4 regla 15; ese caso no existe |

Ronda de propagación 1 (2026-11-09, lote Feature 1: 8, 10, 19, 20, 21).

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D22 | **Decisión (E4-1, ronda de corrección 2; antes propuesta), aprobada por criterio del autor del lote 2026-11-09, pendiente de confirmación del technical-director:** al aceptar una carga `partida_nueva`/`continuar` desde cualquier forma de la pila con un `sin control` ajeno (con o sin `menú` encima: [`menú`, `sin control`(21), `menú`], [`sin control`(21), `menú`]…), Entrada descarta la pila entera y deja [`sin control`(4)] con su `D_carga` + margen; emite el aviso «`sin control` absorbido» al dueño descartado. Tabla de pila con las formas nuevas; AC-E13c firme. No cambia AC-E13/E13b ni AC-21b. | (a) Cubrir solo [`sin control`(21), `menú`] (la propuesta anterior): deja sin definir la pila de tres elementos y el `sin control` antiguo caducaría a mitad de la carga. (b) Rechazar siempre. (c) Que el 21 emita una operación de pila. (d) Descartar también el `menú` del título cuando no hay `sin control` ajeno: rompería AC-E2/E13b y la reposición de `menú` ante un fallo | Una sola regla sobre la pila entera cubre todas las formas sin casos especiales y mantiene la regla 11b de 21 (21 no emite operaciones de pila); el `sin control` ajeno deja de existir, así que no hay tope que vigilar |
| D23 | Open Question 12 cerrada con las duraciones de 21 (15,0 / 7,0 / 25,8 s); Dependencies de 21 recoge la apertura de un `sin control` propio en `ESC8_CIERRE`. | Dejar la pregunta abierta hasta implementar 21 | 21 ya las declara (F2/F3) |
| D24 | Open Question 1 cerrada con R16 de 19 (teclado en pantalla con el mismo cursor, sin acciones nuevas); el criterio de mando es AC-10a de 19. | Acción nueva de Entrada para teclear | Regla 4 y 12: sin botones nuevos |
| D25 | F8: la cadena de 7 cita el tope `BOX_OPEN_MAX` 1,6 s de 10 y no el valor único `BOX_Cn_OPEN`. | Mantener `BOX_Cn_OPEN` | 10 lo sustituye por valores por compartimento con tope |
| D26 | ~~`atrás` en `exploración` / `repasar_bolsillo` queda como Open Question 16, no activada.~~ **Sustituida por D27.** | — | — |
| D27 | **Aprobada por el usuario, 2026-11-09:** `atrás` corta en `exploración` = acción derivada `repasar_bolsillo` (regla 23, tablas de acciones y de contextos, AC-E15 a AC-E17); se emite al pulsar, sin umbral `t_hold`; el `atrás` que cierra un modo o el menú no cuenta aunque deje `exploración` antes de soltar; es la única acción que se entrega durante una transición bloqueante de 7 sin guardarse (excepción a la regla 8, para que 7 decida `APLAZADA`/`RECHAZADA`). | (a) Menú de inventario (contradice slice D.1). (b) Sin relectura: la carta del P6 necesitaría un objeto de escena y 9 (D9-23) cambiaría. (c) `interactuar` mantenida sin objetivo (choca con `leer`, no es descubrible). (d) Emitir al soltar con umbral (retrasa la respuesta sin desambiguar nada). | Mantener el slice sin pantalla de inventario con el mínimo mando nuevo; el riesgo es abrir una lectura sin querer, sin coste (pilar *Tensión sin castigo*). |
| D28 | W-3 (ronda de corrección 2): Dependencies de Entrada alineadas con lo que declaran los GDDs y el índice: 19 **Dura**, 21 **Dura** y 20 **Blanda** (Entrada declaraba 19 y 21 blandas y 20 dura). Se añade la fila de 10 (**Dura, indirecta**, como declara 10; W-4). Discrepancia anotada: 19 dice que 21 es «Blanda» y 21 dice que 19 es «Blanda», pero el índice solo lista a Entrada para ambos, sin dureza; no afecta a Entrada | Mantener las durezas anteriores | Cada GDD es la fuente de su propia dependencia; la reciprocidad evita que un revisor lea dos tablas contradictorias |
| D29 | W-7 (ronda de corrección 2): retirado el «sin GDD» obsoleto de Bidireccionalidad (19, 20 y 21 ya existen y listan a Entrada; 10 también) | Dejarlo hasta el próximo lote | Texto desfasado señalado por la revisión |

## Historial de cambios

- **2026-11-09 (ronda 2, re-review):** aplicados los 3 bloqueantes y las 8 importantes del informe `reviews/entrada-y-controles-re-review.md` y los menores M1 a M6 (ver «Decisiones tomadas» D1 a D12): acciones físicas frente a gestos derivados, `Retroceso` fuera de `atrás` y texto en el ordenador, contrato con 4 (avisos de carga y `D_carga`), reglas 8 y 10 alineadas con 7, `rotar` en alternar, precedencia `mantener`/`agarrar`, pausa inmediata por mando o foco, R por elemento acotado (F5b), `dz_in` ≥ 0,05, Output Range de F5a, Open Questions 2, 3, 8, 9, 12, 14 y 15. Estado: Revisado (ronda 2) — pendiente de re-review.

- **2026-11-09 (lote 2/5/7/9, cambios derivados de las revisiones de 2 y 7):** (a) F8 y regla 8: la descarta-hasta-soltar se aplica a acciones disparadoras, no al eje `mover`; el bloqueo de transición lo mantiene 7 desde `interactuar()` hasta «cámara devuelta» / «gesto terminado» (tope 3 s, la pausa lo detiene). (b) `leer` retirada del contexto `inspección` (D7-28). (c) Contexto `ordenador`: V01 solo acerca la cámara, no hay «sentarse». (d) Fila de 7 en la tabla de contextos: 7 entrega las posiciones en px de los elementos de la vista para F5b (cierra parcialmente Open Question 2). **Cambia reglas: pendiente de re-review.** El estado del documento no se modifica.

- **2026-11-09 (ronda 3, aplica `gdd-cross-review-2026-11-09.md`):** regla 6 (dueño y duración del `sin control`; operaciones abrir, cerrar, traspasar, pedir `exploración`, reponer `menú`, reinicio que conserva dueño y duración; modelo de pila desde el título), regla 7 y Edge Cases («carga de escena fallida», relevo del 21), F8 (tope renovado con el traspaso), AC-F8, AC-E2, AC-E9, AC-E13 y AC-E14, Interactions y Dependencies (4 y 21), D13 a D17. **Cambia reglas: pendiente de re-review.**

- **2026-11-09 (ronda 4, aplica `gdd-cross-review-2026-11-09-r2.md`):** regla 6 (operación «pedir `exploración`» del dueño vigente, también el 21; cierre normal del 21 restaura `menú`; tabla de pila por origen), AC-E13b, F8 y rango seguro del tope 3–5 s (B-4), Open Question 3 remitida a 7/9, lista de bidireccionalidad actualizada (N-W2). Ver D18 a D20.
- **2026-11-09 (ronda 5, `gdd-cross-review-2026-11-09-r3.md`):** E-1: regla 6 (cierre normal del 21) y AC-E13b reescritos; D21.
- **2026-11-09 (ronda de propagación 1, lote Feature 1: 8, 10, 19, 20, 21):** regla 6 (propuesta «absorber el `sin control` ajeno», fila de pila, AC-E13c), Dependencies de 19 y 21, F8 y rango del tope (`BOX_OPEN_MAX`), Open Questions 1 y 12 cerradas, 16 y 17 nuevas; D22 a D26. **Cambia reglas (propuesta): pendiente de re-review.**
- **2026-11-09 (ronda de decisiones 1):** D-A aprobada por el usuario: `atrás` corta en `exploración` activa `repasar_bolsillo` (reglas 1, 7, 8 y nueva 23, tablas de contextos, acciones, interacciones y dependencias, edge cases, AC-E15 a AC-E17; Open Question 16 cerrada; D26 sustituida por D27). La propuesta «absorber el `sin control` ajeno» (OQ 17, D22) sigue pendiente. **Cambia reglas: pendiente de re-review.**
- **2026-11-09 (ronda de corrección 2, `gdd-cross-review-2026-11-09-r5.md`):** E4-1 (regla 6: operación general y firme «descartar la pila al aceptar una carga nueva», aviso «`sin control` absorbido», tabla de pila con las formas [`menú`, `sin control`(21), `menú`] y [`sin control`(21), `menú`]; AC-E13c firme; D22 pasa de propuesta a decisión; Open Question 17 cerrada), W-3 y W-4 (Dependencies: 19 y 21 Dura, 20 Blanda, fila de 10), W-7 (sin GDD obsoleto); D28 y D29. **Cambia reglas: pendiente de re-review.**
