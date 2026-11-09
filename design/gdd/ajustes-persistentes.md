# Ajustes persistentes

> **Status**: Revisado (ronda de corrección 5) — pendiente de re-review (ronda de corrección 5: dependencia de 1 en blando sin ciclo duro, 22 sin dependencia directa, 7 ya listado en el índice; ronda de corrección 4: R6-1, cierre de durezas, 18 aguas arriba; R6-1 dureza de dependencias y R6-2 `BOX_Cn_OPEN`) (ronda de corrección 2: W-9 `fov_step_deg`; la ronda de propagación 1 añade a 19 y 21 como consumidores de `reducir_movimiento`; ronda 6 aplica G-2 e INFO de `gdd-cross-review-2026-11-09-r4.md`; ronda 5 aplica C-W6 y F-3 de `gdd-cross-review-2026-11-09-r3.md`; ronda 2: re-review)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (reducir sobresaltos, remapeo, accesibilidad) · Autonomía como progresión (el jugador ajusta su experiencia)

## Summary

Es la memoria de las preferencias del jugador: los volúmenes de voces, efectos y música, los subtítulos, reducir sobresaltos, las ayudas de los puzles, el modo de ventana y los controles que haya reasignado. Las guarda en un fichero propio, separado de la partida, y las reaplica al arrancar; un fichero dañado nunca impide jugar. Existe para que la accesibilidad y la comodidad que el jugador elige —clave para el pilar *Tensión sin castigo*— sobrevivan entre sesiones, con un único dueño que los demás sistemas puedan leer y escuchar.

> **Quick reference** — Layer: `Core` (categoría `Persistence`) · Priority: `MVP` · Key deps: `1 Entrada y controles`

## Overview

Ajustes persistentes guarda las preferencias del jugador —los volúmenes de voces, efectos y música, los subtítulos, la opción de reducir sobresaltos, la asistencia de encaje del puzle 3 y el bloque de controles que define Entrada y controles (1)— y las reaplica cada vez que arranca el juego. Viven en un fichero propio, separado de la partida guardada: borrar o cambiar de partida no toca los ajustes, y cambiar un ajuste no toca la partida.

Es infraestructura que el jugador no ve como pantalla. Las pantallas las ponen el menú de pausa (25), las opciones de accesibilidad (30) y la pantalla de título (27); este sistema decide qué ajustes existen, con qué valor inicial y en qué rango, valida lo que recibe, avisa a quien lo necesite cuando un valor cambia y garantiza que un fichero dañado o ausente nunca impide jugar.

Existe por dos razones. La primera es el pilar *Tensión sin castigo*: reducir sobresaltos, regular cada capa de audio por separado y remapear los controles son condiciones para que el slice se pueda jugar sin que el susto sea una barrera, y esas elecciones deben sobrevivir de una sesión a otra. La segunda es separar responsabilidades: los ajustes no son hechos del juego (el sistema de estado los excluye por diseño, regla 14 del GDD del 3) ni de la partida (el guardado 5 no los incluye), de modo que hace falta un único dueño que los conserve y que ofrezca a los demás sistemas un valor siempre disponible y válido.

## Detailed Design

### Core Rules

**Qué ajustes existen**

1. **Catálogo cerrado.** Solo existen los ajustes declarados en un fichero de datos (`assets/data/settings/defaults.json`). Cada ajuste tiene: clave, tipo (`bool`, `float` con rango, o `enum` con valores permitidos), valor inicial y los sistemas que lo leen. Los valores iniciales de abajo son propuestas (†), a validar en playtest. El catálogo del slice es:

   | Clave | Tipo · inicial † | Qué gobierna | Lo lee |
   |---|---|---|---|
   | `vol_voces` | float 0 a 1 · 1,0 | Voces de Vera y del Guardián y megafonía | 23 Audio |
   | `vol_efectos` | float 0 a 1 · 1,0 | Efectos y sonido ambiente | 23 Audio |
   | `vol_musica` | float 0 a 1 · 1,0 | Música | 23 Audio |
   | `subtitulos_activos` | bool · verdadero | Mostrar subtítulos | 26 Subtítulos |
   | `reducir_sobresaltos` | bool · falso | Atenúa los sustos sonoros y el parpadeo del pasillo y del apagón (slice §14; art bible, fotosensibilidad) | 23 Audio, 28 Atmósfera |
   | `asistencia_encaje` | bool · falso | Radio de encaje de 0,10 m en el puzle 3 (slice B.3) | 13 Puzle 3 |
   | `asistencia_rotacion` | bool · falso | Tolerancia asistida de ±6° en el puzle 5 (slice B.5); nombre provisional, ver Open Questions | 15 Puzle 5 |
   | `balanceo_camara` | enum `completo`, `reducido`, `ninguno` · `reducido` | Balanceo de la cámara al caminar (solo traslación; GDD 2, regla 16) | 2 Jugador |
   | `campo_vision` | float 60 a 90 (grados verticales), paso 5 · 70 | Campo de visión vertical (GDD 2, regla 17; tope horizontal `fov_h_max`) | 2 Jugador |
   | `reducir_movimiento` | bool · falso | Fundido fijo de 100 ms en lugar de la transición larga y cambio estático en lugar de temblor (art bible §7.4): feedback de error de los puzles, cortina de escena, fundido de encendido de la pantalla del ordenador (100 ms, 19) y sustitución del parpadeo del pasillo / reflejo retardado y fundido propio de la escena de cierre (21) | 9 Marco de puzles, 4 Escena de planta (cortina), 19 Ordenador (R4), 21 Director de escenas (regla 23) |
   | `multiplicador_pie` | float 1,0 a 3,0, paso 0,25 · 1,0 | Accesibilidad: multiplica la duración del pie de texto de objeto (GDD 7, F5 y regla 12); 1,0 = duración normal | 7 Interacción e inspección (el sistema 24 dibuja el pie) |
   | `pie_persistente` | bool · falso | Accesibilidad: el pie de texto dura hasta que cambie el objetivo o se active otro objeto, en lugar de la duración de F5 (GDD 7, regla 12) | 7 Interacción e inspección |
   | `modo_ventana` | enum `pantalla_completa`, `ventana` · `pantalla_completa` | Modo de la ventana del juego | este sistema (regla 12) |
   | `controles` | bloque (tipo propio, validación delegada en Entrada) · ausente | Asignaciones y ajustes de manejo de Entrada y controles (reglas 15 a 19 de ese GDD) | 1 Entrada |

   **Cuantización de los `float` con paso.** Todo `float` con paso declarado (los tres volúmenes con `N_pasos`, `campo_vision` con paso 5, `multiplicador_pie` con paso 0,25) se redondea a su rejilla antes de comparar y de guardar (F1 generalizada): 72 pasa a 70; 90,0 a 90; 1,3 pasa a 1,25; fuera de rango se ajusta al límite y luego se cuantiza.

   `balanceo_camara`, `campo_vision`, `multiplicador_pie` y `pie_persistente` los ofrecen las pantallas 25 (pausa) y 30 (accesibilidad) junto a `reducir_sobresaltos`. `reducir_movimiento` **ya está en este catálogo** (fila propia arriba; el GDD 4, que la lee para la cortina, puede darla por hecha). Si los sistemas 26 (subtítulos) o 30 (accesibilidad) necesitan más ajustes (tamaño o fondo de subtítulo, otras ayudas), se añaden a esta tabla cuando se diseñen esos sistemas; este GDD no los inventa.
2. **El bloque de controles es opaco.** Este sistema guarda y devuelve el bloque `controles` tal como Entrada lo exporta, sin interpretar su contenido. Entrada valida las asignaciones y los valores al importarlo (sus casos límite). Aquí solo se garantiza que el bloque se conserva, que si falta se usan los valores por defecto de Entrada y que un bloque ilegible no impide arrancar.
3. **Los ajustes no son hechos del juego ni parte de la partida.** No se incluyen en la instantánea del estado (regla 14 del GDD del 3) ni en el guardado (5). Empezar una partida nueva, cargar otra o borrarlas no toca los ajustes, y cambiar un ajuste no toca la partida. Tampoco son ajustes los niveles de pista ni su uso: son hechos de partida (3; marco 9 reglas 25 a 27; menú 25) y 25 o 30 no deben colocarlos aquí.

**Lectura, escritura y validación**

4. **Valor siempre disponible y válido.** Cualquier sistema puede leer un ajuste en cualquier momento y obtiene siempre un valor válido: el del jugador, o el inicial si no se ha tocado, o falta, o es inválido en el fichero.
5. **Escritura.** Escribe un ajuste el sistema cuya pantalla lo ofrece al jugador: menú de pausa (25), accesibilidad (30) o título (27); y Entrada escribe el bloque `controles`. Una escritura válida se aplica en el instante en que se hace: una lectura inmediatamente posterior devuelve el valor nuevo.
6. **Escritura inválida.** Un `float` fuera de rango se **ajusta al límite más cercano** (el deslizador nunca rompe nada) y se registra; los `float` con paso (volúmenes, `campo_vision` y `multiplicador_pie`) se cuantizan además a su rejilla (F1). Para `controles` solo se comprueba que sea un bloque (no un escalar): su contenido lo valida Entrada. Un `float` NaN, una clave no declarada, un valor de tipo incorrecto o un `enum` fuera de su lista se rechazan: en las builds de desarrollo producen un error visible que detiene la ejecución, en la build final se conserva el valor anterior y se registra una línea en el log.
7. **Aviso de cambio.** Cada vez que el valor de un ajuste cambia realmente, este sistema emite un aviso propio con tres datos (clave, valor anterior, valor nuevo); escribir el mismo valor no emite nada. «Cambio real» se decide tras cuantizar (por paso `n` en los `float` con paso, F1) y, en `controles`, por igualdad profunda del bloque; el aviso de `controles` lleva solo la clave (sin anterior ni nuevo, para no copiar el bloque) y el receptor lo relee. La entrega sigue las mismas reglas que el bus de eventos (3), sin depender de él: orden de suscripción, valor aplicado al instante y aviso encolado si el cambio se provoca desde dentro de una entrega, sin reentrada, y baja de suscriptores efectiva al terminar la entrega en curso. **Descarga de la planta:** cuando se descarga la escena de planta (4), los suscriptores que viven en ella (p. ej. 7, 9, 24) se dan de baja automáticamente del aviso de este sistema, igual que en el bus (3, edge case de descarga de un sistema suscrito): dejan de recibir avisos sin darse de baja a mano y sin errores; el nodo de Ajustes, que sobrevive a los cambios de escena, no queda con referencias colgantes. El formato técnico lo fija un ADR.
8. **Restablecer.** Existe «restablecer un ajuste» y «restablecer todos» («todos» abarca los tres volúmenes, `subtitulos_activos`, `reducir_sobresaltos`, `reducir_movimiento`, las dos asistencias, `balanceo_camara`, `campo_vision`, `multiplicador_pie` y `pie_persistente`: 12 claves; no toca `modo_ventana` ni el bloque `controles`, que tiene su propio restablecer en Entrada, regla 17). Cada uno aplica el valor inicial y emite el aviso de cambio de los que cambian.

**Fichero, carga y guardado**

9. **Fichero propio.** Los valores del jugador viven en un fichero propio en la carpeta de datos del usuario del sistema, con un número de versión de formato. Ruta y formato los fija un ADR (Open Questions).
10. **Carga al arrancar.** Al arrancar se lee el fichero, se valida cada ajuste por separado y se pasa a «Listo». Una clave ausente toma su valor inicial; una de tipo incorrecto, un `enum` fuera de su lista o un NaN también, y solo ese ajuste; un `float` fuera de rango se ajusta al límite más cercano, igual que en una escritura (regla 6), para que un fichero dañado nunca convierta un volumen silenciado en máximo; un volumen dentro de rango pero fuera de la rejilla de pasos se cuantiza como en F1; una clave desconocida se ignora y no se vuelve a escribir. **Una vez en «Listo»** se emite un único aviso «ajustes aplicados» (sin datos, no uno por ajuste) y cada sistema relee lo que necesita: las lecturas dentro de ese aviso ya devuelven los valores cargados. Un fichero ausente en el primer arranque no es un error ni se avisa al jugador.
11. **Fichero ilegible o dañado.** Si el fichero existe pero no se puede leer o no tiene estructura válida, el juego **arranca siempre** con todos los valores iniciales, conserva el fichero dañado renombrándolo a una copia (no lo borra; solo lo sustituye el guardado atómico si el renombrado falla, ver Edge Cases) y registra una línea en el log. No hay mensaje bloqueante al jugador: el juego no se detiene por unos ajustes (pilar *Tensión sin castigo*).
12. **Ajuste de ventana.** `modo_ventana` es el único ajuste que aplica este sistema al motor, al cargar y en cada cambio, sin reiniciar. El resto los aplican quienes los consumen.
13. **Guardado diferido.** Cada cambio marca los ajustes como pendientes y se escribe el fichero cuando pasa `t_guardado` sin nuevos cambios o `t_guardado_max` desde el primero (F3), para que un deslizador no escriba en cada fotograma. Además se escribe lo pendiente al cerrar el juego con normalidad y al abrir el menú de pausa. La escritura es **atómica**: se escribe a un fichero temporal y se sustituye al terminar, de modo que un corte a medias nunca deja el fichero principal dañado.
14. **Datos, no código.** Los valores iniciales, los rangos y `t_guardado` viven en `assets/data/settings/defaults.json`; cambiar un valor inicial no requiere tocar código.

### States and Transitions

El sistema tiene tres estados; no existe un estado de error porque un fichero dañado nunca lo bloquea (regla 11).

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar. Cualquier lectura o escritura es un error. | Cargando |
| **Cargando** | Lee y valida el fichero (reglas 10 y 11) y aplica el modo de ventana. No se entregan avisos de cambio. Solo este sistema lee y escribe aquí. Para cualquier otro llamador (edge case «antes de Listo»): en desarrollo, error visible que detiene la ejecución; en la build final, la lectura devuelve el valor inicial del catálogo y la escritura se rechaza y se registra. | Listo, **antes** de emitir «ajustes aplicados» |
| **Listo** | Se entra con todos los valores ya cargados y validados; **a continuación** se emite «ajustes aplicados» (regla 10). Lecturas, escrituras, avisos de cambio y guardado diferido permitidos. Pendiente de escritura = hay cambios sin volcar a disco. | — (hasta cerrar el juego) |

### Interactions with Other Systems

La tabla del catálogo (regla 1) indica quién lee cada ajuste. Otras interacciones:

| Sistema | Qué recibe de Ajustes | Qué entrega a Ajustes |
|---|---|---|
| 1 Entrada y controles | El aviso «ajustes aplicados», al recibirlo Entrada lee e importa el bloque `controles` guardado (o nada); contrato de señales que Entrada debe registrar (ver re-review) | Su bloque exportado cada vez que el jugador cambia una asignación o un ajuste de manejo |
| 23 Director de audio | Volúmenes, `reducir_sobresaltos`, avisos de cambio (23 atenúa `SFX_BREATH_BROKEN` y el golpe de `SFX_PHONE_BUZZ` de la llamada; 22 no lee Ajustes, D22-19) | — |
| 26 Subtítulos | `subtitulos_activos`, avisos de cambio | — |
| 28 Atmósfera reactiva | `reducir_sobresaltos` | — |
| 2 Jugador en primera persona | `balanceo_camara`, `campo_vision`, avisos de cambio (aplicación inmediata; blanda: sin Ajustes usa los iniciales) | — |
| 9 Marco de puzles (y 13, 15 vía el marco) | `asistencia_encaje`, `asistencia_rotacion`, `reducir_movimiento` (feedback de error) | — |
| 7 Interacción e inspección | `multiplicador_pie`, `pie_persistente` (duración del pie de texto, GDD 7 regla 12 y F5); avisos de cambio | — |
| 4 Escena de planta | `reducir_movimiento` (cortina). Requiere que el nodo de Ajustes sobreviva a los cambios de escena (4, regla 1) | — |
| 19 Ordenador, correo e impresora | `reducir_movimiento` (fundido fijo de 100 ms en el encendido de la pantalla, 19 R4). No lee `reducir_sobresaltos` (19 D19-12) | — |
| 21 Director de escenas | `reducir_movimiento` en cada disparo (atenuación única en lugar del parpadeo, aparición gradual del reflejo, `d_cierre` de 0,1 s; 21 regla 23) | — |
| 25 Menú de pausa · 30 Accesibilidad · 27 Pantalla de título | Valor actual de los ajustes que muestran | Escrituras del jugador y peticiones de restablecer |
| 5 Guardado y carga | Ninguna: ficheros independientes; los ajustes quedan fuera de la partida (regla 3) | — |
| 3 Estado y bus de eventos | Nada | Nada |

## Formulas

Propuestas por `systems-designer`. † = valor propuesto, **a validar en playtest**. Los valores que se leen de `assets/data/settings/defaults.json` (regla 14) se marcan «data file». El sistema no define presupuesto de rendimiento y no se inventa uno.

### F1 · Pasos del deslizador de volumen (y de todo `float` con paso)

La fórmula de pasos del deslizador se define como (redondeo de la mitad hacia arriba: 0,025 × 20 = 0,5 → n = 1):

`n = floor(v_ui × N_pasos + 0,5);   v = n / N_pasos`

Se generaliza a `campo_vision`: `n = floor((fov − 60) / 5 + 0,5)`, `fov = 60 + 5n`, n de 0 a 6 (72 → 70; 72,5 → 75; 90,0 → 90; 95 → 90 y se registra). Y a `multiplicador_pie`: `n = floor((m − 1,0) / 0,25 + 0,5)`, `m = 1,0 + 0,25n`, n de 0 a 8 (1,3 → 1,25; 1,125 → 1,25; 3,5 → 3,0 y se registra). Las demás reglas de F1 (comparar `n`, no el float) valen igual.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| v_ui | float | 0–1 (ya ajustado al rango) | calculated | Valor entregado por el deslizador de la interfaz |
| N_pasos | int | 10–40 | data file, 20† | Número de pasos del deslizador |
| n | int | 0 a N_pasos | calculated | Índice de paso |
| v | float | 0–1 | calculated | Valor guardado en `vol_voces`, `vol_efectos` o `vol_musica` |

**Output Range:** con N_pasos = 20, v toma los valores 0; 0,05; …; 1, en pasos del 5 %; con la curva de F2 cada paso son 2 dB, por encima del umbral de diferencia perceptible (~1 dB). Con 10 pasos serían 4 dB (brusco con mando); con 40, 1 dB (apenas notable). **El cambio «real» se decide comparando `n`, no el float**, para evitar falsos cambios por deriva de coma flotante: si `n` no cambia no hay aviso de cambio (regla 7) ni marca de pendiente de guardado (F3).
**Example:** v_ui = 0,512 → n = round(10,24) = 10 → v = 0,5.

### F2 · Curva de volumen

La fórmula de curva de volumen se define como:

`vol_db = (n = 0) ? silencio : db_min × (1 − v);    ganancia_lineal = 10^(vol_db / 20)  (0 si silencio)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| v | float | 0–1 | calculated | Valor del ajuste ya validado (F1) |
| db_min | float (dB) | −60 a −30 | data file, −40† | dB en el extremo bajo de la curva |
| silencio | bool | {sí, no} | calculated | Verdadero solo si n = 0 |
| vol_db | float (dB) | de db_min·(1 − 1/N_pasos) a 0 | calculated | Ganancia que recibe el director de audio (23) |
| ganancia_lineal | float | 0, o de 0,0126 a 1 | calculated | Equivalente lineal de vol_db |

**Output Range:** mínimo no silencioso −38 dB (n = 1, ganancia 0,0126); máximo 0 dB (n = N_pasos, ganancia 1,0, sin amplificación). Con n = 0 la salida es `silencio = sí` y ganancia lineal exactamente 0: **nunca se emite −inf** ni se calcula `log(0)`. Hay una discontinuidad intencionada entre el paso 1 (−38 dB) y el silencio. Se eligió lineal en dB porque el oído percibe la sonoridad de forma aproximadamente logarítmica (lineal en amplitud concentra el cambio audible en el primer tercio del deslizador; una potencia no tiene suelo y su pendiente en dB varía).
**Example (db_min = −40):**
| v | vol_db | ganancia_lineal |
|---|---|---|
| 0 | silencio | 0 |
| 0,25 | −30 | 0,0316 |
| 0,5 | −20 | 0,1000 |
| 0,75 | −10 | 0,3162 |
| 1 | 0 | 1,0 |

**Casos límite:** un valor fuera de rango se ajusta antes de cuantizar (1,7 → 1; −0,3 → 0; ±infinito → 1 o 0) y se registra. **NaN:** un ajuste no lo arregla, así que se comprueba antes y se trata como escritura inválida (regla 6): en ejecución se conserva el valor anterior y se registra; al cargar el fichero se usa el valor inicial. NaN nunca llega a la curva. Si `N_pasos` o `db_min` están fuera de su rango al cargar `defaults.json`, los datos son inválidos y se aplica el caso de catálogo corrupto (ver Edge Cases): el juego no entra en partida, así que no hay división por cero. En silencio no existe `vol_db`: el director de audio recibe la marca de silencio y ganancia 0.

### F3 · Guardado diferido

La fórmula de guardado diferido se define como:

`escribir ⇔ pendiente ∧ ( (t − t_ult ≥ t_guardado) ∨ (t − t_prim ≥ t_guardado_max) ∨ cierre ∨ pausa )`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pendiente | bool | {sí, no} | calculated | Hay cambios reales sin escribir a disco |
| t | float (s) | ≥ 0 | calculated | Reloj monotónico en tiempo real: no lo afecta la pausa ni la escala de tiempo del juego |
| t_ult | float (s) | ≤ t | calculated | Instante del último cambio real |
| t_prim | float (s) | ≤ t | calculated | Instante del primer cambio desde la última escritura |
| t_guardado | float (s) | 0,2–2,0 | data file, 0,5† | Silencio necesario para escribir |
| t_guardado_max | float (s) | 2,0–30,0 | data file, 5,0† | Espera máxima desde el primer cambio pendiente |
| cierre, pausa | bool | {sí, no} | calculated | Cierre normal del juego; apertura del menú de pausa (regla 13) |

**Output Range:** booleano. Con cambios continuos hay como máximo una escritura cada `t_guardado_max` (0,2 escrituras/s con los valores propuestos); sin cambios continuos, una por ráfaga. La pérdida máxima ante un cierre forzado es `t_guardado_max` (5 s de cambios). Restricción de datos: `t_guardado_max ≥ 2 × t_guardado`; si no se cumple, o si algún parámetro de F1 a F3 está fuera de su rango, los datos son inválidos (catálogo corrupto, ver Edge Cases).
**Reglas de la escritura:** al marcar pendiente con `pendiente` falso, `t_prim = t`; cada cambio real hace `t_ult = t`. La escritura toma una instantánea: un cambio que llegue durante la escritura vuelve a marcar pendiente y no se pierde; al terminar con éxito, `pendiente` pasa a falso solo si no hubo cambios posteriores a la instantánea. Un fallo de escritura mantiene `pendiente`, registra una línea y reintenta tras `t_guardado_max`; nunca bloquea ni avisa al jugador.
**Example:** un arrastre de 12 s con un cambio real cada 0,05 s escribe en t = 5 y t ≈ 10,05 (tope: el primer cambio tras la escritura de t = 5 marca `t_prim` = 5,05, hasta 0,05 s después) y, al soltar en t = 12, en t = 12,5 (silencio de 0,5 s): 3 escrituras en vez de unas 240. Un cambio suelto en t = 3 se escribe en t = 3,5. Justificación de 0,5 s: más largo que la pausa típica entre pulsaciones de mando (~0,15–0,3 s) y más corto que lo que tarda un jugador en cerrar el juego tras ajustar; 5 s limita las escrituras a disco y la pérdida ante un cierre forzado.

## Edge Cases

**Fichero y arranque**
- **If el fichero no existe (primer arranque)**: todos los ajustes toman su valor inicial; no es un error y no se registra como tal. El fichero se crea con el primer cambio.
- **If el fichero existe pero es ilegible o no tiene estructura válida**: regla 11 (valores iniciales, copia del dañado, línea en el log). Se conserva una sola copia: si ya había una de un fallo anterior, la nueva la sustituye.
- **If no se puede renombrar el fichero dañado a copia** (solo lectura, permisos): el juego arranca igual con los valores iniciales y registra una línea; el fichero dañado queda en su sitio y el primer guardado atómico lo sustituye (única excepción a «conservar el dañado»).
- **If el fichero no declara versión o esta no es numérica**: se trata como ilegible (copia + valores iniciales).
- **If el fichero declara una versión de formato mayor que la conocida** (p. ej. se abrió con una build más nueva): se trata como ilegible (copia + valores iniciales), porque no se puede garantizar el significado de sus claves.
- **If el fichero declara una versión menor**: se leen las claves reconocidas y las que faltan toman su valor inicial. En el slice no hay migraciones.
- **If una clave del fichero es inválida** (tipo, `enum` o NaN): solo ese ajuste vuelve a su valor inicial y se registra; el resto se conserva (regla 10). Un `float` fuera de rango no es inválido: se ajusta al límite más cercano y se registra.
- **If el bloque `controles` del fichero es ilegible**: Entrada usa sus asignaciones por defecto (sus casos límite); el resto de los ajustes no se ve afectado.
- **If queda un fichero temporal huérfano de una escritura interrumpida**: se ignora al leer y se elimina; el fichero principal sigue siendo el válido (regla 13, escritura atómica).
- **If se lee o escribe un ajuste antes de «Listo»**: en desarrollo, error visible que detiene la ejecución; en la build final, la escritura se descarta y se registra, y la lectura devuelve el valor inicial del catálogo si se pudo leer, o si no uno seguro (volumen 1,0, subtítulos verdadero, `modo_ventana` = `ventana`, `controles` ausente, resto falso; `campo_vision` 70 y `balanceo_camara` `reducido`) y se registra. `modo_ventana` = `ventana` es intencionado y difiere del inicial del catálogo: sin catálogo fiable no se toca el monitor del jugador ni se fuerza pantalla completa. El orden de arranque garantiza en la práctica que no ocurre; lo fija el ADR.
- **If `defaults.json` falta, está corrupto o tiene un parámetro fuera de su rango** (`N_pasos`, `db_min`, `t_guardado`, `t_guardado_max` o la restricción de F3): el juego no entra en partida y muestra un mensaje de error claro, igual que los otros sistemas de datos (3 y 18); sin catálogo no hay valores iniciales fiables.

**Escritura y guardado**
- **If la carpeta de datos del usuario no existe**: se crea; si no se puede, se trata como un fallo de escritura.
- **If la escritura falla** (disco lleno, sin permisos, solo lectura): los valores siguen vigentes en memoria durante la sesión, `pendiente` se mantiene, se registra una línea y se reintenta tras `t_guardado_max`; nunca se bloquea ni se avisa al jugador (F3).
- **If el jugador cierra el juego con cambios pendientes**: se escribe al cerrar (regla 13); si esa escritura falla, se pierden. **If el cierre es forzado** (proceso terminado): se pierde como máximo `t_guardado_max` de cambios.
- **If hay dos instancias del juego abiertas**: la última en escribir gana; no hay bloqueo de fichero (fuera del alcance del slice).
- **If se pausa el juego con cambios pendientes**: el guardado usa el reloj de tiempo real, así que la pausa no lo congela; además abrir el menú de pausa fuerza la escritura.

**Valores y avisos**
- **If se escribe NaN o ±infinito en un `float`**: NaN se rechaza como valor inválido (regla 6 y F2); ±infinito se ajusta al límite correspondiente.
- **If se escribe el mismo valor (o un valor que cae en el mismo paso `n`, F1)**: no hay aviso ni marca de pendiente.
- **If un suscriptor, al recibir un aviso de cambio, escribe otro ajuste**: el valor se aplica en el acto y su aviso se encola hasta terminar la entrega en curso (regla 7); un bucle de avisos encadenados se corta con el mismo tope de seguridad que el bus de eventos (valor fijado en el ADR).
- **If dos pantallas escriben el mismo ajuste en el mismo fotograma**: se procesan en el orden en que llegaron; gana la última.
- **If se restablece mientras hay cambios pendientes**: se aplican los valores iniciales, se emiten los avisos de los ajustes que cambian y se marca pendiente (se escribirá por F3).
- **If `reducir_sobresaltos` o `subtitulos_activos` cambian durante una escena en curso** (p. ej. el apagón): este sistema solo emite el aviso; cómo reacciona la escena lo decide cada consumidor (23, 26, 28). Un valor ya reproducido no se rebobina.

**Ventana**
- **If el sistema operativo rechaza el cambio de `modo_ventana`**: el ajuste vuelve al valor realmente aplicado, se emite el aviso de cambio correspondiente y se registra; no se bloquea. **Si ocurre durante «Cargando»** (al aplicar el modo guardado) no se emite aviso aparte: el ajuste conserva el valor real, se registra una línea y los consumidores lo leen al recibir «ajustes aplicados».
- **If el jugador cambia el modo de ventana fuera del juego** (p. ej. `Alt+Intro` del sistema operativo): el ajuste se sincroniza con el valor real observado y se guarda por F3.
- **If el modo guardado es `pantalla_completa` y el monitor ya no está**: el motor decide el monitor; el ajuste conserva su valor y se aplica en el que haya.

## Dependencies

**Aguas arriba (de qué depende):** el sistema 1 (Entrada y controles), **dura en cuanto a contrato**: el formato del bloque `controles` lo define Entrada (reglas 18 y 19 de su GDD) y este sistema lo guarda sin interpretarlo; en ejecución funciona sin él, simplemente sin bloque que guardar. **Es una dependencia blanda de 6 hacia 1 (la declara 6, el dependiente), no un ciclo duro:** 1 declara «ninguna dura» aguas arriba y no depende de 6 en ejecución (usa los valores del `InputMap` por defecto si Ajustes falta); el contrato del formato del bloque lo fija 1 y 6 solo lo almacena. Necesita además su fichero de valores iniciales (`assets/data/settings/defaults.json`, definido por este GDD) y la capacidad del motor de leer y escribir ficheros en la carpeta de datos del usuario. No depende del sistema 3: el aviso de cambio es propio (regla 7). **18 Base de contenido narrativo, blanda** (la declara 18, el proveedor, y 6 la repite): los rótulos `UI_…` de las pantallas de ajustes viven en 18; sin el catálogo se usa el texto de emergencia de 18. 6 no lee ni escribe nada de 18 en ejecución.

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él pero su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 23 Director de audio | Dura | Lee `vol_voces`, `vol_efectos`, `vol_musica`, `reducir_sobresaltos`; se suscribe a los avisos de cambio |
| 26 Subtítulos | Dura | Lee `subtitulos_activos`; se suscribe a los avisos de cambio |
| 25 Menú de pausa | Dura | Muestra y escribe ajustes; usa «restablecer» |
| 30 Opciones de accesibilidad | Dura | Muestra y escribe ajustes de accesibilidad; usa «restablecer» |
| 27 Pantalla de título y cierre | Blanda | Muestra y escribe ajustes desde el título |
| 28 Atmósfera reactiva | Blanda | Lee `reducir_sobresaltos` (parpadeo del pasillo y apagón) |
| 2 Jugador en primera persona | Blanda | Lee `balanceo_camara` y `campo_vision` (GDD 2, reglas 16 y 17); aplicación inmediata |
| 9 Marco de puzles (13 y 15 vía el marco) | Blanda | Lee `asistencia_encaje`, `asistencia_rotacion` y `reducir_movimiento` |
| 7 Interacción e inspección | Blanda | Lee `multiplicador_pie` y `pie_persistente` (F5 de ese GDD); sin Ajustes usa 1,0 y falso |
| 18 Base de contenido narrativo | Blanda (aguas arriba: 6 depende de 18 para sus rótulos `UI_…`; ver el párrafo de aguas arriba) | Aloja los textos de interfaz `UI_…` de las pantallas de ajustes (25, 27, 30); no lee ni escribe ajustes. Relación que el índice ya recoge (fila 6: «blanda 18») |
| 4 Escena de planta | Blanda | Lee `reducir_movimiento` (cortina); exige que el nodo de Ajustes sobreviva a los cambios de escena (su regla 1, AC-01) |
| 19 Ordenador, correo e impresora | Blanda | Lee `reducir_movimiento` (fundido de 100 ms, 19 R4); sin Ajustes usa falso (transición normal) |
| 21 Director de escenas | Blanda | Lee `reducir_movimiento` en cada disparo de escena (21 regla 23, DT-12); sin Ajustes usa falso |
| 1 Entrada y controles | Blanda (contrato de formato; no hay ciclo duro: 1 no depende de 6 en ejecución; antes «Dura (su lado)») | Entrega y recupera el bloque `controles` |
| 24 Pie de texto (dibuja el pie) | Blanda (sin GDD aún) | Lee `multiplicador_pie` y `pie_persistente` para dibujar el pie de texto; al redactarse debe listar a Ajustes como dependencia |
| 5 Guardado y carga | Ninguna | Ficheros independientes; retirada por el GDD 5 (regla 4, D-12) |

**Índice de sistemas:** los puzles 13 y 15 y la atmósfera 28 ya listan al sistema 6 como dependencia; la dependencia del sistema 5 está retirada (el índice ya no la lista). La fila 6 del índice dice «1 (dura de contrato) · blanda 18». Las durezas de la tabla de arriba son las que declaran los dependientes (1 blanda, antes «dura de contrato», ver D-6.5; 2, 4, 7, 9, 19 y 21 blandas); el índice ya lista a 7 («blandas: 3, 6»; A14), así que no falta nada.

**Bidireccionalidad.** El par con el sistema 1 está cerrado: Entrada ya lista a Ajustes como dependiente (su tabla de Dependencies y su regla 19). El GDD del 3 ya declara que los ajustes quedan fuera del estado (regla 14), y su tabla de interacciones dice «Nada». Los GDDs que ya existen y se relacionan con este sistema son: 1 Entrada y controles (bloque `controles`, blanda: 6 depende de 1 en blando por el formato del contrato; ningún ciclo duro), 2 Jugador (`balanceo_camara`, `campo_vision`), 4 Escena de planta (`reducir_movimiento`, supervivencia del nodo), 7 Interacción (`multiplicador_pie`, `pie_persistente`), 9 Marco de puzles (asistencias y `reducir_movimiento`), 18 Base de contenido (textos `UI_…`), 19 Ordenador y 21 Director de escenas (`reducir_movimiento`); el 3 los deja fuera del estado y el 5 no tiene relación. 22 Llamada telefónica existe y **no depende de 6** (no lee ninguna clave: `reducir_sobresaltos` lo gestiona 23, D22-19, y `SUB_BREATH_BROKEN` depende de `subtitulos_activos` a través de 26; sin dependencia directa en ambos lados, confirmado). Los demás sistemas de la tabla (23, 24, 25, 26, 27, 28, 30) aún no tienen GDD: cada uno debe, al redactarse, listar a Ajustes como dependencia y usar las claves del catálogo de la regla 1.

## Tuning Knobs

| Parámetro | Valor † | Rango seguro | Qué afecta |
|---|---|---|---|
| `N_pasos` | 20 | 10–40 | Granularidad de los volúmenes (2 dB por paso con `db_min` −40) |
| `db_min` | −40 dB | −60 a −30 | Suelo de la curva de volumen; subir a −50 si la voz de Vera se pierde en el paso 1 |
| `t_guardado` | 0,5 s | 0,2–2,0 s | Silencio necesario antes de escribir el fichero |
| `t_guardado_max` | 5,0 s | 2,0–30,0 s (≥ 2 × `t_guardado`) | Pérdida máxima ante cierre forzado y frecuencia de escrituras |
| `multiplicador_pie` | 1,0 | 1,0–3,0, paso 0,25 | Cuánto se alarga el pie de texto para quien no llega a leerlo (regla 1; lo consume F5 de 7) |
| `fov_step_deg` (paso de `campo_vision`) | 5° | 1–15† | Rejilla del campo de visión (`fov = 60 + 5n`, F1 generalizada). El rango 60–90 es el de la clave `campo_vision`, **no** el del paso; el registro tiene `fov_step_deg` con su rango propio (W-9) |
| `pie_persistente` | falso | bool | Si el pie dura hasta que cambie el objetivo (regla 1) |
| Valores iniciales y rangos del catálogo | regla 1 | los de cada clave | Primera experiencia del jugador; en `defaults.json` |

## Visual/Audio Requirements

*(Sección opcional para la categoría Persistence; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

El sistema no tiene presentación propia. Solo condiciona a quienes la ponen:
- **Audio:** los deslizadores de volumen deben dar al jugador una referencia al moverlos (propuesta: una muestra corta del bus que se está regulando al soltar el deslizador o al cambiar de paso), porque sin ella el jugador ajusta a ciegas en un juego cuyo susto es sonoro. La muestra y su mezcla las define el director de audio (23).
- **Visual:** `reducir_sobresaltos` debe atenuar el parpadeo del pasillo y el apagón, con un límite de destellos por segundo (art bible, sección de fotosensibilidad); el valor lo define la atmósfera reactiva (28).

## Game Feel

No aplica: el jugador no opera este sistema directamente. Lo único exigible es que un cambio de ajuste llegue a sus consumidores en el mismo fotograma en que se escribe, salvo cuando su aviso se encola por una entrega en curso (regla 7), y que cada paso de un deslizador de volumen sea de 2 dB con los valores propuestos, uniforme en todo el recorrido (F1 y F2).

## UI Requirements

El sistema no tiene pantalla propia; las ponen el menú de pausa (25), las opciones de accesibilidad (30) y la pantalla de título (27). Requisitos que este GDD fija a esas pantallas:
- **Deslizadores de volumen:** `N_pasos` pasos (20†) con el valor visible, operables con ratón y con mando (`ui_izquierda` y `ui_derecha` mueven un paso, Entrada regla 15), y con el silencio claramente distinguible del paso más bajo.
- **Conmutadores:** `subtitulos_activos`, `reducir_sobresaltos`, `reducir_movimiento`, `asistencia_encaje`, `asistencia_rotacion`, `pie_persistente` y `modo_ventana`, con su valor actual siempre visible.
- **Deslizador de paso:** `multiplicador_pie` (1,0 a 3,0 en pasos de 0,25, valor visible; mismo manejo que los volúmenes).
- **Restablecer:** «restablecer» por ajuste y «restablecer todos» (regla 8), con confirmación en este último porque cambia varios valores a la vez.
- **Sin mensajes por ficheros dañados:** el jugador no ve ningún aviso cuando el fichero de ajustes falta o se recupera (regla 11).
- **Textos:** todos los rótulos de las pantallas son entradas `UI_…` de la base de contenido (18).

📌 **UX Flag — Ajustes persistentes**: este sistema tiene requisitos de interfaz repartidos entre varias pantallas. En la fase de preproducción, ejecuta `/ux-design` para las opciones de audio, subtítulos, accesibilidad y pantalla antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §5, §14, §16 | Accesibilidad: subtítulos, remapeo, regulación independiente de voces, efectos y música, reducir sobresaltos; el menú de pausa incluye subtítulos, controles y accesibilidad | Define el catálogo de la regla 1 |
| `design/slice/slice-v0.3.md` · Anexo B.3 y B.5 | «Asistencia de encaje» (0,10 m) y tolerancia asistida (±6°) | Origen de `asistencia_encaje` y `asistencia_rotacion` |
| `design/slice/slice-v0.3.md` · §21 | PC (Windows y Linux), 1920 × 1080 con escalado, solo español | Base de `modo_ventana` y de que no haya ajuste de idioma |
| `design/slice/slice-v0.3.md` · D.3 | Autoguardado de la partida con reglas fijas | Justifica que no haya ajuste de autoguardado y que los ajustes queden fuera de la partida |
| `design/art/art-bible.md` · fotosensibilidad | Límite de destellos y atenuación con «reducir sobresaltos» | Condiciona `reducir_sobresaltos` (28) |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Autonomía como progresión* | Pilares que este sistema sirve |
| `design/gdd/estado-y-bus-de-eventos.md` · regla 14, CA-24 y regla 11 | Los ajustes quedan fuera del estado y de la instantánea; reglas de entrega de avisos | Origen de la regla 3 y patrón de la regla 7 |
| `design/gdd/entrada-y-controles.md` · reglas 15 a 19 y AC-18 | Reasignación, ajustes de manejo y bloque exportable de asignaciones | Origen de `controles` (regla 2) |
| `design/gdd/base-de-contenido-narrativo.md` | Textos de interfaz `UI_…` | Rótulos de las pantallas de ajustes |
| `design/gdd/systems-index.md` | Fila 6 y dependientes 2, 4, 7, 9, 23, 25, 26, 27, 28, 30, 13 y 15, más la relación con 18 (textos `UI_…`; el 5 está retirado) | Debe reflejar la tabla de Dependencies |
| `design/gdd/escena-de-planta.md` · regla 1 y AC-01 | Nodo de Ajustes persistente entre escenas; cortina con `reducir_movimiento` | Condición de arranque y lector de la clave |
| `design/art/art-bible.md` · §7.4 | «Reducir movimiento» | Origen de `reducir_movimiento` |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/settings/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante. Los tests L **no hacen E/S real**: usan un almacenamiento falso, un reloj inyectado (ticks enteros, sin acumular error de coma flotante), un manejador de errores y un destino de log sustituibles, y una fixture de `defaults.json` por caso. Solo los criterios I tocan el disco. Tolerancia numérica ±0,0001 salvo indicación. «Se cierra cuando exista X» marca un criterio que depende de un sistema sin GDD. El sistema no define presupuesto de rendimiento y no se inventa uno.

**Catálogo y lectura (reglas 1 a 5)**
- **AC-01 (R1, L)**: **GIVEN** el `defaults.json` del slice, **WHEN** se leen las trece claves con valor (los tres volúmenes, `subtitulos_activos`, `reducir_sobresaltos`, `reducir_movimiento`, las dos asistencias, `balanceo_camara`, `campo_vision`, `multiplicador_pie`, `pie_persistente` y `modo_ventana`), **THEN** cada una coincide en tipo, rango e inicial con la tabla de la regla 1; **WHEN** se lee `controles` sin bloque guardado, **THEN** devuelve «ausente»; **WHEN** se escribe una clave que no está en el catálogo, **THEN** se rechaza (regla 6).
- **AC-02 (R4-5, L)**: **GIVEN** `vol_musica` = 1,0, **WHEN** se escribe 0,5, **THEN** la lectura inmediata devuelve 0,5. Igual con un `bool` (`subtitulos_activos` a falso) y con un `enum` (`modo_ventana` a `ventana`).
- **AC-03a (R3, L)**: **GIVEN** `vol_voces` = 0,5, **WHEN** se serializa la instantánea del estado (3), **THEN** no contiene ninguna clave de ajustes.
- **AC-03b (R3, I)**: **GIVEN** una partida guardada y un ajuste cambiado, **THEN** el fichero de partida no cambia (mismo hash), y empezar partida nueva o cargar otra no altera ningún ajuste. *(Se cierra cuando existan 3 y 5.)*
- **AC-04a (R2, L)**: **GIVEN** un bloque `controles` cualquiera, **WHEN** se guarda y se recarga, **THEN** es estructuralmente idéntico (igualdad profunda, no de bytes); **GIVEN** que no hay bloque, **THEN** se arranca sin error.
- **AC-04c (R2, R6-7, L)**: **WHEN** Entrada escribe un bloque distinto del guardado, **THEN** se emite un aviso con solo la clave `controles` y queda pendiente; **WHEN** escribe un bloque profundamente igual, **THEN** no hay aviso ni pendiente; **WHEN** se escribe un escalar en `controles`, **THEN** se rechaza (regla 6).
- **AC-04d (R1, R6, L)**: **WHEN** se escribe 72 en `campo_vision`, **THEN** se guarda 70; 90,0 se guarda 90; 95 se guarda 90 con una línea en el log; 72 tras 70 no emite aviso (mismo `n`). **GIVEN** 72 en el fichero, **THEN** se carga como 70.
- **AC-04e (R1, R8, L)**: **GIVEN** `reducir_movimiento` ausente en el fichero, **THEN** vale falso; **WHEN** se escribe verdadero, **THEN** la lectura devuelve verdadero y se emite un aviso (`reducir_movimiento`, falso, verdadero).
- **AC-04f (R1, R6, R8, L)**: **GIVEN** `multiplicador_pie` ausente en el fichero, **THEN** vale 1,0; **WHEN** se escribe 1,3, **THEN** se guarda 1,25; 3,5 se guarda 3,0 con una línea en el log; 0,5 se guarda 1,0; 1,3 tras 1,25 no emite aviso (mismo `n`); 2,0 emite (`multiplicador_pie`, 1,25, 2,0). **WHEN** se escribe un NaN o un valor no numérico, **THEN** se rechaza (regla 6). **GIVEN** 1,3 en el fichero, **WHEN** se carga, **THEN** vale 1,25.
- **AC-04g (R1, R7, R8, L)**: **GIVEN** `pie_persistente` ausente en el fichero, **THEN** vale falso; **WHEN** se escribe verdadero, **THEN** la lectura devuelve verdadero y se emite un aviso (`pie_persistente`, falso, verdadero); escribir verdadero otra vez no emite; un valor no booleano se rechaza (regla 6); **WHEN** se restablece ese ajuste, **THEN** vuelve a falso con su aviso.
- **AC-04b (R2, L)**: **GIVEN** un fichero con el bloque `controles` ilegible y el resto válido, **WHEN** se carga, **THEN** se llega a «Listo», los demás ajustes conservan su valor y `controles` queda «ausente». *(La reacción de Entrada se cierra cuando exista el sistema 1.)*

**Escritura inválida y avisos (reglas 6 a 8)**
- **AC-05a (R6, L)**: **WHEN** se escribe 1,7 en un volumen, **THEN** se guarda 1,0 y se añade una línea al log; con −0,3, 0,0 y una línea; con +∞, 1,0; con −∞, 0,0.
- **AC-05b (R6, L)**: **GIVEN** `vol_voces` = 0,5, **WHEN** se escribe NaN, **THEN** el valor sigue en 0,5 y se añade una línea al log.
- **AC-05c (R6, L)**: **GIVEN** la build final, **WHEN** se escribe una clave desconocida, la cadena `"0,5"` en un `float` o `"ventana2"` en `modo_ventana`, **THEN** cada escritura se rechaza, el valor anterior se conserva y se añade una línea al log por escritura.
- **AC-05d (R6, I)**: **GIVEN** una build de desarrollo, **WHEN** se hace cualquiera de las escrituras inválidas de AC-05b o AC-05c, **THEN** la ejecución se detiene con un error visible.
- **AC-06a (R7, L)**: **GIVEN** un suscriptor, **WHEN** `vol_musica` pasa de 1,0 a 0,5, **THEN** recibe exactamente una vez (`vol_musica`, 1,0, 0,5).
- **AC-06b (R7, L)**: **WHEN** se escribe el mismo valor, o un valor que cae en el mismo paso `n` (F1), **THEN** no se emite aviso.
- **AC-06c (R7, L)**: **GIVEN** los suscriptores A y B (en ese orden), **WHEN** cambia un ajuste, **THEN** reciben en el orden A, B.
- **AC-06d (R7, L)**: **GIVEN** un suscriptor que, al recibir el aviso de X, escribe Y, **THEN** la lectura de Y dentro del manejador ya devuelve el valor nuevo, el aviso de Y se entrega después de que X llegue a todos y no hay invocaciones anidadas.
- **AC-06e (R7, L)**: **GIVEN** que A se da de baja durante una entrega, **THEN** A aún recibe el aviso en curso y no recibe ningún aviso posterior.
- **AC-06f (R7, L)**: **GIVEN** dos escrituras del mismo ajuste en el mismo fotograma (0,5 y después 0,7), **THEN** gana la última (lectura = 0,7) y los avisos llegan en el orden de las escrituras: (1,0 → 0,5) y (0,5 → 0,7).
- **AC-06g (R7, L)**: **GIVEN** un suscriptor que vive en la escena de planta (nodo hijo de ella), **WHEN** la planta se descarga, **THEN** queda dado de baja sin llamada explícita; **WHEN** después cambia un ajuste, **THEN** no recibe el aviso, no hay error ni referencia colgante y los demás suscriptores lo reciben con normalidad; si la descarga ocurre dentro de una entrega en curso, la baja se hace efectiva al terminar esa entrega.
- **AC-07a (R8, L)**: **GIVEN** `vol_musica` = 0,5, **WHEN** se restablece solo ese ajuste, **THEN** vale su inicial (1,0), se emite un solo aviso (`vol_musica`, 0,5, 1,0), los demás ajustes no cambian y quedan cambios pendientes; **WHEN** se restablece un ajuste que ya vale su inicial, **THEN** no se emite aviso.
- **AC-07 (R8, L)**: **GIVEN** `vol_voces` = 0,5 y `vol_efectos` = 1,0 (ya inicial), **WHEN** se restablecen todos (las 12 claves de la regla 8, incluidas `reducir_movimiento`, `multiplicador_pie` y `pie_persistente`), **THEN** se emite un solo aviso (`vol_voces`, 0,5, 1,0) y ninguno para `vol_efectos`; **GIVEN** además `reducir_movimiento` = verdadero, `multiplicador_pie` = 2,0 y `pie_persistente` = verdadero, **THEN** sus avisos (verdadero, falso), (2,0, 1,0) y (verdadero, falso) también se emiten; `modo_ventana` y `controles` no cambian y el sistema queda con cambios pendientes de guardar.

**Fichero, carga y guardado (reglas 9 a 14)**
- **AC-08a (R10, L)**: **GIVEN** que no hay fichero, **WHEN** se carga, **THEN** los ajustes valen su inicial, el log no contiene ninguna línea de error o aviso y no se abre ningún diálogo.
- **AC-08b (R13, L)**: **GIVEN** que no hay fichero y un cambio en t = 3 s, **THEN** el fichero existe en t = 3,5 s; **GIVEN** que la carpeta de datos no existe, **THEN** se crea, y si no se puede cuenta como fallo de escritura (AC-14e).
- **AC-09 (R10, L)**: **GIVEN** un fichero con una clave de tipo inválido, un `enum` fuera de lista o NaN, y otras válidas, **WHEN** se carga, **THEN** solo esa clave toma su inicial y se añade una línea al log por clave inválida; **GIVEN** `vol_musica` = −0,3 (o 1,7) en el fichero, **THEN** se carga como 0,0 (o 1,0), con una línea en el log; **GIVEN** una clave desconocida, **WHEN** se hace un guardado posterior, **THEN** el fichero no la contiene.
- **AC-10a (R11, L)**: **GIVEN** un fichero ilegible, **WHEN** se carga, **THEN** se llega a «Listo» con todos los iniciales, el contenido original está byte a byte en la copia, existe una línea en el log y no hay diálogo. Igual con un fichero legible pero con estructura inválida.
- **AC-10b (R11, L)**: **GIVEN** que ya existe una copia de un fallo anterior, **WHEN** se corrompe de nuevo, **THEN** queda una sola copia, con el contenido de la segunda.
- **AC-10c (R11, L)**: **GIVEN** un fichero ilegible y un almacenamiento falso que falla al renombrar, **WHEN** se carga, **THEN** se llega a «Listo» con todos los iniciales, hay una línea en el log y no hay diálogo; **WHEN** se produce el primer guardado, **THEN** el fichero principal pasa a ser el nuevo y válido.
- **AC-11a (R9-10, L)**: **GIVEN** una versión de formato mayor que la conocida, **THEN** se trata como AC-10a; **GIVEN** una menor, **THEN** se leen las claves reconocidas y las ausentes toman su inicial.
- **AC-11b (R9-10, L)**: **GIVEN** un fichero sin versión o con versión no numérica, **THEN** se trata como ilegible (AC-10a).
- **AC-12 (R10, L)**: **GIVEN** un fichero válido con valores distintos de los iniciales, **WHEN** termina la carga, **THEN** el sistema está en «Listo» **antes** de emitir, un suscriptor recibe un único «ajustes aplicados», ningún aviso de cambio por ajuste, y una lectura dentro del manejador ya devuelve los valores cargados sin error (también en desarrollo); lo mismo con un fichero corrupto (valores iniciales).
- **AC-13 (R12, I)**: **GIVEN** el juego en marcha, **WHEN** se cambia `modo_ventana`, **THEN** se aplica sin reiniciar; **WHEN** el sistema operativo lo rechaza, **THEN** el ajuste vuelve al valor realmente aplicado, se emite el aviso de cambio y se añade una línea al log; **WHEN** el modo se cambia fuera del juego, **THEN** el ajuste se sincroniza y se guarda. Se aplica también al cargar; si el sistema operativo lo rechaza durante «Cargando», el ajuste conserva el valor real, se añade una línea al log y no se emite aviso de cambio aparte. *(El caso del monitor ausente es manual y consultivo. «Fuera del juego» depende de la plataforma objetivo.)*
- **AC-14a (F3, L)**: **GIVEN** `t_guardado` = 0,5 s y `t_guardado_max` = 5,0 s, **WHEN** hay un único cambio real en t = 3,0, **THEN** se escribe en t = 3,5.
- **AC-14b (F3, L)**: **GIVEN** un arrastre de 12 s con un cambio real cada 0,05 s que oscila entre pasos distintos, **THEN** hay exactamente 3 escrituras y cada una ocurre como mucho `t_guardado_max` después del primer cambio que contiene.
- **AC-14c (F3, L)**: **GIVEN** cambios pendientes, **WHEN** se cierra el juego con normalidad o se abre el menú de pausa, **THEN** se escribe en el acto; **GIVEN** que no hay cambios pendientes, **THEN** ninguno de los dos escribe.
- **AC-14d (F3, L)**: **GIVEN** un cambio llegado durante una escritura, **WHEN** esta termina con éxito, **THEN** sigue habiendo cambios pendientes y se escribirá de nuevo; **GIVEN** la pausa del juego con tiempo de juego detenido, **THEN** el temporizador del guardado sigue avanzando (reloj de tiempo real).
- **AC-14e (F3, L)**: **GIVEN** un almacenamiento que falla al escribir, **THEN** los cambios siguen pendientes, se añade una línea al log, se reintenta a los `t_guardado_max` leídos de los datos y no se muestra nada al jugador; **GIVEN** que falla la escritura de cierre, **THEN** el cierre no se bloquea.
- **AC-15a (R13, L)**: **GIVEN** un almacenamiento falso que falla entre escribir el temporal y renombrarlo, **THEN** el fichero principal queda intacto.
- **AC-15b (R13, L)**: **GIVEN** un temporal huérfano al arrancar, **THEN** se ignora, se elimina y el principal sigue siendo el válido.
- **AC-15c (R13, I)**: **GIVEN** un corte real del proceso durante una escritura (opcional, sobre disco real), **THEN** el siguiente arranque llega a «Listo» con un fichero principal válido.
- **AC-16a (R14, L)**: **GIVEN** una fixture de `defaults.json` con `vol_voces` inicial = 0,5, **WHEN** arranca, **THEN** la lectura devuelve 0,5 sin recompilar.
- **AC-16b (R14, L)**: **GIVEN** una fixture con `t_guardado_max` < 2 × `t_guardado`, otra con `N_pasos` = 5, otra con `db_min` = 0, y una sin el fichero o corrupta, **WHEN** arranca, **THEN** en cada caso no se carga la escena de partida y se invoca el manejador de error fatal inyectado con el código `CATALOGO_INVALIDO` y el nombre del parámetro o fichero culpable (catálogo corrupto). El texto mostrado al jugador no depende de la base de contenido (18) ni de los ajustes.

**Estados (States and Transitions)**
- **AC-17a (L)**: **GIVEN** «Sin cargar» o «Cargando» y una build de desarrollo, **WHEN** se lee o se escribe, **THEN** hay un error visible (manejador de errores inyectado).
- **AC-17b (L)**: **GIVEN** la build final en esos estados, **WHEN** se escribe, **THEN** la escritura se descarta y se añade una línea al log; **WHEN** se lee, **THEN** devuelve el inicial del catálogo si se pudo leer, o si no el valor seguro (volumen 1,0, subtítulos verdadero, `modo_ventana` = `ventana` (intencionado, ver Edge Cases), `controles` ausente, `campo_vision` 70, `balanceo_camara` `reducido`, resto falso), con una línea al log.

**Fórmulas (valores del ejemplo, tolerancia ±0,0001)**
- **AC-F1 (L)**: **GIVEN** N_pasos = 20, **THEN** v_ui = 0,512 → n = 10 y v = 0,5; 0,026 → n = 1; 0,024 → n = 0; 0,025 → n = 1 (mitad hacia arriba); 1,0 → n = 20; con N_pasos = 10, cada paso son 4 dB, y con 40, 1 dB. **GIVEN** un volumen del fichero dentro de rango pero fuera de la rejilla (p. ej. 0,512), **WHEN** se carga, **THEN** se cuantiza a 0,5 (regla 10).
- **AC-F2a (L)**: **GIVEN** db_min = −40, **THEN** v = 0 → silencio con ganancia exactamente 0 y sin llamar a `log(0)` (nunca −∞); 0,25 → −30 dB / 0,0316; 0,5 → −20 / 0,1000; 0,75 → −10 / 0,3162; 1 → 0 / 1,0; n = 1 → −38 dB / 0,0126 (la comparación en dB usa tolerancia por el error de coma flotante de 1/20).
- **AC-F2b (L)**: **GIVEN** db_min = −50 y n = 1, **THEN** −47,5 dB / 0,0042; con db_min = −60 y −30, n = 1 da −57 y −28,5 dB. *(La entrega de la ganancia al bus se cierra cuando exista el sistema 23.)*

**Interacciones entre sistemas (se cierran cuando existan)**
- **AC-18b (I, `reducir_movimiento`)**: **GIVEN** 19 y 21, **WHEN** el jugador cambia `reducir_movimiento` en el menú de pausa, **THEN** la siguiente apertura de la pantalla del ordenador dura 100 ms ± 1 fotograma y el siguiente disparo de `LUCES_PARPADEO` es una atenuación única (consumidores 19 y 21; la escena en curso termina como se emitió). *(Se cierra con 25/30.)*
- **AC-18 (I)**: **GIVEN** el director de audio (23), subtítulos (26) y atmósfera (28), **WHEN** el jugador cambia `vol_*`, `subtitulos_activos` o `reducir_sobresaltos`, **THEN** cada consumidor reacciona en el mismo fotograma en que se recibe el aviso. *(Se cierra cuando existan 23, 26, 28 y las pantallas de 25, 27 y 30.)*

Sin criterio hasta que exista el ADR: el tope del bucle de avisos encadenados, la ruta y el formato de la copia del fichero dañado, y la representación de NaN en el fichero (JSON estándar no la admite).

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Ruta, formato y versionado del fichero** de ajustes; nombre y ruta de la copia del dañado; cómo se hace el reemplazo atómico; qué representa un NaN en el fichero (JSON estándar no lo admite); **no hay referencia de motor para el dominio Core** (`docs/engine-reference/godot/modules/` no tiene `core.md`), así que hay que verificarlo contra la documentación del motor. Dato ya conocido: desde 4.4 `FileAccess.store_*` devuelven `bool` (`breaking-changes.md`), lo que permite detectar fallos de escritura (F3, AC-14e); el ADR debe fijar también cómo se detecta el fallo del renombrado (regla 11, AC-10c). | `/architecture-decision` | Fase de arquitectura |
| 2 | **Mecanismo del aviso de cambio:** propio (regla 7) frente a unificarlo con el bus de eventos (3); y el tope de avisos encadenados. | `/architecture-decision` | Fase de arquitectura |
| 3 | **Orden de arranque:** garantizar que Ajustes está «Listo» antes de que lo lean audio, subtítulos, Entrada y las pantallas (edge case de lectura antes de «Listo»). | `/architecture-decision` | Fase de arquitectura |
| 4 | **Detección de un cambio externo del modo de ventana** (sondeo o señal del motor) para sincronizar `modo_ventana`. `DisplayServer` y `AudioServer` tampoco tienen referencia local en `docs/engine-reference/godot/`: pendiente de verificación. | `/architecture-decision` | Fase de arquitectura |
| 5 | **`asistencia_rotacion`:** el slice (B.5) nombra una tolerancia «asistido» de ±6° en el puzle 5 pero no una opción; el nombre y que sea un ajuste separado de `asistencia_encaje` son provisionales. | GDD de los sistemas 15 y 30 | GDD del sistema 15 |
| 6 | **Índice de sistemas:** (a) ~~añadir el sistema 6 como dependencia de 13, 15 y 28~~ **hecho (2026-11-08)**; (b) ~~el sistema 5 como dependiente de 6~~ **retirada** (GDD 5 regla 4, D-12). Solo queda que el índice refleje 2, 4 y 9 como dependientes (ver re-review). | Índice | Cierre de la revisión |
| 7 | **Asignación de sonidos a los tres buses:** voces (`VO_*`, `MEGA_*`) está clara; falta decidir si la lluvia y el drone del edificio van a `vol_efectos` o a `vol_musica`. | GDD del sistema 23 | GDD del sistema 23 |
| 8 | **Rampa anti-chasquido** al cambiar un volumen (p. ej. 0,05 s) y muestra de referencia al mover el deslizador. | GDD del sistema 23 | GDD del sistema 23 |
| 9 | **Más ajustes** que puedan pedir los subtítulos y la accesibilidad: se añaden al catálogo cuando se diseñen. `reducir_movimiento` ya está en el catálogo (decisión 2026-11-09). Ya definidos como opciones en el art bible (§7.5 y §7.6), a la espera de clave, tipo y rango: **escala de texto UI** (100, 125, 150 %), **escala de subtítulos** (100, 125, 150, 200 %), **panel de subtítulos** (85 %, 100 %, sin panel), **alto contraste**, **icono de interacción grande** y **etiquetas de acción**. | GDD de los sistemas 26, 30 y 24 | Esos GDD |
| 10 | **Valores † de F1 a F3 y los iniciales del catálogo** (`db_min` = −40 dB: probar que la voz de Vera sigue audible en el paso 1 en una sala silenciosa; si no, bajar a −50). | Playtest (slice §23.4) | Primer playtest |
| 11 | **Rótulos `UI_…`** de las pantallas de ajustes: dar de alta en la base de contenido y contarlos. El GDD 18 ya anticipa los `UI_…` (ronda 2); falta darlos de alta al diseñar 25, 27 y 30. | GDD del sistema 18 y de los sistemas 25, 27 y 30 | Esos GDD |
| 12 | **Reducir sobresaltos:** qué atenúa exactamente en audio (23) y en luz (28), y con qué límite de destellos. | GDD de los sistemas 23 y 28 | Esos GDD |
| 14 | **Menú de pausa (25), sin GDD:** debe ofrecer `multiplicador_pie` (deslizador de paso 0,25) y `pie_persistente` junto a los demás ajustes de accesibilidad (reglas 1 y 8, UI Requirements); anotar en el GDD de 25 y en el de 30. | GDD de los sistemas 25 y 30 | Esos GDD |
| 13 | **Registro de entidades:** lista completa de valores a registrar en la re-review («Cambios requeridos en otros GDDs»). | Revisión de consistencia | Aprobación del GDD |

**Siguen abiertas tras la ronda de decisiones 1 (lote Feature 1).** Ninguna de las decisiones aprobadas (D-A a D-E) las resuelve; no se aplican y no hay clave nueva hasta que se decidan.

| # | Pregunta | Pide | Efecto |
|---|---|---|---|
| 15 | **`escala_texto_ui`** (PA-3 de 19): la pantalla del ordenador fija 24 px lógicos mínimos y el catálogo no tiene ajuste de tamaño de texto. Es la «escala de texto UI» (100, 125, 150 %) de la OQ 9 y del art bible §7.5; alcance del MVP de accesibilidad (slice §14) | 19, accessibility-specialist, usuario | Si se aprueba: clave `float`/`enum` en la regla 1, restablecer todos pasa de 12 a 13 claves, AC-01 de trece a catorce, lector 19 |
| 16 | **¿Debe `reducir_movimiento` acortar las animaciones de la caja?** (pregunta 5 de 10; por defecto solo `ajar_s` y el cierre, no la animación de apertura de la caja, sustituida por `BOX_C1_OPEN`…`BOX_C4_OPEN` y `BOX_OPEN_MAX` (dueño 10)) | 10, ux-designer, accessibility | Si sí: 10 pasa a ser lector (hoy no lo es) |

## Decisiones tomadas

- **Dureza de 6 con 18 y con 7 (ronda de corrección 4, R6-1):** 18 pasa a aguas arriba como dependencia **blanda** (solo rótulos `UI_…`; la declara 18 en su D18-27 y la repite 6). 7 depende de 6 de forma **blanda** (`multiplicador_pie` y `pie_persistente`; la declara 7) y la fila 7 del índice debe listarlo. Descartado: dejar 18 en «aguas abajo», que contradecía el índice y a 18; motivo: en 18 las filas de la tabla son sus dependientes y 6 es uno de ellos.

- **`reducir_movimiento` entra en el MVP** (usuario, 2026-11-09): clave `bool`, falsa por defecto, lectores 9 (feedback de error) y 4 (cortina). Descartado: dejarla en una Open Question genérica; el art bible ya la da por hecha y sin clave no se pueden diseñar 9 ni 25 contra ella.
- **Pistas no son ajustes** (decisión del P6 a dos niveles): son hechos de partida; el progreso de pistas no se guarda. Descartado: una clave de pistas en el catálogo.
- **Entrada recibe `controles` al oír «ajustes aplicados»** (push por señal, no pull): un solo contrato de arranque para todos los lectores. Descartado: que Entrada lea en su propia inicialización (orden de arranque frágil).
- **`float` con paso se cuantizan como los volúmenes** (F1 generalizada, incluye `campo_vision`). Descartado: declararlo `enum` de 7 valores (peor para el deslizador).
- **`controles` es un tipo propio con validación delegada**; cambio real por igualdad profunda; aviso solo con la clave. Descartado: copiar el bloque en el aviso (tres datos con un bloque dentro).
- **Valor seguro `modo_ventana` = `ventana` antes de Listo**: se mantiene y se justifica (no tocar el monitor sin catálogo fiable).
- **Redondeo de la mitad hacia arriba** en F1. Descartado: dejar la ambigüedad.
- **Tuning Knobs** se añade como tabla única (opcional en `standard`, barato).
- **`multiplicador_pie` y `pie_persistente` son ajustes de 6** (C-W6, opción a; ronda 5): 7 ya los usa en F5 y regla 12 y son accesibilidad pura. `multiplicador_pie` es `float` 1,0–3,0 con paso 0,25 (9 pasos, defecto 1,0†); `pie_persistente` `bool` falso. Entran en «restablecer todos» (12 claves) y en AC-01 (trece claves). Descartado (b): fijar el valor en los Tuning Knobs de 7, porque el jugador que no llega a leer el pie necesita regularlo y 7 no persiste preferencias.
- **Baja automática al descargar la planta** (F-3): regla 7 la recoge como en el bus de 3 (AC-06g). Descartado: exigir la baja manual a cada suscriptor, que deja referencias colgantes si un sistema de planta olvida darse de baja.
- **19 y 21 pasan a consumidores de `reducir_movimiento`** (ronda de propagación 1; piden 19 y 21 regla 23): ya existe la clave, solo se amplía la tabla de consumidores, las interacciones, las dependencias (blandas) y AC-18b. Descartado: crear una clave por consumidor o que 19/21 la lean solo al arrancar; motivo: la lectura en cada disparo da el mismo resultado sin avisos nuevos, y una clave única es lo que el art bible §7.4 define.
- **19 no consume `reducir_sobresaltos`** (19 D19-12) y **`escala_texto_ui` queda como pregunta abierta** (PA-3 de 19, OQ 15). Descartado: añadir `escala_texto_ui` ahora; motivo: es alcance del MVP de accesibilidad, no se decide por propagación.
- **18 figura como dependencia blanda** en Dependencies (solo aloja los `UI_…`), alineado con el índice. Descartado: no listarlo, que dejaba el par incoherente con el índice.
- **Rango de `fov_step_deg` propio** (ronda de corrección 2, W-9, 2026-11-09): el registro lo tenía con el rango 60–90 del FOV; se separa en un rango de paso 1–15† (propuesta, el slice solo fija 5). Descartado: dejar el rango de la clave, porque un validador de datos aceptaría un paso de 60°.
- **Lista de GDDs existentes de Bidireccionalidad ampliada** (W-7/E): añade 19 y 21, que ya leen `reducir_movimiento` y figuran en la tabla.
- **`BOX_Cn_OPEN` sustituida en la pregunta 16** (ronda de corrección 3, R6-2): la animación de apertura de la caja son `BOX_C1_OPEN`…`BOX_C4_OPEN` y su tope `BOX_OPEN_MAX` (dueño 10). Descartado: seguir citando el nombre antiguo (en el registro está `deprecated`).
- **Dureza de dependencias alineada con los dependientes** (ronda de corrección 3, R6-1): 1 → dura de contrato (1 la declara «Dura»; **sustituido en la ronda de corrección 5, D-6.5**); 2, 4, 7, 9, 19, 21 → blanda; 5 → ninguna; 18 → blanda. Descartado: tomar la dureza del proveedor cuando discrepa (regla común del índice).
- **D-6.5 (ronda de corrección 5, A3 de `reviews/dependencias-r7-review.md`):** la dependencia de 6 hacia 1 es **blanda** (6 es el dependiente y la declara así); la fila «Dura (su lado)» de la tabla de 1 aguas arriba daba, leída junto a «ninguna dura» de 1, un ciclo duro 1↔6 que no existe: 1 funciona sin 6 (valores por defecto) y 6 sin 1 solo pierde el bloque `controles`. Además se confirma que 22 (Llamada) no depende de 6 (D22-19). Descartado: dejar «Dura (su lado)» con la aclaración «de contrato» (la lectura literal sigue siendo un ciclo duro). Sin cambios de reglas ni de claves.

## Historial de cambios

- **2026-11-09 (ronda de corrección 2, W-9 de `gdd-cross-review-2026-11-09-r5.md`):** knob `fov_step_deg` con rango propio; Bidireccionalidad al día. Sin cambios de reglas. Estado: Revisado (ronda de corrección 2) — pendiente de re-review.

- **2026-11-09 (ronda de decisiones 1):** sin cambios de reglas: `escala_texto_ui` (PA-3 de 19, pregunta 15) y `reducir_movimiento` sobre la caja (pregunta 5 de 10, pregunta 16) siguen abiertas; el catálogo se mantiene en 11 claves.

- **2026-11-09 (ronda de propagación 1, lote Feature 1):** 19 y 21 añadidos como consumidores de `reducir_movimiento` (catálogo, interacciones, dependencias, AC-18b); `escala_texto_ui` (PA-3 de 19) y el alcance de `reducir_movimiento` en la caja (pregunta 5 de 10) como Open Questions 15 y 16. Sin claves nuevas. Estado: pendiente de re-review.

- **2026-11-09 (ronda 5, aplica C-W6 y F-3 de `gdd-cross-review-2026-11-09-r3.md`):** añadidos `multiplicador_pie` y `pie_persistente` (catálogo, cuantización, restablecer todos = 12 claves, interacciones, dependencias con 7, Tuning Knobs, UI, AC-01 = trece claves, AC-04f, AC-04g, AC-07, OQ 14); regla 7 con baja automática de suscriptores al descargar la planta (AC-06g); 18 añadido a Dependencies; aclarado que `reducir_movimiento` ya está en el catálogo.

- **2026-11-09 (ronda 2, aplica la re-review):** añadida `reducir_movimiento` (catálogo, restablecer todos = 10 claves, interacciones, UI, AC-01 = once claves, AC-04e); F1 generalizada a `float` con paso y redondeo de la mitad hacia arriba (AC-04d, AC-F1); `controles` como tipo propio (AC-04c); dependencias 2, 4 y 9 añadidas y la del 5 retirada; contrato «ajustes aplicados» con Entrada; pistas fuera de ajustes; Tuning Knobs; valor seguro justificado; sección «Decisiones tomadas». Pendiente de re-review.

- **2026-11-09 (lote 2/5/7/9, cambios derivados de la revisión del GDD 2):** regla 1 con `balanceo_camara` (enum `completo`/`reducido`/`ninguno`, inicial `reducido`†) y `campo_vision` (float 60 a 90, paso 5, inicial 70†), lector «2 Jugador»; incorporados a «restablecer todos» (regla 8), a las interacciones y a AC-01 (diez claves). Las pantallas 25 y 30 los ofrecen junto a «reducir sobresaltos». Informe de 5: `save_format_version` no lo usa este GDD (se quita de su `referenced_by` en el registro); ninguna acción. **Cambia reglas: pendiente de re-review.** Estado sin cambios.
- **2026-11-09 (ronda 6, `gdd-cross-review-2026-11-09-r4.md`):** G-2: Dependencies sustituye «Ninguno de los demás sistemas tiene GDD» por la lista real (1, 2, 4, 7, 9, 18) y añade a 24 (pie de texto) como dependiente sin GDD (alternativa descartada: dejar la frase obsoleta; motivo: ya no era cierta).

- **2026-11-09 (ronda de corrección 4, R6-1 de `gdd-cross-review-2026-11-09-r6.md` y `reviews/cross-review-r6-2.md`):** 18 declarado dependencia blanda aguas arriba; 7 → 6 blanda confirmada. Sin cambios de reglas ni de claves. Estado: Revisado (ronda de corrección 4) — pendiente de re-review.
- **2026-11-09 (ronda de corrección 3, R6-1 y R6-2 de `gdd-cross-review-2026-11-09-r6.md`):** pregunta 16 con `BOX_C1_OPEN`…`BOX_C4_OPEN` y `BOX_OPEN_MAX` en lugar de `BOX_Cn_OPEN`; nota del índice de Dependencies con la dureza confirmada. Sin cambios de reglas ni de claves (11). Estado: Revisado (ronda de corrección 3) — pendiente de re-review.
- **2026-11-09 (ronda de corrección 5, propagación de 22 y `dependencias-r7-review.md`):** D-6.5: dependencia de 6 hacia 1 pasa a blanda (sin ciclo duro 1↔6), 22 confirmado sin dependencia de 6, texto obsoleto sobre el índice de 7 retirado. Sin cambios de reglas ni de claves. Estado: Revisado (ronda de corrección 5) — pendiente de re-review.
