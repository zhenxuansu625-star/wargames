class_name SquadView
extends Node2D
## Placeholder visual for an infantry squad. Reads its SimUnit every frame;
## never changes sim state.

const SIDE_COLORS := {
	"allies": Color(0.33, 0.47, 0.75),
	"axis": Color(0.70, 0.30, 0.25),
}
const SELECTED_COLOR := Color(0.95, 0.95, 0.55)
const PATH_COLOR := Color(1, 1, 1, 0.55)
const QUEUE_COLOR := Color(1, 1, 1, 0.4)
const SOLDIER_COLOR := Color(0.1, 0.12, 0.08)

var unit: SimUnit
var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			queue_redraw()


func bind(sim_unit: SimUnit) -> void:
	unit = sim_unit
	name = String(sim_unit.id)
	position = sim_unit.position


## Positions the view between the unit's last two tick positions.
func sync(alpha: float) -> void:
	if unit == null:
		return
	position = unit.previous_position.lerp(unit.position, alpha)
	queue_redraw()


func _draw() -> void:
	if unit == null:
		return
	var r := unit.radius

	if selected:
		_draw_orders()
		draw_arc(Vector2.ZERO, r + 6.0, 0.0, TAU, 32, SELECTED_COLOR, 2.5)

	var body: Color = SIDE_COLORS.get(String(unit.side), Color.GRAY)
	draw_circle(Vector2.ZERO, r, body)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color.BLACK, 1.5)
	# Facing tick.
	var dir := Vector2.from_angle(unit.facing)
	draw_line(dir * r * 0.6, dir * (r + 5.0), Color.BLACK, 2.5)
	# One dot per soldier.
	for i in unit.soldiers:
		var angle := TAU * i / maxi(unit.soldiers, 1)
		draw_circle(Vector2.from_angle(angle) * r * 0.6, 2.0, SOLDIER_COLOR)

	# Number of orders waiting behind the current one.
	var queued := unit.orders.size() - 1
	if queued > 0:
		_draw_label("+%d" % queued, Vector2(r + 4.0, r + 4.0), 11)

	_draw_label(unit.display_name, Vector2(0, -r - 10.0), 12, true)


## Current path as a solid line, queued orders as dashed legs to numbered
## waypoints. All in local coordinates.
func _draw_orders() -> void:
	# Where the current order leaves the unit (its own position if idle).
	var end := Vector2.ZERO
	if unit.is_moving():
		var line := PackedVector2Array([Vector2.ZERO])
		for p in unit.remaining_path():
			line.append(p - position)
		draw_polyline(line, PATH_COLOR, 2.0)
		end = line[line.size() - 1]
		draw_circle(end, 5.0, PATH_COLOR)
	elif unit.orders.current != null:
		end = unit.orders.current.planned_end_position(unit.position) - position
	var n := 1
	for p in unit.orders.pending_waypoints(unit.position):
		var point := p - position
		draw_dashed_line(end, point, QUEUE_COLOR, 2.0, 8.0)
		draw_arc(point, 6.0, 0.0, TAU, 16, QUEUE_COLOR, 2.0)
		_draw_label(str(n), point + Vector2(8.0, -8.0), 11)
		end = point
		n += 1


func _draw_label(text: String, at: Vector2, font_size: int, centred := false) -> void:
	var font := ThemeDB.fallback_font
	var pos := at
	if centred:
		pos.x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2.0
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

