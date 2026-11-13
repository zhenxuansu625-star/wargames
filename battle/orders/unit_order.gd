class_name UnitOrder
extends RefCounted
## Base class for an order a unit carries out (move, and later attack-move,
## attack, garrison, abilities...). Pure logic: orders act on SimUnit state
## through the BattleSim, never on nodes.
##
## Lifecycle, driven by OrderQueue:
##   start()  once, when the order becomes the unit's current order
##   update() every sim tick until it returns true (finished)
##   cancel() if it is replaced or cleared before finishing

## Short id for UI and debugging, e.g. &"move".
var kind: StringName = &"order"


func start(_unit: SimUnit, _sim: BattleSim) -> void:
	pass


## Advances the order by [param dt] seconds. Returns true when finished.
func update(_unit: SimUnit, _sim: BattleSim, _dt: float) -> bool:
	return true


func cancel(_unit: SimUnit) -> void:
	pass


## Where the unit will be after this order, given it starts at [param from].
## Used to plan queued orders and draw the queue.
func planned_end_position(from: Vector2) -> Vector2:
	return from
