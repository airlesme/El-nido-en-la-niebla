# Cross-GDD Review Report (ronda 4 de revisión · verificación de la ronda 5)

**Fecha:** 2026-11-09 · **Veredicto: CONCERNS** (0 bloqueantes, avisos menores) · **Modo:** autonomous, workflow standard · **Focus:** verificación de lo cambiado (since-last-review)
Informes anteriores: `gdd-cross-review-2026-11-09.md` (FAIL, 8), `-r2` (FAIL, 2), `-r3` (FAIL, 2: C-W6 y C-W8).

- **GDDs reviewed:** 9 of 9 present. Dos revisores independientes sin Bash (Grep y Read): G (C-W6, atracción, `BOX_Cn_OPEN`; 6, 7, 9, registro) y H (C-W8, 18, y los casos de pila y «descarga total completada» en 1, 4, 5). Ambos escribieron borrador a disco antes de terminar.
- **Desviación del procedimiento:** como en las rondas anteriores, lectura por secciones sin contenido pegado.

## Estado de los bloqueantes de r3

| Bloqueante | Estado | Evidencia |
|---|---|---|
| **C-W6** (`multiplicador_pie`, `pie_persistente`) | **CERRADO** | G: coherentes en 6 (catálogo, cuantización/F1, regla 8, AC-01 «trece» = 12 claves restablecibles + `modo_ventana`, AC-04f/04g, AC-06g, AC-07, Tuning Knobs, UI, Dependencies), en 7 (regla 12, F5, Tuning Knobs, AC-15, D7-25/49) y en el registro (dueño 6, `settings_defaults`) |
| **C-W8** (conteo de claves `PISTA_*`) | **CERRADO** | H: 8 niveles con texto (P1 1, P2 1, P3 0, P4 2, P5 2, P6 2); 9 (reglas 27/29, Dependencies, AC-30/35), 18 (regla 20, D18-1) y registro (`hint_key_count` = 8) coinciden |
| E-1/E-2 (vuelta al título, «descarga total completada») | **CERRADO** | H: tres casos recorridos (Nueva partida con el 21, vuelta desde Recepción, fallo de Recepción + «Volver al título») coinciden en 1, 4, 5; aviso con el mismo nombre en 3, 4, 5 y 1 |
| Atracción (`atraccion_desactivada`), AC-30a/b | **CERRADO** | G: mismo nombre en 7 y 9; 170 px → fallo, 200/230 px → advertencia, 260 px → nada; con excepción, nada |
| `BOX_Cn_OPEN` [1,2; 1,6] | **CERRADO** | G: coherente entre 7 (F4, Tuning Knobs, D7-52), 1 (F8, 3–5 s) y registro |

## Warnings (no bloquean)

⚠️ **A-1 · 9↔18.** La regla 25 de 9 admite que `TEXT` use una clave de interfaz, pero las reglas 27/29 y AC-30 exigen siempre `PISTA_*`: un `TEXT` con clave `UI_*` fallaría la validación.
⚠️ **A-2 · 9.** Ningún AC prueba el fallo por clave `PISTA_*` inexistente.
⚠️ **A-3 · 18.** El tipo `SUB_…` (regla 22) no está en la lista de prefijos de la regla 3 ni en AC-03, que fallaría con un `SUB_`; el verificador (regla 16) no comprueba su formato ni el marcador de pendiente; no hay AC para la regla 22.
⚠️ **A-4 · 18 Dependencies.** La fila de 7 y 8 tiene solo 2 celdas; una nota (l. 202) está obsoleta.
⚠️ **A-5 · 4↔5.** La regla 15 de 4 no lista la vuelta al título desde Recepción como petición de descarga total; el respaldo «re-inspecciona al procesar `quit`» de 5 podría dispararse antes del aviso en el fallo de Recepción, lo que roza AC-18g.
⚠️ **G-1 · Registro.** `atraccion_desactivada` no figura en `entities.yaml`.
⚠️ **G-2 · 6 Dependencies (l. 229)** dice «Ninguno de los demás sistemas tiene GDD»; ya no es cierto para 1, 2, 4, 7 y 9.
ℹ️ INFO: 6 cita a 24 (dibuja el pie) y 24 no figura en su tabla de Dependencies; el slice da `BOX_C2_OPEN` = 1,4 s y 7 modela un único valor de 1,6 s (el rango lo cubre); el Overview de 18 dice «tres niveles»; la nota del slice (l. 327) sigue diciendo que 18 mantiene 26 entradas.

*Arrastrados sin cambio (no dependen de estos GDDs):* D-W1…D-W5, D-W7 (parcial: 18 ya tiene el tipo `SUB_…`), D-W8, D-W9 a D-W11; S-W5, E5-1/E5-2, E6-1, E7-1/E7-2 (necesitan GDDs aún sin escribir).

## Verdict: CONCERNS

Sin bloqueantes. Todos los bloqueantes de las cuatro revisiones están cerrados y verificados por un revisor distinto del autor. Los avisos son de redacción y cobertura de ACs; no impiden empezar la arquitectura de los sistemas ya diseñados.

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:** los revisores G y H no leyeron `jugador-en-primera-persona.md`, `systems-index.md`, el slice completo, AC-47 y Tuning Knobs de 9, ni la UI y AC-04f/04g de 6 (solo por grep). Heredado: E6 (llamada) no recorrido; E3/E5/E7 parciales; sin `puzzles.json` ni `flags.json`; sin GDDs de 8, 10–16, 19–28 y 30. NOT SOURCEABLE: `SceneTree.paused`, `AudioStreamPlayer`, `Area3D`/Jolt.
