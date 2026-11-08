# Estado del juego y bus de eventos

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Tensión sin castigo (sin softlock) · Autonomía como progresión (estado en banderas) · Información incompleta (datos fuera del código)

## Summary

[To be designed]

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Estado y bus de eventos es la memoria compartida del slice. Guarda en un único sitio cada hecho que el juego necesita recordar —qué has leído, qué puertas has abierto, qué compartimentos de la caja has resuelto, qué carta elegiste, cómo respondiste en la llamada— y avisa a quien le interese cada vez que uno cambia. Son 19 hechos con nombre, tipo y valor inicial (slice, Anexo D.2), más los avisos puntuales que los puzles y las escenas emiten al ocurrir algo (por ejemplo, «puzle resuelto»).

El jugador no lo ve ni lo toca; lo percibe por sus consecuencias: una puerta que ahora se abre, una llamada que empieza con la frase de la carta que escribió, una partida que se reanuda donde la dejó. Existe porque todo el diseño del slice se apoya en condiciones («si tienes `tarjeta_B`…», «si `caja_completa`…»), y sin una fuente única de verdad cada sistema acabaría guardando su propia copia y contradiciendo a las demás.

El sistema solo **registra y anuncia**; nunca decide qué ocurre cuando un hecho cambia. Esas reglas pertenecen a los sistemas que producen o consumen cada hecho (acceso, puzles, llamada…). Su aportación al diseño es doble: garantiza que lo hecho queda hecho y que ningún estado alcanzable deja la historia sin salida (pilar *Tensión sin castigo*), y mantiene los datos del juego fuera de la lógica, de modo que cambiar un valor inicial no exige tocar código (pilar *Información incompleta*).

## Detailed Design

### Core Rules

**Hechos (estado)**

1. **Catálogo cerrado.** Solo existen los hechos declarados en un fichero de datos (`assets/data/state/flags.json`). Cada hecho tiene: nombre, tipo (`bool`, `int` con rango, o `enum` con valores permitidos), valor inicial y, si procede, una regla de derivación (regla 7). El catálogo inicial son los 19 hechos del Anexo D.2 del slice.
2. **Un único dueño por hecho.** Cada hecho lo escribe un solo sistema (columna «Escribe» de la tabla de interacciones). Cualquier sistema puede leerlo. Un segundo escritor es un error de diseño, no una carrera que resolver.
3. **Valor actual siempre disponible.** Cualquier sistema puede preguntar el valor de un hecho en cualquier momento, incluido el valor inicial si aún no se ha tocado. El estado es la verdad; los avisos (regla 9) son solo señales de que algo cambió.
4. **Hechos de un solo sentido.** Todos los hechos `bool` y `enum` del catálogo, salvo `pendiente_revelacion`, solo pasan de su valor inicial a un valor final: una vez activados, escribirlos de nuevo con el mismo valor no hace nada, y con otro valor se rechaza y se registra. Los `enum` se fijan una única vez (decisiones D-14 para `carta_variante`; mismo criterio para `respuesta_llamada`). Es lo que hace seguras las reanudaciones y el pilar *Tensión sin castigo*: nada de lo hecho se deshace por accidente.
5. **Hechos reversibles.** Solo tres tipos pueden cambiar en ambos sentidos: los `int` `pos_L`, `pos_C` y `pos_R` (rango 1 a 4, inicial 2, los escribe el puzle 2) y el `bool` `pendiente_revelacion` (verdadero mientras la revelación del puzle 5 está interrumpida, falso al completarse).
6. **Escritura inválida.** Escribir un hecho no declarado, un valor fuera de rango o de tipo, o cambiar un hecho de un solo sentido ya fijado: en desarrollo produce un error visible que detiene la ejecución; en la build final se ignora la escritura, se conserva el valor anterior y se registra una línea en el log.
7. **Hechos derivados.** Un `bool` puede declararse en datos como combinación de otros hechos. Se recalcula automáticamente cuando cambia cualquiera de sus entradas y nadie más lo escribe. En el slice hay uno: `caja_completa` = `caja_c1` y `caja_c2` y `caja_c3` y `caja_c4`. Equivale a lo que dice el slice (B.6) sin depender de que el puzle 6 se acuerde de activarlo.

**Avisos (eventos)**

8. **Qué es un aviso.** Un mensaje puntual, con nombre y datos opcionales, que un sistema emite cuando ocurre algo y que otros reciben. No se guarda: si nadie escuchaba, se pierde. Por eso los sistemas nunca deducen su estado de un aviso que hayan podido perder; lo deducen de los hechos (regla 3).
9. **Aviso automático de cambio.** Cada vez que el valor de un hecho cambia realmente, el sistema emite un aviso con el nombre del hecho, el valor anterior y el nuevo. Escribir el mismo valor que ya había no emite nada.
10. **Avisos con nombre del slice.** Los avisos de la lista siguiente se emiten tal como los nombra el slice. El formato técnico (señales, cadenas…) lo fija un ADR; aquí solo se fija el contrato: `EV_PUZZLE_SOLVED_<ID>` (uno por puzle, Anexo B), «puerta abierta» (con el identificador de la puerta), «compartimento completado» (1 a 4), «llamada iniciada» y «llamada completada». Cada sistema emisor documenta en su GDD cuándo emite los suyos.
11. **Orden de entrega.** Los avisos se entregan en el orden en que ocurrieron los cambios; a los suscriptores, en el orden en que se suscribieron. Si un suscriptor, al recibir un aviso, provoca otro cambio, ese cambio se encola y se entrega cuando termine la entrega en curso (sin reentrada).

**Ciclo de vida**

12. **Partida nueva.** Todos los hechos toman su valor inicial y se emite un único aviso «estado restablecido» (no uno por hecho).
13. **Instantánea y restauración.** El sistema ofrece (a) una instantánea con el valor de todos los hechos declarados y (b) restaurar desde una instantánea. Restaurar no emite un aviso por cada hecho: emite uno solo, «estado restaurado», tras el cual cada sistema relee lo que necesita. Un hecho que falte en la instantánea toma su valor inicial; uno que ya no esté declarado se ignora y se registra. Quién guarda, cuándo y dónde lo decide el sistema de guardado (5), no este.
14. **Ajustes fuera del estado.** Volumen, subtítulos y remapeo de controles no son hechos del juego: los gestiona el sistema de ajustes (6) y no se incluyen en la instantánea.
15. **Modo de pruebas (solo builds de desarrollo).** Una consola permite ver todos los hechos y forzar su valor, saltándose las reglas 4 y 6, para que QA y los playtests lleguen a cualquier punto sin reiniciar. Se marca en el log cada forzado. No existe en la build de la demo.

### States and Transitions

El sistema tiene tres estados de ciclo de vida; cada hecho tiene además su propio recorrido.

| Estado del sistema | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar el juego. Cualquier lectura o escritura es un error. | Listo (al leer el catálogo) |
| **Listo** | Operativo: lecturas, escrituras y avisos permitidos. | Restaurando (al restaurar) · Listo (partida nueva) |
| **Restaurando** | Se aplican valores de una instantánea. No se entregan avisos ni se aceptan escrituras de otros sistemas. | Listo, tras emitir «estado restaurado» |

| Tipo de hecho | Recorrido permitido |
|---|---|
| `bool` de un solo sentido | falso → verdadero (no vuelve a falso) |
| `bool` derivado | falso → verdadero cuando se cumple su regla (no lo escribe nadie más) |
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

[To be designed]

## Game Feel

[To be designed]

## UI Requirements

[To be designed]

## Cross-References

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
