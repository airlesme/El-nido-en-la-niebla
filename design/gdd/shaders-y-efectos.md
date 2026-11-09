# Shaders y efectos de superficie (sistema 29)

> **Status**: Borrador (lote autónomo)
> **Author**: Technical Artist (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Información incompleta (el cristal y el espejo muestran solo lo que la luz o el ángulo permiten; ningún efecto añade pistas que no estén en los datos) · Autonomía como progresión (las ayudas visuales las pide el jugador y nunca resuelven) · El espacio expresa la emoción (superficies frías, sobrias, legibles; sin destellos) · Tensión sin castigo (sin parpadeos, sin avisos de fallo; `reducir_movimiento` respetado)

## Summary

Los shaders y efectos de superficie dan forma visual a lo que los puzles 2 y 5 deciden: el **cristal del memorando** (fragmentos F1–F3 y sello revelados por las lámparas, vista previa en espejo, halo del haz), el **espejo de la diferencia** (foto reflejada que rota con θ, superposición `FADE` y contorno `OUTLINE` de Vera) y los resaltados de pista de 9 (`HIGHLIGHT`, `MARK_LIT`, marcas del suelo). El sistema es **solo presentación**: no escribe hechos, no decide cuándo se ve nada ni lee estado de puzle; recibe órdenes («enciende F2», «contorno de Vera, 2,0 s») y las dibuja. Se entrega en dos niveles: una **versión provisional sin shader** (materiales estándar y texturas, MVP, sirve para el prototipo temprano del cristal) y la versión final con cuatro shaders `.gdshader` baratos, sin lectura de pantalla, válidos en Forward+ y en Compatibility.

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
5. **Sin destellos.** Ningún efecto cambia la luminancia de más de 0,25 (relativa) en menos de 100 ms ni pulsa por encima de 2 Hz. Esto cumple por construcción `reducir_sobresaltos`, que 29 **no necesita leer** (6 lo entrega solo a 23 y 28).
6. **Sin lectura de pantalla.** Ningún shader de 29 usa `hint_screen_texture` ni `hint_depth_texture` (mantiene Compatibility y evita un pase completo). Todos son `shader_type spatial`.

### B. Inventario de shaders

Nombres `[type]_[category]_[name].gdshader`, en `assets/shaders/`; un shader por archivo; funciones comunes en `assets/shaders/include/fx_common.gdshaderinc` vía `#include` (4.3+; verificar en el editor instalado 4.7.2, ver Open Questions).

7. **`spatial_surface_glass_memo.gdshader`** (cristal `B04`). Capas, de abajo arriba: (a) película del cristal (color casi negro frío, `L_bg` ≤ 0,06; ruido suave de 1 muestra, opcional); (b) reflejo de 28 (`reflection_tex`, ver C); (c) fragmentos: una textura atlas con F1, F2, F3 y sello; cada uno con su propia alfa uniforme `frag_alpha[4]`; (d) vista previa en espejo; (e) halo. Máximo 4 muestras de textura por píxel (atlas de fragmentos, máscara de halo, película, reflejo).
8. **`spatial_surface_mirror_photo.gdshader`** (reflejo y foto de la caja de P5). Muestra una foto con rotación UV `theta_deg` alrededor del centro del marco; la foto de la caja usa `theta_deg = 0`. Una sola muestra de textura. **No contiene ningún término dependiente de θ distinto de la rotación** (ni brillo, ni enfoque, ni desenfoque, ni viñeta: regla 7 de 15).
9. **`spatial_fx_outline_mask.gdshader`** (contorno y resaltado). Para elementos planos (fotos, sellos, marcas): dibuja un contorno sobre una **máscara de silueta** (`outline_mask`, textura de 1 canal pregenerada por arte con el borde dilatado) o, para mallas, contorno por casco invertido (`cull_front`, extrusión en vértice). Dos modos: `PULSE` (resaltado temporal) y `PERSISTENT` (`MARK_LIT`).
10. **Efecto sin shader propio:** `FLOOR_MARKS` (`B08`) se resuelve con `StandardMaterial3D` y emisión animada por `Tween`; el número 1–4 es geometría/textura que ya existe y solo cambia `emission_energy_multiplier`. No justifica un `.gdshader`.
11. **Parámetros.** Todos los parámetros artísticos son `uniform` con tipo y rango, agrupados con `group_uniforms`; los que cambian por instancia (alfa de cada fragmento, `theta_deg`, intensidad del contorno) son `instance uniform` para no duplicar materiales ni romper el batching; los constantes (colores, grosor, frecuencia) son `uniform` normales leídos de datos. Nada se fija a mano en el shader (`coding-standards`: valores en datos).

### C. Cristal compartido con 28 (contrato)

12. **Propiedad.** 29 posee el material `mat_glass_memo` y el orden de composición; 28 posee la **imagen del reflejo** (qué se refleja y con qué retardo). 28 no toca la película, los fragmentos ni el halo.
13. **Interfaz de 28 hacia el cristal.** 28 entrega: `reflection_tex` (`sampler2D`, p. ej. un `SubViewport` o textura de silueta) y `reflection_strength` (0–1) mediante `set_shader_parameter` sobre `mat_glass_memo`. 29 **recorta** `reflection_strength` a `reflection_strength_max` (0,15†) en toda la superficie del cristal para garantizar F29-2; 28 puede pedir más y verá el tope.
14. **Reflejo bajo el texto.** En los píxeles donde `frag_alpha > 0` el reflejo se atenúa multiplicándolo por `1 − 0,5·frag_alpha` (el texto manda).
15. **Sin reflejo, sin fallo.** Si 28 no está o no entrega textura, `reflection_strength = 0` y el cristal funciona entero (28 es blanda).
16. **Las lámparas no se tocan.** La luz de las lámparas (haces, `SpotLight3D`) es escena de 4/28; 29 no la usa para decidir qué fragmento se ve. La visibilidad de un fragmento viene de `frag_alpha[i]`, no de iluminación real (R10 de 12: independencia de lámparas; una luz real podría solapar puntos).

### D. Cristal del memorando (órdenes de 12)

17. **Orden `set_fragment(id, visible)`** (`id` ∈ F1, F2, F3, SEAL). Fija el objetivo de `frag_alpha[id]` a 1 o 0; la alfa sigue F29-1 con `fragment_fade_s` = 0,8 s (valor de 12, R11), tanto al encender como al apagar. La visibilidad lógica es instantánea (la decide 12); 29 solo suaviza. Si la orden cambia a mitad de fundido, la alfa continúa desde su valor actual hacia el nuevo objetivo (sin salto).
18. **Texto legible.** Los fragmentos son texto **ya preparado** (textura generada desde `DOC_01` de 18 con una tipografía de trazo uniforme, sin serifas finas) y no se componen en tiempo de ejecución con `Label3D` en espejo. Orientación: legible desde el lado del jugador; solo `MIRROR_PREVIEW` usa la versión invertida horizontal. Tamaño mínimo de glifo: F29-3.
19. **`MIRROR_PREVIEW(fragment, duration_s)`.** Muestra durante `duration_s` (2,0 s† de 12) el texto de F1 **invertido** en una zona neutra definida en datos (`neutral_zone_uv`, rectángulo del cristal que no es ninguno de los 12 puntos). Entra y sale con el mismo fundido de 0,8 s (100 ms con `reducir_movimiento`). Opacidad máxima 0,7 y luminancia del texto igual a la de los fragmentos reales: es una pista legible, no un fantasma.
20. **`BEAM_HALO(points)`.** 12 decide cuándo (≤ `halo_distance_m` de la lámpara) y envía el punto actual de cada haz como coordenadas UV. 29 dibuja un **anillo doble** (dos circunferencias concéntricas finas) de radio `halo_radius_uv`, centrado en el punto, también si es un punto vacío; la forma (anillo) es la señal, no el color. No pulsa; entra en 0,8 s. No altera el texto bajo él: el anillo se dibuja alrededor, no encima (radio interior mayor que el glifo del fragmento).
21. **Sello (distractor).** Es un gráfico sin texto legible (D12-5) con el mismo fundido que un fragmento; su luminancia pico es ≤ la del texto, para que no compita con él.
22. **`play_resolution` de P2.** F1, F2 y F3 quedan encendidos permanentemente; la película puede tener un leve «aliento» de brillo (ver Tuning, `film_breath_amp` 0,03†, ≤ 0,5 Hz), apagado con `reducir_movimiento`. Sin cambio de cámara ni destello.
23. **`FLOOR_MARKS`.** Pone a `floor_mark_energy` (valor pico en datos) la emisión de los números 1–4 de `B08` y, en la marca de la posición actual de cada lámpara, añade un **segundo elemento no cromático**: un marcador en forma de punta (geometría/textura) además del aumento de brillo. 12 envía la posición actual; 29 no la calcula.

### E. Espejo de la diferencia (órdenes de 15)

24. **Rotación de la foto reflejada.** 15 fija `theta_deg` (continuo, el que el jugador gira) en el material del reflejo cada fotograma que cambia; 29 aplica la rotación en el shader (F29-6). Rotar el nodo en lugar de la UV es equivalente y es el **fallback** (versión provisional).
25. **Coincidencia en θ\*.** En |θ − θ\*| = 0 las dos fotos deben coincidir **figura por figura** con error de registro ≤ 1 px a 1080p (F29-6): ambas texturas comparten tamaño, orientación, filtrado y mapeo UV; el borde de la foto reflejada no se recorta distinto al de la caja. Es el requisito que 15 declara hacia 29 (contrato ‡).
26. **`FADE`** (resolución de 15): superpone la foto del reflejo (D04) sobre la foto de la caja con opacidad F29-1 durante `duration_s` (1,2 s); con `reducir_movimiento`: 100 ms fijos y la imagen final se mantiene hasta `duration_s` (regla 14b(b) de 9; los tiempos de 15 no cambian).
27. **`OUTLINE`** (resolución de 15): contorno **solo de la silueta de Vera** (presente en D04, no en la caja), `duration_s` = 2,0 s, entrada 0,8 s (100 ms con `reducir_movimiento`), luego mantenido hasta el cierre de la secuencia. Usa la máscara `vera_outline_mask` (arte). Forma: línea continua doble (trazo claro con borde oscuro) para que se lea sobre cualquier zona de la foto, **no** rojo/verde ni parpadeo.
28. **Resolver y reabrir.** Con `pendiente_revelacion` verdadero, la secuencia empieza desde 0 y 29 debe aceptar `FADE` otra vez desde alfa 0 (sin estado residual). Tras `SOLVED`, `restore_solved_presentation()` de 15 no pide efectos: 29 no dibuja nada en esa restauración.

### F. Resaltados de 9 (`HIGHLIGHT`, `MARK_LIT`)

29. **`HIGHLIGHT(targets, duration_s)`** (no interactivo; 3,0 s† en P5). Para cada objetivo con máscara registrada, modo `PULSE`: contorno visible `duration_s` con envolvente F29-4 (entrada y salida 0,25 s; 100 ms con `reducir_movimiento`; **sin pulso** con `reducir_movimiento`, intensidad constante). El contador de `duration_s` lo gobierna 9 (se detiene en pausa: AC-50 de 9); 29 expone `stop_highlight(target)` y no cuenta tiempo por su cuenta: dibuja mientras 9 no lo retire.
30. **`MARK_LIT`** (marca de 40°, `D01c/mark_40`). Modo `PERSISTENT`: contorno + **cuatro marcas de esquina** (forma, no color) con intensidad constante, hasta que acabe la sesión o se reinicie el nivel. 29 **no guarda el estado**: al abrir la vista, 9/15 vuelven a emitir `MARK_LIT` si la pista de nivel 3 se pidió (D15-17). No resuelve ni mueve el marco.
31. **Registro de objetivos.** Los objetos resaltables (`visual_elements`, `decor`) declaran en su escena un `Node` `FxTarget` con `target_id` (el ID del puzle, p. ej. `D01c/reflection`), la máscara y el mesh/quad a vestir. Un `target_id` sin `FxTarget` se ignora con un `push_warning` y la orden no falla (el puzle sigue; el texto de la pista ya informó).
32. **Un resaltado a la vez por objetivo.** Una orden nueva sobre el mismo objetivo sustituye a la anterior (reinicia la envolvente). `MARK_LIT` no se sustituye por `HIGHLIGHT`; se superponen sin apagarlo.

### G. API de órdenes (propuesta, ‡)

33. **Punto de entrada.** Un `Node` `SurfaceFx` en la escena de cada vista de puzle (no un autoload: dependency injection, testable) expone: `set_fragment(id, visible)`, `play_mirror_preview(fragment, duration_s)`, `set_beam_halo(points)`, `play_highlight(target_id, duration_s)`, `stop_highlight(target_id)`, `set_mark_lit(target_id)`, `play_fade(duration_s)`, `play_outline(duration_s)`, `set_theta(theta_deg)`, `clear_all()`. Quién las llama: 12 y 15 (resolución, estado de sus vistas) y la capa de pistas de 9 (efectos `HIGHLIGHT`/`AFFORDANCE`), vía señal o llamada directa; ver Cambios requeridos.
34. **Ajustes.** `SurfaceFx` lee `reducir_movimiento` de 6 al construirse y escucha su señal de cambio; un cambio afecta a la **siguiente** orden, no a la animación en curso (misma regla que 15 regla 25).
35. **Pausa.** El tiempo de las envolventes usa el reloj de juego (se detiene en pausa); un `Tween` en `PAUSE_MODE_PAUSABLE` equivalente. Las luces de `TIME` en shader no se congelan, por lo que los shaders de 29 **no usan `TIME`** para nada con significado (solo para `film_breath`, decorativo; cuando el juego está en pausa el aliento se detiene al fijar su fase por uniform desde el reloj de juego).

### H. Versión provisional sin shader (MVP)

36. **Contenido.** Hasta que existan los `.gdshader`: cada superficie usa `StandardMaterial3D` (sin sombreado, `shading_mode = unshaded`, transparencia alfa) con la textura de fragmentos; la alfa y la rotación se mueven con `Tween` sobre `albedo_color.a` y la rotación del nodo; `OUTLINE` y `HIGHLIGHT` son un `Sprite3D`/quad con la máscara de contorno y `modulate`; el halo es un quad con textura de anillo.
37. **Misma API.** `SurfaceFx` expone las mismas llamadas con la implementación provisional detrás (estrategia): sustituir el material no cambia a 12, 15 ni 9.
38. **Mismo listón de legibilidad.** La versión provisional debe pasar F29-2 y F29-3 (los mismos AC de legibilidad). No se acepta «provisional» ilegible: es la que se prueba en el prototipo temprano del índice.
39. **Fallback en producción.** Si un `ShaderMaterial` falla al compilar o falta el recurso, `SurfaceFx` cae a la implementación provisional de esa superficie y emite `push_error` una vez; el puzle sigue funcionando.

### I. Renderer y rendimiento

40. **Renderer.** El proyecto usa Forward+ (Godot 4.7). Los shaders de 29 evitan compute, lectura de pantalla y `hint_depth_texture`, por lo que también valen en Mobile y en Compatibility (OpenGL 3.3): el diseño no depende del renderer. En Compatibility, `instance uniform` y `#include` se verificarán en el prototipo (Open Questions).
41. **Transparencia.** Los fragmentos, halo y contorno son `blend_mix` (o `blend_add` para el halo), `unshaded`, `depth_draw_never`, con `render_priority` fijo (película 0, fragmentos 1, halo 2, contorno 3) para ordenar sin depender de la profundidad. Sin `discard` (el borde se suaviza por alfa; el `discard` solo para la máscara si el prototipo lo exige).
42. **Presupuesto.** F29-7. El reflejo de 28 (si usa `SubViewport`) cuenta en el presupuesto de 28, no en el de 29.
43. **Shader Baker (4.5+).** Los cuatro shaders se incluyen en la exportación con el Shader Baker para evitar el tirón de compilación en la primera aparición de un efecto (relevante: el primer `set_fragment` no debe provocar un tirón visible). Alternativa si no se usa: precalentar el material al abrir la vista, fuera de pantalla, durante la transición de apertura.

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
Valores de diseño: `L_txt` ≥ 0,80, `L_film` ≤ 0,06. Ejemplo peor caso: `L_bg_eff = 0,06 + 0,15·0,30 = 0,105` → `C = 0,85 / 0,155 = 5,48 ≥ 4,5`. Sin reflejo: `0,85/0,11 = 7,7`. `L` es luminancia relativa lineal del píxel renderizado (con el tonemapping del proyecto), medida en captura, no en la textura.

**F29-3 · Altura mínima de glifo en pantalla.**
`h_px = x_h · H / (2 · d · tan(fov/2))` con `x_h` = altura de la «x» en metros, `d` = distancia ojo–cristal en la vista de inspección, `fov` vertical, `H` = alto en píxeles.
Requisito: `h_px ≥ 14` a H = 1080 con el `fov` máximo de `campo_vision` (de 6; se asume 90° hasta confirmarlo). Despejando: `x_h ≥ 14 · 2 · d · tan(fov/2) / H`. Ejemplo: d = 1,2 m, fov = 90° → `x_h ≥ 14·2·1,2·1/1080 = 0,0311 m`. Se fija `x_h_min` = 0,032 m (margen) y arte ajusta el tamaño del texto en `B04`. A 720p el glifo medido (9,5 px) queda por debajo del listón: se acepta documentado, el slice apunta a 1080p (ver Open Questions).

**F29-4 · Envolvente del resaltado `PULSE`.**
`I(t) = I_base + I_amp · 0,5 · (1 + sin(2π · f · t))` con envolvente de entrada/salida `E(t)` (0,25 s; 0,1 s reducido), `I_final = I_min + (I(t) − I_min)·E(t)`.
`f` ≤ 2,0 Hz (valor 1,25†); `I_base` 0,6; `I_amp` 0,3; con `reducir_movimiento`: `I_amp = 0`, `I = I_base`. Variación máxima de luminancia por fotograma < 0,25 (regla 5). Ejemplo: f = 1,25 Hz, pico de intensidad 0,9 y valle 0,6, ciclo de 0,8 s.

**F29-5 · Grosor del contorno independiente de resolución.**
`w_px = clamp(round(H · 0,0035), 3, 6)` y en el shader `w_uv = w_px · fwidth(UV)` (derivadas de pantalla, disponibles en el lenguaje de shaders de Godot). Ejemplo: H = 1080 → 3,78 → **4 px**; H = 720 → 2,52 → 3 px (mínimo); H = 2160 → 7,56 → 6 px (tope). Contraste del contorno contra su entorno: trazo claro (`L` ≥ 0,70) con borde oscuro (`L` ≤ 0,05) a 1 px: `C ≥ 4,5` frente a cualquier fondo posible de la foto.

**F29-6 · Rotación UV y error de registro.**
`uv' = R(−θ) · (uv − c) + c`, `c` = (0,5; 0,5) (centro del marco interior), `R` = matriz 2D de giro. Error de registro en θ\*: `e_px = H · max(|Δuv|)` entre las dos fotos para los puntos de control de arte (esquinas de las figuras); debe ser `≤ 1 px`. Ejemplo: error UV de 0,0006 a H = 1080 → 0,65 px (pasa). El filtrado es `filter_linear_mipmap`; con `texture_repeat` desactivado (fuera de UV 0–1 se descarta a transparente, no se repite).

**F29-7 · Presupuesto de rendimiento (1080p, hardware de referencia del proyecto).**
`C_gpu = Σ_i c_i ≤ 0,5 ms` con todo activo a la vez (peor caso: cristal con 3 fragmentos + halo + previa; espejo con `FADE` + `OUTLINE`; no coexisten en la misma vista, así que el peor real es una vista). Reparto: `glass_memo` ≤ 0,20 ms, `mirror_photo` ≤ 0,10, `outline_mask` ≤ 0,10 por efecto, margen 0,10. Muestras de textura por píxel ≤ 4; draw calls añadidos por vista ≤ 6. Está dentro de la banda «Particles/VFX ≤ 1–2 ms» del presupuesto de renderizado general; el valor de 0,5 ms es propuesta del sistema (†).

## Edge Cases

1. **Orden sobre un objetivo sin `FxTarget` o sin máscara.** Se ignora con `push_warning`; la orden no falla ni bloquea el puzle (regla 31).
2. **`set_fragment` repetido o contradictorio en el mismo fotograma.** Gana la última; sin alfa fuera de [0,1].
3. **Cambio de `reducir_movimiento` en mitad de un fundido.** Termina el fundido en curso con su duración original; la siguiente orden usa el nuevo valor (regla 34).
4. **Pausa durante un fundido o un `HIGHLIGHT`.** El reloj de juego se detiene y la envolvente no avanza; al reanudar continúa (AC-50 de 9). El halo y `MARK_LIT` (estados) no se alteran.
5. **Salir de la vista a mitad de `FADE`/`OUTLINE`.** `clear_all()` apaga todo sin fundido (la vista ya no se dibuja). Al reabrir con `pendiente_revelacion`, 15 repite la secuencia desde 0 (regla 28).
6. **`MARK_LIT` pedido y puzle ya resuelto.** Sin efecto (9: una `AFFORDANCE` en puzle `RESUELTO` no tiene efecto); 29 no dibuja.
7. **Dos fragmentos solapados por arte.** No debería ocurrir (R10 de 12: puntos distintos). Si ocurre, gana el de índice mayor y se lanza `push_warning` en depuración.
8. **`BEAM_HALO` en un punto que cae en el sello o fuera del cristal.** En el sello se dibuja igualmente (el punto actual es el sello). Fuera de [0,1] en UV se recorta y no se dibuja.
9. **Reflejo de 28 con `reflection_strength` > tope.** Se recorta a 0,15 (regla 13); no hay aviso.
10. **Cambio de resolución o de ventana en vista.** El grosor del contorno se recalcula (F29-5) y los glifos conservan su tamaño en metros; si en 720p el glifo queda bajo el listón, se registra pero no se corrige (Open Questions).
11. **Fallo de compilación del shader.** Cae a provisional (regla 39); el puzle sigue resoluble y legible.
12. **Daltonismo (protanopia, deuteranopia, tritanopia).** Todas las señales se identifican por forma y luminancia (reglas 4, 20, 27, 30); una simulación en escala de grises no pierde información (AC-14).
13. **Modo de alto contraste del sistema operativo.** No existe en 6; el contraste de diseño (F29-2 ≥ 4,5) ya cubre el uso normal. Fuera de alcance del slice.
14. **Primer uso tras un arranque en frío.** El tirón de compilación se evita con Shader Baker o precalentamiento (regla 43); si aparece, se mide y se trata como defecto de presentación.

## Dependencies

| Sistema | Dirección | Naturaleza | Contrato |
|---|---|---|---|
| 12 Puzle 2 · Memorando | 29 depende | **Dura** (índice) | 12 envía `set_fragment`, `play_mirror_preview`, `set_beam_halo`, `FLOOR_MARKS` con las posiciones; da `neutral_zone_uv`, `fragment_fade_s` (0,8) y `mirror_preview_s` (2,0); exige legibilidad (R11, R21, F29-2/F29-3) |
| 15 Puzle 5 · Espejo | 29 depende | **Dura** (índice) | 15 fija `theta_deg`, pide `FADE` (1,2 s) y `OUTLINE` (2,0 s), exige coincidencia en θ\* (regla 25), sin ayuda de coherencia (regla 7 de 15) |
| 9 Marco de puzles | Blanda | Origen de `HIGHLIGHT`/`AFFORDANCE`; regla 14b (`reducir_movimiento` 100 ms); reloj de pausa | 29 no define qué pista se ve ni cuándo; solo cómo |
| 6 Ajustes | Blanda | Lee `reducir_movimiento` y su señal de cambio | No lee `reducir_sobresaltos` (regla 5) |
| 28 Atmósfera reactiva | Blanda (paralelo) | Reflejo del cristal | Regla C (12–16); 28 declara su lado |
| 4 Escenario/nivel, 10 Contenedores | Datos | Mallas y `FxTarget` en las escenas; `B04`, `B08`, `D01c/*`; 10 no se ve afectado | Arte fija tamaños y UVs |
| 18 Base de contenido | Datos | `DOC_01` por fragmentos; texturas generadas desde él en el pipeline | El texto del cristal no es traducible en tiempo real (Open Questions) |
| 23 Audio | Ninguna | 29 no emite audio | Sincronización de la grabación es de 15/23 |

Bidireccionalidad: 12 y 15 ya citan a 29 (`‡`); 9 y 28 deben citarlo (Cambios requeridos).

## Tuning Knobs

| Perilla | Valor | Rango seguro | Afecta | Origen |
|---|---|---|---|---|
| `fragment_fade_s` | 0,8 s | 0,4–1,2 | Ritmo de aparición del texto | 12 (slice B.2) |
| `fade_reduced_s` | 0,1 s | fijo (9, 14b) | Fundido con `reducir_movimiento` | 9 |
| `mirror_preview_opacity` | 0,7 | 0,5–0,9 | Visibilidad de la pista N1 | 29† |
| `reflection_strength_max` | 0,15 | 0,0–0,25 | Cuánto reflejo tolera el texto (F29-2) | 29† |
| `L_film_max` | 0,06 | 0,03–0,10 | Fondo del cristal | 29† |
| `x_h_min` | 0,032 m | 0,028–0,045 | Tamaño del texto (F29-3) | 29† |
| `halo_radius_uv` | 0,06 | 0,04–0,10 | Tamaño del anillo del haz | 29† |
| `highlight_pulse_hz` | 1,25 | 0,5–2,0 (tope duro 2,0) | Ritmo del resaltado | 29† |
| `outline_width_px` | 4 @1080p | 3–6 (F29-5) | Visibilidad del contorno | 29† |
| `film_breath_amp` | 0,03 | 0–0,06 | «Aliento» del cristal resuelto | 29† |
| `fx_gpu_budget_ms` | 0,5 | 0,3–1,0 | Presupuesto del sistema (F29-7) | 29† |
| `register_error_px_max` | 1,0 | 0,5–1,5 | Tolerancia de coincidencia en θ\* | 29† |

Todos viven en un `Resource` (`fx_config.tres`) por superficie, no en el shader (excepto los literales de la matriz de rotación).

## Acceptance Criteria

Evidencia visual en `production/qa/evidence/` (capturas retenidas) más pruebas unitarias donde la lógica lo permite.

- **AC-1 (regla 17, F29-1).** GIVEN `set_fragment(F2, true)` con reloj falso, THEN `frag_alpha[F2]` vale 0,5 a t = 0,4 s, 1,0 a t ≥ 0,8 s; con `reducir_movimiento`, 1,0 a t ≥ 0,1 s. Prueba unitaria sobre el modelo de fundido.
- **AC-2 (regla 17).** GIVEN fundido a t = 0,4 s, WHEN llega `set_fragment(F2, false)`, THEN la alfa desciende desde 0,5 sin salto.
- **AC-3 (F29-2).** GIVEN F1–F3 encendidos, THEN en captura a 1080p el contraste texto/fondo medido es ≥ 4,5 con el reflejo de 28 al tope y ≥ 7 sin reflejo. Captura retenida; vale para la versión provisional y la final.
- **AC-4 (F29-3).** GIVEN la vista del cristal a 1080p con el `fov` máximo, THEN la altura de la «x» medida en captura es ≥ 14 px.
- **AC-5 (regla 18).** Un playtester sin ayuda lee F1, F2 y F3 completos en el cristal (sin lupa) en la captura de resolución de P2. Test de lectura documentado.
- **AC-6 (regla 19).** GIVEN `MIRROR_PREVIEW(F1, 2,0)`, THEN el texto aparece invertido en `neutral_zone_uv`, no solapa ninguno de los 12 puntos, dura 2,0 s (± 1 fotograma) y se retira.
- **AC-7 (regla 20).** GIVEN un haz que apunta a un punto vacío y la pista N3, THEN se dibuja el anillo doble en ese punto, no se oculta ningún texto cercano; sin pista N3 no hay anillo.
- **AC-8 (regla 25, F29-6).** GIVEN θ = θ\*, THEN el error de registro entre ambas fotos es ≤ 1 px en las esquinas de control (captura ampliada).
- **AC-9 (regla 8).** GIVEN cualquier θ, THEN el brillo medio y la nitidez del reflejo no cambian con θ (la salida solo depende de la rotación). Inspección de código del shader + dos capturas a θ\* y θ\* + 20°.
- **AC-10 (reglas 26, 27).** GIVEN la resolución de P5, THEN `FADE` dura 1,2 s y `OUTLINE` 2,0 s (± 1 fotograma, reloj falso); `OUTLINE` rodea solo a Vera; con `reducir_movimiento` la entrada de ambos es de 100 ms y los `duration_s` no cambian.
- **AC-11 (regla 29, F29-4).** GIVEN `HIGHLIGHT` 3,0 s sin `reducir_movimiento`, THEN la frecuencia de pulso ≤ 2,0 Hz y la variación de luminancia por fotograma < 0,25; con `reducir_movimiento` la intensidad es constante.
- **AC-12 (regla 30).** GIVEN `MARK_LIT` pedido, THEN la marca permanece iluminada (con las cuatro marcas de esquina) hasta cerrar la sesión; tras cerrar y reabrir la vista, 9/15 reemiten y 29 la vuelve a dibujar. En un puzle `RESUELTO` no se dibuja.
- **AC-13 (regla 31).** GIVEN una orden con un `target_id` sin `FxTarget`, THEN no hay excepción, se emite un `push_warning` y el puzle sigue resoluble.
- **AC-14 (regla 4).** GIVEN capturas en escala de grises y con simulación de protanopia, deuteranopia y tritanopia del halo, `MARK_LIT`, `OUTLINE` y `HIGHLIGHT`, THEN cada señal se distingue de su fondo (contraste ≥ 4,5 por luminancia) y por su forma.
- **AC-15 (regla 5).** GIVEN cualquier efecto de 29, THEN no hay variación de luminancia > 0,25 en < 100 ms ni pulso > 2 Hz. Verificado con el modelo F29-4 y en vídeo de captura.
- **AC-16 (regla 14).** GIVEN `reflection_strength` = 1,0 pedido por 28, THEN el valor efectivo en el material es 0,15; GIVEN 28 ausente, THEN el cristal se ve completo.
- **AC-17 (regla 40).** GIVEN el proyecto en Forward+, THEN los cuatro shaders compilan sin advertencias; GIVEN una ejecución en Compatibility (si se prueba), THEN compilan y los AC-3 y AC-8 pasan. Ningún shader usa `hint_screen_texture` (búsqueda en el repositorio).
- **AC-18 (F29-7).** GIVEN la peor vista con todo activo en el hardware de referencia a 1080p, THEN el coste GPU de 29 medido con el perfilador es ≤ 0,5 ms y los draw calls añadidos ≤ 6.
- **AC-19 (reglas 36–39).** GIVEN la versión provisional, THEN pasa AC-1 a AC-8 con las mismas llamadas de API; GIVEN un `ShaderMaterial` roto, THEN la superficie cae a provisional y el puzle sigue resoluble.
- **AC-20 (regla 43).** GIVEN un arranque en frío, WHEN aparece el primer fragmento, THEN no hay un tirón > 50 ms (traza del perfilador).
- **AC-21 (regla 35).** GIVEN pausa en mitad de un `HIGHLIGHT`, THEN la envolvente no avanza y el `duration_s` restante continúa al reanudar.

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D29-1 | Los fragmentos son **texturas preparadas** (atlas desde `DOC_01`) con alfa por fragmento | Componer el texto con `Label3D` espejado en tiempo de ejecución | Control del contraste y del tamaño (F29-2/3), mismo resultado en provisional y final; el texto del cristal no cambia con el idioma del slice (único) |
| D29-2 | La **visibilidad del fragmento viene de un uniform**, no de la iluminación real | Iluminar el cristal con las luces reales y dejar que el shader lo lea | Garantiza R10 (independencia de lámparas) y legibilidad estable; no depende de sombras ni del renderer |
| D29-3 | **Cuatro shaders baratos**, todos `spatial`, sin pantalla ni profundidad | Pase de postproceso con `CompositorEffect` para el contorno | El slice no necesita pase completo; un contorno por quad cuesta menos y funciona en Compatibility |
| D29-4 | Contorno por **máscara de silueta** (planos) y casco invertido (mallas) | Stencil de 4.5 (no verificado en 4.7 en las referencias del proyecto) o detección de bordes por profundidad | Los resaltables del slice son fotos/marcas planas; la máscara es exacta, barata y predecible |
| D29-5 | Rotación de la foto del espejo **en el shader** (UV), con el nodo rotado como fallback | Rotar la malla | Bordes nítidos y control del registro (F29-6); la API de 15 (`theta_deg`) no cambia entre implementaciones |
| D29-6 | `SurfaceFx` es un **nodo por vista**, no un autoload | Singleton global | Inyección de dependencias y pruebas aisladas (coding standards) |
| D29-7 | Señales por **forma** (anillo doble, esquinas, línea doble, punta) y luminancia; el color cálido solo refuerza | Códigos de color (verde/rojo, ámbar) | Accesibilidad (sin dependencia de color) y tono sobrio del slice |
| D29-8 | 29 **no lee `reducir_sobresaltos`**; los efectos ya no tienen destellos | Escalar intensidades con esa opción | 6 solo la entrega a 23 y 28; sin destellos por diseño no hace falta |
| D29-9 | Estado persistente de `MARK_LIT` **no se guarda en 29**; se reemite | Que 29 recuerde la marca | 29 no escribe hechos ni tiene guardado; la fuente de verdad es el estado de pistas de 9 |
| D29-10 | `reflection_strength_max` **lo impone 29** en el cristal | Dejar a 28 libre de fijar el reflejo | La legibilidad del texto es del puzle; un reflejo fuerte arruinaría F29-2 |
| D29-11 | Versión **provisional primero** (materiales estándar + tween), con la misma API | Esperar al shader final para el prototipo | Es el mitigante del riesgo alto del índice: el cristal se prueba antes y el shader solo sustituye la implementación |
| D29-12 | Presupuesto propio de 0,5 ms (†) | Sin presupuesto hasta el perfilado | Un número desde el principio obliga a medir; se ajusta con datos |

## Open Questions

1. **¿Las vistas de P2 y P5 se renderizan como superficies 3D en el mundo (quads/mallas) o como `SubViewport`/UI?** Este GDD supone 3D en mundo (shaders `spatial`). Si fueran UI, habría que escribir variantes `canvas_item` con la misma API. Valor por defecto: 3D en mundo; confirmar con 4/7 antes de implementar. No cambia pilares.
2. **`campo_vision` máximo de 6.** Se asume 90° en F29-3. Si es mayor, `x_h_min` sube proporcionalmente. Por defecto: 90°.
3. **Resolución mínima soportada.** A 720p el glifo queda en 9,5 px (< 14). Por defecto: el slice apunta a 1080p; se documenta y se evalúa un ajuste de tamaño del texto en datos en la revisión de 21/ UX.
4. **Fundido de fragmentos con `reducir_movimiento`.** 14b de 9 habla de 100 ms para presentaciones de resolución; este GDD lo aplica también a los fragmentos del cristal por coherencia. Por defecto: 100 ms; confirmar con 9.
5. **`#include`, `instance uniform` y Shader Baker en el editor instalado (4.7.2) y en Compatibility.** No verificados en un proyecto real en este lote; se comprobarán en el prototipo. Por defecto: usar ambos; si fallan, duplicar utilidades y usar `ShaderMaterial` por instancia.
6. **Quién emite las órdenes de pista a `SurfaceFx`** (la vista, 9 por señal o 12/15 directamente). Por defecto: 9 emite una señal `hint_effect_requested` y la vista la reenvía a `SurfaceFx`. Pendiente de 9.
7. **Orientación del texto del cristal.** Este GDD fija: legible desde el jugador una vez encendido y solo la previa invertida. Si el diseño de 12 quisiera el contrario (texto espejo hasta resolver), cambiaría solo la uniform `mirrored`. Por defecto: lo descrito.
8. **Si hay `reducir_movimiento`, ¿se apaga el «aliento» de la película de P2 resuelto?** Por defecto: sí.

## Cambios requeridos en otros GDDs

- **9 Marco de puzles:** (a) citar a 29 como consumidor de los efectos `HIGHLIGHT`, `AFFORDANCE` (`MIRROR_PREVIEW`, `BEAM_HALO`, `FLOOR_MARKS`, `MARK_LIT`) y de `FADE`/`OUTLINE`; (b) definir la señal o el canal por el que se entregan a `SurfaceFx` (regla 33; Q6); (c) aclarar si 14b(b) del fundido de 100 ms cubre también fundidos de superficie fuera de la resolución (Q4); (d) mantener que 9 gobierna el `duration_s` del `HIGHLIGHT` y la pausa (regla 29).
- **12 Puzle 2:** (a) enviar a 29 `neutral_zone_uv`, `halo_radius_uv` (opcional) y las posiciones de `FLOOR_MARKS`; (b) citar `x_h_min`, F29-2 y F29-3 en R11/R21; (c) confirmar la orientación del texto (Q7); (d) sustituir en Visual/Audio Requirements «de 28/29» por la referencia a las reglas C y D de este GDD.
- **15 Puzle 5:** (a) citar el requisito de registro ≤ 1 px en θ\* (regla 25) y `theta_deg` como API hacia 29; (b) confirmar que `FADE`/`OUTLINE` se piden con `duration_s` 1,2 y 2,0 s y que 29 no cuenta el tiempo de la secuencia; (c) que el contorno solo se pide en `RESOLVING`.
- **28 Atmósfera reactiva:** (a) usar el contrato de las reglas 12 a 16 (uniforms `reflection_tex`, `reflection_strength`); (b) aceptar el tope de 0,15 (regla 13); (c) no tocar película, fragmentos ni halo; (d) conservar el reflejo retardado dentro de su presupuesto.
- **6 Ajustes:** confirmar que expone la señal de cambio de `reducir_movimiento` (regla 34) y el máximo de `campo_vision` (Q2).
- **4 Escenario / 10 Contenedores:** `FxTarget` en `B04`, `B08`, `D01c/reflection`, `D01c/box_photo`, `D01c/mark_40` y `C05/paper/stamp_N`; arte entrega `outline_mask`, `vera_outline_mask`, atlas de fragmentos y UVs registrados (AC-8).
- **`systems-index.md`:** pasar la fila 29 a «Borrador» al integrar este lote.

## Entradas para el registro (†=propuesta)

| Tipo | ID | Valor | Fuente / nota |
|---|---|---|---|
| constante | `reflection_strength_max` † | 0,15 | Regla 13; F29-2 |
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
