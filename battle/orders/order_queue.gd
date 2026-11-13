class_name OrderQueue
extends RefCounted
## A unit's current order plus the orders queued behind it (Shift+click).
##
## A new order starts immediately when the unit is idle, even while the
## battle is paused, so its path can be shown before time resumes.

var current: UnitOrder = null
var _pending: Array[UnitOrder] = []


func is_idle() -> bool:
	return current == null and _pending.is_empty()


## Orders waiting behind the current one, in execution order.
func pending() -> Array[UnitOrder]:
	return _pending.duplicate()


## Total orders, current included.
func size() -> int:
	return _pending.size() + (1 if current != null else 0)


## Drops everything and starts [param order] now.
func replace(order: UnitOrder, unit: SimUnit, sim: BattleSim) -> void:
	clear(unit)
	_begin(order, unit, sim)


## Adds [param order] to the end of the queue (starts it now if idle).
func append(order: UnitOrder, unit: SimUnit, sim: BattleSim) -> void:
	if is_idle():
		_begin(order, unit, sim)
	else:
		_pending.append(order)


## Cancels the current order and forgets the queue.
func clear(unit: SimUnit) -> void:
	if current != null:
		current.cancel(unit)
		current = null
	_pending.clear()


## Runs the current order for one tick; moves on to the next queued order
## when it finishes.
func update(unit: SimUnit, sim: BattleSim, dt: float) -> void:
	if current == null:
		if _pending.is_empty():
			return
		_begin(_pending.pop_front(), unit, sim)
	if current.update(unit, sim, dt):
		current = null
		if not _pending.is_empty():
			_begin(_pending.pop_front(), unit, sim)


## Where the unit will end up after every order, starting from [param from].
func planned_end_position(from: Vector2) -> Vector2:
	var pos := from
	if current != null:
		pos = current.planned_end_position(pos)
	for order in _pending:
		pos = order.planned_end_position(pos)
	return pos


## End points of the queued (not yet started) orders, for drawing.
func pending_waypoints(from: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var pos := from
	if current != null:
		pos = current.planned_end_position(pos)
	for order in _pending:
		pos = order.planned_end_position(pos)
		points.append(pos)
	return points


func _begin(order: UnitOrder, unit: SimUnit, sim: BattleSim) -> void:
	current = order
	order.start(unit, sim)
