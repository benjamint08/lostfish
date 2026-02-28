extends Label

@export var life_time := 3.0
@export var rise_pixels := 18.0

func play(text_value: String) -> void:
	text = text_value
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position:y", position.y - rise_pixels, life_time)

	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(life_time - 0.6)

	tween.chain().tween_callback(queue_free).set_delay(life_time)
