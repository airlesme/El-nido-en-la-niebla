# Story 001: `access.json` — esquema completo, datos M1 (A, A05) y política de fallo

> **Epic**: Acceso — puerta A y cajón A05
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/control-de-acceso.md` — § Detailed Rules › Catálogo y datos; § Tuning Knobs
**Requirement**: `TR-access-001`, `TR-access-002`, `TR-access-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (D1, D2, D3 tres niveles de validación, D5, G-8 política de release, G-13, G-16); ADR-0001 (`LogSink`/`ErrorPolicy` para la detención en desarrollo)
**ADR Decision Summary**: `assets/data/access/access.json` se lee por `DataReader` con esquema `doors[]`/`readers[]`/`drawers[]`/`elevator`, validado en carga y en CI; en desarrollo un dato inválido detiene, en build final falla abierto con una línea de registro.
**ADR Version**: ADR-0005 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: S-0005-A: claves duplicadas de objeto → gana la última en silencio (los IDs van en arrays: el duplicado de `id` sí se detecta); coma final aceptada salvo precomprobación de `JsonText`; BOM quitado en silencio → comprobación sobre bytes en `DataReader`. A7/A9/A10 verificados en export de release: los `.json` llegan al build (G-14).

**Control Manifest Rules (this layer)**:
- Required: ADR-0005 G-1, G-4, G-6, G-7, G-8, G-13 (reunir todos los fallos, con fichero y ruta); F-R09 (logs por `LogSink`, detención por `ErrorPolicy`).
- Forbidden: valores (tiempos, ángulos, LED, IDs) en código.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/control-de-acceso.md`, scoped to this story:*

- [ ] **AC-12**: un `access.json` con ancla, hecho o lector inexistente → en desarrollo error visible; en build final la puerta afectada nace `ABIERTA`, se registra una línea y no falla la carga; el CI marca la build rota. `t_ascensor_s` inválido → 2,0 s con registro; `drawers[]` inválido → `A05` `CERRADO` con valores por defecto.
- [ ] **TR-access-002**: con un fixture completo, el CI valida el mapa fijo (`C06`→`tarjeta_B`/`I-02`; `C07`, `D06`→`tarjeta_D`/`I-03`); ID repetido o hecho inexistente = dato inválido. El fichero M1 pasa con `readers[]` vacío.
- [ ] El fichero M1 contiene la puerta A (`archivo_abierto`, `ANIM_DOOR_OPEN` 1,2 s, 90°, hueco 1,00 × 2,10 m) y el cajón `A05` (`t_cajon_tope_s` 3,0, tarjetas `I-02`, `I-03`).

---

## Implementation Notes

- Decisión registrada en `stories.md` de este épico: esquema completo, datos solo A/A05.
- Distinción desarrollo/release por `BuildFlavor` (existe esqueleto en `src/core/data/build_flavor.gd`; no inventar su API: si no la fija ADR-0005/0009, ADR-fallback).

---

## Out of Scope

- Story 002: uso de los datos en la configuración.

---

## Files

- `assets/data/access/access.json`
- `src/world/access/access_data.gd` (esquema en el `DataCatalog`)
- `tests/unit/access/datos_access_test.gd` (+ fixtures en `tests/unit/access/fixtures/`)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/access/datos_access_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/EPIC.md` (`DataReader`, `DataCatalog`, verificador de CI; historias aún sin crear)
- Unlocks: `production/epics/acceso-puerta-a-cajon-a05/story-002-configuracion-al-arrancar.md`
