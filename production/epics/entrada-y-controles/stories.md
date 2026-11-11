# Historias — Épico: Entrada y controles

> **Épico**: `production/epics/entrada-y-controles/EPIC.md` · **GDD**: `design/gdd/entrada-y-controles.md` (1)
> **Generado**: 2026-11-11 por `/create-stories` (modo autonomous, `review_mode: lean` → QL-STORY-READY omitido)
> **Manifest Version**: 2026-11-11b · **Granularidad**: balanced (2–4 CA por historia)
> **ADRs**: ADR-0006 Accepted · ADR-0001 Accepted · ADR-0002 Accepted · ADR-0003 Accepted · ADR-0005 Accepted · ADR-0009 Accepted · ADR-0011 Accepted · ADR-0007 **Proposed** · ADR-0016 **Proposed**
> **Estimaciones**: días-persona, **confianza BAJA** (no hay velocidad medida). S ≈ 0,5 d · M ≈ 1 d · L ≈ 2 d. Riesgo de motor HIGH (4.7: `DEVICE_ID_*`, SDL3, foco dual): las pruebas con mando físico son NEEDS_MANUAL.

| ID | Título | Tipo | Est. | Días | Depende de | Estado |
|----|--------|------|------|------|------------|--------|
| [001](story-001-input-types-and-binding-table.md) | `InputTypes`, `BindingTable` y `default_bindings.json` | Logic | M | 1,5 | estado-y-bus 001, contenido-y-datos 002 y 003 | Ready |
| [002](story-002-engine-input-adapter.md) | `EngineInputAdapter` → `RawInput` y `feed()` | Logic | M | 1 | 001 | Ready |
| [003](story-003-context-stack-and-sinks.md) | Pila de contextos, sinks y `input_context_changed` | Logic | M | 1 | 002, estado-y-bus 004 | Ready |
| [004](story-004-no-control-operations.md) | Operaciones de `sin control` y puerto `InputContexts` | Logic | M | 1 | 003 | Ready |
| [005](story-005-safety-cap-and-loading-state.md) | Tope de seguridad con `GameClock`, `carga_en_curso` y reinicio de pila | Logic | M | 1 | 004 | Ready |
| [006](story-006-blocking-transitions-and-pocket-review.md) | Transiciones bloqueantes y `repasar_bolsillo` | Logic | M | 1 | 003, 005 | Ready |
| [007](story-007-device-tracker-hysteresis.md) | Dispositivo activo con histéresis F7 y aviso de cambio | Logic | M | 1 | 002, estado-y-bus 004 | Ready |
| [008](story-008-move-and-look-formulas.md) | Movimiento y mirada: F1, F2, F3 | Logic | M | 1 | 002, 003 | Ready |
| [009](story-009-virtual-cursor.md) | Cursor virtual F5a/F5b y `PointerTargetProvider` | Logic | M | 1 | 008 | Ready |
| [010](story-010-gesture-recognizer.md) | Reconocedor de gestos F6 (`agarrar`/`mantener`/`seleccionar`) | Logic | M | 1 | 009 | Ready |
| [011](story-011-interact-short-long-verb.md) | `interactuar`: verbo corto / largo y cancelación | Logic | M | 1 | 003, 006 | Ready |
| [012](story-012-text-field-precedence.md) | Precedencia del campo de texto en `ordenador` (`es_imprimible`) | Logic | S | 0,5 | 003 | Ready |
| [013](story-013-binding-labels.md) | `get_binding_label` y familia de mando | Logic | S | 0,5 | 001, 007 | Ready |
| [014](story-014-pause-triggers.md) | Disparadores de pausa (`pause_requested`) | Integration | M | 1 | 005, 007 | Ready |
| [015](story-015-boot-wiring-and-manual-session.md) | Composición en `Boot` y sesión manual teclado + mando | Integration | M | 1 | 001–014 | Ready |

**Total**: 15 historias (13 Logic, 2 Integration) · ≈ 14 días-persona · 15 Ready, 0 Blocked.
**Camino crítico**: (estado 001, contenido 001–003) → 001 → 002 → 003 → 004 → 005 → 006 → 011 → 015. Jugador (`get_move_vector`, `consume_look_delta`) necesita 008; interacción necesita 006, 010 y 011; ordenador necesita 009 y 012.

## Diferido / bloqueado por ADR

| Requisito / CA | Bloqueado por | Motivo |
|---|---|---|
| TR-input-015 (reasignación, validador de conflictos): AC-15, AC-16 (intercambio), AC-17, AC-E5, AC-E10 (2.ª cláusula) | ADR-0007 (Proposed) | La reasignación se persiste en el bloque `controles` de Ajustes y se aplica por `settings_applied` (ADR-0006 Depends On); además, recorte 7 del hito |
| TR-input-016 (exportar/importar el bloque): AC-18, AC-19 (2.ª mitad) | ADR-0007 (Proposed) | Ídem; la carga de `default_bindings.json` sí entra (001) |
| TR-input-019 (alternar en lugar de mantener, `t_hold` hasta 1,5 s): AC-14 | ADR-0007 (Proposed) | Es un ajuste de manejo de 6; sin ajustes, el valor por defecto (mantener) de 010/011 |
| Ajustes de sensibilidad/inversión desde Ajustes (`get_handling_settings`/`set_handling_setting`) | ADR-0007 (Proposed) | Los valores por defecto salen de `default_bindings.json` (001) |
| Capa de cursor dibujada, atlas de glifos y colores de foco: AC-12 (V), AC-E18 (V), parte V de AC-03/AC-10 | ADR-0016 (Proposed) | HUD/UI; la lógica (posición, visibilidad, `glifo_id`) sí entra (009, 013) |

**Fuera por alcance del hito (no por ADR):** F4 `rotar` y AC-11/AC-F4 (rotación en inspección, recorte 6 → M2); menú de pausa (GDD 25, recorte 5) — aquí solo la señal `pause_requested` (014).

## Decisiones tomadas (modo autonomous)

- **ADR-0006 `depends_on` incluye ADR-0007 (Proposed).** La regla de `/create-stories` bloquearía todo el épico. La dependencia es solo por el nombre `settings_applied` y el bloque `controles` (ADR-0006 § ADR Dependencies, l. 88); las historias que no tocan esa interfaz quedan **Ready** y las que sí, diferidas arriba. *Descartado:* bloquear el épico entero — dejaría sin entrada a todo M1 por una interfaz de un recorte.
- **Lógica del cursor sin ADR-0016:** el rectángulo lógico 1920×1080 de referencia lo fija ADR-0006 D9 y ADR-0011 C1 (Accepted); bajo `expand` es NEEDS_WINDOWED (ADR-0011) y se verifica en 015.
