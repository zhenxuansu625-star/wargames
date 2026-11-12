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

	if selected and unit.is_moving():
		var line := PackedVector2Array([Vector2.ZERO])
		for p in unit.remaining_path():
			line.append(p - position)
		draw_polyline(line, PATH_COLOR, 2.0)
		draw_circle(line[line.size() - 1], 5.0, PATH_COLOR)

	if selected:
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

	var font := ThemeDB.fallback_font
	var label := unit.display_name
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string_outline(font, Vector2(-width / 2.0, -r - 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
	draw_string(font, Vector2(-width / 2.0, -r - 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
