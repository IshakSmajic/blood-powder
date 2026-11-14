class_name UnitCommand
extends RefCounted
## Mouse and future AI commands share this representation.

enum Kind { MOVE, ATTACK, ATTACK_MOVE, STOP, HOLD, CAST }
var kind: Kind = Kind.STOP
var point: Vector3 = Vector3.ZERO
var target: Node3D


static func create(type: Kind, at: Vector3 = Vector3.ZERO, unit: Node3D = null) -> UnitCommand:
	var command := UnitCommand.new()
	command.kind = type
	command.point = at
	command.target = unit
	return command
