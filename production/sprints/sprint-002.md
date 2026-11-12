# Sprint 2: Ruta crítica en lógica (inicio 2026-11-11)

> **Hito**: M1 · Prototipo gris (escenas 1–3), `production/milestones/m1-gray-prototype.md`
> **Generado**: 2026-11-11 por `/sprint-plan new` (producer, `automation: autonomous`;
> `modes.rigor: standard` → `review_mode: lean`, `story_granularity: balanced`)
> **PR-SPRINT**: omitido (modo lean, no es PHASE-GATE).
> **Decisión del usuario (2026-11-11)**: Sprint 2 = RUTA CRÍTICA, solo historias Logic, en olas paralelas.
> **QA plan**: no existe para este sprint (ver § QA).

## Fechas (se registran, no se estiman)

| Campo | Valor |
|---|---|
| Inicio | **2026-11-11** |
| Fin | `____-__-__` (rellenar al cerrar) |
| Sesiones de trabajo usadas | `__` (rellenar al cerrar) |
| Turnos de agente totales | `__` (rellenar al cerrar; incluir reanudaciones y correcciones) |
| Fin de cada ola | O0 `__` · O1 `__` · O2 `__` · O3 `__` · O4 `__` · O5 `__` |

Sin estas fechas el Sprint 2 repite el hueco del Sprint 1 («Tiempo de calendario: NOT MEASURED»)
y M1 sigue sin poder pasarse a calendario.

## Sprint Goal

Llevar la cadena *entrada → jugador → carga de planta → interacción → estado → datos* hasta todo
lo que hoy se puede implementar y probar **solo con gdUnit4 headless**: escritor de hechos y sus
reglas, pila de entrada hasta `sin control` y el tope con `GameClock`, configuración y cálculo del
jugador, datos y fórmulas de carga, y catálogo + picking + oclusión de la interacción.

## Goal Prerequisites

El objetivo es de lógica y tests; no hay escena que enseñar.

| Necesario para mostrar el objetivo | Estado |
|---|---|
| Nada que ejecutar ni enseñar (Logic, evidencia = tests gdUnit4) | n/a |
| Addon gdUnit4 y comando de CI | existen |
| `GameState` con catálogo y lecturas (EB-005/007), `NoticeChannel` + `NoticeIds` (EB-002/003/004), `DataCatalog`/`DataReader` (CD-001..003) | existen (Sprint 1) |
| `GameClock.deadline()`/`is_due()` | **sin implementar** (`src/core/game_clock.gd` l. 3, TODO ADR-0002); **built by EC-005** |
| Directorio `tests/timing/` para el test frágil | no existe; lo crea la deuda D-1 (tarea de mantenimiento de tests, no historia) |

No falta ningún prerrequisito.

## Capacity

- **Unidad: historias cerradas y verificadas por el lead.** No días-persona (ver «Qué se aprende» del Sprint 1).
- Referencia medida: Sprint 1 = **10 historias Logic en una sesión, mediana ≈ 12 turnos/historia, ≈ 130 turnos** con reanudaciones.
- Este sprint: **18 historias** (≈ 216 turnos de agente a la mediana, más verificación). Es 1,8 × lo medido; el multiplicador lo pone el paralelismo por olas, que **no está medido** (R-S2-1).
- Compromiso: **Must = 13 historias** (≈ 1,3 × lo medido). **Should = 5**, cola de tirada dentro de sus olas: si una ola se atasca, las Should de olas posteriores se aplazan antes que una Must.
- Margen: el 20 % se reserva como turnos del lead para verificación independiente, deuda D-1/D-2 y una corrección de fugas o huérfanos por ola (el Sprint 1 tuvo 3 incidencias de procedimiento en 10 historias).
- Estimaciones nominales en días: se copian de `stories.md` solo como talla relativa (confianza BAJA).

Prefijos: **EB** estado-y-bus · **EC** entrada-y-controles · **PJ** jugador-primera-persona · **CP** carga-de-planta · **IP** interaccion-y-prompt.

## Regla de olas

1. Una ola = historias **sin dependencia entre sí** y con **ficheros de código disjuntos**. Se lanza un agente por historia a la vez (`/dev-story`).
2. Ficheros compartidos que obligan a separar olas: `game_state.gd`, `fact_writer.gd`, `input_router.gd`, `data_catalog.gd`, `notice_ids.gd`, `game_clock.gd`, `service_context.gd`, `boot.gd`. Como mucho **un titular por ola** de cada uno.
3. **`data_catalog.gd` se trata como compartido por toda historia que añade un fichero de datos** (F-R50: la fila y el esquema se registran ahí antes de que exista el fichero; `_schema_for` tiene los TODO de entrada y narrativa). Titulares: EC-001, IP-001, PJ-001, CP-002, una por ola. Si `/story-readiness` muestra que alguno no lo toca, puede adelantarse, pero no se juntan dos.
4. Helpers de test compartidos (`tests/doubles/*`, `TestContexts`): solo los toca el lead **entre olas**; un agente que los necesite cambiar lo declara y espera.
5. Ninguna ola empieza hasta que **todas** las historias de la anterior estén cerradas y verificadas, o una se haya bajado explícitamente a la siguiente.

## Verificación independiente del lead (tras CADA historia)

El agente que implementa no cierra su historia. Tras cada una, el lead (sin el contexto del agente):
1. relee los CA y comprueba que cada uno tiene su aserto;
2. ejecuta la **suite completa** con el comando de CI, no solo la suite nueva, y lee el informe (nombre de la suite presente, nº de tests > 0);
3. comprueba **0 fugas ObjectDB y 0 huérfanos**, `forbid_timers` y `check_pins` limpios;
4. lanza el **arranque en debug** y confirma que no hay fatal;
5. solo entonces `/story-done` y un commit por historia (Conventional Commits, `Story: XX-NNN`).
Tras cada ola, una pasada extra de suite completa con las historias de la ola juntas (los ficheros eran disjuntos; los efectos en `ServiceContext`/notices puede que no).

## Ola 0 — Deuda (lead, antes de la ola 1)

| # | Tarea | Ficheros | Evidencia | Criterio |
|---|---|---|---|---|
| D-1 | Aislar el test frágil: los asertos deterministas se quedan en `tests/unit/engine_facts/adr0012_tick_interpolation_test.gd` (bloqueantes); los 4 asertos sensibles a carga pasan a `tests/timing/adr0012_tick_rates_timing_test.gd`; `after_test()` con `Engine.max_fps = 0` en ambos (opción 1 de `production/qa/qa-plan-sprint-001.md` § test frágil) | los dos tests + anotación en `tests/README.md` (motivo, quién, cómo se vuelve a medir) | suite verde 3 veces seguidas; `tests/timing/` se ejecuta y se anota en el smoke, nunca se omite | ningún aserto estructural pierde cobertura |
| D-2 | Smoke formal de EB-006 (Config/Data) | `production/qa/smoke-2026-11-11.md` | informe con suites, nº de tests, fallos, huérfanos y fugas; arranque debug con `flags.json` sin fatal | `/smoke-check` PASS; si falta una suite esperada → FAIL, no PASS |

Fuera de este sprint (deuda anotada, sin dueño aquí): enmiendas a ADR-0001 (2.º desbordamiento solo registra) y ADR-0005 (nombres de hecho con mayúsculas, `float` exacto). Son de `technical-director`.

## Tasks

Todas **Logic**, `Ready`, dependencias cerradas o dentro del sprint en una ola anterior.
Evidencia: test unitario gdUnit4 en verde, BLOQUEANTE (`coding-standards.md` § Test Evidence).
ADR: todos `Accepted`. Las menciones a ADR `Proposed` (0004, 0008, 0013, 0018) de estas historias
son exclusiones ya marcadas como Diferido en su propio story file; no bloquean.

### Must Have (Critical Path): 13 historias

| ID | Historia | Ola | Ficheros previstos (código/datos) | ADR | Evidencia (gdUnit4) | Depende de | Est. (d) |
|---|---|---|---|---|---|---|---|
| EB-008 | [Escritura validada y `FactWriter`](../epics/estado-y-bus/story-008-validated-writes-and-writer.md) | 1 | `src/core/game_state.gd`, `src/core/fact_writer.gd` | 0001 (+0005) | `tests/unit/state/validated_writes_test.gd` | EB-003 ✓, EB-007 ✓ | 1,5 |
| EC-001 | [`InputTypes`, `BindingTable`, `default_bindings.json`](../epics/entrada-y-controles/story-001-input-types-and-binding-table.md) | 1 | `src/input/input_types.gd`, `binding_table.gd`, `data/default_bindings_schema.gd`, `assets/data/input/default_bindings.json`, **`data_catalog.gd`** (TODO ADR-0006) | 0006, 0005 | `tests/unit/input/binding_table_test.gd` | EB-001 ✓, CD-002 ✓, CD-003 ✓ | 1,5 |
| PJ-003 | [`TickInterpolator` con la fracción del motor](../epics/jugador-primera-persona/story-003-tick-interpolator.md) | 1 | `src/player/tick_interpolator.gd` | 0012 | `tests/unit/player/tick_interpolator_test.gd` | — | 0,5 |
| EB-009 | [Hechos de un solo sentido y reversibles](../epics/estado-y-bus/story-009-one-way-and-reversible-facts.md) | 2 | `src/core/game_state.gd` | 0001 | `tests/unit/state/one_way_facts_test.gd` | EB-008 | 0,5 |
| EC-002 | [`EngineInputAdapter` → `RawInput` y `feed()`](../epics/entrada-y-controles/story-002-engine-input-adapter.md) | 2 | `src/input/engine_input_adapter.gd`, `src/input/input_router.gd` | 0006 | `tests/unit/input/engine_input_adapter_test.gd` | EC-001 | 1 |
| IP-001 | [Catálogo `interactables.json`, esquema y configuración](../epics/interaccion-y-prompt/story-001-catalogo-interactuables.md) | 2 | `assets/data/interaction/{interactables,interaction_config,cobertura_anexo_a}.json`, `src/interaction/interaction_catalog.gd`, **`data_catalog.gd`** | 0011, 0005 | `tests/unit/interaction/catalogo_interactuables_test.gd` | CD-002 ✓, CD-003 ✓ | 1 |
| EB-010 | [Hechos derivados (`caja_completa`)](../epics/estado-y-bus/story-010-derived-facts.md) | 3 | `src/core/game_state.gd` | 0001 | `tests/unit/state/derived_facts_test.gd` | EB-008 | 0,5 |
| EC-003 | [Pila de contextos, sinks, `input_context_changed`](../epics/entrada-y-controles/story-003-context-stack-and-sinks.md) | 3 | `src/input/input_router.gd`, `src/input/context_stack.gd`, (`notice_ids.gd` si falta el aviso) | 0006, 0003, 0001 | `tests/unit/input/context_stack_test.gd` | EC-002, EB-004 ✓ | 1 |
| PJ-001 | [`PlayerConfig` y validación de `player.json`](../epics/jugador-primera-persona/story-001-player-config.md) | 3 | `src/player/player_config.gd`, `assets/data/player/player.json`, **`data_catalog.gd`** | 0012, 0005 | `tests/unit/player/player_config_test.gd` | cargador ADR-0005 ✓ | 1 |
| EB-011 | [Partida nueva: `reset_new_game`, `state_reset`](../epics/estado-y-bus/story-011-reset-new-game.md) | 4 | `src/core/game_state.gd`, (`notice_ids.gd` si falta `state_reset`) | 0001 | `tests/unit/state/reset_new_game_test.gd` | EB-003 ✓, EB-008 | 0,5 |
| EC-004 | [Operaciones de `sin control` y puerto `InputContexts`](../epics/entrada-y-controles/story-004-no-control-operations.md) | 4 | `src/input/input_router.gd`, `src/input/input_contexts.gd` | 0006, 0003 | `tests/unit/input/no_control_operations_test.gd` | EC-003 | 1 |
| CP-002 | [`load_transitions.json` y su validación](../epics/carga-de-planta/story-002-load-transitions-data.md) | 4 | `assets/data/scene/load_transitions.json`, `src/scene/load_transitions.gd`, **`data_catalog.gd`** | 0003, 0005 | `tests/unit/scene/load_transitions_validation_test.gd` | cargador ADR-0005 ✓ | 0,5 |
| EC-005 | [Tope de seguridad con `GameClock`, `carga_en_curso`, reinicio de pila](../epics/entrada-y-controles/story-005-safety-cap-and-loading-state.md) | 5 | `src/input/input_router.gd`, **`src/core/game_clock.gd`** (`deadline`/`is_due`), (`notice_ids.gd` avisos de carga) | 0006, 0002, 0003, 0001 | `tests/unit/input/safety_cap_and_loading_test.gd` + `tests/unit/core/game_clock_test.gd` | EC-004 | 1,5 |

### Should Have: 5 historias (cola de tirada, dentro de su ola)

| ID | Historia | Ola | Ficheros previstos | ADR | Evidencia (gdUnit4) | Depende de | Est. (d) |
|---|---|---|---|---|---|---|---|
| IP-002 | [`PickRegistry` y `PickMath`](../epics/interaccion-y-prompt/story-002-pick-registry-y-pickmath.md) | 3 | `src/interaction/interactable_pick.gd`, `pick_registry.gd`, `pick_math.gd`, `ports/eye_ray_source.gd` | 0011 | `tests/unit/interaction/pick_math_test.gd` | IP-001 | 1,5 |
| IP-003 | [Capas físicas y `OcclusionProbe`](../epics/interaccion-y-prompt/story-003-capas-y-oclusion.md) | 4 | `src/interaction/ports/occlusion_probe.gd`, `src/interaction/physics_occlusion_probe.gd` | 0011 | `tests/unit/interaction/oclusion_test.gd`, `oclusion_fisica_test.gd` | IP-002 | 1 |
| PJ-002 | [Locomoción F1/F2 en el marco del cuerpo](../epics/jugador-primera-persona/story-002-locomotion.md) | 4 | `src/player/locomotion.gd` | 0012 | `tests/unit/player/locomotion_test.gd` | PJ-001 | 1 |
| PJ-004 | [Mirada 1:1: yaw/pitch, límites, roll 0](../epics/jugador-primera-persona/story-004-look.md) | 5 | `src/player/look.gd`, `src/player/ports/player_input_port.gd` | 0012, 0006 | `tests/unit/player/look_test.gd` | PJ-001 | 1 |
| CP-003 | [Fórmulas del telón (F1) y `D_carga` (F3)](../epics/carga-de-planta/story-003-curtain-and-dcarga-formulas.md) | 5 | `src/scene/curtain_math.gd`, `src/scene/load_budget.gd` | 0003 | `tests/unit/scene/curtain_formula_test.gd`, `d_carga_test.gd` | CP-002 | 0,5 |

**Totales:** 18 historias (Must 13 · Should 5), ≈ 17 días nominales de talla relativa. Rango `balanced` (6–10) superado a propósito por decisión del usuario (ruta crítica) y por el paralelismo; el compromiso real son las 13 Must.

### Olas (resumen)

| Ola | Historias | Titular de fichero compartido | Nº |
|---|---|---|---|
| 0 | D-1, D-2 (lead) | tests/ y production/qa/ | 2 tareas |
| 1 | EB-008 · EC-001 · PJ-003 | `game_state`/`fact_writer` (EB-008), `data_catalog` (EC-001) | 3 |
| 2 | EB-009 · EC-002 · IP-001 | `game_state` (EB-009), `input_router` (EC-002), `data_catalog` (IP-001) | 3 |
| 3 | EB-010 · EC-003 · PJ-001 · IP-002 | `game_state` (EB-010), `input_router`+`notice_ids` (EC-003), `data_catalog` (PJ-001) | 4 |
| 4 | EB-011 · EC-004 · CP-002 · IP-003 · PJ-002 | `game_state`+`notice_ids` (EB-011), `input_router` (EC-004), `data_catalog` (CP-002) | 5 |
| 5 | EC-005 · PJ-004 · CP-003 | `input_router`+`game_clock`+`notice_ids` (EC-005) | 3 |

La profundidad de 5 olas la fija la cadena de entrada (EC-001 → … → EC-005, 4 de ellas en `input_router.gd`) y la de `game_state.gd` (EB-008 → 009 → 010 → 011). Ninguna ola tiene dos titulares del mismo fichero.

## Carryover from Previous Sprint

Las 5 historias de la cola del Sprint 1 no cerradas. Entran solo aquí; no se repiten como trabajo nuevo.

| Historia | Motivo | Nueva estimación | Dónde |
|---|---|---|---|
| EB-008 | Cola de tirada del Sprint 1, no alcanzada | ≈ 12–22 turnos (la más grande del estado) | Must, ola 1 |
| EC-001 | ídem | ≈ 12 turnos | Must, ola 1 |
| EC-002 | ídem | ≈ 12 turnos | Must, ola 2 |
| EC-003 | ídem | ≈ 12 turnos | Must, ola 3 |
| EC-004 | ídem | ≈ 12 turnos | Must, ola 4 |
| EC-005 | ídem (incluye `GameClock.deadline`/`is_due`) | ≈ 15–22 turnos | Must, ola 5 |

## Criterio de salida del sprint

1. Las 13 Must en `Complete` por `/story-done`, cada una verificada por el lead (§ Verificación).
2. **Suite gdUnit4 completa en verde** con el comando de CI, con las suites nuevas presentes en el informe; **0 fugas de ObjectDB, 0 huérfanos**.
3. `forbid_timers` y `check_pins` limpios.
4. **Arranque en debug limpio** (sin fatal; `DataCatalog` con las filas nuevas validando).
5. `tests/timing/` ejecutado y su resultado anotado (PASS/FAIL/NOT RUN) en el smoke de cierre; no bloquea pero no se omite.
6. CI verde en el último commit, o **NOT VERIFIED** anotado (no cuenta como verde).
7. Fechas de § Fechas rellenadas y turnos por historia anotados.

Una Should a medias no cuenta: pasa a Carryover del Sprint 3.

## Risks

No hay registro de riesgos (`production/risk-register/` no existe); se evalúan desde el contenido del sprint.

| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| **R-S2-1** | **El paralelismo por olas no está medido.** 18 historias = 1,8 × el Sprint 1; la verificación del lead es serie y puede ser el cuello de botella. | Alta | Medio | Compromiso en 13 Must; Should se aplazan primero; anotar turnos del lead por ola para medirlo. |
| **R-S2-2** | **Colisiones en ficheros no declarados** (`data_catalog.gd`, `notice_ids.gd`, `service_context.gd`, helpers de test) entre agentes de la misma ola. | Media | Alto (conflictos de merge, regresiones cruzadas) | Un titular por fichero y ola (§ Regla de olas); `/story-readiness` confirma la lista de ficheros antes de lanzar; si un agente necesita un fichero no declarado, para y lo dice; helpers solo entre olas. |
| R-S2-3 | `GameClock` sin `deadline`/`is_due`/`schedule`/`cancel`: EC-005 añade solo los plazos; `schedule`/`cancel` (puzles, director) siguen pendientes. | Cierta | Bajo aquí, medio en Sprint 3 | EC-005 deja los plazos; anotar en Sprint 3 quién implementa `schedule`/`cancel` (director-escenas 002 o puzles 005). |
| R-S2-4 | IP-003 usa `intersect_ray` con Jolt (4.6+ por defecto) en headless: riesgo de motor HIGH. | Media | Medio | Contrastar con `docs/engine-reference/godot/`; puerto `OcclusionProbe` con doble en unitarios y una sola prueba física aislada. |
| R-S2-5 | Fugas/huérfanos por agentes en paralelo (el Sprint 1 tuvo 3 incidencias en serie). | Media | Medio | Suite completa tras cada historia y otra tras cada ola. |
| R-S2-6 | Test frágil por carga empeora con agentes concurrentes ejecutando suites. | Alta si no se aísla | Medio | D-1 en ola 0, antes de nada; nunca dos suites completas a la vez en la misma máquina. |
| **R-S2-7** | **La ruta crítica se corta en el Sprint 3 por Integration**: CP-004..010 (Logic) dependen de CP-001 (Integration); IP-006..011 (Logic) de IP-005 (Integration). Sin esas dos, no hay más lógica implementable en carga ni en interacción. | Cierta | Alto para el plazo de M1 | Sprint 3 empieza por CP-001 e IP-005 (ver abajo). Decisión del usuario U-4. |

## Decisiones del usuario (no las toma este plan)

| ID | Decisión | Cuándo |
|---|---|---|
| U-1 | Replanificar M1 con la velocidad medida (orden de recorte del hito) | Sin cambios; al cerrar este sprint con fechas reales |
| U-3 | Las 6 decisiones de diseño de `design/gdd/gdd-cross-review-2026-11-10-r2.md` | Antes de pistas, subtítulos, ajustes y prompt |
| **U-4** | ¿CP-001 (`Shell`/`WorldSlot`) e IP-005 (`InteractionSystem` en planta) pueden cerrarse con **test de integración headless** sin sesión manual? Si sí, entran al principio del Sprint 3 y desbloquean 13 historias Logic. | Antes de planificar el Sprint 3 |

## Para el Sprint 3 (Visual / UI / Integration con captura o sesión manual), en orden de ruta crítica

- **Desbloqueadores Integration:** CP-001 Shell/WorldSlot, IP-005 InteractionSystem en planta, CP-011 ZoneHub, CP-012 GameSceneRoot, EB-014 composición en `Boot`, PJ-012 física headless.
- **Integration con escena o sesión manual:** CP-013 `planta.tscn` gris, EB-015 test de estado M1, EC-014 pausa, EC-015 Boot + sesión teclado/mando, IP-013 recorrido M1, AC-004 puerta en escena.
- **UI / Visual:** CP-014 `ErrorPanel` (UI), CP-015 partida nueva hasta la planta (Visual), PJ-013 recorrido gris 30/60/144 fps (Visual).
- **Lógica que queda en cola** (ya implementable al cerrar este sprint, no cabía en 18): EB-012 `write_silent`, EB-013 `dev_force`, EC-006..013, PJ-005..011, IP-004, CD-004..008, CD-010, CD-012, AC-001..003, DB-001..002. Tras CP-001/IP-005: CP-004..010, IP-006..011.

## Dependencies on External Factors

- Ninguna externa. Internas: CI de GitHub Actions y addon gdUnit4.

## QA

No hay QA plan para el Sprint 2 (`production/qa/qa-plan-*.md` solo tiene el del Sprint 1).
**Decisión autonomous (opción A, recomendada):** ejecutar `/qa-plan sprint` antes de la ola 1; puede
hacerse en paralelo con la ola 0 porque no comparte ficheros.

## Definition of Done for this Sprint

- [ ] Ola 0 cerrada (D-1 aislado y anotado, D-2 smoke en `production/qa/smoke-2026-11-11.md`)
- [ ] Las 13 Must completas (`/story-done`) con verificación del lead
- [ ] Todas pasan sus criterios de aceptación
- [ ] QA plan del sprint (`/qa-plan sprint`)
- [ ] Suite verde, 0 fugas ObjectDB, 0 huérfanos, `forbid_timers` y `check_pins` limpios, arranque debug limpio
- [ ] CI verde en el último commit (o NOT VERIFIED anotado)
- [ ] Smoke de cierre (`/smoke-check sprint`) con `tests/timing/` leído
- [ ] Ningún bug S1/S2 en lo entregado
- [ ] GDD actualizados si hubo desviaciones
- [ ] Fechas y turnos rellenados (§ Fechas)

## Decisiones tomadas (modo autonomous)

- **D-S2-1: 18 historias, compromiso 13.** *Descartado:* comprometer 18 (1,8 × lo medido sin medir el paralelismo); *descartado:* 10 (repetir el Sprint 1 desperdicia la paralelización pedida).
- **D-S2-2: `data_catalog.gd` como fichero compartido** para toda historia que añade un fichero de datos (F-R50). *Descartado:* tratarlo como libre; dos agentes añadiendo filas al mismo `registry()`/`_schema_for` es la colisión más probable del sprint.
- **D-S2-3: estado hasta EB-011 y no EB-012/013.** Escritura, sentido único, derivados y partida nueva los necesitan acceso, bolsillo y carga; `write_silent` y `dev_force` no bloquean ninguna historia del Sprint 3 temprano. *Descartado:* EB-012 en lugar de PJ-004 (deja el jugador sin mirada).
- **D-S2-4: interacción hasta IP-003, no IP-004.** IP-004 sería la 19.ª y necesita IP-002 e IP-003 (sexta ola de 1). Primera de la cola del Sprint 3.
- **D-S2-5: CP-001 e IP-005 fuera** pese a desbloquear lógica: son Integration y el usuario las reservó al Sprint 3 (U-4).
- **D-S2-6: `production/sprint-status.yaml` no se escribe en esta pasada** (el encargo limita la salida a este fichero y a una línea del hito). Se genera con `/sprint-plan update` al empezar: Must → `ready-for-dev`, Should → `backlog`.

## Resultado del Sprint 2 (cierre 2026-11-12)

**Fechas:** inicio 2026-11-11, fin 2026-11-12 (≈ 2 días de calendario, una persona dirigiendo agentes). Primera medida de calendario del proyecto.

**Hecho: 18 de 18 historias Logic** (13 Must + 5 Should) y la ola 0 de deuda:
- Ola 0: test frágil aislado en `tests/timing/` (D-1) y smoke formal (D-2, `production/qa/smoke-2026-11-11.md`).
- Ola 1: EB-008, EC-001, PJ-003. Ola 2: EB-009, EC-002, IP-001. Ola 3: EB-010, EC-003, PJ-001, IP-002. Ola 4: EB-011, EC-004, CP-002, IP-003, PJ-002. Ola 5: EC-005, PJ-004, CP-003.

**Verificación final (lead):** suite bloqueante **651/651, 0 fallos, 0 huérfanos, 0 fugas ObjectDB**; `forbid_timers` y `check_pins` limpios; arranque en debug sin fatal; CI de GitHub verde en los commits completos (un run falló por un `HttpError: Not Found` de la acción, infraestructura).

| Métrica | Sprint 1 | Sprint 2 |
|---|---|---|
| Historias cerradas | 10 | 18 |
| Turnos de agente por historia (mediana, declarados) | ≈ 12 | ≈ 12 (6 a 27) |
| Tests nuevos | 290 total | +361 (651 total) |
| Reanudaciones por límite de turnos | 6 | ≈ 9 |

**Velocidad:** ≈ 9 historias de lógica por día de calendario con olas paralelas de 3 a 5 agentes (Sprint 2), frente a ≈ 10 en una sesión sin paralelismo (Sprint 1). Fiabilidad: BAJA (dos muestras, mismo tipo de historia).

**Incidentes y lecciones del sprint**
1. **CI rojo oculto durante ≈ 1 h** (desde c762905 hasta a2c20f4): dos tests de spike asertaban `DisplayServer.get_name() == "headless"`. *Lección:* el CI se mira tras cada ola (ahora posible con el repo público); los tests no asertan hechos del entorno.
2. **Nombre de input de la acción** (`extra-args` frente a `arguments`) escrito de memoria por un agente: se verificó contra el `action.yml` real.
3. **Ciclo RefCounted→lambda→RefCounted** en un test (12 instancias filtradas): atribuido por carpeta y por fichero.
4. **Ficheros compartidos:** una vez un `git add` mío capturó una fila a medias de otra historia (sin daño).
5. Las olas de 4 a 5 agentes funcionaron con ficheros disjuntos declarados; los agentes sin turnos suficientes son lo que alarga las olas, no las colisiones.

**Deuda y pendiente de decisión**
- Enmiendas a ADR acumuladas con `TODO(...)`: ADR-0001 (2.º desbordamiento solo registra; `derive` como conjunción), ADR-0005 (nombres de hecho con mayúsculas; reversibilidad por tipo), ADR-0006 (firmas de `InputContexts`, `INPUT_SIGN`), ADR-0011 (API del catálogo), ADR-0012 (firmas de jugador), ADR-0003 (firmas de carga y cortina).
- Valores † de los GDD a validar en playtest.
- Smoke automático `/smoke-check sprint` no ejecutado (se hizo el manual).

**Sprint 3 (propuesta):** Integration y Visual/UI que necesitan sesión manual (CP-001, IP-005, cortina visual CP-014, prompt de interacción con ADR-0016, jugador con cámara) más la cola de lógica (IP-004, EB-012/013, EC-006..013, PJ-005..011, CD-004+, AC-001..003, DB-001..002).
