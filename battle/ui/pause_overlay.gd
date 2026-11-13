class_name PauseOverlay
extends Control
## Shown while the battle is paused: a coloured frame round the screen and a
## banner. Doesn't block the mouse, so orders can still be given.

const FRAME_COLOR := Color(0.95, 0.80, 0.30, 0.85)
const FRAME_WIDTH := 6.0
const BANNER_TEXT := "PAUSED — give orders, Space to resume"
const BANNER_SIZE := 20


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	resized.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size).grow(-FRAME_WIDTH / 2.0)
	draw_rect(rect, FRAME_COLOR, false, FRAME_WIDTH)

	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(BANNER_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_SIZE)
	var banner := Rect2(Vector2((size.x - text_size.x) / 2.0 - 16.0, size.y - 64.0),
			Vector2(text_size.x + 32.0, text_size.y + 12.0))
	draw_rect(banner, Color(0, 0, 0, 0.6))
	draw_string(font, banner.position + Vector2(16.0, 6.0 + font.get_ascent(BANNER_SIZE)),
			BANNER_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_SIZE, FRAME_COLOR)
