extends Node3D
## Miniature opt-in experiment. Does not replace the top-down arena.

const Body = preload("res://experiments/first_person/captain_body.gd")
const ViewModel = preload("res://experiments/first_person/view_model.gd")
const LabHUD = preload("res://experiments/first_person/hud.gd")
var battlefield_enabled: bool = true
var player: CombatUnit
var dummy: EnemyUnit
var units: Array[CombatUnit] = []
var captain: CaptainController
var camera: Camera3D
var hud: Control
var view_model: Node3D
var captured: bool = false
var feedback: String = "Aim at the soldier. Right mouse fires the flintlock."
var feedback_until: int = 240
var hits: int = 0
var total_damage: float = 0.0
var _keys: Dictionary = {}
var _actions: Array[StringName] = []
var _menu_paused: bool = false
var _was_blocked: bool = false
var _old_mouse_mode: int
var _marker: MeshInstance3D
var _marker_material: StandardMaterial3D

func _ready() -> void:
	_was_blocked = InputRouter.gameplay_blocked
	_old_mouse_mode = Input.mouse_mode
	InputRouter.gameplay_blocked = true
	SimClock.reset()
	_build_lighting()
	var geometry: Node3D = load("res://world/battlefield_geometry.gd").new()
	geometry.name = "Geometry"
	add_child(geometry)
	player = Body.new()
	player.lab = self
	player.stats = preload("res://data/stats/captain.tres")
	player.spawn_point = Vector3(0, 0.04, 3)
	player.unit_id = 0
	player.unit_name = "Captain"
	add_child(player)
	units.append(player)
	dummy = EnemyUnit.new()
	dummy.stats = preload("res://data/stats/chaser.tres")
	dummy.stat_adjustments[&"max_health"] = 2000.0
	dummy.spawn_point = Vector3(0, 0, -3)
	dummy.unit_id = 1
	dummy.team = 1
	dummy.unit_name = "Soldier · practice target"
	add_child(dummy)
	dummy._label.hide() # Crosshair HUD already identifies this target.
	units.append(dummy)
	captain = CaptainController.new()
	captain.configure(self, player)
	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.position.y = 1.65
	camera.fov = 78
	camera.near = 0.05
	camera.current = true
	player.add_child(camera)
	view_model = ViewModel.new()
	view_model.unit = player
	camera.add_child(view_model)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = LabHUD.new()
	hud.lab = self
	canvas.add_child(hud)
	_build_marker()
	SimClock.tick_advanced.connect(simulate_tick)
	InputRouter.reset_requested.connect(reset_lab)
	EventBus.combat_event.connect(_on_event)
	get_window().focus_exited.connect(_on_focus_lost)
	# Startup is paused with a clickable Start button, including on F-key-free laptops.
	set_capture(false)


func _exit_tree() -> void:
	InputRouter.gameplay_blocked = _was_blocked
	Input.mouse_mode = _old_mouse_mode
	SimClock.state.set_paused(false)


func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("8dabb6")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c4d3df")
	world.environment.ambient_light_energy = 0.65
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)


func _build_marker() -> void:
	_marker = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.40
	torus.outer_radius = 0.46
	torus.rings = 24
	torus.ring_segments = 4
	_marker.mesh = torus
	_marker_material = StandardMaterial3D.new()
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker.material_override = _marker_material
	add_child(_marker)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key in [KEY_ESCAPE, KEY_TAB] and event.pressed:
			set_capture(not captured)
			get_viewport().set_input_as_handled()
			return
		if not captured: return
		_keys[key] = event.pressed
		if event.pressed:
			match key:
				KEY_Q: _actions.append(&"Q")
				KEY_E: _actions.append(&"E")
				KEY_F: _actions.append(&"W")
				KEY_R: _actions.append(&"R")
		get_viewport().set_input_as_handled()
	elif captured and event is InputEventMouseMotion:
		set_look(player.yaw - event.screen_relative.x * 0.0025, player.pitch - event.screen_relative.y * 0.0025)
		get_viewport().set_input_as_handled()
	elif captured and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: player.sword_held = event.pressed
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed: _actions.append(&"Q")
		get_viewport().set_input_as_handled()


func set_look(yaw: float, pitch: float) -> void:
	player.yaw = wrapf(yaw, -PI, PI)
	player.pitch = clampf(pitch, deg_to_rad(-85), deg_to_rad(85))


func set_capture(value: bool) -> void:
	captured = value
	_keys.clear()
	_actions.clear()
	player.move_axis = Vector2.ZERO
	player.sword_held = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	if value:
		SimClock.state.set_paused(_menu_paused)
	else:
		_menu_paused = SimClock.state.paused
		SimClock.state.set_paused(true)
	hud.set_menu_visible(not value)


func _on_focus_lost() -> void:
	if captured: set_capture(false)


func simulate_tick(tick: int) -> void:
	player.move_axis = Vector2(float(_keys.get(KEY_D, false)) - float(_keys.get(KEY_A, false)), float(_keys.get(KEY_S, false)) - float(_keys.get(KEY_W, false)))
	# Mouse button/key events only queue intent; target resolution happens on a tick.
	if not _actions.is_empty():
		var slot: StringName = _actions.back()
		_actions.clear()
		var command := UnitCommand.create(UnitCommand.Kind.CAST)
		command.slot = slot
		command.target = aim_target() if slot == &"Q" else null
		var ground: Variant = aim_ground()
		if slot in [&"E", &"R"] and ground == null:
			show_feedback("Aim at clear ground", tick)
		else:
			command.point = ground if ground != null else player.position
			player.queue_command(command, tick - 1)
	captain.pre_tick(tick)
	for unit in units: unit.simulate(tick, units)
	captain.post_tick(tick)


func aim_origin() -> Vector3:
	return player.global_position + Vector3.UP * 1.65


func aim_direction() -> Vector3:
	# Authoritative raw look angles; never read the interpolated render camera.
	return Basis.from_euler(Vector3(player.pitch, player.yaw, 0)) * Vector3.FORWARD


func _ray(mask: int) -> Dictionary:
	var origin := aim_origin()
	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim_direction() * 80.0, mask)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


func aim_target() -> Node3D:
	var hit := _ray(3)
	var best: float = aim_origin().distance_to(hit.position) if not hit.is_empty() else 80.0
	var target: Node3D = hit.collider if not hit.is_empty() and hit.collider is CombatUnit and hit.collider.alive() else null
	# Existing kegs deliberately have no blocking collider. Use their actual volume.
	if captain != null:
		for keg in captain.kegs.views.values():
			if not keg.alive(): continue
			var bounds := AABB(keg.global_position + Vector3(-0.42, 0, -0.42), Vector3(0.84, 0.9, 0.84))
			var point: Variant = bounds.intersects_ray(aim_origin(), aim_direction())
			if point != null and aim_origin().distance_to(point) < best:
				best = aim_origin().distance_to(point)
				target = keg
	return target


func aim_ground() -> Variant:
	var hit := _ray(1)
	return hit.position if not hit.is_empty() and hit.normal.y > 0.65 else null


func ground_position(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(Vector3(point.x, 12, point.z), Vector3(point.x, -8, point.z), 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else point


func contains_ground(point: Vector3) -> bool:
	return point.is_finite() and absf(point.x) <= 49.5 and absf(point.z) <= 49.5


func reset_lab() -> void:
	_actions.clear()
	_keys.clear()
	SimClock.reset()
	player.reset_unit()
	dummy.reset_unit()
	player.yaw = 0
	player.pitch = -0.07
	hits = 0
	total_damage = 0
	feedback = "Fresh target. Place two barrels with E, let them decay, then shoot one."
	feedback_until = 360
	view_model.reset_visuals()
	if not captured: SimClock.state.set_paused(true)


func _on_event(tick: int, event: StringName, payload: Dictionary) -> void:
	if event == &"ability_cast_failed" and payload.source == 0:
		show_feedback(payload.reason, tick)
	elif event == &"damage_dealt" and payload.target == 1:
		total_damage += payload.amount
		hits += 1
		show_feedback("%s damage · %d" % [String(payload.type).capitalize(), roundi(payload.amount)], tick)
	elif event == &"unit_died" and payload.unit == 1:
		show_feedback("Target down · respawning in 2 seconds", tick)


func show_feedback(message: String, tick: int) -> void:
	feedback = message
	feedback_until = tick + 180


func _process(_delta: float) -> void:
	camera.rotation = Vector3(player.pitch, player.yaw, 0)
	var ground: Variant = aim_ground()
	_marker.visible = captured and ground != null
	if ground != null:
		_marker.position = ground + Vector3.UP * 0.04
		var valid: bool = player.position.distance_to(ground) <= captain.e.value(&"range") and captain.can_place(ground)
		_marker_material.albedo_color = Color("d7b66f") if valid else Color("cc665a")


func return_to_arena() -> void:
	get_tree().change_scene_to_file("res://world/battlefield.tscn")
