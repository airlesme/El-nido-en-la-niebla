extends GdUnitTestSuite
# Verifica NS-3 de ADR-0001 en Godot 4.7.2 (V-ENG-3).
## JSON round trip of integral numbers and the restore rule 13 (int fact accepts int or integral float).


func _roundtrip(value: Variant) -> Variant:
	var text: String = JSON.stringify({"v": value})
	var parsed: Variant = JSON.parse_string(text)
	print("V-ENG-3 ", value, " (", type_string(typeof(value)), ") -> ", text, " -> ", type_string(typeof(parsed["v"])), " ", parsed["v"])
	return parsed["v"]


## Mirror of the ADR rule 13 for int facts: returns the int or null when rejected.
func _restore_int(raw: Variant) -> Variant:
	if typeof(raw) == TYPE_INT:
		return raw
	if typeof(raw) == TYPE_FLOAT and is_equal_approx(fposmod(raw, 1.0), 0.0) and absf(raw) <= 9007199254740992.0:
		return int(raw)
	return null


func test_json_roundtrip_int_fact_restores_as_int() -> void:
	# Arrange
	var values: Array[int] = [2, 0, -3, 1000000, -1000000, 9007199254740992, -9007199254740992]

	# Act / Assert
	for v: int in values:
		var back: Variant = _roundtrip(v)
		assert_that(_restore_int(back)).is_equal(v)


## Observed on 4.7.2 (NS-3): JSON numbers always parse as float, so integers beyond 2^53 lose
## precision. Characterisation of the engine, not a defect of the ADR: fact ints are counters (< 2^31).
func test_json_integers_beyond_2_pow_53_lose_precision() -> void:
	# Arrange
	var big: int = 9007199254740993

	# Act
	var back: Variant = _roundtrip(big)

	# Assert
	assert_that(typeof(back)).is_equal(TYPE_FLOAT)
	assert_that(_restore_int(back)).is_not_equal(big)


func test_json_integral_float_restores_as_int() -> void:
	# Arrange / Act
	var back: Variant = _roundtrip(2.0)

	# Assert
	assert_that(_restore_int(back)).is_equal(2)


func test_json_parse_literal_two_and_two_point_zero_are_both_accepted() -> void:
	# Arrange
	var from_int: Variant = JSON.parse_string("{\"v\": 2}")["v"]
	var from_float: Variant = JSON.parse_string("{\"v\": 2.0}")["v"]
	print("V-ENG-3 literal 2 -> ", type_string(typeof(from_int)), "; literal 2.0 -> ", type_string(typeof(from_float)))

	# Assert
	assert_that(_restore_int(from_int)).is_equal(2)
	assert_that(_restore_int(from_float)).is_equal(2)


func test_json_fractional_float_is_rejected_by_restore() -> void:
	# Arrange / Act
	var back: Variant = JSON.parse_string("{\"v\": 2.5}")["v"]

	# Assert
	assert_that(_restore_int(back)).is_null()
