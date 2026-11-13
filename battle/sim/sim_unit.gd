class_name SimUnit
extends RefCounted
## Simulation state of one battle unit (squad, vehicle or gun team).
## Pure data plus small helpers; no nodes or rendering.
##
## World units are pixels. Speeds are converted from m/s using the map's
## pixels_per_meter when the unit is spawned.

var id: StringName
var template_id: StringName
var display_name: String = ""
## "allies" / "axis".
var side: StringName = &"allies"
var soldiers: int = 0
## Movement speed in world units (px) per second.
var move_speed: float = 0.0
## Click/box selection radius in world units.
var radius: float = 16.0

var position: Vector2 = Vector2.ZERO
## Position at the start of the last tick, for render interpolation.
var previous_position: Vector2 = Vector2.ZERO
## Direction the unit faces, in radians (0 = +x).
var facing: float = 0.0

## Waypoints still to visit; path[path_index] is the current target.
var path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0


func _init(unit_id: StringName = &"", start_position := Vector2.ZERO) -> void:
	id = unit_id
	position = start_position
	previous_position = start_position


## Builds a unit from a data/units template. [param pixels_per_meter] converts
## the template's m/s speed into world units.
static func from_template(unit_id: StringName, template: Dictionary, start_position: Vector2,
		pixels_per_meter: float) -> SimUnit:
	var unit := SimUnit.new(unit_id, start_position)
	unit.template_id = StringName(template.get("id", ""))
	unit.display_name = template.get("name", String(unit_id))
	unit.soldiers = int(template.get("soldiers", 0))
	unit.move_speed = float(template.get("move_speed_mps", 0.0)) * pixels_per_meter
	unit.radius = float(template.get("selection_radius_m", 2.0)) * pixels_per_meter
	return unit


func is_moving() -> bool:
	return path_index < path.size()


## Replaces the current path. Waypoints equal to the current position are fine;
## Movement skips them.
func set_path(new_path: PackedVector2Array) -> void:
	path = new_path
	path_index = 0


func stop() -> void:
	path = PackedVector2Array()
	path_index = 0


## Waypoints not yet reached (for drawing the path line).
func remaining_path() -> PackedVector2Array:
	if not is_moving():
		return PackedVector2Array()
	return path.slice(path_index)


## Final destination, or the current position when idle.
func destination() -> Vector2:
	return path[path.size() - 1] if is_moving() else position
