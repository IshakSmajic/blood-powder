class_name KegManager
extends Node3D

signal chain_detonated(tick: int)

var data: KegData = preload("res://data/abilities/powder_keg.tres")
var graph := KegGraph.new()
var views: Dictionary = {}
var units: Array[CombatUnit] = []
var chains: Dictionary = {}
var _queue: Array[Dictionary] = []
var _next_id: int = 1
var _next_chain: int = 1
var _links: MeshInstance3D


func value(field: StringName) -> float:
	return float(DebugConfig.resolve(data.resource_path, field, data.get(field)))


func _ready() -> void:
	_links = MeshInstance3D.new()
	_links.mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	_links.material_override = material
	add_child(_links)


func reserve(point: Vector3, materialize_tick: int) -> KegState:
	var state := KegState.new()
	state.id = _next_id
	_next_id += 1
	state.point = point
	state.materialize_tick = materialize_tick
	graph.nodes[state.id] = state
	var view := PowderKeg.new()
	view.state = state
	view.manager = self
	add_child(view)
	views[state.id] = view
	return state


func materialize(id: int, tick: int) -> void:
	if not graph.nodes.has(id): return
	var state: KegState = graph.nodes[id]
	if not state.pending or tick < state.materialize_tick: return
	state.pending = false
	state.placed_tick = tick
	state.decay_ticks = maxi(1, roundi(value(&"decay_interval") * 60))
	state.next_decay_tick = tick + state.decay_ticks
	state.expires_tick = tick + maxi(1, roundi(value(&"lifetime") * 60))
	EventBus.publish(&"keg_placed", {"unit": 1000 + id, "position": state.point})


func remove(id: int) -> void:
	if graph.nodes.has(id): graph.nodes[id].exploded = true
	graph.nodes.erase(id)
	if views.has(id):
		views[id].queue_free()
		views.erase(id)
	for chain_id in chains.keys():
		var active: bool = false
		for node in graph.nodes.values():
			if node.chain_id == chain_id: active = true
		if not active: chains.erase(chain_id)


func reset() -> void:
	for id in graph.nodes.keys(): remove(id)
	_queue.clear()
	chains.clear()
	_next_id = 1
	_next_chain = 1


func pre_tick(tick: int) -> void:
	graph.connection_distance = maxf(0.0, value(&"connection_distance"))
	for id in graph.nodes.keys():
		var state: KegState = graph.nodes[id]
		if state.pending: continue
		if tick >= state.expires_tick:
			EventBus.publish(&"keg_expired", {"unit": 1000 + id})
			remove(id)
			continue
		while state.health > 1 and tick >= state.next_decay_tick:
			state.health -= 1
			state.next_decay_tick += state.decay_ticks
			EventBus.publish(&"keg_decayed", {"unit": 1000 + id, "value": state.health})
	process_queue(tick)


func hit(id: int, tick: int, payload: Dictionary) -> void:
	if not graph.nodes.has(id): return
	var state: KegState = graph.nodes[id]
	if state.pending: return
	state.health -= 1
	if state.health > 0:
		EventBus.publish(&"keg_hit", {"unit": 1000 + id, "value": state.health})
		return
	if state.chain_id < 0:
		state.chain_id = _next_chain
		_next_chain += 1
		var snapshot := payload.duplicate(true)
		snapshot.damage_raw = float(payload.raw) * (1.0 + value(&"crit_bonus") if payload.crit else 1.0)
		snapshot.penetration = value(&"armor_penetration")
		snapshot.elite_bonus = value(&"elite_bonus")
		snapshot.slow_fraction = value(&"slow_fraction")
		snapshot.slow_ticks = roundi(value(&"slow_duration") * 60)
		chains[state.chain_id] = {"payload": snapshot, "hit_units": {}}
	explode(id, tick)


func explode(id: int, tick: int) -> void:
	if not graph.nodes.has(id): return
	var state: KegState = graph.nodes[id]
	if state.pending: return
	var chain: Dictionary = chains[state.chain_id]
	if not chain.get("passive_reset", false):
		chain.passive_reset = true
		chain_detonated.emit(tick)
	for neighbor in graph.neighbors(id):
		var next: KegState = graph.nodes[neighbor]
		if next.scheduled_tick >= 0: continue
		next.chain_id = state.chain_id
		next.scheduled_tick = maxi(next.materialize_tick, tick + maxi(1, roundi(value(&"chain_delay") * 60)))
		_queue.append({"id": neighbor, "tick": next.scheduled_tick, "chain": state.chain_id})
	var payload: Dictionary = chain.payload
	for target in units:
		if not target.alive() or target.team == 0 or chain.hit_units.has(target.unit_id): continue
		if state.point.distance_to(target.global_position) > value(&"radius") + target.stat(&"gameplay_radius"): continue
		var raw: float = payload.damage_raw
		if target.counts_as_elite: raw += payload.elite_bonus
		var amount := DamageResolver.resolve(raw, target.stat(&"armor"), payload.penetration)
		chain.hit_units[target.unit_id] = true
		target.receive_damage(amount, tick, payload.source, payload.crit)
		target.apply_status(&"slow", tick, payload.slow_ticks, payload.slow_fraction, &"powder_keg", payload.source)
	EventBus.publish(&"keg_exploded", {"unit": 1000 + id, "chain": state.chain_id, "position": state.point, "radius": value(&"radius")})
	remove(id)


func process_queue(tick: int) -> void:
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id if a.tick == b.tick else a.tick < b.tick)
	var remaining: Array[Dictionary] = []
	# New schedules are at least one tick later, so cannot recursively fire now.
	var due := _queue
	_queue = []
	for entry in due:
		if not graph.nodes.has(entry.id): continue
		var state: KegState = graph.nodes[entry.id]
		if entry.tick > tick or state.pending:
			remaining.append(entry)
		else:
			explode(entry.id, tick)
	_queue.append_array(remaining)


func _process(_delta: float) -> void:
	var mesh := _links.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if graph.nodes.size() < 2: return
	var drawing: bool = false
	for id in graph.nodes:
		for neighbor in graph.neighbors(id):
			if neighbor <= id: continue
			if not drawing:
				mesh.surface_begin(Mesh.PRIMITIVE_LINES)
				drawing = true
			var a: KegState = graph.nodes[id]
			var b: KegState = graph.nodes[neighbor]
			mesh.surface_set_color(Color("e6b15f") if a.scheduled_tick >= 0 or b.scheduled_tick >= 0 else Color("473528"))
			mesh.surface_add_vertex(a.point + Vector3.UP * 0.05)
			mesh.surface_add_vertex(b.point + Vector3.UP * 0.05)
	if drawing: mesh.surface_end()


func enemy_hit(id: int) -> void:
	if not graph.nodes.has(id): return
	var state: KegState = graph.nodes[id]
	if state.pending: return
	state.health -= 1
	if state.health <= 0:
		EventBus.publish(&"keg_destroyed", {"unit": 1000 + id, "position": state.point})
		remove(id) # Enemy destruction never triggers an owned explosion or passive reset.
	else:
		EventBus.publish(&"keg_hit", {"unit": 1000 + id, "value": state.health})
