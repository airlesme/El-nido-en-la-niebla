# 05 · Textos

Todos los textos que el jugador oye o lee, con su ID. **Este archivo manda:** si un texto de `04` no coincide con este, vale este. La tabla de avisos (§4) se genera desde `04-puzles.md`; si cambiáis un aviso, cambiadlo en `04` y regenerad.

## 1. Voces [CANON]

| ID | Hablante | Texto | Escena |
|---|---|---|---|
| `MEGA_01` | Megafonía | «Turno de noche. Recuerde que la planta nueve está en modo de ahorro energético». | 1 |
| `VO_V_01` | Vera | «Tres días en esta unidad y todavía no sé dónde está el archivo de transición. Solo sé que me toca a mí». | 1 |
| `VO_V_04` | Vera | «Hace nueve días estaba en un avión a Lisboa. Me acuerdo porque no pude dormir. Y la firma es mía. O se parece tanto que da igual». | 3 |
| `MEGA_02` | Megafonía | «Reunión de dirección en la sala nueve B». | 4 |
| `VO_V_08` | Vera | «Ratificación pendiente. Llevo tres días aquí. Da igual si está firmada». | 5 |
| `VO_G_07` | El Guardián | «Venga, que somos un equipo». [pausa] «No. Esa toma no. Lo pedí sin preguntarte, Vera. Lo pedí y después te lo conté como si fuera tuyo». | 6 (P5) |
| `VO_G_12A` | El Guardián | «Has escrito que estás bien. ¿Estás resfriada?». | 7 |
| `VO_G_12B` | El Guardián | «Has escrito que no sabes qué firmaste. ¿Estás resfriada?». | 7 |
| `VO_G_12C` | El Guardián | «Has escrito que todavía no puedes enviarlo. ¿Estás resfriada?». | 7 |
| `VO_G_13A` | El Guardián | «Ya. Eso dijiste también la última vez». | 7 |
| `VO_G_13B` | El Guardián | «Lo sé». | 7 |
| `VO_G_13C` | El Guardián | «Vale. Pero la caja sigue en tu mesa». | 7 |
| `VO_G_13D` | El Guardián | «Entonces hablo yo. Te he dejado la caja abierta. Cuando quieras». | 7 |
| `VO_G_14_RET` | El Guardián | «Sigo aquí.» (si `t4_decision` = `returned`) | 7 |
| `VO_G_14_ASG` | El Guardián | «Sigo aquí. La carta a Dirección ya va firmada.» (si `t4_decision` = `assigned`; texto provisional) | 7 |
| `VO_V_12A` | Vera | «Le dije que estaba bien. Ninguno de los dos se lo creyó». | 8 |
| `VO_V_12B` | Vera | «Le dije que estaba desbordada. Era lo más cierto de la noche». | 8 |
| `VO_V_12C` | Vera | «No quise hablarlo. La caja sigue en mi mesa». | 8 |
| `VO_V_12D` | Vera | «No dije nada. Él habló por los dos». | 8 |
| `VO_V_12E` | Vera | «La V no me convence». | 8 |
| `MEGA_03` | Megafonía | «Planta en modo de ahorro energético». (redacción final pendiente) | Ascensor antes de tiempo |

**Opciones de la llamada:** «Estoy bien» (A) · «Estoy desbordada» (B) · «No quiero hablarlo ahora» (C) · «No responder» (D).

## 2. Documentos y mensajes [CANON]

| ID | Soporte | Texto |
|---|---|---|
| `SMS_01` | Mensaje del contacto «Guardián» | «¿Jugamos esta noche?» |
| `SMS_02` | Respuesta de Vera | «Ahora no» |
| `SMS_03` | Aviso del teléfono | «Este número ya no está disponible» |
| Correo ref. 1 | Lunes 11:40 | «Traslado de Vera: pendiente de tu confirmación. — G.» |
| Correo ref. 2 | Lunes 09:14 | «Vera, ¿te viene bien que lo hablemos esta semana? — G.» |
| Correo ref. 3 | Lunes 16:02 | «Solicitud registrada a nombre de Vera. Yo me encargo del resto. — G.» |
| Correo ref. 4 | Martes 08:55 | «Vera ya figura en la unidad nueva. — Dirección» |
| Correo sin número | Lunes 10:30 | Recordatorio de cambio de extensiones (texto libre, administrativo) |
| Correo sin número | Martes 14:00 | Aviso de mantenimiento del aire acondicionado (texto libre, administrativo) |
| Pie de I-01 | Impresión | «Ordena por hora de envío» |
| `DOC_01` | Memorando en el cristal | «Traslado de Vera: aprobado a petición de la interesada. Ratificación pendiente de firma del responsable». |
| `NOTA_01` | Nota del cajón de la caja (letra del Guardián) | «La transición es tuya». |
| `NOTA_02` | Nota del aparador de la Sala B (letra del Guardián) | «No te quites la carga. Yo tampoco». |
| `CARTA_A` | Primera frase (letra de Vera) | «Estoy bien. Es lo que escribiría si no fuera verdad». |
| `CARTA_B` | Primera frase | «La verdad es que no sé qué firmé». |
| `CARTA_C` | Primera frase | «Todavía no puedo enviarte esto». |
| `CARTA_CUERPO` | Cuerpo de la carta | «No quiero que me digas que somos un equipo. Quiero que me digas por qué firmé». |
| Libro de visitas | Recepción | «Vera · 23:40 · Planta 9» / debajo: «Vera · 22:12 · Planta 9» (hace nueve días) |

**Orden de impresión de I-01:** ref. 3, aviso de extensiones, ref. 1, ref. 4, aviso de aire acondicionado, ref. 2. Cada bloque lleva «Enviado: hh:mm».

## 3. Grabados y rótulos de los objetos [NUEVO]

| ID | Dónde | Texto |
|---|---|---|
| `GRB_P1_PLACA` | Cajetín, bajo la tapa | «L 09:14 · L 11:40 · L 16:02 · M 08:55» / más pequeño: «Lo demás es ruido.» |
| `GRB_P1_ETIQUETA` | Etiqueta de la llave I-08 | «ARCHIVO» |
| `GRB_CAJA_BASE` | Base de la caja del Guardián | «¿Jugamos?» |
| `GRB_P3_ROTULO` | Sobre los tambores de la caja | «FILA DE ABAJO» |
| `GRB_P3_PLACA` | Caja, bajo la tapa izquierda | «Fila de abajo:» [taza] [paraguas] [símbolo rayado] |
| `GRB_P4_FILA_1` | Tablero de la trasera | «Cliente Lima · revisión antes del jueves · Vera» |
| `GRB_P4_FILA_2` | Ídem | «Revisión de contrato · tres semanas parada · Guardián» |
| `GRB_P4_FILA_3` | Ídem | «Mudanza del archivo · sin fecha · Dirección» |
| `GRB_P4_FILA_4` | Plaquita suelta | «Carta a Dirección · explicar la solicitud de traslado en nombre de la interesada · ~~Vera~~ G» |
| `GRB_P4_FLECHAS` | Junto al cubo de la manivela | «↻ La asumo» · «↺ La devuelvo» |
| `GRB_P6_TIRA_A` | Tira de papel (letra de Vera) | «Estoy bien.» |
| `GRB_P6_TIRA_B` | Ídem | «La verdad.» |
| `GRB_P6_TIRA_C` | Ídem | «Todavía no.» |

**Lista de tareas del Guardián (I-05) [CANON en el concepto, texto PROPUESTO]:** cuatro entradas a mano, mismas tareas que el tablero; en la última, «Carta a Dirección — Vera», con «Vera» tachado.

## 4. Avisos de contexto (pensamientos de Vera) [NUEVO]

Generados desde `04-puzles.md`. Texto, sin voz. Duración por defecto 4,2 s; los de «primera vez» 5,2 s.

| ID | Cuándo | Texto |
|---|---|---|
| `TST_P1_ENFOQUE_FRENTE_A` | Enfocar el frente, sin resolver | «Cuatro tambores. Números del uno al cuatro, un teléfono y un ventilador. Un candado de oficina.» |
| `TST_P1_ENFOQUE_FRENTE_B` | Enfocar el frente, resuelto y llave sin coger | «El cajón se ha abierto. Hay una llave.» |
| `TST_P1_ENFOQUE_FRENTE_C` | Enfocar el frente, llave cogida | «Aquí ya no queda nada.» |
| `TST_P1_ENFOQUE_IZQ_A` | Enfocar la izquierda, tapa sin levantar | «Una tapa con asa. Se levanta.» |
| `TST_P1_ENFOQUE_IZQ_B` | Enfocar la izquierda, tapa ya vista | «Cuatro horas. Lunes y martes.» |
| `TST_P1_TAPA_VISTA_CON_I01` | Primera vez que se lee la placa, con I-01 en el bolsillo | «Cuatro horas y "lo demás es ruido". Son los correos. Ha convertido sus correos en una combinación.» |
| `TST_P1_TAPA_VISTA_SIN_I01` | Primera vez que se lee la placa, sin I-01 | «Cuatro horas y "lo demás es ruido". Algo en mi ordenador tendrá estas horas.» |
| `TST_P1_ENFOQUE_DER_A` | Enfocar la derecha, sin llave | «La cerradura del Archivo.» |
| `TST_P1_ENFOQUE_DER_B` | Enfocar la derecha, llave seleccionada | «La llave del cajón. Probemos.» |
| `TST_P1_CERRADURA_SIN_LLAVE` | Tocar la cerradura sin llave | «Sin llave no hay archivo. Ni transición.» |
| `TST_P1_CERRADURA_SIN_SELECCION` | Tocar la cerradura con la llave sin seleccionar | «La llave está en el bolsillo. Tengo que sacarla.» |
| `TST_P1_RESUELTO` | Tambores resueltos | «Dos, uno, tres, cuatro. Así fue la semana.» |
| `TST_P1_LLAVE_COGIDA` | Coger la llave | «Pone "ARCHIVO". Al menos algo aquí tiene nombre.» |
| `TST_P1_LLAVE_DENTRO` | Llave metida | «Entra. Ahora, girarla.» |
| `TST_P2_ENTRADA` | Primera vez que se entra en modo examen | «Tres lámparas. Una ilumina algo en el cristal.» |
| `TST_P2_SELLO` | Primera vez que se ve el sello | «Un sello de Dirección, escrito al revés en el cristal. Alguien tenía tiempo.» |
| `TST_P2_ENFOQUE_LAMPARA` | Enfocar una lámpara sin resolver | «La cabeza gira. Cuatro marcas en el suelo.» |
| `TST_P2_PRIMER_FRAGMENTO` | Primer fragmento revelado | «Está al revés. Pero es para mí.» |
| `TST_P2_DOS_FRAGMENTOS` | Dos fragmentos a la vez | «Falta un trozo.» |
| `TST_P2_ENFOQUE_CRISTAL_A` | Enfocar el cristal sin resolver | «A la luz normal no hay nada. Solo lluvia.» |
| `TST_P2_ENFOQUE_CRISTAL_B` | Enfocar el cristal resuelto | «El memorando. Entero.» |
| `TST_P2_NOTA` | Leer `NOTA_02` | «"Yo tampoco". Qué generoso.» |
| `TST_P3_ENFOQUE_FRENTE_A` | Enfocar el frente, sin resolver | «La foto del equipo. Y tres tambores: fila de abajo.» |
| `TST_P3_ENFOQUE_FRENTE_B` | Enfocar el frente, resuelto, nota sin coger | «Algo brilla dentro del cajón.» |
| `TST_P3_ENFOQUE_FRENTE_C` | Enfocar el frente, todo cogido | «Aquí ya no queda nada.» |
| `TST_P3_FOTO` | Primera vez que se enfoca el frente | «El equipo. Conozco las caras. A la derecha, abajo, no hay nadie.» |
| `TST_P3_LIMADA` | Primera vez que un tambor muestra la cara limada | «Esta cara está limada. Aquí había un símbolo.» |
| `TST_P3_ENFOQUE_IZQ_A` | Enfocar la izquierda, tapa sin levantar | «Una tapa de latón con un asa.» |
| `TST_P3_TAPA_VISTA` | Primera vez que se lee la placa | «"Fila de abajo". Taza, paraguas… y el tercero, rayado.» |
| `TST_P3_ENFOQUE_IZQ_B` | Enfocar la izquierda, tapa ya vista | «Taza, paraguas y un rayajo.» |
| `TST_P3_RESUELTO` | Tambores resueltos | «Taza, paraguas y nadie. Se abre con nadie.» |
| `TST_P3_ENGRANAJE` | El engranaje pasa al inventario | «Una pieza dentada. Encajará en alguna parte. Él siempre lo hacía así.» |
| `TST_P4_ENFOQUE_A` | Enfocar la trasera, sin engranaje colocado | «Engranajes, un tablero de tareas… y un eje vacío a la izquierda.» |
| `TST_P4_ENFOQUE_B` | Enfocar la trasera, engranaje colocado, sin terminar | «Gira la manivela. Varias vueltas.» |
| `TST_P4_ENFOQUE_C` | Enfocar la trasera, resuelto | «El mecanismo ha cedido.» |
| `TST_P4_TABLERO` | Primera vez que se enfoca la trasera | «Sus tareas. La última tiene mi nombre tachado y una G encima.» |
| `TST_P4_EJE_SIN_PIEZA` | Tocar el eje sin engranaje | «Un eje vacío. Aquí falta una pieza.» |
| `TST_P4_EJE_SIN_SELECCION` | Tocar el eje con el engranaje sin seleccionar | «El engranaje está en el bolsillo. Tengo que sacarlo.» |
| `TST_P4_EN_VACIO` | 180° sin engranaje | «Los engranajes giran en vacío. Falta una pieza en el eje de la izquierda.» |
| `TST_P4_ENCAJA` | Engranaje colocado | «Encaja. Ahora, la manivela.» |
| `TST_P4_GEMA_1` | Se enciende la gema 1 | «Cliente Lima. Eso ya era mío.» |
| `TST_P4_GEMA_2` | Se enciende la gema 2 | «El contrato. Eso es suyo.» |
| `TST_P4_GEMA_3` | Se enciende la gema 3 | «La mudanza. Eso es de Dirección.» |
| `TST_P4_TOPE` | Tope | «La última no gira sola. A un lado pone "La asumo". Al otro, "La devuelvo".» |
| `TST_P4_ASUMIDA` | `assigned` | «La asumo. Alguien tiene que hacerlo.» |
| `TST_P4_DEVUELTA` | `returned` | «No me corresponde. Que la firme la G.» |
| `TST_P4_PASADOR` | Tras resolver | «Algo se ha soltado en el lateral derecho.» |
| `TST_P5_ENFOQUE_A` | Enfocar la derecha, con pasador | «Un medallón con un cristal. Refleja algo de la pared.» |
| `TST_P5_BLOQUEADO` | Intentar girar con pasador | «Tiene un pasador. No gira. Todavía.» |
| `TST_P5_ENFOQUE_B` | Enfocar la derecha, libre | «Ahora gira. El cristal tiene dos fotos: una dentro y otra reflejada.» |
| `TST_P5_CERCA` | Primera vez que |θ − 40| ≤ 10° | «Casi encajan.» |
| `TST_P5_DESPUES` | Tras `VO_G_07` | «Las tres luces de arriba están verdes.» |
| `TST_P5_ENFOQUE_C` | Enfocar la derecha, resuelto | «Estaba. Yo estaba.» |
| `TST_P6_ENFOQUE_A` | Enfocar arriba, pestillo bloqueado | «Un pestillo y tres luces.» |
| `TST_P6_BLOQ_1` | Pestillo bloqueado, luz 1 roja | «No cede. La primera luz está roja. Empecemos por delante.» |
| `TST_P6_BLOQ_2` | Pestillo bloqueado, luz 2 roja | «No cede. La segunda luz sigue roja. Algo en la parte de atrás.» |
| `TST_P6_BLOQ_3` | Pestillo bloqueado, luz 3 roja | «No cede. Falta la tercera. El lateral derecho.» |
| `TST_P6_ENFOQUE_B` | Enfocar arriba, desbloqueado y cerrado | «Tres luces verdes. Ahora sí.» |
| `TST_P6_CARTA` | La bandeja termina de subir | «Es mi letra. Una carta para él. Le falta la primera frase.» |
| `TST_P6_SELECCION` | Primera selección de una tira | «¿Esta? Luego no podré cambiarla.» |
| `TST_P6_DESPUES` | Tras leer la carta | «Es mi letra. Esta noche eso ya no me sorprende.» |

## 5. Pistas del menú de pausa [NUEVO, P2/P5/P6 adaptadas del CANON]

| ID | Texto |
|---|---|
| `PST_P1_1A` | «La tapa del lateral se levanta.» |
| `PST_P1_1B` | «Las horas de la tapa están en la impresión de los correos.» |
| `PST_P1_2` | «Cada hora es un correo, y cada correo tiene un número.» |
| `PST_P1_3` | «El primer tambor es el correo de las 09:14.» |
| `PST_P2_1` | «El memorando está escrito en espejo. Un haz lo muestra mejor que la luz directa.» (con F1 en espejo durante 2 s) |
| `PST_P2_2` | «Cada lámpara tiene cuatro posiciones. Solo una ilumina texto.» |
| `PST_P2_3` | (sin texto) Halo en el cristal sobre el punto actual del haz de la lámpara más cercana |
| `PST_P3_1A` | «La tapa del lateral izquierdo se levanta.» |
| `PST_P3_1B` | «El pie de foto describe la fila de abajo de la foto.» |
| `PST_P3_2` | «Mira quién hay en la foto en el sitio del símbolo rayado.» |
| `PST_P3_3` | «En ese sitio no hay nadie. Una de las caras de los tambores tampoco tiene símbolo.» |
| `PST_P4_1A` | «En la trasera falta una pieza. Está en otra cara de la caja.» |
| `PST_P4_1B` | «La manivela necesita dos vueltas.» |
| `PST_P4_2` | «Al final, la manivela se detiene. Gira hacia el lado de lo que decidas.» |
| `PST_P4_3` | «Los dos sentidos abren la caja. Ninguno es un error.» |
| `PST_P5_1` | «El reflejo muestra algo que la foto de la caja no muestra.» |
| `PST_P5_2` | «Compara las dos fotos con atención.» |
| `PST_P5_3` | (sin texto) La marca de 40° del aro del medallón se ilumina |
| `PST_P6_1` | «Solo puedes elegir una vez.» (sale sola a los 10 s) |
| `PST_P6_2` | «La carta no cambia; cambia la primera frase.» (sale sola a los 20 s) |

## 6. Recuento

| Tipo | Cantidad |
|---|---|
| Voces (§1) | 21 |
| Documentos y mensajes (§2) | 18 |
| Grabados (§3) | 13 |
| Avisos `TST_` (§4) | 61 |
| Pistas `PST_` (§5) | 20 |
