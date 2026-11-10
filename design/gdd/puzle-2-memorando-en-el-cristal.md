# Puzle 2 · Memorando en el cristal

> **Status**: Revisado (ronda de corrección 10) — pendiente de re-review (ronda 10: D12-26)
> **Author**: Álvaro + agentes (`game-designer`)
> **Last Updated**: 2026-11-09 (ronda de corrección 7)
> **Sistema**: 12 (índice: `design/gdd/systems-index.md`) · Layer `Feature` · Categoría `Gameplay` · Prioridad `MVP`
> **Fuente de verdad**: `design/slice/slice-v0.3.md` (§10.2, §19.2, Anexo A.5, B.2, C.5, D.2; contenido v0.4.2). Prevalece sobre este GDD.
> **Marco**: `design/gdd/marco-de-puzles.md` (9). Este GDD **instancia** el contrato del marco para el P2; no lo redefine.
> **Implements Pillar**: Autonomía como progresión (el jugador decide qué lámpara tocar y cuándo; nada le dice la solución) · Tensión sin castigo (no existe el fallo; ninguna posición es «mala») · El espacio expresa la emoción (el sentido llega por luz y reflejo, no por texto) · Información incompleta (entrega la versión oficial: un hecho, no una intención)

## Summary

En la Sala de Reuniones hay tres lámparas de escritorio (`B01` izquierda, `B02` central, `B03` derecha) y un ventanal de cristal (`B04`) con un memorando escrito al revés. Cada lámpara tiene cuatro posiciones y, en cada una, su haz apunta a un punto distinto del cristal; solo **un** punto por lámpara contiene un fragmento del memorando (F1, F2 o F3). Cuando el haz cae sobre su fragmento, el texto se vuelve legible; cuando las tres lámparas iluminan su fragmento a la vez, el memorando queda completo y permanente. No hay fallo, ni contador, ni llave: la recompensa es **leer la versión oficial de Dirección** («aprobado a petición de la interesada» pero «ratificación pendiente de firma del responsable»), que contradice el formulario del Archivo. Este GDD instancia el contrato de `marco-de-puzles.md` (9) para el P2: modo `WORLD`, política `ON_CHANGE`, feedback `PARTIAL` por fragmento, `persist` de `pos_L`, `pos_C` y `pos_R`.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `7 Interacción e inspección` (verbo `Girar`, manejador de `B01`–`B03`), `9 Marco de puzles` (ciclo de vida, hechos, pistas), `18 Base de contenido` (`DOC_01` por fragmentos, `PISTA_P2_N1`) · lo consumen: `21` (`EV_PUZZLE_SOLVED_P2` → `VO_V_08`), `28`/`29` (reflejo del cristal; 29 Dura, la declara 29); `17` **no** lee `memo_leido` (solo `request_hint`, D17-10) · espacio de estados: 4³ = 64 combinaciones, una solución (3, 1, 4)

## Overview

**Qué es.** Un puzle de estado en el mundo (`mode: WORLD`, sin vista cercana ni cursor): el jugador pulsa la base de una lámpara (verbo `Girar` de 7) y esta avanza a su siguiente posición (1→2→3→4→1). El marco (9) escribe la posición en el hecho `pos_L`, `pos_C` o `pos_R` en el mismo fotograma y llama a `evaluate()` sin retraso (`ON_CHANGE`). El controlador del P2 (este GDD) responde con un veredicto: `NONE` (ningún fragmento iluminado), `PARTIAL` (uno o dos fragmentos, con el conjunto `progress`) o `SOLVED` (los tres). El marco decide qué ocurre con cada veredicto (regla 10 de 9).

**Qué pregunta responde (función narrativa, slice §10).** «¿Qué dice oficialmente Dirección?». La respuesta es un hecho observable —el memorando existe, dice «a petición de la interesada» y deja la ratificación pendiente—, nunca una intención (pilar *Información incompleta*). El puzle no confirma quién firmó ni por qué.

**Qué lo hace distinto de los demás.** Es el único puzle sin fallo posible (B.2: «el fallo no existe»), el único que se resuelve desde la exploración sin abrir una vista, y el único cuyo estado intermedio se **guarda** (las tres posiciones). Tampoco bloquea nada: ni puerta ni compartimento dependen de `memo_leido` (grafo del slice §8; D-16). Lo lee solo el sistema 17.

**Qué entrega.** El hecho `memo_leido` (bool, solo ida), el aviso `EV_PUZZLE_SOLVED_P2` y el memorando completo legible en el cristal (`DOC_01`). Sin ítem ni llave. Tras resolverse, las lámparas quedan inertes (D9-7).

**Loops (nested loop model).** *Micro (≈ 3 s):* pulsar una lámpara, ver girar la cabeza, ver si aparece texto en el cristal. *Meso (≈ 1–4 min, F7 de 9 pide 3–6, ver Q12-2):* descubrir que las lámparas apuntan a algo → probar cada una → leer. *Macro:* el memorando entra en la reconstrucción de la cronología (formulario firmado «antes» de la confirmación vs. memorando con ratificación pendiente).

## Player Fantasy

Vera no «resuelve un acertijo»: **mira un cristal oscuro en una sala vacía, mueve una luz cálida y, de pronto, el cristal le habla**. El texto estaba ahí desde el principio, escrito al revés, esperando el ángulo justo. La emoción que debe sentir el jugador es la de **descubrir algo que ya estaba allí** —la versión oficial— y percibir, sin que nadie se lo diga, que no cuadra con lo que ha leído abajo, en el Archivo.

Estética principal (MDA): **Sensation** (luz ámbar contra cristal frío, el hum del vidrio, la lluvia al otro lado; pilar *El espacio expresa la emoción*) y **Discovery** (rango 2 del juego). Secundaria: **Narrative**. **Challenge** es deliberadamente la más baja de los seis puzles: el P2 es un respiro de mecánica sencilla entre el panel del P1 y la caja del P3 al P6 (sierra de dificultad del marco). SDT: **Competencia** (cada giro tiene respuesta inmediata y legible; el jugador sabe por qué una lámpara «acierta»), **Autonomía** (puede ir a la Sala B antes o después de D, resolver las lámparas en el orden que quiera, o no resolver el puzle). Tipo de jugador: Explorer (Bartle) y Discovery/Immersion (Quantic Foundry).

**Lo que no debe sentir:** un candado que hay que forzar por tanteo ciego, un examen, ni que una lámpara está «mal». Ninguna posición es un error: solo hay posiciones que aún no dicen nada (pilar *Tensión sin castigo*).

## Detailed Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado. † = valor propuesto, a validar en playtest. Reglas propias numeradas **R1…R32**; «regla N de 9» es siempre una regla de `marco-de-puzles.md`. Los IDs del slice (`B01`–`B08`, `F1`–`F3`, `pos_L`, `memo_leido`, `SFX_GLASS_HUM`, `VO_V_08`, `DOC_01`) se conservan.

### A. Identidad, estado y reparto de responsabilidades

**R1. Identidad.** `id` = `P2`; `mode` = `WORLD` (modo `MUNDO` en 7 y en la prosa; mismo modo); `elements` = `B01` (lámpara L), `B02` (lámpara C), `B03` (lámpara R); `solved_flag` = `memo_leido`; `validation.policy` = `ON_CHANGE`; `resolution.kind` = `IMMEDIATE`. El ventanal `B04` **no es interactuable** (D7-18 de 7; `interactuable: false` en `cobertura_anexo_a.json`, **fichero planificado que hoy no existe** en `assets/data`; solo lo menciona `design/registry/entities.yaml`: ver «Cambios requeridos»): sus fragmentos son consecuencia de `B01`–`B03`, no un objetivo. `B08` (marcas del suelo) tampoco es interactuable.

**R2. Estado público.** `requires.all` = `[]`: el P2 está `ACTIVO` desde el arranque del juego, no `BLOQUEADO`. La puerta de la Sala B la gobierna 8 (`tarjeta_B` en `C06`), no el puzle (B.2: «Estado: `ACTIVO` al entrar en la sala»). Pasos permitidos: `ACTIVO → RESUELTO`; nunca hacia atrás (regla 6 y S2 de 9).

**R3. Reparto.** El controlador del P2 (`P2Controller`, hereda de `PuzzleController`, regla 9 de 9) **solo devuelve veredictos y presenta**: no escribe hechos, no emite avisos, no cambia el estado público (regla 10 de 9). **9 escribe** `pos_L`, `pos_C`, `pos_R` (en cada cambio, regla 22 de 9), `memo_leido`, y emite `EV_PUZZLE_SOLVED_P2`. Este GDD **no escribe ningún hecho**.

**R4. Ningún otro sistema depende del P2 para avanzar.** Ni puertas (8), ni compartimentos (10), ni la llamada (22) leen `memo_leido` ni `pos_*`. `memo_leido` no tiene lector en el slice: 17 **no** lo lee (`sistema-de-pistas.md` D17-10; 3 ya lo anota sin 17). Saltarse el P2 no bloquea nada y no tiene coste (pilar *Autonomía como progresión*).

### B. Estado inicial y posiciones

**R5. Estado inicial (slice A.5, D.2).** Las tres lámparas están en la posición **2**: `pos_L = pos_C = pos_R = 2` (tipo `int`, rango 1 a 4). Con ese estado:
- `B01` (L, pos 2) apunta al **sello de Dirección** (distractor): el sello es visible en el cristal desde el primer momento (R14).
- `B02` (C, pos 2) y `B03` (R, pos 2) apuntan a puntos vacíos: no revelan nada.
- Ningún fragmento está iluminado: `progress = {}`, veredicto `NONE`.
- El estado inicial **no** satisface la solución (validación de la regla 29 de 9: 2,2,2 frente a 3,1,4).

**R6. Cuatro posiciones por lámpara.** Cada lámpara tiene las posiciones 1, 2, 3 y 4 (`int`). La posición determina **a qué punto del cristal apunta el haz** (R9). Las marcas `B08` del suelo (arcos de cuatro marcas numeradas a 1,0 m de cada lámpara, slice A.5) corresponden a esas cuatro posiciones.

**R7. Cómo cambia una lámpara de posición.** El jugador apunta a la base de la lámpara (collider de `B01`/`B02`/`B03`, prioridad 1 en 7) y activa el verbo **`Girar`** (`interactuar`, etiqueta «Girar»). Cada activación válida avanza **un paso y un solo sentido**: `pos' = (pos mod 4) + 1` (1→2→3→4→1). No hay retroceso, no hay salto directo a una posición, no hay arrastre (B.2: «`CLICK` en la base avanza su posición de 1 a 4 y vuelve a 1 tras el 4»). Para el jugador, desde la posición 2 llegar a la 1 cuesta 3 pulsaciones (F2).

**R8. Atomicidad del cambio.** Una activación hace, en este orden y en el mismo fotograma: (1) 7 llama a `interact(Girar, ctx)` del marco, que la reenvía a `handle_activation(element_id, 'Girar')` del controlador; (2) el controlador avanza su posición interna y devuelve `HECHO`; (3) el marco escribe el hecho de esa lámpara (`pos_L`, `pos_C` o `pos_R`); (4) el marco llama a `evaluate()` (`ON_CHANGE`, sin retraso; regla 12 de 9) y procesa el veredicto; (5) 7 reproduce `gesto_hecho` (`HAND_TURN`, ≤ 0,8 s, Jugador); el marco no reproduce ningún gesto de mano. El feedback sonoro o visual de un veredicto se emite en el mismo fotograma (regla 13 de 9).

**R9. Mapa de apuntado.** Cada pareja (lámpara, posición) apunta a un punto del cristal. Los 12 puntos son **distintos y no se solapan entre sí** (R10). Contenido (slice B.2, fuente de verdad):

| Lámpara | Pos. 1 | Pos. 2 | Pos. 3 | Pos. 4 |
|---|---|---|---|---|
| `B01` (L) | vacío | **sello** (distractor) | **F1** | vacío |
| `B02` (C) | **F2** | vacío | vacío | vacío |
| `B03` (R) | vacío | vacío | vacío | **F3** |

Fragmentos (`DOC_01` partido en tres por 18, regla 10 de 18): **F1** «Traslado de Vera: aprobado a petición de la interesada.» · **F2** «Ratificación pendiente» · **F3** «de firma del responsable.» Concatenados en orden, con espacios, son el texto de `DOC_01`. El mapa vive en `puzzles.json` (Datos del puzle); el controlador no lo contiene.

**R10. Independencia de las lámparas (requisito de diseño y de nivel).** El haz de una lámpara solo puede iluminar **sus propios** puntos. Ninguna lámpara ilumina el fragmento de otra, y el estado de una no altera lo que muestra otra. Consecuencias exigidas a 4/arte: (a) los 12 puntos no se solapan; (b) el área del cristal iluminada por un haz no cubre el punto de otra lámpara. Sin esto, el puzle dejaría de ser descomponible por lámpara y el análisis de F1–F3 no valdría.

### C. Qué se ve en el cristal (feedback `PARTIAL`)

**R11. Visibilidad por punto.** Un fragmento está **iluminado** (y legible) si y solo si su lámpara está en la posición que apunta a él (R9). El sello está iluminado si y solo si `pos_L = 2`. Un punto vacío no muestra nada. La visibilidad lógica es **instantánea** (se calcula en el fotograma del cambio); la presentación fundida dura `fragment_fade_s` = **0,8 s** (slice B.2), tanto al encenderse como al apagarse.

**R12. Veredictos.** `evaluate()` es una función pura del estado de las tres lámparas y de la definición:
- `progress` = conjunto de IDs de fragmento iluminados (⊆ {F1, F2, F3}). El sello **no** cuenta.
- `progress = {F1, F2, F3}` → `SOLVED`.
- `progress` con 1 o 2 elementos → `PARTIAL` (con `progress`).
- `progress = {}` → `NONE`.
- **Nunca devuelve `REJECT`** (regla 15 de 9: un `REJECT` en P2 se trata como `NONE` y se registra como error de datos).

**R13. Feedback sonoro (regla 13b de 9).** El marco compara `progress` con el anterior y emite `SFX_GLASS_HUM` (`on_partial`) **una vez por cada fragmento incorporado**. Si el jugador mueve una lámpara entre dos puntos sin fragmento nuevo, **no suena nada**; si un fragmento se apaga, cambia lo visual sin sonido y sin `REJECT`; el fragmento que vuelva a iluminarse genera de nuevo su sonido. Como una lámpara tiene un solo punto con fragmento y avanza en ciclo de 4, a lo sumo se oye **un hum por vuelta completa de esa lámpara** (no hay spam: cada lámpara necesita ≥ 4 pulsaciones entre dos incorporaciones de su fragmento).

**R14. El sello (distractor).** Con `pos_L = 2` se ilumina el sello de Dirección. Es un **gráfico sin texto legible** (D12-5): no afirma nada, no añade un hecho nuevo (pilar *Información incompleta*). No cuenta para `progress`, no suena `SFX_GLASS_HUM`, no genera veredicto `PARTIAL`. Como la lámpara L empieza en 2, **el jugador ve el sello iluminado antes de tocar nada**: es la primera demostración, sin palabras, de que «una luz de aquí hace aparecer cosas en el cristal».

**R15. Qué no existe.** No hay parpadeo de lámparas al «fallar» (el slice §10.2 lo dice; el Anexo B.2 lo anula: «Fallo: no existe». Se sigue B.2, D9-12 de 9 y D12-1), ni sonido de error, ni contador, ni límite de intentos, ni espera tras pulsar, ni temporizador, ni cambio de dificultad. Un punto vacío simplemente no revela nada.

**R16. Lo que muestra la cabeza de la lámpara.** Cada pulsación gira físicamente la cabeza de la lámpara hacia el nuevo punto en `lamp_turn_s` (0,4 s†; ≤ la duración de `HAND_TURN`). Esto es feedback de la **acción** (el jugador ve que su pulsación hizo algo) y no revela dónde está el fragmento. Con `reducir_movimiento` activo (regla 14b de 9) la cabeza cambia de orientación **al instante** (cambio estático); el fundido de luz del fragmento (R11) se conserva porque es luminancia, no movimiento (D12-12).

**R17. Sin marca del punto vacío por defecto.** Sin pista de nivel 3, un haz que cae en un punto vacío **no** se marca en el cristal (D12-6): lo que el jugador ve es la orientación de la cabeza y la ausencia de texto. Con la pista de nivel 3 (tabla de pistas, sección F) aparece el halo del haz. Ver Q12-1 (tanteo frente a deducción).

### D. Solución y derivación

**R18. Solución.** `pos_L = 3`, `pos_C = 1`, `pos_R = 4` (slice B.2): con esa combinación F1, F2 y F3 son visibles a la vez. La solución es **única**: cada lámpara tiene exactamente un punto con fragmento, así que de las 64 combinaciones solo una ilumina los tres (F1).

**R19. Derivación.** La solución no es un código que el jugador introduce: es la **configuración de los haces**. La **comprensión del mecanismo** se deduce así; **dónde** está cada fragmento **no** se deduce: se encuentra por **tanteo por lámpara con feedback `PARTIAL`** (hum y fragmento al acertar), sin softlock (toda posición es alcanzable con `Girar`, F2). El punto vacío no lleva marca (D12-6; sin pista 3 no se ve), así que no hay forma de inferir la posición correcta sin probar. (1) el cristal y el texto en espejo se perciben (película del cristal, hum de las lámparas); (2) cada lámpara ilumina un punto distinto al girar; (3) el sello de L en 2 enseña que la luz revela texto; (4) hay tres lámparas y el memorando se lee en tres tramos (el texto cobra sentido solo con los tres: una frase que empieza «Traslado de Vera…», un tramo «Ratificación pendiente» y un cierre «de firma del responsable.»); (5) cada lámpara se resuelve **por separado** (R10), de modo que un fragmento que aparece indica «esta lámpara ya está», y se pasa a la siguiente. Los números 3, 1 y 4 son etiquetas de implementación; el jugador solo los ve en la pista de nivel 2 (tabla de pistas, sección F). El orden de lectura F1, F2, F3 coincide con el orden izquierda-centro-derecha de las lámparas L, C, R (diseño de nivel; la geometría exacta es de 4). Si el tanteo basta como puzle (Autonomía, D-W2 del índice) sigue abierto (Q12-1).

### E. Resolución y recompensa

**R20. Resolución.** Con el veredicto `SOLVED` el marco aplica la regla 16 de 9 en el mismo fotograma: (1) escribe `memo_leido = true` (`on_solved.write`); (2) `solved_flag` ya está en la lista; (3) pasa a `RESUELTO`; (4) emite `EV_PUZZLE_SOLVED_P2` con `{puzzle: "P2", rewards: []}`; (5) no hay `compartment` (P2 no completa ningún compartimento); (6) feedback de acierto `SFX_GLASS_HUM` de `glass_hum_s` = **2,0 s** (distinto del `PARTIAL`, que es una vez por fragmento) y `play_resolution()` del controlador; (7) sin `close_view_after_s` (no hay vista). Todo es no bloqueante: ningún hecho ni aviso espera a que termine el sonido.

**R21. Presentación de la resolución.** `play_resolution()` deja el memorando **completo y permanente** (F1, F2 y F3 iluminados con el fundido de R11, `DOC_01` legible; slice C.5). La cabeza de cada lámpara permanece en su posición (3, 1, 4). No hay cinemática ni cambio de cámara. El detalle visual (película del cristal, brillo) es de 28/29 (Visual/Audio Requirements).

**R22. Recompensa.** Solo el memorando legible. **Sin llave, sin ítem y sin entrada en el bolsillo** (slice §10.2, «No hay llave ni objeto»): `rewards` = `[]`. El jugador lee el memorando **en el cristal** (`B04` no tiene verbo; D7-18). Cuestión abierta Q12-7: si 20 debe ofrecer relectura (`repasar_bolsillo`) de `DOC_01`; por defecto, no.

**R22b. Efectos posteriores (no los gobierna el P2).** `21` pide `VO_V_08` a +3,0 s† de `EV_PUZZLE_SOLVED_P2` (2,0 s del hum + 1,0 s, slice C.5; `d_vo08_s` de 21). `17` **no** lee `memo_leido` (D17-10). 5 guarda con la causa `puzzle_solved:P2` (GDD del 5). Nada más cambia.

**R23. Estado `RESUELTO`.** El puzle es inerte (D9-7; regla 35 de 9): cualquier `Girar` sobre `B01`–`B03` devuelve `SIN_EFECTO`; 7 reproduce `SFX_CLICK_SUBTLE` y `HAND_REACH`; no cambia ninguna posición ni hecho; no se escribe nada (`memo_leido` es de un solo sentido).

### F. Pistas (enganche con 9 y 17)

El P2 declara **tres** pistas (regla 27 de 9). Todas son `trigger: REQUEST`: el P2 es `WORLD`, no hay compromiso ni inactividad (F3 de 9 no aplica; regla 25 de 9), así que **ninguna pista aparece sola** (D12-8). Se piden desde el menú de pausa (25) vía 17; 9 solo las aplica (regla 26 de 9). Todas son **énfasis** de información que ya está en el juego, nunca información nueva (regla 27 de 9) y **ninguna cambia una posición ni resuelve** (`apply_hint_effect` devuelve `false`; no se dispara la regla 12b de 9). Solo se pueden aplicar con el puzle `ACTIVO`.

| Nivel | `availability` | Efectos | Clave / dato | Qué hace exactamente |
|---|---|---|---|---|
| 1 | `ON_HINT` | `TEXT` + `AFFORDANCE` (`MIRROR_PREVIEW`) | `PISTA_P2_N1` (18, regla 20): «El memorando está escrito en espejo. Un haz lo muestra mejor que la luz directa» | Muestra el texto como nota de 17 (duración por F2 de 17, ≈ 6 s; sin `duration_s` propio) y, a la vez, el texto de F1 **en espejo** durante `mirror_preview_s` = 2,0 s† en una zona neutra del cristal que **no** es ninguno de los 12 puntos (no revela dónde está F1). Ver Q12-4 |
| 2 | `ON_HINT` | `AFFORDANCE` (`FLOOR_MARKS`) | — (dato del objeto `B08`) | Las marcas del suelo `B08` se resaltan: muestran sus **números 1 a 4** y la marca de la **posición actual** de cada lámpara se ilumina. No indica la posición correcta. Ver Q12-5 |
| 3 | `ON_HINT` | `AFFORDANCE` (`BEAM_HALO`) | — (efecto visual) | Mientras el jugador esté a ≤ `halo_distance_m` = 1,5 m† de la base de una lámpara, el **punto actual** de su haz se marca con un halo en el cristal, también si es un punto vacío. Muestra el punto actual, **no** la posición correcta (slice B.2). Las lámparas están a 1,6 m entre sí: desde el centro de la fila, cada una se ve desde ≤ 0,8 m |

**R24. Persistencia de las pistas.** Los niveles 2 y 3 permanecen mientras dure la sesión de la escena; el nivel alcanzado (`hint_level_reached`) solo está en memoria y no se persiste (regla 26 de 9). Tras cargar, hay que volver a pedirlas. El nivel 1 es una nota que 17 muestra (F2 de 17, ≈ 6 s) y no se persiste.

**R25. Pistas en pausa.** `request_hint` escribe el nivel alcanzado en el acto; la duración del texto y de la vista previa se mide con el `GameClock` (regla 36 de 9) y **empieza al reanudar**.

### G. Guardado, carga y reevaluación

**R26. Qué se guarda.** `pos_L`, `pos_C`, `pos_R` (escritas en **cada** cambio, `persist`) y `memo_leido` (al resolver). No se guarda `progress`, `hint_level_reached` ni el estado de los fundidos (se reconstruyen de los hechos).

**R27. Configuración al cargar (regla 8 de 9).** Orden: (1) si `memo_leido` es verdadero, P2 = `RESUELTO` y `restore_solved_presentation()` coloca el memorando completo y las cabezas en 3, 1, 4 **al instante, sin sonidos ni avisos** (si `pos_*` no coincide con la solución, se fuerza solo la presentación; los hechos `pos_*` no se reescriben); (2) si no, `ACTIVO`; (3) restaura `pos_L`, `pos_C`, `pos_R`: cabezas en su posición, fragmentos iluminados **sin fundido, sin `SFX_GLASS_HUM` y sin `PARTIAL`** (el `progress_previo` del marco se calcula en silencio tras restaurar). Un valor fuera de 1–4 ya lo normaliza 3 a 2 (CA de 3).

**R28. Reevaluación inicial (regla 8 de 9).** Tras «escena lista», una sola vez, el marco llama a `evaluate()` en el P2. Si `pos = (3, 1, 4)` y `memo_leido` es falso (cierre forzado entre la escritura de la última lámpara y el guardado, o consola de desarrollo), el P2 se resuelve **por el camino normal** (R20), sin esperar a que el jugador mueva una lámpara. Como la escena arranca en el despacho de Vera, el hum es posicional (en la Sala B) y puede no oírse; `VO_V_08` sí se pediría (Q12-8, aceptado).

**R29. Escena.** Al recargar la escena (`planta`), las lámparas reflejan el valor **actual** de sus hechos (4, regla 9 paso 6; AC-08 de 4), no el inicial del slice.

### H. Datos, validación y pruebas

**R30. Todo valor numérico vive en `puzzles.json`** (mapa de apuntado, solución, posiciones iniciales, tiempos, pistas), no en el controlador (regla 5 de 9). Ver «Datos del puzle».

**R31. Validación al arrancar (regla 29 de 9).** Se exige, entre otras cosas: (a) exactamente 3 elementos y cada uno con 4 posiciones; (b) **un solo punto con fragmento por lámpara** (si hubiera dos, la independencia de R10 y la unicidad de R18 se rompen: error de datos); (c) el estado inicial no satisface la solución; (d) `solution` coincide con el mapa; (e) las claves `PISTA_P2_N1` y los fragmentos de `DOC_01` existen en 18; (f) los tres niveles de pista referencian efectos del catálogo; (g) no hay `on_reject` (el P2 no lo admite).

**R32. Prueba de resolubilidad (regla 30 de 9).** El solucionador de referencia, desde **cualquier** estado alcanzable (64 combinaciones, con pistas, cierres y cargas intermedias), llega a `RESUELTO` por la tubería real con `Girar`, en ≤ 9 pulsaciones (F2). Con 64 estados, la prueba es **exhaustiva**, no por muestreo.

## Formulas

### F1 · Espacio de estados y combinaciones

`N = P^L = 4³ = 64`   ·   `N_visibles = P · L = 12`   ·   `C(k) = C(3, k) · 1^k · (P − 1)^(3 − k)`

**Variables:** `P` posiciones por lámpara (4, `positions` en datos); `L` lámparas (3); `k` fragmentos iluminados a la vez (0 a 3); `C(k)` combinaciones con exactamente `k` iluminados (cada lámpara tiene 1 posición con fragmento y `P − 1` sin él).
**Output Range:** `N` = 64 (fijo para el slice; si `P` o `L` cambian, cambia). `N_visibles` = 12 puntos distintos que el jugador puede ver.
**Example:** `C(0) = 27`, `C(1) = 27`, `C(2) = 9`, `C(3) = 1`; suma = 64. Solo 1 de 64 (1,6 %) es la solución; el 42 % (27/64) no ilumina nada y el 58 % (37/64) ilumina al menos un fragmento. Combinaciones con el sello visible (`pos_L = 2`): 16 de 64. Como el estado inicial es (2,2,2) y el sello no cuenta, el jugador **empieza en `k = 0`** (cristal con solo el sello).

### F2 · Pulsaciones hasta el objetivo (resolución por tanteo, D-W2)

`clics(p₀, p*) = (p* − p₀) mod P`   ·   `clics_total = Σ_lámparas clics(p₀ᵢ, p*ᵢ)`   ·   `cota = L · (P − 1) = 9`

**Variables:** `p₀` posición actual (1–4); `p*` posición del fragmento (R9); `mod` con resultado en 0…3 (el avance es en un solo sentido, R7).
**Output Range:** por lámpara 0 a 3; total 0 a 9.
**Example (slice):** desde (2,2,2) hasta (3,1,4): L `(3−2) mod 4 = 1`, C `(1−2) mod 4 = 3`, R `(4−2) mod 4 = 2` → **6 pulsaciones**. La cota **≤ 9 pulsaciones de D-W2** se cumple: es `L · (P − 1) = 3 · 3`, alcanzable solo si las tres soluciones estuvieran a 3 pasos. Media sobre un objetivo aleatorio distinto del inicial (L ∈ {1,3,4} → 3,1,2 pasos): 2 por lámpara, 6 en total. Media sobre los 64 estados: `L · (0+1+2+3)/4 = 4,5`. **Condición:** la cota solo vale si el jugador **se detiene a observar** tras cada pulsación (R10: lámparas independientes). Si deja pasar un fragmento sin verlo, volver a él cuesta una vuelta completa (`P` = 4 pulsaciones) y el peor caso práctico sube a `9 + 3 · 4 = 21`.

### F3 · Coste de la fuerza bruta (comprobación de diseño, en la línea de F6 de 9)

`t_paso = t_clic + t_fundido + t_obs`   ·   `T_tanteo = clics · t_paso`   ·   `T_peor_clics = cota · t_clic`

**Variables:** `t_clic` = **0,8 s** = techo de `HAND_TURN` (7 descarta las pulsaciones durante el gesto, Edge Case 2, así que el jugador no puede pulsar más rápido que el gesto; con `lamp_turn_s` = 0,4 el mínimo sería 0,4 s, que es la convención de F6 de 9 y **no** se usa aquí); `t_fundido` = `fragment_fade_s` = 0,8 s (se toma **sin solape** con el gesto: cota conservadora); `t_obs` = 2,0 s† (mirar el cristal y decidir si apareció algo; a validar en playtest).
**Output Range:** `t_paso` = 0,8 + 0,8 + 2,0 = **3,6 s** (rango 3,2–3,6 s según el gesto dure 0,4 o 0,8 s).
**Example:** `T_tanteo` = 6 · 3,6 = **21,6 s** (concreto); con la cota, 9 · 3,6 = **32,4 s**; con una vuelta completa «pasada de largo» en cada lámpara (21 pulsaciones) = **75,6 s**. Solo las pulsaciones puras: 9 · 0,8 = 7,2 s (frente a ≈ 22 s de P4 en F6 de 9, **sin recalcular** a 0,8 s; P1 ≈ 122 s). **Conclusión de diseño:** el P2 es el de **menor coste de fuerza bruta** de los seis; no hay rechazo, `delay_s` ni reset que lo encarezcan. No es un defecto de *Tensión sin castigo* (es la intención), pero sí un riesgo de **resolución sin comprensión** (D-W2): ver Q12-1.

### F4 · Tiempo esperado de un jugador nuevo frente a F7 de 9

`T_P2 = T_entrada + T_descubrir + T_tanteo + T_lectura (+ T_pistas)`

**Variables y rangos (†, a validar en playtest con el registro de la regla 32 de 9):**

| Término | Bajo | Típico | Alto | Qué incluye |
|---|---|---|---|---|
| `T_entrada` | 20 s | 35 s | 45 s | Entrar en la Sala B, mirar el cristal y las lámparas |
| `T_descubrir` | 15 s | 40 s | 60 s | Entender que las lámparas giran y que el haz revela (ayuda: el sello inicial, R14) |
| `T_tanteo` | 21,6 s | 32,4 s | 75,6 s | F3 con `t_paso` = 3,6 s: **6** pulsaciones (F2, distancia exacta desde (2,2,2)) / **9** (cota de F2) / **21** (peor caso práctico de F2) |
| `T_lectura` | 10 s | 15 s | 30 s | Leer F1–F3 y esperar `VO_V_08` (+3,0 s tras resolver) |
| `T_pistas` | 0 | 0 | 60 s | Dos pistas pedidas en pausa |
| **Total** | **66,6 s = 1,11 min** | **122,4 s = 2,04 min** | **270,6 s = 4,51 min** | |

**Qué pulsaciones usa cada cálculo:** F2 da **6** (distancia exacta desde (2,2,2), el caso real del slice) y la media sobre los 64 estados es 4,5; F3 y esta tabla usan 6 en «Bajo», **9** (la cota) en «Típico» y 21 en «Alto». Es decir, el «típico» es **deliberadamente conservador** (la cota, no el valor esperado de F2); con 6 pulsaciones el típico sería 122,4 − 10,8 = 111,6 s = 1,86 min. Todos los términos son † sin validar: **el modelo no está medido**.

**Output Range:** ≈ **1,1 a 4,5 min**, típico ≈ **2,0 min**. **F7 de 9 pide 3–6 min** (slice §22 lo repite). El modelo solo alcanza el objetivo con jugadores indecisos o que piden pistas: **el objetivo de F7 parece por encima de lo que el diseño del slice produce**, pero es una estimación sin datos. No se toca F7 aquí: **medir primero** (Q12-2).

### F5 · Fundido de un fragmento

`opacidad(t) = clamp(opacidad₀ + sgn · (t − t₀) / fragment_fade_s, 0, 1)`   con `sgn = +1` si el fragmento pasa a iluminado y `−1` si se apaga

**Variables:** `fragment_fade_s` = 0,8 s (0,4–1,5); `t₀` instante del cambio; `opacidad₀` opacidad en ese instante (la nueva transición parte de la opacidad actual: **sin saltos** si el jugador gira dos veces seguidas).
**Output Range:** 0–1.
**Example:** F1 a 0,0; el jugador pulsa L a 3 → a 0,4 s la opacidad es 0,5; si pulsa de nuevo a 0,4 s (L pasa a 4), F1 desciende desde 0,5 y llega a 0 a los 0,4 s siguientes.

### F6 · Alcance del halo (pista de nivel 3)

`halo(lámpara) = verdadero  ⇔  distancia(cámara, base_lámpara) ≤ halo_distance_m`   (plano horizontal)

**Variables:** `halo_distance_m` = 1,5 m† (1,0–2,5); separación entre lámparas 1,6 m (slice A.5: `X` 13,4 / 15,0 / 16,6).
**Output Range:** 0, 1 o 2 halos simultáneos (con 1,5 m < 1,6 m, desde la vertical de una lámpara se ve solo la suya; entre dos lámparas, ambas).
**Example:** jugador a 1,0 m frente a `B02` (X = 15,0): distancia a `B01` = √(1,6² + 1,0²) ≈ 1,89 m > 1,5 → solo el halo de `B02`. En el punto medio entre `B01` y `B02`, a 0,5 m de la fila: distancia ≈ √(0,8² + 0,5²) = 0,94 m a ambas → dos halos.

## Edge Cases

Cada caso dice **qué ocurre**, no «se gestiona».

1. **`Girar` con el puzle `RESUELTO`.** `SIN_EFECTO`: 7 reproduce `SFX_CLICK_SUBTLE` y `HAND_REACH`; no cambia `pos_*` ni la cabeza (R23).
2. **Pulsaciones rápidas.** Cada pulsación aceptada avanza la posición lógica y escribe su hecho en ese fotograma; la cabeza va hacia la posición lógica actual y el fundido (F5) parte de la opacidad actual. No hay cola ni pérdida. Si 7 bloquea la entrada mientras dura `HAND_TURN`, la pulsación se descarta (lo manda 7; no es un rechazo del puzle).
3. **Se completan las tres en la última pulsación mientras fundían.** `SOLVED` se decide por el estado **lógico**, no por el fundido (D12-3): se resuelve en el fotograma de la pulsación; los fundidos pendientes terminan solos.
4. **Pasar por la solución sin querer.** Resolver es **inmediato** (sin tiempo mantenido): si la tercera lámpara cae en su punto, queda `RESUELTO` y las lámparas se bloquean. Esto es intencionado (D12-4): no hay «solución mantenida» que el jugador pueda perder.
5. **Mover una lámpara ya correcta.** Antes de resolver, es libre: el fragmento se apaga (sin sonido, F5) y `progress` baja; no hay `REJECT`. El jugador no «rompe» nada (R13).
6. **Girar una lámpara 4 veces seguidas.** Vuelve a la misma posición; el fragmento (si lo había) vuelve a iluminarse y suena de nuevo `SFX_GLASS_HUM` (un hum por incorporación, R13).
7. **Cargar con `pos` fuera de 1–4.** 3 lo normaliza a 2 y registra (CA de 3). La presentación usa 2.
8. **Cargar con (3,1,4) y `memo_leido` falso.** Se resuelve por el camino normal tras «escena lista» (R28), con un solo `EV_PUZZLE_SOLVED_P2`. El hum es posicional y `VO_V_08` se pide en el despacho (Q12-8).
9. **Cargar con `memo_leido` verdadero y `pos` distinto de (3,1,4)** (consola o dato corrupto). `RESUELTO` en silencio; las cabezas y el memorando se presentan en la solución; `pos_*` no se reescribe (R27).
10. **Cierre entre dos escrituras** (p. ej. entre `pos_C` y el guardado). Se pierde, como mucho, el último cambio hasta la siguiente causa de guardado (`t_periodico`, 5); es inocuo (rehacer una pulsación no cuesta nada, regla 22 de 9).
11. **Pausa durante el hum de 2,0 s o durante un fundido.** Se miden con el `GameClock` (regla 36 de 9) y se detienen con la pausa. Verificación en el editor pendiente (Open Questions 4 de 9).
12. **Cambio de `reducir_movimiento` con el puzle activo.** Afecta a la **siguiente** pulsación (regla 14b de 9); la cabeza ya girando termina como estaba.
13. **El jugador nunca resuelve el P2.** Permitido: ninguna regla lo exige (R4). Pierde el memorando (el contraste entre fuentes) y no cambia ningún otro puzle ni la llamada. `memo_leido` queda falso; 17 puede ofrecer pistas (no depende de ese hecho).
14. **`B05` (nota bajo la base de `B02`).** Apuntar a la base da «Girar»; apuntar a la parte de la nota que asoma da «Leer» (collider ≥ 0,02 m de margen, 7 y 4). Lo verifica AC-04c de 7; el P2 no añade lógica.
15. **Sello iluminado con `pos_L = 2` y nada más.** Veredicto `NONE`; no suena nada; no cuenta como progreso (R14). Si L pasa a 3 y F1 se ilumina, el sello se apaga con su fundido.
16. **Dato inválido** (dos fragmentos en una lámpara, posición fuera de rango, `REJECT` de un controlador): la validación de arranque lo detecta (R31); en la build final es un fallo de carga, nunca un puzle inactivo (regla 29 de 9). Un `REJECT` en tiempo de ejecución se trata como `NONE` y se registra (regla 15 de 9).
17. **Pista pedida con el puzle `RESUELTO`.** `request_hint` valida que el puzle esté `ACTIVO` (regla 26 de 9): no se aplica; 17 decide qué mostrar.
18. **Pista de nivel 1 mientras hay un fragmento visible.** La vista previa de F1 va a una zona neutra (tabla de pistas) y no se superpone al punto iluminado; si el diseño de nivel no encontrara zona neutra, el efecto se limita al texto (Q12-4).
19. **Degenerate strategy: tantear sin mirar (Sirlin).** Pulsar la misma lámpara hasta que algo aparezca es **legítimo y barato** (≤ 3 pulsaciones por lámpara, F2). No es una explotación: no hay recompensa que se pierda; el riesgo es de **comprensión**, no de equilibrio (Q12-1).
20. **Accesibilidad.** Visual: el fragmento aparece por luminancia y no por color; pilar *Ambivalencia*: sin rojo/verde moral. Auditiva: cada incorporación tiene `SFX_GLASS_HUM`, pero el estado del cristal es visible sin sonido. Motriz: una pulsación por paso, sin arrastre, sin tiempo; sin parpadeos (el fundido es suave de 0,8 s: no hay riesgo de destello). Sin audio: el memorando es texto visible; no depende de `VO_V_08`.

## Dependencies

La **dureza la declara el dependiente**. El índice (`systems-index.md`, fila 12) lista **7, 9 y 18**, que son las **tres dependencias duras** de este GDD. Las demás (3, 4, 2 y 6) son **blandas** y el índice no las lista (solo recoge las duras): no hay contradicción.

**12 depende de (declara 12):**

| Sistema | Dureza | Qué recibe 12 | Qué entrega 12 |
|---|---|---|---|
| 9 Marco de puzles | Dura | Ciclo de vida, escritura de `pos_*` y `memo_leido`, `EV_PUZZLE_SOLVED_P2`, planificación `ON_CHANGE`, pistas (`request_hint`), reevaluación inicial, validación | Veredictos (`NONE`/`PARTIAL`/`SOLVED`), `handle_activation`, `restore_solved_presentation()`, `apply_hint_effect()` y los datos de su entrada de `puzzles.json` |
| 7 Interacción e inspección | Dura | Verbo `Girar` sobre `B01`–`B03` (manejador registrado por 9), `can_interact` = `SI` siempre, `SIN_EFECTO` con `SFX_CLICK_SUBTLE` y `HAND_REACH` | Nada directo (9 es el manejador); depende de 7 el desempate `B02`/`B05` |
| 18 Base de contenido | Dura en validación | `DOC_01` en fragmentos F1–F3 (regla 10 de 18), `PISTA_P2_N1` (regla 20 de 18) | Nada |
| 3 Estado y bus | Blanda (vía 9) | Tipos y rangos de `pos_*` y `memo_leido` | Ninguna escritura directa |
| 4 Escena de planta | Blanda | Instancia de las lámparas, el cristal y `B08`; restauración desde hechos (regla 9 de 4) | Requisitos de geometría (R10) |
| 2 Jugador | Blanda (vía 7) | `HAND_TURN` (≤ 0,8 s) | — |
| 6 Ajustes | Blanda (vía 9) | `reducir_movimiento` | — |

**Dependen de 12** (la dureza la declara el dependiente): **17** (`sistema-de-pistas.md`) **no** lee `memo_leido` (solo pide las pistas por `request_hint`; D17-10); **21** reacciona a `EV_PUZZLE_SOLVED_P2` (`ESC5_MEMORANDO`, `VO_V_08`; indirecta, vía bus); **5** guarda `pos_*` y `memo_leido` (causa `puzzle_solved:P2`); **29** (`shaders-y-efectos.md`; **Dura**, la declara 29 y la repite 12; fila 29 del índice) y **28** (Blanda, la declara 28) presentan el reflejo; **23** reproduce `SFX_GLASS_HUM`. La sección «Matriz de encaje: los seis puzles frente al marco» de 9 (columna «P2 Memorando») recoge al P2. 21 no declara a 12 (relación indirecta vía bus).

## Tuning Knobs

**F** = feel, **C** = curva, **G** = gate. Viven en `assets/data/puzzles/puzzles.json` (en negrita, valores del slice; † = propuesto).

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué |
|---|---|---|---|---|
| `fragment_fade_s` | F | **0,8 s** | 0,4–1,5 | Fundido de cada fragmento (F5). Bajo: se siente brusco; alto: se pierde la causalidad entre pulsación y texto |
| `glass_hum_s` | F | **2,0 s** | 1,0–3,0 | `SFX_GLASS_HUM` al resolver; fija `d_vo08_s` de 21 (2,0 + 1,0) |
| `lamp_turn_s` | F | 0,4 s† | 0,2–0,8 (≤ `HAND_TURN`) | Giro de la cabeza de la lámpara; 0 con `reducir_movimiento` |
| `positions` | C | **4** | 3–6 | Posiciones por lámpara; cambia `N` y la cota de F1/F2 |
| `initial_pos` | C | **2,2,2** | 1–4, nunca = solución | Estado inicial; (2,2,2) pone el sello a la vista (R14) |
| `solution` / `pointing_map` | C | **3,1,4** / R9 | un solo fragmento por lámpara | Solución; cualquier cambio exige revalidar R31 y AC-P2-04 |
| `t_obs_s` (modelo F3) | C | 2,0 s† | 1,0–4,0 | Parámetro del modelo de tiempo, no de código |
| ~~`hint_text_s`~~ | F | — | — | Retirado (ronda de corrección 9): la duración de la nota de la pista 1 la fija F2 de 17 |
| `mirror_preview_s` | F | 2,0 s† | 1,0–3,0 | Vista previa en espejo de F1 (pista 1) |
| `halo_distance_m` | G | 1,5 m† | 1,0–2,5 | Alcance del halo (pista 3); debe ser < separación entre lámparas (1,6 m) para que cada halo se atribuya a una lámpara |
| `d_vo08_s` | G | 3,0 s† (de 21) | 1–5 | Retardo de `VO_V_08`; lo posee 21 |

## Visual/Audio Requirements

Requisitos de diseño, no dirección de arte (la decide el art director; la implementan 28/29).
- **Película del cristal:** el texto existe siempre, en espejo, apenas perceptible; solo el haz lo hace legible. Su legibilidad no depende de color (sin código bueno/malo, pilar *Ambivalencia*).
- **Haz:** cálido (ámbar, 2200 K, slice A.5) contra cristal frío; fundido de 0,8 s en ambos sentidos.
- **Sello de Dirección:** gráfico sin texto legible (R14).
- **Memorando completo:** F1–F3 permanentes y legibles al resolver (R21).
- **Audio:** zumbido de lámparas (2 dB), goteo de lluvia, `SFX_GLASS_HUM` (por fragmento y 2,0 s al resolver), `SFX_CLICK_SUBTLE` en `SIN_EFECTO`. Silencio parcial para oír el hum (game-concept).
- **Sin parpadeos** y sin sonido de error (R15).

## Acceptance Criteria

Tipos: **L** lógica (test automático, `tests/unit/`), **I** integración (`tests/integration/`), **PV** playtest o verificación visual con captura retenida (`production/qa/evidence/`).

**Funcionales**
- **AC-P2-01 (R5, L)**: **GIVEN** una partida nueva, **THEN** `pos_L = pos_C = pos_R = 2`, P2 `ACTIVO`, `progress = {}`, veredicto `NONE`, el sello iluminado y ningún fragmento.
- **AC-P2-02 (R7, L)**: **GIVEN** una lámpara en la posición p, **WHEN** se activa `Girar`, **THEN** pasa a `(p mod 4) + 1`; **WHEN** p = 4, **THEN** pasa a 1.
- **AC-P2-03 (R8, I)**: **WHEN** se pulsa `Girar` en `B02`, **THEN** en el mismo fotograma `pos_C` cambia, se llama a `evaluate()` y 7 reproduce `HAND_TURN`.
- **AC-P2-04 (R9, R12, R18, L)**: **GIVEN** las 64 combinaciones, **THEN** solo (3,1,4) da `SOLVED`; (3,1,2) da `PARTIAL` con `progress = {F1, F2}`; (2,2,2) da `NONE`; ninguna da `REJECT`.
- **AC-P2-05 (R11, R14, L)**: **GIVEN** `pos_L = 2`, **THEN** el sello está iluminado, F1 no, y no suena `SFX_GLASS_HUM`; **WHEN** `pos_L = 3`, **THEN** F1 está iluminado y el sello no.
- **AC-P2-06 (R13, L)**: **GIVEN** `progress = {F2}`, **WHEN** se mueve L de 1 a 2, **THEN** no suena nada; **WHEN** L llega a 3, **THEN** `SFX_GLASS_HUM` suena una vez; **WHEN** C sale de 1, **THEN** F2 se apaga sin sonido y sin `REJECT`.
- **AC-P2-07 (R20, I)**: **WHEN** la tercera lámpara llega a su posición, **THEN** en el mismo fotograma, en este orden: `memo_leido = true`, estado `RESUELTO`, `EV_PUZZLE_SOLVED_P2` con `rewards = []`; no se emite «compartimento completado»; suena `SFX_GLASS_HUM` 2,0 s.
- **AC-P2-08 (R23, L)**: **GIVEN** P2 `RESUELTO`, **WHEN** `Girar`, **THEN** `SIN_EFECTO`, suena `SFX_CLICK_SUBTLE` y `pos_*` no cambia.
- **AC-P2-09 (R4, I)**: **GIVEN** `memo_leido` falso, **THEN** la puerta D, la caja, P3–P6 y la llamada funcionan igual (ningún sistema lo lee; 17 tampoco, D17-10).
- **AC-P2-10 (R26, R27, I)**: **GIVEN** `pos = (4,3,2)` guardados, **WHEN** se carga, **THEN** las lámparas están en 4, 3, 2 sin fundido, sin sonido y sin `PARTIAL`.
- **AC-P2-11 (R28, L)**: **GIVEN** `pos = (3,1,4)` y `memo_leido` falso al cargar, **WHEN** llega «escena lista», **THEN** se resuelve una sola vez por el camino normal (AC-41 de 9).
- **AC-P2-12 (R27, L)**: **GIVEN** `memo_leido` verdadero y `pos = (2,2,2)`, **WHEN** se carga, **THEN** `RESUELTO` en silencio, presentación en 3,1,4 y `pos_*` sin reescribir.
- **AC-P2-13 (tabla de pistas, I)**: **GIVEN** P2 `ACTIVO`, **WHEN** se piden los niveles 1, 2 y 3, **THEN** se aplican los efectos de la tabla de pistas, `pos_*` no cambia, `apply_hint_effect` devuelve `false` y ninguna pista aparece sin pedirla (sin `IDLE`).
- **AC-P2-14 (F6, L)**: **GIVEN** `halo_distance_m` = 1,5, **THEN** a 1,89 m de `B01` no hay halo y a 0,94 m sí.
- **AC-P2-15 (R31, L)**: **GIVEN** un `puzzles.json` con dos fragmentos en una lámpara, estado inicial = solución o `on_reject` presente, **THEN** la validación de arranque falla.
- **AC-P2-16 (R32, L)**: **GIVEN** cada uno de los 64 estados, **THEN** el solucionador llega a `RESUELTO` por la tubería real en ≤ 9 pulsaciones (F2).
- **AC-P2-17 (R16, PV)**: **GIVEN** `reducir_movimiento` activo, **WHEN** se pulsa `Girar`, **THEN** la cabeza cambia al instante y el fundido de luz se mantiene (captura retenida).

**Experienciales (playtest, 5 jugadores)**
- **AC-P2-18 (PV)**: ≥ 4 de 5 resuelven sin pista de nivel 3; el tiempo se compara con F4 (1,1–4,5 min) y F7 de 9 (3–6 min); se registra el número de pulsaciones (esperado ≈ 6–21) y el intervalo real entre pulsaciones (valida `t_paso` = 3,6 s y `t_obs`); es la medición que decide Q12-2.
- **AC-P2-19 (PV)**: ≥ 4 de 5, al preguntarles, dicen que **encontraron** cada fragmento y no que acertaron por azar (mide Q12-1); y ≥ 3 de 5 mencionan que el memorando y el formulario no coinciden (función narrativa, sin que se afirme una intención).
- **AC-P2-20 (PV)**: ningún jugador describe el puzle como «tedioso» ni percibe una lámpara como «mal puesta»; 0 jugadores intentan «reiniciar» el puzle.

## Datos del puzle

Entrada de `assets/data/puzzles/puzzles.json` según el esquema de la regla 4 de 9. Sin `on_reject`, `on_unlock`, `assist`, `needs_items` ni `close_view_after_s` (no aplican a P2). Los enteros se convierten explícitamente a `int` (regla 29 de 9).

```json
{
  "schema_version": 2,
  "id": "P2",
  "mode": "WORLD",
  "elements": ["B01", "B02", "B03", { "id": "B08", "decor": true }],
  "solved_flag": "memo_leido",
  "requires": { "all": [] },
  "validation": { "policy": "ON_CHANGE" },
  "solution": {
    "positions": 4,
    "lamps": [
      { "element": "B01", "fact": "pos_L", "initial": 2, "target": 3 },
      { "element": "B02", "fact": "pos_C", "initial": 2, "target": 1 },
      { "element": "B03", "fact": "pos_R", "initial": 2, "target": 4 }
    ],
    "pointing_map": {
      "B01": ["EMPTY", "SEAL", "F1", "EMPTY"],
      "B02": ["F2", "EMPTY", "EMPTY", "EMPTY"],
      "B03": ["EMPTY", "EMPTY", "EMPTY", "F3"]
    },
    "fragments": { "F1": "DOC_01#1", "F2": "DOC_01#2", "F3": "DOC_01#3" },
    "decoys": ["SEAL"],
    "fragment_fade_s": 0.8,
    "lamp_turn_s": 0.4
  },
  "on_partial": { "sfx": "SFX_GLASS_HUM" },
  "on_solved": {
    "write": [{ "flag": "memo_leido", "value": true }],
    "sfx": "SFX_GLASS_HUM", "sfx_s": 2.0,
    "rewards": []
  },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "IMMEDIATE" },
  "persist": ["pos_L", "pos_C", "pos_R"],
  "hints": [
    { "level": 1, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [
        { "type": "TEXT", "key": "PISTA_P2_N1", "duration_s": 2.0 },
        { "type": "AFFORDANCE", "affordance": "MIRROR_PREVIEW", "fragment": "F1", "duration_s": 2.0 }
      ] },
    { "level": 2, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "AFFORDANCE", "affordance": "FLOOR_MARKS", "targets": ["B08"] } ] },
    { "level": 3, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "AFFORDANCE", "affordance": "BEAM_HALO", "targets": ["B01", "B02", "B03"], "distance_m": 1.5 } ] }
  ]
}
```

Notas: **esquema v2 de 9 (regla 4b, D9-67 a D9-79; `schema_version: 2` es de la raíz del fichero y se repite aquí para fijar la versión de la entrada; el decorado, D9-71, es decisión del usuario):** `B08` no es interactuable ni está en el catálogo de 7 (regla 26 de 7: «no se declaran»), así que se declara aquí con `decor: true` y la validación de la regla 29 de 9 lo acepta como `targets` de `FLOOR_MARKS` sin exigir que exista en 7. `MIRROR_PREVIEW` **no lleva `targets`**: es un efecto sin objetivo y el esquema v2 lo declara válido. La marca es `decor: true` dentro de la lista `elements` de `WORLD` (`{ "id": "B08", "decor": true }`, regla 4b-f); no es un manejador. `on_reject` ausente equivale a `null` (válido en P2, regla 4b-d). `on_reopen` en un `WORLD` no abre vista; las lámparas responden `SIN_EFECTO` (regla 35 de 9). El campo se llama `affordance` en todos los puzles (regla 4b-m, D9-72; sustituye a `kind`); lo interpreta el controlador (catálogo cerrado de 8 nombres); los tres de P2 se registran (Entradas para el registro).

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D12-1 | Sin fallo ni parpadeo de lámparas: se sigue B.2 | §10.2 («si falla, las lámparas parpadean») | Ya decidido por 9 (D9-12); el Anexo B es la especificación; un parpadeo sería un castigo visual (pilar *Tensión sin castigo*) |
| D12-2 | Giro en un solo sentido cíclico (1→2→3→4→1) | Doble sentido o salto directo | Lo dice B.2; añadir verbos cambia 7 |
| D12-3 | `progress` y `SOLVED` se calculan sobre el estado lógico, instantáneo; el fundido es solo presentación | Resolver al terminar el fundido de 0,8 s | Evita una ventana con `pos` = solución y `memo_leido` falso (rompería la reevaluación y el guardado) |
| D12-4 | Resolución inmediata, sin tiempo mantenido | `SUSTAINED` 0,8 s como P5 | B.2 y la matriz de 9 fijan `ON_CHANGE`; el hold ya existe en P5 |
| D12-5 | Sello gráfico sin texto legible, iluminado desde el inicio con L = 2, no cuenta como progreso | Sello con texto de Dirección | Texto nuevo = hecho nuevo (pilar *Información incompleta*); además enseña la mecánica sin tutorial |
| D12-6 | Sin pista 3, un punto vacío no se marca en el cristal; la cabeza de la lámpara sí gira | Haz siempre visible como mancha de luz | B.2 define el halo como pista de nivel 3; mostrar siempre el haz la vaciaría. Opción en Q12-1 |
| D12-7 | `B08` siempre presentes (A.5); la pista 2 los enfatiza (números y marca de la posición actual) | Que aparezcan solo con la pista 2 | A.5 dice «Visibles siempre»; ver Q12-5 |
| D12-8 | Las tres pistas son `REQUEST`; ninguna cambia el estado | `AUTO_SOLVE_ELEMENT` de una lámpara en el nivel 3 | `WORLD` no tiene inactividad; B.2 dice que el halo «no muestra la posición correcta»; las pistas son énfasis (regla 27 de 9) |
| D12-9 | Pista 1 = texto `PISTA_P2_N1` + vista previa de F1 en espejo 2 s en zona neutra | Solo texto | El slice B.2 pide mostrar F1; la zona neutra evita revelar su punto. Ver Q12-4 |
| D12-10 | Halo de la pista 3 por proximidad (≤ 1,5 m) | Por mirada fija a la lámpara | «Al acercar la cámara» (B.2); la mirada exigiría coordinar con 2 |
| D12-11 | Al resolver, las lámparas quedan en 3,1,4 y la presentación final se impone aunque `pos_*` difiera | Reescribir `pos_*` | El controlador no escribe hechos (regla 10 de 9) |
| D12-12 | Con `reducir_movimiento`, la cabeza salta; el fundido de luz se mantiene | Fundido instantáneo | La regla 14b de 9 habla de movimiento; la luminancia suave no lo es (verificar con art bible §7.4) |
| D12-13 | La independencia de lámparas es requisito de nivel (R10) | Solapar haces | Sin ella, F1–F3 no valen y el puzle no se resuelve lámpara a lámpara |
| D12-14 | El P2 no bloquea nada y no es puerta | Exigirlo para B o D | Grafo §8 y D-16; el §7 del slice dice «Puzle 2» como acceso a B (Q12-3) |
| D12-15 | La reevaluación inicial dispara `VO_V_08` aunque la escena arranque en el despacho | Suprimirlo | Caso rarísimo (cierre forzado); suprimirlo exigiría lógica extra en 21 (Q12-8) |
| D12-16 | No se alarga el puzle para alcanzar F7 | Añadir lámparas o posiciones | Cambiaría el slice (§10.2) y arriesga «puzles tediosos» (§22); ver Q12-2 |
| D12-17 | `B04` no interactuable | Verbo «Examinar» | D7-18 de 7 |
| D12-18 | (Ronda 7, B1) `B08` se declara en «Datos del puzle» con `decor: true`; se pide a 9 el esquema v2 y a 4 la geometría | Pedir a 7 que lo incluya en su catálogo (rompe su regla 26) o eximir a todos los decorados | La regla 29 de 9 exige que los `targets` existan; con `decor: true` la validación arranca sin tocar el catálogo de 7. Aprobado por el usuario |
| D12-19 | (Ronda 7, A3) No se baja F7 hasta medir; el «típico» de F4 usa 9 pulsaciones (cota) y se declara | Bajar F7 a 1,5–4 min ya | Bajarlo mueve el mínimo de F9 de 14,8 a 13,3 min y roza el criterio 1 del slice (15–30 min) y §22; el modelo está sin validar |
| D12-20 | (Ronda 7, A1) `MIRROR_PREVIEW` sin `targets` es válido en el esquema v2 | Darle un `targets` artificial (la zona neutra) | Es un efecto sin objetivo; un `targets` falso confundiría la validación |
| D12-21 | (Ronda 7, A4) `t_clic` de F3 = 0,8 s (techo de `HAND_TURN`), `t_paso` = 3,6 s | Mantener 0,4 s | 7 descarta pulsaciones durante el gesto (Edge Case 2), así que 0,4 s no es alcanzable con el gesto de 0,8 s |
| D12-22 | (Ronda 7, A5) R19 dice «tanteo por lámpara con feedback `PARTIAL`; sin softlock»; Q12-1 sigue abierta | Afirmar que la solución se deduce | Sin marca del punto vacío (R17, D12-6) solo se deduce el mecanismo, no la posición |
| D12-23 | (Ronda 7, A6/A7) Dependencies: duras 7, 9 y 18 (como el índice); 3, 4, 2 y 6 blandas; la «matriz de encaje» existe en 9 y se cita por su título | Subir 3, 4, 2, 6 a duras | La dureza la declara el dependiente y ninguna impide arrancar el P2. A7 (Q12-3/Q12-6 frente al slice) ya está abierta |
| D12-24 | (Ronda 8) Alineado con el esquema v2 (regla 4b de 9): `schema_version: 2`; `affordance` en lugar de `kind`; `B08` como `{ "id": "B08", "decor": true }` dentro de `elements` (sustituye al `decor_elements` provisional) | Mantener `kind` y `decor_elements` | Un nombre por concepto y validación única (D9-71, D9-72); sin cambio de diseño ni de tiempos |
| D12-25 | (Ronda de corrección 9, `sistema-de-pistas.md` Cambios requeridos nº 5) 17 **no** lee `memo_leido` (D17-10): se quita a 17 como lector de R4, R22b, la lista de dependientes, AC-P2-09 y las entradas de registro; el `TEXT` de la pista 1 pierde su `duration_s` y el knob `hint_text_s` (la nota la dura F2 de 17, ≈ 6 s) | Mantener a 17 como lector «por si acaso»; mantener los 2,0 s de la pista | Un lector que no lee confunde al verificador de hechos; 2,0 s no bastan para leer la nota (F2 de 17) |
| D12-26 | **(Ronda de corrección 10)** La Quick reference ya no dice que 17 lee `memo_leido` (17 no lo lee: D17-10, `sistema-de-pistas.md`); 29 se lista como dependiente Dura (la declara 29) y 28/29 dejan de ser «al redactarse» | Dejar a 17 como lector | Contradecía el contrato que declara 17 | 

## Open Questions

| ID | Pregunta | Opciones | Recomendación | Estado |
|---|---|---|---|---|
| Q12-1 | **D-W2: ¿el P2 se puede deducir o solo se tantea?** Hoy se resuelve en ≤ 9 pulsaciones con feedback por lámpara (F2, F3): la comprensión del mecanismo se deduce, pero **dónde** está cada fragmento no se puede inferir de nada visible. Toca *Autonomía* y *Competencia* | O1: dejar como está (tanteo por lámpara). O2: huellas casi invisibles en la película del cristal, visibles al acercarse a `B04`, que indican dónde hay texto (deducción espacial). O3: haz siempre visible como mancha de luz (el jugador aprende el mapa posición → punto) y el halo de la pista 3 pasa a ser un anillo | O3 primero (solo arte, no revela la solución) y medir con AC-P2-19; O2 si el playtest dice «azar» | **Abierta (decide el usuario)** |
| Q12-2 | **F7 y slice §22 piden 3–6 min para el P2**; el modelo F4 da 1,1–4,5 (típico 2,0), todo sin validar. El P2 tiene el mayor objetivo y el menor coste de fuerza bruta | (a) **Medir antes** (AC-P2-18) y decidir con datos. (b) Si tras medir se baja F7 del P2 a 1,5–4 min, el mínimo de F9 pasa de 14,8 a 13,3 min y **roza el criterio 1 del slice (15–30 min)** y su §22 (fuente de verdad): decide el usuario. (c) Subir profundidad (Q12-1) | (a) **Medir antes; no bajar F7 hasta tener datos** (D12-19) | Abierta (toca slice §22) |
| Q12-3 | El slice §7 dice que B se accede con «Tarjeta de A + Puzle 2», pero B.2 y §8 sitúan el puzle **dentro** de B. ¿Es el P2 un requisito de algo? | Leer §7 como contenido de la sala (por defecto, D12-14) o convertirlo en puerta | Por defecto | Abierta (contradice el slice) |
| Q12-4 | La pista 1: el slice B.2 dice «se muestra durante 2 s el texto de F1 en espejo» y da el texto de `PISTA_P2_N1`. ¿Son dos cosas (texto + vista previa) o una? | Dos (D12-9) / solo texto | Dos | Abierta |
| Q12-5 | B08 «visibles siempre» (A.5) frente a la pista 2 que los «indica» (B.2) | Enfatizar (D12-7) / aparecer | Enfatizar | Abierta |
| Q12-6 | C.5 dice «el cristal está vacío» al entrar, pero L = 2 ilumina el sello | Leer «vacío de fragmentos» (D12-5) / sello solo con L ≠ 2 | Primera | Abierta |
| Q12-7 | ¿20 ofrece relectura de `DOC_01` en el bolsillo? El slice dice «sin ítem» | No (por defecto) | No | Abierta |
| Q12-8 | `VO_V_08` tras la reevaluación inicial se oiría en el despacho | Aceptar (D12-15) / condicionar a la sala | Aceptar | Abierta (afecta a 21) |

## Cambios requeridos en otros GDDs

No se ha editado ningún archivo existente. Pendiente:

- **9 Marco de puzles:** (1) F7: **no cambiar** el valor del P2 hasta medir (Q12-2); (2) **absorbido en 9 (esquema v2, D9-71, D9-72, D9-70):** catálogo `AFFORDANCE` (`affordance`: `MIRROR_PREVIEW` sin `targets`, `FLOOR_MARKS`, `BEAM_HALO`), `decor: true` (`B08`) aceptado como `targets` sin exigir presencia en 7, y `on_reject: null` válido (el P2 no lleva `on_reject`); (3) la fila «Pistas» de la matriz: aclarar que las 3 del P2 son `REQUEST`; (4) AC-12 de 9: añadir que el sello no cuenta como progreso.
- **18 Base de contenido:** fila 163 («el sello»): el sello es gráfico, sin clave ni texto (D12-5); confirmar Q12-4 sobre `PISTA_P2_N1`.
- **17 Sistema de pistas (`sistema-de-pistas.md`):** las pistas del P2 son solo a petición; 17 **no** usa `memo_leido` (D17-10) y muestra la nota de la pista 1 con su propia duración (F2 de 17, ≈ 6 s; sin persistirla).
- **21 Director de escenas:** nota sobre Q12-8.
- **4 Escena de planta:** requisitos de nivel de R10 (12 puntos sin solape, haces independientes, orden izquierda-centro-derecha) y que `B08` esté siempre presente (geometría; no hace falta que esté en el catálogo de 7).
- **Datos / registro (`assets/data`, `design/registry/entities.yaml`):** `cobertura_anexo_a.json` **no existe** (solo lo cita el registro): crearlo con `B04` y `B08` como `interactuable: false`, o corregir la referencia (R1).
- **28 (`atmosfera-reactiva.md`) y 29 (`shaders-y-efectos.md`), que ya existen:** película del cristal y fundido de 0,8 s (Visual/Audio Requirements).
- **`systems-index.md`:** fila 12 → «Borrador (lote Feature 3) — pendiente de review», ruta de este GDD.
- **Slice (decide el usuario):** Q12-3, Q12-5, Q12-6 y el §22 (Q12-2).

## Entradas para el registro

Constantes (verificar duplicados con 9, que ya tiene `fragment_fade_s` y `glass_hum_s`): `p2_lamp_count` = 3 · `p2_positions` = 4 · `p2_initial_pos` = 2 · `p2_solution` = [3, 1, 4] · `p2_combinations` = 64 · `p2_clicks_worst_case` = 9 · `p2_clicks_slice` = 6 · `p2_lamp_turn_s` = 0,4 † · `p2_halo_distance_m` = 1,5 † · `p2_mirror_preview_s` = 2,0 †.
Fórmulas: `p2_clicks_to_target` = (p* − p₀) mod 4 (0–3) · `p2_expected_time_min` (1,1–4,5; típico 2,0; sin validar).
Entidades: `B01`–`B03` (lámparas L, C, R), `B04` (ventanal, no interactuable), `B08` (marcas), fragmentos `F1`–`F3` de `DOC_01`, sello de Dirección (distractor).
Efectos de pista nuevos: `MIRROR_PREVIEW`, `FLOOR_MARKS`, `BEAM_HALO`.
Hechos (sin cambios): `pos_L/C/R` (owner 9), `memo_leido` (owner 9; sin lector en el slice: 17 no lo lee, D17-10).

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Esqueleto creado (lote Feature 3). |
| 2026-11-09 | Borrador completo: reglas R1–R32, F1–F6, 20 casos límite, 20 AC, datos de `puzzles.json`, D12-1 a D12-17, Q12-1 a Q12-8. Pendiente de review independiente. |
| 2026-11-09 | Review independiente: NEEDS REVISION (1 bloqueante, 7 avisos). |
| 2026-11-09 (ronda de corrección 8) | Alineación mecánica con el esquema v2 de `puzzles.json` (regla 4b de 9): `schema_version: 2`, `kind` → `affordance`, `decor_elements` → `decor: true` en `elements`; petición a 9 marcada como absorbida; D12-24. Sin cambio de diseño. Estado: Revisado (ronda 8), pendiente de re-review. |
| 2026-11-09 | Ronda de corrección 7: B1 (`B08` con `decor: true`, petición a 9 esquema v2 y a 4; se quita la petición a 7); A1 (`MIRROR_PREVIEW` sin `targets`); A2 (`cobertura_anexo_a.json` planificado, no existe); A3 (F4: se declara qué pulsaciones usa cada cálculo; Q12-2 «medir antes»; F7 no se toca); A4 (F3 con `t_clic` 0,8 s, `t_paso` 3,6 s; F4 recalculada: 66,6 / 122,4 / 270,6 s, ≈ 1,1–4,5 min); A5 (R19 reescrita; Q12-1 abierta); A6/A7 (Dependencies; matriz de encaje verificada en 9). D12-18 a D12-23. Estado: pendiente de re-review. |
| 2026-11-10 (ronda de corrección 10) | Quick reference alineada con D17-10 (17 no lee `memo_leido`); 29 como dependiente Dura (la declara 29) en Dependencies; «al redactarse» de 28/29 sustituido por sus ficheros; D12-26. Estado: Revisado (ronda de corrección 10) — pendiente de re-review. |
| 2026-11-10 (ronda de corrección 9) | Lector de `memo_leido`: 17 retirado (D17-10); pista 1 sin `duration_s` ni `hint_text_s` (F2 de 17); fila de 17 con su GDD; D12-25. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. |
