# Story 009: Overlay del ordenador en gris y capturas (ordenador + impresión)

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Blocked — BLOCKED: H21 (overlay del ordenador) pendiente en la cola de diseño (EPIC.md § Overview); no es un bloqueo de ADR. Desbloquea al cerrar H21.
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Overlay en `SceneUi` con campo, lista y panel de correo, a la resolución lógica base. Cierra
C-M1-7 para «ordenador» e «impresión».

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R5, R14, R29)
**Requirement**: `TR-computer-010` (presentación), `TR-computer-016` (presentación)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (foco y etiquetas); ADR-0005 (textos de 18)
**ADR Decision Summary**: textos por clave de 18; foco visible en el campo y en la fila.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0006)
**Engine Notes**: ninguna propia.

**Control Manifest Rules (this layer)**:
- Required: textos por clave de 18
- Forbidden: FE-X03 (no codificar 1920/1080 en código)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-06**: abriendo los seis correos en cualquier orden, cada panel muestra día, remitente, asunto y cuerpo de 18 (y la hora si `pantalla_muestra_hora`).
- [ ] **GDD 19 AC-22**: el árbol de nodos al abrir y tras buscar no contiene carpeta Recibidos, contador ni indicador de leído/relevante.
- [ ] **C-M1-7**: capturas retenidas del motor del ordenador (lista 3, 1, 4, 2 con distractores y un correo abierto) y de la impresión (`V08` imprimiendo y hoja en bandeja), a 1920×1080. Tamaños de texto, contraste y 16:10 → **Diferido** (ADR-0007).

---

## Implementation Notes

- **Captura del propio motor**: `godot --path . --write-movie production/qa/evidence/computer/computer.png --fixed-fps 60 <escena de evidencia>` (`.claude/docs/run-and-observe.md`); nunca captura del escritorio.

---

## Out of Scope

- Escalado y accesibilidad de texto (TR-computer-013/014, ADR-0007).

---

## Files

- escena del overlay en `src/ui/` (nombre según H21)
- `production/qa/evidence/computer/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: una captura retenida de cada pantalla tocada en `production/qa/evidence/computer/`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ordenador-e-impresora/story-002-latencia-lista-correos-leidos.md`, `production/epics/ordenador-e-impresora/story-004-impresora-v08-entrega-i01.md`, `production/epics/ordenador-e-impresora/story-006-foco-dual-teclado-pantalla.md`; H21
- Unlocks: None
