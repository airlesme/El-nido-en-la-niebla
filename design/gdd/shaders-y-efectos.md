# Shaders y efectos de superficie (sistema 29)

> **Status**: Revisado (ronda de corrección 10) — pendiente de re-review
> **Author**: Technical Artist (lote autónomo)
> **Last Updated**: 2026-11-10
> **Implements Pillar**: Información incompleta (el cristal y el espejo muestran solo lo que la luz o el ángulo permiten; ningún efecto añade pistas que no estén en los datos) · Autonomía como progresión (las ayudas visuales las pide el jugador y nunca resuelven) · El espacio expresa la emoción (superficies frías, sobrias, legibles; sin destellos) · Tensión sin castigo (sin parpadeos, sin avisos de fallo; `reducir_movimiento` respetado)

## Summary

Los shaders y efectos de superficie dan forma visual a lo que los puzles 2 y 5 deciden: el **cristal del memorando** (fragmentos F1–F3 y sello revelados por las lámparas, vista previa en espejo, halo del haz), el **espejo de la diferencia** (foto reflejada que rota con θ, superposición `FADE` y contorno `OUTLINE` de Vera) y los resaltados de pista de 9 (`HIGHLIGHT`, `MARK_LIT`, marcas del suelo). El sistema es **solo presentación**: no escribe hechos, no decide cuándo se ve nada ni lee estado de puzle; recibe órdenes («enciende F2», «contorno de Vera, 2,0 s») y las dibuja. Se entrega en dos niveles: una **versión provisional sin shader** (materiales estándar y texturas, MVP, sirve para el prototipo temprano del cristal) y la versión final con tres shaders `.gdshader` baratos, sin lectura de pantalla, pensados para Forward+ (el renderer fijado en `project.yaml`; Compatibility no es objetivo del slice y no se afirma nada sobre él).

> **Quick reference** — Layer: `Presentation` · Priority: `Vertical Slice` · Key deps: `12 Puzle 2`, `15 Puzle 5` · Blandas: `9 Marco de puzles` (órdenes de pista/resolución), `6 Ajustes` (`reducir_movimiento`, `reducir_sobresaltos` no se lee) · Comparte superficie con: `28 Atmósfera reactiva` (reflejo del cristal) · Escribe hechos: nada · Presupuesto: ≤ 0,5 ms GPU en 1080p con todo activo

## Overview

El slice (B.2, B.5, C.5) necesita que dos superficies hagan el trabajo del puzle: un cristal oscuro donde aparece texto al mover una luz, y una foto reflejada que solo coincide con otra en un ángulo. En ambos casos **la legibilidad es el requisito**, no el adorno: si el jugador no puede leer F1–F3 en el cristal, el puzle P2 no existe (riesgo «Technical» del índice). Por eso este GDD fija primero la legibilidad (contraste, tamaño de glifo, sin dependencia de color) y después la técnica.

**Qué cubre (alcance).**

| Efecto | Quién lo pide | Superficie | Shader |
|---|---|---|---|
| Fragmentos F1–F3 y sello (fundido 0,8 s) | 12 (R11, R14, R21) | Cristal `B04` | `spatial_surface_glass_memo` |
| `MIRROR_PREVIEW` (F1 en espejo, zona neutra) | 12 (pista N1) | Cristal `B04` | ídem (`mirrored = true`) |
| `BEAM_HALO` (anillo en el punto actual del haz) | 12 (pista N3) | Cristal `B04` | ídem |
| `FLOOR_MARKS` (números 1–4 y marca actual) | 12 (pista N2) | Marcas `B08` | material emisivo (sin shader propio) |
| Foto reflejada con θ | 15 (regla 7) | Reflejo `D01c/reflection` | `spatial_surface_mirror_photo` |
| `FADE` (superposición) y `OUTLINE` (Vera) de la resolución | 15 (regla 17, F8 de 9) | Reflejo y foto de la caja | ídem + `spatial_fx_outline_mask` |
| `HIGHLIGHT` no interactivo (P1 `stamp_N`, P5 `reflection`/`box_photo`) | 9 (regla 4b-m) | Cualquier `visual_elements` o `decor` | `spatial_fx_outline_mask` |
| `MARK_LIT` (marca 40°, persistente en sesión) | 15 (nivel 3), 9 (D9-72) | `D01c/mark_40` | `spatial_fx_outline_mask` (modo `persistent`) |

**Qué no cubre.** El reflejo retardado del jugador en el cristal y la atmósfera general son de 28 (regla 5 y Dependencies); los resaltados de objetos **interactivos** (el cursor/outline de selección de 7 y 8 es UI/HUD de 8, no de este sistema); la animación de tapas (10); el audio (23).

## Player Fantasy

El cristal «habla»: al girar la lámpara, una frase aparece despacio, nítida, como si hubiera estado siempre ahí, escrita al revés. Quien juega no piensa en un efecto, piensa en «ha salido algo». En el espejo, las dos fotos que no cuadraban se encajan en un solo gesto y, sin sonido de acierto, una silueta se perfila: Vera estuvo en la sala. Los resaltados de ayuda son un dedo que señala, no una alarma: aparecen con calma, se retiran con calma, y se ven igual para quien no distingue el rojo del verde y para quien ha pedido menos movimiento.

## Detailed Rules

### A. Principios y límites

1. **Solo presentación.** 29 no escribe hechos ni avisos, no evalúa soluciones y no lee inventario ni correos. Cada efecto es una orden (con parámetros) que alguien con autoridad emite y 29 dibuja. Una orden idéntica produce siempre el mismo resultado visual (determinista salvo `TIME`).
2. **La legibilidad manda.** Ningún efecto (película, reflejo, halo, ruido) puede reducir el contraste del texto del cristal por debajo de F29-2. Si hay conflicto entre estética y lectura, gana la lectura.
3. **Sin información extra.** Ningún efecto revela la solución: `BEAM_HALO` marca el punto **actual**, `MIRROR_PREVIEW` cae en una zona neutra, el contorno de Vera solo aparece en `RESOLVING`, y no existe «imán» ni brillo que crezca cerca de θ* (regla 7 de 15).
4. **Sin dependencia de color.** Toda señal se distingue por forma, patrón o luminancia, nunca solo por tono. El color (cálido de las lámparas) es refuerzo.
5. **Sin destellos.** Definición: un *destello* es un **par de transiciones opuestas** (subida y bajada, o al revés) de más de 0,25 de luminancia relativa dentro de una ventana de 333 ms, o un pulso por encima de 2 Hz (criterio de 3 destellos/s de WCAG). Una **transición única y monótona** (fundido de entrada o de salida, sin vuelta dentro de 333 ms) puede durar 100 ms aunque supere 0,25, porque `reducir_movimiento` de 9 (14b) manda 100 ms y no se puede alargar. Para que no se encadenen dos opuestas en < 333 ms, `MIRROR_PREVIEW` mantiene ≥ 333 ms entre su entrada y su salida y `HIGHLIGHT` no repite pulso con `reducir_movimiento`. Esto cumple `reducir_sobresaltos`, que 29 **no necesita leer** (6 lo entrega solo a 23 y 28).
6. **Sin lectura de pantalla.** Ningún shader de 29 usa `hint_screen_texture` ni `hint_depth_texture` (restricción negativa; el coste de evitar un pase completo es **NOT SOURCEABLE** ‡: `rendering.md` no cubre los `hint_*`). Todos son `shader_type spatial`.

### B. Inventario de shaders

Nombres `[type]_[category]_[name].gdshader`, en `assets/shaders/`; un shader por archivo; funciones comunes en `assets/shaders/include/fx_common.gdshaderinc` vía `#include` (**no verificado** en 4.7.2: se comprueba en el spike de la regla 44; si falla, se duplican las utilidades).

7. **`spatial_surface_glass_memo.gdshader`** (cristal `B04`). **Un único material y un único pase** (`blend_mix`, `render_priority` 0 ‡ NOT SOURCEABLE: `blend_mode` y `render_priority` no figuran en `rendering.md`; ver regla 41) que compone en el shader, de abajo arriba: (a) película del cristal (color casi negro frío, `L_bg` ≤ 0,06; ruido suave de 1 muestra, opcional); (b) fragmentos: una textura atlas con F1, F2, F3 y sello, cada uno con su alfa (`frag_alpha`, regla 11) más el **residuo latente** de la regla 18; (c) vista previa en espejo; (d) halo, mezclado con `mix` dentro del shader (no `blend_add`). El **reflejo de 28 no está en este material**: es un proxy de geometría espejada de 28, un draw call aparte (regla C). Máximo 3 muestras de textura por píxel (atlas, máscara de halo, película).
8. **`spatial_surface_mirror_photo.gdshader`** (reflejo y foto de la caja de P5). Muestra una foto con rotación UV `theta_deg` alrededor del centro del marco; la foto de la caja usa `theta_deg = 0`. Una sola muestra de textura. **No contiene ningún término dependiente de θ distinto de la rotación** (ni brillo, ni enfoque, ni desenfoque, ni viñeta: regla 7 de 15).
9. **`spatial_fx_outline_mask.gdshader`** (contorno y resaltado). Para elementos planos (fotos, sellos, marcas): dibuja un contorno sobre una **máscara de silueta** (`outline_mask`, textura de 1 canal pregenerada por arte **sin dilatar**; la dilatación se hace en el shader con ≤ 4 muestras extra, de modo que el grosor `w_px` de F29-5 sea realmente independiente de la resolución) o, para mallas, contorno por casco invertido (`cull_front`, extrusión en vértice). Dos modos: `PULSE` (resaltado temporal) y `PERSISTENT` (`MARK_LIT`).
10. **Efecto sin shader propio:** `FLOOR_MARKS` (`B08`) se resuelve con `StandardMaterial3D` y emisión animada por `Tween`; el número 1–4 es geometría/textura que ya existe y solo cambia `emission_energy_multiplier`. No justifica un `.gdshader`.
11. **Parámetros.** Todos los parámetros artísticos son `uniform` con tipo y rango, agrupados con `group_uniforms`; los que cambian por instancia son `instance uniform` **escalares o `vec4`, nunca arrays** (la alfa de los cuatro fragmentos es un `instance uniform vec4 frag_alpha`; `theta_deg` e intensidad del contorno, escalares). Que `instance uniform` se comporte así en 4.7.2 **no está verificado**: se comprueba en el spike (regla 44). **Fallback como regla:** si el spike falla, un `ShaderMaterial` por instancia (material único por superficie, que no se comparte). Los constantes (colores, grosor, frecuencia) son `uniform` normales leídos de datos. Nada se fija a mano en el shader (`coding-standards`: valores en datos).

### C. Cristal compartido con 28 (contrato)

12. **Propiedad.** 29 posee `mat_glass_memo` (película, fragmentos, previa, halo; regla 7). 28 posee el **reflejo**: un **proxy de geometría espejada alimentado por `pose_con_retardo` (1 draw call)**, sin `SubViewport` ni `reflection_tex` (DT-3 de 28). 28 no toca la película, los fragmentos ni el halo; 29 no dibuja el reflejo. **Dueño único del reflejo: 28** (decisión de la ronda 9, alineada con 28 R13): en `B04` el reflejo de 28 es la `ReflectionProbe` de la sala **sin retardo** (el proxy retardado `pose_con_retardo` es solo de `C02`, y nunca de P2/P5); 29 aporta el shader y el material `mat_glass_memo` que lo compone bajo el texto y publica el tope `reflection_strength_max`. Donde las reglas 13–14, F29-2, AC-3 y AC-16 dicen «proxy de reflejo de 28», léase «reflejo de 28 en `B04`». El material final de `B04` es `mat_glass_memo` (el `rain_glass` de 28 es solo para ventanales). Naturaleza: 29 es **Opcional** para 28 (28 funciona sin 29) y 28 es **Blanda** para 29.
13. **Interfaz con 28 (contrato por geometría).** No hay textura ni uniform que 28 pase a 29. 28 fija la **alfa del proxy** de reflejo; 29 publica la constante `reflection_strength_max` (0,15†) como tope de esa alfa y 28 la acata al fijarla. 29 **no puede recortar** geometría que no posee; el cumplimiento del tope se verifica por captura (AC-3, AC-16). Si 28 dejara de acatarlo, F29-2 es el criterio de rechazo.
14. **Reflejo bajo el texto.** El reflejo se compone **debajo** del texto (alfa 1). Si se dibujara como malla aparte, el orden por `render_priority` menor que `mat_glass_memo` es **NOT SOURCEABLE** (`render_priority` y el orden de dibujo no figuran en `docs/engine-reference/godot/rendering.md`) ‡ y se confirma en el spike de la regla 44. Para el peor caso, F29-2 se evalúa con el reflejo en el tope sobre la película y la atenuación por fragmento se obtiene del orden de dibujo, no de una multiplicación en el shader.
15. **Sin reflejo, sin fallo.** Si 28 no está o no dibuja el proxy, el cristal funciona entero.
16. **Las lámparas no se tocan.** La luz de las lámparas (haces, `SpotLight3D`) es escena de 4/28; 29 no la usa para decidir qué fragmento se ve. La visibilidad de un fragmento viene de `frag_alpha[i]`, no de iluminación real (R10 de 12: independencia de lámparas; una luz real podría solapar puntos).

### D. Cristal del memorando (órdenes de 12)

17. **Orden `set_fragment(id, visible)`** (`id` ∈ F1, F2, F3, SEAL). Fija el objetivo de `frag_alpha[id]` a 1 o 0; la alfa sigue F29-1 con `fragment_fade_s` = 0,8 s (valor de 12, R11), tanto al encender como al apagar. La visibilidad lógica es instantánea (la decide 12); 29 solo suaviza. Si la orden cambia a mitad de fundido, la alfa continúa desde su valor actual hacia el nuevo objetivo (sin salto).
18. **Texto legible y orientación.** Los fragmentos son texto **ya preparado** (textura generada desde `DOC_01` de 18 con una tipografía de trazo uniforme, sin serifas finas) y no se componen en tiempo de ejecución con `Label3D`. **Orientación por defecto (manda el slice, líneas 165/762, y 12 R21):** el texto está escrito **en espejo** (`mirrored = true`) y existe siempre sobre la película como **residuo latente** casi invisible (`residue_alpha` 0,04†, C ≈ 1,3 frente a la película: apenas perceptible); el haz lo lleva a `frag_alpha` 1 y se hace legible (lectura por la persona jugadora, también en el reflejo). El contraste ≥ 4,5 de F29-2 se exige **solo al fragmento encendido**. La orientación definitiva es la Q7 (decide el usuario/12); cambiarla es solo la uniform `mirrored`. Tamaño mínimo de glifo: F29-3.
19. **`MIRROR_PREVIEW(fragment, duration_s)`.** Muestra durante `duration_s` (2,0 s† de 12) el texto de F1 con la orientación **contraria** a la de los fragmentos (la que permite leerlo, si éstos están en espejo; pendiente de Q7) en una zona neutra definida en datos (`neutral_zone_uv`, rectángulo del cristal que no es ninguno de los 12 puntos). Entra y sale con el mismo fundido de 0,8 s (100 ms con `reducir_movimiento`, con ≥ 333 ms de mantenimiento: regla 5). Opacidad máxima 0,8 (F29-2, segundo caso): es una pista legible, no un fantasma.
20. **`BEAM_HALO(points)`.** 12 decide cuándo (≤ `halo_distance_m` de la lámpara) y envía el punto actual de cada haz como coordenadas UV. 29 dibuja un **anillo doble** (dos circunferencias concéntricas finas) de radio `halo_radius_uv`, centrado en el punto, también si es un punto vacío; la forma (anillo) es la señal, no el color. No pulsa; entra en 0,8 s. No altera el texto bajo él: el anillo se dibuja alrededor, no encima (radio interior mayor que el glifo del fragmento).
21. **Sello (distractor).** Es un gráfico sin texto legible (D12-5) con el mismo fundido que un fragmento; su luminancia pico es ≤ la del texto, para que no compita con él.
22. **`play_resolution` de P2.** F1, F2 y F3 quedan encendidos permanentemente; la película puede tener un leve «aliento» de brillo (ver Tuning, `film_breath_amp` 0,03†, ≤ 0,5 Hz), apagado con `reducir_movimiento`. Sin cambio de cámara ni destello.
23. **`FLOOR_MARKS`.** Pone a `floor_mark_energy` (valor pico en datos) la emisión de los números 1–4 de `B08` y, en la marca de la posición actual de cada lámpara, añade un **segundo elemento no cromático**: un marcador en forma de punta (geometría/textura) además del aumento de brillo. 12 envía la posición actual; 29 no la calcula.

### E. Espejo de la diferencia (órdenes de 15)

24. **Rotación de la foto reflejada.** 15 fija `theta_deg` (continuo, el que el jugador gira) en el material del reflejo cada fotograma que cambia; 29 aplica la rotación en el shader (F29-6). Rotar el nodo en lugar de la UV es equivalente y es el **fallback** (versión provisional).
25. **Coincidencia en θ\*.** En |θ − θ\*| = 0 las dos fotos deben coincidir **figura por figura** con error de registro ≤ 1 px a 1080p (F29-6): ambas texturas comparten tamaño, orientación, filtrado y mapeo UV; el borde de la foto reflejada no se recorta distinto al de la caja. Es el requisito que 15 declara hacia 29 (contrato ‡).
26. **`FADE`** (resolución de 15): superpone la foto del reflejo (D04) sobre la foto de la caja con opacidad F29-1 durante `duration_s` (1,2 s = `reveal_fade_s`); con `reducir_movimiento`: 100 ms fijos (transición única monótona, regla 5) y la imagen final se mantiene hasta `duration_s` (regla 14b(b) de 9; los tiempos de 15 no cambian).
27. **`OUTLINE`** (resolución de 15): contorno **solo de la silueta de Vera** (presente en D04, no en la caja), `duration_s` = **0,8 s†** (`reveal_outline_s`: paso de aparición que *termina* a 2,0 s desde el inicio de la secuencia, tras `FADE` de 1,2 s; F8 de 9, F-P5-4 de 15); entrada de 0,8 s (100 ms con `reducir_movimiento`, sin cambiar `duration_s`) y el contorno **se mantiene hasta el cierre de la secuencia** (`T_seq`). Usa la máscara `vera_outline_mask` (arte). Forma: línea continua doble (trazo claro con borde oscuro) para que se lea sobre cualquier zona de la foto, **no** rojo/verde ni parpadeo.
28. **Resolver y reabrir.** Con `pendiente_revelacion` verdadero, la secuencia empieza desde 0 y 29 debe aceptar `FADE` otra vez desde alfa 0 (sin estado residual). Tras `SOLVED`, `restore_solved_presentation()` de 15 no pide efectos: 29 no dibuja nada en esa restauración.

### F. Resaltados de 9 (`HIGHLIGHT`, `MARK_LIT`)

29. **`HIGHLIGHT(targets, duration_s)`** (no interactivo; 3,0 s† en P5). Para cada objetivo con máscara registrada, modo `PULSE`: contorno visible `duration_s` con envolvente F29-4 (entrada y salida 0,25 s; 100 ms con `reducir_movimiento`; **sin pulso** con `reducir_movimiento`, intensidad constante). El contador de `duration_s` lo gobierna 9 (se detiene en pausa: AC-50 de 9); 29 expone `stop_highlight(target)` y no cuenta tiempo por su cuenta: dibuja mientras 9 no lo retire.
30. **`MARK_LIT`** (marca de 40°, `D01c/mark_40`). Modo `PERSISTENT`: contorno + **cuatro marcas de esquina** (forma, no color) con intensidad constante, hasta que acabe la sesión o se reinicie el nivel. 29 **no guarda el estado**: al abrir la vista, 9/15 vuelven a emitir `MARK_LIT` si la pista de nivel 3 se pidió (D15-17). No resuelve ni mueve el marco.
31. **Registro de objetivos.** Los objetos resaltables (`visual_elements`, `decor`) declaran en su escena un `Node` `FxTarget` con `target_id` (el ID del puzle, p. ej. `D01c/reflection`), la máscara y el mesh/quad a vestir. Un `target_id` sin `FxTarget` se ignora con un `push_warning` y la orden no falla (el puzle sigue; el texto de la pista ya informó).
32. **Un resaltado a la vez por objetivo.** Una orden nueva sobre el mismo objetivo sustituye a la anterior (reinicia la envolvente). `MARK_LIT` no se sustituye por `HIGHLIGHT`; se superponen sin apagarlo.

### G. API de órdenes (propuesta, ‡)

33. **Punto de entrada.** Un `Node` `SurfaceFx` en la escena de cada vista de puzle (no un autoload: dependency injection, testable) expone: `set_fragment(id, visible)`, `play_mirror_preview(fragment, duration_s)`, `set_beam_halo(points)`, `play_highlight(target_id, duration_s)`, `stop_highlight(target_id)`, `set_mark_lit(target_id)`, `play_fade(duration_s)`, `play_outline(duration_s)`, `set_theta(theta_deg)`, `clear_all()`. Quién las llama: 12 y 15 (resolución, estado de sus vistas) y la capa de pistas de 9 (efectos `HIGHLIGHT`/`AFFORDANCE`), vía señal o llamada directa; ver Cambios requeridos.
34. **Ajustes.** `SurfaceFx` lee `reducir_movimiento` de 6 al construirse y escucha su señal de cambio; un cambio afecta a la **siguiente** orden, no a la animación en curso (misma regla que 15 regla 25).
35. **Pausa.** El tiempo de las envolventes usa el reloj de juego (se detiene en pausa); un `Tween` con `Node.PROCESS_MODE_PAUSABLE` ‡ (nombre de Godot 4; `PAUSE_MODE_PAUSABLE` es de Godot 3) y `Tween.set_pause_mode(TWEEN_PAUSE_STOP)` ‡, como 28 R7 y R22: la pausa del árbol no está documentada en `docs/engine-reference/godot/` (OQ de ADR de pausa). Que `TIME` en shader no se congele en pausa es **NOT SOURCEABLE** ‡ (se asume que no se congela, por prudencia); por lo que los shaders de 29 **no usan `TIME`** para nada con significado (solo para `film_breath`, decorativo; cuando el juego está en pausa el aliento se detiene al fijar su fase por uniform desde el reloj de juego).

### H. Versión provisional sin shader (MVP)

36. **Contenido.** Hasta que existan los `.gdshader`: cada superficie usa `StandardMaterial3D` (sin sombreado, `shading_mode = unshaded`, transparencia alfa) con la textura de fragmentos; la alfa y la rotación se mueven con `Tween` sobre `albedo_color.a` y la rotación del nodo. Un `StandardMaterial3D` solo tiene una alfa, por lo que se usa **un quad (con su propio material) por fragmento F1–F3, uno para el sello, uno para `MIRROR_PREVIEW` y uno para el halo**, cada uno con su alfa; `OUTLINE` y `HIGHLIGHT` son un `Sprite3D`/quad con la máscara de contorno y `modulate`. El residuo latente (regla 18) es la misma textura a `residue_alpha`. Los draw calls de esta versión superan el tope de F29-7 y se aceptan como provisionales.
37. **Misma API.** `SurfaceFx` expone las mismas llamadas con la implementación provisional detrás (estrategia): sustituir el material no cambia a 12, 15 ni 9.
38. **Mismo listón de legibilidad.** La versión provisional debe pasar F29-2 y F29-3 (los mismos AC de legibilidad). No se acepta «provisional» ilegible: es la que se prueba en el prototipo temprano del índice.
39. **Fallback en producción.** Si un `ShaderMaterial` falla al compilar o falta el recurso, `SurfaceFx` cae a la implementación provisional de esa superficie y emite `push_error` una vez; el puzle sigue funcionando.

### I. Renderer y rendimiento

40. **Renderer.** El proyecto usa Forward+ (Godot 4.7) y ése es el único objetivo del slice. Los shaders evitan compute, lectura de pantalla y `hint_depth_texture`. No se afirma nada sobre Compatibility ni Mobile: es un objetivo **no verificado** y fuera del slice.
41. **Transparencia y orden.** El cristal `mat_glass_memo` es **un solo material** `blend_mix`, `unshaded`, `depth_draw_never`, `render_priority` 0 (‡ NOT SOURCEABLE, regla 7), que compone todas sus capas internamente (regla 7); el proxy de reflejo de 28 se dibuja con prioridad inferior (regla 14). El contorno (`spatial_fx_outline_mask`) es otro material `blend_mix` con `render_priority` 3. Sin `discard` (el borde se suaviza por alfa; el `discard` solo para la máscara si el spike lo exige).
42. **Presupuesto.** F29-7. El reflejo de 28 (proxy, 1 draw call) cuenta en el presupuesto de 28, no en el de 29.
43. **Shader Baker (4.5+).** Se intenta incluir los tres shaders en la exportación con el Shader Baker para evitar el tirón de la primera aparición de un efecto. Su comportamiento con `instance uniform` **no está verificado** (regla 44). Alternativa si no se usa: precalentar el material al abrir la vista, fuera de pantalla, durante la transición de apertura.
44. **Spike previo a la implementación.** Antes del lote de implementación, un spike en 4.7.2 (Forward+) verifica: (a) `instance uniform vec4`/escalar en `ShaderMaterial`; (b) `#include` de `.gdshaderinc`; (c) Shader Baker con `instance uniform`; (d) el precalentamiento como alternativa. Resultado en un ADR (`docs/architecture/`). Hasta entonces los tres son **no verificado**.
45. **Materiales fuera de glow y exposición.** **NOT SOURCEABLE ‡ (posiblemente falso):** se afirmaba que los materiales de 29 (`unshaded`) no reciben glow ni exposición automática del `Environment`; el glow 4.6 es un postproceso sobre el color renderizado, antes del tonemapping (`rendering.md`), y `unshaded` no exime. No se da por supuesto:  `L_txt` ≥ 0,80 se mide en captura con el `Environment` del nivel (HDR de 4.7 incluido), no en la textura.

## Formulas

**F29-1 · Fundido de alfa (fragmentos, previa, halo, `FADE`, `OUTLINE`).**
`a(t) = a0 + (a1 − a0) · smoothstep(0, 1, clamp((t − t_ini) / T_f, 0, 1))`
| Variable | Rango | Valor |
|---|---|---|
| `T_f` | 0,1–1,2 s | 0,8 (cristal), 1,2 (`FADE`), 0,8 (`OUTLINE`); con `reducir_movimiento`: 0,1 |
| `a0`, `a1` | 0–1 | alfa actual y objetivo |
Ejemplo: fragmento F2 enciende con T_f = 0,8; a t = 0,4 s, `smoothstep(0,1,0,5)` = 0,5 → alfa 0,5. Cambio de orden a medias (apagar a t = 0,4): `a0 = 0,5`, `a1 = 0`; no hay salto.

**F29-2 · Contraste del texto (legibilidad).**
`C = (L_txt + 0,05) / (L_bg_eff + 0,05) ≥ 4,5`, con `L_bg_eff = L_film + r · L_refl` (`r` = `reflection_strength` recortado a 0,15; `L_refl` ≤ 0,30).
Valores de diseño: `L_txt` ≥ 0,80, `L_film` ≤ 0,06. Ejemplo peor caso: `L_bg_eff = 0,06 + 0,15·0,30 = 0,105` → `C = 0,85 / 0,155 = 5,48 ≥ 4,5`. Sin reflejo: `0,85/0,11 = 7,7`. `L` es luminancia relativa lineal del píxel renderizado (con el tonemapping del proyecto), medida en captura, no en la textura. Se exige solo al fragmento **encendido**; el residuo latente (regla 18) debe quedar en `C_res = (L_film + residue_alpha·(L_txt − L_film) + 0,05)/(L_film + 0,05) ≈ 1,3` (0,06 + 0,04·0,74 = 0,09 → 0,14/0,11 = 1,27), «apenas perceptible» (†, a validar en playtest).
**Segundo caso: `MIRROR_PREVIEW`** con opacidad `o` = 0,8: `L_prev = o·L_txt + (1−o)·L_film = 0,8·0,80 + 0,2·0,06 = 0,652`; sobre película sin reflejo `C = 0,702/0,11 = 6,4`; con el reflejo al tope (`L_bg_eff` = 0,105) `C = 0,702/0,155 = 4,53 ≥ 4,5`. Con `o` = 0,7 sería `0,578` → `C` = 5,7 sin reflejo pero 4,05 con reflejo al tope (no pasa): por eso el valor es 0,8.

**F29-3 · Altura mínima de glifo en pantalla.**
`h_px = x_h · H / (2 · d · tan(fov/2))` con `x_h` = altura de la «x» en metros, `d` = distancia ojo–cristal en la vista de inspección, `fov` vertical, `H` = alto en píxeles.
Requisito: `h_px ≥ 14` a H = 1080 con el `fov` máximo de `campo_vision` (6: 60–90° **verticales**, defecto 70°; peor caso 90°; con 70° y el mismo `x_h` el glifo queda mayor: `h_px` ≈ 0,032·1080/(2·1,2·tan 35°) ≈ 20,6 px). Despejando: `x_h ≥ 14 · 2 · d · tan(fov/2) / H`. Ejemplo: d = 1,2 m, fov = 90° → `x_h ≥ 14·2·1,2·1/1080 = 0,0311 m`. Se fija `x_h_min` = 0,032 m (margen) y arte ajusta el tamaño del texto en `B04`. A 720p el glifo medido (9,5 px) queda por debajo del listón: se acepta documentado, el slice apunta a 1080p (ver Open Questions).

**F29-4 · Envolvente del resaltado `PULSE`.**
`I(t) = I_base + I_amp · 0,5 · (1 + sin(2π · f · t))` con envolvente de entrada/salida `E(t)` (0,25 s; 0,1 s reducido), `I_final = I_min + (I(t) − I_min)·E(t)`.
`f` ≤ 2,0 Hz (valor 1,25†); `I_base` 0,6; `I_amp` 0,3; con `reducir_movimiento`: `I_amp = 0`, `I = I_base`. Variación máxima de luminancia por fotograma < 0,25 (regla 5). Ejemplo: f = 1,25 Hz, pico de intensidad 0,9 y valle 0,6, ciclo de 0,8 s.

**F29-5 · Grosor del contorno independiente de resolución.**
`w_px = clamp(round(H · 0,0035), 3, 6)` y en el shader `w_uv = w_px · fwidth(UV)` (derivadas de pantalla; **NOT SOURCEABLE ‡**: `fwidth(UV)` no figura en `rendering.md`, se confirma en el spike de la regla 44). Ejemplo: H = 1080 → 3,78 → **4 px**; H = 720 → 2,52 → 3 px (mínimo); H = 2160 → 7,56 → 6 px (tope). Contraste del contorno contra su entorno: trazo claro (`L` ≥ 0,70) con borde oscuro (`L` ≤ 0,05) a 1 px: `C ≥ 4,5` frente a cualquier fondo posible de la foto.

**F29-6 · Rotación UV y error de registro.**
`uv' = ((R(−θ) · ((uv − c) · (a, 1))) / (a, 1)) + c`, `c` = (0,5; 0,5) (centro del marco interior), `R` = matriz 2D de giro, `a` = ancho/alto del marco (corrección de aspecto: sin ella un marco no cuadrado se cizalla y el registro no está garantizado). Ejemplo: marco 4:3 (`a` = 1,333), θ = 90°: el punto `uv` = (0,75; 0,5) → `(uv−c)·(a,1)` = (0,333; 0) → `R(−90°)` = (0; −0,333) → `/(a,1)` = (0; −0,333) → `uv'` = (0,5; 0,167). Fuera de UV 0–1 tras rotar se descarta a transparente (alfa 0, sin `discard`). Error de registro en θ\*: `e_px = H · max(|Δuv|)` entre las dos fotos para los puntos de control de arte (esquinas de las figuras); debe ser `≤ 1 px`. Ejemplo: error UV de 0,0006 a H = 1080 → 0,65 px (pasa). El filtrado es `filter_linear_mipmap`; con `texture_repeat` desactivado (fuera de UV 0–1 se descarta a transparente, no se repite).

**F29-7 · Presupuesto de rendimiento (1080p, hardware de referencia del proyecto).**
`C_gpu = Σ_i c_i ≤ 0,5 ms` con todo activo a la vez (peor caso: cristal con 3 fragmentos + halo + previa; espejo con `FADE` + `OUTLINE`; no coexisten en la misma vista, así que el peor real es una vista). Reparto: `glass_memo` ≤ 0,20 ms, `mirror_photo` ≤ 0,10, **tope conjunto de todos los contornos simultáneos** (`outline_mask`, Vera + `HIGHLIGHT` de `reflection`/`box_photo` + `MARK_LIT`) ≤ 0,15 ms, margen 0,05. Muestras de textura por píxel ≤ 3 (cristal; el contorno añade ≤ 4 de dilatación); draw calls añadidos por vista ≤ 6 (cristal 1 + contornos ≤ 4 + espejo 1). Todos los valores son propuesta (†) **sin medir**; «hardware de referencia» y su documento de presupuesto de renderizado (la banda «Particles/VFX ≤ 1–2 ms» citada no está verificada) quedan por fijar (Q9).

## Edge Cases

1. **Orden sobre un objetivo sin `FxTarget` o sin máscara.** Se ignora con `push_warning`; la orden no falla ni bloquea el puzle (regla 31).
2. **`set_fragment` repetido o contradictorio en el mismo fotograma.** Gana la última; sin alfa fuera de [0,1].
3. **Cambio de `reducir_movimiento` en mitad de un fundido.** Termina el fundido en curso con su duración original; la siguiente orden usa el nuevo valor (regla 34).
4. **Pausa durante un fundido o un `HIGHLIGHT`.** El reloj de juego se detiene y la envolvente no avanza; al reanudar continúa (AC-50 de 9). El halo y `MARK_LIT` (estados) no se alteran.
5. **Salir de la vista a mitad de `FADE`/`OUTLINE`.** `clear_all()` apaga todo sin fundido (la vista ya no se dibuja). Al reabrir con `pendiente_revelacion`, 15 repite la secuencia desde 0 (regla 28).
6. **`MARK_LIT` pedido y puzle ya resuelto.** Sin efecto (9: una `AFFORDANCE` en puzle `RESUELTO` no tiene efecto); 29 no dibuja.
7. **Dos fragmentos solapados por arte.** No debería ocurrir (R10 de 12: puntos distintos). Si ocurre, gana el de índice mayor y se lanza `push_warning` en depuración.
8. **`BEAM_HALO` en un punto que cae en el sello o fuera del cristal.** En el sello se dibuja igualmente (el punto actual es el sello). Fuera de [0,1] en UV se recorta y no se dibuja.
9. **Proxy de reflejo de 28 con alfa > tope.** 29 no lo recorta (no posee la geometría); se detecta en captura (AC-3, AC-16) y se corrige en 28 (regla 13).
10. **Cambio de resolución o de ventana en vista.** El grosor del contorno se recalcula (F29-5) y los glifos conservan su tamaño en metros; si en 720p el glifo queda bajo el listón, se registra pero no se corrige (Open Questions).
11. **Fallo de compilación del shader.** Cae a provisional (regla 39); el puzle sigue resoluble y legible.
12. **Daltonismo (protanopia, deuteranopia, tritanopia).** Todas las señales se identifican por forma y luminancia (reglas 4, 20, 27, 30); una simulación en escala de grises no pierde información (AC-14).
13. **Modo de alto contraste del sistema operativo.** No existe en 6; el contraste de diseño (F29-2 ≥ 4,5) ya cubre el uso normal. Fuera de alcance del slice.
14. **Primer uso tras un arranque en frío.** El tirón de compilación se evita con Shader Baker o precalentamiento (regla 43); si aparece, se mide y se trata como defecto de presentación.

## Dependencies

| Sistema | Dirección | Naturaleza | Contrato |
|---|---|---|---|
| 12 Puzle 2 · Memorando | 29 depende | **Dura** (índice) | 12 envía `set_fragment`, `play_mirror_preview`, `set_beam_halo`, `FLOOR_MARKS` con las posiciones; da `neutral_zone_uv`, `fragment_fade_s` (0,8) y `mirror_preview_s` (2,0); exige legibilidad (R11, R21, F29-2/F29-3) |
| 15 Puzle 5 · Espejo | 29 depende | **Dura** para 29 (consume las órdenes de 15), **Blanda** en ejecución para 15 (versión provisional): el índice la marca dura (con «blanda en ejecución para 15»), como aquí (12 y 15 no dependen de 29) | 15 fija `theta_deg`, pide `FADE` (`duration_s` 1,2 s) y `OUTLINE` (`duration_s` 0,8 s†, fin a 2,0 s), exige coincidencia en θ\* (regla 25), sin ayuda de coherencia (regla 7 de 15) |
| 9 Marco de puzles | Blanda | Origen de `HIGHLIGHT`/`AFFORDANCE`; regla 14b (`reducir_movimiento` 100 ms); reloj de pausa | 29 no define qué pista se ve ni cuándo; solo cómo |
| 6 Ajustes | Blanda | Lee `reducir_movimiento` y su señal de cambio, y `campo_vision` (60–90° verticales, defecto 70; solo para validar F29-3) | No lee `reducir_sobresaltos` (regla 5); 6 aún no lista a 29 como lector (Cambios requeridos) |
| 28 Atmósfera reactiva | 29 es Opcional para 28; 28 Blanda para 29 | Reflejo del cristal: lo posee 28 (sonda de sala sin retardo en `B04`; proxy retardado solo en `C02`), sin textura | Regla C (12–15); 28 acata `reflection_strength_max`; `B04` es de 29 (material) y su reflejo es de 28 (resuelto, ronda 9) |
| 4 Escenario/nivel, 10 Contenedores | Datos | Mallas y `FxTarget` en las escenas; `B04`, `B08`, `D01c/*`; 10 no se ve afectado | Arte fija tamaños y UVs |
| 18 Base de contenido | Datos | `DOC_01` por fragmentos; texturas generadas desde él en el pipeline | El texto del cristal no es traducible en tiempo real (Open Questions) |
| 23 Audio | Ninguna | 29 no emite audio | Sincronización de la grabación es de 15/23 |

Bidireccionalidad: 12 y 15 ya citan a 29 (`‡`); 9 y 28 deben citarlo (Cambios requeridos).

## Tuning Knobs

| Perilla | Valor | Rango seguro | Afecta | Origen |
|---|---|---|---|---|
| `fragment_fade_s` | 0,8 s | 0,4–1,2 | Ritmo de aparición del texto | 12 (slice B.2) |
| `fade_reduced_s` | 0,1 s | fijo (9, 14b) | Fundido con `reducir_movimiento` | 9 |
| `mirror_preview_opacity` | 0,8 | 0,8–0,9 (con 0,7 falla F29-2 con reflejo al tope) | Visibilidad de la pista N1 | 29† |
| `residue_alpha` | 0,04 | 0,02–0,06 | Texto latente en espejo, apenas perceptible (regla 18) | 29† |
| `reflection_strength_max` | 0,15 | 0,0–0,25 | Tope de alfa del proxy de reflejo de 28 (F29-2) | 29† |
| `L_film_max` | 0,06 | 0,03–0,10 | Fondo del cristal | 29† |
| `x_h_min` | 0,032 m | 0,0311–0,045 (el suelo lo fija F29-3: 14 px a 1080p, d = 1,2 m, fov 90°; por debajo, AC-4 falla) | Tamaño del texto (F29-3) | 29† |
| `halo_radius_uv` | 0,06 | 0,04–0,10 | Tamaño del anillo del haz | 29† |
| `highlight_pulse_hz` | 1,25 | 0,5–2,0 (tope duro 2,0) | Ritmo del resaltado | 29† |
| `outline_width_px` | 4 @1080p | 3–6 (F29-5) | Visibilidad del contorno | 29† |
| `film_breath_amp` | 0,03 | 0–0,06 | «Aliento» del cristal resuelto | 29† |
| `fx_gpu_budget_ms` | 0,5 | 0,3–1,0 | Presupuesto del sistema (F29-7) | 29† |
| `register_error_px_max` | 1,0 | 0,5–1,5 | Tolerancia de coincidencia en θ\* | 29† |

Todos viven en un `Resource` (`fx_config.tres`) por superficie, no en el shader (excepto los literales de la matriz de rotación).

## Acceptance Criteria

Tipo de evidencia de cada AC: **L** = prueba unitaria sobre el modelo (gdUnit4, reloj falso; `tests/unit/shaders/`); **I** = integración, playtest o medición con el perfilador, documentada; **UI** = captura retenida en `production/qa/evidence/` (evidencia visual); **PV** = pendiente de verificación en el editor de Godot 4.7 (glow/HDR sobre `unshaded`, `process_mode` en pausa, orden de render del cristal: NOT SOURCEABLE).

- **AC-1 (L; regla 17, F29-1).** GIVEN `set_fragment(F2, true)` con reloj falso, THEN `frag_alpha[F2]` vale 0,5 a t = 0,4 s, 1,0 a t ≥ 0,8 s; con `reducir_movimiento`, 1,0 a t ≥ 0,1 s. Prueba unitaria sobre el modelo de fundido.
- **AC-2 (L; regla 17).** GIVEN fundido a t = 0,4 s, WHEN llega `set_fragment(F2, false)`, THEN la alfa desciende desde 0,5 sin salto.
- **AC-3 (F29-2, PV — depende del glow/HDR de 4.6/4.7 sobre materiales `unshaded`, no verificado).** GIVEN F1–F3 encendidos, THEN en captura a 1080p el contraste texto/fondo medido es ≥ 4,5 con el proxy de reflejo de 28 al tope y ≥ 7 sin reflejo; GIVEN `MIRROR_PREVIEW` activa, ≥ 4,5 con reflejo al tope (segundo caso de F29-2). GIVEN ningún fragmento encendido, el residuo latente tiene `C_res` ≤ 1,5. Captura retenida con el `Environment` del nivel; vale para la versión final (la provisional no implementa el tope de reflejo: se mide sin reflejo, ≥ 7).
- **AC-4 (UI; F29-3).** GIVEN la vista del cristal a 1080p con el `fov` máximo (90°) y con el defecto (70°), THEN la altura de la «x» medida en captura es ≥ 14 px.
- **AC-5 (I; regla 18).** Al menos 3 testers sin ayuda leen F1, F2 y F3 completos en el cristal (sin lupa) en la captura de resolución de P2, en la orientación definida por Q7 (lectura directa o en el reflejo); acierto 3/3 en lectura de cada fragmento. Test de lectura documentado.
- **AC-6 (I; regla 19).** GIVEN `MIRROR_PREVIEW(F1, 2,0)`, THEN el texto aparece invertido en `neutral_zone_uv`, no solapa ninguno de los 12 puntos, dura 2,0 s (± 1 fotograma) y se retira.
- **AC-7 (I; regla 20).** GIVEN un haz que apunta a un punto vacío y la pista N3, THEN se dibuja el anillo doble en ese punto, no se oculta ningún texto cercano; sin pista N3 no hay anillo.
- **AC-8 (UI; regla 25, F29-6).** GIVEN θ = θ\*, THEN el error de registro entre ambas fotos es ≤ 1 px en las esquinas de control (captura ampliada).
- **AC-9 (UI; regla 8).** GIVEN cualquier θ, THEN el brillo medio y la nitidez del reflejo no cambian con θ (la salida solo depende de la rotación). Inspección de código del shader + dos capturas a θ\* y θ\* + 20°.
- **AC-10 (L; reglas 26, 27).** GIVEN la resolución de P5, THEN `FADE` dura 1,2 s y `OUTLINE` tiene `duration_s` 0,8 s y termina a 2,0 s desde el inicio de la secuencia (± 1 fotograma, reloj falso), y el contorno se mantiene hasta `T_seq`; `OUTLINE` rodea solo a Vera; con `reducir_movimiento` la entrada de ambos es de 100 ms y los `duration_s` no cambian.
- **AC-11 (L; regla 29, F29-4).** GIVEN `HIGHLIGHT` 3,0 s sin `reducir_movimiento`, THEN la frecuencia de pulso ≤ 2,0 Hz y la variación de luminancia por fotograma < 0,25; con `reducir_movimiento` la intensidad es constante.
- **AC-12 (I; regla 30).** GIVEN `MARK_LIT` pedido, THEN la marca permanece iluminada (con las cuatro marcas de esquina) hasta cerrar la sesión; tras cerrar y reabrir la vista, 9/15 reemiten y 29 la vuelve a dibujar. En un puzle `RESUELTO` no se dibuja.
- **AC-13 (L; regla 31).** GIVEN una orden con un `target_id` sin `FxTarget`, THEN no hay excepción, se emite un `push_warning` y el puzle sigue resoluble.
- **AC-14 (UI; regla 4).** GIVEN capturas en escala de grises y con simulación de protanopia, deuteranopia y tritanopia (herramienta de simulación del editor o equivalente, indicada en la evidencia) del halo, `MARK_LIT`, `OUTLINE` y `HIGHLIGHT`, THEN cada señal se distingue de su fondo (contraste ≥ 4,5 por luminancia) y por su forma.
- **AC-15 (I; regla 5).** GIVEN cualquier efecto de 29, THEN no hay un par de transiciones opuestas > 0,25 de luminancia dentro de 333 ms ni pulso > 2 Hz. Casos explícitos: los fundidos de 100 ms con `reducir_movimiento` (fragmento 0→0,80, `FADE` 0→1, `HIGHLIGHT` 0→`I_base`) son transiciones únicas monótonas y se permiten; `MIRROR_PREVIEW` con `reducir_movimiento` mantiene ≥ 333 ms entre entrada y salida. Verificado con el modelo F29-4 y en vídeo de captura.
- **AC-16 (PV; regla 13).** GIVEN el proxy de reflejo de 28 en su alfa máxima, THEN la alfa efectiva es ≤ `reflection_strength_max` (0,15) y AC-3 se cumple; GIVEN 28 ausente, THEN el cristal se ve completo.
- **AC-17 (reglas 40, 44, PV — compilación sin advertencias y spike pendientes).** GIVEN el proyecto en Forward+, THEN los tres shaders compilan sin advertencias; el spike de la regla 44 está documentado en un ADR. Compatibility no se prueba ni se afirma. Ningún shader usa `hint_screen_texture` (búsqueda en el repositorio).
- **AC-18 (I; F29-7).** GIVEN la peor vista con todo activo en el hardware de referencia a 1080p, THEN el coste GPU de 29 medido con el perfilador es ≤ 0,5 ms y los draw calls añadidos ≤ 6.
- **AC-19 (I; reglas 36–39).** GIVEN la versión provisional, THEN pasa AC-1, AC-2, AC-4 a AC-8 con las mismas llamadas de API y AC-3 en su forma sin reflejo; GIVEN un `ShaderMaterial` roto, THEN la superficie cae a provisional y el puzle sigue resoluble.
- **AC-20 (I; regla 43).** GIVEN un arranque en frío, WHEN aparece el primer fragmento, THEN no hay un tirón > 50 ms (traza del perfilador).
- **AC-21 (PV; regla 35).** GIVEN pausa en mitad de un `HIGHLIGHT`, THEN la envolvente no avanza y el `duration_s` restante continúa al reanudar.

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D29-1 | Los fragmentos son **texturas preparadas** (atlas desde `DOC_01`) con alfa por fragmento | Componer el texto con `Label3D` espejado en tiempo de ejecución | Control del contraste y del tamaño (F29-2/3), mismo resultado en provisional y final; el texto del cristal no cambia con el idioma del slice (único) |
| D29-2 | La **visibilidad del fragmento viene de un uniform**, no de la iluminación real | Iluminar el cristal con las luces reales y dejar que el shader lo lea | Garantiza R10 (independencia de lámparas) y legibilidad estable; no depende de sombras ni del renderer |
| D29-3 | **Tres shaders baratos**, todos `spatial`, sin pantalla ni profundidad | Pase de postproceso con `CompositorEffect` para el contorno | El slice no necesita pase completo; un contorno por quad cuesta menos |
| D29-4 | Contorno por **máscara de silueta sin dilatar + dilatación en shader** (planos) y casco invertido (mallas) | Stencil buffer (`modules/rendering.md` lo lista, es una alternativa viable) o detección de bordes por profundidad | Los resaltables del slice son fotos/marcas planas; la máscara es exacta, barata y simple; el stencil añade complejidad de pases sin necesidad. Máscara sin dilatar para que el grosor sea independiente de la resolución (W-4) |
| D29-5 | Rotación de la foto del espejo **en el shader** (UV), con el nodo rotado como fallback | Rotar la malla | Bordes nítidos y control del registro (F29-6); la API de 15 (`theta_deg`) no cambia entre implementaciones |
| D29-6 | `SurfaceFx` es un **nodo por vista**, no un autoload | Singleton global | Inyección de dependencias y pruebas aisladas (coding standards) |
| D29-7 | Señales por **forma** (anillo doble, esquinas, línea doble, punta) y luminancia; el color cálido solo refuerza | Códigos de color (verde/rojo, ámbar) | Accesibilidad (sin dependencia de color) y tono sobrio del slice |
| D29-8 | 29 **no lee `reducir_sobresaltos`**; los efectos ya no tienen destellos | Escalar intensidades con esa opción | 6 solo la entrega a 23 y 28; sin destellos por diseño no hace falta |
| D29-9 | Estado persistente de `MARK_LIT` **no se guarda en 29**; se reemite | Que 29 recuerde la marca | 29 no escribe hechos ni tiene guardado; la fuente de verdad es el estado de pistas de 9 |
| D29-10 | 29 **fija** `reflection_strength_max` y 28 lo acata como tope de alfa de su proxy | Que 29 recorte un `reflection_strength` uniform, o dejar a 28 libre | 28 usa proxy de geometría (DT-3), sin uniform ni textura que recortar; la legibilidad del texto es del puzle y F29-2 es el criterio (B-1) |
| D29-13 | **Un solo material y un solo pase** para el cristal (`blend_mix`; halo mezclado en shader) | Varios quads/materiales con `render_priority` por capa y `blend_add` para el halo | Un material tiene un único `render_priority` y `blend_mode` (**NOT SOURCEABLE** ‡, no figura en `rendering.md`); menos draw calls y orden determinista (W-1) |
| D29-14 | `OUTLINE` = `duration_s` 0,8 s† (termina a 2,0 s), contorno mantenido hasta `T_seq` | `duration_s` 2,0 s | Es el valor de 9 (F8) y 15 (`reveal_outline_s`); verificado por Grep (B-2) |
| D29-15 | Destello = par de transiciones opuestas > 0,25 en < 333 ms; fundido único monótono de 100 ms permitido | Prohibir todo cambio > 0,25 en < 100 ms | 9 mandata 100 ms con `reducir_movimiento`; el criterio WCAG de 3 destellos es el que protege (B-4) |
| D29-16 | `instance uniform` solo `vec4`/escalares; fallback `ShaderMaterial` por instancia como regla; sin afirmaciones sobre Compatibility; spike + ADR antes de implementar | Array `frag_alpha[4]` y «vale en Compatibility» | Los arrays no son admisibles como `instance uniform`; soporte no verificado; el proyecto es Forward+ (B-5, W-10) |
| D29-17 | Orientación por defecto = **slice** (texto en espejo con residuo latente casi invisible; contraste ≥ 4,5 solo encendido); elevada como Q7 | Texto legible siempre desde el lado del jugador | El slice (líneas 165/762) y 12 R21 mandan; cambiar eso es decisión del usuario (B-3) |
| D29-18 | `mirror_preview_opacity` 0,8 | 0,7 | Con 0,7 y reflejo al tope C = 4,05 < 4,5 (W-12) |
| D29-19 | Versión provisional con un quad por fragmento/previa/halo | Un solo `StandardMaterial3D` con atlas | Una sola alfa por material impide alfa por fragmento (W-7) |
| D29-20 | Tope conjunto de contornos ≤ 0,15 ms; valores † sin medir | 0,10 ms por efecto | 4 contornos simultáneos sumaban 0,40 ms sin margen (W-6) |
| D29-21 | (Ronda 9) Dueño único del reflejo: 28 (sonda sin retardo en `B04`, proxy retardado solo en `C02`); 29 aporta el shader/material y el tope `reflection_strength_max`; alineado con 28 R13/DT-14 | 29 posee el reflejo de `B04`; o 28 entrega textura | 29 R12 y 28 R13 se contradecían |
| D29-22 | (Ronda 9) `PAUSE_MODE_PAUSABLE` pasa a `Node.PROCESS_MODE_PAUSABLE` ‡ (R35); `render_priority`, `blend_mode`, `fwidth(UV)`, `hint_*` y `TIME` en pausa se marcan NOT SOURCEABLE | Darlos por conocidos | No figuran en `rendering.md` ni en la documentación de pausa |
| D29-23 | (Ronda 9) R45 («`unshaded` no recibe glow») pasa a NOT SOURCEABLE y posiblemente falsa; AC-3 y AC-17 pasan a PV | Mantenerla como hecho | El glow 4.6 es un postproceso (`rendering.md`); `unshaded` no exime |
| D29-24 | (Ronda 9) `x_h_min` rango inferior 0,0311 m (suelo de F29-3) | 0,028 m | Con 0,028 m, h_px = 12,6 < 14 y AC-4 falla |
| D29-25 | **(Ronda de corrección 10, restos R15)** Cada AC lleva su tipo (L/I/UI/PV; PV los de glow, `process_mode` y orden de render); la fila 15 de Dependencies dice que el índice la marca **dura** (no blanda); 12 y 15 no listan a 29 con dureza (anotado en Cambios requeridos) | Dejar los AC sin tipo y «blanda» | R15-4: sin tipo no hay gate de evidencia; el índice ya dice dura |
| D29-11 | Versión **provisional primero** (materiales estándar + tween), con la misma API | Esperar al shader final para el prototipo | Es el mitigante del riesgo alto del índice: el cristal se prueba antes y el shader solo sustituye la implementación |
| D29-12 | Presupuesto propio de 0,5 ms (†) | Sin presupuesto hasta el perfilado | Un número desde el principio obliga a medir; se ajusta con datos |

## Open Questions

1. **¿Las vistas de P2 y P5 se renderizan como superficies 3D en el mundo (quads/mallas) o como `SubViewport`/UI?** **Decisión elevada: decide el usuario / 4 y 7**, *antes de implementar* (cambia todos los shaders `spatial`). Valor provisional: 3D en mundo con la misma API. Responsable: director técnico + 4/7.
2. **`campo_vision` máximo de 6.** *Cerrada*: 60–90° verticales, defecto 70° (6, línea 41); F29-3 usa 90° como peor caso y AC-4 mide 90° y 70°.
3. **Resolución mínima soportada.** A 720p el glifo queda en 9,5 px (< 14). Por defecto: el slice apunta a 1080p; se documenta. Responsable: UX/21. *Antes del cierre del slice.*
4. **Fundido de fragmentos con `reducir_movimiento`.** 14b de 9 habla de 100 ms para presentaciones de resolución; este GDD lo aplica también a los fragmentos del cristal. Por defecto: 100 ms. Responsable: 9 (Cambios requeridos); bloquea solo la coherencia, no la implementación.
5. **Spike (regla 44).** `instance uniform` vec4/escalar, `#include`, Shader Baker con `instance uniform` y precalentamiento en 4.7.2 **(no verificado)**. Responsable: gameplay/tech programmer + technical-artist; *antes del lote de implementación*; resultado en ADR.
6. **Quién emite las órdenes de pista a `SurfaceFx`** (la vista, 9 por señal o 12/15 directamente). Por defecto: 9 emite una señal `hint_effect_requested` y la vista la reenvía a `SurfaceFx`. Pendiente de 9.
7. **Orientación del texto del cristal — decide el usuario (con 12).** El slice (líneas 165/762) y 12 (R21) dicen: texto escrito en espejo, siempre presente y apenas perceptible, legible con el haz. Este GDD sigue provisionalmente al slice (regla 18, `mirrored = true`, `residue_alpha`). La alternativa (legible desde el lado del jugador, solo la previa invertida) cambia el puzle 2, la pista N1 y el pilar *Información incompleta*: **no se aplica sin decisión**. Bloquea AC-5 y el arte del atlas. Cambiarlo es solo la uniform `mirrored`.
8. **Si hay `reducir_movimiento`, ¿se apaga el «aliento» de la película de P2 resuelto?** Por defecto: sí. Responsable: technical-artist.
9. **Hardware de referencia y documento de presupuesto de renderizado** (F29-7): sin fijar y sin medir; la banda «Particles/VFX ≤ 1–2 ms» no está verificada. Responsable: technical-director / performance-analyst; antes de AC-18.
10. **Propietario del material de `B04`** (29 `mat_glass_memo` frente al `rain_glass` de 28). Se resuelve en la ronda paralela de 28; responsable: art/technical-artist con 28.
11. **ADR de pausa (`SceneTree.paused` / `process_mode`):** `docs/engine-reference/godot/` no documenta la pausa del árbol. R35 y el reloj de juego dependen de ella. Opciones sin decidir: (a) 25 pausa el árbol y cada sistema declara su `process_mode` (los `Tween` de 29 `PAUSABLE`); (b) 25 no lo pausa y 28/29 gestionan su propio reloj de juego (uniform de fase desde Δ_juego; los shaders no usan `TIME`). 29 cumple con ambas.

## Cambios requeridos en otros GDDs

- **9 Marco de puzles:** (0) citar a 29 y `SurfaceFx` en sus dependencias (aún no lo hace); (a) citar a 29 como consumidor de los efectos `HIGHLIGHT`, `AFFORDANCE` (`MIRROR_PREVIEW`, `BEAM_HALO`, `FLOOR_MARKS`, `MARK_LIT`) y de `FADE`/`OUTLINE`; (b) definir la señal o el canal por el que se entregan a `SurfaceFx` (regla 33; Q6); (c) aclarar si 14b(b) del fundido de 100 ms cubre también fundidos de superficie fuera de la resolución (Q4); (d) mantener que 9 gobierna el `duration_s` del `HIGHLIGHT` y la pausa (regla 29).
- **12 Puzle 2:** (a) enviar a 29 `neutral_zone_uv`, `halo_radius_uv` (opcional) y las posiciones de `FLOOR_MARKS`; (b) citar `x_h_min`, F29-2 y F29-3 en R11/R21; (c) confirmar la orientación del texto (Q7, decide el usuario; el slice manda: espejo con residuo latente); (d) sustituir en Visual/Audio Requirements «de 28/29» por la referencia a las reglas C y D de este GDD.
- **15 Puzle 5:** (a) citar el requisito de registro ≤ 1 px en θ\* (regla 25) y `theta_deg` como API hacia 29; (b) **corrección:** `FADE` `duration_s` 1,2 s y `OUTLINE` `duration_s` 0,8 s† (fin a 2,0 s; ya así en 15, no hay que cambiar valores) y que 29 no cuenta el tiempo de la secuencia; (c) que el contorno solo se pide en `RESOLVING`.
- **28 Atmósfera reactiva:** (a) contrato por **proxy de geometría espejada** (`pose_con_retardo`, 1 draw call), sin `reflection_tex` ni `reflection_strength` uniform (reglas 12–15); (b) fijar la alfa del proxy ≤ `reflection_strength_max` 0,15† y dibujarlo bajo `mat_glass_memo` (regla 14); (c) no tocar película, fragmentos ni halo; (d) confirmar el propietario del material de `B04` y declarar a 29 como **Opcional** para 28 (Q10); (e) conservar el reflejo dentro de su presupuesto.
- **6 Ajustes:** listar a 29 como lector de `reducir_movimiento` (y su señal de cambio, regla 34) y de `campo_vision`.
- **12 Puzle 2 y 15 Puzle 5 (Dependencies):** 29 declara su dependencia **Dura** de 12 y 15 (la declara el dependiente; en 15, Blanda en ejecución por la versión provisional); 12 (prosa de «Dependen de 12», l.250) y 15 (l.239, tabla de 29) la mencionan sin dureza: conviene que listen a 29 como consumidor que los lee. 29 no los edita.
- **`systems-index.md`:** fila 12 «17 (lee `memo_leido`)» contradice D17-10 (lo anota la revisión R15-4); mantener 12 y 15 como no dependientes de 29 en ejecución (versión provisional) aclarando que «Dura» significa que 29 consume sus órdenes.
- **4 Escenario / 10 Contenedores:** `FxTarget` en `B04`, `B08`, `D01c/reflection`, `D01c/box_photo`, `D01c/mark_40` y `C05/paper/stamp_N`; arte entrega `outline_mask`, `vera_outline_mask`, atlas de fragmentos y UVs registrados (AC-8).
- **`systems-index.md`:** pasar la fila 29 a «Borrador» al integrar este lote.

## Entradas para el registro (†=propuesta)

| Tipo | ID | Valor | Fuente / nota |
|---|---|---|---|
| constante | `reflection_strength_max` † | 0,15 (tope de alfa del proxy de 28) | Regla 13; F29-2 |
| constante | `residue_alpha` †, `mirror_preview_opacity` † | 0,04; 0,8 | Reglas 18–19; F29-2 |
| constante | `x_h_min_m` † | 0,032 | F29-3 |
| constante | `L_film_max` † | 0,06 | F29-2 |
| constante | `highlight_pulse_hz` † | 1,25 (tope 2,0) | F29-4 |
| constante | `outline_width_px` † | 4 @1080p | F29-5 |
| constante | `fx_gpu_budget_ms` † | 0,5 | F29-7 |
| constante | `register_error_px_max` † | 1,0 | F29-6 |
| entidad | `SurfaceFx` † | nodo por vista | Regla 33 |
| entidad | `FxTarget` † | nodo por objetivo resaltable | Regla 31 |
| recurso | `mat_glass_memo` † | material del cristal | Regla 12 |
| shader | `spatial_surface_glass_memo`, `spatial_surface_mirror_photo`, `spatial_fx_outline_mask` † | `assets/shaders/` | Regla B |
| referencia | `fragment_fade_s` (12), `MIRROR_PREVIEW`, `BEAM_HALO`, `MARK_LIT`, `FLOOR_MARKS` | existentes | Ya en el registro |

## Historial

| Fecha | Versión | Cambio |
|---|---|---|
| 2026-11-09 | 0.1 | Borrador inicial (lote autónomo). Define shaders, contrato del cristal con 28, versión provisional sin shader, accesibilidad y presupuesto. Referencias del motor: `docs/engine-reference/godot/modules/rendering.md` (4.7) para renderer, Shader Baker y compositor; `#include`, `instance uniform` y stencil sin verificar en referencias. |
| 2026-11-09 | 0.2 | Ronda de corrección 1 (informe `reviews/shaders-y-efectos-review.md`). B-1: reflejo = proxy de geometría de 28, sin `reflection_tex`. B-2: `OUTLINE` `duration_s` 0,8 s (fin 2,0 s), verificado en 9 y 15. B-3: orientación del texto sigue al slice (espejo + residuo latente) y se eleva como Q7 (decide el usuario). B-4: regla 5 redefine destello (WCAG, 333 ms). B-5: `instance uniform` solo vec4/escalar, spike + ADR, sin afirmaciones sobre Compatibility. W-1 a W-13 aplicados (un pase de cristal, máscara sin dilatar, aspecto en F29-6, tope conjunto de contornos, quad por fragmento provisional, sin glow, opacidad previa 0,8, referencias de AC, responsables en Open Questions). |
| 2026-11-10 | 0.3 | Ronda de corrección 9 (informe `gdd-cross-review-2026-11-10.md`). Reflejo: dueño 28, 29 aporta shader (R12–R14, deps, D29-21); R35 `PROCESS_MODE_PAUSABLE`; R45, `render_priority`, `blend_mode`, `fwidth(UV)`, `hint_*`, `TIME` en pausa marcados NOT SOURCEABLE; AC-3 y AC-17 a PV; `x_h_min` ≥ 0,0311 m; OQ ADR de pausa; D29-21 a D29-24. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. |
| 2026-11-10 | 0.4 | Ronda de corrección 10 (restos R15): ACs tipados con leyenda; dureza de 15 alineada con el índice (dura); Cambios requeridos para 12/15 (D29-25). Pendiente de re-review. |
