extends Node
## Holds the active GameRuleset (autoload: Ruleset).
##
## Game code calls e.g. `Ruleset.active.is_equipment_available(...)`. Only
## historical mode exists in v1; a second variant is added by writing another
## GameRuleset subclass and registering it here.

var active: GameRuleset = HistoricalRuleset.new()

var _registry: Dictionary[StringName, GameRuleset] = {}


func _init() -> void:
	register(active)


func register(ruleset: GameRuleset) -> void:
	_registry[ruleset.id] = ruleset


func set_active(ruleset_id: StringName) -> bool:
	if not _registry.has(ruleset_id):
		push_error("Unknown ruleset: %s" % ruleset_id)
		return false
	active = _registry[ruleset_id]
	return true


func available_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_registry.keys())
	return ids
