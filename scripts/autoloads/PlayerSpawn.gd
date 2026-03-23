class_name PlayerSpawnScene
extends Node2D

@export var player_scene: PackedScene
@export var default_spawn_point: String

func _ready():	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Если игрока нет — создаём НУЖНУЮ модель
	if not GameManager.player:
		print("Создаём игрока")
		GameManager.player = player_scene.instantiate()
	elif GameManager.player.scene_file_path != player_scene.resource_path:
		print("Пересоздаём игрока")
		GameManager.player.queue_free()
		GameManager.player = player_scene.instantiate()
	
	add_child(GameManager.player)

	# Определяем spawn
	if not SaveSystem.is_loading:
		print("Инициализируем игрока по точке спавна")
		var spawn_name := GameManager.pending_spawn_point
		if spawn_name == "":
			spawn_name = default_spawn_point

		var spawn = get_node_or_null(spawn_name)
		if spawn:
			GameManager.player.global_position = spawn.global_position
	else:
		SaveSystem.load_player_data()

	GameManager.pending_spawn_point = ""
