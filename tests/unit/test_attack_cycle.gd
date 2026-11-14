extends GutTest


func test_captain_windup_and_attack_period() -> void:
	var cycle := AttackCycle.new()
	assert_true(cycle.start(1, 0.658, 0.164))
	assert_eq(cycle.hit_tick, 16)
	assert_eq(cycle.ready_tick, 92)
	assert_false(cycle.take_hit(15))
	assert_true(cycle.take_hit(16))
	assert_false(cycle.take_hit(16), "A hit cannot be consumed twice")
	assert_false(cycle.start(91, 0.658, 0.164))
	assert_true(cycle.start(92, 0.658, 0.164))


func test_cancel_before_hit_refunds_but_backswing_does_not() -> void:
	var cycle := AttackCycle.new()
	cycle.start(10, 0.658, 0.164)
	assert_true(cycle.cancel(24))
	assert_true(cycle.start(24, 0.658, 0.164))
	assert_true(cycle.take_hit(39))
	assert_false(cycle.cancel(40))
	assert_eq(cycle.ready_tick, 115)


func test_command_on_hit_tick_cannot_refund_committed_hit() -> void:
	var cycle := AttackCycle.new()
	cycle.start(0, 0.658, 0.164)
	assert_false(cycle.cancel(15))
	assert_true(cycle.take_hit(15))
	assert_eq(cycle.ready_tick, 91)


func test_damage_resists_penetration_and_negative_armor() -> void:
	assert_almost_eq(DamageResolver.resolve(100.0, 50.0), 66.6666667, 0.00001)
	assert_almost_eq(DamageResolver.resolve(100.0, -50.0), 133.3333333, 0.00001)
	assert_almost_eq(DamageResolver.resolve(100.0, 100.0, 0.4), 62.5, 0.00001)
	assert_eq(DamageResolver.resolve(-100.0, 0.0), 0.0)
