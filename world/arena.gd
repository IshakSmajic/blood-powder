extends Node3D

const Geometry = preload("res://world/arena_geometry.gd")
const Camera = preload("res://world/camera_rig/arena_camera.gd")
const HUD = preload("res://ui/sandbox_hud.gd")

var player: CombatUnit
var units: Array[CombatUnit] = []
var camera: Camera3D
var selected: Node3D
var captain_enabled: bool = true
var captain: CaptainController
var navigation_ready: bool = false
var attack_move_armed: bool = false
var show_states: bool = false
var show_ranges: bool = false
var _armed_until: int = 0
var _region: NavigationRegion3D
var _hud: CanvasLayer
var _right_ground_held: bool = false
var _last_hold_tick: int = 0
var _menu_open: bool = false
var _paused_before_menu: bool = false
var _debug_mesh: MeshInstance3D
var _effects: Node3D
var _queued_debug_statuses: Array[StringName] = []
var combat_log := CombatLog.new()


func _ready() -> void:
	SimClock.reset()
	InputRouter.gameplay_blocked = false
	_build_lighting()
	var geometry := Geometry.new()
	geometry.name = "Geometry"
	add_child(geometry)
	_build_navigation(geometry)
	player = _add_unit(0, 0, "Powder Captain", Vector3(0, 0, 11), preload("res://data/stats/captain.tres"))
	for i in range(3):
		_add_unit(i + 1, 1, "Dummy %d" % (i + 1), Vector3((i - 1) * 3, 0, -8), preload("res://data/stats/dummy.tres"))
	if captain_enabled:
		captain = CaptainController.new()
		captain.configure(self, player)
	selected = player
	camera = Camera.new()
	camera.name = "Camera"
	camera.target = player
	add_child(camera)
	_effects = Node3D.new()
	_effects.name = "TransientEffects"
	add_child(_effects)
	_debug_mesh = MeshInstance3D.new()
	_debug_mesh.mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("c9b476")
	_debug_mesh.material_override = material
	add_child(_debug_mesh)
	_hud = HUD.new()
	_hud.arena = self
	add_child(_hud)
	_hud.resume_requested.connect(_toggle_menu)
	_hud.restart_requested.connect(reset_arena)
	InputRouter.reset_requested.connect(reset_arena)
	InputRouter.pause_menu_requested.connect(_on_escape)
	InputRouter.world_action.connect(_on_action)
	SimClock.tick_advanced.connect(simulate_tick)
	EventBus.combat_event.connect(_on_combat_event)
	# The navigation server synchronizes the runtime-baked region at a physics boundary.
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_ready = _region.navigation_mesh.get_polygon_count() > 0
	if not navigation_ready:
		push_error("Arena navigation bake produced no polygons")


func _exit_tree() -> void:
	InputRouter.gameplay_blocked = false


func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("22272e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b2bbc9")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_navigation(geometry: Node3D) -> void:
	_region = NavigationRegion3D.new()
	_region.name = "Navigation"
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.75
	mesh.agent_height = 2.0
	mesh.agent_max_climb = 0.0
	mesh.agent_max_slope = 20.0
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, geometry)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	_region.navigation_mesh = mesh
	add_child(_region)


func _add_unit(id: int, team: int, label: String, at: Vector3, data: UnitStats) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.name = "Player" if id == 0 else "Dummy%d" % id
	unit.unit_id = id
	unit.team = team
	unit.unit_name = label
	unit.spawn_point = at
	unit.stats = data
	add_child(unit)
	units.append(unit)
	return unit


func simulate_tick(tick: int) -> void:
	if not navigation_ready:
		return
	for kind in _queued_debug_statuses:
		match kind:
			&"cleanse": player.cleanse()
			&"burn": player.apply_status(kind, tick, 150, 24.0)
			&"slow": player.apply_status(kind, tick, 180, 0.5)
			&"speed_buff": player.apply_status(kind, tick, 180, 0.5)
			_: player.apply_status(kind, tick, 120)
	_queued_debug_statuses.clear()
	if captain != null: captain.pre_tick(tick)
	if attack_move_armed and tick >= _armed_until:
		attack_move_armed = false
	if _right_ground_held and not _menu_open and tick - _last_hold_tick >= 6:
		_issue_ground_move()
		_last_hold_tick = tick
	for unit in units:
		unit.simulate(tick, units)
	if captain != null: captain.post_tick(tick)


func _on_action(action: StringName) -> void:
	if action == &"move_release":
		_right_ground_held = false
		return
	if _menu_open:
		return
	match action:
		&"ability_q":
			if player.alive():
				var command := UnitCommand.create(UnitCommand.Kind.CAST)
				if captain != null: command.target = _flintlock_target()
				player.queue_command(command, SimClock.state.tick)
			else:
				EventBus.publish(&"ability_cast_failed", {"source": player.unit_id, "reason": "Dead"})
		&"ability_w":
			if captain == null: return
			if not player.alive():
				EventBus.publish(&"ability_cast_failed", {"source": player.unit_id, "reason": "Dead", "slot": &"W"})
				return
			var command := UnitCommand.create(UnitCommand.Kind.CAST)
			command.slot = &"W"
			player.queue_command(command, SimClock.state.tick)
		&"ability_e":
			if captain == null: return
			if not player.alive():
				EventBus.publish(&"ability_cast_failed", {"source": player.unit_id, "reason": "Dead", "slot": &"E"})
				return
			var point: Variant = _ground_point()
			if point == null: return
			var command := UnitCommand.create(UnitCommand.Kind.CAST, point)
			command.slot = &"E"
			player.queue_command(command, SimClock.state.tick)
		&"toggle_camera_lock", &"zoom_in", &"zoom_out":
			camera.handle_action(action)
		&"debug_panel": _hud.toggle_debug()
		&"debug_ranges": show_ranges = not show_ranges
		&"debug_states": show_states = not show_states
		&"debug_log": _hud.toggle_log()
		&"attack_move":
			attack_move_armed = true
			_armed_until = SimClock.state.tick + 180
		&"stop", &"hold_position":
			_right_ground_held = false
			attack_move_armed = false
			var kind := UnitCommand.Kind.STOP if action == &"stop" else UnitCommand.Kind.HOLD
			player.queue_command(UnitCommand.create(kind), SimClock.state.tick)
		&"move_attack":
			attack_move_armed = false
			var picked := _pick_unit()
			if picked != null and (picked is PowderKeg or picked.team != player.team) and picked.alive():
				_right_ground_held = false
				player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, picked), SimClock.state.tick)
				_click_ring(picked.global_position, Color("c94e43"))
			else:
				_right_ground_held = true
				_last_hold_tick = SimClock.state.tick
				_issue_ground_move()
		&"select_inspect":
			if attack_move_armed:
				var point: Variant = _ground_point()
				if point != null:
					player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK_MOVE, point), SimClock.state.tick)
					_click_ring(point, Color("d1a34e"))
				attack_move_armed = false
			else:
				selected = _pick_unit()


func _issue_ground_move() -> void:
	var point: Variant = _ground_point()
	if point != null and navigation_ready:
		player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, point), SimClock.state.tick)
		_click_ring(point, Color("84b37a"))


func queue_debug_status(kind: StringName) -> void:
	_queued_debug_statuses.append(kind)


func _ground_point() -> Variant:
	var mouse := get_viewport().get_mouse_position()
	return Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))


func _targets() -> Array[Node3D]:
	var targets: Array[Node3D] = []
	for unit in units: targets.append(unit)
	if captain != null:
		for view in captain.kegs.views.values(): targets.append(view)
	return targets


func _flintlock_target() -> Node3D:
	var point: Variant = _ground_point()
	if point == null: return null
	var hovered := _pick_unit()
	if hovered != null and (hovered is PowderKeg or hovered.team != player.team): return hovered
	var best: float = 1.5 * 1.5 + 0.00001
	var nearest: Node3D
	for target in _targets():
		if not target.alive() or (target is CombatUnit and target.team == player.team): continue
		var distance: float = point.distance_squared_to(target.global_position)
		if distance < best:
			best = distance
			nearest = target
	return nearest


func _pick_unit() -> Node3D:
	var point: Variant = _ground_point()
	if point == null:
		return null
	var nearest: Node3D
	var best: float = INF
	for unit in _targets():
		var distance: float = unit.global_position.distance_squared_to(point)
		if unit.alive() and distance <= pow(unit.stat(&"selection_radius"), 2) and distance < best:
			best = distance
			nearest = unit
	return nearest


func _on_escape() -> void:
	if attack_move_armed:
		attack_move_armed = false
	else:
		_toggle_menu()


func _toggle_menu() -> void:
	_menu_open = not _menu_open
	_right_ground_held = false
	if _menu_open:
		_paused_before_menu = SimClock.state.paused
		SimClock.state.set_paused(true)
	else:
		SimClock.state.set_paused(_paused_before_menu)
	InputRouter.gameplay_blocked = _menu_open
	camera.controls_enabled = not _menu_open
	_hud.show_menu(_menu_open)


func reset_arena() -> void:
	SimClock.reset()
	# Session tuning stays active until the editor/game is restarted.
	for unit in units:
		unit.reset_unit()
	for effect in _effects.get_children():
		effect.queue_free()
	_menu_open = false
	InputRouter.gameplay_blocked = false
	camera.controls_enabled = true
	_right_ground_held = false
	attack_move_armed = false
	_queued_debug_statuses.clear()
	_hud.show_menu(false)
	_hud.clear_log()
	combat_log.clear()
	selected = player
	camera.snap()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var immediate := _debug_mesh.mesh as ImmediateMesh
	immediate.clear_surfaces()
	if show_ranges:
		immediate.surface_begin(Mesh.PRIMITIVE_LINES)
		_draw_circle(immediate, player.global_position, player.stat(&"attack_range") + player.stat(&"gameplay_radius"))
		_draw_circle(immediate, player.global_position, player.ability.value(&"radius"))
		if captain != null:
			for node in captain.kegs.graph.nodes.values(): _draw_circle(immediate, node.point, captain.e.value(&"radius"))
		for unit in units:
			_draw_circle(immediate, unit.global_position, unit.stat(&"gameplay_radius"))
		if player.movement.active:
			var path := player.movement.agent.get_current_navigation_path()
			for i in range(1, path.size()):
				immediate.surface_add_vertex(path[i - 1] + Vector3.UP * 0.08)
				immediate.surface_add_vertex(path[i] + Vector3.UP * 0.08)
		immediate.surface_end()


func _draw_circle(mesh: ImmediateMesh, center: Vector3, radius: float) -> void:
	for i in range(48):
		for angle in [TAU * i / 48.0, TAU * (i + 1) / 48.0]:
			mesh.surface_add_vertex(center + Vector3(cos(angle) * radius, 0.06, sin(angle) * radius))


func _click_ring(point: Vector3, color: Color, radius: float = 0.31, grow: bool = false) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.01, radius - 0.03)
	torus.outer_radius = maxf(0.04, radius + 0.03)
	torus.rings = 16
	torus.ring_segments = 6
	ring.mesh = torus
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	ring.material_override = material
	ring.position = point + Vector3.UP * 0.06
	_effects.add_child(ring)
	if grow: ring.scale = Vector3.ONE * 0.1
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3.ONE if grow else Vector3.ONE * 0.1, 0.4)
	tween.tween_callback(ring.queue_free)


func _on_combat_event(tick: int, event: StringName, payload: Dictionary) -> void:
	combat_log.record(tick, event, payload)
	if event == &"keg_exploded":
		_click_ring(payload.position, Color("f09d46"), payload.radius, true)
	if event == &"ability_cast_completed" and payload.get("ability", "") == "training_pulse":
		_click_ring(payload.position, Color("6cb8dc"), payload.radius, true)
	if event == &"ability_cast_completed" and payload.get("ability", "") == "ration":
		_click_ring(payload.position, Color("80cf79"), 1.0, true)
	if event not in [&"damage_dealt", &"healing_received"]:
		return
	var number := Label3D.new()
	number.text = str(roundi(payload.amount)) + ("!" if payload.get("crit", false) else "")
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.font_size = 64 if payload.get("crit", false) else 46
	number.pixel_size = 0.005
	var type: StringName = payload.get("type", &"physical")
	number.modulate = Color("80cf79") if event == &"healing_received" else Color("7db9ef") if type == &"magic" else Color("ef9b4d") if type == &"true" else Color.WHITE
	number.position = payload.position + Vector3(0, 2.0, 0)
	_effects.add_child(number)
	var tween := number.create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y + 0.8, 0.7)
	tween.tween_property(number, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(number.queue_free)
