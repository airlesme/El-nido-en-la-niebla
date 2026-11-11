## Schema of `assets/data/input/default_bindings.json` (ADR-0005 D1/D2/D10, ADR-0006 D1/D11). Owned by system 1.
## Shape: `{schema_version: 1, actions: [{name, keyboard_mouse: [binding], gamepad: [binding], comment?}],
## tuning: {<key>: {value, min, max}}, toggles: {<key>: bool}}` with a binding `{kind, code, axis_dir?}`.
## `actions` holds exactly the physical actions of GDD 1 rule 1 (`PHYSICAL_ACTIONS`); the derived
## gestures (`leer`, `agarrar`, `rotar`, `mantener`, `repasar_bolsillo`) and `correr`/`agacharse`/`saltar`
## are not in the closed list, so they are rejected as an unknown value. The objects are closed, so a
## combo, double-tap or timer field is an unknown key (AC-04, part L): the only waits are `t_hold` and
## the drag (`d_drag_px`), both in `tuning`.
## TODO(ADR-0006): the order of the `mover` keyboard bindings (up, down, left, right) and the use of one
## binding per stick axis for `mover`/`mirar` are ADR-fallbacks of EC-001; ADR-0006 does not fix them.
## Example: `var entry := DataCatalog.Entry.new("input/default_bindings.json", DefaultBindingsSchema.new())`.
class_name DefaultBindingsSchema extends DataSchema

## Physical actions of GDD 1 rule 1 (with the accents of GDD 18/24).
const PHYSICAL_ACTIONS: Array[StringName] = [
	&"mover", &"mirar", &"interactuar", &"pausa", &"atrás", &"mover_cursor", &"seleccionar",
	&"ui_arriba", &"ui_abajo", &"ui_izquierda", &"ui_derecha", &"ui_aceptar", &"ui_atrás",
]
## Actions that must keep at least one binding per device (GDD 1 rule 17).
const MINIMUM_ACTIONS: Array[StringName] = [&"interactuar", &"atrás", &"pausa"]
## Binding kinds accepted by the file, by device (names of `InputTypes.RawKind`).
const KEYBOARD_MOUSE_KINDS: Array[StringName] = [&"KEY", &"MOUSE_BUTTON", &"MOUSE_MOTION"]
const GAMEPAD_KINDS: Array[StringName] = [&"PAD_BUTTON", &"PAD_AXIS"]
## Tuning keys of "Valores por defecto y rangos seguros" (GDD 1 § Formulas). Each is {value, min, max}.
const TUNING_KEYS: Array[StringName] = [
	&"k_mouse_deg_per_px", &"dz_in", &"dz_out", &"omega_max_deg_s", &"omega_r_max_deg_s",
	&"v_max_px_s", &"attract_r_base_px", &"attract_r_max_elem_px", &"attract_lambda",
	&"t_hold_s", &"d_drag_px", &"n_m_px", &"t_m_s", &"transition_cap_s", &"sin_control_margin_s",
]
## Boolean settings of GDD 1 rule 18 and their initial values.
const TOGGLE_KEYS: Array[StringName] = [
	&"attract_assist", &"toggle_instead_of_hold", &"invert_y_keyboard_mouse", &"invert_y_gamepad",
]
## Generous outer bound of every tuning number (the real safe range is the file's own min/max).
const NUMBER_LIMIT: float = 100000.0
const CODE_LIMIT: int = 1 << 24


## Semantic checks a FieldSpec tree cannot express.
class BindingsRules extends FileRules:
	func check(value: Variant, file: String, issues: Array[DataIssue]) -> void:
		var root: Dictionary = value
		var actions: Array = root["actions"]
		var seen: Dictionary = {}
		for i: int in actions.size():
			var a: Dictionary = actions[i]
			seen[StringName(a["name"])] = true
			var p: String = "actions[%d]" % i
			_check_list(a["keyboard_mouse"] as Array, DefaultBindingsSchema.KEYBOARD_MOUSE_KINDS,
					file, p + ".keyboard_mouse", issues)
			_check_list(a["gamepad"] as Array, DefaultBindingsSchema.GAMEPAD_KINDS,
					file, p + ".gamepad", issues)
			if StringName(a["name"]) in DefaultBindingsSchema.MINIMUM_ACTIONS:
				for dev: String in ["keyboard_mouse", "gamepad"]:
					if (a[dev] as Array).is_empty():
						issues.append(_err(file, "%s.%s" % [p, dev], &"minimum",
								"%s keeps at least one binding per device" % a["name"]))
		for need: StringName in DefaultBindingsSchema.PHYSICAL_ACTIONS:
			if not seen.has(need):
				issues.append(_err(file, "actions", &"required", "missing action %s" % need))
		_check_tuning(root["tuning"] as Dictionary, file, issues)


	func _check_list(list: Array, kinds: Array[StringName], file: String, p: String,
			issues: Array[DataIssue]) -> void:
		for j: int in list.size():
			var b: Dictionary = list[j]
			var bp: String = "%s[%d]" % [p, j]
			if not (StringName(b["kind"]) in kinds):
				issues.append(_err(file, bp + ".kind", &"kind",
						"kind %s is not valid for this device" % b["kind"]))
			var dir: int = b.get("axis_dir", 0)
			if StringName(b["kind"]) == &"PAD_AXIS":
				if dir < -1 or dir > 1:
					issues.append(_err(file, bp + ".axis_dir", &"range", "axis_dir must be -1, 0 or 1"))
			elif b.has("axis_dir") and dir != 0:
				issues.append(_err(file, bp + ".axis_dir", &"kind", "axis_dir only applies to PAD_AXIS"))
			for k: int in j:
				var o: Dictionary = list[k]
				if o["kind"] == b["kind"] and o["code"] == b["code"] \
						and int(o.get("axis_dir", 0)) == dir:
					issues.append(_err(file, bp, &"dup_id", "duplicate binding"))


	func _check_tuning(tuning: Dictionary, file: String, issues: Array[DataIssue]) -> void:
		for key: Variant in tuning:
			var t: Dictionary = tuning[key]
			var lo: float = t["min"]
			var hi: float = t["max"]
			var v: float = t["value"]
			var p: String = "tuning.%s" % key
			if lo > hi:
				issues.append(_err(file, p + ".min", &"range", "min %s is above max %s" % [lo, hi]))
			elif v < lo or v > hi:
				issues.append(_err(file, p + ".value", &"range", "value %s outside [%s, %s]" % [v, lo, hi]))
		var dz_in: Dictionary = tuning["dz_in"]
		var dz_out: Dictionary = tuning["dz_out"]
		if float(dz_out["value"]) > float(dz_in["value"]):
			issues.append(_err(file, "tuning.dz_out.value", &"range", "dz_out must not exceed dz_in"))


	static func _err(file: String, path: String, rule: StringName, msg: String) -> DataIssue:
		return DataIssue.new(DataIssue.Severity.ERROR, file, path, rule, msg)


func version() -> int:
	return 1


func root() -> FieldSpec:
	var binding: FieldSpec = object_({
		"kind": enum_([&"KEY", &"MOUSE_BUTTON", &"MOUSE_MOTION", &"PAD_BUTTON", &"PAD_AXIS"] as Array[StringName]),
		"code": int_(0, CODE_LIMIT),
	}, {"axis_dir": int_(-1, 1)})
	var actions: FieldSpec = array_(object_({
		"name": enum_(PHYSICAL_ACTIONS),
		"keyboard_mouse": array_(binding),
		"gamepad": array_(binding),
	}, {"comment": string_()}), PHYSICAL_ACTIONS.size(), &"name")
	actions.max_len = PHYSICAL_ACTIONS.size()
	var tuning_req: Dictionary = {}
	for k: StringName in TUNING_KEYS:
		tuning_req[String(k)] = object_({
			"value": float_(-NUMBER_LIMIT, NUMBER_LIMIT),
			"min": float_(-NUMBER_LIMIT, NUMBER_LIMIT),
			"max": float_(-NUMBER_LIMIT, NUMBER_LIMIT),
		})
	var toggles_req: Dictionary = {}
	for k: StringName in TOGGLE_KEYS:
		toggles_req[String(k)] = bool_()
	return object_({
		"actions": actions,
		"tuning": object_(tuning_req),
		"toggles": object_(toggles_req),
	})


func rules() -> FileRules:
	return BindingsRules.new()
