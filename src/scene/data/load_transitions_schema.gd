## Schema of `assets/data/scene/load_transitions.json` (ADR-0003 D, ADR-0005 D2). Owned by system 4.
## Shape: `{schema_version: 1, t_cap_s, n_gap, delta_max_s, delta_ref_s, t_descarga_total_max_s,
## reducir_movimiento_s, motivos: {partida_nueva|reanudar|recepcion: {d_out, d_in}, cierre: {d_out}}}`.
## Ranges are those of `design/gdd/escena-de-planta.md` § Tuning Knobs and Edge Cases: `d_out`/`d_in` 0-5 s,
## `t_cap_s` (GDD `T_cap`) 3-30 s, `n_gap` 0-10 frames, `delta_max_s` (GDD `Δ_max`) 0.05-0.1 s,
## `delta_ref_s` (`Δ_ref`) 1/144-1/30 s, `t_descarga_total_max_s` 1-5 s, `reducir_movimiento_s` (the fixed
## fade of rule 11, art bible 7.4) 0-5 s. A value outside its range, a missing or unknown key is a data error.
## Example: `var entry := DataCatalog.Entry.new("scene/load_transitions.json", LoadTransitionsSchema.new())`.
class_name LoadTransitionsSchema extends DataSchema

## Slack for `delta_ref_s` at its documented bounds (1/30 and 1/144 are not exactly representable in JSON).
const _REF_EPS: float = 1e-6


func version() -> int:
	return 1


func root() -> FieldSpec:
	var fade_both: Dictionary = {"d_out": float_(0.0, 5.0), "d_in": float_(0.0, 5.0)}
	return object_({
		"t_cap_s": float_(3.0, 30.0),
		"n_gap": int_(0, 10),
		"delta_max_s": float_(0.05, 0.1),
		"delta_ref_s": float_(1.0 / 144.0 - _REF_EPS, 1.0 / 30.0 + _REF_EPS),
		"t_descarga_total_max_s": float_(1.0, 5.0),
		"reducir_movimiento_s": float_(0.0, 5.0),
		"motivos": object_({
			"partida_nueva": object_(fade_both),
			"reanudar": object_(fade_both),
			"recepcion": object_(fade_both),
			# `cierre` only darkens (TR-scene-015): no d_in.
			"cierre": object_({"d_out": float_(0.0, 5.0)}),
		}),
	})
