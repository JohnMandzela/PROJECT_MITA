extends Node

const SAVE_PATH := "user://save.bin"

# TODO: перенести в меню
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	var player = GameManager.player
	if not player:
		print("Узел игрока не найден")
		return
		
	var save_data := {
		"current_scene" = get_tree().current_scene.name, # TODO
		"player_position" = player.position,
		"player_direction" = player.last_direction,
		"flashlight_enabled" = player.flashlight.enabled
	}
	
	file.store_var(save_data)
	file.close()
	
	print("Игра сохранена")

func load_game() -> void:
	var player = GameManager.player
	if not player:
		print("Узел игрока не найден")
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("Файл с сохранением не найден")
		return
	
	var save_data: Dictionary = file.get_var()
	file.close()
	
	player.position = save_data["player_position"]
	player.last_direction = save_data["player_direction"]
	player.flashlight.enabled = save_data["flashlight_enabled"]
	
	print("Игра загружена")
