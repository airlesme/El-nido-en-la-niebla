# review-R14-D · Fase 3 (atención, pilares, fuerza bruta/pistas, tiempos, accesibilidad) · informe final

Alcance real: leídos 17 (R1-40, F1-F3, Edge Cases 1-19, Decisiones, OQ), 30 (casi entero), 25 (R1-29), 26 (R1-29), 27 (R1-30 + OQ), 28 (R1-25 + OQ), 23 (Overview, Fantasy, R36-45, OQ), 24 (R1-20), 29 (R1-12), slice §4/§10/§14/§16/§19/C.4/C.7, r9, índice, pilares, concepto.

## BLOQUEANTE
Ninguno. (Candidatos A1, A4 y A15 degradados a AVISO porque los 9 GDDs los registran como pregunta con defecto y no cierran tono/alcance sin marcarlo.)

## AVISO
- A1 [17 R11.3, D17-4 / 30 D30-8 / 17 OQ3 / 30 OQ1] La espera 20/40 s decide cuándo hay pista; pilar 4 (prioridad 1) lista como violación «Un temporizador que decida por el jugador». 17 OQ3 remite a 30 («Usuario / accessibility-specialist (30)») y 30 OQ1 remite a 17 («Usuario, 17»); ambos con defecto «sin opción»: lazo sin dueño. Fricción real (R11.3): pedir -> reanudar -> jugar el gap -> volver a pausar. Pregunta para el usuario, no decisión.
- A2 [17 R10 «Pips»] N puntos rellenos por puzle = indicador visible de ayuda usada; roza anti-pilar «NOT medidores» (D17-17 lo niega). OQ10 solo lo trata como spoiler (P6 = 2 niveles), no como medidor. Cortable (OQ11).
- A3 [17 R25 cuaderno, R13 repetir, R5 lista] El panel de pistas es un menú de ayuda con registro releíble; slice §10/§16 solo pide «pistas en tres niveles en el menú de pausa». 17 OQ11 lo marca «cortable» y lo eleva: bien. Riesgo para «No hay menú de inventario» solo si se acepta; decisión del usuario.
- A4 [17 Edge Case 5] Tras cargar a mitad de P4/P2 el panel muestra «Nada pendiente.» (`UI_PISTAS_NADA`) aunque el puzle esté activo, hasta reabrir la vista/primera acción: afirmación falsa al jugador atascado; sin bloqueo pero fricción para quien vuelve tras cerrar el juego. Aceptado en D17-5/D17-6.
- A5 [17 R17/OQ1, pilares P3 «Violating»] P3 nivel 3 automático (60 s) y P6 niveles 1-2 (10/20 s) rozan «Escenas que resuelven el puzle por el jugador». Vienen del Anexo B (decisión del slice); 17 OQ1 lo eleva, defecto (a) mantener. OK como pregunta.
- A6 [28 R9 / 28 OQ8] El parpadeo de C03 pasa de «3 veces, 0,15 s cada vez» (slice C.4, ≈0,45 s) a 1,15 s por defecto (pausas 0,35 s). Cambia contenido literal de escena 4 (~+0,7 s en la escena; irrelevante para F9) aplicado «por defecto». Registrado con OQ8 (decide el usuario). Verificar que 21 (ESC4_PASILLO_MEGA) y C.4 se ajustan al decidirse.
- A7 [28 R8/R18 vs slice C.7] Con `reducir_sobresaltos` el apagón cae en 0,8 s† (no 0,4 s) y suelo de ambiente 0,10: también reinterpreta C.7 («fundido 0,4 s»); además 28 R8 impone suelo `ambiente_apagon` 0,06† (OQ7 lo pregunta; C.7 dice «completo»).
- A8 [30 R19, 28 R9/R18, slice §14] El slice §14 define `reducir_movimiento` solo para «feedback de error y cortina de carga»; 30 R19/28 R9/R17 lo extienden a LUCES_PARPADEO, reflejo retardado y lluvia, y 28 usa además `reducir_sobresaltos` para el mismo parpadeo y el apagón. Dos claves sobre el mismo estímulo (con ambas manda 0,6 s, R9): el jugador fotosensible no sabe cuál activar. Coherente internamente (D30-12), pero la extensión de §14 no figura como pregunta.
- A9 [30 R1, D30-1, OQ8; índice «preguntas de alcance pendientes»] 30 propone nivel «Estándar» (por encima del Básico que exige slice §14/§16) y OQ8 lo eleva (bien), pero a la vez «cierra PA-3 de 19» (regla 8, D30-4) y fija `escala_texto_ui` que el índice mantiene como pregunta de alcance sin decidir. 12 -> 18 claves en 6.
- A10 [25 R18 y Overview vs 30 R2/R6/AC-30-02] 25 sigue con 12 claves y sin `escala_texto_ui`, `icono_grande`, `etiqueta_accion_visible` en Accesibilidad; 30 lo pide como cambio requerido, sin propagar. AC-25-12/-23 y AC-30-02 compiten por el orden.
- A11 [25 R13 (7:1, D25-22) / 26 R18 (7:1) / 30 AC-30-04 (4,5:1, 3:1)] Tres umbrales de contraste para UI; 30 «mide» 4,5:1. Unificar.
- A12 [28 R11 (≥10 % luminancia, 0,35 s) / 29 R5 (>0,25 en 333 ms) / 24 R17 (340 ms, «25 % del campo») / 30 AC-30-13 (≥10 %, área >25 %)] Cuatro definiciones de «destello». Para el tope de fotosensibilidad 30 verifica con la de WCAG; 29 usa una más laxa (0,25) y declara que no lee `reducir_sobresaltos`.
- A13 [29 R12 vs 28 R13] Contradicción: 29 R12 dice que 28 posee el reflejo de `B04` (proxy alimentado por `pose_con_retardo`); 28 R13 dice que 28 no entrega nada a `B04` y que P2/P5 nunca usan `pose_con_retardo`. Ambos remiten a «confirmar con 28». Afecta a la legibilidad del P2 (pilar 3/D-W2). Lo resuelve el revisor de consistencia; lo dejo anotado.
- A14 [26 R3 «[Llanto contenido]» vs 26 R3 «nunca su causa ni su significado»; slice C.7 «respiración rota»; 18 OQ11, 22 OQ5] El ejemplo de subtítulo para `SFX_BREATH_BROKEN` nombra una emoción/causa («llanto»). Texto del writer, pendiente. Pregunta de tono (pilares 2 y 5), no decisión.
- A15 [27 R2] El título lista los cinco temas del slice §17 antes de jugar («decepción afectiva», «llanto contenido», «dinámicas de control y de desigualdad…»). Es mandato del slice; 27 omite la promesa de contenido (OQ8), créditos (OQ7), «Avisos de contenido» y versión de compilación (OQ9) y los marca «decide el usuario»: bien. Pregunta de tono: lista literal o categorías.
- A16 [28 R20 LLUVIA_REALCE en `formulario_leido` (+3 dB en 23)] La atmósfera subraya el hallazgo del formulario; permitido por pilar 2, roza «NOT una historia explicada» si el jugador lo lee como «esto importa». Nunca confirma intención. Valor †; pregunta para el art director.
- A17 [30 AC-30-08, OQ5; 22 OQ10] Completar el slice solo con mando choca con el cursor oculto en la llamada (decisión del usuario, respetada). 30 lo reconoce: limitar el AC o decidir una señal. 
- A18 [30 Historial 0.1] Dice «No se ha leído el GDD de 28» pero cita 28 R9/R11/R17/R18 y «verificado en 28 regla 18»: estado de verificación inconsistente.
- A19 [25 Player Fantasy: Submission y Expression; game-pillars: Submission «N/A»] 25 sirve a Submission («descanso sin presión»); los pilares lo marcan N/A y el concepto lo coloca en «tensión central, no es un juego de relajación». Matiz pequeño. Mismo patrón que D-W8 (estética no alineada con el ranking de pilares).
- A20 [23 R41 `pause_closed` vs 25 R3 / 26 R5 «pausa cerrada»] Nombre del aviso distinto. Menor.

## INFO (comprobado, sin hallazgo)
- 3a progresión: no aplica tras comprobar (sin XP/economía/combate; 17 R37 sin contador, logro ni hecho; D17-17).
- 3b atención (>4 sistemas con ACCIÓN simultánea): ninguno. Llamada: la única acción es elegir opción (22); 23 voz, 26 subtítulo, 28 sin acción tras el apagón (R8 «no hace nada más»), 24 oculto en `llamada` (24 R2, 26 R24), 17 sin nada que aplicar (17 R39). Apagón y sillas: solo caminar; 28 ya cae a 0,4 s. Revelación P5: la entrada solo admite `atrás`; 15+29+28 (pulso 1,0 s, R19c)+23+26 son salidas, no acciones. Pausa congela 26 (R25), 28 (R22), 23 (R41), 17 (GameClock).
- 3c fuerza bruta de 17: no rompe puzles. Escalera sin saltos (R10, D17-2), gap 20/40 s (F1), P6 sin pista que señale opción (R31), `AUTO_SOLVE_ELEMENT` solo T1 y «Ninguna pista decide T4» (R30), «Repetir» no reejecuta `AUTO_SOLVE` ni `evaluate()` (R13), sin tope (castigo evitado, D17-4). Pedir todas las pistas: degenerada pero legítima (Edge 16, pilar 3). Riesgo medible: T_min(3)=60 s = 67 % del mínimo de P3/P5 (F3); criterio 5 (≥50 % sin nivel 3) en playtest.
- 3e tiempos: 17 (≤60 s al rehacer la escalera tras cargar, R36), 25 (pausa; reloj detenido), 27 (tarjeta 3,0 s†, créditos una página sin tiempo, OQ7; advertencias esperan «Entendido» sin tope, previas a la partida) no añaden minutos a F9 (mín ≈14,8, techo ≈33,1; suelo real ≈10,7). Condición: AC-X5 debe fijar que el cronómetro empieza en «Nueva partida» y termina en «tarjeta final pedida». 28 A6 añade ~0,7 s a la escena 4, no al F9 de los puzles. Las notas A1-A4 de r9 no se re-verificaron.
- 3f «Tensión sin castigo»: 25 R2/R5/R28 (pausa siempre, cierre guarda, único aviso grave cuando hay pérdida real con guardado en riesgo, R28); 27 sin penalización; 30 R13/R18. Ningún cierre o título pierde progreso salvo guardado en riesgo (marcado).
- 3f «No hay menú de inventario»: 25 raíz = Continuar/Pistas/Sonido/Accesibilidad/Controles/Salir; 24 sin inventario (R8 no explica por qué algo no está disponible); `repasar_bolsillo` solo aparece como leyenda de texto en Controles (25 R20).
- 3f «NOT historia explicada»: 26 R29 sin historial, «no revela información que el audio no diga»; 23 sin audio descriptivo (R40, «Autonomía: sin hueco»); 17 R38 nunca confirma intención; 29 R3 sin información extra; 28 R8 sin silueta ni sombra extra. Salvo A14 y A16.
- Pilar 1: 17 sin nada moral; 23 `SFX_STAMP` igual al aceptar y devolver; 29 sin rojo/verde.
- Las tres decisiones de tono marcadas: lluvia en el apagón (23 OQ1 = 28 OQ1), saturación de la voz del Guardián (23 OQ10 retirada por defecto), parpadeo/luz de emergencia (28 OQ2/8), créditos (27 OQ7). No encontré tono o alcance decididos sin marcar, salvo la extensión de `reducir_movimiento` (A8) y `escala_texto_ui` (A9).
- Decisiones del usuario respetadas: P6 con dos niveles (17 R31), `repasar_bolsillo` (25 R20), B.1 literal (17 R32 / F2 `PISTA_P1_N2`), cursor oculto en la llamada (A17), respuesta definitiva/repetible, no colgar.

## ESTADO D-W (textos actuales)
- D-W1 (P1 24 permutaciones): vigente; 17 no la agrava (P1 N1 solo resalta `V08`, R32; N2 «Ordena por hora de envío»).
- D-W2 (P2): abierta (Q12-1); 17 R18 sin `IDLE` para P2; N2 `FLOOR_MARKS` persiste (R33). A13 afecta a su legibilidad.
- D-W3 (P5): aceptada; 29 R3 refuerza que no hay brillo cerca de θ*. Criterio 5 sigue en riesgo por T_min(3)=60 s.
- D-W4 (pistas sin información nueva): vigente y ampliada: 17 Edge 10/D17-7 (P4 N1 `ALWAYS` repite la regla visible) y P1 N2 repite el pie de B.1.
- D-W5 (P6 elegir antes de 10 s): vigente; la nota automática N1 «Solo puedes elegir una vez» sale a los 10 s (17 R17); quien elige antes no la ve.
- D-W6: cerrado.
- D-W7: parcial. 26 R2 hace obligatorio `SUB_BREATH_BROKEN` (mecanismo cerrado); el texto sigue pendiente del writer (18 OQ11, 22 OQ5, A14).
- D-W8 (fantasía del marco prioriza Challenge/Discovery sobre Narrative): vigente (9, línea 26 del Player Fantasy); 17 repite Discovery/Challenge y 25 añade Submission/Expression (A19).
- D-W9, D-W10 (P4: `VO_G_14_ASG`, T4 poco percibido): no re-verificados (14/22 fuera de mi lectura); 17 R30 coherente («ninguna pista decide T4»).
- D-W11 (tiempos): vigente; sin cambio por 17/25/27.

## NO LEÍDO
17 (Acceptance Criteria, Datos, Cambios requeridos, Registro); 23 (reglas A-G, fórmulas, AC, datos, Decisiones); 24 (reglas 21 en adelante); 25 (Formulas, Edge Cases, AC, Decisiones, OQ); 26 (Formulas, Edge Cases, AC, OQ); 27 (Formulas, Edge Cases, AC, Decisiones); 28 (Formulas, Edge Cases, AC, Decisiones); 29 (reglas 13 en adelante); 30 (texto de UI); slice §12, §13.3, §22, Anexo B, C.8; GDDs 1-16 y 18-22 salvo citas; r8.
