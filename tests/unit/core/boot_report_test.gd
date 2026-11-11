extends GdUnitTestSuite
## Boot report line and `--boot-report` argument (ADR-0018 D4 layer 3, V-18-2/V-18-7).


func test_report_line_release_flavor_says_release() -> void:
	# Arrange
	var flavor: BuildFlavor = BuildFlavor.new(false)

	# Act
	var line: String = Boot.format_report_line(flavor, "0.1.0", "abc1234", "absent")

	# Assert
	assert_str(line).is_equal("[boot] flavor=release dev_tools=absent version=0.1.0 commit=abc1234")


func test_report_line_debug_flavor_says_debug() -> void:
	# Arrange
	var flavor: BuildFlavor = BuildFlavor.new(true)

	# Act
	var line: String = Boot.format_report_line(flavor, "dev", "dev", "absent")

	# Assert
	assert_str(line).starts_with("[boot] flavor=debug ")


func test_wants_boot_report_flag_present_returns_true() -> void:
	assert_bool(Boot.wants_boot_report(PackedStringArray(["--x", "--boot-report"]))).is_true()


func test_wants_boot_report_flag_absent_returns_false() -> void:
	assert_bool(Boot.wants_boot_report(PackedStringArray())).is_false()
	assert_bool(Boot.wants_boot_report(PackedStringArray(["--boot-reports"]))).is_false()
