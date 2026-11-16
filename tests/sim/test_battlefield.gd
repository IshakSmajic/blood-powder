extends GutTest

var arena: Node3D
var tick: int = 0

func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = load("res://world/battlefield.tscn").instantiate()
	add_child_autofree(arena)
	SimClock.state.set_paused(true)
	for i in range(3): await get_tree().physics_frame
	while not arena.navigation_ready: await get_tree().physics_frame
	tick = 0
	SimClock.state.tick = 0

func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()

func advance(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
		tick += 1
		SimClock.state.tick = tick
		arena.simulate_tick(tick)

func test_import_collision_navigation_and_all_eight_concealment_zones() -> void:
	var geometry := arena.get_node("Geometry")
	assert_eq(geometry.get_node("Battlefield").find_children("*", "StaticBody3D", true, false).size(), 59)
	assert_eq(geometry.get_children().filter(func(n: Node) -> bool: return n is BrushZone).size(), 8)
	var map: RID = arena.get_world_3d().navigation_map
	for brush in geometry.get_children():
		if not brush is BrushZone: continue
		var ground: Vector3 = arena.ground_position(brush.position)
		assert_eq(arena.brush_at(ground), brush)
		assert_null(arena.brush_at(ground + Vector3(3.5, 0, 3.5)), "Circular footprint excludes square corners")
		var path := NavigationServer3D.map_get_path(map, Vector3.ZERO, ground, true)
		assert_gt(path.size(), 1, "Reachable bush: " + brush.name)
		assert_lt(path[-1].distance_to(ground), 0.8)
	var query := PhysicsRayQueryParameters3D.create(Vector3(28, 2, -35), Vector3(31, 2, -35), 1)
	assert_false(arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Arch is solid")

func test_imported_map_materials_render_the_authored_vertex_palette() -> void:
	var materials := {}
	var palette := {}
	for node in arena.get_node("Geometry/Battlefield").find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var material: StandardMaterial3D = node.mesh.surface_get_material(surface)
			materials[material] = true
			var colors: PackedColorArray = node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
			for color in colors: palette[color.to_html()] = true
	assert_eq(materials.size(), 2)
	for material in materials:
		assert_true(material.vertex_color_use_as_albedo, material.resource_name + " uses vertex colors")
		assert_false(material.vertex_color_is_srgb, "glTF colors are already linear")
	assert_gt(palette.size(), 20, "Imported meshes retain the varied earth, stone and foliage palette")

func test_sloped_movement_expanded_casts_and_replay() -> void:
	var start: Vector3 = arena.ground_position(Vector3(20, 0, 0))
	var destination: Vector3 = arena.ground_position(Vector3(28, 0, 0))
	arena.player.position = start + Vector3.UP * 0.04
	assert_gt(destination.y, 0.2)
	arena.player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, destination), 0)
	await advance(240)
	assert_lt(arena.player.position.distance_to(destination), 0.7, "Walk uphill to the destination")
	assert_almost_eq(arena.player.position.y, arena.ground_position(arena.player.position).y + 0.04, 0.02)
	assert_true(arena.captain.can_place(arena.ground_position(Vector3(25, 0, 10))))
	assert_true(arena.contains_ground(Vector3(40, 0, 40)))
	assert_false(arena.contains_ground(Vector3(51, 0, 0)))
	# Record from a normal reset so replay owns its full initial state.
	arena.reset_arena()
	SimClock.state.set_paused(true)
	tick = 0
	arena.player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, destination), 0)
	await advance(180)
	var path := "res://.local/battlefield/replay-test.bpr"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	assert_eq(arena.replay.save_run(arena, path), OK)
	assert_eq(arena.load_replay(path), OK)
	SimClock.state.set_paused(true)
	tick = 0
	await advance(180)
	assert_eq(arena.replay.result, "REPLAY MATCH")
	DirAccess.remove_absolute(path)
