# Review GDD 12 (final)
VEREDICTO: NEEDS REVISION
BLOQUEANTE
- B1: hint nivel 2 `FLOOR_MARKS` targets ["B08"]; marco r29 exige targets existentes "en los datos del puzle y en 7"; 7 r26 dice que B08 "no se declaran" (fuera del catalogo) -> fallo de arranque en build final. No esta en Cambios requeridos (solo se pide a 4 que B08 exista).
AVISOS
- A1 MIRROR_PREVIEW sin `targets` (r29); kinds nuevos no estan en catalogo (ya en Cambios 9).
- A2 `cobertura_anexo_a.json` (R1) no existe en assets/data; solo aparece en design/registry/entities.yaml.
- A3 F4: "tipico" usa 9 pulsaciones (28,8 s) aunque F2 da 6 (19,2 s); F4 con 6 daria ~109 s. T_descubrir/t_obs todo sin validar. Recomendar (a) "bajar F7 y medir" es al reves: primero medir (b). Bajar F7 P2 (1,5-4) baja minimo F9 (14,8->13,3) y roza criterio 1 del slice (15-30) y slice §22 (fuente de verdad).
- A4 t_clic 0,4 s (F6 de 9) vs HAND_TURN <=0,8 s y Edge 2 (7 descarta pulsaciones durante HAND_TURN): t_paso real >= 0,8+.
- A5 R19 afirma "se deduce"; R17/D12-6 sin marca de punto vacio: solo hay tanteo por lampara. Pilar Autonomia / D-W2 abierto (Q12-1), bien declarado.
- A6 Indice fila 12 deps "7, 9, 18" pero GDD declara tambien 3,4,2,6 (blandas); 21 no declara a 12 (indirecta via bus).
- A7 "matriz de encaje" de 9 citada en Dependencies: no verificada en 9.
INFO: math F1-F6 correcta; DOC_01 concatenado coincide con slice; AC-12/AC-41 de 9 y reglas citadas existen; on_reject ausente valido (r15); AFFORDANCE admitido (r25). Q12-1..8 abiertas y marcadas (Q12-3/6 contradicen slice, avisado).
No leido: game-pillars, game-concept, entities.yaml, slice C.5/D.2/§22 completos, 17, 10/5 al detalle, AC-04c de 7.

---
## Informe final del revisor (respuesta de cierre)

**Veredicto: NEEDS REVISION** (1 bloqueante, 7 avisos).

**Bloqueante B1.** La pista 2 declara `"kind":"FLOOR_MARKS","targets":["B08"]`. La regla 29 de 9 exige que los `targets` existan «en los datos del puzle y en 7», y la regla 26 de 7 dice que `B08` «no se declaran». Resultado: fallo de arranque en la build final. «Cambios requeridos» solo pide a 4 que `B08` esté presente; falta pedir a 7 que lo incluya en su catálogo, o a 9 que exima a los decorados.

**Avisos.**
- A1: `MIRROR_PREVIEW` no lleva `targets` y la regla 29 los valida. Los tres `kind` nuevos ya están en «Cambios» (9, punto 2). `on_reject` ausente y el tipo `AFFORDANCE` sí los admite 9 (reglas 15 y 25).
- A2: R1 cita `cobertura_anexo_a.json`, que no existe en `assets/data`; solo se menciona en `design/registry/entities.yaml`.
- A3: sobre F7. Recalculadas las 64 combinaciones (27/27/9/1), las 6 pulsaciones (1+3+2), la cota de 9, la media de 4,5 y los totales de F4 (64,2 / 118,8 / 262,2 s): todo cuadra. El «típico» de F4 usa 9 pulsaciones (28,8 s), no las 6 de F2 (19,2 s). Todos los términos son † sin validar. Que el modelo quede por debajo de F7 es plausible, pero Q12-2 recomienda «bajar F7 y medir» y el revisor mediría primero: bajar F7 mueve el mínimo de F9 de 14,8 a 13,3 min, roza el criterio 1 del slice (15–30 min) y toca §22.
- A4: F3 usa `t_clic` = 0,4 s, pero `HAND_TURN` dura ≤ 0,8 s y el caso límite 2 dice que 7 descarta pulsaciones durante ese gesto, así que el `t_paso` real es mayor.
- A5: R19 dice que la solución «se deduce», pero R17 y D12-6 no marcan el punto vacío, así que solo hay tanteo por lámpara (Q12-1, abierta). Sin softlock: toda posición es alcanzable con `Girar`.
- A6: el índice lista 7, 9 y 18, mientras el GDD declara además 3, 4, 2 y 6 como blandas; 21 no declara a 12 (indirecta, vía bus). La «matriz de encaje» de 9 no se verificó.
- A7: Q12-3 y Q12-6 contradicen el slice (§7 y C.5); están marcadas abiertas y resueltas por defecto (aceptable).

**No leído:** `game-pillars`, `game-concept`, `entities.yaml`, slice C.5/D.2/§22 completos, 10 y 5 al detalle, AC-04c de 7.
