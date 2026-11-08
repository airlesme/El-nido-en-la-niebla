# Estado del juego y bus de eventos

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Tensión sin castigo (sin softlock) · Autonomía como progresión (estado en banderas) · Información incompleta (datos fuera del código)

## Summary

Es la memoria compartida del slice: guarda los 19 hechos que el juego debe recordar (qué has leído, qué puertas abriste, qué carta elegiste…) y avisa a los demás sistemas cuando uno cambia. El jugador no lo ve, pero es lo que hace que sus acciones tengan consecuencias visibles y que la partida se reanude donde la dejó, sin que nada hecho pueda deshacerse por accidente. Existe porque todo el diseño del slice se apoya en condiciones sobre estos hechos, y sin una única fuente de verdad los sistemas se contradirían.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Estado y bus de eventos es la memoria compartida del slice. Guarda en un único sitio cada hecho que el juego necesita recordar —qué has leído, qué puertas has abierto, qué compartimentos de la caja has resuelto, qué carta elegiste, cómo respondiste en la llamada— y avisa a quien le interese cada vez que uno cambia. Son 19 hechos con nombre, tipo y valor inicial (slice, Anexo D.2), más los avisos puntuales que los puzles y las escenas emiten al ocurrir algo (por ejemplo, «puzle resuelto»).

El jugador no lo ve ni lo toca; lo percibe por sus consecuencias: una puerta que ahora se abre, una llamada que empieza con la frase de la carta que escribió, una partida que se reanuda donde la dejó. Existe porque todo el diseño del slice se apoya en condiciones («si tienes `tarjeta_B`…», «si `caja_completa`…»), y sin una fuente única de verdad cada sistema acabaría guardando su propia copia y contradiciendo a las demás.

El sistema solo **registra y anuncia**; nunca decide qué ocurre cuando un hecho cambia. Esas reglas pertenecen a los sistemas que producen o consumen cada hecho (acceso, puzles, llamada…). Su aportación al diseño es doble: garantiza que lo hecho queda hecho y que ningún estado alcanzable deja la historia sin salida (pilar *Tensión sin castigo*), y mantiene los datos del juego fuera de la lógica, de modo que cambiar un valor inicial no exige tocar código (pilar *Información incompleta*).

## Detailed Design

### Core Rules

**Hechos (estado)**

1. **Catálogo cerrado.** Solo existen los hechos declarados en un fichero de datos (`assets/data/state/flags.json`). Cada hecho tiene: nombre, tipo (`bool`, `int` con rango, o `enum` con valores permitidos), valor inicial, sistema dueño (`owner`) y, si procede, una regla de derivación (regla 7). El catálogo inicial son los 19 hechos del Anexo D.2 del slice.
2. **Un único dueño por hecho.** Cada hecho lo escribe un solo sistema (columna «Escribe» de la tabla de interacciones). Cualquier sistema puede leerlo. Un segundo escritor es un error de diseño, no una carrera que resolver: en las builds de desarrollo, una escritura hecha por un sistema distinto del `owner` declarado se trata como inválida (regla 6); en la build final no se comprueba.
3. **Valor actual siempre disponible.** Cualquier sistema puede preguntar el valor de un hecho en cualquier momento, incluido el valor inicial si aún no se ha tocado. El estado es la verdad; los avisos (regla 9) son solo señales de que algo cambió.
4. **Hechos de un solo sentido.** Todos los hechos `bool` y `enum` del catálogo, salvo `pendiente_revelacion`, solo pasan de su valor inicial a un valor final: una vez activados, escribirlos de nuevo con el mismo valor no hace nada, y con otro valor se rechaza y se registra. Los `enum` se fijan una única vez (decisión D-14 para `carta_variante`; mismo criterio para `respuesta_llamada`) y no se puede escribir «sin fijar» una vez fijados. Esta regla no se aplica a la partida nueva (regla 12), a la restauración (regla 13) ni a la consola de desarrollo (regla 15). El rechazo se trata como dice la regla 6. Es lo que hace seguras las reanudaciones y el pilar *Tensión sin castigo*: nada de lo hecho se deshace por accidente.
5. **Hechos reversibles.** Solo cuatro hechos pueden cambiar en ambos sentidos: los `int` `pos_L`, `pos_C` y `pos_R` (rango 1 a 4, inicial 2, los escribe el puzle 2) y el `bool` `pendiente_revelacion` (verdadero mientras la revelación del puzle 5 está interrumpida, falso al completarse).
6. **Escritura inválida.** Escribir un hecho no declarado, un valor fuera de rango o de tipo (sin conversiones: un `float` en un `int` o un `int` en un `bool` son de tipo incorrecto), escribir un hecho derivado, o cambiar un hecho de un solo sentido ya fijado: en desarrollo produce un error visible que detiene la ejecución; en la build final se ignora la escritura, se conserva el valor anterior y se registra una línea en el log.
7. **Hechos derivados.** Un `bool` puede declararse en datos como combinación de otros hechos. Se recalcula automáticamente cuando cambia cualquiera de sus entradas y nadie más lo escribe. En el slice hay uno: `caja_completa` = `caja_c1` y `caja_c2` y `caja_c3` y `caja_c4`. Equivale a lo que dice el slice (B.6) sin depender de que el puzle 6 se acuerde de activarlo.

**Avisos (eventos)**

8. **Qué es un aviso.** Un mensaje puntual, con nombre y datos opcionales, que un sistema emite cuando ocurre algo y que otros reciben. No se guarda: si nadie escuchaba, se pierde. Por eso los sistemas nunca deducen su estado de un aviso que hayan podido perder; lo deducen de los hechos (regla 3).
9. **Aviso automático de cambio.** Cada vez que el valor de un hecho cambia realmente, el sistema emite un aviso con el nombre del hecho, el valor anterior y el nuevo. Escribir el mismo valor que ya había no emite nada. Los sistemas pueden darse de baja en cualquier momento; una baja pedida durante una entrega surte efecto cuando esa entrega termina.
10. **Avisos con nombre del slice.** Los avisos de la lista siguiente se emiten tal como los nombra el slice. El formato técnico (señales, cadenas…) lo fija un ADR; aquí solo se fija el contrato: `EV_PUZZLE_SOLVED_<ID>` (uno por puzle, Anexo B; identificadores propuestos `P1` a `P6`, pendientes de confirmar: ver Open Questions), «puerta abierta» (con el identificador de la puerta), «compartimento completado» (1 a 4), «llamada iniciada» y «llamada completada». Cada sistema emisor documenta en su GDD cuándo emite los suyos.
11. **Orden de entrega.** Los avisos se entregan en el orden en que ocurrieron los cambios; a los suscriptores, en el orden en que se suscribieron. Si un suscriptor, al recibir un aviso, provoca otro cambio, ese cambio se encola y se entrega cuando termine la entrega en curso (sin reentrada).

**Ciclo de vida**

12. **Partida nueva.** Todos los hechos toman su valor inicial y se emite un único aviso «estado restablecido» (no uno por hecho, sin datos). Los avisos que estuvieran pendientes en la cola se descartan.
13. **Instantánea y restauración.** El sistema ofrece (a) una instantánea con el valor de todos los hechos declarados y (b) restaurar desde una instantánea. Restaurar descarta los avisos pendientes en la cola y no emite un aviso por cada hecho: emite uno solo, «estado restaurado» (sin datos), tras el cual cada sistema relee lo que necesita. La instantánea es un mapa nombre → valor con un número de versión; su formato exacto lo fija un ADR. Un hecho que falte en la instantánea toma su valor inicial; uno que ya no esté declarado se ignora y se registra. Quién guarda, cuándo y dónde lo decide el sistema de guardado (5), no este.
14. **Ajustes fuera del estado.** Volumen, subtítulos y remapeo de controles no son hechos del juego: los gestiona el sistema de ajustes (6) y no se incluyen en la instantánea.
15. **Modo de pruebas (solo builds de desarrollo).** Una consola permite ver todos los hechos y forzar su valor, saltándose las reglas 4 y 6, para que QA y los playtests lleguen a cualquier punto sin reiniciar. Cada forzado emite el aviso de cambio normal (regla 9) para que los sistemas reaccionen, y se marca en el log. No existe en la build de la demo. Todo «se registra» de este documento escribe en un destino de log que las pruebas automáticas pueden sustituir.

### States and Transitions

El sistema tiene tres estados de ciclo de vida; cada hecho tiene además su propio recorrido.

| Estado del sistema | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar el juego. Cualquier lectura o escritura es un error. | Listo (al leer el catálogo) |
| **Listo** | Operativo: lecturas, escrituras y avisos permitidos. | Restaurando (al restaurar) · Listo (partida nueva) |
| **Restaurando** | Se aplican valores de una instantánea. No se entregan avisos ni se aceptan escrituras de otros sistemas; las lecturas devuelven el valor que tenía cada hecho antes de empezar. Una nueva restauración o partida nueva pedida en este estado se rechaza y se registra. | Listo, tras emitir «estado restaurado» |

| Tipo de hecho | Recorrido permitido |
|---|---|
| `bool` de un solo sentido | falso → verdadero (no vuelve a falso) |
| `bool` derivado | sigue siempre a su regla: falso → verdadero cuando se cumple; solo puede volver a falso por recálculo (consola de desarrollo o restauración), nunca por escritura |
| `enum` | sin fijar → valor final, una sola vez |
| `int` `pos_L/C/R` | cualquier valor 1 a 4 → cualquier valor 1 a 4 |
| `pendiente_revelacion` | falso ↔ verdadero |

### Interactions with Other Systems

La tabla recoge los 19 hechos del Anexo D.2. «Escribe» y «Lee» son propuestas coherentes con la columna «Se activa en / Se usa en» del slice y se confirmarán cuando se redacte el GDD de cada sistema (marcado ‡ donde el sistema aún no tiene GDD).

| Hecho | Tipo · inicial | Escribe | Lee |
|---|---|---|---|
| `correos_leidos` | bool · falso | 19 Ordenador ‡ | 19 (habilita imprimir) · 11 Puzle 1 |
| `archivo_abierto` | bool · falso | 11 Puzle 1 ‡ | 8 Acceso (puerta A) |
| `formulario_leido` | bool · falso | 20 Documentos ‡ | 17 Pistas |
| `tarjeta_B` | bool · falso | 20 Documentos ‡ | 8 Acceso (lector C06) |
| `tarjeta_D` | bool · falso | 20 Documentos ‡ | 8 Acceso (lector C07) |
| `memo_leido` | bool · falso | 12 Puzle 2 ‡ | 17 Pistas · 21 Director de escenas |
| `pos_L`, `pos_C`, `pos_R` | int 1 a 4 · 2 | 12 Puzle 2 ‡ | 12 Puzle 2 · 5 Guardado |
| `caja_c1` | bool · falso | 13 Puzle 3 ‡ | 10 Caja · 15 Puzle 5 |
| `caja_c2` | bool · falso | 14 Puzle 4 ‡ | 10 Caja · 16 Puzle 6 |
| `caja_c3` | bool · falso | 15 Puzle 5 ‡ | 10 Caja · 16 Puzle 6 |
| `caja_c4` | bool · falso | 16 Puzle 6 ‡ | 10 Caja |
| `pendiente_revelacion` | bool · falso | 15 Puzle 5 ‡ | 15 Puzle 5 · 5 Guardado |
| `caja_completa` | bool derivado · falso | este sistema (regla 7) | 21 Director de escenas (dispara el apagón y la llamada) |
| `carta_variante` | enum A, B, C · sin fijar | 16 Puzle 6 ‡ | 22 Llamada |
| `llamada_iniciada` | bool · falso | 22 Llamada ‡ | 22 Llamada · 5 Guardado |
| `respuesta_llamada` | enum A, B, C, D · sin fijar | 22 Llamada ‡ | 21 Director de escenas (última línea de Vera) |
| `llamada_completada` | bool · falso | 22 Llamada ‡ | 21 Director de escenas (activa el ascensor) |

Otras interacciones:

| Sistema | Qué recibe de este | Qué entrega a este |
|---|---|---|
| 5 Guardado y carga | Instantánea de todos los hechos; aviso «estado restaurado» | Una instantánea que restaurar |
| 4 Escena de planta | Valor actual de los hechos al cargar la escena, para ponerla en su estado | — |
| 23 Audio, 28 Atmósfera, 26 Subtítulos, 27 Título | Avisos de cambio y de eventos con nombre a los que se suscriben | — |
| 6 Ajustes | Nada (los ajustes quedan fuera, regla 14) | — |

## Edge Cases

**Escrituras y orden**
- **If un sistema escribe un hecho mientras el sistema está en «Restaurando»**: la escritura se rechaza (no se encola) y se registra; la restauración continúa sin interferencias.
- **If un suscriptor, al recibir un aviso, escribe otro hecho**: el cambio se encola y se entrega al terminar la entrega en curso (regla 11). Un tope de seguridad de avisos encadenados por fotograma (valor a fijar en el ADR) corta cualquier bucle entre hechos reversibles: al alcanzarlo se descarta el resto de la cola, se registra y, en desarrollo, se detiene la ejecución.
- **If un hecho cambia y con él cambia un hecho derivado** (p. ej. `caja_c4` y `caja_completa`): el aviso del hecho de entrada se entrega antes que el del derivado.
- **If dos sistemas escriben hechos distintos en el mismo fotograma**: se procesan en el orden en que llegaron; los derivados se recalculan tras cada escritura.
- **If se emite dos veces el mismo aviso con nombre** (p. ej. un puzle reintenta): no se deduplica. Los receptores basan su lógica en los hechos, no en contar avisos; los cambios de hecho sí son idempotentes (regla 9).
- **If se escribe un hecho con un nombre mal escrito o con otra capitalización**: es un hecho no declarado (regla 6); los nombres distinguen mayúsculas.

**Restauración e instantáneas**
- **If la instantánea trae `caja_completa` distinto del resultado de `caja_c1`…`caja_c4`**: se ignora el valor guardado del derivado y se recalcula desde sus entradas.
- **If la instantánea trae un `enum` con un valor no permitido**: ese hecho queda «sin fijar» y se registra.
- **If la instantánea trae un `pos_*` fuera de 1 a 4**: toma el valor inicial (2) y se registra.
- **If la instantánea trae `llamada_iniciada` verdadero y `llamada_completada` falso**: es un estado válido (la partida se cerró durante la llamada); se restaura tal cual y el sistema de llamada (22) reanuda (slice D.3).
- **If la instantánea trae una combinación incoherente entre hechos** (p. ej. `llamada_completada` verdadero con `llamada_iniciada` falso): se restaura tal cual, sin corregir, y se registra una advertencia; corregir en silencio podría deshacer progreso real.
- **If falta el fichero de instantánea o no se puede leer**: no es responsabilidad de este sistema; el sistema de guardado (5) decide y, si se empieza partida nueva, se aplica la regla 12.

**Arranque y datos**
- **If se lee o escribe un hecho antes de que el catálogo esté cargado** («Sin cargar»): en desarrollo, error visible; en la build final, la lectura devuelve el valor neutro del tipo (falso, 0 o sin fijar), la escritura se descarta y se registra.
- **If el fichero de catálogo falta o está corrupto al arrancar**: el juego no entra en la partida; muestra un mensaje de error claro y se cierra. No se arranca con un catálogo parcial.
- **If un sistema se descarga con la escena (p. ej. al pasar a Recepción) mientras está suscrito**: deja de recibir avisos sin que haga falta darse de baja y sin errores.

- **If se lee un hecho no declarado en estado «Listo»**: en desarrollo, error visible; en la build final devuelve el valor neutro del tipo (falso, 0 o sin fijar) y se registra.

**Guardado y pruebas**
- **If el sistema de guardado (5) pide una instantánea mientras hay avisos pendientes de entregar**: espera a que la cola esté vacía, de modo que la instantánea nunca contiene un cambio a medias (p. ej. `caja_c4` sin su derivado `caja_completa`).
- **If en la consola de desarrollo se fuerza un hecho de un solo sentido a su valor anterior**: se permite (regla 15), se marca en el log y se recalculan los derivados; el estado de las escenas ya cargadas no se garantiza coherente, y para una prueba limpia se recarga la partida.
- **If la consola de desarrollo existe en la build de la demo**: es un defecto; la comprobación de builds de entrega debe fallar si la encuentra (ver Acceptance Criteria).

## Dependencies

**Aguas arriba (de qué depende):** ninguna. Solo necesita su fichero de catálogo (`assets/data/state/flags.json`, definido por este GDD) y la capacidad del motor de leer datos al arrancar.

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él pero el resto de su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 4 Escena de planta | Dura | Lee hechos al cargar la escena para dejarla en su estado |
| 5 Guardado y carga | Dura | Pide instantánea, restaura, escucha «estado restaurado» |
| 8 Control de acceso | Dura | Lee `archivo_abierto`, `tarjeta_B`, `tarjeta_D`, `llamada_completada` |
| 9 Marco de puzles | Dura | Escribe hechos de puzle; emite `EV_PUZZLE_SOLVED_<ID>` |
| 10 Caja y compartimentos | Dura | Lee `caja_c1` a `caja_c4` para las dependencias entre compartimentos |
| 19 Ordenador, correo e impresora | Dura | Escribe `correos_leidos` |
| 20 Documentos y bolsillo | Dura | Escribe `formulario_leido`, `tarjeta_B`, `tarjeta_D` |
| 21 Director de escenas | Dura | Lee `caja_completa`, `respuesta_llamada`, `llamada_completada`, `memo_leido` |
| 22 Llamada telefónica | Dura | Lee `carta_variante`; escribe `llamada_iniciada`, `respuesta_llamada`, `llamada_completada` |
| 23 Director de audio | Blanda | Se suscribe a avisos |
| 27 Pantalla de título y cierre | Blanda | Lee hechos para detectar partida en curso |
| 28 Atmósfera reactiva | Blanda | Se suscribe a avisos (apagón, parpadeo, reflejo) |
| 11 a 16 Puzles | Indirecta (vía 9) | Escriben y leen sus hechos a través del marco de puzles |
| 17 Sistema de pistas | Dura (**no está en el índice**) | Lee `formulario_leido` y `memo_leido` |

**Corrección pendiente en el índice de sistemas:** el sistema 17 (Pistas) lee hechos pero su fila de dependencias en `design/gdd/systems-index.md` no incluye el sistema 3. Se añade al cerrar este GDD (Fase 5).

**Bidireccionalidad.** Ninguno de los sistemas dependientes tiene GDD aún. Cada uno debe, al redactarse, listar este sistema como dependencia y registrar los hechos que escribe o lee con el mismo nombre que figura en la tabla de «Interacciones con otros sistemas».

## Visual/Audio Requirements

Ninguno. El sistema no tiene presentación propia: lo que el jugador ve y oye lo producen los sistemas que reaccionan a sus avisos (audio 23, atmósfera 28, subtítulos 26). *(Sección opcional para la categoría Core; no se consulta a `art-director`.)*

## Game Feel

No aplica: el jugador no opera este sistema directamente. Lo único exigible es que un cambio de hecho llegue a sus suscriptores en el mismo fotograma en que se produce, salvo cuando se encola por la regla 11.

## UI Requirements

Ninguno para el jugador. La consola de desarrollo (regla 15) es una herramienta interna, solo existe en builds de desarrollo y queda fuera de los requisitos de UI del juego.

## Cross-References

Ningún otro GDD existe todavía; las referencias son a documentos de diseño ya escritos. Cuando se redacten los GDD de los sistemas dependientes, este cuadro debe ampliarse con ellos.

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · Anexo D.2 | Lista de los 19 hechos, tipos y valores iniciales | Fuente de los datos de `flags.json`; si cambia, hay que actualizar el catálogo |
| `design/slice/slice-v0.3.md` · Anexo B | `EV_PUZZLE_SOLVED_<ID>`, dependencias de la caja (B.6: `caja_completa`) | Define los avisos de puzle y el hecho derivado |
| `design/slice/slice-v0.3.md` · §13.2 y D.3 | Puntos de autoguardado y reanudaciones | Condiciona la instantánea (reglas 13 y 14) |
| `design/slice/slice-v0.3.md` · D-14, D-15, D-16 | Carta permanente; silencio en la llamada; orden de la caja | Justifican hechos de un solo sentido y `caja_completa` derivado |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Información incompleta* | Pilares que este sistema sirve |
| `design/gdd/systems-index.md` | Fila 3 y dependencias de los sistemas 4, 5, 8, 9, 10, 17, 19–23, 27, 28 | Debe reflejar la tabla de Dependencies (ver Open Questions) |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/state/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante. Este sistema no define fórmulas ni valores de equilibrio, así que no hay criterios de ese tipo; tampoco define un presupuesto de rendimiento, por lo que no se propone ninguno.

**Hechos (reglas 1 a 7)**
- **CA-01 (L)**: **GIVEN** el fichero de catálogo, **WHEN** el sistema carga, **THEN** existen exactamente 19 hechos y cada uno devuelve su valor inicial del Anexo D.2.
- **CA-02 (L)**: **GIVEN** un hecho sin tocar, **WHEN** se lee, **THEN** devuelve su inicial; **GIVEN** que su dueño escribe un valor válido, **WHEN** se lee, **THEN** devuelve el nuevo.
- **CA-03 (L)**: **GIVEN** `tarjeta_B` verdadero, **WHEN** se escribe verdadero, **THEN** no se emite aviso; **WHEN** se escribe falso, **THEN** se rechaza, el valor sigue verdadero y se añade una línea al log.
- **CA-04 (L)**: **GIVEN** `carta_variante` = B, **WHEN** se escribe C o «sin fijar», **THEN** se rechaza y sigue en B. Idéntico para `respuesta_llamada`.
- **CA-05 (L)**: **GIVEN** `pos_L` = 2, **WHEN** se escribe 4 y luego 1, **THEN** ambas se aceptan; **GIVEN** `pendiente_revelacion` verdadero, **WHEN** se escribe falso, **THEN** se acepta.
- **CA-06 (L)**: **GIVEN** la build final, **WHEN** se escribe un hecho no declarado, `Tarjeta_B` (otra capitalización), `pos_L` = 5, un `bool` con una cadena o un `float` en un `int`, **THEN** el valor anterior se conserva y se añade exactamente una línea al log. **GIVEN** una build de desarrollo, **THEN** se detiene la ejecución (I).
- **CA-07 (L)**: **GIVEN** `caja_c1` a `caja_c3` verdaderos y `caja_c4` falso, **WHEN** se escribe `caja_c4` verdadero, **THEN** `caja_completa` pasa a verdadero; **WHEN** un sistema intenta escribir `caja_completa` directamente, **THEN** se rechaza (regla 6).
- **CA-08 (L)**: **GIVEN** un hecho cuyo `owner` es el sistema X, **WHEN** en una build de desarrollo escribe el sistema Y, **THEN** se trata como escritura inválida; **WHEN** lo hace la build final, **THEN** no se comprueba el dueño.

**Avisos (reglas 8 a 11)**
- **CA-09 (L)**: **GIVEN** un aviso emitido sin suscriptores, **WHEN** alguien se suscribe después, **THEN** no lo recibe y los hechos no cambian.
- **CA-10 (L)**: **GIVEN** un suscriptor, **WHEN** un hecho cambia, **THEN** lo recibe exactamente una vez con (nombre, valor anterior, valor nuevo); **WHEN** se escribe el mismo valor, **THEN** no recibe nada.
- **CA-11 (I)**: **GIVEN** un suscriptor, **WHEN** se emite `EV_PUZZLE_SOLVED_P1`…`P6`, «puerta abierta» (con identificador), «compartimento completado» (1 a 4), «llamada iniciada» o «llamada completada», **THEN** lo recibe con su nombre y datos.
- **CA-12 (L)**: **GIVEN** los suscriptores A y B (en ese orden), **WHEN** cambia un hecho, **THEN** reciben en el orden A, B; dos cambios sucesivos se entregan en el orden en que ocurrieron.
- **CA-13 (L)**: **GIVEN** un suscriptor que, al recibir el aviso de X, escribe Y, **WHEN** cambia X, **THEN** el aviso de Y se entrega después de que X llegue a todos los suscriptores (sin reentrada).
- **CA-14 (L)**: **GIVEN** `caja_c1` a `caja_c3` verdaderos, **WHEN** `caja_c4` pasa a verdadero, **THEN** el aviso de `caja_c4` llega antes que el de `caja_completa`.
- **CA-15 (L)**: **GIVEN** un bucle de escrituras entre hechos reversibles que supera el tope de avisos encadenados, **WHEN** se alcanza el tope, **THEN** se descarta el resto de la cola y se registra (valor del tope fijado por el ADR; en desarrollo se detiene la ejecución).
- **CA-16 (L)**: **GIVEN** un suscriptor que se da de baja durante una entrega, **WHEN** termina esa entrega, **THEN** no recibe ningún aviso posterior.
- **CA-17 (I)**: **GIVEN** un nodo suscrito, **WHEN** se libera junto con su escena, **THEN** el siguiente cambio de hecho no produce errores.

**Ciclo de vida, instantáneas y arranque (reglas 12 a 14)**
- **CA-18 (L)**: **GIVEN** progreso arbitrario y avisos pendientes, **WHEN** empieza partida nueva, **THEN** los 19 hechos valen su inicial, la cola queda vacía y se emite un único «estado restablecido» sin avisos de cambio por hecho.
- **CA-19 (L)**: **GIVEN** una instantánea del estado A, **WHEN** se restaura en una instancia limpia, **THEN** los 19 valores coinciden con A y se emite un único «estado restaurado».
- **CA-20 (L)**: **GIVEN** una instantánea sin `tarjeta_D` y con un hecho que ya no está declarado, **WHEN** se restaura, **THEN** `tarjeta_D` toma su inicial y el hecho sobrante se ignora con una línea en el log.
- **CA-21 (L)**: **GIVEN** una instantánea con `caja_completa` incoherente, un `enum` inválido y `pos_C` = 9, **WHEN** se restaura, **THEN** `caja_completa` se recalcula, el `enum` queda sin fijar (con log) y `pos_C` vale 2 (con log).
- **CA-22 (L)**: **GIVEN** `llamada_iniciada` verdadero y `llamada_completada` falso, **WHEN** se restaura, **THEN** se conservan tal cual sin advertencia; **GIVEN** `llamada_completada` verdadero y `llamada_iniciada` falso, **THEN** se conservan con una advertencia en el log.
- **CA-23 (L)**: **GIVEN** el estado «Restaurando», **WHEN** otro sistema escribe, **THEN** la escritura se rechaza (no se encola) y se registra; **WHEN** lee, **THEN** obtiene el valor previo a la restauración; **WHEN** pide una partida nueva o una restauración, **THEN** se rechaza y se registra.
- **CA-24 (L)**: **GIVEN** una instantánea, **THEN** sus claves son exactamente las 19 del catálogo, sin ajustes de volumen, subtítulos ni controles.
- **CA-25 (I)**: **GIVEN** avisos pendientes, **WHEN** el sistema de guardado (5) pide una instantánea, **THEN** se entrega con la cola vacía y nunca contiene `caja_c4` sin `caja_completa`.
- **CA-26 (I)**: **GIVEN** un fichero de catálogo ausente o corrupto, **WHEN** arranca el juego, **THEN** no entra en la partida, muestra un mensaje de error claro y se cierra.
- **CA-27 (L)**: **GIVEN** la build final y el estado «Sin cargar» (o un hecho no declarado en «Listo»), **WHEN** se lee, **THEN** devuelve el valor neutro (falso, 0 o sin fijar) con una línea en el log; **WHEN** se escribe, **THEN** la escritura se descarta.

**Modo de pruebas (regla 15)**
- **CA-28 (I)**: **GIVEN** una build de desarrollo, **WHEN** la consola fuerza `tarjeta_B` a falso, **THEN** se permite, se registra, se emite el aviso de cambio y se recalculan los derivados.
- **CA-29 (I)**: **GIVEN** el export de la demo, **THEN** la verificación de la build falla si encuentra la consola de desarrollo.

**Interacciones entre sistemas**
- **CA-30 (I)**: **GIVEN** una partida nueva, **WHEN** el jugador completa el slice por el camino previsto, **THEN** cada hecho de la tabla de «Interacciones con otros sistemas» cambia únicamente a manos de su sistema escritor y los avisos de puerta, compartimento y llamada que consume el guardado (5) se emiten una vez cada uno.

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Identificadores de los puzles** para `EV_PUZZLE_SOLVED_<ID>`: se proponen `P1` a `P6`; el slice no los enumera. | Autor / `/design-system` del marco de puzles (9) | GDD del sistema 9 |
| 2 | **Tope de avisos encadenados** por fotograma y **formato de la instantánea** (mapa nombre → valor + versión). | `/architecture-decision` | Fase de arquitectura |
| 3 | **Mecanismo del `owner`**: cómo se identifica al sistema escritor en desarrollo sin acoplar los sistemas. | `/architecture-decision` | Fase de arquitectura |
| 4 | **Escritores y lectores de la tabla de interacciones**: son propuestas (‡); cada GDD dependiente debe confirmarlas o corregirlas. | GDD de cada sistema dependiente | Al redactar cada uno |
| 5 | **Índice de sistemas**: añadir el sistema 3 como dependencia del sistema 17 (Pistas), que lee `formulario_leido` y `memo_leido`. | Este GDD (cierre) | Ahora |
| 6 | ¿`memo_leido` debe leerlo el director de escenas (21)? El slice solo dice «pistas, recompensa de B». | `/design-system` del sistema 21 | GDD del sistema 21 |
| 7 | **Destino de log inyectable** para las pruebas («se registra» verificable). | `/architecture-decision` | Fase de arquitectura |
