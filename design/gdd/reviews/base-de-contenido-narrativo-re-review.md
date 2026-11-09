# Re-review — Base de contenido narrativo (sistema 18)

- **Fecha:** 2026-11-09
- **Revisor:** independiente (no autor), modo lean, `modes.workflow` = standard (`project.yaml`: `modes.rigor: standard`)
- **Documento:** `design/gdd/base-de-contenido-narrativo.md` (sin modificar)
- **Revisión previa:** 2026-11-08, NEEDS REVISION (2 bloqueantes, 8 recomendados; todos aplicados). Esta pasada cubre además el cambio del 2026-11-09 (P6 con dos pistas, claves de etiqueta de 7, dependencia de 9).
- **Contrastado con:** `slice-v0.3.md` (§10, §12, §16, §19.2, 11.1, B.1, B.4, B.6, D.1, D.4), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, GDDs 1, 2, 3, 4, 5, 6, 7 y 9.

## Veredicto: NEEDS REVISION

El GDD es sólido en lo que ya cubrió la primera revisión: las cifras del §12 cuadran (26 entradas = 8 Vera + 9 Guardián + 2 megafonía + 1 memorando + 2 notas + 4 cartas), los dos niveles del P6 están bien reflejados (reglas 3 y AC-03, `PISTA_P6_N1`/`N2`, 17 claves = 5×3 + 2) y coinciden con el slice actual (§10, §16, §19.2 y B.6 ya dicen «dos en el P6») y con el GDD 9 (reglas 25, 27 y 29, D9-14). Lo que impide aprobarlo es que el conjunto de claves de pista no está definido de forma implementable, que el propio GDD se contradice con su regla 6 y que las dependencias están desfasadas respecto a los GDD ya escritos.

### Completitud (standard)

Requeridas presentes: Overview, Detailed Rules (como `## Detailed Design`), Edge Cases, Dependencies, Acceptance Criteria = 5/5. Formulas no es obligatoria: el sistema no define reglas numéricas (cifras y tiempos son del slice o de otros sistemas). Player Fantasy y Tuning Knobs no existen: **consultivo** en `standard`, no bloquea. Ningún PLACEHOLDER.

### Dependencias declaradas (existencia de GDD)

Existen: 3 (indirecto), 7, 9, 1, 2, 4, 5, 6. No existen aún (todos «Not Started» en el índice): 8, 11, 12, 14, 16, 17, 19 a 27. Se ve en hallazgo 4.

### Valores del registro

`design/registry/entities.yaml` no contiene ninguna entrada propiedad del sistema 18 ni referencias a MAIL, ids de línea o a las claves `PISTA_*` (solo una nota sobre `idle_s_P6_N1/N2`). Se contrastó por tanto con el slice y los GDD vecinos: 26 líneas, 6 correos con sus horas (lunes 09:14, 10:30, 11:40, 16:02; martes 08:55, 14:00), solución 2-1-3-4, orden de presentación 3-1-4-2, grupos `CARTA_` A–C, `VO_G_12` A–C, `VO_G_13` A–D, `VO_V_12` A–D, `carta_variante` (A/B/C) y `respuesta_llamada` (A–D): sin discrepancias.

## Hallazgos

### Bloqueantes

**1. [bloqueante] Qué claves `PISTA_*` existen y qué contienen no está definido (reglas 1 y 3, Dependencies fila 9 y 17, AC-03).**
El GDD afirma «textos de pista del Anexo B» y 17 claves, y el GDD 9 (regla 29) hace **fallar la carga** si falta una. Pero casi todas las pistas del slice **no son texto**: P1 N1 es un gesto de cámara, P2 N3 y P3 N3 son halos o contornos, P4 N2 es un resaltado, etc. Solo P4 N1, P4 N3, P6 N1 y P6 N2 citan texto, y P1 N2/N3 muestran el pie de la impresión (que es dato del correo, regla 11). Un programador no puede saber si hay que crear 17 textos, cuáles, ni qué clave usan los textos no-pista que aparecen como pista (la regla del tablero P4 N1 es a la vez pista y texto fijo del tablero: ¿`PISTA_P4_N1` o `UI_…`?). La regla 25 del GDD 9 admite en `TEXT` «una clave `PISTA_P<n>_N<k>` o una clave de interfaz», así que el GDD 18 debe decir cuál es el contrato.
*Arreglo:* añadir una tabla «Pistas» con las 17 combinaciones puzle×nivel, indicando para cada una: efecto (texto / cámara / resaltado / afordancia / auto-resolución), si lleva clave `PISTA_P<n>_N<k>` con texto, y la clave `UI_…`/dato que reutiliza cuando el texto ya existe en otro sitio. Decisión por defecto sugerida: las 17 claves existen siempre y las de efecto no textual llevan texto vacío permitido por tipo `pista`, o, más limpio, solo existen las que tienen texto y el GDD 9 valida solo las referenciadas en un efecto `TEXT`. Añadir una AC que cuente las claves esperadas y fije P6 en dos.

**2. [bloqueante] El GDD se contradice con su regla 6 («ningún texto en el código»): el «…» de la build final y el mensaje del estado Error.**
Edge Cases: en la build final un identificador no encontrado o una petición antes de la carga muestran «…» (literal que debe vivir en código, porque el catálogo puede no estar cargado) y, en estado «Error», «el juego muestra un mensaje claro y se cierra» (el texto del mensaje solo puede venir del catálogo que no se ha cargado). Los GDD 4 (OQ 8, mensaje de error de carga «o texto fijo si no se puede cargar contenido») y 5 apuntan al mismo hueco y delegan en el 18. La regla 6 habla de una «lista de excepciones junto al verificador», pero el GDD no declara que estas dos sean excepciones, y AC-06 haría fallar el escaneo con el «…».
*Arreglo:* añadir una regla «Textos de emergencia»: un conjunto mínimo y cerrado (el «…» y un único mensaje de fallo de carga, en `es`, definido como constante fuera del catálogo y listado en las excepciones de la regla 6), con una AC que verifique que ese conjunto es el único literal visible permitido. Es decisión de diseño por defecto, no de tono.

### Importantes

**3. [importante] Los marcadores de nombre no cubren todos los sitios donde aparece el nombre o la inicial (regla 8, AC-08).**
La regla enumera `VO_V_12E` y las firmas de los correos 1 a 3 como usos de la inicial, pero el slice también tiene la ficha T4 («nombre tachado y reemplazado por «G»», B.4 y §10.4; `I-05`, D.1: «con el nombre de Vera tachado»), el libro de visitas («Vera · 23:40 · Planta 9»; además «la V de la segunda entrada» es un detalle visual atado a la inicial), los nombres en T1 («Ya la tiene asignada Vera»), los selectores del tablero («Vera, Guardián, Dirección»), y los cuerpos de los correos 1 a 3. Si T4 o el libro quedan escritos a mano, el cambio «en un solo sitio» que promete el Overview (D-04, D-07) falla. AC-08 solo prueba `VO_V_12E` y las firmas.
*Arreglo:* hacer la lista de la regla 8 exhaustiva por derivación (cualquier aparición del nombre o inicial en datos usa marcador; el verificador falla si encuentra literalmente el nombre vigente de la tabla dentro de un texto), y ampliar AC-08 a T4 y libro. Anotar en Open Question 8 que las líneas ya grabadas (`VO_G_07` dice «Vera») hacen que cambiar la tabla de nombres rompa la coincidencia voz–subtítulo: cualquier cambio de nombre exige volver a grabar.

**4. [importante] Dependencias aguas abajo desfasadas y no bidireccionales (Dependencies, Interactions).**
(a) El texto «Ninguno de estos sistemas tiene todavía GDD (salvo los dos ya diseñados, que no dependen de este)» es falso: 1, 2, 4, 5, 6, 7 y 9 ya tienen GDD. (b) Los GDD 1, 2, 4, 5 y 6 declaran sus rótulos como entradas `UI_…` de 18 (p. ej. GDD 5 los lista en su tabla de dependencias; GDD 6 OQ 11 pide expresamente «anotarlo» en el 18; GDD 4 OQ 8), y **el 18 no los lista** como dependientes ni anticipa sus familias de claves (solo los de Entrada y controles, orientativos). (c) El índice de sistemas deja la fila 18 con «—» y no incluye 18 en las filas de 1, 2, 4, 5, 6. (d) Dependencies fila 9 dice «Dura» pero el propio texto de debajo dice «blanda en el índice»; el GDD 9 dice «Dura en validación» y el índice «blanda» (3 fuentes, 3 redacciones). (e) La referencia «GDD 9, regla 27» para la carga fallida es errónea: es la regla 29 (la 27 es consistencia del contenido).
*Arreglo:* reescribir Bidireccionalidad con el estado real; añadir 1, 2, 4, 5, 6 a la tabla (blanda, solo `UI_…`) y a Cross-References; corregir «regla 27» a «regla 29»; unificar dura/blanda para 9 (propuesta: dura en validación, blanda en ejecución) y reflejarlo en el índice. Cerrar OQ 11 del GDD 6 desde aquí.

**5. [importante] Posición de los dos correos de ruido en la lista de presentación sin decidir (regla 12, AC-12).**
La regla dice que la lista «fija en los datos» la posición de X1 y X2 y AC-12 «las posiciones que fijan los datos»: una prueba no puede fallar. El slice (B.1) solo dice «intercalados». Además, el slice no da remitente ni cuerpo de X1 y X2 (solo asunto), pero el tipo Correo exige remitente y cuerpo.
*Arreglo:* decidir y escribir la lista completa (propuesta: 3, X1, 1, 4, X2, 2, mantiene 3-1-4-2 y no revela la solución), fijar remitentes y cuerpos de X1/X2 como Open Question de redacción (propietario: writer) y añadir su resolución a AC-03/AC-12.

**6. [importante] El conjunto de «líneas del §12» que compara el verificador no está definido (regla 16, AC-02/AC-15).**
«Que el conjunto de identificadores … del slice §12 coincide con los datos» supone igualdad de conjuntos, pero el catálogo también tendrá líneas audibles fuera del §12 (mensajes del teléfono de la escena 1, «avisos de megafonía del sistema» incluidos en el tipo Texto de interfaz) y ¿qué distingue una línea del §12 de una `UI_…` de megafonía? No hay marca (`origen: slice_12`) ni criterio por prefijo.
*Arreglo:* marcar en los datos las entradas con `fuente: slice_§12` (o definir la comparación como «todo id del §12 existe y su texto coincide; las entradas marcadas §12 sin fila en el slice fallan»).

### Menores

**7. [menor] Cabecera y fechas.** `Status: In Design` frente a `In Review` en el índice; `Last Updated: 2026-11-08` pero el historial tiene una entrada del 2026-11-09. Alinear.

**8. [menor] Regla 15 ambigua.** «Los ficheros de datos … es donde se edita el texto» choca con «las líneas del slice se editan primero en el slice» (Summary, Edge Cases). Precisar: el texto de las 26 entradas del §12 se edita en el slice primero y después en los datos; el resto, solo en datos.

**9. [menor] Registro.** Ninguna entrada de `entities.yaml` pertenece a 18 aunque los GDD 7, 9 y 17 consumen sus hechos (17 claves de pista, 6 correos con hora, grupos de variantes). Proponer al menos `mail_send_times` y `hint_key_count` como candidatos al registro.

**10. [menor] ACs.** AC-14 («inspecciona su interfaz pública») y AC-20 («lista firmada») dependen de revisión humana y deberían etiquetarse como tales; AC-21 («los ficheros se leen una sola vez») necesita medio de observación (contador de accesos al sistema de ficheros en un doble de prueba).

**11. [menor] Estados vs recarga.** La tabla de estados dice «Listo → Listo» para la recarga, correcto, pero Error vs recarga fallida aparece solo en el prosa de la regla 19 y AC-E6; añadir la fila «Recarga fallida: se queda en Listo con el anterior».

### Cruce con GDD 9 y slice sobre los dos niveles de pista del P6

Coherente. Pendiente de limpiar en otros documentos (no se tocan aquí): la regla 27 y la OQ 1 del GDD 9 y su decisión D9-14 siguen diciendo que el slice discrepa y que «queda reflejarlo en 18», cuando el slice ya dice dos y el 18 ya lo refleja; y la fila 17 del índice se titula «Sistema de pistas (3 niveles)».

## Godot 4.7 (solo lo que respalda `docs/engine-reference/godot/`)

El GDD casi no afirma API de motor. Lo único que toca el motor y **no está en** `docs/engine-reference/godot/`:

- **NOT SOURCEABLE** — carga de datos (JSON/Resource) y su comportamiento en 4.5–4.7: `docs/engine-reference/godot/` solo documenta `FileAccess.store_*` devolviendo `bool` y `duplicate_deep()`, no lectura de catálogos de texto. Implica el arquetipo «intercambio atómico» (regla 19, AC-E6): no se puede afirmar nada sobre hilos ni sobre sustitución segura de un `Resource` en caliente.
- **NOT SOURCEABLE** — la capa de idioma y los marcadores `{vera}` frente al soporte de traducción del motor (`TranslationServer`, `tr()`), citado nunca por el GDD pero necesario para la decisión del ADR (OQ 5/7).
- **NOT SOURCEABLE** — «recarga en caliente solo en desarrollo, inexistente en el export» (AC-21) y el escaneo de literales de texto de nodos `Label`/`RichTextLabel`/`Button` (regla 6).
- **NOT SOURCEABLE** — tipografía que cubra `¿ ¡ « » ñ …` es un requisito del art bible, sin respaldo de motor.

Estos huecos afectan a la verificación de implementabilidad de las reglas 6, 7 y 19: no bloquean el GDD, pero el ADR de la OQ 1/5/7 debe resolverlos con fuente antes de la fase de arquitectura. Hasta entonces la implementabilidad de esas reglas figura como **NOT ASSESSED**, sin afectar al veredicto de diseño.

## Preguntas para el usuario

Solo una afecta al alcance:

1. **Remitente y cuerpo de los dos correos de ruido (X1, X2) y otros textos de relleno** (hallazgo 5). El slice solo da asunto; son contenido nuevo no aprobado. ¿Los redacta el writer dentro del lote (se registra como v0.4 del slice o solo en datos) o se reducen a asunto + remitente genérico sin cuerpo legible? Por defecto asumo redacción mínima en datos, sin cambiar el slice.

El resto (hallazgos 1 a 11) se decide con la recomendación propia y se registra en «Decisiones tomadas» del GDD; en concreto, el GDD carece de esa sección y debería añadirla al aplicar la revisión.

## Cambios requeridos en otros GDDs

Aplicada la ronda 2 al GDD 18 (2026-11-09). Pendiente en otros documentos (no se tocan desde aquí):

- **Slice** (líneas ~136 y ~724, B.1 P1 N1): «gesto de cámara» pasa a «resaltado de la impresión»; B.1 y §10: orden de presentación 3, X1, 1, 4, X2, 2 (anotar; X1/X2 solo en datos).
- **GDD 9 (marco de puzles):** las claves `PISTA_*` con texto son 8 (no 17): `PISTA_P1_N2`, `P2_N1`, `P4_N1`, `P4_N3`, `P5_N1`, `P5_N2`, `P6_N1`, `P6_N2`; las pistas no textuales no llevan clave (reglas 25 y 29, D9-14, OQ 1). Efecto P1 N1 = HIGHLIGHT, sin `CAMERA_NUDGE`. Dependencia del 18: dura en validación, blanda en ejecución.
- **GDD 17 y fila 17 del índice:** retitular («3 niveles; P6 dos») y usar solo las 8 claves; los efectos sin clave viven en los datos del puzle.
- **GDD 2 y GDD 7:** P1 N1 es un resaltado; ningún evento mueve la cámara.
- **GDD 1, 2, 4, 5, 6 e índice (fila 18 y filas 1, 2, 4, 5, 6, 9):** listar 18 como dependencia blanda (`UI_…`). GDD 6 OQ 11 y GDD 4 OQ 8 quedan cerradas (mensaje de fallo de carga: regla 21 del 18, texto de emergencia fuera del catálogo).
- **Registro (`entities.yaml`):** candidatos `mail_send_times`, `hint_key_count` (= 8 claves con texto) y `mail_presentation_order`.
- **Índice:** estado del 18 → «Revisado (ronda 2) — pendiente de re-review».
