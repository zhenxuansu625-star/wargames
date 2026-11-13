class_name BattleSim
extends RefCounted
## Top-level battle simulation: owns the units and steps them each fixed tick.
## Pure logic; the battle scene renders it and feeds it player orders.

## Spacing between units in a group move, in world units. Set from the
## battle data's formation_spacing_m.
var formation_spacing: float = 64.0

## Callable(from: Vector2, to: Vector2) -> PackedVector2Array returning
## waypoints (excluding or including `from`). The battle scene plugs in the
## navigation map; the default walks in a straight line (handy for tests).
var path_finder: Callable = func(_from: Vector2, to: Vector2) -> PackedVector2Array:
	return PackedVector2Array([to])

var _units: Dictionary[StringName, SimUnit] = {}
## Insertion order, so iteration is deterministic.
var _order: Array[StringName] = []


func add_unit(unit: SimUnit) -> void:
	assert(not _units.has(unit.id), "duplicate unit id %s" % unit.id)
	_units[unit.id] = unit
	_order.append(unit.id)


func get_unit(id: StringName) -> SimUnit:
	return _units.get(id)


func has_unit(id: StringName) -> bool:
	return _units.has(id)


func units() -> Array[SimUnit]:
	var result: Array[SimUnit] = []
	for id in _order:
		result.append(_units[id])
	return result


func unit_ids() -> Array[StringName]:
	return _order.duplicate()


## One fixed simulation step of [param dt] seconds.
func tick(dt: float) -> void:
	for id in _order:
		var unit := _units[id]
		unit.previous_position = unit.position
		Movement.step(unit, dt)


## Orders the given units to move to [param target]. A group keeps a grid
## formation centred on the target, facing the direction of travel.
func order_move(ids: Array[StringName], target: Vector2) -> void:
	var movers: Array[SimUnit] = []
	for id in ids:
		if _units.has(id):
			movers.append(_units[id])
	if movers.is_empty():
		return

	var centre := Vector2.ZERO
	for unit in movers:
		centre += unit.position
	centre /= movers.size()
	var heading := (target - centre).angle() if target != centre else 0.0

	var offsets := Formation.grid_offsets(movers.size(), formation_spacing, heading)
	# Assign slots so units don't cross each other: sort both by how far along
	# the frontage they are.
	var across := Vector2.from_angle(heading).orthogonal()
	movers.sort_custom(func(a: SimUnit, b: SimUnit) -> bool:
		return a.position.dot(across) < b.position.dot(across))
	offsets.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.dot(across) < b.dot(across))

	for i in movers.size():
		var unit := movers[i]
		var path: PackedVector2Array = path_finder.call(unit.position, target + offsets[i])
		unit.set_path(path)
