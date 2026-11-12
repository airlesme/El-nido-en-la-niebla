# 06 · Trazabilidad

Para comprobar que todo está hilado: cada pista tiene un origen, cada puzle abre algo, cada elección tiene un eco, y cada objeto con historia se usa.

## 1. Puzle → historia

| Puzle | Pregunta | Pistas que necesita (y dónde están) | Qué revela | Qué abre | Banderas | Eco posterior |
|---|---|---|---|---|---|---|
| **P1 · Cajetín** | ¿Cuándo se decidió? | Placa de horas (cajetín, tapa izquierda) + impresión I-01 (impresora del despacho de Vera, tras buscar «transición») | Orden real: pregunta → pide confirmación → registra → Dirección lo da por hecho. Y el formulario, dentro, firmado antes | Puerta A → formulario I-04, tarjetas I-02 e I-03 | `archivo_abierto`, `formulario_leido`, `tarjeta_B`, `tarjeta_D` | La fecha del formulario cuadra con la segunda entrada del libro de visitas (escena 8) |
| **P2 · Lámparas** | ¿Qué dice Dirección? | Ninguna externa. Las marcas del suelo y el sello visible al entrar enseñan el gesto | «Aprobado a petición de la interesada. Ratificación pendiente de firma del responsable» | Nada (lectura) | `memo_leido`, `pos_L/C/R` | Da sentido a T4 («en nombre de la interesada») y a «La carta a Dirección ya va firmada» (`VO_G_14_ASG`) |
| **P3 · ¿Quién falta?** | ¿Quién falta en la foto? | Pie de foto (caja, tapa izquierda) + foto de la caja (frente) | Vera no está. Su símbolo fue limado | Cajón: `NOTA_01` + engranaje I-09 | `caja_c1` | El hueco se llena en P5. La nota «La transición es tuya» enlaza con `VO_V_01` («Solo sé que me toca a mí») |
| **P4 · ¿Qué carga?** | ¿Qué acepta y qué devuelve? | Engranaje (P3) + tablero grabado (trasera) + `NOTA_02` (Sala B, opcional) | La lista del Guardián, con el nombre de Vera tachado | Pasador del medallón; lista I-05 | `t4_decision`, `caja_c2` | `VO_G_14_RET` / `VO_G_14_ASG` en la llamada si Vera se calla |
| **P5 · ¿Qué cambia?** | ¿Qué cambia entre fotos? | Foto de la pared D04 (reflejada) + foto pequeña bajo el cristal (= foto de la caja de P3) | Vera estaba en el equipo. Grabación `VO_G_07` | Luz 3 → pestillo | `pendiente_revelacion`, `caja_c3` | «Venga, que somos un equipo» vuelve en `CARTA_CUERPO` («No quiero que me digas que somos un equipo») |
| **P6 · ¿Qué responde?** | ¿Qué responde a su carta? | Ninguna: es una elección | La carta con letra de Vera | Fin de la caja → apagón al salir | `carta_variante`, `caja_c4`, `caja_completa` | Primera frase de la llamada (`VO_G_12A/B/C`) |

## 2. Hilos que cruzan el slice

Cada hilo aparece al menos tres veces. Si se corta uno, se nota.

| Hilo | Apariciones |
|---|---|
| **La firma** | Formulario (escena 3) → `VO_V_04` «la firma es mía, o se parece» → memorando «pendiente de firma del responsable» → T4 con nombre tachado y «G» → `CARTA_CUERPO` «por qué firmé» → `VO_G_12B` «no sabes qué firmaste» → `VO_G_14_ASG` «ya va firmada» → la V del libro de visitas |
| **El equipo** | Foto de la pared → foto de la caja sin Vera → símbolos de la caja y cara limada → `VO_G_07` «somos un equipo» (toma descartada) → `CARTA_CUERPO` «no quiero que me digas que somos un equipo» |
| **La transición** | `VO_V_01` «el archivo de transición… me toca a mí» → búsqueda «transición» → cajetín «de transición» → `NOTA_01` «La transición es tuya» |
| **La carga** | `NOTA_02` «No te quites la carga. Yo tampoco» → manivela del tablero de tareas → T4 asumida o devuelta → eco en la llamada |
| **Jugar** [PROPUESTA] | `SMS_01` «¿Jugamos esta noche?» → «Ahora no» → cajetín hecho a mano → «¿Jugamos?» en la base de la caja → `TST_P3_ENGRANAJE` «Él siempre lo hacía así» |
| **Nueve días** | Libro de visitas (22:12) → formulario fechado → `VO_V_04` avión a Lisboa |
| **Resfriada** | Las tres variantes de `VO_G_12` terminan en «¿Estás resfriada?»: la voz oye que Vera ha llorado, o lo supone. Nunca se explica |
| **La extensión** | Cambio de extensiones (correo de ruido, cara del auricular en el cajetín) → la llamada sale desde la extensión de Vera |
| **Reflejos** | Reflejo de Vera que llega tarde (escena 4) → memorando en espejo (P2) → medallón de espejo (P5) |

## 3. Eco de las elecciones (todas las combinaciones)

`t4_decision` (2) × `carta_variante` (3) × `respuesta_llamada` (4) = 24 recorridos. Todos deben poder jugarse.

| Elección | Valores | Se oye en |
|---|---|---|
| T4 | `assigned` / `returned` | Llamada, solo si el jugador no responde en 20 s: `VO_G_14_ASG` / `VO_G_14_RET` |
| Carta | `A` / `B` / `C` | Llamada, primera frase: `VO_G_12A` / `B` / `C` |
| Llamada | `A` / `B` / `C` / `D` | Respuesta del Guardián `VO_G_13A–D` y frase final de Vera `VO_V_12A–D` |

**Combinaciones a probar en QA como mínimo:** las tres cartas con respuesta A; T4 en sus dos valores con 20 s de silencio; las cuatro respuestas con la carta B.

## 4. Inventario y bolsillo

| Ítem | Origen | Uso | ¿Se relee? |
|---|---|---|---|
| I-01 Impresión de correos | Impresora del despacho | Pista de P1 | En el ordenador o el papel |
| I-08 Llave del Archivo [PROPUESTA] | Cajón del cajetín (P1) | Cerradura de la puerta A | No |
| I-02 Tarjeta de la Sala B | Cajón A05 del Archivo | Lector de B | No |
| I-03 Tarjeta sin foto | Cajón A05 del Archivo | Lector de D | No |
| I-04 Formulario de traslado | Caja A03 del Archivo | Lectura | Sí |
| I-06a `NOTA_01` | Cajón de la caja (P3) | Lectura | Sí |
| I-09 Engranaje [PROPUESTA] | Cajón de la caja (P3) | Eje de la trasera (P4) | No |
| I-05 Lista de tareas | Detrás del tablero (P4) | Lectura | Sí |
| I-07 Carta de Vera | Bandeja de la caja (P6) | Lectura | Sí |

**Inventario de un hueco (M3):** solo I-08 e I-09 lo ocupan, y nunca a la vez (I-08 se gasta en la puerta A antes de que exista I-09). Las tarjetas se usan solas al acercarse al lector (sin selección), como en el slice.

## 5. Lista de comprobación de coherencia

Antes de dar por terminado cualquier objeto, texto o asset:

- [ ] Las horas de la placa del cajetín son exactamente las de los correos ref. 2, 1, 3 y 4.
- [ ] La impresión I-01 está desordenada y cada bloque lleva su hora.
- [ ] La foto de la caja y la de la pared son **la misma foto** salvo por Vera: mismas posiciones, mismas caras, misma luz.
- [ ] En la foto de la caja no hay rastro de recorte en el sitio de Vera.
- [ ] Vera sostiene el peluche cúbico en la foto de la pared, y es el mismo peluche que hay en su despacho.
- [ ] La cara limada de los tambores deja intuir un cuadrado, no otra forma.
- [ ] La placa de la tapa izquierda de la caja tiene exactamente taza y paraguas, y el tercero rayado.
- [ ] La fila 4 del tablero tiene «Vera» tachado y «G» encima, igual que la ficha T4 del slice.
- [ ] La foto de la pared está en la pared hacia la que mira la cara derecha de la caja.
- [ ] Las tiras de P6 y la carta tienen la misma letra que la firma del formulario y que el libro de visitas.
- [ ] Ningún asset ni sonido confirma que el Guardián está en el edificio.
- [ ] Ningún texto `TST_` confirma una intención («lo hizo para…», «quería…»).
- [ ] Las gemas y la plaquita de T4 no usan un color que premie una opción.
- [ ] Cada aviso que aparece en pantalla está en `05` con su ID.
- [ ] La luz cálida (ámbar) solo está en la Sala B y, tenue, en la bandeja de la carta.

## 6. Recuento de marcas

| Marca | Dónde |
|---|---|
| **[EXTENSIÓN 1]** | Cabeza de lámpara: tambor de 4 posiciones y giro horizontal (`04` §3.2) |
| **[EXTENSIÓN 2]** | Tope de la manivela y elección por sentido de giro (`04` §4.4) |
| **[EXTENSIÓN 3]** | Medallón con pasador y detección de alineación (`04` §4.5) |
| **[EXTENSIÓN 4]** | Elegir entre tres objetos con selección y confirmación (`04` §4.6) |
| Decisiones nuevas | D-B1 a D-B10 (`04` §7) |
