extends Node

# Путь к файлу сохранений
# TODO: проверить формат
const SAVE_PATH := "user://save.bin"

# Свойства GameManager, подлежащие сериализации
const GAME_MANAGER_PROPERTIES_TO_SAVE: PackedStringArray = [
	"game_flags", 
	"items_inventory"
]

# Свойства игрока, подлежащие сериализации
const PLAYER_PROPERTIES_TO_SAVE: PackedStringArray = [
	"global_position",
	"last_direction",
	"is_flashlight_on"
]

var is_loading := false
var _save_data = null

# Сохранение игры
func save_game() -> void:
	if is_loading:
		print("Нельзя сохраниться во время загрузки")
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	var player := GameManager.player
	if not player:
		print("Узел игрока не найден")
		return

	var save_data := {
		"scene_file_path" = get_tree().current_scene.scene_file_path
	}
	
	for property in GAME_MANAGER_PROPERTIES_TO_SAVE:
		save_data[property] = GameManager.get(property)
		
	for property in PLAYER_PROPERTIES_TO_SAVE:
		save_data[property] = player.get(property)
	
	file.store_var(save_data)
	file.close()
	
	print("Игра сохранена")

# Загрузка сохранённой игры
func load_game() -> void:	
	print("Начинаем загрузку...")
	
	if not save_exists():
		print("Файл с сохранением не найден")
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	_save_data = file.get_var()
	file.close()
	
	is_loading = true
	GameManager.screen_fader.fade_out()


# Завершение загрузки GameManager. Вызывать после анимации затухания
func load_game_data() -> void:
	if not is_loading:
		return
		
	for property in GAME_MANAGER_PROPERTIES_TO_SAVE:
		GameManager.set(property, _save_data[property])
	
	GameManager._pending_scene_path = _save_data["scene_file_path"]
	
	print("Загружены данные GameManager")


# Завершение загрузки игрока. Вызывать после загрузки сцены
func load_player_data() -> void:
	if not is_loading:
		return
	
	var player := GameManager.player
	for property in PLAYER_PROPERTIES_TO_SAVE:
		player.set(property, _save_data[property])
		
	print("Загружены данные игрока")
	is_loading = false
	_save_data = null


# Проверка, что сохранение существует
func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
