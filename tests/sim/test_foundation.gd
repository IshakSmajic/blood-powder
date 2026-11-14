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
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	player = arena.player
	dummy = arena.units[1]
	SimClock.state.tick = 0
	current_tick = 0
	DebugConfig.set_override(player.stats.resource_path, &"crit_chance", 0.0)
	player.global_position = Vector3(0, 0, 8)
	dummy.global_position = Vector3(1.5, 0, 8)


func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()


func advance(to_tick: int) -> void:
	while current_tick < to_tick:
		await get_tree().physics_frame
		current_tick += 1
		SimClock.state.tick = current_tick
		arena.simulate_tick(current_tick)


func test_orders_apply_next_tick_and_hits_land_exactly_after_windup() -> void:
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	assert_eq(player.state, "Idle")
	await advance(1)
	assert_eq(player.state, "Attack windup")
	assert_eq(player.attack.hit_tick, 16)
	await advance(15)
	assert_eq(dummy.health, 2000.0)
	await advance(16)
	assert_almost_eq(dummy.health, 2000.0 - 70.0 / 1.5, 0.0001)
	await advance(91)
	assert_almost_eq(dummy.health, 2000.0 - 70.0 / 1.5, 0.0001)
	await advance(92)
	assert_eq(player.attack.hit_tick, 107)


func test_stop_during_windup_refunds_without_damage() -> void:
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	await advance(10)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.STOP), 10)
	await advance(11)
	assert_eq(player.attack.hit_tick, -1)
	assert_eq(player.attack.ready_tick, 11)
	await advance(30)
	assert_eq(dummy.health, 2000.0)
	assert_eq(player.state, "Idle")


func test_retarget_cancels_old_windup_and_commits_only_new_target() -> void:
	var other: CombatUnit = arena.units[2]
	other.global_position = Vector3(-1.5, 0, 8)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	await advance(10)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, other), 10)
	await advance(26)
	assert_eq(dummy.health, 2000.0)
	assert_almost_eq(other.health, 2000.0 - 70.0 / 1.5, 0.0001)


func test_move_after_hit_keeps_cooldown_and_moves_immediately() -> void:
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), 0)
	await advance(16)
	var before := player.global_position
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(4, 0, 8)), 16)
	await advance(17)
	assert_eq(player.attack.ready_tick, 92)
	assert_gt(player.global_position.distance_to(before), 0.01)
	assert_eq(player.state, "Moving")


func test_navigation_routes_around_pillars_with_fixed_step_motion() -> void:
	assert_true(arena.navigation_ready)
	player.global_position = Vector3(-7, 0, 9)
	var goal := Vector3(-7, 0, -9)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, goal), 0)
	for tick in range(1, 601):
		await advance(tick)
		for z in [-4.0, 4.0]:
			var nearest := Vector3(clampf(player.position.x, -8.0, -6.0), 0, clampf(player.position.z, z - 1, z + 1))
			assert_gte(player.position.distance_to(nearest), 0.64, "Capsule penetrated a pillar")
	assert_lt(player.global_position.distance_to(goal), 0.4)
	assert_eq(player.state, "Idle")


func test_hold_attacks_in_range_without_chasing() -> void:
	var original := player.position
	player.queue_command(UnitCommand.create(UnitCommand.Kind.HOLD), 0)
	await advance(16)
	assert_lt(dummy.health, 2000.0)
	assert_eq(player.position, original)
	dummy.position = Vector3(10, 0, 8)
	await advance(200)
	assert_eq(player.position, original)


func test_death_respawns_on_the_exact_tick() -> void:
	dummy.receive_damage(99999, 5, 0)
	await advance(124)
	assert_false(dummy.alive())
	await advance(125)
	assert_eq(dummy.health, 2000.0)
	assert_eq(dummy.global_position, dummy.spawn_point)


func test_attack_move_resumes_original_goal_after_target_dies() -> void:
	dummy.position = Vector3(0, 0, 5.2)
	var goal := Vector3(0, 0, -8)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK_MOVE, goal), 0)
	await advance(20)
	dummy.receive_damage(99999, 20, 0)
	await advance(40)
	assert_lt(player.movement.destination.distance_to(goal), 0.3)
	assert_eq(player.order.kind, UnitCommand.Kind.ATTACK_MOVE)
