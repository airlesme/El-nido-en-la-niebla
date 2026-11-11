extends GdUnitTestSuite
# Verifica NS-8 de ADR-0001 en Godot 4.7.2 (V-ENG-5).
## A runtime error inside a Callable.call() during an index drain: does the caller's loop continue?
## The probe runs in a child Godot process: gdUnit4 turns any in-process script error into a test error.

const PROBE: String = "res://tests/unit/engine_facts/fixtures/callback_error_probe.gd"


func test_callback_runtime_error_does_not_wedge_drain() -> void:
	# Arrange
	var args: PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", PROBE]
	var output: Array = []

	# Act
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "".join(output)
	print("V-ENG-5 exit=", code, " output=", text)

	# Assert: the error is reported, only the callee aborts ("b:after" missing), the loop reaches "c" and the end
	assert_int(code).is_equal(0)
	assert_bool(text.contains("Nonexistent function 'nonexistent_method'")).is_true()
	assert_bool(text.contains("PROBE_RESULT log=a,b:before,c reached_end=true")).is_true()
