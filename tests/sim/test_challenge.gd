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
	while not arena.navigation_ready: await get_tree().physics_frame
	arena.mode = "Challenge"
	arena.reset_arena()
	SimClock.state.set_paused(true)
	tick = 0

func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()

func step() -> void:
	await get_tree().physics_frame
	tick += 1
	SimClock.state.tick = tick
	arena.simulate_tick(tick)

func advance(until: int) -> void:
	while tick < until: await step()

func spawn(type: String, at: Vector3) -> EnemyAI:
	var enemy := EnemyUnit.new()
	enemy.unit_id = arena.units.size()
	enemy.team = 1
	enemy.stats = load("res://data/stats/%s.tres" % type)
	enemy.spawn_point = at
	enemy.respawn_enabled = false
	arena.add_child(enemy)
	arena.units.append(enemy)
	var ai := EnemyAI.new()
	ai.configure(arena, enemy, type, tick)
	arena.challenge.drivers.append(ai)
	return ai

func test_wave_delays_composition_victory_and_restart() -> void:
	await advance(179)
	assert_eq(arena.units.size(), 1)
	await step()
	assert_eq(arena.challenge.wave, 1)
	assert_eq(arena.units.size(), 5)
	for unit in arena.units:
		if unit != arena.player: unit.receive_damage(100000.0, tick, 0)
	await step()
	assert_eq(arena.challenge.next_wave, 421)
	await advance(420)
	assert_eq(arena.challenge.wave, 1)
	await step()
	assert_eq(arena.challenge.wave, 2)
	assert_eq(arena.challenge.drivers.filter(func(ai: EnemyAI) -> bool: return ai.kind == "kiter").size(), 2)
	for unit in arena.units:
		if unit != arena.player: unit.receive_damage(100000.0, tick, 0)
	await step()
	await advance(662)
	assert_eq(arena.challenge.wave, 3)
	var elites: Array = arena.units.filter(func(u: CombatUnit) -> bool: return u.counts_as_elite)
	assert_eq(elites.size(), 1)
	assert_eq(elites[0].health, 2200.0)
	for unit in arena.units:
		if unit != arena.player: unit.receive_damage(100000.0, tick, 0)
	await step()
	assert_eq(arena.challenge.outcome, "Victory")
	assert_true(arena.challenge.summary(tick).contains("VICTORY"))
	arena.reset_arena()
	assert_eq(arena.challenge.wave, 0)
	assert_eq(arena.units.size(), 1)
	assert_eq(arena.challenge.outcome, "")

func test_defeat_has_no_respawn_and_training_returns_defaults() -> void:
	arena.player.receive_damage(9999.0, 1, 1)
	await step()
	assert_eq(arena.challenge.outcome, "Defeat")
	await advance(200)
	assert_false(arena.player.alive())
	arena.queue_mode("Training")
	await step()
	assert_eq(arena.mode, "Training")
	assert_eq(arena.units.size(), 4)
	assert_true(arena.player.respawn_enabled)
	assert_true(arena.units[1].training_infinite)

func test_chaser_acquisition_melee_and_sight_timeout() -> void:
	var ai := spawn("chaser", Vector3(0, 0, 8.5))
	await advance(24)
	assert_true(ai.acquired)
	assert_lt(arena.player.health, 1200.0)
	arena.player.position = Vector3(0, 0, -12)
	await advance(206)
	assert_false(ai.acquired)
	assert_eq(ai.unit.order.kind, UnitCommand.Kind.MOVE)
	assert_eq(ai.unit.order.point, ai.unit.spawn_point)
	await advance(300)
	assert_lt(ai.unit.position.distance_to(ai.unit.spawn_point), 0.2)

func test_elite_telegraph_survives_stun_root_but_can_be_dodged() -> void:
	var ai := spawn("elite", Vector3(0, 0, 8))
	ai.slam_ready = 1
	await step()
	assert_eq(ai.slam_end, 61)
	var initial: float = arena.player.health
	ai.unit.apply_status(&"stun", tick, 120)
	ai.unit.apply_status(&"root", tick, 120)
	await advance(60)
	assert_eq(arena.player.health, initial)
	await step()
	assert_almost_eq(arena.player.health, initial - 120.0 / 1.32, 0.001)
	assert_true(arena.player.statuses.has(&"stun"))
	arena.player.position = Vector3(10, 0, 10)
	ai.slam_ready = tick + 1
	# Dying during a future windup cancels it entirely.
	ai.unit.receive_damage(99999.0, tick, 0)
	await step()
	assert_eq(ai.slam_end, -1)

func test_kiter_retreat_and_projectile_travel_time() -> void:
	var ai := spawn("kiter", Vector3(0, 0, 7))
	await advance(8)
	assert_eq(ai.state, "Retreat")
	assert_lt(ai.unit.position.z, 7.0)
	ai.unit.position = Vector3(0, 0, 5)
	ai.unit.movement.stop()
	var hp: float = arena.player.health
	ai.launch(arena.player, tick)
	await advance(20)
	assert_eq(arena.player.health, hp)
	await advance(35)
	assert_lt(arena.player.health, hp)

func test_hunter_brush_and_camouflage_stop_live_tracking() -> void:
	arena._set_class("Hunter")
	arena.player.position = Vector3(-11, 0, -7)
	var ai := spawn("chaser", Vector3(-11, 0, 0))
	await advance(40)
	assert_eq(ai.state, "Search")
	assert_ne(ai.unit.order.kind, UnitCommand.Kind.ATTACK)
	arena.hunter.stalk_start = 0
	arena.hunter.stalk_end = 1000
	arena.player.position = Vector3(11, 0, -7)
	await advance(221)
	assert_false(ai.acquired)


func test_slam_fixed_center_can_be_dodged_and_crowds_keep_separation() -> void:
	var ai := spawn("elite", Vector3(0, 0, 8))
	ai.slam_ready = 1
	await step()
	var initial: float = arena.player.health
	arena.player.position = Vector3(10, 0, 10)
	await advance(61)
	assert_eq(arena.player.health, initial)
	assert_false(arena.player.statuses.has(&"stun"))
	var a := spawn("chaser", Vector3(10, 0, 6))
	var b := spawn("chaser", Vector3(10, 0, 6))
	await advance(100)
	assert_gt(a.unit.position.distance_to(b.unit.position), 0.9)

func test_captain_brush_hides_and_recent_damage_reveals_to_that_observer() -> void:
	arena.player.position = Vector3(-11, 0, -7)
	var ai := spawn("chaser", Vector3(-11, 0, 0))
	await advance(40)
	assert_false(arena.player_visible_to(ai.unit, tick))
	ai.unit.receive_damage(1.0, tick, 0)
	assert_true(arena.player_visible_to(ai.unit, tick))
	arena.player.position = Vector3(11, 0, -7)
	await advance(110)
	assert_false(arena.player_visible_to(ai.unit, tick))

func test_ranged_projectile_stops_at_central_wall() -> void:
	arena.player.position = Vector3(0, 0, -4)
	var ai := spawn("kiter", Vector3(0, 0, 2))
	ai.launch(arena.player, tick)
	var initial: float = arena.player.health
	for i in range(30): ai.post_tick(i + 1)
	assert_true(ai.shots.is_empty())
	assert_eq(arena.player.health, initial)


func test_kiter_opt_in_keg_attack_travels_and_destroys_without_explosion() -> void:
	DebugConfig.set_override(arena.training_settings.resource_path, &"enemies_attack_kegs", true)
	spawn("kiter", Vector3(0, 0, 2))
	var manager: KegManager = arena.captain.kegs
	var keg := manager.reserve(Vector3(0, 0, 7), 0)
	manager.materialize(keg.id, 0)
	keg.health = 1
	await advance(35)
	assert_true(manager.graph.nodes.has(keg.id), "Ranged hit launches a traveling shot")
	await advance(70)
	assert_false(manager.graph.nodes.has(keg.id))
	var explosions: Array = arena.combat_log.rows.filter(func(row: Dictionary) -> bool: return row.event == "keg_exploded")
	assert_eq(explosions.size(), 0)
