extends GdUnitTestSuite
## StepTracker + SurfaceProbe (PJ-006, ADR-0012 D1/D10, AC-38). Pure logic, no engine state.

const L: float = 0.75
const I_MIN: float = 0.4
const V: float = 1.6
const DT: float = 1.0 / 60.0


class FakeProbe extends SurfaceProbe:
	var label: StringName = SurfaceProbe.DEFAULT_SURFACE

	func floor_surface() -> StringName:
		return label


## Walks `meters` at `speed` in physics ticks, collecting every crossing distance.
func _walk(meters: float, speed: float) -> Array[float]:
	var out: Array[float] = []
	var d: float = 0.0
	var step: float = speed * DT
	var ticks: int = int(round(meters / step))
	for i in ticks:
		out.append_array(StepTracker.crossings(d, d + step, L))
		d += step
	return out


func test_walk_three_meters_emits_four_steps_at_expected_distances() -> void:
	var c: Array[float] = _walk(3.0, V)

	assert_int(c.size()).is_equal(4)
	var expected: Array[float] = [0.375, 1.125, 1.875, 2.625]
	for i in 4:
		assert_float(c[i]).is_equal_approx(expected[i], 0.0001)


func test_blocked_by_wall_emits_no_steps() -> void:
	var d: float = 0.0
	var total: int = 0
	for i in 120:
		total += StepTracker.crossings(d, d + 0.0, L).size()

	assert_int(total).is_equal(0)


func test_crossing_on_interval_end_counts_once() -> void:
	var a: Array[float] = StepTracker.crossings(0.0, 0.375, L)
	var b: Array[float] = StepTracker.crossings(0.375, 0.5, L)

	assert_int(a.size()).is_equal(1)
	assert_int(b.size()).is_equal(0)


func test_single_large_step_returns_all_crossings_in_order() -> void:
	var c: Array[float] = StepTracker.crossings(0.0, 3.0, L)

	assert_int(c.size()).is_equal(4)
	assert_float(c[3]).is_equal_approx(2.625, 0.0001)


func test_invalid_inputs_return_empty() -> void:
	assert_int(StepTracker.crossings(1.0, 1.0, L).size()).is_equal(0)
	assert_int(StepTracker.crossings(2.0, 1.0, L).size()).is_equal(0)
	assert_int(StepTracker.crossings(0.0, 3.0, 0.0).size()).is_equal(0)
	assert_int(StepTracker.crossings(0.0, 3.0, -1.0).size()).is_equal(0)
	assert_int(StepTracker.crossings(0.0, NAN, L).size()).is_equal(0)
	assert_int(StepTracker.crossings(0.0, INF, L).size()).is_equal(0)


func test_negative_start_never_yields_negative_n() -> void:
	var c: Array[float] = StepTracker.crossings(-2.0, 0.4, L)

	assert_int(c.size()).is_equal(1)
	assert_float(c[0]).is_equal_approx(0.375, 0.0001)


func test_intensity_matches_ac38_values() -> void:
	assert_float(StepTracker.intensity(1.0, I_MIN)).is_equal_approx(1.0, 0.0001)
	assert_float(StepTracker.intensity(0.5, I_MIN)).is_equal_approx(0.7, 0.0001)
	assert_float(StepTracker.intensity(0.0, I_MIN)).is_equal_approx(0.4, 0.0001)


func test_intensity_clamps_out_of_range_and_nan() -> void:
	assert_float(StepTracker.intensity(3.0, I_MIN)).is_equal_approx(1.0, 0.0001)
	assert_float(StepTracker.intensity(-1.0, I_MIN)).is_equal_approx(I_MIN, 0.0001)
	assert_float(StepTracker.intensity(NAN, I_MIN)).is_equal_approx(I_MIN, 0.0001)


func test_surface_probe_defaults_to_default_label() -> void:
	var probe: FakeProbe = FakeProbe.new()

	assert_str(String(probe.floor_surface())).is_equal("default")


func test_surface_probe_fake_returns_its_label() -> void:
	var probe: FakeProbe = FakeProbe.new()
	probe.label = &"wood"

	assert_str(String(probe.floor_surface())).is_equal("wood")
