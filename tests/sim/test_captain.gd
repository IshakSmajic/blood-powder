extends GutTest

const Arena = preload("res://world/arena.tscn")
var arena: Node3D
var player: CombatUnit
var dummy: CombatUnit
var current_tick: int = 0


func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = Arena.instantiate()
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


func test_ration_stun_interrupts_without_heal_or_cooldown_refund() -> void:
	player.health = 600.0
	queue_w()
	await advance(5)
	player.apply_status(&"stun", 5, 60)
	await advance(16)
	assert_eq(player.health, 600.0)
	assert_eq(arena.captain.w.ready_tick, 1081)
	assert_eq(arena.captain.w.completion_tick, -1)
	queue_w()
	await advance(17)
	assert_true(player.statuses.has(&"stun"))
	var failures: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "ability_cast_failed")
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
