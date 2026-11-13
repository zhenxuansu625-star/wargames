extends GdUnitTestSuite


func _unit(speed: float, start := Vector2.ZERO) -> SimUnit:
	var unit := SimUnit.new(&"u", start)
	unit.move_speed = speed
	return unit


func test_moves_toward_waypoint_at_speed() -> void:
	var unit := _unit(10.0)
	unit.set_path(PackedVector2Array([Vector2(100, 0)]))
	Movement.step(unit, 1.0)
	assert_vector(unit.position).is_equal_approx(Vector2(10, 0), Vector2(0.001, 0.001))
	assert_bool(unit.is_moving()).is_true()


func test_leftover_distance_carries_round_corners() -> void:
	var unit := _unit(10.0)
	unit.set_path(PackedVector2Array([Vector2(4, 0), Vector2(4, 100)]))
	Movement.step(unit, 1.0)
	# 4 px east, then the remaining 6 px south.
	assert_vector(unit.position).is_equal_approx(Vector2(4, 6), Vector2(0.001, 0.001))
	assert_float(unit.facing).is_equal_approx(PI / 2.0, 0.001)


func test_stops_exactly_at_destination() -> void:
	var unit := _unit(50.0)
	unit.set_path(PackedVector2Array([Vector2(10, 0), Vector2(20, 0)]))
	Movement.step(unit, 1.0)
	assert_vector(unit.position).is_equal(Vector2(20, 0))
	assert_bool(unit.is_moving()).is_false()
	assert_int(unit.path.size()).is_equal(0)


func test_waypoint_at_current_position_is_skipped() -> void:
	# NavigationServer paths start with the unit's own position.
	var unit := _unit(10.0, Vector2(5, 5))
	unit.set_path(PackedVector2Array([Vector2(5, 5), Vector2(5, 25)]))
	Movement.step(unit, 1.0)
	assert_vector(unit.position).is_equal_approx(Vector2(5, 15), Vector2(0.001, 0.001))


func test_idle_unit_does_not_move() -> void:
	var unit := _unit(10.0, Vector2(3, 3))
	Movement.step(unit, 1.0)
	assert_vector(unit.position).is_equal(Vector2(3, 3))
