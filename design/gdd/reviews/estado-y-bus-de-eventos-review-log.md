# Review log — Estado del juego y bus de eventos

## Review — 2026-11-08 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 3 | Recommended: 6
Summary: Diseño sólido y alineado con el slice (19 hechos coinciden con D.2) y con los pilares; los bloqueantes eran de precisión de contrato. Tras la revisión del mismo día se aplicaron todos los arreglos; una re-review en sesión limpia decide Approved.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Dependencies/regla 10: los avisos de Entrada y controles (1) no estaban listados y el sistema 1 no figuraba como dependiente. Arreglado: regla 10, CA-11, Dependencies (blanda).
- [BLOCKING] Reglas 3 y 11: no decían si el valor se aplica al instante durante una entrega. Arreglado: valor inmediato, aviso encolado; CA-13 ampliado.
- [BLOCKING] States and Transitions / CA-23: «Restaurando» sin definir síncrono o asíncrono. Arreglado: síncrono; CA-23 reescrito.
- [RECOMMENDED] Edge Cases: partida nueva o restauración pedida desde una entrega. Añadido + CA-13b.
- [RECOMMENDED] CA-30 no verificable. Reescrito sobre los owner de flags.json; integración pasa a CA-31.
- [RECOMMENDED] CA-15 y CA-29 dependían de datos sin definir. Reescritos (tope de prueba, script de verificación).
- [RECOMMENDED] CA-06 mezclaba L e I. Separado en CA-06 y CA-06b.
- [RECOMMENDED] Tuning Knobs ausente. Añadido max_chained_notices.
- [RECOMMENDED] Open Question 5 obsoleta (el índice ya incluía 3 en el 17). Cerrada.
Reviewed-Content-Hash: design/gdd/estado-y-bus-de-eventos.md fee8001760753398901601de2bb02f1039b2165f
Reviewed-Content-Hash: design/registry/entities.yaml 4e5f1b0145c266c04083df9e037a01062247f346
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/entrada-y-controles.md 8f45919318fc7a28be30bfff01cdd29af2d03188
Reviewed-Content-Hash: design/gdd/base-de-contenido-narrativo.md ff3eedfd81207b932504c257b64facaf9407ea50
Reviewed-Content-Hash: design/gdd/game-concept.md 42c8757ef76c7b78ffd32027384a14cd4134f02e
Reviewed-Content-Hash: design/gdd/game-pillars.md b779b89b06b8cb687a8fe0148e81b82831914b97
Reviewed-Content-Hash: design/slice/slice-v0.3.md d8398aa0cede5242a4094e0fe3776164ecbfea09
