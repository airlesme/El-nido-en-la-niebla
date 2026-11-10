# Revision R15-1: R9-B1 (avisos del bus) y R9-B3 (puzzle_solved)

## VEREDICTO
- R9-B1: CERRADO en contrato (3 regla 10 + emisores/consumidores coinciden); PARCIAL en texto: quedan restos de nombres/marcas obsoletas (avisos, no bloqueantes).
- R9-B3: CERRADO. Ningun GDD pide ni emite `puzzle_solved {id}`.
- Global: PARCIAL (0 bloqueantes, 9 avisos de limpieza).

## 1. Avisos: emisor, consumidores y nombre (verificado)
Fuente: estado-y-bus-de-eventos.md (3) regla 10, l.40-56.
- «pausa abierta»/«pausa cerrada»: emisor 25 (3 l.55; 25 R3 l.44, AC-25-50 l.278). Consumidores 3 declara 5, 23, 26, 28. 23: R41 (l.179), AC-23-18 (l.370) y D23-29 usan «pausa ...»; 26 R25 (l.61); 28 R22 (l.120). 5 solo consume `pause_opened` como causa de guardado (INFO: 3 dice que 5 consume ambas).
- «sonido pedido»: emisores en 3 l.56 = 7, 8, 10, 15, 17, 19, 22, 25; consumidor 23 (R5 tabla l.64 lista los mismos 8). 26 lo escucha para SFX (l.35). 22: l.193, l.330, AC-22-16 coinciden. Registro l.3208 lista emisores sin 22 (ver A2).
- «linea pedida» solo voz: 3 l.56 y l.53; 23 R7b (l.87); 22 l.193/330; 26 l.35. Coherente. Emisores 9, 8, 21, 22 (23 l.62).
- «linea iniciada»: emisor 23 (3 l.54, registro l.3215), consumidor 26 (l.35). OK.
- Causas de «linea terminada» fin/corte/watchdog/interrumpida: 3 l.54, registro l.3179, 23 R14. OK.
- «puzles configurados»: emisor 9 (R8/D9-80/AC-68; 3 l.52), consumidor 17 (3 l.187; sistema-de-pistas l.109, 210, 439). OK.
- «descarga total solicitada/completada»: emisor 4 (3 l.47; 4 l.75); oyentes: 23 (R42e, AC-23-17, l.68/180), 26 (R27, AC-26-18), 5 (re-inspeccion con «completada», guardado l.119/149), 21 inactivo entre ambos (4 l.31). OK.
- «estado de objeto pedido»: emisor 21 unicamente (3 l.51 y l.53; 21 DT-29; 22 l.330; 23 l.66). Receptor 22 para `V02`. OK.
- «interaccion ejecutada» filtrada por HECHO: 21 (l.71, DT-29, AC-21-15) y 7 (D7-74 l.687) OK; 23 y 28 NO (A6).
- `EV_PUZZLE_SOLVED_<ID>`: emisor 9 (3 l.52; 9 AC-68 l.729, D9-81 l.823); 28 R19 (l.107), l.222, l.237, DT-18. `puzzle_solved` sin guion solo como causa de guardado de 5 (guardado l.66, l.187, l.584; marco l.336, l.629, D9-8): legitimo.

## 2. Restos de variantes antiguas
- `pause_opened`/`pause_closed`: nombre de codigo permitido por 3 (l.55, l.124) y registro l.3188/3197. Uso en prosa de 25 en vez de «pausa abierta»: l.10, 44, 184, 187, 205, 235-236, 248, 277, 280, 340, 375, 378, 395, 416, 423, 434. 25 l.44 y l.429 describen `pause_closed` como "alias" de 23 (obsoleto: 23 ya se renombro). systems-index l.263. Resto como causa de guardado: legitimo.
- «sonido de llamada pedido»: solo en notas historicas/negaciones (22 l.193, 238, 330, 343; 23 l.87, 461, 493; bus l.349 log). Vivo en registro l.2170 y l.3208 (A2). 23 l.493 pide retirarlo (ya hecho).
- `puzzle_solved {id}`: 0 vivos. `t_espera_voz_s`: solo historico (21 l.3, 307, 371; 23 l.90, 458); registro l.1893 deprecated OK.
- `t_corte_senal_s`: VIVO en 22 l.113 (formula T_compl) contra su retiro en l.211 (A1); registro l.2110 deprecated pero con `referenced_by: marco-de-puzles` (l.2113).
- Slice (design/slice): 0 coincidencias de cualquier variante. Indice: solo l.263.

## 3. Orden al volver al titulo desde la pausa
25 R28 (l.119): 1 Saliendo, 2 5 guarda `quit`, 3 pide descarga total, 4 4 emite «descarga total solicitada» (23 descarta voz/efectos pausados, 26 retira bloques), 5 «pausa cerrada» tras la descarga, "no reanuda nada". AC-25-58 (l.347) y AC-25-59 (l.353), D25-27 (l.386); 4 l.75 (solicitada; completada al terminar; 21 inactivo); 23 R41/(e) l.180, AC-23-17 l.369; 26 R27 l.63, AC-26-18 l.181, D26-17; 3 l.55 («tambien al salir al titulo tras la descarga total»). Coherente: solicitada -> (descarga) -> completada -> pausa cerrada; sin voz ni subtitulo colgados. INFO: 25 R28 no nombra «descarga total completada» (5 la usa para re-inspeccion; llega antes de «pausa cerrada», sin conflicto). 28 y 21 no consumen la cadena (reloj de juego).

## 4. Referencias cruzadas muestreadas (OK salvo indicado)
OK (existen y dicen lo citado): 23 R5 (l.58), R7b (l.87), R10 (l.90), R14 (l.94), R41 (l.179), R42e (l.180); 25 R3 (l.44), R28 (l.119), AC-25-50 (l.278), D25-19/D25-27; 22 reglas 3, 14, 15, 17, 33 (l.33, 50, 51, 56, 84); 26 R5, R25, R27 (l.35, 61, 63), AC-26-18; 21 R1, R17, R22, R23 (l.35, 73, 78, 79), AC-21-15, DT-29; 8 reglas 11, 13, 14, 15 (control-de-acceso l.82-99); 9 R8 (l.164), R19, R22, R26 (l.225-246), AC-68, D9-80, D9-81; 28 R13, R17, R19, R22 (l.77-120), DT-18/21; 4 reglas 11-17 (l.71-77), regla 15/16 de 4 citadas por 3 y 25; 5 reglas 3, 6, 13, 17, 24, 29 (guardado l.50-137); AC-23-18 (l.370), AC-23-32 (l.384), AC-22-16 (l.238), AC-9 68, D23-27/29/30, D7-74. Total ~45 existen.
ERROR:
- 4 l.75 cita «director-de-audio.md regla 27» para el descarte de voces pausadas: es R42e (A7).
- AC-25-58 y AC-25-59 duplicados en 25 (l.347/352 y 348/353): referencia ambigua (A8).

## HALLAZGOS
BLOQUEANTE: ninguno.
AVISO:
- A1 llamada-telefonica.md:113 «`T_compl` suma ademas `t_corte_senal_s` (0,3†)»; retirada en l.211 (-> `t_interrupt_s` 0,2 s de 23). Formula con constante inexistente.
- A2 registry l.2170 «sonido de llamada pedido» ‡ y «linea pedida (tambien 22)»; l.3208 «22 «sonido de llamada pedido» ‡ ... nunca por «linea pedida» (R7b) ‡»; l.3217 y l.3199 con ‡; l.2113 referenced_by de constante deprecated; sin entrada de «estado de objeto pedido» ni «descarga total».
- A3 menu-de-pausa (25) l.44 y l.429 «`pause_closed` = alias»; l.416/423 piden «dar de alta ‡» lo ya hecho; prosa con `pause_opened` en vez de «pausa abierta» (lista en seccion 2).
- A4 director-de-audio (23) ‡ obsoletas: l.70 («pausa cerrada es nuevo ‡»), 179, 306, 316, 489, 497, 498, 512; l.87 «OQ 7 ... debe resolverse antes de cerrar el lote» (ya resuelta en 3).
- A5 ‡ obsoletas en 26 (l.35, 61), 28 (l.120, 226, 240, 359) y 17 (sistema-de-pistas l.398, 439); 5 con ‡ en «descarga total completada» (guardado l.119, 120, 149); 4 l.98 ‡ en «descarga total completada».
- A6 23 y 28 no mencionan «interaccion ejecutada» (grep 0) ni el filtro `HECHO`; 7 (l.148, 439, 706) les asigna consumirla y exige que lo digan; 23 R5 (l.60-71) no la lista.
- A7 4 l.75: cita de 23 «regla 27» deberia ser R42e.
- A8 25: AC-25-58/59 duplicados.
- A9 systems-index l.263 «25 emite `pause_opened`».
INFO: 5 solo consume `pause_opened` (3 l.55 dice que consume ambas); causas de guardado `pause_opened`, `puzzle_solved:<ID>` legitimas; slice sin restos.

## NO LEIDO
- Entero: pantalla-de-titulo (27), ajustes-persistentes (6), opciones-de-accesibilidad (29/30), shaders-y-efectos, jugador-en-primera-persona (2), base-de-contenido-narrativo (18), puzles 1-6, caja-y-compartimentos, ordenador-correo-impresora, documentos-y-bolsillo, entrada-y-controles y prompt-de-interaccion (solo por grep de nombres).
- Solo por grep de fragmentos (no leidos enteros): 3 (salvo l.40-56), 4, 5, 7, 9, 17, 21, 22, 23, 25, 26, 28, registro (solo l.1893, 2110, 2165, 3175-3219), systems-index.
- No verificado: AC-23-32 en detalle, 26 R5 completa, 28 R22 completa, 28 sobre `EV_PUZZLE_SOLVED` en AC.
