extends GdUnitTestSuite


func _units() -> Array[SimUnit]:
	var a := SimUnit.new(&"a", Vector2(10, 10))
	var b := SimUnit.new(&"b", Vector2(100, 10))
	var enemy := SimUnit.new(&"enemy", Vector2(20, 20))
	enemy.side = &"axis"
	var result: Array[SimUnit] = [a, b, enemy]
	return result


func test_box_selects_only_own_units_inside() -> void:
	var picked := Selection.units_in_rect(_units(), Rect2(0, 0, 50, 50), &"allies")
	assert_array(picked).contains_exactly([&"a"])


func test_box_dragged_up_left_works() -> void:
	var picked := Selection.units_in_rect(_units(), Rect2(150, 50, -150, -50), &"allies")
	assert_array(picked).contains_exactly_in_any_order([&"a", &"b"])


func test_click_picks_unit_within_radius() -> void:
	var units := _units()
	assert_str(String(Selection.unit_at_point(units, Vector2(14, 10), &"allies"))).is_equal("a")
	assert_str(String(Selection.unit_at_point(units, Vector2(60, 60), &"allies"))).is_empty()
	# Enemy units can't be selected.
	assert_str(String(Selection.unit_at_point(units, Vector2(20, 20), &"allies"))).is_equal("a")


func test_additive_select_and_clear() -> void:
	var sel := Selection.new()
	var a: Array[StringName] = [&"a"]
	var b: Array[StringName] = [&"b"]
	sel.select(a)
	sel.select(b, true)
	assert_array(sel.ids()).contains_exactly([&"a", &"b"])
	sel.select(b)
	assert_array(sel.ids()).contains_exactly([&"b"])
	sel.clear()
	assert_bool(sel.is_empty()).is_true()


func test_changed_signal_only_on_real_change() -> void:
	var sel := Selection.new()
	var a: Array[StringName] = [&"a"]
	var count := [0]
	sel.changed.connect(func() -> void: count[0] += 1)
	sel.select(a)
	sel.select(a)
	sel.clear()
	sel.clear()
	assert_int(count[0]).is_equal(2)
