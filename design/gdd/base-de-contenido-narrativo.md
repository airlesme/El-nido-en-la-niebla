# Base de contenido narrativo

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Información incompleta (datos fuera del código, hechos fijos) · Ambivalencia sin moral binaria (el texto no clasifica a nadie)

## Summary

[To be designed]

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

La base de contenido narrativo es el almacén único de todo lo que el jugador lee u oye: las 26 líneas con identificador del guion (voces, megafonía, notas y cartas), los documentos (formulario, memorando, lista de tareas, libro de visitas), los correos, los textos de las fichas y de los botones, las pistas de tres niveles de cada puzle y los mensajes del sistema. Cada pieza tiene un identificador estable —los del slice, como `VO_G_12A`, `DOC_01` o `CARTA_B`— y vive en ficheros de datos, no en el código ni en las escenas. Los demás sistemas piden contenido por identificador y no saben cuál es el texto.

El jugador no ve este sistema; ve su resultado: cada frase es exactamente la que fija el guion, los subtítulos coinciden con la voz y los hechos observables (fechas, horas, remitentes) son los mismos en todas las pantallas. Eso sostiene el pilar *Información incompleta*: los hechos son fijos y fiables, y solo las intenciones quedan abiertas.

Existe por cuatro razones: (1) el nombre de Vera es provisional (D-04), así que el texto debe poder cambiarse en un solo sitio; (2) los subtítulos completos deben poder comprobarse contra la sección 12 del slice (criterio de aceptación 8); (3) el juego se prepara para traducción desde el principio aunque solo se entregue en español (D-10); y (4) guionistas y QA deben poder trabajar sin tocar código.

## Detailed Design

### Core Rules

**Qué contiene**

1. **Tipos de contenido.** Siete tipos, cada uno con sus campos:
   - **Línea** (voz de Vera, voz del Guardián, megafonía o voz interior): identificador, hablante, escena (1 a 8), uno o más segmentos de texto y una referencia opcional a su audio.
   - **Documento** (memorando, formulario, nota, carta, lista de tareas, libro de visitas, impresión): identificador, tipo, cuerpo (en uno o más fragmentos ordenados), estilo de presentación (`impreso`, `manuscrito_vera`, `manuscrito_guardian`, `cristal_espejo`, `pantalla`, `libro`) y, si procede, el ítem que representa (`I-01` a `I-07`).
   - **Correo**: referencia (1 a 4 o sin numerar), remitente, cuerpo, día, hora de envío y etiquetas de búsqueda.
   - **Ficha de tarea** (T1 a T4): título, descripción y marcas de edición (el nombre tachado y reemplazado por «G» en T4).
   - **Pista**: puzle, nivel (1 a 3) y texto.
   - **Texto de interfaz y mensaje del sistema**: botones («Estoy bien», «La verdad», «Todavía no»), opciones de la llamada, mensajes del teléfono, sellos del tablero, advertencias de la pantalla de inicio, avisos de megafonía del sistema, etc.
   - **Texto de objeto**: lo que dice el juego al inspeccionar un objeto o un relleno (la caja «Pertenencias · Equipo anterior», «Café frío. Lo dejó a las siete», las cajas de las estanterías…).
2. **Cantidad inicial.** El slice contiene las 26 líneas del §12 (8 de Vera, 9 del Guardián, 2 de megafonía, 1 memorando, 2 notas y 4 cartas), 6 correos (4 numerados y 2 de ruido), el formulario del Anexo A.4, las fichas T1 a T4, los textos de pista del Anexo B y los textos de objeto y de interfaz del Anexo A. Las cifras son informativas: el contenido real lo define el catálogo.

**Identificadores**

3. **Identificador estable.** Cada pieza se pide por un identificador que no cambia. Los identificadores que ya existen en el slice se conservan tal cual, con las mismas mayúsculas (`VO_G_12A`, `MEGA_02`, `DOC_01`, `NOTA_01`, `CARTA_CUERPO`…). Los nuevos usan prefijos coherentes con el Anexo D.4: `PISTA_P<n>_N<nivel>` para las pistas, `UI_…` para interfaz y mensajes del sistema, `OBJ_<id del objeto>` para textos de objeto y `MAIL_<ref>` para correos.
4. **No se reutilizan ni se renombran.** Un identificador retirado se marca como inactivo, no se borra ni se reasigna. Renombrar equivale a dar de baja uno y dar de alta otro.
5. **Variantes agrupadas.** Las líneas con variante (`CARTA_A/B/C`, `VO_G_12A/B/C`, `VO_G_13A–D`, `VO_V_12A–D`) forman un **grupo** con un prefijo y una letra. Quien consume (la llamada, el director de escenas, el puzle 6) construye el identificador a partir del prefijo y de la letra que lee del estado del juego (`carta_variante`, `respuesta_llamada`). Este sistema **no lee el estado**: solo entrega el contenido del identificador pedido y declara qué letras completan cada grupo.

**Texto y traducción**

6. **Ningún texto en el código ni en las escenas.** Ningún texto que vea el jugador aparece escrito en scripts o en escenas; todos se piden por identificador. Se exceptúan los mensajes de depuración y del log.
7. **Preparado para traducción.** Cada texto se identifica por su identificador y por un idioma. El slice solo entrega `es`, pero toda lectura pasa por la capa de idioma, de modo que añadir otro idioma no requiere cambiar código (decisión D-10). Si un identificador no existe en el idioma activo, se usa `es`; si no existe en `es`, se aplica el caso límite de «Texto no encontrado».
8. **Parámetros de nombre.** Un texto puede contener dos marcadores, `{vera}` y `{guardian}`, que se sustituyen al leerlo por los valores de una tabla de nombres. Así el nombre provisional de Vera (D-04) y el del Guardián (D-07) se cambian en un solo sitio. No hay más marcadores ni lógica dentro de los textos.
9. **Segmentos.** Una línea se compone de uno o más **segmentos**, cada uno con su texto y, opcionalmente, una pausa previa. `VO_G_07` tiene dos segmentos («Venga, que somos un equipo» y «No. Esa toma no. …»), separados por la pausa que marca el guion. El subtítulo de una línea es la secuencia de sus segmentos; no existe una pista de subtítulos aparte.
10. **Fragmentos de documento.** Un documento puede dividirse en fragmentos ordenados que otros sistemas piden por separado. `DOC_01` tiene tres (F1, F2 y F3 del puzle 2); la concatenación de sus fragmentos, en orden, es el texto del documento.

**Hechos observables y datos derivados**

11. **Un dato, un registro.** Cada dato observable (el día y la hora de un correo, su remitente, la fecha del formulario) se define en un único registro. Los textos que lo muestran lo leen de ahí y no lo reescriben a mano. La impresión de correos (`I-01`) se compone a partir de los registros de los seis correos.
12. **Orden de presentación separado del cronológico.** Cada correo guarda su hora de envío; el orden en que se muestran en pantalla y en la impresión (3, 1, 4, 2, con los dos correos de ruido intercalados) es una lista aparte. La solución del puzle 1 (2, 1, 3, 4) se deduce de las horas, no del orden de presentación.
13. **Etiquetas de búsqueda.** Un correo puede llevar etiquetas (p. ej. «transición»). Cómo se hace la búsqueda lo decide el sistema del ordenador (19); este solo entrega las etiquetas.

**Solo lectura y verificación**

14. **Solo lectura en juego.** El contenido no cambia mientras se juega. Lo que el jugador ha leído o hecho se guarda como hechos en el estado del juego (3), no aquí.
15. **Fuente de verdad.** Los ficheros de datos son lo que lee el juego y es donde se edita el texto. Un verificador en `tools/` compara el contenido con la tabla de líneas de la sección 12 del slice y **falla** si no coinciden. Los cambios de texto de diseño entran como una versión nueva del slice (v0.4…) y se reflejan en los datos.
16. **Qué comprueba el verificador:**
    - Que no hay identificadores duplicados.
    - Que cada identificador usado por otros ficheros de datos existe.
    - Que cada línea que se oye tiene texto (nunca es legal una línea audible sin texto).
    - Que los grupos de variantes están completos (A, B y C; A a D).
    - Que los marcadores de nombre son válidos.
    - Que el conjunto de identificadores y el texto de las líneas del slice §12 coinciden exactamente con los datos (se normalizan solo espacios y saltos de línea).
    - Que cada línea con audio indica un fichero que existe (se avisa, no falla, mientras el audio no esté grabado; ver «Sin audio»).
17. **Sin audio.** Una línea puede existir sin audio mientras se prototipa. Se considera «sin audio»: se muestra solo el subtítulo, durante el tiempo que decida el sistema de subtítulos (26). El verificador la lista como aviso hasta el hito de calidad, momento en el que pasa a error.

**Reglas de contenido (revisión humana, no automáticas)**

18. Las líneas del Guardián nunca explican por qué pasó algo y pueden contradecirse con los documentos (slice §12). Ningún texto confirma las intenciones de nadie. Ningún texto da instrucciones sobre cómo sentirse (slice §17). Ningún texto clasifica a un personaje como bueno o malo. Estas reglas se aplican en la revisión de cada texto nuevo.
19. **Carga.** El catálogo se carga una vez al arrancar. En builds de desarrollo se puede **recargar en caliente**, sin reiniciar, para ver un cambio de texto al momento.

### States and Transitions

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar. Cualquier petición es un error. | Cargando |
| **Cargando** | Lee los ficheros de datos y los valida. | Listo · Error |
| **Listo** | Atiende peticiones de lectura. | Cargando (recarga en caliente, solo desarrollo) |
| **Error** | Falta un fichero o hay datos corruptos o duplicados. | — (el juego no entra en partida) |

El idioma activo es `es` en todo el slice y no cambia durante la partida.

### Interactions with Other Systems

| Sistema | Qué lee de la base de contenido |
|---|---|
| 19 Ordenador, correo e impresora | Los 6 correos con día, hora, etiquetas y orden de presentación; el pie «Ordena por hora de envío» |
| 20 Documentos y bolsillo | Formulario, memorando, notas, cartas, lista de tareas, libro de visitas, con su estilo de presentación |
| 11 Puzle 1 | Textos del panel y de la impresión (a través de 19) |
| 12 Puzle 2 | `DOC_01` por fragmentos (F1, F2, F3), el sello, `NOTA_02` y las pistas |
| 14 Puzle 4 | Fichas T1 a T4, regla del tablero, sellos «ACEPTADA» y «DEVUELTA» y el mensaje «No corresponde» |
| 16 Puzle 6 | Los tres botones, `CARTA_A/B/C` y `CARTA_CUERPO` |
| 17 Sistema de pistas | Textos de pista de los 6 puzles y 3 niveles |
| 21 Director de escenas | `MEGA_*`, `VO_V_*`, los mensajes del teléfono de la escena 1 y los de sistema |
| 22 Llamada telefónica | `VO_G_12A/B/C`, `VO_G_13A–D`, `VO_G_14` y las cuatro opciones de respuesta |
| 23 Director de audio | La referencia de audio y los segmentos de cada línea |
| 26 Subtítulos | El texto y los segmentos de cada línea |
| 27 Pantalla de título | Título, advertencias de contenido (slice §17) y el rótulo «Continuará» |
| 7 Interacción · 8 Control de acceso · 24 Prompt · 25 Pausa | Etiquetas de acción («Abrir», «Girar», «Examinar», «Leer»), textos de objeto, mensajes de puerta cerrada y textos de menú |
| 3 Estado del juego | Nada (este sistema no lee el estado; los consumidores eligen la variante) |

## Edge Cases

**Peticiones**
- **If se pide un identificador que no existe en `es`** («Texto no encontrado»): en desarrollo, error visible que detiene la ejecución; en la build final se muestra «…» en el sitio del texto y se registra una línea en el log. No se muestra nunca el identificador al jugador.
- **If se pide un identificador que no existe en el idioma activo pero sí en `es`**: se usa el texto en `es` y se registra.
- **If se pide un identificador inactivo** (retirado, regla 4): se trata como no encontrado.
- **If se pide una letra de variante que el grupo no declara** (p. ej. `VO_G_12D`): se trata como no encontrado; el grupo declara qué letras completan cada variante.
- **If un consumidor pide un fragmento de documento que no existe**: igual que no encontrado.
- **If se pide contenido antes de que termine la carga («Sin cargar» o «Cargando»)**: en desarrollo, error visible; en la build final se devuelve «…» y se registra.

**Datos**
- **If hay dos registros con el mismo identificador en ficheros distintos**: el verificador falla; si ocurre en el juego, en desarrollo se detiene la ejecución y en la build final gana el primero cargado y se registra.
- **If un texto contiene un marcador desconocido** (p. ej. `{otro}`): el verificador falla; en la build final el marcador se elimina del texto y se registra.
- **If la tabla de nombres no define `{vera}` o `{guardian}`**: el catálogo no pasa a «Listo» y se entra en «Error» (no se puede mostrar un nombre vacío en el formulario).
- **If un grupo de variantes está incompleto** (falta una letra): el verificador falla.
- **If una línea tiene audio pero el fichero indicado no existe**: en desarrollo, aviso; en la build final, la línea se trata como «sin audio» (regla 17) y se registra. Mientras el audio no esté grabado no es error (ver el hito de calidad).
- **If una línea audible no tiene texto**: el verificador falla siempre, también en prototipos.
- **If un texto usa tipografía no ASCII** (comillas «», guiones largos, acentos, ñ): se conserva tal cual; el verificador solo normaliza espacios y saltos de línea al comparar con el slice.
- **If el catálogo tiene un fichero ausente o corrupto al arrancar**: estado «Error»; el juego muestra un mensaje claro y se cierra, igual que el sistema de estado (3).

**Cambios de texto**
- **If se edita un texto en los datos sin cambiar el slice**: el verificador falla para las líneas del §12 hasta que el slice y los datos vuelvan a coincidir (regla 15). Para textos que no están en el §12 (pistas, interfaz, objetos) no hay comparación con el slice.
- **If se recarga en caliente un catálogo (solo desarrollo) y se ha eliminado un identificador que sigue en uso**: el consumidor conserva el último texto mostrado y se registra; el siguiente intento de leerlo es «no encontrado».
- **If dos identificadores distintos tienen el mismo texto** (p. ej. `CARTA_A` y la opción «Estoy bien»): son entradas independientes; no se deduplican ni se enlazan.
- **If un fragmento de documento incluye saltos de línea o formato**: el formato se limita a saltos de línea y a las marcas de edición del tipo de contenido (p. ej. el tachado de T4); no hay otro marcado.

**Presentación**
- **If un texto no cabe en el espacio del consumidor**: el consumidor decide (reducir, partir, desplazar); este sistema no recorta ni abrevia textos.
- **If el pie de una impresión debe mostrar la hora de un correo**: se lee del registro del correo (regla 11); no se escribe a mano en el documento.

## Dependencies

**Aguas arriba (de qué depende):** ninguna. Solo necesita sus ficheros de datos (`assets/data/narrative/`), la capacidad del motor de leerlos al arrancar y el texto del slice (`design/slice/slice-v0.3.md`, §12) para la verificación. No lee el estado del juego, de modo que no depende del sistema 3.

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él pero su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 11 Puzle 1 · 12 Puzle 2 · 14 Puzle 4 · 16 Puzle 6 | Dura (11 **no está en el índice**) | Textos de panel, fragmentos, fichas, botones y pistas |
| 17 Sistema de pistas | Dura | Textos de pista por puzle y nivel |
| 19 Ordenador, correo e impresora | Dura | Correos con hora, etiquetas y orden de presentación |
| 20 Documentos y bolsillo | Dura | Documentos con estilo de presentación |
| 21 Director de escenas | Dura | Líneas de voz y megafonía; mensajes de sistema |
| 22 Llamada telefónica | Dura | Líneas del Guardián y opciones de respuesta |
| 23 Director de audio | Dura | Referencia de audio de cada línea |
| 26 Subtítulos | Dura | Texto y segmentos de cada línea |
| 27 Pantalla de título y cierre | Dura | Título, advertencias, «Continuará» |
| 7 Interacción · 8 Control de acceso · 24 Prompt · 25 Menú de pausa | Blanda (**no están en el índice**) | Etiquetas de acción, textos de objeto, mensajes de puerta cerrada y menús |

**Correcciones pendientes en el índice de sistemas** (se aplican al cerrar este GDD): añadir el sistema 18 como dependencia de 7, 8, 11, 24 y 25.

**Bidireccionalidad.** Ninguno de estos sistemas tiene todavía GDD (salvo los dos ya diseñados, que no dependen de este). Cada uno debe, al redactarse, listar este sistema como dependencia y pedir el contenido solo por identificador.

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
