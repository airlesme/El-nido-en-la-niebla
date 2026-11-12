## Durations of one load (GDD 4 F1 table + rule 11, F3; ADR-0003 step 0 and D5). Pure: reads a `LoadTransitions`.
## `reducir_movimiento` is read ONCE per load by the caller (Settings, ADR-0007) and passed here as `reduced`.
## `D_carga = d_out + T_cap + N_gap * delta_ref + d_in`, always from NOMINAL table values (an upper bound).
## Example: `var d: float = LoadBudget.d_carga(transitions, LoadTransitions.MOTIVO_RECEPCION)  # ~11.667`.
class_name LoadBudget extends RefCounted


## Darken duration used by this load: the fixed reduced-motion value when `reduced`, else the table value.
static func d_out(t: LoadTransitions, motivo: StringName, reduced: bool) -> float:
	return t.reduced_motion_s if reduced else t.d_out_s(motivo)


## Lighten duration used by this load. `cierre` never lifts, so it stays 0 even with `reduced`.
static func d_in(t: LoadTransitions, motivo: StringName, reduced: bool) -> float:
	var nominal: float = t.d_in_s(motivo)
	if nominal <= 0.0:
		return 0.0
	return t.reduced_motion_s if reduced else nominal


## `D_carga` declared to Entrada, nominal values (independent of `reducir_movimiento`).
static func d_carga(t: LoadTransitions, motivo: StringName) -> float:
	return t.d_out_s(motivo) + t.t_cap_s + float(t.n_gap) * t.delta_ref_s + t.d_in_s(motivo)
