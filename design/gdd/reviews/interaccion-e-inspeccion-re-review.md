# Re-review: Interacción e inspección (sistema 7)

- **Documento revisado:** `design/gdd/interaccion-e-inspeccion.md` (91 KB, leído entero por rangos de encabezado: la guarda de 40 KB impide la lectura de una vez y la revisión necesita todas las reglas, fórmulas y ACs).
- **Fecha:** 2026-11-09 · **Revisor:** independiente (no autor), modo lean, sin especialistas (un solo revisor; no hay `creative-director` de síntesis).
- **Workflow:** `standard` (`project.yaml`: `modes.rigor: standard`, sin `workflow` ni `system_overrides` fijados). Se exigen Overview, Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria y Formulas (el sistema define umbrales, tiempos y distancias).
- **Re-review:** Sí. Revisión previa: `reviews/interaccion-e-inspeccion-review.md` (NEEDS REVISION, H-01 a H-20, 2026-11-09). No existe `interaccion-e-inspeccion-review-log.md`, así que no hay recibo de hashes que comprobar; se revisa todo el documento.
- **Contrastado con:** `design/slice/slice-v0.3.md` (§10/§16 pistas, A.2 a A.7, B.3, B.6, B.7), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, y los GDDs de `jugador-en-primera-persona.md` (reglas 11, 18, 19, 24, 33; tablas de gestos y contrato), `entrada-y-controles.md` (reglas 6, 8, 10, F8, tabla de contextos), `marco-de-puzles.md` (reglas 7, 9, 11, 17, 18, 33, 35; F3, F4; matriz), `estado-y-bus-de-eventos.md`, `escena-de-planta.md` (reglas 9.6 y 18), `base-de-contenido-narrativo.md`, `docs/engine-reference/godot/`.
- **Decisión del usuario aplicada:** el P6 tiene **dos** niveles de pista (B.6; los puzles 1 a 5 tienen tres). Ninguna regla ni AC del GDD 7 asume tres niveles para todos (el GDD 7 no habla de pistas); la repercusión sobre 7 se trata en H-13 y en «Preguntas».

## Veredicto: NEEDS REVISION

Los 20 hallazgos de la primera revisión están en su mayoría resueltos y bien resueltos: el algoritmo de foco (F1) es coherente, la API pública existe (reglas 27 a 31), el catálogo tiene 35 entradas que coinciden con la tabla, hay ACs de evidencia visual y los cálculos de F1 a F6 cuadran al recalcularlos. Lo que impide pasar el documento a programadores ya no es el diseño del sistema sino que **el contrato 2↔7↔9 todavía no cierra por sus bordes**: 7 describe operaciones y nombres que el Jugador (cuya lista de API es cerrada) y el Marco no coinciden en usar, y hay tres caminos reales del slice (salir de la vista del P6 antes de que aparezca la carta, la cadena de bloqueos de un compartimento y la sustitución de `sostener`) sin regla. Ninguno obliga a rediseñar; todos son enmiendas del documento y de dos notas en el Jugador y el Marco.

## Completitud (workflow `standard`: 6/6 requeridas presentes)

`gdd-structure-check.sh`: PRESENT Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria; sin ABSENT ni PLACEHOLDER. Player Fantasy y Tuning Knobs son consultivas en `standard` y están completas. Spot-read de las secciones de las que depende el veredicto (reglas 3, 10, 13, 19, 23, 27, 30; F1; ACs de contrato): no son encabezados vacíos.

## Grafo de dependencias

| Sistema | GDD en disco | ¿Lista a 7? | Nota |
|---|---|---|---|
| 1 Entrada | sí | sí (reglas 6, 8, tabla de contextos, fila 7) | Cambios derivados aplicados (`leer` fuera de `inspección`, «sentarse», bloqueo de 7) |
| 2 Jugador | sí | sí (fila 7 de interacciones, «contrato») | **Nombres y supuestos aún sin reconciliar** (B-01, I-02) |
| 3 Estado y bus | sí | **sí** (línea 143, ahora lista a 7 como lector y emisor) | El GDD 7 sigue diciendo que **no** (I-10) |
| 4 Escena de planta | sí | **sí** (regla 18f y fila de Dependencies) | El GDD 7 sigue diciendo «falta el 4» en el índice (I-10) |
| 9 Marco | sí | sí | **Firmas distintas** (B-03) |
| 18 Contenido | sí | sí (incluye las diez claves `UI_VERBO_*` y `OBJ_A02a`–`c`) | OK |
| `systems-index.md` | sí | sí, fila 7 y Feature Layer punto 1 = «1, 2, 4, 18 (blanda: 3)» | El GDD 7 (Quick reference, línea 13) todavía dice «1, 2, 18» |
| 8, 10, 19, 20, 21, 22, 24, 28 | no existen aún | n/a | No es un fallo; deben adoptar las reglas 3 y 30 |

## Valores del registro

Búsqueda en el documento de los nombres y valores del registro (`alcance_interaccion_m`, `player_fov_vertical_default_deg`, `player_camera_transition_cap_s`, `long_press_threshold`, `close_view_after_s`, `t_vista_salida_s`, `F6_ppm`, `radio_apuntado_m`, `pick_min_px`, `r_max_inspeccion_m`, `lectura_min_s_A04`, `t_vista_entrada_D01a_s`, `lock_max_s`) y de los números 1,8 / 70° / 3 s / 0,5 / 1,5 / 44 / 0,06 / 0,20 / 2,0 / 1,0:

- Coinciden: 1,8 m; 70°; tope 3 s; `t_hold` 0,5 s (el GDD cita `long_press_threshold`); 1,5 s de `close_view_after_s` (el GDD solo lo nombra); 0,06 m; 44 px; 0,20 m; 2,0 s; 1,0 s; F6 `(H/2)/(d·tan(FOV_v/2))` y 2.203 px/m.
- **Discrepancia de nombre:** el registro tiene `t_vista_salida_s` (propietario: Jugador, 0,5 s, «no usar 0,6 s», `referenced_by` 7), mientras el GDD 7 afirma en F4 «No existe `t_vista_salida_s`». Una de las dos frases sobra (m-18).
- **Discrepancia de nombre:** el registro (`player_effective_fov`, notas) dice «7 lo lee con `fov_vigente()`»; el Jugador (regla 19 y 33) llama a la operación `fov_actual()` y su API es una lista cerrada. Ver I-02.
- `lock_max_s` ya no cita a 7 (corregido en el registro; el GDD no lo usa). OK.
- No registrados todavía y citados como constantes por el GDD: `radio_pegajoso_m`, `t_gracia_foco_s`, `desempate_prof_m`, `theta_fill_deg`, `d_ins_min/max`, `t_mano_s`, `texto_max_caracteres`. Son †, no hay conflicto; conviene registrarlos al cerrar el lote (m-19).
- La «Propuesta de registro» del GDD (líneas 567 a 585) está obsoleta: casi todo lo que propone ya figura en `entities.yaml` (m-19).

## Estado de los hallazgos de la primera revisión

| H | Estado | Comentario |
|---|---|---|
| H-01 detección/objetos planos/B05 | Resuelto | Regla 5 y F1 en cuatro pasos. Residuos: B-06 (haz de 7 rayos no implementa F1 completo) y m-14 (ejemplo y AC-04 con geometría que el propio diseño excluye) |
| H-02 contrato con el Jugador | **Parcial** | Rayo, regreso de 0,5 s y sin ocultar manos adoptados. Quedan: V05/`sostener` (B-01), nombres y peticiones ‡ obsoletas (I-02) |
| H-03 `bloquea_s` / `sin control` | Resuelto en concepto (D7-13) | Queda el orden «gesto rechazado» (I-04) |
| H-04 API pública | **Parcial** | API añadida; no coincide con la del Marco (B-03) y falta el bloqueo en manos del dueño (B-05) |
| H-05 contrato del manejador/catálogo | Mayormente resuelto | `NO`, `etiqueta()`, tabla con disponibilidad. Quedan AC-37 (I-05) y esquema (I-07) |
| H-06 foco | Resuelto | Y explícito; AC-05 en pasos de física |
| H-07 PointerEvent | Resuelto | Tabla gesto→fase→elemento. Verificada contra Marco regla 11 |
| H-08 unidades y motor | Resuelto como riesgo declarado | V1 a V5 como «pendiente de verificación» y no se afirma nada del motor sin respaldo. V5 ya lo cierra el Jugador (regla 11): actualizar (I-02) |
| H-09 lectura apilada | Resuelto en 7 y en el Jugador (regla 24, estado Cámara cedida) | Falta definir cuándo es legal `abrir_lectura` (B-04) |
| H-10 secuencia D01a | Resuelto (D7-19) | Queda la transferencia del bloqueo (B-05) |
| H-11 knobs | Mayormente resuelto | Garantía de F3 (m-13) |
| H-12 ACs V | Resuelto | AC-V1 a V8 |
| H-13 dependencias | Resuelto en los otros GDDs; **el texto de 7 quedó obsoleto** (I-10) |
| H-14 a H-20 | Resueltos salvo restos en m-17 a m-19 |

## Hallazgos

Severidad: **bloqueante** (resolver antes de implementar o de dar por cerrado el contrato) · **importante** · **menor**.

### Bloqueantes

**B-01 · bloqueante · Inspección de `V05`: 7 y el Jugador describen dos mecanismos incompatibles** · regla 13 (l. 66), Interactions fila 2 (l. 189), Dependencies fila 2 (l. 340), AC-20b; Jugador reglas 24 y 33, tabla de gestos (`HAND_HOLD_ITEM`), contrato fila «Objetos sostenibles» (l. 299)
- 7 dice «**No se usa `sostener`**: `V05` no es un ítem, sino un objeto de escena que posiciona 7» y pide al Jugador (‡) admitir `HAND_HOLD_ITEM` sin ítem. El Jugador ya resolvió eso al revés: `sostener(obj_id, mano)` **admite objetos de escena declarados sostenibles en datos (`V05`, `A03`, tarjetas) y «7 declara cuáles»**; la tabla de gestos describe `HAND_HOLD_ITEM` como «Sostener y girar un objeto (V05, A03, tarjetas)» y su AC-32 prueba «girar el peluche (V05, `HAND_HOLD_ITEM`)». Su API es una lista cerrada comprobada por igualdad, de modo que no habrá una variante «sin ítem». El catálogo de 7 no tiene ningún campo para declarar sostenibles.
- Consecuencia: si 7 mueve el objeto por su cuenta y solo pide el gesto, el Jugador no sabe que hay un objeto en la mano (`reposo()` «suelta el objeto» no soltaría nada) y los fundidos `t_item_dentro/fuera` (0,3 s) chocan con los `t_mano_s` (0,4 s) de 7. Además `A03` y las tarjetas figuran como sostenibles en el Jugador y como «no inspeccionables» en 7 (D7-29): contradicción entre los dos documentos.
- La secuencia «`reproducir_gesto(HAND_REACH)` **seguido de** `HAND_HOLD_ITEM`» tampoco es válida con las reglas del Jugador: `HAND_REACH` es bloqueante (≤ 0,5 s) y «una petición mientras otro gesto bloqueante está en curso se rechaza; no se encola». Hay que esperar `gesto_terminado(HAND_REACH)`; y como `HAND_REACH` puede durar hasta 0,5 s frente a `t_mano_s` = 0,4 s, la regla no dice qué señal da por terminada la entrada (¿el temporizador de 0,4 s o el aviso?).
- *Arreglo:* elegir una vía y escribirla en los dos GDDs. Propuesta: 7 usa `sostener("V05", izquierda)` (el Jugador ya tiene el fundido y la ranura) y declara en el catálogo `sostenible: true` para `V05` solamente (retirar `A03` y tarjetas de la lista del Jugador, que las sostiene 20 con ítems); la transición de entrada termina en el último de `gesto_terminado(HAND_REACH)` y el fin de `t_mano_s`; quitar la petición ‡ de «`HAND_HOLD_ITEM` sin ítem»; reescribir AC-20b (hoy exige «sin llamar a `sostener`»).

**B-02 · bloqueante · `abrir_lectura(doc_id)`: no se define cuándo es legal ni qué pasa si no lo es (camino real del P6)** · regla 27b (l. 105), regla 30; Marco reglas 35 y 17 (P6 `IMMEDIATE`, `play_resolution` no bloqueante), matriz (P6: `close_view_after_s` nulo, «su final pide `abrir_lectura(I-07)`»), AC-42 y D9-23 (relectura de la carta desde `exploración`); Entrada tabla de contextos (`lectura`: «sin cursor»)
- La regla 27b solo describe un caso: lectura **apilada sobre una vista abierta**. El Marco necesita tres más y 7 no los describe:
  1. **P6 resuelto mientras la vista sigue en `Abierta`** (el caso que 7 sí cubre).
  2. **El jugador sale de la vista antes del final de la presentación.** Esa presentación es no bloqueante (`SFX_LOCK_CLICK` 0,3 s + tapa 1,6 s ≈ 1,9 s antes de la carta) y `atrás` está permitido: la vista pasa a `Saliendo` (contexto bloqueado hasta `camara_devuelta`) o a `exploración` cuando el Marco pide `abrir_lectura(I-07)`. No hay regla para ninguna de las dos: ¿se rechaza (y la carta solo queda en el bolsillo), se encola hasta volver a `exploración`, o se abre en `exploración` obligando al jugador a leer en mitad de un paseo? Es la carta que paga el clímax del slice (`carta_variante`).
  3. **Relectura desde el bolsillo** (AC-42 del Marco): `abrir_lectura` desde `exploración`. 7 la admite implícitamente («sin que el jugador mantenga `interactuar`»), pero no pide el contexto `lectura` a Entrada en ese caso ni dice qué manos (`HAND_READ`) ni qué hace con una pulsación o gesto en curso.
  4. Con la lectura apilada sobre una vista, el contexto `lectura` es «sin cursor» (Entrada) y la vista tenía cursor visible: falta decir que 7 oculta el cursor y que Entrada restaura la posición (regla 6 de Entrada la restaura «tal como estaba»). Y si había un gesto en curso en la vista (P1 a P5 no abren lecturas, pero la regla es general), no se dice que se cancela.
- *Arreglo:* añadir a la regla 30 una tabla de precondiciones de `abrir_lectura`: **permitida** en `exploración` (sin transición) y apilada sobre `vista` en `Abierta`; **aplazada hasta el estado estable** si hay una transición bloqueante (vista en `Saliendo`, gesto bloqueante) con un tope y registro; **rechazada** con menú, llamada, `ordenador` u otra lectura. Decidir el caso 2 (ver «Preguntas»). Añadir ACs para los cuatro casos.

**B-03 · bloqueante · El contrato 7↔9 no coincide en nombres ni en firmas** · reglas 20, 23, 30; Marco regla 9 (`PuzzleController`), 11, 33; Interactions fila 9
- 7: `registrar_receptor(vista_id, receptor)`, `abrir_vista(vista_id) → {ACEPTADA, RECHAZADA(motivo)}`, y el receptor implementa `elements()`, `handle_pointer`, `on_open()`, `on_close(motivo)`. Marco: «7 se registra con el marco como *receptor de vista*… (`abrir_vista(view_id, receptor)`; **el marco es el receptor**)», y su controlador implementa `on_engage()`, `on_disengage(reason)`, `handle_pointer(ev)`, `cancel_gesture()`, `elements()`. Son dos firmas de `abrir_vista`, dos pares de ganchos (`on_open/on_close` frente a `on_engage/on_disengage`) y el sentido del registro dicho al revés («7 se registra con el marco» frente a «el marco llama a `registrar_receptor`»). Un implementador de 7 y otro de 9 construirían interfaces que no se conectan.
- El `PointerEvent` de 7 añade la fase `actualización` y el gesto «desplazar cursor»; el Marco enumera solo `inicio`/`fin`/`cancelación` y cuatro gestos. Probablemente el marco ignora lo demás, pero debe decirlo, porque la inactividad (F3 del Marco, P6 con pista a 10 s y 20 s) se mide con «gestos de inicio/fin/cancelación, no movimiento»: si el marco contara las `actualización` de 7, las dos pistas del P6 nunca saltarían.
- *Arreglo:* un único vocabulario en un único sitio. Propuesta: el GDD 7 es el dueño de la interfaz `ViewReceiver` (`elements`, `handle_pointer`, `on_open`, `on_close(motivo)`, `cancel_gesture`), `registrar_receptor` en la configuración y `abrir_vista(vista_id)`; el Marco adapta `on_engage/on_disengage` a esos nombres (o 7 adopta los del Marco, pero uno solo). Añadir a Marco regla 11 que `actualización` no reinicia la inactividad. Anotarlo en «Cambios requeridos en otros GDDs».

**B-04 · bloqueante · Falta la operación con la que un dueño mantiene el bloqueo durante su propia animación; la cadena de B.3 deja huecos** · regla 19 (l. 78), regla 10, regla 30, F4 (ejemplo), AC-26, D7-19; Entrada regla 8 («el bloqueo lo declara y mantiene 7»)
- La secuencia del slice B.3 es: pulsar `D01a` → `BOX_C1_OPEN` (1,6 s, animación **del dueño 10**, «transición propia») → cámara 1,0 s → cursor. Entrada dice que **solo 7** declara las transiciones bloqueantes. La API pública de 7 (regla 30) no tiene ninguna operación para que un dueño (10, y también 8, 19, 20, 22) pida «mantén el contexto bloqueado mientras mi animación dura»: sin ella, 10 no puede bloquear por su cuenta y 7 no sabe cuándo termina la animación.
- Sin traspaso atómico hay un hueco entre «fin de la animación del dueño» y «`abrir_vista` acepta»: el bloqueo se libera, el contexto vuelve a `exploración` un fotograma y `abrir_vista` «rechaza si… la llamada no ocurre en `exploración` o en la transición del propio dueño» (regla 30). El jugador puede mover, pulsar `atrás` o abrir otro objeto en ese fotograma.
- El catálogo de ejemplo da a `D01a` `gesto_hecho: HAND_REACH` (≤ 0,5 s, bloqueante) **además** de la animación del compartimento (1,6 s) y la cámara (1,0 s): son **tres** transiciones consecutivas, hasta 3,1 s desde la pulsación, y AC-26 solo prueba dos (2,6 s). Cada tramo queda bajo el tope de 3 s, pero el jugador pasa más de 3 s sin control sin que ninguna regla lo diga.
- *Arreglo:* añadir `bloquear_contexto(razon) -> token` / `liberar_contexto(token)` (o `abrir_vista(vista_id, desde_transicion = token)` que transfiere el bloqueo sin soltarlo), con tope de 3 s por token y registro; decidir si `D01a`–`D01d` llevan `gesto_hecho` (propuesta: ninguno, la animación del compartimento ya es el gesto) y probar el peor caso completo en AC-26.

### Importantes

**I-01 · importante · Gesto rechazado: la regla 10 pide un orden imposible** · reglas 3 y 10 (l. 40, 60), Edge Cases (l. 297), AC-13
- La regla 3 dice que `interact()` devuelve `HECHO` y *después* se reproduce `gesto_hecho`. La regla 10 y el edge case dicen que si el Jugador rechaza el gesto «no se ejecuta el efecto del objeto». Pero cuando se pide el gesto el dueño ya ejecutó el efecto y escribió sus hechos (regla 3: «El manejador es quien escribe hechos»). AC-13 solo comprueba que no se bloquea el contexto, no que el efecto no se ejecute: o la regla o el AC son erróneos. Un gesto bloqueante en curso puede existir porque lo pidió otro dueño (22: `HAND_PHONE_PUTDOWN`; 20) sin que 7 lo haya declarado.
- *Arreglo:* o 7 pide el gesto **antes** de llamar a `interact()` (reservar la ranura; si se rechaza, no se llama) o se reconoce que el efecto ya ocurrió y se elimina «no se ejecuta». Propuesta: reservar primero. Reescribir el edge case y AC-13.

**I-02 · importante · Nombres y peticiones al Jugador desfasados respecto de su GDD (lista de API cerrada)** · reglas 19, 23, 24; F6; Interactions fila 2; Dependencies fila 2; registro (`player_effective_fov`, `t_vista_salida_s`); Jugador reglas 11, 19, 33, y tabla de contrato
- `fov_vigente()` ‡ no existe; el Jugador ofrece `fov_actual()` (incluye una cesión en curso). Las señales se llaman `camara_cedida(propietario)`, `camara_devuelta(propietario)` y `gesto_terminado(id, motivo: completo | cancelado | tope)`; 7 las nombra «cámara cedida»/«cámara devuelta» con ‡ como «solicitudes pendientes» cuando ya existen. 7 filtra por `propietario` o recibiría los avisos de otro dueño; tampoco dice qué hace con `cancelado`/`tope` (¿cuenta el efecto como hecho?).
- Ya están resueltas en el Jugador y 7 las sigue marcando pendientes: avisos de cámara, `fov_actual`, plano cercano (`near` 0,05 m, < 0,19 m), estado Cámara cedida + `lectura` (regla 24: ranuras izquierda/derecha), propietarios cerrados `interaccion:vista`/`interaccion:ordenador`. La V5 (transformada del barrido) también la resuelve el Jugador (regla 11: origen = estado de física sin interpolar y sin balanceo; dirección = la del fotograma actual): 7 sigue diciendo «la transformada del paso de física… ver V5» (l. 46) y V5 en Open Questions.
- *Arreglo:* sustituir por los nombres reales; borrar las ‡ cerradas; copiar el criterio de la regla 11 del Jugador en la regla 5; definir la respuesta de 7 a `cancelado` y `tope`; alinear la nota del registro (`fov_actual`).

**I-03 · importante · `cerrar_modos()`: contradicción con la descarga de escena y sin señal de «pila vacía»** · regla 27a (l. 105), regla 30, Edge Cases (l. 307, 329), AC-35
- La regla 27a y la 30 dicen que la **descarga de escena** puede pedir `cerrar_modos()` y se emiten avisos de cierre con motivo `sistema`; el edge case de la línea 329 dice que al descargar la escena con un modo abierto «no emite avisos de cierre». Una de las dos es falsa (y el Marco regla 18 cuenta con la interrupción por «descarga de la escena» para `RESOLVING`).
- El director (21) pide `cerrar_modos()` «antes de pedir `sin control`» (l. 307), pero los cierres son asíncronos (`devolver_camara` 0,5 s) y no hay aviso de «todos los modos cerrados»; además `ordenador` queda **excluido** (AC-35), de modo que con el ordenador abierto el director no puede obtener control limpio y la cámara queda cedida. No hay regla de qué hace 21 en ese caso.
- Tampoco se dice si el cierre forzado de `inspección` es instantáneo o dura `t_mano_s`.
- *Arreglo:* una sola redacción para la descarga; aviso único «modos cerrados» (con la lista) al vaciarse la pila; decidir si el director debe poder cerrar `ordenador` (pidiéndolo a 19 con un contrato) y fijar la duración del cierre forzado.

**I-04 · importante · `cerrar_vista` durante la entrada y red de seguridad del Marco** · regla 23, regla 30 (idempotencia), Edge Cases (l. 316, 322); Marco regla 7 (red de seguridad), regla 33
- La regla 23 supone la vista `Abierta`. El Marco (regla 7) pide `cerrar_vista(view_id, 'sistema')` cuando una vista de un puzle bloqueado se abre por otra vía: esa llamada puede llegar justo tras `abrir_vista`, con la vista en `Entrando` (cámara a medio camino). No se define si se espera a «cámara cedida» para devolver, o se cancela la cesión (el Jugador interpola «desde donde esté» solo para el mismo propietario; la regla 18 no define devolver una cesión incompleta).
- El Marco (regla 33) y F4 (cierre automático) pueden coincidir con un `atrás` ya en curso: 7 los trata como «la vista no está abierta, no hace nada y se registra»; en desarrollo eso es un error visible por una condición de carrera normal.
- *Arreglo:* tabla de estados de la vista × petición de cierre (`Entrando`, `Abierta`, `Saliendo`); `Entrando` aplaza hasta `camara_cedida` y luego cierra; `Saliendo` ignora sin registrar como error.

**I-05 · importante · AC-37 y la regla 31 no son reproducibles tal como están escritas** · regla 31 (l. 134), AC-37 (l. 497); slice A.3 y A.4
- El filtro dice «IDs del Anexo A cuya columna **“Interacción”** no sea “Ninguna”, “Visibles siempre”, “Ver…” o “Emite…”». Al aplicarlo al slice: (a) la tabla de A.3 (`C01`–`C08`) **no tiene columna «Interacción»** (tiene «Función»); (b) `C05`, `C06`, `C07` dicen «Ver B.1»/«Ver A.5»/«Ver A.6» → el filtro los **excluye** y el catálogo los **incluye**; (c) `B04` («Puzle 2»), `C02`, `C03` y `C04` los **incluye** el filtro y el texto los excluye. El catálogo de 35 entradas es correcto en sí; lo que falla es la regla con la que la prueba lo «deriva».
- *Arreglo:* sustituir el filtro por una regla verificable: un fichero de datos del Anexo A (o una columna `interactuable: sí/no` añadida al slice) y una lista de excepciones explícita con motivo (`C05`–`C07` por «Ver…»; `B04`, `C02`–`C04`, `D01`, `V07`, `R03`, `B08`, puerta de Recepción excluidos). AC-37 compara contra ese fichero, no contra una columna que no existe en todas las tablas.

**I-06 · importante · Dependencias: el texto de 7 quedó obsoleto tras la propagación** · Quick reference (l. 13), Dependencies (l. 343, 345, 362), Open Question 5 (l. 565), «Propuesta de registro» (l. 567 a 585)
- «El GDD del 3 **aún no lista** a 7» (l. 343 y 362): falso; `estado-y-bus-de-eventos.md` l. 143 lo lista. «El índice… falta el 4 en ambas» (l. 345): falso; el índice (fila 7 y Feature Layer 1) ya dice «1, 2, 4, 18 (blanda: 3)». El Quick reference sigue sin el 4.
- Open Question 5 («¿La pausa detiene el tope de 3 s?») ya la contesta Entrada (F8: «el tope… se detiene con la pausa igual que el de `sin control`»); la regla 32 de 7 lo afirma. Cerrarla.
- La «Propuesta de registro» propone entradas que ya existen en `entities.yaml` (`radio_apuntado_m`, `pick_min_px`, `r_max_inspeccion_m`, `lectura_min_s_A04`, `t_vista_entrada_D01a_s`, `F6_ppm`).
- *Arreglo:* editar esas líneas; el grafo real quedó cerrado.

**I-07 · importante · El esquema del catálogo no es formal y se contradice en un punto** · reglas 2 y 31, AC-38
- AC-38 pide «valida contra el esquema», pero el esquema no está: solo hay tres ejemplos «ilustrativos». `verbo_corto` y `etiqueta_corto` llevan la misma clave en el ejemplo (`"UI_VERBO_DESCOLGAR"` dos veces): no queda claro si `verbo_corto` es un identificador de verbo, una clave de etiqueta o un booleano. No hay ejemplo de `INSPECCION_MANO` (falta `pose_inspeccion`, `sostenible` según B-01) ni de `INSPECCION_TEXTO`.
- La regla 31 dice que `modo` «solo existe en los efectos que abren un modo», y el ejemplo de `D01a` es `DELEGAR` con un bloque `modo` de vista (un `DELEGAR` no abre modo; lo abre 10 llamando a `abrir_vista`).
- *Arreglo:* publicar el esquema (tipos, obligatorios, valores por defecto) como parte del GDD o como fichero `.schema.json` citado; dar un ejemplo por efecto; aclarar que `modo.vista_id` en un `DELEGAR` son datos que 7 entrega a `abrir_vista`.

**I-08 · importante · El F1 documentado no se puede implementar con el respaldo de 7 rayos** · F1 (pasos 4 y 5, l. 210 a 211, 226), regla 7, D7-27
- Con `intersect_ray` (lo único que cubre `docs/engine-reference/godot/modules/physics.md`) un haz de 1 central + 6 en un anillo de 0,06 m devuelve, como mucho, «el rayo central toca» y «tal rayo del anillo toca». Eso da el criterio (i) «contiene el eje» (rayo central) pero **no** el (iii) «menor distancia al eje» (solo se sabe que está entre 0 y 0,06 m), ni la retención por `radio_pegajoso_m` = 0,15 m (> 0,06 m: ningún rayo del anillo llega a medir una distancia de 15 cm a un collider que no se toca). La retención y el desempate (iii) necesitan una consulta de punto más cercano (`get_rest_info`, `intersect_shape`…) que la referencia del motor no cubre.
- Las pruebas AC-04, AC-05, AC-X2b se escriben contra «un mundo de física falso» que sí devuelve distancias; el ADR de V1 debe demostrar equivalencia, pero hoy nada impide que se implemente el respaldo y se declare «cumple».
- **NOT SOURCEABLE** — el comportamiento de `ShapeCast3D`/`intersect_shape`/`get_rest_info` con Jolt en 4.7 no está cubierto por `docs/engine-reference/godot/`; esta revisión no lo afirma.
- *Arreglo:* en F1 y en D7-27 declarar que el respaldo de 7 rayos **degrada** (i), (ii) y la retención (indicar exactamente cómo: retención solo por tiempo y por que el rayo central siga a ≤ `radio_apuntado_m`), o bloquear la implementación de 7 hasta el ADR V1. Cablearlo a la puerta: sin ADR de V1, la historia de «detección» no pasa de «en pruebas».

**I-09 · importante · Gesto de cámara de las pistas (P1 nivel 1) fuera del contrato de cámara** · slice §10 y B.1 (l. 136, 724: «gesto de cámara hacia la impresión, 3 s»); Jugador regla 18 (`propietarios_camara` cerrada, solo `interaccion:vista` e `interaccion:ordenador`); Marco regla 25 (efectos de pista)
- El slice describe como pista un movimiento de cámara, y el Jugador solo concede la cámara a 7 «en nombre de 9, 10 y 19» con dos propietarios. 7 no define ninguna operación para ejecutar un movimiento de cámara de pista del Marco (ni dice que lo deniega). No es un fallo del P6 (cuyas dos pistas son texto por inactividad: 10 s y 20 s) pero es contrato 2↔7↔9 sin dueño.
- *Arreglo:* decidir quién ejecuta esos gestos (7 con un tercer propietario `interaccion:pista`, o el Jugador con una operación propia) o mover la pista a otro efecto. Ver «Preguntas».

### Menores

**m-13 · menor · La garantía de F3 solo vale para `theta_fill` = 25°** · F3 (l. 251), AC-17, Tuning Knobs
`d_ins − r ≥ 0,19 m` se demuestra con el valor por defecto. Con `theta_fill` = 40° (dentro del rango seguro 15–40) y `V05` (r = 0,104 m): d = 0,104/tan 20° = 0,286 m y `d − r` = 0,182 m < 0,19. Ya no importa para la cámara (plano cercano del Jugador 0,05 m), pero la afirmación «para cualquier r» no es cierta en todo el rango. Reducir el rango de `theta_fill` o sustituir la garantía por «`d − r` ≥ `near` + margen».

**m-14 · menor · Ejemplo (2) de F1 y AC-04 describen una geometría que el diseño excluye** · F1 ejemplo (l. 225), tabla de objetos (l. 184), AC-04
El diseño exige que el collider de `B05` quede ≥ 0,02 m fuera del de `B02` en planta: los dos nunca contienen el eje a la vez, y entonces la `prioridad` 2 > 1 solo actúa cuando el eje no cae en ninguno. Con esa `prioridad`, apuntar a ≤ 6 cm de ambos da «Leer» aunque la base esté más cerca del eje. Aceptable, pero el ejemplo y AC-04 deberían presentarse como pruebas del algoritmo general, y el AC-04c de integración debe cubrir la banda de 2 a 6 cm.

**m-15 · menor · AC-X2 mezcla píxeles de pantalla con cuentas de ratón** · AC-X2 (l. 512)
«Ruido de ±6 px… = ±0,39°» convierte con el FOV (píxeles de pantalla). El ruido de un ratón es en cuentas de ratón y el giro es `k_m` = 0,10 °/px (Entrada, tabla de valores): ±6 cuentas = ±0,6°. Ambas cifras están bajo `radio_pegajoso_m` (≈ 4,8° a 1,8 m), pero el AC debe decir qué se simula.

**m-16 · menor · Cuenta de etiquetas** · reglas 25 y Dependencies: «nueve etiquetas» frente a las diez claves que lista el GDD 18 (Encender y Apagar separadas). Alinear.

**m-17 · menor · Reglas pequeñas sin AC** · (a) `lectura` sin `lectura_min_s` no emite «lectura completada» (solo `A04`); (b) `etiqueta()` nulo; (c) rechazo de `abrir_lectura` con otra abierta (regla 27b, «se rechaza y se registra») no tiene AC; (d) regla 28 «al reanudar, el objetivo se recalcula en el primer fotograma» solo la cubre AC-16 en lo de cancelar.

**m-18 · menor · `t_vista_salida_s`** · F4 (l. 260) dice «No existe `t_vista_salida_s`» y el registro lo conserva como clave del Jugador (0,5 s, referenciada por 7). Citar `t_devolver` del Jugador y pedir que el registro cambie la clave a `t_devolver` o que 7 diga «alias».

**m-19 · menor · Registro** · añadir `radio_pegajoso_m`, `t_gracia_foco_s`, `desempate_prof_m`, `texto_max_caracteres` y retirar la sección «Propuesta de registro» ya cumplida.

**m-20 · menor · Pregunta abierta de `D04`** · Open Question 3 sigue pendiente del GDD del puzle 5 (si `D04` abre una vista o solo texto); si abre vista, la fila 35 → 36 y AC-37 cambian. No bloquea.

## Cálculos verificados (sin hallazgo)

- F1 ejemplo (1): 1,38 m ≤ 1,8 ✓. Ejemplo (2): grupo hasta 1,13 con Δ = 0,02 ≤ 0,03 ✓; Δ = 0,10 fuera ✓. Ejemplo (4): 1,50 − 0,03 = 1,47 ≤ 1,499 ✓; pared a 1,0 < 1,47 ✓.
- Regla 7 / AC-05: 7 pasos × 16,667 ms = 0,1167 s ≤ 0,12; 8 pasos = 0,1333 s > 0,12 ✓.
- F2: 0,30/0,5 = 0,6; 0,12/1,5 = 0,08 ✓.
- F3: r = 0,12·√3/2 = 0,1039 m; tan 12,5° = 0,2217; d = 0,4688 m; r = 0,2 → 0,902 → 0,60 m; ángulo 2·atan(0,2/0,6) = 36,9°; 25/70 = 36 % ✓. (Reserva: m-13.)
- F4 (referencia del Jugador): s(0,25) = 0,15625; s(0,5) = 0,5; s(0,75) = 0,84375 ✓.
- F5: 0,5 + 30/14 = 2,64 s; 0,5 + 90/14 = 6,93 s; × 2 = 5,29 s; 8 × 3 = 24 s ✓.
- F6: 540/(0,35·tan 35°) = 2.203 px/m; 0,04 m = 88 px; 0,10 m = 220 px; 600/0,24507 = 2.448; con 70° horizontal en 16:9 (FOV_v 43,0°) = 3.917 ✓.
- Catálogo: la tabla de objetos suma 35 filas lógicas (9 + 10 + 2 + 3 + 1 + 1 + 3 + 1 + 4 + 1) ✓.

## Engine (Godot 4.7): qué se afirma y qué no

Solo se confirma lo documentado en `docs/engine-reference/godot/`: `intersect_ray` (physics.md), la reestructuración de la interpolación física 3D (`breaking-changes.md`, «API sin cambios, internos distintos») y que `@abstract` existe desde 4.5. **NOT SOURCEABLE** (no cubierto por esa referencia; el GDD ya los declara V1 a V5 y esta revisión no los afirma): consultas de forma y `ShapeCast3D` con Jolt (V1, I-08); eje por defecto del FOV de `Camera3D` (V2); colocar el cursor y alternar ratón capturado/visible (V3); altura lógica del viewport con el estiramiento del proyecto (V4); tipado de JSON ya no aplica a 7. Ninguno de los cinco está cableado a una puerta: añadir que AC-V6, AC-32 y la historia de detección no pasan de «pendiente» hasta tener el ADR (hoy son «riesgo declarado» que no impide marcar la historia como hecha).

## Alineación con pilares y tono

Sin contradicciones con *Autonomía como progresión* (D7-4: lo no disponible no tiene icono), *Tensión sin castigo* (`atrás` siempre cierra, sin temporizadores, sin fallos) ni *Información incompleta* (el pie nunca lleva información necesaria, D7-25). Dos puntos de tono para el usuario en «Preguntas»: la carta del P6 si el jugador abandona la vista pronto, y el compromiso irreversible del P6 con una sola pulsación al soltar.

**P6 y los dos niveles de pista:** el GDD 7 no contiene ningún supuesto de «tres niveles» y es coherente con B.6 y con la matriz del Marco: sus ACs no dependen de ese número; la inactividad de 10 s y 20 s depende de que 7 entregue solo `inicio`/`fin`/`cancelación` como gestos (B-03). El único cabo del P6 en 7 es la carta (B-02).

## Scope signal

Rough scope signal: **L** (6 fórmulas, 10 contratos con otros sistemas, API de 8 operaciones y dos interfaces, un ADR de barridos/picking/cursor pendiente). El productor debe verificarlo antes de planificar el sprint.

## Preguntas para el usuario

1. **Carta del P6 (tono/ritmo del clímax).** La presentación del P6 es no bloqueante (≈ 1,9 s hasta que aparece la carta). Si el jugador pulsa `atrás` en ese intervalo, ¿la carta debe (a) abrirse igualmente al volver a `exploración`, (b) no abrirse y quedar solo en el bolsillo (relectura a demanda, como ya prevé D9-23), o (c) bloquear la salida de la vista hasta que aparezca? Hoy la regla 30 de 7 no lo decide (B-02) y la opción (c) contradiría D7-11 («atrás siempre cierra»).
2. **Gesto de cámara como pista (alcance).** El slice usa «gesto de cámara hacia la impresión, 3 s» como pista de nivel 1 del P1. Obligaría a ampliar el contrato de cámara (tercer propietario o operación nueva del Jugador). ¿Se mantiene tal cual en el slice o se sustituye por un efecto sin cámara (por ejemplo, destello del objeto)? (I-09).
3. **Elección única del P6 sin confirmación.** `seleccionar` se entrega al soltar y no hay deshacer (D-14). Los botones están separados por regla 22, pero un clic accidental fija `carta_variante` sin confirmación. ¿Se acepta esa irreversibilidad (coherente con «sin fallo» pero no con «nunca pierdes algo por pulsar mal», Player Fantasy) o se añade una confirmación por pulsación prolongada (`mantener` ≥ `t_hold`)? Cambia el tono de la decisión más importante del slice.

## Siguiente paso recomendado

1. Resolver B-01 a B-04 en 7 y, con ellos, las notas correspondientes en el Jugador (reglas 24 y 33, tabla de gestos), en el Marco (reglas 9 y 11) y en el registro (`fov_actual`, `t_vista_salida_s`).
2. Resolver I-01 a I-09 en el mismo lote (la mayoría son edición de texto en 7).
3. Volver a pasar la revisión solo tras cerrar los bloqueantes; los cálculos de «Cálculos verificados» pueden reutilizarse.
