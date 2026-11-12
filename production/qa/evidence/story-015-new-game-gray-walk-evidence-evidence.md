# Evidencia — CP-015 Partida nueva hasta la planta gris

Fecha: 2026-11-12 · Godot 4.7.2 local (editor, no export) · Resumen de verificación: `--import` sin errores; `--boot-report` imprime `[boot] ...`; arranque headless con arranque automático 600 fotogramas sin errores; suite bloqueante 954/954, 0 orphans, 0 `ObjectDB instances were leaked` / `resources still in use`; `forbid_timers` limpio; `project.godot` sin cambios.

## Qué se hizo

- `Boot.wire_scene_loading(ctx, slot, alpha_sink, panel)`: `SceneSource` real, `WorldSlot`, `LoadTransitions`, `RealClock`, `contexts_port()` (a 4), `Curtain.set_alpha`, puerto de error y de descarga del `ErrorPanel`. `Boot.start_new_game(ctx)`: cortina negra inicial y `request_load(PLANTA, PARTIDA_NUEVA, EXPLORACION)`; `control_final = exploracion` porque el Director (21) no existe (`TODO(director-21)`). Se desactiva con `-- --no-autostart` (y `--boot-report` sale antes).
- Captura del ratón mínima en `InputRouter` (R-S3-8, `TODO(input-owner)`).
- Ficheros fuera de lo previsto: `src/shell/curtain.gd` (`set_alpha`), `src/scene/scene_loader.gd` (`prime_curtain_dark`), `src/input/input_router.gd` (ratón), `src/player/player.tscn` (grupo `scene_element`: sin él `configure_all` nunca configuraba al Player), `tools/evidence/*` (runners de captura y de S-0003-C).

## Criterios

| Criterio | Estado | Evidencia |
|---|---|---|
| AC-11a (`partida_nueva`: spawn_office ±0,01 m, v=0, yaw ±0,5°) | Cumplido | `tests/integration/scene/new_game_boot_walk_test.gd` |
| AC-12a α=0,5 (luminancia 50 % ± 5 %) | Cumplido | `carga-015-curtain-a050.png`: α=0,5000, ratio 0,4975 (reloj forzado 50 ms/fotograma, `tools/evidence/carga_015_capture.tscn`) |
| AC-12a α=1 (RGB 0,0,0 centro y 4 esquinas, sin UI) | Cumplido | `carga-015-curtain-a100.png`: píxeles (0,0,0) medidos en los 5 puntos |
| C-M1-7 captura del Archivo | Parcial | `carga-015-archivo.png` y `carga-015-despacho.png` (motor, editor). Falta en export |
| C-M1-1 `playtest-windows`/`playtest-linux` | No | No se exporta (posterior) |
| AC-X2 (parcial) recorrido en gris | Parcial | Automático: cortina solo cambia en el aclarado (primada a 1, sin fundido de salida) y sin UI de carga. Recorrido humano: no hecho |
| S-0003-C | Cumplido (informativo) | ADR-0003 § Spike Results: instanciar mediana 293,5 ms / peor 307,7 ms; hueco de fotograma mediana 349,7 ms / peor 386 ms (5 procesos). < 1 s. Editor local sin hardware de referencia ni export |

## Para la sesión manual del usuario

1. `Godot_v4.7.2-stable_win64.exe --path C:\dev\personal\el-nido`: ver el aclarado de 2 s, caminar (WASD/stick izq.), mirar (ratón capturado/stick der.) por despacho, pasillo y Archivo; comprobar que el ratón se libera al cerrar la ventana y no hay interfaz de carga.
2. C-M1-1 y C-M1-7 en builds exportadas `playtest-windows`/`playtest-linux`, sin consola; repetir S-0003-C en el export.
3. Teclado y mando (AC-04 I), fps 30/60/144 (jugador-013), un fallo de carga real con el panel en export (CP-014).
4. Nota: la captura del ratón no tiene test automático (el modo se ignora en headless).
