# Story 003: Capas físicas y `OcclusionProbe` (`intersect_ray`)

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Done
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Formulas › F1 (paso 2, oclusión con tolerancia); § Core Rules, regla 5
**Requirement**: `TR-interact-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D1, D4, G-2)
**ADR Decision Summary**: la única consulta física de 7 es un `intersect_ray` por contacto superviviente con `collision_mask` = bit 1 (`world_geometry`), excluyendo los `self_occluders`; ocluido si `(hit − ojo)·u < d_c − desempate_prof_m`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (Jolt por defecto desde 4.6; márgenes de colisión)
**Engine Notes**: S-0011-B medido: error de profundidad peor 8,3e-7 m (60°); `query.exclude: Array[RID]` salta el cuerpo; bit 1 ignora bits 2–5. **Un rayo que nace dentro de un sólido no golpea** (`hit_from_inside` = false por defecto en 4.7.2, devuelve `{}`): es un fallo de oclusión por diseño y **no** se activa `hit_from_inside` (FE-R02). S-0011-A (c): `layer_names/3d_physics/layer_3` **no está definido** en `project.godot` → esta historia los añade.

**Control Manifest Rules (this layer)**:
- Required: FE-R01 (solo `intersect_ray`, máscara bit 1, detrás de `OcclusionProbe`), FE-R02, FE-R04.
- Forbidden: FE-X01, FE-X02; máscara de oclusión con bits 2–5.
- Guardrail: ≤ `max_contactos_por_paso` (8) rayos por paso (FE-G01).

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-03**: con una pared entre la cámara y un objeto a 1,0 m, no hay objetivo.
- [ ] **AC-04c (parte de oclusión)**: `B05` plana a 1,50 m sobre una mesa que corta el segmento a 1,499 m **no** está ocluida; con una pared a 1,0 m, sí.
- [ ] `project.godot` nombra las capas 1–5 de D1 (`world_geometry`, `player_body`, `interactable`, `zone_sensor`, `zone_trigger`) y una prueba lo comprueba; la constante `OCCLUSION_MASK = 1 << 0`.
- [ ] Un contacto cuyo segmento ojo→punto nace dentro de geometría se trata como no ocluido por ese rayo (comportamiento medido, documentado en la prueba).

---

## Implementation Notes

*Derived from ADR-0011 D1/D4:*

- `PhysicsOcclusionProbe` envuelve `PhysicsRayQueryParameters3D.create(eye, c.contact_point)`, `collision_mask = _config.mascara_geometria`, `exclude = c.excluded_rids`, `_space.intersect_ray(q)`. `AnalyticOcclusionProbe` para las pruebas unitarias (planos/cajas analíticas).
- `d_g` se mide a lo largo del eje (`dot(u)`), comparable con `d_c`.
- Más contactos que `max_contactos_por_paso`: se ignoran en orden de registro y se registran una vez por escena en debug.
- Pruebas de motor reales (mundo de física headless) junto a las de `tests/unit/engine_facts/adr0011_ray_occlusion_test.gd` como referencia, no como sustituto.

---

## Out of Scope

- Story 004: agrupación y desempate tras la oclusión. Lint de escena de volúmenes (T-S3): en 005.

---

## Files

- `project.godot` (nombres de capas 3D)
- `src/interaction/ports/occlusion_probe.gd`, `src/interaction/physics_occlusion_probe.gd`
- `tests/unit/interaction/oclusion_test.gd` (con `AnalyticOcclusionProbe`) y `tests/unit/interaction/oclusion_fisica_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/oclusion_test.gd` y `oclusion_fisica_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-002-pick-registry-y-pickmath.md`
- Unlocks: `production/epics/interaccion-y-prompt/story-004-focus-selector.md`

---

## Evidencia

- `tests/unit/interaction/oclusion_test.gd` (analítica, 11 casos: AC-03, AC-04c, borde de tolerancia, ojo dentro de sólido, RID excluido, máx. contactos, nombres de capa y `OCCLUSION_MASK`) y `oclusion_fisica_test.gd` (Jolt real, 6 casos, sin asertar plataforma): todos pasan en la suite completa (la ejecución aislada de `tests/unit/interaction` previa a corregir un fixture mío no mostró fugas).
- Suite bloqueante completa: 573 casos, 1 fallo ajeno (`tests/unit/content/data_validator_test.gd::test_registry_lists_m1_rows_in_fixed_order`: CP-002 añadió `scene/load_transitions.json` al registro). Los avisos `ObjectDB instances were leaked` / `resources still in use` aparecen en la suite completa pero no en la ejecución aislada de `tests/unit/interaction`; no son de esta historia.
- Capas 3D nombradas en `project.godot` (`[layer_names]`, 1–5 de D1). `ContactInfo.excluded_rids` añadido; `PickRegistry` resuelve `self_occluders` a RIDs (cierra `TODO(IP-003)`).
