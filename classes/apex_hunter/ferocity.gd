class_name Ferocity
extends RefCounted

var stacks: int = 0
var leap_stack_present: bool = false
var last_combat_tick: int = 0
var empowered_lock: Dictionary = {}
var base_lock: Dictionary = {}


func reset() -> void:
	stacks = 0
	leap_stack_present = false
	last_combat_tick = 0
	empowered_lock.clear()
	base_lock.clear()


func clear() -> void:
	stacks = 0
	leap_stack_present = false


func advance(tick: int, decay_ticks: int = 600) -> void:
	if tick - last_combat_tick >= decay_ticks: clear()


func gain(slot: StringName, tick: int, leap: bool = false) -> void:
	if leap and leap_stack_present: return
	if stacks >= 4: return
	if leap: leap_stack_present = true
	if stacks == 0: last_combat_tick = maxi(last_combat_tick, tick)
	stacks += 1
	if stacks == 4 and slot in [&"Q", &"E"]: empowered_lock[slot] = tick + 6


func empowered() -> bool:
	return stacks == 4


func consume(slot: StringName, tick: int) -> bool:
	if not empowered() or tick < int(empowered_lock.get(slot, 0)): return false
	clear()
	base_lock[slot] = tick + (15 if slot == &"W" else 6)
	return true
