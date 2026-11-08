# Ajustes persistentes

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Tensión sin castigo (reducir sobresaltos, remapeo, accesibilidad) · Autonomía como progresión (el jugador ajusta su experiencia)

## Summary

[To be designed]

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `1 Entrada y controles`

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
   | `modo_ventana` | enum `pantalla_completa`, `ventana` · `pantalla_completa` | Modo de la ventana del juego | este sistema (regla 12) |
   | `controles` | bloque opaco | Asignaciones y ajustes de manejo de Entrada y controles (reglas 15 a 19 de ese GDD) | 1 Entrada |

   Si los sistemas 26 (subtítulos) o 30 (accesibilidad) necesitan más ajustes (tamaño o fondo de subtítulo, otras ayudas), se añaden a esta tabla cuando se diseñen esos sistemas; este GDD no los inventa.
2. **El bloque de controles es opaco.** Este sistema guarda y devuelve el bloque `controles` tal como Entrada lo exporta, sin interpretar su contenido. Entrada valida las asignaciones y los valores al importarlo (sus casos límite). Aquí solo se garantiza que el bloque se conserva, que si falta se usan los valores por defecto de Entrada y que un bloque ilegible no impide arrancar.
3. **Los ajustes no son hechos del juego ni parte de la partida.** No se incluyen en la instantánea del estado (regla 14 del GDD del 3) ni en el guardado (5). Empezar una partida nueva, cargar otra o borrarlas no toca los ajustes, y cambiar un ajuste no toca la partida.

**Lectura, escritura y validación**

4. **Valor siempre disponible y válido.** Cualquier sistema puede leer un ajuste en cualquier momento y obtiene siempre un valor válido: el del jugador, o el inicial si no se ha tocado, o falta, o es inválido en el fichero.
5. **Escritura.** Escribe un ajuste el sistema cuya pantalla lo ofrece al jugador: menú de pausa (25), accesibilidad (30) o título (27); y Entrada escribe el bloque `controles`. Una escritura válida se aplica en el instante en que se hace: una lectura inmediatamente posterior devuelve el valor nuevo.
6. **Escritura inválida.** Un `float` fuera de rango se **ajusta al límite más cercano** (el deslizador nunca rompe nada) y se registra; los volúmenes se cuantizan además en pasos (F1). Un `float` NaN, una clave no declarada, un valor de tipo incorrecto o un `enum` fuera de su lista se rechazan: en las builds de desarrollo producen un error visible que detiene la ejecución, en la build final se conserva el valor anterior y se registra una línea en el log.
7. **Aviso de cambio.** Cada vez que el valor de un ajuste cambia realmente, este sistema emite un aviso propio con tres datos (clave, valor anterior, valor nuevo); escribir el mismo valor no emite nada. La entrega sigue las mismas reglas que el bus de eventos (3), sin depender de él: orden de suscripción, valor aplicado al instante y aviso encolado si el cambio se provoca desde dentro de una entrega, sin reentrada, y baja de suscriptores efectiva al terminar la entrega en curso. El formato técnico lo fija un ADR.
8. **Restablecer.** Existe «restablecer un ajuste» y «restablecer todos» (para los ajustes de accesibilidad y de audio; el bloque de controles tiene su propio restablecer en Entrada, regla 17). Cada uno aplica el valor inicial y emite el aviso de cambio de los que cambian.

**Fichero, carga y guardado**

9. **Fichero propio.** Los valores del jugador viven en un fichero propio en la carpeta de datos del usuario del sistema, con un número de versión de formato. Ruta y formato los fija un ADR (Open Questions).
10. **Carga al arrancar.** Al arrancar se lee el fichero, se valida cada ajuste por separado y se pasa a «Listo». Una clave ausente toma su valor inicial; una inválida (rango, tipo o `enum`) también, y solo ese ajuste; una clave desconocida se ignora y no se vuelve a escribir. Al terminar se emite un único aviso «ajustes aplicados» (sin datos, no uno por ajuste) y cada sistema relee lo que necesita. Un fichero ausente en el primer arranque no es un error ni se avisa al jugador.
11. **Fichero ilegible o dañado.** Si el fichero existe pero no se puede leer o no tiene estructura válida, el juego **arranca siempre** con todos los valores iniciales, conserva el fichero dañado renombrándolo a una copia (no lo borra ni lo sobrescribe) y registra una línea en el log. No hay mensaje bloqueante al jugador: el juego no se detiene por unos ajustes (pilar *Tensión sin castigo*).
12. **Ajuste de ventana.** `modo_ventana` es el único ajuste que aplica este sistema al motor, al cargar y en cada cambio, sin reiniciar. El resto los aplican quienes los consumen.
13. **Guardado diferido.** Cada cambio marca los ajustes como pendientes y se escribe el fichero cuando pasa `t_guardado` sin nuevos cambios o `t_guardado_max` desde el primero (F3), para que un deslizador no escriba en cada fotograma. Además se escribe lo pendiente al cerrar el juego con normalidad y al abrir el menú de pausa. La escritura es **atómica**: se escribe a un fichero temporal y se sustituye al terminar, de modo que un corte a medias nunca deja el fichero principal dañado.
14. **Datos, no código.** Los valores iniciales, los rangos y `t_guardado` viven en `assets/data/settings/defaults.json`; cambiar un valor inicial no requiere tocar código.

### States and Transitions

El sistema tiene tres estados; no existe un estado de error porque un fichero dañado nunca lo bloquea (regla 11).

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar. Cualquier lectura o escritura es un error. | Cargando |
| **Cargando** | Lee y valida el fichero (reglas 10 y 11) y aplica el modo de ventana. No se entregan avisos de cambio. | Listo, tras emitir «ajustes aplicados» |
| **Listo** | Lecturas, escrituras, avisos de cambio y guardado diferido permitidos. Pendiente de escritura = hay cambios sin volcar a disco. | — (hasta cerrar el juego) |

### Interactions with Other Systems

La tabla del catálogo (regla 1) indica quién lee cada ajuste. Otras interacciones:

| Sistema | Qué recibe de Ajustes | Qué entrega a Ajustes |
|---|---|---|
| 1 Entrada y controles | Al arrancar, el bloque `controles` guardado (o nada); el aviso «ajustes aplicados» | Su bloque exportado cada vez que el jugador cambia una asignación o un ajuste de manejo |
| 23 Director de audio | Volúmenes, `reducir_sobresaltos`, avisos de cambio | — |
| 26 Subtítulos | `subtitulos_activos`, avisos de cambio | — |
| 28 Atmósfera reactiva | `reducir_sobresaltos` | — |
| 13 Puzle 3 · 15 Puzle 5 | `asistencia_encaje`, `asistencia_rotacion` (vía el marco de puzles 9) | — |
| 25 Menú de pausa · 30 Accesibilidad · 27 Pantalla de título | Valor actual de los ajustes que muestran | Escrituras del jugador y peticiones de restablecer |
| 5 Guardado y carga | Nada: los ajustes quedan fuera de la partida (regla 3). El índice lo lista como dependiente; ver Open Questions | — |
| 3 Estado y bus de eventos | Nada | Nada |

## Formulas

Propuestas por `systems-designer`. † = valor propuesto, **a validar en playtest**. Los valores que se leen de `assets/data/settings/defaults.json` (regla 14) se marcan «data file». El sistema no define presupuesto de rendimiento y no se inventa uno.

### F1 · Pasos del deslizador de volumen

La fórmula de pasos del deslizador se define como:

`n = round(v_ui × N_pasos);   v = n / N_pasos`

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

**Casos límite:** un valor fuera de rango se ajusta antes de cuantizar (1,7 → 1; −0,3 → 0; ±infinito → 1 o 0) y se registra. **NaN:** un ajuste no lo arregla, así que se comprueba antes y se trata como escritura inválida (regla 6): en ejecución se conserva el valor anterior y se registra; al cargar el fichero se usa el valor inicial. NaN nunca llega a la curva. Si `N_pasos` < 1 o `db_min` ≥ 0 al cargar los datos, se usan los valores por defecto y se registra (no hay división por cero).

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

**Output Range:** booleano. Con cambios continuos hay como máximo una escritura cada `t_guardado_max` (0,2 escrituras/s con los valores propuestos); sin cambios continuos, una por ráfaga. La pérdida máxima ante un cierre forzado es `t_guardado_max` (5 s de cambios). Restricción de datos: `t_guardado_max ≥ 2 × t_guardado`; si no se cumple al cargar, se usan los valores por defecto y se registra.
**Reglas de la escritura:** al marcar pendiente con `pendiente` falso, `t_prim = t`; cada cambio real hace `t_ult = t`. La escritura toma una instantánea: un cambio que llegue durante la escritura vuelve a marcar pendiente y no se pierde; al terminar con éxito, `pendiente` pasa a falso solo si no hubo cambios posteriores a la instantánea. Un fallo de escritura mantiene `pendiente`, registra una línea y reintenta tras `t_guardado_max`; nunca bloquea ni avisa al jugador.
**Example:** un arrastre de 12 s con un cambio real cada 0,05 s escribe en t = 5 y t = 10 (tope) y, al soltar en t = 12, en t = 12,5 (silencio de 0,5 s): 3 escrituras en vez de unas 240. Un cambio suelto en t = 3 se escribe en t = 3,5. Justificación de 0,5 s: más largo que la pausa típica entre pulsaciones de mando (~0,15–0,3 s) y más corto que lo que tarda un jugador en cerrar el juego tras ajustar; 5 s limita las escrituras a disco y la pérdida ante un cierre forzado.

## Edge Cases

**Fichero y arranque**
- **If el fichero no existe (primer arranque)**: todos los ajustes toman su valor inicial; no es un error y no se registra como tal. El fichero se crea con el primer cambio.
- **If el fichero existe pero es ilegible o no tiene estructura válida**: regla 11 (valores iniciales, copia del dañado, línea en el log). Se conserva una sola copia: si ya había una de un fallo anterior, la nueva la sustituye.
- **If el fichero declara una versión de formato mayor que la conocida** (p. ej. se abrió con una build más nueva): se trata como ilegible (copia + valores iniciales), porque no se puede garantizar el significado de sus claves.
- **If el fichero declara una versión menor**: se leen las claves reconocidas y las que faltan toman su valor inicial. En el slice no hay migraciones.
- **If una clave del fichero es inválida** (rango, tipo, `enum` o NaN): solo ese ajuste vuelve a su valor inicial y se registra; el resto se conserva (regla 10).
- **If el bloque `controles` del fichero es ilegible**: Entrada usa sus asignaciones por defecto (sus casos límite); el resto de los ajustes no se ve afectado.
- **If queda un fichero temporal huérfano de una escritura interrumpida**: se ignora al leer y se elimina; el fichero principal sigue siendo el válido (regla 13, escritura atómica).
- **If se lee o escribe un ajuste antes de «Listo»**: en desarrollo, error visible que detiene la ejecución; en la build final, la escritura se descarta y se registra, y la lectura devuelve el valor inicial del catálogo si se pudo leer, o si no uno seguro (volumen 1,0, subtítulos verdadero, resto falso) y se registra. El orden de arranque garantiza en la práctica que no ocurre; lo fija el ADR.
- **If `defaults.json` falta o está corrupto**: el juego no entra en partida y muestra un mensaje de error claro, igual que los otros sistemas de datos (3 y 18); sin catálogo no hay valores iniciales fiables.

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
- **If el sistema operativo rechaza el cambio de `modo_ventana`**: el ajuste vuelve al valor realmente aplicado, se emite el aviso de cambio correspondiente y se registra; no se bloquea.
- **If el jugador cambia el modo de ventana fuera del juego** (p. ej. `Alt+Intro` del sistema operativo): el ajuste se sincroniza con el valor real observado y se guarda por F3.
- **If el modo guardado es `pantalla_completa` y el monitor ya no está**: el motor decide el monitor; el ajuste conserva su valor y se aplica en el que haya.

## Dependencies

**Aguas arriba (de qué depende):** el sistema 1 (Entrada y controles), **dura en cuanto a contrato**: el formato del bloque `controles` lo define Entrada (reglas 18 y 19 de su GDD) y este sistema lo guarda sin interpretarlo; en ejecución funciona sin él, simplemente sin bloque que guardar. Necesita además su fichero de valores iniciales (`assets/data/settings/defaults.json`, definido por este GDD) y la capacidad del motor de leer y escribir ficheros en la carpeta de datos del usuario. No depende del sistema 3: el aviso de cambio es propio (regla 7).

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él pero su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 23 Director de audio | Dura | Lee `vol_voces`, `vol_efectos`, `vol_musica`, `reducir_sobresaltos`; se suscribe a los avisos de cambio |
| 26 Subtítulos | Dura | Lee `subtitulos_activos`; se suscribe a los avisos de cambio |
| 25 Menú de pausa | Dura | Muestra y escribe ajustes; usa «restablecer» |
| 30 Opciones de accesibilidad | Dura | Muestra y escribe ajustes de accesibilidad; usa «restablecer» |
| 27 Pantalla de título y cierre | Blanda | Muestra y escribe ajustes desde el título |
| 28 Atmósfera reactiva | Blanda | Lee `reducir_sobresaltos` (parpadeo del pasillo y apagón) |
| 13 Puzle 3 · 15 Puzle 5 | Blanda (vía marco 9) | Leen `asistencia_encaje` y `asistencia_rotacion` |
| 1 Entrada y controles | Dura (su lado) | Entrega y recupera el bloque `controles` |
| 5 Guardado y carga | **A confirmar** | El índice lo lista como dependiente; no hay ningún ajuste que lo gobierne (autoguardado fijo, slice D.3). Ver Open Questions |

**Correcciones pendientes en el índice de sistemas:** (a) los puzles 13 y 15 y la atmósfera 28 leen ajustes y no listan al sistema 6 como dependencia; (b) la dependencia del sistema 5 respecto de este se confirma o se retira. Se aplican al cerrar este GDD.

**Bidireccionalidad.** El par con el sistema 1 está cerrado: Entrada ya lista a Ajustes como dependiente (su tabla de Dependencies y su regla 19). El GDD del 3 ya declara que los ajustes quedan fuera del estado (regla 14), y su tabla de interacciones dice «Nada». Ninguno de los demás sistemas tiene GDD: cada uno debe, al redactarse, listar a Ajustes como dependencia y usar las claves del catálogo de la regla 1.

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
