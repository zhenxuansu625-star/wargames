class_name BattleCamera
extends Camera2D
## RTS camera: WASD/arrow keys or middle-mouse drag to pan, mouse wheel to zoom
## toward the cursor. Stays inside the map bounds.

## Keyboard pan speed in screen pixels per second (constant on screen at any zoom).
@export var pan_speed: float = 900.0
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5
## Zoom multiplier per wheel notch.
@export var zoom_step: float = 1.15

var bounds: Rect2 = Rect2()

var _dragging := false


func _process(delta: float) -> void:
	var dir := Input.get_vector(&"camera_pan_left", &"camera_pan_right", &"camera_pan_up", &"camera_pan_down")
	if dir != Vector2.ZERO:
		position += dir * pan_speed * delta / zoom.x
		clamp_to_bounds()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_zoom_in"):
		zoom_at(zoom.x * zoom_step, get_viewport().get_mouse_position())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"camera_zoom_out"):
		zoom_at(zoom.x / zoom_step, get_viewport().get_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom.x
		clamp_to_bounds()
		get_viewport().set_input_as_handled()


## Sets the zoom level, keeping the world point under [param screen_point] fixed.
func zoom_at(new_zoom: float, screen_point: Vector2) -> void:
	new_zoom = clampf(new_zoom, min_zoom, max_zoom)
	var world_before := screen_to_world(screen_point)
	zoom = Vector2(new_zoom, new_zoom)
	var world_after := screen_to_world(screen_point)
	position += world_before - world_after
	clamp_to_bounds()


func screen_to_world(screen_point: Vector2) -> Vector2:
	var view_size := get_viewport_rect().size
	return position + (screen_point - view_size / 2.0) / zoom.x


func clamp_to_bounds() -> void:
	if bounds.size == Vector2.ZERO:
		return
	var half_view := get_viewport_rect().size / 2.0 / zoom.x
	for axis in 2:
		var lo := bounds.position[axis] + half_view[axis]
		var hi := bounds.end[axis] - half_view[axis]
		# View bigger than the map on this axis: centre it.
		position[axis] = (bounds.get_center()[axis] if lo > hi else clampf(position[axis], lo, hi))
