# Hitos · línea base (Pre-Production, 2026-11-11)

Creada al entrar en Pre-Production (PR-PHASE-GATE C12). Equipo: **una persona con
agentes**. **Sin fecha de demo**: todos los plazos son relativos, en semanas, con
optimista / esperado / pesimista. No hay historia de sprints ni velocidad medida:
**toda estimación es de confianza baja** hasta que cierre el primer sprint.

## Índice

| Hito | Fichero | Objetivo en una línea | Plazo (opt. / esp. / pes.) | Estado |
|---|---|---|---|---|
| S0 · Setup | [s0-project-setup.md](s0-project-setup.md) | Proyecto que exporta a Win/Linux; Foundation aceptada | 1 / 1,5 / 2 sem | En curso |
| S0b · Atmósfera | [s0b-atmosphere-test.md](s0b-atmosphere-test.md) | 30 s de pasillo medidos en `REF-1` + aprobación de tono | 0,5 / 1 / 1,5 sem | No iniciado |
| M1 · Prototipo gris | [m1-gray-prototype.md](m1-gray-prototype.md) | Escenas 1–3 jugables sin texturas, P1 y puerta A | 2 / 3 / 4 sem | No iniciado |
| M2 · Caja | — (sin línea base) | Sala B + P2, despacho D, caja, P3–P6 | — | Pendiente |
| M3 · Llamada | — | Apagón, llamada, variantes, Recepción | — | Pendiente |
| M4 · Pase de calidad | — | Arte, VO, subtítulos, a11y, perfilado P2/P3 | — | Pendiente |
| M5 · Playtest y demo | — | 5 jugadores, build, vídeo, gate | — | Pendiente |

**Total S0 → M1: 3,5 / 5,5 / 7,5 semanas** (secuencial; S0b puede solaparse con el final de S0
y M1 con el veredicto de S0b, pero con una sola persona el solape reordena trabajo, no lo reduce).
M2–M5 se dan de línea base al cerrar M1, con la velocidad real.

## Desviación respecto al plan (para decisión del usuario, no resuelta aquí)

`docs/PLAN-TECNICO.md` § 4 estima **6–7 semanas para todo el slice** y el slice § 23 da
**1 semana** al prototipo gris. Esta línea base estima **5,5 semanas esperadas solo hasta
M1**, porque desde que se escribió el plan aparecieron 19 ADR `Proposed` con 13 spikes
pendientes o parciales (0002 S4, 0003, 0004, 0005, 0006, 0007, 0008, 0011, 0012, 0013, 0014/S0b, 0015, 0016) y una cola de 69 cambios de diseño. El plan de 6–7 semanas debe considerarse
**optimista** hasta que el primer sprint dé velocidad. No es un recorte de alcance: es un
dato para re-planificar.

## Regla global de recorte

1. **Primero se recorta dentro del hito**, siguiendo su orden de recorte, uno a uno y anotado
   en su «Registro de cambios». Solo después se mueve el plazo.
2. **Disparador:** a la mitad del plazo esperado, si el criterio central del hito no se ve
   (S0: un export arranca; S0b: P1 grabada; M1: se juega la escena 2), se aplica el
   siguiente recorte **y se avisa al usuario**.
3. **Si se supera el pesimista**, se para y se re-planifica con el usuario (`/estimate`,
   `/sprint-plan`); no se encadena otro recorte en silencio.
4. **Lo recortado se mueve, no se borra**: cada recorte nombra el hito destino.
5. **Nunca se recorta:** el invariante «ningún fallo de puzle es terminal»; los límites de
   destellos, el suelo de luz ambiente, el suelo de texto de 24 px y la banda de subtítulos
   (ADR-0019 D4); la regla de que un ADR `Proposed` bloquea su historia; la evidencia
   retenida de lo que se ve.
6. **Lo que cambia pilares, tono o alcance del slice** (p. ej. la escalada E de render, quitar
   la elección en la escena 1) lo decide el usuario.
7. **El rendimiento no se recorta con este orden**, sino con la escalera fija de ADR-0019 D4,
   disparada por medida.

## ADR por hito (los 19 están `Proposed` a 2026-11-11)

| Hito | ADR que debe cerrar |
|---|---|
| S0 | 0001, 0002 (log S4), 0009, 0018 |
| S0b | 0014, 0019 |
| M1 | 0003, 0005, 0006, 0010, 0011, 0012, 0017; parciales 0007, 0008; condicionados al recorte 0004, 0013, 0016 |
| M2+ | 0015 (y lo que M1 recorte) |

## Cola de diseño pendiente (contada, no resuelta)

Fuente: `docs/architecture/adr-reconciliation-2026-11-10.md`. La ronda 2 (R2.2) tiene
**35** cambios (H1–H35) y la ronda 1 (§ 2) otros **34** (G1–G26, A1–A8): **69** en total.
Cada cambio se asigna al primer hito que lo necesita:

| Hito | Ronda 1 | Ronda 2 | Total |
|---|---|---|---|
| S0 | 12 | 0 | 12 |
| S0b | 0 | 6 (4 [U]) | 6 |
| M1 | 11 | 16 | 27 |
| M2+ | 11 (G8–G13, G17, G20, G22–G24) | 13 (H8, H13, H16–H19, H22, H25–H27, H30, H31, H35) | 24 |
| **Total** | **34** | **35** | **69** |

Decisiones del usuario de `design/gdd/gdd-cross-review-2026-11-10-r2.md`: **6** (la n.º 6
agrupa ~8 cuestiones antiguas). S0: 0 · S0b: 1 (n.º 2) · M1: 2 directas (n.º 3, 4) + 2
condicionadas (n.º 1, 5) · el resto de la n.º 6 recae en M2–M5.
Estado de aplicación de la cola: NOT VERIFIED.
