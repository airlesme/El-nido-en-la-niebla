# Revision R6-1 - cierre de E4-1 (borrador final)

VEREDICTO E4-1: CERRADO en comportamiento (la operacion general cubre todas las formas de pila); quedan 0 BLOQUEANTES y varios AVISOS de precision/tests.

## (1) Recorrido de pilas
- [menu]+Nueva partida: 1 R6 fila "Titulo ninguno" y AC-E2/AC-E13c ultimo GIVEN: abre -> [menu, sc(4)] (nada que absorber, sin aviso absorbido); terminada -> 21 traspasa [menu, sc(21)] (sin aviso); 21 pide exploracion -> [exploracion] (descarta menu). 4 R9 pasos 1-9, AC-21b.
- [menu]+Continuar: [menu, sc(4)]; 4 paso 9 pide exploracion -> [exploracion]. AC-10 de 4.
- [menu, sc(21), menu] + Nueva partida: 1 R6 "Descartar la pila..." + fila 65, AC-E13c 2o GIVEN: pila entera descartada -> [sc(4)], un aviso contexto cambiado (menu, sc) + "sc absorbido"(21). 21 R11b cancela sin ordenes. Tope del 4 = D_carga+2 s desde esa apertura. Descarga (paso 3): sin cambio. Traspaso -> [sc(21)] -> exploracion.
- [sc(21), menu] (ESC1 sin menu titulo, ESC8_ASCENSOR): fila 66, AC-E13c 1er GIVEN, AC-21-23b: igual.
- [exploracion, menu(pausa)]+Nueva partida: sin sc ajeno -> abrir normal ([exploracion, menu, sc(4)]), descarga paso 3 -> [sc(4)] (R6 "Reinicio"). Fila 63 de 1 y 4 dice "Antes: [exploracion]" y omite el menu de pausa (AVISO-3).
- Fallo tras absorber: 4 R14 (3) "reponer menu" -> [menu]; 1 R6 lo dice ("el sc del 21 no se restaura"). 21 ya cancelado (AC-21-23b ultimo GIVEN). Quien repone: 4. Luego "Volver al titulo" -> solicitada/completada.
- Cierre del juego en carga: 4 Edge Cases "cierra el juego durante una carga": nada que ver con la pila; valido.
- Volver al titulo desde Recepcion con 21 activo: 4 R15 emite "descarga total solicitada"; 21 R1 -> inactivo (borra volatil); 4 tras descargar pide Reponer menu (cierra sc si hay y deja [menu]) y emite "completada"; 21 R22 paso 8 no cierra su sc. AC-E13b, AC-21-28/29. Reponer menu lo hace 4. Correcto.

## (2)
- El sc ajeno NO puede caducar durante la carga: ya no existe (R6 1; AC-E13c 2o GIVEN). Antes de "iniciada" su tope esta detenido por el menu de pausa abierto (Entrada R7/F8, AC-E8).
- Tope D_carga+2 s se abre sobre pila limpia: SI ([sc(4)]).
- AC-E13c/E13b/E2/AC-21b(4)/AC-21-23b/29: compatibles entre si. AC-F8: sin contradiccion (la cuenta del 4 empieza en la apertura; el reinicio al descargar no la renueva).

## HALLAZGOS
BLOQUEANTE: ninguno.

AVISO-1 (tests/tablas incompletas): ESC8_CIERRE abre su sc *sobre exploracion* (21 R8c: "el jugador esta en exploracion") -> pila real con pausa [exploracion, sc(21), menu], no [sc(21), menu]. 1 R6 fila 66, 4 R9 fila 66, AC-E13c y AC-21-23b solo listan [sc(21), menu]. El texto general ("cualquier otro contexto", R6 1) lo cubre, pero ningun AC prueba esa forma. Igual 1 R6 "Cierre normal" dice que en Recepcion la pila es [sc(21)] sin menu: durante el cierre es [exploracion, sc(21)]. Inocuo para menu (Reponer menu deja [menu]) pero inexacto.
AVISO-2 (nombre de causa): 1 R6, 3 R10, AC-E13c dicen `partida_nueva`/`continuar`; 4 R7 define el motivo como `partida_nueva`/`reanudar`/`recepcion`. Entrada decide por el motivo de "iniciada": usar `reanudar`. Ademas la peticion "abrir" del 4 no lleva motivo: Entrada debe correlacionarla con el aviso (orden aviso/peticion no especificado).
AVISO-3: fila 63 (1) y 62-63 (4): "Antes: [exploracion]" omite el menu de pausa (Nueva partida desde pausa en la planta). El menu queda bajo sc(4) hasta la descarga; correcto pero la tabla debe decirlo (AC-E9 cuenta avisos).
AVISO-4 (21 inactivo, incoherencia interna): 21 R1 dice que el estado volatil se borra "al pasar a inactivo" y que no escucha avisos; Edge Case l.174, AC-21-23a y R11c dicen que cancela/borra "al recibir descarga total completada"; Edge l.158 dice "no cancela con retraso". Ademas "no escucha avisos" choca con reactivarse en "iniciada"/"escena lista" (debe escuchar esos dos). Unificar: borra en solicitada; solo escucha iniciada/escena lista.
AVISO-5 (decision stale en 4): Decisiones tomadas, fila E7-1 (l.400): alternativa descartada "Avisar al 21 desde el 4 o cancelarlo en 'descarga total solicitada'", pero R1 y R15 de 4 ahora emiten precisamente "descarga total solicitada". La razon "el 21 ya conoce el momento (el la pide)" tampoco vale para la peticion de 27 o "Volver al titulo" tras fallo. Reescribir.
AVISO-6 (D22/R6 rationale): R6 dice que sin sc ajeno "el menu del titulo queda debajo, porque Reponer menu lo necesita", pero Reponer menu "deja la pila en [menu]" y funciona tras absorber (titulo ya descartado). Comportamiento coherente (D22 alt. d), justificacion contradictoria con la propia operacion. No altera reglas.
AVISO-7 (AC-E13c / AC-21-23b): "a los 15+2 s del tope antiguo la pila sigue [sc(4)]" solo se cumple con carga forzada larga (retencion); con carga instantanea (1,6 s) ya hay traspaso del 21. Anadir la fixture (retencion/T_cap) al AC.
AVISO-8 (preexistente, ruta en el perimetro): descarga total (Volver al titulo) desde [exploracion, menu] sin sc vigente: 1 R6 "Reinicio de pila" lo trata como "defecto" (abre sc de Entrada 3 s y registra) si se aplica en descargas totales; no queda claro que la descarga total no pase por el reinicio. Y con el menu de pausa abierto el tope no corre (AC-21-28 "Entrada libera a exploracion" no actua). Aclarar que la descarga total no usa el reinicio y que "Volver al titulo" cierra el menu.
INFO-1: Mapas de dependencias: 4 (R9/Interacciones l.94, l.98) no lista "sc absorbido" ni "descarga total solicitada" como avisos que 21/Entrada reciben; registro: "sc absorbido" solo en input_sin_control_ops (no en scene_load_notices: correcto, emisor Entrada); referenced_by de input_sin_control_ops no incluye 21 ni 3.
INFO-2: 5 solo conoce "completada" (D-41/42, R17/29): correcto, no necesita "solicitada".
INFO-3: Formas [menu, sc(21)] y [sc(21)] listadas en R6 no son alcanzables con Nueva partida (siempre hay menu de pausa encima); inofensivo.
INFO-4: Emisor/datos de ambos avisos coinciden en 1, 3 R10, 4 R15/R9, 21 R1/R11b, registro (solicitada: sin datos, emite 4; absorbido: dueno, emite Entrada).

## (4) D22 vs R6: coherentes en comportamiento ([menu] intacto sin ajeno; pila entera con ajeno); solo la justificacion (AVISO-6) es floja.

NO LEIDO: guardado-y-carga.md reglas 17/29 en texto completo (solo grep: lineas largas omitidas), interaccion (7), pantalla de titulo (27), menu de pausa (25), director-de-escenas.md lineas 64/158/260/266/296/305/356 largas leidas solo por fragmentos, GDD 4 Dependencies (208-245) y Tuning Knobs, GDD 1 Dependencies 380-410.
