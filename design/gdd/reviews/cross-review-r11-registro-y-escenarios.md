# review-R15-3 (informe, parte 1 registro + parte 2 escenarios)

## PARTE 1

### (1) Muestra frente a Tuning Knobs (~75 constantes: 23 ~30, 28 ~35, 29 13, 24 17, 26 ~17, 30 8, 25 7, 27 5, 17 9)
OK (valor, rango y unidad coinciden): todas las de 23 (director-de-audio.md L326-345: duck_*, t_duck_*, t_fade_carga_s, t_entrada/salida_capa_s, t_cola_canal_s 8,0/3-12, t_interrupt_s 0,2/0,05-0,3, t_min_lect/cps_lect/t_max_lect 1,5/15/14,0 con 1-3/10-25/6-20); las de 28 (atmosfera-reactiva.md L251-273); las de 29 (shaders-y-efectos.md L181-193, x_h_min 0,032 / 0,0311-0,045); las de 24 (prompt-de-interaccion.md L145-157); 25 pausa_* (menu-de-pausa.md L259-267); 27 (pantalla-de-titulo.md L144-149); 17 hint_* (sistema-de-pistas.md L230-239); 26 L137-148; tam_min_px 24 [24,32] (opciones-de-accesibilidad.md L170).
Discrepancias:
- AVISO D1: registro `texto_min_px` (19) value 24, range [20,32] (entities.yaml L1786-1793) permite 20-23; contradice el suelo 24 de 30 R26 (opciones-de-accesibilidad.md L112, que cita "ordenador (19)"). `referenced_by: []`.
- AVISO D2: registro formula `sub_text_height_px` `output_range: "≥ 20"` (L473-480) y `sub_alto_min_px` 20 sin range (26 dice "≥ 18", L147); `sub_base_px` sin range (26 L146: 20-28/28-40/40-56).
- AVISO D3: fundido reducido: valor único 100 ms OK, pero cada GDD conserva knob con rango propio: 25 `t_velo_reducido_s` 0,05-0,2 (menu-de-pausa.md L260), 24 `fade_reducido_ms` 50-150 (L148), 26 `t_fundido_sub_s` 0,05-0,3 (L148), 29 `fade_reduced_s` "fijo"; el registro `reduce_motion_fade_s` (L1077) no tiene `range`. 30 R27 (L113) dice "se alinea a 100 ms" pero los rangos permiten divergir.
- INFO D4: no registrados: 24 `fade_reducido_ms`, 28 `pulso_resolucion_red` (0,15), 25 `t_velo_reducido_s` (solo en nota). Registro sin † por campo (solo en note): coherente en lo muestreado.

### (2) Dueño único
OK: reduce_motion_fade_s 0,1 s (6); t_interrupt_s, t_cola_canal_s, t_min_lect_s, cps_lect, t_max_lect_s (dueño 23; 26 L137 los cita con los mismos rangos y no los duplica; 21 L213 tacha su fila); x_h_min (29 = registro); settings_reset_all_keys = 18 claves en 25/6/30/registro; tam_min_px 24 (suelo único, 25 L57 y 24 L67 lo citan); contraste 4,5:1/3:1 (registro contraste_texto_min/ui_min; 25 AC-25-18 lo cita); pie_alto_min_px 24 = knob de 24 L154.
Deprecated:
- t_espera_voz_s: OK (status deprecated, referenced_by [], sustituta t_cola_canal_s; en 21 solo tachada L213 y en changelog).
- BLOQUEANTE-menor B1 (referencia viva): llamada-telefonica.md L113 sigue usando `t_corte_senal_s` (0,3†) en `T_compl`, contra su propia L211 («Retirada») y L150 (`t_interrupt_s` 0,2). Un implementador de F de T_compl lee 0,3 de una constante retirada. Corregir a `t_interrupt_s` (0,2) y recalcular T_compl.
- AVISO: registro `t_corte_senal_s` (L2110-2118) tiene `referenced_by: [marco-de-puzles.md]`; Grep no halla la constante en 17-marco ni en otro GDD vivo: referencia obsoleta en el registro (rango [0.1,0.6] antiguo conservado, ok al ser deprecated).

### (3) Discrepancias anotadas por el autor
- `sub_alto_min_px` 20 vs suelo 24 lógicos de 30: AVISO. 26 F3 L88, knob L147, AC-26-08 L171 usan 20 px físicos; 30 R26 afirma "26 cita el mismo suelo" (falso nominalmente). Numéricamente no hay violación: a 1080p `pequeno`=24 (= suelo); a 720p 24 lógicos = 16 reales y 26 da 20 (mayor). Es contradicción de definición (dos suelos), no de resultado. Alinear: 26 usa `tam_min_px` o 30 R26 declara la excepción.
- F2 de 24 cita 20: AVISO (cerca de BLOQUEANTE si se implementa literal). prompt-de-interaccion.md L98: "alto mínimo absoluto del pie es `pie_alto_min_px` 20† y el pie usa `max(28·s, 20)`" frente a knob L154 (24), D24-15 (L205), AC-24-14 (L176, ≥ 24). Errata viva en la fórmula; D24-15 dice «antes 20» pero F2 no se tocó.
- `piso_mega_db`: AVISO. Valor 12 dB sin range, `referenced_by: []` (entities.yaml L3112); 23 solo lo cita en L162 ("−12 dB") y AC-23-24 L376 (≤ 12); sin fila en Tuning Knobs (L326-346) pese a la regla de datos externos. Falta además signo coherente (12 en registro, −12 en 23). Añadir fila con rango (p. ej. −18…−6) y referenced_by.

### (4) Duplicados
- `name:` repetidos entre las ~382 entradas: ninguno (revisado el listado completo).
- Casi-duplicados por prefijo, INFO: lluvia_apagon_db (23) / lluvia_apagon (28) / d_lluvia_apagon_s; realce_lluvia_db / realce_lluvia_factor / d_realce_lluvia_s; unidades distintas, ok.
- Claves sin GDD que las cite (`referenced_by: []`): piso_mega_db, texto_min_px, t_fundido_sub_s y t_espera_voz_s (esta, correcta por estar deprecated). No se comprobaron todas las de `[]`.

## PARTE 2 escenarios (textos actuales)

### S1 Nueva partida desde el título con guardado que expira — PARCIAL
- 27 R11 (pantalla-de-titulo.md L65): confirmación también en `desconocido` (regla 9), foco en «Cancelar», llama `nueva_partida()` de 5; R12 L66: 5 pide `planta` a 4, el título solo bloquea y espera. AC-05 (L159) cubre `valida` sin `terminada`. OK.
- INFO: no pude leer R9 de 27 (L63, línea larga omitida por la herramienta) ni 5 R24/R29, 4 ni 21 AC-21-23b; no verifico que «desconocido» tras `t_espera_inspeccion_s` (3,0 s, L146-151) exija confirmación en la tabla ni que el guardado que expira no se sobrescriba. Sin BLOCKER visto.

### S3 Volver al título desde la pausa (llamada y revelación P5) — CERRADO con avisos
- 25 R28 (menu-de-pausa.md L119): Saliendo → `quit` en 5 → descarga total pedida; «antes de la descarga» 4 emite «descarga total solicitada» (4 R15, escena-de-planta.md L75) y 23 descarta voz/efectos pausados (23 R42e, AC-23-17 L369) y 26 retira bloques (26 R27, AC-26-18 subtitulos.md L181); «pausa cerrada» llega después y no reanuda nada. Resultado: ya no queda voz pausada ni subtítulo congelado. OK.
- Llamada (22): R26 (L71) congela máquina y cuenta; 22 no se suscribe a «descarga total solicitada», vive en la escena del despacho que se descarga (R19; 4 R15: suscriptores desaparecen sin error). Estado a medias (no `COMPLETADA`) al descargar: 22 solo describe COMPLETADA→INACTIVA (L17, L256); WARNING W1: no hay AC de descarga total con la llamada en `OPCIONES`/`SENAL`, ni dice que `V02`/timbre queden en el estado del guardado (AC-22-17 L239 cubre cierre, no descarga total).
- P5 en `RESOLVING`: 5/17-puzle R19 (puzle-5 L89, caso 12 L200): interrupción por descarga, `caja_c3` falso, `pendiente_revelacion` sigue verdadero. OK. Luces de 28: escena descargada. INFO: 28 no cita la descarga total.
- WARNING W2: 21 AC-21-29 (director-de-escenas.md L269) dice «con el tiempo de juego reanudado» durante la descarga, mientras 25 R28 emite «pausa cerrada» DESPUÉS de la descarga (reloj aún parado). Contradicción; inocua porque 21 está inactivo, pero el AC es ambiguo.
- INFO: 25 R28 numera el paso (4) «antes de la descarga» después del (3) «cuando 5 devuelve el control, 25 pide la descarga»: orden confuso, el texto aclara el orden real.

### S5 Cambiar escala de texto y tamaño de subtítulos desde la pausa — CERRADO (parcial en detalle)
- 25 L24-25, L72, L75, AC-25-23 (L305): «Sonido y pantalla» ofrece `subtitulos_tamano`; «Accesibilidad» ofrece `escala_texto_ui` (primera fila, «se aplica en el acto a esta misma pantalla, reflow, R13»). Ahora es posible desde la pausa. OK.
- WARNING W3: `escala_texto_ui` sigue "provisional" (25 OQ 5 L398, 6 OQ 15): si el usuario lo rechaza, «restablecer todos» pasa a 17 claves (el registro y 6/25/30 dicen 18). Dependencia abierta, no error.
- INFO: no leí 26 R19 ni la vista previa de subtítulos; no confirmo cómo se redimensiona un bloque congelado al cambiar `subtitulos_tamano` en pausa.

### S6 Nueva partida desde la pausa en la planta — PARCIAL
- 25 R30 (L121): fila solo con partida en curso y no sellada/terminada; diálogo con foco en «Cancelar»; Saliendo → `nueva_partida()` (5 R24); 4 abre carga `partida_nueva`, Entrada descarta la pila (1 R6); «carga iniciada» descarta voz pausada (23 R42) y bloques (26 R27); 21 AC-21-23b/c. Coherente, 5 D-8: no se borra al pulsar.
- WARNING W4: R30 marca «‡ 5 la admite también desde "En partida"»: dependencia por cerrar; no pude leer 5 R24 para ver si ya lo admite. Si no, la fila falla.
- INFO: no leí 5 R24, 21 AC-21-23b/c ni 1 R6.

## Clasificación resumen
- BLOQUEANTE (menor): B1 llamada-telefonica.md L113 `t_corte_senal_s` viva.
- AVISO: D1, D2, D3, registro t_corte_senal_s referenced_by obsoleto, sub_alto_min_px vs 24, F2 de 24 (L98), piso_mega_db sin knob/rango, W1, W2, W3, W4.
- INFO: D4, casi-duplicados, S1 sin verificación completa.

## VEREDICTO
- R9-B2 (registro): PARCIAL. Constantes de 17/23-30 ya presentes y coherentes con Tuning Knobs en lo muestreado, dueños únicos y sin duplicados, pero quedan B1, tres errores de rango/suelo (texto_min_px, sub_alto_min_px, F2 de 24) y piso_mega_db.
- Escenarios: S3 y S5 CERRADO (con W1-W3); S1 y S6 PARCIAL (por lectura incompleta, sin BLOCKER visto).

## NO LEÍDO
- pantalla-de-titulo.md regla 9 (L63) y 12-13 enteras; guardado-y-carga.md (5) enteros (R24, R29, R17); estado-y-bus-de-eventos.md salvo L47; entrada-y-controles.md (1 R6); subtitulos.md R19 y R27 completas (solo líneas citadas); director-de-audio.md R41/R42 íntegras; llamada-telefonica.md salvo líneas citadas; atmosfera-reactiva.md reglas; marco-de-puzles.md; jugador-en-primera-persona.md (6/otros); puzle-6, documentos-y-bolsillo, ordenador-correo-impresora (solo registro y 3 líneas); sistema-de-pistas.md reglas; sin muestreo de 24-29 más allá de Tuning Knobs; registro: formulas (L1-1050) no revisadas.
