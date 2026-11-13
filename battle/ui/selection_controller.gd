class_name SelectionController
extends Control
## Mouse selection and move commands for the battle:
## - left click a unit to select it, left click empty ground to deselect
## - left drag to box-select; hold Shift to add to the selection
## - right click to order the selected units to move there; Shift+right
##   click queues the move after their current orders
##
## Covers the screen on the HUD layer, draws the drag box, and works on
## sim units through BattleSim / Selection (no node references to units).

signal move_requested(world_target: Vector2, queued: bool)

## Drags shorter than this (screen pixels) count as clicks.
const DRAG_THRESHOLD := 6.0
const BOX_FILL := Color(0.95, 0.95, 0.55, 0.12)
const BOX_BORDER := Color(0.95, 0.95, 0.55, 0.9)

var sim: BattleSim
var selection: Selection
var camera: BattleCamera
## Side the player controls.
var player_side: StringName = &"allies"

var _drag_start := Vector2.ZERO
var _drag_end := Vector2.ZERO
var _pressing := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Let clicks fall through to _unhandled_input so other UI can take them first.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_dragging() -> bool:
	return _pressing and _drag_start.distance_to(_drag_end) >= DRAG_THRESHOLD


func _unhandled_input(event: InputEvent) -> void:
	if sim == null or selection == null or camera == null:
		return
	if event.is_action_pressed(&"select"):
		_pressing = true
		_drag_start = event.position
		_drag_end = event.position
		get_viewport().set_input_as_handled()
	elif event.is_action_released(&"select") and _pressing:
		_drag_end = event.position
		_finish_selection(Input.is_action_pressed(&"selection_add"))
		_pressing = false
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pressing:
		_drag_end = event.position
		queue_redraw()
	elif event.is_action_pressed(&"command"):
		if not selection.is_empty():
			move_requested.emit(camera.screen_to_world(event.position),
					Input.is_action_pressed(&"order_queue"))
		get_viewport().set_input_as_handled()


func _finish_selection(additive: bool) -> void:
	var units := sim.units()
	var picked: Array[StringName] = []
	if is_dragging():
		var a := camera.screen_to_world(_drag_start)
		var b := camera.screen_to_world(_drag_end)
		picked = Selection.units_in_rect(units, Rect2(a, b - a), player_side)
	else:
		var hit := Selection.unit_at_point(units, camera.screen_to_world(_drag_end), player_side)
		if hit != &"":
			picked.append(hit)
	if picked.is_empty() and not additive:
		selection.clear()
	else:
		selection.select(picked, additive)


func _draw() -> void:
	if not is_dragging():
		return
	var rect := Rect2(_drag_start, _drag_end - _drag_start).abs()
	draw_rect(rect, BOX_FILL)
	draw_rect(rect, BOX_BORDER, false, 1.5)
