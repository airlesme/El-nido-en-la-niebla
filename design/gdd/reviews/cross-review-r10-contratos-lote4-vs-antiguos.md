# R14-A (contratos 9 nuevos GDDs vs 21 existentes) - PARCIAL

## BLOQUEANTES
B1. «sonido pedido» y `pause_closed` no existen en 3 regla 10. 23 R5 los consume (emisores 7, 8, 10, 15, 19; 25). 3: fila «23 Audio ‡» solo «línea terminada/sin audio/fallida»; fila «25 Menú de pausa ‡» solo `pause_opened`; no hay fila para 10. 23 R7b: la OQ 7 «debe resolverse antes de cerrar el lote». Grep: 7, 8, 10, 15, 19 tienen 0 menciones de «sonido pedido» (SFX_CLICK_SUBTLE de 7 regla 11 sigue sin emisor de bus). Regla 10 de 3: emisor no declarado = defecto.
B2. 22 vs 23 contradictorios: 22 Dependencies l.193 pide «línea pedida» (VO y `SFX_*`) + «sonido de llamada pedido» ‡; 23 R7b rechaza `SFX_*` en «línea pedida» (sin señal de respuesta). 22 AC-22-16 y 3 regla 10 (fila 22) mantienen «sonido de llamada pedido»; 23 R5 lo trata como alias de «sonido pedido». Tres nombres para un aviso.
B3. Nombre del aviso de pausa: 23 R5/R41 usa `pause_closed`; 25 (reglas, AC-25-50, D25-19), 26 R5/R25 y 28 usan «pausa cerrada». 23 Cambios requeridos exige a 25 «definir `pause_closed`»; 25 no lo hace. 3 no tiene ninguno de los dos.
B4. 28 (Dependencies / Cambios requeridos) pide a 9 «Emitir `puzzle_solved {id}`»; el aviso real es `EV_PUZZLE_SOLVED_<ID>` (3 regla 10, fila 9). `puzzle_solved` = 0 en 9 y 3. Inexistente.
B5. 17 consume «puzles configurados» ‡ (emisor 9); 3 regla 10 (fila 9) no lo lista (0 coincidencias en 3). No verificado si 9 lo declara con ese nombre (9 tiene 7 coincidencias de «puzles configurados|puzle activado»).
B6. 24 depende de forma DURA de 7 y 24 exige cambios no aplicados: `get_target()` con `anillo_visible` (7 regla 30 devuelve `{id, etiqueta, ¿largo?, p}`), `duracion_pie()`, `mostrar_pie/ocultar_pie` (7 regla 12 dice «entrega la clave y la duración»), dominio ampliado de `resultado` de «interacción ejecutada» (7 regla 29 y AC-36 solo HECHO). 0 coincidencias en 7. Además 1 no expone `get_binding_label` (0) y 20 R23 no usa `mostrar_pie` con `retener` (verificar: 20 cita UI_BOLSILLO_AYUDA pero no `mostrar_pie`). 24 los marca ‡ (abiertos con motivo), pero el contrato duro queda sin dueño que lo cierre.

## AVISOS
A1. 6 no define `icono_grande` ni `etiqueta_accion_visible` (24 R4/R31, 30 regla 2); recuento «restablecer todos»: 24 dice 12→14, 30 dice 12→18 (12+6 con `escala_texto_ui`, `subtitulos_tamano/fondo/hablante`). Dos cifras para el mismo contador; 30 AC-30-01 BLOQUEADO.
A2. 23 R5 «estado de objeto pedido» emisores «21, 22»; en 3 regla 10 solo lo emite 21 (22 lo recibe). 22 D22-22 coincide con 3. Corregir 23.
A3. 3 tabla l.94/97: `formulario_leido` y `memo_leido` los lee «17 Pistas ‡»; 17 D17-10 los declara sin uso (condicionado OQ 2). Y 17 lee `correos_leidos` (Dependencies) pero 3 solo lista a 19 como lector.
A4. 17 pide `SFX_CLICK_SUBTLE` (botón inerte); 23 R5 no lista 17 como emisor de «sonido pedido».
A5. 28 DT-8 y 23 R22 derivan por separado la caída de la lluvia (imagen y audio) de `LUCES_APAGON`; 28 espera `LLUVIA_CESA` de 21 en `ESC7_APAGON` («OQ 1 de 23»); 23 Cambios requeridos pide a 21 reemitir `LUCES_APAGON` duración 0 en reanudación. 21 menciona `LLUVIA_CESA` (l.50, 51, 74, 350) pero no verificado si resuelve la OQ 1: riesgo de dos dueños de la misma verdad.
A6. 30 regla 2 coloca `subtitulos_tamano/fondo` en «Visión» (pantalla Accesibilidad) mientras 30 Cambios (6) dice que 6 l.50 asigna los de subtítulos a 25 «Sonido y pantalla»; AC-30-01 exige que ninguna clave esté en dos pantallas. 26 y 25 no verificados.
A7. 25 Dependencies l.242: «30 no revisado en esta ronda».

## INFO
I1. 17 Dependencies l.214 llama a 25 «sin GDD»; 25 existe y reconoce a 17 (25 l.234). 3 sigue con ‡ para 17, 23–28 en la tabla de interacciones (l.88).
I2. 25↔5: `pause_opened` como causa en 5 (16 coincidencias) coherente con 3. 24↔6 reciprocidad parcial (B6/A1).

## NO LEIDO (no declarar limpio)
27 pantalla-de-titulo (solo encabezados), 29 shaders-y-efectos, 26 subtitulos (solo reglas 5 y 25 por grep), 30 (solo regla 2 y Cambios por grep), 28 (solo Dependencies), 17 (solo Dependencies), 25 (solo grep), 24 (reglas A-E leídas). Pares sin leer ambos lados: 23↔8, 23↔15, 23↔9, 23↔21 (solo grep), 25↔1, 25↔4, 25↔22, 25↔21, 27↔1/4/5/6/21, 28↔4/10/8/22, 29↔todos, 30↔1/2, 26↔18/22, 17↔11–16. Muestra «regla N / AC-N» verificada: < 50 (unas 15). ‡ de 3 para 23: parcialmente cerradas (23 ya existe, pero 3 no se actualizó).

---
## Informe final del revisor (respuesta de cierre) — revisión parcial: no leyó 27 ni 29; de 17, 26, 28 y 30 solo secciones sueltas

**6 bloqueantes y 7 avisos.**
1. «sonido pedido» y `pause_closed` no existen en la regla 10 de 3. 23 R5 los consume (emisores 7, 8, 10, 15, 19 y 25); 3 solo lista las tres señales de respuesta de 23 y `pause_opened`. Ninguno de 7, 8, 10, 15 ni 19 dice «sonido pedido».
2. 22 y 23 se contradicen: 22 (l.193) pide `SFX_*` por «línea pedida» más «sonido de llamada pedido» ‡; 23 R7b rechaza `SFX_*` en «línea pedida» y trata «sonido de llamada pedido» como alias de «sonido pedido».
3. El aviso de pausa tiene dos nombres: 23 R5/R41 `pause_closed`; 25 (AC-25-50, D25-19), 26 R5/R25 y 28 «pausa cerrada». 3 no lista ninguno.
4. 28 pide a 9 emitir `puzzle_solved {id}`, que no existe en 9 ni en 3; el aviso real es `EV_PUZZLE_SOLVED_<ID>`.
5. 17 consume «puzles configurados» ‡ (emisor 9). 3 regla 10 no lo lista.
6. 24 depende de forma dura de 7 y los cambios que exige no están aplicados (`anillo_visible`, `duracion_pie`, `mostrar_pie`, dominio ampliado de `resultado` no aparecen en 7); 1 no expone `get_binding_label`. Todo marcado ‡, ningún GDD lo cierra.

**Avisos:** 6 no define `icono_grande` ni `etiqueta_accion_visible` y «Restablecer todos» pasa de 12 a 14 (24) y a 18 (30); 23 da a 22 como emisor de «estado de objeto pedido» pero en 3 solo lo emite 21; 3 cita a 17 como lector de `formulario_leido`/`memo_leido` que 17 declara sin uso, y 17 lee `correos_leidos` que 3 no anota; 17 pide `SFX_CLICK_SUBTLE` y 23 no lo lista; 28 y 23 derivan por separado la lluvia de `LUCES_APAGON` (falta ver si 21 resuelve la OQ 1); 30 y 25 podrían duplicar las claves de subtítulos; 30 aparece como «no revisado» en 25.

**No leído:** 27 y 29 enteros; de 17, 25, 26, 28 y 30 solo secciones sueltas; sin verificar los pares 23↔8/15/9/21, 25↔1/4/22/21, 26↔18/22 y 30↔1/2; unas 15 referencias muestreadas (de ≥ 50 pedidas).
