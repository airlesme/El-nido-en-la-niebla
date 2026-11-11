# S0b - Prueba de atmosfera (prototipo desechable)

`# PROTOTYPE - NOT FOR PRODUCTION`. Hito: `production/milestones/s0b-atmosphere-test.md`.
Fuentes: ADR-0014 (D1-D12), ADR-0019 (D5), GDD 28, slice A.3.

**Estado: in-progress** (arnes y escena verificados con carreras cortas; faltan las carreras P1 en REF-1 y los veredictos).

## Hipotesis

(1) Un pasillo en gris con 6 `C03`, reflejo `C02`, lluvia en ventanal, glow y AgX transmite el tono.
(2) Cabe en `REF-1` (iGPU Intel): 99 % de fotogramas <= 16,6 ms, 28 <= 1,0 ms GPU / <= 0,15 ms CPU media.

## Como ejecutar

Proyecto Godot independiente (Forward+, Jolt, D3D12 en Windows; no toca el proyecto raiz).

```
godot --path prototypes/s0b-atmosphere                      # interactivo (reloj real, bucle de 30 s; P pausa, Esc sale)
godot --path prototypes/s0b-atmosphere -- --perf-run --vsync=0 --out=C:/ruta/p1-run1.csv
```

Export de medida: preset `profiling` (Windows release, tag `profiling`, `export_presets.cfg`;
nombres de propiedades NO VERIFICADOS hasta el primer export). Usar la `.console.exe` para ver la salida;
ademas se escribe `<out>.summary.txt` con el mismo resumen.

Argumentos tras `--`: `--perf-run` (descarta 120 fotogramas, graba 1800, sale con 0), `--out=`, `--vsync=0|1`
(0 => `max_fps=0`), `--scale=1.0|0.85|0.77` (+`--scale-mode=bilinear|fsr`), `--rain=0|1`, `--rain-mode=ratio|emit`
(S0b-4), `--shadows=0|1|2`, `--glow=0|1`, `--lights-n=<n>` (0-14), `--c28=0|1` (subarbol de atmosfera;
metodo diferencial), `--no-reflection`, `--frames=N`, `--warmup=N`, `--luma-every=N` (0 = off por defecto: la
lectura del viewport detiene la GPU y falsea la medida; usar `--luma-every=1` solo en la captura de S0b-6),
`--clock=real|frame`, `--blackout=0|1`, `--shot=<png> --shot-at=<ms>`.

## Decisiones del prototipo

- **Reloj propio en ms enteros**, sin `Tween` ni `SceneTreeTimer` (ADR-0014 D3). En `--perf-run` el reloj es de
  fotograma (1 fotograma = 1000/60 ms, el recorrido cubre exactamente los 1800 fotogramas grabados y se mantiene
  quieto durante el calentamiento); en interactivo es la suma de diferencias de `ticks_msec`, congelado en pausa.
- Guion (tiempos de recorrido): parpadeo 10,0 s (3 caidas de 150 ms, pausa 350 ms, f=0,40: GDD 28 R9);
  reflejo retardado 16,5-19,5 s (tau 0,6 s); apagon 22,0 s (0,4 s monotono, `lluvia_apagon`=0, suelo ambiente 0,06);
  restauracion 25,0 s (2,0 s lineal, `LLUVIA_VUELVE` 2,0 s). Paradas de auditoria: X = 3, 7, 11, 15, 19, 23.
- **Valores del GDD tal como estan escritos.** La decision del usuario sobre 1,15 s / 0,8 s con
  `reducir_sobresaltos` NO esta tomada: no hay variantes `reducir_*` en el prototipo.
- Pasillo X 0..26 (la ruta recorre 20 m, X 3->23). Cristal con shader de fresnel propio (no es el shader del 29).
- `frame_delta_smoothing=false` en el proyecto (si no, `delta` se ajusta a multiplos del refresco).
- Las luces ocultas (`visible=false` con energia 0) cuentan como no habilitadas en la auditoria (NS-A1).
- `frame_time_ms` es `delta` del motor; `ticks_dt_ms` es la diferencia de `Time.get_ticks_usec()` (NS-P6).
  Las columnas `TIME_PROCESS`/`TIME_PHYSICS` y la fila de cada fotograma reflejan el fotograma anterior.
- Auditoria "visible" = habilitada y (posicion en frustum o dentro de su rango): aproximacion, no consulta real.

## CSV

`frame,t_ms,frame_time_ms,ticks_dt_ms,time_process_ms,time_physics_ms,draw_calls,objects,primitives,mem_static_mb,video_mem_mb,gpu_ms,render_cpu_ms,cpu28_us,luma,path_ms,flicker_state,light_factor,rain_level,cam_x`
(`gpu_ms`/`render_cpu_ms` = `NA` si la API falta; `luma` = `NA` en fotogramas no muestreados; no hay veredictos).

## Hallazgos

Pendientes de las carreras P1. Primeros datos de verificacion (editor, debug, ventana, NO son medida de P1):
API de GPU de `RenderingServer` presente y con valores != 0 en la iGPU Intel/D3D12 (NS-P2 plausible, a confirmar en export).
