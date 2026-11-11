# Ordenador, correo e impresora (sistema 19)

> **Status**: Revisado (ronda de corrección 10) — pendiente de re-review (ronda de corrección 8: `ts_envio` en `compose_i01()` para el AC-3 de 11, 11 listado como dependiente, D19-20 y D19-21)
> **Author**: ux-designer (lote autónomo, sin aprobación por archivo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el jugador decide qué buscar y qué leer) · Información incompleta (hechos de los correos fijos y comprobables) · Tensión sin castigo (nada falla; la impresión es repetible)
> **Fuente de verdad del slice**: `design/slice/slice-v0.3.md` (§10.1, V01, V08, B.1, C.2, D.1, D.2)

Convenciones: `‡` = propuesta que debe confirmar el GDD del sistema afectado; `†` = valor propuesto, a validar en playtest. Identificadores de código en inglés; IDs del slice (`V01`, `V08`, `I-01`, `MAIL_1`…) tal cual.

---

## Summary

El ordenador del despacho (`V01`) es una pantalla de correo con un buscador sobre el archivo de correo de la unidad. Al buscar «transición» aparecen los correos del periodo en un orden de presentación fijo que no revela la solución; ese hallazgo escribe `correos_leidos` y habilita la impresión. La impresora (`V08`) imprime `I-01`, la hoja con los correos y las referencias del Puzle 1, de forma repetible e ilimitada. 19 posee el contenido de la hoja (`compose_i01()`); 20 solo guarda que el jugador la tiene; 9 la dibuja en `C05`. Este sistema no contiene ninguna regla de puzle.

## Overview

19 es dueño de tres objetos del despacho: la **pantalla** de `V01` (estados `apagado` → `sesión abierta`), la **lista y el lector de correos** (los correos de 18, con día, hora, remitente, asunto y cuerpo) y la **impresora** `V08` (`lista`, `imprimiendo`, `sin_resultados`). Interacción (7) abre y cierra el modo `ordenador` (cámara, contexto, `atrás`); 19 es el receptor de la vista: dibuja la pantalla, interpreta el cursor y `seleccionar`, gestiona el campo de búsqueda (con teclado en pantalla para el mando, que cierra la laguna abierta en Entrada) y, al terminar la impresión, llama a `otorgar_sesion("I-01")` de 20. Lo único que escribe en el estado (3) es `correos_leidos`; `I-01` no se conserva entre sesiones y su contenido se reconstruye siempre de los datos de 18 (R30). Es la puerta de entrada de la escena 2 y de la cadena `correos_leidos` → P1 → `archivo_abierto`. Las decisiones de alcance aún abiertas (PA-2 en su parte de pantalla y PA-3 a PA-9) están parametrizadas en datos con un valor provisional.

## Player Fantasy

Vera, sola en el despacho, escribe una palabra que ha oído a medias («el archivo de transición») y la máquina le devuelve, sin comentario, una semana de correos que no cuadran. El jugador siente que **encuentra** algo en un sistema ordinario, no que se lo enseñan: el correo no explica, solo tiene horas. El zumbido de la impresora al fondo, lejos de la pantalla, y el papel caliente en la mano convierten el dato en objeto. Ningún mensaje del sistema dice «bien hecho» ni «te falta algo» (Pilar 3; anti-pilar «historia explicada»).

---

## Detailed Rules

### A. Alcance y propiedad

R1. **Qué posee 19:** el contenido y el comportamiento de la pantalla de `V01`, el buscador, la lista de resultados y el lector de correo, el estado y el manejador de `V08`, el **contenido de `I-01`** (`compose_i01()`, R20 y R30) y el hecho `correos_leidos` (único hecho que escribe). **Qué no posee:** abrir/cerrar el modo `ordenador`, la cámara y el contexto (7, regla 24); los textos y datos de los correos (18); el conjunto de sesión del bolsillo y `has_item` (20; `I-01` es Relegible = No); el Puzle 1, la vista `C05` que dibuja la hoja, sus huecos y `archivo_abierto` (9); las pistas (17); los gestos (2).

R2. **Un solo ordenador, un solo buscador.** El slice no tiene otro terminal. 19 no implementa contraseñas, ventanas múltiples, escritorio ni otras aplicaciones.

### B. Apertura, estados y cierre

R3. **Abrir.** `V01` tiene el verbo «Abrir» (7, regla 24 y tabla de objetos: `ABRIR_ORDENADOR`, siempre disponible). 7 pide el contexto `ordenador` a Entrada y `ceder_camara("interaccion:ordenador", …)` al Jugador y, cuando la cámara llega (`camara_cedida`), llama a `on_open()` del receptor de 19. No hay animación de sentarse. Hasta `on_open()` 19 no recibe puntero.

R4. **Estados de `V01`.** `apagado` → `sesión abierta`, de un solo sentido y sin contraseña. En la primera apertura la pantalla pasa de negro a la bandeja en `t_encendido` (0,3 s†; con `reducir_movimiento` de 6: fundido fijo de 100 ms, sin barrido). Desde entonces `sesión abierta` se mantiene el resto de la partida; al cargar una partida, `V01` vuelve a `apagado` (el estado de la pantalla no se guarda, no es un hecho).

R5. **Pantalla inicial (bandeja).** Tras abrir sesión se muestra una vista con tres zonas: (a) campo de búsqueda con la etiqueta `UI_MAIL_BUSCAR` («Buscar en el archivo de correo»), (b) la lista (vacía al principio, con el texto `UI_MAIL_VACIO`), (c) el panel de lectura (vacío). **Recibidos** no existe como carpeta: Vera es nueva en la unidad y el archivo solo se explora buscando (valor provisional, PA-5). La pantalla no ofrece ninguna pista del término de búsqueda (la voz interior `VO_V_01` ya menciona el «archivo de transición»; el término lo aporta el jugador, Pilar 3).

R6. **Foco inicial.** Al abrir, el campo de búsqueda recibe el foco con el cursor visible sobre la pantalla. Con ratón y teclado se escribe directamente; con mando se aplica la regla 16 (teclado en pantalla). El foco puede perderse haciendo `seleccionar` fuera del campo y recuperarse haciéndolo sobre él.

R7. **Cerrar.** El jugador cierra con `atrás` (clic derecho / botón este / la asignación de `atrás`; Entrada regla 20 y 7, regla 23), nunca con `Retroceso` ni con `Esc` (que es `pausa`). Al cerrar, 7 envía `cancelación` de cualquier gesto, `on_close(motivo)` con `motivo ∈ {jugador, sistema}` y devuelve la cámara. En `on_close` 19: (1) saca el foco del campo y oculta el teclado en pantalla, (2) pide `reposo()` al Jugador (fin de `HAND_TYPE`), (3) conserva en memoria la consulta y la lista abierta, sin guardarlas (se reabre como se dejó durante la sesión), (4) **no interrumpe** una impresión en curso (R25). Con `motivo = sistema` (cierre forzado `cerrar_modos()` de 7, regla 27a, que puede pedir el director de escenas 21 antes de una escena dirigida con `sin control`) el comportamiento es idéntico; no hay mensaje. En el slice no hay camino que lo use con el ordenador abierto: 21 solo lo pide en `ESC8_CIERRE`, en Recepción, donde no hay ordenador (21 regla 20), y el apagón (`ESC7_APAGON`) no toma `sin control` ni cierra modos (21 regla 13); es un caso de robustez, no de flujo.

R8. **Siempre se puede salir.** 19 no puede bloquear `atrás`. Con una consulta a medias o un teclado abierto, `atrás` cierra el ordenador (no «cierra el teclado» primero): el teclado en pantalla es parte de la vista.

R9. **Pausa.** La pausa no cierra el ordenador (Entrada regla 8). 19 no mide tiempo real salvo los temporizadores de R12 y R25, que usan tiempo de juego y se detienen en pausa.

### C. Buscador y resultados

R10. **Campo de búsqueda.** Un solo campo de una línea, máximo `long_consulta_max` (32† caracteres). Mientras tiene el foco consume las teclas imprimibles, `Retroceso`, `Supr`, flechas e `Intro` antes que cualquier acción (Entrada, regla 20). `Intro` o el botón «Buscar» (`UI_MAIL_BUSCAR_BTN`) lanzan la búsqueda. No hay búsqueda al teclear (evita resultados parciales que se activen sin querer).

R11. **Coincidencia (F1).** La consulta y las etiquetas se normalizan (minúsculas, sin tildes ni signos, espacios recortados). Hay coincidencia con un correo cuando la consulta normalizada es **igual** a una de sus etiquetas (18, regla 13: «transición» en los cuatro numerados) y tiene ≥ `long_consulta_min` (3†) caracteres. Así «Transicion», «TRANSICIÓN» y «transición » valen. No se busca en remitente, asunto ni cuerpo (decisión D19-4).

R12. **Respuesta de la búsqueda.** Con coincidencia, los resultados aparecen `t_busqueda` (0,4 s, slice C.2) después de lanzarla, con un indicador de espera de la propia pantalla (cursor de carga; sin sonido). Sin coincidencia aparece `UI_MAIL_SIN_RESULTADOS` («Sin resultados»), sin sonido de error, sin contador ni cuenta de intentos, y el jugador puede buscar de nuevo ilimitadamente.

R13. **Lista de resultados.** Con coincidencia se muestran **los seis correos** del periodo (con `resultados_incluyen_ruido` = verdadero; cuatro si es falso, PA-4) en el **orden de presentación** de 18 (regla 12): `MAIL_3`, `MAIL_X1`, `MAIL_1`, `MAIL_4`, `MAIL_X2`, `MAIL_2`. Cada fila (alto `fila_px`) lleva remitente, asunto y día, y la hora de envío si `pantalla_muestra_hora` (PA-2). Las filas con la etiqueta buscada llevan la marca «Coincide: …» (`UI_MAIL_COINCIDE`, texto con icono; nunca solo color) y las sin etiqueta no. El orden es el mismo en pantalla e impresión y no se reordena por hora, remitente ni a petición del jugador: no hay botones de orden (valor provisional, PA-6). La pantalla no muestra las referencias 1 a 4: viven en la hoja (R20).

R14. **Lector.** `seleccionar` sobre una fila abre el correo en el panel de lectura: remitente, asunto, «Lunes · 11:40» y cuerpo (todo de 18, con marcadores de nombre resueltos). Un correo abierto no escribe ningún hecho. Se puede abrir cualquiera, en cualquier orden, repetidamente.

R15. **`correos_leidos`.** 19 escribe `correos_leidos = verdadero` (3) en el mismo fotograma en que se muestra el primer resultado (R12), una sola vez y sin vuelta atrás (C.2 del slice). El botón «Imprimir» sigue a este hecho (R21). No hay aviso de pantalla: la lista que aparece es el único feedback.

### D. Mando y accesibilidad de entrada

R16. **Teclado en pantalla (cierra la Open Question 1 de Entrada).** Si el dispositivo activo es mando (Entrada), el campo de búsqueda muestra un teclado en pantalla anclado bajo él, operado **con el mismo cursor** de los sticks y `seleccionar` (sin acciones nuevas de Entrada). Teclas: a-z, `ñ`, `Espacio`, `Borrar`, `Buscar`; sin teclas de acento ni signos (D19-14: la búsqueda ignora tildes y signos, R11). Disposición: filas de 10, 10 y 7 letras (a-z más `ñ`) y fila inferior `Espacio`, `Borrar`, `Buscar`. Con ratón y teclado el teclado en pantalla no se muestra, pero se puede invocar con el botón «Teclado» (`UI_MAIL_TECLADO`). Cada tecla mide ≥ `tecla_px` (56 px† a 1080p, ≥ `pick_min_px` = 44† de 7) con separación `tecla_sep_px` (8 px†). **Modo teclado (D19-13):** mientras el teclado está visible, el panel de lectura se oculta y la lista muestra al menos `filas_visibles_min` filas completas con scroll (rueda o `mover_cursor` en el borde) para el resto; `seleccionar` sobre una fila saca el foco del campo (R6), oculta el teclado y abre el lector.

R17. **Sin dependencia del color ni del sonido.** Todo estado se codifica con forma o texto: foco del campo (borde grueso + cursor de texto), fila seleccionada (marca ▶ + fondo), coincidencia (texto), botón deshabilitado (texto atenuado + sin relieve + el lector de pantalla lo anuncia como «no disponible»). Contraste mínimo texto/fondo 4,5:1 (7:1 para el cuerpo de correo), según WCAG 2.1 SC 1.4.3 y 1.4.6. El sonido de teclado (`SFX_KEY`) es accesorio.

R18. **Tamaño y escala.** La cámara del modo `ordenador` debe dejar la pantalla ocupando ≥ `pantalla_min_px` (1280 px† lógicos de ancho a 1080p) para que el texto sea legible sin zoom ‡. Tamaño mínimo de texto: 24 px† lógicos a 1080p (cuerpo de correo 28 px†). La **pantalla del ordenador es un overlay del lienzo raíz** alojado en `SceneUi` (ADR-0016 OI-10, H21; no una superficie 3D del mundo ni un `SubViewport`). La UI se dibuja a resolución lógica de 1920 × 1080 y escala con el viewport (slice §21) sin recortar el teclado en pantalla ni el panel de lectura en 16:9 y 16:10. Los píxeles de R16, F5 y los AC son lógicos salvo que se diga «físicos».

R19. **Gesto de manos.** Mientras se teclea (caracteres desde teclado o teclas del teclado en pantalla) 19 pide a 2 `reproducir_gesto('HAND_TYPE')` (bucle). Termina con `reposo()` tras `t_tipeo_inactivo` (1,0 s† sin caracteres) o en `on_close`. Un rechazo del Jugador no impide escribir (el gesto es decorativo).

### E. La impresión (`I-01`) y la impresora (`V08`)

R20. **Contenido de `I-01` (slice B.1): lo posee 19.** `I-01` es una hoja de *datos*, no un documento de 20: 20 solo guarda `has_item('I-01')` (Relegible = No; 20, R1, R8 y R9). 19 la compone con `compose_i01()` (R30) a partir de los registros de 18 (regla 11), en el orden de presentación (R13): por cada correo un bloque con **Ref.** (`1`–`4`, o null en los de ruido), **día**, **cuerpo** (firmas por marcadores de nombre) y **hora de envío** «Enviado: hh:mm»; más cabecera y pie global «Ordena por hora de envío». La visibilidad de la hora por bloque y del pie la fijan los datos `i01_hora_visible` e `i01_pie_ordena_visible` (decididos, D19-16: literal de B.1, ambos verdadero). La hoja no tiene estado: es función pura de los datos de 18 y de esos dos datos (18, AC-11). El pie global es `PISTA_P1_N2` de 18. Las pistas 2 y 3 del P1 no añaden esa información (D19-16); 17 no muestra el pie.

R21. **Dos puntos de entrada, un solo trabajo (provisional, PA-7).** (a) El botón «Imprimir» de la pantalla (`UI_MAIL_IMPRIMIR`) está **habilitado ⇔ `correos_leidos` es verdadero y `V08` no está en `imprimiendo`** (D19-15); no depende de que haya filas en la lista, de modo que tras cargar con la lista vacía está habilitado. Deshabilitado = texto atenuado y sin relieve. Pulsarlo **envía el trabajo** a `V08`. (b) La interacción directa con `V08` (verbo «Imprimir»; 7, tabla de objetos) lo ejecuta en el sitio. Ambos usan la misma máquina de estados de `V08` (R22). Con (a), la impresora arranca a distancia (se oye, ≈ 4,05 m† de la pantalla) y la hoja queda en la bandeja; con (b) se imprime y se recoge en un paso.

R22. **Estados de `V08`.** `sin_resultados` (inicial, `correos_leidos` falso) → `lista` (al escribirse `correos_leidos`) ⇄ `imprimiendo` (`t_impresion` = 1,5 s, slice V08; `SFX_PRINTER`). Además, `V08` lleva el indicador interno `hoja_en_bandeja` (bool, de sesión, no es hecho ni estado público del slice). Tabla de la interacción directa (7, regla 8 de disponibilidad; verbo mostrado: «Imprimir», o «Recoger» con `hoja_en_bandeja`, etiqueta dinámica como `V06`):

| Estado de `V08` | `hoja_en_bandeja` | Efecto de `interact()` | Respuesta de 7 |
|---|---|---|---|
| `sin_resultados` | — | Ninguno; texto `OBJ_V08_SIN_RESULTADOS` («No hay nada que imprimir») | `SIN_EFECTO` + `HAND_REACH` |
| `lista` | falso | Pasa a `imprimiendo`; a los 1,5 s la hoja se entrega (R23) | `SI` + `HAND_REACH` |
| `lista` | verdadero | Entrega la hoja (R23) sin esperar | `SI` + `HAND_REACH` |
| `imprimiendo` | — | Ninguno | `NO` (oculto) |

R23. **Entrega.** Al terminar `imprimiendo` por (b), o al interactuar con `V08` en `lista` con `hoja_en_bandeja`, 19 comprueba que `correos_leidos` es verdadero y llama a `otorgar_sesion("I-01")` de 20 (contrato acordado: 20, R8 fila `I-01`; la llamada es idempotente). Si `has_item('I-01')` ya es verdadero, 19 no llama y el pie de objeto dice `OBJ_V08_YA_IMPRESA` («Ya tienes una copia»); la hoja se retira igualmente de la bandeja. Si no lo tiene, `I-01` entra en el conjunto de sesión y el prop de la hoja desaparece de la bandeja con `HAND_REACH`. 20 no muestra la hoja ni abre lectura (`I-01` no es relegible): la hoja se lee en la vista `C05` del P1 (R27, R30).

R24. **Repetible e ilimitada (9, regla 34).** Imprimir no se agota, no tiene coste ni límite, y funciona igual tras cargar una partida con `correos_leidos` verdadero (en ese caso `V08` nace en `lista`, `hoja_en_bandeja` falso, e `I-01` no está en el bolsillo; 9, AC-39b). El trabajo enviado desde la pantalla con la hoja ya en bandeja no genera una segunda hoja (idempotente).

R25. **Impresión durante el cierre.** Cerrar el ordenador no cancela un trabajo ya enviado: `V08` termina `imprimiendo` y deja `hoja_en_bandeja` verdadero. La hoja no desaparece por salir de la sala, cambiar de escena ni abrir la pausa.

R26. **La pista de nivel 1 del P1 (9, regla 25 y edge case de `needs_items`).** Mientras falte `I-01`, el marco resalta `V08` (`targets_if_missing_items`). 19 solo debe exponer a `V08` como objetivo resaltable por ID; no gestiona pistas.

### F. Relación con el Puzle 1

R27. **9 es dueño de sus hechos y de la vista.** 19 no escribe `archivo_abierto`, no conoce la solución `2 · 1 · 3 · 4` y no valida la vista del panel `C05`. El papel de `C05` (`C05/paper`) lo dibuja 9 con los datos que 19 le da (`compose_i01()`, R30), solo si `has_item('I-01')` (20); sin él, el marco muestra los elementos sin material (9, regla 7 y AC-39). 9 **no lee `correos_leidos`** (su `requires` es vacío); ese hecho solo lo lee 19. Tras cargar una partida `I-01` no está en el bolsillo (20, R9); el jugador reimprime y la hoja se reconstruye con `compose_i01()` idéntica, sin estado guardado.

R28. **Las referencias del P1 nacen vacías** (9, reglas 8 y 22: el estado en memoria de las piezas no persistidas empieza siempre vacío). 19 no guarda en ningún sitio qué referencia puso el jugador: la hoja es la misma siempre; las referencias colocadas en `H1`–`H4` son estado de 9.

### G. Qué no hace 19

R29. 19 no muestra medidores, contadores de intentos, avisos de «correo importante», marcas de leído/no leído que sugieran qué es relevante, ni valoraciones de ningún correo (anti-pilares: sin medidores de moral; sin historia explicada). No añade correos nuevos a los de 18 (Pilar 5: hechos observables fijos).

### H. Interfaz hacia 9 (contenido de `I-01`)

R30. **`compose_i01() -> SheetI01`** (síncrona, pura, sin escritura ni estado; la puede llamar 9 en cualquier momento, sin que 19 compruebe `has_item`, que es cosa de 9). Devuelve: `cabecera` (clave de 18); `bloques` (uno por correo, en el orden de R13): `{mail_id, ref: int 1..4 | null, dia, ts_envio: int, hora_envio: "hh:mm" | null, hora_visible: bool, cuerpo, firma}`; **`ts_envio` (D19-20)** es un **entero en minutos desde el lunes 00:00** (`índice_del_día · 1440 + hh · 60 + mm`, con `índice_del_día` de la tabla cerrada Lunes = 0 … Domingo = 6 aplicada al campo `dia` de 18) calculado por 19 a partir de los registros de 18, **siempre presente** aunque `hora_visible` sea falso y **nunca mostrado**: es solo la clave de orden para que 11 pruebe la solución (R19/AC-3 de 11) comparando enteros, sin analizar cadenas. Con `hora_visible` falso `hora_envio` es null (9 y 11 no pueden dibujar la hora ni en el papel ni en un sello de hueco: confirmado, D11-6), pero `ts_envio` sigue ahí; 11 no necesita usar solo `dia`; `pie_ordena: clave | null`. 9 la llama al abrir `C05` y en `on_reopen`, dibuja el papel con los bloques y crea un elemento clicable `C05/paper/ref_N` por cada bloque con `ref` ≠ null (exactamente 4). 19 no recibe nada de vuelta: dónde coloca el jugador cada referencia es estado de 9 (R28). Si un correo falta o su hora es ilegible, su bloque se omite con «—» y se registra el error (Edge Cases). Cualquier cambio de datos de 18 o de los datos `i01_*` se refleja en la siguiente llamada.

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

`t_impresion = 1,5 s` (slice V08). Tras `t_impresion`: `hoja_en_bandeja = verdadero`. Por (b) se entrega en el mismo fotograma (R23). `reducir_sobresaltos` no lo altera: 19 no lo consume (D19-12). Ejemplo: enviar desde pantalla en t = 20,0 s → hoja en bandeja en t = 21,5 s; si el jugador llega a `V08` en t = 28 s, «Recoger» entrega al instante.

### F4 · Composición y tamaño de la hoja `I-01`

Datos de la hoja (no layout): `bloques = 6` (4 con `ref`, 2 sin), `bloques_con_ref = 4`; cada bloque lleva día, cuerpo, firma y hora (ocultable). Estimación orientativa, **no una regla**: unas 26 líneas (6 bloques × ≈ 4 líneas + cabecera + pie), que a 24 px y ≈ 32 px por línea dan ≈ 832 px, dentro de 1080. El layout lo decide 9 al dibujar `C05/paper`; si no cabe, pagina por bloque sin partir un correo. El tamaño real por bloque varía con el cuerpo (28 px) y con firmas de dos líneas.

### F5 · Teclado en pantalla

Disposición: 10 teclas en la fila 1, 10 en la 2, 7 en la 3 (27 letras con `ñ`) y fila inferior (`Espacio`, `Borrar`, `Buscar`). Ancho de la fila más larga = `10 × tecla_px + 9 × tecla_sep_px = 10×56 + 9×8 = 632 px`; alto = `4 × 56 + 3 × 8 = 248 px`. Región de pantalla mínima = 1280 × 720 lógicos. Reparto en modo teclado (R16): teclado 248 + campo `tecla_px` 56 + `filas_visibles_min × fila_px` = 4 × 48 = 192 + 3 separaciones de 8 = 24 → 248 + 56 + 192 + 24 = **520 px ≤ 720** (holgura 200 px); el panel de lectura se oculta. Con 6 filas (288 px) sumarían 616 ≤ 720, pero se deja la lista con scroll por si el encuadre real es menor. Cada tecla ≥ `pick_min_px` (44†, 7).

---

## Edge Cases

- **Si el jugador abre el ordenador con la impresora imprimiendo (trabajo anterior):** nada cambia en la pantalla; el botón «Imprimir» queda deshabilitado (texto atenuado) hasta que `V08` vuelva a `lista`.
- **Si pulsa «Imprimir» con la hoja ya en bandeja:** no hace nada nuevo; muestra `UI_MAIL_YA_ENVIADO` («Trabajo ya enviado») en la pantalla y no genera segunda hoja (R24).
- **Si pulsa «Imprimir» dos veces seguidas durante `imprimiendo`:** la segunda se ignora (el botón ya está deshabilitado); un solo trabajo.
- **Si busca una palabra sin resultados cinco veces seguidas:** siempre `UI_MAIL_SIN_RESULTADOS`; ningún contador ni pista automática de 19 (las pistas son de 17).
- **Si busca «transición» con el campo vacío o con espacios:** longitud < 3 tras normalizar → no coincide; no hay mensaje de error propio, solo «Sin resultados».
- **Si busca varias veces «transición» tras ya tener resultados:** la lista se repite sin cambio y `correos_leidos` (ya verdadero) no se reescribe ni se emite aviso.
- **Si el jugador cierra con `atrás` durante la espera de 0,4 s:** `on_close` cancela la búsqueda pendiente; no aparece lista ni se escribe `correos_leidos`. Al reabrir, el campo conserva el texto y puede lanzarla de nuevo (AC-26).
- **Si el director (21) cierra el ordenador con `on_close(sistema)` durante la espera:** igual que arriba; si la lista ya estaba mostrada, `correos_leidos` ya estaba escrito.
- **Si el jugador carga una partida con `correos_leidos` verdadero:** `V01` empieza `apagado`, la lista está vacía (la consulta no se guarda), `V08` nace en `lista` sin hoja en bandeja y sin `I-01` en el bolsillo (`I-01` no persiste, 20 R9). El botón «Imprimir» de la pantalla **está habilitado** aunque la lista esté vacía (R21: habilitado = `correos_leidos`, no «hay resultados»); el jugador puede imprimir desde la pantalla o en `V08` sin volver a buscar (9, regla 34), o volver a buscar (no cambia nada). La hoja reimpresa se reconstruye con `compose_i01()` de los datos de 18, idéntica a la anterior.
- **Si el jugador pierde `I-01` por cargar y no recuerda dónde imprimir:** la pista de nivel 1 resalta `V08` (R26); 19 no añade ayuda propia.
- **Si el mando está activo y el jugador cambia a teclado a mitad de una consulta:** el teclado en pantalla se oculta, el texto escrito se conserva y el foco del campo se mantiene.
- **Si el jugador cambia a mando con texto escrito:** el teclado aparece; el texto se conserva.
- **Si se escribe un carácter fuera del alfabeto previsto (emoji, símbolo):** el campo lo acepta hasta `long_consulta_max` y `norm` lo elimina; no hay error.
- **Si el jugador reasigna `atrás` o `interactuar` a una tecla imprimible:** esa tecla escribe mientras el campo tiene foco (Entrada, regla 20). `atrás` conserva su asignación no imprimible, por lo que R8 se cumple.
- **Si se abre la pausa con el teclado en pantalla abierto:** al reanudar vuelve al mismo estado (foco, texto, tecla bajo el cursor).
- **Si `pantalla_min_px` no se alcanza (resolución distinta de 16:9):** 19 reduce el panel de lectura antes que el texto (nunca por debajo de 24 px lógicos); el teclado en pantalla no se recorta nunca (R16, F5): lo que se sacrifica es el número de filas visibles de la lista (mínimo `filas_visibles_min` con teclado), que se desplaza con scroll (AC-28).
- **Si un correo de 18 falta o su `hora` es ilegible:** 19 muestra «Texto no encontrado» (18, caso de texto no encontrado), registra el error y la hoja `I-01` omite el bloque con «—»; el juego no se bloquea. El verificador de 18 debería haberlo evitado.
- **Si el Jugador rechaza `HAND_REACH` al interactuar con `V08`:** 7 no llama a `interact()` (7, D7-34); no se imprime ni entrega.
- **Si `V08` está en `imprimiendo` y se guarda la partida:** el guardado no guarda `imprimiendo` ni `hoja_en_bandeja`; al cargar, estado según R24.

---

## Dependencies

Dependencias recíprocas con regla o AC citado de la otra parte. `‡` = la contraparte debe confirmar o reflejar el cambio (ver «Cambios requeridos»).

| Sistema | Tipo | Qué usa 19 / qué recibe | Regla / AC en la contraparte |
|---|---|---|---|
| 1 Entrada y controles | Dura | Cursor, `seleccionar`, texto, `atrás`, `pausa` en `ordenador`; dispositivo activo | Regla 20 (texto en el ordenador), regla 8 (transiciones), regla 17 (`pausa`), AC-12, Open Question 1 (teclado en pantalla); el AC-20 que se cita en esa pregunta no existe aún |
| 2 Jugador en primera persona | Blanda | `reproducir_gesto('HAND_TYPE')`, `reposo()` | Tabla de gestos (`HAND_TYPE`, derecha, bucle); regla 18 (cesión de cámara) |
| 3 Estado y bus | Dura | Escribe `correos_leidos`; lo lee al cargar y para habilitar «Imprimir» (R21). **19 es el único lector**: 9 no lo lee | Tabla de hechos (`correos_leidos`, escritor «19 ‡», lectores «19 · 9 (puzle 1, `requires`)»): la ‡ se cierra y el lector 9 se corrige (Cambios requeridos) |
| 4 Escena de planta | Dura | Anclaje de la pantalla `V01`, posición de `V08`, prop de hoja en la bandeja, distancia ≈ 4,05 m† entre `V01` y `V08` (de las coordenadas del slice) | `V01` y `V08` (slice §Despacho); anclajes de las vistas (4 → 7) |
| 6 Ajustes persistentes | Blanda | Lee `reducir_movimiento` (fundido de 100 ms, R4). **No** consume `reducir_sobresaltos` (D19-12) | Catálogo de ajustes (regla 1); la tabla de consumidores de `reducir_movimiento` (solo 9 y 4) debe añadir a 19 ‡ |
| 7 Interacción e inspección | Dura | Modo `ordenador`, `ViewReceiver` (`registrar_receptor`, `elements()`, `handle_pointer`, `on_open`, `on_close(motivo)`), `pick_min_px` (44†), manejador de `V01` y `V08` | Reglas 20 (PointerEvent), 22 (tamaños), 23 (cierre), 24 (ordenador); tabla de objetos (`V01`, `V08`); D7-34 |
| 11 Puzle 1 · Cronología | Dura (la declara 11) | 11 consume `compose_i01()` (`ref`, `ts_envio`, `dia`; D19-20), el objetivo resaltable `V08` (pista de nivel 1, `targets_if_missing_items`) y la impresión repetible (R23) | R19/AC-3, AC-6 y AC-8 de 11 |
| 9 Marco de puzles | Dura (9 → 19) | 9 **llama a `compose_i01()`** (R30) para dibujar `C05/paper` y los 4 elementos de referencia; `needs_items: ['I-01']` y `has_item` los evalúa 9 contra 20; pista de nivel 1 sobre `V08`. 9 **no lee `correos_leidos`** (su `requires` es `all: []`) | Reglas 7, 34 y 35; AC-39 y AC-39b; D9-33; JSON de P1 (`needs_items`, `C05/paper`) ‡ |
| 17 Sistema de pistas | Blanda | Expone `V08` como objetivo resaltable; las pistas 2 y 3 del P1 no añaden información sobre la hora de envío (D19-16: la hoja ya la lleva) | Pistas del P1 (slice 10.1, B.1; `sistema-de-pistas.md` regla 32) |
| 18 Base de contenido | Dura | Seis correos con día, hora, remitente, asunto, cuerpo, etiquetas y orden de presentación; claves `UI_MAIL_*`, `OBJ_V08_*`, `MAIL_1`–`MAIL_4`, `MAIL_X1`, `MAIL_X2`; pie `PISTA_P1_N2` | Reglas 3, 8, 11, 12, 13, 17; AC-11; filas «19» de las tablas de dependencias |
| 20 Documentos y bolsillo | Dura (de 19 hacia 20; la declara 19, el dependiente) | `otorgar_sesion("I-01")` (acordado: 20, R8 fila `I-01` e Interfaz) y `has_item("I-01")`. 20 solo guarda la pertenencia al conjunto de sesión (`I-01`, Relegible = No); **no** guarda ni muestra el contenido | 20, R8, R9, AC-05; «19 Ordenador (futuro)» en Interactions de 20 |
| 21 Director de escenas | Indirecta (vía 7; la declara 19 y 21 la repite; D19-18). Ni 19 consume API de 21 ni 21 depende de 19; sin camino en el slice | 19 solo recibe `on_close(sistema)` si 21 pide `cerrar_modos()`; no depende de 21 para nada más | `cerrar_modos()` de 7 (regla 27a); 21 reglas 13 y 20 (verificado: `cerrar_modos()` incluye `ordenador`, pero solo se pide en `ESC8_CIERRE`, en Recepción; el apagón no cierra modos); el contrato real es 21 → 7 |
| 26 Subtítulos | Ninguna | 19 no genera voz; los sonidos de la impresora llevan subtítulo no verbal si 26 lo decide | — |
| 23 Audio | Blanda | `SFX_PRINTER`, `SFX_KEY`, `SFX_CLICK_SUBTLE` | Catálogo de efectos (`director-de-audio.md`) |
| 25 Pausa / 30 Accesibilidad | Blanda | Pantalla de opciones (escala de texto, PA-3) | `menu-de-pausa.md` y `opciones-de-accesibilidad.md` |

---

## Tuning Knobs

| Parámetro | Valor | Rango seguro | Afecta a | Fuente / razón |
|---|---|---|---|---|
| `t_encendido` | 0,3 s† | 0–0,6 s | Sensación de encendido de la pantalla | Pilar 2 (sensorial); 100 ms fijos con `reducir_movimiento` |
| `t_busqueda` | 0,4 s | 0,2–0,8 s | Latencia percibida del buscador | Slice C.2 (valor del slice, sin †) |
| `t_impresion` | 1,5 s | 1,0–2,5 s | Sensación de máquina, no de espera | Slice V08 (valor del slice, sin †) |
| `long_consulta_min` | 3† | 1–6 | Ruido en búsquedas cortas | F1 |
| `long_consulta_max` | 32† | 16–64 | Tamaño del campo | R10 |
| `t_tipeo_inactivo` | 1,0 s† | 0,5–2,0 s | Fin del gesto `HAND_TYPE` | R19 |
| `tecla_px` | 56 px† | 44–72 | Precisión motriz con mando (`pick_min_px` = 44†, 7) | F5 |
| `tecla_sep_px` | 8 px† | 8–16 | Errores de pulsación | F5; el mínimo 8 coincide con AC-11 |
| `fila_px` | 48 px† | 44–64 | Altura de fila de la lista (seleccionable, ≥ `pick_min_px`) | F5 |
| `filas_visibles_min` | 4† | 3–6 | Filas de lista visibles con el teclado abierto | F5, AC-28 |
| `texto_min_px` | 24 px† (lógicos) | 24–32 (suelo único de 30, regla 26) | Legibilidad (cuerpo 28†) | R18 |
| `pantalla_min_px` | 1280 px† (lógicos) | 960–1600 | Encuadre de la cámara de 7 | R18 |
| `contraste_min` | 4,5:1 (7:1 cuerpo) | ≥ 4,5 | Accesibilidad visual | R17; WCAG 2.1 SC 1.4.3 (4,5:1) y 1.4.6 (7:1) |
| `i01_pie_ordena_visible` (dato) | verdadero† | bool | Si la hoja lleva «Ordena por hora de envío» | D19-16 (decidido); literal de B.1 |
| `i01_hora_visible` (dato) | verdadero† | bool | Si cada bloque de la hoja lleva «Enviado: hh:mm» | D19-16 (decidido); literal de B.1 |
| `pantalla_muestra_hora` (dato) | verdadero† | bool | Si lista y lector muestran la hora de envío | PA-2 (abierta: el slice B.1 no dice qué muestra la pantalla; valor provisional) |
| `resultados_incluyen_ruido` (dato) | verdadero† | bool | 6 resultados (con `MAIL_X1`/`MAIL_X2`) o 4 | PA-4; slice C.2 vs Escena 2 |
| Orden de presentación | 3, X1, 1, 4, X2, 2 | fijo | No revelar la solución | 18 regla 12; no es un knob de juego |

Todos los valores son datos (`assets/data/computer/computer.json`, ruta por G14/ADR-0005 D1), no constantes en código.

---

## Acceptance Criteria

Tipos: **L** = lógica (test automático), **I** = integración (incluye inyección de entrada), **PV** = playtest/visual con captura en `production/qa/evidence/`. Los AC marcados «(cond. PA-n)» dependen del valor provisional de una pregunta abierta y se reescriben si cambia.

- **AC-01 (R11, F1, L)**: **GIVEN** la consulta «transición», «Transicion», «TRANSICIÓN » o «transición», **WHEN** se lanza, **THEN** `hay_resultados` es verdadero; con «trans», «tr», «» o «mantenimiento», es falso.
- **AC-02 (R12, F2, L)**: **GIVEN** una consulta con coincidencia, **WHEN** pasan `t_busqueda` (0,4 s) de tiempo de juego, **THEN** se muestra la lista; **GIVEN** la pausa abierta durante la espera, **THEN** el contador se detiene.
- **AC-03 (R13, L; cond. PA-4, PA-6)**: **GIVEN** una búsqueda con coincidencia y los datos provisionales, **THEN** la lista contiene exactamente 6 filas en el orden `MAIL_3`, `MAIL_X1`, `MAIL_1`, `MAIL_4`, `MAIL_X2`, `MAIL_2`; las filas `MAIL_1`–`MAIL_4` llevan `UI_MAIL_COINCIDE` y `MAIL_X1`/`MAIL_X2` no; no existe control de ordenación; con `resultados_incluyen_ruido` = falso la lista tiene 4 filas.
- **AC-04 (R15, R21, I)**: **GIVEN** `correos_leidos` falso, **WHEN** se muestra el primer resultado, **THEN** `correos_leidos` pasa a verdadero en ese mismo fotograma y «Imprimir» pasa a habilitado (porque `correos_leidos` es verdadero); **WHEN** se repite la búsqueda, **THEN** no se emite ningún aviso nuevo.
- **AC-05 (R15, L)**: **GIVEN** una búsqueda sin coincidencia, **THEN** no se escribe ningún hecho y se muestra «Sin resultados» sin sonido de error.
- **AC-06 (R14, L)**: **GIVEN** la lista, **WHEN** el jugador abre cada uno de los seis correos en cualquier orden, **THEN** cada panel muestra día, remitente, asunto y cuerpo de 18 (y la hora si `pantalla_muestra_hora`, cond. PA-2) y no se escribe ningún hecho.
- **AC-07 (R3, R7, I)**: **GIVEN** exploración, **WHEN** se activa `V01`, **THEN** 7 abre `ordenador`, 19 recibe `on_open()` solo tras `camara_cedida`; **WHEN** `atrás`, **THEN** 19 recibe `on_close(jugador)` antes de la devolución de la cámara y el campo pierde el foco.
- **AC-08 (R7, R25, I)**: **GIVEN** un trabajo de impresión enviado, **WHEN** el jugador cierra el ordenador, **THEN** `V08` termina `imprimiendo` y `hoja_en_bandeja` es verdadero.
- **AC-09 (R8, I)**: **GIVEN** el teclado en pantalla abierto y texto escrito, **WHEN** `atrás`, **THEN** el ordenador se cierra; **GIVEN** `Retroceso` con foco en el campo, **THEN** borra un carácter y no cierra; **GIVEN** `Esc`, **THEN** abre la pausa y no cancela el texto.
- **AC-10a (R16, I)**: **GIVEN** un mando como dispositivo activo y el campo enfocado, **THEN** se muestra el teclado en pantalla; **WHEN** se inyectan eventos de stick y `seleccionar` que pulsan t-r-a-n-s-i-c-i-o-n y `Buscar`, **THEN** `hay_resultados` es verdadero y aparece la lista.
- **AC-10b (R16, F5, PV)**: **GIVEN** el teclado en pantalla abierto, **THEN** existe captura retenida a 1920 × 1080 y a 1920 × 1200 en la que las 4 filas de teclas, el campo y las `filas_visibles_min` filas de lista son completamente visibles (lista de comprobación binaria: sin recorte, sin solape).
- **AC-11 (R16, F5, L)**: **GIVEN** los datos de teclado, **THEN** `tecla_px` ≥ `pick_min_px` (44) y `tecla_sep_px` ≥ 8 (el mínimo del rango de Tuning); **y** la geometría medida del teclado instanciado a 1080p coincide con esos datos.
- **AC-12 (R22, L)**: **GIVEN** la tabla de R22, **WHEN** se interactúa con `V08` en cada fila, **THEN** el resultado coincide: `sin_resultados` → `SIN_EFECTO` y `OBJ_V08_SIN_RESULTADOS`; `lista` sin hoja → `imprimiendo` 1,5 s y entrega; `lista` con hoja → entrega inmediata; `imprimiendo` → el objeto no es objetivo.
- **AC-13 (R23, I)**: **GIVEN** `has_item('I-01')` falso, **WHEN** se completa una impresión, **THEN** 19 llama a `otorgar_sesion("I-01")` de 20 una vez y `has_item('I-01')` es verdadero; **GIVEN** que ya lo tiene, **THEN** no se llama de nuevo y el pie dice `OBJ_V08_YA_IMPRESA`.
- **AC-14 (R21, I; cond. PA-7)**: **GIVEN** `correos_leidos` verdadero **y la lista vacía** (partida cargada), **THEN** «Imprimir» está habilitado; **WHEN** se pulsa, **THEN** `V08` pasa a `imprimiendo` durante 1,5 s y `hoja_en_bandeja` queda verdadero; **WHEN** se pulsa de nuevo con la hoja en bandeja, **THEN** no se genera otra y se muestra `UI_MAIL_YA_ENVIADO`; **GIVEN** `correos_leidos` falso o `V08` en `imprimiendo`, **THEN** «Imprimir» está deshabilitado.
- **AC-15 (R24, I)**: **GIVEN** una partida cargada con `correos_leidos` verdadero y sin `I-01`, **THEN** `V08` está en `lista`, `V01` en `apagado` y P1 sin material (9, AC-39b); **WHEN** se imprime en `V08`, **THEN** `has_item('I-01')` es verdadero y P1 resoluble; el número de impresiones no tiene tope (30 repeticiones sin cambio de comportamiento).
- **AC-16 (R20, L; D19-16)**: **GIVEN** los registros de 18 y los datos provisionales, **WHEN** se llama a `compose_i01()`, **THEN** devuelve 6 bloques en el orden de presentación con `ref` 3, null, 1, 4, null, 2, cada uno con `hora_envio` igual a su registro y `hora_visible` verdadero; **WHEN** se cambia la hora de `MAIL_2` en los datos, **THEN** la hoja la refleja sin otra edición (18, AC-11).
- **AC-17 (R20, L)**: **GIVEN** un texto con marcadores de nombre, **WHEN** se compone la hoja, **THEN** ningún bloque contiene un literal de nombre o inicial vigente (18, regla 8).
- **AC-18a (R17, L)**: **GIVEN** la paleta de la pantalla, **THEN** el contraste calculado texto/fondo es ≥ 4,5:1 en todo texto y ≥ 7:1 en el cuerpo del correo.
- **AC-18b (R17, L)**: **GIVEN** los estados foco del campo, fila seleccionada, coincidencia y botón deshabilitado, **THEN** cada uno tiene en los datos al menos un atributo no cromático (borde grueso, marca ▶, texto «Coincide», relieve/texto atenuado) y el botón deshabilitado expone el estado «no disponible» al lector de pantalla.
- **AC-19 (R18, L + PV)**: **GIVEN** el viewport lógico de 1920 × 1080 (R18), **THEN** (L) el tamaño de fuente de los datos es ≥ 24 px lógicos (28 en el cuerpo) y la pantalla ocupa ≥ 1280 px lógicos de ancho; **y** (PV) existe captura retenida a 1920 × 1080, 1920 × 1200 y 1280 × 720 físicos sin recortes. A 1280 × 720 físicos el texto de 24 px lógicos mide 16 px físicos: se acepta como resolución mínima soportada y la mitigación es PA-3.
- **AC-20 (R19, I)**: **GIVEN** un jugador tecleando, **THEN** el Jugador reproduce `HAND_TYPE` hasta 1,0 s tras el último carácter o hasta `on_close`; **GIVEN** que el Jugador rechaza el gesto, **THEN** el texto se sigue escribiendo.
- **AC-21 (R4, I)**: **GIVEN** la primera apertura, **WHEN** se mide con el reloj de juego, **THEN** la transición de negro a bandeja dura `t_encendido` ± 1 fotograma, y 100 ms ± 1 fotograma con `reducir_movimiento` activo.
- **AC-22 (R5, R29, L)**: **GIVEN** el árbol de nodos de la pantalla al abrir y tras buscar, **THEN** no contiene ningún nodo de carpeta Recibidos (cond. PA-5), contador ni indicador de leído/relevante, y el único texto de relevancia es `UI_MAIL_COINCIDE`.
- **AC-23 (R27, R30, I)**: **GIVEN** `correos_leidos` verdadero e `I-01` en el bolsillo, **WHEN** el jugador abre `C05`, **THEN** 9 ve `has_item('I-01')` verdadero y dibuja `C05/paper` a partir de `compose_i01()`; 19 no escribe `archivo_abierto` en ningún caso.
- **AC-24 (edge, I)**: **GIVEN** una búsqueda en curso, **WHEN** el director cierra el ordenador con `on_close(sistema)`, **THEN** no se escribe `correos_leidos` si la lista no llegó a mostrarse.
- **AC-25 (edge, L)**: **GIVEN** el dispositivo cambia de mando a teclado con texto escrito, **THEN** el texto y el foco se conservan y el teclado en pantalla se oculta.
- **AC-26 (edge, R7, I)**: **GIVEN** una búsqueda lanzada con coincidencia, **WHEN** el jugador hace `atrás` a los 0,3 s, **THEN** no hay lista ni `correos_leidos`; **WHEN** reabre el ordenador, **THEN** el campo conserva el texto, y **WHEN** lo lanza otra vez, **THEN** los resultados aparecen a los 0,4 s y `correos_leidos` pasa a verdadero.
- **AC-27 (Player Fantasy, PV, †)**: **GIVEN** jugadores nuevos sin ayuda de pistas, **THEN** al menos 4 de 5 encuentran el buscador, lo usan con «transición» y llegan a los resultados (umbral †, análogo al criterio X1 del slice §7; a validar en playtest).
- **AC-28 (R16, F5, L + PV)**: **GIVEN** el teclado en pantalla abierto en una región de pantalla de 1280 × 720 lógicos, **THEN** teclado (248 px) + campo + `filas_visibles_min` (4) filas de lista caben sin solape (F5), el resto de la lista se alcanza con scroll (rueda o `mover_cursor` en el borde), y el panel de lectura queda oculto mientras el teclado está visible.
- **AC-29 (R30, I)**: **GIVEN** 9 abriendo `C05`, **WHEN** llama a `compose_i01()` antes y después de cargar una partida, **THEN** la estructura devuelta es idéntica (función pura sin estado) y contiene exactamente 4 bloques con `ref` ≠ null para los elementos clicables de `C05/paper`.
- **AC-30 (R20, L; D19-16, prueba de configuración de los datos)**: **GIVEN** `i01_hora_visible` = falso o `i01_pie_ordena_visible` = falso, **WHEN** se llama a `compose_i01()`, **THEN** `hora_visible` es falso en todos los bloques o `pie_ordena` es null, respectivamente, sin cambiar nada más.
- **AC-31 (R30, D19-20, L)**: **GIVEN** los registros de 18 y los datos provisionales, **WHEN** se llama a `compose_i01()`, **THEN** cada bloque lleva `ts_envio` entero igual a `índice_del_día · 1440 + hh · 60 + mm` de su registro; **WHEN** `i01_hora_visible` = falso, **THEN** `hora_envio` es null y `ts_envio` sigue presente y sin cambios; **GIVEN** un `dia` fuera de la tabla Lunes–Domingo, **THEN** el bloque se omite con «—» y se registra el error (Edge Cases); **THEN** ordenar los 4 bloques con `ref` por `ts_envio` da la secuencia que 11 espera sin leer ninguna cadena.

---

## Decisiones tomadas

| D19-4 | Coincidencia por **igualdad con etiqueta** normalizada (sin tildes/mayúsculas), mínimo 3 caracteres | Búsqueda de texto libre en asunto/cuerpo; coincidencia por prefijo | Una búsqueda libre abre caminos que el slice no diseña (p. ej. «Vera») y obliga a decidir qué correos devuelve; el prefijo causa dudas |
| D19-6 | La pantalla muestra remitente, asunto y día (y hora según PA-2); no muestra las referencias 1–4 | Mostrar las referencias en pantalla | El material del P1 es la hoja (`needs_items`); la pantalla da los hechos, la hoja la utilidad |
| D19-7 | Teclado en pantalla con el cursor existente, solo con mando (más botón opcional) | Autocompletado «transición» o botón-atajo; teclado con navegación por D-pad | El autocompletado regala la palabra (Pilar 3); un D-pad requeriría acciones nuevas de Entrada; el cursor ya existe (Entrada, AC-12) |
| D19-8 | La búsqueda es insensible a tildes | Exigir «transición» exacta | Quien teclea sin tilde no debe ser castigado (Pilar 4); además el mando lo ahorra |
| D19-9 | `V01` pasa a `sesión abierta` una vez; al cargar vuelve a `apagado` | Guardar el estado de la pantalla | No es un hecho; guardarlo añade estado sin valor; el coste es 0,3 s de encendido |
| D19-10 | El estado de una búsqueda a medias no se guarda | Guardar consulta y lista | No cambia ningún hecho; la hoja y `correos_leidos` bastan |
| D19-11 | El contenido de `I-01` lo posee 19 (`compose_i01()`, función pura que consume 9 para `C05/paper`); 20 solo guarda `has_item` | Hacer `I-01` relegible en 20 con texto propio; que 9 componga la hoja | Contrato acordado entre lotes: un solo dueño del contenido (18 → 19), 20 sin almacenamiento (20 D20-1) y 9 sin conocer correos. Coste: la hoja solo se lee dentro de `C05` (ver PA-9) |
| D19-12 | 19 no consume `reducir_sobresaltos` | Atenuar `SFX_PRINTER` con ese ajuste | El zumbido de la impresora es ambiente bajo, no un susto; si 23 decide atenuarlo lo hace por su cuenta |
| D19-13 | Con el teclado abierto el panel de lectura se oculta y la lista muestra ≥ `filas_visibles_min` filas con scroll; el teclado se oculta al seleccionar una fila (el foco sale del campo, R6) | Teclado reducido sobre lista completa; lector siempre visible | En 720 lógicos no caben teclado (248) + campo + 6 filas + lector; la lista y el lector no se necesitan a la vez que se teclea |
| D19-14 | Se elimina la tecla `´` (y `-`) del teclado en pantalla | Teclas muertas de acento | La búsqueda ignora tildes (R11, D19-8); las teclas muertas añaden estados sin valor |
| D19-15 | «Imprimir» habilitado ⇔ `correos_leidos` verdadero y `V08` ≠ `imprimiendo` | Habilitado solo cuando hay resultados en pantalla | Coherente con la carga de partida con lista vacía (edge, AC-14) |
| D19-16 | **Aprobada por el usuario, 2026-11-09 (cierra PA-1 y la parte de la hoja de PA-2; slice v0.4, B.1 literal):** la hoja `I-01` lleva siempre `Enviado: hh:mm` en cada bloque y el pie «Ordena por hora de envío» (`i01_hora_visible` = verdadero, `i01_pie_ordena_visible` = verdadero; los datos siguen existiendo y son parametrizables). Las pistas 2 y 3 del P1 no añaden esa información; la escalera de pistas es más corta (aceptado). | Hoja sin pie ni hora, que 17 los revele con las pistas 2 y 3. | Es el texto literal de B.1 del slice; mantiene la hoja autosuficiente y evita contradecir el slice; el coste (pistas 2 y 3 redundantes) lo asume el usuario. |
| D19-17 | **(Ronda de corrección 2, W-8, W-4)** El ejemplo de `motivo = sistema` ya no es «antes del apagón» (21 reglas 13 y 20: el apagón no cierra modos); la dependencia 19 ↔ 21 queda Blanda y asimétrica (21 no la lista; el contrato real es 21 → 7). Se confirma que `compose_i01()` es la R30 de 19 (L110). Discrepancia de dureza anotada: 19 declara a 1 Dura y 1 lista a 19 como Blanda; 19 declara a 4 Dura y 4 no lista a 19. | Quitar la fila de 21 o dejar el ejemplo del apagón. | El ejemplo era falso; 19 sí recibe `on_close(sistema)` y debe poder tolerarlo. Decisión por defecto. |
| D19-18 | **(Ronda de corrección 4, R6-1)** Dirección real de 19↔21: 19 no llama a ninguna API de 21 ni lee nada suyo; 21 tampoco depende de 19 (no le pide nada ni escucha su estado). El único camino es 21 → 7 (`cerrar_modos()`, 7 regla 27a) → `on_close(sistema)` en 19, y en el slice ni siquiera se recorre (21 reglas 13 y 20: solo pide `cerrar_modos()` en `ESC8_CIERRE`, en Recepción). Se declara **una sola vez**, aquí, por 19 (el que recibe el cierre): **Indirecta (vía 7)**, y 21 repite «Indirecta». Sustituye a «Blanda asimétrica» de D19-17. Pares restantes de 19 comprobados: 1, 3, 4, 7, 9, 18 y 20 **Dura/Dura**; 2, 6 y 23 **Blanda/Blanda** | Dejar «Blanda» con una contraparte que no la lista, o declarar una dependencia directa 21 → 19 | Una dependencia que pasa por 7 es indirecta; «Blanda sin camino» no describía el contrato |
| D19-19 | **(Ronda de corrección 5, dependencias R7 y GDD 22)** Comprobado: 19 no cita ni depende de 22 (ninguna cita «22 sin GDD/pendiente»); la llamada no pide cambios a 19. 19 ↔ 9: 19 no depende de 9; la declara 9 (Dura, 9 → 19: `compose_i01()`) y 19 la repite en su fila, sin ciclo (9 → 19 → 20; 19 no llama a 9). 19 ↔ 21 sigue Indirecta (vía 7, D19-18) | Añadir una fila de 22 | No existe ninguna relación 19 ↔ 22: la llamada solo exige estar en el despacho y no cierra modos (22 D22-14), y 19 no recibe nada de ella |
| D19-20 | **(Ronda de corrección 8, petición bloqueante de 11)** `compose_i01()` devuelve `ts_envio` entero (minutos desde el lunes 00:00) por bloque; con `hora_visible` falso `hora_envio` es null y `ts_envio` se conserva (D11-6). Cierra AC-3 de 11 | `dia_orden` entero más `hora_envio` (obliga a analizar la hora); que 11 compare cadenas | Un solo entero comparable; la hoja y la solución salen de la misma fuente y no se leen textos |
| D19-21 | **(Ronda de corrección 8)** 11 queda listado como dependiente duro en Dependencies («consume `compose_i01()`, `V08` resaltable e impresión repetible»). Sin claves `OBJ_V08_*` nuevas: 11 solo usa `OBJ_V08_SIN_RESULTADOS` (ya en 18) | Pedir `OBJ_V08_*` nuevas | 11 no lo pide |

Reclasificadas como preguntas abiertas en la ronda de corrección 1 (alcance del slice, no decisiones): D19-1 (hoja no sostenible) y D19-2 (hoja en bandeja y botón de pantalla) → PA-7; D19-3 (sin Recibidos) → PA-5; D19-5 (sin ordenar) → PA-6. La implementación provisional no cambia.

---
| D19-22 | **(Ronda de corrección 9, `gdd-cross-review-2026-11-10.md`)** Las ‡ de la fila de 17 (pistas del P1: `sistema-de-pistas.md` regla 32), 23 (`SFX_PRINTER`, `SFX_KEY`, `SFX_CLICK_SUBTLE`: `director-de-audio.md`) y 25/30 (escala de texto: `menu-de-pausa.md`, `opciones-de-accesibilidad.md`) se sustituyen por el fichero. 17 lee `correos_leidos` (blanda, vía 3) | Dejar las ‡ | Los contratos ya están en esos GDD |
| D19-23 | **(Ronda de corrección 10, restos R15)** `texto_min_px`: rango [24, 32] en lugar de [20, 32] | Dejar 20–32 | El suelo de texto de 30 (regla 26) es 24 px lógicos; el rango no puede permitir bajar de él. El registro (`texto_min_px`, range [20,32]) debe alinearse (cambio requerido, no editado aquí) |
| D19-24 | **(2026-11-11, M1 cola B; H21 = ADR-0016 OI-10; G14 = ADR-0005 O1)** (a) R18: la pantalla del ordenador es un overlay del lienzo raíz en `SceneUi`; (b) los valores viven en `assets/data/computer/computer.json`. Tensión anotada, sin resolver aquí: la cláusula de R18 «la cámara del modo `ordenador` debe dejar la pantalla ocupando ≥ `pantalla_min_px`» describe el encuadre del monitor `V01`; con un overlay, `pantalla_min_px` se mide sobre el ancho lógico del overlay y la cámara solo encuadra `V01`. A revisar con 2 y 7 | (a) `SubViewport` sobre una malla 3D del monitor (también contradice H30, que es [U] para los puzles 2/5, no para 19); (b) dejar `assets/data/` genérico | ADR-0016 OI-10 lo confirma para el slice (cierra ADR-0007 OI-5); ADR-0005 D1 fija `assets/data/<dominio>/<snake>.json`. |

## Preguntas abiertas

| PA-1 | ~~Pie «Ordena por hora de envío» y hora en la hoja.~~ **Decidida (D19-16, 2026-11-09).** | — | Cerrada |
| PA-2 | **Parte de la hoja: decidida** (D19-16: la hoja lleva la hora). **Parte de la pantalla: abierta.** El slice B.1 define solo la hoja; no dice si la lista y el lector del ordenador muestran la hora de envío (como todo cliente de correo). Con hora en pantalla y en la hoja el P1 apenas exige imprimir (basta ordenar cuatro horas); sin ella la hoja sigue siendo necesaria. **Provisional:** sí (`pantalla_muestra_hora` = verdadero; R13/R14), parametrizado en datos. | game-designer / creative-director | Dificultad del P1 |
| PA-3 | ¿Escala de texto de la pantalla y de las lecturas? El catálogo de 6 no tiene ajuste de tamaño de texto; 19 fija 24 px lógicos mínimos. Si se añade `escala_texto_ui`, 19 la aplicaría. | accessibility-specialist / usuario | Alcance del MVP de accesibilidad (slice §14) |
| PA-4 | ¿Cuántos resultados: 4 o 6? El slice se contradice: Escena 2 (l.232) «el buscador muestra los cuatro correos»; C.2 (l.965) «dos distractores entre ellos» (seis). Los dos de ruido (`MAIL_X1`, `MAIL_X2`) los aporta 18. **Provisional:** 6 (`resultados_incluyen_ruido` = verdadero); AC-03 condicionado. | autor del slice / narrative-director | Dificultad del P1 y coherencia del slice |
| PA-5 | **Sin carpeta Recibidos** (antes D19-3). El slice l.411 dice que los correos «se pueden consultar desde el ordenador en cualquier momento»; con 19 la lista está vacía tras cargar y exige volver a buscar. Alternativa: bandeja de entrada con los seis correos visibles y el buscador como atajo (pero `correos_leidos` perdería su hallazgo). **Provisional:** sin Recibidos. | creative-director / autor del slice | Alcance y Pilar 3; cambia la lectura de una frase del slice |
| PA-6 | **Sin ordenar la lista** (antes D19-5). Alternativa: botones de orden por hora/remitente (regalarían la solución del P1). **Provisional:** orden fijo de 18, sin control de ordenación. | game-designer | Dificultad del P1 |
| PA-7 | **Hoja en bandeja y dos vías de impresión** (antes D19-1 y D19-2). 19 introduce un prop nuevo (hoja en la bandeja de `V08`, `hoja_en_bandeja`) y una segunda vía de entrada (botón «Imprimir» de pantalla) además del verbo de `V08`; la hoja no se sostiene en la mano. Alternativas: solo verbo de `V08` (el botón del slice C.2 quedaría sin función) o solo botón (la hoja se teletransporta). Afecta a 4 (prop) y a 7 (verbo dinámico). **Provisional:** como en R21–R23. | autor del slice / level-designer | Alcance de 4 y 7 |
| PA-8 | ¿Los dos correos de ruido (`MAIL_X1`, `MAIL_X2`) y su contenido, ya dados por 18, forman parte del alcance del slice? | narrative-director | Alcance de contenido |
| PA-9 | ¿Debe poder releerse la hoja fuera de `C05`? Con D19-11 `I-01` no es relegible: solo se ve en la vista del P1. Alternativa: hacer `I-01` relegible en 20 usando `compose_i01()` para el texto. **Provisional:** solo en `C05`. | autor del slice / 20 | Alcance de 20 y del bolsillo |

---

## Cambios requeridos en otros GDDs

| GDD | Cambio | Motivo |
|---|---|---|
| 18 Base de contenido | Añadir claves `UI_MAIL_BUSCAR`, `UI_MAIL_BUSCAR_BTN`, `UI_MAIL_VACIO`, `UI_MAIL_SIN_RESULTADOS`, `UI_MAIL_COINCIDE`, `UI_MAIL_IMPRIMIR`, `UI_MAIL_YA_ENVIADO`, `UI_MAIL_TECLADO`, `OBJ_V08_SIN_RESULTADOS`, `OBJ_V08_YA_IMPRESA`, `OBJ_V01`/`OBJ_V08` (etiquetas), la cabecera de la hoja `I-01` (`DOC_I01` pasa a ser la plantilla de composición de 19, no un documento de 20) y los asuntos/remitentes de `MAIL_1`–`MAIL_4` | R5, R12, R13, R20, R22, R23 |
| 20 Documentos y bolsillo | (a) **Sin cambio de API**: `otorgar_sesion("I-01")` y `has_item` ya cubren R23. (b) Reflejar que el **contenido** de `I-01` lo posee 19 (`compose_i01()`) y que 20 no guarda ni muestra referencias; mantener `I-01` Relegible = No salvo que se acepte PA-9. (c) Cambiar «19 Ordenador (sin GDD)» por la referencia a `ordenador-correo-impresora.md`. (d) Quitar la expectativa de `DOC_I01` como documento de 20 | R23, R30, D19-11 |
| 9 Marco de puzles | (a) Dibujar `C05/paper` y los 4 elementos de referencia con `compose_i01()` de 19 (R30), solo si `has_item("I-01")`; llamarla al abrir `C05` y en `on_reopen`. (b) Declarar que 9 **no lee `correos_leidos`** (su `requires` es `all: []`); corregir cualquier frase contraria. (c) Recoger la dependencia 9 → 19 | R27, R30, A1 |
| 3 Estado y bus | En la tabla de hechos: cerrar la ‡ de `correos_leidos` (escritor **19**, confirmado) y cambiar los lectores a «19 (habilita imprimir)»; quitar «9 (puzle 1, `requires`)» y la fila equivalente de dependencias | R15, A1, A2 |
| 6 Ajustes persistentes | Añadir 19 como consumidor de `reducir_movimiento` (fundido de 100 ms, R4) en la tabla de consumidores (hoy solo 9 y 4). 19 no consume `reducir_sobresaltos` (D19-12); si se resuelve PA-3, añadir `escala_texto_ui` | R4, D19-12 |
| 7 Interacción e inspección | Fila `V08`: verbo dinámico «Imprimir»/«Recoger» (como `V06`) y disponibilidad según `hoja_en_bandeja`; anclaje de `V01` con `fov_destino` que deje la pantalla ≥ `pantalla_min_px` | R18, R22 (cond. PA-7) |
| 4 Escena de planta | Prop de hoja en bandeja de `V08`; anclaje de cámara de `V01` y sonido de impresora a ≈ 4,05 m | R18, R21 (cond. PA-7) |
| 1 Entrada y controles | Cerrar Open Question 1 con R16; el AC-20 citado puede referirse al AC-10a de 19 | R16 |
| 17 Sistema de pistas | Pistas 2 y 3 del P1 sin información nueva sobre la hora (D19-16; el slice v0.4 lo acepta); solo la pista 1 orienta (guía a `V08`); usar `V08` como `targets_if_missing_items` | R26 |
| 21 Director de escenas | Verificado (ronda 5): `cerrar_modos()` de 21 (regla 20) incluye `ordenador` y produce `on_close(sistema)`; sin camino real en el slice (solo `ESC8_CIERRE`, en Recepción). Sin cambio. | R7 |
| `design/ux/` | **UX spec** de la pantalla del ordenador (`design/ux/ordenador-correo.md`): disposición, foco, teclado en pantalla (modo teclado D19-13), estados vacío/sin resultados/resultados y legibilidad; la escribe `/ux-design`, no este GDD | Sistema con pantalla y flujo |
| 11 Puzle 1 · Cronología | Retirar la petición bloqueante de AC-3 (`ts_envio` aceptado, D19-20) y confirmar que usa `hora_envio` null/`ts_envio` según D11-6 (aplicado en la ronda 8) | R30, AC-31 |
| 18 Base de contenido | Sin claves nuevas; el campo `dia` de los registros debe estar en la tabla Lunes–Domingo (D19-20) | R30 |
| `systems-index.md` | Marcar 19 «Revisado (ronda de corrección 8) — pendiente de re-review»; añadir 11 a los dependientes | Estado |

## Entradas para el registro

- **Hecho:** `correos_leidos` (bool, falso); escritor 19; lector 19 (habilitar imprimir). 9 no lo lee. Ya existe en el GDD de 3.
- **Ítem:** `I-01` (no persistente; origen `V08`; 19 llama a `otorgar_sesion("I-01")` de 20). Contenido: lo compone 19 (`compose_i01()`).
- **Estados de objeto:** `V01` (`apagado`, `sesión abierta`); `V08` (`sin_resultados`, `lista`, `imprimiendo`; indicador interno `hoja_en_bandeja`).
- **Constantes:** `t_busqueda` 0,4 s; `t_impresion` 1,5 s; `long_consulta_min` 3†; `long_consulta_max` 32†; `tecla_px` 56†; `tecla_sep_px` 8†; `fila_px` 48†; `filas_visibles_min` 4†; `texto_min_px` 24†; `pantalla_min_px` 1280†.
- **Datos parametrizados (PA):** `i01_pie_ordena_visible`, `i01_hora_visible`, `pantalla_muestra_hora`, `resultados_incluyen_ruido`.
- **Claves de contenido nuevas:** las listadas en «Cambios requeridos» (18).
- **Plantilla:** `DOC_I01` (composición de la hoja, estilo `impreso`; no es documento de 20).
- **Orden de presentación de correos:** 3, X1, 1, 4, X2, 2 (de 18, regla 12).

## Historial

| Versión | Fecha | Cambios |
|---|---|---|
| 0.1 | 2026-11-09 | Borrador del lote Feature 1 (ux-designer, modo autónomo). Pendiente de review. |
| 0.2 | 2026-11-09 | Ronda de corrección 1 según la revisión independiente (3 bloqueantes, 11 avisos): contrato con 20 (`otorgar_sesion`), dueño del contenido de `I-01` (`compose_i01()`, R30), PA-1 y D19-1/2/3/5 reclasificadas como preguntas abiertas con valores provisionales parametrizados, teclado en pantalla simplificado y con scroll (D19-13/14), «Imprimir» ligado a `correos_leidos` (D19-15), ACs retipados y ampliados (AC-10a/b, 18a/b, 26–30), valores † uniformes, distancia recalculada (≈ 4,05 m). Estado: Revisado (ronda de corrección 1) — pendiente de re-review. |
| 0.3 | 2026-11-09 | Ronda de decisiones 1: D19-16 (aprobada por el usuario): PA-1 cerrada y PA-2 cerrada en lo que toca a la hoja (`i01_hora_visible` y `i01_pie_ordena_visible` = verdadero, B.1 literal, pistas 2 y 3 sin información nueva); `pantalla_muestra_hora` sigue abierta (el slice no lo define). PA-3 a PA-9 sin cambios. Estado: pendiente de re-review. |
| 0.4 | 2026-11-09 | Ronda de corrección 2 (informe cruzado ronda 5, W-8, W-4): R7 sin el ejemplo falso del apagón, fila de 21 reescrita (Blanda, asimétrica), D19-17; discrepancias de dureza anotadas. Estado: Revisado (ronda de corrección 2) — pendiente de re-review. |
| 0.5 | 2026-11-09 | Ronda de corrección 4 (informe cruzado ronda 6: R6-1, `reviews/cross-review-r6-2.md`): 19 ↔ 21 declarada Indirecta (vía 7) una sola vez (D19-18); fila de 20 con quién la declara. Estado: Revisado (ronda de corrección 4) — pendiente de re-review. |
| 0.6 | 2026-11-09 | Ronda de corrección 5 (GDD 22 y `reviews/dependencias-r7-review.md`): comprobadas las citas a 22 (ninguna) y la dirección 9 → 19; D19-19. Sin cambios de reglas. Estado: Revisado (ronda de corrección 5) — pendiente de re-review. |
| 0.7 | 2026-11-09 | Ronda de corrección 8 (propagación del GDD 11): `ts_envio` entero en `SheetI01` de R30 (D19-20, AC-31), `hora_envio` null con `hora_visible` falso, 11 como dependiente (D19-21). Sin cambios en 18 (`dia` en la tabla Lunes–Domingo). Estado: Revisado (ronda de corrección 8) — pendiente de re-review. |
| 0.8 | 2026-11-10 | Ronda de corrección 9: ‡ de 17, 23, 25 y 30 sustituidas por sus ficheros; D19-22. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. |
| 0.9 | 2026-11-10 | Ronda de corrección 10 (restos R15): `texto_min_px` con rango [24, 32] (D19-23). Estado: Revisado (ronda de corrección 10) — pendiente de re-review. |
