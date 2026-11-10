# Gate Check: Technical Setup → Pre-Production (segunda ejecución, r2)

**Fecha**: 2026-11-10 (r2, después de cerrar el bloqueante de tests de `pre-production-2026-11-10.md`)
**Checked by**: gate-check skill, ejecutada por el subagente `producer` en modo autonomous
**Config resuelta**: `workflow: standard` (vía `modes.rigor: standard`), `review_mode: lean`, `qa.level: standard`, `team.size: individual`. `testing.strict` no está definido, así que Logic e Integration son BLOCKING por defecto. `performance.enforce: warn` (por defecto). `system_overrides`: ninguno. `project.stage: Concept`.
**Tier aplicado**: reducción `standard` de `references/gate-pre-production.md`.
- Art bible: solo si hay historias de assets visuales.
- ADR: solo los críticos (Foundation).
- UX-spec, accesibilidad, interaction-patterns e índice de trazabilidad: **recomendados**.
- Hay artefactos requeridos tras la reducción, así que no aplica el NOT ASSESSED por gate vacío (`2b-workflow-tier.md`).

**Panel de directores**: no se ha relanzado. Se integran tal cual los veredictos que ya se emitieron: `pre-production-2026-11-10-td.md` (TD-PHASE-GATE: **CONCERNS**) y `pre-production-2026-11-10-pr.md` (PR-PHASE-GATE: **CONCERNS**). A `workflow: standard` el panel lo forman 2 de 4 directores (TD + PR), y los dos volvieron con veredicto. No falta ningún director que el tier exigiera.

## Veredicto: **CONCERNS**

El único FAIL de la r1, el framework de tests no funcional, está **cerrado con evidencia**. También se cierran el NOT ASSESSED de la ejecución de la suite y el del panel de directores.

Lo que queda:
- Las CONCERNS de los artefactos.
- Las de los dos directores. Gana la más estricta, y ambos dicen CONCERNS.
- Una comprobación **NOT ASSESSED**: la ejecución de la CI en GitHub.

Por precedencia (FAIL > CONCERNS > NOT ASSESSED > PASS) gana **CONCERNS**. Como pide `5-verdict.md`, el NOT ASSESSED se lista igualmente en Bloqueantes.

**No se avanza la fase.** Con CONCERNS, la fase solo avanza si el usuario las acepta de forma explícita (Sección 6). Además, el NOT ASSESSED de la CI frena el avance mientras siga abierto. `project.yaml` (`project.stage: Concept`) y `production/stage.txt` (`Concept`) no se han tocado.

---

## Qué ha cambiado desde la r1 (comprobado en esta ejecución, no supuesto)

| Hecho | Comprobación | Resultado |
|---|---|---|
| (1) gdUnit4 instalado | `addons/gdUnit4/plugin.cfg` leído: `version="6.2.3"`. `addons/gdUnit4/bin/GdUnitCmdTool.gd` existe. `.gitignore:46` des-ignora `addons/gdUnit4/bin/` | **Cerrado**. El git status del inicio de sesión no lista `addons/` como sin rastrear, y el commit `1bbcc8e` lo instala, así que el addon está versionado. Que se haya hecho push no se ha comprobado: esta ejecución no usa git ni red |
| (2) Suite ejecutada | `Godot_v4.7.2-stable_win64_console.exe --path C:/dev/personal/el-nido --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode` | **Cerrado**. Ver el resumen debajo. Código de salida **0** |
| (3) CI en GitHub | `.github/workflows/tests.yml` existe. El preflight ya encontraría `GdUnitCmdTool.gd`. Usa `gdUnit4-action@v1` con `godot-version: '4.7.2'` y `version: 'installed'` | **NOT ASSESSED**. Nunca se ha ejecutado en GitHub: no hay `gh` ni red de confianza. Que el preflight ya no saldría con `exit 1` es una inferencia leyendo el fichero, no un run |
| (4) Fase | `project.yaml:11` `stage: Concept`; `production/stage.txt` = `Concept` | Sin cambios, como corresponde a CONCERNS |

**Resumen real del runner** (salida de consola, sin los códigos ANSI):

```
Godot Engine v4.7.2.stable.official.ed1daf0bf
ERROR: The remote port number must be between 1 and 65535 (inclusive).     <- ruido esperado
ERROR: Remote Debugger: Unable to connect to host '127.0.0.1:0'.          <- ruido esperado
Scanning for test suites in: res://tests
Run Test Suite: res://tests/integration/example/example_node_integration_test.gd
  test_add_child_registers_child_under_parent PASSED 9ms
Statistics: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 31ms
Run Test Suite: res://tests/unit/example/example_smoke_test.gd
  test_clamp_percent_above_range_returns_100 PASSED 11ms
  test_clamp_percent_in_range_returns_same_value PASSED 11ms
Statistics: 2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 54ms
Overall Summary: 3 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |
Executed test suites: (2/2)
EXIT=0
```

El informe HTML de gdUnit4 quedó en `reports/report_2/`. Ese directorio está ignorado (`.gitignore:176` `/reports/`), así que el registro que se conserva es el bloque de arriba.

---

## Artefactos requeridos (re-evaluados)

| Artefacto | Requerido (standard) | Estado r2 | Evidencia |
|---|---|---|---|
| Motor elegido | Sí | PASS | `CLAUDE.md` = Godot 4.7; `project.yaml` `engine.name: "Godot"` |
| Config del proyecto (engine / naming / performance) | Sí | CONCERNS (sin cambios) | `project.yaml` sigue **sin bloque `performance`**. Respaldo provisional en `technical-preferences.md` (60 fps / 16,6 ms / ~1500 draw calls, sin techo de memoria). `commands.build: "[TO BE CONFIGURED]"` (`project.yaml:61`) |
| Art bible §1–4 | Solo si hay historias de assets visuales (aún no hay historias) | PASS (presente) | `design/art/art-bible.md`; no ha cambiado desde la r1 |
| ≥3 ADR Foundation | Sí (solo críticos) | PASS (existen), **ninguno Accepted** | Se vuelve a comprobar `## Status` fichero a fichero: 0001–0017 = **Proposed** (17/17) |
| Referencia del motor | Sí | PASS | `docs/engine-reference/godot/VERSION.md` (pin 4.7.2) |
| Raíz de tests | Sí | PASS | `tests/unit/example/` y `tests/integration/example/` |
| Workflow de CI | Sí | PASS (existe) | `.github/workflows/tests.yml`. Su *ejecución* va como NOT ASSESSED en Quality checks |
| Test de ejemplo que confirme que el framework funciona | Sí | **PASS** (antes FAIL) | 2 suites y 3 casos en verde con la consola 4.7.2 local, `EXIT=0` |
| `docs/architecture/architecture.md` | Sí | PASS (existe) / CONCERNS (desfasado) | `architecture.md:13` sigue diciendo «ADRs referenciados: Ninguno aún» |
| `requirements-traceability.md` | Recomendado | PASS | Existe, con `tr-registry.yaml` (609 TR) |
| `/architecture-review` ejecutado (modo `full`) | Sí | PASS / veredicto CONCERNS | `architecture-review-2026-11-10.md`, `Mode: full`; es el más reciente y no hay otro posterior |
| `design/accessibility-requirements.md` con tier | Recomendado | PASS con nota | Tier Estándar; falta la confirmación del usuario (OQ 8) |
| `design/ux/interaction-patterns.md` | Recomendado | PASS | Existe (`In Design`) |
| `control-manifest.md` (`workflow-catalog.yaml`; el gate no lo pide) | No lo pide el gate | CONCERNS | `artifact-check.sh --phase technical-setup`: 6/7 PRESENT, `control-manifest status=ABSENT`, `NO_CHECK: 0` |

**Required (tras la reducción standard): 9/9 presentes**, y el test de ejemplo ya es funcional.

## Quality checks (re-evaluados)

| Check | Estado r2 | Evidencia |
|---|---|---|
| ADR cubren rendering, input y estado | PASS | Sin cambios: 0013–0016, 0006 y 0002–0004 |
| Naming y presupuestos de rendimiento | CONCERNS | Naming completo. Presupuestos provisionales, fuera de `project.yaml` y sin memoria (QQ-04 → ADR-0019) |
| Tier de accesibilidad definido | PASS | Estándar |
| Al menos una UX spec de pantalla empezada | CONCERNS (recomendado) | `design/ux/` solo contiene `interaction-patterns.md` |
| ADR con Engine Compatibility y versión | PASS | 17/17, en 4.7 / 4.7.2 |
| ADR con GDD Requirements Addressed | PASS | 17/17 |
| Ninguna API de `deprecated-apis.md` | PASS | Revisión `full`: 0 usos |
| Dominios HIGH RISK tratados | PASS | `architecture.md` § Engine Knowledge Gap Summary |
| Cero huecos Foundation en la matriz | PASS con matiz | Revisión `full`: los 7 ❌ son de Tooling y Localization. La cobertura Foundation es 🟡 (ADR Proposed); 0/609 TR ✅ |
| Ciclos de dependencias entre ADR | PASS | `adr-dep-graph.sh` (r2): `ADRS: 18`, sin `CYCLE:`, `NO_DEPS_SECTION` vacío, sin `UNFILLED_DEPS` |
| ADR post-corte con Knowledge Risk | PASS | 17/17 |
| Engine audit | PASS en APIs obsoletas / CONCERNS en el resto | 236 `NOT SOURCEABLE` sin verificar fuera de la pausa; `godot-specialist` no consultado |
| Misma versión de motor en todos los ADR | PASS | 4.7 |
| **Ejecución de la suite de tests (local)** | **PASS** (antes NOT ASSESSED) | 3/3 PASSED, 0 errors, 0 failures, 0 orphans, EXIT=0 |
| **Ejecución de la CI en GitHub** | **NOT ASSESSED** | Nunca ejecutada: sin `gh` ni red. La CI es la que ejecuta la suite «on every push» (coding-standards), y no hay ningún run que la demuestre |
| `commands.test` reproducible en este equipo | CONCERNS | `project.yaml:62` invoca `godot`, que no está en el PATH local. La ejecución r2 funcionó con la ruta absoluta del ejecutable. Hay que fijarlo con `/settings --local commands.test=…` o añadir el ejecutable al PATH |
| Rendimiento frente a presupuesto | NOT ASSESSED (no bloquea, `enforce: warn`) | No hay `tests/performance/` ni salida de `/perf-profile` |

## Director Panel Assessment (integrado, no relanzado)

```
Technical Director (TD-PHASE-GATE): CONCERNS  — production/gate-checks/pre-production-2026-11-10-td.md
Producer           (PR-PHASE-GATE): CONCERNS  — production/gate-checks/pre-production-2026-11-10-pr.md
```

Panel: 2 de 4 (`workflow: standard`, origen `modes.rigor: standard`). Creative y Art no se consultan a este tier.

- **TD**: su condición 1, el framework de tests, ya se cumple en local. La parte de «job de GitHub Actions en verde» sigue abierta, y aquí figura como NOT ASSESSED.
- **PR**: su calendario es NOT ASSESSED (sin fecha de demo ni velocidad). El bloat de `/scope-check` también es NOT ASSESSED, porque `production/milestones/` solo tiene `.gitkeep` y no hay baseline. Las dos son partes internas de un veredicto que en conjunto es CONCERNS, así que no hacen subir el veredicto.

---

## BLOQUEANTES

### Cerrados con evidencia en la r2
1. ~~[FAIL] Framework de tests no funcional~~ → gdUnit4 6.2.3 está en `addons/gdUnit4/` y 3/3 tests pasan en 4.7.2, con EXIT=0.
2. ~~[NOT ASSESSED] Ejecución de la suite~~ → se ejecutó; el resumen está arriba.
3. ~~[NOT ASSESSED] Panel de directores~~ → TD y PR emitieron veredicto (CONCERNS ambos).

### Siguen abiertos
1. **[NOT ASSESSED] CI nunca ejecutada en GitHub.** No se ha visto ningún run de `.github/workflows/tests.yml`.
   **Cierre (usuario):** hacer push de `main` y comprobar en la pestaña Actions que el job `Run GdUnit4 Tests` sale verde. Después, anotar el enlace o el ID del run en el siguiente gate-check o en `production/qa/`. Si falla, `/test-setup` con `godot-gdscript-specialist`.

## CONCERNS (no bloquean a `standard`; el usuario puede aceptarlas para avanzar)

Se heredan de la r1, menos las que ya se han cerrado, y se suman las de los directores.

1. **17/17 ADR en `Proposed`, 0/609 TR ✅.** Foundation (0001, 0002, 0009) sin aceptar. Toda historia que los cite queda auto-bloqueada, y el gate Pre-Production → Production lo bloqueará (TD 1).
2. **Auditoría de motor parcial**: 236 `NOT SOURCEABLE` y `godot-specialist` no consultado. Los ADR Core dependen de spikes que no se han ejecutado (TD 2). Además, S4 del spike de pausa sigue en `NEEDS_WINDOWED`.
3. **`architecture.md` desfasado** (ADR Audit, A1–A8, H2/H3/H9/H12/H18) y contratos C1–C9 abiertos (TD 5).
4. **Presupuestos de rendimiento provisionales**, sin techo de memoria y fuera de `project.yaml`. QQ-04 está sin decidir (TD 3, PR 4).
5. **Falta ADR-0018** (build, export, CI y tooling; prohibición de `create_timer`).
6. **`control-manifest.md` ausente.**
7. **No hay ninguna UX spec de pantalla.**
8. **Tier de accesibilidad sin confirmar por el usuario** (OQ 8).
9. **S0 del plan sin cerrar** (PR 1): `commands.build` está `[TO BE CONFIGURED]`, no hay export de una escena vacía en Windows y Linux, y D-16 está abierta.
10. **`commands.test` / `smoke` / `run` invocan `godot`, que no está en el PATH local.** La versión del editor local tampoco está registrada en `VERSION.md`; la consola 4.7.2 de esta máquina coincide con el pin.
11. **Equipo y fecha sin declarar** (PR: plan §7.3 y §7.5). El calendario queda NOT ASSESSED dentro del veredicto PR.
12. **Sin baseline de hito** en `production/milestones/` y cola de diseño abierta: 35 cambios a GDDs, 6 decisiones [U] e items ADR pendientes (PR 2–4).
13. **Incoherencia de fase**: el repo está en `Concept` y no hay registro de los gates SD ni TS. Un avance saltaría de Concept a Pre-Production.
14. **Limpieza**: `docs/architecture/production/` sin rastrear (session logs fuera de sitio).

## Plan ordenado mínimo hasta PASS

| # | Acción | Quién | Decisión del usuario |
|---|---|---|---|
| 1 | Hacer push de `main` y confirmar en GitHub Actions que el job de tests sale verde. Si falla: `/test-setup` | **Usuario** (push y comprobación); agente `godot-gdscript-specialist` si falla | — |
| 2 | Fijar `commands.test` local con la ruta absoluta de la consola 4.7.2 (`/settings --local`) y registrar la versión del editor local en `VERSION.md` | Usuario (o agente con su visto bueno) | — |
| 3 | **Opción rápida, avanzar con CONCERNS**: tras el paso 1, volver a ejecutar `/gate-check pre-production`. Debería salir CONCERNS sin NOT ASSESSED. Si el usuario acepta las CONCERNS 1–14, se registran en «Accepted Risks» y se avanza la fase | Producer (re-ejecución); **usuario** (aceptación) | **Sí**: aceptar CONCERNS y decidir sobre el salto Concept → Pre-Production (C13) |
| 4 | **Opción PASS limpio** (además de 1–2): registrar el log manual de S4 y revisar S7, S8, S11 y SB3, luego aceptar ADR-0002. Hacer V-ENG-1…6 y decidir C1, luego aceptar ADR-0001. Después aceptar ADR-0009 | Usuario (S4 manual, a ojo y oído); `godot-specialist` + `technical-director` | **Sí**: cada aceptación de ADR y la decisión de C1 |
| 5 | Decidir QQ-04 (hardware de referencia) → ADR-0019 → `/settings performance.*` con techo de memoria | **Usuario** (QQ-04); `technical-director` (ADR) | **Sí** |
| 6 | `/create-architecture` en modo actualización; `/architecture-decision` ADR-0018; `/ux-design` de una pantalla (pausa o título) | Agentes (`technical-director`, `ux-designer`) | No (modo por lotes) |
| 7 | Responder al plan §7.3 (equipo) y §7.5 (fecha de demo, o «sin fecha»); confirmar el tier de accesibilidad (OQ 8) | **Usuario** | **Sí** |
| 8 | Re-ejecutar `/gate-check pre-production` | Producer | — |

Lo mínimo para que el veredicto *pueda* ser PASS son los pasos 1, 4, 5 y 6. Las CONCERNS 9–14 no son condiciones del checklist del gate, pero los directores las piden. Un PASS con el panel aún en CONCERNS no es alcanzable: gana el veredicto más estricto, así que el paso 8 necesita que TD y PR se reevalúen tras los pasos 4–7. La vía realista es el paso 3.

## Chain-of-Verification

5 preguntas comprobadas; el veredicto no cambia (CONCERNS).

1. ¿Alguna CONCERN debería subir a bloqueante? No. El gate no exige ADR `Accepted` y el tier deja UX, accesibilidad y trazabilidad como recomendados. Los presupuestos son provisionales pero existen, y `enforce: warn`.
2. ¿He rebajado un FAIL a CONCERN? [TOOL ACTION] He vuelto a leer `addons/gdUnit4/plugin.cfg` (6.2.3) y a ejecutar la suite: 3/3 PASSED, EXIT=0. El antiguo FAIL está cerrado con un run real, no por razonamiento.
3. ¿Hay artefactos sin revisar que puedan revelar bloqueantes? [TOOL ACTION] He repetido el grep de `## Status` (17/17 Proposed), `adr-dep-graph.sh` (sin ciclos) y `artifact-check.sh` (6/7, falta control-manifest). No aparecen bloqueantes nuevos.
4. ¿He resuelto un NOT ASSESSED con la lectura permisiva? No. La CI se mantiene como NOT ASSESSED aunque el preflight ya pasaría al leer el YAML: leer no es ejecutar.
5. ¿Las CONCERNS juntas forman un bloqueo? Para *entrar* en Pre-Production, no (spikes y prototipos). Para el siguiente gate, sí: la acumulación 1+2+4 bloqueará Pre-Production → Production si no se trata durante esta fase.

## Accepted Risks

Ninguno todavía. El veredicto es CONCERNS con un NOT ASSESSED abierto, y el usuario no ha aceptado las CONCERNS. La fase no avanza.
