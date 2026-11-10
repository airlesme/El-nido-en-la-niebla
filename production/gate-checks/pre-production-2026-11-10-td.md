TD-PHASE-GATE: CONCERNS

# TD-PHASE-GATE — Technical Setup → Pre-Production (2026-11-10)

**Director:** technical-director · **Tier:** `workflow: standard`, `review_mode: lean`
**Vocabulario:** la definición del gate (`.claude/docs/director-gates/td-phase-gate.md`) admite READY / CONCERNS / NOT READY. El encargo pedía APPROVE / CONCERNS / REJECT; CONCERNS existe en ambos y es el veredicto.
**Relación con el informe de artefactos** (`pre-production-2026-11-10.md`, FAIL): este veredicto **no anula** ese FAIL. El framework de tests no funcional sigue siendo bloqueante del gate; aquí figura como condición 1.

## Veredicto: CONCERNS

La arquitectura es sólida para *entrar* en Pre-Production (fase de spikes, prototipos y primeras historias), pero no está lista para implementación de producción: ninguna decisión Foundation está aceptada y el motor solo está verificado en un dominio (pausa).

### Lo que está en su sitio (por qué no NOT READY)

- **Estructura de decisiones completa y acíclica.** 17 ADR, 73 aristas, sin ciclos; orden topológico claro (0001 → 0002 → 0009 → Core). Ningún hueco ❌ en Foundation ni Core: los 7 ❌ son Tooling (ADR-0018) y Localización (ADR-0020, post-slice).
- **Dominios HIGH RISK identificados con profundidad suficiente para esta fase.** `architecture.md` § Engine Knowledge Gap Summary separa por dominio lo que cambió en 4.5–4.7 y lo que es NOT SOURCEABLE, y agrupa todo en cinco spikes con dueño. Es el método correcto: no se puede resolver leyendo más documentación.
- **El riesgo más alto de Foundation ya está medido.** El spike de pausa corrió en el pin exacto (4.7.2.stable.official.ed1daf0bf): S1–S3, S5–S16 y SB1–SB3 PASS; la opción A de ADR-0002 es válida. Además aportó hallazgos que *cambian* diseño (S10 `TIME` de shader avanza en pausa; S16 `create_timer` se dispara en pausa por defecto), lo que confirma que el programa de spikes funciona.
- **Higiene de motor:** 17/17 ADR con Engine Compatibility en 4.7, 0 usos de APIs obsoletas, riesgo declarado en todos.
- **Composición testeable por diseño** (ADR-0009: autoloads acotados, `ServiceContext` inyectado; ADR-0001: `NoticeChannel` `RefCounted` sin dependencia del árbol).

### Concerns (por qué no READY)

1. **0/17 ADR `Accepted`; 0/609 TR ✅.** Foundation (0001, 0002, 0009) en `Proposed`: toda historia que los cite queda auto-bloqueada.
2. **Motor verificado solo en pausa.** 236 afirmaciones NOT SOURCEABLE; fuera de la pausa son NOT ASSESSED. `godot-specialist` no consultado. La mayoría de ADR Core (0003, 0004, 0005, 0006, 0007) dependen de spikes sin ejecutar.
3. **Sin hardware de referencia (QQ-04).** Presupuestos 60 fps / 16,6 ms / ~1500 draw calls provisionales, sin techo de memoria, fuera de `project.yaml`. La suma 0014 + 0015 + 0008 (C8) no es evaluable. Aceptable para entrar en Pre-Production, no para cerrar ADR-0014.
4. **Tooling ausente:** gdUnit4 sin instalar, tests y CI nunca ejecutados, ADR-0018 sin escribir (incluye la prohibición de `create_timer` que el spike demostró necesaria), `godot` fuera del PATH, versión del editor local sin registrar en `VERSION.md`.
5. **`architecture.md` desfasado** (ADR Audit, A1–A8, H2/H3/H9/H12/H18) y contratos C1–C9 abiertos entre ADR.

## Condiciones para entrar en Pre-Production

1. **Framework de tests funcionando (bloqueante, coincide con el informe de artefactos).** gdUnit4 compatible con 4.7.2 en `addons/gdUnit4/`, los dos tests de ejemplo en verde en local con la consola 4.7.2 (log retenido) y el job de GitHub Actions en verde.
2. **Foundation aceptada antes de la primera historia de producción**, en este orden y con confirmación del usuario: ADR-0002 tras el log manual de S4 y la revisión a ojo/oído de S7, S8, S11 y SB3; ADR-0001 tras V-ENG-1…6 y la decisión de C1; ADR-0009 después (C9). Hasta entonces, solo spikes y prototipos.
3. **QQ-04 decidido → ADR-0019 → bloque `performance.*` en `project.yaml`** con techo de memoria, antes de cualquier spike de render (0014 S0b, 0015).
4. **Programa de spikes de motor con pasada de `godot-specialist`.** Orden recomendado: E/S atómica, hash y JSON (0004/0005) → escenas (0003) → entrada (0006) → Jolt sensores y consulta de forma (0011/0012) → UI/AccessKit (0007/0016). Cada ADR se acepta solo con su § Spike Results escrito en 4.7.2. Escribir ADR-0018 en paralelo.
5. **Higiene documental:** `architecture.md` actualizado (ADR Audit remite a `requirements-traceability.md`; A1–A8 y H* aplicados) y la versión del editor local registrada en `VERSION.md` (cierra el riesgo de desfase instalado/pin).

## Lectura parcial (lo que NO se ha leído y por tanto no se aprueba)

- **ADR:** de 0001, 0002 y 0009 solo `## Status`, `## Summary`, el inicio de `## Engine Compatibility` y el de `## Decision`. Los otros 14 ADR no se abrieron; su estado se toma del informe de artefactos y de `architecture-review-2026-11-10.md`. No se juzga la corrección interna de ningún ADR.
- **`architecture.md`:** cabeceras y líneas 1–54 (Document Status, Engine Knowledge Gap Summary). System Layer Map, Module Ownership, Data Flow y API Boundaries no se leyeron.
- **`requirements-traceability.md`:** no abierto; las cifras (609 TR, 439 🟡, 163 ⚠️, 7 ❌) vienen de § Traceability Summary de la revisión de arquitectura.
- **Resultados del spike:** solo las líneas `RESULT`; no el README del spike ni las capturas de S7/SB3.
- Ningún GDD, `systems-index.md`, `breaking-changes.md` ni `modules/*.md`.

## Validación

Sabremos que esta decisión fue correcta si: (a) 0001, 0002 y 0009 pasan a `Accepted` sin enmiendas estructurales tras sus verificaciones; (b) ningún spike Core invalida la opción elegida en su ADR (como mucho, la acota); (c) el primer job de CI sale verde y se mantiene así.
