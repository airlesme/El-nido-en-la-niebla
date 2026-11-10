# ADR-0013: First-Person Hands Rendering and Blackout Lighting

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> This ADR additionally cannot be `Accepted` before the D-28 spike (§ Spike Plan)
> has run and its result is written into § Decision D1 (the losing branch is
> then deleted from this document and from the code).

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/modules/rendering.md`
(last verified 2026-10-17) and Godot 4.7.2 pin (`VERSION.md`). Every engine
behaviour this ADR depends on that the reference does not cover is marked
**‡ NOT SOURCEABLE** and is a spike item.

## Decision Makers

technical-director (autonomous mode, `project.yaml` `modes.automation:
autonomous`). Consulted by document: GDD 2 (`jugador-en-primera-persona.md`,
rules 23–28, D-07, D-28, OQ 2), GDD 28 (`atmosfera-reactiva.md`, rule 8,
DT-5, OQ 10, OQ 11), ADR-0002, ADR-0007, ADR-0009. Art director owns the
value of `luz_minima_manos` and the AC-34 sign-off; technical-artist runs the
spike with engine-programmer.

## Summary

Vera's hands (GDD 2 rules 23–28) must be drawn over the world with their own
`fov_manos` (60°), never cut by walls, and stay legible in the blackout
(GDD 28 rule 8; hands/surroundings luminance ratio ≥ 1.5:1). Decided: hands
live on a dedicated render layer `HANDS` inside the main `World3D`, lit by the
scene's own lights plus a **constant emissive floor in the hands material**
(`luz_minima_manos`, data), with no extra light and no reaction to the
blackout; the drawing technique is chosen by a measurable A/B spike (D-28)
between **B — single camera, viewmodel `ShaderMaterial` that rewrites the
clip-space position with `fov_manos` and compresses depth** (candidate of
record) and **A — `SubViewport` with a second `Camera3D`** (fallback).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH (4.5, 4.6, 4.7 post-cutoff; `VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/rendering.md` (4.6 glow before tonemapping, D3D12 default on Windows, AgX controls; 4.7 HDR output; 4.5 stencil buffer and SMAA; 4.3 `Compositor` for post-processing) |
| **Post-Cutoff APIs Used** | None directly named by the reference. Behaviours relied on that changed post-cutoff and **are** sourced: glow processed before tonemapping with screen blending (4.6); D3D12 default backend on Windows (4.6); HDR output (4.7). Everything else is ‡ (see § Engine API sourcing) |
| **Verification Required** | Spike S-H1…S-H7 (§ Spike Plan): clip-space write and depth convention in a `spatial` `vertex()` (B); `SubViewport` sharing the main `World3D` with transparent background and per-camera cull mask (A); render-layer exclusion from `ReflectionProbe`; emissive floor below the glow threshold after the 4.6 glow change; GPU cost per branch on D3D12 and Vulkan; image stability while the tree is paused |

### Engine API sourcing

`rendering.md` covers only post-processing (`Compositor`), AA, backends and the
version deltas listed above. The following are **NOT SOURCEABLE — not covered
by `docs/engine-reference/godot/modules/rendering.md`** and must not be cited
as fact anywhere downstream until the spike writes them back:

| # | Behaviour | Branch | Spike |
|---|---|---|---|
| NS-H1 | `PROJECTION_MATRIX` readable and `POSITION` (clip space) writable in a `spatial` shader `vertex()`, with lighting still computed from the unmodified view-space `VERTEX` | B | S-H1 |
| NS-H2 | Depth convention in Forward+ on 4.7 (reversed-Z, near = 1.0) — the depth-compression formula depends on it | B | S-H1 |
| NS-H3 | Motion vectors / TAA behaviour for a mesh whose `POSITION` is rewritten (ghosting) | B | S-H5 |
| NS-H4 | `SubViewport` with `own_world_3d = false` renders the parent `World3D`; `transparent_bg`; `Camera3D.cull_mask`; per-camera `Camera3D.environment` | A | S-H2 |
| NS-H5 | `VisualInstance3D.layers` (render layers, 20 bits) and `ReflectionProbe.cull_mask` honoured by probe capture | A, B | S-H3 |
| NS-H6 | `GeometryInstance3D.cast_shadow = SHADOW_CASTING_SETTING_OFF` | A, B | S-H1 |
| NS-H7 | `render_priority` on transparent materials vs. a depth-compressed opaque mesh (already NOT SOURCEABLE for GDD 29, ronda 9) — this ADR is designed **not** to need it | B | — |
| NS-H8 | Rendering continues (static image) while `SceneTree.paused = true`; `SubViewport.render_target_update_mode` during pause | A, B | S-H6 (shares ADR-0002 S1) |
| NS-H9 | GPU timing source (`RenderingServer.viewport_set_measure_render_time` / `viewport_get_measured_render_time_gpu`) on D3D12 | A, B | S-H4 (fallback: PIX / RenderDoc capture) |
| NS-H10 | `Light3D.light_cull_mask` (only for the fallback lighting L1) | L1 | S-H7 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 Pause and game time (`Proposed`): `WorldSlot` subtree `PAUSABLE`, `Player` (2) under it; no `TIME` in shaders for game effects. ADR-0009 Service composition (`Proposed`): `Player` is a scene node configured by `configurar()` with injected data; `Atmosphere` (28) is a scene node (D11) and this ADR adds **no** call between 2 and 28. ADR-0007 Settings, accessibility (`Proposed`): `A11yConstants` (D9) and `FlashGuard` (OI-6, answered here for hands). ADR-0005 Data schema (`Proposed`): keys live in `assets/data/player/player.json`. All must be `Accepted` before implementation |
| **Enables** | ADR-0012 (player controller: hands rig placement and the interpolated transform it reads); ADR-0014 (atmosphere lighting budget: hands consume 0 light slots); ADR-0015 (glass draw order: hands need no `render_priority`); ADR-0019 (hands GPU budget line) |
| **Blocks** | Hands epic of GDD 2 (rules 23–28, AC-31…AC-34); M3 blackout scene (scene 7) visual sign-off; AC-28-04 |
| **Ordering Note** | ADR-0012, 0014, 0015, 0016 and 0019 do not exist yet (2026-11-10). The spike S-H1…S-H6 must run **before epics** (GDD 2 OQ 2) and can run before ADR-0012 with a throw-away camera rig. If branch A wins, ADR-0016 must place the hands composite `CanvasLayer` below the HUD |

## Context

### Problem Statement

GDD 2 rule 25 requires the hands to be drawn **over** the world with their own
field of view (`fov_manos` 60°, range 40–75) so that they never pass through a
wall while the capsule (`radio_capsula` 0.25 m) touches it, and so that their
size and shape do not change with `campo_vision` (60–90°) or aspect ratio
(AC-31: mask difference ≤ 0.5 % of its area). The hands rest 0.3–0.6 m in
front of the eye (art bible §5.1), so with a 0.25 m capsule they geometrically
enter walls. GDD 2 rule 28 and GDD 28 rule 8 require them to stay legible in
the blackout (AC-34: luminance ratio hands/immediate surroundings ≥ 1.5:1 in a
retained capture, plus art-director approval). GDD 2 D-28 makes the drawing
technique a spike with a measurable exit; `architecture.md` § Required ADRs
lists ADR-0013 as HIGH risk with that spike.

### Current State

No code. GDD 2 OQ 2 names two candidates — (A) second camera in `SubViewport`,
(B) shader in `vertex()` — both unverified. GDD 28 rule 8 leaves the lighting
mechanism (light mask, second camera, hands shader) to this ADR and its own
hand-off table asks 2 for "a separate light mask for the hands layer".

### Constraints

- Forward+, no `LightmapGI` (TR-atmos-017); ≤ 8 visible dynamic lights, ≤ 2
  with shadow, ≤ 14 loaded per scene, owned by 28 (TR-atmos-016/017).
- Blackout: `C03` and `despacho_guardian` lights to `f_apagon` 0.0 in 0.4 s
  (0.8 s with `reducir_sobresaltos` — **pending user decision, GDD 28 OQ 11;
  this ADR is independent of that value**), ambient floor 0.06 (0.10 reduced),
  `V06` at 100 % and phone screen light `V02` kept (rule 8). No new emergency
  light without the art director (DT-5).
- Glow is processed **before** tonemapping with screen blending since 4.6
  (`rendering.md`); HDR output exists in 4.7 (`rendering.md`).
- D3D12 is the default backend on Windows since 4.6 (`rendering.md`): costs
  must be measured on D3D12 and on Vulkan (Linux build).
- 28 owns every reflection (`C02` proxy, `B04` `ReflectionProbe`; TR-atmos-009,
  -013); 29 owns `mat_glass_memo`. Hands must not appear in either.
- Pause (ADR-0002 D2): `Player` is under `WorldSlot` (`PAUSABLE`); gestures
  and hand sway freeze (TR-player-015, AC-27).
- `reducir_sobresaltos` must not change any output of the Player, hands
  included (GDD 2 AC-14).
- Solo developer, slice scope: the simplest technique that passes the ACs wins.

### Requirements

- R1 Hands drawn over every world surface, opaque or transparent, including
  `rain_glass` and `mat_glass_memo` (TR-player-010, AC-33, AC-32).
- R2 Own FOV `fov_manos`, invariant to `campo_vision` and aspect (AC-31).
- R3 Hands receive scene light (monitor, phone `V02` from below, `V06`) — GDD 2
  rule 28 — with a guaranteed minimum in the blackout, ratio ≥ 1.5:1
  (TR-atmos-010, AC-34, AC-28-04).
- R4 Hands are absent from `C02` and from the `B04` probe (TR-atmos-009/-013).
- R5 Frozen and pixel-stable under pause; no `TIME` in their shader.
- R6 GPU cost of hands rendering ≤ 0.30 ms at 1080p on the reference machine
  (provisional until ADR-0019); CPU ≤ 0.05 ms/frame; 0 light slots of 28's budget.
- R7 Works identically with `reducir_sobresaltos` on or off.

## Decision

### D1 — Drawing technique: spike A/B, candidate of record B

Two branches are built behind one seam (`HandsView`, § Key Interfaces) and
measured by the D-28 spike. The rule in § Spike Plan picks one; the other is
deleted. Until then **B is the candidate of record** (stories may assume B's
scene layout; A changes only the `HandsView` implementation and one
`CanvasLayer`).

**B — Viewmodel shader (single camera).** Hands meshes are children of the
`HandsRig` under the `Player`'s presentation camera, in the main `World3D`,
on render layer `HANDS`. Their `ShaderMaterial` (`hands.gdshader`) rewrites
the clip-space position in `vertex()` with a projection whose vertical FOV is
`fov_manos` and whose aspect is taken from the camera's own projection, then
compresses the depth into the nearest `HANDS_DEPTH_FRACTION` (0.02) of the
depth range so the hands win the depth test against every world surface
(NS-H1, NS-H2). Lighting is computed from the unmodified view-space vertex, so
the hands are lit exactly as world objects at their real position. One pass,
one tonemap, one glow: the hands are inside the same HDR buffer as the world.

**A — Second camera in a `SubViewport`.** A `SubViewport` sharing the main
`World3D` (NS-H4), `transparent_bg = true`, size = main viewport size, holds
`HandsCamera` (`Camera3D`, `fov = fov_manos`, `cull_mask = HANDS`) that copies
the main camera's interpolated global transform every frame. The main camera's
`cull_mask` excludes `HANDS`. The texture is composited by a full-screen
`TextureRect` in a `CanvasLayer` **below** the HUD (layer index owned by
ADR-0016). `HandsCamera.environment` is a copy of the scene `Environment`
**with glow disabled** (same tonemapper and exposure) so the hands are
tonemapped once and never glow over a transparent background (NS-H4).

Common to both branches:

- `HANDS` = render layer 20 (bit 19), declared once in
  `src/gameplay/player/hands/hands_layers.gd`; main camera, `ReflectionProbe`
  of `B04` and every other probe exclude it (R4). `C02` uses its own full-body
  proxy (TR-atmos-009) and never includes the viewmodel.
- Every hands mesh: `cast_shadow = OFF` (NS-H6) — viewmodel geometry must not
  shadow the world. Hands receive shadows normally.
- **Eye-centred scale** (`HANDS_EYE_SCALE` 0.4): the rig is scaled about the
  eye point, which leaves the projected image unchanged but places the meshes
  at 0.12–0.24 m, inside the 0.25 m capsule. Geometric penetration — and with
  it light leaking from the room behind a wall (clustered lights do not
  occlude without shadows) — disappears. Hands vertices stay beyond `near`
  0.05 m (TR-player-008). Lights carried by the hands (the phone screen `V02`,
  owned by 28) are **not** children of the scaled rig: 28 attaches them to an
  unscaled `HandsLightAnchor` that follows the phone socket's world position
  multiplied back by `1 / HANDS_EYE_SCALE` from the eye.
  The scale is a code constant (it is not a feel value) and is part of the
  spike: S-H1 validates it in B, S-H2 in A.
- The rig reads the **interpolated presentation** transform (TR-player-005),
  never the physics state.

### D2 — Blackout lighting: constant emissive floor in the hands material (L2)

The hands receive every scene light like any world object (R3). Their
guaranteed minimum is an **emissive floor**:
`EMISSION = albedo × luz_minima_manos`, constant, always on, in the hands
material (the same material in A and B). It does **not** react to the
blackout, to 28's state, to `reducir_sobresaltos` (R7, AC-14) or to pause.
Consequences of "constant":

- No coupling 2 ↔ 28: 28 never sets a hands parameter and 2 never reads 28.
- Not a flash: it never changes at run time, so `FlashGuard` (ADR-0007 OI-6)
  never sees it. **Answer to ADR-0007 OI-6 for hands: nothing in hands
  rendering counts as a flash.**
- Independent of the blackout duration (0.4 s / 0.8 s, GDD 28 OQ 11 open).
- 0 light slots of 28's budget (TR-atmos-016/017).

`luz_minima_manos` lives in `assets/data/player/player.json` (default
0.04†, range 0.0–0.20), owned by the art director (GDD 2 rule 28: "the value
and the mode are the art director's; the Player only guarantees the material
is never disabled"). The default is chosen so that in scene 1 lighting the
floor changes the hands' mean luminance by ≤ 5 % (invisible) while in the
blackout (ambient 0.06, `V02` from below) the ratio R of F1 reaches ≥ 1.5.

**Fallback L1 (only if L2 fails S-H7):** an `OmniLight3D` `HandsFillLight`
under the `HandsRig`, no shadow, `light_cull_mask = HANDS` (NS-H10), constant
energy from data. It costs one of 28's ≤ 8 visible light slots and needs 28's
budget owner to accept it (ADR-0014). L1 is adopted only if L2 cannot reach
R ≥ 1.5 without breaking the ≤ 5 % scene-1 invisibility condition, or the art
director rejects the flat look of the floor.

**Formula F1 — legibility ratio (AC-34, AC-28-04).** On the retained 1080p
capture, decoded from sRGB to linear:
`Y(p) = 0.2126·R + 0.7152·G + 0.0722·B`;
`L_manos = mean Y over the hands mask M`;
`L_entorno = mean Y over the ring Ω = dilate(M, 48 px) \ dilate(M, 16 px)`
(the "immediate surroundings"; pixels of HUD/subtitles excluded);
`R = L_manos / max(L_entorno, 1e-4)`. Pass: `R ≥ 1.5`.
Example: `L_manos` 0.030, `L_entorno` 0.018 ⇒ R = 1.67 (pass); with the floor at 0
the same frame gives `L_manos` 0.022 ⇒ R = 1.22 (fail) — numbers illustrative,
the capture decides. The mask `M` comes from the dev-only mask capture (§ Test
plan), not from colour thresholds.

### D3 — Glow, tonemap, HDR

- B: hands are in the world's HDR buffer; the 4.6 glow (before tonemap, screen
  blend; `rendering.md`) treats them as world pixels. `luz_minima_manos` × albedo
  must stay below the environment's glow HDR threshold (S-H7 checks the hands
  contribute 0 to glow in the blackout capture).
- A: hands are tonemapped in their own pass with glow off (D1), then
  composited in LDR over the main image; world glow does not bleed over the
  hands. S-H2 checks tonemap parity (F2 of § Spike Plan).
- HDR output (4.7) is **not** enabled by this ADR; ratios and parity are
  measured on SDR captures. Enabling HDR output re-opens S-H7 (Open Item OI-5).

### D4 — Transparent world surfaces and glass

- B: the depth-compressed hands are opaque and drawn in the opaque pass;
  transparent surfaces (`rain_glass`, `mat_glass_memo`, `C02`) are depth-tested
  against them and lose. No `render_priority` is needed (NS-H7 avoided).
- A: composited after the whole 3D image, so above every glass by construction.
- Hands never appear in `C02` (separate proxy) or `B04` (probe excludes `HANDS`);
  checked statically (AC-H5).

### D5 — Pause

`HandsRig` and its meshes are under `Player` → `WorldSlot` (`PAUSABLE`,
ADR-0002 D2). Gestures, sway (F3/F7 of GDD 2) and the `AnimationPlayer` freeze
with the tree. `hands.gdshader` must never read `TIME` (ADR-0002 D3, row 29).
Rendering keeps presenting the last image (NS-H8). Branch A: the `SubViewport`
keeps `UPDATE_ALWAYS` during pause (no mode switch: the image is static anyway
and a switch is a second path to test); the hands composite stays below the
pause veil because its `CanvasLayer` is below 25's. Nothing in this ADR
subscribes to «pausa abierta» / «pausa cerrada».

### Architecture Diagram

```text
WorldSlot (PAUSABLE)
└─ planta
   ├─ Atmosphere (28)  ── owns lights V02/V06/C03, ReflectionProbe B04 (cull_mask & ~HANDS)
   └─ Player (2)
      └─ PresentationPivot (interpolated transform, TR-player-005)
         ├─ Camera3D  "MainCamera"   fov = F5(campo_vision), cull_mask = ALL & ~HANDS (A) | ALL (B)
         ├─ HandsLightAnchor (unscaled; 28 may parent V02 here, OI-3)
         └─ HandsRig  scale = HANDS_EYE_SCALE about the eye
            ├─ HandsView  ── B: HandsViewShader | A: HandsViewSubViewport
            ├─ hand_r / hand_l  MeshInstance3D  layers = HANDS, cast_shadow OFF,
            │                    material = hands.gdshader (fov_manos, luz_minima_manos)
            └─ AnimationPlayer (gestures; frozen by pause)

Branch A only:
   SubViewport (own_world_3d = false, transparent_bg) ─ HandsCamera (cull_mask = HANDS,
       environment = scene Environment with glow off)
   Shell ─ CanvasLayer "HandsComposite" (below HUD, ADR-0016) ─ TextureRect(viewport texture)

Light path in blackout:  ambient 0.06 + V02 (+ V06 if in view) + EMISSION floor ─▶ hands
No signal, call or notice between 2 and 28.
```

### Key Interfaces

```gdscript
# ─── src/gameplay/player/hands/hands_layers.gd ─────────────────────────────
class_name HandsLayers extends RefCounted
## Single definition of the hands render layer (NS-H5). Code, not data.
const HANDS_LAYER_INDEX: int = 20                    # 1-based, as shown in the editor
const HANDS_BIT: int = 1 << (HANDS_LAYER_INDEX - 1)
const HANDS_EYE_SCALE: float = 0.4                   # D1; validated by S-H1/S-H2
const HANDS_DEPTH_FRACTION: float = 0.02             # D1 branch B; validated by S-H1

## Mask for any camera or probe that must NOT see the hands.
static func without_hands(mask: int) -> int:
	return mask & ~HANDS_BIT


# ─── src/gameplay/player/hands/hands_projection.gd ─────────────────────────
class_name HandsProjection extends RefCounted
## Pure mirror of the math in hands.gdshader, so it is unit-testable (no GPU).

## Focal term for a vertical FOV in degrees.
static func focal(fov_v_deg: float) -> float:
	return 1.0 / tan(deg_to_rad(fov_v_deg) * 0.5)

## Normalised device Y of a view-space point projected with the hands FOV.
## Independent of the main camera FOV by construction (AC-31).
static func ndc_y(view_pos: Vector3, fov_manos_deg: float) -> float:
	return focal(fov_manos_deg) * view_pos.y / -view_pos.z

## Reversed-Z depth compression (NS-H2): maps ndc depth d in [0,1] to
## [1 - k, 1]. Equivalent to the shader's mix(w, z, k) / w.
static func compress_depth(d: float, k: float) -> float:
	return 1.0 - k * (1.0 - d)


# ─── src/gameplay/player/hands/hands_view.gd ───────────────────────────────
@abstract   # 4.5+ class annotation (VERSION.md timeline); exact syntax per ADR-0010 usage
class_name HandsView extends Node
## Seam for the D-28 spike. Exactly one subclass survives the spike.

## Called once by HandsRig.configurar(). `main_camera` is the presentation camera.
func bind(main_camera: Camera3D, fov_manos_deg: float, light_floor: float) -> void:
	pass

## Called by Settings change of campo_vision: must change NOTHING in the hands
## (AC-31). Exists so tests can assert it is a no-op.
func on_main_fov_changed(_fov_v_deg: float) -> void:
	pass


# ─── src/gameplay/player/hands/hands_view_shader.gd  (branch B) ────────────
class_name HandsViewShader extends HandsView
@export var meshes: Array[MeshInstance3D] = []

func bind(main_camera: Camera3D, fov_manos_deg: float, light_floor: float) -> void:
	main_camera.cull_mask |= HandsLayers.HANDS_BIT
	for m: MeshInstance3D in meshes:
		m.layers = HandsLayers.HANDS_BIT
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # NS-H6
		var mat := m.get_active_material(0) as ShaderMaterial
		mat.set_shader_parameter(&"fov_manos_deg", fov_manos_deg)
		mat.set_shader_parameter(&"depth_fraction", HandsLayers.HANDS_DEPTH_FRACTION)
		mat.set_shader_parameter(&"luz_minima_manos", light_floor)


# ─── src/gameplay/player/hands/hands_view_subviewport.gd  (branch A) ───────
class_name HandsViewSubViewport extends HandsView
@export var viewport: SubViewport
@export var hands_camera: Camera3D
var _main: Camera3D

func bind(main_camera: Camera3D, fov_manos_deg: float, light_floor: float) -> void:
	_main = main_camera
	_main.cull_mask = HandsLayers.without_hands(_main.cull_mask)
	viewport.own_world_3d = false                      # NS-H4
	viewport.transparent_bg = true
	hands_camera.cull_mask = HandsLayers.HANDS_BIT
	hands_camera.fov = fov_manos_deg
	hands_camera.near = _main.near
	# same hands material as B, but its vertex() projection rewrite is disabled
	# (uniform use_own_projection = false) — the camera already has fov_manos.
	# light_floor applied to the meshes exactly as in B.

func _process(_dt: float) -> void:
	hands_camera.global_transform = _main.global_transform   # interpolated pivot
	var s: Vector2i = get_viewport().get_visible_rect().size as Vector2i
	if viewport.size != s:
		viewport.size = s


# ─── src/gameplay/player/hands/hands_rig.gd ────────────────────────────────
class_name HandsRig extends Node3D
## Owns hands presentation. Reads player.json values injected by Player.
@export var view: HandsView

## Part of Player.configurar() (ADR-0009 D3). No bus subscription here.
func configurar(main_camera: Camera3D, cfg: PlayerConfig) -> void:
	scale = Vector3.ONE * HandsLayers.HANDS_EYE_SCALE
	view.bind(main_camera, cfg.fov_manos, cfg.luz_minima_manos)
```

```glsl
// ─── assets/shaders/player/hands.gdshader ─────────────────────────────────
// Every builtin use marked ‡ is NOT SOURCEABLE (NS-H1/NS-H2); verified by S-H1.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform bool use_own_projection = true;        // B: true · A: false
uniform float fov_manos_deg = 60.0;            // overwritten by bind() from player.json
uniform float depth_fraction = 0.02;           // HandsLayers.HANDS_DEPTH_FRACTION
uniform vec3 albedo : source_color = vec3(0.62, 0.52, 0.46);  // art placeholder
uniform float roughness_value = 0.9;           // matte, art bible §5.1
uniform float luz_minima_manos = 0.04;         // D2 emissive floor (data)

void vertex() {
	if (use_own_projection) {
		mat4 proj = PROJECTION_MATRIX;                              // ‡ NS-H1
		float f = 1.0 / tan(radians(fov_manos_deg) * 0.5);
		float aspect = PROJECTION_MATRIX[1][1] / PROJECTION_MATRIX[0][0];
		proj[0][0] = f / aspect;
		proj[1][1] = f;
		vec4 clip = proj * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
		clip.z = mix(clip.w, clip.z, depth_fraction);               // ‡ NS-H2 reversed-Z
		POSITION = clip;                                            // ‡ NS-H1
	}
	// No TIME anywhere (ADR-0002 D3).
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = roughness_value;
	EMISSION = albedo * luz_minima_manos;      // D2: constant floor, never animated
}
```

New data key (ADR-0005 path `assets/data/player/player.json`):

| Key | Default | Range | Owner | Consumer |
|---|---|---|---|---|
| `fov_manos` | 60 (exists, GDD 2) | 40–75 | technical-artist / GDD 2 | `HandsView.bind` |
| `luz_minima_manos` | 0.04† | 0.0–0.20 | art director | hands material `EMISSION` |

### Implementation Guidelines

- Hands meshes **must** be on `HandsLayers.HANDS_BIT` only and **must** have
  `cast_shadow = OFF`.
- Every `ReflectionProbe` and every camera other than the hands path **must**
  use `HandsLayers.without_hands()`; no literal layer numbers anywhere else.
- `hands.gdshader` **must never** read `TIME`, screen textures or depth
  textures, and **must never** be animated at run time; only `bind()` writes
  its uniforms.
- Nothing in 2 **may** subscribe to 28's orders or read 28's state for hands
  lighting; 28 **must never** call `set_shader_parameter` on the hands
  material (mirrors AC-28-11 for `mat_glass_memo`).
- `luz_minima_manos` and `fov_manos` **must** come from `player.json`;
  `HANDS_EYE_SCALE`, `HANDS_DEPTH_FRACTION`, `HANDS_LAYER_INDEX` are code
  constants (technical, not feel values).
- `HandsRig` **must** follow the interpolated presentation pivot, never the
  physics body (TR-player-005).
- After the spike, the losing `HandsView` subclass, its scene nodes and (if B
  wins) the `use_own_projection` uniform's `false` path **must** be deleted in
  the same commit that sets this ADR's D1 to the winner.
- No `Compositor` effect and no stencil pass for the hands (Alternatives 3 and 4).

## Spike Plan (D-28)

Owner: technical-artist + engine-programmer. Machine: the developer's
machine, recorded in the report (reference hardware is ADR-0019; this spike's
numbers are PV until then). Backends: D3D12 (Windows default, `rendering.md`)
**and** Vulkan. Resolution 1920×1080, AA mode of the project at spike time
(recorded). Fixture: `prototypes/hands_spike/` — a 4 × 4 m room with the
corridor's `C03` lights, one `rain_glass` pane, one transparent pane with a
placeholder `mat_glass_memo`, a `ReflectionProbe`, a phone-screen `OmniLight3D`
standing in for `V02`, and the blackout state (lights at 0, ambient 0.06).
Both branches are built on the same fixture and the same hands meshes.

| Spike | Question | Measurement | Pass |
|---|---|---|---|
| S-H1 | B works on 4.7.2: clip-space write, reversed-Z formula, lighting from view-space `VERTEX`, `cast_shadow` off (NS-H1, -H2, -H6) | Shader compiles; capsule touching the wall at yaw 0/90/180/270° and pitch −60/0/+60° (12 poses): count wall pixels inside the hands mask | 0 pixels in all 12 poses |
| S-H2 | A works on 4.7.2: shared `World3D`, `transparent_bg`, cull masks, camera `environment` with glow off (NS-H4) | Same 12 poses | 0 pixels in all 12 poses |
| S-H3 | Hands absent from probes (NS-H5) | Capture of the probe's reflection on the glass pane with hands in front of it; mask overlap | No hand pixels in the reflection |
| S-H4 | Cost (NS-H9) | GPU frame time, mean of 600 frames, hands on minus hands off (same pose), both backends; CPU time of `HandsView._process` / `bind` | GPU Δ ≤ 0.30 ms; CPU ≤ 0.05 ms |
| S-H5 | Motion artefacts (NS-H3) | Yaw sweep at 200 °/s for 2 s at 60 fps; max ghost-trail length behind the hand silhouette in the frame after the sweep stops | ≤ 2 px, and no visible artefact for the art director |
| S-H6 | Pause stability (NS-H8, shares ADR-0002 S1) | `SceneTree.paused = true` for 600 frames; per-pixel diff of the first and last frame | Identical (diff 0) |
| S-H7 | Lighting L2 (D2, D3) | F1 ratio R in the blackout state; scene-1 lighting mean-luminance change of the hands with floor on vs. 0; glow contribution of the hands (glow-only debug or glow on/off diff inside M) | R ≥ 1.5; Δ ≤ 5 %; glow Δ inside M ≤ 1 % |

**F2 — tonemap parity (A only).** Under the same fixed light, mean Y of the
hands mask in A vs. the same hands drawn as ordinary world meshes (main camera,
no special path, positioned away from walls): `|Y_A − Y_ref| / Y_ref ≤ 0.03`.
B is the reference by construction (same buffer).

**FOV invariance (both).** AC-31 test: masks at `campo_vision` 60/70/90° and
aspect 16:9 and 16:10: area difference ≤ 0.5 % of the mask area.

**Selection rule (measurable, applied in this order):**

1. A branch that fails any **hard** test — S-H1/S-H2 (its own), S-H3, S-H6,
   FOV invariance — is eliminated.
2. If both survive: **B wins** when it passes S-H5 and
   `GPU_Δ(B) ≤ GPU_Δ(A) + 0.05 ms` on both backends. Otherwise **A wins**,
   provided A passes S-H5 and F2; if A also fails S-H5 or F2, B wins (fewer
   moving parts, no extra render target).
   In words: B unless B has motion artefacts or is measurably slower and A is
   clean.
3. If both survive and both fail S-H4's 0.30 ms budget: take the cheaper one
   and raise the budget line in ADR-0019 (budget, not technique, is the
   problem).
4. If both are eliminated: escalate to the user with Alternative 1 (hands as
   world meshes with `depth_test_disabled`) and the design cost of losing
   AC-31 or AC-33 — that is a change to GDD 2 rule 25, not a technical choice.

S-H7 is run on the winner. If it fails, adopt lighting fallback L1 (D2) and
re-run S-H7 with L1; if L1 also fails, the art director chooses between a
higher `luz_minima_manos` (accepting the visible floor in normal light) and an
extra diegetic light (GDD 28 DT-5 / OQ 2).

**Spike output** (write-back, required to move to `Accepted`): D1 set to the
winner; NS-H1…H10 results added to `docs/engine-reference/godot/modules/rendering.md`
with "verified on 4.7.2, <date>"; the report and every capture in
`production/qa/evidence/adr-0013/` (§ Validation Criteria).

## Alternatives Considered

### Alternative 1: Hands as world meshes with `depth_test_disabled` + `render_priority`
- **Description**: Ordinary meshes near the camera, material with depth test off, drawn last.
- **Pros**: No projection math; one pass.
- **Cons**: With depth test off the hands self-overlap wrongly (fingers over palm); ordering against transparent glass needs `render_priority`, already NOT SOURCEABLE (NS-H7, GDD 29 ronda 9); no own FOV, so AC-31 fails unless the vertex trick of B is added anyway.
- **Estimated Effort**: Lower than B.
- **Rejection Reason**: Fails AC-31 and depends on an unsourced draw-order behaviour. Kept only as the escalation in rule 4.

### Alternative 2: Same FOV as the world, hands pulled inside the capsule
- **Description**: No custom projection; scale the rig so it sits within 0.25 m.
- **Pros**: Trivial; no shader.
- **Cons**: Hands change size with `campo_vision` 60–90° (AC-31 fails); GDD 2 D-07 explicitly rejected "same FOV as the world".
- **Estimated Effort**: Minimal.
- **Rejection Reason**: Contradicts GDD 2 rule 25 / D-07. (Its scaling idea is kept as `HANDS_EYE_SCALE` inside A and B.)

### Alternative 3: `CompositorEffect` hands pass
- **Description**: Render hands in a custom `RenderingDevice` pass via `Compositor` (`rendering.md`, 4.3+).
- **Pros**: Full control of order and depth.
- **Cons**: `Compositor` is documented for post-processing, not for drawing geometry; requires low-level `RenderingDevice` code whose 4.4 signatures changed (`draw_list_begin`, `rendering.md`); far beyond a solo slice.
- **Estimated Effort**: Several times B.
- **Rejection Reason**: Disproportionate complexity and risk.

### Alternative 4: Stencil mask (4.5) to cut the world where hands are
- **Description**: Write stencil with the hands, then reject world pixels.
- **Pros**: Uses a sourced 4.5 feature.
- **Cons**: Solves occlusion, not FOV; the material-level stencil API is not covered by `rendering.md` beyond "stencil buffer support"; still needs B's projection.
- **Estimated Effort**: Higher than B.
- **Rejection Reason**: Adds a mechanism without removing one.

### Alternative 5 (lighting): Hands-only fill light (L1) as primary
- **Description**: `OmniLight3D` with `light_cull_mask = HANDS`.
- **Pros**: Looks like light (shading, falloff) rather than a flat floor.
- **Cons**: One of 28's ≤ 8 visible light slots; depends on NS-H10; owned across 2/28.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Budget and coupling; kept as fallback L1.

### Alternative 6 (lighting): Floor driven by the blackout (28 sets a uniform / global uniform)
- **Description**: The floor is 0 normally and rises during the blackout.
- **Pros**: Floor invisible in normal light by definition.
- **Cons**: Couples 28 → hands material (mirror of what AC-28-11 forbids for `mat_glass_memo`); a run-time luminance change is a `FlashGuard` candidate (ADR-0007 OI-6); depends on the blackout duration still pending (GDD 28 OQ 11); global shader uniforms not covered by the reference.
- **Estimated Effort**: Higher (two systems, two tests, ramp).
- **Rejection Reason**: Constant floor meets AC-34 with zero coupling; revisit only if S-H7's ≤ 5 % invisibility condition fails.

### Alternative 7 (lighting): Separate light mask for the hands layer (GDD 28 hand-off wording)
- **Description**: All scene lights exclude `HANDS`; hands get only their own lights.
- **Pros**: Full art control of hand lighting.
- **Cons**: Violates GDD 2 rule 28 (hands receive monitor and phone light); doubles light setup.
- **Estimated Effort**: Higher.
- **Rejection Reason**: Contradicts GDD 2 rule 28 (see Contradictions C1).

## Consequences

### Positive
- No coupling between 2 and 28 for hands; 28's light budget untouched.
- Branch B (if it wins): one pass, one tonemap and glow, no extra memory.
- Eye-centred scale removes light leaks through walls in both branches.
- `HandsProjection` gives a GPU-free unit test of the FOV invariant.

### Negative
- Branch B depends on four NOT SOURCEABLE behaviours (NS-H1…H3, H6); a 4.x
  upgrade can break it silently → Knowledge Risk HIGH, re-validate on upgrade.
- Branch A costs a second render target (≈ 8 MB RGBA8 colour + ≈ 8 MB depth at
  1080p, ≈ 4× at 2160p; estimate) and a second scene-culling pass.
- A constant floor is visible as flatness if over-tuned; the art director owns
  the trade-off.

### Neutral
- One temporary seam (`HandsView`) exists only until the spike.
- HDR output stays off for measurements (OI-5).

## Risks

| Risk | Mitigation |
|---|---|
| B's clip-space rewrite unsupported or lighting computed from rewritten position | S-H1 first; A built in parallel on the same fixture |
| Reversed-Z assumption wrong on D3D12 or Vulkan | S-H1 on both backends; formula isolated in one line and in `HandsProjection` |
| TAA/motion-vector ghosting with B | S-H5; switch to SMAA (4.5, `rendering.md`) is an AA decision for ADR-0019, otherwise A |
| 4.6 glow makes the floor bloom in the blackout | S-H7 glow check; floor below threshold |
| `V02` carried in hand mispositioned by the eye scale | `HandsLightAnchor` unscaled (D1); OI-3 with 28/ADR-0014 |
| Hands leak into `B04` probe | Static check AC-H5 + S-H3 |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| jugador-en-primera-persona.md (2) | Rule 25 / D-07 / TR-player-010: own plane over the world, `fov_manos` 60°, no wall penetration, invariant to `campo_vision` and aspect | D1 (A/B with spike rule), eye-centred scale, `HandsProjection`; AC-31, AC-33 |
| jugador-en-primera-persona.md (2) | Rule 23: always visible; rule 28 / TR-player-010: minimum light in the blackout; material never disabled | D2 constant emissive floor, no run-time toggle; AC-34 via F1 |
| jugador-en-primera-persona.md (2) | D-28 / OQ 2: spike A (SubViewport) vs B (shader) with measurable exit | § Spike Plan S-H1…S-H7 and selection rule |
| jugador-en-primera-persona.md (2) | TR-player-005: hands read the interpolated presentation | `HandsRig` under `PresentationPivot`; guideline |
| jugador-en-primera-persona.md (2) | TR-player-015 / AC-27: hands frozen in pause | D5; S-H6 |
| jugador-en-primera-persona.md (2) | AC-14: `reducir_sobresaltos` changes no Player output | D2: floor independent of every setting; AC-H6 |
| atmosfera-reactiva.md (28) | Rule 8 / TR-atmos-010: hands keep light in the blackout, ratio ≥ 1.5:1 | D2 + F1; AC-28-04 shares the capture |
| atmosfera-reactiva.md (28) | TR-atmos-009 / -013: 28 owns reflections; hands not in `C02` or `B04` | `HANDS` layer excluded from probes; `C02` proxy separate; AC-H5 |
| atmosfera-reactiva.md (28) | TR-atmos-016 / -017: light budget | L2 uses 0 lights; L1 fallback must be accepted by ADR-0014 |
| atmosfera-reactiva.md (28) | Edge case "HDR 4.7 / glow 4.6 alter blackout luminance" ‡; OQ 10 item "mechanism of hands light" | D3; S-H7 glow check; HDR output off (OI-5) |

## Performance Implications
- **CPU**: ≤ 0.05 ms/frame (branch A: one transform copy per frame; B: none after `bind`).
- **GPU**: ≤ 0.30 ms at 1080p (PV, S-H4). B expected near zero (two small meshes in the opaque pass); A adds a culling and render pass.
- **Memory**: B: 0 extra. A: one full-resolution colour + depth target (estimate ≈ 16 MB at 1080p).
- **Load Time**: one extra shader; covered by Shader Baker (4.5, `rendering.md`) when ADR-0015/0018 enable it.
- **Network**: N/A.

## Migration Plan

No code exists. Order: (1) spike in `prototypes/hands_spike/`; (2) write D1
winner and engine-reference write-back; (3) implement `HandsLayers`,
`HandsProjection`, the winning `HandsView`, `hands.gdshader` in `src/` with the
tests below; (4) add `luz_minima_manos` to `player.json` schema (ADR-0005).

**Rollback plan**: the seam stays one class wide. If the winner breaks on an
engine upgrade, re-introduce the other `HandsView` subclass (kept in the spike
folder history) without touching `HandsRig`, GDD 2 or 28.

## Validation Criteria

- AC-31, AC-32, AC-33, AC-34 of GDD 2 and AC-28-04 of GDD 28 pass with
  retained captures.
- Spike selection rule applied and recorded; NS-H1…H10 written back.
- S-H4 budget met on the winner on both backends.

### Test plan

**Unit (gdUnit4, `tests/unit/player/`, Logic, BLOCKING):**
- `hands_projection_test.gd` — AC-H1: `ndc_y` of a fixed view point is identical
  (±1e-6) for main FOV 60/70/90 (main FOV is not an input; asserts the seam);
  `focal(60) = 1.7320508`; `compress_depth(0.0, 0.02) = 0.98`,
  `compress_depth(1.0, 0.02) = 1.0`, monotonic on [0, 1].
- `hands_layers_test.gd` — AC-H2: `without_hands(0xFFFFF) & HANDS_BIT == 0`;
  `HANDS_LAYER_INDEX` in 1–20.
- `hands_rig_test.gd` — AC-H3: with a fake `HandsView`, `configurar()` passes
  `fov_manos` and `luz_minima_manos` from an injected `PlayerConfig` fixture;
  `on_main_fov_changed()` leaves every recorded uniform unchanged; rig scale =
  `HANDS_EYE_SCALE`.
- AC-H6: toggling `reducir_sobresaltos` in a fake `SettingsReader` produces no
  call on `HandsView` (GDD 2 AC-14).

**Integration (`tests/integration/player/`, BLOCKING):**
- `hands_scene_contract_test.gd` — AC-H4: instantiate the `Player` scene; every
  `MeshInstance3D` under `HandsRig` has `layers == HANDS_BIT` and
  `cast_shadow == OFF`; material is `hands.gdshader`; the shader source contains
  no `TIME` token.
- AC-H5 (static tree check, like AC-28-11): in `planta`, every
  `ReflectionProbe.cull_mask & HANDS_BIT == 0`; no node outside `HandsRig` is on
  `HANDS_BIT`; no script under `src/gameplay/atmosphere/` references the hands
  material.

**Visual, retained screenshots (Visual/Feel, BLOCKING) in
`production/qa/evidence/adr-0013/`:**
- `spike/<branch>_<backend>_wall_y<yaw>_p<pitch>.png` (12 per branch per backend) + mask twins `_mask.png`.
- `fov_cv60.png`, `fov_cv70.png`, `fov_cv90.png` (+ `_169`/`_1610`) and masks — AC-31.
- `gestures/<gesture>.png` — AC-32.
- `blackout_scene7.png` + `blackout_scene7_mask.png` + `blackout_ratio.txt` (F1 output, R value) — AC-34 / AC-28-04, with art-director sign-off line.
- `scene1_floor_on.png` / `scene1_floor_off.png` — S-H7 ≤ 5 %.
- `pause_f0.png` / `pause_f600.png` — S-H6.
- `spike_results.txt` — raw S-H1…S-H7 numbers per branch and backend, and the selection-rule outcome.

Mask captures come from a **dev-only** debug mode (`HandsDebug.mask_mode`,
excluded from release per ADR-0018) that renders hands flat white and the world
black from the same pose. F1 and the mask-diff are computed by a tool script in
`tools/qa/` (observation only, never a verdict — CLAUDE.md helper rule).

## Open Items

| # | Item | Owner |
|---|---|---|
| OI-1 | Run the D-28 spike S-H1…S-H7; write D1 winner and NS-H1…H10 back to `rendering.md`. Blocks `Accepted` | technical-artist + engine-programmer |
| OI-2 | `luz_minima_manos` value and AC-34 sign-off; acceptability of the flat floor | art director |
| OI-3 | `V02` (phone screen light, owned by 28) when the phone is held: attach to `HandsLightAnchor` or keep world-fixed; light count in scene 7 | ADR-0014 / 28 |
| OI-4 | If A wins: `CanvasLayer` index of `HandsComposite` below HUD and pause veil | ADR-0016 |
| OI-5 | HDR output (4.7) for the slice: off here; enabling it re-runs S-H7 | ADR-0019 / art director |
| OI-6 | AA mode (TAA vs SMAA) interacts with S-H5 for B | ADR-0019 |
| OI-7 | Blackout duration with `reducir_sobresaltos` (0.8 s) and flicker 1.15 s: **user decision pending** (GDD 28 OQ 8 / OQ 11). This ADR does not depend on either | User |
| OI-8 | Gesture-specific hand/item rendering (e.g. `HAND_CARD_SWIPE`, GDD 2 OQ 9) uses the same layer and material; item meshes held in hand join `HANDS_BIT` while held | ADR-0012 |

### Contradictions detected (for `/architecture-review`)

1. **C1 — GDD 28 hand-off to 2 ("separate light mask for the hands layer",
   § hand-off table row 2) vs GDD 2 rule 28 (hands receive monitor and phone
   light).** A separate light mask that excludes scene lights contradicts rule
   28. Resolved here in favour of GDD 2: separate **render** layer, shared
   lights, emissive floor. GDD 28 row should read "render layer `HANDS` with
   guaranteed emissive floor, ADR-0013 D2" (`/propagate-design-change`).
2. **C2 — TR-atmos-010 wording "mechanism (mask, second camera, shader)"**
   mixes the drawing technique (D1) with the lighting mechanism (D2). This ADR
   separates them: lighting is decided (L2), drawing is spike-decided. TR text
   to be updated at the next `/architecture-review`.
3. **C3 — ADR-0007 OI-6** asks the rendering ADRs which effects are flashes:
   answered for hands (none). 28's blackout and flicker remain for ADR-0014.

## Related
- Depends on: ADR-0002 (pause), ADR-0005 (data path), ADR-0007 (`A11yConstants`, `FlashGuard`), ADR-0009 (composition, D11).
- Enables: ADR-0012, ADR-0014, ADR-0015, ADR-0016, ADR-0019 (none written yet).
- `design/gdd/jugador-en-primera-persona.md` rules 23–28, D-07, D-28, OQ 2, AC-31…AC-34.
- `design/gdd/atmosfera-reactiva.md` rule 8, DT-5, OQ 10, OQ 11, AC-28-04.
- `docs/architecture/architecture.md` § Required ADRs (ADR-0013 row).
- `docs/architecture/tr-baseline-provisional.md` TR-player-005, -008, -010, -015; TR-atmos-009, -010, -013, -016, -017.
- `docs/engine-reference/godot/modules/rendering.md`.
