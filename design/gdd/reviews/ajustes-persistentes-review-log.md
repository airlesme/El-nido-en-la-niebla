# Review log — Ajustes persistentes

## Review — 2026-11-08 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean)
Blocking items: 1 | Recommended: 9
Summary: Diseño coherente con los pilares y fórmulas correctas al recalcular (F1, F2 y F3, y todos los ejemplos). El único bloqueante era una contradicción de contrato entre la tabla de estados, la regla 10 y AC-12 sobre si «ajustes aplicados» se emite antes o después de pasar a «Listo». Las recomendadas cubren precisión de ACs, edge cases de la copia del fichero dañado, opciones del art bible ausentes del catálogo y notas para el ADR.
Prior verdict resolved: First review
Findings:
- [BLOCKING] States and Transitions: «Cargando» sale a «Listo» tras emitir «ajustes aplicados», pero en «Cargando» las lecturas devuelven el inicial (o error en desarrollo); regla 10 y AC-12 exigen leer los valores cargados dentro del manejador.
- [RECOMMENDED] F3: el ejemplo del arrastre escribe en t = 10; por la regla de `t_prim` sería t ≈ 10,05.
- [RECOMMENDED] Regla 10 / regla 6: fuera de rango se ajusta al límite en ejecución pero vuelve al inicial al cargar; justificar o igualar.
- [RECOMMENDED] Regla 11: falta el caso de fallo al renombrar la copia del fichero dañado y su AC.
- [RECOMMENDED] Catálogo / Open Question 9: el art bible (7.4 y 7.6) define opciones (reducir movimiento, escalas de texto y subtítulos, alto contraste, icono grande, etiquetas) que no figuran.
- [RECOMMENDED] AC-16b («mensaje de error claro») no es verificable; AC-01 dice «ocho claves» con 9 entradas de catálogo.
- [RECOMMENDED] Faltan AC para restablecer un ajuste suelto, doble escritura en el mismo fotograma y fallo del renombrado.
- [RECOMMENDED] Open Question 1: añadir que `FileAccess.store_*` devuelve `bool` desde 4.4 y que no hay `modules/core.md`.
- [RECOMMENDED] Edge Cases (ventana): rechazo del modo de ventana durante «Cargando», cuando no se entregan avisos.
- [RECOMMENDED] Registro y bidireccionalidad: registrar `N_pasos`, `db_min` y la curva de volumen; el GDD 18 no menciona los rótulos `UI_…` de ajustes.
- [NICE] Cabecera «In Design»/Layer Core frente al índice «Designed»/Persistence; falta tabla de Tuning Knobs; versión de formato ausente solo está en AC-11b.
Reviewed-Content-Hash: design/gdd/ajustes-persistentes.md e605f48026fef1bfe9659a551e10b22051e5cb2f
Reviewed-Content-Hash: design/registry/entities.yaml 4e5f1b0145c266c04083df9e037a01062247f346
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/entrada-y-controles.md 534bf8a968bc407705ac04eae73779ac0ba79115
Reviewed-Content-Hash: design/gdd/estado-y-bus-de-eventos.md fee8001760753398901601de2bb02f1039b2165f
Reviewed-Content-Hash: design/gdd/base-de-contenido-narrativo.md 3ffdab1aa3d7e1a116a278feb6e604e30cde5fd6
Reviewed-Content-Hash: design/gdd/game-concept.md 42c8757ef76c7b78ffd32027384a14cd4134f02e
Reviewed-Content-Hash: design/gdd/game-pillars.md b779b89b06b8cb687a8fe0148e81b82831914b97
Reviewed-Content-Hash: design/slice/slice-v0.3.md d8398aa0cede5242a4094e0fe3776164ecbfea09
Reviewed-Content-Hash: design/art/art-bible.md b618cd0eb440cdd95b0df160ebec2d52c16d42aa
