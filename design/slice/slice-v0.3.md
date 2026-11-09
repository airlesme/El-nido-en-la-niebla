# El Nido en la Niebla · Documento de referencia del vertical slice «Turno de noche»

**Versión:** 0.3
**Fecha:** 2026-11-08
**Estado:** base para desarrollo. Sujeta a revisión tras el primer playtest.
**Alcance:** vertical slice de 25 a 30 minutos.

> Este documento es la fuente de verdad para el slice. Prevalece sobre el GDD general (v0.1, 26 de octubre de 2026) y sobre las versiones 0.1 y 0.2 de este documento. Donde el GDD general diga tercera persona, el slice usa **primera persona** (decisión D-01). Los anexos A a D contienen el detalle de implementación de espacios, puzles, eventos e inventario.

---

## 1. Resumen

Vera, una líder recién trasladada a una unidad nueva sin procedimientos ni equipo, se queda a trabajar de noche durante una lluvia continua. En la planta nueve encuentra un formulario de traslado con su firma, un conjunto de correos que no cuadran con esa firma y una caja cerrada que dejó su antiguo responsable, El Guardián.

Para avanzar hay que resolver puzles que responden preguntas concretas de la historia: cuándo se decidió el traslado, qué dice el memorando oficial, quién falta en la foto del equipo, qué tareas le corresponden y qué quiere ella hacer con todo ello.

El slice termina con una pregunta abierta: quién firmó la solicitud, y qué elige Vera hacer con lo que ha descubierto.

## 2. Objetivo del slice

Comprobar, con un prototipo de calidad final en lo que se muestra, si:

1. El bucle **buscar información → resolver puzle → descubrir historia** funciona como juego.
2. Cada puzle responde a una pregunta de la historia o fuerza una elección.
3. La tensión se mantiene **sin castigo** (ni muerte, ni game over, ni penalizaciones).
4. La ambigüedad narrativa engancha en lugar de confundir.
5. Las decisiones del jugador tienen efectos visibles.
6. El alcance de la versión completa es realista para el equipo.

## 3. Incluye / no incluye

**Incluye**
- Un piso con cuatro espacios: despacho de Vera, Archivo, Sala de Reuniones y Despacho del Guardián (sección 7).
- Búsqueda en ordenador y lectura de documentos.
- Seis puzles, cada uno con una función narrativa (sección 10).
- Una llamada telefónica con respuestas seleccionables, cuyo inicio depende de la carta elegida.
- Un final de slice con variaciones según las elecciones.

**No incluye**
- Ciudad exterior o más plantas.
- Combate o enemigos que persigan al jugador.
- Sistemas de gestión de tareas completos (solo el tablero del compartimento 2).
- Guardado manual (sí hay guardado automático al abrir puertas y al completar compartimentos).
- Localización a otros idiomas (solo español en esta versión).
- Despacho de Dirección como sala jugable (eliminado en v0.2, ver D-11).

## 4. Pilares y tono

1. **Ambivalencia sin moral binaria.** No hay medidor de bueno o malo. Afecto y daño pueden coexistir.
2. **El espacio expresa la emoción.** Luces, reflejos y sonidos cambian con la tensión, sin necesidad de explicarlo.
3. **Autonomía como progresión.** Avanzar es decidir qué mirar, qué aceptar y qué responder.
4. **Tensión sin castigo.** Los sustos son sonido, luz y silencio. Nunca bloquean la historia.
5. **Información incompleta.** Ninguna pista confirma las intenciones de nadie. Los documentos pueden contradecirse.

**Tono:** misterio nocturno, íntimo y melancólico. Humor seco de Vera como mecanismo de defensa. Momentos de silencio largo.

## 5. Perspectiva y controles

- **Perspectiva:** primera persona, cámara a la altura de los ojos de Vera.
- **Animaciones:** manos visibles en todas las interacciones (abrir cajones, teclear, girar palancas, sostener el teléfono, pasar páginas, rotar objetos, encajar piezas).
- **Movimiento:** teclado y ratón o mando. Desplazamiento a velocidad de paseo; sin sprint.
- **Inspección:** los objetos pequeños se pueden girar en la mano. Pulsación prolongada para leer.
- **Interacción:** una sola tecla o botón contextual.
- **Accesibilidad:** subtítulos completos, remapeo, regulación independiente de voces y efectos, opción de reducir sobresaltos.

## 6. Personajes

| Personaje | Presencia | Notas |
|---|---|---|
| **Vera** | Voz interior y voz en la llamada. Sin cuerpo visible (manos en primera persona). | Voz: grabación del desarrollador, sin conversión. Nombre completo pendiente (D-04). |
| **El Guardián** | Solo grabaciones, correos, documentos escritos y voz en la llamada. Nunca aparece en pantalla. | Voz convertida desde la grabación del desarrollador, con timbre distinto al de Vera. No es villano ni héroe. |
| **Megafonía** | Voz automática del edificio. | Frases breves, tono neutro. |
| **Presencias** | Sonido de sillas, tecleo, pasos. Sin voz. | Nunca se acercan a una distancia que obligue a reaccionar. |

## 7. Espacios y acceso

| Espacio | Acceso | Qué contiene | Qué entrega |
|---|---|---|---|
| **Despacho de Vera** | Inicio | Escritorio, ordenador, teléfono, caja de cartón, peluche cúbico | Ninguna |
| **Archivo (A)** | Puzle 1 (cronología) | Formulario de traslado, estanterías | Tarjeta de la Sala de Reuniones (llave de B) y tarjeta sin foto (llave de D) |
| **Sala de Reuniones (B)** | Tarjeta de A + Puzle 2 (lámparas) | Mesa de cristal, memorando escrito en el cristal | Lectura del memorando |
| **Despacho del Guardián (D)** | Tarjeta sin foto | Abrigo mojado, taza fría, foto del equipo con Vera al margen, caja de madera | Caja con cuatro compartimentos (puzles 3 a 6) |
| **Ascensor y Recepción** | Se activa tras la llamada | Libro de visitas | Fin del slice |

**Puertas cerradas en el slice:** tres (A, B y D). Las tres dependen de la misma fuente, el Archivo, o de la caja.

## 8. Progresión

Grafo de dependencias. Cada flecha es una condición:

1. Despacho de Vera → buscar «transición» en el ordenador → **flag** `correos_leidos`.
2. `correos_leidos` → resolver Puzle 1 → **flag** `archivo_abierto`. Se entregan `tarjeta_B` y `tarjeta_D`.
3. `tarjeta_B` → entrar en Sala B → resolver Puzle 2 → **flag** `memo_leido`.
4. `tarjeta_D` → entrar en D → resolver compartimentos 1 a 4 en cualquier orden, aunque la lectura tiene sentido en este orden → **flag** `caja_completa`.
5. Al salir de D con `caja_completa`, se activa la llamada (escena 7). Es el único disparador de la llamada.
6. Llamada completada → se activa el ascensor → Recepción (escena 8).

**Nota:** el jugador puede visitar la Sala B antes o después de D. Si no tiene `tarjeta_B`, la puerta muestra un mensaje de cerrada, sin penalización.

## 9. Línea temporal

Esta es la cronología interna del slice. Los personajes no la explican. El jugador la reconstruye con los documentos.

| Momento | Qué ocurre | Fuente |
|---|---|---|
| Hace nueve días | Vera está en Lisboa. El formulario de traslado aparece firmado con su nombre. | Formulario (Archivo) · Vera (`VO_V_04`) |
| Lunes 09:14 | El Guardián le pregunta si puede hablar del traslado esta semana. | Correo ref. 2 |
| Lunes 11:40 | El traslado queda pendiente de la confirmación de Vera. | Correo ref. 1 |
| Lunes 16:02 | La solicitud queda registrada a nombre de Vera. | Correo ref. 3 |
| Martes 08:55 | Dirección confirma que Vera figura en la unidad nueva. | Correo ref. 4 |
| Hoy, noche | El memorando dice «ratificación pendiente». La caja contiene una confesión a medias. | Memorando (Sala B) · Caja (compartimentos) |

**Contradicción deliberada:** el formulario está firmado antes de que se pida la confirmación de Vera. Ninguna fuente aclara si ella firmó, si alguien firmó por ella o si el formulario se preparó antes de la conversación.

## 10. Puzles

Los puzles 1 a 5 tienen tres niveles de pista y el puzle 6 tiene dos (Anexo B.6; decisión del usuario, 2026-11-09), accesibles desde el menú de pausa o mediante gesto de cámara. Ningún puzle bloquea la historia si el jugador falla. Cada puzle tiene una **función narrativa**: qué pregunta responde o qué elección obliga.

| Puzle | Pregunta que responde o elección que fuerza | Ubicación |
|---|---|---|
| **1 · Cronología** | ¿Cuándo se decidió el traslado y sin qué confirmación? | Archivo |
| **2 · Reflejo del memorando** | ¿Qué dice oficialmente Dirección? | Sala de Reuniones |
| **3 · Encaje de la foto** | ¿Quién falta en la foto del equipo? | Caja, compartimento 1 |
| **4 · Tablero de tareas** | ¿Qué carga acepta Vera y cuál devuelve? | Caja, compartimento 2 |
| **5 · Espejo de la diferencia** | ¿Qué cambia entre la foto de la caja y la del despacho? | Caja, compartimento 3 |
| **6 · Decisión** | ¿Qué respuesta da Vera a la carta que escribió? | Caja, compartimento 4 |

### 10.1 Puzle 1 · Cronología (Archivo)

- **Mecánica:** un panel con cuatro huecos. Cada hueco acepta la referencia de un correo (1 a 4). El jugador introduce las referencias en orden cronológico de envío.
- **Solución:** `2 · 1 · 3 · 4`.
- **Fuente:** los cuatro correos de la búsqueda «transición» (ver tabla).
- **Si falla:** los cuatro huecos vibran y las referencias vuelven a la impresión tras 1,5 s. Sin penalización. Detalle en el anexo B.1.
- **Pistas:**
  1. Nivel 1: gesto de cámara hacia la impresión de los cuatro correos.
  2. Nivel 2: el pie de la impresión dice «Ordena por hora de envío».
  3. Nivel 3: la hora de envío aparece en letra pequeña al pie de cada correo impreso.
- **Función:** reconstruye la línea temporal (sección 9). Confirma que la solicitud se registró después de que el formulario pareciera firmado y que Vera nunca confirmó.

**Correos de la búsqueda «transición»:**

| Ref. | Envío | Contenido |
|---|---|---|
| 1 | Lunes 11:40 | «Traslado de Vera: pendiente de tu confirmación. — G.» |
| 2 | Lunes 09:14 | «Vera, ¿te viene bien que lo hablemos esta semana? — G.» |
| 3 | Lunes 16:02 | «Solicitud registrada a nombre de Vera. Yo me encargo del resto. — G.» |
| 4 | Martes 08:55 | «Vera ya figura en la unidad nueva. — Dirección» |

Hay además dos correos sin relación (un recordatorio de cambio de extensiones y un aviso de mantenimiento del aire acondicionado). Son ruido, pero dan textura.

### 10.2 Puzle 2 · Reflejo del memorando (Sala de Reuniones)

- **Mecánica:** tres lámparas de escritorio con cuatro posiciones cada una. En el cristal hay tres fragmentos de un memorando escrito al revés. Cada lámpara debe iluminar un fragmento concreto.
- **Solución:**

| Lámpara | Posición | Fragmento que ilumina |
|---|---|---|
| Izquierda | 3 | «Traslado de Vera: aprobado a petición de la interesada.» |
| Central | 1 | «Ratificación pendiente» |
| Derecha | 4 | «de firma del responsable.» |

- **Si falla:** las lámparas parpadean. No hay penalización.
- **Pistas:**
  1. Nivel 1: el memorando al revés es legible en el reflejo del cristal.
  2. Nivel 2: las marcas numeradas (1 a 4) del suelo junto a cada lámpara.
  3. Nivel 3: cada lámpara muestra un halo sobre su fragmento al acercar la cámara.
- **Recompensa:** el memorando completo queda legible. No hay llave ni objeto.
- **Función:** entrega la versión oficial de Dirección. Su contenido contradice el formulario: sí se aprobó «a petición de la interesada», pero la firma del responsable está pendiente.

### 10.3 Puzle 3 · Encaje de la foto (Caja, compartimento 1)

- **Mecánica:** la foto del equipo está rota en cinco piezas. Hay seis huecos en el marco. El jugador encaja las cinco piezas.
- **Solución:** las cinco piezas encajan en sus huecos por forma y color. El sexto hueco queda **vacío** y el mecanismo lo acepta.
- **Si falla:** la pieza vuelve a la mesa. Sin penalización.
- **Pistas:**
  1. Nivel 1: el marco tiene una silueta de cada hueco.
  2. Nivel 2: las piezas tienen los bordes numerados por fila.
  3. Nivel 3: al acercar la cámara, el hueco vacío muestra una silueta sin pieza.
- **Recompensa:** el compartimento se abre y muestra una nota en letra del Guardián: «La transición es tuya».
- **Función:** la foto del equipo no tiene a Vera. El puzle no se puede completar sin dejar ese hueco vacío. La ausencia es la historia.

### 10.4 Puzle 4 · Tablero de tareas (Caja, compartimento 2)

- **Mecánica:** cuatro fichas de tarea. Cada una tiene una descripción que indica lo que pide. El jugador asigna urgencia y responsable, o devuelve la ficha.
- **Regla visible en el tablero:** «Acepta lo que tiene urgencia y responsable. Devuelve lo que no te corresponde».

| Ficha | Descripción | Acción correcta |
|---|---|---|
| Cliente Lima | «Revisión antes del jueves. Ya la tiene asignada Vera.» | Urgencia **Alta**, responsable **Vera** |
| Revisión de contrato | «Lleva tres semanas parada. Solo puede firmarla quien dirigía el equipo anterior.» | Urgencia **Media**, responsable **Guardián** |
| Mudanza del archivo | «Sin fecha. Requiere aprobación de Dirección.» | Urgencia **Baja**, responsable **Dirección** |
| Carta a Dirección | «Explicar a Dirección la solicitud de traslado en nombre de la interesada.» (Nombre tachado y reemplazado por «G».) | **Devolver** |

- **Si falla:** la ficha se resiste (vibración y devolución a la posición inicial). Sin penalización.
- **Sin temporizador:** una ficha sin decidir permanece en la mesa. Este puzle no tiene reglas de tiempo.
- **Pistas:**
  1. Nivel 1: cada ficha tiene una marca de color para la urgencia.
  2. Nivel 2: la descripción de la ficha se resalta al pasar el cursor.
  3. Nivel 3: la regla del tablero se ejemplifica con la ficha «Cliente Lima».
- **Recompensa:** la lista de tareas del Guardián, con el nombre de Vera tachado en la última entrada.
- **Función:** la respuesta se deduce del contenido, no del azar. La ficha de la carta obliga a elegir si Vera habla por otra persona. Es la primera elección de autonomía del slice.

### 10.5 Puzle 5 · Espejo de la diferencia (Caja, compartimento 3)

- **Mecánica:** un marco interior con una superficie reflectante. El jugador lo gira hasta alinear el reflejo de la foto del marco de la pared (en el mismo despacho) con la foto de la caja (la del puzle 3).
- **Solución:** rotación de **40°** (valor de referencia; el equipo puede ajustar la tolerancia).
- **Efecto al alinear:** las dos fotos se superponen. Solo queda visible la figura de Vera, que existe en la foto de la pared pero no en la de la caja.
- **Si falla:** el marco vuelve a su posición inicial. Sin penalización.
- **Recompensa:** se activa la grabación del Guardián (`VO_G_07`).
- **Función:** convierte la diferencia del puzle 3 en revelación. El jugador comprueba por sí mismo que Vera estaba en la foto, y después escucha la grabación.

### 10.6 Puzle 6 · Decisión (Caja, compartimento 4)

- **Mecánica:** tres botones: **«Estoy bien»**, **«La verdad»** y **«Todavía no»**.
- **Solución:** cualquiera de los tres. **No hay respuesta incorrecta, por diseño.**
- **Efecto:** cada botón abre la carta con una primera frase distinta (`CARTA_A`, `CARTA_B`, `CARTA_C`). El cuerpo de la carta es el mismo. La variante se guarda en `carta_variante` y **cambia la primera frase de la llamada** (escena 7).
- **Función:** la primera decisión de la historia que se ve reflejada después. Si el jugador elige «Estoy bien» y luego la voz le dice que lo escribió, la elección tiene peso.

## 11. Escenas

### Escena 1 · Llegada (23:40)

- Fundido desde negro. Lluvia contra un cristal. Un ventilador que vibra.
- Megafonía (`MEGA_01`).
- Voz interior de Vera (`VO_V_01`).
- Mensaje del contacto «Guardián»: «¿Jugamos esta noche?». Vera responde «Ahora no». Aparece: «Este número ya no está disponible».

### Escena 2 · El correo (00:05)

- El buscador muestra los cuatro correos (sección 10.1).
- Es la puerta de entrada al puzle 1.

### Escena 3 · Archivo (puerta A)

- Tras resolver el puzle 1, el jugador encuentra el formulario, la tarjeta de la Sala de Reuniones y la tarjeta sin foto.
- Voz interior (`VO_V_04`). Sonido: la lluvia se intensifica al leer la fecha.

### Escena 4 · Pasillo (00:40)

- Megafonía: «Reunión de dirección en la sala nueve B» (`MEGA_02`). No hay nadie.
- Las luces parpadean. En el cristal, el reflejo de Vera llega un instante tarde.
- Aviso visual, no ataque. Cuando el jugador gira la cabeza, el reflejo vuelve a la normalidad.

### Escena 5 · Sala de Reuniones (puerta B)

- Puzle 2. Al completarlo, el memorando queda legible en el cristal.
- Voz interior (`VO_V_08`). Sonido: silencio, salvo el zumbido de las lámparas.

### Escena 6 · Despacho del Guardián (puerta D)

- Entrada: abrigo mojado en la silla, taza fría, foto del equipo con Vera al margen en la pared.
- La caja de madera con cuatro compartimentos (puzles 3 a 6).
- Las recompensas se muestran en orden: nota, lista de tareas, grabación y carta.
- Al salir con `caja_completa`, la luz del despacho se apaga (ver escena 7).

### Escena 7 · Corte de luz y llamada (02:30)

- Apagón completo. Sillas rodando por el pasillo. Tecleo en un escritorio cercano.
- Suena el teléfono del despacho de Vera. El número que aparece es **su propia extensión**.
- Vera descuelga. Silencio y respiración.
- **Primera línea** según la carta elegida:
  - Carta A (`carta_variante = A`): `VO_G_12A` «Has escrito que estás bien. ¿Estás resfriada?».
  - Carta B (`carta_variante = B`): `VO_G_12B` «Has escrito que no sabes qué firmaste. ¿Estás resfriada?».
  - Carta C (`carta_variante = C`): `VO_G_12C` «Has escrito que todavía no puedes enviarlo. ¿Estás resfriada?».
- Opciones de respuesta (sección 11.1).
- Si no hay respuesta durante veinte segundos: se oye un llanto contenido y El Guardián dice «Sigo aquí» (`VO_G_14`). Las opciones siguen visibles y no hay elección automática. El botón «No responder» equivale al silencio.
- La llamada termina. Vuelve la lluvia.

#### 11.1 Respuestas de la llamada

| Opción de Vera | Guarda | Respuesta de El Guardián |
|---|---|---|
| «Estoy bien» | `A` | `VO_G_13A`: «Ya. Eso dijiste también la última vez». |
| «Estoy desbordada» | `B` | `VO_G_13B`: «Lo sé. Por eso lo pedí». |
| «No quiero hablarlo ahora» | `C` | `VO_G_13C`: «Vale. Pero la caja sigue en tu mesa». |
| No responder | `D` | `VO_G_13D`: «Entonces hablo yo. Te he dejado la caja abierta. Cuando quieras». |

### Escena 8 · Recepción (03:40 a 04:10)

- La lluvia cesa. El ascensor baja despacio.
- Libro de visitas abierto. Última entrada: «Vera · 23:40 · Planta 9». Debajo, hace nueve días: «Vera · 22:12 · Planta 9».
- La letra es idéntica. La V de la segunda entrada está cerrada hacia dentro.
- **Última línea de Vera** según la respuesta de la llamada (`respuesta_llamada`):
  - A: `VO_V_12A` «Le dije que estaba bien. Ninguno de los dos se lo creyó».
  - B: `VO_V_12B` «Le dije que estaba desbordada. Era lo más cierto de la noche».
  - C: `VO_V_12C` «No quise hablarlo. La caja sigue en mi mesa».
  - D: `VO_V_12D` «No dije nada. Él habló por los dos».
- Cierre común: `VO_V_12E` «La V no me convence».
- Corte a negro. Título y rótulo «Continuará».

## 12. Líneas de guion

Cada línea tiene un ID para que audio, localización y QA puedan referenciarla.

| ID | Hablante | Texto | Escena |
|---|---|---|---|
| `MEGA_01` | Megafonía | «Turno de noche. Recuerde que la planta nueve está en modo de ahorro energético». | 1 |
| `VO_V_01` | Vera | «Tres días en esta unidad y todavía no sé dónde está el archivo de transición. Solo sé que me toca a mí». | 1 |
| `VO_V_04` | Vera | «Hace nueve días estaba en un avión a Lisboa. Me acuerdo porque no pude dormir. Y la firma es mía. O se parece tanto que da igual». | 3 |
| `MEGA_02` | Megafonía | «Reunión de dirección en la sala nueve B». | 4 |
| `VO_V_08` | Vera | «Ratificación pendiente. Llevo tres días aquí. Da igual si está firmada». | 5 |
| `DOC_01` | Memorando | «Traslado de Vera: aprobado a petición de la interesada. Ratificación pendiente de firma del responsable». | 5 |
| `VO_G_07` | El Guardián | «Venga, que somos un equipo». [pausa] «No. Esa toma no. Lo pedí sin preguntarte, Vera. Lo pedí y después te lo conté como si fuera tuyo». | 6 |
| `NOTA_01` | Nota (letra del Guardián) | «La transición es tuya». | 6 |
| `NOTA_02` | Nota (letra del Guardián) | «No te quites la carga. Yo tampoco». | 5 |
| `CARTA_A` | Carta (letra de Vera) | «Estoy bien. Es lo que escribiría si no fuera verdad». | 6 |
| `CARTA_B` | Carta (letra de Vera) | «La verdad es que no sé qué firmé». | 6 |
| `CARTA_C` | Carta (letra de Vera) | «Todavía no puedo enviarte esto». | 6 |
| `CARTA_CUERPO` | Carta (letra de Vera) | «No quiero que me digas que somos un equipo. Quiero que me digas por qué firmé». | 6 |
| `VO_G_12A` | El Guardián | «Has escrito que estás bien. ¿Estás resfriada?». | 7 |
| `VO_G_12B` | El Guardián | «Has escrito que no sabes qué firmaste. ¿Estás resfriada?». | 7 |
| `VO_G_12C` | El Guardián | «Has escrito que todavía no puedes enviarlo. ¿Estás resfriada?». | 7 |
| `VO_G_13A` | El Guardián | «Ya. Eso dijiste también la última vez». | 7 |
| `VO_G_13B` | El Guardián | «Lo sé. Por eso lo pedí». | 7 |
| `VO_G_13C` | El Guardián | «Vale. Pero la caja sigue en tu mesa». | 7 |
| `VO_G_13D` | El Guardián | «Entonces hablo yo. Te he dejado la caja abierta. Cuando quieras». | 7 |
| `VO_G_14` | El Guardián | «Sigo aquí». | 7 |
| `VO_V_12A` | Vera | «Le dije que estaba bien. Ninguno de los dos se lo creyó». | 8 |
| `VO_V_12B` | Vera | «Le dije que estaba desbordada. Era lo más cierto de la noche». | 8 |
| `VO_V_12C` | Vera | «No quise hablarlo. La caja sigue en mi mesa». | 8 |
| `VO_V_12D` | Vera | «No dije nada. Él habló por los dos». | 8 |
| `VO_V_12E` | Vera | «La V no me convence». | 8 |

**Regla de escritura:** las líneas del Guardián nunca explican por qué pasó algo. Pueden contradecirse con los documentos. Ningún personaje confirma intenciones.

## 13. Sistemas y estado

### 13.1 Banderas (flags)

| Flag | Tipo | Se activa en | Se usa en |
|---|---|---|---|
| `correos_leidos` | bool | Escena 2 | Puzle 1 |
| `archivo_abierto` | bool | Escena 3 | Accesos |
| `tarjeta_B` | bool | Escena 3 | Puerta de B |
| `tarjeta_D` | bool | Escena 3 | Puerta de D |
| `memo_leido` | bool | Escena 5 | Recepción (opcional, pistas) |
| `caja_c1` a `caja_c4` | bool | Escena 6 | Puzles 3 a 6 |
| `caja_completa` | bool | Escena 6 | Disparador de la llamada |
| `carta_variante` | enum (`A`, `B`, `C`) | Puzle 6 | Escena 7 (primera línea) |
| `respuesta_llamada` | enum (`A`, `B`, `C`, `D`) | Escena 7 | Escena 8 (última línea) |
| `llamada_completada` | bool | Escena 7 | Activa el ascensor |

### 13.2 Guardado

- **Automático** al abrir cualquier puerta y al completar cada compartimento de la caja.
- **Sin guardado manual** en el slice.
- Si el jugador cierra el juego durante la llamada, al volver se reanuda en el despacho con la llamada pendiente.

### 13.3 Casos límite (sin softlock)

- Si el jugador sale de la Sala B sin cuadrar las lámparas, quedan en la última posición. Puede volver cuando quiera.
- Si el jugador deja «Carta a Dirección» sin decidir, la ficha permanece en la mesa y el compartimento 2 no se resuelve hasta devolverla.
- Si el jugador sale de D sin completar la caja, la llamada no se activa. Puede volver a D en cualquier momento. Ningún compartimento depende de otro para ser resoluble.
- Si el jugador intenta salir del edificio antes de la llamada, el ascensor no responde y la megafonía indica «Planta en modo de ahorro energético».

## 14. Audio

- **Lluvia:** capa continua en toda la planta. Más intensa en el Archivo y en el pasillo. Se atenúa dentro de las salas cerradas.
- **Edificio:** drone de baja frecuencia (Suno, modo instrumental) con tono constante durante todo el slice.
- **Voces:** la voz de Vera (sin conversión) y la de El Guardián (convertida). Subtítulos completos.
- **Sonidos de puzle:** clics mecánicos para el panel de cronología, zumbido para lámparas, vibración para fichas, sonido de madera para la caja, sonido de metal para el encaje.
- **Silencios:** los puzles tienen silencio parcial para que el jugador escuche pistas.
- **Efectos:** pasos de Vera, sillas rodando, tecleo lejano, puerta que se cierra (dentro de la grabación de `VO_G_07`).
- **Accesibilidad:** regulación independiente de voces, efectos y música. Opción de reducir sobresaltos.

## 15. Arte y assets

**Estilo:** low poly con texturas generadas. Formas simples, luz cálida en la Sala de Reuniones (lámparas) y luz fría en el resto.

**Paleta de referencia:**
- Oficinas: verde grisáceo y azul frío.
- Lámparas y halo de la Sala de Reuniones: ámbar cálido.
- Lluvia y ventanas: gris azulado, con reflejos.

**Lista de assets mínima (P0 = necesario para el slice):**

| Asset | Prioridad | Origen previsto |
|---|---|---|
| Puerta con cerradura (x3: A, B, D) | P0 | Modelo simple, textura generada |
| Panel de cuatro huecos (puzle 1) | P0 | Modelo simple |
| Lámpara de escritorio (x3) | P0 | Modelo simple |
| Cristal con memorando al revés | P0 | Textura generada y shader |
| Caja de madera con cuatro compartimentos | P0 | Modelo simple, textura generada |
| Marco de foto con seis huecos (puzle 3) | P0 | Modelo simple |
| Piezas de foto (x5) | P0 | Textura generada |
| Marco interior con superficie reflectante (puzle 5) | P0 | Modelo simple y shader |
| Fichas de tarea (x4) | P0 | Textura de papel generada |
| Botones de decisión (x3) | P0 | Modelo simple |
| Mesa, silla, escritorio, ordenador | P0 | Assets low poly gratuitos |
| Papeles, carpetas, formulario, correos | P0 | Textura generada |
| Teléfono | P0 | Modelo simple |
| Peluche cúbico | P1 | Modelo simple |
| Escenario exterior (ventana) | P1 | Imagen generada o modelo 3D generado |
| Iluminación de lluvia | P0 | Shader y partículas |

**Modelos 3D generados por IA** (Tripo, Meshy u otra herramienta): se usan solo cuando el modelo simple no alcance. Cualquier modelo generado requiere limpieza de geometría y validación de escala antes de entrar en el proyecto.

## 16. Interfaz y feedback

- **Sin barra de salud, sin barra de cordura, sin medidor de relación.**
- **Sin game over.**
- Los puzles muestran feedback visual y sonoro en cada acción, correcta o no.
- La interacción aparece como un icono discreto cuando el objeto es interactuable.
- El menú de pausa incluye: pistas (tres niveles por puzle; dos en el puzle 6), subtítulos, controles y opciones de accesibilidad.
- Los **correos y documentos** se guardan automáticamente. Se pueden consultar desde el ordenador en cualquier momento.

## 17. Contenido sensible y clasificación

**Advertencias para el jugador (en la pantalla de inicio):**
- Estrés laboral.
- Aislamiento.
- Decepción afectiva.
- Llanto contenido.
- Dinámicas de control y de desigualdad en una relación de trabajo.

**Reglas de contenido:**
- No hay violencia gráfica en el slice.
- No hay referencias a autolesiones ni a suicidio.
- El llanto se representa como algo que el juego espera, sin penalizarlo.
- Ningún personaje da instrucciones explícitas sobre cómo sentirse.

**Clasificación:** pendiente de revisión (D-06).

## 18. Declaración de IA para Steam

Según la política de Steam de 2026, hay que declarar el contenido generado por IA que el jugador ve, oye o lee, en la ficha de la tienda. Contenido previsto en este slice:

- **Voz convertida:** la voz de El Guardián se genera a partir de grabaciones del desarrollador mediante herramientas de IA.
- **Arte generado:** texturas, papeles, fotos y escenarios de fondo generados con Midjourney (o herramienta equivalente).
- **Música:** drone generado con Suno.
- **Modelos 3D generados:** solo si se usan Tripo o Meshy en la versión final.

**Acción para el equipo:** llevar un registro de qué herramienta se usó para cada asset y confirmar los términos de licencia del plan contratado antes de publicar.

## 19. Criterios de aceptación del slice

El slice se considera aceptable cuando:

1. Un jugador nuevo completa el slice en 25 a 30 minutos sin guía externa.
2. Cada puzle se resuelve con información que está en el juego (pistas en tres niveles; dos en el puzle 6).
3. Ningún fallo en un puzle bloquea el avance.
4. Tres de cada cuatro jugadores de prueba describen el ambiente como «tenso» o «inquietante» sin usar la palabra «confuso» como única descripción.
5. Los jugadores identifican la diferencia de la foto (puzle 5) sin pista de nivel 3 en al menos la mitad de los casos.
6. Las tres variantes de carta aparecen en los playtests, y al menos un jugador menciona que la llamada cambió según su elección.
7. Ningún jugador tiene que reiniciar el juego para completar el slice.
8. Los subtítulos coinciden con todas las líneas de la sección 12.
9. El slice funciona en el equipo de referencia definido en la sección 21.

## 20. Decisiones

**Tomadas en este documento:**

- **D-01 · Perspectiva:** primera persona en el slice, no tercera persona como dice el GDD general. Motivo: la inmersión y la reducción de animación de personajes completos.
- **D-02 · Personaje del Guardián:** sin cuerpo visible en el slice. Solo voz, correos, documentos y objetos.
- **D-03 · Activación de la llamada:** requiere `caja_completa` y se activa al salir de D. La Sala de Juegos (E) queda eliminada, así que la llamada ya no depende de ningún puzle externo a la caja. *(Resuelta en v0.2.)*
- **D-09 · Efecto de las elecciones:** la carta cambia la primera línea de la llamada, y la respuesta de la llamada cambia la última línea de Vera. *(Resuelta en v0.2.)*
- **D-11 · Despacho de Dirección eliminado como sala:** el memorando pasa a escribirse en el cristal de la Sala de Reuniones. Motivo: la sala solo contenía exposición. Si el equipo quiere más espacios, Dirección puede volver como sala de exploración sin puzle.
- **D-12 · Puzle de la Sala de Juegos eliminado:** la Sala de Juegos (E) sale del slice. Su función de «amistad compartida» se traslada, si se desea, a la versión completa.

**Pendientes:**

- **D-14 · Permanencia de la carta:** la elección del compartimento 4 es definitiva. Motivo: coherencia con el pilar de autonomía. Confirmar.
- **D-15 · Silencio en la llamada:** es un botón («No responder»). Tras veinte segundos no se elige nada por el jugador. Confirmar.
- **D-16 · Orden de la caja:** el compartimento 3 requiere el 1, y el 4 requiere el 1, el 2 y el 3. El 2 es libre. Confirmar.
- **D-04 · Nombre de Vera:** provisional. Afecta a la carta, la megafonía y el formulario.
- **D-05 · Motor:** Godot o Unity. Ambos sirven. La decisión depende de la experiencia del equipo.
- **D-06 · Clasificación por edad:** pendiente de revisión.
- **D-07 · Nombre del Guardián:** se mantiene como «El Guardián» en el slice. Decidir si el nombre aparece en la versión completa.
- **D-08 · Voz de Vera:** grabación directa o convertida. Por defecto, sin conversión.
- **D-10 · Localización:** solo español en el slice. Decidir si las líneas de la sección 12 se preparan para traducción desde el principio.
- **D-13 · Número de espacios:** el brief original hablaba de varios despachos. En el slice quedan tres puertas cerradas y cuatro espacios. Confirmar si es suficiente.

## 21. Requisitos técnicos

- **Plataforma objetivo del slice:** PC (Windows y Linux). Mando compatible.
- **Equipo de referencia para pruebas:** a definir.
- **Resolución:** 1920 × 1080 como base, con escalado.
- **Idiomas de audio:** español.
- **Idiomas de texto:** español.
- **Formatos de audio:** OGG Vorbis o WAV para voces y efectos.

## 22. Riesgos

| Riesgo | Mitigación |
|---|---|
| Los puzles se perciben como tediosos | Seis puzles con funciones distintas. Ninguno requiere más de dos minutos. |
| La ambigüedad se confunde con incoherencia | Hechos observables fijos (fechas, correos, memorando, formulario). Solo las intenciones son ambiguas. |
| La voz convertida suena artificial | Grabar las líneas en varias tomas. Probar con dos motores de voz antes de decidir. |
| Los assets low poly no transmiten atmósfera | Iluminación y shaders como prioridad. Probar la escena de 30 segundos antes de modelar el resto. |
| La reducción de espacios empobrece el slice | Confirmar D-13. Si hace falta, Dirección vuelve como sala sin puzle. |
| Alcance mayor del previsto | Lista de assets P0 cerrada. Los P1 se hacen solo si sobra tiempo. |
| Problemas de licencia con IA | Registro de herramientas y términos por asset (sección 18). |
| El tema toca experiencias personales reconocibles | Ficcionalizar por completo. Revisar antes de cualquier presentación externa. |

## 23. Siguientes pasos

1. **Prototipo gris (semana 1):** despacho, Archivo y puzle 1, con geometría sin texturas.
2. **Prototipo de caja (semana 2):** compartimentos 3 a 6, sin audio final.
3. **Prototipo de llamada (semana 3):** diálogo con las tres variantes de carta y las cuatro respuestas.
4. **Primer playtest:** cinco personas, sin explicaciones previas. Observar dónde se atascan y qué elección toman.
5. **Gate de preproducción:** decidir si se continúa con la versión completa, se reduce el alcance o se rediseña el puzle que falló.

## Anexo A · Espacios (implementación)

### A.0 Convenciones

- **Unidades:** metros. Ejes: X de oeste a este, Z de sur a norte, Y de suelo a techo. Origen (0, 0, 0) en el centro del umbral de la puerta del Despacho de Vera, en la cara del pasillo.
- **Techo:** 2,70 m en todos los espacios de planta, salvo Recepción (3,20 m).
- **Puertas:** hueco de 1,00 × 2,10 m. Apertura en 1,2 s (`ANIM_DOOR_OPEN`).
- **Cámara de Vera:** altura de ojos 1,62 m. Campo de visión 70°. Sin agacharse en el slice.
- **Carga:** toda la planta es una escena continua, con las puertas como disparadores. Recepción se carga tras la escena 7 con fundido de 0,8 s.

### A.1 Envolvente de planta

| Espacio | X (m) | Z (m) | Tamaño (m) | Acceso |
|---|---|---|---|---|
| Despacho de Vera | −6,0 … 0,0 | −2,5 … 2,5 | 6,0 × 5,0 | Abierto. Umbral en X = 0, Z −0,5 … 0,5. Sin cerradura. |
| Pasillo | 0,0 … 24,0 | −1,3 … 1,3 | 24,0 × 2,6 | Continuo |
| Archivo (A) | 6,5 … 9,5 | −5,5 … −1,3 | 3,0 × 4,2 | Puerta en el muro sur del pasillo, X 7,5 … 8,5. Cerrada. El panel del puzle 1 está en el pasillo, junto a la puerta. |
| Sala de Reuniones (B) | 11,5 … 18,5 | 1,3 … 6,3 | 7,0 × 5,0 | Puerta en el muro norte del pasillo, X 12,0 … 13,0. Cerrada. |
| Despacho del Guardián (D) | 19,5 … 24,5 | 1,3 … 5,3 | 5,0 × 4,0 | Puerta en el muro norte del pasillo, X 21,0 … 22,0. Cerrada. |
| Ascensor | 1,4 … 2,6 | 1,3 … 1,3 (hueco) | Cabina externa | Hueco en el muro norte del pasillo |
| Recepción | Escena aparte | — | 8,0 × 6,0 | Desde el ascensor |

**Ventanas exteriores:** B tiene ventanal en el muro norte (Z = 6,3, X 11,5 … 18,5). D tiene ventanal en el muro norte (Z = 5,3, X 20,0 … 24,0). Vera no tiene ventana; la lluvia se oye a través de la persiana.

**Patio de luces:** ventanas altas en el muro sur del pasillo, X 12,0 … 20,0, Y 0,9 … 2,6. Reflejan el pasillo (efecto de la escena 4).

### A.2 Despacho de Vera

**Mobiliario**

| ID | Objeto | Posición (X; Z) | Tamaño (X × Z × Y) | Notas |
|---|---|---|---|---|
| V-MOB-1 | Escritorio | (−4,0; −2,05) | 1,60 × 0,80 × 0,75 | Pegado al muro sur |
| V-MOB-2 | Silla | (−4,0; −1,25) | 0,50 × 0,50 × 0,90 | Orientada al norte. Girable (decorativa). |
| V-MOB-3 | Armario bajo | (−5,5; 1,8) | 0,80 × 0,45 × 0,75 | Pegado al muro oeste. Sobre él, la impresora. |
| V-MOB-4 | Persiana | Muro norte (Z = 2,5) | 1,20 de ancho | Tapa la ventana. Cerrada. |

**Objetos interactuables**

| ID | Objeto | Posición | Interacción | Estados |
|---|---|---|---|---|
| V01 | Ordenador | Escritorio (−4,4; −2,1) | Abrir correo, buscar, imprimir | `apagado` → `sesión abierta` |
| V02 | Teléfono | Escritorio (−3,6; −2,1), 0,15 × 0,08 | Descolgar, responder | `reposo`, `vibrando`, `en_llamada` |
| V03 | Cajón | Bajo el escritorio, lado este (−3,4; −2,05; Y 0,5) | Abrir | `cerrado`, `abierto`. Contiene bolígrafo y grapas. |
| V04 | Caja de cartón | Escritorio (−5,2; −2,1), 0,40 × 0,30 × 0,25 | Inspeccionar | Texto: «Pertenencias · Equipo anterior». |
| V05 | Peluche cúbico | Escritorio (−3,0; −2,2), cubo de 0,12 | Girar en la mano | Pegatina del equipo antiguo. |
| V06 | Lámpara de escritorio | Escritorio (−4,8; −2,0) | Encender y apagar | `encendida` al inicio. 2700 K. |
| V07 | Umbral | X = 0 | Ninguna | Abierto |
| V08 | Impresora | Armario (−5,5; 1,8) | Imprimir resultados de búsqueda | `lista`, `imprimiendo` (1,5 s), `sin_resultados`. Genera I-01 si `correos_leidos` es verdadero. |

**Iluminación:** lámpara V06 (2700 K) como fuente principal. Luz de techo apagada al inicio. Pantalla del ordenador (6500 K) como fuente secundaria.

**Audio:** ventilador en bucle (52 dB). Lluvia filtrada por la persiana. Megafonía desde el pasillo.

### A.3 Pasillo

**Elementos**

| ID | Objeto | Posición | Función |
|---|---|---|---|
| C01 | Altavoz de megafonía | Techo, (10,0; 0,0; Y 2,55) | Emite `MEGA_01` y `MEGA_02` |
| C02 | Patio de luces | Muro sur, X 12,0 … 20,0 | Efecto de reflejo retardado (escena 4) |
| C03 | Luminarias | Techo, X = 3, 7, 11, 15, 19, 23 | Parpadeo (escena 4) y apagón (escena 7) |
| C04 | Cartel de planta | Muro sur, (0,3; Y 1,5) | Texto: «Planta 9 · Proyectos Nuevos» |
| C05 | Panel de cronología (puzle 1) | Muro sur, X 6,6 … 7,2, Y 1,3 | Ver B.1 |
| C06 | Lector de tarjeta B | Muro norte, (13,2; Y 1,1) | Ver A.5 |
| C07 | Lector de tarjeta D | Muro norte, (22,2; Y 1,1) | Ver A.6 |
| C08 | Ascensor | Muro norte, X 1,4 … 2,6 | Activo tras `llamada_completada` (escena 8) |

**Disparadores**

| Zona | Condición | Efecto |
|---|---|---|
| T-PAS-1 | X entre 9,0 y 10,0 (escena 4) | Inicia `MEGA_02` |
| T-PAS-2 | X entre 14,0 y 18,0 (escena 4) | Activa el reflejo retardado de C02 durante 3 s |

### A.4 Archivo (A)

**Interior** (tras abrir la puerta con el puzle 1)

| ID | Objeto | Posición | Interacción | Contenido |
|---|---|---|---|---|
| A02 | Estanterías | Muro oeste (X = 6,6), Z −5,0 … −2,0 | Inspeccionar cajas (3) | Textos de relleno: «Procedimientos 2019 (incompletos)», «Acuerdos de confidencialidad», «Equipo anterior · actas». |
| A03 | Caja de cartón del traslado | Suelo (7,0; −4,6), 0,50 × 0,40 × 0,30 | Abrir tapa | `cerrada` → `abierta` |
| A04 | Formulario de traslado | Dentro de A03 | Leer (2 s) | Genera `formulario_leido` y el item I-04 |
| A05 | Cajón del escritorio viejo | Escritorio (9,0; −3,6), 1,20 × 0,60, cajón inferior | Abrir | `cerrado` → `abierto`. Contiene I-02 y I-03. |
| A06 | Papelera | (6,8; −1,9) | Inspeccionar | Papel triturado (relleno) |

**Texto del formulario (A04):**

> SOLICITUD DE TRASLADO INTERNO
> Nombre: Vera
> Unidad origen: Equipo Anterior
> Unidad destino: Proyectos Nuevos
> Motivo: Reasignación
> Firma: [firma manuscrita]
> Fecha: hace nueve días

**Iluminación:** un tubo fluorescente con parpadeo irregular (dos parpadeos cada 20 s). Sin otras fuentes.

### A.5 Sala de Reuniones (B)

**Mobiliario**

| ID | Objeto | Posición | Tamaño (X × Z × Y) | Notas |
|---|---|---|---|---|
| B-MOB-1 | Mesa de reuniones | (15,0; 3,6) | 3,20 × 1,20 × 0,75 | Eje largo en X |
| B-MOB-2 | Sillas (6) | Alrededor de la mesa | 0,50 × 0,50 × 0,90 | Una de ellas volcada (B07) |

**Objetos interactuables**

| ID | Objeto | Posición | Interacción | Estados |
|---|---|---|---|---|
| B01 | Lámpara L (izquierda) | Mesa (13,4; 4,0; Y 0,75) | Girar (CLICK en la base) | `pos` 1 a 4. Inicial: 2. |
| B02 | Lámpara C (central) | Mesa (15,0; 4,0; Y 0,75) | Girar | `pos` 1 a 4. Inicial: 2. |
| B03 | Lámpara R (derecha) | Mesa (16,6; 4,0; Y 0,75) | Girar | `pos` 1 a 4. Inicial: 2. |
| B04 | Ventanal con memorando | Muro norte (Z = 6,3), X 11,5 … 18,5, Y 0,0 … 2,6 | Puzle 2 | Fragmentos F1, F2, F3 y sello |
| B05 | Nota | Bajo la base de la lámpara C | Leer (siempre disponible) | `NOTA_02` |
| B06 | Reloj de pared | Muro este (18,45; 3,0; Y 2,2) | Inspeccionar | Marca 00:40 en la escena 4 |
| B07 | Silla volcada | (17,2; 2,6) | Inspeccionar | Relleno |
| B08 | Marcas del suelo | Arcos de 4 marcas numeradas (1 a 4) a 1,0 m de cada lámpara | Visibles siempre | Decals del suelo |

**Iluminación:** lámparas en ámbar (2200 K), encendidas en posición 2 al inicio. Fluorescentes apagados. Luz fría de la ventana (lluvia).

**Audio:** zumbido de las lámparas (2 dB). Goteo de la lluvia en el ventanal. Hum de vidrio al iluminar un fragmento (`SFX_GLASS_HUM`).

### A.6 Despacho del Guardián (D)

**Mobiliario**

| ID | Objeto | Posición | Tamaño (X × Z × Y) | Notas |
|---|---|---|---|---|
| D-MOB-1 | Escritorio | (22,5; 4,6) | 1,40 × 0,70 × 0,75 | Pegado al muro norte |
| D-MOB-2 | Silla | (22,5; 3,8) | 0,55 × 0,55 × 0,95 | Orientada al sur |
| D-MOB-3 | Perchero | (19,8; 4,6) | Altura 1,85 | Con el abrigo |
| D-MOB-4 | Estantería baja | Muro este (X = 24,35), Z 2,0 … 3,2 | 0,40 × 1,20 × 0,80 | Libros de procedimientos (relleno) |

**Objetos interactuables**

| ID | Objeto | Posición | Interacción | Estados / notas |
|---|---|---|---|---|
| D01 | Caja de madera (nogal) | Escritorio (22,4; 4,9; Y 0,75), 0,50 × 0,30 × 0,20 | Ver B.3 a B.6 | Cuatro compartimentos: D01a, D01b, D01c, D01d |
| D02 | Abrigo mojado | Perchero | Inspeccionar | Gotea a 2 gotas por segundo. Solo inspección. |
| D03 | Taza | Escritorio (22,9; 4,6) | Inspeccionar | Texto: «Café frío. Lo dejó a las siete». |
| D04 | Marco de foto | Muro oeste (X = 19,55; Z 3,0; Y 1,5), 0,50 × 0,40 | Inspeccionar | Foto del equipo con Vera al margen. Usada en el puzle 5. |
| D05 | Cajón | Escritorio (21,8; 4,6; Y 0,4) | Abrir | Vacío salvo un bolígrafo rojo (relleno) |
| D06 | Lector de tarjeta D | Muro sur, (22,2; Y 1,1) | Pasar I-03 | Ver C07 |

**Iluminación:** lámpara de escritorio en 2700 K. Luz de techo apagada. Luz fría de la ventana norte.

**Audio:** lluvia fuerte en el ventanal. Goteo del abrigo.

### A.7 Recepción (escena 8)

**Geometría:** 8,0 × 6,0 × 3,2. Las puertas del ascensor están en el muro sur, X 3,0 … 5,0. La puerta de salida, en el muro norte (Z = 6,0), X 3,6 … 4,4, aparece cerrada y no es interactuable en el slice.

| ID | Objeto | Posición | Interacción | Notas |
|---|---|---|---|---|
| R01 | Libro de visitas | Atril (4,0; 2,0; Y 1,1) | Pasar página (`ANIM_PAGE_TURN`) | Página 1: entrada de hoy. Página 2: entrada de hace nueve días. |
| R02 | Mostrador vacío | (6,5; 4,5) | Inspeccionar | Relleno |
| R03 | Ventanal | Muro este (X = 8,0), Y 0,9 … 2,8 | Ninguna | La lluvia cesa durante el trayecto del ascensor |

**Textos del libro de visitas:**

- Página 1: «23:40 · Vera · Planta 9 · Puesta al día»
- Página 2: «22:12 · Vera · Planta 9 · —»

**Iluminación:** fluorescentes fríos (6500 K), dos tubos. Uno parpadea una vez al entrar.

---

## Anexo B · Puzles (especificación)

**Convenciones**

- **Estados de puzle:** `BLOQUEADO`, `ACTIVO`, `RESUELTO`. Al resolverse, cada puzle emite `EV_PUZZLE_SOLVED_<ID>`.
- **Entradas:** `CLICK`, `ARRASTRAR`, `ROTAR` (arrastre horizontal: 1 píxel ≈ 0,25°), `PULSAR`.
- **Tiempos:** en segundos.
- **Sonidos y animaciones:** IDs listados en B.8.
- **Dependencias de la caja:** el compartimento 3 requiere el 1. El compartimento 4 requiere el 1, el 2 y el 3. El compartimento 2 no tiene dependencias.

### B.1 Puzle 1 · Cronología

- **Ubicación:** C05, en el pasillo, junto a la puerta del Archivo.
- **Acceso:** `ACTIVO` desde el inicio. Para resolverlo hace falta I-01 (impresión de correos).
- **Obtención de I-01:** en V08, imprimir tras haber abierto la búsqueda de «transición» (`correos_leidos = verdadero`). El papel incluye las cuatro referencias y los dos correos sin numerar.

**Contenido de la impresión (I-01)**

| Ref. | Día | Cuerpo | Pie |
|---|---|---|---|
| 1 | Lunes | «Traslado de Vera: pendiente de tu confirmación. — G.» | Enviado: 11:40 |
| 2 | Lunes | «Vera, ¿te viene bien que lo hablemos esta semana? — G.» | Enviado: 09:14 |
| 3 | Lunes | «Solicitud registrada a nombre de Vera. Yo me encargo del resto. — G.» | Enviado: 16:02 |
| 4 | Martes | «Vera ya figura en la unidad nueva. — Dirección» | Enviado: 08:55 |
| — | Lunes | Recordatorio de cambio de extensiones | Enviado: 10:30 |
| — | Martes | Aviso de mantenimiento del aire acondicionado | Enviado: 14:00 |

El orden de impresión es 3, 1, 4, 2, con los dos correos sin numerar intercalados. El pie de la impresión dice «Ordena por hora de envío».

**Interfaz**

- Cuatro huecos H1 a H4 en fila.
- `CLICK` en una referencia del papel y después en un hueco la coloca. Si la referencia ya estaba en otro hueco, se mueve. `CLICK` en un hueco lleno devuelve la referencia al papel.

**Verificación**

- Se comprueba 0,6 s después de la última inserción, cuando H1 a H4 están llenos.

**Solución**

- H1 = 2, H2 = 1, H3 = 3, H4 = 4.

**Resultado**

- Éxito: `SFX_UNLOCK` (1,4 s) y `ANIM_DOOR_OPEN` en la puerta A. Se activa `archivo_abierto`. Estado: `RESUELTO`.
- Fallo: los cuatro huecos vibran 1,2 s (`SFX_REJECT`). A los 1,5 s, las referencias vuelven al papel. Sin penalización.

**Pistas**

1. Nivel 1: gesto de cámara hacia la impresión, 3 s.
2. Nivel 2: el pie de la impresión muestra «Ordena por hora de envío».
3. Nivel 3: la hora de envío aparece en letra pequeña al pie de cada correo.

### B.2 Puzle 2 · Memorando en el cristal

- **Ubicación:** B01, B02 y B03 (lámparas), B04 (ventanal).
- **Acceso:** puerta B. Requiere `tarjeta_B` (I-02) en el lector C06. Estado: `ACTIVO` al entrar en la sala.
- **Entrada:** `CLICK` en la base de una lámpara avanza su posición de 1 a 4 y vuelve a 1 tras el 4.

**Mapeo de apuntado**

Cada posición de cada lámpara apunta a un punto del cristal. Solo un punto por lámpara contiene un fragmento.

| Lámpara | Pos. 1 | Pos. 2 | Pos. 3 | Pos. 4 |
|---|---|---|---|---|
| L (B01) | Vacío | Sello de Dirección (distractor) | **F1** | Vacío |
| C (B02) | **F2** | Vacío | Vacío | Vacío |
| R (B03) | Vacío | Vacío | Vacío | **F3** |

**Fragmentos**

- **F1:** «Traslado de Vera: aprobado a petición de la interesada.»
- **F2:** «Ratificación pendiente»
- **F3:** «de firma del responsable.»

El texto está escrito en espejo sobre una película del cristal. El haz de la lámpara lo hace legible en el reflejo.

**Verificación**

- Se comprueba con cada cambio de posición. Un fragmento se hace visible cuando su lámpara apunta a él (fundido de 0,8 s).

**Solución**

- L = 3, C = 1, R = 4. Con esta combinación, F1, F2 y F3 son visibles a la vez.

**Resultado**

- Éxito: se activa `memo_leido`. El memorando completo queda legible. `SFX_GLASS_HUM` (2,0 s). Estado: `RESUELTO`.
- Fallo: no existe. Si las lámparas apuntan a puntos vacíos, simplemente no se revela nada.

**Pistas**

1. Nivel 1: al pulsar «pista», se muestra durante 2 s el texto de F1 en espejo. Texto: «El memorando está escrito en espejo. Un haz lo muestra mejor que la luz directa».
2. Nivel 2: las marcas numeradas del suelo (B08) indican las cuatro posiciones de cada lámpara.
3. Nivel 3: al acercar la cámara a una lámpara, su haz se marca con un halo en el cristal. Muestra el punto actual, no la posición correcta.

### B.3 Puzle 3 · Encaje de la foto (compartimento D01a)

- **Acceso:** `ACTIVO` al entrar en D. `PULSAR` sobre D01a abre el compartimento (`BOX_C1_OPEN`, 1,6 s).
- **Contenido de la foto de la caja:** el Guardián en el centro (S1), cuatro compañeros en S2 a S5. S6 es el hueco de Vera, que no tiene pieza.

**Elementos**

- Marco con seis huecos en tres filas: S1 S2 / S3 S4 / S5 S6.
- Cinco piezas P1 a P5. Cada una tiene una silueta propia y un número de fila en el borde.

**Solución**

| Pieza | Hueco |
|---|---|
| P1 | S1 |
| P2 | S2 |
| P3 | S3 |
| P4 | S4 |
| P5 | S5 |

S6 queda vacío.

**Mecánica**

- Al abrir la tapa, la cámara se acerca y se bloquea a 0,35 m del marco (1,0 s). Vista de cierre.
- `ARRASTRAR` una pieza. Al soltarla, si está a 0,04 m o menos del hueco correcto (en coordenadas del marco), encaja con `SFX_SNAP` (0,2 s).
- Si no encaja, vuelve a la bandeja en 0,4 s (`SFX_REJECT`).
- Un hueco ocupado no acepta otra pieza. S6 rechaza cualquier pieza.

**Verificación**

- Al encajar la quinta pieza.

**Resultado**

- Éxito: `caja_c1` pasa a verdadero. El marco se ilumina 1,0 s. El compartimento se cierra. En la bandeja aparece I-06a (`NOTA_01`). Estado: `RESUELTO`.

**Accesibilidad**

- Opción «asistencia de encaje»: radio de encaje de 0,10 m.

**Pistas**

1. Nivel 1: se ve la silueta de cada hueco.
2. Nivel 2: mantener `PULSAR` 0,5 s sobre una pieza muestra su número de fila.
3. Nivel 3: tras 60 s sin movimiento, el hueco correcto de la pieza sostenida se marca con un contorno.

### B.4 Puzle 4 · Tablero de tareas (compartimento D01b)

- **Acceso:** `ACTIVO` al entrar en D. `PULSAR` sobre D01b abre el compartimento (`BOX_C2_OPEN`, 1,4 s).
- **Elementos:** cuatro fichas T1 a T4. Cada ficha tiene dos selectores (Urgencia: Alta, Media, Baja; Responsable: Vera, Guardián, Dirección) y un botón «Devolver». Al elegir «Devolver», los selectores se desactivan.

**Textos de las fichas**

| Ficha | Descripción |
|---|---|
| T1 · Cliente Lima | «Revisión antes del jueves. Ya la tiene asignada Vera.» |
| T2 · Revisión de contrato | «Lleva tres semanas parada. Solo puede firmarla quien dirigía el equipo anterior.» |
| T3 · Mudanza del archivo | «Sin fecha. Requiere aprobación de Dirección.» |
| T4 · Carta a Dirección | «Explicar a Dirección la solicitud de traslado en nombre de la interesada.» (Nombre tachado y reemplazado por «G».) |

**Solución**

| Ficha | Urgencia | Responsable | Acción |
|---|---|---|---|
| T1 | Alta | Vera | Aceptar |
| T2 | Media | Guardián | Aceptar |
| T3 | Baja | Dirección | Aceptar |
| T4 | — | — | Devolver |

**Verificación**

- Cada ficha se evalúa cuando tiene sus dos selectores completos o el botón «Devolver» activo.

**Resultado por ficha**

- Correcta: sello «ACEPTADA» o «DEVUELTA» (`SFX_STAMP`). La ficha queda bloqueada.
- Incorrecta: la ficha vuelve a neutra (`SFX_REJECT`) y aparece «No corresponde» durante 1,5 s. Las fichas correctas no se reinician.

**Resultado del compartimento**

- Cuando T1 a T4 están bloqueadas como correctas: `caja_c2` pasa a verdadero. Aparece I-05 (lista de tareas del Guardián). Estado: `RESUELTO`.

**Sin temporizador:** una ficha sin decidir permanece en la mesa.

**Pistas**

1. Nivel 1: la regla del tablero es visible en todo momento: «Acepta lo que tiene urgencia y responsable. Devuelve lo que no te corresponde».
2. Nivel 2: la descripción de la ficha se resalta al pasar el cursor.
3. Nivel 3: T1 se resuelve sola y muestra su explicación: «La urgencia sigue al plazo; el responsable, a quien ya lleva el caso».

### B.5 Puzle 5 · Espejo de la diferencia (compartimento D01c)

- **Acceso:** `BLOQUEADO` hasta `caja_c1`. Al desbloquearse, el compartimento se entreabre 2 cm (`SFX_UNLOCK_SOFT`).
- **Elementos:** marco interior giratorio con superficie reflectante. Ángulo θ de 0° a 90°. Marcas cada 5°.
- **Entrada:** `ROTAR`.

**Solución**

- θ = 40° ± 3° (tolerancia normal) o ± 6° (asistido).

**Verificación**

- Si |θ − 40| ≤ tolerancia durante 0,8 s seguidos, se inicia la revelación.

**Revelación**

1. La superficie refleja la foto de D04 superpuesta sobre la foto de la caja (puzle 3 ya completo).
2. Fundido de 1,2 s.
3. La silueta de Vera, presente solo en la foto de D04, se resalta con un contorno.
4. Reproduce `VO_G_07` (unos 14 s) desde un altavoz del compartimento.
5. Al terminar: `caja_c3` pasa a verdadero. Estado: `RESUELTO`.

**Resultado**

- No hay fallo. Si el jugador se aleja de la caja durante la revelación, queda `pendiente_revelacion` y se completa al volver.

**Pistas**

1. Nivel 1: «El reflejo muestra algo que la foto de la caja no muestra».
2. Nivel 2: «Compara las dos fotos con atención».
3. Nivel 3: la marca de 40° del marco se ilumina.

### B.6 Puzle 6 · Decisión (compartimento D01d)

- **Acceso:** `BLOQUEADO` hasta `caja_c1`, `caja_c2` y `caja_c3`.
- **Elementos:** tres botones: A («Estoy bien»), B («La verdad») y C («Todavía no»). Cada uno fija `carta_variante`.
- **Entrada:** `PULSAR`, una sola vez. Al pulsar, los otros dos botones se bloquean.

**Efecto**

1. `SFX_LOCK_CLICK` (0,3 s).
2. La tapa se abre (1,6 s).
3. Aparece la carta: primera línea según la variante (`CARTA_A`, `CARTA_B` o `CARTA_C`) y cuerpo (`CARTA_CUERPO`).
4. La carta se guarda como I-07.

**Resultado**

- `carta_variante` queda fijada. `caja_c4` pasa a verdadero. Si `caja_c1` a `caja_c4` son verdaderos, `caja_completa` pasa a verdadero. Estado: `RESUELTO`.
- No hay fallo.

**Pistas**

1. Tras 10 s sin pulsar: «Solo puedes elegir una vez».
2. Tras 20 s sin pulsar: «La carta no cambia; cambia la primera frase».

### B.7 Índice de sonidos y animaciones

| ID | Uso |
|---|---|
| `SFX_SLIDE_OK` | Inserción correcta en un hueco del puzle 1 |
| `SFX_SLOT_IN` | Referencia colocada en un hueco |
| `SFX_UNLOCK` | Apertura de una puerta por puzle |
| `SFX_UNLOCK_SOFT` | Desbloqueo de un compartimento |
| `SFX_REJECT` | Error en cualquier puzle |
| `SFX_GLASS_HUM` | Fragmento iluminado en el cristal |
| `SFX_SNAP` | Pieza encajada |
| `SFX_STAMP` | Ficha aceptada o devuelta |
| `SFX_LOCK_CLICK` | Pulsación en la cerradura de decisión |
| `SFX_CLICK_SUBTLE` | Interacción sin efecto (relleno) |
| `SFX_PHONE_BUZZ` | Vibración del teléfono |
| `SFX_PHONE_END` | Fin de la llamada |
| `SFX_BREATH_BROKEN` | Llanto contenido tras 20 s sin respuesta |
| `ANIM_DOOR_OPEN` | Apertura de puerta (1,2 s) |
| `BOX_C1_OPEN` … `BOX_C4_OPEN` | Apertura de cada compartimento |
| `ANIM_PHONE_PICKUP` | Descolgar (0,8 s) |
| `ANIM_PAGE_TURN` | Pasar página del libro de visitas |

---

## Anexo C · Eventos y tiempos

### C.1 Escena 1 · Llegada

| t (s) | Evento |
|---|---|
| 0,0 | Fundido desde negro (2,0 s). Ventilador en bucle. |
| 1,5 | `VO_V_01` (unos 8 s) |
| 6,0 | `MEGA_01` desde C01 |
| 12,0 | V02 vibra (`SFX_PHONE_BUZZ`, 3 pulsos de 1 s). Aparece en pantalla el mensaje «¿Jugamos esta noche?». |
| 14,0 | Opciones: «Ahora no». Al pulsar, sale el mensaje «Ahora no». |
| +1,0 tras el mensaje | «Este número ya no está disponible». |

### C.2 Escena 2 · Correo

- Al escribir «transición», los resultados aparecen tras 0,4 s.
- Al mostrarse el primer resultado, se activa `correos_leidos`.
- El botón «Imprimir» (V08) se habilita al mismo tiempo.
- Resultados en orden visual: 3, 1, 4 y 2, con los dos distractores entre ellos.

### C.3 Escena 3 · Archivo

1. Resolver el puzle 1 → `ANIM_DOOR_OPEN` (1,2 s).
2. Entrar. Inspeccionar A03 → abrir la tapa.
3. Leer A04 (2 s) → `formulario_leido`.
4. Abrir A05 → recibir I-02 e I-03.

### C.4 Escena 4 · Pasillo (00:40)

| Evento | Disparador | Acción |
|---|---|---|
| Megafonía | T-PAS-1 | `MEGA_02` desde C01 |
| Parpadeo | T-PAS-1, t + 2,0 | C03 parpadea 3 veces (0,15 s cada vez) |
| Reflejo retardado | T-PAS-2 | C02 muestra el reflejo del jugador con retardo de 0,6 s durante 3 s |

### C.5 Escena 5 · Sala de Reuniones

- Al entrar, las lámparas están en posición 2 y el cristal está vacío.
- Al completarse el puzle 2: `SFX_GLASS_HUM` (2,0 s). `DOC_01` aparece legible.
- A los 1,0 s tras el memorando completo: `VO_V_08` (unos 6 s).

### C.6 Escena 6 · Despacho del Guardián

- Al abrir cada compartimento se muestra su recompensa:
  - D01a: `NOTA_01` en la bandeja.
  - D01b: I-05.
  - D01c: `VO_G_07` (unos 14 s) tras la revelación.
  - D01d: I-07 (la carta).

### C.7 Escena 7 · Apagón y llamada

| t (s) | Evento |
|---|---|
| 0,0 | Al cruzar el umbral de D con `caja_completa`: fundido de C03 en el pasillo y en D (0,4 s). La lámpara V06 del despacho de Vera sigue encendida. |
| 1,0 a 4,0 | Sillas rodando desde el Archivo hacia el pasillo (sonido 3D, sin imagen). |
| 4,5 | Tecleo lejano (3 s). |
| Al entrar en el despacho de Vera | V02 suena (`SFX_PHONE_BUZZ`). Si el jugador no entra en 60 s, el teléfono se oye desde el pasillo. El juego espera en el despacho. |
| Al pulsar V02 | `ANIM_PHONE_PICKUP` (0,8 s). Silencio de 2,0 s. Respiración de 2,0 s. |
| +4,0 | Línea de variante: `VO_G_12A`, `VO_G_12B` o `VO_G_12C` (unos 5 s). |
| +1,0 tras la línea | Aparecen las opciones: «Estoy bien», «Estoy desbordada», «No quiero hablarlo ahora» y «No responder». |
| +20,0 sin elegir | `SFX_BREATH_BROKEN` (4 s) y `VO_G_14`: «Sigo aquí». Las opciones siguen visibles. No hay elección automática. |
| Al elegir | Se reproduce la línea de respuesta (`VO_G_13A` a `VO_G_13D`). Se guarda `respuesta_llamada`. |
| +1,0 tras la respuesta | `SFX_PHONE_END`. Se activa `llamada_completada`. |
| +2,0 | C03 se restablece (2,0 s). Vuelve la lluvia. Se activa C08 (ascensor). |

### C.8 Escena 8 · Recepción

| t (s) | Evento |
|---|---|
| 0,0 | Trayecto en ascensor (6,0 s). Fundido de la lluvia durante el trayecto. |
| 6,0 | Puertas abiertas. R01 disponible. |
| Al pasar página | `ANIM_PAGE_TURN`. Muestra la página 2. |
| +3,0 tras leer | Línea de Vera según `respuesta_llamada` (`VO_V_12A` a `VO_V_12D`). |
| +3,0 | `VO_V_12E`: «La V no me convence». |
| +2,0 | Fundido a negro. Título (3 s). Rótulo «Continuará». |

---

## Anexo D · Inventario, banderas e índice

### D.1 Ítems

| ID | Nombre | Origen | Notas |
|---|---|---|---|
| I-01 | Impresión de correos | V08 (impresora) | Requiere `correos_leidos`. Contiene las referencias del puzle 1. |
| I-02 | Tarjeta de la Sala de Reuniones | A05 (cajón) | Llave de B (C06) |
| I-03 | Tarjeta sin foto | A05 (cajón) | Llave de D (C07) |
| I-04 | Formulario de traslado | A03 (caja) | Lectura en A04 |
| I-05 | Lista de tareas del Guardián | D01b (puzle 4) | Con el nombre de Vera tachado |
| I-06a | Nota «La transición es tuya» | D01a (puzle 3) | `NOTA_01` |
| I-06b | Nota «No te quites la carga. Yo tampoco» | B05 | Lectura in situ. No es ítem. |
| I-07 | Carta de Vera | D01d (puzle 6) | Según `carta_variante` |

Vera lleva los ítems en un bolsillo visual. No hay menú de inventario en el slice.

### D.2 Banderas

| Flag | Tipo | Inicial | Se activa en | Se usa en |
|---|---|---|---|---|
| `correos_leidos` | bool | falso | Escena 2 | V08, puzle 1 |
| `archivo_abierto` | bool | falso | Puzle 1 | Puerta A |
| `formulario_leido` | bool | falso | A04 | Pistas de la escena 3 |
| `tarjeta_B` | bool | falso | A05 | C06 |
| `tarjeta_D` | bool | falso | A05 | C07 |
| `memo_leido` | bool | falso | Puzle 2 | Pistas, recompensa de B |
| `pos_L`, `pos_C`, `pos_R` | int (1 a 4) | 2 | Puzle 2 | Puzle 2 |
| `caja_c1` | bool | falso | Puzle 3 | Dependencias de c3 y c4 |
| `caja_c2` | bool | falso | Puzle 4 | Dependencia de c4 |
| `caja_c3` | bool | falso | Puzle 5 | Dependencia de c4 |
| `caja_c4` | bool | falso | Puzle 6 | `caja_completa` |
| `pendiente_revelacion` | bool | falso | Puzle 5 (si se interrumpe) | Puzle 5 |
| `caja_completa` | bool | falso | Puzle 6 | Apagón y llamada |
| `carta_variante` | enum (A, B, C) | — | Puzle 6 | Escena 7 |
| `llamada_iniciada` | bool | falso | Escena 7 | Evita repetir la llamada |
| `respuesta_llamada` | enum (A, B, C, D) | — | Escena 7 | Escena 8 |
| `llamada_completada` | bool | falso | Escena 7 | C08 (ascensor) |

### D.3 Guardado

- Automático al abrir cualquier puerta, al completar cada compartimento y al iniciar la llamada.
- Al cerrar durante la llamada, se reanuda en el despacho con la llamada pendiente (`llamada_iniciada` verdadero, `llamada_completada` falso).
- Al cerrar durante la revelación del puzle 5, se reanuda con `pendiente_revelacion` verdadero.

### D.4 Índice de IDs

| Prefijo | Significado | Ejemplo |
|---|---|---|
| V | Despacho de Vera | V02 (teléfono) |
| A | Archivo | A04 (formulario) |
| B | Sala de Reuniones | B02 (lámpara C) |
| D | Despacho del Guardián | D01a (compartimento 1) |
| R | Recepción | R01 (libro) |
| C | Pasillo y elementos comunes | C05 (panel del puzle 1) |
| I | Ítem | I-01 (impresión) |
| T | Disparador de zona | T-PAS-1 |
| VO | Voz | `VO_G_12A` |
| SFX / ANIM | Sonido y animación | `SFX_UNLOCK` |

---

## 24. Historial de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| 0.3 | 2026-11-08 | Añadidos los anexos A (espacios), B (puzles), C (eventos y tiempos) y D (inventario, banderas e índice). Ajustes en v0.2: la impresión de correos sustituye a la búsqueda como fuente de referencias; el silencio en la llamada pasa a ser el botón «No responder» y no hay elección automática a los 20 s; se elimina el temporizador de la ficha «Carta a Dirección». Decisiones D-14 a D-16. |
| 0.1 | 2026-11-08 | Creación del documento a partir del guion del turno de noche. |
| 0.2 | 2026-11-08 | Eliminada la Sala de Juegos (E). Eliminado el despacho de Dirección como sala. El memorando pasa al cristal de la Sala de Reuniones. Puzle 1 cambiado a cronología con cuatro correos y solución `2·1·3·4`. Puzle 2 con lámparas ligadas a fragmentos del memorando. Puzle 3 cambiado a encaje de foto con hueco vacío. Puzle 4 con fichas que se deducen de su descripción. Puzle 5 con espejo que revela la diferencia en la foto. Puzle 6 con variantes que cambian la llamada. Llamada con primera línea según la carta y última línea de Vera según la respuesta. Añadida la línea temporal (sección 9). Actualizados flags, assets, criterios y decisiones. |
