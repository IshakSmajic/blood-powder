class_name CombatUnit
extends CharacterBody3D
## Command-driven capsule unit shared by the player and training targets.

var stats: UnitStats
var unit_name: String = "Unit"
var team: int = 0
var unit_id: int = 0
var health: float = 0.0
var state: String = "Idle"
var spawn_point: Vector3
var attack := AttackCycle.new()
var movement := MovementComponent.new()
var order: UnitCommand = UnitCommand.create(UnitCommand.Kind.STOP)
var _pending: UnitCommand
var _pending_tick: int = 0
var _victim: CombatUnit
var _last_repath: int = -999
var _respawn_tick: int = -1
var _visual: Node3D
var _mesh: MeshInstance3D
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
	_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	_mesh.mesh = capsule
	_mesh.position.y = 0.9
	_mesh.material_override = _material(_color)
	_visual.add_child(_mesh)
	var facing := MeshInstance3D.new()
	var tip := BoxMesh.new()
	tip.size = Vector3(0.16, 0.16, 0.5)
	facing.mesh = tip
	facing.material_override = _material(Color("e0b26b"))
	facing.position = Vector3(0, 1.0, -0.58)
	_visual.add_child(facing)
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
	movement.stop()
	order = UnitCommand.create(UnitCommand.Kind.STOP)
	_pending = null
	_victim = null
	_last_repath = -999
	_respawn_tick = -1
	_resume_attack_move = false
	_visual.show()
	reset_physics_interpolation()


func queue_command(command: UnitCommand, issued_tick: int) -> void:
	if not alive():
		return
	_pending = command
	_pending_tick = issued_tick + 1


func simulate(tick: int, units: Array[CombatUnit]) -> void:
	if not alive():
		if tick >= _respawn_tick:
			reset_unit()
			EventBus.publish(&"unit_respawned", {"unit": unit_id})
		return
	health = minf(health, stat(&"max_health"))
	# A command on the hit tick cannot cancel a hit already committed that tick.
	if attack.take_hit(tick):
		_hit(tick)
	if _pending != null and tick >= _pending_tick:
		if attack.cancel(tick):
			EventBus.publish(&"attack_cancelled", {"source": unit_id})
		order = _pending
		_pending = null
		_victim = null
		movement.stop()
		_last_repath = -999
		_resume_attack_move = false
		EventBus.publish(&"order_issued", {"source": unit_id, "kind": order.kind})
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
			_face(movement.simulate(stat(&"move_speed")))
			return
	if order.kind in [UnitCommand.Kind.MOVE, UnitCommand.Kind.ATTACK_MOVE]:
		if _resume_attack_move:
			_last_repath = -999
			_resume_attack_move = false
		if _last_repath < 0:
			movement.set_destination(order.point)
			_last_repath = tick
		_face(movement.simulate(stat(&"move_speed")))
		state = "Moving" if movement.active else "Idle"
		if not movement.active:
			order = UnitCommand.create(UnitCommand.Kind.STOP)
	else:
		movement.stop()
		state = "Holding" if order.kind == UnitCommand.Kind.HOLD else "Idle"


func _choose_target(units: Array[CombatUnit]) -> CombatUnit:
	if order.kind == UnitCommand.Kind.ATTACK:
		return order.target as CombatUnit if is_instance_valid(order.target) and order.target.alive() else null
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


func in_attack_range(target: CombatUnit) -> bool:
	return global_position.distance_to(target.global_position) <= stat(&"attack_range") + stat(&"gameplay_radius") + target.stat(&"gameplay_radius") + 0.001


func _hit(tick: int) -> void:
	if not is_instance_valid(_victim) or not _victim.alive() or not in_attack_range(_victim):
		return
	var crit := SimClock.state.rng.randf() < clampf(stat(&"crit_chance"), 0.0, 1.0)
	var raw := stat(&"attack_damage") * (stat(&"crit_multiplier") if crit else 1.0)
	var damage := DamageResolver.resolve(raw, _victim.stat(&"armor"))
	EventBus.publish(&"attack_hit", {"source": unit_id, "target": _victim.unit_id})
	_victim.receive_damage(damage, tick, unit_id, crit)


func receive_damage(amount: float, tick: int, source: int, crit: bool = false) -> void:
	if not alive():
		return
	health = maxf(0.0, health - maxf(0.0, amount))
	_flash_frames = 3
	EventBus.publish(&"damage_dealt", {"source": source, "target": unit_id, "amount": amount, "crit": crit, "position": global_position})
	if not alive():
		attack.reset()
		_pending = null
		movement.stop()
		state = "Dead"
		_respawn_tick = tick + (180 if team == 0 else 120)
		_visual.hide()
		EventBus.publish(&"unit_died", {"unit": unit_id})


func _process(_delta: float) -> void:
	_label.text = "%s\n%d / %d" % [unit_name, ceili(health), ceili(stat(&"max_health"))]
	_health_fill.scale.x = maxf(0.001, health / maxf(1.0, stat(&"max_health")))
	var material := _mesh.material_override as StandardMaterial3D
	material.albedo_color = Color.WHITE if _flash_frames > 0 else _color
	_flash_frames = maxi(0, _flash_frames - 1)


func _face(direction: Vector3) -> void:
	if direction.length_squared() > 0.001:
		_visual.rotation.y = atan2(-direction.x, -direction.z)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
