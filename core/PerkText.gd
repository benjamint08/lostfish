extends RichTextLabel

func _ready() -> void:
	RunState.perks_total.connect(_on_perks_changed)
	RunState.item_gained.connect(_on_item_gained)

func _on_item_gained(id: String) -> void:
	print("Item " + id + " bought")
	
func _on_perks_changed(text: String) -> void:
	self.text = text
