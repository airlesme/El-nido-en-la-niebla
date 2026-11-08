# Base de contenido narrativo

> **Status**: In Design
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Información incompleta (datos fuera del código, hechos fijos) · Ambivalencia sin moral binaria (el texto no clasifica a nadie)

## Summary

Es el almacén único de todo lo que el jugador lee u oye —las 26 líneas del guion, los documentos, los correos, las fichas, las pistas y los mensajes— identificado por los mismos códigos que usa el slice y guardado en ficheros de datos, no en el código. Garantiza que cada frase es la que fija el guion, que los subtítulos coinciden con la voz y que los hechos observables (fechas, horas, remitentes) son idénticos en todas las pantallas. Existe para poder cambiar un texto en un solo sitio (el nombre de Vera es provisional), verificar los subtítulos contra el slice y dejar el juego listo para traducir.

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
2. **Cantidad inicial.** El slice contiene las 26 líneas del §12 (8 de Vera, 9 del Guardián, 2 de megafonía, 1 memorando, 2 notas y 4 cartas), 6 correos (4 numerados y 2 de ruido), el formulario del Anexo A.4, las fichas T1 a T4, los textos de pista del Anexo B y los textos de objeto y de interfaz del Anexo A. Las cifras de las líneas son las del §12 y las comprueba el verificador (regla 16); el resto de cifras son orientativas.

**Identificadores**

3. **Identificador estable.** Cada pieza se pide por un identificador que no cambia. Los identificadores que ya existen en el slice se conservan tal cual, con las mismas mayúsculas (`VO_G_12A`, `MEGA_02`, `DOC_01`, `NOTA_01`, `CARTA_CUERPO`…). Los nuevos usan prefijos coherentes con el Anexo D.4: `PISTA_P<n>_N<nivel>` para las pistas, `UI_…` para interfaz y mensajes del sistema, `OBJ_<id del objeto>` para textos de objeto y `MAIL_<ref>` para correos.
4. **No se reutilizan ni se renombran.** Un identificador retirado se marca como inactivo, no se borra ni se reasigna. Renombrar equivale a dar de baja uno y dar de alta otro.
5. **Variantes agrupadas.** Las líneas con variante forman un **grupo** con un prefijo y las letras que lo completan, declaradas en los datos: `CARTA_` (A, B, C), `VO_G_12` (A, B, C), `VO_G_13` (A, B, C, D) y `VO_V_12` (A, B, C, D). `CARTA_CUERPO` y `VO_V_12E` son líneas simples, no pertenecen a ningún grupo. Quien consume (la llamada, el director de escenas, el puzle 6) construye el identificador a partir del prefijo y de la letra que lee del estado del juego (`carta_variante`, `respuesta_llamada`). Este sistema **no lee el estado**: solo entrega el contenido del identificador pedido y declara qué letras completan cada grupo.

**Texto y traducción**

6. **Ningún texto en el código ni en las escenas.** Ningún texto que vea el jugador aparece escrito en scripts o en escenas; todos se piden por identificador. Se exceptúan los mensajes de depuración y del log. Un escaneo de scripts y escenas busca literales en las propiedades de texto de la interfaz y en las llamadas que muestran texto; la lista de excepciones se mantiene junto al verificador.
7. **Preparado para traducción.** Cada texto se identifica por su identificador y por un idioma. El slice solo entrega `es`, pero toda lectura pasa por la capa de idioma, de modo que añadir otro idioma no requiere cambiar código (decisión D-10). Si un identificador no existe en el idioma activo, se usa `es`; si no existe en `es`, se aplica el caso límite de «Texto no encontrado».
8. **Parámetros de nombre.** Un texto puede contener dos marcadores, `{vera}` y `{guardian}`, que se sustituyen al leerlo por los valores de una tabla de nombres. Así el nombre provisional de Vera (D-04) y el del Guardián (D-07) se cambian en un solo sitio. No hay más marcadores ni lógica dentro de los textos.
9. **Segmentos.** Una línea se compone de uno o más **segmentos**, cada uno con su texto y, opcionalmente, una pausa previa. `VO_G_07` tiene dos segmentos («Venga, que somos un equipo» y «No. Esa toma no. …»), separados por la pausa que marca el guion. El subtítulo de una línea es la secuencia de sus segmentos; no existe una pista de subtítulos aparte.
10. **Fragmentos de documento.** Un documento puede dividirse en fragmentos ordenados que otros sistemas piden por separado. `DOC_01` tiene tres (F1, F2 y F3 del puzle 2); la concatenación de sus fragmentos, en orden, es el texto del documento.

**Hechos observables y datos derivados**

11. **Un dato, un registro.** Cada dato observable (el día y la hora de un correo, su remitente, la fecha del formulario) se define en un único registro. Los textos que lo muestran lo leen de ahí y no lo reescriben a mano. La impresión de correos (`I-01`) se compone a partir de los registros de los seis correos.
12. **Orden de presentación separado del cronológico.** Cada correo guarda su día y su hora de envío; el orden en que se muestran es una **lista explícita de los seis correos**, única para pantalla e impresión, que fija en los datos la posición de cada correo de ruido (el slice solo fija el orden de los numerados: 3, 1, 4, 2). La solución del puzle 1 (2, 1, 3, 4) es el orden de los numerados por (día, hora), no el orden de presentación.
13. **Etiquetas de búsqueda.** Un correo puede llevar etiquetas. Los cuatro correos numerados llevan «transición»; los dos de ruido no (slice §10.1). Cómo se hace la búsqueda lo decide el sistema del ordenador (19); este solo entrega las etiquetas.

**Solo lectura y verificación**

14. **Solo lectura en juego.** El contenido no cambia entre cargas (la recarga en caliente de la regla 19 solo existe en desarrollo). Lo que el jugador ha leído o hecho se guarda como hechos en el estado del juego (3), no aquí.
15. **Fuente de verdad.** Los ficheros de datos son lo que lee el juego y es donde se edita el texto. Un verificador en `tools/` compara el contenido con la tabla de líneas de la sección 12 del slice y **falla** si no coinciden. Los cambios de texto de diseño entran como una versión nueva del slice (v0.4…) y se reflejan en los datos.
16. **Qué comprueba el verificador:**
    - Que no hay identificadores duplicados.
    - Que cada identificador usado por otros ficheros de datos existe.
    - Que cada línea que se oye tiene texto (nunca es legal una línea audible sin texto).
    - Que los grupos de variantes están completos (A, B y C; A a D).
    - Que los marcadores de nombre son válidos.
    - Que el conjunto de identificadores y el texto de las líneas del slice §12 coinciden con los datos. El texto de comparación es el contenido entre « » de cada celda del §12 (el punto final queda fuera de las comillas y no se exige); los marcadores `{vera}` y `{guardian}` se sustituyen con la tabla de nombres antes de comparar; una celda con `[pausa]` se parte en segmentos y se compara segmento a segmento, y la pausa cuenta como «pausa previa mayor que 0»; los fragmentos de un documento se unen con un espacio; se normalizan espacios y saltos de línea.
    - Que cada línea con audio indica un fichero que existe (se avisa, no falla, mientras el audio no esté grabado; ver «Sin audio»). Toda línea de tipo voz, megafonía o voz interior es audible por definición.
    - El verificador acepta un parámetro de hito (`--hito=calidad`); con él, las líneas sin audio pasan de aviso a error. Termina con código 0 si no hay errores (aunque haya avisos) y con código distinto de 0 si los hay.
17. **Sin audio.** Una línea puede existir sin audio mientras se prototipa. Se considera «sin audio»: se muestra solo el subtítulo, durante el tiempo que decida el sistema de subtítulos (26). El verificador la lista como aviso hasta que se ejecuta con el hito de calidad, momento en el que pasa a error.

**Reglas de contenido (revisión humana, no automáticas)**

18. **Lista de revisión de cada texto nuevo** (la firma quien lo revisa): (a) las líneas del Guardián nunca explican por qué pasó algo y pueden contradecirse con los documentos (slice §12); (b) ningún texto confirma las intenciones de nadie; (c) ningún texto da instrucciones sobre cómo sentirse (slice §17); (d) ningún texto clasifica a un personaje como bueno o malo.
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

*(En modo `lean` no se consulta a `art-director`: lo visual de este sistema se limita a declarar el estilo de cada documento; revisar antes de producción.)*

- **Estilo de presentación por documento.** El sistema declara el estilo de cada documento (regla 1) y el sistema de documentos (20) y el art bible lo resuelven: `impreso` (impresión y formulario), `manuscrito_vera` (cartas, firma del formulario; el art bible la define como «eco»: el libro de visitas la imita), `manuscrito_guardian` (notas `NOTA_01` y `NOTA_02`, lista de tareas), `cristal_espejo` (memorando del puzle 2), `pantalla` (correos en el ordenador, que usa la tipografía del software diegético) y `libro` (libro de visitas).
- **Tipografía.** La tipografía del overlay y del ordenador debe cubrir `¿ ¡ « » ñ á é í ó ú ü …` (art bible §7.2); los textos usan comillas angulares `« »` y la hora en formato de 24 h. Los datos no llevan cursiva ni versalitas.
- **Formato permitido en los textos:** solo saltos de línea y marcas de edición propias del tipo de contenido (el nombre tachado en T4). Nada más: el aspecto lo decide el estilo de presentación, no el texto.
- **Audio:** cada línea de voz referencia su fichero (formato OGG Vorbis o WAV, slice §21); el sonido ambiente incluido dentro de una grabación (p. ej. la puerta que se cierra dentro de `VO_G_07`) forma parte del fichero y no se declara aparte. Los efectos de interfaz no son contenido de este sistema.

## Game Feel

No aplica: el jugador no opera este sistema. Lo único exigible es que pedir un contenido ya cargado no cause tirones perceptibles: todo se lee en la carga inicial (regla 19) y no se accede a disco durante la partida para obtener texto.

## UI Requirements

Ninguno propio. Cada consumidor decide cómo mostrar el texto que recibe (reducir, partir o desplazar; no se recorta aquí). Los textos que ve el jugador y que pertenecen a este sistema son los de interfaz y mensajes (`UI_…`); su pantalla la define quien los usa.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §12 | Tabla de 26 líneas con identificador | Fuente de verdad del diseño de las líneas; el verificador compara contra ella (reglas 15 y 16) |
| `design/slice/slice-v0.3.md` · Anexo B.1 | Correos, horas y orden de impresión | Origen de los registros de correo (reglas 11 y 12) |
| `design/slice/slice-v0.3.md` · Anexo A.4, D.1 | Formulario y lista de ítems `I-01` a `I-07` | Documentos y su relación con los ítems |
| `design/slice/slice-v0.3.md` · D-04, D-07, D-10 | Nombres provisionales y localización | Justifican los marcadores de nombre y las claves de traducción |
| `design/slice/slice-v0.3.md` · §17, §19 (criterio 8) | Reglas de contenido y subtítulos que coinciden con todas las líneas | Reglas 16 y 18 |
| `design/gdd/game-pillars.md` | *Información incompleta*, *Ambivalencia sin moral binaria* | Pilares que este sistema sirve |
| `design/art/art-bible.md` · §7.2 | Tipografía, comillas, hora de 24 h, caracteres que debe cubrir | Condiciona la sección Visual/Audio |
| `design/gdd/estado-y-bus-de-eventos.md` | `carta_variante` y `respuesta_llamada` | Los consumidores eligen la variante leyendo esos hechos (regla 5); este sistema no los lee |
| `design/gdd/entrada-y-controles.md` | Mensaje «Mando desconectado» y otros textos de interfaz | Texto de interfaz que debe existir en el catálogo |
| `design/gdd/systems-index.md` | Fila 18 y dependientes | Debe reflejar la tabla de Dependencies |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/content/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante; **T** = ejecución del verificador de `tools/`, bloqueante en CI. El GDD no define presupuestos de carga ni de memoria y no se inventa ninguno.

**Contenido e identificadores (reglas 1 a 5)**
- **AC-01 (R1, L)**: **GIVEN** el catálogo en «Listo», **WHEN** se pide un ejemplo de cada tipo (línea, documento, correo, ficha T1, pista, `UI_…`, `OBJ_…`), **THEN** cada uno devuelve todos sus campos obligatorios y ninguno vacío.
- **AC-02 (R2, T)**: **GIVEN** los datos del slice, **WHEN** corre el verificador, **THEN** cuenta 26 líneas (8 de Vera, 9 del Guardián, 2 `MEGA_`, 1 `DOC_`, 2 `NOTA_`, 4 `CARTA_`), 6 correos (4 numerados y 2 sin numerar) y las fichas T1 a T4.
- **AC-03 (R3, T)**: **GIVEN** los datos, **WHEN** se listan los identificadores, **THEN** los 26 del §12 existen con las mayúsculas exactas y los nuevos cumplen `PISTA_P<n>_N<1 a 3>`, `UI_…`, `OBJ_…` o `MAIL_<ref>`.
- **AC-04 (R4, L + T)**: **GIVEN** un identificador marcado inactivo, **WHEN** se pide, **THEN** se trata como «no encontrado»; **GIVEN** una referencia de otro fichero a un identificador que no existe ni está inactivo, **THEN** el verificador falla.
- **AC-05 (R5, L + T)**: **GIVEN** los grupos `CARTA_` (A–C), `VO_G_12` (A–C), `VO_G_13` (A–D) y `VO_V_12` (A–D), **WHEN** se quita una letra de cualquiera, **THEN** el verificador falla; **WHEN** se pide `VO_G_12D`, **THEN** devuelve «no encontrado»; `CARTA_CUERPO` y `VO_V_12E` se piden como líneas simples.

**Texto y traducción (reglas 6 a 10)**
- **AC-06 (R6, T + I)**: **GIVEN** los scripts y escenas del juego, **WHEN** corre el escaneo de literales visibles, **THEN** no hay ninguno fuera de depuración, log y la lista de excepciones.
- **AC-07 (R7, L)**: **GIVEN** un idioma de prueba `xx` sin un identificador, **WHEN** se pide, **THEN** devuelve el texto en `es` y se registra; si falta también en `es`, devuelve «no encontrado».
- **AC-08 (R8, L + T)**: **GIVEN** la tabla `{vera}` y `{guardian}`, **WHEN** se lee un texto con marcador, **THEN** se sustituye; con `{otro}` el verificador falla; si la tabla no define `{guardian}`, el catálogo entra en «Error».
- **AC-09 (R9, L)**: **GIVEN** `VO_G_07`, **WHEN** se lee, **THEN** tiene 2 segmentos, el segundo con pausa previa, y el subtítulo es la secuencia de ambos.
- **AC-10 (R10, L)**: **GIVEN** `DOC_01`, **WHEN** se piden F1, F2 y F3, **THEN** existen y su concatenación en orden, unida con espacios, es el texto del documento; F4 devuelve «no encontrado».

**Hechos observables (reglas 11 a 13)**
- **AC-11 (R11, L)**: **GIVEN** el correo 2, **WHEN** se lee, **THEN** tiene lunes 09:14 en un único registro; **WHEN** se cambia esa hora en los datos, **THEN** la impresión `I-01` la refleja sin más ediciones.
- **AC-12 (R12, L)**: **GIVEN** los 6 correos, **WHEN** se pide la lista de presentación, **THEN** es la lista explícita de los datos, con los numerados en el orden 3, 1, 4, 2 y los dos de ruido en las posiciones que fijan los datos; **WHEN** se ordenan los numerados por (día, hora), **THEN** salen 2 (lunes 09:14), 1 (lunes 11:40), 3 (lunes 16:02) y 4 (martes 08:55); **WHEN** se cambia una hora, **THEN** cambia la solución y no la lista de presentación.
- **AC-13 (R13, L)**: **GIVEN** los correos 1 a 4, **WHEN** se piden sus etiquetas, **THEN** incluyen «transición»; los dos de ruido no; el sistema no expone ninguna búsqueda.

**Solo lectura y verificación (reglas 14 a 17)**
- **AC-14 (R14, L)**: **GIVEN** el catálogo en «Listo», **WHEN** se inspecciona su interfaz pública, **THEN** no tiene operaciones de escritura ni lee el estado del juego.
- **AC-15 (R15, T)**: **GIVEN** los datos del slice sin tocar, **WHEN** corre el verificador, **THEN** termina con código 0; **WHEN** se cambia una letra de cualquiera de las 26 líneas, **THEN** termina con código distinto de 0 y nombra el identificador; **WHEN** solo cambian espacios o saltos de línea, **THEN** sigue en 0.
- **AC-16 (R15, T)**: **GIVEN** `VO_G_07` (celda con `[pausa]`), `DOC_01` (fragmentos) y un texto con `{vera}`, **WHEN** corre el verificador, **THEN** los compara con el §12 según la regla 16 (segmento a segmento, fragmentos unidos con espacio, marcadores sustituidos) y los da por coincidentes.
- **AC-17 (R16, T)**: **GIVEN** datos con un identificador duplicado, una referencia inexistente o una línea audible sin texto, **WHEN** corre el verificador, **THEN** falla en cada caso, también en prototipos; un fichero de audio ausente da aviso con código 0.
- **AC-18 (R17, T)**: **GIVEN** líneas sin audio, **WHEN** corre el verificador, **THEN** las lista como aviso con código 0; **WHEN** se ejecuta con `--hito=calidad`, **THEN** pasan a error.
- **AC-19 (R17, I)**: **GIVEN** una línea sin audio, **WHEN** se reproduce en el juego, **THEN** se muestra su subtítulo y no se produce error.

**Reglas de contenido y carga (reglas 18 y 19)**
- **AC-20 (R18, I)**: **GIVEN** cada texto nuevo, **WHEN** se revisa, **THEN** existe una lista de revisión firmada con los cuatro puntos de la regla 18.
- **AC-21 (R19, L + I)**: **GIVEN** el arranque, **WHEN** se hacen varias peticiones de contenido, **THEN** los ficheros se leen una sola vez; **GIVEN** una build de desarrollo, **WHEN** se edita un texto y se recarga, **THEN** el cambio se ve sin reiniciar; **GIVEN** el export de la demo, **THEN** la recarga en caliente no existe.

**Casos límite**
- **AC-E1 (L + I)**: **GIVEN** el catálogo en «Sin cargar» o «Cargando», **WHEN** se pide contenido, **THEN** en desarrollo hay un error visible y en la build final se devuelve «…» y se registra; **GIVEN** un fichero ausente o corrupto, **THEN** el estado es «Error» y no se entra en partida.
- **AC-E2 (L)**: **GIVEN** textos con «», —, á y ñ, **WHEN** se leen, **THEN** se conservan carácter a carácter; `CARTA_A` y la opción «Estoy bien» son entradas independientes.
- **AC-E3 (L)**: **GIVEN** una recarga en caliente que elimina un identificador en uso, **WHEN** el consumidor lo vuelve a pedir, **THEN** conserva el último texto y se registra; el siguiente intento da «no encontrado».
- **AC-E4 (L)**: **GIVEN** una línea con audio cuyo fichero no existe, **WHEN** se reproduce en la build final, **THEN** se trata como «sin audio» y se registra.
- **AC-E5 (L)**: **GIVEN** dos registros con el mismo identificador en ficheros distintos, **WHEN** se carga el catálogo, **THEN** el verificador falla; en el juego, en desarrollo se detiene la ejecución y en la build final gana el primero cargado y se registra.

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Ruta y formato de los ficheros de datos** (`assets/data/narrative/`), cómo se invoca el verificador y sus códigos de salida (propuesta: 0 sin errores, distinto de 0 con errores, aviso con código 0). | `/architecture-decision` | Fase de arquitectura |
| 2 | **Dónde se parte `DOC_01` en F1, F2 y F3** y cómo se escribe el punto final (en el §12 está fuera de las comillas, en F3 del puzle 2 lleva punto). | Autor / GDD del sistema 12 | GDD del sistema 12 |
| 3 | **Duración de la pausa de `VO_G_07`** entre sus dos segmentos. | Audio / GDD del sistema 23 | GDD del sistema 23 |
| 4 | **Tiempo de un subtítulo sin audio** (prototipos): lo decide el sistema 26. | GDD del sistema 26 | GDD del sistema 26 |
| 5 | **Qué cuenta como literal visible en el escaneo** de scripts y escenas (regla 6) y dónde vive la lista de excepciones. | `/architecture-decision` | Fase de arquitectura |
| 6 | **Dónde se guardan los identificadores retirados** (regla 4) y cómo se marca «inactivo». | `/architecture-decision` | Fase de arquitectura |
| 7 | **Forma de la tabla de nombres** (`{vera}`, `{guardian}`): ¿un fichero propio o parte de los datos? | `/architecture-decision` | Fase de arquitectura |
| 8 | **D-04 (nombre de Vera) y D-07 (nombre del Guardián):** siguen abiertas en el slice. El sistema las tolera, pero la firma «G.» de los correos y el nombre del formulario dependen de ellas. | Autor | Antes de la grabación de voces |
| 9 | **Índice de sistemas:** añadir el sistema 18 como dependencia de 7, 8, 11, 24 y 25. | Este GDD (cierre) | Ahora |
