# Historias — Épico «Marco de puzles y puzle 1 (Cronología)»

> **Épico**: `production/epics/puzles-marco-y-p1/EPIC.md` · **Capa**: Feature · **Hito**: M1
> **GDD**: `design/gdd/marco-de-puzles.md` (9) · `design/gdd/puzle-1-cronologia.md` (11)
> **Manifest Version**: 2026-11-11b · **workflow**: standard · **story_granularity**: balanced (2–4 AC) · **docs.density**: balanced
> **Generado**: 2026-11-11 por `/create-stories` (automation: autonomous)
> **Revisión**: QL-STORY-READY skipped — Lean mode

ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0003 Accepted · ADR-0004 **Proposed** · ADR-0005 Accepted ·
ADR-0006 Accepted · ADR-0007 **Proposed** · ADR-0008 **Proposed** · ADR-0009 Accepted · ADR-0010 Accepted ·
ADR-0011 Accepted · ADR-0015 **Proposed** · ADR-0017 Accepted

Estimaciones en días de una persona; **confianza BAJA** en todas: no hay historial de sprints
(`production/sprints/` vacío), los spikes V1–V5 de ADR-0010 no se han ejecutado y el esqueleto de
`GameClock` aún no expone `deadline`/`is_due`/`schedule` (ADR-0002 § Key Interfaces).

## Historias

| ID | Título | Tipo | Est. (d) | Depende de | Estado |
|----|--------|------|----------|------------|--------|
| 001 | Carga y validación de `puzzles.json` v2 (entrada P1) | Logic | 1,5 | estado-y-bus, contenido-y-datos (DataReader/ContentDB) | Ready |
| 002 | Contrato `PuzzleController` y `Verdict` | Logic | 1,0 | — | Ready |
| 003 | `Puzzle1Controller`: colocación, tabla R13 y `evaluate()` puro | Logic | 1,5 | 002 | Ready |
| 004 | Estados públicos, configuración síncrona y registro de vista `C05` | Integration | 1,5 | 001, 002 | Ready |
| 005 | Política `DELAYED_AFTER_CHANGE` 0,6 s y cancelación con `GameClock` | Logic | 1,0 | 003, 004 | Ready |
| 006 | Rechazo uniforme: bloqueo 1,5 s, vibración 1,2 s, reinicio sin penalización | Logic | 1,5 | 005 | Ready |
| 007 | Resolución `IMMEDIATE`: orden de escritura y `EV_PUZZLE_SOLVED_P1` | Logic | 1,0 | 005 | Ready |
| 008 | Material de la vista: `elements()`, `compose_i01()` y sin `I-01` | Integration | 1,5 | 003, 004; ordenador-e-impresora/story-003 | Ready |
| 009 | Geometría de `p1_view.json` y zonas de atracción | Logic | 0,5 | 001 | Ready |
| 010 | Panel P1 en gris: presentación, vibración y captura | Visual/Feel | 1,5 | 006, 007, 008, 009 | Ready |
| 011 | Puerta A tras resolver y `C05` fuera de objetivo | Integration | 1,0 | 007; acceso-puerta-a-cajon-a05 (puerta A) | Ready |
| 012 | Oráculo de 1.000 secuencias y fallo repetido ×5 | Logic | 1,5 | 006, 007, 008 | Blocked |

**Orden recomendado (camino crítico en negrita):** **001 → 002 → 003 → 004 → 005 → 006 → 007** → 008 → 009 → 010 → 011 → 012.
Total: 15,0 d (esperado; optimista ≈ 11, pesimista ≈ 20 con un spike V1–V5 fallido).

## Diferido (sin historia: su ADR es Proposed o está fuera de M1)

| Requisito / AC | Motivo | Desbloqueo |
|----------------|--------|------------|
| GDD 11 AC-14, GDD 9 AC-39b (cargar partida con `correos_leidos` y reimprimir), parte «guardar y cargar» de AC-12/AC-36 | ADR-0004 (guardado) **Proposed** | aceptar ADR-0004 |
| GDD 11 AC-17, GDD 9 AC-52 (`reducir_movimiento` en el rechazo) | lectura vía `SettingsReader` de ADR-0007 **Proposed** | aceptar ADR-0007 |
| TR-puzzles-013 (pasos `LINE`) | ADR-0008 **Proposed**; solo afecta a P5 | aceptar ADR-0008 |
| GDD 11 AC-PV5, parte 16:10 | escalado de UI de ADR-0007 **Proposed** | aceptar ADR-0007 |
| TR-puzzle1-016, GDD 11 AC-13 (pistas de P1) | **recorte 2 de M1** → M2 (no es un bloqueo de ADR) | M2 |
| TR-puzzles-012, -019, -022 y AC de P2–P6 | fuera del alcance M1 (solo marco + P1) | M2+ |

## Decisiones tomadas (autonomous)

1. **Dependencias de ADR por historia, no por ADR.** ADR-0010 (Accepted) declara `depends_on` ADR-0004
   (Proposed). La regla de la skill bloquearía todo el épico; se aplica solo a las historias que
   ejercitan esa dependencia (guardar/cargar), que quedan en «Diferido». *Descartado:* bloquear las
   12 historias — contradice el estado LISTO del épico y el Ordering Note de ADR-0010, que solo
   exige ADR-0011 para las historias de vista.
2. **TR-puzzle1-018 (oráculo) NOT ASSESSED.** No tiene ADR en el registro. Se propone trazarlo a
   ADR-0010 § Validation Criteria **T-I6** (`solvability_oracle_test.gd`, que ya cubre TR-puzzles-021)
   y ubicar el código así: arnés compartido `tests/helpers/puzzles/solvability_oracle.gd`,
   prueba de P1 `tests/unit/puzzle_1/p1_solvability_oracle_test.gd` (la ruta que fija el GDD 11),
   semilla fija. Historia 012 en Blocked hasta que `tr-registry.yaml` lo trace.
3. **Hojas fuera de alcance**: las pistas de P1 no generan historia (recorte 2 ya aplicado en el
   hito); no se escriben historias de P2–P6.
4. **EPIC.md e `index.md` no se tocan en esta pasada**: el encargo nombra como salida solo las
   historias y este índice; actualizar la tabla Stories de `EPIC.md` queda para la próxima
   reconciliación.
