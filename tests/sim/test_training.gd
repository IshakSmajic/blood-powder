extends GutTest

const Arena = preload("res://world/arena.tscn")
var arena: Node3D
var tick: int = 0


func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = Arena.instantiate()
	add_child_autofree(arena)
	SimClock.state.set_paused(true)
	for i in range(3): await get_tree().physics_frame
	tick = 0


func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()


func step() -> void:
	await get_tree().physics_frame
	tick += 1
	SimClock.state.tick = tick
	arena.simulate_tick(tick)


func setting(field: StringName, value: Variant) -> void:
	DebugConfig.set_override(arena.training_settings.resource_path, field, value)


func test_default_infinite_dummy_survives_lethal_damage_and_tracks_dps() -> void:
	var dummy: CombatUnit = arena.units[1]
	assert_true(dummy.training_infinite)
	dummy.receive_damage(6000.0, 10, 0)
	assert_true(dummy.alive())
	assert_eq(dummy.health, 2000.0)
	assert_eq(dummy.training_damage, 6000.0)
	assert_eq(dummy.training_dps(69), 6000.0)
	dummy.apply_status(&"burn", 10, 150, 24.0)
	dummy.cleanse()
	assert_true(dummy.statuses.has(&"burn"))
	arena.queue_training_action(&"reset_damage")
	assert_eq(dummy.training_damage, 6000.0)
	await step()
	assert_eq(dummy.training_damage, 0.0)
	assert_eq(dummy.training_dps(1), 0.0)


func test_count_settings_apply_next_tick_keep_shared_target_array_and_selection_safe() -> void:
	var dummy_resource: UnitStats = arena.units[1].stats
	setting(&"dummy_count", 5)
	setting(&"dummy_armor", 100.0)
	setting(&"dummy_health", 10000.0)
	setting(&"elite", true)
	assert_eq(arena.units.size(), 4)
	await step()
	assert_eq(arena.units.size(), 6)
	assert_eq(arena.captain.kegs.units.size(), 6)
	for i in range(1, 6):
		var dummy: CombatUnit = arena.units[i]
		assert_eq(dummy.stat(&"armor"), 100.0)
		assert_eq(dummy.health, 10000.0)
		assert_true(dummy.counts_as_elite)
		assert_eq(dummy.position.x, (i - 3) * 3.0)
	assert_eq(dummy_resource.armor, 50.0)
	assert_eq(dummy_resource.max_health, 2000.0)
	arena.selected = arena.units[5]
	setting(&"dummy_count", 1)
	await step()
	assert_eq(arena.units.size(), 2)
	assert_same(arena.selected, arena.player)
	assert_eq(arena.units[1].position.x, 0.0)
	assert_eq(arena.captain.kegs.units.size(), 2)


func test_finite_health_death_reset_and_default_restore() -> void:
	setting(&"infinite_health", false)
	setting(&"dummy_health", 10000.0)
	await step()
	var dummy: CombatUnit = arena.units[1]
	dummy.receive_damage(20000.0, 1, 0)
	assert_false(dummy.alive())
	arena.reset_arena()
	assert_eq(dummy.health, 10000.0)
	assert_false(dummy.training_infinite)
	assert_eq(dummy.training_damage, 0.0)
	DebugConfig.clear_overrides()
	await step()
	assert_eq(arena.units.size(), 4)
	assert_true(dummy.training_infinite)
	assert_eq(dummy.health, 2000.0)


func test_training_elite_flag_uses_keg_bonus_and_infinite_readout() -> void:
	setting(&"elite", true)
	await step()
	var dummy: CombatUnit = arena.units[1]
	var manager: KegManager = arena.captain.kegs
	var keg := manager.reserve(dummy.position, 1)
	manager.materialize(keg.id, 1)
	keg.health = 1
	manager.hit(keg.id, 1, {"raw": 100.0, "crit": false, "source": 0})
	assert_almost_eq(dummy.training_damage, (100.0 + 135.0) / 1.3, 0.0001)
	assert_eq(dummy.health, 2000.0)
	assert_true(dummy.statuses.has(&"slow"))


func test_restore_player_and_decay_tier_remain_tick_based() -> void:
	arena.player.health = 500.0
	arena.queue_training_action(&"restore_player")
	assert_eq(arena.player.health, 500.0)
	await step()
	assert_eq(arena.player.health, 1200.0)
	var manager: KegManager = arena.captain.kegs
	var first := manager.reserve(Vector3.ZERO, 1)
	manager.materialize(first.id, 1)
	DebugConfig.set_override(manager.data.resource_path, &"decay_interval", 0.5)
	var second := manager.reserve(Vector3(5, 0, 0), 1)
	manager.materialize(second.id, 1)
	assert_eq(first.decay_ticks, 60)
	assert_eq(second.decay_ticks, 30)


func advance(until: int) -> void:
	while tick < until: await step()


func test_strafe_reverses_within_three_meter_span_and_respects_root() -> void:
	setting(&"dummy_count", 1)
	setting(&"behavior", 1)
	await advance(20)
	var dummy: CombatUnit = arena.units[1]
	assert_gt(dummy.position.x, 0.2)
	dummy.apply_status(&"root", tick, 30)
	var rooted := dummy.position
	await advance(49)
	assert_eq(dummy.position, rooted)
	var maximum := dummy.position.x
	var minimum := dummy.position.x
	await advance(80)
	while tick < 160:
		await step()
		maximum = maxf(maximum, dummy.position.x)
		minimum = minf(minimum, dummy.position.x)
	assert_gt(maximum, 1.0)
	assert_lt(minimum, -1.0)
	assert_lte(maximum, 1.6)
	assert_gte(minimum, -1.6)
	arena.reset_arena()
	assert_eq(dummy.position, dummy.spawn_point)


func test_chase_uses_slow_speed_and_does_not_attack_player() -> void:
	setting(&"dummy_count", 1)
	setting(&"behavior", 2)
	await step()
	var dummy: CombatUnit = arena.units[1]
	arena.player.position = Vector3(0, 0, -3)
	var initial := dummy.position.distance_to(arena.player.position)
	await advance(61)
	assert_lt(dummy.position.distance_to(arena.player.position), initial - 1.0)
	assert_eq(dummy.stat(&"move_speed"), 1.5)
	assert_eq(arena.player.health, 1200.0)
	setting(&"behavior", 0)
	await step()
	var stationary := dummy.position
	await advance(85)
	assert_eq(dummy.position, stationary)


func test_enemy_keg_toggle_defaults_off_then_destroys_without_explosion() -> void:
	setting(&"dummy_count", 1)
	await step()
	var dummy: CombatUnit = arena.units[1]
	var manager: KegManager = arena.captain.kegs
	var keg := manager.reserve(dummy.position + Vector3.RIGHT, tick)
	manager.materialize(keg.id, tick)
	keg.health = 1
	await advance(25)
	assert_true(manager.graph.nodes.has(keg.id))
	setting(&"enemies_attack_kegs", true)
	await advance(45)
	assert_false(manager.graph.nodes.has(keg.id))
	var destroyed: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "keg_destroyed")
	var blasts: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "keg_exploded")
	assert_eq(destroyed.size(), 1)
	assert_eq(blasts.size(), 0)
	assert_eq(dummy.training_damage, 0.0)
