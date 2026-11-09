# Slice «Turno de noche» · Índice del documento

Fuente de verdad: [`slice-v0.3.md`](slice-v0.3.md) (contenido en **versión 0.4**, 2026-11-09; el nombre del fichero se mantiene). **No se edita en caliente**: los cambios entran como nueva versión (v0.4…) con entrada en su historial (sección 24).

## Dónde vive cada parte en el repo

| Parte del documento | Destino en el repo | Estado |
|---|---|---|
| §1–§5 Resumen, objetivo, alcance, pilares, controles | `design/gdd/` (concepto + controles/cámara) | por derivar |
| §6, §9, §11, §12 Personajes, cronología, escenas, guion | `design/narrative/` + `assets/data/narrative/lines.json` (IDs `VO_*`, `MEGA_*`, `NOTA_*`, `CARTA_*`, `DOC_*`) | por derivar |
| §7, Anexo A Espacios y acceso | `design/levels/` (blocking) + `scenes/levels/` | por derivar |
| §8, §13, Anexo D Progresión, flags, guardado | `design/gdd/` (estado y progresión) + `assets/data/state/flags.json` | por derivar |
| §10, Anexo B Puzles | `design/gdd/puzzle-*.md` + `assets/data/puzzles/*.json` + `src/puzzles/` | por derivar |
| Anexo C Eventos y tiempos | `design/narrative/` (timelines) + `src/narrative/` | por derivar |
| §14 Audio, Anexo B.7 SFX/ANIM | `design/audio/` + `assets/audio/` | por derivar |
| §15 Arte y assets | `design/art/` (art bible) + `assets/art/` | por derivar |
| §16–§17 UI, contenido sensible | `design/gdd/` (UI/accesibilidad) + `design/narrative/content-notes.md` | por derivar |
| §18 Declaración de IA (Steam) | `docs/decisions/ai-asset-register.md` (registro por asset) | por crear |
| §19 Criterios de aceptación, §22 Riesgos | `production/milestones/` + `production/playtests/` | por derivar |

## Decisiones

**Cerradas por el equipo en esta sesión**
- **D-05 · Motor:** Godot 4 (versión de referencia pinneada en `docs/engine-reference/godot/`: 4.7). Pendiente confirmar versión instalada y lenguaje con `/setup-engine` (propuesta: GDScript).

**Ajustes autorizados sobre v0.3 (2026-11-09, ver §24, entradas 0.3.1 y 0.3.2):** P1 nivel 1 = resaltado; D.2 `llamada_iniciada` no evita repetir la llamada y `pendiente_revelacion` se escribe al iniciar la revelación; partida sellada al llegar a Recepción (el título ofrece solo «Nueva partida»); «reducir movimiento» en la accesibilidad. 0.3.2: T4 acepta Devolver o asignar (sin respuesta incorrecta), `t4_decision` (20 hechos) y `VO_G_14_RET`/`_ASG` (propuesta pendiente de narrative-director). **Pendientes de v0.4** (pedidos por las re-reviews de la ronda 2 y no aplicados): ver la lista entregada al cerrar el lote (A.0 «escena 7»→«llamada completada (escena 8)», D.3 puertas B/D cerradas al reanudar y causa de guardado al recoger tarjetas, orden de presentación de correos, §8/§13.3 frente al Anexo B, I-01 no persistente, columna «Interacción», secuencia de D01a).

**Abiertas en el documento (siguen abiertas):** D-04, D-06, D-07, D-08, D-10, D-13, D-14, D-15, D-16. Las que bloquean antes de implementar: **D-16** (orden de la caja), **D-14/D-15** (comportamiento de carta y silencio) y **D-10** (preparar claves de traducción desde ya; recomendación: sí, es casi gratis ahora).

## Incoherencias detectadas al procesar el documento

Para resolver en v0.4 (o aclarar al implementar). Entre paréntesis, la lectura que propongo seguir mientras tanto.

1. **Orden de la caja.** §8 y §13.3 dicen que los compartimentos son independientes («en cualquier orden», «ningún compartimento depende de otro»), pero D-16, Anexo B y Anexo D los encadenan (c3 requiere c1; c4 requiere c1, c2 y c3). *(Seguir el Anexo B/D: es el más detallado y es consistente con el puzle 5, que usa la foto del puzle 3.)* Si se mantiene la cadena, §13.3 debe corregirse: en D sí hay dependencias, aunque nunca hay softlock.
2. **Pistas distintas entre §10 y Anexo B.** Los niveles de pista no coinciden en los puzles 3, 4, 5 y 6 (p. ej. P3 nivel 2: «bordes numerados» en §10.3 vs. «mantener PULSAR 0,5 s» en B.3; P4 nivel 1: «marca de color» vs. «regla visible»; P6 solo tiene dos pistas en B.6 y §10 promete tres niveles por puzle). *(Seguir el Anexo B. Resuelto 2026-11-09: el P6 se queda con dos niveles; §10, §16 y §19.2 actualizados.)*
3. **Flags incompletos en §13.1.** Faltan `formulario_leido`, `pos_L/C/R`, `pendiente_revelacion` y `llamada_iniciada`, que sí están en D.2. *(D.2 es canónico.)*
4. **Geometría.** El escritorio A05 (centro X 9,0; ancho 1,20) llega a X 9,6, 10 cm fuera del muro este del Archivo (X 9,5). *(Ajustar al construir el blocking.)*
5. **Equipo de referencia** (§21) sin definir, pero el criterio de aceptación 9 (§19) depende de él. *(Definir antes del primer playtest; ver plan técnico.)*
6. **Sin pista para el puzle 1 salvo la impresión.** Nivel 1 («resaltado de la impresión»; antes «gesto de cámara», sustituido por decisión del usuario 2026-11-09: ningún evento mueve la cámara) presupone que el jugador ya la tiene; si no ha buscado «transición», no hay pista que le guíe hacia el ordenador. *(Añadir una pista de «objetivo» previa; cuestión de diseño, no de motor.)*
