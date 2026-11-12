class_name GameRuleset
extends Resource
## Base ruleset. Anything that differs between game variants (historical mode
## vs. a future alternate/sandbox mode) is asked of the active ruleset instead
## of being hard-coded. See PLAN.md section 8 ("Ruleset abstraction").
##
## Dates are ISO strings ("YYYY-MM-DD"); they compare correctly as strings.

@export var id: StringName = &"base"
@export var display_name: String = "Base"


## Whether battles must happen on their historical dates.
func uses_historical_dates() -> bool:
	return false


## Whether a piece of equipment introduced on [param intro_date] may be
## produced / fielded on [param current_date].
func is_equipment_available(_intro_date: String, _current_date: String) -> bool:
	return true
