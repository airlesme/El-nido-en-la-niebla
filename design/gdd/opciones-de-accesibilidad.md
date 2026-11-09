# Opciones de accesibilidad (sistema 30)

> **Status**: Revisado (ronda de corrección 1) — pendiente de re-review
> **Author**: Accessibility Specialist (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (nadie pierde por una limitación física, sensorial o cognitiva; ninguna **solución** exige reaccionar en una ventana de tiempo ni el color como único canal; la precisión motriz se compensa con asistencias, regla 14) · Autonomía como progresión (el jugador ajusta la experiencia, no se le pide justificarse) · Información incompleta (las ayudas rebajan la barrera de manejo, nunca revelan la solución) · El espacio expresa la emoción (las ayudas mantienen el tono: sin banners, sin colores de alarma)
> **Category**: Meta · **Priority**: Vertical Slice · **Modo**: `standard`

## Summary

Define el **catálogo de accesibilidad del slice**: qué ajustes existen, quién es dueño de cada uno, dónde se muestran y qué garantías de diseño (sin color, sin tiempo, sin precisión, sin destellos) debe cumplir todo el juego. No añade pantallas ni duplica ajustes: reparte contenido entre las pantallas de 25 y 27, fija el nivel objetivo, mantiene la matriz de cobertura y resuelve `escala_texto_ui` (PA-3 de 19).

## Overview

El slice ya tiene accesibilidad repartida en diez GDDs (subtítulos en 26, volúmenes y `reducir_sobresaltos` en 23/6, asistencias en 13 y 15, manejo en 1, confort en 2, pie de texto en 7, prompt en 24). Ningún documento tiene la visión de conjunto. Este sistema es esa visión: (1) **catálogo y propiedad** de cada ajuste (reglas 1 a 4); (2) **contenido y orden** de la pestaña «Accesibilidad» de 25 (que 27 reutiliza) sin rehacerla (reglas 5 a 7); (3) **escala de texto UI** como único ajuste nuevo de fondo (regla 8 a 10); (4) **garantías transversales** que los demás GDDs deben cumplir, con una auditoría de los seis puzles (reglas 11 a 17); (5) **fotosensibilidad** (reglas 18 a 20); (6) **matriz de cobertura** y huecos conocidos (reglas 21 y 22). Los ajustes se guardan en 6; las pantallas son de 25 y 27; 30 es dueño del catálogo, de las garantías y de la auditoría, no de claves ni de widgets.

## Player Fantasy

Quien tiene una limitación no se entera de que el juego «tiene un modo para ella»: abre Accesibilidad, ve frases normales («Fundidos fijos y sin temblor»), ajusta lo que necesita y vuelve al turno de noche sin que nada cambie de tono. Quien juega sin ajustes no ve nunca estas opciones. Nadie recibe un logro, un mensaje de «modo fácil» ni un cambio de final por usarlas. Las ayudas mueven la barrera (tolerancia, mantener, tamaño, brusquedad), nunca el misterio.

## Detailed Rules

### A. Nivel objetivo y propiedad

1. **Nivel objetivo del slice: «Estándar».** Tres niveles: **Básico** (lo que exige el slice §14/§16: subtítulos, remapeo, tres volúmenes, reducir sobresaltos, reducir movimiento), **Estándar** (Básico + WCAG 2.1 AA **parcial** en las pantallas de UI —excepción declarada: 1.4.4 solo hasta 150 %, OQ 2— + toda información de juego en al menos dos canales + todo puzle resoluble sin color como único canal, sin reaccionar en ventanas de tiempo y con asistencia para la precisión (regla 14) + escala de texto + ayudas de manejo + tope de destellos) y **Completo** (Estándar + filtros de daltonismo, alto contraste, audio mono, lector de pantalla, 200 % de texto). Se **propone** **Estándar** como nivel del slice; Completo queda fuera (Decisiones D30-1, D30-2). Que Estándar sea el compromiso de accesibilidad del slice ante financiadores lo decide el usuario (OQ 8; por defecto, sí). Criterios WCAG usados como referencia (no como certificación): 1.4.1 Uso del color, 1.4.3 Contraste (mínimo), 1.4.4 Cambio de tamaño del texto (hasta el 150 % en el slice), 1.4.11 Contraste no textual, 2.1.1 Teclado, 2.2.1 Tiempo ajustable, 2.3.1 Tres destellos, 2.5.5 Tamaño del objetivo (gestión como guía, no AAA obligatorio).
2. **Catálogo.** Cada ajuste de accesibilidad tiene un **propietario del significado** (el GDD que lo lee y define su efecto), un **propietario de la clave** (siempre 6, salvo `controles` de 1) y una **pantalla** (25/27). 30 no define efectos de ajustes ajenos. Tabla maestra:

   | Ajuste | Clave de | Efecto definido en | Pantalla (25) | Barrera que reduce |
   |---|---|---|---|---|
   | `subtitulos_activos` | 6 | 26 | Sonido y pantalla | Audición |
   | `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante` ‡ | 6 (propuestas por 26) | 26 | Sonido y pantalla (junto a `subtitulos_activos`) | Audición, visión |
   | `vol_voces`, `vol_efectos`, `vol_musica` | 6 | 23 | Sonido y pantalla | Audición, sensorial |
   | `reducir_sobresaltos` | 6 | 23 (audio), 28 (luces; regla 18), 15 y otros lectores | Accesibilidad | Sensorial, ansiedad |
   | `reducir_movimiento` | 6 | Lectores: 9 (regla 14b; vía 13, 15, 11 y otros), 4, 19, 21, 28. Pendientes en 6: 24 y 10 (OQ 16 de 6; 15 R25 «lo resuelve 10 hasta entonces»); P6 no la lee (D16-3) | Accesibilidad | Fotosensibilidad, vestibular |
   | `balanceo_camara` (enum, defecto `reducido`), `campo_vision` (60–90, paso 5, 70) | 6 | 2 | Accesibilidad | Vestibular |
   | `multiplicador_pie`, `pie_persistente` | 6 | 7 (dibuja 24) | Accesibilidad | Cognitiva, lectura |
   | `icono_grande`, `etiqueta_accion_visible` ‡ | 6 | 24 | Accesibilidad | Visión |
   | `escala_texto_ui` † (enum de tres valores, regla 8) | 6 | 30 (F1) y consumidores de la regla 9 | Accesibilidad | Visión |
   | `asistencia_encaje` | 6 | 13 | Accesibilidad | Motricidad |
   | `asistencia_rotacion` | 6 | 15 | Accesibilidad | Motricidad |
   | Alternar en lugar de mantener, `t_hold`, atracción asistida, velocidad de cursor, zonas muertas, sensibilidades, inversión | `controles` (1 regla 18) | 1 | Controles › Manejo | Motricidad |
   | Reasignación | `controles` | 1 | Controles | Motricidad |

   Leyenda: **†** = clave nueva propuesta por 30, aún no existe en 6; **‡** = clave propuesta por otro GDD (24, 26) y aún no existente en 6. Hoy 6 define 12 claves en «restablecer todos»; con las pendientes serían **18**: 12 + `icono_grande` + `etiqueta_accion_visible` + `escala_texto_ui` + `subtitulos_tamano`/`fondo`/`hablante` (la cuenta final la fija 6; ver Cambios requeridos).
3. **Qué no es ajuste.** Los sonidos de feedback con equivalente visual, el modo de enfoque a pantalla completa para leer texto necesario (art bible §7.5), el foco sin color, el pausable en cualquier momento (25 regla 1) y el tope de destellos (regla 18) son **garantías de diseño** siempre activas, no opciones.
4. **Sin perfiles ni preajustes.** Cada ajuste actúa solo y se explica en una línea. «Restablecer todos» (25 regla 18) es la única acción masiva.

### B. Pantalla de accesibilidad (contenido y reparto; 25 la dibuja)

5. **No hay pantalla propia.** La «pantalla de accesibilidad» es la pestaña de nivel 2 de 25, reutilizada en título (27 regla 13). 30 fija el **orden** y la **agrupación** de sus filas, 25 conserva control y navegación (25 reglas 9 a 13, 16, 18).
6. **Orden y grupos** de la pestaña «Accesibilidad» (separadores de texto, sin color):
   1. **Lectura:** `escala_texto_ui`, `icono_grande`, `etiqueta_accion_visible`, `multiplicador_pie`, `pie_persistente`.
   2. **Confort y movimiento:** `reducir_movimiento`, `reducir_sobresaltos`, `balanceo_camara`, `campo_vision`.
   3. **Ayudas de puzle:** `asistencia_encaje`, `asistencia_rotacion`.
   4. **Restablecer todos.**

   Los grupos 1 y 2 van arriba porque se necesitan antes de poder usar el resto. Cada fila: nombre, valor en texto, una línea de ayuda; sin iconos de dificultad.
7. **Remisiones.** Al final de los grupos, una línea no enfocable: «Subtítulos y volumen: en Sonido y pantalla. Manejo y reasignación: en Controles.» Los textos de ayuda de ajustes ajenos viven en la tabla de 18 (claves `UI_ACC_*` †); 30 propone los textos de la sección UI Requirements. Si en una fila el texto de ayuda no cabe con `escala_texto_ui` = 1,5, pasa a una segunda línea; nunca se recorta (25 regla 20).

### C. Escala de texto UI (cierra PA-3 de 19 y OQ 15 de 6)

8. **Ajuste.** `escala_texto_ui` †: **enum de tres valores** `1_00` / `1_25` / `1_50` (multiplicadores 1,00 / 1,25 / 1,50; selector con texto «100 %», «125 %», «150 %»), defecto `1_00`. Al ser enum, 6 no cuantiza (sin valores intermedios como 1,3 o 0,9: un valor desconocido en el fichero → defecto). Se aplica en el fotograma del aviso y sin reiniciar nada; no pausa ni obliga a pausar (se ofrece desde 25, donde ya hay pausa).
9. **Alcance.** Multiplica el tamaño de fuente de: menús de 25 y 27, pies de texto y etiqueta de acción de 24, ordenador/correo/impresora (19) y fichas, selectores y sellos del puzle 4 (la ficha crece, no se recorta: P4-E12), texto del memorando, formulario y impresiones en la vista de enfoque (art bible §7.5), prompts y créditos. **No** multiplica: subtítulos (tienen `subtitulos_tamano`, regla 10), texto diegético fuera de la vista de enfoque (nunca hace falta leerlo; art bible §7.5) ni los iconos (para eso `icono_grande`).
10. **Subtítulos aparte.** `subtitulos_tamano` (3 tamaños, F3 de 26) es independiente de `escala_texto_ui`: quien quiere subtítulos grandes no tiene por qué agrandar el ordenador. No se combinan (evita un 2,25×).
11. **Reflow, no recorte.** Con 1,50 todo contenedor crece o pasa a más líneas o desplaza (scroll de 25/19 ya existente); nunca se corta texto, nunca se superponen controles, nunca se pierde una acción fuera de pantalla. Los objetivos de pulsación escalan con el texto de su fila con un mínimo de 44 px (como `pick_min_px` de 11).

### D. Garantías transversales (auditoría de los puzles)

12. **Sin color como único canal.** Resultado de la auditoría (verificada contra 11–16): P1 (referencias y huecos por texto y posición; sin verde, 11 R35), P2 (fragmento por luminancia, sin rojo/verde moral, 12 punto 20 y D12), P3 (cada pieza lleva silueta propia y contorno de borde que solo encaja en su hueco; **el color es canal complementario, no único**; ver excepción documentada abajo), P4 (selectores con texto «Alta/Media/Baja», «Vera/Guardián/Dirección»; regla visible sin color, P4-R4/R12), P5 (contorno por forma y luminancia, D15-11) y P6 (texto, sin rojo/verde moral, D16-3) **cumplen**. 29 usa forma para sus señales (D29-7). **No se ofrecen filtros de daltonismo** (D30-1). Todo GDD nuevo declara «sin color» en su AC (AC-30-05).
    - **Excepción documentada (P3):** el pilar de 13 dice «la solución se deduce de la forma y el color» y su requisito de diseño es asignar las piezas «por forma y color» (13 regla 3, AC-24). Verificado: la forma (silueta y contorno de borde) basta por sí sola para encajar; el color acompaña. Un jugador con daltonismo resuelve por contorno, pero **13 no lo afirma explícitamente**: pendiente de que 13 declare «el contorno determina el hueco sin el color» (Cambios requeridos) y de AC-30-05 sobre P3.
13. **Sin reaccionar en ventanas de tiempo.** Ninguna **solución** exige actuar dentro de un plazo. Hay esperas **pasivas** (el jugador no actúa durante ellas) que no son temporizadores de solución; se declaran para que nadie las confunda:

    | Puzle | Gesto | Tolerancia / precisión | Dwell o espera (sin acción del jugador) |
    |---|---|---|---|
    | P1 (11) | `seleccionar` (pulsar y soltar; R10) | Objetivo ≥ 44 px (`pick_min_px`) | Bloqueo tras rechazo **1,5 s** (11 AC-8; evento descartado, no encolado) |
    | P2 (12) | `seleccionar` sobre la base de la lámpara (verbo `Girar`) | Sin arrastre | Gesto de la mano 0,4–0,8 s (`lamp_turn_s`, `t_clic`); pulsaciones descartadas durante el gesto |
    | P3 (13) | `agarrar` (siempre; R5) y, con pista de nivel 2, `mantener` | Radio de encaje (0,04 m sin asistencia; 0,10 m con `asistencia_encaje`) | Pieza rechazada vuelve a la bandeja en **0,4 s** |
    | P4 (14) | `seleccionar` (2 clics por combinación, 1 para «Devolver») | Objetivo ≥ 44 px | Ninguna; sin `lock` (P4-R8) |
    | P5 (15) | `rotar` (gesto continuo, R1) | θ* ± 3° (±6° con `asistencia_rotacion`) | **Dwell `hold_s` = 0,8 s†** dentro de la tolerancia (R11) |
    | P6 (16) | `seleccionar` (clic al soltar, R5) | Objetivo ≥ 44 px | Presentación de 1,9 s tras aceptar (no exige reacción) |

    **Excepciones aceptadas, sin ajuste:** (a) el dwell de P5 (0,8 s) es tiempo **y** precisión: hay que mantener θ dentro de la tolerancia 0,8 s; se compensa con `asistencia_rotacion` y con `alternar` (la rotación no exige mantener un botón), pero **el dwell no se puede suprimir ni acortar desde 30**; se eleva como OQ 9; (b) espera entre pistas de 20/40 s (17; ver OQ 1); (c) duración del pie de texto (ajustable con `multiplicador_pie`/`pie_persistente`); (d) el nivel 3 de pista de P3 a los 60 s de inactividad es una ayuda, no una obligación.
14. **Precisión motriz: reducida y compensada, no eliminada.** P1, P2, P4 y P6 usan `seleccionar` sobre objetivos ≥ 44 px (sin arrastre ni tolerancia fina). **P3** exige arrastre (`agarrar`) con tolerancia de encaje: se compensa con `asistencia_encaje` (radio 0,10 m frente a 0,04 m). **P5** exige girar con tolerancia ±3° y mantener 0,8 s: se compensa con `asistencia_rotacion` (±6°). Por tanto la garantía es «ningún puzle exige precisión sin una asistencia disponible», no «sin precisión».
15. **Sin mantener obligatorio.** `leer`, `mantener`, `agarrar` y `rotar` se pueden hacer alternando (1 regla 14). Es **BLOCKING** que el ajuste exista antes de dar el slice por accesible; ver AC-30-09.
16. **Dispositivos.** El slice completo es jugable solo con teclado y ratón o solo con mando (art bible §7.6, 1 reglas 3 y 9). El campo de texto del ordenador (19) con mando queda **cumplido** por el teclado en pantalla de 19 R16 (anclado bajo el campo, operado con el cursor de los sticks y `seleccionar`; cierra la OQ 1 de 1; criterio AC-10a de 19). 30 no define nada más; solo verifica (AC-30-08).
17. **Audio.** Ningún acierto depende solo del sonido (23 regla 40); toda voz tiene subtítulo (26); silenciar un bus no acorta la escena (23 regla 37). La lista de sonidos con función de juego (`SFX_BOX_*`, `SFX_PHONE_BUZZ`, etc.) debe tener un equivalente visual o de texto; 30 pide a 23 la tabla «sonido → equivalente» y a 26 decidir qué sonidos se rotulan (AC-30-11).

### E. Fotosensibilidad y confort

18. **Tope duro siempre activo.** Ningún efecto del juego produce más de **3 destellos por segundo** (SC 2.3.1) y el parpadeo de luces de 28 se limita a **2 ciclos por segundo con pausas mínimas de 0,35 s** (art bible §7.4), **con o sin** `reducir_movimiento`. El tope lo aplica el sistema emisor; 30 lo verifica (AC-30-13).
19. **`reducir_movimiento`.** Su efecto es único para todo el slice: fundidos fijos de 100 ms, cambios estáticos en lugar de temblor, y los **tres destellos de `LUCES_PARPADEO`** (orden de 21, Director de escenas, DT-12 y regla 23 de 21) sustituidos por una única atenuación suave (0,6 s); la cortina de carga es de 4 (Escena de planta, regla 11). La leen: 9 (regla 14b; la aplican 13, 15, 11 y otros), 4, 19, 21 y 28. **Pendientes de 6:** 24 (listado como consumidor) y 10 (aperturas; OQ 16 de 6, OQ 5 de 10: no baja `BOX_Cn_OPEN` del rango; 15 R25 «lo resuelve 10 hasta entonces»). 30 no puede crear una segunda clave de movimiento. Alcance abierto: P6 no la lee (D16-3; OQ 6).
20. **Contrato con 28 (Atmósfera reactiva; verificado en 28 regla 18).** 28 existe y lee **dos** claves: `reducir_sobresaltos` (atenúa lo que sobresalta: caída de luz y parpadeo, una sola atenuación hasta `f_parpadeo_red`, rampas de 0,30 s; regla 9) y `reducir_movimiento` (atenúa lo que se mueve: reflejo retardado con fundido cruzado ≥ 0,5 s, lluvia a `lluvia_vel_red`; regla 17). 30 **no** exige que 28 deje de leer `reducir_sobresaltos` (D30-12). 30 solo verifica de 28: (a) ambas se leen en el fotograma del aviso de cambio; (b) con cualquiera activa, el aviso se atenúa sin eliminarse; (c) el tope de destellos (28 reglas 9 y 11: constantes de código `pausa_min_s` = 0,35 s, 2,0 Hz, 3 destellos/s, limitador no desactivable) vale **con o sin** ellas; (d) con `reducir_movimiento` activa, 28 ejecuta tal cual la atenuación única que envía 21 (28 regla 9, veces = 1). Como 28 está en revisión paralela, estos números se re-verifican en el re-review.

### F. Cobertura

21. **Matriz de cobertura** (qué garantiza el slice):

   | Ámbito | Ayuda en el slice | Estado |
   |---|---|---|
   | **Visión** | `escala_texto_ui`, `icono_grande`, `etiqueta_accion_visible`, `subtitulos_tamano`/`fondo`, foco sin color, modo de enfoque, sin color único | Cubierto (Estándar); sin filtros ni alto contraste (D30-1); contrastes a medir (AC-30-04) |
   | **Audición** | Subtítulos con hablante, 3 volúmenes, equivalentes visuales | Cubierto; mono y señales direccionales no aplican (sin dirección de juego) (D30-3) |
   | **Motricidad** | Reasignación, alternar en vez de mantener, `asistencia_encaje`, `asistencia_rotacion`, objetivos ≥ 44 px, un solo botón, sin tiempo | Cubierto |
   | **Cognitiva** | Pistas por niveles, `multiplicador_pie`, `pie_persistente`, pausa siempre, sin temporizador, bolsillo y papeles releíbles | Cubierto; hueco de la espera de pistas (OQ 1) |
   | **Fotosensibilidad / vestibular** | Tope de destellos, `reducir_movimiento`, `balanceo_camara`, `campo_vision`, `reducir_sobresaltos` | Cubierto si 28 cumple regla 20 |
22. **Huecos conocidos (fuera de Estándar, registrados):** lector de pantalla (AccessKit existe desde Godot 4.5, VERSION.md; los controles se nombran, regla 23); cursor oculto en la llamada (22 OQ 10; **riesgo para AC-30-08**, OQ 5); espera de pistas (OQ 1); dwell de P5 (OQ 9); P6 sin `reducir_movimiento`. (El teclado en pantalla para mando ya no es hueco: 19 R16.)
23. **Preparado para lector de pantalla.** Todo control de 25/27 lleva nombre accesible = su texto visible y el orden de foco es el visual. **API no verificado:** `docs/engine-reference/godot/` confirma solo que los `Control` se integran con AccessKit desde 4.5 (`breaking-changes.md`, `current-best-practices.md` § Accessibility) y menciona `Control.accessibility_live` (4.7, `modules/ui.md`); el nombre exacto de la propiedad de nombre accesible y el comportamiento del orden de foco **no están verificados** en la referencia y deben comprobarse antes de implementar. Sin pruebas con lector en el slice.

## Formulas

### F1 · Tamaño de texto efectivo

`tam_px = tam_base_px × escala_texto_ui × (alto_ventana_px / 1080)` redondeado al entero más próximo.

| Variable | Rango | Notas |
|---|---|---|
| `tam_base_px` | 18–44 (art bible §7.5). **En la pantalla del ordenador (19) el suelo es 24 px lógicos** (19 R18, AC-19; prevalece sobre 18) | A 1080p y escala 1,00. 18 solo aplica a pies y etiquetas |
| `escala_texto_ui` | {1,00; 1,25; 1,50} (enum) | Setting de 6 † |
| `alto_ventana_px` | 720–2160 | Ventana o pantalla completa |

Ejemplo: texto de ordenador base 24 px, escala 1,50, ventana 1440 p: 24 × 1,5 × 1,333 = 48 px. Ejemplo mínimo: 18 px (pie) a 720 p, escala 1,00: 18 × 1 × 0,667 = 12 px; **se aplica el suelo** `tam_min_px` = 18 px lógicos × (alto/1080) ≥ 12 px reales (solo pies y etiquetas; en 19 el suelo de 24 lógicos da 16 px a 720 p, mitigación PA-3 de 19); por debajo de 720 p no se soporta. El prompt de 24 absorbe esta F1 en su F2.

**Interacción con el escalado de ventana (no verificado):** el factor `alto_ventana_px / 1080` de F1 asume que el proyecto **no** estira la UI con el modo de escalado de Godot (`content_scale_mode`/`stretch`). Si el proyecto lo usa (p. ej. `canvas_items` con base 1920×1080), el motor ya aplica ese factor y F1 lo duplicaría: en ese caso F1 se reduce a `tam_base_px × escala_texto_ui`. La configuración de escalado de la UI no está decidida ni cubierta por la referencia de motor (`docs/engine-reference/godot/` no la trata); queda para el ADR/arquitectura de UI antes de implementar.

**Composición con el pie de 7:** `escala_texto_ui` (tamaño) y `multiplicador_pie` (duración) son independientes; F5 de 7 no depende del tamaño del texto. Un pie más grande no recibe más tiempo automáticamente: se compensa con `multiplicador_pie` o `pie_persistente`.

## Edge Cases

- **Fichero de ajustes dañado o ausente:** 6 devuelve defectos (todo falso, escala 1,00); el juego es jugable. 30 no guarda nada propio.
- **`escala_texto_ui` cambia con un bloque en pantalla** (pie, ordenador abierto): se recompone en el siguiente fotograma, el pie conserva su reloj; el ordenador conserva scroll y foco.
- **Texto que no cabe a 1,50 en 720 p:** se aplica reflow y scroll; el AC-30-03 exige capturas a 720 p y 1,50.
- **Idioma:** el slice es solo español; si se añade otro, localización revisa longitudes con escala 1,50.
- **`reducir_movimiento` cambiado a mitad de una cortina:** la cortina en curso termina como empezó; el nuevo valor vale desde la siguiente (15 D15-13 análogo).
- **`asistencia_rotacion` / `asistencia_encaje` cambiadas desde la pausa durante el puzle:** valen desde el siguiente gesto (15 regla 10; 13 lo lee al configurar y al cambiar).
- **Asistencia activada y puzle ya resuelto:** sin efecto; nada se rehace.
- **Mando desconectado con Accesibilidad abierta:** no modal, línea de cabecera (25 regla 17); los ajustes siguen editables con teclado y ratón.
- **Restablecer todos:** restablece todas las claves de 6 listadas en 25 regla 18; no toca `modo_ventana` ni `controles`. Hoy son 12 (6 regla 8); con las claves pendientes de la regla 2 serán 18 (24 ya pide pasar a 14). El diálogo cita lo que cubre; la cuenta final la fija 6.
- **Alternar en lugar de mantener activo y gesto de `rotar` en curso:** una pulsación inicia, la siguiente termina; `atrás` cancela (1 regla 14).
- **Todos los volúmenes a 0 y subtítulos apagados:** permitido (decisión del jugador); no se advierte ni se bloquea. Escena con voz crítica sin subtítulos: ver OQ 4 (aviso opcional; D30-11).
- **Cambio de ajuste desde título antes de la primera partida:** escritura normal de 6; sin sesión no hay acumulador que cancelar.

## Dependencies

| Sistema | Tipo | Qué usa 30 | Qué recibe |
|---|---|---|---|
| 1 Entrada y controles | Dura | API de reasignación y ajustes de manejo; alternar en vez de mantener | Listas de ajustes de manejo; sin duplicar pantallas |
| 6 Ajustes persistentes | Dura | Claves, rangos, restablecer; `escala_texto_ui` †, subtítulos ‡ | Nuevas claves de la regla 2 |
| 13 Puzle 3 | Blanda (lectura; 13 no necesita nombrar a 30) | `asistencia_encaje` (0,10 m) | Declarar que el contorno determina el hueco sin color (regla 12) |
| 15 Puzle 5 | Blanda (ídem) | `asistencia_rotacion` (±6°), `reducir_movimiento`, dwell `hold_s` (OQ 9) | Sin cambios |
| 23 Director de audio | **Dura para AC-30-11** (blanda para el resto) | Volúmenes y `reducir_sobresaltos` | Tabla «sonido → equivalente»; 23 no menciona aún a 30 (añadir fila de reciprocidad) |
| 26 Subtítulos | Dura | `subtitulos_*` ‡ | Ubicación en Sonido y pantalla |
| 25 Menú de pausa / 27 Título | **Dura** (30 no tiene pantalla propia: sin 25 no se muestra ningún ajuste) | Pantalla; orden de filas | Orden de la regla 6 |
| 28 Atmósfera reactiva | Blanda (verificación) | `reducir_sobresaltos` y `reducir_movimiento` (28 regla 18); tope de destellos (reglas 9 y 11) | Cumplir regla 20 |
| 19 Ordenador | Blanda | Teclado en pantalla (R16); consume `escala_texto_ui` | Cumplir regla 9 |
| 24 Prompt, 7 Interacción, 4 Escena, 10 Caja, 21 | Blanda (consumidores) | `escala_texto_ui`, `reducir_movimiento`, `icono_grande` | Cumplir reglas 9, 18 y 19 |
| 17 Sistema de pistas | Blanda | Espera de pistas (OQ 1) | — |

## Tuning Knobs

| Perilla | Defecto | Rango seguro | Afecta a |
|---|---|---|---|
| `escala_texto_ui` pasos | 1,00 / 1,25 / 1,50 (enum) | Añadir 2,00 si se acepta OQ 2 | Legibilidad frente a reflow |
| `tam_min_px` (lógico) | 18 (pies y etiquetas; 24 en 19) | 18–24 | Suelo de F1 |
| `objetivo_min_px` | 44 (= `pick_min_px` de 11; alias, ver Registro) | 44–64 | Objetivos de pulsación |
| `tope_destellos_s` | 3 (siempre) | 2–3; no subir | Fotosensibilidad |

**Solo lectura (valores y rangos viven en su dueño; 30 no los posee):** `parpadeo_ciclos_s`/`pausa_min_s` (28: 2,0 Hz, 0,35 s, constantes de código), `fundido_reducido_ms` (15 `fade_reduced_ms`: 50–200; 6 fija 100 ms), `asistencia_encaje_m` (13), `asistencia_rotacion_deg` (15), `multiplicador_pie` (6/7).

Los valores viven en los datos de cada propietario, no en 30.

## Acceptance Criteria

- **AC-30-01 (R2, L) — BLOQUEADO hasta aplicar los Cambios requeridos en 6 y 25:** **GIVEN** el catálogo de 6 con las claves †/‡ añadidas (18 en «restablecer todos»), **THEN** cada ajuste de la regla 2 existe en 6 con su tipo y defecto; ninguna clave de accesibilidad aparece en dos pantallas distintas de 25. Hoy falla por diseño (faltan `icono_grande`, `etiqueta_accion_visible`, `escala_texto_ui`, `subtitulos_tamano/fondo/hablante`).
- **AC-30-02 (R5-R7, UI, BLOCKING):** **THEN** la pestaña Accesibilidad de 25 muestra los 4 grupos en el orden de la regla 6, con valor en texto y ayuda de una línea; una captura por grupo, en 25 y en título (27), retenida en `production/qa/evidence/`. Sustituye al orden de 25 AC-25-23 y AC-25-12 (30 manda el orden).
- **AC-30-03 (R8-R11, UI):** **GIVEN** `escala_texto_ui` = 1,50 y ventana 720 p, **THEN** ningún texto de 25, 27, 24, 19 ni del puzle 4 está recortado ni solapado; capturas retenidas.
- **AC-30-04 (R1, UI):** **THEN** texto sobre fondo ≥ 4,5:1 y bordes de control/foco ≥ 3:1, medidos en capturas de cada pantalla de UI (pares texto/fondo y borde/fondo de la paleta del art bible, listados en la captura); fallo = BLOCKING.
- **AC-30-05 (R12, H, BLOCKING):** **GIVEN** cada puzle (incluido P3, solo con contorno) jugado con una simulación de protanopia/deuteranopia/tritanopia (simulador de CVD del editor o Coblis sobre capturas), **THEN** se resuelve sin ambigüedad.
- **AC-30-06 (R13, L):** **THEN** los datos de los seis puzles no contienen temporizador de solución; los únicos tiempos son las esperas pasivas de la tabla de la regla 13 (bloqueo de rechazo de P1 1,5 s y de P3 0,4 s, dwell de P5 0,8 s, gestos de P2, presentación de P6) y la espera de pistas; ninguna se acorta por debajo de lo declarado ni exige acción del jugador.
- **AC-30-07 (R14, I):** **GIVEN** `asistencia_encaje` activa, **THEN** una pieza soltada a 0,09 m encaja y a 0,11 m no; **GIVEN** `asistencia_rotacion`, 46,1° → no resuelve y 43,5° sí (15 AC-P5-03).
- **AC-30-08 (R16, H):** **GIVEN** el slice entero con solo teclado y ratón, y otro con solo mando, **THEN** se llega a `ESC8_CIERRE` en ambos; el campo del ordenador es completable con mando mediante el teclado en pantalla de 19 R16 (cumple AC-10a de 19). Riesgo abierto: cursor oculto en la llamada (OQ 5); si no se resuelve, se limita este AC a las escenas sin llamada con mando.
- **AC-30-09 (R15, H):** **GIVEN** alternar-en-vez-de-mantener, **THEN** `leer`, `mantener`, `agarrar` y `rotar` se completan sin mantener ningún botón, en los seis puzles y en el pie de objetos.
- **AC-30-10 (R17, I):** **GIVEN** `vol_*` = 0 y subtítulos activos, **THEN** la información de juego es la misma y no hay silencios sin texto.
- **AC-30-11 (R17, H):** **THEN** la tabla «sonido → equivalente» de 23 no deja ningún sonido de función de juego sin equivalente visual o texto.
- **AC-30-12 (R19, I):** **GIVEN** `reducir_movimiento` activa, **THEN** los fundidos duran 100 ms y `LUCES_PARPADEO` se sustituye por una única atenuación (21 DT-12, regla 23); no hay tres destellos.
- **AC-30-13 (R18, I):** **GIVEN** cualquier secuencia de 28, 29, 24 y 21, capturada en vídeo a 60 fps, **THEN** nunca hay más de 3 destellos en 1 s, con la opción activa y apagada. Criterio de «destello» (WCAG 2.3.1): par de cambios de luminancia relativa ≥ 10 % sobre un área > 25 % del campo de visión (o la que fije el criterio vigente de la herramienta); medida con una herramienta de análisis de destellos (p. ej. PEAT, **no verificada su disponibilidad en el entorno**) sobre el vídeo; luces ≤ 2 ciclos/s con pausas ≥ 0,35 s (constantes de 28).
- **AC-30-14 (R20, I):** **THEN** 28 lee `reducir_sobresaltos` y `reducir_movimiento` en el fotograma del aviso de cambio y, con cualquiera activa, atenúa el aviso sin parpadeo adicional (28 regla 18).
- **AC-30-15 (R3, H):** **THEN** ningún ajuste de accesibilidad muestra etiquetas de dificultad, logros ni cambia la historia.
- **AC-30-16 (R23, I) — pendiente de verificación del API de Godot 4.7 (regla 23):** **THEN** cada control de 25/27 expone nombre accesible igual a su texto y orden de foco visual.

Tipos: L = lógica (test automático), UI = captura retenida, H = humano/playtest, I = integración. Salvo indicación, los AC de tipo UI son BLOCKING; L e I siguen los valores de `testing.strict` de `project.yaml`; H es ADVISORY.

Capturas UI retenidas en `production/qa/evidence/` (por AC-30-02, -03, -04).

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D30-1 | Nivel objetivo **Estándar**, sin filtros de daltonismo ni alto contraste | Básico (solo slice §14); Completo | Básico deja sin cubrir texto, motricidad y fotosensibilidad que el diseño ya soporta; Completo (filtros, alto contraste) no se justifica porque la auditoría de la regla 12 muestra que ningún puzle depende del color y la paleta es sobria (art bible); coste de shaders sin beneficio |
| D30-2 | Lector de pantalla y 200 % de texto fuera del slice; controles con nombre y orden de foco | Entregarlos | Es acabado de producto, no vertical slice; se deja preparado (regla 23) |
| D30-3 | Sin audio mono ni señales direccionales | Añadirlos | Ningún sonido es direccional ni necesario para jugar (23 regla 40); mono no mejora nada aquí |
| D30-4 | `escala_texto_ui` entra: 3 pasos 1,00/1,25/1,50, defecto 1,00, **enum** de tres valores (ronda 1; antes `float`) | `float` con cuantización; dejar la pregunta abierta; 2 pasos; slider continuo | PA-3 de 19 pide un mínimo de 24 px y el art bible §7.6 ya la prevé; 3 pasos son testables y evitan reflow imprevisible; el alcance de MVP de accesibilidad es decisión previa del usuario (6 OQ 15 la cuenta en la pausa) |
| D30-5 | Escala de texto y tamaño de subtítulos son independientes | Un solo multiplicador | Evita 2,25× y respeta la preferencia de cada necesidad |
| D30-6 | 30 no tiene pantalla propia: contenido en la pestaña de 25, reutilizada por 27 | Pantalla propia | 25 y 27 ya la definen (25 regla 16 y 27 regla 13); duplicar rompe «las mismas claves» (25 Deps) |
| D30-7 | `subtitulos_tamano/fondo/hablante` en «Sonido y pantalla» junto a `subtitulos_activos` | En «Accesibilidad» | El jugador busca lo de subtítulos con `subtitulos_activos` (D25-14 análogo); Accesibilidad queda sin duplicar |
| D30-8 | La espera entre pistas **no** tiene opción en el slice | Opción «sin espera» | Cambia el diseño de pistas (pilar *Autonomía*, 17 OQ 3): va a OQ 1 |
| D30-9 | Tope de destellos como garantía fija, no opción | Opción activable | La fotosensibilidad no debe depender de que el jugador sepa que es sensible |
| D30-10 | Un solo `reducir_movimiento` para todo el slice | Una clave por sistema | Evita 5 interruptores; es la clave leída por 9 (vía 13, 15, 11…), 4, 19, 21 y 28 (24 y 10 pendientes en 6) |
| D30-11 | (Ronda 1) Volúmenes a 0 y subtítulos apagados: sin aviso ni bloqueo (OQ 4) | Aviso suave al apagar todo | Pilares *Autonomía* y *Tensión sin castigo*: es decisión del jugador; sin advertencias |
| D30-12 | (Ronda 1, B-2) 28 lee **dos** claves, `reducir_sobresaltos` (lo que sobresalta) y `reducir_movimiento` (lo que se mueve); 30 no pide que deje de leer ninguna | Exigir que 28 no lea `reducir_sobresaltos` (borrador 0.1) | 28 regla 18 y 6 ya lo fijan; la separación evita mezclar destello con movimiento y no hay motivo para cambiar a 28 |
| D30-13 | (Ronda 1, B-1) El teclado en pantalla para mando no es un hueco de 30: lo cubre 19 R16 | Pedir a 19 un teclado propio | 19 R16, AC-10a y 1 OQ 1 ya lo resuelven |
| D30-14 | (Ronda 1, B-4) La garantía de puzles se redacta como «ninguna solución exige reaccionar en una ventana», con tabla por puzle y excepciones declaradas (P3 color complementario; P5 dwell 0,8 s; bloqueos de rechazo) | Mantener «sin tiempo, precisión ni color» | La afirmación absoluta era falsa; se documenta lo que dicen 11–16 |
| D30-15 | (Ronda 1, W-14/W-15) 30 no posee knobs ajenos; `objetivo_min_px` es alias de `pick_min_px` (11) | Constante propia duplicada | Evita dos constantes con el mismo valor y dueño distinto |
| D30-16 | (Ronda 1, W-9) `escala_texto_ui` y `multiplicador_pie` son independientes; F5 de 7 no depende del tamaño | Fórmula de composición | Sin evidencia de que se necesite; se revisa en playtest de lectura |

## Open Questions

| # | Pregunta | Dueño | Valor por defecto |
|---|---|---|---|
| 1 | ¿Opción `pistas_sin_espera` para la espera de 20/40 s? (cognitiva; 17 OQ 3) | Usuario, 17 | No; espera corta. Si se quiere: bool en 6, fila en grupo 3 |
| 2 | **Decide el usuario.** ¿Subir `escala_texto_ui` a 200 % (SC 1.4.4)? Sin ello, Estándar declara 1.4.4 como excepción | Usuario, UX | No en el slice; se añade un paso si el reflow lo permite |
| 3 | ~~Teclado en pantalla para mando~~ | — | **Cerrada** (ronda 1): 19 R16 / AC-10a (D30-13). Numeración conservada |
| 4 | ¿Aviso suave si volúmenes a 0 y subtítulos apagados? | Usuario, UX | No (sin advertencias; D30-11) |
| 5 | ¿Cursor oculto en la llamada: pista visual/sonora para mando? (22 OQ 10) | 22, usuario | No decidido aquí; se valora en playtest con mando. **Riesgo de AC-30-08**: resolver antes de cerrar la capa o limitar el AC |
| 6 | ¿`reducir_movimiento` baja la tapa de 1,9 s del P6? (D16-3) | 10, 16 | No |
| 7 | ¿Modo de alto contraste/colorblind en el vertical completo? | Usuario, art director | Tras el slice, si el contraste (AC-30-04) o el playtest lo piden |
| 8 | **Decide el usuario.** ¿Se acepta el nivel «Estándar» (WCAG 2.1 AA parcial, sin 200 %, sin filtros, sin lector) como compromiso de accesibilidad del slice ante financiadores? Cambia la promesa de alcance frente a slice §14/§16 | Usuario | Sí, Estándar (D30-1) |
| 9 | **Decide el usuario.** El dwell de 0,8 s de P5 (`hold_s`) es tiempo y precisión sin ajuste: ¿se ofrece ayuda (acortarlo/quitarlo con `asistencia_rotacion`) o se acepta la excepción? Toca el diseño de P5 | Usuario, 15 | Aceptar la excepción documentada (regla 13); `hold_s` ya es † (0,4–1,5 s) |
## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| **6 Ajustes** | Añadir `escala_texto_ui` (enum `1_00`/`1_25`/`1_50`; defecto `1_00`), `icono_grande`, `etiqueta_accion_visible` y `subtitulos_tamano/fondo/hablante`; cerrar OQ 15; «restablecer todos» pasa de 12 a **18** claves (12 + 6); actualizar regla 8, AC-07/AC-01 y la cuenta; corregir en su OQ 16 y tabla de consumidores de `reducir_movimiento`; y su línea 50: los ajustes de subtítulos los ofrece 25 (Sonido y pantalla) |
| **25 Menú de pausa** | Fila `escala_texto_ui` en Accesibilidad (cierra su OQ 5); añadir `icono_grande` y `etiqueta_accion_visible`; reordenar en 4 grupos (regla 6); `subtitulos_tamano/fondo/hablante` en «Sonido y pantalla»; reescribir AC-25-23, AC-25-12, D25-7, la captura «Accesibilidad» del resumen de capturas y la cuenta de claves (18) |
| **27 Pantalla de título** | Confirmar que reutiliza la pestaña con las nuevas filas |
| **26 Subtítulos** | Confirmar ubicación de `subtitulos_*` en Sonido y pantalla (corregir su línea ≈125 «30 Accesibilidad ofrecen la pantalla» y sus Dependencias); decidir qué sonidos se rotulan (regla 17) |
| **23 Director de audio** | Tabla «sonido → equivalente visual» (AC-30-11); fila de dependencia hacia 30 (reciprocidad) |
| **24 Prompt / 7 Interacción** | F2 absorbe `escala_texto_ui`; `multiplicador_pie` es independiente de ella (D30-16); 24 pasa a la lista de lectores de `reducir_movimiento` en 6 |
| **19 Ordenador** | Solo consumir `escala_texto_ui` y cerrar PA-3 (el teclado en pantalla ya está en R16) |
| **28 Atmósfera reactiva** | Sin cambios requeridos por 30: ya lee ambas claves y fija el tope (reglas 9, 11, 17, 18). Re-verificar la regla 20 tras la revisión paralela de 28 |
| **29 Shaders y efectos / 21 Director de escenas** | Verificar tope de destellos (AC-30-13); DT-12 y regla 23 de 21 confirmados |
| **17 Sistema de pistas** | Decidir OQ 1 |
| **10 Caja / 16 Puzle 6** | Cerrar alcance de `reducir_movimiento` (OQ 6; OQ 16 de 6) |
| **13 Puzle 3** | Declarar que el contorno de borde determina el hueco sin color y ajustar el Implements Pillar («forma y color») en consecuencia |
| **11, 12, 14, 15, 16** | Declarar «sin color» y las esperas pasivas de la regla 13 en sus AC (AC-30-05/06) |

## Entradas para el registro

| Entrada | Tipo | Valor | Fuente |
|---|---|---|---|
| `escala_texto_ui` † | Ajuste (enum) | 1,00 / 1,25 / 1,50; defecto 1,00 | 30 regla 8 (clave en 6) |
| `accessibility_level_slice` † | Constante de diseño | «Estándar» (pendiente de OQ 8) | 30 regla 1 |
| `tope_destellos_s` † | Constante | 3 | 30 regla 18 |
| `objetivo_min_px` | **Alias de `pick_min_px`** (ya en `entities.yaml`, dueño 9/11); no se crea constante nueva | 44 | 30 regla 11; verificar valor en el registro antes de citar |
| `tam_min_px` † | Constante | 18 (lógico) | 30 F1 |
| `reducir_movimiento`, `icono_grande`, `etiqueta_accion_visible`, `subtitulos_*` | Ajustes (existentes o ‡) | Ver regla 2 | Dueño: 6 |

## Historial

| Fecha | Versión | Cambio |
|---|---|---|
| 2026-11-09 | 0.1 | Borrador inicial (lote autónomo). Catálogo, reparto con 25/27, `escala_texto_ui`, auditoría de puzles, fotosensibilidad y matriz de cobertura. No se ha leído el GDD de 28. |
| 2026-11-09 | 0.2 | Ronda de corrección 1 (informe `reviews/opciones-de-accesibilidad-review.md`). B-1: teclado en pantalla cumplido por 19 R16 (OQ 3 cerrada). B-2: contrato con 28 reescrito según su regla 18 (lee ambas claves; D30-12). B-3: «3» → 21/4; lectores reales de `reducir_movimiento`. B-4: auditoría de puzles con tabla por puzle (P3 color complementario, dwell de P5, bloqueos de rechazo; D30-14, OQ 9). B-5: leyenda †/‡, cuenta de 18 claves, AC-30-01 bloqueado. Avisos: nivel Estándar a OQ 8 y 1.4.4 como excepción; `escala_texto_ui` enum; suelo de 24 px en 19; nota de escalado de ventana y API de accesibilidad «no verificado»; dependencias; knobs ajenos; AC con herramienta/gate. Status: pendiente de re-review. |
