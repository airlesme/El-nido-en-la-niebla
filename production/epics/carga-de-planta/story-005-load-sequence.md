# Story 005: Secuencia de carga de 9 pasos y orden de configuración

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L — 2 días (1,5–2,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R6, R8–R10 (regla 9: secuencia), § Formulas F3 (N_gap)
**Requirement**: `TR-scene-010`, `TR-scene-011`, `TR-scene-016` (N_gap)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (§ Load sequence, D3, D4, D5; Key Interfaces `GameSceneRoot.configure_all`) · ADR-0001 (avisos y entrega en el fotograma) · ADR-0002 (`GameClock.reset_session()` antes de instanciar; G-11) · ADR-0009 (D6 `bind_scene`/`unbind_scene`)
**ADR Decision Summary**: máquina por fotogramas con fases 1:1 con los 9 pasos: «iniciada» (con `D_carga`) → oscurecer hasta α = 1 → descargar en U (`unbind_scene`, `queue_free`) → instanciar en U+1 vía `SceneSource` (nunca reutilizar la instancia) → `colocar` desde el ancla → `configure_all(ctx)` 7 → 9 → resto, síncrono → «escena lista» (`bind_scene`) → `N_gap` fotogramas → aclarar → «carga de escena terminada» (Lista, zonas activadas).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (orden de liberación)
**Engine Notes**: **Medido en S-0003-A**: la instancia vieja sigue `is_instance_valid` en U y deja de serlo en U+1 (10/10, también con el árbol en pausa); 0 huérfanos; nodos 17 → 17; suscriptores 0 → 0.

**Control Manifest Rules (Core)**:
- Required: C-R02, C-R03, C-R04 (instanciar estrictamente en U+1), C-R05, C-R06 (configurar síncrono o hold con ID), C-R08 (`colocar` desde el ancla)
- Forbidden: C-X01, C-X02, C-X03 (carga en hilo), C-X04 (Player persistente), C-X05
- Guardrail: C-G02

---

## Acceptance Criteria

- [ ] **AC-09 (alcance M1: destino `planta`)**: GIVEN los dobles y un reloj inyectado, WHEN se pide `planta` desde una `planta` cargada, THEN el registro conjunto de cortina, cargador, jugador espía, elementos y bus es exactamente: «iniciada» (con `D_carga`, antes de cualquier cambio de α) → oscurecido hasta α = 1 → descarga → instanciación → «colocar» → `configurar()` → «escena lista» → inicio del aclarado → «carga de escena terminada»; la descarga no empieza hasta α = 1. *(El tramo `recepcion` + «partida terminada» queda fuera de M1.)*
- [ ] **AC-10**: GIVEN `control_final` = `exploracion`, THEN tras «terminada» se emite exactamente una petición de `exploración` y no se emite «partida terminada».
- [ ] **AC-06 + AC-23**: un elemento espía que lee `archivo_abierto` (verdadero en el estado falso) recibe `configurar()` una vez, antes de «escena lista», con el valor verdadero; escrituras en el estado = 0 y lecturas del propio 4 = 0 en `planta`; el orden es 7 → validación de 9 → configuración de 9 → resto; si la validación de 9 falla, no siguen los pasos y se aplica el fallo `invalid_puzzle_data` sin esperar a `T_cap`.
- [ ] **AC-F3 (parte 2)**: GIVEN una carga instantánea a 60 fps (Δ real 1/60 ≠ Δ_ref), THEN el aclarado empieza exactamente `N_gap` = 2 fotogramas después de «escena lista» y el tiempo sin control es 1,6333 ± 0,001 s.

---

## Implementation Notes

- Fases de § Key Interfaces: `IDLE, FADING_OUT, UNLOADING, INSTANTIATING, WAITING_HOLDS, GAP, FADING_IN` (las de descarga total son 009).
- Desde el título (o sin escena) el paso 3 **no** es una descarga (D2): sin reset de pila; lo prueba 006.
- `GameClock.reset_session()` justo antes de `SceneSource.instantiate(destino)`; afirmar que el árbol no está en pausa (G-11).
- Fallo de `configure_all` → la ruta de 008. `GameSceneRoot` real es 012; aquí, doble.

---

## Out of Scope

- 006: llamadas a `InputContexts`; 007: holds y `T_cap`; 008: fallos; 011: `ZoneHub.set_enabled` (aquí basta un espía).

---

## Files

- `src/scene/scene_loader.gd`
- `tests/unit/scene/scene_loader_sequence_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/scene_loader_sequence_test.gd` (T-U2) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-003-curtain-and-dcarga-formulas.md`, `story-004-loader-preconditions-states.md`
- Unlocks: `production/epics/carga-de-planta/story-006-no-control-input-contract.md`, `story-007-holds-and-tcap.md`, `story-008-load-failure-error-state.md`, `story-012-game-scene-root-and-source.md`
