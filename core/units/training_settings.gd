class_name TrainingSettings
extends Resource

@export var dummy_count: int = 3
@export var dummy_armor: float = 50.0
@export var dummy_health: float = 2000.0
@export var infinite_health: bool = true
@export var elite: bool = false

@export_enum("Stationary", "Strafe", "Chase") var behavior: int = 0
@export var strafe_distance: float = 3.0
@export var strafe_speed: float = 3.45
@export var chase_speed: float = 1.5
@export var chase_stop_distance: float = 2.0
@export var enemies_attack_kegs: bool = false
