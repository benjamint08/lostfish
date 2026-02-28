extends Node

var coins: int = 0
var perk_tiers := {}
var perk_defs := {}

signal coins_changed(new_amount: int)
signal coins_gained(amount: int, reason: String)
signal coins_removed(amount: int, reason: String)
signal perks_total(text: String)

func register_perks(perks: Array[Perk]) -> void:
	perk_defs.clear()
	for p in perks:
		perk_defs[p.id] = p
		
func get_tier(perk_id: String) -> int:
	return int(perk_tiers.get(perk_id, 0))
	
func has_perk(perk_id: String) -> int:
	return int(perk_tiers.get(perk_id, 0))

func can_upgrade(perk: Perk) -> bool:
	return get_tier(perk.id) < perk.max_tier

func next_tier(perk: Perk) -> int:
	return get_tier(perk.id) + 1

func apply_perk(perk: Perk) -> void:
	var t := next_tier(perk)
	if t > perk.max_tier:
		return
	perk_tiers[perk.id] = t
	perks_total.emit(_build_perks_text())
	
func get_perk_data(perk_id: String, tier: int = -1) -> Dictionary:
	if not perk_defs.has(perk_id):
		return {}

	var perk: Perk = perk_defs[perk_id]

	if tier == -1:
		tier = has_perk(perk_id)

	if tier <= 0:
		return {}

	return {
		"id": perk.id,
		"name": perk.display_name,
		"tier": tier,
		"max_tier": perk.max_tier,
		"cost": perk.cost_for_tier(tier),
		"desc": perk.desc_for_tier(),

		"pierce_bonus": perk.pierce_bonus_per_tier * tier,
		"ammo_bonus": perk.ammo_bonus_per_tier * tier,
		"speed_bonus": perk.speed_bonus_per_tier * tier,
		"projectile_speed_bonus": perk.projectile_speed_bonus_per_tier * tier,
		"reload_speed_bonus": perk.reload_speed_bonus_per_tier * tier,
		"shoot_speed_bonus": perk.shoot_speed_bonus_per_tier * tier,
		"damage_decrease_bonus": perk.damage_decrease_bonus_per_tier * tier
	}
	
func _build_perks_text() -> String:
	if perk_tiers.is_empty():
		return ""

	var parts: Array[String] = []

	for id in perk_tiers.keys():
		var tier: int = int(perk_tiers[id])
		if tier <= 0:
			continue

		var name: String = get_perk_data(id)["name"]
		parts.append("%s %d" % [name, tier])

	parts.sort()
	return ", ".join(parts)

func get_pierce_count() -> int:
	var t := get_tier("passthrough")
	return t * 1

func get_ammo_bonus() -> int:
	return get_tier("lungs") * 4

func get_speed_multiplier() -> float:
	return 1.0 + get_tier("speed") * 0.12
	
func add_coins(addValue: int, reason: String) -> void:
	coins += addValue
	coins_gained.emit(addValue, reason)
	coins_changed.emit(coins)
	
func remove_coins(removeValue: int, reason: String) -> void:
	coins -= removeValue
	coins_changed.emit(coins)
	coins_removed.emit(removeValue, reason)
		
