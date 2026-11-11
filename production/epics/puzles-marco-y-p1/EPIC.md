# Epic: Marco de puzles y puzle 1 (Cronología)

> **Layer**: Feature
> **GDD**: design/gdd/marco-de-puzles.md (§ Overview l. 16, § Acceptance Criteria l. 638); design/gdd/puzle-1-cronologia.md (§ Overview l. 18, § Acceptance Criteria l. 350)
> **Architecture Module**: Capa 3 — 9 Marco de puzles (`PuzzleFramework`) y 11 P1 (subclase de `PuzzleController`); `architecture.md` § API Boundaries «Marco de puzles (9) y `puzzles.json` v2 — ADR-0010»
> **Status**: **BLOQUEADO por ADR-0010 (Proposed)** — 0/40 TR libres (marco: 16 citan ADR-0010, 6 ADR-0005; P1: 17 citan ADR-0010; TR-puzzle1-018 sin ADR, índice A4)
> **Desbloqueo**: aceptación de ADR-0010 sin spike (C4, C5, C6; H1–H5, H3 y H8 de la cola) + ADR-0005
> **Stories**: Not yet created — run `/create-stories puzles-marco-y-p1` tras aceptar ADR-0010
> **Control manifest**: v2026-11-11 — § Feature Layer Rules (vacía) + reglas transversales de Foundation
> **Engine Risk**: MEDIUM (`@abstract`, retorno tipado heredado 4.7, `Tween` en pausa)

## Overview

Marco con estado público por puzle, fases, `EV_PUZZLE_SOLVED_P1`, escritor único de
`archivo_abierto`. P1: panel de la puerta A con 4 huecos, solución `2 · 1 · 3 · 4`; fallo: las hojas
vibran y vuelven a la impresión tras 1,5 s, sin penalización; `evaluate() -> Verdict` puro.
**No se recorta nunca en M1:** P1 completo con su fallo no terminal y sus tests de lógica.
Pistas de P1 diferidas (recorte 2).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0010: Puzzle framework and controller contract (**Proposed**) | Marco, `PuzzleController`, `puzzles.json` v2 | MEDIUM |
| ADR-0001 (Accepted) | Co-cubre 10 TR de P1 (hechos y avisos) | MEDIUM |
| ADR-0002, ADR-0009 (Accepted) | `GameClock` inyectable (TR-puzzles-014) | HIGH |
| ADR-0005, ADR-0008, ADR-0017 (Proposed) | Co-citados | — |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-2**: tests gdUnit4 en verde de solución válida, inválidas y «sin softlock»; oráculo con
  `GameClock` falso (TR-puzzle1-018) **NOT ASSESSED** mientras no tenga ADR trazado.
- **C-M1-3**: fallo repetido ×5 en P1 sin estado terminal.
- **C-M1-4**: `archivo_abierto` lo escribe solo 9.
- **C-M1-7**: captura retenida del panel P1.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` puzzles puzzle1; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-puzzles-001 | Un puzle = entrada en `assets/data/puzzles/puzzles.json` (raíz `{ "schema_version": 2, "puzzles": [...] }`, otra versión = fallo de validación) + subclase de `PuzzleController`; todo valor numé... | ❌ No ADR (ADR-0005 Proposed) |
| TR-puzzles-002 | Esquema de definición: `id` (P1–P6), `solved_flag`, `mode` (`VIEW`/`WORLD`), `view`/`elements`, `requires.all`, `needs_items`, `validation`, `solution`, `on_reject`, `on_partial`, `on_change`, `... | ❌ No ADR (ADR-0005 Proposed) |
| TR-puzzles-003 | `on_solved.write[]` admite `{flag,value}` XOR `{flag,value_from,map?}`; `value_from` toma una clave de la carga útil del veredicto `SOLVED` (`choice` P6, `t4_action` P4) y `map` traduce a un valor... | ❌ No ADR (ADR-0005 Proposed) |
| TR-puzzles-004 | Catálogos cerrados validados: `commit_on` (`SELECT_END_SAME_ELEMENT`/`SELECT_START`), `idle_reset` (`GESTURE`/`GESTURE_AND_MOVE`/`PRESS_ONLY`), `AFFORDANCE.affordance` (`MIRROR_PREVIEW`, `FLOOR_MA... | ❌ No ADR (ADR-0005 Proposed) |
| TR-puzzles-005 | Validación de datos al arrancar (regla 29), tras cargar catálogos de 7 y claves de 18 y antes de configurar puzles/registrar receptores: unicidad, `requires.all` sin ciclos y con escritor, `on_re... | ❌ No ADR (ADR-0005 Proposed) |
| TR-puzzles-006 | Tipos: el cargador convierte explícitamente a `int` los campos enteros (`sequence`, `pos_*`, `level`) y los comprueba (parser JSON devuelve float; Open Questions 4) | ❌ No ADR (ADR-0005 Proposed) |
| TR-puzzles-007 | Tres estados públicos `BLOQUEADO`→`ACTIVO`→`RESUELTO`, monótonos, sin método de retroceso (salvo consola dev, regla 31); fases internas `IDLE`/`EVALUATING`/`FEEDBACK`/`RESOLVING` no publicad... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-008 | `PuzzleController` clase abstracta (`@abstract`, Godot ≥4.5) con `configure(def, flags)`, `on_open()`, `on_close(motivo)`, `elements()`, `handle_pointer(ev)`, `handle_activation(element_id, verb)... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-009 | El controlador nunca escribe hechos ni emite avisos ni recibe referencia de escritura; `evaluate()` es función pura sin tiempo ni acumulador; `Verdict` ∈ {`NONE`,`HOLDING`,`PARTIAL`(progress),`R... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-010 | Cinco políticas de comprobación: `DELAYED_AFTER_CHANGE` (0,6 s), `ON_CHANGE` (+reevaluación única tras «escena lista»), `PER_ELEMENT`, `SUSTAINED` (`evaluate()` cada fotograma, acumulador del... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-011 | Orden de escritura al resolver en el mismo fotograma: hechos de `on_solved.write` en orden declarado -> `solved_flag` -> estado `RESUELTO` -> `EV_PUZZLE_SOLVED_<ID>` {puzzle, rewards, choice} -> «... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-012 | Resolución `DEFERRED` (P5, 16,0 s nominales): escribe `pendiente_revelacion`=true al iniciar; al acabar escribe `caja_c3`, luego limpia `pendiente_revelacion`; interrumpible solo por salida de la ... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-013 | Pasos `LINE`: duración = `fallback_s` 14,0 s si «línea sin audio»/«línea fallida», termina en «línea terminada» sin pasar de `fallback_s + line_grace_s` (2,0 s) si no hay señal; el audio... | ❌ No ADR (ADR-0008, ADR-0010 Proposed) |
| TR-puzzles-014 | `GameClock` inyectable que avanza solo con tiempo de juego para todo temporizador del marco (F1, F2, F3, F8, locks, `close_view_after_s`, `line_grace_s`); prohibido `SceneTreeTimer`/`create_timer`;... | ADR-0002, ADR-0009 ✅ (+ ADR-0010, ADR-0017 Proposed) |
| TR-puzzles-015 | Configuración síncrona al cargar la escena (regla 9.6 de 4): por puzle, resolver `RESUELTO` si `solved_flag` (restaurar presentación sin avisos), `ACTIVO`/`BLOQUEADO` según `requires.all`, rest... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-016 | Estado persistido solo como hechos de `flags.json`: `solved_flag` por puzle, `pos_L/C/R` (escritos en cada cambio del P2), `pendiente_revelacion`, `carta_variante`, `t4_decision`; sin hechos nuevos... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-017 | Registro como `ViewReceiver` de cada vista de puzle y como manejador de `B01`–`B03` (`registrar_receptor`, `registrar_manejador`) antes de «escena lista»; `get_view_gate(view_id) -> {state: OPE... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-018 | Política única de fallo: `REJECT` -> feedback, `reset_attempt` tras `reset_after_s`, `lock` (`PUZZLE`/`ELEMENT`/`NONE`) ≤ `lock_max_s` 2,0 s; eventos durante el bloqueo se descartan (no se enco... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-019 | API de pistas para 17: `list_puzzles()`, `get_hints(id)`, `request_hint(id, level)` (ignorada en `RESOLVING`), notificación «puzle inactivo» al cruzar `idle_s`; `idle_hints_auto_apply` en datos;... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-020 | Avisos del marco con nombre y carga: `EV_PUZZLE_SOLVED_<ID>` {puzzle, rewards, choice}, «compartimento completado» (n), «puzle activado» {puzzle, ajar_cm?}, «feedback de puzle» {puzzle, sound... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-021 | Resolubilidad (S7): prueba automática con oráculo independiente: `N_fuzz` 1.000 secuencias por puzle (incluye pistas, cancelaciones, cierre/reapertura, guardar/cargar), solucionador de referencia... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzles-022 | Registro de playtest local (solo builds dev/playtest, ausente en demo): tiempo a resolver, intentos, rechazos, pistas pedidas/ignoradas, cierres; accesibilidad: lee `reducir_movimiento`, `asistenci... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-001 | La entrada `P1` de `assets/data/puzzles/puzzles.json` usa `schema_version: 2`, `mode: VIEW`, `view: C05`, `solved_flag: archivo_abierto`, `requires.all: []`, `needs_items: ["I-01"]` y `persist: []`... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-002 | `solution.sequence = [2,1,3,4]` (enteros, convertidos a `int` en la carga) es dato; una prueba de CI ordena los 4 bloques con `ref` por el entero `ts_envio` de `compose_i01()` y falla si difiere de... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-003 | `Puzzle1Controller` hereda de `PuzzleController` y solo devuelve veredictos: no escribe ni lee hechos, no emite avisos y no cambia el estado público (el hecho `archivo_abierto` lo escribe 9 al res... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-004 | El controlador posee dos estados en memoria: la colocación `S=(s1..s4)`, con `sk ∈ {1..4, vacío}` e inyectiva (209 estados, 24 completos), y `en_mano ∈ {ninguna,1..4}`. | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-005 | Solo procesa el gesto `seleccionar` (confirmado en fase `fin`) e ignora actualización, agarrar, mantener y rotar. Implementa las 9 filas de R13, incluidos mover (fila 4), intercambiar (fila 5), de... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-006 | `evaluate()` es función pura de (colocación, `en_mano`, `solution`) y devuelve `SOLVED` con `[2,1,3,4]`, `REJECT` con cualquier otro estado completo y `NONE` con estado incompleto o `en_mano ≠ ... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-007 | Seleccionar, deseleccionar o perder la referencia en mano cuenta como cambio para `DELAYED_AFTER_CHANGE` (`delay_s` 0,6 s en `GameClock`, rango 0,3–1,5). Una cancelación (cierre, `atrás`, pérd... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-008 | Reparto de `elements()`: 19 aporta los bloques y las 4 refs vía `compose_i01()`; el marco crea `C05/paper/ref_N` (exactamente 4); el controlador declara `C05/slot_1..4` y las marcas no clicables `... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-009 | Sin `I-01` (`has_item`, vía marco), la vista muestra 4 huecos vacíos sin hoja ni refs; pulsar un hueco da `locked_feedback` `SFX_CLICK_SUBTLE` sin texto, sin escribir hechos y con P1 `ACTIVO`. | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-010 | La geometría de la vista vive en `assets/data/puzzles/p1_view.json`, no en el controlador. Viewport 1920×1080, hoja 1000×960, `ref_N` 112×56 con paso ≥150, `slot_k` 160×160 con paso 200 desd... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-011 | `element_zones` con `ids: ["C05/paper/ref_*"]` y `atraccion_desactivada: true`; `slot_k` mantiene la atracción asistida (mando/stick atraído solo por los huecos). No declara `assist` y usa R=64 p... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-012 | `on_change: {sfx:"SFX_SLOT_IN", when:"REF_PLACED"}`: el marco emite «feedback de puzle» una vez por cada cambio que deja una referencia en un hueco (filas 4 y 5), y ninguno al vaciar (fila 6). | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-013 | Rechazo uniforme para los 23 estados incorrectos: `lock: PUZZLE` 1,5 s con eventos descartados, `shake_s` 1,2 s, `reset_after_s` 1,5 s (≤ `lock_max_s` 2,0). `reset_attempt` devuelve las 4 refs a ... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-014 | Persistencia: solo `archivo_abierto`. Colocaciones, `en_mano`, hoja y nivel de pista no se guardan; las colocaciones sobreviven al cierre de la vista (`KEEP`) y se pierden al cargar. Al cargar con ... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-015 | Resolución `IMMEDIATE`, en el mismo fotograma y por este orden: escribir `archivo_abierto`, P1 `RESUELTO`, `EV_PUZZLE_SOLVED_P1 {puzzle:'P1', rewards:[]}`, sin «compartimento completado», `SFX_U... | ADR-0001 ✅ (+ ADR-0010 Proposed) |
| TR-puzzle1-016 | Tres pistas `REQUEST` sin `IDLE` y sin mover cámara: N1 `HIGHLIGHT` de `C05/paper` 3,0 s con `targets_if_missing_items:["V08"]`; N2 `TEXT` con la clave `PISTA_P1_N2` de 18; N3 `HIGHLIGHT` de `stam... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-017 | Tras resolver, el marco cierra de inmediato una apertura por vía no normal (`cerrar_vista('C05','sistema')`). `C05` deja de ser objetivo con `archivo_abierto` verdadero (`habilitado_si: {ninguno:[... | ❌ No ADR (ADR-0010 Proposed) |
| TR-puzzle1-018 | Pruebas en `tests/unit/puzzle_1/` con `GameClock` falso: oráculo de 1.000 secuencias aleatorias que llega siempre a `RESUELTO` (AC-12), 23 rechazos idénticos (AC-10) y temporización F5 (AC-6/7).... | ❌ No ADR (hueco: ninguno en el registro) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
