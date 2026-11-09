# Puzle 4 · Tablero de tareas

> **Status**: Borrador (lote Feature 3) — pendiente de review
> **Author**: game-designer (lote autónomo, 2026-11-09)
> **Last Updated**: 2026-11-09
> **Sistema**: 14 · Capa `Feature` · Categoría `Gameplay` · Prioridad `MVP`
> **Implements Pillar**: Autonomía como progresión (la «primera elección de autonomía» del slice) · Ambivalencia sin moral binaria (ninguna opción de T4 es incorrecta) · Tensión sin castigo (sin temporizador, sin contador, rechazo sin coste)

## Summary

El Tablero de tareas es el cuarto puzle del slice: cuatro fichas de trabajo sobre una mesa (compartimento 2 de la caja, `D01b`), cada una con una descripción, dos selectores (Urgencia y Responsable) y un botón «Devolver». Tres fichas (T1 a T3) se resuelven razonando sobre su texto; la cuarta (T4, la «Carta a Dirección») acepta «Devolver» o cualquier asignación y es la primera elección de autonomía del jugador: decidir si Vera habla por otra persona. Este GDD **instancia** el marco de puzles (9); no redefine ciclo de vida, política de fallo, orden de escritura ni pistas.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `9 Marco de puzles` (dura), `10 Caja y compartimentos` (dura), `18 Base de contenido narrativo` (dura) · dependen de 14: `22 Llamada telefónica` (indirecta, por el hecho `t4_decision`), `20 Documentos y bolsillo` (blanda, `I-05`)

## Overview

P4 es un puzle `VIEW` de política `PER_ELEMENT` (9, regla 12) que se juega en la vista cercana `D01b`. Cuatro fichas (T1 Cliente Lima, T2 Revisión de contrato, T3 Mudanza del archivo, T4 Carta a Dirección) se resuelven una a una: cada ficha tiene dos selectores (Urgencia: Alta/Media/Baja; Responsable: Vera/Guardián/Dirección) y un botón «Devolver». Una ficha se evalúa cuando tiene sus dos selectores completos o «Devolver» activo. En T1–T3 hay una sola acción correcta, deducible del texto de la ficha; una acción equivocada la devuelve a neutra con «No corresponde» (1,5 s) sin tocar las demás. T4 acepta «Devolver» o cualquier combinación de selectores: nunca se rechaza. Cuando T1–T3 están aceptadas y T4 decidida, el marco (9) escribe `t4_decision` (`returned` o `assigned`) y después `caja_c2`, y aparece `I-05` (lista de tareas del Guardián, con el nombre de Vera tachado). No hay temporizador: una ficha sin decidir permanece en la mesa. La regla visible del tablero («Acepta lo que tiene urgencia y responsable. Devuelve lo que no te corresponde») es a la vez la pista de nivel 1 y el único «tutorial».

Estructura de este GDD: reglas P4-R1 a P4-R20 (Detailed Rules); fórmulas P4-F1 a P4-F5; casos límite P4-E1 en adelante; la entrada completa de `puzzles.json` está en «Datos del puzle». Las referencias «regla N de 9» remiten a `marco-de-puzles.md`.

## Player Fantasy

Vera no «rellena un formulario»: **lee el trabajo que otros dejaron en su mesa y decide qué es suyo**. Las tres primeras fichas dan la sensación de competencia tranquila (el texto basta para saber a quién toca y con qué prisa). La cuarta cambia el registro: nada en ella es una pregunta con respuesta, y el jugador lo nota solo cuando se detiene a pensarlo; devolverla o asumirla es **hablar o no hablar por otra persona**. El jugador debe sentir que eligió, que ninguna elección lo juzgó y que el juego lo recordó en silencio (la llamada). Estética principal (MDA): **Challenge** suave y **Discovery** (T1–T3); secundaria: **Narrative** y **Expression** (T4). SDT: **Competencia** (feedback legible por ficha, solución deducible), **Autonomía** (la primera elección sin respuesta correcta del slice; orden libre de las fichas y de la caja). Pilares servidos por nombre: *Autonomía como progresión*, *Ambivalencia sin moral binaria* (ni sello, ni color, ni sonido distinguen «bueno» de «malo» en T4) y *Tensión sin castigo* (sin temporizador, sin contador, rechazo sin coste). La tensión viene del tema (alguien escribió «en nombre de la interesada»), nunca de la mecánica.

## Detailed Rules

† = valor propuesto a validar en playtest. Nombres de gesto y verbo, los de 7 (`seleccionar`); claves de datos en inglés; IDs del slice tal cual.

**El tablero y las fichas**

**P4-R1. Vista y acceso.** P4 vive en la vista `D01b` (compartimento 2, `caja_c2`). Estado inicial `ACTIVO` (`requires.all` vacío, slice B.4 y 9 regla 24); su orden respecto a P3 es libre. Abre la vista el dueño (10) tras `get_view_gate('D01b')` = `OPEN`; la cadena `BOX_C2_OPEN` (1,4 s) y `t_vista_entrada_s` son de 10 y de 7. Modo `VIEW`, política `PER_ELEMENT`, resolución `IMMEDIATE`, `on_reopen` `NO_VIEW` (9, reglas 7, 12, 35).

**P4-R2. Elementos de la vista.** Por cada ficha Tn (n = 1..4) el controlador expone, con el prefijo `D01b/`: `Tn/body` (la descripción, no clicable salvo el resaltado de la pista de nivel 2), `Tn/urg_alta`, `Tn/urg_media`, `Tn/urg_baja`, `Tn/resp_vera`, `Tn/resp_guardian`, `Tn/resp_direccion` y `Tn/return`. Son 28 elementos señalables (`atraccion` verdadero) más 4 `body` y el texto fijo de la regla del tablero (`D01b/rule`, no interactivo). Los selectores son **segmentos con todas las opciones visibles** (no desplegables): una combinación completa son exactamente 2 `seleccionar`. Gesto único: `seleccionar`; `agarrar`, `rotar` y `mantener` se ignoran. Tamaño ≥ `pick_min_px` (44 px) y separación entre centros ≥ 128 px (R = 64, 9 regla 29; sin tolerancia propia); disposición: 4 columnas, una por ficha (la maquetación exacta es de ux/arte; Open Question 1).

**P4-R3. Las cuatro fichas.** Textos de 18 (regla 1 de 18, «Ficha de tarea»; el slice B.4 los fija): T1 «Cliente Lima» · «Revisión antes del jueves. Ya la tiene asignada Vera.»; T2 «Revisión de contrato» · «Lleva tres semanas parada. Solo puede firmarla quien dirigía el equipo anterior.»; T3 «Mudanza del archivo» · «Sin fecha. Requiere aprobación de Dirección.»; T4 «Carta a Dirección» · «Explicar a Dirección la solicitud de traslado en nombre de la interesada.» con el nombre tachado y reemplazado por «G». Este GDD no reescribe esos textos.

**P4-R4. La regla visible.** `D01b/rule` muestra siempre, sin interacción ni temporizador, el texto `PISTA_P4_N1`: «Acepta lo que tiene urgencia y responsable. Devuelve lo que no te corresponde». Es la misma clave que la pista de nivel 1 (D18-3): no existe una clave `UI_` duplicada. La regla es **cierta para T4 sin implicar error** (aceptar o devolver son ambas opciones, slice B.4 nivel 1). La regla no se resalta, no cambia con el estado y no usa color de valor moral.

**P4-R5. Los dos selectores y «Devolver».** Estado de una ficha: `urgencia` ∈ {nula, Alta, Media, Baja}, `responsable` ∈ {nulo, Vera, Guardián, Dirección}, `devuelta` (bool), `bloqueada` (bool). `seleccionar` sobre un segmento fija ese valor (sustituye el anterior del mismo selector; se puede cambiar mientras la ficha no se evalúe). `seleccionar` sobre `Tn/return` fija `devuelta` y **desactiva los selectores** de esa ficha (slice B.4); como la evaluación es inmediata (P4-R6), «Devolver» no es deshacible en una ficha bloqueada, pero sí cuando la ficha se rechaza (T1–T3, vuelve a neutra). Una ficha con **un solo** selector elegido conserva la selección al salir o cancelar (9, regla 11b) y no se evalúa.

**Qué se acepta y qué se rechaza**

**P4-R6. Evaluación por ficha (`PER_ELEMENT`).** Una ficha se evalúa cuando termina su gesto: tiene sus dos selectores completos **o** `devuelta` verdadero. El marco llama a `evaluate()` (9, reglas 12 y 12b); el controlador devuelve `PARTIAL` (ficha aceptada), `REJECT` (solo T1–T3, ficha equivocada), `SOLVED` o `NONE`. Una ficha ya bloqueada no se reevalúa.

**P4-R7. Solución de T1 a T3** (slice B.4; acción única `ASSIGN`). La solución se deduce del texto, no del azar:

| Ficha | Urgencia | Responsable | `RETURN` |
|---|---|---|---|
| T1 | Alta | Vera | `REJECT` |
| T2 | Media | Guardián | `REJECT` |
| T3 | Baja | Dirección | `REJECT` |

Cualquier otra combinación completa (8 por ficha) y `RETURN` (1) son incorrectas: 9 opciones erróneas de 10 por ficha (P4-F1). Deducción prevista: T1, «antes del jueves» (plazo cercano, urgencia más alta) y «ya la tiene asignada Vera» (quien ya lleva el caso); T2, «tres semanas parada» (ni lo más urgente ni lo más relajado) y «quien dirigía el equipo anterior» (el Guardián); T3, «sin fecha» (la urgencia más baja) y «requiere aprobación de Dirección». La explicación del nivel 3 («La urgencia sigue al plazo; el responsable, a quien ya lleva el caso») es el modelo de lectura.

**P4-R8. Rechazo de T1–T3** (política única de 9, regla 14, instanciada con `lock: NONE`). Un `REJECT` hace, y solo hace: `SFX_REJECT`; la ficha afectada vuelve a neutra **al instante** (`urgencia`, `responsable` y `devuelta` a nulo/falso); aparece «No corresponde» sobre esa ficha durante `no_corresponde_s` = 1,5 s†; la ficha puede reeditarse de inmediato (no hay `reset_after_s` ni bloqueo de entrada). Las fichas ya aceptadas **no se reinician** y no se toca nada más. No hay contador, ni el mensaje indica qué selector falló, ni cambia la dificultad. «Reducir movimiento» (9, regla 14b): la vibración de la ficha se sustituye por un cambio estático de tono de la misma duración. El mensaje es la clave de 18 del rechazo de T1–T3 (propuesta de clave en Cambios requeridos).

**P4-R9. T4 nunca se rechaza** (9, regla 12c; D9-39). T4 acepta `RETURN` (botón «Devolver») **o** `ASSIGN` (cualquier combinación completa: 9 posibles). El controlador **no puede devolver `REJECT` para T4** (ni `SFX_REJECT`, ni «No corresponde»). Datos: `solution.T4 = {accept: [RETURN, ASSIGN]}`. T4 carece de solución «preferida»: los 10 desenlaces valen lo mismo para el marco y para el puzle.

**P4-R10. Aceptación y sellos** (`PARTIAL`). Al aceptarse una ficha (T1–T3 correcta, T4 decidida): `SFX_STAMP`, sello sobre la ficha y ficha **bloqueada** (los selectores y «Devolver» dejan de responder). Sello «ACEPTADA» si la acción fue `ASSIGN`; «DEVUELTA» si fue `RETURN` (textos de 18, fila «14 Puzle 4» de su tabla de dependientes; claves propuestas en Cambios requeridos). El sello y su sonido son **idénticos en forma y registro para las dos salidas de T4** salvo la palabra (pilar *Ambivalencia*: sin rojo/verde moral, sin tono distinto, sin animación distinta; el arte y el audio lo ratifican). T1–T3 aceptadas llevan siempre «ACEPTADA». `PARTIAL` emite el feedback **solo por la ficha incorporada** (9, regla 13b).

**P4-R11. Qué decide T4 y qué recuerda el controlador.** Al decidirse T4 el controlador guarda `t4_action` ∈ {`RETURN`, `ASSIGN`} **solo en memoria**. Los selectores concretos de una T4 `ASSIGN` **no se guardan ni se leen** (D9-40). T4 puede decidirse antes, entre o después de T1–T3.

**P4-R12. Resolución.** El puzle es `SOLVED` cuando T1–T3 están aceptadas **y** T4 decidida. Con T4 sin decidir, `caja_c2` y por tanto P6 quedan bloqueados hasta que el jugador la decida, sin temporizador, sin pista que la decida y sin penalización; no hay softlock porque ambas acciones están siempre disponibles (S7 de 9).

**El hecho `t4_decision`**

**P4-R13. Efecto de «Devolver» o «Asignar» en T4.** El veredicto `SOLVED` lleva `t4_action`. El marco (9, regla 16) escribe, en el mismo fotograma y en este orden: (1) `t4_decision` = `returned` si `t4_action` = `RETURN`, `assigned` si `ASSIGN`; (2) `caja_c2` = verdadero; (3) estado `RESUELTO`; (4) `EV_PUZZLE_SOLVED_P4` con `{puzzle: P4, rewards: [I-05]}`; (5) «compartimento completado» (2); (6) feedback de acierto. `t4_decision` es de un solo sentido (3, regla 6; owner 9) y **no se escribe al decidir T4** sino al resolver el puzle (D9-41): el parcial de P4 no se persiste (9, regla 22).

**P4-R14. Lo que hace y lo que no hace `t4_decision`.** Su único lector es 22 (Llamada telefónica): elige `VO_G_14_RET` (`returned`) o `VO_G_14_ASG` (`assigned`) cuando se cumplen los 20 s sin respuesta (slice §11, escena 7; 18 regla 5). **No cambia** ningún puzle, puerta, ítem, carta ni final; no es un medidor ni una puntuación (pilar *Ambivalencia*; anti-pilar «sin medidores de moral»). **No se muestra al jugador** ningún texto que diga que la elección «se ha recordado» (no hay aviso de «el Guardián lo recordará»). La línea `VO_G_14_ASG` es una propuesta pendiente de narrative-director; este GDD no la redacta ni la valora.

**Pistas**

**P4-R15. Tres niveles, instanciados** (slice B.4; 9, reglas 25 a 27):

| Nivel | Efecto (9) | Clave de 18 | Disparo | Detalle |
|---|---|---|---|---|
| 1 | `TEXT` (siempre visible) | `PISTA_P4_N1` | `REQUEST` (el texto ya es visible en la vista: `availability: ALWAYS`) | Reafirma la regla del tablero. No resalta ninguna ficha |
| 2 | `AFFORDANCE` `HOVER_HIGHLIGHT` | — (efecto visual) | `REQUEST` | La descripción (`Tn/body`) de la ficha bajo el cursor se resalta al pasar; `availability: ON_HINT`; el desplazar cursor **no cuenta como acción de inactividad** (9, regla 9 y F3) |
| 3 | `AUTO_SOLVE_ELEMENT` (solo T1) | `PISTA_P4_N3` | `REQUEST` | T1 se resuelve (Alta, Vera, sello «ACEPTADA») y muestra «La urgencia sigue al plazo; el responsable, a quien ya lleva el caso». Pasa por `evaluate()` (9, regla 12b) |

El nivel 3 **nunca** resuelve ni toca T4 (9, regla 25; D9-42). Si T1 ya está aceptada al pedirlo, el nivel 3 no cambia nada (solo muestra la explicación). Ninguna pista usa `IDLE`: P4 no tiene hint automático (`idle_hints_auto_apply` no aplica); el reparto lo hará 17. Las pistas no dan información nueva (9, regla 27): resaltan el texto que ya está en la ficha.

**Recompensa**

**P4-R16. `I-05`.** Recompensa: la lista de tareas del Guardián con el nombre de Vera tachado en la última entrada (slice §10.4, D.1). Viaja en `rewards` del aviso; 20 deriva `has_item('I-05')` de `caja_c2` (R5 de 20). 10 pone solo el papel como decorado no interactivo (regla 17 de 10); **ni 14 ni 9 ni 10 presentan una lectura al resolver** (D20-19). El jugador la relee con `repasar_bolsillo` (orden del repaso: `I-07`, `I-05`, `I-06a`, `I-04`; R6 de 20). El texto es `DOC_LISTA_TAREAS` de 18.

**Qué escribe 9 (no 14)**

**P4-R17. Reparto de escritura.** 14 es solo datos + `PuzzleController`; **no escribe ningún hecho ni emite ningún aviso** (9, regla 10). Escribe 9: `t4_decision`, `caja_c2`, `EV_PUZZLE_SOLVED_P4`, «compartimento completado» (2), «feedback de puzle» (sellos, rechazo), «pista aplicada». Lee 10 (`caja_c2`), 20 (`has_item`), 22 (`t4_decision`).

**Carga, cierre y reinicio**

**P4-R18. Configurar y cargar** (9, regla 8). Si `caja_c2` es verdadero: P4 `RESUELTO`; `restore_solved_presentation()` llama a `set_final_pose(2)` de 10 y coloca las cuatro fichas **selladas**. Cada ficha muestra «ACEPTADA» salvo T4, cuyo sello depende de `t4_decision` (`returned` → «DEVUELTA»; `assigned` → «ACEPTADA»); sin sonido ni avisos. Si `caja_c2` es falso: P4 `ACTIVO` con las cuatro fichas **vacías** (el parcial no se persiste, D9-8): fichas selladas antes de cerrar vuelven a neutras. Si `t4_decision` ya tiene valor con `caja_c2` falso (consola), 9 no lo rescribe (Edge Case P4-E8).

**P4-R19. Salir y cerrar.** `atrás` cierra la vista en cualquier momento (S4 de 9). Al salir se conserva el estado de las fichas mientras dure la sesión de escena (9, regla 21b); una ficha con un selector elegido lo conserva; no hay pérdida ni coste. Tras `SOLVED`, 9 pide `cerrar_vista('D01b','resuelto')` a `close_view_after_s` = 1,5 s†; el regreso de cámara es 0,5 s (2, regla 18). Reabrir un P4 `RESUELTO`: `NO_VIEW` (9, regla 35); el jugador relee `I-05` desde el bolsillo.

**P4-R20. Ausencia de tiempo.** P4 no tiene temporizador, cuenta atrás, límite de intentos, enfriamiento ni evento por inactividad (pilar *Tensión sin castigo*; 9, S3). Una ficha sin decidir permanece como está indefinidamente.

## Formulas

### P4-F1 · Número de combinaciones

`N_ficha = n_urg · n_resp + 1 = 3 · 3 + 1 = 10`   ·   `N_total = N_ficha^4 = 10 000`   ·   `S_T1..T3 = 1`   ·   `S_T4 = N_ficha = 10`

**Variables:** `n_urg` = 3 (Alta, Media, Baja), `n_resp` = 3 (Vera, Guardián, Dirección); el `+ 1` es «Devolver». `S` = salidas aceptadas por ficha. **Rango:** enteros fijos del slice. **Example:** soluciones totales = `1 · 1 · 1 · 10 = 10` de `10 000` desenlaces de las cuatro fichas; la probabilidad de acertar T1–T3 al azar a la primera es `(1/10)^3 = 0,001`; T4 es `10/10 = 1`. Opciones erróneas por ficha de T1–T3: `N_ficha − 1 = 9` (8 combinaciones + «Devolver»).

### P4-F2 · Coste de la fuerza bruta (D-W1)

Con `lock: NONE` no hay `delay_s` ni `reset_after_s` (P4-R8): el coste de un intento fallido es solo el de los gestos. Una combinación = 2 clics; «Devolver» = 1 clic; `t_clic` = 0,4 s† (F6 de 9).

`C_fallo_peor(ficha) = 8 · (2 · t_clic) + 1 · t_clic = 6,4 + 0,4 = 6,8 s`   ·   `C_fallo_medio(ficha) = 4,5 · (6,8 / 9) ≈ 3,4 s`   ·   `T_peor(T1–T3) = 3 · (6,8 + 0,8) = 22,8 s`   ·   `T_medio(T1–T3) ≈ 3 · (3,4 + 0,8) = 12,6 s`

**Variables:** 9 opciones erróneas por ficha (P4-F1); el orden de prueba es aleatorio (media de 4,5 intentos fallidos antes de acertar; coste medio por fallo `6,8/9 ≈ 0,76 s`); el último término `0,8 s` es el intento correcto. **Rango:** `T ∈ [2,4 s, 22,8 s]` (mínimo: acertar las tres a la primera = `3 · 0,8`). T4: un solo gesto, 0 s de fuerza bruta (no hay nada que forzar). **Comparación con F6 de 9:** F6 estima ≈ 22 s para las tres; el valor aquí (22,8 s) incluye el intento correcto y el coste menor de «Devolver»; es el mismo orden de magnitud. **Veredicto de diseño (D-W1, vigente para T1–T3):** forzar T1–T3 cuesta de media ≈ 13 s, menos que leerlas y decidirlas (P4-F3: 20–60 s por ficha, nominal 30 s); es **posible y barato**. No es estrategia dominante en el sentido de Sirlin porque no salta ningún contenido que dé la historia: la carga narrativa de P4 es **T4** (que no puede forzarse: hay un solo gesto) y `I-05` (llega después). Se acepta y se instrumenta (regla 32 de 9: rechazos por ficha); decisión D14-4.

### P4-F3 · Tiempo esperado frente a F7 de 9

`T_P4 = t_entrada + t_regla + Σ_{i=1..3}(t_i + k_i · t_fallo) + t_T4 + t_pistas + t_salida`

**Variables (todas †, jugador nuevo):** `t_entrada` = 2,4 s (`BOX_C2_OPEN` 1,4 + `t_vista_entrada_s` 1,0 propuesta de 10); `t_regla` = 5 s (lectura de la regla); `t_i` = leer y decidir una ficha, 20–30–60 s (mín–nominal–máx); `k_i` = fallos por ficha, 0–1–3; `t_fallo` = 12 s (0,8 s de gestos + 1,5 s de «No corresponde» + ~10 s de repensar); `t_T4` = 20–45–90 s (sin límite superior; ver P4-F4); `t_pistas` = 0–0–30 s (hasta dos peticiones de ~15 s desde la pausa); `t_salida` = 2,0 s (`close_view_after_s` 1,5 + 0,5 de cámara).
**Cálculo (nominal):** `2,4 + 5 + 3 · (30 + 1 · 12) + 45 + 0 + 2 = 180,4 s ≈ 3,0 min`. **Mínimo:** `2,4 + 5 + 3 · 20 + 20 + 0 + 2 = 89,4 s ≈ 1,5 min`. **Máximo:** `2,4 + 5 + 3 · (60 + 3 · 12) + 90 + 30 + 2 = 417,4 s ≈ 7,0 min`.
**Contraste con F7 (2–4 min):** el nominal (3,0 min) cae dentro; el mínimo queda por debajo (jugador que deduce rápido: aceptable, el objetivo es de un jugador nuevo medio); el máximo (7,0 min) lo supera, pero con tres fallos por ficha y 90 s en T4. **Alerta de playtest:** mediana < 1,5 min (puzle trivial: sospecha de fuerza bruta, P4-F2) o > 5 min (T1–T3 poco deducibles: subir la explicitud del texto o mover el nivel 1). Esto no prueba la duración del slice (F9 de 9).

### P4-F4 · La elección de T4 apenas se percibe (D-W10)

Hallazgo vigente de la revisión cruzada (r2): la regla visible empuja a «Devolver»; T4 usa los mismos sellos; queda fija al primer gesto; su único efecto se oye tras 20 s de silencio en la llamada. Se mide con tres indicadores de playtest (no de código), definidos aquí para que el registro de 9 (regla 32) los calcule:

`r_T4 = t_T4 / media(t_1, t_2, t_3)`   ·   `p_RET = n_returned / n_resueltos`   ·   `p_oir = n_que_oyen_VO_G_14 / n_resueltos`

**Variables:** `t_T4`, `t_i` = tiempo entre la primera interacción con la ficha y su sello (reloj de juego); `n_returned` = partidas con `t4_decision = returned`; `p_oir` es el porcentaje de jugadores que llegan a los 20 s de silencio de la llamada y oyen `VO_G_14_*` (lo mide 22; ver su F3). **Objetivos†:** `r_T4 ≥ 1,0` (T4 se piensa al menos tanto como una ficha de solución única; `r_T4 < 0,5` = se decide sin reflexión, no se percibe como elección); `0,25 ≤ p_RET ≤ 0,75` (si cualquiera de las salidas queda por debajo del 25 %, la otra es en la práctica «la correcta» y se rompe el pilar *Ambivalencia*); `p_oir`: **sin objetivo propio**, solo se informa. **Ejemplo:** `t_1..3 = 30, 40, 20 s` ⇒ media 30 s; `t_T4 = 45 s` ⇒ `r_T4 = 1,5` (correcto). 
**Sesgo de orden previsto (explicación, no regla):** quien decide T4 **tras** T1–T3 ha aprendido que «Devolver» es incorrecto en tres fichas seguidas y tiende a asignar; quien la decide **primero** lee la regla («Devuelve lo que no te corresponde») y tiende a devolver. El orden de las fichas es libre (pilar *Autonomía*); no se corrige, se mide. **Mitigaciones aplicadas aquí:** sellos y sonido idénticos (P4-R10); ninguna pista toca T4 (P4-R15); el texto de T4 no lleva ningún marcador visual distinto salvo el nombre tachado del slice. **Lo que no puede arreglar 14** (propiedad de 22 y del slice): que quien responde antes de 20 s no oye diferencia alguna; queda como Open Question 2.

### P4-F5 · Cierre tras resolver

`t_camara_vuelta = t_ultimo_sello + close_view_after_s + t_devolver = t_ultimo_sello + 1,5 + 0,5`

**Variables:** `close_view_after_s` 1,5 s† (F4 de 9), `t_devolver` 0,5 s (2, regla 18). **Rango:** ≥ 2,0 s. **Example:** el jugador sella la última ficha en t = 120,0 s ⇒ `SOLVED` y escrituras (P4-R13) en t = 120,0 s; petición de cierre a 121,5 s; cámara de vuelta a 122,0 s. Las escrituras no esperan a la presentación (9, regla 16).

## Edge Cases

- **P4-E1. T4 decidida antes que T1–T3.** Queda sellada y bloqueada; `t4_decision` **aún no** se escribe (P4-R13). Cerrar y cargar antes de resolver la borra (D9-8): T4 puede decidirse de nuevo, de la misma o de la otra forma (AC-58 de 9).
- **P4-E2. T1–T3 aceptadas y T4 sin decidir.** El puzle sigue `ACTIVO`; `caja_c2` y P6 esperan; sin temporizador ni pista que decida T4. `request_hint(P4, 3)` no cambia nada (T1 ya correcta; AC-55 de 9).
- **P4-E3. Nivel 3 con T2–T4 aceptadas y T1 pendiente.** `AUTO_SOLVE_ELEMENT` resuelve T1, el marco llama a `evaluate()` y obtiene `SOLVED`: `t4_decision` con el valor de T4, luego `caja_c2` (AC-43 de 9). Sin esto el puzle quedaría completo y `ACTIVO` para siempre.
- **P4-E4. Un selector elegido y cancelación** (`atrás`, pausa, pérdida de foco): la ficha conserva su selección, sin `REJECT` ni evaluación (9, regla 11b).
- **P4-E5. Segundo `seleccionar` sobre una ficha ya bloqueada:** se ignora, sin sonido (la ficha no se reevalúa). Un `seleccionar` sobre un segmento ya elegido no hace nada (idempotente).
- **P4-E6. «Devolver» con un selector ya elegido:** vale `RETURN`; la selección previa se descarta (los selectores se desactivan, P4-R5). En T1–T3 es `REJECT`: la ficha vuelve a neutra (también la selección previa).
- **P4-E7. Dos `seleccionar` en el mismo fotograma sobre fichas distintas** (cursor virtual con mando): se procesan en el orden de llegada; cada ficha se evalúa por separado; un segundo `SOLVED` en el mismo fotograma se descarta (S9 de 9).
- **P4-E8. `t4_decision` ya tiene valor con `caja_c2` falso** (consola o dato corrupto): 9 no lo rescribe al cargar; si el jugador resuelve con una decisión distinta, el estado rechaza la escritura (regla 6 de 3) y se trata como error de datos, como cualquier hecho de un solo sentido (9, Edge Cases). Con el mismo valor, la reescritura es idempotente.
- **P4-E9. `caja_c2` verdadero por consola con la vista abierta:** 9 reconcilia a `RESUELTO` en silencio y cierra la vista (`sistema`); 10 no abre `D01b` de nuevo (AC-06b de 10).
- **P4-E10. Carga con `caja_c2` verdadero y `t4_decision` sin fijar** (solo consola): T4 se dibuja «ACEPTADA» (sello por defecto) y 22 usa `VO_G_14_RET` con una advertencia (regla 16 de 22). No se bloquea nada.
- **P4-E11. Orden P4 antes que P3:** válido; `I-05` llega antes que `I-06a` (regla 24 de 9; edge 18 de 10).
- **P4-E12. Textos largos o subtítulos** (accesibilidad de texto): el rechazo «No corresponde» y los sellos nunca tapan los selectores; si el tamaño de texto crece, la ficha crece, no se recorta (ux).
- **P4-E13. Mando:** el cursor virtual de 7 selecciona; la separación de 128 px (R = 64) evita ambigüedad de la atracción asistida (F5b de 7). Con «reducir movimiento» el rechazo no vibra (P4-R8).
- **Estrategias degeneradas (Sirlin).**
  - **D-W1 · Fuerza bruta en T1–T3.** Posible y barata (≈ 13 s de media, P4-F2); no salta contenido narrativo (T4 e `I-05` no se pueden forzar). Aceptada e instrumentada. Alternativa descartada: que el rechazo reinicie las demás o añada espera (castigo, contradice *Tensión sin castigo*).
  - **D-W10 · T4 apenas se percibe como elección.** Mitigaciones y medición en P4-F4; parte queda fuera de 14 (Open Question 2).
  - **Pedir la pista 3 y decidir T4 por azar:** inocuo; ambas salidas son válidas.
  - **Decidir T4 sin leerla:** inocuo mecánicamente; `r_T4 < 0,5` lo detectaría en playtest.
  - **Guardar y cargar para «ver» la otra salida:** `t4_decision` es de un solo sentido pero solo se escribe al resolver; antes de resolver se puede probar cada salida sin consecuencias; una vez resuelto, la partida no permite deshacer. Es coherente con la elección única de P6 (D-14) y no se corrige.

## Dependencies

**Aguas arriba (de qué depende 14).** *La dureza la declara el dependiente (14).*

| Sistema | Tipo | Qué necesita 14 | Contrato / origen |
|---|---|---|---|
| 9 Marco de puzles | **Dura** | Ciclo de vida, `PuzzleController`, política `PER_ELEMENT`, política de fallo (regla 14), orden de escritura (regla 16), regla 12c (T4), pistas (reglas 25–27), validación de datos (regla 29), `GameClock` (36) | Regla 3, 9, 12, 12b, 12c, 14, 16, 25 |
| 10 Caja y compartimentos | **Dura** | Dueño de `D01b`: `get_view_gate`, `BOX_C2_OPEN`, `set_final_pose(2)`, decorado de `I-05` | Reglas 7, 17 de 10; 9 regla 7 |
| 18 Base de contenido narrativo | **Dura** (en validación y en datos) | `PISTA_P4_N1`, `PISTA_P4_N3`, textos de las fichas T1–T4, sellos «ACEPTADA»/«DEVUELTA», «No corresponde», `DOC_LISTA_TAREAS` | 18, reglas 1, 5, 20, 23; D18-9 |
| 7 Interacción e inspección | Blanda (vía 9) | `PointerEvent`/`seleccionar`, `elements()`, `pick_min_px`, R₁+R₂, F6 (px por metro) | 7, reglas 20–22, F6 |
| 3 Estado y bus de eventos | Blanda (vía 9) | Hechos `t4_decision` y `caja_c2` (los escribe 9) | 3, regla 6 |
| 2 Jugador · 6 Ajustes | Blanda (vía 9) | Regreso de cámara; `reducir_movimiento` | 9, reglas 11 y 14b |
| 17 Sistema de pistas | Blanda (cuando exista) | Pide `request_hint(P4, n)` | 9, regla 26 |

**Aguas abajo (quién depende de 14).**

| Sistema | Tipo | Qué recibe de 14 |
|---|---|---|
| 22 Llamada telefónica | Indirecta (por el estado 3; la declara 22, el dependiente) | `t4_decision` (`returned`/`assigned`) para elegir `VO_G_14_RET`/`VO_G_14_ASG`. 14 no llama a 22 |
| 20 Documentos y bolsillo | Blanda (la declara 20) | `I-05` derivado de `caja_c2`; releíble con `repasar_bolsillo` |
| 10 Caja y compartimentos | Dura (recíproca de la anterior) | Resultado de P4 por `caja_c2` y «compartimento completado» (2) |
| 9 Marco de puzles | Dura (recíproca) | Datos de P4 y controlador |
| 16 Puzle 6 · Decisión | Dura (por el estado) | `caja_c2` es requisito de P6 (`requires.all`) |
| 5 Guardado y carga | Indirecta | `caja_c2`, `t4_decision` en la instantánea; causa `compartment_done:2` |

**Circularidad:** la de 9 ↔ 10 existente; 14 no añade ninguna. No hay dependencia circular con 22 (14 → estado → 22).

## Tuning Knobs

**F** = feel, **C** = curva, **G** = gate. † = a validar en playtest. Viven en `assets/data/puzzles/puzzles.json` (ver «Datos del puzle»), nunca en código.

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `no_corresponde_s` | F | **1,5 s** (slice B.4) | 1,0–3,0 | Duración del mensaje de ficha incorrecta; el rango mínimo es legible, el máximo no estorba (no bloquea la entrada) |
| `close_view_after_s` (P4) | F | 1,5 s† | 0,5–3,0 | Cierre tras `SOLVED` (F4 de 9) |
| `hover_highlight_s` (nivel 2) | F | continuo mientras el cursor esté sobre la ficha | n/a | Resaltado de `Tn/body` al pasar; no es un temporizador |
| `stamp_s` (`SFX_STAMP`) | F | lo fija 23 | — | Duración del sello; la misma para las dos salidas de T4 |
| `lock` | G | **`NONE`** | fijo | Una ficha rechazada se puede reeditar al instante; cambiarlo rompe F2 y `lock_max_s` |
| `elements_min_separation_px` | F | 128 (R = 64) | 128–176 | Separación mínima entre centros (7, regla 22); mayor = más legible, ocupa más |
| `view_distance_m` (D01b) | F | pendiente (Open Question 1) | lo fija 7/10 | Escala de la vista (F6 de 7) |
| `t4_accept` | C | `[RETURN, ASSIGN]` | no editable (decisión del usuario, D9-39) | Qué acciones acepta T4; añadir una exigencia reintroduciría una respuesta errónea |
| `t_clic` (modelo) | — | 0,4 s | 0,3–0,6 | Solo de P4-F2/P4-F3 (no es un knob de juego) |
| Objetivos de playtest: `r_T4`, `p_RET` | G | ≥ 1,0 · 0,25–0,75 | ver P4-F4 | Umbrales de verificación, no de código |

No expone knobs de dificultad (no hay selector de dificultad ni límite de intentos). Las soluciones de T1–T3 son **datos de contenido** (Alta/Vera, Media/Guardián, Baja/Dirección) fijados por el slice: cambiarlas exige cambiar los textos de las fichas (18) y la explicación del nivel 3.

## Acceptance Criteria

Tipos: **L** = lógica (prueba automática con `GameClock` falso, en `tests/unit/puzzle_4/`), **I** = integración (`tests/integration/puzzle_4/` o playtest documentado), **PV** = playtest / visual (captura retenida en `production/qa/evidence/` o sesión de playtest). Cada AC cita la regla de este GDD.

**Funcionales**

- **AC-14-01 (P4-R1, I):** **GIVEN** una partida nueva con la caja abierta a D, **WHEN** `get_view_gate('D01b')` y se pulsa D01b, **THEN** devuelve `OPEN`, la vista se abre y P4 está `ACTIVO` sin haber resuelto ningún otro puzle.
- **AC-14-02 (P4-R2, L):** **GIVEN** la vista abierta, **WHEN** se pide `elements()`, **THEN** hay 28 elementos con `atraccion` verdadero, todos ≥ 44 px, con separación entre centros ≥ 128 px, y cada ficha expone exactamente 3 + 3 segmentos y `return`.
- **AC-14-03 (P4-R4, PV):** **GIVEN** la vista abierta en cualquier estado, **THEN** el texto de `PISTA_P4_N1` es visible sin interacción, idéntico al de 18, sin color moral (captura retenida).
- **AC-14-04 (P4-R5, R6, L):** **GIVEN** T1 neutra, **WHEN** se elige solo «Alta», **THEN** no hay evaluación, ni sonido, ni mensaje; **WHEN** se elige luego «Vera», **THEN** se evalúa una vez y T1 queda «ACEPTADA» y bloqueada con `SFX_STAMP`.
- **AC-14-05 (P4-R7, L):** **GIVEN** el conjunto de las 10 acciones por ficha, **WHEN** se ejecutan sobre T1, T2 y T3 por separado, **THEN** exactamente 1 por ficha devuelve `PARTIAL` (T1 Alta/Vera, T2 Media/Guardián, T3 Baja/Dirección) y 9 devuelven `REJECT` (8 combinaciones y «Devolver»).
- **AC-14-06 (P4-R8, L):** **GIVEN** T1 aceptada y T2 con Alta/Vera, **WHEN** se evalúa T2, **THEN** suena `SFX_REJECT`, T2 queda neutra de inmediato, aparece «No corresponde» durante 1,5 s (± un fotograma), T1 sigue bloqueada, y T2 acepta un `seleccionar` en el fotograma siguiente (AC-09 de 9).
- **AC-14-07 (P4-R8, L):** **GIVEN** 20 rechazos consecutivos, **THEN** el estado del juego, los textos y los tiempos son idénticos al primer rechazo: ningún contador, ningún cambio de dificultad, ninguna escritura de hecho.
- **AC-14-08 (P4-R9, L):** **GIVEN** T4 en cualquier estado y cualquiera de las 10 acciones, **THEN** el controlador nunca devuelve `REJECT`; no aparece «No corresponde» ni suena `SFX_REJECT` por T4 (AC-57 de 9).
- **AC-14-09 (P4-R10, PV):** **GIVEN** T4 aceptada con «Devolver» y otra partida con una combinación cualquiera, **THEN** el sello, la animación y el sonido son idénticos salvo la palabra («DEVUELTA»/«ACEPTADA») y no hay rojo ni verde en ninguno (captura de ambos).
- **AC-14-10 (P4-R12, L):** **GIVEN** T1–T3 aceptadas y T4 sin decidir, **THEN** P4 sigue `ACTIVO`, `caja_c2` falso, `t4_decision` sin fijar, y no hay efecto por el paso del tiempo (reloj falso +600 s).
- **AC-14-11 (P4-R13, L):** **GIVEN** T1–T3 aceptadas, **WHEN** T4 se devuelve, **THEN** las escrituras ocurren en este orden y en el mismo fotograma: `t4_decision` = `returned`, `caja_c2` = verdadero, `EV_PUZZLE_SOLVED_P4` con `rewards = [I-05]`, «compartimento completado» (2) (AC-55 de 9).
- **AC-14-12 (P4-R13, L):** **GIVEN** el mismo estado, **WHEN** T4 se asigna con cada una de las 9 combinaciones, **THEN** `t4_decision` = `assigned` antes de `caja_c2`, en las 9 (AC-56 de 9).
- **AC-14-13 (P4-R13, L):** **GIVEN** T4 decidida y T1–T3 pendientes, **WHEN** se guarda y se carga, **THEN** `t4_decision` sigue sin fijar y T4 puede decidirse de nuevo de cualquier forma (AC-58 de 9).
- **AC-14-14 (P4-R15, L):** **GIVEN** `request_hint(P4, 2)`, **WHEN** el cursor pasa sobre `T2/body`, **THEN** se resalta; el movimiento del cursor no reinicia `idle` (F3 de 9).
- **AC-14-15 (P4-R15, L):** **GIVEN** `request_hint(P4, 3)` sobre un P4 con T2, T3 y T4 decididas y T1 pendiente, **THEN** T1 se resuelve con su explicación, `evaluate()` devuelve `SOLVED` y se cumple AC-14-11 (AC-43, AC-33 de 9). **GIVEN** T4 sin decidir, **THEN** el nivel 3 no cambia T4.
- **AC-14-16 (P4-R15, L):** **GIVEN** `puzzles.json`, **WHEN** corre la validación (regla 29 de 9), **THEN** P4 declara exactamente 3 niveles; los niveles 1 y 3 referencian `PISTA_P4_N1` y `PISTA_P4_N3` existentes en 18; el nivel 2 no lleva clave.
- **AC-14-17 (P4-R16, I):** **GIVEN** `caja_c2` verdadero, **THEN** `has_item('I-05')` es verdadero, ni 9 ni 10 abren ninguna lectura, y `repasar_bolsillo()` abre `I-05` tras `I-07` según el orden de 20.
- **AC-14-18 (P4-R17, L):** **GIVEN** el código del controlador de P4, **THEN** no contiene escrituras de hechos ni emisión de avisos (revisión estática o prueba con un estado simulado de solo lectura).
- **AC-14-19 (P4-R18, I):** **GIVEN** una carga con `caja_c2` verdadero y `t4_decision` = `returned`, **THEN** P4 `RESUELTO` en silencio, T1–T3 «ACEPTADA» y T4 «DEVUELTA»; con `assigned`, T4 «ACEPTADA»; sin sonidos ni avisos.
- **AC-14-20 (P4-R18, L):** **GIVEN** una carga con `caja_c2` falso tras haber sellado fichas, **THEN** las cuatro fichas están neutras.
- **AC-14-21 (P4-R19, L):** **GIVEN** T3 con solo la urgencia elegida y `atrás`, **WHEN** se reabre la vista en la misma sesión, **THEN** T3 conserva la selección y no hubo `REJECT`.
- **AC-14-22 (P4-R20, L):** **GIVEN** cualquier estado de P4, **THEN** no existe en datos ni código ningún temporizador de solución, límite o contador de intentos (revisión de `puzzles.json`: ningún `*_timeout`, `max_attempts`).
- **AC-14-23 (P4-E3, L):** **GIVEN** P4 con T4 devuelta, **WHEN** T1 por el nivel 3 completa el puzle, **THEN** no queda ningún estado `ACTIVO` con todos los elementos correctos (S7 de 9; oráculo de la regla 30 con 1.000 secuencias).
- **AC-14-24 (P4-E1, L):** **GIVEN** el orden P4, P3, P5, P6 y P3, P5, P4, P6, **THEN** ambos terminan con `caja_completa` verdadero (AC-05 de 9).

**Experienciales (PV)**

- **AC-14-25 (P4-F3, PV):** **GIVEN** 6 o más jugadores nuevos, **THEN** la mediana de duración de P4 está entre 2 y 4 min (F7 de 9; alerta fuera de 1,5–5 min).
- **AC-14-26 (P4-F4, PV):** **GIVEN** las mismas partidas, **THEN** `r_T4 ≥ 1,0` y `0,25 ≤ p_RET ≤ 0,75`; si no, se abre una revisión de diseño de T4 (no un balance numérico).
- **AC-14-27 (Pilar 1, PV):** **GIVEN** un cuestionario posterior, **THEN** ningún jugador describe una salida de T4 como «la equivocada»; al menos la mitad dice que fue una elección suya.
- **AC-14-28 (Pilar 4, PV):** **GIVEN** observación de playtest, **THEN** ningún jugador describe P4 como «con prisa» ni espera una cuenta atrás.

## Datos del puzle

Entrada de `assets/data/puzzles/puzzles.json` según el esquema de 9 (regla 4). Valores en **negrita en los Tuning Knobs** vienen del slice (Anexo B.4); `shake_s` y `close_view_after_s` son †. `solution` solo lo interpreta el controlador de P4 (`urgency` ∈ `HIGH|MEDIUM|LOW`; `owner` ∈ `VERA|GUARDIAN|DIRECTION`; los nombres son identificadores de código en inglés).

```json
{
  "id": "P4", "mode": "VIEW", "view": "D01b",
  "solved_flag": "caja_c2",
  "requires": { "all": [] },
  "validation": { "policy": "PER_ELEMENT" },
  "solution": {
    "T1": { "accept": ["ASSIGN"], "urgency": "HIGH",   "owner": "VERA" },
    "T2": { "accept": ["ASSIGN"], "urgency": "MEDIUM", "owner": "GUARDIAN" },
    "T3": { "accept": ["ASSIGN"], "urgency": "LOW",    "owner": "DIRECTION" },
    "T4": { "accept": ["RETURN", "ASSIGN"] }
  },
  "on_partial": { "sfx": "SFX_STAMP", "stamp_text_keys": { "ASSIGN": "UI_P4_SELLO_ACEPTADA", "RETURN": "UI_P4_SELLO_DEVUELTA" } },
  "on_reject": { "sfx": "SFX_REJECT", "shake_s": 0.4, "reset_after_s": 0.0, "lock": "NONE",
                 "message_key": "UI_P4_NO_CORRESPONDE", "message_s": 1.5, "applies_to": ["T1", "T2", "T3"] },
  "on_solved": {
    "write": [ { "flag": "t4_decision", "value_from": "t4_action", "map": { "RETURN": "returned", "ASSIGN": "assigned" } },
               { "flag": "caja_c2", "value": true } ],
    "compartment": 2, "rewards": ["I-05"], "close_view_after_s": 1.5
  },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "IMMEDIATE" },
  "persist": [],
  "elements": { "atraccion_desactivada": false, "min_separation_px": 128 },
  "hints": [
    { "level": 1, "trigger": "REQUEST", "availability": "ALWAYS",
      "effects": [ { "type": "TEXT", "key": "PISTA_P4_N1" } ] },
    { "level": 2, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "AFFORDANCE", "name": "HOVER_HIGHLIGHT", "targets": ["D01b/T1/body", "D01b/T2/body", "D01b/T3/body", "D01b/T4/body"] } ] },
    { "level": 3, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "AUTO_SOLVE_ELEMENT", "target": "D01b/T1" },
                   { "type": "TEXT", "key": "PISTA_P4_N3" } ] }
  ]
}
```

Notas de datos: (1) `value_from`/`map` es una extensión propuesta del esquema para que `on_solved.write` lea la carga útil del veredicto (9 regla 12c ya lo exige y 9 la declara como «dato, no caso especial»; Cambios requeridos en 9). (2) Las claves `UI_P4_*` son **propuestas** para 18 (Cambios requeridos); `PISTA_P4_N1` ya existe y se usa también como texto fijo de la regla (D18-3). (3) `reset_after_s` = 0 y `lock: NONE` cumplen `lock_max_s` (≤ 2,0 s). (4) El estado inicial (ninguna ficha aceptada) no satisface la solución, como exige la regla 29.

## Decisiones tomadas

Decididas del lote autónomo con recomendación propia (el usuario las aprueba al final del lote). **Del usuario, ya tomadas:** T4 acepta devolver o asignar y ninguna es incorrecta (D9-39); «No corresponde» solo para T1–T3 (D18-9); la línea de la llamada cambia según `t4_decision` (propuesta pendiente de narrative-director: no se redacta aquí).

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D14-1 | Los selectores son **segmentos con todas las opciones visibles**; una combinación = 2 clics | Desplegables (3 clics y opciones ocultas) | F6 de 9 ya modela 2 clics por combinación; no oculta información (pilar *Información incompleta* del puzle: todo lo visible está en la ficha); mejor con mando |
| D14-2 | Elementos con atracción asistida activa (`atraccion_desactivada` falso), R = 64, separación ≥ 128 px | `atraccion_desactivada: true` para toda la vista | La atracción ayuda al mando y a la motricidad; 28 elementos caben con 128 px (P4-R2); evita que 9 tenga que tolerar una excepción |
| D14-3 | Los sellos «ACEPTADA» y «DEVUELTA» y su sonido son idénticos salvo la palabra | Sello distinto para devolver (p. ej. otro color o sonido) | Pilar *Ambivalencia*: ni color ni sonido codifican «bien/mal»; anti-pilar de moral binaria |
| D14-4 | D-W1: se **acepta** la fuerza bruta en T1–T3 (≈ 13 s de media) y se instrumenta | Reiniciar las demás fichas, añadir espera o contar fallos | Cualquiera es un castigo (pilar *Tensión sin castigo*); la ficha acertada ya se sella en el acto (mitigación de la revisión cruzada) y T4 no es forzable |
| D14-5 | «No corresponde» no dice qué selector falló | Resaltar el selector erróneo | Reduce la fuerza bruta a ~3 intentos por ficha y deja de ser deducción; el texto de la ficha ya contiene la solución |
| D14-6 | El orden de las fichas es libre y el **sesgo de orden de T4** se mide (P4-F4), no se corrige | Fijar T4 en último lugar (desbloquearla tras T1–T3) | Pilar *Autonomía*; desbloquear T4 la convertiría en un guion y reforzaría el sesgo hacia asignar |
| D14-7 | No hay pistas `IDLE` en P4 | Pista de nivel 2 automática tras N segundos de inactividad | El slice declara «sin temporizador»; el reparto lo hará 17 |
| D14-8 | La regla del tablero es **a la vez** el texto fijo y la pista de nivel 1 (`PISTA_P4_N1`, sin clave `UI_` duplicada) | Dos claves | D18-3 y regla 20 de 18 |
| D14-9 | Se sigue el Anexo B.4 (nivel 1 = regla visible) y no la lista del §10.4 (nivel 1 = marca de color de urgencia) | Añadir marcas de color de urgencia | B.4 es más específico y ya lo siguen 9 y 18; una marca de color por urgencia sería un tercer canal de información y arriesga la regla de «sin color moral»; se registra la discrepancia (Open Question 3) |
| D14-10 | Al cargar con `caja_c2` verdadero las fichas se muestran selladas, y T4 según `t4_decision` | Mostrar T4 siempre «ACEPTADA» | `t4_decision` es el único dato disponible y ya lo guarda el estado; los selectores de una T4 asignada no se guardan (D9-40) |
| D14-11 | El jugador no recibe ningún aviso de que su elección «se ha recordado» | Un texto o sonido de confirmación | Pilar *Información incompleta* y anti-pilar de medidores; la elección se nota en la llamada, no en la interfaz |
| D14-12 | `shake_s` = 0,4 s† de vibración de la ficha rechazada, sin bloqueo | Igual que P1 (1,2 s) | Con `lock: NONE` el jugador reedita al instante; una vibración larga estorbaría |
| D14-13 | Disposición en 4 columnas (una por ficha) | 2 × 2 | 3 filas × 128 px por ficha no caben en dos filas de fichas en 1080 px |

## Open Questions

| # | Pregunta | Quién | Efecto |
|---|---|---|---|
| 1 | **Tamaño físico y distancia de vista de `D01b`.** El layout (4 columnas, 28 elementos ≥ 128 px) ocupa ≈ 85 % del ancho del viewport (1.632 de 1.920 px). Con el FOV vertical de 70° la anchura del tablero en metros es `W = 2,116 · d` (F6 de 7): un tablero de 0,22 m exige `d ≈ 0,10 m`, demasiado cerca; con `d = 0,35 m` el tablero mediría 0,74 m. Hace falta que 10, 7 y arte fijen tablero y `d` compatibles (p. ej. el tablero se desliza fuera del compartimento) | Arte / 7 / 10 | Bloquea la maquetación y `view_distance_m` de D01b |
| 2 | **D-W10.** El único efecto de `t4_decision` se oye tras 20 s sin responder en la llamada (slice §11, escena 7); quien responde antes no oye diferencia. ¿Se acepta, o se amplía el efecto (otra línea o la carta)? Ampliar cambia el tono y el alcance de 22 y del slice | Usuario / narrative-director | No se decide aquí; 14 solo mide `p_oir` (P4-F4) |
| 3 | **Discrepancia del slice:** §10.4 dice que la pista de nivel 1 es una marca de color de urgencia en cada ficha; B.4 y 18 dicen «la regla del tablero es visible». Se sigue B.4 (D14-9). El slice debería alinear §10.4 | Usuario (autoriza el cambio del slice) | Cambia el contenido de la pista 1 |
| 4 | **`VO_G_14_ASG`** («Sigo aquí. La carta a Dirección ya va firmada.»): propuesta pendiente; D-W9 señala que casi responde «quién firmó» (pilar *Información incompleta*) y suena igual con las 9 combinaciones, algunas incoherentes con el texto de la ficha. 14 no la redacta | Narrative-director | Ninguno en 14 |
| 5 | **Valores de playtest.** `t_i`, `t_T4`, `k_i` de P4-F3 y los objetivos de P4-F4 son estimaciones† | Playtest (AC-14-25 a 27) | Ajuste de F7 de 9 si la mediana sale de 2–4 min |
| 6 | **Textos de interfaz:** etiquetas de selectores y botón, sellos y «No corresponde» (claves `UI_P4_*` propuestas) | Writer / 18 | Sin ellos el puzle no es completable en español |

## Cambios requeridos en otros GDDs

No se ha editado ningún archivo existente. Propuestas:

1. **9 Marco de puzles:** (a) esquema de `on_solved.write` (regla 4): admitir `value_from` + `map` para escribir `t4_decision` desde la carga útil del veredicto (regla 12c ya lo exige); (b) F6: el coste de P4 queda en ≈ 22,8 s para T1–T3 (incluye el intento correcto; P4-F2) en lugar de ≈ 22 s, o dejar la cota; (c) Dependencies: citar `puzzle-4-tablero-de-tareas.md` como GDD del 14; (d) F7: sin cambio salvo que el playtest mueva la mediana.
2. **18 Base de contenido:** claves propuestas `UI_P4_NO_CORRESPONDE`, `UI_P4_SELLO_ACEPTADA`, `UI_P4_SELLO_DEVUELTA`, `UI_P4_URGENCIA` y `UI_P4_RESPONSABLE` (rótulos), `UI_P4_URG_ALTA/MEDIA/BAJA`, `UI_P4_RESP_VERA/GUARDIAN/DIRECCION`, `UI_P4_DEVOLVER`, con texto provisional y marcador de pendiente (regla 23 de 18). Los textos de las fichas (T1–T4) ya son de 18. **Sin** clave para ningún aviso de «elección recordada» (D14-11).
3. **10 Caja:** `D01b` necesita tamaño del tablero y `view_distance_m` compatibles con el layout (Open Question 1); el papel de `I-05` es decorado sobre el tablero y no puede tapar selectores ni sellos; añadir 14 en Dependencies como dependiente (blanda, por `caja_c2`).
4. **7 Interacción:** catálogo de `D01b`: `t_vista_entrada_s`, distancia, FOV y los 33 IDs de elemento `D01b/...` (28 botones, 4 `body`, `rule`; P4-R2); P4 no declara `atraccion_desactivada`.
5. **22 Llamada telefónica:** citar 14 en Dependencies (indirecta, por `t4_decision`); sin cambio de comportamiento. La línea `VO_G_14_ASG` sigue pendiente de narrative-director.
6. **20 Documentos y bolsillo:** sin cambio; `I-05` sigue siendo `DOC_LISTA_TAREAS` (fila de 14 como origen del ítem).
7. **systems-index:** fila 14 → `Borrador (lote Feature 3) — pendiente de review`, enlace a este archivo, dependencias `9, 10, 18`; dependientes: 22 (indirecta) y 20, 10 (blandas).
8. **Slice (con autorización del usuario):** alinear §10.4 con B.4 en la pista de nivel 1 (Open Question 3).
9. **3 Estado y bus:** confirmar `t4_decision` como hecho con `owner = 9` (ya listado en D.2).

## Entradas para el registro

Propuestas para `design/registry/entities.yaml` (no se ha editado):

```yaml
constants:
  - name: no_corresponde_s
    value: 1.5
    unit: s
    range: [1.0, 3.0]
    source: design/gdd/puzle-4-tablero-de-tareas.md
    note: "slice B.4; solo T1-T3; no bloquea la entrada"
  - name: p4_options_per_card
    value: 10
    unit: count
    source: design/gdd/puzle-4-tablero-de-tareas.md
    note: "3 urgencias x 3 responsables + Devolver"
  - name: p4_min_element_separation_px
    value: 128
    unit: px
    range: [128, 176]
    source: design/gdd/puzle-4-tablero-de-tareas.md
    note: "R = 64 por elemento (regla 22 de 7)"
formulas:
  - name: p4_bruteforce_worst_s
    output_range: [2.4, 22.8]
    source: design/gdd/puzle-4-tablero-de-tareas.md
    note: "T1-T3, t_clic 0,4 s; T4 no es forzable"
  - name: p4_expected_duration_s
    output_range: [89.4, 417.4]
    nominal: 180.4
    source: design/gdd/puzle-4-tablero-de-tareas.md
    note: "contraste con F7 de 9 (2-4 min); estimaciones"
facts:
  - name: t4_decision
    type: enum
    values: [returned, assigned]
    initial: unset
    owner: 9
    writer_puzzle: 14
    reader: 22
    source: design/gdd/puzle-4-tablero-de-tareas.md
    note: "se escribe en on_solved antes de caja_c2; un solo sentido"
```

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Primer borrador (lote Feature 3): reglas P4-R1 a R20, fórmulas P4-F1 a F5, 28 AC, datos de `puzzles.json`, 13 decisiones y 6 preguntas abiertas. Estado: pendiente de review. |
