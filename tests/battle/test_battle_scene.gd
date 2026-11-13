extends GdUnitTestSuite
## Integration test of the battle scene's time controls: pause, orders while
## paused, the order queue and game speed. Frames are stepped by calling
## _process() with fixed deltas so results don't depend on real frame timing.

var _runner: GdUnitSceneRunner
var _battle: Node2D


func before_test() -> void:
	_runner = scene_runner("res://battle/battle.tscn")
	_battle = _runner.scene()
	var map: BattleMap = _battle.get_node("Map")
	for i in 120:
		if map.is_navigation_ready():
			break
		await _runner.simulate_frames(1)
	assert_bool(map.is_navigation_ready()).is_true()


func _step(seconds: float, frame := 0.05) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		_battle._process(frame)
		t += frame


func _first_unit() -> SimUnit:
	return _battle.sim.units()[0]


func _ids(unit: SimUnit) -> Array[StringName]:
	var ids: Array[StringName] = [unit.id]
	return ids


func test_paused_battle_takes_orders_but_nothing_moves() -> void:
	var unit := _first_unit()
	var start := unit.position
	_battle.set_paused(true)
	var paused_at: float = _battle.clock.elapsed_seconds()
	_battle.sim.issue_move(_ids(unit), start + Vector2(200, 0))
	# The path exists straight away so the player can see it while paused...
	assert_bool(unit.is_moving()).is_true()
	_step(2.0)
	# ...but no time passes.
	assert_vector(unit.position).is_equal(start)
	assert_float(_battle.clock.elapsed_seconds()).is_equal(paused_at)

	_battle.set_paused(false)
	_step(1.0)
	assert_float(unit.position.distance_to(start)).is_greater(1.0)


func test_queue_built_while_paused_runs_in_order_after_resume() -> void:
	var unit := _first_unit()
	var a := unit.position + Vector2(80, 0)
	var b := a + Vector2(0, 80)
	_battle.set_paused(true)
	_battle.sim.issue_move(_ids(unit), a)
	_battle.sim.issue_move(_ids(unit), b, true)
	assert_int(unit.orders.size()).is_equal(2)
	_battle.set_paused(false)
	# 80 px at 40 px/s = 2 s per leg; allow slack.
	_step(2.5)
	assert_int(unit.orders.size()).is_equal(1)
	_step(2.5)
	assert_bool(unit.orders.is_idle()).is_true()
	assert_vector(unit.position).is_equal_approx(b, Vector2(1, 1))


func test_double_speed_covers_twice_the_ground() -> void:
	var unit := _first_unit()
	var start := unit.position
	_battle.sim.issue_move(_ids(unit), start + Vector2(400, 0))
	_step(1.0)
	var normal := unit.position.distance_to(start)

	_battle.sim.issue_stop(_ids(unit))
	var start2 := unit.position
	_battle.step_speed(1)
	assert_float(_battle.clock.speed).is_equal(2.0)
	_battle.sim.issue_move(_ids(unit), start2 + Vector2(400, 0))
	_step(1.0)
	assert_float(unit.position.distance_to(start2)).is_equal_approx(normal * 2.0, 1.0)


func test_pause_toggle_updates_overlay_and_emits_signal() -> void:
	var overlay: Control = _battle.get_node("%PauseOverlay")
	var received: Array = []
	var on_paused := func(paused: bool) -> void: received.append(paused)
	EventBus.battle_paused_changed.connect(on_paused)
	_battle.toggle_pause()
	assert_bool(overlay.visible).is_true()
	_battle.toggle_pause()
	assert_bool(overlay.visible).is_false()
	EventBus.battle_paused_changed.disconnect(on_paused)
	assert_array(received).contains_exactly([true, false])
