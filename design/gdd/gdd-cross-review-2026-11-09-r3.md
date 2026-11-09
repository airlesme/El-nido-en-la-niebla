# Cross-GDD Review Report (ronda 3 de revisión · since-last-review + cobertura de 6 y 18)

**Fecha:** 2026-11-09 · **Veredicto: FAIL** (2 bloqueantes, ambos arrastrados como avisos desde la primera revisión y elevados al leer por fin los GDDs 6 y 18) · **Modo:** autonomous, workflow standard
Informes anteriores: `gdd-cross-review-2026-11-09.md` (8 bloqueantes) y `…-r2.md` (2 bloqueantes).

- **GDDs reviewed:** 9 of 9 present. Revisor E: verificación de los cambios de la ronda 4 (1, 3, 4, 5, 7, 9, registro, índice). Revisor F: lectura completa de 6 y 18 (los dos que nadie había leído).
- **Desviación del procedimiento:** igual que antes, lectura por secciones sin contenido pegado (~680 KB). E y F agotaron su límite de turnos una vez y se reanudaron para volcar lo comprobado. E no pudo usar Bash (`git diff`) y revisó el estado actual con Read y Grep.
- **Decisiones del usuario respetadas:** las de los informes anteriores.

## Estado de los bloqueantes de r2

| Bloqueante | Estado | Evidencia (revisor E) |
|---|---|---|
| **N-B1** (`control_final` de `partida_nueva`, pila bajo el `sin control`) | **CERRADO** | Casos título→Nueva partida, título→Continuar, partida_nueva desde la planta y fallo de carga coinciden entre 1 regla 6, 4 reglas 7/9/14, AC-21b, AC-E13b, 5 regla 24 y AC-18f |
| **B-1** (separación de elementos de vista) | **CERRADO** | 7 regla 22/AC-30/Edge Cases, 9 regla 29/AC-35/AC-47 y 1 Open Question 3 dicen lo mismo: asistida 220 px/R=128/256 px solo advertencia; normal 88 px/176 px fallo sin excepción |
| **B-4** (tope de 3 s frente a la cadena de `D01a`) | **CERRADO** | 1 F8 (3–5 s), registro (`player_camera_transition_cap_s`, `BOX_Cn_OPEN` 1,2–1,8) y 7 F4 coinciden |

---

## Consistency Issues

### Blocking

🔴 **C-W6 → bloqueante · 6↔7 · `multiplicador_pie` y `pie_persistente` no existen en Ajustes.**
7 los pide «para el 6» (l. 321, 439, AC-15, D7-25). 6 no los tiene en el catálogo, en «restablecer todos», en AC-01 ni en su lista de dependientes, y el registro tampoco. `alternar` sí está cubierto (bloque `controles` de Entrada). Una referencia a un ajuste que no existe es bloqueante (2c).
Opciones: (a) 6 añade los dos ajustes con rango, defecto, persistencia y AC; (b) 7 los retira y fija el valor en sus Tuning Knobs.

🔴 **C-W8 → bloqueante · 9↔18 · Conteo de claves `PISTA_*`.**
9 regla 29 (l. 206) exige «tres pistas (dos en P6) con claves existentes en 18» (17 claves). 18 crea solo 8, las de las pistas con texto (D18-1), igual que `hint_key_count` del registro. Aplicada al pie de la letra, la validación de 9 aborta el arranque. Los textos de dependencias de 9 (l. 282, 442) y su regla 27 dicen lo mismo.
Opciones: (a) 9 valida solo las pistas con texto contra las claves de 18 y comprueba los efectos contra los datos del puzle (recomendado, coincide con D18-1); (b) 18 crea las 17 claves con texto vacío en las no textuales.

### Warnings

⚠️ **F-1 · 18 Dependencies (l. 196)** usa la numeración obsoleta «2 Cámara y movimiento · 4 Guardado · 5 Transiciones de escena» y dice «cierra OQ 11 del GDD 6», pero esa pregunta sigue abierta en 6.
⚠️ **F-2 · 18 `VO_G_14`.** El slice §12 ya tiene `VO_G_14_RET` y `VO_G_14_ASG` (27 entradas); 18 las marca «no son del §12» y sigue contando 26 (regla 2, AC-02, AC-03). El verificador fallaría. El grupo `VO_G_14` falta en la regla 5, la regla 16 y AC-05.
⚠️ **F-3 · 6 regla 7** no recoge la baja automática de suscriptores al descargar la planta (3 l. 150) ni tiene AC para ella. 6 no lista al 18 en Dependencies aunque el índice sí. 4 (l. 387–389) dice que falta `reducir_movimiento` en 6, y ya está.
⚠️ **E-1 · Caso (v), vuelta al título desde Recepción.** 1 regla 6 y AC-E13b presentan como «único caso legítimo» el cierre del 21 sobre [`menú`, `sin control`(21)], pero según 4 (l. 62) en Recepción la pila es [`sin control`(21)] sin `menú`; el título lo repone el 4 con la descarga total. El caso no puede darse tal cual: reescribir la justificación.
⚠️ **E-2 · «descarga total completada».** 5 regla 17 no nombra el aviso (solo el párrafo «Re-inspección»), y 4 regla 14 no dice si el fallo de carga de Recepción lo emite.
⚠️ **E-3 · Campo de la excepción de atracción.** Ni 7 ni 9 le dan un identificador único; solo la frase «atracción desactivada en esa zona». `puzzles.json` no existe aún.
⚠️ **E-4 · AC-30 de 7:** a 170 px con tolerancia normal pide a la vez «advertencia» y «fallo de arranque».
⚠️ **E-5 · Margen de la cadena:** con `BOX_Cn_OPEN` = 1,8 y `t_vista_entrada_s` = 1,2 la cadena suma 3,0 s (margen 0); F4 solo garantiza 0,2 s con 1,6. Notas obsoletas en 7 (l. 446) y en el registro (l. 508).
⚠️ **Arrastrados de r2 sin cambio:** D-W9 a D-W11 y D-W1…D-W8 vigentes (revisor C); D-W7 sigue abierto (18 sin tipo de contenido ni pregunta abierta para el subtítulo del llanto); E1-1 (S-W5), E5-1/E5-2, E6-1, E7-1/E7-2 (dependen de GDDs aún sin escribir).

---

## Game Design Issues

Sin cambios respecto a r2 (0 bloqueantes). F confirmó: `VO_G_13B` = «Lo sé», `t4_decision`, regla 21 de 18 («Vuelve a intentarlo desde el título») y «No corresponde» solo para T1–T3. Tuning Knobs de 6 (`volume_steps` 20, `volume_db_min` −40, `fov_step_deg` 5, `asistencia_rotacion_deg` 6) coinciden con el registro; `asistencia_encaje` (0,04/0,10 m → 88/220 px) es coherente con 1 F5b, 7 F6/AC-32 y 9 AC-08; los ACs de 6 no chocan con los de 1, 2, 4 ni 5.

## Cross-System Scenario Issues
Sin escenarios nuevos esta ronda; sin blockers firmes. E4-1 (= N-B1) cerrado. Resto igual que en r2.

---

## GDDs Flagged for Revision

| GDD | Motivo | Tipo | Prioridad |
|---|---|---|---|
| ajustes-persistentes.md (6) | C-W6 (`multiplicador_pie`, `pie_persistente`), F-3 | Consistency | Blocking |
| interaccion-e-inspeccion.md (7) | C-W6 (opción b), E-3, E-4, E-5 | Consistency | Blocking |
| marco-de-puzles.md (9) | C-W8 (reglas 27 y 29, l. 282 y 442), E-3 | Consistency | Blocking |
| base-de-contenido-narrativo.md (18) | F-1, F-2, D-W7 | Consistency / Design | Warning |
| entrada-y-controles.md (1) | E-1 | Consistency | Warning |
| guardado-y-carga.md (5) · escena-de-planta.md (4) | E-2 | Consistency | Warning |

## Verdict: FAIL

2 bloqueantes (C-W6, C-W8). Ninguno nace de la ronda 4: ya existían y no se habían podido comprobar porque nadie había leído 6 y 18. Los bloqueantes de las rondas anteriores (N-B1, B-1, C-B1…C-B4, S-B1, D-B1, D-B2) están todos cerrados.

### Required actions before re-running
1. **C-W6:** decidir (a) o (b) y aplicarlo en 6 y 7.
2. **C-W8:** 9 valida solo las claves con texto (opción a); corregir 9 regla 29 (l. 206), l. 282, l. 442 y regla 27.
3. 18: numeración de dependencias, `VO_G_14` (27 entradas, grupo en reglas 5 y 16 y AC-05), OQ 11, tipo de contenido para sonido no verbal (D-W7).
4. 6: baja de suscriptores al descargar y dependencia con 18. 1: justificación del caso (v). 5 y 4: nombrar «descarga total completada» en las reglas 17 y 14. 7: AC-30, margen de la cadena, notas obsoletas, y un identificador único para la excepción de atracción en 7 y 9.

---

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:**
- E no leyó: 3 regla 10 completa (solo la fila de emisores) y CA-01, AC-F8 de 1, el contador de emisores del índice y el slice.
- No existen `puzzles.json` ni `flags.json`, así que nada de datos se pudo contrastar. No existen GDDs de 8, 10–16, 19–28 ni 30.
- Heredado de r2: E6 (llamada) no recorrido; E3/E5/E7 parciales; referencias muestreadas 34 de ≥ 40; IDs de decisión citados sin verificar uno a uno.
- NOT SOURCEABLE: `SceneTree.paused`, `AudioStreamPlayer`, `Area3D`/Jolt (S-W5, AC-09 de 2, AC-05a/b de 4).
