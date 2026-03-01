extends Node3D

@onready var spawn_container: Node3D = $"../SpawnPoints"
@onready var shop_marker: Marker3D = $"../ShopPoint"
@onready var shark_text: RichTextLabel = $"../FishPlr/PlayerUI/SharksLeft"
@onready var wave_text: RichTextLabel = $"../FishPlr/PlayerUI/WaveCount"
@onready var audio_player: AudioStreamPlayer3D = $"../FishPlr/AudioStreamPlayer3D"

@onready var world_env: WorldEnvironment = get_tree().current_scene.get_node("WorldEnvironment")

@export var blue_env: Environment
@export var red_env: Environment

@export var enemy_scene: PackedScene
@export var angry_enemy_scene: PackedScene

@export var countdown_audio: AudioStreamWAV
@export var blood_round_audio: AudioStreamWAV
@export var new_round_audio: AudioStreamWAV
@export var shopmarine_scene: PackedScene

var _fade_rect: ColorRect

var wave := 0
var sharks_per_wave := 2
var alive_sharks := 0
var started := false
var spawned := 0

var current_sea: Node3D = null

var shopmarine_manager: ShopMarineManager

func _ready() -> void:
	print("Getting ready")

	_set_env(false)
	
	audio_player.stream = countdown_audio
	audio_player.play()
	await start_countdown(3)
	started = true
	start_wave()
	ShopManager.shop_closed_mgr.connect(_on_shop_closed)

func start_wave() -> void:
	wave += 1
	spawned = 0
	alive_sharks = 0

	_set_env(wave % 5 == 0)

	var to_spawn := sharks_per_wave * wave
	if wave % 5 == 0:
		await get_tree().create_timer(2).timeout
		audio_player.stop()
		audio_player.stream = blood_round_audio
		audio_player.play()
		spawn_sharks_rndm(to_spawn, angry_enemy_scene)
	else:
		spawn_sharks_rndm(to_spawn, enemy_scene)

	update_ui()

func spawn_sharks_rndm(amount: int, sceneToSpawn: PackedScene) -> void:
	var markers := spawn_container.get_children()

	if markers.is_empty():
		push_error("No spawn markers!")
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(amount):
		var delay := rng.randf_range(0.5, 3)
		await get_tree().create_timer(delay).timeout

		var marker := markers[rng.randi_range(0, markers.size() - 1)]

		if marker is Marker3D:
			var enemy = sceneToSpawn.instantiate()
			enemy.global_position = marker.global_position
			get_tree().current_scene.add_child(enemy)

			alive_sharks += 1
			spawned += 1

			if enemy.has_signal("died"):
				enemy.died.connect(_on_shark_died)
			update_ui()
			
func _set_env(is_red: bool) -> void:
	if world_env == null:
		push_error("WorldEnvironment node not found in current_scene. Name it 'WorldEnvironment' or adjust the path.")
		return

	var env := red_env if is_red else blue_env
	if env == null:
		push_error("Blue/Red Environment resources not assigned.")
		return

	print("Setting world env to (Red? " + str(is_red) + ")")
	world_env.environment = env

func _on_shopmarine_exit():
	_on_shop_closed()
	
func _on_shark_died():
	alive_sharks -= 1
	update_ui()
	if alive_sharks <= 0 and started and (spawned >= sharks_per_wave * wave):
		audio_player.stream = new_round_audio
		audio_player.play()
		RunState.add_coins(60, "Round Survival")
		await get_tree().create_timer(3).timeout
		if (wave + 1) % 5 == 0:
			ShopManager.open_shop()
		elif (wave + 1) % 4 == 0:
			var shopMarine = shopmarine_scene.instantiate()
			shopMarine.global_position = shop_marker.global_position
			get_tree().current_scene.add_child(shopMarine)
			shopmarine_manager = shopMarine.get_node("ShopMarineManager") as ShopMarineManager
			shopmarine_manager.shopmarine_gone.connect(_on_shopmarine_exit)
		else:
			# i know this says on shop closed, but it's just the function that starts the new round
			_on_shop_closed()

func _on_shop_closed():
	audio_player.stream = countdown_audio
	audio_player.play()
	await start_countdown(3)
	start_wave()

func update_ui() -> void:
	var suffix := "s"
	if alive_sharks == 1:
		suffix = ""
	shark_text.text = str(alive_sharks) + " Shark" + suffix + " Remaining"
	wave_text.text = "Wave " + str(wave)

func start_countdown(seconds: int) -> void:
	for i in range(seconds, 0, -1):
		shark_text.text = str(i)
		await get_tree().create_timer(1.0).timeout
