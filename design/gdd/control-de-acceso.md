# Control de acceso (puertas, tarjetas, lectores)

> **Status**: Borrador (lote Feature 1) — pendiente de review
> **Author**: level-designer (lote autónomo) + Álvaro
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (ningún lector ni puerta puede dejar al jugador sin salida) · El espacio expresa la emoción (puertas que se abren despacio, lectores que no juzgan) · Autonomía como progresión (las llaves se ganan resolviendo, no se compran ni se pierden)

## Summary

Control de acceso pone y gobierna las cuatro «cerraduras» del slice: las puertas del Archivo (A), la Sala de Reuniones (B) y el Despacho del Guardián (D), los lectores de tarjeta que abren B y D (`C06`, `C07`, `D06`) y el ascensor (`C08`) que lleva a Recepción. Lee hechos (`archivo_abierto`, `tarjeta_B`, `tarjeta_D`, `llamada_completada`), no escribe ninguno, anima las hojas (1,2 s) y avisa de «puerta abierta» para que Guardado escriba. Existe para que la progresión del grafo del slice (§8) sea legible en el espacio —una puerta cerrada es una pregunta, un lector que parpadea es una respuesta parcial— y para garantizar que reanudar, repetir o equivocarse nunca deja al jugador sin camino.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `3 Estado y bus de eventos` (dura) · `7 Interacción e inspección` (dura) · `4 Escena de planta` (dura) · `18 Base de contenido narrativo` (dura) · `5 Guardado y carga`, `9 Marco de puzles`, `20 Documentos y bolsillo`, `21 Director de escenas`, `23 Audio` (blandas)

## Overview

El slice tiene tres puertas cerradas (A, B y D; slice §7) y un ascensor inactivo hasta la llamada. Este sistema es el dueño de todos ellos y de sus tres lectores. **No es un sistema de inventario ni de llaves con estado propio**: las «llaves» son los hechos `tarjeta_B` y `tarjeta_D` (escritos por 20 al recoger las tarjetas `I-02` e `I-03` en el cajón `A05`); las tarjetas **no se gastan** al usarlas.

La puerta A no tiene lector: se abre sola cuando 9 escribe `archivo_abierto` (resolución del puzle 1). Las puertas B y D se abren cuando el jugador usa su lector con la tarjeta ya recogida (gesto `HAND_CARD_SWIPE`); sin tarjeta, el lector muestra un pie de texto de «cerrada» y suena un clic sutil, sin penalización. Una vez abierta, una puerta **no vuelve a cerrarse** durante la sesión. Al reanudar desde un guardado, A refleja `archivo_abierto` y B y D vuelven a nacer cerradas (el estado «abierta» no se guarda, D-24 de 5): el jugador las abre de nuevo con la misma tarjeta, sin coste.

El ascensor `C08` responde solo tras `llamada_completada` (más 2,0 s, slice C.7). Antes de eso, intentar usarlo hace sonar la megafonía «Planta en modo de ahorro energético» (slice §13.3). Qué ocurre después de entrar (cambio a Recepción) lo decide el director de escenas (21) con 4.

## Player Fantasy

Vera es una empleada de noche en una planta que ya no le pertenece del todo. Las puertas son los puntos donde el edificio le dice «todavía no» o «adelante», y debe sentirse como un edificio real, no como un videojuego de cerraduras: la tarjeta que pasa por el lector, el parpadeo, el clic de la cerradura, la hoja que cede con lentitud (1,2 s) y deja ver la sala por primera vez. Abrir el Archivo tras el puzle debe sentirse como una recompensa merecida; abrir B y D, como un permiso que ya tenía y que ahora se atreve a usar.

Lo que **no** debe sentir: que el edificio la castiga. Un lector sin tarjeta es un «todavía no» neutro, nunca una alarma, un rojo agresivo ni un contador de intentos. No hay nada que gastar, perder ni «usar mal». Si cierra el juego y vuelve, las puertas se abren con un gesto, como si la tarjeta siguiera donde estaba.

## Detailed Rules

### Catálogo y datos

1. **Qué posee este sistema (y qué no).** Posee: la hoja y el marco de las puertas A, B y D (en los huecos `door_slot_a`, `door_slot_b`, `door_slot_d` que pone 4, regla 3 de 4), los lectores `C06` (corredor, junto a B), `C07` (corredor, junto a D) y `D06` (interior de D), el hueco `door_slot_elevator` con el ascensor `C08` y los manejadores `can_interact`/`interact`/`etiqueta` de los cuatro objetos interactuables (`C06`, `C07`, `D06`, `C08`; 7 regla 3). **No posee:** las tarjetas ni sus hechos (20; el 3 lista a 20 como dueño de `tarjeta_B/D`), `archivo_abierto` (9), `llamada_completada` (22), el cambio de escena a Recepción (21 y 4), el cuerpo del Jugador (2) ni la puerta de salida de Recepción (decorado de `recepcion`, «no es interactuable»: 7 regla 26 y slice A.7; **no** pertenece a este sistema). **8 no escribe ningún hecho**: ninguno de los 20 hechos del slice (Anexo D.2) es suyo, y el estado de cada puerta es derivado (regla 4), no un hecho.
2. **Elementos controlados** (los IDs y posiciones son los del slice A.3, A.6, A.0 y A.1):

   | Elemento | Tipo | Dónde | Se abre / se activa con | Interactuable (7) |
   |---|---|---|---|---|
   | Puerta **A** | Puerta | `door_slot_a` (muro sur del pasillo, X 7,5 a 8,5) | Hecho `archivo_abierto` | No (se abre por hecho) |
   | Puerta **B** | Puerta | `door_slot_b` (muro norte, X 12,0 a 13,0) | Lector `C06` + hecho `tarjeta_B` | No |
   | Puerta **D** | Puerta | `door_slot_d` (muro norte, X 21,0 a 22,0) | Lector `C07` o `D06` + hecho `tarjeta_D` | No |
   | Lector `C06` | Lector | Muro norte del pasillo, (13,2; Y 1,1) | Abre la puerta B | Sí, verbo «Usar» |
   | Lector `C07` | Lector | Muro norte del pasillo, (22,2; Y 1,1) | Abre la puerta D | Sí, verbo «Usar» |
   | Lector `D06` | Lector | Cara interior del muro de D, (22,2; Y 1,1) | Abre la puerta D (espejo de `C07`, regla 7) | Sí, verbo «Usar» |
   | Ascensor `C08` | Ascensor | `door_slot_elevator` (muro norte, X 1,4 a 2,6) | Hecho `llamada_completada` + `t_ascensor_s` | Sí, verbo «Entrar» |

   Hueco de las puertas: 1,00 × 2,10 m (slice A.0). Cada elemento tiene datos en `assets/data/access/access.json` (regla 3); nada de lo anterior se fija en código (coding-standards: valores de juego dirigidos por datos).
3. **Datos** (esquema; validado en carga y en CI): `doors[]` con `{id: A|B|D, slot, abre_por: "hecho"|"lector", hecho: <nombre>, lectores: [<ID>], tarjeta_item: <I-xx>, t_apertura_s, bisagra: oeste|este}`; `readers[]` con `{id, puerta, texto_sin_tarjeta: <clave OBJ_…>}`; `elevator` con `{id: C08, hecho: llamada_completada, t_activacion_s, linea_inactivo: <ID de línea>, enfriamiento_linea_s, texto_inactivo: <clave>}`. Un ID repetido, un ancla o un hecho inexistente o un lector que no esté en el catálogo de 7 es un dato inválido (regla 19).

### Estados de la puerta

4. **Estados de puerta** (derivados; no se guardan, D-24 de 5): `CERRADA`, `ABRIÉNDOSE`, `ABIERTA`. Al configurarse (regla 5) y por la regla 6 y 9 solo hay estas transiciones: `CERRADA → ABRIÉNDOSE → ABIERTA`. **No existe `ABIERTA → CERRADA`** (regla 10). Una puerta `CERRADA` tiene la colisión de su hoja activa; en `ABRIÉNDOSE` y `ABIERTA` la hoja **no colisiona** (regla 18(b) de 4, D-19 de 2, regla 1 de 2).
5. **Configuración al arranque.** Es parte del paso 6 de la regla 9 de 4 («el resto de elementos», tras 7 y 9; los hechos ya están definitivos). Síncrona, en el mismo fotograma, sin retención. Puertas: **A** nace `ABIERTA` (hoja abierta, sin animación, sin sonido, **sin aviso «puerta abierta»**) si `archivo_abierto` es verdadero, y `CERRADA` si es falso; **B y D nacen siempre `CERRADA`** aunque `tarjeta_B/D` sean verdaderos (D-24 de 5, AC-41b de 5). Lectores: su estado (regla 7) se calcula en cada consulta, no se almacena. Ascensor: regla 13. Después se suscribe al hecho `archivo_abierto` (aviso de cambio por hecho, regla 9 de 3).

### Puerta A

6. **La puerta A se abre por un hecho.** Cuando `archivo_abierto` pasa de falso a verdadero con la puerta `CERRADA`, A pasa a `ABRIÉNDOSE` **en el mismo paso** en que recibe el aviso de cambio y emite «puerta abierta» (`A`) (regla 11), reproduce `ANIM_DOOR_OPEN` (1,2 s) y, al terminar, pasa a `ABIERTA`. **No reproduce `SFX_UNLOCK`**: lo reproduce 9 como parte de la resolución del puzle 1 (marco de puzles, ejemplo de F4: «`SFX_UNLOCK` (1,4 s) y la puerta A empieza a abrirse»). Si el aviso llega cuando la puerta ya está `ABRIÉNDOSE` o `ABIERTA`, no hace nada. La puerta A no tiene lector y no es interactuable (7 reglas 6 y 26): quien se acerca antes de resolver el puzle ve una puerta cerrada y, a su lado, el panel `C05` (slice A.3).

### Puertas B y D: lectores

7. **Estados del lector** (calculados, no guardados). Para un lector `R` de la puerta `P` con tarjeta `K` (`tarjeta_B` para `C06`; `tarjeta_D` para `C07` y `D06`), leyendo el hecho `K` por lectura directa en el paso de física (7 regla 3, `can_interact` es puro y barato):

   | Estado del lector | Condición | `can_interact(Usar)` | LED (regla 17) |
   |---|---|---|---|
   | `SIN_TARJETA` | `P` = `CERRADA` y `K` falso | `SIN_EFECTO` (con `texto_sin_tarjeta`) | Ámbar tenue |
   | `LISTO` | `P` = `CERRADA` y `K` verdadero | `SI` | Ámbar tenue |
   | `LEYENDO` | Lector usado, aún no ha empezado `ABRIÉNDOSE` (regla 8) | `NO` | Ámbar parpadeando |
   | `ABIERTO` | `P` = `ABRIÉNDOSE` o `ABIERTA` | `NO` (sin icono, sin reacción, 7 regla 3) | Verde fijo |

   `D06` es **espejo exacto de `C07`**: misma puerta, mismo hecho, mismo estado (se calcula de la puerta, no del lector). No existe lector interior para A ni B (nunca hay jugador dentro con la puerta cerrada, regla 10). `D06` no añade ningún comportamiento ni dato propio; existe porque el slice A.6 lo coloca en el interior de D. El `SIN_EFECTO` de `SIN_TARJETA` nunca confirma qué tarjeta falta ni dónde está; solo dice que está cerrada (regla 16).
8. **`interact(Usar)` de un lector.** Si el estado es `LISTO` (comprobado de nuevo dentro de `interact`, 7 regla 3, porque pudo cambiar entre el paso de física y la pulsación): (a) el lector pasa a `LEYENDO`; (b) suena `SFX_CARD_OK` (3D, en el lector) ‡; (c) tras `t_lectura_s` (0,5 s†, tiempo de juego, regla 20) la puerta pasa a `ABRIÉNDOSE`, se emite «puerta abierta» (`B` o `D`) y empieza `ANIM_DOOR_OPEN`; (d) devuelve `HECHO`. Si el estado no es `LISTO` devuelve `SIN_EFECTO` (con texto si es `SIN_TARJETA`, sin él si es `LEYENDO` o `ABIERTO`); **no** emite aviso ni cambia estado. El gesto `HAND_CARD_SWIPE` (≤ 1,0 s†, bloqueante, derecha; catálogo de 2) lo reserva 7 antes de llamar a `interact()` (7 regla 3); mientras el gesto está activo la apertura no depende de él: si el jugador cierra el menú o mira a otro lado, la puerta se abre igual. Si el Jugador **rechaza** el gesto (otro gesto bloqueante en curso), `interact()` no se llama (7 regla 3): el jugador pulsa de nuevo, sin coste.
9. **Secuencia de apertura.** `ABRIÉNDOSE` dura `t_apertura_s` = 1,2 s (slice A.0; F1). La hoja gira 90° hacia el **interior** de la sala (regla 18(b) de 4: «preferir que abran hacia el lado contrario al paso habitual»), con bisagra en el lado oeste en B y D y en el lado este en A (el lector queda siempre en el lado libre del marco). La **colisión de la hoja se desactiva en el primer paso de `ABRIÉNDOSE`** (D-19 de 2; 4 regla 18(b)): el jugador puede cruzar el hueco antes de que termine la animación y nunca queda atrapado (AC-07 de 2). La hoja no empuja ni mueve al jugador (regla 21 de 2). Al llegar a 1,2 s, `ABIERTA`: la hoja queda a 90° y no se mueve más.
10. **Las puertas no se cierran.** Una puerta `ABRIÉNDOSE` o `ABIERTA` permanece así hasta que se descarga la escena. Esto garantiza, por construcción, que el jugador no puede quedar encerrado dentro de A, B o D, que el recorrido de salida de D con `caja_completa` (slice §8 paso 5, escena 7) siempre está libre y que no hace falta lector interior para A ni B. Si una herramienta de desarrollo fuerza `archivo_abierto` a falso (CA-28 de 3), la puerta A **no se cierra**: se registra una línea y se ignora.

### Hechos, avisos y guardado

11. **Avisos que emite este sistema** (los declara aquí y se incorporan a la tabla de la regla 10 de 3): **«puerta abierta» (`A`, `B` o `D`)** ‡ — se emite **una vez por apertura real**, en el primer paso de `ABRIÉNDOSE` (no al terminar la animación, para que el guardado no dependa de que el jugador espere 1,2 s). No se emite al configurar una puerta A ya abierta (regla 5), ni al ignorar un aviso duplicado (regla 6). **«ascensor llamado»** (sin datos) ‡ — una vez, al aceptar `interact(Entrar)` con el ascensor `DISPONIBLE` (regla 14); lo consume 21. **«línea pedida»** (`MEGA_03`) ‡ — la pide 8 para la megafonía (regla 15); 8 se añade como emisor de «línea pedida» junto a 9. 8 es **suscriptor** de: el hecho `archivo_abierto`, y lee `tarjeta_B`, `tarjeta_D`, `llamada_completada` por lectura directa; no se suscribe a ningún otro.
12. **Guardado y reanudación.** Este sistema **no guarda nada** y no aporta ningún hecho al guardado. «Puerta abierta» (`A|B|D`) es la causa `door_opened:<ID>` de 5 (regla 6 de 5; no urgente), que ya la consume. Al reanudar, la escena se reconstruye según la regla 5: A según `archivo_abierto`; B y D cerradas; el jugador (en el despacho de Vera, siempre) vuelve a abrirlas con la tarjeta sin penalización (AC-41b de 5). Que `tarjeta_B/D` sean verdaderos tras reanudar lo garantiza 5 (causa `card_acquired`, D-29 de 5) y su monotonía, 3 (CA-03 de 3: un hecho de tarjeta no vuelve a falso).

### Ascensor

13. **Estados del ascensor `C08`** (derivados; no se guardan): `INACTIVO` (por defecto: `llamada_completada` falso), `ESPERA` (`llamada_completada` verdadero hace menos de `t_ascensor_s`), `DISPONIBLE` (pasados `t_ascensor_s` = 2,0 s, slice C.7: «+2,0: C03 se restablece. Se activa C08»), `EN_USO` (tras aceptar la entrada). Al configurar: si `llamada_completada` ya es verdadero (guardado tras la llamada o prueba), el ascensor nace `DISPONIBLE` sin espera. Mientras `INACTIVO`, `can_interact` devuelve `SIN_EFECTO`; en `ESPERA` y `EN_USO`, `NO` (sin icono ni reacción, 7 regla 3); `DISPONIBLE`, `SI`.
14. **`interact(Entrar)`**. En `DISPONIBLE`: pasa a `EN_USO`, emite «ascensor llamado» (regla 11) y devuelve `HECHO` (7 reserva `HAND_REACH`, 0,5 s, antes, lo que cubre el hueco de un fotograma hasta que 21 toma el `sin control`). 8 **no** carga Recepción ni anima la cabina (la planta no la modela, regla 18(e) de 4): eso lo ordena 21 a 4, que rechaza `recepcion` con `llamada_completada` falso (4 regla 13), así que un fallo de 8 no puede adelantar el final. En `INACTIVO`, `interact` aplica la regla 15. En cualquier otro estado devuelve `SIN_EFECTO` sin efectos. Si 4 informa de un fallo de carga de Recepción (4 regla 14), la planta se recarga desde el título (5 regla 18): `llamada_completada` ya no estará verdadero, el ascensor nace `INACTIVO` y la llamada se repite (slice §13.2).
15. **Ascensor `INACTIVO` (slice §13.3).** El jugador ve el icono «Entrar» en `C08` y puede intentar usarlo: 7 reserva `HAND_REACH`, llama a `interact()` y 8 (a) devuelve `SIN_EFECTO` con `texto_inactivo` como pie (suena `SFX_CLICK_SUBTLE`, 7 regla 11) y (b) si ha pasado `enfriamiento_linea_s` (8 s†) desde la última, emite «línea pedida» (`MEGA_03`) ‡ (megafonía por `C01`: «Planta en modo de ahorro energético»), que 23 reproduce. Dentro del enfriamiento solo pie y clic. **No hay penalización**: sin contador, sin consecuencia, sin cambio de estado.

### Textos, audio y accesibilidad

16. **Textos.** Cada lector y el ascensor llevan una clave de objeto de 18 (`OBJ_C06`, `OBJ_C07`, `OBJ_D06` para «cerrada sin tarjeta»; `OBJ_C08` para el ascensor inactivo). Son pies breves (≤ `texto_max_caracteres`, 7 regla 12): ambiente y estado, **nunca información necesaria para avanzar** (el pie no se puede releer, 7 regla 12). Tono: descriptivo y neutro, sin confirmar intención ni culpa («Lector de tarjeta. Luz ámbar.» — texto final de 18, narrative-director). Etiquetas de acción: «Usar» y «Entrar» (existen en 18, 7 regla 25). 8 no tiene `etiqueta()` propia salvo que la pida (opcional: ninguna en el slice).
17. **Presentación del lector (para 28/29 y 23).** Dos cues **independientes del color**: el LED cambia de **brillo y de patrón** (ámbar tenue fijo → ámbar parpadeando → verde brillante fijo), no solo de tono, y cada cambio lleva un sonido (`SFX_CARD_OK` al leer; `SFX_CLICK_SUBTLE` para el rechazo, que pone 7). El rechazo no usa rojo, ni sonido de error, ni destello (con `reducir_sobresaltos` activo no cambia nada: ya es mínimo). Los sonidos son 3D posicionados en el lector o en el hueco; la puerta no tiene sonido propio más allá de `ANIM_DOOR_OPEN`.
18. **Invariantes de no-softlock (pilar 1, prioridad 1).** (a) Ninguna secuencia de acciones deja una de A, B o D `CERRADA` con su condición cumplida y sin forma de activarla: A la abre el hecho; B y D, el lector, que acepta cuantas pulsaciones haga falta. (b) No hay contadores, bloqueos temporales ni «lector atascado». (c) Las tarjetas no se gastan ni se pueden perder. (d) Ninguna puerta se cierra con el jugador dentro (regla 10). (e) `C08` solo depende de `llamada_completada` (22) y nunca de que el jugador esté en un sitio u otro. (f) Ninguna ruta crítica pasa por una puerta cuyo hecho no se pueda alcanzar sin pasar por ella: `tarjeta_D` se recoge en `A05` (dentro de A, que depende solo de `archivo_abierto`), y `tarjeta_B` también.
19. **Datos inválidos.** En desarrollo, un dato inválido (regla 3) es un error visible que detiene la ejecución. En la build final **8 falla abierto**: la puerta afectada se crea `ABIERTA` (o el lector funciona como `LISTO`), se registra una línea con la causa y se continúa. Nunca se emite fallo de carga por este sistema (no puede dejar al jugador sin camino, pilar 1) y el CI debe fallar en cualquier build con datos inválidos (regla 3, AC-12).
20. **Reloj.** Los temporizadores de este sistema (`t_lectura_s`, `t_apertura_s`, `t_ascensor_s`, `enfriamiento_linea_s`) son de **tiempo de juego**: el menú de pausa los detiene (7 regla 32 para su familia; mismo criterio).

### States and Transitions

| Elemento | De → a | Disparo |
|---|---|---|
| Puerta A | `CERRADA` → `ABRIÉNDOSE` | Aviso de cambio `archivo_abierto` (falso → verdadero) |
| Puerta B/D | `CERRADA` → `ABRIÉNDOSE` | `t_lectura_s` tras `interact()` válido del lector |
| Puerta | `ABRIÉNDOSE` → `ABIERTA` | `t_apertura_s` |
| Lector | `SIN_TARJETA` ↔ `LISTO` | Cambio de `tarjeta_B/D` (solo falso → verdadero) |
| Lector | `LISTO` → `LEYENDO` → `ABIERTO` | `interact()` válido; inicio de `ABRIÉNDOSE` |
| Ascensor | `INACTIVO` → `ESPERA` → `DISPONIBLE` | `llamada_completada` verdadero; `t_ascensor_s` |
| Ascensor | `DISPONIBLE` → `EN_USO` | `interact(Entrar)` |

No hay transiciones inversas dentro de una sesión (regla 10). La recarga (escena nueva) reinicia todo a partir de los hechos (regla 5).

## Formulas

**F1 · Tiempo de pulsación a puerta abierta (B y D)**

`T_pulsa→abierta = t_lectura_s + t_apertura_s`

| Variable | Definición | Rango | Valor |
|---|---|---|---|
| `t_lectura_s` | Pausa entre `interact()` y el inicio de la hoja (lectura de tarjeta) | 0,2 a 1,0 s | 0,5 s† |
| `t_apertura_s` | Duración de `ANIM_DOOR_OPEN` | 0,8 a 2,0 s (fijo del slice: 1,2 s) | 1,2 s |

Ejemplo: pulsa en `t = 0` → `SFX_CARD_OK` y LED parpadeando; `t = 0,5` → «puerta abierta» y empieza la hoja; `t = 1,7` → `ABIERTA`. El jugador puede cruzar desde `t = 0,5 + (0,5 ÷ v_caminar)`. No cuenta el gesto `HAND_CARD_SWIPE` (≤ 1,0 s, de 2): corre en paralelo (regla 8).

**F2 · Puerta A**

`T_A = t_apertura_s` desde la escritura de `archivo_abierto` (1,2 s). Ejemplo (ejemplo de F4 del marco de puzles): P1 se resuelve en `t = 20,0`; la hoja empieza en `t = 20,0` (mismo paso que el aviso) y termina en `t = 21,2`; la cámara vuelve en `t = 22,0` (`close_view_after_s` = 1,5 s + vuelta) y el jugador ve la puerta ya abierta. **Restricción:** `t_apertura_s` ≤ `close_view_after_s` + vuelta de cámara (≈ 2,0 s) para que la puerta no se abra a la vista del jugador a medias; con 2,0 s es el límite.

**F3 · Ángulo de hoja**

`θ(t) = 90° · s(clamp(t ÷ t_apertura_s, 0, 1))`, con `s(x) = 3x² − 2x³` (suavizado: arranque y llegada lentos). `t` = tiempo de juego desde el primer paso de `ABRIÉNDOSE`. Rango `θ` ∈ [0°, 90°]; ejemplo: `t = 0,6 s` → `x = 0,5` → `s = 0,5` → `θ = 45°`; `t = 0,3 s` → `x = 0,25` → `s = 0,156` → `θ ≈ 14°`. Sin comportamiento de juego asociado: la colisión se retira en `t = 0` (regla 9).

**F4 · Activación del ascensor y enfriamiento de la línea**

`t_activo = t_llamada_completada + t_ascensor_s` (2,0 s, slice C.7); `DISPONIBLE` si `t_ahora ≥ t_activo`, o desde la carga si el hecho ya era verdadero. `MEGA_03` suena si `t_ahora − t_última_MEGA_03 ≥ enfriamiento_linea_s` (8 s†; ≥ duración de la línea + 2 s de margen). Ejemplo: usos en `t = 0, 3, 9, 10` s sin llamada → `MEGA_03` suena en `t = 0` y `t = 9`; en `t = 3` y `t = 10` solo pie + clic.

## Edge Cases

- **If el jugador pulsa un lector `LISTO` y, antes de `t_lectura_s`, pulsa el otro lector de D** (`C07`/`D06`): el segundo ve el lector en `LEYENDO` y `can_interact` = `NO` (o, si el estado cambió entre el paso de física y la pulsación, `interact()` devuelve `SIN_EFECTO`). Una sola apertura, un solo «puerta abierta».
- **If el jugador cierra el juego durante `LEYENDO` o `ABRIÉNDOSE`:** no se guarda nada de este sistema. Al reanudar, B y D están `CERRADAS`, `tarjeta_B/D` siguen verdaderas y la puerta se abre de nuevo con la misma tarjeta; la causa `door_opened:<ID>` pudo o no haber llegado a disco, sin diferencia observable (AC-41b de 5).
- **If `archivo_abierto` es verdadero al cargar** (reanudación tras P1): A nace `ABIERTA` sin animación, sonido ni «puerta abierta» (regla 5). Evita un guardado espurio al reanudar.
- **If el jugador reanuda con `tarjeta_D` verdadero, `caja_completa` verdadero y la llamada pendiente:** aparece en el despacho de Vera (siempre); B y D cerradas no bloquean nada, porque la llamada solo exige estar en el despacho y el ascensor no depende de ellas (regla 18(e)).
- **If el jugador intenta usar `C08` antes de la llamada y repite la pulsación 30 veces:** el pie y el clic repiten; `MEGA_03` suena como máximo una vez por `enfriamiento_linea_s`. Sin consecuencias (regla 15).
- **If `llamada_completada` pasa a verdadero mientras el jugador ya está mirando `C08` inactivo:** en el siguiente paso de física `C08` es `ESPERA` (`NO`: pierde el foco y el icono); a los 2,0 s pasa a `DISPONIBLE` (`SI`) y el icono vuelve si sigue apuntándolo. No hay sorpresa: el ascensor se reactiva con la luz del pasillo (slice C.7, +2,0).
- **If el jugador está en el despacho de Vera durante la llamada** (siempre: slice C.7 «el juego espera en el despacho») y la llamada termina: el ascensor se activa a 2,0 s; el jugador llega después (la distancia al hueco, ≥ 2 m, lo hace posible con holgura); si llegara antes (herramientas), `ESPERA` lo oculta.
- **If `interact(Entrar)` se acepta pero 21 no responde** (aviso perdido): `C08` queda `EN_USO` (sin icono). Defecto de integración, no de jugador: 21 tiene el tope propio de `sin control` y 4 la regla 13. 8 no reintenta ni emite «ascensor llamado» dos veces. *(Prueba de integración AC-10.)*
- **If el jugador está en el hueco de la puerta cuando empieza `ABRIÉNDOSE`:** imposible para B y D (la puerta está cerrada y el jugador, en el pasillo, queda a ≥ 0,25 m por la cápsula; la hoja gira hacia dentro, hacia el otro lado). Para A, el jugador está ante el panel `C05` o en el pasillo; la hoja gira hacia dentro del Archivo; sin solape. Si por herramientas hubiera solape, D-19 de 2 lo admite: la hoja no colisiona.
- **If un lector `SIN_TARJETA` se pulsa con la tarjeta del otro lector en el bolsillo** (p. ej. `C06` con solo `tarjeta_D`): mismo `SIN_EFECTO` y mismo pie. No hay selección de tarjeta: el sistema comprueba el hecho de su puerta (el jugador no elige tarjeta, regla 7); no existe una «tarjeta equivocada».
- **If 20 escribe `tarjeta_B` en el mismo fotograma en que el jugador pulsa `C06`:** el estado se calcula por lectura directa; ese fotograma se resuelve con el valor vigente al llamar a `can_interact`/`interact`. Si el valor cambió entre ambos, `interact()` lo vuelve a leer (regla 8) y actúa con el actual.
- **If el hecho `tarjeta_B/D` es falso pero el jugador ya abrió la puerta en esta sesión** (herramienta de desarrollo, CA-28 de 3): la puerta sigue abierta (regla 10); el lector queda en `ABIERTO`.
- **If falta un ancla `door_slot_*` o un hecho, o un ID de lector no está en el catálogo de 7:** regla 19 (falla abierto; error visible en desarrollo; CI en rojo).
- **If el jugador abre la pausa durante `LEYENDO`, `ABRIÉNDOSE` o `ESPERA`:** los temporizadores se detienen (regla 20) y se reanudan al volver; no se pierde la apertura.
- **If se carga `recepcion`** (escena aparte): este sistema no existe allí; la puerta de salida de Recepción es decorado y los pasos de ascensor en Recepción los pone 21.
- **If `reducir_sobresaltos` está activo:** sin efecto en este sistema. La megafonía `MEGA_03` no es un susto (voz grave, sin pico); `SFX_CARD_OK` es un clic suave.

## Dependencies

| Sistema | Tipo | Qué da 8 | Qué recibe 8 | Regla / AC citado |
|---|---|---|---|---|
| **3 Estado y bus de eventos** | Dura | Aviso «puerta abierta» (`A|B|D`), «ascensor llamado», «línea pedida» (emisor); ningún hecho | Lee `archivo_abierto`, `tarjeta_B`, `tarjeta_D`, `llamada_completada`; suscripción por hecho a `archivo_abierto`; monotonía de las tarjetas | 3 reglas 9 y 10; CA-03; tabla de hechos (dueño de `tarjeta_B/D` = 20, lector = 8) |
| **7 Interacción e inspección** | Dura | Manejadores `can_interact`/`interact`/`etiqueta` de `C06`, `C07`, `D06`, `C08`; claves de texto | Objetivo, gesto reservado `HAND_CARD_SWIPE`/`HAND_REACH`, pie de texto, `SFX_CLICK_SUBTLE`, `bloquear_contexto` | 7 reglas 3, 6, 11, 12, 26, 30; tabla de objetos (filas `C06/C07/D06` y `C08`); AC-V8 |
| **4 Escena de planta** | Dura | Puertas, lectores y ascensor que llenan los huecos | `door_slot_a/b/d/elevator`, geometría, orden de arranque 7 → 9 → resto, regla de colisión de puertas | 4 reglas 3, 9 (paso 6), 13, 14, 18(b) y (e) |
| **5 Guardado y carga** | Blanda | «Puerta abierta» (causa `door_opened:<ID>`); puertas B y D reconstruibles cerradas | Causa `door_opened`, `card_acquired`, reanudación en el despacho | 5 reglas 3 y 6, D-24, D-29; AC-41b |
| **9 Marco de puzles** | Blanda | Hoja de la puerta A que ejecuta `ANIM_DOOR_OPEN` | Hecho `archivo_abierto` y `SFX_UNLOCK` (9 es dueño del hecho y del sonido) | 9, fila «8 Control de acceso» de Interactions; ejemplo de F4 |
| **18 Base de contenido narrativo** | Dura | Claves pedidas: `OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08`, línea `MEGA_03` | Textos de objeto y de «puerta cerrada» | 18 Dependencies (fila 7·8) |
| **2 Jugador en primera persona** | Blanda (indirecta) | Hoja sin colisión al abrirse; huecos de 1,00 m | Gesto `HAND_CARD_SWIPE`, cápsula, no empuja | 2 regla 1, D-19, AC-07; catálogo de gestos |
| **20 Documentos y bolsillo** | Blanda | Nada (8 no escribe) | Escribe `tarjeta_B/D` al recoger `I-02/I-03` | Slice D.1/D.2; 3 CA-03 |
| **21 Director de escenas** | Blanda | Aviso «ascensor llamado» | Decide la transición a Recepción, el `sin control` y el fundido | 4 regla 13; slice C.8 |
| **22 Llamada** | Blanda | Nada | Escribe `llamada_completada` | Slice C.7 |
| **23 Audio** | Blanda | Peticiones de sonido: `SFX_CARD_OK`, `ANIM_DOOR_OPEN`, línea `MEGA_03` | Reproducción 3D, ducking de la megafonía | Reglas 8, 15, 17 |
| **28/29 Atmósfera y arte** | Blanda | Estados visibles del lector (LED), hoja | Material, luz del LED | Regla 17 |

**Recíprocos (los otros GDDs deben listar a 8):** 3 (ya lo lista, fila «8 Control de acceso»: Dura), 4 (fila «8 Control de acceso»: Dura, ya lo lista), 5 (fila «8 Control de acceso · 9 a 16 · 20»: Blanda, ya lo lista), 7 (fila «8 Control de acceso»: Dura, ya lo lista), 9 (fila «8 Control de acceso»: indirecta, ya lo lista). 2 (indirecta, ya lo lista), 18 (Dura, ya lo lista). Pendiente de que 20, 21, 22 y 23 lo listen al redactarse.

## Tuning Knobs

| Knob | Valor | Rango seguro | Qué afecta | Fuente |
|---|---|---|---|---|
| `t_lectura_s` | 0,5 s† | 0,2 a 1,0 | Pausa entre pasar la tarjeta y que la hoja empiece; por debajo de 0,2 el LED no se aprecia; por encima de 1,0 el jugador cree que falló | F1 |
| `t_apertura_s` | 1,2 s | 0,8 a 2,0 | Duración de `ANIM_DOOR_OPEN`; fijo por el slice A.0. Un valor > 2,0 rompe F2 | Slice A.0 |
| `angulo_apertura_deg` | 90 | 80 a 100 | Hoja abierta; > 100 invade mobiliario cercano (D: perchero en X 19,8) | Regla 9 |
| `t_ascensor_s` | 2,0 s | 0 a 4,0 | Retraso del ascensor tras la llamada; coherente con el restablecimiento de luces | Slice C.7, F4 |
| `enfriamiento_linea_s` | 8 s† | 5 a 20 | Frecuencia de `MEGA_03`; menos de 5 solapa la línea | F4, regla 15 |
| `bisagra` (por puerta) | oeste (B, D), este (A) | oeste/este | Lado libre del marco para el lector | Regla 9 |
| `led_brillo_*` | ver 28 | n/a | Brillo del LED en los tres estados; mantener ≥ 30 % de diferencia entre estados (cue no solo cromático) | Regla 17 |
| `texto_*` (claves OBJ) | n/a | ≤ `texto_max_caracteres` (90†, 7) | Longitud de los pies | 7 regla 12 |

Todos están en `assets/data/access/access.json` (regla 3). † = valor propuesto, a validar en prototipo gris o playtest. Los tiempos no son ajustes del jugador (el ajuste de pie `multiplicador_pie` ya lo gestiona 7).

## Visual/Audio Requirements

- **Hoja:** giro de 90° hacia el interior de la sala, `ANIM_DOOR_OPEN` (1,2 s, F3). Sin chirrido agudo (con `reducir_sobresaltos` ya queda mínimo). La puerta A usa además `SFX_UNLOCK` de 9; B y D usan `SFX_CARD_OK` ‡ del lector.
- **Lector:** pieza pequeña con LED de tres estados (regla 17); en la oscuridad de la escena 7 el LED es la única luz de la zona y no debe sobreexponer.
- **Audio nuevo propuesto:** `SFX_CARD_OK` ‡ (clic suave de cierre, 0,3 s), `MEGA_03` ‡ (voz de megafonía, pendiente de ID y texto final en 18). No existe `SFX_DENY`: el rechazo es `SFX_CLICK_SUBTLE` de 7.
- **Iluminación y ambiente por puerta (guía al art-director):** el interior de A se ve al abrir con su tubo fluorescente parpadeando (slice A.4); el de B, lámparas ámbar; el de D, lámpara de escritorio. Lo que se ve tras la hoja debe ser el primer «premio» visual de la puerta.

## UI Requirements

Ninguna pantalla. Solo los pies de texto de 7/24 (`OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08`), el icono de acción de 24 con las etiquetas «Usar» y «Entrar», y el LED físico del lector. Sin mensajes en pantalla de «puerta bloqueada» ni contadores.

## Acceptance Criteria

Tipos: **L** = lógica (prueba automatizada en `tests/unit/access/`), **I** = integración (`tests/integration/access/`), **PV** = playtest o verificación visual (captura retenida en `production/qa/evidence/`).

- **AC-01 (R5, L):** **GIVEN** `archivo_abierto` falso, **WHEN** se configura la escena, **THEN** A está `CERRADA` con la colisión activa; **GIVEN** `archivo_abierto` verdadero, **THEN** A está `ABIERTA` sin colisión y no se emite «puerta abierta».
- **AC-02 (R5, R12, L):** **GIVEN** `tarjeta_B` y `tarjeta_D` verdaderos y un cierre normal, **WHEN** se continúa, **THEN** B y D nacen `CERRADAS`, los lectores en `LISTO` y no se emite ningún «puerta abierta» al cargar. *(Cubre AC-41b de 5.)*
- **AC-03 (R6, R9, I):** **GIVEN** A `CERRADA`, **WHEN** 9 escribe `archivo_abierto` = verdadero en `t = 20,0`, **THEN** en `t = 20,0` A está `ABRIÉNDOSE` sin colisión, se emite «puerta abierta» (`A`) una vez, y en `t = 21,2 ± 0,05` está `ABIERTA`; `SFX_UNLOCK` no lo reproduce 8.
- **AC-04 (R7, L):** **GIVEN** `tarjeta_B` falso y B `CERRADA`, **THEN** `C06.can_interact(Usar)` = `SIN_EFECTO`; **GIVEN** `tarjeta_B` verdadero, **THEN** = `SI`; **GIVEN** `tarjeta_D` verdadero y `tarjeta_B` falso, **THEN** `C06` sigue `SIN_EFECTO` y `C07` es `SI`.
- **AC-05 (R8, F1, I):** **GIVEN** `tarjeta_B` verdadero y B `CERRADA`, **WHEN** el jugador usa `C06` en `t = 0`, **THEN** `interact()` devuelve `HECHO`, suena `SFX_CARD_OK`, en `t = 0,5` se emite «puerta abierta» (`B`), la hoja empieza y la colisión se retira, y en `t = 1,7 ± 0,05` está `ABIERTA`.
- **AC-06 (R7, R8, L):** **GIVEN** B `ABRIÉNDOSE` o `ABIERTA`, **WHEN** se pulsa `C06`, **THEN** `can_interact` = `NO` (sin icono) y `interact()` devuelve `SIN_EFECTO` sin emitir aviso; **GIVEN** D abierta por `C07`, **THEN** `D06` también es `NO`. Una apertura = un aviso.
- **AC-07 (R10, L):** **GIVEN** cualquier puerta `ABIERTA`, **WHEN** transcurre cualquier tiempo o un hecho de tarjeta cambia (incluso forzado a falso), **THEN** la puerta sigue `ABIERTA` y no vuelve a colisionar.
- **AC-08 (R10, R18, PV):** **GIVEN** un jugador de prueba que entra en D, completa la caja y sale con `caja_completa`, **THEN** la puerta D está abierta y el jugador cruza el hueco de 1,00 m sin roce (AC-07 de 2).
- **AC-09 (R13, R15, I):** **GIVEN** `llamada_completada` falso, **WHEN** el jugador usa `C08` en `t = 0, 3, 9, 10 s`, **THEN** `interact()` devuelve `SIN_EFECTO` las cuatro veces, se emite «línea pedida» (`MEGA_03`) solo en `t = 0` y `t = 9`, y no se emite «ascensor llamado».
- **AC-10 (R13, R14, I):** **GIVEN** `llamada_completada` escrito verdadero en `t = 0`, **THEN** `C08` es `NO` hasta `t = 2,0` y `SI` desde entonces; **WHEN** se usa, **THEN** se emite «ascensor llamado» una vez, `C08` pasa a `EN_USO` y no responde a más pulsaciones.
- **AC-11 (R13, L):** **GIVEN** `llamada_completada` verdadero ya al configurar, **THEN** `C08` nace `DISPONIBLE` sin espera.
- **AC-12 (R3, R19, L):** **GIVEN** un `access.json` con un ancla, hecho o lector inexistente, **THEN** en desarrollo hay error visible; en la build final la puerta afectada se crea `ABIERTA`, se registra una línea y no hay fallo de carga; el CI marca la build como rota.
- **AC-13 (R20, L):** **GIVEN** la pausa abierta durante `LEYENDO` o `ABRIÉNDOSE`, **THEN** ninguna transición avanza hasta reanudar.
- **AC-14 (R11, L):** **GIVEN** que 8 emite «puerta abierta» (`B`), **THEN** Guardado recibe la causa `door_opened:B` y los 19 hechos intactos (8 no escribe ningún hecho: ningún hecho cambia por su acción). *(Se cierra cuando existan 5 y 8.)*
- **AC-15 (R16, R17, PV):** **GIVEN** un lector en los tres estados, **THEN** el LED se distingue sin depender del tono (brillo y patrón distintos, captura retenida) y el rechazo no usa rojo ni sonido de error.
- **AC-16 (R2, PV):** **GIVEN** la partida completa de un tester, **THEN** el jugador nunca queda sin forma de avanzar por culpa de este sistema (recorrido A → B → D → C08 con y sin cierre/reanudación entre cada puerta).

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D8-01 | Las tarjetas **no se gastan** al usarlas; los hechos `tarjeta_B/D` permanecen verdaderos y las puertas B/D se reabren tras reanudar. | Tarjeta de un solo uso consumida en el lector. | Con la regla D-24 de 5 (B y D vuelven cerradas) y CA-03 de 3 (los hechos no vuelven a falso), consumirlas dejaría al jugador sin acceso tras reanudar: un softlock, contra el pilar 1. «Un solo uso» del análisis cruzado debe leerse como «llave sin sumidero» (no hay economía), no como «se consume». |
| D8-02 | Una puerta abierta **no se cierra** en la sesión. | Puertas con cierre automático o al salir. | Elimina por construcción el encierro del jugador y la necesidad de lectores interiores en A y B; la salida de D con `caja_completa` queda siempre libre (slice §8 paso 5). |
| D8-03 | Las puertas **no son interactuables**; el mensaje de «cerrada» sale del lector. | Hacer interactuable la hoja con un mensaje. | 7 regla 6 y 26 ya establecen que ninguna puerta es interactuable; el slice §8 dice «la puerta muestra un mensaje de cerrada»: el lector, pegado a la puerta, lo cumple sin tocar 7. |
| D8-04 | **Auto-selección de tarjeta**: el lector comprueba el hecho de su puerta; el jugador no elige tarjeta. | Menú o selector de inventario. | El slice no tiene menú de inventario (D.1); evita un acto de «elegir mal» (anti-castigo). |
| D8-05 | «Puerta abierta» se emite al **empezar** `ABRIÉNDOSE`. | Emitir al terminar la animación. | El guardado (no urgente, 5 regla 6) no debe depender de que el jugador espere 1,2 s; un cierre en medio de la animación no pierde nada, pero el aviso no se retrasa. |
| D8-06 | `D06` es **espejo de `C07`**, sin lógica propia. | Descartar `D06` o darle comportamiento propio (salida). | El slice A.6 lo incluye; como las puertas no se cierran, no tiene función real pero cumple el catálogo de 7 y mantiene la lectura espacial (un lector a cada lado). |
| D8-07 | El ascensor **inactivo** es objetivo con `SIN_EFECTO` + pie + `MEGA_03` con enfriamiento. | Mantenerlo `habilitado_si: llamada_completada` (oculto hasta la llamada, como dice la fila de 7). | El slice §13.3 exige que el ascensor «no responde y la megafonía indica…»: ocultar el objeto no produce esa respuesta. Requiere cambiar la fila de `C08` en 7 (Cambios requeridos). |
| D8-08 | **8 falla abierto** con datos inválidos. | Fallo de carga (regla 14 de 4). | Un fallo de carga impediría jugar; abrir la puerta no daña la historia y el CI evita el defecto. Prioridad 1: sin softlock. |
| D8-09 | Hoja de 90° hacia el **interior**, bisagra en el lado opuesto al lector. | Hacia el pasillo; puertas correderas. | 4 regla 18(b) prefiere abrir al lado contrario al paso; el pasillo mide 2,6 m y una hoja de 1,0 m lo estrecharía. El giro al interior no choca con el mobiliario de A, B ni D (comprobado con A.4 a A.6). Corredera no la pide el slice. |
| D8-10 | `t_ascensor_s` = 2,0 s **y** la lectura de `llamada_completada` por lectura directa; si ya es verdadero al cargar, sin espera. | Activación inmediata (como dice la fila de 7). | Slice C.7 «+2,0 … se activa C08», coherente con el restablecimiento de luces. |
| D8-11 | 8 **no escribe hechos**. | Un hecho `puerta_X_abierta`. | Los 20 hechos del slice son un conjunto cerrado (Anexo D.2) y el estado «abierta» no se guarda (D-24); añadir hechos contradice ambos. |
| D8-12 | La puerta A se abre por **aviso de cambio del hecho**, no por `EV_PUZZLE_SOLVED_P1`. | Suscribirse al aviso del puzle. | El hecho es la fuente de verdad (3); si el aviso se pierde, el estado de arranque igualmente es correcto. 9 ya lo prevé (fila de Interactions). |

## Open Questions

1. **ID y texto de la megafonía de ahorro energético.** El slice §13.3 da el texto («Planta en modo de ahorro energético») sin ID, mientras §12 dice que cada línea tiene uno. Se propone `MEGA_03` ‡ y que 18 pase de 27 a 28 entradas. *Dueño:* narrative-director / 18. *Efecto:* añadir una línea de contenido al slice (alcance menor: ya exigida por §13.3).
2. **Mecanismo de peticiones de sonido 3D a 23.** 8 pide efectos en un lector o hueco y una línea de megafonía; 23 no tiene GDD. Debe confirmar la interfaz (¿aviso «línea pedida» también para efectos?). *Dueño:* 23 / audio-director.
3. **Variante de la tarjeta en `HAND_CARD_SWIPE`.** El gesto muestra la tarjeta `I-02` en `C06` y `I-03` en `C07`/`D06`; el catálogo de gestos de 2 no lo parametriza. *Dueño:* 2 / 7 (proponemos que 7 pase el `tarjeta_item` de 8).
4. **¿Debería 17 (pistas) ofrecer una pista si el jugador intenta un lector sin tarjeta repetidas veces?** El slice no lo pide; el camino crítico ya pasa por el Archivo (P1, con pistas). *Dueño:* 17.
5. **Texto final de los pies** (`OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08`): tono neutro, sin juicio ni confirmación (regla 16). *Dueño:* 18 / narrative-director.

## Cambios requeridos en otros GDDs

| GDD | Cambio | Regla de este GDD |
|---|---|---|
| **3 Estado y bus de eventos** | En la tabla de la regla 10: declarar los avisos de 8: «puerta abierta» (`A|B|D`; quitar ‡), «ascensor llamado» (sin datos; consume 21) y 8 como emisor de «línea pedida» (con 9). Confirmar que 8 no escribe hechos. | 11 |
| **4 Escena de planta** | Confirmar que `door_slot_*` y `door_slot_elevator` solo reciben la puerta/ascensor de 8; añadir 8 al orden de arranque («resto», paso 6) con falla abierta (no fallo de carga) y que la regla 13 sigue siendo la red de seguridad del ascensor. | 5, 14, 19 |
| **5 Guardado y carga** | Confirmar que el `<ID>` de `door_opened:<ID>` es `A`, `B` o `D`; que «puerta abierta» llega al empezar `ABRIÉNDOSE`; marcar AC-41b de 5 como cubierto por AC-02 de este GDD. | 11, 12 |
| **7 Interacción** | (a) Fila de `C08`: **quitar** `habilitado_si: todos [llamada_completada]` y delegar `can_interact` a 8 (para que el ascensor inactivo sea objetivo con `SIN_EFECTO`, slice §13.3); (b) fila de lectores: `can_interact` = `NO` cuando la puerta está `ABRIÉNDOSE/ABIERTA` (compatible con «siempre»); (c) añadir las claves `OBJ_C06/C07/D06/C08`; (d) pasar `tarjeta_item` a `HAND_CARD_SWIPE`. | 7, 13, 15 |
| **9 Marco de puzles** | Aclarar en la fila de 8 que `SFX_UNLOCK` es de 9 y `ANIM_DOOR_OPEN` de 8, y que 8 reacciona al **hecho** `archivo_abierto`, no al aviso del puzle. | 6 |
| **18 Base de contenido** | Pedir claves `OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08`; línea `MEGA_03` (28 entradas); aclarar que no hay mensaje distinto para «tarjeta equivocada». | 16, 15 |
| **2 Jugador** | Variante de tarjeta en `HAND_CARD_SWIPE` (pregunta abierta 3); confirmar que 8 retira la colisión de la hoja en el primer paso de `ABRIÉNDOSE`. | 8, 9 |
| **23 Audio (al redactarse)** | Reproducir `SFX_CARD_OK`, `ANIM_DOOR_OPEN` (sonido) y `MEGA_03` por `C01`. | 8, 15, 17 |
| **21 Director de escenas (al redactarse)** | Consumir «ascensor llamado», tomar `sin control` en el mismo fotograma, ordenar la carga a 4. | 14 |
| **Informe cruzado `gdd-cross-review-2026-11-09.md` (nota de lectura)** | Sustituir «llaves de un solo uso» por «llaves sin sumidero (no se gastan)» para la economía de tarjetas. | D8-01 |
| **Índice de sistemas** | Fila 8: estado → «Borrador (lote Feature 1)»; dependencia 3, 7, 18 → añadir 4 (dura) y 5/9/20/21/23 (blandas). | Dependencies |

## Entradas para el registro

Formato de `design/registry/entities.yaml` (todas con `source: design/gdd/control-de-acceso.md`, `added: 2026-11-09`):

| Nombre | Valor | Unidad | Referenciada por | Nota |
|---|---|---|---|---|
| `door_open_duration_s` | 1,2 | s | 9, 4 | Duración de `ANIM_DOOR_OPEN`; slice A.0; F2 |
| `card_read_delay_s` | 0,5 | s | — | Pausa entre pasar la tarjeta y la hoja (propuesta) |
| `elevator_activation_delay_s` | 2,0 | s | 21 | Slice C.7 |
| `elevator_deny_line_cooldown_s` | 8 | s | 23 | Enfriamiento de `MEGA_03` |
| `door_open_angle_deg` | 90 | ° | 4 | Giro al interior |
| `door_state` | `CERRADA`/`ABRIÉNDOSE`/`ABIERTA` | enum | 5 | No se guarda (D-24 de 5) |
| `elevator_state` | `INACTIVO`/`ESPERA`/`DISPONIBLE`/`EN_USO` | enum | 21 | No se guarda |
| `door_ids` | `A`, `B`, `D` | — | 5 | Datos del aviso «puerta abierta» y de la causa `door_opened:<ID>` |
| `MEGA_03` | «Planta en modo de ahorro energético» | línea | 18, 23 | Propuesta ‡ (pregunta abierta 1) |
| `SFX_CARD_OK` | — | sonido | 23 | Propuesta ‡ |
| Avisos | «puerta abierta» (8), «ascensor llamado» (8) | aviso | 3, 5, 21 | Emisor 8 |

## Historial

| Versión | Fecha | Cambio |
|---|---|---|
| 0.1 | 2026-11-09 | Borrador (lote Feature 1): 20 reglas, 4 fórmulas, 16 AC, 12 decisiones, 5 preguntas abiertas. Pendiente de review independiente. |
