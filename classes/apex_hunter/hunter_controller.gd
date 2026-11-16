class_name HunterController
extends RefCounted

var unit: CombatUnit
var arena: Node3D
var passive := AbilityRunner.new()
var w := AbilityRunner.new()
var e := AbilityRunner.new()
var r := AbilityRunner.new()
var ferocity := Ferocity.new()
var _command: UnitCommand
var _empowered: bool = false
var _cast_slot: StringName
var _cast_end: int = -1
var airborne: bool = false
var leap_start: int = 0
var leap_end: int = 0
var leap_origin := Vector3.ZERO
var leap_destination := Vector3.ZERO
var leap_target: CombatUnit
var leap_blocked: bool = false
var last_brush_tick: int = -9999
var brush_enter_tick: int = -1
var eligible_since: int = -1
var _was_eligible: bool = false
var rend_hits: int = 0
var rend_first: bool = false
var rend_empowered: bool = false
var rend_expires: int = -1
var rend_speed_expires: int = -1
var empowered_speed_expires: int = -1
var stalk_start: int = -1
var stalk_end: int = -1
var marked: CombatUnit
var grey_hits: Array[Dictionary] = []
var bolas: Array[Dictionary] = []
var hit_reveal: Dictionary = {}
var _camo_materials: Array[StandardMaterial3D] = []


func configure(world: Node3D, owner_unit: CombatUnit) -> void:
	arena = world
	unit = owner_unit
	unit.ability.data = preload("res://data/abilities/rend.tres")
	passive.data = preload("res://data/abilities/ambush_pounce.tres")
	w.data = preload("res://data/abilities/howl.tres")
	e.data = preload("res://data/abilities/bola.tres")
	r.data = preload("res://data/abilities/stalk.tres")
	unit.cast_controller = self
	reset()


func reset() -> void:
	for runner in [unit.ability, w, e, r, passive]: runner.reset()
	ferocity.reset()
	interrupt()
	airborne = false
	leap_target = null
	last_brush_tick = -9999
	brush_enter_tick = -1
	eligible_since = -1
	_was_eligible = false
	rend_hits = 0
	rend_first = false
	rend_expires = -1
	rend_speed_expires = -1
	empowered_speed_expires = -1
	stalk_start = -1
	stalk_end = -1
	marked = null
	grey_hits.clear()
	hit_reveal.clear()
	for shot in bolas:
		if is_instance_valid(shot.visual): shot.visual.queue_free()
	bolas.clear()
	unit.avatar.position.y = 0.0


func pre_tick(tick: int) -> void:
	ferocity.advance(tick, maxi(1, roundi(passive.value(&"ferocity_decay") * 60)))
	var brush: BrushZone = arena.brush_at(unit.position)
	if brush != null:
		if brush_enter_tick < 0: brush_enter_tick = tick
		last_brush_tick = tick
	else: brush_enter_tick = -1
	var eligible := leap_eligible(tick)
	if eligible and not _was_eligible: eligible_since = tick
	_was_eligible = eligible
	if tick >= rend_expires:
		rend_hits = 0
		rend_first = false
	if stalk_start >= 0 and tick >= stalk_end: end_stalk()
	if stalk_start >= 0:
		marked = null
		var best := r.value(&"mark_range")
		for target in arena.units:
			if not target.alive() or target.team == unit.team: continue
			var distance: float = unit.position.distance_to(target.position)
			if distance <= best:
				best = distance
				marked = target
	grey_hits = grey_hits.filter(func(hit: Dictionary) -> bool: return tick - hit.tick < roundi(w.value(&"grey_window") * 60))


func leap_eligible(tick: int) -> bool:
	return unit.alive() and not unit.statuses.has(&"root") and not unit.statuses.has(&"stun") and (tick <= last_brush_tick + roundi(passive.value(&"leap_linger") * 60) or camouflaged(tick))


func camouflaged(tick: int) -> bool:
	return stalk_start >= 0 and tick >= stalk_start + roundi(r.value(&"camouflage_delay") * 60) and tick < stalk_end


func visible_to(observer: CombatUnit, tick: int) -> bool:
	var distance := unit.position.distance_to(observer.position)
	if camouflaged(tick) and distance > r.value(&"detection_range"): return false
	var brush: BrushZone = arena.brush_at(unit.position)
	if brush != null and arena.brush_at(observer.position) != brush and tick - brush_enter_tick >= roundi(passive.value(&"brush_hide_delay") * 60):
		return distance <= passive.value(&"brush_reveal_range") or tick - int(hit_reveal.get(observer.unit_id, -9999)) < roundi(passive.value(&"brush_hit_reveal") * 60)
	return true


func request(command: UnitCommand, tick: int) -> Dictionary:
	if command.slot not in [&"Q", &"W", &"E", &"R"]: return {"reason": "Unavailable"}
	var runner: AbilityRunner = runner_for(command.slot)
	var empowered := command.slot != &"R" and ferocity.empowered()
	if empowered and tick < int(ferocity.empowered_lock.get(command.slot, 0)): return {"reason": "Ferocity lockout"}
	if not empowered and (tick < runner.ready_tick or tick < int(ferocity.base_lock.get(command.slot, 0))): return {"reason": "On cooldown"}
	if unit.statuses.has(&"stun") and not (command.slot == &"W" and empowered): return {"reason": "Stunned"}
	if command.slot == &"E" and (command.point - unit.position).length_squared() < 0.00001: return {"reason": "No direction"}
	var saved_ready := runner.ready_tick
	if empowered: runner.ready_tick = 0
	var reason := runner.start(tick)
	if not reason.is_empty():
		runner.ready_tick = saved_ready
		return {"reason": reason}
	if empowered:
		runner.ready_tick = saved_ready
		ferocity.consume(command.slot, tick)
		unit.apply_status(&"speed_buff", tick, roundi(passive.value(&"empowered_speed_duration") * 60), passive.value(&"empowered_speed"), &"ferocity", unit.unit_id)
	if airborne and command.slot == &"E": runner.completion_tick = tick
	if command.slot == &"E" and not empowered: ferocity.gain(&"E", tick)
	_command = command
	_empowered = empowered
	_cast_slot = command.slot
	_cast_end = runner.completion_tick
	if command.slot not in [&"Q", &"R"]: end_stalk()
	return {"runner": runner, "name": ["rend", "howl", "bola", "stalk"][[&"Q", &"W", &"E", &"R"].find(command.slot)]}


func runner_for(slot: StringName) -> AbilityRunner:
	return w if slot == &"W" else e if slot == &"E" else r if slot == &"R" else unit.ability


func complete(tick: int) -> void:
	if _command == null: return
	var slot := _command.slot
	match slot:
		&"Q":
			rend_hits = 2
			rend_first = true
			rend_empowered = _empowered
			rend_expires = tick + roundi(unit.ability.value(&"duration") * 60)
			rend_speed_expires = rend_expires
			if _empowered: empowered_speed_expires = tick + roundi(unit.ability.value(&"empowered_duration") * 60)
			unit.attack.reset()
		&"W":
			var raw := w.value(&"empowered_damage") if _empowered else w.value(&"damage")
			for target in arena.units:
				if target.team == unit.team or not target.alive(): continue
				if unit.position.distance_to(target.position) <= w.value(&"radius") + target.stat(&"gameplay_radius"):
					deal(target, raw, tick, &"magic")
			unit.heal(grey_health(tick))
			if _empowered: unit.cleanse()
			else: ferocity.gain(&"W", tick)
		&"E":
			var direction := _command.point - unit.position
			direction.y = 0.0
			direction = direction.normalized()
			var visual := MeshInstance3D.new()
			var shape := SphereMesh.new()
			shape.radius = 0.13
			shape.height = 0.26
			visual.mesh = shape
			visual.position = unit.position + Vector3.UP
			arena.add_child(visual)
			bolas.append({"position": unit.position, "direction": direction, "left": e.value(&"range"), "speed": e.value(&"projectile_speed"), "width": e.value(&"width"), "damage": e.value(&"empowered_damage") if _empowered else e.value(&"damage"), "empowered": _empowered, "duration": roundi(e.value(&"root_duration" if _empowered else &"slow_duration") * 60), "slow": e.value(&"slow_fraction"), "visual": visual, "tick": tick})
		&"R":
			stalk_start = tick
			stalk_end = tick + roundi(r.value(&"duration") * 60)
			unit.apply_status(&"speed_buff", tick, stalk_end - tick, r.value(&"speed_fraction"), &"stalk", unit.unit_id)
	EventBus.publish(&"ability_cast_completed", {"source": unit.unit_id, "ability": String(slot), "position": unit.position, "empowered": _empowered})
	_command = null


func interrupt() -> void:
	if not unit.alive():
		ferocity.reset()
		end_stalk()
		rend_hits = 0
		rend_first = false
	_command = null
	_cast_end = -1
	if airborne:
		airborne = false
		unit.avatar.position.y = 0.0
		EventBus.publish(&"leap_interrupted", {"source": unit.unit_id})


func can_cast_while_stunned(slot: StringName) -> bool:
	return slot == &"W" and ferocity.empowered()


func cast_survives_stun(_runner: AbilityRunner) -> bool:
	return false


func before_attack(target: Node3D, tick: int) -> bool:
	if not target is CombatUnit or target.team == unit.team: return false
	if not leap_eligible(tick) or unit.in_attack_range(target): return false
	var distance := unit.position.distance_to(target.position)
	if tick < unit.attack.ready_tick:
		unit.movement.stop()
		unit.state = "Leap waiting"
		return true
	if distance > passive.value(&"leap_range") + unit.stat(&"gameplay_radius") + target.stat(&"gameplay_radius"): return false
	leap_target = target
	leap_origin = unit.position
	var direction := (target.position - unit.position).normalized()
	leap_destination = target.position - direction * (target.stat(&"gameplay_radius") + passive.value(&"landing_gap") + unit.stat(&"gameplay_radius"))
	leap_start = tick
	leap_end = tick + maxi(1, roundi(leap_origin.distance_to(leap_destination) / maxf(0.1, passive.value(&"leap_speed")) * 60))
	airborne = true
	leap_blocked = false
	unit.movement.stop()
	unit._face(target.position - unit.position)
	unit.attack.start(tick, attack_speed(tick), unit.stat(&"windup_fraction"))
	unit.attack.hit_tick = -1
	ferocity.gain(&"leap", tick, true)
	EventBus.publish(&"attack_windup_started", {"source": unit.unit_id, "target": target.unit_id, "hit_tick": leap_end})
	EventBus.publish(&"leap_started", {"source": unit.unit_id, "target": target.unit_id, "landing_tick": leap_end, "position": leap_origin})
	unit.state = "Airborne"
	return true


func airborne_tick(tick: int) -> bool:
	if not airborne: return false
	if unit.statuses.has(&"stun"):
		interrupt()
		return false
	if unit._pending != null and unit._pending.kind == UnitCommand.Kind.CAST and tick >= unit._pending_tick:
		var command: UnitCommand = unit._pending
		unit._pending = null
		unit._request_cast(command, tick, arena.units)
	var fraction := clampf((tick - leap_start) / float(maxi(1, leap_end - leap_start)), 0.0, 1.0)
	if not leap_blocked:
		var destination := leap_origin.lerp(leap_destination, fraction)
		if arena.battlefield_enabled: destination = arena.ground_position(destination) + Vector3.UP * 0.04
		if unit.move_and_collide(destination - unit.position) != null: leap_blocked = true
	unit.avatar.position.y = passive.value(&"arc_height") * 4 * fraction * (1 - fraction)
	unit.state = "Airborne"
	if tick < leap_end: return true
	airborne = false
	unit.avatar.position.y = 0.0
	if tick >= unit.attack.ready_tick:
		unit.attack.start(tick, attack_speed(tick), unit.stat(&"windup_fraction"))
		unit.attack.hit_tick = -1
	unit._victim = leap_target
	if is_instance_valid(leap_target) and leap_target.alive(): unit._hit(tick, true)
	else: consume_rend(tick, false)
	end_stalk()
	EventBus.publish(&"leap_landed", {"source": unit.unit_id, "position": unit.position})
	unit._victim = null
	unit.state = "Attack backswing"
	return true


func attack_speed(tick: int) -> float:
	var bonus := 0.0
	if tick < rend_speed_expires and rend_hits > 0: bonus = unit.ability.value(&"attack_speed_bonus")
	if tick < empowered_speed_expires: bonus = maxf(bonus, unit.ability.value(&"empowered_attack_speed"))
	return unit.stat(&"attack_speed") * (1.0 + bonus)


func bonus_range(tick: int) -> float:
	if not rend_first or tick >= rend_expires: return 0.0
	if eligible_since >= 0 and tick >= eligible_since + roundi(unit.ability.value(&"range_loss_delay") * 60): return 0.0
	return unit.ability.value(&"bonus_range")


func locked_windup() -> bool:
	return rend_first and unit.attack.hit_tick >= 0


func attack_bonus(target: CombatUnit, tick: int) -> float:
	var bonus := unit.ability.value(&"empowered_damage" if rend_empowered else &"damage") if rend_first and tick < rend_expires else 0.0
	if stalk_start >= 0 and target == marked:
		bonus += unit.stat(&"attack_damage") * r.value(&"mark_ad_ratio")
		target.apply_status(&"armor_shred", tick, roundi(r.value(&"armor_duration") * 60), r.value(&"armor_reduction"), &"stalk", unit.unit_id)
	if not airborne: end_stalk()
	return bonus


func basic_hit(target: CombatUnit, tick: int) -> void:
	ferocity.last_combat_tick = tick
	hit_reveal[target.unit_id] = tick
	consume_rend(tick, true)


func consume_rend(tick: int, landed: bool) -> void:
	if rend_hits <= 0: return
	if rend_first and landed and not rend_empowered: ferocity.gain(&"Q", tick)
	rend_first = false
	rend_hits -= 1


func took_damage(amount: float, tick: int, burn: bool) -> void:
	grey_hits.append({"tick": tick, "amount": maxf(0.0, amount) * w.value(&"grey_fraction")})
	if not burn: ferocity.last_combat_tick = tick


func grey_health(tick: int) -> float:
	var total := 0.0
	for hit in grey_hits:
		if tick - hit.tick < roundi(w.value(&"grey_window") * 60): total += hit.amount
	return total


func deal(target: CombatUnit, raw: float, tick: int, type: StringName) -> void:
	var resistance := target.stat(&"magic_resist" if type == &"magic" else &"armor")
	target.receive_damage(DamageResolver.resolve(raw, resistance), tick, unit.unit_id, false, type)
	ferocity.last_combat_tick = tick
	hit_reveal[target.unit_id] = tick


func end_stalk() -> void:
	stalk_start = -1
	stalk_end = -1
	marked = null
	unit.statuses.effects.erase("speed_buff:stalk")


func post_tick(tick: int) -> void:
	for i in range(bolas.size() - 1, -1, -1):
		var shot: Dictionary = bolas[i]
		if tick <= shot.tick: continue
		var travel := minf(float(shot.left), maxf(0.01, float(shot.speed)) / 60.0)
		var from: Vector3 = shot.position
		var to: Vector3 = from + shot.direction * travel
		var shape := SphereShape3D.new()
		shape.radius = maxf(0.01, float(shot.width) * 0.5)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, from + Vector3.UP * (shape.radius + 0.05))
		query.motion = to - from
		query.collision_mask = 1
		var fractions := arena.get_world_3d().direct_space_state.cast_motion(query)
		var overlapping := not arena.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
		var wall_hit := overlapping or fractions[0] < 1.0
		var wall_distance := 0.0 if overlapping else travel * fractions[0] if wall_hit else INF
		var victim: CombatUnit
		var best := wall_distance
		for target in arena.units:
			if target.team == unit.team or not target.alive(): continue
			var offset: Vector3 = target.position - from
			var along := clampf(offset.dot(shot.direction), 0.0, travel)
			var closest: Vector3 = from + shot.direction * along
			if target.position.distance_to(closest) <= float(shot.width) * 0.5 + target.stat(&"gameplay_radius") and along < best:
				best = along
				victim = target
		if victim != null:
			deal(victim, shot.damage, tick, &"physical")
			victim.apply_status(&"root" if shot.empowered else &"slow", tick, shot.duration, 0.0 if shot.empowered else shot.slow, &"bola", unit.unit_id)
		if victim != null or wall_hit or shot.left <= travel:
			shot.visual.queue_free()
			bolas.remove_at(i)
		else:
			shot.position = to
			shot.left -= travel
			shot.visual.position = to + Vector3.UP
