extends VBoxContainer

const ROW_SCENE := preload("res://core/CoinPopupRow.tscn")

@onready var vbox: VBoxContainer = self

func _ready() -> void:
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN

	RunState.coins_gained.connect(_on_coins_gained)
	RunState.coins_removed.connect(_on_coins_removed)

func _on_coins_gained(amount: int, reason: String) -> void:
	var row := ROW_SCENE.instantiate() as Label

	var msg := "+%d coins" % amount
	if reason != "":
		msg += "  (" + reason + ")"

	row.text = msg

	vbox.add_child(row)
	vbox.move_child(row, 0)

	var t := get_tree().create_timer(3.0)
	t.timeout.connect(func():
		if is_instance_valid(row):
			var tw := row.create_tween()
			tw.tween_property(row, "modulate:a", 0.0, 0.4)
			tw.tween_callback(row.queue_free)
	)

func _on_coins_removed(amount: int, reason: String) -> void:
	var row := ROW_SCENE.instantiate() as Label

	var msg := "-%d coins" % amount
	if reason != "":
		msg += "  (" + reason + ")"

	row.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	row.text = msg

	vbox.add_child(row)
	vbox.move_child(row, 0)

	var t := get_tree().create_timer(3.0)
	t.timeout.connect(func():
		if is_instance_valid(row):
			var tw := row.create_tween()
			tw.tween_property(row, "modulate:a", 0.0, 0.4)
			tw.tween_callback(row.queue_free)
	)
