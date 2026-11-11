# Evidencia S0: ejecutables exportados (Windows)

Capturadas el 2026-11-11 con el modo `--write-movie` del propio motor (frame 5 de 5, 960x540 pedido, 1152x648 renderizado): el motor escribe el fotograma que renderiza, **no** se captura la pantalla del escritorio.

| Fichero | Preset | Qué se ve |
|---|---|---|
| `playtest-windows.png` | `playtest-windows` (export debug) | Fondo gris uniforme: la escena vacía `Main` (solo `Boot`) sin contenido de juego. Es lo esperado en S0 |
| `demo-windows.png` | `demo-windows` (export release) | Igual: gris uniforme, escena vacía |

Consola de ambos al arrancar (`--boot-report`): `playtest` → `[boot] flavor=debug …`, `demo` → `[boot] flavor=release …`.

Lo que NO está aquí: capturas de los exportados de Linux (solo se exportaron; sin ejecutar).

Nota: un primer intento de captura con `CopyFromScreen` de la ventana recogió contenido del escritorio del usuario; esas imágenes se borraron sin guardarse ni versionarse.
