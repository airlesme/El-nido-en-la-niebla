# Documentos y bolsillo

> **Estado:** Borrador (lote Feature 1) — pendiente de review
> **Sistema:** 20 del índice (`design/gdd/systems-index.md`) · Categoría: Narrative · Prioridad: MVP
> **Autor:** game-designer (lote autónomo, 2026-11-09)
> **Fuente de verdad del slice:** `design/slice/slice-v0.3.md` (D.1 ítems, D.2 banderas, A.4/A.5/A.6 objetos, C.3/C.6 escenas)
> **Pilares que mandan:** Tensión sin castigo (1.º), Información incompleta (2.º), Autonomía como progresión (3.º)

---

## Summary

El sistema 20 es el **dueño de lo que Vera lleva encima y de cómo se lee**. Tiene tres funciones: (1) **dibujar y gestionar la pantalla de lectura** de todos los documentos del slice (formulario, memorando, notas, lista de tareas, carta, libro de visitas), a partir de las claves y estilos de la base de contenido (18); (2) ser el **dueño de los hechos** `formulario_leido`, `tarjeta_B` y `tarjeta_D` y de la pregunta `has_item(id)`; (3) presentar el **bolsillo visual**: el gesto breve de «sacar y guardar» tarjetas, y una relectura sin menú. El bolsillo **no guarda estado propio**: es una *vista derivada de los hechos* (salvo `I-01`, que es de sesión). Por eso no puede perderse nada, ni al cargar ni al fallar un gesto.

## Overview

El slice (D.1) declara siete ítems y una regla: «Vera lleva los ítems en un bolsillo visual. No hay menú de inventario». Este GDD la convierte en reglas.

Hay tres clases de ítem. **Llave** (`I-02`, `I-03`: las tarjetas): se obtienen al abrir el cajón `A05`, se muestran en la mano un instante y se usan en los lectores `C06`/`C07` (sistema 8). **Documento** (`I-04` formulario, `I-05` lista de tareas, `I-06a` nota, `I-07` carta): se leen en pantalla y se pueden releer. **Material** (`I-01`, la impresión de correos): lo necesita el puzle 1 (`needs_items`) y **no se conserva entre sesiones** (marco 9, D9-33). `I-06b` (la nota bajo la lámpara, `B05`) **no es ítem**: se lee en el sitio.

La decisión estructural es que **ningún ítem tiene almacenamiento propio**. `has_item(id)` es una función de los hechos del estado (3): `tarjeta_B` ⇔ `I-02`, `tarjeta_D` ⇔ `I-03`, `formulario_leido` ⇔ `I-04`, `caja_c1` ⇔ `I-06a`, `caja_c2` ⇔ `I-05`, `caja_c4` ⇔ `I-07`. Guardar y cargar (5) ya persiste esos hechos, de modo que el bolsillo se reconstruye solo. La presentación (la tarjeta en la mano, la pantalla de lectura) es siempre **posterior** al hecho y **nunca lo condiciona**: si un gesto se cancela, el ítem ya está en el bolsillo.

Para releer sin menú, el slice no define ningún mando. Este GDD propone (decisión por defecto, Pregunta abierta Q1) que `atrás` en `exploración` «repase el bolsillo»: abre la lectura del siguiente documento relegible, de uno en uno, sin pantalla de selección.

## Player Fantasy

Vera es una mujer cansada que trabaja de noche: busca en cajones, saca papeles, los guarda en el bolsillo del abrigo. El jugador debe sentir **manos de oficinista, no de aventurero**: nada brilla, no hay iconos, no suena una fanfarria de «objeto obtenido». Coger la tarjeta es un gesto pequeño y creíble; leer un papel es mirarlo de cerca, con la lluvia de fondo. Dos sentimientos concretos:

- **Seguridad de archivo** (Competence, Narrative): «lo que he encontrado sigue conmigo». Puedo volver sobre la carta que escribí cuando quiera, sin que el juego me lo reproche ni me ponga a prueba.
- **Papeles que se contradicen** (Discovery, *Información incompleta*): el sistema muestra los textos tal cual y nunca resalta, resume ni ordena por importancia. Comparar es trabajo del jugador (Autonomía como progresión).

Aesthetic principal: **Discovery** y **Narrative**; secundario, Sensation (el gesto de manos).

---

## Detailed Rules

### A. Qué es un ítem y un documento

**R1. Catálogo cerrado de ítems.** Existen exactamente siete ítems en el slice, definidos en `assets/data/items/items.json`. Ninguno se crea en ejecución.

| ID | Nombre | Clase | `has_item` ≡ | Persistente | Relegible (repaso) | Origen |
|---|---|---|---|---|---|---|
| `I-01` | Impresión de correos | material | conjunto de sesión (R9) | **No** | No | `V08` (19) |
| `I-02` | Tarjeta de la Sala de Reuniones | llave | `tarjeta_B` | Sí (hecho) | No | `A05` |
| `I-03` | Tarjeta sin foto | llave | `tarjeta_D` | Sí (hecho) | No | `A05` |
| `I-04` | Formulario de traslado | documento | `formulario_leido` | Sí (hecho) | Sí | `A04` |
| `I-05` | Lista de tareas del Guardián | documento | `caja_c2` | Sí (hecho de 9) | Sí | `D01b` (P4) |
| `I-06a` | Nota «La transición es tuya» | documento | `caja_c1` | Sí (hecho de 9) | Sí | `D01a` (P3) |
| `I-07` | Carta de Vera | documento | `caja_c4` | Sí (hecho de 9) | Sí | `D01d` (P6) |

`I-06b` no está en el catálogo (el slice D.1: «No es ítem»). Un ID fuera del catálogo hace que `has_item` devuelva falso y registre una línea (en desarrollo, error visible).

**R2. Qué es un documento.** Un documento es una entrada de la base de contenido (18, regla 1: tipo *documento*) con clave, uno o más fragmentos ordenados (18, regla 10) y un **estilo de presentación** (`impreso`, `manuscrito_vera`, `manuscrito_guardian`, `cristal_espejo`, `pantalla`, `libro`). Este sistema **dibuja** cualquier documento que 7 le entregue (7, regla 16), sea un ítem del bolsillo o un objeto de escena (`A04`, `B05`, `DOC_01`, `R01`). Para los ítems documento, `items.json` fija la correspondencia ítem → documento:

| Ítem | Contenido que se dibuja | Estilo |
|---|---|---|
| `I-04` | Formulario del Anexo A.4 (clave por asignar en 18, ver «Cambios requeridos») | `impreso` |
| `I-05` | Lista de tareas con el nombre de Vera tachado y reemplazado por «G» (fichas T1–T4 tal como quedaron, 18 regla 1) | `manuscrito_guardian` |
| `I-06a` | `NOTA_01` | `manuscrito_guardian` |
| `I-07` | Dos fragmentos en orden: `CARTA_<carta_variante>` y `CARTA_CUERPO` | `manuscrito_vera` |

El estilo concreto de `NOTA_01`/lista de tareas lo confirma el arte (18 es el dueño del campo); aquí solo se exige que el estilo salga del catálogo, nunca del código.

**R3. El texto no se toca.** Este sistema no edita, resume, resalta, ordena por importancia ni anota ningún texto. Dibuja lo que 18 entrega, con los marcadores de nombre resueltos por 18. No hay «diario», «ficha de personaje» ni cronología automática (*Información incompleta*: la comparación es del jugador).

### B. Capacidad y organización del bolsillo

**R4. Capacidad.** El bolsillo no tiene límite que el jugador pueda alcanzar: el catálogo (R1) lo acota a 7. No hay peso, no hay descartar, no hay soltar, no hay combinar, no hay «usar con». El jugador **no puede perder ni tirar** un ítem (*Tensión sin castigo*).

**R5. Sin almacenamiento propio.** El bolsillo es la función `has_item(id)` de la R1. No existe una lista de ítems escrita. Consecuencias: (a) guardar, cargar y reiniciar no requieren campos nuevos; (b) un ítem solo existe si existe su hecho; (c) no se puede dar un ítem sin escribir su hecho, ni quitarlo sin una consola de desarrollo (3, regla 15).

**R6. Organización.** No hay pantalla de inventario ni HUD de ítems (slice D.1; pilar *El espacio expresa la emoción*: ningún indicador). El único orden es el **orden de repaso** (R22), fijo en datos: `I-07`, `I-05`, `I-06a`, `I-04`. Las llaves y el material no se repasan.

### C. Cómo se adquieren

**R7. Principio: hecho primero, gesto después.** Toda adquisición escribe el hecho correspondiente **antes** de mostrar nada. La presentación (R12) no condiciona el hecho, ni el avance, ni el guardado. Si se cancela, se rechaza o no ocurre, el ítem está igualmente en el bolsillo.

**R8. Cómo llega cada ítem.**

| Ítem | Disparo | Qué hace 20 |
|---|---|---|
| `I-04` | El aviso «lectura completada» (7, regla 18) con el ID del documento `A04` (≥ `lectura_min_s` = 2 s). | Escribe `formulario_leido` = verdadero (hecho propio). Si ya era verdadero, no pasa nada (3, regla 4 y 9). `A04` **permanece** en la caja y sigue siendo legible en el sitio; `I-04` es la copia que lleva Vera. |
| `I-02`, `I-03` | 8 llama a `otorgar("A05")` cuando el cajón `A05` ha terminado de abrirse (tras el `gesto_terminado` de `HAND_DRAWER`, cualquier `motivo`). | Escribe `tarjeta_B` y luego `tarjeta_D` (en ese orden) y lanza la presentación R12 de las que **acaban** de pasar a verdadero. Idempotente: si ambas ya son verdaderas, no escribe ni presenta nada. |
| `I-06a`, `I-05`, `I-07` | Cambio de `caja_c1`, `caja_c2`, `caja_c4` a verdadero (aviso automático de cambio de hecho, 3 regla 9). | **No escribe nada** (los hechos son de 9). Solo se hace derivable `has_item`. La primera aparición en pantalla de estas recompensas (nota en la bandeja, lista, carta) es de 9 y 10; 20 solo garantiza que luego están en el bolsillo y se pueden releer. |
| `I-01` | 19 llama a `otorgar_sesion("I-01")` al terminar la impresión de `V08` (requiere `correos_leidos`, lo comprueba 19). | Añade `I-01` al conjunto de sesión (R9). Repetible: añadir un ítem ya presente no hace nada. |

**R9. Conjunto de sesión.** Solo `I-01` es de sesión: se guarda en memoria, **no se persiste**, y se vacía al descargar la escena de planta, al empezar una partida nueva y al cargar. Tras cargar, `has_item("I-01")` es falso aunque `correos_leidos` sea verdadero (9, regla 34 y AC-39b); el jugador vuelve a imprimir en `V08` (repetible e ilimitado, D9-33).

**R10. Escritura de hechos.** El dueño de `formulario_leido`, `tarjeta_B` y `tarjeta_D` es 20 (3, regla 2; fila 20 del índice). Los tres son de un solo sentido (3, regla 4): una vez verdaderos no se deshacen, ni siquiera al «usar» la llave (R16).

### D. Cómo se sostienen

**R11. Sostener solo tras un gesto terminado.** 20 pide `sostener(item_id, izquierda)` al Jugador (2, regla 24) **únicamente** cuando no hay gesto bloqueante en curso: tras el `gesto_terminado` de `HAND_DRAWER` (adquisición) o antes de que 8 pida el gesto de pasar la tarjeta (uso, R16). Si el Jugador rechaza `sostener` (otro bloqueante, otro objeto sujeto, `reposo()`), 20 **no lo reintenta**, registra y sigue (R7: el ítem ya es del jugador). Los ítems y la caja `A03` **no** son sostenibles de escena (7, regla 13: la única lista de sostenibles de escena es `V05`; D7-29): los ítems del bolsillo son sostenibles **propios** del 20, no entran en esa lista.

**R12. Presentación de adquisición (solo tarjetas).** Tras R8 para `I-02`/`I-03`, y solo para las que acaban de pasar a verdadero, 20 ejecuta en serie por tarjeta: `sostener(id, izquierda)` → espera `objeto_sujeto(id)` (fundido `t_item_dentro`, 0,3 s, tuning de 2) → mantiene `t_mostrar_item_s` → `soltar()` → espera `objeto_soltado(id)` (`t_item_fuera`, 0,3 s). No bloquea el contexto: el jugador puede moverse, mirar o activar otro objeto. Si llega `reposo()`, una `lectura`, una `inspección`, un modo abierto o una escena con `sin control`, la presentación se **aborta** (F1) y el ítem sigue en el bolsillo. No hay sonido de «recompensa»: solo el foley de papel/plástico del Jugador/23. Nada aparece en pantalla (sin icono ni texto de «obtenido»).

**R13. Documentos: sin presentación de adquisición propia.** `I-04` se «obtiene» al terminar de leer el formulario, que ya está en pantalla: no hay segundo gesto. `I-05`, `I-06a` e `I-07` los muestra 9/10 (nota, lista, carta; slice C.6). 20 no añade animación.

### E. Cómo se leen

**R14. Lectura de objetos de escena.** Cuando 7 entra en `lectura` (7, regla 16) para un documento cuyo dueño es 20 (`A04`, `B05`, o los que 12/16/etc. deleguen), entrega clave y estilo; 20 dibuja la pantalla de lectura. La lectura se cierra con `atrás` (7); 20 recibe «lectura cerrada» (7, regla 29) y libera la pantalla. Un documento de varias páginas (`R01`, dos páginas) usa `interactuar` para pasar (7, regla 17); 20 muestra la página que 7 indica y no tiene estado de página propio.

**R15. `A03` y `A04`.** `A03` (caja del traslado) es `DELEGAR` a 20 (7, tabla de objetos). Estados: `cerrada` → `abierta`. `can_interact` de `A03` es `NO` si ya está `abierta`. `interact()` (tras `HAND_REACH` del Jugador) pasa a `abierta` en el mismo paso y reproduce la animación de la tapa `t_tapa_s` (no bloquea, solo visual). `A04` está habilitado (`can_interact` `LEER`) **solo** con `A03` `abierta` (7). El estado de `A03` **no se guarda**: al cargar, `A03` se reconstruye `abierta` si `formulario_leido` es verdadero y `cerrada` si no (R5, 5 y 3 no necesitan campo nuevo).

**R16. Uso de una llave (tarjeta) y por qué no se consume.** Cuando 8 va a usar `I-02` en `C06` (o `I-03` en `C07`) llama a `sostener_item(id)`: 20 pide `sostener(id, izquierda)` (R11) y devuelve `ACEPTADA` o `RECHAZADA(motivo)`. Tras `objeto_sujeto(id)` 8 pide su gesto (`HAND_CARD_SWIPE`, 2) y, al terminar, llama a `guardar_item()`: 20 pide `soltar()`. **Ninguna llave se consume.** El hecho `tarjeta_B`/`tarjeta_D` queda verdadero y `has_item` sigue verdadero tras abrir la puerta. El slice dice «llave de B/D», no «de un solo uso», y 8 reconstruye las puertas cerradas al cargar (índice, notas de la ronda 2): la llave tiene que seguir en el bolsillo para volver a abrir sin penalización. Si `sostener_item` es `RECHAZADA`, 8 puede pasar la tarjeta igualmente sin mostrarla: el rechazo solo afecta a la presentación (R7).

**R17. Hechos de lectura.** El único hecho que escribe una lectura es `formulario_leido` (R8). Leer cualquier otro documento (incluida la carta) no escribe nada. Releer no cambia ningún hecho.

### F. Relectura (repaso del bolsillo)

**R18. Acción.** Se añade una acción derivada: `atrás` (pulsación corta) en `exploración` estable lanza `repasar_bolsillo()`. Es una propuesta del lote, **pendiente de Pregunta abierta Q1** y de un cambio en Entrada (1): hoy `atrás` no está activa en `exploración`. El `atrás` que **cierra** un modo (lectura, inspección, vista) no cuenta: la pulsación debe empezar con el contexto ya en `exploración` (Entrada, tabla de contextos).

**R19. Qué hace `repasar_bolsillo()`.** Calcula la lista de documentos relegibles presentes: los ítems de la R1 con «Relegible = Sí» y `has_item` verdadero, ordenados según R6. Si está vacía, no hace nada (sin sonido, sin mensaje). Si no, elige el siguiente según F2 y llama a `abrir_lectura(<item_id>)` a 7 (7, regla 27b).

**R20. Resultados de `abrir_lectura`.**
- `ACEPTADA`: 7 abre la `lectura` con `HAND_READ`. El cursor de repaso avanza (F2).
- `APLAZADA`: 20 no hace nada más; 7 la abrirá al volver el control o la descartará a los 3 s (7, regla 27b: «lectura descartada»). El cursor **no** avanza hasta que 7 emita «lectura abierta» (ID del documento).
- `RECHAZADA(motivo)`: 20 no hace nada, registra y deja el cursor. Ocurre con `inspección`, `ordenador`, `llamada`, otra lectura abierta o **ya hay una petición aplazada** (por ejemplo, la carta del P6 pendiente tras salir de la vista: no se apila una segunda). Sin mensaje al jugador: pulsar de nuevo cuesta nada.

**R21. La relectura no tiene coste.** No hay límite de aperturas, ni temporizador, ni contador. La relectura no altera `lectura_min_s`: solo `A04` lo tiene y solo en su lectura de escena.

**R22. Orden de repaso.** El primer repaso de la sesión empieza por el último de la lista (`I-07` si está). Cada apertura aceptada avanza al siguiente de la lista y, tras el último, vuelve al primero (F2). El cursor es de sesión y no se guarda. Con un solo documento relegible, `atrás` lo reabre siempre.

**R23. Pista de control.** La primera vez que algún documento relegible entra en el bolsillo, 20 pide una vez a 24 un pie no bloqueante (clave `UI_BOLSILLO_AYUDA`, ver cambios en 18: «Atrás: revisar los papeles»). Se muestra como un pie de 7 (regla 12): no es información necesaria para avanzar; la persistencia de «ya mostrado» es de sesión (si se vuelve a ver tras cargar, es inocuo).

### G. Persistencia y propiedad

**R24. Qué se guarda.** Nada propio. Se guardan los hechos que ya existen: `formulario_leido`, `tarjeta_B`, `tarjeta_D` (de 20) y `caja_c1`, `caja_c2`, `caja_c4`, `carta_variante` (de 9). Guardado (5, regla 14) ya tiene la causa `card_acquired:<id>` para el cambio de `tarjeta_B`/`tarjeta_D`. `formulario_leido` no tiene causa propia: se guarda por `periodic` o por la siguiente causa (coste: como mucho 2 s de relectura del formulario, ver Edge Cases).

**R25. Quién es dueño de qué.**

| Dato | Dueño (escribe) | Lee |
|---|---|---|
| `formulario_leido`, `tarjeta_B`, `tarjeta_D` | **20** | 8 (puertas), 17 (pistas), 7 (`habilitado_si`) |
| `caja_c1`, `caja_c2`, `caja_c4`, `carta_variante` | 9 | 20 (deriva `has_item`, elige la carta) |
| conjunto de sesión (`I-01`) | **20** (lo rellena 19) | 9 (`needs_items`, `has_item`) |
| texto y estilo de documentos | 18 | 20 (dibuja) |
| gestos y objeto sujeto | 2 | 20 (pide), 7/8 (esperan) |
| estado de `A03` | 20 (se reconstruye) | 7 |

**R26. Restauración y descarga.** Al restaurar (3, regla 13) 20 no hace nada: `has_item` ya devuelve el valor correcto porque los hechos están restaurados. Al descargar la escena (4), 20 cancela cualquier presentación, cierra la pantalla de lectura sin avisos al bus (7, regla 27a, descarga) y vacía el conjunto de sesión (R9).

**R27. Sin medidores ni moral.** Ningún ítem lleva valor, relevancia ni «importancia». La carta se guarda con su variante (A/B/C) por contenido; el sistema no la clasifica (pilar *Ambivalencia sin moral binaria*; Engineering: ningún flag representa moralidad).

---

## Formulas

**F1 · Duración de la presentación de adquisición (R12).**
`t_pres = Σ_{i=1..n} (t_item_dentro + t_mostrar_item_s + t_item_fuera)`, con `n` ∈ {0, 1, 2} (tarjetas recién adquiridas).
Variables: `t_item_dentro` = `t_item_fuera` = 0,3 s (2, tuning, rango 0,15–0,6); `t_mostrar_item_s` = 0,7 s† (rango 0,4–1,5).
Ejemplo (valores por defecto, `n` = 2): `2 × (0,3 + 0,7 + 0,3)` = **2,6 s**. Con `n` = 1: 1,3 s. Con `n` = 0: 0 s.
Aborto: si en cualquier instante se cumple una condición de la R12, se corta y la duración efectiva es el tiempo transcurrido; el ítem no se pierde.

**F2 · Cursor de repaso (R19, R22).**
Sea `L` la lista ordenada de relegibles presentes (longitud `m` ≥ 0) en orden `I-07, I-05, I-06a, I-04` filtrado por `has_item`. Sea `c` el cursor de sesión, con valor inicial «ninguno».
`i_siguiente = 0` si `c` es ninguno o `c` ya no está en `L`; si no, `i_siguiente = (posición(c, L) + 1) mod m`.
Tras `ACEPTADA` (o «lectura abierta» tras `APLAZADA`): `c = L[i_siguiente]`. Con `m` = 0 no se hace nada.
Ejemplo: `L = [I-07, I-05, I-04]`. Pulsaciones sucesivas abren `I-07`, `I-05`, `I-04`, `I-07`. Si entre medias se obtiene `I-06a`, `L = [I-07, I-05, I-06a, I-04]` y, estando `c = I-05`, la siguiente abre `I-06a`.
Rango de salida: 0 ≤ `i_siguiente` ≤ 3. Peor caso para llegar a un documento dado: `m − 1` = 3 pulsaciones adicionales (< 10 s con la lectura intercalada).

**F3 · Equivalencia `has_item` (R1).** `has_item(id)` = hecho del estado de la R1 para `I-02..I-07`; `id ∈ sesión` para `I-01`; falso en otro caso. Sin parámetros numéricos.

---

## Edge Cases

- **Se cierra el juego tras leer el formulario y antes de cualquier causa de guardado.** `formulario_leido` se pierde a lo sumo `t_periodico` (120 s, 5). Al cargar, `A03` está `cerrada` y `I-04` no está; el jugador la abre y lee otros 2 s. Sin coste (*Tensión sin castigo*). Si ya había cogido las tarjetas, `card_acquired` guarda también `formulario_leido`.
- **Se cierra el juego con las tarjetas ya cogidas.** `tarjeta_B` y `tarjeta_D` están guardadas (`card_acquired`, 5). Al cargar, las puertas B y D están cerradas (8) y el jugador usa de nuevo la tarjeta (R16). `A05` se encuentra vacío: `otorgar("A05")` es idempotente y no presenta nada (R8).
- **`A05` se abre pero la presentación se cancela** (`reposo()`, `cerrar_modos()`, el jugador abre una lectura): los dos hechos ya están escritos (R7); sin tarjeta en la mano, pero con ambas en el bolsillo.
- **`sostener` rechazado** (otro bloqueante o un objeto sujeto): no se reintenta (R11); el uso de la llave sigue funcionando sin mostrarla (R16).
- **El jugador abre `A05` con `lectura` o `inspección` de otra cosa en curso.** Imposible: son modos de 7 y `A05` es un `DELEGAR` en `exploración`.
- **`A04` se lee menos de 2 s.** No hay «lectura completada» (7, AC-24): `formulario_leido` sigue falso. Se puede releer sin coste.
- **`A04` se relee con `formulario_leido` verdadero.** El aviso se emite de nuevo; la escritura de 20 es el mismo valor: no hay aviso de cambio ni nuevo guardado (3, regla 9).
- **`atrás` en `exploración` sin documentos relegibles.** No pasa nada. No hay aviso de «no tienes nada».
- **`atrás` pulsado mientras hay una petición aplazada** (la carta del P6 mientras 7 termina la salida de la vista): `RECHAZADA` (7, E2-1). El cursor no avanza. Cuando la carta se abre sola (D7-32) y se cierra con `atrás`, ese `atrás` no cuenta como repaso (R18).
- **La carta del P6 y el repaso a la vez.** `I-07` es `caja_c4`: está en el bolsillo desde el instante en que el hecho es verdadero, aunque la lectura inicial de 9 se aplace. El jugador puede releerla desde que 7 acepte una lectura.
- **Dos tarjetas y `carta_variante` ausente.** Si `caja_c4` es verdadero y `carta_variante` no está fijada (estado imposible salvo consola): `I-07` se dibuja con `CARTA_CUERPO` solo y se registra un error en desarrollo; en la build final no se oculta el ítem.
- **Un documento sin texto en 18 (clave ausente).** 18 devuelve «no encontrado»; 20 muestra el texto de emergencia de 18 (regla 21 de 18) y registra. No se bloquea la lectura ni se cierra el modo.
- **Texto muy largo** (carta y cuerpo en un solo viewport): la pantalla de lectura ajusta el tamaño a la página; si no cabe, divide en páginas con `interactuar`, nunca recorta. Hoy ningún documento del slice (≤ 90 palabras la carta) lo necesita.
- **Pausa durante una presentación o una lectura.** El tiempo de juego se detiene (7, regla 28); la presentación reanuda; `lectura_min_s` no avanza en pausa.
- **Escena con `sin control` (21) a mitad de presentación.** La presentación se aborta; el ítem queda en el bolsillo.
- **Descarga total (vuelta al título).** El conjunto de sesión se vacía; los hechos se rehacen desde la carga (3, regla 12).
- **Degenerado: spam de `atrás` en `exploración`.** Cada `ACEPTADA` abre una lectura que `atrás` cierra; el ciclo es seguro y sin coste. No hay recompensa por hacerlo (sin logro, sin contador).
- **Degenerado: coger las tarjetas antes de resolver P1.** No aplica: `A05` está tras la puerta A (`archivo_abierto`).
- **Degenerado: forzar `tarjeta_B` por consola.** Permitido solo en desarrollo (3, regla 15); `has_item` y las puertas responden al instante.

---

## Dependencies

| Sistema | Tipo | Qué da 20 | Qué recibe 20 |
|---|---|---|---|
| 3 Estado y bus | Dura | Escribe `formulario_leido`, `tarjeta_B`, `tarjeta_D` (reglas 1, 2, 4) | Lee hechos (reglas 3, 9); no emite avisos propios (ver cambios: «ítem obtenido» opcional, no incluido) |
| 7 Interacción e inspección | Dura | Dibuja la pantalla de `lectura` (regla 16); maneja `A03` (tabla de objetos); llama a `abrir_lectura` (regla 27b) | Clave y estilo del documento; «lectura completada» (regla 18), «lectura abierta/cerrada/descartada» (regla 29); `A03` DELEGAR |
| 18 Contenido narrativo | Dura | Muestra documentos con su estilo (regla 1) | Textos y fragmentos (regla 10), marcadores de nombre, texto de emergencia (regla 21) |
| 2 Jugador | Blanda | `sostener(id, izquierda)` y `soltar()` (regla 24), tras `gesto_terminado` | `objeto_sujeto`, `objeto_soltado`, `gesto_terminado`; `t_item_dentro/fuera` |
| 9 Marco de puzles | Blanda (‡) | `has_item(id)` para `needs_items` (regla 34); deriva `I-05`, `I-06a`, `I-07` de sus hechos | `abrir_lectura(I-07)` al resolver P6 (regla 16 de 9, paso final) y en la reapertura (regla 35: `on_reopen`); los hechos `caja_c1..c4` y `carta_variante`; AC-39, AC-39b |
| 8 Control de acceso (sin GDD) | Dura (de 8 hacia 20) | `sostener_item(id)`, `guardar_item()`, `otorgar("A05")` | Llama a esos tres puntos; lee `tarjeta_B/D` |
| 19 Ordenador (sin GDD) | Dura (de 19 hacia 20) | `otorgar_sesion("I-01")`, `has_item("I-01")` | Llama tras la impresión de `V08` |
| 17 Pistas (sin GDD) | Blanda | `formulario_leido` | Lee el hecho |
| 1 Entrada | Blanda | Acción derivada `atrás` en `exploración` (R18) | Hoy no existe (ver cambios) |
| 5 Guardado | Indirecta | — | Persiste los hechos; causa `card_acquired` (regla 14, AC-04b) |
| 24 Prompt | Blanda | Pie `UI_BOLSILLO_AYUDA` (R23) | Dibuja el pie |
| 4 Escena de planta | Indirecta | Libera sesión en la descarga (R26) | Descarga |
| 21 Director de escenas | Indirecta | — | `cerrar_modos()` cierra la lectura (7, regla 27a) |

Contrato recíproco con 7: la fila 20 de las interacciones de 7 («Documento a mostrar, estilo, aviso lectura completada» / «Dibujo de la pantalla; `abrir_lectura`») coincide con las reglas R14 y R19–R20. Con 2: la nota de la regla 24 («20 pide `sostener` solo tras `gesto_terminado`») es R11. Con 9: `has_item` (regla 34) y `rewards` (regla 16, los ítems no son hechos propios) son R5 y R8.

---

## Tuning Knobs

| Perilla | Defecto | Rango seguro | Categoría | Razón |
|---|---|---|---|---|
| `t_mostrar_item_s` | 0,7 s† | 0,4–1,5 | Feel | Tiempo con la tarjeta visible. Menos de 0,4 no se lee; más de 1,5 con dos tarjetas supera 4 s de presentación sin control |
| `t_tapa_s` (animación de `A03`) | 0,6 s† | 0,3–1,0 | Feel | Visual, no bloquea |
| `repaso_orden` | `I-07, I-05, I-06a, I-04` | Cualquier permutación | Curve | Prioriza lo que se necesita para la llamada (carta) |
| `repaso_cerrar_ciclo` | `true` | `true`/`false` | Feel | Vuelve al primero tras el último; con `false` se detiene en el último |
| `aplazada_tope_s` | 3 s (de 7) | no es de 20 | Gate | Solo referencia: lo posee 7 (regla 27b) |
| `lectura_min_s` de `A04` | 2 s† (de 7) | no es de 20 | Gate | Solo referencia: lo posee 7 (regla 18) |
| `mostrar_pista_bolsillo` | `true` | `true`/`false` | Feel | Pie de ayuda de R23 |

Los valores viven en `assets/data/items/items.json` y `assets/data/items/inventory_config.json`. † = valor inicial sin playtest.

---

## Acceptance Criteria

Tipos: **L** lógica (prueba unitaria), **I** integración, **PV** playtest/visual (captura retenida en `production/qa/evidence/`).

- **AC-01 (R1, L)**: **GIVEN** el catálogo, **WHEN** se piden los 7 IDs y `I-06b`, **THEN** los siete existen con su clase y `I-06b` devuelve falso con una línea de registro.
- **AC-02 (R5, F3, L)**: **GIVEN** una partida con `tarjeta_B` verdadero, **THEN** `has_item("I-02")` es verdadero y `has_item("I-03")` falso; **WHEN** se restaura una instantánea con `caja_c1`, `caja_c2` y `caja_c4` verdaderos, **THEN** `has_item` es verdadero para `I-06a`, `I-05` e `I-07` sin llamar a ninguna función de 20.
- **AC-03 (R8, R10, L)**: **GIVEN** «lectura completada» de `A04`, **THEN** `formulario_leido` pasa a verdadero una vez; **WHEN** llega de nuevo, **THEN** no hay aviso de cambio (3, CA-03 análogo).
- **AC-04 (R8, L)**: **GIVEN** `otorgar("A05")` con ambas tarjetas falsas, **THEN** `tarjeta_B` y luego `tarjeta_D` son verdaderas; **WHEN** se llama otra vez, **THEN** no hay escritura ni presentación.
- **AC-05 (R9, L + I)**: **GIVEN** `otorgar_sesion("I-01")`, **WHEN** se carga la partida, **THEN** `has_item("I-01")` es falso; **WHEN** se imprime otra vez, **THEN** es verdadero y P1 es resoluble (9, AC-39b).
- **AC-06 (R7, R12, F1, I)**: **GIVEN** `A05` abierto, **WHEN** se llama a `otorgar`, **THEN** se presenta `I-02` y luego `I-03` en 2,6 s con los valores por defecto sin bloquear el contexto; **WHEN** se llama a `reposo()` en t = 1,0 s, **THEN** la presentación se aborta y `has_item` de ambas sigue verdadero.
- **AC-07 (R11, I)**: **GIVEN** un gesto bloqueante en curso, **WHEN** 20 pide `sostener`, **THEN** el Jugador lo rechaza, 20 registra y no reintenta; el hecho no cambia.
- **AC-08 (R16, I)**: **GIVEN** `tarjeta_B` verdadero, **WHEN** 8 usa `I-02` (sostener → gesto → guardar), **THEN** `has_item("I-02")` sigue verdadero; **WHEN** se carga la partida, **THEN** la puerta B está cerrada y la tarjeta la abre de nuevo.
- **AC-09 (R15, I)**: **GIVEN** `A03` cerrada, **THEN** `A04` no está habilitado; **WHEN** se abre `A03`, **THEN** `A04` es legible; **WHEN** se carga con `formulario_leido` verdadero, **THEN** `A03` está abierta.
- **AC-10 (R14, I)**: **GIVEN** `A04`, **WHEN** se lee 1,9 s y se cierra, **THEN** `formulario_leido` sigue falso; **WHEN** se lee 2,0 s, **THEN** es verdadero.
- **AC-11 (R19, R22, F2, L)**: **GIVEN** `I-07`, `I-05` e `I-04` presentes, **WHEN** se llama cuatro veces a `repasar_bolsillo()` con `ACEPTADA`, **THEN** abre `I-07`, `I-05`, `I-04`, `I-07`; **GIVEN** ninguno, **THEN** no hace nada.
- **AC-12 (R20, I)**: **GIVEN** una petición de 9 aplazada (carta del P6), **WHEN** el jugador pulsa `atrás` en `exploración`, **THEN** `abrir_lectura` devuelve `RECHAZADA` y el cursor no avanza; **WHEN** 7 devuelve `APLAZADA`, **THEN** 20 espera «lectura abierta» y no repite la petición.
- **AC-13 (R2, R14, L)**: **GIVEN** `carta_variante` = B, **WHEN** se lee `I-07`, **THEN** muestra `CARTA_B` y después `CARTA_CUERPO` con estilo `manuscrito_vera` y los textos exactos de 18.
- **AC-14 (R18, I)**: **GIVEN** una lectura abierta, **WHEN** se cierra con `atrás`, **THEN** no se lanza un segundo repaso con la misma pulsación.
- **AC-15 (R26, I)**: **GIVEN** una presentación en curso, **WHEN** se descarga la escena, **THEN** se cancela sin avisos al bus y el conjunto de sesión queda vacío.
- **AC-16 (R3, R27, PV)**: **GIVEN** un playtest con cinco jugadores, **THEN** ninguno recibe un indicador de «importancia» o «bueno/malo» sobre un documento, y al menos cuatro releen la carta o la lista sin ayuda externa o la consideran accesible al preguntarles.
- **AC-17 (R12, PV)**: **GIVEN** la presentación de las tarjetas, **THEN** la captura retenida muestra la tarjeta en la mano izquierda, sin icono ni texto; el equipo la considera creíble («un gesto de oficina», no «un objeto de aventura»).
- **AC-18 (R23, PV)**: **GIVEN** que se obtiene el primer documento relegible, **THEN** aparece el pie `UI_BOLSILLO_AYUDA` una sola vez y no vuelve a salir en la sesión.

---

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D20-1 | El bolsillo no tiene almacenamiento propio: `has_item` deriva de los hechos (R5). | Lista de ítems guardada en la instantánea. | Una sola fuente de verdad (3); sin campos nuevos en 5; imposible desincronizar ítem y hecho; cumple *Tensión sin castigo*. |
| D20-2 | Hecho primero, presentación después, sin reintentos (R7, R11). | Condicionar el ítem a que termine el gesto. | Un gesto cancelado (`reposo()`, escena 21) no puede quitar una llave del camino crítico. |
| D20-3 | Ninguna llave se consume (R16). | Consumir la tarjeta al usarla («un solo uso»). | El slice dice «llave», 8 reconstruye puertas cerradas al cargar; consumirla produciría un softlock tras cargar. |
| D20-4 | Los ítems del bolsillo son sostenibles **propios** del 20, fuera de la lista de 7. | Añadirlos a la lista de sostenibles de escena. | 7 (regla 13) y su D7-29 fijan que solo `V05` es sostenible de escena. |
| D20-5 | Solo las tarjetas se presentan al obtenerse; los documentos los presentan 9/10. | Animación de adquisición para todos. | Evita duplicar la animación de recompensas de 9/10 y el fanfarreo («sin recompensas visibles»). |
| D20-6 | `I-04` se añade al terminar de leer `A04`, y `A04` permanece en la caja. | Retirar `A04` de la escena al leerlo. | Nada se quita al jugador; sigue legible en el sitio y la copia está en el bolsillo. |
| D20-7 | `I-01` es un material de sesión (R9). | Persistirlo. | Decisión de 9 (D9-33): evita saltar la impresión y la pista de `V08`. |
| D20-8 | Relectura con `atrás` corta en `exploración` y ciclo de un documento por pulsación (R18–R22). | (a) Menú de inventario. (b) Sin relectura (solo objetos de escena). (c) `interactuar` mantenida sin objetivo. | (a) contradice D.1 del slice. (b) la carta no tiene objeto de escena y 9 (D9-23) la relee desde el bolsillo. (c) choca con el gesto `LEER` y no es descubrible. Pregunta abierta Q1. |
| D20-9 | Orden de repaso fijo, empieza por la carta. | Orden de adquisición. | La adquisición de `caja_c1..c4` es libre (7 y 9) y no se guarda: derivar de hechos no da el orden. |
| D20-10 | 20 no emite avisos nuevos al bus. | «ítem obtenido» (id). | Nadie lo consume en el slice (23 y 28 reaccionan a «interacción ejecutada», 7 regla 29); se puede añadir sin cambiar el resto. |
| D20-11 | `A03` se reconstruye de `formulario_leido` al cargar. | Guardar su estado. | Misma regla que las puertas (índice, ronda 2); no añade campos. |

## Preguntas abiertas

| # | Pregunta | Por qué es del autor | Valor por defecto aplicado |
|---|---|---|---|
| Q1 | ¿Se acepta una acción de relectura sin menú (`atrás` corta en `exploración`)? | El slice D.1 dice «No hay menú de inventario»; añadir un mando nuevo roza el alcance de interfaz y toca el GDD 1. | Sí, mínima: un documento por pulsación, sin pantalla de selección. Si se rechaza, la carta necesita un objeto de escena y 9 (D9-23) cambia. |
| Q2 | ¿Se muestran `I-05` e `I-06a` en el momento de resolver P4/P3 mediante `abrir_lectura` (como la carta del P6)? | Cambia el ritmo de la escena 6 (slice C.6) y el tono del clímax. | No decidido aquí: lo resuelven 9 y 10; 20 solo garantiza el bolsillo. |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| 1 Entrada y controles | Añadir `atrás` (pulsación corta, sólo si empieza en `exploración`) a las acciones activas de `exploración` y emitir la acción derivada `repasar_bolsillo` (R18). Depende de Q1. |
| 7 Interacción | Fila de `A03`/`A04`: dueño 20 (ya es así). Añadir `repasar_bolsillo` a quien llama a `abrir_lectura` (regla 27b ya lo cita). Confirmar que 7 devuelve «lectura abierta» también tras `ACEPTADA` o solo tras `APLAZADA` (R20). |
| 2 Jugador | Confirmar que `sostener(item_id, izquierda)` acepta IDs del catálogo del 20 (no de escena) y el emisor de `objeto_sujeto`/`objeto_soltado` (regla 24). |
| 3 Estado | Fila 20 de la tabla de interacciones: ya escribe los tres hechos (correcto). No requiere avisos nuevos (D20-10). |
| 5 Guardado | Ninguno (`card_acquired` cubre las tarjetas). Opcional: causa para `formulario_leido`. |
| 9 Marco | `rewards` de P3/P4/P6 solo informativos para 20 (R8); fijar quién muestra `I-05`/`I-06a` (Q2). |
| 18 Contenido | Claves para el formulario y la lista de tareas como documentos con estilo; clave `UI_BOLSILLO_AYUDA`; confirmar el estilo de `NOTA_01` y de la lista. |
| 8 Control de acceso (futuro) | Recoger `otorgar("A05")`, `sostener_item`, `guardar_item`, `has_item`; no consumir llaves. |
| 19 Ordenador (futuro) | Llamar a `otorgar_sesion("I-01")`; el conjunto no persiste. |
| 24 Prompt | Mostrar el pie `UI_BOLSILLO_AYUDA`. |
| 17 Pistas (futuro) | Leer `formulario_leido`. |
| `systems-index.md` | Estado de la fila 20 a «Borrador»; añadir 1 y 9 a «Depende de» (blandas). |

## Entradas para el registro

**Constantes (`design/registry/entities.yaml`)**

| Nombre | Valor | Fuente |
|---|---|---|
| `t_mostrar_item_s` | 0,7 s | este GDD, F1 |
| `t_tapa_s` | 0,6 s | R15 |
| `repaso_orden` | `I-07, I-05, I-06a, I-04` | R6 |

**Entidades (ítems):** `I-01` … `I-07` (clase, hecho equivalente, persistencia: tabla de la R1).

**Hechos escritos por 20 (owner = 20):** `formulario_leido`, `tarjeta_B`, `tarjeta_D`.

**Interfaz:** `has_item(item_id) -> bool` · `otorgar(origen_id)` (8) · `otorgar_sesion(item_id)` (19) · `sostener_item(item_id) -> {ACEPTADA, RECHAZADA(motivo)}` y `guardar_item()` (8) · `repasar_bolsillo()` (1).

**Claves de contenido nuevas (18):** `UI_BOLSILLO_AYUDA`; claves de documento del formulario y de la lista de tareas.

**Fórmulas:** F1 (`t_pres`), F2 (`i_siguiente`).

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote Feature 1), pendiente de review. |
