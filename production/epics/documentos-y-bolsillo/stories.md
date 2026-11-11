# Historias — Documentos y bolsillo (sistema 20)

> **Generado**: 2026-11-11 por `/create-stories` (modo `autonomous`, `review_mode: lean`)
> **Manifest Version**: 2026-11-11b · **Workflow**: standard · **Granularidad**: balanced
> **ADRs**: ADR-0009 Accepted · ADR-0001 Accepted · ADR-0005 Accepted · ADR-0002 Accepted · ADR-0011 Accepted · ADR-0012 Accepted · ADR-0016 **Proposed** · ADR-0004 **Proposed**
> **QL-STORY-READY**: omitido — modo Lean
> **Estimaciones**: días de una persona, confianza **BAJA** (sin historial de sprints).

| ID | Título | Tipo | Est. (días) | Depende de | Estado |
|----|--------|------|-------------|------------|--------|
| 001 | Catálogo `items.json` + `inventory_config.json` y esquema | Logic | 0,5 (0,5–1) | épico contenido-y-datos | Ready |
| 002 | `has_item` derivado de hechos y conjunto de sesión (`I-01`) | Logic | 1 (0,5–1,5) | 001; épico estado-y-bus | Ready |
| 003 | Escritor único: `formulario_leido`, `otorgar("A05")` → `tarjeta_B`, `tarjeta_D` | Logic | 1 (0,5–1,5) | 002; interacción 008 | Ready |
| 004 | Tapa `A03` (DELEGAR) y habilitado de `A04` | Integration | 1 (0,5–1,5) | 003; interacción 007 | Ready |
| 005 | Presentación de tarjetas en serie, `sostener_item` y descarga de escena | Integration | 1,5 (1–2,5) | 003; épico jugador-primera-persona | Ready |
| 006 | Repaso del bolsillo (`repasar_bolsillo`) y pista única de sesión | Integration | 1,5 (1–2) | 003; interacción 008 | Ready |

**Total Ready**: 6 historias · 6,5 días esperados (rango 4–10) · 0 Blocked.

## Diferido / bloqueado por ADR

| Qué | TR / AC | Bloqueado por | Salida |
|-----|---------|---------------|--------|
| Pantalla de lectura `ReadingScreen` (dibujo del documento con su estilo, en `HUD`) y su captura **C-M1-7 «Archivo»** (formulario `A04`), AC-13 y AC-16 (parte dibujada) del GDD 20, AC-V5 del GDD 7 | TR-pocket-011 | **ADR-0016** (Proposed): su tabla «Blocks» incluye «UI parts of 20 (reading screen)» | aceptar ADR-0016; luego una historia UI con captura `--write-movie` |
| Pista `UI_BOLSILLO_AYUDA` **visible** (pie de 24) | TR-pocket-018 (parte visible) | **ADR-0016** | 006 la solicita por el puerto `PromptSink` de 7; el dibujo llega con 24 |
| AC-08 (puerta B cerrada al cargar y la tarjeta la reabre) y AC-05 «se carga la partida» con guardado real | — | **ADR-0004** (Proposed) + puertas B/D fuera de M1 | recorte 4 (guardado → M2); 002 prueba con `restore` de instantánea de 3 |

> **Discrepancia a corregir en `EPIC.md`**: el épico dice «18/18 TR libres», pero TR-pocket-011
> (pantalla de lectura) cae bajo ADR-0016 según su propia tabla «Blocks». Se trata aquí como
> diferido; `/architecture-review` debe añadir ADR-0016 a la fila de TR-pocket-011.

## Fuera del alcance de M1 (no por ADR)

- Ítems `I-05`, `I-06a`, `I-07` (cajas C1/C2/C4 de sala D y carta del P6): el catálogo los incluye (AC-01) y el repaso los filtra por `has_item`, pero no se adquieren en M1.
- Uso de tarjeta en lectores `C06`/`C07` (AC-08, AC-23, AC-24 en su parte de 8): puertas B/D fuera; `sostener_item` se prueba con doble de 8 en 005.
- Presentación con firma de arte (AC-17, PV): M1 es gris; la captura se toma pero la firma del lead de arte queda para M2+.
