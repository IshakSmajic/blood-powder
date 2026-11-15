class_name ChallengeEncounter
extends RefCounted

var arena: Node3D
var data: EncounterData = preload("res://data/encounters/challenge.tres")
var wave: int = 0
var next_wave: int = 180
var outcome: String = ""
var end_tick: int = 0
var damage_taken: float = 0.0
var drivers: Array[EnemyAI] = []
var next_id: int = 1

func reset() -> void:
	wave = 0
	next_wave = data.first_delay
	outcome = ""
	end_tick = 0
	damage_taken = 0.0
	drivers.clear()
	next_id = 1

func pre_tick(tick: int) -> void:
	if not outcome.is_empty(): return
	if not arena.player.alive():
		finish("Defeat", tick)
		return
	if next_wave >= 0 and tick >= next_wave:
		spawn_wave(tick)
	for driver in drivers: driver.pre_tick(tick)

func post_tick(tick: int) -> void:
	if not outcome.is_empty(): return
	for driver in drivers: driver.post_tick(tick)
	if not arena.player.alive():
		finish("Defeat", tick)
		return
	if wave == 0 or next_wave >= 0: return
	for unit in arena.units:
		if unit != arena.player and unit.alive(): return
	if wave >= data.waves.size(): finish("Victory", tick)
	else:
		next_wave = tick + data.wave_delay
		EventBus.publish(&"wave_cleared", {"wave": wave, "next_tick": next_wave})

func spawn_wave(tick: int) -> void:
	wave += 1
	next_wave = -1
	var types: PackedStringArray = data.waves[wave - 1]
	# Fixed spawn pads clear the central wall and all pillars; no random spawn order.
	var pads := [Vector3(-8, 0, -6), Vector3(8, 0, -6), Vector3(0, 0, -9), Vector3(-11, 0, 1), Vector3(11, 0, 1)]
	for i in types.size():
		var enemy := EnemyUnit.new()
		enemy.unit_id = next_id
		next_id += 1
		enemy.name = "Enemy%d" % enemy.unit_id
		enemy.unit_name = types[i].capitalize()
		enemy.team = 1
		enemy.stats = load("res://data/stats/%s.tres" % types[i])
		enemy.spawn_point = pads[i % pads.size()]
		enemy.counts_as_elite = types[i] == "elite"
		enemy.respawn_enabled = false
		arena.add_child(enemy)
		arena.units.append(enemy)
		var driver := EnemyAI.new()
		driver.configure(arena, enemy, types[i], tick)
		drivers.append(driver)
	EventBus.publish(&"wave_started", {"wave": wave, "count": types.size()})

func finish(result: String, tick: int) -> void:
	outcome = result
	end_tick = tick
	for unit in arena.units: unit.movement.stop()
	EventBus.publish(&"challenge_finished", {"result": result, "wave": wave, "clear_ticks": tick, "damage_taken": damage_taken})

func summary(tick: int) -> String:
	if not outcome.is_empty():
		return "%s · Wave %d · %.2f s · damage taken %.0f · Reset to retry" % [outcome.to_upper(), wave, end_tick / 60.0, damage_taken]
	return "CHALLENGE · Wave %d / %d · %.2f s%s" % [wave, data.waves.size(), tick / 60.0, " · next wave %.1f s" % (maxi(0, next_wave - tick) / 60.0) if next_wave >= 0 else ""]
