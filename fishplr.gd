class_name Player
extends CharacterBody3D

var SPEED := 12.0
var BOOST_MULT := 3.0
var ACCEL := 20.0
var DRAG := 4.0
var MOUSE_SENS := 0.002

var maxHealth := 100
var health := maxHealth
var dmgPerEnemyHit := 25
var hitCooldown := 1
var canBeHit = true

@export var projectile_scene: PackedScene
@export var seanade_scene: PackedScene
@onready var cam: Camera3D = $"SpringArm3D/Camera3D"
@onready var ammo_count: RichTextLabel = $"PlayerUI/AmmoCount"
@onready var weapon_name: RichTextLabel = $"PlayerUI/WeaponName"
@onready var healthbar: ProgressBar = $"PlayerUI/Health"

var unlocked := true

var pitch := 0.0

var maxAmmo := 5
var currentAmmo := maxAmmo
var reloadTime := 3
var reloading := false
var canShoot := true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	unlocked = false
	ammo_count.text = str(currentAmmo) + "/" + str(maxAmmo)
	
func reload_weapon() -> void:
	reloading = true
	ammo_count.text = "-/" + str(maxAmmo)
	if(RunState.has_perk("lungs") != 0):
		maxAmmo = 5 + (RunState.get_perk_data("lungs", RunState.has_perk("lungs"))["ammo_bonus"])
	var timeToWait: float = reloadTime
	if(RunState.has_perk("scales")):
		timeToWait -= RunState.get_perk_data("scales", RunState.has_perk("scales"))["reload_speed_bonus"]
	await get_tree().create_timer(timeToWait).timeout
	currentAmmo = maxAmmo
	ammo_count.text = str(currentAmmo) + "/" + str(maxAmmo)
	reloading = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)

		pitch = clamp(pitch - event.relative.y * MOUSE_SENS, deg_to_rad(-80), deg_to_rad(80))
		rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		unlocked = true
		
	if event.is_action_pressed("reload"):
		reload_weapon()
		
	if event.is_action_pressed("grenade") and RunState.has_item("seanade") == 1 and RunState.can_use_seanade() == true:
		var nade := seanade_scene.instantiate()

		get_tree().current_scene.add_child(nade)

		nade.global_transform = cam.global_transform
		var forward := -cam.global_transform.basis.z
		nade.global_position += forward * 8

		if nade is RigidBody3D:
			#var up := cam.global_transform.basis.y <- i didnt like this. maybe will re-enable
			var throw_dir := (forward).normalized()

			var throw_power := 5.0
			nade.apply_central_impulse(throw_dir * throw_power)

			nade.apply_torque_impulse(Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			) * 2.0)
			RunState.use_seanade()
				
	if event is InputEventMouseButton:
		if unlocked == true:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			unlocked = false
		else:
			if reloading == true:
				return
			if canShoot == false:
				return
			if currentAmmo == 0:
				reload_weapon()
				return
			var projectile = projectile_scene.instantiate()

			projectile.global_transform = cam.global_transform

			get_tree().current_scene.add_child(projectile)

			var forward := -cam.global_transform.basis.z
			projectile.global_position += forward * 4

			var power := 80.0
			if(RunState.has_perk("airpressure")):
				power = power + RunState.get_perk_data("airpressure", RunState.has_perk("airpressure"))["projectile_speed_bonus"]
	
			projectile.apply_central_impulse(forward * power)
			currentAmmo -= 1
			ammo_count.text = str(currentAmmo) + "/" + str(maxAmmo)
			canShoot = false
			var timeToWait: float = 0.3
			if(RunState.has_perk("scales")):
				timeToWait -= RunState.get_perk_data("scales", RunState.has_perk("scales"))["shoot_speed_bonus"]
			await get_tree().create_timer(0.3).timeout
			canShoot = true
			
func add_health(hp: int) -> void:
	if health == maxHealth:
		return
	if (health + hp) > maxHealth:
		health = maxHealth
		healthbar.value = health
		return
	health += hp
	healthbar.value = health

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if(RunState.has_perk("speed")):
		SPEED = 12 + RunState.get_perk_data("speed", RunState.has_perk("speed"))["speed_bonus"]
	
	var up_down := 0.0
	if Input.is_action_pressed("move_up"):
		up_down += 1.0
	if Input.is_action_pressed("move_down"):
		up_down -= 1.0

	var local_wish := Vector3(input_2d.x, up_down, input_2d.y)

	var wish_dir := (global_transform.basis * local_wish).normalized()

	var target_speed := SPEED * (BOOST_MULT if Input.is_action_pressed("boost") else 1.0)
	var target_vel := wish_dir * target_speed

	velocity = velocity.move_toward(target_vel, ACCEL * delta)

	velocity = velocity.move_toward(Vector3.ZERO, DRAG * delta)

	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var body := col.get_collider()
		
		if (body is Shark or body is AngryShark) and canBeHit == true:
			canBeHit = false
			var damageToDecrease: float = dmgPerEnemyHit
			if(RunState.has_perk("scales")):
				damageToDecrease -= (RunState.get_perk_data("scales", RunState.has_perk("scales"))["damage_decrease_bonus"] / 2)
			if body is AngryShark:
				health -= damageToDecrease * 3
			else:
				health -= damageToDecrease
			if health < 0:
				get_tree().quit()
			healthbar.value = health
			await get_tree().create_timer(hitCooldown).timeout
			canBeHit = true
			
		if body == null or not is_instance_valid(body):
			continue
		if body is RigidBody3D:
			var push_dir := -col.get_normal()
			var strength := velocity.length() * 0.2
			body.apply_impulse(push_dir * strength, col.get_position() - body.global_position)
