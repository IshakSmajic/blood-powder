class_name EnemyAI
extends RefCounted
## Fixed-tick command producer. Hidden targets are never chased by live position.
var settings: EnemyBehavior = preload("res://data/encounters/enemy_behavior.tres")
var slam_radius: float = 2.5
var slam_duration: int = 60
var slam_damage: float = 120.0
var slam_stun: int = 60
var arena: Node3D
var unit: EnemyUnit
var kind: String
var state: String = "Idle"
var acquired: bool = false
var last_seen: int = -1
var last_point: Vector3
var retreat_until: int = -1
var next_retreat: int = 0
var slam_ready: int = 480
var slam_end: int = -1
var slam_point: Vector3
var shots: Array[Dictionary] = []

func configure(world: Node3D, actor: EnemyUnit, type: String, tick: int) -> void:
	arena = world
	unit = actor
	kind = type
	unit.driver = self
	unit.ranged = kind == "kiter"
	slam_ready = tick + maxi(1, roundi(value(&"slam_cooldown_ticks")))

func command(type: UnitCommand.Kind, tick: int, point: Vector3 = Vector3.ZERO, target: Node3D = null) -> void:
	if unit._pending != null:
		if unit._pending.kind == type and unit._pending.target == target and (type != UnitCommand.Kind.MOVE or unit._pending.point.distance_to(point) < 0.2): return
	if unit.order.kind == type and unit.order.target == target:
		if type != UnitCommand.Kind.MOVE or unit.order.point.distance_to(point) < 0.2: return
	# Never cancel an attack merely to refresh an unchanged AI decision.
	unit.queue_command(UnitCommand.create(type, point, target), tick)

func pre_tick(tick: int) -> void:
	if not unit.alive():
		slam_end = -1
		return
	if slam_end >= 0:
		unit.movement.stop()
		if tick >= slam_end:
			for target in arena.units:
				if target.team == unit.team or not target.alive(): continue
				if target.position.distance_to(slam_point) <= slam_radius + target.stat(&"gameplay_radius"):
					target.receive_damage(DamageResolver.resolve(slam_damage, target.stat(&"magic_resist")), tick, unit.unit_id, false, &"magic")
					target.apply_status(&"stun", tick, slam_stun, 0.0, &"elite_slam", unit.unit_id)
			EventBus.publish(&"elite_slam_hit", {"source": unit.unit_id, "position": slam_point})
			slam_end = -1
		return
	if unit.statuses.has(&"stun"): return
	var player: CombatUnit = arena.player
	if not player.alive():
		state = "Idle"
		command(UnitCommand.Kind.STOP, tick)
		return
	var distance := unit.position.distance_to(player.position)
	var visible: bool = arena.player_visible_to(unit, tick)
	if visible and distance <= value(&"acquire_range"):
		acquired = true
		last_seen = tick
		last_point = player.position
	if not acquired:
		if unit.position.distance_to(unit.spawn_point) > 0.15:
			state = "Return"
			command(UnitCommand.Kind.MOVE, tick, unit.spawn_point)
		else:
			state = "Idle"
		return
	if not visible or distance > value(&"acquire_range"):
		if tick - last_seen >= roundi(value(&"sight_memory_ticks")):
			acquired = false
			state = "Return"
			command(UnitCommand.Kind.MOVE, tick, unit.spawn_point)
		else:
			state = "Search"
			command(UnitCommand.Kind.MOVE, tick, last_point)
		return
	if kind == "elite" and tick >= slam_ready and distance <= value(&"slam_trigger_range"):
		state = "Slam"
		slam_point = unit.position
		slam_duration = maxi(1, roundi(value(&"slam_windup_ticks")))
		slam_radius = maxf(0.0, value(&"slam_radius"))
		slam_damage = maxf(0.0, value(&"slam_damage"))
		slam_stun = maxi(0, roundi(value(&"slam_stun_ticks")))
		slam_end = tick + slam_duration
		slam_ready = tick + maxi(1, roundi(value(&"slam_cooldown_ticks")))
		unit.attack.cancel(tick)
		unit._pending = null
		unit.order = UnitCommand.create(UnitCommand.Kind.STOP)
		unit.movement.stop()
		EventBus.publish(&"elite_slam_started", {"source": unit.unit_id, "position": slam_point, "end_tick": slam_end})
		return
	if bool(DebugConfig.resolve(arena.training_settings.resource_path, &"enemies_attack_kegs", arena.training_settings.enemies_attack_kegs)) and arena.captain != null:
		for keg in arena.captain.kegs.views.values():
			if keg.alive() and unit.in_attack_range(keg):
				command(UnitCommand.Kind.ATTACK, tick, Vector3.ZERO, keg)
				return
	if kind == "kiter":
		if distance < value(&"retreat_distance") and tick >= next_retreat and retreat_until < 0:
			retreat_until = tick + maxi(1, roundi(value(&"retreat_ticks")))
		if retreat_until >= 0:
			if tick < retreat_until and distance < value(&"retreat_distance") and not unit.statuses.has(&"root"):
				state = "Retreat"
				if tick % 6 == 0:
					var away := (unit.position - player.position).normalized()
					if away.length_squared() < 0.01: away = Vector3.RIGHT
					command(UnitCommand.Kind.MOVE, tick, unit.position + away * 3.0)
				return
			retreat_until = -1
			next_retreat = tick + 86
		if distance <= value(&"approach_distance"):
			state = "Attack"
			command(UnitCommand.Kind.ATTACK, tick, Vector3.ZERO, player)
			return
	state = "Attack" if unit.in_attack_range(player) else "Chase"
	command(UnitCommand.Kind.ATTACK, tick, Vector3.ZERO, player)

func launch(target: Node3D, tick: int) -> void:
	shots.append({"target": target, "point": unit.position + Vector3.UP * 0.9, "born": tick, "damage": unit.stat(&"attack_damage"), "speed": maxf(0.1, value(&"projectile_speed"))})
	EventBus.publish(&"enemy_projectile_launched", {"source": unit.unit_id, "target": target.unit_id})

func post_tick(tick: int) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot := shots[i]
		var target: Node3D = shot.target
		if not is_instance_valid(target) or not target.alive():
			shots.remove_at(i)
			continue
		if tick <= shot.born: continue
		var aim := target.position + Vector3.UP * 0.9
		var next: Vector3 = shot.point.move_toward(aim, float(shot.speed) / 60.0)
		var query := PhysicsRayQueryParameters3D.create(shot.point, next, 1)
		if not unit.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			shots.remove_at(i)
			continue
		if next.distance_to(aim) <= target.stat(&"gameplay_radius"):
			if target is PowderKeg: target.manager.enemy_hit(target.state.id)
			else: target.receive_damage(DamageResolver.resolve(shot.damage, target.stat(&"armor")), tick, unit.unit_id)
			shots.remove_at(i)
		else: shot.point = next


func value(field: StringName) -> float:
	return float(DebugConfig.resolve(settings.resource_path, field, settings.get(field)))
