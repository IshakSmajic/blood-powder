extends CombatUnit
## Isolated direct-control adapter. Shared Captain damage/ability code is reused.

var lab: Node3D
var move_axis := Vector2.ZERO
var yaw: float = 0.0
var pitch: float = -0.07
var sword_held: bool = false

func _ready() -> void:
	super._ready()
	collision_mask = 3 # Static scenery and the soldier, excluding this body's RID.

func reset_unit() -> void:
	super.reset_unit()
	move_axis = Vector2.ZERO
	sword_held = false
	_visual.hide()
	_label.hide()
	_health_fill.hide()


func simulate(tick: int, units: Array[CombatUnit]) -> void:
	# STOP is intentional: no automatic chase, path following or auto-targeting.
	order = UnitCommand.create(UnitCommand.Kind.STOP)
	super.simulate(tick, units)
	_visual.hide()
	if not alive() or statuses.has(&"stun") or active_cast != null: return
	if sword_held and tick >= attack.ready_tick and attack.hit_tick < 0:
		var target: Node3D = lab.aim_target()
		_victim = target if is_instance_valid(target) and in_attack_range(target) else null
		if attack.start(tick, stat(&"attack_speed"), stat(&"windup_fraction")):
			EventBus.publish(&"attack_windup_started", {"source": unit_id, "target": _victim.unit_id if _victim != null else -1, "hit_tick": attack.hit_tick})
	if not statuses.has(&"root"):
		var direction := Basis(Vector3.UP, yaw) * Vector3(move_axis.x, 0, move_axis.y).limit_length(1.0)
		var motion := direction * stat(&"move_speed") * statuses.move_multiplier() / 60.0
		if motion.length_squared() > 0.0:
			var grounded: Vector3 = lab.ground_position(position + motion)
			motion.y = grounded.y + 0.04 - position.y
			var collision := move_and_collide(motion)
			if collision != null:
				var slide := collision.get_remainder().slide(collision.get_normal())
				if slide.length_squared() > 0.000001: move_and_collide(slide)
		velocity = direction * stat(&"move_speed") * statuses.move_multiplier()
	else:
		velocity = Vector3.ZERO
	position = lab.ground_position(position) + Vector3.UP * 0.04
	state = "Attack windup" if attack.hit_tick >= 0 else "Attack backswing" if tick < attack.ready_tick else "Moving" if velocity.length_squared() > 0.001 else "Idle"


func _hit(tick: int, ignore_range: bool = false) -> void:
	# A first-person swing must still aim at its victim at the impact tick.
	if lab.aim_target() == _victim: super._hit(tick, ignore_range)


func _request_cast(command: UnitCommand, tick: int, units: Array[CombatUnit]) -> void:
	if command.slot == &"Q" and is_instance_valid(command.target):
		var reach: float = ability.value(&"range") + stat(&"gameplay_radius") + command.target.stat(&"gameplay_radius")
		if position.distance_to(command.target.position) > reach:
			_cast_failed("Out of pistol range", command.slot)
			return
	if command.slot == &"E" and position.distance_to(command.point) > lab.captain.e.value(&"range"):
		_cast_failed("Place barrels closer", command.slot)
		return
	super._request_cast(command, tick, units)


func _face(_direction: Vector3) -> void:
	pass # Mouse look owns facing in this experiment.
