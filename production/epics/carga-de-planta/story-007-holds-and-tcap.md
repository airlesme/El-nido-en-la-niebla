# Story 007: Retenciones y `T_cap` en tiempo real

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Partial — AC-13, AC-F2, AC-F3 (parte 3) y AC-19 (holds) cumplidos en lógica; pendiente AC-19 «hecho que cambia en Cargando» (no probado en el cargador) y el error visible en dev
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R12, § Formulas F2, § Edge Cases (retención tardía, hecho que cambia en Cargando)
**Requirement**: `TR-scene-012`, `TR-scene-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D5; Load sequence «wait»; Key Interfaces `take_hold`/`release_hold`)
**ADR Decision Summary**: los holds son un conjunto de `StringName`; `take_hold` idempotente, `release_hold` nunca baja de 0; válidos solo entre el inicio del paso 6 y «escena lista» (fuera: ignorados + log); `t_espera` en tiempo real sin recortar desde α = 1; `t_espera ≥ T_cap` → fallo `t_cap` con los IDs.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: `RealClock` (`src/core/platform/real_clock.gd`, `now_ms()`) ya existe; en test, ticks enteros.

**Control Manifest Rules (Core)**:
- Required: C-R05, C-R06 (IDs `&"<system>:<element_id>"`, liberación por ID)
- Forbidden: C-X06 (contar holds a mano)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **AC-13**: GIVEN una retención de 3 s, THEN la cortina doble registra α = 1 hasta «escena lista», el aclarado no empieza antes y no se crea ningún nodo de interfaz visible bajo la cortina.
- [ ] **AC-F2**: retenciones liberadas a 0,2, 1,5 y 4,0 s → «escena lista» a 4,0 s sin fallo; una que nunca se libera con `T_cap` = 10 → fallo a t_espera = 10,0 s (no antes) con el nombre del elemento en el log; 100 liberadas a 1 s → sin fallo; doble liberación → `n_ret` no baja de 0; ventana sin foco 20 s → t_espera sigue avanzando (fallo a los 10 s).
- [ ] **AC-19 (parte holds)**: GIVEN una retención tomada después de «escena lista», THEN se ignora, hay línea de log (dev: error visible) y «escena lista» no se vuelve a emitir; GIVEN un hecho que cambia durante Cargando, THEN el aviso se entrega y los elementos pendientes leen el valor nuevo.
- [ ] **AC-F3 (parte 3)**: un fallo por T_cap ocurre a d_out + T_cap desde «iniciada», antes de `D_carga` + margen (margen leído de los datos de Entrada, no fijado aquí), también sin foco 20 s.

---

## Implementation Notes

- El fallo por `t_cap` entra por la misma ruta que 008 (causa + IDs pendientes).
- La parte de AC-19 sobre la pausa en Cargando la descarta Entrada (ADR-0006): solo comprobar que 4 no la ve.

---

## Out of Scope

- 008: estado Error y panel.

---

## Files

- `src/scene/scene_loader.gd`
- `tests/unit/scene/scene_loader_holds_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/scene_loader_holds_test.gd` (T-U3) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-005-load-sequence.md`
- Unlocks: `production/epics/carga-de-planta/story-008-load-failure-error-state.md`

---

## Evidencia

- Código: `src/scene/scene_loader.gd` (`take_hold`, `release_hold`, `get_hold_count`, `_wait_step`, `CAUSE_T_CAP`; `t_espera` desde α = 1 con `RealClock`, sin recortar; `_fail` acepta IDs pendientes ordenados y los registra).
- Tests: `tests/unit/scene/scene_loader_holds_test.gd` (14 casos; dobles `holding_scene_source.gd`, `holding_scene_root.gd`). Reloj en ms relativos a «α = 1», sin depender de nº de fotogramas.
- Suite bloqueante: 873 casos, 0 errores, 0 fallos, 0 huérfanos; sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` sin errores; `--boot-report` rc 0 sin errores.
- AC-13: α = 1 sin escrituras de cortina durante la espera (los nodos de UI no los crea el cargador). AC-F2: 0,2/1,5/4,0 s → lista a 4,0 s; fallo a exactamente 10,0 s (no a 9,999) con el ID; 100 a 1 s sin fallo; doble liberación ≥ 0; 20 s sin foco falla. AC-F3 p.3: fallo en d_out + T_cap < D_carga (margen de Entrada no fijado aquí).
- AC-19: hold tardío/previo ignorado + línea de log, «lista» no se repite. NO cubierto: entrega del aviso y lectura del valor nuevo de un hecho durante Cargando (es de GameState/elementos). Error visible en dev: solo línea de log; `TODO(carga-007)` → carga-008.
- Ruta de fallo: `_fail` mínimo de 005; el panel/contrato completo es 008.
