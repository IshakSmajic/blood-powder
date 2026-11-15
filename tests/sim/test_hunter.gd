extends GutTest

const Arena = preload("res://world/arena.tscn")
var arena: Node3D
var player: CombatUnit
var dummy: CombatUnit
var hunter: HunterController
var tick: int


func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = Arena.instantiate()
	arena.initial_class = "Hunter"
	arena.training_enabled = false
	add_child_autofree(arena)
	SimClock.state.set_paused(true)
	for i in range(3): await get_tree().physics_frame
	player = arena.player
	dummy = arena.units[1]
	hunter = arena.hunter
	player.position = Vector3(-11, 0, -7)
	dummy.position = Vector3(-3, 0, -7)
	tick = 0
	DebugConfig.set_override(player.stats.resource_path, &"crit_chance", 0.0)


func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()


func advance(to: int) -> void:
	while tick < to:
		await get_tree().physics_frame
		tick += 1
		SimClock.state.tick = tick
		arena.simulate_tick(tick)


func cast(slot: StringName, point: Vector3 = Vector3.ZERO) -> void:
	var command := UnitCommand.create(UnitCommand.Kind.CAST, point)
	command.slot = slot
	player.queue_command(command, tick)


func attack() -> void:
	player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, dummy), tick)


func test_brush_range_edge_boundary_and_exact_landing_ticks() -> void:
	dummy.position = player.position + Vector3.RIGHT * (7.4 + 1.3)
	attack()
	await advance(1)
	assert_true(hunter.airborne)
	var landing := hunter.leap_end
	var expected := 1 + roundi(hunter.leap_origin.distance_to(hunter.leap_destination) / 14.5 * 60)
	assert_eq(landing, expected)
	await advance(landing - 1)
	assert_eq(dummy.health, 2000.0)
	await advance(landing)
	assert_false(hunter.airborne)
	assert_eq(dummy.health, 1950.0)
	assert_eq(hunter.ferocity.stacks, 1)
	arena.reset_arena()
	player.position = Vector3(-11, 0, -7)
	dummy.position = player.position + Vector3.RIGHT * (7.6 + 1.3)
	attack()
	await advance(tick + 2)
	assert_false(hunter.airborne)


func test_linger_twenty_ticks_then_expires_at_twenty_two() -> void:
	await advance(1)
	player.position = Vector3(-11, 0, -5)
	await advance(21)
	assert_true(hunter.leap_eligible(tick))
	await advance(23)
	assert_false(hunter.leap_eligible(tick))


func test_midair_bola_immediate_and_move_buffered_until_landing() -> void:
	attack()
	await advance(1)
	var landing := hunter.leap_end
	cast(&"E", dummy.position)
	await advance(2)
	assert_eq(hunter.bolas.size(), 1)
	assert_eq(player.active_cast, null)
	assert_eq(hunter.e.ready_tick, 602)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(-2, 0, -10)), tick)
	await advance(landing - 1)
	assert_true(hunter.airborne)
	await advance(landing + 1)
	assert_false(hunter.airborne)
	assert_eq(player.order.kind, UnitCommand.Kind.MOVE)


func test_stun_interrupts_leap_without_landing_damage() -> void:
	attack()
	await advance(5)
	var position := player.position
	player.apply_status(&"stun", tick, 60)
	await advance(40)
	assert_false(hunter.airborne)
	assert_eq(player.position, position)
	assert_eq(dummy.health, 2000.0)
	assert_eq(player.avatar.position.y, 0.0)


func test_rend_reset_uncancellable_first_hit_and_ferocity_gain() -> void:
	player.position = Vector3(0, 0, 8)
	dummy.position = Vector3(2, 0, 8)
	player.attack.ready_tick = 500
	cast(&"Q")
	await advance(1)
	assert_eq(player.attack.ready_tick, 0)
	attack()
	await advance(2)
	var hit := player.attack.hit_tick
	assert_gt(hit, tick)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(0, 0, 10)), tick)
	await advance(hit)
	assert_almost_eq(dummy.health, 2000.0 - 135.0 / 1.5, 0.0001)
	assert_eq(hunter.ferocity.stacks, 1)
	assert_eq(hunter.rend_hits, 1)
	assert_eq(player.order.kind, UnitCommand.Kind.MOVE)


func test_grey_health_rolling_ninety_ticks_and_empowered_cleanse() -> void:
	player.receive_damage(200.0, 0, 1)
	await advance(30)
	player.receive_damage(100.0, tick, 1)
	assert_eq(hunter.grey_health(tick), 150.0)
	await advance(90)
	assert_eq(hunter.grey_health(tick), 50.0)
	hunter.ferocity.stacks = 4
	player.apply_status(&"root", tick, 100)
	player.apply_status(&"stun", tick, 100)
	cast(&"W")
	await advance(91)
	assert_eq(player.health, 750.0)
	assert_false(player.statuses.has(&"root"))
	assert_false(player.statuses.has(&"stun"))
	assert_eq(hunter.ferocity.stacks, 0)
	assert_eq(hunter.w.ready_tick, 0)
	assert_almost_eq(player.statuses.move_multiplier(), 1.4, 0.0001)


func test_stalk_camouflage_mark_bonus_and_armor_expiry() -> void:
	cast(&"R")
	await advance(120)
	assert_false(hunter.camouflaged(tick))
	await advance(121)
	assert_true(hunter.camouflaged(tick))
	assert_true(hunter.leap_eligible(tick))
	assert_same(hunter.marked, dummy)
	assert_false(hunter.visible_to(dummy, tick))
	attack()
	await advance(122)
	var landing := hunter.leap_end
	await advance(landing)
	assert_almost_eq(dummy.health, 2000.0 - 150.0 / 1.3, 0.0001)
	assert_false(hunter.camouflaged(tick))
	assert_eq(dummy.stat(&"armor"), 30.0)
	player.queue_command(UnitCommand.create(UnitCommand.Kind.STOP), tick)
	await advance(landing + 240)
	assert_eq(dummy.stat(&"armor"), 50.0)


func test_ground_bola_cast_aim_fixed_and_first_target_hit() -> void:
	player.position = Vector3(0, 0, 8)
	dummy.position = Vector3(3, 0, 8)
	var other: CombatUnit = arena.units[2]
	other.position = Vector3(6, 0, 8)
	cast(&"E", Vector3(10, 0, 8))
	await advance(15)
	assert_eq(hunter.bolas.size(), 0)
	assert_eq(hunter.ferocity.stacks, 1)
	await advance(16)
	assert_eq(hunter.bolas.size(), 1)
	await advance(35)
	assert_almost_eq(dummy.health, 2000.0 - 80.0 / 1.5, 0.0001)
	assert_eq(other.health, 2000.0)
	assert_true(dummy.statuses.has(&"slow"))


func test_class_switch_clears_live_effects_and_reset_restores_state() -> void:
	cast(&"E", dummy.position)
	await advance(17)
	assert_gt(hunter.bolas.size(), 0)
	arena.queue_class("Captain")
	await advance(18)
	assert_eq(arena.hunter, null)
	assert_not_null(arena.captain)
	assert_eq(player.health, 1200.0)
	assert_eq(hunter.bolas.size(), 0)
	arena.queue_class("Hunter")
	await advance(19)
	assert_eq(arena.captain, null)
	assert_eq(player.health, 1000.0)
	assert_eq(player.stat(&"armor"), 30.0)
	arena.reset_arena()
	assert_eq(arena.hunter.ferocity.stacks, 0)


func test_leap_howl_bola_rend_build_four_then_empowered_bola_ignores_cooldown() -> void:
	attack()
	await advance(1)
	cast(&"W")
	await advance(2)
	cast(&"E", dummy.position)
	await advance(3)
	cast(&"Q")
	await advance(4)
	var landing := hunter.leap_end
	await advance(landing)
	assert_eq(hunter.ferocity.stacks, 4)
	assert_gt(player.ability.ready_tick, tick)
	assert_gt(hunter.e.ready_tick, tick)
	var old_cooldown := hunter.e.ready_tick
	cast(&"E", dummy.position)
	await advance(landing + 1)
	assert_eq(hunter.ferocity.stacks, 0)
	assert_eq(hunter.e.ready_tick, old_cooldown)
	await advance(landing + 20)
	assert_true(dummy.statuses.has(&"root"))
	assert_almost_eq(player.statuses.move_multiplier(), 1.4, 0.0001)


func test_root_prevents_leap_and_attack_cooldown_waits_without_pathing() -> void:
	player.apply_status(&"root", 0, 60)
	attack()
	await advance(3)
	assert_false(hunter.airborne)
	assert_eq(player.position, Vector3(-11, 0, -7))
	player.cleanse()
	player.attack.ready_tick = 100
	await advance(5)
	assert_eq(player.state, "Leap waiting")
	assert_false(player.movement.active)
	assert_eq(player.position, Vector3(-11, 0, -7))


func test_wall_blocked_leap_still_attacks_and_dead_target_consumes_rend() -> void:
	player.position = Vector3(-4, 0, -1)
	dummy.position = Vector3(4, 0, -1)
	hunter.last_brush_tick = 1
	cast(&"Q")
	await advance(1)
	attack()
	await advance(2)
	var landing := hunter.leap_end
	assert_true(hunter.airborne)
	await advance(landing)
	assert_true(hunter.leap_blocked)
	assert_lt(player.position.x, -3.5)
	assert_almost_eq(dummy.health, 2000.0 - 135.0 / 1.5, 0.0001)
	arena.reset_arena()
	player.position = Vector3(-11, 0, -7)
	dummy.position = Vector3(-3, 0, -7)
	cast(&"Q")
	await advance(tick + 1)
	attack()
	await advance(tick + 1)
	landing = hunter.leap_end
	dummy.receive_damage(9999.0, tick, 0)
	await advance(landing)
	assert_false(hunter.rend_first)
	assert_eq(hunter.rend_hits, 1)
	assert_eq(dummy.health, 0.0)


func test_bola_width_hits_and_walls_block_projectile() -> void:
	player.position = Vector3(0, 0, 8)
	dummy.position = Vector3(3, 0, 9)
	cast(&"E", Vector3(10, 0, 8))
	await advance(35)
	assert_lt(dummy.health, 2000.0)
	arena.reset_arena()
	player.position = Vector3(0, 0, 3)
	dummy.position = Vector3(0, 0, -4)
	cast(&"E", dummy.position)
	await advance(tick + 60)
	assert_eq(dummy.health, 2000.0)
	assert_eq(hunter.bolas.size(), 0)


func test_brush_vision_delay_nearby_reveal_and_damage_refresh_excludes_burn() -> void:
	await advance(30)
	assert_true(hunter.visible_to(dummy, tick))
	await advance(31)
	assert_false(hunter.visible_to(dummy, tick))
	dummy.position = player.position + Vector3.RIGHT
	assert_true(hunter.visible_to(dummy, tick))
	dummy.position = Vector3(-3, 0, -7)
	hunter.ferocity.stacks = 2
	hunter.ferocity.last_combat_tick = 1
	player.apply_status(&"burn", tick, 150, 1.0)
	await advance(61)
	assert_eq(hunter.ferocity.last_combat_tick, 1)
	player.receive_damage(1.0, tick, 1, false, &"true")
	assert_eq(hunter.ferocity.last_combat_tick, tick)


func test_empowered_rend_speed_persists_through_followup_base_rend() -> void:
	hunter.ferocity.stacks = 4
	cast(&"Q")
	await advance(1)
	assert_almost_eq(hunter.attack_speed(tick), 0.667 * 1.75, 0.0001)
	await advance(7)
	cast(&"Q")
	await advance(8)
	assert_false(hunter.rend_empowered)
	assert_almost_eq(hunter.attack_speed(tick), 0.667 * 1.75, 0.0001)
	await advance(301)
	assert_almost_eq(hunter.attack_speed(tick), 0.667, 0.0001)


func test_leap_landing_hits_moved_target_and_f2_render_does_not_change_rng() -> void:
	attack()
	await advance(1)
	var destination := hunter.leap_destination
	var landing := hunter.leap_end
	dummy.position = Vector3(10, 0, 10)
	arena.show_ranges = true
	var rng := SimClock.state.rng.state
	arena._process(0.016)
	assert_eq(SimClock.state.rng.state, rng)
	await advance(landing)
	assert_eq(player.position, destination)
	assert_eq(dummy.health, 1950.0)


func test_bola_launch_origin_is_cast_completion_position_with_original_aim() -> void:
	player.position = Vector3(0, 0, 8)
	cast(&"E", Vector3(10, 0, 8))
	await advance(5)
	player.position = Vector3(0, 0, 10)
	await advance(16)
	assert_eq(hunter.bolas.size(), 1)
	assert_eq(hunter.bolas[0].position, Vector3(0, 0, 10))
	assert_almost_eq(hunter.bolas[0].direction.z, -2.0 / sqrt(104.0), 0.0001)


func test_armor_shred_expires_before_target_turn_on_boundary_tick() -> void:
	dummy.apply_status(&"armor_shred", 0, 10, 20.0, &"stalk", 0)
	assert_eq(dummy.stat(&"armor"), 30.0)
	SimClock.state.tick = 10
	assert_eq(dummy.stat(&"armor"), 50.0)
