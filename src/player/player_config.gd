## Typed, validated view of `assets/data/player/player.json` (ADR-0012 § Key Interfaces «PlayerConfig», D1, D4; TR-player-002, TR-player-021).
## Every knob of GDD 2 § Tuning Knobs lives here; nothing about the player is hard-coded elsewhere.
## Angles are exposed in radians (`pitch_max`, `pitch_cesion_max`, converted once here, C-R20); the two FOVs stay in degrees
## because `Camera3D.fov` and `fov_actual()` use degrees (ADR-0012 D4). Knob names follow the JSON keys (snake_case):
## GDD `T_hist` -> `t_hist`, `L_paso` -> `l_paso`, `A_v` -> `a_v`, `A_h` -> `a_h`, `A_manos` -> `a_manos`,
## `X_in_max` -> `x_in_max`, `A_resp` -> `a_resp`, `T_giro` -> `t_giro`.
## Any failure while loading is fatal `CATALOGO_INVALIDO` with the parameter name in `detail[&"param"]` and the
## config is not created (`load_from` returns null).
## TODO(ADR-0012): no signature is fixed for the factory; this story fixes `load_from(reader, fatal, tick_rate, passage)`
## and `from_dict(d)` and records them as an amendment to § Key Interfaces (ADR-fallback; owner: lead-programmer).
## Example: `var cfg := PlayerConfig.load_from(reader, ctx.fatal, Engine.physics_ticks_per_second); if cfg == null: return`.
class_name PlayerConfig extends RefCounted

## File of the registry row (ADR-0005 D1), relative to assets/data/.
const PATH: String = "player/player.json"
## GDD system number that owns the file.
const OWNER: int = 2
## Registry constant `player_min_passage_width_m` (design/registry/entities.yaml; GDD 2 Core Rules 3), in metres.
## TODO(ADR-0005): read it from the registry once a loader for registry constants exists (owner: lead-programmer).
const PLAYER_MIN_PASSAGE_WIDTH_M: float = 0.60
## `radio_sensor_zona` when the optional key is absent (GDD 2 Tuning Knobs default; ADR-0005 D1 allows omitting it).
const DEFAULT_RADIO_SENSOR_ZONA: float = 0.05
## Settings default of `campo_vision` (vertical FOV, degrees; slice A.0). Injected until the Settings reader exists.
## TODO(ADR-0007): replace with the Settings value when ADR-0007 is Accepted (owner: lead-programmer).
const DEFAULT_CAMPO_VISION_DEG: float = 70.0


## One entry of the `gestures` catalogue (ADR-0012 D9).
class GestureDef extends RefCounted:
	## Gesture id, e.g. `HAND_REACH`.
	var id: StringName = &""
	## `right`, `left`, `both` or `held` (the hand of the held object).
	var hand: StringName = &""
	## `blocking` (fixed duration) or `background` (loop).
	var kind: StringName = &""
	## Seconds; 0.0 for background gestures.
	var duration_s: float = 0.0
	## Extra hands whose background gestures it suspends.
	var also_suspends: Array[StringName] = []
	## True when it uses the object currently held.
	var uses_held: bool = false
	## True when it is rejected without a held object.
	var requires_held: bool = false
	## Gesture started when this one completes, or empty.
	var chain_on_complete: StringName = &""


	## True for a blocking gesture.
	func is_blocking() -> bool:
		return kind == &"blocking"


# --- body and collision (GDD 2 rules 1-4)
var v_paseo: float = 0.0
var k_atras: float = 0.0
var k_lat: float = 0.0
var t_acel: float = 0.0
var t_freno: float = 0.0
var radio_capsula: float = 0.0
var margen_paso: float = 0.0
var altura_capsula: float = 0.0
var altura_ojos: float = 0.0
## Zone-sensor sphere radius in metres (default when omitted: `DEFAULT_RADIO_SENSOR_ZONA`).
var radio_sensor_zona: float = 0.0
# --- camera
## Free-look pitch limit, radians (JSON `pitch_max_deg`).
var pitch_max: float = 0.0
## Pitch limit of leased poses, radians (JSON `pitch_cesion_max_deg`).
var pitch_cesion_max: float = 0.0
var propietarios_camara: Array[StringName] = []
## Horizontal FOV cap, degrees.
var fov_h_max_deg: float = 0.0
var near: float = 0.0
## Hands camera FOV, degrees.
var fov_manos_deg: float = 0.0
## Vertical FOV from Settings (injected default; not in player.json).
var campo_vision_deg: float = DEFAULT_CAMPO_VISION_DEG
## Initial sway level from Settings (injected default `reducido`; not in player.json).
var balanceo_nivel: StringName = &"reducido"
# --- bob, hands, breathing
var g_completo: float = 0.0
var g_reducido: float = 0.0
var t_cambio_balanceo: float = 0.0
var l_paso: float = 0.0
var a_v: float = 0.0
var a_h: float = 0.0
var a_manos: float = 0.0
var phi_ret: float = 0.0
var k_in: float = 0.0
var tau_in: float = 0.0
var x_in_max: float = 0.0
var a_resp: float = 0.0
var f_resp: float = 0.0
var i_paso_min: float = 0.0
# --- time and history
var t_devolver: float = 0.0
var t_transicion_max: float = 0.0
var t_hist: float = 0.0
var t_giro: float = 0.0
var f_fisica: int = 0
# --- safety net
var t_atasco: float = 0.0
var t_pose_segura: float = 0.0
var y_min: float = 0.0
var eps_atasco_m: float = 0.0
# --- hands
var t_item_dentro: float = 0.0
var t_item_fuera: float = 0.0
var t_mano_s: float = 0.0
var sostenibles_escena: Array[StringName] = []
## Gesture id (StringName) -> GestureDef.
var gestures: Dictionary[StringName, GestureDef] = {}


## Reads and validates `player/player.json`. On any problem raises `CATALOGO_INVALIDO` on `fatal` with
## `{param, value, owner, file, rule, message}` and returns null; otherwise returns the config.
## `engine_tick_rate` is the engine's physics rate (inject `Engine.physics_ticks_per_second`; C-R22) and
## `passage_width_m` the registry constant. Example: `PlayerConfig.load_from(reader, fatal, 60)`.
static func load_from(reader: DataReader, fatal: FatalErrorHandler, engine_tick_rate: int,
		passage_width_m: float = PLAYER_MIN_PASSAGE_WIDTH_M) -> PlayerConfig:
	var res: DataResult = reader.read_file(DataCatalog.Entry.new(PATH, PlayerSchema.new()))
	var bad: DataIssue = res.first_error()
	if bad == null:
		bad = cross_check(res.value, engine_tick_rate, passage_width_m)
	if bad != null:
		fatal.raise_fatal(FatalErrorHandler.CATALOGO_INVALIDO, {
			&"param": bad.json_path, &"value": null, &"owner": OWNER, &"file": bad.file,
			&"rule": bad.rule, &"message": bad.message,
		})
		return null
	return from_dict(res.value)


## Checks the invariants that need injected facts: `f_fisica` = engine tick rate (ADR-0012 D1, TR-player-021) and
## `2*radio_capsula + margen_paso` = passage width (TR-player-002). Returns the first failing DataIssue or null.
static func cross_check(d: Dictionary, engine_tick_rate: int, passage_width_m: float) -> DataIssue:
	if int(d["f_fisica"]) != engine_tick_rate:
		return DataIssue.new(DataIssue.Severity.ERROR, PATH, "f_fisica", &"range",
				"f_fisica %d differs from the engine tick rate %d" % [d["f_fisica"], engine_tick_rate])
	var width: float = 2.0 * float(d["radio_capsula"]) + float(d["margen_paso"])
	if not is_equal_approx(width, passage_width_m):
		return DataIssue.new(DataIssue.Severity.ERROR, PATH, "radio_capsula", &"invariant",
				"2*radio_capsula + margen_paso = %s, registry says %s" % [width, passage_width_m])
	return null


## Builds the config from a tree already normalised by `PlayerSchema` (no validation here).
## Example: `PlayerConfig.from_dict(result.value)`.
static func from_dict(d: Dictionary) -> PlayerConfig:
	var c: PlayerConfig = PlayerConfig.new()
	c.v_paseo = float(d["v_paseo"])
	c.k_atras = float(d["k_atras"])
	c.k_lat = float(d["k_lat"])
	c.t_acel = float(d["t_acel"])
	c.t_freno = float(d["t_freno"])
	c.radio_capsula = float(d["radio_capsula"])
	c.margen_paso = float(d["margen_paso"])
	c.altura_capsula = float(d["altura_capsula"])
	c.altura_ojos = float(d["altura_ojos"])
	c.radio_sensor_zona = float(d.get("radio_sensor_zona", DEFAULT_RADIO_SENSOR_ZONA))
	c.pitch_max = deg_to_rad(float(d["pitch_max_deg"]))
	c.pitch_cesion_max = deg_to_rad(float(d["pitch_cesion_max_deg"]))
	c.propietarios_camara.assign(d["propietarios_camara"] as Array)
	c.fov_h_max_deg = float(d["fov_h_max_deg"])
	c.near = float(d["near"])
	c.fov_manos_deg = float(d["fov_manos_deg"])
	c.g_completo = float(d["g_completo"])
	c.g_reducido = float(d["g_reducido"])
	c.t_cambio_balanceo = float(d["t_cambio_balanceo"])
	c.l_paso = float(d["l_paso"])
	c.a_v = float(d["a_v"])
	c.a_h = float(d["a_h"])
	c.a_manos = float(d["a_manos"])
	c.phi_ret = float(d["phi_ret"])
	c.k_in = float(d["k_in"])
	c.tau_in = float(d["tau_in"])
	c.x_in_max = float(d["x_in_max"])
	c.a_resp = float(d["a_resp"])
	c.f_resp = float(d["f_resp"])
	c.i_paso_min = float(d["i_paso_min"])
	c.t_devolver = float(d["t_devolver"])
	c.t_transicion_max = float(d["t_transicion_max"])
	c.t_hist = float(d["t_hist"])
	c.t_giro = float(d["t_giro"])
	c.f_fisica = int(d["f_fisica"])
	c.t_atasco = float(d["t_atasco"])
	c.t_pose_segura = float(d["t_pose_segura"])
	c.y_min = float(d["y_min"])
	c.eps_atasco_m = float(d["eps_atasco_m"])
	c.t_item_dentro = float(d["t_item_dentro"])
	c.t_item_fuera = float(d["t_item_fuera"])
	c.t_mano_s = float(d["t_mano_s"])
	c.sostenibles_escena.assign(d["sostenibles_escena"] as Array)
	var src: Dictionary = d["gestures"]
	for key: Variant in src:
		var g: Dictionary = src[key]
		var def: GestureDef = GestureDef.new()
		def.id = StringName(str(key))
		def.hand = g["hand"]
		def.kind = g["kind"]
		def.duration_s = float(g.get("duration_s", 0.0))
		if g.has("also_suspends"):
			def.also_suspends.assign(g["also_suspends"] as Array)
		def.uses_held = bool(g.get("uses_held", false))
		def.requires_held = bool(g.get("requires_held", false))
		def.chain_on_complete = StringName(g.get("chain_on_complete", &""))
		c.gestures[def.id] = def
	return c
