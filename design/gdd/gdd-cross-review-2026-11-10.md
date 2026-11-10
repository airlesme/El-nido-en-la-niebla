# Cross-GDD Review Report (ronda 9 · los 30 GDDs de sistemas, por primera vez todos presentes)

**Fecha:** 2026-11-10 · **Veredicto: FAIL** (6 bloqueantes) · **Modo:** autonomous, workflow standard · **Focus:** full
Informes anteriores: `…-2026-11-09.md` (8 bloqueantes) a `-r8` (CONCERNS, 0 bloqueantes, 21 GDDs). Esta es la primera revisión que incluye los 9 GDDs del lote autónomo (17, 23–30), escritos por otra sesión y nunca contrastados con los otros 21.

- **GDDs reviewed:** 30 of 30 present. Siete revisores independientes (Grep y Read): A contratos del lote nuevo con los 21 antiguos; B contratos internos y tabla de dependencias; C dueños de datos, registro y fórmulas; D pilares y accesibilidad; E nueve escenarios; F criterios de aceptación y referencias; G afirmaciones sobre Godot 4.7. Tres agotaron su límite de turnos y se reanudaron. **Ninguno cubrió todo**: ver «Cobertura».
- **Desviación del procedimiento:** lectura por secciones sin contenido pegado (los GDDs suman más de 2 MB).
- **Decisiones del usuario respetadas:** las anteriores (T4 acepta devolver o asignar; `VO_G_13B` = «Lo sé»; P6 con dos niveles de pista; B.1 literal; `repasar_bolsillo`; `MEGA_03`; zonas T-D-OUT/T-OFI-IN; la llamada definitiva y repetible al cargar; no colgar manual; cursor oculto; criterio de duración a medir).
- Informes de revisores en `reviews/cross-review-r10-*.md`.

## Consistency Issues

### Blocking

🔴 **R9-B1 · 3 (regla 10) · Avisos que 23, 25, 26, 28, 17 y 22 consumen o emiten y 3 no declara.** *(A, C, E, F)*
- «sonido pedido» (emite 7, 8, 10, 15, 19 y 25; lo consume 23 R5); «línea iniciada» (emite 23); «puzles configurados» (emite 9; lo consume 17 ‡); las causas de «línea terminada»; y el aviso de pausa, que tiene DOS NOMBRES: `pause_closed` (23 R5/R41; AC-23-18 y AC-23-32) y «pausa cerrada» (25 AC-25-50 y D25-19, 26 R5/R25, 28). 3 solo lista `pause_opened`.
- 22 (l.193) pide `SFX_*` por «línea pedida» más «sonido de llamada pedido» ‡; 23 R7b rechaza `SFX_*` en «línea pedida» y trata «sonido de llamada pedido» como alias de «sonido pedido»: contradicción directa 22↔23.
- Arreglo: 3 declara todos los avisos con un nombre único y su emisor; 22 y 23 se alinean sobre qué hace «línea pedida»; 17 y 28 usan los nombres de 3.

🔴 **R9-B2 · Registro (`entities.yaml`) sin ninguna constante de 17 ni de 23–30.** *(C)* La búsqueda por `source:` de esos GDDs da 0 resultados. Entre otras faltan `t_min_lect_s`, `cps_lect` y `t_max_lect_s`, que 26 declara como de 23 y no duplica.

🔴 **R9-B3 · 28↔9 · `puzzle_solved {id}` no existe.** *(A)* 28 pide a 9 emitirlo; el aviso real es `EV_PUZZLE_SOLVED_<ID>` (9 y 3).

🔴 **R9-B4 · 24↔7↔1 · dependencia dura de 24 con cambios sin aplicar.** *(A)* 24 exige a 7 `anillo_visible`, `duracion_pie`, `mostrar_pie` y un dominio ampliado de `resultado`, y a 1 `get_binding_label`; ni 7 ni 1 los contienen, y ningún GDD lo cierra (todo ‡).

🔴 **R9-B5 · 27↔30 · ciclo duro sin declarar.** *(B)* 27 declara a 30 «Dura» (`pantalla-de-titulo.md` L136) y 30 declara a 27 «Dura» (`opciones-de-accesibilidad.md` L151); «Circular Dependencies» del índice no lo recoge. Declararlo o degradar un lado.

🔴 **R9-B6 · Fundido con `reducir_movimiento`: 0,15 s frente a 100 ms.** *(F, C; confirmar con el autor)* 27 AC-18 y 26 fijan 0,15 s; 30 AC-30-12, 25 AC-25-08, 26 AC-26-20, 24 AC-24-16, 29 AC-1, 6 y el registro fijan 100 ms (0,10 s). No pueden pasar a la vez, y AC-17 de 27 (3,15 s) depende de 0,15 s.

### Warnings

**Contratos y dependencias (A, B)**
- Durezas discrepantes: 17↔25 (17 Blanda, 25 Dura), 25↔27 (27 Dura, 25 Blanda), 25↔30 (30 Dura, 25 Blanda), 23↔26 (23 dice que 26 lo declara Dura, 26 lo declara Blanda), 27 frente a 3, 4 y 1 (27 Dura; ellos Blanda), 29↔15 (29 Dura, índice «blanda»). Direcciones: 28 y 21 «sin dependencia» frente al índice; 28 y 29 se contradicen; 23 sin fila hacia 30 (30 lo declara Dura para AC-30-11); 24 no nombra a 26; 3 no lista a 26; 17 dice `formulario_leido`/`memo_leido` «sin uso» y 3 y 20 los declaran lecturas.
- Índice: columnas «Depende de» de las filas 17, 24, 26, 27 y 30 incompletas; fila 28 lista a 21 sin que 28 lo declare; fila 25 sin marcar blanda su dependencia de 18.
- 23 da a 22 como emisor de «estado de objeto pedido» (en 3 solo lo emite 21); 17 pide `SFX_CLICK_SUBTLE` y 23 no lo lista; 28 y 23 derivan por separado la lluvia de `LUCES_APAGON`; 30 y 25 podrían duplicar claves de subtítulos.

**Constantes y fórmulas (C)**
- Dos dueños: `t_cola_canal_s` (23) y `t_espera_voz_s` (21), ambos 8,0 s; `t_corte_senal_s` (22, 0,1–0,6) y `t_interrupt_s` (23, 0,05–0,3) para el mismo fundido. 29 `x_h_min` tiene un rango inferior (0,028 m) que incumple su propia F29-3 (mínimo 0,0311 m). 21 R23 dice «≈3,3 destellos/s» y 28 da 1,15 s con ≤ 2,0 Hz.
- Ajustes: 6 tiene 12 claves en «restablecer todos»; 25 dice 12, 30 dice 18, y con `advertencias_vistas` de 27 serían 19; faltan en 6 las claves de 24, 26 y 30. Cinco suelos distintos de tamaño de texto; 24, 25, 28 y 29 usan † sin fuente.

**Escenarios (E; los nueve parciales, ninguno completo)**
- «Volver al título» desde la pausa: 25 R28 emite «pausa cerrada» DESPUÉS de la descarga total, 23 R42 solo descarta voz pausada en «carga iniciada» y 26 R27 solo retira bloques en «carga iniciada»: una voz pausada puede reanudarse sobre el título o un subtítulo quedar congelado.
- 25 R16 no incluye `escala_texto_ui`, `icono_grande`, `etiqueta_accion_visible` ni los ajustes de subtítulos: con 25 como está el jugador no puede cambiar escala de texto ni tamaño de subtítulos.
- 28 R22 y 29 R35 dependen de pausar el árbol de escena; 25 y 23 D23-25 dicen que 25 no lo pausa; 29 usa el nombre de Godot 3 `PAUSE_MODE_PAUSABLE`.
- **Posible pérdida de partida:** si pasa `t_espera_inspeccion_s`, 27 asume `ninguna`; «Nueva partida» sin confirmación puede sobrescribir una partida válida que la inspección detecte después (contradice el candado de 27 R9).
- 4, 21 y 1 especifican «Nueva partida»/«Continuar» desde la pausa; 25 no ofrece esas filas. «Continuar» significa cosas distintas en 25 (reanudar) y en 27 (cargar).

**Criterios de aceptación y referencias (F)**
- 25 AC-25-23 y AC-25-27 chocan con 30 AC-30-01, AC-30-02 y D30-7 (12 frente a 18 claves y otro reparto de pantallas). Umbrales de destello distintos en 29 AC-15, 30 AC-30-13 y 28 AC-28-21; pie ≥ 20 px (24 AC-24-14) frente a ≥ 24 px (25 AC-25-18). 27 y 29 no tipan ningún AC. 28 AC-28-17 exige cerrar AC-28-16 y AC-28-19, que dependen de un spike pendiente. 17 AC-17-17 ambiguo ante AC-17-14/15.
- Textos obsoletos: «sin GDD»/«por redactar» sobre sistemas que ya existen en `director-de-escenas`, `documentos-y-bolsillo`, `puzle-1`, `puzle-5`, `puzle-6`, `sistema-de-pistas`, `llamada-telefonica`, `ajustes-persistentes`, `base-de-contenido-narrativo`, `estado-y-bus-de-eventos` y `marco-de-puzles`; «25–30 min» en `CLAUDE.md` L9 y `README.md` L4.

**Motor (G)**
- ~42 afirmaciones sobre Godot: 12 sustentadas, 20 NOT SOURCEABLE ya marcadas, 8 NOT SOURCEABLE sin marcar, 2 posiblemente erróneas: 29 R45 («los materiales `unshaded` no reciben glow»; el glow 4.6 es un postproceso, `rendering.md`) y el nombre `PAUSE_MODE_PAUSABLE` (en 4.7 es `PROCESS_MODE_PAUSABLE`, como ya escribe 28 R22). 23 (l.412) dice «no cita ninguna API que no figure en `audio.md`» pero cita `stream_paused`, `process_mode` y `AudioListener3D`; 27 R14 trata `SceneTree.quit()` como «API estándar» sin marca; 24 AC-24-07 («filtros de daltonismo del motor») no está cubierto; 29 `render_priority`/`blend_mode`/`fwidth(UV)`/`TIME` en pausa sin marca. AC-23-32, AC-23-14, AC-28-16 y AC-29-3/17 deben pasar a PV. **La pausa (`SceneTree.paused`) sigue sin documentación del motor**; 25 OQ 2 lo reconoce.

## Game Design Issues (D)

### Blocking
Ninguno. El sistema de pistas (17) no rompe ningún puzle y ningún momento supera 4 sistemas con acción simultánea; 17, 25 y 27 no añaden minutos a F9.

### Warnings
- **Tono y alcance decididos sin pregunta:** 30 R19 y 28 R9 extienden `reducir_movimiento` más allá del slice §14; 30 «cierra» `escala_texto_ui`, que el índice mantiene pendiente.
- **Pilar 4:** la espera de pistas de 20/40 s choca con «Tensión sin castigo»; 17 OQ3 y 30 OQ1 se remiten mutuamente sin dueño. Los pips, el cuaderno y la fila «Repetir» de 17 rozan «NOT medidores» y «No hay menú de inventario» (marcados cortables en OQ11).
- **Cambios al slice:** el parpadeo pasa a 1,15 s por defecto (28 R9/OQ8) y el apagón a 0,8 s con `reducir_sobresaltos` (28 R18): ambos modifican C.4/C.7.
- 29 R12 y 28 R13 se contradicen sobre quién posee el reflejo del cristal B04. Cuatro definiciones de «destello» (24, 28, 29, 30) y tres umbrales de contraste (25, 26, 30). El ejemplo «[Llanto contenido]» de 26 R3 interpreta el sonido. Tras cargar, el panel de 17 muestra «Nada pendiente» aunque el puzle esté activo.
- D-W1, D-W2, D-W3, D-W5, D-W8 y D-W11 vigentes; D-W4 ampliada (17 R32 y su edge 10 repiten pistas que no añaden información); D-W6 cerrada; D-W7 parcial (26 R2 hace obligatorio `SUB_BREATH_BROKEN`, texto pendiente del writer).

## GDDs Flagged for Revision

| GDD | Motivo | Prioridad |
|---|---|---|
| estado-y-bus-de-eventos.md (3) | R9-B1 | **Blocking** |
| entities.yaml (registro) | R9-B2 | **Blocking** |
| 28 atmosfera-reactiva · 9 marco-de-puzles | R9-B3 | **Blocking** |
| 24 prompt-de-interaccion · 7 interaccion-e-inspeccion · 1 entrada-y-controles | R9-B4 | **Blocking** |
| 27 pantalla-de-titulo · 30 opciones-de-accesibilidad · systems-index.md | R9-B5 | **Blocking** |
| 27, 26, 30, 25, 24, 29, 6 | R9-B6 (valor del fundido) | **Blocking** |
| 22, 23, 25, 26, 28, 17 | contratos y escenarios (avisos) | Warning |
| 6, 21, 29, 30, 17, 24, 25, 27 | constantes, ajustes, tono | Warning |
| CLAUDE.md, README.md y GDDs con «sin GDD» | textos obsoletos | Warning |

## Verdict: FAIL

6 bloqueantes, todos de contrato entre el lote nuevo y el resto (avisos sin declarar, registro sin las constantes nuevas, ciclo duro, valor del fundido, cambios sin aplicar). Los 21 GDDs antiguos no introducen bloqueantes nuevos. Es el resultado esperable de integrar nueve GDDs escritos en paralelo con un diseño que ya estaba cerrado.

### Required actions before re-running
1. R9-B1: 3 declara todos los avisos nuevos con un nombre único (propuesta: «pausa cerrada», que usan 25, 26 y 28); 22 y 23 se alinean sobre «línea pedida».
2. R9-B2: registrar las constantes de 17 y 23–30.
3. R9-B3: 28 usa `EV_PUZZLE_SOLVED_<ID>`.
4. R9-B4: aplicar en 7 y 1 lo que pide 24, o recortarlo.
5. R9-B5: decidir qué lado del ciclo 27↔30 es el dependiente.
6. R9-B6: un solo valor de fundido (propuesta: 100 ms, que ya usan 6 y el registro).
7. Avisos de escenarios (voz y subtítulo tras «Volver al título»; ajustes de accesibilidad ausentes en 25; confirmar «Nueva partida» si la inspección tarda; «Nueva partida»/«Continuar» desde la pausa) y de durezas, constantes y textos obsoletos.
8. Re-ejecutar `/review-all-gdds since-last-review`.

### Decisiones tuyas que esta ronda destapa
1. **Espera de pistas de 20/40 s** (17 OQ3, 30 OQ1) frente al pilar 4, y si los pips, el cuaderno y «Repetir» de 17 se recortan.
2. **Parpadeo 1,15 s y apagón 0,8 s** con `reducir_sobresaltos`: cambian el slice C.4/C.7.
3. Si `reducir_movimiento` se extiende más allá del slice §14 (30 R19, 28 R9) y si `escala_texto_ui` se da por cerrada.
4. Las anteriores: D13-4, silueta de `slot_6`, `VO_G_07`, `CARTA_A`/«La verdad», asimetría Devolver/Asignar, criterio de duración (suelo real ≈ 10,7 min), D-15 del slice.

---

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:** los siete revisores fueron parciales. No se leyeron: 27 y 29 (por A), buena parte de las Detailed Rules, fórmulas, Edge Cases y AC de 17 y 23–29 (D), las Dependencies de 1 a 22 salvo lo citado (B), los Tuning Knobs de 1–22 (C), los ACs de 1, 7, 8, 9, 10, 18, 19, 20 y 21 y unas 59 de las 80 referencias pedidas (F), y las cuerpos de 9, 10, 21, 22, 2 y 4 para la parte de motor (G). Los nueve escenarios quedan parciales (E); la llamada (S4) es el más avanzado. Siguen sin existir `puzzles.json` y `flags.json`. NOT SOURCEABLE: `SceneTree.paused`, `process_mode`, pausa de audio y animación, `AnimationPlayer`, `Area3D`/Jolt, `render_priority`, `TIME` en pausa.
