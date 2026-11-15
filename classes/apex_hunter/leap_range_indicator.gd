class_name LeapRangeIndicator
extends MeshInstance3D
## Presentation only: the ring reaches the nearest edge of a valid leap target.

var _radius: float = -1.0
var _width: float = -1.0
var _material := StandardMaterial3D.new()


func _ready() -> void:
	mesh = ImmediateMesh.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	hide()


func update_visual(owner_unit: CombatUnit, controller: HunterController, tick: int) -> void:
	visible = controller != null and not controller.airborne and controller.leap_eligible(tick)
	if not visible: return
	global_position = owner_unit.get_global_transform_interpolated().origin
	var radius := maxf(0.0, controller.passive.value(&"leap_range")) + owner_unit.stat(&"gameplay_radius")
	var width := maxf(0.02, controller.passive.value(&"leap_ring_width"))
	if not is_equal_approx(radius, _radius) or not is_equal_approx(width, _width):
		_radius = radius
		_width = width
		var geometry := mesh as ImmediateMesh
		geometry.clear_surfaces()
		geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_annulus(geometry, radius, width + 0.1, 0.065, Color(0.12, 0.15, 0.13))
		_annulus(geometry, radius, width, 0.075, Color.WHITE)
		geometry.surface_end()
	_material.albedo_color = Color("f4d17e") if controller.camouflaged(tick) else Color("8ed5a4")


func _annulus(geometry: ImmediateMesh, radius: float, width: float, height: float, color: Color) -> void:
	var inner := maxf(0.0, radius - width * 0.5)
	var outer := radius + width * 0.5
	geometry.surface_set_color(color)
	for i in range(128):
		var a := Vector3(cos(TAU * i / 128.0), 0, sin(TAU * i / 128.0))
		var b := Vector3(cos(TAU * (i + 1) / 128.0), 0, sin(TAU * (i + 1) / 128.0))
		for point in [a * inner, a * outer, b * outer, a * inner, b * outer, b * inner]:
			geometry.surface_add_vertex(point + Vector3.UP * height)
