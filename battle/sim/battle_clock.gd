class_name BattleClock
extends RefCounted
## Fixed-tick battle clock (pure logic, no nodes).
##
## Converts variable frame time into a whole number of fixed simulation ticks
## (PLAN.md section 10: 10–20 ticks/sec, pause stops ticks). The battle scene
## feeds it frame deltas; the sim steps once per returned tick.

const DEFAULT_TICK_RATE := 20

## Simulation ticks per second of battle time.
var tick_rate: int = DEFAULT_TICK_RATE
## Multiplier on real time (game speed controls, Milestone 3).
var speed: float = 1.0
var paused: bool = false
## Total ticks simulated so far.
var tick_count: int = 0

var _accumulator: float = 0.0


func _init(rate: int = DEFAULT_TICK_RATE) -> void:
	assert(rate > 0, "tick rate must be positive")
	tick_rate = rate


## Seconds of battle time per tick.
func tick_length() -> float:
	return 1.0 / tick_rate


## Elapsed battle time in seconds.
func elapsed_seconds() -> float:
	return tick_count * tick_length()


## How far (0..1) real time has progressed into the next tick. Use it to
## interpolate rendering between previous and current sim positions.
func interpolation_alpha() -> float:
	return clampf(_accumulator / tick_length(), 0.0, 1.0)


## Feed [param delta] real seconds; returns how many ticks the sim should run.
func advance(delta: float) -> int:
	if paused or delta <= 0.0:
		return 0
	_accumulator += delta * speed
	# Small epsilon so float error (e.g. 0.5 / 0.05 = 9.999...) doesn't drop a tick.
	var ticks := int(floor(_accumulator / tick_length() + 1e-6))
	_accumulator = maxf(_accumulator - ticks * tick_length(), 0.0)
	tick_count += ticks
	return ticks
