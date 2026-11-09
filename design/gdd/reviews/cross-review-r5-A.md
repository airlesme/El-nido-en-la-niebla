# R5-A informe (perímetro: contratos 8/10/19/20/21 entre sí y con los existentes)

Veredicto de mi perímetro: 0 BLOQUEANTES, 7 AVISOS, varios INFO. Revisado contra textos actuales.

## Pares revisados
| Par | Resultado | Notas |
|---|---|---|
| 8 <-> 20 (otorgar, sostener_item, guardar_item, has_item; dueño tarjeta_B/D) | OK | 8 reglas 8, 22, 23 / 20 R8, R10, R11, R16, R25, AC-04, AC-23. Firmas y devolución ACEPTADA/RECHAZADA idénticas. Idempotencia coincide. |
| 8 <-> 7 (lectores, C08, A05, bloquear_contexto) | OK | 7 filas L231, L242, L243 coinciden con 8 reglas 7, 13, 21; 7 regla 30 cita «8 con la secuencia del lector, ≈1,6 s < 3 s». |
| 8 <-> 2 (HAND_CARD_SWIPE, HAND_DRAWER, objeto_sujeto, colisión) | OK | 2 L110, L302, L393-394 coinciden. |
| 8 <-> 3 (avisos, hechos) | OK | 3 L50-51, L121, L173, L177-178: «puerta abierta», «ascensor llamado», «ascensor rechazado», «línea pedida»(MEGA_03). 8 no escribe hechos. |
| 8 <-> 5 (door_opened, card_acquired, AC-41b) | OK | 5 L60, L63, L471 coinciden con 8 reglas 11-12, AC-02. |
| 8 <-> 4 (door_slot_*, anclaje A05, falla abierto) | OK | 4 L225, L390 (`drawer_slot_a05` propuesto). |
| 8 <-> 18 (OBJ_C06/C07/D06/C08, MEGA_03) | OK | 18 L126-127, L137: 8 único pedidor; 28 entradas. |
| 8 <-> 21 (ascensor llamado/rechazado, MEGA_03, C08) | OK con AVISOS A6, A7 | 21 regla 17 + Dep L196 coinciden con 8 reglas 11, 13-15. Dueño único de «ascensor activo» = 8; enfriamiento único = 8 (21 sin t_ahorro_cooldown_s). |
| 8 <-> 9 (archivo_abierto, SFX_UNLOCK, close_view_after_s) | OK | 8 F2 ejemplo de F4 de 9. |
| 20 <-> 19 (otorgar_sesion, has_item, DOC_I01, I-01 Relegible=No) | OK | 19 R20, R23, R27 / 20 L44, L63, R8, R9, R25, AC-05, AC-05b. |
| 19 -> 9 (compose_i01) | OK | 19 R30 / 9 L274, L444, D9-49, D9-56, D9-59, AC-39/39b. 9 no lee correos_leidos (9 D9-50, 3 L92, DT-16, 19 R15). Único lector = 19. |
| 19 <-> 3 (correos_leidos) | OK | 3 L88-92, L176, L232. |
| 19 <-> 6 (reducir_movimiento) | OK | 6 L42, L95, L226. |
| 10 <-> 9 (play_open(4), set_final_pose(n), get_view_gate, ajar_cm, caja_c1..c4) | OK | 9 L122, L165, L269, L445, L455, AC-03 (ajar_cm solo P5, P6 sin entreabierto, D9-48). Nombres y firmas idénticos. |
| 10 <-> 1 (BOX_OPEN_MAX 1,6 s) | OK | 1 L325 y D25; 10 F2, knobs, registro. |
| 10 <-> 7 (D01d no encadena, SIN_EFECTO C3/C4, bloquear_contexto) | OK | 7 L150, L244, F4 L322 ya aplicados. |
| 10 <-> 20 (I-05/I-06a presentación) | AVISO A2 | R13 de 20 sin ajustar. |
| 10 <-> 4 (ANC_D01*, SPK_D01C, VIS_D01C) | OK | 4 L48 (regla 9 paso 6) lista `ANC_D01A..D`, `SPK_D01C`, `VIS_D01C`. Cambio aplicado. |
| 1 regla 8 (excepción repasar_bolsillo) <-> 7 regla 27(b) | OK | 1 L66, L104-109 / 7 L130-139: Entrada entrega sin guardar; 7 decide ACEPTADA (exploración estable) / APLAZADA (transición o gesto bloqueante, incluido bloquear_contexto de 8, tope 3 s) / RECHAZADA. 7 D7-56 + AC-26e: reposo() antes de HAND_READ con tarjeta sostenida (20 R12). AC-E17 de 1 coincide. Sin contradicción. |
| 1 regla 23 <-> 20 R18-R22 | OK | AC-E15..E17 <-> 20 AC-11/12/12b/14. |
| 21 <-> 1 (traspaso sin control, apertura propia en ESC8_CIERRE, D22) | AVISO A4 | ver abajo. |
| 21 <-> 4 (zonas T-*, recepcion, control_final, fundido propio) | OK | 4 L173, L224, L391 coinciden con 21 reglas 8, 11, 17. |
| 21 <-> 6 (reducir_movimiento) | OK | 6 L96, L227 <-> 21 regla 23. |
| 21 <-> 3 | OK | 3 L51, L121, L178. |
| 21 <-> 19 (cerrar_modos) | AVISO A3 | |

## BLOQUEANTES
Ninguno.

## AVISOS
A1. 20 Dependencies fila «1 Entrada y controles»: «Hoy no existe (ver cambios)» frente a 1 regla 23 (existe), AC-E15..E17 y 20 R18/Cambios fila 1 («Hecho»). Texto obsoleto.
A2. 20 R13 «`I-05`, `I-06a` e `I-07` los muestra 9/10 (nota, lista, carta; slice C.6)» y R8 fila I-06a/I-05/I-07 («La primera aparición en pantalla ... es de 9 y 10») frente a 20 D20-19 («no tienen presentación nueva ... decorado de la caja (10)»), 10 Dependencies fila 20 («no es de 10») y 10 Cambios (a) (pide ajustar R13) y 9 D9-58. R13/R8 no se ajustaron. Riesgo: un programador implementa una presentación que nadie posee.
A3. 19 R7 «`motivo = sistema` (director de escenas 21, p. ej. antes del apagón)» frente a 21 regla 13 (el apagón no cierra modos, DT-2) y regla 20 (`cerrar_modos()` solo en `ESC8_CIERRE`, en Recepción, donde no hay ordenador). El ejemplo es falso. Además 19 Dep fila 21 «Blanda» y 21 Dep L198 «9 · 19 · 20: Sin dependencia»: clasificación asimétrica (el contrato real es 21->7, 19 solo recibe on_close(sistema)).
A4. D22 «absorber el `sin control` ajeno»: 1 regla 6/L64/AC-E13c/OQ 17 y 4 regla 9 lo recogen como propuesta pendiente («Antes de implementar 21»), pero 21 PA-2 y Cambios (1b) siguen describiéndolo como hueco («no está cubierto ... propone a 1 una»), AC-21-23b «diferido», y 21 regla 11(b) no nombra ningún aviso al descartar [`sin control`(21), `menú`] mientras 1 L64 dice «un aviso». Tres GDDs con estados de decisión distintos de lo mismo. Compatibilidad funcional OK (21 solo cancela líneas y no emite operaciones de pila, 11b; 1 hace la absorción), pero al cerrar D22 hay que actualizar 21 PA-2/Cambios y fijar el aviso.
A5. Nomenclatura de la acción: 1, 20 y 9 L546 usan `repasar_bolsillo`; 7 (L130, L257, D7-59, D7-60) y 9 (L251, L380, regla 35) usan «repasar bolsillo» / «acción». Mismo concepto; unificar el identificador en 7 para evitar dos acciones en la implementación.
A6. 8 regla 14: «7 reserva HAND_REACH, 0,5 s, antes, lo que cubre el hueco de un fotograma hasta que 21 toma el `sin control`». Según 4 (L224, fila de pila) quien toma `sin control` en «carga iniciada» es 4 y 21 lo recibe por traspaso en «terminada» (21 regla 8a, F5). No hay hueco de un fotograma: el contexto lo tiene 4 desde el inicio de la carga. Texto impreciso (y la cita «traspaso de 12,0 s† de 21, F4» debería ser F5; F4 de 21 es «Esperas con tope»; el valor 12,0 s es 21 F5 `M_traspaso`).
A7. 8 Dependencies L202 y L197 («21 lista hoy a 8 como "Sin dependencia directa": debe pasar a Blanda»; «21 regla 17 (a corregir, D8-13)») y 8 Cambios fila 21/3/4/7: ya aplicados en 21 (regla 17, Dep L196), 3 (L50-51), 4 (L225, L390), 7 (L242-243). Texto de 8 obsoleto; 21 Dep L196 cita «línea 163 de 8» (referencia por línea, frágil; 8 la tiene en L197).

## INFO
- 21 Dep L196 «ESC8_ASCENSOR, 7,0 s» frente a catálogo `t_fin` = 6,0: 7,0 es `duracion_declarada` (F2), no incoherente pero confuso.
- 8 F4: `t_en_uso_tope_s` 20,0 s > `M_traspaso` 12,0 s (21 F5: 12,04 s) coherente; 21 F5 da `D_carga` ≈ 11,67 s.
- 20 R9 (vacía sesión al descargar planta) y 19 R25 («la hoja no desaparece al cambiar de escena»): irrelevante en el slice (único cambio es planta->recepcion, final).
- 10 Knobs `BOX_C3_OPEN` 1,4 s† sin fuente en el slice (declarado †).
- Hechos/avisos con dueño único comprobados: `tarjeta_B/D` 20; `formulario_leido` 20; `correos_leidos` 19; `caja_c1..c4` 9; `caja_completa` derivado de 3 (8, 10, 21 solo leen); `llamada_completada` 22; «ascensor llamado» emisor 8 / receptor 21; «ascensor rechazado» emisor 21 / receptor 8; `MEGA_03` pedidor único 8 (18 L137; 21 regla 17); `atraccion_desactivada`: no revisado (ver NO LEÍDO). Estado `LISTO` del lector (8 regla 7) y `LISTO` del ascensor (regla 13) usan el mismo nombre en dos máquinas distintas (lector/ascensor): sin colisión, sí cuidado en implementación; 4 usa «Listo» (estado de la escena) como condición de rechazo de `recepcion`: homónimo, no el mismo estado.
- Referencias «regla N / AC-N» muestreadas (válidas): 8 reglas 8, 11, 13-15, 21-23, F1-F4; 8 AC-02, AC-09, AC-10, AC-13; 8->20 R8, R11, R12, R16, AC-04; 8->2 reglas 21 y 24; 8->3 CA-03; 8->5 D-24, D-29, AC-41b, regla 6; 8->7 reglas 3, 12, 26, 30; 20->7 reglas 12, 13, 18, 27(b), 29; 20->1 regla 23, AC-E15..E17; 20->9 reglas 34, 35, AC-39b; 19->9 reglas 7, 34, 35; 19->3; 19->7 reglas 20-24; 10->9 reglas 8, 16.6, 35, AC-03; 10->1 F8; 21->8 AC-09/10; 21->1 reglas 6, 7, F8; 21->4 reglas 5, 7, 9, 11, 13-16; 21->3 reglas 2, 4, 9, 10; 1->20 R18-R22; 9->19 R23, R27, R30. Nota: «regla 27b» de 7 es en realidad el apartado (b) de la regla 27 (7 L130); consistente en todos los citantes. «AC-41b de 5» marca NOT ASSESSED por diseño. No se encontró ninguna referencia rota en las ~45 comprobadas.

## NO LEÍDO
- Edge Cases y Acceptance Criteria completos de 8 (solo AC-02, 09, 10, 13), 10, 19, 20 y 21 (solo AC-21-01..05).
- 21 reglas de Edge Cases y AC-21-23b/28; 4 reglas 7, 9, 13, 14, 18 (solo greps); 4 y 10: anclajes `ANC_D01A..D`, `SPK_D01C`, `VIS_D01C` (Cambios de 10 a 4) no verificados.
- 2 completo (solo líneas citadas por grep); 5 completo (solo greps); 6 completo; 18 completo (solo greps); 9 completo (solo greps y líneas de contrato).
- `atraccion_desactivada`, `ajar_cm` en 4, `design/registry/entities.yaml`, `systems-index.md` (excepto L286), slice-v0.3.md, y los 4 informes previos.
- 10: reglas 1-36 (Detailed Rules A-H) y F1-F6 no leídas salvo F2 y knobs.
- 19: Edge Cases, Formulas, AC. 20: Formulas F1/F2, Edge Cases, AC (salvo 04, 05, 14, 23).
