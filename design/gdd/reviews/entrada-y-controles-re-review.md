# Re-review independiente: Entrada y controles (sistema 1)

Fecha: 2026-11-09 · Revisor: subagente independiente (no autor) · Modo: lean · Workflow: `standard` (`modes.rigor: standard`, sin `system_overrides`)
Documento: `design/gdd/entrada-y-controles.md` (53 975 bytes, leído por rangos) · Revisión previa: 2026-11-08, NEEDS REVISION (4 bloqueantes, todos aplicados; verificado abajo).
Contrastado con: `design/slice/slice-v0.3.md` (§5, §10/línea 118, Anexo B, P6 con dos niveles), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, GDDs 2, 3, 4, 5, 6, 7, 9 y 18, `docs/engine-reference/godot/modules/input.md`.

## Veredicto: NEEDS REVISION

Las fórmulas recalculan bien (F1 0,613; F3 57,6 °/s; F4 30 / 7,4 / 1,2 °/s; F5a 338 px/s; F5b 0,833 px/fotograma). Los 4 bloqueantes de la revisión anterior están resueltos. Quedan 3 bloqueantes nuevos, uno de implementabilidad y dos de contrato con 7 y 4, más importantes sobre todo de propagación del lote 2/5/7/9.

## Completitud (workflow `standard`)

5 de 5 secciones requeridas presentes (Overview, Detailed Design/Rules, Edge Cases, Dependencies, Acceptance Criteria) y Formulas (el sistema define umbrales y velocidades). Advisory, no bloquean: **Player Fantasy** ausente (el Overview lo cubre en parte, párrafo 3) y **Tuning Knobs** ausente como sección (la tabla «Valores por defecto y rangos seguros» de Formulas la sustituye con rangos). El estado de las secciones opcionales Visual/Audio, Game Feel y UI Requirements es correcto.

## Grafo de dependencias

GDDs existentes: 2, 3, 6, 7 (y 4, 5, 9, 18 relacionados). No existen aún 19, 21, 22, 24, 25, 27, 30 (referencias abiertas esperadas, índice «Not Started»). Bidireccionalidad verificada: 3 lista a 1 (regla 10 y tabla), 6 lista a 1 (`controles`), 2 lista a 1 (dura), 7 lista a 1 (dura). **Falla con 4** (hallazgo 3).

## Registro de entidades

`long_press_threshold` = 0,5 s, `rotate_mouse_gain` = 0,25 °/px y `player_camera_transition_cap_s` = 3,0 s coinciden con el GDD. Discrepancias: `F6_ppm` del registro (2.203 px/m) contradice el supuesto de 1.200 px/m aún vivo en Open Question 2 (hallazgo 5). El registro marca como «cambio pendiente en ese GDD» el tope de `sin control` de una carga (hallazgo 3).

## Seguimiento de la revisión anterior

Bloqueantes 1 a 4 (dependencia blanda con 3, aviso de contexto, escape de F5b, tope F8 con escenas dirigidas): resueltos y con AC (E9, F5, F8). Recomendados corregidos: F3, F4, unidades, delta, regla 16/21, regla 7. Sin regresión salvo lo señalado abajo.

## Hallazgos

### Bloqueantes

**B1 · `atrás` = Retroceso choca con escribir en el ordenador** (tabla de asignaciones, línea 85; regla 20; estados, línea 102). `atrás` por defecto incluye `Retroceso`, y es una acción activa en el contexto `ordenador`, donde además «el teclado físico entrega caracteres» (el único campo de texto del slice es la búsqueda «transición», slice línea 92). Borrar un carácter cerraría el ordenador, o dispararía las dos cosas. AC-20 solo comprueba que se escriben caracteres, no cierra el caso. Arreglo: quitar `Retroceso` de `atrás` por defecto (dejar clic derecho) o declarar que en `ordenador` el texto consume `Retroceso`, `Esc` (¿pausa o cancelar texto?) y las letras antes que cualquier acción, y añadir un AC (escribir y borrar con `Retroceso` no sale del contexto). Igualmente hay que decir qué pasa si el jugador reasigna `atrás` a una tecla imprimible.

**B2 · Las asignaciones por defecto incumplen la regla 16** (regla 16 frente a la tabla, líneas 67 y 88; regla 7). La regla 16 prohíbe que dos acciones del mismo contexto compartan entrada, pero `seleccionar`, `agarrar`, `rotar` y `mantener` comparten clic izquierdo / botón sur en `vista cercana`, y `pausa` y `ui_atrás` comparten `Esc` en `menú` (la propia regla 7 lo asume). Un validador de conflictos que implemente la regla literalmente rechazaría `default_bindings.json`, y la importación de AC-E5 («gana la primera, la otra vuelve a su valor por defecto») reiniciaría gestos legítimos. Además es ambiguo si `agarrar`, `rotar` y `mantener` son acciones reasignables o gestos derivados de `seleccionar` (la regla 15 dice «todas las acciones de vista cercana»; AC-15 no lo aclara). Arreglo: definir `seleccionar` como única acción física y `agarrar`/`rotar`/`mantener` como gestos derivados no reasignables, y exceptuar explícitamente `pausa`/`ui_atrás`; actualizar regla 15, 16 y AC-15/16.

**B3 · Contrato con Escena de planta (4) sin cerrar** (Interactions, Dependencies, F8, regla 6). El GDD 4 (regla 15, F3, línea 212 de ese GDD) exige que Entrada: (a) liste a 4 como emisor de los avisos de carga (de ellos depende la regla 7, «salvo durante una carga de escena», y las reglas 21 y AC-E11), y (b) acepte `D_carga` como duración declarada de `sin control` (F8 dice hoy que solo la declara el director, 21; el registro lo anota como «cambio pendiente»). Ni la tabla de Interactions ni la de Dependencies ni el índice nombran a 4, y nada define cómo sabe Entrada que hay una carga en curso. Arreglo: añadir a 4 en Interactions, Dependencies y Cross-References (aviso «carga de escena iniciada/terminada», petición de `exploración`); ampliar F8 y Open Question 12 a «director de escenas o Escena de planta»; añadir fila 4 en el índice (hallazgo 8). En sentido inverso, 4 y 2 citan «regla 15 de Entrada» para el reinicio de la pila: esa regla es la reasignación; el reinicio está en la regla 6 y en Edge Cases (corregir en 4).

### Importantes

**I1 · AC-10 y regla 10 contradicen a Interacción (7), regla 9** (línea 49 y AC-10, línea 412). El GDD 7 define que un objeto solo con `verbo_largo` (todos los documentos del slice: A04, B05, R01…) ante un toque corto no hace nada salvo pulsar el anillo y sonar `SFX_CLICK_SUBTLE`; Entrada dice que sobre documentos la pulsación corta «activa al soltar». Arreglo: reescribir AC-10 («un objeto con `verbo_corto` y `verbo_largo` decide al soltar; con solo `verbo_largo`, un toque corto no activa») y precisar que la decisión corto/largo la determina el catálogo de 7, no Entrada.

**I2 · Regla 8: bloqueo de transición mal acotado y texto duplicado** (línea 44). Dice que el bloqueo va «desde `interactuar()` hasta «cámara devuelta» / «gesto terminado»» y que «no termina al llegar la cámara». En la entrada a una vista, 7 (regla 19) la considera abierta con «cámara cedida», así que ese aviso también debe liberar el bloqueo. Además «Solo se acepta `pausa`» aparece dos veces y la frase del tope mezcla dos redacciones. Arreglo: listar los tres avisos de fin («cámara cedida», «cámara devuelta», «gesto terminado») y limpiar la regla.

**I3 · `rotar` no está cubierto por «alternar en lugar de mantener»** (regla 14, AC-14). `rotar` exige mantener `seleccionar` mientras se mueve, el mismo patrón que `agarrar`, y es el gesto del puzle 5. Quien no puede mantener un botón no puede jugar el puzle 5. Arreglo: incluir `rotar` en la regla 14 (comienza con una pulsación y termina con otra, el cursor/stick controla el giro) y en AC-14. Esto afecta al pilar *Tensión sin castigo*.

**I4 · Open Questions y F5b desactualizadas respecto al lote** (OQ 2, 9, 12; F5b R; línea 455). 7 F6 y el registro (`F6_ppm`) fijan 2.203 px/m en D01a: 0,04 m = 88 px y 0,10 m = 220 px, sustituyendo el supuesto de 1.200 px/m (48 / 120 px). OQ2 sigue con el supuesto antiguo. OQ9 («Leer (2 s)») ya la resolvió 7 (`lectura_min_s` = 2 s). OQ12 se resuelve en parte por 4 (`D_carga`). Consecuencia de diseño: F5b define `R = max(R base, tolerancia del elemento en px)` con rango de R de 32 a 128, pero la tolerancia asistida de 220 px lo sobrepasa y la ambigüedad entre centros a menos de 2·R (OQ3) crece a 440 px. Arreglo: actualizar OQ2/9/12 como resueltas o parciales, acotar R por elemento (p. ej. tope 128 px o declarar que el rango no limita la tolerancia asistida) y fijar la regla de desempate cuando varios elementos comparten captación.

**I5 · Precedencia `mantener` / `agarrar` indefinida** (regla 13, F6, AC-13). F6 mide el desplazamiento y el tiempo de forma independiente: si el jugador mantiene 0,6 s quieto (ya emitió `mantener` a 0,5 s) y después se mueve 12 px, no se dice si además emite `agarrar`, ni qué pasa con un `agarrar` que se detiene sin llegar a nada. Arreglo: primera señal que se cumpla decide el gesto y el otro queda descartado hasta soltar; añadirlo a F6 y AC-F6/AC-13. Relacionado: el sticks de `rotar` con mando no dice cuál de los dos sticks gira (F4 «eje horizontal» sin especificar) mientras ambos mueven el cursor.

**I6 · Pérdida de foco y desconexión de mando: tratamiento inconsistente en transiciones** (reglas 21 y 22; Edge Cases líneas 298 y 323; AC-E4). La regla 8 deja pasar `pausa` durante cualquier transición, y la pausa se abre al instante al perder foco; pero la desconexión de mando durante `ANIM_PHONE_PICKUP` pospone la pausa al final de la animación. No se justifica la diferencia, y AC-E4 está marcado como L pero requiere la animación (I). Arreglo: unificar (abrir en el acto en ambos) o explicar por qué el mando espera, y reclasificar AC-E4.

**I7 · `leer` sin estatus claro como acción** (regla 1, tabla de estados, AC-01). La nota de la regla 1 dice que `leer` «sigue activa en `exploración`», pero ni la lista de acciones de `exploración` (regla 1 y tabla de estados) ni la de `lectura` incluyen `leer`; en la tabla de asignaciones es «`interactuar` · `leer` (mantener)». AC-01 exige que existan «solo las acciones de la regla 1». Arreglo: decidir si `leer` es acción propia (listarla en `exploración`) o es el gesto prolongado de `interactuar` (y retirar la palabra «acción» y la nota de la regla 1).

**I8 · Índice sin la dependencia blanda 4 → 1** (`systems-index.md`, fila 4: deps «3»). El GDD 4 declara a 1 como dependencia blanda y el GDD 1 debería listarla (B3). Arreglo en el índice: `3 (blanda: 1)` y reflejarlo en Entrada.

### Menores

**M1 · Game Feel contradice a F4** (línea 373): «clavar 40° ± 3° en menos de ~4 s» frente a F4: «~4,4 s en la práctica». Alinear la cifra.

**M2 · Cabecera desactualizada** (líneas 3 y 5): `Status: In Design` frente a «In Review» del índice y `Last Updated: 2026-11-08` frente al cambio del 2026-11-09 en el Historial (que además dice «pendiente de re-review»).

**M3 · F1 dz_in = 0 permitido por el rango** (0–0,5) combinado con la deriva del stick y F7 (`dz_in + m_s`): con `dz_in` = 0 cualquier deriva cuenta como uso. Subir el mínimo (p. ej. 0,05) o documentar el riesgo.

**M4 · F5a Output Range solo para valores por defecto** («0 a 1.350 px/s»): con v_max = 1600 y s_c = 1,5 llega a 2.400 px/s. Indicar el máximo real o el tope del rango.

**M5 · Edge Case «mando desconectado» y AC-22**: al reconectar «se ofrece continuar» sin que ningún sistema (25) esté definido; dependencia de UI ya señalada en el UX Flag, basta anotarlo en Dependencies como pendiente del 25.

**M6 · Ajustes (6) y el aviso «ajustes aplicados»** (GDD 6, línea 82): Entrada recibe ese aviso al arrancar, pero no figura en su tabla de Interactions con 6. Añadir una fila de entrada.

## Alineación con el slice y los pilares

- **P6 con dos niveles de pista (decisión del usuario):** Entrada no define niveles de pista y no los contradice. El acceso a pistas por «gesto de cámara» (slice, línea 118) sigue abierto en Open Question 8 y es coherente; sin impacto. Observación fuera del alcance de este GDD: el índice (fila 17: «Sistema de pistas (3 niveles)») y `game-pillars.md` (línea 193: «pistas de tres niveles») siguen diciendo tres niveles; conviene propagar «tres niveles; dos en el puzle 6».
- **Slice §5 y Anexo B:** acciones, sin sprint/agacharse/saltar, pulsación prolongada para leer (0,5 s), 1 px ≈ 0,25° (`rotate_mouse_gain`), remapeo y mando coinciden. La entrada `PULSAR` corta/larga del puzle 3 está cubierta por `seleccionar` / `mantener`.
- **Pilares:** *Tensión sin castigo* (sin gestos temporales, alternativa a mantener, mínimos garantizados) bien servido salvo I3. *Autonomía como progresión* sin conflicto.

## Motor (Godot 4.7)

Respaldado por `docs/engine-reference/godot/modules/input.md`: el backend de mando es SDL3 (4.5); el foco es dual, ratón/táctil separado de teclado/mando (4.6); desde 4.7 el teclado y el ratón ya no usan `device == 0`, se identifican por tipo de evento o por `DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD`. Recomendación derivada (menor): la detección del dispositivo activo (regla 3, F7) debe identificar por tipo de evento, no por `device`, y la nota debería quedar en el GDD.

**NOT SOURCEABLE** (no cubierto por `docs/engine-reference/`, no se afirma): (a) que el motor entregue «ejes crudos sin zona muerta» para F1 y cómo se combina con la zona muerta por acción del `InputMap`; (b) comportamiento de captura de ratón y de `relative_px` acumulado; (c) señal o notificación de pérdida/recuperación de foco de la ventana y de conexión/desconexión de mando; (d) reasignación en caliente y guardado de eventos del `InputMap`; (e) el modo de estiramiento del viewport lógico 1920 × 1080 (Open Question 13, correctamente diferida a ADR). Hasta documentarlos en `docs/engine-reference/godot/` o en un ADR, las reglas 3, 12, 15, 21, 22 y F1 no pueden pasar como verificadas contra el motor.

## Preguntas para el usuario

Ninguna que cambie pilares, tono o alcance. Una decisión de producto menor, opcional: si `Retroceso` (B1) debe seguir siendo `atrás` fuera del ordenador. Recomendación propia: quitarlo.

## Alcance estimado

L: 8 fórmulas, 22 reglas, 11 dependientes, probable ADR de entrada/InputMap. A confirmar por producción antes de planificar sprint.
