extends Node

enum Mode {
	AUTO,
	QUICK,
	MANUAL,
}

const SLOT_COUNT := 3
const LEGACY_SAVE_PATH := "user://save.bin"

const GAME_MANAGER_PROPERTIES_TO_SAVE: PackedStringArray = [
	"game_flags",
	"quests_info",
]

const ITEMS_PROPERTIES_TO_SAVE: PackedStringArray = [
	"items_inventory",
	"inventory_order",
]

const PLAYER_PROPERTIES_TO_SAVE: PackedStringArray = [
	"global_position",
	"last_direction",
	"is_flashlight_on",
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
			return "user://save_%d.bin" % clampi(slot, 0, SLOT_COUNT - 1)
	
	assert(false, "Недопустимый режим сохранения")
	return ""


# Получение всех существующих сохранений
func get_all_save_files() -> Array[String]:
	var save_files: Array[String] = []
	
	for mode in [Mode.AUTO, Mode.QUICK]:
		var path := _get_save_file_path(mode)
		if FileAccess.file_exists(path):
			save_files.append(path)
	
	for slot in range(SLOT_COUNT):
		var path := _get_save_file_path(Mode.MANUAL, slot)
		if FileAccess.file_exists(path):
			save_files.append(path)
	
	if FileAccess.file_exists(LEGACY_SAVE_PATH) and not save_files.has(LEGACY_SAVE_PATH):
		save_files.append(LEGACY_SAVE_PATH)

	return save_files


# Получение пути к последнему сохранённому файлу (по времени модификации)
func get_latest_save_path() -> String:
	var latest_time := 0
	var latest_file := ""

	for path in get_all_save_files():
		var modified_time := FileAccess.get_modified_time(path)
		if modified_time >= latest_time:
			latest_time = modified_time
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
		if _save_data.has(property):
			GameManager.set(property, _save_data[property])

	GameManager.sync_quest_progress()
	
	var loaded_inventory := Items.items_inventory
	if _save_data.has("items_inventory"):
		loaded_inventory = _save_data["items_inventory"]

	var loaded_order := Items.inventory_order
	if _save_data.has("inventory_order"):
		loaded_order = _save_data["inventory_order"]

	Items.apply_inventory_state(loaded_inventory, loaded_order)
	GameManager._pending_scene_path = GameManager.resolve_scene_path(str(_save_data["scene_file_path"]))
	
	print("Загружены данные GameManager")


# Завершение загрузки игрока. Вызывать после загрузки сцены
func load_player_state() -> void:
	if not is_loading:
		push_warning("Функция load_player_state вызвана вне процесса загрузки")
		return
	
	assert(_save_data != null, "Нет данных для загрузки")

	var player := GameManager.player
	for property in PLAYER_PROPERTIES_TO_SAVE:
		if _save_data.has(property):
			GameManager.player.set(property, _save_data[property])
		
	print("Загружены данные игрока")
	is_loading = false
	_save_data = null

func _build_slot_info(id: String, title: String, mode: Mode, slot: int) -> Dictionary:
	return _build_path_info(id, title, get_save_file_path(mode, slot), mode, slot)


func _build_path_info(id: String, title: String, path: String, mode = null, slot := -1) -> Dictionary:
	var exists := FileAccess.file_exists(path)
	var summary := get_save_summary(path) if exists else {}
	return {
		"id": id,
		"title": title,
		"mode": mode,
		"slot": slot,
		"path": path,
		"exists": exists,
		"modified_time": FileAccess.get_modified_time(path) if exists else 0,
		"scene_file_path": str(summary.get("scene_file_path", "")),
		"scene_name": str(summary.get("scene_name", "Пусто")),
		"is_valid": bool(summary.get("is_valid", false)),
	}


func _humanize_scene_name(scene_path: String) -> String:
	if scene_path.is_empty():
		return "Неизвестная сцена"

	var file_name := scene_path.get_file().get_basename()
	if file_name.is_empty():
		return scene_path

	return file_name.replace("_", " ").capitalize()
