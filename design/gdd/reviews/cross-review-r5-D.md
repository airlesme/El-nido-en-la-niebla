# Revisión R5-D (Fase 4, escenarios) — informe final

Revisor independiente; solo lectura. Verificado contra los textos ACTUALES; r4 solo como línea base.
Leído: 8 (reglas 4–23, F1–F4, Edge Cases), 20 (secciones A–G), 21 (reglas 1–24, F1–F5, Edge Cases), 1 (reglas 5–8, 23, AC-E1–E17, D13–D21), 4 (reglas 9 tabla de pila, 10–18), 5 (reglas 6, 17, 18, 29, estados), 7 (reglas 27a/b, 28), 10 (reglas 10–23), 19 (R10–R30), 9 (reglas 16–19, 23), 3 (reglas 4–5), 6 (catálogo, dependencias), r4.

## Resumen
| Escenario | Estado | BLOCKER | Hallazgos |
|---|---|---|---|
| N1 puerta B | Completo salvo 2 (gesto) | 0 | N1-1, N1-2 |
| N2 imprimir I-01 | Parcial (9: P1/C05 no leído) | 0 | N2-1 |
| N3 ascensor/Recepción | Parcial (22 ausente) | 0 | N3-1 |
| N4 repasar bolsillo | Parcial (9 r16.6 no leído) | 0 | N4-1, N4-2 |
| N5 caja y P5 | Parcial (cadena D01a–D01d en 7 no leída) | 0 | N5-1, N5-2 |
| E1 | Parcial | 0 | INFO |
| E3 | Parcial | 0 | INFO |
| E4 | Parcial | **1 (E4-1)** | E4-1 |
| E5 | Parcial | 0 | INFO |
| E7 | Parcial | 0 | E7-1 |

## N1 Puerta B con tarjeta — COMPLETO (salvo 2)
Cadena: 8 r22 (`A05`, `HAND_DRAWER`; espera `gesto_terminado` cualquier `motivo` o `t_cajon_tope_s` 3,0 s) → `otorgar("A05")` una vez → 20 R8/R12 (`tarjeta_B` y luego `tarjeta_D`; presentación no bloqueante) → en el lector: 8 r8 (a `bloquear_contexto("tarjeta")` dentro de `interact`, b `LEYENDO` 0,5 s, c `SFX_CARD_OK`, d `HECHO`) y, en paralelo, `sostener_item` → `objeto_sujeto` (o 0,6 s) → `HAND_CARD_SWIPE` → `gesto_terminado` → `guardar_item` + `liberar_contexto` → a 0,5 s `ABRIÉNDOSE` y «puerta abierta» (r11: primer paso, no al final) → 5 r6 `door_opened:<ID>`.
- INFO N1-0: para B y D el guardado es un no-op: 5 (AC de `door_opened`, D-24) dice que B/D no son hechos, `dif` es falso y no escriben. El «guardado» del escenario solo escribe si otro hecho cambió (p. ej. `tarjeta_*`, que ya tiene `card_acquired`).
- INFO: cierre en mitad del gesto o de `LEYENDO`/`ABRIÉNDOSE` → B/D nacen cerradas, tarjetas siguen verdaderas (8 r12, Edge Cases; 5 AC-41b; 20 R16 «no se consume»). Coherente en 8, 20, 5.
- WARNING N1-1: 20 R12 (aborto de presentación) no lista `bloquear_contexto("tarjeta")` de 8. Si el jugador llega a B con la presentación de la otra tarjeta en curso, `sostener_item` se rechaza (20 R11) y 8 pasa el gesto sin objeto (8 r8): coherente, pero `HAND_HOLD_ITEM` (izquierda, de 20) y `HAND_CARD_SWIPE` (derecha, de 8) podrían coexistir; ninguna AC de 8/20 lo prueba (a confirmar en 2).
- INFO N1-2: 8 r14 dice «hasta que 21 toma el `sin control`»; 21 no lo toma, lo releva con *traspasar* (1 r6; 21 r8a). Solo redacción.
- NO RECORRIDO: reglas de `reproducir_gesto`/`sostener`/`soltar` en 2 (no leídas): solo se verificó el contrato desde 8 y 20.

## N2 Imprimir I-01 — PARCIAL
19 R10–R15: búsqueda exacta ≥3 car., resultados a 0,4 s, `correos_leidos` escrito en el mismo fotograma del primer resultado → botón «Imprimir» habilitado (R21a) o verbo de `V08` (R21b) → `imprimiendo` 1,5 s → R23 `otorgar_sesion("I-01")` (idempotente) → 20 R9 conjunto de sesión → 9 llama `compose_i01()` (R30) al abrir `C05`/`on_reopen`. Carga: 20 R9, 19 R24/R27, 9 AC-39b coinciden (no persiste, `V08` nace `lista`, `hoja_en_bandeja` falso, reimprimir).
- WARNING N2-1: `correos_leidos` no tiene causa de guardado propia (5 solo guarda hechos «que condicionan el avance» por causa; este va por `quit`/`periodic`/pausa). Un cierre forzado tras buscar lo pierde: el jugador vuelve a buscar (barato, sin softlock); ningún GDD lo declara como consecuencia aceptada (20 R24 sí lo declara para `formulario_leido`). Documentar.
- INFO: tras la vía (a) (botón de pantalla) la hoja queda en la bandeja y `otorgar_sesion` solo se llama cuando el jugador interactúa con `V08` (R23): el jugador que imprime y se va a `C05` sin recoger no tiene `I-01`; 9 lo cubre con la pista de nivel 1 (resalta `V08`, R26).
- NO RECORRIDO: paso «resolver P1» (9: reglas 7, 25, 34 y AC de P1 no leídas); `C05` dibujado por 9.

## N3 Ascensor `C08` y Recepción — PARCIAL (22 ausente)
- Paso no recorrido: `llamada_completada` lo escribe 22 (inexistente). Supuesto: lo escribe y 21 `ESC7_RESTAURAR` y 8 `ESPERA` arrancan a +2,0 s (21 tabla fila 50; 8 r13, F4) sin dependencia mutua (21 r17): coherente.
- Verificado: `LISTO` → `interact(Entrar)` → `EN_USO` + «ascensor llamado» (8 r14) → 21 r17 pide `recepcion` con `control_final` = `ninguno` (4 r13 precondición) → pila [`exploración`, `sin control`(4)] → descarga → [`sin control`(4)] → «terminada» + traspaso 21 (misma fotograma, 1 r6) → `partida terminada` (4 r16, mismo fotograma, después) → 5 r29 `slice_completed` (única causa en «Sellada»). Duración declarada 7,0 s (t_fin 6,0 + h 1,0); control retenido ≈5,17 s tras el traspaso (21 F2).
- «Ascensor rechazado»: 4 r13 rechaza → 21 r17 emite → 8 `EN_USO` → `LISTO` (tope 20 s > 12 s de traspaso, 8 F4). Coherente.
- Fallo de carga en trayecto: 4 r14 (cortina negra, «carga fallida», repone `menú`, mensaje con «Volver al título»); 21 r11a cancela sin liberar; 5 r29 no escribe `completed`; re-inspección por «descarga total completada» (4 r15) → «Continuar» reanuda `planta` con llamada pendiente; 8 r14: `C08` `EN_APAGON` (caja completa, `llamada_completada` no se guarda). Sin bucle. Coherente en 4, 5, 8, 21 (A-5 de r4 resuelto: 5 r17 ya nombra el disparador).
- `C08` en apagón: `EN_APAGON` = `NO` (sin icono, sin pie, sin `MEGA_03`), 8 r13/r15 y Edge Cases; 21 r17 no interviene. OK.
- INFO N3-1: 21 tabla de escenas, fila `ESC8_ASCENSOR` (línea 51) está sangrada 6 espacios: puede romper la tabla Markdown.
- INFO: «escena lista» (origen del reloj) y «terminada» (traspaso) difieren ≈0,83 s en `recepcion` (21 F2); consistente, pero la tabla de 21 dice «origen = escena lista» y la regla 8a «traspaso en terminada»: se entiende solo con F2.
- NO RECORRIDO: dónde se coloca al jugador en la cabina (`spawn_elevator`, Open Question 2 de 4); `R01`/cierre de la escena 8 (no pedidos).

## N4 Repasar bolsillo — PARCIAL
Entrada r23 + AC-E15–E17, 20 R18–R22, 7 r27b: pulsación corta en flanco; solo si empieza en `exploración`; el `atrás` que cierra un modo o el menú se consume; en `sin control`, `menú`, `llamada` no existe. Coherente en 1, 20 y 7 (tabla `ACEPTADA`/`APLAZADA`/`RECHAZADA`).
- Lectura aplazada pendiente: segunda petición → `RECHAZADA(ya hay una petición aplazada)`; cursor de 20 no avanza (R20). Coherente.
- Transición bloqueante: Entrada r8 excepción → 7 `APLAZADA` (tope 3 s, pausa no cuenta). En la puerta (N1) la lectura aplazada se abre al `liberar_contexto`; 20 R12 «orden al abortar» (7 llama a `reposo()` antes) cubre la tarjeta aún sostenida.
- Con pausa: Entrada r7 hace que el `atrás` lo consuma el menú. **INFO N4-0:** la fila «menú de pausa abierto → `APLAZADA`» de 7 r27b solo es alcanzable por la petición programática (carta P6), nunca por el repaso (Entrada r23 no lo entrega en `menú`).
- 0 documentos: R19 silencio total. Un documento: lo reabre siempre (R22).
- WARNING N4-1: `lectura abierta` (7 r27b, tras petición aplazada) lleva solo el ID. 20 R20 la usa para avanzar el cursor; si la aplazada que se abre es la carta `I-07` pedida por 9, 20 recibe el aviso sin haberla pedido y puede avanzar el cursor indebidamente. Falta especificar que 20 solo avanza con el ID que pidió él.
- WARNING N4-2 (carta P6, D9-23): si el jugador pulsa `atrás` en `exploración` mientras la vista de `D01d` está `Saliendo` (o la presentación del P6 sigue ≈1,9 s), su repaso queda `APLAZADA` y la petición de 9 (`abrir_lectura(I-07)`) se `RECHAZA` («ya hay una petición aplazada»): se abre un documento viejo y la carta del clímax no se abre sola. 7 r27b dice que la carta «se abre igualmente», salvo este caso, que no está en 7, 20 ni AC-42 de 9 (no leído). Opciones: prioridad de la petición del dueño sobre la del repaso, o ignorar `repasar_bolsillo` mientras `pendiente_carta`.
- `I-05`/`I-06a`: relegibles, orden de 20 R6/R22; 10 r17 confirma que 10 no los presenta. Sin hallazgo.
- NO RECORRIDO: 9 r16.6/AC-42 (qué hace 9 ante `RECHAZADA`).

## N5 Caja y P5 — PARCIAL
10 r11/r14/r15/r19 y 9 r16–r19: orden de escritura (hechos → `solved_flag` → estado → `EV_PUZZLE_SOLVED_*` → «compartimento completado» → presentación → `cerrar_vista`); P5 `DEFERRED` solo con la vista abierta (9 r17/r18, 10 r14b); `pendiente_revelacion` = verdadero **al iniciar**, falso al terminar tras `caja_c3` (9 r19; 3 reglas 4–5; 5 causa `reveal_pending`). Cierre a mitad: 9 r18 sin penalización, 10 r14 sin aviso → sin cierre, `ABIERTO`. Carga con `pendiente_revelacion` verdadero: 10 línea 71 → C3 `ENTREABIERTO`, 9 reproduce la secuencia desde el principio al reabrir. `play_open(4)` a t=0,3 s tras `SFX_LOCK_CLICK` (9 r16.6, 10 r11) y `set_final_pose(n)` idempotente sin animar (10 r15). Coherentes.
- WARNING N5-1: tras interrumpir en sesión, C3 queda `ABIERTO` (10 r14) y tras cargar `ENTREABIERTO` (10 línea 71): la pose visible difiere según haya habido carga. Sin impacto en reglas, pero la tapa «cerrada a medias» al cargar contradice el relato del jugador. Unificar o declarar.
- INFO N5-2: 9 r19 dice «al volver a comprometerse» (gesto de confirmación) y 10 dice «al reabrir»: el disparador de la repetición de la secuencia debe ser uno solo.
- INFO: «compartimento completado» (4) y `caja_completa` ocurren en t=0 del P6, antes de `play_open` y la carta (10 línea 63): consistente; no afecta a 8 (los lectores no leen `caja_completa`; el ascensor sí, pero `EN_APAGON` solo importa fuera de la vista).
- NOT SOURCEABLE (declarado en 10 r22 y 9): pausa vs `AnimationPlayer`; AC-21 sin confirmar. No se asume.
- NO RECORRIDO: cadena de tiempos `D01a`–`D01d` (7 F4, `BOX_Cn_OPEN`, `t_vista_entrada_s`): 7 F4 y Tuning Knobs no leídos.

## E1 Revelación del P5 con pausa/cierre/carga — PARCIAL
Cierre/carga cubiertos en N5. Pausa: 9 r17 reloj de juego; «línea de voz» no bloquea (r20). INFO: 9 r19 admite que el guardado puede ser anterior a la escritura del hecho (ventana `t_agrupar` 0,1 s) mientras 5 dice que `reveal_pending` cubre el cierre forzado: las dos frases se complementan, no se contradicen.

## E3 Llegada a Recepción y sellado — PARCIAL
4 r16 ↔ 5 r29 ↔ 21 r8: coinciden (único emisor 4; mismo fotograma; `slice_completed` único admitido en «Sellada»; título solo «Nueva partida»). Cierre del juego antes de la escritura → se repite la llamada (consecuencia aceptada, 5 r11). Sin hallazgo.

## E4 «Nueva partida» desde el título, escena 1 dirigida — PARCIAL
Cadena: [`menú`] → [`menú`, `sin control`(4)] → traspaso 21 (sin aviso) → t_fin 14,0 → 21 pide `exploración` → [`exploración`] sin `menú` (1 r6 viñetas 3–4, tabla fila 2, AC-E13b; 4 tabla fila 1; 21 r8). Coherente.
- **BLOCKER E4-1 (hueco de pila, 1↔4↔21).** Entre el traspaso (≈2 s) y los 14 s la pila es [`menú`(título), `sin control`(21)]. La pausa está permitida en `sin control` (1 r7, 21 r9) y fuera de la carga → [`menú`, `sin control`(21), `menú`(pausa)]. «Nueva partida» desde esa pausa dispara «absorber el `sin control` ajeno» (1 r6 viñeta 7, AC-E13c, 4 tabla fila 5, 21 PA-2), pero todas lo definen solo para [`sin control`(21), `menú`]; la pila de tres elementos cae en «cualquier otra pila… rechaza y registra». Efecto: 4 no abre su `sin control`, 21 cancela su línea (r11b) sin tocar la pila, el `sin control`(21) antiguo sigue contando su tope durante una carga de ≈12,9 s (`partida_nueva` desde el título, 21 F5) y puede expirar a mitad de carga restaurando el `menú` del título, o ser traspasado sobre un dueño obsoleto. Comportamiento indefinido en un camino plausible (Nueva partida → pausa → Nueva partida). Arreglo: definir *absorber* como «descartar todo `sin control` ajeno y todo `menú` bajo la cima de pausa» (incluido el de título) y añadir la fila y su AC en 1, 4 y 21. Además, el absorber sigue «propuesta pendiente» en los tres GDDs.
- INFO: «Volver al título» desde ese mismo estado queda cubierto (*Reponer `menú`* → [`menú`]).

## E5 Cambio de ajustes en vivo — PARCIAL
6: `reducir_movimiento` se lee en el paso 1 de la carga (4 r11) y «en cada disparo» (21 r23): no cambia a mitad de carga (pausa bloqueada en carga, 1 r7). 21 F3 usa `d_cierre` 0,8 s como cota superior; con 0,1 s la secuencia es más corta: sin riesgo. INFO: 4 r11 no dice cuándo lee la clave para el fundido propio `cierre` (¿al pedirlo o al empezar la escena 8?). Los otros ajustes (volúmenes, `multiplicador_pie`) no recorridos (consumidores 23/24 inexistentes).

## E7 Vuelta al título desde Recepción — PARCIAL
Pila [`exploración`] o [`sin control`(21)] + pausa → «Volver al título» → 4 descarga total ≤3,0 s† → *Reponer `menú`* → [`menú`] → «descarga total completada» → 5 re-inspección (`terminada`: solo «Nueva partida»); 21 cancela al recibirlo (21 r11c, Edge Cases). Coherente con 1 AC-E13b y 5 r17.
- WARNING E7-1: entre la petición de descarga total y «descarga total completada» (≤3,0 s) el director no está cancelado (21 solo cancela al recibir el aviso final, Edge Cases) y, si el tiempo de juego se reanuda al elegir «Volver al título» desde la pausa, su línea de `ESC8_CIERRE` puede pedir `VO_V_12x`, el fundido propio, la tarjeta final o su propia descarga total (r22 paso 8) sobre la descarga en curso. Falta que 21 cancele en «descarga total solicitada» o que 4 rechace una segunda y quede el reloj detenido hasta el aviso (a verificar en 21 AC-21-28 y 25, no existente).

## NO LEÍDO / NO RECORRIDO (por nombre)
- GDD 2 (jugador-en-primera-persona) entero: contrato de gestos `HAND_*`, `sostener`/`soltar`, D-19.
- GDD 9: reglas 1–15, 20–22, 24–37, Tuning Knobs, AC (P1/`C05`, `needs_items`, AC-39b, AC-42, F8).
- GDD 7: F4 y Tuning Knobs (cadena `D01a`–`D01d`), regla 30 (`bloquear_contexto`) solo vía citas de 8, regla 3.
- GDD 3: reglas 7–13 y CA (derivado `caja_completa`); 5: reglas 1–5, 7–16, 19–28, F1–F4; 6: UI y AC; 18 y 19: AC.
- Slice v0.3/v0.4 (no leído); `systems-index.md` (no leído).
- Dependientes de GDDs inexistentes: **22** (llamada: `llamada_completada`, descolgar), **23** (audio: «línea terminada», pausa de audio), **24** (UI/pie), **25** (menú de pausa/título: qué hace «Volver al título» con el tiempo de juego), **27** (título/tarjeta final), **28** (luces/efectos). Los pasos que dependen de ellos están marcados NO RECORRIDO en cada escenario.
