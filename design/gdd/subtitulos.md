# Subtítulos (sistema 26)

> **Status**: Borrador (lote autónomo)
> **Author**: UX Designer (lote autónomo)
> **Last Updated**: 2026-11-09
> **System**: 26 · UI · Vertical Slice
> **Implements Pillar**: Tensión sin castigo (quien lee vive la misma línea de tiempo que quien oye) · Información incompleta (el subtítulo transcribe, no explica ni añade pistas) · Autonomía como progresión (nada obliga a leer para avanzar: ninguna pista vive solo en el sonido, 9) · El espacio expresa la emoción (banda mínima, sin luz propia)
> **Depende de**: 6 Ajustes persistentes · 18 Base de contenido narrativo · 23 Director de audio · 3 Estado y bus de eventos (avisos)

## Summary

26 es la capa de texto que transcribe lo que se oye: las voces (`VO_V_*`, `VO_G_*`, `MEGA_*`) y un pequeño conjunto de sonidos con significado (`SFX_BREATH_BROKEN` y los sustos que se acercan). Reacciona a los avisos de 23 («línea iniciada», «terminada», «sin audio», «fallida») y a «línea pedida», lee el texto de 18, aplica tamaño, fondo y nombre de hablante de 6, y vive en una banda inferior que el prompt (24) respeta. Está activado por defecto. No decide cuándo suena nada, no bloquea nunca y no cambia ningún tiempo del juego.

## Overview

El slice (§14, §16) exige subtítulos y que el menú de pausa los ofrezca. Contratos ‡ que este GDD cumple: de 22, subtitular `SFX_BREATH_BROKEN` con `SUB_BREATH_BROKEN` solo si los subtítulos están activos (regla 20 de 22) y dar a una línea «sin audio/fallida» el tiempo `fallback_s` (regla 25 de 22); de 9, mostrar `VO_G_07` durante `fallback_s` (14,0 s) con y sin audio (R17 y AC-P5-17 de 9/15); de 21, que `t_lectura_s` sea la duración de una línea sin audio sin `fallback_s`; de 23, consumir «línea iniciada» ‡ (R15) y la pausa de `VO_G_07` (R16, OQ 9); de 6, leer `subtitulos_activos` y añadir al catálogo los ajustes de tamaño y fondo (nota de la regla 1 de 6); de 24, no pisar el pie.

26 es **solo presentación**: escucha, compone texto y lo dibuja. Es un sistema de lectura pasiva (sin entrada del jugador salvo la configuración, que vive en 25 y 30).

## Player Fantasy

Quien no oye, o juega sin sonido, oye el edificio igual: la voz del Guardián llega por el auricular, el sonido que se acerca y nunca llega deja su rastro escrito, y todo ocurre al mismo ritmo que para los demás. El texto es discreto: ni un rótulo de cine, ni un parpadeo que rompa la oscuridad. Quien oye apenas lo nota; quien lo necesita no echa nada en falta. Test de pilar: entre un subtítulo que explica el susto («¡algo se acerca!») y uno que solo nombra el sonido («[Sillas rodando a lo lejos]»), el segundo; entre esperar al audio o seguir, seguir (D23).

## Detailed Rules

### A. Qué se subtitula

1. **Voces.** Toda línea de 18 con prefijo `VO_V_`, `VO_G_` o `MEGA_` tiene subtítulo, con audio o sin él. Sin texto en 18 (clave ausente) 26 no inventa nada: registra la advertencia, no muestra bloque vacío y la línea de tiempo no cambia.
2. **Sonidos con subtítulo.** Solo los que 18 declara con clave `SUB_*` (tipo «sonido no verbal»). Lista del slice (†, ver OQ 2): `SUB_BREATH_BROKEN` (obligatorio, regla 20 de 22), `SUB_CHAIRS_ROLL`, `SUB_TYPING_FAR`, `SUB_PHONE_BUZZ`. No se subtitulan: pasos, clics de interfaz, feedback de puzle, ambiente, música, la respiración inicial `SFX_CALL_BREATH` (D22-20) ni la muestra de volumen `UI_VOL_MUESTRA` (R25 de 23).
3. **Formato de sonido.** Entre corchetes y sin nombre de hablante: «[Llanto contenido]». Es un texto neutro que nombra el sonido, nunca su causa ni su significado (pilar Información incompleta). El texto lo cierra el writer (OQ 5 de 22).
4. **Efectos dentro de una línea.** Los sonidos incrustados en `VO_G_07` (pasos, sillas, tecleo, puerta; slice §14) **no** se subtitulan aparte: 18 puede incluirlos entre corchetes en el propio texto del segmento si el writer lo decide (OQ 3).

### B. Cuándo aparece y desaparece (sincronía)

5. **Suscripciones.** 26 escucha «línea pedida» (guarda `line_id` y `fallback_s`), «línea iniciada» ‡, «línea terminada», «línea sin audio», «línea fallida», «sonido pedido» de los `SFX_*` de la regla 2, «pausa abierta/cerrada», y los avisos de cambio de ajustes. No llama a 23 ni a 21.
6. **Con audio.** El bloque aparece en el fotograma en que llega «línea iniciada» (no en «línea pedida», porque una línea puede esperar en cola, 23 R10, R15) y se retira `t_cola_sub_s` (0,4†) después de «terminada», salvo que F1 exija más.
7. **Duración mínima.** Un bloque nunca está menos de `t_lectura_s` (F1) aunque el audio acabe antes, con tope `t_sub_max_s` (8,0†) por bloque. Si otra línea del mismo canal llega antes, el bloque anterior se retira al terminar su mínimo, no antes.
8. **Sin «línea iniciada».** Si 23 no emite el aviso opcional, el bloque aparece en la **señal de línea pedida + 0,0 s** y se retira en «terminada» (mismo mínimo). La ausencia de avisos se resuelve con el tope de 9/22: `fallback_s + line_grace_s` (23 R8, R12).
9. **Sin audio o fallida.** Con «línea sin audio» o «línea fallida» el bloque aparece al momento y dura `fallback_s` de la petición; si la petición no lo traía, `t_lectura_s` del texto (47 de 23). Es el mismo tiempo que 9, 21 y 22 esperan: **26 no los retiene ni los adelanta** (marco de 9: «ni más ni menos»).
10. **Silenciar no acorta.** Con un volumen a cero la línea sigue «con audio» en lo que a 26 respecta: mismos avisos, mismos tiempos (D23-2).
11. **Cortes.** «Terminada» con causa `corte`, `interrumpida` o `watchdog` retira el bloque tras `t_cola_sub_s`, también si no se cumplió el mínimo de la regla 7 cuando la causa es `interrumpida` (22 interrumpe con `VO_G_14_*`, `SFX_BREATH_BROKEN`: no se deja un texto colgado de una voz cortada).
12. **Sonidos con subtítulo.** Aparecen en «sonido pedido» y duran la duración del sonido del catálogo (`SFX_BREATH_BROKEN`: 4,0 s†, AC-22-25), con mínimo `t_sub_sfx_min_s` (1,5†). Un sonido en lazo (`SFX_PHONE_BUZZ`) se subtitula **una vez por inicio de lazo**, no por pulso.
13. **`VO_G_07` en dos segmentos.** 18 entrega el texto como dos segmentos (A y B) con la pausa entre ellos. Con audio: se muestra A en «línea iniciada» y B tras la pausa del fichero; el instante de B es `seg_b_inicio_s` ‡ si 18 lo aporta, y si no, F2 (reparto por caracteres). Sin audio: A, pausa `pausa_segmento_s` (1,2†, 23 R16) y B, repartidos en `fallback_s` = 14,0 s con F2. Cierra la OQ 9 de 23. La suma de los dos bloques cubre toda la ventana: el último se retira con la señal de fin.

### C. Composición

14. **Banda.** Una banda inferior centrada, ancho `sub_ancho_pct` (60† de la anchura de viewport, margen mínimo lateral 5 %), con margen inferior `sub_margen_inf_pct` (7†, dentro de la zona segura de 5 % de 1,10 de 30). Nunca ocupa la parte central ni se mueve con la cámara; no se ancla al altavoz.
15. **Bloques.** Un bloque = un hablante + hasta `sub_lineas_max` (2†) líneas de `sub_car_linea` (42†) caracteres. Un texto más largo se parte en **páginas** por oraciones, cada una con duración proporcional (F2). Máximo `sub_bloques_max` (2†) bloques a la vez, apilados con el más reciente abajo. Una tercera línea simultánea sustituye al más antiguo una vez cumplida su duración mínima de 1,0 s†; si no la ha cumplido, espera (cola de 1, sin pérdida de texto; si desborda se descarta el más antiguo y se registra).
16. **Nombre de hablante.** Texto delante del bloque, en la forma `NOMBRE:`, según el prefijo: `VO_V_` → «Vera», `VO_G_` → «Guardián», `MEGA_` → «Megafonía» (claves `SUB_HABLANTE_*` ‡ de 18). Con `subtitulos_hablante` verdadero (por defecto) se muestra siempre; falso, solo cuando hay dos bloques a la vez (para no confundirlos). Los sonidos no llevan nombre.
17. **No solo color.** El hablante se distingue por **tres canales redundantes**: el nombre escrito, el estilo (la voz interior de Vera en cursiva, la megafonía entre comillas angulares, el Guardián sin adorno) y, opcionalmente, un matiz de color de nombre que **nunca es el único canal** (art bible §4.5: ningún color es señal). Los sonidos van entre corchetes. Todos los estilos son legibles en escala de grises.
18. **Aspecto (visual: art-director).** Texto claro sobre fondo oscuro. El contraste texto-fondo mínimo es **7:1** (AAA) con el fondo «translúcido» u «opaco» y **4,5:1 contra la escena más clara posible** con «ninguno» (contorno de 2 px en el color de fondo, para que el texto sea legible sobre cualquier cuadro). Tipografía, color exacto y opacidad: art-director. Sin sombras animadas, sin destellos.
19. **Tamaño y fondo (de 6).** `subtitulos_tamano` (`pequeno`, `medio`, `grande`; F3) y `subtitulos_fondo` (`ninguno`, `translucido`, `opaco`) se aplican en el fotograma del aviso, incluso con una línea en curso (el bloque se recompone, sin reiniciar su reloj). El tamaño crece, el bloque no se recorta: crece hacia arriba y el ancho de 60 % no cambia (se reflowa en más líneas; ver F3 y regla 15).
20. **Transiciones.** Entrada y salida con fundido de `t_fundido_sub_s` (0,15†); con `reducir_movimiento`, 0,10 s fijos (como 24). Sin deslizamientos ni escalas.
21. **Activar y desactivar.** `subtitulos_activos` por defecto **verdadero** (regla 1 de 6, valor seguro también si el fichero falla). Falso: 26 no dibuja nada, pero sigue contando sus relojes (para poder mostrar lo restante si se reactiva a mitad de línea: el bloque vigente aparece con lo que queda de su duración). Los sonidos y avisos de 23 no cambian en ningún caso.

### D. Convivencia con otras capas y contextos

22. **Contextos.** Los subtítulos se dibujan en **todos** los contextos de Entrada donde puede sonar una línea: `exploración`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada` y `sin control`. También sobre el velo de la pausa (25) para poder previsualizar los ajustes (regla 26).
23. **Prompt (24).** 24 dibuja el pie de texto en la zona baja; 26 **reserva** la banda de F4. Mientras 26 tenga algún bloque visible, el pie de 24 se desplaza **hacia arriba** la altura de los bloques actuales más `sub_hueco_px` (12†), con el fundido de 24 (150 ms/100 ms), de modo que nunca se solapen ni se tapen. El anillo y la etiqueta de acción no se tocan (están sobre el objetivo, no en la banda). Si el desplazamiento no cabe (tamaño grande + 2 bloques), el pie se coloca encima y puede recortarse a 2 líneas, nunca el subtítulo. Cambio requerido en 24.
24. **Llamada (22).** En el contexto `llamada` 24 está oculto; las opciones de respuesta y la UI de 22 no pueden usar la banda inferior de F4 (cambio requerido en 22 / ADR de UI). Los subtítulos de la llamada (`VO_G_12*`, `VO_G_13*`, `VO_G_14_*`, `SFX_BREATH_BROKEN`) siguen las mismas reglas; durante la elección de respuesta el último bloque cumple su duración y se retira (no se «congela»).
25. **Pausa.** «Pausa abierta» congela todos los relojes de 26 (incluidos mínimos y `fallback_s` restante), coherente con 23 R41 y 21; «pausa cerrada» los reanuda. Los bloques visibles permanecen visibles (atenuados un 0 %: no se cambia su aspecto).
26. **Vista previa.** Las pantallas de 25 y 30 que ofrecen tamaño/fondo/nombre muestran una muestra fija `UI_SUB_MUESTRA` ‡ (texto de 18, dos líneas, con nombre) que cambia con el ajuste. No usa la banda de juego ni los avisos de 23.
27. **Carga y escenas.** «Carga iniciada» retira todos los bloques y vacía la cola sin fundido; «escena lista» no restaura nada (los bloques no se persisten, como el pie de 24). Los ajustes se leen de 6 al arrancar (6 R«Listo»); si 6 no está «Listo», se usan los valores iniciales (verdadero, `medio`, `translucido`, hablante verdadero).
28. **Prioridad de la banda.** Si compiten un subtítulo de voz y uno de sonido, ambos caben (bloques ≤ 2); el de sonido va debajo del de voz. Si ya hay 2 bloques de voz, el de sonido espera (cola de 1) hasta `t_sub_sfx_espera_s` (2,0†) y se descarta (registrado) pasado ese tiempo: es lo menos esencial.

### E. Lo que 26 no hace

29. No decide ni cambia la duración de ninguna línea ni del juego; no emite hechos ni avisos que otros consuman; no reproduce audio; no guarda; no ofrece historial ni relectura (fuera del slice); no traduce (el slice es solo español, OQ 4); no marca al hablante con iconos; no revela información que el audio no diga.

## Formulas

### F1 · Duración de lectura y duración visible

`t_lectura_s = t_lectura_base_s + n / cps_sub` (misma definición que F3 de 23: `t_lectura_base_s` 1,5†, `cps_sub` 15†; `n` = caracteres del texto sin tokens y sin corchetes). Rango: 1,5–8,0 s. Con tope `t_sub_max_s`.

Con audio: `t_visible = clamp(max(duracion_audio_s + t_cola_sub_s, t_lectura_s), 1,5, t_sub_max_s)`. Sin audio o fallida: `t_visible = fallback_s` (o `t_lectura_s` si no hay).

Ejemplos: «Lo sé» (5 car.), audio de 0,8 s → `max(1,2; 1,83)` = **1,83 s**. `VO_G_13D` (63 car.) audio de 4,0 s → `max(4,4; 5,70)` = **5,70 s**. `VO_G_07` sin audio: **14,0 s** repartidos con F2.

### F2 · Reparto de una línea en páginas o segmentos

`t_i = (T − P) · n_i / Σ n`, con `T` = ventana total (audio, o `fallback_s`), `P` = pausa entre segmentos (`pausa_segmento_s` 1,2† sin audio; 0 en páginas de una misma frase) y `n_i` = caracteres del bloque `i`. Cada `t_i` ≥ 1,0 s (si no, se fusionan con el contiguo). El último bloque cierra con la señal de fin.

Ejemplo: `VO_G_07` sin audio, `T` = 14,0, `P` = 1,2, A = 120 car., B = 80 car.: `T − P` = 12,8; A = 12,8 · 120/200 = **7,68 s**, pausa 1,2 s, B = **5,12 s**. Suma 14,0 s.

### F3 · Alto de texto con escala

`alto_px = max(round(base_px · s), alto_min_px)`, con `s = alto_viewport / 1080` y `alto_min_px` 20† (mismo criterio que 24). Bases a 1080p: `pequeno` 24†, `medio` 32†, `grande` 44†.

Ejemplo: a 720p (`s` = 0,667) con `medio`: 32 · 0,667 = 21,3 → **21 px**; con `pequeno`: 16 → se sube a **20 px**.

### F4 · Banda reservada

`alto_banda_px = sub_lineas_max · sub_bloques_max · alto_px · 1,25 + 2 · sub_hueco_px`. Con `medio` a 1080p: 2 · 2 · 32 · 1,25 + 24 = **184 px** (17 % de alto). Con `grande`: 2 · 2 · 44 · 1,25 + 24 = **244 px** (23 %). El tope del contenido de 22 y 24 es `alto_banda_px`.

## Edge Cases

- **Clave de texto ausente (18):** sin bloque, advertencia en el log; la línea de tiempo no cambia (R1).
- **«Terminada» sin «iniciada»:** el bloque (si existe por «pedida») se retira como en R6; si nunca apareció no se muestra uno tardío.
- **«Iniciada» después de «sin audio»:** imposible (nunca dos señales por línea, 23 R7); si ocurre, gana la primera y se registra.
- **Misma `line_id` repetida:** 23 la ignora; 26 también (no duplica bloque).
- **Texto de más de 2 líneas (R15):** se pagina; si aun así una página no cabe con tamaño `grande`, se parte por palabras. Nunca se recorta ni se reduce la letra por debajo de `alto_min_px`.
- **Cambio de ajuste a mitad de bloque:** recomposición inmediata, sin reiniciar el reloj (R19).
- **Cambio de idioma o de dispositivo:** los tokens `{accion:*}` de 18 se re-resuelven, como en 24; no reinicia el reloj.
- **Dos líneas de canales distintos a la vez:** ver R15 (máximo 2 bloques, nombre visible aunque `subtitulos_hablante` sea falso).
- **Interrupción de 22 (`VO_G_14_*`):** el bloque de la línea cortada se retira; el nuevo aparece (R11); no hay bloque «fantasma».
- **Pausa durante un fundido:** se congela a medio fundido y continúa.
- **Cambio de escena:** el cambio de escena (21) no retira bloques; sí «carga iniciada» (R27).
- **Alta carga:** el tope de 2 bloques acota el coste por fotograma; la composición se cachea por clave y ajuste.
- **Texto muy largo en 24 (pie) + subtítulo + tamaño grande:** R23; prioridad del subtítulo.
- **Muestra de vista previa durante el juego en pausa:** independiente de los bloques de juego, que siguen congelados bajo la pantalla.

## Dependencies

| Sistema | Tipo | Qué consume / ofrece | Notas |
|---|---|---|---|
| 6 Ajustes persistentes | **Dura** | Lee `subtitulos_activos` y, **propuestos ‡**, `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante`; avisos de cambio | Nota de la regla 1 de 6 |
| 18 Base de contenido narrativo | **Dura** | Texto por `line_id`, segmentos de `VO_G_07`, claves `SUB_*`, `SUB_HABLANTE_*`, `UI_SUB_MUESTRA` ‡, `fallback_s` | Solo lectura |
| 23 Director de audio | **Dura** (avisos) | «Línea iniciada» ‡, «terminada», «sin audio», «fallida»; `t_lectura_s`, `pausa_segmento_s` | R7, R15, R16 de 23 |
| 3 Estado y bus de eventos | **Dura** | Entrega de avisos de 23 y de pausa, cambios de ajustes, «carga iniciada»; 26 no emite | Índice, sección de eventos |
| 9 Marco de puzles / 15 Puzle 5 | Consumidor | `VO_G_07` durante `fallback_s` (14,0 s) | AC-P5-17 |
| 22 Llamada telefónica | Consumidor | `fallback_s`, `SUB_BREATH_BROKEN`; su UI respeta la banda | R20 y R25 de 22 |
| 21 Director de escenas | Sin dependencia | Mismos tiempos (`t_lectura_s`); 26 no depende de 21 | Índice |
| 24 Prompt de interacción | Convivencia | El pie sube sobre la banda (R23) | Cambio requerido |
| 25 Menú de pausa / 30 Accesibilidad | Ofrecen la pantalla | Muestran los ajustes de 26 y la vista previa | Cambio requerido en 25 |
| 1 Entrada y controles | Indirecta | Contexto activo (R22) y tokens de glifo | — |
| 19 Ordenador, 20 Documentos | Ninguna | No generan voz; los sonidos de la impresora no se subtitulan (OQ 2) | — |
| 17 Sistema de pistas | Ninguna | Las notas no son audio | — |

## Tuning Knobs

| Parámetro | Valor † | Rango seguro | Afecta a |
|---|---|---|---|
| `t_lectura_base_s` / `cps_sub` | 1,5 / 15 | 1,0–2,5 / 10–20 | Duración mínima legible (F1); mismo valor que 23 |
| `t_sub_max_s` | 8,0 | 5–12 | Tope por bloque |
| `t_cola_sub_s` | 0,4 | 0–1,0 | Persistencia tras el fin del audio |
| `t_sub_sfx_min_s` / `t_sub_sfx_espera_s` | 1,5 / 2,0 | 1–3 / 1–4 | Subtítulos de sonido |
| `sub_ancho_pct` | 60 | 50–80 | Longitud de línea |
| `sub_car_linea` / `sub_lineas_max` / `sub_bloques_max` | 42 / 2 / 2 | 32–56 / 2–3 / 1–3 | Densidad de texto |
| `sub_margen_inf_pct` / `sub_hueco_px` | 7 / 12 | 5–12 / 8–24 | Colocación |
| Bases de tamaño (`pequeno` / `medio` / `grande`) | 24 / 32 / 44 px a 1080p | 20–28 / 28–40 / 40–56 | Legibilidad (F3) |
| `alto_min_px` | 20 | ≥ 18 | Suelo absoluto |
| `t_fundido_sub_s` | 0,15 (0,10 con `reducir_movimiento`) | 0,05–0,3 | Transición |
| Mínimo antes de ceder el sitio | 1,0 s | 0,5–2,0 | Apilado (R15) |
| `subtitulos_tamano` / `subtitulos_fondo` / `subtitulos_hablante` (ajustes de 6) | `medio` / `translucido` / verdadero | enum / enum / bool | Aspecto, personalizable por el jugador |

## Acceptance Criteria

- **AC-26-01 (R21, L):** **GIVEN** un perfil nuevo, **THEN** `subtitulos_activos` es verdadero y el primer `VO_*` muestra su bloque sin tocar ajustes.
- **AC-26-02 (R6, I):** **GIVEN** `VO_G_12A` con audio, **THEN** el bloque aparece en el mismo fotograma que «línea iniciada» (±1 fotograma) y se retira `t_cola_sub_s` ±0,05 s tras «terminada».
- **AC-26-03 (R7, F1, L):** **GIVEN** `VO_V_*` «Lo sé» con audio de 0,8 s, **THEN** el bloque está visible 1,83 s ±0,05.
- **AC-26-04 (R9, I):** **GIVEN** «línea sin audio» con `fallback_s` 14,0, **THEN** el bloque aparece en ≤ 1 fotograma y dura 14,0 s ±0,05; 9 continúa exactamente a los mismos 14,0 s.
- **AC-26-05 (R13, F2, L):** **GIVEN** `VO_G_07` sin audio con A = 120 y B = 80 car., **THEN** A dura 7,68 s, pausa 1,2 s, B 5,12 s (±0,05).
- **AC-26-06 (R12, I):** **GIVEN** `SFX_BREATH_BROKEN` con subtítulos activos, **THEN** «[Llanto contenido]» (o el texto de 18) se muestra 4,0 s ±0,1; con subtítulos desactivados, nada.
- **AC-26-07 (R16, R17, V):** **GIVEN** un bloque de cada hablante en escala de grises, **THEN** se distinguen por nombre y estilo sin usar color.
- **AC-26-08 (R19, F3, L):** **GIVEN** 720p y `medio`, **THEN** el texto mide 21 px; con `pequeno`, 20 px.
- **AC-26-09 (R18, V):** **GIVEN** fondo `translucido`, **THEN** el contraste texto-fondo medido ≥ 7:1; con `ninguno` sobre la escena más clara, ≥ 4,5:1.
- **AC-26-10 (R19, I):** **GIVEN** un cambio de `subtitulos_tamano` con un bloque visible, **THEN** se recompone en el siguiente fotograma sin reiniciar su reloj.
- **AC-26-11 (R23, V):** **GIVEN** un pie de 24 y un bloque de 26 a la vez, **THEN** no se solapan en ningún tamaño; el pie queda sobre la banda.
- **AC-26-12 (R15, L):** **GIVEN** tres líneas simultáneas, **THEN** nunca hay más de 2 bloques y no se pierde texto antes de su mínimo de 1,0 s.
- **AC-26-13 (R25, I):** **GIVEN** pausa a mitad de bloque, **THEN** el tiempo restante no avanza; al reanudar, termina con lo que quedaba.
- **AC-26-14 (R11, I):** **GIVEN** `VO_G_14_*` interrumpe una línea, **THEN** el bloque anterior se retira en ≤ 0,4 s.
- **AC-26-15 (R21, I):** **GIVEN** reactivar los subtítulos con una línea a mitad, **THEN** aparece el bloque vigente con su tiempo restante.
- **AC-26-16 (R10, I):** **GIVEN** `vol_voces` = 0, **THEN** los bloques salen en los mismos instantes que con volumen 1,0.
- **AC-26-17 (R1, L):** **GIVEN** una clave sin texto, **THEN** no se dibuja bloque vacío y no cambia ninguna duración de 9, 21 o 22.
- **AC-26-18 (R27, I):** **GIVEN** «carga iniciada», **THEN** todos los bloques desaparecen y la cola queda vacía.
- **AC-26-19 (R22, V):** **GIVEN** cada contexto de Entrada con una línea en curso, **THEN** el bloque es visible y no tapa la elección de respuesta de 22.
- **AC-26-20 (R20, V):** **GIVEN** `reducir_movimiento`, **THEN** el fundido es de 0,10 s sin deslizamientos.

## Decisiones tomadas

| Nº | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D26-1 | Activados **por defecto** (verdadero) | Preguntar en el primer arranque | Una pregunta previa rompe la inmersión y el coste de ver texto sobrante es bajo (pilar Tensión sin castigo) |
| D26-2 | El bloque nace en «línea iniciada», no en «línea pedida» | Mostrar en «pedida» | Una línea puede esperar en cola (23 R10); el texto se adelantaría al audio |
| D26-3 | Duración mínima = `t_lectura_s` aunque el audio sea más corto | Retirar con el audio | Una frase de 1 s no es legible; no altera ningún tiempo de juego |
| D26-4 | «Sin audio» usa `fallback_s` de la petición | Usar `t_lectura_s` siempre | 9 y 22 esperan `fallback_s`; igualar evita un hueco o un texto cortado (marco de 9) |
| D26-5 | Hablante con nombre escrito + estilo; el color solo es refuerzo | Color por personaje | Art bible §4.5 y checklist de accesibilidad: no solo color |
| D26-6 | Subtítulo gana al pie de 24 (el pie sube) | Subtítulo arriba | El pie es ambiente; el subtítulo es información; la zona inferior es la costumbre de lectura (mental model) |
| D26-7 | 3 ajustes nuevos en 6: tamaño, fondo, hablante | Un solo ajuste «subtítulos grandes» | Las tres necesidades son independientes (baja visión, contraste, confusión de voces); coste mínimo |
| D26-8 | Subtitular los sustos como nombre del sonido, sin causa | No subtitular sonidos | Quien no oye pierde un cuarto de la tensión; el texto neutro respeta Información incompleta |
| D26-9 | Máximo 2 bloques y 2 líneas | Cola ilimitada | Evita muros de texto; la elección de seguir con el subtítulo importa más que el archivo completo |
| D26-10 | `VO_G_07`: 2 bloques con F2 sin audio | Un solo bloque de 14 s | El guion tiene dos segmentos con pausa; un bloque único sería un muro de texto |
| D26-11 | Sin historial de líneas | Registro de diálogo | Fuera del alcance del slice; anotado en OQ 4 |

## Open Questions

| Nº | Pregunta | Valor por defecto | Quién |
|---|---|---|---|
| 1 | ¿`seg_b_inicio_s` de `VO_G_07` puede venir como metadato de 18, o se usa solo F2? | F2 por caracteres | 18 / audio |
| 2 | ¿Qué sonidos (sillas, tecleo lejano, timbre, impresora) llevan subtítulo? Toca el pilar Información incompleta | `SUB_BREATH_BROKEN` + sillas + tecleo + timbre; no la impresora | Usuario / narrative-director |
| 3 | ¿Los efectos incrustados de `VO_G_07` se escriben entre corchetes en el texto? | No | Writer |
| 4 | ¿Historial de líneas y otros idiomas? | Fuera del slice | Usuario |
| 5 | ¿El texto de `SUB_BREATH_BROKEN` es «[Llanto contenido]» o más sobrio? | Provisional del writer (OQ 5 de 22) | Writer |
| 6 | ¿Valores de la banda y el tamaño base para playtest? | Los † | Playtest |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| `ajustes-persistentes.md` (6) | Añadir al catálogo `subtitulos_tamano` (enum `pequeno`/`medio`/`grande`, `medio`), `subtitulos_fondo` (enum `ninguno`/`translucido`/`opaco`, `translucido`) y `subtitulos_hablante` (bool, verdadero); lector: 26; ofrecidos por 25 y 30 |
| `base-de-contenido-narrativo.md` (18) | Claves `SUB_*` (tipo sonido no verbal), `SUB_HABLANTE_*` y `UI_SUB_MUESTRA`; segmentos de `VO_G_07` con `seg_b_inicio_s` opcional; texto y `fallback_s` por `line_id` |
| `director-de-audio.md` (23) | Confirmar «línea iniciada» (R15) como contrato de 26; cerrar OQ 9 con R13 de este GDD; «sonido pedido» de los `SFX_*` con subtítulo |
| `prompt-de-interaccion.md` (24) | El pie sube sobre la banda de 26 (R23) |
| `llamada-telefonica.md` (22) | Su UI no usa la banda inferior (R24); confirmar el contrato de `SUB_BREATH_BROKEN` |
| `menu-de-pausa.md` (25) | Pantalla de subtítulos con tamaño, fondo y nombre, y vista previa `UI_SUB_MUESTRA` (R26) |
| `estado-y-bus-de-eventos.md` (3) | Confirmar que 26 se suscribe a «pausa abierta/cerrada» y a los avisos de 23 |
| `systems-index.md` | Fila 26: Designed; añadir dependencia blanda de 3 si procede |

## Entradas para el registro (†=propuesta)

| Entrada | Tipo | Valor |
|---|---|---|
| `t_lectura_base_s` † / `cps_sub` † | constante | 1,5 / 15 (comparte con 23) |
| `t_sub_max_s` † | constante | 8,0 |
| `t_cola_sub_s` † | constante | 0,4 |
| `sub_bloques_max` † / `sub_lineas_max` † / `sub_car_linea` † | constantes | 2 / 2 / 42 |
| `subtitulos_tamano` † / `subtitulos_fondo` † / `subtitulos_hablante` † | ajustes de 6 | `medio` / `translucido` / verdadero |
| `SUB_BREATH_BROKEN`, `SUB_CHAIRS_ROLL` †, `SUB_TYPING_FAR` †, `SUB_PHONE_BUZZ` † | claves de 18 | sonidos subtitulados |
| `SUB_HABLANTE_VERA` † / `_GUARDIAN` † / `_MEGA` † | claves de 18 | nombres de hablante |
| `UI_SUB_MUESTRA` † | clave de 18 | muestra de vista previa |
| Banda de subtítulos (`alto_banda_px` F4) † | fórmula | 184 px (1080p, `medio`) |

## Historial

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-11-09 | Primer borrador (lote autónomo) | UX Designer |
