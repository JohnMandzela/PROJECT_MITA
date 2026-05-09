extends Node


#---------------------------------------------------------------------------------------------------------------
# Файл с данными настроек
var SETTINGS_PATH := "user://settings.cfg"

# Переменные для СПАВНА игрока в сцене
var player_scene: PackedScene = preload("res://scenes/player.tscn")
var player: CharacterBody2D
var pending_spawn_point: String = ""

# Переменные для анимации ПЕРЕХОДА и сохранения взгляда
var screen_fader
var _pending_scene: String
var saved_direction

# Переменная для музыки (чтобы громкость постоянно обновлялась)
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Переменная для диалоговой системы
var disable_movement := false
<<<<<<< Updated upstream
#---------------------------------------------------------------------------------------------------------------
=======
var is_minigame_active := false
var minigame_pause_target: Node = null

const SCENE_ROOT := "res://scenes/"

var quests_info: Dictionary:
	get:
		return Quests.quests_info
	set(value):
		Quests.quests_info = value

var game_flags: Dictionary:
	get:
		return Quests.game_flags
	set(value):
		Quests.game_flags = value
>>>>>>> Stashed changes



#---------------------------------------------------------------------------------------------------------------
var items_inventory = {
		"buttle_cola" = 0
	}

# Проверяем, было ли событие или нет
func item_check(item_name: String) -> int:
	return items_inventory.get(item_name, 0)

# Отмечаем событие выполненным
func item_was_took(item_name: String):
	items_inventory[item_name] = items_inventory[item_name] + 1
	print(items_inventory[item_name])

# Снимаем флаг события (воспроизводим заново)
func item_was_dropped(item_name: String):
	items_inventory[item_name] = items_inventory[item_name] - 1
	print(items_inventory[item_name])
#---------------------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------------------
# Хранение флажков по игровым событиям
var game_flags = {
		"1_morning_quest" = false,
		"2_mike_room_bed" = false,
		"3_cola_in_fridge" = false,
		"4_shower_use" = false,
	}

# Проверяем, было ли событие или нет
func is_done(flag_name: String) -> bool:
	return game_flags.get(flag_name, false)

# Отмечаем событие выполненным
func set_done(flag_name: String) -> void:
	game_flags[flag_name] = true

# Снимаем флаг события (воспроизводим заново)
func reload(flag_name: String) -> void:
	game_flags[flag_name] = false
#---------------------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------------------
# Загружаем данные настроек
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err != OK:
		return # если файла нет — запускаем с дефолтными

	var fullscreen = config.get_value("video", "fullscreen", false)
	var music_vol = config.get_value("audio", "music_volume", 100.0)
	var sounds_vol = config.get_value("audio", "sounds_volume", 100.0)

	# Применяем fullscreen
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

	# Применяем звук
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), 
		linear_to_db(music_vol / 100.0)
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sounds"), 
		linear_to_db(sounds_vol / 100.0)
	)
#---------------------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------------------
func _ready() -> void:
	# Добавляем музыку в AutoLoad
	add_child(music_player)
	music_player.bus = "Music"
	music_player.autoplay = false
	
	load_settings()
	screen_fader = preload("res://scenes/system/screen_fader.tscn").instantiate()   # подзагружаем анимацию перехода
	add_child(screen_fader)                                                         # добавляем ее в сцену

	screen_fader.fade_finished.connect(_on_fade_finished)
#---------------------------------------------------------------------------------------------------------------


<<<<<<< Updated upstream

#---------------------------------------------------------------------------------------------------------------
# Начинаем перемещение в другую локацию
func start_scene_transition(scene_path: String, spawn_point: String) -> void:
	_pending_scene = scene_path
=======
func start_scene_transition(scene_reference: String, spawn_point: String) -> void:
	_pending_scene_path = resolve_scene_path(scene_reference)
	if _pending_scene_path.is_empty() or not ResourceLoader.exists(_pending_scene_path):
		push_error("Scene transition target does not exist: %s" % scene_reference)
		return

>>>>>>> Stashed changes
	pending_spawn_point = spawn_point
	screen_fader.fade_out()                                                         # затемняем экран

<<<<<<< Updated upstream
# Меняем локацию после затемнения экрана
=======
func resolve_scene_path(scene_reference: String) -> String:
	var reference := scene_reference.strip_edges()
	if reference.is_empty():
		return ""

	if reference.begins_with("res://") and ResourceLoader.exists(reference):
		return reference

	reference = reference.replace("\\", "/")
	if reference.begins_with(SCENE_ROOT):
		reference = reference.trim_prefix(SCENE_ROOT)
	if reference.ends_with(".tscn"):
		reference = reference.trim_suffix(".tscn")

	var direct_path := "%s%s.tscn" % [SCENE_ROOT, reference]
	if ResourceLoader.exists(direct_path):
		return direct_path

	var found_path := _find_scene_by_name(reference.get_file().get_basename())
	if not found_path.is_empty():
		return found_path

	push_warning("Unknown scene transition target: %s" % scene_reference)
	return direct_path


func _find_scene_by_name(scene_name: String) -> String:
	return _find_scene_by_name_in_dir(SCENE_ROOT, scene_name.to_lower())


func _find_scene_by_name_in_dir(directory_path: String, scene_name: String) -> String:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return ""

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		var path := directory_path.path_join(file_name)
		if directory.current_is_dir():
			if not file_name.begins_with("."):
				var nested_result := _find_scene_by_name_in_dir(path, scene_name)
				if not nested_result.is_empty():
					directory.list_dir_end()
					return nested_result
		elif file_name.get_extension() == "tscn" and file_name.get_basename().to_lower() == scene_name:
			directory.list_dir_end()
			return path

		file_name = directory.get_next()

	directory.list_dir_end()
	return ""


>>>>>>> Stashed changes
func _on_fade_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/" + _pending_scene + ".tscn")     # смена локации
	screen_fader.fade_in()                                                          # осветляем экран
#---------------------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------------------
# Воспроизводим музыку
func play_music(stream: AudioStream):
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

# Останавливаем музыку
func stop_music():
	if music_player.playing:
		music_player.stop()
#---------------------------------------------------------------------------------------------------------------
