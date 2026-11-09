# Documentos y bolsillo

> **Estado:** Revisado (ronda de corrección 3) — pendiente de re-review
> **Sistema:** 20 del índice (`design/gdd/systems-index.md`) · Categoría: Narrative · Prioridad: MVP
> **Autor:** game-designer (lote autónomo, 2026-11-09)
> **Fuente de verdad del slice:** `design/slice/slice-v0.3.md` (D.1 ítems, D.2 banderas, A.4/A.5/A.6 objetos, C.3/C.6 escenas)
> **Pilares que mandan:** Tensión sin castigo (1.º), Información incompleta (2.º), Autonomía como progresión (3.º)

---

## Summary

El sistema 20 es el **dueño de lo que Vera lleva encima y de cómo se lee**. Tiene tres funciones: (1) **dibujar y gestionar la pantalla de lectura** de todos los documentos del slice (formulario, memorando, notas, lista de tareas, carta, libro de visitas), a partir de las claves y estilos de la base de contenido (18); (2) ser el **dueño de los hechos** `formulario_leido`, `tarjeta_B` y `tarjeta_D` y de la pregunta `has_item(id)`; (3) presentar el **bolsillo visual**: el gesto breve de «sacar y guardar» tarjetas (al obtenerlas y al usarlas, a petición de 8), y una relectura sin menú (decisión del usuario, 2026-11-09, D20-8). El bolsillo **no guarda estado propio**: es una *vista derivada de los hechos* (salvo `I-01`, que es de sesión). Por eso no puede perderse nada, ni al cargar ni al fallar un gesto.

## Overview

El slice (D.1) declara siete ítems y una regla: «Vera lleva los ítems en un bolsillo visual. No hay menú de inventario». Este GDD la convierte en reglas.

Hay tres clases de ítem. **Llave** (`I-02`, `I-03`: las tarjetas): se obtienen al abrir el cajón `A05` (objeto y apertura de 8, que llama a `otorgar("A05")`), se muestran en la mano un instante y se usan en los lectores `C06`/`C07` (8). **Documento** (`I-04` formulario, `I-05` lista de tareas, `I-06a` nota, `I-07` carta): se leen en pantalla y se pueden releer. **Material** (`I-01`, la impresión de correos): lo necesita el puzle 1 (`needs_items`) y **no se conserva entre sesiones** (marco 9, D9-33). `I-06b` (la nota bajo la lámpara, `B05`) **no es ítem**: se lee en el sitio.

La decisión estructural es que **ningún ítem tiene almacenamiento propio**. `has_item(id)` es una función de los hechos del estado (3): `tarjeta_B` ⇔ `I-02`, `tarjeta_D` ⇔ `I-03`, `formulario_leido` ⇔ `I-04`, `caja_c1` ⇔ `I-06a`, `caja_c2` ⇔ `I-05`, `caja_c4` ⇔ `I-07`. Guardar y cargar (5) ya persiste esos hechos, de modo que el bolsillo se reconstruye solo. La presentación (la tarjeta en la mano, la pantalla de lectura) es siempre **posterior** al hecho y **nunca lo condiciona**: si un gesto se cancela, el ítem ya está en el bolsillo.

Para releer sin menú, el slice no define ningún mando. Por decisión del usuario (2026-11-09, ronda de decisiones 1; D20-8) `atrás` en `exploración` lanza la acción `repasar_bolsillo` (1, regla 23): abre la lectura del siguiente documento relegible, de uno en uno, sin menú ni pantalla de inventario (el slice D.1, «No hay menú de inventario», se respeta). Entrada (1) activa `atrás` en `exploración` con esta acción (1, regla 23). Los AC-11, AC-12, AC-12b y AC-14 son firmes.

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
| `I-01` | Impresión de correos | material | conjunto de sesión (R9) | **No** | No (el contenido es de 19, R2) | `V08` (19) |
| `I-02` | Tarjeta de la Sala de Reuniones | llave | `tarjeta_B` | Sí (hecho) | No | `A05` (8) |
| `I-03` | Tarjeta sin foto | llave | `tarjeta_D` | Sí (hecho) | No | `A05` (8) |
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

**`I-01` no tiene lectura en 20.** El contenido de la hoja impresa (`DOC_I01`, estilo `impreso`) lo posee 19 (ordenador-correo-impresora.md, R20); 20 solo responde `has_item("I-01")`, no lo ofrece a `repasar_bolsillo()` (Relegible = No) ni lo lee para 9: quien necesite sus referencias las pide a 19.

El estilo concreto de `NOTA_01`/lista de tareas lo confirma el arte (18 es el dueño del campo); aquí solo se exige que el estilo salga del catálogo, nunca del código.

**R3. El texto no se toca.** Este sistema no edita, resume, resalta, ordena por importancia ni anota ningún texto. Dibuja lo que 18 entrega, con los marcadores de nombre resueltos por 18. No hay «diario», «ficha de personaje» ni cronología automática (*Información incompleta*: la comparación es del jugador).

### B. Capacidad y organización del bolsillo

**R4. Capacidad.** El bolsillo no tiene límite que el jugador pueda alcanzar: el catálogo (R1) lo acota a 7. No hay peso, no hay descartar, no hay soltar, no hay combinar, no hay «usar con». El jugador **no puede perder ni tirar** un ítem (*Tensión sin castigo*).

**R5. Sin almacenamiento propio.** El bolsillo es la función `has_item(id)` de la R1. No existe una lista de ítems escrita. Consecuencias: (a) guardar, cargar y reiniciar no requieren campos nuevos; (b) un ítem solo existe si existe su hecho; (c) no se puede dar un ítem sin escribir su hecho, ni quitarlo sin una consola de desarrollo (3, regla 15).

**R6. Organización.** No hay pantalla de inventario ni HUD de ítems (slice D.1; pilar *El espacio expresa la emoción*: ningún indicador). El único orden es el **orden de repaso** (R22), fijo en datos y **neutro** (no expresa importancia, R3): `I-07`, `I-05`, `I-06a`, `I-04`. Las llaves y el material no se repasan.

### C. Cómo se adquieren

**R7. Principio: hecho primero, gesto después.** Toda adquisición escribe el hecho correspondiente **antes** de mostrar nada. La presentación (R12) no condiciona el hecho, ni el avance, ni el guardado. Si se cancela, se rechaza o no ocurre, el ítem está igualmente en el bolsillo.

**R8. Cómo llega cada ítem.**

| Ítem | Disparo | Qué hace 20 |
|---|---|---|
| `I-04` | El aviso «lectura completada» (7, regla 18 y regla 29) con el ID del documento `A04` (≥ `lectura_min_s` = 2 s†). | Escribe `formulario_leido` = verdadero (hecho propio). Si ya era verdadero, no pasa nada (3, regla 4 y 9). `A04` **permanece** en la caja y sigue siendo legible en el sitio; `I-04` es la copia que lleva Vera. |
| `I-02`, `I-03` | `A05` es objeto de 8 (control-de-acceso.md): 8 es su dueño, resuelve su `interact()` y es **la única fuente** de `tarjeta_B/D`. 8 llama a `otorgar("A05")` cuando el cajón ha terminado de abrirse (tras el `gesto_terminado` de `HAND_DRAWER`, cualquier `motivo`). 20 no tiene `interact()` de `A05`. | Escribe `tarjeta_B` y luego `tarjeta_D` (en ese orden) y lanza la presentación R12 de las que **acaban** de pasar a verdadero. Idempotente: si ambas ya son verdaderas, no escribe ni presenta nada. |
| `I-06a`, `I-05`, `I-07` | Cambio de `caja_c1`, `caja_c2`, `caja_c4` a verdadero (aviso automático de cambio de hecho, 3 regla 9). | **No escribe nada** (los hechos son de 9). Solo se hace derivable `has_item`. `I-07` (la carta) la abre 9 con `abrir_lectura` al resolver el P6 (regla 16 de 9); `I-05` e `I-06a` **no tienen presentación nueva** (D20-19): quedan como decorado de la caja (10) y 20 solo garantiza que están en el bolsillo y se pueden releer con `repasar_bolsillo()`. |
| `I-01` | 19 llama a `otorgar_sesion("I-01")` al terminar la impresión de `V08` (requiere `correos_leidos`, lo comprueba 19). | Añade `I-01` al conjunto de sesión (R9). Repetible: añadir un ítem ya presente no hace nada. 20 no guarda ni lee el contenido de la hoja (R2). |

**R9. Conjunto de sesión.** Solo `I-01` es de sesión: se guarda en memoria, **no se persiste**, y se vacía al descargar la escena de planta, al empezar una partida nueva y al cargar. Tras cargar, `has_item("I-01")` es falso aunque `correos_leidos` sea verdadero (9, regla 34 y AC-39b); el jugador vuelve a imprimir en `V08` (repetible e ilimitado, D9-33).

**R10. Escritura de hechos.** El dueño de `formulario_leido`, `tarjeta_B` y `tarjeta_D` es 20 (3, regla 2; fila 20 del índice). Los tres son de un solo sentido (3, regla 4): una vez verdaderos no se deshacen, ni siquiera al «usar» la llave (R16).

### D. Cómo se sostienen

**R11. Sostener solo tras un gesto terminado.** 20 pide `sostener(item_id, izquierda)` al Jugador (2, regla 24) **únicamente** cuando no hay gesto bloqueante en curso: tras el `gesto_terminado` de `HAND_DRAWER` (adquisición) o antes de que 8 pida el gesto de pasar la tarjeta (uso, R16: 8 llama a `sostener_item`). Si el Jugador rechaza `sostener` (otro bloqueante, otro objeto sujeto, `reposo()`), 20 **no lo reintenta**, registra y sigue (R7: el ítem ya es del jugador). Los ítems y la caja `A03` **no** son sostenibles de escena (7, regla 13: la única lista de sostenibles de escena es `V05`; D7-29): los ítems del bolsillo son sostenibles **propios** del 20, no entran en esa lista.

**R12. Presentación de adquisición (solo tarjetas).** Tras R8 para `I-02`/`I-03`, y solo para las que acaban de pasar a verdadero, 20 ejecuta en serie por tarjeta: `sostener(id, izquierda)` → espera `objeto_sujeto(id)` (fundido `t_item_dentro`, 0,3 s, tuning de 2) → pide `HAND_HOLD_ITEM` en la mano izquierda (2, regla 24: exige un objeto sujeto en esa mano y se pide aparte) y lo mantiene `t_mostrar_item_s` → `soltar()` → espera `objeto_soltado(id)` (`t_item_fuera`, 0,3 s). No bloquea el contexto: el jugador puede moverse, mirar o activar otro objeto. Si llega `reposo()`, una `lectura`, una `inspección`, un modo abierto o una escena con `sin control`, la presentación se **aborta** (F1) y el ítem sigue en el bolsillo.

**Orden al abortar por una `lectura`.** `HAND_READ` ocupa la mano izquierda, que sostiene la tarjeta. Quien abre la lectura (7) llama primero a `reposo()` de 2, que suelta el objeto y emite `objeto_soltado`; 20, al recibir un `objeto_soltado` que no viene de su propio `soltar()`, da la presentación por abortada y **no** vuelve a llamar a `soltar()` ni a `reposo()`. Solo entonces arranca `HAND_READ`. 20 nunca pide `reposo()` (‡ 2 y 7 deben confirmar el orden).

**Orden respecto al gesto de 8 (N1-1).** La presentación de R12 empieza **después** del `gesto_terminado(HAND_DRAWER)` (R11) y la tarjeta se guarda (`soltar()` y `objeto_soltado`) al cerrar su turno; `HAND_HOLD_ITEM` es de la mano izquierda y `HAND_CARD_SWIPE` (8) de la derecha, y **no se solapan**: mientras dure cualquier turno de la presentación (hasta 2,6 s† con dos tarjetas, F1), `sostener_item` devuelve `RECHAZADA(presentacion_en_curso)`, 20 **no** corta la presentación por ello y 8 pasa la tarjeta sin mostrarla y sin pedir `HAND_CARD_SWIPE` (8 regla 8; R16). `bloquear_contexto("tarjeta")` de 8 no es causa de aborto. 8 y 20 coinciden en este orden (AC-24 de 20, AC-21 de 8).

No hay sonido de «recompensa»: solo el foley de papel/plástico del Jugador/23. Nada aparece en pantalla (sin icono ni texto de «obtenido»).

**R13. Documentos: sin presentación de adquisición propia.** `I-04` se «obtiene» al terminar de leer el formulario, que ya está en pantalla: no hay segundo gesto. Solo `I-07` tiene lectura automática (la pide 9 al resolver el P6, regla 16 de 9); `I-05` e `I-06a` no tienen presentación nueva (D20-19: decorado de la caja de 10, releíbles con el repaso). 20 no añade animación.

### E. Cómo se leen

**R14. Lectura de objetos de escena.** Cuando 7 entra en `lectura` (7, regla 16) para un documento cuyo dueño es 20 (`A04`, `B05`, o los que 12/16/etc. deleguen), entrega clave y estilo; 20 dibuja la pantalla de lectura. La lectura se cierra con `atrás` (7); 20 recibe «lectura cerrada» (7, regla 29) y libera la pantalla. Un documento de varias páginas (`R01`, dos páginas) usa `interactuar` para pasar (7, regla 17); 20 muestra la página que 7 indica y no tiene estado de página propio.

**R15. `A03` y `A04` (y qué no es de 20: `A05`).** `A05` (el cajón de las tarjetas) lo posee 8; 20 solo recibe `otorgar("A05")` (R8). `A03` (caja del traslado) es `DELEGAR` a 20 (7, tabla de objetos). Estados: `cerrada` → `abierta`. `can_interact` de `A03` es `NO` si ya está `abierta`. `interact()` (tras `HAND_REACH` del Jugador) pasa a `abierta` en el mismo paso y reproduce la animación de la tapa `t_tapa_s` (no bloquea, solo visual). `A04` está habilitado (`can_interact` `LEER`) **solo** con `A03` `abierta` (7). El estado de `A03` **no se guarda**: al cargar, `A03` se reconstruye `abierta` si `formulario_leido` es verdadero y `cerrada` si no (R5, 5 y 3 no necesitan campo nuevo).

**R16. Uso de una llave (tarjeta) y por qué no se consume.** El gesto de pasar la tarjeta lo orquesta **8**, no 7: 7 **no** pasa `tarjeta_item` a `HAND_CARD_SWIPE`. Cuando 8 va a usar `I-02` en `C06` (o `I-03` en `C07`) llama a `sostener_item(id)`: 20 pide `sostener(id, izquierda)` (R11) y devuelve `ACEPTADA` o `RECHAZADA(motivo)`. Tras `objeto_sujeto(id)` 8 pide su gesto (`HAND_CARD_SWIPE`, 2) y, al terminar, llama a `guardar_item()`: 20 pide `soltar()`. 20 no pide `HAND_HOLD_ITEM` en este caso: el gesto de pasar la tarjeta sustituye a la pose de R12 (‡ 2). **Ninguna llave se consume.** El hecho `tarjeta_B`/`tarjeta_D` queda verdadero y `has_item` sigue verdadero tras abrir la puerta. El slice dice «llave de B/D», no «de un solo uso», y 8 reconstruye las puertas cerradas al cargar (índice, notas de la ronda 2): la llave tiene que seguir en el bolsillo para volver a abrir sin penalización. Si `sostener_item` es `RECHAZADA` (incluido `presentacion_en_curso`, R12), 8 pasa la tarjeta igualmente sin mostrarla y sin `HAND_CARD_SWIPE`: el rechazo solo afecta a la presentación (R7). Dependencia dura **recíproca** 8 ↔ 20 (8 llama a `otorgar`, `sostener_item`, `guardar_item` y lee `has_item`/los hechos; 20 no conoce las puertas).

**R17. Hechos de lectura.** El único hecho que escribe una lectura es `formulario_leido` (R8). Leer cualquier otro documento (incluida la carta) no escribe nada. Releer no cambia ningún hecho.

### F. Relectura (repaso del bolsillo)

**R18. Acción.** Se añade una acción derivada: `atrás` (pulsación corta) con el contexto en `exploración` lanza `repasar_bolsillo()`. 20 no exige «estable»: el estado de la transición o del gesto lo evalúa 7 en `abrir_lectura` (R20). Decisión aprobada por el usuario (2026-11-09): Entrada (1) la incorpora como acción `repasar_bolsillo` de `atrás` en `exploración` (1, regla 23; AC-E15 a AC-E17 de 1). El `atrás` que **cierra** un modo (lectura, inspección, vista) no cuenta: la pulsación debe empezar con el contexto ya en `exploración` (Entrada, tabla de contextos).

**R19. Qué hace `repasar_bolsillo()`.** Calcula la lista de documentos relegibles presentes: los ítems de la R1 con «Relegible = Sí» y `has_item` verdadero, ordenados según R6. Si está vacía, no hace nada (sin sonido, sin mensaje). Si no, elige el siguiente según F2 y llama a `abrir_lectura(<item_id>)` a 7 (7, regla 27b).

**R20. Resultados de `abrir_lectura`.**
- `ACEPTADA`: 7 abre la `lectura` con `HAND_READ`. El cursor de repaso avanza (F2).
- `APLAZADA`: ocurre con `exploración` y un gesto bloqueante o una transición en curso (p. ej. un gesto de `HAND_REACH` o el regreso de cámara; 7, regla 27b). 20 no hace nada más; 7 la abrirá al volver el control o la descartará a los 3 s (7, regla 27b: «lectura descartada»). El cursor **no** avanza hasta que 7 emita «lectura abierta» (ID del documento; 7 la emite solo tras una petición aplazada, regla 29: tras `ACEPTADA` no hay aviso y el cursor avanza con la propia respuesta). 20 guarda `repaso_pendiente` (el ID que pidió su propio `repasar_bolsillo()`, vacío si no hay).
- **Solo avanza con lo que pidió 20 (N4-1).** El cursor avanza únicamente con una lectura abierta por la propia acción de repaso: al recibir «lectura abierta(ID)», 20 avanza solo si `repaso_pendiente` no está vacío y es ese ID; si no (p. ej. la carta `I-07` pedida por 9 al resolver el P6 y abierta tras un aplazamiento), ignora el aviso y no toca el cursor. «Lectura descartada», `RECHAZADA` y «cerrada» vacían `repaso_pendiente` sin avanzar.
- `RECHAZADA(motivo)`: 20 no hace nada, registra y deja el cursor. Ocurre con `inspección`, `ordenador`, `llamada`, otra lectura abierta o **ya hay una petición aplazada** (por ejemplo, la carta del P6 aplazada mientras 7 termina el regreso de cámara: no se apila una segunda). Sin mensaje al jugador: pulsar de nuevo cuesta nada.

**R21. La relectura no tiene coste.** No hay límite de aperturas, ni temporizador, ni contador. La relectura no altera `lectura_min_s`: solo `A04` lo tiene y solo en su lectura de escena.

**R22. Orden de repaso.** El primer repaso de la sesión empieza por el **primero** de la lista (`I-07` si está), como en F2 (`i_siguiente = 0`). Cada apertura aceptada avanza al siguiente de la lista y, tras el último, vuelve al primero si `repaso_cerrar_ciclo` es `true` (por defecto, F2); con `false` el cursor se detiene en el último y las pulsaciones siguientes lo reabren. El cursor es de sesión y no se guarda. Con un solo documento relegible, `atrás` lo reabre siempre.

**R23. Pista de control.** La primera vez que algún documento relegible entra en el bolsillo, 20 pide una vez a 24 un pie no bloqueante (clave `UI_BOLSILLO_AYUDA`, ver cambios en 18: «Atrás: revisar los papeles»). Se muestra como un pie de 7 (regla 12): no es información necesaria para avanzar; «ya mostrado» es un indicador **de sesión**, no se persiste: se muestra como máximo una vez por sesión; tras cargar (sesión nueva) puede volver a mostrarse la primera vez que entre un relegible, y es inocuo.

### G. Persistencia y propiedad

**R24. Qué se guarda.** Nada propio. Se guardan los hechos que ya existen: `formulario_leido`, `tarjeta_B`, `tarjeta_D` (de 20) y `caja_c1`, `caja_c2`, `caja_c4`, `carta_variante` (de 9). Guardado (5, regla 14) ya tiene la causa `card_acquired:<id>` para el cambio de `tarjeta_B`/`tarjeta_D`. `formulario_leido` no tiene causa propia: lo cubren `quit` (cierre normal o «salir al título», 5), `periodic` o la siguiente causa. Solo un cierre forzado puede perderlo (coste: como mucho 2 s de relectura del formulario, ver Edge Cases).

**R25. Quién es dueño de qué.**

| Dato | Dueño (escribe) | Lee |
|---|---|---|
| `formulario_leido`, `tarjeta_B`, `tarjeta_D` | **20** | 8 (puertas), 17 (pistas), 7 (`habilitado_si`) |
| `caja_c1`, `caja_c2`, `caja_c4`, `carta_variante` | 9 | 20 (deriva `has_item`, elige la carta) |
| conjunto de sesión (`I-01`) | **20** (lo rellena 19) | 9 (`needs_items`, `has_item`) |
| texto y estilo de documentos | 18 | 20 (dibuja) |
| gestos y objeto sujeto | 2 | 20 (pide), 7/8 (esperan) |
| `A05` (objeto, `interact()` y apertura) | 8 | 20 (recibe `otorgar("A05")`) |
| contenido de la hoja `I-01` (`DOC_I01`) | 19 | 20 solo responde `has_item` |
| estado de `A03` | 20 (se reconstruye) | 7 |

**R26. Restauración y descarga.** Al restaurar (3, regla 13) 20 no hace nada: `has_item` ya devuelve el valor correcto porque los hechos están restaurados. Al descargar la escena (4), 20 cancela cualquier presentación, cierra la pantalla de lectura sin avisos al bus (7, regla 27a, descarga) y vacía el conjunto de sesión (R9).

**R27. Sin medidores ni moral.** Ningún ítem lleva valor, relevancia ni «importancia». La carta se guarda con su variante (A/B/C) por contenido; el sistema no la clasifica (pilar *Ambivalencia sin moral binaria*; Engineering: ningún flag representa moralidad).

---

## Formulas

**F1 · Duración de la presentación de adquisición (R12).**
`t_pres = Σ_{i=1..n} (t_item_dentro + t_mostrar_item_s + t_item_fuera)`, con `n` ∈ {0, 1, 2} (tarjetas recién adquiridas).
Variables: `t_item_dentro` = `t_item_fuera` = 0,3 s (2, tuning, rango 0,15–0,6); `t_mostrar_item_s` = 0,7 s† (rango 0,4–1,5; propuesta: el slice no fija este tiempo, se ajusta en playtest).
Ejemplo (valores por defecto, `n` = 2): `2 × (0,3 + 0,7 + 0,3)` = **2,6 s†** (depende de †). Con `n` = 1: 1,3 s†. Con `n` = 0: 0 s.
Aborto: si en cualquier instante se cumple una condición de la R12, se corta y la duración efectiva es el tiempo transcurrido; el ítem no se pierde.

**F2 · Cursor de repaso (R19, R22).**
Sea `L` la lista ordenada de relegibles presentes (longitud `m` ≥ 0) en orden `I-07, I-05, I-06a, I-04` filtrado por `has_item`. Sea `c` el cursor de sesión, con valor inicial «ninguno».
`i_siguiente = 0` si `c` es ninguno o `c` ya no está en `L`; si no, `i_siguiente = (posición(c, L) + 1) mod m` con `repaso_cerrar_ciclo = true`, o `mín(posición(c, L) + 1, m − 1)` con `false` (R22).
Tras `ACEPTADA` (o «lectura abierta» tras `APLAZADA`): `c = L[i_siguiente]`. Con `m` = 0 no se hace nada.
Ejemplo: `L = [I-07, I-05, I-04]`. Pulsaciones sucesivas abren `I-07`, `I-05`, `I-04`, `I-07`. Si entre medias se obtiene `I-06a`, `L = [I-07, I-05, I-06a, I-04]` y, estando `c = I-05`, la siguiente abre `I-06a`.
Rango de salida: 0 ≤ `i_siguiente` ≤ 3. Peor caso para llegar a un documento dado: `m − 1` = 3 pulsaciones adicionales (estimación < 10 s† con la lectura intercalada, sin medir).
Con `repaso_cerrar_ciclo = false`: si `c` es el último de `L`, `i_siguiente` = posición de `c` (se detiene en el último y lo reabre); con `true` (defecto), `mod m` vuelve al primero. El ejemplo de arriba es con `true`.

**F3 · Equivalencia `has_item` (R1).** `has_item(id)` = hecho del estado de la R1 para `I-02..I-07`; `id ∈ sesión` para `I-01`; falso en otro caso. Sin parámetros numéricos.

---

## Edge Cases

- **Se cierra el juego de forma forzada tras leer el formulario y antes de cualquier causa de guardado.** Solo si el cierre es **forzado** (proceso terminado; el cierre normal escribe por `quit`, 5): `formulario_leido` se pierde a lo sumo `t_periodico` (120 s†, 5, regla 14). Al cargar, `A03` está `cerrada` y `I-04` no está; el jugador la abre y lee otros 2 s. Sin coste (*Tensión sin castigo*). Si ya había cogido las tarjetas, `card_acquired` guarda también `formulario_leido`.
- **Se cierra el juego con las tarjetas ya cogidas.** `tarjeta_B` y `tarjeta_D` están guardadas (`card_acquired`, 5). Al cargar, las puertas B y D están cerradas (8) y el jugador usa de nuevo la tarjeta (R16). `A05` se encuentra vacío: `otorgar("A05")` es idempotente y no presenta nada (R8).
- **`A05` se abre pero la presentación se cancela** (`reposo()`, `cerrar_modos()`, el jugador abre una lectura): los dos hechos ya están escritos (R7); sin tarjeta en la mano, pero con ambas en el bolsillo.
- **`sostener` rechazado** (otro bloqueante o un objeto sujeto): no se reintenta (R11); el uso de la llave sigue funcionando sin mostrarla (R16).
- **El jugador abre `A05` con `lectura` o `inspección` de otra cosa en curso.** Imposible: son modos de 7 y `A05` es un `DELEGAR` en `exploración`.
- **`A04` se lee menos de 2 s.** No hay «lectura completada» (7, AC-24): `formulario_leido` sigue falso. Se puede releer sin coste.
- **`A04` se relee con `formulario_leido` verdadero.** El aviso se emite de nuevo; la escritura de 20 es el mismo valor: no hay aviso de cambio ni nuevo guardado (3, regla 9).
- **`atrás` en `exploración` sin documentos relegibles.** No pasa nada. No hay aviso de «no tienes nada».
- **`atrás` pulsado mientras hay una petición aplazada** (la carta del P6 mientras 7 termina la salida de la vista): `RECHAZADA` (7, regla 27b: «ya hay una petición aplazada»). El cursor no avanza. Cuando la carta se abre sola (D7-32) y se cierra con `atrás`, ese `atrás` no cuenta como repaso (R18).
- **La carta del P6 y el repaso a la vez.** `I-07` es `caja_c4`: está en el bolsillo desde el instante en que el hecho es verdadero, aunque la lectura inicial de 9 se aplace. El jugador puede releerla desde que 7 acepte una lectura.
- **Dos tarjetas y `carta_variante` ausente.** Si `caja_c4` es verdadero y `carta_variante` no está fijada (estado imposible salvo consola): `I-07` se dibuja con `CARTA_CUERPO` solo y se registra un error en desarrollo; en la build final no se oculta el ítem.
- **Un documento sin texto en 18 (clave ausente).** 18 devuelve «no encontrado»; 20 muestra el texto de emergencia de 18 (regla 21 de 18) y registra. No se bloquea la lectura ni se cierra el modo.
- **Texto muy largo** (carta y cuerpo en un solo viewport): la pantalla de lectura ajusta el tamaño a la página; si no cabe, divide en páginas con `interactuar`, nunca recorta. Hoy se estima que ningún documento del slice lo necesita (la carta, ≤ 90 palabras†, estimación sin verificar contra 18).
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
| 7 Interacción e inspección | Dura | Dibuja la pantalla de `lectura` (regla 16); maneja `A03` (tabla de objetos); llama a `abrir_lectura` (regla 27b) | Clave y estilo del documento; «lectura completada» (regla 18), «lectura abierta» (solo tras `APLAZADA`)/«cerrada»/«descartada» (regla 29); `A03` DELEGAR; `reposo()` de 2 antes de `HAND_READ` si hay un objeto sujeto (R12) |
| 18 Contenido narrativo | Dura | Muestra documentos con su estilo (regla 1) | Textos y fragmentos (regla 10), marcadores de nombre, texto de emergencia (regla 21) |
| 2 Jugador | Blanda | `sostener(id, izquierda)` y `soltar()` (regla 24), tras `gesto_terminado` | `objeto_sujeto`, `objeto_soltado`, `gesto_terminado`; `t_item_dentro/fuera` |
| 9 Marco de puzles | Blanda (‡) | `has_item(id)` para `needs_items` (regla 34); deriva `I-05`, `I-06a`, `I-07` de sus hechos | `abrir_lectura(I-07)` al resolver P6 (regla 16 de 9, paso final); en la reapertura, `on_reopen` responde `SIN_EFECTO` (regla 35) y la relectura de la carta **no la pide 9**: la hace el jugador con `repasar_bolsillo()` (20, vía R18 y 7, regla 27b); 20 no avanza su cursor con la lectura que abre 9 (R20, N4-1); los hechos `caja_c1..c4` y `carta_variante`; AC-39, AC-39b |
| 8 Control de acceso | Dura (de 8 hacia 20; la declara 8, que consume `otorgar`/`sostener_item`/`guardar_item`; 20 la repite) | `otorgar("A05")`, `sostener_item(id) -> {ACEPTADA, RECHAZADA(motivo)}`, `guardar_item()`, `has_item(id)`; escribe `tarjeta_B/D` | 8 es dueño de `A05` y de su `interact()`; llama a esas cuatro operaciones alrededor de `HAND_CARD_SWIPE` (7 no pasa `tarjeta_item`); lee `tarjeta_B/D` |
| 19 Ordenador, correo e impresora | Dura (de 19 hacia 20) | `otorgar_sesion("I-01")`, `has_item("I-01")` | Llama a `otorgar_sesion("I-01")` tras la impresión de `V08`; posee el contenido (`DOC_I01`); 20 no lo lee |
| 10 Caja y compartimentos | Blanda | Nada (deriva `I-06a`, `I-05`, `I-07` de `caja_c1`, `caja_c2`, `caja_c4`, R5) | Decorado `NOTA_01`, papel de `I-05` y carta plegada (no interactivos); 10 no presenta la lectura de `I-05`/`I-06a` (D20-19) ni consulta `has_item` (10 reglas 17, 18; Dependencies de 10) |
| 17 Pistas (sin GDD) | Blanda | `formulario_leido` | Lee el hecho |
| 1 Entrada | Blanda (así la declaran 20 y 1) | La acción `repasar_bolsillo()` (R18); 20 no define mando propio | La acción derivada `repasar_bolsillo` de `atrás` corta con el contexto en `exploración` (1, regla 23; AC-E15 a AC-E17) |
| 5 Guardado | Blanda (así la declara 5) | — | Persiste los hechos; causa `card_acquired` (regla 14, AC-04b) |
| 24 Prompt | Blanda | Pie `UI_BOLSILLO_AYUDA` (R23) | Dibuja el pie |
| 4 Escena de planta | Dura (así la declara 4: vía contenedores e IDs) | Libera sesión en la descarga (R26) | Sus elementos viven en los contenedores de la planta; descarga |
| 21 Director de escenas | Indirecta (así la declara 21) | — | `cerrar_modos()` cierra la lectura (7, regla 27a) |

Contrato recíproco con 7: la fila 20 de las interacciones de 7 («Documento a mostrar, estilo, aviso lectura completada» / «Dibujo de la pantalla; `abrir_lectura`») coincide con las reglas R14 y R19–R20. Con 2: la nota de la regla 24 («20 pide `sostener` solo tras `gesto_terminado`») es R11. Con 9: `has_item` (regla 34) y `rewards` (regla 16, los ítems no son hechos propios) son R5 y R8.

---

## Tuning Knobs

| Perilla | Defecto | Rango seguro | Categoría | Razón |
|---|---|---|---|---|
| `t_mostrar_item_s` | 0,7 s† (propuesta, sin fuente en el slice) | 0,4–1,5 | Feel | Tiempo con la tarjeta visible. Menos de 0,4 no se lee; más de 1,5 con dos tarjetas supera 4 s de presentación sin control |
| `t_tapa_s` (animación de `A03`) | 0,6 s† (propuesta, sin fuente en el slice) | 0,3–1,0 | Feel | Visual, no bloquea |
| `repaso_orden` | `I-07, I-05, I-06a, I-04` | Cualquier permutación | Feel | Orden fijo y neutro (no expresa importancia, R3); la adquisición es libre y no se guarda (D20-9) |
| `repaso_cerrar_ciclo` | `true` | `true`/`false` | Feel | Vuelve al primero tras el último (R22, F2); con `false` se detiene en el último |
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
- **AC-05 (R9, L)**: **GIVEN** `otorgar_sesion("I-01")`, **WHEN** se carga la partida, **THEN** `has_item("I-01")` es falso aunque `correos_leidos` sea verdadero.
- **AC-05b (R9, I)**: **GIVEN** una partida cargada con `correos_leidos` verdadero e `I-01` ausente, **WHEN** 19 llama de nuevo a `otorgar_sesion("I-01")`, **THEN** `has_item("I-01")` es verdadero y P1 es resoluble (9, AC-39b).
- **AC-06 (R7, R12, F1, I)**: **GIVEN** `A05` abierto, **WHEN** se llama a `otorgar`, **THEN** se presenta `I-02` y luego `I-03` en 2,6 s† con los valores por defecto sin bloquear el contexto; **WHEN** se llama a `reposo()` en t = 1,0 s, **THEN** la presentación se aborta y `has_item` de ambas sigue verdadero.
- **AC-07 (R11, I)**: **GIVEN** un gesto bloqueante en curso, **WHEN** 20 pide `sostener`, **THEN** el Jugador lo rechaza, 20 registra y no reintenta; el hecho no cambia.
- **AC-08 (R16, I)**: **GIVEN** `tarjeta_B` verdadero, **WHEN** 8 usa `I-02` (sostener → gesto → guardar), **THEN** `has_item("I-02")` sigue verdadero; **WHEN** se carga la partida, **THEN** la puerta B está cerrada y la tarjeta la abre de nuevo.
- **AC-09 (R15, I)**: **GIVEN** `A03` cerrada, **THEN** `A04` no está habilitado; **WHEN** se abre `A03`, **THEN** `A04` es legible; **WHEN** se carga con `formulario_leido` verdadero, **THEN** `A03` está abierta.
- **AC-10 (R14, I)**: **GIVEN** `A04`, **WHEN** se lee 1,9 s y se cierra, **THEN** `formulario_leido` sigue falso; **WHEN** se lee 2,0 s, **THEN** es verdadero.
- **AC-11 (R19, R22, F2, L; firme, D20-8)**: **GIVEN** `I-07`, `I-05` e `I-04` presentes, **WHEN** se llama cuatro veces a `repasar_bolsillo()` con `ACEPTADA`, **THEN** abre `I-07`, `I-05`, `I-04`, `I-07`; **GIVEN** ninguno, **THEN** no hace nada.
- **AC-12 (R20, I; firme, D20-8)**: **GIVEN** una petición de 9 aplazada (carta del P6, regreso de cámara en curso), **WHEN** el jugador pulsa `atrás` en `exploración`, **THEN** `abrir_lectura` devuelve `RECHAZADA`, el cursor no avanza y no hay mensaje.
- **AC-12b (R20, I; firme, D20-8)**: **GIVEN** `exploración` con un gesto bloqueante en curso y ningún aplazamiento previo, **WHEN** se pulsa `atrás` y 7 devuelve `APLAZADA`, **THEN** 20 espera «lectura abierta» sin repetir la petición y el cursor avanza solo cuando llega; **WHEN** 7 emite «lectura descartada», **THEN** el cursor no avanza.
- **AC-12c (R20, N4-1, I; firme)**: **GIVEN** `repaso_pendiente` vacío y la carta `I-07` pedida por 9 aplazada, **WHEN** 7 emite «lectura abierta(`I-07`)», **THEN** el cursor de repaso no cambia; **GIVEN** un repaso propio `APLAZADO` de `I-05`, **WHEN** llega «lectura abierta(`I-05`)», **THEN** el cursor avanza una vez; **WHEN** llega «lectura descartada», **THEN** `repaso_pendiente` queda vacío y el cursor no avanza.
- **AC-13 (R2, R14, L)**: **GIVEN** `carta_variante` = B, **WHEN** se lee `I-07`, **THEN** muestra `CARTA_B` y después `CARTA_CUERPO` con estilo `manuscrito_vera` y los textos exactos de 18.
- **AC-14 (R18, I; firme, D20-8)**: **GIVEN** una lectura abierta, **WHEN** se cierra con `atrás`, **THEN** no se lanza un segundo repaso con la misma pulsación.
- **AC-15 (R26, I)**: **GIVEN** una presentación en curso, **WHEN** se descarga la escena, **THEN** se cancela sin avisos al bus y el conjunto de sesión queda vacío.
- **AC-16 (R3, R27, L)**: **GIVEN** los textos de 18 de `I-04`, `I-05`, `I-06a` e `I-07`, **THEN** el texto dibujado es idéntico al de 18 (sin marcas, resaltado ni anotación), la API de 20 no expone ningún campo de importancia/valoración, y el orden de `repasar_bolsillo()` es el de `repaso_orden` con independencia del orden de adquisición.
- **AC-17 (R12, PV)**: **GIVEN** la presentación de las tarjetas, **THEN** la captura retenida muestra la tarjeta en la mano izquierda, sin icono ni texto superpuesto, y el lead de arte firma que la pose es de oficina (checklist: sin brillo, sin partículas, sin destello).
- **AC-18 (R23, L)**: **GIVEN** que entra el primer documento relegible, **THEN** se solicita `UI_BOLSILLO_AYUDA` una sola vez y entradas posteriores en la misma sesión no la repiten; **WHEN** se carga una partida (sesión nueva), **THEN** puede solicitarse otra vez, una vez.
- **AC-19 (R4, L)**: **GIVEN** la API pública de 20, **THEN** no existe operación para tirar, soltar, combinar ni consumir un ítem; **WHEN** se usa `I-02` (R16) o se llama a `reposo()`, **THEN** ningún hecho de R1 cambia a falso.
- **AC-20 (R12, I)**: **GIVEN** la presentación de una tarjeta, **THEN** no se emite ningún evento de audio de recompensa (solo el foley de papel/plástico) y no se pide ningún texto ni icono a 24.
- **AC-21 (R15, I)**: **GIVEN** `A03` cerrada, **WHEN** se activa, **THEN** `A04` queda habilitado en el mismo paso y el jugador puede moverse y mirar durante `t_tapa_s` (la animación no bloquea).
- **AC-22 (R12, I)**: **GIVEN** una tarjeta sujeta en presentación, **WHEN** 7 abre una `lectura`, **THEN** 7 llama a `reposo()` antes de `HAND_READ`, 20 da la presentación por abortada sin llamar a `soltar()` ni a `reposo()`, y `has_item` sigue verdadero.
- **AC-24 (R12, R16, N1-1, I)**: **GIVEN** una presentación de tarjeta en curso (cualquier turno de F1), **WHEN** 8 llama a `sostener_item`, **THEN** devuelve `RECHAZADA(presentacion_en_curso)`, la presentación sigue y termina con `soltar()`, y no se pide `HAND_CARD_SWIPE` mientras `HAND_HOLD_ITEM` esté activo (nunca coexisten); **GIVEN** ninguna presentación, **THEN** `sostener_item` devuelve `ACEPTADA`. La presentación nunca empieza antes del `gesto_terminado(HAND_DRAWER)`.
- **AC-23 (R16, I)**: **GIVEN** `tarjeta_B` verdadero, **WHEN** 8 pasa la tarjeta, **THEN** 7 no recibe `tarjeta_item`, la tarjeta se muestra una sola vez (por `sostener_item`) y, con `sostener_item` `RECHAZADA`, el gesto se ejecuta igualmente sin tarjeta mostrada.

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
| D20-8 | Relectura con `atrás` corta en `exploración` y ciclo de un documento por pulsación (R18–R22). | (a) Menú de inventario. (b) Sin relectura (solo objetos de escena). (c) `interactuar` mantenida sin objetivo. | (a) contradice D.1 del slice. (b) la carta no tiene objeto de escena y 9 (D9-23) la relee desde el bolsillo. (c) choca con el gesto `LEER` y no es descubrible. Aprobada por el usuario (2026-11-09): sin menú, un documento por pulsación; activada en Entrada (1). |
| D20-9 | Orden de repaso fijo, empieza por la carta. | Orden de adquisición. | La adquisición de `caja_c1..c4` es libre (7 y 9) y no se guarda: derivar de hechos no da el orden. |
| D20-10 | 20 no emite avisos nuevos al bus. | «ítem obtenido» (id). | Nadie lo consume en el slice (23 y 28 reaccionan a «interacción ejecutada», 7 regla 29); se puede añadir sin cambiar el resto. |
| D20-11 | `A03` se reconstruye de `formulario_leido` al cargar. | Guardar su estado. | Misma regla que las puertas (índice, ronda 2); no añade campos. |
| D20-12 | `A05` y su `interact()` son de 8; 8 llama a `otorgar("A05")` y es la única fuente de `tarjeta_B/D`. | 20 como dueño del cajón. | 8 ya lo cita (regla 18f) y orquesta puertas y lectores; evita un objeto sin dueño (B1 de la review). |
| D20-13 | El gesto de tarjeta lo orquesta 8 con `sostener_item`/`guardar_item`; 7 no pasa `tarjeta_item` a `HAND_CARD_SWIPE`. | 7 muestra la tarjeta pasando `tarjeta_item`. | Un solo mecanismo: evita dibujar la tarjeta dos veces y mantiene a 2 como único dueño de la mano (D-34). |
| D20-14 | El contenido de `I-01` lo posee 19; 20 solo guarda `has_item("I-01")` y no lo ofrece al repaso. La llamada es `otorgar_sesion("I-01")`. | 20 almacena y dibuja la hoja. | Un dato, un dueño (18 regla 11 por analogía); 19 compone la hoja a partir de los correos. |
| D20-15 | El repaso empieza por el primero de la lista (`I-07`) y `repaso_orden` es neutro. | Empezar por el último; ordenar «lo necesario para la llamada». | Coherencia con F2 y con R3 (sin orden por importancia). |
| D20-16 | R18 exige solo el contexto `exploración`, no «estable»; 7 decide ACEPTADA/APLAZADA/RECHAZADA. | 20 filtra transiciones. | Duplicar la lógica de 7 deja `APLAZADA` inalcanzable y desincroniza ambos. |
| D20-17 | `HAND_HOLD_ITEM` lo pide 20 solo en la presentación de adquisición (R12); en el uso (R16) lo sustituye `HAND_CARD_SWIPE`. | 20 siempre pide `HAND_HOLD_ITEM`. | El gesto de 8 ya ocupa la mano; dos poses encadenadas dibujarían una tarjeta fantasma (‡ 2). |
| D20-18 | La relectura de la carta tras reabrir P6 la hace el jugador (R18); 9 responde `SIN_EFECTO` en `on_reopen` (regla 35). | 9 pide `abrir_lectura(I-07)` al reabrir. | 9 regla 35 y D9-23 lo dejan como petición independiente de la vista. |
| D20-19 | `I-05` (lista, P4) e `I-06a` (nota, P3) no tienen presentación nueva al resolver el puzle: quedan como decorado de la caja (10) y son releíbles desde el bolsillo con `repasar_bolsillo()` (R18–R22). Cierra Q2. Aprobada por el usuario, 2026-11-09. | Mostrarlos con `abrir_lectura` al resolver P4/P3 como la carta del P6. | Cambiaría el ritmo de la escena 6 (slice C.6) y el tono del clímax; la relectura voluntaria da el mismo acceso sin interrumpir. |
| D20-8b | Confirmación de D20-8 (Q1): acción `atrás` corta en `exploración` aprobada y activada en Entrada (1). Aprobada por el usuario, 2026-11-09. | Rechazarla y dar un objeto de escena a la carta. | Mantener D.1 del slice (sin menú) y mantener la relectura que 9 (D9-23) ya asume; riesgo mínimo: abrir una lectura sin querer, sin coste. |
| D20-23 | **(Ronda de corrección 3, R6-1)** Regla común de dureza: la declara el GDD dependiente (el que consume la API) y el proveedor repite la misma; si discrepan manda el dependiente salvo texto obsoleto. En 20: 8 **Dura** (de 8 hacia 20), 4 **Dura**, 5 **Blanda**, 21 **Indirecta** (así las declaran 8, 4, 5 y 21), 1 **Blanda** (texto «Dura» retirado: la regla 23 de 1 existe), 9 y 10 **Blanda**. | Mantener «Indirecta» con 4 y 5 y la nota de discrepancia con 1. | Una sola dureza por pareja; la fila de 1 estaba obsoleta tras la regla 23 de Entrada. |
| D20-24 | **(R6-2, R6-7)** `repasar_bolsillo` con guion bajo también en el Historial; `t_mostrar_item_s` y `t_tapa_s` marcados † como propuesta (el slice no fija tiempos de presentación). | Dejarlos sin marca. | Valores sin fuente deben declararse como propuesta. |

## Preguntas abiertas

| # | Pregunta | Por qué es del autor | Valor por defecto aplicado |
|---|---|---|---|
| — | Q1 (acción de relectura sin menú) y Q2 (¿se muestran `I-05`/`I-06a` al resolver P4/P3?) quedan **decididas** (ver «Decisiones tomadas», D20-8 y D20-19). No hay preguntas abiertas de alcance en este GDD. | — | — |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| 1 Entrada y controles | Hecho (D-A, regla 23 de 1): `atrás` (pulsación corta, solo si empieza en `exploración`) activa en `exploración` con la acción derivada `repasar_bolsillo` (R18); AC-E15 a AC-E17 de 1 (AC-E16 cubre AC-14 de 20). |
| 7 Interacción | Fila de `A03`/`A04`: dueño 20 (ya es así). Añadir `repasar_bolsillo` a quien llama a `abrir_lectura` (regla 27b ya lo cita). Ya confirmado: «lectura abierta» solo tras `APLAZADA` (regla 29); R20 lo respeta. Confirmar que 7 llama a `reposo()` de 2 antes de `HAND_READ` si hay un objeto sujeto (R12). `HAND_CARD_SWIPE` no recibe `tarjeta_item`. |
| 2 Jugador | Confirmar que `sostener(item_id, izquierda)` acepta IDs del catálogo del 20 (no de escena) y el emisor de `objeto_sujeto`/`objeto_soltado` (regla 24); que `HAND_HOLD_ITEM` se pide aparte tras `objeto_sujeto` (R12) y que `HAND_CARD_SWIPE` sustituye a esa pose (R16). |
| 3 Estado | Fila 20 de la tabla de interacciones: ya escribe los tres hechos (correcto). No requiere avisos nuevos (D20-10). |
| 5 Guardado | Ninguno (`card_acquired` cubre las tarjetas). Opcional: causa para `formulario_leido`. |
| 9 Marco | `rewards` de P3/P4/P6 solo informativos para 20 (R8); `I-05`/`I-06a` no tienen presentación nueva en 9 ni en 10 (D20-19). Regla 35: `on_reopen` responde `SIN_EFECTO`; la relectura de la carta no la pide 9 (la hace `repasar_bolsillo()`, R18); actualizar la mención de 9 en Dependencies (hecho aquí). |
| 18 Contenido | Claves para el formulario y la lista de tareas como documentos con estilo; clave `UI_BOLSILLO_AYUDA`; confirmar el estilo de `NOTA_01` y de la lista. |
| 8 Control de acceso | Reconocer a 20 como dependencia dura recíproca; 8 es dueño de `A05` y de su `interact()` y llama a `otorgar("A05")`, `sostener_item(id)`, `guardar_item()` alrededor de `HAND_CARD_SWIPE`; no consumir llaves; quitar «8 no tiene GDD / sin 20» y la propuesta de 7 pasando `tarjeta_item` (Pregunta abierta 3 y Cambios a 7 (d) de 8). |
| 19 Ordenador, correo e impresora | Sustituir `entregar_item('I-01')` por `otorgar_sesion("I-01")`; 19 posee `DOC_I01` y su contenido; 20 no lo lee ni lo ofrece al repaso; la vista de `C05` (R27 de 19) obtiene las referencias de `I-01` de 19, no de 20; pasar la dependencia con 20 a «de 19 hacia 20 (dura)». |
| 10 Caja | Hecho (ronda 5): fila de 10 en Dependencies de 20 (Blanda); `I-05`/`I-06a` sin presentación nueva (D20-19). |
| 24 Prompt | Mostrar el pie `UI_BOLSILLO_AYUDA`. |
| 17 Pistas (futuro) | Leer `formulario_leido`. |
| `systems-index.md` | Estado de la fila 20 a «Revisado (ronda de corrección 1)»; «Depende de» con 1, 3, 7, 8, 9, 18, 19 (blandas: 2); nombre «Documentos y bolsillo» (sin «visual»). |

## Entradas para el registro

**Constantes (`design/registry/entities.yaml`)**

| Nombre | Valor | Fuente |
|---|---|---|
| `t_mostrar_item_s` | 0,7 s† | este GDD, F1 (propuesta; sin fuente en el slice) |
| `t_tapa_s` | 0,6 s† | R15 (propuesta; sin fuente en el slice) |
| `repaso_orden` | `I-07, I-05, I-06a, I-04` | R6 |
| `repaso_cerrar_ciclo` | `true` | R22 |

**Entidades (ítems):** `I-01` … `I-07` (clase, hecho equivalente, persistencia: tabla de la R1).

**Hechos escritos por 20 (owner = 20):** `formulario_leido`, `tarjeta_B`, `tarjeta_D`.

**Interfaz:** `has_item(item_id) -> bool` · `otorgar(origen_id)` (llama 8, para `"A05"`) · `otorgar_sesion(item_id)` (llama 19) · `sostener_item(item_id) -> {ACEPTADA, RECHAZADA(motivo)}` y `guardar_item()` (llama 8) · `repasar_bolsillo()` (acción de 1).

**Claves de contenido nuevas (18):** `UI_BOLSILLO_AYUDA`; claves de documento del formulario y de la lista de tareas.

**Fórmulas:** F1 (`t_pres`), F2 (`i_siguiente`).
| D20-20 | **(Ronda de corrección 2, N1-1)** La presentación de tarjetas (R12) empieza tras `gesto_terminado(HAND_DRAWER)` y se guarda al cerrar su turno; durante ella `sostener_item` es `RECHAZADA(presentacion_en_curso)` y 8 no pide `HAND_CARD_SWIPE`. | (a) Abortar la presentación al llegar `sostener_item`. (b) Dejar coexistir `HAND_HOLD_ITEM` y `HAND_CARD_SWIPE`. | (a) retrasaría la apertura de la puerta y rompería el no-castigo de D20-2; (b) dibujaría dos tarjetas (‡ 2). Con el rechazo, 8 ya abre la puerta sin mostrar la tarjeta (8 regla 8). Decisión por defecto. |
| D20-21 | **(N4-1)** El cursor de repaso avanza solo con lecturas abiertas por la propia acción (`repaso_pendiente`), no con la carta `I-07` que abre 9. | Avanzar con cualquier «lectura abierta». | El aviso lleva solo el ID: la carta del P6 haría saltar el orden del siguiente repaso sin que el jugador lo haya pedido. Decisión por defecto. |
| D20-22 | **(W-4, W-5, W-6)** Se añade la fila de 10 (Blanda); la acción se llama siempre `repasar_bolsillo` (1, regla 23); `I-05`/`I-06a` no tienen presentación nueva en 9/10. | Dejar «Hoy no existe» y las menciones a 9/10. | Textos obsoletos: la acción ya existe en 1 (AC-E15 a AC-E17) y D20-19 la cerró. |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote Feature 1), pendiente de review. |
| 2026-11-09 | Ronda de corrección 1 tras la review independiente (2 bloqueantes, 13 avisos): contrato con 8 (`A05`, gesto de tarjeta, recíproca), `I-01` de 19, cita 7 regla 27b, orden de repaso (R22/F2/`repaso_orden`), regla 29 de 7, regla 35 de 9, Q1 como pregunta de alcance, `quit`/120 s†, R12 con `HAND_HOLD_ITEM` y orden `reposo()`/`HAND_READ`, R18/R20, R23/AC-18, `repaso_cerrar_ciclo`, ACs nuevos y separados, valores con †. Decisiones D20-12 a D20-18. Estado: pendiente de re-review. |
| 2026-11-09 | Ronda de decisiones 1: Q1 decidida (D-A, `atrás` corta en `exploración` = `repasar_bolsillo`; AC-11, AC-12, AC-12b y AC-14 firmes, activada en 1) y Q2 decidida (D-B, D20-19: `I-05`/`I-06a` sin presentación nueva, releíbles con el repaso). Estado: pendiente de re-review. |
| 2026-11-09 | Ronda de corrección 2 (informe cruzado ronda 5: W-4, W-5, W-6, W-7, N1-1, N4-1): fila de 10 y fila 1 corregida en Dependencies, `repasar_bolsillo` unificado, R8/R13 sin presentación de 9/10 para `I-05`/`I-06a`, orden presentación-gesto de 8 (R12, R16, AC-24), `repaso_pendiente` (R20, AC-12c), D20-20 a D20-22. Estado: Revisado (ronda de corrección 2) — pendiente de re-review. |
| 2026-11-09 | Ronda de corrección 3 (informe cruzado ronda 6: R6-1, R6-2, R6-7): durezas alineadas con las declaradas por 8, 4, 5, 21, 1, 9, 10 (D20-23), fila de 1 sin la discrepancia obsoleta, `repasar_bolsillo` en el log, `t_mostrar_item_s` y `t_tapa_s` como propuesta † (D20-24). Estado: Revisado (ronda de corrección 3) — pendiente de re-review. |
