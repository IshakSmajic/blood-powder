extends Camera3D

var target: Node3D
var locked: bool = true
var zoom: float = 1.0
var focus: Vector3 = Vector3.ZERO
var controls_enabled: bool = true
var _shake_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _shake_phase: float = 0.0


func _ready() -> void:
	# The camera follows an interpolated target in _process; do not interpolate
	# its own transform a second time or treat visual updates as physics motion.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fov = 40.0
	current = true
	snap()


func snap() -> void:
	if is_instance_valid(target):
		focus = target.global_position
	_update_transform()
	reset_physics_interpolation()


func handle_action(action: StringName) -> void:
	match action:
		&"toggle_camera_lock": locked = not locked
		&"zoom_in": zoom = minf(1.25, zoom + 0.05)
		&"zoom_out": zoom = maxf(0.8, zoom - 0.05)


func add_shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_duration, duration)
	_shake_left = maxf(_shake_left, duration)


func clear_shake() -> void:
	_shake_left = 0.0
	_shake_duration = 0.0
	_shake_strength = 0.0


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if controls_enabled and Input.is_action_pressed("center_camera"):
		focus = target.get_global_transform_interpolated().origin
	elif locked:
		focus = focus.lerp(target.get_global_transform_interpolated().origin, 1.0 - exp(-delta / 0.05))
	elif controls_enabled and get_window().has_focus():
		var mouse := get_viewport().get_mouse_position()
		var rect := get_viewport().get_visible_rect()
		if rect.has_point(mouse):
			var pan := Vector3.ZERO
			if mouse.x <= 8.0: pan.x -= 1.0
			if mouse.x >= rect.size.x - 8.0: pan.x += 1.0
			if mouse.y <= 8.0: pan.z -= 1.0
			if mouse.y >= rect.size.y - 8.0: pan.z += 1.0
			focus += pan.normalized() * 25.0 * delta
	focus.x = clampf(focus.x, -22.0, 22.0)
	focus.z = clampf(focus.z, -18.0, 18.0)
	_shake_left = maxf(0.0, _shake_left - delta)
	_shake_phase += delta * 70.0
	if _shake_left <= 0.0:
		_shake_strength = 0.0
		_shake_duration = 0.0
	_update_transform()


func _update_transform() -> void:
	var distance := 17.0 / zoom
	var weight := _shake_left / maxf(0.001, _shake_duration)
	var shake := Vector3(sin(_shake_phase) * _shake_strength * weight, cos(_shake_phase * 1.31) * _shake_strength * weight, 0.0)
	position = focus + Vector3(0, sin(deg_to_rad(56)) * distance, cos(deg_to_rad(56)) * distance) + shake
	look_at(focus)
