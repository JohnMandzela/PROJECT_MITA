extends Node


#---------------------------------------------------------------------------------------------------------------
# Константы для масштаба экрана в игре
var SETTINGS_PATH := "user://settings.cfg"

# Переменные для СПАВНА игрока в сцене
var player_scene: PackedScene = preload("res://scenes/player.tscn")
var player: CharacterBody2D
var pending_spawn_point: String = ""

# Переменные для анимации ПЕРЕХОДА и сохранения взгляда
var screen_fader
var _pending_scene: String
var saved_direction = null
var saved_flashlight_state = null

# Переменная для музыки (чтобы громкость постоянно обновлялась)
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Переменная для диалоговой системы
var disable_movement := false
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



#---------------------------------------------------------------------------------------------------------------
# Начинаем перемещение в другую локацию
func start_scene_transition(scene_path: String, spawn_point: String) -> void:
	_pending_scene = scene_path
	pending_spawn_point = spawn_point
	screen_fader.fade_out()                                                         # затемняем экран

# Меняем локацию после затемнения экрана
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
