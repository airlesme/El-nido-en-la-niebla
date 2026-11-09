# Subtítulos (sistema 26)

> **Status**: Revisado (ronda de corrección 1) — pendiente de re-review
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
2. **Sonidos con subtítulo.** Solo los que 18 declara con clave `SUB_*` (tipo «sonido no verbal»). **Obligatorio:** `SUB_BREATH_BROKEN` (regla 20 de 22). **Propuesta pendiente de OQ 2** (†, decide el usuario): `SUB_CHAIRS_ROLL`, `SUB_TYPING_FAR`, `SUB_PHONE_BUZZ`; hasta que se resuelva, no se implementan. Las tres claves nuevas nacen **provisionales con marcador de pendiente** (18 R22). No se subtitulan: pasos, clics de interfaz, feedback de puzle, ambiente, música, la respiración inicial `SFX_CALL_BREATH` (D22-20) ni la muestra de volumen `UI_VOL_MUESTRA` (R25 de 23).
3. **Formato de sonido.** Entre corchetes y sin nombre de hablante: «[Llanto contenido]». Es un texto neutro que nombra el sonido, nunca su causa ni su significado (pilar Información incompleta). El texto lo cierra el writer (OQ 5 de 22).
4. **Efectos dentro de una línea.** Los sonidos incrustados en `VO_G_07` (pasos, sillas, tecleo, puerta; slice §14) **no** se subtitulan aparte: 18 puede incluirlos entre corchetes en el propio texto del segmento si el writer lo decide (OQ 3).

### B. Cuándo aparece y desaparece (sincronía)

5. **Suscripciones.** 26 escucha «línea pedida» (guarda `line_id` y `fallback_s`), «línea iniciada» ‡, «línea terminada», «línea sin audio», «línea fallida», «sonido pedido» de los `SFX_*` de la regla 2, `pause_opened` ‡ y «pausa cerrada» ‡ (nombres de 23/3), y los avisos de cambio de ajustes. No llama a 23 ni a 21.
6. **Con audio.** El bloque aparece en el fotograma en que llega «línea iniciada» (no en «línea pedida», porque una línea puede esperar en cola, 23 R10, R15) y se retira `t_cola_sub_s` (0,4†) después de «terminada», salvo que F1 exija más.
7. **Duración mínima y páginas.** Una línea con texto está visible, en conjunto, al menos `t_lectura_s` (F3 de 23, citada en F1) aunque el audio acabe antes. El tope `t_sub_max_s` (8,0†) es **por página**, no por línea: una línea cuyo audio o `t_lectura_s` supere 8,0 s se pagina (F2) y la suma de páginas cubre toda la voz. Si otra línea del mismo canal llega antes, el bloque anterior se retira al terminar su mínimo, no antes.
8. **Sin «línea iniciada» (excepción acotada a D26-2).** Si 23 no emite el aviso opcional, el bloque nace en «línea pedida» + 0,0 s **solo si no hay otra línea del mismo canal activa o pendiente** (la línea no ha podido entrar en cola); si la hay, espera a la «terminada» de esa. Se retira en «terminada» (mismo mínimo). El posible adelanto del texto sobre el audio es el coste asumido de la degradación y solo ocurre sin el aviso (D26-12). La ausencia de avisos se resuelve con el tope de 9/22: `fallback_s + line_grace_s` (23 R8, R12).
9. **Sin audio o fallida.** Con «línea sin audio» o «línea fallida» el bloque aparece al momento y dura `fallback_s` de la petición; si la petición no lo traía, `t_lectura_s` del texto (F3 de 23). Es el mismo tiempo que 9, 21 y 22 esperan: **26 no los retiene ni los adelanta** (marco de 9: «ni más ni menos»).
10. **Silenciar no acorta.** Con un volumen a cero la línea sigue «con audio» en lo que a 26 respecta: mismos avisos, mismos tiempos (D23-2).
11. **Cortes.** «Terminada» con causa `corte`, `interrumpida` o `watchdog` retira el bloque tras `t_cola_sub_s`, también si no se cumplió el mínimo de la regla 7 cuando la causa es `interrumpida` (22 interrumpe con `VO_G_14_*`, `SFX_BREATH_BROKEN`: no se deja un texto colgado de una voz cortada).
12. **Sonidos con subtítulo.** Aparecen en «sonido pedido» y duran la duración del sonido del catálogo (`SFX_BREATH_BROKEN`: 4,0 s†, AC-22-25), con mínimo `t_sub_sfx_min_s` (1,5†). Un sonido en lazo (`SFX_PHONE_BUZZ`) se subtitula **una vez por inicio de lazo**, no por pulso, y se retira con `stop`/`interrupt` de 23 (R34), al entrar en `llamada`, o a los `t_sub_sfx_lazo_s` (3,0†) si ninguno ocurre antes.
13. **`VO_G_07` en dos segmentos.** 18 entrega el texto como dos segmentos (A y B) con la pausa entre ellos. **Con audio:** A aparece en «línea iniciada» (`duracion_s` del aviso es la ventana `T`); B aparece en `seg_b_inicio_s` ‡ si 18 lo aporta; si no, en el instante que da F2 con `P` = `pausa_segmento_s` (1,2†) estimada **dentro** de `T` (en el fichero la pausa va incluida, 23 R16). **Sin audio:** A, pausa de 1,2 s y B, repartidos en `fallback_s` = 14,0 s con F2. En ambos casos B (≈96 car.) supera `t_sub_max_s` y se pagina dentro de su ventana (F2). La suma de bloques y pausa cubre toda la ventana; el último se retira con la señal de fin. **Es una propuesta, no cierra la OQ 9 de 23** hasta que 18 y 23 confirmen `seg_b_inicio_s`.

### C. Composición

14. **Banda.** Una banda inferior centrada, ancho `sub_ancho_pct` (60† de la anchura de viewport, margen mínimo lateral 5 %), con margen inferior `sub_margen_inf_pct` (7†, dentro de la zona segura de 5 % de 1,10 de 30). Nunca ocupa la parte central ni se mueve con la cámara; no se ancla al altavoz.
15. **Bloques.** Un bloque = un hablante + hasta `sub_lineas_max` (2†) líneas de `sub_car_linea` (42†) caracteres. Un texto más largo se parte en **páginas** por oraciones, cada una con duración proporcional (F2). `sub_car_linea` es el valor con `medio`; con otro tamaño se deriva del ancho fijo de banda (F3). Máximo `sub_bloques_max` (2†) bloques a la vez, apilados con el más reciente abajo. Una tercera línea simultánea sustituye al más antiguo una vez cumplido su mínimo `min(t_lectura_s, 1,0 s†)` (un único mínimo, ver R7); si no lo ha cumplido, espera (cola de 1, sin pérdida de texto; si desborda se descarta el más antiguo y se registra).
16. **Nombre de hablante.** Texto delante del bloque, en la forma `NOMBRE:`, según el prefijo: `VO_V_` → «Vera», `VO_G_` → «Guardián», `MEGA_` → «Megafonía» (claves `UI_SUB_HABLANTE_*` ‡ de 18, prefijo de interfaz para no confundirlas con las `SUB_<EVENTO>` de sonido de 18 R22). Con `subtitulos_hablante` verdadero (por defecto) se muestra siempre; falso, solo cuando hay dos bloques a la vez (para no confundirlos). Los sonidos no llevan nombre.
17. **No solo color.** El hablante se distingue por **tres canales redundantes**: el nombre escrito, el estilo (la voz interior de Vera en cursiva, la megafonía entre comillas angulares, el Guardián sin adorno) y, opcionalmente, un matiz de color de nombre que **nunca es el único canal** (art bible §4.5: ningún color es señal). Los sonidos van entre corchetes. Todos los estilos son legibles en escala de grises.
18. **Aspecto (visual: art-director).** Texto claro sobre fondo oscuro. El contraste se mide contra **fondos de referencia fijos** (blanco puro y negro puro tras el bloque), no contra «la escena»: con «opaco», **7:1** (AAA); con «translúcido», **7:1** con ambos fondos de referencia, lo que fija una opacidad mínima `sub_fondo_opacidad_min` (70 %†, art-director la confirma midiendo); con «ninguno», **4,5:1** del texto contra su contorno de 2 px (color de fondo) y el contorno es el único garante sobre cualquier cuadro. Tipografía, color exacto y opacidad final: art-director. Sin sombras animadas, sin destellos.
19. **Tamaño y fondo (de 6).** `subtitulos_tamano` (`pequeno`, `medio`, `grande`; F3) y `subtitulos_fondo` (`ninguno`, `translucido`, `opaco`) se aplican en el fotograma del aviso, incluso con una línea en curso (el bloque se recompone, sin reiniciar su reloj). El tamaño crece, el bloque no se recorta: crece hacia arriba y el ancho de 60 % no cambia; manda el **ancho en píxeles**: los caracteres por línea se derivan de él (F3) y el texto se repagina (regla 15).
20. **Transiciones.** Entrada y salida con fundido de `t_fundido_sub_s` (0,15†); con `reducir_movimiento`, 0,10 s fijos (como 24). Sin deslizamientos ni escalas.
21. **Activar y desactivar.** `subtitulos_activos` por defecto **verdadero** (regla 1 de 6, valor seguro también si el fichero falla). Falso: 26 no dibuja nada, pero sigue contando sus relojes (para poder mostrar lo restante si se reactiva a mitad de línea: el bloque vigente aparece con lo que queda de su duración). Los sonidos y avisos de 23 no cambian en ningún caso.

### D. Convivencia con otras capas y contextos

22. **Contextos.** Los subtítulos se dibujan en **todos** los contextos de Entrada donde puede sonar una línea: `exploración`, `lectura`, `inspección`, `vista cercana`, `ordenador`, `llamada` y `sin control`. También sobre el velo de la pausa (25) para poder previsualizar los ajustes (regla 26).
23. **Prompt (24).** 24 dibuja el pie de texto en la zona baja; 26 **reserva** la banda de F4. Mientras 26 tenga algún bloque visible, el pie de 24 se desplaza **hacia arriba** hasta quedar sobre el borde superior de los bloques actuales (margen inferior incluido) más `sub_hueco_px` (12†); la reserva completa de F4 solo es el tope de diseño para 22 y 24. El desplazamiento usa el fundido de 24 (150 ms/100 ms), de modo que nunca se solapen ni se tapen. El anillo y la etiqueta de acción no se tocan (están sobre el objetivo, no en la banda). Si el desplazamiento no cabe (tamaño grande + 2 bloques), el pie se coloca encima y puede recortarse a 2 líneas, nunca el subtítulo. Cambio requerido en 24.
24. **Llamada (22).** En el contexto `llamada` 24 está oculto; las opciones de respuesta y la UI de 22 no pueden usar la banda inferior de F4 (cambio requerido en 22 / ADR de UI). Los subtítulos de la llamada (`VO_G_12*`, `VO_G_13*`, `VO_G_14_*`, `SFX_BREATH_BROKEN`) siguen las mismas reglas; durante la elección de respuesta el último bloque cumple su duración y se retira (no se «congela»).
25. **Pausa.** `pause_opened` ‡ congela todos los relojes de 26 (incluidos mínimos y `fallback_s` restante), coherente con 23 R41 y 21; «pausa cerrada» ‡ los reanuda. Los bloques visibles permanecen visibles, sin cambio de aspecto.
26. **Vista previa.** Las pantallas de 25 y 30 que ofrecen tamaño/fondo/nombre muestran una muestra fija `UI_SUB_MUESTRA` ‡ (texto de 18, dos líneas, con nombre) que cambia con el ajuste. No usa la banda de juego ni los avisos de 23.
27. **Carga y escenas.** «Carga iniciada» retira todos los bloques y vacía la cola sin fundido; «escena lista» no restaura nada (los bloques no se persisten, como el pie de 24). Los ajustes se leen de 6 al arrancar (6 R«Listo»); si 6 no está «Listo», se usan los valores iniciales (verdadero, `medio`, `translucido`, hablante verdadero).
28. **Prioridad de la banda.** Si compiten un subtítulo de voz y uno de sonido, ambos caben (bloques ≤ 2); el de sonido va debajo del de voz. Si ya hay 2 bloques de voz, el de sonido espera (cola de 1) hasta `t_sub_sfx_espera_s` (2,0†) y se descarta (registrado) pasado ese tiempo: es lo menos esencial.

### E. Lo que 26 no hace

29. No decide ni cambia la duración de ninguna línea ni del juego; no emite hechos ni avisos que otros consuman; no reproduce audio; no guarda; no ofrece historial ni relectura (fuera del slice); no traduce (el slice es solo español, OQ 4); no marca al hablante con iconos; no revela información que el audio no diga.

## Formulas

### F1 · Duración de lectura y duración visible

**`t_lectura_s` es la de 23, no una propia:** `t_lectura_s = clamp(t_min_lect_s + n_car / cps_lect, t_min_lect_s, t_max_lect_s) + n_pausas · pausa_segmento_s` (F3 de 23: `t_min_lect_s` 1,5†, `cps_lect` 15†, `t_max_lect_s` 14,0†, `pausa_segmento_s` 1,2†; `n_car` = caracteres sin tokens ni corchetes). 26 la cita; no la redefine. Lo propio de 26 es `t_visible_linea` y `t_sub_max_s` por página.

Con audio: `t_visible_linea = max(duracion_audio_s + t_cola_sub_s, t_lectura_s)`, **sin tope por línea**; se reparte en `ceil(t_visible_linea / t_sub_max_s)` páginas como mínimo (F2), cada una ≤ `t_sub_max_s` (8,0†) y ≥ 1,0 s. Así una voz de 14 s nunca deja el texto retirado mientras suena. Sin audio o fallida: `t_visible_linea = fallback_s` (o `t_lectura_s` si no hay), paginada igual.

Ejemplos: «Lo sé» (5 car.), audio de 0,8 s → `max(1,2; 1,83)` = **1,83 s**. `VO_G_13D` (63 car.) audio de 4,0 s → `max(4,4; 5,70)` = **5,70 s**. `VO_G_07` con audio de 14,0 s → `max(14,4; …)` = **14,4 s**, 2 páginas como mínimo; sin audio: **14,0 s** repartidos con F2.

### F2 · Reparto de una línea en páginas o segmentos

`t_i = (T − P) · n_i / Σ n`, con `T` = ventana total (`duracion_s` de «línea iniciada» con audio, o `fallback_s` sin él), `P` = pausa entre segmentos (`pausa_segmento_s` 1,2†, **con y sin audio**: con audio es una estimación dentro de `T` cuando falta `seg_b_inicio_s`; 0 en páginas de una misma frase) y `n_i` = caracteres del segmento `i`. Cada `t_i` ≥ 1,0 s (si no, se fusionan con el contiguo). Si un segmento supera `t_sub_max_s`, se **pagina dentro de su ventana** por oraciones, repartiendo `t_i` por caracteres. El último bloque cierra con la señal de fin.

Ejemplo: `VO_G_07` (slice §12), `T` = 14,0, `P` = 1,2, A = «Venga, que somos un equipo» (26 car.), B = «No. Esa toma no. Lo pedí sin preguntarte, Vera. Lo pedí y después te lo conté como si fuera tuyo» (≈96 car.): `T − P` = 12,8; A = 12,8 · 26/122 = **2,73 s**, pausa 1,2 s, B = 12,8 · 96/122 = **10,07 s**. Suma 14,0 s. B > 8,0 s → 2 páginas por oraciones: «No. Esa toma no. Lo pedí sin preguntarte, Vera.» (≈47 car., ≈4,93 s) y «Lo pedí y después te lo conté como si fuera tuyo» (≈49 car., ≈5,14 s), cada una en 2 líneas de ≤ 42 car.

### F3 · Alto de texto con escala

`alto_px = max(round(base_px · s), alto_min_px)`, con `s = alto_viewport / 1080` y `alto_min_px` 20† (mismo criterio que 24). Bases a 1080p: `pequeno` 24†, `medio` 32†, `grande` 44†.

Ejemplo: a 720p (`s` = 0,667) con `medio`: 32 · 0,667 = 21,3 → **21 px**; con `pequeno`: 16 → se sube a **20 px**.

Caracteres por línea (el ancho de banda es fijo, `sub_ancho_pct`): `car_linea = floor(sub_car_linea · base_medio / base_tam)`. Con `medio` 42; `pequeno` floor(42·32/24) = **56**; `grande` floor(42·32/44) = **30**. Con `grande` la paginación usa 30 car./línea.

### F4 · Banda reservada

`alto_banda_px = sub_lineas_max · sub_bloques_max · alto_px · 1,25 + 2 · sub_hueco_px`. Con `medio` a 1080p: 2 · 2 · 32 · 1,25 + 24 = **184 px** (17 % de alto). Con `grande`: 2 · 2 · 44 · 1,25 + 24 = **244 px** (22,6 %, 23 %). A esto se suma el margen inferior: `alto_reservado_px = alto_banda_px + round(sub_margen_inf_pct · alto_viewport)` = 184 + 76 = **260 px** (24 %) con `medio`, 244 + 76 = **320 px** (30 %) con `grande`. **El tope del contenido de 22 y 24 es `alto_reservado_px`.**

## Edge Cases

- **Clave de texto ausente (18):** sin bloque, advertencia en el log; la línea de tiempo no cambia (R1).
- **«Terminada» sin «iniciada»:** si el bloque nació por la excepción de R8 (línea no en cola), se retira como en R6; si no había nacido (la línea esperaba) no se muestra uno tardío.
- **Audio más largo que `t_sub_max_s`:** se pagina (R7, F2); el texto no se retira mientras la voz sigue.
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
| 18 Base de contenido narrativo | **Dura** | Texto por `line_id`, segmentos de `VO_G_07`, claves `SUB_*`, `UI_SUB_HABLANTE_*`, `UI_SUB_MUESTRA` ‡, `fallback_s` | Solo lectura |
| 23 Director de audio | **Blanda** (avisos) | «Línea iniciada» ‡, «terminada», «sin audio», «fallida»; `t_lectura_s`, `pausa_segmento_s` | R7, R15, R16 de 23. Sin avisos, 26 degrada a `fallback_s` (R8, R9); 23 no espera a 26 (23 R8) |
| 3 Estado y bus de eventos | **Dura** | Entrega de avisos de 23 y de pausa, cambios de ajustes, «carga iniciada»; 26 no emite | Añadir 3 a la fila 26 y al orden del índice |
| 9 Marco de puzles / 15 Puzle 5 | Consumidor (**blanda**, como declara 9) | `VO_G_07` durante `fallback_s` (14,0 s) | AC-P5-17 |
| 22 Llamada telefónica | Consumidor (**blanda**, como declara 22 ‡) | `fallback_s`, `SUB_BREATH_BROKEN`; su UI respeta la banda | R20 y R25 de 22 |
| 21 Director de escenas | Sin acoplamiento directo | 21 (L134) usa la duración del subtítulo como fin de línea; el vínculo es **de datos** (`t_lectura_s` de 23), 26 no depende de 21 ni 21 de 26 | Índice; nota en 21 |
| 24 Prompt de interacción | Convivencia | El pie sube sobre la banda (R23); 24 debe nombrar a 26 | Cambio requerido |
| 25 Menú de pausa / 30 Accesibilidad | Ofrecen la pantalla | Muestran los ajustes de 26 y la vista previa | Cambio requerido en 25 |
| 1 Entrada y controles | Indirecta | Contexto activo (R22) y tokens de glifo | — |
| 19 Ordenador, 20 Documentos | Ninguna | No generan voz; los sonidos de la impresora no se subtitulan (OQ 2) | — |
| 17 Sistema de pistas | Ninguna | Las notas no son audio | — |

## Tuning Knobs

| Parámetro | Valor † | Rango seguro | Afecta a |
|---|---|---|---|
| `t_min_lect_s` / `cps_lect` / `t_max_lect_s` (**de 23**, no se duplican aquí) | 1,5 / 15 / 14,0 | 1–3 / 10–25 / 6–20 | Duración mínima legible (F1); la fuente es 23 F3 |
| `t_sub_max_s` | 8,0 | 5–12 | Tope por **página** |
| `t_sub_sfx_lazo_s` | 3,0 | 2–5 | Retirada de subtítulo de sonido en lazo sin `stop` |
| `sub_fondo_opacidad_min` | 70 % | 60–85 % | Contraste 7:1 con fondo translúcido (R18) |
| `t_cola_sub_s` | 0,4 | 0–1,0 | Persistencia tras el fin del audio |
| `t_sub_sfx_min_s` / `t_sub_sfx_espera_s` | 1,5 / 2,0 | 1–3 / 1–4 | Subtítulos de sonido |
| `sub_ancho_pct` | 60 | 50–80 | Longitud de línea |
| `sub_car_linea` / `sub_lineas_max` / `sub_bloques_max` | 42 / 2 / 2 | 32–56 / 2–3 / 1–3 | Densidad de texto |
| `sub_margen_inf_pct` / `sub_hueco_px` | 7 / 12 | 5–12 / 8–24 | Colocación |
| Bases de tamaño (`pequeno` / `medio` / `grande`) | 24 / 32 / 44 px a 1080p | 20–28 / 28–40 / 40–56 | Legibilidad (F3) |
| `alto_min_px` | 20 | ≥ 18 | Suelo absoluto |
| `t_fundido_sub_s` | 0,15 (0,10 con `reducir_movimiento`) | 0,05–0,3 | Transición |
| Mínimo antes de ceder el sitio | `min(t_lectura_s, 1,0 s)` | 0,5–2,0 | Apilado (R15) |
| `subtitulos_tamano` / `subtitulos_fondo` / `subtitulos_hablante` (ajustes de 6) | `medio` / `translucido` / verdadero | enum / enum / bool | Aspecto, personalizable por el jugador |

## Acceptance Criteria

- **AC-26-01 (R21, L):** **GIVEN** un perfil nuevo, **THEN** `subtitulos_activos` es verdadero y el primer `VO_*` muestra su bloque sin tocar ajustes.
- **AC-26-02 (R6, I):** **GIVEN** `VO_G_12A` con audio, **THEN** el bloque aparece en el mismo fotograma que «línea iniciada» (±1 fotograma) y se retira `t_cola_sub_s` ±0,05 s tras «terminada».
- **AC-26-03 (R7, F1, L):** **GIVEN** `VO_V_*` «Lo sé» con audio de 0,8 s, **THEN** el bloque está visible 1,83 s ±0,05.
- **AC-26-04 (R9, I):** **GIVEN** «línea sin audio» con `fallback_s` 14,0, **THEN** el bloque aparece en ≤ 1 fotograma y dura 14,0 s ±0,05; 9 continúa exactamente a los mismos 14,0 s.
- **AC-26-05 (R13, F2, L):** **GIVEN** `VO_G_07` sin audio con A = 26 y B ≈ 96 car. (texto del slice), **THEN** A dura 2,73 s, pausa 1,2 s, B 10,07 s en 2 páginas (≈4,93 s y ≈5,14 s), ninguna > 8,0 s (±0,05).
- **AC-26-21 (R7, F1, I):** **GIVEN** `VO_G_07` con audio de 14,0 s, **THEN** hay texto visible de forma continua durante toda la voz (páginas cubren ≥ 14,0 s + `t_cola_sub_s`) y ninguna página > 8,0 s.
- **AC-26-22 (R8, I):** **GIVEN** 23 sin emitir «línea iniciada» y sin otra línea del canal, **THEN** el bloque aparece en «pedida» + ≤ 1 fotograma y se retira en «terminada»; **GIVEN** otra línea del canal en curso, **THEN** espera a su «terminada».
- **AC-26-23 (R13, I):** **GIVEN** `VO_G_07` con audio sin `seg_b_inicio_s`, **THEN** B aparece en el instante de F2 con P = 1,2 s dentro de `duracion_s` (±0,1 s).
- **AC-26-24 (R16, L):** **GIVEN** `subtitulos_hablante` falso, **THEN** con un bloque no hay nombre y con dos bloques simultáneos ambos lo llevan.
- **AC-26-25 (R4, L):** **GIVEN** un efecto incrustado de `VO_G_07`, **THEN** no hay bloque de sonido aparte (solo aparece si el texto de 18 lo trae entre corchetes).
- **AC-26-26 (R5, L):** **GIVEN** 26 en ejecución, **THEN** no emite ni llama a 23 ni a 21 (solo se suscribe).
- **AC-26-27 (R24, V):** **GIVEN** el contexto `llamada` con elección de respuesta, **THEN** el último bloque cumple su duración y se retira; ni este ni la UI de 22 invaden `alto_reservado_px`.
- **AC-26-28 (R26, V):** **GIVEN** la pantalla de ajustes, **THEN** `UI_SUB_MUESTRA` cambia con tamaño/fondo/nombre sin usar la banda de juego.
- **AC-26-29 (R28, L):** **GIVEN** 2 bloques de voz y un subtítulo de sonido, **THEN** espera ≤ `t_sub_sfx_espera_s` (2,0 s) y se descarta con registro.
- **AC-26-30 (R12, I):** **GIVEN** `SFX_PHONE_BUZZ` en lazo, **THEN** el subtítulo se retira con `stop`/`interrupt` o a los 3,0 s.
- **AC-26-06 (R12, I):** **GIVEN** `SFX_BREATH_BROKEN` con subtítulos activos, **THEN** «[Llanto contenido]» (o el texto de 18) se muestra 4,0 s ±0,1; con subtítulos desactivados, nada.
- **AC-26-07 (R16, R17, V):** **GIVEN** un bloque de cada hablante en escala de grises, **THEN** se distinguen por nombre y estilo sin usar color.
- **AC-26-08 (R19, F3, L):** **GIVEN** 720p y `medio`, **THEN** el texto mide 21 px; con `pequeno`, 20 px.
- **AC-26-09 (R18, V):** **GIVEN** fondo `translucido` u `opaco` sobre fondos de referencia blanco y negro puros, **THEN** el contraste texto-fondo medido ≥ 7:1 (opacidad ≥ `sub_fondo_opacidad_min`); con `ninguno`, texto-contorno ≥ 4,5:1.
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
| D26-7 | 3 ajustes nuevos en 6: tamaño, fondo, hablante (**provisional, ver OQ 7**) | Un solo ajuste «subtítulos grandes» | Las tres necesidades son independientes (baja visión, contraste, confusión de voces); amplían el menú de pausa (25), por lo que decide el usuario |
| D26-8 | Subtitular los sustos como nombre del sonido, sin causa | No subtitular sonidos | Quien no oye pierde parte de la tensión; el texto neutro respeta Información incompleta. Solo `SUB_BREATH_BROKEN` es obligatorio (OQ 2) |
| D26-9 | Máximo 2 bloques y 2 líneas | Cola ilimitada | Evita muros de texto; la elección de seguir con el subtítulo importa más que el archivo completo |
| D26-10 | `VO_G_07`: 2 bloques con F2 sin audio | Un solo bloque de 14 s | El guion tiene dos segmentos con pausa; un bloque único sería un muro de texto |
| D26-11 | Sin historial de líneas | Registro de diálogo | Fuera del alcance del slice; anotado en OQ 4 |
| D26-12 | Sin «línea iniciada», el bloque nace en «pedida» solo si no hay otra línea del canal activa o pendiente (excepción a D26-2) | Esperar siempre a «iniciada» (sin texto si 23 no lo emite) o mostrar siempre en «pedida» | 23 R15 lo define opcional y 23 R8 no espera a 26: nunca puede faltar el texto de una voz; el adelanto solo es posible si la línea no ha podido esperar en cola |
| D26-13 | `t_sub_max_s` por página y `t_lectura_s` citada de 23 F3 | Tope por línea; fórmula propia con tope 8,0 | Con tope por línea el texto se retiraría con la voz aún sonando (`VO_G_07`, ≈14 s); una sola definición evita valores divergentes |
| D26-14 | Contraste medido contra fondos de referencia fijos con opacidad mínima | Contraste «contra la escena más clara» | La escena es variable y no es verificable; el contorno de 2 px cubre `ninguno` |
| D26-15 | Sonido en lazo: retirar en `stop`/`interrupt`/`llamada` o a `t_sub_sfx_lazo_s` | Duración inexistente del lazo | Un lazo no tiene duración; el texto no puede quedar colgado |
| D26-16 | `car_linea` derivado del ancho fijo según tamaño | Constante 42 con ancho variable | Con `grande` los 42 car. desbordarían los 60 % de ancho; manda el ancho en px |

## Open Questions

| Nº | Pregunta | Valor por defecto | Quién |
|---|---|---|---|
| 1 | ¿`seg_b_inicio_s` de `VO_G_07` puede venir como metadato de 18, o se usa solo F2? | F2 por caracteres | 18 / audio |
| 2 | ¿Qué sonidos (sillas, tecleo lejano, timbre, impresora) llevan subtítulo? Toca el pilar Información incompleta. **Decide el usuario** | Solo `SUB_BREATH_BROKEN`; los otros tres no se implementan hasta resolver | Usuario / narrative-director |
| 3 | ¿Los efectos incrustados de `VO_G_07` se escriben entre corchetes en el texto? | No | Writer |
| 4 | ¿Historial de líneas y otros idiomas? | Fuera del slice | Usuario |
| 5 | ¿El texto de `SUB_BREATH_BROKEN` es «[Llanto contenido]» o más sobrio? | Provisional del writer (OQ 5 de 22) | Writer |
| 6 | ¿Valores de la banda y el tamaño base para playtest? | Los † | Playtest |
| 7 | ¿Se añaden al menú de pausa (25) los tres ajustes `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante`? Amplía el alcance del menú. **Decide el usuario** | Sí, con los valores †; si no, solo `subtitulos_activos` y valores fijos `medio`/`translucido`/verdadero | Usuario |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| `ajustes-persistentes.md` (6) | Añadir al catálogo `subtitulos_tamano` (enum `pequeno`/`medio`/`grande`, `medio`), `subtitulos_fondo` (enum `ninguno`/`translucido`/`opaco`, `translucido`) y `subtitulos_hablante` (bool, verdadero) (sujeto a OQ 7); lector: 26. El bloque «restablecer todos» pasa de 12 a 15 claves |
| `base-de-contenido-narrativo.md` (18) | Claves `SUB_*` nuevas (`SUB_CHAIRS_ROLL`, `SUB_TYPING_FAR`, `SUB_PHONE_BUZZ`) como **provisionales con marcador de pendiente** (R22; solo `SUB_BREATH_BROKEN` es única del lote hoy), `UI_SUB_HABLANTE_*` y `UI_SUB_MUESTRA`; segmentos de `VO_G_07` con `seg_b_inicio_s` opcional (no está en R9/AC-09 de 18); texto y `fallback_s` por `line_id` |
| `director-de-audio.md` (23) | Confirmar «línea iniciada» (R15) como contrato de 26; `seg_b_inicio_s` para la OQ 9 (R13 de 26 es **propuesta**, no cierre); `t_lectura_s` (F3) es la fuente única citada por 26 F1; «sonido pedido» de los `SFX_*` con subtítulo; fila 26 en Dependencias como **Blanda** (ya lo es) |
| `prompt-de-interaccion.md` (24) | El pie sube sobre la banda de 26 (R23, tope `alto_reservado_px` de F4); añadir fila de dependencia con 26 |
| `director-de-escenas.md` (21) | Nota: el fin de línea usa `t_lectura_s` de 23 (L134); 26 comparte el dato sin depender |
| `marco-de-puzles.md` (9) / `llamada-telefonica.md` (22) | Mencionar a 26 como consumidor blando (ya declarado blando) |
| `llamada-telefonica.md` (22) | Su UI no usa la banda inferior (R24); confirmar el contrato de `SUB_BREATH_BROKEN` |
| `menu-de-pausa.md` (25) | Hoy solo ofrece `subtitulos_activos`: añadir pantalla de subtítulos con tamaño, fondo y nombre, y vista previa `UI_SUB_MUESTRA` (R26), sujeto a OQ 7 |
| `estado-y-bus-de-eventos.md` (3) | Confirmar que 26 se suscribe a `pause_opened`/«pausa cerrada» y a los avisos de 23 |
| `systems-index.md` | Fila 26: Designed; dependencias 3 (**Dura**), 6, 18 y 23 (**Blanda**); añadir 3 al orden de diseño |

## Entradas para el registro (†=propuesta)

| Entrada | Tipo | Valor |
|---|---|---|
| `t_sub_max_s` † (por página) | constante | 8,0 |
| `t_sub_sfx_lazo_s` † / `sub_fondo_opacidad_min` † | constantes | 3,0 / 70 % |
| `t_cola_sub_s` † | constante | 0,4 |
| `sub_bloques_max` † / `sub_lineas_max` † / `sub_car_linea` † | constantes | 2 / 2 / 42 |
| `subtitulos_tamano` † / `subtitulos_fondo` † / `subtitulos_hablante` † | ajustes de 6 | `medio` / `translucido` / verdadero |
| `SUB_BREATH_BROKEN`; `SUB_CHAIRS_ROLL` †, `SUB_TYPING_FAR` †, `SUB_PHONE_BUZZ` † (provisionales, pendiente OQ 2) | claves de 18 | sonidos subtitulados |
| `UI_SUB_HABLANTE_VERA` † / `_GUARDIAN` † / `_MEGA` † | claves de 18 | nombres de hablante |
| `UI_SUB_MUESTRA` † | clave de 18 | muestra de vista previa |
| Banda de subtítulos (`alto_banda_px` / `alto_reservado_px` F4) † | fórmula | 184 / 260 px (1080p, `medio`) |

## Historial

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-11-09 | Primer borrador (lote autónomo) | UX Designer |
| 2026-11-09 | Ronda de corrección 1: B-1..B-5 y W-1..W-10 de `reviews/subtitulos-review.md` (R2, R7, R8, R12, R13, R15, R16, R18, R19, R23, R25, F1–F4, dependencias, 12 ACs nuevos, D26-12..16, OQ 7); pendiente de re-review | Claude (corrección) |
