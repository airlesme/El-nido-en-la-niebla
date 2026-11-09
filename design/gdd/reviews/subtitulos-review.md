# Revisión independiente · Subtítulos (sistema 26)

Fecha: 2026-11-09 · Revisor: independiente (sin contexto del autor) · Documento: `design/gdd/subtitulos.md`

## Veredicto: NEEDS REVISION

Estructura completa y buen respeto de los pilares. Hay 5 bloqueantes, todos corregibles sin rediseñar el sistema. Los dos más serios son que F1 no es la misma fórmula que F3 de 23 y que el ejemplo de `VO_G_07` no se parece al texto real del slice.

## Completitud

Presentes: Overview, Player Fantasy, Detailed Rules (A–E), Formulas F1–F4, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria, Decisiones tomadas, Open Questions, Cambios requeridos y Entradas para el registro. Cumple las 8 secciones y los extras del proyecto.

Huecos de ACs, sin prueba para: R4, R5, R8, R13 con audio, R16 con `subtitulos_hablante` falso, R24, R26 (`UI_SUB_MUESTRA`) y R28.

## BLOQUEANTES

| Id | Ubicación | Problema | Arreglo propuesto |
|---|---|---|---|
| B-1 | R8, Edge Cases «Terminada sin iniciada», frente a R6 y D26-2 | R6 y D26-2 dicen que el bloque nace **solo** en «línea iniciada», nunca en «pedida». R8 lo hace nacer en «pedida + 0,0 s» si falta el aviso. El Edge Case dice «el bloque (si existe por pedida)». Si 23 no emite el aviso, el texto se adelanta al audio, que es lo que D26-2 descarta. 23 R15 lo define como «opcional» y 23 R8 dice que 23 no espera a 26. | Fijar un único comportamiento. Propuesta: sin «iniciada», el bloque nace en «pedida» **solo** si la línea no ha entrado en cola. Documentar el desfase como excepción de D26-2. Reescribir el Edge Case en consecuencia y añadir un AC para R8. |
| B-2 | F1 y R7 frente a 23 F3 y R47 | F1 afirma «misma definición que F3 de 23». No lo es. 23 F3 es `clamp(1,5 + n/15, 1,5, 14,0) + n_pausas·1,2`, con techo 14,0 y término de pausas. F1 usa tope 8,0 y no tiene el término de pausas. Los dos valores de `t_lectura_s` divergen para `VO_G_07` y para todo texto de más de unos 97 caracteres. Además, `t_visible` se acota a `t_sub_max_s` (8,0) también **con audio**. Una línea con audio más largo (`VO_G_07`, unos 14 s) retiraría el texto mientras la voz sigue. Eso contradice «misma línea de tiempo» y R6. | (a) Citar 23 F3 literalmente y distinguir `t_lectura_s` (de 23) de `t_visible_bloque` (de 26). (b) Aplicar `t_sub_max_s` **por página**, no por línea. Aclarar que una línea con audio de más de 8 s se pagina y que la suma de páginas cubre el audio. (c) Añadir un AC con audio largo. |
| B-3 | R13, F2, AC-26-05 y ejemplo F2, frente al slice §12 (L306), 23 R16/OQ 9 y 18 R9 | El ejemplo usa A = 120 y B = 80 caracteres. El texto real del slice es A = «Venga, que somos un equipo» (26 car.) y B = «No. Esa toma no. … tuyo» (unos 96 car.). Con T = 14,0 y P = 1,2, A dura unos 2,7 s y B unos 10,1 s. B pasa de `t_sub_max_s` (8,0) y de 2 líneas de 42 car. (3 líneas), así que necesita paginar. F2 no dice cómo se pagina B dentro de su ventana. Con audio, la pausa va dentro del fichero (23 R16), pero F2 solo define P sin audio. El instante de B queda sin definir si `seg_b_inicio_s` no existe. Ese campo no está en 18 (R9, AC-09), y 23 OQ 9 solo promete la duración total. «Cierra la OQ 9 de 23» es por tanto una propuesta, no un cierre. | Rehacer el ejemplo y AC-26-05 con 26/96 caracteres. Definir F2 con audio: P = `pausa_segmento_s` (estimado) dentro de la duración de «línea iniciada», y paginación anidada de B. Declarar `seg_b_inicio_s` como cambio requerido en 18 y 23 y marcar la OQ 9 de 23 como «propuesta». |
| B-4 | R2, R16, Entradas para el registro (`SUB_HABLANTE_*`) frente a 18 R22 y AC-03a | 18 define `SUB_<EVENTO>` como «sonido no verbal con subtítulo». Exige marcador de pendiente si el texto es provisional, y dice que `SUB_BREATH_BROKEN` es la única de ese lote. R2 de 26 llama a «los que 18 declara con clave `SUB_*`» sonidos subtitulables. Con `SUB_HABLANTE_VERA` el verificador de 18 los trataría como sonidos y no cuadrarían con R2. `SUB_CHAIRS_ROLL`, `SUB_TYPING_FAR` y `SUB_PHONE_BUZZ` tampoco existen aún en 18. | Renombrar los nombres de hablante a `UI_SUB_HABLANTE_*`. Marcar las tres `SUB_*` nuevas como provisionales con marcador de pendiente y listar el cambio en 18 con el prefijo correcto. |
| B-5 | Dependencies, cabecera «Depende de» y Cambios requeridos | Las dependencias no son recíprocas ni tienen la misma dureza. 26→23 es **Dura**, pero 23 (fila 26) y el índice la tratan como **Blanda**; 22 también la declara blanda ‡. 26→3 es **Dura**, pero el índice (fila 26 y sección de orden) solo lista 6, 18 y 23, sin 3. 24 no menciona a 26 en su texto. 26 marca 9 y 22 como «Consumidor» sin dureza, mientras 9 declara 26 blanda. 21 dice «sin dependencia» con 26. Sin embargo, 21 (L134) usa la «duración de su subtítulo» como fin de línea; el vínculo es de datos (`t_lectura_s`), no un acoplamiento directo, y conviene decirlo. | Unificar. O 26→23 es Blanda («avisos», con degradación a `fallback_s`, como pretende R8), o 23 la sube a Dura. Añadir 3 al índice. Escribir la fila de 26 en 24 y en 21, con la nota de que 21 comparte `t_lectura_s` sin depender. Poner una dureza en las filas 9 y 22. |

## AVISOS

| Id | Ubicación | Problema | Arreglo propuesto |
|---|---|---|---|
| W-1 | R15 frente a R7 | R15 permite ceder el sitio tras 1,0 s, pero R7 impone `t_lectura_s` (≥ 1,5 s). Dos mínimos distintos para el mismo bloque. | Usar `min(t_lectura_s, 1,0)` o un único mínimo explícito. |
| W-2 | R19 frente a R15 y `sub_car_linea` | R19 dice que el ancho (60 %) no cambia y que el texto «se reflowa en más líneas». Pero `sub_lineas_max` = 2 y `sub_car_linea` = 42 son fijos. No queda claro qué manda con `grande`: el ancho en píxeles o los 42 caracteres. | Definir `sub_car_linea` como máximo derivado del ancho (por F3) y no como constante, o fijar la paginación con `grande`. |
| W-3 | F4, R14 y R23 | F4 da 184 px (17 %) pero ignora el margen inferior del 7 %, de modo que la banda real ocupa el 24 %. El tope para 22 y 24 debe incluirlo. R23 desplaza el pie «la altura de los bloques actuales» pero reserva la F4 completa en la regla de 24. | Sumar `sub_margen_inf_pct` a F4 y alinear R23 con la altura reservada. |
| W-4 | R12, `SUB_PHONE_BUZZ` | Un lazo no tiene «duración del sonido». No se dice cuándo se retira el subtítulo ni qué pasa con `stop`/`interrupt` (23 R34). | Retirar en `stop`/`interrupt`/`en_llamada`, o duración fija `t_sub_sfx_lazo_s`. |
| W-5 | R25 | «Atenuados un 0 %» no significa nada. | Eliminar el inciso: «sin cambio de aspecto». |
| W-6 | R5 y R25 | 26 llama «pausa abierta/cerrada» a señales que 23 nombra `pause_opened` y «pausa cerrada» ‡. | Usar los nombres de 23/3. |
| W-7 | R2 y OQ 2 | R2 enumera como «lista del slice» tres sonidos subtitulados que ni 22 ni 18 ni el slice contemplan. El texto lo afirma antes de resolver la OQ 2, que sí roza «Información incompleta». D26-7 añade tres ajustes de jugador nuevos. D26-8 cita «un cuarto de la tensión» sin fuente. Alcance y tono, no elevados. | Marcar R2 como «propuesta pendiente de OQ 2». Mantener solo `SUB_BREATH_BROKEN` como obligatorio. Retirar la cifra de D26-8. Elevar los tres ajustes de 6 a Open Question, porque amplían el menú de pausa (25). |
| W-8 | R18 y AC-26-09 | «7:1 con fondo translúcido» no es garantizable sobre una escena variable. «La escena más clara posible» no está definida. | Medir contra un fondo de referencia fijo (blanco y negro) y definir el fondo mínimo de opacidad. |
| W-9 | R13 | 23 R16 dice que la pausa de `VO_G_07` va dentro del fichero. R13 usa 1,2 s † para la rama con audio sin dato. | Con audio, B debe esperar «línea iniciada» + `seg_b_inicio_s` o un fallback explícito (F2 con P = 1,2). |
| W-10 | Cambios requeridos | Faltan: 6 (el bloque «restablecer todos» fija 12 claves y pasaría a 15), 25 (hoy solo ofrece `subtitulos_activos`), 23 (`t_lectura_s` ya tiene su propia definición), 18 (`seg_b_inicio_s`, prefijos). | Completar la tabla. |

## Verificado correcto

- **Avisos de 23:** «línea terminada» (motivos `fin`, `corte`, `watchdog`, `interrumpida`), «línea sin audio» y «línea fallida» (payload `t_lectura_s`) y «línea iniciada» ‡ (`{line_id, duracion_s, canal}`, opcional, R15) existen en 23 con esos nombres.
- **Cálculos:** F1: «Lo sé» = 1,83 s y `VO_G_13D` = 5,70 s coinciden con AC-23-02. F4: 184 px (17,0 %) y 244 px (22,6 %, redondeo 23 %). F3: 21 y 20 px a 720p. F2: 7,68 + 1,2 + 5,12 = 14,0.
- **Slice:** `fallback_s` 14,0 para `VO_G_07`, `pausa_segmento_s` 1,2 y `t_linea_max_s` 8,0 de 21 coinciden con `t_sub_max_s`. El fundido de 100 ms con `reducir_movimiento` es coherente con el slice (L65). El texto de los subtítulos del slice es literal y no se inventa nada (L455).
- **22:** `SUB_BREATH_BROKEN`, `SFX_BREATH_BROKEN` (4,0 s) y R20 coinciden con 22 AC-22-25 y con 18.
- **Silenciar:** «silenciar no acorta» coincide con 23 R37 y D23-2.
- **Corte de 23:** el corte a `techo_s` con «terminada» (`corte`) está contemplado en R11.
- **Pilares:** no hay contradicciones. El subtítulo de sonido sin causa respeta «Información incompleta».
- **Godot:** no hay afirmaciones sobre APIs de Godot 4.7 en el GDD. No hay nada que verificar en `docs/engine-reference/godot/`.

## No verificado

No he contrastado: R15 de 9 / AC-P5-17 de 15, «regla 1,10 de 30» (zona segura), R8 y R12 de 23 sobre topes, y 22 R25. Quedan fuera de este informe.
