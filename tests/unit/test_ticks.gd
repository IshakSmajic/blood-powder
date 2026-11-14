extends GutTest

const State = preload("res://core/simulation/tick_state.gd")


func test_reference_durations_round_to_whole_ticks() -> void:
	for sample in [[0.25, 15], [0.33, 20], [0.35, 21], [0.5, 30], [1.0, 60], [10.0, 600]]:
		assert_eq(State.seconds_to_ticks(sample[0]), sample[1], str(sample[0]) + " seconds")


func test_normal_speed_advances_exactly_once_per_physics_frame() -> void:
	var clock := State.new()
	for frame in range(600):
		assert_true(clock.advance_physics_frame())
	assert_eq(clock.tick, 600)


func test_slow_motion_preserves_integer_ticks() -> void:
	for speed in range(1, 11):
		var clock := State.new()
		clock.set_speed(speed)
		for frame in range(600):
			clock.advance_physics_frame()
		assert_eq(clock.tick, 60 * speed, "Speed in tenths: " + str(speed))


func test_pause_and_single_step_do_not_leak_ticks() -> void:
	var clock := State.new()
	clock.set_paused(true)
	for frame in range(120):
		clock.advance_physics_frame()
	assert_eq(clock.tick, 0)
	clock.request_step()
	assert_true(clock.advance_physics_frame())
	assert_eq(clock.tick, 1)
	assert_false(clock.advance_physics_frame())
	clock.set_paused(false)
	assert_true(clock.advance_physics_frame())
	assert_eq(clock.tick, 2)


func test_step_requested_while_running_is_not_deferred_until_pause() -> void:
	var clock := State.new()
	clock.request_step()
	clock.set_paused(true)
	assert_false(clock.advance_physics_frame())


func test_reset_restores_pacing_and_seeded_random_sequence() -> void:
	var clock := State.new()
	clock.reset(42)
	var expected: Array[int] = []
	for draw in range(20):
		expected.append(clock.rng.randi())
	clock.set_speed(3)
	clock.advance_physics_frame()
	clock.set_paused(true)
	clock.request_step()
	clock.reset(42)
	assert_eq(clock.tick, 0)
	assert_eq(clock.speed_tenths, 10)
	assert_false(clock.paused)
	for value in expected:
		assert_eq(clock.rng.randi(), value)
	assert_true(clock.advance_physics_frame())
	assert_eq(clock.tick, 1)
