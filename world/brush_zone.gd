class_name BrushZone
extends Area3D

@export var extent := Vector3(3.0, 1.0, 1.5)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = extent * 2.0
	shape.shape = box
	add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(extent.x * 2, 0.18, extent.z * 2)
	visual.mesh = mesh
	visual.position.y = 0.09
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("526847")
	visual.material_override = material
	add_child(visual)


func contains(point: Vector3) -> bool:
	var local := to_local(point)
	return absf(local.x) <= extent.x and absf(local.z) <= extent.z and absf(local.y) <= extent.y
