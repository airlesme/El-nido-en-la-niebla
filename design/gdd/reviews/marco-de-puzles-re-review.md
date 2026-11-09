# Re-revisión de diseño: Marco de puzles (sistema 9)

> **Documento revisado**: `design/gdd/marco-de-puzles.md` (hash al final)
> **Revisor**: independiente, sin contexto del autor · **Modo**: `lean` (sin especialistas) · **Workflow**: `standard` (`rigor: standard`)
> **Fecha**: 2026-11-09 · **Revisión previa**: `reviews/marco-de-puzles-review.md` (NEEDS REVISION, 5 bloqueantes)
> **Contrastado con**: `design/slice/slice-v0.3.md` (§8, §10, §13.3, §19, Anexos B y D), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, y los GDD de 1, 2, 3, 4, 5, 6, 7 y 18. Los sistemas 8, 10, 11–17, 19–21, 23, 25, 26, 28 y 29 no tienen GDD aún (esperado).
> **Método**: lectura completa del GDD por rangos de encabezados; `gdd-structure-check.sh`; comprobación de cada hallazgo de la revisión previa; cotejo de nombres, firmas, señales, claves y valores con los documentos vecinos.

## Veredicto: NEEDS REVISION

El GDD 9 ha corregido bien lo que la revisión previa pidió. Los cinco bloqueantes anteriores están resueltos dentro del propio documento: la política de audio es única (reglas 18 y 20, F8, D9-15), la secuencia del P5 tiene datos y duración (JSON de la regla 5, F8), los efectos de pista pasan por `evaluate()` (regla 12b, AC-43), los datos inválidos en la build final son un fallo de carga y no un puzle inactivo (regla 29, D9-18), y el reparto «el dueño consulta antes de abrir la vista» está escrito (regla 7). Las dos aritméticas (F6, F2) y los AC discutibles se han reescrito.

Lo que impide aprobarlo ahora es **el contrato con 7**, justo el que pedía comprobar esta re-review. El 9 propone un contrato (`get_view_gate`, `abrir_vista(view_id, receptor)`, `on_engage/on_disengage`, `needs_items`) y el GDD de 7 ya publicado usa otro (`registrar_receptor` + `abrir_vista(vista_id)`, `on_open/on_close`, `requires.items`, y no conoce `get_view_gate`). Además, la fila de 7 para `D01a`–`D01d` describe una cadena de compartimentos que contradice al 9 y al Anexo B. Aparte hay un hueco de especificación en P5 (`evaluate()` «pura» frente al acumulador de F2), dos puntos sin dueño (la reapertura de `C05` y `CAMERA_NUDGE`) y una laguna que puede causar un atasco tras cargar (propiedad de `I-01`). Nada exige rediseñar el marco; todo es alineación de contrato y precisión.

### Estado de los hallazgos de la revisión previa

| # previo | Estado | Nota |
|---|---|---|
| 1 audio R18/R20 | Resuelto | R18 solo interrumpe por salida de vista; AC-23 cubre el fallo a mitad |
| 2 secuencia P5 | Resuelto | JSON, F8 (16,0 s nominales) y AC-20/23 coinciden entre sí |
| 3 pista sin `evaluate()` | Resuelto | R12b, AC-43, D9-16 |
| 4 datos inválidos | Resuelto | R29, AC-47, D9-18. Ver hallazgo 11 (momento de la validación) |
| 5 reparto 7/10 | **Parcial** | El 9 está corregido; **7 no se ha alineado** (hallazgo 1) |
| 6 dependencias | Parcial | Tablas del 9 completas; faltan 2 en el índice y la clasificación de 18 es incoherente (hallazgo 12) |
| 7 propiedad en 3 | Resuelto | 3 regla 2 y tabla ya dicen `owner = 9`; 3 regla 10 lista los avisos del 9 |
| 8 F3 inactividad | Resuelto | Gestos, no movimiento; `idle_reset` por puzle; coincide con B.3 y B.6 |
| 9 borde de `PARTIAL` | Resuelto | R13b, AC-44 |
| 10 oráculo de resolubilidad | Resuelto | R30, AC-36 con sanity del oráculo |
| 11 desfases con 5 y registro | Mayormente resuelto | Registro: ver hallazgo 13 |
| 12 `cancelación` | Resuelto | R11b, AC-45 |
| 13 reapertura y `RESUELTO` | Resuelto | R35, AC-42. Ver hallazgo 3 para `C05` |
| 14 `requires.items` | Resuelto en el 9 | `needs_items`/`requires.all`; **7 sigue diciendo `requires.items`** (hallazgo 1) y falta decidir `I-01` (hallazgo 4) |
| 15 pistas del P6 | Cerrado por el usuario | Dos niveles. Ahora el slice también lo dice (hallazgo 14) |
| 16 riesgos Godot | Mantenido | Siguen sin respaldo en la referencia del motor; ver «Motor» |
| 17–23 menores | Resueltos | F6 recalculada y comprobada (P1 ≈ 122 s / 61 s; P4 ≈ 29 s); ε en F2; orden P5 invertido; reevaluación `ON_CHANGE`; IDs con prefijo |

### Completitud (workflow `standard`)

6/6 secciones requeridas presentes (Overview, Detailed Design = Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria y Formulas, que aplica: el sistema define umbrales, tiempos y tolerancias). Player Fantasy y Tuning Knobs (asesoras) presentes. `gdd-structure-check.sh`: sin ausentes ni placeholders.

### Grafo de dependencias (existencia de GDD)

| Sistema | Estado |
|---|---|
| 1 Entrada · 2 Jugador · 3 Estado · 4 Escena · 5 Guardado · 6 Ajustes · 7 Interacción · 18 Contenido | existen |
| 8 · 10 · 11–16 · 17 · 19 · 20 · 21 · 23 · 25 · 26 · 28 · 29 | no existen aún (esperado; todos marcados ‡ o «cuando exista») |

### Valores del registro

Búsqueda de `lock_max_s`, `close_view_after_s`, `delay_s_P1`, `snap_radius_m_P3`, `theta_solution_deg_P5`, `hold_s_P5`, `reveal_fade_s_P5`, `line_fallback_s_P5`, `latencia_feedback_ms`, `idle_s_P3_N3`, `t_vista_salida_s`, `long_press_threshold`, `rotate_mouse_gain`, `pick_min_px`, `save_periodic_interval_s`. **Sin conflictos de valor** (2,0 s; 1,5 s; 0,6 s; 0,04 m; 40°; 0,8 s; 1,2 s; 14,0 s; 100 ms; 60 s; 0,5 s; 0,5 s; 0,25°/px). Solo desfases de forma: hallazgo 13.

---

## Hallazgos

Severidad: **B** bloqueante · **I** importante · **M** menor. Las líneas son del GDD 9 salvo indicación.

### Bloqueantes

**1. [B] El contrato 9↔7 no coincide con el GDD de 7 publicado (reglas 7 y 11, l.102 y l.124; Interactions l.258; Dependencies l.423).**
La propagación de la revisión previa dejó el 9 corregido, pero 7 conserva un contrato distinto. Diferencias concretas, comprobadas en `interaccion-e-inspeccion.md`:
- **`get_view_gate` no existe en 7.** El 9 depende de él (reglas 7 y 35, AC-04, AC-42) y el índice lo menciona (l.61), pero 7 solo dice «10 consulta al marco antes de abrir» (tabla l.181), sin nombre ni firma.
- **Cadena de compartimentos errónea en 7.** La fila de `D01a`–`D01d` (l.181) dice «`SIN_EFECTO` en `D01b`–`D01d` hasta que el anterior esté resuelto». Contradice el Anexo B (P4 sin dependencias; P5 solo requiere `caja_c1`; P6 requiere c1, c2 y c3), el slice §8 («en cualquier orden») y el 9 (AC-05, regla 24). Un 10 implementado desde 7 haría P4 inaccesible hasta resolver P3. Tampoco dice que `D01a` pasa a `SIN_EFECTO` al resolverse (regla 35 del 9).
- **Firma de registro.** El 9 (regla 11): `abrir_vista(view_id, receptor)` y «7 se registra con el marco como receptor». 7 (regla 30): `registrar_receptor(vista_id, receptor)` en la configuración (antes de «escena lista») y `abrir_vista(vista_id)` sin receptor.
- **Ciclo de vida del receptor.** 9: `on_engage()` / `on_disengage(reason)`; 7: `on_open()` / `on_close(motivo)` con `motivo` ∈ `jugador|resuelto|sistema`. El 9 nunca define `reason`.
- **`ViewElement`.** 7 exige `{id, forma, z_orden, atraccion}` y la señal `elements_changed` cada vez que cambian las formas (piezas arrastradas del P3, referencias del P1 que pasan del papel al hueco, sellos del P4). El 9 solo dice «IDs y formas de hit-test» (regla 9) y no menciona `elements_changed` ni `atraccion`.
- **Fases del `PointerEvent`.** 7 entrega también `actualización` (y el gesto «desplazar cursor» sin botón); el 9 enumera solo `inicio`, `fin` y `cancelación` (reglas 9 y 11). `agarrar` y `rotar` del P3 y P5 se alimentan de `actualización`.
- **Requisito de ítems.** 7 (regla 19 y D7-22) escribe `requires.items`; el 9 lo llama `needs_items` y reserva `requires.all` para el estado. Hay que fijar un solo nombre.
- **Manejador.** 7 pide `interact(verbo, contexto) -> {HECHO, SIN_EFECTO}` y `can_interact`; el 9 define `handle_activation(element_id, verb)` sin decir qué devuelve ni quién reproduce `HAND_TURN` (`gesto_hecho`).
*Arreglo:* (a) en 7: añadir `get_view_gate` a la API con la firma del 9, corregir la fila de `D01a`–`D01d` (dependencias reales: P5←c1, P6←c1∧c2∧c3, `SOLVED`→`SIN_EFECTO`), renombrar `requires.items` a `needs_items`; (b) en el 9: usar `registrar_receptor`/`abrir_vista(vista_id)` y los nombres `on_open/on_close(motivo)`, declarar el contrato `ViewElement`/`elements_changed` y las cuatro fases (con qué hace cada controlador ante `actualización`), y definir el retorno de `handle_activation` (`HECHO`/`SIN_EFECTO`). Hasta que ambos GDD digan lo mismo, el contrato 2↔7↔9 no está cerrado.

### Importantes

**2. [I] `evaluate()` «pura» frente al acumulador de F2 y al veredicto de P5 (regla 9 l.113; regla 12 l.133; F2; tabla de estados l.220; matriz l.235).**
La regla 9 dice que `evaluate()` es función pura del estado y la definición, sin parámetro de tiempo. Pero la política `SUSTAINED` (P5) exige acumular `dt` durante `hold_s` (F2), y el estado de tabla `EVALUATING` habla de un «acumulador `SUSTAINED` en marcha». El vocabulario del veredicto (`NONE`, `PARTIAL`, `REJECT`, `SOLVED`) no tiene valor para «la condición se cumple en este fotograma» y la matriz dice que P5 no emite `PARTIAL`. No se sabe si el acumulador vive en el controlador (entonces no es pura) o en el marco (entonces falta el valor que se le devuelve).
*Arreglo:* declarar que `evaluate()` es pura y el acumulador es del marco, y añadir al `Verdict` un valor `HOLDING` (o `PARTIAL` con un `progress` de un solo elemento «alineado» que no suene) que el marco convierte en `SOLVED` según F2. Cubrir con un AC que pruebe el acumulador por separado del controlador.

**3. [I] `C05` no tiene dueño que consulte la puerta, y AC-42 es inalcanzable para P1 (reglas 7 y 35; Open Question 6; AC-42).**
7 (tabla l.178) asigna `C05` al efecto genérico `ABRIR_VISTA`, dueño 9, sin manejador. La regla 7 del 9 dice «para `C05`, quien registre la vista» y la Open Question 6 pregunta si es 19, 11 u 8. Con `ABRIR_VISTA` la vista se abriría siempre: una vez resuelto P1 el jugador vería el acercamiento de cámara, y el 9 la cerraría (red de seguridad), lo mismo que se evitó para `D01*`. AC-42 («P1 `RESUELTO` ⇒ no se abre ninguna vista») no se puede cumplir.
*Arreglo:* dos opciones, ambas baratas: (a) 7 admite `habilitado_si: { ninguno: [archivo_abierto] }` en `C05` (el esquema ya soporta `ninguno`, regla 2 de 7) y el 9 lo declara; o (b) el 9 registra un manejador para `C05` con `can_interact` y `get_view_gate`. Cerrar la Open Question 6 con una de las dos y quitar la duda sobre 19/11/8.

**4. [I] Propiedad de `I-01` tras cargar: posible atasco o salto de la impresión (reglas 7, 34; S6; AC-39).**
La regla 34 dice que 20 deriva los ítems de los hechos y que `I-01` «no tiene hecho propio; `correos_leidos` lo habilita». El Anexo D.1 dice que `I-01` se obtiene **imprimiendo** en `V08` tras `correos_leidos`, y D.2 no tiene un hecho de impresión. Tras cargar, `has_item('I-01')` solo puede ser (a) verdadero siempre que `correos_leidos`, aunque no se haya impreso, lo que salta la acción de imprimir y deja la pista nivel 1 del P1 (`CAMERA_NUDGE` a `I-01`) apuntando a algo que no existe; o (b) falso tras cargar, lo que exige que imprimir sea repetible, algo que el 9 no puede garantizar (19 no existe).
*Arreglo:* decidir y escribir una de las dos en la regla 34 y obligar a 19/20 a cumplirla (recomendado: imprimir repetible e ilimitado, `I-01` no se conserva entre sesiones, y S6 se redacta así); añadir un AC de carga con `correos_leidos` verdadero y sin `I-01`.

**5. [I] `CAMERA_NUDGE` no tiene proveedor en el Jugador y colisiona con la lista cerrada de propietarios de cámara (Interactions l.259; regla 25; regla 18 de 2).**
El 9 dice que 2 entrega `CAMERA_NUDGE` (P1 nivel 1, 3 s). El GDD de 2 (regla 18) solo admite los propietarios `interaccion:vista` e `interaccion:ordenador`, rechaza cualquier otro y no define ningún gesto de cámara guiado ni lista al 9 como dependiente (ni en sus dependientes ni en «Cambios requeridos», que solo dice «alinearse con el contrato»). No se dice tampoco si el jugador puede mover la cámara durante esos 3 s, ni qué pasa si la pista se pide desde el menú de pausa.
*Arreglo:* o 2 añade un propietario `pista` con duración y devolución, o el 9 sustituye el nudge por un `HIGHLIGHT` sin ceder la cámara. Registrarlo como cambio requerido en 2 y añadir al 9 como dependiente del Jugador.

**6. [I] Pistas pedidas desde la pausa: el reloj de juego está parado (reglas 26, 36; AC-33, AC-43).**
Las pistas se piden desde el menú de pausa (regla 26) y la regla 36 hace que **pausa detenga todo temporizador del marco**. Los efectos tienen duración (`CAMERA_NUDGE` 3 s, texto del P2 2 s, `HIGHLIGHT`) medida con el mismo reloj, y `request_hint` puede llamar a `evaluate()` y escribir hechos (`AUTO_SOLVE_ELEMENT`) en pausa. No se dice cuándo empieza el efecto (¿al reanudar?), si un `SOLVED` en pausa reproduce su presentación al reanudar, ni qué hace `idle` (F3) en la pausa.
*Arreglo:* regla explícita: los efectos de pista arrancan al reanudar; la resolución se escribe en el acto y la presentación empieza al reanudar. Añadir un AC.

**7. [I] Disparador de pista y «a petición» para pistas `IDLE` (reglas 25–26; matriz l.241).**
Cada nivel tiene un solo `trigger` (`REQUEST` o `IDLE`). El slice (§10, l.118; §16, l.405) dice que las pistas son «accesibles desde el menú de pausa». Las pistas `IDLE` (P3 nivel 3, P6 niveles 1 y 2) quedan ambiguas: `request_hint` no comprueba el `trigger`. Si se piden desde la pausa, ¿se aplican y se marcan como alcanzadas? Si no, el P6 no tiene pistas a petición, contra el slice.
*Arreglo:* permitir ambos (`trigger: IDLE` implica también `REQUEST`) o declararlo por nivel; decirlo en la regla 25.

### Menores

**8. [M] Reanudación del P5: pose del marco interior y gesto activo (reglas 17 y 19).** Al reanudar con `pendiente_revelacion` verdadero, la regla 8 deja a θ en `theta_initial_deg` (0°) y la secuencia superpone las fotos «alineadas». Falta decir que el controlador fija θ = θ* al reanudar. Tampoco se dice qué pasa con un `rotar` aún activo cuando llega `SOLVED` (se cancela en silencio, sin `REJECT`).

**9. [M] AC-X2 y P1 (F6; Game Feel l.499; AC-X2 l.602).** El criterio dice «tiempo hasta reintentar ≤ 2 s». En P1 el jugador no puede volver a actuar hasta 0,6 s (`delay_s`) + 1,5 s (`lock`) = 2,1 s tras su último clic. Fijar el origen de la medida («desde el inicio del rechazo») o subir el margen.

**10. [M] Avisos sin carga útil ni emisor completos (reglas 16, 20, 26; Interactions).** «feedback de puzle» y «línea pedida» no declaran campos (ID de sonido, ID de línea, `fallback_s`). Las señales «línea terminada/sin audio/fallida» las emitiría 23 (sin GDD) y no están en la lista de avisos de 3 (regla 10). Si «línea terminada» llega durante la pausa, la regla 20 no dice si se retiene. Falta decir cómo recibe 10 el valor `ajar_cm` (el aviso «puzle activado» solo lleva el ID). Añadirlo a las cargas útiles y a «Cambios requeridos».

**11. [M] Momento de la validación de `puzzles.json` (regla 29; AC-47).** La regla dice «al arrancar», y habla del fallo de carga de 4 (regla 14), pero el GDD 4 enumera como fallo de carga solo «recurso ausente», «escena no instanciable» y «tope de F2» (4, regla 14), y la validación depende de catálogos de 7 y de claves de 18. Decir en qué punto de la secuencia de 4 corre (entre los pasos 4 y 6, con 7 cargado) y pedir a 4 que añada «datos de puzle inválidos» a su lista. Además, el fallo vuelve al título y «Continuar» repetiría el fallo: es deliberado (defecto de empaquetado), pero conviene decirlo.

**12. [M] Dependencias: clasificación incoherente y huecos en el índice (Quick reference l.13; Dependencies l.425; índice l.33).** El encabezado llama a 18 «blanda —dura en validación—», la tabla lo llama «Dura en validación» y el índice lo pone entre las blandas. 2, 25 y 26 aparecen en el 9 pero no en la fila 9 del índice. 18 cita la regla 27 del 9 para la validación; es la 29. 2 no lista al 9 (hallazgo 5).

**13. [M] Registro (`entities.yaml`).** La «Propuesta de registro» del 9 dice que las constantes «no están todavía»; ya están `delay_s_P1`, `snap_radius_m_P3`, `theta_solution_deg_P5`, `hold_s_P5`, `reveal_fade_s_P5`, `line_fallback_s_P5`, `latencia_feedback_ms`, `idle_s_P3_N3` y `close_view_after_s`. Siguen sin registrar `reveal_outline_s_P5`, `line_grace_s`, `idle_s_P6_N1/N2`, `idle_move_px_P3`, los valores asistidos (0,10 m; 6°) y `tol_deg`. `lock_max_s` tiene `referenced_by: []` aunque el 9 lo usa. Actualizar la sección para que no afirme lo contrario.

**14. [M] Texto obsoleto sobre las pistas del P6 (regla 27; matriz l.248; Cross-References l.518; D9-14; Open Question 1).** El 9 dice que dos niveles «discrepan de §10, §16 y §19.2», pero el slice ya fue actualizado (commit `4636af1`) y §10 (l.118), §16 (l.405) y §19.2 (l.441) dicen «tres niveles; dos en el puzle 6». Quitar la nota de discrepancia, la petición de «Cambios requeridos en 18» (18 ya la refleja, l.255) y la Open Question 1.

**15. [M] Cosméticos y precisión.**
- F8, rango: `T_seq ∈ [2,0 + t_terminada, 18,0]` no es un rango (el mínimo depende de una variable); escribir `[2,0, 18,0]`.
- S3 (l.190) sigue llamando «tiempo de juego» a retrasos que usan el reloj propio; unificar el término con la regla 36.
- Rule 9 hace que `PuzzleController` aporte «estado, planificación, bloqueo, escritura de hechos»: eso contradice la regla 10 (el controlador nunca escribe hechos). Separar la clase base (datos del controlador) del `PuzzleFramework` (lógica), o decir que la escritura solo se expone al marco.
- La `condición` de pista `HELD_PIECE` (P3) no aparece en el esquema de la regla 25.
- El tono: un compartimento `BLOQUEADO` contesta `SIN_EFECTO`, que según 7 (regla 3) conserva el icono de interacción. Esto contradice la frase de Visual/Audio («el compartimento entreabierto es el único aviso» de P5) y el principio de 7 de no revelar interacciones futuras. Decidir si basta `SIN_EFECTO` o si 7 debe ocultar el icono (`NO`) hasta que el puzle se desbloquee.

### Criterios de aceptación no testeables o ausentes

| AC | Problema | Reescritura propuesta |
|---|---|---|
| AC-01 | «por reflexión» exige una API de GDScript que no consta en la referencia del motor (NOT SOURCEABLE) | Probar que el objeto `PuzzleState` solo expone `activate()` y `resolve()`; sin depender de la reflexión |
| AC-42 (P1) | Inalcanzable hoy (hallazgo 3) | Cerrar la ruta de `C05` y mantener la prueba |
| AC-X1 | «resuelve cada puzle con información del propio juego» no es medible por sí solo | Mantenerlo como playtest (I) y dejar la checklist firmada como criterio de aceptación |
| AC-X2 | Origen del «tiempo hasta reintentar» ambiguo (hallazgo 9) | «Desde el inicio del rechazo» |
| AC-13 (V/I) | Aceptable tal como está (L + V/I) | — |
| **Ausentes** | Pista pedida en pausa; `idle` en pausa; carga con `correos_leidos` sin `I-01`; cambio de `reduce`/`asistencia` mientras el puzle está activo; `rotar` activo al llegar `SOLVED`; `actualización` y `elements_changed`; `C05` resuelto | Añadir un AC por cada uno |

### Pilares y coherencia con el slice

- **Tensión sin castigo:** servida (sin contador, bloqueo ≤ 2 s, `RESUELTO` inerte, nada deshace hechos). No se ha encontrado ningún camino que deje la historia bloqueada: los atascos que existían (R12b, R29, R18) están cerrados. Único riesgo residual: hallazgo 4 (`I-01` tras cargar).
- **Autonomía como progresión:** la cadena de compartimentos de la fila de 7 (hallazgo 1) restaría el orden libre P3/P4 que el slice y el 9 garantizan.
- **Información incompleta:** las pistas siguen siendo énfasis, no información nueva (regla 27).
- **Slice como fuente de verdad:** los seis puzles reproducen B.1–B.6 (soluciones, tolerancias, tiempos, hechos). Una incoherencia **del propio slice**, que el 9 resuelve a favor del Anexo B: §13.3 dice «Ningún compartimento depende de otro para ser resoluble», pero B (convenciones, B.5, B.6) y D.2 sí encadenan c3←c1 y c4←c1,c2,c3. Ver «Preguntas».
- **Desvío puntual de D.2 documentado:** `pendiente_revelacion` se escribe al iniciar la revelación, no «si se interrumpe» (D9-5, Cross-References). Correcto y comprobado: el efecto observable de B.5 y D.3 es el mismo.

### Motor (Godot 4.7; solo lo respaldado por `docs/engine-reference/godot/`)

| Afirmación del GDD | Estado |
|---|---|
| `@abstract` desde 4.5 para la clase base (regla 9) | **Respaldado**: `breaking-changes.md` l.69; `current-best-practices.md` l.32–39 |
| `AudioStreamPlayer.finished` como base de «línea terminada» (regla 37) | **Respaldado en lo general**: `modules/audio.md` l.85 recomienda las señales (`finished`) frente a temporizar con `_process`. Que `finished` se emita (o no) con un recurso ausente o fallido: **NOT SOURCEABLE** (lo cubre el diseño con `fallback_s`) |
| `SceneTree.paused`, `process_mode`, `Tween` y `AudioStreamPlayer` durante la pausa (regla 36, Open Question 4a) | **NOT SOURCEABLE** — no cubierto por `docs/engine-reference/godot/`. El diseño lo reconoce; verificar en el editor 4.7 antes de la ADR |
| Tipado entero/flotante al parsear JSON (regla 29, AC-48; Open Question 4b) | **NOT SOURCEABLE** — no cubierto. La validación explícita del 9 es la mitigación correcta |
| Prueba «por reflexión» de la API (AC-01) | **NOT SOURCEABLE** (hallazgo de AC) |
| Orden de señales de `AudioStreamPlayer` y `Tween` frente a `GameClock` | **NOT SOURCEABLE**; relevante para el hallazgo 10 |

Estas lagunas no cambian el veredicto de diseño, pero impiden dar por verificadas las reglas 36 y 29 en Godot; deben cerrarse en la ADR del marco y quedar anotadas allí.

## Preguntas para el usuario

1. **D-16 y el orden de la caja.** El slice se contradice: §8 (l.95) y §13.3 (l.353) dicen que los compartimentos se resuelven «en cualquier orden» y «ninguno depende de otro», mientras que Anexo B (l.683) y B.5/B.6 hacen depender c3 de c1 y c4 de c1, c2 y c3 (y B.5 usa la foto del P3 ya completa). El 9 sigue el Anexo B. ¿Se confirma que el Anexo B manda y se corrige §8/§13.3, o se quiere que P5 y P6 sean independientes? Cambia el alcance de los puzles 5 y 6.
2. **Icono en compartimentos bloqueados** (hallazgo 15, última viñeta): ¿un compartimento bloqueado debe mostrar el icono de interacción y no hacer nada (`SIN_EFECTO`), o debe permanecer sin icono hasta su desbloqueo? Es una cuestión de tono (*Información incompleta* / *Autonomía*).

No hay más preguntas: las pistas del P6 (dos niveles) ya están decididas y reflejadas en el slice.

## Alcance de implementación

**Scope signal: L** (sin cambio). 7+ dependencias duras o semiduras, 8 fórmulas, 6 controladores, un contrato de datos propio y cambios pendientes en 2, 4, 7 y el índice. Probablemente requiere ADR (clase base `PuzzleController` y `PuzzleFramework`, esquema de `puzzles.json`, `GameClock`). Verificar con producción antes de planificar sprints.

## Qué debe cambiar para pasar a APPROVED

1. Alinear el contrato con 7 en ambos sentidos y corregir la fila de `D01a`–`D01d` de 7 (hallazgo 1).
2. Definir `evaluate()` para P5 (hallazgo 2), la ruta de `C05` (3), la propiedad de `I-01` (4), el proveedor del `CAMERA_NUDGE` (5), pistas en pausa (6) y su disparador (7).
3. Responder las dos preguntas anteriores.
4. Aplicar los menores 8–15 (barato) y re-revisar; no se admite una revisión parcial.

---

Reviewed-Content-Hash: design/gdd/marco-de-puzles.md 13f586c9848da68977255cce983ca95c99219985
Reviewed-Content-Hash: design/registry/entities.yaml 08f58908e677a3e7325e32b3987fc4bf485965cf
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/slice/slice-v0.3.md 0c2eb2302e8878da87c14a772a5ee60d51ef87fd
Reviewed-Content-Hash: design/gdd/estado-y-bus-de-eventos.md a1a0250d497279886228d0598e1ea6c959e076d2
Reviewed-Content-Hash: design/gdd/interaccion-e-inspeccion.md 39c9c90faf9541a3a028fac98e34ee75dceca01e
Reviewed-Content-Hash: design/gdd/jugador-en-primera-persona.md e002ace598864227abc2024eee1ff0ee248e097a
Reviewed-Content-Hash: design/gdd/escena-de-planta.md 18ec16b93b8810e51d7e35ea9a5daac204220064
Reviewed-Content-Hash: design/gdd/guardado-y-carga.md a5d2edf2af45d738ba71d55de9797a67cc499a65
Reviewed-Content-Hash: design/gdd/base-de-contenido-narrativo.md 322335f76fb32df6403aba435ec161cf1d387e7a
Reviewed-Content-Hash: design/gdd/systems-index.md 040f47822d57f2110b20a2933585ca78ef4f7bd5
Reviewed-Content-Hash: design/gdd/game-pillars.md b779b89b06b8cb687a8fe0148e81b82831914b97
Reviewed-Content-Hash: design/gdd/ajustes-persistentes.md b1dcff8162a3584582ad67d1b88c80ed542e7746
Reviewed-Content-Hash: design/gdd/entrada-y-controles.md f39e00bb5c26462a61eae5b53af7481bcc72afcf

---

## Cambios requeridos en otros GDDs (ronda 2 del GDD 9, 2026-11-09)

Lo que el GDD 9 ya asume y deben reflejar los demás documentos (el 9 solo edita el 9):

- **GDD 7 (`interaccion-e-inspeccion.md`)**: (a) renombrar `requires.items` a `needs_items` (reglas 19, D7-22, l.317) y fijar el nombre; (b) corregir la fila de `D01a`–`D01d` (l.181): dependencias reales P5←`caja_c1`, P6←`caja_c1`∧`c2`∧`c3`, P3/P4 sin dependencias, y `SIN_EFECTO` también cuando el puzle está resuelto; el dueño (10) consulta `get_view_gate(view_id)` del marco antes de `abrir_vista`; (c) `C05` con `habilitado_si: { ninguno: [archivo_abierto] }` y receptor = marco; (d) citar `HIGHLIGHT` sobre objetos del mundo y elementos de vista (`C05/paper`, `V08`) como servicio de resaltado, sin cámara; (e) el marco entrega `elements()` con `{id, forma, z_orden, atraccion}` y emite `elements_changed`; usa `on_open`/`on_close(motivo)` y las cuatro fases. **Discrepancias que persistan tras la corrección de 7**: ninguna conocida (el 9 adopta sus nombres).
- **GDD 2 (Jugador)**: no añadir `CAMERA_NUDGE` ni un propietario `pista`; mantener la regla 14/18 (ningún evento mueve la cámara). Reinterpretar el «gesto de cámara» de la pista.
- **Slice v0.3**: (a) la pista de nivel 1 del P1 pasa a resaltado (~l.136 y ~l.724); (b) corregir §8 y §13.3 ante el Anexo B (P5←c1, P6←c1∧c2∧c3) si el usuario confirma D9-35; (c) D.2: nota de `pendiente_revelacion` al iniciar, `I-01` no persistente e impresión repetible.
- **GDD 3**: añadir a la lista de avisos (regla 10) «línea terminada / sin audio / fallida» (emisor 23, carga `{line_id}`), «línea pedida» `{puzzle, line_id, fallback_s}`, «feedback de puzle» `{puzzle, sound_id, text_key?, element?}` y «puzle activado» `{puzzle, ajar_cm?}`.
- **GDD 4**: añadir «datos de puzle inválidos» a los fallos de carga (regla 14), con validación tras cargar catálogos de 7 y claves de 18 y antes de configurar los puzles; consumir `reducir_movimiento` (cortina).
- **GDD 6 (Ajustes)**: clave booleana `reducir_movimiento` (decisión del usuario), leída por 9 y 4.
- **GDD 18**: la validación del 9 es la regla 29 (no la 27); 9 es dependencia dura en validación.
- **GDD 19/20**: imprimir en `V08` repetible e ilimitado; `I-01` no se conserva entre sesiones y `has_item('I-01')` es falso tras cargar.
- **Índice de sistemas**: fila 9 = `3, 4, 7, 18 (dura en validación) · blandas 2, 6, 20, 23, 25, 26`; `get_view_gate` en la API de 7/10.
- **Registro (`entities.yaml`)**: añadir `reveal_outline_s_P5`, `line_grace_s`, `idle_s_P6_N1`/`N2`, `idle_move_px_P3`, `tol_deg`, asistido 0,10 m, `highlight_s_P1`, `reducir_movimiento`; `referenced_by` de `lock_max_s`.
- **Preguntas aún abiertas para el usuario** (el 9 sigue la recomendación): D9-34 (icono en compartimentos bloqueados) y D9-35 (orden de la caja, D-16).
