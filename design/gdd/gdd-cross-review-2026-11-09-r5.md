# Cross-GDD Review Report (ronda 5 · revisión completa de los 14 GDDs)

**Fecha:** 2026-11-09 · **Veredicto: FAIL** (1 bloqueante, E4-1) · **Modo:** autonomous, workflow standard · **Focus:** full
Informes anteriores: `gdd-cross-review-2026-11-09.md` (8 bloqueantes), `-r2` (2), `-r3` (2), `-r4` (CONCERNS, 0, sobre 9 GDDs) y `reviews/feature-batch-1-resumen.md` (11 bloqueantes de contrato en los 5 GDDs nuevos, corregidos).

- **GDDs reviewed:** 14 of 14 present (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20, 21). Revisores independientes: A (contratos entre los GDDs nuevos y los existentes), B (dueños de datos, constantes, fórmulas, recuentos), C (diseño, pilares, anti-pilares), D (diez escenarios), E (cobertura pendiente, referencias, reciprocidad). A, B y E no encontraron bloqueantes; C tampoco; D encontró uno.
- **Desviación del procedimiento:** lectura por secciones sin contenido pegado (~1 MB entre GDDs); A se reanudó una vez tras agotar su límite de turnos. Ningún revisor leyó todo: ver «Cobertura».
- **Decisiones del usuario respetadas:** las de las rondas anteriores más las 5 aprobadas el 2026-11-09: `repasar_bolsillo`, `I-05`/`I-06a` releíbles, B.1 literal, `MEGA_03` (28 entradas), zonas `T-D-OUT`/`T-OFI-IN` (slice v0.4).

## Consistency Issues

### Blocking

🔴 **E4-1 · 1↔4↔21 · «Nueva partida» desde la pausa durante la escena 1: hueco en la pila.** *(Revisor D.)*
- Tras «Nueva partida» desde el título la pila es [`menú`, `sin control`(21)] hasta que termina la escena 1. Si el jugador pausa y elige «Nueva partida», la pila pasa a [`menú`, `sin control`(21), `menú`].
- La propuesta «absorber el `sin control` ajeno» (1 regla 6, D22, AC-E13c; 4; 21 PA-2 y AC-21-23b) solo cubre [`sin control`(21), `menú`]. Para la pila con un `menú` encima el comportamiento queda sin definir y el `sin control` antiguo puede caducar a mitad de la carga.
- «Absorber» sigue como propuesta pendiente en los tres GDDs y 21 todavía la trata como hueco (PA-2); 1 habla de «un aviso» que 21 regla 11(b) no nombra.
- Decisión propuesta: definir la operación en 1 de forma general («al aceptar una carga `partida_nueva`/`continuar`, la pila se descarta entera y el 4 abre `sin control`(4)»), cubriendo ambas formas de la pila; 4 y 21 se alinean; AC-E13c y AC-21-23b firmes para las dos formas.

### Warnings

⚠️ **W-1 · 5 (guardado-y-carga).** Regla 18 (paso 3) y regla 24 dicen «sin re-inspección» tras un fallo de carga; la regla 17, la 29, AC-18g y la regla 14 del 4 sí re-inspeccionan tras «Volver al título» (el 4 emite «descarga total completada» en cualquier fallo). Dos tests no pueden pasar a la vez. *(E)*
⚠️ **W-2 · 2 (jugador).** L315 limita `sostener` a ítems de 20 y a `V05`, pero AC-32 y AC-47 llaman `sostener(pieza, derecha)` con la pieza del P3; AC-47 y AC-49 no pasan `pose_inspeccion`, el tercer parámetro de L315. *(E)*
⚠️ **W-3 · Dureza de dependencias.** Entrada declara 19 como Blanda, 20 como Dura y 21 como Blanda; esos GDDs y el índice dicen lo contrario en cada caso. *(E)*
⚠️ **W-4 · Reciprocidad que falta.** 4 no lista a 19 (que lo declara dura); 20 no tiene fila para 10 (blanda); 1 no lista a 10 («Dura, indirecta»); la fila 9 del índice omite 10 y 19 (duras) y 8 (blanda); 9↔10 es dura circular. *(E)*
⚠️ **W-5 · Nombre de la acción.** `repasar_bolsillo` (1, 20, 9) frente a «repasar bolsillo» (7, 9) y «repasar» (7); la fila 1 de 20 aún habla de `atrás`. 20 Dependencies dice que la acción de 1 «Hoy no existe» (ya existe: regla 23, AC-E15..E17). *(A, E)*
⚠️ **W-6 · 20 R8/R13.** Dicen que 9/10 muestran `I-05` e `I-06a`; 20 D20-19 y 10 dicen que no hay presentación nueva. *(A)*
⚠️ **W-7 · Textos desfasados.** «sin GDD» o «a corregir» donde el GDD ya existe: 1 L405, 2 L339, 4 L232 y L241, 5 L333, 7 L435, 18 L206 y L225, 8 L197 y L202 (sobre 21, 3, 4, 7). 5 regla 3 (L50) y L196 dicen «19 hechos» (son 20). 5 citas con número o línea errónea: 4 L232, 8 L202 (tres), 20 L212. *(A, B, E)*
⚠️ **W-8 · 21↔19, 21↔8.** 19 R7 pone como ejemplo que 21 cierra el ordenador antes del apagón, pero 21 reglas 13 y 20 no lo hacen; la dependencia 19↔21 es asimétrica. 8 regla 14 habla de un hueco de un fotograma hasta que 21 toma el `sin control`, que 4 ya cubre desde «carga iniciada»; cita «21 F4» donde es F5. *(A)*
⚠️ **W-9 · Constantes.** `BOX_OPEN_MAX` con dos dueños (registro: 10; 7 Tuning Knobs l. 458: «constante de 7»; 10 sin fila propia). `BOX_Cn_OPEN` sigue vivo en 7 F4 (l. 322), D7-47/D7-52, marco l. 544, 21 l. 54 y `box_chain_time.variables`. 2 dice «Entrada F8 (1–5)» (es 3–5 s). `fov_step_deg` con el rango del FOV en el registro. † inconsistente en `lectura_min_s_A04` y `t_timbre_pasillo_s`. *(B)*
⚠️ **W-10 · Tiempos (B, C).** F7 de 9 (10,5–22 min) es solo de puzles; con escenas dirigidas (37–48 s) y ~2 min de paseo el mínimo ronda 13,5 min, y falta presupuestar llamada, lectura, exploración y espera del apagón: nada demuestra que el slice entre en 25–30 min.
⚠️ **W-11 · Escenarios (D).** N1-1 la presentación de tarjetas de 20 y el gesto de 8 pueden coincidir sin AC; N2-1 `correos_leidos` no tiene causa de guardado propia; N4-1 el cursor de repaso de 20 puede avanzar con la «lectura abierta» de `I-07`; N4-2 un `atrás` en la salida de la vista de `D01d` aplaza el repaso y hace que se rechace la carta del P6; N5-1 C3 queda `ABIERTO` si se interrumpe en sesión y `ENTREABIERTO` si se carga; E7-1 21 sigue activo durante la descarga total al volver al título.

*INFO:* AC-36 y AC-38c no existen en 4 por grep; la pausa sobre `AnimationPlayer` (Godot 4.7) no consta en `docs/engine-reference/godot/` (NOT SOURCEABLE).

---

## Game Design Issues (revisor C)

### Blocking
Ninguno. Sin softlock en puertas B/D, `A05`, ascensor `EN_USO`, impresora ni bolsillo; `repasar_bolsillo` es coherente con «No hay menú de inventario» (slice D.1 y AC-E15..17); 21, `MEGA_03`, los mensajes del teléfono y «Continuará» no violan «NOT una historia explicada»; ningún momento supera 4 sistemas con acción simultánea.

### Warnings
⚠️ **A-C1 · P1 con B.1 literal.** Con hora y pie siempre visibles el P1 solo se distingue por el día (ordenar solo por `hh:mm` da 4,2,1,3, y el pie sesga). Las pistas N2 y N3 no añaden nada, así que quien se atasca no recibe ayuda sobre el día. (Consecuencia aceptada de la decisión B.1, D-W4.)
⚠️ 22 (llamada) sin GDD aunque 8, 21, 9 y 5 ya dependen de contratos con él. 21 hace opcional el «Ahora no» de la escena 1 y el slice C.1 no. Las pistas automáticas del P6 (10 s y 20 s) chocan con «pistas desde la pausa» (§10) y la de 20 s adelanta el efecto de la carta. El slice §13.3 («ningún compartimento depende de otro») contradice B.6 y la cadena c1→c3→c4.
*Estado D-W1…D-W11:* vigentes D-W1 (P1 y T1–T3; T4 ya no), D-W4 (más fuerte con B.1 literal), D-W5, D-W8, D-W9, D-W10, D-W11; cerrado D-W6; D-W7 parcial; D-W2 y D-W3 no reverificados (dependen de 14 y 22, sin GDD).

---

## Cross-System Scenario Issues (revisor D)

**Scenarios walked:** 12 (N1 a N5 nuevos; E1, E3, E4, E5, E7). N1 completo salvo los gestos de 2; N2, N3, N4, N5, E1, E3, E5, E4 y E7 parciales; E6 (llamada) no recorrido (22 sin GDD).
### Blockers
🔴 E4-1 (arriba).
### Warnings
Los de W-11. Los pasos que dependen de 22, 23, 24, 25, 27 y 28 (sin GDD) quedan NO RECORRIDOS.

---

## GDDs Flagged for Revision

| GDD | Motivo | Tipo | Prioridad |
|---|---|---|---|
| entrada-y-controles.md (1) | E4-1 (operación general sobre la pila), W-3, W-4 | Consistency | Blocking |
| escena-de-planta.md (4) | E4-1, W-4, W-7 | Consistency | Blocking |
| director-de-escenas.md (21) | E4-1 (PA-2, AC-21-23b, regla 11b), W-8, E7-1 | Consistency | Blocking |
| guardado-y-carga.md (5) | W-1, W-7 | Consistency | Warning |
| jugador-en-primera-persona.md (2) | W-2, W-9 | Consistency | Warning |
| documentos-y-bolsillo.md (20) | W-5, W-6, W-4, W-7 | Consistency | Warning |
| control-de-acceso.md (8) | W-7, W-8 | Consistency | Warning |
| ordenador-correo-impresora.md (19) | W-8 | Consistency | Warning |
| interaccion-e-inspeccion.md (7) | W-5, W-9 | Consistency | Warning |
| marco-de-puzles.md (9) | W-10, W-4 | Consistency / Design | Warning |
| caja-y-compartimentos.md (10) | W-9, N5-1 | Consistency | Warning |
| base-de-contenido-narrativo.md (18) | W-7 | Consistency | Warning |
| systems-index.md · entities.yaml | W-4, W-9 | Consistency | Warning |

## Verdict: FAIL

1 bloqueante (E4-1). Es el último tramo de C-B4, del que ya había una versión parcial en r2 (N-B1). Todos los bloqueantes de rondas anteriores siguen cerrados: C-B1…C-B3, N-B1, B-1, C-W6, C-W8 y los 11 del lote Feature 1.

### Required actions before re-running
1. **E4-1:** definir en 1 la operación general sobre la pila para «Nueva partida»/«Continuar» aceptadas desde cualquier forma de la pila (con o sin `menú` encima), alinear 4 y 21 y dar AC firmes; cerrar la «propuesta» D22.
2. Unificar W-1 (5), W-2 (2), W-3 y W-4 (dependencias y duras/blandas), W-5, W-6, W-7 (textos desfasados y «19 hechos»), W-8 y W-9 (`BOX_OPEN_MAX`, `BOX_Cn_OPEN`).
3. Decidir cómo se presupuesta el tiempo del slice (W-10): añadir al marco de puzles un presupuesto total con las escenas, la llamada y la exploración, o corregir «dentro de 25–30 min».
4. Re-ejecutar `/review-all-gdds since-last-review`.

---

## Cobertura (qué no se pudo revisar)

**NOT ASSESSED:**
- **Sin leer por ningún revisor:** F1–F4 y reglas 13–16 y 20 de 1; F1/F2 y regla 9 de 4; reglas 7a y 11 de 5 y ACs 18b/c; reglas 4, 18 y 24, F9/F10 y ACs de 2 (casi); reglas 14, 27 y 29 y AC-47 de 9; Edge Cases, tabla de objetos y ACs de 7; ACs de 8, 10, 18, 19, 20 y 21 (2f no hecho para estos); filas 11–17 del índice; el registro solo parcial (`volume_*`, `rotate_mouse_gain`, `player_*`); el slice leído solo por secciones.
- **Escenarios:** E6 (llamada) no recorrido; N2, N3, N4, N5, E1, E3, E4, E5 y E7 parciales. 22, 23, 24, 25, 27 y 28 sin GDD.
- **NOT SOURCEABLE:** `AnimationPlayer`/`SceneTree.paused`/`AudioStreamPlayer`/`Area3D`-Jolt.
- AC-36 y AC-38c no localizados en 4.
