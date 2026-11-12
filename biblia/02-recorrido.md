# 02 · Recorrido de la noche

La noche entera, en el orden en que la juega alguien que no se salta nada. Cada escena dice: dónde, qué pasa, qué aprende el jugador, qué tiene que hacer y qué queda guardado. Los puzles se detallan en `04-puzles.md`; aquí solo se sitúan.

**Cómo se juega [NUEVO]:** el jugador camina en primera persona entre salas. Al interactuar con un objeto-puzle (cajetín, lámparas, caja) entra en **modo examen**: la cámara deja de ser la de Vera y pasa a orbitar el objeto como en el piloto (ver `03` M0). Sale con «Volver». Fuera del modo examen no se resuelve ningún puzle.

---

## Escena 1 · Llegada (23:40) · Despacho de Vera

- **Qué pasa:** fundido desde negro. Lluvia contra el cristal, un ventilador que vibra. Megafonía `MEGA_01`. Voz interior `VO_V_01`. Llega un mensaje del contacto «Guardián»: «¿Jugamos esta noche?». Vera contesta «Ahora no». Respuesta automática: «Este número ya no está disponible».
- **Qué aprende el jugador:** Vera es nueva, está sola, busca el «archivo de transición», y el Guardián ya no está localizable. Con lo de `01` §4, «jugar» significa algo concreto que entenderá en el despacho D.
- **Qué hace:** nada obligatorio. Puede mirar la caja de cartón y el peluche cúbico (el peluche es el símbolo de Vera en la caja: conviene que lo vea).
- **Banderas:** ninguna.

## Escena 2 · El correo (00:05) · Despacho de Vera

- **Qué pasa:** en el ordenador, el jugador busca «transición». Salen cuatro correos numerados (ref. 1 a 4) y dos sin número.
- **Qué hace:** leer y pulsar «Imprimir». La impresora saca I-01.
- **Qué aprende:** el Guardián preguntó, luego pidió confirmación, luego registró la solicitud, y Dirección la dio por hecha. El orden de impresión está revuelto.
- **Banderas:** `correos_leidos`.

## Escena 3 · Pasillo y Archivo (puerta A)

- **Qué pasa:** junto a la puerta A hay un **cajetín de latón** atornillado a la pared (puzle 1, `04` §2). Tiene una tapa con asa en el lateral y cuatro tambores numerados en el frente.
- **Qué hace:** levanta la tapa y lee cuatro horas grabadas; las cruza con la impresión; gira los tambores a `2 · 1 · 3 · 4`; del cajón sale una llave; la mete en la cerradura y le da un cuarto de vuelta. La puerta A se abre.
- **Dentro del Archivo:** el formulario de traslado (I-04) en una caja (A03), lectura en A04. Al leer la fecha, la lluvia sube de intensidad y suena `VO_V_04`. En un cajón (A05), la tarjeta de la Sala B (I-02) y la tarjeta sin foto (I-03).
- **Qué aprende:** la solicitud se registró después de que el formulario pareciera firmado, y Vera nunca confirmó. La firma «es suya, o se parece tanto que da igual».
- **Banderas:** `archivo_abierto` (al abrirse la puerta), `formulario_leido`, `tarjeta_B`, `tarjeta_D`.
- **Guardado:** al abrirse la puerta.

## Escena 4 · Pasillo (00:40)

- **Qué pasa:** megafonía `MEGA_02`: «Reunión de dirección en la sala nueve B». No hay nadie. Las luces parpadean. En el cristal, el reflejo de Vera llega un instante tarde; al girar la cabeza vuelve a la normalidad.
- **Qué es:** un aviso, no un ataque. Con «reducir sobresaltos», la luz no parpadea.
- **Banderas:** ninguna.

## Escena 5 · Sala de Reuniones (puerta B)

Se puede visitar antes o después del despacho D. Sin `tarjeta_B`, la puerta dice que está cerrada, sin más.

- **Qué pasa:** tres lámparas de escritorio sobre la mesa de cristal (puzle 2, `04` §3). En el cristal, invisible a la luz normal, el memorando escrito en espejo. En el aparador (B05), la nota `NOTA_02`: «No te quites la carga. Yo tampoco».
- **Qué hace:** gira la cabeza de cada lámpara hasta que su haz revele un fragmento. Con los tres a la vez, el memorando entero queda legible.
- **Qué aprende:** la versión oficial. «Aprobado a petición de la interesada.» «Ratificación pendiente de firma del responsable.» Contradice el formulario y la confesión, y deja una duda: ¿qué responsable no ha firmado?
- **Voz interior:** `VO_V_08`.
- **Banderas:** `memo_leido`, `pos_L`, `pos_C`, `pos_R`.

## Escena 6 · Despacho del Guardián (puerta D)

- **Entrada:** abrigo mojado en la silla, taza fría, la foto del equipo en la pared (D04) con Vera abajo a la derecha, al margen, sosteniendo el peluche cúbico. Sobre la mesa, **la caja** (D01).
- **La caja** (puzles 3 a 6, `04` §4) se resuelve en cadena:
  1. **Puzle 3 · ¿Quién falta?** Frente de la caja: la foto del equipo sin Vera, y tres tambores con los símbolos de la fila de abajo. La tapa lateral tiene el pie de foto, con el tercer símbolo rayado. La combinación correcta deja el tercer tambor en la cara **limada**: el sitio de Vera es un hueco. Se abre el cajón: dentro, `NOTA_01` («La transición es tuya») envuelta alrededor de un engranaje.
  2. **Puzle 4 · ¿Qué carga acepta?** Trasera: el tablero de tareas grabado en latón y un eje vacío. Vera encaja el engranaje y gira la manivela. Se encienden las tres primeras tareas; en la cuarta, «Carta a Dirección», la manivela topa. Seguir girando en el mismo sentido es **asumirla**; volver hacia atrás es **devolverla**. Las dos sueltan el mecanismo. Aparece la lista de tareas del Guardián (I-05).
  3. **Puzle 5 · ¿Qué cambia?** Derecha: un medallón de espejo que ahora gira. Refleja la foto de la pared. A 40°, el reflejo encaja sobre la pequeña foto de la caja que hay bajo el cristal y solo sobra una figura: Vera. Suena la grabación `VO_G_07`.
  4. **Puzle 6 · ¿Qué responde?** Arriba: el pestillo con tres luces, ya verdes. Se desliza, las dos tapas se abren y sube una carta con letra de Vera, sin primera frase, y tres tiras de papel. Vera elige una. La carta queda completa (I-07).
- **Banderas:** `caja_c1`, `t4_decision` (antes que `caja_c2`), `caja_c2`, `caja_c3` (con `pendiente_revelacion` mientras suena la grabación), `carta_variante`, `caja_c4`, `caja_completa`.
- **Guardado:** al completar cada compartimento.
- **Salida:** al cruzar la puerta de D con `caja_completa`, la luz del despacho se apaga.

## Escena 7 · Apagón y llamada (02:30)

- **Qué pasa:** apagón completo (con «reducir sobresaltos», oscurecimiento gradual de al menos 2 s). Sillas rodando por el pasillo. Tecleo cerca. Suena el teléfono del despacho de Vera: el número que aparece es **su propia extensión**.
- **Qué hace:** ir al despacho y descolgar. Silencio y respiración.
- **Primera frase**, según `carta_variante`: `VO_G_12A`, `VO_G_12B` o `VO_G_12C`.
- **Respuestas** (botones): «Estoy bien» (A), «Estoy desbordada» (B), «No quiero hablarlo ahora» (C), «No responder» (D). Respuesta del Guardián: `VO_G_13A` a `VO_G_13D`.
- **Si pasan 20 s sin responder:** llanto contenido y `VO_G_14_RET` o `VO_G_14_ASG` según `t4_decision`. Los botones siguen ahí; no se elige nada por el jugador.
- **Fin:** cuelga. Vuelve la lluvia.
- **Banderas:** `llamada_iniciada`, `respuesta_llamada`, `llamada_completada`.
- **Guardado:** al descolgar. Si el jugador cierra durante la llamada, vuelve al despacho y la llamada se repite entera.

## Escena 8 · Recepción (03:40 a 04:10)

- **Qué pasa:** la lluvia cesa. El ascensor baja despacio. En recepción, el libro de visitas abierto: «Vera · 23:40 · Planta 9» y, debajo, hace nueve días, «Vera · 22:12 · Planta 9». La letra es idéntica. La V de la segunda está cerrada hacia dentro.
- **Última frase de Vera**, según `respuesta_llamada`: `VO_V_12A` a `VO_V_12D`. Cierre común: `VO_V_12E` «La V no me convence».
- **Fin:** corte a negro, título, «Continuará». La partida queda sellada.
- **Si el jugador intentó usar el ascensor antes de la llamada:** no responde, y suena `MEGA_03`.

---

## Mapa de dependencias

```
correos_leidos ──► Puzle 1 (cajetín) ──► archivo_abierto ──► tarjeta_B ──► Puzle 2 (lámparas) ──► memo_leido
                                                         └─► tarjeta_D ──► Caja: P3 ─► P4 ─► P5 ─► P6 ──► caja_completa
                                                                                                         │
                                                                         salir de D ◄────────────────────┘
                                                                              │
                                                                       Apagón y llamada ──► llamada_completada ──► Recepción
```

La Sala B no bloquea nada: es la única pieza opcional de la historia. Pero el memorando da sentido a la ficha T4 y a la frase «ratificación pendiente», así que el recorrido está pensado para que el jugador llegue a B antes que a D (el lector de B está más cerca del Archivo que el de D). **[NUEVO]**

## Duración orientativa

| Tramo | Minutos (jugador nuevo) |
|---|---|
| Escenas 1–2 | 2–3 |
| Puzle 1 + Archivo | 3–5 |
| Pasillo + Puzle 2 | 3–5 |
| Caja (P3–P6) | 8–12 |
| Llamada | 2–3 |
| Recepción | 1–2 |
| **Total** | **≈ 19–30** |

A medir en playtest. No se promete ninguna cifra.
