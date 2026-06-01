extends Node

# Режимы сохранения
enum Mode {
	AUTO,
	QUICK,
	MANUAL
}

# Количество слотов для сохранения (для ручного сохранения)
const SLOT_COUNT := 3

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

# Получение пути к файлу сохранения в зависимости от режима сохранения
func _get_save_file_path(mode: Mode, slot := 0) -> String:
	match mode:
		Mode.AUTO: 
			return "user://autosave.bin"
		Mode.QUICK: 
			return "user://quicksave.bin"
		Mode.MANUAL: 
			return "user://save_%d.bin" % slot
		_: 
			assert(false, "Недопустимый режим сохранения")
			return ""


# Получение всех существующих сохранений
func get_all_save_files() -> Array:
	var save_files := []
	
	for mode in [Mode.AUTO, Mode.QUICK]:
		var path := _get_save_file_path(mode)
		if FileAccess.file_exists(path):
			save_files.append(path)
	
	for slot in range(SLOT_COUNT):
		var path := _get_save_file_path(Mode.MANUAL, slot)
		if FileAccess.file_exists(path):
			save_files.append(path)
	
	return save_files


# Получение пути к последнему сохранённому файлу (по времени модификации)
func get_latest_save_path() -> String:
	var latest_time := 0
	var latest_file := ""

	for path in get_all_save_files():
		var time := FileAccess.get_modified_time(path)
		if time > latest_time:
			latest_time = time
			latest_file = path

	return latest_file


# Сохранение игры
func save_game(mode: Mode, slot := 0) -> void:
	if is_loading:
		push_warning("Нельзя сохраниться во время загрузки")
		return
	
	var path := _get_save_file_path(mode, slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	var player := GameManager.player
	if not player:
		push_error("Узел игрока не найден")
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
	
	print("Игра сохранена в файл %s" % path)


# Загрузка сохранённой игры по режиму сохранения и слоту
func load_game(mode: Mode, slot := 0) -> void:	
	var path := _get_save_file_path(mode, slot)
	load_game_from_file(path)


# Загрузка сохранённой игры по пути к файлу
func load_game_from_file(path: String) -> void:
	print("Начинаем загрузку файла %s..." % path)
	
	if not FileAccess.file_exists(path):
		push_warning("Файл %s не найден" % path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	_save_data = file.get_var()
	file.close()
	
	is_loading = true
	GameManager.screen_fader.fade_out()


# Завершение загрузки GameManager. Вызывать после анимации затухания
func load_game_state() -> void:
	if not is_loading:
		push_warning("Функция load_game_state вызвана вне процесса загрузки")
		return
	
	assert(_save_data != null, "Нет данных для загрузки")

	for property in GAME_MANAGER_PROPERTIES_TO_SAVE:
		GameManager.set(property, _save_data[property])
	
	GameManager._pending_scene_path = _save_data["scene_file_path"]
	
	print("Загружены данные GameManager")


# Завершение загрузки игрока. Вызывать после загрузки сцены
func load_player_state() -> void:
	if not is_loading:
		push_warning("Функция load_player_state вызвана вне процесса загрузки")
		return
	
	assert(_save_data != null, "Нет данных для загрузки")

	var player := GameManager.player
	for property in PLAYER_PROPERTIES_TO_SAVE:
		player.set(property, _save_data[property])
		
	print("Загружены данные игрока")
	is_loading = false
	_save_data = null
