extends Node
## JSON save/load of the full game state (autoload: SaveSystem).
##
## Each top-level system contributes a section via to_dict()/from_dict().
## Economy and roster sections are added in later milestones.

const SAVE_DIR := "user://saves/"


func save_game(slot: String) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": GameState.SAVE_VERSION,
		"game_state": GameState.to_dict(),
		"campaign": CampaignManager.to_dict(),
	}
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventBus.game_saved.emit(slot)
	return OK


func load_game(slot: String) -> Error:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != GameState.SAVE_VERSION:
		push_error("Unsupported save version in %s" % path)
		return ERR_INVALID_DATA
	GameState.from_dict(data.get("game_state", {}))
	CampaignManager.from_dict(data.get("campaign", {}))
	EventBus.game_loaded.emit(slot)
	return OK


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func _slot_path(slot: String) -> String:
	return SAVE_DIR + slot.validate_filename() + ".json"
