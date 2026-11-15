class_name ChargePool
extends RefCounted

var maximum: int = 3
var available: int = 3
var recharge_ticks: int = 780
var next_charge_tick: int = -1


func reset(capacity: int = 3, duration: int = 780) -> void:
	maximum = capacity
	available = capacity
	recharge_ticks = maxi(1, duration)
	next_charge_tick = -1


func configure(capacity: int, duration: int) -> void:
	available = clampi(available + capacity - maximum, 0, capacity)
	maximum = capacity
	recharge_ticks = maxi(1, duration)
	if available == maximum: next_charge_tick = -1


func spend(tick: int) -> bool:
	if available <= 0: return false
	available -= 1
	if next_charge_tick < 0: next_charge_tick = tick + recharge_ticks
	return true


func advance(tick: int) -> void:
	while next_charge_tick >= 0 and tick >= next_charge_tick:
		available += 1
		next_charge_tick = next_charge_tick + recharge_ticks if available < maximum else -1
