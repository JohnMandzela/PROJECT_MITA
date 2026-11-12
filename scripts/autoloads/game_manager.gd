extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SCENE_ROOT := "res://scenes/locations/"
const SCENE_FADE_DURATION := 0.5
const DEFAULT_VOLUME := 100.0

const SCREEN_FADER_PATH := "res://scenes/ui/screen_fader.tscn"

signal flag_updated(flag_name: String, value: bool)

## Установленные флаги. Отсутствие ключа означает, что флаг не установлен,
## поэтому значение false в словаре не хранится. Имена флагов — в Flags.
var game_flags: Dictionary[String, bool] = {}

var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")
var player: CharacterBody2D
var pending_spawn_point: String = ""

var is_virtual_world := false

var screen_fader: ScreenFader
var _pending_scene_path: String
var saved_direction = null
var saved_flashlight_state = null

var disable_movement := false
var is_minigame_active := false
var minigame_pause_target: Node = null

## Идёт пропуск катсцены: диалоговые функции работают без анимаций и ожиданий.
## Не сохраняется.
var is_skipping_cutscene := false


func reset_game_state() -> void:
	game_flags.clear()
	Quests.reset()
	Inventory.reset()


# Возвращает значение флага
func get_flag(flag_id: String) -> bool:
	if not Flags.is_valid(flag_id):
		push_error("Флаг '%s' не объявлен в Flags." % flag_id)
		return false

	return game_flags.has(flag_id)


# Устанавливает значение флага на параметр value (по умолчанию true)
func set_flag(flag_id: String, value := true) -> void:
	if not Flags.is_valid(flag_id):
		push_error("Флаг '%s' не объявлен в Flags." % flag_id)
		return

	if game_flags.has(flag_id) == value:
		return

	if value:
		game_flags[flag_id] = true
	else:
		game_flags.erase(flag_id)

	flag_updated.emit(flag_id, value)


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		config.set_value("audio", "music_volume", DEFAULT_VOLUME)
		config.set_value("audio", "sounds_volume", DEFAULT_VOLUME)
		config.set_value("video", "fullscreen", false)
		config.save(SETTINGS_PATH)
		return

	var fullscreen: bool = config.get_value("video", "fullscreen", false)
	var music_vol: float = config.get_value("audio", "music_volume", DEFAULT_VOLUME)
	var sounds_vol: float = config.get_value("audio", "sounds_volume", DEFAULT_VOLUME)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED,
	)

	SoundManager.set_music_volume(music_vol / DEFAULT_VOLUME)
	SoundManager.set_sound_volume(sounds_vol / DEFAULT_VOLUME)



func save_settings(fullscreen: bool, music_vol: float, sounds_vol: float) -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("audio", "music_volume", music_vol)
	config.set_value("audio", "sounds_volume", sounds_vol)
	config.save(SETTINGS_PATH)


func set_fullscreen(fullscreen: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED,
	)


func _ready() -> void:
	reset_game_state()
	load_settings()

	screen_fader = preload(SCREEN_FADER_PATH).instantiate()
	add_child(screen_fader)

	screen_fader.fade_out_finished.connect(_on_fade_out_finished)


func resolve_scene_path(scene_reference: String) -> String:
	return SCENE_ROOT + scene_reference + ".tscn"


# Переход в локацию, заданную сценой из инспектора (@export PackedScene).
# Состояние игрока, которое должно пережить смену сцены (фонарик),
# сохраняется здесь, а не в каждом отдельном событии-переходе.
func start_scene_transition(scene: PackedScene, spawn_point: String) -> void:
	if scene == null or scene.resource_path.is_empty():
		push_error("Сцена для перехода не задана")
		return

	_begin_scene_transition(scene.resource_path, spawn_point)


# Переход по ссылке вида "mihyung_offices/corridors_offices" (SceneTransitionEventAction).
# Здесь строка, а не PackedScene: локации ссылаются друг на друга, а циклические
# PackedScene Godot не грузит — второй ресурс приходит null (проверено).
func start_scene_transition_by_reference(scene_reference: String, spawn_point: String) -> void:
	_begin_scene_transition(resolve_scene_path(scene_reference), spawn_point)


func _begin_scene_transition(scene_path: String, spawn_point: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Сцена для перехода не существует: %s" % scene_path)
		return

	_pending_scene_path = scene_path

	var current_player := player as Player
	if current_player:
		saved_flashlight_state = current_player.is_flashlight_on

	pending_spawn_point = spawn_point
	screen_fader.fade_out(SCENE_FADE_DURATION) # затемняем экран


# Назначает сцену, в которую нужно перейти после затемнения экрана.
# Используется загрузкой сохранения: сразу после этого приходит fade_out_finished.
# Возвращает false, если сцены не существует.
func schedule_scene_change(scene_path: String) -> bool:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Сцена для перехода не существует: %s" % scene_path)
		return false

	_pending_scene_path = scene_path
	return true


# Меняем локацию после затемнения экрана
func _on_fade_out_finished() -> void:
	if SaveSystem.is_loading:
		SaveSystem.load_game_state()

	if _pending_scene_path:
		get_tree().change_scene_to_file(_pending_scene_path)
		_pending_scene_path = ""
