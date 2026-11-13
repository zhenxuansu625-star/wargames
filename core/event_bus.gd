extends Node
## Global signal hub (autoload: EventBus).
##
## Systems emit here instead of holding references to each other, so the battle
## sim, economy sim, UI and campaign layer stay decoupled. Signals are declared
## up front per PLAN.md section 10; most are not emitted until later milestones.
##
## Convention: unit / objective / equipment identifiers are StringName ids, not
## node references, so sim code (which has no nodes) can emit them too.

# --- Flow / scenes ---------------------------------------------------------
@warning_ignore("unused_signal")
signal scene_changed(scene_path: String)
@warning_ignore("unused_signal")
signal battle_started(battle_id: StringName)
@warning_ignore("unused_signal")
signal battle_ended(battle_id: StringName, result: StringName)

# --- Battle time -----------------------------------------------------------
@warning_ignore("unused_signal")
signal battle_paused_changed(paused: bool)
@warning_ignore("unused_signal")
signal battle_speed_changed(speed: float)

# --- Battle events ---------------------------------------------------------
@warning_ignore("unused_signal")
signal unit_killed(unit_id: StringName, killer_id: StringName)
@warning_ignore("unused_signal")
signal objective_changed(objective_id: StringName, owner_side: StringName)
@warning_ignore("unused_signal")
signal morale_broken(unit_id: StringName)
@warning_ignore("unused_signal")
signal reinforcements_called(unit_ids: Array[StringName], arrival_delay_s: float)
@warning_ignore("unused_signal")
signal reinforcements_arrived(unit_ids: Array[StringName], entry_point_id: StringName)
@warning_ignore("unused_signal")
signal retreat_ordered(unit_ids: Array[StringName], full_force: bool)
@warning_ignore("unused_signal")
signal unit_escaped(unit_id: StringName, men_saved: int)

# --- Economy ---------------------------------------------------------------
@warning_ignore("unused_signal")
signal equipment_produced(equipment_id: StringName, amount: int)
@warning_ignore("unused_signal")
signal day_advanced(date: String)

# --- Persistence -----------------------------------------------------------
@warning_ignore("unused_signal")
signal game_saved(slot: String)
@warning_ignore("unused_signal")
signal game_loaded(slot: String)
