# Review R6-2 (final)

BLOQUEANTES: 0.

## (1) W-1 CERRADO (INFO)
5 reglas 17/18/24/29 + AC-18, 18d, 18g, 36b, 38c: una politica (sin re-inspeccion en el fallo; una al llegar «descarga total completada»); 4 (escena-de-planta.md:386) coincide. Sin contradiccion.

## (2) W-2 PARCIAL
- Firma: 2 regla 24 `sostener(obj_id, mano = izquierda, pose_inspeccion = nulo)` y 7 regla 13 `sostener(id, izquierda, pose_inspeccion = {...})` coinciden. Sostenible unico = V05.
- AVISO: 2 AC-47 usa `sostener("V05", derecha, pose_inspeccion)` pero 7 regla 13 manda `izquierda` (HAND_REACH derecha, HOLD_ITEM izquierda). AC-47/AC-32 usan V05 como «sustituto de la pieza del P3» (D-41): la pieza del P3 sigue sin ser sostenible (7 «unica lista», solo V05); queda abierto.
- AVISO: 2:112 (tabla Dependencies, 20) `sostener(item_id, izquierda)` 2 argumentos; la firma es de 3 (AC-49 pasa `nulo`).

## (3) Pares de dependencia (dureza declarada por cada lado)
OK (coinciden): 8-20 Dura/Dura (8 «de 8 hacia 20»; 20 «recíproca»); 19-20 Dura/Dura; 19-9 Dura/Dura (9->19); 10-9 Dura/Dura circular; 7-10 Dura/Dura; 21-8 Blanda/Blanda; 21-19 Blanda/Blanda (asimetria documentada en 19 y 21:199); 21-4 Dura/Dura; 21-1 Dura/Dura; 20-7 Dura/Dura; 1-19 Dura/Dura; 4-19 Dura/Dura; 1-20 Blanda/Blanda; 20-9 Blanda/Blanda; 10-4 Dura/Dura; 8-5, 8-9, 8-7, 8-4 coinciden.
DISCREPANCIAS (AVISO):
 D1. 20-4: 4 (escena-de-planta.md:227) «9 · 10 · 20: Dura (vía contenedores e IDs)»; 20 (:219) «4 Escena de planta: Indirecta».
 D2. 20-5: 5 (guardado-y-carga.md:329) «8 · 9 a 16 · 20: Blanda»; 20 (:217) «5 Guardado: Indirecta».
 D3. 20-9 dentro de 9: marco-de-puzles.md:463 «20: Blanda» y :477 «20: Indirecta» (misma pareja, dos durezas).
 D4. 9-21: 9 (:478) «21: Indirecta»; 21 (:198) «9: Sin dependencia».
 D5. 10-5: 10 (:196) «5: Blanda»; indice fila 10 «indirectas: 1, 2, 5, 21».
 D6. 10-21: 10 (:200) «21: Blanda»; indice fila 10 «indirectas ... 21»; 21 no lista a 10.
 D7. 1-10: 1 (:403) «10: Dura (indirecta)»; indice fila 10 «indirectas: 1»; 10 no lo lista como Dura.
 D8. 20-10: 20 (:214) lista 10 Blanda; indice fila 20 «(blandas: 1, 2, 9, 17, 24)» NO incluye 10 (W-4 dice cerrado; el indice no).
 D9. Indice fila 1 «— (blandas: 3, 4, 18)» vs 1 Dependencies (7, 19, 21 Duras; 10 Dura indirecta; 20 Blanda): el indice no refleja las duras de 1 (si la columna es «depende de», es dependencia de 1 hacia 7/19/21: 1 las lista como Dura).
 D10. 1-20 en 20 (documentos-y-bolsillo.md:216): «1 la lista como “Dura (de 20 hacia 1)” (discrepancia anotada)» — 1 (:394) ya dice Blanda: texto de 20 obsoleto.
 D11. 8-20 reciprocidad: 8 «Dura (de 8 hacia 20)» vs 20 «Dura, recíproca (8 ↔ 20)»: misma dureza, distinta direccion declarada.
Total discrepancias de dureza/reciprocidad: 11 (D1-D11; las de dureza estricta: D1-D7, D10).

## (4) W-5 repasar_bolsillo
Con guion bajo: 1 (regla 23), 7:257, 9, 20, registro (:1439), indice :284. AVISO: sin guion bajo en 18 (:134, D18-21 :370), 3 DT-19 (:330), 5 D-47 (:560/:583), 2 (:584), 20 log (:355).

## (5) Restos
- AVISO entities.yaml:519 nota «pendiente de actualizar 7» (7 ya lo hizo, D7-62); la entrada esta `deprecated` (OK).
- AVISO systems-index.md:253 (nota de 10): «anima BOX_Cn_OPEN (1,6 s) ... peor caso 2,6 s» sin «sustituida por»; ademas esta bajo «sistemas sin GDD» y 10 ya existe.
- AVISO ajustes-persistentes.md:383 (Q16): «no BOX_Cn_OPEN» sin marcar como sustituida.
- AVISO caja-y-compartimentos.md: usa `BOX_Cn_OPEN` como notacion generica (:54,:81,:124-139 F1/F2,:181,:221,:238,:277,:296) y :336 «se sustituye ... actualizar»; no es «solo sustituida por».
- INFO: «sin GDD»/«por redactar» restantes se refieren a 17, 22, 23, 24, 25, 27, 28 (correcto). «19 hechos/19 valores»: sin resultados. «Hoy no existe», «a corregir»: sin resultados relevantes salvo en decisiones de historial (8 D8-25, 18 D18-25, 20 D20-22, descritos como retirados).

## (6) W-9
BOX_OPEN_MAX: unico dueno 10 (registro :1208 source caja; 7 D7-62 lo consume; Entrada F8 :327/:403 lo cita «de 10»; 21:54 solo lo cita). INFO. fov_step_deg: registro :700-707 y ajustes :245 coinciden (5, rango 1-15†). † consistente.
AVISO menor: registro :404 y :509 siguen diciendo «BOX_OPEN_MAX 1,6 + hasta 1,2 = 2,8» (coherente).

## (7) ACs nuevos
- N4-1 (20 AC-12c) vs 9 AC-59 / 7: compatibles (carta I-07 no mueve el cursor).
- AVISO N4-2: 9 AC-59 («atras» durante `Saliendo` de D01d lo consume la vista; no se emite repasar_bolsillo) vs 1 AC-E17 / regla 23 («repasar_bolsillo se entrega aunque haya una transicion bloqueante de 7 en exploracion»; solo se descarta si la pulsacion cierra un modo). Pueden contradecirse si la pila ya es `exploracion` durante `Saliendo`; 1 no cita la excepcion de la salida de D01d. No verificado D7-63 en 7 ni 7 regla 27b.
- N1-1, N5-1: NO verificados en detalle.

## NO LEIDO
Reglas 14/15 de 4 (solo via cita en :386), regla 27b y D7-63 de 7, ACs N1-1 (8/20), N5-1 (10) y sus vecinos, 3 (estado) Dependencies, 18 Dependencies/tablas, 6 Dependencies, 19 completo, filas 21 salvo :185-200, interior de las lineas largas omitidas por Grep (p. ej. 7:130/139/324/458, 1:35/67/68, 10:16/116/143/300/327).
