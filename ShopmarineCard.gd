extends PanelContainer
signal buy_pressed(card_data: Dictionary)

@onready var name_label: Label = $VBox/Name
@onready var desc_label: Label = $VBox/Desc
@onready var cost_label: Label = $VBox/Cost
@onready var buy_button: Button = $VBox/Buy

var _data: Dictionary = {}

func set_card(card_data: Dictionary, coins: int) -> void:
	_data = card_data
	name_label.text = str(card_data.get("name", "Perk"))
	desc_label.text = str(card_data.get("desc", ""))
	cost_label.text = "Cost: %s" % str(card_data.get("cost", 0))
	buy_button.text = "Buy (" + str(card_data.get("cost", 0)) + " Coins)"

	var cost := int(card_data.get("cost", 0))
	buy_button.disabled = coins < cost

func _ready() -> void:
	buy_button.pressed.connect(func():
		buy_pressed.emit(_data)
	)
