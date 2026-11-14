extends GutTest


func test_only_strongest_slow_applies_then_weaker_slow_resumes() -> void:
	var effects := StatusEffects.new()
	effects.apply(&"slow", 0, 120, 0.2, &"weak")
	effects.apply(&"slow", 0, 60, 0.6, &"strong")
	assert_almost_eq(effects.move_multiplier(), 0.4, 0.00001)
	effects.advance(60)
	assert_almost_eq(effects.move_multiplier(), 0.8, 0.00001)
	effects.advance(120)
	assert_eq(effects.move_multiplier(), 1.0)


func test_root_and_stun_keep_longest_remaining_duration() -> void:
	for kind in [&"root", &"stun"]:
		var effects := StatusEffects.new()
		effects.apply(kind, 0, 120)
		effects.apply(kind, 10, 30)
		effects.advance(119)
		assert_true(effects.has(kind))
		effects.advance(120)
		assert_false(effects.has(kind))


func test_speed_buffs_add_and_strongest_slow_multiplies() -> void:
	var effects := StatusEffects.new()
	effects.apply(&"speed_buff", 0, 60, 0.2, &"one")
	effects.apply(&"speed_buff", 0, 60, 0.3, &"two")
	effects.apply(&"slow", 0, 60, 0.4)
	assert_almost_eq(effects.move_multiplier(), 0.9, 0.00001)


func test_cleanse_removes_cc_but_keeps_burn_and_buffs() -> void:
	var effects := StatusEffects.new()
	for kind in [&"slow", &"root", &"stun", &"burn", &"speed_buff"]:
		effects.apply(kind, 0, 150, 0.5)
	var removed := effects.cleanse()
	assert_eq(removed.size(), 3)
	assert_false(effects.has(&"slow"))
	assert_false(effects.has(&"root"))
	assert_false(effects.has(&"stun"))
	assert_true(effects.has(&"burn"))
	assert_true(effects.has(&"speed_buff"))


func test_burn_has_five_exact_half_second_pulses_including_expiry_tick() -> void:
	var effects := StatusEffects.new()
	effects.apply(&"burn", 0, 150, 24.0, &"edge", 7)
	var pulses := effects.advance(149)
	assert_eq(pulses.size(), 4)
	for i in range(4):
		assert_eq(pulses[i].tick, (i + 1) * 30)
		assert_eq(pulses[i].amount, 24.0)
		assert_eq(pulses[i].source_id, 7)
	var last := effects.advance(150)
	assert_eq(last.size(), 2)
	assert_eq(last[0].tick, 150)
	assert_eq(last[1].event, &"status_expired")
	assert_false(effects.has(&"burn"))


func test_burn_reapplication_refreshes_duration_without_delaying_next_pulse() -> void:
	var effects := StatusEffects.new()
	effects.apply(&"burn", 0, 150, 24.0)
	effects.advance(30)
	effects.apply(&"burn", 45, 150, 24.0)
	var next := effects.advance(60)
	assert_eq(next.size(), 1)
	assert_eq(next[0].tick, 60)
	effects.advance(194)
	assert_true(effects.has(&"burn"))
	effects.advance(195)
	assert_false(effects.has(&"burn"))
