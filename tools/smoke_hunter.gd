extends "res://tools/smoke.gd"


func _start() -> void:
	super._start()
	_room.queue_class("Hunter")
