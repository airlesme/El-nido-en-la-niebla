# Estado del juego y bus de eventos

> **Status**: Revisado (ronda de corrección 2) — pendiente de re-review
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Tensión sin castigo (sin softlock) · Autonomía como progresión (estado en banderas) · Información incompleta (datos fuera del código)

## Summary

Es la memoria compartida del slice: guarda los 20 hechos que el juego debe recordar (qué has leído, qué puertas abriste, qué carta elegiste…) y avisa a los demás sistemas cuando uno cambia. El jugador no lo ve, pero es lo que hace que sus acciones tengan consecuencias visibles y que la partida se reanude donde la dejó, sin que nada hecho pueda deshacerse por accidente. Existe porque todo el diseño del slice se apoya en condiciones sobre estos hechos, y sin una única fuente de verdad los sistemas se contradirían.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Estado y bus de eventos es la memoria compartida del slice. Guarda en un único sitio cada hecho que el juego necesita recordar —qué has leído, qué puertas has abierto, qué compartimentos de la caja has resuelto, qué carta elegiste, cómo respondiste en la llamada— y avisa a quien le interese cada vez que uno cambia. Son 20 hechos con nombre, tipo y valor inicial (slice, Anexo D.2; el vigésimo, `t4_decision`, es la decisión D-B1 pendiente de recoger en el slice), más los avisos puntuales que los puzles y las escenas emiten al ocurrir algo (por ejemplo, «puzle resuelto»).

El jugador no lo ve ni lo toca; lo percibe por sus consecuencias: una puerta que ahora se abre, una llamada que empieza con la frase de la carta que escribió, una partida que se reanuda donde la dejó. Existe porque todo el diseño del slice se apoya en condiciones («si tienes `tarjeta_B`…», «si `caja_completa`…»), y sin una fuente única de verdad cada sistema acabaría guardando su propia copia y contradiciendo a las demás.

El sistema solo **registra y anuncia**; nunca decide qué ocurre cuando un hecho cambia. Esas reglas pertenecen a los sistemas que producen o consumen cada hecho (acceso, puzles, llamada…). Su aportación al diseño es doble: garantiza que lo hecho queda hecho y que ningún estado alcanzable deja la historia sin salida (pilar *Tensión sin castigo*), y mantiene los datos del juego fuera de la lógica, de modo que cambiar un valor inicial no exige tocar código (pilar *Información incompleta*).

## Detailed Design

### Core Rules

**Hechos (estado)**

1. **Catálogo cerrado.** Solo existen los hechos declarados en un fichero de datos (`assets/data/state/flags.json`). Cada hecho tiene: nombre, tipo (`bool`, `int` con rango, o `enum` con valores permitidos), valor inicial, sistema dueño (`owner`) y, si procede, una regla de derivación (regla 7). El catálogo inicial son los 20 hechos del Anexo D.2 del slice (incluido `t4_decision`).
2. **Un único dueño por hecho.** Cada hecho lo escribe un solo sistema (columna «Escribe» de la tabla de interacciones). **Los hechos de puzle** (`archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1` a `caja_c4`, `pendiente_revelacion`, `carta_variante`, `t4_decision`) tienen `owner = 9` (Marco de puzles): los puzles 11 a 16 los escriben solo a través del marco (GDD 9, regla 1 y D9-4). Cualquier sistema puede leerlo. Un segundo escritor es un error de diseño, no una carrera que resolver: en las builds de desarrollo, una escritura hecha por un sistema distinto del `owner` declarado se trata como inválida (regla 6); en la build final no se comprueba.
3. **Valor actual siempre disponible.** Cualquier sistema puede preguntar el valor de un hecho en cualquier momento, incluido el valor inicial si aún no se ha tocado. El estado es la verdad; los avisos (regla 9) son solo señales de que algo cambió. **Una escritura válida se aplica en el instante en que se hace** (y los derivados se recalculan en el acto, regla 7), incluso si se produce durante una entrega de avisos: lo único que puede esperar es el aviso (regla 11), nunca el valor. Una lectura inmediatamente posterior a una escritura devuelve siempre el valor nuevo.
4. **Hechos de un solo sentido.** Todos los hechos `bool` y `enum` del catálogo, salvo `pendiente_revelacion`, solo pasan de su valor inicial a un valor final: una vez activados, escribirlos de nuevo con el mismo valor no hace nada, y con otro valor se rechaza y se registra. Los `enum` se fijan una única vez (decisión D-14 para `carta_variante`; mismo criterio para `respuesta_llamada` y `t4_decision`) y no se puede escribir «sin fijar» una vez fijados. Esta regla no se aplica a la partida nueva (regla 12), a la restauración (regla 13) ni a la consola de desarrollo (regla 15). El rechazo se trata como dice la regla 6. Es lo que hace seguras las reanudaciones y el pilar *Tensión sin castigo*: nada de lo hecho se deshace por accidente.
5. **Hechos reversibles.** Solo cuatro hechos pueden cambiar en ambos sentidos: los `int` `pos_L`, `pos_C` y `pos_R` (rango 1 a 4, inicial 2, los escribe el puzle 2) y el `bool` `pendiente_revelacion` (verdadero desde que el marco (9) **inicia** la revelación del puzle 5, falso cuando esta se completa; si el jugador cierra a mitad, el hecho queda verdadero y la revelación se reanuda. Confirma el desvío del GDD 9 sobre el texto «si se interrumpe» del slice D.2; ver «Decisiones tomadas», DT-1).
6. **Escritura inválida.** Escribir un hecho no declarado, un valor fuera de rango o de tipo (sin conversiones: un `float` en un `int` o un `int` en un `bool` son de tipo incorrecto), escribir un hecho derivado, o cambiar un hecho de un solo sentido ya fijado: en desarrollo produce un error visible que detiene la ejecución; en la build final se ignora la escritura, se conserva el valor anterior y se registra una línea en el log.
7. **Hechos derivados.** Un `bool` puede declararse en datos como combinación de otros hechos. Se recalcula automáticamente cuando cambia cualquiera de sus entradas y nadie más lo escribe. En el slice hay uno: `caja_completa` = `caja_c1` y `caja_c2` y `caja_c3` y `caja_c4`. Equivale a lo que dice el slice (B.6) sin depender de que el puzle 6 se acuerde de activarlo.

**Avisos (eventos)**

8. **Qué es un aviso.** Un mensaje puntual, con nombre y datos opcionales, que un sistema emite cuando ocurre algo y que otros reciben. No se guarda: si nadie escuchaba, se pierde. Por eso los sistemas nunca deducen su estado de un aviso que hayan podido perder; lo deducen de los hechos (regla 3).
9. **Aviso automático de cambio.** Cada vez que el valor de un hecho cambia realmente, el sistema emite un aviso con el nombre del hecho, el valor anterior y el nuevo. Escribir el mismo valor que ya había no emite nada. Se admite suscribirse a **un hecho concreto**, a **todos los cambios de hecho** o a **un aviso con nombre** (el filtrado por nombre lo hace el bus, no el suscriptor); el marco de puzles (9) usa la suscripción por hecho para los de `requires.all`. Los sistemas pueden darse de baja en cualquier momento; una baja pedida durante una entrega surte efecto cuando esa entrega termina.
10. **Avisos con nombre.** Los avisos de la lista siguiente se emiten tal como los nombra su emisor. El formato técnico (señales, cadenas…) lo fija un ADR; aquí solo se fija el contrato (nombre y datos). Cada sistema emisor documenta en su GDD cuándo emite los suyos. Un emisor no declarado aquí es un defecto de documentación.

    | Emisor | Avisos (datos) |
    |---|---|
    | **Este sistema (3)** | «estado restablecido» (regla 12), «estado restaurado» (regla 13), «avisos descartados» (Edge Cases, tope de cadena; Guardado lo trata como la causa `notices_dropped`); todos sin datos |
    | **1 Entrada** | «dispositivo de entrada cambiado» (teclado/ratón o mando), «contexto de entrada cambiado», «`sin control` absorbido» (dato: el dueño descartado, p. ej. el 21; al aceptar una carga `partida_nueva`/`continuar` con un `sin control` ajeno en la pila, Entrada regla 6) |
    | **4 Escena de planta** | «carga de escena iniciada» (destino, `motivo`, `D_carga`; Entrada necesita `D_carga` para el tope del `sin control`), «escena lista» (destino), «carga de escena terminada» (sin datos), «descarga total solicitada» (sin datos; la emite 4 al aceptar la petición de volver al título, regla 15 de 4; el 21 queda inactivo desde este aviso hasta «descarga total completada»), «descarga total completada» (sin datos; la emite 4 al terminar la descarga de la escena al volver al título; la consume 5 para su re-inspección, regla 17 de 5), «carga de escena fallida» (destino, `motivo`, causa), «zona activada» (ID `T-…`; se emite en cada entrada), «partida terminada» (sin datos; **único emisor**, en el fotograma de «carga de escena terminada» de `recepcion`, nunca en «iniciada»; GDD 4 regla 16) |
    | **5 Guardado** | «guardado en riesgo» (tras `n_fallos_aviso` fallos seguidos de escritura), «guardado restablecido» (primera escritura con éxito después); sin datos |
    | **7 Interacción** | «vista cercana abierta/cerrada», «lectura completada», «lectura cerrada», «lectura abierta», «lectura descartada», «modos cerrados» (al vaciar la pila de modos; lo espera 21 antes de pedir `sin control`), «interacción ejecutada» |
    | **8 Control de acceso** | «puerta abierta» (identificador `A`, `B` o `D`; una vez por apertura real, al empezar `ABRIÉNDOSE`; GDD 8 regla 11), «ascensor llamado» (sin datos; una por aceptación de `interact(Entrar)`; **receptor 21**), «línea pedida» (`MEGA_03`, con el mismo contrato que 9). **8 no escribe ningún hecho** |
    | **21 Director de escenas** | «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida», «línea pedida» (como 9 y 8), «ascensor rechazado» (sin datos; la emite cuando 4 rechaza `recepcion` tras «ascensor llamado»; **receptor 8**, que devuelve `C08` a `LISTO`; GDD 21 regla 17) |
    | **9 Marco de puzles** | `EV_PUZZLE_SOLVED_<ID>` (uno por puzle, Anexo B; identificadores `P1` a `P6`, confirmados por el GDD 9, D9-13), «compartimento completado» (1 a 4), «puzle activado», «resolución de puzle interrumpida», «pista aplicada», «puzle inactivo», «feedback de puzle», «línea pedida» (también la emiten 8 y 21) |
    | **22 Llamada** ‡ | «llamada iniciada», «llamada completada» |
    | **23 Audio** ‡ | «línea terminada», «línea sin audio», «línea fallida» (respuestas a «línea pedida», con el identificador de la línea) |
    | **25 Menú de pausa** ‡ | `pause_opened` (sin datos) |

    **Fuera del bus.** Ajustes (6) tiene un mecanismo de aviso propio con las mismas reglas de entrega (su regla 7) que **no pasa por este bus** y no figura en la tabla; el ADR de avisos debe cubrir ambos con un único mecanismo. El Jugador (2) no usa el bus (sus pasos y gestos son señales directas).
11. **Orden de entrega.** Los avisos se entregan en el orden en que ocurrieron los cambios; a los suscriptores, en el orden en que se suscribieron. Si un suscriptor, al recibir un aviso, provoca otro cambio, el valor se aplica en el acto (regla 3) y solo el **aviso** de ese cambio se encola, para entregarse cuando termine la entrega en curso (sin reentrada). Una partida nueva o una restauración pedida desde dentro de una entrega se aplica al terminar esta; la cola pendiente se descarta entonces como dicen las reglas 12 y 13.

**Ciclo de vida**

12. **Partida nueva.** Todos los hechos toman su valor inicial y se emite un único aviso «estado restablecido» (no uno por hecho, sin datos). **Tras restablecer, el contenido resultante (la instantánea del estado inicial) es obtenible con la petición de instantánea de la regla 13**: Guardado (5) lo usa como línea base de `dif` de «Nueva partida» (GDD 5, reglas 7 y 24). Los avisos que estuvieran pendientes en la cola se descartan.
13. **Instantánea y restauración.** El sistema ofrece (a) una instantánea con el valor de todos los hechos declarados y (b) restaurar desde una instantánea. Restaurar descarta los avisos pendientes en la cola y no emite un aviso por cada hecho: emite uno solo, «estado restaurado» (sin datos), tras el cual cada sistema relee lo que necesita. La instantánea es un mapa nombre → valor con un número de versión (`snapshot_version`); su formato exacto lo fija un ADR. **El sistema expone la `snapshot_version` que conoce** (consulta de solo lectura) para que Guardado (5) detecte instantáneas de una versión futura (GDD 5, regla 20); valor inicial `1`. Un hecho que falte en la instantánea toma su valor inicial; uno que ya no esté declarado se ignora y se registra. **Tipos al restaurar** (más tolerante que la escritura de la regla 6, porque la instantánea llega de un fichero JSON): un valor numérico con parte fraccionaria nula (p. ej. `2.0`) se acepta como `int`; con parte fraccionaria, o fuera de rango, el hecho toma su inicial y se registra; un `bool` o un `enum` de otro tipo se trata como valor no permitido (hecho sin fijar o inicial, con log). Cómo tipa el analizador JSON de Godot 4.7 los números **no está cubierto por `docs/engine-reference/godot/`: pendiente de verificación** con una prueba de ida y vuelta (GDD 5, AC-30c). **Instantánea y cola.** El sistema expone la consulta de solo lectura `cola_vacía()`. La petición de instantánea es **síncrona y nunca espera**: con la cola vacía devuelve la instantánea; con avisos pendientes devuelve «no disponible» sin efectos, y Guardado (5) la repite en el primer instante con `cola_vacía()` verdadera (su variable `cola_vacía`, GDD 5, F1). Quién guarda, cuándo y dónde lo decide el sistema de guardado (5), no este.
14. **Ajustes fuera del estado.** Volumen, subtítulos y remapeo de controles no son hechos del juego: los gestiona el sistema de ajustes (6) y no se incluyen en la instantánea.
15. **Modo de pruebas (solo builds de desarrollo).** Una consola permite ver todos los hechos y forzar su valor, saltándose las reglas 4 y 6, para que QA y los playtests lleguen a cualquier punto sin reiniciar. Cada forzado emite el aviso de cambio normal (regla 9) para que los sistemas reaccionen, y se marca en el log. No existe en la build de la demo. Todo «se registra» de este documento escribe en un destino de log que las pruebas automáticas pueden sustituir.
16. **Escritura silenciosa de reparación (ronda 3, S-W7).** Segunda operación de escritura, `escribir_silencioso(hecho, valor)`, para que el marco de puzles (9) deje el estado coherente al configurarse tras una carga (GDD 9, regla 8: limpiar `pendiente_revelacion` si P5 ya está resuelto; AC-41). (a) La admite solo el `owner` del hecho (9), solo para hechos reversibles (regla 5: `pos_*` y `pendiente_revelacion`) y solo entre «carga de escena iniciada» y «escena lista»; cualquier otro uso es una escritura inválida (regla 6). **Ventana (E1-3b):** 3 se suscribe a «carga de escena iniciada» y «escena lista» de 4 (regla 10) para abrirla y cerrarla; sin «carga de escena iniciada» previa, o tras «escena lista» o «carga de escena fallida», la escritura se rechaza. (b) Valida tipo y rango como una escritura normal. (c) Aplica el valor en el acto (regla 3) y recalcula los derivados sin avisarlos tampoco. (d) **No emite ni encola ningún aviso**: ni a quien se suscribe a ese hecho ni a quien escucha todos los cambios (Audio 23, Atmósfera 28, Guardado 5); solo deja una línea de registro informativa. (e) **Línea base de `dif`:** no se rehace la de Guardado (GDD 5, regla 7a, fijada tras «estado restaurado»); el estado actual pasa a diferir de ella (`dif` verdadero) y la limpieza llega a disco con la siguiente causa o con `periodic`, que es lo deseado (el fichero deja de decir `pendiente_revelacion` verdadero con P5 resuelto). Una instantánea pedida después ya contiene el valor limpio. La consola de desarrollo (regla 15) no es esto: sus forzados sí emiten el aviso normal.

### States and Transitions

El sistema tiene tres estados de ciclo de vida; cada hecho tiene además su propio recorrido.

| Estado del sistema | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar el juego. Cualquier lectura o escritura es un error. | Listo (al leer el catálogo) |
| **Listo** | Operativo: lecturas, escrituras y avisos permitidos. | Restaurando (al restaurar) · Listo (partida nueva) |
| **Restaurando** | **Síncrono:** la restauración se aplica entera dentro de una sola llamada, sin ceder el control ni esperar fotogramas. El estado existe como garantía de atomicidad: mientras dura, ningún código externo (un suscriptor, una lectura) puede ejecutarse, así que ninguna lectura ve valores a medias. Si, aun así, algo intentara escribir, leer, pedir una restauración o una partida nueva desde dentro de ella (un fallo de programación), se rechaza y se registra; en desarrollo detiene la ejecución. | Listo; el aviso «estado restaurado» se emite ya en «Listo», como último paso de la llamada |

| Tipo de hecho | Recorrido permitido |
|---|---|
| `bool` de un solo sentido | falso → verdadero (no vuelve a falso) |
| `bool` derivado | sigue siempre a su regla: falso → verdadero cuando se cumple; solo puede volver a falso por recálculo (consola de desarrollo o restauración), nunca por escritura |
| `enum` | sin fijar → valor final, una sola vez |
| `int` `pos_L/C/R` | cualquier valor 1 a 4 → cualquier valor 1 a 4 |
| `pendiente_revelacion` | falso ↔ verdadero |

### Interactions with Other Systems

La tabla recoge los 20 hechos del Anexo D.2 (el 20.º, `t4_decision`, decisión del usuario 2026-11-09, D-B1, recogido en slice v0.3.2). «Escribe» y «Lee» están **confirmados** por los GDD de 1, 4, 5, 7, 8, 9, 10, 19, 20 y 21 (lote Feature 1; pendientes de su re-review) y siguen como propuesta (‡) donde el sistema aún no tiene GDD (17, 22 a 28). **Dueños únicos:** `correos_leidos` 19; `formulario_leido`, `tarjeta_B` y `tarjeta_D` 20 (8 solo lee las tarjetas).

| Hecho | Tipo · inicial | Escribe | Lee |
|---|---|---|---|
| `correos_leidos` | bool · falso | 19 Ordenador | 19 (habilita «Imprimir»; GDD 19 R15, R21). **9 no lo lee** (el `requires` del puzle 1 es `all: []`). **Sin causa de guardado propia** (ronda de corrección 2, N2-1, DT-20): 5 lo cubre con `periodic` y `quit` (GDD 5 regla 6, AC-48); un cierre forzado lo pierde como máximo durante `t_periodico` y 19 vuelve a ofrecer la impresión |
| `archivo_abierto` | bool · falso | 9 Marco de puzles (a petición del puzle 1) | 8 Acceso (puerta A; suscripción por hecho) · 7 (`habilitado_si`) |
| `formulario_leido` | bool · falso | 20 Documentos | 17 Pistas ‡ · 21 Director de escenas (`ESC3_FORMULARIO`) · 7 (`habilitado_si`) |
| `tarjeta_B` | bool · falso | 20 Documentos | 8 Acceso (lector `C06`; monótono) |
| `tarjeta_D` | bool · falso | 20 Documentos | 8 Acceso (lector `C07` y `D06`; monótono) |
| `memo_leido` | bool · falso | 9 Marco de puzles (a petición del puzle 2) | 17 Pistas ‡ (el 21 **no** lo lee: se retira la lectura opcional, DT-5 de 21) |
| `pos_L`, `pos_C`, `pos_R` | int 1 a 4 · 2 | 9 Marco de puzles (a petición del puzle 2) | 9 (puzle 2, restauración) · 5 Guardado |
| `caja_c1` | bool · falso | 9 Marco de puzles (a petición del puzle 3) | 10 Caja · 9 (puzle 5) |
| `caja_c2` | bool · falso | 9 Marco de puzles (a petición del puzle 4) | 10 Caja · 9 (puzle 6) |
| `caja_c3` | bool · falso | 9 Marco de puzles (a petición del puzle 5) | 10 Caja · 9 (puzle 6) |
| `caja_c4` | bool · falso | 9 Marco de puzles (a petición del puzle 6) | 10 Caja |
| `pendiente_revelacion` | bool · falso | 9 Marco de puzles (a petición del puzle 5) | 9 (puzle 5, reanudación) · 5 Guardado |
| `caja_completa` | bool derivado · falso | este sistema (regla 7) | 21 Director de escenas (dispara el apagón y el timbre de `V02`, que pasa a `vibrando`; **la llamada la inicia 22 al descolgar**, GDD 21 regla 15; con `¬llamada_completada` decide la reanudación, GDD 5 regla 28) · 8 Acceso (`C08` en `EN_APAGON`) · 7 (`habilitado_si`) |
| `carta_variante` | enum A, B, C · sin fijar | 9 Marco de puzles (a petición del puzle 6) | 22 Llamada |
| `t4_decision` | enum `returned`, `assigned` · sin fijar | 9 Marco de puzles (a petición del puzle 4; se escribe al resolverlo, antes de `caja_c2`, GDD 9 regla 12c) | 22 Llamada ‡ (variación de una línea del Guardián, propuesta en GDD 18). **21 no lo lee** (DT-6 de 21) |
| `llamada_iniciada` | bool · falso | 22 Llamada ‡ | 22 Llamada · 5 Guardado (marca de **sellado**: tras escribirse, la partida no vuelve a guardarse) · 21 Director de escenas |
| `respuesta_llamada` | enum A, B, C, D · sin fijar | 22 Llamada ‡ | 21 Director de escenas (última línea de Vera) · 7 (`habilitado_si`) |
| `llamada_completada` | bool · falso | 22 Llamada ‡ | 21 Director de escenas (`ESC7_RESTAURAR`, `ESC8_CIERRE`, reanudación) · 8 Acceso (activa `C08` 2,0 s después) · 4 (precondición de `recepcion`) |

**Nota sobre `llamada_iniciada`.** El GDD 5 (regla 12) reinterpreta D.2: el hecho **no evita repetir la llamada**; marca el sellado del guardado, y la llamada se repite hasta quedar completada y guardada (decisión del usuario, ronda 2, anotada en el slice D.2). Restricción para el GDD 22: escribirlo **inmediatamente antes** de emitir «llamada iniciada» y antes de cualquier otra escritura de la llamada. Este sistema no cambia de reglas por ello (las reglas 4 y 13 siguen valiendo).

**Lectura por `habilitado_si`.** El sistema 7 lee hechos arbitrarios del catálogo en cada paso de física para unos 35 objetos; la lectura debe ser de coste constante y sin asignaciones (ver Game Feel).

Otras interacciones:

| Sistema | Qué recibe de este | Qué entrega a este |
|---|---|---|
| 5 Guardado y carga | Instantánea de todos los hechos; aviso «estado restaurado»; «avisos descartados» (causa `notices_dropped`) | Una instantánea que restaurar |
| 4 Escena de planta | Precondición: estado en «Listo»; avisos «estado restablecido» y «estado restaurado». **Solo lee `llamada_completada`** (precondición de `recepcion`, GDD 4 regla 13); los demás hechos los leen los elementos de la escena al configurarse (GDD 4, regla 6) | Los avisos de la regla 10 (4), incluidos «carga de escena fallida» y «partida terminada» |
| 8 Control de acceso, 21 Director de escenas | Avisos de cambio de hecho; 8 recibe «ascensor rechazado» y 21 recibe «ascensor llamado» | 8: «puerta abierta», «ascensor llamado», «línea pedida». 21: «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida», «línea pedida», «ascensor rechazado». Ninguno escribe hechos |
| 23 Audio, 28 Atmósfera, 26 Subtítulos, 27 Título | Avisos de cambio y de eventos con nombre a los que se suscriben | 23: «línea terminada», «línea sin audio», «línea fallida» |
| 25 Menú de pausa | Avisos de cambio; «guardado en riesgo» para su indicador | `pause_opened` |
| 2 Jugador, 18 Base de contenido narrativo | Nada (no usan el bus; 18 es contenido que los consumidores eligen leyendo `carta_variante` y `respuesta_llamada`) | — |
| 6 Ajustes | Nada (los ajustes quedan fuera, regla 14; su aviso de cambio es propio, ver regla 10) | — |

## Edge Cases

**Escrituras y orden**
- **If un sistema escribe un hecho mientras el sistema está en «Restaurando»**: como la restauración es síncrona (ver States and Transitions) solo puede ocurrir por un fallo de programación; la escritura se rechaza (no se encola) y se registra, y la restauración continúa sin interferencias.
- **If un suscriptor pide partida nueva o restauración durante una entrega**: se aplica al terminar la entrega en curso (regla 11); la cola se descarta entonces (reglas 12 y 13).
- **If un suscriptor, al recibir un aviso, escribe otro hecho**: el valor se aplica en el acto y su aviso se encola; se entrega al terminar la entrega en curso (reglas 3 y 11). Un tope de seguridad de avisos encadenados por fotograma (valor a fijar en el ADR) corta cualquier bucle entre hechos reversibles: al alcanzarlo se descarta el resto de la cola, se registra y, en desarrollo, se detiene la ejecución. **El descarte no es silencioso:** emite siempre el aviso de sistema «avisos descartados» (sin datos, registrado) para que Guardado (5) lo trate como causa de guardado (`notices_dropped`, GDD 5 regla 6) y no se pierda una causa que estuviera en la cola descartada (los sistemas deducen su estado de los hechos, regla 8, pero un guardado disparado por un aviso perdido no se repetiría hasta la siguiente causa). Con el flujo previsto el tope no se alcanza (la cadena más larga del slice, `carta_variante` → `caja_c4` → `caja_completa` → apagón, son unos pocos avisos frente a 64): CA-32 lo comprueba.
- **If un hecho cambia y con él cambia un hecho derivado** (p. ej. `caja_c4` y `caja_completa`): el aviso del hecho de entrada se entrega antes que el del derivado.
- **If dos sistemas escriben hechos distintos en el mismo fotograma**: se procesan en el orden en que llegaron; los derivados se recalculan tras cada escritura.
- **If se emite dos veces el mismo aviso con nombre** (p. ej. un puzle reintenta): no se deduplica. Los receptores basan su lógica en los hechos, no en contar avisos; los cambios de hecho sí son idempotentes (regla 9).
- **If se escribe un hecho con un nombre mal escrito o con otra capitalización**: es un hecho no declarado (regla 6); los nombres distinguen mayúsculas.

**Restauración e instantáneas**
- **If la instantánea trae `caja_completa` distinto del resultado de `caja_c1`…`caja_c4`**: se ignora el valor guardado del derivado y se recalcula desde sus entradas.
- **If la instantánea trae un `enum` con un valor no permitido**: ese hecho queda «sin fijar» y se registra.
- **If la instantánea trae un `pos_*` fuera de 1 a 4**: toma el valor inicial (2) y se registra.
- **If la instantánea trae `llamada_iniciada` verdadero y `llamada_completada` falso**: es un estado válido (la partida se cerró durante la llamada); se restaura tal cual y el sistema de llamada (22) reanuda (slice D.3).
- **If la instantánea trae `caja_c3` verdadero y `pendiente_revelacion` verdadero** (cierre entre las dos escrituras del marco, GDD 9 regla 19): se restaura tal cual, sin advertencia; por contrato, el marco (9) limpia `pendiente_revelacion` con la escritura silenciosa (regla 16, GDD 9 regla 8): nadie recibe aviso y la línea base de `dif` de Guardado no se rehace (la limpieza se guarda con la siguiente causa).
- **If alguien que no es el `owner`, o fuera de la ventana de carga, o sobre un hecho de un solo sentido, intenta una escritura silenciosa**: escritura inválida (regla 6).
- **If la instantánea trae un `int` como `2.0` o un `bool` como número**: reglas de tipos de la regla 13.
- **If la instantánea trae una combinación incoherente entre hechos** (p. ej. `llamada_completada` verdadero con `llamada_iniciada` falso): se restaura tal cual, sin corregir, y se registra una advertencia; corregir en silencio podría deshacer progreso real.
- **If falta el fichero de instantánea o no se puede leer**: no es responsabilidad de este sistema; el sistema de guardado (5) decide y, si se empieza partida nueva, se aplica la regla 12.

**Arranque y datos**
- **If se lee o escribe un hecho antes de que el catálogo esté cargado** («Sin cargar»): en desarrollo, error visible; en la build final, la lectura devuelve el valor neutro del tipo (falso, 0 o sin fijar), la escritura se descarta y se registra.
- **If el fichero de catálogo falta o está corrupto al arrancar**: el juego no entra en la partida; muestra un mensaje de error claro y se cierra. No se arranca con un catálogo parcial.
- **If un sistema se descarga con la escena (p. ej. al pasar a Recepción) mientras está suscrito**: deja de recibir avisos sin que haga falta darse de baja y sin errores.
- **If se lee un hecho no declarado en estado «Listo»**: en desarrollo, error visible; en la build final devuelve el valor neutro del tipo (falso, 0 o sin fijar) y se registra.

**Guardado y pruebas**
- **If el sistema de guardado (5) pide una instantánea mientras hay avisos pendientes de entregar**: no la recibe: la petición devuelve «no disponible» (regla 13) y Guardado la repite cuando `cola_vacía()` es verdadera, de modo que la instantánea nunca contiene un cambio a medias (p. ej. `caja_c4` sin su derivado `caja_completa`).
- **If en la consola de desarrollo se fuerza un hecho de un solo sentido a su valor anterior**: se permite (regla 15), se marca en el log y se recalculan los derivados; el estado de las escenas ya cargadas no se garantiza coherente, y para una prueba limpia se recarga la partida.
- **If la consola de desarrollo existe en la build de la demo**: es un defecto; la comprobación de builds de entrega debe fallar si la encuentra (ver Acceptance Criteria).

## Dependencies

**Aguas arriba (de qué depende):** ninguna. Solo necesita su fichero de catálogo (`assets/data/state/flags.json`, definido por este GDD) y la capacidad del motor de leer datos al arrancar.

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él pero el resto de su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 1 Entrada y controles | Blanda | Emite «dispositivo de entrada cambiado» y «contexto de entrada cambiado» por el bus; **se suscribe** a «carga de escena iniciada» (con `D_carga`), «carga de escena terminada» y «carga de escena fallida» (de 4) y recibe «ajustes aplicados» (de 6, fuera del bus). No lee ni escribe hechos. Funciona sin el bus salvo por esos avisos |
| 4 Escena de planta | Dura | Precondición (estado «Listo») y avisos de ciclo de vida; emite «carga de escena iniciada» (destino, `motivo`, `D_carga`), «escena lista», «carga de escena terminada», «carga de escena fallida», «zona activada» y «partida terminada». Solo lee `llamada_completada`; los demás hechos los leen los elementos de la escena |
| 5 Guardado y carga | Dura | Pide instantánea, restaura, restablece (y lee el contenido restablecido), consulta `snapshot_version` y `cola_vacía()`, escucha «estado restaurado», «avisos descartados» (causa `notices_dropped`), «partida terminada» (de 4) y los avisos de causa; emite «guardado en riesgo» / «guardado restablecido» |
| 7 Interacción e inspección | Blanda | Lee cualquier hecho para `habilitado_si` (coste constante, sin asignaciones); emite «vista cercana abierta/cerrada», «lectura completada», «lectura cerrada», «interacción ejecutada» |
| 6 Ajustes persistentes | Ninguna | No usa el bus: aviso de cambio propio con las mismas reglas (su regla 7); el ADR debe unificar el mecanismo |
| 8 Control de acceso | Dura | Lee `archivo_abierto` (suscripción por hecho), `tarjeta_B`, `tarjeta_D`, `caja_completa` y `llamada_completada`; **no escribe hechos**; emite «puerta abierta», «ascensor llamado» y «línea pedida»; recibe «ascensor rechazado» |
| 9 Marco de puzles | Dura | Es `owner` de los hechos de puzle y único escritor; se suscribe por hecho a los de `requires.all`; emite `EV_PUZZLE_SOLVED_<ID>`, «compartimento completado» y los demás avisos de puzle; escribe `pendiente_revelacion` al iniciar la revelación y lo limpia **con la escritura silenciosa** (regla 16) al configurarse tras una carga |
| 10 Caja y compartimentos | Dura | Lee `caja_c1` a `caja_c4` para las dependencias entre compartimentos |
| 19 Ordenador, correo e impresora | Dura | Escribe `correos_leidos` y es su único lector (habilita «Imprimir»); no emite avisos con nombre |
| 20 Documentos y bolsillo | Dura | Escribe `formulario_leido`, `tarjeta_B`, `tarjeta_D` (`tarjeta_*` a petición de 8 vía `otorgar("A05")`); lee `caja_c1`, `caja_c2`, `caja_c4` y `carta_variante` para derivar ítems; no emite avisos nuevos (D20-10) |
| 21 Director de escenas | Dura | Lee `formulario_leido`, `caja_completa`, `llamada_iniciada`, `llamada_completada` (reanudación: `caja_completa ∧ ¬llamada_completada`) y `respuesta_llamada`; **no lee** `memo_leido` ni `t4_decision`; no escribe hechos; emite «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida», «línea pedida» y «ascensor rechazado»; escucha «ascensor llamado» (de 8) |
| 22 Llamada telefónica | Dura | Lee `carta_variante`; escribe `llamada_iniciada` (restricción de momento: nota tras la tabla de hechos), `respuesta_llamada`, `llamada_completada`; emite «llamada iniciada» y «llamada completada» |
| 23 Director de audio | Blanda | Se suscribe a avisos; emite «línea terminada», «línea sin audio» y «línea fallida» |
| 25 Menú de pausa | Blanda | Emite `pause_opened`; muestra «guardado en riesgo». No lee ni escribe hechos |
| 27 Pantalla de título y cierre | Blanda | Lee hechos para detectar partida en curso |
| 28 Atmósfera reactiva | Blanda | Se suscribe a avisos (apagón, parpadeo, reflejo) |
| 11 a 16 Puzles | Indirecta (vía 9) | Escriben y leen sus hechos a través del marco de puzles |
| 17 Sistema de pistas | Dura | Lee `formulario_leido` y `memo_leido` (único lector de `memo_leido`; el índice ya lista el 3 en su fila: `3, 9, 18`) |

**Índice de sistemas:** la fila del sistema 17 ya lista el 3 (`3, 9, 18`). La fila del sistema 1 (Entrada y controles) queda sin dependencias porque la suya con este sistema es blanda.

**Bidireccionalidad.** Existen los GDD de 1, 2, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20 y 21, y todos remiten a este documento (los de 8, 10, 19, 20 y 21, lote Feature 1, en su tabla de dependencias o de cambios requeridos; pendientes de su re-review): 1 (regla 3 y tabla; emisor blando), 4 (reglas 5, 6 y 17; sus avisos están ya en la regla 10), 5 (reglas 5, 7, 12, 13, 18, 24; instantánea, restablecimiento, `snapshot_version`, `cola_vacía`), 6 (reglas 3 y 7: los ajustes quedan fuera; aviso propio con las mismas reglas), 7 (regla 29: avisos y lectura por `habilitado_si`), 9 (reglas 1, 8 y 19: propiedad de los hechos de puzle y `pendiente_revelacion`), 2 y 18 (no usan el bus y lo declaran). Pendientes de redactarse y de listar este sistema con los nombres de la tabla de «Interacciones con otros sistemas»: 22, 23, 25, 26, 27, 28 (y 11 a 16 vía 9; 17 en lo suyo).

## Tuning Knobs

El sistema no tiene valores de equilibrio de juego; su único parámetro configurable es un umbral de seguridad técnico.

| Knob | Valor inicial | Rango seguro | Qué afecta |
|---|---|---|---|
| `max_chained_notices` | A fijar en el ADR (propuesta: 64) | 8 a 256 | Cuántos avisos encadenados por fotograma se entregan antes de cortar la cola (Edge Cases). Muy bajo: corta cascadas legítimas (p. ej. `caja_c4` → `caja_completa` → apagón); muy alto: un bucle entre hechos reversibles congela el fotograma antes de cortarse. Vive en datos, junto al catálogo. |

## Visual/Audio Requirements

Ninguno. El sistema no tiene presentación propia: lo que el jugador ve y oye lo producen los sistemas que reaccionan a sus avisos (audio 23, atmósfera 28, subtítulos 26). *(Sección opcional para la categoría Core; no se consulta a `art-director`.)*

## Game Feel

No aplica: el jugador no opera este sistema directamente. Lo único exigible es que un cambio de hecho llegue a sus suscriptores en el mismo fotograma en que se produce, salvo cuando se encola por la regla 11. **Coste:** la lectura de un hecho es de coste constante y no asigna memoria (el GDD 7 lee hechos en cada paso de física para unos 35 objetos); escribir un valor sin cambio no asigna ni emite nada.

## UI Requirements

Ninguno para el jugador. La consola de desarrollo (regla 15) es una herramienta interna, solo existe en builds de desarrollo y queda fuera de los requisitos de UI del juego.

## Cross-References

Las referencias son a documentos de diseño; los GDD 1, 2, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20 y 21 ya existen y figuran abajo. Los demás sistemas dependientes se añadirán al redactarse.

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · Anexo D.2 | Lista de los 20 hechos (incluido `t4_decision`, recogido en slice v0.3.2), tipos y valores iniciales | Fuente de los datos de `flags.json`; si cambia, hay que actualizar el catálogo |
| `design/slice/slice-v0.3.md` · Anexo B | `EV_PUZZLE_SOLVED_<ID>`, dependencias de la caja (B.6: `caja_completa`) | Define los avisos de puzle y el hecho derivado |
| `design/slice/slice-v0.3.md` · §13.2 y D.3 | Puntos de autoguardado y reanudaciones | Condiciona la instantánea (reglas 13 y 14) |
| `design/slice/slice-v0.3.md` · D-14, D-15, D-16 | Carta permanente; silencio en la llamada; orden de la caja | Justifican hechos de un solo sentido y `caja_completa` derivado |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Información incompleta* | Pilares que este sistema sirve |
| `design/gdd/systems-index.md` | Fila 3 y dependencias de los sistemas 4, 5, 8, 9, 10, 17, 19–23, 27, 28 (8, 10, 19, 20 y 21 ya propagadas) | Debe reflejar la tabla de Dependencies |
| `design/gdd/entrada-y-controles.md` · regla 3 | «dispositivo de entrada cambiado» y «contexto de entrada cambiado» | Avisos emitidos por Entrada (1) y listados en la regla 10 |
| `design/gdd/jugador-en-primera-persona.md` · regla 31 y tabla de interacciones | El Jugador (2) no usa el bus | Sin dependencia; declarado en la regla 10 |
| `design/gdd/escena-de-planta.md` · reglas 5, 6, 9, 13, 14, 16, 17 y «Cambios requeridos» nº 1 | Avisos de carga, de fallo y de zona; «partida terminada»; solo lee `llamada_completada` | Cubierto por la regla 10 y la fila 4 |
| `design/gdd/guardado-y-carga.md` · reglas 5, 6, 7, 11, 12, 13, 18, 24, 29 y F1 | Instantánea, `cola_vacía` (F1), `snapshot_version`, sellado por `llamada_iniciada`, `pause_opened`, causa `notices_dropped`, línea base de `dif`, «partida terminada» | Interfaz con Guardado (reglas 13 y 16; nota de `llamada_iniciada`) |
| `design/gdd/ajustes-persistentes.md` · reglas 3 y 7 | Ajustes fuera del estado; aviso propio con las mismas reglas y el mismo tope | Mecanismo duplicado a unificar en el ADR (Open Question 2) |
| `design/gdd/interaccion-e-inspeccion.md` · regla 29 | Avisos de vista/lectura/interacción; lectura por `habilitado_si` | Regla 10 y Game Feel (coste) |
| `design/gdd/marco-de-puzles.md` · reglas 1, 8, 19, 20, D9-4, D9-5, D9-13 | Propiedad de hechos de puzle; `pendiente_revelacion` al iniciar; avisos de puzle y de línea; identificadores `P1`–`P6` | Reglas 2, 5 y 10; Decisiones tomadas |
| `design/gdd/control-de-acceso.md` · reglas 11, 13 a 15 y Dependencies | «puerta abierta», «ascensor llamado», «línea pedida»; lee `archivo_abierto`, `tarjeta_B/D`, `caja_completa`, `llamada_completada`; no escribe hechos | Regla 10 y tabla de hechos |
| `design/gdd/caja-y-compartimentos.md` · reglas 3, 6, 19 | Lee `caja_c1`–`caja_c4`; `caja_completa` es derivado | Sin cambios de contrato |
| `design/gdd/ordenador-correo-impresora.md` · R15, R21 | Escribe y lee `correos_leidos` (único lector) | Tabla de hechos |
| `design/gdd/documentos-y-bolsillo.md` · R1, R8, R12 | Escribe `formulario_leido`, `tarjeta_B`, `tarjeta_D`; deriva los demás ítems de hechos de 9 | Tabla de hechos; D20-10 (sin avisos nuevos) |
| `design/gdd/director-de-escenas.md` · reglas 5, 6, 14, 15, 17 | Lee 5 hechos sin escribir; avisos de 21; «ascensor llamado»/«ascensor rechazado» | Regla 10 y tabla de hechos |
| `design/gdd/base-de-contenido-narrativo.md` · regla 5 | `carta_variante` y `respuesta_llamada` leídos por los consumidores | Sin dependencia directa |

## Acceptance Criteria

Revisados por `qa-lead`. **Testeabilidad hoy:** los CA marcados L se ejecutan sin otros sistemas; los I dependen de sistemas sin escribir y se prueban mientras tanto con emisores de prueba. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/state/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante. Este sistema no define fórmulas ni valores de equilibrio, así que no hay criterios de ese tipo; tampoco define un presupuesto de rendimiento, por lo que no se propone ninguno.

**Hechos (reglas 1 a 7)**
- **CA-01 (L)**: **GIVEN** el fichero de catálogo, **WHEN** el sistema carga, **THEN** existen exactamente 20 hechos, los del Anexo D.2 (incluido `t4_decision`) y cada uno devuelve su valor inicial del Anexo D.2.
- **CA-02 (L)**: **GIVEN** un hecho sin tocar, **WHEN** se lee, **THEN** devuelve su inicial; **GIVEN** que su dueño escribe un valor válido, **WHEN** se lee, **THEN** devuelve el nuevo.
- **CA-03 (L)**: **GIVEN** `tarjeta_B` verdadero, **WHEN** se escribe verdadero, **THEN** no se emite aviso; **WHEN** se escribe falso, **THEN** se rechaza, el valor sigue verdadero y se añade una línea al log.
- **CA-04 (L)**: **GIVEN** `carta_variante` = B, **WHEN** se escribe C o «sin fijar», **THEN** se rechaza y sigue en B. Idéntico para `respuesta_llamada`, y para `t4_decision` (`returned` no admite `assigned` ni «sin fijar»).
- **CA-05 (L)**: **GIVEN** `pos_L` = 2, **WHEN** se escribe 4 y luego 1, **THEN** ambas se aceptan; **GIVEN** `pendiente_revelacion` falso, **WHEN** se escribe verdadero (inicio de la revelación) y luego falso (fin), **THEN** ambas se aceptan y emiten su aviso de cambio.
- **CA-06 (L)**: **GIVEN** la build final, **WHEN** se escribe un hecho no declarado, `Tarjeta_B` (otra capitalización), `pos_L` = 5, un `bool` con una cadena o un `float` en un `int`, **THEN** el valor anterior se conserva y se añade exactamente una línea al log.
- **CA-06b (I)**: **GIVEN** una build de desarrollo, **WHEN** se escribe cualquiera de los valores inválidos de CA-06, **THEN** se detiene la ejecución con un error visible.
- **CA-07 (L)**: **GIVEN** `caja_c1` a `caja_c3` verdaderos y `caja_c4` falso, **WHEN** se escribe `caja_c4` verdadero, **THEN** `caja_completa` pasa a verdadero; **WHEN** un sistema intenta escribir `caja_completa` directamente, **THEN** se rechaza (regla 6).
- **CA-08 (L)**: **GIVEN** un hecho cuyo `owner` es el sistema X, **WHEN** en una build de desarrollo escribe el sistema Y, **THEN** se trata como escritura inválida; **WHEN** lo hace la build final, **THEN** no se comprueba el dueño.

**Avisos (reglas 8 a 11)**
- **CA-09 (L)**: **GIVEN** un aviso emitido sin suscriptores, **WHEN** alguien se suscribe después, **THEN** no lo recibe y los hechos no cambian.
- **CA-10 (L)**: **GIVEN** un suscriptor, **WHEN** un hecho cambia, **THEN** lo recibe exactamente una vez con (nombre, valor anterior, valor nuevo); **WHEN** se escribe el mismo valor, **THEN** no recibe nada.
- **CA-11 (I)**: **GIVEN** un suscriptor, **WHEN** se emite `EV_PUZZLE_SOLVED_P1`…`P6`, «puerta abierta» (con identificador), «compartimento completado» (1 a 4), «llamada iniciada», «llamada completada», «dispositivo de entrada cambiado», «contexto de entrada cambiado», «carga de escena iniciada» (con destino, `motivo` y `D_carga`), «escena lista», «carga de escena terminada», «carga de escena fallida», «partida terminada», «zona activada», «línea terminada», «línea sin audio», «línea fallida» o `pause_opened`, **THEN** lo recibe con su nombre y datos; **y** un suscriptor a un hecho concreto no recibe los cambios de otro (regla 9). *(Testeable hoy con un emisor de prueba; la parte de integración real se cierra cuando existan los sistemas 8, 22, 23 y 25.)*
- **CA-12 (L)**: **GIVEN** los suscriptores A y B (en ese orden), **WHEN** cambia un hecho, **THEN** reciben en el orden A, B; dos cambios sucesivos se entregan en el orden en que ocurrieron.
- **CA-13 (L)**: **GIVEN** un suscriptor que, al recibir el aviso de X, escribe Y, **WHEN** cambia X, **THEN** el aviso de Y se entrega después de que X llegue a todos los suscriptores (sin reentrada), **y** una lectura de Y hecha por ese suscriptor inmediatamente después de escribirla devuelve ya el valor nuevo (regla 3).
- **CA-13b (L)**: **GIVEN** un suscriptor que, al recibir un aviso, pide partida nueva, **WHEN** termina esa entrega, **THEN** se aplica la partida nueva, la cola queda vacía y se emite un único «estado restablecido».
- **CA-14 (L)**: **GIVEN** `caja_c1` a `caja_c3` verdaderos, **WHEN** `caja_c4` pasa a verdadero, **THEN** el aviso de `caja_c4` llega antes que el de `caja_completa`.
- **CA-15 (L)**: **GIVEN** un bucle de escrituras entre hechos reversibles que supera el tope de avisos encadenados, **WHEN** se alcanza el tope, **THEN** se descarta el resto de la cola y se registra (en desarrollo se detiene la ejecución) y se emite «avisos descartados». El test fija el tope en un valor de prueba leído de datos (`max_chained_notices`, ver Tuning Knobs) y comprueba que se respeta exactamente; el valor definitivo lo fija el ADR.
- **CA-16 (L)**: **GIVEN** un suscriptor que se da de baja durante una entrega, **WHEN** termina esa entrega, **THEN** no recibe ningún aviso posterior.
- **CA-17 (I, necesita escenas de 4)**: **GIVEN** un nodo suscrito, **WHEN** se libera junto con su escena, **THEN** el siguiente cambio de hecho no produce errores.

**Ciclo de vida, instantáneas y arranque (reglas 12 a 14)**
- **CA-18 (L)**: **GIVEN** progreso arbitrario y avisos pendientes, **WHEN** empieza partida nueva, **THEN** los 20 hechos valen su inicial, la cola queda vacía y se emite un único «estado restablecido» sin avisos de cambio por hecho.
- **CA-19 (L)**: **GIVEN** una instantánea del estado A, **WHEN** se restaura en una instancia limpia, **THEN** los 20 valores coinciden con A y se emite un único «estado restaurado».
- **CA-20 (L)**: **GIVEN** una instantánea sin `tarjeta_D` y con un hecho que ya no está declarado, **WHEN** se restaura, **THEN** `tarjeta_D` toma su inicial y el hecho sobrante se ignora con una línea en el log.
- **CA-21 (L)**: **GIVEN** una instantánea con `caja_completa` incoherente, un `enum` inválido y `pos_C` = 9, **WHEN** se restaura, **THEN** `caja_completa` se recalcula, el `enum` queda sin fijar (con log) y `pos_C` vale 2 (con log).
- **CA-22 (L)**: **GIVEN** `llamada_iniciada` verdadero y `llamada_completada` falso, **WHEN** se restaura, **THEN** se conservan tal cual sin advertencia; **GIVEN** `llamada_completada` verdadero y `llamada_iniciada` falso, **THEN** se conservan con una advertencia en el log.
- **CA-23 (L)**: **GIVEN** una restauración (síncrona), **WHEN** termina la llamada, **THEN** el sistema está en «Listo», los 20 valores son los de la instantánea y el aviso «estado restaurado» se ha emitido ya en «Listo». **GIVEN** un doble de prueba invocado desde el propio código de restauración mediante un gancho de pruebas (ningún código externo puede ejecutarse dentro, por diseño) que intenta escribir, leer, restaurar o pedir partida nueva, **THEN** cada intento se rechaza con una línea en el log (en desarrollo, detiene la ejecución) y los valores finales siguen siendo los de la instantánea.
- **CA-24 (L)**: **GIVEN** una instantánea, **THEN** sus claves son exactamente las 20 del catálogo, sin ajustes de volumen, subtítulos ni controles.
- **CA-25 (L, con Guardado falso)**: **GIVEN** avisos pendientes, **WHEN** el sistema de guardado (5) pide una instantánea, **THEN** recibe «no disponible» y `cola_vacía()` es falso; **WHEN** la cola se vacía, **THEN** la petición devuelve la instantánea, que nunca contiene `caja_c4` sin `caja_completa`.
- **CA-26 (I, arranque del juego)**: **GIVEN** un fichero de catálogo ausente o corrupto, **WHEN** arranca el juego, **THEN** no entra en la partida, muestra un mensaje de error claro y se cierra.
- **CA-27 (L)**: **GIVEN** la build final y el estado «Sin cargar» (o un hecho no declarado en «Listo»), **WHEN** se lee, **THEN** devuelve el valor neutro (falso, 0 o sin fijar) con una línea en el log; **WHEN** se escribe, **THEN** la escritura se descarta.

**Modo de pruebas (regla 15)**
- **CA-28 (L, con consola de pruebas)**: **GIVEN** una build de desarrollo, **WHEN** la consola fuerza `tarjeta_B` a falso, **THEN** se permite, se registra, se emite el aviso de cambio y se recalculan los derivados.
- **CA-29 (I, script de CI)**: **GIVEN** el export de la demo, **THEN** un script de verificación de builds de entrega (en `tools/ci/`, a crear junto con el ADR de la consola) busca el recurso de la consola y falla si lo encuentra. Se prueba con un export que lo incluya a propósito (debe fallar) y con uno que no (debe pasar).

- **CA-32 (I, recorrido del slice)**: **GIVEN** una partida nueva y el recorrido completo del slice en desarrollo (o una secuencia de emisores de prueba equivalente), **THEN** no se emite «avisos descartados» y la cola más larga observada queda por debajo de `max_chained_notices`.
- **CA-33 (L)**: **GIVEN** una instantánea con `pos_C` = `2.0` y otra con `pos_C` = `2.5`, **WHEN** se restauran, **THEN** la primera da 2 sin log y la segunda da 2 (inicial) con una línea de log; un `bool` con valor numérico se trata como no permitido (regla 13). *(La conducta real del analizador JSON queda a la prueba de ida y vuelta, GDD 5 AC-30c.)*
- **CA-35 (L)**: **GIVEN** un suscriptor a todos los cambios, otro a `pendiente_revelacion` y la cola vacía, con una carga en curso y `pendiente_revelacion` verdadero, **WHEN** el `owner` (9) escribe falso con la escritura silenciosa, **THEN** una lectura posterior devuelve falso, ningún suscriptor recibe aviso, la cola sigue vacía y se añade una línea informativa al log; **WHEN** lo intenta otro sistema, o el `owner` fuera de la ventana entre «iniciada» y «escena lista», o sobre un hecho de un solo sentido, **THEN** se trata como escritura inválida (regla 6) y el valor no cambia. **GIVEN** un Guardado doble con línea base fijada tras «estado restaurado», **THEN** tras la escritura silenciosa su `dif` es verdadero y no recibe ninguna causa.
- **CA-36 (L)**: **GIVEN** el bus y los dobles de 4, **THEN** «carga de escena iniciada» llega con los tres datos (destino, `motivo`, `D_carga`), «carga de escena fallida» con (destino, `motivo`, causa) y «partida terminada» solo desde el emisor 4; un segundo emisor de «partida terminada» es un defecto de documentación (regla 10).
- **CA-34 (L)**: **GIVEN** una instantánea con `caja_c3` y `pendiente_revelacion` verdaderos, **WHEN** se restaura, **THEN** se conservan tal cual, sin advertencia en el log.

**Interacciones entre sistemas**
- **CA-30 (L)**: **GIVEN** `flags.json`, **THEN** el `owner` de cada uno de los 20 hechos coincide con la columna «Escribe» de la tabla de «Interacciones con otros sistemas» (el derivado `caja_completa` tiene como dueño este sistema).
- **CA-31 (I)**: **GIVEN** una partida nueva, **WHEN** el jugador completa el slice por el camino previsto en una build de desarrollo, **THEN** no se registra ninguna escritura inválida por dueño (regla 2) y los avisos de puerta, compartimento y llamada se emiten una vez cada uno. *(Se cierra cuando existan los sistemas escritores.)*
- **CA-37 (L, N2-1)**: **GIVEN** `correos_leidos` falso, **WHEN** 19 lo escribe verdadero, **THEN** se emite el aviso de cambio genérico del hecho y **no** un aviso con nombre de causa de guardado (5 no tiene suscripción propia a él; lo cubren `periodic` y `quit`, GDD 5 AC-48); la instantánea siguiente lo recoge.

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | ~~Identificadores de los puzles `P1` a `P6`.~~ **Resuelta:** confirmados por el GDD 9 (D9-13). | — | Cerrada (2026-11-09) |
| 2 | **Tope de avisos encadenados** por fotograma y **formato de la instantánea** (mapa nombre → valor + versión). | `/architecture-decision` | Fase de arquitectura |
| 3 | **Mecanismo del `owner`**: cómo se identifica al sistema escritor en desarrollo sin acoplar los sistemas. | `/architecture-decision` | Fase de arquitectura |
| 4 | **Escritores y lectores de la tabla de interacciones**: confirmados por 1, 4, 5, 7, 8, 9, 10, 19, 20 y 21 (lote Feature 1, pendientes de re-review); siguen como propuesta (‡) los de 17, 22, 23 y 25–28. | GDD de cada sistema dependiente | Al redactar cada uno |
| 5 | ~~Índice de sistemas: añadir el sistema 3 a las dependencias del 17.~~ **Resuelta:** la fila 17 ya lista `3, 9, 18`. | — | Cerrada (2026-11-08) |
| 6 | ~~`memo_leido` y el director de escenas (21).~~ **Resuelta:** el GDD 21 retira la lectura opcional (DT-5 de 21); `memo_leido` solo lo lee 17 (DT-17). | — | Cerrada (2026-11-09) |
| 8 | **Tipado de números JSON en Godot 4.7** (¿`2` llega como `int` o `float`?): no cubierto por `docs/engine-reference/godot/`, **pendiente de verificación**. La regla 13 es robusta a ambos casos. | ADR de la instantánea + prueba de ida y vuelta (GDD 5 AC-30c) | Fase de arquitectura |
| 7 | **Destino de log inyectable** para las pruebas («se registra» verificable). | `/architecture-decision` | Fase de arquitectura |

## Decisiones tomadas

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| DT-1 | `pendiente_revelacion` se escribe **al iniciar** la revelación del puzle 5 y se limpia al terminar (desvío del GDD 9 confirmado). Se actualizan regla 5, CA-05 y los casos límite de restauración (`caja_c3 ∧ pendiente_revelacion` se restaura tal cual y el marco limpia el hecho). El slice D.2 debe actualizarse | Mantener «si se interrumpe» del slice | Más robusto ante cierres forzados; no cambia el valor observable. Recomendación del revisor, ronda 2 |
| DT-2 | `llamada_iniciada` es marca de sellado (GDD 5): no evita repetir la llamada; el catálogo es de 20 hechos (incluido `t4_decision`, DT-9; recogido en el slice v0.3.2); se anota en la tabla de hechos | Hecho que evita repetir la llamada (D.2 original) | Decisión del usuario, ronda 2; sin cambio de reglas aquí |
| DT-3 | La petición de instantánea es síncrona y no espera: devuelve «no disponible» con la cola no vacía; se expone `cola_vacía()` | Que el sistema 3 bloquee o difiera la respuesta | Evita esperas ocultas y encaja con la variable `cola_vacía` del GDD 5 |
| DT-4 | Se admite suscribirse a un hecho concreto, a todos o a un aviso con nombre | Solo «todos los cambios» | Lo necesita el marco (9) para `requires.all`; coste nulo |
| DT-5 | La restauración acepta un número sin parte fraccionaria como `int`; la escritura (regla 6) sigue estricta. La conducta JSON del motor queda pendiente de verificación | Rechazar todo `float` también al restaurar | Un guardado válido no debe perderse por el tipado del analizador |
| DT-6 | El descarte de cola por tope emite «avisos descartados» (causa de guardado) y CA-32 comprueba que el slice no alcanza el tope | Solo documentar que no se alcanza | Cierra el hueco a coste mínimo |
| DT-7 | Ajustes (6) no pasa por el bus; el ADR de avisos unifica ambos mecanismos | Que Ajustes use este bus | Los ajustes no son hechos del juego (regla 14); lo decide el GDD 6 |
| DT-8 | ~~`memo_leido`: lectura opcional del 21 en Recepción, pendiente de confirmar~~ **Sustituida por DT-17** | Quitar al 21 como lector | La fila de Recepción del slice la sustenta |
| DT-9 | **(usuario, 2026-11-09, D-B1)** Nuevo hecho `t4_decision` (enum `returned`/`assigned`, sin fijar, `owner = 9`, un solo sentido); el catálogo pasa de 19 a 20. Lo escribe el marco al resolver el puzle 4 | `bool` `t4_devuelta`; escribirlo al decidir la ficha | El enum admite un tercer valor y se lee como `carta_variante`; escribirlo al decidir chocaría con la restauración (el parcial del P4 no se persiste, GDD 9 D9-8) |
| DT-10 | **(ronda 3, S-W7)** Escritura silenciosa de reparación (regla 16): solo el `owner`, solo reversibles, solo durante la carga, sin aviso; la línea base de `dif` de Guardado no se rehace | Que 9 use la escritura normal y los demás ignoren el aviso; o rehacer la línea base | 9 regla 8 / AC-41 exigen «sin avisos»; con aviso, 23 y 28 reaccionarían a un estado que no es un cambio del jugador. Dejar `dif` verdadero hace que la limpieza llegue a disco |
| DT-11 | **(ronda 3, S-B1)** «Partida terminada» tiene un único emisor, 4, tras «terminada» de `recepcion` | «4 o 22» (referencia circular entre 3, 4 y 5); en «iniciada» | 22 vive en la planta, que se descarga; en «iniciada» un fallo de carga marcaría la partida |
| DT-12 | **(ronda 3, C-W2)** «Carga de escena iniciada» lleva (destino, `motivo`, `D_carga`); nuevo «carga de escena fallida» (destino, `motivo`, causa) | Solo el destino; sin aviso de fallo | Entrada necesita `D_carga` y el fin de la carga; 5 distingue fallo de éxito |
| DT-13 | **(ronda 3, C-B2)** «Avisos descartados» es la causa `notices_dropped` en 5 | Retirar la promesa y fiar en `periodic` | La garantía «no perder una causa» necesita contraparte en Guardado |
| DT-14 | **(ronda 4, B-3/E1-3b)** El slice D.2 ya recoge los 20 hechos (v0.3.2); la ventana de la escritura silenciosa se acota con los avisos de carga de 4, a los que 3 se suscribe | Dejar «19 + 1» pendiente; ventana implícita | Elimina la discrepancia 19/20/21 y explicita la dependencia de 3 con 4 |
| DT-15 | **(lote Feature 1)** Se declaran en la regla 10 los avisos de 8 («puerta abierta» A/B/D, «ascensor llamado», «línea pedida») y de 21 («efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida», «línea pedida», «ascensor rechazado»); se quita la ‡ de 8 | Que 4 emitiera «ascensor rechazado»; dejar la ‡ hasta el re-review de 8 | 4 solo rechaza `recepcion`; quien conoce el contexto de la llamada es 21 (GDD 21 regla 17); el contrato de nombre y datos ya está cerrado en 8 y 21 |
| DT-16 | Propietarios cerrados: `correos_leidos` 19 (único lector 19; 9 no lo lee); `formulario_leido`, `tarjeta_B`, `tarjeta_D` 20 (8 solo lee las tarjetas). Se quitan las ‡ de esos escritores. Recuento: 20 hechos, sin cambios (verificado contra el slice D.2) | Que 9 lea `correos_leidos` para su `requires`; que 8 escriba las tarjetas | 9 declara `requires: all: []` (GDD 19 R27); `A05` es de 8 pero `tarjeta_B/D` las escribe 20 al `otorgar` (un solo dueño, regla 2) |
| DT-17 | 21 deja de leer `memo_leido` y `t4_decision` (los lee 17 y 22 respectivamente) y pasa a leer `formulario_leido`; cierra Open Question 6 y sustituye a DT-8 | Mantener la lectura opcional del 21 | En Recepción no hay puzle ni pistas (GDD 21 DT-5, DT-6) |
| DT-18 | `caja_completa` lo leen 21 (apagón y timbre; la llamada la inicia 22) y 8 (`C08` en `EN_APAGON`); `llamada_completada` la leen 21, 8 (activa `C08` +2,0 s) y 4 (precondición). 8 y 21 no escriben hechos | Que 21 «active el ascensor» o «dispare la llamada» | `C08` es íntegramente de 8 (D8-13, DT-17 de 21); corrige el texto previo de la tabla de hechos |
| DT-19 | **(ronda de decisiones 1, aprobada por el usuario, 2026-11-09)** Sin cambio de contrato: la acción `atrás` en `exploración` («repasar bolsillo», 20) no escribe hechos ni emite avisos (repasar es de sesión y no cambia ninguno de los 20 hechos), y `MEGA_03` pasa a ser la línea 28 del §12 con el mismo aviso «línea pedida» (regla 10) y sin hecho nuevo. | Un hecho `bolsillo_repasado` o un aviso «bolsillo repasado»; un aviso propio para la megafonía de ahorro | Ningún sistema lee que se haya releído un documento; la relectura no es progreso y los 20 hechos bastan. |
| DT-20 | **(ronda de corrección 2, `gdd-cross-review-2026-11-09-r5.md`, N2-1 y W-7)** `correos_leidos` no recibe causa de guardado propia ni aviso con nombre: queda cubierto por `periodic` y `quit` de 5 (regla 6, AC-48); CA-37 lo comprueba. «19 valores» de CA-23 pasa a 20 | Añadir la causa `correos_leidos` (una escritura más en el camino crítico por un hecho que 19 puede volver a ofrecer) | Pérdida acotada por `t_periodico` y sin softlock |

## Historial de cambios
- **2026-11-09 (ronda de decisiones 1):** DT-19 deja constancia de que las decisiones «repasar bolsillo» y `MEGA_03` al §12 no cambian hechos, avisos ni recuentos de este GDD (siguen 20 hechos). Estado: pendiente de re-review.
- **2026-11-09 (D-B1, decisión del usuario):** hecho nuevo `t4_decision` (enum `returned`/`assigned`, owner 9, un solo sentido): el catálogo pasa de 19 a 20 hechos (regla 2, regla 4, tabla de hechos, CA-01, CA-04, CA-18, CA-19, CA-24, CA-30, DT-9). Cambia el catálogo, no el mecanismo: pendiente de re-review.
- **2026-11-09 (ronda 2, re-review):** aplicada la re-review (H-01 a H-06 y H-08; H-07, el registro de entidades, queda en «Cambios requeridos en otros GDDs»). Regla 10 convertida en tabla por emisor (3, 1, 4, 5, 7, 8, 9, 22, 23, 25); reglas 5, 9 y 13 ampliadas; tablas de lectores y Dependencies completadas (21, 7, 5, 4, 6, 23, 25); Cross-References y bidireccionalidad reescritas con los GDD existentes; fila 17; Open Questions 1, 4, 6 y 8; CA-05, 11, 15, 17, 23, 25 a 29 retocados y CA-32 a 34 añadidos; sección «Decisiones tomadas». Estado: revisado, pendiente de re-review.

- **2026-11-09 (lote 2/5/7/9, cambios derivados de las revisiones de 5, 7 y 9):** (a) `owner = 9` para `archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1` a `caja_c4`, `pendiente_revelacion` y `carta_variante` (regla 2 y tabla; antes «11 a 16»; GDD 9 D9-4). (b) Se exponen `snapshot_version` conocida (regla 13) y el contenido del estado restablecido (regla 12) para Guardado. (c) Avisos nuevos en la regla 10: «guardado en riesgo» / «guardado restablecido» (emisor 5), avisos de puzle (emisor 9) y avisos de vista/lectura/interacción (emisor 7). (d) Dependencias: 7 (blanda) y 9 actualizadas. **Cambia reglas: pendiente de re-review.** Estado del documento sin cambios. Nota: `llamada_iniciada` sigue sin cambios; la restricción de emisión pedida por el informe de 5 pertenece al GDD 22 (sin redactar).

- **2026-11-09 (ronda 3, aplica `gdd-cross-review-2026-11-09.md`):** regla 10 (datos de «carga de escena iniciada», «carga de escena fallida», «partida terminada» con 4 como único emisor; «avisos descartados» = `notices_dropped`), nueva regla 16 (escritura silenciosa y línea base de `dif`), regla 13 (`cola_vacía` → F1 de 5), tablas de interacciones y dependencias (4 lee `llamada_completada`), CA-35 y CA-36, DT-10 a DT-13. **Cambia reglas: pendiente de re-review.**
- **2026-11-09 (ronda 4, aplica `gdd-cross-review-2026-11-09-r2.md`):** B-3: 20 hechos del Anexo D.2 (incluido `t4_decision`) en regla 1, CA-01, tabla de hechos, Fuentes y DT-2 (recogido en slice v0.3.2). E1-3b: regla 16a deja escrito que 3 se suscribe a «carga de escena iniciada»/«escena lista» de 4 para acotar la ventana. DT-14. Pendiente de re-review.
- **2026-11-09 (propagación del lote Feature 1, GDD 8, 10, 19, 20 y 21):** regla 10 (avisos de 8 sin ‡ y de 21; «línea pedida» con tres emisores; fila 23 con la sangría corregida), tabla de hechos (dueños de `correos_leidos`, `formulario_leido`, `tarjeta_B/D` cerrados; lectores de `caja_completa`, `llamada_completada`, `memo_leido`, `t4_decision`, `formulario_leido`; texto «dispara el apagón y la llamada» corregido), otras interacciones, Dependencies (8, 10, 19, 20, 21, 17), bidireccionalidad, Cross-References, Open Questions 4 y 6, DT-8 sustituida y DT-15 a DT-18. 20 hechos (sin cambios). Ninguna pregunta de alcance del lote (`atrás`/`repasar_bolsillo`, B.1, `MEGA_03` y slice v0.4, quién muestra `I-05`/`I-06a`) afecta al contrato de 3. **Cambia reglas: pendiente de re-review.** Estado: Revisado (ronda de propagación 1) — pendiente de re-review.

- **2026-11-09 (ronda de corrección 2, `gdd-cross-review-2026-11-09-r5.md`):** N2-1 (nota en la tabla de hechos, CA-37, DT-20), W-7 (CA-23: 20 valores). Estado: pendiente de re-review.