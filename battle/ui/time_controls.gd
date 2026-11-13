class_name TimeControls
extends PanelContainer
## Top-right widget: pause/resume button, slower/faster buttons and the
## current speed. Emits requests; the battle scene owns the clock and calls
## show_state() back.

signal pause_pressed
signal speed_step_requested(direction: int)

var _pause_button: Button
var _slower_button: Button
var _faster_button: Button
var _speed_label: Label


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	_pause_button = _make_button("Pause", "Pause / resume (Space)")
	_pause_button.custom_minimum_size.x = 76
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	row.add_child(_pause_button)

	_slower_button = _make_button("-", "Slower (-)")
	_slower_button.pressed.connect(func() -> void: speed_step_requested.emit(-1))
	row.add_child(_slower_button)

	_speed_label = Label.new()
	_speed_label.custom_minimum_size.x = 52
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_speed_label)

	_faster_button = _make_button("+", "Faster (+)")
	_faster_button.pressed.connect(func() -> void: speed_step_requested.emit(1))
	row.add_child(_faster_button)

	show_state(false, 1.0)


func show_state(paused: bool, speed: float) -> void:
	_pause_button.text = "Resume" if paused else "Pause"
	_speed_label.text = format_speed(speed)


static func format_speed(speed: float) -> String:
	# 0.25x, 0.5x, 1x, 2x...
	return ("%.2f" % speed).rstrip("0").rstrip(".") + "x"


func _make_button(text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size.x = 32
	# No keyboard focus, so Space never "clicks" a button instead of pausing.
	button.focus_mode = Control.FOCUS_NONE
	return button
