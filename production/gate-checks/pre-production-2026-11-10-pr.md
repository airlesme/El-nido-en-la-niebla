PR-PHASE-GATE: CONCERNS

# PR-PHASE-GATE · Technical Setup → Pre-Production · 2026-11-10

**Agente:** producer · **Tier:** `workflow: standard` (vía `modes.rigor: standard`), `review_mode: lean`
**Entradas leídas:** `.claude/docs/director-gates/pr-phase-gate.md`; `production/gate-checks/pre-production-2026-11-10.md`; `docs/PLAN-TECNICO.md` §1–§7; `design/slice/slice-v0.3.md` (cabecera de alcance, §2, §3, §19.1, §22); `project.yaml`; `production/` (listado); `docs/architecture/architecture-review-2026-11-10.md` y `adr-reconciliation-2026-11-10.md` (por encabezados y filas pendientes).

## Veredicto: CONCERNS

Desde producción no hay un bloqueante propio. Este gate es **anterior** al de Production, así que la falta de sprint plan e hitos formales **no es un hallazgo** a este tier (`pr-phase-gate.md`: «before it, no sprint plan is expected»). El FAIL del informe de artefactos (gdUnit4 sin instalar, suite sin ejecutar) es un bloqueante técnico que corresponde al TD. Lo cito porque es el criterio de salida de S0 y está en el camino crítico, pero no lo convierto en un NOT READY de producción.

Hay tres partes que se evalúan por separado:

| Parte | Estado | Motivo |
|---|---|---|
| Alcance frente al tamaño de equipo | **CONCERNS** | `team.size: individual` sale de la expansión de `modes.rigor` en `resolve_config`. El usuario no lo ha confirmado: la pregunta §7.3 del plan sigue abierta |
| Calendario | **NOT ASSESSED** | No hay fecha de demo (§7.5), ni sprints, ni histórico de velocidad. La «estimación gruesa» de 6–7 semanas (§4) es anterior a la descomposición en 30 GDDs y 17 ADR, y no está calibrada |
| Plan y orden de dependencias para empezar | **CONCERNS** | El orden de hitos S0 → S0b → M1…M5 es coherente. Pero S0 no ha cerrado su criterio de salida y S0b depende de QQ-04 |

## Razones concretas

1. **S0 sigue abierto según su propia definición.** El plan §4 exige que «el proyecto abre, corre y exporta una escena vacía en Windows y Linux» con CI y gdUnit4, y que «D-16 [esté] cerrada». Hoy `addons/` no existe, `commands.build` está `[TO BE CONFIGURED]`, la CI nunca se ha ejecutado y D-16 está abierta (§7.1). Pre-producción arrancaría con S0 sin terminar.
2. **Hay mucha documentación por cada línea de código.** Son 30 GDDs (con 10 rondas de revisión), 17 ADR en Proposed y 609 TR, con 0 líneas de código de juego y 0/609 TR ✅. Para un slice de 15–30 min es una carga muy alta. El esfuerzo hasta ahora ha ido a especificar, no a validar jugando, y el objetivo nº 1 del slice (§2: «el bucle… funciona como juego») solo se responde jugando.
3. **El trabajo de diseño pendiente es una cola real.** Quedan 35 cambios a GDDs (reconciliación §2 y §R2.2), 6 decisiones **[U]** del usuario y varios items de ADR pendientes (23–28, R24–R33). Si no se cierran en un solo lote con fecha, se arrastran a cada historia y bloquean `/create-stories`, porque las historias que citan un ADR Proposed quedan auto-bloqueadas.
4. **El hardware de referencia (QQ-04) bloquea dos cosas.** Sin él no hay ADR-0019 ni presupuestos definitivos. Además ADR-0014 queda bloqueado y la prueba S0b no tiene contra qué validarse (revisión, tabla de aceptación de ADR).

## Riesgos de alcance (¿es realista un slice de 15–30 min con 30 GDDs?)

**Respuesta corta:** en contenido, sí es realista para una persona. **El calendario de 6–7 semanas no se puede sostener con lo que hay**, y la falta de fecha impide decir si cabe.

- **Contenido** (slice §3): 1 planta con 4 espacios + Recepción, 6 puzles, 1 llamada con 3 cartas × 4 respuestas + silencio, 8 escenas, VO, subtítulos y accesibilidad Estándar. Para un individual con herramientas de IA es un slice ajustado pero clásico (comparable a los slices de juegos narrativos de 1–2 personas). Los 30 GDDs son granularidad de diseño, no contenido extra: **no hay creep de contenido** respecto a `slice-v0.3.md` §3.
- **El creep está en el proceso, no en el contenido.** No se puede cuantificar con `/scope-check` porque no existe ningún baseline de hito en `production/milestones/` (solo `.gitkeep`). Por eso queda NOT ASSESSED numérico.

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| M4 (pase de calidad: arte final, VO, shaders, accesibilidad) consume el calendario de un individual | Alta | Alto | Línea de corte P0/P1 de §15/§22 ya cerrada. Pactar **ahora** el orden de recorte (ver condición 4) |
| La cola de cambios en GDDs y ADR sigue creciendo (cada ronda de revisión abre más items) | Alta | Medio | Congelar la documentación tras un último lote (condición 3) |
| La atmósfera low poly no transmite el tono (riesgo §22) y obliga a rehacer arte | Media | Alto | S0b como primer entregable de pre-producción, con decisión go/no-go |
| VO del Guardián (calidad, §3 del plan: medio-alto) | Media | Alto | Audio provisional hasta M3 y decisión D-08 antes de M4 |
| Sin fecha de demo, el pulido se alarga sin límite | Alta | Alto | Condición 1 |
| `team.size` inferido y no declarado; si hay más personas, el rigor y el panel cambian | Media | Medio | Condición 1 |

## Condiciones para ir a Pre-Production

1. **El usuario responde §7.3 y §7.5 del plan**: equipo real (personas y perfiles) y fecha objetivo de la demo, o acepta de forma explícita «sin fecha». Con eso, la parte de calendario deja de ser NOT ASSESSED y se puede pasar `/estimate` sobre M1.
2. **Cerrar S0 según su criterio de salida.** gdUnit4 en verde en local y en CI (es el bloqueante del TD), export de una escena vacía en Windows y Linux, D-16 decidida y QQ-04 (hardware de referencia) fijado **antes** de S0b.
3. **Un último lote de diseño con fecha y después congelar.** Aplicar los 35 cambios a GDDs y resolver las 6 decisiones [U] en una sola sesión por lotes (modo de `CLAUDE.md`). Aceptar los ADR Foundation 0001, 0002 y 0009, y escribir ADR-0018. Después, **no se abren GDDs ni ADR nuevos** hasta que M1 sea jugable, salvo ADR-0019 cuando llegue QQ-04.
4. **Un baseline de hito escrito** en `production/milestones/`: S0b (prueba de atmósfera de 30 s, go/no-go) y M1 (prototipo gris, escenas 1–3, puzle 1, puerta A) con timebox, criterio de salida y **orden de recorte pactado** si M1 se pasa más de un 50 % del timebox. El orden de recorte lo decide el CD/usuario; candidatos: variantes de carta, P5 o pulido de shaders P1. Así `/scope-check` tendrá contra qué medir.
5. **Validar jugando cuanto antes.** El primer hito de pre-producción debe producir algo jugable (S0b + M1), no más documentación. Se mide con el criterio del plan: «se juega de la escena 1 a la 3 sin texturas».

**Sabremos que fue la decisión correcta si** M1 se juega de punta a punta dentro de su timebox y la cola de cambios a GDDs no crece entre S0 y M1.

## No evaluado

- Calendario: no hay fecha, ni velocidad, ni sprints.
- Bloat numérico de `/scope-check`: no hay baseline de hito.
- Si las 6 decisiones [U] cambian el alcance del slice: no se leyó el contenido de cada [U] en la tabla R2.2, solo los encabezados y las filas pendientes.
