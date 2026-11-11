extends GdUnitTestSuite
## BuildFlavor is injectable (ADR-0005): release behaviour must be testable in the editor.


func test_flavor_false_reports_release() -> void:
	# Arrange
	var flavor: BuildFlavor = BuildFlavor.new(false)

	# Act / Assert
	assert_bool(flavor.is_debug()).is_false()


func test_flavor_true_reports_debug() -> void:
	# Arrange
	var flavor: BuildFlavor = BuildFlavor.new(true)

	# Act / Assert
	assert_bool(flavor.is_debug()).is_true()


func test_from_engine_matches_os_debug_build() -> void:
	# Arrange / Act
	var flavor: BuildFlavor = BuildFlavor.from_engine()

	# Assert (editor and playtest: true, demo: false, ADR-0018 V-18-2)
	assert_bool(flavor.is_debug()).is_equal(OS.is_debug_build())
