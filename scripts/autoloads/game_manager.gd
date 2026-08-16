extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SCENE_ROOT := "res://scenes/"

const SCREEN_FADER_PATH := "res://scenes/ui/screen_fader.tscn"

const DEFAULT_GAME_FLAGS: Dictionary[String, bool] = {
	"bed_interacted": false,
	"shower_used": false,
	"offices_coffee_picked_up": false,
	"programming_office_samples_puzzle_completed": false,
}

signal flag_updated(flag_name: String, value: bool)

var game_flags: Dictionary[String, bool] = {}

var player_scene: PackedScene = preload("res://scenes/player.tscn")
var player: CharacterBody2D
var pending_spawn_point: String = ""

var is_virtual_world := false

var screen_fader: ScreenFader
var _pending_scene_path: String
var saved_direction = null
var saved_flashlight_state = null

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var disable_movement := false
var is_minigame_active := false
var minigame_pause_target: Node = null

# Константы для отладки
const DEBUG_SKIP_INTRO := true


func reset_game_state() -> void:
	game_flags = DEFAULT_GAME_FLAGS.duplicate()
	Quests.reset()
	Inventory.reset()

	

# Возвращает значение флага
func get_flag(flag_id: String) -> bool:
	if not game_flags.has(flag_id):
		push_error("Флаг '%s' не найден." % flag_id)
		return false

	return game_flags[flag_id]


# Устанавливает значение флага на параметр value (по умолчанию true)
func set_flag(flag_id: String, value := true) -> void:
	if not game_flags.has(flag_id):
		push_error("Флаг '%s' не найден." % flag_id)
	elif game_flags[flag_id] != value:
		game_flags[flag_id] = value
		flag_updated.emit(flag_id, value)


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return

	var fullscreen: bool = config.get_value("video", "fullscreen", false)
	var music_vol: float = config.get_value("audio", "music_volume", 100.0)
	var sounds_vol: float = config.get_value("audio", "sounds_volume", 100.0)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED,
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_vol / 100.0),
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sounds"),
		linear_to_db(sounds_vol / 100.0),
	)


func _ready() -> void:
	add_child(music_player)
	music_player.bus = "Music"
	music_player.autoplay = false

	reset_game_state()
	load_settings()

	screen_fader = preload(SCREEN_FADER_PATH).instantiate()
	add_child(screen_fader)

	screen_fader.fade_out_finished.connect(_on_fade_out_finished)


func resolve_scene_path(scene_reference: String) -> String:
	return "res://scenes/" + scene_reference + ".tscn"


# Начинаем перемещение в другую локацию
func start_scene_transition(scene_reference: String, spawn_point: String) -> void:
	_pending_scene_path = resolve_scene_path(scene_reference)
	if _pending_scene_path.is_empty() or not ResourceLoader.exists(_pending_scene_path):
		push_error("Scene transition target does not exist: %s" % scene_reference)
		return

	pending_spawn_point = spawn_point
	screen_fader.fade_out(0.5) # затемняем экран


# Меняем локацию после затемнения экрана
func _on_fade_out_finished() -> void:
	if SaveSystem.is_loading:
		SaveSystem.load_game_state()

	get_tree().change_scene_to_file(_pending_scene_path) # смена локации
	_pending_scene_path = ""


func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	if music_player.playing:
		music_player.stop()
