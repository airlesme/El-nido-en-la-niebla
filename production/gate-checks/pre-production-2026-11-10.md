# Gate Check: Technical Setup → Pre-Production

**Fecha**: 2026-11-10
**Checked by**: gate-check skill (ejecutada por el subagente `producer`, modo autonomous)
**Config resuelta** (`resolve_config`): `workflow: standard`, `review_mode: lean`, `qa.level: standard`, `team.size: individual`, `testing.strict`: sin definir (Logic e Integration estrictos por defecto), `performance.enforce: warn` (por defecto), `system_overrides`: ninguno, `project.stage: Concept`.
**Tier aplicado**: reducción `standard` de `references/gate-pre-production.md`. El art bible solo es obligatorio si hay historias de assets visuales. De los ADR solo cuentan los críticos (Foundation). UX-spec, accesibilidad, interaction-patterns y el índice de trazabilidad pasan a **recomendados**: si faltan, es CONCERNS y no bloquean.

## Veredicto: **FAIL**

Hay un bloqueante real: el framework de tests no funciona. Además quedan dos comprobaciones NOT ASSESSED: el panel de directores y la ejecución de la suite. Por precedencia (FAIL > CONCERNS > NOT ASSESSED > PASS) gana FAIL. Las dos NOT ASSESSED se listan igualmente en Bloqueantes, porque también impiden avanzar la fase.

**No se avanza la fase.** `project.yaml` (`project.stage: Concept`) y `production/stage.txt` (`Concept`) no se han tocado.

---

## Artefactos requeridos

| Artefacto | Requerido (standard) | Estado | Evidencia |
|---|---|---|---|
| Motor elegido | Sí | PASS | `CLAUDE.md` Technology Stack = Godot 4.7; `project.yaml` `engine.name: "Godot"`, `version: "4.7"` |
| Config del proyecto (engine / naming / performance) | Sí | CONCERNS | `project.yaml` tiene `engine` y `naming`, pero **no tiene bloque `performance`**. Respaldo en `.claude/docs/technical-preferences.md:41-44`: 60 fps, 16,6 ms y ~1500 draw calls, todo «provisional»; `Memory Ceiling: [TO BE CONFIGURED]`. `commands.build: "[TO BE CONFIGURED]"` |
| Art bible §1–4 | Solo si hay historias de assets visuales (aún no hay historias) | PASS (presente) | `design/art/art-bible.md`, 67,9 KB, §1–§9 presentes (líneas 12–600) |
| ≥3 ADR Foundation (escenas, eventos, save/load) | Sí (solo críticos) | PASS (existen), **ninguno Accepted** | 17 ADR. ADR-0001 eventos, 0003 escenas, 0004 save, 0002 pausa y 0009 composición. `## Status` = **Proposed** en los 17 (comprobado por grep fichero a fichero) |
| Referencia del motor | Sí | PASS | `docs/engine-reference/godot/VERSION.md` (pin 4.7.2) |
| Raíz de tests (`tests/unit/`, `tests/integration/`) | Sí | PASS | Ambos directorios existen, con `example/` |
| Workflow de CI | Sí | PASS (existe) / **nunca ejecutado** | `.github/workflows/tests.yml`. Su paso de preflight sale con `exit 1` si falta `addons/gdUnit4/bin/GdUnitCmdTool.gd`, así que hoy fallaría en cada push. El commit `33a8003` dice «workflow de CI sin ejecutar». El historial de runs es NOT ASSESSED: `gh` no está instalado en este entorno |
| Test de ejemplo que **confirme que el framework funciona** | Sí | **FAIL** | `tests/unit/example/example_smoke_test.gd` y `tests/integration/example/example_node_integration_test.gd` hacen `extends GdUnitTestSuite`, pero **`addons/` no existe** (`ls addons` → No such file or directory). Sin el addon esos ficheros ni siquiera parsean, y nunca se han ejecutado |
| `docs/architecture/architecture.md` | Sí | PASS (existe) / CONCERNS (desfasado) | Document Status dice «ADRs referenciados: Ninguno aún». La revisión de arquitectura (§ Phase 6) confirma que § ADR Audit está desfasado y que A1–A8 y H2/H3/H9/H12/H18 están sin aplicar |
| `requirements-traceability.md` | Recomendado | PASS | Existe, junto con `tr-registry.yaml` (609 TR) |
| `/architecture-review` ejecutado (modo `full`) | Sí | PASS (ejecutado) / veredicto **CONCERNS** | `architecture-review-2026-11-10.md`: `Mode: full`, `## Verdict: CONCERNS`, con 4 partidas NOT ASSESSED |
| `design/accessibility-requirements.md` con tier | Recomendado | PASS con nota | Tier **Estándar**, `Status: Committed (… confirmación del usuario pendiente, OQ 8 de 30)` |
| `design/ux/interaction-patterns.md` | Recomendado | PASS | Existe; `Status: In Design`, todos los patrones en Draft |
| `control-manifest.md` (paso `required` en `workflow-catalog.yaml`; no está en el checklist del gate) | No lo pide el gate | CONCERNS | `artifact-check.sh --phase technical-setup` → `control-manifest … status=ABSENT` |

Resultado de `artifact-check.sh --phase technical-setup`: 6 de 7 pasos PRESENT (falta `control-manifest`); `NO_CHECK: 0`.

## Quality checks

| Check | Estado | Evidencia |
|---|---|---|
| Los ADR cubren rendering, input y estado | PASS | Rendering: 0013, 0014, 0015, 0016. Input: 0006. Estado: 0002, 0003, 0004 |
| Naming y presupuestos de rendimiento definidos | CONCERNS | Naming completo. Presupuestos provisionales y sin memoria; dependen de QQ-04 (hardware de referencia) y ADR-0019 |
| Tier de accesibilidad definido | PASS | Estándar (ver arriba) |
| Al menos una UX spec de pantalla empezada | CONCERNS (recomendado) | `design/ux/` solo contiene `interaction-patterns.md`; no hay ninguna spec por pantalla |
| Todos los ADR con `## Engine Compatibility` y versión | PASS | 17/17 con la sección; los 17 sellan Godot 4.7 / 4.7.2 |
| Todos los ADR con `## GDD Requirements Addressed` | PASS | 17/17 |
| Ningún ADR usa APIs de `deprecated-apis.md` | PASS | Revisión `full`, § Engine Compatibility: 0 usos. Las 7 coincidencias citan la API sustituta |
| Dominios HIGH RISK tratados en la arquitectura | PASS | `architecture.md` § Engine Knowledge Gap Summary: Rendering, Physics/Jolt, Input, UI/AccessKit, Animation y Core/pausa en HIGH (Audio y GDScript en MED), cada uno con sus NOT SOURCEABLE y su spike |
| Cero huecos Foundation en la matriz | PASS con matiz | Revisión `full`: los 7 ❌ son de Tooling y Localization; Foundation y Core sin ❌. Matiz: la cobertura es 🟡 (ADR Proposed). Hay 0/609 TR ✅ |
| Ciclos de dependencias entre ADR | PASS | `adr-dep-graph.sh`: sin líneas `CYCLE:`, `NO_DEPS_SECTION` vacío, sin `UNFILLED_DEPS`. `ADRS: 18` incluye `adr-reconciliation-2026-11-10.md`, que no tiene aristas |
| ADR post-corte marcados con Knowledge Risk | PASS | 17/17 declaran riesgo: HIGH ×12, MEDIUM ×3, LOW ×2 |
| Engine audit sin APIs obsoletas | PASS en APIs obsoletas / NOT ASSESSED en el resto | 236 marcas `NOT SOURCEABLE` sin verificar fuera de la pausa, y `godot-specialist` no consultado (revisión § Engine Compatibility) |
| Todos los ADR con la misma versión de motor | PASS | Todos en 4.7. ADR-0008 menciona 4.5 solo como contexto de riesgo |
| Ejecución de la suite de tests | **NOT ASSESSED** | `commands.test` está configurado, pero el runner no puede arrancar: falta `res://addons/gdUnit4/bin/GdUnitCmdTool.gd` y `godot` no está en el PATH de este entorno. El editor 4.7.2 local está fuera del repo; el spike usó `Godot_v4.7.2-stable_win64_console.exe` |
| Rendimiento frente a presupuesto | NOT ASSESSED (no bloquea, `enforce: warn`) | No existe `tests/performance/` ni ninguna salida de `/perf-profile` |

## Contexto upstream

- **Spike de pausa** (`prototypes/pause-spike/results-2026-11-10.md`): S1–S3, S5–S16 y SB1–SB3 en PASS en 4.7.2. **S4 = `NEEDS_WINDOWED`**: falta la prueba manual de foco con teclado y mando, y de conectar/desconectar el mando durante la pausa. S7, S8, S11 y SB3 piden además revisión a ojo u oído. Es el único spike ejecutado.
- **`gdd-cross-review-2026-11-10-r2.md`**: CONCERNS, 0 bloqueantes, `Focus: since-last-review`.
- **`design/gdd/systems-index.md`**: `Status: Draft`, «Design docs approved: 0», MVP 23/23 y VS 7/7 diseñados.
- **`docs/consistency-failures.md`**: no existe, así que no hay patrones previos de Architecture ni Engine.
- **Estado de fase incoherente**: `project.stage` y `stage.txt` dicen `Concept`, y `production/gate-checks/` no existía. Los gates Concept → SD y SD → TS nunca se registraron.

## Director Panel Assessment

Panel esperado a `workflow: standard`: 2 de 4 (`technical-director`, `producer`).

```
Technical Director (TD-PHASE-GATE): NOT ASSESSED — no ejecutado
Producer           (PR-PHASE-GATE): NOT ASSESSED — no ejecutado
```

**No consta como «skipped — lean mode».** `references/4-assessment.md` §4b dice que en `lean` el panel de fase **sí** se ejecuta («phase gates always run in lean mode»). La skill no permite saltarlo en lean. No se ejecutó porque este subagente no tiene la herramienta `Agent` y no pudo lanzar directores independientes. Según `5-verdict.md`, un director que el tier exigía y que no volvió es NOT ASSESSED, nunca APPROVE ni READY.
Panel: 2 de 4 (`workflow: standard`, origen `modes.rigor: standard`). Las perspectivas Creative y Art no se consultan a este tier. Para el panel completo hay que subir `modes.rigor` a `full`.

---

## BLOQUEANTES

1. **[FAIL] Framework de tests no funcional.** gdUnit4 no está instalado (`addons/` no existe) y los tests de ejemplo nunca se han ejecutado.
   **Cierre:** el usuario (o `/test-setup` con el especialista `godot-gdscript-specialist`) instala gdUnit4, en una versión compatible con 4.7.2, en `addons/gdUnit4/` (con U mayúscula) siguiendo `tests/README.md` § «Installing GdUnit4».
   - Luego hay que fijar la ruta local del editor: `/settings --local commands.test="<ruta>\Godot_v4.7.2-stable_win64_console.exe --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode"`.
   - Ejecutarlo hasta que salga verde, conservar el log, hacer commit del addon y push.
   - Comprobar en GitHub Actions que el job `Run GdUnit4 Tests` sale verde. Así se cierra también «CI nunca ejecutado».
2. **[NOT ASSESSED] Ejecución de la suite de tests.** Se cierra con el bloqueante 1: es la misma ejecución, que deja evidencia del runner arrancando y de 0 fallos.
3. **[NOT ASSESSED] Panel de directores (TD-PHASE-GATE + PR-PHASE-GATE) no ejecutado.**
   **Cierre:** volver a ejecutar `/gate-check pre-production` desde la sesión principal, que sí tiene `Agent`. Alternativa: que el usuario decida explícitamente `--review solo`, lo que deja constancia de que el veredicto se basa solo en artefactos.

## CONCERNS (no bloquean a `standard`; el usuario puede aceptarlas para avanzar)

1. **17/17 ADR en `Proposed`, 0/609 TR ✅.** Foundation (0001, 0002, 0009) sin aceptar. El gate Pre-Production → Production lo bloqueará, y las historias que citen un ADR Proposed quedan auto-bloqueadas.
   **Acción:** registrar el log manual de S4 y revisar S8/S11 → aceptar ADR-0002. Hacer V-ENG-1…6 y decidir C1 → aceptar ADR-0001. Después aceptar ADR-0009. Cada aceptación la confirma el usuario.
2. **Auditoría de motor parcial**: 236 `NOT SOURCEABLE` y `godot-specialist` no consultado. **Acción:** lanzar `godot-specialist` sobre 0002, 0006, 0007, 0011, 0012, 0014 y 0015, y ejecutar los spikes de la tabla de la revisión.
3. **`architecture.md` desfasado** (ADR Audit, A1–A8, H2/H3/H9/H12/H18). **Acción:** `/create-architecture`, en modo actualización, y que remita a `requirements-traceability.md`.
4. **Presupuestos de rendimiento provisionales**, sin memoria y fuera de `project.yaml`. **Acción:** el usuario decide QQ-04 (hardware de referencia) → ADR-0019 → `/settings performance.*`.
5. **Falta ADR-0018** (Build, export, CI y tooling dev-only). Cierra 5 ❌ y la prohibición de `create_timer`. **Acción:** `/architecture-decision` ADR-0018.
6. **Contratos de integración C1–C9 abiertos** entre ADR (revisión § Cross-ADR Conflicts). Se cierran con enmiendas antes de aceptar cada ADR destino.
7. **`control-manifest.md` ausente.** **Acción:** `/create-control-manifest` cuando estén aceptados los ADR Foundation.
8. **No hay ninguna UX spec de pantalla.** **Acción:** `/ux-design` del menú de pausa o de la pantalla de título.
9. **Tier de accesibilidad sin confirmar por el usuario** (OQ 8 de 30).
10. **Incoherencia de fase**: el repo está en `Concept` sin gates previos registrados. Si este gate llegara a PASS, `set-stage.sh` saltaría de Concept a Pre-Production. El usuario debe decidir si registra los gates SD y TS o acepta el salto.
11. **`commands.build` sin configurar** y **`godot` fuera del PATH** local: `commands.smoke` y `commands.run` tampoco funcionan en esta máquina.
12. **Limpieza**: hay un directorio `docs/architecture/production/session-logs/` sin rastrear (session logs fuera de sitio) y `.godot/global_script_class_cache.cfg` está modificado.

## Plan mínimo y ordenado hasta PASS

1. **Instalar gdUnit4** en `addons/gdUnit4/` y fijar `commands.test` local a la consola 4.7.2. Ejecutar los dos tests de ejemplo hasta que salgan verdes y guardar el log. Commit y push, y confirmar el job verde en GitHub Actions. Cierra los bloqueantes 1 y 2.
2. **Volver a ejecutar `/gate-check pre-production`** desde la sesión principal con el panel TD + PR (lean). Cierra el bloqueante 3. El resultado esperado es **CONCERNS**.
3. **Con CONCERNS hay dos caminos.**
   - (a) El usuario acepta explícitamente las CONCERNS 1–12; quedan registradas en «Accepted Risks» y la fase avanza.
   - (b) Para llegar a PASS limpio, cerrar antes lo mínimo: registrar el log S4 y aceptar 0002, 0001 y 0009 (CONCERN 1); actualizar `architecture.md` (3); escribir ADR-0018 (5); y hacer una UX spec de una pantalla (8).

## Chain-of-Verification

5 preguntas comprobadas; el veredicto no cambia (FAIL).

1. ¿Separé bien bloqueantes de recomendaciones? Sí. El único FAIL es un ítem *requerido* sin reducción a `standard` («framework functional»). ADR Proposed, UX y accesibilidad quedan como CONCERNS porque el gate no exige `Accepted` y el tier los deja en recomendados.
2. ¿Fui indulgente con algún PASS? [TOOL ACTION] Volví a comprobar `ls addons` (ausente) y el preflight de `tests.yml` (`exit 1` sin el addon). El ítem «CI existe» es PASS solo como existencia; que se haya ejecutado se declara aparte.
3. ¿Faltan bloqueantes? [TOOL ACTION] El grep de `## Status` en los 17 ADR da Proposed en todos. `adr-dep-graph.sh` no muestra ningún `CYCLE:`. No aparecen bloqueantes nuevos.
4. ¿Camino mínimo a PASS? Sí: los pasos 1–3 del plan.
5. ¿Es resoluble o es un problema de fondo? Es resoluble: es setup de herramientas (addon, ruta del editor y CI), no un problema de arquitectura.

## Accepted Risks

Ninguno. El veredicto es FAIL, así que la fase no avanza.
