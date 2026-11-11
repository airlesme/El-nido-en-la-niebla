# Sprint 1: sin fechas (10 días laborables nominales)

> **Hito**: M1 · Prototipo gris (escenas 1–3), `production/milestones/m1-gray-prototype.md`
> **Generado**: 2026-11-11 por `/sprint-plan new` (producer, `automation: autonomous`;
> `modes.rigor: standard`, así que `review_mode: lean` y `story_granularity: balanced`)
> **PR-SPRINT**: omitido (modo lean, no es PHASE-GATE). **No se ha empezado ninguna historia.**
> **QA plan**: no existe todavía. Hay que ejecutar `/qa-plan sprint` antes de empezar la primera historia (ver § QA).

## Sprint Goal

Construir y probar con gdUnit4 la base Foundation de la ruta crítica de M1
(*entrada → interacción → estado → puzle → puerta*): costuras de plataforma, pipeline de datos
validado, `NoticeChannel` y catálogo de hechos con lectura. Si la velocidad lo permite, se suman
el escritor de hechos y la pila de entrada hasta los plazos de `GameClock`. El sprint también
sirve para **medir la velocidad real** del equipo.

## Goal Prerequisites

El objetivo es solo de lógica y tests: no hay escena que enseñar.

| Necesario para mostrar el objetivo | Estado |
|---|---|
| Nada que ejecutar ni enseñar (historias Logic, evidencia = tests gdUnit4) | n/a |
| Addon gdUnit4 en `addons/gdUnit4/` (lo exige la CI) | existe |
| Flujo de CI `.github/workflows/tests.yml` | existe (que esté en verde hoy: **NOT VERIFIED**) |
| `src/core/composition/service_context.gd`, `src/core/boot/boot.gd` (los amplía EB-001) | existen |
| `GameClock.deadline()` / `is_due()` (los usa EC-005) | **sin implementar** (TODO en `src/core/game_clock.gd`); los implementa EC-005 según su propia nota (+0,5 d) |

No falta ningún prerrequisito.

## Milestone Context

- Hito actual: M1 · Prototipo gris. Sin fecha fija; duración de la línea base 2–4 semanas (esperado 3, ≈ 15 días laborables), confianza **baja**.
- Sprints previstos en la línea base: 2. **Este dato no es fiable**: ver R-S1-1.
- Backlog de M1 escrito: **124 historias en 11 épicos, ≈ 130 días-persona estimados, todas con confianza BAJA.**

## Capacity

- **Capacidad: desconocida.** No hay ningún sprint cerrado ni velocidad medida. Los 10 días son **nominales** (el reloj del sprint), no una capacidad comprometida.
- Total nominal: 10 días laborables
- Margen (20 %): 2 días para trabajo no previsto, corrección de la CI y reparto de estimaciones
- Disponible nominal: 8 días. Es lo que suma Must Have.
- **El Sprint 1 sirve para MEDIR la velocidad.** Should Have y Nice to Have no son compromiso: forman una cola de tirada **en orden topológico**, y se toma la siguiente solo cuando la anterior está cerrada. Así la medida sale aunque las estimaciones fallen hacia cualquiera de los dos lados.
- Unidad de estimación: días-persona del `stories.md` de cada épico (S ≈ 0,5 · M ≈ 1 · L ≈ 1,5–2), todos con **confianza BAJA**.

Equipo: una persona que dirige agentes de Claude. La columna «Agente» indica el especialista
que implementa por `/dev-story`. Una sola persona revisa todo, así que nada corre en paralelo
si depende de algo abierto (R-M1-6).

Prefijos de ID: **EB** = `estado-y-bus` · **CD** = `contenido-y-datos` · **EC** = `entrada-y-controles`.
Ninguna historia está Blocked. Las 15 están `Ready` según su línea `> **Status**` (Grep, 2026-11-11).

## Tasks

El orden de la tabla es el de ejecución, y es topológico: ninguna fila depende de otra posterior.
Todas son de tipo **Logic**. Su evidencia es un test unitario gdUnit4 en verde, que bloquea
(`coding-standards.md` § Test Evidence).

### Must Have (Critical Path): 7 historias, 8,0 días nominales

| # | ID | Historia | Agente | Est. (d) | Depende de | ADR (todos Accepted) | Tipo · evidencia | Criterio de aceptación |
|---|----|----------|--------|---------|------------|------|------|------|
| 1 | EB-001 | [Costuras de plataforma: `LogSink`, `ErrorPolicy`, `FatalErrorHandler`, `TestContexts`](../epics/estado-y-bus/story-001-platform-seams.md) | lead-programmer | 1,5 | — | 0009, 0001 | Logic · `tests/unit/state/platform_seams_test.gd` | CA de la historia + suite verde |
| 2 | CD-001 | [`FileStore` y `JsonText` (BOM, comas finales, claves duplicadas)](../epics/contenido-y-datos/story-001-file-store-and-json-text.md) | lead-programmer | 1 | EB-001 | 0005, 0009 | Logic · `tests/unit/content/json_text_test.gd` | ídem |
| 3 | EB-002 | [`NoticeChannel`: suscripción, cola FIFO, drenaje síncrono](../epics/estado-y-bus/story-002-notice-channel-core.md) | lead-programmer | 1 | EB-001 | 0001 | Logic · `tests/unit/state/notice_channel_core_test.gd` | ídem |
| 4 | CD-002 | [`DataSchema`/`FieldSpec`, `DataReader.normalise` y `to_int`](../epics/contenido-y-datos/story-002-schema-and-data-reader.md) | lead-programmer | 1,5 | CD-001 | 0005 | Logic · `tests/unit/content/data_reader_test.gd` | ídem |
| 5 | CD-003 | [`DataCatalog`, `RefIndex` y `DataValidator`](../epics/contenido-y-datos/story-003-data-catalog-and-validator.md) | lead-programmer | 1 | CD-002 | 0005, 0009 | Logic · `tests/unit/content/data_validator_test.gd` | ídem |
| 6 | EB-005 | [Esquema de `flags.json` y `GameState.load_catalog`](../epics/estado-y-bus/story-005-flags-schema-and-catalog-load.md) | lead-programmer | 1,5 | EB-001, CD-002, CD-003 | 0005, 0001 | Logic · `tests/unit/state/flags_catalog_load_test.gd` | ídem |
| 7 | EB-007 | [Lecturas O(1): `get_fact`, `resolve_fact`, `get_fact_at`](../epics/estado-y-bus/story-007-fact-reads.md) | lead-programmer | 0,5 | EB-005 | 0001 | Logic · `tests/unit/state/fact_reads_test.gd` | ídem |

### Should Have: primeras en la cola de tirada, 3 historias, 3,5 días nominales

| # | ID | Historia | Agente | Est. (d) | Depende de | ADR | Tipo · evidencia | Criterio |
|---|----|----------|--------|---------|------------|-----|------|------|
| 8 | EB-003 | [`NoticeChannel`: tope de encadenados, callables inválidos, `run_after_drain`, tap](../epics/estado-y-bus/story-003-notice-channel-cap-and-lifecycle.md) | lead-programmer | 1 | EB-002 | 0001 | Logic · `tests/unit/state/notice_channel_cap_test.gd` | CA + suite verde |
| 9 | EB-008 | [Escritura validada y `FactWriter` (escritor de hechos)](../epics/estado-y-bus/story-008-validated-writes-and-writer.md) | lead-programmer | 1,5 | EB-003, EB-007 | 0001 (+0005 vía catálogo) | Logic · `tests/unit/state/validated_writes_test.gd` | ídem |
| 10 | EB-004 | [Registro `NoticeIds` y validación de payload en debug](../epics/estado-y-bus/story-004-notice-ids-registry.md) | lead-programmer | 1 | EB-002 | 0001 | Logic · `tests/unit/state/notice_ids_registry_test.gd` | ídem |

### Nice to Have: resto de la cola de tirada, 5 historias, 6,0 días nominales

| # | ID | Historia | Agente | Est. (d) | Depende de | ADR | Tipo · evidencia | Criterio |
|---|----|----------|--------|---------|------------|-----|------|------|
| 11 | EC-001 | [`InputTypes`, `BindingTable` y `default_bindings.json`](../epics/entrada-y-controles/story-001-input-types-and-binding-table.md) | gameplay-programmer | 1,5 | EB-001, CD-002, CD-003 | 0006, 0005 | Logic · `tests/unit/input/binding_table_test.gd` | CA + suite verde |
| 12 | EC-002 | [`EngineInputAdapter` → `RawInput` y `feed()`](../epics/entrada-y-controles/story-002-engine-input-adapter.md) | gameplay-programmer | 1 | EC-001 | 0006 | Logic · `tests/unit/input/engine_input_adapter_test.gd` | ídem |
| 13 | EC-003 | [Pila de contextos, sinks y `input_context_changed`](../epics/entrada-y-controles/story-003-context-stack-and-sinks.md) | gameplay-programmer | 1 | EC-002, EB-004 | 0006, 0003, 0001 | Logic · `tests/unit/input/context_stack_test.gd` | ídem |
| 14 | EC-004 | [Operaciones de `sin control` y puerto `InputContexts`](../epics/entrada-y-controles/story-004-no-control-operations.md) | gameplay-programmer | 1 | EC-003 | 0006, 0003 | Logic · `tests/unit/input/no_control_operations_test.gd` | ídem |
| 15 | EC-005 | [Tope de seguridad con `GameClock` (plazos `deadline`/`is_due`), `carga_en_curso`, reinicio de pila](../epics/entrada-y-controles/story-005-safety-cap-and-loading-state.md) | gameplay-programmer | 1,5 (1 + 0,5 por los plazos sin implementar) | EC-004 | 0006, 0002, 0003, 0001 | Logic · `tests/unit/input/safety_cap_and_loading_test.gd` + `tests/unit/core/game_clock_test.gd` | ídem |

**Totales:** 15 historias · 17,5 días nominales (Must 8,0 · Should 3,5 · Nice 6,0). Lo comprometido
es Must, con 7 historias, y entra en el rango `balanced` de 6 a 10. Must + Should suman 10 historias.

**Cadena crítica del sprint:** EB-001 → CD-001 → CD-002 → CD-003 → EB-005 → EB-007 → EB-008. EB-008 es
el escritor de hechos, y de él dependen todas las historias jugables de M1 que escriben un hecho.
Rama de entrada: CD-003 → EC-001 → EC-002 → EC-003 (necesita también EB-004) → EC-004 → EC-005.
ADR citados: 0001, 0002, 0003, 0005, 0006 y 0009, todos Accepted. Ninguna historia del sprint
cita 0010, 0011, 0012 ni 0017; esos ADR rigen los épicos de Core y Feature de los sprints
siguientes. Las co-citas `Proposed` de estos épicos (0004, 0007, 0016, 0018) solo afectan a
requisitos que sus `stories.md` ya dejan fuera.

## Carryover from Previous Sprint

Ninguno: es el primer sprint.

## Criterio de salida del sprint

1. Todas las historias Must Have pasan a `Complete` por `/story-done`, con sus CA marcados.
2. **Todos los tests gdUnit4 en verde en local**, con el comando de CI de `coding-standards.md`, e incluyen las suites nuevas del sprint.
3. **CI verde** (`Run GdUnit4 Tests` de `.github/workflows/tests.yml`) en el último commit del sprint. Si el job no se pudo ver, se escribe **NOT VERIFIED** y no cuenta como verde.
4. Velocidad medida y anotada: días-persona *reales* por historia cerrada frente a su estimación (ver § Medición).

Una historia de Should o Nice que quede a medias **no** cuenta como hecha. Pasa a Carryover del Sprint 2.

## Medición de velocidad (lo que produce este sprint)

- Por cada historia cerrada se anota: estimación, días reales (media jornada como unidad) y desvío. Va en su story file (`Last Updated`) y en el informe de cierre (`/sprint-status`, `/retrospective`).
- Velocidad del Sprint 1 = suma de las estimaciones de las historias cerradas ÷ días laborables reales usados.
- Factor de corrección = días reales ÷ días estimados de las mismas historias. Se aplica a los ≈ 130 días de M1 para rebaselinar.
- Hasta que se mida, toda cifra de capacidad o plazo de M1 es **NOT VERIFIED / estimación BAJA**.

## Reglas de replanificación (al cerrar el Sprint 1)

1. **Rebaselinar M1** con la velocidad y el factor medidos. Plazo restante = (≈ 130 d − días cerrados) × factor ÷ días laborables por semana. Se escribe en `m1-gray-prototype.md` § Plazo y § Registro de cambios.
2. Si el total rebaselinado no cabe en el plazo de M1 que **el usuario** fije (decisión U-1), se aplica el **orden de recorte del hito** (`m1-gray-prototype.md` § Orden de recorte): 1 manos → 2 pistas de P1 → 3 subtítulos → 4 guardado → 5 pausa → 6 rotación → 7 ajustes y audio por zonas → 8 escena 1 simplificada. **Un recorte cada vez**, cada uno anotado, y se vuelve a calcular tras cada uno. Lo que el hito marca «no se recorta nunca» no se toca.
3. Si con los recortes 1 a 7 sigue sin caber, **no** se aplica el 8 sin consultar: se para y se presentan al usuario dos opciones, mover el plazo o recortar la escena 1, porque toca el tono.
4. Las historias de Should y Nice no cerradas pasan al Sprint 2 como Carryover, con nueva estimación y el factor medido. No vuelven a entrar como trabajo nuevo.
5. Sprint 2 empieza por lo que quede de la cadena (EB-008, EC-001…005) y sigue el orden entre épicos del índice: estado → contenido/entrada → jugador → carga de planta → interacción → …

## Risks

No hay registro de riesgos (`production/risk-register/` no existe). Los riesgos salen del contenido
del sprint y del hito.

| ID | Riesgo | Prob. | Impacto | Mitigación |
|----|--------|-------|---------|------------|
| **R-S1-1** | **M1 ≈ 130 días-persona estimados frente a ≈ 15 planificados** (124 historias, 11 épicos, confianza BAJA). La línea base de M1 (2–4 semanas) es de 8 a 9 veces menor que el backlog escrito. | Alta (es un hecho, no una probabilidad; lo único incierto es el factor real) | Muy alto: M1 no cabe sin replanificar | El Sprint 1 mide la velocidad. Después se rebaselina y se aplica el orden de recorte (§ Reglas). La decisión es del usuario (U-1). |
| R-S1-2 | Estimaciones de confianza BAJA: el reparto real puede alejarse ±50 % | Alta | Medio | Cola de tirada en orden topológico, en lugar de compromiso, y margen del 20 % |
| R-S1-3 | `GameClock.deadline()`/`is_due()` sin implementar (y también `schedule`/`cancel`, TODO de ADR-0002) | Cierta | Bajo | EC-005 lleva +0,5 d. Si otra historia lo necesita antes, se adelanta ahí (no hay ninguna en este sprint). |
| R-S1-4 | Estado actual de la CI: **NOT VERIFIED** (no se ejecutó en esta planificación) | Media | Medio | Hacer una pasada de CI antes de EB-001. Si falla, se arregla con cargo al margen. |
| R-S1-5 | Riesgo de motor HIGH en entrada (4.7: `DEVICE_ID_*`, SDL3) | Media | Bajo en este sprint (lógica con `feed()` y dobles) | Las pruebas con mando físico son NEEDS_MANUAL y no entran en el sprint (EC-015) |
| R-S1-6 | Una persona: cualquier bloqueo detiene todo (R-M1-6) | Alta | Alto | Nada en paralelo que dependa de algo abierto. Si se bloquea una historia, se pasa a la siguiente de la cola que no dependa de ella. |
| R-S1-7 | Sin QA plan del sprint | Cierta hoy | Medio | `/qa-plan sprint` antes de la primera historia |

## Decisiones del usuario (no las toma este plan)

| ID | Decisión | Qué desbloquea / de qué depende | Cuándo hace falta |
|----|----------|------|------|
| **U-1** | **Replanificar M1**: aceptar el plazo rebaselinado con la velocidad medida, y hasta qué recorte del orden se llega, o mover el plazo | Todo M1 (R-S1-1) | Al cerrar el Sprint 1 |
| **U-2** | **Aceptar ADR-0016 y ADR-0007** (parcial: escalado de UI). ADR-0016 desbloquea el prompt (GDD 24, 20 TR). ADR-0007 desbloquea el escalado de UI del prompt y del ordenador (TR-prompt-018, TR-computer-013/014). | Épicos interaccion-y-prompt (24) y ordenador-e-impresora. No bloquean este sprint. | Antes del sprint que tome historias del prompt |
| **U-3** | **Las 6 decisiones de diseño pendientes** de `design/gdd/gdd-cross-review-2026-11-10-r2.md` § «Decisiones tuyas pendientes»: (1) espera de pistas 20/40 s; (2) parpadeo/apagón con `reducir_sobresaltos`; (3) `reducir_movimiento` y `escala_texto_ui`; (4) filtro del aviso «interacción ejecutada» (opción por defecto aplicada); (5) suelo de subtítulos a 720p; (6) las de siempre (D13-4, `slot_6`, `VO_G_07`, …) | Según el hito, la 3 y la 4 afectan a M1 directamente, y la 1 y la 5 si no se recortan pistas ni subtítulos | Antes de las historias de pistas, subtítulos, ajustes o prompt |

## Dependencies on External Factors

- Ninguna externa. Internas: CI de GitHub Actions disponible y addon gdUnit4 instalado (existe).

## QA

No hay QA plan para este sprint (Glob `production/qa/qa-plan-*.md`: vacío). Sin QA plan los
requisitos de prueba quedan sin definir y el sprint no podrá pasar la puerta Production → Polish.
**Decisión en modo autonomous (opción A, la recomendada):** ejecutar `/qa-plan sprint` antes de
empezar ninguna historia.

## Definition of Done for this Sprint

- [ ] Todas las historias Must Have completas (`/story-done`)
- [ ] Todas pasan sus criterios de aceptación
- [ ] Existe el QA plan (`production/qa/qa-plan-sprint-001-[date].md`, de `/qa-plan sprint`)
- [ ] Todas las historias Logic tienen sus tests gdUnit4 en verde
- [ ] CI verde en el último commit (o NOT VERIFIED anotado, que no cuenta como verde)
- [ ] Smoke check pasado (`/smoke-check sprint`)
- [ ] Informe de QA: APPROVED o APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] Ningún bug S1 o S2 en lo entregado
- [ ] GDD actualizados si hubo desviaciones
- [ ] Código revisado y en `main`
- [ ] Velocidad medida anotada y M1 rebaselinado (§ Reglas de replanificación)

## Decisiones tomadas (modo autonomous)

- **D-S1-1: Compromiso solo en Must (8 d = 80 % de 10).** Should y Nice forman una cola de tirada ordenada. *Descartado:* comprometer las 15 historias (17,5 d), que es una capacidad inventada. *Descartado también:* planificar solo 8 días, porque si las estimaciones resultan pesimistas la medida se quedaría sin trabajo.
- **D-S1-2: Estado y datos antes que entrada.** La cadena hasta EB-008 alimenta toda escritura de hechos de M1. Entrada necesita además CD-002/003 y EB-004. *Descartado:* entrada primero, porque deja el escritor de hechos para el Sprint 2.
- **D-S1-3: Los «plazos de GameClock» entran por EC-005.** Ninguna historia de estado-y-bus los implementa, y EC-005 los asume (+0,5 d).
- **D-S1-4: `production/sprint-status.yaml` no se escribe en esta pasada**, porque el orquestador limitó la salida a este fichero y a una línea del hito. Se genera con `/sprint-plan update` al empezar el sprint; las prioridades salen de las tablas de arriba (Must → `ready-for-dev`; Should y Nice → `backlog`).
- **D-S1-5: Sin fechas.** El hito no tiene fecha y la capacidad es desconocida. Las fechas reales se anotan al empezar y al cerrar.

## Resultado del Sprint 1 (2026-11-11)

**Hecho: 10 historias** (7 comprometidas + 3 de la cola): EB-001, EB-002, EB-003, EB-004, EB-005, EB-006, EB-007, CD-001, CD-002, CD-003. Todas Logic, todas con tests gdUnit4 en verde. Suite final **290/290, 0 errores, 0 fallos, 0 huérfanos, 0 fugas de ObjectDB**, `forbid_timers` y `check_pins` limpios, arranque en debug sin fatal. Verificada por el lead tras cada historia (no solo por el agente).

| Métrica | Valor | Fiabilidad |
|---|---|---|
| Historias cerradas | 10 de 15 del backlog del sprint (los 7 Must Have y 3 de los 8 de la cola) | medida |
| Estimado de lo cerrado | ≈ 10,5 días-persona nominales (EB-006 añadida a la cola durante el sprint) | estimación de confianza BAJA |
| Esfuerzo real en turnos de agente | ≈ 10–22 por historia, mediana ≈ 12; ≈ 130 en total incluidas reanudaciones y correcciones | medida aproximada (turnos que declaran los agentes) |
| Tiempo de calendario | **NOT MEASURED** (el sprint se ejecutó en una sesión de trabajo continua; no hay fechas de inicio/fin) | — |
| Defectos encontrados y corregidos dentro del sprint | 1 ciclo de referencias en tests (49 instancias filtradas al salir), 1 helper de test que dejaba huérfanos, 1 test frágil por carga | medida |

**Qué se aprende (para rebaselinar M1)**
- Con este modelo (una persona que dirige agentes, historias Logic ≤ 2 días nominales) el coste real es del orden de **una docena de turnos de agente por historia**, no de 1–2 días-persona. Las 124 historias de M1 serían ≈ 1.500 turnos si todas fueran de este tipo, pero **no lo son**: las Visual/Feel, UI e Integration exigen capturas, sesiones manuales con teclado y mando y juicio del desarrollador, y ahí el cuello de botella pasa a ser el desarrollador, no los agentes.
- El estimado «130 días-persona» **no es una buena unidad** para este equipo; la unidad útil es «historias cerradas verificadas por sesión». No se puede convertir a calendario sin fechas: la próxima iteración debe registrar fecha de inicio y fin.
- Calidad: ningún criterio se marcó hecho sin evidencia, pero hubo 3 incidencias de procedimiento (fugas, helper, test frágil) que un agente solo no vio; la verificación independiente del lead por historia es lo que las detectó. Mantenerla.
- Deuda abierta: test frágil `tests/unit/engine_facts/adr0012_tick_interpolation_test.gd` (QA plan: aislar en `tests/timing/`); smoke formal `production/qa/smoke-*.md` de EB-006; enmiendas al ADR-0001 (el 2.º desbordamiento solo registra) y al ADR-0005 (nombres de hecho con mayúsculas, `float` exacto).

**Pendiente de decisión del usuario** (sin cambios): U-1 replanificar M1 con este dato (orden de recorte del hito); U-3 las 6 decisiones de diseño de `design/gdd/gdd-cross-review-2026-11-10-r2.md`.
