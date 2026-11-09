# Llamada telefónica (sistema 22)

> **Estado:** Borrador (lote Feature 2) — pendiente de review
> **Autor:** narrative-director (lote autónomo, 2026-11-09)
> **Capa:** Feature · **Categoría:** Narrativa / Gameplay
> **Fuente de verdad:** `design/slice/slice-v0.3.md` (contenido v0.4.1): §11 escena 7 y 11.1, §8.5/D-03, §13, Anexo C.7, Anexo D.2/D.3.
> **Implements Pillar:** Tensión sin castigo (ninguna respuesta es incorrecta; ningún camino sin salida) · Ambivalencia sin moral binaria (las cuatro respuestas pesan distinto, no «bien/mal»; sin medidores) · Información incompleta (la llamada no explica: `VO_G_13B` = «Lo sé») · Autonomía como progresión (decidir qué responder, incluido no responder)
> **Anti-pilares vigilados:** NOT una historia explicada · NOT medidores de moral o relación.
> **Marcas:** ‡ = contrato propuesto a un sistema aún sin GDD (23 Audio y voz) · † = valor provisional, a validar en playtest.

## Summary

La llamada telefónica es el momento más íntimo del slice (escena 7, 02:30). Tras el apagón suena `V02` en el despacho de Vera con su propia extensión; Vera descuelga, El Guardián le habla con una primera línea que depende de la carta elegida (`VO_G_12A/B/C`) y el jugador elige una de cuatro respuestas («Estoy bien», «Estoy desbordada», «No quiero hablarlo ahora», «No responder»). El Guardián contesta (`VO_G_13A–D`), la llamada termina y se activa el ascensor. Este sistema es el único que escribe `llamada_iniciada`, `respuesta_llamada` y `llamada_completada`, y el único dueño del contexto de entrada `llamada` y del estado `en_llamada` de `V02`. No explica nada, no puntúa nada y no se puede fallar.

## Overview

El sistema 22 se pone en marcha cuando el jugador pulsa «Descolgar» sobre `V02` en estado `vibrando` (el timbre lo pone 21, no 22). Ejecuta una máquina de estados lineal con una sola decisión: `Inactiva → Descolgando → Silencio → Respiración → Línea de variante → Opciones → Respuesta → Cierre → Completada`. La primera línea la elige leyendo `carta_variante` (hecho de 9); la respuesta se escribe como `respuesta_llamada` (A, B, C o D) y solo cambia la última línea de Vera en Recepción (escena 8, `VO_V_12A–D`, a cargo de 21) y la línea de respuesta del propio Guardián. Si el jugador no elige en 20 s de juego, suena un llanto contenido y El Guardián dice `VO_G_14_RET` o `VO_G_14_ASG` según `t4_decision`; las opciones siguen visibles y no se elige nada por el jugador. «No responder» equivale a la elección `D`.

Tres garantías de diseño sostienen el sistema: (1) **sin castigo ni callejón**: las cuatro respuestas, incluida no responder, llevan al mismo cierre y al mismo ascensor; no hay temporizador que decida; (2) **sin explicación**: ninguna línea confirma la intención del Guardián (`VO_G_13B` = «Lo sé») y ningún hecho de la llamada mide moral ni relación (los tres hechos solo cambian líneas); (3) **atómica y reanudable**: la llamada se juega entera o se repite entera (GDD 5, reglas 11 y 12); nunca se guarda `respuesta_llamada` ni `llamada_completada`. Los textos son los del slice y de la base de contenido (18); este GDD no los reescribe. El audio y la voz los reproduce 23 (sin GDD): todo contrato con él lleva ‡.

## Player Fantasy

Vera descuelga un teléfono que marca su propia extensión y oye respirar a alguien que la conoce. El jugador siente que le hablan a él y que lo que diga, o calle, importa sin que nadie se lo explique ni lo juzgue: la oficina se queda a oscuras y en silencio para que la voz pese. Puede ser sincero, defensivo, evasivo o callar, y ninguna es la correcta; solo cambia lo que Vera dirá después, a solas en Recepción. Si tarda, la llamada espera con él (un llanto contenido, un «Sigo aquí») y nunca lo empuja. Pilares servidos: *Ambivalencia sin moral binaria*, *Tensión sin castigo*, *Información incompleta*.

## Detailed Rules

**Estados de la llamada (máquina de 22).** `INACTIVA` → `DESCOLGANDO` → `SILENCIO` → `RESPIRACION` → `LINEA` → `ANTES_OPCIONES` → `OPCIONES` → `RESPUESTA` → `CIERRE` → `COMPLETADA`. `OPCIONES` tiene dos subestados: `ESPERA` (0 a 20 s†) y `SENAL` (llanto contenido y `VO_G_14_*` en curso; las opciones siguen visibles). Solo hay un camino hacia delante: nunca se vuelve a un estado anterior y ninguno es terminal salvo `COMPLETADA`.

**A. Cuándo suena el teléfono y cómo se descuelga**

1. **22 no tiene disparador propio.** La llamada empieza únicamente cuando el jugador activa el verbo «Descolgar» sobre `V02` en estado `vibrando` (7 delega el verbo en 22: catálogo de 7, fila `V02`). Quién hace sonar el teléfono es 21: `ESC7_TIMBRE` al cruzar `T-OFI-IN` con `apagon_activo`, o `TELEFONO_SUENA` a los 60,0 s† del apagón (21, reglas 4 y 15). 22 no lee el temporizador ni decide cuándo suena, salvo en la reanudación (regla 30).
2. **`can_interact(V02, Descolgar)` de 22** es verdadero si y solo si `V02` está `vibrando` ∧ `caja_completa` ∧ ¬`llamada_completada` ∧ la máquina de 22 está `INACTIVA`. Con `V02` en `reposo` el verbo no existe (el verbo «Responder» de la escena 1 es de 7/21 y no inicia llamada, 21 regla 15). 22 no ofrece ningún otro verbo.
3. **`interact(Descolgar)`**, en el mismo fotograma lógico y en este orden: (a) si `llamada_iniciada` es falso, 22 lo escribe (3) y **inmediatamente después** emite el aviso «llamada iniciada»; esto ocurre antes de cualquier otro elemento de la llamada (restricción de 5, regla 12) y es el único punto de sellado; (b) pide a 1 el contexto `llamada` (1, regla 6); (c) pone `V02` en `en_llamada`; (d) entra en `DESCOLGANDO`. El gesto `ANIM_PHONE_PICKUP` (0,8 s) lo pidió 7 a 2 antes de llamar a `interact()` (7, regla 3); al terminar, 2 mantiene `HAND_PHONE_HOLD` (bucle) hasta el colgado (regla 24). Si `llamada_iniciada` ya es verdadero (llamada reanudada), 22 no lo reescribe ni vuelve a emitir el aviso (3, edge case «llega dos veces»; 5, AC-18).
4. **El jugador no pierde el control de forma brusca.** `llamada` es un contexto de Entrada (1, regla 6) que 2 trata como «Congelado»: la cámara queda quieta en la orientación actual y las manos sostienen el teléfono. No es `sin control` (que es de 21 y 4) y no hay desplazamiento de cámara hacia el teléfono.

**B. Secuencia de la llamada (tiempos de C.7)**

5. `DESCOLGANDO` (0,8 s): el gesto de 7. Sin audio nuevo; 22 pide a 23 cortar el bucle `SFX_PHONE_BUZZ` ‡ (el sonido del timbre es de 21; cortarlo lo pide quien lo detiene).
6. `SILENCIO` (2,0 s†): silencio de línea. `RESPIRACION` (2,0 s†): respiración del Guardián (sonido sin ID en el slice; propuesta `SFX_CALL_BREATH` ‡, Entradas para el registro). Sin subtítulo (no es un evento que el jugador necesite leer; ver Open Questions nº 4).
7. `LINEA` (≈5 s†): 22 lee `carta_variante` (A, B o C) y emite «línea pedida» con el ID `VO_G_12A`, `VO_G_12B` o `VO_G_12C`. Espera «línea terminada» de 23. Los textos son los de 18 y no se reescriben aquí.
8. `ANTES_OPCIONES` (1,0 s†) tras «línea terminada»: silencio. Después las opciones aparecen (regla 9).
9. `OPCIONES`: aparecen **cuatro** opciones en este orden fijo: «Estoy bien» (A), «Estoy desbordada» (B), «No quiero hablarlo ahora» (C), «No responder» (D). Textos y claves de 18 (propuesta de clave `UI_LLAMADA_OPCION_A` a `_D`, a confirmar en 18). Todas con idéntico aspecto (sin color ni icono moral: pilar 1, art bible), sin resaltar ninguna por defecto, sin aleatorizar. Al aparecer, 22 pide a 1 mostrar el cursor (regla 22) y empieza la **cuenta de espera** (regla 14). Durante `t_guarda_opciones_s` (0,6 s†) tras aparecer, las pulsaciones se ignoran (no se encolan): evita elegir sin querer con el mismo pulso que descolgó o con una pulsación repetida.
10. **Cómo se elige.** Con ratón, clic sobre una opción; con teclado o mando, `ui_arriba`/`ui_abajo` mueven el foco (la primera pulsación lo coloca en A; el mando mueve el cursor solo con el stick derecho, 1) y `ui_aceptar` o `seleccionar` eligen la opción enfocada (1, tabla de contextos). Mover el foco o el cursor **no** elige. `ui_atrás` y `atrás` no hacen nada en `llamada` (no hay colgar manual: «No responder» es la salida de quien no quiere hablar, regla 12). `pausa` abre el menú (regla 26).
11. **La elección es definitiva y se confirma al instante.** No hay paso de confirmación ni «volver a elegir»: el slice (§11.1, D.2) reproduce la línea al elegir y el hecho `respuesta_llamada` es de un solo sentido (3, regla 4). Lo que sí se puede repetir libremente antes de elegir es el recorrido del foco (regla 10) y la espera es ilimitada (regla 14). Ver decisión D22-4 y Open Questions nº 3.
12. **«No responder» (D)** es una opción como las otras: botón visible y elegible desde que aparecen las opciones. Elegirla equivale a callar: guarda `D` y El Guardián dice `VO_G_13D`. No elegir nada **no** equivale a elegir D (regla 14): la llamada espera.

**C. Espera y señal de los 20 segundos**

13. La cuenta de espera `t_espera_s` (20,0 s†) empieza **al aparecer las opciones** (incluye los `t_guarda_opciones_s` iniciales; D22-6) y solo cuenta tiempo de juego: se detiene con la pausa (1, Edge Cases, «menú de pausa abierto durante `llamada`»).
14. **Al cumplirse `t_espera_s` sin elección**, 22 entra en el subestado `SENAL` **una sola vez en toda la llamada**: (a) pide `SFX_BREATH_BROKEN` (4,0 s†) con el subtítulo `SUB_BREATH_BROKEN` (regla 20); (b) al terminar el sonido, emite «línea pedida» con `VO_G_14_RET` si `t4_decision` = `returned` o `VO_G_14_ASG` si `assigned`. **Las opciones siguen visibles y elegibles durante todo el subestado y después.** Pasada la señal, `OPCIONES` continúa en `ESPERA` sin límite: no se repite la señal, no se elige nada por el jugador, no hay temporizador que decida (pilar *Tensión sin castigo*; D-15 del slice).
15. **Elegir durante `SENAL`** es válido y tiene prioridad: 22 pide a 23 interrumpir lo que suene de la señal (cierre en ≤ 0,3 s† ‡) y sigue con la regla 17. El jugador nunca espera a que acabe una línea para responder.
16. **Si `t4_decision` no está fijado** (solo posible con consola de desarrollo): 22 usa `VO_G_14_RET` (es la `VO_G_14` original del slice, sin cambios en 18) y registra una advertencia.

**D. Respuesta y cierre**

17. **Al elegir**, 22 en este orden: (a) escribe `respuesta_llamada` (A, B, C o D) en 3; (b) oculta las opciones y devuelve el cursor a oculto; (c) emite «línea pedida» con `VO_G_13A` a `VO_G_13D`; (d) pasa a `RESPUESTA`. Si la escritura es rechazada por estar ya fijado otro valor (solo consola de desarrollo), 22 lee el valor guardado, reproduce la línea de **ese** valor y registra la discrepancia.
18. **Líneas de respuesta** (textos de 18/slice §11.1, sin cambios): A `VO_G_13A` «Ya. Eso dijiste también la última vez»; B `VO_G_13B` «Lo sé»; C `VO_G_13C` «Vale. Pero la caja sigue en tu mesa»; D `VO_G_13D` «Entonces hablo yo. Te he dejado la caja abierta. Cuando quieras». Ninguna respuesta añade explicación, ninguna cambia lo que Vera sabe, y `VO_G_13B` no confirma la intención del Guardián (anti-pilar *NOT una historia explicada*, pilar 1; D-B2 del slice).
19. `CIERRE`: tras «línea terminada» de la respuesta, silencio de 1,0 s†. Luego, en este orden: `SFX_PHONE_END` (pedido a 23 ‡), escritura de `llamada_completada` = verdadero (3), emisión de «llamada completada», y petición a 2 del gesto `HAND_PHONE_PUTDOWN` (≤ 0,6 s†). Al terminar el gesto (o a los 0,6 s† si 2 lo rechaza), 22 libera el contexto `llamada` (1), pone `V02` en `reposo` y la máquina pasa a `INACTIVA`; el control vuelve a `exploración`.
20. **Subtítulo del llanto contenido.** El sonido `SFX_BREATH_BROKEN` es un evento sonoro sin palabras que el jugador necesita poder leer (18, regla 22): clave `SUB_BREATH_BROKEN` con texto provisional «[Llanto contenido]» y marcador de pendiente. El texto lo cierra el writer (Open Questions nº 5). Se muestra solo si los subtítulos están activos (ajustes, 6; lo muestra 26).

**E. Qué ocurre alrededor (propiedad de otros sistemas)**

21. **Hechos que escribe 22** (y solo 22): `llamada_iniciada` (regla 3), `respuesta_llamada` (regla 17), `llamada_completada` (regla 19). **Hechos que lee:** `carta_variante`, `t4_decision`, `caja_completa`, `llamada_completada`, `llamada_iniciada`. 22 no lee `respuesta_llamada` salvo en la regla 17. Ninguno de estos hechos es un medidor: solo eligen líneas.
22. **Presentación de las opciones.** Panel diegético sobre la vista del teléfono, sin cursor circular (1, sección Visual; el círculo es de la luz del mundo). El cursor está oculto hasta `OPCIONES` y vuelve a ocultarse al elegir (cambio requerido en 1, que hoy lo da por visible en todo `llamada`).
23. **`C03`, lluvia y ascensor** no son de 22. `ESC7_RESTAURAR` (21, a +2,0 s† de `llamada_completada`) y la activación de `C08` (8, `t_ascensor_s`, regla 13) reaccionan al hecho; 22 no emite ninguna orden a 21 ni a 8 (índice, nota de ciclos). Si el jugador pulsa `C08` antes de que esté activo, 8 lo resuelve (`MEGA_03`).
24. **Manos.** Durante `LINEA` a `CIERRE` 2 muestra `HAND_PHONE_HOLD`; 22 solo pide `HAND_PHONE_PUTDOWN` (regla 19). Las manos nunca se ocultan.
25. **Respuesta de 23 ‡.** Tras «línea pedida», 23 responde «línea terminada», «línea sin audio» o «línea fallida» con el ID (3, tabla de avisos). Con las dos últimas, 22 espera `fallback_s` de la línea (duración nominal de 18) para que el subtítulo (26) tenga su tiempo y continúa: la llamada **no se bloquea** por un fallo de audio (mismo modelo que 9, regla 20).

**F. Pausa, cierre del juego y reanudación**

26. **Pausa.** `pausa` está permitida en todo `llamada` (1). Congela la máquina, la cuenta de espera y el audio de la llamada (23 ‡). Al cerrar el menú, `llamada` vuelve tal cual estaba, con el foco donde estaba. Pausar no sella ni guarda nada (5, regla 11).
27. **Cierre del juego durante la llamada.** El guardado de sellado ya está escrito desde el aviso de la regla 3 (5, regla 11): al continuar, 5 restaura con `llamada_iniciada` verdadero y `llamada_completada` falso, y la llamada se repite **entera**. `respuesta_llamada` y `llamada_completada` nunca llegan a disco (5, reglas 10 y 11): una respuesta ya elegida se pierde y puede cambiarse al repetirla.
28. **Cierre antes del sellado** (fallo de escritura del sellado, o cierre entre el cruce de `T-D-OUT` y el descolgar): el fichero tiene `caja_completa` ∧ ¬`llamada_iniciada`; 21 aplica el apagón reducido y `ESC7_TIMBRE` (21, regla 14) y la llamada empieza como la primera vez.
29. **Cierre tras completarla** pero antes de `slice_completed`: se repite la llamada (consecuencia aceptada de 5, regla 11).
30. **Reanudación con llamada pendiente.** Tras «escena lista» y al volver `exploración`, si `llamada_iniciada` ∧ ¬`llamada_completada`, 22 pone `V02` en `vibrando` (el timbre tiene un único dueño por caso: 21 si ¬`llamada_iniciada`, 22 si `llamada_iniciada`; 21 regla 14) y 22 espera a «Descolgar». Al descolgar, la llamada se repite desde `DESCOLGANDO`, sin variaciones (sin «atajo» ni líneas distintas por ser repetición).
31. **Ningún camino sin salida.** La llamada no se puede suspender de forma permanente: toda combinación de acciones (pausar, cerrar, no responder, esperar, descolgar en cualquier momento tras el apagón) termina en `llamada_completada` por una elección del jugador. 22 no tiene estado de fallo.

**G. Lo que 22 no hace**

32. No decide ni cambia nada del aspecto visual (apagón, lluvia, luces: arte/21); no escribe `carta_variante` ni `t4_decision` (9); no reproduce audio (23); no muestra subtítulos (26); no abre menús; no inicia Recepción (4, tras «ascensor llamado»); no muestra puntuaciones, iconos ni texto que valore la respuesta; no guarda (5).

## Formulas

**Variables (todas en segundos de juego; la pausa no cuenta).**

| Variable | Valor | Rango | Origen |
|---|---|---|---|
| `t_pick` | 0,8 | fijo (duración de `ANIM_PHONE_PICKUP`) | slice C.7, B.7 |
| `t_sil` | 2,0† | 1,0–4,0 | slice C.7 |
| `t_resp` | 2,0† | 1,0–4,0 | slice C.7 |
| `L12` | ≈5,0† | 3–8 (duración real de `VO_G_12A/B/C`, la informa 23) | slice C.7 |
| `t_ante` | 1,0† | 0,5–2,0 | slice C.7 («+1,0 tras la línea») |
| `t_guarda` | 0,6† | 0–1,0 | D22-5 |
| `t_e` | decisión del jugador, desde que aparecen las opciones | `t_guarda` a ∞ | — |
| `t_espera` | 20,0† | 10–40 | slice C.7 / D-15 |
| `T_breath` | 4,0† | fijo (`SFX_BREATH_BROKEN`) | slice C.7 |
| `L14` | ≈5,0† | 2–8 (`VO_G_14_RET` ≈ 1 s; `VO_G_14_ASG` ≈ 3 s; la media de 9 usa 5) | GDD 9, tiempos |
| `L13` | ≈4,0† | 2–7 (`VO_G_13A–D`, duración no fijada en el slice) | GDD 9, tiempos |
| `t_cierre` | 1,0† | 0,5–2,0 | slice C.7 («+1,0 tras la respuesta») |
| `t_putdown` | ≤0,6† | 0,3–0,8 | GDD 2 (`HAND_PHONE_PUTDOWN`) |

**F1 · Inicio de la línea de variante.** `T_linea = t_pick + t_sil + t_resp` = 0,8 + 2,0 + 2,0 = **4,8 s**.
*Lectura adoptada de C.7 (D22-1):* la fila «+4,0 | Línea de variante» es silencio (2,0) + respiración (2,0) y la animación es previa. *Lecturas descartadas:* (a) la línea a +4,0 s desde el pulso, con silencio y respiración solapando la animación (0,8 s menos); (b) silencio y respiración **más** otros 4,0 s (línea a 8,8 s), que es lo que supone la estimación de 9 (14,8 s hasta las opciones). Ver Open Questions nº 1.

**F2 · Aparición de las opciones.** `T_opc = T_linea + L12 + t_ante` = 4,8 + 5,0 + 1,0 = **10,8 s** (rango por `L12` de 3 a 8 s: 8,8–13,8).

**F3 · Fin de la llamada para el jugador.** `T_compl(t_e) = T_opc + t_e + L13 + t_cierre`, con `t_e ≥ t_guarda`.
La espera larga **no suma**: si `t_e > t_espera`, la señal (`T_breath + L14` = 9,0 s) ocurre dentro de `t_e` y elegir la interrumpe (regla 15).
Efectos sobre la escena: `llamada_completada` en `T_compl`; luces y lluvia en `T_compl + 2,0` (`retardo_restaurar_s`, 21); `C08` activo en `T_compl + t_ascensor_s` (8); control de vuelta en `T_compl + t_putdown`.

| Caso | `t_e` | `T_compl` | Cálculo |
|---|---|---|---|
| Elige lo antes posible | 0,6 | **16,4 s** | 10,8 + 0,6 + 4,0 + 1,0 |
| Lectura normal | 8,0 | **23,8 s** | 10,8 + 8,0 + 5,0 |
| Elige justo antes de la señal | 20,0 | **35,8 s** | 10,8 + 20,0 + 5,0 |
| Elige tras la señal completa | 29,0 | **44,8 s** | 10,8 + 29,0 + 5,0 |
| «No responder» a los 8 s | 8,0 | 23,8 s | igual que cualquier opción |

**F4 · Cuenta de la señal.** `t_señal_inicio = t_opc_visible + t_espera`; sonido hasta `+ T_breath`; `VO_G_14_*` hasta `+ T_breath + L14` ≈ 29,0 s tras aparecer las opciones. Se dispara como máximo una vez (regla 14).

**F5 · Suma frente al presupuesto.** Las cinco ramas (A–D, y D por no responder = misma duración) duran **igual** salvo por `L13`. Rango práctico 16,4–44,8 s = 0,27–0,75 min†; la estimación de 9 para la llamada (0,4–1,0 min†, GDD 9, tiempos) la contiene salvo en la franja baja (elección en menos de ≈7 s†), por 8 s. Con la lectura (b) de F1 se sumarían 4,0 s (20,4–48,8 s) y seguiría dentro. El resto de la escena 7 (sillas 1,0–4,0; tecleo 4,5; 60 s del timbre) es de 21 y no se suma aquí. C.7 no fija `L13`; el valor real lo da el audio y la suma se recalcula en el playtest.

## Edge Cases

*Cierre del juego (5, reglas 10 a 12, 28 y 29)*

- **If se cierra con `caja_completa` ∧ ¬`llamada_iniciada` (antes de descolgar):** no hay sellado; al continuar, 21 aplica apagón reducido y `ESC7_TIMBRE`; la llamada empieza como la primera vez (regla 28).
- **If se cierra durante `DESCOLGANDO` a `ANTES_OPCIONES`, `OPCIONES`, `SENAL`, `RESPUESTA` o `CIERRE`:** el fichero tiene `llamada_iniciada` verdadero (regla 3); se reanuda en el despacho con `V02` `vibrando` y la llamada se repite entera (regla 30). La respuesta ya elegida se descarta; el jugador puede elegir otra.
- **If la escritura del sellado falla y el jugador sigue la llamada:** 22 no lo sabe ni cambia; 5 reintenta con el contenido capturado (5, regla 11.2). Si cierra, vale el caso «antes de descolgar».
- **If el jugador completa la llamada y cierra antes de llegar a Recepción** (o falla la carga de `recepcion`, 4 regla 14): vuelve a vivir la llamada (consecuencia aceptada, regla 29); no es softlock.
- **If se continúa una partida con `llamada_completada` verdadero** (consola de desarrollo): `V02` no es descolgable (regla 2), 21 aplica `ESC7_RESTAURAR` sin retardo y `C08` está activo.

*Pausa y ventana*

- **If se abre el menú de pausa en cualquier estado:** todo se congela, incluida la cuenta de 20 s (regla 26); al cerrarlo, sigue donde estaba, con el foco donde estaba.
- **If se pausa justo cuando aparecen las opciones o cuando termina `t_guarda`:** el contador de guarda y el de espera siguen el tiempo de juego; no hay pulsación perdida ni elegida por la pausa.
- **If el juego pierde el foco de ventana:** lo decide 25/1; 22 no tiene lógica propia y se comporta como en la pausa si el juego se detiene.

*Elección*

- **If el jugador no responde nunca:** la llamada espera sin límite; la señal suena una vez a los 20 s†; no hay elección automática ni se repite la señal (regla 14).
- **If el jugador elige durante `SENAL`:** 23 interrumpe el sonido o la línea (≤ 0,3 s† ‡) y sigue la respuesta (regla 15). Si 23 no soporta interrumpir, la respuesta espera a «línea terminada» como máximo `T_breath + L14` (9,0 s); no se pierde la elección.
- **If dos entradas de elección llegan en el mismo fotograma** (clic y `ui_aceptar`): gana la primera por orden de Entrada; la segunda llega con la máquina ya en `RESPUESTA` y se ignora.
- **If el jugador pulsa dentro de `t_guarda`:** se ignora y no se encola (regla 9).
- **If el jugador intenta «repetir la elección»** (volver a las opciones tras elegir): no existe; las opciones no vuelven. Tras una reanudación sí puede elegir otra (cierre durante la llamada).
- **If `ui_atrás`/`atrás` en `llamada`:** no hace nada; no hay colgar. Es deliberado (regla 10).
- **If cambia el dispositivo (ratón ↔ mando) durante las opciones:** el foco/cursor sigue las reglas de 1; el foco previo se conserva.
- **If `respuesta_llamada` ya está fijada al elegir** (solo consola): regla 17.

*Descolgar y entorno*

- **If «Descolgar» se pulsa dos veces seguidas:** la segunda no existe (`V02` ya `en_llamada`, regla 2).
- **If `V02` empieza a vibrar con el ordenador `V01`, una lectura o una inspección abiertos:** suena igual; «Descolgar» no está disponible hasta volver a `exploración` (`interactuar` solo existe en `exploración`: 1, regla 5). 22 y 21 no cierran modos; la llamada nunca empieza con un modo abierto.
- **If el apagón sigue en curso** (sillas, tecleo, luz C03 apagada): la llamada transcurre dentro del apagón; las luces vuelven por `llamada_completada` (21). En la reanudación no se repiten las sillas ni el tecleo (apagón reducido, 21 regla 14).
- **If el jugador sale de D y no vuelve al despacho:** el teléfono suena desde el pasillo a los 60 s† (21) y espera; `C08` no responde con `MEGA_03` (8). Sin penalización.
- **If `V02` no pasa a `vibrando`** (error de 21): no hay llamada; con `caja_completa`, 21 vuelve a poner `vibrando` al cruzar `T-OFI-IN` (21, regla 14); 22 no corrige.
- **If `1` rechaza el contexto `llamada`** (otro contexto ya abierto): 22 queda `INACTIVA`, `V02` vuelve a `vibrando` y el hecho `llamada_iniciada` permanece verdadero (consistente con la regla 27); se registra.

*Audio y datos*

- **If una línea llega como «línea sin audio» o «línea fallida»** (voz ausente o fallo de 23): la llamada continúa; 22 espera `fallback_s` de la línea para que 26 muestre su subtítulo (regla 25). Una llamada entera sin voz sigue siendo jugable.
- **If «línea terminada» no llega** (23 perdido): a los `fallback_s` + `line_grace_s` (2,0†, como 9) 22 sigue; no hay softlock.
- **If `carta_variante` está sin fijar** (solo consola): 22 omite `VO_G_12*`, conserva la espera de `t_ante` y registra una advertencia; no inventa una variante (que cada letra tiene sentido emocional propio).
- **If `t4_decision` está sin fijar:** `VO_G_14_RET` (regla 16).
- **If `reducir_sobresaltos` está activo:** 23 atenúa `SFX_BREATH_BROKEN` y el golpe de `SFX_PHONE_BUZZ`; 22 no cambia ni el contenido ni los tiempos (ajustes 6, catálogo).

## Dependencies

*Tipo declarado por el dependiente (la fila dice quién declara). Índice de sistemas, fila 22: duras 1, 3, 5, 7, 18; blanda 2.*

| Sistema | Tipo | Quién declara | 22 recibe / usa | 22 da / pide | Referencia en el otro GDD |
|---|---|---|---|---|---|
| 1 Entrada y controles | Dura | 22 (sin contexto `llamada` no hay opciones). 1 la anota **Blanda** en su tabla (cambio nº 8) | Contexto `llamada`, `ui_*`, cursor, `seleccionar`, `pausa` | Petición de entrar y salir de `llamada` (regla 6 de 1); petición de mostrar/ocultar el cursor | 1, regla 6 y tabla de contextos |
| 2 Jugador en primera persona | Blanda | 22 | Fin de los gestos `ANIM_PHONE_PICKUP`, `HAND_PHONE_PUTDOWN`; `reposo()` | Petición de `HAND_PHONE_PUTDOWN`; `HAND_PHONE_HOLD` (bucle) lo mantiene 2 | 2, catálogo de gestos (`HAND_PHONE_*`) y estado «Congelado» |
| 3 Estado y bus de eventos | Dura | 22 | Lectura de `carta_variante`, `t4_decision`, `caja_completa`, `llamada_completada`, `llamada_iniciada`; respuestas de 23 | Escritura de `llamada_iniciada`, `respuesta_llamada`, `llamada_completada`; avisos «llamada iniciada», «llamada completada» y «línea pedida» | 3, regla 4 (un solo sentido), tabla de hechos y de avisos (fila 22) |
| 5 Guardado y carga | Dura (contrato) | 22 y 5 (5 la declara en su fila 22) | Sellado por «llamada iniciada»; restauración de `llamada_iniciada` ∧ ¬`llamada_completada` | Fijar `llamada_iniciada` en el descolgar; repetir entera la llamada; no depender de que se guarde otra cosa | 5, reglas 10, 11, 12, 28 y 29; AC-34 |
| 7 Interacción e inspección | Dura | 22 | `V02`, verbo «Descolgar» (`DELEGAR`), `can_interact`/`interact` de 22, `ANIM_PHONE_PICKUP` pedida antes de `interact()` | Manejador de `V02` | 7, catálogo (`V02`) y regla 3 |
| 18 Base de contenido narrativo | Dura | 22 (18 la declara dura en su fila 22) | `VO_G_12A–C`, `VO_G_13A–D`, `VO_G_14_RET/ASG`, textos de las cuatro opciones, `fallback_s`, `SUB_BREATH_BROKEN` | Petición de claves por ID; sin modificar textos | 18, reglas 5, 16 y 22; D18-10 |
| 21 Director de escenas | Sin dependencia directa (por el bus). 22 respeta el límite de 21 | 21 | `V02` en `vibrando`; apagón activo; reanudación sin sillas ni tecleo | Hecho `llamada_completada` (21 reacciona con `ESC7_RESTAURAR`); `V02` `vibrando` solo en reanudación con `llamada_iniciada`; ninguna orden a 21 | 21, reglas 4, 14, 15 y 17; fila 22 |
| 8 Control de acceso | Blanda (la declara 8 en el índice) | 8 | Nada | `llamada_completada` (8 activa `C08` a `t_ascensor_s`) | 8, regla 13 |
| 9 Marco de puzles | Indirecta (por el bus) | 22 | `carta_variante` (la escribe P6), `t4_decision` (la escribe P4) | Ninguna; 9 estima la duración de la llamada | 9, tiempos (llamada), regla 20 |
| 4 Escena de planta | Sin dependencia directa | 22 | Nada | `llamada_completada` es la precondición de `recepcion` | 4, regla 13 |
| 23 Director de audio ‡ | Blanda | 22 | «línea terminada» / «línea sin audio» / «línea fallida»; reproducción y mezcla | «línea pedida» (VO y `SFX_*`); «sonido de llamada pedido» ‡ (parar `SFX_PHONE_BUZZ`, `SFX_BREATH_BROKEN`, `SFX_PHONE_END`, `SFX_CALL_BREATH`); interrumpir ‡ | 3, tabla de avisos (23); sin GDD |
| 26 Subtítulos ‡ | Blanda | 22 | Muestra el subtítulo de las líneas y de `SUB_BREATH_BROKEN` | Nada directo (lo pide 23/18) | 18, regla 22; sin GDD |
| 6 Ajustes persistentes | Sin dependencia directa | 22 | Nada (23 lee `reducir_sobresaltos`, 6 catálogo) | — | 6, catálogo |

**Ciclos:** 22 no depende de 21 ni 21 de 22 (21 regla 15); 22 → 5 → 3 es lineal. 22 ↔ 7 es dura circular aceptable (7 delega en 22 el verbo; 22 usa el catálogo de 7), sin ciclo de construcción.

## Tuning Knobs

Todos los valores en datos externos (`call.json` propuesto ‡), no en código.

| Knob | Valor | Rango seguro | Afecta a |
|---|---|---|---|
| `t_sil_s` † | 2,0 | 1,0–4,0 | Peso del silencio inicial; por debajo de 1,0 la llamada deja de sentirse íntima, por encima de 4,0 parece un fallo |
| `t_resp_s` † | 2,0 | 1,0–4,0 | Idem, la respiración |
| `t_ante_s` † | 1,0 | 0,5–2,0 | Pausa entre la línea de variante y las opciones |
| `t_guarda_opciones_s` † | 0,6 | 0–1,0 | Protección contra pulsaciones accidentales; 0 la desactiva |
| `t_espera_s` † | 20,0 (slice C.7, D-15) | 10–40 | Cuándo suena la señal del llanto; no decide por el jugador |
| `t_cierre_s` † | 1,0 | 0,5–2,0 | Silencio entre la respuesta y el fin de la llamada |
| `t_corte_senal_s` † ‡ | 0,3 | 0,1–0,6 | Cuánto tarda 23 en cortar la señal al elegir |
| `line_grace_s` † | 2,0 (el de 9, regla 20) | 1,0–4,0 | Margen antes de dar por perdida una «línea terminada» |
| `fallback_s` por línea † | de 18 | 1,5–8 | Tiempo del subtítulo si falla el audio |
| `t_putdown_s` † | ≤0,6 | 0,3–0,8 | Se pide a 2; si 2 lo rechaza, 22 espera este valor |
| `orden_opciones` | A, B, C, D (fijo) | no es un knob | Deliberadamente sin aleatorizar |

No existen knobs que cambien el contenido de las respuestas, ni medidores, ni dificultad: no hay nada que ganar ni perder.

## Acceptance Criteria

Tipos: L = lógica (automática), I = integración, PV = playtest o verificación visual/sonora.

- **AC-22-01 (R1, R2, L):** **GIVEN** `V02` en `reposo`, `vibrando` y `en_llamada`, con `caja_completa` verdadero/falso y `llamada_completada` verdadero/falso, **WHEN** se evalúa `can_interact(Descolgar)`, **THEN** solo es verdadero con `vibrando` ∧ `caja_completa` ∧ ¬`llamada_completada` ∧ máquina `INACTIVA`.
- **AC-22-02 (R3, L):** **GIVEN** `llamada_iniciada` falso, **WHEN** se ejecuta `interact(Descolgar)`, **THEN** en el mismo fotograma, por este orden: `llamada_iniciada` = verdadero, aviso «llamada iniciada», petición de contexto `llamada`; ninguna línea ni sonido de la llamada se ha pedido antes.
- **AC-22-03 (R3, R30, I):** **GIVEN** una partida restaurada con `llamada_iniciada` verdadero, **WHEN** el jugador descuelga, **THEN** no se escribe ni se emite «llamada iniciada» por segunda vez y la llamada empieza en `DESCOLGANDO`.
- **AC-22-04 (F1, F2, L):** **GIVEN** reloj falso y duraciones `L12` = 5,0 s, **WHEN** se descuelga, **THEN** `VO_G_12*` se pide a t = 4,8 s (±0,05) y las opciones aparecen a t = 10,8 s (±0,05).
- **AC-22-05 (R7, L):** **GIVEN** `carta_variante` = A, B o C, **WHEN** llega `LINEA`, **THEN** se pide exactamente `VO_G_12A`, `VO_G_12B` o `VO_G_12C` respectivamente.
- **AC-22-06 (R9, L):** **WHEN** aparecen las opciones, **THEN** son exactamente cuatro, en el orden A, B, C, D, sin foco inicial, con el mismo aspecto (comparación de captura: mismo color, tamaño, icono y estilo).
- **AC-22-07 (R9, L):** **GIVEN** opciones recién aparecidas, **WHEN** llega una selección antes de 0,6 s, **THEN** se ignora y no se encola; **WHEN** llega a 0,6 s o más, **THEN** se acepta.
- **AC-22-08 (R10, I):** **WHEN** se mueve el foco con `ui_arriba`/`ui_abajo` o el cursor sobre una opción, **THEN** no se escribe `respuesta_llamada`; **WHEN** llega `ui_atrás` o `atrás`, **THEN** no cambia nada; con el mando, el stick izquierdo no mueve el cursor.
- **AC-22-09 (R11, L):** **GIVEN** una opción elegida, **WHEN** llega otra selección en el mismo fotograma o después, **THEN** se ignora y `respuesta_llamada` conserva el primer valor.
- **AC-22-10 (R14, L):** **GIVEN** opciones visibles sin elección, **WHEN** pasan 20,0 s de tiempo de juego, **THEN** suena `SFX_BREATH_BROKEN` y, al terminar, se pide `VO_G_14_RET` (`t4_decision` = `returned`) o `VO_G_14_ASG` (`assigned`); las opciones siguen visibles; `respuesta_llamada` sigue sin fijar; **WHEN** pasan otros 120 s, **THEN** no se repite la señal ni se elige nada.
- **AC-22-11 (R13, R26, I):** **GIVEN** 12 s de espera, **WHEN** se abre y cierra el menú de pausa 30 s después, **THEN** la señal suena 8 s de juego más tarde, no antes.
- **AC-22-12 (R15, I):** **GIVEN** la señal en curso, **WHEN** el jugador elige, **THEN** la señal se interrumpe en ≤ 0,3 s†, `respuesta_llamada` se escribe y se pide `VO_G_13x`; **GIVEN** que 23 no soporta interrumpir, **THEN** la respuesta empieza como mucho 9,0 s después y no se pierde la elección.
- **AC-22-13 (R17, R18, L):** **GIVEN** cada opción A, B, C y D, **WHEN** se elige, **THEN** `respuesta_llamada` toma A, B, C o D y se pide `VO_G_13A`, `VO_G_13B`, `VO_G_13C` o `VO_G_13D`; el texto de `VO_G_13B` en 18 es «Lo sé» y no contiene «Por eso lo pedí».
- **AC-22-14 (R12, L):** **GIVEN** opciones visibles, **WHEN** el jugador elige «No responder», **THEN** `respuesta_llamada` = D y se pide `VO_G_13D`; **GIVEN** que no elige nada durante la señal y después, **THEN** `respuesta_llamada` sigue sin fijar.
- **AC-22-15 (R19, L):** **GIVEN** `VO_G_13x` terminada, **WHEN** pasa `t_cierre_s`, **THEN** por este orden se pide `SFX_PHONE_END`, `llamada_completada` = verdadero, aviso «llamada completada» y `HAND_PHONE_PUTDOWN`; el contexto `llamada` se libera al terminar el gesto (≤ 0,6 s†); `llamada_completada` se escribe exactamente una vez.
- **AC-22-16 (R21, L):** **GIVEN** una llamada completa, **THEN** los únicos escritores de `llamada_iniciada`, `respuesta_llamada` y `llamada_completada` son 22 (registro de escrituras) y ninguna otra escritura o aviso de 22 existe.
- **AC-22-17 (R27, 5 AC-14, I):** **GIVEN** un cierre en cualquier estado entre `DESCOLGANDO` y `CIERRE`, **WHEN** se continúa, **THEN** `V02` vibra, `respuesta_llamada` y `llamada_completada` están sin fijar en el fichero, y la llamada puede elegirse de nuevo hasta Recepción (cumple AC-34 de 5).
- **AC-22-18 (R30, I):** **GIVEN** una reanudación con `llamada_iniciada` verdadero, **THEN** al volver `exploración` `V02` está `vibrando`, el apagón reducido no repite sillas ni tecleo, y la llamada repetida es idéntica en tiempos y líneas.
- **AC-22-19 (R25, L):** **GIVEN** «línea sin audio», «línea fallida» o ninguna respuesta de 23, **WHEN** pasan `fallback_s` (o `fallback_s` + `line_grace_s` en el último caso), **THEN** la máquina avanza; la llamada llega a `COMPLETADA` sin voz alguna.
- **AC-22-20 (Edge, L):** **GIVEN** `carta_variante` sin fijar, **THEN** no se pide `VO_G_12*`, la máquina avanza y el log contiene una advertencia; **GIVEN** `t4_decision` sin fijar al cumplirse los 20 s, **THEN** se pide `VO_G_14_RET`.
- **AC-22-21 (Edge, I):** **GIVEN** `V02` `vibrando` y el ordenador `V01` abierto, **WHEN** el jugador intenta descolgar, **THEN** no hay llamada ni cierre forzado; al volver a `exploración`, «Descolgar» está disponible.
- **AC-22-22 (R31, I):** **GIVEN** una partida que llega a `caja_completa`, **WHEN** se juega la llamada en las cuatro ramas (A, B, C, D) y en la rama de no responder durante 60 s, **THEN** cada una llega a `llamada_completada`, `C08` se activa a `t_ascensor_s` y se alcanza Recepción sin bloqueo.
- **AC-22-23 (F3, PV):** **GIVEN** las duraciones reales de audio, **THEN** `T_compl` medido con elección inmediata y con elección tras 8 s está a ±1 s de la tabla F3; el resultado se anota en el informe de playtest.
- **AC-22-24 (R22, PV):** Captura retenida de las opciones: el cursor no es un círculo, está oculto hasta `OPCIONES` y las cuatro opciones son indistinguibles en estilo.
- **AC-22-25 (R20, PV):** **GIVEN** subtítulos activos, **WHEN** suena `SFX_BREATH_BROKEN`, **THEN** se muestra `SUB_BREATH_BROKEN` mientras dura el sonido.
- **AC-22-26 (pilares, PV):** En el playtest, ningún participante identifica una opción como «la correcta» o «la mala» tras jugar; se registra qué opción eligió, por qué y si volvería a elegir otra (sin medidor).

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D22-1 | La línea de variante empieza a 4,8 s del pulso: animación (0,8) + silencio (2,0) + respiración (2,0). La fila «+4,0» de C.7 se lee como silencio + respiración. | Línea a +4,0 solapando la animación; o +4,0 adicional tras silencio y respiración (8,8 s, la lectura de 9). | La lectura secuencial respeta cada duración nombrada en C.7 y no inventa una espera sin nombre; la diferencia es ≤ 4 s. Se marca en Open Questions nº 1. |
| D22-2 | 22 emite «línea pedida» para `VO_G_12*`, `VO_G_13*` y `VO_G_14_*`. | Que 21 reproduzca `VO_G_14_*`. | 21 regla 15 prohíbe que el director lea el contenido de la llamada; 18 (regla 5) ya dice que quien consume `VO_G_14` es 22. |
| D22-3 | `llamada_iniciada` se escribe y se emite al pulsar «Descolgar» (el punto más temprano). | Sellar al aparecer la primera línea o las opciones. | 5 (regla 12) exige sellar «como máximo al descolgar»; sellar al pulsar elimina el estado «descolgado pero no sellado», que sería irreproducible desde los hechos. |
| D22-4 | La elección es inmediata y definitiva: sin paso de confirmación ni «volver a elegir». | Selección + confirmar, con posibilidad de repetir. | El slice (§11.1, D.2) reproduce la línea al elegir; D.2 no prevé repetición; `respuesta_llamada` es de un solo sentido (3 regla 4). Un paso de confirmación añadiría una pregunta («¿seguro?») que cambia el tono. La protección es `t_guarda_opciones_s` (D22-5). |
| D22-5 | Las pulsaciones se ignoran durante 0,6 s† tras aparecer las opciones (no se encolan). | Ninguna guarda; o guarda que bloquea la cuenta de 20 s. | Evita que el pulso que descolgó o una repetición elija sin querer una respuesta definitiva; es invisible para el jugador atento. |
| D22-6 | Los 20 s cuentan desde que aparecen las opciones (incluida la guarda). | Contar desde que termina la guarda. | Es el valor literal de C.7; la guarda no altera el tono de la espera. |
| D22-7 | La señal (`SFX_BREATH_BROKEN` y luego `VO_G_14_*`) ocurre una sola vez y en ese orden. | Simultáneos; o repetir la señal cada 20 s. | C.7 y 9 los suman en secuencia; repetirla sería un temporizador que presiona (pilar *Tensión sin castigo*). |
| D22-8 | Elegir durante la señal la interrumpe (≤ 0,3 s† ‡). | Ignorar la elección hasta que termine la señal. | Una pulsación perdida es un castigo; el slice dice que las opciones «siguen visibles», no que se bloqueen. Open Questions nº 6 (efecto sonoro del corte). |
| D22-9 | No hay colgar manual: `ui_atrás` y `atrás` no hacen nada en `llamada`. | `atrás` equivale a «No responder» o cuelga sin respuesta. | Colgar sin respuesta dejaría `respuesta_llamada` sin valor y obligaría a `VO_V_12*` sin variante; «No responder» ya es la salida y tiene su línea (`D`). |
| D22-10 | El cursor está oculto hasta `OPCIONES`. | Cursor visible durante todo `llamada` (1 hoy). | Un cursor flotando durante el silencio contradice el pilar 2 (el espacio expresa la emoción). Cambio requerido en 1. |
| D22-11 | Las opciones se muestran siempre en el orden A, B, C, D, con idéntico aspecto y sin foco inicial. | Aleatorizar; destacar «No responder»; foco inicial en A. | Pilar 1: ninguna es la correcta; la posición fija permite que 18 y las pruebas la referencien. |
| D22-12 | Con `carta_variante` sin fijar, 22 omite `VO_G_12*` y avisa. | Usar una variante por defecto. | Ninguna variante es neutra (cada una cita lo que Vera escribió); inventar sería escribir contenido. Solo ocurre por consola. |
| D22-13 | Con `t4_decision` sin fijar, `VO_G_14_RET`. | Omitir la línea. | `VO_G_14_RET` es la `VO_G_14` original sin cambios (18). |
| D22-14 | 22 no cierra modos (el ordenador, la lectura): la llamada no puede empezar con un modo abierto porque 7 solo activa objetos en `exploración`. | Que 22 pida `cerrar_modos()` al descolgar. | Ya está resuelto por 7 y 21 (reglas 13 y 20 de 21): dos dueños para lo mismo. |
| D22-15 | En la reanudación 22 pone `V02` en `vibrando` y la llamada repetida es idéntica. | Atajo («ya hablamos»); o variación de la primera línea. | Un atajo cambiaría el tono y la repetición sería un hecho narrativo («otra vez»); 5 (regla 12) pide repetirla desde su principio. |
| D22-16 | `llamada_completada` se escribe en `SFX_PHONE_END`, antes de terminar `HAND_PHONE_PUTDOWN`; el contexto se libera cuando termina el gesto. | Escribir el hecho tras el gesto. | Es el orden de C.7 (+1,0 tras la respuesta: `SFX_PHONE_END` y `llamada_completada`); el gesto (≤ 0,6 s†) termina antes de `C08` (2,0 s). |
| D22-17 | En la reanudación 22 no reescribe `llamada_iniciada` ni repite el aviso. | Repetir el aviso. | 3 y 5 (AC-18) lo ignorarían; evita un segundo sellado. |
| D22-18 | Se propone `SUB_BREATH_BROKEN` con texto provisional «[Llanto contenido]» y marcador de pendiente. | No subtitular el sonido. | 18 (regla 22) lo exige para sonidos sin palabras necesarios; el texto final es del writer. |
| D22-19 | `reducir_sobresaltos` lo gestiona 23; 22 no lo lee. | Que 22 acorte la señal. | La llamada no tiene sustos; 22 no debe cambiar tiempos ni contenido por un ajuste (ajustes 6, catálogo). |
| D22-20 | La respiración inicial no lleva subtítulo. | Subtitularla. | Es ambiente sin información necesaria. Open Questions nº 4. |

## Open Questions

| Nº | Pregunta | Quién decide | Efecto |
|---|---|---|---|
| 1 | **Tiempos de C.7:** ¿La fila «+4,0» de C.7 (línea de variante) es silencio + respiración (adoptado, línea a 4,8 s), solapa la animación (4,0 s) o se suma a ellos (8,8 s, la estimación de 9)? | Autor del slice | Cambia la línea de variante en ≤ 4,0 s; no cambia ninguna regla. |
| 2 | **Texto y hablante de `VO_G_14_ASG`** («Sigo aquí. La carta a Dirección ya va firmada.»): es propuesta de 18 (D-B1) y no se ha cambiado aquí. ¿Es del Guardián? ¿Confirma la intención («ya va firmada» afirma un hecho de P4, no una intención)? | Narrative-director con el usuario | Tono: un cambio de texto no corresponde a este GDD. |
| 3 | **¿Confirmación o repetición de la elección?** (slice D-15 sigue «Pendiente: confirmar»). Recomendación: no, con la guarda de 0,6 s† (D22-4, D22-5). La alternativa es una confirmación explícita o un «volver atrás» antes de que suene `VO_G_13*`. | Usuario | Toca el tono (¿la elección debe poder retractarse?) y el pilar 3. |
| 4 | **Subtítulo de la respiración inicial** (accesibilidad): ¿se subtitula `SFX_CALL_BREATH`? Recomendación: no. | Usuario / UX | Accesibilidad; no cambia reglas. |
| 5 | **Texto de `SUB_BREATH_BROKEN`** («[Llanto contenido]» provisional): ¿literal o más sobrio, p. ej. «[Respiración entrecortada]»? El slice dice «llanto contenido» (nombre del evento). | Writer / narrative-director | Tono del subtítulo. |
| 6 | **Interrumpir al Guardián:** cortar `VO_G_14_*` o el llanto a mitad cuando el jugador elige, ¿con corte seco o fundido? Contradice un poco «silencios largos» (pilar 2). | audio-director | Realización; la regla de elegir sin esperar no cambia. |
| 7 | **Repetir la llamada con la respuesta ya dada** (cierre antes de Recepción, 5 regla 11): el jugador puede cambiar de respuesta. Aceptado por 5 (D-4); ¿se acepta también como lectura narrativa (no hay «primera vez» canónica)? | Usuario | Pilar 5 (hechos fijos): `respuesta_llamada` no es un hecho observable, es una elección. |
| 8 | **Voz del Guardián en la llamada** (convertida o no, D-08 del slice) no la decide este GDD; afecta a la intimidad de la escena. | audio-director / usuario | Audio. |
| 9 | **¿La llamada puede dejar `V02` sonando indefinidamente?** Hoy `SFX_PHONE_BUZZ` en bucle hasta que el jugador descuelga (21). ¿Debe atenuarse con el tiempo? | audio-director | Fatiga sonora; no cambia reglas. |

## Cambios requeridos en otros GDDs

(Ninguno se ha aplicado: este GDD no edita archivos existentes.)

1. **3 Estado y bus de eventos:** (a) tabla de avisos, fila 22: añadir «línea pedida» (con los IDs `VO_G_12*`, `VO_G_13*`, `VO_G_14_*`) y, ‡, «sonido de llamada pedido»; (b) confirmar el aviso «llamada iniciada» solo en la primera descolgada (regla 3 de este GDD).
2. **1 Entrada y controles:** (a) contexto `llamada`: cursor oculto hasta `OPCIONES` (D22-10); (b) `ui_atrás`/`atrás` sin efecto en `llamada`; (c) su fila 22 dice «Blanda»; 22 la declara **Dura**; reconciliar; (d) AC para el cursor no circular.
3. **9 Marco de puzles:** (a) tiempos: la llamada hasta las opciones es 10,8 s (F2), no 14,8 s; rango 0,27–0,75 min†; (b) añadir fila 22 en Dependencies (lee `carta_variante` y `t4_decision`, indirecta).
4. **18 Base de contenido:** claves `UI_LLAMADA_OPCION_A–D` (o las vigentes), `SUB_BREATH_BROKEN` (texto provisional), `fallback_s` de `VO_G_12*`, `VO_G_13*`, `VO_G_14_*`; cerrar Pendientes 10 (propuesta de 22: sin cambio de texto, Open Questions nº 2) y 11.
5. **7 Interacción e inspección:** catálogo, `V02`: estados `vibrando`/`en_llamada`; `can_interact` de «Descolgar» lo evalúa 22 (regla 2).
6. **21 Director de escenas:** regla 15: `V02` pasa a `vibrando` también por 22 en la reanudación con `llamada_iniciada` (regla 30 de este GDD); fila 22 de Dependencies: ahora existe el GDD.
7. **5 Guardado y carga:** AC-34 deja de ser NOT ASSESSED (cerrar con el sistema 22); Pendiente nº 4 cerrado.
8. **2 Jugador:** `HAND_PHONE_HOLD` empieza al terminar `ANIM_PHONE_PICKUP`; `HAND_PHONE_PUTDOWN` lo pide 22 en `SFX_PHONE_END`.
9. **systems-index.md:** fila 22: «Borrador (lote Feature 2)», ruta `design/gdd/llamada-telefonica.md`, dependencias (duras 1, 3, 5, 7, 18; blandas 2, 23, 26).
10. **Slice (v0.4.1, decisión del usuario):** aclarar C.7 «+4,0» (Open Questions nº 1) y que `llamada_iniciada` se escribe al pulsar «Descolgar»; confirmar D-15.
11. **23 y 26 (sin GDD):** contratos ‡ de la regla 25: respuesta a «línea pedida», interrupción en ≤ 0,3 s†, «sonido de llamada pedido», subtítulos de `SUB_BREATH_BROKEN`.

## Entradas para el registro

- **Hechos (ya existen):** `llamada_iniciada`, `respuesta_llamada`, `llamada_completada`; dueño 22; sin hechos nuevos.
- **Avisos:** «llamada iniciada» (22 → 3, 5), «llamada completada» (22 → 8, 21, 4), «línea pedida» (también 22), «sonido de llamada pedido» ‡ (22 → 23).
- **Estados de `V02`:** `reposo`, `vibrando` (21; 22 en reanudación), `en_llamada` (22).
- **Contexto de entrada:** `llamada` (22 abre y cierra).
- **IDs propuestos:** `SFX_CALL_BREATH` ‡, `SUB_BREATH_BROKEN` (texto provisional), `UI_LLAMADA_OPCION_A–D` ‡. Existentes usados: `V02`, `VO_G_12A/B/C`, `VO_G_13A–D`, `VO_G_14_RET/ASG`, `SFX_PHONE_BUZZ`, `SFX_BREATH_BROKEN`, `SFX_PHONE_END`, `ANIM_PHONE_PICKUP`, `HAND_PHONE_HOLD`, `HAND_PHONE_PUTDOWN`, `VO_V_12A–D` (consumidas por 21).
- **Constantes †:** `t_sil_s` 2,0, `t_resp_s` 2,0, `t_ante_s` 1,0, `t_guarda_opciones_s` 0,6, `t_espera_s` 20,0, `t_cierre_s` 1,0, `t_corte_senal_s` 0,3, `line_grace_s` 2,0 (de 9), `t_putdown_s` ≤0,6.
- **Datos:** `call.json` ‡ (tiempos y claves). **Estados de 22:** `INACTIVA`, `DESCOLGANDO`, `SILENCIO`, `RESPIRACION`, `LINEA`, `ANTES_OPCIONES`, `OPCIONES` (`ESPERA`, `SENAL`), `RESPUESTA`, `CIERRE`, `COMPLETADA`.

## Historial

- 2026-11-09 — Borrador completo (lote Feature 2): 32 reglas, 5 fórmulas, 26 AC, 20 decisiones, 9 preguntas abiertas, 11 cambios requeridos. Pendiente de review independiente.
