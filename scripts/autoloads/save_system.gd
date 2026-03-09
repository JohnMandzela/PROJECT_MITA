extends Node

const SAVE_PATH := "user://save.bin"



# TODO: перенести в меню
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	var player: Node = %Player
	if not player:
		print("Узел игрока не найден")
		return
		
	var flashlight: Node = %Player/Phone_Flashlight
		
	var save_dict := {
		"current_scene" = get_tree().current_scene.name,
		"player_position" = player.position,
		"player_direction" = player.last_direction,
		"flashlight_enabled" = flashlight.enabled
	}
	
	print(save_dict)

func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("Файл с сохранением не найден")
		return
		
	var player: Node = %Player
	if not player:
		print("Узел игрока не найден")
		return
	
