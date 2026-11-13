extends GdUnitTestSuite


func test_format_speed() -> void:
	assert_str(TimeControls.format_speed(0.25)).is_equal("0.25x")
	assert_str(TimeControls.format_speed(0.5)).is_equal("0.5x")
	assert_str(TimeControls.format_speed(1.0)).is_equal("1x")
	assert_str(TimeControls.format_speed(4.0)).is_equal("4x")
