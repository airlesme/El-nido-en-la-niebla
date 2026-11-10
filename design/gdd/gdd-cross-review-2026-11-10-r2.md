# Cross-GDD Review Report (ronda 10 · re-verificación de las correcciones de la ronda 9)

**Fecha:** 2026-11-10 · **Veredicto: CONCERNS** (0 bloqueantes confirmados) · **Modo:** autonomous, workflow standard · **Focus:** since-last-review (los 30 GDDs de sistemas, solo lo cambiado)
Informe anterior: `gdd-cross-review-2026-11-10.md` (FAIL, 6 bloqueantes). El sufijo `-r2` hace que este informe siga siendo el último en orden léxico.

- **GDDs reviewed:** 30 of 30 present. Cuatro revisores independientes (Grep y Read): nombres de avisos, contratos 24↔7↔1 y ajustes, registro y escenarios, referencias y textos obsoletos. Tres agotaron su límite de turnos y se reanudaron. Informes: `reviews/cross-review-r11-*.md`.
- **Importante:** tras la re-verificación se aplicó una última tanda de limpieza de los restos que encontraron (3 agentes y una corrección propia en el GDD 26). **Esa limpieza no se ha vuelto a verificar de forma independiente.**
- **Decisiones del usuario respetadas:** las anteriores; las cuatro de diseño que esta serie de rondas destapó siguen SIN decidir y marcadas «pendiente de decisión del usuario».

## Estado de los 6 bloqueantes de la ronda 9

| Bloqueante | Estado tras re-verificación | Evidencia |
|---|---|---|
| **R9-B1** avisos sin declarar en 3 / dos nombres de pausa / 22↔23 | **CERRADO** (restos limpiados después) | Contrato de la regla 10 de 3 coherente en todos los emisores y consumidores; orden «solicitada → completada → pausa cerrada» igual en 25, 4, 23 y 26 (revisor 1). Restos: `T_compl` de 22 (ya corregido a `t_interrupt_s`), alias `pause_closed` en 25 y ‡ obsoletas, limpiados en la ronda 10 |
| **R9-B2** registro sin constantes de 17 y 23–30 | **CERRADO** | ~75 constantes comparadas con los Tuning Knobs: todas coinciden en valor, rango y unidad; dueños únicos correctos; 382 entradas sin `name:` duplicado (revisor 3). Restos: rango de `texto_min_px` y suelo `sub_alto_min_px`, ya alineados a 24 px (incluido el GDD 26) |
| **R9-B3** `puzzle_solved` inexistente | **CERRADO** | Ningún GDD lo emite ni lo pide; solo queda como causa de guardado de 5 (revisor 1) |
| **R9-B4** 24 → 7 y 1 sin aplicar | **CERRADO** | `anillo_visible`, `duracion_pie`, `resultado` ampliado y `get_binding_label(accion, dispositivo)` en 7 y 1 con regla, AC y decisión; firmas iguales a 24 (revisor 2). Resto: 21 (AC-21-15, `ESC1_MENSAJE`), 23 y 28 filtran «interacción ejecutada» por `HECHO` (aplicado en la ronda 10) |
| **R9-B5** ciclo duro 27↔30 | **CERRADO** | 27→30 Dura, 30→27 Blanda; sin ciclo duro entre 17 y 23–30 (revisor 2) |
| **R9-B6** fundido 0,15 s frente a 100 ms | **CERRADO** | Ningún 0,15 s para ese fundido; 27 AC-17 y AC-18 coherentes (revisor 2). Resto: rango 50–200 frente a 50–150 ms, unificado a 50–150 ms en la ronda 10 |

Escenarios (revisor 3): **S3 «Volver al título» desde la pausa CERRADO** (ya no queda voz ni subtítulo colgado); **S5 ajustes de texto desde la pausa CERRADO**; S1 y S6 «Nueva partida» parciales sin BLOCKER visto.

## Warnings que quedaban (aplicados en la ronda 10, sin verificar)
- Textos «sin GDD aún» / «cuando exista» sobre 17 y 23–28 en 3, 6, 5, 1 y 8, y ‡ obsoletas en 23, 25, 26, 28, 17, 4, 5, 24 y 30 (el revisor 4 las clasificó como bloqueantes; son referencias a sistemas que existen, es decir texto viejo, no contratos rotos).
- Contradicción real: la fila 12 del índice y el GDD 12 decían «17 lee `memo_leido`» frente a D17-10; fila 15 del índice sugería un ciclo duro 9↔15; 12 y 15 no repetían a 29 con su dureza.
- «Nueva partida o Continuar» desde la pausa en 1, 4 y 21 frente a 25 R31 (solo «Nueva partida» con confirmación; «Continuar» solo en el título).
- ACs de 27 y 29 sin tipo; umbral de destello en unidades distintas (28 frente a 30); `piso_mega_db` sin fila en 23; `BOX_Cn_OPEN` sin «sustituida por» en 7, 16 y 9.
- **Consecuencia de diseño nueva (D26-22):** con el suelo único de 24 px lógicos, a 720p los tamaños de subtítulo `pequeno` y `medio` dan el mismo tamaño (24 px). Si el equipo de referencia es 720p, el selector pierde efecto en los dos primeros niveles. Pregunta abierta para 30 y el usuario.

## Game Design Issues / Scenarios
Sin bloqueantes. Siguen abiertas las cuestiones de tono de la ronda 9 (no tocadas).

## Verdict: CONCERNS

Los 6 bloqueantes de la ronda 9 están cerrados y verificados por un revisor distinto del autor. Los 30 GDDs de sistemas tienen contratos recíprocos con los mismos nombres de aviso, un único dueño por constante, esquema único de datos de puzle y una sola definición de fundido, destello, contraste y suelo de texto. Lo que queda son decisiones de diseño y de ingeniería, no incoherencias entre documentos.

### Decisiones tuyas pendientes (ninguna bloquea el diseño; todas condicionan el slice)
1. **Espera de pistas de 20/40 s** (17 OQ3, 30 OQ1) frente al pilar «Tensión sin castigo», y si los pips, el cuaderno y «Repetir» de 17 se recortan.
2. **Parpadeo 1,15 s y apagón 0,8 s con `reducir_sobresaltos`:** modifican slice C.4 y C.7.
3. **`reducir_movimiento` más allá del slice §14** (30 R19, 28 R9) y si `escala_texto_ui` se da por cerrada (si no, «restablecer todos» pasa de 18 a 17 claves).
4. **Aviso «interacción ejecutada»:** filtrar por `HECHO` (opción por defecto, aplicada) o aviso aparte solo para 24 (7 OQ 6).
5. **Suelo de subtítulos a 720p** (D26-22).
6. Las de siempre: D13-4, silueta de `slot_6`, `VO_G_07`, `CARTA_A`/«La verdad», asimetría «Devolver»/«Asignar», criterio de duración (suelo real ≈ 10,7 min), D-15 del slice, textos de `VO_G_14_ASG` y de la respiración de la llamada.

### Decisiones de ingeniería que el diseño ya no puede resolver
- **ADR de pausa** (`SceneTree.paused` / `process_mode`, audio y animación en pausa): sin documentación del motor; afecta a 23, 25, 26, 28 y 29.
- ~20 afirmaciones sobre Godot 4.7 siguen marcadas NOT SOURCEABLE y varios ACs son PV: se resuelven con un prototipo, no con más revisión de documentos.

---

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:** los cuatro revisores fueron parciales (27, 6, 29, 30, 2, 18, los puzles, 19 y 20 solo por Grep en algunos; las Dependencies completas de casi todos; las líneas largas de 21, 27, 25, 24, 6 y 1; los ACs de 23–30; el bloque de fórmulas del registro L1–1050). **La última tanda de limpieza no está re-verificada.** Siguen sin existir `puzzles.json` y `flags.json`. NOT SOURCEABLE: `SceneTree.paused`, `process_mode`, pausa de audio y animación, `AnimationPlayer`, `Area3D`/Jolt, `render_priority`, `TIME` en pausa.
