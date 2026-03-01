extends Node3D

@export var rpm: float = 600.0

func _process(delta: float) -> void:
	var degrees_per_second = rpm * 6.0
	rotate_z(deg_to_rad(degrees_per_second * delta))
