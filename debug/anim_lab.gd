extends Node3D
## Standalone stock-animation inspection and hit-frame marking. Simulation stays paused.

var avatar: CharacterAvatar
var role: StringName = &"attack_a"
var time: float = 0.0
var playing: bool = false
var _info: Label
var _notice: Label
const ROLES: Array[StringName] = [&"attack_a", &"attack_b", &"idle", &"run", &"cast", &"shoot", &"throw", &"death", &"rest"]


func _ready() -> void:
	SimClock.reset()
	SimClock.state.set_paused(true)
	InputRouter.gameplay_blocked = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("242a32")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy = 0.7
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("525963")
	floor.material_override = material
	add_child(floor)
	avatar = CharacterAvatar.new()
	add_child(avatar)
	var camera := Camera3D.new()
	camera.position = Vector3(2.4, 2.0, -3.6)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0, 0.95, 0))
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 24)
	layer.add_child(panel)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 22)
	panel.add_child(_info)
	var character_picker := OptionButton.new()
	character_picker.add_item("Captain prototype / red ranger outfit")
	character_picker.add_item("Training body / flat grey")
	character_picker.item_selected.connect(set_character)
	panel.add_child(character_picker)
	var picker := OptionButton.new()
	for item in ROLES: picker.add_item(String(item))
	picker.item_selected.connect(func(index: int) -> void:
		role = ROLES[index]
		time = 0.0
		playing = false)
	panel.add_child(picker)
	var buttons := HBoxContainer.new()
	panel.add_child(buttons)
	for label in ["Previous frame [,]", "Next frame [.]", "Play / pause [Space]", "Mark hit [M]", "Back to arena [Esc]"]:
		var button := Button.new()
		button.text = label
		buttons.add_child(button)
		match label:
			"Previous frame [,]": button.pressed.connect(func() -> void: step(-1))
			"Next frame [.]": button.pressed.connect(func() -> void: step(1))
			"Play / pause [Space]": button.pressed.connect(func() -> void: playing = not playing)
			"Mark hit [M]": button.pressed.connect(mark_hit)
			_: button.pressed.connect(back)
	_notice = Label.new()
	_notice.text = "Attack hit markers are provisional until you inspect and mark them. Marking saves only the selected project .tres profile."
	panel.add_child(_notice)
	InputRouter.pause_menu_requested.connect(back)


func _exit_tree() -> void:
	InputRouter.gameplay_blocked = false


func _process(delta: float) -> void:
	var length := avatar.animation_player.get_animation(role).length
	if playing:
		time = fposmod(time + delta, length)
	avatar.preview(role, time)
	var profile: AnimProfile = AvatarLibrary.PROFILES.get(role)
	_info.text = "ANIMATION LAB / %s\nFrame %d at 60 fps · %.3f / %.3f s" % [role, roundi(time * 60), time, length]
	if profile != null:
		_info.text += "\nHit marker %.3f s · %s" % [profile.hit_time, "marked" if profile.calibrated else "PROVISIONAL"]


func step(direction: int) -> void:
	playing = false
	time = clampf(time + direction / 60.0, 0.0, avatar.animation_player.get_animation(role).length)


func set_character(index: int) -> void:
	avatar.free()
	avatar = CharacterAvatar.new()
	avatar.dressed = index == 0
	add_child(avatar)
	avatar.preview(role, time)


func mark_hit() -> void:
	var profile: AnimProfile = AvatarLibrary.PROFILES.get(role)
	if profile == null:
		_notice.text = "Select attack_a or attack_b to mark a hit frame."
		return
	var source_clip: Animation = AvatarLibrary.source(2).clips[profile.clip_name]
	if time <= 0.0 or time > source_clip.length:
		_notice.text = "Choose a frame within the strike clip, before its recovery segment."
		return
	var old_time := profile.hit_time
	var old_mark := profile.calibrated
	profile.hit_time = time
	profile.calibrated = true
	var error := ResourceSaver.save(profile, profile.resource_path)
	if error != OK:
		profile.hit_time = old_time
		profile.calibrated = old_mark
		_notice.text = "Could not save profile: " + error_string(error)
	else:
		_notice.text = "Saved " + profile.resource_path + ". Gameplay hit ticks are unchanged."


func back() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://world/arena.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_COMMA: step(-1)
		KEY_PERIOD: step(1)
		KEY_SPACE: playing = not playing
		KEY_M: mark_hit()
