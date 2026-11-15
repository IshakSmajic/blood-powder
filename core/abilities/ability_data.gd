class_name AbilityData
extends Resource
## Shared tunable fields for ability resources.

@export var display_name: String = "Training Pulse"
@export var cooldown: float = 3.0
@export var cast_time: float = 0.25
@export var radius: float = 3.5
@export var damage: float = 60.0
@export var slow_fraction: float = 0.4
@export var slow_duration: float = 2.0
@export var range: float = 0.0
@export var projectile_speed: float = 0.0
@export var ad_ratio: float = 0.0

@export var heal_flat: float = 0.0
@export var heal_missing_fraction: float = 0.0

@export var burn_duration: float = 2.5
@export var speed_fraction: float = 0.25
@export var speed_duration: float = 2.0
