class_name MovementComponent
extends Node
## Explicit fixed-step motion; never uses render delta or Engine.time_scale.

var body: CharacterBody3D
var agent: NavigationAgent3D
var active: bool = false
var destination: Vector3


func configure(owner_body: CharacterBody3D) -> void:
	body = owner_body
	agent = NavigationAgent3D.new()
	agent.name = "NavigationAgent"
	agent.path_desired_distance = 0.12
	agent.target_desired_distance = 0.1
	agent.radius = 0.65
	if body.has_meta("terrain_arena"):
		# Recast quantizes sloped path heights to voxels. Waypoint tolerance must
		# cover that vertical error, while collision still uses the actual terrain.
		agent.path_desired_distance = 0.65
		agent.target_desired_distance = 0.65
	# Arena uses synchronous crowd separation; asynchronous avoidance would
	# let physics frames outside admitted simulation ticks alter replay motion.
	agent.avoidance_enabled = false
	body.add_child(agent)


func set_destination(point: Vector3) -> void:
	var surface := NavigationServer3D.map_get_closest_point(body.get_world_3d().navigation_map, point)
	# Recast's walkable surface is quantized above the physical floor. Align
	# agent path points with the actor's feet so the first waypoint is reachable.
	if body.has_meta("terrain_arena"):
		var arena: Node3D = body.get_meta("terrain_arena")
		agent.path_height_offset = surface.y - arena.ground_position(surface).y
	else:
		agent.path_height_offset = surface.y - body.global_position.y
	destination = Vector3(surface.x, body.global_position.y, surface.z)
	agent.target_position = surface
	active = true


func stop() -> void:
	active = false
	body.velocity = Vector3.ZERO


func simulate(speed: float) -> Vector3:
	if not active:
		return Vector3.ZERO
	# Updating the path first clears a stale finished flag after retarget/reset.
	var point := agent.get_next_path_position()
	if agent.is_navigation_finished():
		stop()
		return Vector3.ZERO
	var direction := point - body.global_position
	direction.y = 0.0
	var distance := direction.length()
	if distance < 0.0001:
		return Vector3.ZERO
	var motion := direction / distance * minf(maxf(0.0, speed) / 60.0, distance)
	if body.has_meta("terrain_arena"):
		var arena: Node3D = body.get_meta("terrain_arena")
		motion.y = arena.ground_position(body.global_position + motion).y + 0.04 - body.global_position.y
	var collision := body.move_and_collide(motion)
	if collision != null:
		var slide := collision.get_remainder().slide(collision.get_normal())
		if slide.length_squared() > 0.000001:
			body.move_and_collide(slide)
	body.velocity = motion * 60.0
	return direction.normalized()
