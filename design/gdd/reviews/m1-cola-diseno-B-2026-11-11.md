# M1 cola de diseño, lote B — 2026-11-11

Fuente: `production/milestones/m1-gray-prototype.md` § Cola de diseño; `docs/architecture/adr-reconciliation-2026-11-10.md` (§ 2, R2.2).
Numeración de GDD = índice de sistemas (GDD 1 = entrada-y-controles, GDD 2 = jugador-en-primera-persona, GDD 18 = base-de-contenido-narrativo, GDD 19 = ordenador, GDD 21 = director, GDD 22 = llamada). Ningún cambio aplicado toca tiempos, textos ni pilares del slice; ninguno es [U].

| Cambio | GDD | Estado | Línea |
|---|---|---|---|
| H10 (signos de `consume_look_delta()`) | GDD 1 = `entrada-y-controles.md` F2–F3 | NO APLICADO: el destino es GDD 1, fuera de los ficheros del lote (`consume_look_delta` no aparece en ningún GDD); pasar al lote de entrada | — |
| H11 r22 (sondeo, no bus) | jugador-en-primera-persona | APLICADO | regla 22; D-45 |
| H11 OQ 4 (`apuntar`: TwoBoneIK) | jugador-en-primera-persona | APLICADO | Open Questions fila 4; D-45 |
| H11 OQ 9 (`HAND_CARD_SWIPE`) | jugador-en-primera-persona | APLICADO (sigue abierta; propietario actualizado) | Open Questions fila 9; D-45 |
| H12 (filas ADR-0012/0013 de `architecture.md`) | `architecture.md` | NO APLICADO: no es GDD ni está en los ficheros del lote | — |
| G5 (`control_final`, `t_since_started_s`) | director-de-escenas F5 | APLICADO | F5 y tabla de variables; DT-31 e |
| G5 | GDD 3 r10, GDD 4 | NO APLICADO: fuera del lote | — |
| H23 (`TELEFONO_*` sobre `V02`) | director-de-escenas | APLICADO (dueño del nodo sigue abierto, ADR-0017 OI-2) | regla 4 fila `ESC1_LLEGADA`; DT-31 b |
| H23 | llamada-telefonica | APLICADO (nota) | D22-34 |
| H23 | GDD 7 | NO APLICADO: fuera del lote | — |
| H24 (estados de objeto, regla 4) | director-de-escenas | APLICADO | regla 4 filas `ESC7_APAGON`, `ESC8_ASCENSOR`; DT-31 a |
| H24 (regla 7 / AC-21-26: cola en 23) | director-de-escenas | APLICADO | regla 7, AC-21-26; DT-31 c (F4 y su fila de esperas no se han releído: revisar que no hable de «aplazar» por 21) |
| H24 (Tuning Knobs: ruta y ubicación) y G14 | director-de-escenas | APLICADO | Tuning Knobs, regla 3, Entradas para el registro; DT-31 d |
| H20 (claves `UI_ACCION_*`, `UI_SUB_*`, `TEL_MENSAJE_*`, `UI_TITULO_JUEGO`, `UI_CONTINUARA`) | base-de-contenido-narrativo | APLICADO | regla 24; D18-33 |
| G23 (`seg_b_inicio_s` opcional) | base-de-contenido-narrativo | APLICADO | regla 24; D18-33 (GDD 26 OQ 1 fuera del lote) |
| G14 (ruta de datos) | base-de-contenido-narrativo | APLICADO (OQ 1: ruta cerrada por ADR-0005 D2.3; el verificador sigue abierto) | Open Questions fila 1; D18-33 |
| H21 (overlay del ordenador) | ordenador-correo-impresora | APLICADO (con tensión anotada con la cláusula de cámara de R18) | R18; D19-24 |
| G14 (`computer/computer.json`) | ordenador-correo-impresora | APLICADO | Tuning Knobs; D19-24 |
| G14 (`call.json` pierde ‡) | llamada-telefonica | APLICADO | Tuning Knobs, Entradas para el registro; D22-34 |
| G14 claves `t_cap`, `n_gap`, `delta_max`; rutas de GDD 4, 5, 7, 17 | otros GDD | NO APLICADO: fuera del lote | — |
