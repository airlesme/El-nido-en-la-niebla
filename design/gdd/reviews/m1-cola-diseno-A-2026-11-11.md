# M1 · Cola de diseño A (H1–H7, H9) — 2026-11-11

Fuente: `docs/architecture/adr-reconciliation-2026-11-10.md` § R2.2; ADR-0010 y ADR-0011 (Open Items / Contradicciones).
Ninguno de H1–H7, H9 está marcado [U] ni contradice `slice-v0.3.md` (son contratos internos, sin cambio de diseño ni de tiempos). Sin git por encargo: nada confirmado ni subido.

| H-n | GDD | Estado | Línea |
|---|---|---|---|
| H1 | marco-de-puzles (r9 `elements()`) | aplicado | D9-83. En puzle-1 ya aplicado: R14 y AC-18 (`ref_N` con `atraccion_desactivada`, D11-17); anotado en D11-23 |
| H2 | marco-de-puzles (r9 `Verdict`, r13) | aplicado | D9-84 (`PARTIAL(progress, element?, action?)`) |
| H3 | sistema-de-pistas (GDD 17) + architecture.md | no aplicado: fuera de los ficheros del encargo | pendiente en otro lote |
| H4 | marco-de-puzles (r7, r9, dependencias), puzle-1 (R7, dependencias) | aplicado | D9-85, D11-23 (`missing_items` lista; el controlador del P1 llama a `compose_i01()` en `on_open()`). El GDD 11 es puzle-1; su fila de 9 también actualizada |
| H5 | marco-de-puzles (Tuning Knobs, r4b, r9, r14a) | aplicado | D9-86. La nota en TR-puzzles-008 es del registro TR (`/architecture-review`), no de un GDD |
| H6 | interaccion-e-inspeccion (r31 `vista`, catálogo `D01a`) | aplicado | D7-78. Pendiente: GDD 13 (`view_distance_m`) fuera de los ficheros del encargo |
| H7 | interaccion-e-inspeccion (r20, r32) | aplicado | D7-79 (`pos_px_inicio`; `seleccionar` = un solo `fin`; nota de pulsación larga). F2 no necesitó cambio de fórmula |
| H9 | architecture.md § Interacción (7) | no aplicado: fuera de los ficheros del encargo | pendiente. Nota: Open Question 9 de prompt-de-interaccion (tipo de `PERSISTENTE`) queda resuelta en ADR-0011 (`-1.0`); sin edición en el GDD 24 |
| H8 | GDD 14 OQ 1 / OQ 5 de 7 | no aplicado: decisión de diseño/arte, fuera del encargo | OQ 5 sigue abierta |
| — | prompt-de-interaccion | sin cambios requeridos por H1–H9 | ningún H-n lo cita |
