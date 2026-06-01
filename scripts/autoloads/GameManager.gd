extends Node


const SETTINGS_PATH := "user://settings.cfg"
const SCENE_ROOT := "res://scenes/"

var player_scene: PackedScene = preload("res://scenes/player.tscn")
var player: CharacterBody2D
var pending_spawn_point: String = ""

var screen_fader: ScreenFader
var _pending_scene_path: String
var saved_direction = null
var saved_flashlight_state = null

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var disable_movement := false
var is_minigame_active := false
var minigame_pause_target: Node = null

var items_inventory: Dictionary:
	get:
		return Items.items_inventory
	set(value):
		Items.apply_inventory_state(value, Items.inventory_order)

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


func item_check(item_name: String) -> int:
	return Items.item_check(item_name)


func item_was_took(item_name: String) -> void:
	Items.item_was_took(item_name)


func item_was_dropped(item_name: String) -> void:
	Items.item_was_dropped(item_name)


func is_done(flag_name: String) -> bool:
	return Quests.is_done(flag_name)


func set_done(flag_name: String) -> void:
	Quests.set_done(flag_name)


func reload(flag_name: String) -> void:
	Quests.reload(flag_name)


func reset_game_state() -> void:
	Quests.reset_game_state()
	Items.apply_inventory_state(Items.DEFAULT_ITEMS_INVENTORY.duplicate(true), [])


func sync_quest_progress() -> void:
	Quests.sync_quest_progress()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return

	var fullscreen: bool = config.get_value("video", "fullscreen", false)
	var music_vol: float = config.get_value("audio", "music_volume", 100.0)
	var sounds_vol: float = config.get_value("audio", "sounds_volume", 100.0)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_vol / 100.0)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sounds"),
		linear_to_db(sounds_vol / 100.0)
	)


func _ready() -> void:
	add_child(music_player)
	music_player.bus = "Music"
	music_player.autoplay = false

	sync_quest_progress()
	load_settings()

	const screen_fader_path := "res://scenes/system/screen_fader.tscn"
	screen_fader = preload(screen_fader_path).instantiate()
	add_child(screen_fader)
	
	screen_fader.fade_out_finished.connect(_on_fade_out_finished)

#---------------------------------------------------------------------------------------------------------------

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

	get_tree().change_scene_to_file(_pending_scene_path)     # смена локации
	_pending_scene_path = ""
#---------------------------------------------------------------------------------------------------------------


func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	if music_player.playing:
		music_player.stop()
