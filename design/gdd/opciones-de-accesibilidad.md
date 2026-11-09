# Opciones de accesibilidad (sistema 30)

> **Status**: Borrador (lote autónomo)
> **Author**: Accessibility Specialist (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (nadie pierde por una limitación física, sensorial o cognitiva; ninguna solución depende de tiempo, precisión o color) · Autonomía como progresión (el jugador ajusta la experiencia, no se le pide justificarse) · Información incompleta (las ayudas rebajan la barrera de manejo, nunca revelan la solución) · El espacio expresa la emoción (las ayudas mantienen el tono: sin banners, sin colores de alarma)
> **Category**: Meta · **Priority**: Vertical Slice · **Modo**: `standard`

## Summary

Define el **catálogo de accesibilidad del slice**: qué ajustes existen, quién es dueño de cada uno, dónde se muestran y qué garantías de diseño (sin color, sin tiempo, sin precisión, sin destellos) debe cumplir todo el juego. No añade pantallas ni duplica ajustes: reparte contenido entre las pantallas de 25 y 27, fija el nivel objetivo, mantiene la matriz de cobertura y resuelve `escala_texto_ui` (PA-3 de 19).

## Overview

El slice ya tiene accesibilidad repartida en diez GDDs (subtítulos en 26, volúmenes y `reducir_sobresaltos` en 23/6, asistencias en 13 y 15, manejo en 1, confort en 2, pie de texto en 7, prompt en 24). Ningún documento tiene la visión de conjunto. Este sistema es esa visión: (1) **catálogo y propiedad** de cada ajuste (reglas 1 a 4); (2) **contenido y orden** de la pestaña «Accesibilidad» de 25 (que 27 reutiliza) sin rehacerla (reglas 5 a 7); (3) **escala de texto UI** como único ajuste nuevo de fondo (regla 8 a 10); (4) **garantías transversales** que los demás GDDs deben cumplir, con una auditoría de los seis puzles (reglas 11 a 17); (5) **fotosensibilidad** (reglas 18 a 20); (6) **matriz de cobertura** y huecos conocidos (reglas 21 y 22). Los ajustes se guardan en 6; las pantallas son de 25 y 27; 30 es dueño del catálogo, de las garantías y de la auditoría, no de claves ni de widgets.

## Player Fantasy

Quien tiene una limitación no se entera de que el juego «tiene un modo para ella»: abre Accesibilidad, ve frases normales («Fundidos fijos y sin temblor»), ajusta lo que necesita y vuelve al turno de noche sin que nada cambie de tono. Quien juega sin ajustes no ve nunca estas opciones. Nadie recibe un logro, un mensaje de «modo fácil» ni un cambio de final por usarlas. Las ayudas mueven la barrera (tolerancia, mantener, tamaño, brusquedad), nunca el misterio.

## Detailed Rules

### A. Nivel objetivo y propiedad

1. **Nivel objetivo del slice: «Estándar».** Tres niveles: **Básico** (lo que exige el slice §14/§16: subtítulos, remapeo, tres volúmenes, reducir sobresaltos, reducir movimiento), **Estándar** (Básico + WCAG 2.1 AA en las pantallas de UI + toda información de juego en al menos dos canales + todo puzle resoluble sin color, tiempo ni precisión + escala de texto + ayudas de manejo + tope de destellos) y **Completo** (Estándar + filtros de daltonismo, alto contraste, audio mono, lector de pantalla, 200 % de texto). El slice entrega **Estándar**; Completo queda fuera del slice (Decisiones D30-1, D30-2). Criterios WCAG usados como referencia (no como certificación): 1.4.1 Uso del color, 1.4.3 Contraste (mínimo), 1.4.4 Cambio de tamaño del texto (hasta el 150 % en el slice), 1.4.11 Contraste no textual, 2.1.1 Teclado, 2.2.1 Tiempo ajustable, 2.3.1 Tres destellos, 2.5.5 Tamaño del objetivo (gestión como guía, no AAA obligatorio).
2. **Catálogo.** Cada ajuste de accesibilidad tiene un **propietario del significado** (el GDD que lo lee y define su efecto), un **propietario de la clave** (siempre 6, salvo `controles` de 1) y una **pantalla** (25/27). 30 no define efectos de ajustes ajenos. Tabla maestra:

   | Ajuste | Clave de | Efecto definido en | Pantalla (25) | Barrera que reduce |
   |---|---|---|---|---|
   | `subtitulos_activos` | 6 | 26 | Sonido y pantalla | Audición |
   | `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante` ‡ | 6 (propuestas por 26) | 26 | Sonido y pantalla (junto a `subtitulos_activos`) | Audición, visión |
   | `vol_voces`, `vol_efectos`, `vol_musica` | 6 | 23 | Sonido y pantalla | Audición, sensorial |
   | `reducir_sobresaltos` | 6 | 23 (audio) | Accesibilidad | Sensorial, ansiedad |
   | `reducir_movimiento` | 6 | 4, 10, 15, 19, 21, 24, 28 | Accesibilidad | Fotosensibilidad, vestibular |
   | `balanceo_camara`, `campo_vision` | 6 | 2 | Accesibilidad | Vestibular |
   | `multiplicador_pie`, `pie_persistente` | 6 | 7 (dibuja 24) | Accesibilidad | Cognitiva, lectura |
   | `icono_grande`, `etiqueta_accion_visible` ‡ | 6 | 24 | Accesibilidad | Visión |
   | `escala_texto_ui` † | 6 | 30 (F1) y consumidores de la regla 9 | Accesibilidad | Visión |
   | `asistencia_encaje` | 6 | 13 | Accesibilidad | Motricidad |
   | `asistencia_rotacion` | 6 | 15 | Accesibilidad | Motricidad |
   | Alternar en lugar de mantener, `t_hold`, atracción asistida, velocidad de cursor, zonas muertas, sensibilidades, inversión | `controles` (1 regla 18) | 1 | Controles › Manejo | Motricidad |
   | Reasignación | `controles` | 1 | Controles | Motricidad |
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

8. **Ajuste.** `escala_texto_ui` ‡: `float`, valores **1,00 / 1,25 / 1,50** (selector de tres valores, texto «100 %», «125 %», «150 %»), defecto **1,00†**. Se aplica en el fotograma del aviso y sin reiniciar nada; no pausa ni obliga a pausar (se ofrece desde 25, donde ya hay pausa).
9. **Alcance.** Multiplica el tamaño de fuente de: menús de 25 y 27, pies de texto y etiqueta de acción de 24, ordenador/correo/impresora (19) y fichas, selectores y sellos del puzle 4 (la ficha crece, no se recorta: P4-E12), texto del memorando, formulario y impresiones en la vista de enfoque (art bible §7.5), prompts y créditos. **No** multiplica: subtítulos (tienen `subtitulos_tamano`, regla 10), texto diegético fuera de la vista de enfoque (nunca hace falta leerlo; art bible §7.5) ni los iconos (para eso `icono_grande`).
10. **Subtítulos aparte.** `subtitulos_tamano` (3 tamaños, F3 de 26) es independiente de `escala_texto_ui`: quien quiere subtítulos grandes no tiene por qué agrandar el ordenador. No se combinan (evita un 2,25×).
11. **Reflow, no recorte.** Con 1,50 todo contenedor crece o pasa a más líneas o desplaza (scroll de 25/19 ya existente); nunca se corta texto, nunca se superponen controles, nunca se pierde una acción fuera de pantalla. Los objetivos de pulsación escalan con el texto de su fila con un mínimo de 44 px (como `pick_min_px` de 11).

### D. Garantías transversales (auditoría de los puzles)

12. **Sin color como único canal.** Resultado de la auditoría: P1 (sellos y referencias por forma y texto), P2 (fragmento por luminancia, D12), P3 (silueta y contorno), P4 (selectores con texto «Alta/Media/Baja», «Vera/Guardián/Dirección»), P5 (contorno por forma y luminancia, D15-11) y P6 (texto) **cumplen**. 29 usa forma para sus señales (D29-7). **No se ofrecen filtros de daltonismo** (D30-1). Todo GDD nuevo declara «sin color» en su AC (AC-30-05).
13. **Sin tiempo para resolver.** P1, P4, P6 explícitamente sin temporizador; P2 sin tiempo; P3 sin tiempo (el nivel 3 de pista a los 60 s de inactividad es una ayuda, no una obligación); P5 sin tiempo (tolerancia por gesto); P6: la tapa de 1,9 s no exige reacción. Excepciones aceptadas, sin ajuste: espera entre pistas de 20/40 s (17; ver OQ 1) y la duración del pie de texto (ajustable con `multiplicador_pie`/`pie_persistente`).
14. **Sin precisión motriz obligatoria.** P1, P2 y P4 usan pulsar y soltar sobre un objetivo ≥ 44 px. P3 (arrastrar con tolerancia) se compensa con `asistencia_encaje` (radio 0,10 m). P5 (girar con tolerancia ±3°) se compensa con `asistencia_rotacion` (±6°). P6 es un clic de selección.
15. **Sin mantener obligatorio.** `leer`, `mantener`, `agarrar` y `rotar` se pueden hacer alternando (1 regla 14). Es **BLOCKING** que el ajuste exista antes de dar el slice por accesible; ver AC-30-09.
16. **Dispositivos.** El slice completo es jugable solo con teclado y ratón o solo con mando (art bible §7.6, 1 reglas 3 y 9). Hueco: el ordenador (19) pide escribir «transición» en un campo de texto, y el mando no puede escribir (1 regla 20): 19 debe definir un teclado en pantalla con foco o una alternativa (Cambios requeridos).
17. **Audio.** Ningún acierto depende solo del sonido (23 regla 40); toda voz tiene subtítulo (26); silenciar un bus no acorta la escena (23 regla 37). La lista de sonidos con función de juego (`SFX_BOX_*`, `SFX_PHONE_BUZZ`, etc.) debe tener un equivalente visual o de texto; 30 pide a 23 la tabla «sonido → equivalente» y a 26 decidir qué sonidos se rotulan (AC-30-11).

### E. Fotosensibilidad y confort

18. **Tope duro siempre activo.** Ningún efecto del juego produce más de **3 destellos por segundo** (SC 2.3.1) y el parpadeo de luces de 28 se limita a **2 ciclos por segundo con pausas mínimas de 0,35 s** (art bible §7.4), **con o sin** `reducir_movimiento`. El tope lo aplica el sistema emisor; 30 lo verifica (AC-30-13).
19. **`reducir_movimiento`.** Su efecto es único para todo el slice: fundidos fijos de 100 ms, cambios estáticos en lugar de temblor, y los **tres destellos de la cortina** de 3 (director de escenas, DT-12) sustituidos por una atenuación suave. La leen 4, 10 (aperturas, OQ 5: no baja `BOX_Cn_OPEN` del rango), 15 (AC-P5-13), 19, 21, 24 y 28. 30 no puede crear una segunda clave de movimiento. Alcance abierto: P6 no la lee (D16-3).
20. **Contrato con 28 (Atmósfera reactiva).** 28 debe: (a) leer `reducir_movimiento` en el fotograma del aviso; (b) con ella activa, el apagón y el reflejo retardado ocurren sin parpadeo y con transición ≥ 100 ms; la lluvia no cambia de frecuencia; (c) respetar el tope de la regla 18 siempre; (d) no depender de `reducir_sobresaltos`. Se anota en Cambios requeridos sin haber leído 28.

### F. Cobertura

21. **Matriz de cobertura** (qué garantiza el slice):

   | Ámbito | Ayuda en el slice | Estado |
   |---|---|---|
   | **Visión** | `escala_texto_ui`, `icono_grande`, `etiqueta_accion_visible`, `subtitulos_tamano`/`fondo`, foco sin color, modo de enfoque, sin color único | Cubierto (Estándar); sin filtros ni alto contraste (D30-1); contrastes a medir (AC-30-04) |
   | **Audición** | Subtítulos con hablante, 3 volúmenes, equivalentes visuales | Cubierto; mono y señales direccionales no aplican (sin dirección de juego) (D30-3) |
   | **Motricidad** | Reasignación, alternar en vez de mantener, `asistencia_encaje`, `asistencia_rotacion`, objetivos ≥ 44 px, un solo botón, sin tiempo | Cubierto |
   | **Cognitiva** | Pistas por niveles, `multiplicador_pie`, `pie_persistente`, pausa siempre, sin temporizador, bolsillo y papeles releíbles | Cubierto; hueco de la espera de pistas (OQ 1) |
   | **Fotosensibilidad / vestibular** | Tope de destellos, `reducir_movimiento`, `balanceo_camara`, `campo_vision`, `reducir_sobresaltos` | Cubierto si 28 cumple regla 20 |
22. **Huecos conocidos (fuera de Estándar, registrados):** lector de pantalla (AccessKit existe desde Godot 4.5; los controles se nombran, regla 23); cursor oculto en la llamada (22 OQ 10); teclado en pantalla para mando (regla 16); espera de pistas (OQ 1); P6 sin `reducir_movimiento`.
23. **Preparado para lector de pantalla.** Todo control de 25/27 lleva nombre accesible = su texto visible y el orden de foco es el visual (`Control.accessibility_name` / orden de foco; verificar en `docs/engine-reference/godot/` antes de usar el API). Sin pruebas con lector en el slice.

## Formulas

### F1 · Tamaño de texto efectivo

`tam_px = tam_base_px × escala_texto_ui × (alto_ventana_px / 1080)` redondeado al entero más próximo.

| Variable | Rango | Notas |
|---|---|---|
| `tam_base_px` | 18–44 (art bible §7.5; mínimo de 19: 24 px lógicos) | A 1080p y escala 1,00 |
| `escala_texto_ui` | {1,00; 1,25; 1,50} | Setting de 6 |
| `alto_ventana_px` | 720–2160 | Ventana o pantalla completa |

Ejemplo: texto de ordenador base 24 px, escala 1,50, ventana 1440 p: 24 × 1,5 × 1,333 = 48 px. Ejemplo mínimo: 18 px (pie) a 720 p, escala 1,00: 18 × 1 × 0,667 = 12 px; **se aplica el suelo** `tam_min_px` = 18 px lógicos × (alto/1080) ≥ 12 px reales; por debajo de 720 p no se soporta. El prompt de 24 absorbe esta F1 en su F2.

## Edge Cases

- **Fichero de ajustes dañado o ausente:** 6 devuelve defectos (todo falso, escala 1,00); el juego es jugable. 30 no guarda nada propio.
- **`escala_texto_ui` cambia con un bloque en pantalla** (pie, ordenador abierto): se recompone en el siguiente fotograma, el pie conserva su reloj; el ordenador conserva scroll y foco.
- **Texto que no cabe a 1,50 en 720 p:** se aplica reflow y scroll; el AC-30-03 exige capturas a 720 p y 1,50.
- **Idioma:** el slice es solo español; si se añade otro, localización revisa longitudes con escala 1,50.
- **`reducir_movimiento` cambiado a mitad de una cortina:** la cortina en curso termina como empezó; el nuevo valor vale desde la siguiente (15 D15-13 análogo).
- **`asistencia_rotacion` / `asistencia_encaje` cambiadas desde la pausa durante el puzle:** valen desde el siguiente gesto (15 regla 10; 13 lo lee al configurar y al cambiar).
- **Asistencia activada y puzle ya resuelto:** sin efecto; nada se rehace.
- **Mando desconectado con Accesibilidad abierta:** no modal, línea de cabecera (25 regla 17); los ajustes siguen editables con teclado y ratón.
- **Restablecer todos:** restablece todas las claves de 6 listadas en 25 regla 18; no toca `modo_ventana` ni `controles`. El diálogo cita lo que cubre; la cuenta de claves la fija 6, no 30.
- **Alternar en lugar de mantener activo y gesto de `rotar` en curso:** una pulsación inicia, la siguiente termina; `atrás` cancela (1 regla 14).
- **Todos los volúmenes a 0 y subtítulos apagados:** permitido (decisión del jugador); no se advierte ni se bloquea. Escena con voz crítica sin subtítulos: ver OQ 4 (aviso opcional).
- **Cambio de ajuste desde título antes de la primera partida:** escritura normal de 6; sin sesión no hay acumulador que cancelar.

## Dependencies

| Sistema | Tipo | Qué usa 30 | Qué recibe |
|---|---|---|---|
| 1 Entrada y controles | Dura | API de reasignación y ajustes de manejo; alternar en vez de mantener | Listas de ajustes de manejo; sin duplicar pantallas |
| 6 Ajustes persistentes | Dura | Claves, rangos, restablecer; `escala_texto_ui` †, subtítulos ‡ | Nuevas claves de la regla 2 |
| 13 Puzle 3 | Blanda | `asistencia_encaje` (0,10 m) | Sin cambios |
| 15 Puzle 5 | Blanda | `asistencia_rotacion` (±6°), `reducir_movimiento` | Sin cambios |
| 23 Director de audio | Blanda | Volúmenes y `reducir_sobresaltos` | Tabla «sonido → equivalente» |
| 26 Subtítulos | Dura | `subtitulos_*` ‡ | Ubicación en Sonido y pantalla |
| 25 Menú de pausa / 27 Título | Blanda | Pantalla; orden de filas | Orden de la regla 6 |
| 24 Prompt, 7 Interacción, 19 Ordenador, 4 Escena, 10 Caja, 21, 28 Atmósfera | Blanda (consumidores) | `escala_texto_ui`, `reducir_movimiento`, `icono_grande` | Cumplir reglas 9, 18 a 20 |
| 17 Sistema de pistas | Blanda | Espera de pistas (OQ 1) | — |

## Tuning Knobs

| Perilla | Defecto | Rango seguro | Afecta a |
|---|---|---|---|
| `escala_texto_ui` pasos | 1,00 / 1,25 / 1,50 | Añadir 2,00 si se acepta OQ 2 | Legibilidad frente a reflow |
| `tam_min_px` (lógico) | 18 | 18–24 | Suelo de F1 |
| `objetivo_min_px` | 44 | 44–64 | Objetivos de pulsación |
| `tope_destellos_s` | 3 (siempre) | 2–3; no subir | Fotosensibilidad |
| `parpadeo_ciclos_s` / `parpadeo_pausa_s` | 2 / 0,35 | 1–2 / 0,35–1,0 | Luces de 28 |
| `fundido_reducido_ms` | 100 | 100–200 | `reducir_movimiento` |
| `asistencia_encaje_m` / `asistencia_rotacion_deg` | 0,10 / 6 | de 13 y 15 | Motricidad |
| `multiplicador_pie` | 1,0 (paso 0,25) | 1,0–3,0 | Lectura |

Los valores viven en los datos de cada propietario, no en 30.

## Acceptance Criteria

- **AC-30-01 (R2, L):** **GIVEN** el catálogo de 6, **THEN** cada ajuste de la regla 2 existe en 6 con su tipo y defecto; ninguna clave de accesibilidad aparece en dos pantallas distintas de 25.
- **AC-30-02 (R5-R7, UI):** **THEN** la pestaña Accesibilidad de 25 muestra los 4 grupos en el orden de la regla 6, con valor en texto y ayuda de una línea; capturas retenidas en 25 y en título (27).
- **AC-30-03 (R8-R11, UI):** **GIVEN** `escala_texto_ui` = 1,50 y ventana 720 p, **THEN** ningún texto de 25, 27, 24, 19 ni del puzle 4 está recortado ni solapado; capturas retenidas.
- **AC-30-04 (R1, UI):** **THEN** texto sobre fondo ≥ 4,5:1 y bordes de control/foco ≥ 3:1, medidos en capturas de cada pantalla de UI; fallo = BLOCKING.
- **AC-30-05 (R12, H):** **GIVEN** cada puzle jugado con una simulación de protanopia/deuteranopia/tritanopia (herramienta externa), **THEN** se resuelve sin ambigüedad.
- **AC-30-06 (R13, L):** **THEN** los datos de los seis puzles no contienen temporizador de solución; el único tiempo es el de pistas.
- **AC-30-07 (R14, I):** **GIVEN** `asistencia_encaje` activa, **THEN** una pieza soltada a 0,09 m encaja y a 0,11 m no; **GIVEN** `asistencia_rotacion`, 46,1° → no resuelve y 43,5° sí (15 AC-P5-03).
- **AC-30-08 (R16, H):** **GIVEN** el slice entero con solo teclado y ratón, y otro con solo mando, **THEN** se llega a `ESC8_CIERRE` en ambos; el campo del ordenador es completable con mando.
- **AC-30-09 (R15, H):** **GIVEN** alternar-en-vez-de-mantener, **THEN** `leer`, `mantener`, `agarrar` y `rotar` se completan sin mantener ningún botón, en los seis puzles y en el pie de objetos.
- **AC-30-10 (R17, I):** **GIVEN** `vol_*` = 0 y subtítulos activos, **THEN** la información de juego es la misma y no hay silencios sin texto.
- **AC-30-11 (R17, H):** **THEN** la tabla «sonido → equivalente» de 23 no deja ningún sonido de función de juego sin equivalente visual o texto.
- **AC-30-12 (R19, I):** **GIVEN** `reducir_movimiento` activa, **THEN** los fundidos duran 100 ms y no hay tres destellos en la cortina (3 DT-12).
- **AC-30-13 (R18, I):** **GIVEN** cualquier secuencia de 28, 29, 24 y 3, medida a 60 fps, **THEN** nunca hay más de 3 destellos en 1 s; luces ≤ 2 ciclos/s con pausas ≥ 0,35 s, con la opción activa y apagada.
- **AC-30-14 (R20, I):** **THEN** 28 lee `reducir_movimiento` en el fotograma del aviso y no parpadea con ella activa.
- **AC-30-15 (R3, H):** **THEN** ningún ajuste de accesibilidad muestra etiquetas de dificultad, logros ni cambia la historia.
- **AC-30-16 (R23, I):** **THEN** cada control de 25/27 expone nombre accesible igual a su texto y orden de foco visual.

Capturas UI retenidas en `production/qa/evidence/` (por AC-30-02, -03, -04).

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D30-1 | Nivel objetivo **Estándar**, sin filtros de daltonismo ni alto contraste | Básico (solo slice §14); Completo | Básico deja sin cubrir texto, motricidad y fotosensibilidad que el diseño ya soporta; Completo (filtros, alto contraste) no se justifica porque la auditoría de la regla 12 muestra que ningún puzle depende del color y la paleta es sobria (art bible); coste de shaders sin beneficio |
| D30-2 | Lector de pantalla y 200 % de texto fuera del slice; controles con nombre y orden de foco | Entregarlos | Es acabado de producto, no vertical slice; se deja preparado (regla 23) |
| D30-3 | Sin audio mono ni señales direccionales | Añadirlos | Ningún sonido es direccional ni necesario para jugar (23 regla 40); mono no mejora nada aquí |
| D30-4 | `escala_texto_ui` entra: 3 pasos 1,00/1,25/1,50, defecto 1,00, `float` | Dejar la pregunta abierta; 2 pasos; slider continuo | PA-3 de 19 pide un mínimo de 24 px y el art bible §7.6 ya la prevé; 3 pasos son testables y evitan reflow imprevisible; el alcance de MVP de accesibilidad es decisión previa del usuario (6 OQ 15 la cuenta en la pausa) |
| D30-5 | Escala de texto y tamaño de subtítulos son independientes | Un solo multiplicador | Evita 2,25× y respeta la preferencia de cada necesidad |
| D30-6 | 30 no tiene pantalla propia: contenido en la pestaña de 25, reutilizada por 27 | Pantalla propia | 25 y 27 ya la definen (25 regla 16 y 27 regla 13); duplicar rompe «las mismas claves» (25 Deps) |
| D30-7 | `subtitulos_tamano/fondo/hablante` en «Sonido y pantalla» junto a `subtitulos_activos` | En «Accesibilidad» | El jugador busca lo de subtítulos con `subtitulos_activos` (D25-14 análogo); Accesibilidad queda sin duplicar |
| D30-8 | La espera entre pistas **no** tiene opción en el slice | Opción «sin espera» | Cambia el diseño de pistas (pilar *Autonomía*, 17 OQ 3): va a OQ 1 |
| D30-9 | Tope de destellos como garantía fija, no opción | Opción activable | La fotosensibilidad no debe depender de que el jugador sepa que es sensible |
| D30-10 | Un solo `reducir_movimiento` para todo el slice | Una clave por sistema | Evita 5 interruptores; ya es la clave consumida por 4, 10, 15, 19, 21, 24 |

## Open Questions

| # | Pregunta | Dueño | Valor por defecto |
|---|---|---|---|
| 1 | ¿Opción `pistas_sin_espera` para la espera de 20/40 s? (cognitiva; 17 OQ 3) | Usuario, 17 | No; espera corta. Si se quiere: bool en 6, fila en grupo 3 |
| 2 | ¿Subir `escala_texto_ui` a 200 % (SC 1.4.4)? | Usuario, UX | No en el slice; se añade un paso si el reflow lo permite |
| 3 | ¿Teclado en pantalla para el campo del ordenador con mando? (regla 16) | 19, UX | Sí; si no se hace, AC-30-08 falla (BLOCKING) |
| 4 | ¿Aviso suave si volúmenes a 0 y subtítulos apagados? | Usuario, UX | No (sin advertencias; D30-6) |
| 5 | ¿Cursor oculto en la llamada: pista visual/sonora para mando? (22 OQ 10) | 22, usuario | No decidido aquí; se valora en playtest con mando |
| 6 | ¿`reducir_movimiento` baja la tapa de 1,9 s del P6? (D16-3) | 10, 16 | No |
| 7 | ¿Modo de alto contraste/colorblind en el vertical completo? | Usuario, art director | Tras el slice, si el contraste (AC-30-04) o el playtest lo piden |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| **6 Ajustes** | Añadir `escala_texto_ui` (float 1,0/1,25/1,5; defecto 1,0); cerrar OQ 15; `subtitulos_*` ‡ de 26 ya propuestos; ajustar cuenta de «restablecer todos» (12 → las que correspondan) y AC-01 |
| **25 Menú de pausa** | Fila `escala_texto_ui` en Accesibilidad (cierra su OQ 5); añadir `icono_grande` y `etiqueta_accion_visible`; reordenar en 4 grupos (regla 6); `subtitulos_tamano/fondo/hablante` en «Sonido y pantalla»; actualizar AC-23, D25-7 y la cuenta de claves |
| **27 Pantalla de título** | Confirmar que reutiliza la pestaña con las nuevas filas |
| **26 Subtítulos** | Confirmar ubicación de `subtitulos_*` en Sonido y pantalla; decidir qué sonidos se rotulan (regla 17) |
| **23 Director de audio** | Tabla «sonido → equivalente visual» (AC-30-11) |
| **24 Prompt / 7 Interacción** | F2 absorbe `escala_texto_ui`; `multiplicador_pie` se compone con ella |
| **19 Ordenador** | Teclado en pantalla/alternativa para mando; consumir `escala_texto_ui`; cerrar PA-3 |
| **28 Atmósfera reactiva** (no leído) | Cumplir reglas 18 a 20: tope de destellos siempre, leer `reducir_movimiento`, sin parpadeo con ella activa, no leer `reducir_sobresaltos` |
| **29 Shaders y efectos / 3 Director de escenas** | Verificar tope de destellos (AC-30-13); DT-12 confirmado |
| **17 Sistema de pistas** | Decidir OQ 1 |
| **10 Caja / 16 Puzle 6** | Cerrar alcance de `reducir_movimiento` (OQ 6) |
| **11, 12, 14, 15, 16** | Declarar «sin color» y «sin tiempo» en sus AC (AC-30-05/06) |

## Entradas para el registro

| Entrada | Tipo | Valor | Fuente |
|---|---|---|---|
| `escala_texto_ui` † | Ajuste (float) | 1,00 / 1,25 / 1,50; defecto 1,00 | 30 regla 8 (clave en 6) |
| `accessibility_level_slice` † | Constante de diseño | «Estándar» | 30 regla 1 |
| `tope_destellos_s` † | Constante | 3 | 30 regla 18 |
| `objetivo_min_px` † | Constante | 44 | 30 regla 11 |
| `tam_min_px` † | Constante | 18 (lógico) | 30 F1 |
| `reducir_movimiento`, `icono_grande`, `etiqueta_accion_visible`, `subtitulos_*` | Ajustes (existentes o ‡) | Ver regla 2 | Dueño: 6 |

## Historial

| Fecha | Versión | Cambio |
|---|---|---|
| 2026-11-09 | 0.1 | Borrador inicial (lote autónomo). Catálogo, reparto con 25/27, `escala_texto_ui`, auditoría de puzles, fotosensibilidad y matriz de cobertura. No se ha leído el GDD de 28. |
