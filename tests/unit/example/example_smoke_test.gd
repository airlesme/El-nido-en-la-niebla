extends GdUnitTestSuite
## Example unit test: proves the gdUnit4 runner is wired up. Deterministic, no I/O.
## Replace/delete once real system tests exist (tests/unit/[system]/).


func _clamp_percent(value: int) -> int:
	return clampi(value, 0, 100)


func test_clamp_percent_above_range_returns_100() -> void:
	# Arrange
	var input := 250

	# Act
	var result := _clamp_percent(input)

	# Assert
	assert_int(result).is_equal(100)


func test_clamp_percent_in_range_returns_same_value() -> void:
	# Arrange
	var input := 42

	# Act
	var result := _clamp_percent(input)

	# Assert
	assert_int(result).is_equal(42)
