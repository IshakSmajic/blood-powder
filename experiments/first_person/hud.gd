extends Control

var lab: Node3D
var _menu: Control
var _status: Label
var _target: Label
var _feedback: Label
var _abilities: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := label("BLOOD & POWDER   /   FIRST PERSON", Vector2(28, 22), 22, Color("e7c58b"))
	title.add_theme_color_override("font_shadow_color", Color("151c23"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	label("CAPTAIN · FIELD EXPERIMENT", Vector2(28, 53), 14, Color("d8e2e5"))
	_status = label("", Vector2(28, 85), 17, Color.WHITE)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 28
	panel.offset_right = -28
	panel.offset_top = -132
	panel.offset_bottom = -20
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(.035, .05, .065, .82)
	background.content_margin_left = 16
	background.content_margin_right = 16
	background.content_margin_top = 10
	background.content_margin_bottom = 10
	background.border_width_top = 2
	background.border_color = Color("a78c57")
	panel.add_theme_stylebox_override("panel", background)
	add_child(panel)
	var lower := VBoxContainer.new()
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lower)
	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_color_override("font_color", Color("f0d39e"))
	_feedback.add_theme_font_size_override("font_size", 20)
	lower.add_child(_feedback)
	_abilities = Label.new()
	_abilities.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_abilities.add_theme_font_size_override("font_size", 18)
	lower.add_child(_abilities)
	var controls := Label.new()
	controls.text = "WASD move   ·   Mouse look   ·   LMB sword   ·   RMB / Q pistol   ·   E barrel   ·   F heal   ·   R broadside   ·   Esc / Tab menu"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color("e1e5e0"))
	lower.add_child(controls)
	_target = Label.new()
	_target.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_target.offset_left = -260
	_target.offset_right = 260
	_target.offset_top = 22
	_target.offset_bottom = 70
	_target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target.add_theme_font_size_override("font_size", 18)
	_target.add_theme_color_override("font_outline_color", Color("18212b"))
	_target.add_theme_constant_override("outline_size", 4)
	add_child(_target)
	_menu = ColorRect.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.color = Color(.035, .05, .065, .94)
	add_child(_menu)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -290
	box.offset_right = 290
	box.offset_top = -225
	box.offset_bottom = 225
	box.add_theme_constant_override("separation", 14)
	_menu.add_child(box)
	var heading := Label.new()
	heading.text = "POWDER, UP CLOSE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("e7c58b"))
	box.add_child(heading)
	var description := Label.new()
	description.text = "First-person Captain experiment\n\nOne soldier target, sword, flintlock and barrel chains.\nThe target respawns two seconds after defeat.\n\nWASD moves; F replaces W for healing.\nEsc or Tab pauses and releases the mouse."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 18)
	box.add_child(description)
	button(box, "Start / Resume", func() -> void: lab.set_capture(true))
	button(box, "Reset Captain + Target", func() -> void: lab.reset_lab(); lab.set_capture(true))
	button(box, "Return to top-down arena", lab.return_to_arena)
	button(box, "Quit", func() -> void: get_tree().quit())


func button(parent: Control, text: String, callback: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 42
	control.focus_mode = Control.FOCUS_NONE
	control.pressed.connect(callback)
	parent.add_child(control)


func label(text: String, at: Vector2, size: int, color: Color) -> Label:
	var control := Label.new()
	control.text = text
	control.position = at
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	return control


func set_menu_visible(value: bool) -> void:
	_menu.visible = value
	_target.visible = not value


func cooldown(ready_tick: int) -> String:
	return "READY" if ready_tick <= SimClock.state.tick else "%.1fs" % ((ready_tick - SimClock.state.tick) / 60.0)


func _process(_delta: float) -> void:
	if lab.captain == null: return
	_status.text = "HP %d / %d   ·   Target damage %.0f   ·   Hits %d" % [ceili(lab.player.health), ceili(lab.player.stat(&"max_health")), lab.total_damage, lab.hits]
	var target: Node3D = lab.aim_target()
	_target.text = "%s\n%d / %d HP" % [target.unit_name, ceili(target.health), ceili(target.stat(&"max_health"))] if target != null else ""
	_feedback.text = lab.feedback if SimClock.state.tick <= lab.feedback_until else ""
	_abilities.text = "RMB / Q  Flintlock %s     |     E  Barrels %d/%d     |     F  Ration %s     |     R  Broadside %s" % [cooldown(lab.player.ability.ready_tick), lab.captain.charges.available, lab.captain.charges.maximum, cooldown(lab.captain.w.ready_tick), cooldown(lab.captain.r.ready_tick)]
	queue_redraw()


func _draw() -> void:
	if not lab.captured: return
	var center := size / 2.0
	var target: Node3D = lab.aim_target()
	var color := Color("e9ba66") if target != null else Color("eef1e7")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * 5, center + direction * 12, Color("18212b"), 4)
		draw_line(center + direction * 5, center + direction * 12, color, 2)
	draw_circle(center, 1.5, color)
