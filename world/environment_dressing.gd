extends Node3D
## Visual-only arena dressing. Existing StaticBody collision and navigation stay authoritative.

const DUNGEON := "res://assets/environment/dungeon/"
const FOLIAGE := "res://assets/environment/foliage/"
static var _scenes: Dictionary = {}

var _decorative_roots: Array[Node3D] = []


func build(geometry: Node3D) -> void:
	# The same box colliders continue to drive physics and nav baking; only their visible
	# primitive meshes are hidden beneath imported scenery.
	_hide_mesh(geometry, "Floor")
	_hide_mesh(geometry, "NorthWall")
	_hide_mesh(geometry, "SouthWall")
	_hide_mesh(geometry, "WestWall")
	_hide_mesh(geometry, "EastWall")
	_hide_mesh(geometry, "LowWall")
	for body in geometry.get_children():
		if body is BrushZone:
			var brush_mesh := body.get_node_or_null("MeshInstance3D") as MeshInstance3D
			if brush_mesh != null: brush_mesh.hide()
	_build_floor()
	_build_outer_walls()
	_build_low_wall()
	_build_pillars(geometry)
	_build_brush(geometry)
	_build_perimeter_props()
	_build_foliage()


func _build_floor() -> void:
	var source_root := _load_scene(DUNGEON + "floor_modular.glb").instantiate()
	var meshes := source_root.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		source_root.free()
		push_error("Floor_Modular has no mesh")
		return
	var source := meshes[0] as MeshInstance3D
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.mesh = source.mesh
	mesh.instance_count = 18 * 14
	var local_transform := _relative_transform(source_root, source)
	var index := 0
	for row in range(14):
		for column in range(18):
			var at := Vector3(-17.0 + column * 2.0, -0.105, -13.0 + row * 2.0)
			mesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, at) * local_transform)
			index += 1
	source_root.free()
	var tiles := MultiMeshInstance3D.new()
	tiles.name = "M5FloorTiles"
	tiles.multimesh = mesh
	add_child(tiles)


func _build_outer_walls() -> void:
	for x in range(-18, 19, 2):
		_add("wall_modular.glb", DUNGEON, Vector3(float(x), 1.0, -14.5))
		_add("wall_modular.glb", DUNGEON, Vector3(float(x), 1.0, 14.5), Vector3.ONE, PI)
	for z in range(-14, 15, 2):
		_add("wall_modular.glb", DUNGEON, Vector3(-18.5, 1.0, float(z)), Vector3.ONE, PI * 0.5)
		_add("wall_modular.glb", DUNGEON, Vector3(18.5, 1.0, float(z)), Vector3.ONE, -PI * 0.5)
	# Low wall panels fit the existing six-by-one-by-one obstacle exactly.
	for x in [-2.0, 0.0, 2.0]:
		_add("wall_modular.glb", DUNGEON, Vector3(x, 0.5, -1.0), Vector3(1.0, 0.5, 2.2))


func _build_low_wall() -> void:
	# A pair of masonry accents along the existing wall keeps its height legible.
	_add("decorative_wall.glb", DUNGEON, Vector3(0, 0.5, -1.52), Vector3(1.0, 0.7, 1.0))
	_add("decorative_wall.glb", DUNGEON, Vector3(0, 0.5, -0.48), Vector3(1.0, 0.7, 1.0), PI)


func _build_pillars(geometry: Node3D) -> void:
	for x in [-7.0, 7.0]:
		for z in [-4.0, 4.0]:
			var body := _find_named(geometry, "Pillar", Vector3(x, 1.5, z))
			if body != null: _hide_mesh_node(body)
			var variant := "column.glb" if int(absf(x + z)) % 2 == 0 else "column2.glb"
			_add(variant, DUNGEON, Vector3(x, 1.5, z), Vector3(1.5, 0.8, 1.5))


func _build_brush(geometry: Node3D) -> void:
	for brush in geometry.get_children():
		if not brush is BrushZone: continue
		var center: Vector3 = brush.position
		for i in range(6):
			var local_x := -2.4 + i * 0.96
			for local_z in [-0.72, 0.72]:
				var yaw := float((i * 29 + int(local_z * 20)) % 360) * PI / 180.0
				_add("grass.glb", FOLIAGE, center + Vector3(local_x, 0.0, local_z), Vector3.ONE * (0.9 + float(i % 3) * 0.13), yaw)
		_add("bush_1.glb", FOLIAGE, center + Vector3(-2.35, 0.0, 0.0), Vector3(0.9, 0.92, 0.9), 0.3)
		_add("bush_1.glb", FOLIAGE, center + Vector3(2.35, 0.0, 0.0), Vector3(0.9, 0.92, 0.9), 2.4)


func _build_perimeter_props() -> void:
	for x in [-14.0, -8.0, 8.0, 14.0]:
		_add("torch.glb", DUNGEON, Vector3(x, 1.25, -13.9))
		_add("torch.glb", DUNGEON, Vector3(x, 1.25, 13.9), Vector3.ONE, PI)
		_add_torch_light(Vector3(x, 2.0, -13.1))
		_add_torch_light(Vector3(x, 2.0, 13.1))
	for z in [-10.0, -4.0, 4.0, 10.0]:
		_add("torch.glb", DUNGEON, Vector3(-17.9, 1.25, z), Vector3.ONE, PI * 0.5)
		_add("torch.glb", DUNGEON, Vector3(17.9, 1.25, z), Vector3.ONE, -PI * 0.5)
		_add_torch_light(Vector3(-17.0, 2.0, z))
		_add_torch_light(Vector3(17.0, 2.0, z))
	for entry in [[-15.7, -11.8], [15.7, -11.8], [-15.7, 11.8], [15.7, 11.8]]:
		var at := Vector3(entry[0], 0.0, entry[1])
		_add("barrel.glb", DUNGEON, at + Vector3(0.0, 0.0, 0.5), Vector3.ONE * 1.35)
		_add("crate.glb", DUNGEON, at + Vector3(1.0, 0.0, -0.2), Vector3.ONE * 1.35, 0.24)
		_add("rock_1.glb", FOLIAGE, at + Vector3(-1.2, 0.0, -0.1), Vector3.ONE * 1.7, 0.8)


func _build_foliage() -> void:
	for at in [Vector3(-16.4, 0, -10.8), Vector3(16.4, 0, -10.8), Vector3(-16.4, 0, 10.8), Vector3(16.4, 0, 10.8)]:
		_add("pinetree_1.glb", FOLIAGE, at, Vector3.ONE * 1.45)
	for at in [Vector3(-13.0, 0, -12.5), Vector3(13.0, 0, -12.5), Vector3(-13.0, 0, 12.5), Vector3(13.0, 0, 12.5)]:
		_add("commontree_1.glb", FOLIAGE, at, Vector3.ONE * 1.35)


func _add_torch_light(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = "TorchGlow"
	light.position = at
	light.light_color = Color("ffb86c")
	light.light_energy = 0.48
	light.omni_range = 4.8
	light.shadow_enabled = false
	add_child(light)


func _add(file_name: String, folder: String, at: Vector3, scale: Vector3 = Vector3.ONE, yaw: float = 0.0) -> Node3D:
	var scene := _load_scene(folder + file_name)
	if scene == null: return null
	var instance := scene.instantiate() as Node3D
	instance.position = at
	instance.scale = scale
	instance.rotation.y = yaw
	instance.name = file_name.get_basename().capitalize()
	add_child(instance)
	_decorative_roots.append(instance)
	return instance


func _load_scene(path: String) -> PackedScene:
	if not _scenes.has(path): _scenes[path] = load(path)
	return _scenes[path] as PackedScene


func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node3D = node
	while current != root:
		chain.push_front(current)
		current = current.get_parent() as Node3D
	var result := Transform3D.IDENTITY
	for child in chain: result = result * child.transform
	return result


func _hide_mesh(geometry: Node3D, body_name: String) -> void:
	for body in geometry.get_children():
		if body is Node3D and body.name == body_name:
			_hide_mesh_node(body)


func _find_named(geometry: Node3D, body_name: String, at: Vector3) -> Node3D:
	for child in geometry.get_children():
		if child is Node3D and child.name == body_name and child.position.distance_squared_to(at) < 0.0001:
			return child
	return null


func _hide_mesh_node(body: Node3D) -> void:
	var mesh := body.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh != null: mesh.hide()
