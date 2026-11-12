extends Node2D
## Battle scene root. Milestone 1: an empty battlefield driven by the fixed-tick
## BattleClock. Units, orders and pause controls arrive in Milestones 2–3.

@onready var _info_label: Label = %InfoLabel

var clock := BattleClock.new()


func _ready() -> void:
	EventBus.battle_started.emit(GameState.pending_battle_id)


func _process(delta: float) -> void:
	var ticks := clock.advance(delta)
	for i in ticks:
		_sim_tick()
	_info_label.text = "Battle: %s   |   t = %.1f s   (tick %d)\nEsc — back to main menu" % [
		_battle_name(), clock.elapsed_seconds(), clock.tick_count
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.battle_ended.emit(GameState.pending_battle_id, &"abandoned")
		GameState.go_to_main_menu()


## One fixed simulation step. Battle sim systems will be stepped from here.
func _sim_tick() -> void:
	pass


func _battle_name() -> String:
	if GameState.pending_battle_id == &"":
		return "Sandbox (empty)"
	return String(GameState.pending_battle_id)
