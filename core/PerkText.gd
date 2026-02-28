extends RichTextLabel

func _ready() -> void:
	RunState.perks_total.connect(_on_perks_changed)

func _on_perks_changed(text: String) -> void:
	self.text = text
