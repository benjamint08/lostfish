class_name AngryShark
extends RigidBody3D

signal died

var sharkIsDead := false
var hit1 := false

@export var speed: float = 18.0
@export var turn_speed: float = 18.0

@onready var player: Node3D = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var to_player: Vector3 = (player.global_position - global_position)
	if to_player.length() < 0.01:
		return

	var desired_dir = to_player.normalized()
	var desired_vel = desired_dir * speed

	linear_velocity = linear_velocity.lerp(desired_vel, turn_speed * delta)

	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity, Vector3.UP)

func die() -> void:
	if sharkIsDead == false:
		if hit1 == true:
			RunState.add_coins(4, "Angry Shark Kill")
			died.emit()
			queue_free()
			sharkIsDead = true
		else:
			hit1 = true
	
func _ready() -> void:
	pass
