extends Node

@export var shop_ui_scene: PackedScene = preload("res://roll_ui.tscn")
@export var shopmarine_ui_scene: PackedScene = preload("res://shopmarine_ui.tscn")
@export var perks_dir: String = "res://perks"
@export var perk_pool: Array[Perk] = []
@export var current_items: Array[Item] = []

signal shop_closed_mgr
signal shopmarine_shop_closed_mgr

var rng := RandomNumberGenerator.new()

var shopmarine_ui: CanvasLayer = null
var shopmarine_shop_open := false

var shop_ui: CanvasLayer = null
var shop_open := false
var current_cards: Array = []

func wait_for_game_scene() -> void:
	while true:
		var scene := get_tree().current_scene
		
		if scene != null and scene.scene_file_path == "res://game.tscn":
			return
		
		await get_tree().process_frame
		
func _ready() -> void:
	await wait_for_game_scene()
	rng.randomize()
	_load_perks_from_registry()

	if shop_ui_scene == null:
		push_error("ShopManager: shop_ui_scene is not assigned!")
		return
		
	if shopmarine_ui_scene == null:
		push_error("ShopManager: shopmarine_ui_scene is not assigned!")
		return

	var inst: Node = shop_ui_scene.instantiate()
	if inst == null:
		push_error("ShopManager: Failed to instantiate shop UI scene.")
		return

	shop_ui = inst as CanvasLayer

	if shop_ui == null:
		push_error("ShopManager: roll_ui.tscn root must be a CanvasLayer.")
		inst.queue_free()
		return
		
	inst = shopmarine_ui_scene.instantiate()
	if inst == null:
		push_error("ShopManager: Failed to instantiate Shopmarine UI scene.")
		return
		
	shopmarine_ui = inst as CanvasLayer

	if shopmarine_ui == null:
		push_error("ShopManager: shopmarine_ui.tscn root must be a CanvasLayer.")
		inst.queue_free()
		return
		
	get_tree().current_scene.add_child(shop_ui)
	get_tree().current_scene.add_child(shopmarine_ui)

	if shop_ui.has_signal("perk_chosen"):
		shop_ui.perk_chosen.connect(_on_perk_chosen)
	else:
		push_error("ShopUI missing signal: perk_chosen(card_data)")

	if shop_ui.has_signal("shop_closed"):
		shop_ui.shop_closed.connect(_on_shop_closed)
	else:
		push_error("ShopUI missing signal: shop_closed")

	if shop_ui.has_method("close_shop"):
		shop_ui.close_shop()
	elif "visible" in shop_ui:
		shop_ui.visible = false
		
	if shopmarine_ui.has_signal("item_chosen"):
		shopmarine_ui.item_chosen.connect(_on_item_chosen)
	else:
		push_error("ShopMarineUI missing signal: item_chosen(card_data)")

	if shopmarine_ui.has_signal("shop_closed"):
		shopmarine_ui.shop_closed.connect(_on_shopmarine_shop_closed)
	else:
		push_error("ShopMarineUI missing signal: shop_closed")

	if shopmarine_ui.has_method("close_shop"):
		shopmarine_ui.close_shop()
	elif "visible" in shopmarine_ui:
		shopmarine_ui.visible = false


func _load_perks_from_registry() -> void:
	perk_pool.clear()

	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_error("ShopManager: No current_scene; can't find PerkRegistry.")
		return

	var registry := current_scene.find_child("PerkRegistry", true, false)
	if registry == null:
		push_error("ShopManager: Couldn't find node 'PerkRegistry' in current scene tree.")
		return

	if not registry.has_method("get"):
		push_error("ShopManager: PerkRegistry node exists but doesn't look like the right script.")
		return

	var perks_value = registry.get("perks")
	if perks_value == null or typeof(perks_value) != TYPE_ARRAY:
		push_error("ShopManager: PerkRegistry script must have `@export var perks: Array[Perk]`.")
		return

	for p in perks_value:
		if p != null:
			perk_pool.append(p)

	print("Loaded perks:", perk_pool.size())
	RunState.register_perks(perk_pool)
	
	var items_value = registry.get("items")
	if items_value == null or typeof(items_value) != TYPE_ARRAY:
		push_error("ShopManager: PerkRegistry script must have `@export var perks: Array[Perk]`.")
		return

	for p in items_value:
		if p != null:
			current_items.append(p)

	print("Loaded items:", current_items.size())
	RunState.register_items(current_items)

func open_shopmarine_shop() -> void:
	if shopmarine_shop_open:
		return
	if shopmarine_ui == null or not is_instance_valid(shopmarine_ui):
		push_error("ShopManager: shopmarine_ui instance missing.")
		return
	
	if current_items.is_empty():
		return

	shopmarine_shop_open = true
	shopmarine_ui.open_shop(return_items_in_json(), RunState.coins)

func open_shop() -> void:
	if shop_open:
		return
	if shop_ui == null or not is_instance_valid(shop_ui):
		push_error("ShopManager: shop_ui instance missing.")
		return

	current_cards = roll_three_cards()
	if current_cards.is_empty():
		return

	shop_open = true
	shop_ui.open_shop(current_cards, RunState.coins)


func roll_three_cards() -> Array:
	var available: Array[Perk] = []

	for p in perk_pool:
		if p == null:
			continue
		if RunState.can_upgrade(p):
			available.append(p)

	if available.is_empty():
		return []

	available.shuffle()

	var cards: Array = []
	var count: int = min(3, available.size())

	for i in range(count):
		var perk: Perk = available[i]
		var next_tier := RunState.next_tier(perk)

		cards.append({
			"perk": perk,
			"id": perk.id,
			"name": perk.display_name,
			"tier": next_tier,
			"cost": perk.cost_for_tier(next_tier),
			"desc": perk.desc_for_tier(),
		})

	return cards
	
func return_items_in_json() -> Array:
	var available: Array[Item] = []

	for p in current_items:
		if p == null:
			continue
		if RunState.has_item(p.id) == 0:
			available.append(p)

	if available.is_empty():
		return []

	available.shuffle()

	var cards: Array = []
	var count: int = min(3, available.size())

	for i in range(count):
		var item: Item = available[i]

		cards.append({
			"item": item,
			"id": item.id,
			"name": item.display_name,
			"cost": item.base_cost,
			"desc": item.description
		})

	return cards
	
func _on_item_chosen(card_data: Dictionary) -> void:
	if not shopmarine_shop_open:
		return
		
	var item: Item = card_data["item"]
	var cost: int = int(card_data["cost"])
	
	if item == null:
		return
	if RunState.has_item(item.id) == 1:
		return
	if RunState.coins < cost:
		return
	
	RunState.remove_coins(cost, "Bought " + card_data["name"])
	RunState.apply_item(item)
		
	print(card_data)
	if shopmarine_ui != null and is_instance_valid(shopmarine_ui) and shopmarine_ui.has_method("close_shop"):
		shopmarine_ui.close_shop()

func _on_perk_chosen(card_data: Dictionary) -> void:
	if not shop_open:
		return

	if not card_data.has("perk") or not card_data.has("cost"):
		push_error("ShopManager: invalid card_data received.")
		return

	var perk: Perk = card_data["perk"]
	var cost: int = int(card_data["cost"])

	if perk == null:
		return
	if not RunState.can_upgrade(perk):
		return
	if RunState.coins < cost:
		return

	RunState.remove_coins(cost, "Bought " + card_data["name"] + " " + str(card_data["tier"]))
	RunState.apply_perk(perk)

	if shop_ui != null and is_instance_valid(shop_ui) and shop_ui.has_method("close_shop"):
		shop_ui.close_shop()


func _on_shop_closed() -> void:
	shop_closed_mgr.emit()
	shop_open = false
	current_cards.clear()

func _on_shopmarine_shop_closed() -> void:
	shopmarine_shop_closed_mgr.emit()
	shopmarine_shop_open = false
	current_items.clear()
