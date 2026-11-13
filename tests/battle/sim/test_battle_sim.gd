extends GdUnitTestSuite


func _sim_with_units(positions: Array[Vector2], speed := 10.0) -> BattleSim:
	var sim := BattleSim.new()
	for i in positions.size():
		var unit := SimUnit.new(StringName("u%d" % i), positions[i])
		unit.move_speed = speed
		sim.add_unit(unit)
	return sim


func test_move_order_uses_path_finder() -> void:
	var sim := _sim_with_units([Vector2.ZERO])
	var calls: Array = []
	sim.path_finder = func(from: Vector2, to: Vector2) -> PackedVector2Array:
		calls.append([from, to])
		return PackedVector2Array([Vector2(0, 50), to])
	sim.order_move([&"u0"], Vector2(50, 50))
	assert_int(calls.size()).is_equal(1)
	assert_vector(calls[0][1]).is_equal(Vector2(50, 50))
	assert_int(sim.get_unit(&"u0").path.size()).is_equal(2)


func test_tick_moves_units_and_records_previous_position() -> void:
	var sim := _sim_with_units([Vector2.ZERO])
	sim.order_move([&"u0"], Vector2(100, 0))
	sim.tick(0.5)
	var unit := sim.get_unit(&"u0")
	assert_vector(unit.previous_position).is_equal(Vector2.ZERO)
	assert_vector(unit.position).is_equal_approx(Vector2(5, 0), Vector2(0.001, 0.001))


func test_group_move_spreads_destinations() -> void:
	var sim := _sim_with_units([Vector2(0, 0), Vector2(0, 40), Vector2(0, 80)])
	sim.order_move(sim.unit_ids(), Vector2(500, 40))
	var destinations: Array[Vector2] = []
	for unit in sim.units():
		destinations.append(unit.destination())
	for i in destinations.size():
		for j in range(i + 1, destinations.size()):
			assert_float(destinations[i].distance_to(destinations[j])).is_greater(1.0)


func test_group_move_keeps_left_to_right_order() -> void:
	# Units side by side (north to south) moving east keep their order, so
	# their paths don't cross.
	var sim := _sim_with_units([Vector2(0, 0), Vector2(0, 100)])
	sim.order_move(sim.unit_ids(), Vector2(500, 50))
	var north := sim.get_unit(&"u0").destination()
	var south := sim.get_unit(&"u1").destination()
	assert_float(north.y).is_less(south.y)


func test_unknown_ids_are_ignored() -> void:
	var sim := _sim_with_units([Vector2.ZERO])
	sim.order_move([&"nope"], Vector2(10, 10))
	assert_bool(sim.get_unit(&"u0").is_moving()).is_false()


func test_unit_from_template_converts_metres() -> void:
	var template := {"id": "t", "name": "T", "soldiers": 12, "move_speed_mps": 5.0, "selection_radius_m": 2.0}
	var unit := SimUnit.from_template(&"x", template, Vector2(1, 2), 8.0)
	assert_float(unit.move_speed).is_equal(40.0)
	assert_float(unit.radius).is_equal(16.0)
	assert_int(unit.soldiers).is_equal(12)
