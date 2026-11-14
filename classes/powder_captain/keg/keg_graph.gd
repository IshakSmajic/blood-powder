class_name KegGraph
extends RefCounted

var nodes: Dictionary = {}
var connection_distance: float = 6.9


func neighbors(id: int) -> Array[int]:
	var result: Array[int] = []
	if not nodes.has(id): return result
	var origin: KegState = nodes[id]
	for key in nodes:
		if key != id and not nodes[key].exploded and origin.point.distance_squared_to(nodes[key].point) <= connection_distance * connection_distance + 0.00001:
			result.append(key)
	result.sort()
	return result


func spacing_valid(point: Vector3, minimum: float) -> bool:
	for state in nodes.values():
		if point.distance_squared_to(state.point) < minimum * minimum - 0.00001: return false
	return true
