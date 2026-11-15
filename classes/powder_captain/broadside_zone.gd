class_name BroadsideZone
extends Node3D
## Tick-owned area damage. Seeded impact points decorate area-wide waves only.

var source: int
var team: int
var units: Array[CombatUnit] = []
var expires_tick: int
var radius: float
var damage: float
var slow_fraction: float
var slow_ticks: int
var waves: Array[Dictionary] = []
var visual_impacts: Array[Dictionary] = []
var _next_wave: int = 0
var _streaks: Array[MeshInstance3D] = []
var _impacts: Array[MeshInstance3D] = []


func configure(owner_unit: CombatUnit, runner: AbilityRunner, point: Vector3, tick: int, targets: Array[CombatUnit]) -> void:
	source = owner_unit.unit_id
	team = owner_unit.team
	units = targets
	position = point
	radius = maxf(0.0, runner.value(&"radius"))
	damage = maxf(0.0, runner.value(&"damage"))
	slow_fraction = clampf(runner.value(&"slow_fraction"), 0.0, 1.0)
	slow_ticks = maxi(0, roundi(runner.value(&"slow_duration") * 60))
	expires_tick = tick + maxi(1, roundi(runner.value(&"duration") * 60))
	var delay := maxi(0, roundi(runner.value(&"first_wave_delay") * 60))
	var cluster_step := maxi(1, roundi(runner.value(&"cluster_interval") * 60))
	var wave_step := maxi(1, roundi(runner.value(&"wave_interval") * 60))
	for cluster in range(clampi(int(runner.value(&"cluster_count")), 1, 32)):
		for wave in range(clampi(int(runner.value(&"waves_per_cluster")), 1, 32)):
			var due := tick + delay + cluster * cluster_step + wave * wave_step
			if due >= expires_tick: continue
			var angle := SimClock.state.rng.randf() * TAU
			var distance := sqrt(SimClock.state.rng.randf()) * radius
			waves.append({"tick": due, "impact": Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)})
	waves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.tick < b.tick)
	var count := clampi(int(runner.value(&"cannonballs_per_wave")), 1, 32)
	for wave in waves:
		# Expand the existing seeded anchor with a local cosmetic RNG. Density
		# changes never consume additional simulation RNG or alter later crits.
		var cosmetic_rng := RandomNumberGenerator.new()
		cosmetic_rng.seed = String(str(wave.impact)).hash()
		for i in range(count):
			if visual_impacts.size() >= 2048: break
			var angle := cosmetic_rng.randf() * TAU
			var distance := sqrt(cosmetic_rng.randf()) * radius
			visual_impacts.append({"tick": mini(expires_tick - 1, int(wave.tick) + cosmetic_rng.randi_range(-5, 5)),
				"impact": Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)})


func _ready() -> void:
	var ring := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	ring.mesh = mesh
	ring.material_override = _material(Color("df9463"))
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(97):
		var angle := TAU * i / 96.0
		mesh.surface_add_vertex(Vector3(cos(angle) * radius, 0.06, sin(angle) * radius))
	mesh.surface_end()
	add_child(ring)
	var shape := CylinderMesh.new()
	shape.top_radius = 0.05
	shape.bottom_radius = 0.09
	shape.height = 1.2
	shape.radial_segments = 6
	var blast := SphereMesh.new()
	blast.radius = 0.45
	blast.height = 0.5
	blast.radial_segments = 8
	blast.rings = 4
	var streak_material := _material(Color("ffd296"))
	var impact_material := _material(Color("d98544"))
	for impact_data in visual_impacts:
		var streak := MeshInstance3D.new()
		streak.mesh = shape
		streak.material_override = streak_material
		streak.hide()
		add_child(streak)
		_streaks.append(streak)
		var impact := MeshInstance3D.new()
		impact.mesh = blast
		impact.material_override = impact_material
		impact.position = impact_data.impact + Vector3.UP * 0.2
		impact.hide()
		add_child(impact)
		_impacts.append(impact)


func simulate(tick: int) -> bool:
	if tick >= expires_tick: return true
	while _next_wave < waves.size() and waves[_next_wave].tick <= tick:
		var wave: Dictionary = waves[_next_wave]
		for target in units:
			if not is_instance_valid(target) or not target.alive() or target.team == team: continue
			if global_position.distance_to(target.global_position) > radius + target.stat(&"gameplay_radius") + 0.00001: continue
			target.receive_damage(DamageResolver.resolve(damage, target.stat(&"magic_resist")), tick, source, false, &"magic")
			target.apply_status(&"slow", tick, slow_ticks, slow_fraction, &"broadside", source)
		EventBus.publish(&"broadside_wave", {"source": source, "wave": _next_wave + 1, "position": global_position, "impact": global_position + wave.impact})
		_next_wave += 1
	return false


func _process(_delta: float) -> void:
	var tick := SimClock.state.tick
	visible = tick < expires_tick
	for i in range(visual_impacts.size()):
		var until: int = visual_impacts[i].tick - tick
		_streaks[i].visible = until > 0 and until <= 15
		_streaks[i].position = visual_impacts[i].impact + Vector3.UP * (0.6 + 8.0 * until / 15.0)
		_impacts[i].visible = until <= 0 and until > -8
		_impacts[i].scale = Vector3.ONE * (1.0 + maxf(0.0, -until) / 8.0)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
