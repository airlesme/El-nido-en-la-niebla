# Story 006: Contrato `sin control` con Entrada

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Done (2026-11-12)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R9 (pila de contextos durante la carga)
**Requirement**: `TR-scene-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D6; § `sin control` handoff to 21; Key Interfaces `InputContexts`) · ADR-0006 (firmas de las operaciones de Entrada)
**ADR Decision Summary**: 4 **abre** `sin control`(4, `D_carga`) justo tras «iniciada» (`absorbs_foreign` en `partida_nueva`/`reanudar`); pide `reset_stack_on_unload()` solo al liberar una escena de juego; pide `exploración` en «terminada» si `control_final = exploracion`; con `ninguno` no toca la pila y el 21 traspasa en ese fotograma; `restore_menu()` en fallo y en descarga total. 4 nunca cierra ni traspasa por el 21.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: C-R07
- Forbidden: que 4 emita una petición de cierre o restaure `menú` tras un traspaso
- Guardrail: —

---

## Acceptance Criteria

- [x] **AC-21**: GIVEN Entrada doble con pila [`menú`], WHEN se pide `planta` con `partida_nueva`, THEN en «iniciada» Entrada recibe la apertura de `sin control` (dueño 4, `D_carga`) y la pila es [`menú`, `sin control`]; si la carga falla, 4 repone `menú`; WHEN el 21 doble traspasa en el fotograma de «terminada», THEN el dueño es 21 y 4 no pide cierre; WHEN nadie traspasa, THEN el tope `D_carga` + margen lo libera con una línea de log. *(El tramo `recepcion` se adapta a recarga de `planta` desde `planta`.)*
- [x] **AC-21b**: GIVEN `control_final` = `ninguno`, WHEN la carga es desde el título ([`menú`]), THEN [`menú`, `sin control`(4)] → tras el traspaso [`menú`, `sin control`(21)] → al pedir 21 `exploración`, [`exploración`]; WHEN es desde la planta ([`exploración`]), THEN [`exploración`, `sin control`(4)] → tras la descarga [`sin control`(4)] → [`sin control`(21)] → [`exploración`]; 4 nunca pide cierre ni restaura `menú`.
- [x] Liberar el título **no** pide `reset_stack_on_unload()` (D2).

---

## Implementation Notes

- `InputContexts` (§ Key Interfaces de ADR-0003; firmas propiedad de ADR-0006): `open_no_control(owner, declared_s, absorbs_foreign)`, `close_no_control`, `transfer_no_control`, `request_exploration`, `restore_menu`, `reset_stack_on_unload`. Usar exactamente esas; si ADR-0006 difiere, prevalece ADR-0006 y se anota.
- `t_since_started_s` en «terminada» medido con `RealClock` (para la F5 del 21).
- Test con Entrada doble y 21 doble; la prueba con los reales (T-I2) es del épico del Director.

---

## Out of Scope

- AC-X1 / AC-X1b (Entrada y 21 reales): épicos de Entrada y Director.

---

## Files

- `src/scene/scene_loader.gd`
- `tests/unit/scene/scene_loader_input_contract_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/scene_loader_input_contract_test.gd` (T-U6) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-005-load-sequence.md`
- Unlocks: `production/epics/carga-de-planta/story-015-new-game-gray-walk-evidence.md`

---

## Evidencia

- `tests/unit/scene/scene_loader_input_contract_test.gd` (T-U6): 12 tests verdes (apertura con dueño 4 y `absorbs`, recepcion sin `absorbs`, fallo -> `restore_menu` sin cierre, traspaso del 21, `ninguno` desde título y desde planta, `exploracion` una vez, `t_since_started_s` con reloj falso, título sin `reset_stack_on_unload`).
- El código del contrato ya estaba en `src/scene/scene_loader.gd` (CP-005/008/009); no se modificó. `src/input/` sin cambios.
- El tope `D_carga` + margen con línea de log es del router: cubierto en `tests/unit/input/safety_cap_and_loading_test.gd`.
- Suite bloqueante: 951 casos, 0 errores, 0 fallos, 0 orphans, exit 0; sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` y `--boot-report` sin errores.
