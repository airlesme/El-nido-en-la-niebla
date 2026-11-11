# Story 005: Presentación de tarjetas en serie, `sostener_item` y descarga de escena

> **Epic**: Documentos y bolsillo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/documentos-y-bolsillo.md` — § Detailed Rules › C, D (cómo se sostienen); § Formulas (F1)
**Requirement**: `TR-pocket-006`, `TR-pocket-007`, `TR-pocket-008`, `TR-pocket-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (D4 llamadas directas 20 → Jugador); ADR-0012 (`sostener`, `soltar`, `reposo`, `reproducir_gesto`); ADR-0002 (G-1 plazos en `GameClock`)
**ADR Decision Summary**: tras `gesto_terminado(HAND_DRAWER)` 20 presenta cada tarjeta en serie (0,3 + 0,7 + 0,3 = 1,3 s; 2,6 s con dos) sin bloquear el contexto; `sostener_item` devuelve `ACEPTADA` o `RECHAZADA(presentacion_en_curso)`; `HAND_HOLD_ITEM` y `HAND_CARD_SWIPE` nunca coexisten; la descarga cancela sin avisos.
**ADR Version**: ADR-0009 2026-11-10 · ADR-0012 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: firmas de ADR-0012: `sostener(obj_id: StringName, mano: StringName, pose_inspeccion: InspectionPose)`, `soltar()`, `reposo()`, `reproducir_gesto(id, parametros = {})`. Señales `objeto_sujeto`/`objeto_soltado`: tomar sus nombres de ADR-0012 «Key Interfaces»; si no están fijados, ADR-fallback.

**Control Manifest Rules (this layer)**:
- Required: F-R32 (llamada directa solo a subcapa inferior: 20 → Jugador), F-R31, ADR-0002 G-1.
- Forbidden: `Timer`/`create_timer`; reintentar `sostener` tras un rechazo; audio de recompensa o icono «obtenido».
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/documentos-y-bolsillo.md`, scoped to this story:*

- [ ] **AC-06**: con `A05` abierto, `otorgar` presenta `I-02` y luego `I-03` en 2,6 s† sin bloquear el contexto; `reposo()` a t = 1,0 s aborta la presentación y `has_item` de ambas sigue verdadero.
- [ ] **AC-07 / AC-22**: con un gesto bloqueante en curso, el Jugador rechaza `sostener`; 20 registra y no reintenta; el hecho no cambia; si 7 abre una `lectura`, llama `reposo()` antes de `HAND_READ` y 20 da la presentación por abortada sin llamar a `soltar()` ni `reposo()`.
- [ ] **AC-24 / AC-20**: durante la presentación, `sostener_item` (doble de 8) devuelve `RECHAZADA(presentacion_en_curso)`, la presentación termina con `soltar()` y nunca coexisten `HAND_HOLD_ITEM` y `HAND_CARD_SWIPE`; sin presentación → `ACEPTADA`; la presentación nunca empieza antes de `gesto_terminado(HAND_DRAWER)`; sin audio de recompensa ni petición de texto/icono a 24.
- [ ] **AC-15**: con una presentación en curso, la descarga de escena la cancela sin avisos al bus y vacía el conjunto de sesión.

---

## Implementation Notes

- Fases por tarjeta con plazos `GameClock.deadline` (`t_item_dentro`, `t_mostrar_item_s`, `t_item_fuera` de `inventory_config.json`).
- Aborto externo detectado por `objeto_soltado` no propio.
- La captura AC-17 (tarjeta en mano izquierda, gris) se toma en el recorrido M1 con `--write-movie`; la firma de arte queda fuera de M1.

---

## Out of Scope

- Uso de la tarjeta en lectores (épico acceso, fuera de M1). Story 003: escritura de los hechos.

---

## Files

- `src/systems/pocket/card_presentation.gd`
- `tests/integration/pocket/presentacion_tarjetas_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pocket/presentacion_tarjetas_test.gd` (doble del Jugador y de 8, reloj falso) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`; épico `jugador-primera-persona` (manos y gestos)
- Unlocks: `production/epics/acceso-puerta-a-cajon-a05/story-005-cajon-a05.md` (integración completa)
