# PROTOTYPE - NOT FOR PRODUCTION
extends RefCounted
## Builds the grey corridor `pasillo` (slice A.3) in code: boxes only, no textures.
## X west->east, Z south->north, Y up. Corridor X 0..26, Z -1.3..1.3, ceiling Y 2.6.
## South wall has the window (C02) at X 12..20, Y 0.9..2.6.

const AtmosphereScript := preload("res://atmosphere.gd")

const GLASS_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.05, 0.08, 0.12, 1.0);
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = tint.rgb;
	ALPHA = mix(0.12, 0.75, f);
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 1.0;
}
"""


static func _mat(c: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func _box(parent: Node, nm: String, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	mi.name = nm
	mi.position = center
	parent.add_child(mi)
	return mi


## opts: lights_n:int, shadows:int, rain:bool, glow:bool, reflection:bool, rain_mode:String, blackout:bool, c28:bool
static func build(root: Node3D, opts: Dictionary) -> Dictionary:
	var grey_wall := _mat(Color(0.5, 0.5, 0.5))
	var grey_floor := _mat(Color(0.3, 0.3, 0.3))
	var grey_ceil := _mat(Color(0.4, 0.4, 0.4))
	var grey_back := _mat(Color(0.2, 0.22, 0.25))

	# --- environment: fixed exposure (no CameraAttributes), AgX, glow, SDR ---
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.11, 0.16, 0.22)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = opts["glow"]
	env.glow_intensity = 0.8
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)

	# --- static geometry (outside the 28 subtree) ---
	var geo := Node3D.new()
	geo.name = "Corridor"
	root.add_child(geo)
	_box(geo, "Floor", Vector3(13, -0.1, 0), Vector3(26, 0.2, 2.6), grey_floor)
	_box(geo, "Ceiling", Vector3(13, 2.7, 0), Vector3(26, 0.2, 2.6), grey_ceil)
	_box(geo, "WallNorth", Vector3(13, 1.3, 1.4), Vector3(26, 2.6, 0.2), grey_wall)
	_box(geo, "WallWest", Vector3(-0.1, 1.3, 0), Vector3(0.2, 2.6, 2.6), grey_wall)
	_box(geo, "WallEast", Vector3(26.1, 1.3, 0), Vector3(0.2, 2.6, 2.6), grey_wall)
	_box(geo, "WallSouthA", Vector3(6, 1.3, -1.4), Vector3(12, 2.6, 0.2), grey_wall)
	_box(geo, "WallSouthB", Vector3(23, 1.3, -1.4), Vector3(6, 2.6, 0.2), grey_wall)
	_box(geo, "WallSouthSill", Vector3(16, 0.45, -1.4), Vector3(8, 0.9, 0.2), grey_wall)
	_box(geo, "PatioBack", Vector3(16, 1.5, -4.5), Vector3(14, 4.0, 0.2), grey_back)
	# door blocks (north wall) for scale, grey
	_box(geo, "DoorB", Vector3(12.5, 1.05, 1.28), Vector3(1.0, 2.1, 0.05), grey_floor)
	_box(geo, "DoorD", Vector3(21.5, 1.05, 1.28), Vector3(1.0, 2.1, 0.05), grey_floor)

	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.position = Vector3(3, 1.6, 0)
	root.add_child(cam)

	# --- atmosphere subtree (system 28) ---
	var atm: AtmosphereScript = AtmosphereScript.new()
	atm.name = "Atmosphere28"
	atm.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.add_child(atm)
	atm.camera = cam
	atm.env = env
	atm.ambient_nom = 0.9
	atm.rain_mode = opts["rain_mode"]
	atm.blackout_enabled = opts["blackout"]

	# C03: SpotLights pointing down, no shadow except the allowlist.
	var shadow_idx: Array[int] = [3, 2]
	var n: int = clampi(opts["lights_n"], 0, 14)
	for i in n:
		var x := 3.0 + 4.0 * i
		var z := 0.0
		if i >= 6:
			x = 5.0 + 4.0 * ((i - 6) % 6)
			z = 0.4
		var l := SpotLight3D.new()
		l.name = "C03_%d" % i
		l.position = Vector3(x, 2.55, z)
		l.rotation_degrees = Vector3(-90, 0, 0)
		l.spot_range = 7.0
		l.spot_angle = 80.0
		l.spot_attenuation = 1.0
		l.light_color = Color(0.65, 0.78, 1.0)
		l.light_energy = 6.0
		l.shadow_enabled = shadow_idx.find(i) >= 0 and shadow_idx.find(i) < int(opts["shadows"])
		l.add_to_group("proto_lights")
		atm.add_child(l)
		atm.lights.append(l)
		atm.nominal.append(6.0)
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(0.2, 0.2, 0.2)
		fm.emission_enabled = true
		fm.emission = Color(0.65, 0.78, 1.0)
		fm.emission_energy_multiplier = atm.FIXTURE_EMISSION
		_box(atm, "Fixture_%d" % i, Vector3(x, 2.57, z), Vector3(1.2, 0.05, 0.25), fm)
		atm.fixture_mats.append(fm)

	# C02 glass: window quad + ReflectionProbe + mirrored proxy (ghost).
	var gm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GLASS_SHADER
	gm.shader = sh
	var glass := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(8.0, 1.7)
	q.material = gm
	glass.mesh = q
	glass.name = "C02_Glass"
	glass.position = Vector3(16, 1.75, -1.3)
	atm.add_child(glass)

	if opts["reflection"]:
		var probe := ReflectionProbe.new()
		probe.name = "C02_Probe"
		probe.position = Vector3(13, 1.3, 0)
		probe.size = Vector3(26, 2.6, 2.6)
		probe.interior = true
		probe.box_projection = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		atm.add_child(probe)
		var ghost := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(0.5, 1.7, 0.35)
		gb.material = _mat(Color(0.7, 0.7, 0.72), 0.6)
		ghost.mesh = gb
		ghost.name = "C02_ProxyGhost"
		ghost.visible = false
		atm.add_child(ghost)
		atm.ghost = ghost

	# Rain: one GPUParticles3D behind the window.
	var rain := GPUParticles3D.new()
	rain.name = "RainWindow"
	rain.position = Vector3(16, 3.4, -1.9)
	rain.amount = 200
	rain.lifetime = 0.5
	rain.use_fixed_seed = true
	rain.seed = 20261109
	rain.visibility_aabb = AABB(Vector3(-5, -5, -1), Vector3(10, 6, 2))
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(4.0, 0.05, 0.4)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 2.0
	pm.initial_velocity_min = 7.0
	pm.initial_velocity_max = 9.0
	pm.gravity = Vector3(0, -2, 0)
	rain.process_material = pm
	var rq := QuadMesh.new()
	rq.size = Vector2(0.015, 0.35)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	rm.albedo_color = Color(0.5, 0.62, 0.8, 0.6)
	rq.material = rm
	rain.draw_pass_1 = rq
	rain.emitting = opts["rain"]
	rain.visible = opts["rain"]
	atm.add_child(rain)
	atm.rain = rain

	return {"env": env, "camera": cam, "atm": atm}
