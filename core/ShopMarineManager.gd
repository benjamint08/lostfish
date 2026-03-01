class_name ShopMarineManager
extends Node3D

@export var player_camera_path: NodePath = NodePath("../../FishPlr/SpringArm3D/Camera3D")
@export var shopmarine_camera_path: NodePath = NodePath("../shopmarine_body2/Camera3D")

@export var player_controller_path: NodePath = NodePath("../../FishPlr")
@export var disable_player_controller: bool = true

@export var cutscene_seconds: float = 10

@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var area3d_box: Area3D = $"../shopmarine_body2/Area3D"

signal shopmarine_gone

var _player_cam: Camera3D
var _shop_cam: Camera3D
var _player_controller: Node

func _on_ui_close() -> void:
	area3d_box.monitorable = false
	area3d_box.monitoring = false
	start_end_cutscene()

func _ready() -> void:
	_player_cam = get_node_or_null(player_camera_path) as Camera3D
	_shop_cam = get_node_or_null(shopmarine_camera_path) as Camera3D
	_player_controller = get_node_or_null(player_controller_path)
	ShopManager.shopmarine_shop_closed_mgr.connect(_on_ui_close)

	if _player_cam == null:
		push_error("Shopmarine: player camera not found at %s" % [player_camera_path])
	if _shop_cam == null:
		push_error("Shopmarine: shopmarine camera not found at %s" % [shopmarine_camera_path])

	if _shop_cam:
		_shop_cam.current = false
	
	start_cutscene()

func start_cutscene() -> void:
	if _player_cam == null or _shop_cam == null:
		return

	_player_cam.current = false

	if disable_player_controller and _player_controller != null:
		_player_controller.set_process(false)
		_player_controller.set_physics_process(false)
		_player_controller.set_process_input(false)
		_player_controller.set_process_unhandled_input(false)

	_shop_cam.current = true

	anim_player.play("shopmarine_enter")
	await get_tree().create_timer(4).timeout

	end_start_cutscene()
	
func start_end_cutscene():
	if _player_cam == null or _shop_cam == null:
		return

	_player_cam.current = false

	if disable_player_controller and _player_controller != null:
		_player_controller.set_process(false)
		_player_controller.set_physics_process(false)
		_player_controller.set_process_input(false)
		_player_controller.set_process_unhandled_input(false)

	_shop_cam.current = true

	anim_player.play("shopmarine_exit")
	await get_tree().create_timer(4).timeout
	end_exit_cutscene()

func end_exit_cutscene():
	end_cutscene()
	shopmarine_gone.emit()
	await get_tree().create_timer(6).timeout
	get_parent().queue_free()
	
func end_start_cutscene():
	end_cutscene()
	await get_tree().create_timer(6).timeout
		
func end_cutscene() -> void:
	if _player_cam:
		_player_cam.current = true
	if _shop_cam:
		_shop_cam.current = false

	if disable_player_controller and _player_controller != null:
		_player_controller.set_process(true)
		_player_controller.set_physics_process(true)
		_player_controller.set_process_input(true)
		_player_controller.set_process_unhandled_input(true)
