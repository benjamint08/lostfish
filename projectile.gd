extends RigidBody3D

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var trail: GPUParticles3D = $GPUParticles3D
var hit := false

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	_die_and_leave_particles()

func _on_body_entered(body: Node) -> void:
	if hit:
		return

	if body is Shark or body is AngryShark:
		hit = true
		body.die()
		player.add_health(5)
		
	if body.is_in_group("seanade"):
		body.get_node("SeanadeArea").explode()

	_die_and_leave_particles()

func _die_and_leave_particles() -> void:
	if is_instance_valid(trail):
		var world := get_tree().current_scene

		var t := trail.global_transform

		remove_child(trail)
		world.add_child(trail)
		trail.global_transform = t

		trail.emitting = false

		var cleanup_time := trail.lifetime + trail.explosiveness + 0.25
		_cleanup_particles_later(trail, cleanup_time)

	queue_free()

func _cleanup_particles_later(p: GPUParticles3D, seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)
