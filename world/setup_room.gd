extends Node3D
## M0 grey test room. The capsule is a scale marker, not a playable character.

var _status: Label
var _pause_overlay: PanelContainer
var _paused_before_menu: bool = false


func _ready() -> void:
	SimClock.reset()
	_build_room()
	_build_overlay()
	InputRouter.reset_requested.connect(_reset_room)
	InputRouter.pause_menu_requested.connect(_toggle_menu)


func _process(_delta: float) -> void:
	var mode := "PAUSED" if SimClock.state.paused else "RUNNING"
	_status.text = "SIMULATION %s   |   TICK %06d   |   %.1f×   |   60 Hz" % [
		mode, SimClock.state.tick, SimClock.state.speed_tenths / 10.0]


func _build_room() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("202329")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b4bdca")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-60, -30, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	add_child(light)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 34, 23)
	camera.fov = 40
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	_add_box("Floor", Vector3(36, 0.5, 28), Vector3(0, -0.25, 0), Color("686d73"))
	_add_box("NorthWall", Vector3(38, 2, 1), Vector3(0, 1, -14.5), Color("41464d"))
	_add_box("SouthWall", Vector3(38, 2, 1), Vector3(0, 1, 14.5), Color("41464d"))
	_add_box("WestWall", Vector3(1, 2, 28), Vector3(-18.5, 1, 0), Color("41464d"))
	_add_box("EastWall", Vector3(1, 2, 28), Vector3(18.5, 1, 0), Color("41464d"))
	var marker := MeshInstance3D.new()
	marker.name = "ScaleMarker"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	marker.mesh = capsule
	marker.material_override = _material(Color("8c3535"))
	marker.position = Vector3(0, 0.9, 5)
	add_child(marker)


func _add_box(node_name: String, size: Vector3, at: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SetupOverlay"
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(screen)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	stack.add_child(_label("BLOOD & POWDER", 30, Color("f0e4d4")))
	stack.add_child(_label("M0 / SETUP ROOM", 16, Color("d6aa76")))
	stack.add_child(_label("Grey room and 1.8 m scale marker. Movement and combat begin in M1.", 17))
	_status = _label("", 17)
	stack.add_child(_status)
	var footer := _label("F5 reset   ·   F7 / F8 speed   ·   F9 pause   ·   F10 single tick   ·   Esc menu", 17)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 28
	footer.offset_top = -54
	footer.offset_right = -28
	screen.add_child(footer)
	_pause_overlay = PanelContainer.new()
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_overlay.offset_left = -180
	_pause_overlay.offset_top = -100
	_pause_overlay.offset_right = 180
	_pause_overlay.offset_bottom = 100
	_pause_overlay.visible = false
	screen.add_child(_pause_overlay)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	_pause_overlay.add_child(menu)
	menu.add_child(_label("SETUP PAUSED", 24))
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(_toggle_menu)
	menu.add_child(resume)
	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	menu.add_child(quit_button)


func _label(text: String, size: int, color: Color = Color("d2d7de")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _reset_room() -> void:
	_pause_overlay.hide()
	SimClock.reset()
	DebugConfig.clear_overrides()


func _toggle_menu() -> void:
	if _pause_overlay.visible:
		_pause_overlay.hide()
		SimClock.state.set_paused(_paused_before_menu)
	else:
		_paused_before_menu = SimClock.state.paused
		SimClock.state.set_paused(true)
		_pause_overlay.show()
