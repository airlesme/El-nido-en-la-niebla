# Ordenador, correo e impresora (sistema 19)

> **Status**: Borrador (lote Feature 1) — pendiente de review
> **Author**: ux-designer (lote autónomo, sin aprobación por archivo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el jugador decide qué buscar y qué leer) · Información incompleta (hechos de los correos fijos y comprobables) · Tensión sin castigo (nada falla; la impresión es repetible)
> **Fuente de verdad del slice**: `design/slice/slice-v0.3.md` (§10.1, V01, V08, B.1, C.2, D.1, D.2)

Convenciones: `‡` = propuesta que debe confirmar el GDD del sistema afectado; `†` = valor propuesto, a validar en playtest. Identificadores de código en inglés; IDs del slice (`V01`, `V08`, `I-01`, `MAIL_1`…) tal cual.

---

## Summary

El ordenador del despacho (`V01`) es una pantalla de correo con un buscador sobre el archivo de correo de la unidad. Al buscar «transición» aparecen los seis correos del periodo en un orden de presentación fijo que no revela la solución; ese hallazgo escribe `correos_leidos` y habilita la impresora (`V08`), que imprime `I-01`, la hoja con los correos y sus horas de envío, de forma repetible e ilimitada. Este sistema no contiene ninguna regla de puzle: el Puzle 1 (9) usa la hoja como material.

## Overview

19 es dueño de tres objetos del despacho: la **pantalla** de `V01` (estados `apagado` → `sesión abierta`), la **lista y el lector de correos** (seis correos de 18, con día, hora, remitente, asunto y cuerpo) y la **impresora** `V08` (`lista`, `imprimiendo`, `sin_resultados`). Interacción (7) abre y cierra el modo `ordenador` (cámara, contexto, `atrás`); 19 es el receptor de la vista: dibuja la pantalla, interpreta el cursor y `seleccionar`, gestiona el campo de búsqueda (con teclado en pantalla para el mando, que cierra la laguna abierta en Entrada) y pide a 20 que entregue `I-01` al bolsillo. Lo único que escribe en el estado (3) es `correos_leidos`; `I-01` no se conserva entre sesiones. Es la puerta de entrada de la escena 2 y de la cadena `correos_leidos` → P1 → `archivo_abierto`.

## Player Fantasy

Vera, sola en el despacho, escribe una palabra que ha oído a medias («el archivo de transición») y la máquina le devuelve, sin comentario, una semana de correos que no cuadran. El jugador siente que **encuentra** algo en un sistema ordinario, no que se lo enseñan: el correo no explica, solo tiene horas. El zumbido de la impresora al fondo, lejos de la pantalla, y el papel caliente en la mano convierten el dato en objeto. Ningún mensaje del sistema dice «bien hecho» ni «te falta algo» (Pilar 3; anti-pilar «historia explicada»).

---

## Detailed Rules

### A. Alcance y propiedad

R1. **Qué posee 19:** el contenido y el comportamiento de la pantalla de `V01`, el buscador, la lista de resultados y el lector de correo, el estado y el manejador de `V08`, la composición de `I-01`, y el hecho `correos_leidos` (único hecho que escribe). **Qué no posee:** abrir/cerrar el modo `ordenador`, la cámara y el contexto (7, regla 24); los textos y datos de los correos (18); el bolsillo, la entrega y la pantalla de lectura de `I-01` (20); el Puzle 1, sus huecos y `archivo_abierto` (9); las pistas (17); los gestos (2).

R2. **Un solo ordenador, un solo buscador.** El slice no tiene otro terminal. 19 no implementa contraseñas, ventanas múltiples, escritorio ni otras aplicaciones.

### B. Apertura, estados y cierre

R3. **Abrir.** `V01` tiene el verbo «Abrir» (7, regla 24 y tabla de objetos: `ABRIR_ORDENADOR`, siempre disponible). 7 pide el contexto `ordenador` a Entrada y `ceder_camara("interaccion:ordenador", …)` al Jugador y, cuando la cámara llega (`camara_cedida`), llama a `on_open()` del receptor de 19. No hay animación de sentarse. Hasta `on_open()` 19 no recibe puntero.

R4. **Estados de `V01`.** `apagado` → `sesión abierta`, de un solo sentido y sin contraseña. En la primera apertura la pantalla pasa de negro a la bandeja en `t_encendido` (0,3 s†; con `reducir_movimiento` de 6: fundido fijo de 100 ms, sin barrido). Desde entonces `sesión abierta` se mantiene el resto de la partida; al cargar una partida, `V01` vuelve a `apagado` (el estado de la pantalla no se guarda, no es un hecho).

R5. **Pantalla inicial (bandeja).** Tras abrir sesión se muestra una vista con tres zonas: (a) campo de búsqueda con la etiqueta `UI_MAIL_BUSCAR` («Buscar en el archivo de correo»), (b) la lista (vacía al principio, con el texto `UI_MAIL_VACIO`), (c) el panel de lectura (vacío). **Recibidos** no existe como carpeta: Vera es nueva en la unidad y el archivo solo se explora buscando (decisión D19-3). La pantalla no ofrece ninguna pista del término de búsqueda (la voz interior `VO_V_01` ya menciona el «archivo de transición»; el término lo aporta el jugador, Pilar 3).

R6. **Foco inicial.** Al abrir, el campo de búsqueda recibe el foco con el cursor visible sobre la pantalla. Con ratón y teclado se escribe directamente; con mando se aplica la regla 16 (teclado en pantalla). El foco puede perderse haciendo `seleccionar` fuera del campo y recuperarse haciéndolo sobre él.

R7. **Cerrar.** El jugador cierra con `atrás` (clic derecho / botón este / la asignación de `atrás`; Entrada regla 20 y 7, regla 23), nunca con `Retroceso` ni con `Esc` (que es `pausa`). Al cerrar, 7 envía `cancelación` de cualquier gesto, `on_close(motivo)` con `motivo ∈ {jugador, sistema}` y devuelve la cámara. En `on_close` 19: (1) saca el foco del campo y oculta el teclado en pantalla, (2) pide `reposo()` al Jugador (fin de `HAND_TYPE`), (3) conserva en memoria la consulta y la lista abierta, sin guardarlas (se reabre como se dejó durante la sesión), (4) **no interrumpe** una impresión en curso (R25). Con `motivo = sistema` (director de escenas 21, p. ej. antes del apagón) el comportamiento es idéntico; no hay mensaje.

R8. **Siempre se puede salir.** 19 no puede bloquear `atrás`. Con una consulta a medias o un teclado abierto, `atrás` cierra el ordenador (no «cierra el teclado» primero): el teclado en pantalla es parte de la vista.

R9. **Pausa.** La pausa no cierra el ordenador (Entrada regla 8). 19 no mide tiempo real salvo los temporizadores de R12 y R25, que usan tiempo de juego y se detienen en pausa.

### C. Buscador y resultados

R10. **Campo de búsqueda.** Un solo campo de una línea, máximo `long_consulta_max` (32† caracteres). Mientras tiene el foco consume las teclas imprimibles, `Retroceso`, `Supr`, flechas e `Intro` antes que cualquier acción (Entrada, regla 20). `Intro` o el botón «Buscar» (`UI_MAIL_BUSCAR_BTN`) lanzan la búsqueda. No hay búsqueda al teclear (evita resultados parciales que se activen sin querer).

R11. **Coincidencia (F1).** La consulta y las etiquetas se normalizan (minúsculas, sin tildes ni signos, espacios recortados). Hay coincidencia con un correo cuando la consulta normalizada es **igual** a una de sus etiquetas (18, regla 13: «transición» en los cuatro numerados) y tiene ≥ `long_consulta_min` (3†) caracteres. Así «Transicion», «TRANSICIÓN» y «transición » valen. No se busca en remitente, asunto ni cuerpo (decisión D19-4).

R12. **Respuesta de la búsqueda.** Con coincidencia, los resultados aparecen `t_busqueda` (0,4 s†) después de lanzarla, con un indicador de espera de la propia pantalla (cursor de carga; sin sonido). Sin coincidencia aparece `UI_MAIL_SIN_RESULTADOS` («Sin resultados»), sin sonido de error, sin contador ni cuenta de intentos, y el jugador puede buscar de nuevo ilimitadamente.

R13. **Lista de resultados.** Con coincidencia se muestran **los seis correos** del periodo en el **orden de presentación** de 18 (regla 12): `MAIL_3`, `MAIL_X1`, `MAIL_1`, `MAIL_4`, `MAIL_X2`, `MAIL_2`. Cada fila lleva remitente, asunto, día y hora de envío. Las filas con la etiqueta buscada llevan la marca «Coincide: …» (`UI_MAIL_COINCIDE`, texto con icono; nunca solo color) y las dos sin etiqueta no. El orden es el mismo en pantalla e impresión y nunca se reordena por hora, remitente ni a petición del jugador (no hay botones de orden, para no regalar la solución; decisión D19-5). La pantalla no muestra las referencias 1 a 4: viven en la hoja (R20).

R14. **Lector.** `seleccionar` sobre una fila abre el correo en el panel de lectura: remitente, asunto, «Lunes · 11:40» y cuerpo (todo de 18, con marcadores de nombre resueltos). Un correo abierto no escribe ningún hecho. Se puede abrir cualquiera, en cualquier orden, repetidamente.

R15. **`correos_leidos`.** 19 escribe `correos_leidos = verdadero` (3) en el mismo fotograma en que se muestra el primer resultado (R12), una sola vez y sin vuelta atrás (C.2 del slice). En el mismo fotograma habilita el botón «Imprimir» de la pantalla (R21). No hay aviso de pantalla: la lista que aparece es el único feedback.

### D. Mando y accesibilidad de entrada

R16. **Teclado en pantalla (cierra la Open Question 1 de Entrada).** Si el dispositivo activo es mando (Entrada), el campo de búsqueda muestra un teclado en pantalla anclado bajo él, operado **con el mismo cursor** de los sticks y `seleccionar` (sin acciones nuevas de Entrada). Teclas: a-z, `ñ`, los signos `´` (la tecla acentúa la vocal siguiente) y `-`, `Espacio`, `Borrar`, `Buscar`. Por ser la búsqueda insensible a tildes (R11), **no hace falta** teclear acentos para encontrar «transición»; la tecla `´` existe solo por fidelidad al texto visible. Con ratón y teclado el teclado en pantalla no se muestra, pero se puede invocar con el botón «Teclado» (`UI_MAIL_TECLADO`) de la pantalla para quien lo prefiera. Cada tecla mide ≥ `tecla_px` (56 px† a 1080p, ≥ `pick_min_px` de 7) con separación `tecla_sep_px` (8 px†).

R17. **Sin dependencia del color ni del sonido.** Todo estado se codifica con forma o texto: foco del campo (borde grueso + cursor de texto), fila seleccionada (marca ▶ + fondo), coincidencia (texto), botón deshabilitado (texto atenuado + sin relieve + el lector de pantalla lo anuncia como «no disponible»). Contraste mínimo texto/fondo 4,5:1 (7:1 para el cuerpo de correo). El sonido de teclado (`SFX_KEY`) es accesorio.

R18. **Tamaño y escala.** La cámara del modo `ordenador` debe dejar la pantalla ocupando ≥ `pantalla_min_px` (1280 px† de ancho lógico a 1080p) para que el texto sea legible sin zoom ‡. Tamaño mínimo de texto: 24 px† a 1080p (cuerpo de correo 28 px†). La UI se dibuja a resolución lógica de 1920 × 1080 y escala con el viewport (slice §21) sin recortar el teclado en pantalla ni el panel de lectura en 16:9 y 16:10.

R19. **Gesto de manos.** Mientras se teclea (caracteres desde teclado o teclas del teclado en pantalla) 19 pide a 2 `reproducir_gesto('HAND_TYPE')` (bucle). Termina con `reposo()` tras `t_tipeo_inactivo` (1,0 s† sin caracteres) o en `on_close`. Un rechazo del Jugador no impide escribir (el gesto es decorativo).

### E. La impresión (`I-01`) y la impresora (`V08`)

R20. **Contenido de `I-01` (slice B.1).** Composición a partir de los registros de los seis correos de 18 (regla 11), en el orden de presentación (R13): por cada correo, un bloque con **Ref.** (`1`–`4`, o «—» en los dos de ruido), **día**, **cuerpo** (con las firmas de los marcadores de nombre) y **pie** «Enviado: hh:mm». El pie global «Ordena por hora de envío» figura en la hoja según B.1 (ver Pregunta abierta PA-1). El documento es `DOC_I01` ‡ (documento de tipo «impresión» y estilo `impreso`, 18 regla 1) y el ítem es `I-01` (D.1). Si el dato de un correo cambia en 18, la hoja lo refleja sin más ediciones (18, AC-11).

R21. **Dos puntos de entrada, un solo trabajo.** (a) El botón «Imprimir» de la pantalla (`UI_MAIL_IMPRIMIR`, habilitado desde R15, deshabilitado y con texto atenuado antes) **envía el trabajo** a `V08`. (b) La interacción directa con `V08` (verbo «Imprimir»; 7, tabla de objetos) lo ejecuta en el sitio. Ambos usan la misma máquina de estados de `V08` (R22). Con (a), la impresora arranca a distancia (se oye, 3,9 m† de la pantalla) y la hoja queda en la bandeja; con (b) se imprime y se recoge en un paso.

R22. **Estados de `V08`.** `sin_resultados` (inicial, `correos_leidos` falso) → `lista` (al escribirse `correos_leidos`) ⇄ `imprimiendo` (`t_impresion` = 1,5 s, slice V08; `SFX_PRINTER`). Además, `V08` lleva el indicador interno `hoja_en_bandeja` (bool, de sesión, no es hecho ni estado público del slice). Tabla de la interacción directa (7, regla 8 de disponibilidad; verbo mostrado: «Imprimir», o «Recoger» con `hoja_en_bandeja`, etiqueta dinámica como `V06`):

| Estado de `V08` | `hoja_en_bandeja` | Efecto de `interact()` | Respuesta de 7 |
|---|---|---|---|
| `sin_resultados` | — | Ninguno; texto `OBJ_V08_SIN_RESULTADOS` («No hay nada que imprimir») | `SIN_EFECTO` + `HAND_REACH` |
| `lista` | falso | Pasa a `imprimiendo`; a los 1,5 s la hoja se entrega (R23) | `SI` + `HAND_REACH` |
| `lista` | verdadero | Entrega la hoja (R23) sin esperar | `SI` + `HAND_REACH` |
| `imprimiendo` | — | Ninguno | `NO` (oculto) |

R23. **Entrega.** Al terminar `imprimiendo` por (b), o al interactuar con `V08` en `lista` con `hoja_en_bandeja`, 19 pide a 20 `entregar_item('I-01')` ‡. Si 20 ya lo tiene (`has_item('I-01')` verdadero), **no se duplica** y el pie de objeto dice `OBJ_V08_YA_IMPRESA` («Ya tienes una copia»); la hoja se retira igualmente de la bandeja. Si no lo tiene, `I-01` entra en el bolsillo, el prop de la hoja desaparece de la bandeja con `HAND_REACH`, y 20 puede mostrar la hoja en su lectura (`abrir_lectura`, 20) cuando el jugador la abra desde el bolsillo. 19 nunca abre la lectura por su cuenta.

R24. **Repetible e ilimitada (9, regla 34).** Imprimir no se agota, no tiene coste ni límite, y funciona igual tras cargar una partida con `correos_leidos` verdadero (en ese caso `V08` nace en `lista`, `hoja_en_bandeja` falso, e `I-01` no está en el bolsillo; 9, AC-39b). El trabajo enviado desde la pantalla con la hoja ya en bandeja no genera una segunda hoja (idempotente).

R25. **Impresión durante el cierre.** Cerrar el ordenador no cancela un trabajo ya enviado: `V08` termina `imprimiendo` y deja `hoja_en_bandeja` verdadero. La hoja no desaparece por salir de la sala, cambiar de escena ni abrir la pausa.

R26. **La pista de nivel 1 del P1 (9, regla 25 y edge case de `needs_items`).** Mientras falte `I-01`, el marco resalta `V08` (`targets_if_missing_items`). 19 solo debe exponer a `V08` como objetivo resaltable por ID; no gestiona pistas.

### F. Relación con el Puzle 1

R27. **9 es dueño de sus hechos.** 19 no escribe `archivo_abierto`, no conoce la solución `2 · 1 · 3 · 4` y no valida la vista del panel `C05`. La vista de `C05` (9) lee las referencias de `I-01` a través de 20; sin `I-01` el marco muestra los elementos sin material (9, regla 7 y AC-39). Que `correos_leidos` habilite imprimir pero no resuelva nada cumple la ficha del slice (B.1).

R28. **Las referencias del P1 nacen vacías** (9, reglas 8 y 22: el estado en memoria de las piezas no persistidas empieza siempre vacío). 19 no guarda en ningún sitio qué referencia puso el jugador: la hoja es la misma siempre; las referencias colocadas en `H1`–`H4` son estado de 9.

### G. Qué no hace 19

R29. 19 no muestra medidores, contadores de intentos, avisos de «correo importante», marcas de leído/no leído que sugieran qué es relevante, ni valoraciones de ningún correo (anti-pilares: sin medidores de moral; sin historia explicada). No añade correos nuevos a los seis (Pilar 5: hechos observables fijos).

---

## Formulas

### F1 · Coincidencia de búsqueda

`norm(s) = recortar(minusculas(sin_tildes(quitar_signos(s))))`
`coincide(c, e) = (len(norm(c)) ≥ long_consulta_min) ∧ (norm(c) = norm(e))`
`hay_resultados(c) = ∃ correo : ∃ e ∈ correo.etiquetas : coincide(c, e)`

| Variable | Rango | Origen |
|---|---|---|
| `c` | cadena, 0 a `long_consulta_max` (32†) | campo de búsqueda |
| `e` | etiqueta de un correo («transición») | 18, regla 13 |
| `long_consulta_min` | entero, 3† (safe 1–6) | Tuning |

Ejemplos: `c = "Transicion "` → `norm = "transicion"` = `norm("transición")` → coincide. `c = "trans"` → no coincide (no hay prefijos; evita que el jugador dude entre variantes). `c = "tr"` → longitud 2 < 3: no coincide. Salida: `{seis correos}` (R13) si `hay_resultados`; si no, vacío.

### F2 · Latencia de búsqueda

`t_resultados = t_lanzamiento + t_busqueda`, con `t_busqueda` = 0,4 s (slice C.2). Si el contexto cambia (pausa) el contador se detiene. `reducir_movimiento` no lo altera (es lógica, no animación). Ejemplo: lanzada en t = 10,0 s → resultados y `correos_leidos` en t = 10,4 s.

### F3 · Duración de la impresión

`t_impresion = 1,5 s` (slice V08). Tras `t_impresion`: `hoja_en_bandeja = verdadero`. Por (b) se entrega en el mismo fotograma (R23). Con `reducir_sobresaltos` no cambia (es sonido de ambiente bajo, no un susto; ver Tuning). Ejemplo: enviar desde pantalla en t = 20,0 s → hoja en bandeja en t = 21,5 s; si el jugador llega a `V08` en t = 28 s, «Recoger» entrega al instante.

### F4 · Composición y tamaño de la hoja `I-01`

`bloques = 6`; `líneas_por_bloque = 4` (Ref./día, cuerpo, pie, separación); `líneas_totales = 6 × 4 + pie_global (1) + cabecera (1) = 26`. A 24 px de texto mínimo y 1080p, el cuerpo cabe en una página de lectura de 20 si la vista admite ≥ 26 × 32 px = 832 px de alto (≤ 1080 − márgenes). Si 20 usara un tamaño menor, la hoja se paginaría por bloque (nunca partiendo un correo).

### F5 · Teclado en pantalla

Disposición: 10 teclas por fila × 3 filas + fila inferior (Espacio, `´`, `-`, Borrar, Buscar). Ancho de fila = `10 × tecla_px + 9 × tecla_sep_px = 10×56 + 9×8 = 632 px`; alto = `4 × 56 + 3 × 8 = 248 px`. Debe caber en el 60 % inferior de la pantalla (≥ 1280 × 720 px): 632 ≤ 1280 y 248 ≤ 0,6 × 720 = 432 (cumple con 184 px de holgura). Cada tecla ≥ `pick_min_px` (44†, 7).

---

## Edge Cases

- **Si el jugador abre el ordenador con la impresora imprimiendo (trabajo anterior):** nada cambia en la pantalla; el botón «Imprimir» queda deshabilitado (texto atenuado) hasta que `V08` vuelva a `lista`.
- **Si pulsa «Imprimir» con la hoja ya en bandeja:** no hace nada nuevo; muestra `UI_MAIL_YA_ENVIADO` («Trabajo ya enviado») en la pantalla y no genera segunda hoja (R24).
- **Si pulsa «Imprimir» dos veces seguidas durante `imprimiendo`:** la segunda se ignora (el botón ya está deshabilitado); un solo trabajo.
- **Si busca una palabra sin resultados cinco veces seguidas:** siempre `UI_MAIL_SIN_RESULTADOS`; ningún contador ni pista automática de 19 (las pistas son de 17).
- **Si busca «transición» con el campo vacío o con espacios:** longitud < 3 tras normalizar → no coincide; no hay mensaje de error propio, solo «Sin resultados».
- **Si busca varias veces «transición» tras ya tener resultados:** la lista se repite sin cambio y `correos_leidos` (ya verdadero) no se reescribe ni se emite aviso.
- **Si el jugador cierra con `atrás` durante la espera de 0,4 s:** `on_close` cancela la búsqueda pendiente; no aparece lista ni se escribe `correos_leidos`. Al reabrir, el campo conserva el texto y puede lanzarla de nuevo.
- **Si el director (21) cierra el ordenador con `on_close(sistema)` durante la espera:** igual que arriba; si la lista ya estaba mostrada, `correos_leidos` ya estaba escrito.
- **Si el jugador carga una partida con `correos_leidos` verdadero:** `V01` empieza `apagado`, la lista está vacía (la consulta no se guarda), `V08` nace en `lista` sin hoja en bandeja y sin `I-01` en el bolsillo; el jugador puede imprimir directamente en `V08` sin volver a buscar (9, regla 34) o volver a buscar (no cambia nada).
- **Si el jugador pierde `I-01` por cargar y no recuerda dónde imprimir:** la pista de nivel 1 resalta `V08` (R26); 19 no añade ayuda propia.
- **Si el mando está activo y el jugador cambia a teclado a mitad de una consulta:** el teclado en pantalla se oculta, el texto escrito se conserva y el foco del campo se mantiene.
- **Si el jugador cambia a mando con texto escrito:** el teclado aparece; el texto se conserva.
- **Si se escribe un carácter fuera del alfabeto previsto (emoji, símbolo):** el campo lo acepta hasta `long_consulta_max` y `norm` lo elimina; no hay error.
- **Si el jugador reasigna `atrás` o `interactuar` a una tecla imprimible:** esa tecla escribe mientras el campo tiene foco (Entrada, regla 20). `atrás` conserva su asignación no imprimible, por lo que R8 se cumple.
- **Si se abre la pausa con el teclado en pantalla abierto:** al reanudar vuelve al mismo estado (foco, texto, tecla bajo el cursor).
- **Si `pantalla_min_px` no se alcanza (resolución distinta de 16:9):** 19 reduce el panel de lectura antes que el texto (nunca por debajo de 24 px); si no cabe el teclado, se desplaza el panel hacia arriba (scroll vertical con `mover_cursor` en el borde).
- **Si un correo de 18 falta o su `hora` es ilegible:** 19 muestra «Texto no encontrado» (18, caso de texto no encontrado), registra el error y la hoja `I-01` omite el bloque con «—»; el juego no se bloquea. El verificador de 18 debería haberlo evitado.
- **Si el Jugador rechaza `HAND_REACH` al interactuar con `V08`:** 7 no llama a `interact()` (7, D7-34); no se imprime ni entrega.
- **Si `V08` está en `imprimiendo` y se guarda la partida:** el guardado no guarda `imprimiendo` ni `hoja_en_bandeja`; al cargar, estado según R24.

---

## Dependencies

Dependencias recíprocas con regla o AC citado de la otra parte. `‡` = la contraparte aún no existe o debe confirmar.

| Sistema | Tipo | Qué usa 19 / qué recibe | Regla / AC en la contraparte |
|---|---|---|---|
| 1 Entrada y controles | Dura | Cursor, `seleccionar`, texto, `atrás`, `pausa` en `ordenador`; dispositivo activo | Regla 20 (texto en el ordenador), regla 8 (transiciones), regla 17 (`pausa`), AC-12, Open Question 1 (teclado en pantalla); el AC-20 que se cita en esa pregunta no existe aún |
| 2 Jugador en primera persona | Blanda | `reproducir_gesto('HAND_TYPE')`, `reposo()` | Tabla de gestos (`HAND_TYPE`, derecha, bucle); regla 18 (cesión de cámara) |
| 3 Estado y bus | Dura | Escribe `correos_leidos`; lee ese hecho al cargar | Tabla de hechos (`correos_leidos`, 19 ‡) y dependencias («19 escribe `correos_leidos`») |
| 4 Escena de planta | Dura | Anclaje de la pantalla `V01`, posición de `V08`, prop de hoja en la bandeja, distancia 3,9 m† | `V01` y `V08` (slice §Despacho); anclajes de las vistas (4 → 7) |
| 6 Ajustes persistentes | Blanda | `reducir_movimiento` (fundido de 100 ms), `reducir_sobresaltos` (sin efecto, R21/F3) | Catálogo de ajustes (regla 1); nota de 26/30 sobre más ajustes |
| 7 Interacción e inspección | Dura | Modo `ordenador`, `ViewReceiver` (`registrar_receptor`, `elements()`, `handle_pointer`, `on_open`, `on_close(motivo)`), `pick_min_px`, manejador de `V01` y `V08` | Reglas 20 (PointerEvent), 22 (tamaños), 23 (cierre), 24 (ordenador); tabla de objetos (`V01`, `V08`); D7-34 |
| 9 Marco de puzles | Indirecta | Lee `correos_leidos` (`requires` del P1), `needs_items: ['I-01']`, `has_item`, pista de nivel 1 sobre `V08` | Reglas 7, 34 y 35; AC-39 y AC-39b; D9-33; matriz de encaje (P1) |
| 17 Sistema de pistas | Blanda | Expone `V08` como objetivo resaltable; capa del pie de la hoja (PA-1) | Pistas del P1 (slice 10.1, B.1) ‡ |
| 18 Base de contenido | Dura | Seis correos con día, hora, remitente, asunto, cuerpo, etiquetas y orden de presentación; claves `UI_MAIL_*`, `OBJ_V08_*`, `MAIL_1`–`MAIL_4`, `MAIL_X1`, `MAIL_X2` | Reglas 3, 8, 11, 12, 13, 17; AC-11; filas «19» de las tablas de dependencias |
| 20 Documentos y bolsillo | Dura | `entregar_item('I-01')`, `has_item`, documento `DOC_I01`, lectura de la hoja | `has_item`, `abrir_lectura`; «I-01 no persistente» (índice) ‡ |
| 21 Director de escenas | Blanda | Pide `cerrar_modos()` → `on_close(sistema)` | `cerrar_modos()` de 7 (regla 27a) y «modos cerrados»; 21 aún sin GDD ‡ |
| 26 Subtítulos | Ninguna | 19 no genera voz; los sonidos de la impresora llevan subtítulo no verbal si 26 lo decide | — |
| 23 Audio | Blanda | `SFX_PRINTER`, `SFX_KEY`, `SFX_CLICK_SUBTLE` | Catálogo de efectos ‡ |
| 25 Pausa / 30 Accesibilidad | Blanda | Pantalla de opciones (escala de texto, PA-3) | ‡ |

---

## Tuning Knobs

| Parámetro | Valor | Rango seguro | Afecta a | Fuente / razón |
|---|---|---|---|---|
| `t_encendido` | 0,3 s† | 0–0,6 s | Sensación de encendido de la pantalla | Pilar 2 (sensorial); 100 ms fijos con `reducir_movimiento` |
| `t_busqueda` | 0,4 s | 0,2–0,8 s | Latencia percibida del buscador | Slice C.2 |
| `t_impresion` | 1,5 s | 1,0–2,5 s | Sensación de máquina, no de espera | Slice V08 |
| `long_consulta_min` | 3 | 1–6 | Ruido en búsquedas cortas | F1 |
| `long_consulta_max` | 32 | 16–64 | Tamaño del campo | R10 |
| `t_tipeo_inactivo` | 1,0 s† | 0,5–2,0 s | Fin del gesto `HAND_TYPE` | R19 |
| `tecla_px` | 56 px† | 44–72 | Precisión motriz con mando (`pick_min_px` 44) | F5 |
| `tecla_sep_px` | 8 px† | 4–16 | Errores de pulsación | F5 |
| `texto_min_px` | 24 px† | 20–32 | Legibilidad (cuerpo 28†) | R18 |
| `pantalla_min_px` | 1280 px† | 960–1600 | Encuadre de la cámara de 7 | R18 |
| `contraste_min` | 4,5:1 (7:1 cuerpo) | ≥ 4,5 | Accesibilidad visual | R17 |
| `pie_ordena_visible` (dato) | verdadero | bool | Si la hoja lleva «Ordena por hora de envío» | PA-1; B.1 del slice |
| Orden de presentación | 3, X1, 1, 4, X2, 2 | fijo | No revelar la solución | 18 regla 12; no es un knob de juego |

Todos los valores son datos (`assets/data/`), no constantes en código.

---

## Acceptance Criteria

Tipos: **L** = lógica (test automático), **I** = integración, **PV** = playtest/visual con captura en `production/qa/evidence/`.

- **AC-01 (R11, F1, L)**: **GIVEN** la consulta «transición», «Transicion», «TRANSICIÓN » o «transición», **WHEN** se lanza, **THEN** `hay_resultados` es verdadero; con «trans», «tr», «» o «mantenimiento», es falso.
- **AC-02 (R12, F2, L)**: **GIVEN** una consulta con coincidencia, **WHEN** pasan 0,4 s de tiempo de juego, **THEN** se muestra la lista; **GIVEN** la pausa abierta durante la espera, **THEN** el contador se detiene.
- **AC-03 (R13, L)**: **GIVEN** una búsqueda con coincidencia, **THEN** la lista contiene exactamente 6 filas en el orden `MAIL_3`, `MAIL_X1`, `MAIL_1`, `MAIL_4`, `MAIL_X2`, `MAIL_2`; las filas `MAIL_1`–`MAIL_4` llevan `UI_MAIL_COINCIDE` y `MAIL_X1`/`MAIL_X2` no; no existe control de ordenación.
- **AC-04 (R15, I)**: **GIVEN** `correos_leidos` falso, **WHEN** se muestra el primer resultado, **THEN** `correos_leidos` pasa a verdadero en ese mismo fotograma y el botón «Imprimir» pasa a habilitado; **WHEN** se repite la búsqueda, **THEN** no se emite ningún aviso nuevo.
- **AC-05 (R15, L)**: **GIVEN** una búsqueda sin coincidencia, **THEN** no se escribe ningún hecho y se muestra «Sin resultados» sin sonido de error.
- **AC-06 (R14, L)**: **GIVEN** la lista, **WHEN** el jugador abre cada uno de los seis correos en cualquier orden, **THEN** cada panel muestra día, hora, remitente, asunto y cuerpo de 18 y no se escribe ningún hecho.
- **AC-07 (R3, R7, I)**: **GIVEN** exploración, **WHEN** se activa `V01`, **THEN** 7 abre `ordenador`, 19 recibe `on_open()` solo tras `camara_cedida`; **WHEN** `atrás`, **THEN** 19 recibe `on_close(jugador)` antes de la devolución de la cámara y el campo pierde el foco.
- **AC-08 (R7, R25, I)**: **GIVEN** un trabajo de impresión enviado, **WHEN** el jugador cierra el ordenador, **THEN** `V08` termina `imprimiendo` y `hoja_en_bandeja` es verdadero.
- **AC-09 (R8, I)**: **GIVEN** el teclado en pantalla abierto y texto escrito, **WHEN** `atrás`, **THEN** el ordenador se cierra; **GIVEN** `Retroceso` con foco en el campo, **THEN** borra un carácter y no cierra; **GIVEN** `Esc`, **THEN** abre la pausa y no cancela el texto.
- **AC-10 (R16, I + PV)**: **GIVEN** un mando conectado y el campo enfocado, **THEN** se muestra el teclado en pantalla; **WHEN** el jugador compone «transicion» solo con sticks y `seleccionar` y pulsa `Buscar`, **THEN** aparecen los seis correos; captura del teclado a 1920 × 1080 y a 1920 × 1200 sin recortes.
- **AC-11 (R16, F5, L)**: **GIVEN** la disposición del teclado, **THEN** cada tecla mide ≥ 44 px de lado (`pick_min_px`) y la separación entre teclas es ≥ 8 px a 1080p.
- **AC-12 (R22, L)**: **GIVEN** la tabla de R22, **WHEN** se interactúa con `V08` en cada fila, **THEN** el resultado coincide: `sin_resultados` → `SIN_EFECTO` y `OBJ_V08_SIN_RESULTADOS`; `lista` sin hoja → `imprimiendo` 1,5 s y entrega; `lista` con hoja → entrega inmediata; `imprimiendo` → el objeto no es objetivo.
- **AC-13 (R23, I)**: **GIVEN** `has_item('I-01')` falso, **WHEN** se completa una impresión, **THEN** 20 recibe `entregar_item('I-01')` una vez y `has_item('I-01')` es verdadero; **GIVEN** que ya lo tiene, **THEN** no se duplica y el pie dice `OBJ_V08_YA_IMPRESA`.
- **AC-14 (R21, I)**: **GIVEN** `correos_leidos` verdadero, **WHEN** se pulsa «Imprimir» en la pantalla, **THEN** `V08` pasa a `imprimiendo` durante 1,5 s y `hoja_en_bandeja` queda verdadero; **WHEN** se pulsa de nuevo con la hoja en bandeja, **THEN** no se genera otra y se muestra `UI_MAIL_YA_ENVIADO`.
- **AC-15 (R24, I)**: **GIVEN** una partida cargada con `correos_leidos` verdadero y sin `I-01`, **THEN** `V08` está en `lista`, `V01` en `apagado` y P1 sin material (9, AC-39b); **WHEN** se imprime en `V08`, **THEN** `has_item('I-01')` es verdadero y P1 resoluble; el número de impresiones no tiene tope (30 repeticiones sin cambio de comportamiento).
- **AC-16 (R20, L)**: **GIVEN** los registros de 18, **WHEN** se compone `I-01`, **THEN** tiene 6 bloques en el orden de presentación con Ref. 3, —, 1, 4, —, 2; cada bloque lleva «Enviado: hh:mm» igual a su registro; **WHEN** se cambia la hora de `MAIL_2` en los datos, **THEN** la hoja la refleja sin otra edición (18, AC-11).
- **AC-17 (R20, L)**: **GIVEN** un texto con marcadores de nombre, **WHEN** se compone la hoja, **THEN** ningún bloque contiene un literal de nombre o inicial vigente (18, regla 8).
- **AC-18 (R17, PV)**: **GIVEN** las capturas en escala de grises, **THEN** foco del campo, fila seleccionada, coincidencia y botón deshabilitado siguen distinguiéndose; el contraste del cuerpo es ≥ 7:1.
- **AC-19 (R18, PV)**: **GIVEN** el modo `ordenador` abierto a 1920 × 1080, 1920 × 1200 y 1280 × 720, **THEN** el texto del cuerpo mide ≥ 24 px lógicos efectivos (≥ 28 px en el cuerpo) y la pantalla ocupa ≥ 1280 px lógicos de ancho; captura de cada resolución.
- **AC-20 (R19, I)**: **GIVEN** un jugador tecleando, **THEN** el Jugador reproduce `HAND_TYPE` hasta 1,0 s tras el último carácter o hasta `on_close`; **GIVEN** que el Jugador rechaza el gesto, **THEN** el texto se sigue escribiendo.
- **AC-21 (R4, PV)**: **GIVEN** la primera apertura, **THEN** la pantalla pasa de negro a la bandeja en 0,3 s (o 100 ms fijos con `reducir_movimiento`); captura de ambos casos.
- **AC-22 (R5, R29, PV)**: **GIVEN** la pantalla al abrir y tras buscar, **THEN** no hay carpeta Recibidos, ni contadores, ni marcas de relevancia aparte de «Coincide»; captura.
- **AC-23 (R27, I)**: **GIVEN** `correos_leidos` verdadero y `I-01` en el bolsillo, **WHEN** el jugador abre `C05`, **THEN** 9 ve `has_item('I-01')` verdadero; 19 no escribe `archivo_abierto` en ningún caso.
- **AC-24 (edge, I)**: **GIVEN** una búsqueda en curso, **WHEN** el director cierra el ordenador con `on_close(sistema)`, **THEN** no se escribe `correos_leidos` si la lista no llegó a mostrarse.
- **AC-25 (edge, L)**: **GIVEN** el dispositivo cambia de mando a teclado con texto escrito, **THEN** el texto y el foco se conservan y el teclado en pantalla se oculta.

---

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D19-1 | La impresión de `I-01` se entrega al bolsillo (20) y no se manipula como objeto del mundo | Hoja sostenible con `sostener` en 3D | 20 ya sostiene `A03` y las tarjetas; evita un segundo dueño de la mano (2, D-34) y de la hoja física |
| D19-2 | Dos puntos de entrada (botón de pantalla y `V08`), un solo trabajo y `hoja_en_bandeja` | Solo botón de pantalla (teletransporta la hoja) o solo `V08` (el botón del slice C.2 queda sin sentido) | Respeta C.2 (botón habilitado) y la ficha de `V08` (imprimir en la impresora, 9 regla 34); la hoja es diegética y obliga a caminar al armario |
| D19-3 | Sin carpeta Recibidos; solo buscador sobre el archivo | Bandeja de entrada con los seis correos visibles | La escena 2 y el flag `correos_leidos` exigen un hallazgo por búsqueda (Pilar 3); Vera es nueva y no tiene correo propio |
| D19-4 | Coincidencia por **igualdad con etiqueta** normalizada (sin tildes/mayúsculas), mínimo 3 caracteres | Búsqueda de texto libre en asunto/cuerpo; coincidencia por prefijo | Una búsqueda libre abre caminos que el slice no diseña (p. ej. «Vera») y obliga a decidir qué correos devuelve; el prefijo causa dudas |
| D19-5 | La lista siempre muestra los seis, en el orden de 18, con marca «Coincide» solo en los cuatro; sin ordenación | Mostrar solo los cuatro etiquetados; botones de orden por hora | Respeta C.2 («distractores entre ellos») y 18 regla 13 a la vez; ordenar por hora regalaría la solución (anti-pilar: tutorial que dice la solución) |
| D19-6 | La pantalla muestra remitente, asunto, día y hora; no muestra las referencias 1–4 | Mostrar las referencias en pantalla | El material del P1 es la hoja (`needs_items`); la pantalla da los hechos, la hoja la utilidad |
| D19-7 | Teclado en pantalla con el cursor existente, solo con mando (más botón opcional) | Autocompletado «transición» o botón-atajo; teclado con navegación por D-pad | El autocompletado regala la palabra (Pilar 3); un D-pad requeriría acciones nuevas de Entrada; el cursor ya existe (Entrada, AC-12) |
| D19-8 | La búsqueda es insensible a tildes | Exigir «transición» exacta | Quien teclea sin tilde no debe ser castigado (Pilar 4); además el mando lo ahorra |
| D19-9 | `V01` pasa a `sesión abierta` una vez; al cargar vuelve a `apagado` | Guardar el estado de la pantalla | No es un hecho; guardarlo añade estado sin valor; el coste es 0,3 s de encendido |
| D19-10 | El estado de una búsqueda a medias no se guarda | Guardar consulta y lista | No cambia ningún hecho; la hoja y `correos_leidos` bastan |

---

## Preguntas abiertas

| ID | Pregunta | Quién decide | Por qué |
|---|---|---|---|
| PA-1 | **Pie «Ordena por hora de envío» y letra pequeña de la hora.** El slice B.1 pone en la hoja siempre el pie «Ordena por hora de envío» y «Enviado: hh:mm» en cada correo; las pistas de nivel 2 y 3 del P1 (slice 10.1 y B.1) dicen que ese pie y esa hora **aparecen** con la pista. Ambas lecturas se contradicen: o la hoja ya los lleva (las pistas 2 y 3 son redundantes) o no (B.1 «Contenido de la impresión» sobra). Implementación provisional: **literal de B.1** (`pie_ordena_visible` = verdadero, hora siempre visible). | creative-director / autor del slice con 17 y 9 | Cambia la dificultad del P1 y el reparto de pistas; contradice un texto del slice |
| PA-2 | ¿La pantalla del ordenador debe mostrar la hora de envío (como todo cliente de correo)? Si sí, el P1 es resoluble sin volver a la hoja salvo para las referencias; si no, la hoja es indispensable. Provisional: sí (R13/R14). | game-designer | Afecta a la dificultad del P1 |
| PA-3 | ¿Escala de texto de la pantalla y de las lecturas? El catálogo de 6 no tiene ajuste de tamaño de texto; 19 fija 24 px mínimos. Si se añade `escala_texto_ui`, 19 la aplicaría. | accessibility-specialist / usuario | Alcance del MVP de accesibilidad (slice §14) |

---

## Cambios requeridos en otros GDDs

| GDD | Cambio | Motivo |
|---|---|---|
| 18 Base de contenido | Añadir claves `UI_MAIL_BUSCAR`, `UI_MAIL_BUSCAR_BTN`, `UI_MAIL_VACIO`, `UI_MAIL_SIN_RESULTADOS`, `UI_MAIL_COINCIDE`, `UI_MAIL_IMPRIMIR`, `UI_MAIL_YA_ENVIADO`, `UI_MAIL_TECLADO`, `OBJ_V08_SIN_RESULTADOS`, `OBJ_V08_YA_IMPRESA`, `OBJ_V01`/`OBJ_V08` (etiquetas), `DOC_I01` (documento `impreso`, compuesto, ítem `I-01`) y los asuntos/remitentes de `MAIL_1`–`MAIL_4` | R5, R12, R13, R20, R22, R23 |
| 20 Documentos y bolsillo (por redactar) | API `entregar_item(item_id)`, `has_item(item_id)`, `I-01` no persistente y lectura de `DOC_I01` | R23, R24; 9 regla 34 |
| 7 Interacción e inspección | Fila `V08`: verbo dinámico «Imprimir»/«Recoger» (como `V06`) y disponibilidad según `hoja_en_bandeja`; anclaje de `V01` con `fov_destino` que deje la pantalla ≥ `pantalla_min_px` | R18, R22 |
| 4 Escena de planta | Prop de hoja en bandeja de `V08`; anclaje de cámara de `V01` y sonido de impresora a ≈ 3,9 m | R18, R21 |
| 1 Entrada y controles | Cerrar Open Question 1 con R16; AC-20 puede referirse al AC-10 de 19 | R16 |
| 3 Estado y bus | Confirmar `correos_leidos` con 19 como único escritor | R15 |
| 17 Sistema de pistas | Resolver PA-1; usar `V08` como `targets_if_missing_items` | R26 |
| 6 Ajustes persistentes | (Si se resuelve PA-3) añadir `escala_texto_ui` | R18 |
| `design/ux/` | **UX spec** de la pantalla del ordenador (`design/ux/ordenador-correo.md`): disposición, foco, teclado en pantalla, estados vacío/sin resultados/resultados y legibilidad; la escribe `/ux-design`, no este GDD | Sistema con pantalla y flujo |
| `systems-index.md` | Marcar 19 «Borrador (lote Feature 1)» | Estado |

## Entradas para el registro

- **Hecho:** `correos_leidos` (bool, falso); escritor 19; lectores 19 (habilitar imprimir), 9 (`requires` P1). Ya existe en el GDD de 3.
- **Ítem:** `I-01` (no persistente; origen 19 vía 20).
- **Estados de objeto:** `V01` (`apagado`, `sesión abierta`); `V08` (`sin_resultados`, `lista`, `imprimiendo`; indicador interno `hoja_en_bandeja`).
- **Constantes:** `t_busqueda` 0,4 s; `t_impresion` 1,5 s; `long_consulta_min` 3; `long_consulta_max` 32; `tecla_px` 56; `tecla_sep_px` 8; `texto_min_px` 24; `pantalla_min_px` 1280.
- **Claves de contenido nuevas:** las listadas en «Cambios requeridos» (18).
- **Documento:** `DOC_I01` (impresión de correos, estilo `impreso`, ítem `I-01`).
- **Orden de presentación de correos:** 3, X1, 1, 4, X2, 2 (de 18, regla 12).

## Historial

| Versión | Fecha | Cambios |
|---|---|---|
| 0.1 | 2026-11-09 | Borrador del lote Feature 1 (ux-designer, modo autónomo). Pendiente de review. |
