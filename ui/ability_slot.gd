extends Control
## Code-drawn prototype ability slot with a radial cooldown sweep.

var ability: AbilityRunner
var key_label: String = "Q"
var usable: bool = true
var _flash_left: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(76, 70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	queue_redraw()


func flash_failure() -> void:
	_flash_left = 0.3


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("343d4a") if ability != null else Color("282d34"))
	var center := size * 0.5
	if ability != null:
		draw_circle(center, 15.0, Color("719ec7") if usable else Color("5c6570"), false, 2.0)
		draw_line(center - Vector2(10, 0), center + Vector2(10, 0), Color("a8c9e6"), 2)
		draw_line(center - Vector2(0, 10), center + Vector2(0, 10), Color("a8c9e6"), 2)
		var remaining := maxi(0, ability.ready_tick - SimClock.state.tick)
		if remaining > 0:
			var fraction := clampf(remaining / float(maxi(1, ability.cooldown_ticks)), 0.0, 1.0)
			if fraction >= 0.999:
				draw_rect(rect, Color(0.05, 0.07, 0.1, 0.75))
			else:
				var polygon := PackedVector2Array([center])
				for i in range(49):
					var angle := -PI / 2.0 + TAU * fraction * i / 48.0
					polygon.append(center + Vector2(cos(angle), sin(angle)) * size.length())
				draw_colored_polygon(polygon, Color(0.05, 0.07, 0.1, 0.75))
			var seconds := remaining / 60.0
			var text := "%.1f" % seconds if seconds < 3 else str(ceili(seconds))
			draw_string(ThemeDB.fallback_font, Vector2(18, 47), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_rect(rect, Color("dc655b") if _flash_left > 0 else Color("b89a6a") if usable else Color("58616a"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(6, 17), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
