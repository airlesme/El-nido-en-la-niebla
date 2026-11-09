# Cross-GDD Review Report (ronda 7 · lote Feature 2: GDD 22 y dependencias de los 15 GDDs)

**Fecha:** 2026-11-09 · **Veredicto: CONCERNS** (0 bloqueantes) · **Modo:** autonomous, workflow standard · **Focus:** since-last-review (GDD 22 nuevo + dependencias de los 15 GDDs)
Informes anteriores: `gdd-cross-review-2026-11-09.md` (8 bloqueantes), `-r2` (2), `-r3` (2), `-r4` (CONCERNS), `-r5` (FAIL, 1), `-r6` (CONCERNS), y `reviews/feature-batch-2-resumen.md` (GDD 22: 1 bloqueante).

- **GDDs reviewed:** 15 of 15 present (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20, 21, 22). Cuatro revisores independientes en dos pasadas: revisión del GDD 22 y de las dependencias (con el informe `dependencias-r7-review.md`: 85 pares, 0 bloqueantes, 13 discrepancias), y re-verificación tras las correcciones (22: NEEDS REVISION por avisos; dependencias: 3 discrepancias abiertas, 0 bloqueantes). Cada revisor escribió borrador a disco antes de terminar.
- **Decisiones del usuario respetadas:** las anteriores y, del 2026-11-09, la respuesta de Vera definitiva con «llamada repetible» = se repite idéntica al cargar, «no colgar manual» y «cursor oculto hasta las opciones» mantenidas, y la fila «+4,0» de C.7 como línea a 4,8 s (slice v0.4.2).

## Estado

| Hallazgo | Estado |
|---|---|
| **B-1 (22↔21):** el efecto de 60 s de `ESC7_APAGON` reiniciaba el timbre en plena llamada | **CERRADO**: guarda `¬llamada_iniciada` en 21 (D21-28, AC-21-14b) coherente con 22 (regla 34, AC-22-27); verificado por recorrido paso a paso |
| A-1/A-2 (dueño de `V02`, reanudación sin sonido) | **CERRADO**: 22 reglas 3c, 30, 33 coherentes con 21 R15 (reescrita), 3, 7, 1 y registro |
| Estado final COMPLETADA/INACTIVA, F3/F5, AC-22-16, `HAND_PHONE_HOLD` | **CERRADO** |
| Dependencias (A1…A14 de `dependencias-r7-review.md`) | **CERRADO** salvo lo de abajo; 3 discrepancias de la re-verificación (8↔22, 21↔22, fila 6 del índice) aplicadas en la ronda 6 de corrección |

## Warnings abiertos (no bloquean)
⚠️ **D-15 del slice sigue «Confirmar»** (decisión del usuario). 22 ya no la da por confirmada.
⚠️ **Textos y claves pendientes del writer:** respiración inicial, `SUB_BREATH_BROKEN`, `VO_G_14_ASG`; preguntas abiertas de tono y de accesibilidad (cursor oculto con mando/lector de pantalla), y OQ 6 a 8 de 22.
⚠️ INFO: R19 mezclaba dos disparadores de vuelta a `INACTIVA` (unificado a «descarga del despacho»); el bloque de la llamada en el registro tiene 14 entradas.
⚠️ *Arrastrados:* los de r6 sobre el tiempo del slice (el criterio queda a medir con AC-X5; mínimo ≈14,8 min y techo ≈33,1 min con la llamada de 16,4–44,8 s), D-W1, D-W4, D-W5, D-W8…D-W11.

## GDDs Flagged for Revision
Ninguno con prioridad Blocking. Warning: 22 (textos y preguntas de tono; pendiente de revisión creativa), slice D-15 (decisión del usuario).

## Verdict: CONCERNS

Sin bloqueantes: todos los de las siete rondas están cerrados y verificados por un revisor distinto del autor. Los 15 GDDs de la capa Feature (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20, 21, 22) tienen contratos recíprocos, un dueño único por hecho y aviso, y dureza de dependencias declarada por el dependiente.

### Antes de empezar la arquitectura
1. Decidir D-15 del slice y las preguntas de tono/accesibilidad de 22 (usuario, writer, narrative-director).
2. Los sistemas sin GDD siguen sin diseñar: 11–17 (puzles 1–6 y sistema de pistas), 23 (audio), 24, 25, 26, 27, 28, 30. Los contratos de otros GDDs con 23 y 26 están marcados ‡. Los puzles (11–16) son la mayor parte del slice y dependen del marco de 9.
3. Confirmar en playtest el tiempo del slice (AC-X5).

---

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:** Tuning Knobs, Acceptance Criteria y Formulas de la mayoría de los GDDs (leídos solo por muestreo), regla 10 de 3 salvo la fila 22, AC y Dependencies completos de 5, 18 y 7, el cuerpo de 8 fuera de su fila de dependencias, el registro entero (solo grep y lectura parcial), el slice completo. E6 (llamada) recorrido solo a nivel de contrato porque 23 no existe. NOT SOURCEABLE: `AnimationPlayer`, `SceneTree.paused`, `AudioStreamPlayer`, `Area3D`/Jolt.
