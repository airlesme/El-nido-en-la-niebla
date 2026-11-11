# Gate Check: Technical Setup → Pre-Production (tercera ejecución, r3)

**Fecha**: 2026-11-11 (r3; anteriores: `pre-production-2026-11-10.md` FAIL, `pre-production-2026-11-10-r2.md` CONCERNS)
**Checked by**: gate-check skill, ejecutada por el subagente `producer` en modo autonomous
**Config resuelta**: `workflow: standard` (vía `modes.rigor: standard`, `project.yaml:33`), `review_mode: lean`, `qa.level: standard`, `team.size: individual`. Desde el 2026-11-10 el usuario lo confirma en `PLAN-TECNICO.md` §7.3; antes solo era una inferencia de `rigor`. `testing.strict` no está definido, así que Logic e Integration son BLOCKING. `performance.enforce: warn`, ahora explícito en `project.yaml:64`. `system_overrides`: ninguno. `project.stage: Concept`.
**Tier aplicado**: reducción `standard` de `references/gate-pre-production.md`.
- Art bible: solo si hay historias de assets visuales.
- ADR: solo los críticos (Foundation).
- UX-spec, accesibilidad, interaction-patterns e índice de trazabilidad: **recomendados**.
- Quedan artefactos requeridos tras la reducción, así que no aplica el NOT ASSESSED por gate vacío (`2b-workflow-tier.md`).

**Panel de directores**: no se ha relanzado. Se integran los veredictos ya emitidos: `pre-production-2026-11-10-td.md` (TD-PHASE-GATE: **CONCERNS**) y `pre-production-2026-11-10-pr.md` (PR-PHASE-GATE: **CONCERNS**). Gana el más estricto, y los dos son CONCERNS. A `standard` el panel es de 2 de 4 y no falta ningún director. Más abajo se revisa qué condiciones de cada uno se han cumplido desde entonces.

## Veredicto: **CONCERNS**

Respecto a la r2 se cierra el último NOT ASSESSED, la CI en GitHub. Queda en una CONCERN de evidencia declarada por el usuario y no verificada (ver C-15). También se cierran 4 de las 14 CONCERNS de la r2 (C3, C4, C5 y C11) y una se cierra en parte (C9).

Siguen abiertas 10 CONCERNS heredadas y 1 nueva. El panel también sigue en CONCERNS. Ninguna condición del checklist tiene FAIL. Ningún check que el tier exija ha quedado sin ejecutar.

Por precedencia (FAIL > CONCERNS > NOT ASSESSED > PASS) el resultado es **CONCERNS**.

**Qué cambia frente a la r2:** ya no queda ningún NOT ASSESSED que frene el avance. **La fase puede avanzar si el usuario acepta de forma explícita las CONCERNS listadas** (Sección 6). Este informe **no cambia la fase**. Siguen sin tocar `project.yaml` (`project.stage: Concept`, línea 11) y `production/stage.txt` (`Concept`).

---

## Hechos nuevos (comprobados en esta ejecución, no supuestos)

| # | Hecho | Comprobación | Resultado |
|---|---|---|---|
| 1 | ADR-0018 y ADR-0019 existen | `## Status` de cada fichero | **Confirmado**. Los dos están en `Proposed` y tienen las secciones obligatorias: Engine Compatibility, ADR Dependencies y GDD Requirements Addressed. ADR-0019 fija el portátil de desarrollo como equipo de referencia (Core Ultra 7 265H, iGPU Intel, 15,4 GB, 1920×1200 a 60 Hz) y deja los presupuestos como objetivos provisionales |
| 2 | Bloque `performance:` en `project.yaml` | `project.yaml:59-64` | **Confirmado**: `target_framerate: 60`, `frame_budget_ms: 16.67`, `draw_call_limit: 1500`, `memory_ceiling_mb: 3072`, `enforce: warn`. `project.stage: Concept` no ha cambiado (línea 11) |
| 3 | `architecture.md` v2 | Grep | **Confirmado**: `| Version | 2 |` (línea 7) y «0 de 609» aparece 0 veces. ADR-0018 y ADR-0019 figuran como «escrito (Proposed)» (líneas 821-822), y QQ-04 consta como resuelta por ADR-0019 (línea 886). **Residuo menor**: la cabecera (línea 13) sigue diciendo «ADR-0001…ADR-0017» |
| 4 | Decisiones del usuario en `PLAN-TECNICO.md` §7 | Lectura de §7 (líneas 91-102) | **Confirmado**. §7.1: D-16 = cadena c1→c3→c4 con c2 libre. §7.3: una persona con agentes. §7.4: portátil de desarrollo. §7.5: sin fecha fija, por hitos con orden de recorte. La propagación de D-16 está en `design/gdd/reviews/d16-propagacion-2026-11-10.md`: 6 ficheros editados y ninguna contradicción de reglas abierta. Pendientes: una relectura parcial (regla 24, AC-03 y AC-19 de `marco-de-puzles.md`) y la D-14 de `puzle-6-decision.md` OQ 3, que es otra decisión |
| 5 | CI de GitHub en verde | Sin `gh`, sin red y sin id de run | **Evidencia declarada por el usuario (2026-11-10), no verificada por el agente.** No figura como PASS verificado ni como NOT ASSESSED. Es la resolución, por parte del usuario, de un check manual que el agente no puede hacer (`5-verdict.md`: un MANUAL CHECK sin resolver da NOT ASSESSED; este lo ha resuelto el usuario). Sí comprobado leyendo el fichero: `.github/workflows/tests.yml` fija `godot-version: '4.7.2'` y `version: 'installed'` (líneas 43-44). Se mantiene como CONCERN C-15 hasta que se registre el enlace o el id del run |
| 6 | Suite local | Ejecutada (salida abajo) | **PASS**: 3/3 casos, 0 errores, 0 fallos, 0 orphans, `EXIT=0` |
| 7 | Siguen pendientes | Grep y listados | **Confirmado**. 19/19 ADR `Proposed`, ninguno `Accepted`. Hasta ADR-0019 son 19 ADR; el script cuenta `ADRS: 20` porque incluye `adr-reconciliation-2026-11-10.md`. S4 manual sigue sin log: ADR-0002 l.943, «provisional OK… stays `Proposed` until a log… is recorded». `design/ux/` solo contiene `interaction-patterns.md`. `production/milestones/` está vacío |

**Observación sobre `commands.test`**: `project.yaml:71` invoca `godot`, que **no está en el PATH** de esta máquina. El comando del gate no se puede ejecutar tal cual aquí. Esta ejecución usó la ruta absoluta de la consola 4.7.2. La configuración local no admite claves `commands.*` (dato del orquestador, no comprobado contra el esquema), así que `/settings --local commands.test=…` no es una salida. Quedan dos opciones: añadir el ejecutable al PATH, o aceptar que en local el comando se lanza con ruta absoluta. Se mantiene como C10. `VERSION.md:6` sigue diciendo «The developer's local editor version is still not recorded», aunque la consola de esta máquina es 4.7.2.stable.official.ed1daf0bf, igual que el pin.

**Resumen real del runner** (`C:\Users\airlesme\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path C:\dev\personal\el-nido -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`, sin códigos ANSI):

```
ERROR: The remote port number must be between 1 and 65535 (inclusive).     <- ruido esperado
ERROR: Remote Debugger: Unable to connect to host '127.0.0.1:0'.          <- ruido esperado
Godot Engine v4.7.2.stable.official.ed1daf0bf
Run Test Suite: res://tests/integration/example/example_node_integration_test.gd
  test_add_child_registers_child_under_parent PASSED 75ms
Statistics: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 244ms
Run Test Suite: res://tests/unit/example/example_smoke_test.gd
  test_clamp_percent_above_range_returns_100 PASSED 87ms
  test_clamp_percent_in_range_returns_same_value PASSED 95ms
Statistics: 2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 466ms
Overall Summary: 3 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |
Executed test suites: (2/2)
Executed test cases : (3/3)
EXIT=0
```

---

## Artefactos requeridos (re-evaluados)

| Artefacto | Requerido (standard) | Estado r3 | Evidencia |
|---|---|---|---|
| Motor elegido | Sí | PASS | `CLAUDE.md` = Godot 4.7; `project.yaml` `engine.name: "Godot"` |
| Config del proyecto (engine / naming / performance) | Sí | **PASS** (antes CONCERNS) | `performance:` completo, con techo de memoria (l.59-64). Residuo en C9: `commands.build: "[TO BE CONFIGURED]"` (l.70) |
| Art bible §1–4 | Solo si hay historias de assets visuales (no hay historias) | PASS (presente) | `design/art/art-bible.md` |
| ≥3 ADR Foundation | Sí (solo críticos) | PASS (existen), **ninguno Accepted** | 0001, 0002, 0003, 0004 y 0009 entre los 19; todos `Proposed` |
| Referencia del motor | Sí | PASS | `docs/engine-reference/godot/VERSION.md` (pin 4.7.2) |
| Raíz de tests | Sí | PASS | `tests/unit/example/` y `tests/integration/example/` |
| Workflow de CI | Sí | PASS (existe) | `.github/workflows/tests.yml` |
| Test de ejemplo funcional | Sí | PASS | 3/3 en verde, `EXIT=0` (arriba) |
| `docs/architecture/architecture.md` | Sí | **PASS** (antes desfasado) | v2; cabecera con residuo menor en l.13 |
| `requirements-traceability.md` | Recomendado | PASS | Existe, con `tr-registry.yaml` |
| `/architecture-review` ejecutado (`full`) | Sí | PASS / veredicto CONCERNS | `architecture-review-2026-11-10.md`, `Mode: full`. Sigue siendo el único y el más reciente: es **anterior** a ADR-0018 y ADR-0019, que ninguna revisión ha leído (ver C2) |
| `design/accessibility-requirements.md` con tier | Recomendado | PASS con nota | Tier Estándar; «confirmación del usuario pendiente, OQ 8» (l.3) |
| `design/ux/interaction-patterns.md` | Recomendado | PASS | Existe |
| `control-manifest.md` (catálogo, no lo pide el gate) | — | CONCERNS | `artifact-check.sh --phase technical-setup`: 6/7 PRESENT, `control-manifest status=ABSENT`, `NO_CHECK: 0` |

**Required (tras la reducción standard): 9/9 presentes y con contenido real.**

## Quality checks (re-evaluados)

| Check | Estado r3 | Evidencia |
|---|---|---|
| ADR cubren rendering, input y estado | PASS | 0013–0016, 0006, 0002–0004 |
| Naming y presupuestos de rendimiento | **PASS** (antes CONCERNS) | Naming completo; presupuestos en `project.yaml`, respaldados por ADR-0019 (Proposed, provisionales) |
| Tier de accesibilidad definido | PASS | Estándar |
| Al menos una UX spec de pantalla empezada | CONCERNS (recomendado) | Solo `interaction-patterns.md` |
| ADR con Engine Compatibility y versión | PASS | 19/19 (0018 y 0019 incluidos, en la sección de cabecera l.41/l.37) |
| ADR con GDD Requirements Addressed | PASS | 19/19 |
| Ninguna API de `deprecated-apis.md` | PASS para 0001–0017 / **no auditado para 0018–0019** | La revisión `full` es anterior a ellos. Se anota en C2, sin bloqueo: los dos están en Proposed y no son Foundation |
| Dominios HIGH RISK tratados | PASS | `architecture.md` § Engine Knowledge Gap Summary |
| Cero huecos Foundation en la matriz | PASS con matiz | Los ❌ de la revisión son Tooling (→ ADR-0018, ya escrito) y Localization (ADR-0020, post-slice). Foundation en 🟡 por Proposed |
| Ciclos de dependencias entre ADR | PASS | `adr-dep-graph.sh`: `ADRS: 20`, 0 líneas `CYCLE:` y 0 `BLOCKED_BY_CYCLE`, `NO_DEPS_SECTION` vacío, sin `UNFILLED_DEPS`. `ORDER` empieza por adr-0001, adr-0019, adr-0002, adr-0009 |
| ADR post-corte con Knowledge Risk | PASS | 19/19 |
| Misma versión de motor en todos los ADR | PASS | 4.7 |
| Ejecución de la suite (local) | PASS | 3/3, `EXIT=0` |
| Ejecución de la CI en GitHub | **Declarada por el usuario, no verificada** (antes NOT ASSESSED) | Ver hecho 5 / C-15 |
| `commands.test` reproducible en este equipo | CONCERNS | `godot` fuera del PATH (observación de arriba) |
| Rendimiento frente a presupuesto | NOT ASSESSED informativo, no bloquea | No hay código de juego que perfilar ni `tests/performance/`. Con `enforce: warn`, incluso una superación medida sería un aviso. Se cierra con el primer `/perf-profile` en S0b, en el equipo de referencia de ADR-0019 |

## Director Panel Assessment (integrado, no relanzado) y estado de sus condiciones

```
Technical Director (TD-PHASE-GATE): CONCERNS  — production/gate-checks/pre-production-2026-11-10-td.md
Producer           (PR-PHASE-GATE): CONCERNS  — production/gate-checks/pre-production-2026-11-10-pr.md
```

| Condición | Estado 2026-11-11 | Evidencia |
|---|---|---|
| TD 1: framework de tests (local + Actions) | **Cumplida en local**; Actions declarado por el usuario | Suite 3/3; hecho 5 |
| TD 2: Foundation aceptada (0002 → 0001 → 0009) | **Abierta** | 0/19 Accepted; S4 sin log; V-ENG-1…6 y C1 sin cerrar |
| TD 3: QQ-04 → ADR-0019 → `performance.*` | **Cumplida** (ADR en Proposed) | ADR-0019 y `project.yaml:59-64` |
| TD 4: programa de spikes con `godot-specialist` + ADR-0018 | **En parte**: ADR-0018 escrito; spikes de 0003–0007 y 0011–0016 sin ejecutar | Solo existe `prototypes/pause-spike/` |
| TD 5: `architecture.md` actualizado + editor local en `VERSION.md` | **En parte**: v2 hecho; `VERSION.md:6` sin el editor local | Hechos 3 y observación |
| PR 1: §7.3 equipo y §7.5 fecha | **Cumplida** (individual; «sin fecha» aceptado) | `PLAN-TECNICO.md` §7 |
| PR 2: cerrar S0 | **En parte**: gdUnit4 local ✔, D-16 ✔, QQ-04 ✔, CI declarada; **export de escena vacía Windows/Linux ✗** | No existe `export_presets.cfg` (ADR-0018 l.104: además `.gitignore` l.71 lo ignora); `commands.build` sin configurar |
| PR 3: último lote de diseño y congelación | **Abierta**: ADR-0018 ✔; Foundation sin aceptar; no se ha verificado en esta ejecución si los 35 cambios y las 6 [U] están cerrados | — |
| PR 4: baseline de hito en `production/milestones/` | **Abierta** | Directorio vacío |
| PR 5: validar jugando | No aplica todavía (es criterio de S0b/M1) | — |

**Parte de calendario del PR**: deja de estar sin decidir, porque «sin fecha» es una decisión del usuario. Lo que sigue sin poder medirse es la duración, porque no hay baseline de hito ni velocidad. Un `/scope-check` daría NOT ASSESSED: el baseline no enumera ningún ítem y el estado actual no tiene código de juego. Un `/estimate` sobre M1 saldría con confianza Low. Por eso esta ejecución no publica cifras de bloat ni de días.

Los dos veredictos del panel son del 2026-11-10 y anteriores a los cierres de arriba. **No se rebajan por razonamiento.** Solo una reevaluación de TD y PR puede moverlos.

---

## BLOQUEANTES

### Cerrados con evidencia en la r3
1. ~~[NOT ASSESSED] CI nunca ejecutada en GitHub~~ → el usuario declara el job en verde (2026-11-10). Pasa a C-15 (evidencia declarada, sin id de run). Ya no frena el avance.

### Siguen abiertos
Ninguno. No hay FAIL ni NOT ASSESSED en ningún check que el tier exija. El NOT ASSESSED de rendimiento es informativo; el motivo está en la tabla de quality checks.

## CONCERNS (no bloquean a `standard`; el usuario puede aceptarlas para avanzar)

Se numeran como en la r2 para que se puedan seguir.

**Cerradas desde la r2:**
- ~~C3 `architecture.md` desfasado~~ → v2. Residuo menor: cabecera l.13.
- ~~C4 Presupuestos fuera de `project.yaml` y sin memoria~~ → bloque `performance:` con techo de 3072 MB. Siguen siendo provisionales (ADR-0019 Proposed, 60 fps en iGPU sin medir).
- ~~C5 Falta ADR-0018~~ → escrito (Proposed).
- ~~C11 Equipo y fecha sin declarar~~ → individual; sin fecha.

**Abiertas:**
1. **C1. 19/19 ADR en `Proposed`, 0 Accepted.** Foundation (0001, 0002 y 0009) sin aceptar: toda historia que cite cualquiera de ellos queda auto-bloqueada. Es el principal riesgo para el gate Pre-Production → Production (TD 2).
2. **C2. Auditoría de motor parcial.** S4 manual sin log (ADR-0002 l.943); 236 NOT SOURCEABLE; `godot-specialist` no consultado. Ninguna revisión ha leído ADR-0018 ni ADR-0019, y ADR-0018 tiene NS propios, como E4 (propiedades de `export_presets.cfg`) (TD 4).
3. **C6. `control-manifest.md` ausente.**
4. **C7. No hay ninguna UX spec de pantalla** (recomendado a `standard`).
5. **C8. Tier de accesibilidad sin confirmar por el usuario** (OQ 8).
6. **C9 (en parte). S0 sin cerrar**: falta el export de una escena vacía en Windows y Linux. No existe `export_presets.cfg`, el nombre está en `.gitignore` l.71 y `commands.build` sigue `[TO BE CONFIGURED]`. D-16 y QQ-04 ya están cerradas.
7. **C10. `commands.test`, `smoke` y `run` invocan `godot`, que no está en el PATH local**, y la config local no admite `commands.*`. `VERSION.md` no registra el editor local.
8. **C12. No hay baseline de hito** en `production/milestones/` (PR 4). El estado de la cola de diseño (35 cambios y 6 [U]) no se ha verificado en la r3.
9. **C13. Incoherencia de fase**: el repo sigue en `Concept` y no hay registro de los gates SD ni TS. Avanzar ahora salta de Concept a Pre-Production.
10. **C14. Limpieza**: `docs/architecture/production/session-logs/` sigue sin rastrear (`agent-audit.log`, `session-cost.md`, `session-log.md`).
11. **C15 (nueva). Evidencia de CI solo declarada.** El job verde lo afirma el usuario; no hay enlace ni id de run, y el agente no tiene acceso a `gh`.

## Plan mínimo hasta PASS

| # | Acción | Quién | ¿Decisión exclusiva del usuario? |
|---|---|---|---|
| 1 | Ejecutar el arnés `s4_manual.tscn` en ventana y anotar en ADR-0002 § Spike Results una línea PASS/FAIL para los puntos 3, 4 y 5 del README | **Usuario**: solo él puede operar el teclado y el mando en ventana | Sí (aporta la evidencia) |
| 2 | Aceptar ADR-0002. Cerrar V-ENG-1…6 y C1, y aceptar ADR-0001. Después aceptar ADR-0009 | `godot-specialist` + `technical-director` preparan; **usuario** acepta | **Sí**: cada aceptación de ADR y la decisión de C1 |
| 3 | Anotar el enlace o el id del run verde de Actions en `production/qa/` | **Usuario** | — |
| 4 | Export de una escena vacía en Windows y Linux según ADR-0018 D1/D5 (presets, des-ignorar `export_presets.cfg`, `commands.build`) | `godot-specialist` / `devops` | No |
| 5 | `/ux-design` de una pantalla (pausa o título); `/create-control-manifest` cuando haya ADR Accepted | `ux-designer`; `technical-director` | No |
| 6 | Confirmar el tier Estándar (OQ 8) | **Usuario** | **Sí** |
| 7 | Baseline de hito S0b + M1 en `production/milestones/`, con timebox y orden de recorte | Producer redacta; **usuario** pacta el orden de recorte | **Sí** (orden de recorte) |
| 8 | Registrar el editor local en `VERSION.md`; poner `godot` en el PATH o documentar la ruta absoluta | Usuario o agente con su visto bueno | — |
| 9 | Reevaluar TD y PR y volver a ejecutar `/gate-check pre-production` | Producer (orquesta), `technical-director` | — |

Un PASS exige como mínimo los pasos 1, 2 y 9: el panel tiene que salir de CONCERNS, y TD 2 solo se cumple con Foundation aceptada. Para un PASS sin CONCERNS recomendadas hacen falta además los pasos 3–7.

**Vía realista: aceptar las CONCERNS ahora.** Ya no queda ningún NOT ASSESSED que lo impida. Pre-Production es precisamente la fase en la que se cierran los pasos 1, 2, 4 y 7 (spikes, primera exportación y S0b), así que esta vía no hace trampa. Sí deja como deuda explícita, ante el gate Pre-Production → Production, la acumulación de C1, C2 y C9.

## Decisiones exclusivas del usuario

1. **Aceptar las CONCERNS C1, C2, C6–C10 y C12–C15 y avanzar la fase**, incluido el salto de `Concept` a `Pre-Production` (C13). Si acepta, se registran abajo en «Accepted Risks» con la fecha. Si no, la fase sigue en `Concept`.
2. Aceptar cada ADR Foundation (0002, 0001 y 0009) y decidir C1.
3. Aportar el log de S4 manual y la referencia del run de CI.
4. Confirmar el tier de accesibilidad (OQ 8).
5. Pactar el orden de recorte del baseline de M1.

## Chain-of-Verification

5 preguntas comprobadas; el veredicto no cambia (CONCERNS).

1. ¿Alguna CONCERN debería subir a bloqueante? No. El checklist no exige ADR `Accepted` y el tier deja la UX spec y la accesibilidad como recomendadas. El export de Windows/Linux es un criterio de S0 del plan, no del gate.
2. ¿He rebajado un FAIL a CONCERN, o un NOT ASSESSED a algo más permisivo? [TOOL ACTION] He vuelto a ejecutar la suite: 3/3, `EXIT=0`. La CI no se marca como PASS: queda como evidencia declarada y abierta en C15. Lo que la saca de NOT ASSESSED es que el usuario ha resuelto un check manual; no es una inferencia mía sobre el YAML.
3. ¿Hay artefactos sin revisar que puedan revelar bloqueantes? [TOOL ACTION] He repetido `adr-dep-graph.sh` (0 `CYCLE:`, ahora con 0018 y 0019), `artifact-check.sh` (6/7) y el grep de `## Status` (19/19 Proposed). Lo nuevo encontrado (0018 y 0019 sin auditar, `export_presets.cfg` ignorado en `.gitignore`) se ha añadido a C2 y C9. No hay bloqueante nuevo.
4. ¿Las CONCERNS juntas forman un bloqueo? Para entrar en Pre-Production, no. Para el gate siguiente, sí: C1, C2 y C9 bloquearán Pre-Production → Production si no se tratan durante esta fase.
5. ¿Doy algo por cerrado solo porque me lo han dicho? [TOOL ACTION] Lo he comprobado en los ficheros: `PLAN-TECNICO.md` §7, `project.yaml:59-64`, `architecture.md:7` y el informe de D-16. La única afirmación no verificable, el run de CI, va marcada como declarada.

## Accepted Risks

Ninguno todavía. El usuario no ha aceptado las CONCERNS de este informe y la fase sigue en `Concept`.
