# 04 · Puzles

Tres objetos-puzle construidos con el kit del piloto (`03`). Los seis puzles del slice siguen respondiendo a las mismas seis preguntas; lo que cambia es cómo se juegan.

| Objeto | Dónde | Puzles | Mecánicas del kit | Minutos |
|---|---|---|---|---|
| **Cajetín de transición** | Pasillo, junto a la puerta A (C05) | 1 · Cronología | M0, M1, M2, M3, M4 (corto) | 2–4 |
| **Lámparas del memorando** | Sala de Reuniones (B01–B04) | 2 · Memorando | M0, M2 en variante, M6 (lectura) | 2–4 |
| **La caja del Guardián** | Despacho D, sobre la mesa (D01) | 3, 4, 5 y 6 | M0 a M8: **es el piloto con otra piel** | 8–12 |

---

## 1. Reglas comunes

1. **Modo examen.** Interactuar con el objeto en primera persona entra en modo examen (M0). Sale con «Volver». Mientras se está en modo examen, Vera no se mueve.
2. **Estados.** Cada puzle está `BLOQUEADO`, `ACTIVO` o `RESUELTO`. Al resolverse emite `EV_PUZZLE_SOLVED_P1` … `EV_PUZZLE_SOLVED_P6`.
3. **No hay fallo.** Ninguna combinación equivocada tiene consecuencia: no abre, y ya está. No hay contador de intentos, no hay temporizador, no hay reinicio.
4. **Todo responde.** Cada gesto tiene sonido (`SFX_KIT_*`) y movimiento.
5. **Lo bloqueado explica por qué.** Todo intento bloqueado da un aviso que señala dónde mirar (M5, M8).
6. **Se queda como se deja.** Si el jugador sale del modo examen o de la sala, todo queda en la posición en que lo dejó (tambores, tapas, medallón, inventario).
7. **Guardado** automático al resolver cada puzle y al abrir cada puerta.
8. **Avisos.** Son pensamientos de Vera (texto). Los que se repiten (al enfocar una cara) cambian con el estado. Los de «primera vez» salen una sola vez por partida.
9. **Pistas del menú de pausa.** Tres niveles por puzle (dos en el 6). Cada nivel se pide; nunca salta solo, salvo donde se indica.

## 2. Puzle 1 · Cajetín de transición

**Pregunta que responde:** ¿cuándo se decidió el traslado, y sin qué confirmación?
**Idea:** el Guardián convirtió la secuencia de sus correos en la combinación del Archivo. Para entrar, Vera tiene que ordenar lo que pasó.

### 2.1 El objeto

Caja de latón y madera oscura de unos 40 × 30 × 15 cm, atornillada a la pared a la izquierda de la puerta A, a la altura del pecho. Hecha a mano, como la caja del Guardián (mismos materiales, mismo herraje). La cerradura de la puerta A queda a su derecha y forma parte del objeto en modo examen.

| Cara | Qué tiene |
|---|---|
| **Frente** | Cuatro tambores en fila (M2) y, debajo, un cajón estrecho sin tirador |
| **Izquierda** | Tapa de latón con asa (M1). Debajo, una placa grabada |
| **Derecha** | La cerradura de la puerta A, con un ojo de llave y un anillo de latón alrededor |

Navegación: ◀ ▶ recorren izquierda → frente → derecha. No hay ▲.

### 2.2 Los tambores

Cuatro tambores de seis caras. Las seis caras, iguales en los cuatro y en este orden: **1 · 2 · 3 · 4 · auricular · aspas**.

- El **auricular** es el correo del cambio de extensiones. Las **aspas** son el del aire acondicionado. Son el ruido de la impresión convertido en cara: si el jugador intenta meter los seis correos, ve que no caben.
- Posición inicial: `3 · 4 · auricular · 1` (ningún tambor en su posición correcta).
- **Solución:** `2 · 1 · 3 · 4`.

### 2.3 La pista (tapa izquierda)

Bajo la tapa, una placa con cuatro horas grabadas en letra del Guardián, de izquierda a derecha:

> L 09:14 · L 11:40 · L 16:02 · M 08:55
> *(debajo, más pequeño)* Lo demás es ruido.

La placa no dice qué es cada hora. La impresión de los correos (I-01) sí: cada correo tiene su número de referencia y su hora de envío. El jugador cruza las dos fuentes: 09:14 → ref. 2; 11:40 → ref. 1; 16:02 → ref. 3; 08:55 → ref. 4.

### 2.4 La llave y la cerradura

1. Al resolverse los tambores: `SFX_KIT_CHIME`, `SFX_KIT_CLUNK`, `SFX_KIT_SLIDE`, y el cajón sale (1,4 s). Dentro, una **llave pequeña de latón** con una etiqueta de cartón: «ARCHIVO» (ítem I-08 **[NUEVO]**), que gira y brilla (M3).
2. Tocarla: vuela a la cámara y pasa al inventario, seleccionada.
3. En la cara derecha, el anillo de la cerradura late mientras la llave está seleccionada.
4. Tocar la cerradura: la llave entra (0,8 s, `SFX_KIT_CLUNK`).
5. **Girar la llave**: arrastre circular sobre ella (M4 con otro objetivo: un cuarto de vuelta, 90°, en sentido horario; `SFX_KIT_TICK` cada 30°; sin gemas). Al llegar: `SFX_UNLOCK` (1,4 s) y `ANIM_DOOR_OPEN`.
6. A los 1,0 s, el modo examen se cierra solo y la cámara vuelve a Vera, mirando a la puerta abierta.

### 2.5 Estado y banderas

| Momento | Efecto |
|---|---|
| Inicio de partida | P1 `ACTIVO`. Los tambores giran desde el principio |
| Tambores resueltos | Tambores bloqueados. Cajón abierto |
| Llave girada | `archivo_abierto` = verdadero. `EV_PUZZLE_SOLVED_P1`. Guardado. P1 `RESUELTO` |

No se exige `correos_leidos` para girar los tambores: sin la impresión, la combinación no se puede deducir y los avisos llevan al ordenador.

### 2.6 Avisos

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

### 2.7 Pistas del menú

1. Si la tapa no se ha levantado: «La tapa del lateral se levanta.» Si ya se ha visto: «Las horas de la tapa están en la impresión de los correos.» (`PST_P1_1A` / `PST_P1_1B`)
2. «Cada hora es un correo, y cada correo tiene un número.» (`PST_P1_2`)
3. «El primer tambor es el correo de las 09:14.» (`PST_P1_3`)

## 3. Puzle 2 · Lámparas del memorando

**Pregunta que responde:** ¿qué dice oficialmente Dirección?
**Idea:** el memorando está escrito en espejo sobre el cristal y solo se ve bajo un haz. Hay que apuntar tres lámparas a tres fragmentos.

### 3.1 El objeto

La mesa de cristal de la Sala B con tres lámparas de escritorio de brazo articulado: izquierda (B01), central (B02) y derecha (B03). Detrás de la mesa, el ventanal (B04) con la película donde está escrito el memorando. Junto a cada lámpara, en el suelo, cuatro marcas numeradas del 1 al 4 (B08).

| «Cara» en modo examen | Qué tiene |
|---|---|
| **Lámpara izquierda** | Cabeza giratoria con 4 posiciones |
| **Lámpara central** | Ídem |
| **Lámpara derecha** | Ídem |
| **Cristal** (▲) | Vista frontal del ventanal, donde aparecen los fragmentos |

Navegación: ◀ ▶ entre las tres lámparas; ▲ al cristal.

### 3.2 La cabeza de la lámpara **[EXTENSIÓN 1]**

Es un tambor (M2) con **4 posiciones en lugar de 6** y **giro horizontal** en lugar de vertical: arrastre horizontal, 30 px por posición, `SFX_KIT_TICK` en cada paso, imán al soltar. Las cuatro posiciones reparten un arco de 60° (20° entre posiciones) y apuntan a cuatro puntos distintos del cristal. El haz se ve en el cristal en todo momento.

Posición inicial de las tres: **2** (`pos_L` = `pos_C` = `pos_R` = 2).

### 3.3 Lo que hay en cada punto

| Lámpara | Pos. 1 | Pos. 2 | Pos. 3 | Pos. 4 |
|---|---|---|---|---|
| Izquierda | Vacío | Sello de Dirección (distractor) | **F1** | Vacío |
| Central | **F2** | Vacío | Vacío | Vacío |
| Derecha | Vacío | Vacío | Vacío | **F3** |

- **F1:** «Traslado de Vera: aprobado a petición de la interesada.»
- **F2:** «Ratificación pendiente»
- **F3:** «de firma del responsable.»

Como la lámpara izquierda empieza en 2, **el sello de Dirección se ve nada más entrar**: enseña sin palabras que el haz revela tinta en el cristal.

Cuando un haz cae sobre un fragmento, el fragmento aparece en 0,8 s (se lee en espejo, invertido) y la lámpara zumba más fuerte. Si el haz se va, el fragmento se apaga en 0,8 s.

**Solución:** izquierda 3, central 1, derecha 4.

### 3.4 Resolución

1. Con los tres fragmentos visibles a la vez: `SFX_GLASS_HUM` (2,0 s) y `SFX_KIT_CHIME`.
2. La cámara pasa sola al cristal (▲). El memorando entero aparece **al derecho** en el reflejo, como si el cristal lo diera la vuelta.
3. Tocar el cristal abre la lectura de `DOC_01` (pulsación prolongada, como cualquier documento).
4. Al cerrar la lectura suena `VO_V_08`.
5. `memo_leido` = verdadero. `EV_PUZZLE_SOLVED_P2`. P2 `RESUELTO`. Guardado.

Las lámparas se quedan en la solución. Si el jugador sale antes de resolver, cada lámpara queda donde estaba.

### 3.5 La nota del aparador

En el aparador (B05), fuera del modo examen, una nota manuscrita del Guardián, `NOTA_02`: «No te quites la carga. Yo tampoco». Se lee in situ; no es ítem. Aviso al leerla: `TST_P2_NOTA`.

### 3.6 Avisos

| ID | Cuándo | Texto |
|---|---|---|
| `TST_P2_ENTRADA` | Primera vez que se entra en modo examen | «Tres lámparas. Una ilumina algo en el cristal.» |
| `TST_P2_SELLO` | Primera vez que se ve el sello | «Un sello de Dirección, escrito al revés en el cristal. Alguien tenía tiempo.» |
| `TST_P2_ENFOQUE_LAMPARA` | Enfocar una lámpara sin resolver | «La cabeza gira. Cuatro marcas en el suelo.» |
| `TST_P2_PRIMER_FRAGMENTO` | Primer fragmento revelado | «Está al revés. Pero es para mí.» |
| `TST_P2_DOS_FRAGMENTOS` | Dos fragmentos a la vez | «Falta un trozo.» |
| `TST_P2_ENFOQUE_CRISTAL_A` | Enfocar el cristal sin resolver | «A la luz normal no hay nada. Solo lluvia.» |
| `TST_P2_ENFOQUE_CRISTAL_B` | Enfocar el cristal resuelto | «El memorando. Entero.» |
| `TST_P2_NOTA` | Leer `NOTA_02` | «"Yo tampoco". Qué generoso.» |

### 3.7 Pistas del menú [CANON, adaptadas]

1. Se muestra 2 s el texto de F1 en espejo: «El memorando está escrito en espejo. Un haz lo muestra mejor que la luz directa.» (`PST_P2_1`)
2. «Cada lámpara tiene cuatro posiciones. Solo una ilumina texto.» (`PST_P2_2`)
3. Al acercar la cámara a una lámpara, su haz se marca con un halo en el cristal. Muestra el punto actual, no el correcto. (`PST_P2_3`)

## 4. La caja del Guardián (puzles 3 a 6)

**La pieza central del slice.** Es el piloto con otra piel: mismas cinco caras, misma cadena, misma física. Si solo hay tiempo para construir una cosa bien, es esta.

### 4.1 El objeto

Caja de madera oscura (nogal) con cantoneras y aros de latón gastado, de unos 35 × 35 × 25 cm, sobre la mesa del despacho del Guardián. En la base, en latón, una inscripción pequeña: «¿Jugamos?» **[NUEVO]**. La foto de la pared (D04) cuelga en la pared que **mira hacia la cara derecha** de la caja: es la que refleja el medallón (§4.5). Requisito de nivel.

| Cara | Puzle | Contenido | Piloto equivalente |
|---|---|---|---|
| **Frente** | 3 | Foto del equipo incrustada bajo cristal (mitad superior), tres tambores (mitad inferior), cajón | Tambores + cajón |
| **Izquierda** | 3 (pista) | Tapa con asa; debajo, el pie de foto grabado | Tapa con la pista |
| **Trasera** | 4 | Tablero de tareas grabado en latón, cuatro gemas, eje vacío, engranajes, manivela | Mecanismo con eje y manivela |
| **Derecha** | 5 | Medallón de espejo con pasador | Medallón (sin función en el piloto) |
| **Superior** | 6 | Pestillo en carril con tres luces; dos tapas; dentro, la carta | Pestillo, tapas y cristal |

**La cadena:**

```
Tapa izq. (pie de foto) ─► Tambores (P3) ─► Cajón: NOTA_01 + engranaje ─► Eje + manivela (P4: elección T4) ─► Pasador del medallón se suelta
     ─► Medallón espejo a 40° (P5: VO_G_07) ─► Tres luces verdes ─► Pestillo ─► Tapas ─► Carta + tres tiras (P6: elección) ─► caja_completa
```

**[NUEVO] Orden lineal.** El slice dejaba el compartimento 2 libre (D-16). Aquí la cadena es lineal (c1 → c2 → c3 → c4) porque el engranaje del cajón es lo que hace funcionar la trasera. Ver la decisión D-B1 en §7.

### 4.2 Las tres luces del pestillo

Sobre el carril del pestillo (cara superior) hay **tres luces** pequeñas en lugar de la gema única del piloto. Se ven desde la vista general de la caja: sirven de indicador de progreso de toda la caja.

| Luz | Se enciende cuando | Sonido |
|---|---|---|
| 1 | `caja_c1` | Clic suave desde arriba |
| 2 | `caja_c2` | Ídem |
| 3 | `caja_c3` | Ídem |

Apagada = roja y hueca. Encendida = verde y llena (doble código para daltonismo). Desde fuera, el jugador ve cuánto le falta sin ningún HUD.

### 4.3 Puzle 3 · ¿Quién falta? (frente + izquierda)

**Idea:** la foto de la caja tiene un hueco en la fila de abajo. El pie de foto tiene ese símbolo rayado. Y en los tambores, la cara que correspondería está limada. La combinación correcta es el vacío.

**La foto de la caja** (mitad superior del frente, bajo cristal): cinco personas en dos filas. Fila de arriba: gafas · llave (el Guardián) · pluma. Fila de abajo: taza · paraguas · **pared vacía**. Nada sugiere un recorte: en ese sitio simplemente no hay nadie.

**Los tambores** (mitad inferior, rotulada en latón «FILA DE ABAJO»): tres tambores de seis caras. Las seis caras, iguales en los tres y en este orden: **llave · gafas · pluma · taza · paraguas · cara limada**.

- La **cara limada** es latón con marcas de lima. Bajo la luz rasante se intuye que hubo un cuadrado grabado. Es el cubo de Vera, borrado (`01` §4). Nadie lo dice.
- Posición inicial: `pluma · llave · gafas`.
- **Solución:** `taza · paraguas · cara limada`.

**La pista** (tapa izquierda, M1): bajo la tapa, una placa con el pie de foto en letra del Guardián:

> Fila de abajo:
> [taza] [paraguas] [▒▒]

El tercer símbolo está rayado con algo punzante. En una esquina del rayado asoma un ángulo recto, como de un cuadrado.

**Por qué no es un simple copiar:** el jugador copia dos símbolos y tiene que deducir el tercero. Mira la foto: en ese sitio no hay nadie. Busca un símbolo «de nadie» y lo único que encaja es la cara limada. Si prueba los otros cinco, no abre. **La ausencia es la respuesta**, como en el slice.

**Resolución:**
1. `SFX_KIT_CHIME`; a los 0,5 s `SFX_KIT_CLUNK`; a los 0,25 s `SFX_KIT_SLIDE`; el cajón sale en 1,4 s.
2. `caja_c1` = verdadero. Luz 1 verde. `EV_PUZZLE_SOLVED_P3`. Guardado.
3. Dentro del cajón: un papel enrollado y atado alrededor del cubo de un engranaje de latón. Gira y brilla (M3).
4. Tocarlo: se abre la lectura de `NOTA_01` («La transición es tuya»), documento I-06a.
5. Al cerrar la lectura, el engranaje (ítem I-09 **[NUEVO]**) vuela a la cámara y pasa al inventario, seleccionado. La nota queda en el bolsillo de documentos.

| ID | Cuándo | Texto |
|---|---|---|
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

**Pistas del menú:**
1. «La tapa del lateral izquierdo se levanta.» Si ya se ha visto: «El pie de foto describe la fila de abajo de la foto.» (`PST_P3_1A` / `PST_P3_1B`)
2. «Mira quién hay en la foto en el sitio del símbolo rayado.» (`PST_P3_2`)
3. «En ese sitio no hay nadie. Una de las caras de los tambores tampoco tiene símbolo.» (`PST_P3_3`)

### 4.4 Puzle 4 · ¿Qué carga acepta? (trasera)

**Idea:** el tablero de tareas del Guardián está grabado en el mecanismo. Hacerlo funcionar es cargar con sus tareas. Al final, la manivela se detiene en la última, la carta a Dirección, y obliga a elegir hacia qué lado seguir.

**El tablero** (placa de latón que ocupa la trasera, con el mecanismo encima). Cuatro filas, cada una con una gema a la izquierda:

| Gema | Grabado |
|---|---|
| 1 | Cliente Lima · revisión antes del jueves · **Vera** |
| 2 | Revisión de contrato · tres semanas parada · **Guardián** |
| 3 | Mudanza del archivo · sin fecha · **Dirección** |
| 4 | Carta a Dirección · explicar la solicitud de traslado en nombre de la interesada · ~~Vera~~ **G** |

La fila 4 es una **plaquita suelta** atornillada en su hueco, no grabada en la placa: se nota que se puede mover. Junto al cubo de la manivela hay dos flechas grabadas: ↻ «La asumo» (horario) y ↺ «La devuelvo» (antihorario).

**El mecanismo** (igual que el piloto): tres engranajes montados (15, 11 y 9 dientes) y un eje vacío a la izquierda donde va el de 11 dientes del cajón. La manivela está sobre el engranaje central.

**Fase 1 · Encajar.** Como M3: sin engranaje, tocar el eje da aviso; con él seleccionado, el anillo del eje late; tocar el eje lo encaja (0,8 s, `SFX_KIT_CLUNK`).

**Fase 2 · Girar.** Como M4: arrastre circular, en cualquier sentido, `SFX_KIT_TICK` cada 30°. Sin engranaje, giran en vacío y a los 180° sale el aviso. Con él, el progreso cuenta el giro acumulado en valor absoluto. Las gemas 1, 2 y 3 se encienden al completar media vuelta, una vuelta y vuelta y media (3π de un total de 4π). Al encenderse cada gema, su fila de texto se ilumina un instante.

**Fase 3 · El tope [EXTENSIÓN 2].** Al llegar a vuelta y media, la manivela **topa**: `SFX_KIT_CLUNK` suave, la gema 4 parpadea, y desde ese momento el giro deja de contar en valor absoluto. Se mide el giro con signo desde el tope:

- **+π (media vuelta en sentido horario) → asumida.** La plaquita de la fila 4 se hunde en la placa con un golpe seco, como un sello. `t4_decision` = `assigned`.
- **−π (media vuelta en sentido antihorario) → devuelta.** La plaquita sale del panel 1 cm, como una ficha que se rechaza, y se queda así. `t4_decision` = `returned`.

Hasta llegar a ±π el jugador puede ir y volver; no hay nada fijado. En los dos casos la gema 4 se enciende **del mismo color que las otras**: ninguna opción se marca como mejor.

**Resolución:**
1. `t4_decision` se escribe **antes** que `caja_c2` (regla del slice).
2. `SFX_KIT_CLUNK`; a los 0,25 s `SFX_KIT_CHIME`. La manivela queda inmóvil.
3. La placa del tablero se separa un dedo por abajo: detrás asoma un papel doblado, la lista de tareas del Guardián (I-05), con el nombre de Vera tachado en la última entrada. Tocar = lectura.
4. `caja_c2` = verdadero. Luz 2 verde. `EV_PUZZLE_SOLVED_P4`. Guardado.
5. Desde el lateral derecho suena un clic metálico (el pasador del medallón se retira) y aparece el aviso `TST_P4_PASADOR`.

| ID | Cuándo | Texto |
|---|---|---|
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

**Pistas del menú:**
1. Sin engranaje colocado: «En la trasera falta una pieza. Está en otra cara de la caja.» Con él: «La manivela necesita dos vueltas.» (`PST_P4_1A` / `PST_P4_1B`)
2. «Al final, la manivela se detiene. Gira hacia el lado de lo que decidas.» (`PST_P4_2`)
3. «Los dos sentidos abren la caja. Ninguno es un error.» (`PST_P4_3`)

### 4.5 Puzle 5 · ¿Qué cambia? (derecha)

**Idea:** el medallón es un espejo semiazogado. Detrás del cristal hay una copia pequeña de la foto de la caja. Por delante refleja la foto de la pared. Cuando las dos encajan, la única figura que no tiene pareja es Vera.

**El medallón:** disco de latón de unos 16 cm con una ventana circular de cristal semiazogado. Detrás del cristal, una copia pequeña de la foto de la caja (la de P3, sin Vera). Aro exterior con **marcas cada 5°**, sin números; una flecha fija arriba hace de índice. Posición inicial: 0°.

**Antes de P4 [EXTENSIÓN 3]:** el medallón tiene un pasador. Al arrastrarlo, gira 3°, vuelve con `SFX_KIT_RATTLE` (como el pestillo bloqueado, M5) y sale `TST_P5_BLOQUEADO`. En el reflejo ya se ve, desenfocada y descolocada, la foto de la pared: el jugador puede intuir qué hace el medallón antes de poder usarlo.

**Después de P4:** gira libre (M7), con `SFX_KIT_TICK` cada 5°.

**El reflejo:** el cristal muestra a la vez la foto pequeña de la caja (detrás) y el reflejo de la foto de la pared (delante). El reflejo está girado y desplazado respecto a la foto pequeña en proporción a |θ − 40°|. Cuanto más cerca de 40°, más se solapan las dos imágenes: es un «frío o caliente» sin palabras. El reflejo es una superposición falsa (textura de la foto de la pared transformada según θ); no hace falta un reflejo físico real.

**Solución:** θ = 40° ± 3° (± 6° con asistencia), sostenido 0,8 s.

**Revelación:**
1. El medallón se bloquea en 40° con `SFX_KIT_CLUNK`.
2. Fundido de 1,2 s: las cinco figuras que coinciden en las dos fotos se funden en una sola imagen. La figura de Vera, abajo a la derecha con el peluche cúbico, solo existe en el reflejo: queda sola, con un contorno.
3. `pendiente_revelacion` = verdadero. Suena `VO_G_07` (unos 14 s) desde dentro de la caja, como de un altavoz pequeño. La lluvia baja.
4. Al terminar: `pendiente_revelacion` = falso. `caja_c3` = verdadero. Luz 3 verde. `EV_PUZZLE_SOLVED_P5`. Guardado.
5. Aviso `TST_P5_DESPUES`.

Si el jugador sale del modo examen o del despacho durante la grabación, se guarda `pendiente_revelacion` y la revelación se repite completa al volver a enfocar el medallón.

| ID | Cuándo | Texto |
|---|---|---|
| `TST_P5_ENFOQUE_A` | Enfocar la derecha, con pasador | «Un medallón con un cristal. Refleja algo de la pared.» |
| `TST_P5_BLOQUEADO` | Intentar girar con pasador | «Tiene un pasador. No gira. Todavía.» |
| `TST_P5_ENFOQUE_B` | Enfocar la derecha, libre | «Ahora gira. El cristal tiene dos fotos: una dentro y otra reflejada.» |
| `TST_P5_CERCA` | Primera vez que |θ − 40| ≤ 10° | «Casi encajan.» |
| `TST_P5_DESPUES` | Tras `VO_G_07` | «Las tres luces de arriba están verdes.» |
| `TST_P5_ENFOQUE_C` | Enfocar la derecha, resuelto | «Estaba. Yo estaba.» |

**Pistas del menú [CANON]:**
1. «El reflejo muestra algo que la foto de la caja no muestra.» (`PST_P5_1`)
2. «Compara las dos fotos con atención.» (`PST_P5_2`)
3. La marca de 40° del aro se ilumina. (`PST_P5_3`)

### 4.6 Puzle 6 · ¿Qué responde Vera? (superior)

**Idea:** la caja guarda una carta con la letra de Vera a la que le falta la primera frase. Hay tres tiras de papel, también con su letra. Elige una.

**El pestillo (M5):** igual que el piloto. Con alguna luz roja, avanza 0,16 y vuelve con `SFX_KIT_RATTLE`. El aviso dice cuál falta (la primera roja). Con las tres verdes, el pestillo corre entero y abre las dos tapas.

**Lo que sube (M6):** al pasar del 55 % de apertura, `SFX_KIT_REVEAL` y sube despacio (2,8 s) una bandeja de madera clara con una luz cálida y tenue (no el cristal cian del piloto). En la bandeja:
- La **carta** (I-07): una hoja con la letra de Vera. La primera línea está en blanco. Debajo, el cuerpo: `CARTA_CUERPO`.
- **Tres tiras de papel** con la letra de Vera, en fila: «Estoy bien.» · «La verdad.» · «Todavía no.»

**Elegir [EXTENSIÓN 4]:** el final del piloto se toca una vez. Aquí hay tres cosas que tocar, y la elección es definitiva, así que se usa la **selección del inventario** (M3) como confirmación:
1. Primer toque en una tira: la tira se levanta 1 cm y se ilumina (seleccionada). `SFX_KIT_TICK`. Aviso `TST_P6_SELECCION`.
2. Tocar otra tira: cambia la selección.
3. Segundo toque en la tira seleccionada: **confirmación**. `SFX_LOCK_CLICK` (0,3 s). La tira vuela hasta la primera línea de la carta y se queda allí (0,7 s). Las otras dos se deslizan dentro de la caja (`SFX_KIT_SLIDE`) y no vuelven.

**Resolución:**
1. `carta_variante` = `A` («Estoy bien»), `B` («La verdad») o `C` («Todavía no»).
2. `caja_c4` = verdadero. Con c1 a c4: `caja_completa` = verdadero. `EV_PUZZLE_SOLVED_P6`. Guardado.
3. Tocar la carta: lectura de la primera frase de la variante (`CARTA_A`, `CARTA_B` o `CARTA_C`) más `CARTA_CUERPO`. Queda en el bolsillo como I-07.
4. Aviso `TST_P6_DESPUES`. Las tapas se quedan abiertas.

| ID | Cuándo | Texto |
|---|---|---|
| `TST_P6_ENFOQUE_A` | Enfocar arriba, pestillo bloqueado | «Un pestillo y tres luces.» |
| `TST_P6_BLOQ_1` | Pestillo bloqueado, luz 1 roja | «No cede. La primera luz está roja. Empecemos por delante.» |
| `TST_P6_BLOQ_2` | Pestillo bloqueado, luz 2 roja | «No cede. La segunda luz sigue roja. Algo en la parte de atrás.» |
| `TST_P6_BLOQ_3` | Pestillo bloqueado, luz 3 roja | «No cede. Falta la tercera. El lateral derecho.» |
| `TST_P6_ENFOQUE_B` | Enfocar arriba, desbloqueado y cerrado | «Tres luces verdes. Ahora sí.» |
| `TST_P6_CARTA` | La bandeja termina de subir | «Es mi letra. Una carta para él. Le falta la primera frase.» |
| `TST_P6_SELECCION` | Primera selección de una tira | «¿Esta? Luego no podré cambiarla.» |
| `TST_P6_DESPUES` | Tras leer la carta | «Es mi letra. Esta noche eso ya no me sorprende.» |

**Pistas del menú [CANON]** (dos niveles; salen solas en el aviso si el jugador no elige):
1. A los 10 s con la bandeja arriba y sin confirmar: «Solo puedes elegir una vez.» (`PST_P6_1`)
2. A los 20 s: «La carta no cambia; cambia la primera frase.» (`PST_P6_2`)

### 4.7 Al salir del despacho

Con `caja_completa`, al cruzar la puerta de D la luz del despacho se apaga detrás de Vera. Empieza la escena 7 (`02`).

## 5. Accesibilidad

| Opción | Efecto en estos puzles |
|---|---|
| **Asistencia de puzles** | Tambores y lámparas: el paso pasa de 30 px a 20 px y el imán actúa antes. Medallón: tolerancia ± 6°. Cajón y eje: el anillo de guía es más grande |
| **Manivela sin gesto circular** | Mantener el botón de acción gira la manivela a una vuelta cada 2 s; el sentido lo marca el stick o las flechas (↻ / ↺). Lo mismo para la llave del Archivo |
| **Reducir movimiento** | Los objetos no vuelan a la cámara: aparecen en el inventario con un fundido de 100 ms. Sin balanceo de la bandeja ni del engranaje del cajón. Las tapas se abren con fundido |
| **Reducir sobresaltos** | Sin cambio en los puzles (no tienen sobresaltos) |
| **Daltonismo** | Las luces del pestillo cambian de forma (hueca/llena) además de color. Las gemas de la trasera, igual |
| **Subtítulos** | `VO_G_07` y `VO_V_08` subtitulados. Los avisos `TST_` ya son texto |
| **Texto grande** | Avisos y lecturas escalan con el tamaño de texto global |

## 6. Orden de construcción y criterio de «hecho»

1. **Caja del Guardián** en escena aislada, con fotos provisionales. Hecha cuando un jugador nuevo, sin explicación, la abre entera en menos de 12 minutos y elige una tira sabiendo que elige.
2. **Cajetín de transición** con una impresión de correos en papel al lado. Hecho cuando el jugador entiende que las horas son los correos sin la pista 3.
3. **Lámparas** con el ventanal. Hecho cuando el sello de Dirección se ve al entrar y el jugador gira lámparas sin que nadie se lo diga.
4. **Integración** en el recorrido de `02`, con banderas y guardado.

**Criterios de aceptación comunes:**
- AC-1 · Cada gesto de cada objeto tiene sonido y movimiento.
- AC-2 · Ningún estado del objeto deja al jugador sin una acción posible que avance (sin bloqueo sin salida).
- AC-3 · Todo intento bloqueado muestra un aviso que dice dónde mirar.
- AC-4 · Salir y volver deja el objeto exactamente igual.
- AC-5 · Cerrar el juego y volver recupera el último puzle resuelto, incluido `pendiente_revelacion`.
- AC-6 · `t4_decision` se escribe antes que `caja_c2`; `carta_variante` antes que `caja_c4`.
- AC-7 · Las dos opciones de T4 y las tres tiras de P6 se pueden elegir y las tres variantes se oyen después en la llamada.
- AC-8 · Todos los textos en pantalla salen de `05-textos.md` por su ID.
- AC-9 · Se puede jugar entero con mando y entero con ratón.

## 7. Decisiones tomadas

**Aprobadas por el autor el 2026-11-12.** Cada una cambia algo del slice v0.4.4 y prevalece sobre él.

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D-B1 | Caja en cadena lineal c1 → c2 → c3 → c4 | c2 libre (D-16 del slice) | El engranaje del cajón une P3 y P4 como en el piloto, que se entiende sin guía. Coste: P4 ya no se puede hacer primero |
| D-B2 | P4 sin deducción de urgencia y responsable en T1–T3: las tres se leen y se encienden al girar | Tres selectores por ficha, o tres medallones de tres posiciones | La pregunta del puzle es la elección de T4; T1–T3 eran trámite. Se conserva su texto y su sentido (lo mío, lo suyo, lo de Dirección) |
| D-B3 | P3 con tambores y cara limada en lugar de encaje de cinco piezas y seis huecos | El encaje del slice | Mismo mensaje (el hueco es la respuesta) con una mecánica ya probada. Y la cara limada añade el borrado de Vera sin decir quién |
| D-B4 | P1 con cajetín de tambores, tapa con horas y llave, en lugar del panel de cuatro huecos | El panel del slice | Enseña en el primer puzle las piezas que se usan en la caja (tapa, tambores, cajón, inventario, giro) |
| D-B5 | P6 con tres tiras de papel y confirmación en dos toques, en lugar de tres botones | Tres botones de un toque | La elección es definitiva (D-14); el segundo toque evita elegir sin querer. Las tiras con la letra de Vera dicen que es ella quien elige su frase |
| D-B6 | Avisos de contexto como pensamientos de Vera, en texto | Avisos neutros como en el piloto, o con voz | Dan el humor seco del tono sin grabar más voz |
| D-B7 | El Guardián hacía juegos; «¿Jugamos esta noche?» es su manera de proponer uno | Dejar el mensaje sin conexión | Une la escena 1 con la caja sin añadir escenas, y no aclara si la caja es regalo o trampa |
| D-B8 | Equipo identificado por objetos; el cubo de Vera viene del peluche de su despacho | Nombres para el equipo | Menos canon, y el jugador reconoce a Vera sin que nadie la nombre |
| D-B9 | `SFX_KIT_CHIME` en menor y corto; la lluvia baja tras cada acierto | El arpegio luminoso del piloto | El tono es melancólico; un acierto no es una celebración |
| D-B10 | Ítems nuevos: I-08 (llave del Archivo) e I-09 (engranaje). No son documentos: no se releen desde el bolsillo | — | Son las piezas que M3 necesita |
