class_name Seanade
extends Area3D

@export var fuse_seconds: float = 5.0

var targets: Array[Node] = []

@onready var fire: GPUParticles3D = $"../Fire"
@onready var smoke: GPUParticles3D = $"../Smoke"
@onready var debris: GPUParticles3D = $"../Debris"
@onready var node_body: Node3D = $"../seanade2"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	print("Waiting to explode")
	await get_tree().create_timer(fuse_seconds).timeout
	print("Waited")
	explode()


func _on_body_entered(body: Node) -> void:
	if body is Shark or body is AngryShark:
		if not targets.has(body):
			print("Entered a shark")
			targets.append(body)


func _on_body_exited(body: Node) -> void:
	var idx := targets.find(body)
	if idx != -1:
		print("Removed a shark")
		targets.remove_at(idx)

func explode() -> void:
	print("Kaboom!")

	for p in [fire, smoke, debris]:
		if p:
			p.one_shot = true
			p.restart()
			p.emitting = true
	
	node_body.visible = false

	for t in targets:
		if is_instance_valid(t) and (t is Shark or t is AngryShark):
			if t.has_method("die"):
				t.die()
		if is_instance_valid(t) and (t is AngryShark):
			# do it again because angry sharks have two to die
			if t.has_method("die"):
				t.die()
	
	monitoring = false
	monitorable = false

	targets.clear()

	await get_tree().create_timer(3.0).timeout
	get_parent().queue_free()
