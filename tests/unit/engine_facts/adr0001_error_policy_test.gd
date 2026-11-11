extends GdUnitTestSuite
# Verifica NS-4 de ADR-0001 en Godot 4.7.2 (V-ENG-4), parte editor/headless.
## The release half runs in prototypes/bus-spike (exported exe); see its README.
## assert(false) and push_error are NOT invoked here: they would halt/poison the suite itself.


func test_error_policy_strict_in_debug_noop_in_release() -> void:
	# Arrange / Act
	var debug: bool = OS.is_debug_build()
	print("V-ENG-4 suite: OS.is_debug_build()=", debug, " has_feature(editor)=", OS.has_feature("editor"))

	# Assert: the gdUnit run is a debug build, so the dev-halt branch is the one selected here
	assert_bool(debug).is_true()


func test_assert_true_is_silent_in_debug() -> void:
	# Arrange / Act
	assert(true, "never fires")

	# Assert: reaching this line means assert(true) did not stop execution
	assert_bool(OS.has_feature("release")).is_false()
