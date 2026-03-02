extends Node

@onready var seanade_countdown_text: Label = $"../SeanadeContainer/Countdown"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RunState.item_gained.connect(_on_item_gained)
	RunState.seanade_used.connect(_on_seanade_used)

func _on_seanade_used() -> void:
	for i in range(30, 0, -1):
		seanade_countdown_text.text = str(i)
		await get_tree().create_timer(1.0).timeout
	seanade_countdown_text.text = "G"
	
func _on_item_gained(id: String) -> void:
	if id == "seanade":
		get_parent().get_node("SeanadeContainer").visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
