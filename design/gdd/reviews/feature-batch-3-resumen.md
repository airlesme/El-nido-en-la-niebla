# Revisión independiente del lote Feature 3 (puzles 1 a 6) — resumen

**Fecha:** 2026-11-09 · **Revisores:** uno por GDD, sin el contexto de los autores (solo Grep y Read). Tres agotaron su límite de turnos y se reanudaron para volcar el informe; las revisiones de 13 y 16 son parciales.
Informes completos: [11](puzle-1-cronologia-review.md) · [12](puzle-2-memorando-en-el-cristal-review.md) · [13](puzle-3-encaje-de-la-foto-review.md) · [14](puzle-4-tablero-de-tareas-review.md) · [15](puzle-5-espejo-de-la-diferencia-review.md) · [16](puzle-6-decision-review.md).

## Veredictos

| GDD | Veredicto | Bloqueantes | Avisos |
|---|---|---|---|
| 11 Puzle 1 · Cronología | NEEDS REVISION | 0 | 9 |
| 12 Puzle 2 · Memorando en el cristal | NEEDS REVISION | **1** | 7 |
| 13 Puzle 3 · Encaje de la foto | NEEDS REVISION | 0 (revisión incompleta) | 9 |
| 14 Puzle 4 · Tablero de tareas | NEEDS REVISION | **1** | 12 |
| 15 Puzle 5 · Espejo de la diferencia | NEEDS REVISION | 0 | 10 |
| 16 Puzle 6 · Decisión | NEEDS REVISION | 0 (revisión parcial) | 6 |

Los cálculos (permutaciones, tiempos de tanteo, revelación de 16,0 s, tapa de 1,9 s, F1–F3) cuadran en los seis. Ninguno viola un pilar sin declararlo como pregunta abierta.

## Bloqueantes
- **12 (B1):** la pista 2 declara `"kind":"FLOOR_MARKS","targets":["B08"]`; la regla 29 de 9 exige que los `targets` existan en los datos del puzle y en 7, y la regla 26 de 7 dice que `B08` «no se declara»: fallo de arranque en la build final. Falta pedir a 7 que lo incluya o a 9 que exima a los decorados.
- **14 (F4):** `p_oir` «lo mide 22; ver su F3» y el registro de 9 (regla 32) «calcula `r_T4` y `p_RET`»: ni la F3 de 22 ni la regla 32 de 9 lo hacen, y no está en «Cambios requeridos».

## Tema transversal: el esquema de `puzzles.json` de 9 no admite lo que piden los seis puzles
`value_from`/`map` en `on_solved.write` (14, 16), `on_partial.stamp_text_keys`, `elements`, `on_reject.message_key/message_s/applies_to`, `commit_on`, `presentation`, `request_reading`, `idle_reset` (16), `solution.visual_elements`, `on_reject: null`, tipos nuevos de `AFFORDANCE` (`MIRROR_PREVIEW`, `FLOOR_MARKS`, `BEAM_HALO`, `MARK_LIT`), `HIGHLIGHT` sobre elementos no interactivos, validación de `targets` para decorados, `request_hint` durante `RESOLVING`. Todos están en «Cambios requeridos (9)» de cada puzle: 9 debe absorberlos como un único cambio de esquema antes de implementar nada.

## Avisos más relevantes por puzle
- **11:** contradicción interna sobre si los huecos `ref_N` tienen atracción asistida; cita de R34 donde toca R30; ambigüedad sobre quién crea `ref_N`/`stamp_N`; D11-6 y D11-8 activos sin consultar; la cabecera de Open Questions dice que ninguna contradice el slice y OQ-5 sí; falta reciprocidad en 19 y 20.
- **12:** F7 de 3–6 min frente a 1,1–4,4 min del modelo: los autores recomiendan bajar F7, el revisor recomienda medir antes (bajarlo acerca el mínimo de F9 de 14,8 a 13,3 min); la pista 2 afirma que la solución «se deduce» pero no marca el punto vacío (solo tanteo por lámpara; D-W2/Q12-1); `cobertura_anexo_a.json` no existe en `assets/data`.
- **13:** el encuadre de la vista no está definido (a 0,35 m con FOV 70° la bandeja en x = 0,48 y `P2`/`P4` en x = 0,42 quedan fuera de pantalla en 16:9 y 16:10); **D13-4 (soltar en la bandeja = `NONE`, sin `SFX_REJECT`) se aparta de B.3 del slice: lo decide el usuario**; B.3 da a cada pieza un número de fila en el borde y 13 solo lo muestra con la pista de nivel 2; el tono de la silueta de `slot_6` sin cerrar.
- **14:** AC-14-25 (mediana 2–4 min) no coincide con la alerta 1,5–5 min de F3; «Devolver» sella con 1 clic y de forma irreversible, «Asignar» necesita 2; faltan ACs para R11, R14, E5, E7, E8 y E10; el índice (:277) está obsoleto; D-W10 sigue como pregunta abierta (bien).
- **15:** AC-P5-04 inestable (a 7,6°/s caen 47 o 48 fotogramas según la fase; usar 8°/s y 16°/s); la marca ‡ con 13 se puede quitar (13 existe); 9 regla 14b solo cubre `FADE` y 15 extiende los 100 ms a `OUTLINE` sin pedirlo; el paso de §10.5 a B.5 no está en «Decisiones tomadas»; `VO_G_07` afirma un acto del Guardián: decide el creative-director (pilares 1 y 5).
- **16:** `seleccionar` llega con `inicio` y `fin` en el mismo fotograma al soltar, así que la mitad de AC-16-04 es inalcanzable; rehacer la elección tras un cierre antes de guardar roza D-14 y no está elevado a Open Question; `t_lectura` sin fuente.

## Decisiones propuestas para la ronda de corrección (no aplicadas)
1. **9 absorbe todo el esquema** en un cambio único (versión del esquema de `puzzles.json`), con los tipos de `AFFORDANCE`, los campos de `on_solved`, `on_partial`, `on_reject`, `idle_reset` y `solution.visual_elements`, y valida `targets` de decorados con una marca `decor: true` (cierra el bloqueante de 12 sin tocar 7).
2. **22 y 9 calculan `p_oir`/`r_T4`/`p_RET`** o 14 retira esa dependencia y lo deja como métrica de playtest (cierra el bloqueante de 14); recomendación: métrica de playtest.
3. **D13-4:** seguir B.3 del slice (con `SFX_REJECT` al soltar fuera) salvo que el usuario apruebe la desviación; **no bajar F7 del puzle 2** hasta medir.
4. Corregir en cada puzle sus avisos propios (contradicciones internas, ACs inestables, referencias, reciprocidad) y elevar a pregunta abierta lo que toque tono.
