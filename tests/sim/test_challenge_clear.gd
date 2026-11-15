extends GutTest
## A command-only combat pilot exercises stock stats; no health/damage cheats.
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
	tick = 0

func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()

func step() -> void:
	await get_tree().physics_frame
	tick += 1
	SimClock.state.tick = tick
	arena.simulate_tick(tick)

func cast(slot: StringName, point: Vector3 = Vector3.ZERO, target: Node3D = null) -> void:
	var command := UnitCommand.create(UnitCommand.Kind.CAST, point, target)
	command.slot = slot
	arena.player.queue_command(command, tick)

func pilot() -> void:
	var player: CombatUnit = arena.player
	if not player.alive() or player._pending != null or player.active_cast != null: return
	var nearest: CombatUnit
	var best: float = INF
	for enemy in arena.units:
		if enemy == player or not enemy.alive(): continue
		var distance := player.position.distance_to(enemy.position)
		if distance < best:
			best = distance
			nearest = enemy
	if nearest == null: return
	# Dodge each fixed slam circle immediately; the warning is a full second.
	for ai in arena.challenge.drivers:
		if ai.slam_end >= 0 and player.position.distance_to(ai.slam_point) < 3.3:
			var away: Vector3 = (player.position - ai.slam_point).normalized()
			if away.length_squared() < 0.01: away = Vector3.FORWARD
			player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, ai.slam_point + away * 4.2), tick)
			return
	if arena.hunter != null and player.attack.hit_tick < 0:
		for ai in arena.challenge.drivers:
			if ai.kind != "kiter" and ai.unit.alive() and ai.unit.attack.hit_tick > tick and player.position.distance_to(ai.unit.position) < 3.6:
				var away: Vector3 = (player.position - ai.unit.position).normalized()
				player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, ai.unit.position + away * 4.0), tick)
				return
	if tick % 6 == 0:
		if arena.hunter != null:
			var h: HunterController = arena.hunter
			if best < 5 and ((tick >= h.w.ready_tick and (h.grey_health(tick) > 10 or best < 4.5)) or (h.ferocity.empowered() and h.grey_health(tick) > 30)):
				cast(&"W")
				return
			if best < 3 and (tick >= player.ability.ready_tick or h.ferocity.empowered()):
				cast(&"Q")
				return
			if tick >= h.e.ready_tick and best < 10:
				cast(&"E", nearest.position)
				return
			if tick >= h.r.ready_tick and best > 5:
				cast(&"R")
				return
		else:
			var c: CaptainController = arena.captain
			if player.health < 950 and tick >= c.w.ready_tick:
				cast(&"W")
				return
			if tick >= c.r.ready_tick and best < 7:
				cast(&"R", player.position)
				return
			if tick >= player.ability.ready_tick:
				for keg in c.kegs.views.values():
					if keg.alive() and keg.state.health == 1 and keg.position.distance_to(nearest.position) < 3.4:
						cast(&"Q", Vector3.ZERO, keg)
						return
				if best < 7:
					cast(&"Q", Vector3.ZERO, nearest)
					return
			if c.charges.available > 0 and tick >= c.e.ready_tick and best < 4 and c.kegs.graph.nodes.size() < 2:
				cast(&"E", player.position + (nearest.position - player.position).normalized() * 1.5)
				return
	# Keep basic attacks running between ability casts.
	if player.order.kind != UnitCommand.Kind.ATTACK or player.order.target != nearest:
		player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, nearest), tick)

func clear_and_replay(type: String) -> void:
	arena._set_class(type)
	arena.mode = "Challenge"
	arena.reset_arena()
	SimClock.state.set_paused(true)
	var previous_wave: int = 0
	while tick < 18000 and arena.challenge.outcome.is_empty():
		if arena.challenge.wave != previous_wave:
			previous_wave = arena.challenge.wave
			print("PILOT WAVE ",type," ",previous_wave," HP ",arena.player.health)
		pilot()
		await step()
	print("CHALLENGE PILOT ", type, " ", arena.challenge.summary(tick), " HP ", arena.player.health)
	assert_eq(arena.challenge.outcome, "Victory", type + " command pilot clears all waves")
	assert_gt(arena.challenge.damage_taken, 200.0, "Combat creates meaningful pressure")
	if arena.challenge.outcome != "Victory": return
	var end: int = tick
	var path := "res://.local/test_exports/full_%s.bpr" % type
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_eq(arena.replay.save_run(arena, path), OK)
	assert_eq(arena.load_replay(path), OK)
	SimClock.state.set_paused(true)
	tick = 0
	while tick < end: await step()
	assert_eq(arena.replay.result, "REPLAY MATCH", type + " full challenge replay")
	assert_eq(arena.challenge.outcome, "Victory")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_captain_clear_and_full_replay() -> void:
	await clear_and_replay("Captain")

func test_hunter_clear_and_full_replay() -> void:
	await clear_and_replay("Hunter")
