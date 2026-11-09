# Puzle 5 · Espejo de la diferencia

> **Estado:** Revisado (ronda de corrección 7) — pendiente de re-review
> **Sistema:** 15 (capa Feature, MVP) · **Autor:** game-designer · **Fecha:** 2026-11-09
> **Fuente de verdad:** `design/slice/slice-v0.3.md` (contenido v0.4.2): §10.5, §19.5, Anexo B.5, C.6, D.2 · **Marco:** `design/gdd/marco-de-puzles.md` (9), que este GDD **instancia, no redefine**.
> **Pilares:** Información incompleta (P5), Tensión sin castigo (P4), Autonomía como progresión (P3), El espacio expresa la emoción (P2); anti-pilar *NOT una historia explicada*.
> **Convenciones:** † = valor propuesto, a validar en playtest. ‡ = propuesta que debe confirmar el GDD del sistema afectado. «Regla N de X» = regla N del GDD del sistema X. Las claves de datos y los identificadores de código van en inglés; los IDs del slice (`VO_G_07`, `caja_c3`, `EV_PUZZLE_SOLVED_P5`…) se conservan.

## Summary

El Puzle 5 («Espejo de la diferencia», `P5`, vista `D01c`, compartimento 3 de la caja) pide girar un marco interior con superficie reflectante (θ de 0° a 90°) hasta que el reflejo de la foto del marco de la pared (`D04`) coincida con la foto de la caja (la del Puzle 3). La alineación correcta es θ* = 40° con tolerancia ±3° (±6° con `asistencia_rotacion`) mantenida 0,8 s. No existe el fallo. Al alinear, empieza una revelación diferida de 16,0 s nominales (fundido 1,2 s, contorno de la silueta de Vera 0,8 s, línea `VO_G_07` 14,0 s) que **muestra** que Vera estaba en la foto sin decirlo; solo al terminarla se escribe `caja_c3`. Si el jugador sale, la secuencia se interrumpe sin perder nada y se repite desde el principio al volver (`pendiente_revelacion`). Este GDD **instancia** el marco (9); no redefine su ciclo de vida.

## Overview

`P5` es el quinto puzle de la caja del despacho del Guardián y el único de resolución **diferida**. Su función en el slice (§10.5) es convertir la diferencia entre dos fotos (la del Puzle 3 y la del marco de la pared) en una revelación que el jugador **comprueba por sí mismo**, antes de escuchar la grabación `VO_G_07`.

El puzle tiene dos mitades de diseño distintas:

1. **El giro (mecánica).** Un único gesto continuo (`rotar`) sobre un único elemento (`D01c/frame`). El jugador observa cómo el reflejo de la foto de la pared se desplaza y se desalinea respecto a la foto de la caja, y busca el ángulo en el que ambas coinciden figura por figura. No hay penalización, ni reinicio, ni veredicto negativo (marco, regla 15): la política es `SUSTAINED` (regla 12 de 9) y solo existen `HOLDING` y `NONE`.
2. **La revelación (presentación).** Superposición, contorno de Vera y grabación. Es el momento narrativo del puzle y está al servicio del pilar *Información incompleta* y del anti-pilar *NOT una historia explicada*: la imagen enseña **un hecho observable** (una figura que existe en una foto y no en la otra) y la línea del Guardián no se acompaña de texto, flecha ni comentario de Vera.

Este GDD define: cómo se gira y cuándo cuenta la alineación; el contenido y los tiempos de la revelación; qué ocurre al interrumpirla y al cargar; las tres pistas; la accesibilidad; y los datos (`puzzles.json`, entrada `P5`). **No** define: el ciclo de vida, la escritura de hechos ni los avisos (9); la tapa y la fuente de audio de `D01c` (10); la foto del Puzle 3 (13, regla 23 de 13: recurso de arte reutilizable); la superposición y el contorno como efecto visual (29); la reproducción y el corte de la línea (23); los subtítulos (26); el reparto de pistas (17).

**Bucle.** Micro (30 s): girar, ver el reflejo acercarse o alejarse, ajustar. Meso (1,5 a 3 min, F7): llegar a la caja con `caja_c1`, comparar las dos fotos, alinear, ver la revelación. Macro: `caja_c3` es una de las tres dependencias de `P6` (la caja completa dispara el apagón y la llamada).

## Player Fantasy

El jugador **descubre por sí mismo** que Vera estaba en la foto. No recibe la noticia: gira un objeto pequeño y pesado, ve cómo dos imágenes casi iguales se encajan y, cuando lo hacen, aparece una figura que no esperaba en un sitio donde ya había sentido un hueco (S6 del Puzle 3). Después, el Guardián habla desde dentro de la caja y no explica nada: la imagen y la voz no coinciden del todo, y eso es lo que el jugador se lleva.

- **Aesthetics primarias** (MDA): *Discovery* (rango 2: comparar dos documentos y encontrar la diferencia) y *Narrative* (rango 1: un hecho observable que reordena lo que el jugador cree). *Sensation* (rango 3) como soporte: reflejo, silencio parcial y una voz íntima.
- **Pilares:** *Información incompleta* (el hecho es fijo y comprobable —Vera estaba—, la intención no se confirma), *Autonomía como progresión* (el jugador encuentra la diferencia, no se le señala antes de alinear), *Tensión sin castigo* (no hay fallo, el marco conserva su ángulo, la interrupción no cuesta nada), *El espacio expresa la emoción* (la luz y el reflejo cuentan, no el texto).
- **SDT:** *Competencia* (la alineación es legible y verificable con los ojos; el jugador sabe por qué acertó) y *Autonomía* (cualquier ritmo de giro es válido; las pistas solo se piden).
- **Lo que NO debe sentir:** que ha fallado, que le han resuelto el puzle, o que el juego le explica quién hizo qué.

## Detailed Rules

«Regla N» = regla de este GDD; «regla N de 9» = del marco. Los valores † están en «Tuning Knobs» y en «Datos del puzle».

### A. Alcance y estados

1. **Identidad.** `id` `P5`; `mode` `VIEW`; `view` `D01c`; `solved_flag` `caja_c3`; `requires.all` = [`caja_c1`]; `validation.policy` `SUSTAINED`; `resolution.kind` `DEFERRED`; `compartment` 3. Es el único puzle diferido y, con P2 y P6, uno de los tres sin `REJECT` (regla 15 de 9).
2. **Estados** (los de 9, regla 6): `BLOQUEADO` hasta `caja_c1` (dueño de la respuesta al jugador: Caja, regla 7 de 9); al activarse, 9 emite «puzle activado» con `ajar_cm` = 2 y suena `SFX_UNLOCK_SOFT` (regla 24 de 9; la animación de 10 espera a ver `D01c`). `ACTIVO` hasta que la secuencia termina; `RESUELTO` después. Nunca hacia atrás (S2 de 9).
3. **Qué posee 15.** El controlador `P5Controller` (θ, `evaluate()`, `apply_hint_effect()`, `restore_solved_presentation()`, `play_resolution(step)`), los datos de su entrada `P5` y los elementos de `D01c`. **No** escribe hechos, no emite avisos ni cambia el estado público (regla 10 de 9): devuelve veredictos. El orden de escritura de `caja_c3` y `pendiente_revelacion` es de 9 (regla 19 de 9).

### B. La vista y el giro

4. **Elementos de `D01c`** (prefijo de vista, regla de IDs de 9):

   | ID | Tipo | Descripción |
   |---|---|---|
   | `D01c/frame` | interactivo (`rotar`) | Marco interior giratorio con la superficie reflectante. Único elemento de `elements()`; `atraccion` = falso (se gira, no se señala). |
   | `D01c/reflection` | visual | Reflejo de la foto de `D04` sobre la superficie; su orientación sigue a θ. |
   | `D01c/box_photo` | visual | La foto de la caja **ya completa** del Puzle 3 (cinco figuras y el hueco S6), fija. |
   | `D01c/marks` | visual | 19 marcas, una cada 5° (0°, 5° … 90°), **sin cifras**. |
   | `D01c/mark_40` | visual | La marca de 40°; solo se ilumina con la pista nivel 3. |
   | `D01c/speaker` | visual/audio | El altavoz del compartimento; la fuente de audio 3D la ofrece 10 (`SPK_D01C`). |

   Los elementos visuales no son objetivo de puntero. Sus IDs deben existir en el catálogo de 7 y declararse en `solution.visual_elements` para que `HIGHLIGHT` y `MARK_LIT` los referencien: admitir `HIGHLIGHT` sobre elementos visuales no interactivos y el campo `solution.visual_elements` lo define el esquema v2 de 9 (Cambios requeridos; hasta que 9 lo publique, ‡).
5. **Entrada.** El gesto aceptado es `rotar` (nombre y fases de 7: `inicio`, `actualización`, `fin`, `cancelación`) sobre `D01c/frame`. Con ratón, 1 px = 0,25° (`delta_grados`, Entrada); con mando, velocidad angular × Δt. El controlador suma `delta_grados` a θ y **limita θ a [0°, 90°]** (regla 9 de 9): no hay vuelta completa ni envoltura. Sentido: `delta_grados` positivo aumenta θ (el reflejo gira hacia su posición de solución al aumentar θ desde 0°). Se admite el modo «alternar» de Entrada (pulsar para empezar a rotar y pulsar para soltar, en lugar de mantener).
6. **θ inicial y persistencia.** θ parte de `theta_initial_deg` = 0° al cargar la escena. Al cerrar la vista **conserva** θ durante la sesión de la escena (regla 21b de 9, `KEEP`); no se guarda en disco (regla 22 de 9: solo `pendiente_revelacion`). Tras cargar vuelve a 0°.
7. **Aspecto del reflejo.** El reflejo es **puramente geométrico**: la foto de `D04` rota con θ respecto a la foto de la caja, y solo en θ* ± tolerancia las figuras coinciden una a una. No hay ayuda de coherencia (sin brillo, enfoque, zumbido ni «imán» que crezca al acercarse a θ*): lo que el jugador ve es la única señal. Mientras θ está en tolerancia **no suena nada** (`HOLDING` no emite feedback, regla 13 de 9).
8. **Sonido del giro.** El slice no define sonido de giro; 15 solicita a 23 un lazo suave de madera/metal cuyo volumen sigue a la velocidad de giro, que cesa en cuanto el gesto termina o se cancela (‡, ID provisional `SFX_FRAME_TURN`, Open Questions). El puzle funciona sin él.

### C. La alineación

9. **Veredicto.** `evaluate()` es una función pura de θ: devuelve `HOLDING` si |θ − θ*| ≤ `tol_deg` y `NONE` en caso contrario. **Nunca** devuelve `PARTIAL`, `REJECT` ni `SOLVED` (regla 12 de 9: en `SUSTAINED` el controlador no devuelve `SOLVED`; regla 15 de 9).
10. **Tolerancia.** `tol_deg` = 3° (normal) o 6° (con `asistencia_rotacion` activa en 6). El marco lee el ajuste al configurar y al cambiar; un cambio se aplica al **siguiente gesto** (el cambio se hace desde la pausa, que entrega `cancelación` y pone el acumulador a 0; regla 14b de 9 y regla 12 de 9).
11. **Cuándo cuenta.** El marco llama a `evaluate()` en cada fotograma con la vista abierta; suma `min(dt, dt_max)` mientras haya `HOLDING` seguido (F2 de 9) y decide `SOLVED` al llegar a `hold_s` = 0,8 s. Pone el acumulador a 0 con cualquier `NONE`, con `on_close` y con `cancelación`. **No hace falta soltar el gesto**: se puede seguir rotando dentro de la tolerancia. Cruzar la tolerancia a más de `v_max` (F-P5-2) no resuelve.
12. **Sin fallo.** Alinear mal, no alinear nunca y salir y volver no tienen consecuencia: no hay `reset`, ni contador, ni sonido de rechazo. El marco interior **no vuelve** a su posición inicial (se descarta el «si falla» de §10.5; ver Decisiones tomadas).
13. **Orden.** `P5` solo exige `caja_c1`; puede resolverse antes o después de `P4` (autonomía; AC-05 de 9). No exige haber inspeccionado `D04`: el reflejo existe igual y la revelación enseña las dos fotos.

### D. La revelación (secuencia diferida)

14. **Inicio.** Cuando el marco convierte la racha de `HOLDING` en `SOLVED`, en este orden y en el mismo fotograma: (1) `cancel_gesture()` en silencio si hay un `rotar` activo (regla 17 de 9); (2) el controlador fija θ = θ* (el marco interior se recoloca con un tween de `theta_settle_s` = 0,3 s†, instantáneo con `reducir_movimiento`); (3) el marco escribe `pendiente_revelacion` = verdadero y entra en `RESOLVING` (regla 19 de 9); (4) la entrada de la vista queda bloqueada salvo `atrás`.
15. **Pasos** (datos en «Datos del puzle»; tiempos desde el inicio de la secuencia, reloj de juego, regla 36 de 9):

    | Paso | Inicio | Fin | Qué se ve | Audio |
    |---|---|---|---|---|
    | `FADE` | 0,0 s | 1,2 s | La superficie refleja la foto de `D04` y se **superpone** a la foto de la caja (fundido de opacidad). Con `reducir_movimiento`: fundido fijo de 100 ms y la imagen final se mantiene hasta 1,2 s (regla 14b(b) de 9). | Sin sonido de acierto. Silencio parcial (slice §14): solo el ambiente de la sala. |
    | `OUTLINE` | 1,2 s | 2,0 s | Las figuras coincidentes quedan como una sola foto; **solo la silueta de Vera** (presente en la foto de `D04`, no en la de la caja) recibe un contorno. Con `reducir_movimiento`, aparece en 100 ms (extensión de 14b(b) de 9 de `FADE` a `OUTLINE`, definida en el esquema v2 de 9). | Ídem. |
    | `LINE` | 2,0 s | 16,0 s nominal (F8) | La imagen superpuesta con el contorno se **mantiene fija**; no hay más animación, cámara ni texto salvo el subtítulo de 26. | `VO_G_07` desde `SPK_D01C` (el altavoz del compartimento, 10). El paso termina por las señales de la regla 20 de 9. |

16. **Qué muestra y qué no** (pilares *Información incompleta* y anti-pilar *NOT una historia explicada*). La revelación **muestra un hecho observable**: existe una figura en una foto que no está en la otra. **No** hay: texto en pantalla, nombre, flecha, etiqueta, destello, zoom, movimiento de cámara, comentario de Vera ni música. El contorno es la única marca y rodea la silueta, no la interpreta. No usa rojo ni verde ni ningún código cromático moral (pilar *Ambivalencia sin moral binaria*): su color y brillo los fija el art bible; 15 exige solo que se distinga por **forma y luminancia**, no solo por tono. En `D04`, Vera está «al margen» (slice, Anexo A); en el reflejo debe ocupar la posición del hueco S6 de la foto de la caja (‡ requisito de contenido para 13 y arte; Open Questions).
17. **Audio de `LINE`.** `VO_G_07` suena desde el altavoz del compartimento (`SPK_D01C`, 10). La línea trae dentro sus efectos (pasos, sillas, tecleo, puerta que se cierra; slice §14). 15 no escribe ni modifica su contenido (narrative-director). El subtítulo lo emite 26 durante `fallback_s`. La ausencia o el fallo de la línea nunca interrumpe la secuencia (regla 20 de 9; F8).
18. **Fin.** Al terminar el último paso, 9 escribe `caja_c3` = verdadero y después `pendiente_revelacion` = falso (regla 19 de 9), pasa a `RESUELTO`, emite `EV_PUZZLE_SOLVED_P5` con `rewards` vacío y «compartimento completado» (3) (regla 16 de 9). **15 no escribe ninguna de esas cosas.** Recompensa de `P5`: la propia grabación y la revelación; no hay ítem (el slice D.1 no define ninguno) y, por tanto, nada nuevo en el bolsillo (20). A `close_view_after_s` = 1,5 s, 9 pide `cerrar_vista('D01c', 'resuelto')` y la cámara vuelve en 0,5 s (F4 de 9); 10 cierra la tapa (`BOX_C3_CLOSE`; `FINAL_CERRADO`).

### E. Interrupción, reanudación y carga

19. **Interrupción.** `RESOLVING` se interrumpe **solo** por salida de la vista (regla 18 de 9: `atrás`, `cerrar_modos()`, descarga). Efecto: se detiene la secuencia, 23 corta la línea con fundido, `caja_c3` sigue falso, `pendiente_revelacion` sigue verdadero, el puzle vuelve a `ACTIVO`/`IDLE`, 10 deja C3 `ENTREABIERTO`. Nada se pierde ni se penaliza. La **pausa no interrumpe**: detiene el reloj de juego y retiene las señales de 23 (regla 20 de 9).
20. **Reapertura con `pendiente_revelacion` verdadero.** Al abrir la vista, el marco **salta la comprobación**; el controlador fija θ = θ* (sin tween: la vista se abre ya alineada) y la secuencia empieza **desde el principio** (el jugador debe oír la grabación entera; D9-6). Cuesta como mucho `T_seq` ≤ 18,0 s cada vez; no hay límite de reintentos.
21. **`pendiente_revelacion`** (hecho `bool`, reversible, dueño 9; slice D.2, desvío D9-5: se escribe al **iniciar**, no «si se interrumpe»). 15 solo lo **conoce** a través del marco: no lo lee ni lo escribe. Casos de carga (regla 8 de 9): (a) `caja_c3` falso y `pendiente_revelacion` verdadero → `P5` `ACTIVO`, el hecho **sigue verdadero**, C3 `ENTREABIERTO`, la secuencia se reproduce al abrir la vista (regla 20); (b) ambos verdaderos → `P5` `RESUELTO` y el marco limpia el hecho en silencio; (c) `caja_c3` verdadero → `restore_solved_presentation()` (regla 24). Si el último guardado es anterior a la escritura del hecho, el jugador repite la alineación (inocuo). El guardado (5) lo guarda con la causa `reveal_pending`.

### F. Pistas (enganche del sistema 17, reglas 25 a 27 de 9)

22. **Tres niveles, todos `REQUEST`** (sin `IDLE`: `idle_hints_auto_apply` solo cubre P3 N3 y P6; la voz y el sistema no guían al jugador, pilar *Autonomía como progresión*). Cada nivel es **énfasis** de información que ya está en el juego (regla 27 de 9):

    | Nivel | Efectos | Clave de 18 | Contenido |
    |---|---|---|---|
    | 1 | `TEXT` + `HIGHLIGHT` | `PISTA_P5_N1` | «El reflejo muestra algo que la foto de la caja no muestra». Resalta `D01c/reflection` 3,0 s†. |
    | 2 | `TEXT` + `HIGHLIGHT` | `PISTA_P5_N2` | «Compara las dos fotos con atención». Resalta `D01c/reflection` y `D01c/box_photo` 3,0 s†. |
    | 3 | `AFFORDANCE` (`MARK_LIT`, definido en el esquema v2 de 9) | — (efecto visual) | La marca de 40° (`D01c/mark_40`) se ilumina y **permanece** iluminada mientras la vista esté abierta y en las siguientes aperturas de la sesión. **No** mueve el marco ni resuelve el puzle: el jugador debe girar hasta ella y mantener. |

    Los `HIGHLIGHT` de los niveles 1 y 2 son una adición de 15 a los textos del slice (Decisiones tomadas); no introducen claves nuevas (las 8 claves de 18 son un conjunto cerrado).
23. **Reglas.** Las pistas se piden desde la pausa (25) vía 17; `request_hint` valida que `P5` esté `ACTIVO`. Con la vista cerrada, el efecto se aplica al estado y se muestra al abrir. **Durante `RESOLVING` `request_hint` se ignora** (sin efecto visible) **y no cuenta como nivel alcanzado** (el estado `RESOLVING` en `request_hint` lo define el esquema v2 de 9; D15-18): la alineación ya se hizo y el nivel no avanza. El nivel alcanzado vive solo en memoria y es monótono (regla 26 de 9). Con `pendiente_revelacion` verdadero la marca de 40° ya no tiene función.

### G. Accesibilidad

24. **`asistencia_rotacion`** (Ajustes 6): bool, falso por defecto; con verdadero la tolerancia pasa de ±3° a ±6° (ventana 12°). Se confirma el nombre provisional de 6 (Decisiones tomadas).
25. **`reducir_movimiento`** (6, regla 14b de 9): fundido de `FADE` y aparición de `OUTLINE` a 100 ms fijos con **los mismos `duration_s`** (F8 no cambia); recolocación de θ a θ* instantánea; el entreabierto y el cierre de C3 con `reducir_movimiento` los resuelve 10 (quién lo resuelve lo fija 14b(c) del esquema v2 de 9; 15 asume 10 hasta entonces). El giro del jugador no se altera (es entrada del jugador, no animación). Un cambio con la secuencia en curso afecta al **siguiente** paso o apertura.
26. **`reducir_sobresaltos`** (6): 15 **no lo lee** (Ajustes lo entrega solo a 23 y 28). La secuencia no contiene destellos ni cambios bruscos de luminancia (solo un fundido de opacidad ≥ 1,2 s o 100 ms fijo). Si el «golpe» de la puerta dentro de `VO_G_07` debe atenuarse con la opción, lo decide 23 (Open Questions).
27. **Otras ayudas.** Subtítulos de `VO_G_07` (26, `fallback_s` 14,0 s); modo «alternar» y velocidad de mando de Entrada; ninguna pista depende solo del color ni del sonido; sin tiempo límite en ninguna fase (S3 de 9); el reintento tras interrumpir no penaliza.

### H. Después de resolver

28. **Reapertura:** `on_reopen` = `NO_VIEW` (regla 35 de 9): el dueño (Caja) contesta `SIN_EFECTO`; la vista no se abre. **Restauración** (`restore_solved_presentation()`, regla 8 de 9): llama a `set_final_pose(3)` de 10 y coloca el marco interior a θ* sin sonido ni aviso. Con la tapa cerrada (`FINAL_CERRADO`) el interior no se ve, pero queda consistente si la vista se abriese por consola (en tal caso la red de seguridad la cierra, regla 7 de 9).
29. **Lo que 15 no hace.** No decide cuándo se ofrece una pista (17); no reproduce ni temporiza audio (23); no anima la tapa (10); no dibuja el contorno (29); no escribe ningún hecho ni aviso (9); no lee `correos_leidos` ni inventario; no exige ítems (`needs_items` vacío).

## Formulas

Esta capa **no redefine** F2 (condición mantenida), F4 (cierre) ni F8 (duración de la secuencia) de 9: las **instancia** con los valores de `P5` y añade las derivadas propias.

### F-P5-1 · Tolerancia y ventana de alineación

`Δ = |θ − θ*|;   HOLDING ⇔ Δ ≤ tol;   W = 2 · tol;   P_azar = W / (θ_max − θ_min)`

| Variable | Tipo | Rango | Fuente | Descripción |
|---|---|---|---|---|
| θ | float (°) | 0–90 | calculado | Ángulo actual (limitado a [θ_min, θ_max]) |
| θ* | float (°) | 20–70 | datos, 40 | Solución (slice B.5) |
| tol | float (°) | 2–5 normal; 4–10 asistido | datos, 3 / 6 (`tol_deg_P5`, `asistencia_rotacion_deg`) | Tolerancia |
| W | float (°) | 4–20 | calculado | Ancho de la ventana |
| θ_min, θ_max | float (°) | 0, 90 | datos | Límites del giro |

**Restricción de datos (regla 29 de 9):** θ* − tol_asistida ≥ θ_min y θ* + tol_asistida ≤ θ_max, y θ_initial fuera de la ventana asistida (|θ_initial − θ*| > tol_asistida).
**Ejemplo:** tol 3 → W = 6° → `P_azar` = 6/90 = 6,7 %; tol 6 → W = 12° → 13,3 %. θ_initial 0°: |0 − 40| = 40 > 6, válido. La ventana normal [37°, 43°] contiene una sola marca (40°); la asistida [34°, 46°] contiene tres (35°, 40°, 45°).

### F-P5-2 · Velocidad máxima de barrido que resuelve (D-W3)

`v_max = W / hold_s;   un barrido a velocidad constante v resuelve ⇔ v ≤ v_max`   (en píxeles de ratón: `v_px = v / 0,25`)

**Variables:** `hold_s` 0,8 s† (0,4–1,5); W de F-P5-1; 0,25°/px (Entrada).
**Output Range:** `v_max` normal = 6 / 0,8 = **7,5°/s** (30 px/s); asistido = 12 / 0,8 = **15°/s** (60 px/s).
**Ejemplo:** a 60 fps (`dt` = 1/60) con tol 3, un giro a 7,5°/s pasa 0,8 s dentro de la ventana (48 fotogramas, F2 de 9) justo en el límite; a 30°/s la cruza en 0,2 s (12 fotogramas, `acum` = 0,2 s < 0,8 s): no resuelve. Un giro a 5°/s dentro de la ventana acumula 6/5 = 1,2 s ≥ 0,8 s: resuelve.
**Lectura de diseño.** Un jugador que gira muy despacio (< 7,5°/s, un movimiento de ratón de < 30 px/s) resuelve sin haber comparado las fotos. Se acepta: ver F-P5-3 y Decisiones tomadas (D15-6).

### F-P5-3 · Tiempo de un barrido lento desde θ_initial

`t_solve(v) = (θ* − tol − θ_initial) / v + hold_s   para v ≤ v_max;     t_barrido_total = (θ_max − θ_min) / v`

**Ejemplos (θ_initial = 0°, θ* = 40°, tol 3):** v = 7,5°/s → 37/7,5 + 0,8 = **5,73 s**; v = 5°/s → 7,4 + 0,8 = 8,2 s; barrido completo del rango a 7,5°/s: 90/7,5 = **12 s** (la cifra «~12 s» de D-W3 es el barrido de todo el rango; el barrido que resuelve desde 0° ya lo hace a ~5,7 s). Con tol 6 y v = 15°/s → (40 − 6)/15 + 0,8 = 3,07 s.
**Uso:** cota inferior del tiempo de un jugador que no entiende el puzle; no es un objetivo de diseño, es el peor caso de «resolución sin comprensión» que el criterio 5 del slice (§19) debe medir aparte (Open Questions 1).

### F-P5-4 · Duración de la secuencia (instancia de F8 de 9)

`T_seq = duration_s(FADE) + duration_s(OUTLINE) + T_line = 1,2 + 0,8 + T_line`; `T_line` según F8 de 9 (`fallback_s` 14,0 s, `line_grace_s` 2,0 s).

| Caso | T_line | T_seq |
|---|---|---|
| Sin audio, línea fallida o audio de 14,0 s exactos | 14,0 s | **16,0 s (nominal)** |
| Línea que termina a 13,2 s (AC-20 de 9) | 13,2 s | 15,2 s |
| Línea de 15,5 s | 15,5 s | 17,5 s |
| Línea de 17 s (se corta a `fallback_s + grace`) | 16,0 s | 18,0 s |
| Señal perdida | 16,0 s | 18,0 s |

**Output Range:** `T_seq` ∈ [2,0 + t_terminada, 18,0] s. **Con `reducir_movimiento`:** `T_seq` no cambia (los pasos conservan su `duration_s`, regla 14b de 9).
**Del hold a la cámara devuelta:** `T_hold→cámara = hold_s + T_seq + close_view_after_s + t_devolver = 0,8 + 16,0 + 1,5 + 0,5 = 18,8 s` nominal; máximo 0,8 + 18,0 + 2,0 = 20,8 s.

### F-P5-5 · Tiempo esperado de `P5` frente a F7 de 9

`T_P5 = T_ent + T_obs + T_giro + hold_s + T_seq + T_sal`   con `T_sal = close_view_after_s + t_devolver = 2,0 s`

| Término | Mín. | Máx. | Fuente |
|---|---|---|---|
| `T_ent` (apertura de la tapa y entrada de la vista) | 2,4 s† | 2,4 s† | `BOX_C3_OPEN` 1,4 s† (10, F1 de 10; C3 parte entreabierta de 2 cm) + vista de entrada 1,0 s (B.3, 7). Para C1 serían 2,6 s (`BOX_C1_OPEN` 1,6 s, slice B.3) |
| `T_obs` (mirar `D04`, la foto de la caja y el reflejo) | 20 s† | 90 s† | Estimación de playtest |
| `T_giro` (buscar el ángulo) | 15 s† | 75 s† | Estimación; F-P5-3 da la cota de 5,7 s sin comprensión |
| `hold_s` | 0,8 s | 0,8 s | datos |
| `T_seq` | 16,0 s | 18,0 s | F-P5-4 |
| `T_sal` | 2,0 s | 2,0 s | F4 de 9 |
| **Total** | **56,2 s ≈ 0,94 min** | **188,2 s ≈ 3,14 min** | 2,4 + 20 + 15 + 0,8 + 16,0 + 2,0 = 56,2; 2,4 + 90 + 75 + 0,8 + 18,0 + 2,0 = 188,2 |

**Contraste con F7 de 9** (objetivo 1,5–3 min): la banda objetivo cae dentro de la del modelo (0,94–3,14 min); los extremos del modelo son colas, no objetivos. Con pistas (cada nivel añade ~0,5–1 min de espera y lectura) el tiempo puede superar 3 min sin ser un fallo de tuning. **Decisión D15-7:** los 1,5–3 min **incluyen** los ~16 s de revelación; F7 de 9 dice literalmente «más ~16 s» y F9 suma 1,5 y 3 sin añadirlos (10,5–22 min): 15 **interpreta F7 de 9 con la revelación incluida** (así AC-P5-19 y F9 son coherentes) y pide a 9 que lo escriba en la nota de F7 y F9 (Cambios requeridos); hasta que 9 lo acepte, AC-P5-19 se mide contra esa lectura y no contra el literal. Si 9 no la aceptase, el rango de F9 subiría 0,27 min en ambos extremos (14,83 → 15,10 min y 33,09 → 33,36 min).
**Reparto:** la revelación pesa 16/56,2 = 28,5 % del tiempo mínimo y 16/188,2 = 8,5 % del máximo.

## Edge Cases

Cada caso dice **qué ocurre** y quién lo garantiza.

1. **Cargar con `P5` `ACTIVO` y `caja_c3` falso.** θ = 0°, C3 `ENTREABIERTO` sin sonido, sin avisos (regla 8 de 9; AC-14 de 10).
2. **Cerrar la vista sin alinear.** θ se conserva en la sesión; el acumulador a 0; sin penalización (regla 6; regla 21b de 9).
3. **Alinear y seguir rotando dentro de la tolerancia.** Sigue acumulando; `SOLVED` a 0,8 s seguidos. Si sale de la ventana antes, acumulador a 0.
4. **Pasar por θ* a más de `v_max`.** No resuelve (F-P5-2); el jugador no recibe feedback negativo, solo ve que el reflejo coincidía un instante.
5. **Giro muy lento que atraviesa la ventana sin comprender (D-W3).** Resuelve (F-P5-3). Se acepta: ningún pilar se viola (no hay castigo), la revelación sigue enseñando el hecho y la comprensión se mide aparte en playtest (Open Questions 1).
6. **Tirón de `dt` grande o caída de fotogramas (< 10 fps).** El marco suma `min(dt, dt_max)` (0,1 s): a 5 fps hacen falta 8 fotogramas (1,6 s reales) en lugar de 0,8 s. Es el comportamiento previsto de `dt_max` (F2 de 9); no hay resolución accidental por un hipo.
7. **θ en un tope (0° o 90°).** Se limita y no pasa nada más; el gesto continúa y el exceso de `delta_grados` se descarta. Los topes no producen sonido de rechazo.
8. **`cancelación` durante `rotar`** (`atrás`, pérdida de foco, pausa; regla 11b de 9). θ se conserva, se corta el gesto en silencio, acumulador a 0, sin evaluar el gesto cancelado.
9. **`asistencia_rotacion` cambia con la vista abierta.** Se aplica al siguiente gesto (la pausa ya cancela el gesto, edge 8); el acumulador no se arrastra entre tolerancias.
10. **`SOLVED` con un `rotar` activo.** `cancel_gesture()` en silencio y θ = θ* (regla 14); la recolocación máxima visible es de `tol_deg` (≤ 6°), con tween de 0,3 s o instantánea con `reducir_movimiento`.
11. **`atrás` durante `RESOLVING` (en cualquier instante, incluido a 0,1 s).** Interrumpe sin escribir `caja_c3`; `pendiente_revelacion` ya es verdadero (se escribió al iniciar); al volver, la secuencia empieza desde 0 con θ = θ* (AC-21, AC-22 de 9). El coste es repetir hasta 18,0 s.
12. **`cerrar_modos()` o descarga de escena durante `RESOLVING`.** Igual que el caso 11 (regla 18 de 9; AC-46 de 9).
13. **Pausa durante `RESOLVING`.** El reloj de juego se detiene; la línea se pausa; las señales de 23 llegadas en pausa se retienen y se procesan al reanudar (regla 20 de 9; AC-54 de 9). No se interrumpe.
14. **Cierre forzado del juego durante `RESOLVING`.** Si el hecho ya estaba guardado (causa `reveal_pending`), se carga `P5` `ACTIVO` con el hecho verdadero (regla 21a); si no, el jugador repite la alineación.
15. **Cierre entre las dos escrituras finales** (`caja_c3` verdadero y `pendiente_revelacion` verdadero): `P5` `RESUELTO` y el marco limpia el hecho en silencio (regla 8.1 de 9; AC-41 de 9).
16. **`VO_G_07` sin archivo, con fallo o sin señal.** La secuencia dura 16,0 s (sin audio o fallida) o 18,0 s (señal perdida) y nunca se atasca ni se interrumpe (F-P5-4; AC-20 de 9); el subtítulo dispone de `fallback_s`.
17. **Pista nivel 3 antes de alinear, con el marco en cualquier θ.** La marca de 40° se ilumina; el marco no se mueve; el jugador puede ignorarla. Un jugador que ve la marca y la sigue resuelve en pocos segundos (válido: la pista es un énfasis).
18. **Pista pedida durante `RESOLVING` o con `P5` `RESUELTO`.** `request_hint` la rechaza con `RESUELTO` (puzle no `ACTIVO`) y, durante `RESOLVING`, **se ignora**: sin efecto visible y **sin contar como nivel alcanzado** (D15-18); sin consecuencia.
19. **Abrir `D01c` con `P5` `BLOQUEADO`.** Lo impide Caja (10) con `SIN_EFECTO` (regla 7 de 9). La red de seguridad cierra una vista abierta por otra vía (consola).
20. **Resolver `P5` antes que `P4`, o `P4` antes.** Ambos órdenes son válidos (AC-05 de 9); `P6` espera a `caja_c1`, `caja_c2` y `caja_c3`.
21. **El jugador nunca ha mirado `D04`.** El puzle sigue siendo resoluble (no hay puerta por inspección); la revelación muestra las dos fotos juntas. La pista nivel 1 (`PISTA_P5_N1`) y el reflejo lo llevan a compararlas.
22. **Resolver con `reducir_movimiento` activo.** Mismos tiempos (F-P5-4), sin movimiento de recolocación; el fundido de 100 ms y la imagen fija el resto de `FADE`.
23. **Consola de desarrollo fuerza `caja_c3`.** El marco reconcilia a `RESUELTO` en silencio (regla 31 de 9); no se emite `EV_PUZZLE_SOLVED_P5`.
24. **Estrategias degeneradas** (Sirlin: dominantes o inmunes al contenido). (a) *Barrido lento sin mirar*: aceptada (edge 5, F-P5-2). (b) *Mashing / mover el ratón sin criterio*: `P_azar` 6,7 % por posición, sin coste alguno; no es dominante porque la ventana exige 0,8 s quieta. (c) *Ver solo la marca de 40°*: la marca solo existe con el nivel 3 y es una pista deliberada. (d) *Saltarse la revelación*: no se permite (no hay botón de omitir; es la función narrativa del puzle, D9-6).
25. **Reapertura de la vista de un `P5` `RESUELTO`.** `NO_VIEW`: no hay vista; el compartimento permanece cerrado; la grabación no se puede volver a oír en el slice (no hay relectura de audio; Open Questions 6).

## Dependencies

Bidireccional. **La dureza la declara el dependiente**: la columna «Dureza» de la primera tabla es la de 15 como dependiente (15 depende de 6, 9, 10 y 13 según el índice, fila 15; dura en 9 y 10, blanda en 6 y 13); la segunda tabla recoge a quienes dependen de 15, que declaran su propia dureza en su GDD (aquí solo se anota qué les entrega 15).

### Sistemas de los que depende 15

| Sistema | Dureza | Qué recibe 15 | Qué entrega 15 | Contrato |
|---|---|---|---|---|
| 9 Marco de puzles | **Dura** | Ciclo de vida, `evaluate()` por fotograma, acumulador F2, secuencia diferida (reglas 12, 17 a 20), escritura de `caja_c3` y `pendiente_revelacion`, pistas, avisos | Controlador `P5Controller`, entrada `P5` de `puzzles.json`, veredictos `HOLDING`/`NONE` | Veredicto, no acción (regla 10 de 9) |
| 10 Caja y compartimentos | **Dura** | Vista `D01c` y su anclaje de cámara, fuente `SPK_D01C`, entreabierto de 2 cm al activarse, `set_final_pose(3)`, cierre de la tapa, estado `ENTREABIERTO` en interrupción y carga | `get_view_gate` se lo da 9 a 10; 15 entrega a 10, vía 9, `ajar_cm` = 2 y el aviso «compartimento completado» (3) | 10 posee la tapa; 15 no la anima |
| 13 Puzle 3 · Encaje de la foto | **Blanda (contenido)** | La **foto de la caja ya completa** (cinco figuras y el hueco S6) como recurso de arte reutilizable para `D01c/box_photo` (regla 23 de 13: `slot_6` vacío, «la imagen que reutiliza la secuencia del P5»). `caja_c1` llega vía 9, no de 13 | — | No es un contrato de lógica: 13 no ejecuta nada de 15. Sin ese recurso el puzle funciona con una foto provisional, pero no se puede validar la coincidencia figura por figura (AC-P5-18). 15 pide a 13 que la liste como dependiente (Cambios requeridos) |
| 6 Ajustes persistentes | Blanda | `asistencia_rotacion` (±6°), `reducir_movimiento` (vía 9: lectura al configurar y al cambiar) | — | Sin 6, ambos son falso (tolerancia ±3°, fundidos normales) |
| 7 Interacción e inspección (vía 9) | Indirecta | Gesto `rotar` y sus fases, `delta_grados` (0,25°/px), captura del elemento al iniciar, `cancelación`; catálogo de elementos de `D01c` | `elements()` = [`D01c/frame`] | Regla 11 y 11b de 9 |
| 23 Director de audio ‡ · 26 Subtítulos ‡ (vía 9) | Blanda | Reproducción y corte de `VO_G_07` desde `SPK_D01C`, señales de línea; subtítulo durante `fallback_s` | «línea pedida» (por 9); la petición de lazo `SFX_FRAME_TURN` ‡ | Regla 20 de 9; sin audio la secuencia dura igual 16,0 s |
| 3 Estado y bus · 5 Guardado y carga (vía 9) | Indirecta | Lectura de `caja_c1`, `caja_c3`, `pendiente_revelacion`; causa `reveal_pending` | — | Reglas 5 y 7 de 3; regla 6 de 5 |
| 17 Sistema de pistas ‡ · 18 Base de contenido (vía 9) | Indirecta | `request_hint`; claves `PISTA_P5_N1`, `PISTA_P5_N2` | Datos de las tres pistas | Reglas 25 a 27 de 9 |
| 1 Entrada y controles · 2 Jugador | Indirecta | Mapeo del giro (ratón, mando, «alternar»), regreso de cámara `t_devolver` 0,5 s | — | Regla 18 de 2 (vía 7 y 9) |

### Sistemas que dependen de 15 (declaran su dureza ellos)

| Sistema | Qué entrega 15 |
|---|---|
| 9 Marco de puzles | Los datos y el controlador de `P5` (la matriz de encaje de 9 ya lo prevé) |
| 10 Caja y compartimentos | El tiempo de la secuencia (para que la tapa de C3 no se cierre durante ella) y `ajar_cm` |
| 29 Shaders y efectos de superficie ‡ | Instante, duración y contenido de la superposición (`FADE`) y del contorno (`OUTLINE`); el requisito de coincidencia en θ* (índice: 29 depende de 12 y 15) |
| 17 Sistema de pistas ‡ | Las tres pistas de `P5` (todas `REQUEST`) |
| 21 Director de escenas | Nada propio: `caja_completa` se deriva de `caja_c3` y los demás compartimentos |

## Tuning Knobs

Todos viven en `assets/data/puzzles/puzzles.json` (entrada `P5`) salvo los marcados «otro dueño». Categorías: F = feel, C = curve, G = gate. † = a validar en playtest.

| Knob | Cat. | Valor | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `theta_deg` (θ*) | C | **40°** | 20–70 | Ángulo de la solución (slice B.5, valor de referencia). Debe dejar θ_initial y los topes fuera de la ventana |
| `tol_deg` | C | **3°** | 2–5 | Ventana normal de 6° (F-P5-1). Menor = más exigente y `v_max` más bajo; mayor = menos legible el «clic» visual |
| `assist.tol_deg` | C | **6°** | 4–10 | Ventana asistida de 12° (`asistencia_rotacion_deg` del registro). Debe ser ≥ `tol_deg` y mantener θ* ± tol dentro de [0, 90] |
| `hold_s` | F | **0,8 s** | 0,4–1,5 | `v_max = W / hold_s` (F-P5-2). Bajarlo permite resolver cruzando más deprisa (más «resolución sin comprender»); subirlo penaliza a quien ajusta con pulso inestable |
| `dt_max` | F | **0,1 s** | 0,05–0,2 | Tope por fotograma del acumulador; evita que un tirón complete la cuenta (F2 de 9) |
| `theta_initial_deg` | C | **0°** | 0–90, fuera de la ventana asistida | Ángulo de partida (valida la regla 29 de 9) |
| `theta_min_deg` / `theta_max_deg` | C | **0° / 90°** | fijos (slice B.5) | Recorrido del marco |
| `mark_step_deg` | F | **5°** | 5–15 | Marcas visibles (slice B.5: cada 5°). Más separadas = menos referencias para el jugador |
| `theta_settle_s` | F | **0,3 s†** | 0–0,6 | Tween de recolocación a θ* al resolver con un gesto activo (instantáneo con `reducir_movimiento`) |
| `reveal_fade_s` (`FADE`) | F | **1,2 s** | 0,6–2,0 | Parte de F8; dueño del valor: marco (registro: `reveal_fade_s`) |
| `reveal_outline_s` (`OUTLINE`) | F | **0,8 s†** | 0,4–1,5 | Parte de F8 |
| `line_fallback_s` (`LINE`) | G | **14,0 s** | duración real de `VO_G_07` ± 1 s | Define los 16,0 s nominales; revisar si se regraba la línea |
| `line_grace_s` | G | **2,0 s†** | 1,0–3,0 | Margen sobre `fallback_s` (F8) |
| `close_view_after_s` | F | **1,5 s†** | 0,5–3,0 | Tiempo con la imagen final y el contorno visibles antes de cerrar la vista |
| `ajar_cm` | F | **2 cm** | 1–4 | Aviso físico de que `P5` está disponible (slice B.5); lo anima 10 |
| `hint_highlight_s` (N1, N2) | F | **3,0 s†** | 2,0–5,0 | Duración del resaltado de las dos fotos |
| `fade_reduced_ms` (otro dueño: 9/6) | F | **100 ms** | 50–200 | Fundido fijo con `reducir_movimiento` |
| Ganancia del ratón (otro dueño: 1/Entrada) | F | **0,25°/px** | — | Convierte px en `delta_grados`; fija `v_px` de F-P5-2 |

**Interacciones entre knobs:** `v_max` depende de `tol_deg` y `hold_s` (F-P5-2); `T_seq` de `reveal_fade_s`, `reveal_outline_s` y `line_fallback_s` (F-P5-4); el presupuesto del F7 de 9 depende de `T_seq`. Ningún knob puede introducir un temporizador de solución ni una penalización (S3 de 9).

## Acceptance Criteria

Tipos: **L** = prueba lógica automática (reloj falso, `GameClock` de la regla 36 de 9), **I** = integración, **PV** = playtest o evidencia visual (captura retenida en `production/qa/evidence/`). Complementan los AC de 9 (AC-03, AC-05, AC-11, AC-20 a AC-22, AC-41, AC-45, AC-46, AC-52 a AC-54 y AC-X3/X4), que los verifican a nivel de marco.

- **AC-P5-01 (R1, R2, L)**: **GIVEN** `caja_c1` falso, **THEN** `P5` está `BLOQUEADO` y la vista no se abre; **WHEN** `caja_c1` pasa a verdadero, **THEN** `P5` pasa a `ACTIVO`, «puzle activado» lleva `ajar_cm` = 2 y suena `SFX_UNLOCK_SOFT` una vez.
- **AC-P5-02 (R5, R6, L)**: **GIVEN** `P5` `ACTIVO`, **THEN** θ = 0°; **WHEN** llegan `delta_grados` que sumarían 120° o −30°, **THEN** θ queda en 90° o 0°, sin envoltura; **WHEN** se cierra y reabre la vista, **THEN** θ se conserva; **WHEN** se carga la partida, **THEN** θ = 0°.
- **AC-P5-03 (R9, R10, F-P5-1, L)**: **GIVEN** tol 3, **THEN** `evaluate()` = `HOLDING` para θ ∈ [37°, 43°] y `NONE` fuera (43,5° → `NONE`); **GIVEN** `asistencia_rotacion` activa, 43,5° → `HOLDING` y 46,1° → `NONE`; **THEN** `evaluate()` nunca devuelve `PARTIAL`, `REJECT` ni `SOLVED`.
- **AC-P5-04 (R11, F-P5-2, L)**: **GIVEN** reloj falso a 60 fps, `dt` = 1/60 y **fase fijada** (θ(n) = θ_inicio + v·n/60, con θ_inicio = θ* − tol − 1°, es decir 36° con tol 3 y 33° con tol 6, n = 0 el primer fotograma), **WHEN** θ barre la ventana a velocidad constante con tol 3, **THEN** a 7°/s `SOLVED` (51 o 52 fotogramas dentro, ≥ 48 = 0,8 s); a 8°/s no resuelve (45 fotogramas, 0,75 s < 0,8 s) y a 30°/s tampoco (12 fotogramas), y el acumulador vuelve a 0 al salir; **GIVEN** tol 6 (θ_inicio 33°), a 14°/s resuelve (51 fotogramas) y a 16°/s no (45 fotogramas). Márgenes ≥ 3 fotogramas respecto al umbral de 48: no depende del redondeo de coma flotante en los bordes (7,5°/s y 15°/s son el límite teórico de F-P5-2 y no se prueban).
- **AC-P5-05 (R11, edge 6, L)**: **GIVEN** `dt` = 0,5 s con θ dentro de la ventana, **THEN** el acumulador suma 0,1 s (`dt_max`), no 0,5 s; con 8 fotogramas de 0,5 s seguidos, `SOLVED`.
- **AC-P5-06 (R12, L)**: **GIVEN** θ fuera de tolerancia durante 10 min de reloj falso, **THEN** θ no cambia, no hay sonido, no hay `REJECT`, no hay contador ni cambio de estado.
- **AC-P5-07 (R14, L)**: **GIVEN** un `rotar` activo cuando el acumulador llega a 0,8 s, **THEN** en el mismo fotograma: `cancel_gesture()` en silencio, θ = θ*, `pendiente_revelacion` = verdadero, `caja_c3` sigue falso, y toda entrada salvo `atrás` se descarta.
- **AC-P5-08 (R15, F-P5-4, L)**: **GIVEN** «línea sin audio», **THEN** `FADE` termina a 1,2 s, `OUTLINE` a 2,0 s y la secuencia a 16,0 s (±0,05 s); **GIVEN** audio que termina a 13,2 s, 15,2 s; **GIVEN** señal perdida, 18,0 s; **GIVEN** `reducir_movimiento`, los mismos tiempos.
- **AC-P5-09 (R18, L)**: **GIVEN** el último paso terminado, **THEN** en este orden: `caja_c3` = verdadero, `pendiente_revelacion` = falso, `P5` `RESUELTO`, `EV_PUZZLE_SOLVED_P5` con `rewards` vacío, «compartimento completado» (3); a +1,5 s, `cerrar_vista('D01c', 'resuelto')`. 15 no escribe ningún hecho (el controlador no recibe referencia de escritura).
- **AC-P5-10 (R19, R20, L)**: **GIVEN** `RESOLVING` a 5 s, **WHEN** `atrás`, **THEN** se emite «resolución de puzle interrumpida», `caja_c3` falso, `pendiente_revelacion` verdadero, `P5` `ACTIVO`/`IDLE`, C3 `ENTREABIERTO`; **WHEN** se reabre, **THEN** no se evalúa la alineación, θ = θ* y la secuencia empieza en `FADE` (0 s).
- **AC-P5-11 (R21, L)**: **GIVEN** una carga con `caja_c3` falso y `pendiente_revelacion` verdadero, **THEN** `P5` `ACTIVO`, el hecho sigue verdadero y no se emite ningún aviso; **GIVEN** ambos verdaderos, **THEN** `P5` `RESUELTO` y el hecho queda falso por escritura silenciosa.
- **AC-P5-12 (R22, R23, L)**: **GIVEN** la entrada `P5` de `puzzles.json`, **THEN** hay tres pistas, todas `REQUEST`, sin `idle_s`; N1 y N2 referencian `PISTA_P5_N1` y `PISTA_P5_N2` (existentes en 18); N3 es `AFFORDANCE` `MARK_LIT` sobre `D01c/mark_40`; **WHEN** `request_hint(P5, 3)`, **THEN** la marca se ilumina, θ no cambia, `P5` no se resuelve y el nivel persiste al reabrir la vista; **GIVEN** `RESOLVING`, **WHEN** `request_hint(P5, k)`, **THEN** se ignora: sin efecto visible, el nivel alcanzado no cambia y no se emite aviso (D15-18; el comportamiento de `request_hint` en `RESOLVING` lo define el esquema v2 de 9).
- **AC-P5-13 (R24, R25, L)**: **GIVEN** `asistencia_rotacion` y `reducir_movimiento` en falso por defecto, **WHEN** se activa la primera durante la vista, **THEN** la tolerancia es 6° desde el siguiente gesto; **WHEN** se activa `reducir_movimiento`, **THEN** el siguiente `FADE` y `OUTLINE` duran 100 ms visuales (los pasos conservan 1,2 s y 0,8 s) y la recolocación de θ es instantánea.
- **AC-P5-14 (R28, L)**: **GIVEN** una carga con `caja_c3` verdadero, **THEN** `P5` `RESUELTO`, `set_final_pose(3)` se llama una vez, sin sonido ni avisos; **WHEN** el jugador pulsa sobre C3, **THEN** `SIN_EFECTO` (`NO_VIEW`).
- **AC-P5-15 (R3, I)**: **GIVEN** la prueba de resolubilidad de 9 (regla 30, `N_fuzz` = 1.000) con acciones de giro, pistas, cancelaciones, cierres/reaperturas y guardar/cargar a mitad, **THEN** el solucionador de referencia llega siempre a `caja_c3` = verdadero.
- **AC-P5-16 (R16, R17, PV)**: **GIVEN** la revelación en ejecución, **THEN** una captura retenida de cada paso (`FADE` a 0,6 s, `OUTLINE` a 2,0 s, `LINE` a 8 s) muestra: las dos fotos superpuestas y coincidentes, **solo** la silueta de Vera con contorno, y **ningún** texto, flecha, etiqueta ni cambio de cámara; el contorno se distingue en escala de grises (no depende del tono) y no usa rojo ni verde moral.
- **AC-P5-17 (R17, I)**: **GIVEN** `VO_G_07` en `LINE`, **THEN** suena desde `SPK_D01C` (no 2D) y el subtítulo permanece visible 14,0 s con y sin audio.
- **AC-P5-18 (R7, PV)**: **GIVEN** `D01a` completado y `D04` visto o no, **THEN** en θ* las cinco figuras de la foto de la caja coinciden con las de la foto de `D04` y la figura sobrante ocupa la posición del hueco S6; en θ* + 10° la desalineación es visible a simple vista.
- **AC-P5-19 (F-P5-5, PV)**: **GIVEN** ≥ 6 testers nuevos con el registro de la regla 32 de 9, **THEN** el tiempo mediano de `P5` (incluida la revelación de ~16 s, lectura de F7 de 9 de D15-7, no su literal «más ~16 s») cae en 1,5–3,0 min; **y** ≥ 50 % identifica la diferencia sin pista de nivel 3 (slice §19.5, AC-X3 de 9); **y** se pregunta a cada tester después de la revelación «¿qué había cambiado?» para separar identificación de alineación (Open Questions 1); **y** ninguno describe haber «fallado» o «perdido el progreso» al salir en mitad de la revelación (AC-X4 de 9).
- **AC-P5-20 (R5, R7, PV)**: **GIVEN** ratón y mando, **THEN** ≥ 5 de 6 testers sitúan el marco en la ventana y lo mantienen sin quejarse de no poder dejarlo quieto; si no, se revisa `hold_s` y la ganancia (Tuning Knobs).

## Datos del puzle

Entrada canónica de `assets/data/puzzles/puzzles.json` (esquema de la regla 4 de 9; sustituye al ejemplo ilustrativo de la regla 5 de 9, que no llevaba pistas ni `persist`). Todo valor numérico vive aquí, nunca en el controlador (coding standards). Las claves van en inglés; los IDs del slice se conservan.

```json
{
  "id": "P5",
  "mode": "VIEW",
  "view": "D01c",
  "solved_flag": "caja_c3",
  "requires": { "all": ["caja_c1"] },
  "needs_items": [],
  "validation": { "policy": "SUSTAINED", "hold_s": 0.8, "dt_max": 0.1 },
  "solution": {
    "theta_deg": 40,
    "tol_deg": 3,
    "theta_initial_deg": 0,
    "theta_min_deg": 0,
    "theta_max_deg": 90,
    "mark_step_deg": 5,
    "settle_s": 0.3,
    "interactive_elements": ["D01c/frame"],
    "visual_elements": ["D01c/reflection", "D01c/box_photo", "D01c/marks", "D01c/mark_40", "D01c/speaker"]
  },
  "on_reject": null,
  "assist": { "setting": "asistencia_rotacion", "tol_deg": 6 },
  "on_unlock": { "sfx": "SFX_UNLOCK_SOFT", "ajar_cm": 2 },
  "on_solved": {
    "write": [{ "flag": "caja_c3", "value": true }],
    "compartment": 3,
    "rewards": [],
    "close_view_after_s": 1.5
  },
  "on_reopen": "NO_VIEW",
  "resolution": {
    "kind": "DEFERRED",
    "resume_flag": "pendiente_revelacion",
    "steps": [
      { "id": "FADE",    "kind": "OVERLAY_FADE", "duration_s": 1.2 },
      { "id": "OUTLINE", "kind": "OUTLINE",      "duration_s": 0.8 },
      { "id": "LINE",    "kind": "LINE", "line": "VO_G_07", "fallback_s": 14.0, "line_grace_s": 2.0 }
    ]
  },
  "persist": ["pendiente_revelacion"],
  "hints": [
    { "level": 1, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [
        { "type": "TEXT", "key": "PISTA_P5_N1" },
        { "type": "HIGHLIGHT", "targets": ["D01c/reflection"], "duration_s": 3.0 } ] },
    { "level": 2, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [
        { "type": "TEXT", "key": "PISTA_P5_N2" },
        { "type": "HIGHLIGHT", "targets": ["D01c/reflection", "D01c/box_photo"], "duration_s": 3.0 } ] },
    { "level": 3, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [
        { "type": "AFFORDANCE", "affordance": "MARK_LIT", "targets": ["D01c/mark_40"] } ] }
  ]
}
```

Notas: `on_solved` no declara `sfx` (no hay sonido de acierto; D15-9). `on_reject` es nulo (el fallo no existe). `idle_s` no aparece en ninguna pista (todas `REQUEST`). Los campos enteros (`level`, `ajar_cm`, `compartment`, `theta_*_deg`, `mark_step_deg`) se cargan como `int` y `tol_deg`, `hold_s`, `settle_s`, `duration_s` como `float` (regla 29 de 9). `MARK_LIT`, `HIGHLIGHT` sobre elementos no interactivos, `on_reject: null`, `solution.visual_elements`, `request_hint` en `RESOLVING`, `OUTLINE` a 100 ms con `reducir_movimiento` y quién resuelve el entreabierto (14b(b) y (c)) los define el esquema v2 de `puzzles.json` de 9 (otro agente; ‡ hasta que se publique); los IDs visuales de `D01c` van además al catálogo de 7.

## Decisiones tomadas

Modo por lotes autónomo: se decide con la recomendación propia y se registra. Formato: decisión · alternativa descartada · motivo.

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D15-1 | **Sin fallo ni reinicio del marco**: θ se conserva siempre (B.5, D9-12; regla 15 de 9). | «Si falla, el marco vuelve a su posición inicial» (§10.5). | B.5 es la especificación de implementación y más reciente; el reinicio castigaría a quien ajusta (pilar *Tensión sin castigo*). Ya fijado por 9. |
| D15-2 | **Reflejo puramente geométrico**: sin imán, enfoque, brillo ni sonido de coherencia al acercarse a θ*; `HOLDING` no suena (regla 7). | Amortiguar el giro cerca de θ* («se siente imanada», Game Feel de 9) o aclarar el reflejo al acercarse. | Cualquier ayuda continua amplía `v_max` y convierte el puzle en «mantén el ratón quieto»; la señal debe ser la coincidencia visible (*Autonomía*, *Competencia*). La ventana de ±3° y los 0,8 s ya dan la sensación de imán sin automatismo. |
| D15-3 | **Marcas cada 5° sin cifras**; solo la de 40° se ilumina con el nivel 3. | Numerar las marcas. | Las cifras ofrecerían un lenguaje de «ángulo correcto» sin información de dónde está; la pista 3 sigue siendo una pista. |
| D15-4 | **θ se conserva en la sesión (`KEEP`) y no se persiste.** | Persistir θ (nuevo hecho) o reiniciar a 0° al salir. | Regla 22 de 9: el marco no añade hechos; reiniciar al salir sería un coste sin motivo (regla 21 de 9). |
| D15-5 | **Pistas:** las tres `REQUEST`; N1 y N2 añaden un `HIGHLIGHT` de las fotos al texto del slice; N3 es `AFFORDANCE` `MARK_LIT` que no resuelve. | Dejar N1/N2 solo con texto (acantilado hasta N3, D-W3) o añadir un nivel nuevo. | El resaltado es énfasis de información existente (regla 27 de 9), no añade claves (las 8 son cerradas) y rellena el salto entre «mira mejor» y «aquí está la marca». |
| D15-6 | **D-W3 aceptada:** un giro < 7,5°/s resuelve sin comprensión (F-P5-2/3). No se sube `hold_s` ni se añade comprobación de «comprensión». | Subir `hold_s` (no ayuda: el límite baja, no sube), bajar la tolerancia o exigir otro gesto. | No hay castigo ni exclusión; la revelación enseña el hecho aunque el jugador no lo haya deducido (la comprensión la entrega la imagen, no el giro). Lo que cambia es **cómo se mide** el criterio 5: Open Questions 1. |
| D15-7 | **El presupuesto de 1,5–3 min de F7 incluye los ~16 s de revelación.** | Sumarlos aparte (F7 dice «más ~16 s»). | F9 suma 10,5–22 min sin añadirlos; interpretarlo «aparte» desplazaría F9 en 0,27 min. Se pide aclarar a 9. |
| D15-8 | **Recolocación a θ* con tween de 0,3 s†** (instantánea con `reducir_movimiento`). | Salto instantáneo o tween largo. | La recolocación máxima es ≤ 6°; un salto se lee como «el juego lo ha hecho por mí»; un tween largo retrasa `FADE`. |
| D15-9 | **Sin sonido de acierto** en `FADE` ni `OUTLINE`; silencio parcial hasta `VO_G_07`. | Un `SFX_` de revelación. | Slice §14 (silencios parciales) y *El espacio expresa la emoción*; evita un jingle de «¡acertaste!». El diseño de sonido de esos pasos es de 23/audio. |
| D15-10 | **Vera ocupa la posición de S6** en el reflejo (requisito de contenido ‡). | Vera en cualquier parte del margen. | Convierte el hueco que el jugador sintió en el Puzle 3 en el hallazgo del Puzle 5; si el arte lo contradice, Open Questions 3. |
| D15-11 | **El contorno se distingue por forma y luminancia**, sin rojo/verde ni codificación moral. | Resaltado en color. | Pilar *Ambivalencia sin moral binaria* y art bible; accesibilidad para daltonismo. |
| D15-12 | **No hay botón de omitir la revelación**; tras interrumpirla se repite entera. | Permitir saltar tras la primera audición completa. | Es la función narrativa del puzle (D9-6); el coste máximo es 18,0 s y no hay penalización. Si se completa, no hay repetición. |
| D15-13 | **Un cambio de `asistencia_rotacion` se aplica al siguiente gesto.** | Aplicarlo al acumulador en curso. | La pausa ya cancela el gesto (regla 11b de 9) y el acumulador no debe arrastrarse entre tolerancias (AC-52 de 9). |
| D15-14 | **`rewards` vacío**; la recompensa es la revelación y la grabación. | Entregar un ítem. | El slice D.1 no define ninguno; añadirlo sería inventar contenido. |
| D15-15 | **15 no lee `reducir_sobresaltos`.** | Leerlo para suavizar el fundido. | Ajustes lo entrega solo a 23 y 28; la secuencia no contiene destellos; el «golpe» de la puerta de la grabación lo gestiona 23. |
| D15-16 | **Se confirma `asistencia_rotacion`** (bool, falso, ±6°) como nombre del ajuste (Open Questions 5 de 6, asignada a 15). | Reutilizar `asistencia_encaje`. | Son tolerancias de unidades distintas (° y m) y puzles distintos. |
| D15-17 | **La marca de 40° queda iluminada** el resto de la sesión una vez pedido el nivel 3. | Que se apague a los 3 s como `HIGHLIGHT`. | «Se ilumina la marca» (B.5) es un estado, no un destello; el jugador debe poder girar hacia ella. |
| D15-18 | **`request_hint` durante `RESOLVING` se ignora y no cuenta como nivel alcanzado.** | Aceptarlo y avanzar el nivel sin efecto, o rechazarlo con aviso. | La alineación ya está hecha; avanzar el nivel sin efecto gastaría una pista (regla 26 de 9, monótono) y un aviso sería ruido. Lo define el esquema v2 de 9 (ronda 7). |
| D15-19 | **Del «solo queda visible Vera» de §10.5 a B.5: superposición de las dos fotos más contorno de Vera.** | Hacer desaparecer las figuras coincidentes y dejar solo la silueta de Vera (§10.5). | B.5 (más reciente, especificación de implementación) pide superposición; mostrar las dos fotos coincidentes y marcar la única figura sobrante enseña el hecho observable por comparación, sin ocultar el resto (*Información incompleta*, *Autonomía*), y evita una animación de desaparición. |
| D15-20 | **Velocidades de AC-P5-04 con margen (7/8°/s y 14/16°/s) y fase fijada**; los fotogramas se recalculan. | Mantener 7,4/7,6°/s y 14,8/15,2°/s (47 o 48 fotogramas según la fase; 48 ya resuelve). | Revisión de la ronda 6: prueba inestable. Con margen ≥ 3 fotogramas el resultado es independiente de la fase. |
| D15-21 | **13 es dependencia blanda de contenido, no ‡.** 15 pide a 13 y a 10 que la listen como dependiente. | Mantener la marca «13 sin redactar» (dura, ‡). | 13 existe y su regla 23 ya reserva `slot_6` vacío y la imagen para la secuencia de P5; lo que 15 necesita es un recurso de arte, no un contrato de lógica. |
| D15-22 | **`T_ent` = 2,4 s** (`BOX_C3_OPEN` 1,4 s† de 10 + vista de entrada 1,0 s), no 1,0 s. | Ignorar la animación de la tapa. | La tapa de C3 se abre antes de ver `D01c` (F1 de 10); el total del modelo pasa a 56,2–188,2 s. |

## Open Questions

Lo que cambia pilares, tono o alcance del slice, o contradice el slice, **no se decide aquí**.

1. **Criterio 5 del slice (§19.5): ¿mide identificación o alineación?** Un giro lento resuelve sin comprender (D-W3, F-P5-3). Propuesta: medir el criterio con una pregunta posterior a la revelación («¿qué había cambiado?») y no con «sin pista nivel 3». Cambiar la redacción del slice requiere decisión del usuario. *Responsable:* usuario / creative-director.
2. **`VO_G_07` y el pilar *Información incompleta*.** La línea («Lo pedí sin preguntarte, Vera. Lo pedí y después te lo conté como si fuera tuyo», slice §12) afirma un acto del Guardián; los pilares 1 y 5 prohíben confirmar su **intención**. Este GDD no toca la línea (la revelación muestra, no explica), pero conviene decidir si es un hecho observable o una confirmación de intención. **Abierta: no la decide 15** (pilares 1 y 5); mientras tanto la secuencia no depende del texto de la línea (solo de su duración, `fallback_s`). *Responsable:* creative-director (con narrative-director).
3. **Composición de las fotos.** Que la figura sobrante de `D04` caiga en el hueco S6 de la foto de la caja (D15-10) y que, a θ*, las otras cinco coincidan figura por figura, es un requisito de contenido para 13 y arte que no está en el slice («Vera al margen», Anexo A). *Responsable:* art-director / 13.
4. **Sonido del giro y de los pasos `FADE`/`OUTLINE`.** `SFX_FRAME_TURN` (lazo de giro) no existe en B.7; el sonido de los dos primeros pasos es silencio parcial (D15-9). *Responsable:* audio / 23.
5. **`reducir_sobresaltos` y el «golpe» de la puerta de `VO_G_07`.** ¿Debe 23 atenuarlo con la opción? 15 no lo lee (D15-15). *Responsable:* 23 (aún sin GDD).
6. **Relectura de la grabación.** Tras resolver, `VO_G_07` no puede volver a oírse (`NO_VIEW`, sin relectura de audio); solo se vuelve a oír si se interrumpe. ¿Se quiere un repaso en el bolsillo o en el menú? Cambiaría alcance (sistema 20/25). *Responsable:* usuario.
7. **Nombre del ajuste y rango.** Confirmado en D15-16; pendiente de que 6 lo marque como cerrado.

## Cambios requeridos en otros GDDs

Esta ronda solo edita este GDD; lo siguiente debe hacerlo el dueño de cada documento.

| Documento | Cambio |
|---|---|
| 9 `marco-de-puzles.md` | (a) **Nota en F7 y F9**: F7 se interpreta con la revelación de ~16 s **incluida** en los 1,5–3 min de `P5` (D15-7; el literal «más ~16 s» contradice AC-P5-19); de lo contrario F9 sube a 15,10–33,36 min. (b) El **esquema v2** de `puzzles.json` (otro agente) debe cubrir lo que 15 usa: 14b(b) `reducir_movimiento` con `OUTLINE` a 100 ms (no solo `FADE`); 14b(c) quién resuelve el entreabierto (15 asume 10); efecto `MARK_LIT` en `AFFORDANCE`; `HIGHLIGHT` sobre elementos visuales no interactivos (regla 29); `on_reject: null`; `solution.visual_elements`; `request_hint` en `RESOLVING` ignorado y sin contar como nivel (D15-18). (c) Declarar que la entrada `P5` de «Datos del puzle» de 15 sustituye al ejemplo ilustrativo de la regla 5. |
| 6 `ajustes-persistentes.md` | Cerrar la Open Question 5: `asistencia_rotacion` (bool, falso, ±6°) confirmada por 15 (D15-16). |
| 7 `interaccion-e-inspeccion.md` | Catálogo de `D01c`: `D01c/frame` (`rotar`, `atraccion` falso) y los elementos visuales no interactivos de «Datos del puzle»; comprobar que «alternar en lugar de mantener» cubre `rotar`. |
| 10 `caja-y-compartimentos.md` | **Listar a 15 como dependiente** (hoy no lo menciona); corregir la contradicción interna (una línea deja C3 `ABIERTO` y otras dos `ENTREABIERTO` en la interrupción de `RESOLVING`; 15 usa `ENTREABIERTO`, regla 4 y AC-34 de 10); confirmar `SPK_D01C` y `ANC_D01C` perpendicular al plano de `D01c` y que la tapa de C3 no se cierra durante `RESOLVING`. |
| 13 `puzle-3-encaje-de-la-foto.md` | **Listar a 15 como dependiente** (blanda, de contenido: hoy no figura); su regla 23 ya deja `slot_6` vacío y la imagen para la secuencia de P5: nombrar el recurso exportado como la foto completa reutilizable por `D01c/box_photo` y fijar la composición de S6 (Open Questions 3). El índice mantiene 13 entre las dependencias de 15 (blanda). |
| 17 Sistema de pistas ‡ | `P5`: tres niveles, todos `REQUEST`, sin `IDLE`; el nivel 3 no resuelve. |
| 23 Director de audio ‡ · 26 Subtítulos ‡ | `VO_G_07` desde `SPK_D01C`; subtítulo de 14,0 s con y sin audio; `SFX_FRAME_TURN` (opcional); decisión sobre `reducir_sobresaltos` (Open Questions 5). |
| 29 Shaders y efectos de superficie ‡ | Superposición con coincidencia figura por figura en θ*, contorno solo en Vera (forma y luminancia, no rojo/verde), fundido de 100 ms con `reducir_movimiento`. |
| `systems-index.md` | Fila 15: estado «Borrador (lote Feature 3) — pendiente de review» y ruta `design/gdd/puzle-5-espejo-de-la-diferencia.md`; dependencias 6, 9, 10, 13 (dura en 9 y 10; blanda en 6 y 13). |
| `design/slice/slice-v0.3.md` | §19.5: ver Open Questions 1 (no se cambia sin decisión del usuario). |
| Registro | Ver «Entradas para el registro». |

## Entradas para el registro

Ya existen en `design/registry/entities.yaml` (no duplicar; la fuente es la de cada fila del registro: 9, el slice o 6 según la constante, p. ej. `asistencia_rotacion_deg` viene de 6 y las de B.5 del slice; comprobar `source:` antes de citarlas): `theta_solution_deg_P5`, `tol_deg_P5`, `asistencia_rotacion_deg`, `hold_s_P5`, `reveal_fade_s_P5`, `reveal_outline_s_P5`, `line_fallback_s_P5`, `line_grace_s`, `close_view_after_s`. Se propone añadir (fuente: este GDD) o hacer que este GDD sea fuente secundaria de:

| Tipo | Nombre | Valor | Unidad / rango | Nota |
|---|---|---|---|---|
| constante | `dt_max_P5` | 0,1 | s · 0,05–0,2 | Tope por fotograma del acumulador (F2 de 9) |
| constante | `theta_initial_deg_P5` | 0 | ° · 0–90, fuera de la ventana asistida | |
| constante | `theta_range_deg_P5` | [0, 90] | ° | Recorrido del marco (slice B.5) |
| constante | `mark_step_deg_P5` | 5 | ° · 5–15 | Marcas cada 5° |
| constante | `theta_settle_s_P5` ▲ | 0,3 | s · 0–0,6 | Tween de recolocación a θ* |
| constante | `hint_highlight_s_P5` ▲ | 3,0 | s · 2,0–5,0 | `HIGHLIGHT` de N1 y N2 |
| constante | `ajar_cm_P5` | 2 | cm · 1–4 | Entreabierto (slice B.5; si no está ya registrado desde 9) |
| fórmula | `v_max_deg_s_P5` | `W / hold_s`: 7,5 (normal) / 15 (asistido) | °/s | F-P5-2 |
| fórmula | `T_seq_P5` | 1,2 + 0,8 + T_line: nominal 16,0; rango 2,0 + t_terminada a 18,0 | s | F-P5-4 (instancia de F8 de 9) |
| fórmula | `T_P5_modelo` | 56,2–188,2 | s | F-P5-5 (con `T_ent` 2,4 s); contrastar con F7 (1,5–3 min, revelación incluida, D15-7) |
| entidad | `D01c/frame`, `D01c/reflection`, `D01c/box_photo`, `D01c/marks`, `D01c/mark_40`, `D01c/speaker` | — | — | Elementos de la vista de `P5` (IDs con prefijo de vista) |
| entidad | `MARK_LIT` ‡ · `SFX_FRAME_TURN` ‡ | — | — | Afordancia de pista nivel 3 · lazo de giro opcional |

▲ = valor propuesto, a validar en playtest. Ningún hecho nuevo (el catálogo de D.2 no cambia) ni aviso nuevo.

## Historial

| Fecha | Versión | Cambio |
|---|---|---|
| 2026-11-09 | 0.1 | Esqueleto (lote Feature 3). |
| 2026-11-09 | 0.2 | Borrador completo: 29 reglas, F-P5-1 a F-P5-5, 25 edge cases, 20 AC, datos de `P5`, 17 decisiones, 7 preguntas abiertas. Pendiente de review independiente. |
| 2026-11-09 | 0.3 | Ronda de corrección 7 (review: 0 bloqueantes, 10 avisos): AC-P5-04 con 7/8 y 14/16°/s y fase fijada (45 vs 51-52 fotogramas); 13 pasa a dependencia blanda de contenido (regla 23 de 13) y 15 se pide como dependiente en 10 y 13; extensiones de 9 referidas al esquema v2; `request_hint` en `RESOLVING` ignorado (D15-18); D15-19 a D15-22 (§10.5 a B.5, AC-04, 13 blanda, `T_ent` 2,4 s, total 56,2–188,2 s); lectura de F7 con revelación incluida; fuente real de constantes del registro; `VO_G_07` queda abierta para creative-director. Pendiente de re-review. |
