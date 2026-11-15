extends GutTest

var manager: KegManager
var events: Array[Dictionary] = []
const PAYLOAD = {"raw": 100.0, "crit": false, "source": 0}


func before_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.state.set_paused(true)
	events.clear()
	manager = KegManager.new()
	add_child_autofree(manager)
	EventBus.combat_event.connect(capture)


func after_each() -> void:
	EventBus.combat_event.disconnect(capture)
	DebugConfig.clear_overrides()
	SimClock.reset()


func capture(tick: int, event: StringName, payload: Dictionary) -> void:
	events.append({"tick": tick, "event": event, "payload": payload})


func live(point: Vector3, tick: int = 0, health: int = 3) -> KegState:
	var state := manager.reserve(point, tick)
	manager.materialize(state.id, tick)
	state.health = health
	return state


func clock(tick: int) -> void:
	SimClock.state.tick = tick
	manager.pre_tick(tick)


func detonate(state: KegState, tick: int, payload: Dictionary = PAYLOAD) -> void:
	SimClock.state.tick = tick
	manager.hit(state.id, tick, payload)


func explosions() -> Array[Dictionary]:
	return events.filter(func(row: Dictionary) -> bool: return row.event == &"keg_exploded")


func target(id: int, point: Vector3) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_id = id
	unit.team = 1
	unit.stats = preload("res://data/stats/dummy.tres")
	unit.spawn_point = point
	add_child_autofree(unit)
	manager.units.append(unit)
	return unit


func test_decay_is_exact_and_stops_at_one() -> void:
	var keg := live(Vector3.ZERO)
	clock(59)
	assert_eq(keg.health, 3)
	clock(60)
	assert_eq(keg.health, 2)
	clock(119)
	assert_eq(keg.health, 2)
	clock(120)
	assert_eq(keg.health, 1)
	clock(600)
	assert_eq(keg.health, 1)


func test_decay_tier_is_snapshotted_when_materialized() -> void:
	var first := live(Vector3.ZERO)
	DebugConfig.set_override(manager.data.resource_path, &"decay_interval", 0.5)
	var second := live(Vector3(5, 0, 0))
	assert_eq(first.decay_ticks, 60)
	assert_eq(second.decay_ticks, 30)
	clock(30)
	assert_eq(first.health, 3)
	assert_eq(second.health, 2)


func test_lifetime_expiry_never_explodes() -> void:
	var keg := live(Vector3.ZERO)
	clock(1499)
	assert_true(manager.graph.nodes.has(keg.id))
	clock(1500)
	assert_false(manager.graph.nodes.has(keg.id))
	assert_eq(explosions().size(), 0)


func test_three_keg_line_propagates_at_exact_twenty_tick_intervals() -> void:
	var a := live(Vector3.ZERO, 0, 1)
	live(Vector3(6, 0, 0))
	live(Vector3(12, 0, 0))
	detonate(a, 10)
	clock(29)
	assert_eq(explosions().size(), 1)
	clock(30)
	assert_eq(explosions().size(), 2)
	clock(50)
	var rows := explosions()
	assert_eq(rows.size(), 3)
	assert_eq([rows[0].tick, rows[1].tick, rows[2].tick], [10, 30, 50])
	assert_eq(manager.chains.size(), 0)


func test_overlapping_explosions_damage_each_unit_once_per_chain() -> void:
	var a := live(Vector3.ZERO, 0, 1)
	live(Vector3(3, 0, 0))
	live(Vector3(6, 0, 0))
	var dummy := target(7, Vector3(3, 0, 0))
	detonate(a, 10)
	clock(30)
	assert_almost_eq(dummy.health, 2000.0 - 100.0 / 1.3, 0.0001)
	var damage := events.filter(func(row: Dictionary) -> bool: return row.event == &"damage_dealt")
	assert_eq(damage.size(), 1)


func test_graph_boundary_includes_six_point_nine_but_not_seven() -> void:
	var a := live(Vector3.ZERO)
	var b := live(Vector3(6.9, 0, 0))
	var c := live(Vector3(7, 0, 0))
	assert_true(manager.graph.neighbors(a.id).has(b.id))
	assert_false(manager.graph.neighbors(a.id).has(c.id))


func test_pending_node_waits_for_materialization_and_can_join_chain() -> void:
	var a := live(Vector3.ZERO, 0, 1)
	var pending := manager.reserve(Vector3(6, 0, 0), 60)
	detonate(a, 10)
	assert_eq(pending.scheduled_tick, 60)
	clock(59)
	assert_eq(explosions().size(), 1)
	manager.materialize(pending.id, 59)
	assert_true(pending.pending)
	clock(60)
	assert_eq(explosions().size(), 1)
	manager.materialize(pending.id, 60)
	manager.process_queue(60)
	assert_eq(explosions().size(), 2)
	assert_eq(explosions()[1].tick, 60)


func test_destroying_scheduled_keg_does_not_double_explode() -> void:
	var a := live(Vector3.ZERO, 0, 1)
	var b := live(Vector3(6, 0, 0), 0, 1)
	detonate(a, 10)
	detonate(b, 15)
	clock(30)
	assert_eq(explosions().size(), 2)
	assert_eq(explosions()[0].payload.chain, explosions()[1].payload.chain)


func test_extension_added_after_root_explosion_joins_at_neighbor_explosion() -> void:
	var a := live(Vector3.ZERO, 0, 1)
	live(Vector3(6, 0, 0))
	detonate(a, 10)
	var extension := manager.reserve(Vector3(12, 0, 0), 35)
	clock(30)
	assert_eq(extension.scheduled_tick, 50)
	manager.materialize(extension.id, 35)
	clock(50)
	assert_eq(explosions().size(), 3)


func test_damage_parameters_are_snapshotted_at_root_detonation() -> void:
	var a := live(Vector3.ZERO, 0, 1)
	live(Vector3(6, 0, 0))
	var first := target(8, Vector3(-2, 0, 0))
	var second := target(9, Vector3(8, 0, 0))
	detonate(a, 10, {"raw": 100.0, "crit": true, "source": 0})
	DebugConfig.set_override(manager.data.resource_path, &"armor_penetration", 0.0)
	DebugConfig.set_override(manager.data.resource_path, &"crit_bonus", 1.0)
	clock(30)
	assert_almost_eq(first.health, 2000.0 - 105.0 / 1.3, 0.0001)
	assert_almost_eq(second.health, first.health, 0.0001)


func test_serial_charge_recharge_and_exhaustion() -> void:
	var pool := ChargePool.new()
	pool.reset()
	assert_true(pool.spend(0))
	assert_true(pool.spend(1))
	assert_true(pool.spend(2))
	assert_false(pool.spend(3))
	pool.advance(779)
	assert_eq(pool.available, 0)
	pool.advance(780)
	assert_eq(pool.available, 1)
	assert_eq(pool.next_charge_tick, 1560)
	pool.advance(2340)
	assert_eq(pool.available, 3)
	assert_eq(pool.next_charge_tick, -1)
