class_name Movement
extends RefCounted
## Moves units along their waypoint paths. Pure logic, stepped once per tick.


## Advances [param unit] along its path by move_speed * dt. Distance left over
## after reaching a waypoint carries on toward the next one, so speed is
## constant through corners. Updates facing to the direction of travel.
static func step(unit: SimUnit, dt: float) -> void:
	var budget := unit.move_speed * dt
	while budget > 0.0 and unit.is_moving():
		var target := unit.path[unit.path_index]
		var to_target := target - unit.position
		var dist := to_target.length()
		if dist > 0.0001:
			unit.facing = to_target.angle()
		if dist <= budget:
			unit.position = target
			budget -= dist
			unit.path_index += 1
		else:
			unit.position += to_target / dist * budget
			budget = 0.0
	if not unit.is_moving():
		unit.stop()
