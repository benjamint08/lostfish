extends CanvasLayer

signal item_chosen(card_data: Dictionary)
signal shop_closed

@onready var card1 = $Root/Panel/VBox/Cards/Card1
@onready var card2 = $Root/Panel/VBox/Cards/Card2
@onready var card3 = $Root/Panel/VBox/Cards/Card3
@onready var skip_button: Button = $Root/Panel/VBox/Skip

var _open := false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	card1.buy_pressed.connect(_on_buy_pressed)
	card2.buy_pressed.connect(_on_buy_pressed)
	card3.buy_pressed.connect(_on_buy_pressed)
	skip_button.pressed.connect(close_shop)

func open_shop(cards: Array, coins: int) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_open = true
	get_tree().paused = true
	visible = true

	if cards.size() >= 1: card1.set_card(cards[0], coins)
	if cards.size() >= 2: card2.set_card(cards[1], coins)
	if cards.size() >= 3: card3.set_card(cards[2], coins)

	card1.visible = cards.size() >= 1
	card2.visible = cards.size() >= 2
	card3.visible = cards.size() >= 3

	skip_button.grab_focus()

func _on_buy_pressed(card_data: Dictionary) -> void:
	if not _open:
		return
	item_chosen.emit(card_data)

func close_shop() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	shop_closed.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
