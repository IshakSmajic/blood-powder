extends GutTest

var lab: Node3D
var tick: int = 0

func before_each() -> void:
	DebugConfig.clear_overrides()
	lab = load("res://experiments/first_person/captain_lab.tscn").instantiate()
	add_child_autofree(lab)
	for i in 3: await get_tree().physics_frame
	SimClock.state.set_paused(true)
	SimClock.state.tick = 0
	tick = 0
	DebugConfig.set_override(lab.player.stats.resource_path, &"crit_chance", 0.0)

func after_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.reset()

func advance(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
		tick += 1
		SimClock.state.tick = tick
		lab.simulate_tick(tick)

func aim_at(point: Vector3) -> void:
	var direction: Vector3 = point - lab.aim_origin()
	lab.set_look(atan2(-direction.x, -direction.z), atan2(direction.y, Vector2(direction.x, direction.z).length()))

func test_normalized_direct_movement_tick_rate_walls_and_no_automatic_chase() -> void:
	var start: Vector3 = lab.player.position
	lab._keys[KEY_W] = true
	lab._keys[KEY_D] = true
	await advance(60)
	var horizontal := Vector2(lab.player.position.x - start.x, lab.player.position.z - start.z)
	assert_almost_eq(horizontal.length(), lab.player.stat(&"move_speed"), 0.02)
	assert_eq(lab.captain.w.ready_tick, 0, "W is movement, not Ration")
	lab._keys.clear()
	lab.player.position = lab.ground_position(Vector3(48, 0, 0)) + Vector3.UP * 0.04
	lab._keys[KEY_D] = true
	await advance(120)
	assert_lt(lab.player.position.x, 49.5, "Map boundary blocks the player")
	lab._keys.clear()
	lab.player.position = Vector3(0, 0.04, 3)
	lab.dummy.position = Vector3(0, 0, -25)
	await get_tree().physics_frame
	aim_at(lab.dummy.position + Vector3.UP)
	assert_eq(lab.aim_target(), lab.dummy)
	lab._actions.append(&"Q")
	await advance(30)
	assert_almost_eq(lab.player.position.z, 3.0, 0.001, "Out-of-range shots never auto-walk")
	assert_eq(lab.player.ability.ready_tick, 0)
	assert_eq(lab.feedback, "Out of pistol range")

func test_melee_impact_aim_gate_and_shared_flintlock_cast_projectile() -> void:
	lab.player.position = Vector3(0, 0.04, -1)
	aim_at(lab.dummy.position + Vector3.UP)
	lab.player.sword_held = true
	await advance(1)
	lab.player.sword_held = false
	var hit_tick: int = lab.player.attack.hit_tick
	var health: float = lab.dummy.health
	await advance(hit_tick - tick - 1)
	assert_eq(lab.dummy.health, health)
	await advance(1)
	assert_lt(lab.dummy.health, health)
	lab.reset_lab()
	tick = 0
	SimClock.state.set_paused(true)
	lab.player.position = Vector3(0, 0.04, -1)
	aim_at(lab.dummy.position + Vector3.UP)
	lab.player.sword_held = true
	await advance(1)
	lab.player.sword_held = false
	lab.set_look(PI, 0)
	await advance(20)
	assert_eq(lab.dummy.health, lab.dummy.stat(&"max_health"), "Looking away before contact misses")
	lab.reset_lab()
	tick = 0
	SimClock.state.set_paused(true)
	aim_at(lab.dummy.position + Vector3.UP)
	lab._actions.append(&"Q")
	await advance(15)
	assert_eq(lab.dummy.health, lab.dummy.stat(&"max_health"), "No instant hitscan")
	assert_gt(lab.player.ability.ready_tick, 0)
	await advance(30)
	assert_lt(lab.dummy.health, lab.dummy.stat(&"max_health"))
	assert_eq(lab.hits, 1)

func test_ground_placement_aimable_barrels_and_chain_damage() -> void:
	aim_at(Vector3(0, 0, -1))
	lab._actions.append(&"E")
	await advance(32)
	assert_eq(lab.captain.kegs.graph.nodes.size(), 1)
	aim_at(Vector3(3, 0, -1))
	lab._actions.append(&"E")
	await advance(150)
	assert_eq(lab.captain.kegs.graph.nodes.size(), 2)
	var first: Node3D = lab.captain.kegs.views[1]
	assert_eq(first.health, 1.0)
	aim_at(first.position + Vector3.UP * 0.45)
	assert_eq(lab.aim_target(), first, "Nonblocking keg can be targeted by crosshair")
	lab._actions.append(&"Q")
	await advance(60)
	assert_eq(lab.captain.kegs.graph.nodes.size(), 0, "Both linked barrels detonate")
	assert_lt(lab.dummy.health, lab.dummy.stat(&"max_health"))

func test_raw_input_pause_focus_reset_and_render_rng_isolation() -> void:
	# Real viewport input verifies WASD wins over the top-down W ability binding.
	lab.set_capture(true)
	SimClock.state.set_paused(true)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	assert_true(lab._keys.get(KEY_W, false))
	assert_true(lab._actions.is_empty())
	lab.player.sword_held = true
	lab._actions.append(&"E")
	lab._on_focus_lost()
	assert_false(lab.captured)
	assert_true(SimClock.state.paused)
	assert_false(lab.player.sword_held)
	assert_true(lab._keys.is_empty())
	assert_true(lab._actions.is_empty())
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	var rng_state: int = SimClock.state.rng.state
	for i in 10:
		lab._process(1.0 / 60)
		lab.view_model._process(1.0 / 60)
	assert_eq(SimClock.state.rng.state, rng_state)
	assert_eq(lab.player.attack.ready_tick, 0)
	lab.player.health = 20
	lab.reset_lab()
	assert_eq(lab.player.health, lab.player.stat(&"max_health"))
	assert_eq(lab.captain.charges.available, 3)
	assert_eq(lab.dummy.avatar.get_script().resource_path, "res://core/units/infantry_avatar.gd")
	assert_false(lab.player._visual.visible)

func test_wall_occludes_target_and_scene_restores_shared_input_state() -> void:
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 4, 0.4)
	collider.shape = shape
	wall.position = Vector3(0, 1, 0)
	wall.add_child(collider)
	lab.add_child(wall)
	await get_tree().physics_frame
	aim_at(lab.dummy.position + Vector3.UP)
	assert_null(lab.aim_target(), "Cannot acquire a soldier through walls")
	assert_null(lab.aim_ground(), "Barrels cannot be placed through walls")
	lab.get_parent().remove_child(lab)
	assert_false(InputRouter.gameplay_blocked)
	assert_false(SimClock.state.paused)
