# Sprint 3: Primer recorrido jugable (inicio 2026-11-12)

> **Hito**: M1 · Prototipo gris (escenas 1–3), `production/milestones/m1-gray-prototype.md`
> **Generado**: 2026-11-12 por `/sprint-plan new` (producer, `automation: autonomous`;
> `modes.rigor: standard` → `review_mode: lean`, `story_granularity: balanced`)
> **PR-SPRINT**: omitido (modo lean, no es PHASE-GATE).
> **Decisión del usuario (2026-11-12)**: Sprint 3 = lógica restante + historias que piden su sesión manual.
> **QA plan**: no existe para este sprint (ver § QA).

## Fechas (se registran, no se estiman)

| Campo | Valor |
|---|---|
| Inicio | **2026-11-12** |
| Fin | **2026-11-12** (cierre técnico; la sesión manual con mando sigue abierta) |
| Sesiones de trabajo usadas | 1 (continua, con 8 olas) |
| Turnos de agente totales | no contabilizados al detalle; ≈10–20 por historia, con 5 reanudaciones por límite de turnos |
| Fin de cada ola | todas el 2026-11-12 (O1–O8) |
| Sesión del usuario | 2026-11-12, parcial: teclado+ratón sí (encontró el bug del avance en diagonal); mando pendiente |

## Sprint Goal

**El primer recorrido jugable:** el usuario arranca el juego (escena principal), `Boot` compone los
servicios y carga la planta gris (despacho, pasillo y Archivo, sin texturas) con el telón, y camina en
primera persona con teclado+ratón y con mando, con cámara y mirada, colisiones contra muros y sensor de
zona; todo con suite verde, 0 fugas, CI verde y capturas del propio motor.

**No promete el prompt de interacción** (ver § Goal Prerequisites, fila 7).

## Goal Prerequisites

| Necesario para mostrar el objetivo | Estado |
|---|---|
| 1. Escena principal en `project.godot` (`run/main_scene`) | **exists** (`res://src/core/boot/main.tscn`); CP-001 la cambia a `shell.tscn` (ver R-S3-6) |
| 2. Composición de servicios en el arranque (`Boot.compose`) | exists (esqueleto S0) |
| 3. Catálogo de hechos cargado al arrancar (sin él el canal de avisos es `null` y la carga no avisa) | **built by EB-014** |
| 4. Tabla de bindings cargada en `InputRouter.setup` (hoy `TODO(ADR-0006)` en `src/input/input_router.gd` l. 37) | **built by EC-015** (paso 1, ver D-S3-3) |
| 5. `get_move_vector()`/`consume_look_delta()` de Entrada (puerto del Jugador) | **built by EC-008** |
| 6. `Shell`, `WorldSlot`, telón; `SceneLoader` real; `SceneSource`; `planta.tscn` gris con `Player` y `ZoneHub`; petición `request_load(PLANTA, PARTIDA_NUEVA)` desde el arranque | built by CP-001, CP-004…009, CP-012, CP-011, CP-013, PJ-011, CP-015 |
| 7. **Prompt de interacción básico** (ADR-0016, ya Accepted) | **missing**: no hay ninguna historia del prompt (24). `production/epics/interaccion-y-prompt/stories.md` § Diferido la dejó sin escribir porque ADR-0016 era Proposed. IP-004/005 no dibujan nada |
| 8. Captura del mouse en ventana (`mouse_mode`) para mirar con ratón | **missing como historia identificable**: ninguna historia elegida lo nombra; ver R-S3-8 |
| 9. `ContentDB` real (`ctx.content`, que el `Player` pide por `ctx.require`) | exists solo como esqueleto (`src/narrative/content_db.gd`, `setup` TODO); CD-004 no entra. Ver R-S3-9 |

**Prerrequisitos que faltan y sus tres salidas (no se resuelven en este plan):**
- **Prompt (fila 7):** (a) escribir sus historias con `/create-stories interaccion-y-prompt` (ahora que ADR-0016 está Accepted) y meter la mínima con `/sprint-plan update`, lo que pasa de 22 y exige además IP-004 e IP-005 (+3 como mínimo); (b) idem en el Sprint 4 (**recomendado**); (c) el objetivo ya está reformulado para no prometerlo.
- **Captura del ratón (fila 8):** (a) `/story-readiness` de EC-015 y PJ-011 confirma si una de las dos ya la incluye; (b) si ninguna, `/create-stories` de una historia corta antes de la ola 3; (c) la sesión del usuario mide la mirada con mando y anota la de ratón como NOT ASSESSED.

## Capacity

- **Unidad: historias cerradas y verificadas por el lead.** No días-persona.
- Medido: Sprint 1 = 10 historias (una sesión, sin paralelismo); Sprint 2 = 18 historias Logic en ≈ 2 días de calendario con olas de 3–5 agentes; mediana ≈ 12 turnos por historia (6 a 27).
- Este sprint: **22 historias** (máximo pedido), ≈ 264 turnos a la mediana. **No son comparables con el Sprint 2:** 6 Integration, 1 UI, 1 Visual y la primera vez con nodos reales, Jolt real y ventana. Estimación de calendario: optimista 2 días, esperado **3–4 días**, pesimista 6 (confianza **BAJA**: la mediana de 12 turnos se midió solo con historias Logic).
- **La profundidad la fija `scene_loader.gd`**: 6 historias (CP-004, 005, 007, 008, 009, 006) lo tocan en serie, así que hay 8 olas y las 4 últimas son de 1–3 historias (ver D-S3-4).
- **Compromiso (Must): 22.** Todas están en la ruta crítica del objetivo; no hay Should de relleno. El 20 % de margen son turnos del lead (verificación, CI tras cada ola, una corrección por ola). Si no cabe, se aplica § Recortes en su orden.

Prefijos: **EB** estado-y-bus · **EC** entrada-y-controles · **PJ** jugador-primera-persona · **CP** carga-de-planta.

## Regla de olas

1. Una ola = historias **sin dependencia entre sí** y con **ficheros de código disjuntos**; un agente por historia (`/dev-story`), en paralelo.
2. Ficheros con un solo titular por ola: `service_context.gd`, `boot.gd`, `game_state.gd`, `game_clock.gd`, `notice_channel.gd`, `notice_ids.gd`, `data_catalog.gd`, `input_router.gd`, `scene_loader.gd`, `project.godot`.
3. Titulares posibles de `service_context.gd` (TODO `ui`, `scene`, `files`): CP-001 (O1), EB-014 (O2), CP-012 (O4). Si `/story-readiness` muestra otro, baja de ola.
4. Helpers de test compartidos (`tests/doubles/*`, `TestContexts`): solo el lead, **entre olas**.
5. Ninguna ola empieza hasta que la anterior esté cerrada y verificada (o una historia bajada explícitamente) **y el CI de su último commit esté verde en GitHub**.
6. Nunca dos suites completas a la vez en la misma máquina (R-S2-6); las pruebas con ventana (`--write-movie`), tampoco en paralelo.

## Verificación independiente del lead

**Tras CADA historia** (el agente que implementa no la cierra):
1. relee los CA y comprueba que cada uno tiene su aserto o su evidencia retenida;
2. ejecuta la **suite completa** con el comando de CI y lee el informe (suite nueva presente, nº de tests > 0);
3. **0 fugas ObjectDB, 0 huérfanos**; `forbid_timers` y `check_pins` limpios;
4. **arranque en debug** sin fatal; desde O3, además, arranque **con ventana** y comprobación de que no hay errores en consola (C-M1-9);
5. para Integration/UI/Visual: la evidencia está en disco (`tests/integration/...` o `production/qa/evidence/...`); una captura de escritorio **no cuenta**;
6. solo entonces `/story-done` y un commit por historia (Conventional Commits, `Story: XX-NNN`).

**Tras CADA ola:** suite completa con las historias juntas + **comprobación del CI en GitHub** del último commit de la ola (`gh run list`/`gh run view`), anotando run y resultado. Rojo o «no ejecutado» bloquea la ola siguiente; un fallo de infraestructura se anota como NOT VERIFIED y se relanza, no se da por verde.

## Tasks

Todas `Ready`; ADR que rigen, todos **Accepted** (0001, 0002, 0003, 0005, 0006, 0009, 0011, 0012). Las menciones a ADR Proposed (0007, 0008, 0013) son exclusiones ya diferidas en cada story file.

### Must Have (ruta crítica): 22 historias

| ID | Historia | Tipo | Ola | Ficheros previstos (código/escena) | ADR | Evidencia | Depende de | Sesión manual |
|---|---|---|---|---|---|---|---|---|
| CP-001 | [`Shell`, `WorldSlot`, telón y capas](../epics/carga-de-planta/story-001-shell-worldslot.md) | Integration | 1 | `src/shell/shell.tscn`, `shell.gd`, `curtain.gd`, **`project.godot`** (escena principal), `tools/ci/` grep C-X01, (¿`service_context.gd`?) | 0003, 0009 | `tests/integration/scene/persistent_nodes_test.gd` | — | No |
| CP-011 | [`ZoneHub` y `ZoneTrigger`](../epics/carga-de-planta/story-011-zone-hub.md) | Integration | 1 | `src/scene/zone_hub.gd`, `zone_trigger.gd` | 0003, 0011 | `tests/unit/scene/zone_hub_order_test.gd`, `tests/integration/scene/zone_jolt_test.gd` | — | No |
| PJ-005 | [`BobMath`](../epics/jugador-primera-persona/story-005-bob-math.md) | Logic | 1 | `src/player/bob_math.gd` | 0012 | `tests/unit/player/bob_math_test.gd` | PJ-001 ✓ | No |
| PJ-006 | [`StepTracker` y `paso`](../epics/jugador-primera-persona/story-006-step-tracker.md) | Logic | 1 | `src/player/step_tracker.gd`, `ports/surface_probe.gd` | 0012 | `tests/unit/player/step_tracker_test.gd` | PJ-001 ✓ | No |
| PJ-007 | [`PoseHistory` y `YawWindow`](../epics/jugador-primera-persona/story-007-pose-history-yaw-window.md) | Logic | 1 | `src/player/pose_history.gd`, `yaw_window.gd`, `player_types.gd` | 0012 | `tests/unit/player/pose_history_test.gd`, `yaw_window_test.gd` | PJ-001 ✓ | No |
| CP-004 | [`SceneLoader`: precondiciones y estados](../epics/carga-de-planta/story-004-loader-preconditions-states.md) | Logic | 2 | **`src/scene/scene_loader.gd`**, `tests/unit/scene/doubles/` | 0003, 0001 | `tests/unit/scene/scene_loader_preconditions_test.gd` | CP-001 | No |
| PJ-008 | [`StuckGuard`](../epics/jugador-primera-persona/story-008-stuck-guard.md) | Logic | 2 | `src/player/stuck_guard.gd`, `ports/penetration_probe.gd` | 0012 | `tests/unit/player/stuck_guard_test.gd` | PJ-001 ✓ | No |
| PJ-009 | [Máquina de estados y `colocar`](../epics/jugador-primera-persona/story-009-state-machine-colocar.md) | Logic | 2 | `src/player/player_state_machine.gd` | 0012 | `tests/unit/player/player_state_machine_test.gd` | PJ-002 ✓, PJ-004 ✓, PJ-007 | No |
| EC-008 | [Movimiento y mirada F1–F3](../epics/entrada-y-controles/story-008-move-and-look-formulas.md) | Logic | 2 | `src/input/input_formulas.gd`, **`input_router.gd`** | 0006 | `tests/unit/input/move_and_look_formulas_test.gd` | EC-002 ✓, EC-003 ✓ | No |
| EB-014 | [Composición en `Boot`: catálogo y `FactWriter`](../epics/estado-y-bus/story-014-boot-wiring-state.md) | Integration | 2 | **`src/core/game_state.gd`**, **`src/core/boot/boot.gd`**, (¿`service_context.gd`?) | 0001, 0009 | `tests/integration/state/boot_state_wiring_test.gd` | EB-001 ✓, EB-005 ✓, EB-008 ✓ | No |
| CP-005 | [Secuencia de carga de 9 pasos](../epics/carga-de-planta/story-005-load-sequence.md) | Logic | 3 | **`scene_loader.gd`** (usa `GameClock.reset_session()`: si falta, **`game_clock.gd`**) | 0003, 0002 | `tests/unit/scene/scene_loader_sequence_test.gd` | CP-003 ✓, CP-004 | No |
| PJ-010 | [`CameraLease`](../epics/jugador-primera-persona/story-010-camera-lease.md) | Logic | 3 | `src/player/camera_lease.gd` | 0012 | `tests/unit/player/camera_lease_test.gd` | PJ-004 ✓, PJ-009 | No |
| EC-015 | [Composición en `Boot` y sesión teclado + mando](../epics/entrada-y-controles/story-015-boot-wiring-and-manual-session.md) — **paso 1 + sesión parcial** (D-S3-3) | Integration | 3 (+ sesión) | **`input_router.gd`** (`setup` carga bindings), **`boot.gd`** (`contexts_port()`) | 0009, 0006 | `tests/integration/input/boot_input_wiring_test.gd` + `production/qa/evidence/input-m1-session.md` | EC-001…005 ✓, EC-008, EB-014 (orden en `boot.gd`) | **Sí** (recorrido de planta) |
| CP-007 | [Retenciones y `T_cap`](../epics/carga-de-planta/story-007-holds-and-tcap.md) | Logic | 4 | **`scene_loader.gd`** | 0003 | `tests/unit/scene/scene_loader_holds_test.gd` | CP-005 | No |
| CP-012 | [`GameSceneRoot` y `SceneSource` real](../epics/carga-de-planta/story-012-game-scene-root-and-source.md) | Integration | 4 | `src/scene/scene_source.gd`, `game_scene_root.gd`, (¿`service_context.gd`?) | 0003, 0009 | `tests/integration/scene/game_scene_root_test.gd` | CP-005 | No |
| PJ-011 | [`Player.tscn`, rig y API cerrada](../epics/jugador-primera-persona/story-011-player-node-api.md) | Logic | 4 | `src/player/player.gd`, `player.tscn`, `ports/*.gd`, **`project.godot`** (`physics_interpolation = false`) | 0012, 0009, 0002 | `tests/unit/player/player_api_surface_test.gd` | PJ-002…010, EC-008 | No |
| CP-008 | [Fallo de carga y estado Error](../epics/carga-de-planta/story-008-load-failure-error-state.md) | Logic | 5 | **`scene_loader.gd`** | 0003 | `tests/unit/scene/scene_loader_failure_test.gd` | CP-005, CP-007 | No |
| CP-013 | [`planta.tscn` gris](../epics/carga-de-planta/story-013-gray-planta-geometry.md) | Integration | 5 | `src/scene/planta.tscn` (o `assets/levels/`), fixtures `tests/fixtures/scene/{floor_layout,element_ids}.json` | 0003, 0012, 0011 | `tests/integration/scene/floor_layout_test.gd`, `element_ids_test.gd` | CP-011, CP-012, PJ-011 | No |
| CP-009 | [Descarga total](../epics/carga-de-planta/story-009-full-unload.md) | Logic | 6 | **`scene_loader.gd`**, `src/shell/title.tscn` (marcador) | 0003 | `tests/unit/scene/full_unload_test.gd`, `tests/integration/scene/pause_full_unload_test.gd` | CP-008 | No |
| CP-006 | [Contrato `sin control` con Entrada](../epics/carga-de-planta/story-006-no-control-input-contract.md) | Logic | 7 | **`scene_loader.gd`** | 0003, 0006 | `tests/unit/scene/scene_loader_input_contract_test.gd` | CP-005 | No |
| CP-014 | [`ErrorPanel` sobre el telón](../epics/carga-de-planta/story-014-error-panel-ui.md) | UI | 7 | `src/shell/error_panel.tscn`, `error_panel.gd` | 0003 | `production/qa/evidence/carga-014-error-panel.png` (motor) | CP-001, CP-008, CP-009 | **Sí** (revisar captura) |
| CP-015 | [Partida nueva hasta la planta gris: capturas y S-0003-C](../epics/carga-de-planta/story-015-new-game-gray-walk-evidence.md) | Visual/Feel | 8 | **`boot.gd`** (`request_load(PLANTA, PARTIDA_NUEVA, …)`), `production/qa/evidence/carga-015-*.png`, fila S-0003-C de ADR-0003 | 0003 | capturas `--write-movie` + `production/qa/evidence/story-015-new-game-gray-walk-evidence-evidence.md` | CP-006, CP-013, CP-014 | **Sí** (sign-off) |

**Totales:** 22 historias: **14 Logic** (CP-004…009, PJ-005…011, EC-008), **6 Integration** (CP-001, CP-011, CP-012, CP-013, EB-014, EC-015), **1 UI** (CP-014), **1 Visual/Feel** (CP-015). **3 con sesión manual** (EC-015, CP-014, CP-015); las otras 19 se cierran con tests gdUnit4 headless.

### Olas (resumen)

| Ola | Historias | Titular de fichero compartido | Nº |
|---|---|---|---|
| 1 | CP-001 · CP-011 · PJ-005 · PJ-006 · PJ-007 | `project.godot` (+¿`service_context`?) CP-001 | 5 |
| 2 | CP-004 · PJ-008 · PJ-009 · EC-008 · EB-014 | `scene_loader` CP-004 · `input_router` EC-008 · `boot`+`game_state` EB-014 | 5 |
| 3 | CP-005 · PJ-010 · EC-015 (paso 1) | `scene_loader` (+¿`game_clock`?) CP-005 · `input_router`+`boot` EC-015 | 3 |
| 4 | CP-007 · CP-012 · PJ-011 | `scene_loader` CP-007 · ¿`service_context`? CP-012 · `project.godot` PJ-011 | 3 |
| 5 | CP-008 · CP-013 | `scene_loader` CP-008 | 2 |
| 6 | CP-009 | `scene_loader` | 1 |
| 7 | CP-006 · CP-014 | `scene_loader` CP-006 | 2 |
| 8 | CP-015 → **Sesión del usuario** | `boot` CP-015 | 1 |

O5–O8 quedan por debajo de 3 historias: no hay historia elegible que no dependa de la cadena de `scene_loader.gd` (D-S3-4). Son las de menos riesgo (lógica pura con dobles) salvo CP-015.

## Sesión del usuario (al final de la ola 8, ≈ 15 min)

Requisitos previos (los comprueba el lead antes de avisar): olas 1–8 verificadas, CI verde, `production/qa/evidence/carga-014-error-panel.png` y las capturas de CP-015 en disco. Un mando conectado por USB o Bluetooth **antes** de lanzar.

**A. Arranque y carga (2 min)**
1. Lanzar: `C:\Users\airlesme\tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe --path C:\dev\personal\el-nido`
2. Debe pasar: ventana negra → fundido de entrada → vista en primera persona **dentro del despacho** (paredes grises, techo, hueco de puerta al pasillo). Sin panel de error, sin texto de carga, sin consola de depuración.
3. Anotar: segundos aproximados desde el clic hasta ver el despacho (la medida precisa de S-0003-C la hace CP-015).

**B. Teclado + ratón (5 min)**
4. Mover el ratón: la vista gira a izquierda/derecha y arriba/abajo, sin girar de lado (roll 0) y con tope arriba/abajo. Si el cursor se sale de la ventana o la vista no gira, anotar **FAIL R-S3-8** (captura del ratón).
5. **W** adelante, **S** atrás, **A**/**D** laterales; en diagonal no va más rápido. Al soltar, se para sin deslizar.
6. Caminar contra una pared del despacho: se detiene, no la atraviesa, no tiembla. Lo mismo contra el marco de la puerta.
7. Salir por la puerta (1 m) al pasillo, recorrerlo y entrar en el Archivo; volver al despacho. No debe haber fundidos ni negro al cambiar de zona.
8. **E** (interactuar) y **Esc** (pausa) **no deben hacer nada visible** en este sprint (prompt y pausa fuera); que no aparezca error.

**C. Mando (5 min)**
9. Soltar ratón y teclado. Stick izquierdo: mover; stick derecho: mirar. Repetir 5–7.
10. Stick en reposo: la vista no deriva (zona muerta). Desconectar y reconectar el mando a mitad de recorrido: anotar qué pasa (PASS si se puede seguir caminando).

**D. Grabación con el motor (3 min; nunca captura de escritorio)**
11. Cerrar el juego (cerrar la ventana) y lanzar con grabación:
    `C:\Users\airlesme\tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe --path C:\dev\personal\el-nido --write-movie C:\dev\personal\el-nido\production\qa\evidence\s3-recorrido-teclado.avi`
    Caminar despacho → pasillo → Archivo (≈ 30 s) y cerrar la ventana. Repetir con mando a `s3-recorrido-mando.avi`. (El modo película fija el paso de tiempo; si se nota a cámara lenta, es esperado.)
12. Responder al lead: PASS/FAIL por paso 2, 4–10 y lo raro que se haya visto. El lead lo copia a `production/qa/evidence/input-m1-session.md` y firma CP-014/CP-015.

## Recortes ordenados (si no cabe)

Un recorte cada vez, anotado aquí y en el hito:
1. **Fuera ya del Sprint 3:** manos, audio, subtítulos, guardado, pausa (EC-014), ordenador (IP-012), puzles, **prompt** (sin historias).
2. S-0003-C en el **export** (CP-015): se mide en el editor y se anota «export NOT RUN».
3. Las comprobaciones NEEDS_MANUAL de EC-015 que no son caminar (hot-plug, familia de mando, `LineEdit`): NOT RUN anotado; EC-015 queda abierta de todos modos (D-S3-3).
4. CP-014 se cierra con la captura del motor hecha por el lead y el sign-off pasa a la sesión siguiente.
5. **Objetivo reducido** (si CP-008/009/006/014/015 no caben): la planta se carga por `SceneLoader` en un test de integración y el usuario camina lanzando la escena directa (`... --path C:\dev\personal\el-nido res://src/scene/planta.tscn`) **solo si** `GameSceneRoot` compone su contexto en solitario; si no, el recorrido es NOT ASSESSED y no se da por cumplido.

## Carryover from Previous Sprint

Ninguno: el Sprint 2 cerró 18/18 (13 Must + 5 Should).

## Risks

No hay registro de riesgos (`production/risk-register/` no existe); se evalúan desde el contenido del sprint.

| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| **R-S3-1** | **Primera integración con nodos reales** (`CharacterBody3D`, `Area3D`, `Camera3D`, `SceneTree` con escena cambiada en ejecución): lo medido (≈ 12 turnos) es de lógica pura. | Alta | Alto | Integration headless primero (CP-001/011/012/013, EB-014); suite tras cada historia; arranque con ventana desde O3. |
| **R-S3-2** | **Jolt real** (por defecto en 4.6+): sensores de zona, `move_and_slide` contra la geometría gris, puerta de 1,00 m (S-0012-C). | Media | Alto | CP-011 `zone_jolt_test` en O1; contrastar todo API con `docs/engine-reference/godot/`; NOT SOURCEABLE se anota, no se rellena de memoria. |
| **R-S3-3** | **Sin assets**: la planta es geometría primitiva; medidas solo del slice (A.1–A.7). Riesgo de inventar medidas o de que la planta no se lea. | Media | Medio | CP-013 construye desde las fixtures de A.x; AC-02/03 con ±0,05 m; nada de texturas ni luces de ambiente. |
| **R-S3-4** | **Rendimiento en el portátil de referencia** (REF-1): tirón de carga síncrona (S-0003-C, umbral ~1 s) y presupuesto por tick (C-G01). | Media | Medio | CP-015 mide 5 veces mediana y peor caso; si > 1 s → ADR nuevo sobre D4 (no se arregla en el sprint). PJ-013 (30/60/144 fps) en el Sprint 4. |
| **R-S3-5** | **Cadena serie de `scene_loader.gd`**: 6 historias en 6 olas; una atascada retrasa CP-014/015 y el objetivo. | Alta | Alto | CP-004/005 lo antes posible (O2/O3); CP-006 al final porque solo lo pide CP-015; § Recortes 5. |
| **R-S3-6** | **Escena principal en disputa**: CP-001 pide `run/main_scene = shell.tscn` y que «`Boot` siga siendo el primer autoload», pero hoy `Boot` es la raíz de `main.tscn`, no un autoload. | Cierta | Medio | `/story-readiness CP-001` lo resuelve antes de O1 con `technical-director` (ADR-0009 D3); EB-014/EC-015/CP-015 dependen de dónde viva `Boot`. |
| R-S3-7 | **Ficheros compartidos no declarados** (`service_context.gd`, `game_clock.gd` por `reset_session`, helpers de test). | Media | Alto | § Regla de olas 2–4; `/story-readiness` confirma la lista; un agente que necesite un fichero no declarado para y lo dice. |
| R-S3-8 | **Captura del ratón** (`mouse_mode`) sin historia identificada: la mirada con ratón puede no funcionar en la sesión. | Media | Medio | § Goal Prerequisites fila 8; paso 4 de la sesión lo detecta. |
| R-S3-9 | **`ContentDB` esqueleto**: `Player` hace `ctx.require(content)`; si alguna lectura real pasa por ahí, falla en ejecución. | Baja | Medio | `/story-readiness PJ-011` lo comprueba; si hace falta, CD-004 entra por `/sprint-plan update` en lugar de un recorte. |
| R-S3-10 | **EC-015 se queda abierta**: su CA AC-04 pide el recorrido de escenas 1–3 (con interacción y puzles), que no existe en M1 hasta el Sprint 4–5. | Cierta | Bajo | D-S3-3: cierre en dos pasos, como prevé la propia historia; el paso 1 cuenta como entregado. |
| R-S3-11 | **CI con ventana**: las historias Visual/UI no se pueden verificar en CI headless; el CI solo cubre las suites. | Cierta | Bajo | Capturas retenidas en `production/qa/evidence/`, hechas con `--write-movie`; el CI no se presenta como prueba de lo visual. |
| R-S3-12 | **Colisiones del jugador sin test propio**: PJ-012 (física headless del `Player`) queda fuera por el tope de 22. | Media | Medio | Paso 6 de la sesión lo cubre a mano; PJ-012 es la primera del Sprint 4. |

## Criterio de salida del sprint

1. Las 22 historias en `Complete` por `/story-done`, verificadas por el lead; **EC-015** con el paso 1 cerrado y la sesión parcial registrada (sigue `In Progress` por AC-04; ver R-S3-10).
2. **Suite gdUnit4 completa en verde** con el comando de CI, suites nuevas en el informe; **0 fugas ObjectDB, 0 huérfanos**; `forbid_timers` y `check_pins` limpios.
3. **CI verde en GitHub** en el último commit de **cada ola**, comprobado por el lead (run anotado); un fallo de infraestructura se anota NOT VERIFIED y no cuenta como verde.
4. Arranque en debug y con ventana **sin errores en consola** (C-M1-9).
5. **Recorrido manual del usuario** con teclado+ratón **y** con mando, pasos 2 y 4–10 de la Sesión en PASS, anotado en `production/qa/evidence/input-m1-session.md`.
6. **Capturas retenidas hechas con el motor** (`--write-movie`): `carga-014-error-panel.png`, `carga-015-archivo.png`, `carga-015-curtain-*.png`, `s3-recorrido-teclado.avi`, `s3-recorrido-mando.avi`. **Nunca capturas de escritorio**: una así no cuenta.
7. S-0003-C medido y anotado en ADR-0003 § Spike Results.
8. Fechas y turnos rellenados (§ Fechas).

## Decisiones del usuario

| ID | Decisión | ¿Afecta al Sprint 3? |
|---|---|---|
| U-1 | Replanificar M1 con la velocidad medida | Tras este sprint (primera medida con Integration) |
| **U-3** | **Las 6 decisiones de diseño** de `design/gdd/gdd-cross-review-2026-11-10-r2.md` § Decisiones tuyas pendientes (pistas 20/40 s; parpadeo/apagón con `reducir_sobresaltos`; `reducir_movimiento` y `escala_texto_ui`; aviso «interacción ejecutada»; suelo de subtítulos a 720p; las de siempre) | **No bloquea ninguna historia de este sprint** (caminar en gris no toca pistas, accesibilidad, subtítulos ni puzles). La n.º 4 la necesita IP-007 y el prompt; la n.º 3 (`reducir_movimiento`) toca el balanceo de cámara de PJ-005 solo vía Ajustes (ADR-0007, diferido). **Hacen falta antes del Sprint 4** (prompt e interacción) |
| U-5 | Prompt: ¿escribir ya sus historias (ADR-0016 Accepted) para el Sprint 4? | Antes de planificar el Sprint 4 (recomendado: sí) |

## Sprint 4 (propuesta, en orden de ruta crítica)

PJ-012 física del `Player` · PJ-013 recorrido 30/60/144 fps · IP-004 `FocusSelector` · IP-005 `InteractionSystem` en planta · historias del prompt (nuevas, ADR-0016) · IP-006 · EB-015 test de estado M1 · EC-006/007/011 · CP-010 · y la cola de lógica (EB-012/013, EC-009/010/012/013, CD-004…012, AC-001…003, DB-001…002, IP-007…011).

## Dependencies on External Factors

- Mando físico del usuario (sesión) y el portátil de referencia para S-0003-C.
- CI de GitHub Actions (acción de gdUnit4; el Sprint 2 tuvo un `HttpError: Not Found` de infraestructura).

## QA

No hay QA plan para el Sprint 3 (`production/qa/qa-plan-*.md` solo tiene el del Sprint 1).
**Decisión autonomous (opción A, recomendada):** `/qa-plan sprint` antes de la ola 1; para las Integration/UI/Visual debe fijar qué se prueba headless y qué en la sesión.

## Definition of Done for this Sprint

- [ ] QA plan del sprint (`/qa-plan sprint`)
- [ ] R-S3-6 resuelto en `/story-readiness CP-001` antes de O1
- [ ] Las 22 historias completas con verificación del lead (EC-015: paso 1)
- [ ] Suite verde, 0 fugas, 0 huérfanos, `forbid_timers`/`check_pins` limpios, arranque sin errores
- [ ] CI verde verificado en GitHub tras cada ola
- [ ] Sesión del usuario hecha y registrada; capturas del motor retenidas
- [ ] Smoke de cierre (`/smoke-check sprint`) con `tests/timing/` leído
- [ ] Ningún bug S1/S2 en lo entregado; GDD actualizados si hubo desviaciones
- [ ] Fechas y turnos rellenados

## Decisiones tomadas (modo autonomous)

- **D-S3-1: objetivo = primer recorrido jugable, sin prompt.** El prompt no tiene historias (se difirieron con ADR-0016 Proposed); escribirlas no es trabajo de `/sprint-plan`. *Descartado:* prometer el prompt (exigiría IP-004, IP-005 y una historia nueva: > 22).
- **D-S3-2: 22 historias = carga entera hasta CP-015 (12) + jugador hasta PJ-011 (7) + EC-008 + EC-015 + EB-014.** Es el mínimo que cumple las dependencias declaradas: CP-015 (petición de carga en el arranque) exige CP-006/013/014, y CP-014 exige CP-008/009. *Descartado:* PJ-012 y PJ-013 dentro (24, por encima del tope); la colisión se valida a mano (R-S3-12). *Descartado:* quitar EB-014 (sin catálogo el canal de avisos es `null` y la carga no avisa en el juego real). *Descartado:* IP-004…006 e IP-013 (no aportan nada visible sin prompt; IP-013 pide puzles y documentos).
- **D-S3-3: EC-015 en dos pasos.** Paso 1 (cableado de `setup`, bindings, `contexts_port()`, test de integración) en O3, con dependencias reales EC-001…005 + EC-008; paso 2 = la sesión. Lo prevé la propia historia (§ Implementation Notes). AC-04 (escenas 1–3) queda abierto. *Descartado:* esperar a EC-006…014 (9 historias más, fuera del tope).
- **D-S3-4: 8 olas, 4 por debajo de 3 historias.** Lo impone `scene_loader.gd` (6 titulares en serie). *Descartado:* juntar dos historias de `scene_loader.gd` en una ola (es la colisión de ficheros que la regla prohíbe); *descartado:* rellenar con lógica fuera de la ruta (rompería el tope de 22).
- **D-S3-5: CP-006 en O7 y no en O4.** Solo la pide CP-015; adelantarla retrasa CP-007→008→009→014, que sí están en serie.
- **D-S3-6: `production/sprint-status.yaml` no se escribe en esta pasada** (el encargo limita la salida a este fichero y a una línea del hito). Se genera con `/sprint-plan update` al empezar: las 22 → `ready-for-dev`.

## Decisión del lead antes de la ola 1 (2026-11-12): R-S3-6, Shell frente a Boot

CP-001 pide `run/main_scene = res://src/shell/shell.tscn` y dice que «Boot sigue siendo el primer autoload (ADR-0009)». En el código `Boot` NO es un autoload: es un `Node` hijo de `src/core/boot/main.tscn` que ejecuta `compose()` en `_ready` (los 9 autoloads de ADR-0009 D1 no incluyen `Boot`). **Decisión:** `shell.tscn` se convierte en la escena principal e instancia `Boot` como su PRIMER hijo (antes que `WorldSlot`, `Curtain` y el resto), de modo que `Boot.compose()` corre antes que cualquier sistema de la escena; `src/core/boot/main.tscn` se retira o queda como escena de pruebas. *Alternativa descartada:* registrar `Boot` como autoload número 10 (cambia la lista de ADR-0009 D1 sin necesidad y mezcla raíz de composición con servicios persistentes). Se anota como enmienda a ADR-0009 (texto «primer autoload» → «primer hijo de `Shell`») al cerrar CP-001.

## Cierre (2026-11-12)

**Resultado:** el juego arranca, carga la planta gris con el telón y se camina en primera persona con
teclado y ratón (confirmado por el usuario tras el arreglo del avance en diagonal). Suite 957/957, 0 fugas,
CI verde en los últimos commits, arranque limpio.

**No cerradas (siguen `Partial`/`In Progress`):** CP-007 (AC-19 «hecho que cambia en Cargando»), CP-008 (AC-22:
falta Entrada con `pausa`/`atrás` sobre el panel), CP-014 (fallo real en el export), CP-015 (C-M1-1 en builds
exportadas; recorrido humano completo), EC-015 (sesión con mando; entrega a 21), EB-014 (parte release de CA-26).

**Qué enseñó el sprint**
- El usuario encontró en 1 minuto un bug que 954 tests no veían: `planta.tscn` instanciaba el `Player` con el
  giro del ancla (cámara = 2× yaw). Las pruebas usaban el jugador suelto. Se añadió un test de arranque real con
  tecla W real (visto fallar antes de arreglar). Regla: **toda historia visible lleva un test por el camino real
  de arranque**, no solo del componente.
- Godot regraba `project.godot` al capturar con `--write-movie`: comprobar `git diff project.godot` tras cada captura.
- Los agentes agotan turnos (~20) en historias con cableado: dar briefs con orden de prioridad y reanudar.

**Pendiente para planificar el Sprint 4:** las 6 decisiones de diseño del usuario (U-3; la n.º 4 la necesita
IP-007 y el prompt), escribir las historias del prompt (U-5, ADR-0016 Accepted), sesión con mando, y replanificar
M1 con la velocidad medida (U-1).

