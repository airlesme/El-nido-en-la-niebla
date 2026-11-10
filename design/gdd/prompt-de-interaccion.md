# Prompt de interacción y feedback (sistema 24)

> **Status**: Revisado (ronda de corrección 9) — pendiente de re-review
> **Author**: UX Designer (lote autónomo)
> **Last Updated**: 2026-11-10
> **Implements Pillar**: Autonomía como progresión (el prompt no revela lo que aún no está disponible) · Tensión sin castigo (el rechazo es un susurro, nunca un error) · Información incompleta (el pie es ambiente, no pista) · El espacio expresa la emoción (overlay mínimo, sin luz propia)

> `†` = valor propuesto, a validar en playtest. `‡` = elemento propuesto que aún no existe en otros GDDs (ver «Cambios requeridos»; desde la ronda 9 quedan abiertos solo los de 6 y 18). `PV` = pendiente de verificación en el editor de Godot 4.7. Los identificadores de código van en inglés; los IDs del slice (`V06`, `OBJ_C06`, `UI_BOLSILLO_AYUDA`…) se conservan tal cual.

## Summary

24 es la **capa de overlay de la exploración**: dibuja el anillo de interacción sobre el objetivo que 7 reporta (con su progreso para `leer`), la etiqueta de acción opcional con el glifo del dispositivo activo, el feedback visual de rechazo («sin efecto») y el **pie de texto** no bloqueante (textos de objeto `OBJ_<id>` y el pie `UI_BOLSILLO_AYUDA` de 20). No decide nada de juego: consulta `get_target()` de 7 cada fotograma, resuelve glifos con Entrada (1) y textos con 18, y no escribe hechos.

## Overview

Una sola tecla o botón contextual (slice §5) exige que el jugador sepa, sin menús, **cuándo** puede actuar, **qué** hará y **qué ha pasado** tras pulsar. 24 resuelve las tres cosas con tres piezas: (1) el **anillo con punto** (art bible §3.3 y §7.3) en el centro de la pantalla, que solo existe sobre objetivos válidos; (2) la **etiqueta** («Abrir», «Leer»…) con el glifo del botón vigente, apagada por defecto y activable en accesibilidad; (3) el **pie** abajo-centro, un texto breve que se sustituye o expira. El rechazo («sin efecto», gesto rechazado, toque corto sobre `leer`) se comunica con un pulso del anillo más el `SFX_CLICK_SUBTLE` que emite 7, y con el pie `OBJ_<id>` cuando el objeto lo tiene: nunca con rojo, temblor ni mensaje de error. Ninguna pieza se apoya solo en el color (todo es blanco frío sobre fondo oscuro; la información viaja por forma, texto, posición y sonido). 24 no tiene estado persistente.

## Player Fantasy

Mirar es elegir (art bible, principio 3): el anillo aparece cuando algo «responde» a la mirada de Vera y se disuelve cuando deja de hacerlo. El juego nunca grita ni regaña; cuando algo no cede, el mundo contesta con un clic discreto y, a veces, con una frase breve que suena a pensamiento, no a instrucción. El jugador siente que *él* descubre qué es interactuable, y que una pulsación de más no cuesta nada.

## Detailed Rules

### A. Anillo de interacción

1. **Fuente única.** 24 consulta `get_target()` de 7 **en cada fotograma de render** (7, regla 29: no hay aviso de cambio de objetivo). Entrada esperada: `{id, etiqueta (clave ya resuelta), largo (bool), p (0 a 1), anillo_visible (bool)} | nulo` (contrato aplicado en 7, regla 30 y D7-73). 24 **no** recalcula el objetivo, el verbo ni `p`.
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
13. **Origen del glifo.** Se lee de Entrada: dispositivo activo (regla 3 de 1) y asignación **vigente** de la acción (reasignable, R15 de 1) mediante `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id}` (1, regla 24, D34). 24 **nunca** guarda ni supone una tecla concreta. Con dos asignaciones para la acción y el dispositivo, se muestra la primera que devuelve `get_binding_label`; se pide a 1 que el orden sea determinista (orden de alta, también tras reasignar).
14. **Reactividad.** Al cambiar el dispositivo activo («dispositivo de entrada cambiado», Entrada R3) o la asignación (se re-consulta al recibir «pausa cerrada»: la reasignación solo ocurre con la pausa abierta; 1, regla 24), la etiqueta y los pies con glifo se re-resuelven en el siguiente fotograma, sin reiniciar el reloj de ningún pie. Una única consulta por cambio, no por fotograma.
15. **El glifo es siempre el de `interactuar`** (la pulsación prolongada de `leer` y la segunda pulsación del modo alternar usan la misma asignación; los gestos derivados no se reasignan, R15 de 1). El texto de etiqueta de `leer` («Leer») ya implica mantener; el anillo lo muestra al rellenarse.
16. **Clave ausente.** Si 18 no tiene la clave de etiqueta, la etiqueta no se dibuja (el anillo sí), se registra el error en desarrollo y no se muestra nunca el nombre de la clave al jugador.

### C. Feedback de rechazo y de «sin efecto»

17. **Contrato.** 24 no reproduce audio. El sonido de rechazo (`SFX_CLICK_SUBTLE`) lo emite 7 (regla 11 de 7); 24 aporta la **parte visual** y el pie. Un solo gesto del jugador produce como máximo **un** pulso. **Tope de fotosensibilidad:** 24 ignora un pulso nuevo si el anterior empezó hace menos de `pulso_min_intervalo_ms` (340 ms†, es decir ≤ 2,9 pulsos/s), aunque el enfriamiento de 7 (`t_enfriamiento_s` 0,25 s†) deje pasar más. Cada pulso es un único par bajada/subida de opacidad (un destello) de un anillo de 28 px. «Destello» y su umbral son los que fija 30 (regla 18 y AC-30-13: par de cambios de luminancia relativa ≥ 10 % sobre un área > 25 % del campo de visión); 24 no define otra medida. El anillo queda muy por debajo de esa área y el tope garantiza además ≤ 3 por segundo (tope duro de 30, regla 18). Un pulso ignorado no vuelve a dispararse (sin cola). El sonido de 7 no se ve afectado.
18. **Casos y respuesta.** Todos los casos comparten el **pulso de rechazo**: el anillo baja de 80 % a 40 %† y vuelve en 120 ms (opacidad, sin movimiento; no altera la silueta, así que no depende de `reducir_movimiento`).

    | Caso (origen en 7) | Pulso | Sonido (7) | Pie |
    |---|---|---|---|
    | `SIN_EFECTO` del manejador (lector sin tarjeta `C06`/`C07`/`D06`, ascensor inactivo `C08`, compartimento bloqueado, puzle resuelto, impresora sin resultados…) | Sí | `SFX_CLICK_SUBTLE` | `OBJ_<id>` si el catálogo tiene `texto` (regla 3 de 7) |
    | Gesto rechazado por el Jugador (otro gesto bloqueante en curso) | Sí | `SFX_CLICK_SUBTLE` | No (7 no muestra `texto`) |
    | Toque corto sobre un objeto solo `leer` | Sí (el anillo pulsa una vez; 7, regla 9) | `SFX_CLICK_SUBTLE` | No |
    | Pulsación en enfriamiento o en transición | No | No | No (7: pulsación muda por diseño) |
    | `repasar_bolsillo` con bolsillo vacío o `RECHAZADA` (20, R19/R20) | No | No | No (20: «sin mensaje; pulsar de nuevo cuesta nada») |

19. **Aviso.** No hay aviso nuevo: el pulso (de aceptación y de rechazo) se dispara con el aviso existente «interacción ejecutada (id, verbo, resultado)» de 7, cuyo dominio de `resultado` se **amplía** (aplicado en 7, regla 29 y D7-74) a `HECHO`, `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` (el dominio de retorno de `interact()` no cambia: sigue `HECHO`/`SIN_EFECTO`; los otros dos los origina 7 sin llamar al manejador); se emite en el mismo paso que `SFX_CLICK_SUBTLE`. Un mismo gesto produce un solo aviso y por tanto un solo pulso (incluido el `SIN_EFECTO` por cambio de estado entre física y pulsación, regla 3 de 7). El pulso se inicia ≤ `latencia_feedback_ms` (100 ms†) tras el aviso.
20. **Sin rojo, sin temblor, sin texto de error.** El rechazo no se codifica en color (art bible §4.5: rojo no es señal) ni en sacudida (art bible §3.3 reserva «leve temblor frío» a los puzles, y eso es de 9). La comprensión del rechazo no depende del pulso: el sonido y el pie (cuando existe) lo redundan.

### D. Pie de texto

21. **Un solo hueco.** Hay un único pie visible. Una nueva petición **sustituye** al pie actual (7, regla 12: activar otro objeto lo sustituye) con fundido cruzado de 150 ms (100 ms con `reducir_movimiento`). No hay cola.
22. **API.** `mostrar_pie(clave, duracion_s | PERSISTENTE, retener = falso)` y `ocultar_pie()` (dueño 24; 7 documenta la llamada en su regla 12 y D7-75). Lo llaman **7** (textos `OBJ_<id>` de `INSPECCION_TEXTO` y `SIN_EFECTO`: objetos de 8, 9, 10, 19, 20, 22, 28 y los del catálogo) y **20** (`UI_BOLSILLO_AYUDA`, con `retener = verdadero`). 24 no conoce qué objeto o sistema originó el pie.
23. **Duración.** La calcula el llamador con F5 de 7 (`t_pie`, que ya incluye `multiplicador_pie`) y 7 expone `duracion_pie(clave) -> float | PERSISTENTE` (regla 30 de 7, D7-75; centinela `PERSISTENTE`, p. ej. `-1`), que ya aplica `pie_persistente`; 20 pasa el valor tal cual a `mostrar_pie`, así que la ayuda de bolsillo también es persistente con ese ajuste (en el cómputo de `n` cada token `{…}` cuenta como un carácter). Con `PERSISTENTE` el pie dura hasta que cambie `get_target().id` respecto del que había **en el instante en que el pie se dibuja** (no cuando se pide; nulo cuenta como un valor) o hasta que llegue otro pie. El reloj es de tiempo de juego: la pausa lo detiene.
24. **Posición y legibilidad.** Abajo-centro, dentro de los márgenes seguros del 5 % (art bible §4.5), máximo 2 líneas con ancho ≤ 60 %† del ancho de pantalla; texto blanco frío sobre panel azul noche al 85 %† de opacidad (contraste mínimo 4,5:1 texto/panel, **garantizado sobre fondo blanco puro** `#FFFFFF`, el peor caso: con 85 % el panel efectivo queda en ≈ `#3E4A56` y el contraste en ≈ 6,5:1 (cálculo aproximado); con 70 % caía a ≈ 4,3:1); alto de texto ≥ 28 px† a 1080p y **nunca por debajo de 24 px** (suelo de texto de 25, AC-25-18, y de 30, D30-4; D24-15): el pie se alinea con ese mínimo aunque no sea texto necesario (regla 29). La tipografía y el panel son del art-director (Open Questions); estos números son el mínimo funcional de accesibilidad. Sin máquina de escribir: fundido de 250 ms† de entrada y 250 ms† de salida (100 ms con `reducir_movimiento`).
    **Convivencia con 26 (Subtítulos, regla 23 de 26; D24-17).** Mientras 26 tenga algún bloque visible, el pie se desplaza **hacia arriba** hasta quedar sobre el borde superior de los bloques actuales más `sub_hueco_px` (12†, de 26), con el fundido del propio pie (150 ms; 100 ms con `reducir_movimiento`); nunca solapa ni tapa un subtítulo. Si no cabe (tamaño grande + 2 bloques), el pie se coloca encima y se recorta a 2 líneas, nunca el subtítulo. El anillo y la etiqueta no se mueven (están sobre el objetivo, no en la banda). En el contexto `llamada` 24 está oculto (regla 2).
25. **Longitud.** Un texto > `texto_max_caracteres` (90†) no es un pie (7, regla 12): 24 lo recibe igualmente y lo muestra (hasta 3 líneas), pero **registra la advertencia** de datos en desarrollo.
26. **Solo en exploración.** Con el contexto ≠ `exploración` el pie se oculta y su reloj se congela. Al salir de `exploración` por un **modo de 7** o `sin control`, los pies de objeto (`retener = falso`) se **descartan** (no reaparecen obsoletos). Un pie con `retener = verdadero` (`UI_BOLSILLO_AYUDA`) se **mantiene pendiente** y se muestra al volver a `exploración` **sin caducidad por tiempo** (D24-8); solo se descarta si llega otro `mostrar_pie` con `retener = verdadero`, o si se carga una partida o cambia la escena (no se persiste). Así la ayuda, que 20 pide una sola vez, no se pierde por una lectura larga. Con la pausa abierta (`menú`) todo pie se congela y se reanuda con «pausa cerrada» (nombre de aviso común a todo el proyecto).
27. **`UI_BOLSILLO_AYUDA`.** Texto (de 18, **provisional**): «Atrás: revisar los papeles». 24 resuelve la acción `atrás` **sin asumir `Retroceso`**: la clave de 18 lleva el token `{accion:atrás}` ‡ (p. ej. «{accion:atrás}: revisar los papeles») que 24 sustituye por el glifo + texto de la asignación vigente de `atrás` en el dispositivo activo (regla 13): `[Clic der.] revisar…` con el valor por defecto de teclado y ratón (Entrada, tabla de acciones: `atrás` = clic derecho), `[B]` o el que sea con mando, o la asignación reasignada (Entrada R15 y R17: siempre hay al menos una asignación). Si 18 conserva la forma literal sin token, 24 muestra el texto tal cual (el nombre de la acción, no una tecla) y se registra la advertencia. Si `get_binding_label` falla, el token se sustituye por el nombre de la acción «Atrás».
28. **Una vez por sesión.** La política de «una sola vez» es de 20 (R23; 24 no mantiene bandera). 24 muestra el pie cada vez que se le pide.
29. **Importancia.** El pie nunca contiene información necesaria para avanzar (7, regla 12; 20, R23): 24 no ofrece historial ni relectura (fuera del slice, Open Questions de 7).

### E. Escala, resoluciones y ajustes leídos

30. **Escala.** Todas las medidas en px de este GDD son para 1080p y escalan con F2 (altura de la ventana; soporte de 720p a 2160p). En 16:9 o más estrecho los márgenes seguros del 5 % se aplican a ambos ejes; en ultraancho se anclan al área 16:9 central.
31. **Ajustes que lee** (de 6, vía avisos de cambio; 24 los aplica en el fotograma siguiente): `reducir_movimiento` (fundidos fijos de 100 ms), `icono_grande` ‡, `etiqueta_accion_visible` ‡ (los dos últimos, pendientes de alta en 6). `multiplicador_pie` y `pie_persistente` los lee 7 (vía `duracion_pie`), no 24; 24 solo recibe el resultado (`float` o `PERSISTENTE`).
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

### F3 · Vigencia del pie retenido

`pie_retenido_vigente = no_sustituido_por_otro_retener ∧ misma_partida_y_escena`. No hay umbral de tiempo (se retiró la caducidad de 10 s; D24-8).

**Ejemplo:** 20 pide el pie al entrar `I-04` durante una `lectura` de 25 s: aparece al volver a `exploración` con su duración completa (F5 de 7), igual que tras una lectura de 6 s.

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
| 1 Entrada y controles | **Dura** | Dispositivo activo, `get_binding_label(accion, dispositivo)` (1, regla 24), contexto actual, aviso «dispositivo de entrada cambiado»; no da nada | Dura desde la ronda 9 (D24-16): sin el glifo vigente 24 no puede decir qué pulsar. Mostrar el nombre de la acción (regla 27) es solo defensa ante fallo, no una dependencia opcional |
| 7 Interacción e inspección | **Dura** | `get_target()` (con `anillo_visible`), `duracion_pie`, aviso «interacción ejecutada» con `resultado` ampliado a `SIN_EFECTO`/`GESTO_RECHAZADO`/`TOQUE_CORTO`; llama a `mostrar_pie` / `ocultar_pie` | Contrato aplicado en 7 (reglas 12, 29 y 30; D7-73 a D7-75); 7 declara la dependencia dura |
| 18 Base de contenido narrativo | **Dura** | Textos de `UI_VERBO_*`, `OBJ_<id>`, `UI_BOLSILLO_AYUDA` (con token `{accion:atrás}` ‡) | Solo lectura; claves ausentes: reglas 16 y de pie |
| 20 Documentos y bolsillo | Consumidor | 20 llama a `mostrar_pie(UI_BOLSILLO_AYUDA, …, retener = verdadero)` (R23 de 20); 24 no lee nada de 20 | 20 declara 24 como blanda |
| 6 Ajustes persistentes | Blanda (valores iniciales si no están) ‡ | `reducir_movimiento`, `icono_grande` ‡, `etiqueta_accion_visible` ‡ | `multiplicador_pie`/`pie_persistente` los lee 7 |
| 26 Subtítulos | Blanda (convivencia) | 26 reserva la banda inferior; 24 sube el pie sobre ella (regla 24; regla 23 de 26); 24 no lee nada de 26 | 24 nombra a 26 desde la ronda 9; 26 ya lo exigía |
| 8, 9, 10, 19, 22, 28 | Indirecta (vía 7) | Sus manejadores (`can_interact`, `interact`, `etiqueta`) llegan a 24 solo como `get_target()`, avisos de 7 y pies de 7 | 24 no los conoce ni los llama |
| 25 / 30 (Pausa, Accesibilidad) | Consumidores | Ofrecen `reducir_movimiento`, `icono_grande`, `etiqueta_accion_visible`; 30 fija el criterio de «destello» (regla 18, AC-30-13) y el suelo de texto (D30-4) que 24 acata | Pantallas fuera de 24 |
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
| `pulso_min_intervalo_ms` | 340† | 334–600 | Tope de fotosensibilidad (≤ 3 pulsos/s); no bajar de 334 |
| `etiqueta_offset_px` | 12† | 8–24 | Separación anillo-etiqueta |
| `pie_ancho_max` | 0,60† | 0,5–0,8 | Líneas del pie |
| `pie_alto_texto_px` / `pie_alto_min_px` | 28† / 24 | 24–36 / 24 fijo (suelo de 25 y 30) | Legibilidad (F2) |
| `pie_panel_opacidad` | 0,85† | 0,75–0,95 | Contraste del pie (≥ 4,5:1 sobre blanco puro) |
| `pie_fade_ms` | 250† | 100–400 | Entrada y salida del pie |
| `ui_escala_min` / `ui_escala_max` | 0,67 / 2,0 | 0,5–0,75 / 1,5–3,0 | Resoluciones soportadas (F2) |
| `etiqueta_accion_visible` ‡ | falso | falso/verdadero | Accesibilidad (6) |
| `icono_grande` ‡ | falso | falso/verdadero | Accesibilidad (6) |

## Acceptance Criteria

- **AC-24-01 (R1–R3, L + V)**: **GIVEN** un objetivo válido en `exploración`, **THEN** el anillo se dibuja en el centro de la pantalla en el fotograma siguiente al primero en que `get_target()` ≠ nulo, con fundido de 250 ms; **WHEN** pasa a nulo, **THEN** desaparece con fundido de 150 ms; **GIVEN** sin objetivo, **THEN** no hay ningún elemento en pantalla (sin punto de mira).
- **AC-24-02 (R2, L)**: **GIVEN** el contexto en `menú`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada` o `sin control`, **THEN** anillo y etiqueta están ocultos aunque `get_target()` devolviera un valor.
- **AC-24-03 (R5, V)**: **GIVEN** el cambio de objetivo `V05` → `C05` sin pasar por nulo, **THEN** el anillo no baja de su opacidad y la etiqueta (si activa) hace un fundido cruzado de 120 ms.
- **AC-24-04 (R6, F1, L)**: **GIVEN** `largo`, `anillo_visible` y `p = 0,6`, **THEN** el relleno es 216° horario desde las 12 h; **GIVEN** `anillo_visible` falso, **THEN** no hay relleno; **WHEN** se suelta antes de `t_hold`, **THEN** el relleno se vacía en 100 ms.
- **AC-24-05 (R7, V)**: **GIVEN** `interactuar` procesado con `HECHO`, **THEN** el anillo pasa de 80 % a 100 % y vuelve en 120 ms, sin escala ni desplazamiento.
- **AC-24-06 (R17–R19, L + V)**: **GIVEN** `SIN_EFECTO` (lector `C06` sin tarjeta), gesto rechazado o toque corto sobre `A04`, **THEN** el anillo hace un pulso de 80 % a 40 % y vuelve en 120 ms, iniciado ≤ 100 ms tras el aviso de 7, y **solo 7** reproduce `SFX_CLICK_SUBTLE`; **GIVEN** enfriamiento o transición, **THEN** no hay pulso; **GIVEN** 10 pulsaciones en 1 s sobre `C06` sin tarjeta, **THEN** el anillo hace como máximo 3 pulsos y el intervalo entre inicios de pulso es ≥ 334 ms.
- **AC-24-07 (R20, R32, V, PV)** — **NOT SOURCEABLE** (la referencia `docs/engine-reference/godot/` no documenta ningún filtro de daltonismo del motor; no se afirma que exista en 4.7; Open Questions 10): **GIVEN** una captura del anillo, el pulso y el pie convertida a escala de grises y simulada con una herramienta externa fija (la que anote el informe de prueba) para deuteranopia, protanopia y tritanopia, **THEN** todos los estados (presencia, progreso, rechazo, pie) siguen distinguiéndose y ningún estado usa rojo.
- **AC-24-08 (R10–R13, L)**: **GIVEN** `etiqueta_accion_visible` verdadero, **THEN** la etiqueta muestra `[glifo] + texto` de la clave de `get_target().etiqueta` y el glifo corresponde a la asignación vigente de `interactuar` del dispositivo activo; **GIVEN** `etiqueta_accion_visible` falso (valor inicial), **THEN** no se dibuja etiqueta.
- **AC-24-09 (R14, L)**: **GIVEN** una etiqueta visible, **WHEN** el dispositivo activo cambia de teclado a mando, **THEN** el glifo cambia en el fotograma siguiente y `get_binding_label` se consulta una sola vez por cambio.
- **AC-24-10 (R27, L)**: **GIVEN** `UI_BOLSILLO_AYUDA` solicitado con `atrás` en su asignación por defecto de teclado, **THEN** el pie muestra el nombre de esa asignación (hoy «Clic der.» en teclado y ratón) leído de Entrada; **GIVEN** `atrás` reasignada a otra tecla o botón, **THEN** el pie muestra la nueva; **THEN** ningún literal «Retroceso» ni «Backspace» existe en el código ni en los datos de 24 (búsqueda en el repositorio).
- **AC-24-11 (R27, L)**: **GIVEN** `get_binding_label` no disponible o clave de 18 sin token, **THEN** el pie se muestra con el nombre de la acción «Atrás» (o el texto tal cual) y se registra una advertencia, sin error en pantalla.
- **AC-24-12 (R21–R23, L)**: **GIVEN** un pie en pantalla, **WHEN** llega otro, **THEN** lo sustituye con fundido de 150 ms; **GIVEN** `pie_persistente`, **THEN** el pie permanece hasta que `get_target().id` cambia respecto del inicial o llega otro pie.
- **AC-24-13 (R22–R23, L)**: **GIVEN** `mostrar_pie(clave, 5,29)`, **THEN** el pie desaparece a los 5,29 s ± 1 fotograma de tiempo de juego y la pausa detiene el reloj (el cálculo 30 caracteres → 5,29 s es F5 de 7, AC-15 de 7).
- **AC-24-14 (R24, V)**: **GIVEN** 720p, 1080p y 2160p, **THEN** el pie queda dentro de los márgenes seguros del 5 %, el texto mide ≥ 24 px físicos a 1080p (≥ 24 px × `ui_scale` en las otras resoluciones, sin bajar de 24 px; F2) y el contraste texto/panel es ≥ 4,5:1 medido en captura con el pie sobre un fondo de prueba blanco puro `#FFFFFF` **y** negro puro (el peor caso es el blanco), calculando la razón de luminancia relativa WCAG entre el color del texto y el color efectivo del panel en la captura.
- **AC-24-15 (R26, L)**: **GIVEN** un pie de objeto activo, **WHEN** se abre una `lectura`, **THEN** el pie se descarta y no reaparece al cerrarla; **GIVEN** `UI_BOLSILLO_AYUDA` pedido durante una `lectura`, **THEN** aparece al volver a `exploración` tanto con una lectura de 6 s como con una de 25 s (sin caducidad, F3); **GIVEN** una partida cargada o cambio de escena con el pie pendiente, **THEN** se descarta.
- **AC-24-16 (R5, R24, V)**: **GIVEN** `reducir_movimiento` activo, **THEN** todos los fundidos del anillo, la etiqueta y el pie duran 100 ms.
- **AC-24-17 (R4, V)**: **GIVEN** `icono_grande` activo, **THEN** el anillo mide 48 px a 1080p, trazo 3 px, opacidad 100 %, con contorno de 2 px.
- **AC-24-18 (Accesibilidad, L + V)**: **GIVEN** teclado y, por separado, mando, **THEN** en cada dispositivo se comprueba esta lista: anillo (AC-24-01), etiqueta con `etiqueta_accion_visible` (AC-24-08), pie de objeto (`OBJ_C06`), pie `UI_BOLSILLO_AYUDA` (AC-24-10) y pulso de rechazo (AC-24-06), con el glifo del dispositivo activo; **THEN** ningún efecto de 24 supera 3 cambios de luminosidad por segundo (se cubre con el tope de AC-24-06).
- **AC-24-21 (R22–R23, L)**: **GIVEN** `pie_persistente` verdadero y `UI_BOLSILLO_AYUDA` pedido por 20 con `duracion_pie` = `PERSISTENTE`, **THEN** el pie no caduca por tiempo y se oculta al cambiar `get_target().id` respecto del que había cuando se dibujó (no cuando se pidió) o al llegar otro pie.
- **AC-24-19 (R8, L)**: **GIVEN** un manejador con `can_interact = NO`, **THEN** 24 no dibuja anillo, pulso ni pie para ese objeto.
- **AC-24-20 (R9, V)**: **GIVEN** `leer` en modo «alternar», **THEN** el relleno permanece visible entre las dos pulsaciones y se vacía al cancelar con `atrás`.
- **AC-24-22 (R24, V + I)**: **GIVEN** un bloque de subtítulo de 26 visible y un pie pedido, **THEN** el pie queda sobre el borde superior del bloque más `sub_hueco_px` sin solaparlo, con fundido de 150 ms (100 ms con `reducir_movimiento`); con tamaño grande + 2 bloques el pie se recorta a 2 líneas y el subtítulo queda íntegro.
- **AC-24-23 (R1, R13, R19, R22–R23, I)**: **GIVEN** 7 con `get_target()` que incluye `anillo_visible`, el aviso «interacción ejecutada» con los cuatro valores de `resultado` y `duracion_pie(clave)`, y 1 con `get_binding_label`, **THEN** 24 funciona contra esos contratos sin adaptadores (prueba de integración de la dependencia dura; casos en 7 AC-15b, AC-36b y AC-36c y en 1 AC-E19).

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D24-1 | Anillo fijo en el centro de la pantalla | Proyectarlo sobre el objeto | El rayo sale del centro; la proyección salta con el temblor y acerca el icono a una fuente de luz del mundo (art bible §3.3) |
| D24-2 | Etiqueta de acción **apagada por defecto** (`etiqueta_accion_visible` ‡) | Siempre visible (lo sugiere UI Requirements de 7) | Art bible §7.3 la fija desactivada por defecto; slice §16 pide «icono discreto»; pilar Autonomía como progresión. 7 queda alineado en «Cambios requeridos» |
| D24-3 | `{accion:atrás}` como token resuelto contra Entrada, con respaldo al nombre de la acción | Escribir «Retroceso» en el texto de 18 o mostrar solo «Atrás» | `atrás` es reasignable (R15 de 1): un literal mentiría; un nombre sin glifo no dice qué pulsar |
| D24-4 | Glifo siempre con texto; nunca solo icono | Solo glifos gráficos | Accesibilidad (sin depender de forma/color del glifo) y lector de pantalla futuro |
| D24-5 | Rechazo = pulso de opacidad + `SFX_CLICK_SUBTLE` de 7 (+ pie si lo hay) | Temblor o color de error; sonido propio de 24 | Art bible: sin rojo, temblor reservado a puzles; una sola fuente de audio (7/23); pilar Tensión sin castigo |
| D24-6 | No hay estado «solo punto» en `exploración` | Dibujar un punto permanente | Slice §16 y art bible §7.3: «no hay punto de mira permanente»; ver Open Questions |
| D24-7 | Un solo hueco de pie, sin cola; el último gana | Cola de pies | Coherencia con 7, regla 12; un pie es ambiente, perder uno no cuesta |
| D24-8 | Pies de objeto se descartan al abrir un modo; solo los marcados `retener` (ayuda de 20) esperan, **sin caducidad por tiempo** (revisado en ronda 1) | Caducar el retenido a los 10 s† (borrador); retener todos / descartar todos | Un pie obsoleto confunde, pero la ayuda de 20 es la única enseñanza de `repasar_bolsillo`, se pide una vez por sesión y 20 no reintenta: caducarla la perdería justo tras una lectura larga (pilar de guía sin menú) |
| D24-9 | 24 consulta `get_target()` por fotograma y el rechazo llega ampliando el `resultado` del aviso existente «interacción ejecutada» ‡ (`SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO`) | Aviso nuevo «interacción sin efecto» (borrador: duplicaba `SIN_EFECTO`); aviso por cambio de objetivo | Regla 29 de 7: una señal por fotograma saturaría el bus; el rechazo es discreto y sí merece aviso |
| D24-10 | La duración la calcula el llamador con F5 de 7 (`duracion_pie`) | 24 reimplementa F5 | Una sola fórmula, un solo dueño (7); 24 solo dibuja |
| D24-12 | Pulso de rechazo limitado a ≥ 340 ms† entre inicios (≤ 2,9/s), independiente del enfriamiento de 7 | Reformular solo el AC con la definición de destello (borrador: 4 pulsos/s) | Cumple el umbral de 3/s por diseño y no depende de la interpretación del área; el sonido de 7 no cambia |
| D24-13 | `pie_panel_opacidad` 0,85† y contraste garantizado sobre blanco puro | Mantener 0,70† con contorno en el panel | Con 0,70 el peor caso caía a ≈ 4,3:1; subir opacidad es más sencillo y no añade elementos al panel (art-director puede sustituirlo por contorno) |
| D24-14 | Token `{accion:atrás}` con el identificador de acción de Entrada (con tilde); la gramática de tokens la fija 18 | `atras` sin tilde; `repasar_bolsillo` como identificador | `atrás` es la acción reasignable (R23 de 1: `repasar_bolsillo` deriva de ella); mismo identificador en 1, 7 y 20 |
| D24-11 | `repasar_bolsillo` sin feedback propio de 24 | Pulso o mensaje si no hay papeles | 20 (R19/R20) fija «sin sonido, sin mensaje»; el pie de ayuda ya enseña la acción una vez |
| D24-15 | Pie con suelo de 24 px: `pie_alto_min_px` = 24 (antes 20†); AC-24-14 ≥ 24 px | Mantener 20 px («el pie no es texto necesario») | Ronda 9: 25 AC-25-18 y D30-4 fijan 24 px; un suelo menor en el pie contradice el criterio de 30 sin ganar nada |
| D24-16 | 24 depende de forma **dura** de 7 y de 1; los cambios que 24 exige se **aplican** en 7 (`anillo_visible`, `resultado` ampliado, `duracion_pie`, `mostrar_pie`/`ocultar_pie`: D7-73 a D7-76) y en 1 (`get_binding_label`: D34, AC-E19); se quitan las ‡ cerradas | Recortar el contrato de 24 (sin etiqueta ni pie) o dejarlo ‡ | R9-B4: sin el glifo vigente y sin el rechazo de 7 el prompt no cumple el slice §16; el contrato ya estaba redactado y no contradice reglas vigentes de 7 ni de 1. Quedan ‡ solo `icono_grande`, `etiqueta_accion_visible` (6) y el token `{accion:atrás}` (18) |
| D24-17 | El pie sube sobre la banda de subtítulos de 26 (regla 24, AC-24-22); 24 nombra a 26 | Que 26 reserve toda la banda fija y el pie se recorte | 26 (regla 23) ya lo fija y lo marca «cambio requerido en 24»; el subtítulo manda sobre el pie (ambiente) |
| D24-18 | «Destello» = definición de 30 (regla 18, AC-30-13); 24 no fija otra | Medida propia del anillo | Una sola definición de proyecto; el tope de 340 ms de D24-12 queda por debajo de 3/s con cualquier definición |
| D24-19 | AC-24-07 pasa a NOT SOURCEABLE + PV: no se afirma un filtro de daltonismo del motor; se usa herramienta externa anotada | Citar «filtros de daltonismo del motor» | La referencia del motor no los documenta (no se afirma una API sin fuente) |
| D24-20 | Convención de nombres: `repasar_bolsillo` y «pausa cerrada» | `pause_closed`, `revisar_bolsillo` | Cierra la discrepancia de nomenclatura de la ronda 9 (7 y 1 la siguen) |

## Open Questions

1. **Etiqueta apagada por defecto frente a descubribilidad.** Con la etiqueta apagada, un objeto solo `leer` se «explica» por el anillo que se rellena y el pulso al toque corto. *Decisión por defecto:* D24-2. Validar en el primer playtest (slice §23.4) si el jugador descubre `leer`; si no, abrir una pista de contexto única («Mantén para leer») en 18, no encender la etiqueta global. Afecta al tono y a la guía del jugador: **para el director creativo**.
2. **Estado «solo punto»** (art bible §7.3) frente a «sin punto de mira». *Defecto:* no se usa en `exploración` (D24-6). **Decide el usuario** (roza tono y pilar «el espacio expresa la emoción»): el art bible se contradice a sí mismo (define «solo punto» y a la vez prohíbe el punto permanente); art-director decide también si sirve para otro contexto (p. ej. vistas).
3. **Tipografía, panel del pie y glifos** (atlas de teclado/mando): sin definir en el art bible; los números de las reglas 24 y 12 son mínimos funcionales †. Dueño: art-director.
4. **Ajuste de tamaño de UI y de texto:** no existe en 6; F2 solo escala con la ventana. Si 30 (Accesibilidad) añade un multiplicador de escala, F2 lo absorbe.
5. **Lector de pantalla (AccessKit, Godot 4.5+):** exponer pie y etiqueta como región viva queda fuera del slice (MVP). Defecto: no; sí se cumple la regla de «glifo siempre con texto».
6. **Clave de `V08` «Recoger» y `UI_VERBO_RESPONDER`:** 7 y 19 los nombran, 18 no los lista; sin clave, 24 no dibuja etiqueta (regla 16).
7. **`V08` con dos pies** (`OBJ_V08_SIN_RESULTADOS`, `OBJ_V08_YA_IMPRESA`) frente a «una clave `texto` por objeto» (regla 3 de 7): pendiente de 7/19; 24 es agnóstico (acepta cualquier clave que 7 pase).
8. **Prioridad de la ayuda de bolsillo** frente a un pie de objeto simultáneo: hoy gana el último. Si resulta que 20 la pierde a menudo, dar `retener` más prioridad. La pérdida por caducidad ya está cerrada (D24-8: el retenido no caduca). Queda abierto, por si 20 necesita saberlo: que 24 avise a 20 de que el pie retenido se descartó (carga/escena/otro `retener`) para que 20 no marque la ayuda como dada. *Defecto:* sin aviso; 20 la pide una vez por sesión.
9. **Tipo de `PERSISTENTE`** (centinela numérico `-1` o valor propio): detalle de implementación; ADR de UI/interacción. Redondeo de F2 y «ancho ≥ ultraancho anclado a 16:9» dependen de cómo Godot 4.7 informe el tamaño del viewport: **no verificado**, apuntado a ADR; este GDD no afirma ninguna API.
10. **Filtros de daltonismo del motor (AC-24-07, PV):** comprobar en el editor 4.7 si existe una simulación nativa; si no, fijar la herramienta externa. Propietario: `godot-specialist` / QA.
11. **Consumidores del aviso ampliado:** con `resultado ≠ HECHO` el aviso «interacción ejecutada» también llega a 21, 23 y 28, que hoy reaccionan a él sin filtrar (p. ej. 21 sobre `V02`, AC-21-15). Hasta que sus GDD digan «solo `HECHO`», 7 (D7-74) les exige filtrar por `resultado`. *Alternativa:* aviso aparte «interacción rechazada» solo para 24 (descartada en D24-9 por duplicar `SIN_EFECTO`). Pendiente de 21, 23 y 28.

## Cambios requeridos en otros GDDs

Este GDD no ha editado ningún archivo existente. Cambios a aplicar (los coordina `producer`):

| GDD | Cambio | Motivo |
|---|---|---|
| `systems-index.md` | Fila 24 (la numerada «22» en su tabla de Progress/Order, corregir numeración): estado «Borrador (lote autónomo)», ruta `design/gdd/prompt-de-interaccion.md`; dependencias 1 (blanda), 7 (dura), 18 (dura), 6 (blanda ‡); consumidor 20 | Existe el GDD |
| `entrada-y-controles.md` (1) | **APLICADO (ronda 9, D34):** regla 24 `get_binding_label` con orden determinista, AC-E19, fila 24 «Dura»; AC-03 «V» cerrado con 24 | Contrato de 24 (W-4) |
| `interaccion-e-inspeccion.md` (7) | **APLICADO (ronda 9, D7-73 a D7-76):** (a) `get_target()` añade `anillo_visible`; (b) ampliar el dominio de `resultado` de «interacción ejecutada» a `HECHO`, `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` (sin aviso aparte); (c) `duracion_pie(clave) -> float \| PERSISTENTE`, aplicando `pie_persistente`; (d) llama a `mostrar_pie`/`ocultar_pie` de 24 y alinea UI Requirements: etiqueta apagada por defecto (D24-2); (e) recoger en F5 la norma de contar cada token `{…}` como un carácter | Contrato de 24 (W-2, W-3, W-5) |
| `base-de-contenido-narrativo.md` (18) | Fijar en un solo lugar la gramática de tokens `{accion:<id>}` con el identificador de Entrada (`atrás`); `UI_BOLSILLO_AYUDA` con token: «{accion:atrás}: revisar los papeles» (texto provisional); claves `UI_VERBO_RECOGER` y `UI_VERBO_RESPONDER` si se mantienen; fila 24 con el token | Sin asumir `Retroceso` (W-5) |
| `documentos-y-bolsillo.md` (20) | R23: «pide a 24» = `mostrar_pie(UI_BOLSILLO_AYUDA, duracion_pie(clave), retener = verdadero)`; el pie retenido ya no caduca por tiempo (D24-8); pasar `PERSISTENTE` tal cual | Contrato concreto (W-1, W-3) |
| `ajustes-persistentes.md` (6) | **Sigue pendiente (otro agente):**  Nuevos ajustes de accesibilidad `icono_grande` y `etiqueta_accion_visible` (bool, falso); **corregir la fila de dependientes 24**: 24 lee solo `reducir_movimiento`, `icono_grande`, `etiqueta_accion_visible`; `multiplicador_pie` y `pie_persistente` los lee 7 (que pasa el resultado a 24); añadir 24 a la columna de consumidores de `reducir_movimiento`; recuento de «restablecer todos» de 12 a 14 (la cifra final la fija 6; 30 cuenta 18) | Art bible §4.5/§7.3; reciprocidad (B-2) |
| `menu-de-pausa` (25) / `opciones-de-accesibilidad` (30) | Ofrecer los dos ajustes nuevos (los dos GDD ya existen) | Pantallas |
| `design/art/art-bible.md` | Confirmar rótulo con etiqueta (glifo en línea) bajo el anillo frente a «nunca flotando junto al anillo»; definir panel y tipografía del pie; resolver la contradicción interna §7.3 («solo punto» frente a «no hay punto de mira permanente») | Open Questions 2 y 3 (W-7) |

## Entradas para el registro

| Tipo | Nombre | Valor / descripción | Fuente |
|---|---|---|---|
| constante | `PROMPT_RING_PX` † | 28 estándar / 48 grande (1080p) | reglas 4, F2 |
| constante | `PROMPT_PULSE_MS` | 120 (aceptado y rechazo) | reglas 7, 18 |
| constante | `PROMPT_REJECT_MIN_OPACITY` † | 0,40 | F1 |
| constante | `PROMPT_PULSE_MIN_INTERVAL_MS` † | 340 (tope de fotosensibilidad) | regla 17 |
| constante | `PROMPT_UI_SCALE_RANGE` † | 0,67–2,0 sobre 1080p | F2 |
| fórmula | `ui_scale` | `clamp(altura/1080, 0,67, 2,0)` | F2 |
| ajuste | `icono_grande` ‡ | bool, falso (6) | regla 4 |
| ajuste | `etiqueta_accion_visible` ‡ | bool, falso (6) | regla 11 |
| aviso | «interacción ejecutada» (dominio de `resultado` ampliado, 7 regla 29) | `HECHO`, `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO`; emite 7, consume 24 | regla 19 |
| API | `mostrar_pie` / `ocultar_pie` | las llaman 7 y 20; dueño 24 | regla 22 |
| API | `get_binding_label` | dueño 1 (regla 24); consume 24 | regla 13 |
| token de texto | `{accion:atrás}` ‡ | sustituido por 24 (glifo + texto vigente); gramática en 18 | regla 27 |
| regla | `prompt_no_audio` | 24 no emite audio; `SFX_CLICK_SUBTLE` es de 7 | regla 17 |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote autónomo): anillo, etiqueta, rechazo, pie y `UI_BOLSILLO_AYUDA` sin asumir `Retroceso`. Pendiente de revisión independiente |
| 2026-11-09 | Ronda de corrección 1 (revisión independiente): B-1 tope de 340 ms entre pulsos (D24-12); B-2 reparto de lectura de ajustes aclarado y fila de 6 a corregir; B-3 panel 0,85 y AC con fondo blanco (D24-13); W-1 pie retenido sin caducidad (D24-8, F3); W-2 sin aviso nuevo (D24-9); W-3 `duracion_pie` devuelve `PERSISTENTE` + AC-24-21; W-4 ejemplo «Clic der.»; W-5 token con tilde (D24-14); W-7 art bible a Cambios; W-8 justificación; W-9 ACs 07/13/18 reescritos. W-6 (índice) ya figura en Cambios requeridos. Pendiente de re-review |
| 2026-11-10 | Ronda de corrección 9 (R9-B4, `gdd-cross-review-2026-11-10.md`; avisos de `reviews/cross-review-r10-*`): contrato con 7 y 1 aplicado y ‡ cerradas (D24-16); suelo de pie 24 px (D24-15); pie sobre subtítulos de 26 y 26 en Dependencies (D24-17, AC-24-22); «destello» de 30 (D24-18); AC-24-07 NOT SOURCEABLE + PV (D24-19); 1 pasa a dependencia Dura; nomenclatura (D24-20); AC-24-23; Open Questions 10 y 11. Pendiente de re-review |
