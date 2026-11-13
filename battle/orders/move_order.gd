class_name MoveOrder
extends UnitOrder
## Walk to a point. The path is found when the order starts, from wherever
## the unit is at that moment, so queued moves chain correctly.

var target: Vector2


func _init(target_point: Vector2) -> void:
	kind = &"move"
	target = target_point


func start(unit: SimUnit, sim: BattleSim) -> void:
	unit.set_path(sim.find_path(unit.position, target))


func update(unit: SimUnit, _sim: BattleSim, dt: float) -> bool:
	Movement.step(unit, dt)
	return not unit.is_moving()


func cancel(unit: SimUnit) -> void:
	unit.stop()


func planned_end_position(_from: Vector2) -> Vector2:
	return target
