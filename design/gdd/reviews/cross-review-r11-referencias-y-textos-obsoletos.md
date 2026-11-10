# R15-4 informe (final)

## 1 REFERENCIAS (muestra ~70: 22 AC + ~22 reglas + ~26 decisiones D)
Confirmadas OK (existen y dicen lo citado): AC-01 de 4/6/18, AC-54, AC-23, AC-20, AC-50, AC-66, AC-31, AC-34, AC-43, AC-55, AC-X1, AC-X3 de 9; AC-41b de 5; AC-22-11 de 22; AC-10a de 19; AC-09 de 18; AC-15 de 7; AC-34 de 2; AC-18b de 6; reglas 10/11 de 3; 3/20/23 de 1; 3/7/11/23/30 de 7; 7/9/11/23 de 21; 13/20/25/26 de 22; 6/20 de 25; 9/15/21 de 28; 15 de 29; D9-8, D9-38, D9-63, D9-80, D9-81, D10-2, D12-1, D12-5, D15-7, D16-3, D17-9, D17-10, D18-28, D20-2, D20-26, D22-14, D24-16, D25-19, D7-24, D8-23, D8-29, D30-4, D30-7, D35 (entrada), D-41/42/52 (5).
ERROR:
- subtitulos.md:16 «AC-P5-17 de 9/15»: AC-P5-17 es de 15 (puzle-5 L290), no existe en 9 (AVISO; L124 de la tabla es correcto).
No verificadas (existencia): regla 28 y 31 de 2 (atmosfera L66, director-de-audio L73/255), regla 8 y 23 de 26, regla 7 de 15 (shaders), F3 de 23/26, F5/F2 de 7.

## 2 TEXTOS OBSOLETOS
BLOQUEANTE (explícitos del perímetro):
- estado-y-bus-de-eventos.md:89 «siguen como propuesta (‡) donde el sistema aún no tiene GDD (17, 23 a 28)»; :300 «siguen como propuesta (‡) los de 17, 22, 23 y 25–28».
- ajustes-persistentes.md:238 «24 ... Blanda (sin GDD aún) ... al redactarse debe listar»; :384 «Menú de pausa (25), sin GDD»; :301/:307/:314/:360/:362/:364 «se cierra cuando exista/existan 1, 3, 5, 23, 26, 28, 25, 27, 30».
- guardado-y-carga.md:337 «Pendientes (aún sin GDD): 27 y 25»; :477/:479 «se cierra cuando exista 9 / existan 8, 9 a 16, 21 y 22».
- entrada-y-controles.md:417 «los sistemas sin GDD (24, 25, 27, 30…) deben listarla».
AVISO:
- interaccion-e-inspeccion.md:31 «‡ ... (aún sin redactar)»; estado-y-bus:257,:290 «se cierra cuando existan los sistemas 8, 22, 23 y 25 / escritores».
- puzle-2:416 «28/29 (al redactarse)».
- control-de-acceso.md:76,77,226 mantienen ‡ en SFX_CARD_OK/SFX_DOOR_SWING pese a D8-29 (cerradas por 23).
- menu-de-pausa.md:10,44,236,378,446 ‡ en «pausa cerrada» (3 la declara en estado L55).
- BOX_Cn_OPEN sin «sustituida por»: interaccion-e-inspeccion.md:78; puzle-6-decision.md:282; marco-de-puzles.md:209.
- docs/PLAN-TECNICO.md:3 «build jugable de 25–30 min».
INFO: «25–30 min» en slice L6 y game-concept L110 solo en negación (OK); CLAUDE.md/README.md ya no lo contienen; pause_closed solo como nombre de código/alias; puzzle_solved solo como causa de guardado o negación; PAUSE_MODE_PAUSABLE: 0; «19 hechos»: solo en revisiones antiguas; «repasar bolsillo» solo en log D18-26.

## 3 ACs
- AC-25-23/AC-25-12 vs AC-30-02: 30 «sustituye al orden de 25»; compatibles solo si 25 remite a 30 (no comprobado en 25) -> AVISO.
- AC-25-27 vs AC-30-01: ambos 18 claves (OK, la línea de 25 no leída entera).
- Destellos: 29 AC-15 (>0,25 de luminancia en 333 ms), 30 AC-30-13 (≤3 destellos/s), 28 AC-28-21 (≤3 cruces del ±10 %/s) con 28 regla 9 «≤2,0 Hz»: un parpadeo a 2 Hz da 4 cruces/s > 3 -> AVISO (unidades distintas: cruces/destellos/ciclos).
- AC-25-18 (pie ≥24 px) vs AC-24-14 (≥20 px): AC-24-14 no localizado; NO verificado.
- 27 (pantalla-de-titulo L155–169: AC-01…AC-15 sin etiqueta) y 29 (shaders L215 «AC-15 (regla 5)» etc.) SIN tipo L/I/PV: confirmado, AVISO.
- 27↔25↔5, 23↔26↔4, 24↔7↔1, 28↔29↔21, 17↔9↔25: NO leí los ACs.

## 4 DEPENDENCIAS
BLOQUEANTE:
- Índice fila 12 «17 (lee memo_leido)» y puzle-2:15 «lo leen: 17 (memo_leido)» contradicen sistema-de-pistas D17-10 (L354), L215, L220 («12 y 20 deben dejar de listar a 17 como lector») y puzle-2:112.
AVISO:
- Fila 15: «dependen de 15: 9 y 10 (duras)» vs fila 9 «dependen de 9 (no al revés): … 11–16 (duras)»: si es literal, ciclo duro 9↔15 no declarado; probablemente son sus proveedores.
- Filas 12 y 15 (29 dura): puzle-2 (L250 prosa) y puzle-5 (L239, L414) no repiten a 29 en Dependencies con dureza; shaders-y-efectos.md:167 sigue diciendo «el índice la marca blanda y debe alinearse» (el índice ya dice dura, «blanda en ejecución para 15»).
- Dirección: 29 depende de 12/15 (duras) aunque 12/15 son quienes envían las órdenes; coherente con el principio, pero mezcla «dura» (29) y «blanda en ejecución» (15) en la misma fila.
INFO:
- Fila 21 no lista a 27 (dura) como dependiente; fila 25 sí lista a 27. 27↔30 (27→30 dura, 30→27 blanda) y 25↔30, 17↔25: sin ciclo duro.
- Fila 9 «dependen de 9: 29 (blanda)» coincide con shaders L168.

## NO LEÍDO
Dependencies completas de 1, 2, 4, 5, 6, 7, 8, 10, 11, 13, 14, 16, 18–28, 30 (solo el índice y filas de 29/12/15/17); ACs de 23, 24, 26, 27 (salvo etiquetas), 28 (salvo AC-28-21), 29 (salvo AC-15), 30 completos; README.md y CLAUDE.md solo por Grep de «25–30» y «sin GDD»; registro de «sin GDD» (design/registry) por Grep; AC-24-14; reglas 28/31 de 2.
