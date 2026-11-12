extends GdUnitTestSuite
## Integration test: BattleMap bakes a navigation polygon and paths go around
## obstacles via NavigationServer2D.

const WALL := [[400, 0], [600, 0], [600, 800], [400, 800]]


func _make_map() -> BattleMap:
	var map: BattleMap = auto_free(BattleMap.new())
	add_child(map)
	map.setup({
		"size": [1000, 1000],
		"pixels_per_meter": 8,
		"nav_agent_radius_m": 2,
		"obstacles": [{"kind": "building", "polygon": WALL}],
	})
	return map


func _await_nav_sync(map: BattleMap) -> void:
	# The navigation map synchronises on physics frames.
	for i in 60:
		if map.is_navigation_ready():
			return
		await get_tree().physics_frame


func test_no_path_before_navigation_ready() -> void:
	var map := _make_map()
	assert_bool(map.is_navigation_ready()).is_false()
	assert_int(map.find_path(Vector2(200, 400), Vector2(800, 400)).size()).is_equal(0)


func test_path_goes_around_obstacle() -> void:
	var map := _make_map()
	await _await_nav_sync(map)
	assert_bool(map.is_navigation_ready()).is_true()
	var from := Vector2(200, 400)
	var to := Vector2(800, 400)
	var path := map.find_path(from, to)

	assert_int(path.size()).is_greater(2)
	if path.is_empty():
		return
	assert_vector(path[path.size() - 1]).is_equal_approx(to, Vector2(1, 1))
	var wall := DataLoader.to_polygon(WALL)
	for i in path.size() - 1:
		for s in 10:
			var p := path[i].lerp(path[i + 1], s / 10.0)
			assert_bool(Geometry2D.is_point_in_polygon(p, wall)).is_false()
	# The only gap is below the wall.
	var lowest := 0.0
	for p in path:
		lowest = maxf(lowest, p.y)
	assert_float(lowest).is_greater(800.0)


func test_target_inside_obstacle_ends_at_closest_reachable_point() -> void:
	var map := _make_map()
	await _await_nav_sync(map)
	# Target inside the wall, nearer its west face.
	var path := map.find_path(Vector2(200, 400), Vector2(450, 400))
	assert_int(path.size()).is_greater(0)
	if path.is_empty():
		return
	var end := path[path.size() - 1]
	assert_bool(Geometry2D.is_point_in_polygon(end, DataLoader.to_polygon(WALL))).is_false()
	assert_float(end.x).is_less(410.0)
