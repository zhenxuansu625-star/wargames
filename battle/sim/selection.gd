class_name Selection
extends RefCounted
## The player's current unit selection, plus the pure hit-testing used by
## click and box select. Holds unit ids, not nodes.

signal changed

var _ids: Array[StringName] = []


func ids() -> Array[StringName]:
	return _ids.duplicate()


func has(id: StringName) -> bool:
	return _ids.has(id)


func is_empty() -> bool:
	return _ids.is_empty()


func size() -> int:
	return _ids.size()


func clear() -> void:
	if _ids.is_empty():
		return
	_ids.clear()
	changed.emit()


## Replaces the selection, or adds to it when [param additive] is true
## (Shift held).
func select(new_ids: Array[StringName], additive: bool = false) -> void:
	var before := _ids.duplicate()
	if not additive:
		_ids.clear()
	for id in new_ids:
		if not _ids.has(id):
			_ids.append(id)
	if _ids != before:
		changed.emit()


## Drops ids that no longer exist (e.g. destroyed units).
func retain(existing: Array[StringName]) -> void:
	var before := _ids.size()
	_ids = _ids.filter(func(id: StringName) -> bool: return existing.has(id))
	if _ids.size() != before:
		changed.emit()


## Ids of [param side] units whose centre lies inside [param rect] (world
## space; the rect may have negative size from dragging up/left).
static func units_in_rect(units: Array[SimUnit], rect: Rect2, side: StringName) -> Array[StringName]:
	var area := rect.abs()
	var result: Array[StringName] = []
	for unit in units:
		if unit.side == side and area.has_point(unit.position):
			result.append(unit.id)
	return result


## Id of the closest [param side] unit whose radius contains [param point],
## or &"" if none.
static func unit_at_point(units: Array[SimUnit], point: Vector2, side: StringName) -> StringName:
	var best: StringName = &""
	var best_dist := INF
	for unit in units:
		if unit.side != side:
			continue
		var dist := unit.position.distance_to(point)
		if dist <= unit.radius and dist < best_dist:
			best = unit.id
			best_dist = dist
	return best
