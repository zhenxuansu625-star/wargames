class_name HistoricalRuleset
extends GameRuleset
## v1 ruleset: historical dates, orders of battle and equipment availability.


func _init() -> void:
	id = &"historical"
	display_name = "Historical"


func uses_historical_dates() -> bool:
	return true


func is_equipment_available(intro_date: String, current_date: String) -> bool:
	# Empty intro date means "always available" (e.g. generic rifles).
	if intro_date.is_empty():
		return true
	return intro_date <= current_date
