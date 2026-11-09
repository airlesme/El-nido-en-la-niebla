# Base de contenido narrativo

> **Status**: Revisado (ronda de corrección 8) — pendiente de re-review (ronda de corrección 8: claves provisionales de los puzles 4 y 6 (`UI_P4_*`, `UI_P6_BOTON_A/B/C`), fila P3 N3 y preguntas abiertas 16 a 18, D18-29 a D18-31; ronda de corrección 5: claves pedidas por 22 (`UI_LLAMADA_OPCION_A–D`, `SUB_BREATH_BROKEN` provisional) y retirada de «22 sin GDD», D18-28; ronda de corrección 3, R6-1/R6-2 de `gdd-cross-review-2026-11-09-r6.md`: nombre `repasar_bolsillo` y dureza de dependencias) (ronda de corrección 2: W-7, D18-25; ronda 6 aplicó A-3 y A-4 de `gdd-cross-review-2026-11-09-r4.md`; la ronda de propagación 1 aplicó los cambios requeridos por 8, 19, 20 y 21; la ronda de decisiones 1 aplica D18-20 a D18-24: `MEGA_03` al §12, `UI_BOLSILLO_AYUDA`, `I-05`/`I-06a` y B.1 del slice)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Información incompleta (datos fuera del código, hechos fijos) · Ambivalencia sin moral binaria (el texto no clasifica a nadie)

## Summary

Es el almacén único de todo lo que el jugador lee u oye —las 28 líneas del guion, los documentos, los correos, las fichas, las pistas y los mensajes— identificado por los mismos códigos que usa el slice y guardado en ficheros de datos, no en el código. Garantiza que cada frase es la que fija el guion, que los subtítulos coinciden con la voz y que los hechos observables (fechas, horas, remitentes) son idénticos en todas las pantallas. Existe para poder cambiar un nombre en un solo sitio (el de Vera es provisional) y editar los textos sin tocar código, verificar los subtítulos contra el slice y dejar el juego listo para traducir. Las 28 entradas del §12 se editan primero en el slice y luego en los datos; el resto, solo en datos; un verificador comprueba que coinciden.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

La base de contenido narrativo es el almacén único de todo lo que el jugador lee u oye: las 28 líneas con identificador del guion (voces, megafonía, notas y cartas), los documentos (formulario, memorando, lista de tareas, libro de visitas), los correos, los textos de las fichas y de los botones, las pistas con texto de cada puzle (hasta tres niveles: P1 1, P2 1, P3 0, P4 2, P5 2 y P6 2 niveles con texto, 8 en total; P3 no tiene texto; no todas las pistas son texto, ver regla 20) y los mensajes del sistema. Cada pieza tiene un identificador estable —los del slice, como `VO_G_12A`, `DOC_01` o `CARTA_B`— y vive en ficheros de datos, no en el código ni en las escenas. Los demás sistemas piden contenido por identificador y no saben cuál es el texto.

El jugador no ve este sistema; ve su resultado: cada frase es exactamente la que fija el guion, los subtítulos coinciden con la voz y los hechos observables (fechas, horas, remitentes) son los mismos en todas las pantallas. Eso sostiene el pilar *Información incompleta*: los hechos son fijos y fiables, y solo las intenciones quedan abiertas.

Existe por cuatro razones: (1) el nombre de Vera es provisional (D-04), así que el texto debe poder cambiarse en un solo sitio; (2) los subtítulos completos deben poder comprobarse contra la sección 12 del slice (criterio de aceptación 8); (3) el juego se prepara para traducción desde el principio aunque solo se entregue en español (D-10); y (4) guionistas y QA deben poder trabajar sin tocar código.

## Detailed Design

### Core Rules

**Qué contiene**

1. **Tipos de contenido.** Ocho tipos, cada uno con sus campos:
   - **Línea** (voz de Vera, voz del Guardián, megafonía o voz interior): identificador, hablante, escena (1 a 8), uno o más segmentos de texto y una referencia opcional a su audio.
   - **Documento** (memorando, formulario, nota, carta, lista de tareas, libro de visitas, impresión): identificador, tipo, cuerpo (en uno o más fragmentos ordenados), estilo de presentación (`impreso`, `manuscrito_vera`, `manuscrito_guardian`, `cristal_espejo`, `pantalla`, `libro`) y, si procede, el ítem que representa (`I-01` a `I-07`).
   - **Correo**: referencia (1 a 4 o sin numerar), remitente, asunto, cuerpo, día, hora de envío y etiquetas de búsqueda.
   - **Ficha de tarea** (T1 a T4): título, descripción y marcas de edición (el nombre tachado y reemplazado por «G» en T4).
   - **Pista**: puzle, nivel (1 a 3) y texto. Solo existen como entrada las pistas cuyo efecto muestra texto (regla 20); las demás son efectos de los datos del puzle (9) y no llevan clave.
   - **Texto de interfaz y mensaje del sistema**: botones («Estoy bien», «La verdad», «Todavía no»), opciones de la llamada, mensajes del teléfono, sellos del tablero, advertencias de la pantalla de inicio, avisos de megafonía del sistema, etc.
   - **Sonido no verbal con subtítulo**: un evento sonoro sin palabras que el jugador necesita poder leer (p. ej. el llanto contenido de la llamada, escena 7). Identificador `SUB_…` (uno por evento), texto breve entre corchetes y referencia opcional a su audio (el sonido lo reproduce 23; este sistema solo guarda el texto). Ver regla 22.
   - **Texto de objeto**: lo que dice el juego al inspeccionar un objeto o un relleno (la caja «Pertenencias · Equipo anterior», «Café frío. Lo dejó a las siete», las cajas de las estanterías…).
2. **Cantidad inicial.** El slice contiene las 28 líneas del §12 (8 de Vera, 10 del Guardián —incluidas `VO_G_14_RET` y `VO_G_14_ASG`—, 3 de megafonía —`MEGA_01` a `MEGA_03`; `MEGA_03` entra con el slice v0.4—, 1 memorando, 2 notas y 4 cartas), 6 correos (4 numerados y 2 de ruido), el formulario del Anexo A.4, las fichas T1 a T4, los textos de las 8 pistas con texto del Anexo B (regla 20) y los textos de objeto y de interfaz del Anexo A. Las cifras de las líneas son las del §12 y las comprueba el verificador (regla 16); el resto de cifras son orientativas. **Las 28 entradas del §12 son de dos tipos:** 21 líneas audibles (8 de Vera, 10 del Guardián y 3 de megafonía) y 7 entradas de **documento** con identificador de línea (`DOC_01`, `NOTA_01`, `NOTA_02` y `CARTA_A`, `CARTA_B`, `CARTA_C` y `CARTA_CUERPO`), que no se oyen y se tratan como documentos (regla 1). Además hay textos de interfaz que otros GDD ya anticipan (p. ej. «Mando desconectado», la pantalla de reasignación y los ajustes de manejo del GDD de Entrada y controles) y que necesitarán entradas `UI_…`; son orientativos.

**Identificadores**

3. **Identificador estable.** Cada pieza se pide por un identificador que no cambia. Los identificadores que ya existen en el slice se conservan tal cual, con las mismas mayúsculas (`VO_G_12A`, `MEGA_02`, `DOC_01`, `NOTA_01`, `CARTA_CUERPO`…). Los nuevos usan prefijos coherentes con el Anexo D.4: `PISTA_P<n>_N<nivel>` para las pistas **con texto** (conjunto cerrado de 8, regla 20; P1 a P5 tienen tres niveles y **P6 dos**, decisión del usuario 2026-11-09, Anexo B.6), `UI_…` para interfaz y mensajes del sistema, `SUB_<EVENTO>` (en mayúsculas) para los subtítulos de sonido no verbal (regla 22), `OBJ_<id del objeto>` para textos de objeto y, para correos, `MAIL_1` a `MAIL_4` (los numerados, con su referencia) y `MAIL_X1` y `MAIL_X2` (los dos sin numerar, en el orden del slice: X1 = recordatorio de extensiones, lunes 10:30; X2 = aviso del aire acondicionado, martes 14:00).
4. **No se reutilizan ni se renombran.** Un identificador retirado se marca como inactivo, no se borra ni se reasigna. Renombrar equivale a dar de baja uno y dar de alta otro.
5. **Variantes agrupadas.** Las líneas con variante forman un **grupo** con un prefijo y las letras que lo completan, declaradas en los datos: `CARTA_` (A, B, C), `VO_G_12` (A, B, C), `VO_G_13` (A, B, C, D), `VO_G_14` (`RET`, `ASG`; sufijos de más de una letra, declarados en los datos igual que las letras) y `VO_V_12` (A, B, C, D). `CARTA_CUERPO` y `VO_V_12E` son líneas simples, no pertenecen a ningún grupo. Quien consume (la llamada, el director de escenas, el puzle 6) construye el identificador a partir del prefijo y de la letra que lee del estado del juego (`carta_variante`, `respuesta_llamada`). Este sistema **no lee el estado**: solo entrega el contenido del identificador pedido y declara qué letras completan cada grupo.

   **Variante por la decisión de T4 (D-B1, 2026-11-09; propuesta — pendiente de narrative-director/usuario).** El hecho `t4_decision` (`returned`/`assigned`, GDD 3) cambia **una** línea: la última del Guardián en la llamada (escena 7, la más cercana al puzle 4 que lee el hecho). Grupo `VO_G_14` con sufijos `_RET` y `_ASG` (declarados en los datos como las letras de otros grupos). Desde la ronda 5 **son entradas del §12** del slice (entonces 27 entradas, ahora 28 con `MEGA_03`; `fuente: slice_§12`, el verificador las compara como las demás, regla 16); `_ASG` sigue siendo un texto propuesto pendiente de narrative-director/usuario:

   | Clave | Cuándo | Texto | Estado |
   |---|---|---|---|
   | `VO_G_14_RET` | `t4_decision` = `returned` | «Sigo aquí.» (es la `VO_G_14` actual del slice, sin cambios) | existente |
   | `VO_G_14_ASG` | `t4_decision` = `assigned` | «Sigo aquí. La carta a Dirección ya va firmada.» | **propuesta — pendiente de narrative-director/usuario** |

   Criterio de la propuesta: una frase mínima que no confirma la intención del Guardián (anti-pilar; D-B2) ni juzga la elección. Si el slice la rechaza, ambas claves se sustituyen por `VO_G_14` simple y el hecho queda sin lector narrativo (sigue guardándose). Quien consume (22) construye el identificador con el sufijo que lee de `t4_decision`.

**Texto y traducción**

6. **Ningún texto en el código ni en las escenas.** Ningún texto que vea el jugador aparece escrito en scripts o en escenas; todos se piden por identificador. Se exceptúan los mensajes de depuración y del log. Un escaneo de scripts y escenas busca literales en las propiedades de texto de la interfaz y en las llamadas que muestran texto; la lista de excepciones se mantiene junto al verificador y contiene, como únicas excepciones de texto de jugador, los dos textos de emergencia de la regla 21. **Definición provisional de «literal visible»** (a confirmar en el ADR, Open Question 5): cualquier cadena literal no vacía asignada a la propiedad de texto de un nodo de interfaz (`Label`, `RichTextLabel`, `Button`, etc.) en un script o una escena, o pasada a una función que muestre texto; las cadenas vacías, los números y los literales de depuración o de log no cuentan.
7. **Preparado para traducción.** Cada texto se identifica por su identificador y por un idioma. El slice solo entrega `es`, pero toda lectura pasa por la capa de idioma, de modo que añadir otro idioma no requiere cambiar código (decisión D-10). Si un identificador no existe en el idioma activo, se usa `es`; si no existe en `es`, se aplica el caso límite de «Texto no encontrado».
8. **Parámetros de nombre.** Un texto puede contener cuatro marcadores, `{vera}`, `{guardian}`, `{vera_inicial}` y `{guardian_inicial}`, que se sustituyen al leerlo por los valores de una tabla de nombres (cada personaje tiene nombre e inicial). Así el nombre provisional de Vera (D-04) y el del Guardián (D-07) se cambian en un solo sitio, también donde el texto usa la inicial: `VO_V_12E` («La `{vera_inicial}` no me convence») y las firmas «— `{guardian_inicial}`.» de los correos 1, 2 y 3. **La lista es exhaustiva por derivación:** cualquier aparición del nombre o de la inicial en un texto de los datos usa marcador, incluidos la ficha T4 (nombre tachado y reemplazado por la inicial del Guardián), T1 («Ya la tiene asignada `{vera}`»), los selectores del tablero, el libro de visitas (entradas y la V de la segunda), el formulario y los cuerpos de los correos 1 a 3; el verificador falla si encuentra literalmente un nombre o inicial vigente de la tabla dentro de un texto. No hay más marcadores ni lógica dentro de los textos.
9. **Segmentos.** Una línea se compone de uno o más **segmentos**, cada uno con su texto y, opcionalmente, una pausa previa. `VO_G_07` tiene dos segmentos («Venga, que somos un equipo» y «No. Esa toma no. …»), separados por la pausa que marca el guion. El subtítulo de una línea es la secuencia de sus segmentos; no existe una pista de subtítulos aparte.
10. **Fragmentos de documento.** Un documento puede dividirse en fragmentos ordenados que otros sistemas piden por separado. `DOC_01` tiene tres (F1, F2 y F3 del puzle 2); la concatenación de sus fragmentos, en orden, es el texto del documento.

**Hechos observables y datos derivados**

11. **Un dato, un registro.** Cada dato observable (el día y la hora de un correo, su remitente, la fecha del formulario) se define en un único registro. Los textos que lo muestran lo leen de ahí y no lo reescriben a mano. La impresión de correos (`I-01`) se compone a partir de los registros de los seis correos.
12. **Orden de presentación separado del cronológico.** Cada correo guarda su día y su hora de envío; el orden en que se muestran es una **lista explícita de los seis correos**, única para pantalla e impresión, y queda decidida así: **3, X1, 1, 4, X2, 2** (mantiene el orden 3-1-4-2 de los numerados, que fija el slice, y no revela la solución; X1 y X2 van «intercalados» según B.1). Los dos correos de ruido llevan redacción mínima, solo en los datos (no cambia el slice): **X1** remitente «Sistemas», asunto «Cambio de extensiones», cuerpo «El lunes se renumeran las extensiones de la planta 9. La lista nueva está en recepción.»; **X2** remitente «Mantenimiento», asunto «Aire acondicionado», cuerpo «El martes se revisa el aire acondicionado de la planta 9. Puede haber cortes breves de ventilación.» Redacción provisional del writer; no nombran a ningún personaje. La solución del puzle 1 (2, 1, 3, 4) es el orden de los numerados por (día, hora), no el orden de presentación.
13. **Etiquetas de búsqueda.** Un correo puede llevar etiquetas. Los cuatro correos numerados llevan «transición»; los dos de ruido no (slice §10.1). Cómo se hace la búsqueda lo decide el sistema del ordenador (19); este solo entrega las etiquetas.

**Solo lectura y verificación**

14. **Solo lectura en juego.** El contenido no cambia entre cargas (la recarga en caliente de la regla 19 solo existe en desarrollo). Lo que el jugador ha leído o hecho se guarda como hechos en el estado del juego (3), no aquí.
15. **Fuente de verdad.** Los ficheros de datos son lo que lee el juego. El texto de las 28 entradas del §12 se edita primero en el slice y después en los datos; el resto (pistas, interfaz, objetos, correos de ruido) se edita solo en los datos. Un verificador en `tools/` compara el contenido con la tabla de líneas de la sección 12 del slice y **falla** si no coinciden. Los cambios de texto de diseño entran como una versión nueva del slice (v0.4…) y se reflejan en los datos.
16. **Qué comprueba el verificador:**
    - Que no hay identificadores duplicados.
    - Que cada identificador usado por otros ficheros de datos existe.
    - Que cada línea que se oye tiene texto (nunca es legal una línea audible sin texto).
    - Que los grupos de variantes están completos (A, B y C; A a D; `VO_G_14`: `RET` y `ASG`).
    - Que los marcadores de nombre son válidos.
    - Que ningún texto contiene literalmente el nombre o la inicial vigentes de la tabla de nombres (regla 8).
    - Que el conjunto de claves `PISTA_*` es exactamente el de la regla 20 (8).
    - Que toda entrada de la regla 23 con texto provisional lleva el marcador de pendiente (aviso; error con `--hito=calidad`) y que las entradas `propuesta_D-B1` no se comparan con el §12. `MEGA_03` **sí** es del §12 (`fuente: slice_§12`, slice v0.4): se compara como las demás y, mientras su texto sea el provisional, lleva además el marcador de pendiente.
    - Que cada clave `SUB_…` tiene el formato `SUB_<EVENTO>` con el evento en mayúsculas y que, si su texto es provisional, lleva el marcador de pendiente (regla 22).
    - Que las entradas marcadas `fuente: slice_§12` coinciden con el §12: todo identificador del §12 existe y su texto coincide, y toda entrada marcada sin fila en el §12 falla; las líneas audibles fuera del §12 (mensajes del teléfono, megafonía del sistema, `UI_…`) no llevan la marca y no se comparan. El texto de comparación es el contenido entre « » de cada celda del §12 (el punto final queda fuera de las comillas y no se exige); los cuatro marcadores de nombre (regla 8) se sustituyen con la tabla de nombres antes de comparar; una celda con `[pausa]` se parte en segmentos y se compara segmento a segmento, y la pausa cuenta como «pausa previa mayor que 0»; los fragmentos de un documento se unen con un espacio; se normalizan espacios y saltos de línea.
    - Que cada línea audible tiene el campo `audio` (la ruta del fichero, o nulo si aún no está grabado) y que, si la tiene, el fichero existe (se avisa, no falla, mientras el audio no esté grabado; ver «Sin audio»). Toda línea de tipo voz, megafonía o voz interior es audible por definición; `DOC_01`, `NOTA_*` y `CARTA_*` no lo son y no llevan `audio`.
    - El verificador acepta un parámetro de hito (`--hito=calidad`); con él, las líneas sin audio pasan de aviso a error. Termina con código 0 si no hay errores (aunque haya avisos) y con código distinto de 0 si los hay.
17. **Sin audio.** Una línea audible puede existir sin audio mientras se prototipa (campo `audio` nulo o fichero ausente). Se considera «sin audio»: se muestra solo el subtítulo, durante el tiempo que decida el sistema de subtítulos (26). El verificador la lista como aviso hasta que se ejecuta con el hito de calidad, momento en el que pasa a error.

**Reglas de contenido (revisión humana, no automáticas)**

18. **Lista de revisión de cada texto nuevo** (la firma quien lo revisa): (a) las líneas del Guardián nunca explican por qué pasó algo y pueden contradecirse con los documentos (slice §12); (b) ningún texto confirma las intenciones de nadie; (c) ningún texto da instrucciones sobre cómo sentirse (slice §17); (d) ningún texto clasifica a un personaje como bueno o malo.
19. **Carga.** El catálogo se carga una vez al arrancar. En builds de desarrollo se puede **recargar en caliente**, sin reiniciar, para ver un cambio de texto al momento. La recarga es un **intercambio atómico**: se lee y valida el catálogo nuevo aparte mientras se sigue sirviendo el anterior, y solo al validar se sustituye de una vez; si la validación falla, se conserva el anterior y se muestra el error. Por eso una recarga nunca produce peticiones en «Cargando».

**Pistas y textos de emergencia**

20. **Pistas: qué claves existen.** Contrato con el marco de puzles (9, reglas 25 y 27: un nivel `TEXT` de pista referencia siempre una clave `PISTA_P<n>_N<k>`; no admite claves `UI_…`) y el sistema de pistas (17): **existe una clave `PISTA_*` solo para las pistas cuyo efecto muestra un texto propio** (8 claves). Las pistas de efecto no textual (resaltado, afordancia, auto-resolución, dato de otro documento) no llevan clave: su efecto vive en los datos del puzle (9) y, si muestran un texto que ya existe en otro sitio, lo leen de ese sitio. P1 a P5 tienen tres niveles de pista y P6 dos. El nivel 1 del P1 es un **resaltado (HIGHLIGHT)** de la impresión; **no mueve la cámara** (decisión del usuario, 2026-11-09; el «gesto de cámara» del slice se reinterpreta).

    | Puzle · nivel | Efecto | Clave / texto |
    |---|---|---|
    | P1 N1 | Resaltado de la impresión | — (sin clave) |
    | P1 N2 | Texto en el pie de la impresión | `PISTA_P1_N2`: «Ordena por hora de envío» |
    | P1 N3 | Hora en letra pequeña al pie de cada correo | — (dato del registro del correo, regla 11) |
    | P2 N1 | Texto de F1 en espejo, 2 s | `PISTA_P2_N1`: «El memorando está escrito en espejo. Un haz lo muestra mejor que la luz directa» |
    | P2 N2 | Marcas numeradas del suelo (B08) | — (afordancia) |
    | P2 N3 | Halo del haz actual en el cristal | — (efecto visual) |
    | P3 N1 | Silueta de cada hueco | — (efecto visual) |
    | P3 N2 | Número de fila al mantener `PULSAR` 0,5 s | — (dato del objeto) |
    | P3 N3 | Contorno del hueco correcto tras 60 s; **permanece hasta que la pieza encaja** (13, D13-8) | — (efecto visual) |
    | P4 N1 | Regla del tablero siempre visible | `PISTA_P4_N1`: «Acepta lo que tiene urgencia y responsable. Devuelve lo que no te corresponde». Es la misma clave del texto fijo del tablero (no se duplica en `UI_…`) |
    | P4 N2 | Resalte de la descripción de la ficha | — (efecto visual) |
    | P4 N3 | T1 se resuelve sola y muestra su explicación | `PISTA_P4_N3`: «La urgencia sigue al plazo; el responsable, a quien ya lleva el caso» |
    | P5 N1 | Texto | `PISTA_P5_N1`: «El reflejo muestra algo que la foto de la caja no muestra» |
    | P5 N2 | Texto | `PISTA_P5_N2`: «Compara las dos fotos con atención» |
    | P5 N3 | Se ilumina la marca de 40° del marco | — (efecto visual) |
    | P6 N1 | Texto tras 10 s sin pulsar | `PISTA_P6_N1`: «Solo puedes elegir una vez» |
    | P6 N2 | Texto tras 20 s sin pulsar | `PISTA_P6_N2`: «La carta no cambia; cambia la primera frase» |

    Las 8 claves son un conjunto cerrado (`PISTA_P1_N2`, `PISTA_P2_N1`, `PISTA_P4_N1`, `PISTA_P4_N3`, `PISTA_P5_N1`, `PISTA_P5_N2`, `PISTA_P6_N1`, `PISTA_P6_N2`); P6 no tiene `PISTA_P6_N3`. Los textos coinciden con el slice (Anexo B). La carga de `puzzles.json` falla si un efecto `TEXT` referencia una clave `PISTA_*` inexistente (GDD 9, regla 29).
21. **Textos de emergencia.** Existen dos textos que el catálogo no puede servir porque pueden pedirse sin catálogo cargado: el marcador «…» (petición sin catálogo o no encontrada en la build final) y un único **mensaje de fallo de carga** («No se ha podido cargar el contenido del juego. Vuelve a intentarlo desde el título.», en `es`, redacción provisional del writer). Son constantes definidas fuera del catálogo, listadas como únicas excepciones de la regla 6. Ningún otro literal visible está permitido.

22. **Sonido no verbal con subtítulo.** Los eventos sonoros sin palabras que el jugador debe poder leer (el llanto contenido de la llamada en el silencio de 20 s, escena 7; `SFX_BREATH_BROKEN` es solo su audio) llevan una clave `SUB_<EVENTO>` por evento, con un texto breve entre corchetes (forma `[…]`; describe el sonido, no lo que siente nadie, regla 18). Campos: identificador, escena, texto y `audio` opcional (rige la regla 17: sin audio, el subtítulo se muestra igual). No son líneas del §12 (el verificador no las compara con el slice), no pertenecen a ningún grupo y las pide quien emite el evento (22 para el llanto); el sistema de subtítulos (26) decide cómo se muestran. **El texto definitivo de cada `SUB_…` lo escribe el writer/narrative-director** (Open Question 11): este GDD no lo fija. Hasta entonces el dato lleva un marcador de pendiente que el verificador lista como aviso (error con `--hito=calidad`).

23. **Claves pedidas por el lote Feature 1 (8, 19, 20, 21) y por 22 (lote Feature 2).** Estas entradas no son del §12 (no llevan `fuente: slice_§12`, no cambian el recuento de 28 ni el de 8 claves `PISTA_*`). **El texto de cada una es provisional**: cada entrada lleva el marcador de pendiente de la regla 22 (aviso del verificador; error con `--hito=calidad`) hasta que lo cierre el writer/narrative-director. Este GDD fija el tipo, la clave y quién la pide; no inventa el texto definitivo. Excepción: cuando el GDD pedidor o el slice ya dan el literal, se anota como texto provisional. `MEGA_03` ya no está en esta regla: desde D18-20 es una entrada del §12 (regla 2).

    | Clave | Tipo | Pide | Contenido / nota |
    |---|---|---|---|
    | `OBJ_C06`, `OBJ_C07`, `OBJ_D06` | Texto de objeto (pie) | 8 (regla 16) | Lector «cerrada sin tarjeta» de B, de D por fuera y de D por dentro (`D06` es espejo de `C07`). Pie breve, ambiente y estado, nunca información necesaria para avanzar; tono neutro sin confirmar intención (regla 18). **No existe un mensaje distinto para «tarjeta equivocada»**: el lector no dice al jugador si tiene la tarjeta |
    | `OBJ_C08` | Texto de objeto (pie) | 8 (regla 16) | Ascensor inactivo (objetivo con `SIN_EFECTO`, slice §13.3). Mismo criterio |
    | `UI_MAIL_BUSCAR`, `UI_MAIL_BUSCAR_BTN`, `UI_MAIL_VACIO`, `UI_MAIL_SIN_RESULTADOS`, `UI_MAIL_COINCIDE`, `UI_MAIL_IMPRIMIR`, `UI_MAIL_YA_ENVIADO`, `UI_MAIL_TECLADO` | Interfaz | 19 (R5, R12, R13, R20, R22, R23) | Rótulos de la pantalla del ordenador: campo de búsqueda y botón, estados vacío y sin resultados, aviso de coincidencia, botón «Imprimir», aviso de ya impreso y rótulo del teclado en pantalla. Distancia de lectura y tamaño mínimo: ux del ordenador |
    | `OBJ_V01`, `OBJ_V08` | Texto de objeto (etiqueta) | 19 | Etiquetas del ordenador y de la impresora |
    | `OBJ_V08_SIN_RESULTADOS`, `OBJ_V08_YA_IMPRESA` | Texto de objeto (pie) | 19 | Pies de la impresora sin búsqueda previa y con la hoja ya impresa |
    | `DOC_I01` | Documento, plantilla de composición (estilo `impreso`) | 19 (R20, R30, D19-11) | **No es un documento de 20 ni un ítem relegible.** 18 posee solo la **cabecera** de la hoja; el contenido lo compone 19 (`compose_i01()`) a partir de los registros de los seis correos (regla 11) y del pie `PISTA_P1_N2` (regla 20). Sin fragmentos ni `audio` |
    | Asunto y remitente de `MAIL_1` a `MAIL_4` | Campos del correo | 19 | El tipo **correo** (regla 1) gana el campo **asunto** (los de `MAIL_X1`/`MAIL_X2` ya están en la regla 12). Asuntos y remitentes de los cuatro numerados: provisionales (el slice B.1 fija día, hora y firma, no el asunto) |
    | `DOC_FORMULARIO`, `DOC_LISTA_TAREAS` | Documento con estilo | 20 (R2, tabla de ítems) | Propuestas de clave: formulario del Anexo A.4 (`I-04`, estilo `impreso`) y lista de tareas (`I-05`, `manuscrito_guardian`, nombre de Vera tachado y reemplazado por la inicial del Guardián, regla 1). Estilo de `NOTA_01` (`I-06a`): `manuscrito_guardian`. 20 exige que el estilo salga de este catálogo; el arte puede cambiarlo, el campo es de 18 |
    | `UI_BOLSILLO_AYUDA` | Interfaz (pie no bloqueante) | 20 (R23), 24 | Texto de 20: «Atrás: revisar los papeles» (**texto provisional**, marcador de pendiente). **Decidida (D18-21):** la acción `atrás` en `exploración` es `repasar_bolsillo` (Q1 de 20: un documento por pulsación, sin menú); la clave es el pie no bloqueante de esa acción. Nada del bolsillo se persiste (5) |
    | Mensajes del teléfono de la escena 1: «¿Jugamos esta noche?», «Ahora no», «Este número ya no está disponible» | Interfaz (mensajes del sistema) | 21 (escena 1) | Tres entradas `UI_…` (nombres definitivos al poblar los datos). El texto del mensaje inicial es el que cita el slice; «Ahora no» depende de PA-9 de 21 (ver pendiente) |
    | Rótulo «Continuará» | Interfaz | 21, 27 | Rótulo de la tarjeta final; lo pinta 27. Distribución del tiempo título/rótulo: PA-4 de 21 |
    | `MEGA_03` | Línea (megafonía) | 8 (único pedidor); 21 no la pide | **Entrada del §12 desde el slice v0.4** (D18-20; `fuente: slice_§12`; aprobada por el usuario, 2026-11-09). Cuenta entre las 28 del §12 y en AC-02/AC-03; el verificador la compara con el §12 (regla 16). Texto: «Planta en modo de ahorro energético» (slice §13.3), **provisional** y con marcador de pendiente hasta que el writer lo cierre si el slice no da el definitivo |

    | `UI_LLAMADA_OPCION_A`, `UI_LLAMADA_OPCION_B`, `UI_LLAMADA_OPCION_C`, `UI_LLAMADA_OPCION_D` | Interfaz (opción de respuesta de la llamada) | 22 (regla 9; D22-11) | Las cuatro opciones de la escena 7 en el orden A, B, C, D (slice §11.1; el texto ya lo da el slice, que se anota como provisional: «Estoy bien», «Estoy desbordada», «No quiero hablarlo ahora», «No responder»). Las claves son **propuestas de 22** (marcador de pendiente: nombres definitivos al poblar los datos). Son entradas `UI_…`, no líneas del §12: no cuentan en el recuento de 28 ni en el de 8 `PISTA_*` |
    | `SUB_BREATH_BROKEN` | Sonido no verbal con subtítulo (regla 22) | 22 (regla 20; D22-18) | Subtítulo del llanto contenido (`SFX_BREATH_BROKEN`, escena 7). **Entrada provisional con marcador de pendiente**: el texto lo escribe el writer/narrative-director (Open Question 11; 22 propone «[Llanto contenido]» sin fijarlo aquí). No es del §12 |

    `SUB_BREATH_BROKEN` es la única `SUB_…` de este lote.

    **Claves de los puzles 4 y 6 (ronda de corrección 8; D18-29).** Pedidas por 14 (Cambios requeridos, punto 2) y 16 (Cambios requeridos, 18 (a)). Mismo régimen que la tabla anterior: entradas `UI_…` provisionales con marcador de pendiente (regla 22), no son del §12 y **no cambian** el recuento de 28 ni el de 8 `PISTA_*`. Los literales entre comillas son los del slice o del GDD pedidor, anotados como texto provisional; los nombres definitivos se confirman al poblar los datos.

    | Clave | Tipo | Pide | Contenido / nota |
    |---|---|---|---|
    | `UI_P4_URGENCIA`, `UI_P4_RESPONSABLE` | Interfaz (rótulo) | 14 (P4-R2) | Rótulos de los dos selectores de cada ficha. Texto pendiente del writer |
    | `UI_P4_URG_ALTA`, `UI_P4_URG_MEDIA`, `UI_P4_URG_BAJA` | Interfaz (opción) | 14 | «Alta», «Media», «Baja» (provisional) |
    | `UI_P4_RESP_VERA`, `UI_P4_RESP_GUARDIAN`, `UI_P4_RESP_DIRECCION` | Interfaz (opción) | 14 | «Vera», «Guardián», «Dirección» (provisional; el nombre depende de la regla 8 y de D-04/D-07) |
    | `UI_P4_DEVOLVER` | Interfaz (botón) | 14 | «Devolver» (provisional) |
    | `UI_P4_SELLO_ACEPTADA`, `UI_P4_SELLO_DEVUELTA` | Interfaz (sello) | 14 (D14-3) | «ACEPTADA», «DEVUELTA» (provisional). Sin color ni sonido que codifique bien o mal |
    | `UI_P4_NO_CORRESPONDE` | Interfaz (aviso) | 14 (`no_corresponde_s` 1,5 s) | «No corresponde», solo T1–T3 (T4 no se rechaza) |
    | `UI_P6_BOTON_A`, `UI_P6_BOTON_B`, `UI_P6_BOTON_C` | Interfaz (botón) | 16 (regla 4) | «Estoy bien», «La verdad», «Todavía no» (slice §10.6 y B.6; provisional). Entradas independientes de `CARTA_A/B/C` y de `UI_LLAMADA_OPCION_*` aunque repitan texto (Edge Case de entradas con el mismo texto). El texto de B y su efecto sobre `CARTA_A` es la Open Question 17 |

    **Confirmaciones.** (1) 16 **no necesita más claves**; (2) 13 y 15 no piden claves nuevas; (3) el sello del cristal del P2 es gráfico, **sin clave** (D12-5), y `PISTA_P2_N1` basta para su pista 1 (Q12-4: solo texto; la vista previa en espejo es efecto visual); (4) la hoja del P1 solo tiene la cabecera de `DOC_I01` (arriba) y `PISTA_P1_N2`; (5) **no hay clave** para un aviso de «elección recordada» (D14-11); (6) la regla del tablero es `PISTA_P4_N1` (no se duplica en `UI_…`); (7) ningún puzle cambia el número de claves `PISTA_*`: siguen siendo 8.

### States and Transitions

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin cargar** | Antes de arrancar. Cualquier petición es un error. | Cargando |
| **Cargando** | Solo en el arranque: lee los ficheros de datos y los valida. | Listo · Error |
| **Listo** | Atiende peticiones de lectura. En desarrollo, una recarga en caliente valida un catálogo nuevo aparte (regla 19) sin salir de este estado. | Listo (catálogo sustituido o conservado) |
| **Recarga fallida** (solo desarrollo) | La validación del catálogo nuevo falla: se queda en Listo con el catálogo anterior y se muestra el error (regla 19). | Listo |
| **Error** | Falta un fichero o hay datos corruptos o duplicados. | — (el juego no entra en partida) |

El idioma activo es `es` en todo el slice y no cambia durante la partida.

### Interactions with Other Systems

| Sistema | Qué lee de la base de contenido |
|---|---|
| 19 Ordenador, correo e impresora | Los 6 correos con día, hora, remitente, asunto, etiquetas y orden de presentación; el pie «Ordena por hora de envío»; claves `UI_MAIL_*`, `OBJ_V01`/`OBJ_V08`/`OBJ_V08_*` y la cabecera de `DOC_I01` (regla 23) |
| 20 Documentos y bolsillo | Formulario, memorando, notas, cartas, lista de tareas, libro de visitas, con su estilo de presentación; `UI_BOLSILLO_AYUDA` (regla 23). No lee `DOC_I01` (lo posee 19) |
| 11 Puzle 1 | Textos del panel y de la impresión (a través de 19) |
| 12 Puzle 2 | `DOC_01` por fragmentos (F1, F2, F3), el sello, `NOTA_02` y las pistas |
| 14 Puzle 4 | Fichas T1 a T4, regla del tablero, sellos «ACEPTADA» y «DEVUELTA» y el mensaje «No corresponde» (solo para T1–T3: T4 acepta devolver o asignar, D-B1) |
| 16 Puzle 6 | Los tres botones, `CARTA_A/B/C` y `CARTA_CUERPO` |
| 17 Sistema de pistas | Textos de pista de los 6 puzles: 3 niveles en P1 a P5 y 2 en P6 |
| 21 Director de escenas | `MEGA_*`, `VO_V_*`, los mensajes del teléfono de la escena 1, el rótulo «Continuará» y los de sistema (regla 23) |
| 22 Llamada telefónica | `VO_G_12A/B/C`, `VO_G_13A–D`, `VO_G_14_RET`/`VO_G_14_ASG` (según `t4_decision`), las cuatro opciones de respuesta (`UI_LLAMADA_OPCION_A–D`, regla 23) y el subtítulo `SUB_BREATH_BROKEN` (regla 22, provisional) |
| 23 Director de audio | La referencia de audio y los segmentos de cada línea |
| 26 Subtítulos | El texto y los segmentos de cada línea |
| 27 Pantalla de título | Título, advertencias de contenido (slice §17) y el rótulo «Continuará» |
| 7 Interacción · 8 Control de acceso · 24 Prompt · 25 Pausa | `OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08` y la línea provisional `MEGA_03` (regla 23); etiquetas de acción («Abrir», «Girar», «Examinar», «Leer»), textos de objeto, mensajes de puerta cerrada y textos de menú |
| 3 Estado del juego | Nada (este sistema no lee el estado; los consumidores eligen la variante) |

## Edge Cases

**Peticiones**
- **If se pide un identificador que no existe en `es`** («Texto no encontrado»): en desarrollo, error visible que detiene la ejecución; en la build final se muestra el texto de emergencia «…» (regla 21) en el sitio del texto y se registra una línea en el log. No se muestra nunca el identificador al jugador.
- **If se pide un identificador que no existe en el idioma activo pero sí en `es`**: se usa el texto en `es` y se registra.
- **If se pide un identificador inactivo** (retirado, regla 4): se trata como no encontrado.
- **If se pide una letra de variante que el grupo no declara** (p. ej. `VO_G_12D`): se trata como no encontrado; el grupo declara qué letras completan cada variante.
- **If un consumidor pide un fragmento de documento que no existe**: igual que no encontrado.
- **If se pide contenido antes de que termine la carga del arranque («Sin cargar» o «Cargando»)**: en desarrollo, error visible; en la build final se devuelve el texto de emergencia «…» (regla 21) y se registra.

**Datos**
- **If hay dos registros con el mismo identificador en ficheros distintos**: el verificador falla; si ocurre en el juego, en desarrollo se detiene la ejecución y en la build final gana el primero cargado y se registra.
- **If un texto contiene un marcador desconocido** (p. ej. `{otro}`): el verificador falla; en la build final el marcador se elimina del texto y se registra.
- **If la tabla de nombres no define alguno de los cuatro marcadores** (nombre o inicial de Vera o del Guardián): el catálogo no pasa a «Listo» y se entra en «Error» (no se puede mostrar un nombre vacío en el formulario); en una recarga en caliente se conserva el catálogo anterior.
- **If un grupo de variantes está incompleto** (falta una letra): el verificador falla.
- **If una línea tiene audio pero el fichero indicado no existe**: en desarrollo, aviso; en la build final, la línea se trata como «sin audio» (regla 17) y se registra. Mientras el audio no esté grabado no es error (ver el hito de calidad).
- **If una línea audible no tiene texto**: el verificador falla siempre, también en prototipos.
- **If un texto usa tipografía no ASCII** (comillas «», guiones largos, acentos, ñ): se conserva tal cual; el verificador solo normaliza espacios y saltos de línea al comparar con el slice.
- **If el catálogo tiene un fichero ausente o corrupto al arrancar**: estado «Error»; el juego muestra el mensaje de fallo de carga de la regla 21 (texto de emergencia, fuera del catálogo) y se cierra, igual que el sistema de estado (3).

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

**Aguas abajo (quién depende de este sistema).** Estado real: 1, 2, 3, 4, 5, 6, 7, 8, 9, 19, 20, 21 y 22 ya tienen GDD y declaran rótulos o textos como entradas de este sistema (10 pide los suyos a través de 7 y 9 y no lo lista); los demás (11–17, 23–27) aún no. Dura = no puede funcionar sin él; blanda = mejora con él pero su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 11 Puzle 1 · 12 Puzle 2 · 14 Puzle 4 · 16 Puzle 6 | Dura | Textos de panel, fragmentos, fichas, botones y pistas |
| 9 Marco de puzles | Dura en validación, blanda en ejecución | Las 8 claves `PISTA_*` con texto (regla 20) y textos de feedback; **la carga de `puzzles.json` falla si falta una clave referenciada** (GDD 9, regla 29) |
| 17 Sistema de pistas | Dura | Las 8 claves `PISTA_*` con texto; los efectos no textuales no pasan por aquí (regla 20) |
| 19 Ordenador, correo e impresora | Dura | Correos con hora, asunto, etiquetas y orden de presentación; claves `UI_MAIL_*`, `OBJ_V*` y cabecera de `DOC_I01` (regla 23) |
| 20 Documentos y bolsillo | Dura | Documentos con estilo de presentación; `UI_BOLSILLO_AYUDA` (regla 23) |
| 21 Director de escenas | Dura | Líneas de voz y megafonía; mensajes de sistema; mensajes del teléfono y rótulo «Continuará» (regla 23) |
| 22 Llamada telefónica | Dura (la declara 22; ya tiene GDD) | Líneas del Guardián, opciones de respuesta (`UI_LLAMADA_OPCION_A–D`) y `SUB_BREATH_BROKEN`; las pide por ID sin modificar textos |
| 23 Director de audio | Dura | Referencia de audio de cada línea |
| 26 Subtítulos | Dura | Texto y segmentos de cada línea |
| 27 Pantalla de título y cierre | Dura | Título, advertencias, «Continuará» |
| 1 Entrada y controles · 2 Jugador en primera persona · 4 Escena de planta · 5 Guardado y carga · 6 Ajustes | Blanda | Solo claves `UI_…`: rótulos y mensajes propios (p. ej. «Mando desconectado», reasignación, ajustes de manejo, errores de carga/guardado, «Reducir movimiento»). Contribuye a la OQ 11 del GDD 6 (sigue abierta allí) y cierra la OQ 8 del GDD 4 (mensaje de fallo de carga: regla 21) |
| 7 Interacción · 8 Control | Dura | Etiquetas de acción (claves `UI_VERBO_*` que 7 necesita: Abrir, Girar, Examinar, Leer, **Descolgar, Encender, Apagar, Imprimir, Usar, Entrar**), textos de objeto (`OBJ_<id>`, incluidos **`OBJ_A02a` a `OBJ_A02c`**), textos de objeto, mensajes de puerta cerrada y menús (incluidos los `UI_…` que anticipa el GDD de Entrada y controles: «Mando desconectado», reasignación y ajustes de manejo) |

**Índice de sistemas:** ya refleja al 18 como dependencia, con la dureza que declara cada dependiente (ronda de corrección 3): **blanda** de 1, 2, 4, 5 y 6; **dura** de 7, 8, 9 (en validación), 19, 20 y 21, y también de 11, 12, 14, 16, 17, 22, 23, 24, 25, 26 y 27 (los que aún no tienen GDD deben repetir la dureza de la tabla de arriba al redactarse). Regla común: la dureza la declara el dependiente y el proveedor la repite; si discrepan, manda el dependiente.

**Bidireccionalidad.** Los GDD 1, 2, 3, 4, 5, 6, 7, 8, 9, 19, 20, 21 y 22 ya listan este sistema (rótulos `UI_…`, claves de pista, correos, documentos, líneas) y piden el contenido solo por identificador. Los que aún no existen (11–17 y 23–27) deben, al redactarse, listarlo como dependencia.

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
| `design/slice/slice-v0.3.md` (contenido v0.4) · §12 | Tabla de 28 líneas con identificador | Fuente de verdad del diseño de las líneas; el verificador compara contra ella (reglas 15 y 16) |
| `design/slice/slice-v0.3.md` · Anexo B.1 | Correos, horas y orden de impresión | Origen de los registros de correo (reglas 11 y 12) |
| `design/slice/slice-v0.3.md` · Anexo A.4, D.1 | Formulario y lista de ítems `I-01` a `I-07` | Documentos y su relación con los ítems |
| `design/slice/slice-v0.3.md` · Anexo B.2 | Fragmentos F1 «Traslado de Vera: aprobado a petición de la interesada.», F2 «Ratificación pendiente» y F3 «de firma del responsable.» | Parten `DOC_01` (regla 10); su concatenación con espacios da el texto del §12 |
| `design/slice/slice-v0.3.md` · D-04, D-07, D-10 | Nombres provisionales y localización | Justifican los marcadores de nombre y las claves de traducción |
| `design/slice/slice-v0.3.md` · §17, §19 (criterio 8) | Reglas de contenido y subtítulos que coinciden con todas las líneas | Reglas 16 y 18 |
| `design/gdd/game-pillars.md` | *Información incompleta*, *Ambivalencia sin moral binaria* | Pilares que este sistema sirve |
| `design/art/art-bible.md` · §7.2 | Tipografía, comillas, hora de 24 h, caracteres que debe cubrir | Condiciona la sección Visual/Audio |
| `design/gdd/estado-y-bus-de-eventos.md` | `carta_variante`, `respuesta_llamada` y `t4_decision` | Los consumidores eligen la variante leyendo esos hechos (regla 5); este sistema no los lee |
| `design/gdd/entrada-y-controles.md` | Mensaje «Mando desconectado» y otros textos de interfaz | Texto de interfaz que debe existir en el catálogo |
| `design/gdd/marco-de-puzles.md` | Reglas 25 y 29 (claves `PISTA_*` y fallo de carga) | Contrato de la regla 20 |
| `design/gdd/systems-index.md` | Fila 18 y dependientes | Debe reflejar la tabla de Dependencies |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/content/`), bloqueante; **I** = test de integración o playtest documentado, bloqueante; **T** = ejecución del verificador de `tools/`, bloqueante en CI. El GDD no define presupuestos de carga ni de memoria y no se inventa ninguno.

**Contenido e identificadores (reglas 1 a 5)**
- **AC-01 (R1, L)**: **GIVEN** el catálogo en «Listo», **WHEN** se pide un ejemplo de cada tipo (línea, documento, correo, ficha T1, pista, `UI_…`, `OBJ_…`), **THEN** cada uno devuelve todos sus campos obligatorios y ninguno vacío.
- **AC-02 (R2, T)**: **GIVEN** los datos del slice, **WHEN** corre el verificador, **THEN** cuenta 28 entradas del §12 (21 líneas audibles: 8 de Vera, 10 del Guardián —incluidas `VO_G_14_RET` y `VO_G_14_ASG`— y 3 `MEGA_`; y 7 de documento: 1 `DOC_`, 2 `NOTA_`, 4 `CARTA_`), 6 correos (4 numerados y 2 sin numerar) y las fichas T1 a T4.
- **AC-03 (R3, T)**: **GIVEN** los datos, **WHEN** se listan los identificadores, **THEN** los 28 del §12 existen con las mayúsculas exactas, las claves `PISTA_*` son exactamente las 8 de la regla 20 (ninguna `PISTA_P6_N3`) y los demás nuevos cumplen `UI_…`, `SUB_<EVENTO>`, `OBJ_…`, `MAIL_1` a `MAIL_4` o `MAIL_X1` y `MAIL_X2`; el orden de presentación de los correos referencia exactamente esos seis identificadores.
- **AC-03a (R22, T)**: **GIVEN** los datos con una clave `SUB_BREATH_BROKEN` válida y otra `sub_llanto` o `SUB_Llanto`, **WHEN** corre el verificador, **THEN** la primera pasa el formato `SUB_<EVENTO>` y las otras dos fallan; **GIVEN** una `SUB_…` con texto provisional y sin marcador de pendiente, **THEN** el verificador falla; con el marcador, la lista como aviso (error con `--hito=calidad`); y una `SUB_…` sin `audio` se muestra igual (regla 17).
- **AC-22 (R23, T)**: **GIVEN** los datos con las entradas de la regla 23 (texto provisional, marcador de pendiente), **WHEN** corre el verificador, **THEN** las lista como aviso con código 0 (error con `--hito=calidad`); **GIVEN** `MEGA_03` con `fuente: slice_§12`, **THEN** AC-02 cuenta 28 entradas del §12 (21 audibles y 7 de documento), el verificador la compara con el §12 y las claves `PISTA_*` siguen siendo 8; **GIVEN** `MEGA_03` sin fila en el §12 del slice, **THEN** el verificador falla; **GIVEN** `DOC_I01`, **THEN** no tiene fragmentos ni ítem de 20 asociado.
- **AC-04 (R4, L + T)**: **GIVEN** un identificador marcado inactivo, **WHEN** se pide, **THEN** se trata como «no encontrado»; **GIVEN** una referencia de otro fichero a un identificador que no existe ni está inactivo, **THEN** el verificador falla.
- **AC-05 (R5, L + T)**: **GIVEN** los grupos `CARTA_` (A–C), `VO_G_12` (A–C), `VO_G_13` (A–D), `VO_G_14` (`RET`, `ASG`) y `VO_V_12` (A–D), **WHEN** se quita una letra o sufijo de cualquiera, **THEN** el verificador falla; **WHEN** se pide `VO_G_12D`, **THEN** devuelve «no encontrado»; `CARTA_CUERPO` y `VO_V_12E` se piden como líneas simples.

**Texto y traducción (reglas 6 a 10)**
- **AC-06 (R6, T + I)**: **GIVEN** los scripts y escenas del juego, **WHEN** corre el escaneo con la definición de «literal visible» de la regla 6, **THEN** no hay ninguno fuera de depuración, log y la lista de excepciones; **GIVEN** un script de prueba con `label.text = "Hola"`, **THEN** el escaneo lo marca; con `label.text = ""` o un literal de log, no.
- **AC-07 (R7, L)**: **GIVEN** un idioma de prueba `xx` sin un identificador, **WHEN** se pide, **THEN** devuelve el texto en `es` y se registra; si falta también en `es`, devuelve «no encontrado».
- **AC-08 (R8, L + T)**: **GIVEN** la tabla de nombres con nombre e inicial de Vera y del Guardián, **WHEN** se lee un texto con `{vera}`, `{guardian}`, `{vera_inicial}` o `{guardian_inicial}`, **THEN** se sustituye (p. ej. `VO_V_12E` da «La V no me convence» con la inicial «V»); **WHEN** se cambia solo la inicial de la tabla, **THEN** `VO_V_12E`, las firmas de los correos 1 a 3, la ficha T4 y el libro de visitas cambian sin más ediciones; **GIVEN** un texto con el nombre vigente escrito a mano, **THEN** el verificador falla; con `{otro}` el verificador falla; si la tabla no define alguno de los cuatro, el catálogo entra en «Error».
- **AC-09 (R9, L)**: **GIVEN** `VO_G_07`, **WHEN** se lee, **THEN** tiene 2 segmentos, el segundo con pausa previa, y el subtítulo es la secuencia de ambos.
- **AC-10 (R10, L)**: **GIVEN** `DOC_01`, **WHEN** se piden F1, F2 y F3, **THEN** existen y su concatenación en orden, unida con espacios, es el texto del documento; F4 devuelve «no encontrado».

**Hechos observables (reglas 11 a 13)**
- **AC-11 (R11, L)**: **GIVEN** el correo 2, **WHEN** se lee, **THEN** tiene lunes 09:14 en un único registro; **WHEN** se cambia esa hora en los datos, **THEN** la impresión `I-01` la refleja sin más ediciones.
- **AC-12 (R12, L)**: **GIVEN** los 6 correos, **WHEN** se pide la lista de presentación, **THEN** es la lista explícita de los datos, con los numerados en el orden 3, 1, 4, 2 y la lista completa es 3, X1, 1, 4, X2, 2; **WHEN** se ordenan los numerados por (día, hora), **THEN** salen 2 (lunes 09:14), 1 (lunes 11:40), 3 (lunes 16:02) y 4 (martes 08:55); **WHEN** se cambia una hora, **THEN** cambia la solución y no la lista de presentación.
- **AC-12b (R12, L)**: **GIVEN** `MAIL_X1` y `MAIL_X2`, **WHEN** se leen, **THEN** tienen remitente, asunto y cuerpo no vacíos, X1 lunes 10:30 y X2 martes 14:00, y ninguno nombra a un personaje.
- **AC-13 (R13, L)**: **GIVEN** los correos 1 a 4, **WHEN** se piden sus etiquetas, **THEN** incluyen «transición»; los dos de ruido no; el sistema no expone ninguna búsqueda.

**Solo lectura y verificación (reglas 14 a 17)**
- **AC-14 (R14, L; la parte de revisión de la interfaz pública es revisión humana)**: **GIVEN** el catálogo en «Listo», **WHEN** se inspecciona su interfaz pública, **THEN** no tiene operaciones de escritura ni lee el estado del juego.
- **AC-15 (R15, T)**: **GIVEN** los datos del slice sin tocar, **WHEN** corre el verificador, **THEN** termina con código 0; **WHEN** se cambia una letra de cualquiera de las 28 líneas, **THEN** termina con código distinto de 0 y nombra el identificador; **WHEN** solo cambian espacios o saltos de línea, **THEN** sigue en 0.
- **AC-16 (R15, T)**: **GIVEN** `VO_G_07` (celda con `[pausa]`), `DOC_01` (fragmentos) y un texto con `{vera}`, **WHEN** corre el verificador, **THEN** los compara con el §12 según la regla 16 (segmento a segmento, fragmentos unidos con espacio, marcadores sustituidos) y los da por coincidentes.
- **AC-17 (R16, T)**: **GIVEN** datos con un identificador duplicado, una referencia inexistente o una línea audible sin texto, **WHEN** corre el verificador, **THEN** falla en cada caso, también en prototipos; un fichero de audio ausente da aviso con código 0.
- **AC-18 (R17, T)**: **GIVEN** líneas audibles con `audio` nulo o con un fichero ausente, **WHEN** corre el verificador, **THEN** las lista como aviso con código 0 (`DOC_01`, `NOTA_*` y `CARTA_*` no se listan: no son audibles); **WHEN** se ejecuta con `--hito=calidad`, **THEN** pasan a error.
- **AC-19 (R17, I)**: **GIVEN** una línea sin audio, **WHEN** se reproduce en el juego, **THEN** se muestra su subtítulo y no se produce error.

**Reglas de contenido y carga (reglas 18 y 19)**
- **AC-20 (R18, I; revisión humana)**: **GIVEN** cada texto nuevo, **WHEN** se revisa, **THEN** existe una lista de revisión firmada con los cuatro puntos de la regla 18.
- **AC-21 (R19, L + I)**: **GIVEN** el arranque, **WHEN** se hacen varias peticiones de contenido, **THEN** los ficheros se leen una sola vez (observado con un contador de accesos al sistema de ficheros en un doble de prueba); **GIVEN** una build de desarrollo, **WHEN** se edita un texto y se recarga, **THEN** el cambio se ve sin reiniciar; **GIVEN** el export de la demo, **THEN** la recarga en caliente no existe.

**Casos límite**
- **AC-E1 (L + I)**: **GIVEN** el catálogo en «Sin cargar» o «Cargando», **WHEN** se pide contenido, **THEN** en desarrollo hay un error visible y en la build final se devuelve «…» y se registra; **GIVEN** un fichero ausente o corrupto, **THEN** el estado es «Error», se muestra el mensaje de fallo de carga y no se entra en partida.
- **AC-E7 (T + I)**: **GIVEN** el escaneo de la regla 6, **WHEN** corre sobre el juego, **THEN** los únicos literales visibles permitidos son los dos textos de emergencia de la regla 21 («…» y el mensaje de fallo de carga).
- **AC-E2 (L)**: **GIVEN** textos con «», —, á y ñ, **WHEN** se leen, **THEN** se conservan carácter a carácter; `CARTA_A` y la opción «Estoy bien» son entradas independientes.
- **AC-E3 (L)**: **GIVEN** una recarga en caliente que elimina un identificador en uso, **WHEN** el consumidor lo vuelve a pedir, **THEN** conserva el último texto y se registra; el siguiente intento da «no encontrado».
- **AC-E4 (L)**: **GIVEN** una línea con audio cuyo fichero no existe, **WHEN** se reproduce en la build final, **THEN** se trata como «sin audio» y se registra.
- **AC-E6 (L)**: **GIVEN** una build de desarrollo en «Listo», **WHEN** se recarga un catálogo válido con un texto cambiado, **THEN** las peticiones durante la recarga siguen devolviendo el texto anterior sin error y después el nuevo; **WHEN** se recarga un catálogo inválido (identificador duplicado), **THEN** se conserva el catálogo anterior y se muestra el error.
- **AC-E5 (L)**: **GIVEN** dos registros con el mismo identificador en ficheros distintos, **WHEN** se carga el catálogo, **THEN** el verificador falla; en el juego, en desarrollo se detiene la ejecución y en la build final gana el primero cargado y se registra.

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Ruta y formato de los ficheros de datos** (`assets/data/narrative/`), cómo se invoca el verificador y sus códigos de salida (propuesta: 0 sin errores, distinto de 0 con errores, aviso con código 0). | `/architecture-decision` | Fase de arquitectura |
| 2 | ~~Dónde se parte `DOC_01` en F1, F2 y F3.~~ **Resuelta:** el slice, Anexo B.2, fija los tres fragmentos (F3 lleva punto final, que en el §12 queda fuera de las comillas y no se exige al comparar). | — | Cerrada (2026-11-08) |
| 3 | **Duración de la pausa de `VO_G_07`** entre sus dos segmentos. | Audio / GDD del sistema 23 | GDD del sistema 23 |
| 4 | **Tiempo de un subtítulo sin audio** (prototipos): lo decide el sistema 26. | GDD del sistema 26 | GDD del sistema 26 |
| 5 | **Confirmar la definición de literal visible** del escaneo de scripts y escenas (regla 6; hay una provisional) y dónde vive la lista de excepciones. | `/architecture-decision` | Fase de arquitectura |
| 6 | **Dónde se guardan los identificadores retirados** (regla 4) y cómo se marca «inactivo». | `/architecture-decision` | Fase de arquitectura |
| 7 | **Forma de la tabla de nombres** (nombre e inicial de Vera y del Guardián, regla 8): ¿un fichero propio o parte de los datos? | `/architecture-decision` | Fase de arquitectura |
| 8 | **D-04 (nombre de Vera) y D-07 (nombre del Guardián):** siguen abiertas en el slice. El sistema las tolera con los marcadores de nombre e inicial (regla 8); queda por decidir qué nombre e inicial se graban en las voces y se firman en los documentos. **Nota:** las líneas ya grabadas (`VO_G_07` dice «Vera») hacen que cambiar la tabla de nombres rompa la coincidencia voz-subtítulo: cualquier cambio de nombre exige volver a grabar. | Autor | Antes de la grabación de voces |
| 9 | ~~Índice de sistemas: añadir el sistema 18 como dependencia de 7, 8, 11, 24 y 25.~~ **Resuelta:** el índice ya lo refleja. | — | Cerrada (2026-11-08) |
| 10 | **Línea que cambia con `t4_decision` (D-B1):** `VO_G_14_ASG` es una propuesta mínima; texto, hablante (¿Guardián o Vera?) y escena definitivos. El texto retirado del REJECT de T4 era «No corresponde» (1,5 s, ficha a neutra). | Narrative-director / usuario | Texto de `VO_G_14_ASG`: el GDD 22 existe y **no cambia el texto** (su Open Question 2 repite esta pregunta); queda la actualización del slice |
| 11 | **Texto del subtítulo del llanto contenido** (regla 22, D-W7): clave `SUB_…` y texto breve entre corchetes de cada sonido no verbal con subtítulo. No se inventa aquí. | Writer / narrative-director | El GDD 22 ya propone la clave `SUB_BREATH_BROKEN` (regla 23, texto provisional «[Llanto contenido]», su Open Question 5); 26 y el texto final, antes del hito de calidad |

**Pendiente de decisión (lote Feature 1) — lo que sigue abierto tras la ronda de decisiones 1.** Se cerraron `MEGA_03` (D18-20), `UI_BOLSILLO_AYUDA` (D18-21), los textos de `I-05`/`I-06a` (D18-22) y la hoja y la hora del P1 en lo que decide B.1 (D18-23). Siguen abiertas, con el valor provisional indicado:

| # | Pregunta | Pide | Valor provisional |
|---|---|---|---|
| 13 | **«Ahora no» como mensaje del teléfono** (PA-9 de 21): si el verbo «Responder» de `V02` sustituye la opción en pantalla del slice, hace falta `UI_VERBO_RESPONDER`; si no, «Ahora no» sigue siendo opción de pantalla | 21, 7 | Mensajes de la regla 23; sin `UI_VERBO_RESPONDER` |
| 15 | **Resto de lo de 19 (`I-01`):** `I-01` relegible fuera de `C05` (PA-9 de 19), 4 o 6 resultados (PA-4) y correos de ruido `MAIL_X1`/`MAIL_X2` dentro del alcance (PA-8): cambian el contenido de `DOC_I01` y de los correos, no las claves. La hoja con `Enviado: hh:mm` y el pie «Ordena por hora de envío» (PA-1/PA-2) ya no están abiertos: D18-23 | 19 | Valores provisionales de 19 |
| 16 | **Fuente de `t_lectura` del P6** (16, F3): «21–25 palabras» entre la primera frase y `CARTA_CUERPO` no tiene fuente en 18; 16 pide esa fuente o el **conteo real** de `CARTA_A/B/C` y `CARTA_CUERPO` para recalcular `t_lectura`. **No se inventa aquí**: a 18 le corresponde contar los textos del §12 cuando se pueblen los datos | writer / 18 (verificador de datos) | 6–12 s† de 16 sin cambio |
| 17 | **`CARTA_A` y el botón B «La verdad»** (Open Question 2 de 16): juntas pueden leerse como A = mentira, B = verdad; roza el pilar 1 y el 5. No se aplica | narrative-director / usuario | Textos del slice §12 sin tocar |
| 18 | **Textos definitivos de `UI_P4_*` y `UI_P6_BOTON_*`** y nombres definitivos de las claves | writer / narrative-director | Los literales de la tabla de la regla 23 |

## Decisiones tomadas

*Ronda de propagación 1 (2026-11-09): ver D18-16 a D18-19 al final de esta sección.*

Ronda 2 (2026-11-09), por lotes; la re-review está en `design/gdd/reviews/base-de-contenido-narrativo-re-review.md`.

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D18-1 | Solo existen claves `PISTA_*` para las pistas con texto (8, regla 20); el resto son efectos en los datos del puzle. | 17 claves siempre, con texto vacío en las no textuales. | Sin entradas vacías ni claves que no se muestran; el 9 valida solo las referenciadas. |
| D18-2 | P1 N1 es un resaltado (HIGHLIGHT) de la impresión; no mueve la cámara (decisión del usuario). | Gesto de cámara / `CAMERA_NUDGE`. | Se mantiene la regla 14 del GDD 2 (ningún evento mueve la cámara). |
| D18-3 | P1 N2 y P4 N1/N3 usan su clave `PISTA_*` también donde el texto ya aparece (pie de la impresión, tablero). | Duplicarlos como `UI_…`. | Un texto, una clave. |
| D18-4 | Dos textos de emergencia fuera del catálogo («…» y mensaje de fallo de carga), únicas excepciones de la regla 6 (regla 21). | Texto en el catálogo con respaldo. | El catálogo puede no estar cargado. |
| D18-5 | Orden de presentación 3, X1, 1, 4, X2, 2; X1/X2 con redacción mínima solo en datos, sin cambiar el slice. | Subir a slice v0.4; correos sin cuerpo. | Es relleno; no cambia ningún hecho de puzle. |
| D18-6 | Marcador de nombre obligatorio en cualquier texto; el verificador falla con el nombre vigente literal. | Lista cerrada de usos. | La lista cerrada olvida T4, libro y T1. |
| D18-7 | Comparación con el slice solo para entradas marcadas `fuente: slice_§12`. | Igualdad de conjuntos con todas las líneas audibles. | Hay líneas audibles fuera del §12. |
| D18-8 | 9 es dependencia dura en validación y blanda en ejecución. | Solo dura o solo blanda. | Unifica las tres redacciones previas. |
| D18-9 | **(usuario, 2026-11-09, D-B1)** Se elimina el mensaje «No corresponde» (rechazo de 1,5 s) **para T4**: T4 acepta devolver («DEVUELTA») o asignar («ACEPTADA»). El texto «No corresponde» se conserva para T1–T3. Una línea cambia según `t4_decision` (regla 5), como **propuesta** pendiente de narrative-director/usuario | Mantener «Devolver» como única solución; cambiar una línea de Vera en vez de la del Guardián | Pilar 1: ninguna opción es incorrecta. La línea del Guardián (`VO_G_14`) es la última de la llamada y no obliga a tocar las cartas ni las de Vera, ya con 4 variantes |

Ronda 3 (2026-11-09), tras `/review-all-gdds` (informe `gdd-cross-review-2026-11-09.md`).

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D18-10 | **(D-B2)** `VO_G_13B` pasa a «Lo sé» (slice v0.3.3). | Mantener «Lo sé. Por eso lo pedí» como excepción registrada; reescribirla con narrative-director. | «Por eso lo pedí» confirma la intención del Guardián, que el pilar 1 («Violating») prohíbe; «Lo sé» reconoce a Vera sin explicar la historia (anti-pilar). La línea sigue siendo audible y la clave no cambia. Sin subtítulo ni audio fuera del slice. |

| D18-11 | **(S-W4)** El mensaje de fallo de carga dice «Vuelve a intentarlo desde el título» (regla 21). | «Reinicia la aplicación». | Todo fallo de carga vuelve al título con acción «Volver al título» (GDD 4 regla 14); reiniciar castiga (*Tensión sin castigo*). |
| D18-12 | **(Ronda 5, F-2)** El §12 del slice ya tiene 27 entradas: `VO_G_14_RET` y `VO_G_14_ASG` son del §12, forman el grupo `VO_G_14` (reglas 5 y 16, AC-05) y cuentan en AC-02/AC-03 (27 = 20 audibles + 7 de documento). | Mantener 26 y marcarlas «no son del §12». | El verificador compara contra el §12; con 26 fallaría. |
| D18-13 | **(Ronda 5, D-W7)** Nuevo tipo «sonido no verbal con subtítulo» (`SUB_…`, regla 22) con texto definitivo pendiente del writer. | Meter el llanto como línea de Vera o del Guardián, o dejarlo sin subtítulo. | No es una línea de un personaje ni del §12; sin subtítulo, un sonido que solo se oye no sería accesible. |
| D18-14 | **(Ronda 5, F-1)** Dependencias con la numeración del índice (2 Jugador en primera persona, 4 Escena de planta, 5 Guardado y carga) y «contribuye a» la OQ 11 del GDD 6. | Seguir diciendo que la cierra. | La pregunta sigue abierta en 6; 18 solo aporta las claves `UI_…`. |
| D18-15 | **(Ronda 6, A-3/A-4)** `SUB_` entra en la lista de prefijos (regla 3, AC-03), el verificador (regla 16) comprueba su formato y el marcador de pendiente (nuevo AC-03a); Dependencies completadas y nota del índice actualizada; Overview con la distribución real de niveles. | Dejar `SUB_` fuera de la lista de prefijos. | Evita que el verificador rechace un tipo que la regla 22 ya define. |

Ronda de propagación 1 (2026-11-09), cambios requeridos por los GDD 8, 19, 20 y 21 (lote Feature 1).

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D18-16 | Regla 23: las claves `OBJ_C06/C07/D06/C08`, `UI_MAIL_*`, `OBJ_V01/V08/V08_*`, `UI_BOLSILLO_AYUDA`, los mensajes del teléfono y el rótulo «Continuará» entran como entradas con tipo, pedidor y marcador de pendiente; sin texto definitivo. No tocan el recuento de 27 ni el de 8 `PISTA_*`. | Redactar aquí el texto definitivo; subir el recuento. | El texto es del writer/narrative-director; el recuento oficial es el del §12. |
| D18-17 | `DOC_I01` es una plantilla de composición cuya cabecera es de 18 y cuyo contenido compone 19; no es documento de 20 ni ítem relegible. El tipo correo gana el campo `asunto`. No hay mensaje distinto para «tarjeta equivocada» (regla 16 de 8). | `DOC_I01` como documento de 20 con fragmentos fijos; mensaje específico de tarjeta equivocada. | `I-01` se compone de los registros de correo (regla 11); un mensaje distinto diría al jugador si tiene la tarjeta. |
| D18-18 | *(Sustituida por D18-20.)* `MEGA_03` se añade solo como entrada provisional `fuente: propuesta_slice_v0.4`, pedida por 8; no cuenta en AC-02. | Pasar a 28 entradas ahora. | Exige slice v0.4 y es decisión de alcance (pregunta abierta, bloque «Pendiente de decisión»). |
| D18-19 | Claves propuestas `DOC_FORMULARIO` y `DOC_LISTA_TAREAS`; estilo de `NOTA_01` y lista: `manuscrito_guardian`. | Dejar la clave «por asignar». | 20 exige que clave y estilo salgan del catálogo. |
| D18-20 | **`MEGA_03` es la línea 28 del §12** (slice v0.4; «Planta en modo de ahorro energético», texto provisional con marcador de pendiente): megafonía pasa de 2 a 3, audibles de 20 a 21, entradas del §12 de 27 a 28 (Summary, Overview, reglas 2, 15 y 16, AC-02, AC-03, AC-15, AC-22 y fuente del slice). `hint_key_count` no cambia (8). Aprobada por el usuario, 2026-11-09. | Mantenerla como entrada provisional `propuesta_slice_v0.4` fuera del recuento (D18-18). | La decisión de alcance está tomada; con ella en el §12 el verificador la compara como las demás y no hay una línea audible sin fuente. |
| D18-21 | **`UI_BOLSILLO_AYUDA` es definitiva como clave**; la acción `atrás` en `exploración` es `repasar_bolsillo` (un documento por pulsación, sin menú, Q1 de 20). El texto «Atrás: revisar los papeles» sigue provisional. Nada del bolsillo se persiste (5). Aprobada por el usuario, 2026-11-09. | Retirar la clave y no ofrecer relectura; o un menú de bolsillo. | Sin menú respeta el slice D.1 («No hay menú de inventario») y deja una sola pulsación para releer. |
| D18-22 | **`I-05` e `I-06a` se pueden releer desde el bolsillo** (D18-21); 9 y 10 no añaden presentación nueva al resolver P4/P3. Sus textos siguen siendo las entradas `DOC_LISTA_TAREAS` y `NOTA_01` de este sistema; sin claves nuevas. Aprobada por el usuario, 2026-11-09. | Textos de lectura nuevos al resolver P4/P3 (Q2 de 20, pregunta 7 de 10). | Los documentos ya existen; la relectura basta y no amplía el slice. |
| D18-23 | **Slice B.1 literal** para el P1: la hoja lleva `Enviado: hh:mm` siempre y el pie `PISTA_P1_N2` «Ordena por hora de envío»; las pistas 2 y 3 no añaden esa información. Se cierra solo eso (PA-1/PA-2 de 19 y lo de PA-4/PA-8 que decide B.1); 4 o 6 resultados (PA-4), ruido `MAIL_X1`/`MAIL_X2` (PA-8) y el resto de 19 quedan abiertos (pregunta 15). Aprobada por el usuario, 2026-11-09. | Dar la hora solo con pistas, o cambiar B.1. | Es lo que el slice ya fija; no cambia claves ni recuentos. |
| D18-24 | D18-18 queda **sustituida** por D18-20. Los demás recuentos (8 `PISTA_*`, 6 correos, 7 documentos) no cambian. | — | Evita dos decisiones vigentes sobre la misma línea. |
| D18-25 | **(Ronda de corrección 2, W-7, 2026-11-09)** Se retiran los «sin GDD» obsoletos de Dependencies (aguas abajo y Bidireccionalidad): ya existen los GDD 3, 8, 19, 20 y 21 y todos listan a 18. Sin cambios de reglas ni de recuentos | Dejar la lista antigua hasta el próximo lote | Un texto desfasado hace creer que faltan reciprocidades que ya están cerradas |
| D18-26 | **(Ronda de corrección 3, R6-2, 2026-11-09)** La acción de `atrás` en `exploración` se escribe siempre `repasar_bolsillo` (con guion bajo, como en 1, 7 y 20) en la fila de `UI_BOLSILLO_AYUDA` y en D18-21. Sin cambios de reglas ni de recuentos | Mantener «repasar bolsillo» en prosa | Un solo identificador en todos los GDD y en el registro; la búsqueda por texto lo encuentra. |
| D18-27 | **(Ronda de corrección 3, R6-1, 2026-11-09)** Dureza de las filas «aguas abajo» alineada con lo que declaran los dependientes: 1, 2, 4, 5 y 6 → blanda (solo claves `UI_…`); 7, 8, 19, 20 y 21 → dura; 9 → dura en validación y blanda en ejecución (regla 29 de 9). 5 no figuraba como dependiente en su GDD y ahora lo lista (blanda). 10 no depende de 18 (pide sus textos vía 7 y 9). | Dejar la dureza del proveedor cuando discrepa | Regla común del índice: manda el GDD dependiente. |
| D18-28 | **(Ronda de corrección 5, GDD 22 y A12 de `reviews/dependencias-r7-review.md`, 2026-11-09)** Se añaden a la regla 23 las claves que pide 22: `UI_LLAMADA_OPCION_A–D` (Interfaz, nombres propuestos por 22, textos del slice §11.1 como provisionales) y `SUB_BREATH_BROKEN` (regla 22, entrada provisional con marcador de pendiente; no se inventa el texto definitivo). No son del §12: no cambian el recuento de 28 entradas ni el de 8 `PISTA_*`. Se quita «22 sin GDD» de Dependencies y de la bidireccionalidad. `fallback_s` **no** es un campo de este sistema (la regla 17 deja la duración del subtítulo a 26): no se añade; queda como pregunta de 22/26. Pendientes 10 y 11 siguen abiertos (los cierra el writer, no 22). La respuesta de Vera es definitiva y la llamada repetible se repite idéntica al cargar (22, regla 17, D22-4 y regla 30): 18 no guarda variantes de «repetición» (sin claves nuevas por repetir). | Inventar el texto de `SUB_BREATH_BROKEN` o cerrar los Pendientes 10 y 11 aquí; añadir `fallback_s` como campo de línea; subir el recuento oficial | El texto es del writer/narrative-director; el recuento oficial es el del §12; `fallback_s` es de la capa de subtítulos. |
| D18-29 | **(Ronda de corrección 8, de 14 y 16)** Claves nuevas de los puzles 4 y 6 (`UI_P4_*`, `UI_P6_BOTON_A/B/C`) como entradas provisionales con marcador de pendiente en la regla 23, sin texto definitivo inventado y **sin cambiar** el recuento de 28 entradas del §12 ni el de 8 `PISTA_*` | Meterlas en el §12; esperar al writer para nombrar las claves | Los puzles las necesitan para validar `puzzles.json` y la regla 23 ya admite este régimen |
| D18-30 | **(Ronda de corrección 8, de 16)** La fuente de las «21–25 palabras» de `t_lectura` queda como pregunta abierta 16 (conteo real de `CARTA_*` al poblar los datos); no se estima aquí | Contar con el texto del slice ahora y fijar la cifra | La cifra la usa 16 como estimación de playtest; contar es del verificador de 18, no de este diseño |
| D18-31 | **(Ronda de corrección 8, de 13)** Fila P3 N3 de la regla 20: el contorno permanece hasta que la pieza encaja (D13-8). Sin clave nueva; 12 (sello y `PISTA_P2_N1`) y 11 confirmados sin claves nuevas | Dejar «tras 60 s» solo | Coherencia con 13 |

## Historial de cambios

- **2026-11-09 (ronda de corrección 2, W-7 de `gdd-cross-review-2026-11-09-r5.md`):** textos «sin GDD» de Dependencies actualizados (D18-25). Sin cambios de reglas. Estado: Revisado (ronda de corrección 2) — pendiente de re-review.
- **2026-11-09 (ronda de decisiones 1, D-A a D-D aprobadas por el usuario):** `MEGA_03` pasa al §12 (28 entradas, 21 audibles, 3 de megafonía; recuentos actualizados), `UI_BOLSILLO_AYUDA` decidida, `I-05`/`I-06a` releíbles, B.1 literal para la hoja del P1 (D18-20 a D18-24); sigue abierto el resto de 19 y «Ahora no». Estado: pendiente de re-review.

- **2026-11-09 (ronda de propagación 1, lote Feature 1):** regla 23 (claves pedidas por 8, 19, 20 y 21 con marcador de pendiente), campo `asunto` en el correo, bullet del verificador, AC-22, filas de Interacciones y Dependencies de 7·8, 19, 20 y 21, `MEGA_03` provisional y bloque «Pendiente de decisión (lote Feature 1)». No cambian los recuentos (27 entradas del §12; 8 `PISTA_*`). Estado: pendiente de re-review.

- **2026-11-09 (D-B1):** hueco de contenido por la decisión de T4: grupo provisional `VO_G_14_RET`/`VO_G_14_ASG` (propuesta, `fuente: propuesta_D-B1`), texto del REJECT de T4 retirado (D18-9) y referencias a `t4_decision`. Cambia contenido propuesto: pendiente de re-review y de narrative-director.

- **2026-11-09 (ronda 2, re-review):** se añaden la sección «Decisiones tomadas», la regla 20 (claves de pista: 8 con texto, tabla por puzle y nivel), la regla 21 (textos de emergencia), la lista de presentación completa con X1/X2, marcadores de nombre exhaustivos, marca `fuente: slice_§12`, dependencias reales (1, 2, 4, 5, 6) y el estado «Recarga fallida». Cambia reglas: pendiente de re-review.

- **2026-11-09 (lote 2/5/7/9, cambios derivados de las revisiones de 7 y 9):** (a) P6 tiene **dos** claves de pista (`PISTA_P6_N1`, `PISTA_P6_N2`), no tres (decisión del usuario; B.6 prevalece sobre slice §10/§16/§19.2): reglas 3, AC-03 y tablas de dependencias. Nota: el slice ya refleja los dos niveles del P6 (actualizado 2026-11-09). (b) Se listan las claves de etiqueta que 7 necesita (`Descolgar`, `Encender`/`Apagar`, `Imprimir`, `Usar`, `Entrar`) y `OBJ_A02a` a `OBJ_A02c`. (c) 9 listado como dependencia (la carga falla si faltan claves). Las claves concretas se crean al poblar los datos, no en este GDD. **Cambia reglas: pendiente de re-review.** Estado sin cambios.

- **2026-11-09 (ronda de corrección 3, R6-1 y R6-2 de `gdd-cross-review-2026-11-09-r6.md`):** `repasar_bolsillo` con guion bajo (fila `UI_BOLSILLO_AYUDA`, D18-21; D18-26); línea del índice de Dependencies con la dureza que declara cada dependiente (D18-27). Sin cambios de reglas ni de recuentos. Estado: Revisado (ronda de corrección 3) — pendiente de re-review.

- **2026-11-09 (ronda de corrección 5, GDD 22 y A12 de `reviews/dependencias-r7-review.md`):** regla 23 con `UI_LLAMADA_OPCION_A–D` y `SUB_BREATH_BROKEN` (provisionales, marcador de pendiente), filas de 22 en Interacciones y Dependencies, retirada de «22 sin GDD», Pendientes 10 y 11 anotados, D18-28. No cambian los recuentos (28 entradas del §12; 8 `PISTA_*`). Estado: Revisado (ronda de corrección 5) — pendiente de re-review.
- **2026-11-09 (ronda de corrección 8, propagación de los GDDs 11 a 16):** claves provisionales de 14 (`UI_P4_*`, 12 claves) y 16 (`UI_P6_BOTON_A/B/C`) en la regla 23 con marcador de pendiente; confirmaciones sin clave nueva para 11, 12, 13, 15 y 16 (el recuento de 28 y de 8 `PISTA_*` no cambia); fila P3 N3 de la regla 20; preguntas abiertas 16 (fuente de `t_lectura`), 17 (`CARTA_A` y botón B) y 18 (textos definitivos); D18-29 a D18-31. Estado: Revisado (ronda de corrección 8) — pendiente de re-review.
