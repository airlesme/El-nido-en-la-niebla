# Story 009: Vista cercana — ciclo de vida, cesión de cámara y token

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 19, 23, 30; § Formulas › F4
**Requirement**: `TR-interact-013`, `TR-interact-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D6 `abrir_vista(id, desde_token)`, transferencia del token sin `end_blocking`); ADR-0012 (`ceder_camara`/`devolver_camara`, señales `camara_cedida`/`camara_devuelta`); ADR-0006 (bloqueo con tope 3 s)
**ADR Decision Summary**: una vista pasa Cerrada → Entrando → Abierta → Saliendo; 7 pide `ceder_camara(&"interaccion:vista", pose, fov, t_vista_entrada_s)` y abre al recibir `camara_cedida` del mismo propietario; el token del dueño se transfiere a la transición de cámara sin hueco en `exploración`.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0012 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: firmas de ADR-0012: `ceder_camara(propietario: StringName, pose_destino: CameraPose, fov_destino_deg: float, duracion_s: float)`, `devolver_camara(propietario: StringName)`. La curva y la pose final son del Jugador (AC-20 del GDD 2), no de 7.

**Control Manifest Rules (this layer)**:
- Required: FE-R05; F-R32 (llamadas directas solo a subcapa inferior: 7 → Jugador por `ctx`).
- Forbidden: FE-X04; temporizador propio de auto-salida en 7.
- Guardrail: `T_cadena` ≤ 2,8 s (`BOX_OPEN_MAX` 1,6 + `t_vista_entrada_s` ≤ 1,2).

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story (con receptor y dueño de prueba; `D01a` como ID de prueba):*

- [ ] **AC-26**: 7 pide `ceder_camara("interaccion:vista", anclaje, 70°, 1,0 s)`; `camara_cedida` del mismo propietario → Abierta y `on_open()`; otro propietario se ignora; un doble que nunca avisa → contexto liberado a 3 s, vista Abierta y error registrado.
- [ ] **AC-26b**: con un dueño que llama `bloquear_contexto`, anima 1,6 s y `abrir_vista(id, desde_token)`, el contexto está bloqueado en todos los pasos hasta la primera acción aceptada (2,6 s con 1,0 s de cámara; 2,8 s con 1,2 s sin liberación por tope); `abrir_vista` rechazada con token deja el token vigente.
- [ ] **AC-27 / AC-27b**: al abrir se emite una vez «vista cercana abierta» (`close_view_opened`), cursor al centro; `abrir_vista` con otro modo, sin receptor o fuera de `exploración` sin token → `RECHAZADA(motivo)` sin cesión; `cerrar_vista` sobre vista no abierta → advertencia.
- [ ] **AC-31 / AC-31b / AC-27d**: `atrás` con la vista abierta → `devolver_camara` y `reposo()`, contexto bloqueado hasta `camara_devuelta`, entonces «vista cercana cerrada» (`jugador`) y `exploración`; `atrás` en Entrando/Saliendo se ignora; `cerrar_vista(resuelto)` sigue el mismo orden; `cerrar_vista(sistema)` en Entrando espera a `camara_cedida`; `atrás` + `cerrar_vista(resuelto)` en el mismo paso = un solo cierre.

---

## Implementation Notes

*Derived from ADR-0011 D6 y GDD regla 19/23:*

- La pose y `fov_destino` salen del bloque `vista` del catálogo (`anclaje`, `distancia_m`); nada codificado.
- En M1 la única vista real es el panel de P1 (épico puzles-marco-y-p1); el ciclo se prueba aquí con dobles.

---

## Out of Scope

- Story 010: contrato `ViewReceiver` y cancelaciones. Story 011: picking. Story 012: modo ordenador.

---

## Files

- `src/interaction/close_view_controller.gd`
- `tests/unit/interaction/vista_cercana_ciclo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/vista_cercana_ciclo_test.gd` — must exist and pass (dobles del Jugador y del router, reloj falso).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md`, `production/epics/interaccion-y-prompt/story-008-pila-de-modos-y-lectura.md`; épico `jugador-primera-persona` (cesión de cámara)
- Unlocks: `production/epics/interaccion-y-prompt/story-010-view-receiver-y-cerrar-modos.md`, `production/epics/interaccion-y-prompt/story-012-modo-ordenador.md`
