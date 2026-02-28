extends RichTextLabel

func _ready() -> void:
	RunState.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(amount: int) -> void:
	self.text = str(amount) + " Coins"
