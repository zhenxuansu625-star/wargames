extends GdUnitTestSuite


class RecordingOrder extends UnitOrder:
	var log: Array
	var label: String
	var ticks_needed: int
	var end := Vector2.ZERO

	func _init(log_ref: Array, name: String, ticks: int = 1, end_point := Vector2.ZERO) -> void:
		log = log_ref
		label = name
		ticks_needed = ticks
		end = end_point

	func start(_unit: SimUnit, _sim: BattleSim) -> void:
		log.append(label + ":start")

	func update(_unit: SimUnit, _sim: BattleSim, _dt: float) -> bool:
		ticks_needed -= 1
		log.append(label + ":tick")
		return ticks_needed <= 0

	func cancel(_unit: SimUnit) -> void:
		log.append(label + ":cancel")

	func planned_end_position(_from: Vector2) -> Vector2:
		return end


var _sim: BattleSim
var _unit: SimUnit


func before_test() -> void:
	_sim = BattleSim.new()
	_unit = SimUnit.new(&"u")


func test_append_to_idle_queue_starts_immediately() -> void:
	var log: Array = []
	_unit.orders.append(RecordingOrder.new(log, "a"), _unit, _sim)
	assert_array(log).contains_exactly(["a:start"])


func test_queued_orders_start_only_after_previous_finishes() -> void:
	var log: Array = []
	var q := _unit.orders
	q.append(RecordingOrder.new(log, "a", 2), _unit, _sim)
	q.append(RecordingOrder.new(log, "b", 1), _unit, _sim)
	q.update(_unit, _sim, 0.05)
	q.update(_unit, _sim, 0.05)
	q.update(_unit, _sim, 0.05)
	assert_array(log).contains_exactly(["a:start", "a:tick", "a:tick", "b:start", "b:tick"])
	assert_bool(q.is_idle()).is_true()


func test_replace_cancels_current_and_drops_queue() -> void:
	var log: Array = []
	var q := _unit.orders
	q.append(RecordingOrder.new(log, "a", 5), _unit, _sim)
	q.append(RecordingOrder.new(log, "b"), _unit, _sim)
	q.replace(RecordingOrder.new(log, "c"), _unit, _sim)
	assert_array(log).contains_exactly(["a:start", "a:cancel", "c:start"])
	assert_int(q.size()).is_equal(1)


func test_clear_cancels_and_empties() -> void:
	var log: Array = []
	var q := _unit.orders
	q.append(RecordingOrder.new(log, "a", 5), _unit, _sim)
	q.append(RecordingOrder.new(log, "b"), _unit, _sim)
	q.clear(_unit)
	assert_bool(q.is_idle()).is_true()
	assert_array(log).contains_exactly(["a:start", "a:cancel"])


func test_planned_end_and_pending_waypoints() -> void:
	var log: Array = []
	var q := _unit.orders
	assert_vector(q.planned_end_position(Vector2(1, 1))).is_equal(Vector2(1, 1))
	q.append(RecordingOrder.new(log, "a", 5, Vector2(10, 0)), _unit, _sim)
	q.append(RecordingOrder.new(log, "b", 1, Vector2(20, 0)), _unit, _sim)
	q.append(RecordingOrder.new(log, "c", 1, Vector2(30, 0)), _unit, _sim)
	assert_vector(q.planned_end_position(Vector2.ZERO)).is_equal(Vector2(30, 0))
	var points := q.pending_waypoints(Vector2.ZERO)
	assert_int(points.size()).is_equal(2)
	assert_vector(points[0]).is_equal(Vector2(20, 0))
	assert_vector(points[1]).is_equal(Vector2(30, 0))


func test_move_order_paths_from_position_when_started() -> void:
	var from_points: Array = []
	_sim.path_finder = func(from: Vector2, to: Vector2) -> PackedVector2Array:
		from_points.append(from)
		return PackedVector2Array([to])
	_unit.move_speed = 100.0
	var q := _unit.orders
	q.append(MoveOrder.new(Vector2(50, 0)), _unit, _sim)
	q.append(MoveOrder.new(Vector2(50, 50)), _unit, _sim)
	# Second path isn't requested until the first leg is done.
	assert_int(from_points.size()).is_equal(1)
	q.update(_unit, _sim, 1.0)
	assert_int(from_points.size()).is_equal(2)
	assert_vector(from_points[1]).is_equal(Vector2(50, 0))
