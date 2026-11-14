class_name KegState
extends RefCounted

var id: int
var point: Vector3
var health: int = 3
var pending: bool = true
var exploded: bool = false
var materialize_tick: int
var placed_tick: int = -1
var decay_ticks: int = 60
var next_decay_tick: int = -1
var expires_tick: int = -1
var scheduled_tick: int = -1
var chain_id: int = -1
