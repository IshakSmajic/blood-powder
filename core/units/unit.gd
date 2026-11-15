class_name CombatUnit
extends CharacterBody3D
## Command-driven unit; stock visual animation never drives its simulation.

var stats: UnitStats
var unit_name: String = "Unit"
var team: int = 0
var unit_id: int = 0
var health: float = 0.0
var state: String = "Idle"
var spawn_point: Vector3
var attack := AttackCycle.new()
var movement := MovementComponent.new()
var statuses := StatusEffects.new()
var ability := AbilityRunner.new()
var cast_controller: RefCounted
var active_cast: AbilityRunner
var counts_as_elite: bool = false
var _approach_cast: UnitCommand
var order: UnitCommand = UnitCommand.create(UnitCommand.Kind.STOP)
var _pending: UnitCommand
var _pending_tick: int = 0
var _pending_expires: int = 0
var _victim: Node3D
var _last_repath: int = -999
var _respawn_tick: int = -1
var _visual: Node3D
var avatar: CharacterAvatar
var _health_fill: MeshInstance3D
var _label: Label3D
var _color: Color
var _flash_frames: int = 0
var _resume_attack_move: bool = false


func stat(field: StringName) -> float:
	return float(DebugConfig.resolve(stats.resource_path, field, stats.get(field)))


func alive() -> bool:
	return health > 0.0


func _ready() -> void:
	ability.data = preload("res://data/abilities/training_pulse.tres")
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = stats.gameplay_radius
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	add_child(movement)
	movement.configure(self)
	_color = Color("923b3b") if team == 0 else Color("a7aeb5")
	_visual = Node3D.new()
	add_child(_visual)
	avatar = CharacterAvatar.new()
	avatar.unit = self
	avatar.dressed = team == 0
	_visual.add_child(avatar)
	if team == 1: _visual.rotation.y = PI
	_label = Label3D.new()
	_label.position.y = 2.5
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	_label.pixel_size = 0.004
	add_child(_label)
	_health_fill = MeshInstance3D.new()
	var bar := QuadMesh.new()
	bar.size = Vector2(1.8, 0.12)
	_health_fill.mesh = bar
	_health_fill.position.y = 2.2
	var material := _material(Color("76ae70") if team == 0 else Color("b86760"))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_health_fill.material_override = material
	add_child(_health_fill)
	reset_unit()


func reset_unit() -> void:
	global_position = spawn_point
	health = stat(&"max_health")
	state = "Idle"
	attack.reset()
	ability.reset()
	active_cast = null
	_approach_cast = null
	if cast_controller != null: cast_controller.reset()
	statuses.clear()
	movement.stop()
	order = UnitCommand.create(UnitCommand.Kind.STOP)
	_pending = null
	_victim = null
	_last_repath = -999
	_respawn_tick = -1
	_resume_attack_move = false
	_visual.show()
	avatar.reset_pose()
	reset_physics_interpolation()


func queue_command(command: UnitCommand, issued_tick: int) -> void:
	if not alive():
		return
	_pending = command
	_pending_tick = issued_tick + 1
	_pending_expires = issued_tick + 30


func simulate(tick: int, units: Array[CombatUnit]) -> void:
	if not alive():
		if tick >= _respawn_tick:
			reset_unit()
			EventBus.publish(&"unit_respawned", {"unit": unit_id})
		return
	for effect_event in statuses.advance(tick):
		if effect_event.event == &"burn_pulse":
			receive_damage(effect_event.amount, tick, effect_event.source_id, false, &"true")
		else:
			EventBus.publish(&"status_expired", {"unit": unit_id, "status": effect_event.kind})
	if not alive():
		return
	if _pending != null and tick >= _pending_expires:
		_pending = null
	if statuses.has(&"stun"):
		if _pending != null and _pending.kind == UnitCommand.Kind.CAST:
			_cast_failed("Stunned", _pending.slot)
			_pending = null
		state = "Stunned"
		movement.stop()
		return
	health = minf(health, stat(&"max_health"))
	# A command on the hit tick cannot cancel a hit already committed that tick.
	if attack.take_hit(tick):
		_hit(tick)
	if active_cast != null and active_cast.take_completion(tick):
		active_cast = null
		if cast_controller != null: cast_controller.complete(tick)
		else: _complete_pulse(tick, units)
	if active_cast != null:
		state = "Casting"
		return
	if _pending != null and tick >= _pending_tick:
		if _pending.kind == UnitCommand.Kind.CAST:
			var command := _pending
			_pending = null
			_approach_cast = null
			_request_cast(command, tick, units)
			if active_cast != null:
				state = "Casting"
				return
		else:
			_approach_cast = null
			if attack.cancel(tick):
				EventBus.publish(&"attack_cancelled", {"source": unit_id})
			order = _pending
			_pending = null
			_victim = null
			movement.stop()
			_last_repath = -999
			_resume_attack_move = false
			EventBus.publish(&"order_issued", {"source": unit_id, "kind": order.kind})
	if _approach_cast != null:
		_request_cast(_approach_cast, tick, units)
		if active_cast != null:
			state = "Casting"
			return
		if _approach_cast != null:
			var destination: Vector3 = _approach_cast.target.global_position if is_instance_valid(_approach_cast.target) else _approach_cast.point
			if tick - _last_repath >= 6:
				movement.set_destination(destination)
				_last_repath = tick
			state = "Approaching cast"
			_face(_move())
			return
	if attack.hit_tick >= 0:
		state = "Attack windup"
		return
	var target := _choose_target(units)
	if target != null:
		_resume_attack_move = order.kind == UnitCommand.Kind.ATTACK_MOVE
		if in_attack_range(target):
			movement.stop()
			_face(target.global_position - global_position)
			if attack.start(tick, stat(&"attack_speed"), stat(&"windup_fraction")):
				_victim = target
				EventBus.publish(&"attack_windup_started", {"source": unit_id, "target": target.unit_id, "hit_tick": attack.hit_tick})
			state = "Attack windup" if attack.hit_tick >= 0 else "Attack backswing"
			return
		if order.kind != UnitCommand.Kind.HOLD:
			if tick - _last_repath >= 6:
				movement.set_destination(target.global_position)
				_last_repath = tick
			state = "Chasing"
			_face(_move())
			return
	if order.kind in [UnitCommand.Kind.MOVE, UnitCommand.Kind.ATTACK_MOVE]:
		if _resume_attack_move:
			_last_repath = -999
			_resume_attack_move = false
		if _last_repath < 0:
			movement.set_destination(order.point)
			_last_repath = tick
		_face(_move())
		state = "Rooted" if statuses.has(&"root") else "Moving" if movement.active else "Idle"
		if not movement.active:
			order = UnitCommand.create(UnitCommand.Kind.STOP)
	else:
		movement.stop()
		state = "Holding" if order.kind == UnitCommand.Kind.HOLD else "Idle"


func _choose_target(units: Array[CombatUnit]) -> Node3D:
	if order.kind == UnitCommand.Kind.ATTACK:
		return order.target if is_instance_valid(order.target) and order.target.alive() else null
	if order.kind not in [UnitCommand.Kind.HOLD, UnitCommand.Kind.ATTACK_MOVE]:
		return null
	var nearest: CombatUnit
	var best: float = INF
	for candidate in units:
		if candidate.team == team or not candidate.alive():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		var margin := 0.5 if order.kind == UnitCommand.Kind.ATTACK_MOVE else 0.0
		if distance <= stat(&"attack_range") + stat(&"gameplay_radius") + candidate.stat(&"gameplay_radius") + margin and distance < best:
			best = distance
			nearest = candidate
	return nearest


func in_attack_range(target: Node3D) -> bool:
	return global_position.distance_to(target.global_position) <= stat(&"attack_range") + stat(&"gameplay_radius") + target.stat(&"gameplay_radius") + 0.001


func _hit(tick: int) -> void:
	if not is_instance_valid(_victim) or not _victim.alive() or not in_attack_range(_victim):
		return
	var crit := SimClock.state.rng.randf() < clampf(stat(&"crit_chance"), 0.0, 1.0)
	var raw := stat(&"attack_damage") * (stat(&"crit_multiplier") if crit else 1.0)
	EventBus.publish(&"attack_hit", {"source": unit_id, "target": _victim.unit_id})
	if _victim is PowderKeg:
		_victim.manager.hit(_victim.state.id, tick, {"raw": raw, "crit": crit, "source": unit_id})
	else:
		var damage := DamageResolver.resolve(raw, _victim.stat(&"armor"))
		_victim.receive_damage(damage, tick, unit_id, crit)
		if cast_controller != null: cast_controller.basic_hit(_victim, tick)


func receive_damage(amount: float, tick: int, source: int, crit: bool = false, damage_type: StringName = &"physical") -> void:
	if not alive():
		return
	health = maxf(0.0, health - maxf(0.0, amount))
	_flash_frames = 3
	EventBus.publish(&"damage_dealt", {"source": source, "target": unit_id, "amount": amount, "crit": crit, "position": global_position, "type": damage_type})
	if not alive():
		attack.reset()
		ability.interrupt()
		if active_cast != null: active_cast.interrupt()
		active_cast = null
		_approach_cast = null
		if cast_controller != null: cast_controller.interrupt()
		statuses.clear()
		_pending = null
		movement.stop()
		state = "Dead"
		_respawn_tick = tick + (180 if team == 0 else 120)
		EventBus.publish(&"unit_died", {"unit": unit_id})


func apply_status(kind: StringName, tick: int, duration: int, magnitude: float = 0.0, source: StringName = &"debug", source_id: int = -1) -> void:
	if not alive() or duration <= 0:
		return
	statuses.apply(kind, tick, duration, magnitude, source, source_id)
	EventBus.publish(&"status_applied", {"unit": unit_id, "status": kind, "duration": duration})
	if kind == &"stun":
		if attack.hit_tick >= 0:
			attack.hit_tick = -1
			attack.ready_tick = tick
			EventBus.publish(&"attack_cancelled", {"source": unit_id})
		if active_cast != null:
			active_cast.interrupt()
			active_cast = null
			if cast_controller != null: cast_controller.interrupt()
			EventBus.publish(&"ability_interrupted", {"source": unit_id})
		movement.stop()
		_last_repath = -999


func heal(amount: float) -> void:
	if not alive(): return
	var previous := health
	health = minf(stat(&"max_health"), health + maxf(0.0, amount))
	EventBus.publish(&"healing_received", {"source": unit_id, "target": unit_id, "amount": health - previous, "position": global_position})


func cleanse() -> void:
	for kind in statuses.cleanse():
		EventBus.publish(&"status_expired", {"unit": unit_id, "status": kind, "reason": "cleanse"})


func _move() -> Vector3:
	if statuses.has(&"root"):
		state = "Rooted"
		velocity = Vector3.ZERO
		return Vector3.ZERO
	return movement.simulate(stat(&"move_speed") * statuses.move_multiplier())


func _cast_failed(reason: String, slot: StringName = &"Q") -> void:
	EventBus.publish(&"ability_cast_failed", {"source": unit_id, "reason": reason, "slot": slot})


func _request_cast(command: UnitCommand, tick: int, units: Array[CombatUnit]) -> void:
	var result: Dictionary
	if cast_controller != null:
		result = cast_controller.request(command, tick)
	else:
		result = {"reason": ability.start(tick), "runner": ability, "name": "training_pulse"}
	if result.get("approach", false):
		if _approach_cast == null:
			attack.cancel(tick)
			movement.stop()
			_last_repath = -999
		_approach_cast = command
		return
	_approach_cast = null
	if not result.get("reason", "").is_empty():
		_cast_failed(result.reason, command.slot)
		return
	active_cast = result.runner
	if is_instance_valid(command.target): _face(command.target.global_position - global_position)
	elif command.slot == &"E": _face(command.point - global_position)
	if attack.cancel(tick): EventBus.publish(&"attack_cancelled", {"source": unit_id})
	_victim = null
	movement.stop()
	_last_repath = -999
	EventBus.publish(&"ability_cast_started", {"source": unit_id, "ability": result.name, "completion_tick": active_cast.completion_tick})
	if active_cast.take_completion(tick):
		active_cast = null
		if cast_controller != null: cast_controller.complete(tick)
		else: _complete_pulse(tick, units)


func _complete_pulse(tick: int, units: Array[CombatUnit]) -> void:
	var radius := maxf(0.0, ability.value(&"radius"))
	for target in units:
		if target.team == team or not target.alive():
			continue
		if global_position.distance_to(target.global_position) <= radius + target.stat(&"gameplay_radius"):
			var damage := DamageResolver.resolve(ability.value(&"damage"), target.stat(&"magic_resist"))
			target.receive_damage(damage, tick, unit_id, false, &"magic")
			target.apply_status(&"slow", tick, maxi(0, roundi(ability.value(&"slow_duration") * 60)), ability.value(&"slow_fraction"), &"training_pulse", unit_id)
	EventBus.publish(&"ability_cast_completed", {"source": unit_id, "ability": "training_pulse", "position": global_position, "radius": radius})


func _process(_delta: float) -> void:
	_label.text = "%s\n%d / %d" % [unit_name, ceili(health), ceili(stat(&"max_health"))]
	_health_fill.scale.x = maxf(0.001, health / maxf(1.0, stat(&"max_health")))
	avatar.set_flash(_flash_frames > 0)
	_flash_frames = maxi(0, _flash_frames - 1)


func _face(direction: Vector3) -> void:
	if direction.length_squared() > 0.001:
		_visual.rotation.y = atan2(-direction.x, -direction.z)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
