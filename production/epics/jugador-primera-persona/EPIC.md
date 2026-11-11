# Epic: Jugador en primera persona (sin manos)

> **Layer**: Core
> **GDD**: design/gdd/jugador-en-primera-persona.md (§ Overview l. 15, § Acceptance Criteria l. 505)
> **Architecture Module**: Capa 2 — 2 Jugador (`Player` en `planta`)
> **Status**: **LISTO** — 17/21 TR libres; TR-player-005/008/010/015 co-citan ADR-0013 (manos, diferidas con el recorte 1)
> **Actualizado 2026-11-11**: desbloqueado por ADR-0005 (TR-player-002/021)
> **Stories**: Not yet created — run `/create-stories jugador-primera-persona` (antes: índice A1 y A5)
> **Control manifest**: v2026-11-11 — § Core Layer Rules **vacía: no incluye ADR-0012** (índice A1) + reglas transversales de Foundation
> **Engine Risk**: HIGH (interpolación física 3D; R1: `Engine.get_physics_interpolation_fraction()`)

## Overview

Cuerpo `CharacterBody3D` sobre Jolt, cabeza y cámara (FOV 70°, ojos a 1,62 m), movimiento y mirada
con interpolación física. En M1 **sin manos** (recorte 1; ADR-0013 y D-28 a M4). Entra aquí el
corredor de 15 s a cada tope de fps (NEEDS_WINDOWED), diferido por ADR-0012 al prototipo jugable.
La cola de diseño tiene pendientes H10 y H12 (jugador/manos): aplicarlos antes de las historias.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0012: Player controller, physics interpolation and camera (Accepted) | Controlador, interpolación y cámara; S-0012-A…F pasados con R1 | HIGH |
| ADR-0002: Pause and game time (Accepted) | Pausa y Δ_juego | HIGH |
| ADR-0013 (Proposed) · ADR-0005 (Accepted) | Co-citados (manos; datos `player/player.json`) | — |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-6**: movimiento y mirada con mando y teclado.
- **C-M1-7**: captura retenida del despacho.
- **C-M1-10**: carrera informativa en `REF-1`; corredor de 15 s a 30/60/144 fps (cierra el NEEDS_WINDOWED de ADR-0012).

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` player; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-player-001 | Cuerpo cinemático (Jolt) con cápsula fija `radio_capsula` 0,25 m / `altura_capsula` 1,75 m, sin sprint/salto/agacharse; desliza por tangente sin rebote ni vibración (<1 mm en 60 pasos); no empuj... | ADR-0012 ✅ |
| TR-player-002 | Invariante `2×radio_capsula + margen_paso (0,10) = player_min_passage_width_m (0,60)`; validación de datos al arrancar (radio 0,30/0,40, `pitch_max` 95, `T_hist` 0,4, `g_reducido` ≥ `g_completo... | ADR-0012, ADR-0005 ✅ |
| TR-player-003 | Sensor de zona esférico (`radio_sensor_zona` 0,05 m, rango 0,02–0,05) a la cintura, separado de la cápsula, que es lo que detectan los `T-…` (Area3D bajo Jolt, PV): activación con centro en ... | ADR-0003, ADR-0012 ✅ |
| TR-player-004 | Movimiento en paso de física fijo `f_fisica` = 60 Hz con presentación interpolada entre pasos (misma distancia/s a 30, 60 y 144 fps; pasillo de 24 m ≈ 15,1±0,3 s); interpolación de física 3D... | ADR-0012 ✅ |
| TR-player-005 | Transformada que lee cada servicio: rayo de visión (origen), sensor de zona y memoria de poses leen estado de física (sin interpolar, sin balanceo); cámara y manos leen la presentación interpol... | ADR-0012 ✅ (+ ADR-0013 Proposed) |
| TR-player-006 | Velocidad calculada en el marco del cuerpo y luego girada por yaw: `v_obj = v_paseo×m'` (1,6 m/s, k_atras 0,8), `move_toward` con `a_acel` 8,0 / `a_freno` 10,67 m/s², regla de elección con hist… (texto truncado) | ADR-0012 ✅ |
| TR-player-007 | Orientación 1:1 sin `dt`, sin suavizado, yaw wrap [−180,180), pitch ±80° (`pitch_max`), roll = 0 siempre (incluso en interpolación de cesión: Euler yaw/pitch separado, no slerp); único siti... | ADR-0012 ✅ |
| TR-player-008 | Cámara principal con FOV vertical (`keep_aspect` = mantener altura, a verificar en 4.7), `campo_vision` 60–90° vía Ajustes aplicado en el acto, tope horizontal `fov_h_max` 120° por F5 con el ... | ADR-0012 ✅ (+ ADR-0013 Proposed) |
| TR-player-009 | Balanceo de cámara solo traslación ligado a distancia real recorrida (`L_paso` 0,75 m, `A_v` 0,015, `A_h` 0,010, g por nivel `balanceo_camara`, `t_cambio_balanceo` 0,25 s, sin saltos >2 mm); con ... | ADR-0012 ✅ |
| TR-player-010 | Manos en plano propio dibujadas encima del mundo con `fov_manos` 60° independiente de `campo_vision`/aspecto, sin atravesar muros (técnica —shader, sub-viewport, segunda cámara— por ADR/spik... | ADR-0012 ✅ (+ ADR-0013 Proposed) |
| TR-player-011 | Sistema de gestos de manos con dos ranuras (derecha/izquierda), gestos de fondo (bucle) vs bloqueantes (duración fija en datos, ≤ `t_transicion_max` 3 s), reglas de rechazo/suspensión/reanudaci... | ADR-0012 ✅ |
| TR-player-012 | Objeto sostenido: el Jugador posee y mueve su transformada (F10: smoothstep `t_mano_s` 0,4 s, `pos_mano` = ojos + dirección×`distancia_m`, slerp de objeto, `girar_objeto`); `sostener` solo para … (texto truncado) | ADR-0012 ✅ |
| TR-player-013 | Cesión de cámara con un único propietario de lista cerrada en datos (`propietarios_camara`: `interaccion:vista`, `interaccion:ordenador`); F9 smoothstep, duración acotada a `t_transicion_max` 3... | ADR-0012 ✅ |
| TR-player-014 | Máquina de 4 estados (Sin escena, Libre, Congelado, Cámara cedida) dirigida por el aviso «contexto de entrada cambiado»; al salir de `exploración` frena con `t_freno` (sin anular de golpe); `m... | ADR-0012 ✅ |
| TR-player-015 | Pausa: con tiempo de juego detenido velocidad, frenado, interpolaciones, balanceo, gestos y traslados se congelan y reanudan desde donde estaban; `t` de F9/F10 y `t_juego` de F7 es tiempo de juego. | ADR-0002, ADR-0012 ✅ (+ ADR-0013 Proposed) |
| TR-player-016 | Memoria circular de poses de `N = ceil(T_hist×f_fisica)+2` = 62 muestras (posición, yaw, pitch, velocidad horizontal, fase del paso) escrita solo por el Jugador, `pose_con_retardo(τ)` con τ cla... | ADR-0012 ✅ |
| TR-player-017 | `giro_acumulado()` = suma de \\ | ADR-0012 ✅ |
| TR-player-018 | `colocar(posición, yaw, pitch)` síncrona en el mismo tick: velocidad 0, cancela cesión sin `camara_devuelta`, manos en reposo sin objeto, memoria de poses rellena, `giro_acumulado` 0; el Jugador... | ADR-0003, ADR-0012 ✅ |
| TR-player-019 | Red de seguridad contra atasco/caída: penetración >`eps_atasco_m` 0,02 con desplazamiento menor durante `t_atasco` 0,5 s, o `y` < `y_min` −2,0 m, devuelve a la última pose segura (`t_pose_segu... | ADR-0012 ✅ |
| TR-player-020 | API pública cerrada y verificada por igualdad (AC): operaciones `colocar`, `ceder_camara`, `devolver_camara`, `rayo_vision`, `fov_actual`, `reproducir_gesto`, `sostener`, `soltar`, `girar_objeto`,... | ADR-0012 ✅ |
| TR-player-021 | Todos los parámetros de feel/curva en `assets/data/player/player.json` (salvo `balanceo_camara` y `campo_vision` que viven en Ajustes 6); tests L con reloj inyectado en pasos enteros, entrada fals... | ADR-0012, ADR-0005 ✅ |

## Requisitos bloqueados (al 2026-11-11)

| TR-ID | Bloqueado por | Motivo / salida |
|-------|---------------|-----------------|
| TR-player-005 | ADR-0013 (Proposed) | manos, recorte 1 |
| TR-player-008 | ADR-0013 (Proposed) | manos, recorte 1 |
| TR-player-010 | ADR-0013 (Proposed) | manos, recorte 1 |
| TR-player-015 | ADR-0013 (Proposed) | manos, recorte 1 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
