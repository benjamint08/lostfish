extends Node

@export var shop_ui_scene: PackedScene = preload("res://roll_ui.tscn")
@export var perks_dir: String = "res://perks"
@export var perk_pool: Array[Perk] = []

signal shop_closed_mgr

var rng := RandomNumberGenerator.new()
var shop_ui: CanvasLayer = null
var shop_open := false
var current_cards: Array = []

func _ready() -> void:
	rng.randomize()
	_load_perks_from_dir(perks_dir)

	if shop_ui_scene == null:
		push_error("ShopManager: shop_ui_scene is not assigned!")
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

	get_tree().current_scene.add_child(shop_ui)

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


func _load_perks_from_dir(dir_path: String) -> void:
	perk_pool.clear()

	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("ShopManager: Can't open perks dir: " + dir_path)
		return

	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		if dir.current_is_dir():
			continue
		if not file.ends_with(".tres"):
			continue

		var perk := load(dir_path + "/" + file) as Perk
		if perk != null:
			perk_pool.append(perk)

	dir.list_dir_end()
	print("Loaded perks:", perk_pool.size())
	RunState.register_perks(perk_pool)


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
