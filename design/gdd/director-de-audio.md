# Director de audio (sistema 23)

> **Status**: Borrador (lote autónomo)
> **Author**: Audio Director (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: El espacio expresa la emoción (lluvia, drone y silencio como lenguaje) · Tensión sin castigo (sustos sonoros atenuables; ningún fallo de audio bloquea) · Ambivalencia sin moral binaria (ningún sonido clasifica una decisión; la voz del Guardián no suena ni amable ni amenazante) · Autonomía como progresión (la voz comenta, no guía) · Información incompleta (el audio no añade hechos)

> **Convenciones:** † = valor propuesto, a validar en playtest. ‡ = contrato que debe confirmar el GDD del sistema afectado. «Regla N de X» = regla N del GDD X. Los avisos entre « » son los del bus (3). IDs del documento (`VO_G_12A`, `SFX_CARD_OK`, `SPK_D01C`, `MEGA_03`…) tal cual. **No se duplica el catálogo de textos**: claves y campo `audio` de cada línea son de 18; 23 posee solo el catálogo de **sonidos** (sección «Datos»).

## Summary

El director de audio es el nodo persistente que reproduce todo lo que suena: voces (`VO_V_*`, `VO_G_*`, `MEGA_*`), efectos (`SFX_*`), ambiente (lluvia, ventilador) y el drone del edificio (la única música del slice). Reacciona a los avisos del bus (3) y a la señal directa `paso` del Jugador, aplica los tres volúmenes por pasos de Ajustes (6), baja drone y lluvia bajo la voz (ducking) y responde a cada «línea pedida» con exactamente una de tres señales: «línea terminada», «línea sin audio» o «línea fallida». Esas señales impiden que una escena, la llamada o una secuencia de puzle se cuelguen por un problema de audio.

> **Quick reference** — Layer: `Core` (categoría `Audio`) · Priority: `Vertical Slice` · Deps: `3`, `6`, `18` (duras) · blanda `2` · Escribe: ningún hecho · Emite: «línea terminada», «línea sin audio», «línea fallida», «línea iniciada» ‡

## Overview

23 es un nodo persistente (fuera de toda escena; regla 1 y AC-01 de 4) que se suscribe una vez al bus. Hace seis cosas: (1) **voces**: atiende «línea pedida» de 9, 8, 21 y 22, resuelve el audio con el campo `audio` de 18, la reproduce en uno de tres canales (Vera, megafonía, Guardián) y responde; sin audio o con fallo responde al momento con una duración de lectura calculada del texto de 18; (2) **efectos**: «feedback de puzle», «sonido pedido» ‡, «efecto de escena pedido» y `paso`; (3) **ambiente y música**: lluvia por estancia, ventilador y drone, que se reanudan tras cada carga leyendo los hechos, nunca recordando; (4) **mezcla**: volúmenes de 6, ducking, silencio parcial en vistas y `reducir_sobresaltos`; (5) **capa de teléfono y fuentes posicionales** (`SPK_D01C`, `SPK_V02` ‡, `C01`); (6) **presupuesto**: voces simultáneas y memoria, con prioridades que nunca roban una voz ni un feedback de puzle.

23 **no** decide cuándo suena una línea (lo piden 9, 8, 21, 22), **no** muestra subtítulos (26), **no** escribe hechos ni guarda, y **no** dibuja lluvia ni luces (28, 29).

### Evaluación frente a los pilares

| Pilar | Qué aporta el audio | Hueco de audio |
|---|---|---|
| **Ambivalencia sin moral binaria** | `SFX_STAMP` suena igual al aceptar y devolver (P4); P6 solo `SFX_LOCK_CLICK`; sin fanfarria ni tono de error agudo; voz del Guardián seca, sin efecto propio salvo la banda del altavoz o auricular | Se protege **por omisión** (R30); el timbre convertido de la voz es decisión de grabación, no de 23 |
| **El espacio expresa la emoción** | El que más sostiene: lluvia por estancia, drone sin melodía, silencio parcial en puzles, sillas y tecleo lejanos, silencio de línea en la llamada | El slice no define la lluvia durante el apagón y la llamada; decisión por defecto (R22, OQ 1) |
| **Autonomía como progresión** | Ningún sonido señala el siguiente paso; el audio nunca espera la elección del jugador (la llamada admite elegir interrumpiendo, R14) | Sin hueco: el audio no tiene función de guía |
| **Tensión sin castigo** | `reducir_sobresaltos` atenúa cuatro sustos (R38); ninguna señal bloquea (R7, R8); sin audio el tiempo es idéntico; el susto es un sonido que se acerca y no llega (R20) | El golpe de puerta **dentro** de `VO_G_07` solo se limita, no se quita (R39, OQ 2) |
| **Información incompleta** | — | **El audio no contribuye a este pilar** salvo no filtrando información: ningún sonido revela una solución y `SFX_CLICK_SUBTLE` suena igual para cualquier interacción sin efecto |

## Player Fantasy

Una planta vacía de noche. Llueve fuera, y se oye más en el pasillo y el Archivo que tras la puerta de una sala. Abajo, constante, el zumbido grave del edificio, sin melodía que diga qué sentir. La voz de Vera suena dentro de la cabeza, seca y cercana; la megafonía, desde el techo del pasillo, lejana y plana. Los objetos suenan a madera, metal y papel, sin recompensas musicales: una pieza encaja con un golpe seco, no con una fanfarria. Casi siempre hay silencio suficiente para oír una pista, una silla que rueda lejos o un teclado donde no debería haber nadie. El jugador no siente «el sistema de audio»: siente un edificio **vivo y callado**. Y al descolgar el teléfono, el mundo se estrecha a una línea, un silencio, una respiración y una voz que no explica nada.

MDA: **Sensation** (silencio como lenguaje) y **Narrative** (la llamada). SDT: **Competencia** (cada acción tiene respuesta sonora legible) y **Autonomía** (nada suena para dirigir). Tests de pilar: entre un motivo musical al resolver un puzle y el golpe seco de la pieza, el golpe; entre un susto fuerte y un sonido que se acerca y nunca llega, el sonido (pilar 4); entre esperar a que acabe el audio o seguir con el subtítulo, seguir.

## Detailed Rules

### A. Identidad, buses y paleta

1. **Nodo persistente.** Vive bajo la raíz, sobrevive a las cargas y arranca tras 3 y 6 («ajustes aplicados»). No guarda referencias a nodos de la planta: las fuentes se resuelven por ID en cada «escena lista» (R19). Sin 2 (blanda) funciona: oyente en el origen y sin pasos.
2. **Paleta.** Acústica y seca. Voces sin reverberación ni efectos de carácter; madera, metal y papel; ruido filtrado (lluvia); un drone grave sin melodía (Suno, instrumental, slice §14 y §18). **Sin *stingers* ni música reactiva** (R30). El silencio es diseño: 23 nunca rellena un hueco.
3. **Buses** (árbol fijo creado al arrancar; esquema técnico en un ADR):

   | Bus | Hijos | Lleva | Volumen del jugador |
   |---|---|---|---|
   | `Voice` | `Voice_Vera`, `Voice_Mega`, `Voice_Guardian` | `VO_V_*`, `MEGA_*`, `VO_G_*`, muestra de volumen | `vol_voces` |
   | `Effects` | `Fx_Puzzle`, `Fx_World`, `Fx_Steps` | `SFX_*` y efectos de escena | `vol_efectos` |
   | `Ambience` | — | `AMB_RAIN`, `AMB_FAN` | `vol_efectos` |
   | `Music` | — | `MUS_DRONE` | `vol_musica` |

   `Master` queda a 0 dB: **no existe `vol_maestro`** en el catálogo de 6 (D23-11, OQ 4). Cierra la OQ 7 de 6: lluvia y ventilador van a `vol_efectos`; el drone, a `vol_musica`.
4. **Contenido.** Las líneas se piden por ID de 18; su audio es el campo `audio` de 18. Los efectos, por ID del catálogo de 23 (`audio_catalog.json`). 23 pide a 18, por `line_id`, solo el texto renderizado y la pausa previa de cada segmento (F3).

### B. Entradas

5. **Suscripciones** (nombres de 3 salvo ‡):

   | Aviso | Emisor | Reacción |
   |---|---|---|
   | «línea pedida» `{line_id, fuente?, fallback_s?, puzzle?}` | 9, 8, 21, 22 | Voces (C) |
   | «feedback de puzle» `{puzzle, sound_id, text_key?, element?}` | 9 | `sound_id` en `Fx_Puzzle` |
   | «sonido pedido» ‡ `{sound_id, fuente?, accion, valor?}` | 7, 8, 10, 15, 19 | `accion` ∈ `play`, `stop`, `set`, `interrupt` (D) |
   | «sonido de llamada pedido» ‡ | 22 | Alias de «sonido pedido» (`SFX_PHONE_BUZZ`, `SFX_CALL_BREATH`, `SFX_BREATH_BROKEN`, `SFX_PHONE_END`) |
   | «efecto de escena pedido» | 21 | Efectos con sonido (R21); ignora los visuales |
   | «estado de objeto pedido» | 21, 22 | `V02`: `vibrando` inicia el bucle `SFX_PHONE_BUZZ`; `reposo`/`en_llamada` lo para. Puertas del ascensor: `SFX_ELEVATOR_DOORS` ‡ |
   | «vista cercana abierta/cerrada» | 7 | Silencio parcial (R29) |
   | «carga de escena iniciada», «escena lista», «descarga total solicitada/completada» | 4 | Carga (I) |
   | «estado restablecido», «estado restaurado» | 3 | R45 |
   | `pause_opened` ‡, «pausa cerrada» ‡ | 25 | R41 |
   | Avisos de cambio de Ajustes | 6 | `vol_*`, `reducir_sobresaltos` (H) |

   Más la **señal directa** `paso(superficie, intensidad)` de 2 (regla 31 de 2). 23 **lee** solo `caja_completa` y `llamada_completada`, solo al reanudar (R43). No lee `carta_variante`, `t4_decision` ni `respuesta_llamada`: quien pide la línea elige su variante.
6. **Sin lógica ajena.** Un ID de sonido desconocido se ignora y se registra; una `fuente` desconocida suena en 2D y se registra.

### C. Voces y señales de respuesta

7. **Contrato de respuesta (cumple los ‡ de 3, 9, 21, 22).** Cada «línea pedida» aceptada recibe **exactamente una** señal con su `line_id`:

   | Señal | Cuándo | Carga |
   |---|---|---|
   | «línea terminada» | `finished` del reproductor (marco 9, regla 37), corte con fundido (F4), watchdog o interrupción (R14) | `{line_id, motivo}`: `fin`, `corte`, `watchdog`, `interrumpida` |
   | «línea sin audio» | `audio` nulo, fichero inexistente o sin dispositivo (R46) | `{line_id, t_lectura_s}` (F3) |
   | «línea fallida» | Fichero existente que no carga o no decodifica, fallo al empezar o a mitad, o cola llena (R10) | `{line_id, t_lectura_s}` |

   Se emiten como avisos encolados (regla 11 de 3), nunca dentro de la entrega de la petición: como máximo **un fotograma** después. «Sin audio» y «fallida» salen **al momento**; quien las recibe espera su propio tiempo (9 y 22: `fallback_s`; 21 y 26 pueden usar `t_lectura_s`). Nunca dos señales por línea: tras «fallida» a mitad no hay «terminada».
8. **Nada bloquea.** Si 23 no emite nada, los consumidores siguen por sus topes (`fallback_s + line_grace_s` en 9 y 22; `t_linea_max_s` en 21). 23 no espera a 26.
9. **Tres canales por prefijo, simultáneos.** `VO_V_*` → `Voice_Vera` (interior, 2D, seca); `MEGA_*` → `Voice_Mega` (diegética); `VO_G_*` → `Voice_Guardian`. Sin espera entre canales (slice C.1 y C.8; DT-18 de 21).
10. **Un canal, una línea.** Una segunda petición al mismo canal se **encola** (cola de 1) con tope `t_cola_canal_s` (8,0†, como `t_espera_voz_s` de 21); con cola ocupada o tope superado, «línea fallida» (`canal_ocupado`, registrado). Es una defensa: 21 ya aplaza. Una petición con el **mismo `line_id`** que la activa o encolada se ignora y registra; la señal única llega a todos.
11. **Fuente por defecto** del catálogo (la `fuente` del aviso, si existe, gana): `VO_G_07` → `SPK_D01C`; `MEGA_*` → `C01`; `VO_G_12*`, `VO_G_13*`, `VO_G_14_*` → `SPK_V02` (auricular); `VO_V_*` → ninguna (2D). 9 pide `VO_G_07` sin fuente.
12. **Techo y corte.** Si la petición trae `fallback_s`, `techo_s = fallback_s + line_grace_s` (2,0†, un solo valor compartido con 9 y 22, leído de los datos). Si el audio dura más, 23 **corta con fundido** `t_fade_corte_s` (0,3†) y emite «terminada» (`corte`) en `techo_s` (F4).
13. **Watchdog.** Sin `finished` a `duración + t_watchdog_s` (1,0†), o pasado `t_linea_audio_max_s` (20,0†), detiene el reproductor y emite «terminada» (`watchdog`).
14. **Interrumpir.** `interrupt` (22: `SFX_BREATH_BROKEN`, `VO_G_14_*`, `SFX_PHONE_BUZZ`) baja el sonido en `t_interrupt_s` (0,2†, dentro del ≤ 0,3 s† de 22); si era una línea, emite «terminada» (`interrumpida`). Interrumpir lo que no suena no es un error. Cumple los ‡ de 22 (reglas 5 y 15).
15. **«Línea iniciada» ‡** `{line_id, duracion_s, canal}`: se emite cuando una línea con audio **empieza a sonar** (puede esperar en cola). No es respuesta; permite a 26 sincronizar el subtítulo. Opcional.
16. **Pausa de `VO_G_07`.** Con audio, la pausa entre sus dos segmentos va **dentro del fichero**; sin audio, F3 usa `pausa_segmento_s` (1,2†). Cierra la OQ 3 de 18.

### D. Efectos, prioridades y polifonía

17. **Efectos.** «Feedback de puzle» y «sonido pedido» llevan un `sound_id`; 23 aplica bus, trim y prioridad del catálogo. La `fuente` es un ID de escena (`C01`, `D01`, `V08`…) resuelto contra los marcadores de la escena cargada. `sound_id` nulo no suena.
18. **Anti-duplicado.** Dos peticiones idénticas en `t_dedup_s` (0,05†) suenan una vez (no aplica a pasos).
19. **Marcadores de escena.** La escena aporta nodos con `audio_id` (`C01`, `SPK_D01C`, `V02`…), volúmenes `audio_room` (`V`, `C`, `A`, `B`, `D`, `R`) y etiquetas de superficie. 23 los indexa en cada «escena lista» y los descarta en «carga iniciada». La estancia se deduce de la **posición del oyente** (de 2) en esos volúmenes, no de «zona activada» (D23-17); sin etiqueta rige `C`.
20. **Sonidos que se acercan y no llegan.** `SFX_CHAIRS_ROLL` y `SFX_TYPING_FAR` (3D, sin imagen) se mueven del Archivo al pasillo y quedan a ≥ `d_no_llega_m` (6,0†) del oyente en D; entran con rampa `t_entrada_susto_s` (1,0†).
21. **Efectos de escena (21) con sonido:**

    | `id_efecto` | Acción de 23 |
    |---|---|
    | `SILLAS_RODANDO`, `TECLEO_LEJANO` | `SFX_CHAIRS_ROLL` ‡, `SFX_TYPING_FAR` ‡ (R20) |
    | `TELEFONO_PULSOS` | 3 pulsos de 1,0 s de `SFX_PHONE_BUZZ` desde `V02` (no es un estado de `V02`) |
    | `TELEFONO_SUENA` | Inicia el bucle de `SFX_PHONE_BUZZ` en `V02` si no suena ya (idempotente); audible desde el pasillo |
    | `LLUVIA_REALCE` (8,0 s†) | +`realce_lluvia_db` (3,0†), rampa 1,0 s, y regreso |
    | `LLUVIA_CESA` (6,0 s) | Lluvia a silencio en la duración dada |
    | `LLUVIA_VUELVE` | Lluvia a su nivel de estancia en `t_lluvia_vuelve_s` (2,0†) |
    | `LUCES_APAGON` | Deriva el apagón (R22) |
    | `PUERTAS_ASCENSOR_ABREN` | `SFX_ELEVATOR_DOORS` ‡ |
    | `LUCES_PARPADEO`, `LUCES_RESTAURAR`, `REFLEJO_RETARDADO` | Ignorados (28 y 29) |

    28 pone la imagen de la lluvia; 23 solo su audio: un mismo aviso, dos sistemas.
22. **Lluvia en el apagón (defecto; OQ 1).** «Vuelve la lluvia» (C.7) implica que se fue: con `LUCES_APAGON`, la capa baja a `lluvia_apagon_db` (−60†) en `d_lluvia_apagon_s` (0,4†; al instante si la duración es 0, reanudación) y regresa con `LLUVIA_VUELVE`.
23. **Prioridades y polifonía (F6).**

    | Prio. | Contenido | Robable |
    |---|---|---|
    | P1 | Voces | **Nunca** |
    | P2 | `Fx_Puzzle`, `SFX_UNLOCK*`, `SFX_REJECT`, `SFX_CLICK_SUBTLE`, sonidos del teléfono de la llamada | Solo por otro P2 si hay más de `max_sfx_p2` (4†) |
    | P3 | `Fx_World` (puertas, caja, impresora, sillas, tecleo, `SFX_CARD_OK`) | Sí, el más antiguo |
    | P4 | `Fx_Steps` | Sí; además `t_paso_min_s` |
    | P5 | Lazos de ambiente y drone | Nunca (reservados) |

    Reservas: 6 lazos (drone, lluvia, realce, ventilador, teléfono, giro de P5), 4 voces (tres canales y muestra), 8 efectos puntuales, 2 pasos. `max_voces_total` = 20†.
24. **Pasos (F5).** `paso(superficie, intensidad)` reproduce una variante de `SFX_STEP_<superficie>` sin repetir la anterior, con ganancia de F5 y tono ±3 %†. Superficies: `moqueta` (planta 9), `baldosa` (Recepción), `default` (D23-14, OQ 5). Suenan con cualquier `balanceo_camara`.
25. **Muestra de referencia del volumen (cierra la OQ 8 de 6).** Con el menú abierto y un cambio de `vol_voces` o `vol_efectos`, suena una muestra del bus, como mucho una cada `t_muestra_min_s` (0,4†): `SFX_CLICK_SUBTLE` para efectos; `UI_VOL_MUESTRA` ‡ (frase neutra grabada, sin subtítulo, fuera del §12; la pide 23 a 18) para voces. Para `vol_musica` no hace falta: el drone sigue en pausa (R41). Sin `UI_VOL_MUESTRA`, se usa `SFX_CLICK_SUBTLE` y se registra.

### E. Ambiente y música

26. **Capas.** `AMB_RAIN` (lazo, nivel por estancia, F8); `AMB_FAN` (3D en `V`, alcance 8 m†, desde la escena 1); `MUS_DRONE` (2D, **constante en todo el slice**, solo ducking, carga y pausa). Ningún estado del juego cambia el drone (R30).
27. **Arranque y fin.** Arrancan en «escena lista» con fundido `t_entrada_capa_s` (3,0†). Sobreviven a `planta` → `recepcion` (drone y lluvia no se reinician; el ventilador se detiene). En «descarga total solicitada», fundido de salida `t_salida_capa_s` (1,5†).
28. **Lluvia por estancia** (slice §14, nivel relativo †): `A` y `C` 0 dB (más intensa); `V` −6; `B` y `D` −9 con paso bajo `lp_sala_hz` (2.500†); `R` −6. Cambio de estancia interpolado en `t_estancia_s` (1,5†).
29. **Silencio parcial.** Con una vista cercana abierta (7), `Ambience` −4 dB y `Music` −3 dB (†), rampa 1,0 s; al cerrar vuelven. No afecta a voces ni a feedback (slice §14: silencio parcial en puzles).
30. **Nada reactivo.** Ningún sonido de «acierto», «error», «logro» o «decisión»; el feedback son los efectos físicos del objeto (B.7). `SFX_REJECT` es corto, seco y grave, sin tono agudo (marco 9). Protege los pilares *Ambivalencia* e *Información incompleta*.

### F. Ducking

31. **Ducking bajo voz (F2).** Mientras suene una línea **con audio**, se bajan otros buses; con varias activas rige la más profunda (no se suma). `Voice`, `Fx_Puzzle` y `Fx_Steps` no se bajan nunca.

    | Canal activo | `Music` | `Ambience` | `Fx_World` |
    |---|---|---|---|
    | `Voice_Vera`, `Voice_Guardian` | −6† | −4† | −4† |
    | `Voice_Mega` | −3† | −2† | −2† |

    Ataque 0,15 s†, retención 0,3 s†, liberación 0,8 s†. La suma de ducking y silencio parcial se limita a `duck_total_min_db` (−12†).
32. **Llamada.** Sin ducking especial: la lluvia ya está en silencio (R22), el drone sigue bajo, y las pausas de 2,0 s (silencio y respiración) son de 22; 23 no rellena el hueco.

### G. Teléfono y fuentes posicionales

33. **Perfiles** (†, hasta el audio real):

    | Fuente | Tipo | Tratamiento |
    |---|---|---|
    | `SPK_D01C` | 3D en la caja (10) | Pasabanda 250–5.000 Hz, saturación suave, cercana; a 2 m cae −6 dB y se oye en toda `D`; respeta `vol_voces` |
    | `SPK_V02` ‡ | Auricular 2D en la llamada; 3D al sonar | Pasabanda 300–3.400 Hz, mono, sin reverberación; cubre `VO_G_12*`, `13*`, `14_*`, `SFX_CALL_BREATH`, `SFX_BREATH_BROKEN`, `SFX_PHONE_END` |
    | `C01` | 3D, techo del pasillo | Plana, paso bajo suave; atenuación máxima −12 dB (`piso_mega_db`) para entenderse en cualquier sala |
    | (ninguna) | 2D | Seca, centrada: `VO_V_*` |

    El timbre convertido del Guardián lo da la grabación; 23 no aplica *pitch* ni distorsión (R30).
34. **Bucle del teléfono.** `SFX_PHONE_BUZZ` en `V02`: empieza con `vibrando` o `TELEFONO_SUENA`; se para con `reposo`, `en_llamada` (fundido 0,1 s†), `stop` o `interrupt`. Idempotente. Se oye desde el pasillo (slice C.7). 23 no inventa el sonido del descolgar (`SFX_PHONE_PICKUP` ‡, sin pedidor).
35. **Llamada sin voz.** 22 sigue con las tres señales y nunca depende de que exista audio (AC-22-19).

### H. Ajustes y accesibilidad

36. **Volúmenes (F1).** 23 recibe de 6 `vol_db` (−38…0 con valores †) o la marca de silencio y lo aplica al bus de su grupo con rampa lineal en dB de `rampa_vol_s` (0,05†; cierra la OQ 8 de 6). En silencio, la rampa llega a −80 dB y el bus se silencia; **nunca −inf** ni `log(0)`. En «ajustes aplicados» aplica los tres valores **sin rampa** antes de arrancar capa alguna.
37. **Silenciar no acorta.** Con un bus en silencio, las líneas **siguen mudas** con la misma duración y señales (D23-2): la línea de tiempo con subtítulos es idéntica a la de quien oye. «Sin audio» solo existe cuando falta el audio.
38. **`reducir_sobresaltos` (cierra la parte de audio de la OQ 12 de 6).** Activa: (a) golpe inicial de `SFX_PHONE_BUZZ` −6 dB† y ataque `t_ataque_buzz_s` (0,25†); (b) `SFX_BREATH_BROKEN` −6 dB†; (c) `SFX_CHAIRS_ROLL` y `SFX_TYPING_FAR` −6 dB† con la rampa de R20; (d) limitador en `VO_G_07` (R39). Nada más (ni voces ni feedback). Se aplica en el fotograma del aviso, con rampa. 19 y 15 no la leen.
39. **Golpe en `VO_G_07`.** Con la opción, la línea pasa por un limitador de techo `techo_limitador_dbfs` (−10†): se **limita**, no se elimina (OQ 2). Responde a 15 (regla 26).
40. **Accesibilidad.** Ningún acierto depende solo del sonido (9) y toda voz tiene subtítulo (26).

### I. Pausa, carga y reanudación

41. **Pausa.** Con `pause_opened` ‡ se **pausan** voces y efectos puntuales en su posición; lazos y drone **siguen** a `pausa_amb_db` (−6†), lo que permite oír el efecto de los deslizadores. Con «pausa cerrada» ‡ (o, si falta, al dejar el árbol de estar pausado) se reanuda. Los relojes de línea son **tiempo de juego** (regla 9 de 21; AC-54 de 9): no avanzan en pausa, y una «terminada» ocurrida en pausa sale al reanudar.
42. **Carga iniciada.** (a) Cancela **sin señal** líneas en curso o encoladas y efectos puntuales, con fundido `t_fade_carga_s` (0,3†); quien esperaba ya canceló o resuelve por su tope (regla 11 de 21); (b) `Ambience` y `Music` −`atenuacion_carga_db` (18†) durante la cortina; (c) descarta el índice de marcadores. Sin señal por las canceladas, para que una señal tardía no adelante la línea de tiempo de la escena nueva (D23-6).
43. **Escena lista / reanudación.** Indexa marcadores, recupera `Ambience` y `Music` en `t_entrada_capa_s` y **deriva las capas de los hechos**: destino `planta` con `caja_completa` ∧ ¬`llamada_completada` → lluvia en `lluvia_apagon_db`; resto, nivel de estancia. Destino `recepcion`: lluvia y drone, sin ventilador. El bucle del teléfono de la reanudación lo piden 21 (`ESC7_TIMBRE`) o 22; 23 no lo infiere.
44. **Nunca repite una voz.** 23 no persiste nada. Una línea suena solo si alguien la pide; la llamada pendiente empieza desde el principio por diseño (D.3 del slice) y la pide 22. La línea de tiempo la reconstruye 21 de los hechos.
45. **Estado restablecido/restaurado.** Descartan la cola y reajustan capas como R43.

### J. Sin audio, fallos y presupuesto

46. **Sin dispositivo.** Con el controlador de audio ficticio, modo `sin_dispositivo`: toda línea responde «sin audio» al momento; los efectos no suenan. Sin aviso al jugador.
47. **Stub de lectura.** Una línea sin audio no suena, no hace ducking ni ocupa canal; su `t_lectura_s` (F3) es el tiempo de subtítulo para quien no declare el suyo. 9 y 22 siguen con su `fallback_s` (D23-1).
48. **Fallo a mitad.** Detiene el sonido en `t_interrupt_s` y emite «fallida» (no «terminada»).
49. **Efecto ausente o corrupto.** No suena, una línea de registro, sin señal (nadie la espera).
50. **Presupuesto (F7).** Voces ≤ 20†; efectos residentes ≤ 10 MB†; audio en ejecución ≤ 24 MB†; disco ≤ 40 MB†. Voces y lazos largos en *streaming*; efectos < 1,0 s precargados. En desarrollo, superar un tope escribe una advertencia.

## Formulas

Valores † a validar. Datos en `assets/data/audio/audio_settings.json`.

### F1 · Volumen

`bus_db(grupo) = vol_db(grupo)` (o bus silenciado si `silencio`)
`ganancia_dB = trim_dB + bus_db + duck_dB + sobresalto_dB + silencio_parcial_dB + pausa_dB + espacial_dB`

| Variable | Rango | Fuente | Descripción |
|---|---|---|---|
| `vol_db` | −38…0 (`db_min` −40†, `N_pasos` 20†) o silencio | 6, F2 | `Voice`←`vol_voces`; `Effects`, `Ambience`←`vol_efectos`; `Music`←`vol_musica` |
| `trim_dB` | −24…+6 | catálogo | Nivelación por sonido |
| `duck_dB` | −12…0 | F2 | Ducking |
| `sobresalto_dB` | −6…0 | R38 | Solo sonidos marcados y opción activa |
| `silencio_parcial_dB`, `pausa_dB` | −4…0 / −6…0 | R29, R41 | `Ambience`, `Music` |
| `espacial_dB` | ≤ 0 | motor | Atenuación 3D |

**Ejemplo:** `vol_efectos` en el paso 15 de 20 (v = 0,75) → −10 dB; `SFX_SNAP` (trim 0) sale a −10 dB. Rampa: de −10 a 0 dB en 0,05 s = 200 dB/s.

### F2 · Ducking

`duck_obj = min sobre canales activos de d_k(bus)` (0 sin línea). Ataque: `duck` baja a `|duck_obj| / t_duck_ataque_s` dB/s. Liberación (tras `t_duck_ret_s`): sube a `|d| / t_duck_lib_s` dB/s hasta 0.

| Variable | Rango | Valor † |
|---|---|---|
| `d_k(bus)` | −12…0 | tabla R31 |
| `t_duck_ataque_s` | 0,05–0,5 | 0,15 |
| `t_duck_ret_s` | 0–1,0 | 0,3 |
| `t_duck_lib_s` | 0,3–2,0 | 0,8 |

**Ejemplo:** `Music` con `VO_V_08` (6 s): −6 dB a 40 dB/s en 0,15 s; fin a 6,0; retención hasta 6,3; subida a 7,5 dB/s → 0 dB a 7,1 s. `VO_V_01` (−6) con `MEGA_01` (−3) a la vez: −6, no −9.

### F3 · Duración de lectura (línea sin audio)

`t_lectura_s = clamp(t_min_lect_s + n_car / cps_lect, t_min_lect_s, t_max_lect_s) + n_pausas · pausa_segmento_s`

| Variable | Rango | Fuente | Descripción |
|---|---|---|---|
| `n_car` | 1–300 | 18 | Caracteres del texto renderizado (nombres sustituidos, espacios incluidos) |
| `t_min_lect_s` | 1,0–3,0 | datos, 1,5† | Mínimo |
| `cps_lect` | 10–25 | datos, 15† | Caracteres por segundo (norma de subtitulado ≈ 15–17) |
| `t_max_lect_s` | 6–20 | datos, 14,0† | Tope de la parte proporcional |
| `pausa_segmento_s` | 0–3,0 | datos, 1,2† | Por cada segmento con pausa previa en 18 |

**Ejemplos:** `VO_G_13B` «Lo sé» (5) → 1,5 + 0,33 = **1,83 s**; `VO_G_13D` (63) → 1,5 + 4,2 = **5,70 s**; `VO_V_12E` «La V no me convence» (19) → 1,5 + 1,27 = **2,77 s**. Es una estimación de subtítulo, no la duración del audio; a 9 y 22 los gobierna su `fallback_s`.

### F4 · Techo y corte

`techo_s = fallback_s + line_grace_s` (solo con `fallback_s`); el fundido empieza en `techo_s − t_fade_corte_s`; «terminada» (`corte`) en `techo_s`. Sin corte: en `finished`; o en `duración + t_watchdog_s` (`watchdog`); máximo absoluto `t_linea_audio_max_s`.

| Variable | Rango | Valor † |
|---|---|---|
| `fallback_s` | 1,0–30,0 | de 9 (`VO_G_07`: 14,0) |
| `line_grace_s` | 1,0–4,0 | 2,0 (un solo valor, de 9 y 22) |
| `t_fade_corte_s` | 0,1–1,0 | 0,3 |
| `t_watchdog_s` / `t_linea_audio_max_s` | 0,3–3,0 / 10–40 | 1,0 / 20,0 |

**Ejemplo (P5):** `VO_G_07`, `fallback_s` 14,0 → `techo_s` 16,0 s. Audio de 17,0 s: fundido desde 15,7, «terminada» a 16,0 (AC-23 de 9). Audio de 13,2 s: «terminada» a 13,2 y secuencia de 15,2 s (AC-20 de 9).

### F5 · Pasos

`paso_db = db_paso_ref + 20 · log10(intensidad)`, con `intensidad = lerp(i_paso_min, 1, r)` (2; `i_paso_min` 0,4†).

| Variable | Rango | Valor † |
|---|---|---|
| `intensidad` | 0,4–1,0 | de 2 |
| `db_paso_ref` | −12…0 | −6 |
| `t_paso_min_s` | 0,1–0,4 | 0,18 |

**Ejemplos:** 0,4 → −6 − 7,96 = **−13,96 dB**; 0,7 → **−9,10 dB**; 1,0 → **−6 dB**.

### F6 · Robo de voces

`candidato = argmax (prioridad_num, edad_s)` entre voces no protegidas (no P1, no P5, no los P2 hasta `max_sfx_p2`). Con `voces_activas ≥ max_voces_total` y candidato con `prioridad_num ≥` la del nuevo, se le aplica fundido de `t_interrupt_s` y entra el nuevo; si no, el nuevo P3 o P4 se descarta (log). Un P1 o P2 nunca se descarta. **Ejemplo:** 20 activas, llega `SFX_DOOR_SWING` (P3): se roba el P3 más antiguo.

### F7 · Memoria

`MB = Σ duración_i · bytes_s / 1.048.576`; WAV mono 16 bits 44,1 kHz = 88.200 B/s. **Ejemplo:** 55 efectos × 0,8 s = 44 s → 3.880.800 B ≈ **3,7 MB** (tope 10 MB†). Voces: 21 líneas de 5 a 14 s en OGG mono (≈ 12 kB/s) ≈ 1,5 MB en disco (streaming). Drone (≈ 3 min) y lluvia (≈ 2 min) en OGG estéreo (≈ 20 kB/s) ≈ 6 MB. Total en disco ≈ 12 MB frente a 40 MB†.

### F8 · Lluvia por estancia

`lluvia_dB = ref + perfil_dB(estancia) + realce_dB + apagon_dB + silencio_parcial_dB`, interpolando en `t_estancia_s`.

| Variable | Rango | Valor † |
|---|---|---|
| `perfil_dB` | −12…0 | A 0, C 0, V −6, B −9, D −9, R −6 |
| `realce_dB` | 0…+3 | +3,0 con `LLUVIA_REALCE` |
| `apagon_dB` | −60…0 | −60 en apagón y llamada |
| `t_estancia_s` | 0,5–3,0 | 1,5 |

**Ejemplo:** del pasillo (0 dB) a `B` (−9 dB): −6 dB a 1,0 s, −9 dB a 1,5 s.

## Edge Cases

- **Canal ocupado / mismo `line_id`:** cola de 1 con tope; con cola llena o tope superado, «fallida» (`canal_ocupado`). Mismo `line_id` activo: se ignora y la señal única llega a todos.
- **`line_id` sin `audio`:** «sin audio» con `t_lectura_s`. **Sin texto en 18** (ID desconocido): «fallida» con `t_lectura_s` = `t_min_lect_s` y registro. **Fichero corrupto:** «fallida» al empezar (18 distingue ausente de roto).
- **Audio más largo/corto que `techo_s`:** corte con fundido (F4) / «terminada» en `finished`. **`finished` perdido:** watchdog (R13).
- **Elegir durante `SENAL` (22):** `interrupt` corta en 0,2 s y «terminada» (`interrumpida`).
- **Línea pedida con la pausa abierta:** se acepta y arranca al reanudar; los relojes no avanzan.
- **Carga con línea en curso:** cancelada sin señal (R42). **«Continuar» durante la llamada:** R42 corta todo, R43 deriva el apagón de los hechos y 22 rehace la llamada desde el principio; nada suena «porque sonaba antes».
- **Volumen en silencio:** líneas mudas con los mismos tiempos (R37). **Sin dispositivo:** todo «sin audio», sin aviso (R46).
- **`reducir_sobresaltos` a mitad de sonido:** rampa; el bucle de `SFX_PHONE_BUZZ` se atenúa sin reiniciarse; el limitador de `VO_G_07` se aplica a partir de su siguiente reproducción.
- **Sin oyente (pruebas):** origen, sin pasos, lluvia a nivel `C`. **Estancia sin etiqueta:** `C` y registro. **Fuente ausente** (`C01`, `SPK_D01C`, `SPK_V02`): 2D con el perfil de la fuente y registro.
- **Tope de voces con solo P1, P2, P5:** el nuevo P3 o P4 se descarta (F6).
- **`set` sobre un lazo que no suena** (`SFX_FRAME_TURN`): ignorado; `play` de un lazo ya sonando: no se duplica.
- **Vista abierta durante el ducking:** se suman en dB con tope `duck_total_min_db`.
- **Volumen cambiado durante la carga:** se aplica al instante; la atenuación de carga es un trim aparte.

## Dependencies

| Sistema | Tipo | Recibe / entrega | Contrato |
|---|---|---|---|
| 3 Estado y bus | **Dura** | Se suscribe (R5); emite las cuatro señales; lee `caja_completa` y `llamada_completada` al reanudar | 3 ya lista a 23 como emisor; faltan «sonido pedido», «línea iniciada», «pausa cerrada» |
| 6 Ajustes | **Dura** | `vol_voces`, `vol_efectos`, `vol_musica`, `reducir_sobresaltos`, «ajustes aplicados», avisos de cambio | Regla 1 de 6; cierra OQ 7, 8, 12 |
| 18 Contenido | **Dura** | Texto renderizado y pausas por `line_id`; campo `audio`; `UI_VOL_MUESTRA` ‡ | Reglas 16 y 17 de 18 |
| 2 Jugador | Blanda | `paso`; posición y orientación del oyente | Reglas 31 de 2; sin 2, sin pasos |
| 9 Marco de puzles | Blanda (avisos) | «Feedback de puzle»; «línea pedida» (`VO_G_07`, `fallback_s`) | Reglas 20 y 37 de 9 |
| 21 Director de escenas | Blanda (avisos) | «Línea pedida» (`VO_V_*`, `MEGA_*`), efectos y estado de objeto | Reglas 6, 7, 9 de 21; 21 no depende de 23 |
| 22 Llamada | Blanda (avisos) | «Línea pedida» (`VO_G_12*`, `13*`, `14_*`), sonidos de llamada ‡, `interrupt` ‡ | Reglas 5, 14, 15, 25 de 22 |
| 26 Subtítulos | Blanda (avisos) | Señales, `t_lectura_s`, «línea iniciada» ‡ | ‡ (sin GDD) |
| 8, 10, 7, 19, 15 | Blanda (avisos) | «Sonido pedido» ‡: `SFX_CARD_OK`, `SFX_DOOR_SWING`, `SFX_DRAWER_OPEN`, `MEGA_03` (8); `SFX_BOX_WOOD_*`, `SPK_D01C` (10); `SFX_CLICK_SUBTLE` (7); `SFX_KEY`, `SFX_PRINTER` (19); `SFX_FRAME_TURN` (15) | Catálogo en «Datos» |
| 4 Escena de planta | Blanda | Avisos de carga; marcadores, estancias, superficies | Regla 1 de 4; ‡ |
| 25 Pausa · 28 Atmósfera · 27 Título | Blanda / informativa | `pause_opened` ‡, «pausa cerrada» ‡ · comparten `LLUVIA_*` y `reducir_sobresaltos` · audio del título (OQ 3) | ‡ |

Ningún dependiente depende de que 23 responda (R8). Sin ciclos: 23 solo se suscribe y responde por el bus.

## Tuning Knobs

| Knob | Valor † | Rango seguro | Afecta |
|---|---|---|---|
| `rampa_vol_s` | 0,05 | 0,02–0,2 | Anti-chasquido (R36) |
| Ducking Vera/Guardián (Music/Amb/Fx_World) | −6/−4/−4 | −12…−2 | R31 |
| Ducking megafonía | −3/−2/−2 | −8…0 | R31 |
| `t_duck_ataque_s` / `_ret_s` / `_lib_s` | 0,15 / 0,3 / 0,8 | 0,05–0,5 / 0–1 / 0,3–2 | Naturalidad |
| `duck_total_min_db` | −12 | −18…−6 | Suma de ducking y silencio parcial |
| `silencio_parcial_amb_db` / `_mus_db` | −4 / −3 | −8…0 | R29 |
| `pausa_amb_db` | −6 | −12…0 | R41 |
| `atenuacion_carga_db` / `t_fade_carga_s` | −18 / 0,3 | −30…−6 / 0,1–0,6 | R42 |
| `t_entrada_capa_s` / `t_salida_capa_s` | 3,0 / 1,5 | 1–6 / 0,5–3 | R27 |
| `lluvia_apagon_db` / `d_lluvia_apagon_s` / `t_lluvia_vuelve_s` | −60 / 0,4 / 2,0 | −60…−24 / 0–2 / 0,5–4 | R22 (OQ 1) |
| `realce_lluvia_db` | +3,0 | 0…+6 | `LLUVIA_REALCE` |
| Perfil de estancia / `lp_sala_hz` / `t_estancia_s` | A 0, C 0, V −6, B −9, D −9, R −6 / 2.500 / 1,5 | −12…0 / 1.500–6.000 / 0,5–3 | F8 |
| `t_cola_canal_s` | 8,0 | 3–12 | R10 |
| `line_grace_s` (registrado de 9) | 2,0 | 1–4 | Techo de línea |
| `t_fade_corte_s` / `t_interrupt_s` | 0,3 / 0,2 | 0,1–1 / 0,05–0,3 | R12, R14 |
| `t_watchdog_s` / `t_linea_audio_max_s` | 1,0 / 20,0 | 0,3–3 / 10–40 | R13 |
| `t_min_lect_s` / `cps_lect` / `t_max_lect_s` / `pausa_segmento_s` | 1,5 / 15 / 14,0 / 1,2 | 1–3 / 10–25 / 6–20 / 0–3 | F3 |
| `atenuacion_sobresalto_db` / `t_ataque_buzz_s` / `techo_limitador_dbfs` / `t_entrada_susto_s` | −6 / 0,25 / −10 / 1,0 | −12…0 / 0,05–0,6 / −18…−6 / 0,3–2 | R38, R39 |
| `d_no_llega_m` | 6,0 | 3–12 | R20 |
| `db_paso_ref` / `t_paso_min_s` | −6 / 0,18 | −12…0 / 0,1–0,4 | F5 |
| `t_muestra_min_s` / `t_dedup_s` | 0,4 / 0,05 | 0,2–1 / 0–0,1 | R25, R18 |
| `max_voces_total` / `max_sfx_p2` | 20 / 4 | 12–32 / 2–8 | F6 |
| Memoria efectos / total / disco (MB) | 10 / 24 / 40 | — | F7 |

## Acceptance Criteria

L = lógica (reloj falso, reproductores simulados) · I = integración · V = medición/captura · P = playtest.

- **AC-23-01 (R7, L):** **GIVEN** una línea con audio, **WHEN** el reproductor emite `finished`, **THEN** «línea terminada» (`fin`) con su `line_id` ≤ 1 fotograma después y ninguna otra señal.
- **AC-23-02 (R7, F3, L):** **GIVEN** `audio` nulo, **THEN** «línea sin audio» ≤ 1 fotograma con `t_lectura_s`: `VO_G_13B` 1,83 s, `VO_G_13D` 5,70 s, `VO_V_12E` 2,77 s (±0,01).
- **AC-23-03 (R7, R48, L):** **GIVEN** un fichero corrupto, **THEN** «fallida» al empezar; **GIVEN** fallo a los 3 s, **THEN** «fallida» a ese instante y ninguna «terminada».
- **AC-23-04 (R12, F4, L):** **GIVEN** `VO_G_07` con `fallback_s` 14,0 y audio de 17,0 s, **THEN** «terminada» (`corte`) a 16,0 s ±0,05 con fundido de 0,3 s; con audio de 13,2 s, a 13,2 s.
- **AC-23-05 (R13, L):** **GIVEN** un reproductor sin `finished`, **THEN** «terminada» (`watchdog`) a `duración + 1,0 s`.
- **AC-23-06 (R9, R10, L):** **GIVEN** dos líneas del mismo canal, **THEN** la segunda arranca al terminar la primera; con la cola llena, «fallida»; **GIVEN** `VO_V_01` y `MEGA_01`, suenan a la vez sin espera; dos peticiones del mismo `line_id` dan una reproducción y una señal.
- **AC-23-07 (R14, L):** **GIVEN** `SFX_BREATH_BROKEN` o `VO_G_14_RET` sonando, **WHEN** llega `interrupt`, **THEN** silencio en ≤ 0,3 s y «terminada» (`interrumpida`); interrumpir lo que no suena no da error.
- **AC-23-08 (R8, I):** **GIVEN** 23 ausente, **THEN** P5 termina a 18,0 s (AC-23 de 9) y la llamada avanza por su tope (AC-22-19).
- **AC-23-09 (R11, L):** **GIVEN** `VO_G_07` sin `fuente`, **THEN** suena desde `SPK_D01C` (3D); `MEGA_03` desde `C01`; `VO_G_12A` por `SPK_V02`; `VO_V_01` en 2D.
- **AC-23-10 (F1, R36, L):** **GIVEN** `vol_efectos` en el paso 15 de 20, **THEN** `Effects` y `Ambience` a −10 dB ±0,1; en el paso 0, buses silenciados sin calcular −inf; el cambio recorre 0,05 s ±0,01; «ajustes aplicados» aplica sin rampa antes de arrancar capas.
- **AC-23-11 (F2, L):** **GIVEN** `VO_V_08` (6 s), **THEN** `Music` a −6 dB en 0,15 s ±0,02, 0 dB a 7,1 s ±0,1; con `VO_V_01` y `MEGA_01` solapadas, −6 (no −9); `Fx_Puzzle`/`Fx_Steps` no se bajan; una línea sin audio no hace ducking.
- **AC-23-12 (R37, L):** **GIVEN** `vol_voces` en silencio, **THEN** las líneas se reproducen mudas con la misma duración y señales a los mismos tiempos.
- **AC-23-13 (R29, L):** **GIVEN** «vista cercana abierta», **THEN** `Ambience` −4 y `Music` −3 en 1,0 s ±0,1; al cerrar, vuelven; voces y feedback intactos.
- **AC-23-14 (R38, R39, V):** **GIVEN** `reducir_sobresaltos`, **THEN** el pico de `SFX_PHONE_BUZZ`, `SFX_BREATH_BROKEN`, `SFX_CHAIRS_ROLL` y `SFX_TYPING_FAR` baja 6 dB ±0,5, el ataque del timbre es 0,25 s, `VO_G_07` no supera −10 dBFS ±0,5 y se oye completa; nada más cambia.
- **AC-23-15 (R28, F8, L):** **GIVEN** el oyente pasa de `C` a `B`, **THEN** la lluvia pasa de 0 a −9 dB (±0,5) en 1,5 s ±0,1.
- **AC-23-16 (R21, R22, L):** **GIVEN** `LUCES_APAGON`, **THEN** lluvia a −60 dB en 0,4 s; con `LLUVIA_VUELVE`, al nivel de la estancia en 2,0 s ±0,1; `LLUVIA_REALCE` (8,0 s): +3 dB durante 8,0 s ±0,2; `LLUVIA_CESA` (6,0 s): silencio a 6,0 s ±0,2.
- **AC-23-17 (R27, L):** **GIVEN** `planta` → `recepcion`, **THEN** drone y lluvia no se reinician y el ventilador se detiene; **GIVEN** «descarga total solicitada», todas las capas a silencio en 1,5 s ±0,1 y ningún reproductor activo tras «completada».
- **AC-23-18 (R41, L):** **GIVEN** `pause_opened` con una línea a mitad, **THEN** voces y efectos pausados en posición, drone y lluvia siguen a −6 dB; tras «pausa cerrada» continúan, el techo no avanzó en pausa y una «terminada» ocurrida en pausa sale al reanudar.
- **AC-23-19 (R42, L):** **GIVEN** una línea en curso y «carga de escena iniciada», **THEN** fundido de 0,3 s y **ninguna** señal; `Ambience`/`Music` −18 dB en la cortina y recuperación en 3,0 s ±0,2 tras «escena lista».
- **AC-23-20 (R43, R44, L):** **GIVEN** «Continuar» con `caja_completa` ∧ ¬`llamada_completada`, **THEN** al «escena lista» lluvia a −60 dB, drone sonando, ninguna voz no pedida y ningún bucle de teléfono inferido.
- **AC-23-21 (R23, F6, L):** **GIVEN** 20 voces activas, **THEN** un P3 nuevo roba el P3 más antiguo; con solo P1/P2/P5, se descarta con registro; una voz P1 y un feedback P2 no se roban nunca.
- **AC-23-22 (F5, L):** **GIVEN** `paso(moqueta, 0,4)`, **THEN** −13,96 dB ±0,1 (0,7: −9,10; 1,0: −6); dos pasos en < 0,18 s dejan sonar uno; la variante no repite la anterior.
- **AC-23-23 (R34, L):** **GIVEN** `V02` en `vibrando`, **THEN** bucle de `SFX_PHONE_BUZZ` en `V02`, sin duplicarse al pedirlo otra vez; `reposo` o `en_llamada` lo cortan en 0,1 s; `TELEFONO_PULSOS` da 3 pulsos de 1,0 s ±0,1.
- **AC-23-24 (R19, R33, I):** **GIVEN** el oyente en `D`, **THEN** `VO_G_07` se oye en toda la estancia desde el altavoz (3D); `MEGA_02` se entiende en las salas cerradas con ≤ 12 dB de atenuación.
- **AC-23-25 (R20, V):** **GIVEN** el apagón, **THEN** sillas y tecleo no se acercan a menos de 6,0 m del oyente en `D` y entran con rampa de 1,0 s.
- **AC-23-26 (R25, L):** **GIVEN** el menú abierto y un cambio de `vol_voces`, **THEN** suena la muestra como mucho cada 0,4 s (con `SFX_CLICK_SUBTLE` si falta `UI_VOL_MUESTRA`); para `vol_musica` no suena muestra.
- **AC-23-27 (R46, R49, L):** **GIVEN** el controlador ficticio, **THEN** toda línea da «sin audio» ≤ 1 fotograma y la llamada y P5 completan con los tiempos de 22 y 9; **GIVEN** un `sound_id` con fichero ausente, no suena, una línea de registro, sin error.
- **AC-23-28 (R50, F7, I):** **GIVEN** el slice completo, **THEN** voces ≤ 20, audio residente ≤ 24 MB y disco ≤ 40 MB.
- **AC-23-29 (R1, I):** **GIVEN** `planta` → `recepcion`, **THEN** `get_instance_id()` de 23 es idéntico y no queda suscripción colgante (parte de AC-01 de 4).
- **AC-23-30 (R30, P):** **GIVEN** un recorrido completo, **THEN** ningún sonido de acierto, error o decisión es musical ni cambia el drone, y 5 de 5 testers no pueden deducir de los sonidos si una decisión de P4 o P6 era «correcta».
- **AC-23-31 (loudness, V):** **GIVEN** los buses al 100 %, **THEN** voces −18 LUFS ±2, efectos de puzle −22 ±2, lluvia −34 ±3, drone −36 ±3 (corto plazo, †) y pico real ≤ −1 dBTP.

## Datos

### `assets/data/audio/audio_catalog.json` (propiedad de 23)

Un registro por sonido: `id`, `bus`, `prioridad`, `archivos` (variantes), `lazo`, `fuente_defecto`, `perfil_fuente`, `trim_db`, `sobresalto`, `pedido_por`. Las **líneas** no están aquí: son de 18.

| `id` | Bus · prio. | Lazo · fuente | Pide |
|---|---|---|---|
| `SFX_SLIDE_OK`, `SFX_SLOT_IN`, `SFX_UNLOCK`, `SFX_UNLOCK_SOFT`, `SFX_REJECT`, `SFX_GLASS_HUM` (2,0 s), `SFX_SNAP`, `SFX_STAMP`, `SFX_LOCK_CLICK` (0,3 s) | `Fx_Puzzle` · P2 | no | 9 (puzles 1 a 6); slice B.7 |
| `SFX_CLICK_SUBTLE` | `Fx_Puzzle` · P2 | no | 7, 8; B.7 |
| `SFX_PHONE_BUZZ` | `Fx_World` · P2 | **sí** · `V02`; `sobresalto` | 21, 22 |
| `SFX_BREATH_BROKEN` (4,0 s†) | `Fx_World` · P2 | no · `SPK_V02`; `sobresalto`; subtítulo `SUB_BREATH_BROKEN` (18) | 22 |
| `SFX_PHONE_END`, `SFX_CALL_BREATH` ‡ (2,0 s†) | `Fx_World` · P2 | no · `SPK_V02` | 22 |
| `SFX_CARD_OK` ‡ (0,3 s), `SFX_DOOR_SWING` ‡ (1,2 s), `SFX_DRAWER_OPEN` ‡ | `Fx_World` · P3 | no | 8 |
| `SFX_BOX_WOOD_OPEN`, `SFX_BOX_WOOD_CLOSE` ‡ | `Fx_World` · P3 | no · `D01` | 10 |
| `SFX_KEY` ‡, `SFX_PRINTER` ‡ (1,5 s) | `Fx_World` · P3 | no · `V01`, `V08` | 19 |
| `SFX_FRAME_TURN` ‡ | `Fx_Puzzle` · P2 | **sí** (`valor` = velocidad) | 15 (opcional) |
| `SFX_CHAIRS_ROLL`, `SFX_TYPING_FAR` ‡ (3,0 s) | `Fx_World` · P3 | no · 3D móvil; `sobresalto` | 21 (slice C.7) |
| `SFX_ELEVATOR_DOORS`, `SFX_PHONE_PICKUP`, `SFX_PAGE_TURN` ‡ | `Fx_World` · P3 | no | 21; los dos últimos sin pedidor aún (`ANIM_PHONE_PICKUP`, `ANIM_PAGE_TURN`) |
| `SFX_STEP_moqueta`, `_baldosa`, `_default` ‡ (4 variantes) | `Fx_Steps` · P4 | no | 2 (`paso`) |
| `AMB_RAIN` ‡, `AMB_FAN` ‡ (3D en `V`) | `Ambience` · P5 | **sí** | 23 |
| `MUS_DRONE` ‡ | `Music` · P5 | **sí** · 2D | 23 |
| `UI_VOL_MUESTRA` ‡ | `Voice` · P1 | no | 23 (clave en 18) |

`audio_settings.json`: todos los números de «Tuning Knobs» (clave = nombre del knob).

### Formatos y objetivos (propuesta; lo fija un ADR)

| Categoría | Formato | Loudness † (corto, al 100 %) |
|---|---|---|
| Voces `VO_*`, `MEGA_*` | OGG Vorbis mono 44,1 kHz (q4–5), *streaming*; grabadas secas | −18 LUFS (megafonía −21); pico ≤ −1 dBTP |
| Efectos de puzle / mundo / pasos | WAV 16 bits mono 44,1 kHz (< 1,0 s, precarga) u OGG | −22 / −26 / −30 LUFS |
| Lluvia, ventilador | OGG, lazo sin costura (≥ 60 s†), *streaming* | −34 / −38 LUFS |
| Drone | OGG estéreo, lazo, *streaming*, sin melodía | −36 LUFS |

Nombres de fichero: `[categoría]_[contexto]_[nombre]_[variante].ogg` (`sfx_puzzle_unlock_01.ogg`, `amb_env_rain_loop.ogg`, `mus_drone_building_loop.ogg`); el ID del documento vive en el catálogo.

## Decisiones tomadas

Decisiones por defecto de este lote, revisables; las que tocan tono o alcance están además en Open Questions.

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D23-1 | «Sin audio» y «fallida» salen **al momento**, con `t_lectura_s` | Retener la señal hasta `t_lectura_s` y emitir «terminada» | 9 (regla 20) y 22 (regla 25) ya esperan `fallback_s`; retener duplicaría la espera y rompería AC-20 de 9. `t_lectura_s` resuelve a 21, que no tiene `fallback_s` |
| D23-2 | Con un volumen en silencio las líneas siguen **mudas** con los mismos tiempos | Responder «sin audio» si el bus está en silencio | La partida con subtítulos debe ser idéntica a la que se oye (*Tensión sin castigo*) |
| D23-3 | `vol_voces`→`Voice`; `vol_efectos`→`Effects`+`Ambience`; `vol_musica`→`Music` (drone) | Lluvia al deslizador de música | El drone es la única música (§14, §18); la lluvia es ambiente de mundo. Cierra la OQ 7 de 6 |
| D23-4 | Aviso genérico «sonido pedido» ‡ | 23 deduce cada sonido de avisos ajenos | Deducirlos obliga a 23 a conocer la lógica de 7, 8, 10, 19. Coste: un aviso nuevo en 3 (OQ 7) |
| D23-5 | 23 soporta `interrupt` (0,2 s) y emite «terminada» (`interrumpida`) | No soportar interrumpir (degradación de 22) | Cumple el ‡ de 22; nadie queda colgado |
| D23-6 | Carga de escena: cancelación **sin señal** | Emitir «terminada» (`cancelada`) | Una señal tardía de la escena anterior podría adelantar la nueva; 21 y 9 ya cancelan |
| D23-7 | Pausa: voces y puntuales se pausan; ambiente y drone siguen −6 dB | Pausar todo / no pausar nada | Pausar todo deja vacío y no deja oír los deslizadores; no pausar voces rompe la lectura |
| D23-8 | Ducking fijo (−6/−4/−4 y −3/−2/−2), nunca bajo feedback ni pasos | Sidechain dinámico | Valores fijos testeables (AC-23-11); el feedback debe oírse siempre |
| D23-9 | Rampa 0,05 s; muestra solo para voces y efectos | Sin rampa; muestra también de música | Evita chasquidos sin lentitud; el drone se oye directamente en pausa |
| D23-10 | `reducir_sobresaltos` quirúrgico: 4 sustos −6 dB y limitador en `VO_G_07` | Bajar todo `Fx_World` | No debe bajar voces ni feedback de puzle |
| D23-11 | Sin volumen maestro | Añadir `vol_maestro` a 6 | El slice pide tres grupos independientes (§14); un maestro es alcance extra (OQ 4) |
| D23-12 | Tres canales con cola de 1 y tope 8,0 s | Cola ilimitada o cancelar la anterior | Coherente con la regla 7 de 21; no hay planificación propia |
| D23-13 | Lluvia a silencio en apagón y llamada | La lluvia continúa y `LLUVIA_VUELVE` solo la sube | «Vuelve la lluvia» (C.7) implica que se fue; sostiene la llamada (pilar 2). OQ 1 |
| D23-14 | Superficies `moqueta`, `baldosa`, `default` | Una sola | Distingue Recepción de la planta con coste mínimo; respuesta a la OQ 6 de 2 (OQ 5) |
| D23-15 | Sin *stingers* ni drone reactivo | Variaciones del drone por puzle o decisión | Un motivo diría qué es «correcto» (*Ambivalencia*, *Información incompleta*) |
| D23-16 | Sin dispositivo: modo `sin_dispositivo`, todo «sin audio» | Error visible | El juego no se detiene por audio (*Tensión sin castigo*) |
| D23-17 | Estancia deducida del oyente en volúmenes `audio_room` | Usar «zona activada» `T-…` | `T-…` son disparadores de escena, no un modelo de estancias |
| D23-18 | «Línea iniciada» ‡ opcional | 26 deduce el arranque de «línea pedida» | La línea puede esperar en cola |
| D23-19 | Silencio parcial en cualquier vista cercana | Solo en puzles | 7 no distingue puzles en el aviso; documentos se benefician igual |
| D23-20 | `fuente_defecto` en el catálogo; la del aviso gana | Que cada pedidor pase siempre la fuente | 9 pide `VO_G_07` sin fuente; el altavoz es dato del catálogo |
| D23-21 | Pausa de `VO_G_07` dentro del fichero; 1,2 s† sin audio | 23 inserta pausa propia | Es una grabación continua. Responde la OQ 3 de 18 |

## Open Questions

| # | Pregunta | Quién decide | Por defecto / impacto |
|---|---|---|---|
| 1 | **¿Cae la lluvia a silencio en el apagón y la llamada?** El slice solo dice que «vuelve» (C.7). Alternativa: lluvia baja pero audible | Usuario / creative-director | Silencio (−60 dB). Tono de la escena 7 (pilar 2) |
| 2 | **Golpe de puerta dentro de `VO_G_07`:** el limitador lo contiene pero no lo quita. ¿Se graba como pista aparte? | Usuario / grabación | Limitador −10 dBFS†. Otra opción implica dos ficheros y cambios en 18 |
| 3 | **¿Suena el drone en el título y el menú?** Hoy arranca en «escena lista» y se detiene al volver al título | Usuario / 27 | Silencio en el título |
| 4 | **¿Volumen maestro?** No está en 6 | Usuario / 6 / 30 | No; si se añade, 23 usa `Master` sin más cambios |
| 5 | **Superficies de suelo:** materiales `moqueta`/`baldosa` por confirmar | Art-director | Las tres; cierra la OQ 6 de 2 |
| 6 | **`UI_VOL_MUESTRA`:** frase neutra grabada y clave en 18 | Narrative-director / 18 | `SFX_CLICK_SUBTLE` mientras tanto |
| 7 | **«Sonido pedido» como aviso del bus (3):** cambio de arquitectura de avisos | Technical-director / 3 | Adoptarlo; si no, 23 deduce de cada sistema |
| 8 | **Objetivos de loudness y presupuestos (20 voces, 24 MB):** †, a medir con audio real y hardware objetivo | Audio-director / technical-director | AC-23-28 y AC-23-31 |
| 9 | **Segmentos de `VO_G_07` para 26:** 23 solo da la duración total en «línea iniciada» | 26 | Solo duración; marcas por segmento en el catálogo si hace falta |

## Cambios requeridos en otros GDDs

Este GDD no ha editado ningún archivo existente. Los coordina `producer`.

| GDD | Cambio | Motivo |
|---|---|---|
| `systems-index.md` | Fila 23: «Borrador (lote autónomo)», ruta `design/gdd/director-de-audio.md`; deps «3, 6, 18 (duras) · blanda 2» | Existe el GDD |
| `estado-y-bus-de-eventos.md` (3) | Regla 10: a 23, añadir «línea iniciada» ‡ y las cargas extendidas; añadir «sonido pedido» ‡ `{sound_id, fuente?, accion, valor?}` (emisores 7, 8, 10, 15, 19; 22 como alias) y «pausa cerrada» ‡ (25); quitar ‡ de las tres señales | Contratos de 23 |
| `ajustes-persistentes.md` (6) | Cerrar OQ 7 (lluvia y ventilador a `vol_efectos`, drone a `vol_musica`), 8 (rampa 0,05 s y muestra) y 12 (parte de audio); anotar que no hay `vol_maestro` | R3, R25, R36, R38 |
| `base-de-contenido-narrativo.md` (18) | Pedir `UI_VOL_MUESTRA` ‡ (fuera del §12, sin subtítulo); cerrar OQ 3 (pausa de `VO_G_07`); exponer texto renderizado y pausa previa por `line_id`; fijar que `audio` nulo o ausente = «sin audio» y fichero roto = «fallida» | R16, R25, F3 |
| `director-de-escenas.md` (21) | Usar `t_lectura_s` de «sin audio/fallida» como duración del subtítulo; emitir `LLUVIA_CESA` en `ESC7_APAGON` o confirmar que 23 la deriva de `LUCES_APAGON`; quitar ‡ de la mezcla en la regla 7; pausa por `pause_opened`/«pausa cerrada» | R7, R22, R41 |
| `llamada-telefonica.md` (22) | «Sonido de llamada pedido» = «sonido pedido» con `accion` ∈ `play`, `stop`, `interrupt`; declarar `SPK_V02`; quitar ‡ de la interrupción (23: 0,2 s); usar `t_lectura_s` si 18 no da `fallback_s` | R14, R33 |
| `marco-de-puzles.md` (9) | Confirmar el corte en `fallback_s + line_grace_s` con «terminada» (`corte`); «feedback de puzle» lleva `sound_id` del catálogo de 23; quitar ‡ | R12, F4 |
| `control-de-acceso.md` (8) · `caja-y-compartimentos.md` (10) · `interaccion-e-inspeccion.md` (7) · `ordenador-correo-impresora.md` (19) · `puzle-5-espejo-de-la-diferencia.md` (15) | Emitir «sonido pedido» ‡ para sus `SFX_*` (8: `SFX_CARD_OK`, `SFX_DOOR_SWING`, `SFX_DRAWER_OPEN`; 10: `SFX_BOX_WOOD_*` con `D01`; 7: `SFX_CLICK_SUBTLE`; 19: `SFX_KEY`, `SFX_PRINTER`; 15: `SFX_FRAME_TURN` con velocidad). 8 sigue pidiendo `MEGA_03` por «línea pedida» | D23-4 |
| `escena-de-planta.md` (4) · `jugador-en-primera-persona.md` (2) | 4: marcadores de audio, volúmenes `audio_room` y etiquetas de superficie. 2: confirmar `moqueta`/`baldosa`/`default` y que el oyente es un `AudioListener3D` en la cámara | R19, R24 |
| 25, 26, 27, 28 (sin GDD) | 25: `pause_opened` y «pausa cerrada» ‡. 26: consumir las señales, `t_lectura_s` y «línea iniciada». 27: audio del título (OQ 3). 28: coordinar `LLUVIA_*` y `reducir_sobresaltos` | R41, D23-18 |

## Entradas para el registro

Solo lo **nuevo**; no se repiten `MEGA_03`, `SFX_CARD_OK`, `SFX_DOOR_SWING`, `SFX_DRAWER_OPEN`, `SPK_D01C`, `SFX_BOX_WOOD_*`, `SFX_CALL_BREATH` ‡ ni los volúmenes de 6.

| Tipo | Nombre | Valor / descripción | Fuente |
|---|---|---|---|
| constante | `AUDIO_BUSES` | `Voice` (`Voice_Vera`, `Voice_Mega`, `Voice_Guardian`), `Effects` (`Fx_Puzzle`, `Fx_World`, `Fx_Steps`), `Ambience`, `Music` | R3 |
| regla | `audio_vol_mapping` | `vol_voces`→`Voice`; `vol_efectos`→`Effects`+`Ambience`; `vol_musica`→`Music`; sin `vol_maestro` | D23-3, D23-11 |
| constante | `AUDIO_RAMP_S` † | 0,05 s | R36 |
| constante | `DUCK_DB` † | Vera/Guardián −6/−4/−4 (Music/Ambience/Fx_World); megafonía −3/−2/−2; ataque 0,15, retención 0,3, liberación 0,8 s | R31, F2 |
| constante | `LINE_REPLY_SIGNALS` | «línea terminada» (`fin`, `corte`, `watchdog`, `interrumpida`), «línea sin audio» y «línea fallida» (`t_lectura_s`) | R7 |
| aviso | «línea iniciada» ‡ · «sonido pedido» ‡ · «pausa cerrada» ‡ | `{line_id, duracion_s, canal}` · `{sound_id, fuente?, accion, valor?}` · sin datos | R15, R5 |
| fórmula | `t_lectura_s` · `techo_s` · `paso_db` | `clamp(1,5 + n_car/15, 1,5, 14,0) + n_pausas·1,2` · `fallback_s + line_grace_s` (16,0 s en `VO_G_07`) · `-6 + 20·log10(intensidad)` (†) | F3, F4, F5 |
| constante | `LINE_CHANNELS` | `VO_V_*`→`Voice_Vera`; `MEGA_*`→`Voice_Mega`; `VO_G_*`→`Voice_Guardian` | R9 |
| constante | `LINE_DEFAULT_SOURCE` | `VO_G_07`→`SPK_D01C`; `MEGA_*`→`C01`; `VO_G_12/13/14*`→`SPK_V02`; `VO_V_*`→2D | R11 |
| constante | `SPK_V02` ‡ | Auricular y altavoz del teléfono de Vera | R33 |
| constante | `AUDIO_ROOMS` ‡ · `RAIN_ROOM_DB` † | `V`, `C`, `A`, `B`, `D`, `R` · A 0, C 0, V −6, B −9, D −9, R −6 | R28 |
| constante | `FOOT_SURFACES` ‡ | `moqueta`, `baldosa`, `default` | R24 |
| constante | `AUDIO_BUDGET` † | 20 voces; 10 MB efectos; 24 MB total; 40 MB disco | R50 |
| fichero | `audio_catalog.json`, `audio_settings.json` | `assets/data/audio/` (propiedad de 23) | Datos |
| sonidos ‡ | `SFX_CHAIRS_ROLL`, `SFX_TYPING_FAR`, `SFX_ELEVATOR_DOORS`, `SFX_PHONE_PICKUP`, `SFX_PAGE_TURN`, `SFX_STEP_*`, `SFX_KEY`, `SFX_PRINTER`, `SFX_FRAME_TURN`, `AMB_RAIN`, `AMB_FAN`, `MUS_DRONE`, `UI_VOL_MUESTRA` | Propuestas (los de 8, 15 y 19 ya los proponen sus GDD) | Datos |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Primer borrador (lote autónomo, sistema 23), por el audio-director: reglas R1 a R50, F1 a F8, edge cases, dependencias bidireccionales, knobs, 31 AC, catálogo de sonidos, 21 decisiones (D23-1 a D23-21), 9 preguntas abiertas. Sin cambios en ningún archivo existente. Estado: Borrador (lote autónomo). |
