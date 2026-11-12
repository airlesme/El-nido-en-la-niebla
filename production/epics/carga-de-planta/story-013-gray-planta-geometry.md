# Story 013: `planta.tscn` gris — despacho, pasillo y Archivo

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Complete (parcial: AC-04 verificado a nivel de escena; el recorrido real con el cargador es 015)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L — 2 días (1,5–3; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R2–R5 (convención espacial, contenedores, IDs, anclas, zonas), contrato geométrico con el Jugador · `design/slice/slice-v0.3.md` anexos A.1, A.2, A.3, A.4, A.7
**Requirement**: `TR-scene-003`, `TR-scene-004`, `TR-scene-005`, `TR-scene-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D1, D3, D8; § Architecture Diagram «planta root») · ADR-0012 (contrato geométrico: cápsula 0,25 m, paso mínimo 0,60 m) · ADR-0011 (tabla de capas: `world_geometry` 1)
**ADR Decision Summary**: `planta.tscn` con raíz `GameSceneRoot`, su propio `Player`, `ZoneHub` y los contenedores con nombre; metros, X oeste→este, Z sur→norte, Y arriba, origen en el centro del umbral del Despacho de Vera; techo 2,70 m; huecos de puerta 1,00 × 2,10 m.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: **S-0012-C**: puerta de 1,00 m transitable a ancho completo (caminante a 0,2 m del eje pasa); hueco de 0,45 m no (la cápsula se detiene en x = 2,64 con la cara a 2,75). Escena grande ⇒ el tirón de carga se mide en 015 (S-0003-C).

**Control Manifest Rules (Core)**:
- Required: C-R08 (un `Player` por escena), C-R09 (zonas `monitoring = false` en el `.tscn`)
- Forbidden: C-X04 (Player persistente)
- Guardrail: C-G02

---

## Acceptance Criteria

- [ ] **AC-02 (alcance M1, I, PV)**: GIVEN la fixture `floor_layout.json` (copia de A.1 y A.7, **solo** `office`, `corridor`, `archive`), WHEN se mide la caja envolvente de cada contenedor, THEN coincide en X, Z y tamaño ±0,05 m por eje; origen en el centro del umbral de Vera; +X este, +Z norte; techos 2,70 m; cada hueco de puerta 1,00 × 2,10 m ±0,05; una caja que difiera > 5 cm falla.
- [ ] **AC-03 (alcance M1, I)**: GIVEN `element_ids.json` (IDs de A.2–A.4 y del pasillo con su prefijo), WHEN se busca cada ID, THEN existe una sola vez y dentro de su contenedor (`V` → `office`, `A` → `archive`, `C` y `T` → `corridor`).
- [ ] **AC-04 (I)**: GIVEN la planta cargada y ningún fundido pedido, WHEN un jugador de prueba (script que fija su posición) va del despacho al Archivo y vuelve, THEN α = 0,0 en cada fotograma y 0 emisiones de «carga de escena iniciada».
- [ ] **TR-scene-007**: ningún paso de M1 < 0,60 m; las hojas de puerta (A) desactivan colisión al empezar a abrir (lo acciona el sistema 8; aquí, que la hoja esté en una capa/nodo conmutable).

---

## Implementation Notes

- Fixtures en `tests/fixtures/scene/`; la geometría se construye a partir de A.x del slice (fuente de verdad), no se inventan medidas. «El pasillo de S0b si existe» (hito): reutilizarlo si está en el repo.
- `T-PAS-1` (X 9,0–10,0) y las zonas de M1 de los anexos con `ZoneTrigger` (011).
- Contenedores B, D y Recepción fuera de M1: no se crean.

---

## Out of Scope

- 015: capturas y medición de carga; puerta A y cajón A05 animados: épico de Acceso (8).

---

## Files

- `src/scene/planta.tscn` (o `assets/levels/planta.tscn` según `README.md`)
- `tests/fixtures/scene/floor_layout.json`, `tests/fixtures/scene/element_ids.json`
- `tests/integration/scene/floor_layout_test.gd`, `tests/integration/scene/element_ids_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/scene/floor_layout_test.gd` y `tests/integration/scene/element_ids_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-011-zone-hub.md`, `story-012-game-scene-root-and-source.md`, `production/epics/jugador-primera-persona/story-011-player-node-api.md`
- Unlocks: `production/epics/carga-de-planta/story-015-new-game-gray-walk-evidence.md`, `production/epics/jugador-primera-persona/story-013-gray-walk-evidence.md`

---

## Evidencia

- `src/scene/planta.tscn`: raíz `GameSceneRoot`, `Player`, `ZoneHub`, contenedores `office`/`corridor`/`archive` (CSGBox3D con colisión en capa 1), anclas, 4 `ZoneTrigger` (`monitoring = false`), hoja de puerta A conmutable (`archive/door_slot_a/DoorLeaf`). `SceneSource.DEFAULT_PATHS` apunta a `res://src/scene/planta.tscn`; `GameSceneRoot._ready` registra los `ZoneTrigger` en el `ZoneHub`.
- Tests: `tests/integration/scene/floor_layout_test.gd` (11) y `element_ids_test.gd` (4) con `tests/fixtures/scene/{floor_layout,element_ids}.json`: 15/15.
- Suite bloqueante completa: 921 casos, 0 errores, 0 fallos, 0 huérfanos; sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` sin errores; `--boot-report` sin errores.
- Captura del motor (`--write-movie`): `production/qa/evidence/s3-planta/planta-gris-vista-cenital.png` (vista cenital, techos ocultos).
- AC-02, AC-03, TR-scene-007 (hueco de puerta ≥ 0,60 y hoja conmutable): cumplidos. AC-04: solo a nivel de escena (alfa 0 e 0 «scene_load_started» con un jugador de prueba movido por script, sin cargador cableado); el recorrido real con el cargador queda para 015.
- TODO(level-design) en el `.tscn`: A05 rotado (1,20 cruzaba el muro este), V05 movido a X −3,3 (estaba fuera del escritorio), bolsillo de 0,475 m entre el armario V-MOB-3 y el muro norte (sin paso: callejón), Y/X de la persiana V-MOB-4, coordenadas propuestas de T-D-OUT y T-OFI-IN.
