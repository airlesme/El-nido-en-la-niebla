# Review F2b-dep (final). Perímetro 2a, 2c.

## 1. Pares: 85 (recuento propio: 83 con dependencia declarada + 2 «ninguna» explícitas 3-6 y 5-6)
CERRADOS (verificado en ambos lados + índice): 22<->1 Dura (22 L183, 1 L396, índice f22); 1<->6 sin ciclo duro (1 L393 Blanda, 6 L228 Blanda, índice L189); 22<->7 Dura no circular (22 L197, 7 L430, índice L189); 2 lista 9 Blanda y 10 Indirecta (2 L301-302); 9 lista 22 Indirecta (9 L478); índice f21 con 10; índice f20 sin contradicción (coincide con 20 L206-220, 1 L395, 8 L192, 19 L187, 9 L463, 10 L197, 21 L200, 5 L331); sin restos de «22 sin GDD/pendiente» en 1, 3, 5, 7, 8, 18 (solo en changelogs/«antes»).
Resto de pares (3, 4, 5, 7, 8, 9, 10, 18, 19, 20, 21, 2, 1): dureza idéntica en ambos lados.

## BLOQUEANTE: ninguno.

## AVISO (discrepancias que quedan o nuevas)
- AV-1 (8<->22): 8 L198 declara Indirecta (vía 3) y dice «22 la repite»; 22 L190 «Blanda (la declara 8 en el índice)»; índice f8 «blandas ... 22» y f22 «8 (blanda, la declara 8)». Manda 8: corregir 22 L190 y las dos filas del índice (y f8 L117). 8 L202 también dice que 22 lista a 8 como Indirecta: falso hoy.
- AV-2 (21<->22): 21 L192 declara 22 «Indirecta (vía 3)» y dice que 22 repite «sin dependencia directa»; 22 L189 «Sin dependencia directa»; índice f21 «sin dependencia 22», f22 «sin dependencia 4, 6, 21», L190. 21 L203 («21 no depende de 22») contradice su propia fila. Decidir y unificar (lo coherente con 21 L203 e índice es «sin dependencia/por el bus»: corregir 21 L192).
- AV-3 (1<->6 en índice): f6 «1 (dura de contrato: 6 → 1...)» frente a 6 L228 y 1 L393 (Blanda); 6 L209 abre con «dura en cuanto a contrato» y sigue «dependencia blanda»; 6 L232 admite que el índice dice «dura de contrato». Manda 6: índice a «blanda».
- AV-4: índice f9 «dependen de 9: 8, 21, 10, 11–16 y 17» omite 22, pese a 9 L481 («Dependientes: ... 22 (indirecta, la declara 22)»).
- AV-5 (obsoleto): 22 L179 («el índice anota 1 como Blanda; cambios nº 2c y 9») y L183 («1 la anota hoy Blanda ... debe pasar a Dura (cambio nº 2c)»): 1 y el índice ya dicen Dura.
- AV-6 (obsoleto): 21 L181 «Dependencias del índice: 1, 3, 4, 18 (duras) y 5 (blanda). Este GDD añade 7 ... propone reflejarlo en el índice»: el índice ya trae blandas 5, 6, 7, 8 e indirectas 2, 9, 10, 20.
- AV-7 (obsoleto): 10 L202 «2 no lista a 10»: 2 L302 sí lo lista (Indirecta).
- AV-8 (registro vs GDD): entities.yaml `t_corte_senal_s` range [0, 0.5] (L1688) frente a 22 L211 «0,1–0,6».

## INFO
- Índice f2 «dependen de 2» omite 8, 21, 4 (los declaran 8 L196, 21 L191, 4 L224; las filas de 8 y 21 sí listan a 2).
- 3 L187 («Las durezas...: 4, 5, 8, 9, 10, 19, 20 y 21 → dura») omite 22; la tabla L179 sí lo trae Dura.
- 18 L209/L228 dicen que 3 lista a 18; la tabla de 3 no tiene fila 18 (y 18 L207 declara no depender de 3). Par sin relación: solo redacción.
- Legítimos: 21 L338 «(por redactar)» 23/28/27/25; 6 L229 24 «sin GDD aún»; 20 L215 17 «sin GDD»; 8 L219 28 «sin GDD»; 5 L337 27 y 25.
- El slice vigente es design/slice/slice-v0.3.md (cabecera con versiones hasta 0.4.2, L1012); no existe slice-v0.4.2.md como fichero.

## 2. Textos obsoletos (Grep en 15 GDDs, slice, game-concept, registro)
- «sin GDD», «por redactar», «pendiente de redactarse», «a corregir», «Hoy no existe»: solo en changelogs/decisiones (D8-25, D18-25, D20-22, 3 L330/L346, 5 L564/568, etc.) o sobre sistemas realmente sin GDD. Sin restos operativos sobre 22.
- `BOX_Cn_OPEN`: GDD 10 L62-L338 (notación genérica/«sustituida por»), 6 L404, 21 solo lista C1..C4, registro L512-519 `status: deprecated` «SUSTITUIDA». Conforme. (10 L128 y 10 L430 la usan como «notación genérica» explícita.)
- «19 hechos»: solo 5 L541, L542, L564 (históricos/«→ 20»). Conforme (5 L542 podría matizarse, INFO).
- «25–30 min»: solo en negación («no se afirma 25–30 min»: game-concept L110, slice L6) y en changelogs de 9 (L380, L729, L732, L748). Conforme.
- «repasar bolsillo» sin guion bajo: 18 L378 (D18-26, cita de la alternativa descartada), index L286 y 2 L497 (en comillas «repasar bolsillo» junto a `repasar_bolsillo`, texto de decisión). INFO/AVISO bajo.

## 3. Referencias muestreadas: ≈70, 0 fallos
Reglas: 1 R6, R8, R23; 21 R4, R5, R6, R9, R11, R13, R14, R15, R17, R20, R23; 7 R3, R19, R23, R27, R29, R30; 9 R7, R8, R16, R17, R20, R24, R25, R27, R29, R35; 18 R5, R16, R20, R22, R23; 5 R10, R11, R12, R28, R29; 3 R4, R7, R9, R10, R13, R14; 8 R13, R14, R15; 22 R1, R3, R6, R14, R17, R19, R23, R27-R30, R33.
AC/D/PA: AC-34 (5), AC-22-18/29/31, AC-E15/16/17, AC-V8, AC-03/17/39/39b/49/X5 (9); D22-1/5/9/10/19, D18-10/21, D9-33/55/64, D7-62, D-43 (2), PA-7/DT-12/DT-27 (21). Todas existen y dicen lo citado (semántica comprobada en el título de la regla).

## 4. Recuentos
- §12: 28 entradas = 21 audibles (3 megafonía) + 7 documento (slice L328; 18 L270, L273). OK.
- 20 hechos (slice L1051, L1106; 3, 5, 8, 21 coinciden). OK.
- 8 `PISTA_*`: P1_N2, P2_N1, P4_N1, P4_N3, P5_N1, P5_N2, P6_N1, P6_N2 (18 L100-117; registro L807, hint_key_count 8); sin PISTA_P6_N3. OK.
- Registro: 168 `name:`; sin repetidos. Bloque de la llamada L1622-1747: 14 entradas (t_sil_s, t_resp_s, t_ante_s, t_guarda_opciones_s, t_espera_s, t_cierre_s, t_corte_senal_s, t_putdown_s, call_timeline_s, v02_state, call_input_context, call_state, state_notices_call, call_content_ids) más line_grace_s preexistente (L938) y t_espera_voz_s (L1465, distinto de t_espera_s). Valores coinciden con 22 salvo AV-8. INFO: son 14, no 13 (si «13» no cuenta v02_state o state_notices_call, aclararlo).

## NO LEÍDO
Tuning Knobs, Acceptance Criteria, Formulas y Detailed Rules completos de los 15 GDDs (solo Dependencies y grep dirigido); tablas «Interacciones con otros sistemas» de cada GDD; slice-v0.3.md (solo grep); game-concept.md (solo grep); índice L97-146 y L286-320 (solo grep); registro entero (solo nombres y el bloque de 22, BOX_Cn_OPEN, hint_key_count); AC-27/27b y F4 de 7, regla 2 de 22, regla 12 de 21 (citadas pero no abiertas); GDDs 23-30 y 11-17 (no existen).
