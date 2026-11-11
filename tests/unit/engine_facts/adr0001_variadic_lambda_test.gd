extends GdUnitTestSuite
# Verifica la nota de lambdas variádicas de ADR-0001 en Godot 4.7.2 (V-ENG-6).


signal three_args(a: int, b: String, c: float)


func test_variadic_lambda_receives_three_args() -> void:
	# Arrange
	var state: Dictionary = {"args": []}
	three_args.connect(func(...args: Array) -> void: state["args"] = args)

	# Act
	three_args.emit(1, "x", 2.5)

	# Assert
	assert_int(state["args"].size()).is_equal(3)
	assert_that(state["args"][0]).is_equal(1)
	assert_that(state["args"][1]).is_equal("x")
	assert_that(state["args"][2]).is_equal(2.5)


func test_variadic_callable_call_forwards_three_args() -> void:
	# Arrange
	var state: Dictionary = {"n": -1}
	var cb: Callable = func(...args: Array) -> void: state["n"] = args.size()

	# Act
	cb.call(1, 2, 3)

	# Assert
	assert_int(state["n"]).is_equal(3)
