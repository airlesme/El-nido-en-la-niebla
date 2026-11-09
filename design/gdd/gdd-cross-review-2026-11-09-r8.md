# Cross-GDD Review Report (ronda 8 · lote Feature 3: los seis puzles y el esquema v2 de 9)

**Fecha:** 2026-11-09 · **Veredicto: CONCERNS** (0 bloqueantes) · **Modo:** autonomous, workflow standard · **Focus:** since-last-review (GDDs 11 a 16, marco 9 con esquema v2, y contratos con 7, 10, 18, 19, 20, 22, índice y registro)
Informes anteriores: `-r7` (CONCERNS, capa Feature de 15 GDDs) y `reviews/feature-batch-3-resumen.md` (6 puzles NEEDS REVISION, 2 bloqueantes).

- **GDDs reviewed:** 21 of 21 present (1–16, 18–22). Tres revisores independientes (Grep y Read): esquema v2 frente a los seis bloques de datos, contratos con los siete GDDs vecinos, y diseño y tiempos. El de diseño agotó su límite de turnos una vez y se reanudó. Informes: `reviews/cross-review-r9-esquema-v2.md`, `-contratos.md`, `-tiempos-y-diseno.md`.
- **Decisiones del usuario respetadas:** las anteriores, más las 4 aprobadas el 2026-11-09 para esta ronda (esquema único en 9 con `decor: true`; `p_oir`/`r_T4`/`p_RET` como métrica de playtest de 14; D13-4 sigue B.3 del slice y no se baja F7 del puzle 2 hasta medir; cada puzle corrige sus avisos y lo de tono sube a pregunta abierta).

## Estado de los bloqueantes de la ronda anterior

| Bloqueante | Estado | Evidencia |
|---|---|---|
| **12:** `B08` (decorado) no declarable | **CERRADO** | P2 l.317 `{ "id": "B08", "decor": true }`; lo aceptan 4b-f (l.76) y la regla 29 (l.261); 7 no lo declara |
| **14:** `p_oir`/`r_T4`/`p_RET` no calculados por 22 ni por el registro de 9 | **CERRADO** | Ninguna frase se los atribuye (Grep); regla 32, D9-77, P4 l.125/l.315, 22 l.191/l.292, índice l.316 y registro l.337 dicen «métrica de playtest de 14» |
| Esquema de `puzzles.json` de 9 insuficiente | **CERRADO con avisos** | Los seis JSON pasan campo a campo; ver avisos E-1…E-4 |

## Warnings (no bloquean)

⚠️ **E-1 · Ejemplos y validación.** 4b (l.61) dice que una entrada sin los campos nuevos «sigue siendo válida», pero la regla 29 (l.261) exige tres niveles de pista; los ejemplos de P1 (1 nivel), P4, P5 y P6 (sin `hints`) no la pasarían. *(esquema)*
⚠️ **E-2 · Nombres sin fijar.** `AUTO_SOLVE_ELEMENT` usa `target` en singular (P4 l.288) y `TEXT` usa `key`; ni 4b ni la regla 25 los fijan, mientras `HIGHLIGHT` usa `targets` y 4b usa `*_key` en otros campos. *(esquema)*
⚠️ **E-3 · P3.** Dice usar `gestos_aceptados` (l.270) pero su JSON (l.273–329) no lo trae; `snap_radius_m` y `view_distance_m` van en `solution` con ‡ pendiente de 9. *(esquema)*
⚠️ **E-4 · ‡ residuales.** P6 l.194 dice «Ningún campo con ‡» y l.243 deja «R = 64 px (‡ 7)»; campos de controlador fuera de 4b: P5 `interactive_elements`, P3 `slots`/`pieces`/`tray_rect_m`, P4 `urgency`/`owner`. *(esquema)*
⚠️ **C-1 · Durezas.** 14→10: P4 l.168 y el índice «Dura», 10 l.200 «Blanda». 11→20: P1 l.308 y el índice «Dura», 20 l.217 «Blanda (la declara 11 como dura vía 9…)», contradictorio. 7→11–16: 7 l.433 «Indirecta (vía 9)», mientras 12 declara a 7 Dura, 13 Dura transitiva y 14/16 Blanda. *(contratos)*
⚠️ **C-2 · «Cambios requeridos» sin aplicar.** 13 no lista a 15 como dependiente (P5 l.410); el GDD de Ajustes (6) l.38 sigue en «13 Puzle 3» (P3 l.381 pide «13 vía 9») y su Open Question 5 de `asistencia_rotacion` sigue provisional; las filas 11–16 del índice siguen en «revisado una vez» (P1 pide «ronda 7» y P4 «ronda 8»). *(contratos)*
⚠️ **C-3 · Textos obsoletos.** Los «Cambios requeridos» de los seis puzles dicen «No se ha editado ningún archivo»; P1 propone `P1_DELAY_S` y P2 `p2_lamp_count` pero el registro usa `delay_s_P1` y `lamp_count_P2`; `marco-de-puzles.md` l.435, 800, 803 y 832 afirman «25–30 min» mientras `game-concept.md` l.110 dice ~15–30 y niega los 25–30. *(contratos)*
⚠️ **T-1 · Tiempos.** F7 y D9-76 dicen P2 «1,1–4,4» pero P2 F4 da 1,11–4,51 (4,5). *(tiempos)*
⚠️ **T-2 · Revelación de P5.** El marco F7 dice «P5 (más ~16 s de revelación)» y F9 no la suma; P5 D15-7 pide aclararlo y 9 no lo ha recogido. Leído al pie de la letra, F9 sube 0,27 min (15,10 / 33,36). *(tiempos)*
⚠️ **T-3 · El mínimo real del slice.** El «mínimo» de F9 (14,8 min) usa los anclajes de F7, no los mínimos de los modelos de cada puzle (que suman ≈ 6,4 min frente a 10,5): el suelo real es ≈ 10,7 min y un jugador rápido puede quedar por debajo del «~15 min» del criterio 1. *(tiempos; relevante para el criterio de duración del slice)*
⚠️ **T-4 · Rangos por puzle.** P4 en el peor caso (6,8 min) supera el «~6 min» de slice §22; P2 (1,1), P5 (0,94) y P6 (0,19) quedan en el límite o por debajo de «~1 min» (los nominales están todos dentro). *(tiempos)*
⚠️ **T-5 · Valores † sin fuente.** P1 F4 tiene celdas sin † ni fuente (`T_leer`, trayectos, deducir, desvío); solo OQ-7 las declara hipótesis. *(tiempos)*
ℹ️ INFO: el máximo de la llamada (44,8 s) omite el +1,0 s de `SFX_PHONE_END` que sí incluye el mínimo (debería ser 45,8 s); P3 D13-9 sigue pidiendo aclarar la regla 25 de 9, que ya lo recoge.

## Game Design Issues
Ninguno bloqueante. Ningún puzle queda sin salida ni castiga; las preguntas abiertas de tono siguen abiertas y declaradas como decisión por defecto, no disfrazada. El riesgo más real es el de P6 (OQ 2): `CARTA_A` y el botón «La verdad» pueden leerse como mentira frente a verdad (pilar 1). D-W1…D-W5, D-W9 y D-W10 siguen vigentes con los valores de los GDDs; D-W11 queda reconciliado salvo T-1…T-4; D-W8 no aparece en los seis. `repasar_bolsillo` es coherente con «No hay menú de inventario». Ningún momento de P5 o P6 supera 4 sistemas con acción simultánea.

## Cross-System Scenario Issues
Sin escenarios nuevos esta ronda. Los recorridos de la revelación de P5 y de la carta de P6 con interrupción y carga dependen de las reglas 17–19 de 9 y de 7 regla 27b, y siguen coherentes en lo leído.

## GDDs Flagged for Revision

| GDD | Motivo | Prioridad |
|---|---|---|
| marco-de-puzles.md (9) | E-1, E-2, T-1, T-2, T-3, C-3 («25–30 min») | Warning |
| puzle-3-encaje-de-la-foto.md (13) | E-3, E-4, C-2 (fila 15) | Warning |
| puzle-6-decision.md (16) · puzle-4 (14) · puzle-5 (15) | E-4, T-4, T-5, C-2 | Warning |
| puzle-1-cronologia.md (11) · puzle-2 (12) | C-1, C-3, T-5 | Warning |
| documentos-y-bolsillo.md (20) · caja-y-compartimentos.md (10) · interaccion-e-inspeccion.md (7) · ajustes-persistentes.md (6) | C-1, C-2 | Warning |
| systems-index.md · entities.yaml | C-2, C-3 | Warning |

## Verdict: CONCERNS

Sin bloqueantes: los de las ocho rondas están cerrados y verificados por un revisor distinto del autor. Los 22 GDDs de sistemas (1–16 y 18–22) tienen contratos recíprocos con los mismos nombres, esquema único de datos de puzle y dueño único de hechos, avisos y constantes en lo comprobado.

### Antes de dar el diseño por cerrado
1. Limpieza de E-1…E-4, C-1…C-3 y T-1…T-5 (un lote corto).
2. Decisión tuya sobre el mínimo real del slice (T-3): con los modelos de los puzles el suelo ronda 10,7 min; conviene que el criterio diga «≈ 10–30 min, a medir» o que se añada contenido (opción (a) de la Open Question 10 de 9).
3. Preguntas de alcance y tono: D13-4 (bandeja), silueta de `slot_6`, `VO_G_07`, `CARTA_A`/«La verdad», asimetría Devolver/Asignar, rehacer la elección tras un cierre (P6 OQ 12), tiempo del puzle 2 (medir), `reducir_movimiento` sobre la caja, tamaño y distancia de vista del tablero, fuente de `t_lectura`, D-15 del slice, textos de `VO_G_14_ASG` y de la respiración de la llamada.
4. Faltan por diseñar: 17 (sistema de pistas), 23 (audio), 24 (prompt de interacción), 25 (menú de pausa), 26 (subtítulos), 27 (título), 28 y 30. Los contratos de otros GDDs con ellos están marcados ‡.

---

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:** `flags.json` y `puzzles.json` no existen (los enums de `t4_decision` y `carta_variante` solo se compararon por nombre); los catálogos `D01a`/`D01b` de 7, las reglas 7, 9, 12 y 14b y los Tuning Knobs de 9; unas 28 de las 40 referencias pedidas; Dependencies completas de P4, P5 y P6; el dueño en el registro de `t4_decision`, `carta_variante`, `caja_cN`, `ts_envio` y `pendiente_revelacion` (el Grep no devolvió entradas); reglas, Edge Cases y AC de varios puzles; slice B.1–B.4 y escena 7. NOT SOURCEABLE: `AnimationPlayer`, `SceneTree.paused`, `AudioStreamPlayer`, `Area3D`/Jolt.
