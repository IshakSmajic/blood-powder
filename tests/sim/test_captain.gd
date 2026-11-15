extends GutTest

const Arena = preload("res://world/arena.tscn")
var arena: Node3D
var player: CombatUnit
var dummy: CombatUnit
var current_tick: int = 0


func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = Arena.instantiate()
	arena.training_enabled = false # Combat regressions retain finite-health targets.
	add_child_autofree(arena)
	SimClock.state.set_paused(true)
	for i in range(3): await get_tree().physics_frame
	player = arena.player
	dummy = arena.units[1]
	player.position = Vector3(0, 0, 8)
	dummy.position = Vector3(6, 0, 8)
	SimClock.state.tick = 0
	current_tick = 0
	DebugConfig.set_override(player.stats.resource_path, &"crit_chance", 0.0)


func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()


func advance(tick: int) -> void:
	while current_tick < tick:
		await get_tree().physics_frame
		current_tick += 1
		SimClock.state.tick = current_tick
		arena.simulate_tick(current_tick)


func queue_e(point: Vector3) -> void:
	var command := UnitCommand.create(UnitCommand.Kind.CAST, point)
	command.slot = &"E"
	player.queue_command(command, current_tick)


func queue_q(target: Node3D) -> void:
	player.queue_command(UnitCommand.create(UnitCommand.Kind.CAST, Vector3.ZERO, target), current_tick)


func test_placement_cast_pending_ghost_charges_and_decay() -> void:
	queue_e(Vector3(2, 0, 8))
	await advance(1)
	assert_eq(arena.captain.charges.available, 2)
	assert_eq(arena.captain.e.ready_tick, 31)
	var state: KegState = arena.captain.kegs.graph.nodes[1]
	assert_true(state.pending)
	await advance(15)
	assert_true(state.pending)
	await advance(16)
	assert_false(state.pending)
	assert_eq(state.placed_tick, 16)
	await advance(75)
	assert_eq(state.health, 3)
	await advance(76)
	assert_eq(state.health, 2)
	await advance(136)
	assert_eq(state.health, 1)


func test_flintlock_cast_and_homing_projectile_hit_on_expected_tick() -> void:
	queue_q(dummy)
	await advance(1)
	assert_gt(player.avatar.global_basis.z.normalized().dot(Vector3.RIGHT), 0.99)
	await advance(16)
	assert_eq(dummy.health, 2000.0)
	assert_eq(arena.captain.projectiles.size(), 1)
	assert_eq(player.ability.ready_tick, 271)
	await advance(29)
	assert_eq(dummy.health, 2000.0)
	await advance(30)
	assert_almost_eq(dummy.health, 2000.0 - 110.0 / 1.5, 0.0001)
	assert_eq(arena.captain.projectiles.size(), 0)


func test_one_part_combo_sees_pending_keg_before_it_materializes() -> void:
	queue_e(Vector3(6, 0, 8))
	await advance(136)
	dummy.position = Vector3(7.5, 0, 8)
	var root: PowderKeg = arena.captain.kegs.views[1]
	queue_q(root)
	await advance(137)
	queue_e(Vector3(9, 0, 8))
	await advance(152)
	var pending: KegState = arena.captain.kegs.graph.nodes[2]
	assert_true(pending.pending)
	assert_eq(pending.materialize_tick, 167)
	await advance(166)
	assert_false(arena.captain.kegs.graph.nodes.has(1))
	assert_true(pending.pending)
	assert_eq(pending.scheduled_tick, 186)
	await advance(167)
	assert_false(pending.pending)
	await advance(186)
	assert_eq(arena.captain.kegs.graph.nodes.size(), 0)
	assert_almost_eq(dummy.health, 2000.0 - 110.0 / 1.3, 0.0001)
	var blasts: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "keg_exploded")
	assert_eq(blasts.size(), 2)
	assert_eq([blasts[0].tick, blasts[1].tick], [166, 186])


func test_new_move_cancels_out_of_range_pending_flintlock() -> void:
	dummy.position = Vector3(10, 0, 8)
	queue_q(dummy)
	await advance(1)
	assert_eq(player.state, "Approaching cast")
	assert_eq(player.ability.ready_tick, 0)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(0, 0, 10)), 1)
	await advance(60)
	assert_eq(player.ability.ready_tick, 0)
	assert_eq(dummy.health, 2000.0)


func test_invalid_wall_placement_and_spacing_do_not_spend_charges() -> void:
	queue_e(Vector3(-7, 0, 4))
	await advance(1)
	assert_eq(arena.captain.charges.available, 3)
	assert_eq(arena.captain.kegs.graph.nodes.size(), 0)
	queue_e(Vector3(2, 0, 8))
	await advance(17)
	assert_eq(arena.captain.charges.available, 2)
	await advance(32)
	queue_e(Vector3(2.5, 0, 8))
	await advance(33)
	assert_eq(arena.captain.charges.available, 2)
	assert_eq(arena.captain.kegs.graph.nodes.size(), 1)


func test_stun_interrupts_pending_placement_without_ghost_or_refund() -> void:
	queue_e(Vector3(2, 0, 8))
	await advance(5)
	player.apply_status(&"stun", 5, 30)
	await advance(16)
	assert_eq(arena.captain.kegs.graph.nodes.size(), 0)
	assert_eq(arena.captain.charges.available, 2)
	assert_eq(arena.captain.e.completion_tick, -1)


func test_reset_clears_scheduled_chains_and_restores_charges() -> void:
	var manager: KegManager = arena.captain.kegs
	var a := manager.reserve(Vector3(0, 0, 5), 0)
	manager.materialize(a.id, 0)
	a.health = 1
	var b := manager.reserve(Vector3(6, 0, 5), 0)
	manager.materialize(b.id, 0)
	manager.hit(a.id, 0, {"raw": 100.0, "crit": false, "source": 0})
	arena.reset_arena()
	assert_eq(manager.graph.nodes.size(), 0)
	assert_eq(arena.captain.charges.available, 3)
	await advance(40)
	assert_eq(manager.graph.nodes.size(), 0)
	assert_eq(arena.combat_log.rows.size(), 0)


func test_basic_attack_detonates_owned_keg_without_changing_attack_period() -> void:
	queue_e(Vector3(1.5, 0, 8))
	await advance(136)
	dummy.position = Vector3(3, 0, 8)
	var keg: PowderKeg = arena.captain.kegs.views[1]
	arena.selected = keg
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, keg), 136)
	await advance(151)
	assert_true(arena.captain.kegs.graph.nodes.has(1))
	await advance(152)
	assert_false(arena.captain.kegs.graph.nodes.has(1))
	assert_eq(player.attack.ready_tick, 228)
	assert_almost_eq(dummy.health, 2000.0 - 70.0 / 1.3, 0.0001)
	await advance(154) # Selected keg is freed; HUD must handle the missing node.


func test_projectile_fizzles_when_its_keg_target_is_removed() -> void:
	var manager: KegManager = arena.captain.kegs
	var state := manager.reserve(Vector3(6, 0, 8), 0)
	manager.materialize(state.id, 0)
	state.health = 1
	queue_q(manager.views[state.id])
	await advance(20)
	manager.hit(state.id, 20, {"raw": 70.0, "crit": false, "source": 0})
	await advance(22)
	assert_eq(arena.captain.projectiles.size(), 0)
	assert_eq(player.ability.ready_tick, 271)


func test_empty_charges_fail_without_creating_another_pending_keg() -> void:
	queue_e(Vector3(0, 0, 6))
	await advance(30)
	queue_e(Vector3(2, 0, 6))
	await advance(60)
	queue_e(Vector3(4, 0, 6))
	await advance(90)
	queue_e(Vector3(6, 0, 6))
	await advance(91)
	assert_eq(arena.captain.charges.available, 0)
	assert_eq(arena.captain.kegs.graph.nodes.size(), 3)
	var failures: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "ability_cast_failed")
	assert_eq(failures.size(), 1)
	assert_eq(failures[0].payload.reason, "No charges")
	assert_eq(failures[0].payload.slot, &"E")


func queue_w() -> void:
	var command := UnitCommand.create(UnitCommand.Kind.CAST)
	command.slot = &"W"
	player.queue_command(command, current_tick)


func test_ration_exact_completion_missing_health_cleanse_and_cooldown() -> void:
	player.health = 600.0
	player.apply_status(&"slow", 0, 120, 0.4)
	player.apply_status(&"root", 0, 120)
	player.apply_status(&"burn", 0, 150, 24.0)
	queue_w()
	await advance(1)
	assert_eq(arena.captain.w.ready_tick, 1081)
	await advance(15)
	assert_eq(player.health, 600.0)
	assert_true(player.statuses.has(&"root"))
	await advance(16)
	assert_almost_eq(player.health, 778.0, 0.0001)
	assert_false(player.statuses.has(&"root"))
	assert_false(player.statuses.has(&"slow"))
	assert_true(player.statuses.has(&"burn"))
	queue_w()
	await advance(17)
	assert_eq(player.health, 778.0)
	var failures: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "ability_cast_failed")
	assert_eq(failures[-1].payload.slot, &"W")
	assert_eq(failures[-1].payload.reason, "On cooldown")
	await advance(30)
	assert_eq(player.health, 754.0)


func test_ration_caps_heal_and_reset_restores_cooldown() -> void:
	player.health = 1190.0
	queue_w()
	await advance(16)
	assert_eq(player.health, 1200.0)
	var heals: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "healing_received")
	assert_eq(heals.size(), 1)
	assert_eq(heals[0].payload.amount, 10.0)
	arena.reset_arena()
	assert_eq(arena.captain.w.ready_tick, 0)
	assert_eq(arena.captain.w.completion_tick, -1)


func test_ration_survives_new_stun_and_cleanses_on_completion() -> void:
	player.health = 600.0
	queue_w()
	await advance(5)
	player.apply_status(&"stun", 5, 60)
	assert_same(player.active_cast, arena.captain.w)
	await advance(15)
	assert_eq(player.health, 600.0)
	assert_true(player.statuses.has(&"stun"))
	await advance(16)
	assert_eq(player.health, 778.0)
	assert_false(player.statuses.has(&"stun"))
	assert_eq(arena.captain.w.ready_tick, 1081)


func test_ration_physical_w_starts_during_stun_and_preserves_buffered_order() -> void:
	player.apply_status(&"stun", 0, 120)
	player.apply_status(&"root", 0, 120)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	InputRouter._unhandled_input(key)
	await advance(1)
	assert_same(player.active_cast, arena.captain.w)
	assert_true(player.statuses.has(&"stun"))
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(0, 0, 11)), 1)
	await advance(15)
	assert_eq(player.position.z, 8.0)
	await advance(18)
	assert_false(player.statuses.has(&"stun"))
	assert_false(player.statuses.has(&"root"))
	assert_gt(player.position.z, 8.0)


func test_stun_still_blocks_flintlock_while_ration_is_on_cooldown() -> void:
	queue_w()
	await advance(16)
	player.apply_status(&"stun", 16, 120)
	queue_w()
	await advance(17)
	assert_eq(player.active_cast, null)
	assert_true(player.statuses.has(&"stun"))
	queue_q(dummy)
	await advance(18)
	assert_eq(player.ability.ready_tick, 0)
	var failures: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "ability_cast_failed")
	assert_eq(failures[-2].payload.reason, "On cooldown")
	assert_eq(failures[-1].payload.reason, "Stunned")


func test_ration_resumes_movement_and_death_cancels_completion() -> void:
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(0, 0, 11)), 0)
	await advance(2)
	queue_w()
	await advance(3)
	var cast_position := player.position
	await advance(17)
	assert_eq(player.position, cast_position)
	await advance(19)
	assert_gt(player.position.z, cast_position.z)
	arena.reset_arena()
	queue_w()
	await advance(20)
	player.receive_damage(5000.0, 20, 1)
	await advance(36)
	assert_eq(player.health, 0.0)
	assert_eq(player.active_cast, null)


func test_physical_w_key_activates_ration_at_full_health() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	assert_true(key.is_action_pressed("ability_w"))
	InputRouter._unhandled_input(key)
	await advance(1)
	assert_same(player.active_cast, arena.captain.w)
	assert_eq(arena.captain.w.ready_tick, 1081)
	await advance(16)
	assert_eq(player.health, 1200.0)
	var completions: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool:
		return row.event == "ability_cast_completed" and row.payload.get("ability") == "ration")
	assert_eq(completions.size(), 1)


func test_searing_edge_melee_burn_exact_pulses_and_speed_expiry() -> void:
	dummy.position = Vector3(2, 0, 8)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	await advance(15)
	assert_false(dummy.statuses.has(&"burn"))
	assert_eq(arena.captain.passive.ready_tick, 0)
	await advance(16)
	assert_eq(arena.captain.passive.ready_tick, 916)
	assert_eq(player.attack.ready_tick, 92)
	assert_eq(player.active_cast, null)
	assert_almost_eq(player.statuses.move_multiplier(), 1.25, 0.0001)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.STOP), 16)
	var after_hit := dummy.health
	await advance(45)
	assert_eq(dummy.health, after_hit)
	for pulse in range(1, 6):
		await advance(16 + 30 * pulse)
		assert_almost_eq(dummy.health, after_hit - 24.0 * pulse, 0.0001)
		if pulse == 4: assert_eq(player.statuses.move_multiplier(), 1.0)
	assert_false(dummy.statuses.has(&"burn"))
	assert_eq(arena.captain.passive.ready_tick, 916)


func test_searing_edge_cancel_and_pistol_do_not_consume_or_apply() -> void:
	dummy.position = Vector3(2, 0, 8)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	await advance(5)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.STOP), 5)
	await advance(16)
	assert_eq(arena.captain.passive.ready_tick, 0)
	assert_false(dummy.statuses.has(&"burn"))
	queue_q(dummy)
	await advance(40)
	assert_lt(dummy.health, 2000.0)
	assert_false(dummy.statuses.has(&"burn"))
	assert_eq(arena.captain.passive.ready_tick, 0)


func test_searing_edge_resets_once_per_chain_and_not_on_child() -> void:
	var manager: KegManager = arena.captain.kegs
	var root := manager.reserve(Vector3(1, 0, 8), 0)
	manager.materialize(root.id, 0)
	root.health = 1
	var child := manager.reserve(Vector3(6, 0, 8), 0)
	manager.materialize(child.id, 0)
	arena.captain.passive.ready_tick = 900
	manager.hit(root.id, 0, {"raw": 70.0, "crit": false, "source": 0})
	assert_eq(arena.captain.passive.ready_tick, 0)
	assert_almost_eq(player.statuses.move_multiplier(), 1.25, 0.0001)
	assert_false(dummy.statuses.has(&"burn"))
	dummy.position = Vector3(2, 0, 8)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	await advance(16)
	assert_eq(arena.captain.passive.ready_tick, 916)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.STOP), 16)
	await advance(20)
	assert_eq(arena.captain.passive.ready_tick, 916)
	var resets: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "searing_edge_reset")
	assert_eq(resets.size(), 1)
	assert_eq(player.statuses.effects["speed_buff:searing_edge"].expires, 136)
	arena.reset_arena()
	assert_eq(arena.captain.passive.ready_tick, 0)
	assert_false(player.statuses.has(&"speed_buff"))
	assert_false(dummy.statuses.has(&"burn"))


func test_searing_edge_rearms_on_exact_cooldown_boundary() -> void:
	arena.captain.basic_hit(dummy, 1)
	assert_eq(arena.captain.passive.ready_tick, 901)
	arena.captain.basic_hit(dummy, 900)
	assert_eq(arena.captain.passive.ready_tick, 901)
	arena.captain.basic_hit(dummy, 901)
	assert_eq(arena.captain.passive.ready_tick, 1801)
	assert_almost_eq(player.statuses.move_multiplier(), 1.25, 0.0001)


func queue_r(point: Vector3) -> void:
	var command := UnitCommand.create(UnitCommand.Kind.CAST, point)
	command.slot = &"R"
	player.queue_command(command, current_tick)


func test_broadside_exact_twelve_waves_slow_and_full_area_duration() -> void:
	queue_r(dummy.position)
	await advance(1)
	assert_same(player.active_cast, arena.captain.r)
	assert_eq(arena.captain.r.ready_tick, 1801)
	await advance(15)
	assert_eq(arena.captain.broadsides.size(), 0)
	await advance(16)
	assert_eq(arena.captain.broadsides.size(), 1)
	var zone: BroadsideZone = arena.captain.broadsides[0]
	assert_eq(zone.expires_tick, 496)
	await advance(45)
	assert_eq(dummy.health, 2000.0)
	await advance(46)
	var per_wave := DamageResolver.resolve(40.0, dummy.stat(&"magic_resist"))
	assert_almost_eq(dummy.health, 2000.0 - per_wave, 0.0001)
	assert_almost_eq(dummy.statuses.move_multiplier(), 0.7, 0.0001)
	await advance(106)
	assert_false(dummy.statuses.has(&"slow"))
	await advance(495)
	assert_eq(arena.captain.broadsides.size(), 1)
	assert_almost_eq(dummy.health, 2000.0 - 12 * per_wave, 0.0001)
	var rows: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "broadside_wave")
	var ticks: Array = rows.map(func(row: Dictionary) -> int: return row.tick)
	assert_eq(ticks, [46, 61, 76, 166, 181, 196, 286, 301, 316, 406, 421, 436])
	await advance(496)
	assert_eq(arena.captain.broadsides.size(), 0)


func test_broadside_area_boundary_targets_and_snapshot() -> void:
	var point := Vector3(0, 0, 8)
	dummy.position = Vector3(6.45, 0, 8)
	var outside: CombatUnit = arena.units[2]
	outside.position = Vector3(6.46, 0, 8)
	queue_r(point)
	await advance(16)
	DebugConfig.set_override(arena.captain.r.data.resource_path, &"damage", 999.0)
	DebugConfig.set_override(arena.captain.r.data.resource_path, &"radius", 30.0)
	await advance(46)
	assert_almost_eq(dummy.health, 2000.0 - DamageResolver.resolve(40.0, dummy.stat(&"magic_resist")), 0.0001)
	assert_eq(outside.health, 2000.0)
	assert_eq(player.health, 1200.0)
	assert_false(dummy.statuses.has(&"burn"))
	assert_eq(arena.captain.passive.ready_tick, 0)
	dummy.position = Vector3(10, 0, 8)
	outside.position = point
	await advance(61)
	assert_almost_eq(outside.health, 2000.0 - DamageResolver.resolve(40.0, outside.stat(&"magic_resist")), 0.0001)


func test_broadside_global_cast_interrupt_cooldown_and_reset() -> void:
	queue_r(Vector3(-15, 0, -11))
	await advance(1)
	assert_same(player.active_cast, arena.captain.r)
	player.apply_status(&"stun", 1, 5)
	await advance(16)
	assert_eq(arena.captain.broadsides.size(), 0)
	assert_eq(arena.captain.r.ready_tick, 1801)
	queue_r(Vector3(0, 0, 8))
	await advance(17)
	var failures: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "ability_cast_failed")
	assert_eq(failures[-1].payload.slot, &"R")
	assert_eq(failures[-1].payload.reason, "On cooldown")
	arena.reset_arena()
	queue_r(Vector3(0, 0, 8))
	await advance(33)
	assert_eq(arena.captain.broadsides.size(), 1)
	arena.reset_arena()
	assert_eq(arena.captain.broadsides.size(), 0)
	assert_eq(arena.captain.r.ready_tick, 0)
	await advance(90)
	assert_eq(arena.combat_log.rows.size(), 0)


func test_broadside_rejects_outside_arena_and_physical_r_is_forwarded() -> void:
	queue_r(Vector3(19, 0, 8))
	await advance(1)
	assert_eq(arena.captain.r.ready_tick, 0)
	watch_signals(InputRouter)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	assert_true(key.is_action_pressed("ability_r"))
	InputRouter._unhandled_input(key)
	assert_signal_emitted_with_parameters(InputRouter, "world_action", [&"ability_r"])


func test_broadside_seeded_impacts_repeat_inside_circle_without_render_rng() -> void:
	SimClock.state.rng.seed = 1234
	queue_r(Vector3(0, 0, 8))
	await advance(16)
	var zone: BroadsideZone = arena.captain.broadsides[0]
	var expected := zone.waves.duplicate(true)
	var rng_state := SimClock.state.rng.state
	zone._process(0.1)
	zone._process(0.2)
	assert_eq(SimClock.state.rng.state, rng_state)
	for wave in zone.waves: assert_lte(wave.impact.length(), 5.80001)
	arena.reset_arena()
	SimClock.state.rng.seed = 1234
	queue_r(Vector3(0, 0, 8))
	await advance(32)
	var actual: Array = arena.captain.broadsides[0].waves
	assert_eq(actual.size(), expected.size())
	for i in range(expected.size()): assert_eq(actual[i].impact, expected[i].impact)


func test_broadside_dense_visuals_preserve_wave_schedule_and_simulation_rng() -> void:
	SimClock.state.rng.seed = 4321
	queue_r(Vector3(0, 0, 8))
	await advance(16)
	var dense: BroadsideZone = arena.captain.broadsides[0]
	assert_eq(dense.visual_impacts.size(), 192)
	var expected_rng := SimClock.state.rng.state
	var expected_waves := dense.waves.duplicate(true)
	for impact in dense.visual_impacts:
		assert_lte(impact.impact.length(), 5.80001)
	arena.reset_arena()
	DebugConfig.set_override(arena.captain.r.data.resource_path, &"cannonballs_per_wave", 1)
	SimClock.state.rng.seed = 4321
	queue_r(Vector3(0, 0, 8))
	await advance(32)
	var sparse: BroadsideZone = arena.captain.broadsides[0]
	assert_eq(sparse.visual_impacts.size(), 12)
	assert_eq(SimClock.state.rng.state, expected_rng)
	assert_eq(sparse.waves.size(), expected_waves.size())
	for i in range(expected_waves.size()):
		assert_eq(sparse.waves[i].impact, expected_waves[i].impact)
		assert_eq(sparse.waves[i].tick - 16, expected_waves[i].tick)
