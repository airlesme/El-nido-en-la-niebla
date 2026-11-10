# Review R14-C (perimetro 2d, 2e) - INFORME (version 2)

Lectura: Tuning Knobs de 23, 26, 30, 6, 25, 27, 28, 29, 24, 17; registro entities.yaml l. 401-1980 (entero hasta el bloque de puzles); 3 reglas 1-16; 23 F1-F3 y AC-23-01..17; 26 reglas 12/16/26/28 y F1; 29 F29-1..7; 28 R18; 21 R23; 9 F8; 18 (claves PISTA_/SUB_); 30 reglas 2, 13 y AC.

## BLOQUEANTE

- **B1. El registro no contiene NINGUNA constante de 17 ni de 23-30.** Grep `source: design/gdd/(sistema-de-pistas|director-de-audio|prompt-de-interaccion|menu-de-pausa|subtitulos|pantalla-de-titulo|atmosfera-reactiva|shaders-y-efectos|opciones-de-accesibilidad)` en `entities.yaml` = 0 resultados (ultimo bloque: GDD 22 y puzles). Consecuencia concreta: 26 declara "`t_min_lect_s` / `cps_lect` / `t_max_lect_s` (**de 23**, no se duplican aqui)" y 23 F3 los define con † pero ninguno esta registrado; igual `line_grace_s` (si registrado, de 9), `gap_s[2|3]` (17), `FLASH_MAX_HZ`/`FLASH_PAUSE_MIN_S`/`FLASH_DEPTH_FLOOR` (28), `fx_gpu_budget_ms` (29), `pulso_min_intervalo_ms` (24), `t_velo_s` (25), `t_fundido_base_s`/`t_atenuacion_s` (27), `N`... El propio 28 (l. 367) dice "`design/registry/entities.yaml` no revisado" y 25 W-9 lo reconoce. Sin registro no hay deteccion automatica de duplicados (ver A1-A4).
- **B2. Avisos nuevos que la regla 10 de 3 no declara** (regla 10: "Un emisor no declarado aqui es un defecto de documentacion"). La tabla de 3 (l. 43-55) solo tiene: fila 23 = «linea terminada», «linea sin audio», «linea fallida»; fila 25 = `pause_opened`; fila 9 sin «puzles configurados». Faltan:
  1. «pausa cerrada» / `pause_closed` (emisor 25; 25 AC-25-50 "«pausa cerrada» se emite **una vez**"; consume 23, AC-23-18). Grep "pausa cerrada|pause_closed" en estado-y-bus-de-eventos.md = 0.
  2. «linea iniciada» ‡ `{line_id, duracion_s, canal}` (emisor 23, R15; consume 26, AC-26-02).
  3. «sonido pedido» ‡ `{sound_id, fuente?, accion, valor?}` (emisores 7, 8, 10, 15, 19; 23 l. 484 lo pide como cambio a 3; 3 solo tiene «sonido de llamada pedido» de 22).
  4. «puzles configurados» ‡ (emisor 9; consume 17 `reset()`, 17 l. 411/438).
  5. Datos de «linea terminada» (causas `fin`/`corte`/`watchdog`/`interrumpida`, 23 R12-R14) no figuran en 3.
  Los cuatro estan marcados ‡ en sus GDD de origen pero 3 no los recoge: el contrato de avisos queda con 4 emisores/avisos sin propietario en la fuente unica. Recuento de HECHOS: sin cambio (ver INFO I1).

## AVISO

- **A1. Fundido con `reducir_movimiento`: mismo valor de 100 ms pero rangos y valores incompatibles, sin dueno unico.** Registro `reduce_motion_fade_s` 0,1 (dueno 6, sin rango; "fundido fijo de 100 ms"). 29 `fade_reduced_s` 0,1 "fijo (9, 14b)"; 24 `fade_reducido_ms` 100 (50-150); 25 `t_velo_reducido_s` 0,10 (0,05-0,2); 15 `fade_reduced_ms` 50-200 (cita 30 l. 166); 26 `t_fundido_sub_s` 0,15 (0,10 con reducir); **27 `t_atenuacion_s` 0,15 (0,05-0,3) "con `reducir_movimiento`/`reducir_sobresaltos`"** y AC-18 "los fundidos duran `t_atenuacion_s` (0,15 s)"; 21 `d_cierre` 0,1 con reducir (registro). 30 AC-30-12 exige "los fundidos duran 100 ms": 27 (0,15) y 26 (0,15 base) lo incumplen y los rangos de 24/25/15/27 permiten valores distintos de 100 ms. Proponer: un solo dueno (6 `reduce_motion_fade_s`) y los demas lo leen.
- **A2. Atenuacion que sustituye al parpadeo:** 21 `atenuacion_reducida_s` 0,6 (0,3-1,5; R23) y 28 R18 "atenuacion suave de 0,6 s (la pide 21)" coinciden; pero con `reducir_sobresaltos` 28 usa "rampas 0,30 s" (R18, tabla) que NO esta en sus Tuning Knobs (`t_caida_s` 0,08-0,30 es otro) y `d_apagon_red` 0,8 vs `ambiente_apagon_red` 0,10† tampoco figura en la tabla de Tuning Knobs de 28 (solo `d_apagon_red_s` y `ambiente_apagon`). Constantes con † fuera de tabla.
- **A3. 21 R23 contradice a 28 en la frecuencia del parpadeo:** 21 R23 "`LUCES_PARPADEO` (tres destellos de 0,15 s, ≈ 3,3 por segundo)"; 28 AC-28-01 "dura 1,15 s ±0,02 ... ≥ 0,50 s entre inicios (≤ 2,0 Hz)" (3x0,15 + 2x0,35 = 1,15 OK). 21 omite la pausa de 0,35 s (constante de 28); 3,3/s superaria el tope de 3/s de 30 (`tope_destellos_s`). 21 l. 45/226 "3 veces, 0,15 s" sin pausa.
- **A4. Interrupcion de senal: dos constantes para un mismo fundido.** 22 `t_corte_senal_s` 0,3 (rango 0,1-0,6, registro) vs 23 `t_interrupt_s` 0,2 (0,05-0,3) y R14 "dentro del ≤ 0,3 s† de 22". Rango de 22 (hasta 0,6) supera el techo de 23 (0,3). Dos nombres, dos duenos.
- **A5. Cola/espera del mismo canal de voz con dos duenos y mismo valor 8,0:** 23 `t_cola_canal_s` 8,0 (R10, 3-12) y 21 `t_espera_voz_s` 8,0 (registro: "Aplazamiento de una linea del mismo canal (F4)", 2-15). Rangos distintos; si uno cambia el otro se desfasa. Ademas 21 `t_linea_max_s` 8,0 (4-15) tercera constante de 8,0 s.
- **A6. Modelos de lectura sin fuente comun:** 17 F2 `lectura_pps` 3,0 palabras/s + `lectura_margen_s` 1,0, `note_min_s` 3,0, `note_max_s` 8,0; 23 F3 `cps_lect` 15 car/s, `t_min_lect_s` 1,5, `t_max_lect_s` 14,0; 26 `t_sub_max_s` 8,0 por pagina. Recalculo: PISTA_P2_N1 (15 palabras) = 15/3+1 = 6,0 s (17) pero ~80 car. -> 1,5+80/15 = 6,8 s con la formula de 23; no es error (distintos destinos) pero un jugador lector percibe dos velocidades. Los 8 ejemplos de 17 F2 son correctos.
- **A7. Suelo de tamano de texto: cinco valores.** 30 `tam_min_px` 18 ("24 en 19"); 24 `pie_alto_min_px` 20† (18-24); 26 `alto_min_px` 20 (>= 18); 25 "Tamanos de texto >= 24 px"; 19 `texto_min_px` 24 (20-32, registro). 30 dice que "los valores viven en el dueno" pero no designa cual manda para 24/26.
- **A8. 29 `x_h_min` rango inseguro:** Tuning Knobs 0,028-0,045 m; F29-3 exige x_h >= 14·2·d·tan(fov/2)/H = 0,0311 m (d=1,2; 90 grados; 1080p). Con 0,028 m: h_px = 12,6 px < 14 (AC-4 falla). Rango inferior debe ser >= 0,0311 (o fijar d). Tambien: 720p da 9,5 px bajo el liston, aceptado y documentado.
- **A9. Destellos: suma no presupuestada entre 24, 28, 29 y 30.** 24 `pulso_min_intervalo_ms` 340 (<= 2,94/s; 334 minimo); 28 `FLASH_MAX_HZ` 2,0 y `pausa_min_s` 0,35; 29 `highlight_pulse_hz` 1,25 (tope 2,0); 30 `tope_destellos_s` 3. Cada uno cumple 3/s por separado; solo AC-30-13 (video, PEAT "no verificada su disponibilidad") mide el conjunto. Ademas 28 AC-28-21 mide "promedio de pantalla" mientras 30 usa criterio WCAG de area > 25 %: metodos distintos.
- **A10. Ajustes nuevos sin dueno efectivo en 6 / conteos:** 6 define hoy 12 claves en «restablecer todos» (regla 8; AC-01 "trece" con `modo_ventana`) y el registro `settings_defaults` lista 13. Faltan en 6 y en el registro: `icono_grande`, `etiqueta_accion_visible` (24 ‡), `escala_texto_ui` (30 †, 6 OQ 15), `subtitulos_tamano`/`fondo`/`hablante` (26 ‡) -> 18 en «restablecer todos» segun 30 (l. 44); 30 AC-30-01 "BLOQUEADO". **Ademas `advertencias_vistas`† (27, "Escribe ajustes: si", Cambios requeridos a 6) no esta en la tabla maestra de 30 ni en la cuenta de 18**: hay 19 claves si se cuenta, y debe decidirse si «restablecer todos» la toca (no deberia). 25 usa "13 ajustes" para `UI_PAUSA_AJ_<CLAVE>` (25 review W-9) -> pasa a 19/20. Tres GDD (24, 26, 27) listan claves de 6 en SU Tuning Knobs con valor por defecto (p. ej. 26 `medio`/`translucido`/verdadero; 24 `falso`/`falso`): dos fuentes de defecto hasta que 6 las absorba.
- **A11. `mostrar_leyendas_gestos` (25, verdadero, bool)** vive como knob de datos de 25 pero el jugador puede querer cambiarlo (accesibilidad: leyendas bajo `interactuar`/`seleccionar`/`atras`); solapa conceptualmente con `etiqueta_accion_visible` (24/30). No esta en la tabla maestra de 30 (R2) ni en 6. Aclarar si es dato o ajuste.
- **A12. Rango de `t_velo_s` etc. en 25 con "art bible" como fuente y la nota ">= 24 px"** conviven con `guarda_apertura_s`, `repeticion_inicial_s`, `repeticion_s`, `guarda_captura_s`, `t_captura_s` todos † sin fuente (25 l. 252-256); ver seccion † abajo.
- **A13. 3 rotula "Este sistema" 20 hechos y tabla de interacciones, pero 17 deja `formulario_leido` y `memo_leido` sin lector** (17 D17-10) y pide a 3 cambiar la columna «Lee»; 3 no actualizado (no verificado cuerpo de la tabla de interacciones). Impacto menor.
- **A14. 26/23: AC-23-12 excluye el tiempo del subtitulo** ("el tiempo de subtitulo de 26 no forma parte de este AC") correcto, pero 26 `t_sub_max_s` 8,0 (pagina) frente a 23 `t_max_lect_s` 14,0 y `fallback_s` VO_G_07 14,0: coinciden solo por casualidad (14,0 en ambos); si `t_max_lect_s` se baja a < 14 la linea sin audio de 14,0 de 9 y 26 ya no coincide con 23. 23 AC-23-02b usa 14,0 como tope, no como fallback.

## Formulas recalculadas (>= 10)

| # | Formula | Resultado | Veredicto |
|---|---|---|---|
| 1 | 23 F1: paso 15/20, db_min -40: -40·(1-0,75) | -10 dB; rampa 10 dB/0,05 s = 200 dB/s; paso 1 = -38 (rango "-38...0") ; 2 dB/paso | OK |
| 2 | 23 F2 ducking Music con VO_V_08 6 s: 6 dB/0,15 s = 40 dB/s; retencion hasta 6,3; 6/0,8 = 7,5 dB/s -> 0 a 7,1 s | AC-23-11 | OK |
| 3 | 23 F3: 13B (5 car) 1,5+5/15 | 1,83 | OK |
| 4 | 23 F3: 13D (63) | 1,5+4,2 = 5,70 | OK |
| 5 | 23 F3: V_12E (19) | 1,5+1,27 = 2,77 | OK |
| 6 | 23 AC-23-02b: 300 car -> 21,5 clamp 14,0; +2 pausas·1,2 | 16,4 (pausas tras clamp) | OK |
| 7 | 23 F4 + 9 F8: VO_G_07 17 s, fallback 14 + grace 2 | corte a 16,0; sin 23: 16,0+2,0 = 18,0 (AC-23-08 = 9 F8 senal perdida) ; nominal 1,2+0,8+14 = 16,0 | OK |
| 8 | 26 AC-26-05: A 26 car + B 96 car sobre 14,0 - 1,2 pausa = 12,8: A = 26/122·12,8 | 2,73; B 10,07; paginas 4,93+5,14 | OK |
| 9 | 26 F1: "Lo sé" audio 0,8 s + cola 0,4 -> max(1,2; 1,83) | 1,83 (AC-26-03); 13D audio 4,0 -> max(4,4; 5,70) = 5,70; VO_G_07 audio 14,0 -> 14,4 | OK |
| 10 | 26 F3 720p: medio 32·(720/1080) | 21,3 -> 21 px; pequeno 24·0,667 = 16 -> suelo `alto_min_px` 20 (AC-26-08) | OK (coherente con 24 `ui_escala_min` 0,67) |
| 11 | 28 F1/AC-28-01: 3·0,15 + 2·0,35 | 1,15 s; inicios cada 0,50 s = 2,0 Hz (<= `FLASH_MAX_HZ`) | OK |
| 12 | 29 F29-2: (0,80+0,05)/(0,06+0,15·0,30+0,05) | 5,48; sin reflejo 7,7; preview o=0,8: 6,4 y 4,53; o=0,7: 5,7/4,05; C_res 1,27 | OK |
| 13 | 29 F29-3: 0,032·1080/(2·1,2·tan 35 grados) | 20,6 px; a 90 grados 14,4 px; a 720p 9,6 | OK (rango inferior de `x_h_min` ver A8: ERROR de rango) |
| 14 | 29 F29-5: round(H·0,0035) clamp 3..6 | 1080 -> 4; 720 -> 3; 2160 -> 6 | OK |
| 15 | 29 F29-7: 0,20+0,10+0,15+0,05; draw calls 1+4+1 | 0,50 ms; 6 | OK |
| 16 | 29 F29-4: I = 0,6 + 0,3·0,5·(1+sin) | pico 0,9, valle 0,6; ciclo 1/1,25 = 0,8 s | OK |
| 17 | 17 F2: palabras/3,0 + 1,0, min 3,0 max 8,0 (8 claves) | 3,0/6,0/5,33/5,33/5,0/3,0/3,0/3,67 | OK (todos) |
| 18 | 24 `pulso_min_intervalo_ms` 340 | 2,94 pulsos/s <= 3 | OK |
| 19 | 21 R23 "3 destellos de 0,15 s ≈ 3,3/s" vs 28 | 28: 2,0 Hz con pausa 0,35 | ERROR en 21 (A3) |
| 20 | 30 R13 P6: 0,3 + 1,6 | 1,9 s (registro `BOX_C4_OPEN` 1,6) | OK |
| 21 | Registro: BOX_OPEN_MAX = 3,0 - 1,2 - 0,2 | 1,6; C1..C4 (1,6/1,4/1,4/1,6) <= 1,6 | OK |
| 22 | 23 R12 / 9: `line_grace_s` 2,0 | 23 lo "lee de los datos"; registro dueno 9 | OK (sin duplicar) |

## Conteos

- 20 hechos: registro `game_state_facts` enumera 20 (6 + 3 pos + 4 caja + pendiente + caja_completa + carta + llamada x3 + t4_decision). Ninguno de los 9 GDD nuevos anade ni propone hechos (17: "no escribe hechos ni emite avisos propios"; 25: "No cambia ningun hecho"; 27 "Escribe hechos: nada"; 28 memoria volatil; `advertencias_vistas` es ajuste, no hecho). **Recuento 20 intacto.**
- 8 `PISTA_*`: 18 R20 y 17 l. 43 coinciden con registro `hint_key_count` 8 (P1_N2, P2_N1, P4_N1, P4_N3, P5_N1, P5_N2, P6_N1, P6_N2). 17 pistas declaradas = 3x5 + 2.
- `SUB_BREATH_BROKEN` es la unica `SUB_*` de 18 (R22; "no es del §12"); 26 usa `UI_SUB_HABLANTE_*` y `UI_SUB_MUESTRA` ‡ (prefijo UI para no chocar), claves nuevas aun no en 18 (18 l. 140 solo lista SUB_BREATH_BROKEN; no verificado si 18 ya incorpora las UI_SUB_*).
- 28 entradas del §12: 18 R15 "28 entradas del §12"; registro MEGA_03 "linea 28 (megafonia 3 de 28 entradas, 21 audibles)". Coherente; no recontado fila a fila (NO LEIDO el §12 del slice).
- Ajustes de 6: 12 en «restablecer todos» / 13 en AC-01 / 6 faltantes (30) -> 18/19; + `advertencias_vistas` (27) -> ver A10.

## † inventados sin fuente en los 9 GDD nuevos (todos marcados †, sin origen en slice ni art bible)
- 23: casi toda la tabla de Tuning Knobs (columna "Valor †"): `rampa_vol_s` 0,05, ducking -6/-4/-4 y -3/-2/-2, `duck_total_min_db` -12, `silencio_parcial` -4/-3, `pausa_amb_db` -6, `atenuacion_carga_db` -18, `t_cola_canal_s` 8,0, `t_watchdog_s` 1,0, `t_linea_audio_max_s` 20,0, `t_min_lect_s`/`cps_lect`/`t_max_lect_s`/`pausa_segmento_s`, `atenuacion_sobresalto_db` -6, `techo_limitador_dbfs` -10, `max_voces_total` 24, memoria 10/24/40 MB. Excepciones con fuente: `lluvia_apagon_db`/`d_lluvia_apagon_s`/`t_lluvia_vuelve_s` (slice C.7, 0,4 y 2,0), `line_grace_s`.
- 25: `guarda_apertura_s` 0,15, `repeticion_inicial_s` 0,4, `repeticion_s` 0,12, `guarda_captura_s` 0,25, `t_captura_s` 8. (`t_velo_s` 0,35 y `t_velo_reducido_s` 0,10 tienen art bible.)
- 27: `t_fundido_base_s` 0,8, `t_atenuacion_s` 0,15, `t_espera_inspeccion_s` 3,0, `creditos_paginas` 1.
- 28: `d_apagon_red_s` 0,8, `f_apagon`, `ambiente_apagon`, `f_parpadeo` 0,40/0,65, `f_tubo`, `t_entrada/salida_reflejo_s`, `t_activo_min_s`, `umbral_giro_deg` 45, `T_giro_s` 0,5, `pulso_resolucion`, `realce_lluvia_factor` 1,3, `n_max_ventanal` 200, `lluvia_vel_red` 0,5. (Slice: `d_apagon_s` 0,4, `d_restaurar_s` 2,0, `retardo_reflejo_s` 0,6, `duracion_reflejo_s` 3,0, `parpadeo_veces` 3, `t_caida_s` 0,15, `pausa_min_s` 0,35 como regla de fotosensibilidad.)
- 29: las 13 constantes de Tuning Knobs llevan origen "29†" excepto `fragment_fade_s` (12/slice B.2) y `fade_reduced_s` (9). `fx_gpu_budget_ms` 0,5 sin medir ni hardware de referencia (Q9, "banda 1-2 ms no verificada").
- 24: `pulso_rechazo_min` 0,40, `pulso_min_intervalo_ms` 340 (derivado de 3/s, con fuente), `etiqueta_offset_px` 12, `pie_*` (28/20/0,85/250), `pie_ancho_max` 0,60. 17: `gap_s[2]` 20, `gap_s[3]` 40, `gap_s[2]` P6 10, `lectura_pps`, `lectura_margen_s`, `note_*`, `queue_max` (el slice solo fija 60 s de P3 N3 y 10/20 de P6). 26: casi todos (`t_cola_sub_s` 0,4, `t_sub_sfx_*`, `sub_*`) salvo bases de tamano; 4,0 s de `SFX_BREATH_BROKEN` es de 22 AC-22-25 (†). 30: 3 de tope de destellos (art bible/WCAG con fuente), 44 px (= `pick_min_px`).
- Ninguno bloquea por si solo, pero el conjunto de 23 define la mezcla entera sin un solo dato de prueba: debe marcarse como "a validar en playtest" y registrarse (B1).

## INFO
- I1. Recuento de 20 hechos sin cambio; 3 regla 1 no necesita reedicion por los 9 GDD nuevos. 17, 25, 27, 28, 29, 30 declaran explicitamente no escribir hechos.
- I2. Triple fundido de 0,8 s: 4 `scene_fade_duration` 0,8; 21 `d_cierre` 0,8; 27 `t_fundido_base_s` 0,8 (27 lo declara: "independiente: si 21 cambia, revisar"). Aceptable, pero tres duenos.
- I3. 28 `realce_lluvia_factor` 1,3 (amplitud) vs 23 `realce_lluvia_db` +3,0 (1,3 = +2,3 dB en amplitud, +1,1 dB en potencia): dos expresiones de un mismo realce, 28 remite a 23 para el audio; sin conversion declarada.
- I4. 23 `d_lluvia_apagon_s` 0,4 = 28 `d_apagon_s` 0,4; 23 `t_lluvia_vuelve_s` 2,0 = 28 `d_restaurar_s` 2,0 = 21 `retardo_restaurar_s` 2,0 (distinto concepto, mismo numero) = `elevator_activation_delay_s` 2,0: coherente con slice C.7; OK.
- I5. 30 R13 coincide con registro: `reset_after_s_P1` 1,5, `hold_s_P5` 0,8, `BOX_C4_OPEN` 1,6 + 0,3 = 1,9 s.
- I6. Registro: `volume_db_min` -40 (rango -60...-30) vs 23 F1 "db_min -40†" consistentes; `volume_steps` 20 = `N_pasos`; `multiplicador_pie` 1,0 (1,0-3,0) coincide entre 6, registro y 30.
- I7. 30 pasa la lista "solo lectura" (`fundido_reducido_ms` etc.) a sus duenos: buen patron; mismo patron deberia usarse en A1.

## NO LEIDO
- Tuning Knobs de 1, 2, 4, 5, 7, 8, 9 (excepto F8 y knobs citados por el registro), 10, 11-16, 18, 19, 20, 21, 22 (solo registro y fragmentos citados); ningun GDD leido entero.
- slice-v0.3.md (§12 de 28 entradas, C.x tiempos) y art bible (§7.4, §8.7); tabla de interacciones de 3 (l. 86-126) y su columna «Lee/Escribe»; cuerpo de 23 reglas 1-47 salvo R7-R15; 26 reglas salvo 12/16/26/28; 25 reglas; 27 reglas; 28 F1-F8; 24 F2; 17 F1/F3; Open Questions y Decisiones de todos.
- No verificado: coste de shaders de 29 frente a F8 de 28 (presupuesto de iluminacion: `max_luces_visibles` 8 / `max_luces_sombra` 2); tiempos de 21/22 contra slice C.4/C.7 mas alla de la linea de tiempo del registro (4,8/10,8/16,4-44,8); si 18 ya incorpora `UI_SUB_*` ‡; recuento fila a fila de §12.
