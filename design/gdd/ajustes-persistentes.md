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
6. **Escritura inválida.** Un `float` fuera de rango se **ajusta al límite más cercano** (el deslizador nunca rompe nada) y se registra. Una clave no declarada, un valor de tipo incorrecto o un `enum` fuera de su lista se rechazan: en las builds de desarrollo producen un error visible que detiene la ejecución, en la build final se conserva el valor anterior y se registra una línea en el log.
7. **Aviso de cambio.** Cada vez que el valor de un ajuste cambia realmente, este sistema emite un aviso propio con tres datos (clave, valor anterior, valor nuevo); escribir el mismo valor no emite nada. La entrega sigue las mismas reglas que el bus de eventos (3), sin depender de él: orden de suscripción, valor aplicado al instante y aviso encolado si el cambio se provoca desde dentro de una entrega, sin reentrada, y baja de suscriptores efectiva al terminar la entrega en curso. El formato técnico lo fija un ADR.
8. **Restablecer.** Existe «restablecer un ajuste» y «restablecer todos» (para los ajustes de accesibilidad y de audio; el bloque de controles tiene su propio restablecer en Entrada, regla 17). Cada uno aplica el valor inicial y emite el aviso de cambio de los que cambian.

**Fichero, carga y guardado**

9. **Fichero propio.** Los valores del jugador viven en un fichero propio en la carpeta de datos del usuario del sistema, con un número de versión de formato. Ruta y formato los fija un ADR (Open Questions).
10. **Carga al arrancar.** Al arrancar se lee el fichero, se valida cada ajuste por separado y se pasa a «Listo». Una clave ausente toma su valor inicial; una inválida (rango, tipo o `enum`) también, y solo ese ajuste; una clave desconocida se ignora y no se vuelve a escribir. Al terminar se emite un único aviso «ajustes aplicados» (sin datos, no uno por ajuste) y cada sistema relee lo que necesita. Un fichero ausente en el primer arranque no es un error ni se avisa al jugador.
11. **Fichero ilegible o dañado.** Si el fichero existe pero no se puede leer o no tiene estructura válida, el juego **arranca siempre** con todos los valores iniciales, conserva el fichero dañado renombrándolo a una copia (no lo borra ni lo sobrescribe) y registra una línea en el log. No hay mensaje bloqueante al jugador: el juego no se detiene por unos ajustes (pilar *Tensión sin castigo*).
12. **Ajuste de ventana.** `modo_ventana` es el único ajuste que aplica este sistema al motor, al cargar y en cada cambio, sin reiniciar. El resto los aplican quienes los consumen.
13. **Guardado diferido.** Cada cambio marca los ajustes como pendientes y se escribe el fichero cuando pasa `t_guardado` sin nuevos cambios, para que un deslizador no escriba en cada fotograma. Además se escribe lo pendiente al cerrar el juego con normalidad y al abrir el menú de pausa. La escritura es **atómica**: se escribe a un fichero temporal y se sustituye al terminar, de modo que un corte a medias nunca deja el fichero principal dañado.
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

[To be designed]

## Edge Cases

[To be designed]

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
