extends GdUnitTestSuite


func test_single_unit_goes_to_target() -> void:
	var offsets := Formation.grid_offsets(1, 40.0)
	assert_int(offsets.size()).is_equal(1)
	assert_vector(offsets[0]).is_equal_approx(Vector2.ZERO, Vector2(0.001, 0.001))


func test_offsets_are_distinct_and_centred() -> void:
	for count in [2, 3, 4, 5, 7, 9]:
		var offsets := Formation.grid_offsets(count, 40.0, 0.7)
		assert_int(offsets.size()).is_equal(count)
		var centre := Vector2.ZERO
		for i in count:
			centre += offsets[i]
			for j in range(i + 1, count):
				assert_float(offsets[i].distance_to(offsets[j])).is_greater_equal(39.9)
		centre /= count
		# Short last rows can pull the centre a little, but never past one spacing.
		assert_float(centre.length()).is_less(40.0)


func test_line_is_perpendicular_to_heading() -> void:
	# Two units moving east stand side by side north/south.
	var offsets := Formation.grid_offsets(2, 40.0, 0.0)
	assert_float(offsets[0].x).is_equal_approx(offsets[1].x, 0.001)
	assert_float(absf(offsets[0].y - offsets[1].y)).is_equal_approx(40.0, 0.001)


func test_zero_units() -> void:
	assert_int(Formation.grid_offsets(0, 40.0).size()).is_equal(0)
