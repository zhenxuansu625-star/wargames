extends GdUnitTestSuite
## Example test suite: the fixed-tick battle clock (pure sim logic).


func test_converts_real_time_into_whole_ticks() -> void:
	var clock := BattleClock.new(20)
	assert_int(clock.advance(0.5)).is_equal(10)
	assert_int(clock.tick_count).is_equal(10)
	assert_float(clock.elapsed_seconds()).is_equal_approx(0.5, 0.0001)


func test_carries_leftover_time_between_frames() -> void:
	var clock := BattleClock.new(10)
	# 0.06 s is less than one 0.1 s tick...
	assert_int(clock.advance(0.06)).is_equal(0)
	# ...but the remainder carries over into the next frame.
	assert_int(clock.advance(0.06)).is_equal(1)


func test_paused_clock_does_not_tick() -> void:
	var clock := BattleClock.new(20)
	clock.paused = true
	assert_int(clock.advance(1.0)).is_equal(0)
	assert_int(clock.tick_count).is_equal(0)


func test_speed_multiplier_scales_ticks() -> void:
	var clock := BattleClock.new(20)
	clock.speed = 2.0
	assert_int(clock.advance(0.5)).is_equal(20)
