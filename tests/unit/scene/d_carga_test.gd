extends GdUnitTestSuite
## CP-003 (T-U5 of ADR-0003): LoadBudget.d_carga, GDD 4 F3. AC-F3 (part 1), TR-scene-016.


func _transitions(t_cap: float = 10.0, n_gap: int = 2) -> LoadTransitions:
	return LoadTransitions.from_dict({
		"t_cap_s": t_cap, "n_gap": n_gap, "delta_max_s": 0.1, "delta_ref_s": 1.0 / 30.0,
		"t_descarga_total_max_s": 3.0, "reducir_movimiento_s": 0.1,
		"motivos": {
			"partida_nueva": {"d_out": 0.8, "d_in": 2.0},
			"recepcion": {"d_out": 0.8, "d_in": 0.8},
			"cierre": {"d_out": 0.8},
		},
	})


func test_d_carga_recepcion_nominal() -> void:
	assert_float(LoadBudget.d_carga(_transitions(), &"recepcion")).is_equal_approx(11.6667, 0.001)


func test_d_carga_ignores_reduced_motion_values() -> void:
	var t: LoadTransitions = _transitions()
	# The reduced fades are shorter, yet the declared budget stays nominal.
	assert_float(LoadBudget.d_out(t, &"recepcion", true)).is_less(t.d_out_s(&"recepcion"))
	assert_float(LoadBudget.d_carga(t, &"recepcion")).is_equal_approx(11.6667, 0.001)


func test_d_carga_partida_nueva_uses_its_longer_lift() -> void:
	assert_float(LoadBudget.d_carga(_transitions(), &"partida_nueva")).is_equal_approx(12.8667, 0.001)


func test_d_carga_bounds_of_the_gdd_range() -> void:
	assert_float(LoadBudget.d_carga(_transitions(3.0, 0), &"recepcion")).is_equal_approx(4.6, 0.001)
	assert_float(LoadBudget.d_carga(_transitions(10.0, 10), &"recepcion")).is_equal_approx(11.9333, 0.001)
