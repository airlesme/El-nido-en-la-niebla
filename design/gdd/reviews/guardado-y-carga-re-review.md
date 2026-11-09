# Re-review: Guardado y carga (sistema 5)

- **Documento:** `design/gdd/guardado-y-carga.md` (520 líneas, estado «Revisado, pendiente de re-review»)
- **Fecha:** 2026-11-09 · **Revisor:** independiente (sin contexto del autor) · **Modo:** lean (sin especialistas)
- **Workflow resuelto:** `standard` (`project.yaml`: `modes.rigor: standard`, sin `modes.workflow` explícito; leído a mano, no con `resolve_config`)
- **Re-review:** Sí. Revisión previa: `reviews/guardado-y-carga-review.md` (NEEDS REVISION, 21 hallazgos). No existe `guardado-y-carga-review-log.md`, así que no se aplicó la comprobación de recibos.
- **Contrastado con:** `slice-v0.3.md` (§13.2, §13.3, D.2, D.3, P6 con dos niveles de pista), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, GDD 3, 4, 6, 9 y 18, `docs/engine-reference/godot/` (`VERSION.md`, `breaking-changes.md`, `modules/`).

## Veredicto: NEEDS REVISION

Los tres bloqueantes de la primera revisión (resultado de inspección obsoleto, línea base de «Nueva partida», espera de reintento en F1) están bien resueltos y los 21 hallazgos previos están aplicados en el texto. Quedan 1 bloqueante nuevo (contradicción entre la regla 19 y AC-33 sobre versiones futuras) y varios huecos importantes que las propias correcciones han abierto: la partida nueva no pasa por «Cargando partida», la inspección borra ficheros pese a la regla 22, y la ruta de «sustitución del principal» exige un renombrado sobre fichero existente que la regla 13 dice no necesitar. El P6 con dos niveles de pista **no afecta** a este GDD (la pista no es un hecho de los 19 ni se guarda; ver pregunta 4).

Scope signal: **L** (4 fórmulas, 8+ dependencias, ADR obligatorio por Open Question 1). Producer debe verificarlo.

## Estado de los hallazgos de la primera revisión

| # previo | Estado | Comprobación |
|---|---|---|
| 1 Re-inspección al volver al título | Resuelto | Reglas 17 y tabla de estados; AC-38b/c; D-14 |
| 2 Línea base de «Nueva partida» | Resuelto | Reglas 7(c) y 24; AC-38; D-15 (ver nuevo 5 por el estado «En partida» inmediato) |
| 3 F1 y `t_intento` | Resuelto | F1 reescrita; `quit` única excepción; AC-22b (ver menor 13: falta la causa `dev`) |
| 4 Checksum sobre bytes | Resuelto | Regla 2, F3, D-17, AC-30b/c (ver nuevo 1 por la cabecera) |
| 5 Orden versión/validación | Parcial | Regla 19 en dos tiempos, pero contradice AC-33 (nuevo 1) |
| 6 Migración en la inspección | Resuelto | Reglas 17, 18, 21; D-19 |
| 7 Captura del sellado y `quit` en «Sellando» | Resuelto | Regla 11.1-11.2; AC-13, AC-26b; D-20 |
| 8 Rotación con principal dañado | Resuelto | Regla 13 paso 3; AC-26c; D-21 (ver nuevo 4) |
| 9 Dueño de la carga de `planta` | Resuelto | GDD 4 (regla 7, L82, L200, L206) ya coincide con D-22 |
| 10 Emisión de `llamada_iniciada` | Resuelto en el GDD; pendiente en 22 | Regla 12, Dependencies |
| 11 Durabilidad | Resuelto | Regla 13 «Garantía (alcance)»; D-23; AC-42 bloqueante en arquitectura |
| 12-20 | Resueltos | Player Fantasy añadido; F1 ejemplo corregido; índice L109 corregido; pilar reformulado; GDD 9 (reglas 19/22, D9-8) y registro actualizados |
| 21 Bloqueo cruzado con el 3 | Resuelto en el 3, **texto obsoleto aquí** (menor 12) |

## Completitud (workflow `standard`: 6/6 requeridas presentes)

Overview, Detailed Design, Formulas (requerida: umbrales, periodos y esperas), Edge Cases, Dependencies y Acceptance Criteria presentes (`gdd-structure-check.sh`: las 8 secciones PRESENT, ninguna PLACEHOLDER). Player Fantasy y Tuning Knobs (advisory) presentes. Sin huecos de estructura.

## Grafo de dependencias

- Existen: 3 `estado-y-bus-de-eventos`, 4 `escena-de-planta`, 6 `ajustes-persistentes`, 9 `marco-de-puzles`, 18 `base-de-contenido-narrativo`.
- No existen aún: 8, 10 a 16, 20, 21, 22, 25, 27. Es esperado en esta fase; AC-34 y AC-43 deben constar como NOT ASSESSED en QA.
- **Bidireccionalidad confirmada:** 3 (reglas 10, 12, 13, tabla y casos límite de guardado), 4 (reglas 7 y 16, tablas L82/L200/L206), 9 (L525, D9-8, regla 22).
- **Bidireccionalidad pendiente:** 6 todavía dice «A confirmar / confirmar o retirar» (L89, L212, L214, L327) cuando el GDD 5 ya retiró la dependencia; 18 no cita al 5 (rótulos `UI_…` de los avisos, Open Question 8); el índice no lista 5 en las dependencias de 25 (blanda), 22 y 21. Ver menor 11.

## Valores del registro

`save_format_version` (1), `save_periodic_interval_s` (120), `save_group_window_s` (0,1), `save_retry_base_s` (2), `save_retry_max_s` (30), `save_fail_warn_count` (3), `save_max_read_bytes` (65 536), `save_files`, `save_config_path` coinciden con el GDD. `referenced_by` de `save_periodic_interval_s` (marco de puzles) y `save_fail_warn_count` (GDD 3) están respaldados. El GDD usa los nombres del código (`t_periodico`, `t_agrupar`…) y no cita los del registro (menor 12).

---

## Hallazgos

### Bloqueantes

**1. [bloqueante] La regla 19 y AC-33 se contradicen sobre qué se valida antes de mirar la versión.** Regla 19 («Envoltura mínima»), regla 20, AC-33, edge case L262, D-18.
La envoltura mínima exige, antes de leer `format_version`, una cabecera de 64 caracteres hex con salto de línea y un cuerpo JSON analizable. AC-33 pide que un fichero con `format_version` mayor, claves distintas **y `checksum` ilegible** dé `version_futura`. Con la regla 19 tal como está, un checksum ilegible falla la envoltura y el candidato es «dañado». Además, el motivo más probable para subir `format_version` es cambiar justo la estructura que la envoltura mínima da por fija (la cabecera con el hash, su longitud, el algoritmo). Una build antigua clasificaría el fichero nuevo como dañado, lo copiaría a `.corrupt` y el primer guardado lo borraría, que es lo que D-11 y D-18 querían evitar. Son además dos especificaciones que un programador no puede cumplir a la vez.
**Arreglo:** que lo único exigido antes de la versión sea lo que no puede cambiar entre versiones: tamaño y que `format_version` pueda leerse en una posición fija (por ejemplo, primera línea `v<N>` o el primer campo del fichero, separado del checksum). La cabecera hex, su longitud y el cuerpo JSON pasan al bloque «Resto (según la versión)». Reescribir AC-33 para que sea satisfacible y añadir una fila con cabecera de otra longitud. La longitud de 64 en la regla 19 depende además del algoritmo, que F3 deja a un ADR (SHA-256 †): quitar el literal de la envoltura o declararlo dependiente del ADR.

### Importantes

**2. [importante] La regla 14 afirma que las tarjetas «se guardan en el acto», y ninguna causa lo hace.** Regla 14, regla 6, D-3, slice D.2/D.3 y §13.2.
`tarjeta_B` y `tarjeta_D` se activan al recoger las tarjetas en el Archivo (D.2: «A05»). Ninguna causa de la regla 6 salta en ese momento (no es puerta, ni compartimento, ni `EV_PUZZLE_SOLVED_*`, ni `pendiente_revelacion`, ni pausa). Las tarjetas llegan a disco por `periodic` (hasta 120 s), por `quit` o por la siguiente puerta. Un cierre forzado entre recogerlas y abrir B o D las pierde. No hay softlock (se vuelven a recoger) y el coste es bajo, pero el texto es falso y el pilar de la cabecera («no pierde ningún hito») queda sobrepromesa.
**Arreglo:** o bien añadir una causa no urgente (por ejemplo `item_acquired:<id>`, o cambio de cualquiera de los hechos de tarjeta, que el 3 ya avisa), o bien corregir la regla 14 y D-3 para decir que las tarjetas dependen de `t_periodico` en el cierre forzado. Añadir un AC.

**2b. [importante] «Las puertas que abrió siguen abiertas» no está sustentado por los 19 hechos.** Player Fantasy (L15), regla 6 (`door_opened`), F1 ejemplo, AC-04, AC-38(d).
D.2 no tiene un hecho «puerta abierta» para B ni para D (solo `tarjeta_B/D`; A se deriva de `archivo_abierto`). Reconstruir desde hechos deja B y D cerradas al reanudar, salvo que el sistema 8 las derive de algo. Como consecuencia, `door_opened:<ID>` escribe solo si otro hecho cambió (`dif`), y el slice D.3 («autoguardado al abrir cualquier puerta») se cumple de forma vacía. No es un defecto de este sistema, pero el texto de fantasía y el nombre de la causa prometen más de lo que se guarda.
**Arreglo:** reformular el Player Fantasy a lo que sí se conserva (tarjetas, archivo abierto, compartimentos), anotar en Dependencies que 8 debe decidir si B y D reaparecen abiertas, y en AC-04 y AC-38(d) usar un hecho concreto en vez de «puerta ya reflejada». Ver pregunta 3.

**3. [importante] «Nueva partida» salta «Cargando partida» y no define el fallo de carga ni `t_ref`.** Regla 24, regla 8, tabla de estados, AC-36, regla 7.
La regla 24 pone la partida directamente en «En partida» y *después* pide `planta` con `partida_nueva`. La tabla solo admite «Cargando partida → Sin partida» para el fallo de carga, y AC-36 solo cubre `continuar`. Consecuencias: (a) durante la carga y el fundido de 2,0 s de la partida nueva (GDD 4, F1) las causas no se ignoran (regla 8 solo cubre «Cargando partida»); (b) si `planta` falla con `partida_nueva` (GDD 4, regla 14), el sistema queda en «En partida» con el jugador en el título y `periodic` y `quit` activos; (c) `t_ref` («última escritura con éxito, o de la carga») no está definido para una partida nueva, y `periodico` puede vencer de inmediato con un `t_ref` de la sesión anterior.
**Arreglo:** que `nueva_partida()` entre en «Cargando partida» (restablecer, línea base, pedir `planta`) y pase a «En partida» con «carga de escena terminada», igual que `continuar`; fallo de carga → «Sin partida» sin re-inspección; fijar `t_ref = t` al entrar en «En partida». Añadir AC espejo de AC-36/AC-37 para la partida nueva.

**4. [importante] La inspección borra y copia ficheros, contra la regla 22, y la sustitución del principal depende de un renombrado sobre fichero existente.** Reglas 22, 23, 13 (paso 3 y 4), edge cases L237, L272-L275, AC-24, AC-29, AC-31.
(a) La regla 22 dice que «la inspección no borra ni modifica ningún fichero dañado»; la regla 23, el edge case L237 y AC-29 dicen que la inspección «descarta y elimina» el temporal huérfano. Con la re-inspección en cada vuelta al título, además, cada candidato inválido se vuelve a copiar a `autosave.corrupt`: un temporal truncado tras un cierre forzado (frecuente) sobrescribe la copia de un principal realmente dañado (menos frecuente y más valioso para diagnóstico).
(b) La regla 13 afirma que la secuencia «no depende de que renombrar sobre un fichero existente lo sobrescriba». Pero si falla el borrado o el renombrado de la rotación (paso 3) y «el principal se sustituye igualmente» (L272, AC-24), el paso 4 renombra `tmp` sobre `autosave.json` que sigue existiendo. Ese caso sí depende de la sobrescritura, que `docs/engine-reference/godot/` no cubre (NOT SOURCEABLE).
**Arreglo:** (a) decidir una sola política: la inspección no escribe ni borra nada (el temporal huérfano inválido se elimina en el siguiente guardado, paso 1) o la copia a `.corrupt` ocurre una vez por fichero y por contenido; cambiar regla 23, L237 y AC-29. (b) En el fallback del paso 3, borrar `autosave.json` antes del paso 4 (el temporal ya está validado) y, si el borrado falla, tratarlo como fallo de escritura. Añadir AC con renombrado sobre existente fallando y borrado del principal fallando.

**5. [importante] La instantánea migrada se guarda en memoria, pero «Continuar» no revalida que el disco siga igual.** Reglas 17, 18, 21, AC-35.
La regla 18 consume la instantánea de la inspección «sin volver a leer». Entre la inspección (arranque) y «Continuar» puede pasar un tiempo arbitrario con el título abierto; si otro proceso (o una segunda instancia, edge case L278) cambia o borra el fichero, «Continuar» restaura algo que ya no está en disco y la línea base de `dif` no corresponde a nada. Es una consecuencia de la decisión D-19, que acierta en lo principal.
**Arreglo:** declararlo como límite aceptado en Edge Cases («Continuar» usa la última inspección; un cambio externo posterior se detecta al guardar, paso 3) o hacer una comprobación barata (tamaño y mtime, o relectura) al pulsar. Un AC para la opción elegida.

**6. [importante] La rama `snapshot_version` mayor y «Continuar» sobre `con_futura` destruyen el original sin avisar al jugador.** Reglas 13 (paso 3), 20, UI Requirements, D-11, D-18.
D-11 justifica no tratar el fichero de versión mayor como dañado porque «no se destruye al abrir con una build anterior». Pero el primer guardado de esa sesión borra el `autosave.json` futuro (solo queda una copia en `autosave.incompatible`, que la siguiente copia sustituye). El aviso de título informa de que Continuar carga la última compatible, no de que el siguiente guardado reemplaza la partida más nueva. Para una demo que se enseña en distintas builds es un riesgo real de pérdida de la partida más avanzada.
**Arreglo:** o conservar el futuro con otro nombre estable sin límite de una copia (por ejemplo `autosave.incompatible.<seq>` con tope), o ampliar el aviso/confirmación. Es decisión de diseño menor; si se acepta, quitar de D-11 la frase de que «no se destruye».

### Menores

**7. [menor] F2 y la tabla de Tuning Knobs dan tiempos erróneos.** F2 Example y Tuning Knobs (`n_fallos_aviso`).
«El aviso aparece unos 14 s después del primer fallo (2 + 4 + 8)» es incorrecto: el aviso sale en el tercer fallo, que ocurre 6 s después del primero (2 + 4); la espera de 8 s es posterior. AC-22 sí está bien («en el tercer fallo»). La nota «más de 5 deja al jugador sin saber que no se guarda durante más de un minuto» tampoco encaja: el 6.º fallo llega a los 62 s (2+4+8+16+30), el 5.º a los 30 s. **Arreglo:** corregir a «~6 s» y recalcular el umbral de la nota.

**8. [menor] AC-08c es vacuo.** AC-08c (reloj de tiempo real en pausa). Abrir la pausa ya escribe (`pause_opened`), y en pausa no cambian hechos, por lo que `periodico` solo puede ser verdadero si había un `dif` ya escrito. El criterio pasa sin probar nada. **Arreglo:** probar el reloj monotónico con la pausa sin cambios previos pendientes de `pause_opened` (cambiar un hecho por consola de desarrollo con la pausa abierta) o eliminarlo y dejar la nota de F1.

**9. [menor] La copia a `.corrupt` no tiene tope de tamaño.** AC-30(b), regla 22. Se copia byte a byte un fichero que supera `max_bytes_lectura` (65 536 B) «sin analizarlo». Un fichero basura de varios GB se copiaría entero. **Arreglo:** copiar solo los primeros `max_bytes_lectura` y marcarlo en el log.

**10. [menor] La base de `dif` tras «Continuar» es «el contenido cargado», no el estado que deja el 3.** Regla 7(a), regla 18 (2), GDD 3 (el derivado `caja_completa` se recalcula; hechos ausentes toman su inicial). Si el 3 normaliza algo al restaurar, `dif` es verdadero en la primera ocasión y se escribe sin que el jugador haya cambiado nada. Es benigno (incluso deseable) pero ambiguo. **Arreglo:** fijar la línea base con una instantánea pedida al 3 tras «estado restaurado», o declarar el comportamiento.

**11. [menor] Propagación pendiente en otros documentos.** (a) GDD 6, L89/L212/L214/L327: sigue en «A confirmar». (b) `systems-index.md`: filas 25, 21 y 22 no listan al 5 (el GDD 5 los declara como dependientes: 25 blanda; 22 dura por contrato). (c) GDD 18 no cita al 5 ni las claves `UI_…` de los avisos (Open Question 8). **Arreglo:** una línea en cada uno al cerrar el lote.

**12. [menor] Texto obsoleto respecto al GDD 3 y al registro.** El GDD 3 ya expone `snapshot_version` (regla 13), tiene los dos avisos nuevos (regla 10) y los lista en su tabla (L142). En el GDD 5 siguen: regla 20 («mientras el 3 no la exponga…»), Dependencies «Bloqueo cruzado con el 3», Open Question 2, la nota de AC-33 y AC-23 («no ejecutables»), y la «Propuesta de registro» (L504-L519) con varias filas ya registradas con otros nombres (`save_group_window_s`, `save_retry_*`, `save_fail_warn_count`, `save_max_read_bytes`). **Arreglo:** retirar el bloqueo cruzado, marcar OQ 2 y OQ 9 como cerradas, y añadir una columna con el nombre del registro a Tuning Knobs.

**13. [menor] La causa `dev` no tiene cláusula en F1.** Regla 6 la marca «urgente», pero F1 solo contempla `solicitud` (no urgentes), sellado y `quit`. «Guardar ahora» (regla 27) no tiene fórmula. **Arreglo:** añadir `es_dev` a la rama `¬sellando` o declarar que se trata como `solicitud` sin agrupación.

**14. [menor] Estado de la pista en la reanudación (P6 con dos niveles, resto con tres).** Regla 3 y slice §10, Anexo B.6. El nivel de pista alcanzado por puzle no es un hecho y no se guarda; tras reanudar vuelve al nivel 1. Es coherente con la regla 3 y con GDD 9 (D9-8), pero no está dicho en este GDD. **Arreglo:** una línea en «Qué no se guarda» («progreso de pistas»). Ver pregunta 4 por si se quiere conservar.

### Criterios de aceptación: testabilidad

- **AC-33** es insatisfacible tal como está (hallazgo 1).
- **AC-08c** es vacuo (hallazgo 8).
- **AC-12** (apagón) y **AC-41/43** dependen de recorridos de referencia del 21 (ya señalados como NOT ASSESSED hasta entonces: correcto).
- **AC-24** debe cubrir la variante con el borrado del principal también fallando (hallazgo 4).
- **Faltan:** nueva partida con fallo de carga y con fundido (3); tarjetas con cierre forzado (2); renombrado sobre existente fallando (4); cambio externo del fichero entre inspección y «Continuar» (5); causa `dev` (13).
- **AC-34, AC-43** deben figurar como NOT ASSESSED en el informe de QA mientras no existan 8, 9 a 16, 21 y 22.

## Consistencia con el slice (fuente de verdad)

- Coincide con §13.2, §13.3 y D.3 (puertas, compartimentos, llamada, `pendiente_revelacion`).
- Las causas extra (`puzzle_solved`, `reveal_pending`, `pause_opened`, `quit`, `periodic`) amplían D.3 sin contradecirlo.
- **Reinterpretación de D.2:** «`llamada_iniciada` evita repetir la llamada» pasa a «marca que el sellado se hizo; la llamada se repite siempre que no esté completada y guardada» (regla 12, D-4). El slice prevalece sobre cualquier GDD y esto lo modifica de hecho. Ver pregunta 1.
- Los 19 hechos coinciden en nombre y número con D.2; el tipo de `pos_*` (int 1 a 4, inicial 2) y los `enum` coinciden con el registro del GDD 3.
- Pilares: *Tensión sin castigo* queda bien servido por la escritura atómica, el respaldo y el sellado, con la salvedad del hallazgo 2.

## Riesgos de implementación en Godot 4.7 (solo lo respaldado por `docs/engine-reference/godot/`)

- **Respaldado:** `FileAccess.store_*` devuelve `bool` desde 4.4 (`breaking-changes.md` L91); el paso 1 de la regla 13 es implementable.
- **NOT SOURCEABLE** en `docs/engine-reference/godot/` (no hay `modules/core.md` ni cobertura de `FileAccess`, `DirAccess`, `JSON` o hashing): tipo numérico que devuelve el analizador JSON, semántica de renombrado sobre fichero existente en Windows y Linux, forzado a disco, borrado/renombrado de ficheros y sus códigos de error, API y algoritmo del hash, reloj monotónico, distinción entre cierre normal y forzado de la ventana. El GDD ya lo marca como pendiente (Open Question 1, F3); mientras no exista el ADR y se ejecute AC-42, la garantía de durabilidad y AC-20/21 solo cubren la lógica de secuencia. Según la regla de estos informes, **un ADR sin resolver estos puntos mantiene la garantía en «mejor esfuerzo»**.

## Preguntas para el usuario

1. **Reinterpretación de D.2.** El slice dice que `llamada_iniciada` «evita repetir la llamada». El GDD 5 lo invierte: la llamada se repite siempre que no esté completada y guardada, y quien complete la llamada y cierre antes o durante Recepción vuelve a vivirla (1 a 2 min). ¿Se acepta, y se anota en el slice, o se prefiere guardar también `llamada_completada` y `respuesta_llamada`? Cambia el slice (D.2) y la experiencia del tramo más emocional.
2. **Qué ofrece «Continuar» tras completar el slice (Open Question 10).** Con la partida sellada para siempre, «Continuar» vuelve a la llamada. Para la demo de financiación, ¿debe el título ofrecer solo «Nueva partida» tras llegar a Recepción? Afecta al alcance y al tono de la demo.
3. **Puertas B y D al reanudar.** Hoy solo se guardan las tarjetas, no el estado «abierta» de B y D. ¿El jugador debe encontrarlas cerradas (y volver a usar la tarjeta, sin penalización) o abiertas? Lo segundo exige hechos nuevos y toca D.2 (19 hechos).
4. **Progreso de pistas.** El nivel de pista alcanzado (tres niveles por puzle, dos en el P6) no se guarda y vuelve al nivel 1 al reanudar. ¿Es aceptable o conviene conservarlo (hechos nuevos, toca D.2)?
