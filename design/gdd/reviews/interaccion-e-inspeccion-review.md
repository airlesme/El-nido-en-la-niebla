# Revisión de diseño: Interacción e inspección (sistema 7)

- **Documento revisado:** `design/gdd/interaccion-e-inspeccion.md` (52 KB, leído entero por rangos: la guarda de 40 KB impide la lectura de una sola vez y el documento se necesita completo para contrastar reglas, fórmulas y ACs).
- **Fecha:** 2026-11-09 · **Revisor:** independiente (no autor), modo lean, sin especialistas.
- **Workflow:** `standard` (`project.yaml`: `modes.workflow` sin `system_overrides` para este sistema). Se exigen 5 secciones + Formulas (el sistema define umbrales, tiempos y distancias).
- **Contrastado con:** `design/slice/slice-v0.3.md` (§5, §16, A.0, A.2 a A.7, B.1 a B.3, B.5 a B.7, C.3, D.1, D.2), `design/gdd/systems-index.md`, `design/gdd/game-pillars.md`, `design/registry/entities.yaml`, `entrada-y-controles.md` (reglas 1 a 14, F6, F8, Open Questions), `jugador-en-primera-persona.md` (reglas 16 a 24, estados, Visual/Audio) y su revisión `reviews/jugador-en-primera-persona-review.md`, `estado-y-bus-de-eventos.md`, `base-de-contenido-narrativo.md` (reglas 1 y 3), `escena-de-planta.md`, `marco-de-puzles.md` (contrato con 7), `docs/engine-reference/godot/`.
- **Re-review:** No, primera revisión (no existe `interaccion-e-inspeccion-review-log.md`).

## Veredicto: NEEDS REVISION

El diseño es coherente con los pilares y con el slice en lo esencial (una sola tecla, mirar antes de tocar, sin castigo, `atrás` siempre cierra) y las seis fórmulas cuadran al recalcularlas. Lo que impide pasarlo a programadores son cuatro puntos: una contradicción interna en la detección del objetivo (regla 5 frente a F1/AC-04), contratos con el Jugador (2) y Entrada (1) que no se han reconciliado, una interfaz incompleta hacia 9/10 (abrir y cerrar vistas), y un catálogo cuyo esquema y cobertura no coinciden con el slice. Ninguno exige rediseñar; todos se arreglan en el documento.

## Completitud (workflow `standard`: 6/6 requeridas presentes)

| Sección | Estado |
|---|---|
| Overview | Presente |
| Detailed Rules (`Detailed Design`) | Presente (29 reglas + estados + interacciones) |
| Formulas (F1 a F6) | Presente. Variables y ejemplos en todas; F1 omite `prioridad` en su tabla |
| Edge Cases | Presente, bien estructurado por modo |
| Dependencies | Presente; faltan dependencias (ver H-13) |
| Acceptance Criteria | Presente (37 AC + 3 de experiencia). Sin ningún AC de evidencia **V** (ver H-12) |
| Player Fantasy, Tuning Knobs | Presentes (consultivas en `standard`) |

`gdd-structure-check.sh` informa de las ocho secciones PRESENT y ninguna ABSENT ni PLACEHOLDER.

## Grafo de dependencias

- Declaradas: 1 `entrada-y-controles.md` existe · 2 `jugador-en-primera-persona.md` existe · 18 `base-de-contenido-narrativo.md` existe · 3 `estado-y-bus-de-eventos.md` existe.
- Aguas abajo: 9 `marco-de-puzles.md` existe y lista a 7. Sin GDD aún: 8, 10, 19, 20, 21, 22, 24, 23, 28 (no es un fallo, pero cada uno debe adoptar el contrato de la regla 3 y las operaciones que se añadan por H-04).
- **Bidireccionalidad:** 1, 2, 18 y 9 listan a 7. **3 no lo lista** (no aparece en su regla 10 ni en su tabla de interacciones; el GDD de 7 afirma que «lo trata como indirecto», lo cual no figura en el GDD del 3). **4 (Escena de planta) no lista a 7** y 7 tampoco lista a 4 (ver H-13).

## Valores del registro

Búsqueda sobre el documento de `alcance_interaccion_m`, `player_fov_vertical_default_deg`, `lock_max_s`, `long_press_threshold` y los valores equivalentes (`1,8`, `70°`, `0,5`, `2,0`, `3 s`).

- `alcance_interaccion_m` = 1,8 m: coincide (propietario: este GDD; la «Propuesta de registro» lo vuelve a proponer aunque ya está registrado).
- FOV vertical 70°: coincide con el registro y con el slice A.0. El GDD lo marca ‡ y reconoce que el eje no está especificado (bien; ver H-08).
- `t_hold` = 0,5 s: coincide con `long_press_threshold` (Entrada); el GDD usa otro nombre sin remitir a la clave del registro (menor, H-20).
- `lock_max_s` = 2,0 s: el registro dice `referenced_by: [interaccion-e-inspeccion.md]`, pero **el GDD no lo menciona** (0 apariciones). O el GDD debe usarlo (la validación de `bloquea_s` y de las esperas del receptor) o el registro está mal (H-14).
- `pick_min_px`, `radio_apuntado_m`, `lectura_min_s_A04` y `t_vista_entrada_D01a_s` figuran en la «Propuesta de registro» pero no están en `entities.yaml`; `pick_min_px` ya lo cita el Marco de puzles.
- Sin conflictos de valor con el slice en los números comprobables (0,35 m; 1,0 s; 0,8 s; 2 s; 0,5 s).

## Hallazgos

Severidad: **B** bloqueante (hay que resolverlo antes de implementar) · **I** importante · **m** menor.

### Bloqueantes

**H-01 · B · La regla 5 contradice a F1 y a AC-04 (detección del objetivo)** · regla 5 (l. 42), F1 (l. 156), AC-04 (l. 369), tabla de objetos (B05, l. 132)
La regla 5 dice que «cuenta el **primer** contacto del barrido», y a continuación habla de «varios interactuables a menos de `desempate_prof_m`». Con un solo primer contacto no hay varios candidatos: `B02` (1,10 m) siempre sería el primer contacto y `B05` (1,12 m) nunca competiría, así que AC-04 («el objetivo es `B05`») no se puede cumplir con el algoritmo descrito. Implica otras tres cosas sin resolver:
1. El barrido debe devolver **todos** los contactos dentro de una ventana de profundidad. Hay que decir cómo se obtienen (barrido + consultas adicionales) y con qué máscaras, porque la geometría ocluye pero los interactuables compiten entre sí.
2. **Objetos planos sobre una superficie** (la nota `B05`, el formulario `A04` sobre la caja, el libro `R01`): una esfera de 6 cm toca a la vez la mesa y el objeto, así que la mesa los ocluye en el primer contacto. Hace falta una regla de oclusión con tolerancia (la geometría solo ocluye si está más cerca que el objeto por más de `desempate_prof_m`) o colliders de interacción elevados.
3. **`B05` frente a `B01`–`B03`:** el slice (A.5) pone la nota «bajo la base de la lámpara C», y B.2 hace de **la base** de la lámpara el punto de pulsación. Con `prioridad` 2 para `B05`, apuntar al borde de la base donde asoma la nota da «Leer» en vez de «Girar», y el puzle 2 depende de esa lámpara. Falta decir dónde está el collider de `B05` respecto al de la base y añadir un AC de que `B02` sigue siendo alcanzable en toda su base útil.
Además, la regla 2 fija `prioridad` = 0 por defecto, pero AC-04 y el ejemplo de F1 hablan de «prioridad 1 y 2» y la tabla no da prioridad a `B02`; y F1 no declara `prioridad` en su tabla de variables.
*Arreglo:* reescribir la regla 5 como: (a) barrido de esfera con la máscara de geometría y de interactuables; (b) recolectar contactos hasta `alcance`; (c) descartar los ocluidos por geometría más de `desempate_prof_m` antes que ellos; (d) aplicar prioridad y distancia al eje. Declarar `prioridad` en F1 y dar a `B02` su valor en la tabla. Añadir AC para objeto plano sobre mesa y para el alcance de la base de `B02`.

**H-02 · B · Contrato con el Jugador (2) sin reconciliar: dos fuentes para el regreso de cámara, rayo, manos y FOV** · reglas 5, 13, 19, 23; F4; AC-31; Dependencies (supuestos A1 a A4); Visual/Audio; Open Questions 1 y 2
El GDD del Jugador ya existe y su revisión (`jugador-en-primera-persona-review.md`, H-02 y H-09) lista los desajustes del lado de 7. Desde el lado de 7:
1. **Regreso de cámara:** 7 define `t_vista_salida_s` (0,6 s, 0,3–1,0) y AC-31 exige 0,6 s; el Jugador tiene `t_devolver` fijo de 0,5 s y `devolver_camara(propietario)` sin parámetro de duración. AC-31 y el AC-20 del Jugador se contradicen. Además F4 duplica la curva (smoothstep) que ya implementa el Jugador.
2. **Quién mantiene el contexto durante el regreso:** el Jugador queda en Cámara cedida y descarta `mover`/`mirar` durante `t_devolver`, y la regla 23 dice que Entrada «devuelve el contexto anterior» sin precisar cuándo. Hay que fijar que 7 conserva el contexto bloqueante hasta el aviso de «cámara devuelta» del Jugador (propuesta del review del Jugador).
3. **Origen del rayo (A1):** la regla 5 lanza el barrido «desde la posición de la cámara»; el Jugador (regla 19, D-16) exige los **ojos sin balanceo**. Con balanceo `completo` el icono parpadearía. Usar el servicio de rayo de visión del Jugador.
4. **Ocultar manos (A3):** 7 (l. 142, 271) espera «ocultar/mostrar manos»; el Jugador dice «siempre visibles» y no tiene esa operación (usa `reposo()`/`sostener`).
5. **Nombres de gesto:** 7 usa `ANIM_HAND_OPEN/TAKE/TURN/READ/PRESS` (Visual/Audio y regla 13); el Jugador ya fijó `HAND_REACH`, `HAND_DRAWER`, `HAND_TURN`, `HAND_HOLD_ITEM`, `HAND_READ`, `HAND_POINT`, `ANIM_PAGE_TURN`, `ANIM_PHONE_PICKUP`. La Open Question 2 está obsoleta. Además `sostener(item_id)` del Jugador toma un ítem y `V05` (peluche) no lo es; hay que decir cómo se sostiene un objeto de escena.
6. **FOV (A4) y propietario:** el Jugador no ofrece lectura del FOV vigente (F6 de 7 la necesita); `ceder_camara(propietario, pose, fov_destino, duración)` admite un solo propietario y 7 no dice cuál usa para vista y ordenador (el Jugador menciona también al sistema 19). Definir los propietarios (p. ej. `interaccion:vista`, `interaccion:ordenador`) y el `fov_destino` por vista.
*Arreglo:* adoptar las operaciones reales del Jugador (`ceder_camara`, `devolver_camara` con duración, rayo sin balanceo, `reproducir_gesto`/`sostener`/`apuntar`/`reposo`), eliminar `ocultar manos`, cambiar los nombres de gesto, borrar F4 o reducirla a «curva del Jugador, duración de 7», y cerrar las Open Questions 1 y 2 con la fecha.

**H-03 · B · `bloquea_s` pide `sin control` a Entrada, que no lo permite, y duplica la duración de los gestos del Jugador** · regla 10 (l. 56), AC-13; Entrada regla 6 y F8; Jugador reglas 24 y tabla de gestos
Entrada (regla 6) dice que `sin control` lo pide **solo** el director de escenas (21), con duración declarada y margen de 2 s; las transiciones de cámara y animación se bloquean por la regla 8 con tope de 3 s, sin pasar por `sin control`. Además el Jugador ya marca qué gestos «bloquean el contexto» y su duración (`ANIM_PHONE_PICKUP` 0,8 s; `HAND_DRAWER` ≤ 1,2 s, etc.). Con `bloquea_s` en el catálogo hay dos números para lo mismo y un mecanismo no admitido por Entrada. Tampoco se dice qué pasa con una tecla mantenida durante el bloqueo (Entrada F8: se ignora hasta soltarla) ni si el `sin control` de 7 emite «contexto de entrada cambiado».
*Arreglo:* decidir una sola vía. Propuesta: 7 mantiene un bloqueo de transición (regla 8 de Entrada) desde `interact()` hasta el aviso «gesto terminado» del Jugador, con `bloquea_s` solo como tope de seguridad (≤ 3 s, ≤ `lock_max_s` si procede); si se prefiere `sin control`, añadir al sistema 7 como solicitante en Entrada regla 6 y F8. Quitar el campo duplicado o declararlo «tope».

**H-04 · B · Faltan las operaciones públicas que 9 y 10 necesitan (abrir y cerrar vistas, registrar receptor, declarar elementos)** · reglas 19 a 23, 27; Marco de puzles (Interactions, regla 11, F4); tabla de objetos (`D01a`–`D01d`)
- La tabla dice que los compartimentos son `DELEGAR` y el dueño (10) «abre su vista», pero 7 solo define `ABRIR_VISTA` como efecto de catálogo, no como operación que un dueño pueda llamar. La secuencia del slice (B.3: `BOX_C1_OPEN` 1,6 s y luego cámara a 0,35 m en 1,0 s) exige que el dueño anime y después pida la vista, o que 7 la encadene; hoy no está dicho.
- El Marco (9) espera «peticiones de abrir y cerrar vistas» y ordenar «cerrar la vista con motivo `resuelto`» tras `close_view_after_s`. 7 menciona esa petición solo de pasada («`t_auto_salida_s`», nombre que no existe en el Marco) y no define `cerrar_vista(id, motivo)`.
- No se define cómo se **registra el receptor** de una vista, ni cómo declara un puzle sus **elementos** (formas de hit-test, IDs, posición en la vista) para el picking de la regla 20 ni para la atracción asistida de Entrada (F5b, en píxeles), que necesita las posiciones en pantalla de los elementos. El «picking» no tiene mecanismo descrito (colliders 3D con rayo, proyección a pantalla…); ver también H-08 sobre lo que no se puede sostener con la referencia del motor.
- `abrir_lectura(doc_id)` (regla 27b) existe, pero no su cierre ni su aviso cuando la pide un dueño.
*Arreglo:* añadir a Detailed Rules una subsección «API pública» con las operaciones `abrir_vista(vista_id, receptor)`, `cerrar_vista(vista_id, motivo)`, `abrir_lectura(doc_id)`, `cerrar_modos()`, `get_target()`, `registrar_manejador(id, manejador)`, y el contrato de `ViewReceiver` (`handle_pointer`, `elements()` con hit-shape e ID). Unificar el nombre del cierre automático con `close_view_after_s` del Marco.

### Importantes

**H-05 · I · Contrato del manejador y catálogo incompletos frente al slice** · reglas 2, 3, 8, 25; tabla (l. 120-137); AC-37
- `can_interact()` devuelve `{SI, NO, SIN_EFECTO}` pero ninguna regla dice qué hace `NO` (¿equivale a deshabilitado y oculta el icono? ¿cuándo se consulta, cada fotograma?). La regla 8 solo trata `habilitado_si`. Sin esto, `A04` (dentro de `A03`, que no tiene hecho propio en D.2) y los estados de cajones o compartimentos no se pueden expresar solo con hechos.
- **Etiquetas dinámicas:** el catálogo tiene un único `etiqueta_corto`, pero la tabla da «Encender/Apagar» (`V06`), «Descolgar (solo `vibrando`)» y el slice da estados abierto/cerrado a los cajones. El prompt (24) necesita que el dueño pueda dar la etiqueta según el estado.
- **La tabla no incluye `habilitado_si` por objeto**, que es lo que gobierna qué es visible (regla 8) y lo que prueban AC-06 y AC-37. Los compartimentos `D01b`–`D01d` y los lectores se comportan distinto según se decida «oculto» o «habilitado con `SIN_EFECTO`» (el slice B.5 prevé el entreabierto de 2 cm y 13.3 pide «sin softlock»); la regla 8 pone el criterio pero no se aplica objeto a objeto.
- **Cobertura del Anexo A:** AC-37 exige que «todos los IDs del slice con interacción» estén en el catálogo, pero la tabla omite `B04` (el slice lo lista como interactuable, «Puzle 2»; ¿examinable o decorativo?) y trata `A02` como un objeto con un texto cuando A.4 dice «Inspeccionar cajas (3)» con tres textos distintos (hacen falta tres IDs o una lista, porque `OBJ_<id>` admite un texto por ID). Tal como está, AC-37 falla.
- Las reglas 3 y 6 y Dependencies hablan de **puertas** interactuables; en el slice las puertas se abren por disparador o puzle y la de Recepción «no es interactuable». Si ninguna puerta es interactuable, retirar las menciones; si lo es alguna (Despacho de Vera, `T-…`), añadirla.
- No existe esquema formal de `interactables.json` (el Marco sí da un ejemplo JSON). Los campos «datos del modo que abre» no tienen forma.
*Arreglo:* definir `NO`; añadir `etiqueta` dinámica en el contrato; ampliar la tabla con columna `habilitado_si` y `prioridad`; decidir `B04`/`A02`; dar un ejemplo JSON de tres entradas (una por efecto) y corregir AC-37 para que derive la lista del Anexo A (no la enumere).

**H-06 · I · Histéresis del foco ambigua (regla 7, AC-05) y muestreo del barrido** · regla 7 (l. 50), edge de pulsación (l. 232), AC-05
«Se conserva `t_gracia_foco_s` después de perderlo **y** mientras el rayo siga a menos de `radio_pegajoso_m`» no dice si ambas condiciones se suman (O: retención indefinida mientras el rayo esté a 15 cm del collider, unos 4,8° a 1,8 m) o se exigen a la vez (Y). AC-05 solo prueba el tiempo y cita «ningún otro objeto» sin que la regla diga si un objeto nuevo sustituye al retenido de inmediato. «No se emite pérdida» (AC-05) no corresponde a ningún aviso definido (D7-10 dice que el cambio no viaja por el bus). Con t_gracia = 0,12 s y un paso de física de 16,7 ms, los casos de 0,10 s y 0,13 s caen a 0,6 pasos de distancia: el AC depende del reloj inyectado, no de la regla. Además, el barrido se hace «cada fotograma de física» mientras la cámara se interpola a la tasa de render (Open Question 3 del Jugador, 3D interpolation en `breaking-changes.md`): hay que decir con qué transformación se lanza el barrido.
*Arreglo:* formalizar: retención = (tiempo desde la pérdida ≤ gracia) Y (distancia rayo–collider ≤ pegajoso); un candidato nuevo válido sustituye siempre; AC en pasos de física (7 y 8 pasos) y sobre `get_target()`. Añadir un AC de «sin objetivo → sin cambio de objetivo con otro objeto a < pegajoso».

**H-07 · I · Semántica de `PointerEvent` y de los gestos sin definir en lo que más afecta al puzle** · regla 20, 21; Entrada F6; Marco regla 11
`seleccionar` solo se conoce al soltar (si no fue `agarrar` ni `mantener`, Entrada F6); `agarrar` empieza tras 8 px de movimiento. El GDD no dice sobre **qué elemento** se inicia: el que había bajo el cursor al **pulsar** (necesario, o la pieza se «salta» 8 px) o el del momento del umbral; ni qué `pos_px` lleva el `inicio`. Tampoco qué eventos produce un clic (`inicio` + `fin` en el mismo fotograma, o solo `fin`), ni cómo se entrega `rotar` con ratón (1 px = 0,25°) y con mando (velocidad angular) en `delta`. El Marco los traduce a `CLICK`/`ARRASTRAR`/`ROTAR`/`PULSAR` y depende de esto. Además, Entrada define la acción `leer` activa en `inspección` (tabla de contextos) y 7 no le da uso: o se retira de Entrada o se define aquí.
*Arreglo:* tabla «gesto → fases → elemento → `pos_px` → `delta`» y regla «el elemento se fija al pulsar».

**H-08 · I · Conversión píxeles↔metros (F6) y cursor: unidades del viewport y afirmaciones del motor sin respaldo** · F6 (l. 211-217), reglas 19, 20, 22; Entrada Open Question 13
- F6 define `H_px` como «altura de la ventana en píxeles (1080 de referencia)», mientras que `pick_min_px`, R y `d_arrastre` están en el viewport lógico 1920 × 1080 (Entrada, review). Con el estiramiento por defecto de los proyectos nuevos de 4.7 (`canvas_items`, `expand`; `VERSION.md`/`ui.md`), la altura lógica cambia con la relación de aspecto (por ejemplo 16:10), y el FOV vertical fijo mantiene los metros pero no los píxeles. Declarar que `H_px` es la altura del viewport **lógico** donde viven el cursor y los elementos, y probarlo con 16:9 y 16:10.
- **NOT SOURCEABLE** (la referencia del motor no cubre estos puntos y esta revisión no los afirma): (a) el comportamiento de los barridos de forma (`cast_motion`, `ShapeCast3D`, `intersect_shape`) con Jolt: `docs/engine-reference/godot/modules/physics.md` solo documenta `intersect_ray`; (b) el eje por defecto del FOV de `Camera3D` y `keep_aspect` (el review del Jugador, H-10, lo reconoce igual): F6 y AC-32 asumen FOV **vertical**; (c) cómo situar el cursor real en `cursor_inicial` (la regla 19 lo pone en el centro: ¿`warp_mouse`?) y el cambio de ratón capturado a visible. Hasta que un ADR lo verifique, estos puntos quedan como riesgo y no pueden contar como «implementables sin adivinar».
*Arreglo:* nota explícita «NOT SOURCEABLE» en Open Questions con propietario `godot-specialist`/ADR y plazo (antes de implementar los sistemas 7 y 9).

**H-09 · I · `lectura` apilada sobre `vista cercana` choca con los estados del Jugador** · regla 27b; Jugador States and Transitions
El Marco (P6, Open Question 2) y 7 prevén abrir `lectura` encima de una vista abierta. El Jugador asocia `lectura` con **Congelado** y `vista cercana` con **Cámara cedida**; no define Cámara cedida + `lectura`, ni qué pasa con las manos (`HAND_POINT` → `HAND_READ`). Tampoco se dice qué ocurre con `cerrar_modos()` si hay dos modos apilados (¿cierra ambos o solo el superior?), ni con una vista que se cierra por `resuelto` mientras la lectura está encima.
*Arreglo:* añadir al GDD del Jugador la combinación (acordado en el lote) y en 7 la regla de cierre con pila.

**H-10 · I · Tiempos de la entrada/salida de la vista y rendimiento de la secuencia del slice** · reglas 19, 23, F4; slice B.3
En B.3 el compartimento se abre con `BOX_C1_OPEN` (1,6 s) y la cámara tarda 1,0 s; si se encadenan, hasta la primera acción pasan 2,6 s de bloqueo, justo bajo el tope de 3 s de Entrada (F8) y con el margen de AC-26 ya consumido. Si van en paralelo, el cursor aparece con el compartimento aún abriéndose. El GDD no dice cuál (ver H-04). Conviene fijarlo y probar el peor caso con pausa a mitad (la pausa detiene el tiempo, pero el tope de 3 s es «real» según la redacción de Entrada F6 y «de juego» según 7 F2: Entrada dice «el tiempo es real, no escalado»; 7 dice «tiempo de juego»).
*Arreglo:* declarar la secuencia (paralela o encadenada) en el catálogo de la vista y unificar «tiempo de juego» frente a «tiempo real» con Entrada.

**H-11 · I · Tuning Knobs y fórmulas: valores sin knob o con rango incoherente** · Tuning Knobs (l. 294-316)
- Faltan como knob (o como dato declarado): la máscara de colisión del barrido, `bloquea_s` (por objeto), `lectura_min_s` solo aparece para `A04`, `cursor_inicial` (regla 19), `fov_vista` por vista (F6 lo necesita), `d_arrastre` ya es de Entrada (bien), pero `t_auto_salida_s` (regla 23) no está en los knobs ni existe en el Marco (`close_view_after_s`).
- F3 `θ_fill` = 25° de un FOV vertical de 70° ocupa el 36 % de la altura; Game Feel (l. 331) dice «aproximadamente un cuarto del campo de visión». Corregir el texto o el valor.
- F3: `d_ins_max` 0,6 m con objetos de r ≥ 0,5 m (AC-17 prueba r = 0,5) deja la superficie a ~0,1 m de la cámara; la regla 14 («nunca atraviesa la cámara») solo se cumple si r < `d_ins_max` − plano cercano. Añadir la precondición o limitar `INSPECCION_MANO` a objetos con r ≤ 0,2 m (en el slice solo `V05`, r = 0,104 m).
- `texto_max_caracteres` = 90 se mide en español; otros idiomas cambian la longitud (regla 7 de 18, preparado para traducción). Definir si el límite se valida por idioma.
- F5: el pie no se puede releer ni prolongar; para la accesibilidad (slice §5) añadir un multiplicador de tiempo de texto o dejar el pie hasta la siguiente acción como opción.

**H-12 · I · Criterios de aceptación: faltan los de evidencia visual y varios no son verificables como están escritos** · Acceptance Criteria (l. 361-417); `coding-standards.md` (evidencia UI y Visual/Feel)
- La cabecera define la clase **V** (captura retenida en `production/qa/evidence/`) pero **ningún AC la usa**. Este sistema produce lo que el jugador ve (icono y etiqueta, pie de objeto, objeto en la mano, pantalla de lectura, vista cercana, cursor, ordenador) y el estándar del proyecto exige captura retenida para cambios observables. Añadir al menos: icono sobre `V02`; pie de `D03`; `V05` en la mano; `A04` en lectura; `D01a` en vista cercana con el cursor visible; ordenador abierto.
- AC-X1 cita «≥ 4 de 5 testers; slice §19.1»: el §19.1 del slice trata de completar el slice en 25–30 minutos sin guía, no de ese umbral ni de esas acciones; el umbral lo introduce este GDD y debe presentarse como propuesta (†), no como cita.
- AC-X2: «ruido de 6 px» no se relaciona con `radio_pegajoso_m` (metros) ni con la distancia de 1,8 m; dar el ángulo equivalente o reproducirlo con una entrada simulada.
- AC-05 (ver H-06), AC-20 («legible» sin criterio: definir tamaño en píxeles de la pegatina o lista de comprobación), AC-26 (la rama de 3 s es inalcanzable porque `t_vista_entrada_s` ≤ 1,5 s y el Jugador acota a 3 s: probar con un doble de prueba que no termina), AC-14 (la latencia de 100 ms con reloj inyectado debe expresarse en pasos de física).
- Ausentes: AC del cierre forzado con dos modos apilados (H-09), del regreso de cámara con el contexto bloqueado (H-02), de objeto plano sobre mesa (H-01), de `NO` del manejador (H-05) y del modo «alternar en lugar de mantener» con `leer` (hay edge case, no AC).

**H-13 · I · Dependencias y bidireccionalidad** · Dependencies (l. 264-292), Quick reference
- **Falta el sistema 4 (Escena de planta)** como dependencia: los objetos se localizan por ID dentro de contenedores (regla 4 de 4), la configuración se hace antes de «escena lista» y puede tomar una retención (regla 9, paso 6 de 4), y 7 dice configurarse con «escena lista», aviso que emite el sistema 4, no el 3 (tabla de interacciones, fila 3). Sin la retención, el catálogo podría no estar cargado cuando el telón sube y los primeros fotogramas no tendrían objetivo.
- Del lado del 3: no lista a 7 como emisor de los avisos de la regla 29 (regla 10 del GDD del 3 pide que cada emisor los documente; hecho aquí, pero el 3 no lo recoge) y el texto «el GDD del 3 lo trata como indirecto» no tiene respaldo en ese documento.
- Texto obsoleto: «El índice lista 1, 2 y 18; falta el 3 como blanda» (l. 275). La fila 7 de `systems-index.md` ya dice «1, 2, 18 (blanda: 3)»; solo la lista por capas (Feature Layer, punto 1) conserva «1, 2, 18».
- Cómo se enteran los dueños y 7 de que un hecho cambió (para `habilitado_si`) no está dicho (¿suscripción a avisos de cambio, lectura por fotograma?); AC-06 «en el fotograma siguiente» asume una de las dos.

### Menores

**H-14 · m · Registro:** `lock_max_s` aparece como referenciado por 7 y el GDD no lo usa (o se usa para acotar `bloquea_s`/esperas del receptor, o se corrige el registro). Registrar `pick_min_px`, `radio_apuntado_m` y la fórmula `F6_ppm`; retirar de la propuesta `alcance_interaccion_m` (ya existe).

**H-15 · m · Inconsistencias con el slice y con el propio documento:** el Overview habla de «40 y pico objetos» (el catálogo del slice suma 33 entradas); la regla 25 dice «los tres verbos de etiqueta» y enumera cuatro, mientras la tabla usa nueve etiquetas (Descolgar, Encender/Apagar, Imprimir, Usar, Entrar, además de las cuatro); el Overview y la regla 15 mencionan «coger», pero ningún objeto del slice se coge (los ítems llegan al bolsillo por los dueños, D.1); Tuning Knobs dice «desde la silla», y en el slice la silla es decorativa y no hay acción de sentarse; el slice llama a `R01` «Pasar página» y aquí es `LEER` mantenido más `interactuar` para pasar (decisión razonable, pero conviene registrarla en «Decisiones tomadas»).

**H-16 · m · Complejidad no usada en el slice:** ningún objeto del slice combina `verbo_corto` y `verbo_largo`, pero las reglas 9 y 10 y AC-09 pagan por ese caso (decisión «al soltar» con su latencia). Mantenerlo como capacidad del catálogo está bien, pero no justifica un AC bloqueante en el slice; o se marca «no usado en el slice» o se retira.

**H-17 · m · `leer` en `inspección`, `HAND_HOLD_ITEM` para `A03` y tarjetas (Jugador l. 332):** el Jugador sostiene la caja del traslado y las tarjetas, y 7 las trata como `DELEGAR`/`Abrir`. Aclarar que no son inspeccionables o añadirlas.

**H-18 · m · Estado del modo `ordenador` y Entrada:** Entrada lo describe como «al sentarse al ordenador»; 7 no hay animación de sentarse ni posición; fijar que `V01` solo acerca la cámara (como dice la regla 24) y avisar a Entrada para corregir el texto.

**H-19 · m · Pie de texto sustituido:** «lo que sustituye el pie» (regla 12) permite perder un texto sin poder releerlo; considerar un registro de últimos textos (fuera del alcance del slice) o dejar la nota como Open Question.

**H-20 · m · Nomenclatura:** `t_hold` (GDD) frente a `long_press_threshold` (registro); `t_auto_salida_s` frente a `close_view_after_s`; `ANIM_HAND_*` frente a `HAND_*`. Una sola clave por concepto, citando la del registro.

## Cálculos verificados (sin hallazgo)

- F2: 0,30/0,5 = 0,6; con `t_hold` 1,5 el anillo (0,12 s) aparece con p = 0,08. Correcto.
- F3: r = 0,12·√3/2 = 0,1039 m; tan 12,5° = 0,2217; d = 0,469 m; clamp a 0,25 m (r = 0,02) y 0,60 m (r = 0,5). Correcto.
- F4: s(0,25) = 0,15625; s(0,75) = 0,84375. Correcto.
- F5: 0,5 + 30/14 = 2,64 s; 0,5 + 90/14 = 6,93 s. Correcto.
- F6: 540 / (0,35 · tan 35°) = 2.203 px/m; 0,04 m = 88 px; con 70° horizontal en 16:9 (FOV vertical 43,0°) = 3.917 px/m. Correcto.

## Alineación con pilares y tono

Sin contradicciones con *Autonomía como progresión*, *Tensión sin castigo* e *Información incompleta* (nombres exactos de `game-pillars.md`). Puntos a favor: `atrás` siempre cierra, sin temporizadores, `SIN_EFECTO` con feedback, inspección no confirma intenciones. Riesgo menor: el pie de texto de duración fija y no releíble (H-19) roza *Información incompleta* solo si el texto es clave, cosa que el catálogo debe evitar.

## Scope signal

Rough scope signal: **L** (6 fórmulas, 9 dependencias aguas arriba y abajo, 10 contratos con otros sistemas, probable ADR sobre barridos/picking y cursor). El productor debe verificarlo antes de planificar el sprint.

## Siguiente paso recomendado

1. Resolver H-01 a H-04 (bloqueantes) en el GDD del 7 y, en paralelo, actualizar el GDD del Jugador (H-02/H-09 de su review), Entrada (regla 6/F8 y texto «sentarse») y Marco (nombre del cierre automático).
2. Resolver H-05 a H-13 en el mismo lote de revisión.
3. Reabrir la revisión (la verificación de los números del slice y de F1 a F6 puede reutilizarse tal cual).

## Cambios requeridos en otros GDDs (añadido al aplicar la revisión, 2026-11-09)

Origen: `interaccion-e-inspeccion.md` revisado (Status «Revisado — pendiente de re-review»). El GDD del Jugador (2) es la fuente de verdad del contrato 2↔7; lo que sigue es lo que 7 necesita **además** de lo que ya tiene el 2.

- **2 Jugador:** (a) avisos «cámara cedida(propietario)» y «cámara devuelta(propietario)» (7 mantiene el bloqueo hasta el segundo); (b) `fov_vigente()` (F6 de 7 lo necesita; `fov_destino` también pasa por `fov_h_max`); (c) `HAND_HOLD_ITEM` admitido sin `item_id` (V05 es un objeto de escena que posiciona 7) y quitar `A03`/tarjetas de la descripción de `HAND_HOLD_ITEM` o aclarar que las sostiene 20 con `sostener`; (d) estado Cámara cedida + `lectura` (manos `HAND_POINT` → `HAND_READ` → `HAND_POINT`); (e) plano cercano de la cámara < 0,19 m; (f) propietarios `interaccion:vista` / `interaccion:ordenador`; (g) fila de 7 en Interactions: «contrato», no «supuestos».
- **1 Entrada:** retirar `leer` del contexto `inspección`; corregir «al sentarse al ordenador» (V01 solo acerca la cámara); confirmar que 7 puede declarar una transición bloqueante por gesto/cámara (regla 8) sin `sin control`, y que la pausa detiene el tope de 3 s también ahí; recoger las posiciones en px de los elementos de la vista (F5b) que entrega 7.
- **9 Marco:** adoptar `registrar_receptor(vista_id, receptor)` con `elements()` (id, forma, z_orden, atracción), `handle_pointer` con el `PointerEvent` ampliado (`elemento_bajo`, `delta_px`, `delta_grados`), `on_open`/`on_close(motivo)`; llamar a `cerrar_vista(id, resuelto)` tras `close_view_after_s` (7 no tiene temporizador); implementar el manejador de 7 para `B01`–`B03` (`WORLD`, `handle_activation`); `requires.items` es el único sitio del requisito de ítems; la negativa de compartimentos bloqueados la da el manejador de 10 (`SIN_EFECTO`) antes de abrir la vista.
- **4 Escena de planta:** listar a 7 como dependiente; 7 toma la retención de arranque (regla 9, paso 6) para cargar el catálogo y registrar manejadores/receptores; collider de `B05` solo en la parte que asoma de la base de la lámpara C (≥ 0,02 m de margen respecto del de `B02`); anclajes de vista perpendiculares a su plano.
- **3 Estado y bus:** listar a 7 como emisor de «vista cercana abierta/cerrada», «lectura completada», «lectura cerrada», «interacción ejecutada» y como lector de hechos para `habilitado_si`.
- **18 Contenido:** claves de etiqueta que falten (`Descolgar`, `Encender`/`Apagar`, `Imprimir`, `Usar`, `Entrar`) y `OBJ_A02a`–`OBJ_A02c`.
- **10 Caja / 8 / 19 / 20 / 22 / 28 (al redactarse):** registrar manejadores con `can_interact`/`interact`/`etiqueta`; 10 llama a `abrir_vista` tras animar el compartimento.
- **Índice y registro:** fila 7 y Feature Layer punto 1 → añadir 4 (y 3 blanda); quitar a 7 del `referenced_by` de `lock_max_s`; registrar `radio_apuntado_m`, `pick_min_px`, `r_max_inspeccion_m`, `F6_ppm` (ver «Propuesta de registro» de 7).
