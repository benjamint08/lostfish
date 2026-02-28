extends Resource
class_name Perk

@export var id: String
@export var display_name: String
@export_multiline var description: String

@export var max_tier: int = 3
@export var base_cost: int = 25
@export var cost_per_tier: int = 15

@export var pierce_bonus_per_tier: int = 1
@export var ammo_bonus_per_tier: int = 3
@export var speed_bonus_per_tier: float = 0.10
@export var projectile_speed_bonus_per_tier: float = 0.00
@export var reload_speed_bonus_per_tier: float = 0.00 
@export var shoot_speed_bonus_per_tier:float = 0.00
@export var damage_decrease_bonus_per_tier:float = 0.00

func cost_for_tier(tier: int) -> int:
	return base_cost + cost_per_tier * (tier - 1)

func desc_for_tier() -> String:
	return "%s" % [description]
