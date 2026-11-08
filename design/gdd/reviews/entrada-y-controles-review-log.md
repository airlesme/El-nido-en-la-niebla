# Review log — Entrada y controles

## Review — 2026-11-08 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean)
Blocking items: 4 | Recommended: 10
Summary: Diseño coherente con los pilares y fórmulas correctas al recalcular (F1, F2, F5a y los ejemplos de F3, F4 y F5b). Los bloqueantes eran de contrato con el sistema 3, de una garantía de accesibilidad falsa en los rangos permitidos (escape de la atracción) y del tope F8 frente a las escenas dirigidas. Se aplicaron las revisiones el mismo día; una re-review en sesión limpia decide Approved.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Dependencies: el sistema 3 no figuraba como dependencia blanda aunque Entrada emite por su bus. Arreglado (Quick reference, Dependencies, Cross-References).
- [BLOCKING] Regla 6: el aviso «contexto de entrada cambiado» no tenía regla, datos ni AC. Arreglado: (anterior, nuevo) por cambio efectivo; AC-E9.
- [BLOCKING] F5b: la garantía de escape era falsa en los rangos (p. ej. s_c = 0,5 o λ = 10). Arreglado: tracción limitada a 0,5·v_c·delta; AC-F5 con extremos.
- [BLOCKING] F8: el tope de 3 s chocaba con las escenas dirigidas que piden `sin control`. Arreglado: duración declarada por el director + margen 2 s; AC-F8; Open Question 12.
- [RECOMMENDED] F3: 0,85 s y 240 °/s incorrectos (0,58 s; 360 °/s en el peor caso). Corregido, AC-F3 ajustado.
- [RECOMMENDED] F4: el tiempo del ejemplo no incluía el freno en marcas (~4,4 s). Aclarado.
- [RECOMMENDED] Resolución: unidades del cursor en viewport lógico 1920 × 1080. Declarado; Open Question 13.
- [RECOMMENDED] F5b: delta sin tope. Limitado a 0,1 s.
- [RECOMMENDED] Regla 16: pausa reasignable chocaba con ui_* fijas. Se rechaza; AC-E10.
- [RECOMMENDED] Regla 7: menú de título como base de la pila. Definido; AC-E10.
- [RECOMMENDED] Regla 21: pérdida de foco durante una carga de escena. Se pospone; AC-E11.
- [RECOMMENDED] Regla 14: semántica de alternar para leer/mantener/agarrar. Propuesta añadida (a validar en playtest).
- [RECOMMENDED] Textos obsoletos sobre el índice y Open Question 11. Limpiados.
- [RECOMMENDED] ACs: AC-04 y AC-09 poco verificables y faltaban AC de contexto y de cancelar pulsación. Reescritos y AC-E9 a E12 añadidos.
Reviewed-Content-Hash: design/gdd/entrada-y-controles.md 534bf8a968bc407705ac04eae73779ac0ba79115
Reviewed-Content-Hash: design/registry/entities.yaml 4e5f1b0145c266c04083df9e037a01062247f346
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/estado-y-bus-de-eventos.md fee8001760753398901601de2bb02f1039b2165f
Reviewed-Content-Hash: design/gdd/game-concept.md 42c8757ef76c7b78ffd32027384a14cd4134f02e
Reviewed-Content-Hash: design/gdd/game-pillars.md b779b89b06b8cb687a8fe0148e81b82831914b97
Reviewed-Content-Hash: design/slice/slice-v0.3.md d8398aa0cede5242a4094e0fe3776164ecbfea09
Reviewed-Content-Hash: design/art/art-bible.md b618cd0eb440cdd95b0df160ebec2d52c16d42aa
