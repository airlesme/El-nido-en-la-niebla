# Propagación de D-16 (orden de la caja), 2026-11-10

Decisión firme del usuario: cadena c1→c3→c4 con c2 libre (c3 requiere c1; c4 requiere c1, c2 y c3). Alternativa descartada: orden libre. Motivo: guía sin callejón.

## Ficheros editados
- `design/slice/slice-v0.3.md`: §8 paso 4 y §13.3 reescritos; D-16 pasa a «Tomada»; entrada 0.4.3 en §24.
- `design/slice/README.md`: D-16 sacada de las abiertas; incoherencia 1 marcada resuelta.
- `design/gdd/caja-y-compartimentos.md`: fuente de la regla 2, Edge Case 17 y fila D10-28.
- `design/gdd/marco-de-puzles.md`: regla del grafo (l.~242), fila de dependencias del slice, D9-35 resuelta, Open Question 8 y nota de cambios pendientes (l.~619). Se añade `requires.all = [caja_c1, caja_c2, caja_c3]` al JSON de ejemplo de P6, que no lo traía.
- `design/gdd/puzle-6-decision.md`: regla 2, Open Question 4 cerrada, cambio requerido sobre el slice y fila D16-0.
- `design/gdd/systems-index.md`: D9-35 / D-16 sacada de las preguntas abiertas.

## Contradicciones sin resolver
1. Ninguna de las reglas de pistas, acceso o puzle contradice la cadena: P3→c1, P4→c2 (libre), P5→c3 (requiere c1), P6→c4 (requiere c1, c2, c3) coinciden en el slice B, D.2, 9 y 16.
2. `marco-de-puzles.md` regla 24 y AC-03/AC-19 no se han releído enteras; se ha comprobado solo lo hallado con Grep.
3. Siguen mencionando el estado anterior, sin tocar por ser históricos: `design/gdd/gdd-cross-review-2026-11-09-r5.md`, los `reviews/*` y `design/gdd/reviews/cross-review-r5-C.md`.
4. `puzle-6-decision.md`, Open Question 3 (D-14) sigue pendiente; no es parte de esta decisión.
5. `design/gdd/estado-y-bus-de-eventos.md` l.222 cita D-16 como justificación de hechos de un solo sentido: no se ha modificado y sigue siendo válido.
