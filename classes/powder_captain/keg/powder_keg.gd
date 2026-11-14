class_name PowderKeg
extends Node3D
## Nonblocking targetable prototype barrel. All gameplay state lives in KegState.

var state: KegState
var manager: Node3D
var team: int = 0
var unit_name: String = "Powder Keg"
var unit_id: int:
	get: return 1000 + state.id
var health: float:
	get: return float(state.health)
var _body: StandardMaterial3D
var _pips: Label3D
var _ring: MeshInstance3D


func alive() -> bool:
	return not state.pending and not state.exploded and manager.graph.nodes.has(state.id)


func stat(field: StringName) -> float:
	match field:
		&"gameplay_radius": return 0.4
		&"selection_radius": return 0.85
		&"max_health": return 3.0
	return 0.0


func _ready() -> void:
	position = state.point
	unit_name = "Powder Keg #%d" % state.id
	var barrel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.36
	cylinder.bottom_radius = 0.4
	cylinder.height = 0.85
	cylinder.radial_segments = 12
	barrel.mesh = cylinder
	barrel.position.y = 0.425
	_body = StandardMaterial3D.new()
	_body.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_body.albedo_color = Color("785137")
	barrel.material_override = _body
	add_child(barrel)
	for height in [0.18, 0.68]:
		var band := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.365
		torus.outer_radius = 0.405
		torus.rings = 12
		torus.ring_segments = 4
		band.mesh = torus
		band.position.y = height
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("31343a")
		band.material_override = material
		add_child(band)
	_pips = Label3D.new()
	_pips.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_pips.font_size = 42
	_pips.pixel_size = 0.004
	_pips.position.y = 1.2
	add_child(_pips)
	_ring = MeshInstance3D.new()
	_ring.mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("e7b969")
	_ring.material_override = material
	add_child(_ring)
	reset_physics_interpolation()


func _process(_delta: float) -> void:
	_body.albedo_color.a = 0.35 if state.pending else 1.0
	_pips.text = "PLACING" if state.pending else "●".repeat(maxi(0, state.health)) + "○".repeat(maxi(0, 3 - state.health))
	var mesh := _ring.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if state.pending or state.health <= 1: return
	var fraction := clampf((state.next_decay_tick - SimClock.state.tick) / float(state.decay_ticks), 0.0, 1.0)
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(33):
		var angle := TAU * fraction * i / 32.0
		mesh.surface_add_vertex(Vector3(cos(angle) * 0.57, 0.04, sin(angle) * 0.57))
	mesh.surface_end()
