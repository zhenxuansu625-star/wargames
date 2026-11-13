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
		unit.orders.update(unit, self, dt)


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return path_finder.call(from, to)


## Orders the given units to move to [param target]. A group keeps a grid
## formation centred on the target, facing the direction of travel.
## With [param queue] the move is added after each unit's existing orders
## (formation planned from where they will be by then); otherwise it
## replaces them.
func issue_move(ids: Array[StringName], target: Vector2, queue: bool = false) -> void:
	var movers := _existing(ids)
	if movers.is_empty():
		return

	# Where each unit will start this move from.
	var starts: Dictionary[StringName, Vector2] = {}
	var centre := Vector2.ZERO
	for unit in movers:
		var start := unit.orders.planned_end_position(unit.position) if queue else unit.position
		starts[unit.id] = start
		centre += start
	centre /= movers.size()
	var heading := (target - centre).angle() if target != centre else 0.0

	var offsets := Formation.grid_offsets(movers.size(), formation_spacing, heading)
	# Assign slots so units don't cross each other: sort both by how far along
	# the frontage they are.
	var across := Vector2.from_angle(heading).orthogonal()
	movers.sort_custom(func(a: SimUnit, b: SimUnit) -> bool:
		return starts[a.id].dot(across) < starts[b.id].dot(across))
	offsets.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.dot(across) < b.dot(across))

	for i in movers.size():
		var order := MoveOrder.new(target + offsets[i])
		if queue:
			movers[i].orders.append(order, movers[i], self)
		else:
			movers[i].orders.replace(order, movers[i], self)


## Cancels all orders of the given units; they stop where they are.
func issue_stop(ids: Array[StringName]) -> void:
	for unit in _existing(ids):
		unit.orders.clear(unit)


func _existing(ids: Array[StringName]) -> Array[SimUnit]:
	var result: Array[SimUnit] = []
	for id in ids:
		if _units.has(id):
			result.append(_units[id])
	return result
