class_name PlayerSpawnScene
extends Node2D

@export var player_scene: PackedScene
@export var default_spawn_point: String


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if player_scene == null:
		push_error("PlayerSpawnScene has no player_scene")
		return

	if not is_instance_valid(GameManager.player):
		GameManager.player = player_scene.instantiate()
	elif GameManager.player.scene_file_path != player_scene.resource_path:
		var old_player = GameManager.player
		if old_player.get_parent() != null:
			old_player.get_parent().remove_child(old_player)
		old_player.queue_free()
		GameManager.player = player_scene.instantiate()

	if GameManager.player.get_parent() != self:
		if GameManager.player.get_parent() != null:
			GameManager.player.get_parent().remove_child(GameManager.player)
		add_child(GameManager.player)

	if SaveSystem.is_loading:
		SaveSystem.load_player_data()
	else:
		_spawn_player()

	GameManager.pending_spawn_point = ""


func _spawn_player() -> void:
	var spawn_name := GameManager.pending_spawn_point
	if spawn_name == "":
		spawn_name = default_spawn_point

	var spawn = find_child(spawn_name, true, false)
	if spawn:
		GameManager.player.global_position = spawn.global_position
