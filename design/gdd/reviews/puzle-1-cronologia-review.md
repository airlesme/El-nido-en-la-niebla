# Review independiente GDD 11 · Puzle 1 Cronología (design/gdd/puzle-1-cronologia.md)

## VEREDICTO: NEEDS REVISION
0 bloqueantes confirmados; 9 avisos; 4 info. Las 8 secciones estan, la aritmetica cuadra y los contratos con 9/19/18 existen. Los avisos son contradicciones internas y deudas de decision, corregibles sin rehacer el diseno.

## Recalculos (checklist 1)
- F1: 1+16+72+96+24 = 209 OK; 4! = 24 OK; 1/24 = 4,17 % OK.
- F2: t_fallo 8*0,4+0,6+1,5 = 5,3 OK; peor 23*5,3+3,8 = 125,7 OK (9 F6 dice 122 hasta el ultimo fallo, coherente); media 11,5*5,3+3,8 = 64,75 -> 64,8 OK; geometrica p=1/24 -> 23 fallos OK; 6 permutaciones: 5*5,3+3,8 = 30,3 y 2,5*5,3+3,8 = 17,05 OK.
- F3: 1,5+1,0+0,5 = 3,0; peor 3+2+1 = 6 OK.
- F4: bajo 45+25+23,8+0+0+2 = 95,8; central 65+36+43,8+10,7+20+2 = 177,5 (2,96 min); alto 90+49+63,8+23+45+2 = 272,8 (4,55 min). T_ordenar (20/40/60 + 3,2 + 0,6), T_trayectos (con 1,0) y T_fallos (0,7*15,3 = 10,7; 1,5*15,3 = 23) OK. 56,5 s dentro de C05 OK. F7 de 9: P1 2-4 min OK (central 2,96 dentro; extremos fuera, lo dice el doc).
- F6: 150-128 = 22; 200-128 = 72; fila de huecos 4*160+3*40 = 760, x 1100..1860 <= 1920 OK.
- F7: 09:14 = 554, 11:40 = 700, 16:02 = 962, 08:55 = 535 OK; sin dia -> [4,2,1,3] OK.

## BLOQUEANTES
Ninguno confirmado. Las referencias a reglas/AC de 9 (4,5,7,9,10,11,11b,12,12b,13,14,14b,16,17,21b,22,25,26,29,30,33-36; F1,F4,F6,F7), 19 (R23,R24,R26-R30, AC-16/23/29, D19-11, PA-6), 18 (reglas 11 y 20, D18-3/17/23, PISTA_P1_N2 unica clave P1), 7 (D7-42, D7-50, D7-61, regla 22/AC-30b) y slice B.1 existen y dicen lo citado. Lo no recogido en vecinos (`on_change`, `rewards`/`persist`/`idle_reset` en el ejemplo, stamps no clicables, NONE con huecos llenos) esta en «Cambios requeridos».

## AVISOS
1. Contradiccion interna (mando): Edge Cases «Mando / stick»: «`ref_N` y `slot_k` tienen atraccion asistida (R14)» frente a R14/Datos nota 7/AC-18: `ref_N` declara `atraccion_desactivada`. Perdida de asistencia con mando en los chips; R14 admite que 9 regla 9 pide atraccion en «referencias y huecos del P1».
2. OQ-8 probablemente ya resuelta por 7: AC-30b de 7 trata la «tolerancia normal» por elemento (64 px -> umbral 128 px, a 170 px solo advertencia por la asistida de 256). Los chips a 150 px pasan sin excepcion; `atraccion_desactivada` provisional es innecesaria y AC-18 queda condicionada a «mientras OQ-8 siga abierta».
3. Referencia rota: R4 dice que los stamps son objetivo de N3 «(R34)»; N3 es R30 (R34 es la resolucion).
4. AC-6 (R20/F5): «el jugador cambia H3 en t = 10,40» trata el cambio como una sola accion; por R12 corregir son dos pulsaciones (seleccionar reinicia, colocar reinicia). El ejemplo de F1 de 9 si usa un solo cambio; AC-6 debe distinguir seleccion y colocacion o remitir a AC-7.
5. Reparto de responsabilidad ambiguo: R7 («el controlador crea `ref_N`... y `stamp_N`») frente a 9 regla 7 («el marco... crea un elemento clicable `C05/paper/ref_N`») y 19 R30 («9... crea un elemento clicable»). Aclarar quien construye `elements()` para que un programador no tenga que adivinar.
6. R7/Edge Cases: «`compose_i01()` devuelve != 4 bloques con ref -> sin material» no tiene AC (AC-3 solo cubre la prueba de datos); es una regla de ejecucion sin criterio testeable.
7. R19/AC-3 requiere un orden de dia y hora; 19 R30 solo entrega `dia` (etiqueta) y `hora_envio` string. La peticion esta en «Cambios requeridos» (19 a, 18 a), pero AC-3 no es ejecutable hasta que se acepte: depende de cambios no aplicados.
8. Decision de contenido tomada por defecto sin pregunta: D11-6 activa el sello en los huecos (`show_stamp_in_slot` = verdadero) y D11-8 define N3 = resaltado de sellos; el slice B.1 dice N3 «la hora de envio aparece en letra pequena» y v0.4 solo confirma que no anade informacion. OQ-4 lo pregunta pero ya esta activo y baja la dificultad respecto a B.1 (afecta criterio de competencia/dificultad del slice). Encabezado de Open Questions afirma «Ninguna... contradice el slice» mientras OQ-5 lo hace (§8 «se entregan tarjeta_B y tarjeta_D»).
9. Reciprocidad: 11 declara dureza dura con 19, 20 y 18, pero 19, 20 y 18 solo nombran «P1»/«11 Puzle 1» (18 si lo lista); 19 y 20 no listan el sistema 11 como dependiente. 11 los marca «sin cambios»; conviene anotarlo en sus tablas.

## INFO
- Orden de OQ (OQ-8 antes que OQ-7) y ACs fuera de orden (AC-4 tras AC-1/2/3/5; AC-16 antes de AC-6).
- F3 compara medias de metricas distintas («23 a <= 6 fallos» peor caso y «11,5 a 3» media): correcto, pero el texto de R26 mezcla ambos en una frase.
- Todos los tiempos de F4 y `t_clic` 0,4 s estan marcados † (sin medir); OQ-7 lo reconoce. No hay afirmaciones de Godot 4.7 propias del doc (las de `GameClock`/pausa son de 9 y estan marcadas como no cubiertas por docs/engine-reference).
- Pilares: sin estado sin salida (R39, AC-12), sin contador/castigo (R25, R46); D-W1 y D-W4 reconocidos con umbral medible (AC-PV4) y OQ-1.

## Esquema de «Datos del puzle» vs regla 4 de 9
Conforme: id, mode VIEW, view, solved_flag, requires.all, needs_items, validation, solution.sequence (int), on_reject (reset_after_s 1,5 <= lock_max_s 2,0), on_solved (write, sfx, sfx_s, close_view_after_s), on_reopen NO_VIEW, resolution IMMEDIATE, persist, hints (3 niveles; `TEXT` con PISTA_P1_N2; `HIGHLIGHT` con `targets_if_missing_items`, 3,0 s sin camara; `availability` ON_HINT valido por regla 25). `locked_feedback` aparece en 9 (regla 7 y matriz) aunque no en la lista de la regla 4. Nuevos y marcados ‡: `on_change`, `rewards: []`, `idle_reset`, stamps no clicables como `targets` (la regla 29 exige que existan en 7). Sin `assist`, correcto (solo P3/P5).

## NO LEIDO / NO VERIFICADO
- AC-X2, AC-39/39b, AC-07/06, AC-18/AC-52 de 9 (cite por numero; solo vi las reglas); seccion Dependencies/Cross-References de 9.
- 8 (regla 6 y `ANIM_DOOR_OPEN`), 10 (caja), 17 (sin GDD), 3 (hechos), 5, 6, 2 (regla 14/18), 4.
- `design/gdd/systems-index.md` fila 11 y `design/registry/entities.yaml` (consistencia de las entradas propuestas).
- 7: texto completo de las reglas 11, 22 y 27 (solo grep); D7-59 (citado como tabla reciproca de C05; parece ser sobre releer documentos, no sobre C05).
- 19: R20 y R23 completos (lineas largas); 20: F3 y R8 (fila de tabla confirmada).
- Slice: §10.1, §19.1, D.2 (solo B.1 y las lineas 93/134).
