class_name MoveMarker
extends Node2D
## Short-lived ring shown where a move order was given.

const LIFETIME := 0.6
const COLOR := Color(0.95, 0.95, 0.55)

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var c := COLOR
	c.a = 1.0 - t
	draw_arc(Vector2.ZERO, lerpf(6.0, 22.0, t), 0.0, TAU, 24, c, 2.0)
