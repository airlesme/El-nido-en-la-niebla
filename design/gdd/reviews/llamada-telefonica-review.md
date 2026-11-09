# Revisión independiente · GDD 22 «Llamada telefónica» (lote Feature 2)

**VEREDICTO: NEEDS REVISION** (1 bloqueante, 12 avisos, 5 info)

Las 8 secciones están completas. Las reglas de 3, 5, 7, 18, 21 y 9 que cita 22 existen y dicen lo que 22 afirma, con las excepciones de abajo.
Pilares y anti-pilares respetados: no hay medidor, ni respuesta «correcta», ni confirmación de intención, ni colgar que deje la partida sin respuesta.

## BLOQUEANTE

**B-1 · El temporizador de 60 s de 21 puede reiniciar el timbre en plena llamada y 22 no lo cubre.**
- 21, `ESC7_APAGON` (línea 48 de director-de-escenas.md): «60,0† `TELEFONO_SUENA` y `V02` pasa a `vibrando` si no lo está ya».
- Con la llamada en curso `V02` está `en_llamada` (22, R3c), así que no «está ya» vibrando. El efecto no tiene guarda `¬llamada_iniciada`. El único guard documentado es de `ESC7_TIMBRE` (`T-OFI-IN`).
- Escenario normal: apagón en t=0, el jugador entra a ~10 s, la llamada llega a las opciones a ~21 s, y con la señal de los 20 s (y esperas ilimitadas) se pasa de los 60 s. 21 reescribe `V02` a `vibrando` y reabre `SFX_PHONE_BUZZ` en bucle durante la llamada.
- Contradice la máquina de 22 (R3c, R19, «V02 `en_llamada`») y el pilar *Tensión sin castigo*/*El espacio expresa la emoción*.
- No figura en «Cambios requeridos» (nº 6 solo cubre la reanudación) ni en Edge Cases (el caso de la línea 155 solo cubre «no vuelve al despacho»).
- Arreglo: guarda `¬llamada_iniciada` en el efecto de 21 y un edge case y AC en 22.

## AVISOS

**A-1 · Dueño del estado de `V02` ambiguo (22 R3c/R19 frente a 21 R15 y PA-7).**
- 21 R15 devuelve `V02` a `reposo` en «llamada iniciada» o «interacción ejecutada». 22 R3c lo pone en `en_llamada` justo después.
- 22 no define quién ejecuta los «estado de objeto pedido» de 21 (PA-7 de 21 dice que el dueño, 22 para `V02`), ni el orden entre los dos escritores.
- Si el aviso llega en cola, `V02` acaba en `reposo` durante la llamada.
- Falta en «Cambios requeridos» (21 R15) y en el registro de avisos: 22 no declara que recibe «estado de objeto pedido».

**A-2 · Reanudación sin sonido de timbre.**
- R30 pone `V02` en `vibrando`, pero no pide `SFX_PHONE_BUZZ`. El bucle lo arranca 21 solo en `ESC7_TIMBRE`/60 s.
- AC-21-16b dice que 21 no emite nada de `V02` con `llamada_iniciada`.
- OQ nº 9 asume que el bucle es de 21. Sin sonido, el teléfono vibra en silencio (falla el caso AC-22-18 «V02 vibrando» a nivel sensorial).

**A-3 · Estado final contradictorio.**
- Encabezado de Detailed Rules: «ninguno es terminal salvo `COMPLETADA`» y Overview acaba en `Completada`.
- R19: «la máquina pasa a `INACTIVA`». R2 exige `INACTIVA` para `can_interact`.
- `COMPLETADA` no tiene definición operativa (¿se permanece en ella o se vuelve a `INACTIVA`?). AC-22-22/-15 no lo fijan.

**A-4 · Cita falsa del índice (Dependencies, línea 169).**
- Dice «Índice de sistemas, fila 22: duras 1, 3, 5, 7, 18; blanda 2». El índice actual (fila 22) dice duras 3, 5, 7, 18 y blandas 1, 2. La tabla de 1 (línea 396) también dice Blanda.
- Los Cambios nº 2c y 9 reconocen la divergencia, pero el texto la presenta como cita. Regla común: manda el dependiente (22 declara Dura con 1), así que deben cambiar índice y 1.
- Cambio nº 9 añade «blandas 2, 23, 26»; 23 y 26 no tienen GDD.

**A-5 · Referencia no verificable.** La fila de 1 dice «1 la anota Blanda en su tabla (cambio nº 8)». No encontré un «cambio nº 8» en entrada-y-controles.md (sin sección «Cambios requeridos» por Grep). La anotación sí existe (línea 396), pero la referencia está rota o es de otro documento.

**A-6 · F5 aritmética.**
- «Con la lectura (b) ... 20,4–48,8 s y seguiría dentro» de 0,4–1,0 min (24–60 s): falso, 20,4 s < 24 s.
- «Elección en menos de ≈7 s» fuera de rango: con los propios números (15,8 + `t_e` < 24) sale `t_e` < ≈8,2 s.
- «Las cinco ramas (A–D...)» son cuatro.

**A-7 · F3/F4 usan `L14` = 5 s con ASG ≈ 3 s y RET ≈ 1 s.** La fila «tras la señal completa» (29,0 s, T_compl = 44,8 s) es un máximo, no el valor real. Además la tabla no cubre `t_e` en [20, 29).

**A-8 · Cambio nº 3(a) a 9 presentado como corrección firme** («10,8 s, no 14,8 s») cuando depende de D22-1/OQ nº 1, que el propio 22 deja abierta. La lectura literal más simple de C.7 («+4,0» desde el pulso, con la animación solapada, que D7-34 de 7 permite al reservar el gesto antes de `interact()`) la descarta 22 en D22-1 sin consultar. Está en OQ nº 1, así que el protocolo se cumple, pero los cambios a 9 no deberían aplicarse antes de la respuesta.

**A-9 · Contradicción interna sobre esperar.**
- R15: «El jugador nunca espera a que acabe una línea para responder».
- Edge Cases (línea 142) y AC-22-12: si 23 no puede interrumpir, la respuesta espera hasta 9,0 s.
- Debe leerse «salvo que 23 no pueda interrumpir», o marcarlo como degradación aceptada.

**A-10 · AC-22-16 incompatible con las reglas.** Dice «ninguna otra escritura o aviso de 22 existe», pero 22 emite «línea pedida» y «sonido de llamada pedido» ‡ (R7, R14, R19, Cambio nº 1). Debe decir «ningún otro hecho/aviso de cambio».

**A-11 · Manos: R3 frente a R24.** R3 dice que 2 mantiene `HAND_PHONE_HOLD` desde el final de `ANIM_PHONE_PICKUP`. R24 dice «durante `LINEA` a `CIERRE`», que excluye `SILENCIO` y `RESPIRACION`. El catálogo de 2 (línea 402) dice «durante la llamada».

**A-12 · Tipos de AC.**
- AC-22-06 está marcada L pero exige «comparación de captura» (debe ser PV).
- Sin AC para: contexto rechazado por 1 (Edge línea 157), cierre antes del sellado (R28/R29), pausa durante la guarda, R16 `t4_decision` sin fijar en formato integración.
- Ninguna AC cubre el solape con el temporizador de 60 s (ver B-1).

## INFO

- Aritmética de F1–F3 correcta: 0,8+2,0+2,0 = 4,8; +5,0+1,0 = 10,8; filas 16,4 / 23,8 / 35,8 / 44,8. En minutos: 0,27–0,75. Rango F2 8,8–13,8 correcto. 9 estima 14,8 s hasta las opciones (8,8+5+1), coherente con la lectura (b) que 22 describe.
- El orden «gesto reservado antes de `interact()`» de R3 coincide con 7 (D7-34, regla 3), y el gesto corre concurrente con `DESCOLGANDO`; no hay doble conteo de 0,8 s.
- `llamada_iniciada` al pulsar «Descolgar»: coincide con 5 R11/R12 (restricción «como máximo al descolgar», AC-16/AC-18/AC-34) y con 3 (nota tras la tabla de hechos; dueño único 22). `respuesta_llamada` y `llamada_completada` nunca van a disco: coincide con 5 R11 y AC-14/15.
- Repetición de la elección: D.2 (L1070) y 5 R12 ya dicen que la llamada se repite entera hasta completada y guardada, así que el borrador es coherente con el slice. OQ nº 3 (confirmar D-15) y OQ nº 7 recogen la parte de tono. Para ese punto no hace falta más.
- Sin afirmaciones de Godot 4.7 en el documento. Valores numéricos con † o fuente (C.7, 9, 2). No hay valores inventados sin marcar.
- Decisiones de tono/pilares/alcance: D22-4 (sin confirmación), D22-18/20 (subtítulos) y D22-15 están en Open Questions. D22-9 (no colgar) y D22-10 (cursor oculto) son decisiones de diseño con efecto en tono/accesibilidad y solo figuran en la tabla de decisiones, no como pregunta abierta (D22-10 sí figura en Cambios requeridos a 1). Conviene pasarlas por el usuario.

## NO LEÍDO / NO VERIFICADO

- design/gdd/escena-de-planta.md (4): reglas 13/14 solo comprobadas por citas en 3, 1 y 5.
- 9: no verifiqué si su Dependencies lista 22 (Cambio nº 3b lo pide; 22 lo reconoce como pendiente).
- 18: D18-10 y reglas 5/16/22 solo por citas de otros GDD y el Grep. La regla 22 y los grupos `VO_G_14` sí están.
- 8: solo leí la regla 13 y la tabla de estados de `C08`; no el texto de `MEGA_03` en edge cases.
- Slice: §14 audio, B.7, Anexo A. Solo leí §8, §11, §13.3, C.7, D.2 y las decisiones D-03/D-14/D-15 por Grep.
- game-concept.md: solo por Grep de «llamada»; no leído entero.
- Texto de 1 reglas 6 y 8 y su Edge Cases: solo líneas sueltas (45, 123, 139, 343, 396). No comprobé si 1 permite pedir `llamada` mientras un gesto de 7 bloquea el contexto (línea 338 sugiere que la pausa sí funciona).
- Cómo 3 entrega los avisos (síncrono o en cola) para A-1: no lo comprobé.
