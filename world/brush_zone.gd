class_name BrushZone
extends Area3D

@export var extent := Vector3(3.0, 1.0, 1.5)
var circular: bool = false
var show_placeholder: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape3D.new()
	if circular:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = extent.x
		cylinder.height = extent.y * 2.0
		shape.shape = cylinder
	else:
		var box := BoxShape3D.new()
		box.size = extent * 2.0
		shape.shape = box
	add_child(shape)
	if not show_placeholder: return
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
	if circular:
		return Vector2(local.x, local.z).length_squared() <= extent.x * extent.x and absf(local.y) <= extent.y
	return absf(local.x) <= extent.x and absf(local.z) <= extent.z and absf(local.y) <= extent.y
