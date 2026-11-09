# Prompt de interacción y feedback (sistema 24)

> **Status**: Borrador (lote autónomo)
> **Author**: UX Designer (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el prompt no revela lo que aún no está disponible) · Tensión sin castigo (el rechazo es un susurro, nunca un error) · Información incompleta (el pie es ambiente, no pista) · El espacio expresa la emoción (overlay mínimo, sin luz propia)

> `†` = valor propuesto, a validar en playtest. `‡` = elemento propuesto que aún no existe en otros GDDs (ver «Cambios requeridos»). Los identificadores de código van en inglés; los IDs del slice (`V06`, `OBJ_C06`, `UI_BOLSILLO_AYUDA`…) se conservan tal cual.

## Summary

24 es la **capa de overlay de la exploración**: dibuja el anillo de interacción sobre el objetivo que 7 reporta (con su progreso para `leer`), la etiqueta de acción opcional con el glifo del dispositivo activo, el feedback visual de rechazo («sin efecto») y el **pie de texto** no bloqueante (textos de objeto `OBJ_<id>` y el pie `UI_BOLSILLO_AYUDA` de 20). No decide nada de juego: consulta `get_target()` de 7 cada fotograma, resuelve glifos con Entrada (1) y textos con 18, y no escribe hechos.

## Overview

Una sola tecla o botón contextual (slice §5) exige que el jugador sepa, sin menús, **cuándo** puede actuar, **qué** hará y **qué ha pasado** tras pulsar. 24 resuelve las tres cosas con tres piezas: (1) el **anillo con punto** (art bible §3.3 y §7.3) en el centro de la pantalla, que solo existe sobre objetivos válidos; (2) la **etiqueta** («Abrir», «Leer»…) con el glifo del botón vigente, apagada por defecto y activable en accesibilidad; (3) el **pie** abajo-centro, un texto breve que se sustituye o expira. El rechazo («sin efecto», gesto rechazado, toque corto sobre `leer`) se comunica con un pulso del anillo más el `SFX_CLICK_SUBTLE` que emite 7, y con el pie `OBJ_<id>` cuando el objeto lo tiene: nunca con rojo, temblor ni mensaje de error. Ninguna pieza se apoya solo en el color (todo es blanco frío sobre fondo oscuro; la información viaja por forma, texto, posición y sonido). 24 no tiene estado persistente.

## Player Fantasy

Mirar es elegir (art bible, principio 3): el anillo aparece cuando algo «responde» a la mirada de Vera y se disuelve cuando deja de hacerlo. El juego nunca grita ni regaña; cuando algo no cede, el mundo contesta con un clic discreto y, a veces, con una frase breve que suena a pensamiento, no a instrucción. El jugador siente que *él* descubre qué es interactuable, y que una pulsación de más no cuesta nada.

## Detailed Rules

### A. Anillo de interacción

1. **Fuente única.** 24 consulta `get_target()` de 7 **en cada fotograma de render** (7, regla 29: no hay aviso de cambio de objetivo). Entrada esperada: `{id, etiqueta (clave ya resuelta), largo (bool), p (0 a 1), anillo_visible (bool) ‡} | nulo`. 24 **no** recalcula el objetivo, el verbo ni `p`.
2. **Cuándo se dibuja.** Solo con el contexto de Entrada en `exploración` y `get_target() ≠ nulo`. En cualquier otro contexto (`menú`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada`, `sin control`) el anillo y la etiqueta están ocultos (el cursor de las vistas no es del 24, 7/Entrada). **No hay punto de mira permanente** (art bible §7.3; slice §16): sin objetivo no se dibuja nada.
3. **Posición.** Centro exacto de la pantalla, fijo (el rayo de 7 sale del centro); no se proyecta sobre el objeto ni sigue su silueta. Evita saltos y no compite con la iluminación del mundo.
4. **Forma y tamaño** (art bible §7.3): anillo de 28 px a 1080p, trazo 2 px, punto 4 px, opacidad 80 %, filo plano de 1 px azul noche `#1C2A38`, blanco frío `#DCE6E8`, sin sombra ni halo. **Versión grande** (accesibilidad, art bible §4.5): 48 px, trazo 3 px, punto 8 px, opacidad 100 %, contorno 2 px; se activa con `icono_grande` ‡ (ajuste de 6, pantallas 25/30). Los tamaños escalan con F2.
5. **Aparición y desaparición.** Fundido de opacidad de 250 ms (ease-out) al aparecer y 150 ms al desaparecer (art bible §7.4). Si el objetivo pasa de un objeto a otro sin pasar por nulo, el anillo **no** parpadea: se mantiene y solo cambia la etiqueta (fundido cruzado de 120 ms). Con `reducir_movimiento` ambos fundidos duran 100 ms fijos.
6. **Progreso de `leer`.** Si `anillo_visible` y `largo`, el anillo se rellena en sentido horario desde las 12 h en proporción a `p` (F1). Es un **relleno del propio anillo, no una barra** (art bible §7.3). Al completarse (`p = 1`) el relleno llega a opacidad 100 % y 7 abre la lectura; el anillo se oculta con el cambio de contexto. Si se suelta antes, el relleno se vacía en 100 ms. En el modo «alternar en lugar de mantener» (Entrada R14) el relleno permanece a la vista entre las dos pulsaciones, como exige 7 (edge case de alternar), y se vacía al cancelar con `atrás`.
7. **Pulsación aceptada.** Cuando `interactuar` se procesa con resultado `HECHO`, el anillo sube de 80 % a 100 % de opacidad en 120 ms y vuelve (art bible §7.4); sin escala ni movimiento. Se dispara con el aviso «interacción ejecutada (id, verbo, resultado = HECHO)» de 7.
8. **Estado deshabilitado/`NO`.** No existe feedback: 7 ya retira al objeto del objetivo y `get_target()` es nulo (7, regla 8). 24 no «explica» nunca por qué un objeto no está disponible (pilar Autonomía).
9. **Sin estado «solo punto».** El art bible §7.3 define dos estados («solo punto» y «anillo con punto»); en la exploración del slice solo existe el segundo, porque la regla «sin punto de mira permanente» lo prohíbe. Ver D24-6 y Open Questions.

### B. Etiqueta de acción y glifo

10. **Qué muestra.** Cuando está activa, una línea de texto bajo el anillo (separación 12 px† a 1080p): `[glifo de interactuar] + texto de la clave de etiqueta` (p. ej. `[E] Abrir`, `[A] Leer`). El texto lo pide 24 a 18 con la clave que entrega 7 (`UI_VERBO_*`, ya resuelta por `etiqueta(verbo)` del manejador si la hay: «Encender»/«Apagar» de `V06`; «Imprimir»/«Recoger» de `V08`).
11. **Apagada por defecto.** `etiqueta_accion_visible` ‡ = falso (art bible §7.3: «desactivada por defecto, activable en accesibilidad»). Con ella apagada el anillo es la única señal y se cumple el slice §16 («icono discreto»). Con ella activa se muestra siempre que haya objetivo.
12. **Glifo siempre con texto.** Un glifo **nunca** va solo: lleva la etiqueta textual de la asignación (`E`, `Clic izq.`, `A`, `Cruz`). Teclas = rectángulo de esquinas vivas con el nombre; botón de mando = forma neutra con su letra o símbolo (art bible §7.3). Alto del glifo = alto de línea del texto que lo acompaña. Los glifos se muestran **en línea con la etiqueta, nunca flotando junto al anillo** (art bible §7.3).
13. **Origen del glifo.** Se lee de Entrada: dispositivo activo (regla 3 de 1) y asignación **vigente** de la acción (reasignable, R15 de 1) mediante `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id}` ‡. 24 **nunca** guarda ni supone una tecla concreta. Con dos asignaciones para la acción y el dispositivo, se muestra la primera.
14. **Reactividad.** Al cambiar el dispositivo activo («dispositivo de entrada cambiado», Entrada R3) o la asignación (cierre de la pantalla de reasignación de 25), la etiqueta y los pies con glifo se re-resuelven en el siguiente fotograma, sin reiniciar el reloj de ningún pie. Una única consulta por cambio, no por fotograma.
15. **El glifo es siempre el de `interactuar`** (la pulsación prolongada de `leer` y la segunda pulsación del modo alternar usan la misma asignación; los gestos derivados no se reasignan, R15 de 1). El texto de etiqueta de `leer` («Leer») ya implica mantener; el anillo lo muestra al rellenarse.
16. **Clave ausente.** Si 18 no tiene la clave de etiqueta, la etiqueta no se dibuja (el anillo sí), se registra el error en desarrollo y no se muestra nunca el nombre de la clave al jugador.

### C. Feedback de rechazo y de «sin efecto»

17. **Contrato.** 24 no reproduce audio. El sonido de rechazo (`SFX_CLICK_SUBTLE`) lo emite 7 (regla 11 de 7); 24 aporta la **parte visual** y el pie. Un solo gesto del jugador produce como máximo **un** pulso (7 impone `t_enfriamiento_s` 0,25 s†, así que ≤ 4 pulsos/s: por debajo del umbral de fotosensibilidad de 3 destellos/s solo si se cuenta el pulso como un destello; el pulso es un cambio de opacidad suave de 120 ms sin cambio de luminosidad brusco, F1).
18. **Casos y respuesta.** Todos los casos comparten el **pulso de rechazo**: el anillo baja de 80 % a 40 %† y vuelve en 120 ms (opacidad, sin movimiento; no altera la silueta, así que no depende de `reducir_movimiento`).

    | Caso (origen en 7) | Pulso | Sonido (7) | Pie |
    |---|---|---|---|
    | `SIN_EFECTO` del manejador (lector sin tarjeta `C06`/`C07`/`D06`, ascensor inactivo `C08`, compartimento bloqueado, puzle resuelto, impresora sin resultados…) | Sí | `SFX_CLICK_SUBTLE` | `OBJ_<id>` si el catálogo tiene `texto` (regla 3 de 7) |
    | Gesto rechazado por el Jugador (otro gesto bloqueante en curso) | Sí | `SFX_CLICK_SUBTLE` | No (7 no muestra `texto`) |
    | Toque corto sobre un objeto solo `leer` | Sí (el anillo pulsa una vez; 7, regla 9) | `SFX_CLICK_SUBTLE` | No |
    | Pulsación en enfriamiento o en transición | No | No | No (7: pulsación muda por diseño) |
    | `repasar_bolsillo` con bolsillo vacío o `RECHAZADA` (20, R19/R20) | No | No | No (20: «sin mensaje; pulsar de nuevo cuesta nada») |

19. **Aviso necesario.** El pulso se dispara con el aviso «interacción sin efecto (id, motivo ∈ `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO`)» ‡ de 7, emitido en el mismo paso que `SFX_CLICK_SUBTLE`. «Interacción ejecutada» con resultado `SIN_EFECTO` (cambio de estado entre física y pulsación, regla 3 de 7) cuenta como `SIN_EFECTO`. El pulso se inicia ≤ `latencia_feedback_ms` (100 ms†) tras el aviso.
20. **Sin rojo, sin temblor, sin texto de error.** El rechazo no se codifica en color (art bible §4.5: rojo no es señal) ni en sacudida (art bible §3.3 reserva «leve temblor frío» a los puzles, y eso es de 9). La comprensión del rechazo no depende del pulso: el sonido y el pie (cuando existe) lo redundan.

### D. Pie de texto

21. **Un solo hueco.** Hay un único pie visible. Una nueva petición **sustituye** al pie actual (7, regla 12: activar otro objeto lo sustituye) con fundido cruzado de 150 ms (100 ms con `reducir_movimiento`). No hay cola.
22. **API.** `mostrar_pie(clave, duracion_s | PERSISTENTE, retener = falso) ‡` y `ocultar_pie()`. Lo llaman **7** (textos `OBJ_<id>` de `INSPECCION_TEXTO` y `SIN_EFECTO`: objetos de 8, 9, 10, 19, 20, 22, 28 y los del catálogo) y **20** (`UI_BOLSILLO_AYUDA`, con `retener = verdadero`). 24 no conoce qué objeto o sistema originó el pie.
23. **Duración.** La calcula el llamador con F5 de 7 (`t_pie`, que ya incluye `multiplicador_pie`) y 7 expone `duracion_pie(clave) -> float` ‡ para que 20 use la misma fórmula (en el cómputo de `n` cada token `{…}` cuenta como un carácter). Con `pie_persistente` activo 7 pasa `PERSISTENTE`: el pie dura hasta que cambie `get_target().id` respecto del que había al mostrarse (nulo cuenta como un valor) o hasta que llegue otro pie. El reloj es de tiempo de juego: la pausa lo detiene.
24. **Posición y legibilidad.** Abajo-centro, dentro de los márgenes seguros del 5 % (art bible §4.5), máximo 2 líneas con ancho ≤ 60 %† del ancho de pantalla; texto blanco frío sobre panel azul noche al 70 %† de opacidad (contraste mínimo 4,5:1 texto/panel; alto de texto ≥ 28 px† a 1080p). La tipografía y el panel son del art-director (Open Questions); estos números son el mínimo funcional de accesibilidad. Sin máquina de escribir: fundido de 250 ms† de entrada y 250 ms† de salida (100 ms con `reducir_movimiento`).
25. **Longitud.** Un texto > `texto_max_caracteres` (90†) no es un pie (7, regla 12): 24 lo recibe igualmente y lo muestra (hasta 3 líneas), pero **registra la advertencia** de datos en desarrollo.
26. **Solo en exploración.** Con el contexto ≠ `exploración` el pie se oculta y su reloj se congela. Al salir de `exploración` por un **modo de 7** o `sin control`, los pies de objeto (`retener = falso`) se **descartan** (no reaparecen obsoletos). Un pie con `retener = verdadero` (`UI_BOLSILLO_AYUDA`) se **mantiene pendiente** y se muestra al volver a `exploración`, con un máximo de espera `pie_espera_max_s` (10 s† de tiempo de juego; la pausa no cuenta). Con la pausa abierta (`menú`) todo pie se congela y se reanuda al cerrar.
27. **`UI_BOLSILLO_AYUDA`.** Texto (de 18, **provisional**): «Atrás: revisar los papeles». 24 resuelve la acción `atrás` **sin asumir `Retroceso`**: la clave de 18 lleva el token `{accion:atras}` ‡ (p. ej. «{accion:atras}: revisar los papeles») que 24 sustituye por el glifo + texto de la asignación vigente de `atrás` en el dispositivo activo (regla 13): `[Retroceso] revisar…` con el valor por defecto de teclado, `[B]` o el que sea con mando, o la tecla/botón reasignados (Entrada R15 y R17: siempre hay al menos una asignación). Si 18 conserva la forma literal sin token, 24 muestra el texto tal cual (el nombre de la acción, no una tecla) y se registra la advertencia. Si `get_binding_label` falla, el token se sustituye por el nombre de la acción «Atrás».
28. **Una vez por sesión.** La política de «una sola vez» es de 20 (R23; 24 no mantiene bandera). 24 muestra el pie cada vez que se le pide.
29. **Importancia.** El pie nunca contiene información necesaria para avanzar (7, regla 12; 20, R23): 24 no ofrece historial ni relectura (fuera del slice, Open Questions de 7).

### E. Escala, resoluciones y ajustes leídos

30. **Escala.** Todas las medidas en px de este GDD son para 1080p y escalan con F2 (altura de la ventana; soporte de 720p a 2160p). En 16:9 o más estrecho los márgenes seguros del 5 % se aplican a ambos ejes; en ultraancho se anclan al área 16:9 central.
31. **Ajustes que lee** (de 6, vía avisos de cambio; 24 los aplica en el fotograma siguiente): `reducir_movimiento` (fundidos fijos de 100 ms), `icono_grande` ‡, `etiqueta_accion_visible` ‡. `multiplicador_pie` y `pie_persistente` los lee 7, no 24.
32. **Sin dependencia del color.** Ningún elemento de 24 usa un color distinto para comunicar estado: anillo = presencia; relleno = progreso; pulso = rechazo; texto = contenido. Tras el filtrado de daltonismo (art bible §4.5) todos los estados se distinguen igual.

## Formulas

### F1 · Relleno del anillo y opacidad del pulso

`relleno_grados = 360 · p` (solo si `anillo_visible`; `p` es F2 de 7)
`opacidad_pulso(t)`: aceptada = `0,80 + 0,20 · tri(t / 0,12)`; rechazo = `0,80 − 0,40 · tri(t / 0,12)`, con `tri(x) = 1 − |2x − 1|` para `x ∈ [0, 1]` y 0 fuera.

**Variables:** `p` 0–1; `t` segundos desde el aviso; 0,12 s = duración del pulso (art bible §7.4); 0,40† = profundidad del rechazo.
**Rango de salida:** 0°–360°; opacidad 0,40–1,00.
**Ejemplo:** `p = 0,6` → 216°. Rechazo, `t = 0,06` → opacidad 0,40; `t = 0,12` → 0,80.

### F2 · Escala de interfaz

`s = clamp(altura_ventana / 1080, 0,67, 2,0)`; `tamaño_px = base_px · s`

**Variables:** `altura_ventana` en px físicos; `base_px` el valor de 1080p de este GDD.
**Rango:** `s` ∈ [0,67, 2,0] (720p → 0,67; 1440p → 1,33; 2160p → 2,0).
**Ejemplo:** a 720p el anillo estándar mide 28 · 0,67 = 18,8 → 19 px (redondeo al entero); el texto del pie de 28 px† mide 19 px, **por debajo del mínimo de legibilidad**: por eso el alto mínimo absoluto del pie es `pie_alto_min_px` 20† y el pie usa `max(28 · s, 20)`.

### F3 · Espera máxima del pie retenido

`pie_retenido_vigente = (t_juego_ahora − t_petición) ≤ pie_espera_max_s`, contando solo tiempo de juego en cualquier contexto menos `menú`.

**Ejemplo:** 20 pide el pie al entrar `I-04` durante una `lectura` de 25 s: a los 10 s el pie se descarta; con una lectura de 6 s aparece al volver a `exploración` con su duración completa (F5 de 7).

## Edge Cases

- **Objetivo cambia durante un pulso.** El pulso termina sobre el anillo, que sigue; no se cancela ni se reinicia.
- **`get_target()` devuelve un `etiqueta` distinta con el mismo `id`** (`V06` encendida → apagada): fundido cruzado de la etiqueta (regla 5); el anillo no parpadea.
- **Dispositivo cambia con el pie `UI_BOLSILLO_AYUDA` en pantalla:** el token se re-resuelve (regla 14); el reloj no se reinicia; el texto puede cambiar de ancho sin saltar de línea (reflow con fundido de 100 ms).
- **Reasignar `atrás` a una tecla imprimible** (25 muestra aviso, Entrada R20): el pie la muestra tal cual (`[Q]`); sin caso especial.
- **Mando desconectado:** la pausa se abre (Entrada R22); al reanudar el dispositivo vigente es el último evento y los glifos se re-resuelven.
- **Dos pies en el mismo fotograma** (p. ej. `SIN_EFECTO` de 7 y `UI_BOLSILLO_AYUDA` de 20): gana el que llega **último en ese fotograma**; el primero se pierde sin cola (ver Open Questions sobre si la ayuda debe esperar).
- **Pie pedido con clave inexistente:** no se dibuja, se registra el error; nunca se muestra la clave.
- **Texto largo en idioma con +30 %:** si no cabe en 2 líneas dentro del 60 %, el ancho crece hasta el 80 %† y luego a 3 líneas; la advertencia de la regla 25 aplica.
- **Anillo sobre fondo muy claro** (monitor, papel, ventanal): el filo de 1 px azul noche (regla 4) mantiene el contraste; no se añade sombra.
- **Carga de partida con objetivo ya enfocado:** `get_target()` es nulo al cargar (7, regla 4); el anillo aparece con el fundido de 250 ms en cuanto haya objetivo; no hay pies pendientes (el pie y su cola no se persisten).
- **Pausa durante un fundido:** el fundido se congela a mitad (tiempo de juego) y continúa al reanudar.
- **`reducir_movimiento` cambia durante un fundido:** el nuevo valor se aplica en la siguiente animación; la actual termina.
- **El jugador mantiene `interactuar` sobre `leer` y el objetivo pasa a `NO`:** el anillo desaparece con el fundido de 150 ms; 7 cancela la pulsación (regla 7 de 7); no hay pulso de rechazo.
- **Escena sin Entrada (arranque):** sin contexto no se dibuja nada; 24 espera «escena lista».

## Dependencies

| Sistema | Dureza (desde 24) | Qué recibe 24 / qué da | Notas |
|---|---|---|---|
| 1 Entrada y controles | Blanda | Dispositivo activo, `get_binding_label(accion, dispositivo)` ‡, contexto actual, aviso «dispositivo de entrada cambiado»; no da nada | Sin Entrada se muestra el nombre de la acción (regla 27) |
| 7 Interacción e inspección | **Dura** | `get_target()` (con `anillo_visible` ‡), `duracion_pie` ‡, avisos «interacción ejecutada» e «interacción sin efecto» ‡; llama a `mostrar_pie` / `ocultar_pie` | 7 ya declara la dependencia dura (índice de 7: «`get_target()`») |
| 18 Base de contenido narrativo | **Dura** | Textos de `UI_VERBO_*`, `OBJ_<id>`, `UI_BOLSILLO_AYUDA` (con token `{accion:atras}` ‡) | Solo lectura; claves ausentes: reglas 16 y de pie |
| 20 Documentos y bolsillo | Consumidor | 20 llama a `mostrar_pie(UI_BOLSILLO_AYUDA, …, retener = verdadero)` (R23 de 20); 24 no lee nada de 20 | 20 declara 24 como blanda |
| 6 Ajustes persistentes | Blanda ‡ | `reducir_movimiento`, `icono_grande` ‡, `etiqueta_accion_visible` ‡ | `multiplicador_pie`/`pie_persistente` los lee 7 |
| 8, 9, 10, 19, 22, 28 | Indirecta (vía 7) | Sus manejadores (`can_interact`, `interact`, `etiqueta`) llegan a 24 solo como `get_target()`, avisos de 7 y pies de 7 | 24 no los conoce ni los llama |
| 25 / 30 (Pausa, Accesibilidad) | Consumidores | Ofrecen `reducir_movimiento`, `icono_grande`, `etiqueta_accion_visible` | Pantallas fuera de 24 |
| 23 Audio | — | 24 no emite audio; `SFX_CLICK_SUBTLE` lo emite 7 | Sin dependencia |

**Qué hacen los manejadores con 24 (contrato de 7, regla 3):** `can_interact` = `NO` → sin anillo ni pie; = `SIN_EFECTO` → anillo con pulso de rechazo al pulsar y pie `OBJ_<id>` si el catálogo lo declara; `etiqueta(verbo)` → la clave llega resuelta en `get_target().etiqueta`. Objetos del slice con etiqueta dinámica conocidos: `V06` («Encender»/«Apagar»), `V08` («Imprimir»/«Recoger», condicional a PA-7 de 19). Pies de 8: `OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08`; de 19: `OBJ_V08_SIN_RESULTADOS`, `OBJ_V08_YA_IMPRESA` (ver Open Questions).

## Tuning Knobs

Todos en `assets/data/ui/prompt.json`. Los de accesibilidad son ajustes del jugador (6), no de datos.

| Clave | Valor inicial | Rango seguro | Afecta a |
|---|---|---|---|
| `anillo_px` / `anillo_grande_px` | 28 / 48 | 24–40 / 40–64 | Legibilidad del anillo (F2) |
| `anillo_opacidad` | 0,80 | 0,6–1,0 | Discreción frente a visibilidad |
| `fade_in_ms` / `fade_out_ms` | 250 / 150 | 100–400 / 100–300 | Sensación «todo se disuelve» |
| `fade_reducido_ms` | 100 | 50–150 | Con `reducir_movimiento` (art bible §7.4) |
| `pulso_ms` | 120 | 80–200 | Latencia percibida; ≤ `latencia_feedback_ms` al inicio |
| `pulso_rechazo_min` | 0,40† | 0,3–0,6 | Que el rechazo se note sin parecer parpadeo |
| `etiqueta_offset_px` | 12† | 8–24 | Separación anillo-etiqueta |
| `pie_ancho_max` | 0,60† | 0,5–0,8 | Líneas del pie |
| `pie_alto_texto_px` / `pie_alto_min_px` | 28† / 20† | 24–36 / 18–24 | Legibilidad (F2) |
| `pie_panel_opacidad` | 0,70† | 0,5–0,9 | Contraste del pie |
| `pie_fade_ms` | 250† | 100–400 | Entrada y salida del pie |
| `pie_espera_max_s` | 10† | 5–20 | Cuánto espera `UI_BOLSILLO_AYUDA` |
| `ui_escala_min` / `ui_escala_max` | 0,67 / 2,0 | 0,5–0,75 / 1,5–3,0 | Resoluciones soportadas (F2) |
| `etiqueta_accion_visible` ‡ | falso | falso/verdadero | Accesibilidad (6) |
| `icono_grande` ‡ | falso | falso/verdadero | Accesibilidad (6) |

## Acceptance Criteria

- **AC-24-01 (R1–R3, L + V)**: **GIVEN** un objetivo válido en `exploración`, **THEN** el anillo se dibuja en el centro de la pantalla en el fotograma siguiente al primero en que `get_target()` ≠ nulo, con fundido de 250 ms; **WHEN** pasa a nulo, **THEN** desaparece con fundido de 150 ms; **GIVEN** sin objetivo, **THEN** no hay ningún elemento en pantalla (sin punto de mira).
- **AC-24-02 (R2, L)**: **GIVEN** el contexto en `menú`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada` o `sin control`, **THEN** anillo y etiqueta están ocultos aunque `get_target()` devolviera un valor.
- **AC-24-03 (R5, V)**: **GIVEN** el cambio de objetivo `V05` → `C05` sin pasar por nulo, **THEN** el anillo no baja de su opacidad y la etiqueta (si activa) hace un fundido cruzado de 120 ms.
- **AC-24-04 (R6, F1, L)**: **GIVEN** `largo`, `anillo_visible` y `p = 0,6`, **THEN** el relleno es 216° horario desde las 12 h; **GIVEN** `anillo_visible` falso, **THEN** no hay relleno; **WHEN** se suelta antes de `t_hold`, **THEN** el relleno se vacía en 100 ms.
- **AC-24-05 (R7, V)**: **GIVEN** `interactuar` procesado con `HECHO`, **THEN** el anillo pasa de 80 % a 100 % y vuelve en 120 ms, sin escala ni desplazamiento.
- **AC-24-06 (R17–R19, L + V)**: **GIVEN** `SIN_EFECTO` (lector `C06` sin tarjeta), gesto rechazado o toque corto sobre `A04`, **THEN** el anillo hace un pulso de 80 % a 40 % y vuelve en 120 ms, iniciado ≤ 100 ms tras el aviso de 7, y **solo 7** reproduce `SFX_CLICK_SUBTLE`; **GIVEN** enfriamiento o transición, **THEN** no hay pulso.
- **AC-24-07 (R20, R32, V)**: **GIVEN** una captura del anillo, el pulso y el pie convertida a escala de grises y simulada para deuteranopia, protanopia y tritanopia, **THEN** todos los estados (presencia, progreso, rechazo, pie) siguen distinguiéndose y ningún estado usa rojo.
- **AC-24-08 (R10–R13, L)**: **GIVEN** `etiqueta_accion_visible` verdadero, **THEN** la etiqueta muestra `[glifo] + texto` de la clave de `get_target().etiqueta` y el glifo corresponde a la asignación vigente de `interactuar` del dispositivo activo; **GIVEN** `etiqueta_accion_visible` falso (valor inicial), **THEN** no se dibuja etiqueta.
- **AC-24-09 (R14, L)**: **GIVEN** una etiqueta visible, **WHEN** el dispositivo activo cambia de teclado a mando, **THEN** el glifo cambia en el fotograma siguiente y `get_binding_label` se consulta una sola vez por cambio.
- **AC-24-10 (R27, L)**: **GIVEN** `UI_BOLSILLO_AYUDA` solicitado con `atrás` en su asignación por defecto de teclado, **THEN** el pie muestra el nombre de esa tecla leído de Entrada; **GIVEN** `atrás` reasignada a otra tecla o botón, **THEN** el pie muestra la nueva; **THEN** ningún literal «Retroceso» ni «Backspace» existe en el código ni en los datos de 24 (búsqueda en el repositorio).
- **AC-24-11 (R27, L)**: **GIVEN** `get_binding_label` no disponible o clave de 18 sin token, **THEN** el pie se muestra con el nombre de la acción «Atrás» (o el texto tal cual) y se registra una advertencia, sin error en pantalla.
- **AC-24-12 (R21–R23, L)**: **GIVEN** un pie en pantalla, **WHEN** llega otro, **THEN** lo sustituye con fundido de 150 ms; **GIVEN** `pie_persistente`, **THEN** el pie permanece hasta que `get_target().id` cambia respecto del inicial o llega otro pie.
- **AC-24-13 (R23, F5 de 7, L)**: **GIVEN** `multiplicador_pie` = 2,0 y «Café frío. Lo dejó a las siete» (30 caracteres), **THEN** el pie dura 5,29 s de tiempo de juego y la pausa detiene el reloj.
- **AC-24-14 (R24, V)**: **GIVEN** 720p, 1080p y 2160p, **THEN** el pie queda dentro de los márgenes seguros del 5 %, el texto mide ≥ 20 px físicos y el contraste texto/panel es ≥ 4,5:1 (medido en captura).
- **AC-24-15 (R26, L)**: **GIVEN** un pie de objeto activo, **WHEN** se abre una `lectura`, **THEN** el pie se descarta y no reaparece al cerrarla; **GIVEN** `UI_BOLSILLO_AYUDA` pedido durante una `lectura` de 6 s, **THEN** aparece al volver a `exploración`; **GIVEN** una lectura de 12 s, **THEN** se descarta (F3).
- **AC-24-16 (R5, R24, V)**: **GIVEN** `reducir_movimiento` activo, **THEN** todos los fundidos del anillo, la etiqueta y el pie duran 100 ms.
- **AC-24-17 (R4, V)**: **GIVEN** `icono_grande` activo, **THEN** el anillo mide 48 px a 1080p, trazo 3 px, opacidad 100 %, con contorno de 2 px.
- **AC-24-18 (Accesibilidad, L)**: **GIVEN** la partida jugada solo con teclado y solo con mando, **THEN** todos los prompts y pies se ven y los glifos son los del dispositivo activo; **THEN** ningún efecto de 24 supera 3 cambios de luminosidad por segundo.
- **AC-24-19 (R8, L)**: **GIVEN** un manejador con `can_interact = NO`, **THEN** 24 no dibuja anillo, pulso ni pie para ese objeto.
- **AC-24-20 (R9, V)**: **GIVEN** `leer` en modo «alternar», **THEN** el relleno permanece visible entre las dos pulsaciones y se vacía al cancelar con `atrás`.

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D24-1 | Anillo fijo en el centro de la pantalla | Proyectarlo sobre el objeto | El rayo sale del centro; la proyección salta con el temblor y acerca el icono a una fuente de luz del mundo (art bible §3.3) |
| D24-2 | Etiqueta de acción **apagada por defecto** (`etiqueta_accion_visible` ‡) | Siempre visible (lo sugiere UI Requirements de 7) | Art bible §7.3 la fija desactivada por defecto; slice §16 pide «icono discreto»; pilar Autonomía como progresión. 7 queda alineado en «Cambios requeridos» |
| D24-3 | `{accion:atras}` como token resuelto contra Entrada, con respaldo al nombre de la acción | Escribir «Retroceso» en el texto de 18 o mostrar solo «Atrás» | `atrás` es reasignable (R15 de 1): un literal mentiría; un nombre sin glifo no dice qué pulsar |
| D24-4 | Glifo siempre con texto; nunca solo icono | Solo glifos gráficos | Accesibilidad (sin depender de forma/color del glifo) y lector de pantalla futuro |
| D24-5 | Rechazo = pulso de opacidad + `SFX_CLICK_SUBTLE` de 7 (+ pie si lo hay) | Temblor o color de error; sonido propio de 24 | Art bible: sin rojo, temblor reservado a puzles; una sola fuente de audio (7/23); pilar Tensión sin castigo |
| D24-6 | No hay estado «solo punto» en `exploración` | Dibujar un punto permanente | Slice §16 y art bible §7.3: «no hay punto de mira permanente»; ver Open Questions |
| D24-7 | Un solo hueco de pie, sin cola; el último gana | Cola de pies | Coherencia con 7, regla 12; un pie es ambiente, perder uno no cuesta |
| D24-8 | Pies de objeto se descartan al abrir un modo; solo los marcados `retener` (ayuda de 20) esperan hasta 10 s† | Retener todos / descartar todos | Un pie obsoleto confunde; la ayuda de 20 se pide normalmente dentro de una `lectura` y debe verse al salir |
| D24-9 | 24 consulta `get_target()` por fotograma y el rechazo llega por **aviso nuevo** ‡ | Aviso por cambio de objetivo | Regla 29 de 7: una señal por fotograma saturaría el bus; el rechazo es discreto y sí merece aviso |
| D24-10 | La duración la calcula el llamador con F5 de 7 (`duracion_pie`) | 24 reimplementa F5 | Una sola fórmula, un solo dueño (7); 24 solo dibuja |
| D24-11 | `repasar_bolsillo` sin feedback propio de 24 | Pulso o mensaje si no hay papeles | 20 (R19/R20) fija «sin sonido, sin mensaje»; el pie de ayuda ya enseña la acción una vez |

## Open Questions

1. **Etiqueta apagada por defecto frente a descubribilidad.** Con la etiqueta apagada, un objeto solo `leer` se «explica» por el anillo que se rellena y el pulso al toque corto. *Decisión por defecto:* D24-2. Validar en el primer playtest (slice §23.4) si el jugador descubre `leer`; si no, abrir una pista de contexto única («Mantén para leer») en 18, no encender la etiqueta global. Afecta al tono y a la guía del jugador: **para el director creativo**.
2. **Estado «solo punto»** (art bible §7.3) frente a «sin punto de mira». *Defecto:* no se usa en `exploración`; art-director decide si sirve para otro contexto (p. ej. vistas).
3. **Tipografía, panel del pie y glifos** (atlas de teclado/mando): sin definir en el art bible; los números de las reglas 24 y 12 son mínimos funcionales †. Dueño: art-director.
4. **Ajuste de tamaño de UI y de texto:** no existe en 6; F2 solo escala con la ventana. Si 30 (Accesibilidad) añade un multiplicador de escala, F2 lo absorbe.
5. **Lector de pantalla (AccessKit, Godot 4.5+):** exponer pie y etiqueta como región viva queda fuera del slice (MVP). Defecto: no; sí se cumple la regla de «glifo siempre con texto».
6. **Clave de `V08` «Recoger» y `UI_VERBO_RESPONDER`:** 7 y 19 los nombran, 18 no los lista; sin clave, 24 no dibuja etiqueta (regla 16).
7. **`V08` con dos pies** (`OBJ_V08_SIN_RESULTADOS`, `OBJ_V08_YA_IMPRESA`) frente a «una clave `texto` por objeto» (regla 3 de 7): pendiente de 7/19; 24 es agnóstico (acepta cualquier clave que 7 pase).
8. **Prioridad de la ayuda de bolsillo** frente a un pie de objeto simultáneo: hoy gana el último. Si resulta que 20 la pierde a menudo, dar `retener` más prioridad.

## Cambios requeridos en otros GDDs

Este GDD no ha editado ningún archivo existente. Cambios a aplicar (los coordina `producer`):

| GDD | Cambio | Motivo |
|---|---|---|
| `systems-index.md` | Fila 24 (la numerada «22» en su tabla de Progress/Order, corregir numeración): estado «Borrador (lote autónomo)», ruta `design/gdd/prompt-de-interaccion.md`; dependencias 1 (blanda), 7 (dura), 18 (dura), 6 (blanda ‡); consumidor 20 | Existe el GDD |
| `entrada-y-controles.md` (1) | Exponer `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id}` y el contexto actual; cerrar el «V» de AC-03 con 24 | Contrato de 24 |
| `interaccion-e-inspeccion.md` (7) | (a) `get_target()` añade `anillo_visible`; (b) aviso nuevo «interacción sin efecto (id, motivo)»; (c) `duracion_pie(clave)`; (d) llama a `mostrar_pie`/`ocultar_pie` de 24 y alinea UI Requirements: etiqueta apagada por defecto (D24-2) | Contrato de 24 |
| `base-de-contenido-narrativo.md` (18) | `UI_BOLSILLO_AYUDA` con token: «{accion:atras}: revisar los papeles» (texto provisional); claves `UI_VERBO_RECOGER` y `UI_VERBO_RESPONDER` si se mantienen; fila 24 con el token | Sin asumir `Retroceso` |
| `documentos-y-bolsillo.md` (20) | R23: «pide a 24» = `mostrar_pie(UI_BOLSILLO_AYUDA, duracion_pie(clave), retener = verdadero)` | Contrato concreto |
| `ajustes-persistentes.md` (6) | Nuevos ajustes de accesibilidad `icono_grande` y `etiqueta_accion_visible` (bool, falso); fila de consumidor 24 (`reducir_movimiento`); recuento de «restablecer todos» pasa de 12 a 14 | Art bible §4.5/§7.3 |
| `menu-de-pausa` (25) / accesibilidad (30), cuando existan | Ofrecer los dos ajustes nuevos | Pantallas |
| `design/art/art-bible.md` | Confirmar rótulo con etiqueta (glifo en línea) bajo el anillo frente a «nunca flotando junto al anillo»; definir panel y tipografía del pie | Open Questions 2 y 3 |

## Entradas para el registro

| Tipo | Nombre | Valor / descripción | Fuente |
|---|---|---|---|
| constante | `PROMPT_RING_PX` † | 28 estándar / 48 grande (1080p) | reglas 4, F2 |
| constante | `PROMPT_PULSE_MS` | 120 (aceptado y rechazo) | reglas 7, 18 |
| constante | `PROMPT_REJECT_MIN_OPACITY` † | 0,40 | F1 |
| constante | `PROMPT_FOOT_MAX_WAIT_S` † | 10 s de tiempo de juego | regla 26, F3 |
| constante | `PROMPT_UI_SCALE_RANGE` † | 0,67–2,0 sobre 1080p | F2 |
| fórmula | `ui_scale` | `clamp(altura/1080, 0,67, 2,0)` | F2 |
| ajuste | `icono_grande` ‡ | bool, falso (6) | regla 4 |
| ajuste | `etiqueta_accion_visible` ‡ | bool, falso (6) | regla 11 |
| aviso | «interacción sin efecto» ‡ | `(id, motivo)`; emite 7, consume 24 | regla 19 |
| API | `mostrar_pie` / `ocultar_pie` ‡ | las llaman 7 y 20; dueño 24 | regla 22 |
| API | `get_binding_label` ‡ | dueño 1; consume 24 | regla 13 |
| token de texto | `{accion:atras}` ‡ | sustituido por 24 (glifo + texto vigente) | regla 27 |
| regla | `prompt_no_audio` | 24 no emite audio; `SFX_CLICK_SUBTLE` es de 7 | regla 17 |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote autónomo): anillo, etiqueta, rechazo, pie y `UI_BOLSILLO_AYUDA` sin asumir `Retroceso`. Pendiente de revisión independiente |
