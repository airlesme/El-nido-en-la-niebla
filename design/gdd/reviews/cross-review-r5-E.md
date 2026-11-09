# Review R5-E (borrador 1) — reciprocidad 2a y textos obsoletos 4

## Tabla de pares (hardness: lado A declara / lado B declara / índice)
| Par | A dice | B dice | Índice | Veredicto |
|---|---|---|---|---|
| 1↔3 | 1: blanda | 3: blanda | 1 «— (blandas 3,4,18)» | OK |
| 1↔4 | 1: blanda | 4: blanda | fila 4 «blandas: 1» | OK |
| 1↔19 | 1 tabla: 19 «Blanda» | 19: 1 «Dura» | fila 19 lista 1 sin «blanda» (dura) | AVISO dureza |
| 1↔20 | 1 tabla: 20 «Dura (de 20 hacia 1)» | 20 fila 1: «Blanda» | fila 20 «blandas: 1» | AVISO dureza (1 es el discrepante) |
| 1↔21 | 1 tabla: 21 «Blanda» | 21 fila 1: «Dura» | fila 21 lista 1 como dura | AVISO dureza |
| 1↔6 | 1: 6 «Dura» (aguas abajo), 6 es dependiente | 6: 1 «dura en cuanto a contrato» | fila 6 «1» | OK |
| 1↔10 | 10 lista 1 «Dura (indirecta)» | 1 NO lista a 10 | fila 10 «indirectas: 1» | AVISO (10 declara, 1 no; etiqueta «Dura (indirecta)» incoherente) |
| 1↔8 | ninguno se lista | ninguno | fila 8 no lista 1 | OK (indirecta vía 7) |
| 2↔4 | 2: dura ambos sentidos | 4: dura ambos sentidos | fila 2 «1,4»; fila 4 «2 (dura)» | OK; 4 L232 dice «El GDD 2 todavía figura con el 4 como Blanda» → OBSOLETO (2 ya dice Dura) |
| 2↔7 | 2: 7 Dura | 7: 2 Dura | OK | OK |
| 2↔8 | 2: Blanda | 8: Blanda | fila 8 blandas 2 | OK |
| 2↔19/20 | Blanda | Blanda | blandas 2 | OK |
| 2↔10 | 10 lista 2 «Blanda (indirecta)» | 2 no lista a 10 | indirectas | INFO |
| 3↔4 | dura | dura | OK | OK |
| 3↔7 | blanda | blanda | fila 7 «(blanda: 3)» | OK |
| 3↔8 | dura | dura | fila 8 «3» | OK |
| 3↔9 | dura | dura | OK | OK |
| 3↔10 | dura | dura | OK | OK |
| 3↔19 | dura | dura | OK | OK |
| 3↔20 | dura | dura | OK | OK |
| 3↔21 | dura | dura | OK | OK |
| 4↔5 | dura | dura | OK | OK |
| 4↔8 | dura | dura | OK | OK |
| 4↔19 | 19: 4 «Dura» | 4 tabla aguas abajo NO lista a 19 (lista «9·10·20», 8, 21…) | fila 19 «4» | AVISO reciprocidad (falta 19 en 4 Dependencies) |
| 4↔21 | dura | dura | OK | OK |
| 4↔10 | 10: dura | 4: «9 · 10 · 20 Dura (vía contenedores)» | OK | OK |
| 5↔8 | blanda | blanda | OK | OK |
| 5↔21 | blanda | blanda | OK | OK |
| 5↔20 | 5: «8·9 a 16·20 Blanda» | 20: «Indirecta» | — | INFO |
| 5↔10 | 5: «9 a 16 Blanda» | 10: Blanda | índice indirecta 5 | INFO |
| 6↔7,9,2,4,19,21 | todas blanda/blanda | | | OK |
| 7↔8,9,10,19,20 | 7 duras | 8,9,10,19,20 dura | OK | OK |
| 7↔21 | blanda | blanda | OK | OK |
| 8↔20 | dura (8→20) | dura recíproca | ambos índices | OK |
| 8↔21 | 8: blanda | 21: blanda | blandas 21/8 | OK; pero 8 L202 dice «21 lista hoy a 8 como Sin dependencia directa: debe pasar a Blanda» → OBSOLETO (21 ya dice Blanda) |
| 8↔9 | 8: blanda | 9: blanda | OK | 8 L202 aún dice «9 … Indirecta» → obsoleto menor |
| 9↔10 | dura ↔ dura (recíproca) | | fila 10 lista 9; fila 9 NO lista 10 | AVISO: dependencia dura circular 9↔10 declarada y fila 9 del índice sin 10 (el propio 9 L464 lo pide) |
| 9→19 | 9: dura | 19: dura (9→19) | fila 9 NO lista 19; fila 19 no lista 9 | AVISO índice (9 L464 «debe listar 19 duras») |
| 9↔20 | blanda | blanda | OK | OK |
| 19↔20 | dura | dura | OK | OK |
| 20↔10 | 10: 20 Blanda | 20 NO tiene fila 10 (10 lo admite: «falta fila de 10») | fila 20 sin 10 | AVISO |
| 18↔todos | 18 L206: «1,2,4,5,6,7 y 9 ya tienen GDD» | | | OBSOLETO (también 8,10,19,20,21) |

## Textos obsoletos («sin GDD» cuando existe) — apartado 4
- 3 Dependencies L189: correcto (lista 8,10,19,20,21 como existentes).
- 1 L405: «Los sistemas sin GDD (19, 21, 22, 24, 25, 27, 30…) deben listarla» → 19 y 21 YA tienen GDD. AVISO.
- 2 L339: «19, 20, 22 y 23 lo harán al diseñarse» → 19 y 20 existen. AVISO.
- 4 L241: «Los demás (2, 5, 8, 9, 10, 20, 21, 23, 27, 28) no tienen GDD» → 2,5,8,9,10,20,21 existen. AVISO.
- 4 L232: «El GDD 2 todavía figura con el 4 como Blanda» → falso hoy (2 L298 dice Dura). AVISO.
- 5 L333: «Pendientes: 27, 25, 22, 21 …» → 21 existe. AVISO/INFO.
- 6 L234: «Los demás (23,24,25,26,27,28,30) aún no tienen GDD» → correcto en lo nombrado; pero «Existen» lista omite 8,10,19,20,21 que SÍ leen/consumen ajustes (6 sí los lista en tabla: 19, 21; falta 8/10 no aplica). OK.
- 7 L435: «Ningún otro sistema tiene GDD aún» → 8,10,19,20,21 existen. AVISO.
- 18 L206 y L225: «Estado real: 1,2,4,5,6,7,9 ya tienen GDD…; los que aún no existen deben listarlo» → faltan 8,10,19,20,21. AVISO.
- 9 L464: «Los GDD de 10 a 17 deben listar al 9»: 10 ya existe y lo lista. INFO.
- Índice de sistemas: filas 2–5 siguen «pendiente de re-review» mientras 1, 6, 7, 9 dicen «ronda 5». INFO.

## Hallazgos de contenido (2b/2f)
### BLOQUEANTE
- Ninguno.
### AVISO
- A1 (2b, 5 vs 5/4): guardado R18 paso 3 («Si el paso (3) falla … «Continuar» sigue disponible (sin re-inspección: nada ha cambiado en disco)») y R24 («Si la carga falla … vuelve a «Sin partida» sin re-inspección») contradicen R17 («…también tras un fallo de carga cuando el jugador acepta «Volver al título»»), R29, AC-18g y 4 R14.5/R15 (4 emite «descarga total completada» tras «Volver al título» de CUALQUIER fallo, también de `planta`; entonces 5 re-inspecciona). Efecto inocuo (inspección de solo lectura) pero dos AC no pueden pasar a la vez si se escribe un test «fallo de planta ⇒ 0 re-inspecciones» (R18/R24) y otro «descarga total completada ⇒ 1 re-inspección» (AC-18g). Corregir R18/R24: «sin re-inspección hasta «descarga total completada»».
- A2 (2f, 2 vs 2): 2 L315 («`sostener` admite ítems … y objetos de escena: solo `V05`») frente a AC-32/AC-47 (`sostener(pieza, derecha)` del puzle 3, «encajar una pieza»). La pieza P3 no es ítem de 20 ni V05: o se amplía la lista o AC-47 usa otro mecanismo. Además AC-47/AC-49 llaman `sostener(id, mano)` sin `pose_inspeccion` mientras L315 y 7 L412 la dan como 3.er parámetro.
- A3 (2c): 20 L208 y 20 R18 remiten a «7, regla 27b» para `repasar_bolsillo()`; 7 (L130, L257) solo dice «repasar», no el nombre de acción `repasar_bolsillo` registrado en 1 (regla 23). 20 L212 (fila 1 Entrada) aún dice «Acción derivada `atrás` … Hoy no existe (ver cambios)» mientras 1 declara `repasar_bolsillo` (regla 23): fila de 20 desfasada.
- A4 (dureza): 1 L387–396 vs 19/20/21 vs índice (ver tabla). Es 1 quien discrepa de los tres + índice.
- A5 (índice): fila 9 sin 10 ni 19 (duras) ni 8 (blanda) — el propio 9 L464 lo exige; 9↔10 es dependencia dura circular declarada en ambos lados (9→10 `play_open`, 10→9 `get_view_gate`): aceptable pero debe constar como ciclo conocido en el índice.
- A6 (reciprocidad): 4 no lista a 19 (19 declara 4 Dura); 20 no tiene fila de 10 (10 declara 20 Blanda); 1 no lista a 10 (10 declara 1 «Dura (indirecta)»).
- A7 (2c, 8 L202): tres afirmaciones obsoletas: «21 lista hoy a 8 como Sin dependencia directa» (21 L196 ya dice Blanda), «9 … Indirecta» (9 L459 dice Blanda), «2 (indirecta)» (2 L302 dice Blanda).
- A8 (2c): textos «sin GDD/pendiente» obsoletos — ver apartado 4 arriba (1 L405, 2 L339, 4 L232 y L241, 5 L333, 7 L435, 18 L206/L225).
INFO
- 2 ACs: orden AC-49, AC-50, AC-46, AC-47 antes de AC-35 (numeración desordenada); AC-32 remite a AC-47 correctamente.
- 4: «AC-36 / AC-38c» NO existen en escena-de-planta.md (grep sin resultados): la cobertura r4 los citaba por error o están numerados de otro modo (el último AC visible es AC-07a/07b/08…; no localizados).
- 1 AC-F8 coherente con 4 F3 (D_carga ≈ 11,67 s, tope 13,67 s; traspaso en t=9 s con 20 s ⇒ 31 s): OK.
- 9 Tuning Knobs: `line_fallback_s` 14,0 + `line_grace_s` 2,0 = 16,0 s nominales (F8) coherente; `lock_max_s` ≤ 2,0 s coherente con AC-X2; `close_view_after_s` 1,5 s > `unlock_sfx_s` 1,4 s OK. Sin conflicto.
- 6 R8: 12 claves = recuento correcto (3+1+1+1+2+1+1+1+1); AC-01 «trece» = 12 + `modo_ventana`: coherente. R7 baja de suscriptores: coherente con 3 y 4 R15.
- 3 R10 (tabla de emisores) coherente con 4 R9/R14/R15/R16, 8 R11, 21 R17, 5 (consumo); R16 (escritura silenciosa) y CA-35 coherentes con 9 R8 y 5 R7a (línea base no se rehace).
- 3 CA-01 «20 hechos» coherente con 5 (D.2 del slice).

## Referencias muestreadas (≈63): OK ≈ 58, ERROR 5 (+2 no resueltas)
Hacia GDDs nuevos (18,19,20,21 y 8,10) — OK: 3→D20-10; 6→DT-12 (21 L282); 8→D8-13; 19→D9-33; 4→D18-11; 4→8 R19 (Datos inválidos) y R5; 3→8 R11; 21→8 R13–15; 21→5 R12/R28/R29 y R14 (OQ5); 21→9 R20; 21→7 R27a; 19→7 R20/22/23/24 y D7-34; 8→7 R3/10/11/12/26/30 y AC-V8; 10→7 R19/23/30 y AC-27b; 10→9 R7/8/16/17/18/19/24/35, AC-03/17/49/43; 19→9 R34/35, AC-39b; 8→3 CA-03; 10→3 CA-07/CA-14; 8→5 D-24/D-29/AC-41b; 8→2 D-19/D-33; 4→21 PA-10; 1→20 R23 (existe); 4→18 R21; 9→18 R20; 8→18 R15; 19/20/21→18 R23; 20→9 R34/R35.
Hacia antiguos — OK: 3→5 AC-30c/R17; 4→5 R17/R29; 3 R10→4 R16; 5→4 R14/R15/R16; 1 AC-F8→4 F3; 4→2 D-19; 2→D-30/D-31/D-35; 6→5 D-12; 2 AC-32→AC-47; 5→4 R16; 4 R9→9 R29/R8; 4 R18f→7 retención; 9 L460–L462 refs; 2→1 R… (no verificado).
ERROR (cita desfasada): E1 4 L232 («2 todavía figura con el 4 como Blanda»); E2–E4 8 L202 (21 «Sin dependencia directa», 9 «Indirecta», 2 «indirecta»); E5 20 L212 (`atrás` en vez de `repasar_bolsillo`).
NO RESUELTAS: 19 L184 «compose_i01() (R30)» (si R30 es de 19 o de 9: en 9 R30 es el oráculo de resolubilidad, no `compose_i01`); 3→17 «fila 17 del índice `3, 9, 18`» no comprobada.

## NO LEÍDO (no se declara limpio)
- 3: reglas 1–9 y 17+ salvo lo leído; CA salvo 01/03/07/14/28/29/32/33/35/36 (solo existencia de 03/07/14).
- 1: F1–F4, F5–F7, reglas 14–16 y 20 (solo cabecera de 13), AC salvo F8.
- 4: F1, F2, AC-36/AC-38c (inexistentes por grep), resto de ACs.
- 5: regla 7a, regla 11 (solo línea 87), ACs 18b y 18c.
- 2: reglas 4, 18, 24 (líneas omitidas por tamaño), F9, F10, ACs 09 y 20.
- 9: reglas 14, 27, 29 (solo cabeceras), AC-47 (por grep no se localizó; sí el AC-47 de 2).
- 7: Edge Cases desde L358, tabla de objetos, ACs (solo AC-27b/AC-V8 por existencia).
- 6: ACs salvo 04f/04g; UI.
- 8, 10, 18, 19, 20, 21: solo Dependencies/cabeceras y citas; ACs no cruzados (2f no hecho para estos).
- systems-index.md: solo las filas 1–10, 18–21 y la tabla de orden; no leídas las filas 11–17, 22+ ni las notas de ciclos.

