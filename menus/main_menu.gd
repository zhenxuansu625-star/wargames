extends Control
## Main menu. Milestone 1: start an empty battle or quit.

@onready var _battle_button: Button = %QuickBattleButton
@onready var _campaign_button: Button = %CampaignButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_battle_button.pressed.connect(_on_quick_battle_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	# Campaign layer arrives in Milestone 16.
	_campaign_button.disabled = true
	# Quitting makes no sense in a browser build.
	_quit_button.visible = not OS.has_feature("web")
	_battle_button.grab_focus()


func _on_quick_battle_pressed() -> void:
	GameState.start_battle()


func _on_quit_pressed() -> void:
	get_tree().quit()
