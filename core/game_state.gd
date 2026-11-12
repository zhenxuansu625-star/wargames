extends Node
## Top-level game state and scene flow (autoload: GameState).
##
## Owns the small amount of global state that isn't campaign- or economy-
## specific, plus helpers to move between the main screens.

const MAIN_MENU_SCENE := "res://menus/main_menu.tscn"
const BATTLE_SCENE := "res://battle/battle.tscn"

## Bumped when the save format changes incompatibly.
const SAVE_VERSION := 1

## Current in-game date (ISO "YYYY-MM-DD"). Default: D-Day.
var current_date: String = "1944-06-06"
## Battle to load when entering the battle scene. Empty = sandbox/test battle.
var pending_battle_id: StringName = &""


func reset() -> void:
	current_date = "1944-06-06"
	pending_battle_id = &""


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


func start_battle(battle_id: StringName = &"") -> void:
	pending_battle_id = battle_id
	_change_scene(BATTLE_SCENE)


func to_dict() -> Dictionary:
	return {
		"current_date": current_date,
		"ruleset": String(Ruleset.active.id),
	}


func from_dict(data: Dictionary) -> void:
	current_date = data.get("current_date", current_date)
	var ruleset_id := StringName(data.get("ruleset", String(Ruleset.active.id)))
	Ruleset.set_active(ruleset_id)


func _change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)" % [path, err])
		return
	EventBus.scene_changed.emit(path)
