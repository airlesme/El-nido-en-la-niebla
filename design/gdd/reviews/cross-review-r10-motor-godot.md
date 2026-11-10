# R14-G Revisión de afirmaciones de motor (Godot 4.7)

## Cobertura de la documentación fijada (docs/engine-reference/godot/)
- audio.md: AudioStreamPlayer/3D (`play`, `volume_db`, `bus`, `finished`), `AudioServer.set_bus_volume_db`, `set_bus_mute`, `get_bus_index`, Tween en volumen; 4.7: `area_mask` por defecto 0 (audio_bus_override en Area3D). NO cubre: ducking, efectos de bus (limitador/filtro), `stream_paused`, `AudioListener3D`, pausa.
- animation.md: AnimationPlayer/AnimationMixer (`active`, `callback_mode_method`), 4.7 `Tween.tween_await()`. NO cubre pausa, `speed_scale`, `process_callback`.
- ui.md: dual-focus 4.6, AccessKit en Control (4.5), `accessibility_live` tipado (4.7), stretch por defecto 4.7, RichTextLabel. NO cubre FontFile, escalado de texto, Theme avanzado, CanvasLayer.
- rendering.md: D3D12 por defecto en Windows (4.6), glow antes de tonemapping (4.6), SMAA (4.5), Shader Baker (4.5), stencil (4.5), HDR (4.7), AreaLight3D, Compositor. NO cubre `instance uniform`, `#include`, `render_priority`, `hint_*`, Environment, ReflectionProbe, `distance_fade`.
- input.md: SDL3, dual-focus, `InputEvent.device` por tipo (4.7), VirtualJoystick. NO cubre InputMap en runtime ni remapeo.
- physics.md: Jolt por defecto (4.6), Area3D/SoftBody en Jolt (4.7). NO cubre consultas de forma ni `ShapeCast3D` con Jolt.
- breaking-changes / deprecated / best-practices: grep de `paused`, `process_mode`, `PROCESS_MODE`: sin resultados. SceneTree.paused y pausa de audio/animación: NO cubiertos.

## Hallazgos

### POSIBLEMENTE ERRÓNEA
- BLOQUEANTE-menor/AVISO alto: 29 shaders-y-efectos R35: «un `Tween` en `PAUSE_MODE_PAUSABLE`». `PAUSE_MODE_*` es nomenclatura de Godot 3; en Godot 4 es `Node.PROCESS_MODE_PAUSABLE` (28 R22 lo escribe bien). Nombre inexistente en 4.7. Corregir (y el Tween usa `Tween.set_pause_mode(TWEEN_PAUSE_STOP)`, como 28 R7).
- AVISO alto: 29 R45: «Los materiales de 29 (`unshaded`) no reciben glow ni exposición automática del `Environment`». El glow es un postproceso sobre el color renderizado (4.6: antes del tonemapping, rendering.md); `unshaded` no exime. NO SOURCEABLE y probablemente falso; condiciona la medida de AC-3 (L_txt >= 0,80). Marcar o eliminar; medir en captura.
- AVISO: 29 R35: «las luces de `TIME` en shader no se congelan» en pausa: comportamiento no cubierto, sin marca; la mitigación (uniform desde reloj de juego) es válida con independencia.

### NOT SOURCEABLE sin marcar
- 27 pantalla-de-titulo R14: `SceneTree.quit()` «(API estándar de Godot 4.x)»: no figura en la documentación; la afirmación de «estándar» sustituye a la marca.
- 24 prompt-de-interaccion AC-24-07 (V): «filtros de daltonismo del motor»: no cubierto; tiene alternativa («herramienta fija») pero la premisa debe marcarse.
- 29 R7/R14/D29-13: «un material tiene un único `render_priority` y `blend_mode`», orden de dibujo por `render_priority` para atenuar el reflejo bajo el texto (R14): no cubierto, sustenta un diseño (cristal de P2).
- 29 fórmula `w_uv = w_px · fwidth(UV)` «disponible en el lenguaje de shaders de Godot»: no cubierto.
- 29 R6/R40: `hint_screen_texture`/`hint_depth_texture`, Forward+ cluster: no cubierto (basta como restricción negativa).
- 28 R7: `Tween` sobre `light_energy`; R-luz de manos, `distance_fade`, ReflectionProbe: 28 OQ 10 los lista con ‡ (OK, marcado) salvo `light_energy` sin marca (trivial).
- 23 línea 412: «Este GDD no cita ninguna API que no figure allí [audio.md]» es falso: cita `stream_paused`, `process_mode`, `AudioListener3D`, limitador, filtro (todos con «no verificado» en otros puntos). Corregir la frase.
- 25 menu-de-pausa OQ 2: reconoce que pausa del árbol, `process_mode`, Tween y AudioStreamPlayer en pausa no están cubiertos (marcado). Es el asunto abierto desde la ronda 1: sigue abierto.

### SOURCED
- AudioStreamPlayer/3D, bus por `AudioServer.set_bus_volume_db`/`set_bus_mute`, `finished` (audio.md); Tween en volumen (audio.md).
- AccessKit desde 4.5 en Control (VERSION.md, ui.md): 30 R22, 27 R19/OQ10, 24 OQ5 lo citan correctamente y declaran que no se promete.
- Forward+ como renderer, Shader Baker 4.5+, SMAA/Stencil (D29-4), HDR 4.7 y glow 4.6 (rendering.md): 29 R40/R43/R45, 28 línea 214.
- Jolt + Area3D (AC-09 de 4, marcado PV) y consultas de forma no cubiertas (7 D7-27, marcado): físicamente correcto.
- Foco dual 4.6 (entrada R, input.md) citado en OQ6 de 1.

### NOT SOURCEABLE marcadas correctamente
- 23: R41 `stream_paused`, rampa en dB, limitador, filtro por fuente, `AudioListener3D` (OQ 12); 26: «línea iniciada» ‡, `pause_opened` ‡ (son eventos de diseño); 28: R7/R22 ‡ (Tween pause mode, PROCESS_MODE_PAUSABLE y pausa de GPUParticles3D), OQ 10 spike; 29: `#include`, `instance uniform`, Shader Baker con instance uniform, spike R44; 25 OQ 2.

### ACs cuyo tipo oculta dependencia de motor (L/I que deberían ser PV o llevar spike)
- AC-23-32 (L): muestra suena con menú abierto mientras una línea queda pausada: depende de `process_mode` y `stream_paused` (no verificados): pasar a PV.
- AC-23-14: mide dBFS con limitador de techo (no verificado): PV hasta el ADR de audio.
- AC-28-16 (I): pausa de Tween/partículas: depende de ‡; ya enlazada con OQ 10, pero debe declararse PV.
- AC-26-13 (I): reloj de bloques detenido en pausa: depende solo de eventos de diseño; OK si 26 usa reloj de juego (no del motor).
- AC-29-3 / AC-29-17: «sin advertencias» de compilación y L_txt con glow/HDR: PV (R45).
- AC-24-07 (V): depende de filtros del motor.

### APIs desaconsejadas/cambiadas 4.5–4.7 prescritas
- Ninguna en uso de `playback_active`/`method_call_mode` (grep sin resultados). No se prescribe `audio_bus_override` ni `area_mask` (no hay coincidencias), ni `device == 0`.
- Riesgo futuro: dual-focus 4.6 sobre menús 25/27/30: solo citado en 1 OQ6; 25/27/30 no tienen regla de foco por teclado/mando frente a ratón. INFO.

## NO LEÍDO
Cuerpo completo de 9, 10, 21, 22 y 2/4 (solo grep por API; líneas largas omitidas por el filtro: 23 línea 492, 29 líneas 10/54/56/60/99/295, 30 líneas 106/122, 26 líneas 16/43/82/84, 1 línea 235/581, 7 línea 296); breaking-changes.md, deprecated-apis.md y current-best-practices.md solo por grep; navigation.md y networking.md.
