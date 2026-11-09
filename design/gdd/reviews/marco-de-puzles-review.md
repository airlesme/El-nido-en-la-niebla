# Revisión de diseño: Marco de puzles (sistema 9)

> **Documento revisado**: `design/gdd/marco-de-puzles.md` (hash al final)
> **Revisor**: independiente, sin contexto del autor · **Modo**: `lean` (sin especialistas, análisis en una sesión) · **Workflow**: `standard` (`rigor: standard`)
> **Fecha**: 2026-11-09 · **Revisión previa**: ninguna (primera revisión)
> **Alcance contrastado**: `design/slice/slice-v0.3.md` (§10, §13, §16, §19, Anexos B y D), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, y los GDD de 3, 4, 5, 6, 7, 18 y Entrada.

## Veredicto: NEEDS REVISION

Es un GDD sólido y cohesionado: el reparto «veredicto, no acción» (D9-1) es una buena decisión, la política de fallo es única y verificable, y los seis puzles del slice encajan en la matriz con sus valores del Anexo B (soluciones, tolerancias, tiempos, hechos y dependencias c1→c3→c4 coinciden con B.1–B.6 y D.2). Las discrepancias §10/Anexo B (P2, P5 sin fallo) están bien resueltas y registradas. Pero tiene **5 defectos bloqueantes**: una contradicción interna sobre el audio del P5, un camino que puede dejar el P4 sin resolver (softlock) y otro que deja un puzle «inactivo» en la build final, una secuencia del P5 sin definir, y un reparto de responsabilidades con 7 y 10 que se contradice con el GDD del 7. Ninguno exige rediseñar el marco; todos se arreglan con cambios localizados.

### Completitud (workflow `standard`)

6/6 secciones requeridas presentes (Overview, Detailed Design = Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria, y Formulas, que aplica porque el sistema define umbrales, tiempos y tolerancias). Player Fantasy y Tuning Knobs (asesoras en `standard`) también presentes. `gdd-structure-check.sh`: sin ausentes ni placeholders. Las secciones opcionales (Visual/Audio, Game Feel, UI Requirements, Cross-References, Decisiones tomadas, Open Questions, Propuesta de registro) están.

### Grafo de dependencias (existencia de GDD en `design/gdd/`)

| Sistema | Estado en disco |
|---|---|
| 3 Estado y bus · 7 Interacción · 6 Ajustes · 18 Contenido · 2 Jugador | existen |
| 4 Escena de planta · 5 Guardado (citados en el cuerpo, **no** en Dependencies) | existen |
| 10 Caja · 11–16 Puzles · 17 Pistas · 19 Ordenador · 20 Documentos · 21 Director · 23 Audio · 25 Pausa · 26 Subtítulos · 28/29 | **no existen aún** (esperado; ver hallazgos 6 y 7 sobre los que faltan por declarar) |

### Valores del registro (`design/registry/entities.yaml`)

Búsqueda de `lock_max_s`, `long_press_threshold`, `rotate_mouse_gain`, `save_periodic_interval_s` y de las constantes `P1`–`P6`, `delay_s`, `snap_radius`, `theta`, `hold_s`. Sin conflictos de valor: `lock_max_s` 2,0 s, 0,5 s de pulsación larga y 0,25°/px coinciden. El registro no tiene entidades de puzle. Dos desajustes de forma, ver hallazgo 11.

---

## Hallazgos

Severidad: **B** bloqueante · **I** importante · **M** menor. Las referencias a línea son del GDD revisado salvo indicación.

### Bloqueantes

**1. [B] Reglas 18 y 20 se contradicen sobre la pérdida de audio (l.129 frente a l.131; Edge l.320).**
La regla 18 dice que `RESOLVING` se interrumpe «si se pierde la línea de audio por una causa externa». La regla 20 y el Edge Case dicen lo contrario: una línea ausente o con fallo de audio **nunca** atasca ni interrumpe; la secuencia continúa. Un programador no puede implementar ambas.
*Arreglo:* quitar la causa de audio de la regla 18 (interrupción solo por cierre de vista, descarga o `cerrar_modos()`), y dejar la regla 20 como única política de audio. Añadir un AC de que un fallo de audio a mitad de la línea no interrumpe.

**2. [B] La secuencia diferida del P5 no está definida y no cubre el caso «sin audio» (reglas 17 y 20, l.128 y l.131; AC-20 y AC-23).**
Regla 17: «una secuencia de pasos declarada en los datos», pero no hay ni un ejemplo de datos del P5 (sí lo hay del P1). Los «~16 s» de AC-20 no salen de ninguna suma (fundido 1,2 s + contorno + `VO_G_07` ≈ 14 s, slice B.5). Además, la base de contenido (18, regla 17) permite líneas **sin audio** durante el prototipado y deja el tiempo del subtítulo a 26, que no existe. Con la regla 20 tal cual, una línea sin audio solo termina a los `line_timeout_s` = 30 s (casi el doble que la real), o el comportamiento depende de 23/26, sin diseñar.
*Arreglo:* añadir en Detailed Design el JSON del P5 con los pasos y duraciones (fundido `reveal_fade_s`, contorno, paso de línea con `fallback_s` ≈ duración declarada de la línea), definir que «línea terminada» llega inmediatamente (o tras `fallback_s`) cuando el audio responde «sin audio», dejar `line_timeout_s` solo para señal perdida, y añadir una fórmula F8 de duración total de la secuencia que enlace con F7 y AC-20. Añadir AC con línea sin audio.

**3. [B] Los efectos de pista pueden cambiar el estado de una pieza sin pasar por `evaluate()`: riesgo de softlock del P4 (reglas 10, 12 y 25; AC-33).**
`AUTO_SOLVE_ELEMENT` (nivel 3 del P4) resuelve T1 y «cuenta como elemento correcto». La política `PER_ELEMENT` solo evalúa cuando «un elemento termina su gesto» (regla 12), y el controlador no escribe hechos (regla 10). Si T2–T4 ya estaban aceptadas y la pista resuelve T1, **nadie dispara `SOLVED`**: el P4 queda con las cuatro fichas correctas pero `ACTIVO`, `caja_c2` nunca se escribe y el P6 no se desbloquea. Viola S7 y el criterio 3 del slice (§19.3), y la prueba de la regla 30 no lo vería si «acciones válidas» no incluye pistas.
*Arreglo:* regla explícita: tras `apply_hint_effect` que cambie el estado de un elemento, el marco llama a `evaluate()` y procesa el veredicto por el camino normal (`PARTIAL`/`SOLVED`). Añadir AC (T2–T4 aceptadas, `request_hint(P4, 3)` ⇒ `EV_PUZZLE_SOLVED_P4` y `caja_c2`) e incluir las pistas en el fuzz.

**4. [B] Datos inválidos en la build final dejan el puzle «inactivo» (regla 29, l.161): softlock de historia.**
«El puzle afectado queda inactivo y se registra, y los demás siguen.» Un P1 inactivo significa que `archivo_abierto` no se escribe nunca y la puerta A no se abre; lo mismo con P3→P5→P6 y la llamada. Contradice S1/S7 (l.152, l.158), el pilar *Tensión sin castigo* («sin softlocks») y el propio Edge Case l.334, que trata el fichero corrupto como fallo de carga.
*Arreglo:* en la build final, cualquier error de validación se trata igual que el fichero ausente (fallo de carga del 4, regla 14), o el puzle cae a una definición de seguridad. «Inactivo» no es una opción para puzles del camino crítico.

**5. [B] Reparto de responsabilidades con 7 y 10 contradictorio para compartimentos bloqueados y para el modo `WORLD` (regla 7 l.76; Matriz l.186; Interactions l.210 y l.211).**
- Regla 7: el marco responde a la apertura de la vista de un puzle `BLOQUEADO` con `locked_feedback` y la cierra. El GDD del 7 (regla 3 y regla 8; tabla l.136) dice que `D01a`–`D01d` son `DELEGAR → abre su vista` con dueño **10 + 9**, y que un compartimento bloqueado «está habilitado y es su dueño quien contesta `SIN_EFECTO` con su texto». Con la regla 7 del marco el jugador vería un acercamiento de cámara (1,0 s) y un retroceso (0,6 s) para nada, y quedan dos sitios que deciden «bloqueado».
- El 7 nombra el modo `MUNDO` y el verbo `Girar` para B01–B03 con el contrato `can_interact/interact`; el marco usa `WORLD`, `CLICK` y `handle_activation(element_id, verb)`. No hay mapeo.
*Arreglo:* decidir un único dueño de la negativa (recomendado: el manejador del dueño de la caja, 10, consulta el estado del puzle al marco antes de abrir la vista, y la vista no llega a abrirse); dejar la regla 7 del marco como red de seguridad para vistas abiertas por otra vía. Unificar el nombre (`WORLD`/`MUNDO`) y declarar que el marco implementa el manejador de 7 para B01–B03. Añadir los cambios en 7 como ‡.

### Importantes

**6. [I] Dependencias incompletas y no bidireccionales (Dependencies l.337–361; Interactions l.205–220).**
- **Faltan en Dependencies**: 4 Escena de planta (regla 8 se apoya en su regla 9.6, y el GDD del 4 ya lista al 9 como *Dura*, l.201), 20 Documentos (la tabla de Interactions dice que entrega ítems para `requires.items` y recibe `rewards` y `abrir_lectura`), 19 (origen de `I-01`), 8 Control de acceso (`ANIM_DOOR_OPEN` del P1 y `archivo_abierto`; F4 describe la puerta empezando a abrirse), 21, 25 (menú de pausa, regla 26) y 26 (subtítulos de línea sin audio).
- **18 no lista al 9** (base de contenido, l.147: solo 11, 12, 14, 16 y 17), aunque la regla 29 hace fallar la carga si faltan claves de pista en 18: es una dependencia dura en validación, no «blanda».
- **El aviso «compartimento completado» (1 a 4) no tiene emisor.** Lo nombra el 3 (regla 10) y 5 lo usa como causa `compartment_done:<n>` (guardado, regla 6). El marco no lo lista entre sus avisos (l.209, l.540) ni se asigna a 10 (sin GDD). Si nadie lo emite, la causa de guardado de compartimento no se dispara.
- Fila 9 del índice: `3, 7 (blandas 6, 18)`; falta 4 y 20 como mínimo.
*Arreglo:* completar las tablas, asignar el emisor de «compartimento completado» (recomendado: el marco, tras escribir `caja_c<n>`, porque ya posee el orden de escritura) y proponer la actualización de 18, 4, 5 y del índice.

**7. [I] Propiedad de los hechos (regla 1 l.37) choca con el GDD del 3 aún vigente.**
El 3 (reglas 2 y 6, tabla l.73–91) asigna `Escribe` a 11–16 y declara inválida (en desarrollo, detiene la ejecución) la escritura de un sistema distinto del `owner`. El marco propone `owner = 9` ‡ pero el 3 no se ha tocado: implementado hoy, **todas** las escrituras del marco pararían la ejecución en desarrollo. Tampoco queda claro quién es el `owner` de `flags.json` para `correos_leidos` y similares (fuera de alcance, bien).
*Arreglo:* registrar el cambio como bloqueo previo a implementación en el 3 (tabla y regla 2), no solo en «Propuesta de registro».

**8. [I] El control de «inactividad» (F3) contradice los disparadores del slice y es frágil (regla 26 l.146; F3 l.249–255; AC-31, AC-32).**
- Slice B.6: pistas del P6 «tras 10 s **sin pulsar**» y «20 s sin pulsar». F3 reinicia `idle` con *cualquier* `PointerEvent`, también el mero movimiento del cursor (el ejemplo l.255 lo confirma). Un jugador que lee la pantalla moviendo el ratón o con deriva del stick no ve nunca el mensaje. Es una contradicción con la fuente de verdad, no una interpretación.
- Slice B.3: «tras 60 s sin movimiento, el hueco correcto de la pieza **sostenida**». «Una vez por compromiso» (l.254) hace que, si a los 60 s no hay pieza sostenida, el umbral se consuma y la pista no vuelva a aparecer (AC-32 lo asume sostenida). Además, una pieza sostenida con el cursor vivo genera eventos continuamente.
*Arreglo:* definir «acción» como evento de gesto de inicio/fin (`seleccionar`, `agarrar`, `mantener`, `rotar`) con zona muerta para el movimiento, no desplazamiento; en P6 contar solo pulsaciones; en P3, condición «sostenida» evaluada al cruzar el umbral y rearmada si no se cumple.

**9. [I] `PARTIAL` sin definición de «borde»: feedback repetido (regla 9, 12, 13; F2).**
`evaluate()` es «función pura», pero se llama en cada cambio (`ON_CHANGE`), cada gesto (`PER_ELEMENT`) y cada fotograma (`SUSTAINED`). No se dice cuándo el marco emite el feedback de `PARTIAL`: sin una regla de borde, `SFX_GLASS_HUM`/`SFX_SNAP` se repiten con cada llamada (y en P2 al mover una lámpara entre dos puntos vacíos). Tampoco se define qué hace el marco cuando el progreso baja (un fragmento del P2 se apaga).
*Arreglo:* `PARTIAL` lleva un conjunto de progreso (p. ej. IDs de fragmentos o fichas); el marco emite feedback solo al **incorporarse** elementos nuevos, y define el comportamiento de retroceso (atenuar sin sonido). Añadir AC.

**10. [I] La prueba de resolubilidad es tautológica (regla 30 l.162; AC-36).**
`debug_is_solvable()` lo implementa cada controlador, así que el fuzz comprueba el oráculo contra sí mismo. Además, «acciones válidas» no incluye pistas, `cancelación`, cerrar y reabrir vistas, ni guardar y cargar a mitad (hallazgos 3 y 12).
*Arreglo:* oráculo independiente. Tras cada acción del fuzz, un solucionador de referencia, que conoce la solución de los datos, la reproduce **por la tubería real** (`handle_pointer` → `evaluate()` → marco) y debe llegar a `RESUELTO` y a escribir el hecho esperado. Ampliar el conjunto de acciones.

**11. [I] Desfases con los GDD ya escritos y con el registro (reglas 19 y 23, D9-8, Open Questions 2 y 3, Propuesta de registro).**
- Open Question 3 y la regla 19 piden al 5 guardar al cambiar `pendiente_revelacion` ‡: el 5 ya lo hace (`reveal_pending`, «en cualquier sentido») y además tiene `puzzle_solved:<ID>`, `compartment_done`, `quit` y `periodic`. La regla 23 («se dispara al cambiar `caja_c*` y `archivo_abierto`») no describe las causas reales, y D9-8 («el slice solo guarda al completar compartimentos») ya no es cierto.
- Open Question 2: «`abrir_lectura` (nueva petición a 7)»: ya existe, el 7 la define con el marco como ejemplo (regla 27b).
- El registro marca `save_periodic_interval_s` como `referenced_by: marco-de-puzles.md`, pero el GDD no lo menciona; sus propias constantes de la «Propuesta de registro» (`delay_s_P1`, etc.) no están en el registro.
*Arreglo:* actualizar reglas 19 y 23, cerrar las Open Questions 2 y 3, nombrar `periodic`/`quit` en la regla 22 (el progreso parcial puede perderse por cierre forzado, no solo «al cerrar el juego»), y que el consolidador añada las filas al registro.

**12. [I] Gestos y vida de la vista: faltan `cancelación` y el cierre durante un arrastre (reglas 9, 11 y 21; 7 reglas 21 y 23).**
7 entrega `cancelación` al receptor antes de cerrar la vista o ante pérdida de foco y pausa, con la exigencia de «no perder ninguna pieza en el aire». El marco solo habla de `on_disengage(reason)` y de «completar el feedback al instante». No dice qué pasa con una pieza del P3 en la mano, un `rotar` del P5 en curso, una ficha del P4 a medias de los selectores, ni si `cancelación` puede dar `REJECT`. Falta AC.
*Arreglo:* regla: `cancelación` ⇒ `reset_attempt` silencioso (sin `REJECT`, sin sonido) y sin evaluar; AC por puzle.

**13. [I] Presentación y vista del P6 y de los puzles `RESUELTO` sin definir (reglas 6, 16, 17; l.180; D-14).**
El P6 es `IMMEDIATE`, pero el slice B.6 describe tres pasos (`SFX_LOCK_CLICK` 0,3 s, tapa 1,6 s, carta) y la regla 16.5 solo habla de «la presentación del controlador». Si luego «un puzle RESUELTO rechaza todo gesto con `SFX_CLICK_SUBTLE`» (l.180, AC-01), ¿puede el jugador reabrir `D01d` para releer la carta (D-14, «permanente»)? ¿Se abre la vista de un `RESUELTO` (P1, P3…) o 7/10 lo impiden? Hoy depende de implementación. Relacionado: `ajar_cm` se aplica al P6 (Knob l.381) pero el slice B.6 no lo pide (solo B.5).
*Arreglo:* declarar por puzle la política de reapertura (`restore_solved_presentation`), p. ej. P6: la carta se relee desde el bolsillo (`abrir_lectura`, I-07), el compartimento queda abierto; y decidir si `ajar_cm` aplica al P6 (sería invención no recogida en el slice: mantener solo P5 salvo que se confirme).

**14. [I] `requires.items` mezcla dos conceptos y no hay API para consultar ítems (regla 4 l.47; regla 6; S6; matriz l.187; Dependencies).**
La regla 4 define `requires` como condición para pasar de `BLOQUEADO` a `ACTIVO` e incluye `items`; pero el P1 está `ACTIVO` desde el inicio *sin* el ítem (matriz, S6). Y `I-01` no tiene hecho en D.2 (solo `correos_leidos` lo habilita), con lo que el marco no puede saber si el jugador lo tiene ni qué pasa tras cargar. 7 declara además `requiere_ítem` por vista (l.74): requisito duplicado en dos ficheros de datos.
*Arreglo:* separar `requires.all` (transición de estado) de `needs_items` (solo afecta al `locked_feedback`), pedir a 20 una consulta `has_item(id)` y decidir la fuente única entre `interactables.json` y `puzzles.json`.

**15. [I] Pistas del P6: dos o tres (regla 27; AC-30; Open Question 1).**
El slice es contradictorio internamente (§10, §16 y §19.2 piden tres niveles para todos; B.6 da dos), y D9-12 dice «prevalece el Anexo B» pero aquí se deja abierta. La base de contenido (18) habla de «pistas de tres niveles de cada puzle». Es una decisión de contenido y tono que toca el slice, así que **no la decide este informe**: ver «Pregunta para el usuario».

**16. [I] Riesgos de implementación en Godot 4.7 (sin afirmar nada fuera de `docs/engine-reference/godot/`).**
- «Interfaz» `PuzzleController` (regla 9): GDScript no tiene interfaces. La referencia del motor documenta `@abstract` (4.5+, `breaking-changes.md` y `current-best-practices.md`); el GDD debería indicar clase base abstracta + el mecanismo de despacho.
- «Reloj falso» (Acceptance Criteria, preámbulo): exige que todo el marco use un reloj de juego propio inyectable, no `SceneTreeTimer` ni `await get_tree().create_timer()`. Solicitar esto como requisito de diseño de 9 (afecta a F1, F2, F3, rule 20, lock). AC-13 («≤ 100 ms con reloj falso») solo puede comprobar el orden lógico dentro del fotograma, no la latencia real: reformularlo como «el evento de feedback se emite en el mismo fotograma» (L) y medir la latencia percibida en playtest (V/I).
- Pausa y `process_mode`: el GDD afirma «la pausa detiene» los temporizadores y la secuencia del P5, pero también la línea de audio de 23 debe detenerse. **NOT SOURCEABLE — el comportamiento de `SceneTree.paused`/`process_mode` con `Tween`, temporizadores y `AudioStreamPlayer` no está cubierto por `docs/engine-reference/godot/`**; verificarlo en el editor 4.7 antes de la ADR.
- Datos JSON (`puzzles.json`, regla 4): **NOT SOURCEABLE — el tipado de enteros frente a flotantes al parsear JSON no está en `docs/engine-reference/godot/`**. Importa porque el 3 rechaza un `float` en un hecho `int` (regla 6, detiene la ejecución en desarrollo) y la solución del P2 (`pos_*`) y `sequence` del P1 viajan por ese fichero. Añadir conversión explícita y test.
- La señal `finished` de `AudioStreamPlayer` está documentada (`modules/audio.md`, errores típicos: no temporizar el audio con `_process`); es la base natural del evento «línea terminada».

### Menores

**17. [M] F6 con aritmética incorrecta (l.277–279).** El P1 necesita 8 clics por intento (cuatro «referencia, hueco»), no 4: `t_gestos` ≈ 3,2 s, intento ≈ 5,3 s, `T_peor` ≈ 23 · 5,3 ≈ 122 s y media ≈ 61 s, no 83/43 s. La conclusión («se acepta») probablemente se mantiene, pero conviene corregirla. Y «P4: 9 combinaciones por ficha más Devolver» ⇒ N = 10 por ficha para T1–T3.

**18. [M] F2: criterio de igualdad en coma flotante (l.235; AC-14).** «48 fotogramas a 60 fps = 0,80 s ⇒ `SOLVED`» depende de cómo se acumule `1/60`; con `acum ≥ hold_s` exacto puede resolverse en el fotograma 49. Fijar un épsilon o expresar el AC como «entre 48 y 49 fotogramas».

**19. [M] Orden de escritura del P5 (regla 19 l.130; AC-20).** `pendiente_revelacion` ← falso antes de `caja_c3` ← verdadero deja un estado intermedio (ambos falsos) visible a suscriptores síncronos (el 3 aplica el valor al instante, regla 3). Invertir el orden (primero `caja_c3`, después limpiar `pendiente_revelacion`) hace que cualquier lectura intermedia sea un estado que, al cargar, ya resuelve el puzle.

**20. [M] Carga con P2 en la solución y `memo_leido` falso (regla 8).** `ON_CHANGE` no reevalúa al configurar: un estado `pos = 3,1,4` con `memo_leido = falso` (cierre forzado entre la escritura y el guardado, o consola) deja el P2 sin resolver hasta mover una lámpara. Evaluar una vez al configurar los puzles `ON_CHANGE`.

**21. [M] Colisión de IDs: piezas `P1`–`P5` del encaje (slice B.3) frente a puzles `P1`–`P6` (D9-13).** Con un espacio plano de IDs de elemento (`PointerEvent.elemento`, `elements`) es una trampa. Prefijar los elementos (`D01a/S1`, `piece_1`).

**22. [M] Knobs y rangos.**
- Valores sin knob: duraciones de `SFX_UNLOCK` (1,4 s), `SFX_GLASS_HUM` (2,0 s), marco iluminado (1,0 s), `CAMERA_NUDGE` (3 s) y texto de P2 nivel 1 (2 s), `locked_feedback`, número de intentos de la secuencia.
- `lock_max_s` rango 1,0–3,0 s contradice «sin espera larga» y AC-X2 («≤ 2 s») si se sube a 3 s; limitar el rango a ≤ 2,0 s o ajustar el AC.
- `latencia_feedback_ms` es un umbral de verificación, no un knob de sensación.
- La regla 29 solo valida `pick_min_px`, pero 7 (regla 22) también atribuye al marco la comprobación de la separación 2·R entre elementos.
- 7 llama al cierre automático `t_auto_salida_s` y el marco `close_view_after_s`: unificar el nombre.

**23. [M] S3 sobredimensionada (l.154).** «No hay temporizadores de solución» convive con `hold_s` (0,8 s), `delay_s` (0,6 s) y la secuencia de ~16 s. Reformular: «ninguna regla castiga el tiempo ni lo exige al jugador».

### Criterios de aceptación no testeables o ausentes

| AC | Problema | Reescritura propuesta |
|---|---|---|
| AC-13 | «≤ 100 ms (reloj falso)» no mide latencia real | L: el evento de feedback se emite en el mismo fotograma que la acción; V/I: latencia percibida en playtest |
| AC-01 (1.ª parte) | «intenta pasar a BLOQUEADO» sin acción definida | Probar que las únicas transiciones expuestas son las de la regla 6 (API sin método de retroceso) |
| AC-14 | Igualdad flotante en el fotograma 48 | Admitir 48–49 fotogramas |
| AC-38 | «se equivoca todo lo posible» no es medible | Guion de QA por puzle con las N rutas de error de F6 y un bot que las ejecuta; criterio: ninguna deja el puzle sin salida |
| AC-X1 | «resuelve cada puzle con información del juego» | Cada pista de AC-30 referencia un elemento visible en la escena; checklist de QA firmado |
| AC-X2 | 6 testers y una pregunta cualitativa | Mantener, pero registrar el cuestionario literal y el umbral (0 de 6) |
| AC-36 | Oráculo autorreferencial | Ver hallazgo 10 |
| **Ausentes** | Pista que completa el puzle; `cancelación`; interrupción por cierre forzado / `cerrar_modos()` / descarga (solo se prueba `atrás`); línea sin audio; fallo de audio a mitad; reconfiguración en carga con P2 en la solución; vista de un puzle `RESUELTO`; `requires` sin escritor a nivel de datos | Añadir un AC por cada caso |

### Casos límite que el GDD sí cubre bien

Puzle resuelto dos veces en el mismo fotograma (S9, AC-24), orden de resolución P3/P4 (AC-05), carga con `caja_c1` (AC-02), reanudación de la revelación (AC-20/22/X4), vista de puzle bloqueado, cierre durante `EVALUATING`/`FEEDBACK` y pausa en mitad de un temporizador. Los huecos reales están en los hallazgos 3, 12 y 20.

## Coherencia con el slice y los pilares

- **Puzles reales cubiertos**: los seis, con política, solución y tiempos de B.1–B.6; hechos y dependencias de D.2/D-16 correctos; `EV_PUZZLE_SOLVED_P1`–`P6` confirma la propuesta del 3 (el slice solo dice `<ID>`).
- **Desviaciones documentadas**: `pendiente_revelacion` se escribe al *iniciar* la revelación (D9-5), mientras D.2 del slice dice «si se interrumpe». Es consistente con B.5/D.3 (el efecto observable coincide) y está registrada; añadir una nota explícita en Cross-References de que desvía D.2 en el *momento* de escritura, no en el valor.
- **Pilares**: *Tensión sin castigo* (sin contador, sin penalización, bloqueo ≤ 2 s) y *Autonomía* (orden libre, pistas opcionales) bien servidos. `AUTO_SOLVE_ELEMENT` procede del propio nivel 3 del P4 (B.4), por lo que no choca con «escenas que resuelven el puzle por el jugador», pero depende de que el jugador la pida.
- **Incumplimientos de pilar por causa de los hallazgos 3 y 4**: ambos pueden bloquear la historia.

## Pregunta para el usuario (no decidida en esta revisión)

**Hallazgo 15 / Open Question 1:** ¿el P6 tiene dos niveles de pista (B.6) o tres (§10, §16, §19.2)? Cambia el slice y el tono del puzle más emocional; se requiere decisión del creative director antes del GDD 16.

## Alcance de implementación

**Scope signal: L** — 8 dependencias, 6 fórmulas más 1 de referencia, 6 controladores, contrato de datos propio (`puzzles.json`), cambios previos en 3, 7, 5, 18 y el índice. Probablemente requiere una ADR (clase base `PuzzleController` y esquema de datos). Verificar con producción antes de planificar sprints.

## Resumen de lo que debe cambiar para pasar a APPROVED

1. Cerrar los bloqueantes 1–5.
2. Aplicar los importantes 6–14 (la 15 espera decisión).
3. Reflejar en 3, 5, 7, 18 y en el índice los cambios de propiedad y dependencias (‡), de modo que las dependencias sean bidireccionales.
4. Re-revisar tras los cambios (no se admite una revisión parcial).

---

Reviewed-Content-Hash: design/gdd/marco-de-puzles.md f11c27ac2aa339510feb38da9bab93e4ffb59119
Reviewed-Content-Hash: design/registry/entities.yaml 9d6f2909c8aea42d600786a53bf78de5a513761e
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/slice/slice-v0.3.md d8398aa0cede5242a4094e0fe3776164ecbfea09
Reviewed-Content-Hash: design/gdd/estado-y-bus-de-eventos.md fee8001760753398901601de2bb02f1039b2165f
Reviewed-Content-Hash: design/gdd/interaccion-e-inspeccion.md f0f666110b19c3ffdff9c6a25d225a9731f3f9c7
Reviewed-Content-Hash: design/gdd/base-de-contenido-narrativo.md 3ffdab1aa3d7e1a116a278feb6e604e30cde5fd6
Reviewed-Content-Hash: design/gdd/guardado-y-carga.md e12ebdd522a54f41b21412ebd7d0ddc9fff8f73f
Reviewed-Content-Hash: design/gdd/escena-de-planta.md 74da8edaf5d28aa73b40747f51dd84dbabe1301e
Reviewed-Content-Hash: design/gdd/systems-index.md 395337e9a90476a750b4888e002ae6c5c67a4dc4
Reviewed-Content-Hash: design/gdd/game-pillars.md b779b89b06b8cb687a8fe0148e81b82831914b97
Reviewed-Content-Hash: design/gdd/entrada-y-controles.md 534bf8a968bc407705ac04eae73779ac0ba79115
Reviewed-Content-Hash: design/gdd/ajustes-persistentes.md fa83c1684d5b687671bf80b7df12dace4e19ca2e

---

## Cambios requeridos en otros GDDs (derivados de la revisión aplicada, 2026-11-09)

Generados al aplicar los hallazgos a `marco-de-puzles.md` (estado «Revisado — pendiente de re-review»). No se han editado los GDDs afectados.

- **3 Estado y bus (bloqueo previo):** `owner = 9` para `archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1`–`c4`, `pendiente_revelacion`, `carta_variante` (tabla de hechos y regla 2); listar al 9 como emisor de «compartimento completado» (1–4), «puzle activado», «resolución de puzle interrumpida», «pista aplicada», «puzle inactivo», «feedback de puzle», «línea pedida».
- **5 Guardado:** ninguno de fondo (ya tiene `puzzle_solved`, `compartment_done`, `reveal_pending`, `quit`, `periodic`); documentar que el emisor de `compartment_done:<n>` es el marco (9).
- **7 Interacción:** (a) el dueño (10) consulta `get_view_gate(view_id)` del marco y contesta `SIN_EFECTO` sin abrir la vista en puzles `BLOQUEADO`/`RESUELTO`; (b) identificador `WORLD` para el modo `MUNDO` y verbo `Girar` en `B01`–`B03` con el marco como manejador (`registrar_manejador`); (c) operaciones `abrir_vista(view_id, receptor)`, `cerrar_vista(view_id, motivo)` con motivos `jugador`/`resuelto`/`sistema`, `abrir_lectura`; (d) `t_auto_salida_s` pasa a llamarse `close_view_after_s`; regreso de cámara = `t_devolver` 0,5 s del Jugador (no 0,6 s) y 7 mantiene el contexto hasta «cámara devuelta»; (e) eliminar `requiere_ítem` de `interactables.json` (la fuente es `needs_items` de `puzzles.json`); (f) `PointerEvent` con fases `inicio`/`fin`/`cancelación`, elemento fijado al pulsar y `elements()` del receptor; (g) el marco comprueba `pick_min_px` y la separación 2·R (regla 22).
- **18 Base de contenido:** P6 tiene **dos** claves de pista (`PISTA_P6_N1`, `PISTA_P6_N2`), no tres (discrepa de slice §10, §16, §19.2; prevalece B.6); listar al 9 como dependencia (la carga falla si faltan claves).
- **2 Jugador:** confirmar `t_devolver` 0,5 s como única duración de regreso y el vocabulario `HAND_*` que usa el marco (`HAND_TURN` para `Girar`).
- **4 Escena de planta:** ninguno (ya lista al 9); confirmar «escena lista» tras la configuración síncrona.
- **20 Documentos:** operación `has_item(item_id)`.
- **Índice de sistemas:** fila 9 → `3, 4, 7 (blandas 6, 18, 20, 23)`.
- **Registro (`entities.yaml`):** añadir las constantes de la «Propuesta de registro» del GDD 9; actualizar rango de `lock_max_s` (1,0–2,0).
