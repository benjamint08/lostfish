extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	var a = anim.get_animation("swimming")
	a.loop_mode = Animation.LOOP_LINEAR
	anim.play("swimming")
