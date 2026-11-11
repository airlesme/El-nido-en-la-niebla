extends GdUnitTestSuite
## TickInterpolator (PJ-003, ADR-0012 D2): lerp(prev, curr, alpha), no extrapolation. Alpha injected.

const A: Vector3 = Vector3(0.0, 1.6, 0.0)
const B: Vector3 = Vector3(1.0, 1.6, 2.0)


func _make() -> TickInterpolator:
	return TickInterpolator.new()


## Synthetic alpha sequence: the physics tick (1/60) vs a frame of the given fps.
func _alphas(fps: float) -> Array[float]:
	var out: Array[float] = []
	var tick: float = 1.0 / 60.0
	var frame: float = 1.0 / fps
	var acc: float = 0.0
	for i in 120:
		acc = fmod(acc + frame, tick)
		out.append(acc / tick)
	return out


func test_position_at_midpoint_is_lerp() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 0.0, 0.0)

	assert_vector(it.position_at(0.5)).is_equal_approx(A.lerp(B, 0.5), Vector3.ONE * 0.0001)


func test_alpha_sequences_never_leave_prev_curr_segment() -> void:
	for fps: float in [30.0, 60.0, 144.0]:
		var it: TickInterpolator = _make()
		it.reset(A)
		it.push(B, 0.0, 0.0)
		for a: float in _alphas(fps):
			var p: Vector3 = it.position_at(a)
			assert_float(p.x).is_between(0.0, 1.0)
			assert_float(p.z).is_between(0.0, 2.0)
			assert_vector(p).is_equal_approx(A.lerp(B, a), Vector3.ONE * 0.0001)


func test_alpha_out_of_range_is_clamped_no_extrapolation() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 0.0, 0.0)

	assert_vector(it.position_at(-0.5)).is_equal(A)
	assert_vector(it.position_at(1.7)).is_equal(B)


func test_non_finite_alpha_shows_current() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 0.0, 0.0)

	assert_vector(it.position_at(NAN)).is_equal(B)
	assert_vector(it.position_at(INF)).is_equal(B)


func test_reset_collapses_prev_and_curr_so_no_sweep() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 1.0, 1.0)

	it.reset(Vector3(9.0, 1.6, 9.0), 0.25, 0.5)

	for a: float in [0.0, 0.3, 1.0]:
		assert_vector(it.position_at(a)).is_equal(Vector3(9.0, 1.6, 9.0))
		assert_float(it.phase_at(a)).is_equal(0.25)
		assert_float(it.ratio_at(a)).is_equal(0.5)


func test_push_shifts_prev_curr_new() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 0.0, 0.0)
	var c: Vector3 = Vector3(2.0, 1.6, 4.0)

	it.push(c, 0.0, 0.0)

	assert_vector(it.position_at(0.0)).is_equal(B)
	assert_vector(it.position_at(1.0)).is_equal(c)


func test_frozen_alpha_gives_same_output_and_resumes_from_it() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 0.0, 0.0)
	var frozen: Vector3 = it.position_at(0.4)

	for i in 30:
		assert_vector(it.position_at(0.4)).is_equal(frozen)
	# Resume: alpha continues from 0.4 upward.
	assert_vector(it.position_at(0.5)).is_equal_approx(A.lerp(B, 0.5), Vector3.ONE * 0.0001)


func test_phase_and_ratio_use_same_alpha() -> void:
	var it: TickInterpolator = _make()
	it.reset(A, 2.0, 0.0)
	it.push(B, 4.0, 1.0)

	assert_float(it.phase_at(0.25)).is_equal_approx(2.5, 0.0001)
	assert_float(it.ratio_at(0.25)).is_equal_approx(0.25, 0.0001)
	assert_float(it.phase_at(5.0)).is_equal_approx(4.0, 0.0001)


func test_non_finite_push_is_ignored() -> void:
	var it: TickInterpolator = _make()
	it.reset(A)
	it.push(B, 1.0, 1.0)

	it.push(Vector3(NAN, 0.0, 0.0), 0.0, 0.0)
	it.push(B, INF, 0.0)

	assert_vector(it.position_at(1.0)).is_equal(B)
	assert_vector(it.position_at(0.0)).is_equal(A)
	assert_float(it.phase_at(1.0)).is_equal(1.0)
