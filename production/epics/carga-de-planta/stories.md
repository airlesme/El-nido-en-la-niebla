# Historias — Épico «Carga de planta (despacho, pasillo, Archivo)»

> **Épico**: `production/epics/carga-de-planta/EPIC.md` · **GDD**: `design/gdd/escena-de-planta.md`
> **Generado**: 2026-11-11 por `/create-stories` (modo `autonomous`, `workflow: standard`, `story_granularity: balanced`, `docs.density: balanced`, `qa.level: standard`)
> **Manifest Version**: 2026-11-11b · **ADR Version** (todas): 2026-11-10
> **Review**: QL-STORY-READY skipped — Lean mode
> **Estimaciones**: días de una persona, **confianza BAJA** (sin historial de sprints ni velocidad; no calibradas).

## Estado de los ADR (comprobado con `## Status` y `.claude/scripts/adr-status.sh`, 2026-11-11)

ADR-0003 Accepted · ADR-0009 Accepted · ADR-0001 Accepted · ADR-0002 Accepted · ADR-0005 Accepted · ADR-0012 Accepted · ADR-0006 Accepted (contrato `InputContexts`) · ADR-0011 Accepted (tabla de capas) · **ADR-0008 Proposed** · ADR-0016 Proposed (no se usa: `ErrorPanel` se rige por ADR-0003)

## Historias

| ID | Título | Tipo | Est. (días, BAJA) | Depende de | Estado |
|----|--------|------|-------------------|------------|--------|
| 001 | [`Shell`, `WorldSlot`, telón y capas](story-001-shell-worldslot.md) | Integration | 1 (0,5–1,5) | — | Ready |
| 002 | [`load_transitions.json` y su validación](story-002-load-transitions-data.md) | Logic | 0,5 (0,5–1) | — (cargador de ADR-0005) | Ready |
| 003 | [Fórmulas del telón (F1) y `D_carga` (F3)](story-003-curtain-and-dcarga-formulas.md) | Logic | 0,5 (0,5–1) | 002 | Ready |
| 004 | [`SceneLoader`: precondiciones y estados](story-004-loader-preconditions-states.md) | Logic | 1 (0,5–1,5) | 001 | Ready |
| 005 | [Secuencia de carga de 9 pasos y orden de configuración](story-005-load-sequence.md) | Logic | 2 (1,5–2,5) | 003, 004 | Ready |
| 006 | [Contrato `sin control` con Entrada](story-006-no-control-input-contract.md) | Logic | 1 (0,5–1,5) | 005 | Ready |
| 007 | [Retenciones y `T_cap` en tiempo real](story-007-holds-and-tcap.md) | Logic | 1 (0,5–1,5) | 005 | Ready |
| 008 | [Fallo de carga y estado Error](story-008-load-failure-error-state.md) | Logic | 1 (1–1,5) | 005, 007 | Ready |
| 009 | [Descarga total](story-009-full-unload.md) | Logic | 1 (0,5–1,5) | 008 | Ready |
| 010 | [Aviso de escena obsoleta](story-010-stale-scene-warning.md) | Logic | 0,5 (0,5–1) | 004 | Ready |
| 011 | [`ZoneHub` y `ZoneTrigger`](story-011-zone-hub.md) | Integration | 1 (0,5–1,5) | — | Ready |
| 012 | [`GameSceneRoot` y `SceneSource` real](story-012-game-scene-root-and-source.md) | Integration | 1 (1–1,5) | 005 | Ready |
| 013 | [`planta.tscn` gris: despacho, pasillo y Archivo](story-013-gray-planta-geometry.md) | Integration | 2 (1,5–3) | 011, 012; jugador 011 | Ready |
| 014 | [`ErrorPanel` sobre el telón](story-014-error-panel-ui.md) | UI | 0,5 (0,5–1) | 001, 008, 009 | Ready |
| 015 | [Partida nueva hasta la planta gris: capturas y S-0003-C](story-015-new-game-gray-walk-evidence.md) | Visual/Feel | 1,5 (1–2) | 006, 013, 014 | Ready |

**15 historias: 9 Logic (002–010), 4 Integration (001, 011, 012, 013), 1 UI (014), 1 Visual/Feel (015), 0 Config/Data; 0 Blocked.** Total ≈ 15,5 días (rango 11–22).

Orden recomendado: 001 → 002 → 003 → 004 → 005 → 007 → 008 → 006 → 009 → 010 → 011 → 012 → 013 → 014 → 015.

## Diferido / bloqueado por ADR (no se escriben historias)

| Qué | TR | ACs del GDD | Bloqueado por | Nota |
|-----|----|-------------|---------------|------|
| Recarga completa: instancia nueva en cada petición de `planta`; huérfanos y suscriptores a valor de arranque tras ciclos | TR-scene-009 | AC-08, AC-16c | **ADR-0008** (Proposed) | S-0003-A ya lo probó a nivel de motor (`tests/unit/engine_facts/adr0003_instantiate_free_orphans_test.gd`); 005 implementa «nunca reutilizar la instancia» como parte de la secuencia (TR-scene-010) pero el test T-I3 de ciclos queda aquí |
| Descarga total: voz de 23 descartada | TR-scene-019 (parte) | AC-16d (parte de 23) | **ADR-0008** (Proposed) | 009 cubre la parte de 4; la de 23 al aceptarse ADR-0008 |

### Fuera de alcance M1 (ADR Accepted, pero Recepción, título, guardado o 21 real fuera de M1)

| Qué | TR | ACs | Motivo |
|-----|----|-----|--------|
| «Partida terminada» tras «terminada» de `recepcion` | TR-scene-020 | AC-09 (último tramo), AC-20 | Recepción fuera de M1. 005 deja el punto de extensión; sin `recepcion.tscn` |
| Jugador en `spawn_elevator`; jugador tras cierre durante carga de Recepción | TR-scene-005 (parte), TR-scene-010 | AC-11b, AC-17 | Recepción y guardado (recorte 4) fuera de M1 |
| `reanudar` (con y sin llamada pendiente) | TR-scene-008 (parte) | AC-11a (partes `reanudar`) | Guardado recortable (recorte 4) |
| Integración con Entrada y Director reales | TR-scene-017 | AC-X1, AC-X1b, AC-01 (parte 1/6/23) | Se cierran en los épicos de Entrada (ADR-0006) y Director (ADR-0017, T-I2 de ADR-0003) |
| Salas B y D, Recepción en `floor_layout.json` / `element_ids.json` | TR-scene-003/004 | AC-02, AC-03 (partes B, D, R) | Fuera de M1; las fixtures de 013 cubren despacho, pasillo y Archivo |

## Decisiones tomadas (modo autónomo)

- **`setup` de `SceneLoader`**: ADR-0003 firma `setup(ctx, source, curtain, input, clock, transitions)`; el esqueleto y ADR-0009 D2 usan `setup(ctx)`. Se decide **conservar `setup(ctx)`** (contrato de composición de ADR-0009, ya en `boot.gd`) y obtener los colaboradores por `ctx.require`; los dobles de test se inyectan igual por el contexto. Se registra como enmienda pedida a ADR-0003 (004).
- **Recepción**: las ramas de precondición de `recepcion` (rechazo con `llamada_completada` falso, `planta` desde `recepcion`) entran en 004 porque son una línea de la misma comprobación; la escena y «partida terminada» no.
- **Título en M1**: no hay título (GDD 27 fuera); la descarga total (009) instancia un `title.tscn` **mínimo de marcador** para cerrar el ciclo de «Volver al título» que exige C-M1-3. No es la pantalla de título.
- **`ErrorPanel`** (014) se rige por ADR-0003 (D5, Implementation Guidelines); no usa la pila de texto/capas de ADR-0016 (Proposed): `Label` por defecto, texto desde datos.

## Riesgos y notas del productor

- **Alcance vs. plazo (escalado)**: ver `production/epics/jugador-primera-persona/stories.md` § Riesgos: ambos épicos suman ≈ 28 días-persona.
- **S-0003-C** (tirón de carga síncrona) se mide en 015; si supera ~1 s en `REF-1`, ADR nuevo sobre D4 (manifiesto P-21).
- Capas de colisión sin nombre en `project.godot` (manifiesto P-23): 011 y 013 dependen de la historia de capas de ADR-0011.
- `EPIC.md` no es UTF-8 válido: su tabla «Stories» no se actualizó desde esta ejecución (Edit lo rechaza). Este índice la sustituye hasta convertirlo.
