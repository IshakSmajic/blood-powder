extends Node3D
## Same geometry feeds both physics and the runtime navigation bake.


func _ready() -> void:
	box("Floor", Vector3(36, 0.5, 28), Vector3(0, -0.25, 0), Color("646a70"))
	box("NorthWall", Vector3(38, 2, 1), Vector3(0, 1, -14.5))
	box("SouthWall", Vector3(38, 2, 1), Vector3(0, 1, 14.5))
	box("WestWall", Vector3(1, 2, 28), Vector3(-18.5, 1, 0))
	box("EastWall", Vector3(1, 2, 28), Vector3(18.5, 1, 0))
	for x in [-7.0, 7.0]:
		for z in [-4.0, 4.0]:
			box("Pillar", Vector3(2, 3, 2), Vector3(x, 1.5, z))
	box("LowWall", Vector3(6, 1, 1), Vector3(0, 0.5, -1))
	for x in [-11.0, 11.0]:
		var brush := BrushZone.new()
		brush.name = "Brush"
		brush.position = Vector3(x, 0, -7)
		add_child(brush)


func box(node_name: String, size: Vector3, at: Vector3, color: Color = Color("404750"), solid: bool = true) -> void:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = node_name
	body.position = at
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	visual.material_override = material
	body.add_child(visual)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	add_child(body)
