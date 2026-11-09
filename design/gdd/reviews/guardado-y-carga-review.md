# Revisión de diseño: Guardado y carga (sistema 5)

- **Documento:** `design/gdd/guardado-y-carga.md` (463 líneas, estado «Designed»)
- **Fecha:** 2026-11-09 · **Revisor:** independiente (sin contexto del autor) · **Modo:** lean (sin especialistas)
- **Workflow resuelto:** `standard` (`modes.rigor: standard`, sin `modes.workflow` explícito)
- **Re-review:** No, primera revisión (no existe `guardado-y-carga-review-log.md`)
- **Contrastado con:** `slice-v0.3.md` (§8.5, §13.2, §13.3, C.7, D.2, D.3), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, `estado-y-bus-de-eventos.md`, `escena-de-planta.md`, `ajustes-persistentes.md`, `marco-de-puzles.md`, `docs/engine-reference/godot/` (VERSION, breaking-changes).

## Veredicto: NEEDS REVISION

El GDD es sólido en estructura y en la mayor parte del razonamiento (escritura atómica, sellado, no-softlock). Pero tiene 3 defectos bloqueantes de lógica (resultado de inspección obsoleto tras salir al título, línea base de `dif` en «Nueva partida» que contradice D-8, y F1 que deja a las causas urgentes y al guardado periódico sin espera de reintento) y varios puntos importantes de ordenación y contrato con otros GDD. Ninguno exige rediseñar el sistema: son arreglos locales.

Scope signal: **L** (4 fórmulas, 8+ dependencias, ADR obligatorio por Open Question 1). Producer debe verificarlo.

## Completitud (workflow `standard`: 6/6 requeridas presentes)

| Sección | Estado |
|---|---|
| Overview | Presente |
| Detailed Rules (`## Detailed Design`) | Presente, 28 reglas |
| Formulas (requerida: el sistema define umbrales, periodos y esperas) | Presente, F1 a F4 |
| Edge Cases | Presente, amplia |
| Dependencies | Presente |
| Acceptance Criteria | Presente, 46 criterios + AC-F |
| Player Fantasy (advisory a `standard`) | **Ausente**. Recomendación, no bloquea. Hay «Game Feel» y el pilar en la cabecera; bastaría un párrafo («no se nota») |
| Tuning Knobs (advisory) | Presente, con rango y efecto |

## Grafo de dependencias

- Existe en disco: 3 `estado-y-bus-de-eventos.md`, 4 `escena-de-planta.md`, 6 `ajustes-persistentes.md`, 18 `base-de-contenido-narrativo.md`.
- **No existe todavía** (referencias salientes que sus autores tendrán que cerrar): 8, 9 a 16 (salvo el marco), 20, 21, 22, 25, 27. El GDD lo declara en «Bidireccionalidad» y Open Questions; es esperado en esta fase, pero obliga a que los AC-34 y AC-43 queden abiertos.
- Bidireccionalidad confirmada: 3 cita a 5 (reglas 13, tabla, casos límite de guardado); 4 cita a 5 (regla 16, tablas); 6 y 11 (marco) lo citan. Pendiente en 3: avisos «guardado en riesgo/restablecido» y `snapshot_version` expuesta (Open Question 2).

## Valores del registro

- `design/registry/entities.yaml` solo contiene 2 entradas de este GDD: `save_format_version` y `save_periodic_interval_s`. Los valores (1 y 120 s) coinciden con el GDD.
- Hallazgos: ver 14 (referencias del registro no respaldadas por los GDD que figuran como `referenced_by`) y 15 (nombres). La «Propuesta de registro» (Open Question 9) sigue sin aplicar.

---

## Hallazgos

### Bloqueantes

**1. [bloqueante] El resultado de inspección queda obsoleto tras jugar y salir al título.** Regla 17 (L98: «La pantalla de título consulta el resultado; no vuelve a leer disco»), tabla de estados (L119 «Sin inspeccionar» solo al arrancar; L122 «las lecturas del resultado… siguen siendo las del arranque»), transición «En partida → Sin partida (salida al título)».
Una sesión que arranca con `ninguna`, juega, guarda y vuelve al título seguiría viendo «Continuar» ausente; una que arranca con `valida` y luego guarda otro estado continuaría con la instantánea vieja del arranque. «Salir al título» existe (regla 6, `quit`; pausa 25) y rompe directamente el pilar *Tensión sin castigo* (cerrar y volver nunca pierde progreso).
**Arreglo:** al entrar en «Sin partida» desde una sesión, repetir la inspección (o actualizar el resultado en memoria con lo último escrito con éxito) antes de que el título consulte; añadir la transición «Sin partida → Sin partida (re-inspección)» a la tabla y un AC (jugar con carpeta vacía, guardar, salir al título: resultado `valida`, «Continuar» ofrecido y restaura el último guardado, incluido uno sellado).

**2. [bloqueante] «Nueva partida» no define la línea base de `dif`, y `quit`/`pause_opened`/`periodic` pisan la partida anterior.** Reglas 7 y 24, D-8, edge case L258, AC-38.
Regla 7 compara con «el último escrito o cargado». Tras «Nueva partida» desde un fichero válido, lo «cargado» es la partida vieja; el estado inicial difiere de ella, así que `dif` es verdadero. Cerrar justo después (`quit`, que es causa urgente), abrir la pausa o dejar pasar 120 s (`periodic`) escribe el estado vacío con `seq`+1 y rota la partida buena a `autosave.prev.json`. Eso contradice D-8 («abandonar una partida nueva antes de la primera puerta no destruye la anterior») y el texto de AC-38, que solo cubre «cierra antes de cualquier causa» (pero `quit` es una causa). El jugador que pulsa «Nueva partida» por error y cierra pierde la partida (recuperable solo como `prev`, que el título no ofrece).
**Arreglo:** definir que en una partida nueva la línea base de `dif` es el estado inicial (hash de «estado restablecido»), de modo que no se escribe nada hasta que algún hecho difiera del inicial. Reformular AC-38 con `quit`, `pause_opened` y `periodic` explícitos. Decidir si, tras confirmar, «Continuar» sigue ofreciendo la partida vieja en esa sesión.

**3. [bloqueante] F1 exime de la espera de reintento a las causas urgentes y al guardado periódico.** F1 (L145): `urgente ∨ (solicitud ∧ … ∧ t ≥ t_intento) ∨ (t_periodico > 0 ∧ t − t_ref ≥ t_periodico)`; F2 (L169, L181).
`t_intento` solo condiciona la rama `solicitud`. Dos consecuencias: (a) el guardado de sellado (`call_started`, urgente) y sus reintentos (regla 11.2) se evalúan cada fotograma sin espera creciente, contradiciendo F2 y AC-22; (b) con un fallo persistente, `t − t_ref ≥ t_periodico` queda verdadero para siempre (t_ref solo avanza con éxito) y se reintenta en cada fotograma ignorando la espera: justo el martilleo de disco/antivirus que F2 quiere evitar. F2 solo exceptúa a `quit`, y la excepción está en prosa, no en la fórmula.
**Arreglo:** reescribir `escribir ⇔ … ∧ dif ∧ ( (urgente ∧ es_quit) ∨ (t ≥ t_intento ∧ ( urgente ∨ solicitud_agrupada ∨ periodico )) )`, con `quit` como única excepción, y añadir AC con almacenamiento que siempre falla y `call_started`/periodic (conteo de intentos en 60 s con la secuencia +2, +4, +8…).

### Importantes

**4. [importante] La suma de comprobación sobre «JSON canónico re-serializado» es frágil en Godot.** F3 (L183-195), regla 19.
El checksum se recalcula al leer re-serializando el objeto analizado. Si el analizador de JSON del motor devuelve todos los números como `float` (a verificar), `1` se re-serializa como `1.0` y todo fichero válido fallaría el checksum; además los tipos «int» exigidos por la regla 19 (`seq`, `format_version`, `pos_*`) dependen de ese comportamiento. **NOT SOURCEABLE:** `docs/engine-reference/godot/` no cubre `JSON`, `FileAccess` (salvo el retorno `bool` de `store_*`) ni `DirAccess` (no existe `modules/core.md`); no se afirma nada del motor desde memoria. Lo que sí es diseñable es no depender de ello.
**Arreglo:** calcular el checksum sobre los bytes exactos del cuerpo escrito (por ejemplo, fichero = línea de cabecera con `checksum` + cuerpo, o el cuerpo como texto y el checksum aparte), y validarlo sobre los bytes leídos, no sobre una re-serialización. Mantener la forma canónica solo para `dif`, con ints normalizados. Añadir un AC de ida y vuelta (escribir, leer, validar con enteros y `enum` sin fijar).

**5. [importante] Orden de validación de versión y definición de `version_futura` incoherentes.** Reglas 17, 19, 20; F4 (L207); AC-33.
(a) Regla 19 exige todas las claves, tipos y checksum de la envoltura v1 *antes* de mirar la versión; un fichero de una versión futura que cambie claves o checksum caería como «dañado» (copia a `.corrupt`, resultado `irrecuperable`) en vez de `version_futura`. Debe leerse `format_version` primero. (b) La regla 17 define `version_futura` como «el más reciente válido pertenece a una versión mayor»; F4 y AC-33 dicen que con un `prev` válido se usa el previo y *no* se informa. Hay que elegir una; en el segundo caso el jugador carga silenciosamente una partida más antigua que la de la build nueva sin saberlo. (c) `snapshot_version` conocida del 3 no existe aún en su GDD (Open Question 2); mientras tanto la regla 20 no es implementable.
**Arreglo:** validar en dos pasos (envoltura mínima: JSON, `format_version` entero, tamaño; luego versión; luego el resto según la versión); unificar la definición con F4; decidir y documentar si se avisa cuando se usa un `prev` por haber un principal futuro.

**6. [importante] La migración está repartida entre la inspección y «Continuar».** Reglas 17, 18 (paso 1), 21, F4 (válido incluye migración).
Para que F4 elija candidato, la migración debe ejecutarse en la inspección; la regla 18 la sitúa al pulsar «Continuar». Si falla ahí, ya se ha ofrecido `valida` y no hay vuelta al `prev` ni a `irrecuperable` (la regla 21 dice «se trata como dañado», pero el flujo no puede ya probar otro candidato).
**Arreglo:** migrar y validar durante la inspección, guardar la instantánea migrada en memoria, y que «Continuar» consuma ese resultado (sin segunda migración). Ajustar AC-33b y AC-35.

**7. [importante] Captura del sellado frente a la regla de cola vacía; `quit` durante «Sellando».** Regla 11.1 vs regla 5; F1; reglas de «Sellando» (L124); edge case L224.
La captura ocurre «en el momento del aviso», pero el aviso se entrega con la cola de avisos no vacía (regla 5 y GDD del 3, regla 11), y F1 exige `cola_vacía` también para lo urgente. No se dice cuándo se captura: ¿dentro de la entrega (viola la regla 5; puede perder derivados) o al vaciar la cola (entonces la captura puede incluir más cambios que `llamada_iniciada`)? Además, en «Sellando» solo se admite el sellado, pero `quit` es urgente y F2 dice que intenta una vez; no se especifica qué escribe `quit` en «Sellando» (¿el contenido capturado? ¿nada?).
**Arreglo:** capturar al vaciarse la cola de la entrega en curso (primer instante con cola vacía), documentarlo y fijarlo en AC-13; definir que `quit` en «Sellando» intenta una vez el contenido capturado; AC nuevo.

**8. [importante] La rotación del paso 3 no comprueba que el principal sea válido; `seq` tras una carga no máxima.** Regla 13 pasos 3 y 4, regla 18(3), regla 22, regla 24, edge case L246.
El paso 3 renombra siempre `autosave.json` a `prev`, aunque el principal esté dañado (por ejemplo, se recuperó desde `prev` en el arranque) o se haya corrompido en caliente: se destruye el único respaldo bueno. El caso L246 («falla el paso 4 después del 3: el previo y el temporal son válidos») es falso cuando el principal estaba dañado (el previo sería el dañado). Además, tras cargar desde `prev` (seq 17) con un principal futuro/dañado de seq 18, «fijar `seq`» (regla 18.3) no dice si se usa el del candidato o el máximo visto: puede haber empate con F4.
**Arreglo:** rotar solo si el principal pasó la validación en la última lectura/escritura; si no, conservar `prev` y sustituir el principal (tras la copia `.corrupt`). Fijar `seq` siguiente = máximo `seq` visto entre todos los candidatos (válidos o con `seq` legible) + 1. Corregir el edge case y añadir AC al caso «principal corrupto en caliente».

**9. [importante] Quién pide la carga de `planta` al continuar.** Regla 18(4) y regla 24 de este GDD; `escena-de-planta.md` regla 7 (L40).
Escena de planta dice que Título (27) pide «la partida nueva y la reanudación»; sus tablas (L81, L198) y este GDD dicen que Guardado pide `reanudar`. En la misma interfaz, «Nueva partida» deja la petición al título y «Continuar» la hace Guardado: asimetría sin justificar.
**Arreglo:** un único dueño. Propuesta: Guardado hace restaurar + pedir `reanudar` (como ya describe) y se corrige la regla 7 del GDD de Escena de planta; o bien Título pide ambas y Guardado solo restaura. Registrarlo en Open Questions y en las dos tablas de interacción.

**10. [importante] Dependencia no declarada del momento en que 22 emite «llamada iniciada».** Reglas 11 y 12, edge cases L222-228, slice C.7 y D.2.
Todo el sellado depende de cuándo se activa `llamada_iniciada` (¿al cruzar el umbral de D, al entrar en el despacho, al descolgar?). Slice C.7 solo da que V02 suena al entrar en el despacho, y D.2 dice que `llamada_iniciada` «evita repetir la llamada», semántica que este GDD invierte (se repite siempre, regla 12). Las consecuencias (qué se pierde si se cierra entre el cruce de D y el descuelgue) no están acotadas; hoy solo figuran en Open Question 4.
**Arreglo:** declarar en Dependencies una restricción para el 22 («`llamada_iniciada` se fija antes de cualquier elemento no reconstruible y como máximo al descolgar») y anotar la reinterpretación de D.2 en Cross-References.

**11. [importante] Garantía de durabilidad no sustentable con la documentación del motor.** Regla 13, regla 28, F4 (ejemplo de «corte de luz»), AC-20, AC-42, Open Question 1.
La afirmación «un corte entre cualquier par de pasos deja siempre al menos un fichero válido» supone que la releeectura del paso 2 valida lo que hay en disco (no en la caché del sistema) y que el renombrado es seguro ante cortes. **NOT SOURCEABLE** desde `docs/engine-reference/godot/`: no se documenta ninguna forma de forzar la escritura a disco ni la semántica de renombrado sobre un fichero existente en Windows y Linux. Los AC-20/21 con almacenamiento falso prueban solo la lógica de secuencia, no la durabilidad.
**Arreglo:** reformular la garantía como «ante cierre del proceso o fallo de la aplicación» y declarar el corte de energía como mejor esfuerzo hasta que el ADR lo verifique (con una prueba en ambas plataformas del slice §21); mantener AC-42 como bloqueante en la fase de arquitectura, no como «opcional».

### Menores

**12. [menor] Ejemplo de F1 incorrecto.** F1, ejemplo (L165). Una puerta no es un hecho de los 19, así que `door_opened:D` solo escribe si cambió otro hecho; el ejemplo lo justifica con «`pos_*` o similar» y deja el caso con `dif` falso sin resolver. Sustituirlo por un caso con valores concretos (por ejemplo `pos_L` cambiado a 3 en t = 101,5 y puerta en 104,0).

**13. [menor] Entre `quit` y el marco de puzles.** `marco-de-puzles.md` regla 19 dice que cerrar el juego «no guarda en ese momento», lo contrario de `quit` (regla 6). Corregir en el GDD 9 o aclarar que se refiere al cierre forzado. La regla 22 de ese GDD también atribuye la pérdida de progreso parcial a «deliberado», mientras este GDD la acota con `t_periodico`: unificar el discurso.

**14. [menor] Referencias del registro no respaldadas.** `entities.yaml` L220-221: `save_format_version` figura `referenced_by: ajustes-persistentes.md`, pero ese GDD no lo menciona (tiene su propio formato de versión); `save_periodic_interval_s` figura `referenced_by: marco-de-puzles.md`, que no habla del guardado periódico (solo de la causa `pendiente_revelacion`). Corregir las referencias o añadir la mención en esos GDD.

**15. [menor] Nombres y cobertura del registro.** El GDD llama `t_periodico` a lo que el registro llama `save_periodic_interval_s`; el resto de la «Propuesta de registro» (L450-463) y los nombres de fichero siguen sin registrar (Open Question 9). Alinear nombres y volcar el lote.

**16. [menor] Índice inconsistente.** `systems-index.md` L29 (tabla) lista las dependencias del 5 como «3, 4»; L107 (orden de diseño) aún dice «3, 4, 6». Corregir L107 (Open Question 3).

**17. [menor] Escritura síncrona o asíncrona sin decidir.** Regla 16 ("una escritura en curso") y Open Question 6 (hilo) sugieren E/S asíncrona, mientras el resto del GDD (`quit`, F2 «intenta una vez y el proceso termina») asume síncrona. Declarar que en el slice la E/S es síncrona y que mover a hilo exige revisar `quit` y la regla 16.

**18. [menor] Causa `dev` no listada.** La regla 27 introduce una causa `dev` que no está en la tabla de la regla 6 ni en `causas_activas`. Añadirla como «solo desarrollo».

**19. [menor] Comportamiento tras completar el slice.** Con la partida sellada para siempre (regla 11.3), «Continuar» después de llegar a Recepción vuelve a la llamada. Es una consecuencia declarada (regla 11), pero para una demo de financiación conviene anotarla en Open Questions de 27/21 (¿pantalla de título final cambia el resultado?).

**20. [menor] Sobrepromesa del pilar en la cabecera.** L7: «cerrar y volver nunca pierde ni repite progreso». Las reglas 3, 11 y 14 aceptan perder hasta `t_periodico` de progreso parcial y repetir la llamada. Reformular: «sin pérdida de hitos y con pérdida acotada y declarada de progreso parcial».

**21. [menor] Dependencia con el 3 aún sin garantía en su GDD.** Regla 5 y 12 dependen de que el 3 exponga `snapshot_version` y los dos avisos nuevos (Open Question 2); mientras no estén en el GDD 3, AC-33 y AC-23 no son ejecutables. Anotar en el índice como bloqueo cruzado.

### Criterios de aceptación: testabilidad

- **AC-12** («el juego no muestra error»): no medible; reescribir como «el log no contiene líneas de error ni advertencia y la escena alcanza «carga de escena terminada» en estado de partida».
- **AC-41** («el juego es terminable en cada caso»): depende de un recorrido de referencia no definido; referenciar el recorrido concreto (lista de acciones) o moverlo al AC-43.
- **AC-30** agrupa siete casos en un solo criterio; dividir en filas parametrizadas para que cada fallo se atribuya.
- **AC-08** mezcla tres condiciones («si `t_ref` = 0», `t_periodico` = 0, pausa); separar.
- **AC-34, AC-43** quedan abiertos hasta que existan 8, 9 a 16, 21 y 22; correcto como está, pero deben constar como «NOT ASSESSED» en el informe de QA mientras tanto, no como pasados.
- **Faltan:** re-inspección tras salir al título (hallazgo 1); línea base de «Nueva partida» (2); reintentos del sellado y del periódico con el almacenamiento fallando (3); ida y vuelta de tipos (4); `quit` en «Sellando» (7); rotación con principal dañado (8).

## Consistencia con el slice

- Coincide con slice §13.2 y D.3 (puertas, compartimentos, llamada, `pendiente_revelacion`) y con §13.3 (sin softlock).
- Las causas extra (`puzzle_solved`, `reveal_pending`, `pause_opened`, `quit`, `periodic`) amplían D.3 sin contradecirlo y están justificadas (D-3). `reveal_pending` cierra la Open Question 3 de `marco-de-puzles.md`.
- Matiz con D.2 (hallazgo 10): la semántica de `llamada_iniciada` («evita repetir la llamada») queda reinterpretada.
- Regla 28 y Open Question 5: la reanudación con `caja_completa` ∧ ¬`llamada_iniciada` deja al jugador en el despacho con el disparador en D (slice §8.5, «único disparador»). No contradice el slice, pero la ausencia del GDD 21 deja el argumento de no-softlock parcialmente abierto; está reconocido.

## Riesgos de implementación en Godot 4.7 (sin afirmar nada fuera de lo sourced)

- Confirmado por `breaking-changes.md` L91: `FileAccess.store_*` devuelve `bool` desde 4.4; la regla 13 paso 1 es implementable.
- NOT SOURCEABLE en `docs/engine-reference/godot/`: tipos numéricos tras analizar JSON, semántica de renombrado sobre fichero existente, forzado a disco, API de hash, gestión del cierre normal de ventana frente al cierre forzado. Todo ello debe resolverse en el ADR (Open Question 1) antes de implementar; hasta entonces los AC con almacenamiento falso cubren la lógica, no el motor.

## Resumen para el autor

Arreglar 1 a 3 antes de aprobar; 4 a 11 en la misma pasada (la mayoría son frases en reglas ya existentes más un AC); 12 a 21 pueden ir con el cierre del lote o con la revisión de los GDD afectados. Tras los arreglos, una re-review en sesión limpia decide APPROVED.

---

## Cambios requeridos en otros GDDs (resultado de aplicar esta revisión, 2026-11-09)

Estado del GDD 5: «Revisado — pendiente de re-review». Los hallazgos 1 a 12 y 17 a 20 están resueltos en el GDD; 13, 14, 16 y 21 exigen cambios fuera de él:

- **3 Estado y bus de eventos:** exponer `snapshot_version` conocida; añadir los avisos «guardado en riesgo» y «guardado restablecido» (regla 10); confirmar que "estado restablecido" permite obtener su contenido para la línea base de `dif` de «Nueva partida» (regla 7 y 24 de Guardado).
- **4 Escena de planta:** la regla 7 (L40) y las tablas de interacción (L85 y L204) dicen que Título (27) pide `planta` (nueva o reanudar). Pasa a ser: **Guardado (5) pide `planta` con `reanudar` y con `partida_nueva`**; 27 solo llama a `continuar()` y `nueva_partida()`. Ajustar también AC-07a si nombra al pedidor.
- **9 Marco de puzles:** regla 19 («cerrar el juego no guarda en ese momento») contradice la causa `quit` (regla 6 de Guardado): aclarar que se refiere al cierre forzado. Regla 22: unificar el discurso de pérdida de progreso parcial («deliberado») con la cota `t_periodico` (regla 14 de Guardado). Mencionar `save_periodic_interval_s` si se mantiene la referencia del registro.
- **27 Pantalla de título (cuando exista):** consulta el resultado de la **última** inspección (con `con_futura`); muestra el aviso de versión más nueva con partida cargable; no pide `planta`; Open Questions: ¿qué ofrece tras completar el slice? (Open Question 10 de Guardado).
- **22 Llamada (cuando exista):** restricción de emisión de `llamada_iniciada` («antes de cualquier elemento no reconstruible y como máximo al descolgar») y nota de reinterpretación de D.2.
- **`design/registry/entities.yaml`:** corregir `referenced_by` de `save_format_version` (L220: `ajustes-persistentes.md` no lo menciona) y `save_periodic_interval_s` (L221: `marco-de-puzles.md` no habla del guardado periódico) o añadir la mención en esos GDD; volcar el resto de la «Propuesta de registro» del GDD 5.
- **`systems-index.md`:** L107 (orden de diseño) aún dice «3, 4, 6» para el sistema 5; anotar el bloqueo cruzado con el 3 (`snapshot_version` y avisos nuevos).
- **Ajustes persistentes (6), opcional:** no usa `save_format_version`; ninguna acción obligatoria.
