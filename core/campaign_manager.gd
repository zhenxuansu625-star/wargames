extends Node
## Campaign progression (autoload: CampaignManager).
##
## Milestone 1 stub: loads a campaign definition from data/campaigns/ and
## tracks which battles are done. Regions, roster, branching and time passing
## arrive in Milestone 16+.

const CAMPAIGN_DATA_DIR := "res://data/campaigns/"

var campaign_id: StringName = &""
## Raw campaign definition as loaded from JSON.
var campaign_data: Dictionary = {}
var completed_battles: Array[StringName] = []


func has_campaign() -> bool:
	return campaign_id != &""


## Loads data/campaigns/<id>.json. Returns false if missing or invalid.
func load_campaign(id: StringName) -> bool:
	var path := CAMPAIGN_DATA_DIR + String(id) + ".json"
	if not FileAccess.file_exists(path):
		push_error("Campaign data not found: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Campaign data is not a JSON object: %s" % path)
		return false
	campaign_id = id
	campaign_data = parsed
	completed_battles.clear()
	return true


func reset() -> void:
	campaign_id = &""
	campaign_data = {}
	completed_battles.clear()


func to_dict() -> Dictionary:
	var done: Array[String] = []
	for b in completed_battles:
		done.append(String(b))
	return {
		"campaign_id": String(campaign_id),
		"completed_battles": done,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	var id := StringName(data.get("campaign_id", ""))
	if id != &"":
		load_campaign(id)
	for b: Variant in data.get("completed_battles", []):
		completed_battles.append(StringName(b))
