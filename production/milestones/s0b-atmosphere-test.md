# Hito: S0b · Prueba de atmósfera (30 s de pasillo)

> Línea base creada el 2026-11-11 (PR-PHASE-GATE C12). Plantilla:
> `.claude/docs/templates/milestone-definition.md`. Equipo: una persona con agentes;
> sin fecha de demo.

## Overview

- **Fecha objetivo**: ninguna fija. Plazo relativo: tras S0 (puede solaparse con su última mitad, ver Dependencias).
- **Tipo**: Prototype (spike de render y tono)
- **Duración**: 0,5–1,5 semanas (esperado 1). **Confianza: baja.**
- **Sprints**: 1
- **Estado**: **No iniciado**

## Objetivo del hito

Responder dos preguntas antes de invertir en arte: **(1) ¿transmite el tono?** (aprobación
visual del usuario, `docs/PLAN-TECNICO.md` § 4) y **(2) ¿cabe en el equipo de referencia?**
(primer dato medido de rendimiento del proyecto). Hoy **ninguna cifra de rendimiento está
medida**: todo presupuesto es objetivo provisional, NOT VERIFIED (ADR-0019 D2/D3).
Mitiga el riesgo del slice § 22 «los assets low poly no transmiten atmósfera».

## Equipo de referencia (`REF-1`, ADR-0019 D1)

Portátil del desarrollador: Windows 11 Enterprise, Intel Core Ultra 7 265H (16 núcleos),
**iGPU Intel** con memoria compartida (driver 32.0.101.8801), 15,4 GB RAM, pantalla
1920×1200 @ 60 Hz. Es el único equipo de veredicto; otros equipos dan números «non-reference».
Riesgo **ALTO** (cualitativo, sin medir) de no cumplir B1 a resolución nativa con glow y 2 luces con sombra (ADR-0019 D2).

## Alcance

**Dentro:** el pasillo (`pasillo`, slice Anexo A.3) en gris con 6 luminarias `C03`, reflejo de
`C02`, lluvia en ventana, drone de ambiente y `LUCES_PARPADEO` a los 10 s; recorrido guionizado
de 30 s (X = 3 → 23); arnés de medida dev-only; los 7 pasos de ADR-0014 D12; la carrera P1
de ADR-0019 D5; script de luminancia por fotograma (AC-28-21).
**Fuera:** texturas finales, resto de salas, puzles, VO final, accesibilidad más allá de los
límites de destellos (que **no** se recortan).

## Los 7 pasos (ADR-0014 D12)

| Paso | Escenario | Criterio de paso | Si falla |
|---|---|---|---|
| S0b-1 | 30 s guionizados, lluvia, 6 `C03`, reflejo `C02`, parpadeo a 10 s; anotar backend | 99 % de fotogramas ≤ 16,6 ms; CPU de 28 media ≤ 0,15 ms, pico ≤ 0,5 ms | Escalera de recorte (abajo); repetir |
| S0b-2 | Igual, GPU diferencial (28 on/off) | ≤ 1,0 ms; `visible = false` quita el coste de la luz (NS-A1) | Pasos 3–4 de F8 (NS-A6); escalar a ADR-0019 |
| S0b-3 | Auditoría de luces en cada parada de cámara | ≤ 8 visibles, ≤ 2 con sombra, ≤ 14 habilitadas | Corregir `zone_visibility` |
| S0b-4 | Rampa de lluvia 1,0 → 0 → 1,0 | Sin salto al reiniciar; elegir `amount_ratio` o fallback (NS-A3); semilla estable | Fallback de D6 |
| S0b-5 | Cristal `C02` con sonda y proxy | Se lee como reflejo; fresnel en cristal transparente (NS-A5); 1 draw call | Proxy opaco + fresnel falso |
| S0b-6 | 10 s de parpadeo, apagón, restauración, glow on, exposición fija, SDR | Script de luminancia: ≤ 3 destellos por ventana de 1 s (esperado 2); luminancia no decreciente con la energía (NS-A8); apagón/restauración no cuentan | Bajar glow; si NS-A8 falla, ampliar el proxy |
| S0b-7 | S7 de ADR-0002 con los emisores de lluvia | Fotogramas idénticos en pausa, sin ráfaga al reanudar | ADR-0002 SB3 |

## Método de medida (ADR-0019 D5, carrera P1)

1. Build **exportada en release** desde el preset `profiling` (con arnés dev-only). Las carreras en editor son solo informativas.
2. `REF-1` enchufado, Windows en «Mejor rendimiento», 1920×1200 pantalla completa, navegador y capturadoras cerradas, 2 min en escena antes de grabar.
3. Vsync off y `max_fps = 0` para medir margen; una carrera extra con vsync on (como se entrega).
4. Descartar 120 fotogramas, grabar **1800**; **3 carreras**, el veredicto usa **la peor**.
5. Por fotograma: tiempo de frame, `TIME_PROCESS`, `TIME_PHYSICS_PROCESS`, GPU (NS-P2 o captura externa PIX / Intel GPA), draw calls, memoria, timers de 2 y 28.
6. GPU por sistema: método diferencial (subárbol on/off). Anotar la herramienta usada.
7. Informe: media, p50, p95, p99, máx.; fotogramas > 16,6 ms y > 50 ms; veredicto por presupuesto (PASS / FAIL / NOT ASSESSED) **escrito por la persona**, no por el arnés.
8. Una pasada informativa con Vulkan para comparar backend.

**Registros:** `production/qa/perf/perf-YYYY-MM-DD-P1.md` (+ `.csv` crudos) y capturas con overlay en `production/qa/evidence/perf/`.

## Criterios de salida (todos medibles)

- [ ] **C-S0b-1** Los 7 pasos S0b-1…S0b-7 con resultado PASS / FAIL anotado (FAIL con la escalera aplicada y registrada es un resultado válido; «sin ejecutar» no).
- [ ] **C-S0b-2** Carrera P1 archivada en `production/qa/perf/` con todos los campos de cabecera y NS-P1…NS-P6 verificados o sustituidos por su fallback (ADR-0019 Validation Criteria).
- [ ] **C-S0b-3** Veredicto de B1, B2, B3, B5, B7, B12 en `REF-1`, con el escalón de recorte vigente anotado.
- [ ] **C-S0b-4** Vídeo / capturas retenidas de los 30 s y del parpadeo en `production/qa/evidence/`.
- [ ] **C-S0b-5** **Aprobación visual del usuario** («¿transmite el tono?»: sí / no / sí con escalón N) registrada en este fichero.
- [ ] **C-S0b-6** Decisión de inversión en arte registrada (sigue el plan de M4 / se reduce / escalada E).
- [ ] **C-S0b-7** ADR-0014 y ADR-0019 actualizados con los resultados (§ Spike Results / OI-6 re-baseline de B5/B6) y propuestos al usuario para `Accepted`.

## Escalera de recorte (ADR-0019 D4: orden fijo, disparada por medida)

Un escalón cada vez, re-medir tras cada uno; el escalón que hace pasar queda como valor por defecto y se anota.

| Paso | Recorte | Coste visual esperado |
|---|---|---|
| 0 | Higiene de medida (corriente, modo rendimiento, vsync off, sin otras apps GPU) | Ninguno |
| 1 | Calidad de sombras; luego V06 (luz no-puzle) pierde la sombra | Bajo |
| 2 | Escala de render 3D 1,0 → 0,85 → 0,77 (FSR 1 o bilineal); UI nativa | Bajo–medio |
| 3 | Lluvia: escalera F8 del GDD 28 (distancia 6 m, `n_max_ventanal` 200 → 100, una capa de ruido) | Medio |
| 4 | Glow: bajar, luego off | Medio (tono) |
| 5 | Shaders 29: fallback `StandardMaterial3D` (contornos, espejo, cristal el último) | Medio–alto |
| 6 | Alcance de luz: `distance_fade`, visibles 8 → 6 | Alto |
| E | **Escalada**: renderer Compatibility o 30 fps → nuevo ADR, **decisión del usuario** | — |

Se salta un escalón si su subsistema no es donde se va el tiempo (atribución de D5).
**Nunca se recorta:** límites de destellos y `FLASH_MAX_HZ`, suelo de luz ambiente, suelo de texto de 24 px, banda de subtítulos, tiempos de 21/22/23, presupuestos de audio.
Criterio de éxito de ADR-0014: cumplir con **como mucho los dos primeros escalones** de F8.

## ADR y spikes que cierra

| ADR | Qué exige S0b | Estado objetivo |
|---|---|---|
| 0014 Atmosphere | S0b-1…7 en `REF-1`; R32 | Accepted (si 0001, 0002, 0003, 0005, 0007, 0009 lo están; si no, «spike cerrado, aceptación pendiente de dependencias») |
| 0019 Perf budgets | Carrera P1; OI-3 (preset `profiling`) | Accepted con B5/B6 re-baselined (OI-6) |
| 0002 Pause | S0b-7 (re-confirma con lluvia) | Ya Accepted en S0 |

No le conciernen: el resto. 0015 (shaders) **no** se cierra aquí: su spike de vistas P2/P5 es la carrera P2 en M4.

## Cola de diseño pendiente que le afecta (contada, no resuelta)

`adr-reconciliation-2026-11-10.md` R2.2: **6** — H14 (envolvente sobre `GameClock` en lugar de `Tween`), H15 (≤ 14 luces por instancia, `zone_visibility`, `shadow_allowlist`), y 4 marcadas **[U]** (decisión del usuario): H29 (ritmo del parpadeo 1,15 s, apagón reducido 0,8 s, lluvia en el apagón), H32 (hardware de referencia: respondido en ADR-0019, falta cerrarlo formalmente), H33 (herramienta de análisis de destellos; PEAT no verificado), H34 (salida HDR y modo de AA).
Ronda 1 (§ 2): **0**.
Decisiones del usuario de `gdd-cross-review-2026-11-10-r2.md`: **1** de 6 (n.º 2: parpadeo 1,15 s y apagón 0,8 s con `reducir_sobresaltos`, modifica slice C.4/C.7). Afecta al paso S0b-6.

## Riesgos

| Riesgo | Prob. | Impacto | Mitigación | Dueño |
|---|---|---|---|---|
| R-S0b-1 B1 a 1920×1200 en iGPU no se cumple (ADR-0019 D2, cualitativo, sin medir) | Alta | Alto | Escalera D4; escalada E solo con ADR y usuario | technical-director |
| R-S0b-2 Contadores de GPU por sistema (NS-P2/NS-A7) no usables en la iGPU | Media | Medio | Captura externa PIX / Intel GPA; anotar herramienta | engine-programmer |
| R-S0b-3 No hay preset `profiling` (ADR-0019 OI-3 / ADR-0018) | Alta | Medio | Cerrar en S0 (R-S0-6) o primera tarea aquí | devops-engineer |
| R-S0b-4 El tono no convence con low poly gris | Media | Alto (decide arte) | Es el propósito del hito; la respuesta «no» es válida y barata ahora | usuario / art-director |
| R-S0b-5 Herramienta de destellos (H33) no decidida | Media | Medio (S0b-6 sin veredicto) | Script propio de luminancia por fotograma (AC-28-21) | qa-lead |
| R-S0b-6 Prueba en dependencias `Proposed` (0003, 0005, 0007) | Media | Bajo | S0b es spike: el veredicto no requiere su aceptación; sí la de 0014 | lead-programmer |

## Orden de recorte (del hito, no del render)

1. Pasada comparativa Vulkan → M4. 2. S0b-5 con proxy opaco directamente (sin probar fresnel transparente). 3. Drone de ambiente con audio provisional.
**No se recorta:** S0b-1, S0b-3, S0b-6, la carrera P1 en `REF-1` y la aprobación visual del usuario.

## Plazo

| Escenario | Semanas | Supuesto |
|---|---|---|
| Optimista | 0,5 | Pasa con escalones 0–1 |
| Esperado | 1 | Dos o tres escalones y re-medidas |
| Pesimista | 1,5 | Contadores GPU no usables; llega a escalón 4–6 o a la escalada E (que se decide fuera del hito) |

**Confianza baja:** primer trabajo de render del proyecto, 9 afirmaciones NOT SOURCEABLE en ADR-0014 (NS-A1…NS-A9), ninguna medida previa.

## Dependencias

| Depende de | Estado | Si se retrasa |
|---|---|---|
| S0: export que funciona + preset `profiling` | Pendiente | S0b mide en editor (solo informativo, no cierra el hito) |
| ADR-0002 `Accepted` (S0b-7) | Pendiente (S0) | S0b-7 queda sin veredicto |
| Usuario: aprobación visual | Al final | El hito no cierra |
| M1 | Puede empezar en paralelo al arte (el gris no depende del veredicto de tono) | — |
