# Escena de planta y carga de Recepción

> **Status**: Revisado (ronda 2) — pendiente de re-review
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-08
> **Implements Pillar**: Tensión sin castigo (reanudar sin perder ni repetir progreso) · El espacio expresa la emoción (planta continua y legible)

## Summary

Es el sistema que construye el espacio del slice y lo deja listo para jugar: la planta 9 como una única escena continua (despacho, pasillo, tres salas y el hueco del ascensor) y Recepción como escena aparte que la sustituye tras la llamada con un fundido de 0,8 s. Garantiza que cualquier carga —primer arranque, partida nueva o partida guardada— termine con el jugador en el despacho y cada elemento reflejando sus hechos, sin pantallas de carga ni escenas a medias. Existe para sostener *Tensión sin castigo* en lo técnico (reanudar nunca repite ni pierde progreso) y para separar quién pone el espacio de quienes lo llenan.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `3 Estado y bus de eventos` (dura) · `2 Jugador en primera persona` (dura) · `1 Entrada y controles`, `6 Ajustes` (blandas)

## Overview

Escena de planta y carga de Recepción construye el espacio donde transcurre el slice y lo deja listo para jugar. La planta 9 es **una única escena continua** —Despacho de Vera, pasillo de 24 m, Archivo, Sala de Reuniones, Despacho del Guardián y el hueco del ascensor— cuyas puertas son disparadores, no cargas: el jugador recorre el edificio sin ver nunca una carga. Recepción es una **escena aparte** que sustituye a la planta tras la llamada, con un fundido de 0,8 s. El sistema fija la geometría y las medidas de referencia (Anexo A del slice), los puntos de aparición, el orden de arranque (hechos listos, escena instanciada, elementos configurados, «escena lista») y el cambio entre la planta y Recepción.

No es una pantalla ni lo opera el jugador; lo que nota es que el mundo está siempre en el estado que cuentan los hechos y que nunca ve una escena a medias. Cualquier carga —primer arranque, partida nueva o partida guardada— termina con el jugador en el despacho y cada elemento del espacio (puertas, tarjetas, puzles, lámparas) reflejando el valor actual de sus hechos.

Existe por dos razones. La primera es el pilar *Tensión sin castigo*: reanudar, cerrar y volver a abrir el juego nunca repite ni pierde progreso, porque el espacio se reconstruye desde los hechos y no desde lo que ocurrió en la sesión anterior. La segunda es separar responsabilidades: este sistema pone el espacio y garantiza su arranque; los inquilinos —control de acceso (8), puzles (9 a 16), documentos (20), director de escenas (21)— ponen lo que contiene y lo que ocurre en él. En el MVP la geometría es gris; la capa visual llega con los sistemas 28 y 29.

## Detailed Design

### Core Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado (todavía sin redactar); † = valor propuesto, a validar en el prototipo gris o en playtest. Los nombres de nodos y anclas son identificadores de código (inglés); los IDs del slice (`V01`, `T-PAS-1`…) se conservan tal cual.

**Qué escenas hay**

1. **Dos escenas, una activa cada vez:** `planta` y `recepcion`. Nunca están cargadas a la vez. Los sistemas 1 (Entrada), 3 (Estado), 6 (Ajustes) y 23 (Audio) no pertenecen a ninguna de las dos: sobreviven a los cambios de escena y no se reinician por ellos.
2. **Las medidas son las del Anexo A del slice**, que prevalece en caso de discrepancia (A.0 convenciones, A.1 envolvente, A.2 a A.6 espacios de la planta, A.7 Recepción). Este GDD no copia sus tablas; fija solo lo que ellas no dicen. Se recuerdan las que condicionan reglas: metros; X de oeste a este, Z de sur a norte, Y del suelo al techo; origen (0, 0, 0) en el centro del umbral del Despacho de Vera, en la cara del pasillo; techo de 2,70 m (Recepción, 3,20 m); puertas con hueco de 1,00 × 2,10 m.
3. **La planta es una escena continua.** Despacho de Vera, pasillo, Archivo (A), Sala de Reuniones (B), Despacho del Guardián (D) y el hueco del ascensor conviven en la misma escena; ninguna puerta provoca una carga. La planta aporta el hueco y un ancla de puerta (`door_slot_a`, `door_slot_b`, `door_slot_d`) y `door_slot_elevator` (hueco de C08 en el contenedor `corridor`, X 1,4 a 2,6, muro norte, 1,2 m de ancho; la cabina de la planta es externa al edificio y no se modela); la puerta, el lector y su comportamiento —incluidos la puerta y el disparador del ascensor— los pone Control de acceso (8) ‡, y qué responde el ascensor lo decide el director de escenas (21) ‡.
4. **Cada espacio es un contenedor con nombre** (`office`, `corridor`, `archive`, `meeting_room`, `guardian_office`, y `reception` en la otra escena) que agrupa geometría y elementos. Los elementos conservan los IDs del slice con el prefijo del Anexo D.4, de modo que cualquier sistema localiza un elemento por su ID. Cada prefijo vive en un contenedor fijo: `V` → `office`, `A` → `archive`, `B` → `meeting_room`, `D` → `guardian_office`, `C` y `T` → `corridor`, `R` → `reception`.
5. **Zonas disparadoras.** La planta aloja los volúmenes `T-…` del Anexo D.4 (A.3 define `T-PAS-1` y `T-PAS-2`) como detectores puros: cuando el jugador entra en uno, se emite el aviso «zona activada» con su ID. Un volumen no tiene lógica ni lee hechos; qué ocurre lo decide quien escucha (Director de escenas 21, Atmósfera 28, Audio 23) ‡. Se emite en **cada** entrada: quien escucha decide, con sus hechos, si ya ocurrió (regla 3 del GDD del 3). Al aparecer, el jugador nunca está dentro de un `T-…` (`spawn_office` está en el despacho y las zonas en el pasillo): el caso «aparecer dentro de una zona» es una defensa solo por datos de prueba (Edge Cases).
6. **Este sistema no escribe hechos y solo lee uno: `llamada_completada`**, únicamente para la precondición de la regla 13 (red de seguridad contra un softlock); no lee ningún otro. Cada elemento con estado (puerta, ficha, lámpara, objeto recogible) lee sus propios hechos al configurarse (regla 9, paso 6). Lo único que exige este sistema es el orden: los hechos están definitivos antes de que se instancie la escena.

**Cómo se pide y se arranca una carga**

7. **Petición.** Una carga se pide con tres datos: `destino` (`planta` o `recepcion`), `motivo` (`partida_nueva`, `reanudar` o `recepcion`) y `control_final` (`exploracion` o `ninguno`). La piden: **Guardado (5)** la partida nueva (`partida_nueva`, desde `nueva_partida()`) y la reanudación (`reanudar`, desde `continuar()`); Pantalla de título (27) solo llama a esas dos operaciones de 5 y **no pide `planta`**; el Director de escenas (21) pide la Recepción ‡. Valores por defecto de `control_final` ‡: `partida_nueva` → `ninguno` (la escena 1 dirigida la devuelve 21); `reanudar` → `exploracion`; `recepcion` → `ninguno`. **Precondición:** el estado (3) está en «Listo» y fuera de una restauración, y los hechos ya valen lo que deben (tras «estado restablecido» o «estado restaurado»). Si no se cumple, la petición se rechaza: en desarrollo, error visible que detiene la ejecución; en la build final, se rechaza y se registra una línea. Una petición mientras hay una carga en curso se rechaza igual.
8. **Recarga completa.** Cada petición de `planta` descarta la instancia anterior, si la hay, y crea otra nueva; nunca se reutiliza una escena cargada, para que nada de una sesión se filtre a la siguiente.
9. **Secuencia de arranque** (la misma para las dos escenas):
   1. Se emite «carga de escena iniciada» (con el destino, el `motivo` y `D_carga`) ‡, **antes de tocar la cortina**. Se lee `reducir_movimiento` (regla 11).
   2. La cortina (regla 11) pasa a negro, si no lo estaba ya, y **los pasos 3 y 4 no empiezan hasta que es opaca por completo**; en ese instante arranca `t_espera` (F2).
   3. Se descarga la escena actual, si la hay.
   4. Se instancia la escena de destino.
   5. Se coloca al jugador (2) en su punto de aparición (regla 10).
   6. Cada elemento con estado se configura **leyendo sus hechos**, de forma síncrona en el mismo fotograma. El que necesite más tiempo toma una **retención** y la libera al terminar.
   7. Cuando no queda ninguna retención se emite «escena lista» (con el destino) ‡; audio y atmósfera arrancan aquí.
   8. La cortina se aclara.
   9. Al terminar el aclarado se emite «carga de escena terminada» ‡ y, si `control_final` es `exploracion`, se pide a Entrada (1) el contexto `exploración`.

   **Orden único** (vale para esta regla, la 12, F2, F3, el estado «Cargando» y la pausa): «iniciada» sale en el paso 1, con la cortina aún sin tocar. Desde ese aviso la pausa no se puede abrir (regla 7 del GDD de Entrada y controles) y Entrada mantiene `sin control`, hasta «terminada». **Quién abre el `sin control` de la carga: este sistema**, al emitir «iniciada» con `D_carga` (F3) como duración declarada ‡; así el tope de seguridad de Entrada (F8: duración declarada más un margen) no libera el control con la escena aún en negro. El reinicio de la pila a `sin control` al descargar (regla 6 y Edge Cases de Entrada) coincide con ese `sin control`: no lo sustituye ni lo acorta. Con `control_final` = `exploracion`, este sistema lo cierra pidiendo `exploración` en el paso 9. Con `ninguno`, el `sin control` de la carga se mantiene en «terminada» y el director de escenas (21) debe tomar el suyo en ese mismo fotograma ‡; el 21 no abre `sin control` en una carga por su cuenta.
10. **Puntos de aparición.** En la planta hay **uno solo**, `spawn_office`, en el Despacho de Vera, a ≈ 2,5 m del ordenador (V01, en (−4,4; −2,1), A.2) y mirando hacia él; posición propuesta (−3,0; 0,0) ‡†, con el yaw calculado desde el ancla hacia V01 (dirección ≈ (−0,56; −0,83) en X, Z). Vale para la partida nueva, para cualquier partida reanudada y para la llamada pendiente (slice D.3): el guardado no almacena posición. En Recepción hay uno, `spawn_elevator`, dentro de la cabina del ascensor (muro sur, X 3,0 a 5,0), mirando al norte. El jugador aparece con velocidad cero y la orientación del ancla; no hereda la de la escena anterior. El interior de la cabina no está definido en el slice (Open Questions).
11. **Cortina.** Es una capa negra opaca que cubre toda la pantalla, por encima del mundo y de la interfaz de juego (el único elemento por encima es el mensaje de error de la regla 14); la posee este sistema. Se oscurece y se aclara con las duraciones de la tabla de datos por `motivo` (F1): planta → Recepción, 0,8 s en ambos sentidos (slice A.0) ‡; partida nueva, aclarado de 2,0 s (slice C.1, fundido de entrada de la escena 1); reanudar, 0,8 s†. El oscurecido parte de la opacidad que haya en ese momento (desde el título, por ejemplo) y se salta si ya es total. **Reducir movimiento (decisión del usuario, 2026-11-09):** si la clave booleana `reducir_movimiento` de Ajustes (6) ‡ es verdadera, d_out y d_in valen 0,1 s para todos los `motivo` (fundido fijo de 100 ms, art bible §7.4), también en el aclarado de 2,0 s de la partida nueva; se lee en el paso 1 y no cambia durante esa carga. La cortina sigue existiendo (sigue siendo un fundido, no un corte). Otros sistemas no manejan la cortina; si el director de escenas necesita un fundido propio (el de cierre de la escena 8), lo pide a este sistema ‡.
12. **Espera en negro.** La cortina no empieza a aclararse hasta que se emite «escena lista». No hay pantalla de carga, barra ni mensaje durante la espera; el negro es el único feedback. El tiempo de espera (`t_espera`) se cuenta desde que la cortina es opaca (paso 2), en tiempo real, y **sigue avanzando sin el foco de la ventana** (F3: así el fallo se detecta antes de que Entrada libere el control); si alcanza el tope de F2, la carga se trata como fallo (regla 14).
13. **De planta a Recepción.** La pide el Director de escenas (21) cuando se cumple lo que dice el slice (§8 y escena 8): `llamada_completada` verdadero y el jugador activa el ascensor. Este sistema además comprueba la precondición: si `llamada_completada` es falso, rechaza la petición como dice la regla 7 (en desarrollo, error visible; en la build final, se rechaza y se registra), una red de seguridad contra un softlock del ascensor y no la regla de acceso. Se sigue la secuencia de la regla 9 con `control_final` = `ninguno`. La planta se descarga entera; no se vuelve a ella desde Recepción: el slice termina allí (título y «Continuará», a cargo de 21 y 27).
14. **Fallo de carga.** Un recurso ausente, una escena que no se puede instanciar o el tope de F2 superado es un fallo de carga. En desarrollo, error visible que detiene la ejecución. En la build final, la cortina se mantiene, se registra una línea, se muestra un mensaje de error claro y se vuelve al título (27) ‡; **nunca** se aclara una escena a medias.
15. **Descarga.** Al descargar una escena todo lo que contiene desaparece: sus suscriptores dejan de recibir avisos sin darse de baja y sin errores (GDD del 3), y Entrada reinicia su pila de contextos a `sin control` (GDD de Entrada, casos límite) hasta que se le pide otro. Existe además una petición de descarga total (volver al título) que deja el sistema en «Sin escena» con la cortina en negro ‡.
16. **El guardado no lo toca este sistema.** No guarda ni pide guardados. Mientras Recepción no esté cargada («terminada»), el último guardado es el de la llamada pendiente: un fallo de carga o un cierre durante la carga reanudan en el despacho (slice D.3). Decisión del usuario (2026-11-09): al llegar a Recepción la partida queda **sellada** y el título ofrece solo «Nueva partida»; quién sella y en qué aviso (propuesto: «terminada» de `recepcion`) lo definen 5 y 22 ‡ (en Guardado es la causa `slice_completed`, GDD 5 regla 29: la única admitida con la partida sellada). Qué ocurre con la llamada al reanudar lo define el sistema 22.
17. **Escena obsoleta.** Si llega «estado restablecido» o «estado restaurado» con una escena cargada y no se ha pedido una recarga, el sistema no intenta parchear los elementos: registra una advertencia (en desarrollo, error visible). Quien restaure (5) o reinicie (27) debe pedir la recarga después (regla 8).
18. **Contrato geométrico con el Jugador (2) y la Interacción (7)** (añadido 2026-11-09; el GDD 2 es la fuente de verdad del contrato 2↔7). (a) **Paso mínimo transitable = 0,60 m** (`player_min_passage_width_m`); la cápsula del Jugador es fija, `radio_capsula` = 0,25 m (`player_capsule_radius_m`); ningún hueco, pasillo ni separación entre mobiliario transitable mide menos. (b) **Las puertas desactivan la colisión de su hoja al empezar a abrirse** (D-19 del GDD 2); preferir que abran hacia el lado contrario al paso habitual. La colisión de la hoja con el Jugador es por tanto «dura» (cerrada) y «blanda» solo en el sentido de que se retira al abrir; esto sustituye a la redacción previa contradictoria («blanda de este lado» / «Dura»). (c) **Los volúmenes `T-…` detectan el sensor esférico del Jugador** (radio 0,02 a 0,05 m), no la cápsula; `T-PAS-1` se activa cuando el centro del sensor está entre X = 8,92 y X = 9,00. (d) **El suelo lleva una etiqueta de superficie** (`default` si falta), que el Jugador usa para los pasos. (e) **La cabina del ascensor de Recepción mide al menos 1,2 × 1,2 m** (restricción mínima; el hueco de A.7 es de 2,0 m, X 3,0 a 5,0; no cierra la Open Question 2). El hueco C08 de la planta (1,2 m) es solo la entrada; su cabina es externa y no se modela. (f) **Interacción (7):** los anclajes de vista son perpendiculares a su plano; el collider de `B05` cubre solo la parte que asoma de la base de la lámpara C, con ≥ 0,02 m de margen respecto del de `B02`; 7 toma la retención de arranque (regla 9, paso 6) para cargar su catálogo y registrar manejadores y receptores.

### States and Transitions

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin escena** | Arranque del juego, o tras una descarga total. Ninguna escena cargada; la cortina está en negro. | Cargando (petición válida) |
| **Cargando** | Ejecuta la secuencia de la regla 9, desde «carga de escena iniciada» (paso 1, antes del oscurecido) hasta «carga de escena terminada», incluida la espera en negro. Rechaza nuevas peticiones y la pausa. | Lista · Error |
| **Lista** | Escena activa, cortina transparente. Las zonas disparadoras emiten avisos. | Cargando (nueva petición válida) · Sin escena (descarga total) |
| **Error** | Fallo de carga (regla 14): cortina en negro y mensaje de error. | Sin escena (tras volver al título) |

### Interactions with Other Systems

El sistema no es una pantalla: se comunica con avisos del bus (3) y con peticiones directas. Los avisos nuevos (‡) deben añadirse a la regla 10 del GDD del 3.

| Sistema | Qué recibe de este | Qué entrega a este |
|---|---|---|
| 3 Estado y bus de eventos | Los avisos «carga de escena iniciada», «escena lista», «carga de escena terminada» y «zona activada» ‡; ningún hecho escrito | Estado «Listo» (precondición); lectura de `llamada_completada` (solo regla 13, ningún otro hecho); avisos «estado restablecido» y «estado restaurado» (regla 17) |
| 1 Entrada y controles | «Iniciada» con `D_carga` (impide la pausa y abre el `sin control` de la carga; su pila se reinicia al descargar); la petición del contexto `exploración` al terminar, si `control_final` lo pide | — |
| 2 Jugador en primera persona | Punto de aparición y orientación; el jugador queda quieto hasta que haya control | Su instancia, para colocarla (si es persistente o se instancia por escena lo fija el ADR) |
| 5 Guardado y carga | Escena cargada y lista tras restaurar o tras restablecer | Petición de `planta` con motivo `reanudar` (tras restaurar los hechos) y con `partida_nueva` (tras restablecerlos) ‡ |
| 8 Control de acceso · 9 a 16 · 20 | Huecos y anclas de puerta, contenedores y IDs; «escena lista» | Elementos que se configuran leyendo sus hechos y, si hace falta, retenciones (regla 9, paso 6) |
| 21 Director de escenas | Zonas `T-…`, avisos de carga | Petición de `recepcion` y petición de fundidos propios; devolución del control si `control_final` = `ninguno` ‡ |
| 6 Ajustes | — | Clave booleana `reducir_movimiento` (regla 11) ‡ |
| 23 Audio · 28 Atmósfera | «escena lista» y zonas | — |
| 27 Pantalla de título | Aviso de fallo de carga | Solo la descarga total ‡ (la carga de `planta` la pide 5 al ejecutar `continuar()` / `nueva_partida()`) |

## Formulas

Propuestas por `systems-designer` y contrastadas con el slice y con el F8 de Entrada. † = valor propuesto, a validar en playtest. «Slice» marca los valores que ya fija el documento del slice. El sistema no define presupuesto de rendimiento y no se inventa uno.

### F1 · Opacidad de la cortina

La fórmula de opacidad de la cortina se define como:

`α_out(t) = α_0 + (1 − α_0) · S(clamp(t / d_out, 0, 1))` (oscurecido) · `α_in(t) = 1 − S(clamp(t / d_in, 0, 1))` (aclarado) · `S(x) = x² (3 − 2x)` · `t += min(Δ_real, Δ_max)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t | float (s) | 0 a d | calculated | Tiempo transcurrido del fundido en curso |
| α_0 | float | 0–1 | calculated | Opacidad al empezar el oscurecido (1 si ya está en negro) |
| d_out, d_in | float (s) | 0–5 | data file, tabla por `motivo` | Duración del oscurecido y del aclarado |
| Δ_real | float (s) | ≥ 0 | calculated | Tiempo real del fotograma, sin escala de tiempo del juego |
| Δ_max | float (s) | 0,05–0,1 | constant, 0,1† | Recorte del tiempo por fotograma: un tirón al recuperar el foco no se salta el fundido |
| α | float | 0–1 | calculated | Opacidad de la cortina |

Tabla de duraciones (data file):

| `motivo` | d_out | d_in |
|---|---|---|
| `partida_nueva` | 0,8† (desde el título; 0 si ya está en negro) | 2,0 (slice, C.1) |
| `reanudar` | 0,8† (ídem) | 0,8† |
| `recepcion` | 0,8 (slice, A.0) | 0,8 (slice, A.0) |

Con `reducir_movimiento` verdadero (regla 11), d_out = d_in = 0,1 s en todas las filas.

**Output Range:** α está acotada a [0, 1]. Si `d ≤ 0` el fundido se salta (α_out = 1; α_in = 0), así que no hay división por cero; una `d` mayor de 5 s es un dato inválido (regla de datos, Edge Cases). La curva es suave (sin saltos de velocidad) y cosmética: el slice solo fija la duración.
**Example:** `recepcion`, d = 0,8: en t = 0,4 el oscurecido va por α = 0,5; en t = 0,2 el aclarado va por α = 0,844 (x = 0,25, S = 0,156). Con `reducir_movimiento`, d = 0,1: en t = 0,05 el oscurecido va por α = 0,5.

### F2 · Tope de espera en negro

La fórmula del tope de espera se define como:

`fallo ⇔ t_espera ≥ T_cap` · `lista ⇔ n_ret = 0` (tras completar los pasos 3 a 6 de la regla 9)

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t_espera | float (s) | ≥ 0 | calculated | Tiempo real (Δ_real sin recortar) desde que la cortina es opaca (paso 2 de la regla 9); **sigue avanzando sin foco de la ventana**; no hay pausa (no se puede abrir). El fallo cae a d_out + T_cap desde «iniciada» |
| T_cap | float (s) | 3–30 | data file, 10† | Tope total de espera en negro (desde cortina opaca). Una escena gris carga en menos de 1 s; 10 s cubre un disco lento sin aparentar un cuelgue |
| n_ret | int | 0 en adelante | calculated | Retenciones abiertas de los elementos (regla 9, paso 6) |

**Output Range:** con `n_ret = 0` la escena está lista en el mismo fotograma (carga instantánea). El tope es **total**, no por retención: 100 retenciones no lo acumulan. Una retención que no se libera provoca el fallo a los T_cap segundos y se registra el nombre del elemento. Cada retención se libera por un identificador propio e idempotente (una doble liberación no deja `n_ret` negativo). Con T_cap = 0 el fallo sería inmediato y con T_cap = ∞ habría bloqueo permanente: de ahí el rango.
**Example:** tres retenciones que tardan 0,2, 1,5 y 4,0 s: lista a los 4,0 s, sin fallo. Una que nunca se libera: fallo al alcanzar t = 10,0 s.

### F3 · Tope declarado a Entrada y fotogramas de gracia

La fórmula del tope declarado se define como:

`D_carga = d_out + T_cap + N_gap · Δ_ref + d_in` · `t_inicio_in = t_lista + N_gap fotogramas`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| D_carga | float (s) | 3–40,34 | calculated | Duración máxima de una carga que se declara a Entrada (1) como tiempo de `sin control` |
| N_gap | int | 0–10 | constant, 2† | Fotogramas de gracia entre «escena lista» y el inicio del aclarado, para que los primeros fotogramas de la escena nueva (shaders, física) no se vean |
| Δ_ref | float (s) | 1/144–1/30 | constant, 1/30† | Duración de fotograma de referencia, solo para dimensionar el tope |

**Output Range:** para `recepcion`, `D_carga` = 0,8 + 10 + 2/30 + 0,8 ≈ 11,67 s; con el margen de 2 s† del F8 de Entrada, su tope queda en ≈ 13,67 s. `D_carga` se declara con los valores nominales de la tabla de F1 (con `reducir_movimiento` la carga real dura menos: sigue siendo cota superior). Invariante: **un fallo de carga se detecta a d_out + T_cap desde «iniciada», antes de que Entrada libere el control** (su tope es `D_carga` + margen, medido desde «iniciada», y no se detiene durante la carga porque la pausa no se puede abrir), porque `t_espera` corre en tiempo real **con o sin foco** (regla 12) y `D_carga` ya incluye T_cap. Condición: los fundidos duran lo nominal, es decir, fotogramas ≤ Δ_max. Si hay tirones sostenidos, el oscurecido real se alarga por encima de d_out; el margen de Entrada (2 s†) absorbe hasta ≈ 2,8 s de alargamiento (margen + N_gap·Δ_ref + d_in); más allá, el invariante no se garantiza (limitación asumida, se registra una advertencia si la carga supera `D_carga`). Sin esta declaración, el tope de 3 s† de Entrada liberaría el control con la escena todavía en negro.
**Example:** carga instantánea en `recepcion`: 0,8 s de oscurecido + 2 fotogramas (≈ 0,033 s a 60 fps) + 0,8 s de aclarado ≈ 1,63 s sin control.

## Edge Cases

**Peticiones de carga**
- **If llega una petición mientras hay una carga en curso** (incluida una segunda petición en el mismo fotograma): se acepta la primera y se rechazan las demás (regla 7); en desarrollo, error visible.
- **If se pide una carga antes de que el estado (3) esté en «Listo» o durante una restauración**: se rechaza (regla 7).
- **If se pide `recepcion` con `llamada_completada` falso**: se rechaza y se registra (regla 13). El ascensor «no responde» lo decide Control de acceso o el director de escenas; este sistema solo evita que se cargue Recepción antes de tiempo.
- **If se pide `planta` estando en Recepción sin una descarga total previa**: se rechaza; solo se vuelve a la planta desde «Sin escena» (tras volver al título) o recargándola desde la propia planta (regla 8).
- **If se pide `planta` con motivo `reanudar` y los hechos dicen `llamada_completada` verdadero** (p. ej. por la consola de desarrollo): la planta carga con normalidad en el despacho y el ascensor activo; no se salta a Recepción.

**Arranque de la escena**
- **If falta un ancla de aparición o un contenedor obligatorio en la escena**: fallo de carga (regla 14).
- **If hay dos anclas con el mismo nombre**: en desarrollo, error visible; en la build final se usa la primera en orden de árbol y se registra.
- **If un elemento toma una retención después de «escena lista»**: se ignora y se registra; en desarrollo, error visible (la retención solo tiene sentido en el paso 6 de la regla 9).
- **If una retención no se libera nunca**: la espera llega a T_cap (F2), fallo de carga con el nombre del elemento en el log.
- **If un hecho cambia durante la carga**: el aviso se entrega con normalidad. Los elementos ya configurados lo procesan; los pendientes leen el valor nuevo; no se pierde nada porque el estado es la verdad (regla 3 del GDD del 3).
- **If «estado restablecido» o «estado restaurado» llega con una escena cargada y sin recarga pedida**: regla 17 (advertencia; no se parchea).

**Cortina y tiempos**
- **If el fotograma dura mucho** (un tirón, una ventana minimizada): el tiempo del fundido avanza como máximo Δ_max por fotograma (F1); el fundido nunca se salta de golpe.
- **If la ventana pierde el foco durante la carga**: la espera de F2 sigue avanzando en tiempo real (un fallo se detecta igual, F3) y la pausa se abre al terminar la carga (regla 21 de Entrada); la cortina sigue con su fundido recortado por Δ_max.
- **If se pide la pausa durante la carga**: la descarta Entrada (regla 7 de ese GDD); no queda pendiente.
- **If la carga es instantánea** (`n_ret` = 0 desde el primer fotograma): se respetan d_out, N_gap y d_in completos; el negro no se acorta (F3).
- **If `reducir_movimiento` cambia durante una carga**: no afecta a esa carga (se leyó en el paso 1); vale desde la siguiente.
- **If un valor de la tabla de datos está fuera de rango** (`d_out` o `d_in` fuera de 0–5, `T_cap` fuera de 3–30, `N_gap` fuera de 0–10, `Δ_max` fuera de 0,05–0,1): los datos son inválidos y el juego no entra en partida, con un mensaje de error claro, igual que los sistemas 3, 6 y 18. Lo mismo si falta el fichero.

**Zonas disparadoras**
- **If el jugador aparece dentro de un volumen `T-…`** (solo por datos de prueba: ningún ancla de aparición está dentro de uno): el aviso se emite al terminar la carga («carga de escena terminada»), nunca durante la espera en negro.
- **If el jugador entra en dos zonas a la vez**: se emiten los dos avisos, por orden de ID.
- **If una zona se atraviesa varias veces**: se emite en cada entrada (regla 5); quien escucha decide con sus hechos si ya ocurrió.

**Cierre, fallo y memoria**
- **If el jugador cierra el juego durante una carga**: el juego se cierra sin guardar; vale el último guardado, que nunca queda a medias (lo garantiza el sistema 5).
- **If falla la carga de Recepción**: fallo de carga (regla 14); el último guardado sigue siendo el de la llamada pendiente, así que «continuar» vuelve al despacho (regla 16).
- **If se encadenan cargas y descargas** (planta, Recepción, título, planta…): el número de nodos y la memoria de escena vuelven a su nivel inicial; no se acumulan escenas ni suscriptores (regla 15).
- **If la geometría de la escena difiere del Anexo A.1 en más de 5 cm**: es un defecto de contenido, no una regla de juego; lo detecta la comprobación de medidas (Acceptance Criteria).

## Dependencies

**Aguas arriba (de qué depende):**
- **3 Estado y bus de eventos — dura.** Necesita el estado en «Listo» como precondición de toda carga (regla 7), el bus para emitir sus avisos y los avisos «estado restablecido» y «estado restaurado» (regla 17). De los hechos, este sistema lee solo `llamada_completada` (regla 13); los demás los leen los elementos de la escena (regla 6).
- **1 Entrada y controles — blanda.** Abre su `sin control` de carga al emitir «iniciada» con `D_carga` (F3) y le pide el contexto `exploración` al terminar (si `control_final` lo pide); además Entrada reacciona a los avisos de carga (pausa bloqueada, pila a `sin control`). Sin Entrada, la carga funciona igual pero nadie devuelve el control.
- **2 Jugador en primera persona — dura.** Este sistema invoca una única operación del jugador, «colocar en un ancla con orientación» (el 4 no depende de más), pero la dependencia es dura en ambos sentidos: el 2 vive en la escena y depende de las anclas y del contrato geométrico de la regla 18 (el índice ya dice que el 2 depende del 4). Sin el jugador (prototipo gris) el paso 5 se omite.
- **6 Ajustes — blanda.** Lee la clave booleana `reducir_movimiento` (regla 11) ‡; sin ella la cortina usa las duraciones normales.
- **18 Base de contenido narrativo — blanda.** Rótulo `UI_…` del mensaje de error de carga (regla 14; regla 21 del GDD 18); si el catálogo no carga, texto de emergencia fuera del catálogo.
- Necesita además su fichero de datos (`assets/data/scene/load_transitions.json`, definido por este GDD: tabla de F1, `T_cap`, `N_gap`, `Δ_max`) y que el motor pueda cargar, instanciar y liberar escenas. **No hay referencia de motor para el dominio Core** (`docs/engine-reference/godot/modules/` no tiene `core.md`), así que la viabilidad de la carga y la liberación de escenas no está contrastada con el motor fijado (Open Questions).

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él pero su lógica sigue.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 2 Jugador en primera persona | Dura | Anclas de aparición y orientación; la escena donde vive; contrato geométrico (regla 18). El 4 solo invoca `colocar` |
| 7 Interacción e inspección | Dura | Toma la retención de arranque (regla 9, paso 6) para cargar el catálogo y registrar manejadores/receptores; anclajes de vista y colliders de objetos |
| 5 Guardado y carga | Dura | Pide la carga de `planta` con motivo `reanudar` (tras restaurar) y `partida_nueva` (tras restablecer) |
| 21 Director de escenas | Dura | Pide `recepcion`; escucha las zonas `T-…` y los avisos de carga; pide fundidos propios; toma el `sin control` en el mismo fotograma de «terminada» si `control_final` = `ninguno` |
| 8 Control de acceso | Dura | Huecos y anclas de puerta; se configura leyendo hechos antes de «escena lista» |
| 9 Marco de puzles · 10 Caja · 20 Documentos | Dura (vía contenedores e IDs) | Sus elementos viven en los contenedores de la planta y se configuran en el paso 6 |
| 1 Entrada y controles | Blanda | «Iniciada» con `D_carga` (abre `sin control`); petición de `exploración` |
| 6 Ajustes | Blanda | Aporta `reducir_movimiento` (regla 11) |
| 23 Director de audio · 28 Atmósfera reactiva | Blanda | «Escena lista» y zonas `T-…` |
| 27 Pantalla de título y cierre | Blanda | Pide la descarga total; recibe el fallo de carga (no pide `planta`: lo hace 5) |

**Índice de sistemas:** la fila del sistema 4 lista solo al 3 como dependencia; las dependencias blandas con 1 y 2 no se añaden, igual que hace el GDD del 3 con Entrada. Las filas de 2, 5 y 21 ya listan al sistema 4.

**Bidireccionalidad (cambios pendientes en otros GDD):**
1. **GDD del 3:** su tabla de interacciones y de dependencias dice que este sistema «lee hechos al cargar la escena para dejarla en su estado». Con esta regla (6) la dependencia sigue siendo dura, pero la lectura la hacen los elementos de la escena (el 4 lee solo `llamada_completada`, regla 13); hay que corregir la redacción (líneas ~98 y ~141) y añadir a la regla 10 los avisos «carga de escena iniciada», «escena lista», «carga de escena terminada» y «zona activada».
2. **GDD de Entrada y controles:** debe listar al sistema 4 como emisor de los avisos de carga y aceptar que el 4 abra el `sin control` de una carga al recibir «iniciada» con `D_carga` como duración declarada (F8 de ese GDD, hoy solo declara el director de escenas; el tope no se detiene durante la carga).
3. **GDD del 6 (Ajustes):** catálogo con la clave booleana `reducir_movimiento` (regla 11).
4. **GDD de 5 y 22:** quién sella la partida al llegar a Recepción y en qué aviso (regla 16).
5. **Los demás** (2, 5, 8, 9, 10, 20, 21, 23, 27, 28) no tienen GDD: cada uno debe, al redactarse, listar al sistema 4 y usar los nombres de este documento (`spawn_office`, `spawn_elevator`, `door_slot_*`, IDs del Anexo D.4).

## Tuning Knobs

Todos viven en `assets/data/scene/load_transitions.json` (fuera del rango indicado los datos son inválidos, Edge Cases). † = a validar en el primer playtest.

| Parámetro | Valor | Rango seguro | Qué afecta |
|---|---|---|---|
| d_out, d_in por `motivo` | 0,8 s (`recepcion`, slice A.0); `partida_nueva` d_in 2,0 s (C.1); `reanudar` 0,8 s† | 0–5 s | Ritmo y solemnidad del cambio; entra en `D_carga` |
| d_out = d_in con `reducir_movimiento` | 0,1 s (art bible §7.4) | fijo | Accesibilidad; no se ajusta por separado |
| T_cap (`scene_load_timeout`) | 10 s† | 3–30 s | Cuánto negro se tolera antes de tratarlo como fallo |
| N_gap | 2 fotogramas† | 0–10 | Que no se vean los primeros fotogramas de la escena |
| Δ_max | 0,1 s† | 0,05–0,1 s | Que un tirón no se salte el fundido (alarga el real: ver F3) |
| Δ_ref | 1/30 s† | 1/144–1/30 s | Solo dimensiona `D_carga` |
| Margen del tope de Entrada | 2 s† (parámetro «Margen sobre la duración declarada», F8 de Entrada) | 1–5 s, propiedad de Entrada | Holgura entre fallo y liberación |

## Visual/Audio Requirements

*(Sección opcional para la categoría Core; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

El sistema no tiene presentación propia salvo la cortina. Condiciona a quienes la ponen:
- **Cortina:** negro puro (RGB 0, 0, 0), sin rojo, sin destellos ni parpadeo (art bible: prohibidos en toda la UI el rojo, los destellos y los temblores). El fundido es suave (F1), con `reducir_movimiento` de 100 ms (regla 11), y no incluye ningún elemento gráfico. No se aplica a la UI de la pausa, que no se puede abrir durante la carga.
- **Audio:** el director de audio (23) no pertenece a ninguna escena (regla 1), así que lluvia, drone y voces no se cortan al descargar la planta. Propuesta: 23 atenúa las capas con el oscurecido de «carga de escena iniciada» y las reactiva en «escena lista» ‡; el slice (C.8) pide además que la lluvia cese durante el trayecto del ascensor, cosa que decide 21 con 23.
- **Geometría (MVP):** gris, con las medidas del Anexo A. Iluminación y materiales finales llegan con los sistemas 28 y 29; no cambian las anclas ni los IDs.

## Game Feel

No aplica en el sentido de respuesta al jugador: no lo opera. Lo único exigible es que no haya nada visible a medias:
- Entre «carga de escena iniciada» y «carga de escena terminada» el jugador no controla nada y no se ve una escena parcial; el negro es el único feedback (regla 12).
- El control vuelve cuando el aclarado termina (regla 9, paso 9), no antes; con `control_final` = `ninguno`, cuando lo decide quien pidió la carga.
- Recorrer la planta nunca muestra una cortina ni una carga (AC-04, AC-X2): lo continuo del espacio es parte del tono (art bible, pasillo rectilíneo de 24 m).

## UI Requirements

El sistema no tiene pantalla propia. Solo hay dos elementos visibles:
- **La cortina** (regla 11): capa negra a pantalla completa, sin texto.
- **El mensaje de error de carga** (regla 14), dibujado por encima de la cortina en negro: texto claro, legible y sin rojo, con la acción de volver al título. Su rótulo será una entrada `UI_…` de la base de contenido (18) o, si el fallo impide cargar contenido, un texto fijo en el propio sistema (Open Questions). Como el jugador solo lo ve ante un defecto, su pantalla se especifica junto con la pantalla de título (27), no aquí.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · Anexo A.0 | Planta como escena continua, Recepción con fundido de 0,8 s (A.0 dice «tras la escena 7»; C.8 y §8, que mandan, la sitúan tras la llamada completada y el ascensor, escena 8), unidades y origen | Origen de las reglas 2, 3, 11 y 13 |
| `design/slice/slice-v0.3.md` · Anexo A.1 a A.7 | Envolvente, espacios, IDs y geometría de Recepción | Fuente de las medidas (regla 2) y de AC-02 y AC-03 |
| `design/slice/slice-v0.3.md` · Anexo A.3 | Zonas `T-PAS-1` y `T-PAS-2` | Origen de la regla 5 |
| `design/slice/slice-v0.3.md` · Anexo C.1 y C.8 | Fundido de entrada de 2,0 s; trayecto de ascensor de 6,0 s en Recepción | Origen de F1 (`partida_nueva`) y contexto de la regla 13 |
| `design/slice/slice-v0.3.md` · §8, §13.3 y Anexo D.3 | Activación de Recepción, ascensor que no responde, guardado y reanudación en el despacho | Origen de las reglas 10, 13 y 16 |
| `design/gdd/estado-y-bus-de-eventos.md` · reglas 3, 10, 12, 13 y tabla de interacciones | Estado como verdad; avisos con nombre; «estado restablecido» y «estado restaurado»; fila del sistema 4 | Reglas 6, 7 y 17; cambios pendientes en ese GDD (Dependencies) |
| `design/gdd/entrada-y-controles.md` · reglas 7, 15 y 21, F8 y casos límite de contextos | Pausa durante la carga, pila reiniciada a `sin control`, foco perdido, tope de seguridad | Reglas 9 y 15, F3 |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *El espacio expresa la emoción* | Pilares que este sistema sirve |
| `design/art/art-bible.md` · §7.4 | Opción «Reducir movimiento» (fundidos de 100 ms) | Regla 11 (`reducir_movimiento`, decisión 2026-11-09) |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/scene/`), bloqueante; **I** = test de integración automático o playtest documentado (`tests/integration/scene/`), bloqueante; **V** = captura retenida en `production/qa/evidence/` con visto bueno del lead, bloqueante. **PV** = pendiente de verificación en el editor 4.7: usa APIs o comportamientos de Godot que `docs/engine-reference/godot/` no cubre (sin `core.md`; sensor esférico con `Area3D` bajo Jolt; monitores de rendimiento; nodos huérfanos; instanciación de escenas). Hasta verificarlos en el editor y en el ADR de carga de escenas (OQ 1), esos ACs no cuentan como superados. Los tests L **no cargan escenas ni ficheros reales**. Usan dobles inyectados: un **cargador de escenas falso** (registra cada llamada y puede fallar por causa), una **cortina doble** (registra cada cambio de α), un **jugador espía** (cuenta las llamadas a «colocar»), un **elemento espía** (cuenta las llamadas a `configurar()` y lee hechos), un **estado falso** (cuenta lecturas y escrituras) y un **bus falso** (guarda los avisos con su fotograma y cuenta los suscriptores), más un reloj inyectado (ticks enteros), un manejador de errores y un destino de log. Las fixtures se citan por ruta bajo `tests/fixtures/scene/`. **Vocabulario:** «estado (3) en Listo» es el sistema de estado; «Sin escena», «Cargando», «Lista» y «Error» son los estados de este sistema. **Modos:** salvo que se diga otra cosa, todo rechazo se mide en los dos modos: en desarrollo, el manejador de errores inyectado recibe un error visible; en la build final, se descarta, se añade una línea al log y no cambia nada. Tolerancia numérica ±0,0001 salvo indicación. «Se cierra cuando exista X» marca un criterio que depende de un sistema sin GDD. El sistema no define presupuesto de rendimiento y no se inventa uno.

**Estructura (reglas 1 a 6)**
- **AC-01 (R1, I, PV)**: **GIVEN** el juego arrancado, **WHEN** se carga `planta` y después `recepcion`, **THEN** `get_instance_id()` de los nodos persistentes de Entrada (1), Estado (3), Ajustes (6) y Audio (23), leído antes de cargar `planta` y después de cargar `recepcion`, es idéntico, y en cada fotograma muestreado hay exactamente una escena de juego bajo la raíz del árbol (la actual). *(Se cierra cuando existan 1, 6 y 23.)*
- **AC-02 (R2-R3, I, PV)**: **GIVEN** la fixture `floor_layout.json` (copia de las tablas A.1 y A.7 del slice), **WHEN** se mide la caja envolvente de cada contenedor, **THEN** coincide en X, Z y tamaño con tolerancia ±0,05 m por eje, el origen (0, 0, 0) está en el centro del umbral del Despacho de Vera, +X apunta al este y +Z al norte (verificado con la posición de `door_slot_b` frente a `door_slot_a`), los techos miden 2,70 m (Recepción, 3,20 m) y cada hueco de puerta 1,00 × 2,10 m ±0,05 m; una caja que difiera más de 5 cm falla.
- **AC-03 (R4, I)**: **GIVEN** la fixture `element_ids.json` (los IDs de los anexos A.2 a A.7 y C del slice con su prefijo), **WHEN** se busca cada ID, **THEN** existe una sola vez y dentro de su contenedor (`V` → `office`, `A` → `archive`, `B` → `meeting_room`, `D` → `guardian_office`, `C` y `T` → `corridor`, `R` → `reception`).
- **AC-04 (R3, I)**: **GIVEN** la planta cargada y ningún fundido pedido por otros sistemas, **WHEN** un jugador de prueba (un script que fija su posición) va del despacho a A, a B y a D y vuelve, **THEN** α = 0,0 en cada fotograma del recorrido y hay 0 emisiones de «carga de escena iniciada».
- **AC-05a (R5, I, PV)**: **GIVEN** un jugador de prueba, **WHEN** entra en `T-PAS-1`, sale y vuelve a entrar, **THEN** «zona activada» se emite dos veces con el ID `T-PAS-1`.
- **AC-05b (R5, I, PV)**: **WHEN** cruza en el mismo fotograma de física dos volúmenes solapados (`T-PAS-1` y `T-PAS-2` en una fixture), **THEN** se emiten dos avisos, ordenados lexicográficamente por ID, en ese fotograma; **WHEN** el jugador aparece dentro de una zona (fixture de datos de prueba: el diseño no lo permite), **THEN** su aviso se emite en un fotograma posterior a «carga de escena terminada» y ninguno antes.
- **AC-06 (R6, L)**: **GIVEN** un estado falso con `archivo_abierto` verdadero y un elemento espía que lo lee en `configurar()`, **WHEN** se carga `planta`, **THEN** `configurar()` se llama una vez, antes del aviso «escena lista» en el registro del bus, y con el valor verdadero; y el contador de escrituras del estado falso es 0; las lecturas hechas por este sistema (no por el elemento) son 0 en una carga de `planta` y exactamente una, de `llamada_completada`, en una carga de `recepcion` (regla 6).

**Petición y secuencia (reglas 7 a 17)**
- **AC-07a (R7, L)**: **GIVEN** el estado (3) en «Listo» y este sistema en «Sin escena», **WHEN** Guardado (5) pide `planta` con motivo `partida_nueva` (y con `reanudar`), **THEN** se acepta y entra en «Cargando»; **GIVEN** el estado (3) sin cargar o en restauración, **THEN** se rechaza (en los dos modos) y este sistema no cambia de estado ni llama al cargador.
- **AC-07b (R7, L)**: **GIVEN** este sistema en «Lista», **WHEN** llegan dos peticiones válidas en el mismo fotograma, **THEN** se acepta la primera y se rechaza la segunda (en los dos modos); **WHEN** llega una petición durante «Cargando», **THEN** se rechaza igual.
- **AC-08 (R8, I, PV)**: **GIVEN** la fixture `puzzle2_moved.json` (lámpara L del puzle 2 movida a la posición 4) y los hechos en su valor inicial (`pos_L` = 2), **WHEN** se pide de nuevo `planta`, **THEN** el identificador de instancia de la escena es distinto del anterior y la lámpara L está en la posición 2.
- **AC-09 (R9, L)**: **GIVEN** los dobles y un reloj inyectado, **WHEN** se pide `recepcion` con `control_final` = `ninguno` y `llamada_completada` verdadero, **THEN** el registro conjunto de cortina, cargador, jugador espía, elementos y bus es exactamente: «carga de escena iniciada» (con `D_carga`, antes de cualquier cambio de α) → oscurecido hasta α = 1 → descarga de la planta → instanciación de Recepción → «colocar» del jugador → `configurar()` de los elementos → «escena lista» → inicio del aclarado → «carga de escena terminada»; la descarga no empieza hasta que la cortina doble registra α = 1; y Entrada recibe 0 peticiones de contexto.
- **AC-10 (R9, L)**: **GIVEN** lo mismo con `control_final` = `exploracion`, **THEN** tras «carga de escena terminada» se emite exactamente una petición del contexto `exploración`.
- **AC-11a (R10, I)**: **GIVEN** la planta cargada con motivo `partida_nueva`, y luego con `reanudar` (con y sin la llamada pendiente, fixtures de hechos), **THEN** en los tres casos el jugador está en `spawn_office` (±0,01 m) con velocidad 0 y la orientación del ancla (±0,5°).
- **AC-11b (R10, I)**: **GIVEN** `recepcion` cargada, **THEN** el jugador está en `spawn_elevator` (±0,01 m), dentro del rectángulo X 3,0 a 5,0 m del muro sur, con velocidad 0 y la orientación hacia +Z (±0,5°).
- **AC-12a (R11, V)**: **GIVEN** la transición planta → Recepción con reloj forzado, **WHEN** t = 0,4 s del oscurecido, **THEN** una captura retenida tiene una luminancia media del 50 % ±5 % de la de la misma escena sin cortina; **WHEN** α = 1, **THEN** otra captura tiene RGB = (0, 0, 0) en el centro y en las cuatro esquinas, y ningún elemento de la interfaz de juego es visible.
- **AC-12b (R11, V)**: **GIVEN** el fallo de carga de la build final (AC-15a), **THEN** una captura retenida muestra el mensaje de error legible por encima de la cortina en negro.
- **AC-13 (R12, L)**: **GIVEN** una retención de 3 s, **THEN** la cortina doble registra α = 1 hasta «escena lista», el aclarado no empieza antes, y no se crea ningún nodo de interfaz visible bajo la cortina (el doble de interfaz no recibe ninguna petición de mostrar).
- **AC-14 (R13, L)**: **GIVEN** `llamada_completada` falso, **WHEN** se pide `recepcion`, **THEN** se rechaza como en AC-07 (en los dos modos): contador de escrituras en el estado = 0, este sistema sigue en el mismo estado, la escena actual conserva su identificador y el cargador falso recibe 0 llamadas; **GIVEN** verdadero, **THEN** se acepta con `control_final` = `ninguno`.
- **AC-15a (R14, L)**: **GIVEN** la build final, **WHEN** falla el cargador por cada causa por separado (recurso ausente, escena no instanciable, contenedor obligatorio ausente, ancla de aparición ausente, `T_cap` alcanzado), **THEN** en cada caso la cortina doble queda en α = 1, hay una línea de log con la causa, se pide el mensaje de error y volver al título (27), y nunca se emite «escena lista» ni se inicia el aclarado.
- **AC-15b (R14, L)**: **GIVEN** una build de desarrollo, **WHEN** ocurre cualquiera de esas causas, **THEN** el manejador de errores inyectado recibe un error visible.
- **AC-15c (R4, L)**: **GIVEN** una escena con dos anclas con el mismo nombre, **THEN** en desarrollo hay error visible; en la build final se usa la primera en orden de árbol y hay una línea en el log.
- **AC-16a (R13, I)**: **GIVEN** una planta cargada, **WHEN** pasa a Recepción, **THEN** la planta ya no existe en el árbol (0 nodos de `office`, `corridor`, `archive`, `meeting_room` ni `guardian_office`); **WHEN** se pide `planta` estando en Recepción sin descarga total, **THEN** se rechaza como en AC-07.
- **AC-16b (R15, I, PV)**: **GIVEN** una escena cargada, **WHEN** se pide la descarga total, **THEN** este sistema queda en «Sin escena», la cortina en α = 1 y sin escena de juego en el árbol.
- **AC-16c (R15, I, PV)**: **GIVEN** diez ciclos planta → Recepción → descarga total → planta, **THEN** tras cada ciclo `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)` y el contador de suscriptores del bus son iguales a los del arranque, `Node.print_orphan_nodes()` no lista ninguno y el log no contiene errores; y, tras cada descarga, la pila de contextos de Entrada es `sin control`. *(La parte de Entrada se cierra cuando exista el sistema 1.)*
- **AC-17 (R16, I)**: **GIVEN** un cierre del juego o un fallo de carga durante la carga de Recepción, antes de «terminada», **WHEN** se reanuda, **THEN** el jugador aparece en `spawn_office` con los hechos exactamente como los restauró el guardado (5). *(Qué hace la llamada lo cierra el sistema 22; se cierra cuando existan 5 y 22.)*
- **AC-18 (R17, L)**: **GIVEN** una escena cargada con un elemento espía, **WHEN** llega «estado restaurado» sin petición de recarga, **THEN** se registra una advertencia (en desarrollo, error visible) y `configurar()` recibe 0 llamadas nuevas.
- **AC-19 (Edge Cases, L)**: **GIVEN** una retención tomada después de «escena lista», **THEN** se ignora, se añade una línea al log (en desarrollo, error visible) y «escena lista» no se vuelve a emitir; **GIVEN** un hecho que cambia durante «Cargando», **THEN** el aviso de cambio se entrega y los elementos pendientes leen el valor nuevo; **GIVEN** una petición de pausa durante «Cargando», **THEN** este sistema no la ve ni la guarda (la descarta Entrada).

**Fórmulas (tolerancia ±0,0001)**
- **AC-F1 (L)**: **GIVEN** d = 0,8 y α_0 = 0, **THEN** el oscurecido da α = 0,5 en t = 0,4; **GIVEN** α_0 = 0,6, **THEN** en t = 0,4 da α = 0,6 + 0,4 · 0,5 = 0,8; el aclarado da α = 0,84375 en t = 0,2; **GIVEN** d = 0, **THEN** el fundido se salta sin división por cero; **GIVEN** α_0 = 1, **THEN** el oscurecido se omite; **GIVEN** Δ_real = 0,5 s con Δ_max = 0,1, **THEN** t avanza 0,1 en ese fotograma; **GIVEN** `reducir_movimiento` verdadero, **THEN** d_out = d_in = 0,1 en todos los `motivo` (α = 0,5 en t = 0,05) y α pasa de 0 a 1 (no hay corte); **GIVEN** la tabla de datos, **THEN** `partida_nueva` tiene d_in = 2,0, `reanudar` d_in = 0,8 y `recepcion` d_out = d_in = 0,8.
- **AC-F2 (L)**: **GIVEN** tres retenciones que se liberan a 0,2, 1,5 y 4,0 s, **THEN** «escena lista» sale a los 4,0 s sin fallo; **GIVEN** una retención que nunca se libera y `T_cap` = 10, **THEN** hay fallo al alcanzar t_espera = 10,0 s (no antes) con el nombre del elemento en el log; **GIVEN** 100 retenciones liberadas a 1 s, **THEN** no hay fallo; **GIVEN** una doble liberación, **THEN** `n_ret` no baja de 0; **GIVEN** la ventana sin foco durante 20 s, **THEN** t_espera sigue avanzando (con T_cap = 10 hay fallo a los 10 s, sin foco).
- **AC-F3 (L)**: **GIVEN** d_out = 0,8, T_cap = 10, N_gap = 2, Δ_ref = 1/30 y d_in = 0,8, **THEN** `D_carga` = 11,6667 ±0,001 s; **GIVEN** una carga instantánea simulada a 60 fps (Δ real de 1/60, distinto de Δ_ref, que solo dimensiona el tope), **THEN** el aclarado empieza exactamente N_gap = 2 fotogramas después de «escena lista» y el tiempo sin control es 1,6333 ±0,001 s; **GIVEN** `D_carga` y el margen de F8 de Entrada (parámetro «Margen sobre la duración declarada»; el AC lo lee de los datos de Entrada, no lo fija), **THEN** un fallo por T_cap ocurre a d_out + T_cap desde «iniciada», antes de `D_carga` + margen, también con la ventana sin foco 20 s.

**Datos**
- **AC-D1 (L)**: **GIVEN** contenidos de fixture inyectados como diccionarios (`d_out` = 6, `T_cap` = 2, `N_gap` = 11, `Δ_max` = 0,2), **WHEN** se valida el catálogo, **THEN** en cada caso no se entra en partida y el manejador de errores fatal recibe el código `DATOS_ESCENA_INVALIDOS` con el nombre del parámetro.
- **AC-D2 (I)**: **GIVEN** el fichero `assets/data/scene/load_transitions.json` ausente o corrupto en disco, **WHEN** arranca el juego, **THEN** no se entra en partida y se muestra el mensaje de error.

**Interacciones (se cierran cuando existan)**
- **AC-X1 (I)**: **GIVEN** Entrada (1) y el director de escenas (21), **WHEN** se pide `recepcion`, **THEN** durante «Cargando» Entrada no abre la pausa, abre su `sin control` al recibir «iniciada» con `D_carga` como duración declarada y no lo libera antes de «escena lista», y el contexto vuelve a `exploración` solo cuando 21 lo pide.
- **AC-X1b (I)**: **GIVEN** Entrada (1) real, `recepcion` con una retención que nunca se libera, T_cap = 10 y la ventana sin foco 20 s desde «iniciada», **THEN** el fallo de carga se registra a d_out + 10 s, antes de que Entrada libere su `sin control` (`D_carga` + margen), la cortina sigue en α = 1 y no se devuelve el control. *(Se cierra cuando exista el sistema 1.)*
- **AC-X2 (I)**: **GIVEN** un playtest documentado en geometría gris, **WHEN** se recorre la planta del despacho al ascensor y se entra en Recepción, **THEN** la cortina solo cambia de α en el aclarado de la partida nueva o reanudada, en la transición a Recepción y en los fundidos que pida expresamente el director de escenas, y no aparece ningún elemento de interfaz de carga.

## Decisiones tomadas

Ronda 2 (2026-11-09), según la re-review y las decisiones ya tomadas del lote.

| Decisión | Alternativa descartada | Motivo |
|---|---|---|
| «Iniciada» sale en el paso 1, antes del oscurecido; la pausa se bloquea desde ahí (regla 9) | Emitirla con la cortina opaca | `D_carga` incluye d_out y Entrada debe cubrir el oscurecido sin dejar abrir la pausa |
| `t_espera` cuenta desde cortina opaca; el fallo cae a d_out + T_cap desde «iniciada» | Contar T_cap total desde «iniciada» | Mantiene F3 y el significado de T_cap como espera real de la carga |
| `t_espera` corre en tiempo real, con o sin foco (regla 12, F2) | Congelarlo sin foco y hacer que Entrada también congele su tope | Un solo cambio local, sin tocar Entrada; el invariante de F3 vale con foco perdido. Limitación con tirones sostenidos documentada |
| El 4 abre el `sin control` de la carga con `D_carga`; 21 solo toma el suyo en «terminada» si `control_final` = `ninguno` | Que 21 abra todos los `sin control` | Cubre `partida_nueva` desde el título y `reanudar`, donde no hay director de escenas activo |
| Lee solo `llamada_completada`; ningún otro hecho (regla 6) | Quitar la comprobación de la regla 13 | La red de seguridad contra softlock es barata |
| Cortina respeta `reducir_movimiento`: 0,1 s fijos (regla 11) | Ignorarlo en la cortina | Decisión del usuario; el fundido sigue existiendo |
| `spawn_office` queda a ≈ 2,5 m de V01 con (−3,0; 0,0) | Moverlo a (−2,6; 0,6) para 3 m | Menos cambio; validar en el prototipo gris |
| Fundido de 0,8 s de A.0 = 0,8 s en cada sentido | 0,8 s en total | Recomendación del revisor, confirmada por defecto |
| Aparecer dentro de una zona `T-…` solo por datos de prueba | Retirar la regla | Defensa barata y AC existente |
| Dependencia con el 2 unificada en «dura» | Blanda de este lado | Coherente con el GDD 2 y la tabla aguas abajo |
| Tras llegar a Recepción la partida queda sellada y el título ofrece solo «Nueva partida» (regla 16) | «Continuar» desde el despacho | Decisión del usuario; el momento del sello lo fijan 5 y 22 |
| Cabina de la planta externa y sin modelar; `door_slot_elevator` añadido | Modelar la cabina de la planta | El slice la llama «cabina externa»; la de 1,2 × 1,2 m es la de Recepción |

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Mecanismo de carga:** cargar, instanciar y liberar escenas; si el jugador y los sistemas persistentes son autoload o nodos aparte; formato de los avisos y de las retenciones. **No hay referencia de motor para el dominio Core** (`docs/engine-reference/godot/modules/` no tiene `core.md`): hay que verificarlo contra la documentación del motor. | `/architecture-decision` | Fase de arquitectura |
| 2 | **Interior de la cabina del ascensor** en Recepción: tamaño y posición de `spawn_elevator`. El slice (A.1) dice «cabina externa» y A.7 solo da el hueco en el muro sur. | GDD del sistema 21 / level-designer | GDD del sistema 21 |
| 3 | **`spawn_office`:** posición propuesta (−3,0; 0,0), a ≈ 2,5 m de V01 (no 3 m), orientación hacia V01 (‡†); validar en el prototipo gris. | Prototipo gris (slice §23) | Primer prototipo |
| 4 | **«Fundido de 0,8 s» del slice (A.0):** resuelta por defecto (2026-11-09): 0,8 s en cada sentido. | — | Cerrada |
| 5 | **Cortina y «Reducir movimiento»:** resuelta (2026-11-09): la cortina respeta `reducir_movimiento` (0,1 s). Falta que el GDD de Ajustes (6) incluya la clave. | GDD del sistema 6 | GDD del sistema 6 |
| 6 | **Quién devuelve el control:** propuesto `control_final` en la petición con valores por defecto (regla 7) y el `sin control` de la carga abierto por el 4 (regla 9); falta confirmar en 21 y 27. | GDD de los sistemas 21 y 27 | Esos GDD |
| 7 | **Cambios pendientes en otros GDD:** avisos nuevos y fila del 4 en el GDD del 3; `sin control` de carga con `D_carga` en F8 de Entrada; `reducir_movimiento` en 6; sello de la partida en 5 y 22. Anotados en la re-review. | Autor de cada GDD | Re-review de cada uno |
| 8 | **Mensaje de error de carga:** texto y rótulo `UI_…` cerrados por la regla 21 del GDD 18 (texto de emergencia fuera del catálogo); queda qué ocurre al volver al título. | GDD del sistema 27 | GDD del sistema 27 |
| 9 | **Fundidos propios del director de escenas** (cierre de la escena 8): contrato de petición a la cortina. | GDD del sistema 21 | GDD del sistema 21 |
| 10 | **Reanudar tras fallar Recepción o cerrar en ella:** la llamada se repite (último guardado = llamada pendiente, slice D.3). Confirmar que es lo deseado. | GDD de los sistemas 5 y 22 | Esos GDD |
| 11 | **Zonas `T-…` al reanudar:** quien escucha (21) decide si repite la escena 4; no hay hecho que marque «escena 4 vista» en el catálogo de 19. | GDD del sistema 21 | GDD del sistema 21 |
| 12 | **Valores † de F1 a F3** (`Δ_max` 0,1 s, `T_cap` 10 s, `N_gap` 2, curva suave) y el 0,8 s† de oscurecido en `partida_nueva` y `reanudar`. | Prototipo gris y playtest (slice §23.4) | Primer playtest |
| 13 | **Registro de entidades:** registrar el fundido de 2,0 s (C.1), `N_gap`, `Δ_max`, `Δ_ref` y los 0,1 s de `reducir_movimiento`; alinear el rango de `scene_load_max_duration` a [3; 40,34]. | `/design-system` (al cerrar el GDD) | Aprobación del GDD |

## Historial de cambios

- **2026-11-09 (lote 2/5/7/9, cambios derivados de las revisiones de 2, 5 y 7):** (a) Regla 7, tablas de interacción y dependencias y AC-07a: **Guardado (5) pide `planta` con `reanudar` y con `partida_nueva`**; Título (27) solo llama a `continuar()` / `nueva_partida()` y a la descarga total. (b) Nueva regla 18: contrato geométrico con el Jugador y con Interacción (paso mínimo 0,60 m, cápsula 0,25 m, puertas sin colisión al abrir, sensor de `T-…`, etiqueta de superficie, cabina ≥ 1,2 × 1,2 m, `B05`, anclajes de vista, retención de arranque de 7). (c) Contradicción interna sobre la dependencia con el Jugador (blanda/dura) aclarada. (d) 7 listado como dependiente. **Cambia reglas: pendiente de re-review.** Estado del documento sin cambios. Pendiente: «confirmar escena lista tras la configuración síncrona» (informe de 9) ya queda cubierto por la regla 9, pasos 6 y 7; sin cambio.
- **2026-11-09 (ronda 2, aplica la re-review):** orden único de «iniciada» (paso 1) en reglas 9 y 12, F2, F3 y estados; invariante de F3 corregido (`t_espera` en tiempo real con foco perdido, límite con tirones documentado) y AC-X1b; el 4 abre el `sin control` de la carga con `D_carga`; el sistema lee solo `llamada_completada`; `reducir_movimiento` en la cortina; `spawn_office` ≈ 2,5 m de V01; `door_slot_elevator`; dependencia con el 2 unificada; secciones Tuning Knobs y Decisiones tomadas; ACs con APIs de Godot marcados PV; cabecera alineada. **Cambia reglas: pendiente de re-review.**
