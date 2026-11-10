<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: ¿Se sostienen NS-1..NS-16 del ADR-0002 en Godot 4.7.2? (variante A, B parcial o B) -->
<!-- Date: 2026-11-10 -->

# pause-spike — Spike de pausa del ADR-0002

**Estado:** en curso (el código se escribió sin poder ejecutarlo: Godot no estaba instalado).
**Hipótesis:** `SceneTree.paused` + `process_mode` explícito congela lo que el ADR dice y deja
correr lo que debe (variante A). Fuente: `docs/architecture/adr-0002-pause-and-game-time.md` § Spike Plan.
Proyecto independiente: no toca `project.godot` de la raíz ni `src/`.

## Instalar Godot 4.7.2

Descargar `4.7.2-stable` desde https://godotengine.org/download/archive/ (o
https://github.com/godotengine/godot/releases). Para el modo sin ventana basta la versión
estándar (la consola de Windows es `Godot_v4.7.2-stable_win64_console.exe`). Hay que usar
exactamente 4.7.2 para que el resultado cuente como «verificado 4.7.2».

## Ejecutar (headless, sin GPU ni audio real)

Desde la raíz del repo:

```
godot --headless --path prototypes/pause-spike --quit-after 20000
```

`--quit-after` es solo un seguro (cuenta frames; las pruebas necesitan unos 3000 con el retardo
artificial de frame). El runner sale solo con `get_tree().quit(code)`:
`0` = ninguna prueba núcleo en FAIL ni UNVERIFIED (S4 queda como NEEDS_WINDOWED, ver abajo);
`1` = alguna núcleo FAIL; `2` = alguna núcleo UNVERIFIED_API.
Duración aproximada: 1–2 minutos (cada «ventana de pausa» son 120 frames de ~14 ms).

Filtrar: `godot --headless --path prototypes/pause-spike -- --only=S1,S5`.

## Ejecutar con ventana (pruebas NEEDS_WINDOWED)

```
godot --path prototypes/pause-spike
godot --path prototypes/pause-spike -- --only=S7,S10,S11,SB3
```

En ventana, `windowed.gd` ejecuta S7, S10, S11 y SB3 y guarda capturas en `user://`
(`OS.get_user_data_dir()` se imprime al final; en Windows `%APPDATA%\Godot\app_userdata\pause-spike`).
Revisar a ojo `pause_spike_s7_paused_*.png` (idénticas en la región central) y
`pause_spike_s7_resume_*.png` (sin salto de densidad). Para S11 poner vsync off (el script lo
hace) y mirar si hay «pop» al reanudar. **S4 manual:** con la ventana abierta pulsar teclas,
clic y conectar/desconectar un mando durante una pausa; requiere un arnés interactivo que este
spike no incluye (solo simula eventos de teclado/ratón); anotar si el foco de un `Button` en un
`CanvasLayer` ALWAYS se mueve con teclado y mando.

## Qué pegar de vuelta

1. Todas las líneas `RESULT …`, `API …` y `SUMMARY …` de la consola.
2. El JSON entre `RESULTS_JSON_BEGIN` / `RESULTS_JSON_END` (también en `results.json`, junto al
   proyecto si `res://` es escribible, y siempre en `user://results.json`).
3. Cualquier error o warning de GDScript (parse errors incluidos) tal cual.
4. Las observaciones manuales de S4, S7, S10, S11, SB3 y la escucha de S8/S9.

## Afirmación → prueba → criterio

| NS | Prueba | Modo | Criterio PASS (resumen) | Regla |
|---|---|---|---|---|
| NS-1 | S1 | headless | 0 llamadas `_process`/`_physics_process` en 120 frames pausados (1 tolerada); reanuda en 1 frame | núcleo |
| NS-2 | S2 | headless | 5 constantes `PROCESS_MODE_*` distintas; INHERIT sigue al padre (PAUSABLE/ALWAYS); `WorldSlot` PAUSABLE explícito independiente del root | núcleo |
| NS-3 | S3 | headless | 120 ±1 llamadas en ALWAYS; Σdelta ±5 % del tiempo real; delta > 0 | núcleo |
| NS-4 | S4 | simulado + manual | sonda ALWAYS recibe todos los eventos, PAUSABLE 0 (simulado); foco/mando/clic reales a mano | núcleo |
| NS-5 | S5 | headless | tween del mundo constante bit a bit en pausa, termina a 1.0 s sin pausa ±0.06, sin salto > 2 frames; tween de velo `TWEEN_PAUSE_PROCESS` termina en pausa | parcial B |
| NS-6 | S6 | headless | posición constante, método de la pista 1.0 s 0 veces en pausa y 1 tras reanudar, fin a 1.6 s sin pausa ±0.06 | parcial B |
| NS-7 | S7 | ventana | región de partículas idéntica en f+1/f+60/f+120; sin ráfaga al reanudar (a ojo) | parcial B |
| NS-8 | S8 | headless + oído | posición se mantiene ±0.05 en pausa; reanuda sin reinicio (escala reducida: pausa a ~1 s, ventana 2 s) | ADR-0008 |
| NS-9 | S9 | headless + oído | reproductor ALWAYS avanza ≈ tiempo real ±5 % en pausa; PAUSABLE informativo | núcleo |
| NS-10 | S10 | ventana | informativo: ¿avanza `TIME` en pausa? | — |
| NS-11 | S11 | ventana | transform interpolado idéntico en pausa; salto al reanudar ≤ 1 paso físico (+ revisión visual) | parcial B |
| NS-12 | S12 | headless | `CharacterBody3D` (Jolt) sin guarda G-4: posición fija, `velocity` intacta, primer paso igual | parcial B |
| NS-13 | S13 | headless | señal/Callable/cola desde ALWAYS hacia nodo PAUSABLE: síncrono, una vez, mismo frame | núcleo |
| NS-14 | S14 | headless | `queue_free()` en pausa libera en ≤ 3 frames ×10; monitores de nodos/huérfanos vuelven a la base | S14 |
| NS-15 | S15 | headless | informativo: orden de `_process` con y sin `process_priority` | — |
| NS-16 | S16 | headless | informativo: qué temporizadores avanzan en pausa | — |
| — | SB1 | headless | como S5 con `Tween.pause()/play()` y el árbol sin pausar | opción B |
| — | SB2 | headless | como S6 con `AnimationPlayer.pause()/play()` y con `speed_scale = 0` | opción B |
| — | SB3 | ventana | como S7 con `GPUParticles3D.speed_scale = 0` | opción B |

Regla de decisión (ADR): núcleo S1–S4, S9, S13 todas PASS → A viable; cualquier FAIL → B completa;
FAIL en S5/S6/S7/S11/S12 → B parcial de ese tipo; S14 FAIL → 25 reanuda antes de T3; S8 → ADR-0008.

## Notas

- El runner añade `OS.delay_msec(12)` por frame para que Δ sea realista en headless.
- Cada prueba nace de un `_reset()` que despausa y libera todo.
- Se imprime `API Clase.miembro OK|MISSING` (vía `ClassDB`) para los nombres de API dudosos.
- S16 usa `create_timer`/`Timer` solo porque está en `prototypes/` (permitido por D6).
