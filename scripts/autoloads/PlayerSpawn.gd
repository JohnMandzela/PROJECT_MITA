extends Node2D

@export var player_scene: PackedScene
@export var default_spawn_point: String

func _ready():
	# Если игрока нет — создаём НУЖНУЮ модель
	if GameManager.player == null:
		GameManager.player = player_scene.instantiate()
		add_child(GameManager.player)
	else:
		# Если игрок есть, но его сцена ДРУГАЯ — пересоздаём
		if GameManager.player.scene_file_path != player_scene.resource_path:
			GameManager.player.queue_free()
			GameManager.player = player_scene.instantiate()
			add_child(GameManager.player)
		else:
			add_child(GameManager.player)

	# Определяем spawn
	var spawn_name := GameManager.pending_spawn_point
	if spawn_name == "":
		spawn_name = default_spawn_point

	var spawn = get_node_or_null(spawn_name)
	if spawn:
		GameManager.player.global_position = spawn.global_position

	GameManager.pending_spawn_point = ""
