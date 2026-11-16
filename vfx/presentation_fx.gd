extends Node3D
## Short, camera-visible effects only. No collision, timers, or RNG from simulation.

var arena: Node3D
var _leap_trail_left: float = 0.0


func configure(owner_arena: Node3D) -> void:
	arena = owner_arena
	EventBus.combat_event.connect(_on_combat_event)


func _exit_tree() -> void:
	if EventBus.combat_event.is_connected(_on_combat_event):
		EventBus.combat_event.disconnect(_on_combat_event)


func clear_transients() -> void:
	for child in get_children():
		child.free()
	_leap_trail_left = 0.0


func _process(delta: float) -> void:
	if not is_instance_valid(arena) or arena.hunter == null or not arena.hunter.airborne:
		_leap_trail_left = 0.0
		return
	_leap_trail_left -= delta
	if _leap_trail_left <= 0.0:
		_leap_trail_left = 0.055
		_burst(arena.player.avatar.global_position + Vector3.UP * 0.15, Color("c4ded1"), 5, 1.1, 0.28)


func _on_combat_event(_tick: int, event: StringName, payload: Dictionary) -> void:
	var point: Vector3 = payload.get("position", Vector3.ZERO)
	match event:
		&"damage_dealt":
			var critical: bool = payload.get("crit", false)
			_flash_target(int(payload.get("target", -1)))
			_burst(point + Vector3.UP * 1.0, Color("ffd18c") if critical else Color("fff0d6"), 20 if critical else 10, 3.4 if critical else 2.0, 0.38)
			if critical:
				_shake(0.09, 0.04)
				_visual_hit_stop(payload.get("source", -1), payload.get("target", -1), 0.04)
		&"keg_exploded":
			var radius := float(payload.get("radius", 2.2))
			_burst(point + Vector3.UP * 0.45, Color("ff9a43"), 64, 8.0, 0.9)
			_burst(point + Vector3.UP * 0.25, Color("5c4b47"), 34, 3.2, 1.4)
			_ring(point, radius * 0.68, Color("ffb866"), 0.42)
			_scorch(point, radius)
			if is_instance_valid(arena.player):
				var distance: float = arena.player.global_position.distance_to(point)
				_shake(0.25 * clampf(1.0 - distance / 15.0, 0.0, 1.0), 0.25)
		&"leap_started":
			_burst(point + Vector3.UP * 0.12, Color("a6d8bd"), 18, 3.5, 0.45)
		&"leap_landed":
			_burst(point + Vector3.UP * 0.12, Color("d8ead8"), 24, 4.6, 0.55)
			_ring(point, 1.15, Color("d5e4c9"), 0.35)
			_shake(0.15, 0.12)
		&"ability_cast_completed":
			match String(payload.get("ability", "")):
				"flintlock":
					var source := _unit_position(int(payload.get("source", -1)))
					_burst(source + Vector3.UP * 1.2, Color("ffd38a"), 14, 1.5, 0.22)
				"W":
					var color := Color("f2d77a") if payload.get("empowered", false) else Color("77c7cc")
					_ring(point, float(payload.get("radius", 3.5)), color, 0.5)
					_burst(point + Vector3.UP * 0.3, color, 26, 2.8, 0.8)
				"ration":
					_ring(point, 0.9, Color("b8df76"), 0.55)
					_burst(point + Vector3.UP * 0.8, Color("b8df76"), 18, 1.8, 0.7)
				"powder_keg":
					_burst(point + Vector3.UP * 0.7, Color("ffd18c"), 12, 1.3, 0.55)
				"bola":
					_burst(point + Vector3.UP * 0.25, Color("d6e7db"), 12, 2.2, 0.35)
		&"broadside_wave":
			_burst(payload.get("impact", point) + Vector3.UP * 0.1, Color("f39850"), 20, 4.1, 0.6)
		&"elite_slam_started":
			_ring(point, 2.5, Color("e95c51"), 0.8)
		&"elite_slam_hit":
			_burst(point + Vector3.UP * 0.2, Color("ef6958"), 36, 5.0, 0.7)
			_shake(0.35, 0.3)


func _flash_target(unit_id: int) -> void:
	for unit in arena.units:
		if unit.unit_id == unit_id and unit.avatar != null:
			unit.avatar.flash_hit()
			return


func _unit_position(unit_id: int) -> Vector3:
	for unit in arena.units:
		if unit.unit_id == unit_id: return unit.global_position
	return arena.player.global_position


func _visual_hit_stop(source_id: int, target_id: int, seconds: float) -> void:
	for unit in arena.units:
		if unit.unit_id in [source_id, target_id] and unit.avatar != null:
			unit.avatar.hit_stop_visual(seconds)


func _shake(strength: float, seconds: float) -> void:
	if strength > 0.0 and is_instance_valid(arena.camera) and arena.camera.has_method("add_shake"):
		arena.camera.add_shake(strength, seconds)


func _burst(point: Vector3, color: Color, count: int, speed: float, duration: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "CosmeticBurst"
	particles.position = point
	particles.amount = count
	particles.lifetime = duration
	particles.explosiveness = 0.94
	particles.one_shot = true
	particles.emitting = true
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.35
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0, -8.0, 0)
	particles.damping_min = 2.0
	particles.damping_max = 5.0
	particles.scale_amount_min = 0.045
	particles.scale_amount_max = 0.12
	var dot := SphereMesh.new()
	dot.radius = 0.055
	dot.height = 0.11
	var dot_material := StandardMaterial3D.new()
	dot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_material.albedo_color = color
	dot_material.emission_enabled = true
	dot_material.emission = color
	dot_material.emission_energy_multiplier = 1.2
	dot_material.vertex_color_use_as_albedo = false
	particles.mesh = dot
	particles.material_override = dot_material
	add_child(particles)
	_free_later(particles, duration + 0.2)


func _ring(point: Vector3, radius: float, color: Color, duration: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.05, radius - 0.08)
	torus.outer_radius = radius + 0.08
	torus.rings = 32
	torus.ring_segments = 8
	mesh_instance.mesh = torus
	mesh_instance.position = point + Vector3.UP * 0.08
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.82)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.8
	mesh_instance.material_override = material
	add_child(mesh_instance)
	mesh_instance.scale = Vector3.ONE * 0.12
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, duration)
	tween.tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), duration)
	tween.chain().tween_callback(mesh_instance.queue_free)


func _scorch(point: Vector3, radius: float) -> void:
	var scorch := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = radius * 0.72
	disk.bottom_radius = radius * 0.72
	disk.height = 0.025
	disk.radial_segments = 32
	scorch.mesh = disk
	scorch.position = point + Vector3.UP * 0.035
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.13, 0.085, 0.06, 0.34)
	scorch.material_override = material
	add_child(scorch)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(material, "albedo_color", Color(0.13, 0.085, 0.06, 0.0), 3.0)
	tween.tween_property(scorch, "scale", Vector3.ONE * 1.08, 3.0)
	tween.chain().tween_callback(scorch.queue_free)


func _free_later(node: Node, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(node): node.queue_free()
