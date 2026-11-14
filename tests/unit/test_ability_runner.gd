extends GutTest


func test_cast_and_cooldown_deadlines_start_on_cast_start() -> void:
	var runner := AbilityRunner.new()
	runner.data = preload("res://data/abilities/training_pulse.tres")
	assert_eq(runner.start(1), "")
	assert_eq(runner.completion_tick, 16)
	assert_eq(runner.ready_tick, 181)
	assert_false(runner.take_completion(15))
	assert_true(runner.take_completion(16))
	assert_false(runner.take_completion(16))
	assert_eq(runner.start(180), "On cooldown")
	assert_eq(runner.ready_tick, 181)
	assert_eq(runner.start(181), "")


func test_interrupt_keeps_cooldown_and_reset_restores_readiness() -> void:
	var runner := AbilityRunner.new()
	runner.data = preload("res://data/abilities/training_pulse.tres")
	runner.start(1)
	runner.interrupt()
	assert_false(runner.take_completion(16))
	assert_eq(runner.ready_tick, 181)
	assert_eq(runner.start(16), "On cooldown")
	runner.reset()
	assert_eq(runner.start(17), "")
