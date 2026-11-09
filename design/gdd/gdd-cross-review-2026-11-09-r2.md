# Cross-GDD Review Report (ronda 2 de revisión)

**Fecha:** 2026-11-09 · **Veredicto: FAIL** (2 bloqueantes; antes 8) · **Modo:** autonomous, workflow standard · **Focus:** full
Informe anterior: `gdd-cross-review-2026-11-09.md`. Sufijo `-r2` porque la fecha ya existía y el orden léxico debe seguir siendo cronológico.

- **GDDs reviewed:** 9 of 9 present (1, 2, 3, 4, 5, 6, 7, 9, 18). **Not read (completos):** ninguno de forma total, pero la cobertura es parcial: ver «Cobertura».
- **Desviación del procedimiento:** el skill pide pasar el contenido de los GDDs pegado a los subagentes; con ~680 KB no cabe, así que cuatro revisores independientes leyeron por secciones. A, B y D agotaron su límite de turnos una vez y se reanudaron para volcar lo comprobado. Ninguno releyó el trabajo del autor sin contexto propio.
- **Revisores:** A (cierre de bloqueantes anteriores y reciprocidad), B (constantes, fórmulas, ACs, referencias), C (diseño y pilares), D (siete escenarios).
- **Decisiones del usuario respetadas** (no son hallazgos): las del informe anterior más D-B1 (T4 acepta devolver o asignar con `t4_decision`) y D-B2 (`VO_G_13B` = «Lo sé»).

## Estado de los bloqueantes anteriores

| Bloqueante | Estado | Quién lo verificó |
|---|---|---|
| C-B1 (2↔7 transformada, `t_mano_s`, manos) | **CERRADO** | A, B (valores del registro), D (E2) |
| C-B2 (3↔5 `notices_dropped`) | **CERRADO** en 3 y 5 · el valor `save_causes` del registro quedó desfasado (B-2, aviso) | A, B |
| C-B3 (7↔9 `habilitado_si` de `C05`) | **CERRADO** | A |
| C-B4 (1↔4 `sin control` de la carga) | **PARCIAL**: traspaso, duración y reinicio de pila cerrados; queda la carga desde el título con `control_final = ninguno` (N-B1) | A, D |
| D-B1 (P4 «Devolver» obligatorio) | **CERRADO** (T4 acepta ambas; sin «No corresponde» en T4) | C |
| D-B2 (`VO_G_13B`) | **CERRADO**; `VO_G_13A/C/D` y `VO_G_14_RET` tampoco confirman la intención | C |
| S-B1 (emisor de «partida terminada») | **CERRADO** (4, única fuente, en «terminada» de `recepcion`) | A, D |
| S-W1, S-W2, S-W3, S-W4, S-W7, S-W8 | **CERRADOS** a nivel de texto | A, D |

---

## Consistency Issues

### Blocking

🔴 **N-B1 · 1↔4↔5 (y 21) · `control_final` de `partida_nueva` y pila bajo el `sin control`.** *(Hallado por A como bloqueante y por D como E4-1.)*
- 4 regla 7: `partida_nueva` usa `control_final = ninguno`. 1 regla 6 (carga desde el título): pila [`menú`, `sin control`]. Al terminar con éxito, «el 4 pide `exploración` y la pila queda [`exploración`]», pero esa operación solo está definida para el 4 con `control_final = exploracion` (caso de «Continuar», 5 regla 18). 5 regla 24 no fija el `control_final` de «Nueva partida». AC-E2 y AC-E13 solo prueban `exploracion`.
- Con `ninguno` el 21 *traspasa* y la pila sigue [`menú`, `sin control`(21)]. Al cerrar su `sin control`, Entrada restaura `menú` (el título) en mitad de la partida, o hace falta una operación no definida.
- Además hay dos modelos de pila para `partida_nueva` según se llame desde el título o desde la planta (4 regla 9 paso 3), sin AC que los distinga.
- Opciones: (a) 1 regla 6 admite «pedir `exploración`» al dueño del `sin control` superior, incluido el 21 tras el traspaso, y descarta lo de debajo (arreglo mínimo, recomendado); (b) 5 regla 24 fija `control_final = exploracion` y el 21 ya no controla la escena 1; (c) el traspaso desde el título descarta el `menú`. En cualquier caso, un AC de 1 y otro de 4 que lo prueben desde [`menú`, `sin control`].

🔴 **B-1 · 7↔9↔1 · Separación mínima de elementos de vista: tres severidades para el mismo dato.**
- 7 regla 22 / AC-30: advertencia en desarrollo (R₁+R₂ con el R por elemento de Entrada F5b, con excepción «atracción desactivada en esa zona»). 9 regla 29 / AC-47: fallo de arranque, y en la build final fallo de carga y puerta de CI que bloquea el empaquetado, sin la excepción. Entrada Open Question 3: solo recomienda separar más de 16 px.
- La tolerancia depende de `asistencia_encaje` (88 px normal, 220 px asistida; R = 128). Ningún GDD dice con cuál valida 9 al arrancar. Con la asistida cualquier par a < 256 px rompe la build; con la normal el modo asistido queda sin comprobar.
- 9 AC-35 sigue diciendo «2·R»; 7 Edge Cases (l. 383) describe el desempate por la dirección del stick, que en F5b solo desempata a igual distancia.
- Opciones: (a) 9 valida con la tolerancia asistida (peor caso, R=128 → 256 px), como advertencia en desarrollo y fallo solo si no hay excepción de atracción; (b) valida con la normal y 7 declara el modo asistido como no garantizado. Corregir además AC-35, 7 l. 383 y la Open Question 3.

### Warnings

⚠️ **B-2 · Registro.** `entities.yaml:746` (`save_causes`) lista 10 causas más `dev`; 5 regla 6 lista 11 (con `notices_dropped`). Falta rellenar `revised`.
⚠️ **B-3 · «20 hechos».** El slice D.2 ya dice 20 y el registro lista 20 nombres, pero 3 (regla 1: «los 19 de D.2»; CA-01: «los 19 de D.2 más `t4_decision`» = 21; l. 87 y 215), 5 (l. 382), 9 (Open Question 9), el índice (l. 274) y la nota del registro (l. 739) siguen diciendo que el slice no lo recoge. `assets/data/` sigue vacío: no hay `flags.json` con el que contrastar.
⚠️ **B-4 · Tope de 3 s de Entrada (F8).** Su rango seguro es 1–5 s, pero la cadena de `D01a` de 7 (1,6 + hasta 1,2 = 2,8 s) solo cabe con el tope por defecto: margen de 0,2 s, y con 1 s Entrada libera antes de «cámara cedida». 7 F4 acota por tramo, no con el tope único. `BOX_Cn_OPEN` no está registrado.
⚠️ **N-W1 · Índice.** `systems-index.md` l. 255 todavía presenta al 22 como «candidato» a emitir «partida terminada».
⚠️ **N-W2 · Listas de pendientes.** Entrada l. 380 (índice) y l. 358 pueden estar obsoletas (C-W9).
⚠️ **N-W3 · Referencias parciales.** 11 de 34 referencias muestreadas solo se verificaron en parte; entre ellas «regla 18 de 5» (4 regla 14), «AC-15a» (4 AC-23), «regla 21 de 18» y «regla 19 de 7» (Entrada regla 8). Tres con ERROR confirmado: 9 AC-35, 3 CA-01, 7 l. 383 (cubiertas arriba).
⚠️ **N-W5 · 7 l. 313** dice que `t_vista_salida_s` «se retiró del registro»; sigue como `deprecated`. Impreciso, no contradictorio. Igualmente, 4 l. 228 (4b) aún dice «pendiente en 18» aunque 18 ya está corregida (D18-11).
⚠️ **E1-2 · 7 regla 21** conserva el ejemplo «pausa que cierra la vista», que contradice a Entrada (l. 321) y a 9 reglas 11b y 18. Errata: sustituir por «pausa, `atrás`, pérdida de foco».
⚠️ **C-W6, C-W7 (parte), C-W8 (parte).** No re-verificados esta ronda (ver Cobertura): nombres `multiplicador_pie`/`pie_persistente`/`alternar` en 6, `get_view_gate` en la fila `D01a` de 7, y el conteo de claves `PISTA_*` de 18 frente a 9.

---

## Game Design Issues

*Fase 3 (revisor C): CONCERNS, 0 bloqueantes. Adaptada al género (sin combate, XP ni economía).*

### Blocking
Ninguno. D-B1 y D-B2 comprobados como cerrados.

### Warnings

⚠️ **D-W9 · `VO_G_14_ASG`** («Sigo aquí. La carta a Dirección ya va firmada.») no confirma intención, pero casi responde a «¿quién firmó?», que el pilar 5 prohíbe resolver. Suena igual en las 9 combinaciones de selectores y con algunos responsables se lee de forma incoherente. Ya está pendiente de narrative-director: medirla también contra el pilar 5.
⚠️ **D-W10 · La elección de T4 apenas se percibe como elección.** La regla visible del tablero empuja a «Devolver»; T4 lleva los mismos sellos que las fichas de solución única; queda fija al primer gesto completo; su único efecto solo se oye tras 20 s de silencio en la llamada, y quien devolvió oye la misma línea que antes.
⚠️ **D-W11 · Tiempos.** F7 del marco (P1 2–4 min, P2 3–6, P4 2–4) contradice «ninguno requiere más de dos minutos» (slice §22, concepto). Con escenas, la llamada y Recepción el slice probablemente pasa de 30 min.
⚠️ **D-W1…D-W8 vigentes:** D-W1 (parcial: T4 ya no se puede forzar; el Edge Case sigue siendo falso para P1 y T1–T3), D-W2, D-W3, D-W4, D-W5 (solo en el texto de N2; sin reabrir los dos niveles), D-W7, D-W8. **D-W6 cerrado** por la decisión de la llamada repetible.

*INFO:* ningún momento supera 4 sistemas con atención simultánea; pilares alineados; sin bucles de progresión en competencia; sin estrategias dominantes nuevas.

---

## Cross-System Scenario Issues

**Scenarios walked:** 7 (E1, E2, E4 completos a nivel de texto; E3, E5, E7 parciales; E6 no completado). Revisor D.

### Blockers
Ninguno firme. E4-1 es el mismo hallazgo que N-B1 (arriba).

### Warnings
⚠️ **E1-1 (S-W5, sigue abierto) · 9, 23.** Si la voz de 23 no se pausa con `SceneTree.paused`, `VO_G_07` sigue sonando con el menú abierto y la imagen se corta al reanudar. *NOT SOURCEABLE* (`SceneTree.paused`/`AudioStreamPlayer` no están cubiertos por `docs/engine-reference/`); 23 no tiene GDD. Requisito a escribir en 23.
⚠️ **E5-1 · 6, 23, 28.** Sin contrato sobre si cambiar `reducir_sobresaltos` en pausa atenúa el parpadeo *en curso* o solo el siguiente (fotosensibilidad: debería atenuar al reanudar). 28 sin GDD.
⚠️ **E5-2 · 3, 6.** El aviso de Ajustes va fuera del bus sin contrato de baja automática de suscriptores al descargar la planta.
⚠️ **E6-1 · 5 regla 11.** `respuesta_llamada` y `llamada_completada` nunca se guardan: tras un cierre la llamada se rehace entera. Confirmar que la carta permanente (D-14) depende solo de hechos que sí se guardan; «respuesta repetible» choca además con que `respuesta_llamada` sea de un solo sentido (3 regla 4).
⚠️ **E7-1 · 4, 5, 27.** Sin aviso con nombre que dispare la re-inspección de 5 al volver al título (5 regla 17).
⚠️ **E7-2 · 5 regla 29.** Si `slice_completed` falla al escribirse, el título ofrece «Continuar» (llamada pendiente) a quien ya terminó el slice. Aceptado por 5; documentar como caso de playtest.

*INFO:* E1-3b (3 regla 16a depende de que 3 conozca los avisos de carga de 4: escribirlo); E2-1 (relectura desde el bolsillo rechazada ≤ 0,5 s con lectura aplazada pendiente); E2-2 (`HAND_REACH` derecha y objeto a la izquierda: validar en arte); E3-1 (falta fila «Sellando» tras `slice_completed` en la tabla de estados de 5); E4-3, E4-4, E7-3 (27 sin GDD); coherencia numérica confirmada: `D_carga` 11,667 s con tope 13,667 s, `partida_nueva` 14,87 s, traspaso en t = 9 con 20 s → 31 s, F5b 88/220 px, `t_mano_s` 0,4 s con dueño 2.

---

## GDDs Flagged for Revision

| GDD | Motivo | Tipo | Prioridad |
|---|---|---|---|
| entrada-y-controles.md (1) | N-B1 (operación «pedir `exploración`» tras traspaso; ACs), B-4, OQ 3 | Consistency | Blocking |
| escena-de-planta.md (4) | N-B1 (dos modelos de pila para `partida_nueva`), errata l. 228 | Consistency | Blocking |
| guardado-y-carga.md (5) | N-B1 (`control_final` de `partida_nueva`), B-2, B-3, E3-1, E7-1 | Consistency | Blocking |
| marco-de-puzles.md (9) | B-1 (severidad y tolerancia), AC-35, B-3 | Consistency | Blocking |
| interaccion-e-inspeccion.md (7) | B-1 (l. 383, regla 22), B-4 (F4), regla 21 | Consistency | Warning |
| estado-y-bus-de-eventos.md (3) | B-3 (regla 1, CA-01), E1-3b | Consistency | Warning |
| base-de-contenido-narrativo.md (18) | D-W9, D-W10 (líneas de T4) | Design Theory | Warning |
| systems-index.md · entities.yaml | N-W1, B-2, B-3 | Consistency | Warning |

Estados del índice: ya figuran «Needs Revision» desde el informe anterior; no se tocan.

---

## Verdict: FAIL

2 bloqueantes (N-B1, B-1) más advertencias. Ambos son localizados y de arreglo corto; ningún bloqueante anterior sigue abierto salvo C-B4, y solo en su último tramo.

### Required actions before re-running
1. **N-B1:** decidir la opción (a) y escribirla en 1 regla 6; ajustar 4 regla 9/7 y 5 regla 24; añadir los ACs desde [`menú`, `sin control`].
2. **B-1:** fijar severidad y tolerancia de referencia de la separación (recomendado: opción a); corregir 9 AC-35, 7 regla 22 y l. 383, y Entrada Open Question 3.
3. Limpiezas baratas: B-2, B-3 (19 → 20 hechos en 3, 5, 9, índice y registro), N-W1, B-4 (rango de F8 y `BOX_Cn_OPEN`), errata de 7 regla 21 y de 4 l. 228.
4. Re-ejecutar `/review-all-gdds since-last-review` y cubrir lo que no se leyó.

---

## Cobertura (qué no se pudo revisar)

**NOT ASSESSED** (el FAIL no depende de esto; una re-ejecución debe cubrirlo):
- **Sin leer por ningún revisor:** `ajustes-persistentes.md` (6) casi entero (Tuning Knobs, C-W6, regla 7, ACs y Edge Cases); `base-de-contenido-narrativo.md` (18) salvo D18-10/D18-11 (conteo de claves `PISTA_*`, C-W8); `game-concept.md` y `game-pillars.md` solo por C; ACs de 4 (AC-36, AC-38c) y de 5 (AC-18b).
- **Parciales:** de 9 solo `C05`, reglas 29 y 14, Tuning Knobs y fragmentos; de 7 la tabla de objetos, Edge Cases y Visual/Audio; de 3 la regla 10 completa y la 16; de 5 las reglas 7a, 11, 17, 18 y F2; de 2 las reglas 4, 18 y 24, F9 y ACs; de 1 las reglas 13–16 y F1–F4; de 4 la regla 9 entera, F1/F2 y AC-15a.
- **Valores del registro:** B contrastó los de `t_mano_s`, `lock_max_s`, `close_view_after_s`, `D_carga`, `t_periodico`, `dz_in`, `R_max_elem_px` y otras; sin contrastar `volume_*`, `rotate_mouse_gain`, `player_*`, `snap_radius_m_P3`, `tol_deg_P5`, `hint_key_count`.
- **E6 (llamada) no recorrido** (22 sin GDD). E5 y E7 parciales. No existen GDDs de 8, 10–16, 19–28, 30.
- **IDs de decisión citados** (D-19, D-30, D7-xx, D9-xx…): no verificados uno a uno.
- **NOT SOURCEABLE:** `SceneTree.paused`, `AudioStreamPlayer`, `Tween`, `Area3D`/Jolt (S-W5, AC-09 de 2 y AC-05a/b de 4).
- Referencias «regla N / AC-N» muestreadas: 34 de ≥ 40 pedidas (20 OK, 3 ERROR, 11 parciales).
