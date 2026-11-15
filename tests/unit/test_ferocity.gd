extends GutTest


func test_leap_stack_flag_and_reset() -> void:
	var meter := Ferocity.new()
	meter.gain(&"leap", 1, true)
	meter.gain(&"leap", 2, true)
	assert_eq(meter.stacks, 1)
	meter.gain(&"W", 3)
	meter.gain(&"E", 4)
	meter.gain(&"Q", 5)
	assert_eq(meter.stacks, 4)
	assert_false(meter.consume(&"Q", 10))
	assert_true(meter.consume(&"Q", 11))
	assert_eq(meter.stacks, 0)
	assert_false(meter.leap_stack_present)
	assert_eq(meter.base_lock[&"Q"], 17)


func test_decay_exact_600_ticks_and_howl_lockout() -> void:
	var meter := Ferocity.new()
	meter.gain(&"W", 10)
	meter.advance(609)
	assert_eq(meter.stacks, 1)
	meter.advance(610)
	assert_eq(meter.stacks, 0)
	meter.stacks = 4
	assert_true(meter.consume(&"W", 700))
	assert_eq(meter.base_lock[&"W"], 715)
