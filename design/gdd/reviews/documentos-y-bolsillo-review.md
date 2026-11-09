# Review independiente GDD 20 «Documentos y bolsillo» (lote Feature 1)

## VEREDICTO: NEEDS REVISION
Las 8 secciones están completas y la arquitectura (bolsillo derivado de hechos, sin softlock) es sólida y coherente con 2, 3, 5, 7 y 9. Hay 2 bloqueantes de contrato, ambos corregibles sin rediseñar: una referencia inexistente y un contrato con 8 que ya existe como GDD y no dice lo que 20 le atribuye.

## BLOQUEANTES

B1. Contrato con 8 (control-de-acceso.md) mal planteado y contradictorio.
- Dependencies de 20: «8 Control de acceso (sin GDD) | Dura | `sostener_item(id)`, `guardar_item()`, `otorgar("A05")`» y Cambios requeridos «8 Control de acceso (futuro)».
- 8 YA existe (índice fila 8: «Borrador (lote Feature 1)») y NO define `otorgar`, `sostener_item` ni `guardar_item` (Grep sin resultados). 8 tampoco tiene a `A05` entre sus objetos (solo lo cita en la regla 18f y en su intro).
- 8, Pregunta abierta 3 y su Cambios requeridos a 7 (d): proponen que 7 pase `tarjeta_item` a `HAND_CARD_SWIPE`, es decir, el gesto muestra la tarjeta. 20 R16 propone en cambio que 8 llame a 20 para `sostener` la tarjeta. Son dos mecanismos incompatibles; con ambos se dibujaría la tarjeta dos veces.
- Además nadie es dueño de `interact()` de `A05`: 7 (tabla, fila cajones) dice «DELEGAR … 8 (A05) · 20 (contenidos)»; 8 no lo asume y 20 solo define A03/A04 (R15). Sin dueño, `otorgar("A05")` (R8) nunca se llama.
- Falta: reconciliar con 8 (quién abre A05, quién llama a `otorgar`, quién muestra la tarjeta en el swipe) y corregir «sin GDD/(futuro)».

B2. Referencia inexistente: Edge Cases, «`atrás` pulsado mientras hay una petición aplazada»: «`RECHAZADA` (7, E2-1)». En 7 no existe «E2-1» (Grep: solo aparece en design/gdd/gdd-cross-review-2026-11-09-r2.md:89 y en este GDD). La regla real es 7, regla 27b (tabla: «ya hay una petición aplazada → RECHAZADA»).

## AVISOS

A1. Inconsistencia interna R22 vs R6/F2: R22 «El primer repaso … empieza por el último de la lista (`I-07` si está)»; R6 y F2 ordenan `I-07, I-05, I-06a, I-04` y `i_siguiente = 0` con cursor ninguno, es decir `I-07` es el PRIMERO. AC-11 sigue F2.

A2. Contradicción con R3/R27 y el pilar «Información incompleta»: Tuning Knobs `repaso_orden`: «Prioriza lo que se necesita para la llamada (carta)» frente a R3 «no … ordena por importancia». Reformular como orden fijo neutro (D20-9 ya lo justifica por datos).

A3. Pregunta ya resuelta por 7: Cambios requeridos a 7: «Confirmar que 7 devuelve ‘lectura abierta’ también tras ACEPTADA o solo tras APLAZADA». 7, regla 27b y regla 29: «lectura abierta (ID de documento; solo si estaba aplazada)». R20 ya es coherente; borrar la duda.

A4. 9, regla 35 vs Dependencies de 20: 20 dice que 9 hace `abrir_lectura(I-07)` «en la reapertura (regla 35: on_reopen)». 9 regla 35: `on_reopen` → `SIN_EFECTO`; la carta se relee «desde el bolsillo con abrir_lectura(I-07), petición a 20/7 independiente de la vista» (y D9-23, AC-42). Lo llama 20 (vía R18), no 9. Reciprocidad a corregir.

A5. 19 (ordenador-correo-impresora.md) existe (Borrador) y se cita como «sin GDD». En lo leído, 19 no define `otorgar_sesion("I-01")` (R24 solo dice «entrega I-01»), define `DOC_I01` (R20) y dice que la vista de `C05` «lee las referencias de I-01 a través de 20» (R27). 20 no tiene interfaz ni fila en R2 para el contenido de `I-01` (la tabla de contenido omite I-01) ni cómo 9 lo lee. Hueco de contrato.

A6. Q1 / Entrada: Entrada, tabla de contextos, `exploración` = `mover, mirar, interactuar, pausa` (sin `atrás`). R18 añade `atrás` en `exploración`; está declarado (Q1, Cambios requeridos a 1, D20-8). Aun así los AC-11, AC-12 y AC-14 y la relectura de la carta (9, AC-42) dependen de una Q1 decidida por defecto en «Sí». Anti-pilar: el slice D.1 dice «No hay menú de inventario»; `atrás` sin pantalla de selección no es un menú (OK). Ojo: «No hay menú de inventario» está en slice D.1, no en la lista de Anti-Pillars de game-pillars.md (3 anti-pilares: combate, medidores de moral, historia explicada); game-concept.md no contiene «inventario». Riesgo menor: clic derecho/botón este accidental abre lecturas; sin coste, pero 7 regla 29/Entrada deben aceptar el cambio de rol de `atrás`.

A7. Guardado: R24 y Edge Case 1 («Se cierra el juego tras leer el formulario … se pierde a lo sumo `t_periodico` (120 s)»). 5 (tabla de causas) incluye `quit` y lista `formulario_leido` entre lo que cubre; el riesgo es solo cierre forzado. Matizar. El valor 120 s no se pudo verificar (ver NO LEÍDO).

A8. R12 solo pide `sostener`. 2, regla 24: `HAND_HOLD_ITEM` «exige un objeto sujeto en esa mano» y hay que pedirlo aparte. Falta especificar si 20 lo pide (pose de la mano). También: `abrir_lectura` acepta `HAND_READ` (izquierda) mientras la tarjeta está en la izquierda; R12 dice que se aborta, pero no fija quién llama a `reposo()`/`soltar()` primero.

A9. R18 (solo si `exploración` estable) frente a R20 (`APLAZADA` posible): `APLAZADA` solo ocurre con transición o gesto bloqueante (7, 27b), que R18 excluye. No es contradicción grave, pero el caso se vuelve casi inalcanzable; AC-12 lo ilustra mal.

A10. R23 vs AC-18: R23 dice que «ya mostrado» es de sesión y «si se vuelve a ver tras cargar, es inocuo»; AC-18 exige «una sola vez … en la sesión». Alinear.

A11. `repaso_cerrar_ciclo = false` («se detiene en el último») no está en R22/F2. Clasificar `repaso_orden` como «Curve» es dudoso (Feel/Gate).

A12. ACs: AC-12 mezcla dos escenarios en un GIVEN/WHEN/THEN («WHEN … RECHAZADA; WHEN 7 devuelve APLAZADA»): separar. AC-16 (PV, 5 jugadores, ≥4) y AC-17 («creíble») son subjetivos; AC-18 es lógica verificable pero tipado PV. AC-05 tipo «L + I»: separar. No hay AC para R15 (`t_tapa_s` no bloquea), R4 (no se puede perder/tirar) ni R12 «sin sonido de recompensa».

A13. Valores sin fuente: `t_mostrar_item_s` 0,7 s† y `t_tapa_s` 0,6 s† (marcados † = propuesta, OK); F1 resultado 2,6 s depende de ellos; «< 10 s» (F2, peor caso) sin marca; «≤ 90 palabras la carta» (Edge Cases) sin fuente verificada; AC-16 «cinco … cuatro» sin marca. `t_item_dentro/fuera` 0,3 s y rango 0,15–0,6 coinciden con 2 (tuning). `aplazada_tope_s` 3 s y `lectura_min_s` 2 s† coinciden con 7.

## INFO
- Cálculos F1 recalculados: n=2 → 2×(0,3+0,7+0,3)=2,6 s ✓; n=1 → 1,3 s ✓. F2: rango 0–3, m máx 4 ✓; ejemplos ✓.
- Propiedad de hechos: tabla de 3 (formulario_leido, tarjeta_B, tarjeta_D = 20; caja_c1/c2/c4 = 9) coincide con R25. 8 los lee y dice «8 no escribe»; 10 (AC-19, regla 18) no consulta `has_item` ni escribe ítems; 21 lee `formulario_leido`. Coherente. Los hechos van marcados ‡ en 3 (20 debe confirmarlos: esto lo hace este GDD).
- Contratos verificados OK: 2 regla 24 y D-34/35 (quién llama a `sostener`, rechazo sin reintento, `t_item_*`); 7 regla 16, 17, 18, 27a, 27b (tabla), 29, A03/A04 en tabla; 9 reglas 34, 35, D9-23, D9-33, AC-39b, AC-42; 5 causa `card_acquired` (AC-04b, D-24, D-29) y fila 327; 8 (tarjetas no se gastan, D8-01) coincide con R16/D20-3.
- 10, Pregunta abierta 1 (¿NOTA_01 cogible?) interactúa con Q2 de 20 y R8 («no escribe nada»): vigilar al cerrar el lote.
- Índice fila 44: depende «3, 7, 18 (blanda: 2)»; el borrador pide añadir 1 y 9 (ya en Cambios requeridos). El nombre del índice es «Documentos y bolsillo visual».
- Godot 4.7: el GDD no hace afirmaciones de API; nada NOT SOURCEABLE.
- Pilares: sin softlock ni castigo posible (D20-1, D20-2, D20-3, I-01 reimprimible); R3/R27 respetan «NOT una historia explicada» (salvo A2). Q1 y Q2 están marcadas como preguntas abiertas; decisiones de alcance no ocultas.

## NO LEÍDO / NO COMPROBADO
- game-concept.md entero; design/registry/entities.yaml; 24 Prompt; 21 (solo líneas de coincidencia).
- 18: reglas 1, 10, 21 y la existencia de claves del formulario/lista/`UI_BOLSILLO_AYUDA` (solo vi la definición de documento en la línea 31).
- 3: numeración exacta de las reglas 2, 4, 9, 12, 13, 15 citadas (comprobé la tabla de hechos y CA-03).
- 5: valor `t_periodico` = 120 s; regla 14 solo vía causa `card_acquired`.
- 7: texto de la fila `A05` (solo vía la cita de otros GDDs) y de la regla 13 (sostenibles = `V05`, vía D7-29).
- 19: lectura completa (la ausencia de `otorgar_sesion` viene de un Grep con límite de resultados; confirmar).
- 8: lectura completa (la ausencia de `otorgar/sostener_item/guardar_item` es por Grep).
- Slice A.4/A.5/A.6 y C.3/C.6 (solo D.1, D.2 y tabla de objetos A03–A05).
