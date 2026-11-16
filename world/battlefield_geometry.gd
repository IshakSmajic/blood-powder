extends Node3D
## Source art and deliberate static proxies; foliage never blocks navigation.

func _ready() -> void:
	var scene: PackedScene = load("res://assets/environment/battlefield/battlefield.glb")
	var map := scene.instantiate()
	map.name = "Battlefield"
	add_child(map)
	for body in map.find_children("*", "StaticBody3D", true, false):
		if "Terrain" in body.name:
			body.name = "Floor"
			body.collision_layer = 5 # Ground sampling uses bit 3; combat walls use bit 1.
	var zones: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/battlefield/zones.json"))
	for zone in zones:
		var brush := BrushZone.new()
		brush.name = zone.name
		brush.position = Vector3(zone.center[0], zone.center[1], zone.center[2])
		brush.extent = Vector3(zone.radius, zone.height / 2.0, zone.radius)
		brush.circular = true
		brush.show_placeholder = false
		add_child(brush)
	# Invisible boundary keeps movement on the authored terrain.
	for axis in [-1.0, 1.0]:
		_boundary(Vector3(axis * 50.5, 4, 0), Vector3(1, 16, 102))
		_boundary(Vector3(0, 4, axis * 50.5), Vector3(100, 16, 1))


func _boundary(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
