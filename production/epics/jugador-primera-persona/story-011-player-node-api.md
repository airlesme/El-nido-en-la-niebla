# Story 011: `Player.tscn`, rig y API pública cerrada

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R1, R4–R6, R19, R32–R33
**Requirement**: `TR-player-020`, `TR-player-001`, `TR-player-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D1, D3, D10, § Key Interfaces; P-1…P-10) · ADR-0009 (`configurar(ctx)`, `ctx.require`, puertos `@abstract`) · ADR-0002 (guarda G-4, `WorldSlot` `PAUSABLE`)
**ADR Decision Summary**: `class_name Player extends CharacterBody3D` con cápsula r 0,25 / h 1,75 (y = 0,875), `ZoneSensor` (`Area3D`, capa `zone_sensor`, `SphereShape3D` r 0,05 a y = 0,90, `monitorable`), `Rig/Look/Bob/MainCamera`; superficie pública = regla 33 + `configurar`, verificada por igualdad.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: **Medido en S-0012-B**: `keep_aspect` por defecto `KEEP_HEIGHT` (FOV vertical); `near` y `make_current()` se leen/cambian como se espera. **S-0012-C**: `CharacterBody3D` con propiedades por defecto basta (`safe_margin` 0,001, `floor_snap_length` 0,1). **S-0012-F**: `physics/common/physics_interpolation` lee `false` por defecto; fijarlo **explícito** en `project.godot` (los prototipos lo ponen a `true`: no copiar). `@abstract` (4.5+) para los puertos.

**Control Manifest Rules (Core)**:
- Required: C-R14, C-R15 (`_fraction()` = `Engine.get_physics_interpolation_fraction()`), C-R16, C-R17, C-R18, C-R21, C-R22, C-R24
- Forbidden: C-X09, C-X11, C-X12, C-X13, C-X16
- Guardrail: C-G01 (≤ 0,15 ms media / 0,40 pico por tick; ≤ 0,10 / 0,25 ms por fotograma)

---

## Acceptance Criteria

- [ ] **AC-04 (parte a)**: la lista de operaciones y señales públicas del Jugador es exactamente la de la regla 33 (comparación con lista fija; sin sprint, salto, agacharse ni ocultar manos); `configurar` y callbacks del motor excluidos explícitamente.
- [ ] **AC-36** y **AC-39**: la API no contiene ninguna operación que escriba la memoria de poses, ni escritura/suscripción al estado (3); el Jugador no aparece en la instantánea de guardado.
- [ ] **AC-22**: GIVEN balanceo `completo` en movimiento, THEN el origen de `rayo_vision()` es siempre (X, 1,62, Z) del cuerpo, sin offset de balanceo ni interpolación. *(Verificado aquí vía TR-player-020; la fila TR-player-005 sigue diferida por ADR-0013.)*
- [ ] Cámara M1: `MainCamera.fov` = `campo_vision` por defecto (70°) con `KEEP_HEIGHT`, `near` 0,05 de datos; `fov_actual()` devuelve grados (incluida una cesión en curso). `physics_interpolation` = `false` explícito en `project.godot`.

---

## Implementation Notes

- Firmas exactas de § Key Interfaces (no inventar): `configurar(ctx: ServiceContext) -> void`, `colocar(posicion: Vector3, yaw: float, pitch: float) -> void`, `ceder_camara(propietario: StringName, pose_destino: CameraPose, fov_destino_deg: float, duracion_s: float) -> bool`, `devolver_camara(propietario) -> bool`, `rayo_vision() -> VisionRay`, `fov_actual() -> float`, `pose_actual() -> PlayerPose`, `pose_con_retardo(tau_s) -> PlayerPose`, `giro_acumulado() -> float`, y las 6 señales.
- **Manos fuera de M1 (recorte 1)**: `reproducir_gesto`, `sostener`, `soltar`, `girar_objeto`, `apuntar`, `reposo` y las señales `gesto_terminado`, `objeto_sujeto`, `objeto_soltado` **existen** (API cerrada, AC-04) y devuelven `false` + log («manos fuera de M1»); `reposo()` es no-op. Sin `HandsRig`. Decisión registrada aquí; se revierte con el épico de manos.
- Puertos de producción: `PlayerInputPort` → `InputRouter.top()/get_move_vector()/consume_look_delta()` (ADR-0006; hoy esqueleto), `SurfaceProbe`, `PenetrationProbe`, `AspectSource`. Dependencias duras por `ctx.require`: clock, input, content, logger, fatal (§ Key Interfaces).
- Orden por tick (D1): sync estado → F1/F2 → `move_and_slide` → adoptar velocidad deslizada → `d` → `paso` → pose → ventana de yaw → `StuckGuard` → `TickInterpolator.push`. Rig: `Rig.position = interpolated_eyes − global_position` (sin `top_level`).
- Capas de colisión por nombre de ADR-0011 (`player_body` 2, `zone_sensor` 4); los nombres en `project.godot` faltan (manifiesto P-23).

---

## Out of Scope

- 012: física real contra geometría; 013: ventana y capturas.

---

## Files

- `src/player/player.gd`, `src/player/player.tscn`, `src/player/ports/*.gd`
- `project.godot` (`physics/common/physics_interpolation = false`)
- `tests/unit/player/player_api_surface_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/player_api_surface_test.gd` (T-U14) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-002-locomotion.md` … `story-010-camera-lease.md` (todas); `InputRouter` con `top()`/`get_move_vector()`/`consume_look_delta()` (épico de Entrada, ADR-0006)
- Unlocks: `production/epics/jugador-primera-persona/story-012-physics-walk-integration.md`; `production/epics/carga-de-planta/story-013-gray-planta-geometry.md` (Player en `planta.tscn`)
