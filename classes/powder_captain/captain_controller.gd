class_name CaptainController
extends RefCounted

var unit: CombatUnit
var arena: Node3D
var kegs: KegManager
var e := AbilityRunner.new()
var w := AbilityRunner.new()
var r := AbilityRunner.new()
var broadsides: Array[BroadsideZone] = []
var passive := AbilityRunner.new()
var charges := ChargePool.new()
var projectiles: Array[Dictionary] = []
var _command: UnitCommand
var _pending_keg: int = -1


func configure(world: Node3D, owner_unit: CombatUnit) -> void:
	arena = world
	unit = owner_unit
	unit.ability.data = preload("res://data/abilities/flintlock.tres")
	passive.data = preload("res://data/abilities/searing_edge.tres")
	r.data = preload("res://data/abilities/broadside.tres")
	w.data = preload("res://data/abilities/ration.tres")
	e.data = preload("res://data/abilities/powder_keg.tres")
	kegs = KegManager.new()
	kegs.name = "Kegs"
	kegs.units = arena.units
	kegs.chain_detonated.connect(_on_chain_detonated)
	arena.add_child(kegs)
	unit.cast_controller = self
	reset()


func reset() -> void:
	unit.ability.reset()
	e.reset()
	w.reset()
	r.reset()
	for zone in broadsides: zone.queue_free()
	broadsides.clear()
	passive.reset()
	charges.reset(clampi(int(e.value(&"charges")), 3, 5), maxi(1, roundi(e.value(&"recharge") * 60)))
	kegs.reset()
	for shot in projectiles:
		if is_instance_valid(shot.visual): shot.visual.queue_free()
	projectiles.clear()
	_command = null
	_pending_keg = -1


func pre_tick(tick: int) -> void:
	charges.configure(clampi(int(e.value(&"charges")), 3, 5), maxi(1, roundi(e.value(&"recharge") * 60)))
	charges.advance(tick)
	kegs.pre_tick(tick)


func request(command: UnitCommand, tick: int) -> Dictionary:
	if command.slot not in [&"Q", &"W", &"E", &"R"]: return {"reason": "Unavailable"}
	var runner: AbilityRunner = e if command.slot == &"E" else w if command.slot == &"W" else r if command.slot == &"R" else unit.ability
	if tick < runner.ready_tick: return {"reason": "On cooldown"}
	if command.slot == &"E":
		if charges.available <= 0: return {"reason": "No charges"}
		if not can_place(command.point): return {"reason": "Invalid placement"}
		if unit.position.distance_to(command.point) > e.value(&"range") + 0.001: return {"approach": true}
	elif command.slot == &"R":
		if not command.point.is_finite() or absf(command.point.x) > 18.0 or absf(command.point.z) > 14.0: return {"reason": "Outside arena"}
	elif command.slot == &"Q":
		if not is_instance_valid(command.target) or not command.target.alive(): return {"reason": "No target"}
		if command.target is CombatUnit and command.target.team == unit.team: return {"reason": "No target"}
		var range_limit: float = unit.ability.value(&"range") + unit.stat(&"gameplay_radius") + command.target.stat(&"gameplay_radius")
		if unit.position.distance_to(command.target.global_position) > range_limit + 0.001: return {"approach": true}
	var reason := runner.start(tick)
	if not reason.is_empty(): return {"reason": reason}
	_command = command
	if command.slot == &"E":
		charges.spend(tick)
		_pending_keg = kegs.reserve(command.point, runner.completion_tick).id
	return {"runner": runner, "name": "powder_keg" if command.slot == &"E" else "ration" if command.slot == &"W" else "broadside" if command.slot == &"R" else "flintlock"}


func can_place(point: Vector3) -> bool:
	if absf(point.x) > 17.5 or absf(point.z) > 13.5: return false
	if not kegs.graph.spacing_valid(point, e.value(&"minimum_spacing")): return false
	var shape := SphereShape3D.new()
	shape.radius = 0.44
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * 0.5)
	query.collision_mask = 1
	return arena.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func interrupt() -> void:
	if _pending_keg >= 0: kegs.remove(_pending_keg)
	_pending_keg = -1
	_command = null


func complete(tick: int) -> void:
	if _command == null: return
	if _command.slot == &"E":
		kegs.materialize(_pending_keg, tick)
		EventBus.publish(&"ability_cast_completed", {"source": unit.unit_id, "ability": "powder_keg", "position": _command.point})
		_pending_keg = -1
	elif _command.slot == &"R":
		var zone := BroadsideZone.new()
		zone.configure(unit, r, _command.point, tick, arena.units)
		arena.add_child(zone)
		broadsides.append(zone)
		EventBus.publish(&"ability_cast_completed", {"source": unit.unit_id, "ability": "broadside", "position": _command.point})
	elif _command.slot == &"W":
		var missing := maxf(0.0, unit.stat(&"max_health") - unit.health)
		unit.heal(maxf(0.0, w.value(&"heal_flat")) + missing * clampf(w.value(&"heal_missing_fraction"), 0.0, 1.0))
		unit.cleanse()
		EventBus.publish(&"ability_cast_completed", {"source": unit.unit_id, "ability": "ration", "position": unit.global_position})
	elif is_instance_valid(_command.target) and _command.target.alive():
		var visual := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		visual.mesh = sphere
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("ffe4a0")
		visual.material_override = material
		visual.position = unit.position + Vector3.UP * 1.1
		arena.add_child(visual)
		visual.reset_physics_interpolation()
		projectiles.append({"target": _command.target, "position": visual.position, "visual": visual, "launch_tick": tick, "speed": maxf(0.1, unit.ability.value(&"projectile_speed"))})
		EventBus.publish(&"ability_cast_completed", {"source": unit.unit_id, "ability": "flintlock", "target": _command.target.unit_id})
	_command = null


func post_tick(tick: int) -> void:
	for i in range(broadsides.size() - 1, -1, -1):
		if broadsides[i].simulate(tick):
			broadsides[i].queue_free()
			broadsides.remove_at(i)
	var remaining: Array[Dictionary] = []
	for shot in projectiles:
		if not is_instance_valid(shot.target) or not shot.target.alive():
			shot.visual.queue_free()
			continue
		var target: Node3D = shot.target
		if tick <= shot.launch_tick:
			remaining.append(shot)
			continue
		var aim := target.global_position + Vector3.UP * (0.5 if target is PowderKeg else 1.1)
		var offset: Vector3 = aim - shot.position
		var step: float = shot.speed / 60.0
		if offset.length() <= step + 0.00001:
			var crit := SimClock.state.rng.randf() < unit.stat(&"crit_chance")
			var raw := (unit.ability.value(&"damage") + unit.ability.value(&"ad_ratio") * unit.stat(&"attack_damage")) * (unit.stat(&"crit_multiplier") if crit else 1.0)
			if target is PowderKeg:
				kegs.hit(target.state.id, tick, {"raw": raw, "crit": crit, "source": unit.unit_id})
			else:
				target.receive_damage(DamageResolver.resolve(raw, target.stat(&"armor")), tick, unit.unit_id, crit)
			EventBus.publish(&"projectile_hit", {"source": unit.unit_id, "target": target.unit_id})
			shot.visual.queue_free()
		else:
			shot.position += offset.normalized() * step
			shot.visual.position = shot.position
			remaining.append(shot)
	projectiles = remaining
	kegs.process_queue(tick)


func basic_hit(target: CombatUnit, tick: int) -> void:
	if target.team == unit.team or tick < passive.ready_tick: return
	passive.start(tick)
	passive.interrupt() # Passive cooldown only; never locks the unit in a cast.
	target.apply_status(&"burn", tick, maxi(0, roundi(passive.value(&"burn_duration") * 60)), maxf(0.0, passive.value(&"damage")), &"searing_edge", unit.unit_id)
	_grant_edge_speed(tick)
	EventBus.publish(&"searing_edge_hit", {"source": unit.unit_id, "target": target.unit_id, "ready_tick": passive.ready_tick})


func _grant_edge_speed(tick: int) -> void:
	unit.apply_status(&"speed_buff", tick, maxi(0, roundi(passive.value(&"speed_duration") * 60)), maxf(0.0, passive.value(&"speed_fraction")), &"searing_edge", unit.unit_id)


func _on_chain_detonated(tick: int) -> void:
	if not unit.alive(): return
	passive.ready_tick = tick
	_grant_edge_speed(tick)
	EventBus.publish(&"searing_edge_reset", {"source": unit.unit_id})


func can_cast_while_stunned(slot: StringName) -> bool:
	return slot == &"W"


func cast_survives_stun(runner: AbilityRunner) -> bool:
	return runner == w
